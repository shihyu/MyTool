////////////////////////////////////////////////////////////////////////////////
// Copyright 2017 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:        SETokenInterface.h
// Description: Declaration for the SETokenInterface abstract class
////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "slickedit/SEString.h"
#include "tags/SETokenType.h"


namespace slickedit {

/**
 * Tokens are identified by a positive integer token ID. 
 * This ID is used like a handle to look up a token. 
 * <p> 
 * Once a token is created, it's ID is permanent, event if the file 
 * it belongs to is modified, as long as the token itself is not deleted. 
 *  
 * @see SETokenInterface 
 * @see SETokenList 
 * @see SEParseTreeNode 
 * @see SEParseTree 
 */
typedef unsigned int SETokenID;

/**
 * A pair of tokens.
 */
struct VSDLLEXPORT SETokenPair {
   SETokenID mTokenID_1;
   SETokenID mTokenID_2;
};

/**
 * This class defines an interface for accessing the properties of a token. 
 * <p>
 * Implementing this interface will make it possible to insert tokens into 
 * a generic token list and a generic parse tree.  The tokens stored in the 
 * generic token list also implement this interface. 
 * @example 
 * <pre>
 *     class UnixLexToken : public SETokenReadInterface { ... };
 * </pre>
 * <p> 
 * Use this interface in APIs when you need to pass token information into 
 * a function for reading. 
 * @example 
 * <pre>
 *     int printTokenInfo(const SETokenWriteInterface &tokenInfo);
 * </pre>
 *  
 * @see SETokenID 
 * @see SETokenWriteInterface 
 * @see SETokenReadInterface 
 * @see SETokenInterface 
 * @see SETokenList 
 * @see SEParseTreeNode 
 * @see SEParseTree 
 */
class VSDLLEXPORT SETokenReadInterface {
public:

   /**
    * Default constructor.
    */
   SETokenReadInterface();
   /**
    * Destructor.
    */
   virtual ~SETokenReadInterface();

   /**
    * @return Returns 'true' if this token matches the given token. 
    * @param src  token object to compare to 
    */
   bool operator == (const SETokenReadInterface &src) const;
   /**
    * @return Returns 'true' if this token does not match the given token. 
    * @param src  token object to compare to 
    */
   bool operator != (const SETokenReadInterface &src) const;

   /**
    * @return Returns 'true' if this token matches the given token. 
    * @param src  token object to compare to 
    */
   bool operator == (const class SETokenStruct &src) const;
   /**
    * @return Returns 'true' if this token does not match the given token. 
    * @param src  token object to compare to 
    */
   bool operator != (const class SETokenStruct &src) const;

   /**
    * @return Return the positive integer token ID for this token. 
    *  
    * @see SETokenList 
    * @see SEParseTreeNode 
    * @see SEParseTree 
    * @see SETokenID 
    */
   virtual const SETokenID getTokenID() const = 0;

   /**
    * @return Return the token type for this token. 
    *  
    * @see SETokenSource 
    * @see SETokenizer
    * @see SETokenType 
    */
   virtual const SETokenType getTokenType() const = 0;

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
   virtual int getTokenText(SEString &text) const = 0;
   /**
    * @return Return the length of the token in bytes. 
    *  
    * @see getTokenText() 
    */
   virtual const unsigned int getTokenLength() const = 0;

   /**
    * @return Return the name of the file this token comes from. 
    */
   virtual const SEString getFileName() const;
   virtual int getFileName(SEString &fileName) const = 0;

   /**
    * @return Return the buffer ID for the file this token comes from. 
    *         The default implementation of this function returns 0. 
    */
   virtual const int getFileBufferID() const;

   /**
    * @return Return the start seek position (in bytes) of the token relative 
    * to the start of the text buffer it belongs to. 
    *  
    * @see getEndOffset(); 
    * @see getStartLineNumber(); 
    * @see getStartLineOffset(); 
    */
   virtual const unsigned int getStartOffset() const = 0;
   /**
    * @return Return the offset in bytes from the start of this token to the 
    * start of the first line containing this token. 
    *  
    * @see getStartOffset(); 
    * @see getStartLineNumber(); 
    * @see getEndLineOffset(); 
    */
   virtual const unsigned int getStartLineOffset() const = 0;
   /** 
    * @return Return the starting line number for this token. 
    *  
    * @see getStartOffset(); 
    * @see getStartLineOffset(); 
    * @see getEndLineNumber();
    */
   virtual const unsigned int getStartLineNumber() const = 0;
   /**
    * @return Return the end seek position (in bytes) of the token relative 
    * to the start of the text buffer it belongs to.  This can be calculated 
    * by adding the token length to the start offset of the token. 
    *  
    * @see getStartOffset(); 
    */
   virtual const unsigned int getEndOffset() const;
   /**
    * @return Return the offset in bytes from the end of this token to the 
    * start of the last line containing this token. 
    *  
    * @see getEndOffset(); 
    * @see getStartLineOffset(); 
    * @see getEndLineNumber();
    */
   virtual const unsigned int getEndLineOffset() const = 0;
   /**
    * @return Return the ending line number for this token. 
    *  
    * @see getEndOffset(); 
    * @see getEndLineOffset();
    * @see getStartLineNumber();
    */
   virtual const unsigned int getEndLineNumber() const = 0;

   /**
    * @return 'true' if the token spans the given offset 
    *  
    * @see getStartOffset()
    * @see getEndOffset()
    */
   virtual const bool isSpanningOffset(const unsigned int offset) const;
   /**
    * @return 'true' if the token spans the given line number 
    *  
    * @see getStartLineNumber() 
    * @see getEndLineNumber() 
    */
   virtual const bool isSpanningLine(const unsigned int lineNumber) const;

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
    * @return Return the number of lines spanned by this token, inclusive. 
    *  
    * @see getStartLineNumber(); 
    * @see getEndLineNumber(); 
    */
   virtual const unsigned int getNumLines() const;
};

/**
 * This class defines an interface for accessing the properties of a token, 
 * and modifying the properties of a token. 
 * <p> 
 * This interface is required to have a generic interface for copying the 
 * information represented in a read-only token into another token object of 
 * a user-defined type. 
 * <p> 
 * Use this interface when you have a token which you plan on passing to 
 * a function as an output parameter. 
 * <p> 
 * @example 
 * <pre>
 *     int getTokenInfo(SETokenWriteInterface &tokenInfo) const; 
 * </pre>
 *  
 * @see SETokenID 
 * @see SETokenWriteInterface 
 * @see SETokenReadInterface 
 * @see SETokenInterface 
 * @see SETokenList 
 * @see SEParseTreeNode 
 * @see SEParseTree 
 */
class VSDLLEXPORT SETokenWriteInterface : public SETokenReadInterface {
public:

   /**
    * Default constructor.
    */
   SETokenWriteInterface();
   /**
    * Destructor.
    */
   virtual ~SETokenWriteInterface();

   /**
    * Assignment operator.  This uses the generic methods from the token read 
    * interface, combined with the generic setter methods in this interface to 
    * copy a token's information. 
    * 
    * @param src  token to copy
    * @return  Returns a reference to 'this'.
    */
   SETokenWriteInterface &operator = (const SETokenReadInterface &src);

   /**
    * Assignment operator to copy token information from a token struct. 
    * 
    * @param src  token struct to copy
    * @return  Returns a reference to 'this'.
    */
   SETokenWriteInterface &operator = (const class SETokenStruct &src);

   /**
    * @return Returns 'true' if this token matches the given token. 
    * @param src  token object to compare to 
    */
   bool operator == (const SETokenReadInterface &src) const;
   /**
    * @return Returns 'true' if this token does not match the given token. 
    * @param src  token object to compare to 
    */
   bool operator != (const SETokenReadInterface &src) const;

   /**
    * @return Returns 'true' if this token matches the given token. 
    * @param src  token object to compare to 
    */
   bool operator == (const class SETokenStruct &src) const;
   /**
    * @return Returns 'true' if this token does not match the given token. 
    * @param src  token object to compare to 
    */
   bool operator != (const class SETokenStruct &src) const;

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
   virtual int setTokenID(const SETokenID id) = 0;

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
   virtual int setTokenType(const SETokenType token) = 0;

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
    * Set the text that this token represents. 
    *  
    * @param text  string to copy in. 
    * @return 0 on success, <0 on error 
    *  
    * @see getTokenText() 
    * @see setTokenLength() 
    * @see getTokenLength() 
    */
   virtual int setTokenText(const SEString &text) = 0;
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
   virtual int setTokenLength(const unsigned int numBytes) = 0;

   /**
    * Set the file name (and optional buffer ID) which this list of 
    * tokens originate from. 
    *  
    * @param fileName   full path of file tokens come from 
    * @param bufferID   editor buffer ID corresponding to file. 
    */
   virtual int setFileName(const SEString &fileName, int bufferID=0) = 0;

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
   virtual int setStartOffset(const unsigned int seekPosition) = 0;
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
   virtual int setStartLineOffset(const unsigned int lineOffset) = 0;
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
   virtual int setStartLineNumber(const unsigned int lineNumber) = 0;
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
    * @see getStartOffset() 
    * @see getStartLineNumber() 
    * @see getStartLineOffset() 
    */
   virtual int setStartPosition(const unsigned int startOffset,
                                const unsigned int startLineNumber,
                                const unsigned int startLineOffset=0);

   /**
    * Set the end position information for this token. 
    * 
    * @param endOffset      token end offset
    * 
    * @return 0 on success, <0 on error 
    *  
    * @see getEndOffset() 
    */
   virtual int setEndOffset(const unsigned int endOffset);
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
   virtual int setEndLineNumber(const unsigned int lineNumber) = 0;
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
   virtual int setEndLineOffset(const unsigned int lineOffset) = 0;
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
    * @see getEndOffset() 
    * @see getEndLineNumber() 
    * @see getEndLineOffset() 
    */
   virtual int setEndPosition(const unsigned int endOffset,
                              const unsigned int endLineNumber,
                              const unsigned int endLineOffset=0);

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
                               const unsigned int tokenLength,
                               const unsigned int tokenStartLineNumber=0,
                               const unsigned int tokenStartLineOffset=0,
                               const unsigned int tokenEndLineNumber=0,
                               const unsigned int tokenEndLineOffset=0) = 0;

};

/**
 * This class defines an interface for reading and writing the properties 
 * of a generic token object. 
 * <p> 
 * Implementing this interface, or it's simpler read interface allows a token 
 * class to be used with the generic token list and parse tree classes.
 *  
 * @see SETokenID 
 * @see SETokenWriteInterface 
 * @see SETokenReadInterface 
 * @see SETokenInterface 
 * @see SETokenList 
 * @see SEParseTreeNode 
 * @see SEParseTree 
 */
class VSDLLEXPORT SETokenInterface : public SETokenWriteInterface {
public:

   /**
    * Default constructor.
    */
   SETokenInterface();
   /**
    * Destructor.
    */
   virtual ~SETokenInterface();

   /**
    * Assignment operator.  This uses the generic methods from the token read 
    * interface, combined with the generic setter methods in this interface to 
    * copy a token's interface. 
    * 
    * @param src  token to copy
    * @return  Returns a reference to 'this'.
    */
   SETokenInterface &operator = (const SETokenReadInterface &src);

   /**
    * Assignment operator to copy token information from a token struct. 
    * 
    * @param src  token struct to copy
    * @return  Returns a reference to 'this'.
    */
   SETokenInterface &operator = (const class SETokenStruct &src);

   /**
    * @return Returns 'true' if this token matches the given token. 
    * @param src  token object to compare to 
    */
   bool operator == (const SETokenReadInterface &src) const;
   /**
    * @return Returns 'true' if this token does not match the given token. 
    * @param src  token object to compare to 
    */
   bool operator != (const SETokenReadInterface &src) const;

   /**
    * @return Returns 'true' if this token matches the given token. 
    * @param src  token object to compare to 
    */
   bool operator == (const class SETokenStruct &src) const;
   /**
    * @return Returns 'true' if this token does not match the given token. 
    * @param src  token object to compare to 
    */
   bool operator != (const class SETokenStruct &src) const;

};

////////////////////////////////////////////////////////////////////////////////
/// INLINE FUNCIONS
///

inline
SETokenReadInterface::SETokenReadInterface()
{
}

inline
SETokenWriteInterface::SETokenWriteInterface()
{
}

inline
SETokenInterface::SETokenInterface()
{
}

inline
bool
SETokenWriteInterface::operator == (const SETokenReadInterface &src) const
{
   return SETokenReadInterface::operator == (src);
}

inline
bool
SETokenWriteInterface::operator != (const SETokenReadInterface &src) const
{
   return SETokenReadInterface::operator != (src);
}

inline
bool
SETokenInterface::operator == (const SETokenReadInterface &src) const
{
   return SETokenReadInterface::operator == (src);
}

inline
bool
SETokenInterface::operator != (const SETokenReadInterface &src) const
{
   return SETokenReadInterface::operator != (src);
}

inline
bool
SETokenWriteInterface::operator == (const class SETokenStruct &src) const
{
   return SETokenReadInterface::operator == (src);
}

inline
bool
SETokenWriteInterface::operator != (const class SETokenStruct &src) const
{
   return SETokenReadInterface::operator != (src);
}

inline
bool
SETokenInterface::operator == (const class SETokenStruct &src) const
{
   return SETokenReadInterface::operator == (src);
}

inline
bool
SETokenInterface::operator != (const class SETokenStruct &src) const
{
   return SETokenReadInterface::operator != (src);
}

} // namespace slickedit

