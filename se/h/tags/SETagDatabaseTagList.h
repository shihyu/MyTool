////////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "tags/SETagDatabaseInterface.h"
#include "tags/SETagList.h"
#include "tags/SEListTagsTarget.h"
#include "slickedit/SESharedPointer.h"

namespace slickedit {

/**
 * This class represents a programatic interface for querying information 
 * from the a set of symbols in an instance of SETagList.
 *  
 * @since 24.0 
 *  
 * @see SETagList
 * @see SEListTagsTarget 
 * @see SETagInformation 
 * @see SETagDatabaseInterface 
 * @see SETagDatabaseTagList 
 * @see SETagDatabaseLocals 
 * @see SETagDatabaseContext 
 * @see SETagDatabaseOnDisk 
 */
class VSDLLEXPORT SETagDatabaseTagList : public SETagDatabaseInterface {
public:
   /**
    * Default constructor.
    */
   SETagDatabaseTagList();

   /**
    * Construct and initialize with a given set of symbols.
    */
   SETagDatabaseTagList(const SETagList &target);

   /**
    * Construct and initialize with a given set of symbols.
    */
   SETagDatabaseTagList(const SEListTagsTarget &target);

   /**
    * Copy constructor
    * 
    * @param src item to copy
    */
   SETagDatabaseTagList(const SETagDatabaseTagList &src);
   /**
    * Copy constructor
    * 
    * @param src item to copy
    */
   SETagDatabaseTagList(SETagDatabaseTagList &&src);

   /**
    * Destructor
    */
   virtual ~SETagDatabaseTagList();

   /**
    * Assignment operator
    * 
    * @param src item to copy
    * 
    * @return reference to SETagDatabaseTagList 
    */
   SETagDatabaseTagList & operator = (const SETagDatabaseTagList &src); 
   /**
    * Move assignment operator
    * 
    * @param src item to copy
    * 
    * @return reference to SETagDatabaseTagList 
    */
   SETagDatabaseTagList & operator = (SETagDatabaseTagList &&src); 

   /**
    * Assignment operator
    * 
    * @param src  set of symbols to operator on
    * 
    * @return reference to SETagDatabaseTagList 
    */
   SETagDatabaseTagList & operator = (const SETagList &src); 

   /**
    * Assignment operator
    * 
    * @param src  set of symbols to operator on
    * 
    * @return reference to SETagDatabaseTagList 
    */
   SETagDatabaseTagList & operator = (const SEListTagsTarget &src); 

   /**
    * @return 
    * Return a reference to the current set of tags being operated on.
    */
   const SETagList & getTagList() const;

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
                               const size_t                  timeoutAfterMS = 0) const override;

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
                              const size_t                  timeoutAfterMS = 0) const override;

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
                             const size_t                  timeoutAfterMS = 0) const override;

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
                                  const size_t                  timeoutAfterMS = 0) const override;

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
                       const size_t                  timeoutAfterMS = 0) const override;

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
                               const size_t             timeoutAfterMS = 0) const override;

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
                             const size_t                  timeoutAfterMS = 0) const override;

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
                              const size_t                  timeoutAfterMS = 0) const override;

private:

   SETagList mTagList;

};

/**
 * This class represents a programatic interface for querying information 
 * from the a set of local variables.
 *  
 * @since 24.0 
 *  
 * @see SEListTagsTarget 
 * @see SETagInformation 
 * @see SETagDatabaseInterface 
 * @see SETagDatabaseLocals 
 * @see SETagDatabaseContext 
 * @see SETagDatabaseOnDisk
 */
class VSDLLEXPORT SETagDatabaseLocals : public SETagDatabaseTagList {
public:
   /**
    * Default constructor.  Will get the current set of locals on demand.
    */
   SETagDatabaseLocals();

   /**
    * Construct and initialize with a set of local variables.
    */
   SETagDatabaseLocals(const SEListTagsTarget &locals);

   /**
    * Copy constructor
    * 
    * @param src item to copy
    */
   SETagDatabaseLocals(const SETagDatabaseLocals &src);

   /**
    * Destructor
    */
   virtual ~SETagDatabaseLocals();

   /**
    * Assignment operator
    * 
    * @param src item to copy
    * 
    * @return reference to SETagDatabaseLocals 
    */
   SETagDatabaseLocals & operator = (const SETagDatabaseLocals &src); 

   /**
    * Assignment operator
    * 
    * @param locals  set of symbols to operator on
    * 
    * @return reference to SETagDatabaseTagList 
    */
   SETagDatabaseLocals & operator = (const SEListTagsTarget &locals);


private:


};


/**
 * This class represents a programatic interface for querying information 
 * from the a set of symbols defined in the current file (context).
 *  
 * @since 24.0 
 *  
 * @see SEListTagsTarget 
 * @see SETagInformation 
 * @see SETagDatabaseInterface 
 * @see SETagDatabaseLocals 
 * @see SETagDatabaseContext 
 * @see SETagDatabaseOnDisk 
 */
class VSDLLEXPORT SETagDatabaseContext : public SETagDatabaseTagList {
public:
   /**
    * Default constructor.  Will get the current set of context on demand.
    */
   SETagDatabaseContext();

   /**
    * Construct and initialize with a set of local variables.
    */
   SETagDatabaseContext(const SEListTagsTarget &context);

   /**
    * Copy constructor
    * 
    * @param src item to copy
    */
   SETagDatabaseContext(const SETagDatabaseContext &src);

   /**
    * Destructor
    */
   virtual ~SETagDatabaseContext();

   /**
    * Assignment operator
    * 
    * @param src item to copy
    * 
    * @return reference to SETagDatabaseContext 
    */
   SETagDatabaseContext & operator = (const SETagDatabaseContext &src); 

   /**
    * Assignment operator
    * 
    * @param context  set of symbols to operator on
    * 
    * @return reference to SETagDatabaseTagList 
    */
   SETagDatabaseContext & operator = (const SEListTagsTarget &context);


private:


};


} // namespace slickedit
