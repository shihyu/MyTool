////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49817 $
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
#import "cbrowser.e"
#import "context.e"
#import "eclipse.e"
#import "files.e"
#import "ini.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "mfsearch.e"
#import "mouse.e"
#import "picture.e"
#import "projconv.e"
#import "pushtag.e"
#import "quickrefactor.e"
#import "saveload.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagfind.e"
#import "tagform.e"
#import "tags.e"
#import "tagwin.e"
#import "toolbar.e"
#import "treeview.e"
#import "window.e"
#import "wkspace.e"
#endregion


#define REFS_WINDOW_BUFFER_NAME  ".References Window Buffer"
#define REFS_FORM_NAME_STRING    "_tbtagrefs_form"
#define REFS_VISITED_KEY         "REFERENCES_VISITED"

//////////////////////////////////////////////////////////////////////////////
// Timer used for delaying updates after change-selected events,
// allowing you to quickly scroll through the items in the references.
// It is safer for this to global instead of static.
//
#define CB_TIMER_DELAY_MS 200
static int gReferencesSelectedTimerId=-1;
static int gReferencesHighlightTimerId=-1;

// Bitmaps for symbol references and search results
int gref_pic_type=-1;
int _pic_editor_reference=0;
int _pic_editor_search=0;


definit()
{
   if (arg(1)!='L') {
      gReferencesSelectedTimerId=-1;
      gReferencesHighlightTimerId=-1;
      gref_pic_type=-1;
   }
}

// This is window that displays the 
// location of a set of symbol references
defeventtab _tbtagrefs_form;

_tbtagrefs_form.'F12'()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   } else if (def_keys == 'eclipse-keys') {
      activate_editor();
   }
}

_tbtagrefs_form.'C-S-PAD-SLASH'()
{
   if (isEclipsePlugin() || def_keys == 'eclipse-keys') {
      refs_crunch();
   }
}

_tbtagrefs_form.'C-M'()
{
   if (isEclipsePlugin()) {
      eclipse_maximize_part();
   }
}

_command refs_crunch() name_info(','VSARG2_EDITORCTL)
{
   int f = _GetReferencesWID();
   if (!f) {
      messageNwait("_tbtagrefs_form" nls("not found"));
      return('');
   }

   _nocheck _control ctlreferences;

   mou_hour_glass(1);
   int j = f.ctlreferences._TreeGetFirstChildIndex(0);
   while (j > 0) {
      int show_children=0;
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
   mou_hour_glass(0);
}

int _ActivateReferencesWindow()
{
   int index = find_index('_refswindow_Activate',PROC_TYPE);
   if( index_callable(index) ) {
      return (call_index(index));
   }
   return (activate_toolbar("_tbtagrefs_form",""));
}

//Need to be able to call this from proctree.e and cbrowser.e
int _GetReferencesWID(boolean only_when_active=false)
{
   if (isEclipsePlugin()) {
      int formWid = _find_object(ECLIPSE_REFERENCESOUTPUT_CONTAINERFORM_NAME,'n');
      if (formWid > 0) {
         return formWid.p_child;
      }
      return 0;
   } else {
      int wid = 0;
      static int LastFormWID;
      if( _iswindow_valid(LastFormWID) &&
          LastFormWID.p_object==OI_FORM &&
          LastFormWID.p_name==REFS_FORM_NAME_STRING &&
          !LastFormWID.p_edit ){
   
         wid=LastFormWID;
      } else {
         wid=_find_formobj(REFS_FORM_NAME_STRING,'n');
         LastFormWID=wid;
      }
      // check if the tagwin is the active tab
      if( wid && only_when_active ) {
         if( !_tbIsWidActive(wid) || !wid.p_enabled ) {
            return 0;
         }                  
      }
      return wid;
   }
}

// Get current symbol name in references window
_str _GetReferencesSymbolName()
{
   int window_id = _GetReferencesWID();
   if (window_id) {
      int control_id = window_id._find_control('ctlrefname');
      if (control_id) {
         if ((control_id.p_object == OI_COMBO_BOX) || (control_id.p_object == OI_TEXT_BOX)) {
            return control_id.p_text;
         }
      }
   }
   return '';
}

#define RefsEditWindowBufferID ctlrefedit.p_user
#define RefsFilenameTagIsIn    ctlreflabel.p_user

/**
 * Set focus on the editor.  This command can be useful when
 * you are trying to control an instance of SlickEdit from
 * another application or using {@link dde} and you need to
 * transfer focus to the editor to complete an operation.
 * 
 * @categories Miscellaneous_Functions
 */
_command void mdisetfocus() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI)
{
   if (!_no_child_windows()) {
      _mdi.p_child._set_focus();
   } else {
      _mdi._set_focus();
   }
}

void _tbtagrefs_form.on_destroy()
{
   // save the position of the sizing bar
   _append_retrieve(0,ctldivider.p_user,"_tbtagrefs_form.ctldivider.p_x");

   // save whether or not the preview pane is hidden
   _append_retrieve(0,ctlexpandbtn.p_value,"_tbtagrefs_form.ctlexpandbtn.p_value");

   // clear out the references window
   if ( RefsEditWindowBufferID != ctlrefedit.p_buf_id ) {
      if (ctlrefedit.p_buf_flags & VSBUFFLAG_HIDDEN) {
         if (_SafeToDeleteBuffer(ctlrefedit.p_buf_id, ctlrefedit.p_window_id, ctlrefedit.p_buf_flags)) {
            ctlrefedit.quit_file();
         }
      }
      ctlrefedit.load_files('+q +m +bi 'RefsEditWindowBufferID);
   }
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
   int itemNumber = 0;
   int itemCount = 0;
   int fileCount  = 0;
   int fileNumber = 0;

   // get the current tree index and line number
   int index = _TreeCurIndex();
   int parentIndex = index;
   if (_TreeGetDepth(index) == 2) {
      parentIndex = _TreeGetParentIndex(index);
   }
   typeless ds,dn,dc,df;
   _TreeGetInfo(index,ds,dn,dc,df,itemNumber,0);
   itemNumber = (itemNumber < 0)? 0:itemNumber;

   // if expanding incrementally, are there still unexpanded nodes?
   boolean unExpandedNodes = false;

   // for each file in the list
   int i = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (i > 0) {
      // get the number of references under this file
      int childCount=_TreeGetNumChildren(i);
      itemCount+=childCount;
      // if zero, check if this node is unexpanded
      if (!childCount) {
         int show_children=0;
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
      fileCaption=nls('in 1 file');
   } else {
      fileCaption=nls('in %s/%s files',fileNumber,fileCount);
   }

   // display '+' on item count if they have incremental references turned on
   _str incremental=(unExpandedNodes && (def_references_options & VSREF_FIND_INCREMENTAL))? '+':'';

   // that's all folks, format the string and return
   return "["itemNumber'/'itemCount:+incremental' 'fileCaption']';
}

// Set the filename and line number caption for the symbol window.
// The the current object must be the references window.
static void SetRefInfoCaption(struct VS_TAG_BROWSE_INFO cm)
{
   _str caption = ctlreferences.RefCountInfoCaption();
   caption = caption :+ " " :+ 
             ctlreflabel._ShrinkFilename(cm.file_name,
                                         p_active_form.p_width-ctlreflabel.p_x-
                                         ctlreflabel._text_width(caption)-
                                         ctlreflabel._text_width(' : 'cm.line_no)) :+
             ": " :+ cm.line_no;
   if (caption!=ctlreflabel.p_caption) {
      ctlreflabel.p_caption=caption;
   }
   //ctlreflabel.p_width=ctlreflabel._text_width(ctlreflabel.p_caption);
}

void _tbtagrefs_form.on_resize()
{
   int old_wid, avail_x, avail_y;
   // RGH - 4/26/2006
   // For the plugin, first resize the SWT container then do the normal resize
   if (isEclipsePlugin()) {
      int referencesOutputContainer = _GetReferencesWID();
      if(!referencesOutputContainer) return;
      old_wid = p_window_id;
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

   // what are are margins?
   int margin_x = ctlreferences.p_x;
   int margin_y = ctlrefname.p_y;

   // Resize height:
   ctlrefedit.p_y = ctlreferences.p_y;
   ctlrefedit.p_height = avail_y - ctlrefedit.p_y - margin_y;
   ctldivider.p_y = ctlrefedit.p_y;
   ctldivider.p_height = ctlrefedit.p_height;

   // adjust the position and setting of the collapse button
   ctlcollapsebtn.p_x = avail_x - ctlcollapsebtn.p_width - ctlexpandbtn.p_width - margin_x*2;
   ctlexpandbtn.p_x   = ctlcollapsebtn.p_x + ctlcollapsebtn.p_width;

   if (ctlexpandbtn.p_value) {
      // force the sizebar to stay with reasonable size
      if (ctldivider.p_x > ctlcollapsebtn.p_x) {
         ctldivider.p_x = ctlcollapsebtn.p_x;
      }

      // adjust the width of the preview pane
      ctlrefedit.p_x = ctldivider.p_x + ctldivider.p_width;
      ctlrefedit.p_width = avail_x - ctlrefedit.p_x - margin_x;
      ctlreferences.p_height = ctlrefedit.p_height;

      // move label above the preview window
      ctlreflabel.p_y     = ctlsymlabel.p_y;
      ctlreflabel.p_x     = ctlrefedit.p_x;
      ctlreflabel.p_width = ctlrefedit.p_width - ctlcollapsebtn.p_width - ctlexpandbtn.p_width - ctldivider.p_width;
      ctldivider.p_user   = ctldivider.p_x;

   } else {
      // set up the height of the references tree
      ctlreferences.p_height = avail_y - ctlreferences.p_y - ctlreflabel.p_height + margin_y;

      // move label below the list of references
      ctlreflabel.p_y     = ctlreferences.p_y + ctlreferences.p_height;
      ctlreflabel.p_x     = ctlreferences.p_x;
      ctlreflabel.p_width = ctlreferences.p_width;

      // move sizebar all the way to left edge
      ctldivider.p_x = avail_x;

      // hide the controls if collapsing
      ctldivider.p_visible = false;
      ctlrefedit.p_visible = false;
      ctlrefedit.p_enabled = false;
   }

   // Resize width:
   avail_x = ctldivider.p_x;
   ctlreferences.p_width  = avail_x - ctlreferences.p_x - margin_x;
   ctlrefname.p_width     = avail_x - ctlrefname.p_x - margin_x;

   // do not let the combo box push to close to the collapse button
   if (ctlrefname.p_x + ctlrefname.p_width + ctldivider.p_width > ctlcollapsebtn.p_x) {
      ctlrefname.p_width = ctlcollapsebtn.p_x - ctlrefname.p_x - ctldivider.p_width;
   }

   // RGH - 4/26/2006
   // Switch p_window_id back
   if (isEclipsePlugin()) {
      p_window_id = old_wid;
   }
}

void ctlcollapsebtn.lbutton_up()
{
   // hide the controls if collapsing
   ctldivider.p_visible = false;
   ctlrefedit.p_visible = false;
   ctlrefedit.p_enabled = false;

   // delegate repositioning to the on_resize() event
   ctlexpandbtn.p_value   = 0;
   ctlcollapsebtn.p_value = 1;
   ctlcollapsebtn.p_enabled = false;
   ctlexpandbtn.p_enabled   = true;
   call_event(p_active_form,ON_RESIZE,'w');
}

void ctlexpandbtn.lbutton_up()
{
   // hide the controls if collapsing
   ctldivider.p_visible = true;
   ctlrefedit.p_visible = true;
   ctlrefedit.p_enabled = true;

   // restore position for sizebar
   ctldivider.p_x = ctldivider.p_user;

   // delegate repositioning to the on_resize() event
   ctlexpandbtn.p_value   = 1;
   ctlcollapsebtn.p_value = 0;
   ctlcollapsebtn.p_enabled = true;
   ctlexpandbtn.p_enabled   = false;
   call_event(p_active_form,ON_RESIZE,'w');
}

ctldivider.lbutton_down()
{
   int button_width = ctlsymlabel.p_width+ctlsymlabel.p_x;
   int border_width = ctlreferences.p_x;
   int member_width = ctlrefedit.p_x + ctlrefedit.p_width - ctlcollapsebtn.p_width - ctlexpandbtn.p_width;
   _ul2_image_sizebar_handler((button_width+border_width)*2, member_width);
}

void ctlrefname.on_create()
{
   p_user="";
   typeless xpos = _retrieve_value("_tbtagrefs_form.ctldivider.p_x");
   if (isuinteger(xpos)) {
      ctldivider.p_x = xpos;
   }
   ctldivider.p_user = ctldivider.p_x;
   typeless expand = _retrieve_value("_tbtagrefs_form.ctlexpandbtn.p_value");
   if (!isuinteger(expand)) expand = 1;
   ctlexpandbtn.p_value = expand;
   ctlcollapsebtn.p_enabled = expand!=0;
   ctlexpandbtn.p_enabled   = expand==0;
   call_event(p_active_form,ON_RESIZE,'w');

   // initialize the editor control
   ctlrefedit.p_window_flags|=(OVERRIDE_CURLINE_RECT_WFLAG|CURLINE_RECT_WFLAG|OVERRIDE_CURLINE_COLOR_WFLAG);
   ctlrefedit.p_window_flags&=~(CURLINE_COLOR_WFLAG);
   ctlrefedit.p_window_flags|=VSWFLAG_NOLCREADWRITE;
   ctlrefedit.p_buf_name=REFS_WINDOW_BUFFER_NAME;
   ctlrefedit.p_MouseActivate=MA_NOACTIVATE;
   //If I set tabs during the on_create it seemed to get hosed...
   //p_tabs='1 7 15 52';
   ctlrefedit.p_tabs='1 9 41';
   RefsEditWindowBufferID=ctlrefedit.p_buf_id;
   //ctlrefname.p_cb_list_box.p_buf_name=REFS_NAME_BUFFER_LIST;
   ctlrefedit.p_line=1;
   ctlrefedit.line_to_top();
   ctlrefedit.p_scroll_left_edge=-1;

   // if we don't want to go to the first one, do not activate the editor window
   if (!(def_references_options & VSREF_DO_NOT_GO_TO_FIRST)) {
      _post_call(mdisetfocus);
   }

   // copy event bindings from default keys
   copy_default_key_bindings('find-next');
   copy_default_key_bindings('find-prev');
}

void ctlrefname.on_destroy()
{
   p_user="";
   _lbtop();
   while (p_line < 50) {
      _append_retrieve(_control ctlrefname,_lbget_text());
      if (_lbdown()) {
         break;
      }
   }
}

void ctlrefname.on_drop_down(int reason)
{
   if (p_user=='') {
      _retrieve_list();
      p_user=1; // Indicate that retrieve list has been done
   }
   if (reason==DROP_UP_SELECTED) {
      goToTagInDropDown();
   }
}

//Just throwing in the keys that I really feel like I need
ctlrefname.ESC,'C-A'()
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _mdi.p_child._set_focus();
   }else{
      _cmdline._set_focus();
   }
}
void ctlrefname.ENTER()
{
   // in drop down?
   if( ctlrefname._ComboBoxListVisible() ) {
      ctlrefname.call_event(ctlrefname,last_event(),'2');
      return;
   }

   goToTagInDropDown();
}

/**
 * Goes to the tag selected in the references history combo box.
 */
static void goToTagInDropDown()
{
   // get search tag name and search class name
   _str search_string = ctlrefname.p_text;
   if (search_string=='') {
      return;
   }
   // remember this for later
   int orig_wid=p_window_id;
   ctlrefname._lbadd_bounded(search_string);
   ctlrefname._lbselect_line();
   // parse out the tag name and class name
   _str class_name, tag_name, type_name='';
   typeless df;
   tag_tree_decompose_tag(search_string,tag_name,class_name,type_name,df);

   // compose the tag into intermediate form
   search_string=tag_name;
   if (type_name!='') {
      search_string=tag_tree_compose_tag(tag_name,class_name,type_name);
   }
   if (search_string!='') {
      // check if the current workspace tag file or language specific
      // tag file requires occurrences to be tagged.
      if (_MaybeRetagOccurrences() == COMMAND_CANCELLED_RC) {
         return;
      }
      if (find_refs(search_string,1)==0) {
         // success, remember this for later
         if( orig_wid.ctlrefname.p_text != '' ) {
            orig_wid.ctlrefname._lbadd_bounded(orig_wid.ctlrefname.p_text);
            orig_wid.ctlrefname._lbselect_line();
         }
      }
   }
}

static void refswin_mode_enter()
{
   if (p_buf_name!=REFS_WINDOW_BUFFER_NAME) {
      tagwin_goto_tag(p_buf_name, p_RLine);
   }
}

static void refswin_next_window()
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _mdi.p_child._set_focus();
   }else{
      _cmdline._set_focus();
   }
}

static typeless RefsWinCommands:[]={
   "split-insert-line"         =>refswin_mode_enter,
   "c-enter"                   =>refswin_mode_enter,
   "slick-enter"               =>refswin_mode_enter,
   "cmd-enter"                 =>refswin_mode_enter,
   "for-enter"                 =>refswin_mode_enter,
   "pascal-enter"              =>refswin_mode_enter,
   "prg-enter"                 =>refswin_mode_enter,
   "select-line"               =>'',
   "brief-select-line"         =>'',
   "select-char"               =>'',
   "brief-select-char"         =>'',
   "cua-select"                =>'',
   "deselect"                  =>'',
   "copy-to-clipboard"         =>'',
   "next-window"               =>refswin_next_window,
   "prev-window"               =>refswin_next_window,
   "bottom-of-buffer"          =>'',
   "top-of-buffer"             =>'',
   "page-up"                   =>'',
   "vi-page-up"                =>'',
   "page-down"                 =>'',
   "vi-page-down"              =>'',
   "cursor-left"               =>'',
   "cursor-right"              =>'',
   "cursor-up"                 =>'',
   "cursor-down"               =>'',
   "begin-line"                =>'',
   "begin-line-text-toggle"    =>'',
   "brief-home"                =>'',
   "vi-begin-line"             =>'',
   "vi-begin-line-insert-mode" =>'',
   "brief-end"                 =>'',
   "end-line"                  =>'',
   "vi-end-line"               =>'',
   "brief-end"                 =>'',
   "vi-end-line-append-mode"   =>'',
   "mou-click"                 =>'',
   "mou-select-word"           =>'',
   "mou-select-line"           =>'',
   "next-word"                 =>'',
   "prev-word"                 =>'',
   "cmdline-toggle"            =>refswin_next_window
};

void ctlrefedit.\0-ON_SELECT()
{
   _str lastevent=last_event();
   _str eventname=event2name(lastevent);
   if (eventname=='ESC') {
      refswin_next_window();
      return;
   }
   if (eventname=='A-F4') {
      if (!p_active_form.p_DockingArea) {
         p_active_form._delete_window();
         return;
      }else{
         safe_exit();
         return;
      }
   }
   if (upcase(eventname)=='LBUTTON-DOUBLE-CLICK') {
      refswin_mode_enter();
      return;
   }
   int key_index=event2index(lastevent);
   int name_index=eventtab_index(_default_keys,ctlrefedit.p_mode_eventtab,key_index);
   _str command_name=name_name(name_index);
   if (command_name=='safe-exit') {
      safe_exit();
      return;
   }
   if (RefsWinCommands._indexin(command_name)) {
      switch (RefsWinCommands:[command_name]._varformat()) {
      case VF_FUNPTR:
         _str junk=(*RefsWinCommands:[command_name])();
         break;
      case VF_LSTR:
         //junk=(*RefsWinCommands:[command_name][0])(RefsWinCommands:[command_name][1]);
         call_index(name_index);
         break;
      }
   }
   if (select_active()) deselect();
}

void ctlrefedit.wheel_down,wheel_up() {
   fast_scroll();
}
void ctlrefedit.'c-wheel-down'() {
   scroll_page_down();
}
void ctlrefedit.'c-wheel-up'() {
   scroll_page_up();
}

void ctlreferences.rbutton_up()
{
   // Get handle to menu:
   int index=find_index("_tagbookmark_menu",oi2type(OI_MENU));
   int menu_handle=p_active_form._menu_load(index,'P');

   int flags=def_references_flags;
   pushTgConfigureMenu(menu_handle, flags, false, false, false, true);

   // add a couple of things in?
   _menu_insert(menu_handle, 1, MF_ENABLED | MF_UNCHECKED, 'Collapse all', 'TreeCollapseAll', '', '', 'Expand all nodes');
   _menu_insert(menu_handle, 1, MF_ENABLED | MF_UNCHECKED, 'Expand all', 'TreeExpandAll', '', '', 'Expand all nodes');

   // Show menu:
   int x,y;
   mou_get_xy(x,y);
   _KillToolButtonTimer();
   call_list("_on_popup2", translate("_tagbookmark_menu", "_", "-"), menu_handle);
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

void ctlreferences.c_up()
{
   ctlrefedit.cursor_up();
   preview_cursor_up();
}
void ctlreferences.c_down()
{
   ctlrefedit.cursor_down();
   preview_cursor_down();
}
void ctlreferences.c_pgup()
{
   ctlrefedit.scroll_page_up();
   preview_page_up();
}
void ctlreferences.c_pgdn()
{
   ctlrefedit.scroll_page_down();
   preview_page_down();
}

//############################################################################
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
static void refs_start_selected_timer(typeless timer_cb, int index=0, int ms=-1)
{
   if (_GetReferencesWID()) {
      if (ms < 0) ms = CB_TIMER_DELAY_MS;
      gReferencesSelectedTimerId=_set_timer(ms, timer_cb, index);
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
static void refs_start_highlight_timer(typeless timer_cb, int index=0, int ms=-1)
{
   if (_GetReferencesWID()) {
      if (ms < 0) ms = CB_TIMER_DELAY_MS;
      gReferencesHighlightTimerId=_set_timer(ms, timer_cb, index);
   }
}

//////////////////////////////////////////////////////////////////////////////
// compute name / line number string for sorting, accessing references
//
static _str ref_create_reference_info(int line_no, int tag_id, _str tag_filename)
{
   return line_no ';' tag_id ';1;' tag_filename;
}

//////////////////////////////////////////////////////////////////////////////
// retrieve information from reference tree or call tree
// p_window_id must be the references or call (uses) tree control.
//
static int get_reference_tag_info(int j, struct VS_TAG_BROWSE_INFO &cm, int &inst_id)
{
   //say("get_reference_tag_info: here, j="j);
   tag_browse_info_init(cm);
   if (j <= 0) {
      return 0;
   }

   // check the parent node for the filename
   int p=_TreeGetParentIndex(j);
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
   int status=0;
   boolean tag_database=false;
   _str ref_database = refs_filename();
   if (ref_database != '') {
      status = tag_read_db(ref_database);
      if ( status < 0 ) {
         return 0;
      }
   } else {
      tag_database=true;
   }

   // get the file name and line number, tag database, and instance ID
   _str ucm = _TreeGetUserInfo(j);
   typeless line_no,iid,col_no;
   parse ucm with line_no ';' iid ';' col_no ';' cm.tag_database;
   if (line_no == '') line_no = 0;
   if (col_no == '')  col_no = 0;
   cm.line_no = line_no;
   cm.column_no = col_no;
   inst_id    = iid;
   //say("get_reference_tag_info: file_name="cm.file_name" line_no="line_no" iid="iid);

   // get details about the instance (tag)
   if (inst_id > 0 && !tag_database) {
      typeless df,dl;
      tag_get_instance_info(inst_id, cm.member_name, cm.type_name, cm.flags, cm.class_name, cm.arguments, df, dl);
      //say("get_reference_tag_info(): got here 3, inst_id="inst_id" member_name="cm.member_name" file_name="cm.file_name" line_no="cm.line_no" args="cm.arguments);
   } else {
      // normalize member name
      cm.seekpos=0;//iid;
      tag_tree_decompose_caption(_TreeGetCaption(j),cm.member_name,cm.class_name,cm.arguments);
   }

   // is the given file_name and line number valid?
   if (cm.file_name != '') {
      if (cm.line_no > 0 && (_isfile_loaded(cm.file_name) || file_exists(cm.file_name))) {
         return 1;
      }
      if (tag_database && !cm.line_no) {
         // this is where we need to extract more information
         // from the source file, for now, we fake it
         cm.line_no=1;
         return 1;
      }
      cm.file_name = '';
   }

   // count the number of exact matches for this tag
   _str search_file_name  = cm.file_name;
   _str search_type_name  = cm.type_name;
   _str search_class_name = cm.class_name;
   _str search_arguments  = VS_TAGSEPARATOR_args:+cm.arguments;
   _str lang = _Filename2LangId(search_file_name);
   cm.language = lang;
   typeless tag_files=tags_filenamea(lang);
   int i=0;
   _str tag_filename=next_tag_filea(tag_files,i,false,true);
   while (tag_filename != '') {
      //say("get_reference_tag_info: tag_file="tag_filename);
      // search for exact match
      _str alt_type_name = search_type_name;
      //_message_box("member="cm.member_name" type="search_type_name" class="cm.class_name" args="cm.arguments" file="search_file_name);
      status = tag_find_tag(cm.member_name, search_type_name, search_class_name, search_arguments);
      if (status < 0) {
         if (search_type_name :== 'class') {
            alt_type_name = 'interface';
            status = tag_find_tag(cm.member_name, alt_type_name, search_class_name, search_arguments);
         } else if (search_type_name :== 'func') {
            alt_type_name = 'proto';
            status = tag_find_tag(cm.member_name, alt_type_name, search_class_name, search_arguments);
         } else if (search_type_name :== 'proc') {
            alt_type_name = 'procproto';
            status = tag_find_tag(cm.member_name, alt_type_name, search_class_name, search_arguments);
         }
      }
      while (status == 0) {
         // get basic information for this tag, check type and class
         typeless dm;
         tag_get_info(dm, cm.type_name, cm.file_name, cm.line_no, cm.class_name, cm.flags);
         if (cm.type_name :!= search_type_name && cm.type_name != alt_type_name) {
            break;
         }
         //if (cm.class_name :!= search_class_name) {
         //   break;
         //}
         // file name matches, then we've found our perfect match!!!
         if (search_file_name == '' || file_eq(search_file_name, cm.file_name)) {
            cm.tag_database=tag_filename;
            return 1;
         }
         // get next tag
         status = tag_next_equal(1 /*case sensitive*/);
      }
      tag_reset_find_tag();

      // try the next tag file
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }

   return 0;
}

void tag_refs_clear_pics()
{
   if (gref_pic_type >= 0) {
      _StreamMarkerRemoveAllType(gref_pic_type);
   }
}

static int cb_add_file_refs(_str file_name, struct VS_TAG_BROWSE_INFO &cm,
                            int filter_flags, int tree_index,
                            int &num_refs, int max_refs,
                            _str tag_name=null, boolean case_sensitive=null,
                            int start_seekpos=0, int end_seekpos=0,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   //say("cb_add_file_refs: file="file_name" index="tree_index);
   // open a temporary view of 'file_name'
   int tree_wid=p_window_id;
   int temp_view_id,orig_view_id;
   boolean inmem;
   int status=_open_temp_view(file_name,temp_view_id,orig_view_id,'',inmem,false,true);
   if (!status) {
      // delegate the bulk of the work
      //say("cb_add_file_refs: cm.file="cm.file_name" cm.line="cm.line_no);
      if (case_sensitive==null) {
         case_sensitive=p_EmbeddedCaseSensitive;
      }
      _SetAllOldLineNumbers();
      _str errorArgs[]; errorArgs._makeempty();
      status = tag_match_occurrences_in_file(errorArgs,tree_wid,tree_index,
                                             cm.member_name,case_sensitive,
                                             cm.file_name,cm.line_no,filter_flags,
                                             start_seekpos,end_seekpos,
                                             num_refs,max_refs,visited,depth+1);
      tree_wid._TreeSizeColumnToContents(0);

      if (!status && (def_references_options & VSREF_HIGHLIGHT_MATCHES)) {
         if (gref_pic_type < 0) {
            gref_pic_type = _MarkerTypeAlloc();
         }

         got_one := false;
         int first_child = tree_wid._TreeGetFirstChildIndex(tree_index);
         while (first_child > 0) {

            _str tag_info = tree_wid._TreeGetUserInfo(first_child);
            typeless ref_line=0, ref_seekpos=0, ref_col=0;
            parse tag_info with ref_line ';' ref_seekpos ';' ref_col;

            if (_pic_editor_reference <= 0) {
               _pic_editor_reference = _update_picture(0, "_edreference.ico");
            }
            int markerIndex = _StreamMarkerAddB(file_name, ref_seekpos, length(tag_name), 1, _pic_editor_reference, gref_pic_type, "Reference to "tag_name);
            _StreamMarkerSetTextColor(markerIndex, CFG_HILIGHT);
            got_one = true;

            first_child = tree_wid._TreeGetNextSiblingIndex(first_child);
         }

         if (got_one && !_no_child_windows() && temp_view_id.p_buf_id == _mdi.p_child.p_buf_id) {
            refresh();
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
static int cb_add_bsc_refs(int &count, int filter_flags, int i,
                           struct VS_TAG_BROWSE_INFO cm, _str ref_database)
{
   // collect the file names so far
   _str file_name;
   int file_index_map:[]; file_index_map._makeempty();
   int j = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (j > 0) {
      file_name=_TreeGetUserInfo(j);
      if (file_name != '') {
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
   _str member_name='';
   _str class_name='';
   _str type_name='';
   _str arguments='';
   int flags,lno;
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
         _str base_name = _strip_filename(file_name,'P');
         tree_index=_TreeAddItem(TREE_ROOT_INDEX,base_name:+"\t":+file_name,TREE_ADD_AS_CHILD,_pic_file12,_pic_file12,1,0,file_name);
         file_index_map:[_file_case(file_name)]=tree_index;
      }
      //say("cb_add_bsc_refs: file="file_name" index="tree_index);

      // get the tag information for either the tag or instance
      if (context_id > 0) {
         // get details about this tag (for creating caption)
         tag_get_instance_info(context_id, member_name, type_name, flags, class_name, arguments, file_name, lno);
      }

      // find the tag and create caption and icon for it
      int pic_ref,leaf_flag;
      _str fcaption='';
      if (type_name != '' && member_name != '') {
         boolean show_it = false;
         if (tag_filter_type(0,filter_flags,type_name,flags)) {
            // make caption for this instance
            fcaption = tag_tree_make_caption(member_name, type_name, class_name, flags, '', true);
            // function/data, access restrictions and type code for picture selection
            int i_type, i_access;
            //tag_tree_filter_member(0, type_name, ((class_name!='')? 1:0), flags, i_access, i_type);
            //tag_tree_select_bitmap(i_access, i_type, 0, pic_ref);
            tag_tree_get_bitmap(0,0,type_name,class_name,flags,leaf_flag,pic_ref);
         }
      } else if (filter_flags & VS_TAGFILTER_MISCELLANEOUS) {
         // insert the item and set the user info
         fcaption = _strip_filename(file_name,'P'):+"\t":+file_name:+": ":+line_no;
         tag_tree_select_bitmap(0, 28/*CB_type_unknown*/, 0, pic_ref);
      }
      if (fcaption != '') {
         // find-tune column widths if necessary
         _str rpart,lpart;
         parse fcaption with rpart "\t" lpart;
         // set up the user info for this tag
         _str ucaption = ref_create_reference_info(line_no, context_id, ref_database);
         // insert the item and set the user info
         j = _TreeAddItem(tree_index,fcaption,TREE_ADD_AS_CHILD,pic_ref,pic_ref,-1,0,ucaption);
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
static boolean isCHeaderFile(VS_TAG_BROWSE_INFO &cm)
{
   // must be C, C++, Objective-C, or ANSI-C
   switch (cm.language) {
   case 'c':
   case 'cpp':
   case 'm':
   case 'ansic':
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
   switch (first_char(ext)) {
   case 'H':
   case 'h':
   case 'I':
   case 'i':
      return true;
   case 'C':
   case 'c':
   case 'M':
   case 'm':
      return false;
   }
   return false;
}

//////////////////////////////////////////////////////////////////////////////
// Insert items called or used by the given tag (tag_id) into the given tree.
// Opens the given database.  Returns the number of items inserted.
// p_window_id must be the references tree control.
//
static int cb_add_refs(int i, struct VS_TAG_BROWSE_INFO cm, boolean &terminated_early,
                       _str buf_name=null, boolean case_sensitive=true)
{
   // map prototype to proc/func/constr/destr
   int status = 0;
   if (cm.tag_database != '') {
      status = tag_read_db(cm.tag_database);
      if ( status < 0 ) {
         return 0;
      }
   }
   // check if there is a load-tags function, if so, watch out
   _str orig_file_name=cm.file_name;
   boolean is_jar_file=false;
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      is_jar_file=true;
   } else if ((cm.type_name:=='proto' || cm.type_name:=='procproto') &&
              !(cm.flags & (VS_TAGFLAG_native|VS_TAGFLAG_abstract)) && cm.tag_database!='') {
      _str search_arguments  = VS_TAGSEPARATOR_args:+cm.arguments;
      if (tag_find_tag(cm.member_name, 'proc', cm.class_name, search_arguments)==0 ||
          tag_find_tag(cm.member_name, 'func', cm.class_name, search_arguments)==0 ||
          tag_find_tag(cm.member_name, 'constr', cm.class_name, search_arguments)==0 ||
          tag_find_tag(cm.member_name, 'destr', cm.class_name, search_arguments)==0) {
         //say("cb_add_uses: found a proc, file="cm.file_name" line="cm.line_no);
         tag_get_info(cm.member_name, cm.type_name, cm.file_name, cm.line_no, cm.class_name, cm.flags);
         tag_get_detail(VS_TAGDETAIL_language_id,cm.language);
      }
      tag_reset_find_tag();
   }

   int filter_flags = def_references_flags;
   int count = 0;

   // open the tag database for business
   int tag_database=0;
   _str ref_database = refs_filename();
   _str tag_files[]; tag_files._makeempty();
   if (ref_database != '') {
      //say("cb_add_refs: got reference database="ref_database);
      tag_files._makeempty();
      tag_files[0]=ref_database;
   } else {
      tag_database=1;
      _str cm_lang = cm.language;
      if (is_jar_file) {
         cm_ext := _get_extension(cm.file_name);
         if (cm_ext == 'class' || cm_ext == 'jar') {
            cm_lang = 'java';
         } else if (!_no_child_windows()) {
            cm_lang = _mdi.p_child.p_LangId;
         } else if (cm_ext == 'dll' || cm_ext == "winmd") {
            cm_lang = 'cs';
         }
      }
      if (cm_lang==null || cm_lang=='') {
         cm_lang = _Filename2LangId(cm.file_name);
      }
      tag_files = tags_filenamea(cm_lang);
      if (cm.language == "") {
         cm.language = cm_lang;
      }
   }

   // always look for references in the file containing the declaration
   int t=0, tree_index = TREE_ROOT_INDEX;
   int alt_tree_index = TREE_ROOT_INDEX;

   if (tag_database) {
      // check if we have cross referencing built for at least one of the tag files
      boolean have_references=false;
      ref_database=next_tag_filea(tag_files,t,false,true);
      while (ref_database != '') {
         // match instances using Context Tagging(R)
         if (tag_get_db_flags() & VS_DBFLAG_occurrences) {
            have_references=true;
            break;
         }
         // next tag file, please...
         ref_database=next_tag_filea(tag_files,t,false,true);
      }
      // always look for references in the file containing the originating reference
      if (!is_jar_file && cm.language != "tagdoc") {
         tree_index=_TreeAddItem(TREE_ROOT_INDEX,_strip_filename(cm.file_name,'P'):+"\t":+cm.file_name,TREE_ADD_AS_CHILD,_pic_file12,_pic_file12, 0, 0, cm.file_name);
         int ww = _text_width(cm.file_name);
         _TreeColWidth(0,ww);
      }
      // always look for references in the file containing the definition
      if (!file_eq(orig_file_name,cm.file_name) && !_QBinaryLoadTagsSupported(orig_file_name) && cm.language != "tagdoc") {
         alt_tree_index=_TreeAddItem(TREE_ROOT_INDEX,_strip_filename(orig_file_name,'P'):+"\t":+orig_file_name,TREE_ADD_AS_CHILD,_pic_file12,_pic_file12, 0, 0, orig_file_name);
      }
      // and give the current buffer a shot, too
      if (buf_name!=null && buf_name!='' &&
          !file_eq(buf_name,cm.file_name) && !file_eq(buf_name,orig_file_name)) {
         alt_tree_index=_TreeAddItem(TREE_ROOT_INDEX,_strip_filename(buf_name,'P'):+"\t":+buf_name,TREE_ADD_AS_CHILD,_pic_file12,_pic_file12, 0, 0, buf_name);
      }

      // Is this a local variable, paramater, or static non-class declaration?
      // Then don't search tag files
      if (!have_references ||
          cm.type_name=='lvar' || cm.type_name=='param' ||
          (cm.class_name=='' && (cm.flags & VS_TAGFLAG_static) && !isCHeaderFile(cm))) {
         tag_files._makeempty();
      }

      // if this is a private member in Java, then restrict, only need
      // the file that contains it.
      if ((cm.flags & VS_TAGFLAG_access)==VS_TAGFLAG_private && _get_extension(cm.file_name)=="java") {
         tag_files._makeempty();
      }
   }

   // save the current buffer state
   _str orig_context_file='';
   tag_get_detail2(VS_TAGDETAIL_current_file,0,orig_context_file);
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_push_context();

   // this is the language to restrict references matches to
   _str restrictToLangId = "";
   if (!(def_references_options & VSREF_ALLOW_MIXED_LANGUAGES)) {
      restrictToLangId = cm.language;
      if (restrictToLangId == "" && cm.file_name != null && cm.file_name != "") {
         restrictToLangId = _Filename2LangId(cm.file_name);
      }
      if (restrictToLangId == "") {
         tag_get_detail2(VS_TAGDETAIL_language_id,0,restrictToLangId);
      }
   }

   // for each tag file to consider
   t=0;
   ref_database=next_tag_filea(tag_files,t,false,true);
   while (ref_database != '') {

      if (tag_database) {
         // match instances using Context Tagging(R)
         if (!(tag_get_db_flags() & VS_DBFLAG_occurrences)) {
            ref_database=next_tag_filea(tag_files,t,false,true);
            continue;
         }
         tag_list_file_occurrences(p_window_id,TREE_ROOT_INDEX,
                                   cm.member_name,1,(int)case_sensitive,
                                   count,def_cb_max_references,
                                   restrictToLangId);
      } else {
         // match instances in BSC database
         cb_add_bsc_refs(count,filter_flags,i,cm,ref_database);
         // close the BSC database
         status = tag_close_db(ref_database,1);
         if ( status ) {
            break;
         }
      }

      // next tag file, please...
      ref_database=next_tag_filea(tag_files,t,false,true);
   }

   // for each file found in the list
   _TreeSortCaption(TREE_ROOT_INDEX,'UF');

   // if the current buffer is in the list, float it to the top
   if (buf_name != null) {
      int j=_TreeSearch(TREE_ROOT_INDEX, _strip_filename(buf_name,'P'):+"\t":+buf_name, _fpos_case);
      if (j >= 0) {
         if (_TreeGetFirstChildIndex(j)<0) {
            _TreeDelete(j);
            j=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
            if (j>0) {
               alt_tree_index=_TreeAddItem(j,_strip_filename(buf_name,'P'):+"\t":+buf_name,TREE_ADD_BEFORE,_pic_file12,_pic_file12, 0, 0, buf_name);
            } else {
               alt_tree_index=_TreeAddItem(TREE_ROOT_INDEX,_strip_filename(buf_name,'P'):+"\t":+buf_name,TREE_ADD_AS_CHILD,_pic_file12,_pic_file12, 0, 0, buf_name);
            }
         }
      }
   }

   // expand all the references, unless we are doing incremental referencing
   if (!(def_references_options & VSREF_FIND_INCREMENTAL)) {
      int j = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (j > 0 && !_IsKeyPending(false)) {
         if (_TreeGetFirstChildIndex(j) <= 0) {
            call_event(CHANGE_EXPANDED,j,p_window_id,ON_CHANGE,'w');
            _TreeSetInfo(j,1);
            count += _TreeGetNumChildren(j);
            if (count >= def_cb_max_references) {
               break;
            }
         }
         j=_TreeGetNextSiblingIndex(j);
      }
      // they hit escape, there still might be references out there...somewhere
      if (j > 0) {
         if (!count) {
            count += _TreeGetNumChildren(TREE_ROOT_INDEX);
         }
      } else {
         // go through the list and delete items with no references
         j = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         while (j > 0) {
            int next=_TreeGetNextSiblingIndex(j);
            int show_children=0;
            _TreeGetInfo(j,show_children);
            if (show_children > 0 && _TreeGetFirstChildIndex(j) <= 0) {
               _TreeDelete(j);
            }
            j = next;
         }
      }
   }

   // set the column width
   clear_message();
   _TreeSizeColumnToContents(0);
   if (count >= def_cb_max_references) {
      terminated_early=true;
   }

   // force an update of the previous context
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_pop_context();

   // return total number of items inserted
   return count;
}


static void refresh_references_view(struct VS_TAG_BROWSE_INFO cm, boolean &terminated_early,
                                    _str buf_name=null, boolean case_sensitive=true)
{
   // populate the list of references
   tag_refs_clear_pics();
   _SetDialogInfoHt(REFS_VISITED_KEY, null, _mdi); 
   ctlreferences._TreeDelete(TREE_ROOT_INDEX, 'c');
   ctlreferences._TreeColWidth(0,10);
   cb_prepare_expand(p_active_form,ctlreferences,TREE_ROOT_INDEX);

   // blow out of here if cm is empty
   if (cm.member_name=='') {
      return;
   }

   mou_hour_glass(1);
   if( ctlrefname.p_text != '' ) {
      ctlrefname._lbadd_bounded(ctlrefname.p_text);
      ctlrefname._lbselect_line();
   }
   int count = ctlreferences.cb_add_refs(TREE_ROOT_INDEX, cm, terminated_early, buf_name, case_sensitive);

   if (count==0 && tag_tree_type_is_func(cm.type_name)) {
      if (tag_find_tag(cm.member_name, 'proto', cm.class_name, VS_TAGSEPARATOR_args:+cm.arguments)==0) {
         //tag_get_detail(VS_TAGDETAIL_tag_id, proto_tag_id);
         count = ctlreferences.cb_add_refs(TREE_ROOT_INDEX, cm, terminated_early, buf_name, case_sensitive);
      } else if (tag_find_tag(cm.member_name, 'procproto', cm.class_name, VS_TAGSEPARATOR_args:+cm.arguments)==0) {
         //tag_get_detail(VS_TAGDETAIL_tag_id, proto_tag_id);
         count = ctlreferences.cb_add_refs(TREE_ROOT_INDEX, cm, terminated_early, buf_name, case_sensitive);
      }
      tag_reset_find_tag();
   }
   if (count==0 && tag_tree_type_is_class(cm.type_name)) {
      if (tag_find_tag(cm.member_name, 'interface', cm.class_name)==0) {
         //tag_get_detail(VS_TAGDETAIL_tag_id, proto_tag_id);
         count = ctlreferences.cb_add_refs(TREE_ROOT_INDEX, cm, terminated_early, buf_name, case_sensitive);
      }
      tag_reset_find_tag();
   }
   //say('count='count);
   _mffindNoMore(def_mfflags);
   _mfrefIsActive=true;

   // sort exactly the way we want things
   //ctlreferences._TreeSortUserInfo(TREE_ROOT_INDEX,'TI');
   //ctlreferences._TreeTop();
   ctlreferences._TreeRefresh();
   mou_hour_glass(0);
}


//////////////////////////////////////////////////////////////////////////////
// Handle double-click event (opens the file and positions us on the
// line indicated by the reference data), this may or may not be the
// right line to be positioned on.
//
void ctlreferences.enter,lbutton_double_click()
{
   // get the context information, push book mark, and open file to line
   struct VS_TAG_BROWSE_INFO cm;
   int inst_id=0;
   if (ctlreferences.get_reference_tag_info(ctlreferences._TreeCurIndex(), cm, inst_id)) {
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
void ctlreferences.' '()
{
   // IF this is an item we can go to like a class name
   int orig_window_id = p_window_id;

   // get the context information, push book mark, and open file to line
   struct VS_TAG_BROWSE_INFO cm;
   int inst_id=0;
   if (ctlreferences.get_reference_tag_info(ctlreferences._TreeCurIndex(), cm, inst_id)) {
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
   _str caption = _TreeGetCaption(currIndex);
   parse caption with caption "\t" .;
   int show_children=0;
   int pic_index=0;
   _TreeGetInfo(currIndex,show_children,pic_index);
   _str what_not_found = (pic_index == _pic_file12)? 'file':'tag';
   messageNwait("Could not find "what_not_found": "caption);
}

//////////////////////////////////////////////////////////////////////////////
// Preview the selected tab in the references tree
// 
static void refresh_references_preview(struct VS_TAG_BROWSE_INFO cm)
{
   if (ctlexpandbtn.p_value) {

      // close the buffer which was previously open
      if (ctlrefedit.p_buf_name!=REFS_WINDOW_BUFFER_NAME &&
          ctlrefedit.p_buf_name!=cm.file_name &&
          (ctlrefedit.p_buf_flags&VSBUFFLAG_HIDDEN) &&
          _SafeToDeleteBuffer(ctlrefedit.p_buf_id,
                              ctlrefedit.p_window_id,
                              ctlrefedit.p_buf_flags)) {
         ctlrefedit.quit_file();
      }

      ctlrefedit.DisplayFile(cm.file_name,cm.line_no,cm.seekpos,cm.column_no,cm.member_name,cm.language);
      ctlrefedit.refresh();
   }
   cb_refresh_output_tab(cm, true, true, false, APF_REFERENCES);
}

//////////////////////////////////////////////////////////////////////////////
// This is the timer callback.  Whenever the current index (cursor position)
// for the reference tree is changed, a timer is started/reset.  If no
// activity occurs within a set amount of time, this function is called to
// update the properties view, inheritance view, and output window.
//
static void _RefListTimerCallback(int index=0)
{
   // kill the timer
   refs_kill_selected_timer();

   int f = _GetReferencesWID(true);
   if (!f) {
      return;
   }
   _nocheck _control ctlreferences;

   // get the current tree index
   int currIndex = index;
   if (currIndex <= 0) {
      currIndex = f.ctlreferences._TreeCurIndex();
   }
   if (currIndex<=0) {
      return;
   }

   // get the context information, push book mark, and open file to line
   struct VS_TAG_BROWSE_INFO cm;
   int inst_id=0;
   if (f.ctlreferences.get_reference_tag_info(currIndex, cm, inst_id)) {
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

static void _RefListHighlightCallback(int index=0)
{
   // kill the timer
   refs_kill_highlight_timer();

   int f = _GetReferencesWID(true);
   if (!f) {
      return;
   }
   _nocheck _control ctlreferences;

   // get the current tree index
   int currIndex = index;
   if (currIndex <= 0) {
      currIndex = f.ctlreferences._TreeCurIndex();
   }
   if (currIndex<=0) {
      return;
   }

   // get the context information, push book mark, and open file to line
   struct VS_TAG_BROWSE_INFO cm;
   int inst_id=0;
   if (f.ctlreferences.get_reference_tag_info(currIndex, cm, inst_id)) {
      if (cm.seekpos==null) cm.seekpos=0;
      _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle on-change event for member list (a tree control) in inheritance
// tree dialog.  The only event handled is CHANGE_LEAF_ENTER, for which
// we utilize push_tag_in_file to push a bookmark and bring up the code in
// the editor.
//
void ctlreferences.on_change(int reason,int index)
{
   if (reason == CHANGE_LEAF_ENTER) {
      // get the context information, push book mark, and open file to line
      struct VS_TAG_BROWSE_INFO cm;
      int inst_id=0;
      if (ctlreferences.get_reference_tag_info(index, cm, inst_id)) {
         tagwin_goto_tag(cm.file_name,cm.line_no,cm.seekpos,cm.column_no,def_search_result_push_bookmark);
      } else {
         message_cannot_find_ref(index);
      }
   } else if (reason == CHANGE_SELECTED) {
      if (_get_focus()==ctlreferences) {
         // kill the existing timer and start a new one
         refs_kill_selected_timer();
         refs_start_selected_timer(_RefListTimerCallback);
      }
   } else if (reason == CHANGE_EXPANDED) {
      if (ctlreferences._TreeGetDepth(index)==1) {
         struct VS_TAG_BROWSE_INFO cm;
         cm=ctlreferences.p_user;
         if (cm==null || !VF_IS_STRUCT(cm)) {
            return;
         }
         _str file_name=_TreeGetUserInfo(index);
         message("Searching: "file_name);
         mou_hour_glass(1);
         int count=0;
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
         _TreeDelete(index, 'C');
         cb_add_file_refs(file_name,cm,def_references_flags,index,0,
                          def_cb_max_references,cm.member_name,
                          null,func_start_seekpos,func_end_seekpos,*pvisited);
         //_TreeEndUpdate(index);
         _str orig_caption = _TreeGetCaption(index);
         parse orig_caption with orig_caption "...NO REFERENCES";
         _str tag_line = (_TreeGetFirstChildIndex(index) <= 0)? "...NO REFERENCES":"";
         _TreeSetCaption(index,orig_caption:+tag_line);
         mou_hour_glass(0);
         clear_message();
      }
   }
}

void ctlreferences.on_highlight(int index, _str caption="")
{
   // kill the existing timer and start a new one
   refs_kill_highlight_timer();
   if (index < 0 || !def_tag_hover_preview) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   refs_start_highlight_timer(_RefListHighlightCallback, index, def_tag_hover_delay);
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
   refs_kill_selected_timer();
   refs_start_selected_timer(_RefListTimerCallback);
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Refresh the output symbols tab (peek-a-boo window)
// Returns 0 on success, nonzero if the search was terminated abnormally.
//
int refresh_references_tab(struct VS_TAG_BROWSE_INFO cm, boolean find_all=false)
{
   int f = _GetReferencesWID(true);
   if (!f) {
      return(1);
   }

   // if cm was passed in as null, then get information from last time
   _nocheck _control ctlreferences;
   if (cm==null) {
      cm=f.ctlreferences.p_user;
   } else {
      typeless ref_cm = f.ctlreferences.p_user;
      if (!find_all && tag_browse_info_equal(cm,ref_cm)) {
         return(0);
      }
      f.ctlreferences.p_user=cm;
   }
   if (cm==null || !VF_IS_STRUCT(cm)) {
      return(1);
   }

   // find the output tagwin and update it
   _nocheck _control ctlrefname;
   //_nocheck _control ctlrefedit;
   f.ctlrefname.p_user = cm.file_name "\t" cm.line_no;
   if (cm.type_name == '') {
      f.ctlrefname.p_text = cm.member_name;
   } else if (cm.class_name == '') {
      f.ctlrefname.p_text = cm.member_name '(' cm.type_name ')';
   } else {
      f.ctlrefname.p_text = cm.member_name '(' cm.class_name ':' cm.type_name ')';
   }

   // compute language case sensitivity
   boolean case_sensitive = true;
   if (_isEditorCtl()) {
      case_sensitive=p_EmbeddedCaseSensitive;
   } else if (cm.file_name) {
      int temp_view_id,orig_view_id;
      boolean inmem=0;
      int status = _open_temp_view(cm.file_name,temp_view_id,orig_view_id,'',inmem,false,true);
      if (!status) {
         case_sensitive=p_EmbeddedCaseSensitive;
         _delete_temp_view(temp_view_id);
         p_window_id=orig_view_id;
      }
   }

   boolean terminated_early=false;
   tag_refs_clear_pics();
   _SetDialogInfoHt(REFS_VISITED_KEY, null, _mdi); 
   f.ctlreferences._TreeDelete(TREE_ROOT_INDEX,'C');
   f.refresh_references_view(cm, terminated_early,
                             (_isEditorCtl()? p_buf_name:null), case_sensitive);

   if (cm.file_name!=null && cm.file_name!='') {
      if (cm.line_no == null) {
         cm.line_no=1;
      }
      if (!_QBinaryLoadTagsSupported(cm.file_name)) {
         //f.ctlrefedit.DisplayFile(cm.file_name,cm.line_no,0,cm.column_no);
         f.ctlreferences.SetRefInfoCaption(cm);
         f.refresh_references_preview(cm);
      }
   }
   if (terminated_early) {
      f.ctlreflabel.p_caption=nls("WARNING: The references search results were truncated.");
      //f.ctlreflabel.p_width=f.ctlreflabel._text_width(f.ctlreflabel.p_caption);
   }

   f.ctlreferences._TreeTop();
   f.ctlreferences._TreeRefresh();
   return (int)(terminated_early);
}

boolean tag_refs_clear_editor(int buf_id)
{
   int f = _GetReferencesWID();
   if (!f) return false;

   if (f.ctlrefedit.p_buf_id != buf_id) {
      return false;
   }

   f.ctlrefedit.load_files('+q +m +bi 'f.RefsEditWindowBufferID);
   return true;
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Find the next/previous reference
//
static int next_prev_ref_in_tree(int direction, boolean quiet=false)
{
   int index=0;
   for (;;) {
      index = _TreeCurIndex();
      if (index < 0) {
         break;
      }
      int show_children=0;
      _TreeGetInfo(index,show_children);
      if (_TreeGetDepth(index)==1 && show_children==0) {
         _TreeSetInfo(index,1);
         if (_TreeGetNumChildren(index)==0) {
            call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');
         }
         continue;
      }
      int status = 0;
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
static int next_prev_ref(int direction, boolean preview_only=true,boolean quiet=false)
{
   int f = _GetReferencesWID();
   if (!f) {
      return 0;
   }

   // find the output tagwin and update it
   struct VS_TAG_BROWSE_INFO cm;
   _nocheck _control ctlreferences;
   //_nocheck _control ctlrefedit;

   int index = f.ctlreferences.next_prev_ref_in_tree(direction, quiet);
   int inst_id=0;
   f.ctlreferences.get_reference_tag_info(index,cm,inst_id);
   if (index > 0 && cm.file_name!=null && cm.file_name!='') {
      if (cm.line_no == null) {
         cm.line_no=1;
      }
      //f.ctlrefedit.DisplayFile(cm.file_name,cm.line_no,0,cm.column_no);
      f.ctlreferences._TreeRefresh();
      f.ctlreferences.SetRefInfoCaption(cm);
      f.refresh_references_preview(cm);
   } else {
      if (!quiet) {
         _message_box("no more references");
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
 * <p>Repositions the cursor on the next item in the references tool 
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
_command int next_ref(boolean preview_only=true,boolean quiet=false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   return next_prev_ref(1,preview_only,quiet);
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
_command int prev_ref(boolean preview_only=true,boolean quiet=false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   return next_prev_ref(-1,preview_only,quiet);
}
_command int current_ref(boolean preview_only=true,boolean quiet=false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_EDITORCTL)
{
   return next_prev_ref(0,preview_only,quiet);
}

int _MaybeRetagOccurrences(_str curr_tag_file="")
{
   // if there is a BSC file, then bail out
   if (refs_filename() != '') {
      return 0;
   }

   // set up array of two tag files
   _str wst_filename = _GetWorkspaceTagsFilename();
   _str tag_files[]; tag_files._makeempty();
   if (wst_filename != '') {
      // make sure that the project involves the current extension
      if (tag_read_db(wst_filename) >= 0) {
         if (!_isEditorCtl() || tag_find_language(auto dummy_lang,p_LangId)==0) {
            tag_files[tag_files._length()]=wst_filename;
         }
         tag_reset_find_language();
      }
   }
   if (curr_tag_file != '') {
      tag_files[tag_files._length()]=curr_tag_file;
   } else if (_isEditorCtl() && _LanguageInheritsFrom('e')) {
      // extension specific tag file, not in project
      _str ext_tag_files[];
      ext_tag_files = tags_filenamea(p_LangId);
      if (ext_tag_files._length() >= 1 && ext_tag_files[0]!=wst_filename) {
         tag_files[tag_files._length()] = ext_tag_files[0];
      }
   }

   int status,result=0,i=0;
   _str tag_filename = next_tag_filea(tag_files, i, false, true);
   while (tag_filename != '') {

      // already have occurrences
      int db_flags = tag_get_db_flags();
      if (!(db_flags & VS_DBFLAG_occurrences)) {

         // no occurrences, ask if we should build them now
         status=_message_box(nls("Do you want to build a symbol cross-reference for '%s'?\nThis may take several minutes.",tag_filename),'',MB_YESNOCANCEL|MB_ICONQUESTION);
         if (status==IDYES || status==IDOK) {
            // build the cross-reference
            mou_hour_glass(1);
            status = RetagFilesInTagFile(tag_filename,true,true,false,false,true);
            mou_hour_glass(0);
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

void _prjclose_tagrefs()
{
   int f = _GetReferencesWID();
   if (!f) return;
   _nocheck _control ctlrefedit;
   _nocheck _control ctlreferences;
   if (f.ctlrefedit.p_user!=f.ctlrefedit.p_buf_id) {
      if (f.ctlrefedit.p_buf_flags&VSBUFFLAG_HIDDEN) {
         if (_SafeToDeleteBuffer(f.ctlrefedit.p_buf_id,
                                 f.ctlrefedit.p_window_id,
                                 f.ctlrefedit.p_buf_flags)
             ) {
            f.ctlrefedit.quit_file();
         }
      }
      f.ctlrefedit.load_files('+q +m +bi 'f.ctlrefedit.p_user);
   }
   tag_refs_clear_pics();
   _SetDialogInfoHt(REFS_VISITED_KEY, null, _mdi); 
   f.ctlreferences._TreeDelete(TREE_ROOT_INDEX,'C');
   f.ctlreflabel.p_caption='';
   _mfrefNoMore(1);
}

int toolShowReferences()
{
   int index = find_index('_refswindow_Activate',PROC_TYPE);
   if( index_callable(index) ) {
      return (call_index(index));
   }
   return (activate_toolbar("_tbtagrefs_form","ctlreferences"));
}

///////////////////////////////////////////////////////////////////////////////
// For saving and restoring the state of the references tool window
// when the user undocks, pins, unpins, or redocks the window.
//
struct REFERENCES_WINDOW_STATE {
   typeless nodes;
   _str symbolName;
   int colWidth;
};
void _tbSaveState__tbtagrefs_form(REFERENCES_WINDOW_STATE& state, boolean closing)
{
   //if( closing ) {
   //   return;
   //}
   state.colWidth=ctlreferences._TreeColWidth(0);
   state.symbolName=ctlrefname.p_text;
   ctlreferences._TreeSaveNodes(state.nodes);
   if (gReferencesSelectedTimerId == -1) {
      refs_start_selected_timer(_RefListTimerCallback);
   }
}
void _tbRestoreState__tbtagrefs_form(REFERENCES_WINDOW_STATE& state, boolean opening)
{
   //if( opening ) {
   //   return;
   //}
   if (state == null) return;
   ctlrefname.p_text=state.symbolName;
   ctlreferences._TreeColWidth(0,state.colWidth);
   ctlreferences._TreeRestoreNodes(state.nodes);
}

