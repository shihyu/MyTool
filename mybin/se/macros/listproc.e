////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45237 $
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
#import "context.e"
#import "main.e"
#import "pushtag.e"
#import "recmacro.e"
#import "seek.e"
#import "seltree.e"
#import "stdprocs.e"
#import "tags.e"
#import "treeview.e"
#import "util.e"
#import "se/tags/TaggingGuard.e"
#endregion

/** 
 * @return Returns non-zero value if the given language has 
 * support for tagging available.
 * 
 * @param lang    language type to check
 * 
 * @see push_tag
 * @see gui_make_tags
 * @see make_tags
 * 
 * @categories Search_Functions, Tagging_Functions
 */
boolean _istagging_supported(_str lang=null)
{
   return (_QTaggingSupported(p_window_id,lang) != 0);
}
/**
 * Is language-specific local variable tagging supported for
 * the given language?  If no language ID is passed (lang==null), 
 * and the current object is an editor control, use the p_LangId
 * property.  Returns true if either [lang]_list_locals or
 * [lang]_lvar_search are found.
 *
 * @param lang    (optional) language ID
 *
 * @return true if [lang]_list_locals is found, false otherwise
 */
boolean _are_locals_supported(_str lang=null)
{
   if (lang==null) {
      if (!_isEditorCtl()) {
         return(true);
      }
      lang=p_LangId;
   }
   if (lang=='') return(0);
   static _str last_lang;
   if (last_lang:==lang) {
      return(true);
   }
   status := _FindLanguageCallbackIndex('%s-list-locals',lang);
   if (status) {
      last_lang = lang;
      return(status!=0);
   }
   status = _FindLanguageCallbackIndex('%s-lvar-search',lang);
   if (status) {
      last_lang = lang;
      return(status!=0);
   }
   return(false);
}

/** 
 * @return Returns non-zero value if the given language has 
 * support for asynchronous (background) tagging.
 * 
 * @param lang    language type to check
 * @categories Search_Functions, Tagging_Functions
 */
boolean _is_background_tagging_supported(_str lang=null)
{
   if (def_background_tagging_threads == 0) return false;
   index := _FindLanguageCallbackIndex("%s_is_asynchronous_supported", lang);
   return (index > 0);
}
/**
 * @return Returns 'true' if the given background tagging feature is enabled. 
 * @param option     <ul>
 *                   <li>AUTOTAG_WORKSPACE_NO_THREADS -- DO NOT use threads for building workspace tag file
 *                   <li>AUTOTAG_BUFFERS_NO_THREADS   -- DO NOT use thread for tagging buffer or save 
 *                   <li>AUTOTAG_FILES_NO_THREADS     -- DO NOT use threads for tagging files
 *                   <li>AUTOTAG_WORKSPACE_NO_THREADS -- DO NOT use threads for tagging workspace files
 *                   <li>AUTOTAG_LANGUAGE_NO_THREADS  -- DO NOT use threads for language support tag files
 *                   <li>AUTOTAG_SILENT_THREADS       -- Report background tagging activity on status bar
 *                   </ul>
 * @categories Search_Functions, Tagging_Functions
 */
boolean _is_background_tagging_enabled(int option=0)
{
   if (def_background_tagging_threads == 0) return false;
   if ((def_autotag_flags2 & option) == option) return false;
   return true;
}
/**
 * Return the names table index for the callback function for the
 * current language, or a language which we inherit behavior from.
 * The current object should be an editor control.
 *
 * @param callback_name    name of callback to look up, with
 *                         a '%s' marker in place where the
 *                         language ID would be normally located.
 * @param lang             current language (default=p_LangId)
 *
 * @return Names table index for the callback.
 *         0 if the callback is not found or not callable.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions
 * 
 * @deprecated Use {@link _FindLanguageCallbackIndex()}.
 */
int find_ext_callback(_str callback_name, _str lang=null)
{
   if (lang==null) {
      if (!_isEditorCtl()) {
         return(0);
      }
      lang=p_LangId;
   }
   // use fast iterative 'C' callback instead of slick-C code
   return _FindLanguageCallbackIndex(callback_name,lang);
}

/**
 * Does the current language mode match or inherit 
 * behaviors from the given language?
 * The current object should be an editor control.
 *
 * @param parent     language ID to compare to
 * @param lang       current language ID (default={@link p_LangId})
 * 
 * @categories Tagging_Functions
 * @deprecated Use {@link _LanguageInheritsFrom}.
 */
boolean ext_inherits_from(_str parent, _str lang=null)
{
   return _LanguageInheritsFrom(parent, lang)? true:false;
}

static void _tagtree_callback(int reason, typeless user_data, typeless info = null)
{
   switch (reason) {
   case SL_ONINITFIRST:
      // if we have columns, then restore the widths, please
      if (ctl_tree._TreeGetNumColButtons() > 1) {
         ctl_tree._TreeRetrieveColButtonWidths(false, SELECT_TREE_RETRIEVE);
      }
      break;
   case SL_ONCLOSE:
      // save our column widths - we'll be glad we did
      if (ctl_tree._TreeGetNumColButtons() > 1) {
         ctl_tree._TreeAppendColButtonWidths(false, SELECT_TREE_RETRIEVE);
      }
      break;
   }
}

static _str _taglist_callback(int reason,var result,typeless key)
{
   if (reason==SL_ONDEFAULT) {  // Enter key
      result=_sellist.p_line-1;
      return(1);
   }
   return("");
}

static void _TaglistGetIndexList(_str (&IndexList)[],_str (&list)[], typeless (&picList)[] = null)
{
   int i;
   for (i=0;i<list._length();++i) {
      parse list[i] with list[i] " - " IndexList[i];
      if (picList != null) {
         parse IndexList[i] with IndexList[i] " - " picList[i];
      }
   }
}

//Takes off types and appends the index to the end of the line
//Also switches function names like MYCLASS::MemberFunction() to
//MemberFunction() - MYCLASS
static void _TaglistGetNoTypeList(_str (&list)[], int (&picList)[] = null)
{
   int i;
   for (i=0;i<list._length();++i) {
      list[i]=strip(list[i]);
      int paren_pos=pos('(',list[i]);
      if (paren_pos) {
         for (;;) {
            _str ch=substr(list[i],paren_pos-1,1);
            if (ch!=" "&&ch!="\t") break;
            list[i]=substr(list[i],1,paren_pos-2):+substr(list[i],paren_pos);
            paren_pos=pos('(',list[i]);
         }
      }
      int p=pos(' ',list[i]);
      if (p) {
         while (p < pos('(',list[i]) && p < pos('<',list[i])) {
            parse list[i] with . list[i];
            p=pos(' ',list[i]);
            if (!p) break;
         }
      }
      while (substr(list[i],1,1)=='*') {
         list[i]=substr(list[i],2);
      }
      if (pos('::',list[i])) {
         _str ClassName,MemberFunctionName;
         parse list[i] with ClassName '::' MemberFunctionName;
         list[i]=MemberFunctionName"\t"ClassName;
      }
      list[i]=list[i]' - 'i;
      if (picList != null) {
         list[i] = list[i]' - 'picList[i];
      }
   }
}
/**
 * Scans the current buffer for tags and displays the tags in a selection 
 * list.  Only functions are listed.  You may select a tag to go to.  Unlike the 
 * <b>push_tag</b> and <b>find_tag</b> commands, this function does not require 
 * a tags file.  Currently the C, C++, Pascal, REXX, AWK, Modula-2, dBASE, 
 * Cobol, Fortran, Ada, and Assembly languages are supported.
 * See "tags.e" for information on adding support for other
 * languages.
 *  
 * @param options    use 'a' to show all tags, not just procs 
 *  
 * @return Returns 0 if successful user selected to go to a tag.
 * 
 * @see push_tag
 * @see find_tag
 * @see find_proc
 * @see make_tags
 * @see gui_make_tags
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Miscellaneous_Functions
 * 
 */
_command list_tags(_str options="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_TAGGING)
{
   int was_recording=_macro();
   int wid = p_window_id;
   if ( !_istagging_supported() ) {
      _message_box(nls("No tagging support function for '%s'",p_mode_name));
      return(1);
   }

   message(nls('Searching for procedures...'));
   _UpdateContext(true,true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // need lots of lists
   _str tagnameList[];
   int  idList[];
   _str indexList[];
   int picList[];

   _str type_name;
   _str tag_name;
   _str file_name;
   _str class_name;
   _str signature;
   _str return_type;
   int start_line_no;
   int start_seekpos;
   int scope_line_no;
   int scope_seekpos;
   int end_line_no;
   int end_seekpos;
   int tag_flags;

   //
   showAllTags := (lowcase(options):=='a');
   int i,n=tag_get_num_of_context();
   columns := false;
   for (i=1; i<=n; i++) {
      // is this a function, procedure, or prototype?

      tag_get_detail2(VS_TAGDETAIL_context_type,i,type_name);
      if (showAllTags || tag_tree_type_is_func(type_name)) {
         tagnameList[tagnameList._length()]=tag_tree_make_caption_fast(VS_TAGMATCH_context,i,true,true,false);
         idList[idList._length()]=i;

         tag_get_detail2(VS_TAGDETAIL_context_flags,i,tag_flags);
         tag_tree_get_bitmap(0,0,type_name,'',tag_flags,auto leaf_flag,auto pic);
         picList[picList._length()] = pic;

         columns = columns || (pos("::", tagnameList[tagnameList._length() - 1]) > 0);
      }
   }

   clear_message();
   _TaglistGetNoTypeList(tagnameList, picList);  // Add original indexes to end of list
   tagnameList._sort('i');
   _TaglistGetIndexList(indexList,tagnameList, picList);
   if ( tagnameList._length() > 0 ) {
      colFlags := '';
      colNames := '';
      if (columns) {
         colNames = ',';
         colFlags = (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT) :+ ',' :+  (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT);
      }
      i = (int)select_tree(tagnameList,                       // caption array
                            indexList,                         // key array
                            picList,                           // picture index array
                            picList,                           //
                            null,                              // select array
                            _tagtree_callback,                 // callback
                            null,                              // user data
                            nls("Tags in Current File"),       // caption
                            SL_SELECTCLINE | SL_XY_WIDTH_HEIGHT,        // sl flags
                            colNames,                          // column names
                            colFlags,                          // column flags
                            true,                              // modal
                            '',                                // help item
                            'list_tags');                      // retrieve name
      if (i!="" && i >= 0 && i < idList._length()) {
         i = idList[i];

         tag_get_context(i,tag_name,type_name,file_name,
                         start_line_no,start_seekpos,scope_line_no,
                         scope_seekpos,end_line_no,end_seekpos,
                         class_name,tag_flags,signature,return_type);

         _str proc_name=tag_tree_compose_tag(tag_name,class_name,type_name,0,signature);
         // Need macro which does push tag in current file.
         _macro('m',was_recording);
         _macro_delete_line();
         _macro_call("push_bookmark");
         _macro_call("goto_context_tag",proc_name);
         //This made macro recording wrong
         push_bookmark();
         goto_line(start_line_no);
         _nrseek(start_seekpos);
      }
   } else {
      _message_box(nls('No tags found'));
   }
   p_window_id = wid;
   p_window_id._set_focus();
   return(1);
}
_command list_locals() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int was_recording=_macro();
   if (! _are_locals_supported()) {
      _message_box(nls("No local variable tagging support function for '%s'",p_mode_name));
      return(1);
   }

   message(nls('Searching for local variables...'));
   _UpdateContext(true,true);
   _UpdateLocals(true,true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // need lots of lists
   _str tagnameList[];
   int  idList[];
   _str indexList[];
   int i, n=tag_get_num_of_locals();
   for (i=1; i<=n; i++) {
      // is this a function, procedure, or prototype?
      tagnameList[tagnameList._length()]=tag_tree_make_caption_fast(VS_TAGMATCH_local,i,true,true,false);
      idList[idList._length()]=i;
   }

   clear_message();
   _TaglistGetNoTypeList(tagnameList);  // Add original indexes to end of list
   tagnameList._sort('i');
   _TaglistGetIndexList(indexList,tagnameList);
   if ( tagnameList._length() > 0 ) {
      i=show("_sellist_form -mdi -modal -reinit",
                  nls("Local Variables in Current Proc"),
                  SL_DEFAULTCALLBACK|SL_SELECTCLINE,
                  tagnameList,
                  "",
                  "",  // help item name
                  "",  // font
                  _taglist_callback  // Call back function
                 );
      if (i!="") {
         i = idList[(int)indexList[i]];
         VS_TAG_BROWSE_INFO cm;
         tag_get_local_info(i, cm);
         _str proc_name=tag_tree_compose_tag(cm.member_name,cm.class_name,cm.type_name,0,cm.arguments,cm.return_type);
         // Need macro which does push tag in current file.
         _macro('m',was_recording);
         _macro_delete_line();
         _macro_call("push_bookmark");
         _macro_call("goto_context_tag",proc_name);
         //This made macro recording wrong
         push_bookmark();
         goto_line(cm.line_no);
         _nrseek(cm.seekpos);
      }
   } else {
      _message_box(nls('No local variables found'));
   }
   _UpdateLocals(true);
   return(1);
}

/**
 * Is language-specific statement tagging supported for
 * the given language?  If no language ID is passed (lang==null), 
 * and the current object is an editor control, use the p_LangId
 * property.
 * <p>
 * Since list-statements is done as a part of list-tags, the
 * way to indicate that list-statements is supported for a
 * language is to implement a '[lang]-are-statements-supported'
 * function which returns 'true'.
 *
 * @param lang   (optional) language to check
 *
 * @return true if list statements is supported, false otherwise.
 */
int _are_statements_supported(_str lang=null)
{
   if (lang==null) {
      if (!_isEditorCtl()) {
         return(0);
      }
      lang=p_LangId;
   }
   if (lang=='') return(0);
   static _str last_lang;
   if (last_lang:==lang) {
      return(1);
   }
   status := _FindLanguageCallbackIndex("%s-are-statements-supported",lang);
   if (status) {
      last_lang = lang;
      return(status);
   }
   return(0);
}

_command list_statements() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int was_recording=_macro();
   if (! _are_statements_supported()) {
      _message_box(nls("No statement tagging support function for '%s'",p_mode_name));
      return(1);
   }

   message(nls('Searching for statements...'));
   _UpdateContext(true,true, VS_UPDATEFLAG_context|VS_UPDATEFLAG_statement);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   _str type_name;
   _str tag_name;
   _str file_name;
   _str class_name;
   _str signature;
   _str return_type;
   int start_line_no;
   int start_seekpos;
   int scope_line_no;
   int scope_seekpos;
   int end_line_no;
   int end_seekpos;
   int tag_flags;

   // need lots of lists
   _str tagnameList[];
   int  idList[];
   _str indexList[];

   int i, n=tag_get_num_of_context();
   // Filter out contexts
   for (i=1; i<=n; i++) {
      tag_get_detail2(VS_TAGDETAIL_context_type,i,type_name);
      if ( tag_tree_type_is_statement(type_name) ) {
         tagnameList[tagnameList._length()]=tag_tree_make_caption_fast(VS_TAGMATCH_context,i,true,true,false);
         idList[idList._length()]=i;
      }
   }

   clear_message();
   _TaglistGetNoTypeList(tagnameList);  // Add original indexes to end of list
   tagnameList._sort('i');
   _TaglistGetIndexList(indexList,tagnameList);
   if ( tagnameList._length() > 0 ) {

      i=show("_sellist_form -mdi -modal -reinit",
                  nls("Statements in Current File"),
                  SL_DEFAULTCALLBACK|SL_SELECTCLINE,
                  tagnameList,
                  "",
                  "",  // help item name
                  "",  // font
                  _taglist_callback  // Call back function
                 );
      if (i!="") {
         i = idList[(int)indexList[i]];
         tag_get_context(i,tag_name,type_name,file_name,
                         start_line_no,start_seekpos,scope_line_no,
                         scope_seekpos,end_line_no,end_seekpos,
                         class_name,tag_flags,signature,return_type);

         _str proc_name=tag_tree_compose_tag(tag_name,"","",0,signature);
         // Need macro which does push tag in current file.
         _macro('m',was_recording);
         _macro_delete_line();
         _macro_call("push_bookmark");
         _macro_call("goto_context_tag",proc_name);
         //This made macro recording wrong
         push_bookmark();
         goto_line(start_line_no);
         _nrseek(start_seekpos);
      }
   } else {
      _message_box(nls('No statements found'));
   }

   _UpdateContext(true,true, VS_UPDATEFLAG_context|VS_UPDATEFLAG_statement);
   return(1);
}
