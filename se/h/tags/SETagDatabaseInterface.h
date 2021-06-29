////////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "tags/SETagList.h"
#include "tags/SETagInformation.h"
#include "slickedit/SEString.h"
#include "slickedit/SEArray.h"


namespace slickedit {

/**
 * Tag name comparison options
 */
enum SETagCompareNameMode {
   /**
    * Compare the tag against a prefix.
    */
   SE_TAG_COMPARE_PREFIX,
   /**
    * Expect the tag name to match exactly (same length).
    */
   SE_TAG_COMPARE_EXACT,
   /**
    * Look for a substring match.
    */
   SE_TAG_COMPARE_SUBSTRING,
   /**
    * Look for a regular expression match.
    */
   SE_TAG_COMPARE_REGEX,
   /**
    * Look for an intelligent match by trying to match character-by-character 
    * for acronyms and substrings. 
    */
   SE_TAG_COMPARE_SMART,
};

/**
 * File name comparison options. 
 * All options use the system defined case-sensitivity rules. 
 */
enum SETagCompareClassMode {
   /**
    * Prefix match.
    */
   SE_TAG_COMPARE_CLASS_PREFIX,
   /**
    * Exact string match.
    */
   SE_TAG_COMPARE_CLASS_EXACT,
   /**
    * Prefix match of class name part only.
    */
   SE_TAG_COMPARE_CLASS_ONLY_PREFIX,
   /**
    * Exact string match of class name part only.
    */
   SE_TAG_COMPARE_CLASS_ONLY_EXACT,
};


/**
 * This abstract class represents a programatic interface for querying information 
 * from a tagging information storage mechanism.  This could be the current 
 * set of local variables, the tags in the current file, the tags in a on-disk 
 * tag databse, the tags in an in-memory tag database, or the multiplexed 
 * result of querying several tag database instances in a prescribed order. 
 *  
 * @since 24.0 
 *  
 * @see SETagList
 * @see SEListTagsTarget 
 * @see SETagInformation 
 * @see SETagDatabaseTagList 
 * @see SETagDatabaseLocals 
 * @see SETagDatabaseContext 
 * @see SETagDatabaseOnDisk 
 * @see SETagDatabaseMultiplexer 
 */
class VSDLLEXPORT SETagDatabaseInterface {
public:
   /**
    * Default constructor
    */
   SETagDatabaseInterface();

   /**
    * No copy constructors for abstract class
    */
   SETagDatabaseInterface(const SETagDatabaseInterface &src) = delete;
   SETagDatabaseInterface(SETagDatabaseInterface &&src) = delete;

   /**
    * Destructor
    */
   virtual ~SETagDatabaseInterface();

   /**
    * No assignment operators for abstract class
    */
   SETagDatabaseInterface & operator = (const SETagDatabaseInterface &src) = delete; 
   SETagDatabaseInterface & operator = (SETagDatabaseInterface &&src) = delete; 


   /**
    * Search the set of symbols for a tag with the given name. 
    *  
    * @param matches          Insert matching symbols into this set
    * @param tagName          Symbol name to search for
    * @param compareMode      Search for exact tag name match (rather than prefix match) 
    * @param caseSensitive    Search for case-sensitive tag name match 
    * @param maxMatches       Stop if match set contains this many symbols 
    * @param checkTimeout     Stop if the search runs out of time 
    * @param timeoutAfterMS   If non-zero, stop if this function is busy for 
    *                         more than this amount of time in milliseconds. 
    * 
    * @return 
    * Returns 0 if no symbols are found.  Returns the number of symbols 
    * found if it finds matches.  Returns errror &lt; 0 on error.
    */
   virtual int findTagWithName(SETagList &                   matchSet,
                               const SEString &              tagName,
                               const SETagCompareNameMode    compareMode = SE_TAG_COMPARE_EXACT,
                               const bool                    caseSensitive = SESTRING_CASE_SENSITIVE,
                               const SETagContextFlags       contextFlags = SE_TAG_CONTEXT_ANYTHING,
                               const SETagFilterFlags        filterFlags  = SE_TAG_FILTER_ANYTHING,
                               const size_t                  localScopeSeekpos = 0,
                               const size_t                  maxMatches = SESIZE_MAX,
                               const bool                    checkTimeout = false,
                               const size_t                  timeoutAfterMS = 0) const = 0;

   /**
    * Search the set of symbols for a tag in the given class. 
    * 
    * @param matches          Insert matching symbols into this set
    * @param tagName          Symbol name to search for
    * @param className        Symbol class name to search for
    * @param compareMode      Search for exact tag name match (rather than prefix match) 
    * @param caseSensitive    Search for case-sensitive tag name match 
    * @param maxMatches       Stop if match set contains this many symbols 
    * @param checkTimeout     Stop if the search runs out of time 
    * @param timeoutAfterMS   If non-zero, stop if this function is busy for 
    *                         more than this amount of time in milliseconds. 
    * 
    * @return 
    * Returns 0 if no symbols are found.  Returns the number of symbols 
    * found if it finds matches.  Returns errror &lt; 0 on error.
    */
   virtual int findTagInClass(SETagList &                   matchSet,
                              const SEString &              tagName, 
                              const SEString &              className, 
                              const SETagCompareNameMode    compareMode = SE_TAG_COMPARE_EXACT,
                              const bool                    caseSensitive = SESTRING_CASE_SENSITIVE,
                              const size_t                  maxMatches = SESIZE_MAX,
                              const bool                    checkTimeout = false,
                              const size_t                  timeoutAfterMS = 0) const = 0;

   /**
    * Search the set of symbols for a tag in the given file.
    * 
    * @param matches          Insert matching symbols into this set
    * @param fileName         File to search for symbols in
    * @param tagName          Symbol name to search for (ignored if null string)
    * @param className        Symbol class name to search for (ignored if null string)
    * @param compareMode      Search for exact tag name match (rather than prefix match) 
    * @param caseSensitive    Search for case-sensitive tag name match 
    * @param maxMatches       Stop if match set contains this many symbols 
    * @param checkTimeout     Stop if the search runs out of time 
    * @param timeoutAfterMS   If non-zero, stop if this function is busy for 
    *                         more than this amount of time in milliseconds. 
    * 
    * @return 
    * Returns 0 if no symbols are found.  Returns the number of symbols 
    * found if it finds matches.  Returns errror &lt; 0 on error.
    */
   virtual int findTagInFile(SETagList &                   matchSet,
                             const SEString &              fileName = (const char *)0, 
                             const SEString &              tagName = (const char *) 0, 
                             const SEString &              className = (const char *)0, 
                             const SETagCompareNameMode    compareMode = SE_TAG_COMPARE_EXACT,
                             const bool                    caseSensitive = SESTRING_CASE_SENSITIVE,
                             const size_t                  maxMatches = SESIZE_MAX,
                             const bool                    checkTimeout = false,
                             const size_t                  timeoutAfterMS = 0) const = 0;

   /**
    * Search the set of symbols for a tag with the given tag type.
    * 
    * @param matches          Insert matching symbols into this set
    * @param tagTypeId        Tag type to search for
    * @param tagName          Symbol name to search for (ignored if null string)
    * @param className        Symbol class name to search in (ignored if null string)
    * @param compareMode      Search for exact tag name match (rather than prefix match) 
    * @param caseSensitive    Search for case-sensitive class name match 
    * @param maxMatches       Stop if match set contains this many symbols 
    * @param checkTimeout     Stop if the search runs out of time 
    * @param timeoutAfterMS   If non-zero, stop if this function is busy for 
    *                         more than this amount of time in milliseconds. 
    * 
    * @return 
    * Returns 0 if no symbols are found.  Returns the number of symbols 
    * found if it finds matches.  Returns errror &lt; 0 on error.
    */
   virtual int findTagWithTagType(SETagList &                   matchSet,
                                  const SETagType               tagTypeId,
                                  const SEString &              tagName = (const char *) 0, 
                                  const SEString &              className = (const char *)0,
                                  const SETagCompareNameMode    compareMode = SE_TAG_COMPARE_EXACT,
                                  const bool                    caseSensitive = SESTRING_CASE_SENSITIVE,
                                  const size_t                  maxMatches = SESIZE_MAX,
                                  const bool                    checkTimeout = false,
                                  const size_t                  timeoutAfterMS = 0) const = 0;

   /**
    * Search the set of symbols for a tag matching the given tag name, class name, 
    * and other properties. 
    *  
    * @param matches                Insert matching symbols into this set
    * @param tagPrefix              Tag name prefix to search for matches to
    * @param className              Class name to search for matches in 
    * @param compareMode            Search for exact tag name match (rather than prefix match) 
    * @param caseSensitive          Search for case-sensitive tag name match 
    * @param passThroughAnonymous   Pass through all anonymous (unnamed) symbols 
    * @param passThroughTransparent Pass through all transparent / opaque symbols, 
    *                               such as enumerated types which do not have to be qualified
    * @param skipIgnored            Skip symbols with VS_TAGFLAG_ignore tag flag set
    * @param maxMatches             Stop if match set contains this many symbols 
    * @param checkTimeout           Stop if the search runs out of time 
    * @param timeoutAfterMS         If non-zero, stop if this function is busy for 
    *                               more than this amount of time in milliseconds. 
    * 
    * @return 
    * Returns 0 if no symbols are found.  Returns the number of symbols 
    * found if it finds matches.  Returns errror &lt; 0 on error.
    */
   virtual int findTag(SETagList &                   matchSet,
                       const SEString &              tagPrefix, 
                       const SEString &              className = (const char*)0,
                       const SETagCompareNameMode    compareMode = SE_TAG_COMPARE_EXACT,
                       const bool                    caseSensitive = SESTRING_CASE_SENSITIVE,
                       const bool                    passThroughAnonymous=false,
                       const bool                    passThroughTransparent=false,
                       const bool                    skipIgnored=false,
                       const size_t                  maxMatches = SESIZE_MAX,
                       const bool                    checkTimeout = false,
                       const size_t                  timeoutAfterMS = 0) const = 0;

   /**
    * Search the set of symbols for a tag that matches the given tag exactly. 
    * 
    * @param matches             Insert matching symbols into this set
    * @param tagInfo             Symbol to search for a match to
    * @param lineNumberMustMatch Check if line number matches exactly
    * @param maxMatches          Stop if match set contains this many symbols 
    * @param checkTimeout        Stop if the search runs out of time 
    * @param timeoutAfterMS      If non-zero, stop if this function is busy for 
    *                            more than this amount of time in milliseconds. 
    * 
    * @return 
    * Returns 0 if no symbols are found.  Returns the number of symbols 
    * found if it finds matches.  Returns errror &lt; 0 on error.
    */
   virtual int findMatchingTag(SETagList              & matchSet,
                               const SETagInformation & tagInfo, 
                               const bool               lineNumberMustMatch=true,
                               const size_t             maxMatches = SESIZE_MAX,
                               const bool               checkTimeout = false,
                               const size_t             timeoutAfterMS = 0) const = 0;

   /**
    * Search for files matching the given file name specification.
    * 
    * @param foundFiles       Insert matching file names into this list
    * @param fileName         File name to search for (ignored if null string)
    * @param compareMode      Search for exact file name match (rather than prefix match) 
    * @param fileNameOnly     Search for file name only (ignoring path part)
    * @param maxMatches       Stop if 'foundFiles' set contains this many files
    * @param checkTimeout     Stop if the search runs out of time 
    * @param timeoutAfterMS   If non-zero, stop if this function is busy for 
    *                         more than this amount of time in milliseconds. 
    * 
    * @return 
    * Returns 0 if no files are found.  Returns the number of files
    * found if it finds matches.  Returns errror &lt; 0 on error.
    */
   virtual int findFileNames(SEArray<SEString> &           foundFiles,
                             const SEString &              fileName,
                             const SEStringCompareFileMode compareMode = SESTRING_COMPARE_FILE_EXACT,
                             const size_t                  maxMatches = SESIZE_MAX,
                             const bool                    checkTimeout = false,
                             const size_t                  timeoutAfterMS = 0) const = 0;

   /**
    * Search for class names matching the given class name specification.
    * 
    * @param foundClasses     Insert matching class names into this list
    * @param fileName         Class name to search for (ignored if null string)
    * @param compareMode      Search for exact class name match (rather than prefix match) 
    * @param caseSensitive    Search for case-sensitive class name match 
    * @param fileNameOnly     Search for class name only (ignoring class/namespace part)
    * @param maxMatches       Stop if 'foundClasses' set contains this many classes
    * @param checkTimeout     Stop if the search runs out of time 
    * @param timeoutAfterMS   If non-zero, stop if this function is busy for 
    *                         more than this amount of time in milliseconds. 
    * 
    * @return 
    * Returns 0 if no class names are found.  Returns the number of classes
    * found if it finds matches.  Returns errror &lt; 0 on error.
    */
   virtual int findClassNames(SEArray<SEString> &           foundClasses,
                              const SEString &              className,
                              const SETagCompareClassMode   compareMode = SE_TAG_COMPARE_CLASS_EXACT,
                              const bool                    caseSensitive = SESTRING_CASE_SENSITIVE,
                              const size_t                  maxMatches = SESIZE_MAX,
                              const bool                    checkTimeout = false,
                              const size_t                  timeoutAfterMS = 0) const = 0;


   /** 
    * @return 
    * Compare the given tag name against the given pattern (or simply tag name 
    * or tag name prefix), and return 'true' if it is a match.
    * 
    * @param pattern       Search pattern (tag name, prefix, regex, ...) 
    * @param tagName       Tag name (from database) 
    * @param compareMode   Search for exact tag name match (rather than prefix match) 
    * @param caseSensitive Search for case-sensitive tag name match 
    */
    static bool isTagNameMatch(const SEString &              pattern, 
                               const SEString &              tagName, 
                               const SETagCompareNameMode    compareMode,
                               const bool                    caseSensitive);

    /** 
     * @return 
     * Compare the given class name against the given pattern (or simply class name 
     * or class name prefix), and return 'true' if it is a match.
     * 
     * @param pattern       Search pattern (class name or prefix) 
     * @param tagName       Tag name (from database) 
     * @param compareMode   Search for exact class name match (rather than prefix match) 
     * @param caseSensitive Search for case-sensitive class name match 
     */
    static bool isClassNameMatch(const SEString &              pattern, 
                                 const SEString &              className, 
                                 const SETagCompareClassMode   compareMode,
                                 const bool                    caseSensitive);

   /** 
    * @return 
    * Return 'true' if the tag filters match for the given symbol.
    * 
    * @param tagInfo             Symbol information to test
    * @param contextFlags        Context tagging search options.
    * @param filterFlags         Tag filtering options.
    * @param localScopeSeekpos   Local variable scope seek position.
    */
    static bool isTagFilterMatch(const SETagInformation & tagInfo,
                                 const SETagContextFlags  contextFlags = SE_TAG_CONTEXT_ANYTHING,
                                 const SETagFilterFlags   filterFlags  = SE_TAG_FILTER_ANYTHING);

protected:

   /**
    * @return 
    * Return the tick count when search started.
    */
   static const unsigned now();

   /**
    * Generic function for checking the stop coditions when looping and searching 
    * for results. 
    * 
    * @param numMatches       number of matches found so far
    * @param maxMatches       maximum number of matches
    * @param checkTimeout     check timeout (see {@link vsCheckTimeout()})
    * @param startTime        indicates tick count when search started
    * @param timeoutAfterMS   number of milliseconds to stop after
    * 
    * @return 
    * Returns 'true' if it is time to stop. 
    */
   static bool checkStopCondition(const size_t   numMatches,
                                  const size_t   maxMatches,
                                  const bool     checkTimeout,
                                  const unsigned startTime,
                                  const size_t   timeoutAfterMS);

private:


};


} // namespace slickedit
