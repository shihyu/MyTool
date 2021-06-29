////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:          SETokenStruct.h
// Description:   simple struct for representing a token.
////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "SETokenInterface.h"
#include "slickedit/SEString.h"

namespace slickedit {

/**
 * This class is used to generically represent a token as a structure. 
 * <p> 
 * The fields of the structure are public so that you can directly access 
 * them without being forced to use the virtual get and set functions. 
 * This is purely for effeciency and simplicity. 
 * <p> 
 * The only field that is hidden is 'mTokenType', because it is mirrored 
 * in the derived template class SETokenStructTyped using it's native 
 * enumerated type.  This is done primarily for debugging purposes. 
 */
class VSDLLEXPORT SETokenStruct : public SETokenInterface {

public:
   /**
    * Default constuctor.
    */
   SETokenStruct();
   /**
    * Copy constructor. 
    * @param src   token to copy
    */
   SETokenStruct(const SETokenStruct &src);
   /**
    * Move constructor. 
    * @param src   token to copy
    */
   SETokenStruct(SETokenStruct &&src);
   /**
    * Copy constructor from generic token interface.
    * @param src  token to copy
    */
   SETokenStruct(const SETokenReadInterface &src);
   /**
    * Destructor.
    */
   virtual ~SETokenStruct();

   /**
    * Assignment operator
    * 
    * @param src  token to copy from
    * @return Reference to token (*this)
    */
   SETokenStruct &operator = (const SETokenStruct &src);
   /**
    * Move assignment operator
    * 
    * @param src  token to copy from
    * @return Reference to token (*this)
    */
   SETokenStruct &operator = (SETokenStruct &&src);
   /**
    * Assignment operator from generic token interface.
    * 
    * @param src  token to copy from
    * @return Reference to token (*this)
    */
   SETokenStruct &operator = (const SETokenReadInterface &src);
   /**
    * Copy everything execpt token text from a generic token interface
    */
   int copyWithoutText(const SETokenReadInterface &src);

   /**
    * @return Returns 'true' if this token matches the given token. 
    * @param src  token object to compare to 
    */
   bool operator == (const SETokenStruct &src) const;
   bool operator == (const SETokenReadInterface &src) const;
   /**
    * @return Returns 'true' if this token does not match the given token. 
    * @param src  token object to compare to 
    */
   bool operator != (const SETokenStruct &src) const;
   bool operator != (const SETokenReadInterface &src) const;

public:

   /**
    * @return Return the positive integer token ID for this token.
    *
    * @see SETokenList
    * @see SEParseTreeNode
    * @see SEParseTree
    * @see SETokenID
    */
   virtual const SETokenID getTokenID() const;
   /**
    * Set the positive integer token ID for this token.
    *
    * @param id   new token ID
    * @return 0 on success, <0 on error
    *
    * @see getTokenID()
    * @see SETokenList
    * @see SEParseTreeNode
    * @see SEParseTree
    * @see SETokenID
    */
   virtual int setTokenID(const SETokenID id);

   /**
    * @return Return the token type for this token.
    * <p>
    * The token type is represented using an unsigned short integer,
    * which usually maps to an enumerated type defined by the lexical analyzer.
    *
    * @see SETokenSource
    * @see SETokenizer 
    * @see SETokenType 
    */
   virtual const SETokenType getTokenType() const;
   /**
    * Set the token type for this token.
    * <p>
    * The token type is represented using an unsigned short integer,
    * which usually maps to an enumerated type defined by the lexical analyzer.
    *
    * @param token  token type
    * @return 0 on success, <0 on error
    *
    * @see getTokenType()
    * @see SETokenSource
    * @see SETokenizer
    * @see SETokenType 
    */
   virtual int setTokenType(const SETokenType token);

   /**
    * @return Return the parsing error status for this token.
    *
    * @see SETokenSource
    * @see SETokenizer 
    * @see SETokenType 
    * @see SETokenErrorStatus
    */
   virtual const SETokenErrorStatus getTokenErrorStatus() const;
   /**
    * Set the parsing error status for this token.
    *
    * @param token  token type
    * @return 0 on success, <0 on error
    *
    * @see getTokenErrorStatus()
    * @see SETokenSource
    * @see SETokenizer
    * @see SETokenType 
    * @see SETokenErrorStatus
    */
   virtual int setTokenErrorStatus(const SETokenErrorStatus token);

   /**
    * @return Return a copy of the text represented by the token.
    *
    * @see getTokenLength()
    */
   virtual const SEString getTokenText() const;
   /**
    * Copy the text represented by the token into the given string.
    * @param text    (reference) string to copy text into
    * @return 0 on success, <0 on error.
    */
   virtual int getTokenText(SEString &text) const;
   /**
    * Set the text that this token represents.
    *
    * @param text  string to copy in.
    * @return 0 on success, <0 on error
    *
    * @see getTokenText()
    * @see setTokenLength()
    * @see getTokenLength()
    */
   virtual int setTokenText(const SEString &text);

   /**
    * @return Return the length of the token in bytes.
    *
    * @see getTokenText()
    */
   virtual const unsigned int getTokenLength() const;
   /**
    * Set the length of the token in bytes.
    *
    * @param numBytes   token length in bytes
    * @return 0 on success, <0 on error
    *
    * @see setTokenText()
    * @see getTokenText()
    * @see getTokenLength()
    */
   virtual int setTokenLength(const unsigned int numBytes);

   /**
    * @return Return the name of the file this token comes from. 
    */
   virtual const SEString getFileName() const;
   virtual int getFileName(SEString &fileName) const;

   /**
    * @return Return the buffer ID for the file this token comes from.
    */
   virtual const int getFileBufferID() const;

   /**
    * Set the file name (and optional buffer ID) which this list of 
    * tokens originate from. 
    *  
    * @param fileName   full path of file tokens come from 
    * @param bufferID   editor buffer ID corresponding to file. 
    */
   virtual int setFileName(const SEString &fileName, int bufferID=0);

   /**
    * @return Return the start seek position (in bytes) of the token relative
    * to the start of the text buffer it belongs to.
    *
    * @see getEndOffset();
    * @see getStartLineNumber();
    * @see getStartLineOffset();
    */
   virtual const unsigned int getStartOffset() const;
   /**
    * Set the start seek position (in bytes) of the token relative
    * to the start of the text buffer it belongs to.
    *
    * @param seekPosition   offset from start of buffer in bytes
    * @return 0 on success, <0 on error
    *
    * @see getEndOffset();
    * @see getStartLineNumber();
    * @see getStartLineOffset();
    * @see setStartLineNumber();
    * @see setStartLineOffset();
    */
   virtual int setStartOffset(const unsigned int seekPosition);

   /**
    * @return Return the offset in bytes from the start of this token to the
    * start of the first line containing this token.
    *
    * @see getStartOffset();
    * @see getStartLineNumber();
    * @see getEndLineOffset();
    */
   virtual const unsigned int getStartLineOffset() const;
   /**
    * Set the offset in bytes from the start of this token to the
    * start of the first line containing this token.
    *
    * @param lineOffset   offset from start of line in bytes
    * @return 0 on success, <0 on error
    *
    * @see getStartOffset();
    * @see getStartLineNumber();
    * @see getEndLineOffset();
    * @see setStartLineNumber();
    * @see setStartOffset();
    */
   virtual int setStartLineOffset(const unsigned int lineOffset);

   /**
    * @return Return the starting line number for this token.
    *
    * @see getStartOffset();
    * @see getStartLineOffset();
    * @see getEndLineNumber();
    */
   virtual const unsigned int getStartLineNumber() const;
   /**
    * Set the starting line number for this token.
    *
    * @param lineNumber  line number from start of buffer
    * @return 0 on success, <0 on error
    *
    * @see getStartOffset();
    * @see getStartLineOffset();
    * @see getEndLineNumber();
    * @see setStartLineOffset();
    * @see setEndLineNumber();
    * @see setStartOffset();
    */
   virtual int setStartLineNumber(const unsigned int lineNumber);

   /**
    * Set the start position information for this token.
    * 
    * @param startOffset      token start offset
    * @param startLineNumber  token start line number
    * @param startLineOffset  token start line offset
    * 
    * @return 0 on success, <0 on error 
    *  
    * @see setStartOffset() 
    * @see setStartLineNumber() 
    * @see setStartLineOffset() 
    * @see getStartPosition(); 
    */
   virtual int setStartPosition(const unsigned int startOffset,
                                const unsigned int startLineNumber,
                                const unsigned int startLineOffset=0);

   /**
    * @return Return the offset in bytes from the end of this token to the
    * start of the last line containing this token.
    *
    * @see getEndOffset();
    * @see getStartLineOffset();
    * @see getEndLineNumber();
    */
   virtual const unsigned int getEndLineOffset() const;
   /**
    * Set the ending line number for this token.
    *
    * @param lineOffset   offset from beginning of last line in bytes
    * @return 0 on success, <0 on error
    *
    * @see getEndOffset();
    * @see getEndLineOffset();
    * @see getStartLineNumber();
    * @see setEndLineNumber();
    * @see setStartLineOffset();
    */
   virtual int setEndLineOffset(const unsigned int lineOffset);

   /**
    * @return Return the ending line number for this token.
    *
    * @see getEndOffset();
    * @see getEndLineOffset();
    * @see getStartLineNumber();
    */
   virtual const unsigned int getEndLineNumber() const;
   /**
    * Set the offset in bytes from the end of this token to the
    * start of the last line containing this token.
    *
    * @param lineNumber  line number form start of buffer
    * @return 0 on success, <0 on error
    *
    * @see getEndOffset();
    * @see getStartLineOffset();
    * @see getEndLineNumber();
    * @see setStartLineNumber();
    * @see setEndLineOffset();
    */
   virtual int setEndLineNumber(const unsigned int lineNumber);
   /**
    * Set the end position information for this token. 
    * This actually sets the token length.
    * 
    * @param endOffset      token end offset
    * 
    * @return 0 on success, <0 on error 
    *  
    * @see getEndOffset() 
    */
   virtual int setEndOffset(const unsigned int endOffset);
   /**
    * Set the end position information for this token.
    * 
    * @param endOffset      token end offset
    * @param endLineNumber  token end line number
    * @param endLineOffset  token end line offset
    * 
    * @return 0 on success, <0 on error 
    *  
    * @see setEndOffset() 
    * @see setEndLineNumber() 
    * @see setEndLineOffset() 
    * @see getEndPosition(); 
    */
   virtual int setEndPosition(const unsigned int endOffset,
                              const unsigned int endLineNumber,
                              const unsigned int endLineOffset=0);

   /**
    * @return Return the number of lines spanned by this token, inclusive.
    *
    * @see getStartLineNumber();
    * @see getEndLineNumber();
    */
   virtual const unsigned int getNumLines() const;

   /**
    * @return Return the end seek position (in bytes) of the token relative
    * to the start of the text buffer it belongs to.  This can be calculated
    * by adding the token length to the start offset of the token.
    *
    * @see getStartOffset();
    */
   virtual const unsigned int getEndOffset() const;

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
    * Get the start position information for this token.
    * 
    * @param startOffset      [output] set to token start offset
    * @param startLineNumber  [output] set to token start line number
    * @param startLineOffset  [output] set to token start line offset
    * 
    * @return 0 on success, <0 on error 
    *  
    * @see getStartOffset() 
    * @see getStartLineNumber() 
    * @see getStartLineOffset() 
    */
   virtual int getStartPosition(unsigned int &startOffset,
                                unsigned int &startLineNumber,
                                unsigned int &startLineOffset) const;

   /**
    * Get the end position information for this group.
    * 
    * @param endOffset      [output] set to token end offset
    * @param endLineNumber  [output] set to token end line number
    * @param endLineOffset  [output] set to token end line offset 
    * 
    * @return 0 on success, <0 on error 
    *  
    * @see getEndOffset() 
    * @see getEndLineNumber() 
    * @see getEndLineOffset() 
    */
   virtual int getEndPosition(unsigned int &endOffset,
                              unsigned int &endLineNumber,
                              unsigned int &endLineOffset) const;

   /**
    * Initialize the token based on the token information provided. 
    * <p> 
    * If the end line number and end offset are ommited, they will be assigned 
    * based on the values provided for the start line number and offset. 
    * 
    * @param tokenText              token text
    * @param tokenType              token type code
    * @param startOffset            start offset of token in bytes
    * @param tokenLength            length of token in bytes
    * @param tokenStartLineNumber   (optional) start line number
    * @param tokenStartLineOffset   (optional) offset from start of line for token start
    * @param tokenEndLineNumber     (optional) end line number
    * @param tokenEndLineOffset     (optional) offset from start of line for token end
    * 
    * @return 0 on success, <0 on error
    */
   virtual int initializeToken(const SEString &tokenText,
                               const SETokenType tokenType,
                               const unsigned int startOffset,
                               const unsigned int tokenLength=0,
                               const unsigned int tokenStartLineNumber=0,
                               const unsigned int tokenStartLineOffset=0,
                               const unsigned int tokenEndLineNumber=0,
                               const unsigned int tokenEndLineOffset=0);

   /**
    * Is this a completely empty token?
    */
   const bool isEmpty() const;


public:
   /**
    * The positive integer token ID for this token.
    *
    * @see setTokenID()
    * @see getTokenID()
    * @see SETokenID
    */
   SETokenID mTokenID;

   /**
    * The name of the file this token comes from. 
    *  
    * @see getFileName() 
    * @see setFileName()
    * @see getFileBufferID() 
    */
   SEString mFileName;
   /**
    * The SlickEdit buffer ID for the file this token comes from. 
    *  
    * @see getFileName() 
    * @see setFileName()
    * @see getFileBufferID() 
    */
   int mFileBufferID;

   /**
    * The start seek position (in bytes) of the token relative
    * to the start of the text buffer it belongs to.
    *
    * @see setStartOffset();
    * @see getStartOffset();
    */
   unsigned int mStartOffset;
   /**
    * The starting line number for this token.
    *
    * @see getStartLineNumber()
    * @see setStartLineNumber()
    */
   unsigned int mStartLineNumber;

   /**
    * The offset in bytes from the start of this token to the
    * start of the first line containing this token.
    *
    * @see getStartLineOffset()
    * @see setStartLineOffset()
    */
   unsigned int mStartLineOffset;
   /**
    * The ending line number for this token.
    *
    * @see getEndLineNumber()
    * @see setEndLineNumber()
    */
   unsigned int mEndLineNumber;
   /**
    * The offset in bytes from the end of this token to the
    * start of the last line containing this token.
    *
    * @see getEndLineOffset();
    * @see setEndLineOffset();
    */
   unsigned int mEndLineOffset;

   /**
    * The text that this token represents. 
    *  
    * @see getTokenText()
    * @see setTokenText()
    * @see setTokenLength()
    * @see getTokenLength()
    */
   SEString mTokenText;
   /**
    * The length of the token in bytes.
    *
    * @see getTokenText()
    * @see setTokenText()
    * @see setTokenLength()
    * @see getTokenLength()
    */
   unsigned int mTokenLength;

private:

   /**
    * The token type for this token. 
    * This struct field is private because it may be overridden 
    * with an enumerated type in subclasses. 
    *
    * @see getTokenType()
    * @see setTokenType()
    */
   SETokenType mTokenType;

   /**
    * The parse error status for this token.
    * This struct field is private because it may be overridden 
    * with an enumerated type in subclasses. 
    *
    * @see getTokenErrorStatus()
    * @see setTokenErrorStatus()
    */
   SETokenErrorStatus mTokenErrorStatus;
};


} // namespace slickedit


