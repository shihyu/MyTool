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
#include "eclipse.sh"
#include "minihtml.sh"
#import "c.e"
#import "clipbd.e"
#import "cutil.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "context.e"
#import "cua.e"
#import "dlgman.e"
#import "docbook.e"
#import "eclipse.e"
#import "files.e"
#import "help.e"
#import "ini.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "mouse.e"
#import "picture.e"
#import "pushtag.e"
#import "saveload.e"
#import "seldisp.e"
#import "sellist.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagfind.e"
#import "tagform.e"
#import "tagrefs.e"
#import "tags.e"
#import "tagwin.e"
#import "tbclass.e"
#import "tbcmds.e"
#import "tbcontrols.e"
#import "tbsearch.e"
#import "toolbar.e"
#import "util.e"
#import "wfont.e"
#import "window.e"
#import "sc/lang/ScopedTimeoutGuard.e"
#import "se/tags/TaggingGuard.e"
#import "se/ui/mainwindow.e"
#import "se/ui/toolwindow.e"
#import "se/ui/twevent.e"
#endregion

static const TBPREVIEW_DOC_NAME= ".Preview Window Buffer";
static const TBPREVIEW_EXCLUSIONS = "PreviewWindowExclusions";
static const TBPREVIEW_FORM = "_tbtagwin_form";
static int EditWindowBufferID(...) {
   if (arg()) edit1.p_user=arg(1);
   return edit1.p_user;
}
static typeless TBPREVIEW_KEYS(...) {
   if (arg()) ctl_push_tag.p_user=arg(1);
   return ctl_push_tag.p_user;
}
static int TBPREVIEW_TIMER(...) {
   if (arg()) ctltaglist.p_user=arg(1);
   return ctltaglist.p_user;
}
// ctltagdocs.p_user are taken
// ctlbufname.p_user appears to be take but may be a mistake

static const PREFIXMATCHEDMAXLISTCOUNT= 200;

//static int     gtagwin_last_seekpos = -1;
static bool gtagwin_in_quit_file = false;


//static VS_TAG_BROWSE_INFO gtagwin_saved_info = null;
//static bool gtagwin_use_editor = false;
//5:07pm 7/3/1997
//This is window that displays the location of a tag.
//This may be part of a tabbed dialog eventually, try to keep that in mind

struct PREVIEW_WINDOW_STACK_ITEM 
{
   int stack_top;
   int tree_line;
   VS_TAG_BROWSE_INFO symbols[];
   _str helpText;
   _str fileText;
   typeless htmlCtlScrollInfo;
};
//static PREVIEW_WINDOW_STACK_ITEM gtagwin_lastItem;


struct PREVIEW_FORM_INFO {
   int m_form_wid;
   //int m_last_buf_id;
   long m_tagwin_last_seekpos;
   VS_TAG_BROWSE_INFO m_tagwin_saved_info;
   bool m_tagwin_use_editor;
   PREVIEW_WINDOW_STACK_ITEM m_tagwin_lastItem;
   int m_LastModified;
   bool m_forceUpdate;
   long m_tagwin_last_jumppos;
};

static PREVIEW_FORM_INFO gPreviewFormList:[];

static void _init_all_formobj(PREVIEW_FORM_INFO (&formList):[],_str formName) {
   last := _last_window_id();
   for (i:=1; i<=last; ++i) {
      if ( _iswindow_valid(i) && i.p_object == OI_FORM && !i.p_edit && (i.p_window_flags & VSWFLAG_ON_CREATE_ALREADY_CALLED) ) {
         if (i.p_name:==formName) {
            formList:[i].m_form_wid=i;
            formList:[i].m_tagwin_last_seekpos= -1;
            formList:[i].m_tagwin_saved_info= null;
            formList:[i].m_tagwin_use_editor= false;
            formList:[i].m_tagwin_lastItem= null;
            formList:[i].m_LastModified= -1;
            formList:[i].m_forceUpdate = false;
            formList:[i].m_tagwin_last_jumppos = -1;
            //wid = i;
            //break;
         }
      }
   }
}

/**
 * Keeps track of what other windows activate the Preview tool window  automatically 
 * This is a bitset of the following flags: 
 * <ul>
 * <li>APF_ON             -- if not set, all other options are disabled.</li>
 * <li>APF_REFERENCES     -- References tool window</li>
 * <li>APF_SYMBOLS        -- Symbols tool window</li>
 * <li>APF_FIND_SYMBOL    -- Find Symbol tool window</li>
 * <li>APF_CLASS          -- Class tool window</li>
 * <li>APF_DEFS           -- Defs tool window</li>
 * <li>APF_BOOKMARKS      -- Bookmarks tool window</li>
 * <li>APF_SEARCH_RESULTS -- Search Results tool window</li> 
 * <li>APF_FILES          -- Files tool window</li>
 * <li>APF_ANNOTATIONS    -- Annotations tool window</li>
 * <li>APF_BREAKPOINTS    -- Breakpoints tool window</li>
 * <li>APF_MESSAGE_LIST   -- Message List tool window</li>
 * <li>APF_UNIT_TEST      -- Unit test tool window</li>
 * <li>APF_SELECT_SYMBOL  -- Select Symbol dialog (Go to Definition...)</li> 
 * </ul> 
 *  
 * @default AFP_NULL_FLAGS (0)
 * @category Configuration_Variables
 */
int def_activate_preview = 0;

// keeps track of what window last activated the preview window
static ActivatePreviewFlags gtagwin_activated_by = APF_ALL_FLAGS;

/**
 * Determines whether the current line highlighting should be enabled in the 
 * preview tool window. 
 * <ul>  
 * <li>PREVIEW_CURRENT_LINE_BOX       -- draw box around current line</li>
 * <li>PREVIEW_CURRENT_LINE_HIGHLIGHT -- highlight current line</li>
 * <li>PREVIEW_CURRENT_LINE_LANG      -- highlight current line (language specific)</li>
 * </ul>
 *  
 * @default PREVIEW_CURRENT_LINE_BOX (1)
 * @category Configuration_Variables
 */
int def_preview_current_line = 1;

/**
 * Maximum time to spend on looking up tag matches for preview window. 
 *  
 * @default 1000 ms (1 second) 
 * @category Configuration_Variables
 */
int def_preview_window_timeout = 1000;


definit()
{
   // IF editor is initializing from invocation
   if (arg(1)!='L') {
      gtagwin_in_quit_file=false;
   }
   gPreviewFormList._makeempty();
   _init_all_formobj(gPreviewFormList,TBPREVIEW_FORM);
}


/**
 * Determines whether we activate the preview tool window based on the flag sent 
 * in.  Some other tool windows cause the preview window to be shown based on 
 * the user's settings. 
 * 
 * @param activateFlag           the flag to check (based on the calling tool 
 *                               window)
 * 
 * @return                       whether to activate the preview window
 */
bool doActivatePreviewToolWindow(ActivatePreviewFlags activateFlag)
{
   if (!(def_activate_preview & APF_ON)) return false;

   if (!(def_activate_preview & activateFlag)) return false;

   gtagwin_activated_by = activateFlag;
   return true;
}

defeventtab _tbtagwin_form;

_tbtagwin_form."F12"()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   } else if (def_keys == "eclipse-keys") {
      activate_editor();
   }
}

_tbtagwin_form."C-M"()
{
   if (isEclipsePlugin()) {
      eclipse_maximize_part();
   }
}

int _eclipse_getSymbolWindowQFormWID()
{
   formWid := _find_formobj(ECLIPSE_SYMBOLOUTPUT_CONTAINERFORM_NAME,'n');
   if (formWid > 0) {
      return formWid.p_child;
   }
   return 0;
}

static VS_TAG_BROWSE_INFO getSelectedSymbol()
{
   index := ctltaglist._TreeCurIndex();
   if (index <= 0) return null;
   return ctltaglist._TreeGetUserInfo(index);
}

void ctl_symbols.lbutton_up()
{
   VS_TAG_BROWSE_INFO cm = getSelectedSymbol();
   if (cm != null) {
      tag_show_in_class_browser(cm);
   }
}
void ctl_find_refs.lbutton_up()
{
   VS_TAG_BROWSE_INFO cm = getSelectedSymbol();
   if (cm != null) {
      activate_references();
      refresh_references_tab(cm);
   }
}
void ctl_push_tag.lbutton_up()
{
   file_name := tagwin_get_buffer_name();
   if (file_name == "") return;
   edit1.tagwin_goto_tag(tagwin_get_buffer_name(), edit1.p_line);
}
void ctl_back.lbutton_up()
{
   ctltagdocs.call_event(CHANGE_CLICKED_ON_HTML_LINK, "<<back", ctltagdocs, ON_CHANGE, 'w');
}
void ctl_forward.lbutton_up()
{
   ctltagdocs.call_event(CHANGE_CLICKED_ON_HTML_LINK, "<<forward", ctltagdocs, ON_CHANGE, 'w');
}

void ctltaglist.on_change(int reason,int index)
{
   if ( !testFlag(p_window_flags, VSWFLAG_ON_CREATE_ALREADY_CALLED) ) {
      // If on_change() were to be called BEFORE on_create(), then bad
      // things ensue. Like the active editor window's buffer being
      // switched into the preview editor control and having p_tabs set!
      return;
   }
   if (reason == CHANGE_SELECTED) {
      VS_TAG_BROWSE_INFO cm;
      if (index > 0) {
         cm = _TreeGetUserInfo(index);
         if (cm != null && cm.file_name!=null) {

            // special case for COBOL copy books, ASM390 macros
            if (cm.type_name=="include" && cm.return_type!="" && file_exists(cm.return_type)) {
               cm.file_name=cm.return_type;
               cm.line_no=1;
               cm.column_no=1;
               cm.seekpos=0;
            }

            // make sure that this did not come from a jar file or DLL
            if (_QBinaryLoadTagsSupported(cm.file_name)) {
               ctltagdocs.p_text="<i>no documentation available</i>";
               edit1.load_files("+q +m +bi "EditWindowBufferID());
               edit1.SetSymbolInfoCaption(0, cm.file_name);
               edit1.refresh("w");
               edit1.p_window_flags &= ~(CURLINE_COLOR_WFLAG|CURLINE_RECT_WFLAG);
            } else {
               edit1.DisplayFile(cm);
               edit1.SetSymbolInfoCaption(cm.line_no, cm.file_name);
            }

            // update the tag properties form
            child_wid := _MDIGetActiveMDIChild();
            if (TagWinFocus(p_active_form) || 
                (!child_wid && _get_focus()==child_wid)) {
               cb_refresh_property_view(cm);
               cb_refresh_arguments_view(cm);
            }
         }
      }
   } else if (reason == CHANGE_LEAF_ENTER) {
      buffer_name := tagwin_get_buffer_name();
      if (buffer_name != "") {
         edit1.tagwin_goto_tag(buffer_name, edit1.p_RLine);
      }
   }
}

static void savePreviewWindow(PREVIEW_WINDOW_STACK_ITEM &item)
{
   item.stack_top=0;
   item.tree_line = ctltaglist._TreeCurLineNumber();
   item.symbols._makeempty();
   tree_index := ctltaglist._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (tree_index > 0) {
      item.symbols[item.symbols._length()] = ctltaglist._TreeGetUserInfo(tree_index);
      tree_index = ctltaglist._TreeGetNextSiblingIndex(tree_index);
   }
   item.helpText = ctltagdocs.p_text;
   item.fileText = ctlbufname.p_user;
   ctltagdocs._minihtml_GetScrollInfo(item.htmlCtlScrollInfo);
}
static void restorePreviewWindow(PREVIEW_WINDOW_STACK_ITEM &item)
{
   if (TBPREVIEW_TIMER() >= 0) {
      _kill_timer(TBPREVIEW_TIMER());
      TBPREVIEW_TIMER(-1);
   }
   ctltaglist._TreeBeginUpdate(TREE_ROOT_INDEX);
   n := item.symbols._length();
   for (i:=0; i<n; ++i) {
      tag_tree_insert_info(ctltaglist, TREE_ROOT_INDEX, item.symbols[i], false, 1, TREE_ADD_AS_CHILD, item.symbols[i]);
   }
   ctltaglist._TreeEndUpdate(TREE_ROOT_INDEX);
   if (item.tree_line != null && isuinteger(item.tree_line)) {
      ctltaglist._TreeCurLineNumber(item.tree_line);
   }
   if (item.helpText != null) {
      ctltagdocs.p_text = item.helpText;
   }
   if (item.fileText != null) {
      edit1.SetSymbolInfoCaption(0, item.fileText);
   }
   if (item.htmlCtlScrollInfo != null) {
      ctltagdocs._minihtml_SetScrollInfo(item.htmlCtlScrollInfo);
   }
}

void ctltagdocs.on_change(int reason,_str hrefText)
{
   if (TBPREVIEW_TIMER() >= 0) {
      _kill_timer(TBPREVIEW_TIMER());
      TBPREVIEW_TIMER(-1);
   }

   // get the hypertext stack
   stack_top := -1;
   PREVIEW_WINDOW_STACK_ITEM preview_stack[];
   preview_stack._makeempty();
   if (p_user._varformat()==VF_ARRAY) {
      preview_stack = p_user;
      if (preview_stack._length() > 0) {
         stack_top = preview_stack[0].stack_top;
      }
   }

   if (reason==CHANGE_CLICKED_ON_HTML_LINK) {
      if (hrefText=="<<back") {
         if (stack_top > 0) {
            PREVIEW_WINDOW_STACK_ITEM cm = preview_stack[stack_top-1];
            restorePreviewWindow(cm);
            --stack_top;
            preview_stack[0].stack_top = stack_top;
            p_user = preview_stack;
            ctl_forward.p_enabled=true;
            if (stack_top <= 0) {
               ctl_back.p_enabled=false;
            }
         }
         return;

      } else if(hrefText=="<<forward") {
         if (stack_top+1 < preview_stack._length()) {
            PREVIEW_WINDOW_STACK_ITEM cm = preview_stack[stack_top+1];
            restorePreviewWindow(cm);
            ++stack_top;
            preview_stack[0].stack_top = stack_top;
            p_user = preview_stack;
            ctl_back.p_enabled=true;
            if (stack_top+1 >= preview_stack._length()) {
               ctl_forward.p_enabled=false;
            }
         }
         return;

      } else if (substr(hrefText,1,16)=="<<push_clipboard") {
         hrefText = strip(substr(hrefText,17));
         push_clipboard(hrefText);
         message("Copied '"hrefText"' to clipboard");
         return;

      } else if (hrefText=="<<pushtag") {
         edit1.call_event(edit1, LBUTTON_DOUBLE_CLICK, 'w');
         return;

      } else if (substr(hrefText,1,2)=="<<") {
         // generic Slick-C command with one string argument
         parse hrefText with "<<" auto commandName auto argValue;
         index := find_index(commandName, COMMAND_TYPE);
         if (index_callable(index)) {
            call_index(argValue, index);
            return;
         }
      } else if (substr(hrefText,1,7)=="slickc:") {
         parse hrefText with "slickc:" auto commandName auto argValue;
         index := find_index(commandName, COMMAND_TYPE);
         if (index_callable(index)) {
            call_index(argValue, index);
            return;
         }
         return;
      }


      // Is this a web site or other hypertext link (not a code link)?
      if (substr(hrefText,1,1)!=JAVADOCHREFINDICATOR) {
         tag_goto_url(hrefText);
         return;
      }

      // check for internal code link (C# paramters, for example)
      if (substr(hrefText,1,2)==JAVADOCHREFINDICATOR:+JAVADOCHREFINDICATOR) {
        _minihtml_FindAName(substr(hrefText,3),VSMHFINDANAMEFLAG_CENTER_SCROLL);
        return;
      }

      tag_push_matches();
      status := 0;
      filename := edit1.p_buf_name;
      linenum := edit1.p_RLine;
      child_wid := _MDIGetActiveMDIChild();
      if (edit1.p_LangId=="xmldoc" && child_wid) {
         status = child_wid.tag_match_href_text(hrefText, filename, linenum);
      } else {
         status = edit1.tag_match_href_text(hrefText, filename, linenum);
      }

      if (status < 0) {
         _message_box(nls('Could not find help for "%s"',substr(hrefText,2)));
         return;
      }

      PREVIEW_WINDOW_STACK_ITEM item;
      savePreviewWindow(item);
      ctl_back.p_enabled=true;
      ctl_forward.p_enabled=false;

      if (stack_top<0) stack_top=0;
      preview_stack[stack_top] = item;
      ++stack_top;
      while (preview_stack._length() > stack_top) {
         preview_stack._deleteel(stack_top);
      }

      tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:false, 
                                          filterDuplicateGlobalVars:false, 
                                          filterDuplicateClasses:true, 
                                          filterAllImports:true,
                                          filterBinaryLoadedTags:true);

      ctltaglist._TreeBeginUpdate(TREE_ROOT_INDEX);
      preferred_index := 0;
      n := tag_get_num_of_matches();
      for (i:=1; i<=n; ++i) {
         // add this item to the tree
         tag_get_match_info(i, auto cm);
         k := tag_tree_insert_fast(ctltaglist,TREE_ROOT_INDEX,
                                   VS_TAGMATCH_match,i,
                                   0,1,TREE_ADD_AS_CHILD,1,1,cm);

         // check this item's file extension information
         if (cm.language=="") {
            cm.language=_Filename2LangId(cm.file_name);
         }
         // prefer to see source we can pilfer comments from
         if (cm.language!="") {
            if (!_QBinaryLoadTagsSupported(cm.file_name) && _istagging_supported(cm.language)) {
               preferred_index=i;
            }
         }
      }
      ctltaglist._TreeEndUpdate(TREE_ROOT_INDEX);
      if (!preferred_index) preferred_index=1;
      ctltaglist._TreeCurLineNumber(preferred_index);

      tag_pop_matches();

      savePreviewWindow(item);
      preview_stack[stack_top] = item;
      preview_stack[0].stack_top = stack_top;
      p_user = preview_stack;
      return;
   }
}

_editor edit1;

void _tbtagwin_form.on_destroy()
{
   // save the position of the sizing bars
   _moncfg_append_retrieve(0,ctl_size_x.p_x,"_tbtagwin_form.ctl_size_x.p_x");
   _moncfg_append_retrieve(0,ctl_size_y.p_y,"_tbtagwin_form.ctl_size_y.p_y");
   _moncfg_append_retrieve(0,ctl_size_x2.p_x,"_tbtagwin_form.ctl_size_x2.p_x");
   _moncfg_append_retrieve(0,ctl_size_y2.p_y,"_tbtagwin_form.ctl_size_y2.p_y");

   // determine if we should save font size for editor control
   fontsize := edit1.p_font_size;
   edit1.wfont_unzoom();
   if (fontsize != edit1.p_font_size) {
      _append_retrieve(0,fontsize,"_tbtagwin_form.edit1.p_font_size");
   }

   // determine if we should save font size for HTML control
   fontsize = ctltagdocs._minihtml_command("zoom");
   if (fontsize > 0) {
      ctltagdocs._minihtml_command("unzoom");
      if (fontsize != ctltagdocs._minihtml_command("zoom")) {
         _append_retrieve(0,fontsize,"_tbtagwin_form.ctltagdocs.p_font_size");
      }
   }

   // save orientation preferences
   layoutOption := TOOLBAR_LAYOUT_ORIENTATION_AUTOMATIC;
   if (ctlstandardbtn.p_value)   layoutOption = TOOLBAR_LAYOUT_ORIENTATION_STANDARD;
   if (ctlverticalbtn.p_value)   layoutOption = TOOLBAR_LAYOUT_ORIENTATION_VERTICAL;
   if (ctlhorizontalbtn.p_value) layoutOption = TOOLBAR_LAYOUT_ORIENTATION_HORIZONTAL;
   _moncfg_append_retrieve(0,(int)layoutOption,"_tbtagwin_form.ctlautobtn.p_value");

   // unbind keys copied in for push_tag and push_ref shortcuts
   unbindPreviewSymbolShortcuts();

   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id,ON_DESTROY,'2');
}

void _tbtagwin_form.on_change(int reason)
{
   if( reason==CHANGE_AUTO_SHOW ) {
      if (!_find_control("ctltagdocs")) return;
      gPreviewFormList:[p_active_form].m_tagwin_last_seekpos= -1;
      _UpdateTagWindow(AlwaysUpdate:true);
   }
}
void _tbtagwin_form.on_got_focus()
{
   if (!_find_control("ctltagdocs")) {
      return;
   }

   int old_wid;
   if (isEclipsePlugin()) {
      symbolContainer := _eclipse_getSymbolWindowQFormWID();
      if (!symbolContainer) return;
      old_wid = p_window_id;
      // RGH - 4/27/2007
      // Need to set p_window_id so we can find the right controls
      p_window_id = symbolContainer;
   }
   
   if (_get_focus()==ctltagdocs) {
      return;
   }
// if (_get_focus()==ctltaglist && ctltaglist._TreeGetNumChildren(TREE_ROOT_INDEX,"") >= 1) {
//    return;
// }
   gPreviewFormList:[p_active_form].m_tagwin_last_seekpos= -1;

   // DJB 01-27-2021
   // force an update of the preview tool window only if it is currently blank
   if (edit1.p_buf_id == EditWindowBufferID()) {
      _UpdateTagWindow(AlwaysUpdate:true, form_wid:p_active_form);
   }
   if (isEclipsePlugin()) {
      p_window_id = old_wid;
   }
   //DisplayTagList();
}

static void resizePreviewWindowLayoutButtons(int xpos, int ypos, int max_button_height)
{
   ctlautobtn.resizeToolButton(max_button_height);
   ctlstandardbtn.resizeToolButton(max_button_height);
   ctlhorizontalbtn.resizeToolButton(max_button_height);
   ctlverticalbtn.resizeToolButton(max_button_height);

   ctlautobtn.p_y       = ypos;
   ctlstandardbtn.p_y   = ypos;
   ctlhorizontalbtn.p_y = ypos;
   ctlverticalbtn.p_y   = ypos;

   ctlautobtn.p_x       = xpos-4*ctlautobtn.p_width;
   ctlstandardbtn.p_x   = xpos-3*ctlautobtn.p_width;
   ctlhorizontalbtn.p_x = xpos-2*ctlautobtn.p_width;
   ctlverticalbtn.p_x   = xpos-1*ctlautobtn.p_width;

   ctlautobtn.p_border_style       = ctlautobtn.p_value?       BDS_FIXED_SINGLE : BDS_NONE;
   ctlstandardbtn.p_border_style   = ctlstandardbtn.p_value?   BDS_FIXED_SINGLE : BDS_NONE;
   ctlhorizontalbtn.p_border_style = ctlhorizontalbtn.p_value? BDS_FIXED_SINGLE : BDS_NONE;
   ctlverticalbtn.p_border_style   = ctlverticalbtn.p_value?   BDS_FIXED_SINGLE : BDS_NONE;
}

static void resizePreviewWindowToolButtons(int xpos, int ypos, int hspace, int vspace, int max_button_height)
{
   ctl_back.resizeToolButton(max_button_height);
   ctl_forward.resizeToolButton(max_button_height);
   ctl_push_tag.resizeToolButton(max_button_height);
   ctl_find_refs.resizeToolButton(max_button_height);
   ctl_symbols.resizeToolButton(max_button_height);
   ctl_tag_files.resizeToolButton(max_button_height);

   alignControlsVertical(xpos-ctl_back.p_width, ypos, vspace,
                         ctl_back.p_window_id,
                         ctl_forward.p_window_id,
                         ctl_push_tag.p_window_id,
                         ctl_find_refs.p_window_id,
                         ctl_symbols.p_window_id,
                         ctl_tag_files.p_window_id);

   alignControlsHorizontal(xpos-ctl_back.p_width-4*vspace-4*ctlautobtn.p_width,
                           0,
                           hspace,
                           ctlautobtn.p_window_id,
                           ctlstandardbtn.p_window_id,
                           ctlhorizontalbtn.p_window_id,
                           ctlverticalbtn.p_window_id);
}

static void resizePreviewWindowHorizontal(int clientW, int clientH, int max_button_height)
{
   // make sure the right controls are visible
   ctl_size_x.p_visible=true;
   ctl_size_x2.p_visible=true;
   ctl_size_y.p_visible=false;
   ctl_size_y2.p_visible=false;

   // get default horizontal and vertical spacing for toolbar buttons
   hspace := _dx2lx(SM_TWIP, def_toolbar_pic_hspace);
   vspace := _dx2lx(SM_TWIP, def_toolbar_pic_vspace);

   // set position of the buffer name
   ctlbufname.p_x = 60;
   ctlbufname.p_y = 60;
   ctlbufname.p_auto_size=true;

   // adjust the positions of toolbar buttons
   resizePreviewWindowLayoutButtons(clientW, 0, max_button_height);
   title_height := max(vspace+ctlstandardbtn.p_height+vspace,ctlbufname.p_y_extent+vspace+60);
   layoutButtonWidth := ctlstandardbtn.p_width+hspace;
   resizePreviewWindowToolButtons(clientW, title_height, hspace, vspace, max(max_button_height,clientH intdiv 8));
   clientW = clientW - hspace - ctl_back.p_width;

   // set default locations for controls
   ctltaglist.p_x = 0;
   ctltaglist.p_y = 0;
   edit1.p_y = title_height;

   // verify that dividers set to reasonable values
   if (ctl_size_x.p_x < ctltaglist.p_x) {
      ctl_size_x.p_x = ctltaglist.p_x;
   }
   if (ctl_size_x.p_x > ctl_size_x2.p_x-ctl_size_x.p_width) {
      ctl_size_x.p_x = ctl_size_x2.p_x-ctl_size_x.p_width;
   }
   if (ctl_size_x2.p_x < ctltaglist.p_x+ctl_size_x.p_width) {
      ctl_size_x2.p_x = ctltaglist.p_x+ctl_size_x.p_width;
   }
   if (ctl_size_x2.p_x > ctlautobtn.p_x-ctl_size_x2.p_width) {
      ctl_size_x2.p_x = ctlautobtn.p_x-ctl_size_x2.p_width;
   }

   // adjust y positions based on position of sizebar
   ctl_size_x.p_y  = title_height;
   ctltagdocs.p_y  = title_height;
   ctl_size_x2.p_y = title_height;
   edit1.p_y       = title_height;

   // adjust height based on position of y-axis sizebar and client height
   ctltaglist.p_y_extent = clientH ;
   ctl_size_x.p_y_extent = clientH ;
   ctltagdocs.p_height  = clientH - edit1.p_y;
   ctl_size_x2.p_height = clientH - edit1.p_y;
   edit1.p_y_extent = clientH ;

   // adjust x positions based on position of sizebar 
   ctlbufname.p_x = ctl_size_x.p_x_extent+60;
   ctltagdocs.p_x = ctl_size_x.p_x_extent;
   edit1.p_x = ctl_size_x2.p_x_extent;

   // adjust width based on position of x-axis sizebar and client height
   ctltaglist.p_x_extent = ctl_size_x.p_x;
   ctltagdocs.p_x_extent = ctl_size_x2.p_x;
   edit1.p_x_extent = clientW ;

   // finally, adjust width of label
   ctlbufname.p_auto_size=false;
   ctlbufname.p_x_extent = clientW - layoutButtonWidth*4;
   edit1.SetSymbolInfoCaption(0, ctlbufname.p_user);
}

static void resizePreviewWindowVertical(int clientW, int clientH, int max_button_height)
{
   // make sure the right controls are visible
   ctl_size_x.p_visible=false;
   ctl_size_x2.p_visible=false;
   ctl_size_y.p_visible=true;
   ctl_size_y2.p_visible=true;

   // get default horizontal and vertical spacing for toolbar buttons
   hspace := _dx2lx(SM_TWIP, def_toolbar_pic_hspace);
   vspace := _dx2lx(SM_TWIP, def_toolbar_pic_vspace);

   // set default locations for controls
   ctlbufname.p_x = 60;
   ctlbufname.p_y = 60;
   ctlbufname.p_auto_size=true;
   ctltaglist.p_x = 0;
   ctltagdocs.p_x = 0;
   ctl_size_y.p_x = 0;
   ctl_size_y2.p_x = 0;
   edit1.p_x = 0;

   // verify that dividers set to reasonable values
   if (ctl_size_y.p_y < ctltaglist.p_y) {
      ctl_size_y.p_y = ctltaglist.p_y;
   }
   if (ctl_size_y.p_y > ctl_size_y2.p_y-ctl_size_y.p_height) {
      ctl_size_y.p_y = ctl_size_y2.p_y-ctl_size_y.p_height;
   }
   if (ctl_size_y2.p_y < ctltaglist.p_y+ctl_size_y.p_height) {
      ctl_size_y2.p_y = ctltaglist.p_y+ctl_size_y.p_height;
   }
   if (ctl_size_y2.p_y > clientH-ctl_size_y2.p_height) {
      ctl_size_y2.p_y = clientH-ctl_size_y2.p_height;
   }

   // adjust the positions of toolbar buttons
   resizePreviewWindowLayoutButtons(clientW, 0, max_button_height);
   title_height := max(vspace+ctlstandardbtn.p_height+vspace,ctlbufname.p_y_extent+vspace+60);
   layoutButtonWidth := ctlstandardbtn.p_width+hspace;
   resizePreviewWindowToolButtons(clientW, title_height, hspace, vspace, max(max_button_height,clientH intdiv 8));
   clientW = clientW - hspace - ctl_back.p_width;

   // adjust y positions based on position of sizebar
   ctltaglist.p_y = title_height;
   ctltagdocs.p_y = ctl_size_y.p_y_extent;
   edit1.p_y = ctl_size_y2.p_y_extent;

   // adjust height based on position of y-axis sizebar and client height
   ctltaglist.p_y_extent = ctl_size_y.p_y;
   ctltagdocs.p_y_extent = ctl_size_y2.p_y;
   edit1.p_y_extent = clientH ;

   // adjust x positions based on position of sizebar
   edit1.p_x = 0;

   // adjust width based on position of x-axis sizebar and client height
   ctltaglist.p_width  = clientW - edit1.p_x;
   ctl_size_y.p_width  = clientW - edit1.p_x;
   ctltagdocs.p_width  = clientW - edit1.p_x;
   ctl_size_y2.p_width = clientW - edit1.p_x;
   edit1.p_x_extent = clientW ;

   // finally, adjust width of label
   ctlbufname.p_x_extent = clientW - layoutButtonWidth*4;
   ctlbufname.p_auto_size=false;
   edit1.SetSymbolInfoCaption(0, ctlbufname.p_user);
}

static void resizePreviewWindowStandard(int clientW, int clientH, int max_button_height)
{
   // make sure the right controls are visible
   ctl_size_x.p_visible=true;
   ctl_size_x2.p_visible=false;
   ctl_size_y.p_visible=true;
   ctl_size_y2.p_visible=false;

   // get default horizontal and vertical spacing for toolbar buttons
   hspace := _dx2lx(SM_TWIP, def_toolbar_pic_hspace);
   vspace := _dx2lx(SM_TWIP, def_toolbar_pic_vspace);

   // set default locations for controls
   ctlbufname.p_auto_size=true;
   ctlbufname.p_y = 60;
   ctltaglist.p_x = 0;
   ctltaglist.p_y = 0;
   ctl_size_y.p_x = 0;
   ctl_size_x.p_y = 0;
   edit1.p_x      = 0;

   // adjust the positions of toolbar buttons
   resizePreviewWindowLayoutButtons(clientW, 0, max_button_height);
   title_height := max(vspace+ctlstandardbtn.p_height+vspace,ctlbufname.p_y_extent+vspace+60);
   layoutButtonWidth := ctlstandardbtn.p_width+hspace;
   resizePreviewWindowToolButtons(clientW, title_height, hspace, vspace, max(max_button_height,clientH intdiv 8));
   clientW = clientW - hspace - ctl_back.p_width;

   // verify that dividers set to reasonable values
   if (ctl_size_x.p_x < ctltaglist.p_x) {
      ctl_size_x.p_x = ctltaglist.p_x;
   }
   if (ctl_size_x.p_x > clientW-ctl_size_x.p_width-ctltaglist.p_x-layoutButtonWidth*4) {
      ctl_size_x.p_x = clientW-ctl_size_x.p_width-ctltaglist.p_x-layoutButtonWidth*4;
   }
   if (ctl_size_y.p_y < ctltagdocs.p_y) {
      ctl_size_y.p_y = ctltagdocs.p_y;
   }
   if (ctl_size_y.p_y > clientH-ctl_size_y.p_height-ctltaglist.p_y) {
      ctl_size_y.p_y = clientH-ctl_size_y.p_height-ctltaglist.p_y;
   }

   // adjust y positions based on position of sizebar
   ctltagdocs.p_y = title_height;
   edit1.p_y = ctl_size_y.p_y_extent;
   ctl_size_x.p_y = ctltaglist.p_y;
   ctltagdocs.p_y = title_height;
   ctltaglist.p_y = 0;

   // adjust height based on position of y-axis sizebar and client height
   ctltaglist.p_y_extent = ctl_size_y.p_y;
   ctltagdocs.p_y_extent = ctl_size_y.p_y;
   ctl_size_x.p_y_extent = ctl_size_y.p_y;
   edit1.p_y_extent = clientH ;

   // adjust x positions based on position of sizebar
   ctltagdocs.p_x = ctl_size_x.p_x_extent-_dx2lx(SM_TWIP,1);
   ctlbufname.p_x = ctltagdocs.p_x;
   ctl_size_y.p_x = edit1.p_x;

   // adjust width based on position of x-axis sizebar and client height
   ctltaglist.p_x_extent = ctl_size_x.p_x;
   ctltagdocs.p_x_extent = clientW - edit1.p_x;
   edit1.p_width = clientW - 2 * edit1.p_x;
   ctl_size_y.p_width = edit1.p_width;

   // finally, adjust width of label
   ctlbufname.p_x_extent = clientW - layoutButtonWidth*4;
   ctlbufname.p_auto_size=false;
   edit1.SetSymbolInfoCaption(0, ctlbufname.p_user);
}

static void resizePreviewWindowHybrid(int clientW, int clientH, int max_button_height)
{
   // make sure the right controls are visible
   ctl_size_x.p_visible=true;
   ctl_size_x2.p_visible=false;
   ctl_size_y.p_visible=true;
   ctl_size_y2.p_visible=false;

   // get default horizontal and vertical spacing for toolbar buttons
   hspace := _dx2lx(SM_TWIP, def_toolbar_pic_hspace);
   vspace := _dx2lx(SM_TWIP, def_toolbar_pic_vspace);

   // set default locations for controls
   ctlbufname.p_y = 60;
   ctlbufname.p_auto_size=true;
   ctltaglist.p_x = 0;
   ctltaglist.p_y = 0;
   ctltagdocs.p_x = 0;
   ctl_size_y.p_x = 0;
   ctl_size_x.p_y = 0;

   // adjust the positions of toolbar buttons
   resizePreviewWindowLayoutButtons(clientW, 0, max_button_height);
   title_height := max(vspace+ctlstandardbtn.p_height+vspace,ctlbufname.p_y_extent+vspace+60);
   layoutButtonWidth := ctlstandardbtn.p_width+hspace;
   resizePreviewWindowToolButtons(clientW, title_height, hspace, vspace, max(max_button_height,clientH intdiv 8));
   clientW = clientW - hspace - ctl_back.p_width;

   // verify that dividers set to reasonable values
   if (ctl_size_x.p_x < ctltaglist.p_x) {
      ctl_size_x.p_x = ctltaglist.p_x;
   }
   if (ctl_size_x.p_x > clientW-ctl_size_x.p_width-layoutButtonWidth*4) {
      ctl_size_x.p_x = clientW-ctl_size_x.p_width-layoutButtonWidth*4;
   }
   if (ctl_size_y.p_y < ctltaglist.p_y) {
      ctl_size_y.p_y = ctltaglist.p_y;
   }
   if (ctl_size_y.p_y > clientH-ctl_size_y.p_height) {
      ctl_size_y.p_y = clientH-ctl_size_y.p_height;
   }

   // adjust y positions based on position of sizebar
   ctltagdocs.p_y = ctl_size_y.p_y_extent;
   edit1.p_y = title_height;

   // adjust height based on position of y-axis sizebar and client height
   ctltaglist.p_y_extent = ctl_size_y.p_y;
   ctl_size_x.p_height = clientH - 2*ctl_size_x.p_y;
   edit1.p_y_extent = clientH ;
   ctltagdocs.p_y_extent = clientH ;

   // adjust x positions based on position of sizebar
   edit1.p_x = ctl_size_x.p_x_extent;
   ctlbufname.p_x = edit1.p_x+_dx2lx(SM_TWIP,1);

   // adjust width based on position of x-axis sizebar and client height
   ctltaglist.p_x_extent = ctl_size_x.p_x;
   ctltagdocs.p_x_extent = ctl_size_x.p_x;
   ctl_size_y.p_width = ctl_size_x.p_x-ctltagdocs.p_x;
   edit1.p_x_extent = clientW ;

   // finally, adjust width of label
   ctlbufname.p_x_extent = clientW - layoutButtonWidth*4;
   ctlbufname.p_auto_size=false;
   edit1.SetSymbolInfoCaption(0, ctlbufname.p_user);
}

static int getPreviewWindowOrientation(int &clientW, int &clientH)
{
   // RGH - 4/26/2006
   // For the plugin, first resize the SWT container and then continue with the normal resize
   if (isEclipsePlugin()) {
      symbolContainer := _eclipse_getSymbolWindowQFormWID();
      if (!symbolContainer) return TOOLBAR_LAYOUT_ORIENTATION_AUTOMATIC;
      old_wid := p_window_id;
      // RGH - 4/26/2006
      // Need to set p_window_id so we can find the right controls
      p_window_id = symbolContainer;
      eclipse_resizeContainer(symbolContainer);
      clientW = symbolContainer.p_parent.p_width;
      clientH = symbolContainer.p_parent.p_height;
      // RGH - 4/26/2006
      // Switch p_window_id back
      if (isEclipsePlugin()) {
         p_window_id = old_wid;
      }
   } else { 
      clientW = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
      clientH = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   }

   // Determine toolbar orientation based on tool window height
   if (ctlautobtn.p_value) {
      if (clientW > (int)(6*clientH)) {
         return TOOLBAR_LAYOUT_ORIENTATION_HORIZONTAL;
      }
      //if (clientH > (int)(1.5*clientW)) {
      if (clientH > clientW + clientW intdiv 2) {
         return TOOLBAR_LAYOUT_ORIENTATION_VERTICAL;
      }
   }

   layoutOption := TOOLBAR_LAYOUT_ORIENTATION_STANDARD;
   if (ctlautobtn.p_value)       layoutOption = TOOLBAR_LAYOUT_ORIENTATION_HYBRID;
   if (ctlstandardbtn.p_value)   layoutOption = TOOLBAR_LAYOUT_ORIENTATION_STANDARD;
   if (ctlverticalbtn.p_value)   layoutOption = TOOLBAR_LAYOUT_ORIENTATION_VERTICAL;
   if (ctlhorizontalbtn.p_value) layoutOption = TOOLBAR_LAYOUT_ORIENTATION_HORIZONTAL;
   return layoutOption;
}

void _tbtagwin_form.on_resize()
{
   old_wid := p_window_id;
   clientW := 0;
   clientH := 0;
   // size buttons according to label height (and allow 33% larger)
   max_button_height := 2*ctlbufname.p_y+ctlbufname.p_height;
   max_button_height += (max_button_height intdiv 3);

   switch (getPreviewWindowOrientation(clientW, clientH)) {
   case TOOLBAR_LAYOUT_ORIENTATION_HORIZONTAL:
      resizePreviewWindowHorizontal(clientW, clientH, max_button_height);
      break;
   case TOOLBAR_LAYOUT_ORIENTATION_VERTICAL:
      resizePreviewWindowVertical(clientW, clientH, max_button_height);
      break;
   case TOOLBAR_LAYOUT_ORIENTATION_HYBRID:
      if (clientW == 0 && clientH == 0) return;
      resizePreviewWindowHybrid(clientW, clientH, max_button_height);
      break;
   case TOOLBAR_LAYOUT_ORIENTATION_STANDARD:
   default:
      if (clientW == 0 && clientH == 0) return;
      resizePreviewWindowStandard(clientW, clientH, max_button_height);
      break;
   }

   // RGH - 4/26/2006
   // Switch p_window_id back
   if (isEclipsePlugin()) {
      p_window_id = old_wid;
   }
}

static void resetLayoutButtons()
{
   ctlautobtn.p_value=0;
   ctlstandardbtn.p_value=0;
   ctlverticalbtn.p_value=0;
   ctlhorizontalbtn.p_value=0;
   ctlautobtn.p_enabled=true;
   ctlstandardbtn.p_enabled=true;
   ctlverticalbtn.p_enabled=true;
   ctlhorizontalbtn.p_enabled=true;
   p_value = 1;
   p_enabled = false;
}

void ctlhorizontalbtn.lbutton_up()
{
   resetLayoutButtons();
   call_event(p_active_form,ON_RESIZE,'w');
}
void ctlverticalbtn.lbutton_up()
{
   resetLayoutButtons();
   call_event(p_active_form,ON_RESIZE,'w');
}
void ctlstandardbtn.lbutton_up()
{
   resetLayoutButtons();
   call_event(p_active_form,ON_RESIZE,'w');
}
void ctlautobtn.lbutton_up()
{
   resetLayoutButtons();
   call_event(p_active_form,ON_RESIZE,'w');
}

void ctl_size_x.lbutton_down()
{
   switch (getPreviewWindowOrientation(auto clientW, auto clientH)) {
   case TOOLBAR_LAYOUT_ORIENTATION_HORIZONTAL:
      _ul2_image_sizebar_handler(ctltaglist.p_x, ctl_size_x2.p_x);
      break;
   case TOOLBAR_LAYOUT_ORIENTATION_HYBRID:
   case TOOLBAR_LAYOUT_ORIENTATION_STANDARD:
      if (clientW == 0 && clientH == 0) return;
      _ul2_image_sizebar_handler(ctltaglist.p_x, ctlautobtn.p_x);
      break;
   }
}
void ctl_size_x2.lbutton_down()
{
   switch (getPreviewWindowOrientation(auto clientW, auto clientH)) {
   case TOOLBAR_LAYOUT_ORIENTATION_HORIZONTAL:
      _ul2_image_sizebar_handler(ctltaglist.p_x+ctl_size_x.p_width, ctlautobtn.p_x);
      break;
   }
}
void ctl_size_y.lbutton_down()
{
   switch (getPreviewWindowOrientation(auto clientW, auto clientH)) {
   case TOOLBAR_LAYOUT_ORIENTATION_VERTICAL:
      _ul2_image_sizebar_handler(ctltaglist.p_y, edit1.p_y-ctl_size_y2.p_height);
      break;
   case TOOLBAR_LAYOUT_ORIENTATION_HYBRID:
      if (clientW == 0 && clientH == 0) return;
      _ul2_image_sizebar_handler(ctltaglist.p_y, edit1.p_y_extent);
      break;
   case TOOLBAR_LAYOUT_ORIENTATION_STANDARD:
      if (clientW == 0 && clientH == 0) return;
      _ul2_image_sizebar_handler(ctltagdocs.p_y, edit1.p_y_extent);
      break;
   }
}
void ctl_size_y2.lbutton_down()
{
   switch (getPreviewWindowOrientation(auto clientW, auto clientH)) {
   case TOOLBAR_LAYOUT_ORIENTATION_VERTICAL:
      _ul2_image_sizebar_handler(ctltaglist.p_y+ctl_size_y.p_height, edit1.p_y_extent);
      break;
   }
}

static bool _in_keyword(...)
{
   if (p_lexer_name=="") {
      return(false);
   }
   color := CFG_WINDOW_TEXT;
   in_ml_comment := arg(1);
   if (in_ml_comment==1) {
      color=_in_comment_common();
   } else {
      color = (CFGColorConstants)_clex_find(0,'g');
   }
   return(color==CFG_KEYWORD);
}

//We did this because it doesn't take any of the options that cur_word did
static _str mycur_word(VS_TAG_IDEXP_INFO &idexp_info)
{
   // find and call routine to get prefix expression
   lang := p_LangId;
   _str errorArgs[];
   tag_idexp_info_init(idexp_info);

   // Try finding get_expression_info for this extension.
   status := 0;
   get_index := _FindLanguageCallbackIndex("vs%s_get_expression_info",lang);
   if (get_index && index_callable(get_index) && _is_tokenlist_supported(lang)) {
      _UpdateContextAndTokens(true);
      status = call_index(false, _QROffset(), idexp_info, errorArgs, get_index);
      if (status == 0 && idexp_info.lastid != "") return idexp_info.lastid;
   }

   // Try finding get_expression_info for this extension.
   get_index = _FindLanguageCallbackIndex("_%s_get_expression_info",lang);
   if(get_index != 0) {
      struct VS_TAG_RETURN_TYPE visited:[];
      if (get_index && !call_index(false, idexp_info, visited, get_index) && idexp_info.lastid!="") {
         return idexp_info.lastid;
      }
   } else {
      // Revert to old get_idex
      get_index = _FindLanguageCallbackIndex("_%s_get_idexp",lang);
      info_flags := 0;
      typeless junk;
      _str prefixexp,lastid,otherinfo;
      int lastidstart_col,lastidstart_offset;
      if (get_index && 
          !call_index(junk,false, prefixexp, lastid,
                      lastidstart_col, lastidstart_offset,
                      info_flags, otherinfo, get_index) && 
          lastid != "") {
         idexp_info.prefixexp=prefixexp;
         idexp_info.lastid=lastid;
         idexp_info.lastidstart_col=lastidstart_col;
         idexp_info.lastidstart_offset=lastidstart_offset;
         idexp_info.info_flags=info_flags;
         idexp_info.otherinfo=otherinfo;
         return lastid;
      }
   }

   typeless sv_search_string,sv_flags,sv_word_re,sv_more;
   save_search(sv_search_string,sv_flags,sv_word_re,sv_more);
   col := _text_colc(p_col,'p');
   save_pos(auto p);
   word_chars := _clex_identifier_chars();
   common_re := '([~\od'word_chars']|^)\c[\od'word_chars']';
   common_re='('common_re')|^';
   status = search(common_re,'rh-@');
   if ( status || !match_length()) {
      restore_pos(p);
      restore_search(sv_search_string,sv_flags,sv_word_re,sv_more);
      return("");
   }

   start_col := p_col;
   idexp_info.lastidstart_col=start_col;
   idexp_info.lastidstart_offset=(int)_QROffset();
   
   //status=search('[~\od'p_word_chars']|$','r@');
   status=_TruncSearchLine('[~\od'word_chars']|$','r');
   if ( status) {
      _end_line();
   }
   word := _expand_tabsc(start_col,p_col-start_col);
   restore_pos(p);
   //start_col=_text_colc(start_col,'P');
   restore_search(sv_search_string,sv_flags,sv_word_re,sv_more);

   // fill in other ID expression information
   idexp_info.prefixexp="";
   idexp_info.lastid=word;
   idexp_info.info_flags=0;
   idexp_info.otherinfo="";
   return(word);
}

// Need to be able to call this from proctree.e
int _GetTagwinWID(bool only_when_active=false)
{
   if (!_haveContextTagging()) return 0;
   wid := tw_find_form(TBPREVIEW_FORM);

   // check if the tagwin is the active tab
   if( wid > 0 && only_when_active ) {
      if( !tw_is_wid_active(wid)) {
         return 0;
      }                  
   }
   return wid;
}
int _tbGetActivePreviewForm() 
{
   if (!_haveContextTagging()) return 0;
   return _GetTagwinWID();
}
/**
 * Get the window ID of the editor control in the Preview tool window.
 */
int _GetTagwinEditorWID(bool only_when_active=false)
{
   if (!_haveContextTagging()) return 0;
   wid := _GetTagwinWID(only_when_active);
   return (wid > 0)? wid.edit1.p_window_id : 0;
}
static bool TagWinFocus(int FormWID=-1)
{
   FocusWID := _get_focus();
   if (FormWID<0) {
      FormWID = _GetTagwinWID();
   }
   if (FormWID == 0) return false;
   if ( FocusWID==FormWID || 
        FocusWID==FormWID.edit1 || 
        FocusWID==FormWID.ctltagdocs ||
        FocusWID==FormWID.ctltaglist) {
      return true;
   }
   return false;
}

_command void toggle_activate_preview() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Preview window");
      return;
   }
   if (def_activate_preview & APF_ON) def_activate_preview &= ~APF_ON;
   else def_activate_preview |= APF_ON;
}

/**
 * Activate the symbol window to preview the current tag under the cursor.
 * This will expose the symbol window if it is not docked or if it is
 * auto-hidden.  If it was auto-hidden, it will unhind itself after
 * five seconds.
 * 
 * @param cm    tag information to preview, if not specified,
 *              it will find the symbol under the cursor.
 */
_command void preview_tag(VS_TAG_BROWSE_INFO cm=null) name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Preview window");
      return;
   }
   orig_auto_hide_delay := _default_option(VSOPTION_TOOLWINDOW_AUTOHIDE_DELAY);
   _default_option(VSOPTION_TOOLWINDOW_AUTOHIDE_DELAY, 5000);
   wid := activate_tool_window("_tbtagwin_form",false,"ctltaglist");
   form_wid := wid.p_active_form;
   if (form_wid.TBPREVIEW_TIMER() >= 0) {
      _kill_timer(form_wid.TBPREVIEW_TIMER());
      form_wid.TBPREVIEW_TIMER(-1);
   }
   _default_option(VSOPTION_TOOLWINDOW_AUTOHIDE_DELAY, orig_auto_hide_delay);
   if (cm==null) {
      form_wid._UpdateTagWindow(AlwaysUpdate:true);
   } else {
      form_wid.cb_refresh_output_tab(cm,true,true);
   }
}

/**
 * Move to the next symbol in the preview window.
 */
_command void preview_prev_symbol() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Preview window");
      return;
   }
   form_wid := _tbGetActivePreviewForm();
   if (!form_wid) {
      return;
   }
   if (form_wid.TBPREVIEW_TIMER() >= 0) {
      _kill_timer(form_wid.TBPREVIEW_TIMER());
      form_wid.TBPREVIEW_TIMER(-1);
   }
   _nocheck _control ctltaglist;
   tree_wid := form_wid.ctltaglist;

   if (tree_wid._TreeUp()) {
      tree_wid._TreeBottom();
   }
}

/**
 * Move to the next symbol in the preview window.
 */
_command void preview_next_symbol() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Preview window");
      return;
   }
   form_wid := _tbGetActivePreviewForm();
   if (!form_wid) {
      return;
   }
   if (form_wid.TBPREVIEW_TIMER() >= 0) {
      _kill_timer(form_wid.TBPREVIEW_TIMER());
      form_wid.TBPREVIEW_TIMER(-1);
   }
   _nocheck _control ctltaglist;
   tree_wid := form_wid.ctltaglist;

   if (tree_wid._TreeDown()) {
      tree_wid._TreeTop();
   }
}

/**
 * Move the editor control one line down in the preview window.
 */
_command void preview_cursor_down() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Preview window");
      return;
   }
   wid := _GetTagwinWID(true);
   if (wid) {
      wid.edit1.cursor_down();
   } else if (p_object == OI_TREE_VIEW) {
      call_event(defeventtab _ul2_tree, C_DOWN, "e");  
   }
}

/**
 * Move the editor control one line up in the preview window.
 */
_command void preview_cursor_up() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Preview window");
      return;
   }
   wid := _GetTagwinWID(true);
   if (wid) {
      wid.edit1.cursor_up();
   } else if (p_object == OI_TREE_VIEW) {
      call_event(defeventtab _ul2_tree, C_UP, "e");  
   }
}

/**
 * Page the editor control one page down in the preview window.
 */
_command void preview_page_down() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Preview window");
      return;
   }
   wid := _GetTagwinWID(true);
   if (wid) {
      wid.edit1.page_down();
   } else if (p_object == OI_TREE_VIEW) {
      call_event(defeventtab _ul2_tree, C_PGDN, "e");  
   }
}

/**
 * Page the editor control one page up in the preview window.
 */
_command void preview_page_up() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Preview window");
      return;
   }
   wid := _GetTagwinWID(true);
   if (wid) {
      wid.edit1.page_up();
   } else if (p_object == OI_TREE_VIEW) {
      call_event(defeventtab _ul2_tree, C_PGUP, "e");  
   }
}

/**
 * Make the current form respond to the keys to control the preview window
 */
void _MakePreviewWindowShortcuts()
{
   set_eventtab_index(p_eventtab, event2index(C_UP),   find_index("preview_cursor_up",   COMMAND_TYPE));
   set_eventtab_index(p_eventtab, event2index(C_DOWN), find_index("preview_cursor_down", COMMAND_TYPE));
   set_eventtab_index(p_eventtab, event2index(C_PGUP), find_index("preview_page_up",     COMMAND_TYPE));
   set_eventtab_index(p_eventtab, event2index(C_PGDN), find_index("preview_page_down",   COMMAND_TYPE));
}


/**
 * Search for matches to the symbol under the cursor.
 * @param search_tag_name
 */
static void tagwin_match_tag(_str &search_tag_name, bool forceCaseInsenstive=false)
{
   // update the current context and locals
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);
   _UpdateContextAndTokens(true);
   _UpdateLocals(true);

   // drop into embedded language mode if necessary
   struct VS_TAG_RETURN_TYPE visited:[];
   embedded_status := _EmbeddedStart(auto orig_values);
   case_sensitive := p_EmbeddedCaseSensitive && !forceCaseInsenstive;

   // use intelligent Context Tagging(R) function
   _str errorArgs[]; errorArgs._makeempty();
   num_matches := context_match_tags(errorArgs,search_tag_name,
                                     false,PREFIXMATCHEDMAXLISTCOUNT,
                                     true, case_sensitive, visited);

   // no search tag name, try cur_word()
   if (num_matches<=0 && search_tag_name=="") {
      VS_TAG_IDEXP_INFO idexp_info;
      search_tag_name = mycur_word(idexp_info);
   }

   // no matches, try dumber symbol lookup
   tag_files := tags_filenamea(p_LangId);
   if (num_matches <= 0 && !_CheckTimeout()) {
      tag_clear_matches();
      tag_list_symbols_in_context(search_tag_name, "", 
                                  0, 0, tag_files, "",
                                  num_matches, PREFIXMATCHEDMAXLISTCOUNT,
                                  def_tagwin_flags, 
                                  SE_TAG_CONTEXT_ALLOW_LOCALS,
                                  true, case_sensitive, visited, 1);
   }

   // no matches, try even more desparately stupid search 
   color := _clex_find(0,'g');
   if (num_matches <= 0 && !_CheckTimeout() && color != CFG_KEYWORD && color != CFG_PPKEYWORD && color != CFG_LINENUM) {
      tag_list_any_symbols(0,0,search_tag_name,tag_files,
                           def_tagwin_flags,SE_TAG_CONTEXT_ANYTHING,
                           num_matches,PREFIXMATCHEDMAXLISTCOUNT,
                           true, case_sensitive, visited, 1);
   }

   // drop out of embedded language mode
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
}

/**
 * Saves the tag info to be shown in the preview window.
 * 
 * @param cm 
 * @return 
 */
void tagwin_save_tag_info(VS_TAG_BROWSE_INFO &cm) 
{
   form_wid := _GetTagwinWID();
   if (form_wid) {
      gPreviewFormList:[form_wid].m_tagwin_saved_info = cm;
      gPreviewFormList:[form_wid].m_tagwin_use_editor = (gPreviewFormList:[form_wid].m_tagwin_saved_info == null);
   }
}

/**
 * Kill the last delayed Preview window update.
 */
void kill_tagwin_delay_timer()
{
   wid := _GetTagwinWID(true);
   if (!wid) return;
   if (wid.TBPREVIEW_TIMER() >= 0) {
      _kill_timer(wid.TBPREVIEW_TIMER());
      wid.TBPREVIEW_TIMER(-1);
   }
}

static void _UpdateTagWindowNow(struct VS_TAG_BROWSE_INFO cm=null)
{
   wid := _GetTagwinWID(true);
   if (!wid) return;

   if (wid.TBPREVIEW_TIMER() >= 0) {
      _kill_timer(wid.TBPREVIEW_TIMER());
      wid.TBPREVIEW_TIMER(-1);
   } else if (cm != null) {
      // we shouldn't be here
      return;
   }
   if (cm != null) {
      if (!gPreviewFormList._indexin(wid) || gPreviewFormList:[wid].m_tagwin_lastItem == null) {
         wid.savePreviewWindow(gPreviewFormList:[wid].m_tagwin_lastItem);
      }
      _UpdateTagWindow(AlwaysUpdate:true, cm, form_wid:wid);
   } else {
      if (gPreviewFormList._indexin(wid) && gPreviewFormList:[wid].m_tagwin_lastItem != null && gPreviewFormList:[wid].m_tagwin_lastItem.fileText != null) {
         wid.restorePreviewWindow(gPreviewFormList:[wid].m_tagwin_lastItem);
         gPreviewFormList:[wid].m_tagwin_lastItem = null;
      } else if (!_no_child_windows()) {
         child_wid := _MDIGetActiveMDIChild();
         if (child_wid) {
            gPreviewFormList:[wid].m_LastModified= child_wid.p_LastModified-1;
            gPreviewFormList:[wid].m_forceUpdate = true;
            //child_wid.p_ModifyFlags &= ~MODIFYFLAG_TAGWIN_UPDATED;
         }
      }
   }
}
/**
 * After a specified amount of delay (using a timer), update the 
 * preview window to display the given symbol. 
 * 
 * @param cm   Symbol information to display
 * @param ms   number of milliseconds to delay
 */
void _UpdateTagWindowDelayed(struct VS_TAG_BROWSE_INFO &cm=null, int ms=100)
{
   static VS_TAG_BROWSE_INFO last_cm;
   if (ms > 0) {
      if (last_cm != null && tag_browse_info_equal(cm, last_cm)) return;
      wid := _GetTagwinWID(true);
      if (!wid) return;
      if (wid.TBPREVIEW_TIMER() >= 0) {
         _kill_timer(wid.TBPREVIEW_TIMER());
         wid.TBPREVIEW_TIMER(-1);
      }
      wid.TBPREVIEW_TIMER(_set_timer(ms, _UpdateTagWindowNow, cm));
      last_cm = cm;
   } else {
      _UpdateTagWindowNow(cm);
   }
}

static void _UpdateOneTagWindow(int form_wid,
                                PREVIEW_FORM_INFO &formInfo, 
                                long elapsed,
                                int editorctl_wid,
                                bool AlwaysUpdate=false, 
                                struct VS_TAG_BROWSE_INFO &cm=null, 
                                struct VS_TAG_BROWSE_INFO (&cmlist)[]=null)
{
   // idle timer elapsed?
   if (!AlwaysUpdate && formInfo.m_tagwin_use_editor && elapsed <= def_update_tagging_idle) {
      return;
   }
   // make sure the form that was passed in is valid
   if (!AlwaysUpdate && !tw_is_wid_active(form_wid)) {
      return;
   }
   // do not update tag window if another window has a pending symbol to show
   if (!AlwaysUpdate && cm==null && cmlist==null && form_wid.TBPREVIEW_TIMER() >= 0) {
      return;
   }
   /*
      Don't use the focus editor if 
         focus_wid.p_mdi_child &&
         tw_is_docked_window(form_wid) and _MDIFromChild(form_wid)!=_MDIFromChild(focus_wid)

      Don't apply exclusion if
         
         tw_is_docked_window(form_wid) and _MDIFromChild(form_wid)!=_MDIFromChild(focus_wid)


   */

   // this is the editor, so we need to null out whatever we previously saved
   focus_wid := _get_focus();
   if (!AlwaysUpdate && focus_wid && focus_wid._isEditorCtl() && !_isGrepBuffer(focus_wid.p_buf_name)) {
      if (!(focus_wid.p_mdi_child && tw_is_docked_window(form_wid) && _MDIFromChild(form_wid)!=_MDIFromChild(focus_wid))  ) {
         //say('case1 f='form_wid' m='focus_wid.p_mdi_child' d='tw_is_docked_window(form_wid)' d1='_MDIFromChild(form_wid)' '_MDIFromChild(focus_wid));
         formInfo.m_tagwin_use_editor = true;
         formInfo.m_tagwin_saved_info = null;
      }
   }

   if (!AlwaysUpdate && TagWinFocus(form_wid)) {
      //say('return');
      return;
   }

   // if we have no parameter context info, use the saved stuff
   if (cm == null && cmlist == null && 
       !formInfo.m_tagwin_use_editor && 
       formInfo.m_tagwin_saved_info != null &&
       formInfo.m_tagwin_saved_info.member_name != null &&
       formInfo.m_tagwin_saved_info.member_name != "") {
      cm = formInfo.m_tagwin_saved_info;
      formInfo.m_tagwin_saved_info = null;
   }

   curr_seekpos := 0L;
   set_last_edit_pos := false;
   if (cm == null && cmlist==null) {
      //say('h1 f='form_wid);
      // Check if the current form having focus was one of the
      // forms that explicitely updated the tag window.
      // If so, then drop out of here and do not update the
      // preview window based on what is in _mdi.p_child.
      if ( focus_wid && (!formInfo.m_tagwin_use_editor || !AlwaysUpdate) ) {
         focus_form := focus_wid.p_active_form.p_name;
         typeless * phash = form_wid._GetDialogInfoHtPtr(TBPREVIEW_EXCLUSIONS);
         if (phash != null && phash->_indexin(focus_form)) {
            if (!(tw_is_docked_window(form_wid) && _MDIFromChild(form_wid)!=_MDIFromChild(focus_wid))  ) {
               return;
            }
         }
      }

      // DJB 01-27-2021
      // if the editor control that was passed in is not valid, try to use the focus wid
      if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl() || editorctl_wid == form_wid.edit1.p_window_id) {
         editorctl_wid = focus_wid;
      }

      // DJB 01-27-2021
      // editor control still not valid choice?  try the "current" window ID then
      if (!editorctl_wid || !editorctl_wid._isEditorCtl() || editorctl_wid == form_wid.edit1.p_window_id) {
         if (p_window_id._isEditorCtl()) {
            //say('case2 f='form_wid' m='focus_wid.p_mdi_child' d='tw_is_docked_window(form_wid)' d1='_MDIFromChild(form_wid)' '_MDIFromChild(focus_wid));
            editorctl_wid = p_window_id;
         } else {
            //say('case3 f='form_wid' m='focus_wid.p_mdi_child' d='tw_is_docked_window(form_wid)' d1='_MDIFromChild(form_wid)' '_MDIFromChild(focus_wid));
            editorctl_wid = 0;
         }
      }

      // DJB 01-27-2021
      // do not let an editor window from a different MDI group update this preview window.
      if (editorctl_wid && editorctl_wid.p_mdi_child && tw_is_docked_window(form_wid) && _MDIFromChild(form_wid)!=_MDIFromChild(editorctl_wid)) {
         return;
      }

      if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl()) {
         orig_wid := p_window_id;
         p_window_id=form_wid.edit1;
         if (p_buf_id != form_wid.EditWindowBufferID()) {
            if (p_buf_flags&VSBUFFLAG_HIDDEN) {
               if (_SafeToDeleteBuffer(p_buf_id,p_window_id,p_buf_flags)) {
                  //say("_cbmdibuffer_hidden_symbols Calling tagwin_quit_file()");
                  tagwin_quit_file();
               }
            }

            // Load the ".Tag Window Buffer"
            _ClearTagWindowForm(form_wid);
         }
         // restore the window ID
         p_window_id=orig_wid;
         return;
      }

      // DJB 01-27-2021
      // skip out of here if nothing has changed, OR if the cursor is
      // still in the same place we had jumped to from the Preview window.
      curr_seekpos = editorctl_wid._QROffset();
      if ( !AlwaysUpdate && editorctl_wid.p_LastModified==formInfo.m_LastModified ) {
         if (curr_seekpos == formInfo.m_tagwin_last_seekpos) return;
         if (curr_seekpos == formInfo.m_tagwin_last_jumppos) return;
      }
      form_wid.edit1.SetSymbolInfoCaption(0);
      if (!editorctl_wid._istagging_supported()) {
         return;
      }

      // check if the Preview tool window is disabled for this language
      if (!AlwaysUpdate && (editorctl_wid._GetCodehelpFlags() & VSCODEHELPFLAG_NO_PREVIEW_INFO)) {
         return;
      }

      set_last_edit_pos=true;

   } else {
      // The form having focus when this is called should
      // be put on the list of forms who, if they have focus
      // we should not update the Preview window on the
      // autosave timer.
      if ( focus_wid ) {
         focus_form := focus_wid.p_active_form.p_name;
         if (focus_form != "") {
            typeless * phash = form_wid._GetDialogInfoHtPtr(TBPREVIEW_EXCLUSIONS);
            if (phash == null) {
               bool hash:[];
               hash:[focus_form] = true;
               form_wid._SetDialogInfoHt(TBPREVIEW_EXCLUSIONS, hash);
            } else if (!phash->_indexin(focus_form)) {
               (*phash):[focus_form] = true;
            }
         }
      }
   }

   // idle timer elapsed?
   if (!AlwaysUpdate && 
       editorctl_wid && _iswindow_valid(editorctl_wid) && 
       !editorctl_wid._ContextIsUpToDate(elapsed, MODIFYFLAG_CONTEXT_UPDATED|MODIFYFLAG_TOKENLIST_UPDATED)) {
      return;
   }
   if (form_wid.TBPREVIEW_TIMER() >= 0) {
      _kill_timer(form_wid.TBPREVIEW_TIMER());
      form_wid.TBPREVIEW_TIMER(-1);
   }

   formInfo.m_tagwin_last_jumppos = -1;
   if (set_last_edit_pos) {
      formInfo.m_tagwin_last_seekpos = curr_seekpos;
      //editorctl_wid.p_ModifyFlags |= MODIFYFLAG_TAGWIN_UPDATED;
      formInfo.m_LastModified=editorctl_wid.p_LastModified;
   }

   formInfo.m_forceUpdate = AlwaysUpdate;
   symbol_search_timed_out := false;
   case_insensitive_matches_exist := false;
   preferred_match_id := 1;
   tag_push_matches();

   typeless errorArgs;
   tagname := "";
   if (cm != null && cm.member_name != null && cm.member_name != "") {
      tag_insert_match_info(cm);
      //say('match h1 f='form_wid' mdi='_MDIFromChild(form_wid));
   } else if (cmlist != null) {
      for (j:=0; j<cmlist._length(); ++j) {
         if (cmlist[j]==null) continue;
         tag_insert_match_info(cmlist[j]);
      }
      //say('match h2 f='form_wid' mdi='_MDIFromChild(form_wid));
   } else {

      // check if the tag database is busy and we can't get a lock.
      dbName := _GetWorkspaceTagsFilename();
      haveDBLock := tag_trylock_db(dbName);
      if (!AlwaysUpdate && !haveDBLock) {
         tag_pop_matches();
         return;
      }

      // timeout if this takes too long
      sc.lang.ScopedTimeoutGuard timeout(def_preview_window_timeout);

      // search for matches to the symbol under the cursor
      //say('match h3 f='form_wid' mdi='_MDIFromChild(form_wid)' buf='_strip_filename(editorctl_wid.p_buf_name,'P'));
      //say('match h4 line='editorctl_wid.p_line" col="editorctl_wid.p_col" seek="editorctl_wid._QROffset());
      //say('match h5 editorctl_wid='editorctl_wid "edit1="form_wid.edit1.p_window_id);
      editorctl_wid.tagwin_match_tag(tagname);
      if (tag_get_num_of_matches() <= 0) {
         if (_CheckTimeout()) {
            symbol_search_timed_out = true;
         } else {
            editorctl_wid.tagwin_match_tag(tagname, true);
            if (tag_get_num_of_matches() > 0 && (editorctl_wid._GetCodehelpFlags() & VSCODEHELPFLAG_GO_TO_DEF_CASE_SENSITIVE)) {
               case_insensitive_matches_exist = true;
               tag_clear_matches();
            }
         }
      }

      // remove duplicate tags
      tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:false, 
                                          filterDuplicateGlobalVars:false, 
                                          filterDuplicateClasses:true, 
                                          filterAllImports:true,
                                          filterBinaryLoadedTags:true);

      // filter tags based on filtering criteria
      tag_filter_symbols_from_matches(def_tagwin_flags);

      // find the preferred match (definition or declaration) to auto-select
      codehelp_flags := editorctl_wid._GetCodehelpFlags();
      preferred_match_id = editorctl_wid.tag_check_for_preferred_symbol(codehelp_flags);
      if (preferred_match_id <= 0) preferred_match_id=1;

      // see if the statement under the cursor is a #include or variant
      if (tag_get_num_of_matches() == 0) {
         status := editorctl_wid.tag_get_current_include_info(cm);
         if (!status) {
            found_files := cm.file_name;
            status=editorctl_wid._resolve_include_file(found_files, true);
            if (!status) {
               foreach (auto f in found_files) {
                  cm.file_name = f;
                  if (cm.member_name == "") cm.member_name = _strip_filename(cm.file_name, 'P');
                  if (cm.type_name == "")   cm.type_name = "file";
                  tag_insert_match_info(cm);
               }
            }
         }
      }
      // see if the word under the cursor is a keyword that indicates a jump
      if (tag_get_num_of_matches() == 0) {
         status := editorctl_wid.tag_get_continue_or_break_info(cm.line_no, cm.seekpos);
         if (!status && cm.line_no > 0) {
            cm.file_name = editorctl_wid.p_buf_name;
            cm.type_name = "statement";
            cm.member_name = tagname;
            tag_insert_match_info(cm);
         }
      }

      // if we got a trylock, then release it now
      if (haveDBLock) {
         tag_unlock_db(dbName);
      }
   }

   _nocheck _control ctltaglist;
   _nocheck _control ctl_back;
   _nocheck _control ctl_forward;
   _nocheck _control ctl_push_tag;
   _nocheck _control ctl_find_refs;
   _nocheck _control ctl_symbols;
   _nocheck _control ctltagdocs;

   curr_index := 0;
   n := tag_get_num_of_matches();
   form_wid.ctltaglist._TreeBeginUpdate(TREE_ROOT_INDEX);
   for (i:=1; i<=n; ++i) {
      tag_get_match_info(i,cm);
      k := tag_tree_insert_fast(form_wid.ctltaglist.p_window_id, TREE_ROOT_INDEX, 
                                VS_TAGMATCH_match, i, 0, 1, 
                                TREE_ADD_AS_CHILD, 1, 1, cm);
      if (i==preferred_match_id) curr_index=k;
   }
   form_wid.ctltaglist._TreeEndUpdate(TREE_ROOT_INDEX);
   /*
     Need this first set cur index to force the on_change in the
     second. The first set cur index will sometimes cause an
     on_change (seems to generate index=-1 reason=CHANGE_SCROLL).
   */
   if (curr_index > 0) {
      form_wid.ctltaglist._TreeSetCurIndex(TREE_ROOT_INDEX);
      form_wid.ctltaglist._TreeSetCurIndex(curr_index);
   }
   form_wid.ctltaglist._TreeRefresh();

   if (n==0) {
      msg := "<i>no matching symbols</i>";
      if (case_insensitive_matches_exist) {
         msg = "<i>no matching symbols, but case-insensitive matches exist</i>";
      } else if (symbol_search_timed_out) {
         msg = "<i>symbol lookup timeout expired.</i>";
      }
      _ClearTagWindowForm(form_wid, msg);
   }

   form_wid.ctl_back.p_enabled=false;
   form_wid.ctl_forward.p_enabled=false;
   form_wid.ctltagdocs.p_user = null;

   form_wid.ctl_push_tag.p_enabled  = (n > 0);
   form_wid.ctl_find_refs.p_enabled = (n > 0);
   form_wid.ctl_symbols.p_enabled   = (n > 0);

   tag_pop_matches();

}
/**
 * Update the preview window.
 * 
 * @param AlwaysUpdate  force update
 * @param cm            [optional] specific symbol information to display
 * @param cmlist        [optional] list of symbols to display 
 * @param form_wid      [optional] instance of Preview tool window to update
 */
void _UpdateTagWindow(bool AlwaysUpdate=false, 
                      struct VS_TAG_BROWSE_INFO &cm=null, 
                      struct VS_TAG_BROWSE_INFO (&cmlist)[]=null,
                      int form_wid=-1)
{
   if (form_wid<0) {
      form_wid =_GetTagwinWID(!AlwaysUpdate);
   }
   if (!form_wid) {
      return;
   }

   //say('_UpdateOne f='form_wid' cm='(cm==null));
   _UpdateOneTagWindow(form_wid,gPreviewFormList:[form_wid],_idle_time_elapsed(),
                       form_wid._MDIGetActiveMDIChild(),AlwaysUpdate,cm,cmlist);
}

void _MaybeUpdateAllTagWindows(bool AlwaysUpdate=false) {
   _UpdateAllTagWindows(AlwaysUpdate);
}

void _UpdateAllTagWindows(bool AlwaysUpdate=false,
                          struct VS_TAG_BROWSE_INFO &cm=null, 
                          struct VS_TAG_BROWSE_INFO (&cmlist)[]=null
                          ) 
{
   // idle timer elapsed?
   elapsed := _idle_time_elapsed();
   if (!AlwaysUpdate && elapsed <= def_update_tagging_idle) {
      return;
   }

   PREVIEW_FORM_INFO v;
   foreach (auto i => v in gPreviewFormList) {
      if (!_iswindow_valid(i)) continue;
      child_wid := i._MDIGetActiveMDIChild();
      //say('_UpdateAllTagWindows: f='i' c='child_wid 'cm='(cm==null));
      cm_copy := cm;
      cmlist_copy := cmlist;
      _UpdateOneTagWindow(v.m_form_wid,gPreviewFormList:[i],elapsed,child_wid,AlwaysUpdate,cm_copy,cmlist_copy);
   }
}

static void _ClearTagWindowForm(int form_wid, _str msg="<i>no matching symbols</i>") 
{
   form_wid.ctltaglist._TreeDelete(TREE_ROOT_INDEX,"C");
   form_wid.ctltagdocs.p_text=msg;
   form_wid.ctlbufname.p_user="";
   form_wid.ctlbufname.p_caption="";
   form_wid.edit1.load_files("+q +m +bi "form_wid.EditWindowBufferID());
   form_wid.edit1.p_redraw=true;
   form_wid.edit1._lbclear();
   form_wid.edit1.insert_line("");
   form_wid.edit1.p_line=1;
   form_wid.edit1.line_to_top();
   form_wid.edit1.p_scroll_left_edge=-1;
   form_wid.edit1.p_window_flags &= ~(CURLINE_COLOR_WFLAG|CURLINE_RECT_WFLAG);
      
   gPreviewFormList:[form_wid].m_tagwin_last_seekpos = -1;
   gPreviewFormList:[form_wid].m_LastModified = -1;
   gPreviewFormList:[form_wid].m_forceUpdate = false;
   gPreviewFormList:[form_wid].m_tagwin_last_jumppos = -1;

   form_wid.ctl_back.p_enabled=false;
   form_wid.ctl_forward.p_enabled=false;
   form_wid.ctltagdocs.p_user = null;

   form_wid.ctl_push_tag.p_enabled  = false;
   form_wid.ctl_find_refs.p_enabled = false;
   form_wid.ctl_symbols.p_enabled   = false;
}
void _ClearTagWindowForBuffer(int buf_id)
{
   // this is the editor, so we need to null out whatever we previously saved
   editorctl_wid := p_window_id;
   if (!_isEditorCtl()) {
      return;
   }

   PREVIEW_FORM_INFO v;
   int i;
   foreach (i => v in gPreviewFormList) {
      if (!_iswindow_valid(i)) continue;
      wid := i;
      if (wid.edit1.p_buf_id == buf_id) {
         _nocheck _control ctltaglist;
         _nocheck _control ctl_back;
         _nocheck _control ctl_forward;
         _nocheck _control ctl_push_tag;
         _nocheck _control ctl_find_refs;
         _nocheck _control ctl_symbols;
         _nocheck _control ctltagdocs;

         _ClearTagWindowForm(wid);
      }
   }


}

static void mdi_update_tagwin(int form_wid)
{
   if (!_iswindow_valid(form_wid) || form_wid.p_name!=TBPREVIEW_FORM) {
      return;
   }
   child_wid := form_wid._MDIGetActiveMDIChild();
   if (child_wid && TagWinFocus()) {
      child_wid._UpdateTagWindow(AlwaysUpdate:true, form_wid:form_wid);
   }
}

/**
 * Make this form respond to the same keys for push-tag and
 * find references that are set in the editor control
 */
static void createPreviewSymbolShortcuts()
{
   _nocheck _control ctl_push_tag;
   _nocheck _control ctl_find_refs;
   _nocheck _control ctl_symbols;
   _nocheck _control edit1;
   int keys[];

   copy_key_bindings_to_form("push_tag", ctl_push_tag,  LBUTTON_UP, keys);
   copy_key_bindings_to_form("find_tag", ctl_push_tag,  LBUTTON_UP, keys);
   copy_key_bindings_to_form("push_ref", ctl_find_refs, LBUTTON_UP, keys);
   copy_key_bindings_to_form("find_refs",ctl_find_refs, LBUTTON_UP, keys);
   copy_key_bindings_to_form("cb_find",  ctl_symbols,   LBUTTON_UP, keys);

   copy_default_key_bindings("push_tag",    edit1.p_window_id);
   copy_default_key_bindings("push_alttag", edit1.p_window_id);
   copy_default_key_bindings("push_decl",   edit1.p_window_id);
   copy_default_key_bindings("push_def",    edit1.p_window_id);
   copy_default_key_bindings("find_tag",    edit1.p_window_id);
   copy_default_key_bindings("push_ref",    edit1.p_window_id);
   copy_default_key_bindings("find_refs",   edit1.p_window_id);
   copy_default_key_bindings("cb_find",     edit1.p_window_id);

   copy_default_key_bindings("wfont-zoom-in",  edit1.p_window_id);
   copy_default_key_bindings("wfont-zoom-out", edit1.p_window_id);
   copy_default_key_bindings("wfont-unzoom",   edit1.p_window_id);

   TBPREVIEW_KEYS(keys);
}

/**
 * Remove the bindings that were set up in
 * {@link createPreviewSymbolShortCuts()}, above.
 */
static void unbindPreviewSymbolShortcuts()
{
   _nocheck _control ctl_push_tag;
   keys := TBPREVIEW_KEYS();
   n := keys._length();
   for (i:=0; i<n; ++i) {
      set_eventtab_index(p_active_form.p_eventtab, keys[i], 0);
   }

   msg := "";
   parse ctl_push_tag.p_message with msg "(" .; 
   ctl_push_tag.p_message = msg;
   parse ctl_find_refs.p_message with msg "(" .;
   ctl_find_refs.p_message = msg;
   parse ctl_symbols.p_message with msg "(" .;
   ctl_symbols.p_message =msg;
}

/**
 * Callback for key binding / emulation changes
 */
void _eventtab_modify_preview_symbol(typeless keytab_used, _str event="")
{
   kt_index := find_index("default_keys", EVENTTAB_TYPE);
   if (keytab_used && kt_index != keytab_used) {
      return;
   }
   // Need this because defmain() firstinit calls this BEFORE
   // the definit() get calls. Make sure there is a tool window
   // running
   form_wid := _GetTagwinWID();
   if (!form_wid) {
      return;
   }
   PREVIEW_FORM_INFO v;
   int i;
   foreach (i => v in gPreviewFormList) {
      if (!_iswindow_valid(i)) continue;
      wid := i;
      wid.unbindPreviewSymbolShortcuts();
      wid.createPreviewSymbolShortcuts();
   }
}

edit1.on_create()
{
   PREVIEW_FORM_INFO formInfo;
   formInfo.m_form_wid=p_active_form;
   formInfo.m_tagwin_last_seekpos= -1;
   formInfo.m_tagwin_saved_info= null;
   formInfo.m_tagwin_use_editor= false;
   formInfo.m_tagwin_lastItem= null;
   formInfo.m_LastModified= -1;
   formInfo.m_forceUpdate = false;
   formInfo.m_tagwin_last_seekpos = -1;
   gPreviewFormList:[p_active_form]=formInfo;
   TBPREVIEW_TIMER(-1);

   gtagwin_in_quit_file=false;
   p_window_flags|=VSWFLAG_NOLCREADWRITE;
   p_window_flags|=(OVERRIDE_CURLINE_RECT_WFLAG|OVERRIDE_CURLINE_COLOR_WFLAG);
   p_window_flags &= ~(CURLINE_RECT_WFLAG|CURLINE_COLOR_WFLAG);
   p_MouseActivate=MA_NOACTIVATE;
   //MK - changed this to match 9.0, doesn't work for plugin
   //_shellEditor.p_MouseActivate=MA_NOACTIVATE;
   
   //If I set tabs during the on_create it seemed to get hosed...
   //p_tabs='1 7 15 52';
   p_tabs="1 9 41";

   // (+m) Since we don't know what buffer is active here,
   // don't save previous buffer currsor location.
   if (p_buf_id <= 0) {
      status := load_files("+m +q +b ":+_maybe_quote_filename(TBPREVIEW_DOC_NAME));
      if (status) {
         // Since most strings are UTF-8, use UTF-8 encoding for buffer
         load_files("+m +futf8 +q +t");
         p_buf_name=TBPREVIEW_DOC_NAME;
         p_buf_flags|=VSBUFFLAG_HIDDEN|VSBUFFLAG_THROW_AWAY_CHANGES;
      }
   }

   EditWindowBufferID(p_buf_id);
   _UpdateTagWindow(AlwaysUpdate:false, form_wid:p_active_form);
   if (!p_Noflines) {
      insert_line("");
   }
   p_line=1;
   line_to_top();
   p_scroll_left_edge=-1;
   _post_call(mdi_update_tagwin,p_active_form);
   ctlbufname.p_user="";
   ctlbufname.p_caption="";
   edit1.SetSymbolInfoCaption(0);
   ctl_back.p_enabled=false;
   ctl_forward.p_enabled=false;

   // restore position of divider bars
   xpos := _moncfg_retrieve_value("_tbtagwin_form.ctl_size_x.p_x");
   if (isuinteger(xpos)) {
      ctl_size_x.p_x = xpos;
   }
   ypos := _moncfg_retrieve_value("_tbtagwin_form.ctl_size_y.p_y");
   if (isuinteger(ypos)) {
      ctl_size_y.p_y = ypos;
   }
   xpos = _moncfg_retrieve_value("_tbtagwin_form.ctl_size_x2.p_x");
   if (isuinteger(xpos)) {
      ctl_size_x2.p_x = xpos;
   } else {
      ctl_size_x2.p_x = ctl_size_x.p_x*2;
   }
   ypos = _moncfg_retrieve_value("_tbtagwin_form.ctl_size_y2.p_y");
   if (isuinteger(ypos)) {
      ctl_size_y2.p_y = ypos;
   } else {
      ctl_size_y2.p_x = ctl_size_y.p_y*2;
   }
   fontsize := _retrieve_value("_tbtagwin_form.edit1.p_font_size");
   if (isuinteger(fontsize) && fontsize > 0) {
      edit1.p_font_size = fontsize;
   }
   fontsize = _retrieve_value("_tbtagwin_form.ctltagdocs.p_font_size");
   if (isuinteger(fontsize) && fontsize > 0) {
      ctltagdocs._minihtml_command("zoom "fontsize);
   }

   expand := _moncfg_retrieve_value("_tbtagwin_form.ctlautobtn.p_value");
   if (!isuinteger(expand)) expand = TOOLBAR_LAYOUT_ORIENTATION_AUTOMATIC;
   ctlautobtn.p_value       = (expand==TOOLBAR_LAYOUT_ORIENTATION_AUTOMATIC || expand==TOOLBAR_LAYOUT_ORIENTATION_HYBRID)? 1:0;
   ctlstandardbtn.p_value   = (expand==TOOLBAR_LAYOUT_ORIENTATION_STANDARD)?   1:0;
   ctlverticalbtn.p_value   = (expand==TOOLBAR_LAYOUT_ORIENTATION_VERTICAL)?   1:0;
   ctlhorizontalbtn.p_value = (expand==TOOLBAR_LAYOUT_ORIENTATION_HORIZONTAL)? 1:0;
   ctlautobtn.p_enabled       = (ctlautobtn.p_value==0);
   ctlstandardbtn.p_enabled   = (ctlstandardbtn.p_value==0);
   ctlverticalbtn.p_enabled   = (ctlverticalbtn.p_value==0);
   ctlhorizontalbtn.p_enabled = (ctlhorizontalbtn.p_value==0);

   // make this form respond to the same keys for push-tag and
   // find references that are set in the editor control
   createPreviewSymbolShortcuts();

   // disable the toolbar buttons until the symbol window is updated
   ctl_push_tag.p_enabled=false;
   ctl_find_refs.p_enabled=false;
   ctl_symbols.p_enabled=false;
}

// Set the filename and line number caption for the
// symbol window or references window, or whatever
// label is provided using 'label_id'.
// The the current object must be the tag window.
static void SetSymbolInfoCaption(int line_no, _str filename="")
{
   availableWidth := ctlautobtn.p_x-ctlbufname.p_x-_dx2lx(SM_TWIP,2);
   if (p_buf_id != EditWindowBufferID()) {
      filename=p_buf_name;
      ctlbufname.p_user = filename;
      if (filename == "") {
         filename = _build_buf_name();
      }
      if (line_no <= 0 && p_RLine > 1) line_no = p_RLine;
      lineCaption := (line_no > 0)? (": ":+line_no) : ("");
      caption := ctlbufname._ShrinkFilename(filename:+lineCaption,availableWidth);
      if (caption!=ctlbufname.p_caption) {
         ctlbufname.p_caption=caption;
         ctlbufname.p_width=ctlbufname._text_width(ctlbufname.p_caption);
      }
   } else if (filename != "") {
      ctlbufname.p_user = filename;
      ctlbufname.p_caption=ctlbufname._ShrinkFilename(filename:+" (contents not shown)",availableWidth);
      ctlbufname.p_width=ctlbufname._text_width(ctlbufname.p_caption);
   }
}

/**
 * Display the contents of the file associated with the given symbol 
 * in the Preview editor control (either the Preview tool window or the 
 * References tool window code preview). 
 * 
 * @param cm     symbol information, if empty, clear display
 */
void DisplayFile(VS_TAG_BROWSE_INFO cm)
{
   if (!_haveContextTagging()) {
      return;
   }
   if (p_active_form.p_name==TBPREVIEW_FORM) {
      if (TBPREVIEW_TIMER() >= 0) {
         _kill_timer(TBPREVIEW_TIMER());
         TBPREVIEW_TIMER(-1);
      }
   }
   orig_wid := p_window_id;

   // get the preview form information
   PREVIEW_FORM_INFO previewFormInfo;
   foreach (auto i => previewFormInfo in gPreviewFormList) {
      if (!_iswindow_valid(i)) continue;
      if (previewFormInfo.m_form_wid == p_active_form) break;
   }
   AlwaysUpdate := (previewFormInfo != null && previewFormInfo.m_forceUpdate);

   status := -1;
   // resolve unnamed buffer
   filename := cm.file_name;
   file_was_loaded := false;

   // DJB 01-27-2021
   // maybe this tag is coming from an untitled buffer
   // odds are the untitled buffer is the current editor control
   if (filename == "" && cm.line_no > 0 && cm.member_name != "") {
      editorctl_wid := _MDICurrentChild(_MDIFromChild(p_active_form));
      if (editorctl_wid && editorctl_wid._isEditorCtl() && editorctl_wid.p_buf_name == "") {
         filename = editorctl_wid._build_buf_name();
      }
   }
   if (_isno_name(filename)) {
      parse filename with filename "<" auto buf_id ">";
      if (isinteger(buf_id)) {
         status = load_files("+q +m +bi "buf_id);
         if (status >= 0) {
            file_was_loaded = true;
         }
      }
   }

   // attempt other filename
   if (filename == "") {
      status = 0;
      if (p_name != "ctlrefedit") {
         load_files("+bi "EditWindowBufferID());
         p_window_flags &= ~(CURLINE_COLOR_WFLAG|CURLINE_RECT_WFLAG);
      }
   } else if (!file_was_loaded && status) {
      filename=absolute(filename);
      // DJB 01-27-2021
      // only reload the file if the file name changed, 
      // otherwise, we can just move the cursor
      if (filename == p_buf_name && p_file_date == _file_date(filename, 'B')) {
         file_was_loaded = true;
      } else {
         // do not preview URLs, too slow
         protocol := "";
         if (_isUrl(filename, protocol) && protocol != "plugin") {
            if (p_name != "ctlrefedit") {
               load_files("+bi "EditWindowBufferID());
               p_window_flags &= ~(CURLINE_COLOR_WFLAG|CURLINE_RECT_WFLAG);
            }
            return;
         }

         // check that the file is not oversized
         file_size := _file_size(filename);
         if (cm.language=="") {
            cm.language=_Filename2LangId(cm.file_name);
         }
         have_doc_comments := (cm.doc_comments != "");
         if (!have_doc_comments && (cm.flags & SE_TAG_FLAG_NO_COMMENT)) {
            have_doc_comments = true;
         }
         if (have_doc_comments && (cm.language=="xmldoc" || cm.language=="tagdoc" || cm.language=="tld")) {
            status = 0;
            if (p_name != "ctlrefedit") {
               load_files("+bi "EditWindowBufferID());
               p_window_flags &= ~(CURLINE_COLOR_WFLAG|CURLINE_RECT_WFLAG);
            }
         } else if (file_size > def_update_context_max_ksize*1024) {
            status = 0;
            if (p_name != "ctlrefedit") {
               load_files("+bi "EditWindowBufferID());
               p_window_flags &= ~(CURLINE_COLOR_WFLAG|CURLINE_RECT_WFLAG);
            }
            comment_wid := _find_control("ctltagdocs");
            if (comment_wid) {
               ctltagdocs.p_text="<i>Source file exceeds size limit of "def_update_context_max_ksize" KB</i>";
            }
         } else if (have_doc_comments && (p_width < 30 || p_height < 30)) {
            status = 0;
            if (p_name != "ctlrefedit") {
               load_files("+bi "EditWindowBufferID());
               p_window_flags &= ~(CURLINE_COLOR_WFLAG|CURLINE_RECT_WFLAG);
            }
         } else if (_QBinaryLoadTagsSupported(filename)) {
            // do not load DLL files or JAR files
            status = 0;
            if (p_name != "ctlrefedit") {
               load_files("+bi "EditWindowBufferID());
               p_window_flags &= ~(CURLINE_COLOR_WFLAG|CURLINE_RECT_WFLAG);
            }
            comment_wid := _find_control("ctltagdocs");
            if (comment_wid) {
               ctltagdocs.p_text="<i>Binary file contents not displayed</i>";
            }
         } else {
            status=load_files("+q +m +b "filename);
            file_was_loaded = (status >= 0);
            if (status < 0) {
               comment_wid := _find_control("ctltagdocs");
               if (comment_wid) {
                  ctltagdocs.p_text="<i>":+get_message(status, filename):+"</i>";
               }
            }
         }
      }
   }

   lang := cm.language;
   if (status && !file_was_loaded && filename != "") {
      status=_BufEdit(filename,"",false,"",true);
      if (status<0) {
         // DJB 05-23-2006
         // do not do this if we are calling this from tagrefs.e
         if (p_name != "ctlrefedit") {
            load_files("+bi "EditWindowBufferID());
            p_window_flags &= ~(CURLINE_COLOR_WFLAG|CURLINE_RECT_WFLAG);
         }
         return;
      } else {
         p_buf_id=status;
         p_buf_flags|=(VSBUFFLAG_HIDDEN|VSBUFFLAG_DELETE_BUFFER_ON_CLOSE);
         if (lang != "") _SetEditorLanguage(lang);
         if (p_buf_size<def_use_old_line_numbers_ksize*1024) {
            _SetAllOldLineNumbers();
         }
         file_was_loaded = true;
      }
   }

   if ( file_was_loaded ) {
      //maybe_deselect(true);  // trouble with function-parameter auto-completion.

      orig_offset := _QROffset();
      if (cm.column_no > 0) {
         _GoToOldLineNumber(cm.line_no);
         p_col=cm.column_no;
      } else {
         if (isnumber(cm.line_no)) {
            p_RLine=cm.line_no;
         } else {
            top();
         }
         p_col=1;
         if (cm.seekpos > 0) {
            _GoToROffset(cm.seekpos);
            // DJB 04-17-2007
            // If the seek position has the wrong line number, ignore it
            if (isnumber(cm.line_no) && p_RLine != cm.line_no) {
               p_RLine = cm.line_no;
            }
         }
      }

      // DJB 01-27-2021
      // exit the scroll mode if the user was scrolling around
      // and then center on the designated line
      // only do this if the symbol being previewed actually changes.
      if (_QROffset() != orig_offset) {
         _ExitScroll();
         center_line();
      }

      // DJB 02-09-2021
      // update the line highlighting flags for this file
      // complying to language specific or global settings.
      if (def_preview_current_line & PREVIEW_CURRENT_LINE_BOX) {
         p_window_flags |= (CURLINE_RECT_WFLAG);
      } else {
         p_window_flags &= ~(CURLINE_RECT_WFLAG);
      }
      if (def_preview_current_line & PREVIEW_CURRENT_LINE_LANG) {
         if (se.lang.api.LanguageSettings.getColorFlags(p_LangId) & CLINE_COLOR_FLAG) {
            p_window_flags |= (CURLINE_COLOR_WFLAG);
         } else {
            p_window_flags &= ~(CURLINE_COLOR_WFLAG);
         }
      } else {
         if (def_preview_current_line & PREVIEW_CURRENT_LINE_HIGHLIGHT) {
            p_window_flags |= (CURLINE_COLOR_WFLAG);
         } else {
            p_window_flags &= ~(CURLINE_COLOR_WFLAG);
         }
      }
   }

   //Use all that information to get comments:
   f := p_active_form;
   comment_wid := f._find_control("ctltagdocs");

   comment_flags := (VSCodeHelpCommentFlags)0;
   comments := "";
   if (comment_wid > 0) {
      // if the comment wid is squished down to nothing, do not load comments
      if (comment_wid.p_height <= 30 || comment_wid.p_width <= 30) {
         comment_wid.p_text = "<i>Comments were hidden the last time the Preview tool window was refreshed.</i>";
         comment_wid = 0;
      } else if (!AlwaysUpdate && (_GetCodehelpFlags() & VSCODEHELPFLAG_PREVIEW_NO_COMMENTS)) {
         comment_wid.p_text = "<i>Comments are disabled in the Preview tool window for this language.</i>":+
                              "<p>":+
                              "See <b><a href=\"<<setupext -tagging\">":+p_mode_name:+" language options.</a> &gt; Context Tagging&reg;</b>";
      } else {
         if (lang == "docbook") {
            comments = "<i>" :+ create_docbook_comment_str(cm.member_name) :+ "</i>";
            comment_flags = VSCODEHELP_COMMENTFLAG_HTML;
         } else if (GetCommentInfoForSymbol(cm, comment_flags, comments)) {
            // we can use the comments attached to the symbol by tagging
            status = 0;
         } else if (file_was_loaded) {
            save_pos(auto p);
            status = _ExtractTagComments2(comment_flags, 
                                          comments, 2000, 
                                          cm.member_name, 
                                          filename, cm.line_no,
                                          cm.class_name,
                                          cm.type_name,
                                          cm.tag_database); 
            restore_pos(p);
         }
         if (comments=="") {
            comments="<i>no comment</i>";
         } else if (!status) {
            _make_html_comments(comments, comment_flags, "", "", true, lang);
         }
         comment_wid.p_text=comments;
      }

      if (comment_wid > 0 && file_was_loaded && (_GetCodehelpFlags() & VSCODEHELPFLAG_PREVIEW_RETURN_TYPE)) {
         tag_files := tags_filenamea(lang);
         VS_TAG_RETURN_TYPE visited:[] = null;
         add_return_info := _Embeddedget_inferred_return_type_string(auto errorArgs, tag_files, cm, visited);
         if (add_return_info == "") add_return_info = cm.return_type;
         if (add_return_info != "") {
            _escape_html_chars(add_return_info);
            comment_wid.p_text = "<b>Evaluated type:</b>&nbsp;&nbsp;" :+ add_return_info :+ "<hr>" :+ comments;
         }
      }
   }

   // force a refresh
   orig_wid.p_redraw=true;
}

static void tagwin_quit_file()
{
   gtagwin_in_quit_file=true;
   quit_file();
   gtagwin_in_quit_file=false;
}

edit1.on_destroy()
{
   if (EditWindowBufferID()!=p_buf_id) {
      if (p_buf_flags&VSBUFFLAG_HIDDEN) {
         if (_SafeToDeleteBuffer(p_buf_id,p_window_id,p_buf_flags)) {
            tagwin_quit_file();
         }
      }
      load_files("+q +m +bi "EditWindowBufferID());
   }
   if (TBPREVIEW_TIMER() >= 0) {
      _kill_timer(TBPREVIEW_TIMER());
      TBPREVIEW_TIMER(-1);
   }
   gPreviewFormList._deleteel(p_active_form);

}

/*static*/ void tagwin_goto_tag(_str filename, int line_no=0,
                                long seekpos=-1, int column_no=0,
                                bool doPushBookmark=true)
{
   if (filename=="") {
      message(nls("Can not locate source code"));
      return;
   }
   child_wid := _MDIGetActiveMDIChild();
   if (child_wid && doPushBookmark) {
      child_wid.push_bookmark();
   }
   lp := lastpos(":",filename);
   if (lp && !line_no) {
      line_no=(int)substr(filename,lp+1);
      filename=substr(filename,1,lp-1);
   }
   if (_QBinaryLoadTagsSupported(filename)) {
      message(nls("Can not locate source code for %s.",filename));
      return;
   }
   orig_buf_id := 0;
   orig_window_id := 0;
   if (child_wid && !doPushBookmark && child_wid.pop_destination()) {
      orig_window_id = child_wid;
      orig_buf_id = child_wid.p_buf_id;
   }
   if (child_wid && doPushBookmark) {
      child_wid.mark_already_open_destinations();
   }

   status := -1;
   if (_isno_name(filename)) {
      parse filename with filename "<" auto buf_id ">";
      if (isinteger(buf_id)) {
         status = edit("+bi "buf_id, EDIT_DEFAULT_FLAGS);
      }
   } 
   if (status) {
      status = edit(_maybe_quote_filename(filename),EDIT_DEFAULT_FLAGS);
   }
   if (!status) {
      // New document window has been created. Fetch it.
      child_wid=_MDIGetActiveMDIChild();

      child_wid.maybe_deselect(true);
      if (column_no > 0) {
         child_wid._GoToOldLineNumber(line_no);
         child_wid.center_line();
         child_wid.p_col=column_no;
      } else {
         child_wid.p_RLine=line_no;
         child_wid.center_line();
      }
      if (seekpos >= 0) {
         child_wid._GoToROffset(seekpos);
      }
      if (child_wid._lineflags()& HIDDEN_LF) {
         child_wid.expand_line_level();
      }
      orig_col := child_wid.p_col;
      child_wid.begin_line();
      child_wid.p_col = orig_col;
      child_wid.push_destination(orig_window_id, orig_buf_id);
   } else {
      message(nls("Could not open %s: %s",filename,get_message(status)));
   }
}

_str GetClassSep(_str filename)
{
   lang := _Filename2LangId(filename);
   switch (lang) {
   case "cs":
   case "java":
   case "ada":
   case "pas":
   case "e":
   case "py":
   case "d":
      return ".";
   case "pl":
   case "c":
   case "m":
   case "rs":
   default:
      break; // drop through
   }
   return("::");
}

static _str tagwin_get_buffer_name() 
{
   buf_name := edit1.p_buf_name;
   buf_id   := edit1.p_buf_id;
   if (buf_name == "" && buf_id != EditWindowBufferID()) {
      buf_name = edit1._build_buf_name();
   }
   return buf_name;
}

static void tagwin_mode_enter()
{
   buffer_name := tagwin_get_buffer_name();
   if (buffer_name != "") {

      // DJB 01-27-2021
      // save the last position we jumped from, this way we can prevent
      // the editor from updating the Preview while a user is scrolling
      // around and exploring in the Preview tool window.
      PREVIEW_FORM_INFO previewFormInfo;
      foreach (auto i => previewFormInfo in gPreviewFormList) {
         if (!_iswindow_valid(i)) continue;
         if (previewFormInfo.m_form_wid == p_active_form) {
            gPreviewFormList:[i].m_tagwin_last_jumppos = _QROffset();
         }
      }

      // DJB 01-27-2021
      // When we jump to a location, we jump to the exact location.
      tagwin_goto_tag(buffer_name, p_RLine, _QROffset(), p_col);
   }
}

static void tagwin_next_window()
{
   if (!_no_child_windows()) {
      child_wid := _MDIGetActiveMDIChild();
      if (child_wid) {
         p_window_id=child_wid;
         child_wid._set_focus();
      }
   }else{
      _cmdline._set_focus();
   }
}

static typeless TagWinCommands:[]={
   "split-insert-line"         =>tagwin_mode_enter,
   "c-enter"                   =>tagwin_mode_enter,
   "slick-enter"               =>tagwin_mode_enter,
   "cmd-enter"                 =>tagwin_mode_enter,
   "for-enter"                 =>tagwin_mode_enter,
   "pascal-enter"              =>tagwin_mode_enter,
   "prg-enter"                 =>tagwin_mode_enter,
   "select-line"               =>"",
   "brief-select-line"         =>"",
   "select-char"               =>"",
   "brief-select-char"         =>"",
   "cua-select"                =>"",
   "deselect"                  =>"",
   "copy-to-clipboard"         =>"",
   "next-window"               =>tagwin_next_window,
   "prev-window"               =>tagwin_next_window,
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
   "vi-next-line"              =>"",
   "vi-prev-line"              =>"",
   "vi-cursor-right"           =>"",
   "vi-cursor-left"            =>"",
   "cmdline-toggle"            =>tagwin_next_window
};

void edit1.\0-ON_SELECT()
{
   lastevent := last_event();
   eventname := event2name(lastevent);
   if (eventname=="ESC") {
      ToolWindowInfo* twinfo = tw_find_info(p_active_form.p_name);
      if (eventname=="ESC" && twinfo && (twinfo->flags & TWF_DISMISS_LIKE_DIALOG) ) {
         tw_dismiss(p_active_form);
      } else {
         tagwin_next_window();
      }
      return;
   }
   if (eventname=="F1") {
      _dmhelp(p_active_form.p_help);
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
      tagwin_mode_enter();
      return;
   }
   key_index  := event2index(lastevent);
   name_index := eventtab_index(_default_keys,edit1.p_mode_eventtab,key_index);
   command_name := name_name(name_index);
   if (command_name=="safe-exit") {
      safe_exit();
      return;
   }
   if (TagWinCommands._indexin(command_name)) {
      switch (TagWinCommands:[command_name]._varformat()) {
      case VF_FUNPTR:
         junk := (*TagWinCommands:[command_name])();
         break;
      case VF_LSTR:
         //junk=(*TagWinCommands:[command_name][0])(TagWinCommands:[command_name][1]);
         call_index(name_index);
         break;
      }
   }
   if (select_active()) deselect();
}

void edit1.wheel_down,wheel_up() {
   fast_scroll();
}
void edit1."c-wheel-down"() {
   scroll_page_down();
}
void edit1."c-wheel-up"() {
   scroll_page_up();
}

void edit1.rbutton_up()
{
   // Get handle to menu:
   index := find_index("_tagbookmark_menu",oi2type(OI_MENU));
   menu_handle := p_active_form._menu_load(index,'P');

   flags := def_tagwin_flags;
   pushTgConfigureMenu(menu_handle, flags);

   // Show menu:
   mou_get_xy(auto x,auto y);
   _KillToolButtonTimer();
   call_list("_on_popup2", translate("_tagbookmark_menu", "_", "-"), menu_handle);
   status := _menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

void ctltaglist.rbutton_up()
{
   edit1.call_event(edit1, RBUTTON_UP, 'w');
}

void _TagFileRefresh_symbols()
{
   if (gtagwin_in_quit_file) {
      return;
   }
   // DJB 01-27-2021
   // update all windows, not just the one for the current editor control
   _UpdateAllTagWindows(AlwaysUpdate:true);
}

void _cbmdibuffer_hidden_symbols()
{
   // Do nothing if there is no edit windows.
   if (_no_child_windows()) {
      return;
   }

   // Get the active edit window buffer ID.
   editorctl_wid := _mdi.p_child;
   editorBufID := editorctl_wid.p_buf_id;

   PREVIEW_FORM_INFO v;
   int i;
   foreach (i => v in gPreviewFormList) {
      // Access the tagwin buffer ID.
      if (!_iswindow_valid(i)) continue;
      form_wid := i;
      orig_wid := p_window_id;
      p_window_id=form_wid.edit1;

      // If the active edit window's buffer ID is the same as the
      // tagwin's buffer ID, go ahead and quit the tagwin's buffer.
      if (editorBufID == p_buf_id && p_buf_id != form_wid.EditWindowBufferID()) {
         if (p_buf_flags&VSBUFFLAG_HIDDEN) {
            if (_SafeToDeleteBuffer(p_buf_id,p_window_id,p_buf_flags)) {
               //say("_cbmdibuffer_hidden_symbols Calling tagwin_quit_file()");
               tagwin_quit_file();
            }
         }

         // Load the ".Tag Window Buffer"
         _ClearTagWindowForm(form_wid);
      }

      // restore the window ID
      p_window_id=orig_wid;
   }

}

/**
 * This function handles trying to keep an auto-hidden form 
 * raised for the duration that the form that activated it 
 * remains in focus. We keep track of the activation source flag 
 * when we activate the preview window, and then check here in 
 * the auto-hide callback if that form still has focus.  If so, 
 * we will delay hiding the tool window. 
 */
bool _autohide_wait__tbtagwin_form()
{
   wid := _get_focus();
   if ( !wid ) {
      return false;
   }
   wid = wid.p_active_form;
   formName := wid.p_name;

   switch ( gtagwin_activated_by ) {
   case APF_REFERENCES:
      if ( formName :== "_tbtagrefs_form" ) return true;
      break;
   case APF_SYMBOLS:
      if ( formName :== "_tbcbrowser_form" ) return true;
      break;
   case APF_FIND_SYMBOL:
      if ( formName :== "_tbfind_symbol_form" ) return true;
      break;
   case APF_CLASS:
      if ( formName :== "_tbclass_form" ) return true;
      break;
   case APF_DEFS:
      if ( formName :== "_tbproctree_form" ) return true;
      break;
   case APF_BOOKMARKS:
      if ( formName :== "_tbbookmarks_form" ) return true;
      break;
   case APF_SEARCH_RESULTS:
      if ( formName :== "_tbsearch_form" ) return true;
      break;
   case APF_FILES:
      if ( formName :== "_tbfilelist_form" ) return true;
      break;
   case APF_ANNOTATIONS:
      if ( formName :== "_tbannotations_browser_form" ) return true;
      break;
   case APF_BREAKPOINTS:
      if ( formName :== "_tbbreakpoints_form") return true;
      break;
   case APF_MESSAGE_LIST:
      if (formName :== "_tbmessages_browser_form" ) return true;
      break;
   case APF_UNIT_TEST:
      if ( formName :== "_tbunittest_form" ) return true;
      break;
   case APF_SELECT_SYMBOL:
      if ( formName :== "_select_tree_form" ) return true;
      break;
   default:
      // Modal Select Symbol dialog
      if ( formName :== "_select_tree_form" && wid.p_caption == "Select Symbol" ) return true;
      break;
   }

   gtagwin_activated_by = APF_ALL_FLAGS;
   return false;
}
