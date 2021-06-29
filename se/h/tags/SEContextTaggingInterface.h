////////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"
#include "slickedit/SESharedPointer.h"
#include "slickedit/SEArray.h"
#include "slickedit/SEString.h"

namespace slickedit {

// forward declarations
class SETokenList;
class SETagList;
struct SEFindTagsOptions;
struct SEIDExpressionInfo;
struct SEReturnTypeInfo;
struct SETaggingResultsCache;


/**
 * Typedef for old-style vs[lang]_list_tags() function registered with Slick-C
 */
typedef int (VSAPI *SEListTagsSlickCCallbackType)(int output_view_id,VSPSZ filename_p,VSPSZ extension_p);
/**
 * Typedef for old-style [lang]_list_locals() function registered with Slick-C
 */
typedef int (VSAPI *SEListLocalsSlickCCallbackType)(int output_view_id,VSPSZ filename_p,VSPSZ extension_p);
/**
 * Typedef for old-style vs[lang]_get_expression_info() function registered with Slick-C
 */
typedef int (VSAPI *SEGetExpressionInfoSlickCCallbackType)(int PossibleOperator, seSeekPosParam seekPosition, VSHREFVAR hvar_idexpInfo, VSHREFVAR hvar_errorArgs);
/**
 * Typedef for old-style vs[lang]_load_tags() function registered with Slick-C
 */
typedef int (VSAPI *SELoadTagsSlickCCallbacktype)(VSPSZ file_name, int ltf_flags);

/**
 * Typedef for the language-speciic parsing function callback.
 */
typedef int (*SETagParsingCallbackType)(class SEListTagsTarget &context);

/**
 * Typedef for the language-specific get expression info function callback.
 */
typedef int (*SETagExpressionInfoCallbackType)(struct SEIDExpressionInfo &idexpInfo,
                                               SEArray<SEString> &errorArgs,
                                               const class SETokenList &tokenList,
                                               const class SEString &langId,
                                               const bool PossibleOperator, 
                                               const seSeekPos seekPosition,
                                               const int depth /*=0*/);

/**
 * Typedef for the language-specific find tags function callback.
 */
typedef int (*SETagFindTagsCallbackType)(class  SETagList &matches,
                                         struct SEReturnTypeInfo &prefixReturnType,
                                         SEArray<SEString> &errorArgs,
                                         const class SEString &langId,
                                         const struct SEIDExpressionInfo &idexpInfo,
                                         const struct SEFindTagsOptions &findTagsOptions,
                                         struct SETaggingResultsCache &visited, 
                                         const int depth /*= 0*/);

/**
 * Struct used to register a set of language-specific callbacks in one shot.
 */
struct SEContextTaggingCallbacks {

    SELoadTagsSlickCCallbacktype          load_tags;
    SEListTagsSlickCCallbackType          list_tags;
    SEListLocalsSlickCCallbackType        list_locals;
    SEGetExpressionInfoSlickCCallbackType idexp_info;

    SETagParsingCallbackType              tagging_cb;
    SETagExpressionInfoCallbackType       expr_info_cb;
    SETagFindTagsCallbackType             find_tags_cb;

    bool have_locals;
    bool have_statements;
    bool have_token_list;
    bool have_thread_safety;
    bool have_positional_kws;
    bool have_incremental;
};

/**
 * This class represents a programatic interface implementing 
 * context tagging for a language mode.  Override the methods in this class 
 * to implement context tagging for a specific language.  There is also a set 
 * of capability options that can be set in order to indicate if a particular 
 * feature is supported by Context Tagging&reg; for this language. 
 *  
 * In addition to representing the language-specific context tagging interface, 
 * this class is also used as a registry for thread-safe language-specific 
 * context tagging functions.
 *  
 * There are three primary language-specific interfaces realized by this interface. 
 * <ul> 
 *    <li><b>Source code parsing</b> -- Implements thread-safe parsing for a
 *        whole file, a partial file, local variables, or statement tagging.
 *        The core of this is inserting tags ({@link SETagInformation}) into
 *        an instance of {@link SEListTagsTarget}, which contains all the
 *        information necessary to set up the parsing job and indicate where
 *        the results are to be sent.
 *    </li>
 *    <li><b>Expression analysis</b> - Gathers information about the current
 *        symbol at a particular position in the source file, as well as
 *        and prefix expression leading up to the symbol.
 *    </li>
 *    <li><b>Find tags in context</b> - Based on the information gathered by
 *        the expression analysis step, and the set of symbols found in the
 *        tag databases, including locals, current context, and external tag
 *        files, this callback finds a list of symbols which match the
 *        constraints of the context tagging search.  These are the symbols
 *        that are shown in auto-list members, or the symbols used when you
 *        attempt to jump from a symbol to it's definition or declaration.
 *    </li>
 * </ul> 
 * 
 * The following capabilities may or may not be implemented for the 
 * language-specific parsing and tagging. 
 * <ul> 
 *    <li><b>Local variable tagging</b> -- Searches a function for local
 *        variables.  Finds all local variables in all scopes, and tracks the
 *        scopes as well as their opaqueness.  This function also finds labels.
 *        This function can also be used to find parameters to macros, template
 *        functions, and function prototypes.
 *    </li> 
 *    <li><b>Statement tagging</b> -- Scans the entire file down to the statement
 *        level and tags all statements, as well as symbols that would normally
 *        be tagged.
 *    </li> 
 *    <li><b>Tokenization</b> -- In the course of parsing, records
 *        all the tokens that are parsed, and their locations.  This information
 *        is used both by incremental tagging and can also be used by expression
 *        analysis, as well as symbol references and call-tree generation.
 *    </li>
 *    <li><b>Positional Keywords</b> -- If a language has positional keywords,
 *        that is, keywords which can be used as identifiers under normal
 *        circumstances, but are keywords in specific contexts, and the parser
 *        flags identifier tokens which are positional keywords as such.
 *    </li>
 *    <li><b>Incremental Parsing</b> -- If enabled, the parser will rescan
 *        only a sub-section of the code in order to just retag the part
 *        which was modified since the last scan.
 *    </li>
 * </ul> 
 *  
 * This class allows you to provide context tagging hook functions in one 
 * of two ways, overriding virtual methods and registering an instance of 
 * the derived class, or simply registering a function as a callback. 
 *  
 * If you derive from this interface and override any of the virtual 
 * context tagging functions, it is important to register them as overridden 
 * by calling the 'setImplements..." methods to indicate that the callbacks 
 * are available to be called directly. 
 *  
 * To employ the context tagging hook functions, the best technique is to 
 * call {@link getRegisteredInstance()} for the language mode you are trying 
 * to work in, and then call the corresponding virtual method. 
 * 
 * While there are many methods for querying the availability of an interface, 
 * and for obtaining the callback methods, these exist primarily for bookkeeping 
 * and not for general use. 
 *  
 * @since 24.0 
 *  
 * @see SETagList
 * @see SEListTagsTarget 
 * @see SETagInformation 
 */
class VSDLLEXPORT SEContextTaggingInterface {
public:

   /**
    * Default constructor
    */
   SEContextTaggingInterface();

   /**
    * Construct for a given language ID.
    * 
    * @param langId     language ID that these callbacks are for
    */
   SEContextTaggingInterface(const SEString& langId, const SEContextTaggingCallbacks *pSpec=nullptr);

   /**
    * Copy constructor.
    */
   SEContextTaggingInterface(const SEContextTaggingInterface &src);
   /**
    * Move constructor.
    */
   SEContextTaggingInterface(SEContextTaggingInterface &&src);

   /**
    * Destructor
    */
   virtual ~SEContextTaggingInterface();

   /**
    * Assignment operator
    */
   SEContextTaggingInterface & operator = (const SEContextTaggingInterface &src); 
   /**
    * Move assignment operator
    */
   SEContextTaggingInterface & operator = (SEContextTaggingInterface &&src); 

   /**
    * Equality comparison operators
    */
   bool operator == (const SEContextTaggingInterface &src) const; 
   bool operator != (const SEContextTaggingInterface &src) const; 

   /**
    * Ordering comparison operators
    */
   bool operator < (const SEContextTaggingInterface &src) const; 
   bool operator > (const SEContextTaggingInterface &src) const; 
   bool operator <= (const SEContextTaggingInterface &src) const; 
   bool operator >= (const SEContextTaggingInterface &src) const; 


   /**
    * Is this instance null?
    */
   const bool isNull() const;
   /**
    * Is this instance empty?
    */
   const bool isEmpty() const;
   /**
    * Clear all data from this instance, back to default (null) state.
    */
   void clear();

   /** 
    * @return Compute a hash code for this instance. 
    *         Hashes solely on the language ID as a key. 
    */
   const unsigned int hash() const;

   /////////////////////////////////////////////////////////////////////////////
   // VIRTUAL FUNCTIONS (CONTEXT TAGGING INTERFACE)
   /////////////////////////////////////////////////////////////////////////////

   /**
    * Override this function to implement language-specific parsing and tagging 
    * for a whole file, a partial file, local variables, or statement tagging.
    * The core of this is inserting tags ({@link SETagInformation}) for each
    * symbol (or statement) declared or defined in the source code into
    * an instance of {@link SEListTagsTarget}, which contains all the
    * information necessary to set up the parsing job and indicate where
    * the results are to be sent.
    * 
    * By default, this function calls the parsing callback, if set, otherwise, 
    * it returns an error indicating that the feature is not implemented. 
    *  
    * @param context    (input and output) Contains all the information 
    *                   necessary to invoke the tagging function and provides
    *                   methods for logging tokens, statements, and symbols as
    *                   they are found. 
    * 
    * @return Returns 0 on success, &lt;0 on error.
    */
   virtual int listTags(class SEListTagsTarget &context);

   /**
    * Override this function to implement language-specific Context Tagging&reg; 
    * expression analysis.  This function's responsibility is to gather
    * information about the current symbol at a particular position in the
    * source file, as well as and prefix expression leading up to the symbol.
    *  
    * For simplicity, it requires a token list, generated by the {@link listTags()}
    * method, however, if the parsing callback does not support tokenization,
    * you can fake out the token list by creating an instance with the file
    * name and file contents and manually do whatever is necessary to parse
    * out the expression information. 
    * 
    * @param idexpInfo        (output) expression information
    * @param errorArgs        (output) array of strings corresponding to the 
    *                         parameters required by the error returned --
    *                         only if the search terminates in error, of course.
    * @param tokenList        token list generated by parsing callback 
    * @param langId       current language mode
    * @param PossibleOperator was an operator just typed? 
    *                         (such as <b>.</b>, <b>(</b>, or <b>-&gt;</b>)
    * @param seekPosition     seek position (location under the cursor)
    * @param depth            depth of recursive search 
    * 
    * @return Returns 0 on success, &lt;0 on error.
    */
   virtual int getIDExpressionInfo(struct SEIDExpressionInfo &idexpInfo,
                                   SEArray<SEString> &errorArgs,
                                   const class SETokenList &tokenList,
                                   const class SEString &langId,
                                   const bool PossibleOperator, 
                                   const seSeekPos seekPosition,
                                   const int depth = 0);


   /**
    * Override this function to implmeent language-speicific Context Tagging&reg; 
    * symbol searching.  Based on the information gathered by the expression 
    * analysis step, and the set of symbols found in the tag databases, 
    * including locals, current context, and external tag files, 
    * this callback finds a list of symbols which match the
    * constraints of the context tagging search. 
    *  
    * @param matches          (output) list of symbols found 
    * @param prefixReturnType (output) return type evaluated for the current 
    *                         context or for the prefix expression found by
    *                         expression analysis. 
    * @param errorArgs        (output) array of strings corresponding to the 
    *                         parameters required by the error returned --
    *                         only if the search terminates in error, of course.
    *  
    * @param idexpInfo        expression information from {@link getIDExpressionInfo()} 
    * @param findTagsOptions  constraints for find tags operation. 
    * @param visited          (input/output) used to cache intermediate results 
    * @param depth            depth of recursive search 
    * 
    * @return Returns the number of items found &gt=0 on success, &lt;0 on error.
    */
   virtual int findTags(class  SETagList &matches,
                        struct SEReturnTypeInfo &prefixReturnType,
                        SEArray<SEString> &errorArgs,
                        const class SEString &langId,
                        const struct SEIDExpressionInfo &idexpInfo,
                        const struct SEFindTagsOptions &findTagsOptions,
                        struct SETaggingResultsCache &visited, 
                        const int depth = 0);

   /////////////////////////////////////////////////////////////////////////////
   // LANGUAGE ID FUNCTIONS
   /////////////////////////////////////////////////////////////////////////////
   
   /**
    * Set the language ID. 
    *  
    * By default, this function will also query for language parsing support 
    * information, such as list-locals, statement tagging, and token list 
    * generation.  This step can be skipped by passing 'lookupSupportInfo=false'.
    */
   void setLanguageId(const SEString &langId, const bool lookupSupportInfo=true);
   /**
    * Return the language ID.
    */
   const SEString getLanguageId() const;
   const cmStringUtf8 &getLanguageIdRef() const;


   /////////////////////////////////////////////////////////////////////////////
   // CALLBACK REGISTRATION FUNCTIONS
   /////////////////////////////////////////////////////////////////////////////
   
   /**
    * Register this instance of a tagging interface with the global registry. 
    * The pointer is stored as-is, so the instance passed in should be static
    * because the table that it is stored in is also static.
    */
   int registerThisInstance();
   /**
    * Returns a pointer to the registered class instance for the given language 
    * (or the current language mode), optionally looking for an instance 
    * registered to an inherited language mode. 
    *  
    * @param langId        language mode identifier
    * @param checkParents   If this instance does not have the callback, 
    *                       check the inherited language mode(s) 
    */
   static SEContextTaggingInterface *getRegisteredInstance(const SEString &langId, const bool checkParents=true);
   /**
    * Clears all registered context tagging interface instances.
    */
   static void clearRegisteredInstances();
   /**
    * Return the number of context tagging interfaces registered for different languages
    */
   static const size_t getNumRegisteredInstances();
   /**
    * Return an array containing all the registered context tagging interfaces.
    */
   static const SEArray<const SEContextTaggingInterface*> getAllRegisteredInstances();
   /**
    * Return an array containing all the registered languages.
    */
   static const SEArray<SEString> getAllRegisteredLanguages();
   /**
    * Return the parent language for the given language mode. 
    * This is the language mode we inherit callbacks from. 
    *  
    * @param langId        language mode identifier
    */
   static const SEString getRegisteredParentLanguage(const SEString &langId);
   /**
    * Returns a pointer to the registered class instance for the language which 
    * the current language mode inherits callbacks from.  Returns 'null' if 
    * there is no such language.
    */
   SEContextTaggingInterface *getRegisteredParentInstance() const;
   /**
    * Register a set of callbacks for a specific language. 
    * This function can only be ran on the main thread and will create 
    * entries in the Slick-C names table for the various functions registered. 
    *  
    * @param dllName   name of the DLL exporting this function 
    * @param langId    languageId
    * @param cbSpec    callback specification
    */
   static void registerCallbacks(const SEString &dllName,
                                 const SEString &langId, 
                                 const SEContextTaggingCallbacks &cbSpec);


   /////////////////////////////////////////////////////////////////////////////
   // PARSING CALLBACKS (LIST TAGS)
   /////////////////////////////////////////////////////////////////////////////
   
   /**
    * Check if we have a parsing callback for this target language or if this 
    * instance overrides the {@link listTags()} method. 
    *  
    * @param checkParents   If this instance does not have the callback, 
    *                       check the inherited language mode(s) 
    */
   bool hasParsingCallback(const bool checkParents=true) const;
   /**
    * Check if there is a parsing callback registered for the given language, 
    * or inherited by the given language. 
    * 
    * @param langId     language mode identifier
    */
   static bool hasRegisteredParsingCallback(const SEString &langId);

   /**
    * @return 
    * Return the parsing callback for this instance.  If this instance overrides 
    * the {@link listTags()} method, this function will return 'nullptr'.
    *  
    * @param checkParents  If this instance does not have the callback, 
    *                      check the inherited language mode(s) 
    */
   const SETagParsingCallbackType getParsingCallback(const bool checkParents=true) const;
   /**
    * @return
    * Return the parsing callback for the given language, or inherited by the 
    * given language.  If this instance (or an inherited instance) overrides 
    * the {@link listTags()} method, this function will return 'nullptr'.
    * 
    * @param langId        language mode identifier
    */
   static const SETagParsingCallbackType getRegisteredParsingCallback(const SEString &langId);
   /**
    * Register a callback function for listing tags for the given language type.
    * 
    * @param langId        language mode identifier
    * @param taggingFn     parsing and tagging callback 
    */
   static int registerParsingCallback(const slickedit::SEString &langId, 
                                      const SETagParsingCallbackType taggingFn);
   /**
    * Register a callback function for listing tags for the given language type, 
    * and specify if it supports list-locals, statement tagging, and token list. 
    * 
    * @param langId                 language mode identifier
    * @param taggingFn              parsing and tagging callback 
    * @param supportsLocals         does this callback support local variable tagging?
    * @param supportsStatements     does this callback support statement-level tagging? 
    * @param supportsTokenList      does this callback support building a token list? 
    * @param hasPositionalKeywords  does this parser create positional keywords?
    * @param supportsIncremental    does this parser support incremental parsing? 
    */
   static int registerParsingCallback(const slickedit::SEString &langId, 
                                      const SETagParsingCallbackType taggingFn,
                                      const bool supportsLocals,
                                      const bool supportsStatements,
                                      const bool supportsTokenList,
                                      const bool hasPositionalKeywords,
                                      const bool supportsIncremental);
   /**
    * Set the source code parsing callback for this language. 
    * This function implements general file parsing, partial file parsing, 
    * local variable parsing, and statement parsing. 
    *  
    * @param taggingFn     parsing and tagging callback 
    */
   void setParsingCallback(const SETagParsingCallbackType taggingFn);
   /**
    * Set the source code parsing callback for this language. 
    * This function implements general file parsing, partial file parsing, 
    * local variable parsing, and statement parsing. 
    *  
    * @param taggingFn              parsing and tagging callback 
    * @param supportsLocals         does this callback support local variable tagging?
    * @param supportsStatements     does this callback support statement-level tagging? 
    * @param supportsTokenList      does this callback support building a token list? 
    * @param hasPositionalKeywords  does this parser create positional keywords
    * @param supportsIncremental    does this parser support incremental parsing? 
    */
   void setParsingCallback(const SETagParsingCallbackType taggingFn,
                           const bool supportsLocals,
                           const bool supportsStatements,
                           const bool supportsTokenList,
                           const bool hasPositionalKeywords,
                           const bool supportsIncremental);

   /////////////////////////////////////////////////////////////////////////////
   // ID EXPRESSION INFO CALLBACKS
   /////////////////////////////////////////////////////////////////////////////
   
   /**
    * Check if we have a callback to get expression info for this target language, 
    * or if this instance overrides the {@link getIDExpressionInfo} method. 
    *  
    * @param checkParents  If this instance does not have the callback, 
    *                      check the inherited language mode(s) 
    */
   bool hasExpressionInfoCallback(const bool checkParents=true) const;
   /**
    * Check if there is an expression info callback registered for the 
    * given language, or inherited by the given language. 
    * 
    * @param langId     language mode identifier
    */
   static bool hasRegisteredExpressionInfoCallback(const SEString &langId);
   /**
    * @return 
    * Return the expression information callback for this instance. 
    * If this instance overrides the {@link getIDExpressionInfo()} method, 
    * this function will return 'nullptr'.
    *  
    * @param checkParents  If this instance does not have the callback, 
    *                      check the inherited language mode(s) 
    */
   const SETagExpressionInfoCallbackType getExpressionInfoCallback(const bool checkParents=true) const;
   /**
    * @return
    * Return the expression info callback for the given language, or inherited 
    * by the given language.  If this instance (or an inherited instance) overrides 
    * the {@link getIDExpressionInfo()} method, this function will return 'nullptr'.
    * 
    * @param langId        language mode identifier
    */
   static const SETagExpressionInfoCallbackType getRegisteredExpressionInfoCallback(const SEString &langId);
   /**
    * Register a callback function for getting the expression info for the given language type.
    * 
    * @param langId        language mode identifier
    * @param exprInfoFn    expression information callback
    */
   static int registerExpressionInfoCallback(const slickedit::SEString &langId, const SETagExpressionInfoCallbackType exprInfoFn);
   /**
    * Set the Context Tagging&reg; source code expression information 
    * gathering callback function.  This function gathers information about 
    * the current word at a given seek position, as well as any prefix expression 
    * leading up to that identifier. 
    *  
    * @param exprInfoFn    expression information callback
    */
   void setExpressionInfoCallback(const SETagExpressionInfoCallbackType exprInfoFn);


   /////////////////////////////////////////////////////////////////////////////
   // FIND TAGS (CONTEXT TAGGING SEARCH) CALLBACKS
   /////////////////////////////////////////////////////////////////////////////
   
   /**
    * Check if we have a callback to find symbols in context for this target 
    * language, or if this instance overrides the {@link findTags} method. 
    *  
    * @param checkParents  If this instance does not have the callback, 
    *                      check the inherited language mode(s)
    */
   bool hasFindTagsCallback(const bool checkParents=true) const;
   /**
    * Check if there is a find tags callback registered for the 
    * given language, or inherited by the given language. 
    * 
    * @param langId     language mode identifier
    */
   static bool hasRegisteredFindTagsCallback(const SEString &langId);

   /**
    * @return 
    * Return the find tags callback for this instance. 
    * If this instance overrides the {@link findTags()} method, 
    * this function will return 'nullptr'.
    *  
    * @param checkParents  If this instance does not have the callback, 
    *                      check the inherited language mode(s) 
    */
   const SETagFindTagsCallbackType getFindTagsCallback(const bool checkParents=true) const;
   /**
    * @return
    * Return the find tags callback for the given language, or inherited 
    * by the given language.  If this instance (or an inherited instance) overrides 
    * the {@link findTags()} method, this function will return 'nullptr'.
    * 
    * @param langId        language mode identifier
    */
   static const SETagFindTagsCallbackType getRegisteredFindTagsCallback(const SEString &langId);
   /**
    * Register a callback function for finding symbols for the given language type.
    * 
    * @param langId        language mode identifier
    * @param findTagsFn    find tags in context callback
    */
   static int registerFindTagsCallback(const slickedit::SEString &langId, const SETagFindTagsCallbackType findTagsFn);
   /**
    * Set the Context Tagging&reg; function for finding the set of symbols that 
    * match the search constraints as well as the expression information for 
    * the symbol at a given seek position. 
    * 
    * @param findTagsFn       find tags callback
    */
   void setFindTagsCallback(const SETagFindTagsCallbackType findTagsFn);


   /////////////////////////////////////////////////////////////////////////////
   // LIST TAGS FUNCTION CAPABILITIES
   /////////////////////////////////////////////////////////////////////////////

   /**
    * Set flag to indicate whether local variable tagging is supported.
    */
   void setListLocalsSupported(const bool onOff);
   /**
    * @return 
    * Return 'true' if local variable tagging is supported for this language. 
    */
   const bool isListLocalsSupported() const;
   /**
    * @return 
    * Return 'true' if local variable tagging is supported for the given language. 
    */
   static const bool isListLocalsSupported(const SEString &langId);

   /**
    * Set flag to indicate whether statement-level tagging is supported.
    */
   void setStatementTaggingSupported(const bool onOff);
   /**
    * @return 
    * Return 'true' if statement-level tagging is supported for this language.
    */
   const bool isStatementTaggingSupported() const;
   /**
    * @return 
    * Return 'true' if statement-level tagging is supported for the given language.
    */
   static const bool isStatementTaggingSupported(const SEString &langId);

   /**
    * Set flag to indicate whether tokenization is supported.
    */
   void setTokenListSupported(const bool onOff);
   /**
    * @return 
    * Return 'true' if tokenization is supported for this language. 
    */
   const bool isTokenListSupported() const;
   /**
    * @return 
    * Return 'true' if tokenization is supported for the given language. 
    */
   static const bool isTokenListSupported(const SEString &langId);

   /**
    * Set flag to indicate whether the parser creates positional keywords tokens.
    */
   void setPositionalKeywordsSupported(const bool onOff);
   /**
    * @return 
    * Return 'true' if the parser creates positional keywords tokens.
    */
   const bool isPositionalKeywordsSupported() const;
   /**
    * @return 
    * Return 'true' if the given language's parser creates positional keywords tokens.
    */
   static const bool isPositionalKeywordsSupported(const SEString &langId);

   /**
    * Set flag to indicate whether the parser supports incremental tagging.
    */
   void setIncrementalTaggingSupported(const bool onOff);
   /**
    * @return 
    * Return 'true' if the parser supports incremental tagging.
    */
   const bool isIncrementalTaggingSupported() const;
   /**
    * @return 
    * Return 'true' if the given language's parser supports incremental tagging.
    */
   static const bool isIncrementalTaggingSupported(const SEString &langId);


protected:

   /**
    * Indicate that this derived class implements the {@link listTags()} callback.
    */
   void setImplementsParsing();
   /**
    * Indicate that this derived class implements the {@link getIDExpressionInfo()} callback.
    */
   void setImplementsExpressionInfo();
   /**
    * Indicate that this derived class implements the {@link findTags()} callback.
    */
   void setImplementsFindTags();


private:

   SESharedPointer<struct SEPrivateContextTaggingInterface> mpTaggingFunctions;

};


} // namespace slickedit


