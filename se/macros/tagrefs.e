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
#include "markers.sh"
#import "annotations.e"
#import "bind.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "eclipse.e"
#import "files.e"
#import "help.e"
#import "ini.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "mfsearch.e"
#import "mouse.e"
#import "picture.e"
#import "pmatch.e"
#import "proctree.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "pushtag.e"
#import "quickrefactor.e"
#import "recmacro.e"
#import "saveload.e"
#import "search.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagfind.e"
#import "tagform.e"
#import "tags.e"
#import "tagwin.e"
#import "tbcmds.e"
#import "tbcontrols.e"
#import "se/tags/TaggingGuard.e"
#import "se/search/SearchResults.e"
#import "se/ui/mainwindow.e"
#import "se/ui/toolwindow.e"
#import "se/ui/twevent.e"
#import "taggui.e"
#import "treeview.e"
#import "wfont.e"
#import "window.e"
#import "wkspace.e"
#endregion


//////////////////////////////////////////////////////////////////////////////
_metadata enum_flags TagReferencesFlags {
   VSREF_ZERO                    = 0x0,
   VSREF_FIND_INCREMENTAL        = 0x1,
   VSREF_DO_NOT_GO_TO_FIRST      = 0x2,
   VSREF_NO_WORKSPACE_REFS       = 0x4,
   VSREF_HIGHLIGHT_MATCHES       = 0x8,
   VSREF_SEARCH_WORDS_ANYWAY     = 0x10,
   VSREF_ALLOW_MIXED_LANGUAGES   = 0x20,
   VSREF_NO_AUTO_PUSH            = 0x40,
   VSREF_NO_AUTO_POP             = 0x80,
   VSREF_NO_AUTO_FINISH          = 0x100,
   VSREF_NO_HIGHLIGHT_ALL        = 0x200,
   VSREF_NO_BITMAPS_IN_MARGIN    = 0x400,
   VSREF_FIND_ALL_IMMEDIATELY    = 0x800,
};

TagReferencesFlags def_references_options = VSREF_ZERO;

enum TagAssignmentFilterFlags {
   // This is the way it would be done if "Assigments" were three-state.
   // There isn't much value in filtering out assignments, it just makes
   // the interface more confusing.
   /*
   REF_ASSIGNMENT_FILTER_READS  = 0,
   REF_ASSIGNMENT_FILTER_WRITES = 1,
   REF_ASSIGNMENT_FILTER_NONE   = 2,
   */

   // This way, we are just treating the check box as a two-state, on or off.

   /**
    * No filtering of assignments or reads.
    */
   REF_ASSIGNMENT_FILTER_NONE   = 0,
   /**
    * Filter out references, leaving only occurrences where the 
    * variable in question is being written to. 
    */
   REF_ASSIGNMENT_FILTER_WRITES = 1,

   /**
    * Filter out references where a veriable is written to.
    */
   REF_ASSIGNMENT_FILTER_READS  = 2,  // just a placeholder
}

enum TagConstFilterFlags {
   // This is the way it would be done if "Assigments" were three-state.
   // There isn't much value in filtering out assignments, it just makes
   // the interface more confusing.
   /*
   REF_ASSIGNMENT_FILTER_READS  = 0,
   REF_ASSIGNMENT_FILTER_WRITES = 1,
   REF_ASSIGNMENT_FILTER_NONE   = 2,
   */

   // This way, we are just treating the check box as a two-state, on or off.

   /**
    * No filtering of assignments or reads.
    */
   REF_CONST_FILTER_NONE   = 0,
   /**
    * Filter out references, leaving only occurrences where the 
    * variable in question is not used in const context.
    */
   REF_CONST_FILTER_NON_CONST = 1,

   /**
    * Filter out references where a variable is accessed in a non-const context.
    */
   REF_CONST_FILTER_CONST  = 2,
}

//////////////////////////////////////////////////////////////////////////////

static const REFS_WINDOW_DOC_NAME=     ".References Window Buffer";
static const REFS_FORM_NAME_STRING=    "_tbtagrefs_form";
static const REFS_VISITED_KEY=         "REFERENCES_VISITED";
static const REFS_EXPANDING_NOW=       "EXPANDING_NOW";
static const REFS_EXPANDING_INDEX=     "EXPANDING_INDEX";
static const REFS_EXPANDING_COUNT=     "EXPANDING_COUNT";
static const REFS_EXPANDING_STOPPED=   "EXPANDING_STOPPED";
static const REFS_EXPANDING_HASCANCEL= "EXPANDING_HASCANCEL";

//////////////////////////////////////////////////////////////////////////////
// Timer used for delaying updates after change-selected events,
// allowing you to quickly scroll through the items in the references.
// It is safer for this to global instead of static.
//
//const CB_TIMER_DELAY_MS= 200; defined in cbrowser.sh
static int gReferencesSelectedTimerId=-1;
static int gReferencesHighlightTimerId=-1;
static int gReferencesExpandingTimerId=-1;

// Expression to initialize References tool window with
static _str gFindReferencesExpression="";

// Bitmaps for symbol references and search results
static const REFS_MAX_PIC_TYPES = 8;
int gref_pic_types[]=null;
int _pic_editor_reference=0;
int _pic_editor_search=0;

definit()
{
   if (arg(1)!='L') {
      gReferencesSelectedTimerId=-1;
      gReferencesHighlightTimerId=-1;
      gReferencesExpandingTimerId=-1;
      gFindReferencesExpression="";
      gref_pic_types=null;
   }
}

// This is window that displays the 
// location of a set of symbol references
defeventtab _tbtagrefs_form;

_tbtagrefs_form."F12"()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   } else if (def_keys == "eclipse-keys") {
      activate_editor();
   }
}

_tbtagrefs_form."C-S-PAD-SLASH"()
{
   if (isEclipsePlugin() || def_keys == "eclipse-keys") {
      refs_crunch();
   }
}

_tbtagrefs_form."C-M"()
{
   if (isEclipsePlugin()) {
      eclipse_maximize_part();
   }
}

/** 
 * References searching strategy
 * 
 * @param value            the new value to set, leave blank to 
 *                         retrieve current value 
 * 
 * @return int             the current value 
 */
int _references_options_search_strategy(int value = null)
{
   so := def_references_options;
   if (value == null) {
      // just return the value
      value = (so & (VSREF_FIND_INCREMENTAL | VSREF_FIND_ALL_IMMEDIATELY));
   } else {
      // replace the increment/immediately flags
      so &= ~(VSREF_FIND_INCREMENTAL | VSREF_FIND_ALL_IMMEDIATELY);
      so |= (TagReferencesFlags)(value & (VSREF_FIND_INCREMENTAL | VSREF_FIND_ALL_IMMEDIATELY));
      def_references_options = so;
      _macro_append("def_references_options = "def_references_options";");
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   return value;
}

/**
 * Expand all references in the current references set on demand. 
 * This will bring up a progress dialog as we go through all the files. 
 * 
 * @return Returns 0 if successful. 
 *         Otherwise, TOO_MANY_FILES_RC if the max number of 
 *         references found is exceeded or COMMAND_CANCELLED_RC if cancelled.
 *         On error, a message is displayed on the status line.
 * 
 * @see prev_ref
 * @see next_ref
 * @see find_refs
 * @see push_ref 
 * @see refs_crunch
 * 
 * @appliesTo Edit_Window,Editor_Control
 * @categories Editor_Control_Methods, Edit_Window_Methods, Search_Functions
 */
_command void refs_expand_all() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   f := _GetReferencesWID();
   if (f <= 0) {
      messageNwait(nls("%s1 not found",REFS_FORM_NAME_STRING));
      return;
   }

   _nocheck _control ctlreferences;
   symbolName := f._GetReferencesSymbolName();
   status := f.ctlreferences.expandAllReferencesNow(symbolName);
   if (status) {
      message(get_message(status));
   } else {
      message("All references expanded.");
   }
}
int _OnUpdate_refs_expand_all(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveContextTagging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   f := _GetReferencesWID();
   if (!f) return MF_GRAYED;
   _nocheck _control ctlreferences;
   index := f.ctlreferences._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index <= 0) return MF_GRAYED;
   return MF_ENABLED;
}

/**
 * Collapse all the file nodes in the References tool window.
 * 
 * @see prev_ref
 * @see next_ref
 * @see find_refs
 * @see push_ref 
 * @see refs_expand_all
 * 
 * @appliesTo Edit_Window,Editor_Control
 * @categories Editor_Control_Methods, Edit_Window_Methods, Search_Functions
 */
_command void refs_crunch() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      return;
   }

   refs_kill_all_timers();
   f := _GetReferencesWID();
   if (!f) {
      messageNwait(nls("%s1 not found",REFS_FORM_NAME_STRING));
      return;
   }

   _nocheck _control ctlreferences;
   mou_hour_glass(true);
   int j = f.ctlreferences._TreeGetFirstChildIndex(0);
   while (j > 0) {
      show_children := 0;
      f.ctlreferences._TreeGetInfo(j, show_children);
      if (show_children>=0) {
         f.ctlreferences._TreeDelete(j, 'c');
         if (show_children>0) {
            f.ctlreferences._TreeSetInfo(j, 0);
         }
      }
      j = f.ctlreferences._TreeGetNextSiblingIndex(j);
   }
   f.ctlreferences._TreeColWidth(0,0);
   mou_hour_glass(false);
}
int _OnUpdate_refs_crunch(CMDUI& cmdui, int target_wid, _str command)
{
   return _OnUpdate_refs_expand_all(cmdui, target_wid, command);
}

int _ActivateReferencesWindow()
{
   index := find_index("_refswindow_Activate",PROC_TYPE);
   if( index_callable(index) ) {
      return (call_index(index));
   }
   return activate_tool_window(REFS_FORM_NAME_STRING);
}

//Need to be able to call this from proctree.e and cbrowser.e
int _GetReferencesWID(bool only_when_active=false)
{
   if (!_haveContextTagging()) {
      return 0;
   }
#if 0
   This code probably doesnt support duplicates and when Eclipse
   Core is updated to support the new _MDIXXX calls, this code shouldnt
   be needed.
   if (isEclipsePlugin()) {
      int formWid = _find_object(ECLIPSE_REFERENCESOUTPUT_CONTAINERFORM_NAME,'n');
      if (formWid > 0) {
         return formWid.p_child;
      }
      return 0;
   }
#endif
   int wid;
   if (p_active_form.p_name:==REFS_FORM_NAME_STRING) {
      wid=p_active_form;
   } else {
      wid=_get_focus();
      if (wid && wid.p_active_form.p_name:==REFS_FORM_NAME_STRING) {
         wid=wid.p_active_form;
      } else {
         int cur_mdi_wid=_MDICurrent();
         if (!cur_mdi_wid) {
            wid=_find_formobj(REFS_FORM_NAME_STRING,'N');
         } else {
            wid=_MDIFindFormObject(cur_mdi_wid,REFS_FORM_NAME_STRING,'N');
            if (!wid) {
               wid=_find_formobj(REFS_FORM_NAME_STRING,'N');
            }
         }
      }
   }
   // check if the tagwin is the active tab
   if( wid && only_when_active ) {
      if( !tw_is_current(wid) || !wid.p_enabled ) {
         return 0;
      }                  
   }
   return wid;
}

/**
 * Get the window ID of the editor control in the Preview tool window.
 */
int _GetReferencesEditorWID(bool only_when_active=false)
{
   if (!_haveContextTagging()) return 0;
   _nocheck _control ctlrefedit;
   wid := _GetReferencesWID(only_when_active);
   return (wid > 0)? wid.ctlrefedit.p_window_id : 0;
}

/** 
 * @return 
 * Return the current symbol name in references tool window. 
 *  
 * @categories Tagging_Functions 
 */ 
_str _GetReferencesSymbolName()
{
   window_id := _GetReferencesWID();
   if (window_id) {
      control_id := window_id._find_control("ctlrefname");
      if (control_id) {
         if ((control_id.p_object == OI_COMBO_BOX) || (control_id.p_object == OI_TEXT_BOX)) {
            return control_id.p_text;
         }
      }
   }
   return "";
}

/**
 * Get the search scope options for the references tool window. 
 *  
 * @return Returns on of the following constants: 
 *         <ul> 
 *         <li>VS_TAG_FIND_TYPE_EVERYWHERE
 *         <li>VS_TAG_FIND_TYPE_BUFFER_ONLY
 *         <li>VS_TAG_FIND_TYPE_PROJECT_ONLY
 *         <li>VS_TAG_FIND_TYPE_WORKSPACE_ONLY
 *         </ul>
 *  
 * @categories Tagging_Functions 
 */
_str _GetReferencesLookinOption()
{
   window_id := _GetReferencesWID();
   if (window_id) {
      control_id := window_id._find_control("ctllookin");
      if (control_id) {
         if ((control_id.p_object == OI_COMBO_BOX) || (control_id.p_object == OI_TEXT_BOX)) {
            return control_id.p_text;
         }
      }
   }
   return "";
}

static int RefsEditWindowBufferID(...) {
   if (arg()) ctlrefedit.p_user=arg(1);
   return ctlrefedit.p_user;
}
static int RefsTagNameLocation(...) {
   if (arg()) ctlrefname.p_user=arg(1);
   return ctlrefname.p_user;
}
static int RefsEditWindowPicType(...) {
   if (arg()) ctllookin.p_user=arg(1);
   if (ctllookin.p_user == null) return 0;
   return ctllookin.p_user;
}
static SETagFilterFlags RefsEditWindowTagTypeFilters(...) {
   if (arg()) ctlshowall.p_user=arg(1);
   if (ctlshowall.p_user == null || !isinteger(ctlshowall.p_user)) return def_references_flags;
   return ctlshowall.p_user;
}
static VS_TAG_BROWSE_INFO RefsTreeTagBrowseInfo(...) {
   if (arg()) {
      VS_TAG_BROWSE_INFO cm = arg(1);
      ctlreferences.p_user = cm;
      if ( cm != null && cm.language != null ) {
         get_index := _FindLanguageCallbackIndex("vs%s_get_expression_info",cm.language);
         enable_for_symbol := tag_tree_type_is_data(cm.type_name) != 0;
         if (cm.type_name == "control") enable_for_symbol = true;
         ctlassigned.p_enabled = ( get_index != 0 && enable_for_symbol );
         if ( !ctlassigned.p_enabled ) {
            ctlassigned.p_value = REF_ASSIGNMENT_FILTER_NONE;
         }
      }
   }
   if (ctlreferences.p_user != null && ctlreferences.p_user instanceof VS_TAG_BROWSE_INFO) {
      return ctlreferences.p_user;
   }
   return null;
}

/**
 * Set focus on the editor.  This command can be useful when
 * you are trying to control an instance of SlickEdit from
 * another application or using {@link dde} and you need to
 * transfer focus to the editor to complete an operation.
 *
 * @param mdi_wid MDI window to accept focus. Set to 0 for 
 *                current MDI window.
 * 
 * @categories Miscellaneous_Functions
 */
_command void mdisetfocus(int mdi_wid=0) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI)
{
   if (mdi_wid == 0) mdi_wid = _MDICurrent();
   child := _MDICurrentChild(mdi_wid);
   if ( child > 0 ) {
      child._set_focus();
   } else {
      mdi_wid._set_focus();
   }
}

static void tag_refs_maybe_mdisetfocus(int formwid=0)
{
   if ( formwid == 0 ) {
      // Post it
      _post_call(tag_refs_maybe_mdisetfocus, p_window_id);
   } else {
      // Called by _post_call()
      if ( _iswindow_valid(formwid) && formwid.p_isToolWindow ) {
         // Only set focus away from tool-window if it is docked with an mdiarea.
         // Otherwise you can end up with the tool-window falling behind another window.
         mdi_wid := _MDIFromChild(formwid);
         if ( mdi_wid == _mdi || _MDIWindowHasMDIArea(mdi_wid) ) {
            mdisetfocus(mdi_wid);
         }
      }
   }
}

void _tbtagrefs_form.on_destroy()
{
   // kill all the reference form timers
   refs_kill_all_timers();
   //tag_refs_clear_pics();

   // save the position of the sizing bar
   _moncfg_append_retrieve(0,ctldivider.p_user,"_tbtagrefs_form.ctldivider.p_x");
   _moncfg_append_retrieve(0,ctlvdivider.p_user,"_tbtagrefs_form.ctlvdivider.p_y");

   // save whether or not the preview pane is hidden
   _moncfg_append_retrieve(0,ctlexpandbtn.p_value,"_tbtagrefs_form.ctlexpandbtn.p_value");
   _moncfg_append_retrieve(0,ctlvexpandbtn.p_value,"_tbtagrefs_form.ctlvexpandbtn.p_value");

   // determine if we should save font size for preview window
   fontsize := ctlrefedit.p_font_size;
   ctlrefedit.wfont_unzoom();
   if (fontsize != ctlrefedit.p_font_size) {
      _append_retrieve(0,fontsize,"_tbtagrefs_form.ctlrefedit.p_font_size");
   }

   // clear out the references window by restoring the original empty refs
   // edit window buffer id
   if ( RefsEditWindowBufferID() != ctlrefedit.p_buf_id ) {
      if (ctlrefedit.p_buf_flags & VSBUFFLAG_HIDDEN) {
         if (_SafeToDeleteBuffer(ctlrefedit.p_buf_id, ctlrefedit.p_window_id, ctlrefedit.p_buf_flags)) {
            ctlrefedit.quit_file();
         }
      }
      ctlrefedit.load_files("+q +m +bi "RefsEditWindowBufferID());
   }

   RefsTagNameLocation("");
   ctlrefname._lbtop();
   while (ctlrefname.p_line < 50) {
      ctlrefname._append_retrieve(_control ctlrefname,ctlrefname._lbget_text());
      if (ctlrefname._lbdown()) {
         break;
      }
   }
   ctllookin._append_retrieve(_control ctllookin, ctllookin.p_text);
   ctlassigned._append_retrieve(_control ctlassigned,ctlassigned.p_value);
   ctlnonconst._append_retrieve(_control ctlnonconst,ctlnonconst.p_value);
   ctlconst._append_retrieve(_control ctlconst,ctlconst.p_value);
   gFindReferencesExpression="";

   call_event(p_window_id,ON_DESTROY,'2');
}

// Return a caption of the following form:
//
//    [ <item_no> / <item_count> in <file_no> / <file_count> files ]
//
// The current object must be the references tree control
//
// This function could become a performance bottleneck because it
// counts every node in the references tree every time it is invoked.
// However, in most cases when it is invoked, it is done on a timer,
// so the costs are minimized.
//
static _str RefCountInfoCaption()
{
   // item and file counts
   itemNumber := 0;
   itemCount := 0;
   fileCount := 0;
   fileNumber := 0;

   // get the current tree index and line number
   index := _TreeCurIndex();
   int parentIndex = index;
   if (_TreeGetDepth(index) == 2) {
      parentIndex = _TreeGetParentIndex(index);
   }
   typeless ds,dn,dc,df;
   _TreeGetInfo(index,ds,dn,dc,df,itemNumber,0);
   itemNumber = (itemNumber < 0)? 0:itemNumber;

   // if expanding incrementally, are there still unexpanded nodes?
   unExpandedNodes := false;

   // for each file in the list
   i := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (i > 0) {
      // get the number of references under this file
      childCount := _TreeGetNumChildren(i);
      itemCount+=childCount;
      // if zero, check if this node is unexpanded
      if (!childCount) {
         show_children := 0;
         _TreeGetInfo(i,show_children);
         if (!show_children) {
            unExpandedNodes=true;
         }
      }
      // if we found the parent node, adjust the file/item counts
      if (i == parentIndex) {
         itemNumber -= fileCount;
         fileNumber = fileCount+1;
      }
      fileCount++;

      // next please
      i = _TreeGetNextSiblingIndex(i);
   }

   // create the file caption, special case one file
   _str fileCaption;
   if (fileCount==1) {
      fileCaption=nls("in 1 file");
   } else {
      fileCaption=nls("in %s/%s files",fileNumber,fileCount);
   }

   // display '+' on item count if they have incremental references turned on
   incremental := (unExpandedNodes && (def_references_options & VSREF_FIND_INCREMENTAL))? "+":"";

   // that's all folks, format the string and return
   return "["itemNumber"/"itemCount:+incremental" "fileCaption"]";
}

// Set the filename and line number caption for the symbol window.
// The the current object must be the references window.
static void SetRefInfoCaption(struct VS_TAG_BROWSE_INFO cm)
{
   caption := ctlreferences.RefCountInfoCaption();
   caption = caption :+ " " :+ 
             ctlreflabel._ShrinkFilename(cm.file_name,
                                         p_active_form.p_width-ctlreflabel.p_x-ctlcollapsebtn.p_width-
                                         ctlreflabel._text_width(caption) -
                                         ctlreflabel._text_width(" : "cm.line_no)) :+
             ": " :+ cm.line_no;
   if (caption!=ctlreflabel.p_caption) {
      ctlreflabel.p_caption=caption;
   }
   //ctlreflabel.p_width=ctlreflabel._text_width(ctlreflabel.p_caption);
}

void _tbtagrefs_form.on_resize()
{
   CTL_IMAGE btn = 0;
   old_wid := p_window_id;
   avail_x := avail_y := 0;
   // RGH - 4/26/2006
   // For the plugin, first resize the SWT container then do the normal resize
   if (isEclipsePlugin()) {
      referencesOutputContainer := _GetReferencesWID();
      if(!referencesOutputContainer) return;
      // RGH - 4/26/2006
      // Set p_window_id here so we can find the right controls
      p_window_id = referencesOutputContainer;
      eclipse_resizeContainer(referencesOutputContainer);
      avail_x  = referencesOutputContainer.p_parent.p_width;
      avail_y  = referencesOutputContainer.p_parent.p_height;
      // When the references pane is minimized in Eclipse, the resize causes 
      // weirdness...so don't do it
      if (avail_x == 0 && avail_y == 0) {
         return;
      }
   } else {
      // how much space do we have to work with?
      avail_x  = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
      avail_y  = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   }

   // what are our margins?
   margin_x := ctlreferences.p_x;
   margin_y := ctlrefname.p_y;

   // adjust the size of the expand and collapse buttons if necessary
   //max_button_height := (margin_y + ctlrefname.p_height + margin_y + ctllookin.p_height + margin_y) intdiv 2;
   buttons := references_stack_buttons(visibleOnly:false);
   max_button_height := ctllookin.p_height + ctllookin.p_height intdiv 2;
   if (avail_y < max_button_height * (5+REFS_MAX_PIC_TYPES)) {
      max_button_height = ctllookin.p_height;
   }
   ctlcollapsebtn.resizeToolButton(max_button_height);
   ctlexpandbtn.resizeToolButton(max_button_height);
   ctlvexpandbtn.resizeToolButton(max_button_height);
   ctlstackpopbtn.resizeToolButton(max_button_height);
   ctlstackpushbtn.resizeToolButton(max_button_height);

   // save the contents of all the visible buttons
   REFERENCES_WINDOW_STATE buttonStates[];
   int buttonBorderStyles[];
   bool buttonsEnabled[];
   _str buttonMessages[];
   num_stack_items := num_references_stack_items(buttons);
   for (i:=0; i<num_stack_items; i++) {
      btn = buttons[i];
      if ( !btn.p_enabled ) break;
      if ( !btn.p_visible ) break;
      buttonStates[i] = btn.p_user;
      buttonBorderStyles[i] = btn.p_border_style;
      buttonsEnabled[i] = btn.p_enabled;
      buttonMessages[i] = btn.p_message;
   }

   // align the toolbar buttons first before layint out the stack buttons
   alignControlsVertical(avail_x - max(ctlexpandbtn.p_width,ctlvexpandbtn.p_width,ctlcollapsebtn.p_width) - margin_x - 45, 
                         0, _dy2ly(SM_TWIP,1),
                         ctlcollapsebtn.p_window_id,
                         ctlexpandbtn.p_window_id,
                         ctlvexpandbtn.p_window_id,
                         ctlstackpopbtn.p_window_id,
                         ctlstackpushbtn.p_window_id,
                         ctlstack.p_window_id);

   // resize the stack buttons, use smaller buttons if size is limited
   if ( ctlstackpushbtn.p_y_extent + (ctlstackpushbtn.p_height + _dy2ly(SM_TWIP,1))*REFS_MAX_PIC_TYPES > avail_y ) {
      max_button_height = max_button_height intdiv 2;
   }
   ctlstack0btn.p_width  = ctlstackpushbtn.p_width;
   ctlstack0btn.p_height = ctlstackpushbtn.p_height;
   ctlstack0btn.resizeToolButton(max_button_height, allowTinySizes:true);
   foreach ( i => btn in buttons ) {
      btn.p_visible = true;
      btn.p_width=ctlstackpushbtn.p_width;
      btn.p_height=ctlstackpushbtn.p_height;
      btn.resizeToolButton(max_button_height, allowTinySizes:true);
      btn.p_forecolor = 0x00C0C000;
   }

   // align all the stack buttons
   ctlstack.p_x      = ctlstackpushbtn.p_x - _dx2lx(SM_TWIP,1);
   ctlstack.p_width  = ctlstack0btn.p_width + _dx2lx(SM_TWIP,2);
   ctlstack.p_height = ctlstack0btn.p_y_extent + _dy2ly(SM_TWIP,2);
   alignControlsVertical(_dx2lx(SM_TWIP,1), 0, 0,
                         ctlstack7btn.p_window_id,
                         ctlstack6btn.p_window_id,
                         ctlstack5btn.p_window_id,
                         ctlstack4btn.p_window_id,
                         ctlstack3btn.p_window_id,
                         ctlstack2btn.p_window_id,
                         ctlstack1btn.p_window_id,
                         ctlstack0btn.p_window_id);
   ctlstack.p_y += margin_y;
   ctlstack.p_height = ctlstack0btn.p_y_extent + _dy2ly(SM_TWIP,2);
   if ( ctlstack0btn.p_width+_dx2lx(SM_TWIP,2) < ctlstackpopbtn.p_width  ) {
      ctlstack.p_x += (ctlstackpopbtn.p_width - ctlstack0btn.p_width) intdiv 2;
   }
   ctlcollapsebtn.p_border_style = ctlcollapsebtn.p_value? BDS_FIXED_SINGLE : BDS_NONE;
   ctlexpandbtn.p_border_style   = ctlexpandbtn.p_value?   BDS_FIXED_SINGLE : BDS_NONE;
   ctlvexpandbtn.p_border_style  = ctlvexpandbtn.p_value?  BDS_FIXED_SINGLE : BDS_NONE;

   // Search options frame
   ctl_options_frame.p_y = ctlrefname.p_y_extent + margin_y;
   ctl_options_frame.p_x = ctlreferences.p_x;
   ctl_options_frame.p_width = ctlexpandbtn.p_x - ctldivider.p_width;
   ctl_options_button.p_x = _dx2lx(SM_TWIP,4);
   ctl_options_button.resizeToolButton(ctllookinlabel.p_height);
   ctl_options_button.p_y = margin_y;
   ctllookinlabel.p_y = 0;//margin_y;
   ctllookinlabel.p_x = ctl_options_button.p_x_extent + _dx2lx(SM_TWIP,5);
   ctlrefname.p_x = ctlsymlabel.p_x_extent + 360;
   ctllookin.p_x  = ctlrefname.p_x;

   if (ctl_options_button.p_value) {
      // plus (collapsed)
      ctllookin.p_enabled = true;
      ctllookin.p_visible = true;
      ctlassigned.p_enabled = true;
      ctlassigned.p_visible = true;
      ctlconst.p_enabled = true;
      ctlconst.p_visible = true;
      ctlnonconst.p_enabled = true;
      ctlnonconst.p_visible = true;
      ctlshowall.p_enabled = true;
      ctlshowall.p_visible = true;
      ctl_filter_button.p_enabled = true;
      ctl_filter_button.p_visible = true;
      ctl_filter_label.p_enabled = true;
      ctl_filter_label.p_visible = true;

      //ctllookin.p_x = ctllookinlabel.p_x_extent + 4*margin_x;
      ctllookinlabel.p_caption = "Loo&k in:";
      ctllookinlabel.p_y = 0;//margin_y intdiv 2;
      ctllookin.p_y = margin_y intdiv 2;

      // position the assignments check box to the left of Look In: combo
      tagFilterFlags := RefsEditWindowTagTypeFilters();
      ctl_filter_label.p_caption = getFilterOptionsString(tagFilterFlags);
      ctl_filter_label.p_auto_size = true;
      ctl_filter_button.resizeToolButton(ctl_filter_label.p_height);
      if (ctllookin.p_x + ctlassigned.p_width + ctlconst.p_width + ctlnonconst.p_width + ctlshowall.p_width + ctl_filter_button.p_width + ctl_filter_label.p_width + 300 > ctlexpandbtn.p_x) {
         ctlassigned.p_x = ctllookinlabel.p_x;
      } else {
         ctlassigned.p_x = ctllookin.p_x;
      }
      ctlconst.p_x    = ctlassigned.p_x_extent + 60;
      ctlnonconst.p_x = ctlconst.p_x_extent + 60;
      ctlshowall.p_x  = ctlnonconst.p_x_extent + 60;

      ctlassigned.p_y = ctllookin.p_y_extent + margin_y;
      ctlconst.p_y    = ctlassigned.p_y;
      ctlnonconst.p_y = ctlassigned.p_y;
      ctlshowall.p_y  = ctlassigned.p_y;

      // position filter button and label
      ctl_filter_button.p_x = ctlshowall.p_x_extent + 60;
      ctl_filter_button.p_y = ctlassigned.p_y;
      ctl_filter_label.p_auto_size = false;
      ctl_filter_label.p_y = ctlassigned.p_y;
      ctl_filter_label.p_x = ctl_filter_button.p_x_extent + 60;
      ctl_filter_label.p_x_extent = ctlexpandbtn.p_x - 60;

      // hide the filter label if we do not have room for it
      if ( ctl_filter_label.p_width < 900) {
         ctl_filter_label.p_visible = false;
         ctl_filter_label.p_enabled = false;
      } else if (!ctl_filter_label.p_visible) {
         ctl_filter_label.p_visible = true;
         ctl_filter_label.p_enabled = true;
      }

      ctl_options_frame.p_height = ctl_filter_button.p_y_extent + margin_y;

   } else {

      // minus (expanded)
      ctllookin.p_enabled = false;
      ctllookin.p_visible = false;
      ctlassigned.p_enabled = false;
      ctlassigned.p_visible = false;
      ctlconst.p_enabled = false;
      ctlconst.p_visible = false;
      ctlnonconst.p_enabled = false;
      ctlnonconst.p_visible = false;
      ctlshowall.p_enabled = false;
      ctlshowall.p_visible = false;
      ctl_filter_button.p_enabled = false;
      ctl_filter_button.p_visible = false;
      ctl_filter_label.p_enabled = false;
      ctl_filter_label.p_visible = false;

      lookinCaption := "Look in " :+ ctllookin.p_text;
      if (ctlshowall.p_value) {
         lookinCaption :+= ", " :+ ctlshowall.p_caption;
      } else {
         if (ctlassigned.p_value) lookinCaption :+= ", " :+ ctlassigned.p_caption;
         if (ctlconst.p_value) lookinCaption :+= ", " :+ ctlconst.p_caption;
         if (ctlnonconst.p_value) lookinCaption :+= ", " :+ ctlnonconst.p_caption;
      }
      tagFilterFlags := RefsEditWindowTagTypeFilters();
      lookinCaption :+= ", " :+ getFilterOptionsString(tagFilterFlags);

      ctllookinlabel.p_caption = lookinCaption;
      ctl_options_frame.p_height = max(ctl_options_button.p_height,ctllookinlabel.p_height) + 3*margin_y;
      ctllookinlabel.p_y = 0;//margin_y;

   }

   // Resize height:
   ctlreferences.p_y = ctl_options_frame.p_y_extent + margin_y;
   ctlrefedit.p_y = ctlreferences.p_y;
   ctlrefedit.p_y_extent = avail_y - margin_y - ctlreflabel.p_height - margin_y;
   ctldivider.p_y = ctlrefedit.p_y;
   ctldivider.p_height = ctlrefedit.p_height;
   ctlvdivider.p_x = ctlrefedit.p_x;
   ctlvdivider.p_width = ctlrefedit.p_width;

   // adjust the stack if some of them are hidden.
   while ( ctlstack.p_y_extent > avail_y && ctlstack1btn.p_visible && ctlstack0btn.p_visible ) {
      for ( i=0; i<buttons._length()-1; i++ ) {
         CTL_IMAGE curr_btn = buttons[i+0];
         CTL_IMAGE next_btn = buttons[i+1];
         curr_btn.p_y = next_btn.p_y;
         curr_btn.p_visible = next_btn.p_visible;
         if ( !next_btn.p_visible ) {
            next_btn.p_border_style = BDS_NONE;
         }
      }
      //ctlstack9btn.p_visible = false;
      //ctlstack.p_height -= ctlstack9btn.p_height;
      ctlstack7btn.p_visible = false;
      ctlstack.p_height -= ctlstack7btn.p_height;

      // If the bottom-most set of references has stream markes, clear it.
      if (buttons._length() > 0) {
         REFERENCES_WINDOW_STATE state = ctlstack0btn.p_user;
         if (state != null && state instanceof REFERENCES_WINDOW_STATE) {
            if (state.markerType != null && state.markerType >= 0) {
               //tag_refs_clear_pics(state.markerType);
            }
         }
      }
   }

   // restore the contents of all visible buttons (if we lost any)
   visibleButtons := references_stack_buttons(visibleOnly:true);
   if (buttonStates._length() > visibleButtons._length()) {
      numRemoved := buttonStates._length() - visibleButtons._length();
      foreach ( i => btn in visibleButtons ) {
         btn.p_user = buttonStates[i+numRemoved];
         btn.p_border_style = buttonBorderStyles[i+numRemoved];
         btn.p_enabled = buttonsEnabled[i+numRemoved];
         btn.p_message = buttonMessages[i+numRemoved];
      }
      for ( i=visibleButtons._length(); i < buttons._length(); i++) {
         buttons[i].p_enabled = false;
         buttons[i].p_border_style = BDS_NONE;
      }
      for ( i=0; i<numRemoved; i++ ) {
         REFERENCES_WINDOW_STATE state = buttonStates[i];
         if (state != null && state instanceof REFERENCES_WINDOW_STATE) {
            if (state.markerType != null && state.markerType >= 0) {
               tag_refs_clear_pics(state.markerType);
            }
         }
      }
   }

   // Resize drop-down box widths:
   ctlrefname.p_x_extent = ctlexpandbtn.p_x - margin_x;
   ctllookin.p_x_extent = ctlrefname.p_x_extent;

   // do not let the combo box push to close to the collapse button
   if (ctlrefname.p_x_extent + ctldivider.p_width > ctlcollapsebtn.p_x) {
      ctlrefname.p_x_extent = ctlcollapsebtn.p_x - ctldivider.p_width;
      ctllookin.p_width = ctlrefname.p_width;
   }
   // do not let the combo box push to close to the collapse button
   if (ctllookin.p_x_extent + ctldivider.p_width > ctlcollapsebtn.p_x) {
      ctllookin.p_x_extent = ctlcollapsebtn.p_x - ctldivider.p_width;
   }

   if (ctlexpandbtn.p_value) {

      // force the sizebar to stay with reasonable size and position
      if (ctldivider.p_x > ctlcollapsebtn.p_x) {
         ctldivider.p_x = ctlcollapsebtn.p_x;
      }
      if (ctldivider.p_x < ctlrefname.p_x*2) {
         ctldivider.p_x = ctlrefname.p_x*2;
      }

      // adjust the width of the preview pane
      ctlrefedit.p_x = ctldivider.p_x_extent;
      ctlrefedit.p_x_extent = ctlrefname.p_x_extent;
      ctlreferences.p_height = ctlrefedit.p_height;
      ctlreferences.p_x_extent = ctldivider.p_x;
      ctldivider.p_user = ctldivider.p_x;
      ctlvdivider.p_enabled = false;
      ctlvdivider.p_visible = false;

   } else if (ctlvexpandbtn.p_value) {

      // force the sizebar to stay with reasonable size and position
      if (ctlvdivider.p_y < ctlvexpandbtn.p_y_extent) {
         ctlvdivider.p_y = ctlvexpandbtn.p_y_extent;
      }
      if (ctlvdivider.p_y > avail_y - 2*ctlreflabel.p_height - 2*margin_y) {
         ctlvdivider.p_y = avail_y - 2*ctlreflabel.p_height - 2*margin_y;
      }

      // adjust the width of the preview pane
      ctlreferences.p_x_extent = ctlrefname.p_x_extent;
      ctlrefedit.p_x = ctlreferences.p_x;
      ctlrefedit.p_width = ctlreferences.p_width;
      ctlvdivider.p_x = ctlreferences.p_x;
      ctlvdivider.p_width = ctlreferences.p_width;
      ctlreferences.p_y_extent = ctlvdivider.p_y;
      ctlrefedit.p_y = ctlvdivider.p_y + ctlreflabel.p_height + margin_y;
      ctlrefedit.p_y_extent = avail_y;
      ctlvdivider.p_user = ctlvdivider.p_y;
      ctldivider.p_enabled = false;
      ctldivider.p_visible = false;

   } else {
      // set up the height of the references tree
      ctlreferences.p_y_extent = avail_y - margin_y - ctlreflabel.p_height - margin_y;
      ctlreferences.p_x_extent = ctlrefname.p_x_extent;

      // move sizebar all the way to left edge
      ctldivider.p_x = ctlrefname.p_x_extent;

      // hide the controls if collapsing
      ctlrefedit.p_visible = false;
      ctlrefedit.p_enabled = false;
      ctldivider.p_visible = false;
      ctldivider.p_enabled = false;
      ctlvdivider.p_visible = false;
      ctlvdivider.p_enabled = false;
   }

   // move label below the list of references
   ctlreflabel.p_auto_size = false;
   ctlreflabel.p_y = ctlreferences.p_y_extent + margin_y + (ctlvdivider.p_enabled? ctlvdivider.p_height : 0);
   ctlreflabel.p_x = ctlreferences.p_x;
   ctlreflabel.p_x_extent = (ctlreferences.p_y_extent > ctlstack.p_y_extent)? ctlstack.p_x_extent : ctlrefname.p_x_extent;

   // RGH - 4/26/2006
   // Switch p_window_id back
   if (isEclipsePlugin()) {
      p_window_id = old_wid;
   }
}

//void ctlstackupbtn.lbutton_up()
//{
//   if ( ctlstackgauge.p_value < ctlstackgauge.p_max ) {
//      ctlstackgauge.p_value++;
//   }
//}
//void ctlstackdownbtn.lbutton_up()
//{
//   if ( ctlstackgauge.p_value > 1 ) {
//      ctlstackgauge.p_value--;
//   }
//}

void ctlcollapsebtn.lbutton_up()
{
   // hide the controls if collapsing
   ctlrefedit.p_visible = false;
   ctlrefedit.p_enabled = false;
   ctldivider.p_visible = false;
   ctldivider.p_enabled = false;
   ctlvdivider.p_visible = false;
   ctlvdivider.p_enabled = false;

   // delegate repositioning to the on_resize() event
   ctlexpandbtn.p_value   = 0;
   ctlvexpandbtn.p_value  = 0;
   ctlcollapsebtn.p_value = 1;
   ctlcollapsebtn.p_enabled = false;
   ctlexpandbtn.p_enabled   = true;
   ctlvexpandbtn.p_enabled  = true;
   call_event(p_active_form,ON_RESIZE,'w');
}

void ctlexpandbtn.lbutton_up()
{
   // hide the controls if collapsing
   ctlrefedit.p_visible = true;
   ctlrefedit.p_enabled = true;
   ctldivider.p_visible = true;
   ctldivider.p_enabled = true;
   ctlvdivider.p_visible = false;
   ctlvdivider.p_enabled = false;

   // restore position for sizebar
   ctldivider.p_x = ctldivider.p_user;

   // delegate repositioning to the on_resize() event
   ctlexpandbtn.p_value   = 1;
   ctlvexpandbtn.p_value  = 0;
   ctlcollapsebtn.p_value = 0;
   ctlcollapsebtn.p_enabled = true;
   ctlexpandbtn.p_enabled   = false;
   ctlvexpandbtn.p_enabled  = true;
   call_event(p_active_form,ON_RESIZE,'w');
}

void ctlvexpandbtn.lbutton_up()
{
   // hide the controls if collapsing
   ctlrefedit.p_visible = true;
   ctlrefedit.p_enabled = true;
   ctldivider.p_visible = false;
   ctldivider.p_enabled = false;
   ctlvdivider.p_visible = true;
   ctlvdivider.p_enabled = true;

   // restore position for sizebar
   ctlvdivider.p_y = ctlvdivider.p_user;

   // delegate repositioning to the on_resize() event
   ctlexpandbtn.p_value   = 0;
   ctlvexpandbtn.p_value  = 1;
   ctlcollapsebtn.p_value = 0;
   ctlcollapsebtn.p_enabled = true;
   ctlexpandbtn.p_enabled   = true;
   ctlvexpandbtn.p_enabled  = false;
   call_event(p_active_form,ON_RESIZE,'w');
}

void ctlstackpopbtn."s-lbutton-down"()
{
   if ( !p_enabled ) return;
   buttons := references_stack_buttons(visibleOnly:false);
   num_stack_items := num_references_stack_items(buttons);
   if ( num_stack_items <= 0 ) {
      tag_refs_clear_refs_and_preview();
      tag_refs_clear_pics();
      _mfrefNoMore(1);
      return;
   }

   f := p_active_form;
   ok := IDYES;
   ok = _message_box("Clear entire references stack?", "SlickEdit", MB_YESNO);
   if (ok == IDYES) {
      f.clear_references_stack();
      f.pop_references_stack();
   }
}

void ctlstackpopbtn.lbutton_up()
{
   if ( !p_enabled ) return;
   pop_references_stack();
}

void ctlstack0btn.lbutton_up()
{
   if ( !p_enabled ) return;
   if ( p_border_style != BDS_NONE ) return;
   buttons := references_stack_buttons(visibleOnly:false);
   for ( i:=0; i<buttons._length(); i++ ) {
      CTL_IMAGE btn = buttons[i];
      // update the current item before switching
      if (btn.p_border_style != BDS_NONE) {
         REFERENCES_WINDOW_STATE state;
         tbtagrefs_form_save_current_state(state);
         btn.p_user = state;
         if (def_references_options & VSREF_NO_HIGHLIGHT_ALL) {
            if ( state.markerType != null && state.markerType >= 0 ) {
               _MarkerTypeSetFlags(state.markerType, 0);
            }
         }
      }
      if ( btn != p_window_id ) {
         btn.p_border_style = BDS_NONE;
      }
   }
   p_border_style = BDS_ROUNDED;
   REFERENCES_WINDOW_STATE state = p_user;
   if (state != null && state instanceof REFERENCES_WINDOW_STATE) {
      tbtagrefs_form_restore_current_state(state);
      if (def_references_options & VSREF_NO_HIGHLIGHT_ALL) {
         if ( state.markerType != null && state.markerType >= 0 ) {
            _MarkerTypeSetFlags(state.markerType, VSMARKERTYPEFLAG_USE_MARKER_TYPE_COLOR|VSMARKERTYPEFLAG_DRAW_SCROLL_BAR_MARKER);
         }
      }
   }
}

ctldivider.lbutton_down()
{
   border_width := ctlrefname.p_x;
   member_width := ctlrefedit.p_x_extent - ctlcollapsebtn.p_width - ctlexpandbtn.p_width;
   _ul2_image_sizebar_handler(border_width*2, member_width);
}

ctlvdivider.lbutton_down()
{
   border_height := ctlvexpandbtn.p_y_extent;
   member_height := ctlrefedit.p_y_extent - 2*ctlreflabel.p_height;
   _ul2_image_sizebar_handler(border_height, member_height);
}

void ctlassigned.lbutton_up()
{
   refs_kill_expanding_timer();
   refs_update_filter_options();
   refs_update_show_all_check_box();
}

/**
 * Toggle the search options as expanded or collapsed
 */
void ctl_options_button.lbutton_up()
{
   p_value = (p_value==0)? 1:0;
   if (p_user == p_value) {
      return;
   }
   p_user = p_value;
   call_event(p_active_form,ON_RESIZE,'w');
}


void ctlshowall.lbutton_up()
{
   refs_kill_expanding_timer();
   if (p_value == 1) {
      ctlassigned.p_value = 0;
      ctlconst.p_value    = 0;
      ctlnonconst.p_value = 0;
      RefsEditWindowTagTypeFilters(def_references_flags|SE_TAG_FILTER_ANYTHING);
      if ( (def_references_flags | SE_TAG_FILTER_ANYTHING) != def_references_flags ) {
         def_references_flags |= SE_TAG_FILTER_ANYTHING;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      refs_update_filter_options(true);
   } else {
      refs_update_show_all_check_box();
   }
}

/**
 * When the filter button is pressed, display the tag filter menu
 */
void ctl_filter_button.lbutton_up()
{
   // Get handle to menu:
   orig_wid := p_window_id;
   index := find_index("_tagbookmark_menu",oi2type(OI_MENU));
   menu_handle := p_active_form._menu_load(index,'P');

   // configure it for this dialog use
   flags := RefsEditWindowTagTypeFilters();
   pushTgConfigureMenu(menu_handle, flags);

   // Show menu:
   mou_get_xy(auto x, auto y);
   _KillToolButtonTimer();
   status := _menu_show(menu_handle,VPM_LEFTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
   p_window_id = orig_wid;
   p_value = 0;
}

/**
 * If the filter options change, refresh the tag list
 */
void ctl_filter_button.on_change()
{
   // set the filter caption, size the controls so they look nice
   refs_update_filter_options();
   refs_update_show_all_check_box();
}

void refs_update_filter_options(bool tag_filters_changed=false)
{
   static bool updating /*=false*/;
   if ( updating ) return;
   updating = true;

   // do we think the tag filters may have changed?
   if (tag_filters_changed) {
      RefsEditWindowTagTypeFilters(def_references_flags);
      ctl_filter_label.p_caption = getFilterOptionsString(def_references_flags);
   }

   // 'const' and 'non-const' are mutually exclusive
   if ( ctlconst.p_value && ctlnonconst.p_value ) {
      if ( p_window_id == ctlconst.p_window_id ) {
         ctlnonconst.p_value = 0;
      }
      if ( p_window_id == ctlnonconst.p_window_id ) {
         ctlconst.p_value = 0;
      }
   }

   // if the display is collapsed
   if (!ctl_options_button.p_value) {
      lookinCaption := "Look in " :+ ctllookin.p_text;
      if (ctlshowall.p_value) {
         lookinCaption :+= ", " :+ ctlshowall.p_caption;
      } else {
         if (ctlassigned.p_value) lookinCaption :+= ", " :+ ctlassigned.p_caption;
         if (ctlconst.p_value) lookinCaption :+= ", " :+ ctlconst.p_caption;
         if (ctlnonconst.p_value) lookinCaption :+= ", " :+ ctlnonconst.p_caption;
      }
      tagFilterFlags := RefsEditWindowTagTypeFilters();
      lookinCaption :+= ", " :+ ctl_filter_label.p_caption;
      ctllookinlabel.p_caption = lookinCaption;
   }

   refs_get_filter_options(auto assign_filter, auto const_filter);
   ctlreferences.refs_refilter_references(assign_filter, const_filter);
   updating = false;
}

static void refs_get_filter_options(TagAssignmentFilterFlags &assign_filter, TagConstFilterFlags &const_filter)
{
   assign_filter = REF_ASSIGNMENT_FILTER_NONE;
   if (ctlassigned.p_value) {
      assign_filter = REF_ASSIGNMENT_FILTER_WRITES;
   }

   const_filter = REF_CONST_FILTER_NONE;
   if (ctlconst.p_value) {
      const_filter = REF_CONST_FILTER_CONST;
   } else if (ctlnonconst.p_value) {
      const_filter = REF_CONST_FILTER_NON_CONST;
   }
}

static void refs_set_filter_options(TagAssignmentFilterFlags assign_filter, TagConstFilterFlags const_filter)
{
   switch (assign_filter) {
   case REF_ASSIGNMENT_FILTER_WRITES:
      ctlassigned.p_value = 1;
      break;
   case REF_ASSIGNMENT_FILTER_READS:
      // just a placeholder
      break;
   case REF_ASSIGNMENT_FILTER_NONE:
   default:
      ctlassigned.p_value = 0;
      break;
   }

   switch (const_filter) {
   case REF_CONST_FILTER_NON_CONST:
      ctlconst.p_value = 0;
      ctlnonconst.p_value = 1;
      break;
   case REF_CONST_FILTER_CONST:
      ctlconst.p_value = 1;
      ctlnonconst.p_value = 0;
      break;
   case REF_CONST_FILTER_NONE:
   default:
      ctlconst.p_value = 0;
      ctlnonconst.p_value = 0;
      break;
   }
}

void refs_update_show_all_check_box(bool from_ctlshowall=false)
{
   // show all tags?
   tagFilterFlags := RefsEditWindowTagTypeFilters();
   show_all_tags := ((tagFilterFlags & SE_TAG_FILTER_ANYTHING) == SE_TAG_FILTER_ANYTHING);
   if (show_all_tags && ctlassigned.p_value==0 && ctlconst.p_value==0 && ctlnonconst.p_value==0) {
      if (ctlshowall.p_value == 0) {
         ctlshowall.p_value = 1;
         ctl_filter_label.p_caption = getFilterOptionsString(tagFilterFlags);
      }
   } else {
      ctl_filter_label.p_caption = getFilterOptionsString(tagFilterFlags);
      ctlshowall.p_value = 0;
   }
}

/**
 * Filter through symbols in the References list and hide symbols 
 * depending on rules for filtering assignment statements. 
 * 
 * @param filter           filter writes (assign), reads (not assign), none?
 * @param for_file_index   just filter symbols under this tree node
 */
static void refs_refilter_references(TagAssignmentFilterFlags assign_filter, TagConstFilterFlags const_filter, int for_file_index=0)
{
   // just do one file or all the files?
   tagFilterFlags := RefsEditWindowTagTypeFilters();
   file_index := for_file_index;
   if ( file_index <= 0 ) {
      file_index = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   }

   int bitmaps[];
   while ( file_index > 0 ) {
      ref_index := _TreeGetFirstChildIndex(file_index);
      while ( ref_index > 0 ) {

         // go through the overlays to determine if this is an assignment
         have_assignment := false;
         have_const      := false;
         have_nonconst   := false;
         have_unknown    := false;
         bitmaps._makeempty();
         _TreeGetOverlayBitmaps(ref_index, bitmaps);
         foreach ( auto bm_index in bitmaps ) {
            if (bm_index == _pic_symbol_assign) {
               have_assignment = true;
            } else if (bm_index == _pic_symbol_const) {
               have_const = true;
            } else if (bm_index == _pic_symbol_nonconst) {
               have_nonconst = true;
            } else if (bm_index == _pic_symbol_unknown) {
               have_unknown = true;
            }
         }

         // determine if this reference should be hidden
         hide_assign_ref := false;
         if (assign_filter == REF_ASSIGNMENT_FILTER_WRITES) {
            hide_assign_ref = !have_assignment;
         } else if ( assign_filter == REF_ASSIGNMENT_FILTER_READS ) {
            hide_assign_ref = have_assignment;
         }
         hide_nonconst_ref := false;
         if (const_filter == REF_CONST_FILTER_NON_CONST) {
            hide_nonconst_ref = have_const;
         } else if ( const_filter == REF_CONST_FILTER_CONST ) {
            hide_nonconst_ref = !have_const;
         }

         // get the file name and line number, tag database, and instance ID
         filter_symbol_type := false;
         ucm := _TreeGetUserInfo(ref_index);
         ref_parse_reference_info(ucm, auto cm_line_no, auto inst_id, auto cm_seekpos, auto cm_column_no, auto cm_tag_database, auto streamMarkerId, auto tag_type, auto tag_flags);
         if (!tag_filter_type(SE_TAG_TYPE_NULL, tagFilterFlags, tag_type, (int)tag_flags)) {
            filter_symbol_type = true;
         } else if ( have_unknown && !(tagFilterFlags & SE_TAG_FILTER_UNKNOWN) ) {
            filter_symbol_type = true;
         }

         // update the tree node flags the hidden state changed
         _TreeGetInfo(ref_index,auto state, auto bm1, auto bm2, auto nodeFlags);
         if ( hide_assign_ref || hide_nonconst_ref || filter_symbol_type ) {
            _TreeSetInfo(ref_index, state, bm1, bm2, nodeFlags | TREENODE_HIDDEN);
         } else {
            _TreeSetInfo(ref_index, state, bm1, bm2, nodeFlags & ~TREENODE_HIDDEN);
         }

         // next reference within file
         ref_index = _TreeGetNextSiblingIndex(ref_index);
      }

      // next file please
      if ( for_file_index > 0 ) break;
      file_index = _TreeGetNextSiblingIndex(file_index);
   }
}

static void updateLookinOptions()
{
   // put in the standard, top four search types
   origText := p_text;
   _lbclear();
   _lbadd_item(VS_TAG_FIND_TYPE_EVERYWHERE);
   _lbadd_item(VS_TAG_FIND_TYPE_BUFFER_ONLY);
   _lbadd_item(VS_TAG_FIND_TYPE_ALL_BUFFERS);
   _lbadd_item(VS_TAG_FIND_TYPE_PROJECT_ONLY);
   _lbadd_item(VS_TAG_FIND_TYPE_SAME_PROJECTS);
   _lbadd_item(VS_TAG_FIND_TYPE_WORKSPACE_ONLY);
   if (origText != "") {
      _cbset_text(origText);
   } else {
      _cbset_text(VS_TAG_FIND_TYPE_EVERYWHERE);
   }
}

static INTARRAY references_stack_buttons(bool visibleOnly=true)
{
   int buttons[];
   if (!visibleOnly || ctlstack0btn.p_visible) buttons :+= ctlstack0btn.p_window_id;
   if (!visibleOnly || ctlstack1btn.p_visible) buttons :+= ctlstack1btn.p_window_id;
   if (!visibleOnly || ctlstack2btn.p_visible) buttons :+= ctlstack2btn.p_window_id;
   if (!visibleOnly || ctlstack3btn.p_visible) buttons :+= ctlstack3btn.p_window_id;
   if (!visibleOnly || ctlstack4btn.p_visible) buttons :+= ctlstack4btn.p_window_id;
   if (!visibleOnly || ctlstack5btn.p_visible) buttons :+= ctlstack5btn.p_window_id;
   if (!visibleOnly || ctlstack6btn.p_visible) buttons :+= ctlstack6btn.p_window_id;
   if (!visibleOnly || ctlstack7btn.p_visible) buttons :+= ctlstack7btn.p_window_id;
   return buttons;
}

static void enable_disable_stack_buttons(int num_stack_items, int cur_stack_item, INTARRAY buttons=null)
{
   if ( buttons == null ) {
      buttons = references_stack_buttons();
   }
   for ( i:=0; i<buttons._length(); i++ ) {
      CTL_IMAGE btn = buttons[i];
      btn.p_enabled      = (num_stack_items > i);
      btn.p_border_style = (cur_stack_item == i && btn.p_enabled)? BDS_ROUNDED : BDS_NONE;
   }

   // if the user turns off auto-push, then '+' is more like a 'refresh'
   needsResize := false;
   if ((def_references_options & VSREF_NO_AUTO_PUSH) || num_stack_items <= 0) {
      pic_add_btn := _find_or_add_picture("bbadd.svg");
      if (ctlstackpushbtn.p_picture != pic_add_btn) {
         ctlstackpushbtn.p_picture = pic_add_btn;
         needsResize = true;
      }
   } else {
      pic_refresh_btn := _find_or_add_picture("bbrefresh.svg");
      if (ctlstackpushbtn.p_picture != pic_refresh_btn) {
         ctlstackpushbtn.p_picture = pic_refresh_btn;
         needsResize = true;
      }
   }
   if (needsResize) {
      ctlstackpushbtn.p_stretch = false;
      ctlstackpushbtn.resizeToolButton(ctlstackpopbtn.p_height);
      ctlstackpushbtn.p_stretch = true;
      ctlstackpushbtn.p_width = ctlstackpopbtn.p_width;
      ctlstackpushbtn.p_height = ctlstackpopbtn.p_height;
   }
}

static int num_references_stack_items(INTARRAY buttons=null)
{
   if ( buttons == null ) {
      buttons = references_stack_buttons();
   }
   for ( i:=0; i<buttons._length(); i++ ) {
      CTL_IMAGE btn = buttons[i];
      if (!btn.p_enabled) return i;
   }
   return min(buttons._length(), REFS_MAX_PIC_TYPES);
}

static int current_references_stack_item(INTARRAY buttons=null)
{
   if ( buttons == null ) {
      buttons = references_stack_buttons();
   }
   for ( i:=0; i<buttons._length(); i++ ) {
      CTL_IMAGE btn = buttons[i];
      if (btn.p_enabled && btn.p_border_style != BDS_NONE) return i;
   }
   return 0;
}

static void shift_references_stack(INTARRAY buttons=null)
{
   if ( buttons == null ) {
      buttons = references_stack_buttons();
   }
   // If the bottom-most set of references has stream markes, clear them
   if (buttons._length() > 0) {
      CTL_IMAGE last_btn = buttons[0];
      REFERENCES_WINDOW_STATE state = last_btn.p_user;
      if (state != null && state instanceof REFERENCES_WINDOW_STATE) {
         if (state.markerType != null && state.markerType >= 0) {
            tag_refs_clear_pics(state.markerType);
         }
      }
   }
   for ( i:=0; i<buttons._length()-1; i++ ) {
      CTL_IMAGE curr_btn = buttons[i+0];
      CTL_IMAGE next_btn = buttons[i+1];
      curr_btn.p_enabled      = next_btn.p_enabled;
      curr_btn.p_border_style = next_btn.p_border_style;
      curr_btn.p_user         = next_btn.p_user;
      curr_btn.p_message      = next_btn.p_message;
   }
}

int _OnUpdate_clear_references_stack(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveContextTagging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   f := _GetReferencesWID();
   if (!f) return MF_GRAYED;
   return MF_ENABLED;
}
_command void clear_references_stack() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   f := _GetReferencesWID();
   if (!f) return;
   if (_chdebug) {
      say("clear_references_stack");
   }

   buttons := f.references_stack_buttons(visibleOnly:false);
   for ( i:=0; i<buttons._length(); i++ ) {
      CTL_IMAGE btn = buttons[i];
      btn.p_enabled = false;
      btn.p_user = null;
      btn.p_message = "Go to stack position.";
      btn.p_border_style = BDS_NONE;
   }
   f.enable_disable_stack_buttons(0,0,buttons);
   tag_refs_clear_pics();
   _mfrefNoMore(1);
}

static int next_references_marker_type()
{
   // set the stream marker type for this references set to the next one in the queue.
   pic_type := RefsEditWindowPicType();
   if (pic_type <= 0) {
      if (gref_pic_types._length() < REFS_MAX_PIC_TYPES+1) {
         pic_type = _MarkerTypeAlloc();
         gref_pic_types :+= pic_type;
      } else {
         pic_type = gref_pic_types[0];
      }
      RefsEditWindowPicType(pic_type);
      return pic_type;
   }
   if (pic_type >= 0) {
      for (i:=0; i<gref_pic_types._length(); i++) {
         if (gref_pic_types[i] == pic_type) {
            if (i+1 < gref_pic_types._length()) {
               return gref_pic_types[i+1];
            } else if (gref_pic_types._length() >= REFS_MAX_PIC_TYPES+1) {
               return gref_pic_types[0];
            }
            break;
         }
      }
   }
   return -1;
}

static CFGColorConstants reference_marker_type_color(int markerType)
{
   if (def_references_options & VSREF_NO_HIGHLIGHT_ALL) {
      return CFG_REF_HIGHLIGHT_0;
   }
   int marker_color = CFG_REF_HIGHLIGHT_0;
   for (i:=0; i<gref_pic_types._length(); i++) {
      if (gref_pic_types[i] == markerType) {
         marker_color = CFG_REF_HIGHLIGHT_0 + i;
         if (marker_color > CFG_REF_HIGHLIGHT_7) marker_color -= 8;
         break;
      }
   }
   return (CFGColorConstants)marker_color;
}

int _OnUpdate_push_references_stack(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveContextTagging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   f := _GetReferencesWID();
   if (!f) return MF_GRAYED;
   index := f.ctlreferences._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if ( index <= 0 ) {
      editorctl_wid := _MDIGetActiveMDIChild();
      if (editorctl_wid && editorctl_wid._isEditorCtl(false)) {
         return _OnUpdate_push_ref(cmdui, editorctl_wid, "push_ref");
      }
      return MF_GRAYED;
   }
   return MF_ENABLED;
}
_command void push_references_stack(_str is_auto_push=0, _str caption="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      return;
   }

   f := _GetReferencesWID();
   if (!f) return;
   if (_chdebug) {
      say("push_references_stack");
   }

   buttons := f.references_stack_buttons(visibleOnly:false);
   num_stack_items := f.num_references_stack_items(buttons);
   cur_stack_item  := f.current_references_stack_item(buttons);

   static bool already_pushing_refs;
   if (num_stack_items == 0 && !already_pushing_refs && is_auto_push==0) {
      editorctl_wid := _MDIGetActiveMDIChild();
      if (editorctl_wid && editorctl_wid._isEditorCtl(false)) {
         already_pushing_refs = true;
         editorctl_wid.push_ref();
         already_pushing_refs = false;
         return;
      }
   }

   if ( cur_stack_item < num_stack_items ) {
      REFERENCES_WINDOW_STATE state = buttons[cur_stack_item].p_user;
      if (state != null && state instanceof REFERENCES_WINDOW_STATE) {
         if ( state.symbolName == f.ctlrefname.p_text && state.lookinOption == f.ctllookin.p_text ) {
            f.tbtagrefs_form_save_current_state(state);
            buttons[cur_stack_item].p_user = state;
            message("Updating current references stack item");
            if ( !is_auto_push ) {
               f.ctlreferences.expandAllReferencesNow(f._GetReferencesSymbolName());
            }
            return;
         }
      }
      if (def_references_options & VSREF_NO_HIGHLIGHT_ALL) {
         if ( state.markerType != null && state.markerType >= 0 ) {
            _MarkerTypeSetFlags(state.markerType, 0);
         }
      }
   }
   if (num_stack_items > 0) {
      REFERENCES_WINDOW_STATE state = buttons[num_stack_items-1].p_user;
      if (state != null && state instanceof REFERENCES_WINDOW_STATE) {
         if ( state.symbolName == f.ctlrefname.p_text && state.lookinOption == f.ctllookin.p_text ) {
            f.tbtagrefs_form_save_current_state(state);
            buttons[num_stack_items-1].p_user = state;
            buttons[num_stack_items-1].p_message = state.symbolName :+ " in " :+ state.lookinOption;
            message("Updating current top of references stack item");
            if ( !is_auto_push ) {
               f.ctlreferences.expandAllReferencesNow(f._GetReferencesSymbolName());
            }
            return;
         }
      }
   }

   visibleButtons := f.references_stack_buttons(visibleOnly:true);
   if ( num_stack_items >= visibleButtons._length() ) {
      f.shift_references_stack(visibleButtons);
      num_stack_items--;
   }
   f.enable_disable_stack_buttons(num_stack_items+1,num_stack_items,buttons);

   REFERENCES_WINDOW_STATE state;
   f.tbtagrefs_form_save_current_state(state);
   buttons[num_stack_items].p_user = state;
   if (caption != "") {
      buttons[num_stack_items].p_message = caption;
   } else {
      buttons[num_stack_items].p_message = state.symbolName :+ " in " :+ state.lookinOption;
   }
}
void set_references_stack_top_bookmark(_str bookmarkId)
{
   f := _GetReferencesWID();
   if (!f) return;
   if (def_references_options & VSREF_NO_AUTO_PUSH) return;

   buttons := f.references_stack_buttons(visibleOnly:false);
   num_stack_items := f.num_references_stack_items(buttons);
   cur_stack_item  := f.current_references_stack_item(buttons);
   if (num_stack_items > 0 && cur_stack_item == num_stack_items-1) {
      REFERENCES_WINDOW_STATE state = buttons[cur_stack_item].p_user;
      if (state != null && state instanceof REFERENCES_WINDOW_STATE) {
         state.bookmarkId = bookmarkId;
         buttons[cur_stack_item].p_user = state;
      }
   }
}

int _OnUpdate_pop_references_stack(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveContextTagging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   f := _GetReferencesWID();
   if (!f) return MF_GRAYED;
   num_stack_items := f.num_references_stack_items();
   if (num_stack_items <= 0) {
      index := f.ctlreferences._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if ( index > 0 ) return MF_ENABLED;
      return MF_GRAYED;
   }
   return MF_ENABLED;
}
_command int pop_references_stack(_str bookmarkId=null, bool quiet=false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      if (!quiet) {
         popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      }
      return VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG;
   }

   f := _GetReferencesWID();
   if (!f) return 0;
   if (_chdebug) {
      say("pop_references_stack");
   }

   refs_kill_all_timers();
   buttons := f.references_stack_buttons(visibleOnly:false);
   num_stack_items := f.num_references_stack_items(buttons);
   if ( num_stack_items <= 0 ) {
      f.tag_refs_clear_refs_and_preview();
      f.tag_refs_clear_pics();
      _mfrefNoMore(1);
      return 0;
   }

   // If the bookmark we are popping does not match the bookmark for the
   // item on top of the stack, then do not pop.
   if (bookmarkId != null && bookmarkId != "") {
      REFERENCES_WINDOW_STATE state = buttons[num_stack_items-1].p_user;
      if (state.bookmarkId == null || state.bookmarkId != bookmarkId) {
         return 0;
      }
   }

   // pop the item off the stack, and adjust the current item if necessary
   --num_stack_items;
   cur_stack_item := f.current_references_stack_item(buttons);
   orig_stack_item := cur_stack_item;
   pic_type := f.RefsEditWindowPicType();
   tag_refs_clear_pics(pic_type);

   // adjust if deleting an item from the middle of the stack
   if (cur_stack_item < num_stack_items) {
      for (j:=cur_stack_item; j<num_stack_items; j++) {
         buttons[j].p_user    = buttons[j+1].p_user;
         buttons[j].p_message = buttons[j+1].p_message;
         buttons[j].p_enabled = buttons[j+1].p_enabled;
      }
   }

   // adjust current stack item if we took one off the top
   if ( cur_stack_item >= num_stack_items ) --cur_stack_item;

   buttons[num_stack_items].p_user = null;
   buttons[num_stack_items].p_message = "Go to stack position.";
   buttons[num_stack_items].p_enabled = false;
   f.enable_disable_stack_buttons(num_stack_items,cur_stack_item,buttons);

   if ( num_stack_items > 0 ) {
      REFERENCES_WINDOW_STATE state = buttons[cur_stack_item].p_user;
      if (state != null && state instanceof REFERENCES_WINDOW_STATE) {
         f.tbtagrefs_form_restore_current_state(state);
         if (def_references_options & VSREF_NO_HIGHLIGHT_ALL) {
            if ( state.markerType != null && state.markerType >= 0 ) {
               _MarkerTypeSetFlags(state.markerType, VSMARKERTYPEFLAG_USE_MARKER_TYPE_COLOR|VSMARKERTYPEFLAG_DRAW_SCROLL_BAR_MARKER);
            }
         }
      }
   } else {
      _mfrefNoMore(1);
   }

   // that's all folks
   return 1;
}

void ctlrefname.on_create()
{
   RefsTagNameLocation("");
   typeless xpos = _moncfg_retrieve_value("_tbtagrefs_form.ctldivider.p_x");
   if (isuinteger(xpos)) {
      ctldivider.p_x = xpos;
   }
   typeless ypos = _moncfg_retrieve_value("_tbtagrefs_form.ctlvdivider.p_y");
   if (isuinteger(ypos)) {
      ctlvdivider.p_y = ypos;
   }
   typeless fontsize = _retrieve_value("_tbtagrefs_form.ctlrefedit.p_font_size");
   if (isuinteger(fontsize) && fontsize > 0) {
      ctlrefedit.p_font_size = fontsize;
   }
   ctldivider.p_user = ctldivider.p_x;
   ctlvdivider.p_user = ctlvdivider.p_y;
   typeless expand = _moncfg_retrieve_value("_tbtagrefs_form.ctlexpandbtn.p_value");
   if (!isuinteger(expand)) expand = 1;
   typeless vexpand = _moncfg_retrieve_value("_tbtagrefs_form.ctlvexpandbtn.p_value");
   if (!isuinteger(vexpand)) vexpand = 0;
   ctlexpandbtn.p_value   = (expand!=0)? 1:0;
   ctlvexpandbtn.p_value  = (vexpand!=0 && expand==0)? 1:0;
   ctlcollapsebtn.p_value = (expand==0 && vexpand==0)? 1:0;
   ctlcollapsebtn.p_enabled = (expand!=0 || vexpand!=0);
   ctlexpandbtn.p_enabled   = (expand==0);
   ctlvexpandbtn.p_enabled  = (expand!=0 || vexpand==0);
   ctlcollapsebtn.p_border_style = ctlcollapsebtn.p_value? BDS_FIXED_SINGLE : BDS_NONE;
   ctlexpandbtn.p_border_style   = ctlexpandbtn.p_value?   BDS_FIXED_SINGLE : BDS_NONE;
   ctlvexpandbtn.p_border_style  = ctlvexpandbtn.p_value?  BDS_FIXED_SINGLE : BDS_NONE;
   //call_event(p_active_form,ON_RESIZE,'w');

   // initially, the stack is empty
   enable_disable_stack_buttons(0,0);

   // initialize the editor control
   ctlrefedit.p_window_flags|=(OVERRIDE_CURLINE_RECT_WFLAG|OVERRIDE_CURLINE_COLOR_WFLAG);
   ctlrefedit.p_window_flags&=~(CURLINE_COLOR_WFLAG|CURLINE_RECT_WFLAG);
   ctlrefedit.p_window_flags|=VSWFLAG_NOLCREADWRITE;

   // Want p_buf_name blank so that when _ul2_editwin.on_create2() calls 
   // _SetEditorLanguage(), no file I/O occurs.
   //ctlrefedit.p_buf_name=REFS_WINDOW_DOC_NAME;
   ctlrefedit.docname(REFS_WINDOW_DOC_NAME);
   ctlrefedit.p_MouseActivate=MA_NOACTIVATE;
   //If I set tabs during the on_create it seemed to get hosed...
   //p_tabs="1 7 15 52";
   ctlrefedit.p_tabs="1 9 41";
   RefsEditWindowBufferID(ctlrefedit.p_buf_id);
   //ctlrefname.p_cb_list_box.p_buf_name=REFS_NAME_BUFFER_LIST;
   ctlrefedit.p_line=1;
   ctlrefedit.line_to_top();
   ctlrefedit.p_scroll_left_edge=-1;

   // reduced level indent
   ctlreferences.p_LevelIndent=_dx2lx(SM_TWIP,8);

   // restore previous search scope and options
   ctl_options_button._retrieve_value();
   ctllookin.updateLookinOptions();
   ctllookin._retrieve_value();
   if (ctllookin.p_text=="") {
      ctllookin._cbset_text(VS_TAG_FIND_TYPE_EVERYWHERE);
   }
   ctlassigned._retrieve_value();
   ctlnonconst._retrieve_value();
   ctlconst._retrieve_value();

   // make sure "Show all" is initialized to 1 if all filters are turned off
   show_all_tags := ((def_references_flags & SE_TAG_FILTER_ANYTHING) == SE_TAG_FILTER_ANYTHING);
   if (show_all_tags && ctlassigned.p_value==0 && ctlconst.p_value==0 && ctlnonconst.p_value==0) {
      ctlshowall.p_value=1;
   }

   // use expression passed in from current context
   if (gFindReferencesExpression != "") {
      ctlrefname._cbset_text(gFindReferencesExpression);
      gFindReferencesExpression = "";
   }

   // if we don't want to go to the first one, do not activate the editor window
   if (!(def_references_options & VSREF_DO_NOT_GO_TO_FIRST)) {
      //_post_call(mdisetfocus);
      p_active_form.tag_refs_maybe_mdisetfocus();
   }

   // copy event bindings from default keys
   copy_default_key_bindings("find-next");
   copy_default_key_bindings("find-prev");

   // copy key bindings for push-tag, find references to editor control
   copy_default_key_bindings("push_tag",    ctlrefedit.p_window_id);
   copy_default_key_bindings("push_alttag", ctlrefedit.p_window_id);
   copy_default_key_bindings("push_decl",   ctlrefedit.p_window_id);
   copy_default_key_bindings("push_def",    ctlrefedit.p_window_id);
   copy_default_key_bindings("find_tag",    ctlrefedit.p_window_id);
   copy_default_key_bindings("push_ref",    ctlrefedit.p_window_id);
   copy_default_key_bindings("find_refs",   ctlrefedit.p_window_id);
   copy_default_key_bindings("cb_find",     ctlrefedit.p_window_id);

   copy_default_key_bindings("wfont-zoom-in",  ctlrefedit.p_window_id);
   copy_default_key_bindings("wfont-zoom-out", ctlrefedit.p_window_id);
   copy_default_key_bindings("wfont-unzoom",   ctlrefedit.p_window_id);
}

void ctlrefname.on_destroy()
{
   RefsTagNameLocation("");
   _lbtop();
   while (p_line < 50) {
      _append_retrieve(_control ctlrefname,_lbget_text());
      if (_lbdown()) {
         break;
      }
   }
}

void ctllookin.on_destroy()
{
   ctl_options_button._append_retrieve(ctl_options_button, ctl_options_button.p_value);
   _append_retrieve(_control ctllookin,_lbget_text());
}

void ctlrefname.on_drop_down(int reason)
{
   loc := RefsTagNameLocation();
   if (loc == "") {
      _retrieve_list();
      RefsTagNameLocation("1"); // Indicate that retrieve list has been done
   }
   if (reason==DROP_UP_SELECTED) {
      goToTagInDropDown();
   }
}

/**
 * When the search field gets focus, update it's history information
 */
void ctlrefname.on_got_focus()
{
   if( ctlrefname._ComboBoxListVisible() ) {
      // Do not attempt to update the list (and as a result p_text) if
      // the user is in the middle of selecting from the drop-down list.
      return;
   }
   //ctlrefname._lbclear();
   //ctlrefname._retrieve_list();
   if (gFindReferencesExpression != "") {
      ctlrefname._cbset_text(gFindReferencesExpression);
      gFindReferencesExpression = "";
   }
   ctlrefname.p_sel_start  = 1;
   ctlrefname.p_sel_length = length(ctlrefname.p_text);
}

/**
 * Update the search results if look-in scope changes.
 */
void ctllookin.on_change(int reason)
{
   refs_kill_expanding_timer();
   switch (reason) {
   case CHANGE_SELECTED:
   case CHANGE_CLINE:
      cm := RefsTreeTagBrowseInfo();
      if (cm==null || !VF_IS_STRUCT(cm)) {
         goToTagInDropDown();
      } else {
         search_string := strip(ctlrefname.p_text);
         refresh_references_tab(cm, true, search_string);
      }
      break;
   }
}

//Just throwing in the keys that I really feel like I need
void ctlrefname.ESC,"C-A"()
{
   refs_kill_all_timers();
   if (last_event():==ESC) {
      ToolWindowInfo* twinfo = tw_find_info(p_active_form.p_name);
      if (twinfo && (twinfo->flags & TWF_DISMISS_LIKE_DIALOG) ) {
         tw_dismiss(p_active_form);
      } else {
         refswin_next_window();
      }
      return;
   }
   int child_wid=_MDICurrentChild(0);
   if (child_wid) {
      p_window_id=child_wid;
      child_wid._set_focus();
   }else{
      _cmdline._set_focus();
   }
}
void ctlrefname.ENTER()
{
   gFindReferencesExpression="";
   refs_kill_all_timers();
   // in drop down?
   if( ctlrefname._ComboBoxListVisible() ) {
      static bool in_enter_handler;
      if (in_enter_handler) return;
      in_enter_handler=true;
      ctlrefname.call_event(ctlrefname,last_event(),'2');
      in_enter_handler=false;
   }
   goToTagInDropDown();
}

static int findReferenceSymbolInContext(_str word, VS_TAG_BROWSE_INFO &cm)
{
   editorctl_wid := 0;
   if (_isEditorCtl()) {
      editorctl_wid = p_window_id;
   } else if (!_no_child_windows()) {
      editorctl_wid = _mdi.p_child;
   }

   // get the information about the current buffer
   lang := "";
   buffer_name := "";
   tag_init_tag_browse_info(cm);
   if (editorctl_wid) {
      lang = editorctl_wid.p_LangId;
      buffer_name = editorctl_wid.p_buf_name;
   }

   // extract information about the current expression
   orig_view_id := 0;
   temp_view_id := 0;
   orig_view_id = _create_temp_view(temp_view_id);
   p_LangId=lang;
   insert_line(word);
   _end_line();

   // maybe the symbol has arguments, either template or function
   left();
   for (i:=0; i<4; i++) {
      ch := get_text();
      if (ch==")" || ch==">" || ch=="]") {
         find_matching_paren(true);
         left();
      }
   }

   VS_TAG_IDEXP_INFO idexp_info;
   struct VS_TAG_RETURN_TYPE visited:[];
   status := _Embeddedget_expression_info(false, lang, idexp_info, visited);
   if (editorctl_wid) activate_window(editorctl_wid);
   if (status > 0) status = STRING_NOT_FOUND_RC;
   if (status < 0 && !editorctl_wid) {
      status = _do_default_get_expression_info(false, idexp_info, visited);
   }
   if (status < 0) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      return status;
   }

   // update the current context and locals
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContextAndTokens(true);
   _UpdateLocals(true,true);

   // call the extension-specific (possibly embedded)
   // find tags function
   _str errorArgs[];
   tag_push_matches();
   if (editorctl_wid) {
      status = _Embeddedfind_context_tags(errorArgs,
                                          idexp_info.prefixexp,
                                          idexp_info.lastid,
                                          (int)_QROffset(),
                                          idexp_info.info_flags,
                                          idexp_info.otherinfo,
                                          false,
                                          def_tag_max_find_context_tags,
                                          true, p_LangCaseSensitive,
                                          SE_TAG_FILTER_ANYTHING,
                                          (SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_ALLOW_PRIVATE|SE_TAG_CONTEXT_ALLOW_PROTECTED|SE_TAG_CONTEXT_ALLOW_PACKAGE|SE_TAG_CONTEXT_FIND_LENIENT),
                                          visited, 1);
   }

   // no matches, but they want to search all tag files
   num_matches := tag_get_num_of_matches();
   if (num_matches <= 0) {
      if (!editorctl_wid || _GetReferencesLookinOption() == VS_TAG_FIND_TYPE_EVERYWHERE) {
         class_name := strip(idexp_info.prefixexp, 'T', ".():/<>");
         tag_files := project_tags_filenamea();
         if (_GetReferencesLookinOption() == VS_TAG_FIND_TYPE_EVERYWHERE) {
            tag_files = _mdi.tags_filenamea("");
         }
         status = tag_list_symbols_in_context(idexp_info.lastid, 
                                              class_name, 
                                              0, 0, 
                                              tag_files, "",
                                              num_matches,
                                              def_tag_max_find_context_tags,
                                              SE_TAG_FILTER_ANYTHING,
                                              (SE_TAG_CONTEXT_ALLOW_PRIVATE|SE_TAG_CONTEXT_ALLOW_PROTECTED|SE_TAG_CONTEXT_ALLOW_PACKAGE|SE_TAG_CONTEXT_FIND_LENIENT),
                                              true, true, visited, 1);
         if (num_matches <= 0) {
            status = tag_list_symbols_in_context(idexp_info.lastid, 
                                                 class_name, 
                                                 0, 0, 
                                                 tag_files, "",
                                                 num_matches,
                                                 def_tag_max_find_context_tags,
                                                 SE_TAG_FILTER_ANYTHING,
                                                 (SE_TAG_CONTEXT_ALLOW_PRIVATE|SE_TAG_CONTEXT_ALLOW_PROTECTED|SE_TAG_CONTEXT_ALLOW_PACKAGE|SE_TAG_CONTEXT_FIND_LENIENT),
                                                 true, false, visited, 1);
         }
      }
   }

   // no matches, return error
   if (tag_get_num_of_matches() <= 0) {
      status = STRING_NOT_FOUND_RC;
   }

   // clean up the temp view
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   if (editorctl_wid) activate_window(editorctl_wid);

   // check if they specified the option to search with strict case-sensitivity
   case_sensitive_proc_name := "";
   if (_GetCodehelpFlags() & VSCODEHELPFLAG_GO_TO_DEF_CASE_SENSITIVE) {
      case_sensitive_proc_name = idexp_info.lastid;
   }

   // remove duplicate tags
   tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:true, 
                                       filterDuplicateGlobalVars:true, 
                                       filterDuplicateClasses:true, 
                                       filterAllImports:true, 
                                       filterDuplicateDefinitions:false, 
                                       filterAllTagMatchesInContext:false, 
                                       case_sensitive_proc_name, 
                                       filterFunctionSignatures:false, 
                                       visited, 1, 
                                       filterAnonymousClasses:true, 
                                       filterTagUses:true, 
                                       filterTagAttributes:true);

   // check find tag options and override defaults if necessary
   // avoid prompting for declaration vs. definition of the same symbol
   project_flags := (_GetCodehelpFlags() & VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT);
   if (_GetReferencesLookinOption() == VS_TAG_FIND_TYPE_PROJECT_ONLY) {
      project_flags |= VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT;
   }
   if (_GetReferencesLookinOption() == VS_TAG_FIND_TYPE_SAME_PROJECTS) {
      project_flags |= VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT;
   }
   int match_id = tag_check_for_preferred_symbol(project_flags|VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION);
   if (match_id > 0) {
      // used the selected declaration
      tag_get_match_info(match_id, cm);
   } else {
      // prompt user to select match
      status = tag_select_symbol_match(cm);
      if (status < 0) {
         tag_pop_matches();
         return status;
      }
   }

   // that's all folks
   tag_pop_matches();
   return status;
}

/**
 * Goes to the tag selected in the references history combo box.
 */
static void goToTagInDropDown()
{
   // get search tag name and search class name
   search_string := strip(ctlrefname.p_text);
   if (search_string=="") {
      return;
   }
   // remember this for later
   orig_wid := p_window_id;
   ctlrefname._lbadd_bounded(search_string);
   ctlrefname._lbselect_line();

   // try to evaluate the search string
   tag_init_tag_browse_info(auto cm);
   status := findReferenceSymbolInContext(search_string, cm);
   if (status == 0) {
      // use the search string as a context sensitive expression
      refresh_references_tab(cm, true, search_string);
      next_ref(true);
      return;
   }

   // parse out the tag name and class name
   tag_decompose_tag_browse_info(search_string, cm);

   // compose the tag into intermediate form
   search_string = cm.member_name;
   if (cm.type_name!="") {
      tag_init_tag_browse_info(auto search_cm, cm.member_name, cm.class_name, cm.type_name);
      search_string = tag_compose_tag_browse_info(search_cm);
   }
   if (search_string!="") {
      // check if the current workspace tag file or language specific
      // tag file requires occurrences to be tagged.
      if (_MaybeRetagOccurrences() == COMMAND_CANCELLED_RC) {
         return;
      }
      if (find_refs(search_string,1)==0) {
         // success, remember this for later
         if( orig_wid.ctlrefname.p_text != "" ) {
            orig_wid.RefsTreeTagBrowseInfo(cm);
            orig_wid.ctlrefname._lbadd_bounded(orig_wid.ctlrefname.p_text);
            orig_wid.ctlrefname._lbselect_line();
         }
      }
   }
}

static void refswin_mode_enter()
{
   refs_kill_all_timers();
   if (p_buf_name!="" || p_DocumentName!=REFS_WINDOW_DOC_NAME) {
      tagwin_goto_tag(p_buf_name, p_RLine);
   }
}

static void refswin_next_window()
{
   if (!_no_child_windows()) {
      int child_wid=_MDIGetActiveMDIChild();
      if (child_wid) {
         p_window_id=child_wid;
         child_wid._set_focus();
      }
   }else{
      _cmdline._set_focus();
   }
}

static typeless RefsWinCommands:[]={
   "split-insert-line"         =>refswin_mode_enter,
   "nosplit-insert-line"       =>refswin_mode_enter,
   "maybe-split-insert-line"   =>refswin_mode_enter,
   "select-line"               =>"",
   "brief-select-line"         =>"",
   "select-char"               =>"",
   "brief-select-char"         =>"",
   "emacs-select-char"         =>"",
   "cua-select"                =>"",
   "deselect"                  =>"",
   "copy-to-clipboard"         =>"",
   "next-window"               =>refswin_next_window,
   "prev-window"               =>refswin_next_window,
   "bottom-of-buffer"          =>"",
   "top-of-buffer"             =>"",
   "page-up"                   =>"",
   "vi-page-up"                =>"",
   "page-down"                 =>"",
   "vi-page-down"              =>"",
   "cursor-left"               =>"",
   "cursor-right"              =>"",
   "cursor-up"                 =>"",
   "cursor-down"               =>"",
   "begin-line"                =>"",
   "begin-line-text-toggle"    =>"",
   "brief-home"                =>"",
   "vi-begin-line"             =>"",
   "vi-begin-line-insert-mode" =>"",
   "brief-end"                 =>"",
   "end-line"                  =>"",
   "end-line-text-toggle"      =>"",
   "end-line-ignore-trailing-blanks"=>"",
   "vi-end-line"               =>"",
   "brief-end"                 =>"",
   "vi-end-line-append-mode"   =>"",
   "mou-click"                 =>"",
   "mou-select-word"           =>"",
   "mou-select-line"           =>"",
   "next-word"                 =>"",
   "prev-word"                 =>"",
   "cmdline-toggle"            =>refswin_next_window
};

void ctlrefedit.\0-ON_SELECT()
{
   _str lastevent=last_event();
   _str eventname=event2name(lastevent);
   if (eventname=="MOUSE-MOVE") return;
   refs_kill_all_timers();
   if (eventname=="ESC") {
      ToolWindowInfo* twinfo = tw_find_info(p_active_form.p_name);
      if (eventname=="ESC" && twinfo && (twinfo->flags & TWF_DISMISS_LIKE_DIALOG) ) {
         tw_dismiss(p_active_form);
      } else {
         refswin_next_window();
      }
      if (select_active()) {
         deselect();
      }
      return;
   }
   if (eventname=="A-F4") {
      if (!p_active_form.p_DockingArea) {
         p_active_form._delete_window();
         return;
      }else{
         safe_exit();
         return;
      }
   }
   if (upcase(eventname)=="LBUTTON-DOUBLE-CLICK") {
      refswin_mode_enter();
      return;
   }
   int key_index=event2index(lastevent);
   // Best not to use mode keys since have to know different "enter" keys
   name_index := eventtab_index(_default_keys,_default_keys /*ctlrefedit.p_mode_eventtab*/,key_index);
   command_name := name_name(name_index);
   if (command_name=="safe-exit") {
      safe_exit();
      return;
   }
   if (RefsWinCommands._indexin(command_name)) {
      orig_line:=p_line;
      orig_col:=p_col;
      select_was_active:=select_active();
      switch (RefsWinCommands:[command_name]._varformat()) {
      case VF_FUNPTR:
         _str junk=(*RefsWinCommands:[command_name])();
         break;
      case VF_LSTR:
         //junk=(*RefsWinCommands:[command_name][0])(RefsWinCommands:[command_name][1]);
         call_index(name_index);
         break;
      }
      if (_cua_select && !vsIsMouseEvent(key_index) && name_name(name_index)!='cua-select' && select_was_active && (orig_line!=p_line || orig_col!=p_col))  {
         deselect();
      }
   }
   //if (select_active()) deselect();
}

void ctlrefedit.wheel_down,wheel_up() {
   refs_kill_all_timers();
   fast_scroll();
}
void ctlrefedit."c-wheel-down"() {
   refs_kill_all_timers();
   scroll_page_down();
}
void ctlrefedit."c-wheel-up"() {
   refs_kill_all_timers();
   scroll_page_up();
}

void ctlreferences.rbutton_up()
{
   // Stop expanding if they click in the tree
   refs_kill_all_timers();
   set_references_next_message();

   // Get handle to menu:
   index := find_index("_tagbookmark_menu",oi2type(OI_MENU));
   menu_handle := p_active_form._menu_load(index,'P');

   flags := RefsEditWindowTagTypeFilters();
   pushTgConfigureMenu(menu_handle, flags, 
                       include_proctree:false, 
                       include_casesens:false, 
                       include_sort:false, 
                       include_save_print:true, 
                       include_search_results:true);

   // add a couple of things in?
   _menu_insert(menu_handle, 1, MF_ENABLED | MF_UNCHECKED, "Collapse all", "refs_crunch",   "m", "", "Collapse all nodes");
   _menu_insert(menu_handle, 1, MF_ENABLED | MF_UNCHECKED, "Expand all", "refs_expand_all", "m", "", "Expand all nodes");

   // Show menu:
   mou_get_xy(auto x,auto y);
   _KillToolButtonTimer();
   call_list("_on_popup2", translate("_tagbookmark_menu", "_", "-"), menu_handle);
   status := _menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

void ctlreferences.c_up()
{
   refs_kill_all_timers();
   ctlrefedit.cursor_up();
   preview_cursor_up();
}
void ctlreferences.c_down()
{
   refs_kill_all_timers();
   ctlrefedit.cursor_down();
   preview_cursor_down();
}
void ctlreferences.c_pgup()
{
   refs_kill_all_timers();
   ctlrefedit.scroll_page_up();
   preview_page_up();
}
void ctlreferences.c_pgdn()
{
   refs_kill_all_timers();
   ctlrefedit.scroll_page_down();
   preview_page_down();
}

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// kill all the timers associaed with the reference tool window
//
static void refs_kill_all_timers()
{
   refs_kill_expanding_timer();
   refs_kill_selected_timer();
   refs_kill_highlight_timer();
}
//////////////////////////////////////////////////////////////////////////////
// kill the existing references update timer
//
static void refs_kill_selected_timer()
{
   //say("refs_kill_selected_timer("gReferencesSelectedTimerId")");
   if (gReferencesSelectedTimerId != -1) {
      _kill_timer(gReferencesSelectedTimerId);
      gReferencesSelectedTimerId=-1;
   }
}

//////////////////////////////////////////////////////////////////////////////
// kill the existing references update timer
//
static void refs_start_selected_timer(int form_wid,typeless timer_cb, int index=0, int ms=-1)
{
   if (form_wid) {
      if (ms < 0) ms = CB_TIMER_DELAY_MS;
      gReferencesSelectedTimerId=_set_timer(ms, timer_cb, form_wid" "index);
   }
}

//////////////////////////////////////////////////////////////////////////////
// kill the existing references update timer
//
static void refs_kill_highlight_timer()
{
   //say("refs_kill_highlight_timer: "gReferencesHighlightTimerId);
   if (gReferencesHighlightTimerId != -1) {
      _kill_timer(gReferencesHighlightTimerId);
      gReferencesHighlightTimerId=-1;
   }
}

//////////////////////////////////////////////////////////////////////////////
// kill the existing references update timer
//
static void refs_start_highlight_timer(int form_wid,typeless timer_cb, int index=0, int ms=-1)
{
   if (ms < 0) ms = CB_TIMER_DELAY_MS;
   gReferencesHighlightTimerId=_set_timer(ms, timer_cb, form_wid" "index);
}

//////////////////////////////////////////////////////////////////////////////
// kill the existing references update timer
//
static void refs_kill_expanding_timer()
{
   if (gReferencesExpandingTimerId != -1) {
      _kill_timer(gReferencesExpandingTimerId);
      gReferencesExpandingTimerId=-1;
      next_prev_ref(0,true,true);
      clear_message();
   }
}

//////////////////////////////////////////////////////////////////////////////
// kill the existing references update timer
//
static void refs_start_expanding_timer(int form_wid, typeless timer_cb, int index=0, int ms=-1)
{
   if (ms < 0) ms = CB_TIMER_DELAY_MS;
   if (gReferencesExpandingTimerId == -1) {
      gReferencesExpandingTimerId=_set_timer(ms, timer_cb, form_wid" "index);
   }
}

//////////////////////////////////////////////////////////////////////////////
// compute name / line number string for sorting, accessing references
//
static _str ref_create_reference_info(int line_no, 
                                      int tag_id, 
                                      long seekpos, 
                                      int col_no, 
                                      _str tag_database, 
                                      int streamMarkerId,
                                      _str tag_type,
                                      SETagFlags tag_flags)
{
   return line_no ";" tag_id ";" seekpos ";" col_no ";" tag_database ";" streamMarkerId ";" tag_type ";" tag_flags;
}

//////////////////////////////////////////////////////////////////////////////
// compute name / line number string for sorting, accessing references
//
static void ref_parse_reference_info(_str ucm, 
                                     int &line_no, 
                                     int &tag_id, 
                                     long &seekpos, 
                                     int &col_no, 
                                     _str &tag_database, 
                                     int &mark_id, 
                                     _str &tag_type, 
                                     SETagFlags &tag_flags)
{
   typeless t_line_no, t_tag_id, t_seekpos, t_col_no, t_mark_id, t_flags;
   parse ucm with t_line_no ";" t_tag_id ";" t_seekpos ";" t_col_no ";" tag_database ";" t_mark_id ";" tag_type ";" t_flags;
   line_no = isuinteger(t_line_no)? t_line_no : 1;
   tag_id  = isuinteger(t_tag_id)?  t_tag_id  : 0;
   seekpos = isuinteger(t_seekpos)? t_seekpos : 1;
   col_no  = isuinteger(t_col_no)?  t_col_no  : 1;
   mark_id = isuinteger(t_mark_id)? t_mark_id : 0;
   tag_flags = isuinteger(t_flags)? t_flags   : SE_TAG_FLAG_NULL;
}

//////////////////////////////////////////////////////////////////////////////
// retrieve information from reference tree or call tree
// p_window_id must be the references or call (uses) tree control.
//
static int get_reference_tag_info(int j, struct VS_TAG_BROWSE_INFO &cm, int &inst_id)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //say("get_reference_tag_info: here, j="j);
   tag_init_tag_browse_info(cm);
   if (j <= 0) {
      return 0;
   }

   // check the parent node for the filename
   p := _TreeGetParentIndex(j);
   if (p==TREE_ROOT_INDEX) {
      cm.file_name=_TreeGetUserInfo(j);
      cm.line_no=1;
      cm.column_no=1;
      cm.seekpos=0;
      cm.member_name=_strip_filename(cm.file_name,'P');
      cm.type_name="file";
      return 1;
   } else {
      cm.file_name=_TreeGetUserInfo(p);
   }
   //say("get_reference_tag_info: p="p" cm.file_name="cm.file_name);

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
   ucm := _TreeGetUserInfo(j);
   ref_parse_reference_info(ucm, cm.line_no, inst_id, cm.seekpos, cm.column_no, cm.tag_database, auto streamMarkerId, auto tag_type, auto tag_flags);
   //say("get_reference_tag_info: file_name="cm.file_name" line_no="cm.line_no" seekpos="cm.seekpos" streamMarkerId="streamMarkerId);

   // get details about the instance (tag)
   if (inst_id > 0 && !tag_database) {
      tag_get_instance_info(inst_id, cm.member_name, cm.type_name, cm.flags, cm.class_name, cm.arguments, auto df, auto dl);
      //say("get_reference_tag_info(): got here 3, inst_id="inst_id" member_name="cm.member_name" file_name="cm.file_name" line_no="cm.line_no" args="cm.arguments);
   } else {
      // normalize member name
      //cm.seekpos=0;//iid;
      tag_tree_decompose_caption(_TreeGetCaption(j),cm.member_name,cm.class_name,cm.arguments);
   }

   // if we have a stream marker
   if (streamMarkerId != "" && streamMarkerId > 0) {
      //say("get_reference_tag_info H"__LINE__": marker="streamMarkerId);
      _StreamMarkerGet(streamMarkerId, auto info);
      //_dump_var(info, "get_reference_tag_info H"__LINE__": info");
      if ( info != null ) {
         if ( info.StartOffset != null && info.StartOffset > 0 )  cm.seekpos = info.StartOffset;
         if ( info.DeferredBufName != null && cm.file_name == "") cm.file_name = info.DeferredBufName;
         //say("get_reference_tag_info H"__LINE__": cm.seekpos="cm.seekpos);
      }
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
      cm.file_name = "";
   }

   // count the number of exact matches for this tag
   search_file_name  := cm.file_name;
   search_type_name  := cm.type_name;
   search_class_name := cm.class_name;
   search_arguments :=  VS_TAGSEPARATOR_args:+cm.arguments;
   lang := _Filename2LangId(search_file_name);
   cm.language = lang;
   tag_files := tags_filenamea(lang);
   i := 0;
   tag_filename := next_tag_filea(tag_files,i,false,true);
   while (tag_filename != "") {
      //say("get_reference_tag_info: tag_file="tag_filename);
      // search for exact match
      _str alt_type_name = search_type_name;
      //_message_box("member="cm.member_name" type="search_type_name" class="cm.class_name" args="cm.arguments" file="search_file_name);
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
         orig_name := cm.member_name;
         tag_get_tag_browse_info(cm);
         cm.member_name = orig_name;
         if (cm.type_name :!= search_type_name && cm.type_name != alt_type_name) {
            break;
         }
         //if (cm.class_name :!= search_class_name) {
         //   break;
         //}
         // file name matches, then we've found our perfect match!!!
         if (search_file_name == "" || _file_eq(search_file_name, cm.file_name)) {
            cm.tag_database=tag_filename;
            return 1;
         }
         // get next tag
         status = tag_next_equal(true /*case sensitive*/);
      }
      tag_reset_find_tag();

      // try the next tag file
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }

   return 0;
}

void tag_refs_clear_pics(int pic_type=-1)
{
   // remove the picture for this specific item
   if (pic_type >= 0) {
      _StreamMarkerRemoveAllType(pic_type);
      return;
   }
   // remove all picture types
   refs_kill_all_timers();
   for (i:=0; i<gref_pic_types._length(); i++) {
      _StreamMarkerRemoveAllType(gref_pic_types[i]);
   }
}

static int tag_refs_create_pics_for_file(int tree_wid, int tree_index, _str file_name, _str tag_name, _str search_opts="", int editorctl_wid=0)
{
   pic_type := RefsEditWindowPicType();
   if (pic_type < 0) {
      if (gref_pic_types._length() < REFS_MAX_PIC_TYPES+1) {
         pic_type = _MarkerTypeAlloc();
         RefsEditWindowPicType(pic_type);
         gref_pic_types :+= pic_type;
      } else {
         pic_type = gref_pic_types[0];
      }
   }

   // update the references editor bitmap
   if (!(def_references_options & VSREF_NO_BITMAPS_IN_MARGIN)) {
      if (_pic_editor_reference <= 0) {
         _pic_editor_reference = _update_picture(0, "_ed_reference.svg");
      }
      if (_pic_editor_ref_assign <= 0) {
         _pic_editor_ref_assign = _update_picture(0, "_ed_ref_assign.svg");
      }
      if (_pic_editor_ref_const <= 0) {
         _pic_editor_ref_const = _update_picture(0, "_ed_ref_const.svg");
      }
      if (_pic_editor_ref_nonconst <= 0) {
         _pic_editor_ref_nonconst = _update_picture(0, "_ed_ref_nonconst.svg");
      }
      if (_pic_editor_ref_unknown <= 0) {
         _pic_editor_ref_unknown = _update_picture(0, "_ed_ref_unknown.svg");
      }
   }

   // set up stream marker color
   marker_color := reference_marker_type_color(pic_type);
   if (def_references_options & VSREF_HIGHLIGHT_MATCHES) {
      _MarkerTypeSetColorIndex(pic_type, marker_color);
      _MarkerTypeSetFlags(pic_type, VSMARKERTYPEFLAG_USE_MARKER_TYPE_COLOR|VSMARKERTYPEFLAG_DRAW_SCROLL_BAR_MARKER);
   } else {
      _MarkerTypeSetFlags(pic_type, 0);
   }

   // decide whether to display bitmap in margin or not
   pic_refs := _pic_editor_reference;
   pic_assign := _pic_editor_ref_assign;
   pic_const  := _pic_editor_ref_const;
   pic_nonconst := _pic_editor_ref_nonconst;
   pic_unknown := _pic_editor_ref_unknown;
   if (def_references_options & VSREF_NO_BITMAPS_IN_MARGIN) {
      pic_refs = 0;
      pic_assign = 0;
   }

   // get references filtering flags
   tagFilterFlags := RefsEditWindowTagTypeFilters();
   refs_get_filter_options(auto assign_filter, auto const_filter);

   int bitmaps[];
   num_pics := 0;
   child_index := tree_wid._TreeGetFirstChildIndex(tree_index);
   while (child_index > 0) {

      // select which editor margin bitmap to use (plain ref or assignment)
      have_assignment := false;
      have_const      := false;
      have_nonconst   := false;
      have_unknown    := false;
      pic_to_use := pic_refs;
      bitmaps._makeempty();
      tree_wid._TreeGetOverlayBitmaps(child_index, bitmaps);
      foreach ( auto bm_index in  bitmaps) {
         if (bm_index == _pic_symbol_assign) {
            have_assignment = true;
         } else if (bm_index == _pic_symbol_const) {
            have_const = true;
         } else if (bm_index == _pic_symbol_nonconst) {
            have_nonconst = true;
         } else if (bm_index == _pic_symbol_unknown) {
            have_unknown = true;
         }
      }
      if (have_assignment) {
         pic_to_use = pic_assign;
      } else if (have_const) {
         pic_to_use = pic_const;
      } else if (have_unknown) {
         pic_to_use = pic_unknown;
      }

      // determine if this reference should be hidden
      hide_assign_ref := false;
      if (assign_filter == REF_ASSIGNMENT_FILTER_WRITES) {
         hide_assign_ref = !have_assignment;
      } else if ( assign_filter == REF_ASSIGNMENT_FILTER_READS ) {
         hide_assign_ref = have_assignment;
      }
      hide_nonconst_ref := false;
      if (const_filter == REF_CONST_FILTER_NON_CONST) {
         hide_nonconst_ref = have_const;// && !have_assignment;
      } else if ( const_filter == REF_CONST_FILTER_CONST ) {
         hide_nonconst_ref = !have_const;
      }

      // get the tag user info
      filter_symbol_type := false;
      tag_info := tree_wid._TreeGetUserInfo(child_index);
      ref_parse_reference_info(tag_info, auto line_no, auto tag_id, auto ref_seekpos, auto col_no, auto tag_database, auto markerId, auto tag_type, auto tag_flags);
      if (!tag_filter_type(SE_TAG_TYPE_NULL, tagFilterFlags, tag_type, (int)tag_flags)) {
         filter_symbol_type = true;
      } else if ( have_unknown && !(tagFilterFlags & SE_TAG_FILTER_UNKNOWN) ) {
         filter_symbol_type = true;
      }

      // update the tree node flags the hidden state changed
      tree_wid._TreeGetInfo(child_index,auto state, auto bm1, auto bm2, auto nodeFlags);
      if ( hide_assign_ref || hide_nonconst_ref || filter_symbol_type ) {
         tree_wid._TreeSetInfo(child_index, state, bm1, bm2, nodeFlags | TREENODE_HIDDEN);
      } else {
         tree_wid._TreeSetInfo(child_index, state, bm1, bm2, nodeFlags & ~TREENODE_HIDDEN);
      }

      if (markerId == "" || markerId <= 0) {
         if (editorctl_wid && editorctl_wid._isEditorCtl()) {
            editorctl_wid._GoToROffset(ref_seekpos);
            cur_name := editorctl_wid.cur_identifier(col_no);
            if (col_no <= 0) col_no = editorctl_wid.p_col;
            ref_len := length(cur_name);
            editorctl_wid.get_line(cur_name);
            cur_name = substr(cur_name, col_no);
            i := 1;
            if (last_char(search_opts) != 's') {
               // if this was a subword pattern match (from Find Symbol tool window)
               i = pos(tag_name, cur_name, 1, search_opts);
            }
            if (i > 0 && i <= ref_len+8) {
               editorctl_wid.p_col = col_no;
               ref_seekpos = editorctl_wid._QROffset() + (i-1);
               ref_len = pos('');
               cur_name = substr(cur_name, i, i+ref_len);
            }
            markerId = _StreamMarkerAddB(file_name, ref_seekpos, ref_len, true, pic_to_use, pic_type, "Found Symbol: "cur_name);
         } else {
            markerId = _StreamMarkerAddB(file_name, ref_seekpos, length(tag_name), true, pic_to_use, pic_type, "Reference to "tag_name);
         }
         tag_info = ref_create_reference_info(line_no, tag_id, ref_seekpos, col_no, tag_database, markerId, tag_type, tag_flags);
         tree_wid._TreeSetUserInfo(child_index, tag_info);
         num_pics++;
      }

      child_index = tree_wid._TreeGetNextSiblingIndex(child_index);
   }

   return num_pics;
}

static int cb_add_file_refs(_str file_name, struct VS_TAG_BROWSE_INFO &cm,
                            SETagFilterFlags filter_flags, SETagContextFlags context_flags, 
                            int tree_index,
                            int &num_refs, int max_refs,
                            _str tag_name=null, bool case_sensitive=false,
                            int start_seekpos=0, int end_seekpos=0,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // regulate prior result cache size to prevent memory from growing excessively
   if (visited._length() > def_tagging_cache_ksize) {
      visited._makeempty();
   }
   if (_chdebug) {
      isay(depth, "cb_add_file_refs: file="file_name);
   }
   // open a temporary view of 'file_name'
   tree_wid := p_window_id;
   int temp_view_id,orig_view_id;
   bool inmem;
   int status=_open_temp_view(file_name,temp_view_id,orig_view_id,"",inmem,false,true);
   if (!status) {
      // delegate the bulk of the work
      //say("cb_add_file_refs: cm.file="cm.file_name" cm.line="cm.line_no);
      if (case_sensitive==null || case_sensitive==false) {
         case_sensitive=p_EmbeddedCaseSensitive;
      }
      if (tag_tree_type_is_func(cm.type_name) && (cm.flags & SE_TAG_FLAG_ABSTRACT)) {
         context_flags |= SE_TAG_CONTEXT_FIND_PARENTS;
      }
      if (p_buf_size<def_use_old_line_numbers_ksize*1024) {
         _SetAllOldLineNumbers();
      }
      _str errorArgs[]; errorArgs._makeempty();
      // If the symbol we are searching for is an include file,
      // limit the filter flags to just INCLUDE tags.  This serves as an
      // indicator to tag_symbol_match_occurrences_in_file() to also search 
      // within strings, since the include file specs can be in strings.
      if (cm.type_name=="include" || cm.type_name=="file") {
         filter_flags = SE_TAG_FILTER_INCLUDE;
      }
      status = tag_match_symbol_occurrences_in_file(errorArgs,
                                                    tree_wid,tree_index,
                                                    cm, case_sensitive,
                                                    filter_flags,
                                                    context_flags,
                                                    start_seekpos,end_seekpos,
                                                    num_refs,max_refs,
                                                    visited,depth+1);
      if (_chdebug) {
         isay(depth, "cb_add_file_refs: cm.member_name="cm.member_name" line="cm.line_no" status="status);
      }

      num_pics := 0;
      if (!status) {
         num_pics = tree_wid.p_active_form.tag_refs_create_pics_for_file(tree_wid,tree_index,file_name,tag_name);
      }

      expandingHasCancel := _GetDialogInfoHt(REFS_EXPANDING_HASCANCEL);
      if (expandingHasCancel == null || expandingHasCancel == false) {
         tree_wid._TreeSizeColumnToContents(0);
         if (!status) {
            if (num_pics > 0 && !_no_child_windows() && temp_view_id.p_buf_id == _mdi.p_child.p_buf_id) {
               refresh();
            }
         }
      }

      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
   }

   // that's all folks
   return status;
}

//////////////////////////////////////////////////////////////////////////////
// Insert items called or used by the given tag (tag_id) into the given tree.
// Opens the given database.  Returns the number of items inserted.
// p_window_id must be the references tree control.
//
static int cb_add_bsc_refs(int &count, SETagFilterFlags filter_flags, int i,
                           struct VS_TAG_BROWSE_INFO cm, _str ref_database)
{
   // collect the file names so far
   _str file_name;
   int file_index_map:[]; file_index_map._makeempty();
   j := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (j > 0) {
      file_name=_TreeGetUserInfo(j);
      if (file_name != "") {
         file_index_map:[_file_case(file_name)] = j;
      }
      j = _TreeGetNextSiblingIndex(j);
   }

   // match tag up with instance in refernces database
   //message("member="cm.member_name" type="cm.type_name" class="cm.class_name" arguments="cm.arguments);
   int inst_id = tag_match_instance(cm.member_name, cm.type_name, 0, cm.class_name, cm.arguments, cm.file_name, cm.line_no, 1);
   if (inst_id < 0) {
      return 0;
   }
   member_name := "";
   class_name := "";
   type_name := "";
   arguments := "";
   int lno;
   flags := SE_TAG_FLAG_NULL;
   tag_get_instance_info(inst_id, member_name, type_name, flags, class_name, arguments, file_name, lno);

   // find references to this instance
   int ref_type,line_no;
   int context_id = tag_find_refer_to(inst_id, ref_type, file_name, line_no);

   //say("context id="context_id);
   while (context_id >= -1 && count < def_cb_max_references) {

      // if something is going on, get out of here
      if (count % 20 == 0 && _IsKeyPending(false)) {
         break;
      }

      // find the tree entry to insert this reference under
      int tree_index = TREE_ROOT_INDEX;
      if (file_index_map._indexin(_file_case(file_name))) {
         tree_index = file_index_map:[_file_case(file_name)];
      } else {
         base_name := _strip_filename(file_name,'P');
         tree_index=_TreeAddItem(TREE_ROOT_INDEX,base_name:+"\t":+file_name,TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,_pic_file,_pic_symbol_public,1,0,file_name);
         file_index_map:[_file_case(file_name)]=tree_index;
      }
      //say("cb_add_bsc_refs: file="file_name" index="tree_index);

      // get the tag information for either the tag or instance
      if (context_id > 0) {
         // get details about this tag (for creating caption)
         tag_get_instance_info(context_id, member_name, type_name, flags, class_name, arguments, file_name, lno);
      }

      // find the tag and create caption and icon for it
      pic_ref := 0;
      pic_overlay := 0;
      fcaption := "";
      if (type_name != "" && member_name != "") {
         show_it := false;
         if (tag_filter_type(SE_TAG_TYPE_NULL,filter_flags,type_name,(int)flags)) {
            // make caption for this instance
            tag_init_tag_browse_info(auto instance_cm, member_name, class_name, type_name, (SETagFlags)flags);
            fcaption = tag_make_caption_from_browse_info(instance_cm, include_class:true, include_args:false, include_tab:true);
            pic_ref = tag_get_bitmap_for_type(tag_get_type_id(type_name), (SETagFlags)flags, pic_overlay);
         }
      } else if (filter_flags & SE_TAG_FILTER_MISCELLANEOUS) {
         // insert the item and set the user info
         fcaption = _strip_filename(file_name,'P'):+"\t":+file_name:+": ":+line_no;
         pic_ref = tag_get_bitmap_for_type(SE_TAG_TYPE_UNKNOWN);
      }
      if (fcaption != "") {
         // find-tune column widths if necessary
         _str rpart,lpart;
         parse fcaption with rpart "\t" lpart;
         // set up the user info for this tag
         ucaption := ref_create_reference_info(line_no, context_id, 0, 0, ref_database, 0, type_name, flags);
         // insert the item and set the user info
         j = _TreeAddItem(tree_index,fcaption,TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,pic_overlay,pic_ref,-1,0,ucaption);
         if (j < 0) {
            break;
         }
         ++count;
      }

      // next, please
      context_id = tag_next_refer_to(inst_id, ref_type, file_name, line_no);
   }

   // return total number of items inserted
   _TreeSizeColumnToContents(0);
   return count;
}

/**
 * Is the given item from a C header file?
 */
bool isCHeaderFile(VS_TAG_BROWSE_INFO &cm)
{
   // must be C, C++, Objective-C, or ANSI-C
   switch (cm.language) {
   case "c":
   case "cpp":
   case "m":
   case "ansic":
      break;
   default:
      return false;
   }

   // get file extension
   ext := _get_extension(cm.file_name);

   // extensionless C header file
   if (length(ext)==0) {
      return true;
   }

   // starts with 'h' or 'i', probably a header file, otherwise, no
   switch (_first_char(ext)) {
   case "H":
   case "h":
   case "I":
   case "i":
      return true;
   case "C":
   case "c":
   case "M":
   case "m":
      return false;
   }
   return false;
}

//////////////////////////////////////////////////////////////////////////////
// Insert items called or used by the given tag (tag_id) into the given tree.
// Opens the given database.  Returns the number of items inserted.
// p_window_id must be the references tree control.
//
static int cb_add_refs(int i, struct VS_TAG_BROWSE_INFO cm, bool &terminated_early,
                       _str buf_name=null, bool case_sensitive=true)
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
   sticky_message("Searching for references to '"cm.member_name"'.  Press any key to stop.");
   mou_hour_glass(true);
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

   filter_flags := RefsEditWindowTagTypeFilters();
   count := 0;

   // open the tag database for business
   tag_database := 0;
   ref_database := refs_filename();
   _str tag_files[];
   if (ref_database != "") {
      //say("cb_add_refs: got reference database="ref_database);
      tag_files._makeempty();
      tag_files[0]=ref_database;
   } else {
      tag_database=1;
      _str cm_lang = cm.language;
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
   refs_scope := _GetReferencesLookinOption();
   t := 0; 
   tree_index := TREE_ROOT_INDEX;
   alt_tree_index := TREE_ROOT_INDEX;
   bool files_included:[];
   only_look_in_buffer := false;

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
          ((cm.tag_database==null || cm.tag_database=="") && 
           tag_find_local_iterator(cm.member_name, exact:true, case_sensitive:true, class_name:cm.class_name) > 0) ||
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
            say("cb_add_refs: ORIGINATING FILE: "cm.file_name);
         }
         files_included:[_file_case(cm.file_name)] = true;
         tree_index=_TreeAddItem(TREE_ROOT_INDEX,_strip_filename(cm.file_name,'P'):+"\t":+cm.file_name,TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,_pic_file,_pic_symbol_public, 0, 0, cm.file_name);
         int ww = _text_width(cm.file_name);
         _TreeColWidth(0,ww);
      }
      
      // Don't add other files if they specified this buffer only
      if (!only_look_in_buffer && refs_scope != VS_TAG_FIND_TYPE_BUFFER_ONLY) {
         // always look for references in the file containing the declaration
         if (decl_cm.file_name != "" && decl_cm.language != "tagdoc" &&
             !files_included._indexin(_file_case(decl_cm.file_name)) &&
             !_QBinaryLoadTagsSupported(decl_cm.file_name) ) {
            if (_chdebug) {
               say("cb_add_refs: DECLARED IN FILE: "decl_cm.file_name);
            }
            alt_tree_index=_TreeAddItem(TREE_ROOT_INDEX,_strip_filename(decl_cm.file_name,'P'):+"\t":+decl_cm.file_name,TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,_pic_file,_pic_symbol_public, 0, 0, decl_cm.file_name);
            files_included:[_file_case(decl_cm.file_name)] = true;
         }
         // always look for references in the file containing the definition
         if (orig_file_name != "" && cm.language != "tagdoc" &&
             !files_included._indexin(_file_case(orig_file_name)) &&
             !_QBinaryLoadTagsSupported(orig_file_name) ) {
            if (_chdebug) {
               say("cb_add_refs: DEFINED IN FILE: "orig_file_name);
            }
            files_included:[_file_case(orig_file_name)] = true;
            alt_tree_index=_TreeAddItem(TREE_ROOT_INDEX,_strip_filename(orig_file_name,'P'):+"\t":+orig_file_name,TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,_pic_file,_pic_symbol_public, 0, 0, orig_file_name);
         }
         // always look for references associated file names also
         foreach (auto assoc_file_name in assoc_file_names) {
            assoc_file_name = _maybe_unquote_filename(assoc_file_name);
            if (assoc_file_name != "" && cm.language != "tagdoc" &&
                !files_included._indexin(_file_case(assoc_file_name)) &&
                !_QBinaryLoadTagsSupported(assoc_file_name) ) {
               if (_chdebug) {
                  say("cb_add_refs: ASSOCIANTED FILE NAME: "assoc_file_name);
               }
               files_included:[_file_case(assoc_file_name)] = true;
               alt_tree_index=_TreeAddItem(TREE_ROOT_INDEX,_strip_filename(assoc_file_name,'P'):+"\t":+assoc_file_name,TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,_pic_file,_pic_symbol_public, 0, 0, assoc_file_name);
            }
         }
      }

      // and give the current buffer a shot, too
      if (buf_name!=null && buf_name!="" && !files_included._indexin(_file_case(buf_name))) {
         if (_chdebug) {
            say("cb_add_refs: CURRENT BUFFER: "buf_name);
         }
         files_included:[_file_case(buf_name)] = true;
         alt_tree_index=_TreeAddItem(TREE_ROOT_INDEX,_strip_filename(buf_name,'P'):+"\t":+buf_name,TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,_pic_file,_pic_symbol_public, 0, 0, buf_name);
      }
   }

   // add all open buffers to the list of files to search
   if (refs_scope == VS_TAG_FIND_TYPE_ALL_BUFFERS) {
      // switch to the hidden window
      get_window_id(auto orig_tree_wid);
      activate_window(VSWID_HIDDEN);
      _safe_hidden_window();
      orig_buf_id := p_buf_id;
      for (;;) {

         // add this buffer if it hasn't already been added
         if (!(p_buf_flags & VSBUFFLAG_HIDDEN) && !IsSpecialFile(_GetDocumentName())) {
            if (p_buf_name != "" && !files_included._indexin(_file_case(p_buf_name))) {
               if (_chdebug) {
                  say("cb_add_refs: BUFFER: "p_buf_name);
               }
               files_included:[_file_case(p_buf_name)] = true;
               orig_tree_wid._TreeAddItem(TREE_ROOT_INDEX,_strip_filename(p_buf_name,'P'):+"\t":+p_buf_name,TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,_pic_file,_pic_symbol_public, 0, 0, p_buf_name);
            }
         }

         // next buffer please
         _next_buffer('HR');
         if (p_buf_id == orig_buf_id) {
            break;
         }
      }
      activate_window(orig_tree_wid);
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
   _str refs_projects[];
   switch (refs_scope) {
   case VS_TAG_FIND_TYPE_EVERYWHERE:
      // default behavior
      break;
   case VS_TAG_FIND_TYPE_BUFFER_ONLY:
      tag_files._makeempty();
      break;
   case VS_TAG_FIND_TYPE_ALL_BUFFERS:
      tag_files._makeempty();
      break;
   case VS_TAG_FIND_TYPE_PROJECT_ONLY:
      if (project_tags_filename() != "") {
         tag_files._makeempty();
         tag_files[0] = project_tags_filename_only();
         if (tag_files[0] == "") {
            tag_files[0] = workspace_tags_filename_only();
         }
         refs_projects[0] = _project_name;
      }
      break;
   case VS_TAG_FIND_TYPE_SAME_PROJECTS:
      if (buf_name != null && buf_name != "") {
         tag_files._makeempty();
         bool foundTagFiles:[];
         refs_projects = _WorkspaceFindAllProjectsWithFile(buf_name);
         foreach (auto one_project in refs_projects) {
            proj_tagfile := project_tags_filename_only(one_project);
            if (proj_tagfile == "") continue;
            if (foundTagFiles._indexin(_file_case(proj_tagfile))) continue;
            foundTagFiles:[_file_case(proj_tagfile)] = true;
            tag_files :+= proj_tagfile;
         }
         if (tag_files._length() <= 0) {
            tag_files[0] = workspace_tags_filename_only();
         }
      } else if (project_tags_filename() != "") {
         tag_files._makeempty();
         tag_files = project_tags_filenamea();
      }
      break;
   case VS_TAG_FIND_TYPE_WORKSPACE_ONLY:
      if (project_tags_filename() != "") {
         tag_files._makeempty();
         tag_files = project_tags_filenamea();
      }
      break;
   }

   // check if the search scope restrictions still contain tag files which
   // reference the language we are searching for.
   if (refs_scope == VS_TAG_FIND_TYPE_PROJECT_ONLY || 
       refs_scope == VS_TAG_FIND_TYPE_SAME_PROJECTS || 
       refs_scope == VS_TAG_FIND_TYPE_WORKSPACE_ONLY) {
      tag_file_has_lang := false;
      foreach (auto tag_filename in tag_files) {
         // make sure this database matches the language we are searching for
         if (tag_read_db(tag_filename) < 0) continue;
         if (tag_find_language(auto foundLang, restrictToLangId) >= 0) {
            tag_file_has_lang = true;
            break;
         }
      }
      if (!tag_file_has_lang) {
         tag_files = orig_tag_files;
      }
   }

   // if we are only supposed to look in the current buffer, burn the tag files
   if (only_look_in_buffer) {
      tag_files._makeempty();
   }

   if (_chdebug) {
      say("cb_add_refs: lang="restrictToLangId);
   }

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
            say("cb_add_refs: ADD FILES FROM: "ref_database);
         }
         tag_list_file_occurrences(p_window_id,TREE_ROOT_INDEX,
                                   cm.member_name,1,(int)case_sensitive,
                                   count,def_cb_max_references,
                                   restrictToLangId);
         if (_chdebug) {
            index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
            if (last_file_index > 0) {
               index = _TreeGetNextSiblingIndex(last_file_index);
            }
            while (index > 0) {
               file_name := _TreeGetCaption(index);
               if (_chdebug) {
                  say("cb_add_refs    FOUND FILE: ":+file_name);
               }
               last_file_index = index;
               index = _TreeGetNextSiblingIndex(index);
            }
         }
         // How much do I love Perl?  
         // Let me count the ways I can run over it with a large garbage truck.
         if ((_LanguageInheritsFrom("pl", cm.language) || _LanguageInheritsFrom("phpscript", cm.language)) && pos(_first_char(cm.member_name),"$%@")) {
            if (_chdebug) {
               say("cb_add_refs: PERL SPECIAL CASE symbol=: "cm.member_name);
            }
            tag_list_file_occurrences(p_window_id,TREE_ROOT_INDEX,
                                      substr(cm.member_name,2),1,(int)case_sensitive,
                                      count,def_cb_max_references,
                                      restrictToLangId);
         }
      } else {
         // match instances in BSC database
         if (_chdebug) {
            say("cb_add_refs: ADD FILES FROM BSC: "ref_database);
         }
         cb_add_bsc_refs(count,filter_flags,i,cm,ref_database);
         // close the BSC database
         status = tag_close_db(ref_database,true);
         if ( status ) {
            break;
         }
      }

      // next tag file, please...
      ref_database=next_tag_filea(tag_files,t,false,true);
   }

   // Filter out items that are not in the current project
   // Also filter out items that are not the current buffer or required
   if (refs_projects._length() > 0 || refs_scope == VS_TAG_FIND_TYPE_BUFFER_ONLY) {
      index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      filter_loop: while (index > 0) {
         file_name  := _TreeGetUserInfo(index);
         if (files_included._indexin(_file_case(file_name))) {
            index = _TreeGetNextSiblingIndex(index);
            continue filter_loop;
         }
         if (refs_projects._length() > 0) {
            foreach (auto one_project in refs_projects) {
               if (one_project != "" && _isFileInProject(_workspace_filename, one_project, file_name)) {
                  index = _TreeGetNextSiblingIndex(index);
                  continue filter_loop;
               }
            }
         }
         orig_index := index;
         index = _TreeGetNextSiblingIndex(index);
         refs_kill_highlight_timer();
         _TreeDelete(orig_index);
      }
   }

   // for each file found in the list
   _TreeSortCaption(TREE_ROOT_INDEX,'UF');

   // if the current buffer is in the list, float it to the top
   if (buf_name != null && buf_name != "") {
      int j=_TreeSearch(TREE_ROOT_INDEX, _strip_filename(buf_name,'P'):+"\t":+buf_name, _fpos_case);
      if (j >= 0) {
         if (_TreeGetFirstChildIndex(j)<0) {
            refs_kill_highlight_timer();
            _TreeDelete(j);
            j=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
            if (j>0) {
               alt_tree_index=_TreeAddItem(j,_strip_filename(buf_name,'P'):+"\t":+buf_name,TREE_ADD_BEFORE|TREE_OVERLAY_BITMAP1,_pic_file,_pic_symbol_public, 0, 0, buf_name);
            } else {
               alt_tree_index=_TreeAddItem(TREE_ROOT_INDEX,_strip_filename(buf_name,'P'):+"\t":+buf_name,TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,_pic_file,_pic_symbol_public, 0, 0, buf_name);
            }
         }
      }
   }

   // expand all the references, unless we are doing incremental referencing
   if (def_references_options & VSREF_FIND_ALL_IMMEDIATELY) {
      expandAllReferencesNow(_GetReferencesSymbolName());

   } else if (!(def_references_options & VSREF_FIND_INCREMENTAL)) {

      // Always expand the references in the current file directly
      j := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if (j > 0) {
         if (_TreeGetFirstChildIndex(j) <= 0) {
            call_event(CHANGE_EXPANDED,j,p_window_id,ON_CHANGE,'w');
            _TreeSetInfo(j,1);
            count += _TreeGetNumChildren(j);
         }
      }

      // Start timer to expand the rest of the references
      _SetDialogInfoHt(REFS_EXPANDING_INDEX, -1); 
      _SetDialogInfoHt(REFS_EXPANDING_COUNT, count); 
      _SetDialogInfoHt(REFS_EXPANDING_STOPPED, false);
      refs_start_expanding_timer(p_active_form,_RefListExpandingCallback, 0, 50);
   }

   // set the column width
   _TreeSizeColumnToContents(0);
   mou_hour_glass(false);
   stopped := _GetDialogInfoHt(REFS_EXPANDING_STOPPED);
   if (stopped != null && stopped != false) {
      terminated_early=true;
   }
   count = _GetDialogInfoHt(REFS_EXPANDING_COUNT);
   if (count != null && count >= def_cb_max_references) {
      _SetDialogInfoHt(REFS_EXPANDING_STOPPED, true);
      terminated_early=true;
   }

   // force an update of the previous context
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_pop_context();

   // return total number of items inserted
   return count;
}

static void refresh_references_view(struct VS_TAG_BROWSE_INFO cm, bool &terminated_early,
                                    _str buf_name=null, bool case_sensitive=true)
{
   // populate the list of references
   //tag_refs_clear_pics();
   _SetDialogInfoHt(REFS_VISITED_KEY, null, _mdi); 
   _SetDialogInfoHt(REFS_EXPANDING_STOPPED, false);
   ctlreferences._TreeDelete(TREE_ROOT_INDEX, 'C');
   ctlreferences._TreeColWidth(0,10);
   cb_prepare_expand(p_active_form,ctlreferences,TREE_ROOT_INDEX);

   // blow out of here if cm is empty
   if (cm.member_name=="") {
      return;
   }

   //mou_hour_glass(true);
   if ( ctlrefname.p_text != "" ) {
      ctlrefname._lbadd_bounded(ctlrefname.p_text);
      ctlrefname._lbselect_line();
   }
   count := ctlreferences.cb_add_refs(TREE_ROOT_INDEX, cm, terminated_early, buf_name, case_sensitive);

   if (count==0 && tag_tree_type_is_func(cm.type_name)) {
      if (tag_find_tag(cm.member_name, "proto", cm.class_name, VS_TAGSEPARATOR_args:+cm.arguments)==0) {
         //tag_get_detail(VS_TAGDETAIL_tag_id, proto_tag_id);
         count = ctlreferences.cb_add_refs(TREE_ROOT_INDEX, cm, terminated_early, buf_name, case_sensitive);
      } else if (tag_find_tag(cm.member_name, "procproto", cm.class_name, VS_TAGSEPARATOR_args:+cm.arguments)==0) {
         //tag_get_detail(VS_TAGDETAIL_tag_id, proto_tag_id);
         count = ctlreferences.cb_add_refs(TREE_ROOT_INDEX, cm, terminated_early, buf_name, case_sensitive);
      }
      tag_reset_find_tag();
   }
   if (count==0 && tag_tree_type_is_class(cm.type_name)) {
      if (tag_find_tag(cm.member_name, "interface", cm.class_name)==0) {
         //tag_get_detail(VS_TAGDETAIL_tag_id, proto_tag_id);
         count = ctlreferences.cb_add_refs(TREE_ROOT_INDEX, cm, terminated_early, buf_name, case_sensitive);
      }
      tag_reset_find_tag();
   }
   //say("count="count);
   _mffindNoMore(def_mfflags);
   _mfrefIsActive=true;

   // sort exactly the way we want things
   //ctlreferences._TreeSortUserInfo(TREE_ROOT_INDEX,'TI');
   //ctlreferences._TreeTop();
   ctlreferences._TreeRefresh();
   //mou_hour_glass(false);
}


//////////////////////////////////////////////////////////////////////////////
// Handle double-click event (opens the file and positions us on the
// line indicated by the reference data), this may or may not be the
// right line to be positioned on.
//
void ctlreferences.enter,lbutton_double_click()
{
   // get the context information, push book mark, and open file to line
   refs_kill_all_timers();
   if (ctlreferences.get_reference_tag_info(ctlreferences._TreeCurIndex(), auto cm, auto inst_id)) {
      tagwin_goto_tag(cm.file_name,cm.line_no,cm.seekpos,cm.column_no,def_search_result_push_bookmark);
      _mffindNoMore(def_mfflags);
      _mfrefIsActive=true;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle double-click event (opens the file and positions us on the
// line indicated by the reference data), this may or may not be the
// right line to be positioned on.
//
void ctlreferences." "()
{
   // IF this is an item we can go to like a class name
   refs_kill_all_timers();
   orig_window_id := p_window_id;

   // get the context information, push book mark, and open file to line
   if (ctlreferences.get_reference_tag_info(ctlreferences._TreeCurIndex(), auto cm, auto inst_id)) {
      tagwin_goto_tag(cm.file_name,cm.line_no,cm.seekpos,cm.column_no,def_search_result_push_bookmark);
   }

   // restore original focus
   p_window_id = orig_window_id;
   ctlreferences._set_focus();
}

//////////////////////////////////////////////////////////////////////////////
// Report that the given tag reference can not be found.
// Current object needs to be the tree control
//
void message_cannot_find_ref(int currIndex)
{
   caption := _TreeGetCaption(currIndex);
   parse caption with caption "\t" .;
   show_children := 0;
   pic_index := 0;
   _TreeGetInfo(currIndex,show_children,pic_index);
   _str what_not_found = (pic_index == _pic_file)? "file":"tag";
   messageNwait("Could not find "what_not_found": "caption);
}

//////////////////////////////////////////////////////////////////////////////
// Preview the selected tab in the references tree
// 
static void refresh_references_preview(struct VS_TAG_BROWSE_INFO cm)
{
   if (ctlexpandbtn.p_value || ctlvexpandbtn.p_value) {

      // close the buffer which was previously open
      if (ctlrefedit.p_buf_id!=RefsEditWindowBufferID() &&
          ctlrefedit.p_buf_name!=cm.file_name &&
          (ctlrefedit.p_buf_flags&VSBUFFLAG_HIDDEN) &&
          _SafeToDeleteBuffer(ctlrefedit.p_buf_id,
                              ctlrefedit.p_window_id,
                              ctlrefedit.p_buf_flags)) {
         ctlrefedit.quit_file();
      }

      ctlrefedit.DisplayFile(cm);
      ctlrefedit.refresh('w');
   }
   cb_refresh_output_tab(cm, true, true, false, APF_REFERENCES);
}

//////////////////////////////////////////////////////////////////////////////
// This is the timer callback.  Whenever the current index (cursor position)
// for the reference tree is changed, a timer is started/reset.  If no
// activity occurs within a set amount of time, this function is called to
// update the properties view, inheritance view, and output window.
//
static void _RefListTimerCallback(_str FormAndIndex)
{
   // kill the timer
   refs_kill_selected_timer();

   parse FormAndIndex with auto sform_wid auto sindex;
   f := (int)sform_wid;
   if (!f || !_iswindow_valid(f) || f.p_name!=REFS_FORM_NAME_STRING) {
      return;
   }
   _nocheck _control ctlreferences;

   // get the current tree index
   currIndex := (int)sindex;
   if (currIndex <= 0) {
      currIndex = f.ctlreferences._TreeCurIndex();
   }
   if (currIndex<=0) {
      return;
   }

   // get the context information, push book mark, and open file to line
   if (f.ctlreferences.get_reference_tag_info(currIndex, auto cm, auto inst_id)) {
      if (cm.seekpos==null) {
         cm.seekpos=0;
      }

      // find the output tagwin and update it
      f.refresh_references_preview(cm);
      f.ctlreferences.SetRefInfoCaption(cm);

   } else {
      f.ctlreferences.message_cannot_find_ref(currIndex);
   }
}

static void _RefListHighlightCallback(_str FormAndIndex)
{
   // kill the timer
   refs_kill_highlight_timer();

   parse FormAndIndex with auto sform_wid auto sindex;
   f := (int)sform_wid;
   if (!f || !_iswindow_valid(f) || f.p_name!=REFS_FORM_NAME_STRING) {
      return;
   }
   _nocheck _control ctlreferences;

   // get the current tree index
   currIndex := (int)sindex;
   if (currIndex <= 0) {
      currIndex = f.ctlreferences._TreeCurIndex();
   }
   if (currIndex<=0 || !f.ctlreferences._TreeIndexIsValid(currIndex)) {
      return;
   }

   // get the context information, push book mark, and open file to line
   if (f.ctlreferences.get_reference_tag_info(currIndex, auto cm, auto inst_id)) {
      if (cm.seekpos==null) cm.seekpos=0;
      _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
   }
}

static void _RefListExpandingCallback(_str FormAndIndex)
{
   // make sure that the user isn't doing anything fun
   if (_idle_time_elapsed() < CB_TIMER_DELAY_MS) {
      return;
   }

   parse FormAndIndex with auto sform_wid auto sindex;
   f := (int)sform_wid;
   if (!f || !_iswindow_valid(f) || f.p_name!=REFS_FORM_NAME_STRING) {
      return;
   }
   _nocheck _control ctlreferences;

   f.ctlreferences.do_RefListExpandingCallback();
}
static void do_RefListExpandingCallback()
{
   // get the current tree index
   currIndex := _GetDialogInfoHt(REFS_EXPANDING_INDEX);
   if (currIndex == null || currIndex == 0) {
      // kill the timer
      refs_kill_expanding_timer();
      set_references_next_message();
      return;
   }
   if (currIndex < 0) {
      currIndex = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   }
   if (!_TreeIndexIsValid(currIndex)) {
      // kill the timer if the index is somehow invalid
      refs_kill_expanding_timer();
      set_references_next_message();
      return;
   }

   // Loop through references until we have spent too much time
   int expandedIndexes[];
   count := _GetDialogInfoHt(REFS_EXPANDING_COUNT);
   start_time := (long)_time('B');
   while (currIndex > 0) {
      if (_IsKeyPending(false)) {
         _SetDialogInfoHt(REFS_EXPANDING_STOPPED, true);
         break;
      }
      if (_TreeGetFirstChildIndex(currIndex) <= 0) {
         if (_chdebug) {
            say("do_RefListExpandingCallback: EXPANDING"_TreeGetCaption(currIndex));
         }
         _SetDialogInfoHt(REFS_EXPANDING_NOW, true);
         call_event(CHANGE_EXPANDED,currIndex,p_window_id,ON_CHANGE,'w');
         _TreeSetInfo(currIndex,1);
         count += _TreeGetNumChildren(currIndex);
         _SetDialogInfoHt(REFS_EXPANDING_INDEX, currIndex);
         _SetDialogInfoHt(REFS_EXPANDING_NOW, false);
         expandedIndexes :+= currIndex;
         if (count >= def_cb_max_references) {
            _SetDialogInfoHt(REFS_EXPANDING_STOPPED, true);
            break;
         }
         if ((long)_time('B') - start_time > CB_TIMER_DELAY_MS) {
            _SetDialogInfoHt(REFS_EXPANDING_INDEX, currIndex);
            _SetDialogInfoHt(REFS_EXPANDING_COUNT, count);
            // Clean up items that did not have any children
            foreach (auto index in expandedIndexes) {
               show_children := 0;
               _TreeGetInfo(index,show_children);
               if (show_children > 0 && _TreeGetFirstChildIndex(index) <= 0) {
                  if (currIndex == index) {
                     currIndex = _TreeGetNextSiblingIndex(index);
                     _SetDialogInfoHt(REFS_EXPANDING_INDEX, currIndex);
                  }
                  refs_kill_highlight_timer();
                  _TreeDelete(index);
               }
            }
            // And then return
            return;
         }
      }
      currIndex = _TreeGetNextSiblingIndex(currIndex);
   }

   // they hit escape, there still might be references out there...somewhere
   _SetDialogInfoHt(REFS_EXPANDING_INDEX, currIndex);
   _SetDialogInfoHt(REFS_EXPANDING_COUNT, count);
   if (currIndex > 0) {
      if (count == null || count == 0) {
         count = _TreeGetNumChildren(TREE_ROOT_INDEX);
         _SetDialogInfoHt(REFS_EXPANDING_COUNT, count);
      }
   } else {
      // go through the list and delete items with no references
      currIndex = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (currIndex > 0) {
         next := _TreeGetNextSiblingIndex(currIndex);
         show_children := 0;
         _TreeGetInfo(currIndex,show_children);
         if (show_children > 0 && _TreeGetFirstChildIndex(currIndex) <= 0) {
            refs_kill_highlight_timer();
            _TreeDelete(currIndex);
         }
         currIndex = next;
      }
   }

   clear_message();
   _TreeSizeColumnToContents(0);
   refs_kill_expanding_timer();
   set_references_next_message();
}

static int expandAllReferencesNow(_str symbolName)
{
   currIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (currIndex <= 0) {
      return currIndex;
   }

   // show progress form
   numFiles := _TreeGetNumChildren(TREE_ROOT_INDEX);
   progress_wid := 0;
   max_label2_width := 0;
   if (numFiles > 3) {
      progress_wid = _mdi.show_cancel_form("Expanding References to ":+symbolName,null,true,true);
      max_label2_width = cancel_form_max_label2_width(progress_wid);
      clear_message();
   }

   // Loop through references until we have spent too much time
   _SetDialogInfoHt(REFS_EXPANDING_NOW, true);
   _SetDialogInfoHt(REFS_EXPANDING_HASCANCEL, true);
   status := 0;
   numFilesDone := 0;
   numReferences := 0;
   int expandedIndexes[];
   while (currIndex > 0) {

      // check if this file was expanded already, if not, expand it
      if (_TreeGetFirstChildIndex(currIndex) <= 0) {
         currFile := _TreeGetCaption(currIndex);
         parse currFile with . "\t" currFile;
         if (_chdebug) {
            say("expandAllReferencesNow: EXPANDING" :+ currFile);
         }
         if (progress_wid && cancel_form_progress(progress_wid, numFilesDone, numFiles)) {
            currFile = progress_wid._ShrinkFilename(currFile, max_label2_width);
            cancel_form_set_labels(progress_wid,'Expanding 'numFilesDone'/'numFiles':', currFile);
         }

         call_event(CHANGE_EXPANDED,currIndex,p_window_id,ON_CHANGE,'w');
         _TreeSetInfo(currIndex,1);
         _SetDialogInfoHt(REFS_EXPANDING_INDEX, currIndex);
         expandedIndexes :+= currIndex;
         numReferences += _TreeGetNumChildren(currIndex);
         if (numReferences >= def_cb_max_references) {
            _SetDialogInfoHt(REFS_EXPANDING_STOPPED, true);
            status = TOO_MANY_FILES_RC;
            break;
         }
         if (progress_wid && cancel_form_cancelled()) {
            _SetDialogInfoHt(REFS_EXPANDING_STOPPED, true);
            status = COMMAND_CANCELLED_RC;
            break;
         }
      } else {
         _TreeGetInfo(currIndex, auto ShowChildren);
         if (ShowChildren <= 0) {
            _TreeSetInfo(currIndex,1);
         }
      }

      // next file please
      numFilesDone++;
      currIndex = _TreeGetNextSiblingIndex(currIndex);
   }

   // Clean up items that did not have any children
   foreach (auto index in expandedIndexes) {
      show_children := 0;
      _TreeGetInfo(index,show_children);
      if (show_children > 0 && _TreeGetFirstChildIndex(index) <= 0) {
         if (currIndex == index) {
            currIndex = _TreeGetNextSiblingIndex(index);
            _SetDialogInfoHt(REFS_EXPANDING_INDEX, currIndex);
         }
         refs_kill_highlight_timer();
         _TreeDelete(index);
      }
   }

   // they hit escape, there still might be references out there...somewhere
   _SetDialogInfoHt(REFS_EXPANDING_HASCANCEL, false);
   _SetDialogInfoHt(REFS_EXPANDING_NOW, false);
   _SetDialogInfoHt(REFS_EXPANDING_INDEX, currIndex);
   _SetDialogInfoHt(REFS_EXPANDING_COUNT, numReferences);
   clear_message();
   _TreeSizeColumnToContents(0);
   refs_kill_expanding_timer();
   set_references_next_message();
   refresh();

   // clean up progress form
   if (progress_wid) {
      close_cancel_form(progress_wid);
      // leave focus on the references tool window if they do not want
      // to jump ahead to the first reference
      if (def_references_options & VSREF_DO_NOT_GO_TO_FIRST) {
         ctlreferences._set_focus();
      } else {
         tag_refs_maybe_mdisetfocus(p_active_form);
      }
   }

   // could have error from cancellation or exceeding max number of references
   return status;
}

static void set_references_next_message()
{
   // set up find-next / find-prev
   set_find_next_msg("Find reference", _GetReferencesSymbolName());

   // information user how to get next reference
   bindings := "";
   text := "";
   if (def_mfflags & 1) {
      bindings=_mdi.p_child._where_is("find_next");
   } else {
      bindings=_mdi.p_child._where_is("next_error");
   }
   parse bindings with bindings ",";
   if (bindings!="") {
      text="Press "bindings:+" for next occurrence.";
   }
   sticky_message(text);
}

//////////////////////////////////////////////////////////////////////////////
// Handle on-change event for member list (a tree control) in inheritance
// tree dialog.  The only event handled is CHANGE_LEAF_ENTER, for which
// we utilize push_tag_in_file to push a bookmark and bring up the code in
// the editor.
//
void ctlreferences.on_change(int reason,int index)
{
   if ( !testFlag(p_window_flags, VSWFLAG_ON_CREATE_ALREADY_CALLED) ) {
      // If on_change() were to be called BEFORE on_create(), then bad
      // things ensue. Like the active editor window's buffer being
      // switched into the preview editor control and having p_tabs set!
      return;
   }
   if (reason == CHANGE_LEAF_ENTER) {
      // get the context information, push book mark, and open file to line
      if (ctlreferences.get_reference_tag_info(index, auto cm, auto inst_id)) {
         tagwin_goto_tag(cm.file_name,cm.line_no,cm.seekpos,cm.column_no,def_search_result_push_bookmark);
      } else {
         message_cannot_find_ref(index);
      }
      refs_kill_all_timers();
   } else if (reason == CHANGE_SELECTED) {
      if (_get_focus()==ctlreferences) {
         // kill the existing timer and start a new one
         refs_kill_selected_timer();
         refs_start_selected_timer(p_active_form,_RefListTimerCallback);
      }
   } else if (reason == CHANGE_EXPANDED) {
      if (ctlreferences._TreeGetDepth(index)==1) {
         cm := RefsTreeTagBrowseInfo();
         if (cm==null || !VF_IS_STRUCT(cm)) {
            return;
         }
         file_name := _TreeGetUserInfo(index);
         expandingHasCancel := _GetDialogInfoHt(REFS_EXPANDING_HASCANCEL);
         if (expandingHasCancel == null || expandingHasCancel == false) {
            message("Searching: '":+_strip_filename(file_name,'P'):+"' for references.  Press any key to stop.");
         }
         if (_chdebug) {
            say("ctlreferences.on_change: ===================================");
            say("ctlreferences.on_change: EXPANDING FILE:  "file_name);
            say("ctlreferences.on_change: ===================================");
         }
         //mou_hour_glass(true);
         count := 0;
         VS_TAG_RETURN_TYPE visited:[];
         VS_TAG_RETURN_TYPE (*pvisited):[];
         pvisited = _GetDialogInfoHtPtr(REFS_VISITED_KEY, _mdi);
         if (pvisited == null) {
            _SetDialogInfoHt(REFS_VISITED_KEY, visited, _mdi); 
            pvisited = _GetDialogInfoHtPtr(REFS_VISITED_KEY, _mdi);
         }
         if (pvisited == null) {
            pvisited = &visited;
         }

         // compute the boundaries of this local variable's enclosing function
         func_start_seekpos := func_end_seekpos := 0;
         refactor_get_symbol_scope(cm, func_start_seekpos, func_end_seekpos);

         // DJB (02-23-2006)
         // The begin/end update was causing a refresh issue and
         // isn't necessary anyway.
         // 
         //_TreeBeginUpdate(index);
         refs_kill_highlight_timer();
         _TreeDelete(index, 'C');
         cb_add_file_refs(file_name,cm,
                          RefsEditWindowTagTypeFilters(),
                          SE_TAG_CONTEXT_ALLOW_LOCALS,
                          index, 0, def_cb_max_references,
                          cm.member_name, false,
                          func_start_seekpos,func_end_seekpos,
                          *pvisited, 1);
         //_TreeEndUpdate(index);
         expandingNow := _GetDialogInfoHt(REFS_EXPANDING_NOW);
         if (expandingNow == null || expandingNow == false) {
            orig_caption := _TreeGetCaption(index);
            parse orig_caption with auto caption_filename "\t" auto caption_dir;
            parse caption_filename with caption_filename "...NO REFERENCES";
            tag_line := (_TreeGetFirstChildIndex(index) <= 0)? "...NO REFERENCES":"";
            _TreeSetCaption(index, caption_filename:+tag_line:+"\t":+caption_dir);
         }
         //mou_hour_glass(false);
      }
   }
}

void ctlreferences.on_highlight(int index, _str caption="")
{
   // kill the existing timer and start a new one
   refs_kill_highlight_timer();
   if (!def_tag_hover_preview) return;
   if (index < 0) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   refs_start_highlight_timer(p_active_form,_RefListHighlightCallback, index, def_tag_hover_delay);
}

//////////////////////////////////////////////////////////////////////////////
// Update other views when viewer gets focus, important because
// inheritance view, call tree, and props can also update the output
// view, so if they return focus to the references, we need to
// restart the update timer.
//
void ctlreferences.on_got_focus()
{
   // kill the existing timer and start a new one
   refs_kill_all_timers();
   set_references_next_message();
   refs_start_selected_timer(p_active_form,_RefListTimerCallback);
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Refresh the output symbols tab (peek-a-boo window)
// Returns 0 on success, nonzero if the search was terminated abnormally.
//
int refresh_references_tab(struct VS_TAG_BROWSE_INFO cm, bool find_all=false, _str ref_string="")
{
   f := _GetReferencesWID(true);
   if (!f) {
      return(1);
   }

   // update current item on references stack
   if ( !(def_references_options & VSREF_NO_AUTO_PUSH) ) {
      if (f.ctlrefname.p_text != "") {
         index := f.ctlreferences._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         if ( index > 0 ) f.push_references_stack(1);
      }
   }

   // if cm was passed in as null, then get information from last time
   _nocheck _control ctlreferences;
   if (cm==null) {
      cm = f.RefsTreeTagBrowseInfo();
   } else {
      ref_cm := f.RefsTreeTagBrowseInfo();
      if (!find_all && tag_browse_info_equal(cm,ref_cm)) {
         return(0);
      }

      tag_find_tag_line_in_tag_files(null, cm);
      f.RefsTreeTagBrowseInfo(cm);
   }
   if (cm==null || !VF_IS_STRUCT(cm)) {
      return(1);
   }

   // find the output tagwin and update it
   _nocheck _control ctlrefname;
   //_nocheck _control ctlrefedit;
   f.RefsTagNameLocation(cm.file_name "\t" cm.line_no);

   if (ref_string == "") {
      boring_cm := cm;
      if (cm.type_name=="tag" || cm.type_name=="taguse") {
         // html and xml handle this
      } else if (!tag_tree_type_is_func(cm.type_name)) {
         boring_cm.type_name = "var";
      }
      boring_cm.arguments="";
      boring_cm.flags = SE_TAG_FLAG_NULL;
      boring_cm.return_type="";
      boring_cm.template_args="";
      boring_cm.exceptions="";
      ref_string = extension_get_decl(cm.language, boring_cm, VSCODEHELPDCLFLAG_SHOW_CLASS);
   }
   if (ref_string != "") {
      f.ctlrefname.p_text = ref_string;
   } else if (cm.type_name == "") {
      f.ctlrefname.p_text = cm.member_name;
   } else if (cm.class_name == "") {
      f.ctlrefname.p_text = cm.member_name "(" cm.type_name ")";
   } else {
      f.ctlrefname.p_text = cm.member_name "(" cm.class_name ":" cm.type_name ")";
   }

   // compute language case sensitivity
   case_sensitive := true;
   if (_isEditorCtl()) {
      case_sensitive=p_EmbeddedCaseSensitive;
   } else if (cm.file_name) {
      int temp_view_id,orig_view_id;
      inmem := false;
      status := _open_temp_view(cm.file_name,temp_view_id,orig_view_id,"",inmem,false,true);
      if (!status) {
         case_sensitive=p_EmbeddedCaseSensitive;
         _delete_temp_view(temp_view_id);
         p_window_id=orig_view_id;
      }
   }

   // clear old references, or set up the marker type for this set of references
   if (def_references_options & VSREF_NO_AUTO_PUSH) {
      tag_refs_clear_pics();
   } else {
      if (f.num_references_stack_items() > 0) {
         next_pic_type := f.next_references_marker_type();
         f.RefsEditWindowPicType(next_pic_type);
      }
   }

   terminated_early := false;
   _SetDialogInfoHt(REFS_VISITED_KEY, null, _mdi); 
   f.ctlreferences._TreeDelete(TREE_ROOT_INDEX,'C');
   f.refresh_references_view(cm, terminated_early,
                             (_isEditorCtl()? p_buf_name:null), case_sensitive);

   if (cm.file_name!=null && cm.file_name!="") {
      if (cm.line_no == null) {
         cm.line_no=1;
      }
      if (!_QBinaryLoadTagsSupported(cm.file_name)) {
         //f.ctlrefedit.DisplayFile(cm.file_name,cm.line_no,0,cm.column_no);
         f.ctlreferences.SetRefInfoCaption(cm);
         f.refresh_references_preview(cm);
      }
   }
   stopped := f.ctlreferences._GetDialogInfoHt(REFS_EXPANDING_STOPPED);
   if (stopped != null && stopped != false) {
      terminated_early=true;
   }
   if (terminated_early) {
      f.ctlreflabel.p_caption=nls("WARNING: The references search results were truncated.");
      //f.ctlreflabel.p_width=f.ctlreflabel._text_width(f.ctlreflabel.p_caption);
   }

   f.ctlreferences._TreeTop();
   f.ctlreferences._TreeRefresh();

   // automatically push references stack
   if ( !terminated_early && !(def_references_options & VSREF_NO_AUTO_PUSH) ) {
      f.push_references_stack(1);
   }

   return (int)(terminated_early);
}

bool tag_refs_clear_editor(int buf_id)
{
   f := _GetReferencesWID();
   if (!f) return false;

   if (f.ctlrefedit.p_buf_id != buf_id) {
      return false;
   }

   f.ctlrefedit.load_files("+q +m +bi ":+f.RefsEditWindowBufferID());
   return true;
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Find the next/previous reference
//
static int next_prev_ref_in_tree(int direction, bool quiet=false)
{
   index := 0;
   for (;;) {
      index = _TreeCurIndex();
      if (index < 0) {
         break;
      }
      show_children := 0;
      _TreeGetInfo(index,show_children);
      if (_TreeGetDepth(index)==1 && show_children==0) {
         _TreeSetInfo(index,1);
         if (_TreeGetNumChildren(index)==0) {
            call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');
            if (_TreeGetNumChildren(index)==0) {
               next_index := _TreeGetNextSiblingIndex(index);
               _TreeDelete(index);
               if (next_index <= 0) {
                  index=0;
                  break;
               }
               _TreeSetCurIndex(next_index);
            }
         }
         continue;
      }
      status := 0;
      if (direction > 0) {
         status=_TreeDown();
      } else if (direction < 0) {
         status=_TreeUp();
      } else {
         break;
      }
      if (status) {
         index=0;
         break;
      }
      index = _TreeCurIndex();
      if (index <= 0) {
         break;
      }
      _TreeGetInfo(index,show_children);
      if (_TreeGetDepth(index)==1 && show_children==0 && _TreeGetNumChildren(index)==0) {
         continue;
      }
      if (_TreeGetDepth(index)==2) {
         _TreeUp();
         _TreeDown();
         break;
      }
   }
   return index;
}
//////////////////////////////////////////////////////////////////////////////
// preview next/previous reference, please
//
static int next_prev_ref(int direction, bool preview_only=true, bool quiet=false, bool first_ref_search=false)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   f := _GetReferencesWID();
   if (!f) {
      return 0;
   }

   // find the output tagwin and update it
   _nocheck _control ctlreferences;
   //_nocheck _control ctlrefedit;

   index := f.ctlreferences.next_prev_ref_in_tree(direction, quiet);
   f.ctlreferences.get_reference_tag_info(index, auto cm, auto inst_id);
   if (index > 0 && cm.file_name!=null && cm.file_name!="") {
      if (cm.line_no == null) {
         cm.line_no=1;
      }
      //f.ctlrefedit.DisplayFile(cm.file_name,cm.line_no,0,cm.column_no);
      f.ctlreferences._TreeRefresh();
      f.ctlreferences.SetRefInfoCaption(cm);
      f.refresh_references_preview(cm);
   } else {
      if ( direction > 0 && !(def_references_options & VSREF_NO_AUTO_FINISH) && !first_ref_search ) {
         buttons := f.references_stack_buttons();
         num_stack_items := f.num_references_stack_items(buttons);
         cur_stack_item  := f.current_references_stack_item(buttons);
         if ( num_stack_items > 0 && cur_stack_item == num_stack_items-1 && direction > 0 ) {
            status := _message_box("No more references, pop from stack?", "SlickEdit", MB_YESNO);
            if (status == IDYES) f.pop_references_stack();
         }
      } else if (!quiet) {
         _message_box("No more references.");
      }
      f.ctlreferences._TreeRefresh();
      return NO_MORE_FILES_RC;
   }

   if (!preview_only) {
      tagwin_goto_tag(cm.file_name,cm.line_no,cm.seekpos,cm.column_no,false);
   }

   return 0;
}

/**
 * Repositions the cursor on the next item in the references tool 
 * window. If window is not active, it will do a prev-ref, followed by a
 * next-ref to attempt to reposition on the current match. 
 * 
 * @param preview_only  If true, show the reference only in the preview 
 *                      pane of the references tool window.
 * @param quiet         If true, do not display message box when there 
 *                      are no more references.
 * 
 * @return Returns 0 if successful.  
 *         Otherwise NO_MORE_FILES_RC is returned. On error, message is
 *         displayed.
 * 
 * @see prev_ref
 * @see find
 * @see replace
 * @see gui_replace
 * @see gui_find
 * @see find_current
 * @see find_prev
 * @see find_next
 * 
 * @appliesTo Edit_Window,Editor_Control
 * @categories Editor_Control_Methods, Edit_Window_Methods, Search_Functions
 */
_command int next_ref(bool preview_only=true,bool quiet=false, bool first_ref_search=false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   return next_prev_ref(1,preview_only,quiet,first_ref_search);
}
int _OnUpdate_next_ref(CMDUI& cmdui, int target_wid, _str command)
{
   return _OnUpdate_refs_expand_all(cmdui, target_wid, command);
}

/**
 * <p>Repositions the cursor on the previous item in the references tool
 * window. If window is not active, it will do a next-ref, followed by a
 * prev-ref to attempt to reposition on the current match. 
 * 
 * @param preview_only  If true, show the reference only in the preview 
 *                      pane of the references tool window.
 * @param quiet         If true, do not display message box when there 
 *                      are no more references.
 * 
 * @return Returns 0 if successful.  
 *         Otherwise NO_MORE_FILES_RC is returned. On error, message is
 *         displayed.
 * 
 * @see next_ref
 * @see find
 * @see replace
 * @see gui_replace
 * @see gui_find
 * @see find_current
 * @see find_prev
 * @see find_next
 * 
 * @appliesTo Edit_Window,Editor_Control
 * @categories Editor_Control_Methods, Edit_Window_Methods, Search_Functions
 */
_command int prev_ref(bool preview_only=true,bool quiet=false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   return next_prev_ref(-1,preview_only,quiet);
}
int _OnUpdate_prev_ref(CMDUI& cmdui, int target_wid, _str command)
{
   return _OnUpdate_refs_expand_all(cmdui, target_wid, command);
}

/**
 * <p>Repositions the cursor on the current item in the references tool
 * window. If window is not active, it will do a next-ref, followed by a
 * prev-ref to attempt to reposition on the current match. 
 * 
 * @param preview_only  If true, show the reference only in the preview 
 *                      pane of the references tool window.
 * @param quiet         If true, do not display message box when there 
 *                      are no more references.
 * 
 * @return Returns 0 if successful.  
 *         Otherwise NO_MORE_FILES_RC is returned. On error, message is
 *         displayed.
 *  
 * @see find_refs 
 * @see next_ref
 * @see prev_ref
 * @see find
 * @see replace
 * @see gui_replace
 * @see gui_find
 * @see find_current
 * @see find_prev
 * @see find_next
 * 
 * @appliesTo Edit_Window,Editor_Control
 * @categories Editor_Control_Methods, Edit_Window_Methods, Search_Functions
 */
_command int current_ref(bool preview_only=true,bool quiet=false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   return next_prev_ref(0,preview_only,quiet);
}
int _OnUpdate_current_ref(CMDUI& cmdui, int target_wid, _str command)
{
   return _OnUpdate_refs_expand_all(cmdui, target_wid, command);
}

/**
 * Activate the References tool window and initialize it with the 
 * expression under the cursor. 
 *  
 * @param exp   [optional] expression to seed References tool window with
 *  
 * @see push_tag 
 * @see push_ref
 * @see activate_references
 * 
 * @categories Tagging_Functions
 */
_command activate_references_with_curexp(_str exp="")  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Find References");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   editorctl_wid := 0;
   if (_isEditorCtl()) {
      editorctl_wid = p_window_id;
   } else if (!_no_child_windows()) {
      editorctl_wid = _mdi.p_child;
   }
   if (exp != "") {
      gFindReferencesExpression = exp;
   } else if (editorctl_wid != 0) {
      // get the expression to evaluate
      VS_TAG_IDEXP_INFO idexp_info;
      tag_idexp_info_init(idexp_info);
      struct VS_TAG_RETURN_TYPE visited:[];
      status := editorctl_wid._Embeddedget_expression_info(false, auto lang, idexp_info, visited);
      if (status == 0) {
         gFindReferencesExpression = idexp_info.prefixexp:+idexp_info.lastid;
      }
   }

   return activate_references();
}

/**
 * Activate the References tool window and initialize it with the 
 * identifier under the cursor. 
 *  
 * @param id   [optional] identifier to seed References tool window with
 *  
 * @see push_tag 
 * @see push_ref 
 * @see activate_references
 * 
 * @categories Tagging_Functions
 */
_command activate_references_with_identifier(_str id="")  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Find References");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   editorctl_wid := 0;
   if (_isEditorCtl()) {
      editorctl_wid = p_window_id;
   } else if (!_no_child_windows()) {
      editorctl_wid = _mdi.p_child;
   }
   gFindReferencesExpression = (id != "")? id : editorctl_wid.cur_identifier(auto start_col);

   return activate_references();
}

int _MaybeRetagOccurrences(_str curr_tag_file="")
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // if there is a BSC file, then bail out
   if (refs_filename() != "") {
      return 0;
   }

   // set up array of two tag files
   _str wst_filename = _GetWorkspaceTagsFilename();
   _str tag_files[]; tag_files._makeempty();
   if (wst_filename != "") {
      // make sure that the project involves the current extension
      if (tag_read_db(wst_filename) >= 0) {
         if (!_isEditorCtl() || tag_find_language(auto dummy_lang,p_LangId)==0) {
            tag_files[tag_files._length()]=wst_filename;
         }
         tag_reset_find_language();
      }
   }
   if (curr_tag_file != "") {
      tag_files[tag_files._length()]=curr_tag_file;
   } else if (_isEditorCtl() && _LanguageInheritsFrom("e")) {
      // extension specific tag file, not in project
      _str ext_tag_files[];
      ext_tag_files = tags_filenamea(p_LangId);
      if (ext_tag_files._length() >= 1 && ext_tag_files[0]!=wst_filename) {
         tag_files[tag_files._length()] = ext_tag_files[0];
      }
   }

   status := result := i := 0;
   _str tag_filename = next_tag_filea(tag_files, i, false, true);
   while (tag_filename != "") {

      // already have occurrences
      int db_flags = tag_get_db_flags();
      if (!(db_flags & VS_DBFLAG_occurrences)) {

         // no occurrences, ask if we should build them now
         status=_message_box(nls("Do you want to build a symbol cross-reference for '%s'?\nThis may take several minutes.",tag_filename),"",MB_YESNOCANCEL|MB_ICONQUESTION);
         if (status==IDYES || status==IDOK) {
            // build the cross-reference
            mou_hour_glass(true);
            status = RetagFilesInTagFile(tag_filename,true,true,false,false,true);
            mou_hour_glass(false);
            if (status) {
               result = status;
            }
         } else if (status==IDNO) {
            // do nothing
         } else {
            // that's all
            return(COMMAND_CANCELLED_RC);
         }
      }

      // next please...
      tag_filename = next_tag_filea(tag_files, i, false, true);
   }

   // that's all folks
   return result;
}

static void tag_refs_clear_refs_and_preview()
{
   if (RefsEditWindowBufferID() != ctlrefedit.p_buf_id) {
      if (ctlrefedit.p_buf_flags & VSBUFFLAG_HIDDEN) {
         if (_SafeToDeleteBuffer(ctlrefedit.p_buf_id,
                                 ctlrefedit.p_window_id,
                                 ctlrefedit.p_buf_flags)
             ) {
            ctlrefedit.quit_file();
         }
      }
      ctlrefedit.load_files("+q +m +bi ":+RefsEditWindowBufferID());
   }
   ctlreferences._TreeDelete(TREE_ROOT_INDEX,'C');
   ctlreflabel.p_caption="";
   ctlrefname.p_text="";
}

void _prjclose_tagrefs(bool singleFileProject)
{
   if (singleFileProject) return;
   refs_kill_all_timers();
   f := _GetReferencesWID();
   if (!f) return;

   last := _last_window_id();
   for (i:=1; i<=last; ++i) {
      if (_iswindow_valid(i) && i.p_object == OI_FORM && !i.p_edit) {
         if (i.p_name:==REFS_FORM_NAME_STRING) {
            i.tag_refs_clear_refs_and_preview();
         }
      }
   }

   clear_references_stack();
   _SetDialogInfoHt(REFS_VISITED_KEY, null, _mdi); 
   _mfrefNoMore(1);
}

int toolShowReferences()
{
   index := find_index("_refswindow_Activate",PROC_TYPE);
   if( index_callable(index) ) {
      return (call_index(index));
   }
   return activate_tool_window(REFS_FORM_NAME_STRING, true, "ctlreferences");
}

///////////////////////////////////////////////////////////////////////////////
// For saving and restoring the state of the references tool window
// when the user undocks, pins, unpins, or redocks the window.
//
struct REFERENCES_WINDOW_STATE {
   typeless nodes;
   _str symbolName;
   _str lookinOption;
   int colWidth;
   typeless stack[];
   int curStackItem;
   VS_TAG_BROWSE_INFO tagInfo;
   _str bookmarkId;
   _str messageLine;
   int  markerType;
   TagAssignmentFilterFlags assignmentsFilter;
   TagConstFilterFlags      constFilter;
   int                      typeFilterFlags;
};
void _twSaveState__tbtagrefs_form(REFERENCES_WINDOW_STATE& state, bool closing)
{
   //if( closing ) {
   //   return;
   //}
   state.colWidth=ctlreferences._TreeColWidth(0);
   state.symbolName=ctlrefname.p_text;
   state.tagInfo=RefsTreeTagBrowseInfo();
   state.markerType=RefsEditWindowPicType();
   state.lookinOption=ctllookin.p_text;
   state.messageLine=ctlreflabel.p_caption;
   state.typeFilterFlags = RefsEditWindowTagTypeFilters();
   refs_get_filter_options(state.assignmentsFilter, state.constFilter);
   ctlreferences._TreeSaveNodes(state.nodes);

   buttons := references_stack_buttons();
   state.curStackItem = current_references_stack_item(buttons);
   for ( i:=0; i<buttons._length(); i++ ) {
      CTL_IMAGE btn = buttons[i];
      if (!btn.p_visible || !btn.p_enabled || btn.p_user == null || !(btn.p_user instanceof REFERENCES_WINDOW_STATE)) break;

      state.stack[i] = btn.p_user;
   }

   if (gReferencesSelectedTimerId == -1) {
      refs_start_selected_timer(_GetReferencesWID(),_RefListTimerCallback);
   }
}
void _twRestoreState__tbtagrefs_form(REFERENCES_WINDOW_STATE& state, bool opening)
{
   //if( opening ) {
   //   return;
   //}
   if (state == null) return;
   ctlrefname.p_text=state.symbolName;
   ctllookin.p_text=state.lookinOption;
   ctlreflabel.p_caption=state.messageLine;

   // update filter options
   RefsEditWindowTagTypeFilters(state.typeFilterFlags);
   refs_set_filter_options(state.assignmentsFilter, state.constFilter);
   refs_update_show_all_check_box();

   RefsTreeTagBrowseInfo(state.tagInfo);
   RefsEditWindowPicType(state.markerType);
   ctlreferences._TreeDelete(TREE_ROOT_INDEX, 'C');
   ctlreferences._TreeRestoreNodes(state.nodes);
   ctlreferences._TreeColWidth(0,state.colWidth);

   // set up the stack buttons
   buttons := references_stack_buttons(visibleOnly:false);
   if ( state.curStackItem > state.stack._length() ) state.curStackItem = state.stack._length();
   enable_disable_stack_buttons(state.stack._length(),state.curStackItem,buttons);

   // restore references stack
   for ( i:=0; i<buttons._length() && i<state.stack._length(); i++ ) {
      buttons[i].p_user = state.stack[i];
   }
}

static void tbtagrefs_form_save_current_state(REFERENCES_WINDOW_STATE& state)
{
   state.colWidth=ctlreferences._TreeColWidth(0);
   state.symbolName=ctlrefname.p_text;
   state.tagInfo=RefsTreeTagBrowseInfo();
   state.markerType=RefsEditWindowPicType();
   state.lookinOption=ctllookin.p_text;
   state.messageLine=ctlreflabel.p_caption;
   state.typeFilterFlags = RefsEditWindowTagTypeFilters();
   refs_get_filter_options(state.assignmentsFilter, state.constFilter);
   ctlreferences._TreeSaveNodes(state.nodes);
}
static void tbtagrefs_form_restore_current_state(REFERENCES_WINDOW_STATE& state)
{
   if (state == null) return;
   ctlrefname.p_text=state.symbolName;
   ctllookin.p_text=state.lookinOption;
   ctlreflabel.p_caption=state.messageLine;

   // update filter options
   RefsEditWindowTagTypeFilters(state.typeFilterFlags);
   refs_set_filter_options(state.assignmentsFilter, state.constFilter);
   refs_update_show_all_check_box();

   RefsTreeTagBrowseInfo(state.tagInfo);
   RefsEditWindowPicType(state.markerType);
   ctlreferences._TreeDelete(TREE_ROOT_INDEX, 'C');
   ctlreferences._TreeRestoreNodes(state.nodes);
   ctlreferences._TreeColWidth(0,state.colWidth);
   ctlreferences._TreeSizeColumnToContents(0);
}

void tbtagrefs_copy_to_search_results(int grep_id = 0)
{
   se.search.SearchResults results;
   symbol_name := strip(ctlrefname.p_text);
   line := 'References "':+symbol_name:+'"';
   results.initialize(line, "<References>", 0, grep_id);
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   num_files := 0;
   num_refs := 0;
   while (index > 0) {
      filename := _TreeGetUserInfo(index);
      results.insertFileLine(filename, false);
      j := _TreeGetFirstChildIndex(index);
      while (j > 0) {
         caption := " ":+_TreeGetCaption(j);
         ucm := _TreeGetUserInfo(j);
         ref_parse_reference_info(ucm, auto line_no, auto inst_id, auto seekpos, auto column_no, auto tag_database, auto streamMarkerId, auto tag_type, auto tag_flags);
         results.insertResult(line_no, column_no, caption);
         j = _TreeGetNextSiblingIndex(j);
         num_refs++;
      }
      index = _TreeGetNextSiblingIndex(index);
      num_files++;
   }
   text := "Total references: ":+num_refs:+"     Total files: ":+num_files;
   results.done(text);
   results.showResults();
   _mfrefIsActive=false;
}

void refs_push_list_of_symbols(_str search_text, 
                               _str search_opts,
                               _str look_in, 
                               VS_TAG_BROWSE_INFO (&tagInfoList)[])
{
   // If form already exists, reuse it.  Otherwise, create it
   refs_form_wid := _GetReferencesWID();
   if (!refs_form_wid) {
      _ActivateReferencesWindow();
      refs_form_wid = _GetReferencesWID();
      if (!refs_form_wid) return;
   }

   VS_TAG_BROWSE_INFO cm;
   VS_TAG_BROWSE_INFO tagInfoArray[];
   VS_TAG_BROWSE_INFO tagInfoByFileName:[][];
   foreach (cm in tagInfoList) {
      orig_name_seekpos := cm.name_seekpos;
      tag_complete_browse_info(cm);
      if (orig_name_seekpos > 0) cm.name_seekpos = orig_name_seekpos;
      cased_file := _file_case(cm.file_name);
      if (tagInfoByFileName._indexin(cased_file)) {
         tagInfoArray = tagInfoByFileName:[cased_file];
      } else {
         tagInfoArray._makeempty();
      }
      tagInfoArray :+= cm;
      tagInfoByFileName:[cased_file] = tagInfoArray;
   }

   refs_form_wid.refs_kill_all_timers();
   refs_form_wid.push_references_stack(caption: "Symbols matching '":+search_text:+"'");

   tree_wid := refs_form_wid.ctlreferences.p_window_id;
   tree_wid._TreeDelete(TREE_ROOT_INDEX, 'C');
   gFindReferencesExpression = "";
   refs_form_wid.ctlrefname._cbset_text(search_text);

   foreach (tagInfoArray in tagInfoByFileName) {
      file_name := tagInfoArray[0].file_name;
      base_name := _strip_filename(file_name, 'P');
      file_index := tree_wid._TreeAddItem(TREE_ROOT_INDEX,
                                          base_name:+"\t":+file_name,
                                          TREE_ADD_SORTED_FILENAME|TREE_ADD_AS_CHILD,
                                          _pic_file,_pic_file,
                                          TREE_NODE_EXPANDED,0,
                                          file_name);

      tagInfoArray._sort('', 0, -1, tag_browse_info_compare_locations);

      foreach (cm in tagInfoArray) {
         ucm := ref_create_reference_info(cm.line_no, 0, cm.name_seekpos, 0, cm.tag_database, 0, cm.type_name, cm.flags);
         cap := tag_make_caption_from_browse_info(cm, include_class:true, include_args:true, include_tab:true);
         pic := tag_get_bitmap_for_type(tag_get_type_id(cm.type_name), cm.flags, auto ovl);
         tree_wid._TreeAddItem(file_index, cap, TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1, pic, ovl, TREE_NODE_LEAF, 0, ucm);
      }

      // open a temporary view of 'file_name'
      status := _open_temp_view(file_name,auto temp_view_id,auto orig_view_id,"",auto inmem,false,true);
      if (!status) {
         refs_form_wid.tag_refs_create_pics_for_file(tree_wid, file_index, file_name, search_text, search_opts, temp_view_id);
         _delete_temp_view(temp_view_id);
         p_window_id=orig_view_id;
      }
   }

   tree_wid._TreeColWidth(0,0);
   tree_wid._TreeSizeColumnToContents(0);
   tree_wid._TreeTop();
   tree_wid._TreeRefresh();
   _mfrefIsActive=true;
   //mdisetfocus();
}



/**
 * Save the references in the current file, optionally restricting 
 * to a range of lines, and saving relocation information.
 * <p> 
 * This function is used to save reference information before we do 
 * something that heavily modifies a buffer, such as refactoring, 
 * beautification, or auto-reload.  It uses the relocatable marker 
 * information to attempt to restore the references back to their 
 * original line, even if the actual line number has changed because 
 * lines were inserted or deleted. 
 * 
 * @param referenceSaves   Saved references           
 * @param startRLine       First line in region to save
 * @param endRLine         Last line in region to save
 * @param relocatable      Save relocation marker information? 
 *  
 * @see _RestoreReferencesInFile 
 * @categories Tagging_Functions 
 */
void _SaveReferencesInFile(ReferenceSaveInfo (&referenceSaves)[],
                           int startRLine=0, int endRLine=0,
                           bool relocatable=true)
{
   if (!_haveContextTagging()) {
      return;
   }
   if (!_isEditorCtl()) {
      return;
   }

   // clear the list
   referenceSaves._makeempty();

   // determine the start and end offsets
   startROffset := 0L;
   endROffset   := (long) p_buf_size;
   save_pos(auto p);
   if (startRLine) {
      p_RLine = startRLine;
      _begin_line();
      startROffset = _QROffset();
   }
   if (endRLine) {
      p_RLine = endRLine;
      _end_line();
      endROffset = _QROffset();
   }

   // For each reference type, save the ones that are in the current
   // file and within the specified region
   for (i:=0; i<gref_pic_types._length(); i++) {
      pic_type := gref_pic_types[i];
      if (pic_type <= 0) continue;

      // find all the stream marks in the file for this type
      _StreamMarkerFindList(auto refsInFile, p_window_id, startROffset, endROffset-startROffset+1, startROffset-100, pic_type);

      // collect the information
      foreach (auto refId in refsInFile) {
         _StreamMarkerGet(refId, auto refInfo);
         ReferenceSaveInfo r;
         r.ref_id      = refId;
         //r.pic_to_use  = refInfo.BMIndex;
         //r.ref_message = refInfo.msg;
         r.ref_seekpos = refInfo.StartOffset;
         r.ref_len     = (int)refInfo.Length;
         //r.pic_type    = pic_type;

         _GoToROffset(refInfo.StartOffset);
         r.ref_line_no = p_RLine;
         r.ref_column  = p_col;
         r.ref_name    = get_text(r.ref_len);
         r.relocationInfo = null;
         if (relocatable) {
            _BuildRelocatableMarker(r.relocationInfo);
         }

         // add this stream marker to the list
         referenceSaves :+= r;
      }
   }

   // get back to where you once belonged
   restore_pos(p);
}

/**
 * Restore saved references from the current file and relocate them
 * if the reference information includes relocation information. 
 * 
 * @param referenceSaves   Saved references           
 * @param adjustLinesBy    Number of lines to adjust start line by
 *  
 * @see _SaveReferencesInFile 
 * @categories Tagging_Functions 
 */
void _RestoreReferencesInFile(ReferenceSaveInfo (&referenceSaves)[], int adjustLinesBy=0)
{
   if (!_haveContextTagging()) {
      return;
   }
   if (!_isEditorCtl()) {
      return;
   }

   resetTokens := true;
   save_pos(auto p);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   foreach (auto r in referenceSaves) {

      // adjust the start line if we were asked to
      if (adjustLinesBy && r.ref_line_no + adjustLinesBy > 0) {
         r.ref_line_no += adjustLinesBy;
         if (r.relocationInfo != null) {
            r.relocationInfo.origLineNumber += adjustLinesBy;
         }
      }

      // relocate the marker, presuming the file has changed
      origRLine := r.ref_line_no;
      if (r.relocationInfo != null) {
         origRLine = _RelocateMarker(r.relocationInfo, resetTokens);
         resetTokens = false;
         if (origRLine < 0) {
            origRLine = r.relocationInfo.origLineNumber;
         }
      }

      // Move the stream marker where we need it.
      p_RLine = origRLine;
      _begin_line();

      // try to find the symbol on the line again
      nearest_col := 0;
      if (!search(_escape_re_chars(r.ref_name):+"|$", 'rh@')) {
         do {
            if (p_RLine > origRLine) {
               break;
            }
            if (nearest_col != 0 && p_col - r.ref_column > abs(nearest_col - r.ref_column)) {
               break;
            }
            if (get_text(r.ref_len) != r.ref_name) {
               break;
            }
            if (!nearest_col || abs(p_col - r.ref_column) < abs(nearest_col - r.ref_column)) {
               nearest_col = p_col;
            }
         } while (repeat_search('rh@'));
      }
      p_RLine = origRLine;
      if (nearest_col) {
         p_col = nearest_col;
      } else {                      
         p_col = r.ref_column;
      }

      // final step, update the offset of the stream marker
      _StreamMarkerSetStartOffset(r.ref_id, _QROffset());
      _StreamMarkerSetLength(r.ref_id, r.ref_len);
   }

   restore_search(s1, s2, s3, s4, s5);
   restore_pos(p);
}

