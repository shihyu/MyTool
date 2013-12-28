////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_CHARTYPE_H
#define SLICKEDIT_CHARTYPE_H

#include "slickc.h"
#include <string.h>

namespace slickedit { 

class VSDLLEXPORT SECharType {
public:
   /**
    * Constructor, initializes all type tables.
    */
   SECharType();
   /**
    * Copy constructor.
    */
   SECharType(const SECharType& src);

   /**
    * Assignment operator
    */
   SECharType &operator =(const SECharType& src);

   /**
    * @return Return the single instance of the SECharType class.
    */
   static const SECharType &getInstance();

   /**
    * Equivalent to the C library function iscsym(). 
    */
   bool isCSym(unsigned char ch) const;
   
   /**
    * Equivalent to the C library function isalpha() 
    * but only for the strict ASCII 7-bit character set. 
    */
   bool isAlNumAscii(unsigned char ch) const;
   
   /**
    * Equivalent to the C library function isalpha(). 
    */
   bool isAlpha(unsigned char ch) const;
   
   /**
    * Equivalent to the C library function isalnum(). 
    */
   bool isAlNum(unsigned char ch) const;
   
   /**
    * Equivalent to the C library function isdigit(). 
    */
   bool isDigit(unsigned char ch) const;
   
   /**
    * Equivalent to the C library function isxdigit(). 
    */
   bool isHexDigit(unsigned char ch) const;
   
   /**
    * Equivalent to the C library function isupper(). 
    */
   bool isUpper(unsigned char ch) const;
   
   /**
    * Equivalent to the C library function islower(). 
    */
   bool isLower(unsigned char ch) const;
   
   /**
    * Equivalent to the C library function isspace(). 
    */
   bool isSpace(unsigned char ch) const;
   
   /**
    * Equivalent to the C library function tolower(). 
    */
   int toUpper(unsigned char ch) const;
   
   /**
    * Equivalent to the C library function tolower() 
    */
   int toLower(unsigned char ch) const;
   
   /**
    * Equivalent to the C library function tolower() 
    * but only for the strict ASCII 7-bit character set. 
    */
   int toLowerAscii(unsigned char ch) const;
   
   /**
    * Equivalent to the C library function toupper() 
    * but only for the strict ASCII 7-bit character set. 
    */
   int toUpperAscii(unsigned char ch) const;

private:
    unsigned char mUpcaseTab[256];   // Code page specific
    unsigned char mLowcaseTab[256];  // Code page specific
    unsigned char mUpcaseTabAscii[256];
    unsigned char mLowcaseTabAscii[256];
    unsigned short mTypeTab[256];

    friend VSDLLEXPORT bool SECharIsCSym(unsigned char ch);
    friend VSDLLEXPORT bool SECharIsAlNumAscii(unsigned char ch);
    friend VSDLLEXPORT bool SECharIsAlpha(unsigned char ch);
    friend VSDLLEXPORT bool SECharIsAlNum(unsigned char ch);
    friend VSDLLEXPORT bool SECharIsDigit(unsigned char ch);
    friend VSDLLEXPORT bool SECharIsHexDigit(unsigned char ch);
    friend VSDLLEXPORT bool SECharIsUpper(unsigned char ch);
    friend VSDLLEXPORT bool SECharIsLower(unsigned char ch);
    friend VSDLLEXPORT bool SECharIsSpace(unsigned char ch);
    friend VSDLLEXPORT int  SECharToUpper(unsigned char ch);
    friend VSDLLEXPORT int  SECharToLower(unsigned char ch);
    friend VSDLLEXPORT int  SECharToLowerAscii(unsigned char ch);
    friend VSDLLEXPORT int  SECharToUpperAscii(unsigned char ch);

    friend VSDLLEXPORT int SEMemcmpIgnoreCase(const char *a_p,const char *b_p,size_t size);
    friend VSDLLEXPORT int SEStrICmpAscii(const char *p1,const char *p2);
    friend VSDLLEXPORT int SEStrNICmpAscii(const char *p1,const char *p2,size_t len);

    friend VSDLLEXPORT void SEStrToUpper(char *p, size_t len);
    friend VSDLLEXPORT void SEStrToLower(char *p, size_t len);
    friend VSDLLEXPORT void SEStrToCap(char *p, size_t len);

    friend VSDLLEXPORT unsigned int SEHashString(const char *p);
    friend VSDLLEXPORT unsigned int SEHashBStringI(const char *p, size_t len);
    friend VSDLLEXPORT unsigned int SEHashBStringUTF8(const char *p, size_t len);
};

/**
 * Flags used in SECharType::mTypeTab
 */
enum SECharTypeFlags {
   SECHARTYPE_UPPER  = 0x0001,  // Uppercase
   SECHARTYPE_LOWER  = 0x0002,  // Lowercase
   SECHARTYPE_DIGIT  = 0x0004,  // Decimal digits
   SECHARTYPE_SPACE  = 0x0008,  // Space characters
// SECHARTYPE_PUNCT  = 0x0010,  // Punctuation
// SECHARTYPE_CNTRL  = 0x0020,  // Control characters
// SECHARTYPE_BLANK  = 0x0040,  // Blank characters
   SECHARTYPE_XDIGIT = 0x0080,  // Hexadecimal digits
   SECHARTYPE_ALPHA  = 0x0100,  // Any linguistic character: alphabetic, syllabary, or ideographic
   SECHARTYPE_CSYM   = 0x1000,  // alpha, digit 0-9, underscore or dollar sign
   SECHARTYPE_ALNUM  = 0x2000   // alpha or digit 0-9
};


/**
 * Equivalent to the C library function iscsym(). 
 */
VSDLLEXPORT bool SECharIsCSym(unsigned char ch);

/**
 * Equivalent to the C library function isalpha() 
 * but only for the strict ASCII 7-bit character set. 
 */
VSDLLEXPORT bool SECharIsAlNumAscii(unsigned char ch);

/**
 * Equivalent to the C library function isalpha(). 
 */
VSDLLEXPORT bool SECharIsAlpha(unsigned char ch);

/**
 * Equivalent to the C library function isalnum(). 
 */
VSDLLEXPORT bool SECharIsAlNum(unsigned char ch);

/**
 * Equivalent to the C library function isdigit(). 
 */
VSDLLEXPORT bool SECharIsDigit(unsigned char ch);

/**
 * Equivalent to the C library function isxdigit(). 
 */
VSDLLEXPORT bool SECharIsHexDigit(unsigned char ch);

/**
 * Equivalent to the C library function isupper(). 
 */
VSDLLEXPORT bool SECharIsUpper(unsigned char ch);

/**
 * Equivalent to the C library function islower(). 
 */
VSDLLEXPORT bool SECharIsLower(unsigned char ch);

/**
 * Equivalent to the C library function isspace(). 
 */
VSDLLEXPORT bool SECharIsSpace(unsigned char ch);

/**
 * Equivalent to the C library function tolower(). 
 */
VSDLLEXPORT int SECharToUpper(unsigned char ch);

/**
 * Equivalent to the C library function tolower() 
 */
VSDLLEXPORT int SECharToLower(unsigned char ch);

/**
 * Equivalent to the C library function tolower() 
 * but only for the strict ASCII 7-bit character set. 
 */
VSDLLEXPORT int SECharToLowerAscii(unsigned char ch);

/**
 * Equivalent to the C library function toupper() 
 * but only for the strict ASCII 7-bit character set. 
 */
VSDLLEXPORT int SECharToUpperAscii(unsigned char ch);

/**
 * Compare a signal character to an upper case character.
 * 
 * @param ch            character to compare
 * @param upcaseLetter  upper case character to compare to
 */
inline bool SECharUpcaseEqual(const char ch, const char upcaseLetter)
{
   return (ch == upcaseLetter || ch == upcaseLetter+('a'-'A'));
}

/**
 * Compare a signal character to an lower case character.
 * 
 * @param ch            character to compare
 * @param upcaseLetter  lower case character to compare to
 */
inline bool SECharLowcaseEqual(const char ch, const char lowcaseLetter)
{
   return (ch == lowcaseLetter || ch == lowcaseLetter-('a'-'A'));
}

/**
 * Wrapper function to compare two blocks of memory. 
 * Simply calls the standard C-library memcmp function. 
 * 
 * @param a_p     pointer to character data
 * @param b_p     pointer to character data
 * @param size    number of bytes to compare
 * 
 * @return 0 if the data areas match, 
 *         <0 if the contents of a_p < b_p,
 *         >0 if the contents of b_p > a_p
 */
inline int SEMemcmp(const char *a_p, const char *b_p, size_t size)
{
   return memcmp(a_p, b_p, size);
}

/**
 * Wrapper function to compare two blocks of memory case-insensitive. 
 * 
 * @param a_p     pointer to character data
 * @param b_p     pointer to character data
 * @param size    number of bytes to compare
 * 
 * @return 0 if the data areas match, 
 *         <0 if the contents of a_p < b_p,
 *         >0 if the contents of b_p > a_p
 */
VSDLLEXPORT int SEMemcmpIgnoreCase(const char *a_p,const char *b_p,size_t size);

/**
 * Wrapper function to compare two strings case-insensitive. 
 * 
 * @param p1      pointer to character data
 * @param p2      pointer to character data
 * 
 * @return 0 if the data areas match, 
 *         <0 if the contents of a_p < b_p,
 *         >0 if the contents of b_p > a_p
 */
VSDLLEXPORT int SEStrICmpAscii(const char *p1,const char *p2);

/**
 * Wrapper function to compare two strings case-insensitive. 
 * 
 * @param p1      pointer to character data
 * @param p2      pointer to character data
 * @param len     number of bytes to compare
 * 
 * @return 0 if the data areas match, 
 *         <0 if the contents of a_p < b_p,
 *         >0 if the contents of b_p > a_p
 */
VSDLLEXPORT int SEStrNICmpAscii(const char *p1,const char *p2,size_t len);

/**
 * Convert a string to upper case, in place
 * 
 * @param p       pointer to character data 
 * @param len     number of bytes to modify     
 */
VSDLLEXPORT void SEStrToUpper(char *p, size_t len);

/**
 * Convert a string to lower case, in place
 * 
 * @param p       pointer to character data 
 * @param len     number of bytes to modify     
 */
VSDLLEXPORT void SEStrToLower(char *p, size_t len);

/**
 * Convert the first letter of a string to upper case and the 
 * rest of the word to lowercase, in place. 
 * 
 * @param p       pointer to character data
 * @param len     number of bytes to modify
 */
VSDLLEXPORT void SEStrToCap(char *p, size_t len);
}

inline bool slickedit::SECharType::isCSym(unsigned char ch) const
{
   return (mTypeTab[ch] & SECHARTYPE_CSYM) != 0;
}
inline bool slickedit::SECharType::isAlNumAscii(unsigned char ch) const
{
   return (mTypeTab[ch] & SECHARTYPE_ALNUM) != 0;
}
inline bool slickedit::SECharType::isAlpha(unsigned char ch) const
{
   return (mTypeTab[ch]&SECHARTYPE_ALPHA) != 0;
}
inline bool slickedit::SECharType::isAlNum(unsigned char ch) const
{
   return (mTypeTab[ch]&(SECHARTYPE_ALPHA|SECHARTYPE_DIGIT)) != 0;
}
inline bool slickedit::SECharType::isDigit(unsigned char ch) const
{
   return (mTypeTab[ch]&SECHARTYPE_DIGIT) != 0;
}
inline bool slickedit::SECharType::isHexDigit(unsigned char ch) const
{
   return (mTypeTab[ch]&SECHARTYPE_XDIGIT) != 0;
}
inline bool slickedit::SECharType::isUpper(unsigned char ch) const
{
   return (mTypeTab[ch]&SECHARTYPE_UPPER) != 0;
}
inline bool slickedit::SECharType::isLower(unsigned char ch) const
{
   return (mTypeTab[ch]&SECHARTYPE_LOWER) != 0;
}
inline bool slickedit::SECharType::isSpace(unsigned char ch) const
{
   return (mTypeTab[ch]&SECHARTYPE_SPACE) != 0;
}
inline int slickedit::SECharType::toUpper(unsigned char ch) const
{
   return (mUpcaseTab[ch]);
}
inline int slickedit::SECharType::toLower(unsigned char ch) const
{
   return (mLowcaseTab[ch]);
}
inline int slickedit::SECharType::toLowerAscii(unsigned char ch) const
{
   return (mLowcaseTabAscii[ch]);
}
inline int slickedit::SECharType::toUpperAscii(unsigned char ch) const
{
   return (mUpcaseTabAscii[ch]);
}


#endif
