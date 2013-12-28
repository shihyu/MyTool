////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_STRING_H
#define SLICKEDIT_STRING_H

// File:        SEString.h
// Description: Declaration for the SEString class.

#include "vsdecl.h"
#include "SEMemory.h"
#include "SEArray.h"
#include "SEHashTable.h"
#include "strmatch.h"
#include <wchar.h>

namespace slickedit {

/**
 * Manage a string of 'n' characters.  The string is always stored
 * null terminated, but can contain nulls if a length is given.
 * The string can dynamically grow if needed.
 * <P>
 * SEString manages its own memory for the string.
 * Whenever the string is deleted the associated memory is also
 * deleted.
 * <P>
 * SEString uses a reference counted string buffer, so that assignments
 * and copying of strings can be very, very fast and use less memory.
 * If the reference count is about to overflow, it forces a copy.
 * Copies are also forced on any operation that could cause a change
 * to the string buffer.
 * <P>
 * SEString also supports a mode where it can operate on an
 * unmanaged external buffer with a maximum capacity.  All normal
 * SEString operations are supported in this mode, however, it
 * will not attempt to "grow" the buffer if there is an overflow,
 * it will merely return an error status (BUFFER_OVERFLOW_RC).
 * <P>
 * Many of the methods in SEString are inline methods.  This is relying
 * optimistically on the compiler doing good optimizations and hoping
 * that it does not cause excessive code bloat.
 */

class VSDLLEXPORT SEString : public SEMemory
{
public:
   /**
    * Default constructor, SEString initialized to null string.
    */
   SEString();
   /**
    * Create a SEString from a null-terminated "C" string
    *
    * @param text       The string to copy
    */
   SEString(const char *text);
   /**
    * Create a SEString from a character array of the given length.
    *
    * @param text       The character array to copy
    * @param text_len   The length of the character array
    */
   SEString(const char *text, const size_t text_len);
   /**
    * Create a SEString from a character
    *
    * @param ch         The character to copy
    */
   SEString(const char ch);
   /**
    * Create a SEString from a VSE VSLSTR*
    *
    * @param src        The VSLSTR* to copy
    */
   SEString(VSLSTR* src);
   /**
    * Create an empty (not NULL) SEString with the given capacity.
    * Note: the capacity() of the string will be >= 'initial_capacity'.
    *
    * @param initial_capacity   Number of bytes to allocate to string
    */
   explicit SEString(size_t initial_capacity);
   explicit SEString(int initial_capacity);
   /**
    * Create a SEString from another SEString.
    *
    * @param src        The SEString to copy
    */
   SEString(const SEString &src);
   /**
    * Create a SEString from a pointer to another SEString.
    *
    * @param src        The SEString to copy
    */
   SEString(const SEString *src);
   /**
    * Create a SEString from a null-terminated "C" wide string
    *
    * WARNING!!!! This will immediately convert the string to a narrow string
    *
    * @param text       The string to copy
    */
   explicit SEString(const wchar_t *text);
   /**
    * Create a SEString from a null-terminated "C" wide string
    *
    * WARNING!!!! This will immediately convert the string to a narrow string
    *
    * @param text       The string to copy
    * @param text_len   The length of the character array
    */
   explicit SEString(const wchar_t *text, const size_t text_len);
   /**
    * Destruct a SEString.  Deallocates 'textBuf', so if you
    * have used getCString() or getMutableCString() to access the
    * raw string buffer, keep in mind that after the SEString is 
    * deallocated, the string reference becomes invalid. 
    */
   ~SEString();

   /**
    * Set the contents of the string to the given null-terminated
    * "C" string.  Note, this is equivilent to assignment operator.
    *
    * @param text       The string to copy
    *
    * Returns 0 on success, <0 on error.
    */
   int set(const char *text);
   /**
    * Set the contents of the string to the given character array.
    * Note, this is equivilent to assignment operator.
    *
    * @param text       The character array to copy
    * @param text_len   The length of the character array
    *
    * Returns 0 on success, <0 on error.
    */
   int set(const char *text, size_t text_len);
   /**
    * Set the contents of this string to the given null-terminated wide
    * character array.  Note, this is equivilent to assignment operator.
    *
    * WARNING!!!! This will immediately convert the string to a narrow string
    *
    * @param text       The string to copy
    */
   int set(const wchar_t *text);
   /**
    * Set the contents of this string to the given wide character array.
    * Note, this is equivilent to assignment operator.
    *
    * WARNING!!!! This will immediately convert the string to a narrow string
    *
    * @param text       The string to copy
    * @param text_len   The length of the character array
    */
   int set(const wchar_t *text, const size_t text_len);
   /**
    * Set the contents of the string to the given character.
    * Note, this is equivalent to assignment operator.
    *
    * @param ch         The character to copy
    */
   int set(const char ch);
   /**
    * Set the contents of the string to the given VSE VSLSTR*
    *
    * @param src        The VSLSTR* to copy
    */
   int set(VSLSTR* src);
   /**
    * Set the contents of the string to the given SEString.
    * Note, this is equivilent to assignment operator.
    *
    * @param src        The SEString to copy
    */
   int set(const SEString &src);

   /**
    * Set the contents of the string to the given character array.
    *
    * @param buffer   The external buffer to use
    * @param text_len The length of the string currently in the buffer
    * @param buf_cap  The maximum capacity of the buffer
    *
    * @return Returns 0 on success, <0 on error.
    */
   int setExternalBuffer(const char *buffer, 
                         const size_t text_len, 
                         const size_t buf_cap);

   /**
    * Break the link with the external buffer, copying its contents
    * into a reference counted representation.
    */
   int breakLinkToExternalBuffer();

   /**
    * Is this SEString using an external buffer or managing it's own?
    * 
    * @return true if the buffer is external.
    */
   bool isUsingExternalBuffer() const;

   /**
    * If the string is currently using an internal string buffer, 
    * force it to use an allocated string buffer. 
    * 
    * @return Returns 0 on success, <0 on error.
    */
   int doNotUseInternalBuffer(size_t new_capacity=0);

   /**
    * Is this SEString using its compact internal buffer, rather 
    * than using an allocated buffer?
    * 
    * @return true if the buffer is internal.
    */
   bool isUsingInternalBuffer() const;

   /**
    * Specify an initial capacity for the string
    * (how many bytes to allocate for the buffer).
    * Note: After calling this function, capacity() of the
    * string will be greater than or equal to 'new_capacity'.
    *
    * @param new_capacity   The number of bytes to allocate
    *
    * @return 0 on success, <0 on error.
    */
   int setCapacity(const size_t new_capacity);
   /**
    * Specify the new length of the string
    *
    * @param length   The new length of the string.  This must
    *                 be less than or equal to the capacity.
    *
    * @return 0 on success, <0 on error.
    */
   int setLength(const size_t length);
   /**
    * Specify the new length of the string and a fill char.
    *
    * @param length   The new length of the string.  This must
    *                 be less than or equal to the capacity.
    * @param fillChar Character to fill end of string with.
    *
    * @return 0 on success, <0 on error.
    */
   int setLength(const size_t length, const char fillChar);
   /**
    * Pad a string out to the specified length.  If the string
    * is already longer than 'length', do nothing.  This function
    * may increase the capacity of a string.
    *
    * @param length   The new length of the string.
    * @param fillChar Character to fill end of string with.
    *
    * @return 0 on success, <0 on error.
    */
   int pad(const size_t length, const char fillChar=' ');

   /**
    * Scan from the beginning of the string buffer and set the
    * length based on the first null terminator found.
    *
    * NOTE: This is most useful when getMutableCString() has been 
    * used to populate the buffer and the length of data in that buffer
    * is not readily known.
    *
    * @return 0 on success, <0 on error.
    */
   int resetLength();
   /**
    * Force the internal string representation to be NULL terminated. 
    *  
    * @return 0 on success, <0 on error.
    */
   int nullTerminate();

   /**
    * Get a pointer to the string buffer.  Note that the lifetime
    * of this pointer is tied to the lifetime of the SEString instance.
    *
    * @return pointer to string buffer, may be 0 for null string
    */
   const char *getCString() const;
   /**
    * Get a pointer to the string buffer.  The pointer is not const
    * so that the contents of the buffer can be changed. Note that
    * the lifetime of this pointer is tied to the lifetime of the
    * SEString instance.
    *
    * @return pointer to string buffer, may be 0 for null string
    */
   char *getMutableCString();
   /**
    * Get a copy of the string buffer.  Note that in this case, it
    * is the user's responsibility to free the pointer 
    * returned using <code>SEDeallocate()</code>.
    *
    * @return pointer to string buffer, may be 0 for null string
    */
   char *dupCString() const;
   /**
    * Create a copy of the string buffer and return it as a
    * SlickEdit 'VSLSTR*' pointer.
    * <p>
    * It is the user's responsibility to free the pointer returned
    * using <code>SEDeallocate()</code>. 
    *
    * @return pointer to string buffer, may be 0 for null string
    */
   struct VSLSTR *dup_lstr() const;
   /**
    * Create a copy of the string buffer and return it as a
    * null-terminated wide "C" string pointer
    * <p>
    * It is the user's responsibility to free the pointer returned 
    * using <code>SEDeallocate()</code>.
    *
    * @return pointer to wide string buffer, may be 0 for null string
    */
   wchar_t *dup_wide() const;
   /**
    * Export the string to the given bounded string buffer.
    * Truncates the string if it is too long.
    *
    * @param str_buffer  string buffer
    * @param max_length  length of string buffer
    */
   void exportStr(char *str_buffer,const size_t max_length) const;
   /**
    * Export the string to the given bounded wide string buffer.
    * Truncates the string if it is too long.
    *
    * @param str_buffer  string buffer
    * @param max_length  length of string buffer
    */
   void exportStr(wchar_t *str_buffer,const size_t max_length) const;
   /**
    * Export the string to the given bounded SlickEdit VSLSTR
    * string buffer.  Truncates the string if it is too long.
    *
    * @param lstr_p      pointer to string buffer
    * @param max_length  length of string buffer
    */
   void export_lstr(VSLSTR* lstr_p, const size_t max_length=VSMAXLSTR) const;

   /**
    * Return the length of the string.
    */
   size_t length() const;
   /**
    * Return the length of the string. 
    * @deprecated Use the length() method that returns size_t. 
    */
   unsigned int length32() const;

   /**
    * Returns the current capacity of the string.  This includes
    * the terminating null character.
    */
   size_t capacity() const;
   /**
    * Is this a NULL string?
    */
   bool isNull() const;
   /**
    * Is this *not* a NULL string?
    */
   bool isNotNull() const;
   /**
    * Is this string empty (or NULL)?
    */
   bool isEmpty() const;
   /**
    * Is this string *not* empty (or NULL)?
    */
   bool isNotEmpty() const;
   /**
    * Empty the string. 
    *  
    * @return 0 on success, <0 on error.
    */
   int makeEmpty();
   /**
    * Null the string. 
    *  
    * @return 0 on success
    */
   int makeNull();
   /**
    * If this is the null string, make it an empty string. 
    *  
    * @return 0 on success
    */
   int makeNotNull();

   /**
    * Get a substring of the SEString.
    * <p>
    * It is the user's responsibility to free the pointer 
    * returned using <code>SEDeallocate()</code>. 
    *
    * @param start      Starting position of substring, 0 is beginning
    * @param len        Number of characters to extract,
    *                   use MAXINT to extract to end of string.
    *
    * @return pointer to copy of the substring, may be 0 for null sring
    */
   char *dup_sub(size_t start, size_t len) const;
   /**
    * Extract a substring of the SEString to a new SEString object.
    *
    * @param start      Starting position of substring, 0 is beginning
    * @param len        Number of characters to extract,
    *                   use MAXINT to extract to end of string.
    *
    * @return A SEString containing a copy of the substring
    */
   SEString sub(size_t start, size_t len) const;
   /**
    * Extract a substring of the SEString into a new SEString object,
    * using an external buffer representation to avoid copying the string.
    * <p>
    * NOTE:  The lifetime of the substring must be less than the
    * lifetime of 'this'.  FURTHERMORE, if 'this' is modified, the
    * substring becomes invalid.
    * 
    * @param start      Starting position of substring, 0 is beginning
    * @param len        Number of characters to extract,
    *                   use MAXINT to extract to end of string.
    * @param copySmallStrings  Only create a true substring for large strings. 
    *
    * @return A SEString containing a copy of the substring
    */
   SEString subExternalBuffer(size_t start, size_t len, bool copySmallStrings=false) const;
   /**
    * Extract a substring from the tail of the SEString to a
    * new SEString object.
    *
    * @param start      Starting position of substring, 0 is beginning
    *
    * @return A SEString containing a copy of the substring
    */
   SEString tail(size_t start) const;

   /**
    * @return Returns the last character in the string.
    */
   char last_char() const;
   /**
    * @return Returns the first character in the string.
    */
   char first_char() const;
   /**
    * @return Returs the character at the given index in the string. 
    */
   char charAt(const size_t pos) const;

   /**
    * Append the contents of the given null-terminated "C" string
    * to the end of the string.
    *
    * @param text       The string to append
    *
    * Returns 0 on success, <0 on error.
    */
   int append(const char *text);
   /**
    * Append the contents of the given character array
    * to the end of the string.
    *
    * @param text       The character array to append
    * @param text_len   The length of the character append
    *
    * Returns 0 on success, <0 on error.
    */
   int append(const char * text, const size_t text_len);
   /**
    * Append the contents of the given VSE VSLSTR*
    * to the end of the string.
    *
    * @param src        The VSLSTR* to append
    *
    * Returns 0 on success, <0 on error.
    */
   int append(VSLSTR* src);
   /**
    * Append the contents of the given SEString
    * to the end of the string.
    *
    * @param src        The SEString to append
    *
    * Returns 0 on success, <0 on error.
    */
   int append(const SEString &src);
   /**
    * Append the contents of the given SEString pointer
    * to the end of the string.
    *
    * @param src        The SEString to append
    *
    * Returns 0 on success, <0 on error.
    */
   int append(const SEString *src);
   /**
    * Append a single character to the end of the string.
    *
    * @param ch         The character to append
    *
    * Returns 0 on success, <0 on error.
    */
   int append(const char ch);

   /**
    * Append the contents of the given wide character array
    * to the end of the string.
    *
    * WARNING!!!! This will immediately convert the appended string to a narrow string
    *
    * @param text       The character array to append
    * @param text_len   The length of the character append
    *
    * Returns 0 on success, <0 on error.
    */
   int append(const wchar_t *text, const size_t text_len);
   /**
    * Append the contents of the given null-terminated wide "C" string
    * to the end of the string.
    *
    * WARNING!!!! This will immediately convert the appended string to a narrow string
    *
    * @param text       The string to append
    *
    * Returns 0 on success, <0 on error.
    */
   int append(const wchar_t *text);
   /**
    * Append a single wide character to the end of the string.
    *
    * WARNING!!!! This will immediately convert the appended char to a narrow char
    *
    * @param ch         The character to append
    *
    * Returns 0 on success, <0 on error.
    */
   int append(const wchar_t ch);

   /**
    * Append a single character to the end of the string, using an int
    *
    * WARNING!!!! This will immediately convert the appended char to a narrow char
    *
    * @param ch         The character to append
    *
    * Returns 0 on success, <0 on error.
    */
   int append(int ch);

   /**
    * Append an integer to the end of the string. 
    *
    * @param rhs         The integer to append
    * @param radix       numeric base (base 10 for decimal, base 64 supported)
    *
    * Returns 0 on success, <0 on error.
    */
   int appendNumber(const int rhs, int radix=10);

   /**
    * Append an integer to the end of the string.
    *
    * @param rhs         The integer to append
    * @param radix       numeric base (base 10 for decimal, base 64 supported)
    *
    * Returns 0 on success, <0 on error.
    */
   int appendNumber(const unsigned int rhs, int radix=10);

   /**
    * Append a long to the end of the string.
    *
    * @param rhs         The integer to append
    * @param radix       numeric base (base 10 for decimal, base 64 supported)
    *
    * Returns 0 on success, <0 on error.
    */
   int appendNumber(const long rhs, int radix=10);

   /**
    * Append a long to the end of the string.
    *
    * @param rhs         The integer to append
    * @param radix       numeric base (base 10 for decimal, base 64 supported)
    *
    * Returns 0 on success, <0 on error.
    */
   int appendNumber(const unsigned long rhs, int radix=10);

   /**
    * Append a VSUINT64 to the end of the string.
    *
    * @param rhs         The integer to append
    * @param radix       numeric base (base 10 for decimal, base 64 supported)
    *
    * Returns 0 on success, <0 on error.
    */
   int appendNumber(const VSUINT64 rhs, int radix=10);

   /**
    * Append a VSINT64 to the end of the string.
    *
    * @param rhs         The integer to append
    * @param radix       numeric base (base 10 for decimal, base 64 supported)
    *
    * Returns 0 on success, <0 on error.
    */
   int appendNumber(const VSINT64 rhs, int radix=10);

   /**
    * Append a single character to the end of the string,
    * if that char isn't already at the end of the string.
    *
    * @param ch            The character to append
    * @param appendIfEmpty Append char even if the string is empty.
    *
    * Returns 0 on success, <0 on error.
    */
   int maybeAppend(const char ch, bool appendIfEmpty=false);

   /**
    * Append a file sepearator ('/' or '\') character to the end
    * of the string if it doesn't already have one.
    *
    * Returns 0 on success, <0 on error.
    */
   int maybeAppendFileSep();

   /**
    * Prepend the contents of the given null-terminated "C" string
    * to the beginning of the string.
    *
    * @param text       The string to prepend
    *
    * Returns 0 on success, <0 on error.
    */
   int prepend(const char *text);

   /**
    * Prepend the contents of the given character array
    * to the end of the string.
    *
    * @param text       The character array to prepend
    * @param text_len   The length of the character array prepend
    *
    * Returns 0 on success, <0 on error.
    */
   int prepend(const char * text, const size_t text_len);

   /**
    * Prepend the contents of the given VSE VSLSTR*
    * to the end of the string.
    *
    * @param src        The VSLSTR* to prepend
    *
    * Returns 0 on success, <0 on error.
    */
   int prepend(VSLSTR* src);

   /**
    * Prepend the contents of the given SEString
    * to the end of the string.
    *
    * @param src        The SEString to prepend
    *
    * Returns 0 on success, <0 on error.
    */
   int prepend(const SEString &src);

   /**
    * Prepend a single character to the end of the string.
    *
    * @param ch         The character to prepend
    *
    * Returns 0 on success, <0 on error.
    */
   int prepend(const char ch);

   /**
    * Prepend a single character to the beginning of the string,
    * if that char isn't already at the beginning of the string.
    *
    * @param ch            The character to prepend
    * @param appendIfEmpty Append char even if the string is empty.
    *
    * Returns 0 on success, <0 on error.
    */
   int maybePrepend(const char ch, bool appendIfEmpty=false);

   /**
    * Surround the contents of this string with the given
    * the given null-terminated "C" string(s).  If the 'after'
    * string is null, use 'text' both before and after.
    *
    * @param text       The string to prepend
    * @param after      (optional) The string to append
    *
    * Returns 0 on success, <0 on error.
    */
   int surround(const char *text, const char *after=0);

   /**
    * Surround the contents of this string with the given
    * the given character array(s).  If the 'after'
    * string is null, use 'text' both before and after.
    *
    * @param text       The string to prepend
    * @param text_len   The length of the string to prepend
    * @param after      (optional) The string to append
    * @param after_len  The length of the string to prepend
    *
    * Returns 0 on success, <0 on error.
    */
   int surround(const char *text,    size_t text_len,
                const char *after=0, size_t after_len=0);

   /**
    * Surround the contents of this string with the given
    * the given VSE lstr_p(s).  If the 'after' string is null,
    * use 'text' both before and after.
    *
    * @param text       The VSLSTR* to prepend
    * @param after      (optional) The VSLSTR* to append
    *
    * Returns 0 on success, <0 on error.
    */
   int surround(VSLSTR* text, VSLSTR* after=0);

   /**
    * Surround the contents of this string with the given
    * the given SEString(s).
    *
    * @param text       The SEString to prepend
    * @param after      The SEString to append
    *
    * Returns 0 on success, <0 on error.
    */
   int surround(const SEString &text, const SEString &after);

   /**
    * Surround the contents of this string with the given
    * the given character(s).
    *
    * @param text       The character to prepend
    * @param after      The character to append
    *
    * Returns 0 on success, <0 on error.
    */
   int surround(char ch, char after=0);

   /**
    * Surround the contents of this string with the given
    * the given character(s), provided the characters are not
    * already in both positions.
    *
    * @param text       The character to prepend
    * @param after      The character to append
    *
    * Returns 0 on success, <0 on error.
    */
   int maybeSurround(char ch, char after=0);

   /**
    * Insert the contents of the given null-terminated "C" string
    * at the given position in the string.
    *
    * @param text       The string to append
    * @param pos        The position to insert at (default 0)
    *                   if pos > textLen, append to string.
    *
    * Returns 0 on success, <0 on error.
    */
   int insert(const char * text, size_t pos);
   /**
    * Insert the contents of the given character array
    * at the given position in the string.
    *
    * @param text       The character array to append
    * @param text_len   The length of the character append
    * @param pos        The position to insert at
    *                   if pos > textLen, append to string.
    *
    * Returns 0 on success, <0 on error.
    */
   int insert(const char * text, const size_t text_len, size_t pos);
   /**
    * Insert the contents of the given VSE VSLSTR*
    * at the given position in the string.
    *
    * @param src        The VSE VSLSTR* to append
    * @param pos        The position to insert at (default 0)
    *                   if pos > textLen, append to string.
    *
    * Returns 0 on success, <0 on error.
    */
   int insert(VSLSTR* src, size_t pos=0);
   /**
    * Insert the contents of the given SEString
    * at the given position in the string.
    *
    * @param src        The SEString to append
    * @param pos        The position to insert at (default 0)
    *                   if pos > textLen, append to string.
    *
    * Returns 0 on success, <0 on error.
    */
   int insert(const SEString &src, size_t pos=0);
   /**
    * Insert a single character at the given positin in the string.
    *
    * @param ch         The character to append
    * @param pos        The position to insert at (default 0)
    *                   if pos > textLen, append to string.
    *
    * Returns 0 on success, <0 on error.
    */
   int insert(const char ch, size_t pos=0);

   /**
    * Replace 'length' characters starting at the given
    * position in the string with the supplied
    * replacement string.
    *
    * @param pos        Position where string to be replaced starts.
    * @param length     Length of string to be replaced.
    * @param rep        String inserted in place of the removed string.
    * @param rep_len    Length of the replacement string.
    *
    * @return 0 on success, <0 on error.
    * @example
    */
   int replace(size_t pos, size_t length, const char* rep, const size_t rep_length);
   /**
    * Replace 'length' characters starting at the given
    * position in the string with the supplied
    * replacement string.
    *
    * @param pos        Position where string to be replaced starts.
    * @param length     Length of string to be replaced.
    * @param rep        String inserted in place of the removed string.
    *
    * @return 0 on success, <0 on error.
    * @example
    */
   int replace(size_t pos, size_t length, const SEString &rep);

   /**
    * Replace all occurrences of a character
    *
    * @param ch      The character to replace
    * @param repl_ch The character to insert in place of the removed character 
    * @param isUTF8  Set to 'true' to do UTF-8 safe character replacement 
    *
    * @return  the number of characters replaced
    */
   int replaceAll(const char ch, const char repl_ch, bool isUTF8/*=false*/);
   int replaceAll(const char ch, const char repl_ch);

   /**
    * Replace all occurrences of a simple string pattern
    *
    * @param pattern       Pattern to be replaced
    * @param rep_pattern   Pattern to replace with
    * @param isUTF8        Set to 'true' to do UTF-8 safe character replacement 
    *                      'false' will use the OS strstr() function to find matches 
    *
    * @return Number of patterns found and replaced
    * @example
    */
   int replaceAll(const char* pattern, const char* rep_pattern, bool isUTF8/*=false*/);
   int replaceAll(const char* pattern, const char* rep_pattern);

   /**
    * Replace all occurrences of a simple string pattern
    *
    * @param pattern       Pattern to be replaced 
    * @param patternLength Length of pattern to search for 
    * @param rep_pattern   Pattern to replace with 
    * @param replaceLength Length of replacement pattern 
    * @param isUTF8        Set to 'true' to do UTF-8 safe character replacement 
    *                      'false' will use the OS strstr() function to find matches 
    *
    * @return Number of patterns found and replaced
    * @example
    */
   int replaceAll(const char* pattern, size_t patternLength, 
                  const char* rep_pattern, size_t replaceLength, bool isUTF8/*=false*/);
   int replaceAll(const char* pattern, size_t patternLength, 
                  const char* rep_pattern, size_t replaceLength);

   /**
    * Replace all occurrences of a string pattern
    *
    * @param pattern       Pattern to be replaced
    * @param rep_pattern   Pattern to replace with
    * @param isUTF8        Set to 'true' to do UTF-8 safe character replacement 
    *                      'false' will use the OS strstr() function to find matches 
    *
    * @return Number of patterns found and replaced
    * @example
    */
   int replaceAll(const SEString& pattern, const SEString& rep_pattern, bool isUTF8/*=false*/);
   int replaceAll(const SEString& pattern, const SEString& rep_pattern);

   /**
    * Delete 'n' characters starting at the given position.
    *
    * @param start      The position to begin removing chars at
    * @param num_chars  The number of characters to delete
    */
   int remove(const size_t start, const size_t num_chars=1);

   /**
    * Trim 'n' characters off of the end of the string.
    *
    * @param num_chars  The number of characters to delete (default 1)
    * @return 0 on success
    */
   int trim(const size_t num_chars=1);

   /**
    * Strip the given character off the beginning or end of the string
    *
    * @param ch         Character to strip
    * @param ltb        Strip leading, trailing, or both?  'L', 'T', or 'B'
    * @param strip_all  Strip all matches or just the first one?
    *
    * @return 0 on success
    */
   int strip(const char ch, char ltb='B', const int strip_all=1);
   /**
    * Strip the given character off the beginning or end of the string
    *
    * @param strip_chars   Set of characters to strip, for example " \t"
    * @param ltb           Strip leading, trailing, or both?  'L', 'T', or 'B'
    * @param strip_all     Strip all matches or just the first one?
    *
    * @return 0 on success
    */
   int strip(const char *strip_chars, char ltb='B', const int strip_all=1);
   /**
    * Strip whitespace from the beginning or end of the string. 
    * Whitespace includes spaces and tab characters. 
    *  
    * @param ltb Strip leading, trailing, or both?  'L', 'T', or 'B'
    *
    * @return 0 on success
    */
   int stripSpaces(char ltb='B');

   /**
    * Search a string for another substring.
    *
    * @param pattern    String to search for
    * @param start      Position to begin searching at
    * @param options    Search options, see {@link vsStrPos()}
    *                   bitset of VSSTRPOSFLAG_*
    *
    * @return STRING_NOT_FOUND_RC if string is not found,
    *         index of position in string otherwise (0 is first).
    *         NOTE: this differs from vsStrPos()
    */
   int pos(const SEString& string, size_t start=0, int options=0) const;
   /**
    * Search a string for another substring.
    *
    * @param pattern    String to search for
    * @param start      Position to begin searching at
    * @param options    Search options, see {@link vsStrPos()}
    *                   bitset of VSSTRPOSFLAG_*
    *
    * @return STRING_NOT_FOUND_RC if string is not found,
    *         index of position in string otherwise (0 is first).
    *         NOTE: this differs from vsStrPos()
    */
   int pos(const char *pattern, size_t start=0, int options=0) const;
   /**
    * Search a string for another substring. 
    *
    * @param pattern    String to search for
    * @param patternLen Length of search string
    * @param start      Position to begin searching at
    * @param options    Search options, see {@link vsStrPos()}
    *                   bitset of VSSTRPOSFLAG_*
    * @param match      Capture match length, offset and match 
    *                   groups {@link vsStrMatch()}
    *
    * @return STRING_NOT_FOUND_RC if string is not found,
    *         index of position in string otherwise (0 is first).
    *         NOTE: this differs from vsStrPos()
    */
   int pos(const char *pattern, const size_t patternLen, size_t start, int options, str_match_t* match=0, size_t *ppos=0) const;
   /**
    * Search a string for another substring using strstr instead of vsStrPos.
    *
    * @param pattern    String to search for
    * @param start      Position to begin searching at
    *
    * @return STRING_NOT_FOUND_RC if string is not found,
    *         index of position in string otherwise (0 is first).
    */
   int cpos(const SEString& string, const size_t start=0) const;
   /**
    * Search a string for a char using strchr.
    *
    * @param pattern    String to search for
    * @param start      Position to begin searching at
    *
    * @return STRING_NOT_FOUND_RC if string is not found,
    *         index of position in string otherwise (0 is first).
    */
   int cpos(const char *pattern, const size_t start=0) const;
   /**
    * Search a string for another substring using strchr.
    *
    * @param pattern    String to search for
    * @param start      Position to begin searching at
    *
    * @return STRING_NOT_FOUND_RC if string is not found,
    *         index of position in string otherwise (0 is first).
    */
   int cpos(const char ch, const size_t start=0) const;
   /**
    * Search a string last occurrence of the given pattern.
    *
    * @param pattern    String to search for
    * @param start      Position to begin searching at
    * @param options    Search options, see {@link vsStrPos()}
    *                   bitset of VSSTRPOSFLAG_*
    *
    * @return STRING_NOT_FOUND_RC if string is not found,
    *         index of position in string otherwise (0 is first).
    *         NOTE: this differs from vsStrPos()
    */
   int lastpos(const SEString& string, size_t start, int options,size_t *ppos=0) const;
   /**
    * Search a string last occurrence of the given pattern.
    *
    * @param pattern    String to search for
    * @param start      Position to begin searching at
    * @param options    Search options, see {@link vsStrPos()}
    *                   bitset of VSSTRPOSFLAG_*
    *  
    * @return STRING_NOT_FOUND_RC if string is not found,
    *         index of position in string otherwise (0 is first).
    *         NOTE: this differs from vsStrPos()
    */
   int lastpos(const char *pattern, size_t start=SESIZE_MAX, int options=0,size_t *ppos=0) const;
   /**
    * Search a string last occurrence of the given pattern.
    *
    * @param pattern    String to search for
    * @param patternLen Length of search string
    * @param start      Position to begin searching at
    * @param options    Search options, see {@link vsStrPos()}
    *                   bitset of VSSTRPOSFLAG_*
    * @param match      Capture match length, offset and match 
    *                   groups {@link vsStrMatch()}
    *  
    * @return STRING_NOT_FOUND_RC if string is not found,
    *         index of position in string otherwise (0 is first).
    *         NOTE: this differs from vsStrPos()
    */
   int lastpos(const char *pattern, const size_t patternLen, size_t start, int options, str_match_t* match=0, size_t *ppos=0) const;
   /**
    * Search a string last occurrence of the given pattern using strrstr.
    *
    * @param pattern    String to search for
    * @param start      Position to begin searching at
    * @param options    Search options, see {@link vsStrPos()}
    *                   bitset of VSSTRPOSFLAG_*
    *
    * @return STRING_NOT_FOUND_RC if string is not found,
    *         index of position in string otherwise (0 is first).
    *         NOTE: this differs from vsStrPos()
    */
   int clastpos(const char *pattern, size_t start=SESIZE_MAX) const;
   /**
    * Search a string for a character.
    *
    * @param ch         Character to search for
    * @param start      Position to begin searching at (default 0)
    *
    * @return STRING_NOT_FOUND_RC if string is not found,
    *         index of position in string otherwise (0 is first).
    */
   int pos(const char ch, const size_t start=0) const;
   /**
    * Search a string last occurrence of the given character.
    *
    * @param ch         Character to search for
    * @param start      Position to begin searching at (default 0)
    *
    * @return STRING_NOT_FOUND_RC if string is not found,
    *         index of position in string otherwise (0 is first).
    */
   int lastpos(const char ch, size_t start=SESIZE_MAX) const;
   /**
    * Search a string last occurrence of the given character using strrchr.
    *
    * @param ch         Character to search for
    * @param start      Position to begin searching at (default 0)
    *
    * @return STRING_NOT_FOUND_RC if string is not found,
    *         index of position in string otherwise (0 is first).
    */
   int clastpos(const char ch, size_t start=SESIZE_MAX) const;

   /**
    * Count all occurrences of the given character in the string
    *
    * @param ch      Character to search for
    * @return Number of instances found
    */
   size_t countAll(const char ch) const;
   /**
    * Count all occurrences of the given substring in the string
    *
    * @param pattern Pattern to search for
    * @return Number of instances found
    */
   size_t countAll(const char* pattern) const;
   /**
    * Count all occurrences of the given substring in the string
    *
    * @param pattern       Pattern to search for 
    * @param patternLength Length of search pattern string
    * @return Number of instances found
    */
   size_t countAll(const char* pattern, size_t patternLength) const;
   /**
    * Count all occurrences of the given substring in the string
    *
    * @param pattern Pattern to search for
    * @return Number of instances found
    */
   size_t countAll(const SEString& pattern) const;

   /**
    * Make the string all upper-case.
    * @return 0 on success, <0 on error.
    */
   int upcase();
   /**
    * Make the string all lower-case.
    * @return 0 on success, <0 on error.
    */
   int lowcase();
   /**
    * Capitalize the first letter of the string, 
    * and make the rest of the string lower-case.
    * @return 0 on success, <0 on error.
    */
   int capitalize();

   /**
    * Get all upper-case copy of this string.
    * @return 0 on success, <0 on error.
    */
   SEString toUpcase() const;

   /**
    * Get all upper-case copy of this string.
    * @return 0 on success, <0 on error.
    */
   SEString toLowcase() const;
   /**
    * Get a capitalized copy of this string 
    * (first letter upcase, rest of string lowcase)
    */
   SEString toCap() const;

   /**
    * Compare the specified strings, case sensitive.
    *
    * @param lhs  left hand side of comparison
    * @param rhs  right hand side of comparison
    *
    * @return <  0 less than rhs
    *         == 0 equal to rhs
    *         >  0 greater than rhs
    */
   static int compareString(const SEString& lhs, const SEString &rhs);
   static int compareString(SEString& lhs, SEString &rhs);
   /**
    * Compare the specified strings, case-insensitive.
    *
    * @param lhs  left hand side of comparison
    * @param rhs  right hand side of comparison
    *
    * @return <  0 less than rhs
    *         == 0 equal to rhs
    *         >  0 greater than rhs
    */
   static int compareStringI(const SEString& lhs, const SEString &rhs);
   static int compareStringI(SEString lhs, SEString rhs);

   /**
    * Compare to the specified string case-sensitive
    *
    * @param string String to compare to.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return <  0 less than rhs
    *         == 0 equal to rhs
    *         >  0 greater than rhs
    * @example
    */
   int compare(const SEString& rhs, const int caseSensitive) const;

   /**
    * Compare to the specified string.
    *
    * @param rhs String to compare to.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return <  0 less than rhs
    *         == 0 equal to rhs
    *         >  0 greater than rhs
    * @example
    */
   int compare(const VSLSTR* rhs, const int caseSensitive) const;

   /**
    * Compare to the specified string.
    *
    * @param rhs String to compare to.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return <  0 less than rhs
    *         == 0 equal to rhs
    *         >  0 greater than rhs
    * @example
    */
   int compare(const char* rhs, const int caseSensitive) const;

   /**
    * Compare to the specified string.
    *
    * @param rhs String to compare to.
    * @param length Length of rhs.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return <  0 less than rhs
    *         == 0 equal to rhs
    *         >  0 greater than rhs
    * @example
    */
   int compare(const char* rhs, const size_t length, const int caseSensitive) const;

   /**
    * Compare to the specified string case-sensitive. 
    * This function will consider an null string as equal to an empty string. 
    *
    * @param string String to compare to.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return true if equal, false otherwise
    */
   bool equalToIgnoreNull(const SEString& rhs, const bool caseSensitive=true) const;

   /**
    * Compare to the specified string case-sensitive
    *
    * @param string String to compare to.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return true if equal, false otherwise
    */
   bool equalTo(const SEString& rhs, const int caseSensitive) const;

   /**
    * Compare to the specified string.
    *
    * @param rhs String to compare to.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return true if equal, false otherwise
    */
   bool equalTo(const VSLSTR* rhs, const int caseSensitive) const;

   /**
    * Compare to the specified string.
    *
    * @param rhs String to compare to.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return <  0 less than rhs
    *         == 0 equal to rhs
    *         >  0 greater than rhs
    */
   bool equalTo(const char* rhs, const int caseSensitive) const;

   /**
    * Compare to the specified string.
    *
    * @param rhs String to compare to.
    * @param length Length of rhs.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return true if equal, false otherwise
    */
   bool equalTo(const char* rhs, const size_t length, const int caseSensitive) const;

   /**
    * Check to see if this string begins with the specified pattern
    *
    * @param pattern Pattern to look for
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int beginsWith(const SEString& pattern) const;

   /**
    * Check to see if this string begins with the specified pattern
    *
    * @param pattern Pattern to look for 
    * @param options Search options, see {@link vsStrPos()} bitset 
    *                of VSSTRPOSFLAG_*
    * @param match   Capture match length, offset and match groups 
    *                {@link vsStrMatch()}
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int beginsWith(const SEString& pattern, const int options, str_match_t* match) const;

   /**
    * Check to see if this string begins with the specified pattern
    *
    * @param rhs String to compare to.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int beginsWith(const SEString& rhs, const int caseSensitive) const;

   /**
    * Check to see if this string begins with the specified pattern
    *
    * @param rhs String to compare to.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int beginsWith(const char* rhs, const int caseSensitive) const;

   /**
    * Check to see if this string begins with the specified pattern
    *
    * @param rhs String to compare to.
    * @param options Search options, see {@link vsStrPos()} bitset 
    *                of VSSTRPOSFLAG_*
    * @param match   Capture match length, offset and match groups 
    *                {@link vsStrMatch()}
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int beginsWith(const char* rhs, const int options, str_match_t* match) const;

   /**
    * Check to see if this string begins with the specified pattern
    *
    * @param rhs String to compare to.
    * @param length Length of rhs.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int beginsWith(const char* rhs, size_t length, const int caseSensitive) const;

   /**
    * Check to see if this string begins with the specified pattern
    *
    * @param rhs String to compare to.
    * @param length Length of rhs.
    * @param options Search options, see {@link vsStrPos()} bitset 
    *                of VSSTRPOSFLAG_*
    * @param match   Capture match length, offset and match groups 
    *                {@link vsStrMatch()}
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int beginsWith(const char* rhs, size_t length, const int options, str_match_t* match) const;

   /**
    * Check to see if this string begins with the specified pattern
    *
    * @param ch Char to compare to.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int beginsWith(const char ch, const int caseSensitive) const;

   /**
    * Check to see if this string ends with the specified pattern
    *
    * @param pattern Pattern to look for
    *
    * @return 1 if it ends with it, 0 otherwise
    */
   int endsWith(const SEString& pattern) const;

   /**
    * Check to see if this string ends with the specified pattern
    *
    * @param pattern Pattern to look for
    * @param options Search options, see {@link vsStrPos()} bitset 
    *                of VSSTRPOSFLAG_*
    * @param match   Capture match length, offset and match groups 
    *                {@link vsStrMatch()}
    *
    * @return 1 if it ends with it, 0 otherwise
    */
   int endsWith(const SEString& pattern, const int options, str_match_t* match) const;

   /**
    * Check to see if this string ends with the specified pattern
    *
    * @param rhs String to compare to.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int endsWith(const SEString& rhs, const int caseSensitive) const;

   /**
    * Check to see if this string ends with the specified pattern
    *
    * @param rhs String to compare to.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int endsWith(const char* rhs, const int caseSensitive) const;

   /**
    * Check to see if this string ends with the specified pattern
    *
    * @param rhs String to compare to.
    * @param options Search options, see {@link vsStrPos()} bitset 
    *                of VSSTRPOSFLAG_*
    * @param match   Capture match length, offset and match groups 
    *                {@link vsStrMatch()}
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int endsWith(const char* rhs, const int options, str_match_t* match) const;

   /**
    * Check to see if this string ends with the specified pattern
    *
    * @param rhs String to compare to.
    * @param length Length of rhs.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int endsWith(const char* rhs, size_t length, const int caseSensitive) const;

   /**
    * Check to see if this string ends with the specified pattern
    *
    * @param rhs String to compare to.
    * @param length Length of rhs.
    * @param options Search options, see {@link vsStrPos()} bitset 
    *                of VSSTRPOSFLAG_*
    * @param match   Capture match length, offset and match groups 
    *                {@link vsStrMatch()}
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int endsWith(const char* rhs, size_t length, const int options, str_match_t* match) const;

   /**
    * Check to see if this string ends with the specified pattern
    *
    * @param ch Char to compare to.
    * @param caseSensitive
    *               1 = case-sensitive comparison
    *               0 = case-insensitive comparison
    *
    * @return 1 if it begins with it, 0 otherwise
    */
   int endsWith(const char ch, const int caseSensitive = 0) const;

   /**
    * @return Returns a hash value for the this string.
    */
   unsigned int hash() const;
   /**
    * Compute a hash value for the given string.
    *
    * @param p    string to compute hash value for
    *
    * @return hash value
    */
   static unsigned int hashString(const SEString &s);
   static unsigned int hashString(SEString s);

   /**
    * Compute a hash value for the given string, assuming the string 
    * contains UTF8 data. 
    *
    * @param p    string to compute hash value for
    *
    * @return hash value
    */
   static unsigned int hashStringUTF8(const SEString &s);
   static unsigned int hashStringUTF8(SEString s);

   /**
    * Split the string into an array of strings pivoting on line
    * endings.  This works for all types of line endings, Unix (LF),
    * DOS (CR,LF), and Mac (CR).
    *
    * @param a                array that holds the split strings
    * @param stripLineEndings strip line endings for each line 
    * @param createSubStrings create substrings instead of copying lines. 
    *                         substrings will NOT be null-terminated 
    *
    * @return 0 on succes, <0 otherwise
    */
   int splitLines(SEArray<SEString>& a, 
                  bool stripLineEndings=true, 
                  bool createSubStrings=false) const;

   /**
    * Split the string into an array of strings pivoting on the given
    * delimeter character.
    * This function does not work with strings containing nulls.
    *
    * @param delim            character delimeter to split string at
    * @param a                array that holds the split strings
    * @param createSubStrings create substrings instead of copying lines. 
    *                         substrings will NOT be null-terminated 
    *
    * @return 0 on succes, <0 otherwise
    */
   int split(const char delim, SEArray<SEString>& a, bool createSubStrings=false) const;

   /**
    * Parse the first item off of this string and return it.
    * Setting the remainder of the string to the 'rest' argument.
    * This function does not work with strings containing nulls.
    *
    * @param delim      character delimeter to split string at
    * @param rest       the rest of the string, maybe be 'this'
    * @param start_col  [default 0] column to start on
    *
    * @return the first item off of the list
    */
   SEString parse(const char delim, SEString &rest, size_t start_col=0) const;

   /**
    * Parse the last item off of this string and return it. Setting
    * the beginning of the string to the 'start' argument. This 
    * function does not work with strings containing nulls. 
    *
    * @param delim      character delimeter to split string at
    * @param start      the beginning of the string 
    *                   (before last delimeter), maybe be 'this'
    *
    * @return the first item off of the list
    */
   SEString parseLast(const char delim, SEString &start) const;

   /**
    * Convert hexadecimal number string to integer number. Can
    * handle up to 64-bit signed integers. Handles hexadecimal 
    * number string of the form: 
    * <ul>
    * <li>Hexadecimal: 7f
    * </ul>
    * 
    * <p>
    * Note: Only plain hexadecimal number strings are supported. 
    * C-style prefixes, suffixes, and sign are not supported. 
    * Examples of styles not supported: 
    * <ul>
    * <li>Prefix: 0x7f
    * <li>Sign: -0x7f
    * <li>Suffix: 0x7fL
    * </ul>
    * </p>
    * 
    * <p>
    * Note: If you want to stop conversion at the first non-hex 
    * character (e.g. you are parsing a url or C-style number 
    * ending in 'U' or 'L', etc.), then specify a stop character 
    * set. Specify '*' for any non-hex character. Specify 0 for no 
    * stop character set. 
    * </p>
    *
    * <p>
    * Warning: Overflow is possible on values greater than 2^63.
    * </p>
    * 
    * @param offset       (in,out) Offset index to start converting
    *                     at. 0 is the beginning of the string. On
    *                     return offset is set to index that
    *                     conversion stopped at. 
    * @param len          Number of characters to process into 
    *                     number. Specify SESIZE_MAX for entire
    *                     string. Defaults to SESIZE_MAX.
    * @param stopCharSet  If conversion encounters a character in 
    *                     stopCharSet, then current value is
    *                     returned (no error). Set to '*' to stop
    *                     at any non-hex characer. Specify 0 for no
    *                     stop character set. Default to 0. 
    *
    * @return 64-bit signed int. -1 is returned if not a valid 
    *         hexadecimal number.
    *
    * @see toInt
    */
   VSINT64 parseHexInt(size_t& offset, size_t len=SESIZE_MAX, const char* stopCharSet=0) const;

   /**
    * Convert decimal number string to integer number. Can handle
    * up to 64-bit signed integers. Handles decimal number string
    * of the form: 
    * <ul>
    * <li>Decimal: 123456789
    * </ul>
    * 
    * <p>
    * Note: Only plain decimal number strings are supported. 
    * C-style prefixes, suffixes, and sign are not supported. 
    * Examples of styles not supported: 
    * <ul>
    * <li>Sign: -789
    * <li>Suffix: 789L
    * </ul>
    * </p>
    * 
    * <p>
    * Note: If you want to stop conversion at the first non-decimal 
    * character (e.g. you are parsing a url or C-style number 
    * ending in 'U' or 'L', etc.), then specify a stop character 
    * set. Specify '*' for any non-decimal character. Specify 0 for
    * no stop character set. 
    * </p>
    *
    * <p>
    * Warning: Overflow is possible on values greater than 2^63.
    * </p>
    * 
    * @param offset       (in,out) Offset index to start converting
    *                     at. 0 is the beginning of the string. On
    *                     return offset is set to index that
    *                     conversion stopped at. 
    * @param len          Number of characters to process into 
    *                     number. Specify SESIZE_MAX for entire
    *                     string. Defaults to SESIZE_MAX.
    * @param stopCharSet  If conversion encounters a character in 
    *                     stopCharSet, then current value is
    *                     returned (no error). Set to '*' to stop
    *                     at any non-decimal characer. Specify 0
    *                     for no stop character set. Default to 0.
    *
    * @return 64-bit signed int. -1 is returned if not a valid 
    *         decimal number.
    *
    * @see toInt
    */
   VSINT64 parseDecimalInt(size_t& offset, size_t len=SESIZE_MAX, const char* stopCharSet=0) const;

   /**
    * Convert octal number string to integer number. Can handle up 
    * to 64-bit signed integers. Handles octal number string of the
    * form: 
    * <ul>
    * <li>Octal: 1234567
    * </ul>
    * 
    * <p>
    * Note: Only plain octal number strings are supported. C-style
    * prefixes, suffixes, and sign are not supported. Examples of 
    * styles not supported: 
    * <ul>
    * <li>Prefix: 0123 (leading '0' harmless but unnecessary)
    * <li>Sign: -0123
    * <li>Suffix: 0123L
    * </ul>
    * </p>
    * 
    * <p>
    * Note: If you want to stop conversion at the first non-octal 
    * character (e.g. you are parsing a url or C-style number 
    * ending in 'U' or 'L', etc.), then specify a stop character 
    * set. Specify '*' for any non-octal character. Specify 0 for 
    * no stop character set. 
    * </p>
    *
    * <p>
    * Warning: Overflow is possible on values greater than 2^63.
    * </p>
    * 
    * @param offset       (in,out) Offset index to start converting
    *                     at. 0 is the beginning of the string. On
    *                     return offset is set to index that
    *                     conversion stopped at. 
    * @param len          Number of characters to process into 
    *                     number. Specify -1 for entire string.
    *                     Defaults to -1. 
    * @param stopCharSet  If conversion encounters a character in 
    *                     stopCharSet, then current value is
    *                     returned (no error). Set to '*' to stop
    *                     at any non-octal characer. Specify 0 for
    *                     no stop character set. Default to 0.
    *
    * @return 64-bit signed int. -1 is returned if not a valid 
    *         octal number.
    *
    * @see parseHexInt, parseDecInt, toInt
    */
   VSINT64 parseOctalInt(size_t& offset, size_t len=SESIZE_MAX, const char* stopCharSet=0) const;

   /**
    * Convert C-style number string to integer number. Can handle up to 64-bit
    * signed integers. Handles number string of the form:
    * <ul>
    * <li>Decimal: 3, 3L, 3U
    * <li>Octal: 077
    * <li>Hexadecimal: 0x7f
    * <li>Signed: +3, -3, -3L, -077, -0x7f
    * </ul>
    * 
    * <p>
    * Warning: Overflow is possible on values greater than 2^63.
    * </p>
    *
    * @param result         64-bit signed int result. 
    * @param suffixSupport  Set to true to support C-style type 
    *                       suffixes (L, LL, U). Defaults to true. 
    * @param signSupport    Set to true to support +/- sign prefix. 
    *                       Defaults to true.
    * 
    * @return true on success, false if number string is invalid. 
    */
   bool toInt(VSINT64& result, bool suffixSupport=true, bool signSupport=true) const;
   bool toInt64(VSINT64& result, bool suffixSupport=true, bool signSupport=true) const;
   bool toInt32(int& result, bool suffixSupport=true, bool signSupport=true) const;

   /**
    * Convert C-style number string to integer number. Can handle up to 64-bit
    * signed integers. Handles number string of the form:
    * <ul>
    * <li>Decimal: 3, 3L, 3U
    * <li>Octal: 077
    * <li>Hexadecimal: 0x7f
    * <li>Signed: +3, -3, -3L, -077, -0x7f
    * </ul>
    * 
    * <p>
    * Warning: Overflow is possible on values greater than 2^63.
    * </p>
    *
    * @param suffixSupport  Set to true to support C-style type 
    *                       suffixes (L, LL, U). Defaults to true.
    * @param signSupport    Set to true to support +/- sign prefix. 
    *                       Defaults to true.
    * 
    * @return 64-bit signed int. 0 is returned if not a valid number.
    */
   VSINT64 toInt(bool suffixSupport=true, bool signSupport=true) const;
   VSINT64 toInt64(bool suffixSupport=true, bool signSupport=true) const;
   int toInt32(bool suffixSupport=true, bool signSupport=true) const;

   /**
    * Convert a base-64 encoded string to an integer number. 
    * Can handle up to 64-bit unsigned signed integers.
    * 
    * <p>
    * Warning: Overflow is possible on values greater than or equal to 2^64.
    * </p>
    *
    * @param result         64-bit unsigned int result. 
    * 
    * @return true on success, false if number string is invalid. 
    */
   bool toIntBase64(VSUINT64& result) const;

   /**
    * Convert a base-64 encoded string to an integer number. 
    * Can handle up to 64-bit unsigned signed integers.
    * <p>
    * Warning: Overflow is possible on values greater than or equal to 2^64.
    * </p>
    *
    * @return 64-bit unsigned int. 0 is returned if not a valid number.
    */
   VSUINT64 toIntBase64() const;

   /**
    * Convert this string to a string in base64 encoding. 
    *  
    * @param lineLength    maximum encoded line length. 
    *                      line feeds are inserted at this point.
    *                      typical values are 64 or 76 
    */
   SEString getBase64EncodedString(size_t lineLength=0) const;

   /**
    * Convert this string, encoded as base64 to plain text.
    */
   SEString getBase64DecodedString() const;

   /**
    * Convert C-style floating point number string to floating point number.
    * Can handle up to double-precision floating point numbers. Handles number
    * strings of the form:
    * 
    * <ul>
    * <li>Float: 3.1457, 3.1457F, 3.1457L
    * <li>Exponent: 3.1457E4, 3.1457E-4
    * <li>Signed: +3.1457, -3.1457, -3.1457E4
    * </ul>
    * 
    * @return double
    */
   double toFloat() const;

   /**
    * Overload assignment operator to copy a null-terminated "C" string.
    */
   const SEString &operator =(const char *text);
   /**
    * Overload assignment operator to copy a null-terminated "C" string.
    */
   const SEString &operator =(const char ch);
   /**
    * Overload assignment operator to copy a SEString.
    */
   const SEString &operator =(const SEString &src);
   /**
    * Overload assignment operator to copy a VSE VSLSTR*.
    */
   const SEString &operator =(VSLSTR* src);
   /**
    * Overload assignment operator to copy a null-terminated "C" string.
    */
   const SEString &operator =(const wchar_t *text);
   /**
    * Overload array access operator to index character array
    */
   char operator[](const size_t pos) const;
   /**
    * Overload array access operator to index character array.
    * This version of operator can be used in the LHS of an expr.
    */
   char &operator[](const size_t pos);

   /**
    * Overload equality comparison operator, does case-sensitive compare.
    */
   bool operator ==(const SEString &rhs) const;
   /**
    * Overload equality comparison operator, does case-sensitive compare.
    */
   bool operator ==(VSLSTR* rhs) const;
   /**
    * Overload equality comparison operator, does case-sensitive compare.
    */
   bool operator ==(const char *rhs) const;
   /**
    * Overload equality comparison operator, does case-sensitive compare.
    */
   bool operator ==(const char ch) const;

   /**
    * Overload inequality comparison operator, does case-sensitive compare.
    */
   bool operator !=(const SEString &rhs) const;
   /**
    * Overload inequality comparison operator, does case-sensitive compare.
    */
   bool operator !=(VSLSTR* rhs) const;
   /**
    * Overload inequality comparison operator, does case-sensitive compare.
    */
   bool operator !=(const char *rhs) const;
   /**
    * Overload inequality comparison operator, does case-sensitive compare.
    */
   bool operator !=(const char ch) const;

   /**
    * Overload LTE comparison operator, does case-sensitive compare.
    */
   bool operator <=(const SEString &rhs) const;
   /**
    * Overload LTE comparison operator, does case-sensitive compare.
    */
   bool operator <=(const char *rhs) const;
   /**
    * Overload LTE comparison operator, does case-sensitive compare.
    */
   //int operator <=(const char ch) const;

   /**
    * Overload GTE comparison operator, does case-sensitive compare.
    */
   bool operator >=(const SEString &rhs) const;
   /**
    * Overload GTE comparison operator, does case-sensitive compare.
    */
   bool operator >=(const char *rhs) const;
   /**
    * Overload GTE comparison operator, does case-sensitive compare.
    */
   //int operator >=(const char ch) const;

   /**
    * Overload LT comparison operator, does case-sensitive compare.
    */
   bool operator <(const SEString &rhs) const;
   /**
    * Overload LT comparison operator, does case-sensitive compare.
    */
   bool operator <(const char *rhs) const;
   /**
    * Overload LT comparison operator, does case-sensitive compare.
    */
   //int operator <(const char ch) const;

   /**
    * Overload GT comparison operator, does case-sensitive compare.
    */
   bool operator >(const SEString &rhs) const;
   /**
    * Overload GT comparison operator, does case-sensitive compare.
    */
   bool operator >(const char *rhs) const;
   /**
    * Overload GT comparison operator, does case-sensitive compare.
    */
   //int operator >(const char ch) const;

   /**
    * Overload += operator to append a SEString to string
    */
   const SEString &operator+=(const SEString &rhs);
   /**
    * Overload += operator to append a null-terminated "C" string
    */
   const SEString &operator+=(const char *rhs);
   /**
    * Overload += operator to append a wide null-terminated "C" string
    */
   const SEString &operator+=(const wchar_t *rhs);
   /**
    * Overload += operator to append a single charactor.
    */
   const SEString &operator+=(const char ch);
   /**
    * Overload += operator to append a single wide charactor.
    */
   const SEString &operator+=(const wchar_t ch);
   /**
    * Overload + operator to concatenate strings (inefficient copies).
    */
   SEString operator +(const SEString &rhs) const;
   /**
    * Overload + operator to concatenate "C" string (inefficient copies).
    */
   SEString operator +(const char *rhs) const;
   /**
    * Overload + operator to concatenate SEString with a single char.
    */
   SEString operator +(const char ch) const;

private:
   // These constructors and operators are declared private to make
   // sure that no implicit conversion from these types is ever
   // accidentally performed without the caller knowing

   SEString(const long rhs);
   SEString(const VSINT64 rhs);

   const SEString &operator+=(const int rhs);
   const SEString &operator+=(const unsigned int rhs);
   const SEString &operator+=(const long rhs);
   const SEString &operator+=(const unsigned long rhs);
   const SEString &operator+=(const VSUINT64 rhs);
   const SEString &operator+=(const VSINT64 rhs);

   SEString operator+(const int rhs) const;
   SEString operator+(const unsigned int rhs) const;
   SEString operator+(const long rhs) const;
   SEString operator+(const unsigned long rhs) const;
   SEString operator+(const VSUINT64 rhs) const;
   SEString operator+(const VSINT64 rhs) const;

   const SEString &operator=(const int rhs);
   const SEString &operator=(const unsigned int rhs);
   const SEString &operator=(const long rhs);
   const SEString &operator=(const unsigned long rhs);
   const SEString &operator=(const VSUINT64 rhs);
   const SEString &operator=(const VSINT64 rhs);

private:

   // Maximum number of references to a single string instance
   enum { SESTRINGBUF_MAX_REFS = 65535 };

   // header for reference counted string buffer
   struct SEPrivateStringBuffer {
      // fields
      size_t   mTextLength;
      unsigned short mNumRefs;
      unsigned char  mMutexIndex;
      unsigned char  mReserved;
      char     mTextBuffer[8];
      // reference counting functions
      struct SEPrivateStringBuffer *addRef();
      const bool remRef();
   };

   union {

      // Used to initialize a string to NULL (all zeroes), faster than memset()
      struct {
         VSUINT64 mZero1;
         VSUINT64 mZero2;
         VSUINT64 mZero3;
         VSUINT64 mZero4;
      } mInitial;

      // String is small enough to fit in our small internal string buffer
      // If 'mUseInternalBuffer==1', it does not matter what
      // 'mpExternalBuffer' is set to.
      struct {
         char mInternalBuffer[sizeof(VSUINT64)*4 - sizeof(unsigned char)];
         unsigned char mInternalLength:7;
         unsigned char mUseInternalBuffer:1;
      };

      // String uses an allocated string buffer or
      // points to an external string buffer,
      // which may be a substring of another string.
      // In this case, 'mUseInternalBuffer==0'
      // The string is considered as NULL if mpStringBuffer==NULL
      // and mpExternalBuffer==NULL
      struct {
         struct SEPrivateStringBuffer *mpStringBuffer;
         char *mpExternalBuffer;
         unsigned int mExternalLength;
         unsigned int mExternalCapacity;
      };
   };

   /**
    * Return the length of the string and also get a pointer to the 
    * string buffer for this string. 
    */
   const size_t getLengthAndPointer(const char *&pBuffer) const;

   /**
    * Copy on write.  After a call to this function, the buffer
    * representation is guaranteed to be unique and at have space 
    * for at least req_capacity, plus an extra byte for a null 
    * terminator. 
    */
   int cow(const size_t req_capacity, const size_t extra_capacity=0);

};


///////////////////////////////////////////////////////////////////////////
// INLINE METHODS for SEString
//

#if !defined(SE_NO_INLINE) || defined(SLICKEDIT_STRING_CPP)

#ifndef SE_NO_INLINE
#define SE_INLINE inline
#else
#define SE_INLINE
#endif

// constructors and destructors
SE_INLINE SEString::SEString()
{
   mInitial.mZero1 = mInitial.mZero2 = mInitial.mZero3 = mInitial.mZero4 = 0;
}

// internal state tests
SE_INLINE bool SEString::isUsingExternalBuffer() const
{
   return (!mUseInternalBuffer && mpExternalBuffer != NULL);
}

SE_INLINE bool SEString::isUsingInternalBuffer() const
{
   return mUseInternalBuffer;
}

// 'get' string
SE_INLINE const char *SEString::getCString() const
{
   if (mUseInternalBuffer) return &mInternalBuffer[0];
   if (mpExternalBuffer != NULL) return mpExternalBuffer;
   if (mpStringBuffer == NULL) return NULL;
   return &mpStringBuffer->mTextBuffer[0];
}

// length functions
SE_INLINE size_t SEString::length() const
{
   if (mUseInternalBuffer) return mInternalLength;
   if (mpExternalBuffer != NULL) return mExternalLength;
   if (mpStringBuffer == NULL) return 0;
   return mpStringBuffer->mTextLength;
}
SE_INLINE unsigned int SEString::length32() const
{
   if (mUseInternalBuffer) return mInternalLength;
   if (mpExternalBuffer != NULL) return mExternalLength;
   if (mpStringBuffer == NULL) return 0;
   return (unsigned int)mpStringBuffer->mTextLength;
}

// null or empty tests
SE_INLINE bool SEString::isNull() const
{
   return (!mUseInternalBuffer &&
           mpExternalBuffer == NULL &&
           mpStringBuffer   == NULL);
}
SE_INLINE bool SEString::isNotNull() const
{
   return (mUseInternalBuffer ||
           mpExternalBuffer != NULL ||
           mpStringBuffer   != NULL);
}

SE_INLINE bool SEString::isEmpty() const
{
   if (mUseInternalBuffer) return (mInternalLength == 0);
   if (mpExternalBuffer != NULL) return (mExternalLength == 0);
   if (mpStringBuffer == NULL) return true;
   return (mpStringBuffer->mTextLength == 0);
}
SE_INLINE bool SEString::isNotEmpty() const
{
   if (mUseInternalBuffer) return (mInternalLength > 0);
   if (mpExternalBuffer != NULL) return (mExternalLength > 0);
   if (mpStringBuffer == NULL) return false;
   return (mpStringBuffer->mTextLength > 0);
}

// character indexing methods
SE_INLINE char SEString::last_char() const
{
   if (mUseInternalBuffer) {
      if (mInternalLength <= 0) return '\0';
      return mInternalBuffer[mInternalLength-1];
   }
   if (mpExternalBuffer != NULL) {
      if (mExternalLength <= 0) return '\0';
      return mpExternalBuffer[mExternalLength-1];
   }
   if (mpStringBuffer != NULL) {
      const size_t text_len = mpStringBuffer->mTextLength; 
      if (text_len <= 0) return '\0';
      return mpStringBuffer->mTextBuffer[text_len-1];
   }
   return '\0';
}
SE_INLINE char SEString::first_char() const
{
   if (mUseInternalBuffer) {
      if (mInternalLength <= 0) return '\0';
      return mInternalBuffer[0];
   }
   if (mpExternalBuffer != NULL) {
      if (mExternalLength <= 0) return '\0';
      return mpExternalBuffer[0];
   }
   if (mpStringBuffer != NULL) {
      const size_t text_len = mpStringBuffer->mTextLength; 
      if (text_len <= 0) return '\0';
      return mpStringBuffer->mTextBuffer[0];
   }
   return '\0';
}
SE_INLINE char SEString::charAt(const size_t pos) const
{
   if (mUseInternalBuffer) {
      if (pos >= mInternalLength) return '\0';
      return mInternalBuffer[pos];
   }
   if (mpExternalBuffer != NULL) {
      if (pos >= mExternalLength) return '\0';
      return mpExternalBuffer[pos];
   }
   if (mpStringBuffer != NULL) {
      if (pos >= mpStringBuffer->mTextLength) return '\0';
      return mpStringBuffer->mTextBuffer[pos];
   }
   return '\0';
}

// array subscript operator
SE_INLINE char SEString::operator[](const size_t pos) const
{
   if (mUseInternalBuffer) {
      if (pos >= mInternalLength) return '\0';
      return mInternalBuffer[pos];
   }
   if (mpExternalBuffer != NULL) {
      if (pos >= mExternalLength) return '\0';
      return mpExternalBuffer[pos];
   }
   if (mpStringBuffer != NULL) {
      if (pos >= mpStringBuffer->mTextLength) return '\0';
      return mpStringBuffer->mTextBuffer[pos];
   }
   return '\0';
}

// assignment operators
SE_INLINE const SEString &SEString::operator =(const char *text)
{
   set(text);
   return(*this);
}
SE_INLINE const SEString &SEString::operator =(const char ch)
{
   set(ch);
   return(*this);
}
SE_INLINE const SEString &SEString::operator =(VSLSTR* src)
{
   set(src? (const char*)src->str:0,src? src->len:0);
   return(*this);
}
SE_INLINE const SEString &SEString::operator =(const SEString &src)
{
   if (this != &src) set(src);
   return(*this);
}

// concatenation (append) operators
SE_INLINE const SEString &SEString::operator+=(const SEString &rhs)
{ 
   append(rhs);
   return(*this); 
}
SE_INLINE const SEString &SEString::operator+=(const char *rhs)
{ 
   append(rhs); 
   return(*this); 
}
SE_INLINE const SEString &SEString::operator+=(const char ch)
{ 
   append(ch);  
   return(*this); 
}

// concatenation operators
SE_INLINE SEString SEString::operator +(const SEString &rhs) const
{
   SEString text(*this);
   text.append(rhs);
   return(text);
}
SE_INLINE SEString SEString::operator +(const char *rhs) const
{
   SEString text(*this);
   text.append(rhs);
   return(text);
}
SE_INLINE SEString SEString::operator +(const char ch) const
{
   SEString text(*this);
   text.append(ch);
   return(text);
}

#endif // SE_NO_INLINE

// work around warning about inconsistent linkage
#ifdef SLICKEDIT_STRING_CPP
#undef VSDLLIMPORT
#define VSDLLIMPORT
#endif

/**
 * Stock pre-constructed empty string
 */
extern const VSDLLIMPORT SEString EMPTYString;
/**
 * Stock pre-constructed null string
 */
extern const VSDLLIMPORT SEString NULLString;

/**
 * Convert a 64-bit integer to an ASCII string
 *
 * @param v               64-bit value
 * @param buffer          output buffer
 * @param base            numeric base (base 10 for decimal)
 */
extern VSDLLEXPORT void i64toa(VSINT64 v, char *buffer, const int base);

/**
 * Convert an unsigned 64-bit integer to ASCII
 *
 * @param v               unsigned 64-bit value
 * @param buffer          output buffer of adaquate size
 * @param base            numeric base (base 10 for decimal, base 64 supported)
 */
extern VSDLLEXPORT void u64toa(VSUINT64 v, char *buffer, const int base);

/**
 * Convert an unsigned 64-bit integer to ASCII
 *
 * @param v               unsigned 64-bit value
 * @param buffer          output buffer of adaquate size
 * @param base            numeric base (base 10 for decimal, base 64 supported)
 */
extern VSDLLEXPORT void u32toa(unsigned int v, char *buffer, const int base);

/**
 * Convert a 32-bit integer to an ASCII string 
 *
 * @param v               32-bit value
 * @param buffer          output buffer
 * @param base            numeric base (base 10 for decimal)
 */
extern VSDLLEXPORT void i32toa(int v, char *buffer, const int base);

/**
 * Utility function for converting a string to a 64-bit integer.
 * 
 * @param s                string to convert 
 * @param length           length of string
 * @param result           [output] on success, integer value is placed here
 * @param suffixSupport    [optional] allow integer to have C style suffixes
 * @param signSupport      [optional] allow integer to have leading +/- signs
 * 
 * @return 'true' on success, 'false' otherwise
 */
extern VSDLLEXPORT 
bool SEStringToInt64(const char *s, 
                     const size_t length, 
                     VSINT64& result, 
                     bool suffixSupport=true, 
                     bool signSupport=true);

} // namespace slickedit

// global operators
extern VSDLLEXPORT slickedit::SEString operator+(const char  lhs, const slickedit::SEString& rhs);
extern VSDLLEXPORT slickedit::SEString operator+(const char* lhs, const slickedit::SEString& rhs);

/**
 * Utility function for setting the value of a reference
 * variable to the value of a SEString object.  Checks for
 * isNull() case, and sets string to empty string in that case.
 *
 * @param var        (reference) interpreter variable to set
 * @param value      SEString to set variable to value of
 */
extern VSDLLEXPORT int vsHvarSetS(VSHREFVAR var, const slickedit::SEString &value);
/**
 * Utility function for getting the value of a reference
 * variable and constructing and storing it in a SEString object.
 *
 * @param var        (reference) interpreter variable to get
 *
 * @returns SEString containing value of 'var'
 */
extern VSDLLEXPORT slickedit::SEString vsHvarGetS(VSHREFVAR var);

/**
 * Utility function for getting the value of a property
 * and placing it in a SEString variable.
 *
 * @param wid           window id
 * @param prop_id       property id (VSP_*)
 * @param value         (reference) SEString to set value to
 */
extern VSDLLEXPORT int vsPropGetS(int wid,int prop_id, slickedit::SEString &value);

/*
 * Utility function for setting the value of a property
 * to the value of a SEString passed in.
 *
 * @param wid           window id
 * @param prop_id       property id (VSP_*)
 * @param value         value to set parameter to
 */
extern VSDLLEXPORT void vsPropSetS(int wid,int prop_id,const slickedit::SEString &value);

#endif // SLICKEDIT_STRING_H

