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
#import "c.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "files.e"
#import "help.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "math.e"
#import "mouse.e"
#import "notifications.e"
#import "seltree.e"
#import "setupext.e"
#import "slickc.e"
#import "stdprocs.e"
#import "tagform.e"
#import "taggui.e"
#import "tags.e"
#import "util.e"
#import "toast.e"
#import "sc/lang/ScopedTimeoutGuard.e"
#import "se/tags/TaggingGuard.e"
#import "se/ui/mainwindow.e"
#endregion

//////////////////////////////////////////////////////////////////////////////
// global variables
//
static const CONTEXT_TOOLTIP_DELAYINC=    100;

static const PIC_LSPACE_Y=   60;    // Extra line spacing for list box.
static const PIC_LINDENT_X=  150;    // Indent before for list box bitmap.
static const PIC_RINDENT_X=  40;    // Indent after list box bitmap (hard-coded)

//////////////////////////////////////////////////////////////////////////////
// built-in limits
//
static const MAX_SYMBOL_MATCHES=    512;
static const MAX_RECURSIVE_SEARCH=   32;
static const MAX_SEARCH_CALLS=      500;


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Globals needed for tool tips for context control
//
static int gi_ContextTimerID = -1;
static bool gContextToolTipShown = false;
static int gi_UpdateTimerID = -1;
static int gi_PrevTotalJobs = 0;

static bool gcontext_files_too_large:[] = null;

int def_context_toolbar_flags=0;//CONTEXT_TOOLBAR_ADD_LOCALS;

/**
 * Specifies the maximum size, in kilobytes, a file is allowed to have in 
 * order to be tagged.
 *  
 * @default 2048k
 * @categories Configuration_Variables 
 */
int def_update_context_max_ksize = 0x800;
/**
 * Specifies the maximum size, in kilobytes, a file is allowed to have in 
 * order to be tagged when the file's language mode uses a slower proc-search 
 * based tagging function. 
 *  
 * @default 2048k
 * @categories Configuration_Variables 
 */
int def_update_context_slow_max_ksize = 0x100;
/**
 * Specifies the maximum size, in kilobytes, a file is allowed to have in order 
 * to be tagged using statement tagging.
 *  
 * @default 512k
 * @categories Configuration_Variables 
 * @since 20.0 
 */
int def_update_statements_max_ksize = 0x200;
/**
 * Specifies the maximum size, in kilobytes, a file is allowed to have in order 
 * to be allowed to construct a token list. Token lists are used to optimize 
 * gathering expression information for symbol analysis, symbol coloring, and 
 * positional keyword coloring.
 *  
 * @default 1024k
 * @categories Configuration_Variables 
 * @since 20.0 
 */
int def_update_tokenlist_max_ksize = 0x400;
/**
 * Specifies the maximum number of tags (including statements, 
 * if Statement Level Tagging is enabled) that a file is allowed to have in 
 * order to appear in the Defs, Class, and Current Context tool windows. 
 * 
 * @default 128k
 * @categories Configuration_Variables 
 */
int def_update_context_max_symbols = 0x20000;
/**
 * Specifies the maximum amount of time in millisconds to spend updating the current context. 
 * This setting exists to prevent delays when updating the symbols in the 
 * current file for files that have slower proc-search functions instead of 
 * fast tagging callbacks written in C++.
 * 
 * @default 2500 ms
 * @categories Configuration_Variables 
 * @since 21.0
 */
int def_update_context_max_time = 2500;
/**
 * Specifies the maximum number of items to store in the context tagging 
 * class name caches.  When the caches exceed this number they will be wiped 
 * and restarted.  These caches are also wiped out on application activation, 
 * and when you switch worksapces. 
 * 
 * @default 1000
 * @categories Configuration_Variables 
 * @since 24.0
 */
int def_tag_max_class_name_cache = 1000;
/**
 * If the average time in milliseconds to update the context for the current file 
 * exceeds this threshold, avoid non-essential operations, like auto-complete, 
 * symbol coloring and highlighting, and beautify while typing which require 
 * the current context to be updated on demand.
 * 
 * @default 500
 * @categories Configuration_Variables 
 * @since 25.0
 */
int def_update_context_slow_ms = 500;
/**
 * If the maximum time in milliseconds to update the context for the current file 
 * is less than this threshold, do not hesitate to update the current context 
 * when it is needed for updating a tool window or auto-complete or any other 
 * tagging operation.
 * 
 * @default 100
 * @categories Configuration_Variables 
 * @since 25.0
 */
int def_update_context_fast_ms = 100;

struct CONTEXT_FORM_INFO {
   int m_combo_box_wid;
   _str m_context_window_filename;
   int m_context_window_seekpos;
   int m_context_highlight_index;
   _str m_context_highlight_text;
};
static CONTEXT_FORM_INFO gContextFormList:[];

struct UPDATE_CONTEXT_STAT_PACK {
   int  m_num_runs;     // number of runs
   int  m_num_tags;     // number of symbols found
   long m_run_time_sum; // sum of m_run_times
   long m_run_time_avg; // average run time
   long m_run_time_max; // max run time
   long m_run_time_min; // min run time
};
struct UPDATE_CONTEXT_STATS {
   _str m_file_name;    // file name
   _str m_file_lang;    // language mode
   long m_file_size;    // file size

   UPDATE_CONTEXT_STAT_PACK m_context;
   UPDATE_CONTEXT_STAT_PACK m_statements;
   UPDATE_CONTEXT_STAT_PACK m_tokens;
};

/**
 * Array of run time information collected on all open buffers.
 */
UPDATE_CONTEXT_STATS gUpdateContextStats:[];


/**
 * If enabled, all threaded background tagging results will be logged to 
 * the log file (tagging.log in the logs subdir of the user 
 * configuration directory). 
 * 
 * @default 0
 * @categories Configuration_Variables 
 * @since 16.0 
 */
int def_tagging_logging = 0;

/**
 * This option controls how frequently progress messages are emitted 
 * by background tagging when reporting results.  It is specified in 
 * RPM, reports per minute.  The default of 200 translates into approximately
 * three messages per minute. 
 * 
 * @default 200
 * @categories Configuration_Variables 
 * @since 17.0 
 */
int def_background_tagging_rpm = 200;

/**
 * Name of log file for tagging logging.
 */
const TAGGING_LOG="tagging";

static void _init_all_formobj(CONTEXT_FORM_INFO (&formList):[]) {
   int last = _last_window_id();
   eventtabIndex := find_index("_tbcontext_combo_etab",EVENTTAB_TYPE);
   for (i:=1; i<=last; ++i) {
      if (_iswindow_valid(i) && 
          i.p_object == OI_COMBO_BOX && 
          !i.p_active_form.p_edit &&
          i.p_eventtab==eventtabIndex) {
         formList:[i].m_combo_box_wid = i;
         formList:[i].m_context_window_filename = "";
         formList:[i].m_context_window_seekpos = 0;
         formList:[i].m_context_highlight_index = 0;
         formList:[i].m_context_highlight_text = "";
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (before defload).  Used to
// initialize the timer variable and window IDs.
//
definit()
{
   // IF editor is initializing from invocation
   if (arg(1)!='L') {
      gi_ContextTimerID = -1;
      gContextToolTipShown = false;
      gi_UpdateTimerID = -1;
      gcontext_files_too_large._makeempty();
      gUpdateContextStats._makeempty();
      call_list("_LoadBackgroundTaggingSettings");
   }
   gContextFormList._makeempty();
   _init_all_formobj(gContextFormList);
}

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// current context toolbar
//
defeventtab _tbcontext_form;

void _tbcontext_form.on_resize()
{
   _tbcontext_combo_etab.p_width = p_active_form.p_width - 2*_tbcontext_combo_etab.p_x;
   _tbcontext_combo_etab.p_y = (p_active_form.p_height - _tbcontext_combo_etab.p_height)>>1; 
}

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// kill the context combo box tool tip
//
static void killContextCBTimer()
{
   //say("killContextCBTimer("gi_ContextTimerID")");
   if (gi_ContextTimerID>=0) _kill_timer( gi_ContextTimerID );
   gi_ContextTimerID = -1;
   if (gContextToolTipShown) _bbhelp('C');
   gContextToolTipShown = false;
}

// check mouse position against context combo box, maybe display tool tip
static void contextTimerCB(int comboWID)
{
   //say("contextTimerCB()");
   // verify that gi_ContextWindowId is a valid combo box
   if (!_iswindow_valid(comboWID) ||
       comboWID.p_object!=OI_COMBO_BOX) {
      killContextCBTimer();
      return;
   }

   // find the selected symbol in the context tool window
   contextInfo := gContextFormList:[comboWID];
   if ( contextInfo!=null ) {
      selected_caption := contextInfo.m_context_highlight_text;
      int status = comboWID.find_selected_symbol(selected_caption, auto cm);
      if (status) {
         return;
      }

      // update the properties and arguments tool windows
      cb_refresh_property_view(cm);
      cb_refresh_arguments_view(cm);

      // find the output tagwin and update it
      cb_refresh_output_tab(cm, true);


      if (gi_ContextTimerID>=0) _kill_timer( gi_ContextTimerID );
      gi_ContextTimerID = _set_timer( CONTEXT_TOOLTIP_DELAYINC, contextTimerCB,comboWID );
   }
}


//////////////////////////////////////////////////////////////////////////////
static void updateTimerCB(int comboWID)
{
   //say("updateTimerCB: ");
   // kill the timer
   if (gi_UpdateTimerID>=0) {
      _kill_timer( gi_UpdateTimerID );
      gi_UpdateTimerID = -1;
   }

   // if something is going on, get out of here
   if( _IsKeyPending() ) {
      return;
   }

   if (!_iswindow_valid(comboWID) || comboWID.p_object!=OI_COMBO_BOX) {
      return;
   }

   // find the selected symbol in the context tool window
   selected_caption := comboWID.p_text;
   int status = comboWID.find_selected_symbol(selected_caption, auto cm);
   if (status) {
      return;
   }

   // update the properties and arguments tool windows
   cb_refresh_property_view(cm);
   cb_refresh_arguments_view(cm);

   // find the output tagwin and update it
   cb_refresh_output_tab(cm, true);
}

//////////////////////////////////////////////////////////////////////////////
// Constants for drawing list box
//

defeventtab _tbcontext_combo_etab;

static int find_selected_symbol(_str selected_caption, VS_TAG_BROWSE_INFO &cm)
{
   editorWID := contextGetActiveEditor(p_window_id);
   if ( !editorWID ) return 0;
   // initialize the symbol information
   tag_init_tag_browse_info(cm);

   // check for categories caption
   if (pos("---",selected_caption)==1) {
      return STRING_NOT_FOUND_RC;
   }

   // count the number of duplicate symbols in the list
   i := num_dups := 0;
   caption := "";
   orig_line := p_line;
   _lbtop();
   for (;;) {
      caption = _lbget_text();
      if (caption==selected_caption) {
         ++num_dups;
         if (caption:==selected_caption) break;
      }
      if (_lbdown()) break;
   }
   p_line = orig_line;

   //say("SELECTED: '"selected_caption"'");

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   editorWID._UpdateContext(true);

   if (def_context_toolbar_flags & CONTEXT_TOOLBAR_ADD_LOCALS) {
      editorWID._UpdateLocals(true,true);
      num_locals := tag_get_num_of_locals();
      for (i=1; i<=num_locals; i++) {
         tag_get_detail2(VS_TAGDETAIL_local_flags, i, auto local_flags);
         if (local_flags & SE_TAG_FLAG_IGNORE) continue;
         caption = tag_tree_make_caption_fast(VS_TAGMATCH_local,i,true,true,false);
         if (selected_caption == caption) {
            if (--num_dups > 0) continue;
            tag_get_local_info(i, cm);
            return 0;
         }
      }
   }

   num_context := tag_get_num_of_context();
   for (i=1; i<=num_context; i++) {
      caption = tag_tree_make_caption_fast(VS_TAGMATCH_context,i,true,true,false);
      if (selected_caption == caption) {
         if (--num_dups > 0) continue;
         tag_get_context_info(i, cm);
         return 0;
      }
   }

   return STRING_NOT_FOUND_RC;
}

/** 
 * If this is a duplicate of the item currently displayed as the 
 * current context, add a harmless extra space to the caption so that 
 * the combo box selects the right item when dropped down.
 */
static void mark_duplicate_symbols_with_space(VS_TAG_BROWSE_INFO &cm, 
                                              int (&duplicateCaptions):[]) 
{
   cur_caption := _lbget_text();
   num_dups := 0;
   if (duplicateCaptions._indexin(cur_caption)) {
      num_dups = duplicateCaptions:[cur_caption] + 1;
      pic_index := tag_get_bitmap_for_type(tag_get_type_id(cm.type_name), cm.flags);
      _lbset_item(cur_caption:+substr("",1,num_dups," "), 0, pic_index);
   }
   duplicateCaptions:[cur_caption] = num_dups;

   editor_position := _mdi.p_child._QROffset();
   if (num_dups > 0 && editor_position >= cm.seekpos && editor_position <= cm.end_seekpos) {
      if (cur_caption == p_text) {
         _cbset_text(cur_caption:+substr("",1,num_dups," "));
      }
   }
}

void context_window_set_editor_wid(int editorWID)
{
   _SetDialogInfoHt("editorWID",editorWID,p_window_id);
}

void context_window_set_push_tag_pointer(typeless *pfn)
{
   _SetDialogInfoHt("pushTagPointer",pfn,p_window_id);
}

int context_window_get_editor_wid()
{
   editorWID := _GetDialogInfoHt("editorWID",p_window_id);
   if ( editorWID!=null ) {
      return editorWID;
   }
   return _MDIGetActiveMDIChild();
}

static typeless context_window_get_push_tag_pointer()
{
   pfn := _GetDialogInfoHt("pushTagPointer",p_window_id);
   if ( pfn!=null ) {
      return pfn;
   }
   return push_tag_in_file;
}

void _tbcontext_combo_etab.on_drop_down(int reason)
{
   //say("_tbcontext_combo_etab.on_drop_down: reason="reason);
   static bool didDropUp;
   VS_TAG_BROWSE_INFO cm;
   killContextCBTimer();
   editorWID := contextGetActiveEditor(p_window_id);
   if (_no_child_windows() || !editorWID) {
      _lbclear();
      return;
   }

   // set caption and bitmaps for current context
   if (reason==DROP_INIT) {
      didDropUp = false;

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      editorWID._UpdateContext(true,true);
      if (def_context_toolbar_flags & CONTEXT_TOOLBAR_ADD_LOCALS) {
         editorWID._UpdateLocals(true,true);
      }
      editorWID._UpdateContextWindow(true);

      // keep track of duplicate captions
      int duplicateCaptions:[];

      // set caption and bitmaps for current context
      cb_prepare_expand(p_window_id, 0, 0);
      origCaption := p_text;
      _lbclear();
      p_picture=_pic_file;

      num_locals := 0;
      lcl_start_point := 0;
      if (def_context_toolbar_flags & CONTEXT_TOOLBAR_ADD_LOCALS) {
         _lbadd_item("---Locals---",0,_pic_fldopen);
         lcl_start_point = p_line+1;
         num_locals = tag_get_num_of_locals();
         for (i:=1; i<=num_locals; i++) {
            tag_get_local_info(i, cm);
            if (cm.flags & (SE_TAG_FLAG_IGNORE|SE_TAG_FLAG_OUTLINE_HIDE|SE_TAG_FLAG_ANONYMOUS)) continue;
            tag_list_insert_tag(p_window_id, 0, PIC_LINDENT_X,
                                cm.member_name, cm.type_name, 
                                cm.file_name,   cm.line_no, 
                                cm.class_name,  (int)cm.flags, 
                                cm.return_type:+VS_TAGSEPARATOR_args:+cm.arguments);
            mark_duplicate_symbols_with_space(cm, duplicateCaptions);
         }
      }

      lcl_end_point := p_line;
      _lbadd_item("---Buffer---",0,_pic_fldopen);
      int ctx_start_point = p_line+1;
      int num_context = tag_get_num_of_context();
      for (i:=1; i<=num_context; i++) {
         tag_get_context_info(i, cm);
         // Don't insert statements into current context list
         if (cm.flags & (SE_TAG_FLAG_IGNORE|SE_TAG_FLAG_OUTLINE_HIDE|SE_TAG_FLAG_ANONYMOUS)) continue;
         if( !tag_tree_type_is_statement(cm.type_name)) {
            tag_list_insert_tag(p_window_id, 0, PIC_LINDENT_X,
                                cm.member_name, cm.type_name, 
                                cm.file_name,   cm.line_no, 
                                cm.class_name,  (int)cm.flags, 
                                cm.return_type:+VS_TAGSEPARATOR_args:+cm.arguments);
            mark_duplicate_symbols_with_space(cm, duplicateCaptions);
         }
      }

      ctx_end_point := p_line;
      if (!(def_context_toolbar_flags&CONTEXT_TOOLBAR_SORT_BY_LINE)) {
         if (num_locals > 0) {
            _lbsort('i',lcl_start_point,lcl_end_point);
         }
         if (num_context > 0) {
            _lbsort('i',ctx_start_point,ctx_end_point);
         }
      }
      _lbtop();
      _cbset_text(origCaption);
      
   } else if (reason==DROP_DOWN) {
   
   } else if (reason==DROP_UP_SELECTED /*|| reason==DROP_UP*/) {

      // RB - 6/27/2002 - Cannot check for DROP_UP because clicking with the
      // mouse causes both a DROP_UP_SELECTED _and_ a DROP_UP reason to be
      // triggered. The DROP_UP arrives after the DROP_UP_SELECTED and causes
      // a jump to the wrong symbol.
      if (didDropUp) return;

      // find the symbol to insert and insert it
      selected_caption := p_text;
      if (pos("---",selected_caption)==1) {
         p_picture = _pic_fldopen;
         return;
      }
      int status = find_selected_symbol(selected_caption, cm);
      if (status == 0) {    
         didDropUp = true;
         call_list("-before-context-combo-select-",p_window_id);
         typeless *pfn = context_window_get_push_tag_pointer();
         (*pfn)(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
         call_list("-after-context-combo-select-",p_window_id);
      }
   }
}
// callback for when a context combo box is created
void _tbcontext_combo_etab.on_create()
{
   if (!_haveCurrentContextToolBar()) {
      p_visible = false;
      p_width = 0;
      p_enabled = false;
      return;
   }

   p_pic_point_scale=0;
   p_pic_space_y=PIC_LSPACE_Y;
   p_style=PSCBO_NOEDIT;

   i := p_window_id;
   CONTEXT_FORM_INFO info;
   info.m_combo_box_wid=i;
   info.m_context_window_filename = "";
   info.m_context_window_seekpos = 0;
   info.m_context_highlight_index = 0;
   info.m_context_highlight_text = "";
   gContextFormList:[i] = info;

   if (_no_child_windows()) {
      _lbclear();
      p_picture = 0;
      ContextMessage("");
   } else {
      editorWID := contextGetActiveEditor(p_window_id);
      updateSingleContextWindow(p_window_id,info,_idle_time_elapsed(),editorWID,false);
   }
}

// monitor mouse move events when over the context window
void _tbcontext_combo_etab.mouse_move()
{
   //say("_tbcontext_combo_etab.mouse_move: HERE");
   //gContextToolTipShown=false;
   if (gi_ContextTimerID >= 0 || gContextToolTipShown) {
      //say("shown="gContextToolTipShown);
      return;
   }
   gi_ContextTimerID = _set_timer(CONTEXT_TOOLTIP_DELAYINC, contextTimerCB, p_window_id);
}

void _tbcontext_combo_etab.on_change(int reason)
{
   //say("_tbcontext_combo_etab.on_change: reason="reason);
   if ( reason==CHANGE_SELECTED || reason==CHANGE_CLINE ) {
      //say("_tbcontext_combo_etab.on_change: p_line="p_line);
      // kill the timer
      if (gi_UpdateTimerID>=0) {
         _kill_timer( gi_UpdateTimerID );
         gi_UpdateTimerID = -1;
      }
      // restart the timer (to reset the delay)
      gi_UpdateTimerID = _set_timer(CB_TIMER_DELAY_MS, updateTimerCB, p_window_id);
   }
}

void _tbcontext_combo_etab.on_highlight(int index=0, _str caption="")
{
   if (!def_tag_hover_preview) {
      return;
   }
   //say("_tbcontext_combo_etab.on_highlight: index="index" caption="caption);

   contextInfo := gContextFormList:[p_window_id];
   if ( contextInfo!=null ) {
      contextInfo.m_context_highlight_index = index;
      contextInfo.m_context_highlight_text = caption;
      gContextFormList:[p_window_id] = contextInfo;
   }
   if (gi_ContextTimerID >= 0 || gContextToolTipShown) {
      return;
   }
   if ( contextInfo!=null ) {
      if ( contextInfo.m_context_highlight_index > 0 && 
           contextInfo.m_context_highlight_text != "") {
         gi_ContextTimerID = _set_timer(def_tag_hover_delay, contextTimerCB, p_window_id);
      }
   }
}

void _tbcontext_combo_etab.rbutton_down()
{
   index := find_index("_context_toolbar_menu",oi2type(OI_MENU));
   if (!index) return;
   menu_handle := _menu_load(index,'P');
   if (menu_handle <= 0) return;

   if (def_context_toolbar_flags & CONTEXT_TOOLBAR_DISPLAY_LOCALS) {
      _menu_set_state(menu_handle, "context_toolbar_display_local", MF_CHECKED, 'M');
   }
   if (def_context_toolbar_flags & CONTEXT_TOOLBAR_ADD_LOCALS) {
      _menu_set_state(menu_handle, "context_toolbar_list_locals", MF_CHECKED, 'M');
   }
   if (def_context_toolbar_flags & CONTEXT_TOOLBAR_SORT_BY_LINE) {
      _menu_set_state(menu_handle, "context_toolbar_sort_by_line", MF_CHECKED, 'M');
   }

   int x,y;
   mou_get_xy(x,y);
   _menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

void _tbcontext_combo_etab.on_destroy()
{
   gContextFormList._deleteel(p_window_id);
}

// leave message in context box
//
static void ContextMessage(_str msg, int pic_index=0)
{
   if (msg=="") {
      msg = "no current context";
   }
   _cbset_text(msg, pic_index);
}

_command void context_toolbar_display_local() name_info(','VSARG2_READ_ONLY)
{
   if (!_haveCurrentContextToolBar()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "Current Context toolbar");
      return;
   }
   if (def_context_toolbar_flags & CONTEXT_TOOLBAR_DISPLAY_LOCALS) {
      def_context_toolbar_flags &= ~CONTEXT_TOOLBAR_DISPLAY_LOCALS;
   } else {
      def_context_toolbar_flags |= CONTEXT_TOOLBAR_DISPLAY_LOCALS|CONTEXT_TOOLBAR_ADD_LOCALS;
   }
   if (!_no_child_windows()) {
      removeModifyFlags(MODIFYFLAG_CONTEXTWIN_UPDATED);
      _UpdateContextWindow(true);
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
_command void context_toolbar_list_locals() name_info(','VSARG2_READ_ONLY)
{
   if (!_haveCurrentContextToolBar()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "Current Context toolbar");
      return;
   }
   if (def_context_toolbar_flags & CONTEXT_TOOLBAR_ADD_LOCALS) {
      def_context_toolbar_flags &= ~CONTEXT_TOOLBAR_ADD_LOCALS;
   } else {
      def_context_toolbar_flags |= CONTEXT_TOOLBAR_ADD_LOCALS;
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
_command void context_toolbar_sort_by_line() name_info(','VSARG2_READ_ONLY)
{
   if (!_haveCurrentContextToolBar()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "Current Context toolbar");
      return;
   }
   if (def_context_toolbar_flags & CONTEXT_TOOLBAR_SORT_BY_LINE) {
      def_context_toolbar_flags &= ~CONTEXT_TOOLBAR_SORT_BY_LINE;
   } else {
      def_context_toolbar_flags |= CONTEXT_TOOLBAR_SORT_BY_LINE;
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
_command void context_next_tag() name_info(','VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   if (!_no_child_windows()) _mdi.p_child.next_tag();
}
_command void context_prev_tag() name_info(','VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   if (!_no_child_windows()) _mdi.p_child.prev_tag();
}
_command void context_begin_tag() name_info(','VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   if (!_no_child_windows()) _mdi.p_child.begin_tag();
}
_command void context_end_tag() name_info(','VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   if (!_no_child_windows()) _mdi.p_child.end_tag();
}

/**
 * Look for the current symbol under the cursor, extending the 
 * search boundaries to include the comment immediately before 
 * or after the nearest symbol. 
 *  
 * Expects the current object to be an editor control. 
 *  
 * @return Returns the context id of symbol if found, 0 otherwise. 
 */
static int tag_current_context_or_comment()
{
   // save position and search settings
   save_pos(auto p);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);

   // Allocate a selection for searching top of file
   orig_mark_id := _duplicate_selection("");
   mark_id := _alloc_selection();
   if (mark_id<0) return mark_id;

   // create a selection of the surrounding 500 lines
   if (p_RLine > def_codehelp_max_comments) {
      p_RLine = p_RLine - def_codehelp_max_comments;
   } else {
      top();
   }
   _select_line(mark_id);
   restore_pos(p);
   p_RLine = p_RLine + def_codehelp_max_comments;
   _select_line(mark_id);
   _end_select(mark_id,true);
   _show_selection(mark_id);
   restore_pos(p);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // try to calculate the nearest symbol inclusive to this comment
   context_id := 0;
   do {
      if (_clex_find(0,'g')==CFG_COMMENT) {
         // check for a trailing line comment
         reverse := "";
         context_id = tag_nearest_context(p_RLine);
         if (context_id > 0) {
            tag_get_detail2(VS_TAGDETAIL_context_start_linenum,context_id,auto nearest_line);
            tag_get_detail2(VS_TAGDETAIL_context_start_seekpos,context_id,auto nearest_pos);
            if (nearest_line == p_RLine && nearest_pos < _QROffset()) {
               reverse = "-";
            }
         }
         // skip the comment and spaces between comment and symbol
         _clex_skip_blanks(reverse:+'mh');

      } else if (pos(get_text()," \t\n\r")) {
         // we may be in spaces between comment and symbol, first look back  
         search('[~ \t\r\n]','@-rh');
         if (_clex_find(0,'g') == CFG_COMMENT) {
            _clex_skip_blanks('mh');
         } else {
            // check for trailing comment case
            restore_pos(p);
            search('[~ \t\r\n]','@rh');
            if (_clex_find(0,'g') == CFG_COMMENT) {
               line_with_comment := p_RLine;
               _clex_skip_blanks('-mh');
               if (line_with_comment != p_RLine) {
                  break;
               }
            } else {
               break;
            }
         }

      } else {
         break;
      }

      // find the current context now that we are on the symbol
      context_id = tag_current_context(allow_outline_only:true);

   } while (false);

   // clean up
   _show_selection(orig_mark_id);
   _free_selection(mark_id);
   restore_search(s1, s2, s3, s4, s5);
   restore_pos(p);
   return context_id;
}

static int contextGetActiveEditor(int comboWID)
{
   wid := comboWID.context_window_get_editor_wid();
   return wid;
}

/**
 * Check if the current context is up-to-date, of if we should allow it to be 
 * updated immediately. 
 *  
 * Some tool windows which update on a timer can wait for a thread to finish 
 * updating the current context instead of parsing the current file immedately 
 * in the foreground thread. 
 *  
 * @param elapsed       number of milliseconds elapsed since last idle time
 * @param modifyFlags   bitset of MODIFYFLAG_* to check if context is up-to-date
 * 
 * @return 
 * Returns 'true' under the following conditions: 
 * <ul> 
 *    <li>The modify flags are set, indicating that the context has been updated.</li>
 *    <li>The elapsed time exceeds {@link def_update_tagging_idle} + {@link def_update_tagging_extra_idle}</li>
 *    <li>We know from tagging statistics that this file can be parsed in less than {@link def_update_context_fast_ms}</li>
 *    <li>More than twice {@link def_update_tagging_idle} has passed, and {@link _UpdateContext(false...)} succeeds</li>
 * </ul> 
 * Returns 'false' under the following conditions: 
 * <ul> 
 *    <li>The current object is not an editor control.</li>
 *    <li>The editor is still in auto-restore.</li>
 *    <li>The elapsed time is less than twice {@link def_update_tagging_idle}, and statistics show this file does not parse quickly.</li>
 *    <li>More than twice {@link def_update_tagging_idle} has passed, so we need to respond, bug {@link _UpdateContext(false...)} fails</li>
 * </ul> 
 *  
 * @categories Tagging_Functions 
 */
bool _ContextIsUpToDate(long elapsed=0, int modifyFlags=MODIFYFLAG_CONTEXT_UPDATED)
{
   // this better be an editor control
   if (!_isEditorCtl()) {
      return false;
   }
   // still restoring?
   if (!_autoRestoreFinished()) {
      return false;
   }
   // context up to date
   if ((p_ModifyFlags & modifyFlags) == modifyFlags) {
      return true;
   }
   // a lot of time has elapsed, so act like it is up-to-date
   if (elapsed == 0) elapsed = _idle_time_elapsed();
   if (elapsed > def_update_tagging_idle+def_update_tagging_extra_idle) {
      return true;
   }
   // not enough idle time elapsed
   if (elapsed < 2*def_update_tagging_idle) {
      // If this buffer can be updated fast enough, then just update it
      // otherwise, wait and see if a tagging thread finishes up
      if (elapsed > def_update_context_fast_ms) {
         if (modifyFlags & MODIFYFLAG_STATEMENTS_UPDATED) {
            return _UpdateStatementsIsFast();
         } else if (modifyFlags & MODIFYFLAG_TOKENLIST_UPDATED) {
            return _UpdateContextAndTokensIsFast();
         } else {
            return _UpdateContextIsFast();
         }
      }
      return false;
   }
   // try to get the context to update anyway
   updateFlags := VS_UPDATEFLAG_context;
   if (modifyFlags & MODIFYFLAG_TOKENLIST_UPDATED) {
      updateFlags |= VS_UPDATEFLAG_tokens;
   }
   if (modifyFlags & MODIFYFLAG_STATEMENTS_UPDATED) {
      updateFlags |= VS_UPDATEFLAG_statement;
   }
   _UpdateContext(false, false, updateFlags);
   // check again if context is up to date
   if ((p_ModifyFlags & modifyFlags) == modifyFlags) {
      return true;
   }
   // not up-to-date
   return false;
}

/**
 * Update the current context combo box window(s)
 * the current object must be the editor control to update
 *
 * @param AlwaysUpdate  update now, or wait for
 *                      CONTEXT_UPDATE_TIMEOUT ms idle time?
 */
static void updateSingleContextWindow(int comboBoxWID,
                                      CONTEXT_FORM_INFO &formInfo,
                                      long elapsed,
                                      int editorWID,
                                      bool AlwaysUpdate=false)
{
   // make sure timer has waited long enough
   editor_wid_is_valid := (editorWID && editorWID._isEditorCtl());
   idle_time := _idle_time_elapsed();
   if (!AlwaysUpdate && idle_time < def_update_tagging_idle) {
      if (!editor_wid_is_valid || 
          idle_time < def_update_context_fast_ms ||
          !editorWID._UpdateContextIsFast()) {
         //say("don't always update");
         return;
      }
   }

   // do not update if no context window to update
   if ( !editorWID || !editorWID._isEditorCtl() || !editorWID._istagging_supported()) {
      comboBoxWID.ContextMessage("");
      return;
   }

   // if the context is not yet up-to-date, then don't update yet
   if (!AlwaysUpdate && !editorWID._ContextIsUpToDate(idle_time)) {
      return;
   }

   // blow out of here if cursor hasn't moved and file not modified
   int curr_seekpos = (int)editorWID._QROffset();
   if ((editorWID.p_ModifyFlags&MODIFYFLAG_CONTEXTWIN_UPDATED) &&
       formInfo.m_context_window_seekpos==curr_seekpos &&
       formInfo.m_context_window_filename:==editorWID.p_buf_name) {
      //say("no cursor movement");
      return;
   }
   formInfo.m_context_window_filename = editorWID.p_buf_name;
   formInfo.m_context_window_seekpos  = curr_seekpos;
   editorWID.p_ModifyFlags |= MODIFYFLAG_CONTEXTWIN_UPDATED;

   // Update the current context
   cb_prepare_expand(p_window_id, 0, 0);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   editorWID._UpdateContext(true);
   editorWID._UpdateLocals(true);

   type_name := "";
   tag_flags := SE_TAG_FLAG_NULL;
   caption   := "";
   pic_index := 0;

   // Update the context message, if current context is local variable
   local_id := editorWID.tag_current_local();
   if (local_id > 0 && 
       (def_context_toolbar_flags & CONTEXT_TOOLBAR_ADD_LOCALS) &&
       (def_context_toolbar_flags & CONTEXT_TOOLBAR_DISPLAY_LOCALS) ) {
      //say("_UpdateContextWindow(): local_id="local_id);
      tag_get_detail2(VS_TAGDETAIL_local_type,local_id,type_name);
      tag_get_detail2(VS_TAGDETAIL_local_flags,local_id,tag_flags);
      caption = tag_tree_make_caption_fast(VS_TAGMATCH_local,local_id,true,true,false);
      pic_index = tag_get_bitmap_for_type(tag_get_type_id(type_name), tag_flags);
      comboBoxWID.ContextMessage(caption, pic_index);
      editorWID.p_ModifyFlags |= MODIFYFLAG_CONTEXTWIN_UPDATED;
      return;
   }

   // Update the context message
   context_id := editorWID.tag_current_context(allow_outline_only:true);
   if (context_id <= 0) {
      // check if we are in a comment directly before or after a symbol
      context_id = editorWID.tag_current_context_or_comment();
   }
   if (context_id <= 0) {
      comboBoxWID.ContextMessage("");
      //say("no context");
      return;
   }
   tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);
   tag_get_detail2(VS_TAGDETAIL_context_flags,context_id,tag_flags);
   caption = tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,true,true,false);
   pic_index = tag_get_bitmap_for_type(tag_get_type_id(type_name), tag_flags);
   comboBoxWID.ContextMessage(caption, pic_index);
   editorWID.p_ModifyFlags |= MODIFYFLAG_CONTEXTWIN_UPDATED;
}

static void removeModifyFlags(int flagsToRemove)
{
   CONTEXT_FORM_INFO v;
   int i;
   foreach (i => v in gContextFormList) {
      editorWID := contextGetActiveEditor(v.m_combo_box_wid);
      editorWID.p_ModifyFlags &= ~flagsToRemove;
   }
}

void _UpdateContextWindow(bool AlwaysUpdate=false)
{
   static int grecurse;

   // IF outline nag screen happened and we are recursing
   if (grecurse) {
      // Just get out
      return;
   }
   if ( !gContextFormList._length() ) return;

   ++grecurse;
   elapsed := _idle_time_elapsed();

   CONTEXT_FORM_INFO v;
   int i;
   foreach (i => v in gContextFormList) {
      editorWID := contextGetActiveEditor(v.m_combo_box_wid);
      updateSingleContextWindow(v.m_combo_box_wid,gContextFormList:[i],elapsed,editorWID,AlwaysUpdate);
   }
   --grecurse;
}

#if 0
//############################################################################
//////////////////////////////////////////////////////////////////////////////
// clear the context when the buffer is quit
//
void _switchbuf_context()
{
   //p_ModifyFlags &= ~MODIFYFLAG_CONTEXT_UPDATED;
   //p_ModifyFlags &= ~MODIFYFLAG_LOCALS_UPDATED;
   //p_ModifyFlags &= ~MODIFYFLAG_CONTEXTWIN_UPDATED;
   //p_ModifyFlags &= ~MODIFYFLAG_FCTHELP_UPDATED;
   //p_ModifyFlags &= ~MODIFYFLAG_PROCTREE_UPDATED;
   p_ModifyFlags &= ~MODIFYFLAG_PROCTREE_SELECTED;
}
#endif

//////////////////////////////////////////////////////////////////////////////
/**
 * Reset the list of files considered as too large to tag.
 */
void reset_context_files_too_large_list()
{
   gcontext_files_too_large._makeempty();
}
/**
 * Indicate that the current buffer is to large to tag in the background. 
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true) 
 * prior to invoking this function. 
 */
static void handleUpdateContextFailure(int nUpdateFlags, _str warning, _str adjust_var)
{
   tag_check_cached_context(nUpdateFlags);
   tag_clear_context();
   tag_init_tag_browse_info(auto cm);
   cm.member_name = warning :+ "  " :+
                    "Context information is not generated.  ":+
                    "Double-click to force it to be generated.  ":+
                    "Try adjusting '" :+ adjust_var :+ "' " :+
                    "or go to Tools > Options > Editing > Context Tagging":+VSREGISTEREDTM_TITLEBAR;
   cm.type_name = "package";
   cm.file_name = p_buf_name;
   cm.line_no = 1;
   cm.seekpos = 1;
   cm.scope_line_no = 1;
   cm.scope_seekpos = 1;
   cm.end_line_no   = 1;
   cm.end_seekpos   = p_buf_size;
   tag_insert_context_browse_info(0, cm);
}

bool _CheckUpdateContextSizeLimits(int nUpdateFlags=0, bool quiet=false)
{
   // adjust expectations for slower proc-searches
   LTindex := _FindLanguageCallbackIndex("vs%s-list-tags");
   PSindex := _FindLanguageCallbackIndex("%s-proc-search");
   buf_ksize := (p_buf_size intdiv 1024);
   // Bail out for large files.
   if (buf_ksize > def_update_context_max_ksize) {
      if (quiet) return false;
      if (!tag_check_cached_context(nUpdateFlags) || !(p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED)) {
         handleUpdateContextFailure(nUpdateFlags, "FILE IS TOO LARGE!","def_update_context_max_ksize");
         p_ModifyFlags |= MODIFYFLAG_CONTEXT_UPDATED;
      }
      return false;
   }
   if (!LTindex && PSindex) {
      // Bail out for large files that use proc-search
      if (buf_ksize > def_update_context_slow_max_ksize) {
         if (quiet) return false;
         if (!tag_check_cached_context(nUpdateFlags) || !(p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED)) {
            handleUpdateContextFailure(nUpdateFlags, "FILE IS TOO LARGE!","def_update_context_slow_max_ksize");
            p_ModifyFlags |= MODIFYFLAG_CONTEXT_UPDATED;
         }
         return false;
      }
   }
   if (buf_ksize > def_update_statements_max_ksize && (nUpdateFlags & VS_UPDATEFLAG_statement)) {
      if (quiet) return false;
      if (!tag_check_cached_context(nUpdateFlags) || !(p_ModifyFlags & MODIFYFLAG_STATEMENTS_UPDATED)) {
         handleUpdateContextFailure(nUpdateFlags, "FILE IS TOO LARGE FOR STATEMENT TAGGING!","def_update_statements_max_ksize");
         p_ModifyFlags |= MODIFYFLAG_STATEMENTS_UPDATED;
      }
      return false;
   }
   if (buf_ksize > def_update_tokenlist_max_ksize && (nUpdateFlags & VS_UPDATEFLAG_tokens)) {
      if (quiet) return false;
      if (!tag_check_cached_context(nUpdateFlags) || !(p_ModifyFlags & MODIFYFLAG_TOKENLIST_UPDATED)) {
         handleUpdateContextFailure(nUpdateFlags, "FILE IS TOO LARGE FOR UPDATING TOKEN LIST!","def_update_tokenlist_max_ksize");
         p_ModifyFlags |= MODIFYFLAG_TOKENLIST_UPDATED;
      }
      return false;
   }
   if (gcontext_files_too_large._indexin(p_buf_name)) {
      if (quiet) return false;
      if (!tag_check_cached_context(nUpdateFlags) || !(p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED)) {
         handleUpdateContextFailure(nUpdateFlags, "FILE HAS TOO MANY TAGS!","def_update_context_max_symbols");
         p_ModifyFlags |= MODIFYFLAG_CONTEXT_UPDATED;
      }
      return false;
   }
   return true;
}

bool _DidUpdateContextExceedLimits()
{
   if (tag_get_num_of_context() != 1) return false;
   tag_get_detail2(VS_TAGDETAIL_context_class, 1, auto test_class);
   if (length(test_class) > 0) return false;
   tag_get_detail2(VS_TAGDETAIL_context_name, 1, auto test_name);
   if (!pos("Context information is not generated.", test_name)) return false;
   if (!pos("Context Tagging", test_name)) return false;
   tag_get_detail2(VS_TAGDETAIL_context_line, 1, auto test_line);
   if (test_line != 1) return false;
   return true;
}

/**
 * Update the current context including statements.
 * The current object must be the active buffer
 *
 * @param AlwaysUpdate  update right away or wait for 1500 ms idle time?
 * @param ForceUpdate   force update, even for very large files
 *  
 * @see _UpdateContext 
 *  
 * @categories Tagging_Functions 
 */
void _UpdateStatements(bool AlwaysUpdate=false, bool ForceUpdate=false)
{
   _UpdateContext(AlwaysUpdate,ForceUpdate,VS_UPDATEFLAG_context|VS_UPDATEFLAG_statement);
}
/**
 * Update the current context including the token list.
 * The current object must be the active buffer.
 *
 * @param AlwaysUpdate  update right away or wait for 1500 ms idle time?
 * @param ForceUpdate   force update, even for very large files
 *  
 * @see _UpdateContext 
 *  
 * @categories Tagging_Functions 
 */
void _UpdateContextAndTokens(bool AlwaysUpdate=false, bool ForceUpdate=false)
{
   _UpdateContext(AlwaysUpdate,ForceUpdate,VS_UPDATEFLAG_context|VS_UPDATEFLAG_tokens);
}
/**
 * Update the current context (the set of symbols in the current buffer).
 * the current object must be the active buffer
 *
 * @param AlwaysUpdate  update right away or wait for 1500 ms idle time?
 * @param ForceUpdate   force update, even for very large files
 * @param nUpdateFlags  can have VS_UPDATEFLAG_statements and VS_UPDATEFLAG_contexts 
 *  
 * @categories Tagging_Functions 
 */
void _UpdateContext(bool AlwaysUpdate=false, bool ForceUpdate=false, int nUpdateFlags=VS_UPDATEFLAG_context )
{
   //say("_UpdateContext: ====================================================================================");
   //say("_UpdateContext nUpdateFlags & VS_UPDATEFLAG_context "   ( int )( nUpdateFlags & VS_UPDATEFLAG_context ) );
   //say("_UpdateContext nUpdateFlags & VS_UPDATEFLAG_statement " ( int )( nUpdateFlags & VS_UPDATEFLAG_statement ) );
   //say("_UpdateContext nUpdateFlags & VS_UPDATEFLAG_list_all "  ( int )( nUpdateFlags & VS_UPDATEFLAG_list_all ) );
   //say("_UpdateContext nUpdateFlags & VS_UPDATEFLAG_tokens "    ( int )( nUpdateFlags & VS_UPDATEFLAG_tokens ) );
   //say("_UpdateContext: Always="AlwaysUpdate" Force="ForceUpdate);

   // make sure timer has waited long enough
   int idle_timeout=(def_update_tagging_idle>1500)? def_update_tagging_idle:1500;
   if (!AlwaysUpdate && _idle_time_elapsed()<idle_timeout) {
      return;
   }

   // if this buffer is not taggable, blow out of here
   if (!_isEditorCtl()) {
      //say("_UpdateContext: NOT EDITOR");
      if (_no_child_windows()) return;
      editorctl_wid := _MDIGetActiveMDIChild();
      if (_iswindow_valid(editorctl_wid) && editorctl_wid._isEditorCtl()) {
         editorctl_wid._UpdateContext(AlwaysUpdate,ForceUpdate,nUpdateFlags);
      }
      return;
   }

   // if this buffer is not taggable, blow out of here
   if (!_istagging_supported()) {
      //say("_UpdateContext: NO TAGGING SUPPORT");
      tag_lock_context(true);
      tag_check_cached_context(VS_UPDATEFLAG_context);
      tag_clear_context();
      tag_unlock_context();
      return;
   }

   // Bail out for large files.
   if (!ForceUpdate && !_CheckUpdateContextSizeLimits(nUpdateFlags)) {
      return;
   }

   // if in embedded code, bail out of here
   if (p_embedded==VSEMBEDDED_ONLY) {
      typeless orig_values;
      _EmbeddedSave(orig_values);
      _EmbeddedEnd(p_embedded_orig_values);
      _UpdateContext2(ForceUpdate, nUpdateFlags );
      _EmbeddedRestore(orig_values);
      return;
   }
   _UpdateContext2(ForceUpdate, nUpdateFlags );
}

/**
 * For synchronization, this must be called by the main editor thread and 
 * a write lock must have been already acquired on the current context by 
 * calling tag_lock_context(true); 
 * 
 * @param fileName         fileName being updated 
 * @param taggingFlags     tagging flags (VSLTF_*)
 * @param bufferId         bufferId of file being updated
 */
int _UpdateContextAsyncInsertResults(_str fileName, int taggingFlags, 
                                     int bufferId, int lastModified)
{
   // first we open a temp view to make sure that we are updating the right buffer.
   have_temp_view := false;
   orig_wid := 0;
   temp_wid := 0;
   if (!_isEditorCtl() || 
       p_buf_id != bufferId ||
       !_file_eq(p_buf_name, fileName) ) {
      have_temp_view = true;
      status := _open_temp_view(fileName, temp_wid, orig_wid, "+bi ":+bufferId);
      if (status < 0) {
         return status;
      }
   }
   
   // check if the buffer has been modified since this async tagging job was started
   if (p_LastModified != lastModified) {
      if (have_temp_view) {
         _delete_temp_view(temp_wid);
         activate_window(orig_wid);
      }
      //say("_UpdateContextAsyncInsertResults: context was modified");
      return COMMAND_CANCELLED_RC;
   }

   // check if the context is already up to date, if so, the we should
   // just throw out this late result, it's moot.
   tag_lock_context(true);
   updateFlags := VS_UPDATEFLAG_context;
   if (taggingFlags & VSLTF_LIST_STATEMENTS) {
      updateFlags |= VS_UPDATEFLAG_statement;
   }
   have_context := tag_check_cached_context(updateFlags);
   if (taggingFlags & VSLTF_LIST_STATEMENTS) {
      if (have_context && (p_ModifyFlags & MODIFYFLAG_STATEMENTS_UPDATED)) {
         if (have_temp_view) {
            _delete_temp_view(temp_wid);
            activate_window(orig_wid);
         }
         tag_unlock_context();
         return COMMAND_CANCELLED_RC;
      }
   } else {
      if (have_context && (p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED)) {
         if (have_temp_view) {
            _delete_temp_view(temp_wid);
            activate_window(orig_wid);
         }
         tag_unlock_context();
         return COMMAND_CANCELLED_RC;
      }
   }

   // if context is being recalculated, then invalidate
   // locals, context window, statements and proctree
   if (!(taggingFlags & VSLTF_LIST_STATEMENTS)) {
      p_ModifyFlags &= ~MODIFYFLAG_LOCALS_THREADED;
      p_ModifyFlags &= ~MODIFYFLAG_LOCALS_UPDATED;
      p_ModifyFlags &= ~MODIFYFLAG_CONTEXTWIN_UPDATED;
   }

   // now we insert the symbols found by the threaded search
   //say("_UpdateContextAsyncInsertResults: inserting tags ");
   tag_insert_async_tagging_result(fileName, taggingFlags, bufferId);
   //say("_UpdateContextAsyncInsertResults: number of context="tag_get_num_of_context());

   // check if there are embedded sections to tag.
   if (tag_get_num_of_embedded(true) > 0) {
      save_pos(auto p);
      _UpdateEmbeddedContext(taggingFlags);
      restore_pos(p);
   }

   // check if this file has too many tags
   if (tag_get_num_of_context() > def_update_context_max_symbols) {
      gcontext_files_too_large:[p_buf_name] = true;
   } else {
      gcontext_files_too_large._deleteel(p_buf_name);
   }

   // sort the items in the current context by seekpos
   // this should be instant because the thread already sorted
   // its results before inserting them.
   tag_sort_context();

   // call post-processing function for update context
   AUindex := _FindLanguageCallbackIndex("_%s_after_UpdateContext");
   if (AUindex) {
      typeless p1,p2,p3,p4;
      save_search(p1,p2,p3,p4);
      call_index(AUindex);
      restore_search(p1,p2,p3,p4);
   }

   // set the modify flags, showing that the context is up to date
   // set modify flags for statements if we just updated them
   // now that the context is up-to-date, we can start updating the locals
   //say("_UpdateContextAsyncInsertResults: lastmodified="p_LastModified);
   if ( !(taggingFlags & VSLTF_LIST_STATEMENTS) ) {
      p_ModifyFlags |= MODIFYFLAG_CONTEXT_UPDATED;
      if (!(p_ModifyFlags & (MODIFYFLAG_STATEMENTS_UPDATED|MODIFYFLAG_STATEMENTS_THREADED))) {
         _UpdateStatementsAsyncForWindow();
         tag_check_cached_context(updateFlags|VS_UPDATEFLAG_test_only);
      }
   } else {
      p_ModifyFlags |= MODIFYFLAG_STATEMENTS_UPDATED;
   }

   // clean up our temp view if we had one.
   if (have_temp_view) {
      _delete_temp_view(temp_wid);
      activate_window(orig_wid);
   }

   // that's all folks
   tag_unlock_context();
   return 0;
}

int _RetagFileInsertResults(_str fileName, int taggingFlags, 
                            int bufferId, int lastModified)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //say("_RetagFileInsertResults: file="fileName);
   
   // first we open a temp view to make sure that we are updating the right buffer.
   have_temp_view := false;
   orig_wid := 0;
   temp_wid := 0;
   status   := 0;
   if (bufferId > 0) {
      have_temp_view = true;
      status = _open_temp_view(fileName, temp_wid, orig_wid, "+bi ":+bufferId);
      if (status < 0) {
         have_temp_view = false;
         bufferId = 0;
      }
   }

   // check if the buffer has been modified since this async tagging job was started
   if (have_temp_view && p_LastModified != lastModified) {
      _delete_temp_view(temp_wid);
      activate_window(orig_wid);
      return 0;
   }

   // now we look up which tag file we are expected to update
   tagDatabase := "";
   status = tag_get_async_tag_database(tagDatabase);
   if (status < 0 || tagDatabase == "") {
      if (have_temp_view) {
         _delete_temp_view(temp_wid);
         activate_window(orig_wid);
      }
      return status;
   }

   // report that we are tagging this file in the background
   //orig_message := get_message();
   //message("Retagging '"fileName"'");

   // now we insert the symbols found by the threaded search
   //say("_RetagFileInsertResults: fileName="fileName);
   status = tag_insert_async_tagging_result(fileName, taggingFlags, bufferId);

   // check if there are embedded sections to tag.
   if (!status && tag_get_num_of_embedded(true) > 0) {

      // open the tag database for exclusive write access
      status = tag_open_db(tagDatabase);
      if (status < 0) {
         //if (orig_message != "") message(orig_message);
         if (have_temp_view) {
            _delete_temp_view(temp_wid);
            activate_window(orig_wid);
         }
         return status;
      }

      // first we open a temp view to make sure that we are updating the right buffer.
      if (!have_temp_view) {
         have_temp_view = true;
         if (bufferId > 0) {
            status = _open_temp_view(fileName, temp_wid, orig_wid, "+bi ":+bufferId);
         } else {
            bufferAlreadyExists := false;
            status = _open_temp_view(fileName, temp_wid, orig_wid, "", bufferAlreadyExists, false, true);
         }
         if (status < 0) {
            have_temp_view = false;
         }
      }

      // only tag embedded regions if we successfully got a temp view for the file
      if (have_temp_view) {
         save_pos(auto p);
         _UpdateEmbeddedContext(taggingFlags);
         restore_pos(p);
      }

      // finish updating the tag database for this file
      tag_close_db(tagDatabase, true);
   }

   // update the modify flags for this buffer to reflect the change in tagging status
   if (have_temp_view) {
      if ( !(p_buf_flags&VSBUFFLAG_HIDDEN) && !(p_ModifyFlags&MODIFYFLAG_TAGGED) ) {
         p_ModifyFlags |= MODIFYFLAG_TAGGED;
      }
   }

   // clean up our temp view if we had one.
   if (have_temp_view) {
      _delete_temp_view(temp_wid);
      activate_window(orig_wid);
   }

   // that's all folks
   //if (orig_message != "") message(orig_message);
   return status;
}
void DeactivateTagBuildAlert(_str tagDatabase)
{
   if (!_haveContextTagging()) return;
   gtag_filelist_cache_updated=false;
   tagDatabaseName := _strip_filename(tagDatabase,'p');
   tag_check_async_tag_file_build(tagDatabase, auto isRunning, auto percentProgress);
   alertId := _GetBuildingTagFileAlertGroupId(tagDatabase, false, true);
   if (alertId !="") {
      if (alertId>=ALERT_TAGGING_WORKSPACE0 && alertId <=(ALERT_TAGGING_WORKSPACE:+(ALERT_TAGGING_MAX_WORKSPACES-1))) {
         _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, "Workspace tag file update has completed ("tagDatabaseName")", "", 1);
      } else if (alertId>=ALERT_TAGGING_PROJECT0 && alertId <=(ALERT_TAGGING_PROJECT:+(ALERT_TAGGING_MAX_PROJECTS-1))) {
         _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, "Project tag file update has completed ("tagDatabaseName")", "", 1);
      } else {
         _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, "Tag file update has completed ("tagDatabaseName")", "", 1);
      }
   }
}
static _str getNumJobsRemainingMessage()
{
   totalJobs := tag_get_num_async_tagging_jobs('U');
   if (totalJobs == 0) return "";
   return " ("totalJobs" remaining)";
   //totalWaiting := tag_get_num_async_tagging_jobs('W');
   //if (totalWaiting > def_background_tagging_maximum_jobs) {
   //   return " ("totalJobs" ready, "totalWaiting" waiting)";
   //} else if (totalJobs+totalWaiting > 0) {
   //   return " ("totalJobs+totalWaiting" remaining)";
   //}
   //return "";
}

void _MaybeReportAsyncTaggingResults(bool AlwaysUpdate=false)
{
   _ReportAsyncTaggingResults(AlwaysUpdate);
}

int _ReportAsyncTaggingResults(bool AlwaysUpdate=false, int progressWid=0)
{
   // Do nothing if we do not support context tagging
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // make sure timer has waited long enough
   if (!AlwaysUpdate && _idle_time_elapsed() < def_background_tagging_idle) {
      //say("_UpdateContextAsync: not enough idle time");
      return CMRC_OPERATION_CANCELLED;
   }

   // recursion guard
   static bool reportingResults;
   if (reportingResults) {
      //say("_ReportAsyncTaggingResults: HIT RECURSION GUARD");
      return CMRC_OPERATION_CANCELLED;
   }
   reportingResults = true;

   // calculate the amount of time to wait for slower jobs
   // defer slower jobs if the editor has been active
   slower_tagging_job_idle := def_background_tagging_idle*10 + 1000;
   deferSlowerJobs := (!AlwaysUpdate && _idle_time_elapsed() < slower_tagging_job_idle);

   // report tagging results which completed in the background
   sc.lang.ScopedTimeoutGuard timeout;
   if (!AlwaysUpdate) {
      _SetTimeout(def_background_tagging_timeout);
   }

   status := 0;
   taggingFlags := 0;
   bufferId := 0;
   lastModified := 0;
   fileName := "";
   lastFileName := "";
   updateFinished := 0;
   numFilesTagged := 0;
   waitTimeForResult := 0;
   startTime := (long)_time('B');
   if (!AlwaysUpdate && progressWid > 0) {
      waitTimeForResult = def_background_tagging_timeout;
   }
   
   // loop until we run out of items to process or hit timeout
   static int tagFilesUpdated:[];
   loop {

      // get the next completed result or status from the finished tagging queue
      tagDatabase := "";
      status = tag_get_async_tagging_result(fileName, taggingFlags, 
                                            bufferId, lastModified, 
                                            updateFinished, tagDatabase, 
                                            waitTimeForResult, (int)deferSlowerJobs);
      //say("_ReportAsyncTaggingResults: status="status);
      //say("_ReportAsyncTaggingResults: fileName="fileName);
      //say("_ReportAsyncTaggingResults: tagDatabase="tagDatabase);
      if (status < 0) {
         totalJobs := tag_get_num_async_tagging_jobs('U');
         currentMessage := get_message();
         messageAge := (int)get_message("-age");
         if (totalJobs <= 0 && messageAge >= 2500 &&
             (pos("Tagging", currentMessage)==1 ||
              pos("Retagging", currentMessage)==1 || 
              pos("Removing", currentMessage)==1 || 
              pos("Removed", currentMessage)==1)) {
            clear_message();
         }
         // if there were jobs before, we still need to clear the status alert
         if ( gi_PrevTotalJobs <= 0) {
            break;
         }
      }

      isRemoveFile := false;
      showProgress := false;
      alertMessage := loggingMessage := "";
      fileNamePart := "";
      parse fileName with fileNamePart "\1" .;
      switch (updateFinished) {
      case 0:
      case 1:
         if (taggingFlags & VSLTF_LIST_LOCALS) {
            if (def_tagging_logging) {
               loggingMessage = nls("Completed background update of local variables for '%s1'", fileNamePart);
            }
         } else if (taggingFlags & VSLTF_SET_TAG_CONTEXT) {
            if (def_tagging_logging) {
               loggingMessage = nls("Completed background update of current context for '%s1'", fileNamePart);
            }
         } else {
            if (def_tagging_logging) {
               loggingMessage = nls("Completed background update of '%s1' in tag file '%s2'", fileNamePart, tagDatabase);
            }
            showProgress = true;
            numFilesTagged++;
         }
         break;
      case EMBEDDED_TAGGING_NOT_SUPPORTED_RC:
         //say("_ReportAsyncTaggingResults: File requires embedded tagging: '"fileName"'");
         if (taggingFlags & VSLTF_LIST_LOCALS) {
            // do not handle this case
            if (def_tagging_logging) {
               loggingMessage = nls("Local variables are not supported for an embedded context in '%s1'", fileNamePart);
            }
            status = EMBEDDED_TAGGING_NOT_SUPPORTED_RC;
         } else if (taggingFlags & VSLTF_SET_TAG_CONTEXT) {
            if (def_tagging_logging) {
               loggingMessage = nls("Completed embedded tagging of current context for '%s1'", fileNamePart);
            }
            status = _UpdateContextAsyncInsertResults(fileNamePart, taggingFlags, bufferId, lastModified);
         } else {
            if (def_tagging_logging) {
               loggingMessage = nls("Started foreground embedded tagging of '%s1' in tag file '%s2'", fileNamePart, tagDatabase);
               dsay("BACKGROUND TAGGING: ":+loggingMessage, TAGGING_LOG);
            }
            status = _RetagFileInsertResults(fileNamePart, taggingFlags, bufferId, lastModified);
            showProgress = true;
            numFilesTagged++;
            if (def_tagging_logging) {
               loggingMessage = nls("Completed foreground embedded tagging of '%s1' in tag file '%s2'", fileNamePart, tagDatabase);
            }
         }
         break;
      case BACKGROUND_TAGGING_NOT_SUPPORTED_RC:
         //say("_ReportAsyncTaggingResults: File requires foreground tagging: '"fileName"'");
         if (!(taggingFlags & VSLTF_LIST_LOCALS) && !(taggingFlags & VSLTF_SET_TAG_CONTEXT)) {
            if (tagDatabase != "" && _haveContextTagging()) {
               if (def_tagging_logging) {
                  loggingMessage = nls("Started foreground tagging of '%s1' in tag file '%s2'", fileNamePart, tagDatabase);
                  dsay("BACKGROUND TAGGING: ":+loggingMessage, TAGGING_LOG);
               }
               status = tag_read_db(tagDatabase);
               if (status >= 0) {
                  status = RetagFile(fileName, true, bufferId, null, tagDatabase);
               }
               showProgress = true;
               numFilesTagged++;
               if (def_tagging_logging) {
                  loggingMessage = nls("Completed foreground tagging of '%s1' in tag file '%s2'", fileNamePart, tagDatabase);
               }
            }
         }
         break;
      case TAGGING_NOT_SUPPORTED_FOR_FILE_RC:
         if (def_tagging_logging) {
            loggingMessage = nls("Tagging is not supported for file '%s1'", fileNamePart);
         }
         break;
      case FILE_NOT_FOUND_RC:
      case PATH_NOT_FOUND_RC:
         if (def_tagging_logging) {
            loggingMessage = nls("File or path not found '%s1'", fileNamePart, tagDatabase);
         }
         numFilesTagged++;
         break;
      case LEFTOVER_FILE_REMOVED_FROM_DATABASE_RC:
         //alertMessage = nls("Removed leftover file '%s1' from tag file '%s2'", fileNamePart, _strip_filename(tagDatabase, 'P'));
         if (def_tagging_logging) {
            loggingMessage = nls("Removed leftover file '%s1' from tag file '%s2'", fileNamePart, tagDatabase);
         }
         numFilesTagged++;
         showProgress = true;
         isRemoveFile = true;
         break;
      case FILE_REMOVED_FROM_DATABASE_RC:
         //alertMessage = nls("Removed file '%s1' from tag file '%s2'", fileNamePart, _strip_filename(tagDatabase, 'P'));
         if (def_tagging_logging) {
            loggingMessage = nls("Removed file '%s1' from tag file '%s2'", fileNamePart, tagDatabase);
         }
         numFilesTagged++;
         showProgress = true;
         isRemoveFile = true;
         break;
      case BACKGROUND_TAGGING_IS_FINDING_FILES_RC:
         if (tagDatabase != "") {
            alertMessage = get_message(updateFinished, _strip_filename(tagDatabase, 'P'));
         }
         if (def_tagging_logging) {
            loggingMessage = get_message(updateFinished, tagDatabase);
         }
         break;
      case BACKGROUND_TAGGING_COMPLETE_RC:
         // background tagging finished for this tag file
         if (tagDatabase != "") {
            alertMessage = get_message(updateFinished, _strip_filename(tagDatabase, 'P'));
         }
         if (def_tagging_logging) {
            loggingMessage = get_message(updateFinished, tagDatabase);
         }
         // check if this tag file is still in use
         isTagFileActive := false;
         tag_files := tags_filenamea();
         foreach (auto tf in tag_files) {
            if (_file_eq(tf,tagDatabase)) isTagFileActive = true;
         }
         // close it for good if not
         if (!isTagFileActive) {
            tag_close_db(tagDatabase, false);
         }
         // deactivate the tag file build alert
         DeactivateTagBuildAlert(tagDatabase);
         if (progressWid && _iswindow_valid(progressWid)) {
            cancel_form_check_item(progressWid, tagDatabase, 100);
         }
         break;
      case BACKGROUND_TAGGING_PREEMPTED_RC:
         if (def_tagging_logging) {
            loggingMessage = nls("Background tagging cancelled for '%s1': ", fileNamePart) :+  get_message(updateFinished, fileNamePart);
         }
         break;
      case COMMAND_CANCELLED_RC:
      case CMRC_OPERATION_CANCELLED:
         if (def_tagging_logging) {
            loggingMessage = nls("Background tagging cancelled for file '%s1'", fileNamePart);
         }
         break;
      case ACCESS_DENIED_RC:
         if (_file_eq(fileName, tagDatabase)) {
            alertMessage = nls("Background tagging could not write to '%s1'", _strip_filename(tagDatabase, 'P'));
            if (def_tagging_logging) {
               loggingMessage = nls("Background tagging could not write to '%s1': ", tagDatabase, get_message(ACCESS_DENIED_RC));
            }
            DeactivateTagBuildAlert(tagDatabase);
            break;
         }
         // drop through
      default:
         alertMessage = nls("Error processing file '%s1': ", fileNamePart) :+  get_message(updateFinished, fileNamePart);
         if (def_tagging_logging) loggingMessage = alertMessage;
         //say(alertMessage);
         break;
      }

      // keep track of the tag database that is being updated.
      if (tagDatabase != "") {
         if (tagFilesUpdated._indexin(tagDatabase)) {
            tagFilesUpdated:[tagDatabase] = tagFilesUpdated:[tagDatabase] + numFilesTagged;
         } else {
            tagFilesUpdated:[tagDatabase] = numFilesTagged;
         }
      }
      
      // one single place to report debugging results.
      if (def_tagging_logging && loggingMessage != "") {
         dsay("BACKGROUND TAGGING: ":+loggingMessage, TAGGING_LOG);
      }
      //if (loggingMessage != "") {
      //   say("BACKGROUND TAGGING: ":+loggingMessage);
      //}

      // notify the user that we are updated a the tagging for a file.
      totalJobs := tag_get_num_async_tagging_jobs('A');
      if ((gi_PrevTotalJobs == 0) && (totalJobs > 0)) {
         alertId := _GetBuildingTagFileAlertGroupId(tagDatabase, false);
         if (alertId < 0) {
            _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING, "Background tagging started", "", 1);
         }
      } else if ((gi_PrevTotalJobs > 0) && (totalJobs == 0)) {
         gtag_filelist_cache_updated=false;
         _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING, "Background tagging has completed", "", 0);
         _str tagDatabaseArray[];
         tag_get_async_tag_file_builds(tagDatabaseArray);
         if (tagDatabaseArray._length() == 0) {
            for (i:=0; i<ALERT_TAGGING_MAX_WORKSPACES; i++) {
               _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING_WORKSPACE:+i, "Workspace tag file update has completed", "", 0);
            }
            for (i=0; i<ALERT_TAGGING_MAX_PROJECTS; i++) {
               _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING_PROJECT:+i, "Project tag file update has completed", "", 0);
            }
            for (i=0; i<ALERT_TAGGING_MAX_BUILDS; i++) {
               _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING_BUILD:+i, "Tag file update has completed", "", 0);
            }
         }
      }
      // now update the last job count
      gi_PrevTotalJobs = totalJobs;

      // show a message when completing tag file updates
      messageAge := (int)get_message("-age");
      if (showProgress && !progressWid && 
          def_background_tagging_rpm > 0 &&
          messageAge >= (60*1000 intdiv def_background_tagging_rpm) &&
          !(taggingFlags & VSLTF_LIST_LOCALS) && 
          !(taggingFlags & VSLTF_SET_TAG_CONTEXT) && 
          !(def_autotag_flags2 & AUTOTAG_SILENT_THREADS) && 
          fileName != "" && alertMessage == "" 
         ) {
         // sometimes command line is not initialized, so try to use status width
         // compensating by 9000 twips for the width of the status bar controls.
         cmdlineWidth := _cmdline.p_width+300 /*fudge*/;
         statusWidth  := _dx2lx(SM_TWIP, VSWID_STATUS.p_width);
         if (statusWidth > 9000 && cmdlineWidth < statusWidth-9000) {
            cmdlineWidth = statusWidth-9000;
         }
         taggingMessage := (isRemoveFile ? "Removed" : "Tagging");
         totalJobs = tag_get_num_async_tagging_jobs('U');
         taggingMessage :+= getNumJobsRemainingMessage();
         taggingMessage :+= ": ";
         labelWidth   := _cmdline._text_width(taggingMessage);
         if (cmdlineWidth < labelWidth) cmdlineWidth = labelWidth;
         alertMessage = taggingMessage :+ _cmdline._ShrinkFilename(fileNamePart, cmdlineWidth-labelWidth);
      }

      // display a message on the status line if we are not overwriting
      // anything that would otherwise be really interesting.
      // feel free to overwrite anything that is older than 30 seconds
      if (alertMessage != "" && !progressWid) {
         currentMessage := (messageAge < 30000)? get_message() : "";
         if (pos("Module", currentMessage)==1) {
            if (messageAge > 1000) message(alertMessage);
         } else if (currentMessage=="" || 
             pos("Tagging", currentMessage)==1 || 
             pos("Retagging", currentMessage)==1 || 
             pos("Removing", currentMessage)==1 || 
             pos("Removed", currentMessage)==1 || 
             pos("Finished", currentMessage)==1 || 
             pos("Updating", currentMessage)==1 || 
             pos("Background", currentMessage)==1 || 
             pos("Tag file ", currentMessage)==1 ||
             pos("The workspace tag file ", currentMessage)==1 ||
             pos("Error processing ", currentMessage)==1
            ) {
            message(alertMessage);
         }
      }

      // dispose of the tagging result, we are completely done with it now
      tag_dispose_async_tagging_result(fileName, bufferId);

      // update the progress dialog
      if (progressWid && _iswindow_valid(progressWid) && fileNamePart != "") {
         nowTime := (long)_time('B');
         if (def_background_tagging_rpm <= 0 || (nowTime-startTime) > (60*1000 intdiv def_background_tagging_rpm)) {
            startTime = nowTime;
            lastFileName = "";
            remainingMessage := getNumJobsRemainingMessage();
            cancel_form_set_labels(progressWid, 
                                   "Press Cancel to stop tagging. ":+remainingMessage,
                                   "Updating ":+fileNamePart);
         } else {
            lastFileName = fileNamePart;
         }
      }

      // if we have spent too much time updating tagging results, we should stop
      // and give it a rest, there will always be another autosave timer event.
      if (!AlwaysUpdate && (!def_background_tagging_timeout || _CheckTimeout())) {
         break;
      }

      // if a keystroke came along, break out of here
      if( _IsKeyPending() ) {
         break;
      }
   }

   // update the progress dialog to catch the last file reported
   if (progressWid && _iswindow_valid(progressWid) && lastFileName != "" && numFilesTagged > 0) {
      remainingMessage := getNumJobsRemainingMessage();
      cancel_form_set_labels(progressWid, 
                             "Press Cancel to stop tagging. ":+remainingMessage,
                             "Updating ":+lastFileName);
   }

   // report on the number of jobs processed
   if (numFilesTagged > 0 && def_tagging_logging) {
      numReadingJobs  := tag_get_num_async_tagging_jobs('L');
      numTaggingJobs  := tag_get_num_async_tagging_jobs('Q');
      numFinishedJobs := tag_get_num_async_tagging_jobs('F');
      numDatabaseJobs := tag_get_num_async_tagging_jobs('D');
      numDeferredJobs := tag_get_num_async_tagging_jobs('P');
      numWaitingJobs  := tag_get_num_async_tagging_jobs('W');
      loggingMessage :=  "completed="numFilesTagged :+
                         ", to read="numReadingJobs :+
                         ", to parse="numTaggingJobs :+
                         ", to tag="numDatabaseJobs :+
                         ", to complete="numFinishedJobs :+
                         ", deferred="numDeferredJobs :+
                         ", waiting="numWaitingJobs;
      dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      //say(_time('M'):+": ":+loggingMessage);
   }

   // If tag files were upated, update tool windows.
   if (tagFilesUpdated._length() && progressWid==0 &&
       tag_get_num_async_tagging_jobs('A') <= 0) {

      // send the tag file update callbacks
      numTagFilesModified := 0;
      tagDatabase := "";
      foreach (tagDatabase => numFilesTagged in tagFilesUpdated) {
         if (numFilesTagged > 0) {
            _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,tagDatabase);
            numTagFilesModified++;
         }
      }
      if (numTagFilesModified > 0) {
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      }
      tagFilesUpdated._makeempty();

      // make sure that all the alerts are deactivated at this point
      gtag_filelist_cache_updated=false;
      _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING, "Background tagging has completed", "", 0);
      _str tagDatabaseArray[];
      tag_get_async_tag_file_builds(tagDatabaseArray);
      if (tagDatabaseArray._length() == 0) {
         for (i:=0; i<ALERT_TAGGING_MAX_WORKSPACES; i++) {
            _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING_WORKSPACE:+i, "Workspace tag file update has completed", "", 0);
         }
         for (i=0; i<ALERT_TAGGING_MAX_PROJECTS; i++) {
            _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING_PROJECT:+i, "Project tag file update has completed", "", 0);
         }
         for (i=0; i<ALERT_TAGGING_MAX_BUILDS; i++) {
            _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING_BUILD:+i, "Tag file update has completed", "", 0);
         }
      }
   }

   // cancel recursion guard
   reportingResults = false;
   return 0;
}

_command void finish_background_tagging() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) return;
   _MaybeRetryTaggingWhenFinished(false);
}

bool _MaybeRetryTaggingWhenFinished(bool quiet=false, _str caption="", bool doRefreshTagFiles=true)
{
   totalJobs := tag_get_num_async_tagging_jobs('U');
   if (totalJobs <= 0) {
      return false;
   }

   if (caption == "") {
      caption = "Finishing background tagging jobs";
   }

   // force the main thread to relinquish any locks it has on any databases
   // this way the other threads can do whatever they want immediately.
   tag_close_all_db();

   // keep track of how long we have been processing jobs
   startTime := (long) _time('b');
   progressWid := 0;
   focus_wid := _get_focus();

   wasCancelled := false;
   while (tag_get_num_async_tagging_jobs('U') > 0) {

      if (!quiet && progressWid && cancel_form_cancelled(0)) {
         wasCancelled = true;
         break;
      }
      if (quiet && _IsKeyPending()) {
         wasCancelled = true;
         break;
      }
      if (_ReportAsyncTaggingResults(true, progressWid) < 0) {
         wasCancelled = true;
         break;
      }
      remainingJobs := tag_get_num_async_tagging_jobs('U');
      if (remainingJobs <= 0) {
         break;
      }
      numFinishedJobs := tag_get_num_async_tagging_jobs('F');
      if (numFinishedJobs <= def_background_tagging_maximum_jobs intdiv 10) {
         // before sleeping, make sure we unlock any read-locks we have
         // on the current context so that threads can finish what they are doing
         // if they need to write to the context.
         lockCount := 0;
         while (tag_unlock_context() == 0) {
            ++lockCount;
         }
         if (numFinishedJobs <= 10) {
            delay(def_background_tagging_idle intdiv 10);
         } else {
            delay(def_background_tagging_idle intdiv 100);
         }
         // now re-acquire the same number of read locks we had before
         while (lockCount > 0) {
            tag_lock_context();
            --lockCount;
         }
      }
      if (!quiet && progressWid && _iswindow_valid(progressWid)) {
         remainingJobs = tag_get_num_async_tagging_jobs('U');
         if (remainingJobs > totalJobs) totalJobs = remainingJobs;
         cancel_form_progress(progressWid, totalJobs - remainingJobs, totalJobs);
      }

      // this is taking a while, so let's display the progress dialog
      if (!quiet && !progressWid) {
         currentTime := (long)_time('b');
         currentJobs := (long)tag_get_num_async_tagging_jobs('U');
         if (currentTime - startTime > def_background_tagging_idle && currentJobs > totalJobs intdiv 2) {
            progressWid = show_cancel_form(caption, null, true, true);
         }
      }
   }

   // close the cancel form
   if (!quiet && progressWid && _iswindow_valid(progressWid)) {
      close_cancel_form(progressWid);
      progressWid = 0;
   }

   // restore focus to original window
   if (focus_wid && _iswindow_valid(focus_wid) && focus_wid != _get_focus()) {
      focus_wid._set_focus();
   }

   // If tag files were upated, update tool windows. 
   if (doRefreshTagFiles) {
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }

   return !wasCancelled;
}

void _exit_FinishAsyncTagging()
{
   if (!_haveContextTagging()) return;
   _exit_SymbolsToolWindow();
   _MaybeRetryTaggingWhenFinished(false,"",false);
}

static void _UpdateContextAsyncForWindow(bool AlwaysUpdate=false)
{
   // if this buffer is not taggable, blow out of here
   if (!_isEditorCtl()) {
      //say("_UpdateContextAsync:  Not an editor control");
      return;
   }

   // make sure timer has waited long enough
   if (!AlwaysUpdate && _idle_time_elapsed() < (def_background_tagging_idle intdiv 10)) {
      //say("_UpdateContextAsync: not enough idle time");
      return;
   }

   // if we have already started a thread for this buffer, don't start another
   if (p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED) {
      //say("_UpdateContextAsync: context already up to date");

      // we have the context, do we have statements and tokens ready?
      if (!(p_ModifyFlags & MODIFYFLAG_STATEMENTS_UPDATED)) {
         have_statements := tag_check_cached_context(VS_UPDATEFLAG_context|VS_UPDATEFLAG_statement|VS_UPDATEFLAG_test_only);
         if ( have_statements ) {
            if (AlwaysUpdate || _idle_time_elapsed() > def_background_tagging_idle) {
               _UpdateContext2(false, VS_UPDATEFLAG_context|VS_UPDATEFLAG_statement);
            }
         }
      } else if (!(p_ModifyFlags & MODIFYFLAG_STATEMENTS_UPDATED) && _is_tokenlist_supported()) {
         have_tokenlist := tag_check_cached_context(VS_UPDATEFLAG_context|VS_UPDATEFLAG_tokens|VS_UPDATEFLAG_test_only);
         if ( have_tokenlist ) {
            if (AlwaysUpdate || _idle_time_elapsed() > def_background_tagging_idle) {
               _UpdateContext2(false, VS_UPDATEFLAG_context|VS_UPDATEFLAG_tokens);
            }
         }
      }
      // nothing more to do
      return;
   }

   // if we have already started a thread for this buffer, don't start another
   if (p_ModifyFlags & MODIFYFLAG_CONTEXT_THREADED) {
      //say("_UpdateContextAsync: thread was already started");
      return;
   }

   // verify that we have a list tags function for this language
   LTindex := _FindLanguageCallbackIndex("vs%s-list-tags");
   if (LTindex <= 0) {
      //say("_UpdateContextAsync:  no list tags function");
      return;
   }

   // do nothing if this language doesn't support asynchrounous taggingFlags
   if (!_is_background_tagging_supported()) {
      //say("_UpdateContextAsync:  no background tagging support for language");
      return;
   }

   // bail out for large files.
   if (p_buf_size > def_update_context_max_ksize*1024) {
      //say("_UpdateContextAsync: buffer too large");
      return;
   }
   if (gcontext_files_too_large._indexin(p_buf_name)) {
      //say("_UpdateContextAsync: too many symbols");
      return;
   }

   // check current buffer position against context
   // rely on this function's synchronization since nothing else here depends
   // on the contents of the current context.
   have_context := tag_check_cached_context(VS_UPDATEFLAG_context|VS_UPDATEFLAG_test_only);
   if ( have_context ) {
      //say("_UpdateContextAsync: Already have current context tagged");
      // make sure timer has waited long enough
      if (!AlwaysUpdate && _idle_time_elapsed() < def_background_tagging_idle) {
         return;
      }
      _UpdateContext2(false, VS_UPDATEFLAG_context);
      return;
   }

   // set up tagging flags to read from the editor and then parse in the background
   taggingFlags := (VSLTF_SET_TAG_CONTEXT|VSLTF_ASYNCHRONOUS|VSLTF_READ_FROM_EDITOR); 

   // check if there is already a job running for this buffer
   // cancel the job if the buffer is already out of date
   status := tag_get_async_tagging_job(p_buf_name, 
                                       taggingFlags, 
                                       p_buf_id, 
                                       p_file_date, 
                                       p_LastModified,
                                       null, 1, 0, 0);
   if (!status) {
      //say("_UpdateContextAsync: no job");
      return;
   }

   // Update if we are forced to update or we do not have a current context
   // Also update if the context is not up to date or we are going to list statements
   // and the statements are not up to date
   //say("_UpdateContextAsync: starting async buffer tagging job, p_lastmodify="p_LastModified);
   call_index(0, "", p_LangId, taggingFlags, LTindex);
   p_ModifyFlags |= MODIFYFLAG_CONTEXT_THREADED;
}

/**
 * Start an asynchronous job to update the current context.
 * 
 * @param AlwaysUpdate 
 */
void _UpdateContextAsync(bool AlwaysUpdate=false)
{
   if (_isEditorCtl(AlwaysUpdate)) {
      _UpdateContextAsyncForWindow(AlwaysUpdate);
   } else if (!_no_child_windows()) {
      _mdi.p_child._UpdateContextAsyncForWindow(AlwaysUpdate);
   }
}

static void _UpdateStatementsAsyncForWindow(bool AlwaysUpdate=false)
{
   // if this buffer is not taggable, blow out of here
   if (!_isEditorCtl()) {
      //say("_UpdateStatementsAsync:  Not an editor control");
      return;
   }

   // make sure timer has waited long enough
   if (!AlwaysUpdate && _idle_time_elapsed() < (def_background_tagging_idle intdiv 10)) {
      //say("_UpdateStatementsAsync: not enough idle time");
      return;
   }

   // if we have already started a thread for this buffer, don't start another
   if (p_ModifyFlags & MODIFYFLAG_STATEMENTS_THREADED) {
      //say("_UpdateStatementsAsync: thread was already started");
      return;
   }

   // if we have already started a thread for this buffer, don't start another
   if (p_ModifyFlags & MODIFYFLAG_STATEMENTS_UPDATED) {
      //say("_UpdateContextAsync: statements already up to date");
      return;
   }

   // verify that we have a list tags function for this language
   LTindex := _FindLanguageCallbackIndex("vs%s-list-tags");
   if (LTindex <= 0) {
      //say("_UpdateStatementsAsync:  no list tags function");
      return;
   }

   // do nothing if this language doesn't support asynchrounous taggingFlags
   if (!_is_background_tagging_supported()) {
      //say("_UpdateStatementsAsync:  no background tagging support for language");
      return;
   }

   // check if statement tagging is supported, if so use statement tagging mode
   SSindex := _FindLanguageCallbackIndex("%s_are_statements_supported");
   if (SSindex <= 0 || !call_index(SSindex)) {
      //say("_UpdateStatementsAsync: statement tagging not supported for language");
      return;
   }

   // bail out for large files.
   if (p_buf_size > def_update_context_max_ksize*1024) {
      //say("_UpdateStatementsAsync: buffer too large");
      return;
   }
   if (p_buf_size > def_update_statements_max_ksize*1024) {
      //say("_UpdateStatementsAsync: buffer too large");
      return;
   }
   if (gcontext_files_too_large._indexin(p_buf_name)) {
      return;
   }

   // check current buffer position against context
   // rely on this function's synchronization since nothing else here depends
   // on the contents of the current context.
   have_context := tag_check_cached_context(VS_UPDATEFLAG_context|VS_UPDATEFLAG_statement|VS_UPDATEFLAG_test_only);
   if ( have_context ) {
      //say("_UpdateStatementsAsync: statements already are up to date");
      return;
   }

   // set up tagging flags to read from the editor and then parse in the background
   taggingFlags := (VSLTF_SET_TAG_CONTEXT|VSLTF_ASYNCHRONOUS|VSLTF_READ_FROM_EDITOR|VSLTF_LIST_STATEMENTS); 

   // check if there is already a job running for this buffer
   // cancel the job if the buffer is already out of date
   status := tag_get_async_tagging_job(p_buf_name, 
                                       taggingFlags, 
                                       p_buf_id, 
                                       p_file_date, 
                                       p_LastModified,
                                       null, 1, 0, 0);
   if (!status) {
      //say("_UpdateStatementsAsync: no job");
      return;
   }

   // Update if we are forced to update or we do not have a current context
   // Also update if the context is not up to date or we are going to list statements
   // and the statements are not up to date
   //say("_UpdateStatementsAsync: starting async statement tagging job, p_lastmodify="p_LastModified);
   call_index(0, "", p_LangId, taggingFlags, LTindex);
   p_ModifyFlags |= MODIFYFLAG_STATEMENTS_THREADED;
}

/**
 * Start an asynchronous job to update the current statements.
 * 
 * @param AlwaysUpdate 
 */
void _UpdateStatementsAsync(bool AlwaysUpdate=false)
{
   if (_isEditorCtl(AlwaysUpdate)) {
      _UpdateStatementsAsyncForWindow(AlwaysUpdate);
   } else if (!_no_child_windows()) {
      _mdi.p_child._UpdateStatementsAsyncForWindow(AlwaysUpdate);
   }
}

/**
 * Start an asynchronous job to update local variables.
 * 
 * @param AlwaysUpdate 
 *  
 * @deprecated This is done automatically when the current context is updated. 
 */
void _UpdateLocalsAsync(bool AlwaysUpdate=false)
{
   return;
}

//////////////////////////////////////////////////////////////////////////////

void _UpdateEmbeddedContext(int taggingFlags, bool ForceUpdate=true) 
{
   // bump up the max string size parameter to match the buffer size
   _str orig_max = _default_option(VSOPTION_WARNING_STRING_LENGTH);
   if ( p_RBufSize*3+1024 > orig_max ) {
      _default_option(VSOPTION_WARNING_STRING_LENGTH, p_RBufSize*3+1024);
   }

   // collate all the embedded sections into string buffers
   // NOTE:  It would be more effecient to do this using a set of
   //        views instead of strings.
   gdo_search := false;
   _str ext_embedded_buffer_data:[] = null;
   int ext_embedded_buffer_data_length:[] = null; // length in characters, not bytes as length() returns
   status := 0;

   CollateEmbeddedSections(ext_embedded_buffer_data, ext_embedded_buffer_data_length, gdo_search);

   // for each item in the hash table, run list-tags
   typeless ext;

   for ( ext._makeempty();; ) {
      ext_embedded_buffer_data._nextel(ext);
      if ( ext._isempty() ) {
         break;
      }

      SSindex_embedded := _FindLanguageCallbackIndex("%s_are_statements_supported",ext);

      int ltf_flags_embedded = taggingFlags|VSLTF_READ_FROM_STRING;
      if ( (taggingFlags & VSLTF_LIST_STATEMENTS) && call_index(0, "", p_LangId, 0, SSindex_embedded ) ) {
         ltf_flags_embedded |= VSLTF_LIST_STATEMENTS;
      }

      // look up the list-tags function and call it on the fake buffer
      LTindex := _FindLanguageCallbackIndex("vs%s-list-tags",ext);
      _str fake_buffer = ext_embedded_buffer_data:[ext];
      status = call_index(0, "", fake_buffer,
                          ltf_flags_embedded,
                          0,0,0,length(fake_buffer),
                          LTindex);
   }

   // fall back to conventional list-tags methods
   if ( gdo_search ) {
      typeless p1,p2,p3,p4;
      save_search(p1,p2,p3,p4);
      top();
      proc_name := "";

      // set up timeout if not forcing update
      sc.lang.ScopedTimeoutGuard timeout;
      if (!ForceUpdate) {
         _SetTimeout(def_update_context_max_time);
      }

      findfirst := 1;
      context_id := 0;
      num_symbols := 0;
      for ( ;; ) {
         //say("_UpdateContext");
         proc_name="";
         status=_EmbeddedProcSearch(0,proc_name,findfirst,p_LangId);
         //say("_UpdateContext: PS time="(int)_time('b')-orig_time);
         start_line_no := p_RLine;
         start_seekpos := (int)_QROffset();
         end_line_no := 0;
         end_seekpos := 0;
         //say("proc_name="proc_name" line_no="start_line_no" status="status);
         if ( context_id > 0 ) {
            typeless context_pos;
            save_pos(context_pos);
            if ( status ) {
               bottom();
            } else {
               _GoToROffset(start_seekpos-1);
            }
            _clex_find(~COMMENT_CLEXFLAG,'-O');
            right();
            end_line_no = p_RLine;
            end_seekpos = (int)_QROffset();
            _GoToROffset(start_seekpos);
            tag_end_context(context_id, end_line_no, end_seekpos);
            restore_pos(context_pos);
         }
         if ( status ) {
            break;
         }
         if ( proc_name != "" ) {
            tag_decompose_tag_browse_info(proc_name, auto cm);
            if (cm.member_name != "") {
               cm.file_name = p_buf_name;
               cm.line_no = start_line_no;
               cm.seekpos = start_seekpos;
               cm.scope_line_no = start_line_no;
               cm.scope_seekpos = start_seekpos;
               cm.end_line_no = end_line_no;
               cm.end_seekpos = end_seekpos;
               if (taggingFlags & VSLTF_SET_TAG_CONTEXT) {
                  context_id = tag_insert_context_browse_info(0, cm);
                  if (!ForceUpdate && ++num_symbols > def_update_context_max_symbols) break;
                  if (!ForceUpdate && _CheckTimeout()) break;
               } else {
                  tag_insert_tag_browse_info(cm);
               }
            }
         }
         findfirst=0;
      }
      restore_search(p1,p2,p3,p4);
   }

   // restore the max string size parameter
   _default_option(VSOPTION_WARNING_STRING_LENGTH, orig_max);
}

static int _UpdateContext3(bool ForceUpdate, int nUpdateFlags )
{
   //say("_UpdateContext3 H"__LINE__": buffer="p_buf_name);
   //_StackDump();

   // if context is being recalculated, then invalidate
   // locals, context window, statements and proctree
   if (!(nUpdateFlags & VS_UPDATEFLAG_statement) &&
       !(nUpdateFlags & VS_UPDATEFLAG_tokens)) {
      p_ModifyFlags &= ~MODIFYFLAG_LOCALS_UPDATED;
      p_ModifyFlags &= ~MODIFYFLAG_LOCALS_THREADED;
      p_ModifyFlags &= ~MODIFYFLAG_CONTEXTWIN_UPDATED;
      //p_ModifyFlags &= ~MODIFYFLAG_PROCTREE_UPDATED;
      //p_ModifyFlags &= ~MODIFYFLAG_FCTHELP_UPDATED;
   }

   // start time for updating the list of tags in the current context
   start_time := (long) _time('b');

   // find extension specific tagging functions
   LTindex := _FindLanguageCallbackIndex("vs%s-list-tags");
   PSindex := _FindLanguageCallbackIndex("%s-proc-search");

   ranOutOfTimeInPS := false;
   outer_context := dummy_context := 0;
   start_line_no := start_seekpos := 0;
   scope_line_no := scope_seekpos := 0;
   end_line_no   := end_seekpos   := 0;
   proc_name := signature := return_type := "";
   tag_name := type_name := class_name := file_name := "";
   tag_flags := 0;
   status := 0;
   ltf_flags := VSLTF_SET_TAG_CONTEXT;

   if (LTindex) {
      // call list-tags with LTF_SET_TAG_CONTEXT flags
      // might want to update proctree at same time

      SSindex := _FindLanguageCallbackIndex("%s_are_statements_supported");
      if ( ( nUpdateFlags & VS_UPDATEFLAG_statement ) && SSindex && call_index(0, "", p_LangId, 0, SSindex ) ) {
         ltf_flags |= VSLTF_LIST_STATEMENTS;
      }

      TKindex := _FindLanguageCallbackIndex("%s_is_tokenlist_supported");
      if ( ( nUpdateFlags & VS_UPDATEFLAG_tokens ) && TKindex != 0 && call_index(0, "", p_LangId, 0, TKindex ) ) {
         ltf_flags |= VSLTF_SAVE_TOKENLIST;
      }
      if (_GetCodehelpFlags() & VSCODEHELPFLAG_NO_COMMENT_TAGGING) {
         ltf_flags |= VSLTF_NO_SAVE_COMMENTS;
      }

      INCindex := _FindLanguageCallbackIndex("%s_is_incremental_supported");
      if ( false && TKindex != 0 && INCindex != 0 && call_index(0, "", p_LangId, 0, INCindex ) ) {
         nUpdateFlags |= VS_UPDATEFLAG_tokens;
      }

      origTime := _time('b');
      if (false && TKindex != 0 && INCindex != 0 && 
          !(ltf_flags & VSLTF_ASYNCHRONOUS) &&
          (ltf_flags & VSLTF_SAVE_TOKENLIST)) {
         status = tag_update_context_incrementally(auto start_offset, auto end_offset);
         if (status == 0) {

            // set the modify flags, showing that the context is up to date
            p_ModifyFlags |= MODIFYFLAG_CONTEXT_UPDATED;
            // set modify flags for statements if we just updated them
            if( nUpdateFlags & VS_UPDATEFLAG_statement ) {
               p_ModifyFlags |= MODIFYFLAG_STATEMENTS_UPDATED;
            } else if( nUpdateFlags & VS_UPDATEFLAG_tokens ) {
               p_ModifyFlags |= MODIFYFLAG_TOKENLIST_UPDATED;
            }
            //if (!(ltf_flags & VSLTF_ASYNCHRONOUS) && (pos("tagscntx",p_buf_name) > 0)) {
            //   say("_UpdateContext: INCREMENTAL start="start_offset" end="end_offset);
            //   say("_UpdateContext: INCREMENTAL time="(long)_time('b')-(long)origTime" mod="p_LastModified" statements="((ltf_flags & VSLTF_LIST_STATEMENTS)? "on":"off")" tokens="((ltf_flags & VSLTF_SAVE_TOKENLIST)? "on":"off"));
            //}

            // incremental tagging success
            return 0;
         }
      }

      save_pos(auto p);
      //say("_UpdateContext3: RETAGGING CONTEXT, file="p_buf_name);
      //say("_UpdateContext3: modify flags before update = "dec2hex(p_ModifyFlags));
      //tag_clear_context(p_buf_name, true);
      //tag_clear_embedded();
      status = call_index(0, "", p_LangId, ltf_flags, LTindex);
//       if (!(ltf_flags & VSLTF_ASYNCHRONOUS) && (pos("tagscntx",p_buf_name) > 0)) {
//          say("_UpdateContext: LT time="(long)_time('b')-(long)origTime" mod="p_LastModified" statements="((ltf_flags & VSLTF_LIST_STATEMENTS)? "on":"off")" tokens="((ltf_flags & VSLTF_SAVE_TOKENLIST)? "on":"off"));
//       }
      // now do embedded proc search
      //finalTime := _time('b');
      //if (file_eq(p_buf_name,  'E:\15.0.0-svn\slickedit\rt\slick\gui.cpp') && (ltf_flags & VSLTF_LIST_STATEMENTS) != 0) {
      //   say("_UpdateContext3: elapsed="(int)finalTime-(int)origTime);
      //}
      //say("_UpdateContext3: modify flags after update = "dec2hex(p_ModifyFlags));
      //say("_UpdateContext3: num tags after update = "tag_get_num_of_context());

      // If the list-tags function is disabled for this verions, then
      // try to fall back on a proc-search.
      if (status == VSRC_FEATURE_REQUIRES_PRO_EDITION) {
         LTindex = 0;
      }

      if (tag_get_num_of_embedded(true) > 0) {
         _UpdateEmbeddedContext(ltf_flags, ForceUpdate);
      }
      // restore position and we are done
      restore_pos(p);

   }

   if (LTindex <= 0 && index_callable(PSindex)) {
      // call proc-search to find current context
      //say("_UpdateContext3: PROC SEARCH");
      //tag_clear_context(p_buf_name);
      sc.lang.ScopedTimeoutGuard timeout;
      if (!ForceUpdate) {
         _SetTimeout(def_update_context_max_time);
      }

      //say("_UpdateContext3: parsing using proc-search, buffer="p_buf_name);
      typeless p,p1,p2,p3,p4;
      save_pos(p);
      save_search(p1,p2,p3,p4);
      top();
      proc_name = "";
      findfirst := 1;
      context_id := 0;
      num_symbols := 0;
      for (;;) {
         //say("_UpdateContext");
         proc_name="";
         if (ForceUpdate || p_buf_size <= def_update_context_slow_max_ksize*1024) {
            status=call_index(proc_name,findfirst,p_LangId,PSindex);
         } else {
            status=1;
         }
         start_line_no = p_RLine;
         start_seekpos = (int)_QROffset();
         //say("proc_name="proc_name" line_no="start_line_no);
         if (context_id > 0) {
            typeless context_pos;
            save_pos(context_pos);
            if (status) {
               bottom();
            } else {
               _GoToROffset(start_seekpos-1);
            }
            _clex_find(~COMMENT_CLEXFLAG,'-O');
            right();
            end_line_no = p_RLine;
            end_seekpos = (int)_QROffset();
            _GoToROffset(start_seekpos);
            tag_end_context(context_id, end_line_no, end_seekpos);
            restore_pos(context_pos);
         }
         if (status) {
            break;
         }
         if (proc_name != "") {
            tag_decompose_tag_browse_info(proc_name, auto cm);
            if (cm.member_name != "") {
               cm.file_name = p_buf_name;
               cm.line_no = start_line_no;
               cm.seekpos = start_seekpos;
               cm.scope_line_no = start_line_no;
               cm.scope_seekpos = start_seekpos;
               cm.end_line_no = end_line_no;
               cm.end_seekpos = end_seekpos;
               context_id = tag_insert_context_browse_info(0,cm);
            }
         }

         // stop if we found too many symbols in this file
         if (!ForceUpdate && ++num_symbols > def_update_context_max_symbols) break;
         if (!ForceUpdate && _CheckTimeout()) {
            ranOutOfTimeInPS = true;
            break;
         }
         findfirst=0;
      }
      restore_search(p1,p2,p3,p4);
      restore_pos(p);
   }

   // dump out buffer variable information
   //say("_UpdateContext: "tag_get_num_of_context()" tags");
   //for (j:=1; j<=tag_get_num_of_context(); j++) {
   //   tag_get_detail2(VS_TAGDETAIL_context_parents, j, auto class_parents);
   //   tag_get_detail2(VS_TAGDETAIL_context_class, j, class_name);
   //   tag_get_detail2(VS_TAGDETAIL_context_name, j, proc_name);
   //   tag_get_detail2(VS_TAGDETAIL_context_type, j, type_name);
   //   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, j, start_seekpos);
   //   tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, j, end_seekpos);
   //   tag_get_detail2(VS_TAGDETAIL_context_outer, j, outer_context);
   //   say("   CTX: j="j" name="proc_name" type="type_name" class="class_name" parents="class_parents" start="start_seekpos" end="end_seekpos" outer="outer_context);
   //}

   // check if this file has too many tags
   if (!ForceUpdate && tag_get_num_of_context() > def_update_context_max_symbols) {
      gcontext_files_too_large:[p_buf_name] = true;
      handleUpdateContextFailure(nUpdateFlags, "FILE HAS TOO MANY TAGS!","def_update_context_max_symbols");
      p_ModifyFlags &= ~MODIFYFLAG_CONTEXT_UPDATED;
      p_ModifyFlags &= ~MODIFYFLAG_STATEMENTS_UPDATED;
      return -1;
   } else if (!ForceUpdate && ranOutOfTimeInPS) {
      gcontext_files_too_large:[p_buf_name] = true;
      handleUpdateContextFailure(nUpdateFlags, "TAG SEARCH TOOK TOO LONG!","def_update_context_max_time");
      p_ModifyFlags &= ~MODIFYFLAG_CONTEXT_UPDATED;
      p_ModifyFlags &= ~MODIFYFLAG_STATEMENTS_UPDATED;
      return -1;
   } else {
      gcontext_files_too_large._deleteel(p_buf_name);
   }

   // sort the items in the current context by seekpos
   tag_sort_context();

   // call post-processing function for update context
   AUindex := _FindLanguageCallbackIndex("_%s_after_UpdateContext");
   if (AUindex) {
      typeless p1,p2,p3,p4;
      save_search(p1,p2,p3,p4);
      call_index(AUindex);
      restore_search(p1,p2,p3,p4);
   }

   // keep track of how long this takes
   end_time := (long) _time('b');
   elapsed_time := (end_time - start_time);
   update_context_add_stats(p_buf_name, 
                            p_LangId, 
                            p_file_size, 
                            tag_get_num_of_context(), 
                            elapsed_time, 
                            ltf_flags);

   // success
   return 0;
}

/**
 * Update the current context and context tree message
 * the current object must be the active buffer
 *
 * @param ForceUpdate  force update not matter how big the file
 */
static void _UpdateContext2(bool ForceUpdate, int nUpdateFlags )
{
#if 1
   // lock the current context so that only this thread can update it
   tag_lock_context(true);

   // check current buffer position against context
   if (nUpdateFlags & VS_UPDATEFLAG_statement) {
      nUpdateFlags |= VS_UPDATEFLAG_context;
   }
   if ((nUpdateFlags & VS_UPDATEFLAG_statement) && _is_tokenlist_supported()) {
      nUpdateFlags |= VS_UPDATEFLAG_tokens;
   }
   have_context := tag_check_cached_context(nUpdateFlags);
   //say("_UpdateContext2: have_context="have_context " filename="p_buf_name);
   if (have_context) {
      if ((nUpdateFlags & VS_UPDATEFLAG_statement) && !(p_ModifyFlags & MODIFYFLAG_STATEMENTS_UPDATED)) {
         //say("_UpdateContext2: modify flags not set for statements");
         have_context = 0;
      } else if ((nUpdateFlags & VS_UPDATEFLAG_tokens) && !(p_ModifyFlags & MODIFYFLAG_TOKENLIST_UPDATED)) {
         //say("_UpdateContext2: modify flags not set for tokens");
         have_context = 0;
      } else if (!(nUpdateFlags & VS_UPDATEFLAG_statement) && !(p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED)) {
         //say("_UpdateContext2: modify flags not set for context");
         have_context = 0;
      }
      if (ForceUpdate && _DidUpdateContextExceedLimits()) {
         //say("_UpdateContext2: forcing update despite size constraints");
         have_context = 0;
      }
   }

   // Update if we are forced to update or we do not have a current context
   // Also update if the context is not up to date or we are going to list statements
   // and the statements are not up to date
   //say("_UpdateContext2: ForceUpdate="ForceUpdate" have_context="have_context" file_date="p_file_date" last_modified="p_LastModified" buffer="p_buf_name" num_symbols="tag_get_num_of_context()" flags="nUpdateFlags);
   if ( !have_context ) {

      //if (p_buf_name != "") {
      //   say("_UpdateContext2: updateflags = "nUpdateFlags);
      //   say("_UpdateContext:  Recalculating context="have_context" modify=":+(p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED) " file="p_buf_name);
      //   _StackDump(); 
      //}

      status := _UpdateContext3(ForceUpdate,nUpdateFlags);
      if (status) {
         //say("_UpdateContext2["__LINE__"]: status="status);
         tag_unlock_context();
         return;
      }

      // make sure parsing is marked as finished
      tag_commit_cached_context(nUpdateFlags);
   }

   // set the modify flags, showing that the context is up to date
   p_ModifyFlags |= MODIFYFLAG_CONTEXT_UPDATED;

   // set modify flags for statements if we just updated them
   if( nUpdateFlags & VS_UPDATEFLAG_statement ) {
      p_ModifyFlags |= MODIFYFLAG_STATEMENTS_UPDATED;
   }
   if( nUpdateFlags & VS_UPDATEFLAG_tokens ) {
      p_ModifyFlags |= MODIFYFLAG_TOKENLIST_UPDATED;
   }

   // unlock the current context so that other threads may now read it
   tag_unlock_context();

#else
   tag_update_context();
#endif
}

static void _SaveLocalVariables(bool (&outer_hash):[], 
                                VS_TAG_BROWSE_INFO (&outer_locals)[])
{
   // save/append the current locals to the array
   n := tag_get_num_of_locals();
   for (i:=1; i<=n; i++) {
      tag_get_local_browse_info(i, auto cm);
      if (!outer_hash._indexin(cm.member_name";"cm.seekpos)) {
         outer_locals[outer_locals._length()] = cm;
         outer_hash:[cm.member_name";"cm.seekpos]=true;
      }
      //say("Cgot "cm.member_name);
   }
}
static void _RestoreLocalVariables(VS_TAG_BROWSE_INFO (&outer_locals)[])
{
   // append locals from inner functions
   n := outer_locals._length();
   for (i:=0; i<n; i++) {
      tag_insert_local_browse_info(outer_locals[i]);
   }
}

static long find_start_of_spaces_before(long seekpos)
{
   save_pos(auto p);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   _GoToROffset(seekpos);
   left();
   if (!search("\\om[~ \\t]", "-r@")) {
      if (!search("[ \t]", "r@")) {
         new_seekpos := _QROffset();
         if (new_seekpos < seekpos) {
            seekpos = new_seekpos;
         }
      }
   }
   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);
   return seekpos;
}

/**
 * Update the list of local variables in the current function.
 * Current object must be the current buffer.
 *
 * @param AlwaysUpdate  update right away (ignored)?
 * @param list_all      list all locals, or only those visible in context?
 */
void _UpdateLocals(bool AlwaysUpdate=false, bool list_all=true)
{
   // if this buffer is not taggable, blow out of here
   //say("_UpdateLocals: =========================================================");
   //say("_UpdateLocals("AlwaysUpdate","list_all")");
   if (!_isEditorCtl()) {
      //say("NOT AN EDITOR CONTROL!");
      return;
   }

   // make sure timer has waited long enough
   if (!AlwaysUpdate && _idle_time_elapsed() < def_update_tagging_idle) {
      return;
   }

   // update the context
   int orig_time=(int)_time('b');
   tag_lock_context(true);
   _UpdateContext(true);


   // if there are no symbols in the context, then we should give up right away
   if (tag_get_num_of_context() <= 0) {
      //say("_UpdateLocals H"__LINE__": NO SYMBOLS IN CONTEXT");
      tag_unlock_context();
      return;
   }

   // is the current context defined?
   context_id := tag_current_context();
   cur_type_name     := "";
   cur_start_line_no := 1;
   cur_start_seekpos := 0;
   cur_end_line_no   := 0;
   cur_end_seekpos   := 0;
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, cur_start_line_no);
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, cur_start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_context_end_linenum,   context_id, cur_end_line_no);
      tag_get_detail2(VS_TAGDETAIL_context_end_seekpos,   context_id, cur_end_seekpos);
      tag_get_detail2(VS_TAGDETAIL_context_type,          context_id, cur_type_name);
   } else {
      //say("_UpdateLocals H"__LINE__": NO CURRENT CONTEXT");
      tag_unlock_context();
      return;
   }
   //say("_UpdateLocals: start="cur_start_seekpos" end="cur_end_seekpos);

   // end seekpos is position of cursor or end of function
   end_seekpos := cur_end_seekpos; 
   if (!list_all) {
      end_seekpos=(int)_QROffset();
   }
   if (tag_tree_type_is_class(cur_type_name)) {
      tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, end_seekpos);
   }

   // start seek position should be adjusted to skip leading spaces.
   // that way the column number is more likely to be correct
   start_seekpos := (int)find_start_of_spaces_before(cur_start_seekpos);

   // locals already up to date?
   if (tag_check_cached_locals(start_seekpos, end_seekpos, context_id, list_all? VS_UPDATEFLAG_list_all:0)) {
      //say("_UpdateLocals: using cached locals, num="tag_get_num_of_locals());
      if (p_ModifyFlags & MODIFYFLAG_LOCALS_UPDATED) {
         tag_unlock_context();
         return;
      }
   }
   //say("_UpdateLocals H"__LINE__": ============================================================================");
   //say("_UpdateLocals: Recalculating locals, line="cur_start_line_no", file="p_buf_name" start_seekpos="cur_start_seekpos" end_seekpos="end_seekpos);

   // update the context, is the current context defined?
   if (context_id <= 0) {
      //say("_UpdateLocals: NO CURRENT CONTEXT");
      tag_unlock_context();
      return;
   }

   // parse local variables for this scope and nested local functions and outer functions and/or classes
   status := tag_parse_and_update_locals(start_seekpos, end_seekpos, context_id, (int)_QROffset(), list_all? VS_UPDATEFLAG_list_all:0);
   if (status < 0) {
      tag_unlock_context();
      return;
   }

   //say("_UpdateLocals: after ="_time('b'));

   // call post-processing function for update locals
   AUindex := _FindLanguageCallbackIndex("_%s_after_UpdateLocals");
   if (index_callable(AUindex)) {
      call_index(AUindex);
   }

   //n := tag_get_num_of_locals();
   //say("      _UpdateLocals: final "n" locals");
   //for (i:=1; i<=n; i++) {
   //   VS_TAG_BROWSE_INFO cm;
   //   tag_get_local_info(i,cm);
   //   say("         _UpdateLocals: final member="cm.member_name" flags="cm.flags" seekpos="cm.seekpos);
   //}
   //say("_UpdateLocals: elapsed time ="(int)_time('b')-orig_time"ms");

   // locals are updated, all done
   p_ModifyFlags |= MODIFYFLAG_LOCALS_UPDATED;
   tag_unlock_context();
}

//############################################################################

//////////////////////////////////////////////////////////////////////////////
// Compress the given signature to a very short string
//
static _str compress_signature(_str signature)
{
   if (signature=="void") {
      return "";
   }
   new_signature := "";
   while (signature != "") {
      int p = pos('(:v|[;,*&^]|\[|\])', signature, 1, 'r');
      if (!p) {
         break;
      }
      ch := substr(signature, p, pos(""));
      signature = substr(signature, p+pos("")+1);
      switch (ch) {
      case ";":
      case ",":
      case "*":
      case "&":
      case "^":
      case "[":
      case "]":
      case "int":
      case "integer":
      case "real":
      case "double":
      case "float":
      case "char":
      case "bool":
      case "boolean":
      case "const":
      case "void":
         strappend(new_signature,ch);
      default:
      }
   }
   return new_signature;
}
//////////////////////////////////////////////////////////////////////////////
// Recursive helper function for _ListVirtualMethods (documented below)
//
static void _ListVirtualMethodsR(_str search_class_name, _str search_type,
                                 _str &abstract_indexes, bool only_abstract,
                                 int treewid, int tree_index,
                                 typeless tag_files, bool firstCall,
                                 int &num_matches, int max_matches,
                                 bool allow_locals, bool case_sensitive,
                                 _str (&found_virtual):[], 
                                 _str (&norm_visited):[],
                                 VS_TAG_RETURN_TYPE (&visited):[] = null,
                                 int depth=0)
{
   // Temp code to prevent lockup from bug 1-8IQA3. The problem is classes
   // in the tag database that have the same name as standard java classes
   // and these classes being mistaken for parents of standard java classes.
   // This confusion also causes bug 1-8JR9R. I.E. com.test.InnerClasses/Container
   // is said to be the parent of javax.swing.JComponent when actually the parent of 
   // javax.swing.JComponent is java.awt.Container. This happens when searching a project
   // tag database where com.test.InnerClasses/Container is defined but java.awt.Container is not
   // because it is defined in the java tag database.
   static int nCalls;
   if( firstCall ) nCalls=0;

   if( nCalls > MAX_SEARCH_CALLS ) return;
   nCalls++;

   if (_chdebug) {
      say("_ListVirtualMethodsR("search_class_name")");
   }

   // try to find symbols in this specific class first
   found_definition := false;
   _str outer_class_name, inner_class_name;
   tag_split_class_name(search_class_name, inner_class_name, outer_class_name);
   class_parents := "";
   file_name := "";
   _str tag_filename;
   int i,k,status;
   flag_mask := SE_TAG_FLAG_CONST|SE_TAG_FLAG_VOLATILE|SE_TAG_FLAG_MUTABLE;

   // are all methods abstract (is this an interface?)
   all_abstract := false;
   if (search_type=="interface" /*&& depth==0 */) {
      all_abstract = true;
   }

   type_name := "";
   tag_flags := 0;
   tag_name := "";
   signature := "";
   expected_lang := "";
   if (_isEditorCtl()) {
      expected_lang = p_LangId;
   }

   // is this a .NET language variant
   isdotnet := false;
   if (_LanguageInheritsFrom("cs", expected_lang)) isdotnet = true;
   if (_LanguageInheritsFrom("vb", expected_lang)) isdotnet = true;
   if (_LanguageInheritsFrom("jsl", expected_lang)) isdotnet = true;
   if (_LanguageInheritsFrom("fsharp", expected_lang)) isdotnet = true;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   seekpos := (int)_QROffset();

   // for function context, first try to find a local variable
   if (allow_locals) {
      // find abstract functions
      i = tag_find_local_iterator("", false, case_sensitive, false, search_class_name);
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_local_type, i, type_name);
         tag_get_detail2(VS_TAGDETAIL_local_flags, i, tag_flags);
         if (tag_tree_type_is_func(type_name) && (tag_flags & SE_TAG_FLAG_INCLASS) &&
             (depth==0 || (tag_flags & SE_TAG_FLAG_ACCESS) != SE_TAG_FLAG_PRIVATE || (tag_flags & SE_TAG_FLAG_ABSTRACT)) &&
             !(tag_flags & SE_TAG_FLAG_FINAL) && !(tag_flags & SE_TAG_FLAG_DESTRUCTOR)) {
            tag_get_detail2(VS_TAGDETAIL_local_name, i, tag_name);
            tag_get_detail2(VS_TAGDETAIL_local_args, i, signature);
            if (tag_flags&flag_mask) strappend(tag_name,"/"(tag_flags&flag_mask));
            if (signature != "") strappend(tag_name,"/"compress_signature(signature));
            if ( _chdebug ) {
               isay(depth, "_ListVirtualMethodsR H"__LINE__": Considering "tag_name":"tag_flags" virtual="(tag_flags & SE_TAG_FLAG_VIRTUAL)" abstract="(tag_flags & SE_TAG_FLAG_ABSTRACT));
            }
            if (!found_virtual._indexin(tag_name)) {
               if (all_abstract || (tag_flags & SE_TAG_FLAG_ABSTRACT) ||
                   (!only_abstract && (tag_flags & SE_TAG_FLAG_VIRTUAL))) {
                  if (treewid) {
                     k=tag_tree_insert_fast(treewid,tree_index,VS_TAGMATCH_local,i,0,1,0,0,0);
                  } else {
                     k=tag_insert_match_fast(VS_TAGMATCH_local,i);
                  }
                  if (all_abstract || (tag_flags & SE_TAG_FLAG_ABSTRACT)) {
                     strappend(abstract_indexes,k" ");
                  }
                  found_virtual:[tag_name] = type_name;
                  if (k < 0 || ++num_matches >= max_matches) {
                     break;
                  }
               } 
            }
         }
         i = tag_next_local_iterator("", i, false, case_sensitive, false, search_class_name);
      }

      // if we found the item in local variables, get inheritance information
      i = tag_find_local_iterator(inner_class_name, true, case_sensitive, false, outer_class_name);
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_local_type, i, type_name);
         if (tag_tree_type_is_class(type_name)) {
            found_definition = true;
            tag_get_detail2(VS_TAGDETAIL_local_parents, i, class_parents);
            tag_get_detail2(VS_TAGDETAIL_local_file, i, file_name);
            break;
         }
         i = tag_next_local_iterator(inner_class_name, i, true, case_sensitive, false, outer_class_name);
      }
   }

   // found members of a local structure, search no further
   if (!found_definition) {
      // find abstract functions
      i = tag_find_context_iterator("", false, case_sensitive, false, search_class_name);
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
         tag_get_detail2(VS_TAGDETAIL_context_flags, i, tag_flags);
         if (tag_tree_type_is_func(type_name) && (tag_flags & SE_TAG_FLAG_INCLASS) &&
             (depth==0 || (tag_flags & SE_TAG_FLAG_ACCESS) != SE_TAG_FLAG_PRIVATE || (tag_flags & SE_TAG_FLAG_ABSTRACT)) &&
             !(tag_flags & SE_TAG_FLAG_FINAL) && !(tag_flags & SE_TAG_FLAG_DESTRUCTOR)) {
            tag_get_detail2(VS_TAGDETAIL_context_name, i, tag_name);
            tag_get_detail2(VS_TAGDETAIL_context_args, i, signature);
            if (tag_flags&flag_mask) strappend(tag_name,"/"(tag_flags&flag_mask));
            if (signature != "") strappend(tag_name,"/"compress_signature(signature));
            if ( _chdebug ) {
               isay(depth, "_ListVirtualMethodsR H"__LINE__": Considering "tag_name":"tag_flags" virtual="(tag_flags & SE_TAG_FLAG_VIRTUAL)" abstract="(tag_flags & SE_TAG_FLAG_ABSTRACT));
            }

            if (!found_virtual._indexin(tag_name)) {
               if (all_abstract || (tag_flags & SE_TAG_FLAG_ABSTRACT) ||
                   (!only_abstract && (tag_flags & SE_TAG_FLAG_VIRTUAL))) {
                  if (treewid) {
                     k=tag_tree_insert_fast(treewid,tree_index,VS_TAGMATCH_context,i,0,1,0,0,0);
                  } else {
                     k=tag_insert_match_fast(VS_TAGMATCH_context,i);
                  }
                  if (all_abstract || (tag_flags & SE_TAG_FLAG_ABSTRACT)) {
                     strappend(abstract_indexes,k" ");
                  }
                  found_virtual:[tag_name] = type_name;
                  if (k < 0 || ++num_matches >= max_matches) {
                     break;
                  }
               }
            }
         }
         i = tag_next_context_iterator("", i, false, case_sensitive, false, search_class_name);
      }

      // if we found the item in current context, get inheritance information
      i = tag_find_context_iterator(inner_class_name, true, case_sensitive, false, outer_class_name);
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
         if (tag_tree_type_is_class(type_name)) {
            found_definition = true;
            tag_get_detail2(VS_TAGDETAIL_context_parents, i, class_parents);
            tag_get_detail2(VS_TAGDETAIL_context_file, i, file_name);
            break;
         }
         i = tag_next_context_iterator(inner_class_name, i, true, case_sensitive, false, outer_class_name);
      }
   }

   // found members of a structure within current file, search no further
   if (!found_definition) {
      // look up class members for current class
      i=0;
      tag_filename = next_tag_filea(tag_files, i, false, true);
      while (tag_filename != "") {
         status = tag_find_in_class(search_class_name);
         while (!status) {
            tag_get_detail(VS_TAGDETAIL_name, tag_name);
            tag_get_detail(VS_TAGDETAIL_type, type_name);
            tag_get_detail(VS_TAGDETAIL_flags, tag_flags);
            tag_get_detail(VS_TAGDETAIL_language_id, auto lang);
            if (lang == "tagdoc" || lang == "xmldoc") lang = expected_lang;
            if (lang == "dll" && isdotnet) lang = expected_lang;
            if (lang == "jar" && _LanguageInheritsFrom("java", expected_lang)) lang = expected_lang;
            if (lang == "class" && _LanguageInheritsFrom("java", expected_lang)) lang = expected_lang;
            if (_chdebug) {
               isay(depth, "_ListVirtualMethodsR H"__LINE__": CANDIDATE: "tag_name" flags="(tag_flags & SE_TAG_FLAG_ABSTRACT)" lang="lang" expected_lang="expected_lang);
            }
            if ((expected_lang == "" || lang == expected_lang) &&
                tag_tree_type_is_func(type_name) && (tag_flags & SE_TAG_FLAG_INCLASS) &&
                (depth==0 || (tag_flags & SE_TAG_FLAG_ACCESS) != SE_TAG_FLAG_PRIVATE || (tag_flags & SE_TAG_FLAG_ABSTRACT)) &&
                !(tag_flags & SE_TAG_FLAG_FINAL) && !(tag_flags & SE_TAG_FLAG_DESTRUCTOR)) {
               tag_get_detail(VS_TAGDETAIL_name, tag_name);
               tag_get_detail(VS_TAGDETAIL_arguments, signature);
               if (tag_flags&flag_mask) strappend(tag_name,"/"(tag_flags&flag_mask));
               if (signature != "") strappend(tag_name,"/"compress_signature(signature));
               if (_chdebug) {
                  say("_ListVirtualMethodsR H"__LINE__": Considering2 "tag_name":"tag_flags" A("(tag_flags&SE_TAG_FLAG_ABSTRACT)") V("(tag_flags&SE_TAG_FLAG_VIRTUAL)")");
               }
               if (!found_virtual._indexin(tag_name)) {
                  if (all_abstract || (tag_flags & SE_TAG_FLAG_ABSTRACT) ||
                      (!only_abstract && (tag_flags & SE_TAG_FLAG_VIRTUAL))) {
                     if (_chdebug) {
                        isay(depth, "_ListVirtualMethodsR H"__LINE__": MATCH");
                     }
                     if (treewid) {
                        k=tag_tree_insert_fast(treewid,tree_index,VS_TAGMATCH_tag,0,0,1,0,0,0);
                     } else {
                        k=tag_insert_match_fast(VS_TAGMATCH_tag,0);
                     }
                     if (all_abstract || (tag_flags & SE_TAG_FLAG_ABSTRACT)) {
                        strappend(abstract_indexes,k" ");
                     }
                     found_virtual:[tag_name] = type_name;
                     if (k < 0 || ++num_matches >= max_matches) {
                        break;
                     }
                  }
               }
               if (file_name=="" && (tag_flags & SE_TAG_FLAG_INCLASS)) {
                  tag_get_detail(VS_TAGDETAIL_file_name, file_name);
               }
            }
            status = tag_next_in_class();
         }
         tag_reset_find_in_class();

         // get the class parents, and stop here
         if (!found_definition) {
            status = tag_get_inheritance(search_class_name, class_parents);
            if (!status && class_parents != "") {
               found_definition = true;
            }
         }
         tag_filename = next_tag_filea(tag_files, i, false, true);
      }
   }
   if (_chdebug) {
      isay(depth, "_ListVirtualMethodsR H"__LINE__": num_matches="num_matches);
   }

   // normalize the list of parents from the database
   normalized_parents := "";
   normalized_types := "";
   normalized_files := "";
   if (class_parents != "") {
      tag_normalize_classes(class_parents, search_class_name, file_name,
                            tag_files, allow_locals, case_sensitive,
                            normalized_parents, normalized_types, normalized_files, norm_visited);
   }

   // demote access level before doing inherited classes
   //if (context_flags & SE_TAG_CONTEXT_ALLOW_PRIVATE) {
   //   context_flags &= ~SE_TAG_CONTEXT_ALLOW_PRIVATE;
   //   context_flags |= SE_TAG_CONTEXT_ALLOW_PROTECTED;
   //}

   // add each of them to the list also
   while (normalized_parents != "") {
      // add transitively inherited class members
      _str p1,n1;
      parse normalized_parents with p1 ";" normalized_parents;
      parse normalized_types   with n1 ";" normalized_types;
      //say("p1="p1" n1="n1);
      if (depth < MAX_RECURSIVE_SEARCH) {
         if (_chdebug) {
            isay(depth+1, "_ListVirtualMethodsR depth="depth" normalized_parent="p1);
         }
         parse p1 with p1 "<" .;
         _ListVirtualMethodsR(p1, n1, abstract_indexes,
                              only_abstract, treewid, tree_index,
                              tag_files, false, num_matches, max_matches,
                              allow_locals, case_sensitive, 
                              found_virtual, norm_visited,
                              visited, depth+1);
      } 
   }
}
/**
 * List the virtual functions in the given class, struct, or interface.
 * by searching first locals, then the current file, then tag files,
 * looking strictly for the class definition, not just class members.
 * Recursively looks for symbols in inherited classes.  The order of
 * searching parent classes is depth-first, preorder (root node searched
 * before children).
 *
 * Look at num_matches to see if any matches were found.  Generally
 * if (num_matches >= max_matches) there may be more matches, but
 * the search terminated early.
 * The current object must be an editor control or the current buffer.
 *
 * @param search_class_name  name of class to look for symbols in
 * @param search_type        class/interface/struct
 * @param abstract_indexes   (reference) set to indexes of abstract methods
 * @param only_abstract      list only abstract methods or unimplemented functions
 * @param treewid            window of tree to insert into, 0 implies
 *                           insert matches (tag_insert_match)
 * @param tree_index         tree index to insert items under, ignored
 *                           if (treewid == 0)
 * @param num_matches        (reference) number of matches found so far
 * @param max_matches        maximum number of matches to be considered
 * @param allow_locals       allow local structs?
 * @param case_sensitive     case sensitive tag searching?
 */
void _ListVirtualMethods(_str search_class_name, _str search_type,
                         _str &abstract_indexes, bool only_abstract,
                         int treewid, int tree_index,
                         int &num_matches, int max_matches,
                         bool allow_locals, bool case_sensitive,
                         bool removeFromCurrentClass=true,
                         VS_TAG_RETURN_TYPE (&visited):[]=null,
                         int depth=0)
{
   if (_chdebug) {
      isay(depth, "_ListVirtualMethods("search_class_name")");
   }

   // This function is NOT designed to list globals, bad caller, bad.
   if (search_class_name == "") {
      return;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // update the current context and locals
   _UpdateContext(true);
   _UpdateLocals(true);

   // try to find symbols in this specific class first
   typeless tag_files = tags_filenamea(p_LangId);
   _str found_virtual:[];found_virtual._makeempty();
   _str norm_visited:[]; norm_visited._makeempty();

   //say("Begin list_virtuals=============================");
   _ListVirtualMethodsR(search_class_name, search_type, abstract_indexes, only_abstract,
                        treewid, tree_index, tag_files,
                        removeFromCurrentClass,
                        num_matches, max_matches,
                        allow_locals, case_sensitive, 
                        found_virtual, norm_visited,
                        visited, depth+1);
}




/**
 * List the symbols visible in the different contexts, including 
 * <ul> 
 * <li>Locals</li>
 * <li>Class Members</li>
 * <li>Module Variables (static)</li>
 * </ul>
 * The current object must be an editor control or current buffer. 
 *  
 * @param visited    (optional) hash table of prior results
 * @param depth      (optional) depth of recursive search
 *
 * @return the current class name
 */
_str _MatchThisOrSelf(typeless &visited=null, int depth=0)
{
   //say("_ListThisOrSelf()");

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // update the current context
   _UpdateContext(true);
   context_id := tag_current_context();
   if (context_id <= 0) {
      return "";
   }

   // not a function or proc, not a static method, in a class method
   cur_class_name := cur_type_name := "";
   cur_tag_flags := 0;
   tag_get_detail2(VS_TAGDETAIL_context_class, context_id, cur_class_name);
   tag_get_detail2(VS_TAGDETAIL_context_type,  context_id, cur_type_name);
   tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, cur_tag_flags);
   if (cur_class_name == "" ||
       cur_tag_flags & SE_TAG_FLAG_STATIC ||
       !tag_tree_type_is_func(cur_type_name) || cur_type_name :== "proto") {
      return "";
   }

   // not really a class method, just a member of a package
   tag_files := tags_filenamea(p_LangId);
   tag_split_class_name(cur_class_name, auto inner_name, auto outer_name);
   if (tag_check_for_package(inner_name, tag_files, true, true, null, visited, depth+1)) {
      return "";
   }

   // add the item to the tree
   return cur_class_name;
}

/**
 * List the parameters of the current symbol if it is a #define
 * The current object must be an editor control or current buffer.
 *
 * @param treewid            window of tree to insert into, 0 implies
 *                           insert matches (tag_insert_match)
 * @param tree_index         tree index to insert items under, ignored
 *                           if (treewid == 0)
 * @param num_matches        (reference) number of matches found so far
 * @param max_matches        maximum number of matches to be considered
 */
void _ListParametersOfDefine(int treewid, int tree_index,
                             int &num_matches,
                             int max_matches=MAX_SYMBOL_MATCHES,
                             _str prefix="")
{
   //say("_ListParametersOfDefine()");

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // update the current context
   _UpdateContext(true);
   context_id := tag_current_context();
   if (context_id <= 0) {
      return;
   }

   // is this a #define?
   _str type_name;
   tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
   if (type_name :!= "define") {
      return;
   }

   // get the #define signature
   _str signature;
   tag_get_detail2(VS_TAGDETAIL_context_args, context_id, signature);

   // get the start line and seekpos of the #define
   int start_linenum, start_seekpos;
   tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, start_linenum);
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);

   // insert each argument
   while (signature != "") {
      _str a;
      parse signature with a "," signature;
      a = strip(a);
      if (a != "" && (prefix=="" || a==prefix)) {
         k := 0;
         if (treewid) {
            k=tag_tree_insert_tag(treewid, tree_index, 0, 1, 0, a, "param", p_buf_name, start_linenum, "", 0, "");
         } else {

            // find the exact location of the #define parameter
            typeless s1,s2,s3,s4,s5;
            save_pos(auto p);
            save_search(s1,s2,s3,s4,s5);
            _GoToROffset(start_seekpos);
            if (search('(','@h') < 0) {
               restore_pos(p);
            } else if (search(a, '@ewh') < 0) {
               restore_pos(p);
            } else {
               start_linenum = p_RLine;
               start_seekpos = (int)_QROffset();
            }

            tag_init_tag_browse_info(auto cm, a, "", SE_TAG_TYPE_PARAMETER, SE_TAG_FLAG_NULL, p_buf_name, start_linenum);
            cm.line_no = start_linenum;
            cm.seekpos = start_seekpos;
            cm.scope_line_no = start_linenum;
            cm.scope_seekpos = start_seekpos;
            cm.end_line_no = start_linenum;
            cm.end_seekpos = start_seekpos+length(a);
            k = tag_insert_match_browse_info(cm,true);

            restore_pos(p);
            restore_search(s1,s2,s3,s4,s5);
         }
         if (k < 0 || ++num_matches >= max_matches) {
            break;
         }
      }
   }
}

// List the parameters of the given class symbol
// NOTE: this method is very C++ specific, whatcha gonna do...
//
static void _ListParametersOfClass(int treewid, int tree_index,
                                   _str type_name, int tag_flags, _str signature,
                                   int &num_matches, int max_matches)
{
   // is this a template class?
   if (type_name :== "class" && (tag_flags & SE_TAG_FLAG_TEMPLATE)) {
      // insert each argument
      while (signature != "") {
         _str a;
         parse signature with a "," signature;
         a = strip(a);
         if (a != "") {
            type_name = "var";
            if (pos("class", a)==1) {
               type_name = "class";
               parse a with "class" a;
            } else if (pos("typename", a)==1) {
               type_name = "typedef";
               parse a with "typename" a;
            } else {
            }
            parse a with a "=" .;
            a = strip(a);
            if (pos('{:v}:b@$',a,1,'r')) {
               a = substr(a, pos('S0'), pos('0'));
            }

            int k;
            if (treewid) {
               k=tag_tree_insert_tag(treewid, tree_index, 0, 1, 0, a, type_name, p_buf_name, p_RLine, "", 0, "");
            } else {
               tag_init_tag_browse_info(auto cm, a, "", type_name, SE_TAG_FLAG_NULL, p_buf_name, p_RLine, _QROffset());
               cm.end_line_no = p_RLine;
               cm.end_seekpos = _QROffset();
               k=tag_insert_match_browse_info(cm,true);
            }
            if (k < 0 || ++num_matches >= max_matches) {
               break;
            }
         }
      }
   }
}

/**
 * List the parameters of the current symbol if it is a #define
 * The current object must be an editor control or current buffer.
 *
 * @param treewid            window of tree to insert into, 0 implies
 *                           insert matches (tag_insert_match)
 * @param tree_index         tree index to insert items under, ignored
 *                           if (treewid == 0)
 * @param case_sensitive     case sensitive tag searching?
 * @param num_matches        (reference) number of matches found so far
 * @param max_matches        maximum number of matches to be considered
 */
void _ListParametersOfTemplate(int treewid, int tree_index,
                               bool case_sensitive, int &num_matches,
                               int max_matches=MAX_SYMBOL_MATCHES)
{
   //say("_ListParametersOfTemplate()");

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // update the current context
   _UpdateContext(true);
   context_id := tag_current_context();
   if (context_id <= 0) {
      return;
   }

   // is this a template class?
   _str type_name, signature, cur_class_name="";
   int tag_flags;
   tag_get_detail2(VS_TAGDETAIL_context_type,  context_id, type_name);
   tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, tag_flags);
   tag_get_detail2(VS_TAGDETAIL_context_args,  context_id, signature);
   tag_get_detail2(VS_TAGDETAIL_context_class, context_id, cur_class_name);
   _ListParametersOfClass(treewid, tree_index,
                          type_name, tag_flags, signature,
                          num_matches, max_matches);

   // for each level of class nesting
   lang := _isEditorCtl()? p_LangId : "";
   tag_files := tags_filenamea(lang);
   while (cur_class_name != "") {
      //_str symbol_name = _GetClassNameOnly(cur_class_name);
      //cur_class_name = _GetOuterClassName(cur_class_name);
      _str symbol_name;
      tag_split_class_name(cur_class_name, symbol_name, cur_class_name);

      // Look for template parameters within the current context
      context_id = tag_find_context_iterator(symbol_name, true, case_sensitive, false, cur_class_name);
      while (context_id > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type,  context_id, type_name);
         tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, tag_flags);
         tag_get_detail2(VS_TAGDETAIL_context_args,  context_id, signature);
         //tag_get_detail2(VS_TAGDETAIL_context_class, context_id, class_name);
         //if (class_name :== cur_class_name ||
         //   (!case_sensitive && lowcase(class_name) :== lowcase(cur_class_name))) {
            // got a match, list the parameters
            _ListParametersOfClass(treewid, tree_index,
                                   type_name, tag_flags, signature,
                                   num_matches, max_matches);
         //}
         context_id = tag_next_context_iterator(symbol_name, context_id, true, case_sensitive, false, cur_class_name);
      }

      if (num_matches == 0) {
         i := 0;
         _str tag_filename = next_tag_filea(tag_files, i, false, true);
         while (tag_filename != "") {
            int status = tag_find_equal(symbol_name, case_sensitive, cur_class_name);
            while (!status) {
               tag_get_detail(VS_TAGDETAIL_type, type_name);
               tag_get_detail(VS_TAGDETAIL_flags, tag_flags);
               tag_get_detail(VS_TAGDETAIL_arguments, signature);

               _ListParametersOfClass(treewid, tree_index,
                                      type_name, tag_flags, signature,
                                      num_matches, max_matches);
               status = tag_next_equal(case_sensitive, cur_class_name);
            }
            tag_reset_find_tag();
            tag_filename = next_tag_filea(tag_files, i, false, true);
         }
      }
   }
}

/**
 * Find the given tag in the given tag database and populate the 'cm'
 * datastructure for the symbol browser.
 *
 * @param cm                  struct containing current tag info
 * @param match_tag_database  name of database to search for tag
 * @param tag_name            name of tag to search for
 * @param file_name           name of file tag belongs to
 * @param line_no             line number tag is expected to be on
 *
 * @return tru on success, false if not found.
 */
bool _GetContextTagInfo(struct VS_TAG_BROWSE_INFO &cm,
                           _str match_tag_database, _str tag_name,
                           _str file_name, int line_no)
{
   //say("_GetContextTagInfo("tag_name","file_name","line_no")");
   tag_init_tag_browse_info(cm);
   cm.tag_database   = match_tag_database;
   if (match_tag_database != "") {
      if (_haveContextTagging()) {
         return false;
      }
      // find in the given tag database
      int status = tag_read_db(match_tag_database);
      if (status >= 0) {
         status = tag_find_closest(tag_name, file_name, line_no, true);
         tag_reset_find_tag();
         if (status == 0) {
            tag_get_tag_browse_info(cm);
            return true;
         }
      }
   } else {
      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      // maybe it was a local variable?
      int i = tag_find_local_iterator(tag_name, true, true);
      while (i > 0) {
         context_line := 0;
         tag_get_detail2(VS_TAGDETAIL_local_line,  i, context_line);
         if (context_line == line_no) {
            tag_get_local_info(i, cm);
            if (_file_eq(cm.file_name,file_name) || (cm.flags&SE_TAG_FLAG_EXTERN_MACRO)) {
               return true;
            }
         }
         i = tag_next_local_iterator(tag_name, i, true, true);
      }
      // maybe it was from the current file?
      i = tag_find_context_iterator(tag_name, true, true);
      while (i > 0) {
         context_line := 0;
         tag_get_detail2(VS_TAGDETAIL_context_line, i, context_line);
         if (context_line == line_no) {
            typeless d1,d2,d3,d4,d5;
            tag_get_context_info(i, cm);
            if (_file_eq(cm.file_name,file_name) || (cm.flags&SE_TAG_FLAG_EXTERN_MACRO)) {
               return true;
            }
         }
         i = tag_next_context_iterator(tag_name, i, true, true);
      }
   }
   // did not find a match, really quite depressing, use what we know
   cm.member_name = tag_name;
   cm.type_name   = "";
   cm.file_name   = file_name;
   cm.line_no     = line_no;
   cm.class_name  = "";
   cm.flags       = SE_TAG_FLAG_NULL;
   cm.arguments   = "";
   cm.return_type = "";
   cm.exceptions  = "";
   cm.class_parents = "";
   cm.template_args = "";
   if (cm.language==null) {
      cm.language   = "";
   }
   return false;
}


/**
 * This function removes the duplicate functions from the
 * current match set.  The technique used is to first compute
 * the set partition across the set of matches using the match
 * tag type name and signature / argument comparison as an
 * equivelence relation.  Then for each partition, we select the
 * first item or the best item in the set.
 * <p>
 * The result is returned through the reference parameter
 * 'unique_indexes' is an array of integers represent match
 * indexes of the unique selected tags. 
 * <p> 
 * <p> 
 * For synchronization, macros should perform a 
 * tag_lock_matches(true) prior to invoking this function. 
 *
 * @param unique_indexes     set to list of index of unique matches
 * @param duplicate_indexes  set to lsit of duplicate matches 
 * @param pfnCompareArgs     callback type used for comparing 
 *                           argument lists. This used when
 *                           {@link tag_tree_compare_args} does
 *                           not work for a particular language.
 *                           The function should return true if
 *                           the arg lists match, false otherwise.
 */
void removeDuplicateFunctions(int (&unique_indexes)[], _str (&duplicate_indexes)[], 
                              VS_TAG_COMPARE_ARGS_PFN pfnCompareArgs=null)
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(true);

   int num_matches = tag_get_num_of_matches();
   int num_left = num_matches;
   num_sets := 0;
   int i, first_item = 1;
   bool all_indexes[]; all_indexes._makeempty();
   _str equiv_indexes[]; equiv_indexes._makeempty();

   // initialize the set of match indexes
   for (i=1; i<=num_matches; i++) {
      all_indexes[i] = true;
   }

   cur_type_name:="";
   cur_signature:="";
   cur_proc_name:="";
   cur_line_no:=0;
   cur_file_name:="";

   // until the set of indexes is empty
   while (num_left > 0) {
      // find first remaining item
      for (i=first_item; i<=num_matches; i++) {
         if (all_indexes[i]) {
            all_indexes[i] = false;
            equiv_indexes[num_sets] = first_item = i;
            num_left--;
            break;
         }
      }

      // get all the information about the current item
      tag_get_detail2(VS_TAGDETAIL_match_type,first_item,cur_type_name);
      tag_get_detail2(VS_TAGDETAIL_match_args,first_item,cur_signature);
      tag_get_detail2(VS_TAGDETAIL_match_name,first_item,cur_proc_name);
      tag_get_detail2(VS_TAGDETAIL_match_line,first_item,cur_line_no);
      tag_get_detail2(VS_TAGDETAIL_match_file,first_item,cur_file_name);
      int cur_is_func = tag_tree_type_is_func(cur_type_name);
      equiv_line_no:=0;
      equiv_file_name:="";
      equiv_type_name:="";
      //say("removeDuplicateFunctions: proc_name="cur_proc_name" sig="cur_signature" type="cur_type_name);

      // find items in its equivelance class
      for (i=first_item+1; i<=num_matches; i++) {
         if (all_indexes[i]) {
            // declare variables
            _str i_type_name, i_signature, i_proc_name;
            i_line_no := 0;
            _str i_file_name;
            // check if types match adequately
            tag_get_detail2(VS_TAGDETAIL_match_type,i,i_type_name);
            if (i_type_name == cur_type_name ||
                tag_tree_type_is_func(i_type_name) == cur_is_func) {
               // OK, now check signatures
               tag_get_detail2(VS_TAGDETAIL_match_args,i,i_signature);
               tag_get_detail2(VS_TAGDETAIL_match_name,i,i_proc_name);
               tag_get_detail2(VS_TAGDETAIL_match_line,i,i_line_no);
               tag_get_detail2(VS_TAGDETAIL_match_file,i,i_file_name);
               //say("removeDuplicateFunctions: proc_name["i"]="i_proc_name" sig="i_signature" type="i_type_name);
               if (_LanguageInheritsFrom("cs")) {
                  i_signature = stranslate(i_signature, "ref_#0", "ref:b{:v}", "rew");
                  i_signature = stranslate(i_signature, "out_#0", "ref:b{:v}", "rew");
                  cur_signature = stranslate(cur_signature, "ref_#0", "ref:b{:v}", "rew");
                  cur_signature = stranslate(cur_signature, "out_#0", "ref:b{:v}", "rew");
               }
               if (strieq(i_proc_name,cur_proc_name) &&
                   ((pfnCompareArgs!=null && (*pfnCompareArgs)(i_signature, cur_signature)) ||
                    (pfnCompareArgs==null && !tag_tree_compare_args(i_signature, cur_signature, false)))
                   ) {
                  /*
                     Realistically, line number from tag files will match exactly.
                     However, line number from context may be more update-to-date
                     than the tag file line numbers.
                  */
                  if (abs(i_line_no-cur_line_no)<5 && 
                      _file_eq(i_file_name,cur_file_name) &&
                      i_type_name == cur_type_name) {
                     all_indexes[i]= false;
                     --num_left;
                  } else if (abs(i_line_no-equiv_line_no)<5 && 
                             _file_eq(i_file_name,equiv_file_name) && 
                             i_type_name == equiv_type_name) {
                     all_indexes[i]= false;
                     --num_left;
                  } else {
                     all_indexes[i]= false;
                     strappend(equiv_indexes[num_sets], " "i);
                     --num_left;
                     equiv_line_no=i_line_no;
                     equiv_file_name=i_file_name;
                     equiv_type_name=i_type_name;
                  }
               }
            }
         }
      }

      // increment the number of sets processed
      num_sets++;
   }
   duplicate_indexes=equiv_indexes;
   // remove all but one item from each equivelence class
   for (i=0; i<num_sets; i++) {
      best_match := 0;
      best_score := 0;
      while (equiv_indexes[i] != "") {
         typeless k;
         parse equiv_indexes[i] with k equiv_indexes[i];
         // calculate weighted score for this match
         i_score := 1;
         _str k_type_name;
         int k_tag_flags;
         tag_get_detail2(VS_TAGDETAIL_match_type,k,k_type_name);
         tag_get_detail2(VS_TAGDETAIL_match_flags,k,k_tag_flags);
         // good to be a proc or proto (might have default values)
         if (k_type_name=="proto" || k_type_name=="procproto") {
            i_score++;
         }
         // not good to be external (can omit prototype in Pascal)
         if (!(k_tag_flags & SE_TAG_FLAG_EXTERN)) {
            i_score++;
         }
         // pick the best one...
         if (i_score > best_score) {
            best_match = k;
            best_score = i_score;
         }
      }
      unique_indexes[i] = best_match;
   }
}


//////////////////////////////////////////////////////////////////////////////
/**
 * Initialize a symbol browser tag information structure.
 *
 * @param cm            tag browse info structure to initialize
 * @param name          symbol name
 * @param class_name    class name (scope of this symbol)
 * @param type_name     tag type name (SE_TAG_TYPE_*)
 * @param tag_flags     tag flags (bitset of SE_TAG_FLAG_*)
 * @param file_name     file name
 * @param line_no       start line number
 * @param seekpos       start seek position
 * @param arguments     function arguments
 * @parma return_type   return type of symbol
 * 
 * @note
 * This function is not formally deprecated, however, it is preferred and
 * faster to call {@link tag_init_tag_browse_info()} instead.
 * 
 * @see tag_get_tag_browse_info()
 * @see tag_get_local_browse_info()
 * @see tag_get_context_browse_info()
 * @see tag_get_match_browse_info()
 * 
 * @categories Tagging_Functions
 */
void tag_browse_info_init(struct VS_TAG_BROWSE_INFO &cm,
                          _str name="", 
                          _str class_name="",
                          _str type_name_or_id="", 
                          SETagFlags tag_flags=SE_TAG_FLAG_NULL,
                          _str file_name="", int line_no=0, long seekpos=0,
                          _str arguments="", _str return_type="")
{
   tag_init_tag_browse_info(cm, name, class_name, 
                            type_name_or_id, tag_flags,
                            file_name, line_no, seekpos, 
                            arguments, return_type);
}

/**
 * Initialize an identifier prefix expression information structure.
 *
 * @param cm   prefix expression information structure to initialize
 *
 * @categories Tagging_Functions
 */
void tag_idexp_info_init(struct VS_TAG_IDEXP_INFO &idexp_info)
{
   idexp_info.errorArgs._makeempty();
   idexp_info.info_flags = 0;
   idexp_info.lastid = "";
   idexp_info.lastidstart_col = 0;
   idexp_info.lastidstart_offset = 0;
   idexp_info.otherinfo = null;
   idexp_info.prefixexp = "";
   idexp_info.prefixexpstart_offset = 0;
}

/**
 * Compare two identifier prefix expression info structures equality.
 * 
 * @param lhs              first tag browse info to compare
 * @param rhs              first tag browse info to compare
 * 
 * @return true if equal, false otherwise
 * 
 * @categories Tagging_Functions
 */
bool tag_idexp_info_equal(struct VS_TAG_IDEXP_INFO &lhs, struct VS_TAG_IDEXP_INFO &rhs)
{
   return ( (lhs.info_flags == rhs.info_flags) &&
            (lhs.lastid :== rhs.lastid) &&
            (lhs.lastidstart_col == rhs.lastidstart_col) &&
            (lhs.lastidstart_offset == rhs.lastidstart_offset) &&
            (lhs.otherinfo == rhs.otherinfo) &&
            (lhs.prefixexp :== rhs.prefixexp) &&
            (lhs.prefixexpstart_offset == rhs.prefixexpstart_offset) );
}

void tag_idexp_info_dump(struct VS_TAG_IDEXP_INFO &idexp_info, _str where="", int depth=0)
{
   int i;
   isay(depth, "//=================================================================");
   isay(depth, "// idexp info from " where);
   isay(depth, "//=================================================================");

   isay(depth, "idexp_info.errorArgs");
   if(idexp_info.errorArgs != null) {
      isay(depth, "    length = "idexp_info.errorArgs._length());
      for(i = 0; i < idexp_info.errorArgs._length(); i++) {
         if (idexp_info.errorArgs[i]==null) {
            isay(depth, "    "i"=null");
         } else {
            isay(depth, "    "i"="idexp_info.errorArgs[i]);
         }
      }
   }
   flags := "";
   if(idexp_info.info_flags & VSAUTOCODEINFO_DO_FUNCTION_HELP) {
      flags :+= "DO_FUNCTION_HELP | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_DO_LIST_MEMBERS) {
      flags :+= "DO_LIST_MEMBERS | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      flags :+= "LASTID_FOLLOWED_BY_PAREN | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
      flags :+= "IN_TEMPLATE_ARGLIST | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_INITIALIZER_LIST) {
      flags :+= "IN_INITIALIZER_LIST | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_FUNCTION_POINTER_ARGLIST) {
      flags :+= "IN_FUNCTION_POINTER_ARGLIST | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST) {
      flags :+= "MAYBE_IN_INITIALIZER_LIST | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_VAR_OR_PROTOTYPE_DECL) {
      flags :+= "VAR_OR_PROTOTYPE_DECL | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST_TEST) {
      flags :+= "IN_TEMPLATE_ARGLIST_TEST | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_OPERATOR_TYPED) {
      flags :+= "OPERATOR_TYPED | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) {
      flags :+= "IN_GOTO_STATEMENT | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_THROW_STATEMENT) {
      flags :+= "IN_THROW_STATEMENT | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_ALLOW_SPACE_IN_LIST_MEMBERS) {
      flags :+= "ALLOW_SPACE_IN_LIST_MEMBERS | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_DO_SYNTAX_EXPANSION) {
      flags :+= "DO_SYNTAX_EXPANSION | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL) {
      flags :+= "NOT_A_FUNCTION_CALL | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING) {
      flags :+= "IN_PREPROCESSING | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING_ARGS) {
      flags :+= "IN_PREPROCESSING_ARGS | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_OBJECTIVEC_CONTEXT) {
      flags :+= "OBJECTIVEC_CONTEXT | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) {
      flags :+= "IN_JAVADOC_COMMENT | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS) {
      flags :+= "DO_AUTO_LIST_PARAMS | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_STRING_OR_NUMBER) {
      flags :+= "IN_STRING_OR_NUMBER | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_HAS_REF_OPERATOR) {
      flags :+= "HAS_REF_OPERATOR | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET) {
      flags :+= "LASTID_FOLLOWED_BY_BRACKET | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_IMPORT_STATEMENT) {
      flags :+= "IN_IMPORT_STATEMENT | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_HAS_CLASS_SPECIFIER) {
      flags :+= "HAS_CLASS_SPECIFIER | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_HAS_FUNCTION_SPECIFIER) {
      flags :+= "HAS_FUNCTION_SPECIFIER | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_ASSIGNMENT) {
      flags :+= "LASTID_FOLLOWED_BY_ASSIGNMENT | ";
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACES) {
      flags :+= "LASTID_FOLLOWED_BY_BRACES | ";
   }
   // Take out traiiing " | "
   if(flags != "") {
      flags = substr(flags, 1, length(flags)-3);
   }

   isay(depth, "idexp_info.info_flags='" flags"'");
   isay(depth, "idexp_info.lastid='"idexp_info.lastid"'");
   isay(depth, "idexp_info.lastidstart_col="idexp_info.lastidstart_col);
   isay(depth, "idexp_info.lastidstart_offset="idexp_info.lastidstart_offset);
   if (idexp_info.otherinfo==null) idexp_info.otherinfo="";
   isay(depth, "idexp_info.otherinfo="idexp_info.otherinfo);
   isay(depth, "idexp_info.prefixexp='"idexp_info.prefixexp"'");
   isay(depth, "idexp_info.prefixexpstart_offset="idexp_info.prefixexpstart_offset);
}

/**
 * Compare two tag browse info sets for equality.
 * 
 * @param rt1              first tag browse info to compare
 * @param rt2              first tag browse info to compare
 * @param case_sensitive   case sensitive comparison?
 * 
 * @return true if equal, false otherwise
 * 
 * @categories Tagging_Functions
 */
bool tag_browse_info_equal(struct VS_TAG_BROWSE_INFO &cm1,
                           struct VS_TAG_BROWSE_INFO &cm2,
                           bool case_sensitive=true)
{
   if (cm1==null && cm2==null) {
      return true;
   }
   if (cm1==null || !VF_IS_STRUCT(cm1) ||
       cm2==null || !VF_IS_STRUCT(cm2)) {
      return false;
   }
   if ((cm1.line_no>0 && cm2.line_no>0 && cm1.line_no!=cm2.line_no) ||
       (cm1.seekpos>0 && cm2.seekpos>0 && cm1.seekpos!=cm2.seekpos)) {
      return false;
   }
   if (cm1.type_name :!= cm2.type_name) {
      return false;
   }
   if ((case_sensitive  && cm1.member_name :!= cm2.member_name) ||
       (!case_sensitive && !strieq(cm1.member_name,cm2.member_name))) {
      return false;
   }
   if (tag_compare_classes(cm1.class_name, cm2.class_name, case_sensitive) != 0) {
      return false;
   }
   if (cm1.file_name!="" && cm2.file_name!="" && !_file_eq(cm1.file_name,cm2.file_name)) {
      return false;
   }
   if ((cm1.arguments!=null && cm2.arguments!=null && cm1.arguments!="" && cm2.arguments!="" && cm1.arguments:!=cm2.arguments) ||
       (cm1.return_type!=null && cm2.return_type!=null && cm1.return_type!="" && cm2.return_type!="" && cm1.return_type:!=cm2.return_type) ||
       (cm1.exceptions!=null && cm2.exceptions!=null && cm1.exceptions!="" && cm2.exceptions!="" && cm1.exceptions:!=cm2.exceptions) ||
       (cm1.class_parents!=null && cm2.class_parents!=null && cm1.class_parents!="" && cm2.class_parents!="" && cm1.class_parents:!=cm2.class_parents) ||
       (cm1.template_args!=null && cm2.template_args!=null && cm1.template_args!="" && cm2.template_args!="" && cm1.template_args:!=cm2.template_args)
      ) {
      return false;
   }
   if (cm1.language!="" && cm2.language!="" && cm1.language!=cm2.language) {
      return false;
   }
   // OK, they are close enough
   return true;
}

/**
 * Print out the the current symbol's information
 */
_command void tag_dump_current_context(_str caption="CONTEXT", int level=0)
{
   isay(level, "tag_dump_current_context: ===============================================");
   _UpdateContext(true,false,VS_UPDATEFLAG_context);
   context_id := tag_current_context();
   if (context_id <= 0) {
      isay(level, "tag_dump_current context:  No symbol under cursor");
   } else {
      tag_get_context_browse_info(context_id, auto cm);
      tag_browse_info_dump(cm, caption:+"[":+context_id:+"]", level);
   }
}

/**
 * Print out the full contents of the current context
 */
_command void tag_dump_context(_str caption="CONTEXT", int level=0)
{
   isay(level, "tag_dump_context: =======================================================");
   _UpdateContext(true,false,VS_UPDATEFLAG_context);
   n := tag_get_num_of_context();
   for (i:=1; i<=n; i++) {
      tag_get_context_browse_info(i, auto cm);
      tag_browse_info_dump(cm, caption:+"[":+i:+"]", level);
   }
}

/**
 * Print out the full contents of the current context, including statements
 */
_command void tag_dump_statements(_str caption="STATEMENTS", int level=0)
{
   isay(level, "tag_dump_statements: =======================================================");
   _UpdateStatements(true,false);
   n := tag_get_num_of_statements();
   for (i:=1; i<=n; i++) {
      tag_get_statement_browse_info(i, auto cm);
      tag_browse_info_dump(cm, caption:+"[":+i:+"]", level);
   }
}

/**
 * Print out the full contents of the current set of locals
 */
_command void tag_dump_locals(_str caption="LOCALS", int level=0)
{
   isay(level, "tag_dump_locals: =======================================================");
   _UpdateLocals(true);
   n := tag_get_num_of_locals();
   for (i:=1; i<=n; i++) {
      tag_get_local_browse_info(i, auto cm);
      tag_browse_info_dump(cm, caption:+"[":+i:+"]", level);
   }
}

/**
 * Print out the full contents of the current set of locals
 */
_command void tag_dump_locals_in_scope(_str caption="LOCALS", int level=0)
{
   isay(level, "tag_dump_locals_in_scope: =======================================================");
   _UpdateLocals(true);
   offset := _QROffset();
   n := tag_get_num_of_locals();
   tag_browse_info_init(auto cm);
   isay(level, "tag_dump_locals_in_scope: offset="offset" num locals="n);
   for (i:=1; i<=n; i++) {
      tag_get_local_browse_info(i, cm);
      //tag_get_detail2(VS_TAGDETAIL_local_outer, i, auto outer_id);
      isay(level, "tag_dump_locals_in_scope: CHECKING "i"/"n" name="cm.member_name);//" outer_id="outer_id);
      if (!tag_is_local_in_scope(i,(int)offset)) {
         isay(level+1, "tag_dump_locals_in_scope: SKIPPING "cm.member_name" on line "cm.line_no);
         continue;
      }
      tag_browse_info_dump(cm, caption:+"[":+i:+"]", level+1);
   }
}

/**
 * Print out the full contents of the current tagging match set
 */
_command void tag_dump_matches(_str caption="MATCHES", int level=0)
{
   isay(level, "tag_dump_matches: =======================================================");
   n := tag_get_num_of_matches();
   for (i:=1; i<=n; i++) {
      tag_get_match_info(i, auto cm);
      tag_browse_info_dump(cm, caption:+"[":+i:+"]", level);
   }
}

static int tag_dump_preprocessed_tokens(int tid, _str caption, int level)
{
   if (level > 256) return tid;
   orig_tid := tid;
   pptid := tag_get_first_pptoken(tid);
   if (pptid <= 0 /*|| pptid == tid*/) {
      return tid;
   }
   endtid := tid;
   while (tid > 0) {
      if (tag_get_first_pptoken(tid) != pptid) break;
      tag_get_token_info(tid, auto token_type, auto token_text, auto token_seek, auto token_line);
      isay(level-1, caption :+ "(MACRO):  line " :+ token_line :+ "[" :+ tid :+ "]: " :+ token_text :+ " => " :+ tag_get_token_type_name(token_type));
      endtid = tid;
      tid = tag_get_next_token(tid);
   }
   while (pptid > 0 && pptid != orig_tid) {
      orig_pptid := pptid;
      pptid = tag_dump_embedded_tokens(pptid, caption, level+1);
      pptid = tag_dump_preprocessed_tokens(pptid, caption, level+1);
      if (pptid == orig_pptid) {
         tag_get_token_info(pptid, auto token_type, auto token_text, auto token_seek, auto token_line);
         isay(level, caption :+ "(EXPANDED): line " :+ token_line :+ "[" :+ pptid :+ "]: " :+ token_text :+ " => " :+ tag_get_token_type_name(token_type));
      }
      pptid = tag_get_next_token(pptid);
   }
   return endtid;
}

static int tag_dump_embedded_tokens(int tid, _str caption, int level)
{
   if (level > 256) return tid;
   orig_tid := tid;
   emtid := tag_get_first_token(tid);
   if (emtid <= 0) {
      return tid;
   }
   endtid := tid;
   while (tid > 0) {
      if (tag_get_first_token(tid) != emtid) break;
      tag_get_token_info(tid, auto token_type, auto token_text, auto token_seek, auto token_line);
      isay(level-1, caption :+ "(EMBEDDED): line " :+ token_line :+ "[" :+ tid :+ "]: " :+ token_text :+ " => " :+ tag_get_token_type_name(token_type));
      endtid = tid;
      tid = tag_get_next_token(tid);
   }
   while (emtid > 0 && emtid != orig_tid) {
      orig_emtid := emtid;
      emtid = tag_dump_embedded_tokens(emtid, caption, level+1);
      emtid = tag_dump_preprocessed_tokens(emtid, caption, level+1);
      if (emtid == orig_emtid) {
         tag_get_token_info(emtid, auto token_type, auto token_text, auto token_seek, auto token_line);
         isay(level, caption :+ "(EXPANDED): line " :+ token_line :+ "[" :+ emtid :+ "]: " :+ token_text :+ " => " :+ tag_get_token_type_name(token_type));
      }
      emtid = tag_get_next_token(emtid);
   }
   return endtid;
}

/**
 * Print out the full contents of the token list for the current context
 */
_command void tag_dump_token_list(_str caption="TOKENS", int level=0)
{
   isay(level, caption :+ "==================================================");
   _UpdateContext(true,false,VS_UPDATEFLAG_context|VS_UPDATEFLAG_tokens);
   tid := tag_get_first_token();
   while (tid > 0) {
      orig_tid := tid;
      tid = tag_dump_embedded_tokens(tid, caption, level+1);
      tid = tag_dump_preprocessed_tokens(tid, caption, level+1);
      if (tid == orig_tid) {
         tag_get_token_info(tid, auto token_type, auto token_text, auto token_seek, auto token_line);
         isay(level, caption :+ " line " :+ token_line :+ "[" :+ tid :+ "]: " :+ token_text :+ " => " :+ tag_get_token_type_name(token_type));
      }
      tid = tag_get_next_token(tid);
   }
   isay(level, caption :+ "==================================================");
   tid = tag_get_current_token((int)_QROffset());
   if (tid > 0) {
      isay(level, caption :+ " CURRENT TOKEN, line=" :+ p_RLine :+ " offset=" :+ _QROffset());
      tag_get_token_info(tid, auto token_type, auto token_text, auto token_seek, auto token_line);
      isay(level, caption :+ " line " :+ token_line :+ "[" :+ tid :+ "]: " :+ token_text :+ " => " :+ tag_get_token_type_name(token_type));
   } else {
      isay(level, caption :+ " NO CURRENT TOKEN, line=" :+ p_RLine :+ " offset=" :+ _QROffset());
   }
   isay(level, caption :+ "==================================================");
}

/**
 * Return a string representing a bit set of tag flags (SE_TAG_FLAG_*) 
 *  
 * @param flags   bitset of SE_TAG_FLAG_* 
 */
_str tag_dump_tag_flags(SETagFlags tag_flags)
{
   flags := "";
   if (tag_flags == 0) return "(none)";
   if (tag_flags == SE_TAG_FLAG_PACKAGE) return "(package)";
   if(tag_flags & SE_TAG_FLAG_VIRTUAL)      flags :+= "virtual |";
   if(tag_flags & SE_TAG_FLAG_STATIC)       flags :+= "static |";
   if(tag_flags & SE_TAG_FLAG_ACCESS) {
      switch (tag_flags & SE_TAG_FLAG_ACCESS) {
      case SE_TAG_FLAG_PUBLIC:
         strappend(flags,"public |");
         break;
      case SE_TAG_FLAG_PACKAGE:
         //strappend(before_return,'package ');
         // package is default scope for Java
         break;
      case SE_TAG_FLAG_PROTECTED:
         strappend(flags,"protected |");
         break;
      case SE_TAG_FLAG_PRIVATE:
         strappend(flags,"private |");
         break;
      }
   }
   if (tag_flags & SE_TAG_FLAG_INTERNAL)     flags :+= "internal |";
   if (tag_flags & SE_TAG_FLAG_CONST)        flags :+= "const |";
   if (tag_flags & SE_TAG_FLAG_CONSTEXPR)    flags :+= "constexpr |";
   if (tag_flags & SE_TAG_FLAG_CONSTEVAL)    flags :+= "consteval |";
   if (tag_flags & SE_TAG_FLAG_CONSTINIT)    flags :+= "constinit |";
   if (tag_flags & SE_TAG_FLAG_EXPORT)       flags :+= "export |";
   if (tag_flags & SE_TAG_FLAG_FINAL)        flags :+= "final |";
   if (tag_flags & SE_TAG_FLAG_ABSTRACT)     flags :+= "abstract |";
   if (tag_flags & SE_TAG_FLAG_INLINE)       flags :+= "inline |";
   if (tag_flags & SE_TAG_FLAG_OPERATOR)     flags :+= "operator |";
   if (tag_flags & SE_TAG_FLAG_CONSTRUCTOR)  flags :+= "constructor |";
   if (tag_flags & SE_TAG_FLAG_VOLATILE)     flags :+= "volatile |";
   if (tag_flags & SE_TAG_FLAG_TEMPLATE)     flags :+= "template |";
   if (tag_flags & SE_TAG_FLAG_INCLASS)      flags :+= "inclass |";
   if (tag_flags & SE_TAG_FLAG_DESTRUCTOR)   flags :+= "destructor |";
   if (tag_flags & SE_TAG_FLAG_SYNCHRONIZED) flags :+= "synchronized |";
   if (tag_flags & SE_TAG_FLAG_TRANSIENT)    flags :+= "transient |";
   if (tag_flags & SE_TAG_FLAG_NATIVE)       flags :+= "native |";
   if (tag_flags & SE_TAG_FLAG_MACRO)        flags :+= "macro |";
   if (tag_flags & SE_TAG_FLAG_EXTERN)       flags :+= "extern |";
   if (tag_flags & SE_TAG_FLAG_MAYBE_VAR)    flags :+= "maybe_var |";
   if (tag_flags & SE_TAG_FLAG_ANONYMOUS)    flags :+= "anonymous |";
   if (tag_flags & SE_TAG_FLAG_MUTABLE)      flags :+= "mutable |";
   if (tag_flags & SE_TAG_FLAG_EXTERN_MACRO) flags :+= "extern_macro |";
   if (tag_flags & SE_TAG_FLAG_LINKAGE)      flags :+= "linkage |";
   if (tag_flags & SE_TAG_FLAG_PARTIAL)      flags :+= "partial |";
   if (tag_flags & SE_TAG_FLAG_IGNORE)       flags :+= "ignore |";
   if (tag_flags & SE_TAG_FLAG_FORWARD)      flags :+= "forward |";
   if (tag_flags & SE_TAG_FLAG_OPAQUE)       flags :+= "opaque |";
   if (tag_flags & SE_TAG_FLAG_IMPLICIT)     flags :+= "implicit |";
   if (tag_flags & SE_TAG_FLAG_UNSCOPED)     flags :+= "unscoped |";
   if (tag_flags & SE_TAG_FLAG_OUTLINE_ONLY) flags :+= "outline |";
   if (tag_flags & SE_TAG_FLAG_OUTLINE_HIDE) flags :+= "hide |";
   if (tag_flags & SE_TAG_FLAG_OVERRIDE)     flags :+= "override |";
   if (tag_flags & SE_TAG_FLAG_SHADOW)       flags :+= "shadow |";
   if (tag_flags & SE_TAG_FLAG_INFERRED)     flags :+= "inferred |";
   if (tag_flags & SE_TAG_FLAG_NO_COMMENT)   flags :+= "no_comment |";
   return substr(flags, 1, length(flags)-2);
}

/**
 * Print tag browse info to the SlickEdit debug window.
 * 
 * @param cm      browse info structure
 * @param where   string representing where this was printed from
 * 
 * @see say
 * 
 * @categories Tagging_Functions
 */
void tag_browse_info_dump(struct VS_TAG_BROWSE_INFO cm, _str where = "", int level=0)
{
   isay(level,"//=================================================================");
   isay(level,"// Browse info from " where);
   isay(level,"//=================================================================");

   if (cm==null) {
      isay(level,"cm=null");
      return;
   }

   // always print general information
   isay(level,"cm.member_name=" cm.member_name);
   isay(level,"cm.class_name=" cm.class_name);
   if (cm.type_name != "") {
      isay(level,"cm.type_name=" cm.type_name);
   } else if (cm._length()>=25 && cm.type_id != SE_TAG_TYPE_NULL) {
      tag_get_type(cm.type_id, auto type_name);
      isay(level,"cm.type_name=" type_name);
   }
   flags := tag_dump_tag_flags(cm.flags);
   isay(level,"cm.flags=" flags);

   // always print file, line, seekpos
   isay(level,"cm.file_name=" cm.file_name);
   isay(level,"cm.line_no=" cm.line_no);
   isay(level,"cm.seekpos=" cm.seekpos);
   if (cm.column_no > 0) isay(level,"cm.column_no=" cm.column_no);

   // print other location info if we have it
   if (cm.name_line_no > 0) {
      isay(level,"cm.name_line_no=" cm.name_line_no);
      isay(level,"cm.name_seekpos=" cm.name_seekpos);
   }
   if (cm.scope_line_no > 0) {
      isay(level,"cm.scope_line_no=" cm.scope_line_no);
      isay(level,"cm.scope_seekpos=" cm.scope_seekpos);
   }
   if (cm.end_line_no > 0 || cm.name_line_no > 0 || cm.scope_line_no > 0) {
      isay(level,"cm.end_line_no=" cm.end_line_no);
      isay(level,"cm.end_seekpos=" cm.end_seekpos);
   }
   if (cm._length()>=26 && cm.tagged_line_no > 0) {
      isay(level,"cm.tagged_line_no=" cm.tagged_line_no);
   }
   if (cm._length()>=28 && cm.tagged_date > 0) {
      isay(level,"cm.tagged_date=" cm.tagged_date);
   }

   // only print other details if we have them
   if (length(cm.language)       > 0) isay(level,"cm.language=" cm.language);
   if (length(cm.tag_database)   > 0) isay(level,"cm.tag_database=" cm.tag_database);
   if (length(cm.return_type)    > 0) isay(level,"cm.return_type=" cm.return_type);
   if (length(cm.arguments)      > 0) isay(level,"cm.arguments=" cm.arguments);
   if (length(cm.exceptions)     > 0) isay(level,"cm.exceptions=" cm.exceptions);
   if (length(cm.class_parents)  > 0) isay(level,"cm.class_parents="cm.class_parents);
   if (length(cm.template_args)  > 0) isay(level,"cm.template_args="cm.template_args);
   if (length(cm.qualified_name) > 0) isay(level,"cm.qualified_name=" cm.qualified_name);
   if (length(cm.category)       > 0) isay(level,"cm.category=" cm.category);
   if (cm._length()>=24 && length(cm.doc_comments) > 0) {
      if (cm._length()>=27 && cm.doc_type > 0) {
         isay(level,"cm.doc_type="tag_dump_doc_type(cm.doc_type));
      }
      split(cm.doc_comments, "\n", auto doc_lines);
      foreach (auto s in doc_lines) {
         isay(level,"cm.doc_comments="s);
      }
   }
}

_str tag_dump_doc_type(SETagDocCommentType doc_type)
{
   pszDocType := "";
   switch (doc_type) {
   case SE_TAG_DOCUMENTATION_PLAIN_TEXT:
      pszDocType = "PLAIN_TEXT";
      break;
   case SE_TAG_DOCUMENTATION_FIXED_FONT_TEXT:
      pszDocType = "FIXED_TEXT";
      break;
   case SE_TAG_DOCUMENTATION_HTML:
      pszDocType = "HTML";
      break;
   case SE_TAG_DOCUMENTATION_RAW_JAVADOC:
      pszDocType = "RAW_JAVADOC";
      break;
   case SE_TAG_DOCUMENTATION_RAW_DOXYGEN:
      pszDocType = "RAW_DOXYGEN";
      break;
   case SE_TAG_DOCUMENTATION_RAW_XMLDOC:
      pszDocType = "RAW_XMLDOC";
      break;
   case SE_TAG_DOCUMENTATION_JAVADOC:
      pszDocType = "JAVADOC";
      break;
   case SE_TAG_DOCUMENTATION_DOXYGEN:
      pszDocType = "DOXYGEN";
      break;
   case SE_TAG_DOCUMENTATION_XMLDOC:
      pszDocType = "XMLDOC";
      break;
   default:
      pszDocType = "UNKNOWN";
      break;
   }
   return pszDocType;
}

void tag_dump_context_flags(SETagContextFlags context_flags, _str where = "", int level=0)
{
   flags := "";
   if (context_flags & SE_TAG_CONTEXT_ALLOW_LOCALS      ) flags :+= "ALLOW_locals |";
   if (context_flags & SE_TAG_CONTEXT_ALLOW_PRIVATE     ) flags :+= "ALLOW_private |";
   if (context_flags & SE_TAG_CONTEXT_ALLOW_PROTECTED   ) flags :+= "ALLOW_protected |";
   if (context_flags & SE_TAG_CONTEXT_ALLOW_PACKAGE     ) flags :+= "ALLOW_package |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_VOLATILE     ) flags :+= "ONLY_volatile |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_CONST        ) flags :+= "ONLY_const |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_STATIC       ) flags :+= "ONLY_static |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_NON_STATIC   ) flags :+= "ONLY_non_static |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_DATA         ) flags :+= "ONLY_data |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_FUNCS        ) flags :+= "ONLY_funcs |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_CLASSES      ) flags :+= "ONLY_classes |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_PACKAGES     ) flags :+= "ONLY_packages |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_INCLASS      ) flags :+= "ONLY_inclass |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_CONSTRUCTORS ) flags :+= "ONLY_constructors |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_THIS_CLASS   ) flags :+= "ONLY_this_class |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_PARENTS      ) flags :+= "ONLY_parents |";
   if (context_flags & SE_TAG_CONTEXT_FIND_DERIVED      ) flags :+= "FIND_derived |";
   if (context_flags & SE_TAG_CONTEXT_ALLOW_ANONYMOUS   ) flags :+= "ALLOW_anonymous |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_LOCALS       ) flags :+= "ONLY_locals |";
   if (context_flags & SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE) flags :+= "ALLOW_any_tag_type |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_FINAL        ) flags :+= "ONLY_final |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_NON_FINAL    ) flags :+= "ONLY_non_final |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_CONTEXT      ) flags :+= "ONLY_context |";
   if (context_flags & SE_TAG_CONTEXT_NO_GLOBALS        ) flags :+= "NO_globals |";
   if (context_flags & SE_TAG_CONTEXT_ALLOW_FORWARD     ) flags :+= "ALLOW_forward |";
   if (context_flags & SE_TAG_CONTEXT_FIND_LENIENT      ) flags :+= "FIND_lenient |";
   if (context_flags & SE_TAG_CONTEXT_FIND_ALL          ) flags :+= "FIND_all |";
   if (context_flags & SE_TAG_CONTEXT_FIND_PARENTS      ) flags :+= "FIND_parents |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_TEMPLATES    ) flags :+= "ONLY_templates |";
   if (context_flags & SE_TAG_CONTEXT_NO_SELECTORS      ) flags :+= "NO_selectors |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_THIS_FILE    ) flags :+= "ONLY_this_file |";
   if (context_flags & SE_TAG_CONTEXT_NO_GROUPS         ) flags :+= "NO_groups |";
   if (context_flags & SE_TAG_CONTEXT_ACCESS_PRIVATE    ) flags :+= "ACCESS_private |";
   if (context_flags & SE_TAG_CONTEXT_ACCESS_PROTECTED  ) flags :+= "ACCESS_protected |";
   if (context_flags & SE_TAG_CONTEXT_ACCESS_PACKAGE    ) flags :+= "ACCESS_package |";
   if (context_flags & SE_TAG_CONTEXT_ACCESS_PUBLIC     ) flags :+= "ACCESS_public |";
   if (context_flags & SE_TAG_CONTEXT_MATCH_FIRST_CHAR  ) flags :+= "first_char |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_WORKSPACE    ) flags :+= "ONLY_workspace |";
   if (context_flags & SE_TAG_CONTEXT_INCLUDE_AUTO_UPDATED) flags :+= "INCLUDE_auto_updated |";
   if (context_flags & SE_TAG_CONTEXT_INCLUDE_COMPILER  ) flags :+= "INCLUDE_compiler |";
   if (context_flags & SE_TAG_CONTEXT_ONLY_EXPORT       ) flags :+= "ONLY_export |";

   switch (context_flags & SE_TAG_CONTEXT_MATCH_STRATEGY_FLAGS) {
   case SE_TAG_CONTEXT_MATCH_STSK_SUBWORD: flags :+= "subword |"; break;
   case SE_TAG_CONTEXT_MATCH_STSK_ACRONYM: flags :+= "acronym |"; break;
   case SE_TAG_CONTEXT_MATCH_STSK_PURE:    flags :+= "pure |";    break;
   case SE_TAG_CONTEXT_MATCH_SUBSTRING:    flags :+= "substring |"; break;
   case SE_TAG_CONTEXT_MATCH_SUBWORD:      flags :+= "subword1 |";  break;
   case SE_TAG_CONTEXT_MATCH_CHAR_BITSET:  flags :+= "bitset |";  break;
   }

   if (flags != "") {
      // Take out last ' |'
      flags = substr(flags, 1, length(flags)-2);
   }
   isay(level, where:+".context_flags=":+flags);
}

void tag_dump_filter_flags(SETagFilterFlags filter_flags, _str where = "", int level=0)
{
   // general flags
   flags := "";
   if (filter_flags & SE_TAG_FILTER_CASE_SENSITIVE  ) flags :+= "CASESENSITIVE |";
   if (filter_flags & SE_TAG_FILTER_NO_BINARY       ) flags :+= "NOBINARY |";

   // anything is allowed
   if ((filter_flags & SE_TAG_FILTER_ANYTHING) == SE_TAG_FILTER_ANYTHING) {
      flags :+= "ANYTHING |";
   } else {

      // any symbol, but scope can differ
      if ((filter_flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_ANY_SYMBOL) {
         flags :+= "ANYSYMBOL |";

      } else {

         // any function or prototype
         if ((filter_flags & SE_TAG_FILTER_ANY_PROCEDURE) == SE_TAG_FILTER_ANY_PROCEDURE) {
            flags :+= "ANYPROC |";
         } else {
            if (filter_flags & SE_TAG_FILTER_PROCEDURE           ) flags :+= "PROC |";
            if (filter_flags & SE_TAG_FILTER_PROTOTYPE          ) flags :+= "PROTO |";
            if (filter_flags & SE_TAG_FILTER_SUBPROCEDURE        ) flags :+= "SUBPROC |";
         }

         // any type of variable
         if ((filter_flags & SE_TAG_FILTER_ANY_DATA) == SE_TAG_FILTER_ANY_DATA) {
            flags :+= "ANYDATA |";
         } else {
            if (filter_flags & SE_TAG_FILTER_GLOBAL_VARIABLE           ) flags :+= "GVAR |";
            if (filter_flags & SE_TAG_FILTER_MEMBER_VARIABLE            ) flags :+= "VAR |";
            if (filter_flags & SE_TAG_FILTER_LOCAL_VARIABLE           ) flags :+= "LVAR |";
            if (filter_flags & SE_TAG_FILTER_PROPERTY       ) flags :+= "PROPERTY |";
         }

         // any type of constant
         if ((filter_flags & SE_TAG_FILTER_ANY_CONSTANT) == SE_TAG_FILTER_ANY_CONSTANT) {
            flags :+= "ANYCONSTANT |";
         } else {
            if (filter_flags & SE_TAG_FILTER_DEFINE         ) flags :+= "DEFINE |";
            if (filter_flags & SE_TAG_FILTER_ENUM           ) flags :+= "ENUM |";
            if (filter_flags & SE_TAG_FILTER_CONSTANT       ) flags :+= "CONSTANT |";
         }

         // any type of struct
         if ((filter_flags & SE_TAG_FILTER_ANY_STRUCT) == SE_TAG_FILTER_ANY_STRUCT) {
            flags :+= "ANYSTRUCT |";
         } else {
            if (filter_flags & SE_TAG_FILTER_STRUCT         ) flags :+= "STRUCT |";
            if (filter_flags & SE_TAG_FILTER_UNION          ) flags :+= "UNION |";
            if (filter_flags & SE_TAG_FILTER_INTERFACE      ) flags :+= "INTERFACE |";
         }

         if (filter_flags & SE_TAG_FILTER_TYPEDEF        ) flags :+= "TYPEDEF |";
         if (filter_flags & SE_TAG_FILTER_LABEL          ) flags :+= "LABEL |";
         if (filter_flags & SE_TAG_FILTER_PACKAGE        ) flags :+= "PACKAGE |";
         if (filter_flags & SE_TAG_FILTER_MISCELLANEOUS  ) flags :+= "MISCELLANEOUS |";
         if (filter_flags & SE_TAG_FILTER_DATABASE       ) flags :+= "DATABASE |";
         if (filter_flags & SE_TAG_FILTER_GUI            ) flags :+= "GUI |";
         if (filter_flags & SE_TAG_FILTER_INCLUDE        ) flags :+= "INCLUDE |";
         if (filter_flags & SE_TAG_FILTER_UNKNOWN        ) flags :+= "UNKNOWN |";
      }

      // statements and annotations
      if (filter_flags & SE_TAG_FILTER_STATEMENT      ) flags :+= "STATEMENT |";
      if (filter_flags & SE_TAG_FILTER_ANNOTATION     ) flags :+= "ANNOTATION |";

      if ((filter_flags & SE_TAG_FILTER_ANY_SCOPE) == SE_TAG_FILTER_ANY_SCOPE) {
         // any scope
         flags :+= "ANYSCOPE |";
      } else if ((filter_flags & SE_TAG_FILTER_ANY_ACCESS) == SE_TAG_FILTER_ANY_ACCESS) {
         // public, protected, private, or whatever
         flags :+= "ANYACCESS |";
         if (filter_flags & SE_TAG_FILTER_SCOPE_STATIC   ) flags :+= "SCOPE_STATIC |";
         if (filter_flags & SE_TAG_FILTER_SCOPE_EXTERN   ) flags :+= "SCOPE_EXTERN |";
      } else {
         // specific scopes
         if (filter_flags & SE_TAG_FILTER_SCOPE_STATIC   ) flags :+= "SCOPE_STATIC |";
         if (filter_flags & SE_TAG_FILTER_SCOPE_EXTERN   ) flags :+= "SCOPE_EXTERN |";
         if (filter_flags & SE_TAG_FILTER_SCOPE_PRIVATE  ) flags :+= "SCOPE_PRIVATE |";
         if (filter_flags & SE_TAG_FILTER_SCOPE_PROTECTED) flags :+= "SCOPE_PROTECTED |";
         if (filter_flags & SE_TAG_FILTER_SCOPE_PACKAGE  ) flags :+= "SCOPE_PACKAGE |";
         if (filter_flags & SE_TAG_FILTER_SCOPE_PUBLIC   ) flags :+= "SCOPE_PUBLIC |";
      }

   }

   if (flags != "") {
      // Take out last ' |'
      flags = substr(flags, 1, length(flags)-2);
   }
   isay(level,where:+".filter_flags=":+flags);
}

void tag_autocode_arg_info_init(VSAUTOCODE_ARG_INFO &arg_info)
{
   arg_info.ParamName="";
   arg_info.ParamNum=0;
   arg_info.ParamType="";
   arg_info.ParamKeyword="";
   arg_info.prototype="";
   arg_info.arglength._makeempty();
   arg_info.argstart._makeempty();
   arg_info.tagList._makeempty();
}

void tag_autocode_arg_info_from_browse_info(VSAUTOCODE_ARG_INFO &arg_info, VS_TAG_BROWSE_INFO &cm, _str prototype=null, VS_TAG_RETURN_TYPE &rt=null)
{
   arg_info.ParamName="";
   arg_info.ParamNum=0;
   arg_info.ParamType="";
   arg_info.ParamKeyword="";
   arg_info.prototype="";
   arg_info.arglength._makeempty();
   arg_info.argstart._makeempty();
   arg_info.tagList._makeempty();

   if (prototype == null) {
      prototype = tag_make_caption_from_browse_info(cm, include_class:true, include_args:true, include_tab:false);
   }
   arg_info.prototype = prototype;

   arg_info.tagList[0].filename = cm.file_name;
   arg_info.tagList[0].linenum  = cm.line_no;
   arg_info.tagList[0].comment_flags = 0;
   arg_info.tagList[0].comments = null;
   if (length(cm.doc_comments) > 0) {
      arg_info.tagList[0].comments = cm.doc_comments;
   }
   arg_info.tagList[0].taginfo = tag_compose_tag_browse_info(cm);
   arg_info.tagList[0].browse_info = cm;
   arg_info.tagList[0].class_type = rt;
}

void tag_autocode_arg_info_add_browse_info_to_tag_list(VSAUTOCODE_ARG_INFO &arg_info, VS_TAG_BROWSE_INFO &cm, VS_TAG_RETURN_TYPE &rt=null)
{
   i := arg_info.tagList._length();
   arg_info.tagList[i].filename = cm.file_name;
   arg_info.tagList[i].linenum  = cm.line_no;
   arg_info.tagList[i].comment_flags = 0;
   arg_info.tagList[i].comments = null;
   arg_info.tagList[i].taginfo = tag_compose_tag_browse_info(cm);
   arg_info.tagList[i].browse_info = cm;
   arg_info.tagList[i].class_type = rt;
}

void tag_autocode_arg_info_dump(VSAUTOCODE_ARG_INFO arg_info, _str where = "", int level=0)
{
   int k;
   isay(level,"//=================================================================");
   isay(level,"// VSAUTOCODE_ARG_INFO from " where);
   isay(level,"//=================================================================");

   isay(level,"   ParamName="arg_info.ParamName);
   isay(level,"   ParamNum="arg_info.ParamNum);
   isay(level,"   ParamType="arg_info.ParamType);
   isay(level,"   ParamKeyword="arg_info.ParamKeyword);
   isay(level,"   prototype="arg_info.prototype);

   isay(level,"   arglength length="arg_info.arglength._length());
   for(k=0; k < arg_info.arglength._length(); k++) {
      isay(level,"             arglength["k"]="arg_info.arglength[k]);
   }

   isay(level,"     argstart length="arg_info.argstart._length());
   for(k=0; k < arg_info.argstart._length(); k++) {
      isay(level,"             argstart["k"]="arg_info.argstart[k]);
   }

   isay(level,"     tagList length="arg_info.tagList._length());
   for(k=0; k < arg_info.tagList._length(); k++) {
      isay(level,"             tagList["k"].comment_flags="arg_info.tagList[k].comment_flags);
      //isay(level,"             tagList["k"].comments="arg_info.tagList[k].comments);
      isay(level,"             tagList["k"].filename="arg_info.tagList[k].filename);
      isay(level,"             tagList["k"].linenum="arg_info.tagList[k].linenum);
      isay(level,"             tagList["k"].taginfo="arg_info.tagList[k].taginfo);
      if (arg_info.tagList[k].browse_info != null) {
         isay(level,"             tagList["k"].browse_infoname="arg_info.tagList[k].browse_info.member_name);
      }
      if (arg_info.tagList[k].class_type != null) {
         isay(level,"             tagList["k"].class_type="arg_info.tagList[k].class_type.return_type);
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
/**
 * Initialize a return type information structure.
 * 
 * @param rt   return type structure to initialize
 * 
 * @categories Tagging_Functions
 */
void tag_return_type_init(struct VS_TAG_RETURN_TYPE &rt)
{
   rt.return_type="";
   rt.taginfo="";
   rt.filename="";
   rt.line_number=0;
   rt.pointer_count=0;
   rt.return_flags=0;
   rt.istemplate=false;
   rt.isvariadic=false;
   rt.template_args._makeempty();
   rt.template_names._makeempty();
   rt.template_types._makeempty();
   rt.alt_return_types._makeempty();
}

/**
 * @return Create a string representation for the given return type.
 * 
 * @param rt               return type structure to convert
 * @param printArgNames    print template arguments
 * 
 * @categories Tagging_Functions
 */
_str tag_return_type_string(struct VS_TAG_RETURN_TYPE &rt, bool printArgNames=true, int depth=0)
{
   if (rt == null) return "";
   result := rt.return_type;
   if (rt.template_names._length() > 0) {
      if (length(result) <= 0) result="template";
      result :+= "<";
      for (i:=0; i<rt.template_names._length(); ++i) {
         el := rt.template_names[i];
         if (i > 0) result :+= ",";
         if (printArgNames) {
            result :+= el"=";
         }
         arg_type := el;
         if (rt.template_args._indexin(el) && rt.template_args:[el] != null) {
            arg_type = rt.template_args:[el];
         } else if (rt.template_types._indexin(el) && rt.template_types:[el] != null && depth < 8) {
            arg_type = tag_return_type_string(rt, printArgNames:false, depth+1);
         }
         result :+= arg_type;
      }
      result :+= ">";
   } else if (rt.template_args._length() > 0) {
      if (length(result) <= 0) result="template";
      result :+= "<";
      foreach (auto tn => auto tt in rt.template_args) {
         result :+= tn"="tt;
      }
      result :+= ">";
   }
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES) {
      if (rt.pointer_count >= 2) {
         result :+= substr("", 1, rt.pointer_count-1, "*");
      }
      result :+= "[]";
      rt.pointer_count=0;
   } else if (rt.pointer_count > 0) {
      result :+= substr("", 1, rt.pointer_count, "*");
   }
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_REF) {
      result :+= " &";
   }
   //if (rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY) {
   //   result = "const " :+ result;;
   //}

   return result;
}

/**
 * Compare two return type info sets for equality.
 * This function does not support templates and ignore the match_tag.
 * 
 * @param rt1              first return type to compare
 * @param rt2              second return type to compare
 * @param case_sensitive   case sensitive comparison?
 * 
 * @return true if equal, false otherwise
 * 
 * @categories Tagging_Functions
 */
bool tag_return_type_equal(struct VS_TAG_RETURN_TYPE &rt1,
                           struct VS_TAG_RETURN_TYPE &rt2,
                           bool case_sensitive=true)
{
   // type must match exactly
   if ((case_sensitive && rt1.return_type:!=rt2.return_type) ||
       (!case_sensitive && strieq(rt1.return_type,rt2.return_type))) {
      return(false);
   }
   // pointers must match exactly
   if (rt1.pointer_count!=rt2.pointer_count) {
      return(false);
   }
   // return flags must match exactly
   if (rt1.return_flags!=rt2.return_flags) {
      return(false);
   }
   // don't even try to handle templates
   if (rt1.istemplate || rt2.istemplate) {
      return(false);
   }
   // count this as a match
   return(true);
}

/**
 * Dump a return type structure to the debug window.
 * 
 * @param rt      return type to dump
 * @param tag     prefix to append to output lines (usually function name)
 * @parma level   indentation level for 'isay'
 * 
 * @see say
 * @see isay
 * 
 * @categories Tagging_Functions
 */
void tag_return_type_dump(struct VS_TAG_RETURN_TYPE &rt, _str tag="", int level=0)
{
   flags := "";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS)  flags :+= " private |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY)      flags :+= " const |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY)   flags :+= " volatile |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY)     flags :+= " static |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY) flags :+= " non-static |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)    flags :+= " global |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY)           flags :+= " array |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_HASHTABLE)       flags :+= " hash |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_HASHTABLE2)      flags :+= " hash2 |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_OUT)             flags :+= " out |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_REF)             flags :+= " ref |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_IN)              flags :+= " in |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_INCLASS_ONLY)    flags :+= " inclass |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_FILES_ONLY)      flags :+= " files |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_FUNCS_ONLY)      flags :+= " functions |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_DATA_ONLY)       flags :+= " varaibles |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_BUILTIN)         flags :+= " builtin |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY) flags :+= " qualified |";
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_IS_FAKE)         flags :+= " fake |";
   if (flags != "") flags = substr(flags, 1, length(flags)-2);

   isay(level,tag": rt.return_type="rt.return_type);
   isay(level,tag": rt.pointer_count="rt.pointer_count);
   isay(level,tag": rt.return_flags="flags);
   isay(level,tag": rt.taginfo="rt.taginfo);
   isay(level,tag": rt.filename="rt.filename);
   isay(level,tag": rt.line_number="rt.line_number);
   isay(level,tag": rt.istemplate="rt.istemplate);
   if (rt.isvariadic != null) {
      isay(level,tag": rt.isvariadic="rt.isvariadic);
   }
   if (rt.template_names!=null) {
      for (i:=0; i<rt.template_names._length(); ++i) {
         _str el = rt.template_names[i];
         if (rt.template_args._indexin(el) && rt.template_types._indexin(el)) {
            isay(level,tag": rt.template_args:["el"]="rt.template_args:[el]" => "rt.template_types:[el].return_type" pointer count="rt.template_types:[el].pointer_count);
         } else if (rt.template_args._indexin(el)) {
            isay(level,tag": rt.template_args:["el"]="rt.template_args:[el]);
         } else {
            isay(level,tag": rt.template_args:["el"]=null");
         }
      }
   }
   if (rt.alt_return_types!=null) {
      for (i:=0; i<rt.alt_return_types._length(); ++i) {
         tag_return_type_dump(rt.alt_return_types[i], tag:+"::ALTERNATE["i"]", level);
      }
   }
}

/**
 * Merge the template arguments for the return type represented by 'outer_rt'
 * with the template arguments for the return type represented by 'rt'.
 * This is used to handle nested templates.
 * 
 * @param rt         return type to merge template arguments to
 * @param outer_rt   return type to mrege template arguments from
 * 
 * @categories Tagging_Functions
 */
void tag_return_type_merge_templates(struct VS_TAG_RETURN_TYPE &rt, 
                                     struct VS_TAG_RETURN_TYPE &outer_rt)
{
   if (outer_rt.istemplate && (outer_rt.return_type == rt.return_type || pos(outer_rt.return_type,rt.return_type)==1)) {
      foreach (auto el in outer_rt.template_names) {
         if ((!rt.template_args._indexin(el) || rt.template_args:[el]==null || rt.template_args:[el]=="" || rt.template_args:[el]==el) &&
             outer_rt.template_args._indexin(el) && outer_rt.template_args:[el]!=null && outer_rt.template_args:[el]!="" && outer_rt.template_args:[el]!=el) {
            rt.template_args:[el] = outer_rt.template_args:[el];
            if (outer_rt.template_types._indexin(el)) {
               rt.template_types:[el] = outer_rt.template_types:[el];
            }
         }
         if ((!rt.template_types._indexin(el) || rt.template_types:[el]==null || rt.template_types:[el].return_type=="" || rt.template_types:[el].return_type==el) &&
             outer_rt.template_types._indexin(el) && outer_rt.template_types:[el]!=null && outer_rt.template_types:[el].return_type!="" && outer_rt.template_types:[el].return_type!=el) {
            rt.template_types:[el] = outer_rt.template_types:[el];
         }
      }
   }
}

/**
 * Try to infer actual template argument types from the actual arguments passed 
 * to a template function and the formal arguments required by that function. 
 * 
 * @param template_arg_names   (input) list of function template argument names
 * @param template_args        (output) maps template argument names to template argument types
 * @param template_types       (output) maps template argument names to tempalte argument types (struct)
 * @param actual_rt            (input) array of function parameter types
 * @param formal_rt            (input) array of formal function parameter types 
 *  
 * @return Returns 'true' if it was able to infer any template arguments, false otherwise. 
 */
bool tag_return_type_infer_template_arguments(_str (&template_arg_names)[],
                                              _str (&template_args):[],
                                              VS_TAG_RETURN_TYPE (&template_types):[],
                                              VS_TAG_RETURN_TYPE &actual_rt,
                                              VS_TAG_RETURN_TYPE &formal_rt,
                                              bool is_variadic_template=false,
                                              int depth=0)
{
   if (_chdebug) {
      isay(depth, "tag_return_type_infer_template_arguments: IN");
      tag_return_type_dump(actual_rt, "tag_return_type_infer_template_arguments: actual", depth+1);
      tag_return_type_dump(formal_rt, "tag_return_type_infer_template_arguments: formal", depth+1);
   }
   if (actual_rt == null) return false;
   if (formal_rt == null) return false;
   new_template_arg_names := template_arg_names;

   got_one := false;
   foreach (auto argName in template_arg_names) {
      if (_chdebug) {
         isay(depth, "tag_return_type_infer_template_arguments: argName="argName" formal_rt.return_type="formal_rt.return_type);
      }
      if (tag_compare_classes(formal_rt.return_type, argName) == 0) {
         if (_chdebug) {
            isay(depth, "tag_return_type_infer_template_arguments: ARGUMENT MATCHES FORMAL RETURN TYPE");
         }
         arg_type := actual_rt;
         if (formal_rt.pointer_count > 0 && arg_type.pointer_count >= formal_rt.pointer_count) {
            arg_type.pointer_count -= formal_rt.pointer_count;
         }
         arg_type.return_flags = (arg_type.return_flags & ~(formal_rt.return_flags & actual_rt.return_flags));
         arg_type.return_flags &= ~(VSCODEHELP_RETURN_TYPE_OUT|VSCODEHELP_RETURN_TYPE_REF|VSCODEHELP_RETURN_TYPE_IN);
         template_args:[argName] = tag_return_type_string(arg_type);
         template_types:[argName] = arg_type;
         got_one = true;

      } else if (tag_compare_classes(formal_rt.return_type, actual_rt.return_type) == 0) {
         if (_chdebug) {
            isay(depth, "tag_return_type_infer_template_arguments: FORMAL RETURN TYPE MATCHES ACTUAL RETURN TYPE");
         }
         foreach (auto el in formal_rt.template_names) {
            if (_chdebug) {
               isay(depth, "tag_return_type_infer_template_arguments: el="el);
            }
            if (formal_rt.template_types._indexin(el) && actual_rt.template_types._indexin(el)) {
               got_nested := tag_return_type_infer_template_arguments(new_template_arg_names, 
                                                                      template_args, 
                                                                      template_types, 
                                                                      actual_rt.template_types:[el], 
                                                                      formal_rt.template_types:[el],
                                                                      formal_rt.isvariadic,
                                                                      depth+1); 
               if (got_nested) got_one = true;

               if (got_nested && is_variadic_template) {
                  i := 0;
                  loop {
                     ++i;
                     variadicArgName := el:+"+":+i;
                     if (_chdebug) {
                        isay(depth, "tag_return_type_infer_template_arguments: variadicArgName="variadicArgName);
                     }
                     if (!actual_rt.template_types._indexin(variadicArgName)) break;
                     arg_type := actual_rt.template_types:[variadicArgName];
                     fff_type := formal_rt.template_types:[el];
                     if (fff_type.pointer_count > 0 && arg_type.pointer_count >= fff_type.pointer_count) {
                        arg_type.pointer_count -= fff_type.pointer_count;
                     }
                     arg_type.return_flags = (arg_type.return_flags & ~(fff_type.return_flags & actual_rt.return_flags));
                     arg_type.return_flags &= ~(VSCODEHELP_RETURN_TYPE_OUT|VSCODEHELP_RETURN_TYPE_REF|VSCODEHELP_RETURN_TYPE_IN);
                     if (!template_args._indexin(variadicArgName)) {
                        new_template_arg_names :+= variadicArgName;
                     }
                     template_args:[variadicArgName] = tag_return_type_string(arg_type);
                     template_types:[variadicArgName] = arg_type;
                  }
               }
            }
         }
      }
   }

   template_arg_names = new_template_arg_names;
   if (_chdebug) {
      isay(depth, "tag_return_type_infer_template_arguments: OUT, got_one="got_one);
   }
   return got_one;
}


void _actapp_tagsdb(_str arg1="")
{
   index := find_index("tag_clear_class_name_caches",COMMAND_TYPE|PROC_TYPE);
   if (index_callable(index)) {
      call_index(def_tag_max_class_name_cache, index);
   }
}

/** 
 * Record amount of time updating the current context for the given file.
 *  
 * @param file_name     full path of file updated (usually p_buf_name) 
 * @param lang          language mode 
 * @param size          file size 
 * @param num_tags      number of tags found by list-tags or proc-search 
 * @param ms            number of milliseconds spent parsing 
 * @param ltf_flags     list tags flags (VSLTF_*), to distinguish statement tagging 
 *                      from updating current context or token list. 
 */ 
static void update_context_add_stats(_str file_name, 
                                     _str lang, 
                                     long size,
                                     int num_tags,
                                     long ms, 
                                     int ltf_flags)
{
   UPDATE_CONTEXT_STAT_PACK cts_pack;
   cts_pack.m_num_runs = 1;
   cts_pack.m_num_tags = num_tags;
   cts_pack.m_run_time_sum = ms;
   cts_pack.m_run_time_avg = ms;
   cts_pack.m_run_time_min = ms;
   cts_pack.m_run_time_max = ms;

   fc_file_name := _file_case(file_name);
   UPDATE_CONTEXT_STATS *pCTS = gUpdateContextStats._indexin(fc_file_name);
   if (pCTS) {
      UPDATE_CONTEXT_STAT_PACK *pCTSP = null;
      if (ltf_flags & VSLTF_LIST_STATEMENTS) {
         if (pCTS->m_statements == null) {
            pCTS->m_statements = cts_pack;
            return;
         }
         pCTSP = &pCTS->m_statements;
      } else if (ltf_flags & VSLTF_SAVE_TOKENLIST) {
         if (pCTS->m_tokens == null) {
            pCTS->m_tokens = cts_pack;
            return;
         }
         pCTSP = &pCTS->m_tokens;
      } else {
         if (pCTS->m_context == null) {
            pCTS->m_context = cts_pack;
            return;
         }
         pCTSP = &pCTS->m_context;
      }
      pCTS->m_file_size = size;
      pCTSP->m_num_runs++;
      pCTSP->m_num_tags = num_tags;
      pCTSP->m_run_time_sum += ms;
      pCTSP->m_run_time_avg = (pCTSP->m_run_time_sum intdiv pCTSP->m_num_runs);
      if (ms > pCTSP->m_run_time_max) pCTSP->m_run_time_max = ms;
      if (ms < pCTSP->m_run_time_min) pCTSP->m_run_time_min = ms;
      return;
   }

   UPDATE_CONTEXT_STATS cts;
   cts.m_file_name = file_name;
   cts.m_file_lang = lang;
   cts.m_file_size = size;

   cts.m_context = null;
   cts.m_statements = null;
   cts.m_tokens = null;

   if (ltf_flags & VSLTF_LIST_STATEMENTS) {
      cts.m_statements = cts_pack;
   } else if (ltf_flags & VSLTF_SAVE_TOKENLIST) {
      cts.m_tokens = cts_pack;
   } else {
      cts.m_context = cts_pack;
   }

   gUpdateContextStats:[fc_file_name] = cts;
}

/** 
 * @return 
 * Returns 'true' if the given file's update context statistics show that 
 * parsing for symbols is, on average, somewhat slow, that is, exceeding
 * {@link def_update_context_slow_ms} (by default, a half second).
 * 
 * @param file_name     For current context, usually p_buf_name 
 *  
 * @see _UpdateContext() 
 * @see codehelp_update_context_stats 
 *  
 * @categories Tagging_Functions 
 * @since 25.0
 */
bool _UpdateContextIsSlow(_str file_name=null)
{
   if (file_name == null && _isEditorCtl()) {
      file_name = p_buf_name;
   }
   fc_file_name := _file_case(file_name);
   UPDATE_CONTEXT_STATS *pCTS = gUpdateContextStats._indexin(fc_file_name);
   if (!pCTS) return false;

   if (pCTS->m_context != null) {
      return (pCTS->m_context.m_run_time_avg > def_update_context_slow_ms);
   }
   return false;
}
/** 
 * @return 
 * Returns 'true' if the given file's update context statistics show that 
 * parsing for symbols and building a token list is, on average, somewhat slow, 
 * that is, exceeding {@link def_update_context_slow_ms} 
 * (by default, a half second).
 * 
 * @param file_name     For current context, usually p_buf_name 
 *  
 * @see _UpdateContext() 
 * @see _UpdateContextAndTokens() 
 * @see codehelp_update_context_stats 
 *  
 * @categories Tagging_Functions 
 * @since 25.0
 */
bool _UpdateContextAndTokensIsSlow(_str file_name=null)
{
   if (file_name == null && _isEditorCtl()) {
      file_name = p_buf_name;
   }
   fc_file_name := _file_case(file_name);
   UPDATE_CONTEXT_STATS *pCTS = gUpdateContextStats._indexin(fc_file_name);
   if (!pCTS) return false;

   if (pCTS->m_tokens != null) {
      return (pCTS->m_tokens.m_run_time_avg > def_update_context_slow_ms);
   }
   if (pCTS->m_statements != null) {
      return (pCTS->m_statements.m_run_time_avg > def_update_context_slow_ms);
   }
   return false;
}
/** 
 * @return 
 * Returns 'true' if the given file's update context statistics show that 
 * parsing for statements is, on average, somewhat slow, that is, exceeding
 * {@link def_update_context_slow_ms} (by default, a half second).
 * 
 * @param file_name     For current context, usually p_buf_name 
 *  
 * @see _UpdateContext() 
 * @see _UpdateStatements() 
 * @see codehelp_update_context_stats 
 *  
 * @categories Tagging_Functions 
 * @since 25.0
 */
bool _UpdateStatementsIsSlow(_str file_name=null)
{
   if (file_name == null && _isEditorCtl()) {
      file_name = p_buf_name;
   }
   fc_file_name := _file_case(file_name);
   UPDATE_CONTEXT_STATS *pCTS = gUpdateContextStats._indexin(fc_file_name);
   if (!pCTS) return false;

   if (pCTS->m_tokens != null) {
      return (pCTS->m_tokens.m_run_time_avg > def_update_context_slow_ms);
   }
   if (pCTS->m_statements != null) {
      return (pCTS->m_statements.m_run_time_avg > def_update_context_slow_ms);
   }
   if (pCTS->m_context != null) {
      return (pCTS->m_context.m_run_time_avg > def_update_context_slow_ms);
   }
   return false;
}

/** 
 * @return 
 * Returns 'true' if the given file's update context statistics show that 
 * it can be parsed for symbols very fast, that is in less than 
 * {@link def_update_context_fast_ms} (by default, 100 milliseconds).
 * 
 * @param file_name     For current context, usually p_buf_name 
 *  
 * @see _UpdateContext() 
 * @see codehelp_update_context_stats 
 *  
 * @categories Tagging_Functions 
 * @since 25.0
 */
bool _UpdateContextIsFast(_str file_name=null)
{
   if (file_name == null && _isEditorCtl()) {
      file_name = p_buf_name;
   }
   fc_file_name := _file_case(file_name);
   UPDATE_CONTEXT_STATS *pCTS = gUpdateContextStats._indexin(fc_file_name);
   if (!pCTS) return false;

   max_time := 0L;
   if (pCTS->m_context != null) {
      max_time = pCTS->m_context.m_run_time_max;
   } else if (pCTS->m_tokens != null) {
      max_time = pCTS->m_tokens.m_run_time_max;
   } else if (pCTS->m_statements != null) {
      max_time = pCTS->m_statements.m_run_time_max;
   } else {
      return false;
   }

   return (max_time <= def_update_context_fast_ms);
}
/** 
 * @return 
 * Returns 'true' if the given file's update context statistics show that 
 * it can be parsed for symbols and building a token list very fast, that is, 
 * in less than {@link def_update_context_fast_ms} (by default, 100 milliseconds).
 * 
 * @param file_name     For current context, usually p_buf_name 
 *  
 * @see _UpdateContext() 
 * @see _UpdateContextAndTokens() 
 * @see codehelp_update_context_stats 
 *  
 * @categories Tagging_Functions 
 * @since 25.0
 */
bool _UpdateContextAndTokensIsFast(_str file_name=null)
{
   if (file_name == null && _isEditorCtl()) {
      file_name = p_buf_name;
   }
   fc_file_name := _file_case(file_name);
   UPDATE_CONTEXT_STATS *pCTS = gUpdateContextStats._indexin(fc_file_name);
   if (!pCTS) return false;

   max_time := 0L;
   if (pCTS->m_tokens != null) {
      max_time = pCTS->m_tokens.m_run_time_max;
   } else if (pCTS->m_statements != null) {
      max_time = pCTS->m_statements.m_run_time_max;
   } else if (pCTS->m_context != null) {
      max_time = 2*pCTS->m_context.m_run_time_max;
   } else {
      return false;
   }

   return (max_time <= def_update_context_fast_ms);
}
/** 
 * @return 
 * Returns 'true' if the given file's update context statistics show that 
 * it can be parsed for statements very fast, that is in less than 
 * {@link def_update_context_fast_ms} (by default, 100 milliseconds).
 * 
 * @param file_name     For current context, usually p_buf_name 
 *  
 * @see _UpdateContext() 
 * @see _UpdateStatements() 
 * @see codehelp_update_context_stats 
 *  
 * @categories Tagging_Functions 
 * @since 25.0
 */
bool _UpdateStatementsIsFast(_str file_name=null)
{
   if (file_name == null && _isEditorCtl()) {
      file_name = p_buf_name;
   }
   fc_file_name := _file_case(file_name);
   UPDATE_CONTEXT_STATS *pCTS = gUpdateContextStats._indexin(fc_file_name);
   if (!pCTS) return false;

   max_time := 0L;
   if (pCTS->m_statements != null) {
      max_time = pCTS->m_statements.m_run_time_max;
   } else if (pCTS->m_tokens != null) {
      max_time = 2*pCTS->m_tokens.m_run_time_max;
   } else if (pCTS->m_context != null) {
      max_time = 4*pCTS->m_context.m_run_time_max;
   } else {
      return false;
   }

   return (max_time <= def_update_context_fast_ms);
}

static _str codehelp_update_context_stats_cb(int sl_event, typeless user_data, typeless info=null)
{
   if (sl_event == SL_ONINITFIRST) {
      //select_tree_message("All times are in milliseconds.");
   }
   return "";
}

/**
 * Display the statistics collected for each file which _UpdateContext() 
 * was called on.  This is a debugging tool to help identify files that can 
 * cause certain operations to be more time-consuming while editing. 
 * 
 * @param cmd     One of the following: 
 *                <ul>
 *                <li><b>summary</b> -- print summary information (default)</li>
 *                <li><b>clear</b> -- clear current context tagging data</li>
 *                <li><b>context</b> -- display statistics for updating the current context</li>
 *                <li><b>statements</b> -- display statistics for updating statement tagging</li>
 *                <li><b>tokens</b> -- display statistics for updating the current context with token information</li>
 *                <li><b>dump -- dump all statistics to the vsdebug window</b>
 * </ul> 
 *  
 * @see _UpdateContext() 
 * @see _UpdateContextAndTokens() 
 * @see _UpdateStatements() 
 * @see _UpdateContextGetAverageTime()
 * @see _UpdateContextGetAverageTimeForStatements()
 * @see _UpdateContextGetAverageTimeForTokens()
 *  
 * @categories Tagging_Functions 
 * @since 25.0
 */
_command void codehelp_update_context_stats(_str cmd="") name_info(COMMAND_ARG',')
{
   UPDATE_CONTEXT_STATS cts;

   if (lowcase(cmd) == "clear") {
      gUpdateContextStats._makeempty();
      return;
   } else if (lowcase(cmd) == "dump") {
      foreach (cts in gUpdateContextStats) {
         say("codehelp_update_context_stats: "cts.m_file_name);
         say("codehelp_update_context_stats: lang="cts.m_file_lang);
         say("codehelp_update_context_stats: size="cts.m_file_size);
         if (cts.m_context != null) {
            _dump_var(cts.m_context, "   CONTEXT:");
         }
         if (cts.m_statements != null) {
            _dump_var(cts.m_statements, "   STATEMENTS:");
         }
         if (cts.m_tokens != null) {
            _dump_var(cts.m_tokens, "   TOKENS:");
         }
      }
      return;
   }

   pic_noop := _update_picture(-1, "_f_blank.svg");
   pic_slow := _update_picture(-1, "_f_stop.svg");
   pic_fast := _update_picture(-1, "_f_ok.svg");

   caption := "";
   _str lines[];
   int  icons[];
   doStatements := (substr(lowcase(cmd),1,3) == "sta");
   doTokens     := (substr(lowcase(cmd),1,3) == "tok");

   // print summary/overview of statistics information?
   if (cmd == "" || (substr(lowcase(cmd),1,3) == "sum")) {
      foreach (cts in gUpdateContextStats) {
         if (cts.m_file_name == null || cts.m_file_name == "") continue;
         item := cts.m_file_name;
         item :+= "\t";
         item :+= _LangId2Modename(cts.m_file_lang);
         item :+= "\t";
         item :+= cts.m_file_size;
         item :+= "\t";

         num_runs := 0;
         num_tags := 0;
         num_statements := 0;
         avg_context := 0L;
         avg_statements := 0L;
         avg_tokens := 0L;
         max_context := 0L;
         max_statements := 0L;
         max_tokens := 0L;
         
         if (cts.m_context != null) {
            num_runs += cts.m_context.m_num_runs;
            num_tags = cts.m_context.m_num_tags;
            avg_context = cts.m_context.m_run_time_avg;
            max_context = cts.m_context.m_run_time_max;
         }
         if (cts.m_statements != null) {
            num_runs += cts.m_statements.m_num_runs;
            num_statements = cts.m_statements.m_num_tags;
            avg_statements = cts.m_statements.m_run_time_avg;
            max_statements = cts.m_statements.m_run_time_max;
         }
         if (cts.m_tokens != null) {
            num_runs += cts.m_tokens.m_num_runs;
            avg_tokens = cts.m_tokens.m_run_time_avg;
            max_tokens = cts.m_tokens.m_run_time_max;
            if (!num_tags) num_tags = cts.m_tokens.m_num_tags;
         }

         if (num_runs <= 0) continue;

         item :+= num_tags;
         item :+= "\t";
         item :+= num_statements;
         item :+= "\t";
         item :+= num_runs;
         item :+= "\t";
         item :+= avg_context;
         item :+= "\t";
         item :+= max_context;
         item :+= "\t";
         item :+= avg_statements;
         item :+= "\t";
         item :+= max_statements;
         item :+= "\t";
         item :+= avg_tokens;
         item :+= "\t";
         item :+= max_tokens;
         lines :+= item;

         pic := pic_noop;
         if (_UpdateContextIsFast(cts.m_file_name)) {
            pic = pic_fast;
         } else if (_UpdateContextIsSlow(cts.m_file_name)) {
            pic = pic_slow;
         }
         icons :+= pic;
      }

      orig_view_id := p_window_id;   
      select_tree(cap_array:     lines,
                  picture_array: icons,
                  callback:      codehelp_update_context_stats_cb,
                  caption:       "Context Tagging "VSREGISTEREDTM" Statistics Summary",
                  sl_flags:      SL_CLOSEBUTTON|SL_COLWIDTH|SL_SIZABLE|SL_RESTORE_XY|SL_RESTORE_HEIGHT|SL_DEFAULTCALLBACK,
                  col_names:     "File,Language,File Size,Num Tags,Num Statements,Num Runs,Average Time,Max Time,Statements: Avg Time,Max Time,Tokens: Avg Time,Max Time",
                  col_flags:     (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_FILENAME|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_IS_FILENAME)",":+
                                 (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_FILENAME|TREE_BUTTON_PUSHBUTTON)",":+
                                 (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
                                 (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
                                 (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
                                 (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
                                 (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT|TREE_BUTTON_SORT|TREE_BUTTON_SORT_DESCENDING)",":+
                                 (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
                                 (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
                                 (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
                                 (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
                                 (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT),
                  modal:         false, 
                  retrieve_name: "context_tagging_stats",
                  message_text:  "All times are in milliseconds."
                 );
      activate_window(orig_view_id);
      return;
   }


   foreach (cts in gUpdateContextStats) {
      if (cts.m_file_name == null || cts.m_file_name == "") continue;
      item := cts.m_file_name;
      item :+= "\t";
      item :+= _LangId2Modename(cts.m_file_lang);
      item :+= "\t";
      item :+= cts.m_file_size;
      item :+= "\t";

      UPDATE_CONTEXT_STAT_PACK *pCTSP = null;
      if (doStatements) {
         if (cts.m_statements == null) continue;
         pCTSP = &cts.m_statements;
      } else if (doTokens) {
         if (cts.m_tokens == null) continue;
         pCTSP = &cts.m_tokens;
      } else {
         if (cts.m_context == null) continue;
         pCTSP = &cts.m_context;
      }
      
      if (pCTSP->m_num_runs <= 0) continue;
      item :+= pCTSP->m_num_tags;
      item :+= "\t";
      item :+= pCTSP->m_num_runs;
      item :+= "\t";
      item :+= pCTSP->m_run_time_avg;
      item :+= "\t";
      item :+= pCTSP->m_run_time_min;
      item :+= "\t";
      item :+= pCTSP->m_run_time_max;
      item :+= "\t";
      item :+= pCTSP->m_run_time_sum;
      lines :+= item;

      pic := pic_noop;
      if (pCTSP->m_run_time_max <= def_update_context_fast_ms) {
         pic = pic_fast;
      } else if (pCTSP->m_run_time_avg > def_update_context_slow_ms) {
         pic = pic_slow;
      }
      icons :+= pic;
   }
   if (doStatements) {
      caption = " (Statements)";
   } else if (doTokens) {
      caption = " (Tokens)";
   } else {
      caption = " (Context)";
   }

   orig_view_id := p_window_id;   
   select_tree(cap_array:     lines,
               picture_array: icons,
               callback:      codehelp_update_context_stats_cb,
               caption:       "Context Tagging "VSREGISTEREDTM" Statistics":+caption,
               sl_flags:      SL_CLOSEBUTTON|SL_COLWIDTH|SL_SIZABLE|SL_RESTORE_XY|SL_RESTORE_HEIGHT|SL_DEFAULTCALLBACK,
               col_names:     "File,Language,File Size,Num Tags,Num Runs,Average Time,Min Time,Max Time,Total Time",
               col_flags:     (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_FILENAME|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_IS_FILENAME)",":+
                              (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_FILENAME|TREE_BUTTON_PUSHBUTTON)",":+
                              (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
                              (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
                              (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
                              (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT|TREE_BUTTON_SORT|TREE_BUTTON_SORT_DESCENDING)",":+
                              (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
                              (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
                              (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT),
               modal:         false, 
               retrieve_name: "context_tagging_stats",
               message_text:  "All times are in milliseconds."
              );
   activate_window(orig_view_id);

}
