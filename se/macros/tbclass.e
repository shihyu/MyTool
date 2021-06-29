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
#include "cbrowser.sh"
#import "caddmem.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "cutil.e"
#import "debuggui.e"
#import "files.e"
#import "jrefactor.e"
#import "help.e"
#import "ini.e"
#import "listproc.e"
#import "main.e"
#import "quickrefactor.e"
#import "picture.e"
#import "proctree.e"
#import "pushtag.e"
#import "refactor.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tagcalls.e"
#import "tagform.e"
#import "taggui.e"
#import "tagrefs.e"
#import "tagwin.e"
#import "tbcontrols.e"
#import "toolbar.e"
#import "treeview.e"
#import "eclipse.e"
#import "tbxmloutline.e"
#import "proctree.e"
#import "tbxmloutline.e"
#import "proctree.e"
#import "se/tags/TaggingGuard.e"
#import "se/ui/toolwindow.e"
#import "se/ui/mainwindow.e"
#endregion


struct CLASS_FORM_INFO {
   int m_form_wid;
   int m_LastModified;
   int m_last_buf_id;
   int m_RLine;
   int m_selected_LastModified;
   _str m_old_class;
   bool m_java_workaround_cur_class;
};
static CLASS_FORM_INFO gClassFormList:[];

static void _init_all_formobj(CLASS_FORM_INFO (&formList):[],_str formName) {
   int last = _last_window_id();
   int i;
   for (i=1; i<=last; ++i) {
      if (_iswindow_valid(i) && i.p_object == OI_FORM && !i.p_edit) {
         if (i.p_name:==formName) {
            formList:[i].m_form_wid=i;
            formList:[i].m_LastModified= -1;
            formList:[i].m_last_buf_id= -1;
            formList:[i].m_RLine= -1;
            formList:[i].m_selected_LastModified= -1;
            formList:[i].m_old_class= "";
            formList:[i].m_java_workaround_cur_class= false;
         }
      }
   }
}


defeventtab _tbclass_form;

_tbclass_form."F12"()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   } else if (def_keys == "eclipse-keys") {
      activate_editor();
   }
}

_tbclass_form."C-S-PAD-SLASH"()
{
   if (isEclipsePlugin() || def_keys == "eclipse-keys") {
      class_crunch();
   }
}

_tbclass_form."C-M"()
{
   if (isEclipsePlugin()) {
      eclipse_maximize_part();
   }
}

_command class_crunch() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   f := _eclipse_getClassQFormWid();
   if (!f) {
      messageNwait("_tbclass_form " nls("not found"));
      return("");
   }

   _nocheck _control ctlmembers, ctlclasses;
   tbclass_maybe_kill_timer();
   mou_hour_glass(true);

   int j = f.ctlmembers._TreeGetFirstChildIndex(0);
   while (j > 0) {
      show_children := 0;
      f.ctlmembers._TreeGetInfo(j, show_children);
      if (show_children>=0) {
         f.ctlmembers._TreeDelete(j, 'c');
         if (show_children>0) {
            f.ctlmembers._TreeSetInfo(j, 0);
         }
      }
      j = f.ctlmembers._TreeGetNextSiblingIndex(j);
   }

   j = f.ctlclasses._TreeGetFirstChildIndex(0);
   while (j > 0) {
      show_children := 0;
      f.ctlclasses._TreeGetInfo(j, show_children);
      if (show_children>=0) {
         f.ctlclasses._TreeDelete(j, 'c');
         if (show_children>0) {
            f.ctlclasses._TreeSetInfo(j, 0);
         }
      }
      j = f.ctlclasses._TreeGetNextSiblingIndex(j);
   }

   mou_hour_glass(false);
}

static const TBCLASS_FORM= "_tbclass_form";
static const EXCLUSION_MANAGER_FORM= "_class_exclusion_manager";

// DJB 04/18/2008 -- make these static
//static VS_TAG_BROWSE_INFO old_hierarchy[]=null;
static _str exclusions:[];
static _str exclusions_outside_wspace:[];
static int gClassFocusTimerId = -1;

/**
 * Organize inherited class members in the Class tool window in 
 * categories according to their parent class.  If this option is 
 * turned off, the class members will be presented in a single 
 * flat list. 
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_tbc_organize_by_source = true;
/**
 * Sort symbols (class members) in the Class tool window by name. 
 * If this is turned off, then symbols are sorted by line number.
 *  
 * @default false
 * @categories Configuration_Variables
 */
bool def_tbc_sort_by_name = false;
/**
 * Sort class names in the Class tool window from 
 * top-to-bottom of the inheritance hierarchy. If 
 * this is turned off, then classes will simply be 
 * sorted by name. 
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_tbc_sort_class_by_hierarchy = true;
/**
 * If enabled, classes that are not in the current workspace will 
 * not be included in the class heirarchy in the Class tool window. 
 * This is useful to eliminate some noise in a langauge like Java 
 * where your classes typically derive from system classes which 
 * have a deep hierarchy.
 * 
 * @default false
 * @categories Configuration_Variables
 */
bool def_tbc_filter_outside_wspace = false;
/**
 * Expand all classes in the Class tool window. 
 * If this option is turned off, only the current (top level) 
 * class will be expanded. 
 * 
 * @default false
 * @categories Configuration_Variables
 */
bool def_tbc_expand_all= false;
/**
 * If enabled, expand all inner structs, enums, classes, etc.
 * in the Class tool window. 
 * 
 * @default false
 * @categories Configuration_Variables
 */
bool def_tbc_expand_structs= false;
/**
 * If enabled, jump to definition of symbol on single click. 
 * and jump to declaration on shift-click. 
 * 
 * @default false
 * @categories Configuration_Variables
 */
bool def_tbc_single_click= false;

definit()
{
   if (arg(1)!='L') {
      gClassFocusTimerId=-1;
      exclusions._makeempty();
      exclusions_outside_wspace._makeempty();
   }
   //old_hierarchy=null;
   gClassFormList._makeempty();
   _init_all_formobj(gClassFormList,TBCLASS_FORM);
}

static void tbclass_maybe_kill_timer()
{
   if (gClassFocusTimerId != -1) {
      _kill_timer(gClassFocusTimerId);
      gClassFocusTimerId=-1;
   }
}

// save tool window information (expand option, exclusions) 
int _sr_tbclass(_str options = "", _str info = "")
{
   if (options == 'R' || options == 'N') {
      exclusions._makeempty();
      exclusions_outside_wspace._makeempty();
      _str num1, num2, line;
      parse info with num1" "num2;
      int i;
      for (i = 0; i < num1; i++) {
         down();
         get_line(line);
         exclusions:[line] = 1;
      }
      for (i = 0; i < num2; i++) {
         down();
         get_line(line);
         exclusions_outside_wspace:[line] = 1;
      }
   } else {
      num1 := 0;
      num2 := 0;
      // save the number of exclusions in each hashtable
      _tb_class_get_num_exclusions(num1, num2);
      insert_line("TBCLASS: "num1" "num2);
      down();
      _str key;
      // loop through both hashtables and add the classes excluded
      for (key._makeempty();;) {
         exclusions._nextel(key);
         if (key._isempty()) {
            break;
         }
         if (exclusions:[key] == 1) {
            insert_line(key);
            down();
         }
      }
      for (key._makeempty();;) {
         exclusions_outside_wspace._nextel(key);
         if (key._isempty()) {
            break;
         }
         if (exclusions_outside_wspace:[key] == 1) {
            insert_line(key);
            down();
         }
      }
   }
   return(0);
}

int _eclipse_getClassQFormWid()
{
   int formWid = _find_formobj(ECLIPSE_CLASS_CONTAINERFORM_NAME,"n");
   if (formWid > 0) {
      return formWid.p_child;
   }
   return 0;
}

// used in _sr_tbclass for getting the number of excluded classes in each hashtable
static void _tb_class_get_num_exclusions(int &num_exclusions = 0, int &num_exclusions_wspace = 0)
{
   _str key;
   for (key._makeempty();;) {
      exclusions._nextel(key);
      if (key._isempty()) {
         break;
      }
      if (exclusions:[key] == 1) {
         num_exclusions++;
      }
   }
   for (key._makeempty();;) {
      exclusions_outside_wspace._nextel(key);
      if (key._isempty()) {
         break;
      }
      if (exclusions_outside_wspace:[key] == 1) {
         num_exclusions_wspace++;
      }
   }
}

static void _ClassFocusTimerCallback(int form_wid)
{
   // kill the timer
   _kill_timer(gClassFocusTimerId);
   gClassFocusTimerId=-1;
   if (!_iswindow_valid(form_wid)) {
      return;
   }

   child_wid := form_wid._MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }

   // get all the window ids
   /*int form_wid = _tbGetActiveClassForm();
   if (!form_wid) {
      return;
   } */
   _nocheck _control ctlmembers, ctlclasses;
   int members_wid = form_wid.ctlmembers;
   int classes_wid = form_wid.ctlclasses;
   focuswid := _get_focus();

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag info and preview symbol
   struct VS_TAG_BROWSE_INFO cm;
   if (focuswid :== members_wid) {
      symbol_wid := _GetTagwinWID();
      if (symbol_wid != 0) {
         tbclass_members_get_info(child_wid,members_wid, members_wid._TreeCurIndex(), cm);
         child_wid._UpdateContext(true,false);
         cb_refresh_output_tab(cm,true,true,false,APF_CLASS);
      }

   } else if (focuswid :== classes_wid) {
      symbol_wid := _GetTagwinWID();
      if (symbol_wid != 0) {
         tbclass_classes_get_info(classes_wid, classes_wid._TreeCurIndex(), cm, true);
         cb_refresh_output_tab(cm,true,true,false,APF_CLASS);
      }
   }
}

static void _ClassHighlightTimerCallback(_str formWid_and_index) 
{
   parse formWid_and_index with auto sform_wid auto sindex;
   form_wid := (int)sform_wid;
   index := (int)sindex;

   // kill the timer
   _kill_timer(gClassFocusTimerId);
   gClassFocusTimerId=-1;

   _nocheck _control ctlmembers, ctlclasses;
   classes_wid := form_wid.ctlclasses;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag info and preview symbol
   symbol_wid := _GetTagwinWID();
   if (symbol_wid <= 0) {
      return;
   }

   tbclass_classes_get_info(classes_wid, index, auto cm, true);
   _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
}

static void _MemberHighlightTimerCallback(_str formWid_and_index)
{
   parse formWid_and_index with auto sform_wid auto sindex;
   form_wid := (int)sform_wid;
   index := (int)sindex;

   // kill the timer
   _kill_timer(gClassFocusTimerId);
   gClassFocusTimerId=-1;

   child_wid := _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }

   _nocheck _control ctlmembers, ctlclasses;
   members_wid := form_wid.ctlmembers;

   // find the tag info and preview symbol
   symbol_wid := _GetTagwinWID();
   if (symbol_wid <= 0) {
      return;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   tag_init_tag_browse_info(auto cm);
   tbclass_members_get_info(child_wid,members_wid, index, cm);
   _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
}

// check the available space for the caption and maybe remove it if there isn't enough room
// this is so that the buttons do not slide under the caption
static void setCaptionVisible()
{
   if (ctlcurclass.p_x_extent >= ctlback.p_x) {
      ctlcurclass.p_width = 0; 
      ctlcurclass.p_visible = false;
   } else {
      ctlcurclass.p_visible = true;
      ctlcurclass.p_y = ctlup.p_y;
   }
}

void _tbclass_form.on_resize()
{
   int old_wid, avail_x, avail_y;
   if (isEclipsePlugin()) {
      classContainer := _eclipse_getClassQFormWid();
      if(!classContainer) return;
      old_wid = p_window_id;
      p_window_id = classContainer;
      eclipse_resizeContainer(classContainer);
      avail_x = classContainer.p_parent.p_width;
      avail_y = classContainer.p_parent.p_height;
      if (avail_x == 0 && avail_x == 0) {
         return;
      }
   } else {
      // how much space do we have to work with?
      avail_x  = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
      avail_y  = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   }

   // adjust the button sizes if they are too large
   // (allow them to be 33% larger than font size)
   max_button_height := ctlcurclass.p_y_extent+ctlcurclass.p_height intdiv 3;
   space_x := _dx2lx(SM_TWIP, def_toolbar_pic_hspace);
   ctlback.resizeToolButton(max_button_height);
   ctlup.resizeToolButton(max_button_height);
   ctldown.resizeToolButton(max_button_height);
   ctlshow.resizeToolButton(max_button_height);
   ctlhide.resizeToolButton(max_button_height);
   alignControlsHorizontal(avail_x - ctlhide.p_width*5 - space_x*6,
                           0,
                           space_x,
                           ctlback.p_window_id, 
                           ctlup.p_window_id,
                           ctldown.p_window_id,
                           ctlshow.p_window_id,
                           ctlhide.p_window_id);

   // what are are margins?
   margin_x := ctlclasses.p_x;
   margin_y := max(ctlcurclass.p_y_extent,ctlshow.p_y_extent);

   // resize width:
   ctlclasses.p_x = ctlmembers.p_x;
   ctlclasses.p_width = avail_x - ctlmembers.p_x - margin_x;
   ctlmembers.p_x = ctlmembers.p_x;
   ctlmembers.p_x_extent = avail_x - margin_x;
   ctldivider.p_x = ctlclasses.p_x;
   ctldivider.p_width = ctlclasses.p_width;

   // set caption width and make sure the caption doesn't interfere with the buttons
   ctlcurclass.p_width = avail_x-ctlback.p_width-ctlup.p_width-ctldown.p_width-ctlhide.p_width-
                           ctlshow.p_width-margin_x;
   setCaptionVisible();

   if (ctlshow.p_value) {
      // force the sizebar to stay with reasonable size
      if ((avail_y - ctldivider.p_y) < (margin_y * 2)) {
         ctldivider.p_y = avail_y - margin_y * 2;
      }


      // adjust the height of the two panes
      ctlclasses.p_y = margin_y;
      ctlclasses.p_height = ctldivider.p_y - margin_y;
      ctldivider.p_user = ctldivider.p_y;
      ctlmembers.p_y = ctldivider.p_y_extent;
      ctlmembers.p_height = avail_y - ctldivider.p_y - ctldivider.p_height - margin_y;

      // toggle the divider on
      ctldivider.p_visible = true;
   } else {
      // move the members pane all the way up top
      ctlmembers.p_y = margin_y;

      // hide the appropriate controls if collapsing
      ctldivider.p_visible = false;
      ctlclasses.p_visible = false;

      // set the height of the members pane to the full length of the tool window 
      ctlmembers.p_y_extent = avail_y - ctldivider.p_height;
   }

   // resize height:
   ctlmembers.p_y_extent = avail_y - ctldivider.p_height;
   if (isEclipsePlugin()) {
      p_window_id = old_wid;
   }
}

ctldivider.lbutton_down()
{
   int top_height = ctlhide.p_y_extent * 2;
   int bottom_height = ctlmembers.p_y_extent - ctlhide.p_height * 2; 
   _ul2_image_sizebar_handler(top_height, bottom_height);
}

void _tbclass_form.on_destroy()
{
   tbclass_maybe_kill_timer();

   gClassFormList._deleteel(p_active_form);

   // save the position of the sizing bar
   _moncfg_append_retrieve(0,ctldivider.p_user,"_tbclass_form.ctldivider.p_y");

   // save whether or not the class hierarchy window is hidden
   _moncfg_append_retrieve(0,ctlshow.p_value,"_tbclass_form.ctlshow.p_value");

   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id,ON_DESTROY,"2");
}

void ctlmembers.on_create()
{
   CLASS_FORM_INFO info;
   i := p_active_form;
   info.m_form_wid=p_active_form;
   info.m_LastModified= -1;
   info.m_last_buf_id= -1;
   info.m_RLine= -1;
   info.m_selected_LastModified= -1;
   info.m_old_class="";
   info.m_java_workaround_cur_class=false;
   gClassFormList:[i]=info;

   typeless expand = _moncfg_retrieve_value("_tbclass_form.ctlshow.p_value");
   if (!isuinteger(expand)) expand = 1;
   typeless ypos = _moncfg_retrieve_value("_tbclass_form.ctldivider.p_y");
   if (isuinteger(ypos)) {
      ctldivider.p_y = ypos;
   }
   ctldivider.p_user = ctldivider.p_y;
   ctlshow.p_value = expand;
   ctlhide.p_enabled = expand!=0;
   ctlshow.p_enabled   = expand==0;
   call_event(p_active_form,ON_RESIZE,"w");
   ctlmembers.initClass();
   ctlmembers._MakePreviewWindowShortcuts();
}

///////////////////////////////////////////////////////////////////////////////
// For saving and restoring the state of the Project tool window
// when the user undocks, pins, unpins, or redocks the window.
//
struct CLASS_BROWSER_WINDOW_STATE {
   typeless classNodes;
   typeless memberNodes;
   int classColWidth;
   int memberColWidth;
};
void _twSaveState__tbclass_form(CLASS_BROWSER_WINDOW_STATE& state, bool closing)
{
   if( closing ) {
      tbclass_maybe_kill_timer();
   }
   ctlclasses._TreeSaveNodes(state.classNodes);
   ctlmembers._TreeSaveNodes(state.memberNodes);

   state.classColWidth = ctlclasses._TreeColWidth(0);
   state.memberColWidth = ctlmembers._TreeColWidth(0);
}
void _twRestoreState__tbclass_form(CLASS_BROWSER_WINDOW_STATE& state, bool opening)
{
   //if( opening ) {
   //   return;
   //}
   if (state == null) return;
   tbclass_maybe_kill_timer();
   ctlclasses._TreeDelete(TREE_ROOT_INDEX, 'c');
   ctlmembers._TreeDelete(TREE_ROOT_INDEX, 'c');
   ctlclasses._TreeRestoreNodes(state.classNodes);
   ctlmembers._TreeRestoreNodes(state.memberNodes);

   ctlclasses._TreeColWidth(0,state.classColWidth);
   ctlmembers._TreeColWidth(0,state.memberColWidth);
}

void _tbclass_form.on_change(int reason)
{
   if( reason==CHANGE_AUTO_SHOW ) {
      if (!_find_control("ctlmembers")) return;
      _UpdateClassMe(true);
   }
}

static void tbclass_get_cur_class(int child_wid,
                                  _str &cur_class_name, 
                                  _str &cur_package_name, 
                                  typeless &tag_files, 
                                  int &context_id,
                                  bool &inClassDefinition,
                                  bool &java_workaround_cur_class=false)
{
   orig_id := p_window_id;
   p_window_id = child_wid;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);
   _UpdateLocals(true);

   isjava := (child_wid.p_LangId :== "java");
   context_id = tag_get_current_context(auto cur_tag_name, auto cur_tag_flags,
                                        auto cur_type_name, auto cur_type_id,
                                        cur_class_name, auto cur_context, cur_package_name);

   // Compute whether we are in the original class definition, 
   // and that it is not a partial class
   inClassDefinition = (cur_tag_flags & SE_TAG_FLAG_INCLASS) != 0;
   if (tag_tree_type_is_class(cur_type_name)) {
      cur_class_name = cur_context;
      inClassDefinition = true;
   }
   if (cur_tag_flags & SE_TAG_FLAG_PARTIAL) inClassDefinition = false;

   // tag_list_in_class works better without :'s
   // unfortunately this can break nested classes in java...tag_get_current_context probably needs to be
   // changed...for now just special case c sharp
   if (child_wid.p_LangId :== "cs") {
      cur_class_name = stranslate(cur_class_name, VS_TAGSEPARATOR_package,":");
   }
   java_workaround_cur_class=false;
   // make sure we get the full package/namespace along with the class name
   tag_files = tags_filenamea(child_wid.p_LangId);
   if (isjava && (cur_class_name :== "" || cur_class_name :== cur_package_name)) {
      java_workaround_cur_class=true;
      file_name := _strip_filename(p_buf_name, 'P');
      parse file_name with cur_class_name ".java";
      if (cur_class_name :!= "" && cur_package_name :!= "" && cur_package_name :!= cur_class_name ) {
         cur_class_name = cur_package_name :+ VS_TAGSEPARATOR_package :+ cur_class_name;
      }
   } else if (!isjava && cur_package_name :== "") {
      tag_push_matches();
      _str errorArgs[]; errorArgs._makeempty();
      VS_TAG_RETURN_TYPE rt; tag_return_type_init(rt);
      struct VS_TAG_RETURN_TYPE visited:[];
      parse_status := _Embeddedparse_return_type(errorArgs,tag_files,cur_class_name, cur_class_name,
                                             child_wid.p_buf_name,cur_class_name,isjava,rt,visited); 
      if (!parse_status && rt.return_type != cur_class_name) {
         cur_class_name = rt.return_type;
      }
      tag_pop_matches();
   }
   p_window_id = orig_id;
}

void ctlmembers.on_change(int reason,int index)
{
   if (reason == CHANGE_SELECTED) {
      // don't create a new timer unless there is something to update
      if (!tw_is_visible("_tbtagwin_form")) {
         return;
      }
      tbclass_maybe_kill_timer();
      int timer_delay=max(200,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
      gClassFocusTimerId=_set_timer(timer_delay,_ClassFocusTimerCallback,p_active_form);

   } else if (reason == CHANGE_EXPANDED && _TreeGetFirstChildIndex(index) <= 0) {
      // DJB 04-18-2008 -- expand nodes on-demand if they aren't already expanded 
      int child_wid=_MDIGetActiveMDIChild();
      if (!child_wid) return;
      tbclass_members_get_info(child_wid,p_window_id, index, auto cm);
      if (tag_tree_type_is_class(cm.type_name) || cm.type_name=="enum") {
         context_flags := SE_TAG_CONTEXT_ANYTHING|
                          SE_TAG_CONTEXT_ALLOW_PRIVATE|
                          SE_TAG_CONTEXT_ACCESS_PROTECTED|
                          SE_TAG_CONTEXT_ALLOW_ANONYMOUS;
         tbclass_get_cur_class(child_wid, auto cur_class_name, auto cur_package_name, auto tag_files, auto context_id, auto in_class);
         class_name := tag_join_class_name(cm.member_name, cm.class_name, tag_files, true, true);
         if (class_name != "") {
            tbclass_pop_inner_class(child_wid,p_window_id, index, class_name, context_flags, tag_files, cm.file_name); 
         }
      }
   }
}

void ctlmembers.on_highlight(int index, _str caption="")
{
   //say("ctlmembers.on_highlight: index="index" caption="caption);
   tbclass_maybe_kill_timer();
   if (!def_tag_hover_preview) return;
   if (index < 0) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   gClassFocusTimerId=_set_timer(def_tag_hover_delay, _MemberHighlightTimerCallback, p_active_form" "index);
}

void ctlclasses.on_change(int reason,int index)
{
   if (reason == CHANGE_SELECTED) {
      // don't create a new timer unless there is something to update
      if ( !tw_is_visible("_tbtagwin_form") ) {
         return;
      }
      tbclass_maybe_kill_timer();
      int timer_delay=max(200,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
      gClassFocusTimerId=_set_timer(timer_delay,_ClassFocusTimerCallback,p_active_form);
   } else if (reason == CHANGE_EXPANDED) {
      tbclass_classes_get_info(ctlclasses, index, auto cm);
      typeless tag_files;
      int child_wid=_MDIGetActiveMDIChild();
      if (child_wid) {
         tag_files = tags_filenamea(child_wid.p_LangId);
      } else {
         tag_files="";
      }
      tag_read_db(cm.tag_database);
      class_name := cm.member_name;
      if (cm.class_name != "") {
         class_name = cm.class_name :+ VS_TAGSEPARATOR_package :+ cm.member_name;
      }
      VS_TAG_RETURN_TYPE visited:[];
      tbclass_add_parents_of(index, class_name, cm.file_name, cm.tag_database, tag_files, visited); 
      TraverseAndColorHierarchy(index);
   } else if (reason == CHANGE_COLLAPSED) {
      tbclass_maybe_kill_timer();
      _TreeDelete(index,'c');
   }
}

void ctlclasses.on_highlight(int index, _str caption="")
{
   //say("ctlclasses.on_highlight: index="index" caption="caption);
   tbclass_maybe_kill_timer();
   if (!def_tag_hover_preview) return;
   if (index < 0) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   gClassFocusTimerId=_set_timer(def_tag_hover_delay, _ClassHighlightTimerCallback, p_active_form" "index);
}

void ctlclasses.ENTER()
{
   ctlclasses.call_event(ctlclasses,LBUTTON_DOUBLE_CLICK,'w');
}

void ctlmembers.ENTER()
{
   ctlmembers.call_event(ctlmembers,LBUTTON_DOUBLE_CLICK,'w');
}


void ctlclasses.lbutton_double_click()
{
   tbclass_maybe_kill_timer();
   treewid := p_window_id;
   orig_wid := p_window_id;
   index := ctlclasses._TreeCurIndex();
   if (!index) {
      return;
   }
   tbclass_classes_get_info(treewid, index, auto cm);
   // Set focus to the MDI child so the current MDI window gets
   // set. Then edit() will open the file in the expected MDI frame.
   child_wid := _MDIGetActiveMDIChild();
   if (child_wid) {
      child_wid._set_focus();
   }
   //say('cm.class_name='cm.class_name' line='cm.line_no);
   push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
   treewid._UpdateClassMe(true);
}

void ctlmembers.lbutton_double_click()
{
   tbclass_maybe_kill_timer();
   treewid := p_window_id;
   index := treewid._TreeCurIndex();
   if (!index) {
      return;
   }
   child_wid := _MDIGetActiveMDIChild();
   if (!child_wid) return;
   status := tbclass_members_get_info(child_wid,treewid, index, auto cm);
   if (status < 0) return;
   // Set focus to the MDI child so the current MDI window gets
   // set. Then edit() will open the file in the expected MDI frame.
   if (child_wid) {
      child_wid._set_focus();
   }
   push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
   treewid._UpdateClassMe(true);
}
void ctlmembers.lbutton_up()
{
   if (!def_tbc_single_click) {
      return;
   }
   ctlmembers.call_event(ctlmembers,LBUTTON_DOUBLE_CLICK,'w');
}

/*bool ClassHasFocus()
{ 
   focuswid := _get_focus();
   if (focuswid && focuswid.p_active_form==TBCLASS_FORM) {
      return true;
   }
   return false;
} */

void ctlhide.lbutton_up()
{
   // hide the controls if collapsing
   ctlclasses.p_visible = false;
   ctlclasses.p_enabled = false;
   // delegate repositioning to the on_resize() event
   ctlshow.p_value = 0;
   ctlhide.p_value = 1;
   ctlhide.p_enabled = false;
   ctlshow.p_enabled = true;
   p_active_form.call_event(p_active_form,ON_RESIZE,'w');
}

void ctlshow.lbutton_up()
{
   // hide the controls if collapsing
   ctlclasses.p_visible = true;
   ctlclasses.p_enabled = true;
   // delegate repositioning to the on_resize() event
   ctlshow.p_value = 1;
   ctlhide.p_value = 0;
   ctlhide.p_enabled = true;
   ctlshow.p_enabled = false;
   p_active_form.call_event(p_active_form,ON_RESIZE,'w');
}

void ctlback.lbutton_up()
{
   int child_wid = _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }
   child_wid.pop_bookmark();
   _UpdateClassMe(true);
}

void ctlup.lbutton_up()
{
   if (tbclass_hierarchy_is_empty() == -1) return;
   int wid = ctlclasses;
   // get the info from the class we're currently in
   index := wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   tbclass_classes_get_info(wid, index, auto cm);
   _str lang = _Filename2LangId(cm.file_name);
   typeless tag_files = tags_filenamea(lang);
   bool been_there_done_that:[];
   been_there_done_that._makeempty();
   tag_push_matches();
   tag_clear_matches();
   int child_wid=_MDIGetActiveMDIChild();
   full_name := "";
   // first argument has to be the fully qualified class, with a namespace/pkg if it has one
   if (cm.class_name :!= "") {
      full_name = cm.class_name :+ VS_TAGSEPARATOR_package :+ cm.member_name;
   } else {
      full_name = cm.member_name;
   }
   struct VS_TAG_RETURN_TYPE visited:[]; visited._makeempty();
   tag_find_derived(/*-1, */full_name, 
                    cm.tag_database, tag_files, 
                    cm.file_name, cm.line_no,
                    been_there_done_that, visited);
   // tag_find_derived will include the current class in the match set...so check for at least 2 matches
   if (tag_get_num_of_matches() >= 1) {
      status := tag_select_match();
      if (status > 0) {
         tag_get_match_info(status, auto sel);
         // Set focus to the MDI child so the current MDI window gets
         // set. Then edit() will open the file in the expected MDI frame.
         if (child_wid) {
            child_wid._set_focus();
         }
         push_tag_in_file(sel.member_name, sel.file_name, 
                          sel.class_name, 
                          sel.type_name, sel.line_no);
         wid._UpdateClassMe(true);
      }
   } else {
      _message_box(cm.member_name " has no child classes.");
   }
   tag_pop_matches();
}

void ctldown.lbutton_up()
{
   if (tbclass_hierarchy_is_empty() == -1) return;
   int wid = ctlclasses;
   // do we have any parent classes to jump down to?
   int index = wid._TreeGetFirstChildIndex(wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX));
   if (index > 0) {
      int dest_class_index = index;
      sib_index := wid._TreeGetNextSiblingIndex(index);
      // do the parents have any sibling classes we might want to jump down to?
      if (sib_index > 0) {
         tag_push_matches();
         tag_clear_matches();
         tbclass_classes_get_info(wid, index, auto cm);
         tag_insert_match_info(cm);
         // if so, add 'em to the match set
         while (sib_index > 0) {
            tbclass_classes_get_info(wid, sib_index, cm);
            tag_insert_match_info(cm);
            sib_index = wid._TreeGetNextSiblingIndex(sib_index);
         }
         int status = tag_select_match();
         if (status) {
            tag_get_match_info(status, auto sel);
            int child_wid=_MDIGetActiveMDIChild();
            // Set focus to the MDI child so the current MDI window gets
            // set. Then edit() will open the file in the expected MDI frame.
            if (child_wid) {
               child_wid._set_focus();
            }
            push_tag_in_file(sel.member_name, sel.file_name, sel.class_name, sel.type_name, sel.line_no);
            wid._UpdateClassMe(true);
         }
         tag_pop_matches();
      } else {
         // no other children? just jump down to the one child then
         if (dest_class_index > 0) {
            wid._TreeSetCurIndex(dest_class_index);
            wid.call_event(wid, LBUTTON_DOUBLE_CLICK);
            wid._UpdateClassMe(true);
         }
      }
   }
}

_command void activate_tbclass() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return;
   }

   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.views.showView","org.eclipse.ui.views.showView.viewId,org.eclipse.ui.views.showView.makeFast", "com.slickedit.eclipse.views.SlickEditClassView,false");
   } else {
      activate_tool_window("_tbclass_form", true, "ctlmembers");
   }
}

static void initClass()
{
   gClassFormList:[p_active_form].m_old_class= "";
   //old_hierarchy=null;
   if (def_class_flags == -1) {
      def_class_flags = SE_TAG_FILTER_ANYTHING;
   }
   _UpdateClassMe(true);
}

int _tbGetActiveClassForm()
{
   return tw_find_form(TBCLASS_FORM);
}

int _tbGetActiveClassMembersTreeWid()
{
   wid := _tbGetActiveClassForm();
   if (wid) {
      wid=wid.ctlmembers;
   } else {
      wid=0;
   }
   return(wid);
}

int _tbGetActiveClassHierarchyTreeWid()
{
   wid := _tbGetActiveClassForm();
   if (wid) {
      wid=wid.ctlclasses;
   } else {
      wid=0;
   }
   return(wid);
}

static int GetExclusionManagerFormWID()
{
   int wid = _find_formobj(EXCLUSION_MANAGER_FORM,'N');;
   if (!wid) {
      wid=0;
   }
   return(wid);
}

  
static int tbclass_hierarchy_is_empty()
{
   return(ctlclasses._TreeGetFirstChildIndex(TREE_ROOT_INDEX));
}

static void _UpdateClassHierarchy(int child_wid,
                                  bool NeedsUpdate, 
                                  _str cur_class_name,
                                  VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   int treewid=p_active_form.ctlclasses;
   focuswid := _get_focus();
   if (!focuswid) {
      return;
   }

   // is the tree empty, and not forcing update, and not first time here
   isEmpty := (treewid._TreeGetFirstChildIndex(TREE_ROOT_INDEX) < 0);
   if (focuswid==treewid && !isEmpty && !NeedsUpdate) {
      return;
   }

   // if the hierarchy pane is not current, do not update.
   if ( !tw_is_wid_active(treewid) ) {
      return;
   }

   if (!NeedsUpdate) {
      return; 
   }

   // update and get the current context info
   tbclass_maybe_kill_timer();
   child_wid._UpdateContext(true,false);
   orig_id := p_window_id;
   p_window_id = child_wid;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_get_current_context(auto cur_tag_name,auto cur_tag_flags,
                                            auto cur_type_name,auto cur_type_id,
                                            auto cur_class_name2,auto cur_class_only,
                                            auto cur_package_name,
                                            visited, depth+1);
   if (context_id > 0) {
      tag_get_context_info(context_id, auto cm);
      typeless tag_files = tags_filenamea(cm.language);
      i := 0;
      // open the right tag database
      found_tag := false;
      for (i; i < tag_files._length(); i++) {
         tag_read_db(tag_files[i]);
         _str temp_class;
         int status = tag_find_tag(cm.member_name, cm.type_name, cm.class_name);
         tag_reset_find_tag();
         if (status == 0) {
            found_tag = true;
            break;
         }
      }
      if (!found_tag) {
         tag_read_db(_GetWorkspaceTagsFilename());
      }
      struct VS_TAG_BROWSE_INFO class_hierarchy[]=null;
      same_hierarchy := true;
      if (cur_class_name :!= "") {
         // clear out the stale hierarchy...
         treewid._TreeDelete(TREE_ROOT_INDEX, 'c');
         int status;
         // and add the new one
//         say("_UpdateClass: Adding hierarchy: cur_class_name: " cur_class_name);
         _str file_name, type_name;
         line_no := 0;
         tbclass_class_type(cur_class_name, file_name, line_no, type_name); 
         pic_var := tag_get_bitmap_for_type(tag_get_type_id(type_name), 0, auto pic_overlay);
         info := tag_current_db() :+ ";" :+ cur_class_name ";" :+ type_name ";" file_name ";" :+ line_no;
         int index = treewid._TreeAddItem(TREE_ROOT_INDEX, cur_class_name, TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,pic_overlay, pic_var,1,0,info); 
//         say('_UpdateClass: info ='info);
         treewid.tbclass_add_parents_of(index, cur_class_name, cm.file_name, tag_current_db(), tag_files, visited, 1);
         treewid.TraverseAndColorHierarchy(TREE_ROOT_INDEX);
      } else if (cur_class_name :== "") {
         //say("_UpdateClass: Deleting tree because of no current class");
         // don't show the hierarchy if we're not in a class, either
         treewid._TreeDelete(TREE_ROOT_INDEX, 'c');
      }
   } else {
      //say("_UpdateClass: Deleting tree because of no context");
      // if we have no context, don't show anything
      treewid._TreeDelete(TREE_ROOT_INDEX, 'c');
   }
   treewid._TreeRefresh();
   p_window_id = orig_id;
}

// distinguish between classes, structs, interfaces
static int tbclass_class_type(_str class_name, _str &file_name, int &line_no, _str &type_name)
{
   // need to parse out our outer class name
   outername  := "";
   membername := "";
   tag_split_class_name(class_name, membername, outername);

   // try to look up file_name and type_name for class
   status := 0;
   tag_init_tag_browse_info(auto cm);
   do {
      status = tag_find_tag(membername, "class", outername);
      if (status==0) {
         tag_get_tag_browse_info(cm);
         break;
      }
      status=tag_find_tag(membername, "struct", outername);
      if (status==0) {
         tag_get_tag_browse_info(cm);
         break;
      } 
      status=tag_find_tag(membername, "interface", outername);
      if (status==0) {
         tag_get_tag_browse_info(cm);
         break;
      } 
      status=tag_find_tag(membername, "union", outername);
      if (status==0) {
         tag_get_tag_browse_info(cm);
         break;
      }
      status=tag_find_tag(membername, "enum", outername);
      if (status==0) {
         tag_get_tag_browse_info(cm);
         break;
      }
      status=tag_find_tag(membername, "package", outername);
      if (status==0) {
         tag_get_tag_browse_info(cm);
         break;
      }
      status=tag_find_tag(membername, "task", outername);
      if (status==0) {
         tag_get_tag_browse_info(cm);
         break;
      }
      status=tag_find_tag(membername, "group", outername);
      if (status==0) {
         tag_get_tag_browse_info(cm);
         break;
      }
      status=tag_find_tag(membername, "annotype", outername);
      if (status==0) {
         tag_get_tag_browse_info(cm);
         break;
      }

      tag_lock_context();
      context_id := tag_find_context_iterator(membername, true, true, false, outername);
      if (context_id > 0) {
         tag_get_context_browse_info(context_id, cm);
         file_name = cm.file_name;
         type_name = cm.type_name;
         line_no   = cm.line_no;
      }
      tag_unlock_context();

   } while (false);

   tag_reset_find_tag();
   if (!status) {
      file_name = cm.file_name;
      type_name = cm.type_name;
      line_no   = cm.line_no;
   }

   return status;
}

static void tbclass_add_parents_of(int parent_index, 
                                   _str class_name, 
                                   _str file_name, 
                                   _str cur_tag_file,
                                   typeless tag_files,
                                   VS_TAG_RETURN_TYPE (&visited):[]=null, 
                                   int depth=0)
{
   tag_dbs := cur_tag_file;
   parent_types := "";
   orig_db := tag_current_db();
   parents := cb_get_normalized_inheritance(class_name, 
                                            tag_dbs, tag_files, 
                                            false, "", file_name,
                                            parent_types, false,
                                            visited, depth+1);
   tag_read_db(orig_db);
   while (parents != "") {
      parse parents with auto cur_parent ";" parents;
      parse parent_types with auto cur_type ";" parent_types;
      parse tag_dbs with auto cur_db ";" tag_dbs;
      pic_class := tag_get_bitmap_for_type(tag_get_type_id(cur_type), 0, auto pic_overlay);
      cur_index := _TreeAddItem(parent_index, cur_parent, TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1, pic_overlay, pic_class, (depth < CB_MAX_INHERITANCE_DEPTH)? TREE_NODE_EXPANDED:TREE_NODE_COLLAPSED); 
      status := find_location_of_parent_class(cur_db, cur_parent, auto cur_file, auto cur_line, cur_type);
      info := "";
      if (status == 0) {
         info = cur_db :+ ";" :+ cur_parent";" :+ cur_type ";" cur_file ";" :+ cur_line; 
      } else {
         // this is bad...
         info = cur_db :+ ";" :+ cur_parent ";" :+ cur_type ";;"; 
      }
      _TreeSetUserInfo(cur_index, info);

      if (depth < CB_MAX_INHERITANCE_DEPTH) {
         tbclass_add_parents_of(cur_index, cur_parent, cur_file, cur_db, tag_files, visited, depth+1);
      }
   }
}

static void maybeChangeCaption(int child_wid,_str cur_class = "")
{
   //int formwid = _tbGetActiveClassForm();
   _nocheck _control ctlcurclass;
   caption := "";
   if (cur_class :!= "") {
      caption = cur_class;
   } else {
      caption = child_wid.p_buf_name;
   }
   if (caption :!= ctlcurclass.p_caption) {
      ctlcurclass.p_caption=caption;
   }
   setCaptionVisible();
}

static void _UpdateClassMe(bool AlwaysUpdate=false) {
   int child_wid=_MDIGetActiveMDIChild();
   _UpdateClass2(p_active_form,gClassFormList:[p_active_form],_idle_time_elapsed(),child_wid,AlwaysUpdate);
}
static void _UpdateClass2(int form_wid,CLASS_FORM_INFO &formInfo,long elapsed,int child_wid,bool AlwaysUpdate) 
{
   //say('form_wid='form_wid' '_iswindow_valid(form_wid));
   //say('form name='form_wid.p_name);
   InsertedContext := false;
   treewid := form_wid.ctlmembers;
   _nocheck _control ctlcurclass;

   // is the tree empty, and not forcing update, and not first time here
   isEmpty := (treewid._TreeGetFirstChildIndex(TREE_ROOT_INDEX) < 0);

   // no child windows, then clear everything and bail out
   if (!child_wid) {
      form_wid.ctlcurclass.p_caption="";
      form_wid.ctlcurclass.p_width=0;
      form_wid.ctlmembers._TreeDelete(TREE_ROOT_INDEX, 'c');
      form_wid.ctlclasses._TreeDelete(TREE_ROOT_INDEX, 'c');
      form_wid.ctlmembers._TreeRefresh();
      form_wid.ctlclasses._TreeRefresh();
      return;
   }
   focuswid := _get_focus();
   if (!focuswid) {
      return;
   }
   // if class is not active, bail out
   if ( !tw_is_wid_active(form_wid)){
      return;
   }

   wasEmptyFileNode := false;
   // new buffer or we have switched buffers
   if (formInfo.m_last_buf_id!=child_wid.p_buf_id ) {
      wasEmptyFileNode=true;
   }

   index := TREE_ROOT_INDEX;

   // get file language ID (mode name)
   lang := child_wid.p_LangId;
   buf_name := child_wid.p_buf_name;

   // no current tree index, then bail out?
   curIndex := treewid._TreeCurIndex();

   if ( !wasEmptyFileNode ) {
      wasEmptyFileNode = ( 0==treewid._TreeGetNumChildren(index) );
   }

   orig_wid := p_window_id;
   p_window_id=treewid;
   // get the index of the current member and parent
   OpenIndex := _TreeCurIndex();
   if (OpenIndex > -1) {
      while (_TreeGetDepth(OpenIndex)>0) {
         OpenIndex=_TreeGetParentIndex(OpenIndex);
      }
   }

   _TreeGetInfo(index,auto state);
   OrigNumDown := -1;
   NeedRefresh := false;
   // need update if the buffer has been modified or switched since our last update
   NeedsUpdate := (child_wid.p_LastModified!=formInfo.m_LastModified) || formInfo.m_last_buf_id!=child_wid.p_buf_id;
   NeedsDelete := false;
   if (child_wid.p_buf_id != formInfo.m_last_buf_id ) {
      NeedsUpdate=true;
      NeedsDelete=true;
   }
   if (NeedsUpdate) {
      formInfo.m_selected_LastModified=child_wid.p_LastModified-1;
      //child_wid.p_ModifyFlags&=~MODIFYFLAG_CLASS_SELECTED;
   }
   if (isEmpty || !state) NeedsUpdate=true;
   editor_idle := (elapsed >= def_update_tagging_idle); 
   // if the editor isn't idle, and we aren't forcing an update...stop here
   if (!editor_idle && !AlwaysUpdate) return;
   
   // if the context is not yet up-to-date, then don't update yet
   if (!AlwaysUpdate && !child_wid._ContextIsUpToDate(elapsed)) {
      return;
   }

   // check if the tag database is busy and we can't get a lock.
   dbName := _GetWorkspaceTagsFilename();
   haveDBLock := tag_trylock_db(dbName);
   if (!AlwaysUpdate && !haveDBLock) {
      return;
   }
   // replace the trylock with a guard to handle all function return paths
   se.tags.TaggingGuard sentry;
   status := sentry.lockDatabase(dbName, def_tag_max_list_members_time);
   if (haveDBLock) {
      tag_unlock_db(dbName);
   }
   if (status < 0) {
      return;
   }

   // do not let threads sneak in and modify the context while
   // we are updating the tree.
   sentry.lockContext(false);
   sentry.lockMatches(true);
   _SetTimeout(def_tag_max_list_members_time);
    
   VS_TAG_RETURN_TYPE visited:[];
   filter_flags := SE_TAG_FILTER_ANYTHING;
   has_parents := false;
   cur_class_name := "";
   cur_package_name := "";
   tag_files := null;
   context_id := 0;
   inClassDefinition := false;
   java_workaround_cur_class := false;
   tbclass_get_cur_class(child_wid, cur_class_name, cur_package_name, tag_files, context_id, inClassDefinition,java_workaround_cur_class);
   p_window_id = treewid;
   dumped_context := false;
   if (NeedsUpdate || AlwaysUpdate || cur_class_name :!= formInfo.m_old_class ||
       formInfo.m_java_workaround_cur_class!=java_workaround_cur_class) {
      tbclass_maybe_kill_timer();
      if (NeedsDelete) _TreeDelete(TREE_ROOT_INDEX, "C");
      form_wid.maybeChangeCaption(child_wid,cur_class_name);
      cb_prepare_expand(p_active_form,p_window_id,index);
      _TreeBeginUpdate(index,"","T");
      force_leaf := def_tbc_organize_by_source? 0:-1;
      filter_flags &= (SE_TAG_FILTER_ANY_PROCEDURE|SE_TAG_FILTER_ANY_STRUCT|SE_TAG_FILTER_ANY_DATA);
      p_window_id = child_wid;
      // DJB 04-18-2008 -- allow the current package to be expanded
      // just do not allow it to be recursively expanded
      if (cur_class_name :!= "" /*&& cur_class_name :!= cur_package_name*/) {
         struct VS_TAG_BROWSE_INFO parent_classes[]=null;
         tag_database := tag_current_db();
         tag_push_matches();
         tag_clear_matches();
         context_flags := SE_TAG_CONTEXT_ANYTHING|SE_TAG_CONTEXT_ALLOW_PRIVATE|SE_TAG_CONTEXT_ACCESS_PROTECTED|SE_TAG_CONTEXT_ALLOW_ANONYMOUS;
         child_wid._UpdateContext(true);
         wspace_tagfile := _GetWorkspaceTagsFilename();
         tag_read_db(wspace_tagfile);
         
         num_matches := 0;
         status = child_wid.tag_list_in_class("", cur_class_name, 
                                              0, TREE_ROOT_INDEX, 
                                              tag_files, num_matches, 
                                              def_tag_max_list_members_symbols, 
                                              def_class_flags, context_flags,
                                              false,false,null,null,visited,1);
         prev_class := "";
         cur_class := "";
         cur_parent := TREE_ROOT_INDEX;
         start_index := cur_parent;
         first := true;
         class_order := 1;
         //if (!def_tbc_organize_by_source && !def_tbc_organize_has_been_shut_off) {
         //   def_tbc_organize_by_source = true;
         //}
         tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:true,
                                             filterDuplicateGlobalVars:true,
                                             filterDuplicateClasses:true,
                                             filterAllImports:true,
                                             filterDuplicateDefinitions:false);
                                            
         num_matches = tag_get_num_of_matches();
         for (i:=1; i <= num_matches; i++) {
            if (_CheckTimeout()) break;
            tag_get_match_browse_info(i, auto match_cm);
            parse match_cm.class_name with auto pkg VS_TAGSEPARATOR_package;

            // check if this item is in a duplicate class definition in another copy of this file.
            if ((match_cm.flags & SE_TAG_FLAG_INCLASS) && tag_compare_classes(match_cm.class_name,cur_class_name,child_wid.p_LangCaseSensitive)==0) {
               if (inClassDefinition && !_file_eq(buf_name, match_cm.file_name)) {
                  continue;
               }
            }

            // if were not excluding this class/package
            if (match_cm.type_id != SE_TAG_TYPE_ENUMC && exclusions:[match_cm.class_name] != 1 && exclusions:[pkg] != 1) {
               // check for excluding all outside of workspace
               if ((!def_tbc_filter_outside_wspace) || 
                   (def_tbc_filter_outside_wspace && (match_cm.tag_database :== wspace_tagfile || match_cm.tag_database :== ""))) {
                  // if it's a new class, add a parent node
                  match_class_simplified := stranslate(match_cm.class_name,VS_TAGSEPARATOR_class,VS_TAGSEPARATOR_package);
                  prev_class_simplfiied  := stranslate(prev_class,VS_TAGSEPARATOR_class,VS_TAGSEPARATOR_package);
                  if (match_class_simplified==prev_class_simplfiied) {
                     match_cm.class_name = prev_class;
                  }
                  if (def_tbc_organize_by_source && 
                      match_cm.class_name :!= "" && !(prev_class_simplfiied :== match_class_simplified)) {
                     file_name := "";
                     type_name := "";
                     tag_name_type := "";
                     line_no := 0;
                     // check if the match is from a tag file or the current context
                     if (match_cm.tag_database :!= "") {
                        tag_read_db(match_cm.tag_database);
                        status = tbclass_class_type(match_cm.class_name, file_name, line_no, type_name);
                     } else {
                        // no tag database is found, which means the match came from the current context
                        outername := "";
                        membername := "";
                        tag_split_class_name(match_cm.class_name, membername, outername);
                        int k = tag_find_context_iterator(membername, true, true);
                        done := false;
                        // loop through all the matches for the tag in the current context to see if we can 
                        // find the class definition
                        while (k > 0) {
                           tag_get_detail2(VS_TAGDETAIL_context_type, k, tag_name_type);
                           if (tag_tree_type_is_class(tag_name_type)) {
                              tag_get_detail2(VS_TAGDETAIL_context_line, k, line_no);
                              tag_get_detail2(VS_TAGDETAIL_context_file, k, file_name);
                              tag_get_detail2(VS_TAGDETAIL_context_tag_file, k, match_cm.tag_database);
                              done = true; 
                              break;
                           }
                           k = tag_next_context_iterator(membername, k, true, true);
                        }
                        // if we didn't find it in the current context, then we try to open the right tag file
                        if (!done) {
                           status = -1;
                           k = 0;
                           while (status != 0 && k < tag_files._length()) {
                              tag_read_db(tag_files[k]);
                              match_cm.tag_database = tag_files[k];
                              status = tbclass_class_type(match_cm.class_name, file_name, line_no, type_name); 
                              k++;
                           }
                        }
                     }
                     class_type := "";
                     int leaf, pic_var;
                     tbclass_class_type(match_cm.class_name,file_name,line_no,class_type);
                     if ( class_type == "" ) class_type="class";
                     pic_var = tag_get_bitmap_for_type(tag_get_type_id(class_type), 0, auto pic_overlay);
                     int show_children;
                     if (!def_tbc_expand_all) {
                        // if we aren't expanding everything, still expand the current class
                        if (i == 1) {
                           show_children = 1;
                        } else {
                           show_children = 0;
                        }
                     } else {
                        show_children = 1;
                     }
                     line_no2 := (_str)line_no;
                     info := match_cm.tag_database :+ ";" :+ file_name ";" :+ 
                                 substr("",1,10-length(line_no2),"0") :+ line_no2 :+ ";" :+ class_order++;
                     cur_parent = treewid._TreeAddItem(TREE_ROOT_INDEX, match_cm.class_name, TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1,
                                                       pic_overlay,pic_var,show_children,0,info);
                     treewid._TreeSetInfo(cur_parent, show_children);
                  }
                  int cur_index = tag_tree_insert_fast(treewid,cur_parent, VS_TAGMATCH_match, i, 1, 0, 0, 1, 1);
                  if (cur_index >= 0) {
                     line_no := (_str)match_cm.line_no;
                     info := match_cm.tag_database :+ ";" :+ match_cm.file_name ";" :+
                                 substr("",1,10-length(line_no),"0") :+ line_no; 
                     treewid._TreeSetUserInfo(cur_index, info);
                     // DJB 04-18-2008 - expand nested structs or classes immediately
                     // if def_tbc_expand_structs is set and this is not a package type
                     if (def_tbc_expand_structs && cur_class_name :!= cur_package_name && 
                         (tag_tree_type_is_class(match_cm.type_name) || match_cm.type_id == SE_TAG_TYPE_ENUM)) {
                        treewid.call_event(CHANGE_EXPANDED, cur_index, treewid, ON_CHANGE, 'w');
                        treewid._TreeSetInfo(cur_index, 1);
                     }
                  }
                  prev_class = match_cm.class_name;
               } else {
                  exclusions_outside_wspace:[match_cm.class_name] = 1;
               }
            }
         }
         tag_pop_matches();
         if (num_matches == 0) {
            dumped_context = true;
            tag_tree_insert_context(treewid, index, def_class_flags, 1, 1, 0, 0);
         }
      } else {
         dumped_context = true;
         tag_tree_insert_context(treewid, index, def_class_flags, 1, 1, 0, 0);
      }
      p_window_id = treewid;
      InsertedContext = true;
      formInfo.m_LastModified=child_wid.p_LastModified;
      //child_wid.p_ModifyFlags|=MODIFYFLAG_CLASS_UPDATED;
      formInfo.m_selected_LastModified=child_wid.p_LastModified-1;
      //child_wid.p_ModifyFlags&=~MODIFYFLAG_CLASS_SELECTED;
      formInfo.m_last_buf_id=child_wid.p_buf_id;
      treewid._TreeEndUpdate(index);
      NeedRefresh=true;
   } else if (((child_wid.p_LastModified!=formInfo.m_LastModified) && !AlwaysUpdate)) {
      treewid._TreeSizeColumnToContents(0);
      p_window_id=orig_wid;
      _SetTimeout(0);
      return;
   }
   if (_TreeGetFirstChildIndex(index)>=0 ) {
      // has the selected item in the proc tree been updated
      // or has the current line changed
      EditorLN := child_wid.p_RLine;
      EditorPT := child_wid._QROffset();
      if ( (child_wid.p_LastModified!=formInfo.m_selected_LastModified) 
           || formInfo.m_RLine!=EditorLN ) {
         child_wid._UpdateContext(true,false);

         if (isOutlineViewActive(child_wid) == false) {
            currentWindowID := p_window_id;
            p_window_id = child_wid;

            // if we're between functions, but in a comment, find the next context.
            current_id := tag_current_context(allow_outline_only:true);
            nearest_id := tag_nearest_context(EditorLN, filter_flags, false, true);
            if ((current_id != nearest_id) && _in_comment()) {
               nearest_id = tag_nearest_context(EditorLN, filter_flags, true, true);
            }
            // choose the item that is closest to the current seek position
            if (current_id == 0) current_id = nearest_id;
            if (nearest_id > 0 && current_id > 0 && current_id != nearest_id) {
               curSeekPos := child_wid._QROffset();
               tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, nearest_id, auto nearest_start_seekpos);
               tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, current_id, auto current_start_seekpos);
               if (abs(nearest_start_seekpos-curSeekPos) < abs(current_start_seekpos-curSeekPos)) {
                  current_id = nearest_id;
               }
            }

            p_window_id = currentWindowID;
   
            line_num := 0;
            tag_get_detail2(VS_TAGDETAIL_context_line, current_id, line_num);
            tag_get_detail2(VS_TAGDETAIL_context_name, current_id, auto current_tag_name);
            current_caption := tag_tree_make_caption_fast(VS_TAGMATCH_context, current_id, false, true, true);
            nearLine := 0;
   
            if (state <= 0) {
               _TreeSetInfo(index,1);
            }
   
            nearIndex := -1;
            if (cur_class_name :== "") {
               nearIndex = _TreeSearch(index,"","T",line_num);
            } else {
               line_num_str := (_str)line_num;
               line_num_padded := substr("", 1, 10 - length(line_num_str), "0") :+ line_num_str;
               //concatenate file, line_num padded
               //the tagfile field is USUALLY blank for stuff in the current context
               userinfo :=  ";" :+ child_wid._GetDocumentName() :+ ";"line_num_padded;
               //then do the _TreeSearch
               nearIndex = _TreeSearch(index,"","TP",userinfo);
               // if we didn't find it, try adding the current tag file 
               if (nearIndex <= 0) {
                  userinfo = tag_current_db() ";" :+ child_wid._GetDocumentName() :+ ";"line_num_padded;
                  nearIndex = _TreeSearch(index,"","TP",userinfo);
               }
               if (nearIndex <= 0) {
                  nearIndex = _TreeSearch(index, current_caption, 'T');
                  if (nearIndex <= 0) {
                     nearIndex = _TreeSearch(index, current_tag_name, 'TP');
                  }
               }
            }

            // just in case if we can get closer by matching captions, let's try that
            if (nearIndex > 0 && _TreeGetCaption(nearIndex) != current_caption) {
               captionIndex := _TreeSearch(index, current_caption, 'T');
               if (captionIndex > 0) {
                  captionInfo := _TreeGetUserInfo(captionIndex);
                  if (captionInfo == line_num) {
                     nearIndex = captionIndex;
                  }
               }
            }

            if (nearIndex <= 0) {
               NeedRefresh=true;
               nearIndex = index;
            }
            if (index==0 && nearIndex==0) {
               nearIndex=_TreeGetFirstChildIndex(index);
               if (nearIndex < 0) nearIndex=0;
            }
   
            if (_TreeCurIndex()!=nearIndex) {
               NeedRefresh=true;
               _TreeSetCurIndex(nearIndex);
            }
         } else {
            // find the closest tree item to the current line
            int nearIndex = get_nearest_tree_index_context(treewid, EditorLN, TREE_ROOT_INDEX, EditorPT);
            if ((nearIndex >= 0) && (treewid._TreeCurIndex() != nearIndex)) {
               NeedRefresh = true;
               treewid._TreeSetCurIndex(nearIndex);
            }
         }

         formInfo.m_RLine=EditorLN;
         formInfo.m_selected_LastModified = child_wid.p_LastModified;
      }
   } else {
      cur_index := _TreeCurIndex();
      while (cur_index >= 0 && cur_index!=index) {
         cur_index=_TreeGetParentIndex(cur_index);
      }
      if (cur_index < 0) {
         _TreeSetCurIndex(index);
      }
   }

   // collapse old file node if it was left open
   CurIndex := _TreeCurIndex();
   while (_TreeGetDepth(CurIndex) != 0) {
      CurIndex=_TreeGetParentIndex(CurIndex);
   }
   if (OpenIndex!=CurIndex && OpenIndex!=_TreeGetParentIndex(CurIndex)/* && TaggingSupportedForFileNode(OpenIndex)*/) {
      if (OpenIndex > 0) {
         _TreeSetInfo(OpenIndex,0);
      }
      NeedRefresh=true;
   }
   // expand current file index if autoexpand
   if (_TreeGetParentIndex(CurIndex)==TREE_ROOT_INDEX /*&& TaggingSupportedForFileNode(CurIndex)*/) {
      _TreeSetInfo(CurIndex,1);
   }

   p_window_id = child_wid;
   if (AlwaysUpdate || InsertedContext) {
      // if organize_by_source was turned off by necessity, turn it back on
      // DJB 05/22/2008 -- do not override sort options this way
      //if (!dumped_context) {
      //   def_tbc_sort_by_line = false;
      //   def_tbc_sort_by_name = true;
      //}
      //if (!def_tbc_organize_has_been_shut_off && /*has_parents*/!dumped_context) {
      //   def_tbc_organize_by_source = true;
      //}
      //if (cur_class_name != "") {
      //   if (!def_tbc_organize_by_source) {
      //      def_tbc_sort_by_line = false;
      //      def_tbc_sort_by_name = true;
      //   }
      //}
      if (def_tbc_organize_by_source && !dumped_context) {
         if (def_tbc_sort_class_by_hierarchy) {
            tbclass_sort_by_hierarchy(treewid,TREE_ROOT_INDEX, cur_class_name);
         } else {
            tbclass_sort_by_name(treewid,TREE_ROOT_INDEX);
         }
      }
      if (def_tbc_sort_by_name) {
         if (def_tbc_organize_by_source && !dumped_context) {
            sibling := treewid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
            while (sibling > -1) {
               tbclass_sort_by_name(treewid, sibling, "T");
               sibling = treewid._TreeGetNextSiblingIndex(sibling);
            }
         } else {
            tbclass_sort_by_name(treewid, TREE_ROOT_INDEX, "T");
         }
      } else {
         if (def_tbc_organize_by_source && !dumped_context) {
            sibling := treewid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
            while (sibling > -1) {
               tbclass_sort_by_line(treewid, sibling);
               sibling = treewid._TreeGetNextSiblingIndex(sibling);
            }
         } else {
            tbclass_sort_by_line(treewid, TREE_ROOT_INDEX);
         }
      }
   }
   HierarchyNeedsUpdate := ((cur_class_name :!= formInfo.m_old_class || formInfo.m_java_workaround_cur_class!=java_workaround_cur_class) && editor_idle) || AlwaysUpdate;
   //say('u='HierarchyNeedsUpdate' c='cur_class_name' 'formInfo.m_old_class' j='formInfo.m_java_workaround_cur_class' 'java_workaround_cur_class);
   p_window_id = treewid;
   _UpdateClassHierarchy(child_wid,HierarchyNeedsUpdate, cur_class_name, visited);
   if (AlwaysUpdate || InsertedContext) {
      formInfo.m_old_class = cur_class_name;
      formInfo.m_java_workaround_cur_class=java_workaround_cur_class;
   }
   _TreeSizeColumnToContents(0);
   if (NeedRefresh) {
      _TreeRefresh(); 
   }
   _SetTimeout(0);
   p_window_id=orig_wid;

}
void _UpdateClass(bool AlwaysUpdate = false)
{
   // Class tool window is not support in standard edition
   if (!_haveContextTagging()) {
      return;
   }

   elapsed := _idle_time_elapsed();

   CLASS_FORM_INFO v;
   foreach (auto i => v in gClassFormList) {
      child_wid := i._MDIGetActiveMDIChild();
      _UpdateClass2(v.m_form_wid,gClassFormList:[i],elapsed,child_wid,AlwaysUpdate);
   }
}

_command void tbclass_toggle_auto_expand() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION) 
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return;
   }

   def_tbc_expand_all = !def_tbc_expand_all;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   _UpdateClass(true);
}

_command void tbclass_toggle_expand_structs() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION) 
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return;
   }

   if (!def_tbc_expand_structs) {
      def_tbc_expand_structs = true;
   } else {
      def_tbc_expand_structs = false;
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
   _UpdateClass(true);
}

_command void tbclass_toggle_single_click() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION) 
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return;
   }

   if (!def_tbc_single_click) {
      def_tbc_single_click = true;
   } else {
      def_tbc_single_click = false;
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

_command void tbclass_sort_classes(_str sort_type = "") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION) 
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return;
   }

   if (sort_type :== "name") {
      def_tbc_sort_class_by_hierarchy = false;
   } else if (sort_type :== "hierarchy") {
      def_tbc_sort_class_by_hierarchy = true;
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
   _UpdateClass(true);
}

// recursively populate inner classes found in match sets
static int tbclass_pop_inner_class(int child_wid,int treewid, int index, 
                                   _str name, SETagContextFlags context_flags, 
                                   typeless tag_files,
                                   _str in_file_name="")
{
   // do not let threads sneak in and modify the context while
   // we are updating the tree.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);
    
   num_matches := 0;
   // push a new match set on the stack and find the members of this class
   tag_push_matches();
   typeless visited:[]; visited._makeempty();
   int test = child_wid.tag_list_in_class("",name, 
                                          0, index, 
                                          tag_files, num_matches, 
                                          def_tag_max_list_members_symbols, 
                                          def_class_flags, context_flags,
                                          false,false,null,null,
                                          visited,1);
   tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:true,
                                       filterDuplicateGlobalVars:true,
                                       filterDuplicateClasses:true,
                                       filterAllImports:true,
                                       filterDuplicateDefinitions:false);

   _str wspace_tagfile = _GetWorkspaceTagsFilename();
   for (i:=1; i <= num_matches; i++) {
      tag_get_detail2(VS_TAGDETAIL_match_class, i, auto match_class_name);
      tag_get_detail2(VS_TAGDETAIL_match_tag_file, i, auto match_tag_database);
      tag_get_detail2(VS_TAGDETAIL_match_flags, i, auto match_class_flags);
      if (in_file_name != "" && (match_class_flags & SE_TAG_FLAG_INCLASS)) {
         tag_get_detail2(VS_TAGDETAIL_match_file, i, auto match_class_file);
         if (!_file_eq(match_class_file, in_file_name)) continue;
      }
      parse match_class_name with auto pkg VS_TAGSEPARATOR_package;
      if (exclusions:[match_class_name] != 1 && exclusions:[pkg] != 1) {
         if (!def_tbc_filter_outside_wspace || 
             (match_tag_database :== wspace_tagfile || match_tag_database :== "")) {
            if (match_class_name :== name) {
               int cur_index = tag_tree_insert_fast(treewid,index, VS_TAGMATCH_match, i, 1, 0, 0, 1, 1);
               if (cur_index >= 0) {
                  tag_get_detail2(VS_TAGDETAIL_match_file, i, auto match_file_name); 
                  tag_get_detail2(VS_TAGDETAIL_match_line, i, auto match_line_no); 
                  _str line_no = (_str)match_line_no;
                  info :=  match_tag_database :+ ";" :+ match_file_name ";" :+
                              substr("",1,10-length(line_no),"0") :+ line_no; 
                  treewid._TreeSetUserInfo(cur_index, info);
               }
            }
         } else {
            exclusions_outside_wspace:[match_class_name] = 1;
         }
      }
   }
   // pop the matches off and return
   tag_pop_matches();
   return(0);
}

_command void tbclass_sort_functions(_str sort_type = "") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION) 
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return;
   }

   if (sort_type :== "name") {
      def_tbc_sort_by_name = true;
   } else if (sort_type :== "line") {
      def_tbc_sort_by_name = false;
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
   _UpdateClass(true);
}

//////////////////////////////////////////////////////////////////////////////
// Goto the definition of the currently selected tag in the symbol browser
// Translates (proto) to proc, constr, destr, or function, until it
// finds a match.
//
_command int tbclass_goto_proc() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION) 
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // Locate the currently selected item in the tree control
   tbclass_maybe_kill_timer();
   treewid := _tbGetActiveClassMembersTreeWid();
   if (!treewid) {
      return INVALID_OBJECT_HANDLE_RC;
   }
   index   := treewid._TreeCurIndex();
   if (!index) {
      return BT_RECORD_NOT_FOUND_RC;
   }

   // Set focus to the MDI child so the current MDI window gets
   // set. Then edit() will open the file in the expected MDI frame.
   child_wid := _MDIGetActiveMDIChild();
   if (child_wid) {
      child_wid._set_focus();
   }

   status := tbclass_members_get_info(child_wid, treewid, index, auto cm);
   if (status < 0) {
      return BT_RECORD_NOT_FOUND_RC;
   }

   // Locate the matching proc for this symbol
   tag_get_tagfile_browse_info(cm);
   tag_push_matches();
   maybe_convert_proto_to_proc(cm, true);
   tag_remove_duplicate_symbol_matches();
   match_id := tag_select_symbol_match(cm);
   tag_pop_matches();
   if (match_id < 0) {
      return match_id;
   }

   // And jump to it
   return push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
}

//////////////////////////////////////////////////////////////////////////////
// Goto the declaration for the currently selected tag in the symbol browser
// Translates type_name (proc) to (proto).
//
_command int tbclass_goto_decl() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION) 
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // Locate the currently selected item in the tree control
   tbclass_maybe_kill_timer();
   treewid := _tbGetActiveClassMembersTreeWid();
   if (!treewid) {
      return INVALID_OBJECT_HANDLE_RC;
   }
   index   := treewid._TreeCurIndex();
   if (!index) {
      return BT_RECORD_NOT_FOUND_RC;
   }

   // Set focus to the MDI child so the current MDI window gets
   // set. Then edit() will open the file in the expected MDI frame.
   child_wid := _MDIGetActiveMDIChild();
   if (child_wid) {
      child_wid._set_focus();
   }

   status := tbclass_members_get_info(child_wid, treewid, index, auto cm);
   if (status < 0) {
      return BT_RECORD_NOT_FOUND_RC;
   }

   // locate the prototype corresponding to this symbol
   if (cm.type_name!="procproto" && cm.type_name!="proto" && tag_tree_type_is_func(cm.type_name)) {
      tag_get_tagfile_browse_info(cm);
      search_arguments :=  VS_TAGSEPARATOR_args:+cm.arguments;
      if (tag_find_tag(cm.member_name, "proto", cm.class_name, search_arguments)==0) {
         tag_get_tag_browse_info(cm);
      } else if (tag_find_tag(cm.member_name, "procproto", cm.class_name, search_arguments)==0) {
         tag_get_tag_browse_info(cm);
      } else {
         // first look for a forward declaration
         found_forward_decl := false;
         VS_TAG_BROWSE_INFO inline_cm = null;
         status = tag_find_equal(cm.member_name, case_sensitive:true, cm.class_name);
         while (!status) {
            tag_get_tag_browse_info(auto proto_cm);
            if (proto_cm.flags & SE_TAG_FLAG_FORWARD) {
               cm = proto_cm;
               found_forward_decl = true;
               break;
            } else if (proto_cm.flags & SE_TAG_FLAG_INLINE) {
               inline_cm = proto_cm;
            }
            status = tag_next_equal(case_sensitive:true, cm.class_name);
         }
         if (!found_forward_decl && inline_cm != null) {
            cm = inline_cm;
         }
      }
      tag_reset_find_tag();
   }

   // And jump to it
   return push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
}

static void tbclass_sort_by_line(int treewid, int index)
{
   if (index > -1) {
      _str info = treewid._TreeGetUserInfo(index);
      treewid._TreeSortUserInfo(index,'NT');
   } else {
      return;
   }
/*   int sibling = treewid._TreeGetNextSiblingIndex(index);
   if (sibling > -1) {
      tbclass_sort_by_line(treewid, sibling);
   }*/
}

_command void tbclass_quick_refactor(_str operation = "") name_info(','VSARG2_EDITORCTL|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveRefactoring()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      return;
   }

   // find the tag name, file and line number
   treewid := _tbGetActiveClassMembersTreeWid();
   index := treewid._TreeCurIndex();
   int child_wid=_MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }
   tbclass_members_get_info(child_wid,treewid, index, auto cm);

   // trigger the requested refactoring
   switch (operation) {
   case "quick_encapsulate_field":
      refactor_start_quick_encapsulate(cm);
      break;
   case "quick_rename":
      refactor_quick_rename_symbol(cm);
      break;
   case "quick_modify_params":
      if (cm.type_name == "proto" || cm.type_name == "procproto") {
         if (!refactor_convert_proto_to_proc(cm)) {
            _message_box("Cannot perform quick modify parameters refactoring because ":+
                         "the function definition could not be found", "Quick Modify Parameters");
            break;
         }
      }
      refactor_start_quick_modify_params(cm);
      break;
   }
   _UpdateClass(true);
}

_command void tbclass_refactor(_str operation = "") name_info(','VSARG2_EDITORCTL|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION) 
{
   if (!_haveRefactoring()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      return;
   }

   // find the tag name, file and line number
   treewid := _tbGetActiveClassMembersTreeWid();
   index := treewid._TreeCurIndex();
   int child_wid=_MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }
   tbclass_members_get_info(child_wid,treewid, index, auto cm);
   int status = tag_complete_browse_info(cm);
   if(status < 0) return;

   // trigger the requested refactoring
   switch (operation) {
   case "extract_super_class":
      refactor_extract_class_symbol(cm,true);
      break;
   case "extract_class":
      refactor_extract_class_symbol(cm,false);
      break;
   case "encapsulate":
      refactor_start_encapsulate(cm);
      break;
   case "quick_encapsulate_field":
      refactor_start_quick_encapsulate(cm);
      break;
   case "move_field":
      refactor_start_move_field(cm);
      break;
   case "standard_methods":
      refactor_start_standard_methods(cm);
      break;
   case "rename":
      refactor_rename_symbol(cm);
      break;
   case "quick_rename":
      refactor_quick_rename_symbol(cm);
      break;
   case "global_to_field":
      refactor_global_to_field_symbol(cm);
      break;
   case "static_to_instance_method":
      refactor_static_to_instance_method_symbol(cm);
      break;
   case "move_method":
      refactor_move_method_symbol(cm);
      break;
   case "pull_up":
      refactor_pull_up_symbol(cm);
      break;
   case "push_down":
      refactor_push_down_symbol(cm);
      break;

   case "modify_params":
      if (cm.type_name == "proto" || cm.type_name == "procproto") {
         if (!refactor_convert_proto_to_proc(cm)) {
            _message_box("Cannot perform modify parameters refactoring because ":+
                         "the function definition could not be found",
                         "Modify Parameters");
            break;
         }
      }
      refactor_start_modify_params(cm);
      break;

   case "quick_modify_params":
      if (cm.type_name == "proto" || cm.type_name == "procproto") {
         if (!refactor_convert_proto_to_proc(cm)) {
            _message_box("Cannot perform quick modify parameters refactoring because ":+
                         "the function definition could not be found",
                         "Quick Modify Parameters");
            break;
         }
      }
      refactor_start_quick_modify_params(cm);
      break;
   }
   _UpdateClass(true);
}

_command void tbclass_references() name_info(','VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      return;
   }

   treewid := _tbGetActiveClassMembersTreeWid();
   index := treewid._TreeCurIndex();
   int child_wid=_MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }
   tbclass_members_get_info(child_wid,treewid, index, auto cm);
   // check if the current workspace tag file or extension specific
   // tag file requires occurrences to be tagged.
   if (_MaybeRetagOccurrences(cm.tag_database) == COMMAND_CANCELLED_RC) {
      return;
   }

   int formwid = _GetReferencesWID();
   if (!formwid) {
      formwid=activate_tool_window("_tbtagrefs_form");
   }
   if (formwid) {
      _ActivateReferencesWindow();
   }

   int f = _GetReferencesWID();
   if (f && cm.member_name != "") {
      refresh_references_tab(cm,true);
   }
}

_command void tbclass_props(int tab_number=0) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging");
      return;
   } else if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Class tool window");
      return;
   }

   treewid   := _tbGetActiveClassMembersTreeWid();
   index     := treewid._TreeCurIndex();
   child_wid := _MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }
   tbclass_members_get_info(child_wid,treewid, index, auto cm);

   f := activate_tool_window("_tbsymbol_props_form");
   cb_refresh_property_view(cm,f);
}
_command void tbclass_args() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging");
      return;
   } else if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Class tool window");
      return;
   }

   treewid   := _tbGetActiveClassMembersTreeWid();
   index     := treewid._TreeCurIndex();
   child_wid := _MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }
   tbclass_members_get_info(child_wid,treewid, index, auto cm);
   
   f := activate_tool_window("_tbsymbol_args_form");
   cb_refresh_arguments_view(cm,f);
}

_command void tbclass_calltree() name_info(','VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      return;
   }

   treewid   := _tbGetActiveClassMembersTreeWid();
   index     := treewid._TreeCurIndex();
   child_wid := _MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }
   tbclass_members_get_info(child_wid,treewid, index, auto cm);
   // check if the current workspace tag file or extension specific
   // tag file requires occurrences to be tagged.
   if (_MaybeRetagOccurrences(cm.tag_database) == COMMAND_CANCELLED_RC) {
      return;
   }

   formwid := _tbGetActiveSymbolCallsForm();
   if (!formwid) {
      formwid=activate_tool_window("_tbsymbolcalls_form");
   }

   f := _tbGetActiveSymbolCallsForm();
   if (f && cm.member_name != "") {
      cb_refresh_calltree_view(cm,f);
   }
}

_command void tbclass_callers() name_info(','VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      return;
   }

   treewid   := _tbGetActiveClassMembersTreeWid();
   index     := treewid._TreeCurIndex();
   child_wid := _MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }
   tbclass_members_get_info(child_wid,treewid, index, auto cm);
   // check if the current workspace tag file or extension specific
   // tag file requires occurrences to be tagged.
   if (_MaybeRetagOccurrences(cm.tag_database) == COMMAND_CANCELLED_RC) {
      return;
   }

   formwid := _tbGetActiveSymbolCallersForm();
   if (!formwid) {
      formwid=activate_tool_window("_tbsymbolcallers_form");
   }

   f := _tbGetActiveSymbolCallersForm();
   if (f && cm.member_name != "") {
      cb_refresh_callertree_view(cm,f);
   }
}


// retrieve important tag info from current index in the class hierarchy pane
static int tbclass_classes_get_info(int treewid, int index, VS_TAG_BROWSE_INFO & cm, bool quiet=false)
{
   tag_init_tag_browse_info(cm);
   if (index < 0) return INVALID_ARGUMENT_RC;
   _str line_no, info = treewid._TreeGetUserInfo(index);
   if (info == "" && index == 1) {
      info = treewid._TreeGetUserInfo(TREE_ROOT_INDEX);
   }
   if (info == null || info == "") {
      if (!quiet) message("Class not found.");
      return BT_RECORD_NOT_FOUND_RC;
   }

   parse info with cm.tag_database ";" cm.class_name ";" cm.type_name ";" cm.file_name ";" line_no;
   if (line_no != "" && isinteger(line_no)) {
      cm.line_no = (int)line_no;
   } else {
      cm.line_no = 0;
   }

   membername := "";
   outername := "";
   tag_split_class_name(cm.class_name, membername, outername);

   // broaden scope of search for class name
   status := tag_read_db(cm.tag_database);
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   VS_TAG_RETURN_TYPE visited:[];
   _str errorArgs[];
   editorctl_wid := p_window_id;
   if (!_isEditorCtl()) {
      editorctl_wid = _mdi.p_child;
   }
   tag_files := editorctl_wid.tags_filenamea(editorctl_wid.p_LangId);
   status = editorctl_wid._Embeddedparse_return_type(errorArgs, tag_files, membername, outername, editorctl_wid.p_buf_name, cm.class_name, editorctl_wid._LanguageInheritsFrom("java") || editorctl_wid._LanguageInheritsFrom("cs"), rt, visited);
   if (status == 0) {
      cm.file_name = rt.filename;
      cm.line_no   = rt.line_number;
      if (rt.taginfo != null && rt.taginfo != "") {
         tag_get_info_from_return_type(rt, cm);
      }
      return 0;
   }

   cm.class_name  = outername;
   cm.member_name = membername;
   status = tag_read_db(cm.tag_database);
   if (status >= 0) {
      status = tag_find_closest(membername, cm.file_name, cm.line_no);
      tag_reset_find_tag();
      if (status < 0) {
         cm.tag_database = "";
         cm.class_name  = outername;
         cm.member_name = membername;
         return 0;
      }
      tag_get_detail(VS_TAGDETAIL_name, cm.member_name);
      tag_get_detail(VS_TAGDETAIL_class_name, cm.class_name);
      tag_get_detail(VS_TAGDETAIL_type, cm.type_name);
      tag_get_detail(VS_TAGDETAIL_return, cm.return_type);
   }

   // success
   return 0;
}

//TODO: make this returns something
// retrieve important tag info from current index in the members pane
static int tbclass_members_get_info(int child_wid,int treewid, int index, VS_TAG_BROWSE_INFO & cm, bool quiet=false)
{
   tag_init_tag_browse_info(cm);
   if (index < 0) {
      return INVALID_ARGUMENT_RC;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // if this is the outline view, the=n the tree node's user data is the tag ID
   if (isOutlineViewActive(child_wid) == true) {
      int ctxID = treewid._TreeGetUserInfo(index) + 1;
      tag_get_context_info(ctxID, cm);
      return 0;
   }

   caption := treewid._TreeGetCaption(index);
   info    := treewid._TreeGetUserInfo(index);
   if (info == "") {
      return STRING_NOT_FOUND_RC;
   }
   line_no := null;
   class_order := "";
   if (isinteger(info)) {
      line_no = info;
      cm.file_name = child_wid.p_buf_name;
   } else {
      parse info with cm.tag_database ";" cm.file_name ";" line_no ";" class_order ";";
      // unpad the line number
      while (length(line_no)>1 && substr(line_no,1,1) :== "0") {
         line_no = substr(line_no,2,-1);
      }
   }
   cm.line_no = (int)line_no;
   search_name := "";
   // if its a function just grab the name
   if (pos("(", caption)) {
      parse caption with search_name "(";
   } else {
      parse caption with search_name "\t";
   }
   // special case here for operator
   if (pos("operator", search_name)) {
      parse search_name with auto operator " " search_name;
   } else {
      if (pos("=", search_name)) {
         parse search_name with search_name "=";
      }
   }
   membername := "";
   outername := "";
   tag_split_class_name(search_name, membername, outername);
   // special case here for objective c method with parameters
   if (membername == "" && outername != "") {
      membername = outername;
   }

   // check if the member was added as a match from a tag file or the current context
   if (cm.tag_database :!= "") {
      tag_read_db(cm.tag_database);
      status := tag_find_closest(membername, cm.file_name, cm.line_no);
      tag_reset_find_tag();
      if (status < 0) {
         //TODO: change this to fill in some stuff...not just return
         return 0;
      }
      tag_get_detail(VS_TAGDETAIL_name, cm.member_name);
      tag_get_detail(VS_TAGDETAIL_class_name, cm.class_name);
      tag_get_detail(VS_TAGDETAIL_type, cm.type_name);
      tag_get_detail(VS_TAGDETAIL_return, cm.return_type);
      tag_get_detail(VS_TAGDETAIL_class_parents, cm.class_parents);
   } else {
      // if no tag file, update the context and try to find the right match
      child_wid._UpdateContext(true);

      i := tag_find_context_iterator(membername, true, true);
      if (i > 0) {
         while (i > 0) {
            int context_line;
            _str context_file;
            tag_get_detail2(VS_TAGDETAIL_context_line, i, context_line);
            tag_get_detail2(VS_TAGDETAIL_context_file, i, context_file);
            // make sure the line number and file name of the member match what we find in the context
            if (context_line == cm.line_no && _file_eq(context_file,cm.file_name)) {
               tag_get_context_info(i, cm);
//               tag_browse_info_dump(cm);
               break;
            }
            i = tag_next_context_iterator(membername, i, true, true);
         }
      } else {
         // ok we didn't find the context...possibly because the buffer is off
         // let's go with what we have...
         cm.member_name = membername;
      }
   }
   return 0;
}

_command void tbclass_set_breakpoint() name_info(","VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }

   treewid := _tbGetActiveClassMembersTreeWid();
   index := treewid._TreeCurIndex();
   int child_wid=_MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }
   tbclass_members_get_info(child_wid,treewid, index, auto cm);
   debug_set_breakpoint_on_tag(cm);
}

static void tbclass_sort_by_hierarchy(int treewid, int index, _str cur_class)
{
   cur_node := treewid._TreeGetFirstChildIndex(index);
   int first_node = cur_node;
   typeless node_info:[];
   while (cur_node > -1) {
      // we want to sort JUST on the hierarchy order 
      // so save the full info in a hashtable
      _str info = treewid._TreeGetUserInfo(cur_node);
      node_info:[treewid._TreeGetCaption(cur_node)] = info;
      _str tag_file, filename, line_no, class_order;
      parse info with tag_file ";" filename ";" line_no ";" class_order ";";
      // then set the info to JUST the hierarchy order
      treewid._TreeSetUserInfo(cur_node, class_order);
      cur_node = treewid._TreeGetNextSiblingIndex(cur_node);
   }
   // now do the sort
   treewid._TreeSortUserInfo(index, 'N');
   cur_node = treewid._TreeGetFirstChildIndex(index);
   while (cur_node > -1) {
      // now grab the full info and put it back
      _str info = node_info:[treewid._TreeGetCaption(cur_node)];
      treewid._TreeSetUserInfo(cur_node, info);
      cur_node = treewid._TreeGetNextSiblingIndex(cur_node);
   }
}

static void tbclass_sort_by_name(int treewid, int index, _str recursive_option="")
{
   if (index > -1) {
      treewid._TreeSortCaption(index,"i":+recursive_option,'N');
   }
}

_command void tbclass_toggle_workspace_filter() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return;
   }

   def_tbc_filter_outside_wspace = !def_tbc_filter_outside_wspace;
   if (!def_tbc_filter_outside_wspace) {
      exclusions_outside_wspace._makeempty();
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
   _UpdateClass(true);
}

_command tbclass_include_all_above() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   tbclass_filter_all_above(-1, true);
}

_command tbclass_include_everything() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   def_tbc_filter_outside_wspace = false;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   tbclass_filter_all_above(TREE_ROOT_INDEX, true, false, true);
}

_command tbclass_include_class() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   tbclass_filter_class(true);
}

_command tbclass_include_pkg() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   tbclass_filter_class(true, true);
}

_command tbclass_exclude_pkg() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   tbclass_filter_class(false, true);
}

_command void tbclass_filter_all_above(int index = -1, 
                                       bool include_class = false, 
                                       bool pkg = false, 
                                       bool all = false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return;
   }

   _nocheck _control ctlmembers, ctlclasses;

   f := _tbGetActiveClassForm();
   if (!f) {
      messageNwait("_tbclass_form" nls("not found"));
      return;
   }
   int child_wid=_MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }
   index = f.ctlclasses._TreeCurIndex();
   if (all) {
      // if we are including everything, empty out the exclusion lists and update
      exclusions._makeempty();
      exclusions_outside_wspace._makeempty();
      _UpdateClass(true);
      return;
   }
   
   wid := f.ctlclasses;
   tbclass_classes_get_info(wid, index, auto cm);
   _str qual_name = cm.member_name;
   if (cm.class_name :!= "") {
      qual_name = cm.class_name :+ VS_TAGSEPARATOR_package :+ cm.member_name;
   }
   // exclude the class at the index
   item_to_filter := ctlclasses._TreeGetCaption(index);
   if (include_class) {
      //exclusions:[item_to_filter] = 0;
      exclusions._deleteel(item_to_filter);
      // they have chosen to manually include a class which is excluded via cb_filter_outside_wspace
      // let them do it, and shut off cb_filter_outside_wspace
      if (exclusions_outside_wspace:[item_to_filter] == 1) {
         exclusions_outside_wspace._makeempty();
         def_tbc_filter_outside_wspace = false;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
   } else {
      exclusions:[item_to_filter] = 1;
   }
   tag_dbs := "";
   parent_types := "";
   typeless tag_files;
   tag_files = tags_filenamea(child_wid.p_LangId);
   orig_db := tag_current_db();
   // include or exclude all the parents of the current index
   VS_TAG_RETURN_TYPE visited:[];
   _str parents = cb_get_normalized_inheritance(qual_name, tag_dbs, tag_files, false, "", cm.file_name, parent_types, false, visited);
   tag_read_db(orig_db);
   tbclass_filter_parents(child_wid,parents, include_class, tag_files, tag_dbs, visited);
   _UpdateClass(true);
}

static void tbclass_filter_parents(int child_wid,_str parents, 
                                   bool include_class, 
                                   typeless tag_files, 
                                   _str dbs,
                                   VS_TAG_RETURN_TYPE (&visited):[]=null, 
                                   int depth=0)
{
   _str cur_parent, cur_db;
   while (parents != "") {
      // exclude the first class in the list...
      parse parents with cur_parent ";" parents;
      parse dbs with cur_db ";" dbs;
      if (include_class) {
         exclusions._deleteel(cur_parent);
         // they have chosen to manually include a class which is excluded via cb_filter_outside_wspace
         // let them do it, and shut off cb_filter_outside_wspace
         if (exclusions_outside_wspace:[cur_parent] == 1) {
            exclusions_outside_wspace._makeempty();
            def_tbc_filter_outside_wspace = false;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
      } else {
         exclusions:[cur_parent] = 1;
      }
      tag_dbs := "";
      parent_types := "";
      _str cur_file, type;
      typeless cur_line;
      int status = find_location_of_parent_class(cur_db, cur_parent, cur_file, cur_line, type);
      orig_db := tag_current_db();
      // find all the parents of this class
      _str next_parents = child_wid.cb_get_normalized_inheritance(cur_parent, 
                                                                  tag_dbs, tag_files, 
                                                                  false, "", 
                                                                  cur_file, 
                                                                  parent_types, false,
                                                                  visited, depth+1);

      tag_read_db(orig_db);
      // exclude all the parents of this class 
      tbclass_filter_parents(child_wid,next_parents, include_class, tag_files, tag_dbs, visited, depth+1);
   }
}

_command tbclass_filter_class(bool include_class = false, bool pkg = false) name_info(","VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   _nocheck _control ctlmembers, ctlclasses;

   f := _tbGetActiveClassForm();
   if (!f) {
      messageNwait("_tbclass_form" nls("not found"));
      return("");
   }

   k := f.ctlclasses._TreeCurIndex();
   _str item_to_filter;
   caption := _TreeGetCaption(k);
   if (pkg) {
      parse caption with item_to_filter VS_TAGSEPARATOR_package;
   } else {
      item_to_filter = caption;
   }
   if (include_class) {
      exclusions._deleteel(item_to_filter);
      if (exclusions_outside_wspace:[item_to_filter] == 1) {
         exclusions_outside_wspace._makeempty();
         def_tbc_filter_outside_wspace = false;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
   } else {
      exclusions:[item_to_filter] = 1;
   }
   _UpdateClass(true);
}

static void TraverseAndColorHierarchy(int index)
{
   int treewid=ctlclasses;
   focuswid := _get_focus();
   if (!focuswid) {
      return;
   }
   caption := treewid._TreeGetCaption(index);
   _str class_name = caption;
   _str pkg;
   parse caption with pkg VS_TAGSEPARATOR_package;
   state := bm1 := bm2 := flags := 0;
   treewid._TreeGetInfo(index,state,bm1,bm2,flags);
   if (exclusions:[class_name] == 1 || exclusions:[pkg] == 1 || exclusions_outside_wspace:[class_name] == 1) {
      treewid._TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_GRAYTEXT);
   } else if (def_tbc_filter_outside_wspace && exclusions_outside_wspace:[class_name] != 1) {
      // well if it doesn't have any members visible to the current class then
      // it won't have been marked excluded in _UpdateClass...so find out if that's the case
      tbclass_classes_get_info(treewid, index, auto cm);
      _str wspace_tagfile = _GetWorkspaceTagsFilename();
      if (cm.tag_database :!= wspace_tagfile) {
         exclusions_outside_wspace:[class_name] = 1;
         treewid._TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_GRAYTEXT);
      }
   } else {
      treewid._TreeSetInfo(index,state,bm1,bm2,flags&~TREENODE_GRAYTEXT);
   }
   child_index := treewid._TreeGetFirstChildIndex(index);
   if (child_index > -1) {
      TraverseAndColorHierarchy(child_index);
   }
   sibling_index := treewid._TreeGetNextSiblingIndex(index);
   if (sibling_index > -1) {
      TraverseAndColorHierarchy(sibling_index);
   }
}

_command void tbclass_organize_by_source() name_info(","VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION) 
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return;
   }

   def_tbc_organize_by_source = !def_tbc_organize_by_source;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   _UpdateClass(true);
}

_command void tbclass_add_member(bool dovar = false) name_info(","VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveRefactoring()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      return;
   }

   wid := _tbGetActiveClassMembersTreeWid();
   if (!wid) {
      messageNwait(TBCLASS_FORM nls("not found"));
      return;
   }
   index := wid._TreeCurIndex();
   int child_wid=_MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }
   tbclass_members_get_info(child_wid,wid, index, auto cm);
   _c_add_member(cm,dovar);
}

_command void tbclass_override_method() name_info(","VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveRefactoring()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      return;
   }

   wid := _tbGetActiveClassMembersTreeWid();
   if (!wid) {
      messageNwait(TBCLASS_FORM nls("not found"));
      return;
   }

   k := wid._TreeCurIndex();
   int child_wid=_MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }
   tbclass_members_get_info(child_wid,wid, k, auto cm);

   // check if there is a load-tags function, if so, bail out
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      _message_box(nls("Can not locate source code for %s.",cm.file_name));
      return;
   }

   orig_view_id := temp_view_id := 0;
   int buf_id=_BufEdit(cm.file_name,"",false,"",true);
   if (buf_id<0) {
      if (buf_id==FILE_NOT_FOUND_RC) {
         _message_box(nls("File '%s' not found",cm.file_name));
      } else {
         _message_box(nls("Unable to open '%s'",cm.file_name)".  "get_message(buf_id));
      }
      return;
   }
   _open_temp_view("",temp_view_id,orig_view_id,"+bi "buf_id);
   if (_QReadOnly()) {
      _message_box(nls("File '%s' is read only",p_buf_name));
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      return;
   }
   int status=_cb_goto_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no,true);
   if (status) {
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      return;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   if (context_id<0) {
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      _message_box("Unable to find this class");
      return;
   }
   scope_seekpos := 0;
   tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, scope_seekpos);
   _GoToROffset(scope_seekpos);
   override_method(false,cm,!_LanguageInheritsFrom("c"));
   if (temp_view_id) {
      _delete_temp_view(temp_view_id);
   }
}

_command void tbclass_delete_member() name_info(","VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveRefactoring()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      return;
   }

   wid := _tbGetActiveClassMembersTreeWid();
   if (!wid) {
      messageNwait(TBCLASS_FORM nls("not found"));
      return;
   }

   k := wid._TreeCurIndex();
   int child_wid=_MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }
   tbclass_members_get_info(child_wid,wid, k, auto cm);

   // check if there is a load-tags function, if so, bail out
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      _message_box(nls("Can not locate source code for %s.",cm.file_name));
      return;
   }

   orig_view_id := temp_view_id := 0;
   buf_id := _BufEdit(cm.file_name,"",false,"",true);
   if (buf_id<0) {
      if (buf_id==FILE_NOT_FOUND_RC) {
         _message_box(nls("File '%s' not found",cm.file_name));
      } else {
         _message_box(nls("Unable to open '%s'",cm.file_name)".  "get_message(buf_id));
      }
      return;
   }
   _open_temp_view("",temp_view_id,orig_view_id,"+bi "buf_id);
   if (_QReadOnly()) {
      _message_box(nls("File '%s' is read only",p_buf_name));
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      return;
   }
   status := _cb_goto_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no,true);
   if (status) {
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      return;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   context_id := tag_current_context();
   if (context_id<0) {
      _delete_temp_view(temp_view_id);activate_window(orig_view_id);
      _message_box("Unable to find this class");
      return;
   }

   scope_seekpos := 0;
   tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, scope_seekpos);
   _GoToROffset(scope_seekpos);
   _c_delete_tag(context_id);

   if (temp_view_id) {
      _delete_temp_view(temp_view_id);
   }
}

_command void tbclass_jrefactor(_str params = "") name_info(','VSARG2_EDITORCTL|VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveRefactoring()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      return;
   }

   // get the tag info
   wid := _tbGetActiveClassMembersTreeWid();
   if (!wid) {
      messageNwait(TBCLASS_FORM nls("not found"));
      return;
   }

   index := wid._TreeCurIndex();
   int child_wid=_MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }
   tbclass_members_get_info(child_wid,wid, index, auto cm);

   // trigger the requested refactoring
   switch (params) {
   case "add_import":
      refactor_add_import(false, cm, child_wid.p_buf_name);
      break;
   case "goto_import":
      refactor_goto_import(false, cm, child_wid.p_buf_name);
      break;
   case "organize_imports_options" :
      refactor_organize_imports_options();
      break;
   }
}

// called from rclick menu to jump to a tag in the symbol browser
_command void tbclass_show_tag_in_cb(_str pane = "") name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Symbols tool window");
      return;
   }

   child_wid := _MDIGetActiveMDIChild();
   if (!child_wid) {
      messageNwait("File not open");
      return;
   }

   tag_init_tag_browse_info(auto cm);
   if (pane :== "m") {
      tbclass_members_get_info(child_wid,_tbGetActiveClassMembersTreeWid(), ctlmembers._TreeCurIndex(), cm);
   } else if (pane :== "c"){
      tbclass_classes_get_info(_tbGetActiveClassHierarchyTreeWid(), ctlclasses._TreeCurIndex(), cm);
   }
   tag_show_in_class_browser(cm);
}

void ctlmembers.rbutton_up()
{
   // kill the refresh timer, prevents delays before the menu comes
   // while the refreshes are finishing up.
   tbclass_maybe_kill_timer();
   index := find_index("_tbclass_members_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   child_wid := _MDIGetActiveMDIChild();
   if (!child_wid) {
      _message_box("File not open");
      return;
   }

   menu_handle := p_active_form._menu_load(index,'P');
   has_parents := true;
   struct VS_TAG_BROWSE_INFO parent_classes[] = null;
   typeless tag_files = tags_filenamea(child_wid.p_LangId);
   tag_database := "";
   child_wid._UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   cur_class_name := child_wid.current_class(false);
   cur_package_name := child_wid.current_package(false);
   isjava := (child_wid.p_LangId :== "java");
   // make sure we have the package along with the full class name
   if (isjava && (cur_class_name :== "" || cur_class_name :== cur_package_name)) {
      file_name := _strip_filename(child_wid.p_buf_name, 'P');
      parse file_name with cur_class_name ".java";
      if (cur_class_name :!= "" && cur_package_name :!= cur_class_name) {
         cur_class_name = cur_package_name :+ VS_TAGSEPARATOR_package :+ cur_class_name;
      }
   }
   tbclass_members_get_info(child_wid, ctlmembers.p_window_id, ctlmembers._TreeCurIndex(), auto cm);
   if (ctlmembers._TreeGetFirstChildIndex(TREE_ROOT_INDEX) > 0 &&  cm.member_name :!= "") {
      int output_menu_handle,output_menu_pos;
      int status = _menu_find(menu_handle,"set_breakpoint",output_menu_handle,output_menu_pos);
      _menu_insert(output_menu_handle, ++output_menu_pos,MF_ENABLED, 
                        "Show " cm.member_name " in Symbol browser", "tbclass_show_tag_in_cb m");
   } else {
      _menu_set_state(menu_handle, "goto_def", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "goto_decl", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "refs", MF_GRAYED, 'C');
   }
   if (cm.type_name :== "class") {
      status := _menu_find(menu_handle,"organize_imports",auto output_menu_handle,auto output_menu_pos);
      if (cm.language :== "c") {
         _menu_insert(output_menu_handle,++output_menu_pos,MF_ENABLED,
                      "Add Member Function...","tbclass_add_member 0","",
                      "help class",
                      "Adds a member function to this class");
         _menu_insert(output_menu_handle,++output_menu_pos,MF_ENABLED,
                      "Add Member Variable...","tbclass_add_member 1","",
                      "help class",
                      "Adds a member function to this class");
         _menu_insert(output_menu_handle,++output_menu_pos,MF_ENABLED,
                      "Override Virtual Function...","tbclass_override_method","",
                      "help class",
                      "Adds a function which overrides a base class virtual method");
      } else if (cm.language :== "java" || cm.language == "cs" || cm.language == "e") {
         _menu_insert(output_menu_handle,++output_menu_pos,MF_ENABLED,
                      "Override Method...","tbclass_override_method","",
                      "help class",
                      "Adds a method which overrides a base class method");
      }
   }
   if (cm.type_name :!= "func") {
      _menu_set_state(menu_handle, "set_breakpoint", MF_GRAYED, 'C');
   }
   in_class_context := true;
   if (cur_class_name == "" || cur_class_name == cur_package_name) {
      in_class_context = false;
      _menu_set_state(menu_handle, "organize_by_source", MF_GRAYED, 'C');
   }
   if (!def_tbc_organize_by_source || !in_class_context) {
      _menu_set_state(menu_handle, "expand_all", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "expand_structs", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "class_sort_by_hierarchy", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "class_sort_by_name", MF_GRAYED, 'C');
      if (cur_class_name != "") {
         _menu_set_state(menu_handle, "sort_by_line", MF_GRAYED, 'C');
         _menu_set_state(menu_handle, "sort_by_name", MF_CHECKED, 'C');
      }
   } else {
      if (def_tbc_expand_all) {
         _menu_set_state(menu_handle, "expand_all", MF_CHECKED, 'C');
      } else {
         _menu_set_state(menu_handle, "expand_all", MF_UNCHECKED, 'C');
      }
      if (def_tbc_expand_structs) {
         _menu_set_state(menu_handle, "expand_structs", MF_CHECKED, 'C');
      } else {
         _menu_set_state(menu_handle, "expand_structs", MF_UNCHECKED, 'C');
      }
      _menu_set_state(menu_handle, "organize_by_source", MF_CHECKED, 'C');
      if (def_tbc_sort_class_by_hierarchy) {
         _menu_set_state(menu_handle, "class_sort_by_name", MF_UNCHECKED, 'C');
         _menu_set_state(menu_handle, "class_sort_by_hierarchy", MF_CHECKED, 'C');
      } else {
         _menu_set_state(menu_handle, "class_sort_by_name", MF_CHECKED, 'C');
         _menu_set_state(menu_handle, "class_sort_by_hierarchy", MF_UNCHECKED, 'C');
      }
   }
   // set single click option
   if (def_tbc_single_click) {
      _menu_set_state(menu_handle, "single_click", MF_CHECKED, 'C');
   } else {
      _menu_set_state(menu_handle, "single_click", MF_UNCHECKED, 'C');
   }
   // set sort-by options
   if (def_tbc_sort_by_name) {
      _menu_set_state(menu_handle, "sort_by_name", MF_CHECKED, 'C');
      _menu_set_state(menu_handle, "sort_by_line", MF_UNCHECKED, 'C');
   } else {
      _menu_set_state(menu_handle, "sort_by_name", MF_UNCHECKED, 'C');
      _menu_set_state(menu_handle, "sort_by_line", MF_CHECKED, 'C');
   }
   // taken from pushTgConfigureMenu...cant use it because we have some proctree items in our list
   // but not all
   if ((def_class_flags & SE_TAG_FILTER_ANY_SCOPE) == SE_TAG_FILTER_ANY_SCOPE) {
      _menu_set_state(menu_handle,"all_scope",MF_CHECKED,'C');
   }
   if ((def_class_flags & SE_TAG_FILTER_ANY_SYMBOL) == (SE_TAG_FILTER_ANY_PROCEDURE & ~ SE_TAG_FILTER_PROTOTYPE | 
                                                      SE_TAG_FILTER_ANY_STRUCT)) {
      _menu_set_state(menu_handle,"funcs_only",MF_CHECKED,'C');
   }
   if ((def_class_flags & SE_TAG_FILTER_ANY_SYMBOL) == (SE_TAG_FILTER_PROTOTYPE | SE_TAG_FILTER_ANY_STRUCT)) {
      _menu_set_state(menu_handle,"protos_only",MF_CHECKED,'C');
   }
   if ((def_class_flags & SE_TAG_FILTER_ANY_SYMBOL) == (SE_TAG_FILTER_ANY_DATA | SE_TAG_FILTER_ANY_STRUCT)) {
      _menu_set_state(menu_handle,"vars_only",MF_CHECKED,'C');
   }
   if ((def_class_flags & SE_TAG_FILTER_ANY_SYMBOL) == SE_TAG_FILTER_ANY_STRUCT) {
      _menu_set_state(menu_handle,"class_only",MF_CHECKED,'C');
   }
   if ((def_class_flags & SE_TAG_FILTER_ANY_SYMBOL) == (SE_TAG_FILTER_DEFINE|SE_TAG_FILTER_ENUM|
                                                      SE_TAG_FILTER_CONSTANT|SE_TAG_FILTER_ANY_STRUCT)) {
      _menu_set_state(menu_handle,"defines_only",MF_CHECKED,'C');
   }
   if ((def_class_flags & SE_TAG_FILTER_ANYTHING) == SE_TAG_FILTER_ANYTHING) {
      _menu_set_state(menu_handle,"all",MF_CHECKED,'C');
   }
   // access filters
   if (def_class_flags & SE_TAG_FILTER_SCOPE_PUBLIC) {
      _menu_set_state(menu_handle,"public_scope",MF_CHECKED,'C');
   }
   if (def_class_flags & SE_TAG_FILTER_SCOPE_PACKAGE) {
      _menu_set_state(menu_handle,"package_scope",MF_CHECKED,'C');
   }
   if (def_class_flags & SE_TAG_FILTER_SCOPE_PROTECTED) {
      _menu_set_state(menu_handle,"protected_scope",MF_CHECKED,'C');
   }
   if (def_class_flags & SE_TAG_FILTER_SCOPE_PRIVATE) {
      _menu_set_state(menu_handle,"private_scope",MF_CHECKED,'C');
   }
   if (def_class_flags & SE_TAG_FILTER_SCOPE_STATIC) {
      _menu_set_state(menu_handle,"static_scope",MF_CHECKED,'C');
   }
   if (def_class_flags & SE_TAG_FILTER_SCOPE_EXTERN) {
      _menu_set_state(menu_handle,"extern_scope",MF_CHECKED,'C');
   }
   // populate refactoring submenu
   child_wid._UpdateContext(true);
   int treewid = ctlmembers;
   cur_index := treewid._TreeCurIndex();
   //doing this twice?
   tbclass_members_get_info(child_wid,treewid, cur_index, auto refcm);
   addCPPRefactoringMenuItems(menu_handle, "tbclass", refcm);
   addQuickRefactoringMenuItems(menu_handle, "tbclass", refcm);
   addOrganizeImportsMenuItems(menu_handle, "tbclass", refcm, true, child_wid.p_buf_name, child_wid.p_LangId);
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   call_list("_on_popup2_",translate("_tbclass_members_menu","_","-"),menu_handle);
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}

void ctlclasses.rbutton_up()
{
   // kill the refresh timer, prevents delays before the menu comes
   // while the refreshes are finishing up.
   tbclass_maybe_kill_timer();

   // get the menu form
   int index=find_index("_tbclass_classes_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');
   int wid = ctlclasses;
   cur_index := ctlclasses._TreeCurIndex();
   tbclass_classes_get_info(wid, cur_index, auto cm); 
   if (ctlclasses._TreeGetFirstChildIndex(TREE_ROOT_INDEX) > 0 &&  cm.member_name :!= "") {
      int output_mh, output_mp;
      int status = _menu_find(menu_handle,"include_all_above",output_mh,output_mp);
      output_mp++;
      _menu_insert(output_mh, ++output_mp,MF_ENABLED, 
                        "Show " cm.member_name " in Symbol browser", "tbclass_show_tag_in_cb c");
   }
   if (cur_index <= 0) {
      _menu_set_state(menu_handle, "filter_class", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "exclude_pkg", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "filter_all_above", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "include_class", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "include_pkg", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "include_all_above", MF_GRAYED, 'C');
   }
   if (def_tbc_filter_outside_wspace) {
      _menu_set_state(menu_handle, "filter_outside_wspace", MF_CHECKED, 'C');
   } else {
      _menu_set_state(menu_handle, "filter_outside_wspace", MF_UNCHECKED, 'C');
   }
   // show the menu.
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   call_list("_on_popup2_",translate("_tbclass_classes_menu","_","-"),menu_handle);
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}                                                          

defeventtab _class_exclusion_manager;

void _class_exclusion_manager.on_resize()
{
   // get form wid
   int wid = GetExclusionManagerFormWID();
   _nocheck _control ex_list, remove, clear, add_box, add_label;
   // how much space do we have?
   int avail_x  = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   int avail_y  = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   // what are the margins?
   int margin_x = wid.ex_list.p_x;
   int margin_y = wid.ex_list.p_y;
   // resize the width of the tree
   wid.ex_list.p_width = avail_x - margin_x * 2;
   // center the buttons and add field
   wid.remove.p_x = (avail_x intdiv 2) - (wid.remove.p_width intdiv 2);
   wid.clear.p_x = (avail_x intdiv 2) - (wid.clear.p_width intdiv 2);
   wid.add_box.p_x = (avail_x intdiv 2) - (wid.add_box.p_width intdiv 2);
   wid.add_label.p_x = wid.add_box.p_x;
   // reposition controls according to height of form
   wid.add_box.p_y = avail_y - margin_y;
   wid.add_label.p_y = wid.add_box.p_y - 260;
   wid.clear.p_y = wid.add_label.p_y - 550;
   wid.remove.p_y = wid.clear.p_y - 360;
   // resize height of the tree
   wid.ex_list.p_height = wid.remove.p_y - 480;
}

void ex_list.on_create()
{
   _str key;
   ex_list._TreeBeginUpdate(TREE_ROOT_INDEX);
   for (key._makeempty();;) {
      exclusions._nextel(key);
      if (key._isempty()) {
         break;
      }
      if (exclusions:[key] == 1) {
         ex_list._TreeAddItem(TREE_ROOT_INDEX, key, TREE_ADD_AS_CHILD, 0, 0, -1, 0);
      }
   }
   // iterate through the hashtable keys and populate the list
   for (key._makeempty();;) {
      exclusions_outside_wspace._nextel(key);
      if (key._isempty()) {
         break;
      }
      if (exclusions_outside_wspace:[key] == 1) {
         ex_list._TreeAddItem(TREE_ROOT_INDEX, key, TREE_ADD_AS_CHILD, 0, 0, -1, 0);
      }
   }
   ex_list._TreeEndUpdate(TREE_ROOT_INDEX);
}

void clear.lbutton_up()
{
   int form_wid = GetExclusionManagerFormWID();
   form_wid.ex_list._TreeBeginUpdate(TREE_ROOT_INDEX);
   int index = form_wid.ex_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      int delete_me = index;
      index = form_wid.ex_list._TreeGetNextSiblingIndex(index);
      form_wid.ex_list._TreeDelete(delete_me);
   }
   form_wid.ex_list._TreeEndUpdate(TREE_ROOT_INDEX);
   exclusions._makeempty();
   exclusions_outside_wspace._makeempty();
   def_tbc_filter_outside_wspace = false;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   _UpdateClass(true);
}

void remove.lbutton_up()
{
   int form_wid = GetExclusionManagerFormWID();
   int indices[];
   // doing begin/end update here keeps deleting the whole tree...
   //form_wid.ex_list._TreeBeginUpdate(TREE_ROOT_INDEX);
   form_wid.ex_list._TreeGetSelectionIndices(indices);
   int i;
   for (i = 0; i < indices._length(); i++) {
      _str caption = form_wid.ex_list._TreeGetCaption(indices[i]);
      exclusions._deleteel(caption);
      if (exclusions_outside_wspace:[caption] == 1) {
         exclusions_outside_wspace._makeempty();
         def_tbc_filter_outside_wspace = false;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      form_wid.ex_list._TreeDelete(indices[i]);
   }
   // check to make sure nothing stale is left in
   int cur_index = form_wid.ex_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (cur_index > -1) {
      int temp_index = cur_index;
      _str caption = form_wid.ex_list._TreeGetCaption(cur_index);
      cur_index = form_wid.ex_list._TreeGetNextSiblingIndex(cur_index);
      if (exclusions_outside_wspace:[caption] != 1 && exclusions:[caption] != 1) {
         form_wid.ex_list._TreeDelete(temp_index);
      }
   }
   //form_wid.ex_list._TreeEndUpdate(TREE_ROOT_INDEX);
   _UpdateClass(true);
}

void add_box.ENTER()
{
   int form_wid = GetExclusionManagerFormWID();
   text := add_box.p_text;
   _str search_for;
   // if autocomplete was used to exclude a member, parse the name out
   if (pos("(", text)) {
      parse text with search_for "(";
   } else {
      search_for = text;
   }
   lang := _isEditorCtl()? p_LangId : "";
   typeless tag_files = tags_filenamea(lang);
   i := 0;
   found_it := false;
   // search through the tag files to find the tag
   for (i; i < tag_files._length(); i++) {
      tag_read_db(tag_files[i]);
      _str temp_class;
      tag_find_class(temp_class, search_for);
      if (temp_class :== search_for) {
         found_it = true;
         break;
      }
   }

   // make sure that the context doesn't get modified by a background thread.
   tag_reset_find_class();
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // if we didnt find it as a class, check if it is a package
   if (!found_it) {
      int status = tag_check_for_package(search_for, tag_files, true, true);
      if (status > 0) {
         found_it = true;
      }
   }
   if (found_it) {
      exclusions:[search_for] = 1;
      form_wid.ex_list._TreeAddItem(TREE_ROOT_INDEX, search_for, TREE_ADD_AS_CHILD, 0, 0, -1, 0);
      _UpdateClass(true);
   } else {
      // punt
      _message_box("Unable to find " text " as a class or package.");
   }
   add_box.p_text = "";
}

_command void tbclass_launch_manager() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION) 
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Class tool window");
      return;
   }

   show("_class_exclusion_manager");  
}
