////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50641 $
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
#include "toolbar.sh"
#include "color.sh"
#include "eclipse.sh"
#include "minihtml.sh"
#import "annotations.e"
#import "c.e"
#import "cutil.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "context.e"
#import "cua.e"
#import "dlgman.e"
#import "docbook.e"
#import "eclipse.e"
#import "files.e"
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
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagfind.e"
#import "tagform.e"
#import "tagrefs.e"
#import "tags.e"
#import "tbclass.e"
#import "tbcmds.e"
#import "tbsearch.e"
#import "toolbar.e"
#import "util.e"
#import "window.e"
#import "se/tags/TaggingGuard.e"
#endregion

const TAGWIN_EXCLUSIONS = "PreviewWindowExclusions";
#define TAG_NAME_BUFFER_LIST '.Tag Name Buffer List'
#define TAG_FORM_NAME_STRING  "_tbtagwin_form"
#define EditWindowBufferID edit1.p_user
#define PREFIXMATCHEDMAXLISTCOUNT 200

static int     gPreviewTagTimerId = -1;
static int     gtagwin_last_seekpos = -1;
static boolean gtagwin_in_quit_file = false;

static VS_TAG_BROWSE_INFO gtagwin_saved_info = null;
static boolean gtagwin_use_editor = false;
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


// keeps track of what other windows activate the preview automatically
int def_activate_preview = 0;

// used with def_activate_preview to keep track of which windows activate 
// the preview window automatically
enum_flags ActivatePreviewFlags {
   APF_ON,
   APF_REFERENCES,
   APF_SYMBOLS,
   APF_FIND_SYMBOL,
   APF_CLASS,
   APF_DEFS,
   APF_BOOKMARKS,
   APF_SEARCH_RESULTS,
   APF_FILES,
   APF_ANNOTATIONS,
   APF_BREAKPOINTS,
   APF_MESSAGE_LIST,
   APF_UNIT_TEST
};

// keeps track of what window last activated the preview window
static ActivatePreviewFlags gtagwin_activated_by = -1;


/**
 * Maximum time to spend on looking up tag matches for preview window. 
 *  
 * @default 1000 ms (1 second) 
 * @category Configuration_Variables
 */
int def_preview_window_timeout = 1000;


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
boolean doActivatePreviewToolWindow(int activateFlag)
{
   if (!(def_activate_preview & APF_ON)) return false;

   if (!(def_activate_preview & activateFlag)) return false;

   gtagwin_activated_by = activateFlag;
   return true;
}

defeventtab _tbtagwin_form;

_tbtagwin_form.'F12'()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   } else if (def_keys == 'eclipse-keys') {
      activate_editor();
   }
}

_tbtagwin_form.'C-M'()
{
   if (isEclipsePlugin()) {
      eclipse_maximize_part();
   }
}

int _eclipse_getSymbolWindowQFormWID()
{
   int formWid = _find_object(ECLIPSE_SYMBOLOUTPUT_CONTAINERFORM_NAME,'n');
   if (formWid > 0) {
      return formWid.p_child;
   }
   return 0;
}

static VS_TAG_BROWSE_INFO getSelectedSymbol()
{
   int index = ctltaglist._TreeCurIndex();
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
   edit1.tagwin_goto_tag(edit1.p_buf_name, edit1.p_line);
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
   if (reason == CHANGE_SELECTED) {
      VS_TAG_BROWSE_INFO cm;
      if (index > 0) {
         cm = _TreeGetUserInfo(index);
         if (cm != null && cm.file_name!=null) {

            // special case for COBOL copy books, ASM390 macros
            if (cm.type_name=='include' && cm.return_type!='' && file_exists(cm.return_type)) {
               cm.file_name=cm.return_type;
               cm.line_no=1;
               cm.column_no=1;
               cm.seekpos=0;
            }

            // make sure that this did not come from a jar file or DLL
            if (_QBinaryLoadTagsSupported(cm.file_name)) {
               ctlbufname.p_caption=cm.file_name;
               ctltagdocs.p_text="<i>no documentation available</i>";
               edit1.load_files('+q +m +bi 'EditWindowBufferID);
               edit1.refresh('w');
            } else {
               edit1.DisplayFile(cm.file_name, cm.line_no, cm.seekpos, 
                                 cm.column_no, cm.member_name, cm.language);
               edit1.SetSymbolInfoCaption(cm.line_no);
            }

            // update the tag properties form
            if (TagWinFocus() || (!_no_child_windows() && _get_focus()==_mdi.p_child)) {
               cb_refresh_property_view(cm);
            }
         }
      }
   } else if (reason == CHANGE_LEAF_ENTER) {
      edit1.tagwin_goto_tag(edit1.p_buf_name, edit1.p_line);
   }
}

static void savePreviewWindow(PREVIEW_WINDOW_STACK_ITEM &item)
{
   item.stack_top=0;
   item.tree_line = ctltaglist._TreeCurLineNumber();
   item.symbols._makeempty();
   int tree_index = ctltaglist._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (tree_index > 0) {
      item.symbols[item.symbols._length()] = ctltaglist._TreeGetUserInfo(tree_index);
      tree_index = ctltaglist._TreeGetNextSiblingIndex(tree_index);
   }
   item.helpText = ctltagdocs.p_text;
   item.fileText = ctlbufname.p_caption;
   ctltagdocs._minihtml_GetScrollInfo(item.htmlCtlScrollInfo);
}
static void restorePreviewWindow(PREVIEW_WINDOW_STACK_ITEM &item)
{
   if (gPreviewTagTimerId >= 0) {
      _kill_timer(gPreviewTagTimerId);
      gPreviewTagTimerId = -1;
   }
   ctltaglist._TreeBeginUpdate(TREE_ROOT_INDEX);
   int i, n = item.symbols._length();
   for (i=0; i<n; ++i) {
      tag_tree_insert_info(ctltaglist, TREE_ROOT_INDEX, item.symbols[i], false, 1, TREE_ADD_AS_CHILD, item.symbols[i]);
   }
   ctltaglist._TreeEndUpdate(TREE_ROOT_INDEX);
   ctltaglist._TreeCurLineNumber(item.tree_line);
   if (item.helpText != null) ctltagdocs.p_text = item.helpText;
   if (item.fileText != null) ctlbufname.p_caption = item.fileText;
   if (item.htmlCtlScrollInfo != null) {
      ctltagdocs._minihtml_SetScrollInfo(item.htmlCtlScrollInfo);
   }
}

void ctltagdocs.on_change(int reason,_str hrefText)
{
   if (gPreviewTagTimerId >= 0) {
      _kill_timer(gPreviewTagTimerId);
      gPreviewTagTimerId = -1;
   }

   // get the hypertext stack
   int stack_top = -1;
   PREVIEW_WINDOW_STACK_ITEM preview_stack[];
   preview_stack._makeempty();
   if (p_user._varformat()==VF_ARRAY) {
      preview_stack = p_user;
      if (preview_stack._length() > 0) {
         stack_top = preview_stack[0].stack_top;
      }
   }

   if (reason==CHANGE_CLICKED_ON_HTML_LINK) {
      if (hrefText=='<<back') {
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

      } else if(hrefText=='<<forward') {
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

      } else if (hrefText=='<<pushtag') {
         edit1.call_event(edit1, LBUTTON_DOUBLE_CLICK, 'w');
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
      int status=0;
      _str filename=edit1.p_buf_name;
      int linenum=edit1.p_RLine;
      if (edit1.p_LangId=='xmldoc' && !_no_child_windows()) {
         status = _mdi.p_child.tag_match_href_text(hrefText, filename, linenum);
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

      tag_remove_duplicate_symbol_matches(false, false, true, true);

      ctltaglist._TreeBeginUpdate(TREE_ROOT_INDEX);
      int preferred_index = 0;
      int i, n = tag_get_num_of_matches();
      for (i=1; i<=n; ++i) {
         // add this item to the tree
         VS_TAG_BROWSE_INFO cm;
         tag_get_match_info(i, cm);
         int k = tag_tree_insert_fast(ctltaglist,TREE_ROOT_INDEX,
                              VS_TAGMATCH_match,i,
                              0,1,TREE_ADD_AS_CHILD,1,1,cm);

         // check this item's file extension information
         if (cm.language=='') {
            cm.language=_Filename2LangId(cm.file_name);
         }
         // prefer to see source we can pilfer comments from
         if (cm.language!='') {
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
   _append_retrieve(0,ctl_size_x.p_x,"_tbtagwin_form.ctl_size_x.p_x");
   _append_retrieve(0,ctl_size_y.p_y,"_tbtagwin_form.ctl_size_y.p_y");

   // unbind keys copied in for push_tag and push_ref shortcuts
   unbindPreviewSymbolShortcuts();

   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id,ON_DESTROY,'2');
}

void _tbtagwin_form.on_change(int reason)
{
   if( reason==CHANGE_AUTO_SHOW ) {
      gtagwin_last_seekpos= -1;
      _UpdateTagWindow(true);
   }
}
void _tbtagwin_form.on_got_focus()
{
   int old_wid;
   if (isEclipsePlugin()) {
      int symbolContainer = _eclipse_getSymbolWindowQFormWID();
      if(!symbolContainer) return;
      old_wid = p_window_id;
      // RGH - 4/27/2007
      // Need to set p_window_id so we can find the right controls
      p_window_id = symbolContainer;
   }
   
   if (_get_focus()==ctltagdocs) {
      return;
   }
// if (_get_focus()==ctltaglist && ctltaglist._TreeGetNumChildren(TREE_ROOT_INDEX,'') >= 1) {
//    return;
// }
   gtagwin_last_seekpos= -1;
   _UpdateTagWindow(true);
   if (isEclipsePlugin()) {
      p_window_id = old_wid;
   }
   //DisplayTagList();
}

int def_toolbar_pic_hspace;
int def_toolbar_pic_vspace;

static void resizeTagWin()
{
   int old_wid, clientW, clientH;
   // RGH - 4/26/2006
   // For the plugin, first resize the SWT container and then continue with the normal resize
   if (isEclipsePlugin()) {
      int symbolContainer = _eclipse_getSymbolWindowQFormWID();
      if(!symbolContainer) return;
      old_wid = p_window_id;
      // RGH - 4/26/2006
      // Need to set p_window_id so we can find the right controls
      p_window_id = symbolContainer;
      eclipse_resizeContainer(symbolContainer);
      clientW = symbolContainer.p_parent.p_width;
      clientH = symbolContainer.p_parent.p_height;
   } else { 
      clientW = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
      clientH = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   }

   // adjust y positions of buttons
   int hspace = _dx2lx(SM_TWIP, def_toolbar_pic_hspace);
   int vspace = _dx2lx(SM_TWIP, def_toolbar_pic_vspace);
   ctl_back.p_y      = ctltagdocs.p_y;
   ctl_forward.p_y   = vspace+ctl_back.p_y+ctl_back.p_height;
   ctl_push_tag.p_y  = vspace+ctl_forward.p_y+ctl_forward.p_height;
   ctl_find_refs.p_y = vspace+ctl_push_tag.p_y+ctl_push_tag.p_height;
   ctl_symbols.p_y   = vspace+ctl_find_refs.p_y+ctl_find_refs.p_height;
   ctl_tag_files.p_y = vspace+ctl_symbols.p_y+ctl_symbols.p_height;

   // adjust the x positions of buttons
   clientW = clientW - hspace - ctl_back.p_width;
   ctl_back.p_x      = clientW;
   ctl_forward.p_x   = clientW;
   ctl_push_tag.p_x  = clientW;
   ctl_find_refs.p_x = clientW;
   ctl_symbols.p_x   = clientW;
   ctl_tag_files.p_x = clientW;

   // verify that dividers set to reasonable values
   if (ctl_size_x.p_x < ctltaglist.p_x) {
      ctl_size_x.p_x = ctltaglist.p_x;
   }
   if (ctl_size_x.p_x > clientW-ctl_size_x.p_width-ctltaglist.p_x) {
      ctl_size_x.p_x = clientW-ctl_size_x.p_width-ctltaglist.p_x;
   }
   if (ctl_size_y.p_y < ctltagdocs.p_y) {
      ctl_size_y.p_y = ctltagdocs.p_y;
   }
   if (ctl_size_y.p_y > clientH-ctl_size_y.p_height-ctltaglist.p_y) {
      ctl_size_y.p_y = clientH-ctl_size_y.p_height-ctltaglist.p_y;
   }

   // adjust y positions based on position of sizebar
   edit1.p_y = ctl_size_y.p_y+ctl_size_y.p_height;
   ctltaglist.p_height = ctl_size_y.p_y-ctltaglist.p_y;
   ctltagdocs.p_height = ctl_size_y.p_y-ctltagdocs.p_y;
   ctl_size_x.p_height = ctl_size_y.p_y-ctl_size_x.p_y;

   // adjust x positions based on position of sizebar
   ctltaglist.p_width = ctl_size_x.p_x-ctltaglist.p_x;
   ctltagdocs.p_x     = ctl_size_x.p_x+ctl_size_x.p_width-_dx2lx(SM_TWIP,1);
   ctlbufname.p_x     = ctl_size_x.p_x+ctl_size_x.p_width*2;

   // adjust width and heights of controls based on form size
   edit1.p_width = clientW - 2 * edit1.p_x;
   edit1.p_height = clientH - edit1.p_y;
   ctl_size_y.p_x     = edit1.p_x;
   ctl_size_y.p_width = edit1.p_width;
   ctl_size_x.p_y     = ctltaglist.p_y;
   ctl_size_x.p_height= ctltaglist.p_height;
   ctltagdocs.p_width = clientW - ctltagdocs.p_x - edit1.p_x; 
   ctlbufname.p_caption=ctlbufname._ShrinkFilename(ctlbufname.p_user,clientW-ctlbufname.p_x);

   // RGH - 4/26/2006
   // Switch p_window_id back
   if (isEclipsePlugin()) {
      p_window_id = old_wid;
   }
}

_tbtagwin_form.on_resize()
{
   resizeTagWin();
}

ctl_size_x.lbutton_down()
{
   _ul2_image_sizebar_handler(ctltaglist.p_x*2, ctltagdocs.p_x+ctltagdocs.p_width);
}
ctl_size_y.lbutton_down()
{
   _ul2_image_sizebar_handler(ctltaglist.p_y*2, edit1.p_y+edit1.p_height);
}

static boolean _in_keyword(...)
{
   if (p_lexer_name=='') {
      return(0);
   }
   int color;
   int in_ml_comment=arg(1);
   if (in_ml_comment==1) {
      color=_in_comment_common();
   } else {
      color=_clex_find(0,'g');
   }
   return(color==CFG_KEYWORD);
}

//We did this because it doesn't take any of the options that cur_word did
static _str mycur_word(VS_TAG_IDEXP_INFO &idexp_info)
{
   // find and call routine to get prefix expression
   _str lang=p_LangId;
   tag_idexp_info_init(idexp_info);

   // Try finding get_expression_info for this extension.
   status := 0;
   get_index := _FindLanguageCallbackIndex('vs%s_get_expression_info',lang);
   if (get_index && index_callable(get_index)) {
      _UpdateContext(true, false, VS_UPDATEFLAG_context|VS_UPDATEFLAG_tokens);
      status = call_index(false, _QROffset(), idexp_info, get_index);
      if (status == 0 && idexp_info.lastid != "") return idexp_info.lastid;
   }

   // Try finding get_expression_info for this extension.
   get_index = _FindLanguageCallbackIndex('_%s_get_expression_info',lang);
   if(get_index != 0) {
      struct VS_TAG_RETURN_TYPE visited:[];
      if (get_index && !call_index(false, idexp_info, visited, get_index) && idexp_info.lastid!='') {
         return idexp_info.lastid;
      }
   } else {
      // Revert to old get_idex
      get_index = _FindLanguageCallbackIndex('_%s_get_idexp',lang);
      int info_flags=0;
      typeless junk;
      _str prefixexp,lastid,otherinfo;
      int lastidstart_col,lastidstart_offset;
      if (get_index && 
          !call_index(junk,false, prefixexp, lastid,
                      lastidstart_col, lastidstart_offset,
                      info_flags, otherinfo, get_index) && 
          lastid != '') {
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
   int col=_text_colc(p_col,'p');
   save_pos(auto p);
   word_chars := _clex_identifier_chars();
   _str common_re='([~\od'word_chars']|^)\c[\od'word_chars']';
   common_re='('common_re')|^';
   status = search(common_re,'rh-@');
   if ( status || !match_length()) {
      restore_pos(p);
      restore_search(sv_search_string,sv_flags,sv_word_re,sv_more);
      return('');
   }

   int start_col=p_col;
   idexp_info.lastidstart_col=start_col;
   idexp_info.lastidstart_offset=(int)_QROffset();
   
   //status=search('[~\od'p_word_chars']|$','r@');
   status=_TruncSearchLine('[~\od'word_chars']|$','r');
   if ( status) {
      _end_line();
   }
   _str word=_expand_tabsc(start_col,p_col-start_col);
   restore_pos(p);
   //start_col=_text_colc(start_col,'P');
   restore_search(sv_search_string,sv_flags,sv_word_re,sv_more);

   // fill in other ID expression information
   idexp_info.prefixexp='';
   idexp_info.lastid=word;
   idexp_info.info_flags=0;
   idexp_info.otherinfo='';
   return(word);
}

// Need to be able to call this from proctree.e
int _GetTagwinWID(boolean only_when_active=false)
{
#if 1
   int wid = _find_formobj(TAG_FORM_NAME_STRING,'n');
#else
   int index = find_index('_symbolwindow_QFormWID',PROC_TYPE);
   if( index_callable(index) ) {
      return (call_index(only_when_active,index));
   }

   int wid = 0;
   static int LastFormWID;
   if( _iswindow_valid(LastFormWID) &&
       LastFormWID.p_object==OI_FORM &&
       LastFormWID.p_name==TAG_FORM_NAME_STRING &&
       !LastFormWID.p_edit){

      wid=LastFormWID;
   } else {
      wid=_find_formobj(TAG_FORM_NAME_STRING,'N');
      LastFormWID=wid;
   }
#endif
   // check if the tagwin is active
   if( wid>0 && only_when_active ) {
      if( !_tbIsWidActive(wid) ) {
         return 0;
      }
   }
   return wid;
}
static boolean TagWinFocus()
{
   int FocusWID = _get_focus();
   int FormWID = _GetTagwinWID();
   if (FormWID == 0) return false;
   if ( FocusWID==FormWID || 
        FocusWID==FormWID.edit1 || 
        FocusWID==FormWID.ctltagdocs ||
        FocusWID==FormWID.ctltaglist) {
      return true;
   }
   return false;
}

_command void toggle_activate_preview() name_info(',')
{
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
_command void preview_tag(VS_TAG_BROWSE_INFO cm=null) name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   if (gPreviewTagTimerId >= 0) {
      _kill_timer(gPreviewTagTimerId);
      gPreviewTagTimerId = -1;
   }
   orig_autohide_delay := def_toolbar_autohide_delay;
   def_toolbar_autohide_delay=5000;
   activate_toolbar("_tbtagwin_form","ctltaglist",false);
   def_toolbar_autohide_delay=orig_autohide_delay;
   if (cm==null) {
      _UpdateTagWindow(true);
   } else {
      cb_refresh_output_tab(cm,true,true);
   }
}

/**
 * Move to the next symbol in the preview window.
 */
_command void preview_prev_symbol() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   if (gPreviewTagTimerId >= 0) {
      _kill_timer(gPreviewTagTimerId);
      gPreviewTagTimerId = -1;
   }
   int form_wid = _find_formobj("_tbtagwin_form", 'n');
   if (!form_wid) return;

   int tree_wid = form_wid._find_control("ctltaglist");
   if (!tree_wid) return;

   if (tree_wid._TreeUp()) {
      tree_wid._TreeBottom();
   }
}

/**
 * Move to the next symbol in the preview window.
 */
_command void preview_next_symbol() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   if (gPreviewTagTimerId >= 0) {
      _kill_timer(gPreviewTagTimerId);
      gPreviewTagTimerId = -1;
   }
   int form_wid = _find_formobj("_tbtagwin_form", 'n');
   if (!form_wid) return;

   int tree_wid = form_wid._find_control("ctltaglist");
   if (!tree_wid) return;

   if (tree_wid._TreeDown()) {
      tree_wid._TreeTop();
   }
}

/**
 * Move the editor control one line down in the preview window.
 */
_command void preview_cursor_down() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   int wid = _GetTagwinWID(true);
   if (wid) {
      wid.edit1.cursor_down();
   } else if (p_object == OI_TREE_VIEW) {
      call_event(defeventtab _ul2_tree, C_DOWN, "e");  
   }
}
/**
 * Move the editor control one line up in the preview window.
 */
_command void preview_cursor_up() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   int wid = _GetTagwinWID(true);
   if (wid) {
      wid.edit1.cursor_up();
   } else if (p_object == OI_TREE_VIEW) {
      call_event(defeventtab _ul2_tree, C_UP, "e");  
   }
}
/**
 * Page the editor control one page down in the preview window.
 */
_command void preview_page_down() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   int wid = _GetTagwinWID(true);
   if (wid) {
      wid.edit1.page_down();
   } else if (p_object == OI_TREE_VIEW) {
      call_event(defeventtab _ul2_tree, C_PGDN, "e");  
   }
}
/**
 * Page the editor control one page up in the preview window.
 */
_command void preview_page_up() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   int wid = _GetTagwinWID(true);
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
static void tagwin_match_tag(_str &search_tag_name)
{
   // update the current context and locals
   _UpdateContext(true);
   _UpdateLocals(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // drop into embedded language mode if necessary
   struct VS_TAG_RETURN_TYPE visited:[]; visited._makeempty();
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   case_sensitive := p_EmbeddedCaseSensitive;

   // use intelligent Context Tagging(R) function
   _str errorArgs[]; errorArgs._makeempty();
   num_matches := context_match_tags(errorArgs,search_tag_name,
                                     false,PREFIXMATCHEDMAXLISTCOUNT,
                                     true, case_sensitive);

   // no search tag name, try cur_word()
   if (num_matches<=0 && search_tag_name=='') {
      VS_TAG_IDEXP_INFO idexp_info;
      search_tag_name = mycur_word(idexp_info);
   }

   // no matches, try dumber symbol lookup
   typeless tag_files = tags_filenamea(p_LangId);
   if (num_matches <= 0 && !_CheckTimeout()) {
      tag_clear_matches();
      tag_list_symbols_in_context(search_tag_name, '', 
                                  0, 0, tag_files, '',
                                  num_matches, PREFIXMATCHEDMAXLISTCOUNT,
                                  def_tagwin_flags, 
                                  VS_TAGCONTEXT_ALLOW_locals,
                                  true, case_sensitive, visited, 0);
   }

   // no matches, try even more desparately stupid search 
   if (num_matches <= 0 && !_CheckTimeout()) {
      tag_list_any_symbols(0,0,search_tag_name,tag_files,
                           def_tagwin_flags,VS_TAGCONTEXT_ANYTHING,
                           num_matches,PREFIXMATCHEDMAXLISTCOUNT,
                           true, case_sensitive);
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
   gtagwin_saved_info = cm;
   gtagwin_use_editor = (gtagwin_saved_info == null);
}

static void _UpdateTagWindowNow(struct VS_TAG_BROWSE_INFO cm=null)
{
   if (gPreviewTagTimerId >= 0) {
      _kill_timer(gPreviewTagTimerId);
      gPreviewTagTimerId = -1;
   } else if (cm != null) {
      // we shouldn't be here
      return;
   }
   static PREVIEW_WINDOW_STACK_ITEM lastItem;
   wid := _GetTagwinWID(true);
   if (!wid) return;
   if (cm != null) {
      if (lastItem == null) {
         wid.savePreviewWindow(lastItem);
      }
      _UpdateTagWindow(true, cm);
   } else {
      if (lastItem != null && lastItem.fileText != null) {
         wid.restorePreviewWindow(lastItem);
         lastItem = null;
      } else if (!_no_child_windows()) {
         _mdi.p_child.p_ModifyFlags &= ~MODIFYFLAG_TAGWIN_UPDATED;
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
   if (gPreviewTagTimerId >= 0) {
      _kill_timer(gPreviewTagTimerId);
      gPreviewTagTimerId = -1;
   }
   if (ms > 0) {
      int wid=_GetTagwinWID(true);
      if (!wid) return;
      gPreviewTagTimerId = _set_timer(ms, _UpdateTagWindowNow, cm);
   } else {
      _UpdateTagWindowNow(cm);
   }
}

/**
 * Update the preview window.
 * 
 * @param AlwaysUpdate  force update
 * @param cm            [optional] specific symbol information to display
 * @param cmlist        [optional] list of symbols to display 
 */
void _UpdateTagWindow(boolean AlwaysUpdate=false, 
                      struct VS_TAG_BROWSE_INFO &cm=null, 
                      struct VS_TAG_BROWSE_INFO (&cmlist)[]=null)
{
   // idle timer elapsed?
   if (!AlwaysUpdate && gtagwin_use_editor && _idle_time_elapsed() <= def_update_tagging_idle) {
      return;
   }

   if (gPreviewTagTimerId >= 0) {
      _kill_timer(gPreviewTagTimerId);
      gPreviewTagTimerId = -1;
   }

   int wid=_GetTagwinWID(!AlwaysUpdate);
   if (!wid) {
      return;
   }

   // this is the editor, so we need to null out whatever we previously saved
   int focus_wid = _get_focus();
   if (!AlwaysUpdate && focus_wid && focus_wid._isEditorCtl() && !_isGrepBuffer(focus_wid.p_buf_name)) {
      gtagwin_use_editor = true;
      gtagwin_saved_info = null;
   }

   if (!AlwaysUpdate && TagWinFocus()) {
      return;
   }

   // if we have no parameter context info, use the saved stuff
   if (cm == null && cmlist == null && !gtagwin_use_editor && gtagwin_saved_info != null) {
      cm = gtagwin_saved_info;
      gtagwin_saved_info = null;
   }

   int editorctl_wid = 0;
   if (cm == null && cmlist==null) {
      // Check if the current form having focus was one of the
      // forms that explicitely updated the tag window.
      // If so, then drop out of here and do not update the
      // preview window based on what is in _mdi.p_child.
      if ( focus_wid && (!gtagwin_use_editor || !AlwaysUpdate) ) {
         _str focus_form = focus_wid.p_active_form.p_name;
         typeless * phash = wid._GetDialogInfoHtPtr(TAGWIN_EXCLUSIONS);
         if (phash != null && phash->_indexin(focus_form)) {
            return;
         }
      }
      editorctl_wid = focus_wid;
      if (!editorctl_wid || !editorctl_wid._isEditorCtl()) {
         if (p_window_id._isEditorCtl()) {
            editorctl_wid = p_window_id;
         } else {
            if (_no_child_windows()) {
               return;
            }
            editorctl_wid = _mdi.p_child;
         }
      } 
      wid.edit1.SetSymbolInfoCaption(0);
      int curr_seekpos = (int)editorctl_wid._QROffset();
      if (!AlwaysUpdate && curr_seekpos == gtagwin_last_seekpos &&
          (editorctl_wid.p_ModifyFlags&MODIFYFLAG_TAGWIN_UPDATED)) {
         return;
      }

      if (!editorctl_wid._istagging_supported()) {
         return;
      }

      gtagwin_last_seekpos = curr_seekpos;
      editorctl_wid.p_ModifyFlags |= MODIFYFLAG_TAGWIN_UPDATED;

   } else {
      // The form having focus when this is called should
      // be put on the list of forms who, if they have focus
      // we should not update the Preview window on the
      // autosave timer.
      if ( focus_wid ) {
         _str focus_form = focus_wid.p_active_form.p_name;
         if (focus_form != '') {
            typeless * phash = wid._GetDialogInfoHtPtr(TAGWIN_EXCLUSIONS);
            if (phash == null) {
               boolean hash:[];
               hash:[focus_form] = true;
               wid._SetDialogInfoHt(TAGWIN_EXCLUSIONS, hash);
            } else if (!phash->_indexin(focus_form)) {
               (*phash):[focus_form] = true;
            }
         }
      }
   }

   // idle timer elapsed?
   if (!AlwaysUpdate && 
       editorctl_wid && _iswindow_valid(editorctl_wid) && 
       !(editorctl_wid.p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED) && 
       _idle_time_elapsed() <= def_update_tagging_idle+def_update_tagging_extra_idle) {
      return;
   }

   int preferred_match_id = 1;
   tag_push_matches();

   typeless errorArgs;
   _str tagname="";
   if (cm != null) {
      tag_insert_match_info(cm);
   } else if (cmlist != null) {
      for (j:=0; j<cmlist._length(); ++j) {
         if (cmlist[j]==null) continue;
         tag_insert_match_info(cmlist[j]);
      }
   } else {

      // check if the tag database is busy and we can't get a lock.
      dbName := _GetWorkspaceTagsFilename();
      haveDBLock := tag_trylock_db(dbName);
      if (!AlwaysUpdate && !haveDBLock) {
         tag_pop_matches();
         return;
      }

      // search for matches to the symbol under the cursor
      _SetTimeout(def_preview_window_timeout);
      editorctl_wid.tagwin_match_tag(tagname);
      _SetTimeout(0);

      // remove duplicate tags
      tag_remove_duplicate_symbol_matches(false, false, true, true);

      // filter tags based on filtering criteria
      tag_filter_symbol_matches(def_tagwin_flags);

      // find the preferred match (definition or declaration) to auto-select
      int codehelp_flags = editorctl_wid._GetCodehelpFlags();
      preferred_match_id = editorctl_wid.tag_check_for_preferred_symbol(codehelp_flags);
      if (preferred_match_id <= 0) preferred_match_id=1;

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

   int curr_index=0;
   int i, n = tag_get_num_of_matches();
   wid.ctltaglist._TreeBeginUpdate(TREE_ROOT_INDEX);
   for (i=1; i<=n; ++i) {
      tag_get_match_info(i,cm);
      int k = tag_tree_insert_fast(wid.ctltaglist.p_window_id, TREE_ROOT_INDEX, 
                                   VS_TAGMATCH_match, i, 0, 1, 
                                   TREE_ADD_AS_CHILD, 1, 1, cm);
      if (i==preferred_match_id) curr_index=k;
   }
   wid.ctltaglist._TreeEndUpdate(TREE_ROOT_INDEX);
   /*
     Need this first set cur index to force the on_change in the
     second. The first set cur index will sometimes cause an
     on_change (seems to generate index=-1 reason=CHANGE_SCROLL).
   */
   if (curr_index > 0) {
      wid.ctltaglist._TreeSetCurIndex(TREE_ROOT_INDEX);
      wid.ctltaglist._TreeSetCurIndex(curr_index);
   }
   wid.ctltaglist._TreeRefresh();

   if (n==0) {
      wid.ctltagdocs.p_text="<i>no matching symbols</i>";
      wid.ctlbufname.p_caption='';
      wid.edit1.load_files('+q +m +bi 'wid.EditWindowBufferID);
      wid.edit1.p_redraw=true;
   }

   wid.ctl_back.p_enabled=false;
   wid.ctl_forward.p_enabled=false;
   wid.ctltagdocs.p_user = null;

   wid.ctl_push_tag.p_enabled  = (n > 0);
   wid.ctl_find_refs.p_enabled = (n > 0);
   wid.ctl_symbols.p_enabled   = (n > 0);

   tag_pop_matches();

}

void _ClearTagWindowForBuffer(int buf_id)
{
   int wid=_GetTagwinWID();
   if (!wid) {
      return;
   }

   // this is the editor, so we need to null out whatever we previously saved
   int editorctl_wid = p_window_id;
   if (!_isEditorCtl()) {
      return;
   }

   if (wid.edit1.p_buf_id == buf_id) {
      _nocheck _control ctltaglist;
      _nocheck _control ctl_back;
      _nocheck _control ctl_forward;
      _nocheck _control ctl_push_tag;
      _nocheck _control ctl_find_refs;
      _nocheck _control ctl_symbols;
      _nocheck _control ctltagdocs;

      wid.ctltaglist._TreeDelete(TREE_ROOT_INDEX,"C");
      wid.ctltagdocs.p_text="<i>no matching symbols</i>";
      wid.ctlbufname.p_caption='';
      wid.edit1.load_files('+q +m +bi 'wid.EditWindowBufferID);
      wid.edit1.p_redraw=true;
      gtagwin_last_seekpos = -1;

      wid.ctl_back.p_enabled=false;
      wid.ctl_forward.p_enabled=false;
      wid.ctltagdocs.p_user = null;

      wid.ctl_push_tag.p_enabled  = false;
      wid.ctl_find_refs.p_enabled = false;
      wid.ctl_symbols.p_enabled   = false;
   }
}

static void mdi_update_tagwin()
{
   if (!_no_child_windows() && TagWinFocus()) {
      _mdi.p_child._UpdateTagWindow(true);
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
   int keys[];
   copy_key_bindings_to_form("push_tag", ctl_push_tag,  LBUTTON_UP, keys);
   copy_key_bindings_to_form("find_tag", ctl_push_tag,  LBUTTON_UP, keys);
   copy_key_bindings_to_form("push_ref", ctl_find_refs, LBUTTON_UP, keys);
   copy_key_bindings_to_form("find_refs",ctl_find_refs, LBUTTON_UP, keys);
   copy_key_bindings_to_form("cb_find",  ctl_symbols,   LBUTTON_UP, keys);
   ctl_push_tag.p_user = keys;
}

/**
 * Remove the bindings that were set up in
 * {@link createPreviewSymbolShortCuts()}, above.
 */
static void unbindPreviewSymbolShortcuts()
{
   _nocheck _control ctl_push_tag;
   typeless keys = ctl_push_tag.p_user;
   int i,n = keys._length();
   for (i=0; i<n; ++i) {
      set_eventtab_index(p_active_form.p_eventtab, keys[i], 0);
   }

   msg := "";
   parse ctl_push_tag.p_message with msg '(' .; 
   ctl_push_tag.p_message = msg;
   parse ctl_find_refs.p_message with msg '(' .;
   ctl_find_refs.p_message = msg;
   parse ctl_symbols.p_message with msg '(' .;
   ctl_symbols.p_message =msg;
}

/**
 * Callback for key binding / emulation changes
 */
void _eventtab_modify_preview_symbol(typeless keytab_used, _str event="")
{
   int kt_index = find_index("default_keys", EVENTTAB_TYPE);
   if (keytab_used && kt_index != keytab_used) {
      return;
   }
   int wid = _tbGetWid("_tbtagwin_form");
   if (wid != 0) {
      wid.unbindPreviewSymbolShortcuts();
      wid.createPreviewSymbolShortcuts();
   }
}

edit1.on_create()
{
   gtagwin_in_quit_file=false;
   gtagwin_last_seekpos= -1;
   p_window_flags|=VSWFLAG_NOLCREADWRITE;
   p_window_flags|=(OVERRIDE_CURLINE_RECT_WFLAG|CURLINE_RECT_WFLAG|OVERRIDE_CURLINE_COLOR_WFLAG);
   p_window_flags&=~(CURLINE_COLOR_WFLAG);
   p_MouseActivate=MA_NOACTIVATE;
   //MK - changed this to match 9.0, doesn't work for plugin
   //_shellEditor.p_MouseActivate=MA_NOACTIVATE;
   
   //If I set tabs during the on_create it seemed to get hosed...
   //p_tabs='1 7 15 52';
   p_tabs='1 9 41';
   EditWindowBufferID=p_buf_id;
   _UpdateTagWindow();
   if (!p_Noflines) {
      insert_line('');
   }
   p_line=1;
   line_to_top();
   p_scroll_left_edge=-1;
   _post_call(mdi_update_tagwin);
   ctlbufname.p_caption='';
   edit1.SetSymbolInfoCaption(0);
   ctl_back.p_enabled=false;
   ctl_forward.p_enabled=false;

   // restore position of divider bars
   typeless xpos = _retrieve_value("_tbtagwin_form.ctl_size_x.p_x");
   if (isuinteger(xpos)) {
      ctl_size_x.p_x = xpos;
   }
   typeless ypos = _retrieve_value("_tbtagwin_form.ctl_size_y.p_y");
   if (isuinteger(ypos)) {
      ctl_size_y.p_y = ypos;
   }

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
static void SetSymbolInfoCaption(int line_no)
{
   if (p_buf_id != EditWindowBufferID) {
      _str filename=p_buf_name;
      _str caption=ctlbufname._ShrinkFilename(filename,p_active_form.p_width-ctlbufname.p_x);
      if (line_no > 0) {
         caption = caption:+': 'line_no;
      } else if (p_RLine > 1) {
         caption = caption:+': 'p_RLine;
      }
      if (caption!=ctlbufname.p_caption) {
         ctlbufname.p_caption=caption;
      }
   }
   ctlbufname.p_width=ctlbufname._text_width(ctlbufname.p_caption);
}

/*static*/ void DisplayFile(_str filename,int line_no, 
                            int seek_pos=0, int column_no=0, 
                            _str tag_name="", _str lang='')
{
   if (gPreviewTagTimerId >= 0) {
      _kill_timer(gPreviewTagTimerId);
      gPreviewTagTimerId = -1;
   }
   int orig_wid = p_window_id;
   filename=absolute(filename);
   int status=load_files('+q +m +b 'filename);
   if (status) {
      status=_BufEdit(filename,"",0,"",1);
      if (status<0) {
         // DJB 05-23-2006
         // do not do this if we are calling this from tagrefs.e
         if (p_name != 'ctlrefedit') {
            load_files('+bi 'EditWindowBufferID);
         }
         return;
      }
      p_buf_id=status;
      p_buf_flags|=(VSBUFFLAG_HIDDEN|VSBUFFLAG_DELETE_BUFFER_ON_CLOSE);
      if (lang != "") _SetEditorLanguage(lang);
      _SetAllOldLineNumbers();
   }
   //maybe_deselect(true);  // trouble with function-parameter auto-completion.
   if (column_no > 0) {
      _GoToOldLineNumber(line_no);
      p_col=column_no;
   } else {
      if (isnumber(line_no)) {
         p_RLine=line_no;
      } else {
         top();
      }
      p_col=1;
      if (seek_pos > 0) {
         _GoToROffset(seek_pos);
         // DJB 04-17-2007
         // If the seek position has the wrong line number, ignore it
         if (isnumber(line_no) && p_RLine != line_no) {
            p_RLine=line_no;
         }
      }
   }

   // exit the scroll mode if the user was scrolling around
   // and then center on the designated line
   _ExitScroll();
   center_line();

   //Use all that information to get comments:
   int f = p_active_form;
   int comment_wid = f._find_control('ctltagdocs');
   if (comment_wid > 0 && comment_wid.p_height > 0) {
      save_pos(auto p);
      int commentFlags = 0;
      _str comments = '';
      if (p_LangId == 'docbook') {
         comments = '<i>' :+ create_docbook_comment_str(tag_name) :+ '</i>';
      } else {
         status = _ExtractTagComments2(commentFlags, comments, 2000, 
                                       tag_name, filename, line_no); 
         if (!status) {
            _make_html_comments(comments, commentFlags, "", "");
         }
      }
      if (comments=='') {
         comments="<i>no comment</i>";
      }
      comment_wid.p_text=comments;
      restore_pos(p);
   }

   // force a refresh
   orig_wid.p_active_form.refresh('w');
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
   if (EditWindowBufferID!=p_buf_id) {
      if (p_buf_flags&VSBUFFLAG_HIDDEN) {
         if (_SafeToDeleteBuffer(p_buf_id,p_window_id,p_buf_flags)) {
            tagwin_quit_file();
         }
      }
      load_files('+q +m +bi 'EditWindowBufferID);
   }
}

/*static*/ void tagwin_goto_tag(_str filename, int line_no=0,
                                int seekpos=-1, int column_no=0,
                                boolean doPushBookmark=true)
{
   if (filename=='') {
      message(nls('Can not locate source code'));
      return;
   }
   if (!_no_child_windows() && doPushBookmark) {
      _mdi.p_child.push_bookmark();
   }
   int lp=lastpos(':',filename);
   if (lp && !line_no) {
      line_no=(int)substr(filename,lp+1);
      filename=substr(filename,1,lp-1);
   }
   if (_QBinaryLoadTagsSupported(filename)) {
      message(nls('Can not locate source code for %s.',filename));
      return;
   }
   int orig_buf_id=0;
   int orig_window_id=0;
   if (!_no_child_windows() && !doPushBookmark && _mdi.p_child.pop_destination()) {
      orig_window_id = _mdi.p_child;
      orig_buf_id = _mdi.p_child.p_buf_id;
   }
   if (!_no_child_windows() && doPushBookmark) {
      _mdi.p_child.mark_already_open_destinations();
   }
   int status=_mdi.p_child.edit(maybe_quote_filename(filename),EDIT_DEFAULT_FLAGS);
   if (!status) {
      _mdi.p_child.maybe_deselect(true);
      if (column_no > 0) {
         _mdi.p_child._GoToOldLineNumber(line_no);
         _mdi.p_child.center_line();
         _mdi.p_child.p_col=column_no;
      } else {
         _mdi.p_child.p_RLine=line_no;
         _mdi.p_child.center_line();
         if (seekpos >= 0) {
            _mdi.p_child._GoToROffset(seekpos);
         }
      }
      if (_mdi.p_child._lineflags()& HIDDEN_LF) {
         _mdi.p_child.expand_line_level();
      }
      int orig_col = _mdi.p_child.p_col;
      _mdi.p_child.begin_line();
      _mdi.p_child.p_col = orig_col;
      _mdi.p_child.push_destination(orig_window_id, orig_buf_id);
   } else {
      message(nls("Could not open %s: %s",filename,get_message(status)));
   }
}

_str GetClassSep(_str filename)
{
   _str lang = _Filename2LangId(filename);
   switch (lang) {
   case 'cs':
   case 'java':
   case 'ada':
   case 'pas':
   case 'e':
      return '.';
   case 'pl':
   case 'c':
   default:
      break; // drop through
   }
   return('::');
}

static void tagwin_mode_enter()
{
   tagwin_goto_tag(p_buf_name, p_RLine);
}

static void tagwin_next_window()
{
   if (!_no_child_windows()) {
      p_window_id=_mdi.p_child;
      _mdi.p_child._set_focus();
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
   "select-line"               =>'',
   "brief-select-line"         =>'',
   "select-char"               =>'',
   "brief-select-char"         =>'',
   "cua-select"                =>'',
   "deselect"                  =>'',
   "copy-to-clipboard"         =>'',
   "next-window"               =>tagwin_next_window,
   "prev-window"               =>tagwin_next_window,
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
   "vi-next-line"              =>'',
   "vi-prev-line"              =>'',
   "vi-cursor-right"           =>'',
   "vi-cursor-left"            =>'',
   "cmdline-toggle"            =>tagwin_next_window
};

void edit1.\0-ON_SELECT()
{
   _str lastevent=last_event();
   _str eventname=event2name(lastevent);
   if (eventname=='ESC') {
      tagwin_next_window();
      return;
   }
   if (eventname=='F1') {
      _dmhelp(p_active_form.p_help);
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
      tagwin_mode_enter();
      return;
   }
   int key_index=event2index(lastevent);
   int name_index=eventtab_index(_default_keys,edit1.p_mode_eventtab,key_index);
   _str command_name=name_name(name_index);
   if (command_name=='safe-exit') {
      safe_exit();
      return;
   }
   if (TagWinCommands._indexin(command_name)) {
      switch (TagWinCommands:[command_name]._varformat()) {
      case VF_FUNPTR:
         _str junk=(*TagWinCommands:[command_name])();
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
void edit1.'c-wheel-down'() {
   scroll_page_down();
}
void edit1.'c-wheel-up'() {
   scroll_page_up();
}

void edit1.rbutton_up()
{
   // Get handle to menu:
   int index=find_index("_tagbookmark_menu",oi2type(OI_MENU));
   int menu_handle=p_active_form._menu_load(index,'P');

   int flags=def_tagwin_flags;
   pushTgConfigureMenu(menu_handle, flags);

   // Show menu:
   int x,y;
   mou_get_xy(x,y);
   _KillToolButtonTimer();
   call_list("_on_popup2", translate("_tagbookmark_menu", "_", "-"), menu_handle);
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
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
   int wid = _GetTagwinWID(true);
   if (wid) {
      _UpdateTagWindow(true);
   }
}

void _cbmdibuffer_hidden_symbols()
{
   // Do nothing if there is no edit windows.
   if (_no_child_windows()) {
      return;
   }

   // Get the active edit window buffer ID.
   int editorctl_wid = _mdi.p_child;
   int editorBufID = editorctl_wid.p_buf_id;

   // Access the tagwin buffer ID.
   int twid=_GetTagwinWID(true);
   if (!twid) return;
   int orig_wid=p_window_id;
   p_window_id=twid;
   p_window_id=edit1;

   // If the active edit window's buffer ID is the same as the
   // tagwin's buffer ID, go ahead and quit the tagwin's buffer.
   if (editorBufID == p_buf_id && p_buf_id != EditWindowBufferID) {
      if (p_buf_flags&VSBUFFLAG_HIDDEN) {
         if (_SafeToDeleteBuffer(p_buf_id,p_window_id,p_buf_flags)) {
            //say("_cbmdibuffer_hidden_symbols Calling tagwin_quit_file()");
            tagwin_quit_file();
         }
      }

      // Load the ".Tag Window Buffer"
      load_files('+q +m +bi 'EditWindowBufferID);
      _lbclear();
      insert_line('');p_line=1;
      line_to_top();
      p_scroll_left_edge=-1;
   }

   // restore the window ID
   p_window_id=orig_wid;
}

/**
 * This function handles trying to keep an auto-hidden form up for the 
 * duration that the form that activated it remains in focus. 
 * We keep track of the activation source flag when we activate the 
 * preview window, and then check here in the auto-hide callback if 
 * that form still has focus.  If so, we will delay hiding the tool window. 
 */
int _autohide_wait__tbtagwin_form()
{
   wid := _get_focus();
   if (!wid) return 0;
   wid = wid.p_active_form;
   formName := wid.p_name;

   switch (gtagwin_activated_by) {
   case APF_REFERENCES:
      if (formName :== "_tbtagrefs_form") return 1;
      break;
   case APF_SYMBOLS:
      if (formName :== "_tbcbrowser_form") return 1;
      break;
   case APF_FIND_SYMBOL:
      if (formName :== "_tbfind_symbol_form") return 1;
      break;
   case APF_CLASS:
      if (formName :== "_tbclass_form") return 1;
      break;
   case APF_DEFS:
      if (formName :== "_tbproctree_form") return 1;
      break;
   case APF_BOOKMARKS:
      if (formName :== "_tbbookmarks_form") return 1;
      break;
   case APF_SEARCH_RESULTS:
      if (formName :== "_tbsearch_form") return 1;
      break;
   case APF_FILES:
      if (formName :== "_tbfilelist_form") return 1;
      break;
   case APF_ANNOTATIONS:
      if (formName :== "_tbannotations_browser_form") return 1;
      break;
   case APF_BREAKPOINTS:
      if (formName :== "_tbbreakpoints_form") return 1;
      break;
   case APF_MESSAGE_LIST:
      if (formName :== "_tbmessages_browser_form") return 1;
      break;
   case APF_UNIT_TEST:
      if (formName :== "_tbunittest_form") return 1;
      break;
   }

   gtagwin_activated_by = -1;
   return 0;
}
