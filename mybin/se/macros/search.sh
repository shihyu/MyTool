////////////////////////////////////////////////////////////////////////////////////
// $Revision: 40523 $
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
#ifndef __SEARCH_SH__
#define __SEARCH_SH__

// regular expression syntax names
#define RE_TYPE_UNIX_STRING       "Regular expression (UNIX)"
#define RE_TYPE_BRIEF_STRING      "Regular expression (Brief)"
#define RE_TYPE_SLICKEDIT_STRING  "Regular expression (SlickEdit)"
#define RE_TYPE_PERL_STRING       "Regular expression (Perl)"
#define RE_TYPE_WILDCARD_STRING   "Wildcards (*,?)"
#define RE_TYPE_NONE              "None"

// search range names
#define SEARCH_IN_NONE               "No buffers selected"
#define SEARCH_IN_ECL_NONE           "No SlickEdit buffers selected"
#define SEARCH_IN_CURRENT_BUFFER     "<Current Buffer>"
#define SEARCH_IN_CURRENT_SELECTION  "<Current Selection>"
#define SEARCH_IN_CURRENT_PROC       "<Current Procedure>"
#define SEARCH_IN_ALL_BUFFERS        "<All Buffers>"
#define SEARCH_IN_ALL_ECL_BUFFERS    "<All SlickEdit Buffers>"

// current find toolbar mode
#define VSSEARCHMODE_FIND              0
#define VSSEARCHMODE_FINDINFILES       1
#define VSSEARCHMODE_REPLACE           2
#define VSSEARCHMODE_REPLACEINFILES    3

struct GREP_LOGINFO {
   _str path;
   int mfflags;
   int view_id;
   int first_line;
   int last_line;
   int last_col;
};


/**
 * When the <b>p_TruncateLength</b> is non-zero, replace operations
 * are skipped if the resulting line becomes longer than the truncation
 * length.  This function is used in conjunction with
 * <b>_SearchQNofSkipped</b> and <b>_SearchQSkipped</b> to
 * return information about what was skipped.  Call this function before
 * performing a search and replace operation to reset NofSkipped and
 * Skipped lines data returned by the <b>_SearchQNofSkipped</b> and
 * <b>_SearchQSkipped</b> functions.
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 *
 */
extern void _SearchInitSkipped(int zero_reserved);
/**
 * When the <b>p_TruncateLength</b> is non-zero, replace operations
 * are skipped if the resulting line becomes longer than the truncation
 * length.  The <b>_SearchInitSkipped</b> function is used in
 * conjunction with <b>_SearchQNofSkipped</b> and
 * <b>_SearchQSkipped</b> to return information about what was
 * skipped.  Call this function before performing a search and replace
 * operation to reset NofSkipped and Skipped lines data returned by the
 * <b>_SearchQNofSkipped</b> and <b>_SearchQSkipped</b>
 * functions.
 *
 * @return Returns a space delimited list of line numbers where the replace
 * operation that was skipped.
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 *
 */
extern _str _SearchQSkipped();
/**
 * When the <b>p_TruncateLength</b> is non-zero, replace operations
 * are skipped if the resulting line becomes longer than the truncation
 * length.  The <b>_SearchInitSkipped</b> function is used in
 * conjunction with <b>_SearchQNofSkipped</b> and
 * <b>_SearchQSkipped</b> to return information about what was
 * skipped.  Call this function before performing a search and replace
 * operation to reset NofSkipped and Skipped lines data returned by the
 * <b>_SearchQNofSkipped</b> and <b>_SearchQSkipped</b>
 * functions.
 *
 * @return Returns the number of replace operations that were skipped.
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 *
 */
extern int _SearchQNofSkipped();


#endif /* __SEARCH_SH__ */
