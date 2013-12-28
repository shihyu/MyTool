////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#import "se/tags/TaggingGuard.e"
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
    * Symbol attribute flags.  This is a bitset of VS_TAGFLAG_*
    * @see tag_insert_simple
    */
   int  m_tagFlags;

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
      m_tagFlags = 0;
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
         getMinimalLocalInfo((int)tagSpec);
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
         tag_tree_decompose_tag(tagSpec, 
                                m_name, m_className, 
                                m_tagType, m_tagFlags,
                                m_arguments, m_returnType);
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
      m_tagFlags = 0;
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
   }

   /**
    * Initialize symbol information object to the given local. 
    * <p> 
    * For synchronization, macros should perform a tag_lock_context(false)
    * prior to invoking this function.
    */
   int getLocalInfo(int local_id) {
      if (m_name != null) initialize();
      status := tag_get_local2(local_id, m_name, m_tagType,
                               m_fileName, m_line, m_offset,
                               m_scopeLine, m_scopeOffset,
                               m_endLine, m_endOffset,
                               m_className, m_tagFlags,
                               m_arguments, m_returnType);
      tag_get_detail2(VS_TAGDETAIL_local_name_linenum, local_id, m_nameLine);
      tag_get_detail2(VS_TAGDETAIL_local_name_seekpos, local_id, m_nameOffset);
      tag_get_detail2(VS_TAGDETAIL_local_parents, local_id, m_classParents);
      tag_get_detail2(VS_TAGDETAIL_local_throws, local_id, m_exceptions);
      tag_get_detail2(VS_TAGDETAIL_local_template_args, local_id, m_templateArgs);
      m_langId = (_isEditorCtl() && file_eq(m_fileName,p_buf_name))? p_LangId:"";
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
      status := tag_get_local(local_id, m_name, m_tagType,
                              m_fileName, m_line,
                              m_className, m_tagFlags,
                              m_arguments, m_returnType);
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
      status := tag_get_context(context_id, m_name, m_tagType,
                                m_fileName, m_line, m_offset,
                                m_scopeLine, m_scopeOffset,
                                m_endLine, m_endOffset,
                                m_className, m_tagFlags,
                                m_arguments, m_returnType);
      tag_get_detail2(VS_TAGDETAIL_context_name_linenum, context_id, m_nameLine);
      tag_get_detail2(VS_TAGDETAIL_context_name_seekpos, context_id, m_nameOffset);
      tag_get_detail2(VS_TAGDETAIL_context_parents, context_id, m_classParents);
      tag_get_detail2(VS_TAGDETAIL_context_throws, context_id, m_exceptions);
      tag_get_detail2(VS_TAGDETAIL_context_template_args, context_id, m_templateArgs);
      m_langId = (_isEditorCtl() && file_eq(m_fileName,p_buf_name))? p_LangId:"";
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
      status := tag_get_context_simple(context_id, m_name, m_tagType,
                                       m_fileName, m_line,
                                       m_className, m_tagFlags,
                                       m_arguments, m_returnType);
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
      status := tag_get_match(match_id, m_tagDatabase, 
                              m_name, m_tagType, 
                              m_fileName, m_line,
                              m_className, m_tagFlags,
                              m_arguments, m_returnType);
      tag_get_detail2(VS_TAGDETAIL_match_start_seekpos, match_id, m_offset);
      tag_get_detail2(VS_TAGDETAIL_match_name_linenum,  match_id, m_nameLine);
      tag_get_detail2(VS_TAGDETAIL_match_name_seekpos,  match_id, m_nameOffset);
      tag_get_detail2(VS_TAGDETAIL_match_scope_linenum, match_id, m_scopeLine);
      tag_get_detail2(VS_TAGDETAIL_match_scope_seekpos, match_id, m_scopeOffset);
      tag_get_detail2(VS_TAGDETAIL_match_end_linenum,   match_id, m_endLine);
      tag_get_detail2(VS_TAGDETAIL_match_end_seekpos,   match_id, m_endOffset);
      tag_get_detail2(VS_TAGDETAIL_match_parents,       match_id, m_classParents);
      tag_get_detail2(VS_TAGDETAIL_match_throws,        match_id, m_exceptions);
      tag_get_detail2(VS_TAGDETAIL_match_template_args, match_id, m_templateArgs);
      m_langId = (_isEditorCtl() && file_eq(m_fileName,p_buf_name))? p_LangId:"";
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
      status := tag_get_match(match_id, m_tagDatabase, 
                              m_name, m_tagType, 
                              m_fileName, m_line,
                              m_className, m_tagFlags,
                              m_arguments, m_returnType);
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
      tag_get_info(m_name, m_tagType,
                   m_fileName, m_line,
                   m_className, m_tagFlags);
      tag_get_detail(VS_TAGDETAIL_arguments, m_arguments);
      tag_get_detail(VS_TAGDETAIL_return, m_returnType);
      tag_get_detail(VS_TAGDETAIL_class_parents, m_classParents);
      tag_get_detail(VS_TAGDETAIL_throws, m_exceptions);
      tag_get_detail(VS_TAGDETAIL_template_args, m_templateArgs);
      tag_get_detail(VS_TAGDETAIL_language_id, m_langId);
      m_tagDatabase = tag_current_db();
      return 0;
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
      tag_get_info(m_name, m_tagType,
                   m_fileName, m_line,
                   m_className, m_tagFlags);
      return 0;
   }


   /**
    * @return Return SlickEdit 2.0 style tag specification.
    * @see tag_tree_compose_tag 
    */
   _str getTagSpecification() {
      return tag_tree_compose_tag(m_name, m_className, m_tagType, m_tagFlags, m_arguments, m_returnType);
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
   boolean equals(sc.lang.IEquals &rhs) {

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
             !file_eq(this.m_fileName, psym->m_fileName)) {
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
             !file_eq(this.m_fileName, pcm->file_name)) {
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
         tag_tree_decompose_tag(ps->toString(), 
                                auto tag_name="", auto class_name="", 
                                auto type_name="", auto tag_flags=0, 
                                auto arguments="", auto return_type="");

         // compare symbol name and class name
         if (this.m_name :!= tag_name) {
            return false;
         }
         if (this.m_className :!= class_name) {
            return false;
         }


         // compare arguments, return type, exceptions, class inheritance, and template args
         if ((this.m_arguments  != null && arguments   != null && this.m_arguments  != arguments) &&
             (this.m_returnType != null && return_type != null && this.m_returnType != return_type)) {
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

