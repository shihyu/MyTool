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
#region Imports
#include "slick.sh"
#include "tagsdb.sh"
#require "sc/lang/IEquals.e"
#require "sc/lang/IHashable.e"
#require "sc/lang/String.e"
#require "se/tags/TaggingGuard.e"
#import "context.e"
#import "stdprocs.e"
#endregion

/**
 * The "se.tags" namespace contains interfaces and classes that are
 * necessary for working with SlickEdit's tag databases and symbol 
 * analysis. 
 */
namespace se.tags;

/**
 * This class is used to represent a symbol identified by the symbol
 * tagging engine.
 */
class SymbolInfo : sc.lang.IEquals, sc.lang.IHashable {

   /**
    * Symbol name.
    */
   _str m_name;
   /**
    * Fully qualified package and/or class name identifying the
    * scope the symbol is declared in.
    */
   _str m_className;

   /**
    * Symbol type name.
    * @see tag_get_type
    */
   _str m_tagType;
   /**
    * Symbol attribute flags.  This is a bitset of SE_TAG_FLAG_*
    * @see tag_insert_simple
    */
   SETagFlags m_tagFlags;

   /**
    * Absolute path of file the tag is located in
    */
   _str m_fileName;
   /**
    * Language associated with 'file_name' ({@link p_LangId} property)
    */
   _str m_langId;

   /**
    * Real line number (not including imaginary lines) that this 
    * symbol's definition/declaration STARTS on. Note that this is the 
    * START of the definition, which can include modifier attributes 
    * or keywords or return type information. It is not necessarily 
    * the line containing the symbol name. 
    */
   int m_line;
   /**
    * Real seek position (not including imaginary lines) that this 
    * symbol's definition/declaration STARTS on. 
    */
   int m_offset;

   /**
    * Real line number (not including imaginary lines) of this
    * symbol's name within it's definition/declaration.
    */
   int m_nameLine;
   /**
    * Real seek position (not including imaginary lines) of this 
    * symbol's name within it's definition/declaration.
    */
   int m_nameOffset;

   /**
    * Real line number (not including imaginary lines) of the start of
    * the scope for this symbol.  For example, in C/C++, this is the 
    * location of the open brace for a function or class definition. 
    */
   int m_scopeLine;
   /**
    * Real seek position (not including imaginary lines) of the start 
    * of the scope for this symbol.  For example, in C/C++, this is 
    * the location of the open brace for a function or class 
    * definition. 
    */
   int m_scopeOffset;

   /**
    * Real line number (not including imaginary lines) of the end of
    * the scope for this symbol.  For example, in C/C++, this is the 
    * location of the close brace for a function or class definition. 
    */
   int m_endLine;
   /**
    * Real seek position (not including imaginary lines) of the end of
    * the scope for this symbol.  For example, in C/C++, this is the 
    * location of the open brace for a function or class definition. 
    */
   int m_endOffset;

   /**
    * Declared type of a function, variable or typedef.
    */
   _str m_returnType;

   /**
    * Function argument list signature for functions, parameterized 
    * preprocessor macros, or variables of function pointer type.
    */
   _str m_arguments;

   /**
    * Function exception (throws) clause information for languages
    * that support explicit exception handling.
    */
   _str m_exceptions;

   /**
    * If this is a class, struct, or interface, the class parents are
    * the list of classes or interfaces which it inherits from.  The
    * class names are separated by semicolons and put in the native
    * format used by the language to represent class names.
    */
   _str m_classParents;

   /**
    * For template classes and template functions, this contains the
    * template signature.
    */
   _str m_templateArgs;

   /**
    * Tag database that this symbol was found in.
    */
   _str m_tagDatabase;

   /**
    * Real line number (not including imaginary lines) of the start of
    * this symbol as found in the tag database.  This can be the same as the 
    * start line number, or slightly different if the source file has been 
    * modified and the tag database is out-of-date.
    */
   int m_taggedLine;

   /**
    * Date of file on disk when it was tagged.  This should be the same as the 
    * current date on disk, but can lag behind if the tag file is not up-to-date. 
    *  
    * The date is a 64-bit integer of the form YYYYMMDDhhmmssxxx (xxx is ms). 
    */
   long m_taggedDate;

   /**
    * Type of documentation comment for this symbol.
    */
   SETagDocCommentType m_docCommentType;

   /**
    * Contents of documentation comment for this symbol.
    */
   _str m_docCommentText;

   /**
    * Construct an instance of a symbol information object. 
    * <p> 
    * The object can also be constructed from an old-style (SlickEdit 
    * 2.0) tag specification. 
    *  
    * @param matchType  Type of symbol information to retrieve: 
    *                   <ul> 
    *                   <li><b>L</b>  -- local variable
    *                   <li><b>LQ</b> -- local variable, minimal
    *                   <li><b>C</b>  -- current file
    *                   <li><b>CQ</b> -- current file, minimal
    *                   <li><b>M</b>  -- symbol search result
    *                   <li><b>MQ</b> -- symbol search result, minimal
    *                   <li><b>D</b>  -- symbol from tag database
    *                   <li><b>DQ</b> -- symbol from tag database, minimal
    *                   <li><b>Q</b>  -- parse given tag specification
    *                   <li><b>""</b> -- parse given tag specifiation
    *                   </ul>
    * @param tagSpec    Symbol ID for locals, current file, or matches. 
    *                   "" for symbols from the tag database.
    *                   Otherwise this is a ta specification string
    *                   (see {@link tag_tree_compose_tag}). 
    */
   SymbolInfo(_str matchType="", _str tagSpec=null) { 
   
      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      m_name  = null;
      m_className = null;
      m_tagType = null;
      m_tagFlags = SE_TAG_FLAG_NULL;
      m_fileName = null;
      m_langId = null;
      m_line = 0;
      m_offset = 0;
      m_nameLine = 0;
      m_nameOffset = 0;
      m_scopeLine = 0;
      m_scopeOffset = 0;
      m_endLine = 0;
      m_endOffset = 0;
      m_returnType = 0;
      m_arguments = 0;
      m_exceptions = 0;
      m_classParents = null;
      m_templateArgs = null;
      m_tagDatabase = null;
      m_taggedLine = 0;
      m_taggedDate = 0;
      m_docCommentType = SE_TAG_DOCUMENTATION_NULL;
      m_docCommentText = null;

      switch (upcase(matchType)) {
      case "L":    // local
         getLocalInfo((int)tagSpec);
         break;
      case "QL":   // local, minimal
      case "LQ":   // local, minimal
         getMinimalLocalInfo((int)tagSpec);
         break;

      case "C":    // current file (context)
         getContextInfo((int)tagSpec);
         break;
      case "QC":   // current file, minimal
      case "CQ":   // current file, minimal
         getMinimalContextInfo((int)tagSpec);
         break;

      case "M":    // current match set
         getMatchInfo((int)tagSpec);
         break;
      case "MQ":   // current match set, minimal
      case "QM":   // current match set, minimal
         getMinimalMatchInfo((int)tagSpec);
         break;

      case "D":    // current tag database
         getTagInfo((int)tagSpec);
         break;
      case "DQ":    // current tag database, minimal
      case "QD":    // current tag database, minimal
         getMinimalTagInfo((int)tagSpec);
         break;

      case "":
      case "Q":
         // no tag specification, then just accept the default initializers
         if (tagSpec == null || tagSpec == "") break;
         tag_decompose_tag_symbol_info(tagSpec, this);
         break;

      default:
         ASSERT(false);
         break;
      }
   }

   /**
    * Set all the field data for this structure to defaults.
    */
   void initialize() {
      m_name  = null;
      m_className = null;
      m_tagType = null;
      m_tagFlags = SE_TAG_FLAG_NULL;
      m_fileName = null;
      m_langId = null;
      m_line = 0;
      m_offset = 0;
      m_nameLine = 0;
      m_nameOffset = 0;
      m_scopeLine = 0;
      m_scopeOffset = 0;
      m_endLine = 0;
      m_endOffset = 0;
      m_returnType = 0;
      m_arguments = 0;
      m_exceptions = 0;
      m_classParents = null;
      m_templateArgs = null;
      m_tagDatabase = null;
      m_taggedLine = 0;
      m_taggedDate = 0;
      m_docCommentType = SE_TAG_DOCUMENTATION_NULL;
      m_docCommentText = null;
   }

   /**
    * Convert this symbol to a VS_TAG_BROWSE_INFO structure.
    */
   VS_TAG_BROWSE_INFO getBrowseInfo() {
      tag_browse_info_init(auto cm);
      cm.member_name = m_name;
      cm.class_name  = m_className;
      cm.type_name = m_tagType;
      cm.type_id = tag_get_type_id(m_tagType);
      cm.flags = m_tagFlags;
      cm.file_name = m_fileName;
      cm.language = m_langId;
      cm.line_no = m_line;
      cm.seekpos = m_offset;
      cm.name_line_no = m_nameLine;
      cm.name_seekpos = m_nameOffset;
      cm.scope_line_no = m_scopeLine;
      cm.scope_seekpos = m_scopeOffset;
      cm.end_line_no = m_endLine;
      cm.end_seekpos = m_endOffset;
      cm.return_type = m_returnType;
      cm.arguments = m_arguments;
      cm.exceptions = m_exceptions;
      cm.class_parents = m_classParents;
      cm.template_args = m_templateArgs;
      cm.tag_database = m_tagDatabase;
      cm.tagged_line_no = m_taggedLine;
      cm.tagged_date = m_taggedDate;
      cm.doc_type = m_docCommentType;
      cm.doc_comments = m_docCommentText;
      return cm;
   }

   /**
    * Initialize symbol information object to the given local. 
    * <p> 
    * For synchronization, macros should perform a tag_lock_context(false)
    * prior to invoking this function.
    */
   int getLocalInfo(int local_id) {
      if (m_name != null) initialize();
      status := tag_get_local_symbol_info(local_id, this);
      if (m_langId == "" && _isEditorCtl() && _file_eq(m_fileName,p_buf_name)) {
         m_langId = p_LangId;
      }
      return status;
   }

   /**
    * Initialize symbol information object to the given local. 
    * <p> 
    * Only retrieve the minimal amount of information:  name, class, 
    * type, flags, file and line number. 
    * <p> 
    * For synchronization, macros should perform a tag_lock_context(false)
    * prior to invoking this function.
    */
   int getMinimalLocalInfo(int local_id) {
   if (m_name != null) initialize();
      #pragma option(deprecation,off)
      status := tag_get_local(local_id, m_name, m_tagType,
                              m_fileName, m_line,
                              m_className, m_tagFlags,
                              m_arguments, m_returnType);
      #pragma option(deprecation,on)
      return status;
   }

   /**
    * Initialize symbol information object to the given symbol in the 
    * current file. 
    * <p> 
    * For synchronization, macros should perform a tag_lock_context(false)
    * prior to invoking this function.
    */
   int getContextInfo(int context_id) {
      if (m_name != null) initialize();
      status := tag_get_context_symbol_info(context_id, this);
      if (m_langId == "" && _isEditorCtl() && _file_eq(m_fileName,p_buf_name)) {
         m_langId = p_LangId;
      }
      return status;
   }

   /**
    * Initialize symbol information object to the given symbol in the 
    * current file.
    * <p> 
    * Only retrieve the minimal amount of information:  name, class, 
    * type, flags, file and line number. 
    * <p> 
    * For synchronization, threads should perform a 
    * tag_lock_context(false) prior to invoking this function. 
    */
   int getMinimalContextInfo(int context_id) {
      if (m_name != null) initialize();
      #pragma option(deprecation,off)
      status := tag_get_context_simple(context_id, m_name, m_tagType,
                                       m_fileName, m_line,
                                       m_className, m_tagFlags,
                                       m_arguments, m_returnType);
      #pragma option(deprecation,on)
      return status;
   }

   /**
    * Initialize symbol information to the given symbol in the current
    * (most recent) match set. 
    * <p> 
    * For synchronization, macros should perform a tag_lock_matches(false)
    * prior to invoking this function.
    */
   int getMatchInfo(int match_id) {
      if (m_name != null) initialize();
      status := tag_get_match_symbol_info(match_id, this);
      if (m_langId == "" && _isEditorCtl() && _file_eq(m_fileName,p_buf_name)) {
         m_langId = p_LangId;
      }
      return status;
   }

   /**
    * Initialize symbol information to the given symbol in the current
    * (most recent) match set. 
    * <p> 
    * Only retrieve the minimal amount of information:  name, class, 
    * type, flags, file and line number. 
    */
   int getMinimalMatchInfo(int match_id) {
      if (m_name != null) initialize();
      #pragma option(deprecation,off)
      status := tag_get_match(match_id, m_tagDatabase, 
                              m_name, m_tagType, 
                              m_fileName, m_line,
                              m_className, m_tagFlags,
                              m_arguments, m_returnType);
      #pragma option(deprecation,on)
      return status;
   }

   /**
    * Initialize symbol information to the most recent symbol found by
    * the most recent tag database search using the given iterator. 
    *  
    * @param iterator_id   Database iterator for tags 
    *                      (currently unused)
    */
   int getTagInfo(int iterator_id) {
      if (m_name != null) initialize();
      status := tag_get_tag_symbol_info(this);
      return status;
   }

   /**
    * Initialize symbol information to the most recent symbol found by
    * the most recent tag database search using the given iterator. 
    * <p> 
    * Only retrieve the minimal amount of information:  name, class, 
    * type, flags, file and line number. 
    *  
    * @param iterator_id   Database iterator for tags 
    *                      (currently unused)
    */
   int getMinimalTagInfo(int iterator_id) {
      if (m_name != null) initialize();
      #pragma option(deprecation,off)
      tag_get_info(m_name, m_tagType,
                   m_fileName, m_line,
                   m_className, m_tagFlags);
      #pragma option(deprecation,on)
      return 0;
   }


   /**
    * @return Return SlickEdit 2.0 style tag specification.
    * @see tag_tree_compose_tag 
    */
   _str getTagSpecification() {
      return tag_compose_tag_symbol_info(this);
   }

   /** 
    * Compare two symbol information instances for equality.
    * <p> 
    * Compare this object with the given object of a compatible 
    * class.  The right hand side (rhs) object will always be a 
    * valid and initialized class instance. 
    * <p> 
    * Note that overriding this method effects both the equality 
    * == and inequality != operations 
    * <p> 
    * Also, note that the symbol comparisons are all done using 
    * CASE SENSITIVE comparisons, which may not be strictly correct 
    * for case-insensitive languages. 
    * 
    * @param rhs  object on the right hand side of comparison 
    *  
    * @return 'true' if this equals 'rhs', false otherwise 
    */
   bool equals(sc.lang.IEquals &rhs) {

      // this can't really happen, but it's fun to check for
      if (this==null && rhs==null) {
         return true;
      }
      if (this==null) {
         return false;
      }

      // comparing to another SymbolInfo instance?
      if (rhs instanceof "se.tags.SymbolInfo") {

         SymbolInfo *psym = (typeless*) &rhs;

         // compare positional information
         if ((this.m_line   > 0 && psym->m_line   > 0 && this.m_line   != psym->m_line) ||
             (this.m_offset > 0 && psym->m_offset > 0 && this.m_offset != psym->m_offset)) {
            return false;
         }
         if (this.m_tagType :!= psym->m_tagType) {
            return false;
         }

         // compare symbol name and class name
         if (this.m_name :!= psym->m_name) {
            return false;
         }
         if (this.m_className :!= psym->m_className) {
            return false;
         }

         // compare file name
         if (this.m_fileName != null && this.m_fileName != "" &&
             psym->m_fileName != null && psym->m_fileName != "" &&
             !_file_eq(this.m_fileName, psym->m_fileName)) {
            return false;
         }

         // compare language modes
         if (this.m_langId != null && psym->m_langId != null && this.m_langId :!= psym->m_langId) {
            return false;
         }

         // compare arguments, return type, exceptions, class inheritance, and template args
         if ((this.m_arguments    != null && psym->m_arguments    != null  && this.m_arguments   != psym->m_arguments) &&
             (this.m_returnType   != null && psym->m_returnType   != null && this.m_returnType   != psym->m_returnType) &&
             (this.m_exceptions   != null && psym->m_exceptions   != null && this.m_exceptions   != psym->m_exceptions) &&
             (this.m_classParents != null && psym->m_classParents != null && this.m_classParents != psym->m_classParents) &&
             (this.m_templateArgs != null && psym->m_templateArgs != null && this.m_templateArgs != psym->m_templateArgs) ) {
            return false;
         }

         // OK, they are close enough
         return true;
      }

      if (rhs instanceof "VS_TAG_BROWSE_INFO") {
         VS_TAG_BROWSE_INFO *pcm = (typeless*) &rhs;
         
         // compare positional information
         if ((this.m_line   > 0 && pcm->line_no > 0 && this.m_line   != pcm->line_no) ||
             (this.m_offset > 0 && pcm->seekpos > 0 && this.m_offset != pcm->seekpos)) {
            return false;
         }
         if (this.m_tagType :!= pcm->type_name) {
            return false;
         }

         // compare symbol name and class name
         if (this.m_name :!= pcm->member_name) {
            return false;
         }
         if (this.m_className :!= pcm->class_name) {
            return false;
         }

         // compare file name
         if (this.m_fileName != null && this.m_fileName != "" &&
             pcm->file_name  != null && pcm->file_name  != "" &&
             !_file_eq(this.m_fileName, pcm->file_name)) {
            return false;
         }

         // compare language modes
         if (this.m_langId != null && pcm->language != null && this.m_langId :!= pcm->language) {
            return false;
         }

         // compare arguments, return type, exceptions, class inheritance, and template args
         if ((this.m_arguments    != null && pcm->arguments     != null  && this.m_arguments   != pcm->arguments) &&
             (this.m_returnType   != null && pcm->return_type   != null && this.m_returnType   != pcm->return_type) &&
             (this.m_exceptions   != null && pcm->exceptions    != null && this.m_exceptions   != pcm->exceptions) &&
             (this.m_classParents != null && pcm->class_parents != null && this.m_classParents != pcm->class_parents) &&
             (this.m_templateArgs != null && pcm->template_args != null && this.m_templateArgs != pcm->template_args) ) {
            return false;
         }

         // OK, they are close enough
         return true; 
      }

      if (rhs instanceof "sc.lang.String") {

         // assume that if it is a string, it is a SlickEdit 2.0 style tag spec
         class sc.lang.String *ps = (typeless*) &rhs;
         tag_decompose_tag_browse_info(ps->toString(), auto cm);

         // compare symbol name and class name
         if (this.m_name :!= cm.member_name) {
            return false;
         }
         if (this.m_className :!= cm.class_name) {
            return false;
         }


         // compare arguments, return type, exceptions, class inheritance, and template args
         if ((this.m_arguments  != null && cm.arguments   != null && this.m_arguments  != cm.arguments) &&
             (this.m_returnType != null && cm.return_type != null && this.m_returnType != cm.return_type)) {
            return false;
         }

         // OK, they are close enough
         return true;
      }

      // Not even close, the object type doesn't even match
      return false;
   }

   /**
    * @return Generate a string as the hash key for this object.
    */
   _str getHashKey() {
      return this.m_className":"this.m_name;
   }

}

namespace default;

/**
 * Retrieve information about the given tag match.  Though this function is highly
 * optimized, it is often more efficient to use {@link tag_get_detail2} to retrieve only
 * specific information about a match rather than everything.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(false) 
 * prior to invoking this function.
 *
 * @param match_id         Match ID [ from 1 to {@link tag_get_num_of_matches}() ] of tag
 *                         match to retrieve information about.
 * @param symbolInfo       (Output) Instance of 
 *                         se.tags.SymbolInfo to fill in.
 *
 * @return 0 on success, <0 on error.
 *  
 * @see tag_get_match 
 * @see tag_get_match_browse_info 
 * @see tag_clear_matches
 * @see tag_insert_match
 * @see tag_insert_match_fast
 * @see tag_get_detail2
 * @see tag_get_num_of_matches
 * @see tag_pop_matches
 * @see tag_push_matches
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_get_match_symbol_info(int match_id, class se.tags.SymbolInfo &symbolInfo);

/**
 * Add a tag to the match set.  The tag database allows you to maintain a list of tags
 * very efficiently through the match set.  This is useful when searching for specific
 * tags.  Many of the Context Tagging&reg; functions are designed to insert directly into
 * the match set.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * prior to invoking this function.
 *
 * @param symbolInfo          Instance of se.tags.SymbolInfo to
 *                            insert. This contains all the
 *                            information about the symbol.
 * @param checkForDuplicates  Before inserting, verify that the symbol is not 
 *                            already in the match set, return match_id if so. 
 *
 * @return sequence number (match_id) of matching tag on success, or &lt;0 on error.
 *
 * @see tag_clear_matches 
 * @see tag_get_match 
 * @see tag_get_match_browse_info 
 * @see tag_get_match_symbol_info
 * @see tag_get_detail2
 * @see tag_get_num_of_matches
 * @see tag_get_match_browse_info
 * @see tag_get_match_symbol_info
 * @see tag_insert_context
 * @see tag_insert_local2
 * @see tag_insert_match
 * @see tag_insert_match
 * @see tag_insert_tag
 * @see tag_list_any_symbols
 * @see tag_list_class_context
 * @see tag_list_class_locals
 * @see tag_list_class_tags
 * @see tag_list_context_globals
 * @see tag_list_context_packages
 * @see tag_list_globals_of_type
 * @see tag_list_in_file
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_insert_match_symbol_info(se.tags.SymbolInfo &symbolInfo, bool checkForDuplicates=true);

/**
 * Retrieve information about the given context ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param context_id    Context ID [ from 1 to {@link tag_get_num_of_context}() ] 
 *                      of context tag to retrieve information about.
 * @param symbolInfo    (Output) Instance of se.tags.SymbolInfo
 *                      to fill in.
 *
 * @return  0 on success, or &lt;0 on error. 
 *  
 * @see tag_clear_context
 * @see tag_current_context
 * @see tag_find_context
 * @see tag_get_detail2
 * @see tag_get_num_of_context
 * @see tag_next_context 
 * @see tag_get_context 
 * @see tag_get_context_simple 
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_get_context_symbol_info(int context_id, se.tags.SymbolInfo &symbolInfo);

/**
 * Add a tag and its context information to the context list.
 * The context for the current tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see {@link tag_end_context}().
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param outer_context       context ID for the outer context (eg. class/struct)
 * @param symbolInfo          Instance of se.tags.SymbolInfo to
 *                            insert. This contains all the
 *                            information about the symbol.
 *
 * @return sequence number (context_id) of tag context on success, or &lt;0 on error.
 *
 * @see tag_clear_context
 * @see tag_current_context
 * @see tag_end_context
 * @see tag_find_context
 * @see tag_get_context 
 * @see tag_get_context_simple 
 * @see tag_get_detail2
 * @see tag_get_num_of_context
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 * @see tag_insert_local
 * @see tag_insert_match
 * @see tag_insert_tag
 * @see tag_next_context
 * @see tag_set_context_parents 
 * @see tag_set_context_name_location 
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_insert_context_symbol_info(int outer_context, se.tags.SymbolInfo &symbolInfo);

/**
 * Retrieve complete information about the given local ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param local_id      Local ID [ from 1 to {@link tag_get_num_of_locals}() ] of local
 *                      symbol to retrieve information about.
 * @param symbolInfo    (Output) Instance of se.tags.SymbolInfo
 *                      to fill in.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_clear_locals
 * @see tag_current_local
 * @see tag_find_local
 * @see tag_get_detail2
 * @see tag_get_num_of_locals
 * @see tag_next_local
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_get_local_symbol_info(int local_id, se.tags.SymbolInfo &symbolInfo);

/**
 * Add a tag and its context information to the local variables list, which is
 * the list of tags found in the current function or procedure, accounting for
 * scope and the current cursor position.
 * <p>
 * The context for the a local tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see {@link tag_end_local}().
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param symbolInfo    Instance of Slick-C <code>struct VS_TAG_BROWSE_INFO</code> to insert. 
 *                      This contains all the information about the symbol. 
 *
 * @return sequence number (local_id) of local variable on success, or &lt;0 on error.
 *
 * @see tag_clear_locals
 * @see tag_current_local
 * @see tag_find_local
 * @see tag_get_local
 * @see tag_get_detail2
 * @see tag_get_num_of_locals
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 * @see tag_insert_context
 * @see tag_insert_local
 * @see tag_insert_match
 * @see tag_insert_tag
 * @see tag_next_local
 * @see tag_set_local_parents
 * @see tag_set_local_name_location 
 * @see tag_end_local
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_insert_local_symbol_info(se.tags.SymbolInfo &symbolInfo);

/**
 * Retrieve general information about the current tag (as
 * defined by calls to <i>tag_find_equal</i>, <i>tag_find_prefix</i>, 
 * <i>tag_find_in_file</i>, <i>tag_find_in_class</i>, etc.). 
 * If the current tag is not defined, such as
 * immediately after opening a database or a failed search), all strings
 * will be set to "", and line_no and tag_flags will be set to 0.
 *
 * @param cm         (Output) Instance of {@link VS_TAG_BROWSE_INFO} to fill in. 
 *
 * @see tag_get_info 
 * @see tag_get_detail
 * @see tag_find_equal
 * @see tag_find_in_class
 * @see tag_find_in_file
 * @see tag_find_prefix
 * @see tag_next_equal
 * @see tag_next_in_class
 * @see tag_next_in_file
 * @see tag_next_prefix
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_get_tag_symbol_info(se.tags.SymbolInfo &symbolInfo);

/**
 * Insert the given tag with accompanying information into the database. 
 * The symbol is inserted into the current tag database, ignoring whatever 
 * <code>symbolInfo.m_tagDatabase</code> is set to. 
 *
 * @param symbolInfo    Instance of Slick-C <code>struct VS_TAG_BROWSE_INFO</code> to insert. 
 *                      This contains all the information about the symbol. 
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_insert_file_end
 * @see tag_insert_file_start
 * @see tag_insert_tag
 * @see tag_insert_simple
 * @see tag_insert_tag_browse_info
 * @see tag_insert_tag_symbol_info
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_insert_tag_symbol_info(se.tags.SymbolInfo &symbolInfo);

/**
 * Initialize a tag browse info structure. 
 *  
 * @param cm               (output) symbol information (VS_TAG_BROWSE_INFO)
 * @param tag_name         name of symbol 
 * @param class_name       name of class that tag belongs to
 * @param type_name        type of tag, (see SE_TAG_TYPE_*)
 * @param tag_flags        tag attributes (see SE_TAG_FLAG_*)
 * @param file_name        path to file that is located in
 * @param line_no          line number that tag is positioned on
 * @param seekpos          file offset that tag is positioned on
 * @param arguments        function arguments
 * @param return_type      function/variable return type 
 *
 * @see tag_decompose_tag_browse_info
 * @see tag_compose_tag_browse_info
 *
 * @categories Tagging_Functions 
 */
extern void tag_init_tag_symbol_info(se.tags.SymbolInfo &symbolInfo,
                                     _str tag_name="",
                                     _str class_name="",
                                     _str type_name_or_id="",
                                     SETagFlags tag_flags=SE_TAG_FLAG_NULL,
                                     _str file_name="",
                                     int line_no=0, int seekpos=0,
                                     _str arguments="",
                                     _str return_type="");

/**
 * Encode the given tag as a string.  The format of the entire string is as follows:
 * <pre>
 *       <i>tag_name</i> ( <i>class_name</i> : <i>type_name</i> ) <i>tag_flags</i> ( <i>arguments</i> ) <i>return_type</i>
 * </pre>
 * <p>The class_name is optional, if not given the string may be encoded as follows, indicating that the tag is a global:
 * <pre>
 *       <i>tag_name</i> ( <i>type_name</i> ) <i>tag_flags</i> ( <i>arguments</i> ) <i>return_type</i>
 * </pre>
 *
 * <p> 
 * The type_name, arguments, and return_type are also optional. 
 * If both the arguments and return_type are omitted, the tag is encoded as follows:
 * <pre>
 *       <i>tag_name</i> ( <i>class_name</i> : <i>type_name</i> ) <i>tag_flags</i>
 * </pre>
 * <p>Furthermore, if tag_flags is 0, it is omitted.
 *
 * <p> 
 * Note that the encoding format is not resilient against names that contain special characters, 
 * however, within the argument list, it is allowed to have parenthesis, as long as they are balanced.
 *
 * <p> 
 * The extension specific procedure and local variable search functions (_[ext]_proc_search) 
 * return tags using the format described above. 
 * This function may be used to easily and efficiently implement that part of a proc search function.
 *
 * @param cm   (input) symbol information
 *
 * @return String representation for the tag passed in.
 * @see tag_decompose_tag_symbol_info
 *
 * @categories Tagging_Functions 
 */
extern _str tag_compose_tag_symbol_info(se.tags.SymbolInfo &symbolInfo);

/**
 * Decode the given proc_name into the components of the tag.  See
 * {@link tag_tree_compose_tag} for details about how tags are encoded as strings.
 *
 * @param proc_name  Encoded tag from {@link tag_tree_compose_tag} on an extension specific tag search function.
 * @param cm         (output) symbol information
 *
 * @see tag_compose_tag_symbol_info
 *
 * @categories Tagging_Functions
 */
extern void tag_decompose_tag_symbol_info(_str proc_name, se.tags.SymbolInfo &symbolInfo);

/**
 * Encode class name, member name, signature, etc. in order to make
 * caption for a symbol very quickly.  Returns the resulting tree caption
 * as a NULL terminated string.
 *
 * The output string is generally formatted as follows:
 * <PRE>
 *    member_name[()] &lt;tab&gt; [class_name::member_name[(arguments)]
 * </PRE>
 * Parenthesis are added only for function types (proc, proto, constr, destr, func).
 * The result is returned as a pointer to a static character array.
 *
 * <p>This function is highly optimized, since it is one of the most
 * critical code paths used by the symbol browser.
 *
 * @param symbolInfo    symbol information
 * @param include_class if 'false', does not include class name
 * @param include_args  if 'false', does not include function or template signature
 * @param include_tab   append class name after signature if 'true',
 *                      prepend class name with :: if 'false'.
 *
 * @return Caption formatted in standard form as normally presented in symbol browser.
 * 
 * @example 
 * The following example illustrates constructing a caption for the following C++ class member prototype:
 * <pre>
 * 	static void MyClass::myMember(int a, bool x);
 * </pre>
 * The function would be invoked as follows:
 * <pre>
 *    se.tags.SymbolInfo symbolInfo;
 *    symbolInfo.m_name = "myMember";
 *    symbolInfo.m_className = "MyClass";
 *    symbolInfo.m_tagType = "func";
 *    symbolInfo.m_tagFlags = SE_TAG_FLAG_STATIC;
 *    symbolInfo.m_arguments = "int a, bool x";
 * 	caption := tag_make_caption_from_symbol_info(symbolInfo, true, true, include_tab);
 * </pre>
 * producing the following caption:
 * <pre>
 * 	myMember()&lt;tab&gt;MyClass::myMember(int a, bool x)
 * </pre>
 * and the following if include_tab is false.
 * <pre>
 * 	MyClass::myMember(int a, bool x)
 * </pre>
 *
 * @see tag_get_detail
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_get_instance_info 
 * @see tag_tree_make_caption 
 * @see tag_tree_make_caption_fast
 *
 * @categories Tagging_Functions
 */
extern _str tag_make_caption_from_symbol_info(se.tags.SymbolInfo &symbolInfo,
                                              bool include_class=true,
                                              bool include_args=true,
                                              bool include_tab=false);

