////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49352 $
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
#include "color.sh"
#import "backtag.e"
#import "box.e"
#import "c.e"
#import "caddmem.e"
#import "cbrowser.e"
#import "ccode.e"
#import "codehelp.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "files.e"
#import "fileman.e"
#import "guiopen.e"
#import "ini.e"
#import "last.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "recmacro.e"
#import "saveload.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "util.e"
#import "se/tags/TaggingGuard.e"
#endregion


// Just generate the implementation here.  (ie, like we do for java).
#define LVSELECTION_IMPL_ONLY 1

// Generate prototypes to the current file, and generate the implementation 
// into the clipboard.
#define LVSELECTION_IMPL_CLIPBOARD 2

// Generate prototypes to the current file, and 
// the implementation to the associated implementation
// file.
#define LVSELECTION_IMPL_ASSOCIATED 3

// Marks generated code as inline.
#define LVGENFLAG_INLINE 1

struct ListVirtualsGenerationOptions
{
   /** 
    * Implementation options from _list_virtuals_selecttree_cb. 
    * See LVSELECTION_*
    */
   int selection;

   /**
    * See LVGENFLAG_*
    */
   int flags;


   /**
    *  If "implementation in impl file" selected, this
    *  contains the name of the associated file.  If
    *  no associated file was found, is set to ''
    */
   _str associatedFile;
};


// Generation options.
ListVirtualsGenerationOptions gLVGenOptions;




/**
 * Translate the given bitset of return type flags (VSCODEHELP_RETURN_TYPE_*)
 * to the appropriate bitset of Context Tagging&reg; flags (VS_TAGCONTEXT_*)
 * <pre>
 *    VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS  => VS_TAGCONTEXT_ALLOW_private
 *    VSCODEHELP_RETURN_TYPE_CONST_ONLY      => VS_TAGCONTEXT_ONLY_const
 *    VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY   => VS_TAGCONTEXT_ONLY_volatile
 *    VSCODEHELP_RETURN_TYPE_STATIC_ONLY     => VS_TAGCONTEXT_ONLY_static
 * </pre>
 * 
 * @param return_flags     return type flags (VSCODEHELP_RETURN_TYPE_*)
 * 
 * @return codehelp_flags (VS_TAGCONTEXT_*)
 */
int _CodeHelpTranslateReturnTypeFlagsToContextFlags(int return_flags, int orig_context_flags=0)
{
   int context_flags = 0;
   if (return_flags & VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS) {
      context_flags |= VS_TAGCONTEXT_ALLOW_private;
      context_flags |= VS_TAGCONTEXT_ALLOW_protected;
      context_flags |= VS_TAGCONTEXT_ALLOW_package;
   }
   if (!(orig_context_flags & VS_TAGCONTEXT_FIND_lenient)) {
      if (return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY) {
         context_flags |= VS_TAGCONTEXT_ONLY_const;
      }
      if (return_flags & VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY) {
         context_flags |= VS_TAGCONTEXT_ONLY_volatile;
      }
      if (return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) {
         context_flags |= VS_TAGCONTEXT_ONLY_static;
      }
   }
   return context_flags;
}

/**
 * Check the input arguments and recycle result if it has already
 * been calculated.
 * 
 * @param input_args    function signature
 * @param caller_name   name of function calling us
 * @param rt            [reference] on success, set to return type
 * @param visited       [reference] list of prior results
 * 
 * @return 0 on success,
 *         VSCODEHELPRC_RETURN_TYPE_NOT_FOUND (<0) on failure,
 *         and 1 if the return type has not yet been cached.
 */
int _CodeHelpCheckVisited(_str input_args, _str caller_name,
                          struct VS_TAG_RETURN_TYPE &rt,
                          VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   //isay(depth, caller_name:+": COMPUTE key="input_args);

   // have we been through this before?
   if (visited._indexin(input_args)) {
      // was it a failure or successful?
      if (visited:[input_args].return_type==null) {
         if (_chdebug) isay(depth, caller_name:+": SHORTCUT failure");
         return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      } else {
         rt=visited:[input_args];
         if (_chdebug) {
            tag_return_type_dump(rt, caller_name:+": SHORTCUT returns", depth);
         }
         return 0;
      }
   }

   // placeholder, showing that this result hasn't been computed,
   // but it is just about to be.
   visited:[input_args]=gnull_return_type;
   return 1;
}

/**
 * Update the "Locals" (local variables) category under the list members
 * dialog.  The list is updated incrementally, creating it if it wasn't
 * there before, and searching by prefix on the lastid and lastid prefix.
 *
 * @param editorctl_wid     window ID of editor control listing members
 * @param lastid            Identifier under the cursor
 * @param lastid_prefix     Prefix of identifier that is before the cursor
 * @param expected_type     expected return type (currently unused)
 * @param info_flags        bitset of VS_CODEHELPFLAG_*
 * @param otherinfo         used in some cases for extra information
 * @param tag_files         list of extension-specific tag files to search
 * @param class_name        name of class to look for identifiers in
 * @param this_var          "this" for C++, "self" for cobol, etc.
 * @param locals_optional   Delete category if there are no local variables?
 * @param only_for_funcs    Delete category if current context isn't a function?
 * @param pushtag_flags     bitset of VS_TAGFILTER_*
 * @param context_flags     bitset of VS_TAGCONTEXT_*
 * @param locals_max        maximum number of items to insert in category
 *
 * @return number of locals inserted, <0 on error.
 *
 * @see _CodeHelpListContextLocals
 * @see _CodeHelpBeginUpdate
 * @see _CodeHelpEndUpdate 
 *  
 * @deprecated Use tag_list_class_locals() in _[lang]_find_context_tags()
 */
int _CodeHelpUpdateLocals(int editorctl_wid,_str lastid,_str lastid_prefix,
                          _str expected_type,int info_flags,typeless otherinfo,
                          var tag_files, _str class_name='',_str this_var='',
                          boolean locals_optional=true,
                          boolean only_for_funcs=true,
                          int pushtag_flags=VS_TAGFILTER_ANYTHING,
                          int context_flags=VS_TAGCONTEXT_ANYTHING,
                          int locals_max=1000)
{
   return BT_FEATURE_IS_OBSOLETE_RC;
}

/**
 * @return Returns 'true' if the current identifier under the 
 *         cursor, designated by 'lastid' matches the given
 *         symbol name, depending on the matching options.
 * 
 * @param lastid           symbol under the cursor
 * @param tag_name         symbol to check against
 * @param exact_match      look for an exact match (otherwise prefix)
 * @param case_sensitive   look for a case-sensitive match
 */
boolean _CodeHelpDoesIdMatch(_str lastid, _str tag_name,
                             boolean exact_match=false,
                             boolean case_sensitive=true )
{
   // make sure 'tag_name' matches 'lastid', exactly
   if (exact_match) {
      return (lastid == tag_name || (!case_sensitive && strieq(lastid, tag_name)));
   }

   // check if 'tag_name' starts with 'lastid'
   ignoreCaseOpt := (case_sensitive? "" : "i");
   return (lastid == "" || pos(lastid, tag_name, 1, ignoreCaseOpt)==1);
}

/** 
 * Insert a symbol for the 'this' tag into the current match set 
 * if the current function is part of a class and it is not a 
 * static function. 
 * 
 * @param lastid           the symbol we are matching against
 * @param this_name        the language-specific 'this' symbol 
 * @param tag_files        tag files for the current language
 * @param filter_flags     VS_TAGFILTER_* filters
 * @param context_flags    VS_TAGCONTEXT_* filters
 * @param exact_match      look for an exact match to 'lastid' ?
 * @param case_sensitive   look for a case sensitive match ?
 * 
 * @return 'true' if the symbol matched and was inserted.
 */
boolean _CodeHelpMaybeInsertThis(_str lastid,
                                 _str this_name, 
                                 _str (&tag_files)[],
                                 int filter_flags,
                                 int context_flags,
                                 boolean exact_match,
                                 boolean case_sensitive,
                                 boolean allowStatic=false)
{
   // see if we need to insert current object variable (this, self, etc)
   if (context_flags & VS_TAGCONTEXT_ONLY_funcs) return false;
   if (!(context_flags & VS_TAGCONTEXT_ALLOW_locals)) return false;
   if (!(filter_flags & VS_TAGFILTER_ANYDATA)) return false;

   // if they did not give us a valid 'this' variable name
   if (this_name == '') return false;

   // get the current class and current package from the context
   cur_tag_name := cur_type_name := cur_class_name := "";
   cur_class_only := cur_package_name := "";
   cur_tag_flags := cur_type_id := 0;
   context_id := tag_get_current_context(cur_tag_name, cur_tag_flags,
                                         cur_type_name, cur_type_id,
                                         cur_class_name, cur_class_only,
                                         cur_package_name);
   if (context_id <= 0) return false;

   // make sure we have are in a class context
   if (cur_class_name == '') return false;

   // make sure we are not in a static function
   if (!allowStatic && (cur_tag_flags & VS_TAGFLAG_static)) return false;

   // not a function or proc, not a static method, in a class method
   if (!tag_tree_type_is_func(cur_type_name) || cur_type_name :== 'proto') {
      return false;
   }

   // make sure 'this_name' matches 'lastid'
   if (!_CodeHelpDoesIdMatch(lastid, this_name, exact_match, case_sensitive)) {
      return false;
   }

   // not really a class method, just a member of a package
   inner_name := outer_name := "";
   tag_split_class_name(cur_class_name, inner_name, outer_name);
   if (tag_check_for_package(inner_name, tag_files, true,  case_sensitive)) {
      return false;
   }

   // get the first line number of the current class
   cur_line_no := p_line;
   tag_get_detail2(VS_TAGDETAIL_context_line, context_id, cur_line_no);

   // add the item to the tree
   this_class_name := cur_class_name;
   this_class_name = stranslate(this_class_name, '.', '/');
   this_class_name = stranslate(this_class_name, '.', ':');
   tag_insert_match("", this_name, "lvar", p_buf_name, cur_line_no, "", 0,  this_class_name);
   return true;
}

/**
 * Update the "Members" (class members) category under the list members
 * dialog.  The list is updated incrementally, creating it if it wasn't
 * there before, and searching by prefix on the lastid and lastid prefix.
 *
 * @param editorctl_wid     window ID of editor control listing members
 * @param lastid            Identifier under the cursor
 * @param lastid_prefix     Prefix of identifier that is before the cursor
 * @param cur_context       current class / namespace / package scope
 * @param expected_type     expected return type (currently unused)
 * @param info_flags        bitset of VS_CODEHELPFLAG_*
 * @param otherinfo         used in some cases for extra information
 * @param tag_files         list of extension-specific tag files to search
 * @param members_optional  Delete category if there are no class members?
 * @param pushtag_flags     bitset of VS_TAGFILTER_*
 * @param context_flags     bitset of VS_TAGCONTEXT_*
 * @param members_max       maximum number of items to insert in category
 *
 * @return number of members inserted, <0 on error.
 *
 * @see _CodeHelpListContextMembers
 * @see _CodeHelpBeginUpdate
 * @see _CodeHelpEndUpdate 
 *  
 * @deprecated Use tag_list_symbols_in_context() in _[lang]_find_context_tags() 
 */
int _CodeHelpUpdateMembersInClass(int editorctl_wid,
                                  _str lastid,_str lastid_prefix,_str cur_context,
                                  _str expected_type,int info_flags,typeless otherinfo,
                                  var tag_files, boolean members_optional=true,
                                  int pushtag_flags=VS_TAGFILTER_ANYTHING,
                                  int context_flags=VS_TAGCONTEXT_ANYTHING,
                                  int members_max=1000)
{
   return BT_FEATURE_IS_OBSOLETE_RC;
}

/**
 * Update the "Members" (class members) category under the list members
 * dialog.  The list is updated incrementally, creating it if it wasn't
 * there before, and searching by prefix on the lastid and lastid prefix.
 *
 * @param editorctl_wid     window ID of editor control listing members
 * @param lastid            Identifier under the cursor
 * @param lastid_prefix     Prefix of identifier that is before the cursor
 * @param expected_type     expected return type (currently unused)
 * @param info_flags        bitset of VS_CODEHELPFLAG_*
 * @param otherinfo         used in some cases for extra information
 * @param tag_files         list of extension-specific tag files to search
 * @param members_optional  Delete category if there are no class members?
 * @param pushtag_flags     bitset of VS_TAGFILTER_*
 * @param context_flags     bitset of VS_TAGCONTEXT_*
 * @param members_max       maximum number of items to insert in category
 *
 * @return number of members inserted, <0 on error.
 *
 * @see _CodeHelpListContextMembers
 * @see _CodeHelpBeginUpdate
 * @see _CodeHelpEndUpdate 
 *  
 * @deprecated Use tag_list_symbols_in_context() in _[lang]_find_context_tags() 
 */
int _CodeHelpUpdateMembers(int editorctl_wid,_str lastid,_str lastid_prefix,
                           _str expected_type,int info_flags,typeless otherinfo,
                           var tag_files, boolean members_optional=true,
                           int pushtag_flags=VS_TAGFILTER_ANYTHING,
                           int context_flags=VS_TAGCONTEXT_ANYTHING,
                           int members_max=1000)
{
   return BT_FEATURE_IS_OBSOLETE_RC;
}

/**
 * Update the "Current Buffer" (globals in this file) category under
 * the list members dialog.  The list is updated incrementally, creating
 * it if it wasn't there before, and searching by prefix on the lastid
 * and lastid prefix.
 *
 * @param editorctl_wid     window ID of editor control listing members
 * @param lastid            Identifier under the cursor
 * @param lastid_prefix     Prefix of identifier that is before the cursor
 * @param expected_type     expected return type (currently unused)
 * @param info_flags        bitset of VS_CODEHELPFLAG_*
 * @param otherinfo         used in some cases for extra information
 * @param tag_files         list of extension-specific tag files to search
 * @param symbols_optional  Delete category if there are no class members?
 * @param pushtag_flags     bitset of VS_TAGFILTER_*
 * @param context_flags     bitset of VS_TAGCONTEXT_*
 * @param symbols_max       maximum number of items to insert in category
 *
 * @return number of globals inserted, <0 on error.
 *
 * @see _CodeHelpListContextGlobals
 * @see _CodeHelpBeginUpdate
 * @see _CodeHelpEndUpdate 
 *  
 * @deprecated Use tag_list_context_globals() in _[lang]_find_context_tags() 
 */
int _CodeHelpUpdateBuffer(int editorctl_wid,_str lastid,_str lastid_prefix,
                          _str expected_type,int info_flags,typeless otherinfo,
                          var tag_files, boolean symbols_optional=false,
                          int pushtag_flags=VS_TAGFILTER_ANYTHING,
                          int context_flags=VS_TAGCONTEXT_ANYTHING,
                          int symbols_max=1000)
{
   return BT_FEATURE_IS_OBSOLETE_RC;
}

/**
 * Update the "Globals" (globals found in tag files) category under
 * the list members dialog.  The list is updated incrementally, creating
 * it if it wasn't there before, and searching by prefix on the lastid
 * and lastid prefix.
 *
 * @param editorctl_wid     window ID of editor control listing members
 * @param lastid            Identifier under the cursor
 * @param lastid_prefix     Prefix of identifier that is before the cursor
 * @param expected_type     expected return type (currently unused)
 * @param info_flags        bitset of VS_CODEHELPFLAG_*
 * @param otherinfo         used in some cases for extra information
 * @param tag_files         list of extension-specific tag files to search
 * @param globals_optional  Delete category if there are no class members?
 * @param pushtag_flags     bitset of VS_TAGFILTER_*
 * @param context_flags     bitset of VS_TAGCONTEXT_*
 * @param globals_max       maximum number of items to insert in category
 *
 * @return number of globals inserted, <0 on error.
 *
 * @see _CodeHelpListContextGlobals
 * @see _CodeHelpBeginUpdate
 * @see _CodeHelpEndUpdate 
 *  
 * @deprecated Use tag_list_context_globals() in _[lang]_find_context_tags() 
 */
int _CodeHelpUpdateGlobals(int editorctl_wid,_str lastid,_str lastid_prefix,
                           _str expected_type,int info_flags,typeless otherinfo,
                           var tag_files, boolean globals_optional=false,
                           int pushtag_flags=VS_TAGFILTER_ANYTHING,
                           int context_flags=VS_TAGCONTEXT_ONLY_non_static,
                           int globals_max=1000)
{
   return BT_FEATURE_IS_OBSOLETE_RC;
}

/**
 * Update the "Imports" (tags imported into this context) category under
 * the list members dialog.  The list is updated incrementally, creating
 * it if it wasn't there before, and searching by prefix on the lastid
 * and lastid prefix.
 *
 * @param editorctl_wid     window ID of editor control listing members
 * @param lastid            Identifier under the cursor
 * @param lastid_prefix     Prefix of identifier that is before the cursor
 * @param expected_type     expected return type (currently unused)
 * @param info_flags        bitset of VS_CODEHELPFLAG_*
 * @param otherinfo         used in some cases for extra information
 * @param tag_files         list of extension-specific tag files to search
 * @param imports_optional  Delete category if there are no class members?
 * @param pushtag_flags     bitset of VS_TAGFILTER_*
 * @param context_flags     bitset of VS_TAGCONTEXT_*
 * @param imports_max       maximum number of items to insert in category
 *
 * @return number of globals inserted, <0 on error.
 *
 * @see _CodeHelpListContextImports
 * @see _CodeHelpBeginUpdate
 * @see _CodeHelpEndUpdate
 *  
 * @deprecated Use tag_list_context_imports() in _[lang]_find_context_tags() 
 */
int _CodeHelpUpdateImports(int editorctl_wid,_str lastid,_str lastid_prefix,
                           _str expected_type,int info_flags,typeless otherinfo,
                           var tag_files, boolean imports_optional=false,
                           int pushtag_flags=VS_TAGFILTER_ANYTHING,
                           int context_flags=VS_TAGCONTEXT_ANYTHING,
                           int imports_max=1000)
{
   return BT_FEATURE_IS_OBSOLETE_RC;
}

/**
 * Checks if the given category needs to be updated or not.
 * Must be used in conjunction with _CodeHelpEndUpdate(), below.
 * The current object needs to be the tree control.
 *
 * @param ctg_caption       tag category caption to find, if '', just use ctg_root as is
 * @param lastid_prefix     tag prefix to search for (used to compare against last time)
 * @param ctg_prefix        (reference) last prefix used when updating category
 * @param ctg_root          (reference) result is root index of category
 * @param ctg_count         (reference) number of items found
 * @param ctg_maximum       maximum number of items allowed
 *
 * @return boolean          'true' indicates update is needed, 'false' means up to date.
 *
 * @example This function is used in the following pattern:
 * <PRE>
 *     static _str ctg_prefix;
 *     int ctg_count,ctg_root=0;
 *
 *     if (_CodeHelpBeginUpdate(ctg_caption,   // maybe VSCODEHELP_TITLE_*
 *                              lastid_prefix, // from _*_get_expression_info
 *                              ctg_prefix,    // static, initially empty string
 *                              ctg_root,      // may be uninitialized if ctg_caption!=''
 *                              ctg_count,     // may be uninitialized
 *                              ctg_maximum    // maybe VSCODEHELP_MAX*
 *                             )) {
 *         // insert tags for this category under
 *         // ctg_root, updating ctg_count
 *         ...
 *         _CodeHelpEndUpdate(ctg_root,        // same as above
 *                            ctg_prefix,      // same as above
 *                            ctg_count,       // same as above
 *                            ctg_maximum,     // same as above
 *                            true_or_false    // category optional?
 *                           );
 *     }
 * </PRE>
 *
 * @see _CodeHelpEndUpdate 
 *  
 * @deprecated This function is no longer needed anywhere, 
 *             since all this work is taken care of in auto-complete. 
 */
boolean _CodeHelpBeginUpdate(_str ctg_caption, _str lastid_prefix,
                             _str &ctg_prefix, int &ctg_root, 
                             int &ctg_count, int ctg_maximum=1000)
{
   return true;
}

/**
 * Finishes updating the current category.  If a category is optional,
 * and the number of items inserted under it is zero, delete it.
 * Must be used in conjunction with _CodeHelpBeginUpdate(), above.
 * The current object needs to be the tree control.
 *
 * @param ctg_root          (reference) tree index of category
 * @param ctg_prefix        (reference) last search prefix used updating list
 * @param ctg_count         number of items found
 * @param ctg_maximum       maximum number of items allowed
 * @param ctg_optional      is this category optional (true) or required (false, default)
 *
 * @return nothing
 * @see _CodeHelpBeginUpdate
 *  
 * @deprecated This function is no longer needed anywhere, 
 *             since all this work is taken care of in auto-complete. 
 */
void _CodeHelpEndUpdate(int &ctg_root, _str &ctg_prefix, 
                        int ctg_count, int ctg_maximum=1000,
                        boolean ctg_optional=false)
{
}

/**
 * List tags matching the given reference from an &amp;see
 * JavaDoc tag.  Refer to the JavaDoc specification
 * for details about the searching done here.
 *
 * @param class_name   Class name to search for matches in
 * @param method       Method to search for, within class or current class
 * @param arguments    Signature of method to search for
 * @param filename     Filename to where reference came from
 * @param linenum      Line number that reference came from
 * @param curclassname
 * @param case_sensitive
 *
 * @return 0 on success, results are in the match set.
 */
int _CodeHelpListHRefs(_str class_name,_str method,_str arguments,
                       _str filename, int linenum,_str curclassname,
                       boolean case_sensitive=false)
{
   //say("_CodeHelpListHRefs: class_name="class_name" method="method" args="arguments" file="filename" line="linenum" curclass="curclassname);
   if (class_name=='') {
      class_name=curclassname;
   }
   _str package_name='';
   _str search_class = class_name;
   //int class_pos = lastpos(':v',class_name,MAXINT,'r');
   word_chars := _clex_identifier_chars();
   int class_pos = lastpos('['word_chars']#',class_name,MAXINT,'r');
   if (class_pos > 1) {
      package_name = substr(class_name,1,class_pos-1);
      while (pos(last_char(package_name),".:'")) {
         package_name = substr(package_name,1,length(package_name)-1);
      }
      class_name   = substr(class_name,class_pos);
      if (package_name != '') {
         search_class = package_name :+ VS_TAGSEPARATOR_package :+ class_name;
      }
   }

   _str search_for = method;
   if (method == '') {
      search_for   = class_name;
      search_class = package_name;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   //say("_CodeHelpListHRefs: class_name="class_name" package="package_name);
   _str lang=p_LangId;
   if (lang=='xmldoc') lang='cs';
   typeless tag_files = tags_filenamea(lang);
   _str qualified_class='';
   tag_qualify_symbol_name(qualified_class,class_name,package_name,filename,tag_files,case_sensitive);
   //say("_CodeHelpListHRefs: qualified="qualified_class);
   if (qualified_class!='') {
      if (method=='') {
         _str dummy='';
         tag_split_class_name(qualified_class,dummy,search_class);
      } else {
         search_class=qualified_class;
      }
   }
   //say("_CodeHelpListHRefs: search_for="search_for" search_class="search_class);

   int status=0;
   int num_matches=0;
   tag_clear_matches();
   if (file_eq(filename,p_buf_name)) {
      contextId := tag_find_context_iterator(search_for,true,case_sensitive,false,search_class);
      while (contextId > 0) {
         tag_insert_match_fast(VS_TAGMATCH_context,contextId);
         contextId = tag_next_context_iterator(search_for,contextId,true,case_sensitive,false,search_class);
      }
   }

   int i=0;
   _str tag_filename = next_tag_filea(tag_files,i,false,true);
   while (tag_filename != '') {

      status = tag_find_equal(search_for,case_sensitive,search_class);
      while (!status) {
         _str from_file='';
         tag_get_detail(VS_TAGDETAIL_file_name,from_file);
         if (!file_eq(from_file,p_buf_name) || !file_eq(filename,p_buf_name)) {
            tag_insert_match_fast(VS_TAGMATCH_tag,0);
         }
         status = tag_next_equal(case_sensitive,search_class);
      }
      tag_reset_find_tag();

      tag_filename = next_tag_filea(tag_files,i,false,true);
   }

   if (tag_get_num_of_matches()==0 && case_sensitive) {
      return _CodeHelpListHRefs(class_name,method,arguments,filename,linenum,curclassname,false);
   }
   if (tag_get_num_of_matches()==0 && curclassname!='' && class_name=='') {
      return _CodeHelpListHRefs(class_name,method,arguments,filename,linenum,'',case_sensitive);
   }
   return (tag_get_num_of_matches()>0)? 0:VSCODEHELPRC_NO_SYMBOLS_FOUND;
}

/**
 * List globals in the current buffer (context)
 * Current object must be editor control
 *
 * @param treewid         window ID of tree control to insert into
 * @param tree_index      index in tree to insert items under
 * @param check_context   check locals and current context?
 * @param tag_files       array of tag files to search
 * @param lastid          name to search for
 * @param lastid_prefix   prefix of name before cursor
 * @param pushtag_flags   VS_TAGFILTER_*
 * @param context_flags   VS_TAGCONTEXT_*
 * @param num_matches     number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success.
 *
 * @see _CodeHelpListContextMembers
 * @see _CodeHelpListContextImports
 * @see _CodeHelpListContextLocals 
 *  
 * @deprecated Use tag_list_context_globals() in _[lang]_find_context_tags() 
 */
void _CodeHelpListContextGlobals(int treewid, int tree_index,
                                 boolean check_context,typeless tag_files,
                                 _str lastid, _str lastid_prefix,
                                 int pushtag_flags, int context_flags,
                                 int &num_matches, int max_matches=1000,
                                 boolean exact_match=false)
{
}

/**
 * List members of the given class
 * Current object must be editor control
 *
 * @param treewid         window ID of tree control to insert into
 * @param tree_index      index in tree to insert items under
 * @param tag_files       array of tag files to search
 * @param lastid          name to search for
 * @param lastid_prefix   prefix of name before cursor
 * @param cur_context     current class / namespace / package scope
 * @param pushtag_flags   VS_TAGFILTER_*
 * @param context_flags   VS_TAGCONTEXT_*
 * @param num_matches     number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success.
 *  
 * @deprecated Use tag_list_symbols_in_context() in _[lang]_find_context_tags() 
 */
void _CodeHelpListContextMembersInClass(int treewid, int tree_index,typeless tag_files,
                                        _str lastid, _str lastid_prefix, _str cur_context,
                                        int pushtag_flags, int context_flags,
                                        int &num_matches, int max_matches=1000)
{
}

/**
 * List members of the given class
 * Current object must be editor control
 *
 * @param treewid         window ID of tree control to insert into
 * @param tree_index      index in tree to insert items under
 * @param tag_files       array of tag files to search
 * @param lastid          name to search for
 * @param lastid_prefix   prefix of name before cursor
 * @param pushtag_flags   VS_TAGFILTER_*
 * @param context_flags   VS_TAGCONTEXT_*
 * @param num_matches     number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success.
 *  
 * @deprecated Use tag_list_symbols_in_context() in _[lang]_find_context_tags() 
 */
void _CodeHelpListContextMembers(int treewid, int tree_index,typeless tag_files,
                                 _str lastid, _str lastid_prefix,
                                 int pushtag_flags, int context_flags,
                                 int &num_matches, int max_matches=1000)
{
}

/**
 * List symbols imported into the current buffer (context)
 * Current object must be editor control
 * <p> 
 * For synchronization, threads should perform a 
 * tag_lock_context(false) and tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param treewid         window ID of tree control to insert into
 * @param tree_index      index in tree to insert items under
 * @param tag_files       array of tag files to search
 * @param lastid          name to search for
 * @param lastid_prefix   prefix of name before cursor
 * @param pushtag_flags   VS_TAGFILTER_*
 * @param context_flags   VS_TAGCONTEXT_*
 * @param num_matches     number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success. 
 *  
 * @deprecated Use tag_list_context_imports() in _[lang]_find_context_tags() 
 */
void _CodeHelpListContextImports(int treewid, int tree_index, typeless tag_files,
                                 _str lastid, _str lastid_prefix,
                                 int pushtag_flags, int context_flags,
                                 int &num_matches, int max_matches=1000)
{
}

/**
 * List locals in the current function context
 * Current object must be editor control
 *
 * @param treewid         window ID of tree control to insert into
 * @param tree_index      index in tree to insert items under
 * @param tag_files       array of tag files to search
 * @param lastid          name to search for
 * @param lastid_prefix   prefix of name before cursor
 * @param search_class    class to search for local variables in
 * @param pushtag_flags   VS_TAGFILTER_*
 * @param context_flags   VS_TAGCONTEXT_*
 * @param num_matches     number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success.
 *  
 * @deprecated Use tag_list_class_locals() in _[lang]_find_context_tags() 
 */
void _CodeHelpListContextLocals(int treewid, int tree_index, typeless tag_files,
                                _str lastid, _str lastid_prefix, _str search_class,
                                int pushtag_flags, int context_flags,
                                int &num_matches, int max_matches=1000)
{
}

/**
 * List labels in the current function context
 * Current object must be editor control
 *
 * @param treewid         window ID of tree control to insert into
 * @param tree_index      index in tree to insert items under 
 * @param label_name      name of label to search for 
 * @param cur_class_name  name of current class (to search)
 * @param num_matches     number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success.
 */
void _CodeHelpListLabels(int treewid, int tree_index, 
                         _str label_name, _str cur_class_name,
                         int &num_matches, int max_matches,
                         boolean exact_match=false,
                         boolean case_sensitive=true,
                         typeless &visited=null, int depth=0)
{
   //say("_CodeHelpListLabels()");
   _UpdateLocals(true,true);
   tag_list_class_locals(treewid,tree_index,null,
                         label_name, cur_class_name,
                         VS_TAGFILTER_LABEL,
                         VS_TAGCONTEXT_ANYTHING,
                         num_matches,max_matches,
                         exact_match, case_sensitive);

   // get the current tag type
   cur_tag_type := "";
   context_id := tag_current_context();
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, cur_tag_type);
   }

   // special case for package / program / module initialization code
   if (!tag_tree_type_is_func(cur_tag_type) || cur_tag_type=='') {
      tag_list_class_context(treewid,tree_index,null,
                             label_name, cur_class_name,
                             VS_TAGFILTER_LABEL,
                             VS_TAGCONTEXT_ANYTHING,
                             num_matches,max_matches,
                             exact_match, case_sensitive);
   }
}

/**
 * List any symbols in the matching the identifier or identifier prefix
 * Current object must be editor control
 *
 * @param treewid         window ID of tree control to insert into
 * @param tree_index      index in tree to insert items under
 * @param tag_files       array of tag files to search
 * @param lastid          name to search for
 * @param lastid_prefix   prefix of name before cursor
 * @param pushtag_flags   VS_TAGFILTER_*
 * @param context_flags   VS_TAGCONTEXT_*
 * @param num_matches     number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success. 
 *  
 * @deprecated Use tag_list_any_symbols() in _[lang]_find_context_tags() 
 */
void _CodeHelpListAnySymbols(int treewid, int tree_index, typeless tag_files,
                             _str lastid, _str lastid_prefix,
                             int pushtag_flags, int context_flags,
                             int &num_matches, int max_matches=1000)
{
}

/**
 * List container type tags (classes, structs, interfaces, groups)
 * containing the given symbol name, either directly or indirectly.
 *
 * @param treewid         window ID of tree control to insert into
 * @param tree_index      index in tree to insert items under
 * @param tag_files       array of tag files to search
 * @param member_name     name of tag to search for classes containing
 * @param cur_class_name  current class name
 * @param pushtag_flags   VS_TAGFILTER_*
 * @param context_flags   VS_TAGCONTEXT_*
 * @param num_matches     number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success.
 */
void _CodeHelpListClassesHaving(int treewid, int tree_index, typeless tag_files,
                                _str member_name, _str cur_class_name,
                                int pushtag_flags, int context_flags,
                                int &num_matches, int max_matches,
                                boolean exact_match=false,
                                boolean case_sensitive=false,
                                typeless &visited=null, int depth=0)
{
   tag_push_matches();
   int num_classes=0;

   tag_list_symbols_in_context( member_name, "",
                                0, 0, tag_files, "",
                                num_matches, max_matches, 
                                pushtag_flags, context_flags, 
                                exact_match, case_sensitive, 
                                visited, depth );

   // save the class matches to the array
   VS_TAG_BROWSE_INFO cm;
   VS_TAG_BROWSE_INFO classes_found[];
   classes_found._makeempty();
   int i,n=tag_get_num_of_matches();
   for (i=1; i<=n; i++) {
      tag_get_match_info(i, cm);
      classes_found[classes_found._length()] = cm;
   }
   tag_pop_matches();

   // for each item in the array, check if it has a member with
   // the matching 'member_name'
   for (i=0; i<classes_found._length(); i++) {
      cm = classes_found[i];
      tag_push_matches();
      int num_members=0;
      _str class_name=cm.member_name;
      if (cm.class_name!='') {
         class_name=cm.class_name:+VS_TAGSEPARATOR_class:+cm.member_name;
         tag_list_in_class(member_name,class_name,0,0,tag_files,
                           num_members,1,
                           VS_TAGFILTER_ANYTHING,VS_TAGCONTEXT_ANYTHING,
                           true, false, null, null, visited, depth);
         class_name=cm.class_name:+VS_TAGSEPARATOR_package:+cm.member_name;
      }
      if (!num_members) {
         tag_list_in_class(member_name,class_name,0,0,tag_files,
                           num_members,1,
                           VS_TAGFILTER_ANYTHING,VS_TAGCONTEXT_ANYTHING,
                           true, false, null, null, visited, depth);
      }
      tag_pop_matches();
      if (num_members > 0) {
         _str local_sig = cm.return_type;
         if (cm.arguments!='') {
            strappend(local_sig, VS_TAGSEPARATOR_args:+cm.arguments);
         }
         if (cm.exceptions!='') {
            strappend(local_sig, VS_TAGSEPARATOR_throws:+cm.exceptions);
         }
         int k=0;
         if (treewid) {
            k=tag_tree_insert_tag(treewid,tree_index,0,0,0,
                                  cm.member_name, cm.type_name,
                                  cm.file_name, cm.line_no,
                                  '', cm.flags, '', cm.line_no);
         } else {
            k=tag_insert_match2(cm.tag_database,cm.member_name,
                                cm.type_name, cm.file_name,
                                cm.line_no, cm.seekpos,
                                cm.scope_line_no, cm.scope_seekpos,
                                cm.end_line_no, cm.end_seekpos,
                                cm.class_name, cm.flags, local_sig);
         }
         if (k < 0 || ++num_matches >= max_matches) {
            break;
         }
      }
   }
}

/**
 * List keywords from the current language, extracted from the
 * keyword list in the color coding setup.
 * Current object must be editor control.
 *
 * @param treewid         window ID of tree control to insert into
 * @param tree_index      index in tree to insert items under
 * @param pic_index       index of bitmap to display
 * @param lastid          name to search for
 * @param lastid_prefix   prefix of name before cursor
 * @param num_matches     number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success. 
 *  
 * @deprecated This functionality is made obsolete because 
 *             auto-complete lists keywords that match the
 *             word under the cursor. 
 */
int _CodeHelpListKeywords(int treewid, int tree_index, int pic_index,
                          _str lastid, _str lastid_prefix,
                          int &num_matches, int max_matches=1000)
{
   return BT_FEATURE_IS_OBSOLETE_RC;
}

/**
 * List preprocessing keywords from the current language,
 * extracted from the keyword list in the color coding setup.
 * Current object must be editor control.
 *
 * @param treewid         window ID of tree control to insert into
 * @param tree_index      index in tree to insert items under
 * @param pic_index       index of bitmap to display
 * @param prefixexp       usually '#' for C preprocessing
 * @param lastid          name to search for
 * @param lastid_prefix   prefix of name before cursor
 * @param num_matches     number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success.
 *  
 * @deprecated This functionality is made obsolete because 
 *             auto-complete lists keywords that match the
 *             word under the cursor, including preprocessing.
 */
int _CodeHelpListPPKeywords(int treewid, int tree_index, int pic_index,
                            _str prefixexp, _str lastid, _str lastid_prefix,
                            int &num_matches, int max_matches=1000)
{
   return BT_FEATURE_IS_OBSOLETE_RC;
}

/**
 * List packages precisely matching the given prefix expression and
 * lastid_prefix.  Insert the packages into the given tree control,
 * sort, and trim off the leading prefix and remove duplicates.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 * 
 * @param treewid         window ID of tree control to insert into
 * @param tree_index      index in tree to insert items under
 * @param editorctl_wid     window ID of editor control listing members
 * @param tag_files         list of extension-specific tag files to search
 * @param prefixexp       usually '#' for C preprocessing
 * @param lastid_prefix   prefix of name before cursor
 * @param num_matches     number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 'true' if the prefixexp was a package, 'false' otherwise
 */
boolean _CodeHelpListPackages(int treewid, int tree_index,
                              int editorctl_wid, typeless tag_files,
                              _str prefixexp, _str lastid_prefix,
                              int &num_matches, int max_matches,
                              boolean exact_match = false,
                              boolean case_sensitive = true)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // maybe prefix expression is a package name or prefix of package name
   boolean is_package=false;
   if (tag_check_for_package(prefixexp:+lastid_prefix, tag_files,
                             exact_match, case_sensitive)) {
      is_package=true;
      tag_push_matches();
      num_candidates := 0;
      editorctl_wid.tag_list_context_packages(treewid, tree_index, 
                                              prefixexp, tag_files,
                                              num_candidates, max_matches,
                                              exact_match, case_sensitive);
      VS_TAG_BROWSE_INFO allPackages[];
      tag_get_all_matches(allPackages);
      tag_pop_matches();
      if (treewid != 0) {
         treewid._TreeSortCaption(tree_index, 'u');
         num_matches = 0;
         int index = treewid._TreeGetFirstChildIndex(tree_index);
         int start = length(prefixexp)+1;
         while (index > 0) {
            _str caption = treewid._TreeGetCaption(index);
            if (pos(prefixexp, caption)!=1 || length(caption)<=start) {
               int next_index = treewid._TreeGetNextSiblingIndex(index);
               treewid._TreeDelete(index);
               index = next_index;
               continue;
            }
            caption = substr(caption, start);
            treewid._TreeSetCaption(index, caption);
            index = treewid._TreeGetNextSiblingIndex(index);
            num_matches++;
         }
      } else {
         start := length(prefixexp)+1;
         VS_TAG_BROWSE_INFO cm;
         foreach (cm in allPackages) {
            caption := cm.member_name;
            if (pos(prefixexp:+lastid_prefix, cm.member_name)==1 && length(cm.member_name) >= start) {
               cm.member_name = substr(cm.member_name, start);
               tag_insert_match_info(cm);
               num_matches++;
            }
         }
      }
   }
   return is_package;
}

/**
 * Context Tagging&reg; hook function for filling in the member help dialog.
 * Based on the current prefix expression, last identifier and other
 * information about the current context, fills in the tree control
 * (which is the current window upon entry) with the set of symbols
 * (possibly divided into categories) that could be used in that
 * context.  For example, the list of members of a class (FooBar::&lt;here&gt;)
 * <p>
 * On entry, the tree is either empty, indicating that this is the
 * first time in this function and the list needs to be created.
 * Otherwise, the tree already contains items and needs to be updated
 * incrementally (because lastid_prefix and lastid changing).
 * <p>
 * This version is the extension-non-specific Context Tagging&reg; hook function.
 * It is called for any extension that does not implement an extension
 * specific list members hook function (_[ext]_insert_context_tags). 
 * <p> 
 * This function does not reqire synchronization code for the current context 
 * because that lock is acquired by it's calling function. 
 *
 * @param errorArgs         array of strings for error message arguments
 *                          refer to codehelp.e VSCODEHELPRC_*
 * @param editorctl_wid     window ID of editor control Context Tagging&reg;
 *                          was invoked from.
 * @param prefixexp         prefix of expression (from _[ext]_get_expression_info
 * @param lastid            last identifier in expression
 * @param lastid_prefix     prefix of lastid to the left of the cursor
 * @param lastidstart_offset seek position of last identifier
 * @param expected_type     expected return type (not implemented fully)
 * @param info_flags        bitset of VS_CODEHELPFLAG_*
 * @param otherinfo         used in some cases for extra information
 *                          tied to info_flags
 *
 * @return 0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 *
 * @see _do_list_members
 * @see _CodeHelpUpdateLocals
 * @see _CodeHelpUpdateBuffer
 * @see _CodeHelpUpdateGlobals 
 *  
 * @deprecated use _do_default_find_context_tags() with Auto-Complete 
 */
int _do_default_insert_context_tags(_str (&errorArgs)[],
                                    int editorctl_wid,
                                    _str prefixexp, _str lastid, 
                                    _str lastid_prefix, int lastidstart_offset,
                                    _str expected_type, int info_flags, typeless otherinfo,
                                    VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   return BT_FEATURE_IS_OBSOLETE_RC;
}

/**
 * Context Tagging&reg; hook function for retrieving the information about
 * each function possibly matching the current function call that
 * function help has been requested on.
 *
 * If there is no help for the first function, a non-zero value
 * is returned and message is usually displayed.
 *
 * If the end of the statement is found, a non-zero value is
 * returned.  This happens when a user to the closing brace
 * to the outer most function caller or does some weird
 * paste of statements.
 *
 * If there is no help for a function and it is not the first
 * function, FunctionHelp_list is filled in with a message
 * <PRE>
 *     FunctionHelp_list._makeempty();
 *     FunctionHelp_list[0].proctype=message;
 *     FunctionHelp_list[0].argstart[0]=1;
 *     FunctionHelp_list[0].arglength[0]=0;
 *     FunctionHelp_list[0].return_type=0;
 * </PRE>
 *
 * This is the extension-non-specific hook function for getting
 * function help.  This function could be used to supply generic function
 * help for languages that are like "C", but do not implement a
 * specific _[ext]_fcthelp_get.
 *
 * NOTE: THIS FUNCTION IS NOT USED.
 *
 * @param errorArgs                 array of strings for error message arguments
 *                                  refer to codehelp.e VSCODEHELPRC_*
 * @param FunctionHelp_list         Structure is initially empty.
 *                                  FunctionHelp_list._isempty()==true
 *                                  You may set argument lengths to 0.
 *                                  See VSAUTOCODE_ARG_INFO structure in slick.sh.
 * @param FunctionHelp_list_changed (reference)Indicates whether the data in
 *                                  FunctionHelp_list has been changed.
 *                                  Also indicates whether current
 *                                  parameter being edited has changed.
 * @param FunctionHelp_cursor_x     (reference) Indicates the cursor x position
 *                                  in pixels relative to the edit window
 *                                  where to display the argument help.
 * @param FunctionHelp_HelpWord     Keyword to supply to help system
 * @param FunctionNameStartOffset   The text between this point and
 *                                  ArgumentEndOffset needs to be parsed
 *                                  to determine the new argument help.
 * @param flags                     function help flags (from fcthelp_get_start)
 *
 * @return
 *   Returns 0 if we want to continue with function argument
 *   help.  Otherwise a non-zero value is returned and a
 *   message is usually displayed.
 *   <PRE>
 *      1   Not a valid context
 *      2-9  (not implemented yet)
 *      10   Context expression too complex
 *      11   No help found for current function
 *      12   Unable to evaluate context expression
 *   </PRE>
 *
 * @see _do_function_help
 * @see _do_default_fcthelp_get_start
 * @see _c_fcthelp_get
 */
int _do_default_fcthelp_get(  _str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      boolean &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return(_c_fcthelp_get(errorArgs,
                         FunctionHelp_list,FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth));
}

/**
 * Context Tagging&reg; hook function for function help.  Finds the start
 * location of a function call and the function name.
 *
 * This is the extension-non-specific hook function for getting
 * function help.  This function could be used to supply generic function
 * help for languages that are like "C", but do not implement a
 * specific _[ext]_fcthelp_get.
 *
 * NOTE: THIS FUNCTION IS NOT USED.
 *
 * @param errorArgs                array of strings for error message arguments
 *                                 refer to codehelp.e VSCODEHELPRC_*
 * @param OperatorTyped            When true, user has just typed last
 *                                 character of operator.
 *                                 Example: p-> &lt;Cursor Here&gt;
 *                                 This should be false if cursorInsideArgumentList is true.
 * @param cursorInsideArgumentList When true, user requested function help
 *                                 when the cursor was inside an argument list.
 *                                 Example: MessageBox(...,&lt;Cursor Here&gt;...)
 *                                 Here we give help on MessageBox
 * @param FunctionNameOffset       (reference) Offset to start of function name.
 * @param ArgumentStartOffset      (reference) Offset to start of first argument
 * @param flags                    (reference) function help flags
 *
 * @return 0    Successful
 * <PRE>
 *   VSCODEHELPRC_CONTEXT_NOT_VALID
 *   VSCODEHELPRC_NOT_IN_ARGUMENT_LIST
 *   VSCODEHELPRC_NO_HELP_FOR_FUNCTION
 * </PRE>
 *
 * @see _do_function_help
 * @see _do_default_fcthelp_get
 * @see _c_fcthelp_get_start
 */
int _do_default_fcthelp_get_start(_str (&errorArgs)[],
                            boolean OperatorTyped,
                            boolean cursorInsideArgumentList,
                            int &FunctionNameOffset,
                            int &ArgumentStartOffset,
                            int &flags
                           )
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,
                               cursorInsideArgumentList,
                               FunctionNameOffset,
                               ArgumentStartOffset,flags));
}

int _do_extension_get_idexp_info(_str (&errorArgs)[],
                                 boolean PossibleOperator,
                                 _str &prefixexp,
                                 _str &lastid,
                                 int &lastidstart_col,
                                 int &lastidstart_offset,
                                 int &info_flags,
                                 typeless &otherinfo,
                                 VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0
                                )
{
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);

   fast_get_index := _FindLanguageCallbackIndex('vs%s_get_expression_info');
   get_index := _FindLanguageCallbackIndex('_%s_get_expression_info');
   if (!fast_get_index && !get_index && upcase(substr(p_lexer_name,1,3))=='XML') {
      get_index=find_index('_html_get_expression_info',PROC_TYPE);
   }

   int status = 0;
   if (fast_get_index != 0) {
      _UpdateContext(true, false, VS_UPDATEFLAG_context|VS_UPDATEFLAG_tokens);
      status=call_index(PossibleOperator, _QROffset(), idexp_info, fast_get_index);
   } else if (get_index != 0) {
      status=call_index(PossibleOperator, idexp_info, visited, depth, get_index);
   } else {
      // Could not find new version, try old.
      get_index = _FindLanguageCallbackIndex('_%s_get_idexp');
      if(get_index != 0) {
         // Call old version
         status=call_index(idexp_info.errorArgs, PossibleOperator, idexp_info.prefixexp, idexp_info.lastid, 
                  idexp_info.lastidstart_col, idexp_info.lastidstart_offset, 
                  idexp_info.info_flags, idexp_info.otherinfo, idexp_info.prefixexpstart_offset, get_index);
      } else {
         // Try default version
         status=_do_default_get_expression_info(PossibleOperator, idexp_info, visited, depth);
      } 
   }

   errorArgs               = idexp_info.errorArgs;
   prefixexp               = idexp_info.prefixexp;
   lastid                  = idexp_info.lastid;
   lastidstart_col         = idexp_info.lastidstart_col;
   lastidstart_offset      = idexp_info.lastidstart_offset;
   info_flags              = idexp_info.info_flags;
   otherinfo               = idexp_info.otherinfo;
   return(status);
}

/**
 * @deprecated 
 */
int _do_default_get_idexp(_str (&errorArgs)[],
                       boolean PossibleOperator,
                       _str &prefixexp,
                       _str &lastid,
                       int &lastidstart_col,
                       int &lastidstart_offset,
                       int &info_flags,
                       typeless &otherinfo,
                       VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   int status = _do_default_get_expression_info(PossibleOperator, idexp_info, visited, depth);
   errorArgs               = idexp_info.errorArgs;
   prefixexp               = idexp_info.prefixexp;
   lastid                  = idexp_info.lastid;
   lastidstart_col         = idexp_info.lastidstart_col;
   lastidstart_offset      = idexp_info.lastidstart_offset;
   info_flags              = idexp_info.info_flags;
   otherinfo               = idexp_info.otherinfo;

   return status;
}

int _do_default_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                                    VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (_in_comment() || !_istagging_supported()) {
      return(VSCODEHELPRC_CONTEXT_NOT_VALID);
   }
   tag_idexp_info_init(idexp_info);
   idexp_info.info_flags=VSAUTOCODEINFO_DO_LIST_MEMBERS;
   save_pos(auto orig_pos);
   word_chars := _clex_identifier_chars();
   if (PossibleOperator) {
      left();
      _str ch=get_text();
      if (ch=='(') {
         idexp_info.info_flags=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN|VSAUTOCODEINFO_DO_FUNCTION_HELP;
      } else {
         idexp_info.info_flags=VSAUTOCODEINFO_DO_FUNCTION_HELP;
      }
      if (ch==' ' && p_LangId=='sas') {
         idexp_info.lastid='';
         idexp_info.lastidstart_offset=(int)_QROffset()+1;
         //lastidstart_offset=(int)point('s');
         idexp_info.lastidstart_col=p_col+1;
      } else {
         idexp_info.lastidstart_col=p_col;  // need this for function pointer case
         left();
         search('[~ \t]|^','-rh@');
         // maybe there was a function pointer expression
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            restore_pos(orig_pos);
            return VSCODEHELPRC_CONTEXT_NOT_VALID;
         }
         int end_col=p_col+1;
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
      }
   } else {
      // IF we are not on an id character.
      _str ch=get_text();
      boolean done=false;
      // IF we are not on an id character.
      if (pos('[~'word_chars']',get_text(),1,'r')) {
         int first_col = 1;
         if (p_col > 1) {
            first_col=0;
            left();
         }
         if (pos('[~'word_chars']',get_text(),1,'r')) {
            right();
            if (get_text()=='(') {
               idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
            }
            idexp_info.prefixexp='';
            idexp_info.lastid="";
            idexp_info.lastidstart_col=p_col-first_col;
            idexp_info.lastidstart_offset=(int)point('s');
            done=1;
         }
      }
      if(!done) {
         int old_TruncateLength=p_TruncateLength;p_TruncateLength=0;
         //search('[~'p_word_chars']|$','r@');
         _TruncSearchLine('[~'word_chars']|$','r');
         int end_col=p_col;
         // Check if this is a function call
         //search('[~ \t]|$','r@');
         _TruncSearchLine('[~ \t]|$','r');
         if (get_text()=='(') {
            idexp_info.info_flags|=VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
         }
         p_col=end_col;

         left();
         search('[~'word_chars']\c|^\c','-rh@');
         idexp_info.lastid=_expand_tabsc(p_col,end_col-p_col);
         idexp_info.lastidstart_col=p_col;
         idexp_info.lastidstart_offset=(int)point('s');
         p_TruncateLength=old_TruncateLength;
      }
   }
   restore_pos(orig_pos);
   return(0);
}

/**
 * Find the abstract and virtual function belonging to parents of
 * the current class.
 *
 * @param outer_class         list of parent classes, we will normalize based on
 *                            this outer scope.
 * @param class_name
 * @param selection_indexes   list of items to select initially (abstract)
 * @param only_abstract       Only list abstract members?
 * @param allow_locals        Allow local classes?
 * @param case_sensitive      case sensitive search?
 * @param removeFromCurrentClass
 *
 * @return number of matches on success
 */
int _do_default_get_virtuals(_str outer_class,_str class_name,
                             _str &selection_indexes, boolean only_abstract,
                             boolean allow_locals, boolean case_sensitive,
                             boolean removeFromCurrentClass=true)
{
   //say("_do_default_get_virtuals("parent_classes")");
   // normalize the parent class names
   int num_matches = 0;
   _str tag_files[] = tags_filenamea(p_LangId);
   _str normalized_class_name = '';
   _str normalized_type = '';
   _str normalized_tagfile = '';
   tag_normalize_classes(class_name,outer_class,''/*p_buf_name*/,
                         tag_files,allow_locals,case_sensitive,
                         normalized_class_name,normalized_type,normalized_tagfile);
   //say('normalized_parents='normalized_parents);
   //say('normalized_types='normalized_types);

   // get the virtual methods from each parent class
   tag_clear_matches();
   //say("p1="p1" n1="n1);
   parse normalized_class_name with '<' .;
   _ListVirtualMethods(normalized_class_name,normalized_type, selection_indexes, only_abstract, 0, 0,
                       num_matches, def_tag_max_find_context_tags,
                       allow_locals, case_sensitive, removeFromCurrentClass);

   // return the number of matches
   return num_matches;
}

/**
 * Find tags in the current context and extension specific tag files
 * matching the given tag name or prefix, with the given class, and
 * passing the given tag filters.
 *
 * @param tag_prefix      tag name to search for
 * @param search_class    class that the tag should belong in
 * @param pushtag_flags   VS_TAGFILER_*
 * @param allow_locals    allow local variables?
 * @param case_sensitive  case-sensitive search?
 *
 * @return number of matches found, results are in match set
 *
 * @see tag_get_match
 */
int _do_default_get_matches(_str tag_prefix, _str search_class, int pushtag_flags,
                            boolean allow_locals, boolean case_sensitive, boolean workspaceOnly=false)
{
   // get the list of project tag files
   //_str tag_files[]; tag_files._makeempty();
   //_str project_tag_files = project_tags_filename();
   //while (project_tag_files != '') {
   //   _str tag_filename = next_tag_file2(project_tag_files, true, false);
   //   if (tag_filename!='') {
   //      tag_files[tag_files._length()]=tag_filename;
   //   }
   //}

   // get the virtual methods from each parent class
   _str tag_files[];
   if (workspaceOnly) {
      tag_files[0] = project_tags_filename();
   } else {
      tag_files = tags_filenamea(p_LangId);
   }
   int num_matches = 0;
   tag_clear_matches();
   int base_context_flags = VS_TAGCONTEXT_ACCESS_private;
   if (allow_locals) {
      base_context_flags |= VS_TAGCONTEXT_ALLOW_locals;
   }
   struct VS_TAG_RETURN_TYPE visited:[]; visited._makeempty();
   tag_list_symbols_in_context(tag_prefix, search_class, 0, 0, tag_files, '',
                               num_matches,def_tag_max_find_context_tags,
                               pushtag_flags, base_context_flags,
                               false, case_sensitive, visited, 0);

   // return the number of matches
   return num_matches;
}

/**
 * Sellist callback function to
 * Load the matches into the _sellist_form
 *
 * @param sl_event     event last sent to selection list
 * @param result_str   (output) results
 * @param info         unused
 *
 * @return '' on OK, (1) on failure
 */
static _str _load_matches_in_sellist(int sl_event, _str &result_str, _str info)
{
   //say("_load_matches_in_sellist: sl_event="sl_event);
   _nocheck _control _sellist;
   if (sl_event == SL_ONINITFIRST) {

      int Nofchanges=0;
      typeless p;
      _sellist.save_pos(p);
      _sellist.top();
      _sellist.search('^>','rh@','>',Nofchanges);
      _sellist.restore_pos(p);
      _sellist.p_Nofselected=Nofchanges;

      _sellist.p_picture = _pic_fldopen;
#if 0
      _str select_list = '';
      if (_sellist.p_Noflines > 0) {
         _sellist.p_line = 1;
         select_list = _sellist._lbget_text();
      }
      cb_prepare_expand(p_active_form,_sellist.p_window_id,0);
      int i, a=0, n=tag_get_num_of_matches();
      _sellist.p_picture = _pic_fldopen;
      _sellist._lbclear();
      for (i=1; i<=n; i++) {
         tag_get_match(i, tag_files, tag_name, type_name, file_name, line_no, class_name, tag_flags, signature, return_type);
         tag_list_insert_tag(_sellist.p_window_id, 0, 60, tag_name, type_name, file_name, line_no, class_name, tag_flags, return_type"\1"signature);
      }
      _sellist._lbdeselect_all();
      int first_index = 0;
      while (select_list != '') {
         parse select_list with select_index select_list;
         //say("selecting line: "select_index);
         _sellist.p_line=select_index;
         _sellist._lbselect_line();
         if (first_index==0) {
            first_index=select_index;
         }
      }
      if (first_index<=0) {
         _lbtop();
      } else {
         _sellist.p_line=first_index;
      }
#endif
   } else if (sl_event==SL_ONDEFAULT) {  // Enter key
      result_str='';
      int status=_sellist._lbfind_selected(1);
      while (!status) {
         strappend(result_str, _sellist.p_line-1);
         strappend(result_str, ' ');
         status=_sellist._lbfind_selected(0);
      }
      strappend(result_str, ' ');
      //say("_load_matches_in_sellist: returns"result_str);
      return(1);
   }
   return '';
}
/**
 * Display the set of tags found in the tag database match set
 * (created using tag_clear_matches, tag_insert_matches, or using
 * tag_list_* context related functions targetting a match set.
 * Allow the user to select one or more of the matches from the
 * list control.
 *
 * @param caption             caption for selection list dialog
 * @param allow_multiselect   Allow multiple item selections?
 * @param initial_selections  Initial items to select in list
 * @param already_implemented_class    Fully qualified class.  Entries that belong to
 *                            this class are removed.
 * @param case_sensitive 
 * @param selecttree_cb   Optional callback to be passed along 
 *                        to select_tree()
 * @param cb_data         Optional data that will be passed to 
 *                        selecttree_cb.
 *
 * @return Number of matches on success.
 */
int _list_tag_matches(_str caption, boolean allow_multiselect=false, _str initial_selections='0',
                      _str already_implemented_class='', _str case_sensitive=false, typeless selecttree_cb = null, typeless cb_data = null)
{
   //say("_list_tag_matches: select="initial_selections);

   tag_lock_matches(true);
   int i,j,num_matches=tag_get_num_of_matches();
   boolean selectionlist[];
   for (i=1;i<=num_matches;++i) {
      selectionlist[i]=false;
   }
   for (;;) {
      typeless ln;
      parse initial_selections with ln initial_selections;
      if (ln=='') break;
      selectionlist[ln]=true;
   }
   // create list of captions and tag information
   VS_TAG_BROWSE_INFO cm;
   VS_TAG_BROWSE_INFO taginfo[]; taginfo._makeempty();
   int xlat_index[];
   _str tags[]; tags._makeempty();
   _str keys[]; keys._makeempty();
   boolean select_array[]; select_array._makeempty();

   int first_index=0;
   for (i=1,j=0; i<=num_matches; ++i) {
      tag_get_match_info(i, cm);
      taginfo[i-1]=cm;
      if (already_implemented_class!='') {
         if ((case_sensitive && cm.class_name==already_implemented_class) ||
             (!case_sensitive && strieq(cm.class_name,already_implemented_class))) {
            continue;
         }
      }

      tags[j] = cm.return_type" "cm.member_name"("cm.arguments")\t"cm.class_name;
      keys[j] = j;

      xlat_index[j]=i-1;++j;
      if (selectionlist[i]) {
         select_array[j-1] = true;
      } else {
         select_array[j-1] = false;
      }
   }

   // set up SL_* flags for the _sellist_form
   int sl_flags = (SL_CLOSEBUTTON | SL_SELECTCLINE | 
                   SL_DESELECTALL | SL_COLWIDTH | SL_INVERT | SL_COMBO);

   if (allow_multiselect) {
      sl_flags |= SL_ALLOWMULTISELECT|SL_SELECTALL;
   }

   _str colflag = (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT)','(TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT);
   _str choices = select_tree(tags, keys, null, null, select_array, selecttree_cb, cb_data, caption, sl_flags, "Name,Source Class", colflag);

   if (choices != COMMAND_CANCELLED_RC) {
      // add only the items that they selected to the match list
      tag_clear_matches();
      num_matches = 0;
      while (choices != '') {
         typeless cnum;
         parse choices with cnum"\n"choices;
         cm=taginfo[xlat_index[cnum]];
         tag_insert_match(cm.tag_database,cm.member_name,cm.type_name,
                          cm.file_name,cm.line_no,cm.class_name,cm.flags,
                          cm.return_type:+VS_TAGSEPARATOR_args:+cm.arguments:+VS_TAGSEPARATOR_throws:+cm.exceptions);
         ++num_matches;
      }

   } else {
      num_matches = 0;
   }
   // return the number of matches selected
   tag_unlock_matches();
   return num_matches;
}

/**
 * Find the virtual functions inherited by the current class
 * and list them, initially selecting abstract functions that
 * have to be implemented.
 *
 * @param class_name       Name of class to display list for
 * @param outer_class      Name of class contain class_name
 * @param class_flags      unused
 * @param removeFromCurrentClass
 *
 * @return number of items selected on success, <0 on error.
 */
int _do_default_get_implement_list(_str class_name, _str outer_class, int class_flags,
                                   boolean removeFromCurrentClass=true)
{
   //say("_do_default_get_implement_list("class_name','parent_classes')');
   // list the virtual methods for the given class
   _str parent_classes = '';
   _str selection_indexes = '';
   int num_matches = 0;
   case_sensitive := p_EmbeddedCaseSensitive;
   if(class_name!='') {
      _str tag_files[]=tags_filenamea(p_LangId);
      parent_classes=class_name;//';'parent_classes;
      // Try to qualify this symbol in the scope of the current buffer.
      // tag_qalify_symbol_name usually fails when class_name is for an
      // anonymous class like Enumeration.  This happens when the user
      // types:
      //
      //     new Enumeration() {
      //
      _str qclass_name='';
      tag_qualify_symbol_name(qclass_name,class_name,
                              outer_class,p_buf_name,
                              null /*tag_files*/,case_sensitive);
      if (qclass_name=='') {
         _str normalized_types='';
         _str normalized_files='';
         tag_normalize_classes(class_name,outer_class,''/*p_buf_name*/,
                               tag_files,true,case_sensitive,
                               qclass_name,normalized_types,normalized_files);
      }
      class_name=qclass_name;
   }
   GVindex := _FindLanguageCallbackIndex('_%s_get_virtuals');
   if (GVindex) {
      // This code path has not been tested and probably needs work.
      // Currently,it is not used.
      num_matches= call_index(parent_classes, selection_indexes,
                               false, true, case_sensitive, 
                              removeFromCurrentClass,GVindex);
   } else {
      num_matches= _do_default_get_virtuals(outer_class,
                                            class_name,
                                            selection_indexes,
                                            false, true, case_sensitive,
                                            removeFromCurrentClass);
   }
   if (num_matches <= 0) {
      //_message_box('no matches found');
      return -1;
   }
   if (!removeFromCurrentClass) class_name='';
   // create list of captions and tag information
   return _list_tag_matches(nls('Select virtual functions to override'),
                            true, selection_indexes,class_name,case_sensitive, 
                            _list_virtuals_selecttree_cb, 
                            _LanguageInheritsFrom('c') ? p_buf_name : null);
}



/**
 * Callback that adds list-virtuals option controls 
 * to the selection tree that we bring up.  Implementation 
 * selection information in gListVirtualsImplSelection 
 * 
 * @param reason 
 * @param user_data Name of the active buffer. If this is null, 
 *                  the generation radio buttons will not
 *                  appear.
 * @param info 
 * 
 * @return _str 
 */
static _str _list_virtuals_selecttree_cb(int reason, typeless user_data, typeless info = null)
{
   //TODO help reference
   switch(reason) {
   case SL_ONINITFIRST:
      if (user_data) {
         // We make the assumption here that this is only 
         // supported for C++.  If we're in a header file, get
         // the associated file, otherwise, we assume the associated
         // file would be the file we're currently in.
         if (!_c_is_header_file((_str)user_data)) {
            gLVGenOptions.associatedFile = (_str)user_data;
         } else {
            gLVGenOptions.associatedFile = associated_file_for((_str)user_data);
         }

         bottom_wid := _find_control("ctl_bottom_pic");
        
         group_wid := _create_window(OI_FRAME, bottom_wid, "Generation Options", 0, 60, (int)(bottom_wid.p_width/1.1), 1340, CW_CHILD);
         group_wid.p_name = 'ctl_imploptions';
         group_wid.p_caption = "Generation Options";
         group_wid.p_visible = true;

         implhere_wid := _create_window(OI_RADIO_BUTTON, group_wid, "Implementation here", 120, 200, group_wid.p_width-200, 270, CW_CHILD);
         implhere_wid.p_name = "ctl_implhere";
         implhere_wid.p_eventtab = defeventtab _list_virtuals_handler;

         protohere_wid := _create_window(OI_RADIO_BUTTON, group_wid, "Prototype here, implementation to clipboard",  120, 470 , group_wid.p_width-200 , 270, CW_CHILD);
         protohere_wid.p_name = "ctl_protohere";
         protohere_wid.p_eventtab = defeventtab _list_virtuals_handler;

         _str pretty_target_name = (gLVGenOptions.associatedFile == '') ? "source file" : gLVGenOptions.associatedFile;
         implassoc_wid := _create_window(OI_RADIO_BUTTON, group_wid, "Prototype here, implementation to "_strip_filename(pretty_target_name, 'P'),  
                                         120, 740 , group_wid.p_width-200 , 270, CW_CHILD);
         implassoc_wid.p_name = "ctl_implassoc";
         implassoc_wid.p_eventtab = defeventtab _list_virtuals_handler;

         inline_wid := _create_window(OI_CHECK_BOX, group_wid, "Mark selected implementation as inline", 120, 1030, group_wid.p_width-200, 270, CW_CHILD);
         inline_wid.p_name = 'ctl_inline';
         inline_wid.p_value = 0;
         
         // Default based on whether we found an associated file.         
         if (gLVGenOptions.associatedFile != '') {
            implassoc_wid.p_value = 1;
         } else {
            implhere_wid.p_value = 1;
            implassoc_wid.p_enabled = false;
         }

         bottom_wid.p_visible = bottom_wid.p_enabled = true;
         bottom_wid.p_height = 1450;
         _list_virtuals_enable_handler(p_active_form);
      }
      break;

// case SL_ONSELECT:
//    if (user_data) {
//       _list_virtuals_enable_handler(p_active_form);
//    }
//    break;

   case SL_ONCLOSE:
      if (user_data) {
         int inline_ctl = p_active_form._find_control('ctl_inline');

         gLVGenOptions.selection = _list_virtuals_calc_selection(p_active_form);
         gLVGenOptions.flags = LVGENFLAG_INLINE * (inline_ctl.p_enabled ? inline_ctl.p_value : 0);
      }
      break;
   }

   return '';
}

int _list_virtuals_calc_selection(int form) {
   return LVSELECTION_IMPL_ONLY * form._find_control('ctl_implhere').p_value + 
          LVSELECTION_IMPL_CLIPBOARD * form._find_control('ctl_protohere').p_value +
          LVSELECTION_IMPL_ASSOCIATED *form._find_control('ctl_implassoc').p_value;
}

void _list_virtuals_enable_handler(int form) {
   int inline_ctl = form._find_control('ctl_inline');

   switch (_list_virtuals_calc_selection(form)) {
   case LVSELECTION_IMPL_ONLY:
      inline_ctl.p_enabled = false;
      break;

   case LVSELECTION_IMPL_CLIPBOARD:
      inline_ctl.p_enabled = true;
      break;

   case LVSELECTION_IMPL_ASSOCIATED:
      inline_ctl.p_enabled = _c_is_header_file(gLVGenOptions.associatedFile);
      break;
   }
}

defeventtab _list_virtuals_handler;
void _list_virtuals_handler.lbutton_up()
{
   _list_virtuals_enable_handler(p_active_form);
}

/**
 * Create definition or prototype for all members found in
 * the current match set.
 *
 * @param indent_col         column position to indent to
 * @param brace_indent       amount to indent braces
 * @param make_proto         make prototypes or definitions
 * @param in_class_scope     genenerate code for within class scope
 * @param insert_blank_line  insert blank line between each match?
 * @param className          name of class matches belong to
 * @param class_signature    class signature?
 *
 * @return 0 on success
 */
int _do_default_generate_functions(int indent_col, int brace_indent,
                                 boolean make_proto,
                                 boolean in_class_scope=true,
                                 boolean insert_blank_line=false,
                                 _str className='',
                                 _str class_signature=''
                                 )
{
   // see if code generation is supported
   gen_index := _FindLanguageCallbackIndex('_%s_generate_function');
   if (!gen_index) {
      _message_box("Code generation not supported for this language.");
      return(0);
   }

   // generate code for each match
   boolean CursorDone=false;
   typeless AfterKeyinPos;
   save_pos(AfterKeyinPos);
   int match_id=0;
   int count=tag_get_num_of_matches();
   for (match_id=1; match_id<=count; ++match_id) {
      if (insert_blank_line) {
         get_line(auto line);
         if (line!='') {
            insert_line('');
         }
      }
      // get detailed information about the tag match
      VS_TAG_BROWSE_INFO cm;
      tag_get_match_info(match_id, cm);

      // Can't we get source comments?
      tag_push_matches();
      _str header_list[];header_list._makeempty();
      _ExtractTagComments(header_list, 2000, cm.member_name, cm.file_name, cm.line_no,
                          cm.type_name, cm.class_name, indent_col);
      tag_pop_matches();

      // generate the match signature for this function, not a prototype
      int c_access_flags=(cm.flags&VS_TAGFLAG_access);
      int akpos=call_index(cm,c_access_flags,header_list, null, 
                           indent_col,brace_indent,make_proto,
                           in_class_scope,className,class_signature,gen_index);
      if (!CursorDone) {
         CursorDone=true;
         AfterKeyinPos = akpos;
      }
   }

   // Handle some language specific declaration terminations...
   if (in_class_scope) {
      down();
      get_line(auto cur_line);
      if (_LanguageInheritsFrom('c') && !_LanguageInheritsFrom('d') && cur_line=='}') {
         replace_line(strip(cur_line,'T'):+';');
      }
      if (_LanguageInheritsFrom('e') && cur_line=='}') {
         replace_line(strip(cur_line,'T'):+';');
      }
   }

   // restore cursor position and we're done
   restore_pos(AfterKeyinPos);
   return (0);
}

/**
 * Create definition or prototype for all members found in
 * the current match set.
 *
 * @param indent_col         column position to indent to
 * @param brace_indent       amount to indent braces
 * @param make_proto         make prototypes or definitions
 * @param in_class_scope     genenerate code for within class scope
 * @param insert_blank_line  insert blank line between each match?
 * @param className          name of class matches belong to
 * @param class_signature    class signature?
 *
 * @return 0 on success
 */
/*
int _do_default_generate_matches(int indent_col, int brace_indent,
                                 boolean make_proto,
                                 boolean in_class_scope=true,
                                 boolean insert_blank_line=false,
                                 _str className='',
                                 _str class_signature=''
                                 )
{
   // see if code generation is supported
   int gen_index = _FindLanguageCallbackIndex('_%s_generate_match_signature');
   if (!gen_index) {
      _message_box("Code generation not supported for this language.");
      return(0);
   }

   // generate code for each match
   boolean CursorDone=false;
   typeless AfterKeyinPos;
   save_pos(AfterKeyinPos);
   int match_id=0;
   int count=tag_get_num_of_matches();
   for (match_id=1; match_id<=count; ++match_id) {
      if (insert_blank_line) {
         get_line(auto line);
         if (line!='') {
            insert_line('');
         }
      }
      // get detailed information about the tag match
      _str tag_file='';
      _str tag_name='';
      _str type_name='';
      _str file_name='';
      _str class_name='';
      _str signature='';
      _str return_type='';
      int line_no=0;
      int tag_flags=0;
      tag_get_match(match_id,tag_file,tag_name,type_name,
                    file_name,line_no,class_name,
                    tag_flags,signature,return_type);

      // Can't we get source comments?
      tag_push_matches();
      _str header_list[];header_list._makeempty();
      _ExtractTagComments(header_list,2000,tag_name,file_name,line_no,
                          type_name, class_name, indent_col);
      tag_pop_matches();

      // generate the match signature for this function, not a prototype
      int c_access_flags=(tag_flags&VS_TAGFLAG_access);
      int akpos=call_index(match_id,c_access_flags,header_list,
                           indent_col,brace_indent,make_proto,
                           in_class_scope,className,class_signature,gen_index);
      if (!CursorDone) {
         CursorDone=true;
         AfterKeyinPos = akpos;
      }
   }
   // restore cursor position and we're done
   restore_pos(AfterKeyinPos);
   return (0);
}
*/
/**
 * This is the default function for matching return types.
 * It simply compares types for an exact match and inserts the
 * candidate tag if they match.
 *
 * The extension specific hook function _[ext]_match_return_type()
 * is normally used to perform type matching, and account for
 * language specific features, such as pointer dereferencing,
 * class construction, function call, array access, etc.
 *
 * @param rt_expected    expected return type for this context
 * @param rt_candidate   candidate return type
 * @param tag_name       candidate tag name
 * @param type_name      candidate tag type
 * @param tag_flags      candidate tag flags
 * @param file_name      candidate tag file location
 * @param line_no        candidate tag line number
 * @param prefixexp      prefix to prepend to tag name when inserting ('')
 * @param tag_files      tag files to search (not used)
 * @param tree_wid       tree to insert directly into (gListHelp_tree_wid)
 * @param tree_index     index of tree to insert items at (TREE_ROOT_INDEX)
 *
 * @return number of items inserted into the tree
 */
int _do_default_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                  struct VS_TAG_RETURN_TYPE &rt_candidate,
                                  _str tag_name,_str type_name, int tag_flags,
                                  _str file_name, int line_no,
                                  _str prefixexp,typeless tag_files,
                                  int tree_wid, int tree_index)
{
   if (tag_return_type_equal(rt_expected,rt_candidate,p_EmbeddedCaseSensitive)) {
      if (prefixexp=='') {
         tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,
                             tag_name,type_name,
                             file_name,line_no,'',tag_flags,'');
      }
      return(1);
   }
   return(0);
}

//struct {
class MI_localFunctionParams_t {
   _str m_param[];
   _str m_ptype[];
   _str m_rtype;
   _str m_exception[];
   _str m_existingParamName[];
   _str m_existingParamDesc[];
   _str m_existingRName;
   _str m_existingRDesc;
   _str m_existingSummary;
   _str m_existingException[];
   _str m_signature;
   _str m_procName;
   _str m_className;
   MI_localFunctionParams_t() {
      m_param._makeempty();
      m_ptype._makeempty();
      m_rtype = '';
      m_exception._makeempty();
      m_existingParamName._makeempty();
      m_existingParamDesc._makeempty();
      m_existingRName = '';
      m_existingRDesc = '';
      m_existingSummary = '';
      m_existingException._makeempty();
      m_signature = '';
      m_procName = '';
      m_className = '';
   }
   int paramNum() {
      return m_param._length();
   }
   int returnNum() {
      if (m_rtype != '' && m_rtype != 'void') {
         return 1;
      }
      return 0;
   }
};

/**
 * Create a document-style comment for the current function
 *
 * @parma   localParms
 *
 * @return 0 on success, <0 on error
 */
int getLocalFunctionParams(MI_localFunctionParams_t& localParms)
{
   localParms.m_rtype = '';
   localParms.m_param._makeempty();
   if (!_is_line_before_decl()) {
      return 1;
   }
   //Put Cursor on the declaration
   p_line++;
   _first_non_blank_col();

   _UpdateContext(true);
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   // get the multi-line comment start string
   _str slcomment_start;
   _str mlcomment_start;
   _str mlcomment_end;
   //boolean javadocSupported=false;
   //if(get_comment_delims(slcomment_start,mlcomment_start,mlcomment_end,javadocSupported) || !javadocSupported) {
   //   if (embedded_status==1) {
   //      _EmbeddedEnd(orig_values);
   //   }
   //   _message_box('JavaDoc comment not supported for this file type');
   //   return(1);
   //}
   save_pos(auto p);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // try to locate the current context, maybe skip over
   // comments to start of next tag
   int context_id = tag_current_context();
   if ((context_id<=0 || _in_comment()) && !_clex_skip_blanks()) {
      context_id = tag_current_context();
   }
   if (context_id <= 0) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      restore_pos(p);
      _message_box('no current tag');
      return context_id;
   }

   // get the information about the current function
   _str tag_name = '';
   _str type_name = '';
   _str file_name = '';
   _str class_name = '';
   _str arguments = '';
   _str return_type = '';
   int start_line_no = 0;
   int start_seekpos = 0;
   int scope_line_no = 0;
   int scope_seekpos = 0;
   int end_line_no = 0;
   int end_seekpos = 0;
   int tag_flags = 0;
   tag_get_context(context_id, tag_name, type_name, file_name,
                   start_line_no, start_seekpos, scope_line_no,
                   scope_seekpos, end_line_no, end_seekpos,
                   class_name, tag_flags, arguments, return_type);

   // get the start column of the tag, align new comment here
   int i=0;
   //_str local_param_names[]; 
   //local_param_names._makeempty();
   // Want %\N to work for any tag type so always set localParms.m_procName
   tag_get_detail2(VS_TAGDETAIL_context_name, context_id, localParms.m_procName);
   if (tag_tree_type_is_func(type_name)) {
      _GoToROffset((scope_seekpos<end_seekpos)? scope_seekpos:start_seekpos);
      _UpdateLocals(true);
      localParms.m_signature = tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,true,true,false);

      for (i=1; i<=tag_get_num_of_locals(); i++) {
         _str param_name='';
         _str param_return='';
         _str param_type='';
         int local_seekpos=0;
         tag_get_detail2(VS_TAGDETAIL_local_type,i,param_type);
         tag_get_detail2(VS_TAGDETAIL_local_start_seekpos,i,local_seekpos);
         if (param_type=='param' && local_seekpos>=start_seekpos && local_seekpos < scope_seekpos) {
            tag_get_detail2(VS_TAGDETAIL_local_name, i, param_name);
            tag_get_detail2(VS_TAGDETAIL_local_return, i, param_return);
            //Do not include C/C++ template params
            if (!(param_return == 'class' && p_LangId == 'c')) {
               localParms.m_param[localParms.m_param._length()] = param_name;
               localParms.m_ptype[localParms.m_ptype._length()] = param_return;
            }
         }
      }
      if (return_type != '') {
         localParms.m_rtype = return_type;
         localParms.m_signature = return_type :+ ' ' :+ localParms.m_signature;
      }
   }
   _GoToROffset(start_seekpos);
   int start_col = p_col;

   // hash table of original comments for incremental updates
   int comment_flags=0;
   _str orig_comment='';
   int first_line, last_line;
   if (!_do_default_get_tag_header_comments(first_line, last_line)) {
      p_RLine=start_line_no;
      _GoToROffset(start_seekpos);
      _str line_prefix='';
      int blanks:[][];
      _str doxygen_comment_start='';
      _do_default_get_tag_comments(comment_flags,type_name, orig_comment, 1000, true, line_prefix, blanks, 
         doxygen_comment_start);
   } else {
      first_line = start_line_no;
      last_line  = first_line-1;
      //first_line = last_line = start_line_no-1;
   }

   if (class_name != '') {
      localParms.m_className = class_name;
   }

//say(orig_comment);
#if 0
   // delete the original comment lines
   int num_lines = last_line-first_line+1;
   if (num_lines > 0) {
      p_line=first_line;
      for (i=0; i<num_lines; i++) {
         _delete_line();
      }
   } else {
      first_line=start_line_no;
   }
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }

   // insert the comment start string and juggle slcomment if needed
   if (first_line>1) {
      p_line=first_line-1;
   } else {
      top();up();
   }
   if (mlcomment_start!='') {
      insert_line(indent_string(start_col-1):+mlcomment_start'*');
      slcomment_start='';
      if (pos('*',mlcomment_start)) {
         slcomment_start=' *';
      }
   }
   _str prefix=indent_string(start_col-1):+slcomment_start:+' ';

   //DOB 03-19-06 Do not insert '*' if option not checked
   if (!_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK)) {
      prefix = translate(prefix, ' ', '*');
   }
   //DOB end of change

   // parse the parts out of the original comment
   _str orig_parts:[];
   orig_parts._makeempty();
   int first_param_pos=0;
   _str cmt = orig_comment;
   _str part_key = '';
   while (cmt!='') {
      _str one_line='';
      parse cmt with one_line "\n" cmt;
      if (substr(strip(one_line),1,1)=='@') {
         _str kw='';
         _str id='';
         parse one_line with "@" kw id .;
         if (lowcase(kw)=='param') {
            part_key='@param'id;
            orig_parts:[part_key] = one_line;
            if (!first_param_pos) {
               save_pos(first_param_pos);
            }
         } else if (lowcase(kw)=='return') {
            part_key='@return';
            orig_parts:[part_key] = one_line;
         } else {
            part_key='';
         }
      }
      // either append to the current key or re-insert line
      if (part_key!='') {
         if (substr(strip(one_line),1,1)!='@') {
            orig_parts:[part_key] = orig_parts:[part_key]"\n"one_line;
         }
      } else {
         insert_line(prefix:+one_line);
      }
   }

   // insert the original parts of the comment (description)
   typeless cursor_pos=null;
   if (orig_comment=='') {
      insert_line(prefix);
      save_pos(cursor_pos);
   }
   if (!first_param_pos) {
      save_pos(first_param_pos);
   }
   if (mlcomment_start!='') {
      insert_line(indent_string(start_col):+mlcomment_end);
   }

   // insert the parameter descriptions, recycle old ones
   if (first_param_pos>1) {
      restore_pos(first_param_pos);
   }
   // insert a blank line before the javadoc tags, if necessary
   _str last_inserted='';
   get_line(last_inserted);
   if (last_inserted!='' && last_inserted!='*') {
      insert_line(prefix);
   }

   for (i=0; i<local_param_names._length(); i++) {
      _str param_name=local_param_names[i];
      if (orig_parts._indexin('@param'param_name)) {
         cmt = orig_parts:['@param'param_name];
         orig_parts._deleteel('@param'param_name);
         while (cmt!='') {
            _str one_line='';
            parse cmt with one_line "\n" cmt;
            insert_line(prefix:+one_line);
         }
      } else {
         insert_line(prefix'@param 'param_name);
      }
   }

   boolean hit_param=false;
   typeless j)
   for (j._maieempty();;) {
       orig_partc._nextel(j);
       if (j._iseepty()) break;
       if (subst (j,1,6)=='@para%') {
          if (!hit_param) {
             insert_line(pre$ix'---start old parameters---')!
              it_param=1;
          }
          cmt = orig_ arts:[j];
          while (cmt!='') {
             _str one_line='';
             parse cmt with one_line "\n" cmt;
             insert_line(prefix:+one_line);
          }
       }
   }
   if (hit_param) {
      insert_line(prefix'---end old parameters---');
   }

   // insert the return type description, recycle old one if present
   _str current_line='';
   if (orig_parts._indexin('@return') && orig_parts:['@return']!='') {
      get_line(current_line);
      if (current_line != '') {
         insert_line(prefix);
      }
      cmt = orig_parts:['@return'];
      while (cmt!='') {
         _str one_line='';
         parse cmt with one_line "\n" cmt;
         insert_line(prefix:+one_line);
      }
   } else if (return_type!='' && return_type!='void' && tag_tree_type_is_func(type_name)) {
      get_line(current_line);
      if (current_line != '') {
         insert_line(prefix);
      }
      insert_line(prefix'@return 'return_type);
   }
   if (cursor_pos!=null) {
      restore_pos(cursor_pos);
   }
#endif
   // restore the search and current position
   return(0);
}


/**
 * Create a document-style comment for the current function
 * 
 * @param trigger  The keystoke that triggered the build commment event.
 * 
 * @return 0 on success, <0 on error
*/
int _document_comment(_str trigger = DocCommentTrigger1)
{
   boolean blockStyle;
   switch (trigger) {
      case DocCommentTrigger1:
      case DocCommentTrigger2:
         blockStyle = true;
         break;
      case DocCommentTrigger3:
      case DocCommentTrigger4:
         blockStyle = false;
         break;
      default:
         return -1;
   }
   _str docCommentStyle = _GetDocCommentFlags(trigger);
   if (docCommentStyle == DocCommentStyle3 && !blockStyle) {
      //return (int)c_maybe_create_xmldoc_comment(trigger);
   }

   boolean mergeExistingComment = false;
   _UpdateContext(true);
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   // get the multi-line comment start string
   _str prefix, endPrefix;
   _str mlcomment_start;
   _str mlcomment_end;
   boolean javadocSupported=false;
   if(get_comment_delims(prefix,mlcomment_start,mlcomment_end,javadocSupported) || (!javadocSupported && blockStyle)) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      _message_box('JavaDoc comment not supported for this file type');
      return(1);
   }

   if ((mlcomment_start != substr(trigger, 1, length(mlcomment_start)) && blockStyle) ||
       (prefix != substr(trigger, 1, length(prefix)) && !blockStyle)) {
      _message_box('Unable to create doc comment of specified style for this file type.');
      return(1);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   save_pos(auto p);
   // try to locate the current context, maybe skip over
   // comments to start of next tag
   int context_id = tag_current_context();
   if ((context_id<=0 || _in_comment()) && !_clex_skip_blanks()) {
      context_id = tag_current_context();
   }
   if (context_id <= 0) {
      if (embedded_status==1) {
         _EmbeddedEnd(orig_values);
      }
      restore_pos(p);
      _message_box('no current tag');
      return context_id;
   }

   // get the information about the current function
   _str tag_name = '';
   _str type_name = '';
   _str file_name = '';
   _str class_name = '';
   _str signature = '';
   _str return_type = '';
   int start_line_no = 0;
   int start_seekpos = 0;
   int scope_line_no = 0;
   int scope_seekpos = 0;
   int end_line_no = 0;
   int end_seekpos = 0;
   int tag_flags = 0;
   tag_get_context(context_id, tag_name, type_name, file_name,
                   start_line_no, start_seekpos, scope_line_no,
                   scope_seekpos, end_line_no, end_seekpos,
                   class_name, tag_flags, signature, return_type);

   // get the start column of the tag, align new comment here
   int i=0;
   _str local_param_names[]; 
   local_param_names._makeempty();
   if (tag_tree_type_is_func(type_name)) {
      _GoToROffset((scope_seekpos<end_seekpos)? scope_seekpos:start_seekpos);
      _UpdateLocals(true);

      for (i=1; i<=tag_get_num_of_locals(); i++) {
         _str param_name='';
         _str param_type='';
         int local_seekpos=0;
         tag_get_detail2(VS_TAGDETAIL_local_type,i,param_type);
         tag_get_detail2(VS_TAGDETAIL_local_start_seekpos,i,local_seekpos);
         if (param_type=='param' && local_seekpos>=start_seekpos) {
            tag_get_detail2(VS_TAGDETAIL_local_name,i,param_name);
            local_param_names[local_param_names._length()] = param_name;
         }
      }
   }
   _GoToROffset(start_seekpos);
   int start_col = p_col;

   // hash table of original comments for incremental updates
   int comment_flags=0;
   _str orig_comment='';
   int first_line, last_line;
   first_line = last_line = start_line_no-1;

   // delete the original comment lines
   p_line=first_line;
   _delete_line();

   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }

   // insert the comment start string and juggle slcomment if needed
   if (first_line>1) {
      p_line=first_line-1;
   } else {
      top();up();
   }

   if (blockStyle) insert_line(indent_string(start_col-1) :+ trigger :+ ' ');
   if (!blockStyle) {
      prefix = indent_string(start_col-1) :+ trigger :+ ' ';
      endPrefix = prefix;
   } else {
      if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK)) {
         prefix = indent_string(start_col) :+ '* ';
      }
      else prefix = indent_string(start_col + 2);
      endPrefix = indent_string(start_col) :+ mlcomment_end;
   }

   // parse the parts out of the original comment
   _str orig_parts:[];
   orig_parts._makeempty();
   int first_param_pos=0;
   _str cmt = orig_comment;
   _str part_key = '';

   // insert the original parts of the comment (description)
   typeless cursor_pos=null;
   if (orig_comment=='') {
      insert_line(prefix);
      save_pos(cursor_pos);
   }
   if (!first_param_pos) {
      save_pos(first_param_pos);
   }
   if (endPrefix!='' && blockStyle) {
      insert_line(endPrefix);
   }

   // insert the parameter descriptions, recycle old ones
   if (first_param_pos>1) {
      restore_pos(first_param_pos);
   }
   // insert a blank line before the javadoc tags, if necessary
   _str last_inserted='';
   get_line(last_inserted);
   if (last_inserted!='' && last_inserted!='*' && blockStyle) {
      insert_line(prefix);
   }

   for (i=0; i<local_param_names._length(); i++) {
      _str param_name=local_param_names[i];
      insert_line(prefix :+ makeDocCommentParam(param_name, docCommentStyle));
   }

   // insert the return type description, recycle old one if present
   _str current_line='';
   if (return_type!='' && return_type!='void' && tag_tree_type_is_func(type_name)) {
      get_line(current_line);
      if (current_line != '' && docCommentStyle != DocCommentStyle3) {
         insert_line(prefix);
      }
      insert_line(prefix :+ makeDocCommentReturn(return_type, docCommentStyle));
   }
   if (cursor_pos!=null) {
      restore_pos(cursor_pos);
   }
   if (docCommentStyle != DocCommentStyle3) {
      insert_line(prefix);
   } else {
      _insert_text('<summary>');
      insert_line(prefix);
      save_pos(cursor_pos);
      insert_line(prefix :+ '</summary>');
   }
   restore_pos(cursor_pos);

   // restore the search and current position
   return(0);
}

_str makeDocCommentParam(_str param_name, _str style) {
   switch (style) {
      case DocCommentStyle2:
         return ('\param ' :+ param_name);
         break;
      case DocCommentStyle3:
         return ('<param name="'param_name'"></param>');
         break;
      case DocCommentStyle1:
      default:
         return ('@param ' :+ param_name);
         break;
   }
   return param_name;
}

_str makeDocCommentReturn(_str return_type, _str style) {
   switch (style) {
      case DocCommentStyle2:
         return ('\return ' :+ return_type);
         break;
      case DocCommentStyle3:
         return ('<returns>'return_type'</returns>');
         break;
      case DocCommentStyle1:
      default:
         return ('@return ' :+ return_type);
         break;
   }
   return return_type;
}


static _str _get_class_def_filename(_str className)
{
   boolean case_sensitive=p_EmbeddedCaseSensitive;

   //say(new_signature);
   int isinline=0;

   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   _str tag_files[]= tags_filenamea(p_LangId);
   int num_matches = 0;
   tag_clear_matches();
   struct VS_TAG_RETURN_TYPE visited:[]; visited._makeempty();
   tag_list_symbols_in_context('', className, 0, 0, tag_files, '',
                               num_matches,def_tag_max_find_context_tags,
                               VS_TAGFILTER_ANYTHING,
                               VS_TAGCONTEXT_ACCESS_private|VS_TAGCONTEXT_ONLY_this_class,
                               false, case_sensitive, visited, 0);
   int match_id;
   for (match_id=1;match_id<=num_matches;++match_id) {
      _str tag_file = '';
      _str tag_name = '';
      _str type_name = '';
      _str file_name = '';
      _str class_name = '';
      _str signature = '';
      _str return_type = '';
      int line_no=0;
      int tag_flags=0;
      tag_get_match(match_id,tag_file,tag_name,type_name,
                    file_name,line_no,class_name,
                    tag_flags,signature,return_type);
      if (!(tag_flags & VS_TAGFLAG_inclass) &&
          tag_tree_type_is_func(type_name) &&
          (isinline== (tag_flags&VS_TAGFLAG_inline))
          ) {
         return(file_name);
      }
   }
   return('');
}
static int _override_method(boolean quiet,VS_TAG_BROWSE_INFO &cm,boolean doEdit)
{
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   _str cur_class_name = '';
   _str cur_type_name = '';
   _str cur_parents = '';
   _str cur_outer_class = '';
   _str cur_class = '';
   _str class_signature = '';
   int cur_tag_flags = 0;
   long insert_seekpos = _QROffset();
   while (context_id > 0) {
      // Since the current context is for the class and not a member,
      // cur_class_name is the scope (package/outer classes) of this class and
      // not this class.  This is exactly what we want so we can resolve the
      // parent classes.
      tag_get_detail2(VS_TAGDETAIL_context_class, context_id, cur_outer_class);
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, cur_type_name);
      tag_get_detail2(VS_TAGDETAIL_context_parents, context_id, cur_parents);
      tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, cur_tag_flags);

      tag_get_detail2(VS_TAGDETAIL_context_name,context_id,cur_class);
      tag_get_detail2(VS_TAGDETAIL_context_args,context_id,class_signature);

      if (tag_tree_type_is_class(cur_type_name)) {
         break;
      }
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, insert_seekpos);
      tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, context_id);
   }
   
   if (context_id <= 0 || !tag_tree_type_is_class(cur_type_name)) {
      if (!quiet) {
         _message_box("Not in class context");
      }
      return(1);
   }
   int is_abstract = 0;
   if (cur_tag_flags & VS_TAGFLAG_abstract) {
      is_abstract = 1;
   }
   if (cur_type_name == 'interface') {
      is_abstract = 1;
   }
   _str filename=_get_class_def_filename(cur_class);

   // find the virtual functions
   int num_matches=_do_default_get_implement_list(cur_class, cur_outer_class,is_abstract);
   if (num_matches<=0) {
      if (!quiet && num_matches!=COMMAND_CANCELLED_RC) {
         _message_box("No overridable methods found");
      }
      return(num_matches);
   }
   if (num_matches <= 0) {
      return num_matches;
   }

   // now find exactly where to insert the item
   int cfg=_clex_find(0,'g');
   if (cfg==CFG_COMMENT || insert_seekpos!=_QROffset()) {
      if (insert_seekpos!=_QROffset() && insert_seekpos>0) {
         _GoToROffset(insert_seekpos-1);
      }
      _clex_skip_blanks('-');
      save_pos(auto p);
      long skip_seekpos=_QROffset();
      _clex_find(CFG_COMMENT);
      if (_QROffset() >= insert_seekpos) {
         restore_pos(p);
         _clex_find(0,'n');
      } else {
         _clex_find(CFG_COMMENT,'-n');
      }
   }

   _TagDelayCallList();
   if (cm!=null && _LanguageInheritsFrom('c')) {
      if (filename=='') {
         int orig_view_id;
         get_window_id(orig_view_id);
         // Determine the file which is to contain the definition of the function
         _str wildcards='';
         parse def_file_types with '(^|,)C/C\+\+ Files \(','ri' wildcards')';
         filename=_OpenDialog('-new -mdi -modal','Open File for Definitions',wildcards,'',OFN_NODATASETS,'',p_buf_name);
         activate_window(orig_view_id);
         if (filename=='') {
            return(1);
         }
      }
      int buf_id=p_buf_id;
      int temp_view_id2,orig_view_id2;

      if (!file_eq(filename,p_buf_name)) {
         buf_id=_BufEdit(filename,'',true,'',true);
         if (buf_id<0) {
            if (buf_id==FILE_NOT_FOUND_RC) {
               _message_box(nls("File '%s' not found",filename));
            } else {
               _message_box(nls("Unable to open '%s'",filename)'.  'get_message(buf_id));
            }
            return(buf_id);
         }
         _open_temp_view('',temp_view_id2,orig_view_id2,'+bi 'buf_id);
         if (_QReadOnly()) {
            _delete_temp_view(temp_view_id2);activate_window(orig_view_id2);
            _message_box(nls("File '%s' is read only",filename));
            return(ACCESS_DENIED_RC);
         }
         activate_window(orig_view_id2);
      }

      int enter_indent = c_indent_col(0,false)-1;
      _do_default_generate_functions(enter_indent,0,true,true);
      //_BGReTag2(true);
      if (!file_eq(filename,p_buf_name)) {
         int status=_save_file(build_save_options(p_buf_name));
         if ( status ) {
            _message_box(nls('Unable to save file "%s"',p_buf_name)'.  'get_message(status));
            _delete_temp_view(temp_view_id2);
            activate_window(orig_view_id2);
            return(status);
         }
         TagFileOnSave();
         _delete_temp_view(temp_view_id2,false);
         activate_window(orig_view_id2);
      }
      int status = edit('+bi 'buf_id,EDIT_DEFAULT_FLAGS);
      if (status && status!=NEW_FILE_RC) {
         return(0);
      }
      bottom();
      _do_default_generate_functions(0,0,false,false,true,cur_class,class_signature);
      insert_line(indent_string(p_SyntaxIndent));
      _BGReTag2(true);
   } else {
      generate_code_for_override(cur_outer_class, cur_class);
      _BGReTag2(true);
      if (doEdit) {
         int line=p_RLine;
         int col=p_col;
         // try to open the file
         int status = edit(maybe_quote_filename(p_buf_name),EDIT_DEFAULT_FLAGS);
         if (!status) {
            goto_line(line);goto_col(col);
         }
      }
   }
   _TagProcessCallList();

   return(0);
}

/**
 * Helper function for functions that call 
 * list_tag_matches.  Generates code taking the 
 * generation options set in the dialog into account. 
 * 
 * @param _namespace 
 * @param classname 
 */
void generate_code_for_override(_str _namespace, _str classname)
{
   boolean has_impl              = (_LanguageInheritsFrom('c'));
   boolean proto_in_current_file = has_impl && (gLVGenOptions.selection == LVSELECTION_IMPL_CLIPBOARD || 
                                                gLVGenOptions.selection == LVSELECTION_IMPL_ASSOCIATED);
   int indent_col                = _get_enter_indent();

   _do_default_generate_functions(indent_col,0,proto_in_current_file,true, true);

   // If the language supports it, and the user asked for it, generate
   // implementations and copy them to the clipboard.
   if (proto_in_current_file) {
      _str qual_class_name = (_namespace != '') ? (_namespace :+ VS_TAGSEPARATOR_package :+ classname) : classname;
      boolean mark_as_inline = (gLVGenOptions.flags & LVGENFLAG_INLINE) != 0;

      if (gLVGenOptions.selection == LVSELECTION_IMPL_CLIPBOARD) {
         _str base_bufname = _strip_filename(p_buf_name, 'E');
         _str buf_extension = _get_extension(p_buf_name);

         if (mark_as_inline) {
            // Since they've marked code that's going to the clipboard
            // as being inline, we assume they know what they're doing, and
            // make sure that the code generation file thinks that it's a header
            // file, and therefore ok to drop inline keywords into.
            buf_extension = 'h';
         } else {
            buf_extension = 'cpp';
         }

         old_wid := _create_temp_view(auto tmp_wid, '', base_bufname'.'buf_extension, true, VSBUFFLAG_THROW_AWAY_CHANGES);
         if (old_wid != '') {
            indent_col = _get_enter_indent();
            _do_default_generate_functions(indent_col,0,false,false,true, qual_class_name, '');
            select_all();
            copy_to_clipboard();
            activate_window(old_wid);
            _delete_temp_view(tmp_wid);
            message("Copied implementation skeleton to clipboard.");
         } 
      } else if (gLVGenOptions.selection == LVSELECTION_IMPL_ASSOCIATED) {
         _str curbuf = p_buf_name;
         _save_pos2(auto curpos);
         if (0 == edit('+q -bp 'maybe_quote_filename(gLVGenOptions.associatedFile))) {
            _GoToROffset(p_buf_size);
            insert_line('');
            indent_col = _get_enter_indent();
            _do_default_generate_functions(indent_col,0,false,false,true, 
                                           qual_class_name, '');
            edit('+b -bp'curbuf);
         } else {
            message("Could not open "gLVGenOptions.associatedFile);
         }
         _restore_pos2(curpos);
      }
   } else {
      insert_line(indent_string(indent_col+p_SyntaxIndent));
   }
}

/**
 * Decide whether or not, based on current context, the override
 * virtual method menu item should be enabled or disabled.
 *
 * @param cmdui          CMDUI?
 * @param target_wid     target window
 * @param command        command name
 *
 * @return MF_ENABLED if menu item should be enabled, MF_GRAYED otherwise.
 */
int _OnUpdate_override_method(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   //status=(index_callable(find_index('_'p_LangId'_fcthelp_get_start',PROC_TYPE)) );
   int status=_EmbeddedCallbackAvailable('_%s_generate_function');
   if (!status) {
      return(MF_GRAYED);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // check that they are in a class context
   int context_id = tag_current_context();
   _str cur_type_name = '';
   while (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, cur_type_name);
      if (tag_tree_type_is_class(cur_type_name)) {
         return(MF_ENABLED);
      }
      tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, context_id);
   }
   return(MF_GRAYED);
}

/**
  List virtual functions inherited from parents of the current
  class and select the ones that are to be overridden.
*/
_command void override_method(boolean quiet=true,VS_TAG_BROWSE_INFO &cm=null,boolean doEdit=false) name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _EmbeddedCall(_override_method,quiet,cm,doEdit);
}

/**
  List function prototypes in the given class and create definitions
  for them, carrying over any comments.

  @param class_name   class to make prototypes for functions in

  @return number of functions implemented, <0 on error
*/
_command implement_protos(_str class_name='') name_info(CLASSNAME_ARG','VSARG2_REQUIRES_EDITORCTL)
{
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   _str cur_class_name = '';
   _str cur_class_args = '';
   _str cur_tag_name = '';
   _str cur_type_name = '';
   _str cur_parents = '';
   int cur_tag_flags = 0;
   boolean in_class_scope=false;
   case_sensitive := p_EmbeddedCaseSensitive;
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_name, context_id, cur_tag_name);
      tag_get_detail2(VS_TAGDETAIL_context_class, context_id, cur_class_name);
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, cur_type_name);
      tag_get_detail2(VS_TAGDETAIL_context_parents, context_id, cur_parents);
      tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, cur_tag_flags);

      if (tag_tree_type_is_class(cur_type_name) || tag_tree_type_is_package(cur_type_name)) {
         cur_class_name = tag_join_class_name(cur_tag_name, cur_class_name,
                                              null, case_sensitive);
         in_class_scope=true;
      }
   }

   // list the classes in the current scope if not already in a class
   _str selection_indexes = '';
   int num_matches = 0;
   if (!tag_tree_type_is_class(cur_type_name)) {
      if (class_name!='') {
         GCindex := _FindLanguageCallbackIndex('_%s_get_matches');
         if (GCindex) {
            num_matches = call_index(class_name,cur_class_name,
                                     VS_TAGFILTER_STRUCT|VS_TAGFILTER_UNION|VS_TAGFILTER_INTERFACE,
                                     true, case_sensitive, true, GCindex);
         } else {
            num_matches = _do_default_get_matches(class_name,cur_class_name,
                                                  VS_TAGFILTER_STRUCT|VS_TAGFILTER_UNION|VS_TAGFILTER_INTERFACE,
                                                  true, case_sensitive, true);
         }
         if (num_matches > 0) {
            tag_get_detail2(VS_TAGDETAIL_match_args, 1, cur_class_args);
         }
         cur_class_name=class_name;
      } else {
         GCindex := _FindLanguageCallbackIndex('_%s_get_matches');
         if (GCindex) {
            num_matches = call_index('',cur_class_name,
                                     VS_TAGFILTER_STRUCT|VS_TAGFILTER_UNION|VS_TAGFILTER_INTERFACE,
                                     true, case_sensitive, true, GCindex);
         } else {
            num_matches = _do_default_get_matches('',cur_class_name,
                                                  VS_TAGFILTER_STRUCT|VS_TAGFILTER_UNION|VS_TAGFILTER_INTERFACE,
                                                  true, case_sensitive, true);
         }
         if (num_matches > 0) {
            num_matches = _list_tag_matches(nls('Select class (no selection = globals)'),
                                            false, selection_indexes);
            if (num_matches < 0) {
               return num_matches;
            } else if (num_matches==1) {
               typeless tag_files = tags_filenamea();
               tag_get_detail2(VS_TAGDETAIL_match_name, 1, cur_tag_name);
               tag_get_detail2(VS_TAGDETAIL_match_class, 1, cur_class_name);
               tag_get_detail2(VS_TAGDETAIL_match_type, 1, cur_type_name);
               tag_get_detail2(VS_TAGDETAIL_match_parents, 1, cur_parents);
               tag_get_detail2(VS_TAGDETAIL_match_flags, 1, cur_tag_flags);
               tag_get_detail2(VS_TAGDETAIL_match_args, 1, cur_class_args);
               if (tag_tree_type_is_class(cur_type_name) || tag_tree_type_is_package(cur_type_name)) {
                  cur_class_name = tag_join_class_name(cur_tag_name, cur_class_name,
                                                       tag_files, case_sensitive);
               }
            }
         }
      }
   }

   // list the methods already implemented for the given class
   _str tag_prefix='';
   GVindex := _FindLanguageCallbackIndex('_%s_get_matches');
   if (GVindex) {
      num_matches = call_index(tag_prefix,cur_class_name,
                               VS_TAGFILTER_PROTO,
                               true, case_sensitive, true, GVindex);
   } else {
      num_matches = _do_default_get_matches(tag_prefix,cur_class_name,
                                            VS_TAGFILTER_PROC,
                                            false, case_sensitive, true);
   }

   // create a hash table of proc names
   boolean proc_matches:[];
   int i,n=tag_get_num_of_matches();
   for (i=1; i<=n; ++i) {
      _str caption = tag_tree_make_caption_fast(VS_TAGMATCH_match,i,true,true,false);
      caption = stranslate(caption, '', '[ \t]*[=](:v|:q|:n)','r');
      proc_matches:[caption]=true;
   }

   // list the prototypes for this class
   if (GVindex) {
      num_matches = call_index(tag_prefix,cur_class_name,
                               VS_TAGFILTER_PROTO,
                               true, case_sensitive, true, GVindex);
   } else {
      num_matches = _do_default_get_matches(tag_prefix,cur_class_name,
                                            VS_TAGFILTER_PROTO,
                                            false, case_sensitive, true);
   }
   if (num_matches <= 0) {
      _message_box('no matches found');
      return num_matches;
   }

   // filter out the matches that are no not wanted
   n=tag_get_num_of_matches();
   for (i=n; i>=1; --i) {
      _str match_class='',outer_name;
      tag_get_detail2(VS_TAGDETAIL_match_class,i,match_class);
      tag_split_class_name(class_name,class_name,outer_name);
      if (!pos(cur_class_name,match_class)) {
         tag_remove_match(i);
         continue;
      }
      _str caption = tag_tree_make_caption_fast(VS_TAGMATCH_match,i,true,true,false);
      caption = stranslate(caption, '', '[ \t]*[=](:v|:q|:n)','r');
      if (proc_matches._indexin(caption)) {
         tag_remove_match(i);
      }
   }

   // create list of captions and tag information
   num_matches = _list_tag_matches(nls('Select functions to implement'),
                                   true, selection_indexes);
   if (num_matches <= 0) {
      return num_matches;
   }
   int orig_line=p_line;
   call_key(ENTER);
   if (p_line > orig_line) up();
   return _do_default_generate_functions(p_col-1,0,false,in_class_scope,false,cur_class_name,cur_class_args);
}

/**
  List functions in the given class and create prototypes for
  them, carrying over any comments.

  @param class_name   class to make prototypes for functions in

  @return number of prototypes created, <0 on error.
*/
_command make_protos(_str class_name='') name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   _str cur_class_name = '';
   _str cur_class_args = '';
   _str cur_tag_name = '';
   _str cur_type_name = '';
   _str cur_parents = '';
   int cur_tag_flags = 0;
   boolean in_class_scope=false;
   case_sensitive := p_EmbeddedCaseSensitive;
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_name, context_id, cur_tag_name);
      tag_get_detail2(VS_TAGDETAIL_context_class, context_id, cur_class_name);
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, cur_type_name);
      tag_get_detail2(VS_TAGDETAIL_context_parents, context_id, cur_parents);
      tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, cur_tag_flags);

      if (tag_tree_type_is_class(cur_type_name) || tag_tree_type_is_package(cur_type_name)) {
         cur_class_name = tag_join_class_name(cur_tag_name, cur_class_name,
                                              null, case_sensitive);
         in_class_scope=true;
      }
   }

   // list the classes in the current scope if not already in a class
   _str selection_indexes = '';
   int num_matches = 0;
   if (!tag_tree_type_is_class(cur_type_name)) {
      if (class_name!='') {
         cur_class_name=class_name;
      }
   }
   // list the virtual methods for the given class
   _str tag_prefix='';
   GVindex := _FindLanguageCallbackIndex('_%s_get_matches');
   if (GVindex) {
      num_matches = call_index(tag_prefix,cur_class_name,
                               VS_TAGFILTER_PROC,
                               true, case_sensitive, true, GVindex);
   } else {
      num_matches = _do_default_get_matches(tag_prefix,cur_class_name,
                                            VS_TAGFILTER_PROC,
                                            true, case_sensitive, true);
   }
   if (num_matches <= 0) {
      _message_box('no matches found');
      return num_matches;
   }

   // create list of captions and tag information
   num_matches = _list_tag_matches(nls('Select function prototypes to create'),
                                   true, selection_indexes);
   if (num_matches <= 0) {
      return num_matches;
   }
   return _do_default_generate_functions(_get_enter_indent(),0,true,in_class_scope);
}

