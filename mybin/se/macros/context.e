////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50415 $
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
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "mouse.e"
#import "notifications.e"
#import "slickc.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "util.e"
#import "toast.e"
#import "se/tags/TaggingGuard.e"
#endregion

//////////////////////////////////////////////////////////////////////////////
// global variables
//
#define CONTEXT_TB_FORM_NAME_STRING '_tbcontext_combo_etab'
#define CONTEXT_TOOLTIP_DELAYINC    100

#define PIC_LSPACE_Y   60    // Extra line spacing for list box.
#define PIC_LINDENT_X  150    // Indent before for list box bitmap.
#define PIC_RINDENT_X  40    // Indent after list box bitmap (hard-coded)

//////////////////////////////////////////////////////////////////////////////
// ordered access levels
//
#define CLASS_ACCESS_PRIVATE   0
#define CLASS_ACCESS_PROTECTED 1
#define CLASS_ACCESS_PACKAGE   2
#define CLASS_ACCESS_PUBLIC    3

//////////////////////////////////////////////////////////////////////////////
// built-in limits
//
#define MAX_SYMBOL_MATCHES    512
#define MAX_RECURSIVE_SEARCH   32
#define MAX_SEARCH_CALLS      500
#define MAX_FUNCTION_NESTING    8


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Globals needed for tool tips for context control
//
static int gi_ContextTimerID = -1;
static int gi_ContextWindowId = -1;
static boolean gContextToolTipShown = false;
static boolean gi_haveContextWindow = true;
static int gi_UpdateTimerID = -1;
static int gi_PrevTotalJobs = 0;
static int gi_ContextHighlightIndex = 0;
static _str gz_ContextHighlightText = "";

static _str gcontext_window_filename = '';
static int  gcontext_window_seekpos  = 0;

static boolean gcontext_files_too_large:[] = null;

int def_context_toolbar_flags=0;//CONTEXT_TOOLBAR_ADD_LOCALS;

int def_update_context_max_file_size = 0x200000;   // default at 2MB size limit
int def_update_context_max_symbols   = 0x020000;   // default to 128k max symbols

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

//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (before defload).  Used to
// initialize the timer variable and window IDs.
//
definit()
{
   // IF editor is initalizing from invocation
   if (arg(1)!='L') {
      gi_ContextTimerID = -1;
      gi_ContextWindowId = -1;
      gContextToolTipShown = false;
      gi_haveContextWindow = true;
      gi_UpdateTimerID = -1;
      gcontext_files_too_large._makeempty();
      call_list("_LoadBackgroundTaggingSettings");
   }
}

//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (after definit).  Used to
// correctly initialize the window IDs (if those forms are available),
// and loads the array of pictures used for different tag types.
//
defload()
{
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
static void contextTimerCB()
{
   //say("contextTimerCB()");
   // verify that gi_ContextWindowId is a valid combo box
   if (!_iswindow_valid(gi_ContextWindowId) ||
       gi_ContextWindowId.p_object!=OI_COMBO_BOX) {
      killContextCBTimer();
      return;
   }

   // find the selected symbol in the context tool window
   _str selected_caption = gz_ContextHighlightText;
   int status = gi_ContextWindowId.find_selected_symbol(selected_caption, auto cm);
   if (status) {
      return;
   }

   // refresh the property dialog if available
   f := _GetCBrowserPropsWID();
   if (f) {
      cb_refresh_property_view(cm);
   }

   // find the output tagwin and update it
   cb_refresh_output_tab(cm, true);


   if (gi_ContextTimerID>=0) _kill_timer( gi_ContextTimerID );
   gi_ContextTimerID = _set_timer( CONTEXT_TOOLTIP_DELAYINC, contextTimerCB, 0 );
   return;

   // Get our x and y mouse coordinates, and map to list box
   int orig_wid = p_window_id;
   p_window_id = gi_ContextWindowId;
   int mx, my;
   mou_get_xy(mx,my);
   int mou_y = my;
   _map_xy(0,p_window_id,mx,my);
   int pic_width = p_width;

   // needed below for common code that pops up button help
   int parent_wid = p_window_id;
   _str caption = '';
   int x, y;

   if (mou_in_window()) {

      // mouse is over combo box text box window?
      caption = p_text;
      x = p_x;
      y = p_y+p_height;
      _lxy2dxy(SM_TWIP,x,y);
      _map_xy(p_parent,0,x,y);

      // caption is not obscured, no bubble help
      int caption_width = _text_width(caption);
      if (caption_width < p_width - pic_width) {
         killContextCBTimer();
         return;
      }

   } else if (false && p_visible && mou_in_window() &&
              mx > 0 && mx < p_client_width) {

      // combo is dropped down and mouse is over list box
      parent_wid = p_window_id;
      //if (p_scroll_left_edge>=0) {
      //   _scroll_page('r');
      //}
      //if (_on_line0()) return;
      if (mou_last_y() > p_font_height*p_char_height) {
         scroll_down();
      }
      int old_cursor_x = p_cursor_x;
      int old_cursor_y = p_cursor_y;
      p_cursor_y=mou_last_y();
      p_cursor_x=p_left_edge+p_windent_x;
      caption = _lbget_text();
      p_cursor_x=old_cursor_x;
      p_cursor_y=old_cursor_y;
      p_window_id = gi_ContextWindowId;

      // show tool tip for the context combo box
      x = p_x + PIC_LINDENT_X + pic_width + PIC_RINDENT_X;
      y = p_y + p_height;
      _lxy2dxy(SM_TWIP,x,y);
      _map_xy(p_parent,0,x,y);
      mou_y -= y;
      mou_y -= (mou_y % p_font_height);
      y += mou_y;

      // If tooltip still in same tab but tab no longer has partial caption:
      int caption_width = _text_width(caption);
      int client_width  = _dx2lx(p_xyscale_mode,p_client_width);
      if (caption_width < client_width - pic_width - PIC_LINDENT_X - PIC_RINDENT_X) {
         killContextCBTimer();
         return;
      }

   } else {
      // mouse has moved outside of combo box or drop-down list
      killContextCBTimer();
      p_window_id = orig_wid;
      return;
   }

   // restore window ID
   p_window_id = orig_wid;

   // Same as before, then just return
   static int giOldContextWindowId;
   static _str gzOldContextCaption;
   if (gi_ContextWindowId == giOldContextWindowId &&
       caption :== gzOldContextCaption && gContextToolTipShown) {
      return;
   }
   giOldContextWindowId = gi_ContextWindowId;
   gzOldContextCaption = caption;
   //if (gContextToolTipShown) {
   //   _bbhelp('C');
   //}

   // show tool tip for the context combo box
   if (x < 0) x = 0;
   _bbhelp('M',parent_wid,x,y,caption,"",0,0,0x80000000,0x80000000,0);
   gContextToolTipShown=true;

   if (gi_ContextTimerID>=0) _kill_timer( gi_ContextTimerID );
   gi_ContextTimerID = _set_timer( CONTEXT_TOOLTIP_DELAYINC, contextTimerCB, 0 );
}


//////////////////////////////////////////////////////////////////////////////
static void updateTimerCB()
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

   if (!_iswindow_valid(gi_ContextWindowId) || gi_ContextWindowId.p_object!=OI_COMBO_BOX) {
      return;
   }

   // find the selected symbol in the context tool window
   _str selected_caption = gi_ContextWindowId.p_text;
   int status = gi_ContextWindowId.find_selected_symbol(selected_caption, auto cm);
   if (status) {
      return;
   }

   // refresh the property dialog if available
   f := _GetCBrowserPropsWID();
   if (f) {
      cb_refresh_property_view(cm);
   }

   // find the output tagwin and update it
   cb_refresh_output_tab(cm, true);
}

//////////////////////////////////////////////////////////////////////////////
// Constants for drawing list box
//

defeventtab _tbcontext_combo_etab;

static int find_selected_symbol(_str selected_caption, VS_TAG_BROWSE_INFO &cm)
{
   // initialize the symbol information
   tag_browse_info_init(cm);

   // check for categories caption
   if (pos("---",selected_caption)==1) {
      return STRING_NOT_FOUND_RC;
   }

   // count the number of duplicate symbols in the list
   int i,num_dups=0;
   _str caption='';
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

   //say("SELECTED: "selected_caption);
   _mdi.p_child._UpdateContext(true);
   _mdi.p_child._UpdateLocals(true,true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   if (def_context_toolbar_flags & CONTEXT_TOOLBAR_ADD_LOCALS) {
      int num_locals = tag_get_num_of_locals();
      for (i=1; i<=num_locals; i++) {
         caption = tag_tree_make_caption_fast(VS_TAGMATCH_local,i,true,true,false);
         if (selected_caption == caption) {
            if (--num_dups >= 0) continue;
            tag_get_local_info(i, cm);
            return 0;
         }
      }
   }

   int num_context = tag_get_num_of_context();
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
      tag_tree_get_bitmap(0,0,cm.type_name, cm.class_name, cm.flags, auto leaf_flag, auto pic_index);
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

void _tbcontext_combo_etab.on_drop_down(int reason)
{
   //say("_tbcontext_combo_etab.on_drop_down: reason="reason);
   static boolean didDropUp;
   VS_TAG_BROWSE_INFO cm;
   gi_haveContextWindow = true;
   killContextCBTimer();
   if (_no_child_windows()) {
      _lbclear();
      return;
   }

   // set caption and bitmaps for current context
   if (reason==DROP_INIT) {
      didDropUp = false;
      _mdi.p_child._UpdateContext(true,true);
      _mdi.p_child._UpdateLocals(true,true);
      _mdi.p_child._UpdateContextWindow(true);

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      // keep track of duplicate captions
      int duplicateCaptions:[];

      // set caption and bitmaps for current context
      cb_prepare_expand(p_window_id, 0, 0);
      origCaption := p_text;
      _lbclear();
      p_picture=_pic_file12;

      num_locals := 0;
      lcl_start_point := 0;
      if (def_context_toolbar_flags & CONTEXT_TOOLBAR_ADD_LOCALS) {
         _lbadd_item("---Locals---",0,_pic_fldopen12);
         lcl_start_point = p_line+1;
         num_locals = tag_get_num_of_locals();
         for (i:=1; i<=num_locals; i++) {
            tag_get_local_info(i, cm);
            tag_list_insert_tag(p_window_id, 0, PIC_LINDENT_X,
                                cm.member_name, cm.type_name, 
                                cm.file_name,   cm.line_no, 
                                cm.class_name,  cm.flags, 
                                cm.return_type:+VS_TAGSEPARATOR_args:+cm.arguments);
            mark_duplicate_symbols_with_space(cm, duplicateCaptions);
         }
      }

      int lcl_end_point = p_line;
      _lbadd_item("---Buffer---",0,_pic_fldopen12);
      int ctx_start_point = p_line+1;
      int num_context = tag_get_num_of_context();
      for (i:=1; i<=num_context; i++) {
         tag_get_context_info(i, cm);
         // Don't insert statements into current context list
         if( !tag_tree_type_is_statement(cm.type_name) && !(cm.flags & VS_TAGFLAG_anonymous)) {
            tag_list_insert_tag(p_window_id, 0, PIC_LINDENT_X,
                                cm.member_name, cm.type_name, 
                                cm.file_name,   cm.line_no, 
                                cm.class_name,  cm.flags, 
                                cm.return_type:+VS_TAGSEPARATOR_args:+cm.arguments);
            mark_duplicate_symbols_with_space(cm, duplicateCaptions);
         }
      }

      int ctx_end_point = p_line;
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
      _str selected_caption = p_text;
      if (pos("---",selected_caption)==1) {
         p_picture = _pic_fldopen12;
         return;
      }
      int status = find_selected_symbol(selected_caption, cm);
      if (status == 0) {    
         didDropUp = true;
         push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
      }
   }
}
// callback for when a context combo box is created
void _tbcontext_combo_etab.on_create()
{
   gi_haveContextWindow = true;
   gcontext_window_filename = '';
   gcontext_window_seekpos = 0;
   p_pic_point_scale=0;
   p_pic_space_y=PIC_LSPACE_Y;
   p_style=PSCBO_NOEDIT;
   if (_no_child_windows()) {
      _lbclear();
      p_picture = 0;
      ContextMessage('');
   } else {
      _UpdateContextWindow(true);
   }
}

// monitor mouse move events when over the context window
void _tbcontext_combo_etab.mouse_move()
{
   //say("_tbcontext_combo_etab.mouse_move: HERE");
   gi_ContextWindowId = p_window_id;
   //gContextToolTipShown=false;
   if (gi_ContextTimerID >= 0 || gContextToolTipShown) {
      //say("shown="gContextToolTipShown);
      return;
   }
   gi_ContextTimerID = _set_timer(CONTEXT_TOOLTIP_DELAYINC, contextTimerCB, 0);
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
      gi_ContextWindowId = p_window_id;
      gi_UpdateTimerID = _set_timer(CB_TIMER_DELAY_MS, updateTimerCB);
   }
}

void _tbcontext_combo_etab.on_highlight(int index=0, _str caption="")
{
   if (!def_tag_hover_preview) {
      return;
   }
   //say("_tbcontext_combo_etab.on_highlight: index="index" caption="caption);
   gi_ContextWindowId = p_window_id;
   gi_ContextHighlightIndex = index;
   gz_ContextHighlightText = caption;
   if (gi_ContextTimerID >= 0 || gContextToolTipShown) {
      return;
   }
   if (gi_ContextHighlightIndex > 0 && gz_ContextHighlightText != "") {
      gi_ContextTimerID = _set_timer(def_tag_hover_delay, contextTimerCB, 0);
   }
}

void _tbcontext_combo_etab.rbutton_down()
{
   index := find_index("_context_toolbar_menu",oi2type(OI_MENU));
   if (index <= 0) return;
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
}

// leave message in context box
//
static void ContextMessage(_str msg, int pic_index=0)
{
   if (msg=='') {
      msg = "no current context";
   }
   if (/*_mdi.p_button_bar &&*/ gi_haveContextWindow) {
      gi_haveContextWindow = false;
      typeless eventtab=defeventtab _tbcontext_combo_etab;
      int i;
      for (i=1;i<=_last_window_id();++i) {
         if (_iswindow_valid(i) && !i.p_edit && i.p_eventtab==eventtab) {
            gi_haveContextWindow = true;
            i._cbset_text(msg, pic_index);
         }
      }
   }
}

_command void context_toolbar_display_local() name_info(','VSARG2_READ_ONLY)
{
   if (def_context_toolbar_flags & CONTEXT_TOOLBAR_DISPLAY_LOCALS) {
      def_context_toolbar_flags &= ~CONTEXT_TOOLBAR_DISPLAY_LOCALS;
   } else {
      def_context_toolbar_flags |= CONTEXT_TOOLBAR_DISPLAY_LOCALS|CONTEXT_TOOLBAR_ADD_LOCALS;
   }
   if (!_no_child_windows()) {
      _mdi.p_child.p_ModifyFlags &= ~MODIFYFLAG_CONTEXTWIN_UPDATED;
      _mdi.p_child._UpdateContextWindow(true);
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
_command void context_toolbar_list_locals() name_info(','VSARG2_READ_ONLY)
{
   if (def_context_toolbar_flags & CONTEXT_TOOLBAR_ADD_LOCALS) {
      def_context_toolbar_flags &= ~CONTEXT_TOOLBAR_ADD_LOCALS;
   } else {
      def_context_toolbar_flags |= CONTEXT_TOOLBAR_ADD_LOCALS;
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
_command void context_toolbar_sort_by_line() name_info(','VSARG2_READ_ONLY)
{
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
   orig_mark_id := _duplicate_selection('');
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
         reverse := '';
         context_id = tag_nearest_context(p_RLine);
         if (context_id > 0) {
            tag_get_detail2(VS_TAGDETAIL_context_start_linenum,context_id,auto nearest_line);
            tag_get_detail2(VS_TAGDETAIL_context_start_seekpos,context_id,auto nearest_pos);
            if (nearest_line == p_RLine && nearest_pos < _QROffset()) {
               reverse = '-';
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
      context_id = tag_current_context();

   } while (false);

   // clean up
   _show_selection(orig_mark_id);
   _free_selection(mark_id);
   restore_search(s1, s2, s3, s4, s5);
   restore_pos(p);
   return context_id;
}

/**
 * Update the current context combo box window(s)
 * the current object must be the editor control to update
 *
 * @param AlwaysUpdate  update now, or wait for
 *                      CONTEXT_UPDATE_TIMEOUT ms idle time?
 */
void _UpdateContextWindow(boolean AlwaysUpdate=false)
{
   //say("_UpdateContext()");
   // make sure timer has waited long enough
   if (!AlwaysUpdate && _idle_time_elapsed()<def_update_tagging_idle) {
      //say("don't always update");
      return;
   }

   // do not update if no context window to update
   if (!gi_haveContextWindow) {
      return;
   }

   if (_no_child_windows() || !_mdi.p_child._istagging_supported()) {
      ContextMessage('');
      return;
   }

   // if the context is not yet up-to-date, then don't update yet
   if (!AlwaysUpdate && 
       !(p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED) &&
       _idle_time_elapsed() < def_update_tagging_idle+def_update_tagging_extra_idle) {
      return;
   }

   // blow out of here if cursor hasn't moved and file not modified
   int curr_seekpos = (int)_mdi.p_child._QROffset();
   if ((_mdi.p_child.p_ModifyFlags&MODIFYFLAG_CONTEXTWIN_UPDATED) &&
       gcontext_window_seekpos==curr_seekpos &&
       gcontext_window_filename:==_mdi.p_child.p_buf_name) {
      //say("no cursor movement");
      return;
   }
   gcontext_window_filename = _mdi.p_child.p_buf_name;
   gcontext_window_seekpos  = curr_seekpos;
   _mdi.p_child.p_ModifyFlags |= MODIFYFLAG_CONTEXTWIN_UPDATED;

   // Update the current context
   _mdi.p_child._UpdateContext(true);
   _mdi.p_child._UpdateLocals(true);
   cb_prepare_expand(p_window_id, 0, 0);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   _str type_name;
   int flags;
   _str caption='';
   int leaf_flag,pic_index;

   // Update the context message, if current context is local variable
   int local_id = _mdi.p_child.tag_current_local();
   if (local_id > 0 && 
       (def_context_toolbar_flags & CONTEXT_TOOLBAR_ADD_LOCALS) &&
       (def_context_toolbar_flags & CONTEXT_TOOLBAR_DISPLAY_LOCALS) ) {
      //say("_UpdateContextWindow(): local_id="local_id);
      tag_get_detail2(VS_TAGDETAIL_local_type,local_id,type_name);
      tag_get_detail2(VS_TAGDETAIL_local_flags,local_id,flags);
      caption = tag_tree_make_caption_fast(VS_TAGMATCH_local,local_id,true,true,false);
      //tag_tree_filter_member(0, type_name, 0, flags, i_access, i_type);
      //tag_tree_select_bitmap(i_access, i_type, leaf_flag, pic_index);
      tag_tree_get_bitmap(0,0,type_name,'',flags,leaf_flag,pic_index);
      ContextMessage(caption, pic_index);
      _mdi.p_child.p_ModifyFlags |= MODIFYFLAG_CONTEXTWIN_UPDATED;
      return;
   }

   // Update the context message
   int context_id = _mdi.p_child.tag_current_context();
   if (context_id <= 0) {
      // check if we are in a comment directly before or after a symbol
      context_id = _mdi.p_child.tag_current_context_or_comment();
   }
   if (context_id <= 0) {
      ContextMessage('');
      //say("no context");
      return;
   }
   tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);
   tag_get_detail2(VS_TAGDETAIL_context_flags,context_id,flags);
   caption = tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,true,true,false);
   //tag_tree_filter_member(0, type_name, 0, flags, i_access, i_type);
   //tag_tree_select_bitmap(i_access, i_type, leaf_flag, pic_index);
   tag_tree_get_bitmap(0,0,type_name,'',flags,leaf_flag,pic_index);
   ContextMessage(caption, pic_index);
   _mdi.p_child.p_ModifyFlags |= MODIFYFLAG_CONTEXTWIN_UPDATED;
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
static void handleUpdateContextFailure(_str warning, _str adjust_var)
{
   tag_check_cached_context(VS_UPDATEFLAG_context);
   tag_clear_context();
   tag_insert_context(0, warning :+ "  Context information is not generated.  ":+
                      "Try adjusting '" :+ adjust_var :+ "'",
                      "package", p_buf_name, 1, 1, 1, 1, 1/*p_Noflines*/, p_buf_size, "", 0, "");
   p_ModifyFlags &= ~MODIFYFLAG_CONTEXT_UPDATED;
   p_ModifyFlags &= ~MODIFYFLAG_STATEMENTS_UPDATED;
}

boolean _CheckUpdateContextSizeLimits()
{
   // Bail out for large files.
   if (p_buf_size > def_update_context_max_file_size) {
      handleUpdateContextFailure("FILE IS TOO LARGE!","def_update_context_max_file_size");
      return false;
   }
   if (gcontext_files_too_large._indexin(p_buf_name)) {
      handleUpdateContextFailure("FILE HAS TOO MANY TAGS!","def_update_context_max_symbols");
      return false;
   }
   return true;
}

/**
 * Update the current context and context tree message
 * the current object must be the active buffer
 *
 * @param AlwaysUpdate  update right away or wait for 1500 ms idle time?
 * @param ForceUpdate   ??
 * @param nUpdateFlags  can have VS_UPDATEFLAG_statements and VS_UPDATEFLAG_contexts
 */
void _UpdateContext(boolean AlwaysUpdate=false, boolean ForceUpdate=false, int nUpdateFlags=VS_UPDATEFLAG_context )
{
//   say("_UpdateContext nUpdateFlags & VS_UPDATEFLAG_context "   ( int )( nUpdateFlags & VS_UPDATEFLAG_context ) );
//   say("_UpdateContext nUpdateFlags & VS_UPDATEFLAG_statement " ( int )( nUpdateFlags & VS_UPDATEFLAG_statement ) );
//   say("_UpdateContext nUpdateFlags & VS_UPDATEFLAG_list_all "  ( int )( nUpdateFlags & VS_UPDATEFLAG_list_all ) );
//   say("_UpdateContext nUpdateFlags & VS_UPDATEFLAG_tokens "    ( int )( nUpdateFlags & VS_UPDATEFLAG_tokens ) );

   //say("_UpdateContext: Always="AlwaysUpdate" Force="ForceUpdate);
   // make sure timer has waited long enough
   int idle_timeout=(def_update_tagging_idle>1500)? def_update_tagging_idle:1500;
   if (!AlwaysUpdate && _idle_time_elapsed()<idle_timeout) {
      return;
   }

   // if this buffer is not taggable, blow out of here
   if (!_isEditorCtl() || !_istagging_supported()) {
      tag_lock_context(true);
      tag_check_cached_context(VS_UPDATEFLAG_context);
      tag_clear_context();
      tag_unlock_context();
      return;
   }

   // Bail out for large files.
   if (!ForceUpdate && !_CheckUpdateContextSizeLimits()) {
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
       !file_eq(p_buf_name, fileName) ) {
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

   // clear the current context and embedded code sections
   tag_clear_context(p_buf_name, true);
   tag_clear_embedded();

   // now we insert the symbols found by the threaded search
   //say("_UpdateContextAsyncInsertResults: inserting tags ");
   tag_insert_async_tagging_result(fileName, taggingFlags, bufferId);
   //say("_UpdateContextAsyncInsertResults: number of context="tag_get_num_of_context());

   // check if there are embedded sections to tag.
   if (tag_get_num_of_embedded()) {
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
   AUindex := _FindLanguageCallbackIndex('_%s_after_UpdateContext');
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
      if (!(p_ModifyFlags & (MODIFYFLAG_LOCALS_UPDATED|MODIFYFLAG_LOCALS_THREADED))) {
         _UpdateLocalsAsyncForWindow();
      }
      if (!(p_ModifyFlags & (MODIFYFLAG_STATEMENTS_UPDATED|MODIFYFLAG_STATEMENTS_THREADED))) {
         _UpdateStatementsAsyncForWindow();
         tag_check_cached_context(updateFlags);
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

/**
 * For synchronization, this must be called by the main editor thread and 
 * a write lock must have been already acquired on the current context by 
 * calling tag_lock_context(true); 
 * 
 * @param fileName         fileName being updated 
 * @param taggingFlags     tagging flags (VSLTF_*)
 * @param bufferId         bufferId of file being updated
 */
int _UpdateLocalsAsyncInsertResults(_str fileName, int taggingFlags, 
                                     int bufferId, int lastModified)
{
   // first we open a temp view to make sure that we are updating the right buffer.
   have_temp_view := false;
   orig_wid := 0;
   temp_wid := 0;
   if (!_isEditorCtl() || 
       p_buf_id != bufferId ||
       !file_eq(p_buf_name, fileName) ) {
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
      //say("_UpdateLocalsAsyncInsertResults: context was modified");
      return 0;
   }

   // find the start and end seek positions which we parsed to find local vars
   tag_lock_context(true);
   start_seekpos := 0;
   end_seekpos := 0;
   tag_get_async_locals_bounds(start_seekpos, end_seekpos);

   // check what the context ID for this item was.
   save_pos(auto p);
   _GoToROffset(start_seekpos);
   context_id := tag_current_context();
   restore_pos(p);

   // check if the context is already up to date, if so, the we should
   // just throw out this late result, it's moot.
   have_context := tag_check_cached_locals(start_seekpos, end_seekpos, context_id, 0);
   if (have_context && (p_ModifyFlags & MODIFYFLAG_LOCALS_UPDATED)) {
      if (have_temp_view) {
         _delete_temp_view(temp_wid);
         activate_window(orig_wid);
      }
      //say("_UpdateLocalsAsyncInsertResults: locals are already up to date");
      tag_unlock_context();
      return 0;
   }

   // if context is being recalculated, then invalidate
   // locals, context window, statements and proctree
   p_ModifyFlags &= ~MODIFYFLAG_LOCALS_UPDATED;

   // clear the current context and embedded code sections
   tag_clear_locals(0);

   // now we insert the symbols found by the threaded search
   //say("_UpdateLocalsAsyncInsertResults: inserting tags ");
   tag_insert_async_tagging_result(fileName, taggingFlags, bufferId);
   //say("_UpdateContextAsyncInsertResults: number of context="tag_get_num_of_locals());

   // sort the items in the current context by seekpos
   // this should be instant because the thread already sorted
   // its results before inserting them.
   tag_sort_locals();

   // list locals for each level of local
   boolean local_hash:[];
   local_hash:[start_seekpos]=true;
   boolean outer_hash:[];
   VS_TAG_BROWSE_INFO outer_locals[];
   _UpdateLocalsInLocalFunctions(local_hash, end_seekpos);

   // call post-processing function for update context
   AUindex := _FindLanguageCallbackIndex('_%s_after_UpdateLocals');
   if (AUindex) {
      typeless p1,p2,p3,p4;
      save_search(p1,p2,p3,p4);
      call_index(AUindex);
      restore_search(p1,p2,p3,p4);
   }
   
   // set the modify flags, showing that the context is up to date
   p_ModifyFlags |= MODIFYFLAG_LOCALS_UPDATED;

   //say("_UpdateLocalsAsyncInsertResults: lastmodified="p_LastModified);
 
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
   if (!status && tag_get_num_of_embedded()) {

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
   alertId := _GetBuildingTagFileAlertGroupId(tagDatabase, false, true);
   if (alertId > 0) {
      _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, 'Tag file update has completed', '', 1);
   }
}
int _ReportAsyncTaggingResults(boolean AlwaysUpdate=false, int progressWid=0)
{
   // make sure timer has waited long enough
   if (!AlwaysUpdate && _idle_time_elapsed() < def_background_tagging_idle) {
      //say("_UpdateContextAsync: not enough idle time");
      return VSRC_OPERATION_CANCELLED;
   }

   // recursion guard
   static boolean reportingResults;
   if (reportingResults) {
      return VSRC_OPERATION_CANCELLED;
   }
   reportingResults = true;

   // calculate the amount of time to wait for slower jobs
   // defer slower jobs if the editor has been active
   slower_tagging_job_idle := def_background_tagging_idle*10 + 1000;
   deferSlowerJobs := (!AlwaysUpdate && _idle_time_elapsed() < slower_tagging_job_idle);

   // report tagging results which completed in the background
   if (!AlwaysUpdate) {
      _SetTimeout(def_background_tagging_timeout);
   }

   status := 0;
   taggingFlags := 0;
   bufferId := 0;
   lastModified := 0;
   fileName := "";
   updateFinished := 0;
   numFilesTagged := 0;
   waitTimeForResult := 0;
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
      if (status < 0) {
         totalJobs := tag_get_num_async_tagging_jobs('U');
         if (totalJobs <= 0 && pos("Tagging", get_message())==1) {
            clear_message();
         }
         break;
      }

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
            if (def_tagging_logging) {
               loggingMessage = nls("Completed embedded tagging of local variables for '%s1'", fileNamePart);
            }
            status = _UpdateLocalsAsyncInsertResults(fileNamePart, taggingFlags, bufferId, lastModified);
         } else if (taggingFlags & VSLTF_SET_TAG_CONTEXT) {
            if (def_tagging_logging) {
               loggingMessage = nls("Completed embedded tagging of current context for '%s1'", fileNamePart);
            }
            status = _UpdateContextAsyncInsertResults(fileNamePart, taggingFlags, bufferId, lastModified);
         } else {
            if (def_tagging_logging) {
               loggingMessage = nls("Completed embedded tagging of '%s1' in tag file '%s2'", fileNamePart, tagDatabase);
            }
            status = _RetagFileInsertResults(fileNamePart, taggingFlags, bufferId, lastModified);
            showProgress = true;
            numFilesTagged++;
         }
         break;
      case BACKGROUND_TAGGING_NOT_SUPPORTED_RC:
         //say("_ReportAsyncTaggingResults: File requires foreground tagging: '"fileName"'");
         if (!(taggingFlags & VSLTF_LIST_LOCALS) && !(taggingFlags & VSLTF_SET_TAG_CONTEXT)) {
            if (tagDatabase != "") {
               if (def_tagging_logging) {
                  loggingMessage = nls("Completed tagging of '%s1' in tag file '%s2'", fileNamePart, tagDatabase);
               }
               status = tag_open_db(tagDatabase);
               if (status >= 0) {
                  status = RetagFile(fileName, false, bufferId);
               }
               tag_close_db(tagDatabase, 1);
               showProgress = true;
               numFilesTagged++;
            }
         }
         break;
      case TAGGING_NOT_SUPPORTED_FOR_FILE_RC:
         if (def_tagging_logging) {
            loggingMessage = nls("Tagging is not supported for file '%s1'", fileNamePart);
         }
         break;
      case FILE_NOT_FOUND_RC:
         if (def_tagging_logging) {
            loggingMessage = nls("Missing file '%s1' removed from tag file '%s2'", fileNamePart, tagDatabase);
         }
         numFilesTagged++;
         break;
      case LEFTOVER_FILE_REMOVED_FROM_DATABASE_RC:
         if (def_tagging_logging) {
            loggingMessage = nls("Leftover file '%s1' removed from tag file '%s2'", fileNamePart, tagDatabase);
         }
         numFilesTagged++;
         break;
      case FILE_REMOVED_FROM_DATABASE_RC:
         alertMessage = nls("File '%s1' removed from tag file '%s2'", fileNamePart, _strip_filename(tagDatabase, 'P'));
         if (def_tagging_logging) {
            loggingMessage = nls("File '%s1' removed from tag file '%s2'", fileNamePart, tagDatabase);
         }
         numFilesTagged++;
         break;
      case BACKGROUND_TAGGING_IS_FINDING_FILES_RC:
         alertMessage = get_message(updateFinished, _strip_filename(tagDatabase, 'P'));
         if (def_tagging_logging) {
            loggingMessage = get_message(updateFinished, tagDatabase);
         }
         break;
      case BACKGROUND_TAGGING_COMPLETE_RC:
         alertMessage = get_message(updateFinished, _strip_filename(tagDatabase, 'P'));
         if (def_tagging_logging) {
            loggingMessage = get_message(updateFinished, tagDatabase);
         }
         DeactivateTagBuildAlert(tagDatabase);
         break;
      case COMMAND_CANCELLED_RC:
      case VSRC_OPERATION_CANCELLED:
         if (def_tagging_logging) {
            loggingMessage = nls("Background tagging cancelled for file '%s1'", fileNamePart);
         }
         break;
      case ACCESS_DENIED_RC:
         if (file_eq(fileName, tagDatabase)) {
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
            _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING, 'Background tagging started', '', 1);
         }
      } else if ((gi_PrevTotalJobs > 0) && (totalJobs == 0)) {
         _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING, 'Background tagging has completed', '', 0);
         _str tagDatabaseArray[];
         tag_get_async_tag_file_builds(tagDatabaseArray);
         if (tagDatabaseArray._length() == 0) {
            _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING_WORKSPACE, 'Workspace tag file update has completed', '', 0);
            for (i:=ALERT_TAGGING_BUILD0; i<ALERT_TAGGING_BUILD0+ALERT_TAGGING_MAX_BUILDS; i++) {
               _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, i, 'Tag file update has completed', '', 0);
            }
         }
      }
      // now update the last job count
      gi_PrevTotalJobs = totalJobs;

      // show a message when completing tag file updates
      messageAge := (int)get_message("-age");
      if (showProgress && !progressWid && 
          def_background_tagging_rpm > 0 &&
          messageAge >= (60*1000 / def_background_tagging_rpm) &&
          !(taggingFlags & VSLTF_LIST_LOCALS) && 
          !(taggingFlags & VSLTF_SET_TAG_CONTEXT) && 
          !(def_autotag_flags2 & AUTOTAG_SILENT_THREADS) && 
          fileName != "" && alertMessage == "" 
         ) {
         cmdlineWidth := _cmdline.p_width+300 /*fudge*/;
         remainingJobs := "";
         totalJobs = tag_get_num_async_tagging_jobs('U');
         if (totalJobs > 0) remainingJobs = " ("totalJobs" remaining)";
         labelWidth   := _cmdline._text_width("Tagging":+remainingJobs:+": ");
         if (cmdlineWidth < labelWidth) cmdlineWidth = labelWidth;
         alertMessage = "Tagging":+remainingJobs:+": "_cmdline._ShrinkFilename(fileNamePart, cmdlineWidth-labelWidth);
      }

      // display a message on the status line if we are not overwriting
      // anything that would otherwise be really interesting.
      // feel free to overwrite anything that is older than 30 seconds
      if (alertMessage != "") {
         currentMessage := (messageAge < 30000)? get_message() : "";
         if (currentMessage=="" || 
             pos("Tagging", currentMessage)==1 || 
             pos("Retagging", currentMessage)==1 || 
             pos("Removing", currentMessage)==1 || 
             pos("Finished", currentMessage)==1 || 
             pos("Updating", currentMessage)==1 || 
             pos("Background", currentMessage)==1 || 
             pos("Module", currentMessage)==1 || 
             pos("Tag file ", currentMessage)==1 ||
             pos("The workspace tag file ", currentMessage)==1 ||
             pos("Error processing ", currentMessage)==1
            ) {
            message(alertMessage);
         }
      }

      // dispose of the tagging result, we are completely done with it now
      tag_dispose_async_tagging_result(fileName, bufferId);

      if (progressWid && _iswindow_valid(progressWid)) {
         totalJobs = tag_get_num_async_tagging_jobs('U');
         cancel_form_set_labels(progressWid, 
                                "Press Cancel to stop tagging. ":+"(":+totalJobs:+" remaining)",
                                "Updating ":+fileNamePart);
      }

      // if we have spent too much time updating tagging results, we should stop
      // and give it a rest, there will always be another autosave timer event.
      if (!def_background_tagging_timeout || _CheckTimeout()) {
         break;
      }

      // if a keystroke came along, break out of here
      if( _IsKeyPending() ) {
         break;
      }
   }

   // clear the software timeout
   _SetTimeout(0);

   // report on the number of jobs processed
   if (numFilesTagged > 0 && def_tagging_logging) {
      numReadingJobs  := tag_get_num_async_tagging_jobs('L');
      numTaggingJobs  := tag_get_num_async_tagging_jobs('Q');
      numFinishedJobs := tag_get_num_async_tagging_jobs('F');
      numDatabaseJobs := tag_get_num_async_tagging_jobs('D');
      numDeferredJobs := tag_get_num_async_tagging_jobs('P');
      loggingMessage :=  "completed="numFilesTagged :+
                         ", to read="numReadingJobs :+
                         ", to parse="numTaggingJobs :+
                         ", to tag="numDatabaseJobs :+
                         ", to complete="numFinishedJobs :+
                         ", deferred="numDeferredJobs;
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
      _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING, 'Background tagging has completed', '', 0);
      _str tagDatabaseArray[];
      tag_get_async_tag_file_builds(tagDatabaseArray);
      if (tagDatabaseArray._length() == 0) {
         _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING_WORKSPACE, 'Workspace tag file update has completed', '', 0);
         for (i:=ALERT_TAGGING_BUILD0; i<ALERT_TAGGING_BUILD0+ALERT_TAGGING_MAX_BUILDS; i++) {
            _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, i, 'Tag file update has completed', '', 0);
         }
      }
   }

   // cancel recursion guard
   reportingResults = false;
   return 0;
}

_command void finish_background_tagging() name_info(',')
{
   _MaybeRetryTaggingWhenFinished(false);
}

boolean _MaybeRetryTaggingWhenFinished(boolean quiet=false, _str caption="")
{
   totalJobs := tag_get_num_async_tagging_jobs('U');
   if (totalJobs <= 0) {
      return false;
   }

   if (caption == "") {
      caption = "Finishing background tagging jobs";
   }

   progressWid := 0;
   if (!quiet && totalJobs > 10) {
      progressWid = show_cancel_form(caption, null, true, true);
   }

   // force the main thread to relinquish any locks it has on any databases
   // this way the other threads can do whatever they want immediately.
   tag_close_all_db();

   wasCancelled := false;
   while (tag_get_num_async_tagging_jobs('U') > 0) {
      if (!quiet && cancel_form_cancelled(0)) {
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
      if (tag_get_num_async_tagging_jobs('F') <= 0) {
         // before sleeping, make sure we unlock any read-locks we have
         // on the current context so that threads can finish what they are doing
         // if they need to write to the context.
         lockCount := 0;
         while (tag_unlock_context() == 0) {
            ++lockCount;
         }
         delay(def_background_tagging_idle);
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
   }

   if (!quiet && progressWid && _iswindow_valid(progressWid)) {
      close_cancel_form(progressWid);
   }

   // If tag files were upated, update tool windows. 
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);

   return !wasCancelled;
}

void _exit_FinishAsyncTagging()
{
   _MaybeRetryTaggingWhenFinished();
}

static void _UpdateContextAsyncForWindow()
{
   // if this buffer is not taggable, blow out of here
   if (!_isEditorCtl(false)) {
      //say("_UpdateContextAsync:  Not an editor control");
      return;
   }

   // make sure timer has waited long enough
   if (_idle_time_elapsed() < (def_background_tagging_idle intdiv 10)) {
      //say("_UpdateContextAsync: not enough idle time");
      return;
   }

   // if we have already started a thread for this buffer, don't start another
   if (p_ModifyFlags & MODIFYFLAG_CONTEXT_THREADED) {
      //say("_UpdateContextAsync: thread was already started");
      return;
   }

   // if we have already started a thread for this buffer, don't start another
   if (p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED) {
      //say("_UpdateContextAsync: context already up to date");
      return;
   }

   // verify that we have a list tags function for this language
   LTindex := _FindLanguageCallbackIndex('vs%s-list-tags');
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
   if (p_buf_size > def_update_context_max_file_size) {
      return;
   }
   if (gcontext_files_too_large._indexin(p_buf_name)) {
      return;
   }

   // check current buffer position against context
   // rely on this function's synchronization since nothing else here depends
   // on the contents of the current context.
   have_context := tag_check_cached_context(VS_UPDATEFLAG_context);
   if ( have_context ) {
      //say("_UpdateContextAsync: Already have current context tagged");
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
   call_index(0, '', p_LangId, taggingFlags, LTindex);
   p_ModifyFlags |= MODIFYFLAG_CONTEXT_THREADED;
}

void _UpdateContextAsync()
{
   if (_isEditorCtl(false)) {
      _UpdateContextAsyncForWindow();
   } else if (!_no_child_windows()) {
      _mdi.p_child._UpdateContextAsyncForWindow();
   }
}

static void _UpdateStatementsAsyncForWindow()
{
   // if this buffer is not taggable, blow out of here
   if (!_isEditorCtl()) {
      //say("_UpdateStatementsAsync:  Not an editor control");
      return;
   }

   // make sure timer has waited long enough
   if (_idle_time_elapsed() < (def_background_tagging_idle intdiv 10)) {
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
   LTindex := _FindLanguageCallbackIndex('vs%s-list-tags');
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
   SSindex := _FindLanguageCallbackIndex('%s_are_statements_supported');
   if (SSindex <= 0 || !call_index(SSindex)) {
      //say("_UpdateStatementsAsync: statement tagging not supported for language");
      return;
   }

   // bail out for large files.
   if (p_buf_size > def_update_context_max_file_size intdiv 4) {
      //say("_UpdateStatementsAsync: buffer too large");
      return;
   }
   if (gcontext_files_too_large._indexin(p_buf_name)) {
      return;
   }

   // check current buffer position against context
   // rely on this function's synchronization since nothing else here depends
   // on the contents of the current context.
   have_context := tag_check_cached_context(VS_UPDATEFLAG_context|VS_UPDATEFLAG_statement);
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
   call_index(0, '', p_LangId, taggingFlags, LTindex);
   p_ModifyFlags |= MODIFYFLAG_STATEMENTS_THREADED;
}

void _UpdateStatementsAsync()
{
   if (_isEditorCtl(false)) {
      _UpdateStatementsAsyncForWindow();
   } else if (!_no_child_windows()) {
      _mdi.p_child._UpdateStatementsAsyncForWindow();
   }
}

static void _UpdateLocalsAsyncForWindow()
{
   // if this buffer is not taggable, blow out of here
    if (!_isEditorCtl()) {
      //say("_UpdateLocalsAsync:  Not an editor control");
      return;
   }

    // make sure timer has waited long enough
    if (_idle_time_elapsed() < (def_background_tagging_idle intdiv 10)) {
       //say("_UpdateLocalsAsync: not enough idle time");
       return;
    }

    // if we have already started a thread for this buffer, don't start another
    if (p_ModifyFlags & MODIFYFLAG_LOCALS_THREADED) {
       //say("_UpdateLocalsAsync: thread was already started");
       return;
    }

    // if we have already started a thread for this buffer, don't start another
    if (p_ModifyFlags & MODIFYFLAG_LOCALS_UPDATED) {
       //say("_UpdateLocalsAsync: locals already up to date");
       return;
    }

   // if we have already started a thread for this buffer, don't start another
   if (p_ModifyFlags & MODIFYFLAG_LOCALS_THREADED) {
      //say("_UpdateLocalsAsync: thread was already started");
      return;
   }

   // verify that we have a list tags function for this language
   LLindex := _FindLanguageCallbackIndex('%s-list-locals');
   if (LLindex <= 0) {
      //say("_UpdateLocalsAsync:  no list locals function");
      return;
   }

   // do nothing if this language doesn't support asynchrounous taggingFlags
   if (!_is_background_tagging_supported()) {
      //say("_UpdateLocalsAsync:  no background tagging support for language");
      return;
   }

   // make sure another thread doesn't come along and update the locals
   // while we are still computing what to update
   tag_lock_context();

   // check that the current context is up-to-date
   // rely on this function's synchronization since nothing else here depends
   // on the contents of the current context.
   int have_context = tag_check_cached_context(VS_UPDATEFLAG_context);
   if (!have_context || !(p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED)) {
      //say("_UpdateLocalsAsync:  context is not up to date yet");
      tag_unlock_context();
      return;
   }

   // update the context, is the current context defined?
   orig_context_id := context_id := tag_current_context();
   if (context_id <= 0) {
      //say("_UpdateLocalsAsync: no current function");
      tag_unlock_context();
      return;
   }

   // list locals for each level of context
   int outer_contexts[];
   func_nesting := 0;
   while (context_id>0 && func_nesting<MAX_FUNCTION_NESTING) {

      // check that the current context is a function
      cur_type_name := "";
      cur_tag_name := "";
      cur_tag_flags := 0;
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, cur_type_name);
      tag_get_detail2(VS_TAGDETAIL_context_name, context_id, cur_tag_name);
      tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, cur_tag_flags);

      // add the item to the list of local contexts to gather information from
      if (tag_tree_type_is_func(cur_type_name) || 
          cur_type_name=='define' || cur_type_name=='block' ||
          ((cur_tag_flags & VS_TAGFLAG_template) && tag_tree_type_is_class(cur_type_name))) {
         outer_contexts[outer_contexts._length()] = context_id;
      }

      // get the next level higher of function nesting
      tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, context_id);
      func_nesting++;
   }

   if (outer_contexts._length() > 1) {
      //say("_UpdateLocalsAsync: async locals tagging doesn't support nested functions");
      tag_unlock_context();
      return;
   }
   context_id = outer_contexts[0];
   if (context_id != orig_context_id) {
      //say("_UpdateLocalsAsync: async locals tagging doesn't support outer functions");
      tag_unlock_context();
      return;
   }

   // end seekpos is position of cursor or end of function
   cur_start_line_no := 0;
   cur_start_seekpos := 0;
   cur_scope_seekpos := 0;
   cur_end_seekpos   := 0;
   cur_tag_flags     := 0;
   tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, cur_start_line_no);
   tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, cur_start_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, cur_scope_seekpos);
   tag_get_detail2(VS_TAGDETAIL_context_end_seekpos,   context_id, cur_end_seekpos);
   end_seekpos := (int)_QROffset();

   // locals already up to date?
   if (tag_check_cached_locals(cur_start_seekpos, end_seekpos, context_id, 0)) {
      //say("_UpdateLocals: using cached locals");
      if (p_ModifyFlags & MODIFYFLAG_LOCALS_UPDATED) {
         //say("_UpdateLocalsAsync: locals already up to date");
         tag_unlock_context();
         return;
      }
   }
   //say("_UpdateLocals: Recalculating locals");

   // update the context, is the current context defined?
   if (context_id <= 0) {
      tag_clear_locals(0);
      //say("_UpdateLocalsAsync: NO CURRENT CONTEXT");
      tag_unlock_context();
      return;
   }

   // set list-locals flags appropriately
   taggingFlags := VSLTF_SET_TAG_CONTEXT|VSLTF_LIST_LOCALS|VSLTF_SKIP_OUT_OF_SCOPE|VSLTF_ASYNCHRONOUS;

   // check if there is already a job running for this buffer
   // cancel the job if the buffer is already out of date
   status := tag_get_async_tagging_job(p_buf_name, 
                                       taggingFlags, 
                                       p_buf_id, 
                                       p_file_date, 
                                       p_LastModified,
                                       null, cur_start_line_no, cur_start_seekpos, end_seekpos);
   if (!status) {
      //say("_UpdateLocalsAsync: already have background thread for locals");
      tag_unlock_context();
      return;
   }
   
   // Update if we are forced to update or we do not have a current context
   // Also update if the context is not up to date or we are going to list statements
   // and the statements are not up to date
   //say("_UpdateLocalsAsync: starting async locals tagging job");
   call_index(0, '', p_LangId, taggingFlags, 0, 0, cur_start_seekpos, end_seekpos, LLindex);
   p_ModifyFlags |= MODIFYFLAG_LOCALS_THREADED;
   tag_unlock_context();
}

void _UpdateLocalsAsync()
{
   if (_isEditorCtl(false)) {
      _UpdateLocalsAsyncForWindow();
   } else if (!_no_child_windows()) {
      _mdi.p_child._UpdateLocalsAsyncForWindow();
   }
}

//////////////////////////////////////////////////////////////////////////////

void _UpdateEmbeddedContext(int taggingFlags) 
{
   // bump up the max string size parameter to match the buffer size
   _str orig_max = _default_option(VSOPTION_WARNING_STRING_LENGTH);
   if ( p_RBufSize*3+1024 > orig_max ) {
      _default_option(VSOPTION_WARNING_STRING_LENGTH, p_RBufSize*3+1024);
   }

   // collate all the embedded sections into string buffers
   // NOTE:  It would be more effecient to do this using a set of
   //        views instead of strings.
   boolean gdo_search=false;
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

      SSindex_embedded := _FindLanguageCallbackIndex('%s_are_statements_supported',ext);

      int ltf_flags_embedded = taggingFlags|VSLTF_READ_FROM_STRING;
      if ( (taggingFlags & VSLTF_LIST_STATEMENTS) && call_index(0, '', p_LangId, 0, SSindex_embedded ) ) {
         ltf_flags_embedded |= VSLTF_LIST_STATEMENTS;
      }

      // look up the list-tags function and call it on the fake buffer
      LTindex := _FindLanguageCallbackIndex('vs%s-list-tags',ext);
      _str fake_buffer = ext_embedded_buffer_data:[ext];
      status = call_index(0, '', fake_buffer,
                          ltf_flags_embedded,
                          0,0,0,length(fake_buffer),
                          LTindex);
   }

   // fall back to conventional list-tags methods
   if ( gdo_search ) {
      typeless p1,p2,p3,p4;
      save_search(p1,p2,p3,p4);
      top();
      proc_name := '';
      int findfirst=1;
      int context_id=0;
      for ( ;; ) {
         //say("_UpdateContext");
         proc_name='';
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
         if ( proc_name != '' ) {
            // search backward for non-blank character
            signature := "";
            return_type := "";
            tag_name := "";
            class_name := "";
            type_name := "";
            tag_flags := 0;
            tag_tree_decompose_tag(proc_name, tag_name, class_name, type_name, tag_flags, signature, return_type);
            if (taggingFlags & VSLTF_SET_TAG_CONTEXT) {
               context_id=tag_insert_context(0, tag_name, type_name, p_buf_name, start_line_no, start_seekpos, start_line_no, start_seekpos, end_line_no, end_seekpos, class_name, tag_flags, return_type"\1"signature);
            } else {
               tag_insert_tag(tag_name, type_name, p_buf_name, start_line_no, class_name, tag_flags, return_type"\1"signature);
            }
         }
         findfirst=0;
      }
      restore_search(p1,p2,p3,p4);
   }

   // restore the max string size parameter
   _default_option(VSOPTION_WARNING_STRING_LENGTH, orig_max);
}

/**
 * Update the current context and context tree message
 * the current object must be the active buffer
 *
 * @param ForceUpdate  force update not matter how big the file
 */
static void _UpdateContext2(boolean ForceUpdate, int nUpdateFlags )
{
#if 1
   // current context names
   _str proc_name;
   _str signature;
   _str return_type;
   int outer_context, dummy_context;
   int start_line_no, start_seekpos;
   int scope_line_no, scope_seekpos;
   int i,end_line_no, end_seekpos;
   outer_context = dummy_context = 0;
   start_line_no = start_seekpos = 0;
   scope_line_no = scope_seekpos = 0;
   end_line_no = end_seekpos = 0;
   proc_name = signature = return_type = '';

   _str tag_name,type_name,class_name,file_name;
   int tag_flags=0;
   int status;

   // lock the current context so that only this thread can update it
   tag_lock_context(true);

   // check current buffer position against context
   if (nUpdateFlags & VS_UPDATEFLAG_statement) nUpdateFlags |= VS_UPDATEFLAG_context;
   if (nUpdateFlags & VS_UPDATEFLAG_statement) nUpdateFlags |= VS_UPDATEFLAG_tokens;
   have_context := tag_check_cached_context(nUpdateFlags);
   if (have_context) {
      if ((nUpdateFlags & VS_UPDATEFLAG_statement) && !(p_ModifyFlags & MODIFYFLAG_STATEMENTS_UPDATED)) {
         have_context = 0;
      } else if ((nUpdateFlags & VS_UPDATEFLAG_tokens) && !(p_ModifyFlags & MODIFYFLAG_TOKENLIST_UPDATED)) {
         have_context = 0;
      } else if (!(nUpdateFlags & VS_UPDATEFLAG_statement) && !(p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED)) {
         have_context = 0;
      }
   }

   // Update if we are forced to update or we do not have a current context
   // Also update if the context is not up to date or we are going to list statements
   // and the statements are not up to date
   //say("_UpdateContext2: ForceUpdate="ForceUpdate" have_context="have_context" file_date="p_file_date" last_modified="p_LastModified" buffer="p_buf_name" num_symbols="tag_get_num_of_context()" flags="nUpdateFlags);
   if ( ForceUpdate || !have_context ) { //|| !(p_ModifyFlags&MODIFYFLAG_CONTEXT_UPDATED) ||
        //( ( nUpdateFlags & VS_UPDATEFLAG_statement ) && !(p_ModifyFlags&MODIFYFLAG_STATEMENTS_UPDATED) ) ) {

      //if (p_buf_name != ''  ) {
      //   say("_UpdateContext2: updateflags = "nUpdateFlags);
      //   say("_UpdateContext:  Recalculating context="have_context" modify=":+(p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED) " file="p_buf_name);
      //   _StackDump(); 
      //}

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
      //int orig_time=(int) _time('b');

      // find extension specific tagging functions
      LTindex := _FindLanguageCallbackIndex('vs%s-list-tags');
      PSindex := _FindLanguageCallbackIndex('%s-proc-search');

      if (LTindex) {
         // call list-tags with LTF_SET_TAG_CONTEXT flags
         // might want to update proctree at same time

         SSindex := _FindLanguageCallbackIndex('%s_are_statements_supported');
         int ltf_flags = VSLTF_SET_TAG_CONTEXT;
         if ( ( nUpdateFlags & VS_UPDATEFLAG_statement ) && SSindex && call_index(0, '', p_LangId, 0, SSindex ) ) {
            ltf_flags |= VSLTF_LIST_STATEMENTS;
         }

         INCindex := _FindLanguageCallbackIndex('%s_is_incremental_supported');
         if ( false && INCindex != 0 && call_index(0, '', p_LangId, 0, INCindex ) ) {
            nUpdateFlags |= VS_UPDATEFLAG_tokens;
         }

         TKindex := _FindLanguageCallbackIndex('%s_is_tokenlist_supported');
         if ( ( nUpdateFlags & VS_UPDATEFLAG_tokens ) && TKindex != 0 && call_index(0, '', p_LangId, 0, TKindex ) ) {
            ltf_flags |= VSLTF_SAVE_TOKENLIST;
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
               if (!(ltf_flags & VSLTF_ASYNCHRONOUS) && (pos("tagscntx",p_buf_name) > 0)) {
                  say("_UpdateContext: INCREMENTAL start="start_offset" end="end_offset);
                  say("_UpdateContext: INCREMENTAL time="(long)_time('b')-(long)origTime" mod="p_LastModified" statements="((ltf_flags & VSLTF_LIST_STATEMENTS)? "on":"off")" tokens="((ltf_flags & VSLTF_SAVE_TOKENLIST)? "on":"off"));
               }

               // Unlock the context and return
               tag_unlock_context();
               return;
            }
         }

         save_pos(auto p);
         tag_clear_context(p_buf_name, true);
         tag_clear_embedded();
         status = call_index(0, '', p_LangId, ltf_flags, LTindex);
//       if (!(ltf_flags & VSLTF_ASYNCHRONOUS) && (pos("tagscntx",p_buf_name) > 0)) {
//          say("_UpdateContext: LT time="(long)_time('b')-(long)origTime" mod="p_LastModified" statements="((ltf_flags & VSLTF_LIST_STATEMENTS)? "on":"off")" tokens="((ltf_flags & VSLTF_SAVE_TOKENLIST)? "on":"off"));
//       }
         // now do embedded proc search
         //finalTime := _time('b');
         //if (file_eq(p_buf_name,  'E:\15.0.0-svn\slickedit\rt\slick\gui.cpp') && (ltf_flags & VSLTF_LIST_STATEMENTS) != 0) {
         //   say("_UpdateContext2: elapsed="(int)finalTime-(int)origTime);
         //}

         if (tag_get_num_of_embedded()) {
            _UpdateEmbeddedContext(ltf_flags);
         }
         // restore position and we are done
         restore_pos(p);

      } else if (index_callable(PSindex)) {
         // call proc-search to find current context
         tag_clear_context(p_buf_name);
         typeless p,p1,p2,p3,p4;
         save_pos(p);
         save_search(p1,p2,p3,p4);
         top();
         proc_name='';
         int findfirst=1;
         int context_id=0;
         for (;;) {
            //say("_UpdateContext");
            proc_name='';
            status=call_index(proc_name,findfirst,p_LangId,PSindex);
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
            if (proc_name != '') {
               // search backward for non-blank character
               tag_tree_decompose_tag(proc_name, tag_name, class_name, type_name, tag_flags, signature, return_type);
               context_id=tag_insert_context(0, tag_name, type_name, p_buf_name, start_line_no, start_seekpos, start_line_no, start_seekpos, end_line_no, end_seekpos, class_name, tag_flags, return_type"\1"signature);
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
   }

   // check if this file has too many tags
   if (!ForceUpdate && tag_get_num_of_context() > def_update_context_max_symbols) {
      gcontext_files_too_large:[p_buf_name] = true;
      handleUpdateContextFailure("FILE HAS TOO MANY TAGS!","def_update_context_max_symbols");
      tag_unlock_context();
      return;
   } else {
      gcontext_files_too_large._deleteel(p_buf_name);
   }

   // sort the items in the current context by seekpos
   tag_sort_context();

   // call post-processing function for update context
   AUindex := _FindLanguageCallbackIndex('_%s_after_UpdateContext');
   if (AUindex) {
      typeless p1,p2,p3,p4;
      save_search(p1,p2,p3,p4);
      call_index(AUindex);
      restore_search(p1,p2,p3,p4);
   }

   // set the modify flags, showing that the context is up to date
   p_ModifyFlags |= MODIFYFLAG_CONTEXT_UPDATED;

   // set modify flags for statements if we just updated them
   if( nUpdateFlags & VS_UPDATEFLAG_statement ) {
      p_ModifyFlags |= MODIFYFLAG_STATEMENTS_UPDATED;
   } else if( nUpdateFlags & VS_UPDATEFLAG_tokens ) {
      p_ModifyFlags |= MODIFYFLAG_TOKENLIST_UPDATED;
   }

   // unlock the current context so that other threads may now read it
   tag_unlock_context();

#else
   tag_update_context();
#endif
}

static void _SaveLocalVariables(boolean (&outer_hash):[], 
                                VS_TAG_BROWSE_INFO (&outer_locals)[])
{
   // save/append the current locals to the array
   n := tag_get_num_of_locals();
   for (i:=1; i<=n; i++) {
      VS_TAG_BROWSE_INFO cm;
      tag_get_local_info(i, cm);
      if (!outer_hash._indexin(cm.member_name';'cm.seekpos)) {
         outer_locals[outer_locals._length()] = cm;
         outer_hash:[cm.member_name';'cm.seekpos]=true;
      }
      //say("Cgot "cm.member_name);
   }
}
static void _RestoreLocalVariables(VS_TAG_BROWSE_INFO (&outer_locals)[])
{
   // append locals from inner functions
   tag_clear_locals(0);
   n := outer_locals._length();
   for (i:=0; i<n; i++) {
      VS_TAG_BROWSE_INFO cm = outer_locals[i];
      //say("_UpdateLocals2: member="cm.member_name" flags="cm.flags" seekpos="cm.seekpos" hash="(outer_hash._indexin(cm.member_name';'cm.seekpos)? "true":"false"));
      _str local_sig = cm.return_type;
      if (cm.arguments!='') {
         strappend(local_sig, VS_TAGSEPARATOR_args:+cm.arguments);
      }
      if (cm.exceptions!='') {
         strappend(local_sig, VS_TAGSEPARATOR_throws:+cm.exceptions);
      }
      k:=tag_insert_local2(cm.member_name, cm.type_name, cm.file_name,
                           cm.line_no, cm.seekpos,
                           cm.scope_line_no, cm.scope_seekpos,
                           cm.end_line_no, cm.end_seekpos,
                           cm.class_name, cm.flags, local_sig);
      if (cm.class_parents!='') {
         tag_set_local_parents(k,cm.class_parents);
      }
      if (cm.template_args!='') {
         tag_set_local_template_signature(k,cm.template_args);
      }
      if (cm.name_line_no > 0) {
         tag_set_local_name_location(k,cm.name_line_no,cm.name_seekpos);
      }
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

static void _UpdateLocalsInLocalFunctions(boolean (&local_hash):[], int end_seekpos)
{
   // list locals for each level of local
   boolean outer_hash:[];
   VS_TAG_BROWSE_INFO outer_locals[];
   boolean in_local_function=false;
   func_nesting := 0;
   local_id := tag_current_local();
   while (local_id>0 && func_nesting<MAX_FUNCTION_NESTING) {

      cur_type_name := "";
      cur_tag_name  := "";
      tag_get_detail2(VS_TAGDETAIL_local_type, local_id, cur_type_name);
      tag_get_detail2(VS_TAGDETAIL_local_name, local_id, cur_tag_name);
      //say("_UpdateLocals(): local_id="local_id "type="cur_type_name" name="cur_tag_name);

      // get the type, start line, seekpos, end seekpos information for parsing
      cur_start_line_no := 0;
      cur_start_seekpos := 0;
      cur_end_seekpos   := 0;
      cur_tag_flags     := 0;
      tag_get_detail2(VS_TAGDETAIL_local_type, local_id, cur_type_name);
      tag_get_detail2(VS_TAGDETAIL_local_start_linenum, local_id, cur_start_line_no);
      tag_get_detail2(VS_TAGDETAIL_local_start_seekpos, local_id, cur_start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_local_end_seekpos,   local_id, cur_end_seekpos);
      tag_get_detail2(VS_TAGDETAIL_local_flags,         local_id, cur_tag_flags);

      // check that the current local is a function
      if ((tag_tree_type_is_func(cur_type_name) ||
          ((cur_tag_flags & VS_TAGFLAG_template) && tag_tree_type_is_class(cur_type_name))) &&
          !local_hash._indexin(cur_start_seekpos)) {

         //say("_UpdateLocalsInLocalFunctions: TAGGING LOCAL FUNCTION");
         //say("_UpdateLocals: time loop ="_time('b'));

         // save/append the current locals to the array
         _SaveLocalVariables(outer_hash, outer_locals);
         tag_clear_locals(0);

         // call list-locals with LTF_SET_TAG_CONTEXT flags
         if (cur_type_name!='proto' && cur_type_name!='procproto') {
            in_local_function=true;
         }
         local_hash:[cur_start_seekpos]=true;

         // start seekposition should be adjusted to skip leading spaces.
         // that way the column number is more likely to be correct
         start_seekpos := find_start_of_spaces_before(cur_start_seekpos);

         save_pos(auto p);
         p_RLine = cur_start_line_no;
         //say("LCUR_START_SEEKPOS="cur_start_seekpos" LEND_SEEKPOS="cur_end_seekpos);
         _GoToROffset(start_seekpos);

         // look up the list-locals function according to the embedded context
         typeless orig_values;
         int embedded=_EmbeddedStart(orig_values);
         LLindex := _FindLanguageCallbackIndex('%s-list-locals');
         _str embedded_lang=p_LangId;
         if (embedded==1) {
            _EmbeddedEnd(orig_values);
            embedded=0;
         }

         // only call list-locals if we have a list-locals function
         if (LLindex) {
            ltf_flags := VSLTF_SET_TAG_CONTEXT|VSLTF_LIST_LOCALS;
            call_index(0,'',embedded_lang,ltf_flags,0,0,start_seekpos,end_seekpos,LLindex);
         }
         restore_pos(p);

         // save/append the current locals to the array
         _SaveLocalVariables(outer_hash, outer_locals);

         // append locals from inner functions
         if (outer_locals._length() > tag_get_num_of_locals()) {
            _RestoreLocalVariables(outer_locals);

            // sort the local variables by seekpos
            //say("_UpdateLocals: sort ="_time('b'));
            tag_sort_locals();
         }

         // may have to recalculate current local, if we have
         // local functions are nested two or more levels deep.
         local_id = tag_current_local();
         continue;
      }

      // get the next level higher of function nesting
      tag_get_detail2(VS_TAGDETAIL_local_outer, local_id, local_id);
      func_nesting++;
   }
}

/**
 * Update the list of local variables in the current function.
 * Current object must be the current buffer.
 *
 * @param AlwaysUpdate  update right away (ignored)?
 * @param list_all      list all locals, or only those visible in context?
 */
void _UpdateLocals(boolean AlwaysUpdate=false, boolean list_all=false)
{
   // if this buffer is not taggable, blow out of here
   //say("_UpdateLocals("AlwaysUpdate","list_all")");
   if (!_isEditorCtl()) {
      //say("NOT AN EDITOR CONTROL!");
      return;
   }

   // make sure timer has waited long enough
   if (!AlwaysUpdate && _idle_time_elapsed() < def_update_tagging_idle) {
      return;
   }

   // update the context, is the current context defined?
   tag_lock_context(true);
   _UpdateContext(true);
   int context_id = tag_current_context();
   int cur_start_line_no=0;
   int cur_start_seekpos=0;
   int cur_scope_seekpos=0;
   int cur_end_seekpos=0;
   int cur_tag_flags=0;
   if (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, cur_start_line_no);
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, cur_start_seekpos);
      tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, cur_scope_seekpos);
      tag_get_detail2(VS_TAGDETAIL_context_end_seekpos,   context_id, cur_end_seekpos);
   }

   //say("_UpdateLocals: start="cur_start_seekpos" scope="cur_scope_seekpos" end="cur_end_seekpos);

   // end seekpos is position of cursor or end of function
   end_seekpos := cur_end_seekpos; 
   if (!list_all) {
      end_seekpos=(int)_QROffset();
   }

   // start seekposition should be adjusted to skip leading spaces.
   // that way the column number is more likely to be correct
   start_seekpos := (int)find_start_of_spaces_before(cur_start_seekpos);

   // locals already up to date?
   if (tag_check_cached_locals(start_seekpos, end_seekpos, context_id, (int)list_all)) {
      //say("_UpdateLocals: using cached locals");
      if (p_ModifyFlags & MODIFYFLAG_LOCALS_UPDATED) {
         tag_unlock_context();
         return;
      }
   }
   //say("_UpdateLocals: Recalculating locals");

   // update the context, is the current context defined?
   if (context_id <= 0) {
      tag_clear_locals(0);
      //say("_UpdateLocals: NO CURRENT CONTEXT");
      tag_unlock_context();
      return;
   }

   // set list-locals flags appropriately
   ltf_flags := VSLTF_SET_TAG_CONTEXT|VSLTF_LIST_LOCALS;
   if (!list_all) {
      ltf_flags |= VSLTF_SKIP_OUT_OF_SCOPE;
   }

   // check if we have support for local variable search
   boolean outer_hash:[];
   VS_TAG_BROWSE_INFO outer_locals[];
   tag_clear_locals(0);
   int orig_time=(int)_time('b');
   int i,k,n;
   int LLindex=0;

   //say("_UpdateLocals: time="_time('b'));
   _str cur_type_name,cur_tag_name;

   // list locals for each level of context
   boolean local_hash:[];
   int func_nesting=0;
   context_id = tag_current_context();
   while (context_id>0 && func_nesting<MAX_FUNCTION_NESTING) {

      // check that the current context is a function
      tag_get_detail2(VS_TAGDETAIL_context_type, context_id, cur_type_name);
      tag_get_detail2(VS_TAGDETAIL_context_name, context_id, cur_tag_name);
      tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, cur_tag_flags);
      //say("_UpdateLocals(): context_id="context_id "type="cur_type_name" name="cur_tag_name);

      if (tag_tree_type_is_func(cur_type_name) || 
          cur_type_name=='define' || cur_type_name=='block' ||
          ((cur_tag_flags & VS_TAGFLAG_template) && tag_tree_type_is_class(cur_type_name))) {

         // get the start line, seekpos, end seekpos information for parsing
         tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, cur_start_line_no);
         tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, cur_start_seekpos);
         tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, cur_scope_seekpos);
         tag_get_detail2(VS_TAGDETAIL_context_end_seekpos, context_id, end_seekpos);
         if (context_id==tag_current_context() && !list_all &&
             cur_type_name!='proto' && cur_type_name!='procproto') {
            save_pos(auto before_p);
            _end_line();
            end_seekpos=(int)_QROffset();
            restore_pos(before_p);
         }
         if (cur_scope_seekpos > cur_start_seekpos &&
             end_seekpos > cur_scope_seekpos &&
             tag_tree_type_is_class(cur_type_name) && cur_type_name!='task') {
            end_seekpos = cur_scope_seekpos;
         }
         if (cur_scope_seekpos > cur_start_seekpos &&
             end_seekpos < cur_scope_seekpos &&
             tag_tree_type_is_func(cur_type_name)) {
            end_seekpos = cur_scope_seekpos;
         }

         // start seekposition should be adjusted to skip leading spaces.
         // that way the column number is more likely to be correct
         start_seekpos = (int)find_start_of_spaces_before(cur_start_seekpos);

         // call list-locals with LTF_SET_TAG_CONTEXT flags
         tag_clear_locals(0);
         local_hash:[cur_start_seekpos]=true;
         save_pos(auto p);
         p_RLine = cur_start_line_no;
         //say("CCUR_START_SEEKPOS="cur_start_seekpos" CEND_SEEKPOS="end_seekpos);
         _GoToROffset(start_seekpos);

         // look up the list-locals function according to the embedded context
         typeless orig_values;
         int embedded=_EmbeddedStart(orig_values);
         LLindex = _FindLanguageCallbackIndex('%s-list-locals');
         _str embedded_lang=p_LangId;
         if (embedded==1) {
            _EmbeddedEnd(orig_values);
         }

         // only call list-locals if we have a list-locals function
         if (LLindex) {
            call_index(0,'',embedded_lang,ltf_flags,0,0,start_seekpos,end_seekpos,LLindex);
         }
         restore_pos(p);

         // save/append the current locals to the array
         _SaveLocalVariables(outer_hash, outer_locals);
      }

      // get the next level higher of function nesting
      tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, context_id);
      func_nesting++;
   }

   // append locals from inner functions
   if (outer_locals._length() > tag_get_num_of_locals()) {
      _RestoreLocalVariables(outer_locals);
   }

   // check if any of the locals have nested functions containing further
   // local variables.
   _UpdateLocalsInLocalFunctions(local_hash, end_seekpos);

   //say("_UpdateLocals: "n" locals in outer_locals");
   //n=outer_locals._length();
   //for (i=0; i<n; i++) {
   //   VS_TAG_BROWSE_INFO cm = outer_locals[i];
   //   say("_UpdateLocals3: member="cm.member_name" flags="cm.flags" seekpos="cm.seekpos" hash="(outer_hash._indexin(cm.member_name';'cm.seekpos)? "true":"false"));
   //}

   // sort the local variables by seekpos
   //say("_UpdateLocals: sort ="_time('b'));

   tag_sort_locals();

   //say("_UpdateLocals: after ="_time('b'));

   // call post-processing function for update locals
   AUindex := _FindLanguageCallbackIndex('_%s_after_UpdateLocals');
   if (index_callable(AUindex)) {
      call_index(AUindex);
   }

   // dump out local variable information
   //int j;
   //typeless class_parents, proc_name, type_name, start_seekpos, start_linenum, end_linenum, outer_context;
   //say("_UpdateLocals: "tag_get_num_of_locals()" locals");
   //for (j=1; j<=tag_get_num_of_locals(); j++) {
   //   tag_get_detail2(VS_TAGDETAIL_local_parents, j, class_parents);
   //   tag_get_detail2(VS_TAGDETAIL_local_name, j, proc_name);
   //   tag_get_detail2(VS_TAGDETAIL_local_type, j, type_name);
   //   tag_get_detail2(VS_TAGDETAIL_local_start_seekpos, j, start_seekpos);
   //   tag_get_detail2(VS_TAGDETAIL_local_end_seekpos, j, end_seekpos);
   //   tag_get_detail2(VS_TAGDETAIL_local_start_linenum, j, start_linenum);
   //   tag_get_detail2(VS_TAGDETAIL_local_end_linenum, j, end_linenum);
   //   tag_get_detail2(VS_TAGDETAIL_local_outer, j, outer_context);
   //   say("   LCL: j="j" name="proc_name" type="type_name" parents="class_parents" start="start_seekpos" end="end_seekpos" sline="start_linenum" eline="end_linenum" outer="outer_context);
   //}
   //say("_UpdateLocals(): current="tag_current_local());

   //say("_UpdateLocals: final="(int)_time('b')-orig_time);

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
   if (signature=='void') {
      return '';
   }
   _str new_signature = '';
   while (signature != '') {
      int p = pos('(:v|[;,*&^]|\[|\])', signature, 1, 'r');
      if (!p) {
         break;
      }
      _str ch = substr(signature, p, pos(''));
      signature = substr(signature, p+pos('')+1);
      switch (ch) {
      case ';':
      case ',':
      case '*':
      case '&':
      case '^':
      case '[':
      case ']':
      case 'int':
      case 'integer':
      case 'real':
      case 'double':
      case 'float':
      case 'char':
      case 'bool':
      case 'boolean':
      case 'const':
      case 'void':
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
                                 _str &abstract_indexes, boolean only_abstract,
                                 int treewid, int tree_index,
                                 typeless tag_files, int depth, int firstCall,
                                 int &num_matches, int max_matches,
                                 boolean allow_locals, boolean case_sensitive,
                                 _str (&found_virtual):[], 
                                 _str (&norm_visited):[])
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

   //say("_ListVirtualMethodsR("search_class_name")");

   // try to find symbols in this specific class first
   boolean found_definition=false;
   _str outer_class_name, inner_class_name;
   tag_split_class_name(search_class_name, inner_class_name, outer_class_name);
   _str class_parents = '';
   _str file_name = '';
   _str tag_filename;
   int i,k,status;
   int flag_mask=VS_TAGFLAG_const|VS_TAGFLAG_volatile|VS_TAGFLAG_mutable;

   // are all methods abstract (is this an interface?)
   boolean all_abstract = false;
   if (search_type=='interface' /*&& depth==0 */) {
      all_abstract = true;
   }

   _str type_name='';
   int tag_flags=0;
   _str tag_name='';
   _str signature='';

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // for function context, first try to find a local variable
   if (allow_locals) {
      // find abstract functions
      i = tag_find_local_iterator('', false, case_sensitive, false, search_class_name);
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_local_type, i, type_name);
         tag_get_detail2(VS_TAGDETAIL_local_flags, i, tag_flags);
         if (tag_tree_type_is_func(type_name) && (tag_flags & VS_TAGFLAG_inclass) &&
             (depth==0 || (tag_flags & VS_TAGFLAG_access) != VS_TAGFLAG_private || (tag_flags & VS_TAGFLAG_abstract)) &&
             !(tag_flags & VS_TAGFLAG_final) && !(tag_flags & VS_TAGFLAG_destructor)) {
            tag_get_detail2(VS_TAGDETAIL_local_name, i, tag_name);
            tag_get_detail2(VS_TAGDETAIL_local_args, i, signature);
            if (tag_flags&flag_mask) strappend(tag_name,'/'(tag_flags&flag_mask));
            if (signature != '') strappend(tag_name,'/'compress_signature(signature));
            if (!found_virtual._indexin(tag_name)) {
               if (all_abstract || (tag_flags & VS_TAGFLAG_abstract) ||
                   (!only_abstract && (tag_flags & VS_TAGFLAG_virtual))) {
                  if (treewid) {
                     k=tag_tree_insert_fast(treewid,tree_index,VS_TAGMATCH_local,i,0,1,0,0,0);
                  } else {
                     k=tag_insert_match_fast(VS_TAGMATCH_local,i);
                  }
                  if (all_abstract || (tag_flags & VS_TAGFLAG_abstract)) {
                     strappend(abstract_indexes,k' ');
                  }
                  found_virtual:[tag_name] = type_name;
                  if (k < 0 || ++num_matches >= max_matches) {
                     break;
                  }
               } 
            }
         }
         i = tag_next_local_iterator('', i, false, case_sensitive, false, search_class_name);
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
      i = tag_find_context_iterator('', false, case_sensitive, false, search_class_name);
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
         tag_get_detail2(VS_TAGDETAIL_context_flags, i, tag_flags);
         if (tag_tree_type_is_func(type_name) && (tag_flags & VS_TAGFLAG_inclass) &&
             (depth==0 || (tag_flags & VS_TAGFLAG_access) != VS_TAGFLAG_private || (tag_flags & VS_TAGFLAG_abstract)) &&
             !(tag_flags & VS_TAGFLAG_final) && !(tag_flags & VS_TAGFLAG_destructor)) {
            tag_get_detail2(VS_TAGDETAIL_context_name, i, tag_name);
            tag_get_detail2(VS_TAGDETAIL_context_args, i, signature);
            if (tag_flags&flag_mask) strappend(tag_name,'/'(tag_flags&flag_mask));
            if (signature != '') strappend(tag_name,'/'compress_signature(signature));
            //say("Considering "tag_name":"tag_flags);

            if (!found_virtual._indexin(tag_name)) {
               if (all_abstract || (tag_flags & VS_TAGFLAG_abstract) ||
                   (!only_abstract && (tag_flags & VS_TAGFLAG_virtual))) {
                  if (treewid) {
                     k=tag_tree_insert_fast(treewid,tree_index,VS_TAGMATCH_context,i,0,1,0,0,0);
                  } else {
                     k=tag_insert_match_fast(VS_TAGMATCH_context,i);
                  }
                  if (all_abstract || (tag_flags & VS_TAGFLAG_abstract)) {
                     strappend(abstract_indexes,k' ');
                  }
                  found_virtual:[tag_name] = type_name;
                  if (k < 0 || ++num_matches >= max_matches) {
                     break;
                  }
               }
            }
         }
         i = tag_next_context_iterator('', i, false, case_sensitive, false, search_class_name);
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
      while (tag_filename != '') {
         status = tag_find_in_class(search_class_name);
         while (!status) {
            tag_get_detail(VS_TAGDETAIL_type, type_name);
            tag_get_detail(VS_TAGDETAIL_flags, tag_flags);
            //say("CANDIDATE: "tag_name" flags="(tag_flags & VS_TAGFLAG_abstract));
            if (tag_tree_type_is_func(type_name) && (tag_flags & VS_TAGFLAG_inclass) &&
                (depth==0 || (tag_flags & VS_TAGFLAG_access) != VS_TAGFLAG_private || (tag_flags & VS_TAGFLAG_abstract)) &&
                !(tag_flags & VS_TAGFLAG_final) && !(tag_flags & VS_TAGFLAG_destructor)) {
               tag_get_detail(VS_TAGDETAIL_name, tag_name);
               tag_get_detail(VS_TAGDETAIL_arguments, signature);
               if (tag_flags&flag_mask) strappend(tag_name,'/'(tag_flags&flag_mask));
               if (signature != '') strappend(tag_name,'/'compress_signature(signature));
               //say("Considering2 "tag_name":"tag_flags" A("(tag_flags&VS_TAGFLAG_abstract)") V("(tag_flags&VS_TAGFLAG_virtual)")");
               if (!found_virtual._indexin(tag_name)) {
                  if (all_abstract || (tag_flags & VS_TAGFLAG_abstract) ||
                      (!only_abstract && (tag_flags & VS_TAGFLAG_virtual))) {
                     //say("  MATCH");
                     if (treewid) {
                        k=tag_tree_insert_fast(treewid,tree_index,VS_TAGMATCH_tag,0,0,1,0,0,0);
                     } else {
                        k=tag_insert_match_fast(VS_TAGMATCH_tag,0);
                     }
                     if (all_abstract || (tag_flags & VS_TAGFLAG_abstract)) {
                        strappend(abstract_indexes,k' ');
                     }
                     found_virtual:[tag_name] = type_name;
                     if (k < 0 || ++num_matches >= max_matches) {
                        break;
                     }
                  }
               }
               if (file_name=='' && (tag_flags & VS_TAGFLAG_inclass)) {
                  tag_get_detail(VS_TAGDETAIL_file_name, file_name);
               }
            }
            status = tag_next_in_class();
         }
         tag_reset_find_in_class();

         // get the class parents, and stop here
         if (!found_definition) {
            status = tag_get_inheritance(search_class_name, class_parents);
            if (!status && class_parents != '') {
               found_definition = true;
            }
         }
         tag_filename = next_tag_filea(tag_files, i, false, true);
      }
   }
   //say("num_matches="num_matches);

   // normalize the list of parents from the database
   _str normalized_parents='';
   _str normalized_types='';
   _str normalized_files='';
   if (class_parents != '') {
      tag_normalize_classes(class_parents, search_class_name, file_name,
                            tag_files, allow_locals, case_sensitive,
                            normalized_parents, normalized_types, normalized_files, norm_visited);
   }

   // demote access level before doing inherited classes
   //if (context_flags & VS_TAGCONTEXT_ALLOW_private) {
   //   context_flags &= ~VS_TAGCONTEXT_ALLOW_private;
   //   context_flags |= VS_TAGCONTEXT_ALLOW_protected;
   //}

   // add each of them to the list also
   while (normalized_parents != '') {
      // add transitively inherited class members
      _str p1,n1;
      parse normalized_parents with p1 ';' normalized_parents;
      parse normalized_types   with n1 ';' normalized_types;
      //say("p1="p1" n1="n1);
      if (depth < MAX_RECURSIVE_SEARCH) {
//         _message_box("depth = "depth" normalized_parents = "normalized_parents);
         parse p1 with p1 '<' .;
         _ListVirtualMethodsR(p1, n1, abstract_indexes,
                              only_abstract, treewid, tree_index,
                              tag_files, depth+1, 0, num_matches, max_matches,
                              allow_locals, case_sensitive, found_virtual, norm_visited);
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
                         _str &abstract_indexes, boolean only_abstract,
                         int treewid, int tree_index,
                         int &num_matches, int max_matches,
                         boolean allow_locals, boolean case_sensitive,
                         boolean removeFromCurrentClass=true)
{
   //say("_ListVirtualMethods("search_class_name")");

   // This function is NOT designed to list globals, bad caller, bad.
   if (search_class_name == '') {
      return;
   }

   // update the current context and locals
//   tag_clear_context();
   _UpdateContext(true);
   _UpdateLocals(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // try to find symbols in this specific class first
   typeless tag_files = tags_filenamea(p_LangId);
   _str found_virtual:[];found_virtual._makeempty();
   _str norm_visited:[]; norm_visited._makeempty();

   //say("Begin list_virtuals=============================");
   _ListVirtualMethodsR(search_class_name, search_type, abstract_indexes, only_abstract,
                        treewid, tree_index, tag_files,
                        (removeFromCurrentClass)?0:1,1,
                        num_matches, max_matches,
                        allow_locals, case_sensitive, found_virtual, norm_visited);
}




/**
 * List the symbols visible in the different contexts, including
 *   -- Locals
 *   -- Class Members
 *   -- Module Variables (static)
 * The current object must be an editor control or current buffer.
 *
 * @return the current class name
 */
_str _MatchThisOrSelf()
{
   //say("_ListThisOrSelf()");
   // update the current context
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   if (context_id <= 0) {
      return '';
   }

   // not a function or proc, not a static method, in a class method
   _str cur_class_name, cur_type_name;
   int cur_tag_flags=0;
   tag_get_detail2(VS_TAGDETAIL_context_class, context_id, cur_class_name);
   tag_get_detail2(VS_TAGDETAIL_context_type,  context_id, cur_type_name);
   tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, cur_tag_flags);
   if (cur_class_name == '' ||
       cur_tag_flags & VS_TAGFLAG_static ||
       !tag_tree_type_is_func(cur_type_name) || cur_type_name :== 'proto') {
      return '';
   }

   // not really a class method, just a member of a package
   typeless tag_files = tags_filenamea(p_LangId);
   _str inner_name, outer_name;
   tag_split_class_name(cur_class_name, inner_name, outer_name);
   if (tag_check_for_package(inner_name, tag_files, true, true)) {
      return '';
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
   // update the current context
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   if (context_id <= 0) {
      return;
   }

   // is this a #define?
   _str type_name;
   tag_get_detail2(VS_TAGDETAIL_context_type, context_id, type_name);
   if (type_name :!= 'define') {
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
   while (signature != '') {
      _str a;
      parse signature with a ',' signature;
      a = strip(a);
      if (a != '' && (prefix=="" || a==prefix)) {
         int k=0;
         if (treewid) {
            k=tag_tree_insert_tag(treewid, tree_index, 0, 1, 0, a, 'param', p_buf_name, start_linenum, '', 0, '');
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

            k=tag_insert_match2('', a, 'param', p_buf_name, 
                                start_linenum, start_seekpos,
                                start_linenum, start_seekpos,
                                start_linenum, start_seekpos+length(a),
                                '', 0, '');

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
   if (type_name :== 'class' && (tag_flags & VS_TAGFLAG_template)) {
      // insert each argument
      while (signature != '') {
         _str a;
         parse signature with a ',' signature;
         a = strip(a);
         if (a != '') {
            type_name = 'var';
            if (pos('class', a)==1) {
               type_name = 'class';
               parse a with 'class' a;
            } else if (pos('typename', a)==1) {
               type_name = 'typedef';
               parse a with 'typename' a;
            } else {
            }
            parse a with a '=' .;
            a = strip(a);
            if (pos('{:v}:b@$',a,1,'r')) {
               a = substr(a, pos('S0'), pos('0'));
            }

            int k;
            if (treewid) {
               k=tag_tree_insert_tag(treewid, tree_index, 0, 1, 0, a, type_name, p_buf_name, p_RLine, '', 0, '');
            } else {
               k=tag_insert_match('', a, type_name, p_buf_name, p_RLine, '', 0, '');
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
                               boolean case_sensitive, int &num_matches,
                               int max_matches=MAX_SYMBOL_MATCHES)
{
   //say("_ListParametersOfTemplate()");
   // update the current context
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   if (context_id <= 0) {
      return;
   }

   // is this a template class?
   _str type_name, signature, cur_class_name='';
   int tag_flags;
   tag_get_detail2(VS_TAGDETAIL_context_type,  context_id, type_name);
   tag_get_detail2(VS_TAGDETAIL_context_flags, context_id, tag_flags);
   tag_get_detail2(VS_TAGDETAIL_context_args,  context_id, signature);
   tag_get_detail2(VS_TAGDETAIL_context_class, context_id, cur_class_name);
   _ListParametersOfClass(treewid, tree_index,
                          type_name, tag_flags, signature,
                          num_matches, max_matches);

   // for each level of class nesting
   typeless tag_files = tags_filenamea(p_LangId);
   while (cur_class_name != '') {
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
         int i=0;
         _str tag_filename = next_tag_filea(tag_files, i, false, true);
         while (tag_filename != '') {
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
boolean _GetContextTagInfo(struct VS_TAG_BROWSE_INFO &cm,
                           _str match_tag_database, _str tag_name,
                           _str file_name, int line_no)
{
   //say("_GetContextTagInfo("tag_name","file_name","line_no")");
   tag_browse_info_init(cm);
   cm.tag_database   = match_tag_database;
   if (match_tag_database != '') {
      // find in the given tag database
      int status = tag_read_db(match_tag_database);
      if (status >= 0) {
         status = tag_find_closest(tag_name, file_name, line_no, 1);
         tag_reset_find_tag();
         if (status == 0) {
            tag_get_info(cm.member_name, cm.type_name, cm.file_name, cm.line_no, cm.class_name, cm.flags);
            tag_get_detail(VS_TAGDETAIL_return, cm.return_type);
            tag_get_detail(VS_TAGDETAIL_arguments, cm.arguments);
            tag_get_detail(VS_TAGDETAIL_throws, cm.exceptions);
            tag_get_detail(VS_TAGDETAIL_class_parents, cm.class_parents);
            tag_get_detail(VS_TAGDETAIL_template_args, cm.template_args);
            if (cm.language==null) {
               tag_get_detail(VS_TAGDETAIL_language_id, cm.language);
            }
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
         int context_line=0;
         tag_get_detail2(VS_TAGDETAIL_local_line,  i, context_line);
         if (context_line == line_no) {
            tag_get_local_info(i, cm);
            if (file_eq(cm.file_name,file_name) || (cm.flags&VS_TAGFLAG_extern_macro)) {
               return true;
            }
         }
         i = tag_next_local_iterator(tag_name, i, true, true);
      }
      // maybe it was from the current file?
      i = tag_find_context_iterator(tag_name, true, true);
      while (i > 0) {
         int context_line=0;
         tag_get_detail2(VS_TAGDETAIL_context_line, i, context_line);
         if (context_line == line_no) {
            typeless d1,d2,d3,d4,d5;
            tag_get_context_info(i, cm);
            if (file_eq(cm.file_name,file_name) || (cm.flags&VS_TAGFLAG_extern_macro)) {
               return true;
            }
         }
         i = tag_next_context_iterator(tag_name, i, true, true);
      }
   }
   // did not find a match, really quite depressing, use what we know
   cm.member_name = tag_name;
   cm.type_name   = '';
   cm.file_name   = file_name;
   cm.line_no     = line_no;
   cm.class_name  = '';
   cm.flags       = 0;
   cm.arguments   = '';
   cm.return_type = '';
   cm.exceptions  = '';
   cm.class_parents = '';
   cm.template_args = '';
   if (cm.language==null) {
      cm.language   = '';
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
   int num_sets = 0;
   int i, first_item = 1;
   boolean all_indexes[]; all_indexes._makeempty();
   _str equiv_indexes[]; equiv_indexes._makeempty();

   // initialize the set of match indexes
   for (i=1; i<=num_matches; i++) {
      all_indexes[i] = true;
   }

   _str cur_type_name, cur_signature, cur_proc_name;
   int cur_line_no;
   _str cur_file_name;

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
      //say("removeDuplicateFunctions: proc_name="cur_proc_name" sig="cur_signature" type="cur_type_name);

      // find items in its equivelance class
      for (i=first_item+1; i<=num_matches; i++) {
         if (all_indexes[i]) {
            // declare variables
            _str i_type_name, i_signature, i_proc_name;
            int i_line_no=0;
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
               //say("removeDuplicateFunctions: proc_name[i]="i_proc_name" sig="i_signature" type="i_type_name);
               if (_LanguageInheritsFrom('cs')) {
                  i_signature = stranslate(i_signature, "ref_#0", "ref:b{:v}", 'rew');
                  i_signature = stranslate(i_signature, "out_#0", "ref:b{:v}", 'rew');
                  cur_signature = stranslate(cur_signature, "ref_#0", "ref:b{:v}", 'rew');
                  cur_signature = stranslate(cur_signature, "out_#0", "ref:b{:v}", 'rew');
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
                  if (abs(i_line_no-cur_line_no)<5 && file_eq(i_file_name,cur_file_name) &&
                      i_type_name == cur_type_name) {
                     all_indexes[i]= false;
                     --num_left;
                  } else {
                     all_indexes[i]= false;
                     strappend(equiv_indexes[num_sets], ' 'i);
                     --num_left;
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
      int best_match = 0;
      int best_score = 0;
      while (equiv_indexes[i] != '') {
         typeless k;
         parse equiv_indexes[i] with k equiv_indexes[i];
         // calculate weighted score for this match
         int i_score = 1;
         _str k_type_name;
         int k_tag_flags;
         tag_get_detail2(VS_TAGDETAIL_match_type,k,k_type_name);
         tag_get_detail2(VS_TAGDETAIL_match_flags,k,k_tag_flags);
         // good to be a proc or proto (might have default values)
         if (k_type_name=='proto' || k_type_name=='procproto') {
            i_score++;
         }
         // not good to be external (can omit prototype in Pascal)
         if (!(k_tag_flags & VS_TAGFLAG_extern)) {
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
 * @param cm   tag browse info structure to initialize
 *
 * @categories Tagging_Functions
 */
void tag_browse_info_init(struct VS_TAG_BROWSE_INFO &cm)
{
   cm.arguments='';
   cm.category='';
   cm.class_name='';
   cm.end_line_no=0;
   cm.end_seekpos=0;
   cm.exceptions='';
   cm.language='';
   cm.file_name='';
   cm.flags=0;
   cm.line_no=0;
   cm.member_name='';
   cm.qualified_name='';
   cm.return_type='';
   cm.name_line_no=0;
   cm.name_seekpos=0;
   cm.scope_line_no=0;
   cm.scope_seekpos=0;
   cm.seekpos=0;
   cm.tag_database='';
   cm.type_name='';
   cm.column_no=0;
   cm.template_args='';
   cm.class_parents='';
}

void tag_idexp_info_init(struct VS_TAG_IDEXP_INFO &idexp_info)
{
   idexp_info.errorArgs._makeempty();
   idexp_info.info_flags = 0;
   idexp_info.lastid = '';
   idexp_info.lastidstart_col = 0;
   idexp_info.lastidstart_offset = 0;
   idexp_info.otherinfo = null;
   idexp_info.prefixexp = '';
   idexp_info.prefixexpstart_offset = 0;
}

boolean tag_idexp_info_equal(struct VS_TAG_IDEXP_INFO &lhs, struct VS_TAG_IDEXP_INFO &rhs)
{
   return ( (lhs.info_flags == rhs.info_flags) &&
            (lhs.lastid :== rhs.lastid) &&
            (lhs.lastidstart_col == rhs.lastidstart_col) &&
            (lhs.lastidstart_offset == rhs.lastidstart_offset) &&
            (lhs.otherinfo == rhs.otherinfo) &&
            (lhs.prefixexp :== rhs.prefixexp) &&
            (lhs.prefixexpstart_offset == rhs.prefixexpstart_offset) );
}

void tag_idexp_info_dump(struct VS_TAG_IDEXP_INFO &idexp_info, _str where="")
{
   int i;
   say("//=================================================================");
   say("// idexp info from " where);
   say("//=================================================================");

   say("idexp_info.errorArgs");
   if(idexp_info.errorArgs != null) {
      say("    length = "idexp_info.errorArgs._length());
      for(i = 0; i < idexp_info.errorArgs._length(); i++) {
         if (idexp_info.errorArgs[i]==null) {
            say("    "i"=null");
         } else {
            say("    "i"="idexp_info.errorArgs[i]);
         }
      }
   }
   _str flags = "";
   if(idexp_info.info_flags & VSAUTOCODEINFO_DO_FUNCTION_HELP) {
      strappend(flags, "VSAUTOCODEINFO_DO_FUNCTION_HELP | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_DO_LIST_MEMBERS) {
      strappend(flags, "VSAUTOCODEINFO_DO_LIST_MEMBERS | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      strappend(flags, "VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) {
      strappend(flags, "VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_INITIALIZER_LIST) {
      strappend(flags, "VSAUTOCODEINFO_IN_INITIALIZER_LIST | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_FUNCTION_POINTER_ARGLIST) {
      strappend(flags, "VSAUTOCODEINFO_IN_FUNCTION_POINTER_ARGLIST | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST) {
      strappend(flags, "VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_VAR_OR_PROTOTYPE_DECL) {
      strappend(flags, "VSAUTOCODEINFO_VAR_OR_PROTOTYPE_DECL | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST_TEST) {
      strappend(flags, "VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST_TEST | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_OPERATOR_TYPED) {
      strappend(flags, "VSAUTOCODEINFO_OPERATOR_TYPED | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) {
      strappend(flags, "VSAUTOCODEINFO_IN_GOTO_STATEMENT | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_THROW_STATEMENT) {
      strappend(flags, "VSAUTOCODEINFO_IN_THROW_STATEMENT | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_ALLOW_SPACE_IN_LIST_MEMBERS) {
      strappend(flags, "VSAUTOCODEINFO_ALLOW_SPACE_IN_LIST_MEMBERS | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_DO_SYNTAX_EXPANSION) {
      strappend(flags, "VSAUTOCODEINFO_DO_SYNTAX_EXPANSION | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_NOT_A_FUNCTION_CALL) {
      strappend(flags, "VSAUTOCODEINFO_NOT_A_FUNCTION_CALL | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING) {
      strappend(flags, "VSAUTOCODEINFO_IN_PREPROCESSING | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING_ARGS) {
      strappend(flags, "VSAUTOCODEINFO_IN_PREPROCESSING_ARGS | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) {
      strappend(flags, "VSAUTOCODEINFO_IN_JAVADOC_COMMENT | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS) {
      strappend(flags, "VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_STRING_OR_NUMBER) {
      strappend(flags, "VSAUTOCODEINFO_IN_STRING_OR_NUMBER | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_HAS_REF_OPERATOR) {
      strappend(flags, "VSAUTOCODEINFO_HAS_REF_OPERATOR | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET) {
      strappend(flags, "VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_IN_IMPORT_STATEMENT) {
      strappend(flags, "VSAUTOCODEINFO_IN_IMPORT_STATEMENT | ");
   }
   if(idexp_info.info_flags & VSAUTOCODEINFO_HAS_CLASS_SPECIFIER) {
      strappend(flags, "VSAUTOCODEINFO_HAS_CLASS_SPECIFIER | ");
   }
   // Take out traiiing " | "
   if(flags != "") {
      flags = substr(flags, 1, length(flags)-3);
   }

   say("idexp_info.info_flags='" flags"'");
   say("idexp_info.lastid='"idexp_info.lastid"'");
   say("idexp_info.lastidstart_col="idexp_info.lastidstart_col);
   say("idexp_info.lastidstart_offset="idexp_info.lastidstart_offset);
   if (idexp_info.otherinfo==null) idexp_info.otherinfo="";
   say("idexp_info.otherinfo="idexp_info.otherinfo);
   say("idexp_info.prefixexp='"idexp_info.prefixexp"'");
   say("idexp_info.prefixexpstart_offset="idexp_info.prefixexpstart_offset);
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
boolean tag_browse_info_equal(struct VS_TAG_BROWSE_INFO &cm1,
                              struct VS_TAG_BROWSE_INFO &cm2,
                              boolean case_sensitive=true)
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
   if ((case_sensitive  && cm1.class_name :!= cm2.class_name) ||
       (!case_sensitive && !strieq(cm1.class_name,cm2.class_name))) {
      return false;
   }
   if (cm1.file_name!='' && cm2.file_name!='' && !file_eq(cm1.file_name,cm2.file_name)) {
      return false;
   }
   if ((cm1.arguments!='' && cm2.arguments!='' && cm1.arguments:!=cm2.arguments) ||
       (cm1.return_type!='' && cm2.return_type!='' && cm1.return_type:!=cm2.return_type) ||
       (cm1.exceptions!='' && cm2.exceptions!='' && cm1.exceptions:!=cm2.exceptions) ||
       (cm1.class_parents!='' && cm2.class_parents!='' && cm1.class_parents:!=cm2.class_parents) ||
       (cm1.template_args!='' && cm2.template_args!='' && cm1.template_args:!=cm2.template_args)
      ) {
      return false;
   }
   if (cm1.language!='' && cm2.language!='' && cm1.language!=cm2.language) {
      return false;
   }
   // OK, they are close enough
   return true;
}

/**
 * Print out the full contents of the current context
 */
void _dump_context(_str caption="CONTEXT", int level=0)
{
   n := tag_get_num_of_context();
   for (i:=1; i<=n; i++) {
      tag_get_context_info(i, auto cm);
      tag_browse_info_dump(cm, caption:+"[":+i:+"]", level);
   }
}

/**
 * Print out the full contents of the current set of locals
 */
void _dump_locals(_str caption="LOCALS", int level=0)
{
   n := tag_get_num_of_locals();
   for (i:=1; i<=n; i++) {
      tag_get_local_info(i, auto cm);
      tag_browse_info_dump(cm, caption:+"[":+i:+"]", level);
   }
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

   isay(level,"cm.category=" cm.category);
   isay(level,"cm.class_name=" cm.class_name);
   isay(level,"cm.member_name=" cm.member_name);
   isay(level,"cm.qualified_name=" cm.qualified_name);
   isay(level,"cm.type_name=" cm.type_name);
   isay(level,"cm.file_name=" cm.file_name);
   isay(level,"cm.language=" cm.language);
   isay(level,"cm.line_no=" cm.line_no);
   isay(level,"cm.seekpos=" cm.seekpos);
   isay(level,"cm.name_line_no=" cm.name_line_no);
   isay(level,"cm.name_seekpos=" cm.name_seekpos);
   isay(level,"cm.scope_line_no=" cm.scope_line_no);
   isay(level,"cm.scope_seekpos=" cm.scope_seekpos);
   isay(level,"cm.end_line_no=" cm.end_line_no);
   isay(level,"cm.end_seekpos=" cm.end_seekpos);
   isay(level,"cm.column_no=" cm.column_no);

   _str flags = "";
   if(cm.flags & VS_TAGFLAG_virtual)      flags = flags " virtual |";
   if(cm.flags & VS_TAGFLAG_static)       flags = flags " static |";
   if(cm.flags & VS_TAGFLAG_access) {
      switch (cm.flags & VS_TAGFLAG_access) {
      case VS_TAGFLAG_public:
         strappend(flags,'public |');
         break;
      case VS_TAGFLAG_package:
         //strappend(before_return,'package ');
         // package is default scope for Java
         break;
      case VS_TAGFLAG_protected:
         strappend(flags,'protected |');
         break;
      case VS_TAGFLAG_private:
         strappend(flags,'private |');
         break;
      }
   }
   if(cm.flags & VS_TAGFLAG_const)        flags = flags " const |";
   if(cm.flags & VS_TAGFLAG_final)        flags = flags " final |";
   if(cm.flags & VS_TAGFLAG_abstract)     flags = flags " abstract |";
   if(cm.flags & VS_TAGFLAG_inline)       flags = flags " inline |";
   if(cm.flags & VS_TAGFLAG_operator)     flags = flags " operator |";
   if(cm.flags & VS_TAGFLAG_constructor)  flags = flags " constructor |";
   if(cm.flags & VS_TAGFLAG_volatile)     flags = flags " volatile |";
   if(cm.flags & VS_TAGFLAG_template)     flags = flags " template |";
   if(cm.flags & VS_TAGFLAG_inclass)      flags = flags " inclass |";
   if(cm.flags & VS_TAGFLAG_destructor)   flags = flags " destructor |";
   if(cm.flags & VS_TAGFLAG_const_destr)  flags = flags " const_destr |";
   if(cm.flags & VS_TAGFLAG_synchronized) flags = flags " synchronized |";
   if(cm.flags & VS_TAGFLAG_transient)    flags = flags " transient |";
   if(cm.flags & VS_TAGFLAG_native)       flags = flags " native |";
   if(cm.flags & VS_TAGFLAG_macro)        flags = flags " macro |";
   if(cm.flags & VS_TAGFLAG_extern)       flags = flags " extern |";
   if(cm.flags & VS_TAGFLAG_maybe_var)    flags = flags " maybe_var |";
   if(cm.flags & VS_TAGFLAG_anonymous)    flags = flags " anonymous |";
   if(cm.flags & VS_TAGFLAG_mutable)      flags = flags " mutable |";
   if(cm.flags & VS_TAGFLAG_extern_macro) flags = flags " extern_macro |";
   if(cm.flags & VS_TAGFLAG_linkage)      flags = flags " linkage |";
   if(cm.flags & VS_TAGFLAG_partial)      flags = flags " partial |";
   if(cm.flags & VS_TAGFLAG_ignore)       flags = flags " ignore |";
   if(cm.flags & VS_TAGFLAG_forward)      flags = flags " forward |";
   if(cm.flags & VS_TAGFLAG_opaque)       flags = flags " opaque |";

   // Take out last ' |'
   if (flags != '') {
      flags = substr(flags, 1, length(flags)-2);
   }

   isay(level,"cm.flags=" flags);

   isay(level,"cm.return_type=" cm.return_type);
   isay(level,"cm.arguments=" cm.arguments);
   isay(level,"cm.exceptions=" cm.exceptions);
   isay(level,"cm.class_parents="cm.class_parents);
   isay(level,"cm.template_args="cm.template_args);
}

void tag_dump_context_flags(int context_flags, _str where = "", int level=0)
{
   flags := "";
   if (context_flags & VS_TAGCONTEXT_ALLOW_locals      ) flags :+= "ALLOW_locals |";
   if (context_flags & VS_TAGCONTEXT_ALLOW_private     ) flags :+= "ALLOW_private |";
   if (context_flags & VS_TAGCONTEXT_ALLOW_protected   ) flags :+= "ALLOW_protected |";
   if (context_flags & VS_TAGCONTEXT_ALLOW_package     ) flags :+= "ALLOW_package |";
   if (context_flags & VS_TAGCONTEXT_ONLY_volatile     ) flags :+= "ONLY_volatile |";
   if (context_flags & VS_TAGCONTEXT_ONLY_const        ) flags :+= "ONLY_const |";
   if (context_flags & VS_TAGCONTEXT_ONLY_static       ) flags :+= "ONLY_static |";
   if (context_flags & VS_TAGCONTEXT_ONLY_non_static   ) flags :+= "ONLY_non_static |";
   if (context_flags & VS_TAGCONTEXT_ONLY_data         ) flags :+= "ONLY_data |";
   if (context_flags & VS_TAGCONTEXT_ONLY_funcs        ) flags :+= "ONLY_funcs |";
   if (context_flags & VS_TAGCONTEXT_ONLY_classes      ) flags :+= "ONLY_classes |";
   if (context_flags & VS_TAGCONTEXT_ONLY_packages     ) flags :+= "ONLY_packages |";
   if (context_flags & VS_TAGCONTEXT_ONLY_inclass      ) flags :+= "ONLY_inclass |";
   if (context_flags & VS_TAGCONTEXT_ONLY_constructors ) flags :+= "ONLY_constructors |";
   if (context_flags & VS_TAGCONTEXT_ONLY_this_class   ) flags :+= "ONLY_this_class |";
   if (context_flags & VS_TAGCONTEXT_ONLY_parents      ) flags :+= "ONLY_parents |";
   if (context_flags & VS_TAGCONTEXT_FIND_derived      ) flags :+= "FIND_derived |";
   if (context_flags & VS_TAGCONTEXT_ALLOW_anonymous   ) flags :+= "ALLOW_anonymous |";
   if (context_flags & VS_TAGCONTEXT_ONLY_locals       ) flags :+= "ONLY_locals |";
   if (context_flags & VS_TAGCONTEXT_ALLOW_any_tag_type) flags :+= "ALLOW_any_tag_type |";
   if (context_flags & VS_TAGCONTEXT_ONLY_final        ) flags :+= "ONLY_final |";
   if (context_flags & VS_TAGCONTEXT_ONLY_non_final    ) flags :+= "ONLY_non_final |";
   if (context_flags & VS_TAGCONTEXT_ONLY_context      ) flags :+= "ONLY_context |";
   if (context_flags & VS_TAGCONTEXT_NO_globals        ) flags :+= "NO_globals |";
   if (context_flags & VS_TAGCONTEXT_ALLOW_forward     ) flags :+= "ALLOW_forward |";
   if (context_flags & VS_TAGCONTEXT_FIND_lenient      ) flags :+= "FIND_lenient |";
   if (context_flags & VS_TAGCONTEXT_FIND_all          ) flags :+= "FIND_all |";
   if (context_flags & VS_TAGCONTEXT_FIND_parents      ) flags :+= "FIND_parents |";
   if (context_flags & VS_TAGCONTEXT_ONLY_templates    ) flags :+= "ONLY_templates |";
   if (context_flags & VS_TAGCONTEXT_NO_selectors      ) flags :+= "NO_selectors |";
   if (context_flags & VS_TAGCONTEXT_ONLY_this_file    ) flags :+= "ONLY_this_file |";
   if (context_flags & VS_TAGCONTEXT_NO_groups         ) flags :+= "NO_groups |";
   if (context_flags & VS_TAGCONTEXT_ACCESS_private    ) flags :+= "ACCESS_private |";
   if (context_flags & VS_TAGCONTEXT_ACCESS_protected  ) flags :+= "ACCESS_protected |";
   if (context_flags & VS_TAGCONTEXT_ACCESS_package    ) flags :+= "ACCESS_package |";
   if (context_flags & VS_TAGCONTEXT_ACCESS_public     ) flags :+= "ACCESS_public |";
   if (flags != '') {
      // Take out last ' |'
      flags = substr(flags, 1, length(flags)-2);
   }
   isay(level,"context_flags=" flags);
}

void tag_dump_filter_flags(int filter_flags, _str where = "", int level=0)
{
   flags := "";
   if (filter_flags & VS_TAGFILTER_CASESENSITIVE  ) flags :+= "CASESENSITIVE |";
   if (filter_flags & VS_TAGFILTER_PROC           ) flags :+= "PROC |";
   if (filter_flags & VS_TAGFILTER_PROTO          ) flags :+= "PROTO |";
   if (filter_flags & VS_TAGFILTER_DEFINE         ) flags :+= "DEFINE |";
   if (filter_flags & VS_TAGFILTER_ENUM           ) flags :+= "ENUM |";
   if (filter_flags & VS_TAGFILTER_GVAR           ) flags :+= "GVAR |";
   if (filter_flags & VS_TAGFILTER_TYPEDEF        ) flags :+= "TYPEDEF |";
   if (filter_flags & VS_TAGFILTER_STRUCT         ) flags :+= "STRUCT |";
   if (filter_flags & VS_TAGFILTER_UNION          ) flags :+= "UNION |";
   if (filter_flags & VS_TAGFILTER_LABEL          ) flags :+= "LABEL |";
   if (filter_flags & VS_TAGFILTER_INTERFACE      ) flags :+= "INTERFACE |";
   if (filter_flags & VS_TAGFILTER_PACKAGE        ) flags :+= "PACKAGE |";
   if (filter_flags & VS_TAGFILTER_VAR            ) flags :+= "VAR |";
   if (filter_flags & VS_TAGFILTER_CONSTANT       ) flags :+= "CONSTANT |";
   if (filter_flags & VS_TAGFILTER_PROPERTY       ) flags :+= "PROPERTY |";
   if (filter_flags & VS_TAGFILTER_LVAR           ) flags :+= "LVAR |";
   if (filter_flags & VS_TAGFILTER_MISCELLANEOUS  ) flags :+= "MISCELLANEOUS |";
   if (filter_flags & VS_TAGFILTER_DATABASE       ) flags :+= "DATABASE |";
   if (filter_flags & VS_TAGFILTER_GUI            ) flags :+= "GUI |";
   if (filter_flags & VS_TAGFILTER_INCLUDE        ) flags :+= "INCLUDE |";
   if (filter_flags & VS_TAGFILTER_SUBPROC        ) flags :+= "SUBPROC |";
   if (filter_flags & VS_TAGFILTER_UNKNOWN        ) flags :+= "UNKNOWN |";
   if (filter_flags & VS_TAGFILTER_ANYSYMBOL      ) flags :+= "ANYSYMBOL |";
   if (filter_flags & VS_TAGFILTER_ANYTHING       ) flags :+= "ANYTHING |";
   if (filter_flags & VS_TAGFILTER_ANYPROC        ) flags :+= "ANYPROC |";
   if (filter_flags & VS_TAGFILTER_ANYDATA        ) flags :+= "ANYDATA |";
   if (filter_flags & VS_TAGFILTER_ANYSTRUCT      ) flags :+= "ANYSTRUCT |";
   if (filter_flags & VS_TAGFILTER_ANYCONSTANT    ) flags :+= "ANYCONSTANT |";
   if (filter_flags & VS_TAGFILTER_STATEMENT      ) flags :+= "STATEMENT |";
   if (filter_flags & VS_TAGFILTER_ANNOTATION     ) flags :+= "ANNOTATION |";
   if (filter_flags & VS_TAGFILTER_SCOPE_PRIVATE  ) flags :+= "SCOPE_PRIVATE |";
   if (filter_flags & VS_TAGFILTER_SCOPE_PROTECTED) flags :+= "SCOPE_PROTECTED |";
   if (filter_flags & VS_TAGFILTER_SCOPE_PACKAGE  ) flags :+= "SCOPE_PACKAGE |";
   if (filter_flags & VS_TAGFILTER_SCOPE_PUBLIC   ) flags :+= "SCOPE_PUBLIC |";
   if (filter_flags & VS_TAGFILTER_SCOPE_STATIC   ) flags :+= "SCOPE_STATIC |";
   if (filter_flags & VS_TAGFILTER_SCOPE_EXTERN   ) flags :+= "SCOPE_EXTERN |";
   if (filter_flags & VS_TAGFILTER_ANYACCESS      ) flags :+= "ANYACCESS |";
   if (filter_flags & VS_TAGFILTER_ANYSCOPE       ) flags :+= "ANYSCOPE |";
   if (filter_flags & VS_TAGFILTER_NOBINARY       ) flags :+= "NOBINARY |";
   if (flags != '') {
      // Take out last ' |'
      flags = substr(flags, 1, length(flags)-2);
   }
   isay(level,"filter_flags=" flags);
}

void tag_autocode_arg_info_init(VSAUTOCODE_ARG_INFO &arg_info)
{
   arg_info.ParamName="";
   arg_info.ParamNum=0;
   arg_info.ParamType="";
   arg_info.prototype="";
   arg_info.arglength._makeempty();
   arg_info.argstart._makeempty();
   arg_info.tagList._makeempty();
}

void tag_autocode_arg_info_from_browse_info(VSAUTOCODE_ARG_INFO &arg_info, VS_TAG_BROWSE_INFO &cm)
{
   arg_info.ParamName="";
   arg_info.ParamNum=0;
   arg_info.ParamType="";
   arg_info.prototype="";
   arg_info.arglength._makeempty();
   arg_info.argstart._makeempty();
   arg_info.tagList._makeempty();

   arg_info.prototype = tag_tree_make_caption(cm.member_name, cm.type_name, cm.class_name, cm.flags, cm.arguments, 0);

   arg_info.tagList[0].filename = cm.file_name;
   arg_info.tagList[0].linenum  = cm.line_no;
   arg_info.tagList[0].comment_flags = 0;
   arg_info.tagList[0].comments = "";
   arg_info.tagList[0].taginfo = tag_tree_compose_tag_info(cm);
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
   rt.return_type='';
   rt.taginfo='';
   rt.filename='';
   rt.line_number=0;
   rt.pointer_count=0;
   rt.return_flags=0;
   rt.istemplate=false;
   rt.template_args._makeempty();
   rt.template_names._makeempty();
   rt.template_types._makeempty();
}

/**
 * @return Create a string representation for the given return type.
 * 
 * @param rt               return type structure to convert
 * @param printArgNames    print template arguments
 * 
 * @categories Tagging_Functions
 */
_str tag_return_type_string(struct VS_TAG_RETURN_TYPE &rt, boolean printArgNames=true)
{
   _str result = rt.return_type;
   if (rt.istemplate && rt.template_names._length() > 0) {
      strappend(result,"<");
      int i;
      for (i=0; i<rt.template_names._length(); ++i) {
         _str el = rt.template_names[i];
         if (i > 0) strappend(result,",");
         if (printArgNames) {
            strappend(result,el"=");
         }
         strappend(result,rt.template_args:[el]);
      }
      strappend(result,">");
   }
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
boolean tag_return_type_equal(struct VS_TAG_RETURN_TYPE &rt1,
                              struct VS_TAG_RETURN_TYPE &rt2,
                              boolean case_sensitive=true)
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
void tag_return_type_dump(struct VS_TAG_RETURN_TYPE &rt, _str tag='', int level=0)
{
   isay(level,tag": rt.return_type="rt.return_type);
   isay(level,tag": rt.pointer_count="rt.pointer_count);
   isay(level,tag": rt.return_flags="rt.return_flags);
   isay(level,tag": rt.taginfo="rt.taginfo);
   isay(level,tag": rt.filename="rt.filename);
   isay(level,tag": rt.line_number="rt.line_number);
   isay(level,tag": rt.istemplate="rt.istemplate);
   if (rt.template_args!=null && rt.template_names!=null) {
      int i;
      for (i=0; i<rt.template_names._length(); ++i) {
         _str el = rt.template_names[i];
         isay(level,tag": rt.template_args:["el"]="rt.template_args:[el]);
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
   if (outer_rt.istemplate && pos(outer_rt.return_type,rt.return_type)==1) {
      int i;
      for (i=0; i<outer_rt.template_names._length(); ++i) {
         _str el = outer_rt.template_names[i];
         if (outer_rt.template_args._indexin(el) && !rt.template_args._indexin(el)) {
            rt.template_args:[el] = outer_rt.template_args:[el];
         }
         if (outer_rt.template_types._indexin(el) && !rt.template_types._indexin(el)) {
            rt.template_types:[el] = outer_rt.template_types:[el];
         }
      }
   }
}

