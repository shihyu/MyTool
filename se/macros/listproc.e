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
#import "cbrowser.e"
#import "context.e"
#import "help.e"
#import "main.e"
#import "pushtag.e"
#import "recmacro.e"
#import "seek.e"
#import "seltree.e"
#import "slickc.e"
#import "stdprocs.e"
#import "tagform.e"
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
 * @see push_alttag 
 * @see find_tag 
 * @see gui_make_tags
 * @see make_tags
 * 
 * @categories Search_Functions, Tagging_Functions
 */
bool _istagging_supported(_str lang=null)
{
   if (lang==null || length(lang)==0) {
      if (!_isEditorCtl()) return false;
      lang=p_LangId;
   }
   if (find_index("tag_lang_has_list_tags", PROC_TYPE) > 0) {
      if (tag_lang_has_list_tags(lang)) return true;
   }
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
bool _are_locals_supported(_str lang=null)
{
   if (lang==null || length(lang)==0) {
      if (!_isEditorCtl()) return false;
      lang=p_LangId;
   }
   if (find_index("tag_lang_has_list_tags", PROC_TYPE) > 0) {
      if (tag_lang_has_list_locals(lang)) return true;
   }
   return (_QLocalsSupported(p_window_id,lang) != 0);
}

/** 
 * @return Returns non-zero value if the given language has 
 * support for asynchronous (background) tagging.
 * 
 * @param lang    language type to check
 * @categories Search_Functions, Tagging_Functions
 */
bool _is_background_tagging_supported(_str lang=null)
{
   if (def_background_tagging_threads == 0) return false;
   if (def_autotag_flags2 & AUTOTAG_DISABLE_ALL_THREADS) return false;
   if (def_autotag_flags2 & AUTOTAG_DISABLE_ALL_BG) return false;

   if (lang==null || length(lang)==0) {
      if (!_isEditorCtl()) return false;
      lang=p_LangId;
   }
   if (find_index("tag_lang_has_list_tags", PROC_TYPE) > 0) {
      if (tag_lang_has_list_tags(lang)) return true;
   }

   index := _FindLanguageCallbackIndex("%s_is_asynchronous_supported", lang);
   return (index > 0);
}

/** 
 * @return Returns non-zero value if the given language has 
 * tagging support for creating a token list for the current file. 
 * 
 * @param lang    language type to check
 * @categories Search_Functions, Tagging_Functions
 */
bool _is_tokenlist_supported(_str lang=null)
{
   if (!_haveContextTagging()) {
      return false;
   }
   if (lang==null || length(lang)==0) {
      if (!_isEditorCtl()) return false;
      lang=p_LangId;
   }

   if (find_index("tag_lang_has_list_tags", PROC_TYPE) > 0) {
      if (tag_lang_has_tokenlist_support(lang)) return true;
   }

   if (lang=="") return(false);
   static _str last_lang;
   if (last_lang:==lang) {
      return(true);
   }

   index := _FindLanguageCallbackIndex("%s_is_tokenlist_supported", lang);
   if (index <= 0) {
      return(false);
   }

   status := call_index(index);
   if (status > 0) {
      last_lang = lang;
      return(status);
   }

   return(false);
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
bool _is_background_tagging_enabled(int option=0)
{
   if (!_haveContextTagging()) {
      return false;
   }
   if (def_background_tagging_threads == 0) return false;
   if (def_autotag_flags2 & AUTOTAG_DISABLE_ALL_THREADS) return false;
   if (def_autotag_flags2 & AUTOTAG_DISABLE_ALL_BG) return false;
   if (option && (def_autotag_flags2 & option) == option) return false;
   return true;
}
/** 
 * @return Returns non-zero value if the given language has 
 * support for positional keyword coloring.
 * 
 * @param lang    language type to check
 * @categories Search_Functions, Tagging_Functions
 */
bool _are_positional_keywords_supported(_str lang=null)
{
   if (lang==null || length(lang)==0) {
      if (!_isEditorCtl()) return false;
      lang=p_LangId;
   }
   if (find_index("tag_lang_has_list_tags", PROC_TYPE) > 0) {
      if (tag_lang_has_positional_keywords_support(lang)) return true;
   }

   if (lang=="") return(false);
   static _str last_lang;
   if (last_lang:==lang) {
      return(true);
   }

   index := _FindLanguageCallbackIndex("%s_positional_keywords_supported", lang);
   if (index <= 0) {
      return(false);
   }

   status := call_index(index);
   if (status > 0) {
      last_lang = lang;
      return(status);
   }

   return(false);
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
   if (lang==null || length(lang)==0) {
      if (!_isEditorCtl()) return 0;
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
bool ext_inherits_from(_str parent, _str lang=null)
{
   return _LanguageInheritsFrom(parent, lang)? true:false;
}

static void _tagtree_callback(int reason, typeless user_data, typeless info = null)
{
   switch (reason) {
   case SL_ONINITFIRST:
      // if we have columns, then restore the widths, please
      ctl_tree.p_LevelIndent = 0;
      ctl_tree.p_after_pic_indent_x = 0;
      if (ctl_tree._TreeGetNumColButtons() > 1) {
         // first restore the column widths they had originally
         tree_width := ctl_tree.p_width;
         ctl_tree._TreeRetrieveColButtonWidths(false, _PUSER_SELECT_TREE_RETRIEVE());
         int old_widths[];
         old_widths[0] = old_widths[1] = old_widths[2] = 0;
         n := ctl_tree._TreeGetNumColButtons();
         for (i:=0; i<n; i++) {
            ctl_tree._TreeGetColButtonInfo(i, old_widths[i]);
         }
         // now resize all the columns according to the data and track that
         ctl_tree._TreeSizeColumnToContents(-1);
         int new_widths[];
         new_widths[0] = new_widths[1] = new_widths[2] = 0;
         for (i=0; i<n; i++) {
            ctl_tree._TreeGetColButtonInfo(i, new_widths[i]);
         }
         // check if new column sizes are too big to fit in current tree width
         while (new_widths[0] + new_widths[1] + new_widths[2] + 210 > tree_width) {
            // try shrinking line number column to fit
            if (old_widths[2] < new_widths[2]) {
               new_widths[2] = old_widths[2];
               continue;
            }
            // now try shrinking class column to fit
            if (old_widths[1] < new_widths[1]) {
               new_widths[1] = old_widths[1];
               continue;
            }
            // finally, try shrinking the symbol name to required size
            new_widths[0] = tree_width - 60 - new_widths[1] - new_widths[2];
            if (new_widths[0] < 0) new_widths[0] = old_widths[0];
            break;
         }
         // add an extra column to work around tree control's column size issues
         ctl_tree._TreeSetColButtonInfo(n,0,0,0,"");
         // now drop in the new column sizes
         for (i=0; i<n; i++) {
            ctl_tree._TreeSetColButtonInfo(i, new_widths[i]);
         }
         // delete the extra column button
         ctl_tree._TreeDeleteColButton(n);
      }
      break;
   case SL_ONCLOSE:
      // save our column widths - we'll be glad we did
      if (ctl_tree._TreeGetNumColButtons() > 1) {
         ctl_tree._TreeAppendColButtonWidths(false, _PUSER_SELECT_TREE_RETRIEVE());
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

static void _TaglistGetIndexList(_str (&list)[], typeless (&IndexList)[], typeless (&picList)[], typeless (&overlayList)[])
{
   for (i:=0; i<list._length(); ++i) {
      parse list[i] with list[i] "\n@" IndexList[i] "\n#" picList[i] "\n#" overlayList[i];;
   }
}

//Takes off types and appends the index to the end of the line
static void _TaglistGetNoTypeList(_str (&list)[], _str (&indexList)[], int (&picList)[], int (&overlayList)[])
{
   int i;
   for (i=0;i<list._length();++i) {
      list[i]=strip(list[i]);
      paren_pos := pos("(",list[i]);
      if (paren_pos) {
         for (;;) {
            ch := substr(list[i],paren_pos-1,1);
            if (ch!=" "&&ch!="\t") break;
            list[i]=substr(list[i],1,paren_pos-2):+substr(list[i],paren_pos);
            paren_pos=pos("(",list[i]);
         }
      }
      p := pos(" ",list[i]);
      if (p) {
         while (p < pos("(",list[i]) && p < pos("<",list[i])) {
            parse list[i] with . list[i];
            p=pos(" ",list[i]);
            if (!p) break;
         }
      }
      while (substr(list[i],1,1)=="*") {
         list[i]=substr(list[i],2);
      }
      // append other index names
      list[i] :+= "\n@" indexList[i] "\n#" picList[i] "\n#" overlayList[i];
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
_command list_tags(_str options="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int was_recording=_macro();
   wid := p_window_id;
   if ( !_istagging_supported() ) {
      _message_box(nls("No tagging support function for '%s'",p_mode_name));
      return(1);
   }

   message(nls("Searching for procedures..."));

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true,true);
   cb_prepare_expand(0, 0, TREE_ROOT_INDEX);

   // need lots of lists
   _str tagnameList[];
   _str indexList[];
   int picList[];
   int overlayList[];

   // put together list of symbols 
   showAllTags := (lowcase(options):=="a");
   n := tag_get_num_of_context();
   for (i:=1; i<=n; i++) {
      // is this a function, procedure, or prototype?
      tag_get_detail2(VS_TAGDETAIL_context_type,i,auto type_name);
      if (showAllTags || tag_tree_type_is_func(type_name)) {
         tag_get_detail2(VS_TAGDETAIL_context_line,i,auto start_line_no);
         caption := tag_tree_make_caption_fast(VS_TAGMATCH_context, i,
                                               include_class:true,
                                               include_args:true,
                                               include_tab:true);
         if (!pos("\t", caption)) caption :+= "\t";
         tagnameList :+= caption :+ "\t" start_line_no;
         indexList :+= i;

         tag_get_detail2(VS_TAGDETAIL_context_flags,i,auto tag_flags);
         pic := tag_get_bitmap_for_type(tag_get_type_id(type_name), tag_flags, auto pic_overlay);
         picList :+= pic;
         overlayList :+= pic_overlay;
      }
   }

   clear_message();
   _TaglistGetNoTypeList(tagnameList, indexList, picList, overlayList);  // Add original indexes to end of list
   tagnameList._sort('i');
   _TaglistGetIndexList(tagnameList, indexList, picList, overlayList);
   if ( tagnameList._length() > 0 ) {
      colNames := "Name,Class,Line";
      colFlags := (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT) :+ "," :+  (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT) :+ "," :+  (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_SORT);
      choice := select_tree(tagnameList,                       // caption array
                            indexList,                         // key array
                            picList,                           // picture index array
                            overlayList,                       //
                            null,                              // select array
                            _tagtree_callback,                 // callback
                            null,                              // user data
                            nls("Tags in Current File"),       // caption
                            SL_SELECTCLINE | SL_XY_WIDTH_HEIGHT | SL_COMBO | SL_USE_OVERLAYS | SL_DEFAULTCALLBACK,        // sl flags
                            colNames,                          // column names
                            colFlags,                          // column flags
                            true,                              // modal
                            "",                                // help item
                            "list_tags");                      // retrieve name
      if (choice!="" && choice >= 1 && choice <= tag_get_num_of_context()) {
         tag_get_context_info((int)choice, auto cm);
         proc_name := tag_compose_tag_browse_info(cm);

         // Need macro which does push tag in current file.
         _macro('m',was_recording);
         _macro_delete_line();
         _macro_call("push_bookmark");
         _macro_call("goto_context_tag", proc_name);
         //This made macro recording wrong
         push_bookmark();
         goto_line(cm.line_no);
         _nrseek(cm.seekpos);
      }
   } else {
      _message_box(nls("No tags found"));
   }
   p_window_id = wid;
   p_window_id._set_focus();
   return(1);
}
_command list_locals(_str options="a") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int was_recording=_macro();
   wid := p_window_id;
   embedded_status := _EmbeddedStart(auto orig_values);
   if (! _are_locals_supported()) {
      if (embedded_status==1) _EmbeddedEnd(orig_values);
      _message_box(nls("No local variable tagging support function for '%s'",p_mode_name));
      return(1);
   }

   message(nls("Searching for local variables..."));

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true,true);
   _UpdateLocals(true,true);
   
   cur_seekpos := 0;
   if (_isEditorCtl()) {
      cur_seekpos = (int)_QROffset();
   }

   // need lots of lists
   _str tagnameList[];
   _str indexList[];
   int picList[];
   int overlayList[];

   // put together list of symbols 
   showAllTags := (lowcase(options):=="a" || lowcase(options):=="h");
   showIgnoredTags := (lowcase(options):=="h");
   n := tag_get_num_of_locals();
   for (i:=1; i<=n; i++) {
      // is this a function, procedure, or prototype?
      tag_get_detail2(VS_TAGDETAIL_local_type,i,auto type_name);
      tag_get_detail2(VS_TAGDETAIL_local_flags,i,auto tag_flags);
      if (!showIgnoredTags && (tag_flags & SE_TAG_FLAG_IGNORE)) continue;
      if (showAllTags || tag_is_local_in_scope(i, cur_seekpos)) {
         tag_get_detail2(VS_TAGDETAIL_local_line, i, auto start_line_no);
         caption := tag_tree_make_caption_fast(VS_TAGMATCH_local, i,
                                               include_class:true,
                                               include_args:true,
                                               include_tab:false);
         tagnameList :+= caption :+ "\t" start_line_no;
         indexList :+= i;

         pic := tag_get_bitmap_for_type(tag_get_type_id(type_name), tag_flags, auto pic_overlay);
         picList :+= pic;
         overlayList :+= pic_overlay;
      }
   }

   // leave embedded mode
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
      
   clear_message();
   _TaglistGetNoTypeList(tagnameList, indexList, picList, overlayList);  // Add original indexes to end of list
   tagnameList._sort('i');
   _TaglistGetIndexList(tagnameList, indexList, picList, overlayList);
   if ( tagnameList._length() > 0 ) {
      colNames := "Name,Line";
      colFlags := (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT) :+ "," :+  (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_SORT);
      choice := select_tree(tagnameList,                       // caption array
                            indexList,                         // key array
                            picList,                           // picture index array
                            picList,                           //
                            null,                              // select array
                            _tagtree_callback,                 // callback
                            null,                              // user data
                            nls("Locals in Current Scope"),    // caption
                            SL_SELECTCLINE | SL_XY_WIDTH_HEIGHT | SL_COMBO | SL_USE_OVERLAYS | SL_DEFAULTCALLBACK,        // sl flags
                            colNames,                          // column names
                            colFlags,                          // column flags
                            true,                              // modal
                            "",                                // help item
                            "list_locals");                    // retrieve name
      if (choice!="" && choice >= 1 && choice <= tag_get_num_of_locals()) {
         tag_get_local_info((int)choice, auto cm);
         proc_name := tag_compose_tag_browse_info(cm);

         // Need macro which does push tag in current file.
         _macro('m',was_recording);
         _macro_delete_line();
         _macro_call("push_bookmark");
         _macro_call("goto_context_tag", proc_name);
         //This made macro recording wrong
         push_bookmark();
         goto_line(cm.line_no);
         _nrseek(cm.seekpos);
      }
   } else {
      _message_box(nls("No local variables found"));
   }
   p_window_id = wid;
   p_window_id._set_focus();
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
bool _are_statements_supported(_str lang=null)
{
   if (lang==null || length(lang)==0) {
      if (!_isEditorCtl()) return false;
      lang=p_LangId;
   }

   if (find_index("tag_lang_has_list_tags", PROC_TYPE) > 0) {
      if (tag_lang_has_list_statements(lang)) return true;
   }

   static _str last_lang;
   if (last_lang:==lang) {
      return true;
   }

   index := _FindLanguageCallbackIndex("%s-are-statements-supported",lang);
   if (index <= 0) {
      return false;
   }

   status := call_index(index);
   if (status > 0) {
      last_lang = lang;
      return true;
   }

   return false;
}

_command list_statements(_str options="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Statement tagging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   int was_recording=_macro();
   wid := p_window_id;
   if ( !_istagging_supported() ) {
      _message_box(nls("No tagging support function for '%s'",p_mode_name));
      return(1);
   }
   if (! _are_statements_supported()) {
      _message_box(nls("No statement tagging support function for '%s'",p_mode_name));
      return(1);
   }

   message(nls("Searching for statements..."));

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true,true);
   _UpdateStatements(true,true);

   // find range of current function
   cur_start_seekpos := 0;
   cur_end_seekpos   := MAXINT;
   statement_id := tag_current_statement();
   if (statement_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, statement_id, cur_start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_statement_end_seekpos, statement_id, cur_end_seekpos);
   }

   // need lots of lists
   _str tagnameList[];
   _str indexList[];
   int picList[];
   int overlayList[];

   // put together list of symbols 
   showAllTags := (lowcase(options):=="a");
   n := tag_get_num_of_statements();
   for (i:=1; i<=n; i++) {
      // is this a function, procedure, or prototype?
      tag_get_detail2(VS_TAGDETAIL_statement_type,i,auto type_name);
      if ( tag_tree_type_is_statement(type_name) ) {
         tag_get_detail2(VS_TAGDETAIL_statement_line,i,auto start_line_no);
         tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos,i,auto start_seekpos);
         tag_get_detail2(VS_TAGDETAIL_statement_end_seekpos,i,auto end_seekpos);
         if (showAllTags || (start_seekpos <= cur_end_seekpos && end_seekpos >= cur_start_seekpos)) {
            caption := tag_tree_make_caption_fast(VS_TAGMATCH_statement, i,
                                                  include_class:true,
                                                  include_args:true,
                                                  include_tab:false);
            tagnameList :+= caption :+ "\t" start_line_no;
            indexList :+= i;

            tag_get_detail2(VS_TAGDETAIL_statement_flags,i,auto tag_flags);
            pic := tag_get_bitmap_for_type(tag_get_type_id(type_name), tag_flags, auto pic_overlay);
            picList :+= pic;
            overlayList :+= pic_overlay;
         }
      }
   }

   clear_message();
   _TaglistGetNoTypeList(tagnameList, indexList, picList, overlayList);  // Add original indexes to end of list
   tagnameList._sort('i');
   _TaglistGetIndexList(tagnameList, indexList, picList, overlayList);
   if ( tagnameList._length() > 0 ) {
      colNames := "Name,Line";
      colFlags := (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT) :+ "," :+  (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_SORT);
      choice := select_tree(tagnameList,                       // caption array
                            indexList,                         // key array
                            picList,                           // picture index array
                            overlayList,                       //
                            null,                              // select array
                            _tagtree_callback,                 // callback
                            null,                              // user data
                            nls("Statements in Current ":+(showAllTags? "File":"Scope")),       // caption
                            SL_SELECTCLINE | SL_XY_WIDTH_HEIGHT | SL_COMBO | SL_USE_OVERLAYS| SL_DEFAULTCALLBACK,        // sl flags
                            colNames,                          // column names
                            colFlags,                          // column flags
                            true,                              // modal
                            "",                                // help item
                            "list_statements");                // retrieve name
      _UpdateStatements(true,true);
      if (choice!="" && choice >= 1 && choice <= tag_get_num_of_statements()) {
         tag_get_statement_browse_info((int)choice, auto cm);
         proc_name := tag_compose_tag_browse_info(cm);

         // Need macro which does push tag in current file.
         _macro('m',was_recording);
         _macro_delete_line();
         _macro_call("push_bookmark");
         _macro_call("goto_context_tag", proc_name, "", 1);
         //This made macro recording wrong
         push_bookmark();
         goto_line(cm.line_no);
         _nrseek(cm.seekpos);
      }
   } else {
      _message_box(nls("No statements found"));
   }
   p_window_id = wid;
   p_window_id._set_focus();
   return(1);
}

