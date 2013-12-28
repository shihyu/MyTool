#ifndef STRMATCH_H
#define STRMATCH_H

#include "re_group.h"
#include "vsdecl.h"
/**
 * Capture match length, start, and regex match groups (@link 
 * vsStrMatch()). 
 *  
 */
struct str_match_t {
   int m_match_length;
   int m_match_start;   
   unsigned int m_group_hit_flags;
   re_group_t m_group[MAX_RE_GROUPS];

   str_match_t();
   ~str_match_t();

   /**
    * @return int Return length from captured search (@link 
    *         vsStrMatch()).
    */
   int get_length();

   /**
    * @return int Return start offset from captured search (@link 
    *         vsStrMatch()).  Offsets start at 0 (NOT 1).
    *  
    *          NOTE: this differs from the return value from
    *          vsStrMatch()/vsStrPos()/vsStrLastPos().
    */
   int get_start();

   /**
   * @return Returns true if search captured a tagged expression 
   *         (@link vsStrMatch()).
   * 
   * <p>
   * For SlickEdit and Brief regular expressions the first tagged expression
   * is 0 and the last is 9.  For UNIX, the first tagged expression is 1 and
   * the last is 0. 
   *  
   * @param group    Tagged expression number.
   */
   bool match_group(unsigned int group);

   /**
   * @return Returns length of tagged expression found from
   * captured search (@link vsStrMatch()). 
   *  
   * <p>
   * For SlickEdit and Brief regular expressions the first tagged expression
   * is 0 and the last is 9.  For UNIX, the first tagged expression is 1 and
   * the last is 0.
   *
   * @param group    Tagged expression number.
   */
   int get_group_length(unsigned int group);

   /**
   * @return Returns start offset of tagged expression found from
   * captured search (@link vsStrMatch()). Offsets start at 0 (NOT 
   * 1). 
   *  
   *        NOTE: this differs from the return value from
   *        vsStrMatch()/vsStrPos()/vsStrLastPos().
   *  
   * <p>
   * For SlickEdit and Brief regular expressions the first tagged expression
   * is 0 and the last is 9.  For UNIX, the first tagged expression is 1 and
   * the last is 0.
   *
   * @param group    Tagged expression number.
   */
   int get_group_start(unsigned int group);
};

inline str_match_t::str_match_t() :
   m_match_length(0),
   m_match_start(0),
   m_group_hit_flags(0)
{
}

inline str_match_t::~str_match_t()
{
}

inline int str_match_t::get_length()
{
   return m_match_length;
}

inline int str_match_t::get_start()
{
   return (m_match_start) ? (m_match_start - 1) : 0;
}

inline bool str_match_t::match_group(unsigned int group)
{
   return ((m_group_hit_flags & (1 << group)) && (group < MAX_RE_GROUPS));
}

inline int str_match_t::get_group_length(unsigned int group)
{
   if ((m_group_hit_flags & (1 << group)) && (group < MAX_RE_GROUPS)) {
      return(m_group[group].end - m_group[group].begin);
   }
   return 0;
}

inline int str_match_t::get_group_start(unsigned int group)
{
   if ((m_group_hit_flags & (1 << group)) && (group < MAX_RE_GROUPS)) {
      int s = m_group[group].begin;
      return (s) ? (s - 1) : 0;
   }
   return 0;
}

/** 
 * Thread-safe alternative to vsStrPos/vsStrLastPos. 
 *  
 * @return Searches specified direction from start position 
 * specified for string given.  If string is found, the position 
 * of the string found is returned.  First character of string 
 * is 1. Returns 0 if the string is not found. 
 *  
 * @param pSearchFor	String to search for.
 * 
 * @param SearchForLen	Number of bytes in <i>pSearchFor</i>.
 * You can specify -1 if pSearchFor is NULL 
 * terminated.
 * 
 * @param pBuf	Buffer to search in.
 * 
 * @param BufLen	Number of bytes in <i>pBuf</i>.
 * 
 * @param start	Character position to start searching from 
 * 1..<i>BufLen</i>.  Specify 1 to start search 
 * from firstcharacter.
 * 
 * @param SearchFlags	One or more of the following flags:
 * 
 * <dl>
 * <dt>VSSTRPOSFLAG_IGNORE_CASE</dt><dd>
 * 	Case insensitive search.</dd>
 * <dt>VSSTRPOSFLAG_RE</dt><dd>
 * 	SlickEdit regular expression search.  See
 * <b>SlickEdit Regular Expressions</b>.</dd>
 * <dt>VSSTRPOSFLAG_WORD</dt><dd>
 * 	Reserved for future used.</dd>
 * <dt>VSSTRPOSFLAG_UNIXRE</dt><dd>
 * 	UNIX regular expression search.  See
 * <b>UNIX Regular Expressions</b>.</dd>
 * <dt>VSSTRPOSFLAG_BINARY</dt><dd>
 * 	Binary search.  This allows start positions in
 * the middle of a DBCS or UTF-8 character.
 * This option is useful when editing binary
 * files (in SBCS/DBCS mode) which may 
 * contain characters which look like DBCS 
 * but are not.  For example, if you search for
 * the character 'a', it will not be found as the
 * second character of a DBCS sequence unless
 * this option is specified.</dd>
 * <dt>VSSTRPOSFLAG_ACP </dt><dd>
 * 	Specifies that pSearchFor and pBuf contain
 * active code page data and that an
 * SBCS/DBCS mode search should be
 * performed.  This flag is ignored if Unicode 
 * support is not active. </dd>
 * <dt>VSSTRPOSFLAG_BRIEFRE</dt><dd>
 * 	Brief regular expression search.  See
 * <b>Brief Regular Expressions</b>.</dd>
 * <dt>VSSTRPOSFLAG_WILDCARDS</dt><dd>
 *  Wildcards expression search.
 *  See <b>Wildcard Expressions</b>.</dd>
 * </dl>
 *  
 * @param direction Search forward or backward (direction==1 for
 *                  forward, else backward).
 *  
 * @param match_p  (OPTIONAL) Store match length, start, and 
 *                 regex match groups.
 *  
 * @categories String_Functions
 * 
 */ 
EXTERN_C
int VSAPI vsStrMatch(const char *pSearchFor, size_t SearchForLen,
                     const char *pBuf, size_t BufLen,
                     int start, int SearchFlags, int direction,
                     str_match_t* match_p = 0,
                     size_t* ppos = 0);


#endif // STRMATCH_H
