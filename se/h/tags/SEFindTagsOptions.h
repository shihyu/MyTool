////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:          SEFindTagsOptions.h
// Description:   Declaration of class for representing the options used
//                by a symbol search (find-tags) operation.
////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"
#include "slickedit/SESharedPointer.h"
#include "slickedit/SEString.h"
#include "slickedit/SEArray.h"
#include "tags/SEListTagsTarget.h"
#include "tags/SETokenList.h"
#include "tags/SETagFilterFlags.h"

namespace slickedit {

// forward declarations
class VSDLLEXPORT SETokenList;

/**
 * This method encapsulates the options needed to perform a context tagging 
 * symbol search (find tags callback).
 */
struct VSDLLEXPORT SEFindTagsOptions {

   /**
    * Default constructor.
    */
   SEFindTagsOptions();
   /**
    * Copy constructor
    */
   SEFindTagsOptions(const SEFindTagsOptions& src);
   /**
    * Move constructor
    */
   SEFindTagsOptions(SEFindTagsOptions&& src);
   /** 
    * Destructor
    */
   ~SEFindTagsOptions();
   /**
    * Assignment operator
    */
   SEFindTagsOptions & operator = (const SEFindTagsOptions& src);
   /**
    * Move assignment operator
    */
   SEFindTagsOptions & operator = (SEFindTagsOptions&& src);

   /**
    * Equality comparison operator
    */
   bool operator == (const SEFindTagsOptions& src) const;
   /**
    * Inequality comparison operator
    */
   bool operator != (const SEFindTagsOptions& src) const;

   /**
    * Reset everything to inital state.
    */
   void clear();
   /**
    * @return Return 'true' if this object is in a null state.
    */
   const bool isNull() const;
   /**
    * @return Return 'true' if this object is in it's initial state.
    */
   const bool isEmpty() const;

   /**
    * @return Return the set of global symbols in the current file.
    */
   const SEListTagsTarget &getCurrentContext() const;
   /**
    * Store the set of symbols in the current file.
    * 
    * @param context    current context object
    */
   void setCurrentContext(const SEListTagsTarget &context);

   /**
    * @return Return the set of local variables in the current function.
    */
   const SEListTagsTarget &getCurrentLocals() const;
   /**
    * Store the set of local variables in the current function.
    * 
    * @param locals     current locals object
    */
   void setCurrentLocals(const SEListTagsTarget &locals);

   /**
    * @return Return the token list for the current file.
    */
   const SETokenList &getTokenList() const;
   /**
    * Store the token list for the currrent file.
    * 
    * @param tokenList     token list object
    */
   void setTokenList(SETokenList &tokenList);

   /**
    * @return Return the number of tag files in this tag file set.
    */
   const size_t getNumTagFiles() const;
   /**
    * @return Return the entire list of tag files in this set.
    */
   const SEArray<SEString> getTagFiles() const;
   /**
    * @return Return the i'th tag file in this tag file set.
    * 
    * @param i   index (0 .. {@link getNumTagFiles()} - 1)
    */
   const SEString getTagFileName(const size_t i) const;
   /**
    * Store the array of tag files for this search.
    * 
    * @param tag_files      array of tag file names
    */
   void setTagFiles(const SEArray<SEString> &tag_files);
   /**
    * Clear the array of tag files for this search.
    */
   void clearTagFiles();
   /**
    * Set the tag file name at the given index.
    * 
    * @param i              tag file index (will auto-extend)
    * @param tagFileName    tag file name and path
    */
   void setTagFileName(const size_t i, const SEString &tagFileName);
   /**
    * Add a tag file name to the end of the list of tag files.
    * 
    * @param tagFileName    tag file name and path
    */
   void addTagFileName(const SEString &tagFileName);
   /**
    * Remove a tag file from the tag file list.
    * 
    * @param tagFileName     tag file name and path
    */
   void removeTagFileName(const SEString &tagFileName);

   /**
    * @return Return the language mode to search.
    */
   const SEString getLanguageID() const;
   /**
    * Store the language mode to search.
    * 
    * @param langId      language ID
    */
   void setLanguageID(const SEString &langId);

   /**
    * @return Find all instances of this symbol in class parents?
    */
   const bool doFindParents() const;
   /**
    * @return Do exact symbol match (match whole word, not just prefix)?
    */
   const bool doSymbolExactMatch() const;
   /**
    * @return Do prefix symbol match (just match characters before cursor)?
    */
   const bool doSymbolPrefixMatch() const;
   /**
    * @return Do a case-sensitive symbol search (exclude case-insensitive matches)?
    */
   const bool doCaseSensitiveMatch() const;

   /**
    * Configure search to find all instances of this symbol in class parents.
    *  
    * @param on_off    'true' or 'false'
    */
   void setDoFindParents(const bool on_off);
   /**
    * Configure search to do an exact symbol match (must match whole identifier).
    * 
    * @param on_off    'true' or 'false'
    */
   void setDoExactmatch(const bool on_off);
   /**
    * Configure search to do a case-sensitive symbol name match.
    * 
    * @param on_off    'true' or 'false'
    */
   void setDoCaseSensitiveMatch(const bool on_off);

   /**
    * @return Return the set of tag filter flags configured for this search.
    */
   const SETagFilterFlags getTagFilterFlags() const;
   /**
    * Set the tag filter flags for this search.
    * 
    * @param filterFlags     tag type filter flags
    */
   void setTagFilterFlags(const SETagFilterFlags filterFlags);
   /**
    * Add the given flag to the set of filter flags set
    * 
    * @param filterFlags     tag type filter flags
    */
   void addTagFilterFlags(const SETagFilterFlags filterFlags);
   /**
    * Clear the given flags from the set of filter flags set
    * 
    * @param filterFlags     tag type filter flags
    */
   void clearTagFilterFlags(const SETagFilterFlags filterFlags);
   /**
    * Add the given flag to the set of filter flags set
    * 
    * @param filterFlags     tag type filter flags
    */
   const bool haveAllTagFilterFlags(const SETagFilterFlags filterFlags) const;
   /**
    * Clear the given flags from the set of filter flags set
    * 
    * @param filterFlags     tag type filter flags
    */
   const bool haveAnyTagFilterFlags(const SETagFilterFlags filterFlags) const;

   /**
    * @return Return the tag context filtering flags for this search.
    */
   const SETagContextFlags getTagContextFlags() const;
   /**
    * Set the tag context filter flags for this search.
    * 
    * @param contextFlags     tag context filter flags
    */
   void setTagContextFlags(const SETagContextFlags contextFlags);
   /**
    * Add the given flag to the set of context flags set
    * 
    * @param contextFlags     tag context filter flags
    */
   void addTagContextFlags(const SETagContextFlags contextFlags);
   /**
    * Clear the given flags from the set of context flags set
    * 
    * @param contextFlags     tag context filter flags
    */
   void clearTagContextFlags(const SETagContextFlags contextFlags);
   /**
    * Add the given flag to the set of context flags set
    * 
    * @param contextFlags     tag context filter flags
    */
   const bool haveAllTagContextFlags(const SETagContextFlags contextFlags) const;
   /**
    * Clear the given flags from the set of context flags set
    * 
    * @param contextFlags     tag context filter flags
    */
   const bool haveAnyTagContextFlags(const SETagContextFlags contextFlags) const;

   /**
    * @return Return the maximum number of symbol matches to find.
    */
   const size_t getMaxMatches() const;
   /**
    * Set the maximum number of symbol matches to find.
    * 
    * @param max_symbols     stop searching when we hit this many symbols.
    */
   void setMaxMatches(const size_t max_symbols);

   /**
    * Compute a hash value for this class instance.
    */
   const unsigned int hash() const;

private:

   SESharedPointer<struct SEPrivateFindTagsOptions> mpFindTagsOptions;
};

}

extern unsigned cmHashKey(const slickedit::SEFindTagsOptions &opts);

