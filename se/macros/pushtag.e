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
#import "bind.e"
#import "bookmark.e"
#import "cbrowser.e"
#import "context.e"
#import "ctags.e"
#import "error.e"
#import "files.e"
#import "help.e"
#import "javadoc.e"
#import "listproc.e"
#import "main.e"
#import "notifications.e"
#import "picture.e"
#import "proctree.e"
#import "recmacro.e"
#import "refactor.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagcalls.e"
#import "tagfind.e"
#import "taggui.e"
#import "tagrefs.e"
#import "tags.e"
#import "tagwin.e"
#import "tbclass.e"
#import "tbcmds.e"
#import "treeview.e"
#import "util.e"
#import "xmldoc.e"
#import "se/search/SearchResults.e"
#endregion

static const KEYPRESSTOTAGMATCHINGDELAY=100;
static const PREFIXMATCHEDMAXLISTCOUNT=200;
static const COLWIDTHGAP=200;
static const PREFIXMINCHARCOUNT=1;

static int pushTgBmTimerID = -1;
static int pushTgBmIgnoreChange = 0;

/**
 * Return a pointer to the bookmark stack.
 * The bookmark stack is stored in the dialog info for _mdi.
 * This way the data is transient and not effected by module
 * reloads and never written to the state file.
 */
static STRARRAY *getBookmarkStackPtr()
{
   return _GetDialogInfoHtPtr("BookmarkStack", _mdi);
}

/** 
 * Remove a pushed bookmark from the bookmark stack.  
 */ 
void _BookmarkStackRemove(_str name)
{
   STRARRAY *bm_stack = getBookmarkStackPtr();
   if (bm_stack != null) {
      n := bm_stack->_length();
      for (i:=0; i < n; ++i) {
         if ((*bm_stack)[i] == name) {
            bm_stack->_deleteel(i);
            break;
         }
      }
   }
}

/**
 * Maximum number of tag bookmarks.
 * 
 * @default 15
 * @categories Configuration_Variables
 */
int def_max_bm_tags=15;

/**
 * Show bitmaps for tag bookmarks.
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_show_bm_tags=true;

/**
 * When on, when a buffer is closed (quit), remove any
 * pushed bookmarks remaining in that file.
 * This option is helpful for buffer management,
 * because it prevents buffers which were explicitly
 * closed from coming back when you pop up out of
 * your bookmark stack.
 * 
 * @default false
 * @categories Configuration_Variables
 */
bool def_cleanup_pushed_bookmarks_on_quit=false;

/**
 * Use the classic "Go to Definition" dialog instead of
 * the new "Find Symbol" tool window for
 * {@link gui_push_tag}.
 * 
 * @default false
 * @categories Configuration_Variables
 */
bool def_use_old_goto_definition_dialog=false;

/**
 * Find tag preferences (bitset of VS_FIND_TAG_*).
 * These flags control whether find tag navigates to
 * definitions or declarations first?
 * <ul>
 *    <li>0 -- no bias, prompt for all tags first
 *    <li>1 -- bias to go to definitions first, then declarations
 *    <li>2 -- bias to go to declarations first, then declarations
 * </ul>
 * 
 * @default 0
 * @categories Configuration_Variables
 */
int def_find_tag_flags = 0;

/**
 * List of tag matches found from last 'find_tag'
 * <p>
 * Repeatedly hitting push-tag will cycle forward through these items
 * Hitting pop-tag will back up to the previous definitions.
 * When you pop backwards over the first match, it will be treated
 * as a regular pop-bookmark and the match set will be cleared.
 * When you push-tag forward past the last item, it will cycle back
 * to the first tiem found.
 */
static VS_TAG_BROWSE_INFO gPushTagMatches[];
static int gPushTagItem=0;
static long gPushTagOffset=0;

/**
 * Hash table of reference counts for buffers that were
 * jumped to using tagging.
 */
static int gPushTagDestinations:[];
static typeless gPushTagDestinationModified:[];
static bool gPushTagDestinationAlreadyOpen:[];

_metadata enum VSAutocloseOptions {
   VS_AUTOCLOSE_ENABLED       = 0x0001,
   VS_AUTOCLOSE_CONFIRMATION  = 0x0002,
   VS_AUTOCLOSE_DEFAULT       = 0x0003
};

/**
 * The auto-close options control when SlickEdit will automatically close a
 * file which was briefly visited using a tagging or search operation.
 * The flags consist of a bitset of VS_BUFFER_MANAGEMENT_* flags, including:
 * <ul>
 * <li><b>VS_BUFFER_MANAGEMENT_ENABLED</b> -- When enabled, if you navigate
 * away from a file that was opened using a search or tagging operation, 
 * SlickEdit will attempt to close the file unless it is modified or open in
 * another window.
 * <li><b>VS_BUFFER_MANAGEMENT_CONFIRMATION</b> -- Prompt the user if he
 * wants to close instead of just closing the file automatically.
 * </ul>
 * 
 * @default VS_BUFFER_MANAGEMENT_DEFAULT=3
 * @categories Configuration_Variables
 * 
 * @see pop_bookmark
 * @see push_tag
 * @see push_ref
 * @see find_next
 * @see find_prev
 * @see push_destination
 * @see pop_destination
 */
int def_autoclose_flags=VS_AUTOCLOSE_ENABLED;

definit()
{
   if ( arg(1)!='L' ) {
      gPushTagMatches._makeempty();
      gPushTagItem = 0;
      gPushTagOffset=0;
      gPushTagDestinations._makeempty();
      gPushTagDestinationModified._makeempty();
      gPushTagDestinationAlreadyOpen._makeempty();
   }
}

/**
 * Display a message on the message bar explaining what key(s)
 * the user can hit to pop back to the location he just jumped to.
 */
static void show_pop_bookmark_key_message()
{
   // where are pop_bookmark and push_tag?
   pop_key := _where_is("pop_bookmark");

   // create the message for what pop-bookmark will do
   pop_msg := "";
   if (pop_key == "") {
      pop_msg = "You can bind 'pop-bookmark' to a key to go back.";
   } else {
      pop_msg = "Press "pop_key" to go back.";
   }

   // put the message on the message bar
   message(pop_msg);
}

/**
 * Creates a book mark at the cursor and places it on a stack.  After
 * calling this command you may move the cursor within the same file or
 * another file and restore your original cursor position by invoking the
 * <b>pop_bookmark</b> command (Ctrl+, or "Search", "Pop
 * Bookmark").  The name of the new bookmark created is displayed.
 *
 * @param markid     named selection to create bookmark on
 * 
 * @return Returns 0 if successful.
 *
 * @see pop_bookmark
 * @see set_bookmark
 * @see toggle_bookmark
 * @see goto_bookmark
 * @see bookmark_stack 
 *
 * @appliesTo Edit_Window
 *
 * @categories Bookmark_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command push_bookmark(_str markid="", bool isReferences=false) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   // Note: This command does not work with goto_bookmark.  push_bookmark may work with
   // standard bookmarks if the user is setting markid to be the same as the standard bookmarks.
   if (markid=="") {
      markid=_alloc_selection('b');
      _select_char(markid);
   }

   // get the message prefix for bookmarks
   bm_msg := get_message(VSRC_PUSHED_BOOKMARK_NAME);
   if (bm_msg=="") bm_msg="TAG";
   bm_id := bm_msg:+1;

   // find the next available bookmark ID.
   STRARRAY *bm_stack = getBookmarkStackPtr();
   if (bm_stack != null && bm_stack->_length() > 0) {
      // stack is full, remove the item on the bottom of stack
      if (bm_stack->_length() >= def_max_bm_tags) {
         bm_id_0 := (*bm_stack)[0];
         bm_stack->_deleteel(0);
         int i=_BookmarkFind(bm_id_0,VSBMFLAG_PUSHED);
         if (i>=0) {
            _BookmarkRemove(i);
         }
      }
      // now find the next unused bookmark ID
      if (bm_stack->_length() > 0) {
         bm_id = (*bm_stack)[bm_stack->_length()-1];
         typeless num = substr(bm_id, length(bm_msg)+1);
         loop {
            ++num;
            bm_id = bm_msg:+num;
            if (_BookmarkFind(bm_id,VSBMFLAG_PUSHED) < 0) {
               break;
            }
         }
      }
   }

   // now add the new bookmark
   bm_flags := VSBMFLAG_PUSHED;
   if (def_show_bm_tags) {
      bm_flags |= VSBMFLAG_SHOWNAME;
      bm_flags |= VSBMFLAG_SHOWPIC;
   }
   if ( isReferences && !(def_references_options & VSREF_NO_AUTO_PUSH) ) {
      bm_flags |= VSBMFLAG_REFERENCES;
   }
   _BookmarkAdd(bm_id,(int)markid,bm_flags);
   if ( isReferences && !(def_references_options & VSREF_NO_AUTO_PUSH) ) {
      set_references_stack_top_bookmark(bm_id);
   }

   // and update the bookmark stack
   if (bm_stack != null) {
      (*bm_stack)[bm_stack->_length()] = bm_id;
   } else {
      STRARRAY new_bm_stack;
      new_bm_stack[0] = bm_id;
      _SetDialogInfoHt("BookmarkStack",new_bm_stack,_mdi);
   }

   // inform user about the new bookmark added
   show_pop_bookmark_key_message();
   return(0);
}
int _OnUpdate_push_tag(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_push_ref(cmdui,target_wid,command));
}
int _OnUpdate_codehelp_trace_push_tag(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_push_ref(cmdui,target_wid,command));
}
int _OnUpdate_cb_find(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_push_ref(cmdui,target_wid,command));
}
int _OnUpdate_cf(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_push_ref(cmdui,target_wid,command));
}
int _OnUpdate_push_def(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_push_ref(cmdui,target_wid,command));
}
int _OnUpdate_push_decl(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_push_ref(cmdui,target_wid,command));
}
int _OnUpdate_push_alttag(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_push_ref(cmdui,target_wid,command));
}
int _OnUpdate_push_tag_filter_overloads(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_push_ref(cmdui,target_wid,command));
}

/**
 * The <b>push_tag</b> command pushes a bookmark at the cursor
 * position and places the cursor on the source code for
 * <i>tag_name</i>.  Use the <b>pop_bookmark</b> command (Ctrl+,)
 * to return to the previous bookmark.  If <i>tag_name</i> is not
 * specified, the word at the cursor is used.  To create or modify a tag
 * file, use the <b>Tag Files dialog box</b> ("Search", "Tag Files...").
 * Your tag files will automatically be updated when you make edits.
 * The SPACE BAR and '?' keys may be used to complete the tag name.
 * For those of you working in case sensitive languages, you may (we
 * like it the ways it is) want to make tag name searching case sensitive.
 * The command "<b>set-var def-ignore-tcase 0</b>" will force all tag
 * name searching to be case insensitive.  Currently the C, C++, Pascal,
 * REXX, AWK, Modula-2, dBASE, COBOL, FORTRAN, Ada, and
 * Assembly languages are supported. See "tags.e" for
 * information on adding support for other languages.
 * <p>
 * In ISPF emulation, this command is not called when invoked from the 
 * command line.  Instead <b>ispf_f</b> (short for <b>ispf_find</b>) is called.  
 * Use <b>push_tag</b> or ("Search", "Go to Definition") to explicitly invoke 
 * the <b>f </b>command.
 *
 * @param proc_name              encoded tag name to find.  See {@link tag_tree_compose_tag}. 
 * @param extra_codehelp_flags   [default 0] 
 *                               VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION to 
 *                               to go declaration of symbol, or
 *                               VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION to
 *                               to go to declaration of symbol.
 *                               VSCODEHELPFLAG_FILTER_OVERLOADED_FUNCTIONS to
 *                               filter out non-matching function overloads. 
 *  
 * @see make_tags
 * @see find_tag
 * @see gui_make_tags
 * @see find_proc
 * @see list_tags
 * @see bookmark_stack 
 * @see push_def 
 * @see push_decl 
 * @see push_alttag 
 * @see push_tag_filter_overloads
 *
 * @appliesTo Edit_Window
 * @categories Tagging_Functions, Search_Functions
 */
_command push_tag,f(_str proc_name="", VSCodeHelpFlags extra_codehelp_flags=VSCODEHELPFLAG_NULL) name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   orig_last_index := last_index('','C');
   if (maybe_goto_next_match()) {
      last_index(orig_last_index,'C');
      return 0;
   }

   typeless mark="";
   orig_buf_id := 0;
   if (!_no_child_windows() && _isEditorCtl()) {
      mark=_alloc_selection('b');
      if ( mark<0 ) {
         return mark;
      }
      _mdi.p_child._select_char(mark);
      _ForwardBack_update();
      orig_buf_id=p_buf_id;
      _mdi.p_child.mark_already_open_destinations();
   }

   if (_GetCodehelpFlags() & VSCODEHELPFLAG_GO_TO_DEF_CASE_SENSITIVE) proc_name = "-cs "proc_name;
   status := find_tag(proc_name, false, extra_codehelp_flags);
   if (status) {
      if (orig_buf_id != 0) {
         _free_selection(mark);
      }
      last_index(orig_last_index,'C');
      return status;
   }

   if (orig_buf_id != 0) {
      if (orig_buf_id==p_buf_id) {
         _ForwardBack_push();
      }
      status=push_bookmark(mark);
   }

   gPushTagOffset=_QROffset();
   show_next_prev_match();
   _mdi.p_child.push_destination();
   last_index(orig_last_index,'C');
   return status;

}
_command codehelp_trace_push_tag(_str proc_name="") name_info(TAG_ARG','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   orig_chdebug := _chdebug;
   _chdebug = 1;
   push_tag(proc_name);
   _chdebug = orig_chdebug;

}

/**
 * The <b>push_def</b> command pushes a bookmark at the cursor position 
 * and places the cursor on the source code for the definition of
 * the symbol under the cursor. 
 *
 * @param proc_name     encoded tag name to find.  See {@link tag_tree_compose_tag}.
 *  
 * @see push_tag 
 * @see push_decl 
 * @see make_tags
 * @see find_tag
 * @see bookmark_stack 
 *
 * @appliesTo Edit_Window
 * @categories Search_Functions
 */
_command push_def(_str proc_name="") name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return push_tag(proc_name,VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION);
}
/**
 * The <b>push_decl</b> command pushes a bookmark at the cursor position 
 * and places the cursor on the source code for the declaration of
 * the symbol under the cursor. 
 *
 * @param proc_name     encoded tag name to find.  See {@link tag_tree_compose_tag}.
 *  
 * @see push_tag 
 * @see push_decl 
 * @see make_tags
 * @see find_tag
 * @see bookmark_stack 
 *
 * @appliesTo Edit_Window
 * @categories Search_Functions
 */
_command push_decl(_str proc_name="") name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return push_tag(proc_name,VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION);
}
/**
 * The <b>push_alttag</b> command pushes a bookmark at the cursor position 
 * and places the cursor on the source code for the declaration or definition 
 * of the symbol under the cursor, using preferences exactly opposite of 
 * what push-tag would do.
 *
 * @param proc_name     encoded tag name to find.  See {@link tag_tree_compose_tag}.
 *  
 * @see push_tag 
 * @see push_decl 
 * @see push_def 
 * @see make_tags
 * @see find_tag
 * @see bookmark_stack 
 *
 * @appliesTo Edit_Window
 * @categories Search_Functions
 */
_command push_alttag(_str proc_name="") name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   codehelp_flags := _GetCodehelpFlags();
   if (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION) {
      return push_tag(proc_name,VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION);
   }
   if (codehelp_flags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION) {
      return push_tag(proc_name,VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION);
   }
   return push_tag(proc_name,0);
}

/**
 * The <b>push_tag_filter_overloads</b> command pushes a bookmark at the cursor 
 * position and places the cursor on the source code (definition or declaration) 
 * for the symbol under the cursor, attempting to filter out non-matching function 
 * overloads. 
 *
 * @param proc_name     encoded tag name to find.  See {@link tag_tree_compose_tag}.
 *  
 * @see push_tag 
 * @see push_decl 
 * @see make_tags
 * @see find_tag
 * @see bookmark_stack 
 *
 * @appliesTo Edit_Window
 * @categories Search_Functions
 */
_command push_tag_filter_overloads(_str proc_name="") name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return push_tag(proc_name,VSCODEHELPFLAG_FILTER_OVERLOADED_FUNCTIONS);
}
_command codehelp_trace_push_tag_filter_overloads(_str proc_name="") name_info(TAG_ARG','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI)
{
   orig_chdebug := _chdebug;
   _chdebug = 1;
   push_tag_filter_overloads(proc_name);
   _chdebug = orig_chdebug;

}

/**
 * The <b>mou_push_tag</b> command places the cursor
 * using the mouse position, pushes a bookmark, and then
 * jumps to the symbol pointed to by the mouse.
 * It can be used to navigate source code as if it were
 * a hypertext.
 *
 * @see mou_click
 * @see push_tag
 * @see mou_push_ref
 *
 * @appliesTo Edit_Window
 * @categories Search_Functions, Mouse_Functions
 */
_command void mou_push_tag() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION|VSARG2_NOEXIT_SCROLL)
{
   mou_click();
   push_tag();
}
int _OnUpdate_mou_push_tag(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_push_tag(cmdui,target_wid,command));
}
_command void codehelp_trace_mou_push_tag() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   orig_chdebug := _chdebug;
   _chdebug = 1;
   mou_click();
   push_tag();
   _chdebug = orig_chdebug;
}
/**
 * The <b>mou_push_alttag</b> command places the cursor
 * using the mouse position, pushes a bookmark, and then
 * jumps to the symbol pointed to by the mouse.
 * It can be used to navigate source code as if it were
 * a hypertext.
 *
 * @see mou_click
 * @see push_alttag
 * @see mou_push_ref
 *
 * @appliesTo Edit_Window
 * @categories Search_Functions, Mouse_Functions
 */
_command void mou_push_alttag() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION|VSARG2_NOEXIT_SCROLL)
{
   mou_click();
   push_alttag();
}
int _OnUpdate_mou_push_alttag(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_push_tag(cmdui,target_wid,command));
}

int tag_browse_info_compare_locations(VS_TAG_BROWSE_INFO &t1, VS_TAG_BROWSE_INFO &t2)
{
   if (!_file_eq(t1.file_name, t2.file_name)) {
      return (_file_case(t1.file_name) < _file_case(t2.file_name))? -1:1;
   }
   return (t1.line_no - t2.line_no);
}

/**
 * Find symbols associated with the given symbol.  This is useful in order to 
 * map a symbol declaration to its definition, or vice-versa, or to locate all 
 * the overloads for a symbol. 
 * 
 * @param tag_files            list of tag files to search
 * @param cm                   symbol to search for
 * @param associated_symbols   (output) array of associated symbols
 * @param this_one_found_at    (output) index of 'cm' in the associated symbols
 * @param num_matches          (output) number of symbols found by tagging search
 * @param max_matches          maximum number of symbols to search for
 * @param case_sensitive       case-sensitive symbol search
 * @param visited              visited array 
 * @param depth                recursive depth 
 * 
 * @return 0 on success, &lt;0 on error.
 */
int tag_list_associated_symbols(_str (&tag_files)[], 
                                VS_TAG_BROWSE_INFO cm, 
                                VS_TAG_BROWSE_INFO (&associated_symbols)[],
                                int &this_one_found_at,
                                int &num_matches, 
                                int max_matches=VSCODEHELP_MAXFUNCTIONHELPPROTOS, 
                                bool case_sensitive=true,
                                VS_TAG_BROWSE_INFO (&visited):[]=null,
                                int depth=0)
{
   num_matches = 0;
   tag_push_matches();
   status := tag_list_symbols_in_context(cm.member_name, cm.class_name, 
                                         0, 0, tag_files, "", 
                                         num_matches, max_matches, 
                                         SE_TAG_FILTER_ANYTHING, SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_FIND_ALL|SE_TAG_CONTEXT_ACCESS_PRIVATE,
                                         true, case_sensitive, visited, depth+1);

   // check for namespace qualification
   if (cm.class_name != "") {
      // first try adding qualification
      tag_split_class_name(cm.class_name, auto inner_name, auto outer_name);
      tag_qualify_symbol_name(auto qualified_name, inner_name, outer_name,
                              cm.file_name, tag_files, case_sensitive, 
                              visited, depth+1);
      if (qualified_name != "" && tag_compare_classes(cm.class_name, qualified_name) != 0) {
         status = tag_list_in_class(cm.member_name, qualified_name, 
                                    0, 0, tag_files, 
                                    num_matches, max_matches,
                                    SE_TAG_FILTER_ANYTHING, SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_FIND_ALL|SE_TAG_CONTEXT_ACCESS_PRIVATE,
                                    true, case_sensitive, null, null, visited, depth+1);
      }
      // then try removing qualification
      if (outer_name != "" && inner_name != "" && tag_compare_classes(cm.class_name, inner_name) != 0) {
         status = tag_list_in_class(cm.member_name, inner_name, 
                                    0, 0, tag_files, 
                                    num_matches, max_matches,
                                    SE_TAG_FILTER_ANYTHING, SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_FIND_ALL|SE_TAG_CONTEXT_ACCESS_PRIVATE,
                                    true, case_sensitive, null, null, visited, depth+1);
      }
   }

   // get all matches and sort them by file location
   cm_class_name := stranslate(cm.class_name,VS_TAGSEPARATOR_package,VS_TAGSEPARATOR_class);
   if (cm.language == "" && _isEditorCtl()) cm.language = p_LangId;

   // no matches?
   n := tag_get_num_of_matches();
   if (n <= 0 && status < 0) {
      tag_pop_matches();
      return BT_RECORD_NOT_FOUND_RC;
   }

   // go through the matches and remove duplicates and non-matches.
   VS_TAG_BROWSE_INFO ci;
   bool been_there_done_that:[];
   for (i:=1; i<=n; i++) {

      // check for duplicates
      tag_get_match_browse_info(i, ci);
      key := _file_case(ci.file_name):+"\1":+ci.return_type:+"\1":+ci.type_name:+VS_TAGSEPARATOR_args:+ci.arguments;//"@":+ci.seekpos;
      if (been_there_done_that._indexin(key)) continue;
      been_there_done_that:[key] = true;

      // the symbol name and language mode must match
      if (!strieq(cm.member_name, ci.member_name)) continue;

      // the class name must be similar at least
      if (cm.class_name != ci.class_name) {
         if (cm.class_name == "" && ci.class_name != "") continue;
         if (ci.class_name == "" && cm.class_name != "") continue;
         if (cm.class_name != "" && ci.class_name != "") {
            ci_class_name := stranslate(ci.class_name,VS_TAGSEPARATOR_package,VS_TAGSEPARATOR_class);
            if (ci_class_name != cm_class_name) {
               if (!endsWith(cm_class_name,ci_class_name,true) && !endsWith(ci_class_name,cm_class_name,true)) {
                  continue;
               }
            }
         }
      }

      // we have to have a file name, and not a .jar or .dll file.
      if (ci.file_name == "") continue;
      if (_QBinaryLoadTagsSupported(ci.file_name)) continue;
      if (!file_exists(ci.file_name)) continue;

      // make sure langauge mode matches
      if (ci.language == "") ci.language = _Filename2LangId(ci.file_name);
      if (ci.language != cm.language) continue;

      // add this item to the list of matches
      associated_symbols :+= ci;
   }


   // sort the results by location and identify the symbol which matches the one we started with
   associated_symbols._sort("",0,-1,tag_browse_info_compare_locations);
   this_one_found_at = -1;
   foreach (i => ci in associated_symbols) {
      if (_file_eq(ci.file_name, cm.file_name) && ci.line_no >= cm.line_no && ci.line_no <= cm.end_line_no) {
         this_one_found_at = i;
      }
   }

   // success
   tag_pop_matches();
   return 0;
}

/** 
 * Jump to the symbol corresponding to this symbol.  For example, if the current 
 * symbol under the cursor is a function, this macro would locate the corresponding 
 * function prototype and jump to that symbol.  If the file containing that symbol 
 * is already open in the editor, the position will be left intact if it is already 
 * on the function in question. 
 *  
 * @see push_tag 
 * @see edit_associated_file
 *
 * @appliesTo Edit_Window
 * @categories Search_Functions
 */
_command void edit_associated_symbol() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_TAGGING)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Edit associated symbol");
      return;
   }

   // make sure the current symbol context is up-to-date
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContextAndTokens(true);

   // get list of tag files for this context
   tag_files := tags_filenamea();
   VS_TAG_BROWSE_INFO visited:[];
   this_one_found_at := -1;

   // find the current symbol under the cursor (the function we are in)
   VS_TAG_BROWSE_INFO options[];
   context_id := tag_current_context();
   if (context_id <= 0) {
      message("No symbol under cursor");
   }

   // find other symbols with the same name in the same class
   num_matches := 0;
   tag_get_context_info(context_id, auto cm);
   status := tag_list_associated_symbols(tag_files, cm, options, this_one_found_at, 
                                         num_matches, def_tag_max_function_help_protos,
                                         p_LangCaseSensitive, visited, 0);

   // no matches?
   if (options._length() <= 0 || (this_one_found_at>=0 && options._length() <= 1)) {
      message("No matching symbol found for '"cm.member_name"'");
      return;
   }

   // determine which symbol to go to next
   if (this_one_found_at < 0) {
      cm = options[options._length()-1];
      this_one_found_at = options._length()+1;
   } else if (this_one_found_at+1 >= options._length()) {
      cm = options[0];
      this_one_found_at = 1;
   } else {
      cm = options[this_one_found_at+1];
      this_one_found_at++;
   }

   // open the file associated with this symbol
   message("Jumping to next symbol match out of "options._length());
   dest_line_no := cm.line_no;
   dest_seekpos := cm.seekpos;
   if (dest_seekpos == 0 && dest_line_no > 1) dest_seekpos = -1;
   parse cm.file_name with auto dest_file_name "\1" .;
   edit(_maybe_quote_filename(dest_file_name),EDIT_DEFAULT_FLAGS);

   do {
      // update the set of symbols for this file
      _UpdateContextAndTokens(true);
      // and verify if the cursor is currently already on the symbol we want
      context_id = tag_current_context();
      if (context_id <= 0) break;
      tag_get_context_info(context_id, auto ci);

      if (dest_seekpos >= 0 && ci.seekpos >= 0 && ci.end_seekpos > 0 && (dest_seekpos < ci.seekpos || dest_seekpos > ci.end_seekpos)) break;
      if (!strieq(cm.member_name, ci.member_name)) break;
      if (cm.class_name == "" && ci.class_name != "") break;
      if (ci.class_name == "" && cm.class_name != "") break;
      if (cm.class_name != "" && ci.class_name != "") {
         ci_class_name := stranslate(cm.class_name,VS_TAGSEPARATOR_package,VS_TAGSEPARATOR_class);
         if (!pos(cm.class_name,ci_class_name,1,'i') || !pos(ci_class_name,cm.class_name,1,'i')) break;
      }
      if (tag_tree_compare_args(cm.arguments, ci.arguments, true) != 0) break;
      if (cm.return_type != ci.return_type) break;

      // same function, we are right where we want to be
      if (p_RLine >= ci.line_no && p_RLine <= ci.end_line_no) {
         dest_line_no = p_RLine;
         return;
      }
   } while (false);

   // jump to the designated symbol
   _cb_goto_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no, true, cm.language);

}

int _OnUpdate_pop_bookmark(CMDUI &cmdui,int target_wid,_str command)
{
   // check if there are any bookmarks on the stack
   STRARRAY *bm_stack = getBookmarkStackPtr();
   if (bm_stack != null && bm_stack->_length() > 0) {
      return MF_ENABLED;
   }
   // Return BOTH GRAYED and ENABLED.  This is because the command
   // should remain enabled so that it can be ran from a keystroke
   // or the command line, but it should appear grayed on the menu
   // and button bars.  This allows pop-bookmark to report that
   // there are no more bookmarks on the stack.
   return(MF_GRAYED|MF_ENABLED);
}
/**
 * Places the cursor at the buffer cursor position stored in the top
 * bookmark of the bookmark stack and pops the bookmark off the
 * bookmark stack.  The <b>push_bookmark</b> and <b>push_tag</b>
 * commands add bookmarks to the bookmark stack.
 *
 * @return Returns 0 if successful.
 *
 * @see push_bookmark
 * @see set_bookmark
 * @see toggle_bookmark
 * @see sb
 * @see goto_bookmark
 * @see gb
 * @see push_tag 
 * @see push_alttag 
 * @see bookmark_stack 
 *
 * @appliesTo Edit_Window
 *
 * @categories Bookmark_Functions
 */
_command pop_bookmark() name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // check if we are in a push-tag multiple matches ring
   orig_last_index := last_index('','C');
   if (_haveContextTagging() && maybe_goto_prev_match()) {
      last_index(orig_last_index,'C');
      return 0;
   }

   // find the first valid bookmark on the bookmark stack
   STRARRAY *bm_stack = getBookmarkStackPtr();
   i := 0;
   bm_id := "";
   for (;;) {
      // no more items on stack, bummer
      if (bm_stack==null || bm_stack->_length() <= 0) {
         // the bookmark stack can be empty, but we could still 
         // have items on the references stack
         if (pop_references_stack(null, true) > 0) {
            last_index(orig_last_index,'C');
            return(1);
         }
         message(nls("No bookmarks to pop"));
         last_index(orig_last_index,'C');
         return(1);
      }
      // get the bookmark name and find it's index
      bm_id = (*bm_stack)[bm_stack->_length()-1];
      i = _BookmarkFind(bm_id,VSBMFLAG_PUSHED);
      if (i >= 0) break;
      // delete invalid bookmarks (should never get here)
      bm_stack->_deleteel(bm_stack->_length()-1);
   }

   // prepare to switch buffers if necessary
   old_buffer_name := "";
   swold_pos := "";
   swold_buf_id := 0;
   set_switch_buffer_args(old_buffer_name,swold_pos,swold_buf_id);

   // bookmark attributes
   mark_id := 0;
   vsbmflags := 0;
   buf_id := 0;
   RealLineNumber := 0;
   col := 0;
   BeginLineROffset := 0L;
   _str LineData=0;
   filename := "";
   DocumentName := "";

   // look up the designated bookmark
   int status=_BookmarkGetInfo(i,
                    bm_id,mark_id,vsbmflags,buf_id,
                    0,RealLineNumber,col,BeginLineROffset,
                    LineData,filename,DocumentName
                    );
   if (status==TEXT_NOT_SELECTED_RC) {
      status=_restore_bookmark(filename);
      if (status && status != FILE_NOT_FOUND_RC) {
         last_index(orig_last_index,'C');
         return(status);
      }
   }

   // clean up buffer
   if (p_buf_id!=buf_id) {
      pop_destination(false,true);
   }
   if (p_buf_id==swold_buf_id) {
      _ForwardBack_push();
   }

   switch_buffer(old_buffer_name,"",swold_pos,swold_buf_id);
   begin_select(mark_id,true,true);

   // remove the bookmark we popped
   _BookmarkRemove(i);
   _BookmarkStackRemove(bm_id);
   if ( vsbmflags & VSBMFLAG_REFERENCES ) {
      if ( !(def_references_options & VSREF_NO_AUTO_POP) ) {
         pop_references_stack(bm_id);
      }
   }
   //_set_focus();
   last_index(orig_last_index,'C');
   return(status);


}

/**
 * Clears all the pushed bookmarks.
 * 
 * @see push_tag
 * @see push_alttag 
 * @see push_bookmark
 * @see pop_bookmark
 * @see bookmark_stack 
 *
 * @appliesTo Edit_Window
 * @categories Bookmark_Functions
 */
_command pop_all_bookmarks()
{
   typeless BookmarkName="";
   typeless markid="";
   vsbmflags := 0;
   bufid := 0;
   RealLineNumber := 0;
   col := 0;
   BeginLineROffset := 0L;
   LineData := "";
   Filename := "";
   DocumentName := "";

   int i;
   for (i=_BookmarkQCount()-1; i>=0; --i) {
      _BookmarkGetInfo(i,BookmarkName,markid,vsbmflags,
                       bufid,
                       0,RealLineNumber,col,BeginLineROffset,LineData,
                       Filename,DocumentName);
      if (vsbmflags & VSBMFLAG_PUSHED) {
         _BookmarkRemove(i);
      }
   }
   STRARRAY *bm_stack = getBookmarkStackPtr();
   if (bm_stack != null && bm_stack->_length() > 0) {
      bm_stack->_makeempty();
   }
   pop_all_destinations();
   if (!(def_references_options & VSREF_NO_AUTO_POP)) {
      clear_references_stack();
   }
}

int _OnUpdate_pop_all_bookmarks(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_pop_bookmark(cmdui,target_wid,command);
}

/**
 * Creates a book mark at the cursor.  Then swap that bookmark with the 
 * previous bookmark on the stack, and jump to the previous bookmark. 
 *  
 * This allows you to toggle between the current cursor location and your 
 * most recently pushed bookmark. 
 *
 * @param markid     named selection to create bookmark on
 * 
 * @return Returns 0 if successful.
 *
 * @see push_bookmark
 * @see pop_bookmark
 * @see set_bookmark
 * @see toggle_bookmark
 * @see goto_bookmark
 * @see bookmark_stack 
 *
 * @appliesTo Edit_Window
 *
 * @categories Bookmark_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command swap_bookmarks(_str markid="") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   // push a bookmark at the current cursor location
   status := push_bookmark(markid);
   if (status < 0) {
      return status;
   }

   // swap the two top-most bookmarks
   STRARRAY *bm_stack = getBookmarkStackPtr();
   if (bm_stack != null && bm_stack->_length() >= 2) {
      item_at_top := (*bm_stack)[bm_stack->_length()-1];
      item_below  := (*bm_stack)[bm_stack->_length()-2];
      (*bm_stack)[bm_stack->_length()-1] = item_below;
      (*bm_stack)[bm_stack->_length()-2] = item_at_top;
   }

   // now pop back to the previous bookmark
   // the current bookmark will be left on the top of the stack
   return pop_bookmark();
}

int _OnUpdate_swap_bookmarks(CMDUI &cmdui,int target_wid,_str command)
{
   status := _OnUpdate_push_bookmark(cmdui, target_wid, command);
   if (status == MF_GRAYED || status == MF_REQUIRES_PRO || status == MF_DELETED) {
      return status;
   }
   return _OnUpdate_pop_bookmark(cmdui,target_wid,command);
}

/**
 * Gets called when a buffer is closed.
 * This function is used to clean up pushed bookmarks from
 * the bookmark stack when a file is closed by the user.
 *
 * @param buffid  p_buf_id of the buffer that was closed
 * @param name    p_buf_name of the buffer that was closed
 * @param docname p_DocumentName of the buffer that was closed
 * @param flags   assumed to be 0
 */
void _cbquit_bookmarks(int buffid, _str name, _str docname="", int flags=0)
{
   // is this option turned off?
   if (!def_cleanup_pushed_bookmarks_on_quit) {
      return;
   }

   // bookmark attributes
   bm_name  := "";
   bm_mark  := 0;
   bm_flags := 0;
   bm_bufid := 0;
   bm_line  := 0;
   bm_rline := 0;
   bm_col   := 0;
   bm_rpos  := 0;
   bm_data  := "";
   bm_file  := "";
   bm_docname := "";

   // check each bookmark if it matches the buffer being quit
   n := _BookmarkQCount();
   for (i:=n-1; i>=0; --i) {
      _BookmarkGetInfo(i, bm_name, bm_mark, bm_flags, bm_bufid,
                          bm_line, bm_rline, bm_col, bm_rpos, bm_data, 
                          bm_file, bm_docname);
      if (!(bm_flags & VSBMFLAG_PUSHED)) {
         continue;
      }
      if (bm_bufid == buffid) {
         // bookmark is in the buffer being closed, remove it
         _BookmarkRemove(i);
         _BookmarkStackRemove(bm_name);
      }
   }
}

void push_tag_reset_matches()
{
   gPushTagMatches._makeempty();
}
void push_tag_reset_item()
{
   gPushTagItem = 0;
   gPushTagOffset=_QROffset();
}
void push_tag_add_match(VS_TAG_BROWSE_INFO cm)
{
   // make sure that the symbol does not come from a DLL, Jar, or Class file
   if (_QBinaryLoadTagsSupported(cm.file_name)) return;

   // add the item to the list
   gPushTagMatches[gPushTagMatches._length()] = cm;
}
static bool maybe_goto_next_match()
{
   do {
      if (!_isEditorCtl()) {
         break;
      }
      orig_wid := p_window_id;
      int orig_buf_id = p_buf_id;
      orig_last_index := last_index('','C');
      orig_prev_index := prev_index('','C');
      if (!orig_prev_index) break;

      prev_command := name_name(orig_prev_index);
      if (prev_command != "push-tag" && 
          prev_command != "push-def" && 
          prev_command != "push-decl" && 
          prev_command != "push-alttag" && 
          prev_command != "push-tag-filter-overloads" &&
          prev_command != "pop-bookmark" && 
          prev_command != "f") {
         break;
      }

      if (gPushTagMatches._isempty() || gPushTagMatches._length() <= 1) {
         break;
      }

      if (_QROffset() != gPushTagOffset) {
         break;
      }

      if (gPushTagItem+1 >= gPushTagMatches._length()) {
         gPushTagItem = 0;
      } else {
         gPushTagItem++;
      }

      cm := gPushTagMatches[gPushTagItem];
      status := tag_edit_symbol(cm);
      if (status < 0) {
         return false;
      }

      push_destination(orig_wid,orig_buf_id);
      gPushTagOffset=_QROffset();
      show_next_prev_match();
      last_index(orig_last_index,'C');
      prev_index(orig_prev_index,'C');
      return true;

   } while (false);

   gPushTagMatches._makeempty();
   gPushTagItem=0;
   gPushTagOffset=0;
   return false;
}
static bool maybe_goto_prev_match()
{
   do {
      if (!_isEditorCtl()) {
         break;
      }
      orig_wid := p_window_id;
      int orig_buf_id = p_buf_id;
      orig_last_index := last_index('','C');
      orig_prev_index := prev_index('','C');
      if (!orig_prev_index) break;

      prev_command := name_name(orig_prev_index);
      if (prev_command != "push-tag" && 
          prev_command != "push-def" && 
          prev_command != "push-decl" && 
          prev_command != "push-alttag" && 
          prev_command != "push-tag-filter-overloads" &&
          prev_command != "pop-bookmark" && 
          prev_command != "f") {
         break;
      }

      if (gPushTagMatches._isempty() || gPushTagMatches._length() <= 1) {
         break;
      }

      if (gPushTagItem <= 0) {
         break;
      }

      if (_QROffset() != gPushTagOffset) {
         break;
      }

      gPushTagItem--;
      cm := gPushTagMatches[gPushTagItem];
      status := tag_edit_symbol(cm);
      if (status < 0) {
         return false;
      }

      gPushTagOffset=_QROffset();
      push_destination(orig_wid,orig_buf_id);
      show_next_prev_match();
      last_index(orig_last_index,'C');
      prev_index(orig_prev_index,'C');
      return true;

   } while (false);

   gPushTagMatches._makeempty();
   gPushTagItem=0;
   gPushTagOffset=0;
   return false;
}

/**
 * @return Return true if the given symbol is a declaration rather than
 *         a definition.  For example, return true if it is a prototype.
 * 
 * @param cm   symbol information
 */
bool tag_is_declaration(VS_TAG_BROWSE_INFO &cm)
{
   if (cm.type_name=="proto" || cm.type_name=="procproto") {
      return true;
   }
   if (cm.type_name=="var") {
      return true;
   }
   if (cm.flags & SE_TAG_FLAG_FORWARD) {
      return true;
   }
   return false;
}
/**
 * @return Return true if the given symbol is a declaration rather than
 *         a definition.  For example, return true if it is a function's 
 *         implementation, not the prototype.
 * 
 * @param cm   symbol information
 */
bool tag_is_definition(VS_TAG_BROWSE_INFO &cm)
{
   if (cm.type_name=="proto" || cm.type_name=="procproto") {
      return false;
   }
   if (tag_tree_type_is_func(cm.type_name)) {
      return true;
   }
   if (cm.type_name=="gvar") {
      return true;
   }
   if (cm.type_name=="class" && !(cm.flags & SE_TAG_FLAG_FORWARD)) {
      return true;
   }
   return false;
}
/**
 * Display a message on the message bar explaining what keys
 * the user can hit to cycle through matches found using
 * <code>push_tag()</code>.
 */
void show_next_prev_match()
{
   // verify that we have a valid match set
   if (gPushTagMatches._isempty() || gPushTagMatches._length() <= 0) {
      return;
   }

   // verify that the current item is set
   if (gPushTagItem < 0 || gPushTagItem >= gPushTagMatches._length()) {
      return;
   }

   // what was the last command invoked?
   orig_last_index := last_index('','C');
   orig_prev_index := prev_index('','C');

   // where are pop_bookmark and push_tag?
   _str pop_key  = _where_is("pop_bookmark");
   _str push_key = _where_is("push_tag");
   if (push_key=="") {
      push_key = _where_is("f");
   }

   // get the browse info for the current tag
   cur := gPushTagMatches[gPushTagItem];

   // fine tune the message for previous item
   prev := "previous ";
   item := "item";
   int prevMatchItem = gPushTagItem-1;
   if (prevMatchItem < 0) {
      prevMatchItem = gPushTagMatches._length()-1;
   }
   cm := gPushTagMatches[prevMatchItem];
   if (tag_is_declaration(cm)) {
      item = "declaration";
      if (gPushTagMatches._length()==2 && tag_is_definition(cur)) {
         prev = "";
      }
   } else if (tag_is_definition(cm)) {
      item = "definition";
      if (gPushTagMatches._length()==2 && tag_is_declaration(cur)) {
         prev = "";
      }
   }

   // create the message for what pop-bookmark will do
   pop_msg := "";
   if (pop_key == "") {
      pop_msg = "You can bind 'pop-bookmark' to a key to go back.";
   } else if (gPushTagItem <= 0) {
      pop_msg = "Press "pop_key" to go back.";
   } else {
      pop_msg = "Press "pop_key" to go to ":+prev:+item:+".";
   }

   // fine tune the message for the next item
   next := "next ";
   item = "item";
   int nextMatchItem = gPushTagItem+1;
   if (nextMatchItem >= gPushTagMatches._length()) {
      nextMatchItem = 0;
   }
   cm = gPushTagMatches[nextMatchItem];
   if (tag_is_declaration(cm)) {
      item = "declaration";
      if (gPushTagMatches._length()==2 && tag_is_definition(cur)) {
         next = "";
      }
   } else if (tag_is_definition(cm)) {
      item = "definition";
      if (gPushTagMatches._length()==2 && tag_is_declaration(cur)) {
         next = "";
      }
   }

   // create the message for what another push-tag will do
   push_msg := "";
   if (push_key == "") {
      push_key = "You can bind 'push-tag' to a key to cycle through items.";
   } else if (gPushTagItem >= gPushTagMatches._length()-1) {
      push_msg = "Press "push_key" to go to the first ":+item:+".";
   } else {
      push_msg = "Press "push_key" to go to the ":+next:+item:+".";
   }

   // display the message, provided there is more than one item
   if (gPushTagMatches._length() > 1) {
      message(push_msg"  "pop_msg);
   } else {
      message(pop_msg);
   }

   // restore last_index and prev_index
   last_index(orig_last_index,'C');
   prev_index(orig_prev_index,'C');
}

/**
 * @return Returns the last space delimited word in <i>line</i>.   The last word
 * and trailing spaces are deleted from <i>line</i>.
 *
 * @param line   line to parse
 * 
 * @categories String_Functions
 */
_str strip_last_word(_str &line)
{
   result := "";
   line=strip(line,'T');
   i := lastpos(" ",line);
   if ( ! i ) {
      result=line;
      line="";
      return(result);
   }
   result=substr(line,i+1);
   line=strip(substr(line,1,i-1),'T');
   return(result);

}
/**
 * The <b>push_tag</b> command pushes a bookmark at the cursor position
 * and places the cursor on the source code for a tag you specify.  A dialog box
 * is displayed which allows you to type the tag name in or select from a list
 * of previously entered tag names.  Use the <b>pop_bookmark</b> command
 * (Ctrl+,) to return to the previous bookmark. To create or modify a tag file,
 * use the Tag Files dialog box ("Search", "Tag Files...").  Your tag files will
 * automatically be updated when you make edits.  The SPACE BAR and '?' keys may
 * be used to complete the tag name.  For those of you working in case sensitive
 * languages, you may want to make tag name
 * searching case sensitive.  The command "set-var def-ignore-tcase 0" will
 * force all tag name searching to be case insensitive.  Currently the C, C++,
 * Pascal, REXX, AWK, Modula-2, Clipper, Cobol, Fortran, and Assembly languages
 * are supported.  See "tags.e" for information on adding support for other
 * languages.
 *
 * @param proc_name     encoded tag name to find.  See {@link tag_tree_compose_tag}.
 * 
 * @return Returns 0 if successful.
 *
 * @see make_tags
 * @see push_tag
 * @see gui_make_tags
 * @see find_tag
 * @see f
 *
 * @appliesTo Edit_Window
 *
 * @categories Tagging_Functions, Bookmark_Functions, Search_Functions
 *
 */
_command gui_push_tag(_str proc_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Find Symbol");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (!def_use_old_goto_definition_dialog && proc_name=="") {
      int wid = activate_find_symbol();
      if (wid != 0) return wid;
   }

   _macro_delete_line();
   for (;;) {
      typeless result = show("-modal -xy -reinit _tagbookmark_form",proc_name);
      if (result == "") {
         return(COMMAND_CANCELLED_RC);
      }
      typeless status = push_tag("-is "result);
      if(status != 1) {  /* Tag not found? */
         _macro('m',_macro('s'));
         _macro_call("push_tag", "-is "result);
         return(status);
      }
      int orig_buf_id = p_buf_id;
      status = load_files("+b .command");
      if (!status) {
         bottom();
         status = search("\\@cb _tagbookmark_form.ctlTag", "@r-");
         _delete_line(); up(); _delete_line();
         p_buf_id = orig_buf_id;
      }
   }
}

//--------------------------------------------------------------
defeventtab _tagbookmark_form;
void ctlTagList.on_got_focus()
{
   index := ctlTagList._TreeCurIndex();
   if (index<0) return;
   caption := ctlTagList._TreeGetCaption(index);
   if (substr(caption,1,8) == "<Listing") {
      return;
   }
   ctlTag.p_cb_text_box.p_user = index;
}
void ctlTagList.lbutton_double_click()
{
   ctlOK.call_event(ctlOK, LBUTTON_UP, 'W');
}
void ctlTagList.rbutton_up()
{
   // Get handle to menu:
   index := find_index("_tagbookmark_menu",oi2type(OI_MENU));
   menu_handle := _mdi._menu_load(index,'P');

   flags := ctlTagList.p_user;
   pushTgConfigureMenu(menu_handle, flags, 
                       include_proctree:false, 
                       include_casesens:true, 
                       include_sort:false, 
                       include_save_print:true);

   // Show menu:
   mou_get_xy(auto x, auto y);
   _KillToolButtonTimer();
   status := _menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}
//void ctlCaseSensitive.lbutton_up()
//{
//   pushTgBmMatchTags();
//}
//void _tagbookmark_form.on_create()
//{
//}
void _tagbookmark_form.on_resize()
{
   int width = _dx2lx(SM_TWIP, p_active_form.p_client_width);
   int height = _dy2ly(SM_TWIP, p_active_form.p_client_height);
   int margin_x = ctlTagList.p_x;
   int margin_y = ctlTag.p_y;
   int button_height = ctlOK.p_height + margin_y;

   // adjust the tree control
   ctlTagList.p_width  = width - 2*margin_x;
   ctlTagList.p_y_extent = height - button_height - margin_y;

   // adjust the search tag, and regex combo box
   //ctlTag.p_x = margin_x + max(ctlTagLabel.p_width,ctlClassLabel.p_width) + margin_x;
   ctlTag.p_x = margin_x + ctlTagLabel.p_width + margin_x;
   //ctlClass.p_x = ctlTag.p_x;
   ctlTag.p_x_extent = width - margin_x - ctlPrefix.p_width - margin_x;
   //ctlClass.p_x_extent = width - margin_x - ctlPrefix.p_width - margin_x;
   ctlPrefix.p_x  = ctlTag.p_x_extent + margin_x;

   // adjust the button positioning
   ctlOK.p_y = height - ctlOK.p_height - margin_y;
   ctlCancel.p_y = ctlOK.p_y;
   int x1 = ctlCancel.p_x_extent + margin_x;
   int x2 = width - ctlProgress.p_width - margin_x;
   ctlProgress.p_x = max(x1,x2);
   ctlProgress.p_y = height - ctlProgress.p_height - margin_y;
}
void ctlTagList.on_change(int reason,int index)
{
   if (index <= TREE_ROOT_INDEX) {
      return;
   }
   if (reason == CHANGE_SELECTED && _get_focus()==ctlTagList) {
      class_name := "";
      caption := ctlTagList._TreeGetCaption(index);
      parse caption with caption "\t" class_name "::" .;
      if (substr(caption,1,8) == "<Listing") {
         return;
      }
      _str tag;
      tag_tree_decompose_caption(caption,tag);
      pushTgBmIgnoreChange = 1;
      ctlTag.p_cb_text_box.p_text = tag;
      ctlTag.p_cb_text_box.p_user = index;
      ctlPrefix.p_user=0;
      //ctlClass.p_cb_text_box.p_text = class_name;
      pushTgBmIgnoreChange = 0;
   } else if (reason == CHANGE_LEAF_ENTER) {
      ctlOK.call_event(ctlOK, LBUTTON_UP, 'W');
   }
}
void pushTgBmTimerCB()
{
   if (pushTgBmTimerID >= 0) {
      _kill_timer(pushTgBmTimerID);
      pushTgBmTimerID = -1;
   }
   // Fill tag list:
   int formwid = _find_formobj("_tagbookmark_form","n");
   if (!formwid) return;
   formwid.pushTgBmMatchTags();
   refresh();
}
static void pushTgBmMatchTags()
{
   ctlTag.p_cb_text_box.p_user = 0;

   // If prefix is too short, don't match tags:
   regex_match := (ctlPrefix.p_value == 0);
   class_filter := "";//ctlClass.p_text;
   prefix := ctlTag.p_text;
   if (pos("::",prefix)) {
      parse prefix with class_filter "::" prefix;
   }
   if (prefix=="" && class_filter=="") {
      return;
   }

   // get filtering options
   flags := (SETagFilterFlags) ctlTagList.p_user;
   case_flag := (flags & SE_TAG_FILTER_CASE_SENSITIVE) != 0;

   // Clear tag list box:
   cb_prepare_expand(p_active_form,ctlTagList,TREE_ROOT_INDEX);
   ctlTagList._TreeDelete(TREE_ROOT_INDEX,'C');

   // timeout after ten minutes of searching
   _SetTimeout(10*60*1000);

   // Open tag files:
   tagCount := 0;
   tag_files := null;
   tag_database := ctlCancel.p_user;
   if (tag_database != null && tag_database != "" && file_exists(tag_database)) {
      tag_files[0] = tag_database;
   } else {
      tag_files = tags_filenamea(ctlOK.p_user);
   }
   int status = tag_pushtag_match(ctlTagList,TREE_ROOT_INDEX,ctlProgress,
                                  prefix,class_filter,
                                  tag_files,flags,tagCount,PREFIXMATCHEDMAXLISTCOUNT,
                                  regex_match,false,case_flag);

   ctlTagList._TreeSortCaption(TREE_ROOT_INDEX,'UB');
   //say( "tagCount="tagCount );
   if (status==1 || status < 0) {
      int tree_flags  = TREE_ADD_BEFORE;
      first_child := ctlTagList._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if (first_child < 0) {
         first_child = TREE_ROOT_INDEX;
         tree_flags  = TREE_ADD_AS_CHILD;
      }
      verb := "";
      switch (status) {
      case 1:                    verb = "stopped"; break;
      case COMMAND_CANCELLED_RC: verb = "cancelled"; break;
      case TAGGING_TIMEOUT_RC:   verb = "timed out"; break;
      default:                   verb = "error";
      }
      ctlTagList._TreeAddItem(first_child,"<Listing "verb" after "tagCount" matches>",tree_flags);
   }
   ctlTagList._TreeSizeColumnToContents(0);
   ctlTagList._TreeTop();
   _SetTimeout(0);
}
void _tagbookmark_form.A_P()
{
   ctlPrefix.p_value = (ctlPrefix.p_value)? 0:1;
   if (!ctlPrefix.p_value) {
      ctlTag.p_completion=NONE_ARG;
   }
   ctlPrefix.p_user=0;
   ctlTagList._TreeDelete(TREE_ROOT_INDEX,'C');
   if (pushTgBmTimerID >= 0) _kill_timer(pushTgBmTimerID);
   pushTgBmTimerID = _set_timer( KEYPRESSTOTAGMATCHINGDELAY, pushTgBmTimerCB, 0 );
}
void ctlPrefix.lbutton_up()
{
   if (pushTgBmIgnoreChange) return;

   // If prefix is too short, don't match tags:
   //_str prefix = ctlTag.p_cb_text_box.p_text;
   //if (length(prefix) < PREFIXMINCHARCOUNT) {
      ctlTagList._TreeDelete(TREE_ROOT_INDEX,'C');
   //   return;
   //}

   ctlPrefix.p_user=0;
   if (!ctlPrefix.p_value) {
      ctlTag.p_completion=NONE_ARG;
   }
   if (pushTgBmTimerID >= 0) _kill_timer(pushTgBmTimerID);
   pushTgBmTimerID = _set_timer( KEYPRESSTOTAGMATCHINGDELAY, pushTgBmTimerCB, 0 );
}
void ctlTag.on_change(int reason)
{
   if (pushTgBmIgnoreChange) return;

   // If prefix is too short, don't match tags:
   //_str prefix = ctlTag.p_cb_text_box.p_text;
   //if (length(prefix) < PREFIXMINCHARCOUNT) {
      ctlTagList._TreeDelete(TREE_ROOT_INDEX,'C');
   //   return;
   //}

   // is this a regular expression?
   if (ctlPrefix.p_user && ctlPrefix.p_value &&
       pos("[[*#?^$+{}|]",ctlTag.p_text,1,"r")) {
      ctlPrefix.p_value=0;
      ctlPrefix.p_user=0;
      ctlTag.p_completion=NONE_ARG;
   }
   // is there a class name specification?
   if (pos("::",ctlTag.p_text)) {
      ctlTag.p_completion=NONE_ARG;
   }

   if (pushTgBmTimerID >= 0) _kill_timer(pushTgBmTimerID);
   pushTgBmTimerID = _set_timer( KEYPRESSTOTAGMATCHINGDELAY, pushTgBmTimerCB, 0 );
}
#if 0
void ctlClass.on_change(int reason)
{
   if (pushTgBmIgnoreChange) return;

   // If prefix is too short, don't match tags:
   //_str prefix = ctlTag.p_cb_text_box.p_text;
   //if (length(prefix) < PREFIXMINCHARCOUNT) {
      ctlTagList._TreeDelete(TREE_ROOT_INDEX,"C");
   //   return;
   //}

   if (pushTgBmTimerID >= 0) _kill_timer(pushTgBmTimerID);
   pushTgBmTimerID = _set_timer( KEYPRESSTOTAGMATCHINGDELAY, pushTgBmTimerCB, 0 );
}
#endif
void ctlTag.on_create(_str searchText="",
                      _str FormName="",
                      _str langId="",
                      bool nobinary=true,
                      _str searchClass="",
                      _str tag_database="")
{
   if (FormName != "") {
      p_active_form.p_caption=FormName;
   }
   // Save extension for extension-specific tag file searching
   ctlOK.p_user = langId;
   ctlCancel.p_user = tag_database;
   p_ListCompletions=false;
   if (langId == "e") {
      p_completion=MACROTAG_ARG;
   } else {
      p_completion=TAG_ARG;
   }

   // Restore previous history values:
   ctlTag._retrieve_value();
   ctlTag._retrieve_list();
   //ctlClass._retrieve_value();
   //ctlClass.p_cb_list_box._retrieve_list();
   ctlPrefix.p_user = 1;
   ctlTagList.p_user = _retrieve_value("_tagbookmark_form.ctlTagList");
   if (ctlTagList.p_user == "") {
      ctlTagList.p_user = 0xffff & (~SE_TAG_FILTER_CASE_SENSITIVE);
   }
   if (nobinary) {
      ctlTagList.p_user |= SE_TAG_FILTER_NO_BINARY;
   }

   ctlTag.p_text = searchText;
   //if (arg() >= 5) {
   //   ctlClass.p_text = searchClass;
   //}
}
void ctlTag.on_destroy()
{
   if (pushTgBmTimerID >= 0) {
      _kill_timer(pushTgBmTimerID);
      pushTgBmTimerID = -1;
   }
}
void _tagbookmark_form.on_destroy()
{
   _append_retrieve(ctlTag, ctlTag.p_cb_text_box.p_text);
   _append_retrieve(0, ctlTagList.p_user, "_tagbookmark_form.ctlTagList" );
}
void ctlOK.lbutton_up()
{
   _str tag_name = ctlTag.p_cb_text_box.p_text;
   int index = ctlTag.p_cb_text_box.p_user;
   //say("ctlOK.lbutton_up: index="index);
   if (index > 0) {
      class_name := "";
      caption := ctlTagList._TreeGetCaption(index);
      parse caption with caption "\t" class_name "::" .;
      if (substr(caption,1,8) != "<Listing") {
         tag_tree_decompose_caption(caption,tag_name);
         strappend(tag_name, "("class_name":)");
      }
   }
   p_active_form._delete_window(tag_name);
}
void ctlCancel.lbutton_up()
{
   p_active_form._delete_window("");
}

/**
 * Configure right mouse menu for tag filters
 * 
 * @param menu_handle            instance of _tagbookmark_menu
 * @param flags                  bitset of VS_TAGFITLER_* flags
 * @param include_proctree       include menu items for Defs tool window
 * @param include_casesens       include "Case Sensitive" menu item
 * @param include_sort           include sorting options
 * @param include_save_print     include options to save/print contents of tree
 * @param include_search_results include search results options (find tags)
 * @param include_statements     include statement filters and statement tagging options
 * @param include_refs_results   include references results
 * @param include_quick_filters  (default true) include quick filters
 * @param include_filters        (default true) include other kinds of filters
 */
void pushTgConfigureMenu(int menu_handle, 
                         int flags,
                         bool include_proctree=false,
                         bool include_casesens=false,
                         bool include_sort=false,
                         bool include_save_print=false,
                         bool include_search_results=false,
                         bool include_statements=false,
                         bool include_refs_results=false,
                         bool include_quick_filters=true,
                         bool include_filters=true)
{
   // get rid of sorting options
   status := mh := mpos := 0;
   if (!include_sort && !include_proctree) {
      status=_menu_find(menu_handle,"sortfunc",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"sortlinenum",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"nesting",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
   }
   // get rid of save_print options
   if (!include_save_print) {
      status=_menu_find(menu_handle,"contents",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
   }
   // get rid of proctree items
   if (!include_proctree) {
      status=_menu_find(menu_handle,"cpp_refactoring",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"quick_refactoring",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"outline_view",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"set_breakpoint",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"hierarchy",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"expansion",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"autoexpand",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"autocollapse",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"nontaggable",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"showfiles",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"properties",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"arguments",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"references",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"calltree",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"callertree",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"refactoring",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"sep0",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"expandchildren",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"expandonelevel",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"expandtwolevels",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"expandtostatements",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"statements",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"lang_statements",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"all_statements",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"filter_statements",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"singleclick",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
   } else {
      // Do not remove this item, becuase we use the "parameter"
      // tag for some objects in Verilog that show up in the procs.
      // (DJB 03/11/2003)
      //
      //status=_menu_find(menu_handle,"lvar",mh,mpos,'C');
      //if (!status) {
      //  _menu_delete(mh,mpos);
      //}

      // hide C/C++ refactoring if it is disabled
      if (def_disable_cpp_refactoring || !_haveRefactoring()) {
         status=_menu_find(menu_handle,"cpp_refactoring",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
      }
      if (!_haveRefactoring()) {
         status=_menu_find(menu_handle,"quick_refactoring",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
         status=_menu_find(menu_handle,"refactoring",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
         status=_menu_find(menu_handle,"imports",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
      }
      if (!_haveDebugging()) {
         status=_menu_find(menu_handle,"set_breakpoint",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
      }
      if (!_haveContextTagging()) {
         status=_menu_find(menu_handle,"properties",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
         status=_menu_find(menu_handle,"arguments",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
         status=_menu_find(menu_handle,"references",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
         status=_menu_find(menu_handle,"calltree",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
         status=_menu_find(menu_handle,"callertree",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
         status=_menu_find(menu_handle,"sep0",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
         status=_menu_find(menu_handle,"statements",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
         status=_menu_find(menu_handle,"lang_statements",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
         status=_menu_find(menu_handle,"all_statements",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
         status=_menu_find(menu_handle,"filter_statements",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
      }
   }

   // handle 'case sensitive' as a special case
   if (!include_proctree && include_casesens) {
      if (flags & SE_TAG_FILTER_CASE_SENSITIVE) {
         _menu_set_state(menu_handle,"casesensitive",MF_CHECKED,'C');
      }
      if (!include_proctree) {
         status=_menu_find(menu_handle,"sep2",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
      }
   } else {
      status=_menu_find(menu_handle,"casesensitive",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      if (include_sort) {
         // deletes the seperator bar
         status=_menu_find(menu_handle,"sep1",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
         _menu_delete(mh,2);
      } else if (!include_proctree) {
         // deletes the seperator bar
         status=_menu_find(menu_handle,"sep1",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
         // deletes the other seperator bar
         status=_menu_find(menu_handle,"sep2",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh,mpos);
         }
      }
   }

   if (!include_search_results) {
      status=_menu_find(menu_handle,"search_results",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh, mpos);
      }
   }
   if (!include_refs_results) {
      status=_menu_find(menu_handle,"refs_results",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh, mpos);
      }    
   }

   if (include_filters) {
      // set up states of the rest of the flags
      if (flags & SE_TAG_FILTER_PROCEDURE) {
         _menu_set_state(menu_handle,"proc",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_PROTOTYPE) {
         _menu_set_state(menu_handle,"proto",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_SUBPROCEDURE) {
         _menu_set_state(menu_handle,"subproc",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_DEFINE) {
         _menu_set_state(menu_handle,"define",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_ENUM) {
         _menu_set_state(menu_handle,"enum",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_GLOBAL_VARIABLE) {
         _menu_set_state(menu_handle,"gvar",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_TYPEDEF) {
         _menu_set_state(menu_handle,"typedef",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_STRUCT) {
         _menu_set_state(menu_handle,"struct",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_UNION) {
         _menu_set_state(menu_handle,"union",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_LABEL) {
         _menu_set_state(menu_handle,"label",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_INTERFACE) {
         _menu_set_state(menu_handle,"interface",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_PACKAGE) {
         _menu_set_state(menu_handle,"package",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_MEMBER_VARIABLE) {
         _menu_set_state(menu_handle,"var",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_CONSTANT) {
         _menu_set_state(menu_handle,"const",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_PROPERTY) {
         _menu_set_state(menu_handle,"prop",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_LOCAL_VARIABLE) {
         _menu_set_state(menu_handle,"lvar",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_DATABASE) {
         _menu_set_state(menu_handle,"database",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_GUI) {
         _menu_set_state(menu_handle,"gui",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_INCLUDE) {
         _menu_set_state(menu_handle,"include",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_ANNOTATION) {
         _menu_set_state(menu_handle,"annotation",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_MISCELLANEOUS) {
         _menu_set_state(menu_handle,"misc",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_UNKNOWN) {
         _menu_set_state(menu_handle,"unknown",MF_CHECKED,'C');
      }
      // quick filters
      if ((flags & SE_TAG_FILTER_ANY_SCOPE) == SE_TAG_FILTER_ANY_SCOPE) {
         _menu_set_state(menu_handle,"all_scope",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == (SE_TAG_FILTER_ANY_PROCEDURE & ~ SE_TAG_FILTER_PROTOTYPE)) {
         _menu_set_state(menu_handle,"funcs_only",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_PROTOTYPE) {
         _menu_set_state(menu_handle,"protos_only",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_ANY_DATA) {
         _menu_set_state(menu_handle,"vars_only",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_ANY_STRUCT) {
         _menu_set_state(menu_handle,"class_only",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == (SE_TAG_FILTER_DEFINE|SE_TAG_FILTER_ENUM|SE_TAG_FILTER_CONSTANT)) {
         _menu_set_state(menu_handle,"defines_only",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANYTHING) == SE_TAG_FILTER_ANYTHING) {
         have_type_filtered_out := false;
         for (t:=SE_TAG_TYPE_NULL; t<def_cb_filter_by_types._length(); t++) {
            if (!def_cb_filter_by_types[t]) {
               have_type_filtered_out = true;
               break;
            }
         }
         if (!have_type_filtered_out) {
            _menu_set_state(menu_handle,"all",MF_CHECKED,'C');
         }
      }
      // access filters
      if (flags & SE_TAG_FILTER_SCOPE_PUBLIC) {
         _menu_set_state(menu_handle,"public_scope",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_SCOPE_PACKAGE) {
         _menu_set_state(menu_handle,"package_scope",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_SCOPE_PROTECTED) {
         _menu_set_state(menu_handle,"protected_scope",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_SCOPE_PRIVATE) {
         _menu_set_state(menu_handle,"private_scope",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_SCOPE_STATIC) {
         _menu_set_state(menu_handle,"static_scope",MF_CHECKED,'C');
      }
      if (flags & SE_TAG_FILTER_SCOPE_EXTERN) {
         _menu_set_state(menu_handle,"extern_scope",MF_CHECKED,'C');
      }
      // single items
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_PROCEDURE) {
         _menu_set_state(menu_handle,"1proc",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_PROTOTYPE) {
         _menu_set_state(menu_handle,"1proto",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_SUBPROCEDURE) {
         _menu_set_state(menu_handle,"1subproc",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_DEFINE) {
         _menu_set_state(menu_handle,"1define",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_ENUM) {
         _menu_set_state(menu_handle,"1enum",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_GLOBAL_VARIABLE) {
         _menu_set_state(menu_handle,"1gvar",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_TYPEDEF) {
         _menu_set_state(menu_handle,"1typedef",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_STRUCT) {
         _menu_set_state(menu_handle,"1struct",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_UNION) {
         _menu_set_state(menu_handle,"1union",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_LABEL) {
         _menu_set_state(menu_handle,"1label",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_INTERFACE) {
         _menu_set_state(menu_handle,"1interface",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_PACKAGE) {
         _menu_set_state(menu_handle,"1package",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_MEMBER_VARIABLE) {
         _menu_set_state(menu_handle,"1var",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_CONSTANT) {
         _menu_set_state(menu_handle,"1const",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_PROPERTY) {
         _menu_set_state(menu_handle,"1prop",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_LOCAL_VARIABLE) {
         _menu_set_state(menu_handle,"1lvar",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_DATABASE) {
         _menu_set_state(menu_handle,"1database",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_GUI) {
         _menu_set_state(menu_handle,"1gui",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_INCLUDE) {
         _menu_set_state(menu_handle,"1include",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANNOTATION) == SE_TAG_FILTER_ANNOTATION) {
         _menu_set_state(menu_handle,"1annotation",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_MISCELLANEOUS) {
         _menu_set_state(menu_handle,"1misc",MF_CHECKED,'C');
      }
      if ((flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_UNKNOWN) {
         _menu_set_state(menu_handle,"1unknown",MF_CHECKED,'C');
      }
      // filters by type
      if (def_cb_filter_by_types[SE_TAG_TYPE_BREAK] &&
          def_cb_filter_by_types[SE_TAG_TYPE_CONTINUE] &&
          def_cb_filter_by_types[SE_TAG_TYPE_GOTO]) {
         _menu_set_state(menu_handle,"break",MF_CHECKED,'C');
      }
      if (def_cb_filter_by_types[SE_TAG_TYPE_CALL]) {
         _menu_set_state(menu_handle,"call",MF_CHECKED,'C');
      }
      if (def_cb_filter_by_types[SE_TAG_TYPE_IF] &&
          def_cb_filter_by_types[SE_TAG_TYPE_SWITCH]) {
         _menu_set_state(menu_handle,"if",MF_CHECKED,'C');
      }
      if (def_cb_filter_by_types[SE_TAG_TYPE_LOOP]) {
         _menu_set_state(menu_handle,"loop",MF_CHECKED,'C');
      }
      if (def_cb_filter_by_types[SE_TAG_TYPE_RETURN]) {
         _menu_set_state(menu_handle,"return",MF_CHECKED,'C');
      }
      if (def_cb_filter_by_types[SE_TAG_TYPE_ASSIGN]) {
         _menu_set_state(menu_handle,"assign",MF_CHECKED,'C');
      }
      if (def_cb_filter_by_types[SE_TAG_TYPE_TRY]) {
         _menu_set_state(menu_handle,"try",MF_CHECKED,'C');
      }
      if (def_cb_filter_by_types[SE_TAG_TYPE_PP]) {
         _menu_set_state(menu_handle,"pp",MF_CHECKED,'C');
      }
      if (def_cb_filter_by_types[SE_TAG_TYPE_STATEMENT] &&
          def_cb_filter_by_types[SE_TAG_TYPE_CLAUSE] &&
          def_cb_filter_by_types[SE_TAG_TYPE_BLOCK]) {
         _menu_set_state(menu_handle,"statement",MF_CHECKED,'C');
      }
      if (def_cb_filter_by_types[SE_TAG_TYPE_QUERY]) {
         _menu_set_state(menu_handle,"query",MF_CHECKED,'C');
      }
      if (def_cb_filter_by_types[SE_TAG_TYPE_CONTROL]) {
         _menu_set_state(menu_handle,"control",MF_CHECKED,'C');
      }
      // all statement filters
      if (include_statements &&
          def_cb_filter_by_types[SE_TAG_TYPE_ASSIGN] &&
          def_cb_filter_by_types[SE_TAG_TYPE_BREAK] &&
          def_cb_filter_by_types[SE_TAG_TYPE_CONTINUE] &&
          def_cb_filter_by_types[SE_TAG_TYPE_CALL] &&
          def_cb_filter_by_types[SE_TAG_TYPE_IF] &&
          def_cb_filter_by_types[SE_TAG_TYPE_SWITCH] &&
          def_cb_filter_by_types[SE_TAG_TYPE_LOOP] &&
          def_cb_filter_by_types[SE_TAG_TYPE_RETURN] &&
          def_cb_filter_by_types[SE_TAG_TYPE_GOTO] &&
          def_cb_filter_by_types[SE_TAG_TYPE_TRY] &&
          def_cb_filter_by_types[SE_TAG_TYPE_PP] &&
          def_cb_filter_by_types[SE_TAG_TYPE_CLAUSE] &&
          def_cb_filter_by_types[SE_TAG_TYPE_BLOCK] &&
          def_cb_filter_by_types[SE_TAG_TYPE_STATEMENT]) {
         _menu_set_state(menu_handle,"all_statements",MF_CHECKED,'C');
      }
   } else {
      if (include_quick_filters) {
         status=_menu_find(menu_handle,"filter_pick",mh,mpos,'C');
         if (!status) {
            _menu_delete(mh, mpos);
         }    
      }
      status=_menu_find(menu_handle,"filter_scope",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh, mpos);
      }    
      status=_menu_find(menu_handle,"filter_funcs",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh, mpos);
      }    
      status=_menu_find(menu_handle,"filter_vars",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh, mpos);
      }    
      status=_menu_find(menu_handle,"filter_data",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh, mpos);
      }    
      status=_menu_find(menu_handle,"filter_statements",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh, mpos);
      }    
      status=_menu_find(menu_handle,"filter_others",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh, mpos);
      }    
   }

   // remove quick filters if they do not want them
   if (!include_quick_filters) {
      status=_menu_find(menu_handle,"filter_quick",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh, mpos);
      }    
      status=_menu_find(menu_handle,"sep4",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh, mpos);
      }    
   }

   // Remove the Contents submenu when the parent window is not a 
   // tree control.
   if (p_window_id.p_object != OI_TREE_VIEW) {
      status=_menu_find(menu_handle,"contents",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
   }
}
_command tagBookmarkRunMenu(_str menu_item="") name_info(','VSARG2_CMDLINE|VSARG2_EXECUTE_FROM_MENU_ONLY )
{
   if (menu_item=="") {
      return("");
   }
   _nocheck _control ctl_call_tree_view;
   FormName := p_active_form.p_name;
#if 0
   int formwid = _find_formobj("_tagbookmark_form", "N");
   if (!formwid) return("");
#else
   //1:23pm 8/11/1997 -Dan
   //I think this is ok
   formwid := p_window_id;
#endif

   flags := SE_TAG_FILTER_NULL;
   if (FormName=="_tagbookmark_form") {
      flags = formwid.ctlTagList.p_user;
   } else if (FormName=="_tbtagwin_form") {
      flags = def_tagwin_flags;
   } else if (FormName=="_tbtagrefs_form") {
      flags = def_references_flags;
   } else if (FormName=="_tbfind_symbol_form") {
      flags = def_find_symbol_flags;
   } else if (FormName=="_tbproctree_form" || FormName=="_eclipseProcTreeForm") {
      flags = def_proctree_flags;
   } else if (FormName=="_tbsymbolcalls_form") {
      flags = formwid.ctl_call_tree_view.p_user;
   } else if (FormName=="_tbsymbolcallers_form") {
      flags = formwid.ctl_call_tree_view.p_user;
   } else if (FormName=="_javadoc_form") {
      flags = def_javadoc_filter_flags;
   } else if (FormName=="_javadoc_form") {
      flags = def_xmldoc_filter_flags;
   } else if (FormName=="_tag_select_form") {
      flags = def_tagselect_flags;
   } else if (FormName=="_tbclass_form") {
      flags = def_class_flags;
   }
   orig_case_access_flags := (flags & (SE_TAG_FILTER_CASE_SENSITIVE|SE_TAG_FILTER_ANY_SCOPE|SE_TAG_FILTER_STATEMENT));
   mask := SE_TAG_FILTER_NULL;
   if (substr(menu_item,1,1)=="1") {
      menu_item=substr(menu_item,2);
      flags=orig_case_access_flags;
   }
   switch (menu_item) {
   case "casesensitive": mask = SE_TAG_FILTER_CASE_SENSITIVE; break;
   case "proc":          mask = SE_TAG_FILTER_PROCEDURE;          break;
   case "proto":         mask = SE_TAG_FILTER_PROTOTYPE;         break;
   case "subproc":       mask = SE_TAG_FILTER_SUBPROCEDURE;       break;
   case "define":        mask = SE_TAG_FILTER_DEFINE;        break;
   case "enum":          mask = SE_TAG_FILTER_ENUM;          break;
   case "gvar":          mask = SE_TAG_FILTER_GLOBAL_VARIABLE;          break;
   case "typedef":       mask = SE_TAG_FILTER_TYPEDEF;       break;
   case "struct":        mask = SE_TAG_FILTER_STRUCT;        break;
   case "union":         mask = SE_TAG_FILTER_UNION;         break;
   case "label":         mask = SE_TAG_FILTER_LABEL;         break;
   case "interface":     mask = SE_TAG_FILTER_INTERFACE;     break;
   case "package":       mask = SE_TAG_FILTER_PACKAGE;       break;
   case "var":           mask = SE_TAG_FILTER_MEMBER_VARIABLE;           break;
   case "const":         mask = SE_TAG_FILTER_CONSTANT;      break;
   case "prop":          mask = SE_TAG_FILTER_PROPERTY;      break;
   case "lvar":          mask = SE_TAG_FILTER_LOCAL_VARIABLE;          break;
   case "database":      mask = SE_TAG_FILTER_DATABASE;      break;
   case "gui":           mask = SE_TAG_FILTER_GUI;           break;
   case "include":       mask = SE_TAG_FILTER_INCLUDE;       break;
   case "annotation":    mask = SE_TAG_FILTER_ANNOTATION;    break;
   case "misc":          mask = SE_TAG_FILTER_MISCELLANEOUS; break;
   case "unknown":       mask = SE_TAG_FILTER_UNKNOWN;       break;
   // quick filters
   case "funcs_only":    flags = SE_TAG_FILTER_ANY_PROCEDURE & ~SE_TAG_FILTER_PROTOTYPE; break;
   case "protos_only":   flags = SE_TAG_FILTER_PROTOTYPE;        break;
   case "vars_only":     flags = SE_TAG_FILTER_ANY_DATA;      break;
   case "class_only":    flags = SE_TAG_FILTER_ANY_STRUCT;    break;
   case "defines_only":  flags = SE_TAG_FILTER_DEFINE|SE_TAG_FILTER_ENUM|SE_TAG_FILTER_CONSTANT;       break;
   case "all":           flags = SE_TAG_FILTER_ANYTHING;     break;
   // scopes
   case "public_scope":  mask = SE_TAG_FILTER_SCOPE_PUBLIC;  break;
   case "package_scope": mask = SE_TAG_FILTER_SCOPE_PACKAGE; break;
   case "protected_scope": mask = SE_TAG_FILTER_SCOPE_PROTECTED;break;
   case "private_scope": mask = SE_TAG_FILTER_SCOPE_PRIVATE; break;
   case "static_scope":  mask = SE_TAG_FILTER_SCOPE_STATIC;  break;
   case "extern_scope":  mask = SE_TAG_FILTER_SCOPE_EXTERN;  break;
   }
   // toggle bit mask
   if (mask) {
      flags = (flags & mask)? (flags & (~mask)) : (flags | mask);
   } else {
      flags |= orig_case_access_flags;
   }

   // check for filters by type
   mask_type1 := SE_TAG_TYPE_NULL;
   mask_type2 := SE_TAG_TYPE_NULL;
   mask_type3 := SE_TAG_TYPE_NULL;
   switch (menu_item) {
   case "assign":       mask_type1 = SE_TAG_TYPE_ASSIGN;     break;
   case "break":        mask_type1 = SE_TAG_TYPE_BREAK;
                        mask_type2 = SE_TAG_TYPE_CONTINUE;
                        mask_type3 = SE_TAG_TYPE_GOTO;       break;
   case "call":         mask_type1 = SE_TAG_TYPE_CALL;       break;
   case "if":           mask_type1 = SE_TAG_TYPE_IF;         
                        mask_type2 = SE_TAG_TYPE_SWITCH;     break;
   case "loop":         mask_type1 = SE_TAG_TYPE_LOOP;       break;
   case "return":       mask_type1 = SE_TAG_TYPE_RETURN;     break;
   case "try":          mask_type1 = SE_TAG_TYPE_TRY;        break;
   case "pp":           mask_type1 = SE_TAG_TYPE_PP;         break;
   case "statement":    mask_type1 = SE_TAG_TYPE_STATEMENT;
                        mask_type2 = SE_TAG_TYPE_CLAUSE;
                        mask_type3 = SE_TAG_TYPE_BLOCK;      break;
   case "query":        mask_type1 = SE_TAG_TYPE_QUERY;      break;
   case "control":      mask_type1 = SE_TAG_TYPE_CONTROL;    break;
      break;
   }
   if (mask_type1 != SE_TAG_TYPE_NULL) {
      def_cb_filter_by_types[mask_type1] = def_cb_filter_by_types[mask_type1]? 0:1;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   if (mask_type2 != SE_TAG_TYPE_NULL) {
      def_cb_filter_by_types[mask_type2] = def_cb_filter_by_types[mask_type2]? 0:1;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   if (mask_type3 != SE_TAG_TYPE_NULL) {
      def_cb_filter_by_types[mask_type3] = def_cb_filter_by_types[mask_type3]? 0:1;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   if (menu_item == "all_statements") {
      def_cb_filter_by_types[SE_TAG_TYPE_ASSIGN] = 1;
      def_cb_filter_by_types[SE_TAG_TYPE_BREAK] = 1;
      def_cb_filter_by_types[SE_TAG_TYPE_CALL] = 1;
      def_cb_filter_by_types[SE_TAG_TYPE_CONTINUE] = 1;
      def_cb_filter_by_types[SE_TAG_TYPE_IF] = 1;
      def_cb_filter_by_types[SE_TAG_TYPE_SWITCH] = 1;
      def_cb_filter_by_types[SE_TAG_TYPE_LOOP] = 1;
      def_cb_filter_by_types[SE_TAG_TYPE_RETURN] = 1;
      def_cb_filter_by_types[SE_TAG_TYPE_GOTO] = 1;
      def_cb_filter_by_types[SE_TAG_TYPE_TRY] = 1;
      def_cb_filter_by_types[SE_TAG_TYPE_PP] = 1;
      def_cb_filter_by_types[SE_TAG_TYPE_STATEMENT] = 1;
      def_cb_filter_by_types[SE_TAG_TYPE_CLAUSE] = 1;
      def_cb_filter_by_types[SE_TAG_TYPE_BLOCK] = 1;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   if (menu_item == "all") {
      for (t:=SE_TAG_TYPE_NULL; t<def_cb_filter_by_types._length(); t++) {
         def_cb_filter_by_types[t] = 1;
      }
   }

   if (FormName=="_tagbookmark_form") {
      formwid.ctlTagList.p_user = flags;
      formwid.pushTgBmMatchTags();
   } else if (FormName=="_tbtagrefs_form") {
      def_references_flags&=~(SE_TAG_FILTER_CASE_SENSITIVE|SE_TAG_FILTER_ANYTHING);
      def_references_flags|=flags;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _mdi.p_child._set_focus();
      refs_wid := _GetReferencesWID(true);
      if (refs_wid) {
         refs_wid.refs_update_show_all_check_box();
         refs_wid.refs_update_filter_options(true);
      }
   } else if (FormName=="_tbtagwin_form") {
      def_tagwin_flags&=~(SE_TAG_FILTER_CASE_SENSITIVE|SE_TAG_FILTER_ANYTHING);
      def_tagwin_flags|=flags;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _mdi.p_child._set_focus();
      _UpdateTagWindow(true);
   } else if (FormName=="_tbfind_symbol_form") {
      def_find_symbol_flags&=~(SE_TAG_FILTER_CASE_SENSITIVE|SE_TAG_FILTER_ANYTHING);
      def_find_symbol_flags|=flags;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _mdi.p_child._set_focus();
      _nocheck _control ctl_filter_button;
      _nocheck _control ctl_search_for;
      ctl_filter_button.call_event(CHANGE_CLINE,ctl_filter_button,ON_CHANGE,'W');
      ctl_search_for.call_event(CHANGE_CLINE,ctl_search_for,ON_CHANGE,'W');
   } else if (FormName=="_tbproctree_form" || FormName=="_eclipseProcTreeForm") {
      def_proctree_flags&=~(SE_TAG_FILTER_CASE_SENSITIVE|SE_TAG_FILTER_ANYTHING);
      def_proctree_flags|=flags;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _mdi.p_child._set_focus();
      _mdi.p_child._ProcTreeOptionsChanged(p_active_form);
      _mdi.p_child._UpdateCurrentTag(true);
   } else if (FormName=="_tbclass_form") {
      def_class_flags&=~(SE_TAG_FILTER_CASE_SENSITIVE|SE_TAG_FILTER_ANYTHING);
      flags|=SE_TAG_FILTER_ANY_STRUCT;
      def_class_flags|=flags;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _mdi.p_child._set_focus();
      _mdi.p_child._UpdateClass(true);
   } else if (FormName=="_tbsymbolcalls_form") {
      formwid.ctl_call_tree_view.p_user = flags;
      cb_refresh_calltree_view(null,formwid);
   } else if (FormName=="_tbsymbolcallers_form") {
      formwid.ctl_call_tree_view.p_user = flags;
      cb_refresh_callertree_view(null,formwid);
   } else if (FormName=="_javadoc_form") {
      def_javadoc_filter_flags&=~(SE_TAG_FILTER_CASE_SENSITIVE|SE_TAG_FILTER_ANYTHING);
      def_javadoc_filter_flags|=flags;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _javadoc_refresh_proctree();
   } else if (FormName=="_xmldoc_form") {
      def_xmldoc_filter_flags&=~(SE_TAG_FILTER_CASE_SENSITIVE|SE_TAG_FILTER_ANYTHING);
      def_xmldoc_filter_flags|=flags;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _xmldoc_refresh_proctree();
   } else if (FormName=="_tag_select_form") {
      def_tagselect_flags&=~(SE_TAG_FILTER_CASE_SENSITIVE|SE_TAG_FILTER_ANYTHING);
      def_tagselect_flags|=flags;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _tagselect_refresh_symbols();
   }
   return(flags);
   //_mdi.p_child._set_focus();
}

_command void tagBookmarkCopy(_str action="") name_info(','VSARG2_CMDLINE|VSARG2_EXECUTE_FROM_MENU_ONLY )
{
   form_name := p_active_form.p_name;

   tree_wid := 0;
   if (p_object == OI_TREE_VIEW) {
      tree_wid = p_window_id;
   } else {
      switch (form_name) {
      case "_tbproctree_form":
         _nocheck _control _proc_tree;
         tree_wid = p_active_form._proc_tree;
         break;
      case "_tbtagrefs_form":
         _nocheck _control ctlreferences;
         tree_wid = p_active_form.ctlreferences;
         break;
      case "_tbsymbolcalls_form":
      case "_tbsymbolcallers_form":
         _nocheck _control ctl_call_tree_view;
         tree_wid = p_active_form.ctl_call_tree_view;
         break;
      default:
         _message_box("tagBookmarkCopy: form ='"form_name"'");
         return;
      }
   }

   switch (action) {
   case "item":
      tree_wid._TreeCopyContents(tree_wid._TreeCurIndex(), false);
      break;
   case "tree":
      tree_wid._TreeCopyContents();
      break;
   case "subtree":
      tree_wid._TreeCopyContents(tree_wid._TreeCurIndex());
      break;
   default:
   }
}

_command tagBookmarkSavePrint(_str menu_item="") name_info(','VSARG2_CMDLINE|VSARG2_EXECUTE_FROM_MENU_ONLY )
{
   // verify the form name
   tree_wid := 0;
   _nocheck _control ctl_call_tree_view;
   _nocheck _control ctl_tag_tree_view;
   _nocheck _control ctlreferences;
   _nocheck _control ctlTagList;
   _nocheck _control ctl_symbols;
   _nocheck _control _proc_tree;
   FormName := p_active_form.p_name;
   //_message_box("tagBookmarkSavePrint: form="FormName);
   if (p_object == OI_TREE_VIEW) {
      tree_wid = p_window_id;
   } else {
      switch (FormName) {
      case "_tagbookmark_form":
         tree_wid=p_active_form.ctlTagList;
         break;
      case "_tbfind_symbol_form":
         tree_wid=p_active_form.ctl_symbols;
         break;
      case "_tbproctree_form":
      case "_eclipseProcTreeForm":
         tree_wid=p_active_form._proc_tree;
         break;
      case "_tbsymbolcalls_form":
      case "_tbsymbolcallers_form":
         tree_wid=p_active_form.ctl_call_tree_view;
         break;
      case "_tag_select_form":
         tree_wid=p_active_form.ctl_tag_tree_view;
         break;
      case "_tbtagrefs_form":
         tree_wid=p_active_form.ctlreferences;
         break;
      default:
         // unsupported form name
         return("");
      }
   }

   // OK, we have the tree, now let's rock
   //_message_box("tree_wid="tree_wid.p_name);
   switch (menu_item) {
   // entire tree
   case "save":
      tree_wid._TreeSaveContents();
      break;
   case "print":
      tree_wid._TreePrintContents();
      break;
   // just the sub tree
   case "save2":
      tree_wid._TreeSaveContents(tree_wid._TreeCurIndex());
      break;
   case "print2":
      tree_wid._TreePrintContents(tree_wid._TreeCurIndex());
      break;
   case "searchresults":
      grep_id := promptSearchResultsId();
      if (grep_id < 0) {
         return("");
      }
      switch (FormName) {
      case "_tbfind_symbol_form":
         tree_wid.tbfindsymbol_copy_to_search_results(grep_id);
         break;
      case "_tbtagrefs_form":
         tree_wid.tbtagrefs_copy_to_search_results(grep_id);
         break;
      default:
         // unsupported form name
         return("");
      }
      break;
   case "refsresults":
      switch (FormName) {
      case "_tbfind_symbol_form":
         tree_wid.tbfindsymbol_copy_to_refs_results(grep_id);
         break;
      default:
         // unsupported form name
         return("");
      }
      break;
   // no argument or bad argument
   default:
      return("");
   }
}

/**
 * Increment the reference count for a file that was
 * jumped to by a tagging or search operation.
 * 
 * @param orig_wid      ID of window that was jumped from
 * @param orig_buf_id   Buffer ID of file that was jumped from
 * 
 * @appliesTo Edit_Window
 * @categories Bookmark_Functions
 * 
 * @see def_autoclose_flags
 * @see pop_destination
 * @see pop_bookmark
 */
void push_destination(int orig_wid=0, int orig_buf_id=0)
{
   // get the current reference count, default to 0
   count := 0;
   id :=  p_buf_id"\t"p_buf_name;
   if (gPushTagDestinations._indexin(id)) {
      count = gPushTagDestinations:[id];
   }

   // was this buffer already open beforehand?
   if (!count && gPushTagDestinationAlreadyOpen._indexin(id)) {
      return;
   }

   // increment reference count
   gPushTagDestinations:[id] = count+1;
   if (!gPushTagDestinationModified._indexin(id)) {
      gPushTagDestinationModified:[id] = p_LastModified;
   }

   // check if we need to clean up an old buffer position
   if (orig_wid > 0 && orig_buf_id > 0 && orig_buf_id!=p_buf_id) {
      this_wid := p_window_id;
      if (orig_wid == this_wid) {
         temp_view_id := 0;
         orig_view_id := 0;
         int status = _open_temp_view("",temp_view_id,orig_view_id,"+bi "orig_buf_id);
         if (status==0) {
            if (close_destination()) {
               close_buffer();
            }
            _delete_temp_view(temp_view_id,false);
         }
      } else if (orig_buf_id == orig_wid.p_buf_id) {
         p_window_id=orig_wid;
         if (close_destination()) {
            quit();
         }
      }
      p_window_id = this_wid;
   }
}
/**
 * Decrement the reference count for a file that was
 * jumped to by a tagging or search operation.
 * 
 * @param force         force destination to be popped,
 *                      independent of reference count.
 * @param closeBuffer   close the current buffer?
 * 
 * @return 'true' if the reference count hit zero, 
 *         'false' if not in table or still referenced
 * 
 * @appliesTo Edit_Window
 * @categories Bookmark_Functions
 * 
 * @see def_autoclose_flags
 * @see push_destination
 * @see push_bookmark
 */
bool pop_destination(bool force=false, bool closeBuffer=false)
{
   if (!(def_autoclose_flags & VS_AUTOCLOSE_ENABLED)) {
      gPushTagDestinations._makeempty();
      gPushTagDestinationModified._makeempty();
      gPushTagDestinationAlreadyOpen._makeempty();
      return false;
   }

   // being diffed?
   if (_isdiffed(p_buf_id)) {
      return false;
   }

   // is this buffer in our hash table?
   id :=  p_buf_id"\t"p_buf_name;
   if (!gPushTagDestinations._indexin(id)) {
      return false;
   }
   if (gPushTagDestinationAlreadyOpen._indexin(id)) {
      return false;
   }

   // did the reference count hit zero, if not return now.
   int count = gPushTagDestinations:[id];
   if (!force && count > 1) {
      // decrement reference count
      gPushTagDestinations:[id] = count-1;
      return false;
   }

   // check the last modified value
   typeless last_modified = "";
   if (gPushTagDestinationModified._indexin(id)) {
      last_modified = gPushTagDestinationModified:[id];
   }

   // reference count is zero
   gPushTagDestinations._deleteel(id);
   gPushTagDestinationModified._deleteel(id);

   // has this buffer been modified since it was visited?
   if (p_LastModified != last_modified || p_modify) {
      return false;
   }

   // close the buffer
   if (closeBuffer && close_destination()) {
      bufName := p_buf_name;
      quit();

      // tell the user what we did
      notifyUserOfFeatureUse(NF_AUTO_CLOSE_VISITED_FILE, bufName, 0);

      // restore the current reference in the references tool window
      if (_haveContextTagging()) {
         current_ref(true,true);
      }
   }

   // popped successfully
   return true;
}

void unmark_open_destination() 
{
   id :=  p_buf_id"\t"p_buf_name;
   if (!gPushTagDestinations._indexin(id)) {
      return;
   }

   int count = gPushTagDestinations:[id];
   if (count > 1) {
      // decrement reference count
      gPushTagDestinations:[id] = count-1;
      return;
   }

   // reference count is zero
   gPushTagDestinations._deleteel(id);
   gPushTagDestinationModified._deleteel(id);
}

void mark_open_destination()
{
   id :=  p_buf_id"\t"p_buf_name;
   if (!gPushTagDestinationAlreadyOpen._indexin(id)) {
      gPushTagDestinationAlreadyOpen:[id] = true;
   }
}

/**
 * Flag buffers that were open before jumping to a destination.
 * This helps prevent us from closing a file that appeared to
 * be visited, but was already open.
 */
void mark_already_open_destinations()
{
   int orig_buf_id = p_buf_id;
   for (;;) {
      id :=  p_buf_id"\t"p_buf_name;
      if (!(p_buf_flags & VSBUFFLAG_HIDDEN) &&
          !gPushTagDestinationAlreadyOpen._indexin(id) &&
          !gPushTagDestinations._indexin(id)) {
         gPushTagDestinationAlreadyOpen:[id] = true;
      }
      _next_buffer('hr');
      if (p_buf_id == orig_buf_id) {
         break;
      }
   }
}
/**
 * Check file modification status and optionally prompt to
 * see if file should be automatically closed.
 * 
 * @return true if file should be closed.
 */
static bool close_destination()
{
   // feature disabled, then do not auto-close
   if (!(def_autoclose_flags & VS_AUTOCLOSE_ENABLED)) {
      return false;
   }
   // file is modified, do not close it
   if (p_modify) {
      return false;
   }
   // check the last modified value
   id :=  p_buf_id"\t"p_buf_name;
   if (gPushTagDestinationModified._indexin(id)) {
      // has this buffer been modified since it was visited?
      typeless last_modified = gPushTagDestinationModified:[id];
      if (p_LastModified != last_modified) {
         return false;
      }
   }
   // check if it is in the "already open" list
   if (gPushTagDestinationAlreadyOpen._indexin(id)) {
      return false;
   }
   // file is open in another window, do not close it
   if (!_SafeToDeleteBuffer(p_buf_id,p_window_id,p_buf_flags)) {
      // clear out preview window and references window and check again
      _ClearTagWindowForBuffer(p_buf_id);
      tag_refs_clear_editor(p_buf_id);
      if (!_SafeToDeleteBuffer(p_buf_id,p_window_id,p_buf_flags)) {
         return false;
      }
   }

   // check for multiple views
   wid := p_window_id;
   int buf_id = p_buf_id;
   int last_wid = _last_window_id();
   int i;
   for (i = 1; i <= last_wid; ++i) {
      if (!_iswindow_valid(i) || !i.p_mdi_child || (i.p_window_flags & HIDE_WINDOW_OVERLAP) || (i == wid)) {
         continue;
      }
      if (i.p_buf_id == buf_id) {
         return false;
      }
   }

   // no confirmation prompt, just return 'true' to close file
   if (!(def_autoclose_flags & VS_AUTOCLOSE_CONFIRMATION)) {
      return true;
   }
   // show confirmation before closing file
   return show("-modal _auto_close_file_form",p_buf_name);
}

void _cbquit_destinations(int buffid, _str name, _str docname= "", int flags = 0)
{
   id :=  p_buf_id"\t"p_buf_name;
   if (gPushTagDestinationAlreadyOpen._indexin(id)) {
      gPushTagDestinationAlreadyOpen._deleteel(id);
   }
   pop_destination(true);
}

void pop_all_destinations()
{
   gPushTagDestinations._makeempty();
   gPushTagDestinationModified._makeempty();
   gPushTagDestinationAlreadyOpen._makeempty();
}

void _wkspace_close_pop_bookmarks()
{
   pop_all_bookmarks();
   pop_all_destinations();
}

////////////////////////////////////////////////////////////////////////////
// Auto close form handlers
// 
defeventtab _auto_close_file_form;
static void save_auto_close_options()
{
   // compute new flags
   new_auto_close_flags := 0;
   switch (ctl_auto_close.p_value) {
   case 0:  // disable
      new_auto_close_flags = 0;
      break;
   case 1:  // enable
      new_auto_close_flags = VS_AUTOCLOSE_ENABLED;
      break;
   case 2:  // enable, but prompt
      new_auto_close_flags = VS_AUTOCLOSE_ENABLED|VS_AUTOCLOSE_CONFIRMATION;
      break;
   }

   // check if setting changed
   if (new_auto_close_flags != def_autoclose_flags) {
      def_autoclose_flags = new_auto_close_flags;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}
void ctl_no_btn.lbutton_up()
{
   save_auto_close_options();
   p_active_form._delete_window(false);
}
void ctl_yes_btn.lbutton_up()
{
   save_auto_close_options();
   p_active_form._delete_window(true);
}
void ctl_yes_btn.on_create(_str file_name="")
{
   // plug file name into the file name prompt
   caption := ctl_file_label.p_caption;
   file_name = ctl_file_label._ShrinkFilename(file_name,ctl_file_label.p_width);
   caption = nls(caption,file_name);
   ctl_file_label.p_caption=caption;

   // set up value for three-state check box
   if (!(def_autoclose_flags & VS_AUTOCLOSE_ENABLED)) {
      ctl_auto_close.p_value=0;
   } else if (!(def_autoclose_flags & VS_AUTOCLOSE_CONFIRMATION)) {
      ctl_auto_close.p_value=1;
   } else {
      ctl_auto_close.p_value=2;
   }
}
void _auto_close_file_form."n"()
{
   call_event(ctl_no_btn,LBUTTON_UP,'w');
}
void _auto_close_file_form."y"()
{
   call_event(ctl_yes_btn,LBUTTON_UP,'w');
}
void _auto_close_file_form.ESC()
{
   p_active_form._delete_window(false);
}


