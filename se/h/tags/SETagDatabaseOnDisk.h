////////////////////////////////////////////////////////////////////////////////////
// Copyright 2017 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "tags/SETagDatabaseInterface.h"
#include "slickedit/SEString.h"

namespace slickedit {

/**
 * This class represents a programatic interface for querying information 
 * from the a tag databsae on disk.
 *  
 * @since 24.0 
 *  
 * @see SEListTagsTarget 
 * @see SETagInformation 
 * @see SETagDatabaseInterface 
 * @see SETagDatabaseTagList 
 * @see SETagDatabaseLocals 
 * @see SETagDatabaseContext 
 * @see SETagDatabaseOnDisk
 */
class VSDLLEXPORT SETagDatabaseOnDisk : public SETagDatabaseInterface {
public:
   /**
    * Default constructor.
    */
   SETagDatabaseOnDisk();

   /**
    * Construct and initialize with a given tag database file on disk.
    */
   SETagDatabaseOnDisk(const SEString &tagDatabase);

   /**
    * Construct and initialize with a given tag database handle.
    */
   SETagDatabaseOnDisk(const int dbHandle);

   /**
    * Copy constructor
    * 
    * @param src item to copy
    */
   SETagDatabaseOnDisk(const SETagDatabaseOnDisk &src);
   /**
    * Move constructor
    * 
    * @param src item to copy
    */
   SETagDatabaseOnDisk(SETagDatabaseOnDisk &&src);

   /**
    * Destructor
    */
   virtual ~SETagDatabaseOnDisk();

   /**
    * Assignment operator
    * 
    * @param src item to copy
    * 
    * @return reference to SETagDatabaseOnDisk 
    */
   SETagDatabaseOnDisk & operator = (const SETagDatabaseOnDisk &src); 
   /**
    * Move assignment operator
    * 
    * @param src item to copy
    * 
    * @return reference to SETagDatabaseOnDisk 
    */
   SETagDatabaseOnDisk & operator = (SETagDatabaseOnDisk &&src); 

   /**
    * Assignment operator
    * 
    * @param src  set of symbols to operator on
    * 
    * @return reference to SETagDatabaseOnDisk 
    */
   SETagDatabaseOnDisk & operator = (const SEString &tagDatabase);

   /**
    * @return 
    * Return a reference to the current set of tags being operated on.
    */
   const int getDatabaseHandle() const;


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

   slickedit::SESharedPointer<struct SETagDatabaseOnDiskPrivate> mpDatabase;

};


} // namespace slickedit
