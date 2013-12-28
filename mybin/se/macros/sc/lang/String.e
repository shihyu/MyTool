////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48969 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc. 
// You may modify, copy, and distribute the Slick-C Code (modified or unmodified) 
// only if all of the following conditions are met: 
//   (1) You do not include the Slick-C Code in any product or application 
//       designed to run independently of SlickEdit software programs; 
//   (2) You do not use the SlickEdit name, logos or other SlickEdit 
//       trademarks to market Your application; 
//   (3) You provide a copy of this license with the Slick-C Code; and 
//   (4) You agree to indemnify, hold harmless and defend SlickEdit from and 
//       against any loss, damage, claims or lawsuits, including attorney's fees, 
//       that arise or result from the use or distribution of Your application.
////////////////////////////////////////////////////////////////////////////////////
#pragma option(pedantic,on)
#include "slick.sh"
#import "math.e"
#require "IToString.e"
#require "IEquals.e"
#require "IComparable.e"
#require "IIndexable.e"
#require "IHashable.e"
#require "IAssignTo.e"

/**
 * The "sc.lang" namespace contains interfaces and 
 * classes that are intrinisic to the Slick-C language.
 */
namespace sc.lang;

/** 
 * This utility class is used to represent a Slick-C string.  It
 * is not as effecient as using the _str directly, but 
 * encapsulates many more methods for manipulating the string, 
 * making string operations much simpler. Instances of this 
 * class can be readily converted to a string and to be assigned
 * to string or used in string concatenation expressions. 
 */
class String : 
   IToString,     // allow implicit conversion to _str 
   IAssignTo,     // can assign a string instance to another
   IEquals,       // compare for equality
   IComparable,   // relational comparisons
   IIndexable,    // treat string like a character array
   IHashable      // may be used as hash table keys
{

   /** 
    * The string instance, represented as a Slick-C string
    */
   private _str m_s;

   /** 
    * @return Generate a string representing this object. 
    * [from interface IToString]
    */
   _str toString() {
      return m_s;
   }

   /**
    * Copy this object to the given destination.  The destination
    * class will always be a valid and initialized class instance.
    *
    * @param dest   Destination object, expected to be
    *               the same type as this class.
    */
   void copy(IAssignTo &dest) {
      ((String)dest).m_s = this.m_s;
   }

   /**
    * Constructor, String class initialized to Slick-C string.
    */
   String(_str text=""){
      this.m_s=text;
   }
   /**
    * Destruct a String.  Sets the string instance to null. 
    */
   ~String() {
      this.m_s=null;
   }

   /**
    * Set the contents of the string. 
    *  
    * @param text       The string to copy
    */
   void set(_str text) {
      this.m_s = text;
   }
   
   /**
    * Specify the maximum string length allowed before the Slick-C 
    * interpreter will flag an error. 
    *  
    * @param new_capacity   The number of bytes to allocate 
    *  
    * @return 0 on success, <0 on error.
    */
   static int setCapacity(int new_capacity) {
      return (int)_default_option(VSOPTION_WARNING_STRING_LENGTH,new_capacity);
   }
   /**
    * @return Returns the maximum string length allowed before the
    * Slick-C interpreter will flag an error. 
    */
   static int getCapacity() {
      return (int)_default_option(VSOPTION_WARNING_STRING_LENGTH);
   }

   /**
    * @return Return the length of the string.
    */
   int getLength() /*const*/ {
      return length(m_s);
   }
   /**
    * Specify the new length of the string 
    *  
    * @param new_length   The new length of the string.  This must
    *                 be less than or equal to the capacity.
    *  
    * @return 0 on success, <0 on error.
    */
   void setLength(int new_length, _str fillChar=' ') {
      int diff = new_length - length(m_s);
      if (diff > 0) {
         m_s :+= substr("",1,diff,fillChar);
      } else if (diff < 0) {
         m_s = substr(m_s,1,new_length);
      }
   }

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
   void pad(int new_length, _str fillChar=' ') {
      int diff = new_length - length(m_s);
      if (diff > 0) {
         m_s :+= substr("",1,diff,fillChar);
      }
   }

   /**
    * @return Return a copy of the string buffer.
    */
   _str get() /*const*/ {
      return this.m_s;
   }
   /**
    * Get a pointer to the string buffer. Note that the lifetime of
    * this pointer is tied to the lifetime of the String instance. 
    *  
    * @return pointer to string buffer, may be 0 for null string
    */
   _str *getPointer() {
      return &this.m_s;
   }

   /**
    * Is this a NULL string?
    */
   boolean isNull() /*const*/ {
      return this.m_s == null;
   }
   /**
    * Is this *not* a NULL string?
    */
   boolean isNotNull() /*const*/ {
      return this.m_s != null;
   }
   /**
    * Is this string empty (or NULL)?
    */
   boolean isEmpty() /*const*/ {
      return length(m_s)==0;
   }
   /**
    * Is this string *not* empty (or NULL)?
    */
   boolean isNotEmpty() /*const*/ {
      return length(m_s) > 0;
   }
   /**
    * Empty the string.
    */
   void makeEmpty() {
      this.m_s = "";
   }
   /**
    * Null the string.
    */
   void makeNull() {
      this.m_s = null;
   }
   /**
    * If this is the null string, make it an empty string.
    */
   void makeNotNull() {
      if (this.m_s == null) {
         this.m_s = "";
      }
   }

   /**
    * Extract a substring of the String to a new String object. 
    *  
    * @param start      Starting position of substring, 0 is beginning
    * @param len        Number of characters to extract,
    *                   use MAXINT to extract to end of string.
    *  
    * @return A String containing a copy of the substring
    */
   String sub(int start, int len=-1, _str fillChar=' ') /*const*/ {
      String ss(substr(this.m_s,start,len,fillChar));
      return ss;
   }
   /**
    * Extract a substring from the tail of the String to a new 
    * String object. 
    *  
    * @param start      Starting position of substring, 0 is beginning 
    *  
    * @return A POMString containing a copy of the substring
    */
   String tail(int start) /*const*/ {
      String ss(substr(this.m_s,start));
      return ss;
   }

   /**
    * @return Returns the last character in the string.
    */
   _str lastChar() /*const*/ {
      return substr(this.m_s,length(m_s),1);
   }
   /**
    * @return Returns the first character in the string.
    */
   _str firstChar() /*const*/ {
      return substr(this.m_s,1,1);
   }

   /**
    * Append the contents of the given string 
    * to the end of the string. 
    *  
    * @param text       The string to append
    */
   void append(_str text) {
      this.m_s :+= text;
   }
   /**
    * Append the contents of the String instance 
    * to the end of the string.
    *  
    * @param src        The String to append
    */
   void appendString(String &src) {
      this.m_s :+= src.m_s;
   }

   /**
    * Append an integer to the end of the string. 
    *  
    * @param rhs         The integer to append
    */
   void appendNumber(int rhs) {
      this.m_s :+= rhs;
   }

   /**
    * Append a hex integer to the end of the string. 
    *  
    * @param rhs         The integer to append
    * @param radix       numeric base (base 10 for decimal)
    */
   void appendBinary(int rhs) {
      this.m_s :+= dec2hex(rhs,2);
   }
   /**
    * Append a hex integer to the end of the string. 
    *  
    * @param rhs         The integer to append
    * @param radix       numeric base (base 10 for decimal)
    */
   void appendOctal(int rhs) {
      this.m_s :+= dec2hex(rhs,8);
   }
   /**
    * Append a hex integer to the end of the string. 
    *  
    * @param rhs         The integer to append
    * @param radix       numeric base (base 10 for decimal) 
    */
   void appendHex(int rhs) {
      this.m_s :+= dec2hex(rhs,16);
   }

   /**
    * Append a floating point number to the end of the string. 
    * @param rhs         The number to append
    */
   void appendFloatNumber(double rhs) {
      this.m_s :+= rhs;
   }

   /**
    * Append a single character to the end of the string,
    * if that char isn't already at the end of the string.
    *
    * @param ch            The character to append
    * @param appendIfEmpty Append char even if the string is empty.
    */
   void maybeAppend(_str ch, boolean appendIfEmpty=false) {
      int orig_length = length(m_s);
      if (orig_length <= 0 && appendIfEmpty) {
         this.m_s = ch;
      } else if (substr(this.m_s,orig_length,1) != ch) {
         this.m_s :+= ch;
      }
   }
   /**
    * Append a file sepearator ('/' or '\') character to the end
    * of the string if it doesn't already have one. 
    */
   void maybeAppendFileSep() {
      maybeAppend(FILESEP);
   }
   /**
    * Append a path sepearator (':' or ';') character to the end of
    * the string if it doesn't already have one. 
    */
   void maybeAppendPathSep() {
      maybeAppend(PATHSEP);
   }

   /**
    * Prepend the contents of the given string to the beginning of
    * the string. 
    *
    * @param text       The string to prepend
    */
   void prepend(_str text) {
      if (this.m_s == null) {
         this.m_s = text;
      } else if (text != null) {
         this.m_s = text :+ this.m_s;
      }
   }

   /**
    * Prepend the contents of the given String to the beginning of 
    * the string. 
    *
    * @param src        The String to prepend
    */
   void prependString(String &src) {
      if (this.m_s == null) {
         this.m_s = src.m_s;
      } else if (src.m_s != null) {
         this.m_s = src.m_s :+ this.m_s;
      }
   }

   /**
    * Prepend a single character to the beginning of the string,
    * if that char isn't already at the beginning of the string.
    *
    * @param ch            The character to prepend
    * @param appendIfEmpty Append char even if the string is empty.
    */
   void maybePrepend(_str ch, boolean appendIfEmpty=false) {
      if (length(this.m_s)==0 && appendIfEmpty) {
         this.m_s = ch;
      } else if (substr(this.m_s,1,1) :!= ch) {
         this.m_s = ch :+ this.m_s;
      }
   }

   /**
    * Surround the contents of this string with the given 
    * string(m_s).  If the 'after' string is null, use 'text' both 
    * before and after. 
    *
    * @param text       The string to prepend
    * @param after      (optional) The string to append
    */
   void surround(_str text, _str after=null) {
      if (after==null) {
         this.m_s = text :+ this.m_s :+ text;
      } else {
         this.m_s = text :+ this.m_s :+ after;
      }
   }

   /**
    * Surround the contents of this string with the given
    * the given String(m_s).
    *
    * @param text       The String to prepend
    * @param after      The String to append
    */
   void surroundString(String text, String after=null) {
      if (after==null) {
         this.m_s = text.m_s :+ this.m_s :+ text.m_s;
      } else {
         this.m_s = text.m_s :+ this.m_s :+ after.m_s;
      }
   }

   /**
    * Insert the contents of the string at the given position in
    * the string. 
    *
    * @param text       The string to append
    * @param start      The position to insert at (default 0) if 
    *                   start > textLen, append to string.
    */
   void insert(_str text, int start=1) {
      if (text != null) {
         this.m_s = substr(m_s,1,start-1) :+ text :+ substr(m_s,start);
      }
   }
   /**
    * Insert the contents of the string at the given position in
    * the string. 
    *
    * @param text       The string to append
    * @param start      The position to insert at (default 0) if 
    *                   start > textLen, append to string.
    */
   void insertString(String &text, int start=1) {
      if (text.m_s != null) {
         this.m_s = substr(m_s,1,start-1) :+ text.m_s :+ substr(m_s,start);
      }
   }

   /**
    * Replace 'len' characters starting at the given position in 
    * the string with the supplied replacement string. 
    *
    * @param start      Position where string to be replaced 
    *                   starts.
    * @param len        Length of string to be replaced.
    * @param rep        String inserted in place of the removed string.
    */
   void replace(int start, int len, _str rep) {
      if (rep == null) {
         this.m_s = substr(m_s,1,start-1) :+ substr(m_s,start+len);
      } else {
         this.m_s = substr(m_s,1,start-1) :+ rep :+ substr(m_s,start+len);
      }
   }
   /**
    * Replace 'len' characters starting at the given position in 
    * the string with the supplied replacement string. 
    *
    * @param start      Position where string to be replaced 
    *                   starts.
    * @param len        Length of string to be replaced.
    * @param rep        String inserted in place of the removed string.
    */
   void replaceString(int start, int len, String &rep) {
      if (rep.m_s == null) {
         this.m_s = substr(m_s,1,start-1) :+ substr(m_s,start+len);
      } else {
         this.m_s = substr(m_s,1,start-1) :+ rep.m_s :+ substr(m_s,start+len);
      }
   }

   /**
    * Replace all occurrances of a character
    *
    * @param ch      The character to replace
    * @param repl_ch The character to insert in place of the removed character
    */
   void replaceFirstChar(_str ch, _str repl_ch) {
      int p = pos(ch, this.m_s);
      if (p > 0) {
         this.m_s = substr(this.m_s, 1, p-1) :+ repl_ch :+ substr(this.m_s, p+length(ch));
      }
   }

   /**
    * Replace all occurrances of a pattern using pos for searching
    *
    * @param pattern       Pattern to be replaced
    * @param rep_pattern   Pattern to replace with 
    * @param options       options for string search
    */
   void replaceFirst(_str pattern, _str rep_pattern, _str options='') {
      int p = pos(pattern, this.m_s, 1, options);
      if (p > 0) {
         this.m_s = substr(this.m_s, 1, p-1) :+ rep_pattern :+ substr(this.m_s, p+pos(''));
      }
   }

   /**
    * Replace all occurrances of a pattern using pos for searching
    *
    * @param pattern       Pattern to be replaced
    * @param rep_pattern   Pattern to replace with 
    * @param options       options for string search
    */
   void replaceFirstString(String pattern, String rep_pattern, _str options='') {
      int p = pos(pattern.m_s, this.m_s, 1, options);
      if (p > 0) {
         this.m_s = substr(this.m_s, 1, p-1) :+ rep_pattern.m_s :+ substr(this.m_s, p+pos(''));
      }
   }

   /**
    * Replace all occurrances of a character
    *
    * @param ch      The character to replace
    * @param repl_ch The character to insert in place of the removed character
    */
   void replaceAllChars(_str ch, _str repl_ch) {
      this.m_s = stranslate(this.m_s,repl_ch,ch);
   }

   /**
    * Replace all occurrances of a pattern using pos for searching
    *
    * @param pattern       Pattern to be replaced
    * @param rep_pattern   Pattern to replace with 
    * @param options       options for string search
    */
   void replaceAll(_str pattern, _str rep_pattern, _str options='') {
      this.m_s = stranslate(this.m_s,rep_pattern,pattern,options);
   }

   /**
    * Replace all occurrances of a pattern using pos for searching
    *
    * @param pattern       Pattern to be replaced
    * @param rep_pattern   Pattern to replace with 
    * @param options       options for string search
    */
   void replaceAllStrings(String pattern, String rep_pattern, _str options='') {
      this.m_s = stranslate(this.m_s,rep_pattern.m_s,pattern.m_s,options);
   }

   /**
    * Delete 'n' characters starting at the given position.
    *
    * @param start      The position to begin removing chars at
    * @param num_chars  The number of characters to delete
    */
   void remove(int start, int num_chars=1) {
      this.m_s = substr(m_s,1,start-1) :+ substr(m_s,start+num_chars);
   }

   /**
    * Trim 'n' characters off of the end of the string.
    * @param num_chars  The number of characters to delete (default 1)
    */
   void trim(int num_chars=1) {
      this.m_s = substr(m_s,1,length(m_s)-num_chars);
   }

   /**
    * Strip the given character off the beginning or end of the string
    *
    * @param ch         Character to strip
    * @param ltb        Strip leading, trailing, or both?  'L', 'T', or 'B'
    * @param strip_all  Strip all matches or just the first one?
    */
   void stripChars(_str ch, _str ltb='B', boolean strip_all=true) {
      ltb=lowcase(ltb);
      if ((ltb:=='b' || ltb:=='l') && firstChar() :== ch) {
         this.m_s = substr(m_s,2);
      }
      if ((ltb:=='b' || ltb:=='t') && lastChar() :== ch) {
         this.m_s = substr(m_s,1,length(m_s)-1);
      }
      if (strip_all) {
         if (ltb:=='b' || ltb:=='l') {
            while (firstChar() :== ch) {
               this.m_s = substr(m_s,2);
            }
         }
         if (ltb:=='b' || ltb:=='t') {
            while (lastChar() :== ch) {
               this.m_s = substr(m_s,1,length(m_s)-1);
            }
         }
      }
   }
   /**
    * Strip the given character off the beginning or end of the string
    *
    * @param strip_chars   Set of characters to strip, for example " \t"
    * @param ltb           Strip leading, trailing, or both?  'L', 'T', or 'B'
    * @param strip_all     Strip all matches or just the first one?
    */
   void stripMulti(_str strip_chars, _str ltb='B', boolean strip_all=true) {
      ltb=lowcase(ltb);
      if ((ltb:=='b' || ltb:=='l') && pos(firstChar(),strip_chars) > 0) {
         this.m_s = substr(m_s,2);
      }
      if ((ltb:=='b' || ltb:=='t') && pos(lastChar(),strip_chars) > 0) {
         this.m_s = substr(m_s,1,length(m_s)-1);
      }
      if (strip_all) {
         if (ltb:=='b' || ltb:=='l') {
            while (pos(firstChar(),strip_chars) > 0) {
               this.m_s = substr(m_s,2);
            }
         }
         if (ltb:=='b' || ltb:=='t') {
            while (pos(lastChar(),strip_chars) > 0) {
               this.m_s = substr(m_s,1,length(m_s)-1);
            }
         }
      }
   }

   /**
    * Symmetrically pads string to <i>width</i> characters.
    * If the length of <i>string</i> is less than <i>width</i> characters, the
    * left and right of the returned string will be padded with the <i>pad</i> character.
    * The right will always be padded the same or more than the left.  If the length of
    * <i>string</i> is greater than or equal to <i>width</i> characters, the returned
    * string will be truncated on the left and right.  The right will always be
    * truncated the same or more than the left.  Pad defaults to "".
    *
    * @param width   number of characters to center string to
    * @param pad     pad character, defaults to space
    */
   void centerString(int width,_str pad=" ") {
      m_s = center(m_s,width,pad);
   }

   /**
    * Search a string for another substring.
    *
    * @param pattern    String to search for
    * @param start      Position to begin searching at
    * @param options    Search options, see {@link pos()}
    *
    * @return position in string otherwise, 0 if not found
    */
   int strPos(_str string, int start=0, _str options='') /*const*/ {
      return pos(string, this.m_s, start, options);
   }
   /**
    * Search a string for another substring.
    *
    * @param pattern    String to search for
    * @param start      Position to begin searching at
    * @param options    Search options, see {@link pos()}
    *
    * @return position in string otherwise, 0 if not found
    */
   int stringPos(String& string, int start=0, _str options='') /*const*/ {
      return pos(string.m_s, this.m_s, start, options);
   }
   /**
    * Search a string last occurrence of the given pattern.
    *
    * @param pattern    String to search for
    * @param start      Position to begin searching at
    * @param options    Search options, see {@link lastpos()} 
    *  
    * @return position in string otherwise, 0 if not found
    */
   int strLastpos(_str pattern, int start=-1, _str options='') /*const*/ {
      return pos(pattern, this.m_s, start, options);
   }
   /**
    * Search a string last occurrence of the given pattern.
    *
    * @param pattern    String to search for
    * @param start      Position to begin searching at
    * @param options    Search options, see {@link lastpos()} 
    *  
    * @return position in string otherwise, 0 if not found
    */
   int stringLastpos(String &pattern, int start=-1, _str options='') /*const*/ {
      return pos(pattern.m_s, this.m_s, start, options);
   }
   /**
    * Return a copy of the a search match.
    *
    * @param group      the match group to get
    */
   _str getMatch(_str group='') /*const*/ {
      return substr(this.m_s, pos('S'group), pos(group));
   }
   /**
    * Return the length of the search match.
    *
    * @param group      the match group to get
    */
   int getMatchLength(_str group='') /*const*/ {
      return pos(group);
   }
   /**
    * Search a string for a character.
    *
    * @param ch         Character to search for
    * @param start      Position to begin searching at (default 0)
    *
    * @return position in string otherwise, 0 if not found
    */
   int charPos(_str ch, int start=1) /*const*/ {
      return pos(ch,this.m_s);
   }
   /**
    * Search a string last occurrence of the given character.
    *
    * @param ch         Character to search for
    * @param start      Position to begin searching at (default 0)
    *
    * @return position in string otherwise, 0 if not found
    */
   int charLastpos(_str ch, int start=-1) /*const*/ {
      return lastpos(ch,this.m_s,start);
   }

   /**
    * <p>If <i>option</i> =='', this function returns the first character position
    * in <i>string</i> which is not one of the characters in
    * <i>reference</i>.  If <i>string</i> is only composed of characters
    * from <i>reference</i>, then 0 is returned.</p>
    *
    * <p>If <i>option</i> == 'M' , this function returns the first character
    * position in <i>string</i> which matches one of the characters in
    * <i>reference</i>.  If no characters in <i>reference</i> match a
    * character in <i>string</i>, 0 is returned.</p>
    *
    * <p>If <i>start </i>is specified, the searching begins at <i>start</i>.</p>
    */
   int verifyChars(_str reference, _str option="",int start=1) {
      return (int) verify(m_s,reference,option,start);
   }

   /**
    * Make the string all upper-case.
    */
   void makeUpcase() {
      this.m_s = upcase(this.m_s);
   }
   /**
    * Make the string all lower-case.
    */
   void makeLowcase() {
      this.m_s = lowcase(this.m_s);
   }

   /**
    * @return Return an all upper-case copy of this string.
    * @return 0 on success, <0 on error.
    */
   String toUpcase() /*const*/ {
      String ss(upcase(this.m_s));
      return ss;
   }

   /**
    * @return Return an all lower-case copy of this string.
    */
   String toLowcase() /*const*/ {
      String ss(lowcase(this.m_s));
      return ss;
   }

   /**
    * Compare this object with the given object of a compatible
    * class.  The right hand side (rhs) object will always be a
    * valid and initialized class instance.
    * <p>
    * Note that overriding this method effects both the equality
    * == and inequality != operations
    *
    * @param rhs  object on the right hand side of comparison
    *
    * @return 'true' if this equals 'rhs', false otherwise
    */
   boolean equals(IEquals &rhs) {
      if (rhs==null) {
         return (this==null);
      }
      if (!(rhs instanceof sc.lang.String)) {
         return false;
      }
      if (((String)rhs).m_s == null) {
         return (this.m_s==null);
      }
      if (this.m_s == null) return 1;
      return (this.m_s :== ((String)rhs).m_s);
   }

   /**
    * Compare this object with the given object of a compatible
    * class.  The right hand side (rhs) object will always be a
    * valid and initialized class instance.
    * <p>
    * Note that overriding this method effects both the equality
    * == and inequality != operations
    *
    * @param rhs  object on the right hand side of comparison
    *
    * @return 'true' if this equals 'rhs', false otherwise
    */
   boolean equalToIgnoreCase(String &rhs) {
      if (rhs==null) {
         return (this==null);
      }
      if (rhs.m_s == null) {
         return (this.m_s==null);
      }
      if (this.m_s == null) return 1;
      return strieq(this.m_s, rhs.m_s);
   }

   /**
    * Compare this string with the given string object.
    * <p>
    * Note that overriding this method effects all relational 
    * operators.
    *
    * @param rhs  object on the right hand side of comparison
    *
    * @return &lt;0 if 'this' is less than 'rhs', 0 if 'this'
    *         equals 'rhs', and &gt;0 if 'this' is greater than
    *         'rhs'.
    */
   int compare(IComparable &rhs) {
      if (rhs==null) {
         return (this==null)? 0:-1;
      }
      if (((String)rhs).m_s == null) {
         return (this.m_s==null)? 0:-1;
      }
      if (this.m_s == null) return 1;
      if (this.m_s :== ((String)rhs).m_s) return 0;
      return (this.m_s < ((String)rhs).m_s)? -1:1;
   }

   /**
    * Compare this object with the given object of a compatible
    * class.  The right hand side (rhs) object will always be a
    * valid and initialized class instance.
    * <p>
    * Note that overriding this method effects both the equality
    * == and inequality != operations
    *
    * @param rhs  object on the right hand side of comparison
    *
    * @return &lt;0 if 'this' is less than 'rhs', 0 if 'this'
    *         equals 'rhs', and &gt;0 if 'this' is greater than
    *         'rhs'.
    */
   int compareStr(_str rhs) {
      if (rhs == null) {
         return (this==null || this.m_s==null)? 0:-1;
      }
      if (this.m_s == null) return 1;
      if (this.m_s :== rhs) return 0;
      return (this.m_s < rhs)? -1:1;
   }

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
   static int compareString(String& lhs, String &rhs) {
      return lhs.compare(rhs);
   }
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
   static int compareStringIgnoreCase(String& lhs, String &rhs) {
      if (rhs == null) {
         return (lhs==null || lhs.m_s==null)? 0:-1;
      }
      if (rhs == null) {
         return (lhs.m_s==null)? 1:0;
      }
      String low_lhs = lhs.toLowcase();
      String low_rhs = rhs.toLowcase();
      return low_lhs.compare(low_rhs);
   }

   /**
    * Compare to the specified string using specified 
    * case-sensitivity rules. 
    *
    * @param string String to compare to.
    * @param caseSensitive
    *               true = case-sensitive comparison
    *               false = case-insensitive comparison
    *
    * @return <  0 less than rhs
    *         == 0 equal to rhs
    *         >  0 greater than rhs
    */
   int compareCase(String& rhs, boolean caseSensitive) /*const*/ {
      if (rhs==null) {
         return (this==null)? 0:-1;
      }
      if (rhs.m_s == null) {
         return (this.m_s==null)? 0:-1;
      }
      if (this.m_s == null) return 1;
      if (this.m_s :== rhs.m_s) return 0;
      if (caseSensitive) {
         return (this.m_s < rhs.m_s)? -1:1;
      } else {
         _str low_lhs = lowcase(this.m_s);
         _str low_rhs = lowcase(rhs.m_s);
         if (low_lhs :== low_rhs) return 0;
         return (low_lhs < low_rhs)? -1:1;
      }
   }

   /**
    * Check to see if this string begins with the specified pattern
    *
    * @param pattern    Pattern to look for 
    * @param options    Search options, see {@link pos()}
    *
    * @return true if it begins with it, false otherwise
    */
   boolean beginsWith(_str pattern, _str options='') /*const*/ {
      return (pos(pattern, this.m_s, 1, options) == 1);
   }
   /**
    * Check to see if this string begins with the specified pattern
    *
    * @param pattern    Pattern to look for 
    * @param options    Search options, see {@link pos()}
    *
    * @return true if it begins with it, false otherwise
    */
   boolean beginsWithString(String pattern, _str options='') /*const*/ {
      return (pos(pattern.m_s, this.m_s, 1, options) == 1);
   }

   /**
    * Check to see if this string begins with the specified 
    * character
    *
    * @param ch         Character to look for
    * @param options    Search options, see {@link pos()}
    *
    * @return true if it begins with it, false otherwise
    */
   boolean beginsWithChar(_str ch) /*const*/ {
      return (substr(this.m_s,1,1) :== ch);
   }


   /**
    * Check to see if this string ends with the specified pattern
    *
    * @param pattern    Pattern to look for 
    * @param options    Search options, see {@link pos()}
    *
    * @return true if it begins with it, false otherwise
    */
   boolean endsWith(_str pattern, _str options='') /*const*/ {
      return (lastpos(pattern, this.m_s, -1, options) == length(this.m_s)-length(pattern)+1);
   }
   /**
    * Check to see if this string ends with the specified pattern
    *
    * @param pattern    Pattern to look for 
    * @param options    Search options, see {@link pos()}
    *
    * @return true if it begins with it, false otherwise
    */
   boolean endsWithString(String pattern, _str options='') /*const*/ {
      return (lastpos(pattern.m_s, this.m_s, -1, options) == length(this.m_s)-length(pattern.m_s)+1);
   }

   /**
    * Check to see if this string ends with the specified character
    *
    * @param ch         Character to look for
    * @param options    Search options, see {@link pos()}
    *
    * @return true if it begins with it, false otherwise
    */
   boolean endsWithChar(_str ch) /*const*/ {
      return (substr(this.m_s,length(this.m_s),1) :== ch);
   }

   /**
    * @return Generate a string as the hash key for this object.
    */
   _str getHashKey() {
      return this.m_s;
   }

   /**
    * Split the string into an array of strings pivoting on line
    * endings.  This works for all types of line endings, Unix (LF),
    * DOS (CR,LF), and Mac (CR).
    *
    * @param a                   array that holds the split strings
    * @param stripLineEndings    strip line endings for each line
    */
   void splitLines(_str (&a)[], boolean stripLineEndings=true) /*const*/ {
      a._makeempty();
      int start=1;
      loop {
         // look for a newline (using regex)
         int p = pos(this.m_s,"[\n\r]",start,'r');
         // no more matches, check for extra text
         if (!p) {
            if (start < length(this.m_s)) {
               a[a._length()] = substr(m_s,start);
            }
            return;
         }
         // if not stripping line endings, adjust end point first
         if (!stripLineEndings) {
            if (substr(m_s,p,1) :== "\r") {
               ++p;
            }
            if (substr(m_s,p,1) :== "\n") {
               ++p;
            }
         }
         // extract the substring
         a[a._length()] = substr(m_s,start,p-start);
         // if stripping line endings, adjust the end point
         if (stripLineEndings) {
            if (substr(m_s,p,1) :== "\r") {
               ++p;
            }
            if (substr(m_s,p,1) :== "\n") {
               ++p;
            }
         }
         // next please
         start = p;
      }
   }
   /**
    * @return Split the string into an array of strings pivoting on
    * line endings.  This works for all types of line endings, Unix 
    * (LF), DOS (CR,LF), and Mac (CR). 
    *
    * @param a                   array that holds the split strings
    * @param stripLineEndings    strip line endings for each line
    */
   typeless splitLinesToArray(boolean stripLineEndings=true) /*const*/ {
      _str a[];
      splitLines(a,stripLineEndings);
      return a;
   }

   /**
    * Split the string into an array of strings pivoting on the given
    * delimeter character.
    *
    * @param delim  character delimeter to split string at
    * @param a      array that holds the split strings
    * @param options    Search options, see {@link pos()}
    *
    * @return 0 on succes, <0 otherwise
    */
   void split(_str delim, _str (&a)[], _str options='') /*const*/ {
      a._makeempty();
      int start=1;
      loop {
         // look for a newline (using regex)
         int p = pos(delim,this.m_s,start,options);
         // no more matches, check for extra text
         if (!p) {
            if (start < length(this.m_s)) {
               a[a._length()] = substr(m_s,start);
            }
            return;
         }
         // extract the substring
         a[a._length()] = substr(m_s,start,p-start);
         // next please
         start = p + pos('');
      }
   }

   /**
    * @return
    * Returns a reference to an element in a collection, addressing
    * the element by the given index.  Returns null if there is no
    * such key.
    *
    * @param i  index of item to look up
    */
   typeless _array_el(int i) {
      if (i < 0 || i > (length(this.m_s)-1)) return '';
      return substr(this.m_s,i+1,1);
   }

   /**
    * @return Returns the <code>char</code> value at the specified
    * index. An index ranges from 0 to getLength()-1.
    *
    * @param i    index of item to look up
    */
   _str charAt(int i) {
      if (i < 0 || i > (length(this.m_s)-1)) return '';
      return substr(this.m_s,i+1,1);
   }

   /**
    * Converts this string to a new character array.
    *
    * @return  an array in which each character of this string is 
    *          one string entry.
    */
   typeless toCharArray() {
      _str a[];
      int i, n=length(m_s);
      for(i=0; i<n; ++i) {
         a[i] = substr(m_s,i+1,1);
      }
      return a;
   }

   /**
    * Split the string into an array of strings pivoting on the given
    * delimeter character.
    *
    * @param delim  character delimeter to split string at
    * @param a      array that holds the split strings
    * @param options    Search options, see {@link pos()}
    *
    * @return 0 on succes, <0 otherwise
    */
   typeless splitToArray(_str delim, _str options='') /*const*/ {
      _str a[];
      split(delim,a,options);
      return a;
   }

   /**
    * Parse the first item off of this string and return it.
    * Setting the remainder of the string to the 'rest' argument.
    *
    * @param delim      character delimeter to split string at
    * @param rest       the rest of the string, maybe be 'this'
    * @param start      [default 1] column to start on
    * @param options    Search options, see {@link pos()}
    *
    * @return the first item off of the list
    */
   String parseString(_str delim, String &rest, int start=1, _str options='') /*const*/ {
      p := pos(delim, this.m_s, start, options);
      if (!p) {
         String front = this;
         rest.m_s = "";
         return front;
      }
      String front(substr(this.m_s, start, p-start));
      rest.m_s = substr(this.m_s, p+pos(''));
      return front;
   }

   /**
    * Parse the last item off of this string and return it. Setting
    * the beginning of the string to the 'front' argument.
    *
    * @param delim      character delimeter to split string at
    * @param front      the rest of the string, maybe be 'this'
    * @param start      [default 1] column to start on
    * @param options    Search options, see {@link pos()}
    *
    * @return the first item off of the list
    */
   String parseStringLast(_str delim, String &front, int start=-1, _str options='') /*const*/ {
      p := lastpos(delim, this.m_s, start, options);
      String tail;
      if (!p) {
         front.m_s = this.m_s;
      } else {
         tail.m_s = substr(this.m_s,start+pos(''));
         front.m_s = substr(this.m_s,1,start-1);
      }
      return tail;
   }

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
    * Warning: Overflow is possible on values greater than 2^31.
    * </p>
    * 
    * @return 32-bit signed int.
    */
   int toInt() /*const*/ {
      // TBF:  need to implement this in C code using POMString
      return (int) this.m_s;
   }

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
   double toFloat() /*const*/ {
      // TBF:  need to implement this in C code using POMString
      return (double) this.m_s;
   }

    /**
     * Tests if two string regions are equal.
     * <p>
     * A substring of this <tt>String</tt> object is compared to a substring
     * of the argument other. The result is true if these substrings
     * represent identical character sequences. The substring of this
     * <tt>String</tt> object to be compared begins at index <tt>toffset</tt>
     * and has length <tt>len</tt>. The substring of other to be compared
     * begins at index <tt>ooffset</tt> and has length <tt>len</tt>. The
     * result is <tt>false</tt> if and only if at least one of the following
     * is true:
     * <ul><li><tt>toffset</tt> is negative.
     * <li><tt>ooffset</tt> is negative.
     * <li><tt>toffset+len</tt> is greater than the length of this
     * <tt>String</tt> object.
     * <li><tt>ooffset+len</tt> is greater than the length of the other
     * argument.
     * <li>There is some nonnegative integer <i>k</i> less than <tt>len</tt>
     * such that:
     * <tt>this.charAt(toffset+<i>k</i>)&nbsp;!=&nbsp;other.charAt(ooffset+<i>k</i>)</tt>
     * </ul>
     *
     * @param   toffset   the starting offset of the subregion in this string.
     * @param   other     the string argument.
     * @param   ooffset   the starting offset of the subregion in the string
     *                    argument.
     * @param   len       the number of characters to compare.
     * @return  <code>true</code> if the specified subregion of this string
     *          exactly matches the specified subregion of the string argument;
     *          <code>false</code> otherwise.
     */
    boolean regionMatches(int toffset, String other, int ooffset, int len) {
       String ss = this.sub(toffset,len);
       String ts = other.sub(ooffset,len);
       return (ss.m_s :== ts.m_s);
    }

    /**
     * Tests if two string regions are equal.
     * <p>
     * A substring of this <tt>String</tt> object is compared to a substring
     * of the argument <tt>other</tt>. The result is <tt>true</tt> if these
     * substrings represent character sequences that are the same, ignoring
     * case if and only if <tt>ignoreCase</tt> is true. The substring of
     * this <tt>String</tt> object to be compared begins at index
     * <tt>toffset</tt> and has length <tt>len</tt>. The substring of
     * <tt>other</tt> to be compared begins at index <tt>ooffset</tt> and
     * has length <tt>len</tt>. The result is <tt>false</tt> if and only if
     * at least one of the following is true:
     * <ul><li><tt>toffset</tt> is negative.
     * <li><tt>ooffset</tt> is negative.
     * <li><tt>toffset+len</tt> is greater than the length of this
     * <tt>String</tt> object.
     * <li><tt>ooffset+len</tt> is greater than the length of the other
     * argument.
     * <li><tt>ignoreCase</tt> is <tt>false</tt> and there is some nonnegative
     * integer <i>k</i> less than <tt>len</tt> such that:
     * <blockquote><pre>
     * this.charAt(toffset+k) != other.charAt(ooffset+k)
     * </pre></blockquote>
     * <li><tt>ignoreCase</tt> is <tt>true</tt> and there is some nonnegative
     * integer <i>k</i> less than <tt>len</tt> such that:
     * <blockquote><pre>
     * Character.toLowerCase(this.charAt(toffset+k)) !=
               Character.toLowerCase(other.charAt(ooffset+k))
     * </pre></blockquote>
     * and:
     * <blockquote><pre>
     * Character.toUpperCase(this.charAt(toffset+k)) !=
     *         Character.toUpperCase(other.charAt(ooffset+k))
     * </pre></blockquote>
     * </ul>
     *
     * @param   ignoreCase   if <code>true</code>, ignore case when comparing
     *                       characters.
     * @param   toffset      the starting offset of the subregion in this
     *                       string.
     * @param   other        the string argument.
     * @param   ooffset      the starting offset of the subregion in the string
     *                       argument.
     * @param   len          the number of characters to compare.
     * @return  <code>true</code> if the specified subregion of this string
     *          matches the specified subregion of the string argument;
     *          <code>false</code> otherwise. Whether the matching is exact
     *          or case insensitive depends on the <code>ignoreCase</code>
     *          argument.
     */
    boolean regionMatchesIgnoreCase(int toffset, String other, int ooffset, int len) {
       String ss = this.sub(toffset,len);
       String ts = other.sub(ooffset,len);
       return strieq(ss, ts);
    }

    /**
     * Returns a formatted string using the specified format string and
     * arguments.
     *
     * @param  A format string
     * @param  args
     *         Arguments referenced by the format specifiers in the format
     *         string.  If there are more arguments than format specifiers, the
     *         extra arguments are ignored.  The number of arguments is
     *         variable and may be zero.
     * @return  A formatted string
     * @see  nls
     */
    static String format(_str format, ...) {
       _str result='';
       int i=1;
       int arg_number=1;
       for (;;) {
          int j=pos('%s([123456789]|)',format,i,'r');
          if ( ! j ) {
            result :+= substr(format,i);
            break;
          }
          typeless n;
          int len=pos('');
          if (len>=3) {
             n=substr(format,j+2,1);
          } else {
             n=arg_number;
          }
          if (arg(2)._varformat()==VF_ARRAY) {
             if(arg(2)[n]._varformat()==VF_EMPTY) {
                result :+= substr(format,i,j-i);
             } else {
                result :+= substr(format,i,j-i):+arg(2)[n];
             }
          } else {
             _str argNp1='';
             if (arg()>n && arg(n+1)._varformat()!=VF_EMPTY) {
                argNp1 = arg(n+1);
             }
             result :+= substr(format,i,j-i):+argNp1;
          }
          arg_number=arg_number+1;
          i=j+len;
       }
       String s(result);
       return s;
    }

};

