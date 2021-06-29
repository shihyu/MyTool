////////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc. 
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
#include "cbrowser.sh"
#include "tagsdb.sh"
#import "cbrowser.e"
#import "context.e"
#import "dlgman.e"
#import "files.e"
#import "ini.e"
#import "math.e"
#import "pushtag.e"
#import "picture.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tagrefs.e"
#import "tags.e"
#import "tagwin.e"
#import "se/tags/TaggingGuard.e"
#import "se/ui/toolwindow.e"
#import "se/util/MousePointerGuard.e"
#endregion


//##############################################################################
//##############################################################################

/**
 * The name of the symbol calls/uses tool window form.
 */
static const TBSYMBOLCALLS_FORM   = "_tbsymbolcalls_form";
/**
 * The name of the symbol callers/refs tool window form.
 */
static const TBSYMBOLCALLERS_FORM = "_tbsymbolcallers_form";


//##############################################################################
//##############################################################################

/**
 * Struct for keeping track of calls/callers tool window form instances.
 */
struct TBSYMBOLCALLS_FORM_INFO {
   int m_form_wid;
};

/**
 * Hash table of all instances of calls/uses tool window.
 */
static TBSYMBOLCALLS_FORM_INFO gtbSymbolCallsFormList:[];

/**
 * Hash table of all instances of callers/refs tool window.
 */
static TBSYMBOLCALLS_FORM_INFO gtbSymbolCallersFormList:[];


//##############################################################################
//##############################################################################

/**
 * Timer ID for call tree (or caller tree) update timer for updating the 
 * preview tool window, and other tagging tool windows as required. 
 */
static int gCallTreeUpdateTimerId=-1;

/**
 * Timer ID for call tree (or caller tree) to display hover-over information 
 * for the current symbol under the mouse in the tool window's tree control. 
 */
static int gCallTreeHighlightTimerId=-1;

/**
 * Timer ID for call tree update timer for expanding the call/uses tree.
 */
static int gCallTreeExpandTimerId=-1;

/**
 * Timer ID for caller tree update timer for expanding the callers/refs tree.
 */
static int gCallerTreeExpandTimerId=-1;

/**
 * Boolean variable to indicate if call tree (or caller tree) expansion is 
 * to be cancelled.  Usually false, set to 'true' if the user clicks the 
 * "Stop" button for the form being expanded. 
 */
static bool gCallTreeExpandCancelled=false;


//##############################################################################
//##############################################################################

/** 
 * Arguments to pass to {@link call_tree_add_file_uses()}
 */
struct CALLTREE_ADD_FILE_USES_ARGS
{

   /**
    * Tree control to insert into (always ctl_call_tree_view)
    * We do not really need this, we can get it from context.
    */
   int tree_wid;

   /**
    * Tree index to insert items under, when exapnding a node in the call tree.
    */
   int tree_index;

   /**
    * Path to file containing the symbol whos calls are being expanded.
    */
   _str file_name;
   /**
    * Line number of the symbol being expanded.
    */
   int line_no;

   /**
    * Alternate file path for the symbol being expanded.
    */
   _str alt_file_name;
   /**
    * Alternate line number for the symbol being expanded.
    */
   int alt_line_no;

   /**
    * Full symbol information to match
    */
   struct VS_TAG_BROWSE_INFO cm;

   /**
    * Tag filter flags (bitset of VS_TAG_FILTER_*)
    */
   SETagFilterFlags filter_flags;
   /**
    * Tag context filter flags (bitset of VS_TAGCONTEXT_*)
    */
   SETagContextFlags context_flags;

   /**
    * Start seek position of symbol being expanded 
    * (beginning of range to start looking for calls in). 
    */
   long start_seekpos; 
   /**
    * End seek position of symbol being expanded 
    * (end of range to start looking for calls in). 
    */
   long stop_seekpos;

   /**
    * Current recursive depth when expanding tree.
    */
   int depth;

   /**
    * Maximum number of references to find
    */
   int max_refs;
};


//##############################################################################
//##############################################################################

/** 
 * Struct used to store variables used to cache various calculations 
 * when expanding call tree.  Caching this information this way allows 
 * us to make the process of expanding the call tree restartable, and 
 * for it to take place on a timer callback.
 */
struct CALLTREE_EXPANDING_CACHE
{
   /**
    * Array of arguments to pass to {@link call_tree_add_file_uses()} 
    * This forms the data type for the queue used to process items one 
    * at a time, in order to expand the call tree breadth-first in a 
    * peaceful and orderly manner.
    */
   CALLTREE_ADD_FILE_USES_ARGS matchUsesInFileArray[];

   /**
    * Index into above array (next item to process). 
    */
   int array_index;

   /**
    * Number of items deleted from the head of the queue.
    */
   int num_items_deleted;

   /**
    * Hash table of symbol names already expanded.
    */
   bool been_there_done_that:[];

   /**
    * Number of references found so far.
    */
   int num_refs;

   /**
    * Cache of prior context tagging results.
    */
   VS_TAG_RETURN_TYPE visited:[];
};

/**
 * @return
 * Returns a pointer to the instance of the struct used to cache information 
 * as we expand the call tree in a breadth-first manner. 
 * 
 * @param resetCache   (optional) pass 'true' to empty the cache 
 *                     and start from scratch
 *  
 * @see CALLTREE_EXPANDING_CACHE 
 * @see getCallTreeFindInFileArgs()
 * @see addCallTreeFindInFileArgs()
 */
static CALLTREE_EXPANDING_CACHE *getCallerTreeCache(bool resetCache=false)
{
   CALLTREE_EXPANDING_CACHE *pCallTreeCache = _GetDialogInfoHtPtr("call_tree_cache");
   if (resetCache || pCallTreeCache == null || *pCallTreeCache == null) {
      CALLTREE_EXPANDING_CACHE a;
      a.matchUsesInFileArray = null;
      a.array_index = 0;
      a.num_items_deleted = 0;
      a.visited = null;
      a.been_there_done_that = null;
      a.num_refs = 0;
      _SetDialogInfoHt("call_tree_cache", a);
      pCallTreeCache = _GetDialogInfoHtPtr("call_tree_cache");
   }
   return pCallTreeCache;
}

/** 
 * @return
 * Get the next set of arguments to use in order to expand the call tree 
 * for a single symbol.  Returns 'null' if there are no more symbols to expand.
 * 
 * @see CALLTREE_ADD_FILE_USES_ARGS 
 * @see CALLTREE_EXPANDING_CACHE 
 * @see addCallTreeFindInFileArgs()
 */
static CALLTREE_ADD_FILE_USES_ARGS getCallTreeFindInFileArgs() 
{
   pCallTreeCache := getCallerTreeCache();
   if (pCallTreeCache != null) {
      index := pCallTreeCache->array_index;
      if (index < pCallTreeCache->matchUsesInFileArray._length()) {
         pCallTreeCache->array_index++;
         _nocheck _control ctl_progress;
         ctl_progress.p_value = pCallTreeCache->num_items_deleted + index;
         return pCallTreeCache->matchUsesInFileArray[index];
      }
   }
   return null;
}

/**
 * Add another item to the queue of symbols to expand the call tree for.
 * 
 * @param addUsesArgs   struct containing arguments to pass to 
 *                      {@link call_tree_add_file_uses()}
 * 
 * @see CALLTREE_ADD_FILE_USES_ARGS 
 * @see CALLTREE_EXPANDING_CACHE 
 * @see addCallTreeFindInFileArgs()
 */
static void addCallTreeFindInFileArgs(CALLTREE_ADD_FILE_USES_ARGS addUsesArgs) 
{
   pCallTreeCache := getCallerTreeCache();
   if (pCallTreeCache != null) {
      n := pCallTreeCache->matchUsesInFileArray._length();
      pCallTreeCache->matchUsesInFileArray[n] = addUsesArgs;
      _nocheck _control ctl_progress;
      ctl_progress.p_max = n+1+pCallTreeCache->num_items_deleted;
   }
}


//##############################################################################
//##############################################################################

/**
 * Called when this module is loaded (before defload). 
 * Used to initialize the timer variable and window IDs.
 */
definit()
{
   // IF editor is initializing from invocation
   if (arg(1)!='L') {
      gCallTreeUpdateTimerId=-1;
      gCallTreeHighlightTimerId=-1;
      gCallTreeExpandTimerId=-1;
      gCallTreeExpandCancelled=false;
      gCallerTreeExpandTimerId=-1;
   }
   gtbSymbolCallsFormList._makeempty();
   gtbSymbolCallersFormList._makeempty();
   _init_all_formobj();
}

/**
 * Initialze all form objects in order to keep track of all the active 
 * instances of the symbol calls/uses tool windows and symbol callers/refs 
 * tool windows. 
 */
static void _init_all_formobj() 
{
   gtbSymbolCallsFormList._makeempty();
   gtbSymbolCallersFormList._makeempty();

   last := _last_window_id();
   for (i:=1; i<=last; ++i) {
      if (_iswindow_valid(i) && i.p_object == OI_FORM && !i.p_edit) {
         if (i.p_name:==TBSYMBOLCALLS_FORM) {
            gtbSymbolCallsFormList:[i].m_form_wid=i;
         } else if (i.p_name:==TBSYMBOLCALLERS_FORM) {
            gtbSymbolCallersFormList:[i].m_form_wid=i;
         }
      }
   }
}

/**
 * Clean up all static variables on exit.
 */
void _exit_SymbolCallsToolWindow() 
{
   gtbSymbolCallsFormList._makeempty();
   gtbSymbolCallersFormList._makeempty();
   gCallTreeUpdateTimerId=-1;
   gCallTreeExpandTimerId=-1;
   gCallTreeHighlightTimerId=-1;
   gCallerTreeExpandTimerId=-1;
   gCallTreeExpandCancelled=false;
}


//##############################################################################
//##############################################################################

/**
 * Start the call tree (or caller tree) expand/update/highlight timer.
 *  
 * @param timer_id       Global variable containing timer ID
 * @param form_wid       Form initiating the action
 * @param timer_cb       Callback function to call on the timer
 * @param index          tree index for item being expanded or updated
 * @param timer_delay    timer delay in ms
 */
static void call_tree_start_timer(int &timer_id, 
                                  int form_wid, 
                                  typeless timer_cb, 
                                  int index=-1, 
                                  int timer_delay=0)
{
   if (gtbSymbolCallsFormList._length()   ||
       gtbSymbolCallersFormList._length() ||
       _GetTagwinWID(false) || 
       _GetReferencesWID(false)) {
      // kill the existing timer and start a new one
      if (timer_id != -1) {
         call_tree_kill_timer(timer_id);
      }
      if (timer_delay <= 0) {
         timer_delay=max(CB_TIMER_DELAY_MS,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
      }
      timer_id = _set_timer(timer_delay, timer_cb, form_wid" "index);
   }
}

/**
 * Kill the existing symbol call tree (or caller tree) 
 * expand/update/highlight timer
 */
static void call_tree_kill_timer(int &timer_id)
{
   if (timer_id != -1) {
      _kill_timer(timer_id);
      timer_id=-1;
   }
}


//##############################################################################
//##############################################################################

/** 
 * Handlers for symbol Uses/Calls tool window. 
 *  
 * Parts of these handlers are also used by the Symbol Refs/Callers tool window.
 */
defeventtab _tbsymbolcalls_form;


//##############################################################################
//##############################################################################

/**
 * Cancel button handler for symbol calls/uses and symbol callers/refs 
 * tool window.  Hitting the Stop button stops the breadth-first expansion 
 * of the tree. 
 */
void ctl_cancel_button.lbutton_up()
{
   gCallTreeExpandCancelled=true;
   ctl_expand_button.p_enabled = true;
   ctl_cancel_button.p_enabled = false;
   ctl_progress.p_visible = false;
}

/**
 * If the form is destroyed, make sure that it is interpreted as a cancel action. 
 */
void ctl_cancel_button.on_destroy()
{
   gCallTreeExpandCancelled=true;
}

/** 
 * @return
 * Check if the cancel button had been pressed.  Return 'true' if so.
 * 
 * @param checkFrequency    how often (in ms) to check if the button was pressed
 */
static bool check_call_tree_cancel_button(int checkFrequency=250)
{
   // was the cancel button pressed?
   if (gCallTreeExpandCancelled) {
      return true;
   }

   // check when this function was called 
   if (checkFrequency > 0) {
      static typeless last_time;
      typeless this_time = _time('b');
      if ( isnumber(last_time) && this_time-last_time < checkFrequency ) {
         return false;
      }
      last_time = this_time;
   }

   progress_wid := _find_control("ctl_progress");
   if (progress_wid > 0) {
      progress_wid.p_value++;
   }

   // prepare to safely call process events
   orig_use_timers := _use_timers;
   orig_def_actapp := def_actapp;
   def_actapp=0;
   _use_timers=0;
   orig_view_id := p_window_id;
   activate_window(VSWID_HIDDEN);
   orig_hidden_buf_id := p_buf_id;
   save_pos(auto orig_hidden_pos);

   // process mouse clicks, redraws, etc
   process_events(gCallTreeExpandCancelled);

   // restore everything after calling process events
   activate_window(VSWID_HIDDEN);

   p_buf_id=orig_hidden_buf_id;
   restore_pos(orig_hidden_pos);
   if (_iswindow_valid(orig_view_id)) {
      activate_window(orig_view_id);
   }
   _use_timers=orig_use_timers;
   def_actapp=orig_def_actapp;
   return gCallTreeExpandCancelled;
}

/**
 * Disable the cancel button and hide the progress guage on the symbol 
 * calls/uses or callers/refs tool window.  The active form wid needs 
 * to be the symbol calls/caller tool window.
 */
static void call_tree_disable_cancel()
{
   gCallTreeExpandCancelled=true;
   ctl_expand_button.p_enabled = true;
   ctl_cancel_button.p_enabled = false;
   ctl_progress.p_visible = false;
}

/**
 * Ensable the cancel button and make the progress guage visible on the 
 * symbol calls/uses or callers/refs tool window.  The active form wid needs 
 * to be the symbol calls/caller tool window.
 */
static void call_tree_enable_cancel()
{
   gCallTreeExpandCancelled=false;
   ctl_expand_button.p_enabled = false;
   ctl_cancel_button.p_enabled = true;
   ctl_cancel_button.p_visible = true;
   ctl_progress.p_enabled = true;
   ctl_progress.p_visible = true;
}


//##############################################################################
//##############################################################################

/** 
 * @return 
 * Return the virtual root index for the calls/uses tree control 
 * or the callers/refs tree control.
 */
static int callTreeRootIndex()
{
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index < 0) return TREE_ROOT_INDEX;
   return index;
}

/**
 * Retrieve information for the current node from call/uses tree.
 *  
 * p_window_id must be the references or call (uses) tree control. 
 * 
 * @param index      tree node index to fetch information for 
 * @param cm         [output] set to tag information for current node
 * @param inst_id    [output] instance ID (for BSC reference databases
 * @param depth      seach depth
 * 
 * @return Returns 1 on success, &lt;=0 on failure.
 */
static int call_tree_get_tag_info(int index, 
                                  struct VS_TAG_BROWSE_INFO &cm, 
                                  int &inst_id, 
                                  int depth=1)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   tag_init_tag_browse_info(cm);
   if (index < 0 || !_TreeIndexIsValid(index)) {
      return 0;
   }

   // open the tag database for business
   status := 0;
   is_tag_database := false;
   ref_database := refs_filename();
   if (ref_database != "") {
      status = tag_read_db(ref_database);
      if ( status < 0 ) {
         return 0;
      }
   } else {
      is_tag_database=true;
   }

   // get the file name and line number, tag database, and instance ID
   ucm := _TreeGetUserInfo(index);
   parse ucm with cm.file_name ";" auto line_no ";" auto iid ";" cm.tag_database;
   if (line_no == "") {
      line_no = 0;
   }
   cm.line_no = (line_no=="")? 1:((int)line_no);
   inst_id    = (iid=="")?     0:((int)iid);

   // get details about the instance (tag)
   if (inst_id > 0 && !is_tag_database) {
      typeless df,dl;
      tag_get_instance_info(inst_id, cm.member_name, cm.type_name, cm.flags, cm.class_name, cm.arguments, df, dl);
   } else {
      // normalize member name
      tag_tree_decompose_caption(_TreeGetCaption(index),cm.member_name,cm.class_name,cm.arguments);
   }

   // try to figure out the type of the item, based
   // on the bitmap used
   show_children := 0;
   cm.type_name="";
   _TreeGetInfo(index,show_children,auto pic_ref1,auto pic_ref2);
   type_id := tag_get_type_for_bitmap(pic_ref1);
   if (type_id==SE_TAG_TYPE_NULL && pic_ref2 != pic_ref1) {
      type_id = tag_get_type_for_bitmap(pic_ref2);
   }
   if (type_id!=SE_TAG_TYPE_NULL) {
      tag_get_type(type_id, cm.type_name);
   }
   if (_chdebug) {
      isay(depth, "call_tree_get_tag_info: type_id="type_id" type_name="cm.type_name);
   }

   // is the given file_name and line number valid?
   if (cm.file_name != "") {
      if (cm.line_no > 0 && (path_search(cm.file_name)!="" || _isfile_loaded(cm.file_name))) {
         if (!_QBinaryLoadTagsSupported(cm.file_name)) {
            return 1;
         }
      }
   }

   // count the number of exact matches for this tag
   search_file_name  := cm.file_name;
   search_type_name  := cm.type_name;
   search_class_name := cm.class_name;
   search_arguments := "";//VS_TAGSEPARATOR_args:+cm.arguments;
   if (_QBinaryLoadTagsSupported(search_file_name)) {
      cm.language="java";
      search_file_name="";
   } else {
      cm.language = _Filename2LangId(search_file_name);
   }
   jar_cm := cm;
   jar_cm.member_name="";
   tag_files := tags_filenamea(cm.language);
   i:=0;
   tag_filename := next_tag_filea(tag_files,i,false,true);
   while (tag_filename != "") {
      // search for exact match
      alt_type_name := search_type_name;
      status = tag_find_tag(cm.member_name, search_type_name, search_class_name, search_arguments);
      if (status < 0) {
         if (search_type_name :== "class") {
            alt_type_name = "interface";
            status = tag_find_tag(cm.member_name, alt_type_name, search_class_name, search_arguments);
         } else if (search_type_name :== "func") {
            alt_type_name = "proto";
            status = tag_find_tag(cm.member_name, alt_type_name, search_class_name, search_arguments);
         } else if (search_type_name :== "proc") {
            alt_type_name = "procproto";
            status = tag_find_tag(cm.member_name, alt_type_name, search_class_name, search_arguments);
         }
      }
      while (status == 0) {

         // get basic information for this tag, check type and class
         tag_get_tag_browse_info(cm);
         if (cm.type_name :!= search_type_name && cm.type_name != alt_type_name) {
            break;
         }
         //if (cm.class_name :!= search_class_name) {
         //   break;
         //}
         // file name matches, then we've found our perfect match!!!
         if (search_file_name == "" || _file_eq(search_file_name, cm.file_name)) {

            // check if there is a load-tags function, if so, bail out
            if (_QBinaryLoadTagsSupported(cm.file_name)) {
               jar_cm=cm;
            } else {
               tag_reset_find_tag();
               cm.tag_database=tag_filename;
               return 1;
            }
         }
         // get next tag
         status = tag_next_equal(true /*case sensitive*/);
      }
      tag_reset_find_tag();

      // try the next tag file
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }
   if (jar_cm.member_name != "") {
      cm = jar_cm;
      return 1;
   }

   return 0;
}

//##############################################################################
//##############################################################################

/**
 * Refresh the call tree view, recursively, this is for when
 * the filter flags are changed.
 * 
 * @param index      tree node index to fetch information for 
 */
static void call_tree_refresh_tree_recursive(int index=TREE_ROOT_INDEX)
{
   // check if they hit 'cancel'
   if (check_call_tree_cancel_button()) {
      return;
   }

   // make sure the root index is adjusted to be the symbol name
   if (index <= TREE_ROOT_INDEX) {
      index = callTreeRootIndex();
   }

   // for each child of this node, go recursive
   i := _TreeGetFirstChildIndex(index);
   while (i > 0) {
      show_children := 0;
      _TreeGetInfo(i,show_children);
      if (show_children == TREE_NODE_EXPANDED) {
         call_tree_refresh_tree_recursive(i);
      }
      i = _TreeGetNextSiblingIndex(i);
   }

   // now do this node
   call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');
}

/**
 * @return 
 * Return the window Id of the current active symbol uses/calls tree. 
 */
int _tbGetActiveSymbolCallsForm()
{
   if (!_haveContextTagging()) return 0;
   return tw_find_form(TBSYMBOLCALLS_FORM);
}


//##############################################################################
//##############################################################################

/** 
 * @return 
 * Return string to encode as user-info for each node in the call tree.
 * 
 * @param file_name     file name of symbol referenced
 * @param line_no       line number of symbol call location
 * @param inst_id       symbol instance ID        
 * @param tag_filename  tag file name
 */
static _str call_tree_create_user_info(_str &file_name, 
                                       int line_no, 
                                       int tag_id, 
                                       _str &tag_filename)
{
   return file_name ";" line_no ";" tag_id ";" tag_filename;
}


//##############################################################################
//##############################################################################

/**
 * Refresh the call tree window with the given tag information. 
 * If they do not give a specific form ID, it will refresh all call trees.
 * 
 * @param cm         Symbol information to fill all tree with
 * @param form_wid   Symbol calls/uses tool window form ID
 */
void cb_refresh_calltree_view(struct VS_TAG_BROWSE_INFO cm, int form_wid=-1)
{
   if (!_haveContextTagging()) {
      return;
   }

   // Refresh the specific form requested
   f := form_wid;
   if (f > 0) {
      f.call_tree_refresh_tree_for_one_window(cm);
      return;
   }

   // refresh all instances of the arguments toolbar
   cbrowser_form := p_active_form;
   found_one := false;
   foreach (f => . in gtbSymbolCallsFormList) {
      if (tw_is_from_same_mdi(f,cbrowser_form)) {
         found_one=true;
         f.call_tree_refresh_tree_for_one_window(cm);
      }
   }
   if (!found_one) {
      f=_tbGetActiveSymbolCallsForm();
      if (f) {
         f.call_tree_refresh_tree_for_one_window(cm);
      }
   }
}

/**
 * Refresh the given call tree window with the given tag information. 
 *  
 * The current window is expected to be a symbol calls/uses tool window form.
 * 
 * @param cm         Symbol information to fill all tree with
 */
static void call_tree_refresh_tree_for_one_window(struct VS_TAG_BROWSE_INFO cm)
{
   if (!_haveContextTagging()) {
      return;
   }

   _nocheck _control ctl_stack_view;
   _nocheck _control ctl_call_tree_view;
   form_wid := p_active_form;
   if (!_iswindow_valid(form_wid) || form_wid.p_name!=TBSYMBOLCALLS_FORM) {
      return;
   }

   // just refresh the existing view, recursively, if cm==null
   if (cm==null) {
      form_wid.call_tree_enable_cancel();
      form_wid.ctl_call_tree_view.p_redraw=false;
      form_wid.ctl_call_tree_view.call_tree_refresh_tree_recursive();
      form_wid.ctl_call_tree_view.p_redraw=true;
      if (!check_call_tree_cancel_button()) {
         form_wid.call_tree_disable_cancel();
      }
      return;
   }

   // bail out if we have no member name
   if (!VF_IS_STRUCT(cm) || cm.member_name=="") {
      return;
   }

   // make sure that cm is totally initialized
   if (cm.tag_database._isempty())   cm.tag_database = "";
   if (cm.category._isempty())       cm.category = "";
   if (cm.class_name._isempty())     cm.class_name = "";
   if (cm.member_name._isempty())    cm.member_name = "";
   if (cm.qualified_name._isempty()) cm.qualified_name = "";
   if (cm.type_name._isempty())      cm.type_name = "";
   if (cm.file_name._isempty())      cm.file_name = "";
   if (cm.return_type._isempty())    cm.return_type = "";
   if (cm.arguments._isempty())      cm.arguments = "";
   if (cm.exceptions._isempty())     cm.exceptions = "";
   if (cm.class_parents._isempty())  cm.class_parents = "";
   if (cm.template_args._isempty())  cm.template_args = "";

   // same call tree as last time?
   struct VS_TAG_BROWSE_INFO cm2 = form_wid._GetDialogInfoHt("tag_info");
   if (tag_browse_info_equal(cm,cm2)) {
      return;
   }
   form_wid._SetDialogInfoHt("tag_info", cm);
   form_wid.getCallerTreeCache(true);

   // check if there is a load-tags function, if so, bail out
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      return;
   }

   // refresh the call tree view
   if (cm.member_name == "") {
      form_wid.ctl_stack_view._TreeDelete(TREE_ROOT_INDEX, 'c');
      form_wid.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
      form_wid.ctl_call_tree_view._TreeAddItem(TREE_ROOT_INDEX, "No function selected", TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      return;
   }

   // construct the item caption
   item_name := tag_make_caption_from_browse_info(cm, include_class:true, include_args:true, include_tab:true);

   ref_database := refs_filename();
   enable_refs := (ref_database == "")? 0:1;
   inst_id := 0;

   // open the tag database for business
   orig_database := tag_current_db();
   if (ref_database == "") {
      //form_wid.ctl_stack_view._TreeDelete(TREE_ROOT_INDEX, 'c');
      //form_wid.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
      //return;
   } else {
      status := tag_read_db(ref_database);
      if ( status < 0 ) {
         form_wid.ctl_stack_view._TreeDelete(TREE_ROOT_INDEX, 'c');
         form_wid.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
         return;
      }

      // match tag up with instance in references database
      inst_id = tag_match_instance(cm.member_name, cm.type_name, 0, cm.class_name, cm.arguments, cm.file_name, cm.line_no, 1);

      // close the references database and
      // revert back to the original tag database
      status = tag_close_db(ref_database,true);
      s2 := tag_read_db(orig_database);
      if ( status < 0 ) {
         form_wid.ctl_stack_view._TreeDelete(TREE_ROOT_INDEX, 'c');
         form_wid.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
         return;
      }
   }

   // compute name / line number string for sorting
   ucm := call_tree_create_user_info(cm.file_name, cm.line_no, inst_id, cm.tag_database);

   // clear out the call tree
   form_wid.ctl_stack_view._TreeDelete(TREE_ROOT_INDEX, 'c');
   form_wid.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');

   // find the bitmap for this item
   pic_ref := tag_get_bitmap_for_type(tag_get_type_id(cm.type_name), cm.flags, auto pic_overlay);

   // set up root function
   treeRoot := form_wid.ctl_call_tree_view._TreeAddItem(TREE_ROOT_INDEX, item_name, TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1, pic_overlay, pic_ref, TREE_NODE_COLLAPSED, 0, ucm);
   form_wid.ctl_call_tree_view._TreeSizeColumnToContents(0);

   // look up and insert the items called
   form_wid.ctl_call_tree_view._TreeSetInfo(treeRoot, TREE_NODE_EXPANDED);
   form_wid.ctl_call_tree_view.call_event(CHANGE_EXPANDED,
                                          treeRoot,
                                          form_wid.ctl_call_tree_view,
                                          ON_CHANGE,
                                          'w');
   form_wid.call_tree_update_symbol_trace();
}


//##############################################################################
//##############################################################################

/**
 * Initialize the symbol calls/uses tree tool window.
 */
void _tbsymbolcalls_form.on_create()
{
   TBSYMBOLCALLS_FORM_INFO info;
   info.m_form_wid=p_active_form;
   gtbSymbolCallsFormList:[p_active_form]=info;

   ctl_call_tree_view.p_user = _retrieve_value(TBSYMBOLCALLS_FORM:+".ctl_call_tree_view.p_user");
   if (ctl_call_tree_view.p_user == "") {
      ctl_call_tree_view.p_user = 0xffffffff;
   }

   // reduced level indent
   ctl_call_tree_view.p_LevelIndent = _dx2lx(SM_TWIP, 12);

   // cancel button is disabled until they hit "Expand"
   ctl_expand_button.p_enabled = true;
   ctl_cancel_button.p_enabled = false;
   ctl_progress.p_visible = false;

   ypos := _moncfg_retrieve_value(TBSYMBOLCALLS_FORM:+".ctl_size_y.p_y");
   if (isuinteger(ypos)) {
      ctl_size_y.p_y = ypos;
   }
}

/**
 * Clean up the symbol calls/uses tree tool window when the form is destroyed. 
 * Make sure all timer functions are stopped. 
 */
void _tbsymbolcalls_form.on_destroy()
{
   _append_retrieve(0, ctl_call_tree_view.p_user, TBSYMBOLCALLS_FORM:+".ctl_call_tree_view.p_user");
   _moncfg_append_retrieve(0,ctl_size_y.p_y,TBSYMBOLCALLS_FORM:+".ctl_size_y.p_y");
   call_event(p_window_id,ON_DESTROY,'2');
   call_tree_kill_timer(gCallTreeUpdateTimerId);
   call_tree_kill_timer(gCallTreeExpandTimerId);
   call_tree_kill_timer(gCallTreeHighlightTimerId);
   gtbSymbolCallsFormList._deleteel(p_active_form);
}

//##############################################################################
//##############################################################################

/**
 * Expand all items at all depths of the call tree. 
 *  
 * This will queue up tree nodes to be expanded and start a timer function 
 * to go through the list and expand them, then after they are expanded, 
 * will queue up the new nodes added, so that the timer function can also 
 * expand them.  This allows it to expand the tree in a breadth-first manner, 
 * rather than diving in too deep down the first path it tries. 
 */
void ctl_expand_button.lbutton_up()
{
   form_wid := p_active_form;
   activate_window(form_wid);
   call_tree_enable_cancel();

   pCallTreeCache := form_wid.getCallerTreeCache(resetCache:true);
   ctl_call_tree_view.p_redraw=false;
   cur_index := ctl_call_tree_view._TreeCurIndex();
   ctl_call_tree_view.call_tree_expand_tree(cur_index,
                                           pCallTreeCache->been_there_done_that, 
                                           pCallTreeCache->visited, 0,
                                           doImmediate:false,
      stopRecursion:false);

   call_tree_start_timer(gCallTreeExpandTimerId, p_active_form, _CallTreeExpandCallback, cur_index);

   if (check_call_tree_cancel_button()) {
      form_wid.call_tree_disable_cancel();
   }
   activate_window(form_wid);
   ctl_call_tree_view._TreeSetCurIndex(cur_index);
   ctl_call_tree_view.p_redraw=true;
   ctl_call_tree_view._TreeRefresh();
}

/**
 * Expands the call tree at the given tree node.
 * 
 * @param tree_index             index of tree node to expand
 * @param been_there_done_that   (reference) hash table of tree captions 
 *                               already expanded, so that we do not recursively
 *                               expand the same item's call tree multiple times.
 * @param visited                (reference) context tagging results cache
 * @param depth                  recursive call depth or tree expansion depth
 * @param doImmediate            (default false) expand the tree node immedately?
 * @param stopRecursion          (default true) if 'false' been_there_done_that 
 *                               is ignored for the top-level node. 
 * 
 * @return 
 * Returns 0 on success, &lt;0 on error. 
 */
static int call_tree_expand_tree(int tree_index, 
                                 bool (&been_there_done_that):[],
                                 VS_TAG_RETURN_TYPE (&visited):[], int depth,
                                 bool doImmediate=false,
                                 bool stopRecursion=true)
{
   // check if they hit 'cancel'
   if (check_call_tree_cancel_button()) {
      return COMMAND_CANCELLED_RC;
   }

   // do not expand beyond 32 levels deep
   if (depth > 32) {
      return 0;
   }

   // return if it is a leaf node
   show_children := 0;
   _TreeGetInfo(tree_index,show_children);
   if (show_children == TREE_NODE_LEAF) {
      return 0;
   }

   // already expanded this item?
   caption := _TreeGetCaption(tree_index);
   if (_chdebug) {
      isay(depth, "call_tree_expand_tree: caption="caption);
   }
   if (stopRecursion && been_there_done_that._indexin(caption)) {
      if (_chdebug) {
         isay(depth, "call_tree_expand_tree: BEEN THERE DONE THAT");
      }
      return 0;
   }
   been_there_done_that:[caption]=true;

   // do not expand classes, interfaces, structs, and package names
   tag_init_tag_browse_info(auto cm);
   inst_id := 0;
   if (depth > 0 && call_tree_get_tag_info(tree_index, cm, inst_id, depth+1) > 0) {
      // do not expand package names
      if (tag_tree_type_is_package(cm.type_name)) {
         return 0;
      }
      // expand class names only if the outer item was a class
      if (tag_tree_type_is_class(cm.type_name) || cm.type_name == "enum") {
         parentIndex := _TreeGetParentIndex(tree_index);
         if (parentIndex > 0 && call_tree_get_tag_info(parentIndex, cm, inst_id, depth+1) > 0) {
            if (!tag_tree_type_is_class(cm.type_name) && cm.type_name!="enum" ) {
               return 0;
            }
         }
      }
   }

   // expand node if it is not already expanded
   if (show_children == TREE_NODE_COLLAPSED) {
      se.util.MousePointerGuard hour_glass;
      if (call_tree_get_tag_info(tree_index, cm, inst_id, depth+1) > 0) {
         _TreeBeginUpdate(tree_index);
         count := call_tree_add_uses(tree_index, 
                                    cm, inst_id, 
                                    visited, depth+1, 
                                    doImmediate);
         _TreeEndUpdate(tree_index);
         // sort exactly the way we want things
         _TreeSortUserInfo(tree_index,"UE","E");
         _TreeSortCaption(tree_index,"I");
      }
      if (doImmediate) {
         _TreeSetInfo(tree_index, TREE_NODE_EXPANDED);
      }
   }

   // otherwise, if we get here and the node is already expanded, maybe
   // we need to check the items underneath if they need to be expanded
   if (show_children == TREE_NODE_EXPANDED && !doImmediate) {
      if (_chdebug) {
         isay(depth, "call_tree_expand_tree: EXPAND CHILDREN");
      }
      tree_index = _TreeGetFirstChildIndex(tree_index);
      while (tree_index > 0) {
         if (call_tree_get_tag_info(tree_index, cm, inst_id, depth+1) > 0) {
            call_tree_expand_tree(tree_index, 
                                 been_there_done_that, 
                                 visited, depth+1,
                                 doImmediate:false,
                                 stopRecursion:true);
         }
         tree_index = _TreeGetNextSiblingIndex(tree_index);
      }
   }

   // success
   return 0;
}

//##############################################################################
//##############################################################################

/**
 * Handle resize events for symbol calls/uses tool window and 
 * symbol callers/refs tool window.  This function is shared by both 
 * tool window because they have identical control layouts.
 */
static void call_tree_on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   button_width  := ctl_expand_button.p_width;
   button_height := ctl_expand_button.p_height;

   // have we set the min size yet?  if not, min width will be 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*4, button_height*3);
   }

   // available space and border usage
   avail_x  := p_width;
   avail_y  := p_height;
   border_x := ctl_stack_view.p_x;
   border_y := ctl_stack_label.p_y;

   // we may need to move the size bar into range.
   if (ctl_size_y.p_y < border_y + ctl_stack_label.p_height + border_y) {
      ctl_size_y.p_y = border_y + ctl_stack_label.p_height + border_y;
   } else if (ctl_size_y.p_y > avail_y - border_y*2 - 2*button_height) {
      ctl_size_y.p_y = avail_y - border_y*2 - 2*button_height;
   }

   // size the tree controls
   tree_width := avail_x-border_x;
   ctl_stack_view.p_width      = tree_width;
   ctl_size_y.p_width          = tree_width;
   ctl_call_tree_view.p_width  = tree_width;

   // surround the tree controls around the size bar
   ctl_stack_view.p_y          = border_y + ctl_stack_label.p_height + border_y;
   ctl_stack_view.p_y_extent   = ctl_size_y.p_y;
   ctl_call_tree_view.p_y      = ctl_size_y.p_y_extent;
   ctl_call_tree_view.p_y_extent = avail_y - border_y*2 - button_height;

   // move around the buttons
   button_y := avail_y - button_height - border_y;
   ctl_expand_button.p_y = button_y;
   ctl_cancel_button.p_y = button_y;
   ctl_progress.p_y = button_y;
   ctl_progress.p_x_extent = ctl_call_tree_view.p_x_extent;
}

/**
 * Event handler for resize of "on_resize" event for symbol calls/uses tool window.
 */
void _tbsymbolcalls_form.on_resize() 
{
   call_tree_on_resize();
}


ctl_size_y.lbutton_down()
{
   _ul2_image_sizebar_handler(ctl_stack_view.p_y, ctl_call_tree_view.p_y_extent - 300);
}


//##############################################################################
//##############################################################################

/** 
 * Update the symbol trace when the current item in the symbol calls/uses 
 * tool window or symbol callers/refs tool window changes. 
 * This function is shared by both tool window because they have 
 * identical control layouts. 
 *  
 * @param tree_index   current tree item in the call tree
 */
static void call_tree_update_symbol_trace(int tree_index=0)
{
   // no index passed in?
   if (tree_index <= 0) {
      tree_index = ctl_call_tree_view._TreeCurIndex();
   }


   ctl_call_tree_view._TreeGetInfo(tree_index,
                                   auto ShowChildrenx, 
                                   auto bm1x, auto bm2x,
                                   auto moreFlagsx);


   // check if that item already exists in the call trace, 
   // if so, just make it current, do not rebuild trace.
   found_index := ctl_stack_view._TreeSearch(TREE_ROOT_INDEX, "", "", tree_index);
   if (found_index > 0) {
      ctl_stack_view._TreeSetCurIndex(found_index);
      return;
   }

   // walk up the tree to the root and get all the items.
   int overlays[];
   ctl_stack_view._TreeBeginUpdate(TREE_ROOT_INDEX);
   while (tree_index > 0) {
      caption := ctl_call_tree_view._TreeGetCaption(tree_index);
      ctl_call_tree_view._TreeGetInfo(tree_index,
                                      auto ShowChildren, 
                                      auto bm1, auto bm2,
                                      auto moreFlags);
      ctl_call_tree_view._TreeGetOverlayBitmaps(tree_index, overlays);

      trace_index := ctl_stack_view._TreeAddItem(TREE_ROOT_INDEX, 
                                                 caption,
                                                 TREE_ADD_AS_FIRST_CHILD,
                                                 bm1, bm2,
                                                 -1, 0,
                                                 tree_index);
      if (overlays._length() > 0) {
         ctl_stack_view._TreeSetOverlayBitmaps(trace_index, overlays);
      }

      tree_index = ctl_call_tree_view._TreeGetParentIndex(tree_index);
   }

   // That's all folks
   ctl_stack_view._TreeEndUpdate(TREE_ROOT_INDEX);
   ctl_stack_view._TreeSizeColumnToContents(0);
   ctl_stack_view._TreeRefresh();
}


/**
 * Handle on-change event for symbol call/callers tree stack trace. 
 * This merely delegates the CHANGE_SELECTED events to the call tree. 
 *  
 * @param reason     tree event code (CHANGE_*) 
 * @param currIndex  current tree node index
 */
void ctl_stack_view.on_change(int reason,int currIndex)
{
   if (currIndex <= 0) {
      return;
   }
   if (_chdebug) {
      say("ctl_stack_view.on_change: reason="reason" index="currIndex);
   }

   // get the corresponding tree index
   tree_index := ctl_stack_view._TreeGetUserInfo(currIndex);
   if (!isuinteger(tree_index) || !ctl_call_tree_view._TreeIndexIsValid(currIndex)) {
      return;
   }

   if (reason == CHANGE_LEAF_ENTER || reason == CHANGE_SELECTED) {
      ctl_call_tree_view._TreeSetCurIndex(tree_index);
      call_event(reason, tree_index, ctl_call_tree_view.p_window_id, ON_CHANGE, 'w');
   }
}

/**
 * Handle on-highlight event for symbol call/callers tree stack trace. 
 * This merely delegates the events to the call tree for the given index.
 * 
 * @param index     tree node index under the mouse pointer
 * @param caption   full caption of tree node
 */
void ctl_call_tree_view.on_highlight(int index, _str caption="")
{
   if (index <= 0) {
      return;
   }
   if (_chdebug) {
      say("ctl_call_tree_view.on_highlight: index="index);
   }

   // get the corresponding tree index
   tree_index := ctl_stack_view._TreeGetUserInfo(index);
   if (!isuinteger(tree_index) || !ctl_call_tree_view._TreeIndexIsValid(index)) {
      return;
   }

   call_event(tree_index, ctl_call_tree_view.p_window_id, ON_HIGHLIGHT, 'w');
}


//##############################################################################
//##############################################################################

/**
 * Handle right-mouse button on the symbol calls/uses tree control and 
 * the symbol callers/refs tree control.  This function is shared by both 
 * tool windows because the handling of right-click is identical.
 */
static void call_tree_rbutton_up()
{
   // kill the refresh timer, prevents delays before the menu comes
   // while the refreshes are finishing up.
   call_tree_kill_timer(gCallTreeExpandTimerId);
   call_tree_kill_timer(gCallTreeHighlightTimerId);

   index := find_index("_tagbookmark_menu",oi2type(OI_MENU));
   menu_handle := p_active_form._menu_load(index,'P');

   flags := ctl_call_tree_view.p_user;
   pushTgConfigureMenu(menu_handle, flags, 
                       include_proctree:false, 
                       include_casesens:false, 
                       include_sort:false, 
                       include_save_print:true);

   // Show menu:
   mou_get_xy(auto x,auto y);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

/**
 * Handle right-mouse button on the symbol calls/uses tree control. 
 */
void ctl_call_tree_view.rbutton_up()
{
   call_tree_rbutton_up();
}


//##############################################################################
//##############################################################################

/**
 * Handle double-click event (opens the file and positions us on the
 * line indicated by the reference data), this may or may not be the 
 * right line to be positioned on. 
 */
void ctl_call_tree_view.enter,lbutton_double_click()
{
   // get the context information, push book mark, and open file to line
   tree_index := ctl_call_tree_view._TreeCurIndex();
   status := ctl_call_tree_view.call_tree_get_tag_info(tree_index, auto cm, auto inst_id);
   if (status > 0) {
      push_pos_in_file(cm.file_name, cm.line_no, 0);
   }
}

/**
 * Handles the 'spacebar' event (opens the file and positions us on the
 * line indicated by the reference data), this may or may not be the 
 * right line to be positioned on. 
 */
void ctl_call_tree_view." "()
{
   // IF this is an item we can go to like a class name
   orig_window_id := p_window_id;

   tree_index := ctl_call_tree_view._TreeCurIndex();
   status := ctl_call_tree_view.call_tree_get_tag_info(tree_index, auto cm, auto inst_id);
   if (status > 0) {
      push_pos_in_file(cm.file_name, cm.line_no, 0);
   }

   // restore original focus
   p_window_id = orig_window_id;
   ctl_call_tree_view._set_focus();
}


//##############################################################################
//##############################################################################

/**
 * This is the timer callback for updating other tool windows when an item 
 * is clicked on in the symbol calls/uses tool window. 
 *  
 * Whenever the current index (cursor position) for the call tree is changed, 
 * a timer is started/reset.  If no activity occurs within a set amount of time, 
 * this function is called to update the properties view, inheritance view, 
 * and output window.
 *  
 * Using this allows you to quickly scroll down through items in the tree without 
 * constantly updating other tool windows as we go along.
 *  
 * @param cmdline    information passed from timer, which contains the form 
 *                   window id and the tree index to update tool windows for. 
 */
static void _CallTreeUpdateCallback(_str cmdline)
{
   // kill the timer
   call_tree_kill_timer(gCallTreeUpdateTimerId);

   // get the command line arguments
   parse cmdline with auto sform_wid auto sindex;
   f := (int)sform_wid;
   index := (int)sindex;
   if (!_iswindow_valid(f) || f.p_name!=TBSYMBOLCALLS_FORM) {
      return;
   }

   // get the current tree index
   _nocheck _control ctl_call_tree_view;
   currIndex := f.ctl_call_tree_view._TreeCurIndex();
   if (currIndex<0) {
      return;
   }

   // get the context information, push book mark, and open file to line
   status := f.ctl_call_tree_view.call_tree_get_tag_info(currIndex, auto cm, auto inst_id);
   if (status > 0) {
      // find the output tagwin and update it
      cb_refresh_output_tab(cm, true);
   } else {
      f.ctl_call_tree_view.message_cannot_find_ref(currIndex);
   }
}

/**
 * This is the timer callback for updating tool windows when an item is 
 * highlighted (the mouse hovers over) an item in the symbol calls/uses 
 * tool window. 
 *  
 * This function is very similar, nearly identical, to the callback for 
 * updating the current selected item in the symbol call tree.
 * 
 * @param cmdline    information passed from timer, which contains the form 
 *                   window id and the tree index to update tool windows for. 
 */
static void _CallTreeHighlightCallback(_str cmdline)
{
   // kill the timer
   call_tree_kill_timer(gCallTreeHighlightTimerId);

   parse cmdline with auto sform_wid auto sindex;
   f := (int)sform_wid;
   index := (int)sindex;
   if (!_iswindow_valid(f) || f.p_name!=TBSYMBOLCALLS_FORM) {
      return;
   }
   // get the current tree index
   if (index <= 0) {
      return;
   }

   _nocheck _control ctl_call_tree_view;

   // get the context information, push book mark, and open file to line
   status := f.ctl_call_tree_view.call_tree_get_tag_info(index, auto cm, auto inst_id);
   if (status > 0) {
      // find the output tagwin and update it
      _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
   }
}

/**
 * This is the timer callback for expanding items in the symbol calls/uses 
 * tool window.  It takes an item from a queue of nodes that need expansion, 
 * expands that item in the tree, and then potentially queues up new nodes 
 * which are to be expanded the next time the timer callback is invoked. 
 * Each timer invocation processes one node expansion.  It is broken up this 
 * way in order to minimize delays in the main editor.
 * 
 * @param cmdline    information passed from timer, which contains the form 
 *                   window id only.
 */
static void _CallTreeExpandCallback(_str cmdline)
{
   // hold tight for a bit if the user is doing something
   if (_idle_time_elapsed() < 100) {
      return;
   }

   // get the form wid, and make sure it is a valid call tree tool window
   parse cmdline with auto sform_wid . ;
   form_wid := (int)sform_wid;
   if (!_iswindow_valid(form_wid) || form_wid.p_name!=TBSYMBOLCALLS_FORM) {
      return;
   }

   // check if they hit 'cancel'
   cancel_wid := form_wid.ctl_cancel_button;
   if (form_wid.check_call_tree_cancel_button()) {
      form_wid.call_tree_disable_cancel();
      call_tree_kill_timer(gCallTreeExpandTimerId);
      return;
   }

   // get the cache, this should never return 'null', but check anyway
   pCallTreeCache := form_wid.getCallerTreeCache();
   if (pCallTreeCache == null) {
      call_tree_kill_timer(gCallTreeExpandTimerId);
      form_wid.call_tree_disable_cancel();
      return;
   }

   // get the next argument to process
   addUsesArgs := form_wid.getCallTreeFindInFileArgs();
   if (addUsesArgs == null) {
      call_tree_kill_timer(gCallTreeExpandTimerId);
      form_wid.call_tree_disable_cancel();
      return;
   }

   // get the tree wid and tree index and verify
   tree_wid := addUsesArgs.tree_wid;
   if (tree_wid != form_wid.ctl_call_tree_view.p_window_id) {
      call_tree_kill_timer(gCallTreeExpandTimerId);
      form_wid.call_tree_disable_cancel();
      return;
   }
   tree_index := addUsesArgs.tree_index;
   if (!tree_wid._TreeIndexIsValid(tree_index)) {
      call_tree_kill_timer(gCallTreeExpandTimerId);
      form_wid.call_tree_disable_cancel();
      return;
   }

   // temporarily disable auto-save timers
   orig_use_timers := _use_timers;
   _use_timers=0;

   // now update the items under this tree index
   tree_wid._TreeBeginUpdate(tree_index);
   tree_wid.call_tree_add_file_uses(addUsesArgs.file_name,
                                   addUsesArgs.alt_file_name,
                                   addUsesArgs.alt_line_no,
                                   addUsesArgs.cm,
                                   addUsesArgs.filter_flags,
                                   addUsesArgs.tree_index, 
                                   pCallTreeCache->num_refs,
                                   addUsesArgs.max_refs, 
                                   addUsesArgs.start_seekpos,
                                   addUsesArgs.stop_seekpos,
                                   pCallTreeCache->visited,
                                   addUsesArgs.depth);

   tree_wid._TreeEndUpdate(tree_index);
   tree_wid._TreeSortUserInfo(tree_index,"UE","E");
   tree_wid._TreeSortCaption(tree_index,"I");
   tree_wid._TreeSetInfo(tree_index, TREE_NODE_EXPANDED);

   // now we queue up expandind the new nodes which we just added
   tree_wid.call_tree_expand_tree(tree_index, 
                                 pCallTreeCache->been_there_done_that,
                                 pCallTreeCache->visited,
                                 addUsesArgs.depth+1,
                                 doImmediate:false,
                                 stopRecursion:false);

   // truncate queue if it does not mean moving too many items
   if (pCallTreeCache->matchUsesInFileArray._length() - pCallTreeCache->array_index < 10) {
      pCallTreeCache->matchUsesInFileArray._deleteel(0, pCallTreeCache->array_index);
      pCallTreeCache->num_items_deleted += pCallTreeCache->array_index;
      pCallTreeCache->array_index = 0;
   }

   // re-enabled timers
   _use_timers=orig_use_timers;
}

//##############################################################################
//##############################################################################

/**
 * Add symbol calls/uses to the symbol tree for the given symbol.
 * 
 * @param file_name        name of the file the symbol is defined in
 * @param alt_file_name    alternate file where the symbol may be found in
 * @param alt_line_no      alternate line number the symbol may be found at
 * @param cm               symbol information
 * @param flag_mask        bitset of VS_TAGFITLER_*, for filtering tree 
 *                         to specific types of symbols
 * @param tree_index       tree node index in call tree
 * @param num_refs         (reference) number of references found so far
 * @param max_refs         maximum number of references to find
 * @param start_seekpos    start seek position for range to search
 * @param end_seekpos      end seek position for range to search
 * @param visited          (reference) context tagging results cache
 * @param depth            recursive depth or tree depth
 * 
 * @return Returns the number of items inserted under the tree node.
 */
static int call_tree_add_file_uses(_str file_name,
                                   _str alt_file_name, 
                                   int alt_line_no,
                                   struct VS_TAG_BROWSE_INFO &cm, 
                                   SETagFilterFlags flag_mask,
                                   int tree_index, 
                                   int &num_refs, 
                                   int max_refs,
                                   long start_seekpos, 
                                   long end_seekpos,
                                   VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (_chdebug) {
      isay(depth, "call_tree_add_file_uses("file_name","alt_file_name","alt_line_no","cm.file_name","cm.line_no","cm.seekpos")");
   }
   // open a temporary view of 'file_name'
   tree_wid := p_window_id;
   status := _open_temp_view(file_name,auto temp_view_id,auto orig_view_id,"",auto inmem,false,true);
   if (!status) {
      // go to where the tag should be at
      p_RLine=cm.line_no;
      if (cm.seekpos != null && cm.seekpos > 0) {
         _GoToROffset(cm.seekpos);
         start_seekpos = cm.seekpos;
         end_seekpos   = cm.end_seekpos;
      } else {
         cm.seekpos=(int)_QROffset();
      }

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      _UpdateContext(true);

      if (_chdebug) {
         isay(depth, "call_tree_add_file_uses: cm.member_name="cm.member_name);
      }
      start_line_no := 0;
      case_sensitive := p_EmbeddedCaseSensitive;
      context_id := tag_find_context_iterator(cm.member_name,true,case_sensitive);
      while (context_id > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, start_line_no);
         tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
         tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);
         tag_get_detail2(VS_TAGDETAIL_context_file, context_id, file_name);
         if (cm.line_no == start_line_no) {
            break;
         }
         context_id = tag_next_context_iterator(cm.member_name,context_id,true,case_sensitive);
      }

      _str errorArgs[];
      if (_chdebug) {
         isay(depth, "call_tree_add_file_refs: tag_match_uses_in_file");
         isay(depth, "call_tree_add_file_refs(tree_wid="tree_wid", tree_index="tree_index", case_sensitive="p_LangCaseSensitive);
         isay(depth, "call_tree_add_file_refs(file_name="file_name", start_line_no="start_line_no", alt_file_name="alt_file_name", alt_line_no="alt_line_no);
         isay(depth, "call_tree_add_file_refs(flag_mask=0x"_dec2hex(flag_mask)", context_id="context_id);
         isay(depth, "call_tree_add_file_refs(start_seekpos="start_seekpos", end_seekpos="end_seekpos);
         isay(depth, "call_tree_add_file_refs(num_refs="num_refs", max_refs="max_refs")");
      }
      status = tag_match_uses_in_file(errorArgs,tree_wid,tree_index,
                                      case_sensitive,file_name,start_line_no,
                                      alt_file_name,alt_line_no,flag_mask,
                                      context_id, (int)start_seekpos, (int)end_seekpos,
                                      num_refs,max_refs,visited,depth+1);
      tree_wid._TreeSizeColumnToContents(0);

      // close the temporary view
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
   }

   if (_chdebug) {
      isay(depth, "call_tree_add_file_uses: status="status);
   }
   // that's all folks
   return status;
}

/**
 * Insert items called or used by the given tag (tag_id) into the given tree.
 * Opens the given tag database.
 *  
 * p_window_id must be the call tree control. 
 *  
 * @param tree_index       tree node index in call tree
 * @param cm               symbol information
 * @param inst_id          symbol instance ID for BSC references databases
 * @param visited          (reference) context tagging results cache
 * @param depth            recursive depth or tree depth
 * @param doImmediate      (default false) expand items immediately, 
 *                         or use timer callback?
 * 
 * @return Returns the number of items inserted.
 */
static int call_tree_add_uses(int tree_index, 
                              struct VS_TAG_BROWSE_INFO cm, 
                              int inst_id,
                              VS_TAG_RETURN_TYPE (&visited):[], int depth,
                              bool doImmediate=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // map prototype to proc/func/constr/destr
   status := 0;
   orig_file_name := cm.file_name;
   alt_file_name  := cm.file_name;
   alt_line_no    := cm.line_no;
   if (cm.tag_database != "") {
      status = tag_read_db(cm.tag_database);
      if ( status < 0 ) {
         return 0;
      }
      maybe_convert_proto_to_proc(cm);
   }

   if (_chdebug) {
      isay(depth, "call_tree_add_uses: i="tree_index" member="cm.member_name);
   }
   // compute best width to use for first tab
   // get filtering flags for call tree
   treeRoot := callTreeRootIndex();
   cb_prepare_expand(p_active_form,p_window_id,treeRoot);
   flag_mask := (SETagFilterFlags)p_user;
   count := 0;

   // open the tag database for business
   tag_database := false;
   ref_database := refs_filename();
   _str tag_files[];
   if (ref_database != "") {
      tag_files[0]=ref_database;
   } else {
      tag_database=true;
      if (cm.language==null || cm.language=="") {
         cm.language=_Filename2LangId(cm.file_name);
         if (cm.language=="jar" || cm.language=="zip") {
            cm.language="java";
         }
      }
      tag_files = tags_filenamea(cm.language);
   }

   if (tag_database) {

      // save the current buffer state
      orig_context_file := "";
      tag_get_detail2(VS_TAGDETAIL_current_file,0,orig_context_file);
      //DJB 01-03-2007 -- push/pop context is obsolete
      //tag_push_context();

      // this case doesn't use the database at all
      if (doImmediate) {
         orig_use_timers := _use_timers;
         _use_timers=0;
         call_tree_add_file_uses(cm.file_name,
                                alt_file_name,alt_line_no,
                                cm,flag_mask,tree_index,
                                count,def_cb_max_references,
                                0, 0, visited, depth+1);
         _use_timers=orig_use_timers;
      } else {
         CALLTREE_ADD_FILE_USES_ARGS addUsesArgs;
         addUsesArgs.tree_wid       = p_window_id;
         addUsesArgs.tree_index     = tree_index;
         addUsesArgs.file_name      = cm.file_name;
         addUsesArgs.line_no        = cm.line_no;
         addUsesArgs.alt_file_name  = alt_file_name;
         addUsesArgs.alt_line_no    = alt_line_no;
         addUsesArgs.cm             = cm;
         addUsesArgs.filter_flags   = flag_mask;
         addUsesArgs.context_flags  = SE_TAG_CONTEXT_ANYTHING;
         addUsesArgs.start_seekpos  = cm.seekpos;
         addUsesArgs.stop_seekpos   = cm.end_seekpos;
         addUsesArgs.depth          = depth;
         addUsesArgs.max_refs       = def_cb_max_references;
         p_active_form.addCallTreeFindInFileArgs(addUsesArgs);
      }
   }

   if (inst_id > 0) {
      count = call_tree_add_bsc_uses(inst_id, flag_mask, tree_index, tag_files);
   }

   // set the column width
   _TreeSizeColumnToContents(0);
   _TreeRefresh();

   // return total number of items inserted
   return count;
}

/**
 * Add uses from BSC file.
 * 
 * @param inst_id          symbol instance ID for BSC references databases
 * @param flag_mask        bitset of VS_TAGFITLER_*, for filtering tree 
 *                         to specific types of symbols
 * @param tree_index       tree node index in call tree
 * @param tag_files        tag database (BSC files) to search.
 * 
 * @return Returns the number of items inserted.
 */
static int call_tree_add_bsc_uses(int inst_id,
                                  SETagFilterFlags flag_mask,
                                  int tree_index,
                                  _str (&tag_files)[])
{
   // for each BSC file to consider
   count := 0;
   t := 0;
   ref_database := next_tag_filea(tag_files,t,false,true);
   while (ref_database != "") {

      status := tag_read_db(ref_database);
      if ( status < 0 ) {
         break;
      }

      // find references to this instance
      ref_type  := 0;
      file_name := "";
      line_no   := 0;
      ref_id    := tag_find_refer_by(inst_id, ref_type, file_name, line_no);

      while (count < def_cb_max_references && ref_id >= -1) {

         // if something is going on, get out of here
         if( count % 20 == 0 && _IsKeyPending(false) ) {
            break;
         }

         // compute name / line number string for sorting
         fcaption := "";
         pic_ref  := _pic_file;
         ucaption := call_tree_create_user_info(file_name, line_no, ref_id, ref_database);

         // by default, insert as a leaf node
         show_children := TREE_NODE_LEAF;

         // find the context and create caption and icon for it
         tag_init_tag_browse_info(auto cm);
         if (ref_id > 0) {
            // get details about this tag (for creating caption)
            tag_get_instance_info(ref_id, cm.member_name, cm.type_name, cm.flags, cm.class_name, cm.arguments, cm.file_name, cm.line_no);
         }

         if (ref_id > 0 && cm.member_name != "") {
            // check if this item should be skipped
            if (!tag_filter_type(SE_TAG_TYPE_NULL,flag_mask,cm.type_name,(int)cm.flags)) {
               ref_id = tag_next_refer_by(inst_id, ref_type, file_name, line_no);
               continue;
            }

            // create caption for this item
            fcaption = tag_make_caption_from_browse_info(cm, include_class:true, include_args:false, include_tab:true);

            // get the appropriate bitmap
            pic_ref = tag_get_bitmap_for_type(tag_get_type_id(cm.type_name), cm.flags, auto pic_overlay);
            if (tag_tree_type_is_class(cm.type_name) || tag_tree_type_is_package(cm.type_name) || tag_tree_type_is_func(cm.type_name)) {
               if (!pos("proto", cm.type_name) && !(cm.flags & SE_TAG_FLAG_FORWARD)) {
                  show_children = TREE_NODE_COLLAPSED;
               }
            }
         } else {
            // reference is outside of this tag file, just display filename, line_no
            fcaption = _strip_filename(file_name, 'P');
         }

         // compute name / line number string for sorting
         ucaption = call_tree_create_user_info(file_name, line_no, ref_id, ref_database);

         // insert the item and set the user info
         index := _TreeAddItem(tree_index,fcaption,TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,pic_ref,_pic_symbol_public,show_children,0,ucaption);
         if (index < 0) {
            break;
         }
         ++count;

         // next, please
         ref_id = tag_next_refer_by(inst_id, ref_type, file_name, line_no);
      }

      // close the references database
      status = tag_close_db(ref_database,true);
      if ( status ) {
         return 0;
      }
      ref_database=next_tag_filea(tag_files,t,false,true);
   }

   // return the number of items added
   return count;
}


//##############################################################################
//##############################################################################

/**
 * Handle on-change event for symbol calls/uses tool window tree control.
 *  
 * The CHANGE_LEAF_ENTER event is handled like we handle the double-click 
 * event and utilizes {@link push_tag_in_file} to push a bookmark and bring up 
 * the code in the editor. 
 *  
 * The CHANGE_EXPANDED event handles expanding call tree nodes by one level. 
 *  
 * The CHANGE_SELECTED event handles updating the preview tool window for 
 * the current tree item. 
 *  
 * @param reason     tree event code (CHANGE_*) 
 * @param currIndex  current tree node index
 */
void ctl_call_tree_view.on_change(int reason,int currIndex)
{
   if (currIndex < 0) return;
   if (_chdebug) {
      say("ctl_call_tree_view.on_change: reason="reason" index="currIndex" depth="_TreeGetDepth(currIndex));
   }

   if (reason == CHANGE_LEAF_ENTER) {
      // get the context information, push book mark, and open file to line
      status := ctl_call_tree_view.call_tree_get_tag_info(currIndex, auto cm, auto inst_id);
      if (status > 0) {
         push_pos_in_file(cm.file_name, cm.line_no, 0);
      } else {
         caption := _TreeGetCaption(currIndex);
         parse caption with caption "\t" .;
         message("Could not find tag: " caption);
      }

   } else if (reason == CHANGE_EXPANDED) {

      se.util.MousePointerGuard hour_glass;
      status := ctl_call_tree_view.call_tree_get_tag_info(currIndex, auto cm, auto inst_id);
      if (status > 0) {
         // insert the items we reference into the call tree
         ctl_call_tree_view._TreeBeginUpdate(currIndex);
         count := ctl_call_tree_view.call_tree_add_uses(currIndex, 
                                                       cm, inst_id, 
                                                       visited:null, depth:1, 
                                                       doImmediate:true);
         ctl_call_tree_view._TreeEndUpdate(currIndex);

         // sort exactly the way we want things
         ctl_call_tree_view._TreeSortUserInfo(currIndex,"UE","E");
         ctl_call_tree_view._TreeSortCaption(currIndex,"I");
      }

   } else if (reason == CHANGE_COLLAPSED) {
      ctl_call_tree_view._TreeDelete(currIndex,"c");

   } else if (reason == CHANGE_SELECTED) {
      focus_wid := _get_focus();
      if (focus_wid == ctl_call_tree_view || focus_wid == ctl_stack_view) {
         call_tree_start_timer(gCallTreeUpdateTimerId, p_active_form, _CallTreeUpdateCallback);
         call_tree_update_symbol_trace(currIndex);
      }
   }
}

/**
 * Handle on-highlight event for symbol calls/uses tool window tree control.
 * 
 * @param index     tree node index under the mouse pointer
 * @param caption   full caption of tree node
 */
void ctl_call_tree_view.on_highlight(int index, _str caption="")
{
   //say("ctl_call_tree_view.on_highlight: index="index" caption="caption);
   call_tree_kill_timer(gCallTreeHighlightTimerId);
   if (!def_tag_hover_preview) return;
   if (index < 0) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   call_tree_start_timer(gCallTreeHighlightTimerId, 
                        p_active_form,
                        _CallTreeHighlightCallback, 
                        index, 
                        def_tag_hover_delay);
   //call_tree_update_symbol_trace(index);
}

/**
 * Handle right-mouse button on the symbol call tree trace.
 */
void ctl_stack_view.rbutton_up()
{
   // kill the refresh timer, prevents delays before the menu comes
   // while the refreshes are finishing up.
   call_tree_kill_timer(gCallTreeExpandTimerId);
   call_tree_kill_timer(gCallerTreeExpandTimerId);
   call_tree_kill_timer(gCallTreeHighlightTimerId);

   index := find_index("_tagbookmark_menu",oi2type(OI_MENU));
   menu_handle := p_active_form._menu_load(index,'P');

   flags := ctl_call_tree_view.p_user;
   pushTgConfigureMenu(menu_handle, flags, 
                       include_proctree:false, 
                       include_casesens:false, 
                       include_sort:false, 
                       include_save_print:true,
                       include_quick_filters:true,
                       include_filters:false);

   // Show menu:
   mou_get_xy(auto x,auto y);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}


//##############################################################################
//##############################################################################

/**
 * Update other views when the symbols call tree gets focus, important because 
 * inheritance view, call tree, and props can also update the output 
 * preview window, so if they return focus to the symbols call/uses tree, 
 * we need to restart the update timer.
 */
void ctl_call_tree_view.on_got_focus()
{
   if (!_find_control("ctl_call_tree_view")) return;
   call_tree_start_timer(gCallTreeUpdateTimerId, 
                        p_active_form, 
                        _CallTreeUpdateCallback);
   call_tree_update_symbol_trace();
}


//############################################################################
//##############################################################################

/** 
 * Handlers for symbol Refs/Callers tool window. 
 * 
 * This tool window borrows some of it's event handling from the 
 * Symbol Uses/Calls tool window.
 */
defeventtab _tbsymbolcallers_form;

//##############################################################################
//##############################################################################

/**
 * Retrieve information for the current node from caller/refs tree.
 *  
 * p_window_id must be the references or caller (refs) tree control. 
 * 
 * @param index      tree node index to fetch information for 
 * @param cm         [output] set to tag information for current node
 * @param inst_id    [output] instance ID (for BSC reference databases
 * @param depth      seach depth
 * 
 * @return Returns 1 on success, &lt;=0 on failure.
 */
static int caller_tree_get_tag_info(int index, 
                                    struct VS_TAG_BROWSE_INFO &cm, 
                                    int &inst_id, 
                                    int depth=1)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //say("caller_tree_get_tag_info: here, index="index);
   tag_init_tag_browse_info(cm);
   if (index <= 0) {
      return 0;
   }

   // open the tag database for business
   status := 0;
   tag_database := false;
   ref_database := refs_filename();
   if (ref_database != "") {
      status = tag_read_db(ref_database);
      if ( status < 0 ) {
         return 0;
      }
   } else {
      tag_database=true;
   }

   // get the file name and line number, tag database, and instance ID
   ucm := _TreeGetUserInfo(index);
   if (ucm instanceof VS_TAG_BROWSE_INFO) {
      cm = ucm;
      inst_id = 0;
   } else if (ucm._varformat() == VF_INT) {
      inst_id = ucm;
   } else {
      typeless t_line_no, t_tag_id, t_seekpos, t_col_no, t_mark_id, t_flags;
      parse ucm with t_line_no ";" t_tag_id ";" t_seekpos ";" t_col_no ";" cm.tag_database ";" t_mark_id ";" cm.type_name ";" t_flags ";" cm.file_name;
      cm.line_no    = isuinteger(t_line_no)? t_line_no : 1;
      cm.seekpos    = isuinteger(t_seekpos)? t_seekpos : 0;
      cm.column_no  = isuinteger(t_col_no)?  t_col_no  : 1;
      cm.flags      = isuinteger(t_flags)?   t_flags   : SE_TAG_FLAG_NULL;
      inst_id       = isuinteger(t_tag_id)?  t_tag_id  : 0;
   }

   //say("caller_tree_get_tag_info: file_name="cm.file_name" line_no="cm.line_no" seekpos="cm.seekpos);

   // get details about the instance (tag)
   if (inst_id > 0 && !tag_database) {
      tag_get_instance_info(inst_id, cm.member_name, cm.type_name, cm.flags, cm.class_name, cm.arguments, auto df, auto dl);
      //say("caller_tree_get_tag_info(): got here 3, inst_id="inst_id" member_name="cm.member_name" file_name="cm.file_name" line_no="cm.line_no" args="cm.arguments);
   } else {
      // normalize member name
      //cm.seekpos=0;//iid;
      tag_tree_decompose_caption(_TreeGetCaption(index),cm.member_name,cm.class_name,cm.arguments);
   }

   // is the given file_name and line number valid?
   if (cm.file_name != "") {
      if (cm.line_no > 0 && (_isfile_loaded(cm.file_name) || file_exists(cm.file_name))) {
         return 1;
      }
      if (tag_database && !cm.line_no) {
         // this is where we need to extract more information
         // from the source file, for now, we fake it
         cm.line_no=1;
         return 1;
      }
   }

   return 0;
}

//##############################################################################
//##############################################################################

/**
 * Refresh the caller tree view, recursively, this is for when
 * the filter flags are changed.
 * 
 * @param index      tree node index to fetch information for 
 */
static void caller_tree_refresh_tree_recursive(int index=TREE_ROOT_INDEX)
{
   // check if they hit 'cancel'
   if (check_call_tree_cancel_button()) {
      return;
   }

   // make sure the root index is adjusted to be the symbol name
   if (index <= TREE_ROOT_INDEX) {
      index = callTreeRootIndex();
   }

   // for each child of this node, go recursive
   i := _TreeGetFirstChildIndex(index);
   while (i > 0) {
      show_children := 0;
      _TreeGetInfo(i,show_children);
      if (show_children == TREE_NODE_EXPANDED) {
         caller_tree_refresh_tree_recursive(i);
      }
      i = _TreeGetNextSiblingIndex(i);
   }

   // now do this node
   call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');
}

/**
 * @return 
 * Return the window Id of the current active symbol refs/callers tree. 
 */
int _tbGetActiveSymbolCallersForm()
{
   if (!_haveContextTagging()) return 0;
   return tw_find_form(TBSYMBOLCALLERS_FORM);
}


//##############################################################################
//##############################################################################

/**
 * Refresh the caller tree window with the given tag information. 
 * If they do not give a specific form ID, it will refresh all caller trees.
 * 
 * @param cm         Symbol information to fill all tree with
 * @param form_wid   Symbol callers/refs tool window form ID
 * @param expandChildren   expand the children of the node.
 */
void cb_refresh_callertree_view(struct VS_TAG_BROWSE_INFO cm,
                                int form_wid=-1,
                                bool expandChildren=true)
{
   if (!_haveContextTagging()) {
      return;
   }

   // Refresh the specific form requested
   f := form_wid;
   if (f > 0) {
      f.caller_tree_refresh_tree_for_one_window(cm, expandChildren);
      return;
   }

   // refresh all instances of the arguments toolbar
   cbrowser_form := p_active_form;
   found_one := false;
   foreach (f => . in gtbSymbolCallersFormList) {
      if (tw_is_from_same_mdi(f,cbrowser_form)) {
         found_one=true;
         f.caller_tree_refresh_tree_for_one_window(cm, expandChildren);
      }
   }
   if (!found_one) {
      f=_tbGetActiveSymbolCallersForm();
      if (f) {
         f.caller_tree_refresh_tree_for_one_window(cm, expandChildren);
      }
   }
}

/**
 * Refresh the given caller tree window with the given tag information. 
 *  
 * The current window is expected to be a symbol callers/refs tool window form.
 * 
 * @param cm               Symbol information to fill all tree with 
 * @param expandChildren   expand the children of the node.
 */
static void caller_tree_refresh_tree_for_one_window(struct VS_TAG_BROWSE_INFO cm,
                                                    bool expandChildren=true)
{
   if (!_haveContextTagging()) {
      return;
   }

   _nocheck _control ctl_call_tree_view;
   form_wid := p_active_form;
   if (!_iswindow_valid(form_wid) || form_wid.p_name!=TBSYMBOLCALLERS_FORM) {
      return;
   }

   // just refresh the existing view, recursively, if cm==null
   if (cm==null) {
      form_wid.call_tree_enable_cancel();
      form_wid.ctl_call_tree_view.p_redraw=false;
      form_wid.ctl_call_tree_view.caller_tree_refresh_tree_recursive();
      form_wid.ctl_call_tree_view.p_redraw=true;
      if (!check_call_tree_cancel_button()) {
         form_wid.call_tree_disable_cancel();
      }
      return;
   }

   // bail out if we have no member name
   if (!VF_IS_STRUCT(cm) || cm.member_name=="") {
      return;
   }

   // make sure that cm is totally initialized
   if (cm.tag_database._isempty())   cm.tag_database = "";
   if (cm.category._isempty())       cm.category = "";
   if (cm.class_name._isempty())     cm.class_name = "";
   if (cm.member_name._isempty())    cm.member_name = "";
   if (cm.qualified_name._isempty()) cm.qualified_name = "";
   if (cm.type_name._isempty())      cm.type_name = "";
   if (cm.file_name._isempty())      cm.file_name = "";
   if (cm.return_type._isempty())    cm.return_type = "";
   if (cm.arguments._isempty())      cm.arguments = "";
   if (cm.exceptions._isempty())     cm.exceptions = "";
   if (cm.class_parents._isempty())  cm.class_parents = "";
   if (cm.template_args._isempty())  cm.template_args = "";

   // same caller tree as last time?
   struct VS_TAG_BROWSE_INFO cm2 = form_wid._GetDialogInfoHt("tag_info");
   if (tag_browse_info_equal(cm,cm2)) {
      return;
   }
   form_wid._SetDialogInfoHt("tag_info", cm);
   form_wid.getCallerTreeCache(true);

   // check if there is a load-tags function, if so, bail out
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      return;
   }

   // refresh the caller tree view
   if (cm.member_name == "") {
      form_wid.ctl_stack_view._TreeDelete(TREE_ROOT_INDEX, 'c');
      form_wid.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
      form_wid.ctl_call_tree_view._TreeAddItem(TREE_ROOT_INDEX, "No function selected", TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      return;
   }

   // construct the item caption
   item_name := tag_make_caption_from_browse_info(cm, include_class:true, include_args:true, include_tab:true);

   ref_database := refs_filename();
   enable_refs := (ref_database == "")? 0:1;
   inst_id := 0;

   // open the tag database for business
   orig_database := tag_current_db();
   if (ref_database == "") {
      //form_wid.ctl_stack_view._TreeDelete(TREE_ROOT_INDEX, 'c');
      //form_wid.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
      //return;
   } else {
      status := tag_read_db(ref_database);
      if ( status < 0 ) {
         form_wid.ctl_stack_view._TreeDelete(TREE_ROOT_INDEX, 'c');
         form_wid.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
         return;
      }

      // match tag up with instance in references database
      inst_id = tag_match_instance(cm.member_name, cm.type_name, 0, cm.class_name, cm.arguments, cm.file_name, cm.line_no, 1);

      // close the references database and
      // revert back to the original tag database
      status = tag_close_db(ref_database,true);
      s2 := tag_read_db(orig_database);
      if ( status < 0 ) {
         form_wid.ctl_stack_view._TreeDelete(TREE_ROOT_INDEX, 'c');
         form_wid.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
         return;
      }
   }

   // clear out the caller tree
   form_wid.ctl_stack_view._TreeDelete(TREE_ROOT_INDEX, 'c');
   form_wid.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');

   // find the bitmap for this item
   pic_ref := tag_get_bitmap_for_type(tag_get_type_id(cm.type_name), cm.flags, auto pic_overlay);

   // set up root function
   treeRoot := form_wid.ctl_call_tree_view._TreeAddItem(TREE_ROOT_INDEX, item_name, TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1, pic_overlay, pic_ref, TREE_NODE_COLLAPSED, 0, cm);
   form_wid.ctl_call_tree_view._TreeSizeColumnToContents(0);
   form_wid.call_tree_update_symbol_trace();

   // look up and insert the item callers
   if (expandChildren) {
      form_wid.ctl_call_tree_view._TreeSetInfo(treeRoot, TREE_NODE_EXPANDED);
      form_wid.ctl_call_tree_view.call_event(CHANGE_EXPANDED,
                                             treeRoot,
                                             form_wid.ctl_call_tree_view,
                                             ON_CHANGE,
                                             'w');
   }
}

//##############################################################################
//##############################################################################

/**
 * Initialize the symbol callers/refs tree tool window.
 */
void _tbsymbolcallers_form.on_create()
{
   TBSYMBOLCALLS_FORM_INFO info;
   info.m_form_wid=p_active_form;
   gtbSymbolCallersFormList:[p_active_form]=info;

   ctl_call_tree_view.p_user = _retrieve_value(TBSYMBOLCALLERS_FORM:+".ctl_call_tree_view.p_user");
   if (ctl_call_tree_view.p_user == "") {
      ctl_call_tree_view.p_user = 0xffffffff;
   }

   // reduced level indent
   ctl_call_tree_view.p_LevelIndent = _dx2lx(SM_TWIP, 12);

   // cancel button is disabled until they hit "Expand"
   ctl_expand_button.p_enabled = true;
   ctl_cancel_button.p_enabled = false;
   ctl_progress.p_visible = false;

   ypos := _moncfg_retrieve_value(TBSYMBOLCALLERS_FORM:+".ctl_size_y.p_y");
   if (isuinteger(ypos)) {
      ctl_size_y.p_y = ypos;
   }
}

/**
 * Clean up the symbol callers/refs tree tool window when the form is destroyed. 
 * Make sure all timer functions are stopped. 
 */
void _tbsymbolcallers_form.on_destroy()
{
   _append_retrieve(0, ctl_call_tree_view.p_user, TBSYMBOLCALLERS_FORM:+".ctl_call_tree_view.p_user");
   _moncfg_append_retrieve(0,ctl_size_y.p_y,TBSYMBOLCALLERS_FORM:+".ctl_size_y.p_y");
   call_event(p_window_id,ON_DESTROY,'2');
   call_tree_kill_timer(gCallTreeUpdateTimerId);
   call_tree_kill_timer(gCallerTreeExpandTimerId);
   call_tree_kill_timer(gCallTreeHighlightTimerId);
   gtbSymbolCallersFormList._deleteel(p_active_form);
}

//##############################################################################
//##############################################################################

/**
 * Expand all items at all depths of the caller tree. 
 *  
 * This will queue up tree nodes to be expanded and start a timer function 
 * to go through the list and expand them, then after they are expanded, 
 * will queue up the new nodes added, so that the timer function can also 
 * expand them.  This allows it to expand the tree in a breadth-first manner, 
 * rather than diving in too deep down the first path it tries. 
 */
void ctl_expand_button.lbutton_up()
{
   form_wid := p_active_form;
   activate_window(form_wid);
   call_tree_enable_cancel();

   pCallTreeCache := form_wid.getCallerTreeCache(resetCache:true);
   ctl_call_tree_view.p_redraw=false;
   cur_index := ctl_call_tree_view._TreeCurIndex();
   ctl_call_tree_view.caller_tree_expand_tree(cur_index,
                                             pCallTreeCache->been_there_done_that, 
                                             pCallTreeCache->visited, 0,
                                             doImmediate:false,
                                             stopRecursion:false);

   call_tree_start_timer(gCallerTreeExpandTimerId, p_active_form, _CallerTreeExpandCallback, cur_index);

   if (check_call_tree_cancel_button()) {
      form_wid.call_tree_disable_cancel();
   }
   activate_window(form_wid);
   ctl_call_tree_view._TreeSetCurIndex(cur_index);
   ctl_call_tree_view.p_redraw=true;
   ctl_call_tree_view._TreeRefresh();
}

/**
 * Expands the caller tree at the given tree node.
 * 
 * @param tree_index             index of tree node to expand
 * @param been_there_done_that   (reference) hash table of tree captions 
 *                               already expanded, so that we do not recursively
 *                               expand the same item's caller tree multiple times.
 * @param visited                (reference) context tagging results cache
 * @param depth                  recursive caller depth or tree expansion depth
 * @param stopRecursion          (default true) if 'false' been_there_done_that 
 *                               is ignored for the top-level node. 
 * 
 * @return 
 * Returns 0 on success, &lt;0 on error. 
 */
static int caller_tree_expand_tree(int tree_index, 
                                   bool (&been_there_done_that):[],
                                   VS_TAG_RETURN_TYPE (&visited):[], int depth,
                                   bool doImmediate=false,
                                   bool stopRecursion=true)
{
   // check if they hit 'cancel'
   if (check_call_tree_cancel_button()) {
      return COMMAND_CANCELLED_RC;
   }

   // do not expand beyond 32 levels deep
   if (depth > 32) {
      return 0;
   }

   // return if it is a leaf node
   show_children := 0;
   _TreeGetInfo(tree_index,show_children);
   if (show_children == TREE_NODE_LEAF) {
      return 0;
   }

   // already expanded this item?
   caption := _TreeGetCaption(tree_index);
   if (_chdebug) {
      isay(depth, "caller_tree_expand_tree: caption="caption);
   }
   if (stopRecursion && been_there_done_that._indexin(caption)) {
      if (_chdebug) {
         isay(depth, "caller_tree_expand_tree: BEEN THERE DONE THAT");
      }
      return 0;
   }
   been_there_done_that:[caption]=true;

   // do not expand classes, interfaces, structs, and package names
   tag_init_tag_browse_info(auto cm);
   inst_id := 0;
   if (depth > 0 && caller_tree_get_tag_info(tree_index, cm, inst_id, depth+1) > 0) {
      // do not expand package names
      if (tag_tree_type_is_package(cm.type_name)) {
         return 0;
      }
      // expand class names only if the outer item was a class
      if (tag_tree_type_is_class(cm.type_name) || cm.type_name == "enum") {
         parentIndex := _TreeGetParentIndex(tree_index);
         if (parentIndex > 0 && caller_tree_get_tag_info(parentIndex, cm, inst_id, depth+1) > 0) {
            if (!tag_tree_type_is_class(cm.type_name) && cm.type_name!="enum" ) {
               return 0;
            }
         }
      }
   }

   // expand node if it is not already expanded
   if (show_children == TREE_NODE_COLLAPSED) {
      se.util.MousePointerGuard hour_glass;
      if (caller_tree_get_tag_info(tree_index, cm, inst_id, depth+1) > 0) {
         caller_tree_add_refs(tree_index, cm, inst_id);
      }
      if (doImmediate) {
         _TreeSetInfo(tree_index, TREE_NODE_EXPANDED);
      }
   }

   // otherwise, if we get here and the node is already expanded, maybe
   // we need to check the items underneath if they need to be expanded
   if (show_children == TREE_NODE_EXPANDED && !doImmediate) {
      if (_chdebug) {
         isay(depth, "caller_tree_expand_tree: EXPAND CHILDREN");
      }
      tree_index = _TreeGetFirstChildIndex(tree_index);
      while (tree_index > 0) {
         if (caller_tree_get_tag_info(tree_index, cm, inst_id, depth+1) > 0) {
            caller_tree_expand_tree(tree_index, 
                                    been_there_done_that, 
                                    visited, depth+1,
                                    doImmediate:false,
                                    stopRecursion:true);
         }
         tree_index = _TreeGetNextSiblingIndex(tree_index);
      }
   }

   // success
   return 0;
}

//##############################################################################
//##############################################################################

/**
 * Event handler for resize of "on_resize" event for symbol callers/refs tool window.
 */
void _tbsymbolcallers_form.on_resize() 
{
   call_tree_on_resize();
}

//##############################################################################
//##############################################################################

/**
 * Handle right-mouse button on the symbol callers/refs tree control. 
 */
void ctl_call_tree_view.rbutton_up()
{
   call_tree_rbutton_up();
}


//##############################################################################
//##############################################################################

/**
 * Handle double-click event (opens the file and positions us on the
 * line indicated by the reference data), this may or may not be the 
 * right line to be positioned on. 
 */
void ctl_call_tree_view.enter,lbutton_double_click()
{
   // get the context information, push book mark, and open file to line
   tree_index := ctl_call_tree_view._TreeCurIndex();
   status := ctl_call_tree_view.caller_tree_get_tag_info(tree_index, auto cm, auto inst_id);
   if (status > 0) {
      push_pos_in_file(cm.file_name, cm.line_no, 0);
   }
}

/**
 * Handles the 'spacebar' event (opens the file and positions us on the
 * line indicated by the reference data), this may or may not be the 
 * right line to be positioned on. 
 */
void ctl_call_tree_view." "()
{
   // IF this is an item we can go to like a class name
   orig_window_id := p_window_id;

   tree_index := ctl_call_tree_view._TreeCurIndex();
   status := ctl_call_tree_view.caller_tree_get_tag_info(tree_index, auto cm, auto inst_id);
   if (status > 0) {
      push_pos_in_file(cm.file_name, cm.line_no, 0);
   }

   // restore original focus
   p_window_id = orig_window_id;
   ctl_call_tree_view._set_focus();
}


//##############################################################################
//##############################################################################

/**
 * This is the timer callback for updating other tool windows when an item 
 * is clicked on in the symbol callers/refs tool window. 
 *  
 * Whenever the current index (cursor position) for the caller tree is changed, 
 * a timer is started/reset.  If no activity occurs within a set amount of time, 
 * this function is called to update the properties view, inheritance view, 
 * and output window.
 *  
 * Using this allows you to quickly scroll down through items in the tree without 
 * constantly updating other tool windows as we go along.
 *  
 * @param cmdline    information passed from timer, which contains the form 
 *                   window id and the tree index to update tool windows for. 
 */
static void _CallerTreeUpdateCallback(_str cmdline)
{
   // kill the timer
   call_tree_kill_timer(gCallTreeUpdateTimerId);

   // get the command line arguments
   parse cmdline with auto sform_wid auto sindex;
   f := (int)sform_wid;
   index := (int)sindex;
   if (!_iswindow_valid(f) || f.p_name!=TBSYMBOLCALLERS_FORM) {
      return;
   }

   // get the current tree index
   _nocheck _control ctl_call_tree_view;
   currIndex := f.ctl_call_tree_view._TreeCurIndex();
   if (currIndex<0) {
      return;
   }

   // get the context information, push book mark, and open file to line
   status := f.ctl_call_tree_view.caller_tree_get_tag_info(currIndex, auto cm, auto inst_id);
   if (status > 0) {
      // find the output tagwin and update it
      cb_refresh_output_tab(cm, true);
   } else {
      f.ctl_call_tree_view.message_cannot_find_ref(currIndex);
   }
}

/**
 * This is the timer callback for updating tool windows when an item is 
 * highlighted (the mouse hovers over) an item in the symbol callers/refs 
 * tool window. 
 *  
 * This function is very similar, nearly identical, to the callback for 
 * updating the current selected item in the symbol caller tree.
 * 
 * @param cmdline    information passed from timer, which contains the form 
 *                   window id and the tree index to update tool windows for. 
 */
static void _CallerTreeHighlightCallback(_str cmdline)
{
   // kill the timer
   call_tree_kill_timer(gCallTreeHighlightTimerId);

   parse cmdline with auto sform_wid auto sindex;
   f := (int)sform_wid;
   index := (int)sindex;
   if (!_iswindow_valid(f) || f.p_name!=TBSYMBOLCALLERS_FORM) {
      return;
   }
   // get the current tree index
   if (index <= 0) {
      return;
   }

   _nocheck _control ctl_call_tree_view;

   // get the context information, push book mark, and open file to line
   status := f.ctl_call_tree_view.caller_tree_get_tag_info(index, auto cm, auto inst_id);
   if (status > 0) {
      // find the output tagwin and update it
      _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
   }
}

/**
 * This is the timer callback for expanding items in the symbol callers/refs 
 * tool window.  It takes an item from a queue of nodes that need expansion, 
 * expands that item in the tree, and then potentially queues up new nodes 
 * which are to be expanded the next time the timer callback is invoked. 
 * Each timer invocation processes one node expansion.  It is broken up this 
 * way in order to minimize delays in the main editor.
 * 
 * @param cmdline    information passed from timer, which contains the form 
 *                   window id only.
 */
static void _CallerTreeExpandCallback(_str cmdline)
{
   // hold tight for a bit if the user is doing something
   if (_idle_time_elapsed() < 100) {
      return;
   }

   // get the form wid, and make sure it is a valid caller tree tool window
   parse cmdline with auto sform_wid auto s_recursive;
   form_wid  := (int)sform_wid;
   recursive := (s_recursive >= 0);
   if (!_iswindow_valid(form_wid) || form_wid.p_name!=TBSYMBOLCALLERS_FORM) {
      return;
   }

   // check if they hit 'cancel'
   cancel_wid := form_wid.ctl_cancel_button;
   if (form_wid.check_call_tree_cancel_button()) {
      form_wid.call_tree_disable_cancel();
      call_tree_kill_timer(gCallerTreeExpandTimerId);
      return;
   }

   // get the cache, this should never return 'null', but check anyway
   pCallTreeCache := form_wid.getCallerTreeCache();
   if (pCallTreeCache == null) {
      call_tree_kill_timer(gCallerTreeExpandTimerId);
      form_wid.call_tree_disable_cancel();
      return;
   }

   // get the next argument to process
   addUsesArgs := form_wid.getCallTreeFindInFileArgs();
   if (addUsesArgs == null) {
      call_tree_kill_timer(gCallerTreeExpandTimerId);
      form_wid.call_tree_disable_cancel();
      return;
   }

   // get the tree wid and tree index and verify
   tree_wid := addUsesArgs.tree_wid;
   if (tree_wid != form_wid.ctl_call_tree_view.p_window_id) {
      call_tree_kill_timer(gCallerTreeExpandTimerId);
      form_wid.call_tree_disable_cancel();
      return;
   }
   tree_index := addUsesArgs.tree_index;
   if (!tree_wid._TreeIndexIsValid(tree_index)) {
      call_tree_kill_timer(gCallerTreeExpandTimerId);
      form_wid.call_tree_disable_cancel();
      return;
   }

   // temporarily disable auto-save timers
   orig_use_timers := _use_timers;
   _use_timers=0;

   if (addUsesArgs.cm == null) {
      if (addUsesArgs.file_name == "BEGIN") {
         // begin expanding this node, there could be many files to process
         // and add the results underneath it
         //tree_wid._TreeBeginUpdate(tree_index);
      } else if (addUsesArgs.file_name == "END") {
         // end expanding this node, sort the items, allowing for duplicate
         // captions and leave the tree node in the expanded state
         //tree_wid._TreeEndUpdate(tree_index);
         //tree_wid._TreeSortUserInfo(tree_index,"E","E");
         tree_wid._TreeSortCaption(tree_index,"I");
         tree_wid._TreeSetInfo(tree_index, TREE_NODE_EXPANDED);

         // now we queue up expanding the new nodes which we just added
         if (recursive) {
            tree_wid.caller_tree_expand_tree(tree_index, 
                                             pCallTreeCache->been_there_done_that,
                                             pCallTreeCache->visited,
                                             addUsesArgs.depth+1,
                                             doImmediate:false,
                                             stopRecursion:false);
         }
      }
   } else {

      // determine the line number of the symbol according to the tag database
      tag_files := tags_filenamea(addUsesArgs.cm.language);
      tag_find_tag_line_in_tag_files(tag_files, addUsesArgs.cm);

      // insert all the references to 'cm' for the given file
      tree_wid.caller_tree_add_file_refs(addUsesArgs.file_name,
                                         addUsesArgs.cm,
                                         addUsesArgs.filter_flags,
                                         addUsesArgs.context_flags,
                                         addUsesArgs.tree_index, 
                                         pCallTreeCache->num_refs,
                                         addUsesArgs.max_refs,
                                         addUsesArgs.start_seekpos,
                                         addUsesArgs.stop_seekpos,
                                         pCallTreeCache->visited,
                                         addUsesArgs.depth);
   }

   // truncate queue if it does not mean moving too many items
   if (pCallTreeCache->matchUsesInFileArray._length() - pCallTreeCache->array_index < 10) {
      pCallTreeCache->matchUsesInFileArray._deleteel(0, pCallTreeCache->array_index);
      pCallTreeCache->num_items_deleted += pCallTreeCache->array_index;
      pCallTreeCache->array_index = 0;
   }

   // re-enabled timers
   _use_timers=orig_use_timers;
}

//##############################################################################
//##############################################################################

/**
 * Add symbol callers/refs to the symbol tree for the given symbol.
 * 
 * @param file_name        name of the file the symbol is defined in
 * @param cm               symbol information
 * @param filter_flags     bitset of VS_TAGFITLER_*, for filtering tree 
 *                         to specific types of symbols
 * @param context_flags    bitset of VS_TAGCONTEXT_*, for more context tagging 
 *                         dependent filtering of symbols 
 * @param tree_index       tree node index in caller tree
 * @param num_refs         (reference) number of references found so far
 * @param max_refs         maximum number of references to find 
 * @param start_seekpos    start seek position for range to search
 * @param end_seekpos      end seek position for range to search
 * @param visited          (reference) context tagging results cache
 * @param depth            recursive depth or tree depth
 * 
 * @return Returns the number of items inserted under the tree node.
 */
static int caller_tree_add_file_refs(_str file_name, 
                                     struct VS_TAG_BROWSE_INFO &cm,
                                     SETagFilterFlags filter_flags, 
                                     SETagContextFlags context_flags, 
                                     int tree_index,
                                     int &num_refs, 
                                     int max_refs,
                                     long start_seekpos=0, 
                                     long end_seekpos=0,
                                     VS_TAG_RETURN_TYPE (&visited):[]=null, 
                                     int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // regulate prior result cache size to prevent memory from growing excessively
   if (visited._length() > def_tagging_cache_ksize) {
      visited._makeempty();
   }
   if (_chdebug) {
      isay(depth, "caller_tree_add_file_refs: file="file_name);
   }
   // open a temporary view of 'file_name'
   tree_wid := p_window_id;
   status := _open_temp_view(file_name, auto temp_view_id, auto orig_view_id, "", auto inmem, false, true);
   if (!status) {
      // delegate the bulk of the work
      //say("cb_add_file_refs: cm.file="cm.file_name" cm.line="cm.line_no);
      case_sensitive := p_EmbeddedCaseSensitive;
      if (tag_tree_type_is_func(cm.type_name) && (cm.flags & SE_TAG_FLAG_ABSTRACT)) {
         context_flags |= SE_TAG_CONTEXT_FIND_PARENTS;
      }
      // If the symbol we are searching for is an include file,
      // limit the filter flags to just INCLUDE tags.  This serves as an
      // indicator to tag_symbol_match_occurrences_in_file() to also search 
      // within strings, since the include file specs can be in strings.
      if (cm.type_name=="include" || cm.type_name=="file") {
         filter_flags = SE_TAG_FILTER_INCLUDE;
      }

      _UpdateContextAndTokens(true);
      orig_num_children := tree_wid._TreeGetNumChildren(tree_index);
      orig_caption      := tree_wid._TreeGetCaption(tree_index);

      _str errorArgs[];
      status = tag_match_symbol_occurrences_in_file(errorArgs,
                                                    tree_wid,tree_index,
                                                    cm, case_sensitive,
                                                    filter_flags,
                                                    context_flags,
                                                    (int)start_seekpos,
                                                    (int)end_seekpos,
                                                    num_refs,max_refs,
                                                    visited,depth+1,
                                                    for_callers_tree:true);
      if (_chdebug) {
         isay(depth, "cb_add_file_refs: cm.member_name="cm.member_name" line="cm.line_no" status="status);
      }

      // go through all the items and append the file name to the user info
      // and then mark the item as expandable
      _UpdateContextAndTokens(true);
      int context_ref_ids:[];
      int refs_to_delete[];
      ref_index := tree_wid._TreeGetFirstChildIndex(tree_index);
      while (ref_index > 0) {
         do {
            // skip the items that were already processed
            if (orig_num_children > 0) {
               --orig_num_children;
               break;
            }

            // this assumes knowledge of how tag_match_symbol_occurrences_in_file
            // encodes the user data.
            ucm := tree_wid._TreeGetUserInfo(ref_index);
            typeless t_tag_id, t_seekpos;
            parse ucm with . ";" t_tag_id ";" t_seekpos ";" .;
            t_seekpos = isuinteger(t_seekpos)? t_seekpos : 0;
            t_tag_id  = isuinteger(t_tag_id )? t_tag_id  : 0;
            _GoToROffset(t_seekpos);

            // check if there is a symbol under this seek position
            context_id := tag_current_context();
            if (context_id <= 0) {
               refs_to_delete :+= ref_index;
               break;
            }
            
            // have we already found a reference in this symbol?
            if (context_ref_ids._indexin(context_id)) {
               refs_to_delete :+= ref_index;
               break;
            }

            // mark this context item as processed
            context_ref_ids:[context_id] = ref_index;

            // get the full reference info for this symbol
            tag_get_context_browse_info(context_id, auto ref_cm);
            tree_wid._TreeSetUserInfo(ref_index, ref_cm);

            // is this the symbol we are expanding callers for,
            // if so, remove the self-reference
            if (ref_cm.member_name == cm.member_name &&
                ref_cm.line_no     == cm.line_no     &&
                _file_eq(ref_cm.file_name, cm.file_name)) {
               refs_to_delete :+= ref_index;
               break;
            }

            // if this is another function with the same name as the function
            // we are searching for references to, skip it
            if (ref_cm.member_name == cm.member_name &&
                ref_cm.type_name   == cm.type_name   &&
                ref_cm.name_seekpos == t_seekpos) {
               ref_caption := tree_wid._TreeGetCaption(ref_index);
               if (ref_caption :== orig_caption) {
                  refs_to_delete :+= ref_index;
                  break;
               }
            }
         
            // mark the node as collapsed so we can expand it later
            tree_wid._TreeSetInfo(ref_index, TREE_NODE_COLLAPSED);
                                          
         } while (false);

         // next item please
         ref_index = tree_wid._TreeGetNextSiblingIndex(ref_index);
      }

      // if this is a self-reference, delete it
      foreach (auto del_index in refs_to_delete) {
         tree_wid._TreeDelete(del_index);
      }

      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
   }

   // that's all folks
   return status;
}

/**
 * Locate the files with references or potential references to the given 
 * symbol and add them to the list of files to expand references for. 
 *  
 * p_window_id must be the caller/refs tree control.
 * 
 * @param tree_index       tree node index in caller tree
 * @param cm               symbol information
 * @param inst_id          symbol instance ID for BSC references databases
 * @param buf_name         current file name 
 * @param case_sensitive   search for references using case-sensitive match
 * 
 * @return Returns the number of items inserted.
 */
static int caller_tree_add_refs(int tree_index, 
                                struct VS_TAG_BROWSE_INFO cm, 
                                int inst_id,
                                _str buf_name=null, 
                                bool case_sensitive=true)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // map prototype to proc/func/constr/destr
   status := 0;
   if (cm.tag_database != "") {
      status = tag_read_db(cm.tag_database);
      if ( status < 0 ) {
         return 0;
      }
   }

   // check if there is a load-tags function, if so, watch out
   se.util.MousePointerGuard hour_glass;
   tag_init_tag_browse_info(auto decl_cm);
   orig_file_name  := cm.file_name;
   assoc_file_names := associated_file_for(cm.file_name, true);
   is_jar_file := false;
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      is_jar_file=true;
   } else if ((cm.type_name:=="proto" || cm.type_name:=="procproto") &&
              !(cm.flags & (SE_TAG_FLAG_NATIVE|SE_TAG_FLAG_ABSTRACT)) && cm.tag_database!="") {
      search_arguments :=  VS_TAGSEPARATOR_args:+cm.arguments;
      if (tag_find_tag(cm.member_name, "proc", cm.class_name, search_arguments)==0 ||
          tag_find_tag(cm.member_name, "func", cm.class_name, search_arguments)==0 ||
          tag_find_tag(cm.member_name, "constr", cm.class_name, search_arguments)==0 ||
          tag_find_tag(cm.member_name, "destr", cm.class_name, search_arguments)==0) {
         //say("cb_add_uses: found a proc, file="cm.file_name" line="cm.line_no);
         tag_get_tag_browse_info(cm);
      }
      tag_reset_find_tag();
   } else if (tag_tree_type_is_func(cm.type_name)) {
      search_arguments :=  VS_TAGSEPARATOR_args:+cm.arguments;
      if (tag_find_tag(cm.member_name, "procproto", cm.class_name, search_arguments)==0 ||
          tag_find_tag(cm.member_name, "proto", cm.class_name, search_arguments)==0 ) {
         //say("cb_add_uses: found a proc, file="cm.file_name" line="cm.line_no);
         tag_get_tag_info(decl_cm);
      }
      tag_reset_find_tag();
   }

   filter_flags := (SETagFilterFlags)p_user;
   count := 0;

   // open the tag database for business
   tag_database := 0;
   ref_database := refs_filename();
   _str tag_files[];
   _str bsc_tag_files[];
   if (ref_database != "") {
      //say("cb_add_refs: got reference database="ref_database);
      tag_files[0]=ref_database;
   } else {
      tag_database=1;
      cm_lang := cm.language;
      if (is_jar_file) {
         cm_ext := _get_extension(cm.file_name);
         if (cm_ext == "class" || cm_ext == "jar") {
            cm_lang = "java";
         } else if (!_no_child_windows()) {
            cm_lang = _mdi.p_child.p_LangId;
         } else if (cm_ext == "dll" || cm_ext == "winmd") {
            cm_lang = "cs";
         }
      }
      if (cm_lang==null || cm_lang=="") {
         cm_lang = _Filename2LangId(cm.file_name);
      }
      tag_files = tags_filenamea(cm_lang);
      if (cm.language == "") {
         cm.language = cm_lang;
      }
   }

   // always look for references in the file containing the declaration
   depth := _TreeGetDepth(tree_index);
   t := 0; 
   bool found_files:[];
   only_look_in_buffer := false;

   // add an virtual item to indicate that we are just now staring expanding
   // all files in this node, and we can sort and adjust column widths now.
   // subsequent entries will always have 'cm' set to the symbol info
   CALLTREE_ADD_FILE_USES_ARGS addUsesArgs;
   addUsesArgs.tree_wid       = p_window_id;
   addUsesArgs.tree_index     = tree_index;
   addUsesArgs.file_name      = "START";
   addUsesArgs.line_no        = 1;
   addUsesArgs.alt_file_name  = "";
   addUsesArgs.alt_line_no    = 1;
   addUsesArgs.cm             = null;
   addUsesArgs.filter_flags   = filter_flags;
   addUsesArgs.context_flags  = SE_TAG_CONTEXT_ANYTHING;
   addUsesArgs.start_seekpos  = 0; 
   addUsesArgs.stop_seekpos   = 0;
   addUsesArgs.depth          = depth;
   addUsesArgs.max_refs       = def_cb_max_references;
   addCallTreeFindInFileArgs(addUsesArgs);
   tag_find_tag_line_in_tag_files(tag_files, cm);
   addUsesArgs.cm             = cm;

   if (tag_database) {

      // check if we have cross referencing built for at least one of the tag files
      have_references := false;
      ref_database=next_tag_filea(tag_files,t,false,true);
      while (ref_database != "") {
         // match instances using Context Tagging(R)
         if (tag_get_db_flags() & VS_DBFLAG_occurrences) {
            have_references=true;
            break;
         }
         // next tag file, please...
         ref_database=next_tag_filea(tag_files,t,false,true);
      }

      // Is this a local variable, paramater, or static non-class declaration?
      // Then don't search tag files
      if (!have_references ||
          (cm.type_name=="lvar" && !(cm.flags & SE_TAG_FLAG_EXTERN)) || 
          (cm.type_name=="param") ||
          (cm.class_name=="" && (cm.flags & SE_TAG_FLAG_STATIC) && !isCHeaderFile(cm))) {
         only_look_in_buffer = true;
         tag_files._makeempty();
      }

      // if this is a private member in Java, then restrict, only need
      // the file that contains it.
      if ((cm.flags & SE_TAG_FLAG_ACCESS)==SE_TAG_FLAG_PRIVATE && _get_extension(cm.file_name)=="java") {
         only_look_in_buffer = true;
         tag_files._makeempty();
      }

      // always look for references in the file containing the originating reference
      if (!is_jar_file && cm.file_name != "" && cm.language != "tagdoc") {
         if (_chdebug) {
            isay(depth, "caller_tree_add_refs: ORIGINATING FILE: "cm.file_name);
         }
         addUsesArgs.file_name = cm.file_name;
         addCallTreeFindInFileArgs(addUsesArgs);
         found_files:[_file_case(cm.file_name)] = true;
      }
      
      // Don't add other files if they specified this buffer only
      // always look for references in the file containing the declaration
      if (decl_cm.file_name != "" && decl_cm.language != "tagdoc" &&
          !found_files._indexin(_file_case(decl_cm.file_name)) &&
          !_QBinaryLoadTagsSupported(decl_cm.file_name) ) {
         if (_chdebug) {
            isay(depth, "caller_tree_add_refs: DECLARED IN FILE: "decl_cm.file_name);
         }
         addUsesArgs.file_name = decl_cm.file_name;
         addCallTreeFindInFileArgs(addUsesArgs);
         found_files:[_file_case(decl_cm.file_name)] = true;
      }

      // always look for references in the file containing the definition
      if (orig_file_name != "" && cm.language != "tagdoc" &&
          !found_files._indexin(_file_case(orig_file_name)) &&
          !_QBinaryLoadTagsSupported(orig_file_name) ) {
         if (_chdebug) {
            isay(depth, "caller_tree_add_refs: DEFINED IN FILE: "orig_file_name);
         }
         addUsesArgs.file_name = orig_file_name;
         addCallTreeFindInFileArgs(addUsesArgs);
         found_files:[_file_case(orig_file_name)] = true;
      }

      // always look for references associated file names also
      foreach (auto assoc_file_name in assoc_file_names) {
         assoc_file_name = _maybe_unquote_filename(assoc_file_name);
         if (assoc_file_name != "" && cm.language != "tagdoc" &&
             !found_files._indexin(_file_case(assoc_file_name)) &&
             !_QBinaryLoadTagsSupported(assoc_file_name) ) {
            if (_chdebug) {
               isay(depth, "caller_tree_add_refs: ASSOCIANTED FILE NAME: "assoc_file_name);
            }
            addUsesArgs.file_name = assoc_file_name;
            addCallTreeFindInFileArgs(addUsesArgs);
            found_files:[_file_case(assoc_file_name)] = true;
         }
      }

      // and give the current buffer a shot, too
      if (buf_name!=null && buf_name!="" && !found_files._indexin(_file_case(buf_name))) {
         if (_chdebug) {
            isay(depth, "caller_tree_add_refs: CURRENT BUFFER: "buf_name);
         }
         addUsesArgs.file_name = buf_name;
         addCallTreeFindInFileArgs(addUsesArgs);
         found_files:[_file_case(buf_name)] = true;
      }
   }

   // save the current buffer state
   orig_context_file := "";
   tag_get_detail2(VS_TAGDETAIL_current_file,0,orig_context_file);
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_push_context();

   // this is the language to restrict references matches to
   restrictToLangId := "";
   if (!(def_references_options & VSREF_ALLOW_MIXED_LANGUAGES)) {
      restrictToLangId = cm.language;
      if (restrictToLangId == "" && cm.file_name != null && cm.file_name != "") {
         restrictToLangId = _Filename2LangId(cm.file_name);
      }
      if (restrictToLangId == "") {
         tag_get_detail2(VS_TAGDETAIL_language_id,0,restrictToLangId);
      }
   }

   // Check what the references scope is
   orig_tag_files := tag_files;

   // for each tag file to consider
   last_file_index := 0;
   t=0;
   ref_database=next_tag_filea(tag_files,t,false,true);
   while (ref_database != "") {

      if (tag_database) {

         // make sure this database matches the language we are searching for
         if (tag_find_language(auto foundLang, restrictToLangId) < 0) {
            // next tag file, please...
            ref_database=next_tag_filea(tag_files,t,false,true);
            continue;
         }

         // match instances using Context Tagging(R)
         if (!(tag_get_db_flags() & VS_DBFLAG_occurrences)) {
            ref_database=next_tag_filea(tag_files,t,false,true);
            continue;
         }
         if (_chdebug) {
            isay(depth, "caller_tree_add_refs: ADD FILES FROM: "ref_database);
         }

         status = tag_find_occurrence(cm.member_name, true, case_sensitive);
         while (!status) {
            tag_get_occurrence(auto occurName, auto occurFilename);
            if (!found_files._indexin(_file_case(occurFilename))) {
               addUsesArgs.file_name = occurFilename;
               addCallTreeFindInFileArgs(addUsesArgs);
               found_files:[_file_case(occurFilename)] = true;
               if (_chdebug) {
                  isay(depth, "caller_tree_add_refs:    FOUND FILE: ":+occurFilename);
               }
            }
            status = tag_next_occurrence(cm.member_name, true, case_sensitive);
         }
         tag_reset_find_occurrence();
         
         // Perl special case for variables
         if ((_LanguageInheritsFrom("pl", cm.language) || _LanguageInheritsFrom("phpscript", cm.language)) && pos(_first_char(cm.member_name),"$%@")) {
            if (_chdebug) {
               isay(depth, "caller_tree_add_refs: PERL SPECIAL CASE symbol=: "cm.member_name);
            }
            alt_member_name := substr(cm.member_name,2);
            status = tag_find_occurrence(alt_member_name, true, case_sensitive);
            while (!status) {
               tag_get_occurrence(auto occurName, auto occurFilename);
               if (!found_files._indexin(_file_case(occurFilename))) {
                  addUsesArgs.file_name = occurFilename;
                  found_files:[_file_case(occurFilename)] = true;
                  if (_chdebug) {
                     isay(depth, "caller_tree_add_refs:    FOUND FILE: ":+occurFilename);
                  }
               }
               status = tag_next_occurrence(alt_member_name, true, case_sensitive);
            }
            tag_reset_find_occurrence();
         }

      } else {
         // match instances in BSC database
         bsc_tag_files :+= ref_database;
      }

      // next tag file, please...
      ref_database=next_tag_filea(tag_files,t,false,true);
   }

   // add a final item to indicate that we are done expanding all files
   // in this node, and we can sort and adjust column widths now.
   addUsesArgs.file_name      = "END";
   addUsesArgs.cm             = null;
   addCallTreeFindInFileArgs(addUsesArgs);

   // add BSC references
   if (inst_id > 0 && bsc_tag_files._length() > 0) {
      count = caller_tree_add_bsc_refs(inst_id, filter_flags, tree_index, bsc_tag_files);
   }

   // return total number of items inserted
   return count;
}

/**
 * Add refs from BSC file.
 * 
 * @param inst_id          symbol instance ID for BSC references databases
 * @param flag_mask        bitset of VS_TAGFITLER_*, for filtering tree 
 *                         to specific types of symbols
 * @param tree_index       tree node index in caller tree
 * @param tag_files        tag database (BSC files) to search.
 * 
 * @return Returns the number of items inserted.
 */
static int caller_tree_add_bsc_refs(int inst_id,
                                    SETagFilterFlags flag_mask,
                                    int tree_index,
                                    _str (&tag_files)[])
{
   // for each BSC file to consider
   count := 0;
   t := 0;
   ref_database := next_tag_filea(tag_files,t,false,true);
   while (ref_database != "") {

      status := tag_read_db(ref_database);
      if ( status < 0 ) {
         break;
      }

      // find references to this instance
      ref_type  := 0;
      file_name := "";
      line_no   := 0;
      ref_id    := tag_find_refer_to(inst_id, ref_type, file_name, line_no);

      while (count < def_cb_max_references && ref_id >= -1) {

         // if something is going on, get out of here
         if( count % 20 == 0 && _IsKeyPending(false) ) {
            break;
         }

         // compute name / line number string for sorting
         fcaption := "";
         pic_ref  := _pic_file;

         // by default, insert as a leaf node
         show_children := TREE_NODE_LEAF;

         // find the context and create caption and icon for it
         tag_init_tag_browse_info(auto cm);
         if (ref_id > 0) {
            // get details about this tag (for creating caption)
            tag_get_instance_info(ref_id, cm.member_name, cm.type_name, cm.flags, cm.class_name, cm.arguments, cm.file_name, cm.line_no);
         }

         if (ref_id > 0 && cm.member_name != "") {
            // check if this item should be skipped
            if (!tag_filter_type(SE_TAG_TYPE_NULL,flag_mask,cm.type_name,(int)cm.flags)) {
               ref_id = tag_next_refer_to(inst_id, ref_type, file_name, line_no);
               continue;
            }

            // create caption for this item
            fcaption = tag_make_caption_from_browse_info(cm, include_class:true, include_args:false, include_tab:true);

            // get the appropriate bitmap
            pic_ref = tag_get_bitmap_for_type(tag_get_type_id(cm.type_name), cm.flags, auto pic_overlay);
            if (tag_tree_type_is_class(cm.type_name) || tag_tree_type_is_package(cm.type_name) || tag_tree_type_is_func(cm.type_name)) {
               if (!pos("proto", cm.type_name) && !(cm.flags & SE_TAG_FLAG_FORWARD)) {
                  show_children = TREE_NODE_COLLAPSED;
               }
            }
         } else {
            // reference is outside of this tag file, just display filename, line_no
            fcaption = _strip_filename(file_name, 'P');
         }

         // insert the item and set the user info
         index := _TreeAddItem(tree_index,fcaption,TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,pic_ref,_pic_symbol_public,show_children,0,ref_id);
         if (index < 0) {
            break;
         }
         ++count;

         // next, please
         ref_id = tag_next_refer_to(inst_id, ref_type, file_name, line_no);
      }

      // close the references database
      status = tag_close_db(ref_database,true);
      if ( status ) {
         return 0;
      }
      ref_database=next_tag_filea(tag_files,t,false,true);
   }

   // return the number of items added
   return count;
}


//##############################################################################
//##############################################################################

/**
 * Handle on-change event for symbol callers/refs tool window tree control.
 *  
 * The CHANGE_LEAF_ENTER event is handled like we handle the double-click 
 * event and utilizes {@link push_tag_in_file} to push a bookmark and bring up 
 * the code in the editor. 
 *  
 * The CHANGE_EXPANDED event handles expanding caller tree nodes by one level. 
 *  
 * The CHANGE_SELECTED event handles updating the preview tool window for 
 * the current tree item. 
 *  
 * @param reason     tree event code (CHANGE_*) 
 * @param currIndex  current tree node index
 */
void ctl_call_tree_view.on_change(int reason,int currIndex)
{
   if (currIndex < 0) return;
   if (_chdebug) {
      say("ctl_call_tree_view.on_change: reason="reason" index="currIndex" depth="_TreeGetDepth(currIndex));
   }
   if (reason == CHANGE_LEAF_ENTER) {
      // get the context information, push book mark, and open file to line
      status := ctl_call_tree_view.caller_tree_get_tag_info(currIndex, auto cm, auto inst_id);
      if (status > 0) {
         push_pos_in_file(cm.file_name, cm.line_no, 0);
      } else {
         caption := _TreeGetCaption(currIndex);
         parse caption with caption "\t" .;
         message("Could not find tag: " caption);
      }

   } else if (reason == CHANGE_EXPANDED) {

      se.util.MousePointerGuard hour_glass;
      status := ctl_call_tree_view.caller_tree_get_tag_info(currIndex, auto cm, auto inst_id);
      if (status > 0) {

         pCallTreeCache := getCallerTreeCache(resetCache:true);
         call_tree_enable_cancel();


         // insert the items we reference into the caller tree
         ctl_call_tree_view.caller_tree_add_refs(currIndex, cm, inst_id);
         call_tree_start_timer(gCallerTreeExpandTimerId, p_active_form, _CallerTreeExpandCallback);

         if (check_call_tree_cancel_button()) {
            call_tree_disable_cancel();
         }
      }

   } else if (reason == CHANGE_COLLAPSED) {
      ctl_call_tree_view._TreeDelete(currIndex,"c");

   } else if (reason == CHANGE_SELECTED) {
      focus_wid := _get_focus();
      if (focus_wid == ctl_call_tree_view || focus_wid == ctl_stack_view) {
         call_tree_start_timer(gCallTreeUpdateTimerId, p_active_form, _CallerTreeUpdateCallback);
         call_tree_update_symbol_trace(currIndex);
      }
   }
}

/**
 * Handle on-highlight event for symbol callers/refs tool window tree control.
 * 
 * @param index     tree node index under the mouse pointer
 * @param caption   full caption of tree node
 */
void ctl_call_tree_view.on_highlight(int index, _str caption="")
{
   //say("ctl_call_tree_view.on_highlight: index="index" caption="caption);
   call_tree_kill_timer(gCallTreeHighlightTimerId);
   if (!def_tag_hover_preview) return;
   if (index < 0) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   call_tree_start_timer(gCallTreeHighlightTimerId, 
                        p_active_form,
                        _CallerTreeHighlightCallback, 
                        index, 
                        def_tag_hover_delay);
   //call_tree_update_symbol_trace(index);
}


//##############################################################################
//##############################################################################

/**
 * Update other views when the symbols caller tree gets focus, important because 
 * inheritance view, call tree, and props can also update the output 
 * preview window, so if they return focus to the symbols caller/refs tree, 
 * we need to restart the update timer.
 */
void ctl_call_tree_view.on_got_focus()
{
   if (!_find_control("ctl_call_tree_view")) return;
   call_tree_start_timer(gCallTreeUpdateTimerId, 
                        p_active_form, 
                        _CallerTreeUpdateCallback);
   call_tree_update_symbol_trace();
}

