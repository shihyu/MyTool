////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once

#include "vsdecl.h"
#include <string.h>
/*
Windows code page and description


OEM code pages
437 MS-DOS United States
708 Arabic (ASMO 708)
709 Arabic (ASMO 449+, BCON V4)
710 Arabic (Transparent Arabic)
720 Arabic (Transparent ASMO)
737 Greek (formerly 437G)
775 Baltic
850 MS-DOS Multilingual (Latin I)
852 MS-DOS Slavic (Latin II)
855 IBM Cyrillic (primarily Russian)
857 IBM Turkish
860 MS-DOS Portuguese
861 MS-DOS Icelandic
862 Hebrew
863 MS-DOS Canadian-French
864 Arabic
865 MS-DOS Nordic
866 MS-DOS Russian (former USSR)
869 IBM Modern Greek


ANSI and OEM code pages
874 Thai
932 Japan
936 Chinese (PRC, Singapore)
949 Korean
950 Chinese (Taiwan Region; Hong Kong SAR, PRC)

ANSI code pages
1200 Unicode (BMP of ISO 10646)
1250 Windows 3.1 Eastern European
1251 Windows 3.1 Cyrillic
1252 Windows 3.1 Latin 1 (US, Western Europe)
1253 Windows 3.1 Greek
1254 Windows 3.1 Turkish
1255 Hebrew
1256 Arabic
1257 Baltic

OEM code pages
1361 Korean (Johab)

*/

#define vsIsCodePageLoadedAsUTF8(cp)  (cp!=VSCP_ACTIVE_CODEPAGE && cp!=VSCP_EBCDIC_SBCS)

// The following definitions have to match those in the code page table: unitools/codepagemaps.tx1
#define VSCP_ACTIVE_CODEPAGE     CMCP_ACTIVE_CODE_PAGE
#define VSCP_FIRST            CMCP_FIRST
#define VSCP_EBCDIC_SBCS         CMCP_EBCDIC_SBCS
#define VSCP_CYRILLIC_KOI8_R  CMCP_Cyrillic_KOI8_R
#define VSCP_ISO_8859_1       CMCP_ISO_8859_1   /* Western European - Latin 1 */
#define VSCP_ISO_8859_2       CMCP_ISO_8859_2   /* Central and Eastern Europe - Latin 2*/
#define VSCP_ISO_8859_3       CMCP_ISO_8859_3   /* Esperanto - Latin 3 */
#define VSCP_ISO_8859_4       CMCP_ISO_8859_4   /* Latin 4 */
#define VSCP_ISO_8859_5       CMCP_ISO_8859_5   /* Cyrillic */
#define VSCP_ISO_8859_6       CMCP_ISO_8859_6   /* Arabic */
#define VSCP_ISO_8859_7       CMCP_ISO_8859_7   /* Greek */
#define VSCP_ISO_8859_8       CMCP_ISO_8859_8   /* Hebrew */
#define VSCP_ISO_8859_9       CMCP_ISO_8859_9   /* Latin 5 */
#define VSCP_ISO_8859_10      CMCP_ISO_8859_10   /* Latin 6 */
#define VSCP_ISO_8859_13      CMCP_ISO_8859_13   /* Latin 7 */
#define VSCP_ISO_8859_14      CMCP_ISO_8859_14   /* Latin 8 */
#define VSCP_ISO_8859_15      CMCP_ISO_8859_15   /* Latin 9 */
#define VSCP_ISO_8859_16      CMCP_ISO_8859_16   /* Latin 10? */

#define VSCP_CYRILLIC_KOI8_U  CMCP_Cyrillic_KOI8_U   // Cyrillic

//#define VSCP_JIS_0201         30101   // Japanese
//#define VSCP_JIS_0208         30102   // Japanese
//#define VSCP_JIS_0212         30103   // Japanese
//#define VSCP_KSC_5601         30104   // Korean
#define VSCP_TIS_620          CMCP_Thai_TIS620   // Thai

#define VSCP_MACROMAN         CMCP_MACROMAN   // Macintosh Roman

//#define VSCP_GB_1988          30118   // Chinese Simplified
//#define VSCP_GB_12345         30120   // Chinese Simplified

#define VSCP_EUC_CN           CMCP_Chinese_Simplified_EUC   // Chinese Simplified
#define VSCP_EUC_JP           CMCP_Japanese_EUC   // Japanese
#define VSCP_EUC_KR           CMCP_Korean_EUC   // Korean

#define VSCP_SYMBOLS          CMCP_Symbol   // Symbols
#define VSCP_DINGBATS         CMCP_Dingbats   // Dingbats

// Some hardcoded code pages.
#define VSCP_SJIS             CMCP_Japanese_Shift_JIS     // Japanese Shift-JIS
#define VSCP_CYRILLIC_WINDOWS_1251 CMCP_Cyrillic_Windows_1251   // Cyrillic (Windows-1251)
#define VSCP_GB_2312          CMCP_Chinese_Simplified_GB_2312     // Chinese Simplified
#define VSCP_BIG5             CMCP_Chinese_Traditional_Big5     // Chinese Traditional Big5


#define VSENCODING_AUTOUNICODE         cmEncoding_AutoUnicode
#define VSENCODING_AUTOUNICODEUTF8     cmEncoding_AutoUnicodeUtf8
#define VSENCODING_AUTOTEXT             cmEncoding_AutoText
#define VSENCODING_AUTOEBCDIC          cmEncoding_AutoEbcdic
#define VSENCODING_AUTOUNICODE2        cmEncoding_AutoUnicode2
#define VSENCODING_AUTOUNICODE2UTF8    cmEncoding_AutoUnicode2Utf8
#define VSENCODING_AUTOEBCDIC_AND_UNICODE   cmEncoding_AutoEbcdic_And_Unicode
#define VSENCODING_AUTOEBCDIC_AND_UNICODE2   cmEncoding_AutoEbcdic_And_Unicode2

#define VSENCODING_AUTOXML             cmEncoding_AutoXml
#define VSENCODING_AUTOHTML            cmEncoding_AutoHtml
#define VSENCODING_AUTOHTML5           cmEncoding_AutoHtml5
#define VSENCODING_AUTOTEXTUNICODE     cmEncoding_AutoTextUnicode

#define VSENCODING_UTF8                    cmEncoding_Utf8
#define VSENCODING_UTF8_WITH_SIGNATURE     cmEncoding_Utf8WithSignature
#define VSENCODING_UTF16LE                 cmEncoding_Utf16LE
#define VSENCODING_UTF16LE_WITH_SIGNATURE  cmEncoding_Utf16LEWithSignature
#define VSENCODING_UTF16BE                 cmEncoding_Utf16BE
#define VSENCODING_UTF16BE_WITH_SIGNATURE  cmEncoding_Utf16BEWithSignature
#define VSENCODING_UTF32LE                 cmEncoding_Utf32LE
#define VSENCODING_UTF32LE_WITH_SIGNATURE  cmEncoding_Utf32LEWithSignature
#define VSENCODING_UTF32BE                 cmEncoding_Utf32BE
#define VSENCODING_UTF32BE_WITH_SIGNATURE  cmEncoding_Utf32BEWithSignature
#define VSENCODING_MAX                     cmEncoding_Max

// Flags returned by vsFileDetermineEncoding
#define VSFDE_XML_ENCODING_ERROR         0x1


struct VSUTF8_FILEINFO1 {
   union {
      int fh;
      void *puserdata;
   };
   const char *pBuf;
   const char *pEndBuf;
};
struct VSUTF8_FILEINFO2 {
   union {
      int fh;
      void *puserdata;
   };
   const unsigned short *pBuf;
   const unsigned short *pEndBuf;
};
struct VSUTF8_FILEINFO4 {
   union {
      int fh;
      void *puserdata;
   };
   const unsigned *pBuf;
   const unsigned *pEndBuf;
};

struct OPENENCODINGTAB {
   const char *psz;
   const char *pszOption;
   int codePage;
#define OEFLAG_REMOVE_FROM_OPEN  0x1
#define OEFLAG_REMOVE_FROM_SAVEAS 0x2
#define OEFLAG_BINARY             0x4
#define OEFLAG_REMOVE_FROM_DIFF   0x8
#define OEFLAG_REMOVE_FROM_NEW    0x10
//#define OEFLAG_KEEP_FOR_APPEND    0x8
   int OEFlags;
};

/**
 * Reads a UTF-16 or UTF-32 (surrogate) character.  This function does
 * not read composite characters.  This function is faster than the
 * <b>vsUTF16CharRead</b>() function.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param pwBuf	Buffer contain UTF-16 text.
 *
 * @param pwEndBuf	Pointer to end of buffer.
 *
 * @param uch	Recieves UTF-32 character.
 *
 * @categories Unicode_Functions
 *
 */
VSSTATIC inline unsigned short * VSAPI vsUTF16CharRead2(const unsigned short *pwBuf,const unsigned short *pwEndBuf,unsigned &uch)
{
   if (pwBuf>=pwEndBuf) {
      uch= (unsigned)-1;
      return((unsigned short *)pwBuf);
   }
   uch= *pwBuf++;
   if ((uch&0xFC00)!=(unsigned)0xD800) {
      return((unsigned short *)pwBuf);
   }
   if (pwBuf<pwEndBuf && (*pwBuf&0xFC00)==0xDC00) {
      uch=((unsigned)(uch&0x3ff)<<(unsigned)10)+(*pwBuf&(unsigned)0x3ff)+(unsigned)0x10000;
      ++pwBuf;
   }
   return((unsigned short *)pwBuf);
}
/**
 * Reads a multi-byte UTF-8 sequence.  The current byte MUST
 * be >=0x80 and must be readable (i.e. pBuf<pEndBuf).  This
 * function is intended to be used to speed up reading
 * UTF-8 characters.  See example.
 *
 * @example
 *
 * <PRE>
 * void printUTF8String(const char *p,int len)
 * {
 *    const char *pend=p+len;
 *    while (p<pend) {
 *       unsigned uch;
 *       if ((unsigned char)*p<=0x7f) {
 *          uch=(unsigned char)*p;
 *          ++p;
 *       } else {
 *          p=vsUTF8CharRead2(p,pend,uch);
 *       }
 *       printf("uch=%d\n",uch);
 *    }
 * }
 * @param pBuf    Pointer to UTF-8 string
 * @param pEndBuf Pointer past end of UTF-8 string
 * @param uch     Ouput character index.  Set to -1 if character
 *                sequence is truncated (premature end of buffer).
 * @return Returns pointer to next character to read.
 *
 * @categories Unicode_Functions
 */
VSSTATIC inline char *vsUTF8CharRead2(const char *pBuf,const char *pEndBuf,unsigned &uch)
{
   int i= (unsigned char)*pBuf;

   if ((i&0xE0)==0xC0) {   // high bits are 110
      if (pBuf+1>=pEndBuf) {
         uch= (unsigned)-1;
         return((char *)pBuf+1);
      }
      uch= i&0x1f;   // Take 5 bits
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      return((char *)(++pBuf));
   }
   if ((i&0xF0)==0xE0) {  // high bits are 1110
      if (pBuf+2>=pEndBuf) {
         uch= (unsigned)-1;
         return((char *)pBuf+1);
      }
      uch= i&0xf;   // Take 4 bits
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      return((char *)(++pBuf));
   }
   if ((i&0xF8)==0xF0) { // high bits are 11110
      if (pBuf+3>=pEndBuf) {
         uch= (unsigned)-1;
         return((char *)pBuf+1);
      }
      uch= i&0x7;   // Take 3 bits
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      return((char *)(++pBuf));
   }
   if ((i&0xFC)==0xF8) {    // high bits are 111110
      if (pBuf+4>=pEndBuf) {
         uch= (unsigned)-1;
         return((char *)pBuf+1);
      }
      uch= i&0x3;   // Take 2 bits
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      return((char *)(++pBuf));
   }
   if ((i&0xFE)==0xFC) {   // high bits are 1111110
      if (pBuf+5>=pEndBuf) {
         uch= (unsigned)-1;
         return((char *)pBuf+1);
      }
      uch= i&0x1;   // Take 1 bits
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      uch<<=6;
      ++pBuf;
      uch|= (unsigned char)(*pBuf)&0x3f;
      return((char *)(++pBuf));
   }
   uch= (unsigned)-1;
   return((char *)(++pBuf));
}

/**
 * Converts a UTF-32 character range 0x0-0x7fffffff to
 * UTF-8.  The caller must handle converting UTF-16
 * (windows UNICODE) surrogates into the UTF-32 character
 * equivalent.  That is, the caller must convert
 * 0xD800,0x0DC00 to 0x10000.
 *
 * @param wch    UTF-32 character in range 0x0-0x7fffffff.
 * @param pdest  Pointer to UTF-8 destination buffer
 *               Must contain enough space for UTF-8
 *               character.  In the worst case, 6 bytes are
 *               required.
 * @return Returns number of UTF-8 bytes required to encode
 *         the UTF-32 character given.  0 is returned if the UTF-32
 *         character is too large (above 0x7fffffff).
 *
 * @return Returns number of characters written.
 *
 * @categories Unicode_Functions
 *
 */
VSSTATIC inline int vsUTF8CharWrite(unsigned wch,char *pdest)
{
   if (wch<=0x7f) {
      pdest[0]=(char)wch;
      return(1);
   }
   if (wch<=0x7ff) {
      pdest[1]=(char)(wch&0x3f)|0x80;
      pdest[0]=(char)(wch>>6)|0xC0;
      return(2);
   }
   if (wch<=0xffff) {
      pdest[2]=(char)(wch&0x3f)|0x80;
      wch>>=6;
      pdest[1]=(char)(wch&0x3f)|0x80;
      pdest[0]=(char)(wch>>6)|0xE0;
      return(3);
   }
   if (wch<=0x1fffff) {
      pdest[3]=(char)(wch&0x3f)|0x80;
      wch>>=6;
      pdest[2]=(char)(wch&0x3f)|0x80;
      wch>>=6;
      pdest[1]=(char)(wch&0x3f)|0x80;
      pdest[0]=(char)(wch>>6)|0xF0;
      return(4);
   }
   if (wch<=0x3ffffff) {
      pdest[4]=(char)(wch&0x3f)|0x80;
      wch>>=6;
      pdest[3]=(char)(wch&0x3f)|0x80;
      wch=wch>>6;
      pdest[2]=(char)(wch&0x3f)|0x80;
      wch>>=6;
      pdest[1]=(char)(wch&0x3f)|0x80;
      pdest[0]=(char)(wch>>6)|0xF8;
      return(5);
   }
   // Above 31 bits not supported
   if (wch<=0x7fffffff) {
      pdest[5]=(char)(wch&0x3f)|0x80;
      wch>>=6;
      pdest[4]=(char)(wch&0x3f)|0x80;
      wch>>=6;
      pdest[3]=(char)(wch&0x3f)|0x80;
      wch>>=6;
      pdest[2]=(char)(wch&0x3f)|0x80;
      wch>>=6;
      pdest[1]=(char)(wch&0x3f)|0x80;
      pdest[0]=(char)((wch>>6)&0x1)|0xFC;
      return(6);
   }
   return(0);
}


EXTERN_C_BEGIN
/**
 * Reads a UTF-8 character.  This function does not read composite
 * characters.  This function does performs more error checking on the
 * UTF-8 character read than the <b>vsUTF8CharRead2</b>() function.
 * Use the <b>vsUTF8CharRead2</b>() function instead of the this
 * function  for much better performance.
 *
 * @return Returns pointer to the next character to read.
 * @param pBuf	Buffer contain UTF-8 text.
 *
 * @param pEndBuf	Pointer to end of buffer.
 *
 * @param uch	Recieves UTF-32 character.  Set to -1 if the
 * UTF-8 character read is invalid or
 * <i>pBuf</i>>=<i>pEndBuf</i>.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pBuf</i>>=<i>pEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @example
 * <p>Sample callback function:</p>
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead1(VSUTF8_FILEINFO1 *pfile,const
 * char *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(char *)pCurrentPos;
 *       return(1);  // No more data
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(char *)gTempBuffer;
 *    pfile->pEndBuf=(char *)(gTempBuffer+status);
 *    return(status);  // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8CharRead(const char *pBuf,const char *pEndBuf,unsigned &ich,
                            VSUTF8_FILEINFO1 *pfile=0,
                            int (VSAPI *pfnRead)(VSUTF8_FILEINFO1 *pfile,const char *pCurrentPos)=0);
#if SEBIGENDIAN
   #define vsUTF8ConvertUTF32ToUTF8  vsUTF8ConvertUTF32BEToUTF8
   #define vsUTF8ConvertUTF16ToUTF8  vsUTF8ConvertUTF16BEToUTF8
   #define vsUTF8ConvertUTF8ToUTF16  vsUTF8ConvertUTF8ToUTF16BE
   #define vsUTF8ConvertUTF8ToUTF32  vsUTF8ConvertUTF8ToUTF32BE
   #define vsMultiByteConvertMultiByteToUTF16  vsMultiByteConvertMultiByteToUTF16BE
   #define vsMultiByteConvertMultiByteToUTF32  vsMultiByteConvertMultiByteToUTF32BE
   #define vsMultiByteConvertUTF16ToMultiByte vsMultiByteConvertUTF16BEToMultiByte
#else
   #define vsUTF8ConvertUTF32ToUTF8  vsUTF8ConvertUTF32LEToUTF8
   #define vsUTF8ConvertUTF16ToUTF8  vsUTF8ConvertUTF16LEToUTF8
   #define vsUTF8ConvertUTF8ToUTF16  vsUTF8ConvertUTF8ToUTF16LE
   #define vsUTF8ConvertUTF8ToUTF32  vsUTF8ConvertUTF8ToUTF32LE
   #define vsMultiByteConvertMultiByteToUTF16  vsMultiByteConvertMultiByteToUTF16LE
   #define vsMultiByteConvertMultiByteToUTF32  vsMultiByteConvertMultiByteToUTF32LE
   #define vsMultiByteConvertUTF16ToMultiByte vsMultiByteConvertUTF16LEToMultiByte
#endif
/**
 * Converts a UTF-16 little endian text to UTF-8.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param pwBuf	Buffer containing source UTF-16 little
 * endian text.
 *
 * @param pwEndBuf	Pointer to end of buffer.
 *
 * @param pDest	Destination buffer for UTF-8.
 *
 * @param DestLen	Number of bytes allocated to destination
 * buffer. Specify wBuflen*3+6 bytes if you
 * want all UNICODE characters in your buffer
 * converted.
 *
 * @param pNofbytesWritten	Receives number of bytes written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pwBuf</i>>=<i>pwEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.  Currently this
 * parameter is always set to 0.
 *
 * @example
 * <p>Sample callback function:</p>
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead2(VSUTF8_FILEINFO2 *pfile,const
 * unsigned short *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(unsigned short *)pCurrentPos;
 *       return(1);  // no more data.
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(unsigned short *)gTempBuffer;
 *    pfile->pEndBuf=(unsigned short
 * *)(gTempBuffer+(status&0xfffffffe));
 *    return(status);   // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
unsigned short * VSAPI vsUTF8ConvertUTF16LEToUTF8(
                                                    const unsigned short *pwBuf,const unsigned short *pwEndBuf,
                                                    char *pDest,size_t destLen,
                                                    unsigned *pNofBytesWritten=0,
                                                    int *pstatus=0,
                                                    VSUTF8_FILEINFO2 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO2 *pfile,const unsigned short *pCurrentPos)=0,
                                                    int *pXlatError=0);
/**
 * Converts a UTF-32 little endian text to UTF-8.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param pwBuf	Buffer containing source UTF-32 little
 * endian text.
 *
 * @param pwEndBuf	Pointer to end of buffer.
 *
 * @param pDest	Destination buffer for UTF-8.
 *
 * @param DestLen	Number of bytes allocated to destination
 * buffer.  Specify wBuflen*6+10 bytes if you
 * want all UNICODE characters in your buffer
 * converted.
 *
 * @param pNofbytesWritten	Receives number of bytes written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pwBuf</i>>=<i>pwEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.  Currently this
 * parameter is always set to 0.
 *
 * @example
 * <p>Sample callback function:</p>
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead4(VSUTF8_FILEINFO4 *pfile,const
 * unsigned *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(unsigned *)pCurrentPos;
 *       return(1);  // no more data.
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(unsigned *)gTempBuffer;
 *    pfile->pEndBuf=(unsigned *)(gTempBuffer+(status&0xfffffffc));
 *    return(status);   // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
unsigned * VSAPI vsUTF8ConvertUTF32LEToUTF8(
                                              const unsigned *pwBuf,const unsigned *pwEndBuf,
                                              char *pDest,size_t destLen,
                                              unsigned *pNofBytesWritten=0,
                                              int *pstatus=0,
                                              VSUTF8_FILEINFO4 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO4 *pfile,const unsigned *pCurrentPos)=0,
                                              int *pXlatError=0);
/**
 * Converts a UTF-16 big endian text to UTF-8.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param pwBuf	Buffer containing source UTF-16 big endian
 * text.
 *
 * @param pwEndBuf	Pointer to end of buffer.
 *
 * @param pDest	Destination buffer for UTF-8.
 *
 * @param DestLen	Number of bytes allocated to destination
 * buffer. Specify wBuflen*3+6 bytes if you
 * want all UNICODE characters in your buffer
 * converted.
 *
 * @param pNofbytesWritten	Receives number of bytes written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pwBuf</i>>=<i>pwEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.  Currently this
 * parameter is always set to 0.
 *
 * @example
 * <p>Sample callback function:</p>
 *
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead2(VSUTF8_FILEINFO2 *pfile,const
 * unsigned short *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(unsigned short *)pCurrentPos;
 *       return(1);  // no more data.
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(unsigned short *)gTempBuffer;
 *    pfile->pEndBuf=(unsigned short
 * *)(gTempBuffer+(status&0xfffffffe));
 *    return(status);   // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
unsigned short * VSAPI vsUTF8ConvertUTF16BEToUTF8(
                                                    const unsigned short *pwBuf,const unsigned short *pwEndBuf,
                                                    char *pDest,size_t destLen,
                                                    unsigned *pNofBytesWritten=0,
                                                    int *pstatus=0,
                                                    VSUTF8_FILEINFO2 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO2 *pfile,const unsigned short *pCurrentPos)=0,
                                                    int *pXlatError=0);
/**
 * Converts a UTF-32 big endian text to UTF-8.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param pwBuf 	Buffer containing source UTF-32 big endian
 * text.
 *
 * @param pwEndBuf	Pointer to end of buffer.
 *
 * @param pDest	Destination buffer for UTF-8.
 *
 * @param DestLen	Number of bytes allocated to destination
 * buffer.  Specify wBuflen*6+10 bytes if you
 * want all UNICODE characters in your buffer
 * converted.
 *
 * @param pNofbytesWritten	Receives number of bytes written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pwBuf</i>>=<i>pwEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.  Currently this
 * parameter is always set to 0.
 *
 * @example
 * <p>Sample callback function:</p>
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead4(VSUTF8_FILEINFO4 *pfile,const
 * unsigned *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(unsigned *)pCurrentPos;
 *       return(1);  // no more data.
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(unsigned *)gTempBuffer;
 *    pfile->pEndBuf=(unsigned *)(gTempBuffer+(status&0xfffffffc));
 *    return(status);   // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
unsigned * VSAPI vsUTF8ConvertUTF32BEToUTF8(
                                              const unsigned *pwBuf,const unsigned *pwEndBuf,
                                              char *pDest,size_t destLen,
                                              unsigned *pNofBytesWritten=0,
                                              int *pstatus=0,
                                              VSUTF8_FILEINFO4 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO4 *pfile,const unsigned *pCurrentPos)=0,
                                              int *pXlatError=0);
/**
 * Converts UTF-8 text to UTF-16 little endian.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param pBuf	Buffer containing source UTF-8 text.
 *
 * @param pEndBuf	Pointer to end of buffer.
 *
 * @param pwDest	Destination buffer for UTF-16 text.
 *
 * @param wDestLen	Number of characters allocated to
 * destination buffer. Specify BufLen+10
 * characters (BufLen*2+10 bytes) if you want
 * all data converted.
 *
 * @param pNofCharsWritten	Receives number of characters written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pBuf</i>>=<i>pEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.
 *
 * @example
 * <p>Sample callback function:</p>
 *
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead1(VSUTF8_FILEINFO1 *pfile,const
 * char *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(char *)pCurrentPos;
 *       return(1);  // No more data
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(char *)gTempBuffer;
 *    pfile->pEndBuf=(char *)(gTempBuffer+status);
 *    return(status);  // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8ConvertUTF8ToUTF16LE(
                                          const char *pBuf,const char *pEndBuf,
                                          unsigned short *pwDest,size_t wDestLen,
                                          unsigned *pNofCharsWritten,
                                          int *pstatus=0,
                                          VSUTF8_FILEINFO1 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO1 *pfile,const char *pCurrentPos)=0,
                                          int *pXlatError=0);
/**
 * Converts UTF-8 text to UTF-32 little endian.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param pBuf	Buffer containing source UTF-8 text.
 *
 * @param pEndBuf	Pointer to end of buffer.
 *
 * @param pwDest	Destination buffer for UTF-32 text.
 *
 * @param wDestLen	Number of characters allocated to
 * destination buffer. Specify BufLen+20
 * characters (BufLen*4+20 bytes) if you want
 * all data converted.
 *
 * @param pNofCharsWritten	Receives number of characters written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pBuf</i>>=<i>pEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.
 *
 * @example
 * <pre>
 * Sample callback function:
 *
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead1(VSUTF8_FILEINFO1 *pfile,const
 * char *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(char *)pCurrentPos;
 *       return(1);  // No more data
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(char *)gTempBuffer;
 *    pfile->pEndBuf=(char *)(gTempBuffer+status);
 *    return(status);  // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8ConvertUTF8ToUTF32LE(
                                          const char *pBuf,const char *pEndBuf,
                                          unsigned *pwDest,size_t wDestLen,
                                          unsigned *pNofCharsWritten,
                                          int *pstatus=0,
                                          VSUTF8_FILEINFO1 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO1 *pfile,const char *pCurrentPos)=0,
                                          int *pXlatError=0);
/**
 * Converts UTF-8 text to UTF-16 big endian.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param pBuf	Buffer containing source UTF-8 text.
 *
 * @param pEndBuf	Pointer to end of buffer.
 *
 * @param pwDest	Destination buffer for UTF-16 text.
 *
 * @param wDestLen	Number of characters allocated to
 * destination buffer.  Specify BufLen+10
 * characters (BufLen*2+10 bytes) if you want
 * all data converted.
 *
 * @param pNofCharsWritten	Receives number of characters written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pBuf</i>>=<i>pEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.
 *
 * @example
 * <p>Sample callback function:</p>
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead1(VSUTF8_FILEINFO1 *pfile,const
 * char *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(char *)pCurrentPos;
 *       return(1);  // No more data
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(char *)gTempBuffer;
 *    pfile->pEndBuf=(char *)(gTempBuffer+status);
 *    return(status);  // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8ConvertUTF8ToUTF16BE(
                                          const char *pBuf,const char *pEndBuf,
                                          unsigned short *pwDest,size_t wDestLen,
                                          unsigned *pNofCharsWritten,
                                          int *pstatus=0,
                                          VSUTF8_FILEINFO1 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO1 *pfile,const char *pCurrentPos)=0,
                                          int *pXlatError=0);
/**
 * @return Returns pointer to the next character to read.
 *
 * @param pBuf	Buffer containing source UTF-8 text.
 *
 * @param pEndBuf	Pointer to end of buffer.
 *
 * @param pwDest	Destination buffer for UTF-32 text.
 *
 * @param wDestLen	Number of characters allocated to
 * destination buffer.  Specify BufLen+20
 * characters (BufLen*4+20 bytes) if you want
 * all data converted.
 *
 * @param pNofCharsWritten	Receives number of characters written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pBuf</i>>=<i>pEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.
 *
 * Converts UTF-8 text to UTF-32 big endian.
 *
 * @example
 * <p>Sample callback function:</p>
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead1(VSUTF8_FILEINFO1 *pfile,const
 * char *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(char *)pCurrentPos;
 *       return(1);  // No more data
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(char *)gTempBuffer;
 *    pfile->pEndBuf=(char *)(gTempBuffer+status);
 *    return(status);  // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8ConvertUTF8ToUTF32BE(
                                          const char *pBuf,const char *pEndBuf,
                                          unsigned *pwDest,size_t wDestLen,
                                          unsigned *pNofCharsWritten,
                                          int *pstatus=0,
                                          VSUTF8_FILEINFO1 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO1 *pfile,const char *pCurrentPos)=0,
                                          int *pXlatError=0);
/**
 * Converts UTF-8 text to upper case.  Under Windows, this
 * function relies on the WIN32 function CharUpperBuffW
 * which only support characters below 65536.  Characters
 * above 65537 are not changed.
 *
 * @param p 	   Buffer to convert.
 *
 * @param buflen	Length of buffer to convert.
 *
 * @from pic.doc
 *
 * @categories Unicode_Functions
 *
 */
void VSAPI vsUTF8Upcase(char *p,size_t buflen);
/**
 * Converts UTF-8 text to lower case.  Under Windows, this function
 * relies on the WIN32 function CharLowerBuffW which only support
 * characters below 65536.  Characters above 65537 are not changed.
 *
 * @param p    	Buffer to convert.
 *
 * @param buflen	Length of buffer to convert.
 *
 * @categories Unicode_Functions
 *
 */
void VSAPI vsUTF8Lowcase(char *p,size_t buflen);
/**
 * Converts UTF-8 text to toggle case character by character. 
 * Characters above 65537 are not changed. 
 *
 * @param p    	Buffer to convert.
 *
 * @param buflen	Length of buffer to convert.
 *
 * @categories Unicode_Functions
 *
 */
void VSAPI vsUTF8Togglecase(char *p,size_t buflen);
/**
 * Reverse UTF-8 characters in string.
 *
 * @param p    	Buffer to convert.
 *
 * @param buflen	Length of buffer to convert.
 *
 * @categories Unicode_Functions
 *
 */
void VSAPI vsUTF8Reverse(char *p,size_t buflen);

/**
 * Converts UTF-8 text to multi-byte (SBCS/DBCS code page data).
 *
 * @return Returns pointer to the next character to read.
 *
 * @param codePage	Indicates the code page for the output data.
 * One of following code pages:
 *
 * <ul>
 * <li>VSCP_ACTIVE_CODEPAGE</li>
 * <li>VSCP_CYRILLIC_KOI8_R</li>
 * <li>VSCP_ISO_8859_1</li>
 * <li>VSCP_ISO_8859_2</li>
 * <li>VSCP_ISO_8859_3</li>
 * <li>VSCP_ISO_8859_4</li>
 * <li>VSCP_ISO_8859_5</li>
 * <li>VSCP_ISO_8859_6</li>
 * <li>VSCP_ISO_8859_7</li>
 * <li>VSCP_ISO_8859_8 </li>
 * <li>VSCP_ISO_8859_9</li>
 * <li>VSCP_ISO_8859_10</li>
 * <li>Any valid Windows code page</li>
 * </ul>
 *
 * @param pBuf	Buffer containing source UTF-8 text.
 *
 * @param pEndBuf	Pointer to end of buffer.
 *
 * @param pDest 	Destination buffer for multi-byte text.
 *
 * @param DestLen	Number of bytes allocated to destination
 * buffer. Specify BufLen+2 bytes if you want
 * all UTF-8 bytes in your buffer converted.
 *
 * @param pNofbytesWritten	Receives number of bytes written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pBuf</i>>=<i>pEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.
 *
 * @example
 * <p>Sample callback function:</p>
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead1(VSUTF8_FILEINFO1 *pfile,const
 * char *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(char *)pCurrentPos;
 *       return(1);  // No more data
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(char *)gTempBuffer;
 *    pfile->pEndBuf=(char *)(gTempBuffer+status);
 *    return(status);  // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8ConvertUTF8ToMultiByte(int codePage,
                                         const char *pBuf,const char *pEndBuf,
                                         char *pDest,size_t DestLen,
                                         unsigned *pNofBytesWritten=0,
                                         int *pstatus=0,
                                         VSUTF8_FILEINFO1 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO1 *pfile,const char *pCurrentPos)=0,
                                          int *pXlatError=0);
/**
 * Converts a multi-byte (SBCS/DBCS code page data) text to UTF-8.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param codePage	Indicates the code page for the source data.
 * One of following code pages:
 *
 * <ul>
 * <li>VSCP_ACTIVE_CODEPAGE</li>
 * <li>VSCP_CYRILLIC_KOI8_R</li>
 * <li>VSCP_ISO_8859_1</li>
 * <li>VSCP_ISO_8859_2</li>
 * <li>VSCP_ISO_8859_3</li>
 * <li>VSCP_ISO_8859_4</li>
 * <li>VSCP_ISO_8859_5</li>
 * <li>VSCP_ISO_8859_6</li>
 * <li>VSCP_ISO_8859_7</li>
 * <li>VSCP_ISO_8859_8 </li>
 * <li>VSCP_ISO_8859_9</li>
 * <li>VSCP_ISO_8859_10</li>
 * <li>Any valid Windows code page</li>
 * </ul>
 *
 * @param pBuf	Buffer containing source multi-byte text.
 *
 * @param pEndBuf	Pointer to end of buffer.
 *
 * @param pDest	Destination buffer for UTF-8.
 *
 * @param DestLen	Number of bytes allocated to destination
 * buffer.  For code pages that produce 21-bit
 * UNICODE, specify BufLen*3+6 bytes if
 * you want all UTF-8 bytes in your buffer
 * converted.
 *
 * @param pNofbytesWritten	Receives number of bytes written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pBuf</i>>=<i>pEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.
 *
 * @example
 * <p>Sample callback function:</p>
 *
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead1(VSUTF8_FILEINFO1 *pfile,const
 * char *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(char *)pCurrentPos;
 *       return(1);  // No more data
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(char *)gTempBuffer;
 *    pfile->pEndBuf=(char *)(gTempBuffer+status);
 *    return(status);  // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8ConvertMultiByteToUTF8(int codePage,
                                         const char *pBuf,const char *pEndBuf,
                                         char *pDest,size_t DestLen,
                                         unsigned *pNofBytesWritten=0,
                                         int *pstatus=0,
                                         VSUTF8_FILEINFO1 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO1 *pfile,const char *pCurrentPos)=0,
                                          int *pXlatError=0);
/**
 * This function is used to convert one of the
 * VSENCODING_AUTO<XXX> encoding options into an exact
 * encoding.  All other values for encoding remain unchanged.
 *
 * @return Returns 0 or positive number if successful.  Otherwise, a negative
 * error code is returned.
 *
 * @param filehandle	File handle returned by
 * <b>vsFileOpen</b>().
 *
 * @param encoding	On input this is one of the following:
 *
 * <ul>
 * <li>VSCP_ACTIVE_CODEPAGE</li>
 * <li>VSCP_CYRILLIC_KOI8_R</li>
 * <li>VSCP_ISO_8859_1</li>
 * <li>VSCP_ISO_8859_2</li>
 * <li>VSCP_ISO_8859_3</li>
 * <li>VSCP_ISO_8859_4</li>
 * <li>VSCP_ISO_8859_5</li>
 * <li>VSCP_ISO_8859_6</li>
 * <li>VSCP_ISO_8859_7</li>
 * <li>VSCP_ISO_8859_8 </li>
 * <li>VSCP_ISO_8859_9</li>
 * <li>VSCP_ISO_8859_10</li>
 * <li>Any valid Windows code page</li>
 * <li>VSENCODING_AUTOUNICODE</li>
 * <li>VSENCODING_AUTOUNICODE2</li>
 * <li>VSENCODING_AUTOXML</li>
 * <li>VSENCODING_AUTOEBCDIC</li>
 * <li>VSENCODING_AUTOEBCDIC_AND_UNICODE</li>
 * <li>VSENCODING_AUTOEBCDIC_AND_UNICODE2</li>
 * <li>VSENCODING_EBCDIC_SBCS</li>
 * <li>VSENCODING_UTF8</li>
 * <li>VSENCODING_UTF8_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF16LE</li>
 * <li>VSENCODING_UTF16LE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF16BE</li>
 * <li>VSENCODING_UTF16BE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF32LE</li>
 * <li>VSENCODING_UTF32LE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF32BE</li>
 * <li>VSENCODING_UTF32BE_WITH_SIGNATURE -
 * 	This is set to exact encoding that should be
 * used.</li>
 * </ul>
 *
 * @categories Unicode_Functions
 *
 */
int VSAPI vsFileDetermineEncoding(int filehandle,int &encoding);
int VSAPI vsFileDetermineEncodingFromBuffer(char* buffer,int NofBytes,VSINT64 filesize,int &encoding);
/**
 * Reads the file and converts the data from the encoding specified to
 * UTF-8.
 *
 * @return Returns number of bytes read if successful.  0 is returned when there's
 * no more data to be read.  Otherwise, a negative error code is returned.
 *
 * @param filehandle	File handle returned from
 * <b>vsFileOpen</b>().
 *
 * @param pbuf	Destination buffer for UTF-8 data.
 *
 * @param bufsize	Number of bytes allocated to destination
 * buffer.
 *
 * @param encoding	One of the following encodings:
 *
 * <ul>
 * <li>VSCP_ACTIVE_CODEPAGE</li>
 * <li>VSCP_CYRILLIC_KOI8_R</li>
 * <li>VSCP_ISO_8859_1</li>
 * <li>VSCP_ISO_8859_2</li>
 * <li>VSCP_ISO_8859_3</li>
 * <li>VSCP_ISO_8859_4</li>
 * <li>VSCP_ISO_8859_5</li>
 * <li>VSCP_ISO_8859_6</li>
 * <li>VSCP_ISO_8859_7</li>
 * <li>VSCP_ISO_8859_8 </li>
 * <li>VSCP_ISO_8859_9</li>
 * <li>VSCP_ISO_8859_10</li>
 * <li>Any valid Windows code page</li>
 * <li>VSENCODING_UTF8</li>
 * <li>VSENCODING_UTF8_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF16LE</li>
 * <li>VSENCODING_UTF16LE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF16BE</li>
 * <li>VSENCODING_UTF16BE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF32LE</li>
 * <li>VSENCODING_UTF32LE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF32BE</li>
 * <li>VSENCODING_UTF32BE_WITH_SIGNATURE</li>
 * </ul>
 *
 * @param readFirstBuffer	Indicates whether this is the first read after
 * opening the file.  When this is non-zero and
 * the encoding given has a signature, the
 * signature is skipped.
 *
 * @param pXlatError	Set to 1 if a translation error occurs.
 *
 * @categories Unicode_Functions
 *
 */
int VSAPI vsUTF8FileRead(
   int filehandle,void *pbuf,int bufsize,int encoding,
   int readFirstBuffer,
   int *pXlatError=0);
/**
 * @return Returns the active code page.  This result can be used in any function
 * which accepts a code page.
 *
 * @categories Unicode_Functions
 *
 */
int VSAPI vsGetACP();
/**
 * @return Returns pointer to the beginning of the next composite character or
 * <i>pEndBuf</i>  if <i>pCurrent</i>==<i>pEndBuf</i>.
 *
 * @param pBuf 	Buffer contain UTF-8 text.
 *
 * @param pEndBuf	Pointer to end of pBuf text where
 * <i>pEndBuf</i>-<i>pCurrent</i> is the
 * buffer length.
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8CharNext(const char *pBuf,const char *pEndBuf);

/**
 * @return Returns pointer to the beginning of the next UTF-8 character or
 * <i>pEndBuf</i>  if <i>pCurrent</i>==<i>pEndBuf</i>.  Use {@link vsUTF8CharNext},
 * to skip composite characters.
 *
 * @param pCurrent	Buffer contain UTF-8 text.
 *
 * @param pEndBuf	Pointer to end of pBuf text where
 * pEndBuf</i>-<i>pCurrent</i> is the
 * buffer length.
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8CharNext2(const char *pBuf,const char *pEndBuf);

/**
 * Reads the previous UTF-8 character.  This function does not read
 * composite characters.
 *
 * @param pLine	Buffer contain UTF-8 text.
 *
 * @param pCurrent	Pointer to current character in <i>pLine</i>.
 *
 * @param uch	Recieves UTF-32 character.
 *
 * @return Returns pointer to the previous character.
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8CharReadPrev(const char *pLine,const char *pCurrent, unsigned &uch);
/**
 * @return Returns pointer to the beginning of the previous composite character
 * or <i>pLine</i>  if <i>pCurrent</i>==<i>pLine</i>.
 *
 * @param pLine	Buffer contain UTF-8 text.
 *
 * @param pCurrent	Pointer to the beginning of a UTF-8
 * character in <i>pLine</i>.
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8CharPrev(const char *pLine,const char *pCurrent);

char * VSAPI vsMultiByteToUTF8(const char *pBuf,int BufLen=-1,int *pDestLen=0,int i=0,int codePage=VSCP_ACTIVE_CODEPAGE);
/**
 * Converts a UTF-8 text to multi-byte.  To free the memory allocated by
 * this function, specify 0 for <i>pBuf</i>, -1 for <i>BufLen</i>,
 * anything for <i>DestLen</i>, and the correct destination temp buffer.
 * There is typically no need to free the memory allocated by this
 * function unless you converted a very large amount of data.
 *
 * @return Returns pointer to null terminated multi-byte string.
 *
 * @param pBuf	Input UTF-8 buffer.
 *
 * @param BufLen	Length of buffer.  Specify -1 to compute
 * length from a null terminated buffer.
 *
 * @param pDestLen	Length of resulting multi-byte string.
 *
 * @param i	Destination temp buffer index where
 * 0&lt;=i&lt;=9.  This allows you to call this
 * function multiple times without the previous
 * result being overwritten by the new result.
 *
 * @param codePage	One of the following code pages:
 *
 * <ul>
 * <li>VSCP_ACTIVE_CODEPAGE</li>
 * <li>VSCP_CYRILLIC_KOI8_R</li>
 * <li>VSCP_ISO_8859_1</li>
 * <li>VSCP_ISO_8859_2</li>
 * <li>VSCP_ISO_8859_3</li>
 * <li>VSCP_ISO_8859_4</li>
 * <li>VSCP_ISO_8859_5</li>
 * <li>VSCP_ISO_8859_6</li>
 * <li>VSCP_ISO_8859_7</li>
 * <li>VSCP_ISO_8859_8 </li>
 * <li>VSCP_ISO_8859_9</li>
 * <li>VSCP_ISO_8859_10</li>
 * <li>Any valid Windows code page</li>
 * </ul>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8ToMultiByte(const char *pBuf,int BufLen=-1,int *pDestLen=0,int i=0,int codePage=VSCP_ACTIVE_CODEPAGE);
/**
 * Converts a UTF-8 text to UTF-16.  To free the memory allocated by
 * this function, specify 0 for <i>pBuf</i>, -1 for <i>BufLen</i>,
 * anything for <i>DestLen</i>, and the correct destination temp buffer.
 * There is typically no need to free the memory allocated by this
 * function unless you converted a very large amount of data.
 *
 * @return Returns pointer to null terminated UTF-16 string.
 *
 * @param pBuf	Input UTF-8 buffer.
 *
 * @param BufLen	Length of buffer.  Specify -1 to compute
 * length from a null terminated buffer.
 *
 * @param pDestLen	Length of resulting UTF-16 string.
 *
 * @param i	Destination temp buffer index where
 * 0&lt;=i&lt;=9.  This allows you to call this
 * function multiple times without the previous
 * result being overwritten by the new result.
 *
 * @categories Unicode_Functions
 *
 */
unsigned short * VSAPI vsUTF8ToUTF16(const char *pBuf,int BufLen=-1,int *pDestLen=0,int i=0);
char * VSAPI vsUnicodeToUTF8(int SrcEncoding,const void *pBuf,int BufLen=-1,int *pDestLen=0,int i=0);
/**
 * Converts a UTF-16 to UTF-8.  To free the memory allocated by this
 * function, specify 0 for <i>pBuf</i>, -1 for <i>BufLen</i>, anything
 * for <i>DestLen</i>, and the correct destination temp buffer.  There is
 * typically no need to free the memory allocated by this function unless
 * you converted a very large amount of data.
 *
 * @return Returns pointer to null terminated UTF-8 string.
 *
 * @param pBuf	Input UTF-16 buffer.
 *
 * @param BufLen	Length of buffer.  Specify -1 to compute
 * length from a null terminated buffer.
 *
 * @param pDestLen	Length of resulting UTF-8 string.
 *
 * @param i	Destination temp buffer index where
 * 0&lt;=i&lt;=9.  This allows you to call this
 * function multiple times without the previous
 * result being overwritten by the new result.
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF16ToUTF8(const unsigned short *pBuf,int BufLen=-1,int *pDestLen=0,int i=0);
unsigned * VSAPI vsUTF8ToUTF32(const char *pBuf,int BufLen=-1,int *pDestLen=0,int i=0);
unsigned short * VSAPI vsMultiByteToUTF16(const char *pBuf,int BufLen,int *pDestLen=0,int i=0,int codePage=0);
char * VSAPI vsUTF16ToMultiByte(const unsigned short *pBuf,int BufLen=-1,int *pDestLen=0,int i=0,int codePage=0);
//int VSAPI vsUTF8BufXlatRequired(int wid);
/**
 * @return Returns non-zero value if the code page given is available.   When a
 * code page is not available, it can't be used as input to a function which
 * accepts a code page parameter.
 *
 * @categories Unicode_Functions
 *
 */
int VSAPI vsIsCodePageAvailable(int codePage);
/**
 * @return Returns non-zero value if <i>encoding</i> is a code page and not one
 * of the VSENCODING_* constants.
 *
 * @categories Unicode_Functions
 *
 */
int VSAPI vsIsCodePage(int encoding);
//int VSAPI vsUTF8UTF32CharMaybeTrailChar(unsigned uch);
/**
 * Finds the beginning of the current composite character or UTF-8
 * character.
 *
 * @return Returns pointer to the beginning of the current composite or UTF-8
 * character.   <i>pCurrent</i> is returned if <i>pCurrent</i>
 * >=<i>pBuf</i>+<i>BufLen</i>.
 *
 * @param pBuf	Buffer contain UTF-8 text.
 *
 * @param BufLen	Number of UTF-8 characters in pBuf.
 * Specify -1 to compute the length from a null
 * terminated buffer.
 *
 * @param pCurrent	Pointer to UTF-8 character in pBuf.
 *
 * @param pCharLen	Set to number of bytes in the current
 * character.
 *
 * @param beginComposite	When non-zero, finds the beginning of the
 * composite character.
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8CharBegin(const char *pBuf,int BufLen,
                             const char *pCurrent,
                             int *pCharLen=0,int beginComposite=1);
/**
 * Finds the beginning of the current UTF-8 character.
 *
 * @return Returns pointer to the beginning of the UTF-8 character.
 * <i>pCurrent</i> is returned if <i>pCurrent</i>
 * >=<i>pBuf</i>+<i>BufLen</i>.
 *
 * @param pBuf	Buffer contain UTF-8 text.
 *
 * @param BufLen	Number of UTF-8 characters in pBuf.
 * Specify -1 to compute the length from a null
 * terminated buffer.
 *
 * @param pCurrent	Pointer to UTF-8 character in pBuf.
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8CharBegin2(const char *pBuf,int BufLen,const char *pCurrent);
/**
 * Converts string to upper case.
 *
 * @param pString	Input <i>string</i>.
 *
 * @param StringLen	Number of bytes in <i>pString</i>.  If
 * <i>pString</i> is null terminated, you can
 * specify -1 for the length of string.
 *
 * @param utf8 -1 specifies that input and output string
 * are UTF-8 if UTF-8 support is enabled.  0
 * specifies that the input and output string are
 * SBCS/DBCS.  1 specifies that the input and
 * output string are UTF-8.
 *
 * @see vsLowcase
 *
 * @categories String_Functions, Unicode_Functions
 *
 */
char * VSAPI vsUpcase(char *pString,int StringLen= -1,int utf8= -1);
/**
 * Converts string to lower case.
 *
 * @param pString	Input string.
 *
 * @param StringLen	Number of bytes in <i>pString</i>.  Specify
 * -1 to determine length of string if string is
 * null terminated.
 *
 * @param utf8	-1 specifies that input and output string
 * are UTF-8 if UTF-8 support is enabled.  0
 * specifies that the input and output string are
 * SBCS/DBCS.  1 specifies that the input and
 * output string are UTF-8.
 *
 * @see vsUpcase
 *
 * @categories String_Functions, Unicode_Functions
 *
 */
char * VSAPI vsLowcase(char *pString,int StringLen= -1,int utf8= -1);
/**
 * Toggles case on all characters.
 *
 * @param pString	Input <i>string</i>.
 *
 * @param StringLen	Number of bytes in <i>pString</i>.  If
 * <i>pString</i> is null terminated, you can
 * specify -1 for the length of string.
 *
 * @param utf8 -1 specifies that input and output string
 * are UTF-8 if UTF-8 support is enabled.  0
 * specifies that the input and output string are
 * SBCS/DBCS.  1 specifies that the input and
 * output string are UTF-8.
 *
 * @see vsLowcase
 *
 * @categories String_Functions, Unicode_Functions
 *
 */
char * VSAPI vsTogglecase(char *pString,int StringLen= -1,int utf8= -1);
/**
 * Reverse characters in string.
 *
 * @param pString	Input <i>string</i>.
 *
 * @param StringLen	Number of bytes in <i>pString</i>.  If
 * <i>pString</i> is null terminated, you can
 * specify -1 for the length of string.
 *
 * @param utf8 -1 specifies that input and output string
 * are UTF-8 if UTF-8 support is enabled.  0
 * specifies that the input and output string are
 * SBCS/DBCS.  1 specifies that the input and
 * output string are UTF-8.
 *
 * @categories String_Functions, Unicode_Functions
 *
 */
char * VSAPI vsStrRev(char *pString,int StringLen= -1,int utf8= -1);
/**
 * Reads a UTF-16 or UTF-32 (surrogate) character.  This function does
 * not read composite characters.  This function is slower than the
 * <b>vsUTF16CharRead2</b>() function.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param pwBuf	Buffer contain UTF-16 text.
 *
 * @param pwEndBuf	Pointer to end of buffer.
 *
 * @param uch	Recieves UTF-32 character.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pwBuf</i>>=<i>pwEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @example
 * <p>Sample callback function:</p>
 *
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead2(VSUTF8_FILEINFO2 *pfile,const
 * unsigned short *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(unsigned short *)pCurrentPos;
 *       return(1);  // no more data.
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(unsigned short *)gTempBuffer;
 *    pfile->pEndBuf=(unsigned short
 * *)(gTempBuffer+(status&0xfffffffe));
 *    return(status);   // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
unsigned short * VSAPI vsUTF16CharRead(const unsigned short *pwBuf,const unsigned short *pwEndBuf,unsigned &uch,
                            VSUTF8_FILEINFO2 *pfile=0,
                            int (VSAPI *pfnRead)(VSUTF8_FILEINFO2 *pfile,const unsigned short *pCurrentPos)=0);
/**
 * @return Returns pointer to the beginning of the next composite or surrogate
 * character or <i>pEndBuf</i>  if <i>pCurrent</i>==<i>pEndBuf</i>.
 *
 * @param pCurrent	Buffer contain UTF-16 text.
 *
 * @param pEndBuf	Pointer to end of pBuf text where
 * <i>pEndBuf</i>-<i>pCurrent</i> is the
 * buffer length.
 *
 * @categories Unicode_Functions
 *
 */
unsigned short * VSAPI vsUTF16CharNext(const unsigned short *pCurrent,const unsigned short *pEndBuf);
/**
 * Reads the previous UTF-16 or UTF-32 (surrogate) character.  This
 * function does not read composite characters.
 *
 * @return Returns pointer to the previous character.
 *
 * @param pLine	Buffer contain UTF-16 text.
 *
 * @param pCurrent	Pointer to current character in <i>pLine</i>.
 *
 * @param uch	Recieves UTF-32 character.
 *
 * @categories Unicode_Functions
 *
 */
unsigned short * VSAPI vsUTF16CharReadPrev(const unsigned short *pLine,const unsigned short *pCurrent, unsigned &uch);
/**
 * @return Returns pointer to the beginning of the previous composite or
 * surrogate character or <i>pLine</i>  if
 * <i>pCurrent</i>==<i>pLine</i>.
 *
 * @param pLine	Buffer contain UTF-16 text.
 *
 * @param pCurrent	Pointer to the beginning of a UTF-16
 * character in <i>pLine</i>.
 *
 * @categories Unicode_Functions
 *
 */
unsigned short * VSAPI vsUTF16CharPrev(const unsigned short *pLine,const unsigned short *pCurrent);
/**
 * @return Returns non-zero value if the UTF-8 character is a letter.  Otherwise, 0
 * is returned.
 *
 * @param p	Pointer to UTF-8 character
 *
 * @param pend	Pointer to end of UTF-8 source buffer.
 *
 * @param plen	Set to number of bytes in UTF-8 character
 * read.
 *
 * @categories Unicode_Functions
 *
 */
int VSAPI vsUTF8IsAlpha(const char *p,const char *pend,int *plen);
/**
 * @return Returns non-zero value if the UTF-8 character is a upper case letter.
 * Otherwise, 0 is returned.
 *
 * @param p	Pointer to UTF-8 character
 *
 * @param pend	Pointer to end of UTF-8 source buffer.
 *
 * @param plen	Set to number of bytes in UTF-8 character
 * read.
 *
 * @categories Unicode_Functions
 *
 */
int VSAPI vsUTF8IsUpper(const char *p,const char *pend,int *plen);
/**
 * @return Returns non-zero value if the UTF-8 character is a lower case letter.
 * Otherwise, 0 is returned.
 *
 * @param p	Pointer to UTF-8 character
 *
 * @param pend	Pointer to end of UTF-8 source buffer.
 *
 * @param plen	Set to number of bytes in UTF-8 character
 * read.
 *
 * @categories Unicode_Functions
 *
 */
int VSAPI vsUTF8IsLower(const char *p,const char *pend,int *plen);


/**
 * Converts multi-byte text to UTF-16 little endian.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param pBuf	Buffer containing source multi-byte text.
 *
 * @param pEndBuf	Pointer to end of buffer.
 *
 * @param pwDest	Destination buffer for UTF-16 text.
 *
 * @param wDestLen	Number of characters allocated to
 * destination buffer. Specify wBufLen+4
 * characters (BufLen*2+4 bytes) if you want
 * all data converted.
 *
 * @param pNofCharsWritten	Receives number of characters written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pBuf</i>>=<i>pEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.
 *
 * @example
 * <p>Sample callback function:</p>
 *
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead1(VSUTF8_FILEINFO1 *pfile,const
 * char *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(char *)pCurrentPos;
 *       return(1);  // No more data
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(char *)gTempBuffer;
 *    pfile->pEndBuf=(char *)(gTempBuffer+status);
 *    return(status);  // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsMultiByteConvertMultiByteToUTF16LE(int codePage,
                                       const char *pBuf,const char *pEndBuf,
                                       unsigned short *pwDest,size_t wDestLen,
                                       unsigned *pNofCharsWritten=0,
                                       int *pstatus=0,
                                       VSUTF8_FILEINFO1 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO1 *pfile,const char *pCurrentPos)=0,
                                                  int *pXlatError=0);
/**
 * Converts multi-byte text to UTF-16 big endian.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param pBuf	Buffer containing source multi-byte text.
 *
 * @param pEndBuf	Pointer to end of buffer.
 *
 * @param pwDest	Destination buffer for UTF-16 text.
 *
 * @param wDestLen	Number of characters allocated to
 * destination buffer. Specify wBufLen+4
 * characters (BufLen*2+4 bytes) if you want
 * all data converted.
 *
 * @param pNofCharsWritten	Receives number of characters written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pBuf</i>>=<i>pEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.
 *
 * @example
 * <p>Sample callback function:</p>
 *
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead1(VSUTF8_FILEINFO1 *pfile,const
 * char *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(char *)pCurrentPos;
 *       return(1);  // No more data
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(char *)gTempBuffer;
 *    pfile->pEndBuf=(char *)(gTempBuffer+status);
 *    return(status);  // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsMultiByteConvertMultiByteToUTF16BE(int codePage,
                                       const char *pBuf,const char *pEndBuf,
                                       unsigned short *pwDest,size_t wDestLen,
                                       unsigned *pNofCharsWritten=0,
                                       int *pstatus=0,
                                       VSUTF8_FILEINFO1 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO1 *pfile,const char *pCurrentPos)=0,
                                       int *pXlatError=0);
/**
 * Converts multi-byte text to UTF-32 big endian.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param pBuf	Buffer containing source multi-byte text.
 *
 * @param pEndBuf	Pointer to end of buffer.
 *
 * @param pwDest	Destination buffer for UTF-32 text.
 *
 * @param wDestLen	Number of characters allocated to
 * destination buffer.  Specify uBufLen+2
 * characters (BufLen*4+8 bytes) if you want
 * all data converted.
 *
 * @param pNofCharsWritten	Receives number of characters written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pBuf</i>>=<i>pEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.
 *
 * @example
 * <p>Sample callback function:</p>
 *
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead1(VSUTF8_FILEINFO1 *pfile,const
 * char *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(char *)pCurrentPos;
 *       return(1);  // No more data
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(char *)gTempBuffer;
 *    pfile->pEndBuf=(char *)(gTempBuffer+status);
 *    return(status);  // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsMultiByteConvertMultiByteToUTF32BE(int codePage,
                                       const char *pBuf,const char *pEndBuf,
                                       unsigned *pwDest,size_t wDestLen,
                                       unsigned *pNofCharsWritten=0,
                                       int *pstatus=0,
                                       VSUTF8_FILEINFO1 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO1 *pfile,const char *pCurrentPos)=0,
                                       int *pXlatError=0);
/**
 * Converts multi-byte text to UTF-32 little endian.
 *
 * @return Returns pointer to the next character to read.
 *
 * @param pBuf	Buffer containing source multi-byte text.
 *
 * @param pEndBuf	Pointer to end of buffer.
 *
 * @param pwDest	Destination buffer for UTF-32 text.
 *
 * @param wDestLen	Number of characters allocated to
 * destination buffer. Specify uBufLen+2
 * characters (BufLen*4+8 bytes) if you want
 * all data converted.
 *
 * @param pNofCharsWritten	Receives number of characters written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pBuf</i>>=<i>pEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs while
 * translating the data.
 *
 * @example
 * <p>Sample callback function:</p>
 *
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead1(VSUTF8_FILEINFO1 *pfile,const
 * char *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(char *)pCurrentPos;
 *       return(1);  // No more data
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(char *)gTempBuffer;
 *    pfile->pEndBuf=(char *)(gTempBuffer+status);
 *    return(status);  // 0 for success, negative number for error.
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsMultiByteConvertMultiByteToUTF32LE(int codePage,
                                       const char *pBuf,const char *pEndBuf,
                                       unsigned *pwDest,size_t wDestLen,
                                       unsigned *pNofCharsWritten=0,
                                       int *pstatus=0,
                                       VSUTF8_FILEINFO1 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO1 *pfile,const char *pCurrentPos)=0,
                                       int *pXlatError=0);
#if SEBIGENDIAN
   char * VSAPI vsMultiByteConvertUTF16BEToMultiByte(
      int codePage,
      const unsigned short *pBuf,const unsigned short *pEndBuf,
      char *pDest,size_t destLen,
      unsigned *pNofBytesWritten=0,
      int *pstatus=0,
      VSUTF8_FILEINFO2 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO2 *pfile,const unsigned short *pCurrentPos)=0,
      int *pXlatError=0);
#else
   char * VSAPI vsMultiByteConvertUTF16LEToMultiByte(
      int codePage,
      const unsigned short *pBuf,const unsigned short *pEndBuf,
      char *pDest,size_t destLen,
      unsigned *pNofBytesWritten=0,
      int *pstatus=0,
      VSUTF8_FILEINFO2 *pfile=0,int (VSAPI *pfnRead)(VSUTF8_FILEINFO2 *pfile,const unsigned short *pCurrentPos)=0,
      int *pXlatError=0);
#endif
/**
 * Converts the data from the multi-byte code page specified to the
 * encoding specified UTF-8.
 *
 * @return Returns pointer to next character to read.
 *
 * @param destEncoding	One of the following encodings:
 *
 * <ul>
 * <li>VSENCODING_UTF16LE</li>
 * <li>VSENCODING_UTF16LE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF16BE</li>
 * <li>VSENCODING_UTF16BE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF32LE</li>
 * <li>VSENCODING_UTF32LE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF32BE</li>
 * <li>VSENCODING_UTF32BE_WITH_SIGNATURE</li>
 * </ul>
 *
 * @param codePage	One of the following code pages:
 *
 * <ul>
 * <li>VSCP_ACTIVE_CODEPAGE</li>
 * <li>VSCP_CYRILLIC_KOI8_R</li>
 * <li>VSCP_ISO_8859_1</li>
 * <li>VSCP_ISO_8859_2</li>
 * <li>VSCP_ISO_8859_3</li>
 * <li>VSCP_ISO_8859_4</li>
 * <li>VSCP_ISO_8859_5</li>
 * <li>VSCP_ISO_8859_6</li>
 * <li>VSCP_ISO_8859_7</li>
 * <li>VSCP_ISO_8859_8 </li>
 * <li>VSCP_ISO_8859_9</li>
 * <li>VSCP_ISO_8859_10</li>
 * <li>Any valid Windows code page</li>
 * </ul>
 *
 * @param writeFirstBuffer	Indicates whether this is the first buffer is
 * being written.  When this is non-zero and
 * the encoding given has a signature, the
 * signature is written.
 *
 * @param pDest	Destination buffer for data in the encoding
 * format specified.
 *
 * @param DestLen	Number of bytes allocated to destination
 * buffer.
 *
 * @param pSrc	Pointer to multi-byte source data.
 *
 * @param pSrcEnd	Pointer to end of multi-byte source data.
 *
 * @param pNofbytesWritten	Receives number of bytes (not characters of
 * encoding format) written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pBuf</i>>=<i>pEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs.
 *
 * @example
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead1(VSUTF8_FILEINFO1 *pfile,const
 * char *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(char *)pCurrentPos;
 *       return(1);  // No more data
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(char *)gTempBuffer;
 *    pfile->pEndBuf=(char *)(gTempBuffer+status);
 *    return(status);  // 0 for success, negative number for error.
 * }
 *
 * static char gDestTempBuffer[32768];
 * static int WriteFromUTF8(const char *pszFilename,int
 * dest_encoding,int intput_fh)
 * {
 *    VSUTF8_FILEINFO1 fileinfo;
 *    fileinfo.pBuf=fileinfo.pEndBuf=0;
 *    fileinfo.fh=intput_fh;
 *
 *    int output_fh=vsFileOpen(pszFilename,1);
 *    if (output_fh<0) {
 *       return(output_fh);
 *    }
 *    int writeFirstBuffer=1;
 *    int status;
 *    for (;;) {
 *       int Nofbytes;
 *
 * fileinfo.pBuf=vsMultiByteFillBuf(dest_encoding,VSCP_ACTI
 * VE_CODEPAGE, writeFirstBuffer,
 *
 * gDestTempBuffer,sizeof(gDestTempBuffer),
 *                              fileinfo.pBuf,fileinfo.pEndBuf,
 *                              (unsigned
 * *)&Nofbytes,&status,&fileinfo,CallbackFileRead1
 *                              );
 *       if (status<0) {
 *          break;
 *       }
 *       if (Nofbytes<=0) {
 *          status=Nofbytes;
 *          break;
 *       }
 *       Nofbytes=writefh(output_fh,gDestTempBuffer,Nofbytes);
 *       if (Nofbytes<0) {
 *          status=Nofbytes;
 *          break;
 *       }
 *       writeFirstBuffer=0;
 *    }
 *    closefh(output_fh);
 *    return(status);
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsMultiByteFillBuf(
   int destEncoding,
   int codePage,
   int writeFirstBuffer,
   void *pDest,size_t DestLen,
   const char *pSrc,const char *pSrcEnd,
   unsigned *pNofBytesWritten=0,int *pstatus=0,
   VSUTF8_FILEINFO1 *pfile=0,
   int (VSAPI *pfnRead)(VSUTF8_FILEINFO1 *pfile,const char *pCurrentPos)=0,
   int *pXlatError=0
   );
/**
 * Converts the data from the UTF-8 to the encoding specified UTF-8.
 *
 * @return Returns pointer to next character to read.
 *
 * @param encoding	One of the following encodings:
 *
 * <ul>
 * <li>VSCP_ACTIVE_CODEPAGE</li>
 * <li>VSCP_CYRILLIC_KOI8_R</li>
 * <li>VSCP_ISO_8859_1</li>
 * <li>VSCP_ISO_8859_2</li>
 * <li>VSCP_ISO_8859_3</li>
 * <li>VSCP_ISO_8859_4</li>
 * <li>VSCP_ISO_8859_5</li>
 * <li>VSCP_ISO_8859_6</li>
 * <li>VSCP_ISO_8859_7</li>
 * <li>VSCP_ISO_8859_8 </li>
 * <li>VSCP_ISO_8859_9</li>
 * <li>VSCP_ISO_8859_10</li>
 * <li>Any valid Windows code page</li>
 * <li>VSENCODING_UTF8</li>
 * <li>VSENCODING_UTF8_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF16LE</li>
 * <li>VSENCODING_UTF16LE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF16BE</li>
 * <li>VSENCODING_UTF16BE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF32LE</li>
 * <li>VSENCODING_UTF32LE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF32BE</li>
 * <li>VSENCODING_UTF32BE_WITH_SIGNATURE</li>
 * </ul>
 *
 * @param writeFirstBuffer	Indicates whether this is the first buffer is
 * being written.  When this is non-zero and
 * the encoding given has a signature, the
 * signature is written.
 *
 * @param pDest	Destination buffer for data in the encoding
 * format specified.
 *
 * @param DestLen	Number of bytes allocated to destination
 * buffer.
 *
 * @param pSrc Pointer to UTF-8 source data.
 *
 * @param pSrcEnd	Pointer to end of UTF-8 source data.
 *
 * @param pNofBytesWritten	Receives number of bytes (not characters of
 * encoding format) written.
 *
 * @param pstatus	Set to 0 if no error.  Otherwise, a negative
 * return code.
 *
 * @param pfnRead	Callback function to read more data when
 * <i>pBuf</i>>=<i>pEndBuf</i>.  This
 * allows you to write more efficient code
 * which processes data directly from any
 * source without having to make a copy of the
 * data.  Returns 0 if successful, 1 if no more
 * data, and a negative error code for an error.
 *
 * @param pXlatError	Set to 1 if a translation error occurs.
 *
 * @example
 * <pre>
 * static char gTempBuffer[32768];
 *
 * static int VSAPI CallbackFileRead1(VSUTF8_FILEINFO1 *pfile,const
 * char *pCurrentPos)
 * {
 *    if (pCurrentPos<pfile->pEndBuf) {
 *       pfile->pBuf=(char *)pCurrentPos;
 *       return(1);  // No more data
 *    }
 *    int status=readfh(pfile->fh,gTempBuffer,sizeof(gTempBuffer));
 *    pfile->pBuf=(char *)gTempBuffer;
 *    pfile->pEndBuf=(char *)(gTempBuffer+status);
 *    return(status);  // 0 for success, negative number for error.
 * }
 *
 * static char gDestTempBuffer[32768];
 * static int WriteFromUTF8(const char *pszFilename,int
 * dest_encoding,int intput_fh)
 * {
 *    VSUTF8_FILEINFO1 fileinfo;
 *    fileinfo.pBuf=fileinfo.pEndBuf=0;
 *    fileinfo.fh=intput_fh;
 *
 *    int output_fh=vsFileOpen(pszFilename,1);
 *    if (output_fh<0) {
 *       return(output_fh);
 *    }
 *    int writeFirstBuffer=1;
 *    int status;
 *    for (;;) {
 *       int Nofbytes;
 *       fileinfo.pBuf=vsUTF8FillBuf(dest_encoding,writeFirstBuffer,
 *
 * gDestTempBuffer,sizeof(gDestTempBuffer),
 *                              fileinfo.pBuf,fileinfo.pEndBuf,
 *                              (unsigned
 * *)&Nofbytes,&status,&fileinfo,CallbackFileRead1
 *                              );
 *       if (status<0) {
 *          break;
 *       }
 *       if (Nofbytes<=0) {
 *          status=Nofbytes;
 *          break;
 *       }
 *       Nofbytes=writefh(output_fh,gDestTempBuffer,Nofbytes);
 *       if (Nofbytes<0) {
 *          status=Nofbytes;
 *          break;
 *       }
 *       writeFirstBuffer=0;
 *    }
 *    closefh(output_fh);
 *    return(status);
 * }
 * </pre>
 *
 * @categories Unicode_Functions
 *
 */
char * VSAPI vsUTF8FillBuf(
   int encoding,
   int writeFirstBuffer,
   void *pDest,size_t DestLen,
   const char *pSrc,const char *pSrcEnd,
   unsigned *pNofBytesWritten=0,int *pstatus=0,
   VSUTF8_FILEINFO1 *pfile=0,
   int (VSAPI *pfnRead)(VSUTF8_FILEINFO1 *pfile,const char *pCurrentPos)=0,
   int *pXlatError=0
   );

int VSAPI vsUTF8PositionFromUTF16(unsigned short *pBuf,int BufLen,int index);

int VSAPI vsUTF8PositionToUTF16(char *pBuf,int BufLen,int index);
int VSAPI vsUTF8PositionToUTF32(char *pBuf,int BufLen,int index);
/**
 * Copies a null terminated UTF-16 string.  Resulting string is always
 * null terminated even if the entire source string cannot be copied.
 *
 * @param pszDest	Destination buffer.
 *
 * @param pszSrc	Null terminated UTF-16 string.
 *
 * @param DestLen	Number of characters allocated to
 * pszDest.  Must be at least 1.
 *
 * @categories Unicode_Functions
 *
 */
void VSAPI vsUTF16SafeCpy(unsigned short *pszDest,const unsigned short *pszSrc,size_t DestLen);
/**
 * @return Returns non-zero if SlickEdit is running in UTF-8 mode.
 * Otherwise, 0 is returned.
 *
 * @categories Unicode_Functions
 *
 */
int VSAPI vsUTF8();

// For SlickEdit use only.
/**
 * @return Converts UTF-32 character to upper case.  Currently, if a character
 * above 0xFFFFF is given, the character is returned unchanged.
 *
 * @param uch	UTF-32 character.
 *
 * @categories Unicode_Functions
 *
 */
unsigned VSAPI vsUTF32ToUpper(unsigned uch);
/**
 * @return Converts UTF-32 character to lower case.  Currently, if a character
 * above 0xFFFFF is given, the character is returned unchanged.
 *
 * @param uch	UTF-32 character.
 *
 * @categories Unicode_Functions
 *
 */
unsigned VSAPI vsUTF32ToLower(unsigned uch);
const char * VSAPI vsUTF8CharName(unsigned uch);
/**
 * Converts entire file from encoding specified to UTF-8.
 *
 * @return Returns 0 if successful.  Otherwise, a negative return code.
 *
 * @param filehandle	Source file handle returned by
 * <b>vsFileOpen</b>().
 *
 * @param encoding	One of the following encodings:
 *
 * <ul>
 * <li>VSCP_ACTIVE_CODEPAGE</li>
 * <li>VSCP_CYRILLIC_KOI8_R</li>
 * <li>VSCP_ISO_8859_1</li>
 * <li>VSCP_ISO_8859_2</li>
 * <li>VSCP_ISO_8859_3</li>
 * <li>VSCP_ISO_8859_4</li>
 * <li>VSCP_ISO_8859_5</li>
 * <li>VSCP_ISO_8859_6</li>
 * <li>VSCP_ISO_8859_7</li>
 * <li>VSCP_ISO_8859_8 </li>
 * <li>VSCP_ISO_8859_9</li>
 * <li>VSCP_ISO_8859_10</li>
 * <li>Any valid Windows code page</li>
 * <li>VSENCODING_UTF8</li>
 * <li>VSENCODING_UTF8_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF16LE</li>
 * <li>VSENCODING_UTF16LE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF16BE</li>
 * <li>VSENCODING_UTF16BE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF32LE</li>
 * <li>VSENCODING_UTF32LE_WITH_SIGNATURE</li>
 * <li>VSENCODING_UTF32BE</li>
 * <li>VSENCODING_UTF32BE_WITH_SIGNATURE</li>
 * </ul>
 *
 * @param pszBuf	Output buffer for UTF-8 data.  This buffer is
 * null terminated.  If reuseCurrentPoint is non-
 * zero, this must be a pointer to memory
 * allocated by <b>vsAlloc</b>().
 *
 * @param BufLen	Number of bytes read into <i>pszBuf</i>.
 * This length does not including the null
 * terminating character.
 *
 * @param reuseCurrentPointer	When non-zero, <i>pszBuf</i>
 * must already point to memory allocated by
 * vsAlloc.  If <i>pszBuf</i> is not big
 * enough, its size will be increased.
 *
 * @param pXlatError	Set to 1 if a translation error occurs.
 *
 * @categories Unicode_Functions
 *
 */
EXTERN_C
int VSAPI vsUTF8ReadEntireFile(int filehandle,int encoding,
                               char *&pszBuf,int &BufLen,
                               int reuseCurrentPointer=0,
                               int *pXlatError=0);

/**
 * Compares two UTF-8 strings.  This function is slow because it applies
 * many of the Unicode rules.  Under Windows, both buffers are
 * converted to UTF-16 and then the WIN32 CompareStringW() function
 * is called.  Use the vsUTF8StrCmpQuick() function for a fast string
 * compare that does not apply Unicode rules.
 *
 * @return Returns 1 if string 1 is greater than string 2. Returns 0 if string 1
 * equals string 2.  Returns -1 if string 1 is less than string 2.
 *
 * @param p1	UTF-8 string 1.
 *
 * @param p2	UTF-8 string 2.
 *
 * @param len1	Number of bytes in string 1.
 *
 * @param len2	Number of bytes in string 2.
 *
 * @categories Unicode_Functions
 *
 */
int VSAPI vsUTF8StrCmp(const char *p1,const char *p2,int len1=SESIZE_MAX,int len2=SESIZE_MAX);
/**
 * Compares two UTF-8 strings case insensitive.  This function is slow
 * because it applies many of the Unicode rules.  Under Windows, both
 * buffers are converted to UTF-16 and then the WIN32
 * CompareStringW() function is called.  Use the
 * vsUTF8StrICmpQuick() function for a fast string compare that does
 * not apply Unicode rules.
 *
 * @return Returns 1 if string 1 is greater than string 2. Returns 0 if string 1
 * equals string 2.  Returns -1 if string 1 is less than string 2.
 *
 * @param p1	UTF-8 string 1.
 *
 * @param p2	UTF-8 string 2.
 *
 * @param len1	Number of bytes in string 1.
 *
 * @param len2	Number of bytes in string 2.
 *
 * @categories Unicode_Functions
 *
 */
int VSAPI vsUTF8StrICmp(const char *p1, const char *p2,int len1=-1,int len2=-1);

/**
 * Converts EBCDIC text to ASCII.   <i>pSrcBuf</i>  maybe the same
 * as <i>pDestBuf</i> (OK if pSrcBuf==pDestBuf).
 *
 * @param pSrcBuf	Buffer contain EBCDIC data to be
 * converted.
 *
 * @param pDestBuf	Destination buffer for ASCII.
 *
 * @param SrcBufLen	Number of bytes in <i>pSrcBuf</i>.
 *
 * @categories Unicode_Functions
 *
 */
void VSAPI vsEBCDICToASCII(const char *pSrcBuf,char *pDestBuf,int SrcBufLen=-1);
/**
 * Converts ASCII text to EBCDIC.   <i>pSrcBuf</i>  maybe the same
 * as <i>pDestBuf</i> (OK if pSrcBuf==pDestBuf).
 *
 * @param pSrcBuf	Buffer contain ASCII data to be converted.
 *
 * @param pDestBuf	Destination buffer for EBCDIC.
 *
 * @param SrcBufLen	Number of bytes in <i>pSrcBuf</i>.
 *
 * @categories Unicode_Functions
 *
 */
void VSAPI vsASCIIToEBCDIC(const char *pSrcBuf,char *pDestBuf,int SrcBufLen=-1);
/**
 * Case insensitive compare.  Characters are compared
 * by character value and not using any Unicode
 * standard.
 *
 * @param pBuf1   Pointer to UTF-8 buffer 1
 * @param pBuf2   Pointer to UTF-8 buffer 2
 * @param len     Number of bytes to compare
 * @return <PRE>
 * 0     Strings are equal
 * >0    pBuf1>pBuf2
 * <0    pBuf1<pBuf2
 * </PRE>
 *
 * @categories Unicode_Functions
 *
 */
VSSTATIC inline int vsUTF8MemICmp(const char *pBuf1,const char *pBuf2,size_t len)
{
   const char *pBufEnd1=pBuf1+len;
   const char *pBufEnd2=pBuf2+len;
   for (;;) {
      if (pBuf1>=pBufEnd1) {
         return(0);
      }
      unsigned uch1;
      unsigned uch2;
      if ((unsigned char )*pBuf1<=0x7f) {
         uch1=(unsigned char)*pBuf1++;
         if ((unsigned char )*pBuf2<=0x7f) {
            uch2=(unsigned char)*pBuf2++;
         } else {
            return(-1);
         }
      } else {
         pBuf1=vsUTF8CharRead2(pBuf1,pBufEnd1,uch1);
         if ((unsigned char )*pBuf2<=0x7f) {
            return(1);
         } else {
            pBuf2=vsUTF8CharRead2(pBuf2,pBufEnd2,uch2);
         }
      }
      if (uch1 == uch2) continue;
      int diff=vsUTF32ToLower(uch1)-vsUTF32ToLower(uch2);
      if (diff) {
         return(diff);
      }
   }
   return(0);
}
/**
 * Case insensitive compare.  Characters are compared
 * by character value and not using any Unicode
 * standard.
 *
 * @param pBuf1   Pointer to UTF-8 buffer 1
 * @param pBuf2   Pointer to UTF-8 buffer 2
 * @param BufLen1 Number of bytes in buffer 1.  Use -1 if pBuf1
 *                is a NULL terminated string.
 * @param BufLen2 Number of bytes in buffer 2.  Use -1 if pBuf2
 *                is a NULL terminated string.
 * @return <PRE>
 * 0     Strings are equal
 * >0    pBuf1>pBuf2
 * <0    pBuf1<pBuf2
 * </PRE>
 *
 * @categories Unicode_Functions
 *
 */
VSSTATIC inline int vsUTF8StrICmpQuick(const char *pBuf1,const char *pBuf2,size_t BufLen1=SESIZE_MAX,size_t BufLen2=SESIZE_MAX)
{
   const char *pBufEnd1=pBuf1+((BufLen1==SESIZE_MAX)?strlen(pBuf1):BufLen1);
   const char *pBufEnd2=pBuf2+((BufLen2==SESIZE_MAX)?strlen(pBuf2):BufLen2);
   for (;;) {
      if (pBuf1>=pBufEnd1) {
         return((pBuf2>=pBufEnd2)?0:-1);
      }
      if (pBuf2>=pBufEnd2) {
         return(1);
      }
      unsigned uch1;
      unsigned uch2;
      if ((unsigned char )*pBuf1<=0x7f) {
         uch1=*pBuf1++;
         if ((unsigned char )*pBuf2<=0x7f) {
            uch2=*pBuf2++;
         } else {
            return(-1);
         }
      } else {
         pBuf1=vsUTF8CharRead2(pBuf1,pBufEnd1,uch1);
         if ((unsigned char )*pBuf2<=0x7f) {
            return(1);
         } else {
            pBuf2=vsUTF8CharRead2(pBuf2,pBufEnd2,uch2);
         }
      }
      if (uch1 == uch2) continue;
      int diff=vsUTF32ToLower(uch1)-vsUTF32ToLower(uch2);
      if (diff) {
         return(diff);
      }
   }
   return(0);
}
/**
 * Case sensitive compare.  Characters are compared
 * by character value and not using any Unicode
 * standard.
 *
 * @param pBuf1   Pointer to UTF-8 buffer 1
 * @param pBuf2   Pointer to UTF-8 buffer 2
 * @param BufLen1 Number of bytes in buffer 1.  Use -1 if pBuf1
 *                is a NULL terminated string.
 * @param BufLen2 Number of bytes in buffer 2.  Use -1 if pBuf2
 *                is a NULL terminated string.
 * @return <PRE>
 * 0     Strings are equal
 * >0    pBuf1>pBuf2
 * <0    pBuf1<pBuf2
 * </PRE>
 *
 * @categories Unicode_Functions
 *
 */
VSSTATIC inline int vsUTF8StrCmpQuick(const char *pBuf1,const char *pBuf2,int BufLen1,int BufLen2)
{
   const char *pBufEnd1=pBuf1+((BufLen1<0)?strlen(pBuf1):BufLen1);
   const char *pBufEnd2=pBuf2+((BufLen2<0)?strlen(pBuf2):BufLen2);
   for (;;) {
      if (pBuf1>=pBufEnd1) {
         return((pBuf2>=pBufEnd2)?0:-1);
      }
      if (pBuf2>=pBufEnd2) {
         return(1);
      }
      if (*pBuf1!=*pBuf2) {
         return((unsigned char)*pBuf1-(unsigned char)*pBuf2);
      }
      ++pBuf1;++pBuf2;
   }
   return(0);
}
int VSAPI vsUTF8GetOpenEncodingTable(OPENENCODINGTAB * & table, unsigned int & entryCount);
//int VSAPI vsUTF8InitCodePageMaps(const char * vsRootDir);

//int VSAPI vsUTF8IsInitialized();
int VSAPI vsACPWasUTF8(bool getRealValue=false);
/*void VSAPI vsUTF8SetDetermineHTMLEncodingCallback(
   int (VSAPI *pfnDetermineHTMLEncoding)(const char *pBuffer,int BufLen));*/
int VSAPI vsXMLFindEncoding(const char *pszName);
EXTERN_C_END
