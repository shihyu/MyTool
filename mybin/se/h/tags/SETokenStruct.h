#ifndef SE_TOKEN_STRUCT_H
#define SE_TOKEN_STRUCT_H

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

};

/**
 * This template class is used to generically represent a token as a 
 * structure.  The token type is strictly typed as an enumerated type.
 * <p> 
 * The fields of the structure are public so that you can directly access 
 * them without being forced to use the virtual get and set functions. 
 * This is purely for effeciency and simplicity. 
 * <p> 
 * The only field that is hidden is 'mUSTokenType', because it is mirrored 
 * in the derived template class SETokenStruct using it's native enumerated 
 * type.  This is done primarily for debugging purposes. 
 */
template <class TokenType>
class SETokenStructTyped : public SETokenStruct {
public:
   /**
    * Default constuctor.
    */
   SETokenStructTyped();
   /**
    * Copy constructor. 
    * @param src   token to copy
    */
   SETokenStructTyped(const SETokenStructTyped &src);
   /**
    * Copy constructor from generic (untyped) token struct.
    * @param src  token to copy
    */
   SETokenStructTyped(const SETokenStruct &src);
   /**
    * Copy constructor from a generic token type.
    * @param src   token to copy
    */
   SETokenStructTyped(const SETokenReadInterface &src);
   /**
    * Destructor.
    */
   virtual ~SETokenStructTyped();

   /**
    * Assignment operator
    * 
    * @param src  token to copy from
    * @return Reference to token (*this)
    */
   SETokenStructTyped &operator = (const SETokenStructTyped &src);
   /**
    * Assignment operator from generic (untyped) token structure.
    * 
    * @param src  token to copy from
    * @return Reference to token (*this)
    */
   SETokenStructTyped &operator = (const SETokenStruct &src);
   /**
    * Assignment operator from generic token interface.
    * 
    * @param src  token to copy from
    * @return Reference to token (*this)
    */
   SETokenStructTyped &operator = (const SETokenReadInterface &src);

   /**
    * @return Returns 'true' if this token matches the given token. 
    * @param src  token object to compare to 
    */
   bool operator == (const SETokenStructTyped &src) const;
   bool operator == (const SETokenStruct &src) const;
   bool operator == (const SETokenReadInterface &src) const;
   /**
    * @return Returns 'true' if this token does not match the given token. 
    * @param src  token object to compare to 
    */
   bool operator != (const SETokenStructTyped &src) const;
   bool operator != (const SETokenStruct &src) const;
   bool operator != (const SETokenReadInterface &src) const;

   /**
    * @return Return the token type for this token.
    *
    * @see SETokenSource
    * @see SETokenizer
    */
   virtual const SETokenType getTokenType() const;
   /**
    * @return Return the token type for this token.
    *
    * @see SETokenSource
    * @see SETokenizer
    */
   virtual const TokenType getTokenTypeTyped() const;
   /**
    * Set the token type for this token.
    *
    * @param token  token type
    * @return 0 on success, <0 on error
    *
    * @see getTokenType()
    * @see SETokenSource
    * @see SETokenizer
    */
   virtual int setTokenType(const TokenType token);

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
                               const TokenType tokenType,
                               const unsigned int startOffset,
                               const unsigned int tokenLength=0,
                               const unsigned int tokenStartLineNumber=0,
                               const unsigned int tokenStartLineOffset=0,
                               const unsigned int tokenEndLineNumber=0,
                               const unsigned int tokenEndLineOffset=0);

private:
   /**
    * This field hides the "mTokenType" field in SETokenStruct
    */
   TokenType mTokenType;

};


////////////////////////////////////////////////////////////////////////////
/// INLINE FUNCTIONS
///

template <class TokenType>
inline
SETokenStructTyped<TokenType>::SETokenStructTyped():
   SETokenStruct(),
   mTokenType((TokenType)0)
{
}

template <class TokenType>
inline
SETokenStructTyped<TokenType>::SETokenStructTyped(const SETokenReadInterface &src):
   SETokenStruct(src),
   mTokenType((TokenType) src.getTokenType())
{
}

template <class TokenType>
inline
SETokenStructTyped<TokenType>::SETokenStructTyped(const SETokenStruct &src):
   SETokenStruct(src),
   mTokenType((TokenType) src.getTokenType())
{
}

template <class TokenType>
inline
SETokenStructTyped<TokenType>::SETokenStructTyped(const SETokenStructTyped &src):
   SETokenStruct(src),
   mTokenType(src.mTokenType)
{
}

template <class TokenType>
inline
SETokenStructTyped<TokenType>::~SETokenStructTyped()
{
   mTokenType = (TokenType) 0;
}

template <class TokenType>
inline
SETokenStructTyped<TokenType> & 
SETokenStructTyped<TokenType>::operator =(const SETokenStruct &src)
{
   if (this != &src) {
      SETokenStruct::operator = (src);
      this->mTokenType = (TokenType) src.getTokenType();
   }
   return *this;
}

template <class TokenType>
inline
SETokenStructTyped<TokenType> & 
SETokenStructTyped<TokenType>::operator =(const SETokenStructTyped &src)
{
   if (this != &src) {
      SETokenStruct::operator = (src);
      this->mTokenType = src.mTokenType;
   }
   return *this;
}

template <class TokenType>
inline 
SETokenStructTyped<TokenType> & 
SETokenStructTyped<TokenType>::operator =(const SETokenReadInterface &src)
{
   if (this != &src) {
      SETokenStruct::operator = (src);
      this->mTokenType = (TokenType) src.getTokenType();
   }
   return *this;
}

template <class TokenType>
inline 
bool 
SETokenStructTyped<TokenType>::operator !=(const SETokenStructTyped &src) const
{
   if (this == &src) return false;
   if (SETokenStruct::operator != (src)) return true;
   if (this->mTokenType != src.mTokenType) return true;
   return false;
}

template <class TokenType>
inline 
bool
SETokenStructTyped<TokenType>::operator ==(const SETokenStructTyped &src) const
{
   if (this == &src) return true;
   if (SETokenStruct::operator != (src)) return false;
   if (this->mTokenType != src.mTokenType) return false;
   return true;
}

template <class TokenType>
inline 
bool 
SETokenStructTyped<TokenType>::operator !=(const SETokenStruct &src) const
{
   if (this == &src) return false;
   if (SETokenStruct::operator != (src)) return true;
   if (this->mTokenType != (TokenType)src.getTokenType()) return true;
   return false;
}

template <class TokenType>
inline 
bool
SETokenStructTyped<TokenType>::operator ==(const SETokenStruct &src) const
{
   if (this == &src) return true;
   if (SETokenStruct::operator != (src)) return false;
   if (this->mTokenType != (TokenType)src.getTokenType()) return false;
   return true;
}

template <class TokenType>
inline 
bool 
SETokenStructTyped<TokenType>::operator !=(const SETokenReadInterface &src) const
{
   if (this == &src) return false;
   if (SETokenStruct::operator != (src)) return true;
   if (this->mTokenType != (TokenType)src.getTokenType()) return true;
   return false;
}

template <class TokenType>
inline 
bool 
SETokenStructTyped<TokenType>::operator ==(const SETokenReadInterface &src) const {
   if (this == &src) return true;
   if (SETokenStruct::operator != (src)) return false;
   if (this->mTokenType != (TokenType)src.getTokenType()) return false;
   return true;
}

template <class TokenType>
inline 
const TokenType 
SETokenStructTyped<TokenType>::getTokenTypeTyped() const
{
   return mTokenType;
}

template <class TokenType>
inline 
const SETokenType
SETokenStructTyped<TokenType>::getTokenType() const
{
   return (SETokenType) mTokenType;
}

template <class TokenType>
inline 
int
SETokenStructTyped<TokenType>::setTokenType(const TokenType token)
{
   SETokenStruct::setTokenType((SETokenType) token);
   mTokenType = token;
   return 0;
}

template <class TokenType>
inline 
int
SETokenStructTyped<TokenType>::initializeToken(const SEString &tokenText,
                                               const TokenType tokenType,
                                               const unsigned int startOffset,
                                               const unsigned int tokenLength,
                                               const unsigned int tokenStartLineNumber,
                                               const unsigned int tokenStartLineOffset,
                                               const unsigned int tokenEndLineNumber,
                                               const unsigned int tokenEndLineOffset)
{
   this->setTokenType(tokenType);
   this->mTokenID         = 0;
   this->mStartOffset     = startOffset;
   this->mTokenLength     = tokenLength? tokenLength : tokenText.length32();
   this->mStartLineNumber = tokenStartLineNumber? tokenStartLineNumber : 1;
   this->mStartLineOffset = tokenStartLineNumber? tokenStartLineOffset : startOffset;
   this->mEndLineNumber   = tokenEndLineNumber? tokenEndLineNumber: mStartLineNumber;
   this->mEndLineOffset   = tokenEndLineNumber? tokenEndLineOffset: mStartLineOffset+tokenLength;
   return this->mTokenText.set(tokenText);
}


} // namespace slickedit

#endif

