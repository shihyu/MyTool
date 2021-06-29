////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:          SETaggingResultsCache.h
// Description:   Declaration of class for collecting results from prior
//                calls to _[lang]_find_context_tags.
////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"
#include "tags/SETagInformation.h"
#include "tags/SETagFlags.h"
#include "tags/SETagTypes.h"
#include "tagsdb.h"
#include "slickedit/SESharedPointer.h"
#include "slickedit/SEString.h"


namespace slickedit {

// forward declarations
struct SEFindTagsOptions;
struct SEReturnTypeInfo;
struct SEIDExpressionInfo;

/**
 * This class is used to represent a cache for prior results when doing 
 * context tagging operations, such as language-specific context tagging, 
 * evaluating the return type of a symbol, or a symbol prefix expression, 
 * or evaluating the type/value of an expression. 
 *  
 * @see SEFindTagsOptions
 * @see SEIDExpressionInfo
 * @see SEReturnTypeInfo
 * @see SETagList
 */ 
struct VSDLLEXPORT SETaggingResultsCache
{
public:
   /**
    * Default constructor
    */
   SETaggingResultsCache();

   /**
    * Copy constructor
    */
   SETaggingResultsCache(const SETaggingResultsCache& src);
   /**
    * Move constructor
    */
   SETaggingResultsCache(SETaggingResultsCache && src);

   /**
    * Destructor
    */
   virtual ~SETaggingResultsCache();

   /**
    * Assignment operator
    */
   SETaggingResultsCache &operator = (const SETaggingResultsCache &src);
   /**
    * Move assignment operator
    */
   SETaggingResultsCache &operator = (SETaggingResultsCache &&src);

   /**
    * Is the cache completely empty?
    */
   const bool isEmpty() const;

   /**
    * Clear out all past results from the cache.
    */
   void clear();

   /**
    * Add a set of matches found from a language-specific context tagging 
    * symbol search with the given parameters.  The return type information is 
    * optional, as some context tagging operations will not require this. 
    * 
    * @param idexpInfo          information about expression under the cursor
    * @param findTagsOptions    find tags options, including the current context and tag files used
    * @param matches            list of symbol matches found
    * @param pReturnType        (optional) return type information evaluated
    */
   void addFindTagsMatches(const struct slickedit::SEIDExpressionInfo &idexpInfo,
                           const struct slickedit::SEFindTagsOptions &findTagsOptions,
                           const class  slickedit::SETagList &matches,
                           const struct slickedit::SEReturnTypeInfo *pReturnType = nullptr);
   /**
    * Add a set of matches found from a language-specific context tagging 
    * symbol search which we generated the given key for. 
    * The return type information is optional, as some context tagging operations 
    * will not require this. 
    * 
    * @param hashKey            unique key generated for some context tagging operation
    * @param matches            list of symbol matches found
    * @param pReturnType        (optional) return type information evaluated
    */
   void addFindTagsMatches(const slickedit::SEString &hashKey,
                           const class  slickedit::SETagList &matches,
                           const struct slickedit::SEReturnTypeInfo *pReturnType = nullptr);


   /**
    * Add the return type information found for the given language-specific 
    * context tagging operation. 
    * 
    * @param idexpInfo          information about expression under the cursor
    * @param findTagsOptions    find tags options, including the current context and tag files used
    * @param returnType         return type information evaluated
    */
   void addReturnTypeInfo(const struct slickedit::SEIDExpressionInfo &idexpInfo,
                          const struct slickedit::SEFindTagsOptions &findTagsOptions,
                          const struct slickedit::SEReturnTypeInfo &returnType);

   /**
    * Add the return type information found from a language-specific context 
    * tagging operation which we generated the given key for.
    * 
    * @param hashKey            unique key generated for some context tagging operation
    * @param returnType         return type information evaluated
    */
   void addReturnTypeInfo(const slickedit::SEString &hashKey,
                          const struct slickedit::SEReturnTypeInfo &returnType);

   /**
    * Add a record indicating that the given language-specific context tagging 
    * symbol search failed.  Stores the error arguments and the return status. 
    * 
    * @param idexpInfo          information about expression under the cursor
    * @param findTagsOptions    find tags options, including the current context and tag files used
    * @param errorArgs          error parameters
    * @param returnStatus       VSRC_* error code
    */
   void addFailureInfo(const struct slickedit::SEIDExpressionInfo &idexpInfo,
                       const struct slickedit::SEFindTagsOptions &findTagsOptions,
                       const slickedit::SEArray<slickedit::SEString> &errorArgs,
                       const int returnStatus);

   /**
    * Add a record indicating that the given language-specific contex tagging 
    * operation which we generated the given key for failed.
    * 
    * @param hashKey            unique key generated for some context tagging operation
    * @param errorArgs          error parameters
    * @param returnStatus       VSRC_* error code
    */
   void addFailureInfo(const slickedit::SEString &hashKey,
                       const slickedit::SEArray<slickedit::SEString> &errorArgs,
                       const int returnStatus);

   /** 
    * @return 
    * Returns the list of symbols found by the cached language-specific context 
    * tagging operation with the given key.  Returns 'nullptr' if there 
    * is no such result cached, or if the result cached was a failure.
    * 
    * @param idexpInfo          information about expression under the cursor
    * @param findTagsOptions    find tags options, including the current context and tag files used
    */
   const slickedit::SETagList *getFindTagsMatches(const struct slickedit::SEIDExpressionInfo &idexpInfo,
                                                  const struct slickedit::SEFindTagsOptions &findTagsOptions) const;
   /** 
    * @return 
    * Returns the list of symbols found by the cached language-specific context 
    * tagging operation with the given parameters.  Returns 'nullptr' if there 
    * is no such result cached, or if the result cached was a failure.
    * 
    * @param hashKey            unique key generated for some context tagging operation
    */
   const slickedit::SETagList *getFindTagsMatches(const slickedit::SEString &hashKey) const;

   /** 
    * @return 
    * Returns the return type information found by the cached language-specific context 
    * tagging operation with the given parameters.  Returns 'nullptr' if there 
    * is no such result cached, or if the result cached was a failure.
    * 
    * @param idexpInfo          information about expression under the cursor
    * @param findTagsOptions    find tags options, including the current context and tag files used
    */
   const slickedit::SEReturnTypeInfo *getReturnTypeInfo(const struct slickedit::SEIDExpressionInfo& idexpInfo,
                                                        const struct slickedit::SEFindTagsOptions &findTagsOptions) const;
   /** 
    * @return 
    * Returns the return type information found by the cached language-specific context 
    * tagging operation with the given key.  Returns 'nullptr' if there 
    * is no such result cached, or if the result cached was a failure.
    * 
    * @param hashKey            unique key generated for some context tagging operation
    */
   const slickedit::SEReturnTypeInfo *getReturnTypeInfo(const slickedit::SEString &hashKey) const;

   /** 
    * @return 
    * Returns the error status last found by the cached language-specific context 
    * tagging operation with the given parameters.  Returns 'nullptr' if there 
    * is no such result cached, or if the result cached was a failure. 
    *  
    * Returns 'STRING_NOT_FOUND_RC' if there is no such record. 
    * 
    * @param idexpInfo          information about expression under the cursor
    * @param findTagsOptions    find tags options, including the current context and tag files used 
    * @param errorArgs          (output) set to error parameters for failure code
    */
   int getFailureInfo(const struct slickedit::SEIDExpressionInfo &idexpInfo,
                      const struct slickedit::SEFindTagsOptions &findTagsOptions,
                      slickedit::SEArray<slickedit::SEString> &errorArgs) const;

   /** 
    * @return 
    * Returns the error status last found by the cached language-specific context 
    * tagging operation with the given parameters.  Returns 'nullptr' if there 
    * is no such result cached, or if the result cached was a failure. 
    *  
    * Returns 'STRING_NOT_FOUND_RC' if there is no such record. 
    * 
    * @param hashKey            unique key generated for some context tagging operation
    * @param errorArgs          (output) set to error parameters for failure code
    */
   int getFailureInfo(const slickedit::SEString &hashKey,
                      slickedit::SEArray<slickedit::SEString> &errorArgs) const;


private:

   // Pointer to private implementation of tagging target
   SESharedPointer<struct SEPrivateTaggingResultsCache> mpTaggingResultsCache;

   /**
    * Comparison operators
    */
   bool operator == (const SETaggingResultsCache &rhs) const;
   bool operator != (const SETaggingResultsCache &rhs) const;

};


} // namespace slickedit





