////////////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////////////
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "tagsdb.sh"
#include "eclipse.sh"
#import "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "se/ui/toolwindow.e"
#import "se/ui/twautohide.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "context.e"
#import "dlgman.e"
#import "guicd.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "project.e"
#import "projutil.e"
#import "pushtag.e"
#import "seltree.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tagwin.e"
#import "tags.e"
#import "wkspace.e"
#endregion

using namespace se.lang.api;

//////////////////////////////////////////////////////////////////////////
// Tag Select Form


// Timer for refreshing tagwin when scrolling through diff tree
static int gTagSelectTimerId=-1;

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (before defload).  Used to
// initialize the timer variable and window IDs.
//
definit()
{
   // IF editor is initializing from invocation
   if (arg(1)!='L') {
      gTagSelectTimerId=-1;
   }
}

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Open the given file in a temporary view, and insert all the tags from
// that file into the tree control, which is the current object.
//
static int BuildTagList(_str filename)
{
   // save the tree wid, and open the file
   form_wid := p_active_form;
   tree_wid := p_window_id;
   int temp_view_id, orig_view_id;
   buffer_already_exists := false;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id,"",buffer_already_exists,false,true);
   if (status) {
      return(status);
   }

   // update the current context
   orig_context_file := "";
   tag_get_detail2(VS_TAGDETAIL_current_file,0,orig_context_file);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   // insert the tags from the current context into the tree, no heirarchy
   // path up the user info with start line and end line
   cb_prepare_expand(form_wid,tree_wid,TREE_ROOT_INDEX);
   tree_wid._TreeDelete(TREE_ROOT_INDEX,'C');
   int i, n=tag_get_num_of_context();
   for (i=1; i<=n; i++) {
      j := tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      // is this a function, procedure, or prototype?
      type_name :="";
      tag_flags := SE_TAG_FLAG_NULL;
      startline := endline := 0;
      tag_get_detail2(VS_TAGDETAIL_context_type,i,type_name);
      tag_get_detail2(VS_TAGDETAIL_context_flags,i,tag_flags);
      if (tag_filter_type(SE_TAG_TYPE_NULL,def_tagselect_flags,type_name,(int)tag_flags)) {
         tag_get_detail2(VS_TAGDETAIL_context_start_linenum,i,startline);
         tag_get_detail2(VS_TAGDETAIL_context_end_linenum,i,endline);
         tag_get_detail2(VS_TAGDETAIL_context_file,i,filename);
         j=tag_tree_insert_fast(tree_wid,TREE_ROOT_INDEX,VS_TAGMATCH_context,i,1,-1,0,1,1,
                                startline" "endline" "type_name);
      }
   }

   // sort the items in the tree alphabetically
   tree_wid._TreeTop();
   if (def_tag_select_options&PROC_TREE_SORT_FUNCTION) {
      tree_wid._TreeSortCaption(TREE_ROOT_INDEX,'i');
   }

   // close the temporary view and restore the context
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_pop_context();
   return(0);
}

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Event table for tag selector form
//
defeventtab _tag_select_form;

static _str NO_TAG_ISEARCH(...) {
   if (arg()) ctlname_prefix.p_user=arg(1);
   return ctlname_prefix.p_user;
}
static _str NO_FILL_IN_CB(...) {
   if (arg()) ctl_tag_tree_view.p_user=arg(1);
   return ctl_tag_tree_view.p_user;
}

// Refresh the list of symbols in case if the filters have changed
void _tagselect_refresh_symbols()
{
   _nocheck _control ctlfilename;
   _TreeBeginUpdate(TREE_ROOT_INDEX,"",'T');
   BuildTagList(p_active_form.ctlfilename.p_user);
   _TreeEndUpdate(TREE_ROOT_INDEX);
   p_redraw=true;
}

// handle OK button press (successful finish)
void ctlok.lbutton_up()
{
   index := ctl_tag_tree_view._TreeCurIndex();
   if (index <= 0) {
      p_active_form._delete_window("");
      return;
   }
   FuncName := ctl_tag_tree_view._TreeGetCaption(index);
   _str LineInfo=ctl_tag_tree_view._TreeGetUserInfo(index);

   //Before we save the form response, complete the text in the text box
   //so the retrieval looks nice.
   ctlname_prefix.p_text=FuncName;
   _save_form_response();
   p_active_form._delete_window(FuncName:+_chr(1):+LineInfo);
}

// initialize form when it is created, load tags from file
void ctlok.on_create(_str filename=null,_str caption=null,_str formCaption=null)
{
   if (filename==null) {
      filename=_mdi.p_child.p_buf_name;
   }
   ctlfilename.p_caption=ctlfilename._ShrinkFilename(filename,ctlfilename.p_width);
   ctlfilename.p_user=filename;
   ctlline.p_caption="";

   ctl_tag_tree_view.BuildTagList(filename);
   ctl_tag_tree_view._TreeTop();
   if (caption!="") {
      int index=ctl_tag_tree_view._TreeSearch(TREE_ROOT_INDEX,caption);
      if (index < 0) {
         index=ctl_tag_tree_view._TreeSearch(TREE_ROOT_INDEX,caption, "", null, 0);
      }
      if (index>=0) {
         ctl_tag_tree_view._TreeSetCurIndex(index);
      }
   }
   if ( formCaption!=null ) {
      p_active_form.p_caption = formCaption;
   }
   ctlname_prefix._retrieve_list();
}

// kill the timer
static void kill_select_tag_timer()
{
   if (gTagSelectTimerId != -1) {
      _kill_timer(gTagSelectTimerId);
      gTagSelectTimerId=-1;
   }
}

// kill the timer
void ctlok.on_destroy()
{
   kill_select_tag_timer();
}

static void SearchTreeForPrefix()
{
   text := ctlname_prefix.p_text;
   wid := p_window_id;
   p_window_id=ctl_tag_tree_view;
   int index=_TreeSearch(TREE_ROOT_INDEX,text,'ip');
   if (index>-1) {
      _TreeSetCurIndex(index);
   }
   p_window_id=wid;
}

void ctlname_prefix.on_change(int reason)
{
   if (NO_TAG_ISEARCH()==1) return;
   NO_FILL_IN_CB(1);
   SearchTreeForPrefix();
   NO_FILL_IN_CB(0);
}


/**
 * Retrieve information about the given tag in the given file
 *
 * @param filename       Source code file to search
 * @param tag_name       name of tag to look for
 * @param tag_caption    displayed caption for tag
 * @param StartLine      (reference) start line
 * @param LastLine       (reference) last line
 * @param TagType        (reference) set to unique tag information
 * @param pcm            (pointer) all tag information
 *
 * @return 0 on success, nonzero otherwise
 */
int FindSymbolInfo(_str filename,
                   _str tag_name, _str tag_caption,
                   int &StartLine, int &LastLine,
                   int &CommentLine, _str &TagType,
                   struct VS_TAG_BROWSE_INFO *pcm=null,
                   bool AlwaysLoadFromDisk=false)
{
   // open the file in a temporary view
   buffer_already_exists := false;
   int temp_view_id, orig_view_id;
   LoadOptions := "";
   if (AlwaysLoadFromDisk) {
      LoadOptions="+d";
   }
   int status=_open_temp_view(filename,temp_view_id,orig_view_id,LoadOptions,buffer_already_exists,false,true);
   if (status) {
      return(status);
   }

   // update the current context
   orig_context_file := "";
   tag_get_detail2(VS_TAGDETAIL_current_file,0,orig_context_file);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   // search for the tag within the current context
   type_name := "";
   start_line_no := start_seekpos := end_line_no := 0;
   int context_id = tag_find_context_iterator(tag_name,true,true);
   while (context_id > 0) {
      tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);
      if (TagType=="" || type_name==TagType) {
         _str caption=tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,true,true,true);
         if (tag_caption=="" || caption==tag_caption) {
            tag_get_detail2(VS_TAGDETAIL_context_start_linenum, context_id, start_line_no);
            tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, start_seekpos);
            tag_get_detail2(VS_TAGDETAIL_context_end_linenum,   context_id, end_line_no);
            if (StartLine==0) {
               StartLine=(int)start_line_no;
               LastLine=(int)end_line_no;
               TagType=type_name;
               if (pcm!=null) {
                  _GetContextTagInfo(*pcm,"",tag_name, filename, start_line_no);
               }
               break;
            } else if (StartLine==start_line_no && LastLine==end_line_no) {
               if (pcm!=null) {
                  _GetContextTagInfo(*pcm,"",tag_name, filename, start_line_no);
               }
               break;
            }
         }
      }
      context_id = tag_next_context_iterator(tag_name,context_id,true,true);
      // didn't find the tag with matching caption, try just tag name
      if (tag_caption!="" && context_id < 0 && StartLine==0) {
         tag_caption="";
         context_id = tag_find_context_iterator(tag_name,true,true);
      }
   }

   // If we got the tag, find the start line, otherwise, use startline
   CommentLine = StartLine;
   if (context_id>0 && start_seekpos>0) {
      _GoToROffset(start_seekpos);
      typeless unused;
      _do_default_get_tag_header_comments(CommentLine,unused);
      if (!CommentLine) {
         CommentLine=StartLine;
      }
   }

   // close the temp view and clean up
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_pop_context();
   return (context_id > 0)? 0:1;
}

/**
 * Retrieve information about the tag with the given caption.
 * If the caption is initially empty, prompt the user with
 * the list of tags, and let them select one.
 *
 * @param filename       (required) name of file to list tags in
 * @param caption        (reference) If empty, let user select caption,
 *                                   otherwise, caption to search for
 * @param StartLine      (reference) set to first line of tag
 * @param LastLine       (reference) set to last line of tag
 * @param TagType        (reference) set to unique tag information
 * @param pcm            (optional) contains rest of tag info
 *
 * @return 0 on success, nonzero on error.
 */
int GetSymbolInfo(_str filename, _str &caption,
                  int &StartLine,int &LastLine,int &CommentLine,_str &TagType,
                  struct VS_TAG_BROWSE_INFO *pcm=null,
                  bool AlwaysLoadFromDisk=false,
                  _str formCaption=null)
{
   // initialize the tag browse info if we were given any
   if (pcm!=null) {
      tag_init_tag_browse_info(*pcm);
   }

   // display the form
   OrigWID := p_window_id;
   _str Info=show("-modal -reinit -xy _tag_select_form",filename,caption,formCaption);
   if (Info=="") {
      return(COMMAND_CANCELLED_RC);
   }

   // parse up the results and return
   _str sStartLine,sLastLine;
   parse Info with caption (_chr(1)) sStartLine sLastLine TagType . ;
   StartLine=(int)sStartLine;
   LastLine=(int)sLastLine;
   _str tag_name;
   tag_tree_decompose_caption(caption,tag_name);
   p_window_id=OrigWID;
   FindSymbolInfo(filename,tag_name,caption,StartLine,LastLine,CommentLine,TagType,pcm,AlwaysLoadFromDisk);
   return(0);
}

// Bring up filter menu for tag dialog
void ctl_tag_tree_view.rbutton_up()
{
   // Get handle to menu:
   index := find_index("_tagbookmark_menu",oi2type(OI_MENU));
   menu_handle := p_active_form._menu_load(index,'P');

   if (def_tag_select_options&PROC_TREE_SORT_FUNCTION) {
      _menu_set_state(menu_handle,"sortfunc",MF_CHECKED,'C');
   }else if (def_tag_select_options&PROC_TREE_SORT_LINENUMBER) {
      _menu_set_state(menu_handle,"sortlinenum",MF_CHECKED,'C');
   }

   pushTgConfigureMenu(menu_handle, 
                       def_tagselect_flags, 
                       include_proctree:false, 
                       include_casesens:false, 
                       include_sort:true);

   // Show menu:
   mou_get_xy(auto x,auto y);
   _KillToolButtonTimer();
   status := _menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

// Timer callback, called from the on_change() event of the tree
// control, whenever the selected item in the tree changes.
//
// Used to update the output symbol tab, in order to preview
// tag choices.
//
static void _TagSelectTimerCallback()
{
   // kill the timer
   kill_select_tag_timer();

   // find the tagform
   _nocheck _control ctl_tag_tree_view;
   _nocheck _control ctlfilename;
   int wid=_find_formobj("_tag_select_form","n");
   if (!wid) return;

   // update the property view, call tree view, and output tab
   index := wid.ctl_tag_tree_view._TreeCurIndex();
   _str file_name=wid.ctlfilename.p_user;
   _str uinfo=wid.ctl_tag_tree_view._TreeGetUserInfo(index);
   line_no := "";
   parse uinfo with line_no " " . ;
   caption := wid.ctl_tag_tree_view._TreeGetCaption(index);
   tag_tree_decompose_caption(caption,caption);

   // find the output tagwin and update it
   tag_init_tag_browse_info(auto cm, caption, "", SE_TAG_TYPE_NULL, SE_TAG_FLAG_NULL, file_name, (int)line_no);
   tag_push_matches();
   cb_refresh_output_tab(cm, true, true, false, APF_SELECT_SYMBOL);
   tag_pop_matches();
}

// Handle change selected or selections (double-click/enter)
// in the tree control
void ctl_tag_tree_view.on_change(int reason, int index)
{
   if (reason == CHANGE_SELECTED) {
      _str startline,endline;
      parse _TreeGetUserInfo(index) with startline endline .;
      ctlline.p_caption=nls("Line range: %s - %s",startline,endline);

      kill_select_tag_timer();
      if (_GetTagwinWID(true)) {
         int timer_delay=max(200,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
         gTagSelectTimerId=_set_timer(timer_delay, _TagSelectTimerCallback);
      }

      NO_TAG_ISEARCH(1);

      if (NO_FILL_IN_CB()!=1) {
         wid := p_window_id;
         text := _TreeGetCaption(index);
         p_window_id=ctlname_prefix;
         p_text=text;_set_sel(1);_refresh_scroll();
         _set_sel(1,length(p_text)+1);
         p_window_id=wid;
      }

      NO_TAG_ISEARCH(0);

   } else if (reason == CHANGE_LEAF_ENTER) {
      ctlok.call_event(ctlok,LBUTTON_UP);
   }
}

void ctl_tag_tree_view.'a'-'z','_','A'-'Z'()
{
   wid := p_window_id;
   p_window_id=ctlname_prefix;
   _str ch=last_event();
   _set_focus();
   call_event(p_window_id,ch);
   p_window_id=wid;
}

// handle resizing the dialog
void _tag_select_form.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int tree_y = ctl_tag_tree_view.p_y;
   int button_width  = ctlok.p_width;
   int button_height = ctlok.p_height;

   // force size of dialog to remain reasonable
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*3, button_height*4);
   }

   // available space and border usage
   int avail_x, avail_y, border_x, border_y;
   avail_x  = p_width;
   avail_y  = p_height;
   border_x = ctlfilename.p_x;
   border_y = ctlfilename.p_y;

   // size the tree controls
   ctl_tag_tree_view.p_width  = avail_x - border_x*2;
   ctl_tag_tree_view.p_height = avail_y - border_y*2 - button_height - tree_y;
   ctlline.p_x= avail_x - border_x - ctlline.p_width;
   ctlfilename.p_width = avail_x - border_x*3 - ctlline.p_width;
   ctlfilename.p_caption = ctlfilename._ShrinkFilename(ctlfilename.p_user,ctlfilename.p_width);

   // move the buttons up/down
   ctlok.p_y     = avail_y - border_y - button_height;
   ctlcancel.p_y = avail_y - border_y - button_height;
   ctlname_prefix.p_width=ctl_tag_tree_view.p_width;
}

static void _TagSelectTreeTimerCallback()
{
   // kill the timer
   kill_select_tag_timer();

   // find the tagform
   _nocheck _control ctl_tree;
   int wid=_find_formobj("_select_tree_form","n");
   if (!wid) return;

   // update the property view, call tree view, and output tab
   index := wid.ctl_tree._TreeCurIndex();
   if (index <= 0) return;
   _str uinfo=wid.ctl_tree._TreeGetUserInfo(index);
   if (isuinteger(uinfo) && uinfo <= tag_get_num_of_matches()) {
      tag_get_match_info((int)uinfo, auto cm);
      tag_push_matches();
      cb_refresh_output_tab(cm, true, true, false, APF_SELECT_SYMBOL);
      tag_pop_matches();
   }
}

static void sortProcsAndProtos(VSCodeHelpFlags codehelpFlags)
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(false);

   // Copy all the matches from the tree
   bool isProto[];
   int matchIds[];
   _str captions[];
   int bitmaps[];
   int overlays[][];
   i := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   j := 0;
   while ( i > 0) {
      
      matchId := _TreeGetUserInfo(i);
      isProto[j] = false;
      matchIds[j] = matchId;
      captions[j] = _TreeGetCaption(i);
      _TreeGetInfo(i, auto show_children, bitmaps[j]);
      _TreeGetOverlayBitmaps(i, overlays[i]);
      tag_get_detail2(VS_TAGDETAIL_match_type, matchId, auto typeName); 
      if (typeName == "proto" || typeName == "procproto") {
         isProto[j] = true;
      }
      tag_get_detail2(VS_TAGDETAIL_match_flags, matchId, auto tagFlags); 
      if (tagFlags & SE_TAG_FLAG_FORWARD) {
         isProto[j] = true;
      }

      i = _TreeGetNextSiblingIndex(i);
      j++;
   }

   // Do they want procs or prototypes first?
   preferProtos := false;
   if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION) {
      preferProtos = true;
   }

   // Insert the preferred stock
   _TreeBeginUpdate(TREE_ROOT_INDEX);
   _TreeDelete(TREE_ROOT_INDEX, "C");
   for (i=0; i<isProto._length(); i++) {
      if (isProto[i] == preferProtos) {
         j = _TreeAddItem(TREE_ROOT_INDEX, captions[i],
                          TREE_ADD_AS_CHILD, bitmaps[i], bitmaps[i],
                          TREE_NODE_LEAF, 0, matchIds[i]);
         if (overlays[i] != null && overlays[i]._length() > 0) {
            _TreeSetOverlayBitmaps(j, overlays[i]);
         }
      }
   }
   // Then insert the other matches
   for (i=0; i<isProto._length(); i++) {
      if (isProto[i] != preferProtos) {
         j = _TreeAddItem(TREE_ROOT_INDEX, captions[i],
                          TREE_ADD_AS_CHILD, bitmaps[i], bitmaps[i],
                          TREE_NODE_LEAF, 0, matchIds[i]);
         if (overlays[i] != null && overlays[i]._length() > 0) {
            _TreeSetOverlayBitmaps(j, overlays[i]);
         }
      }
   }
   _TreeEndUpdate(TREE_ROOT_INDEX);
   _TreeTop();
}

static void sortInProjectAndWorkspace(_str file_name)
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(false);

   // Determine the current file name associated with this project
   current_project := _WorkspaceFindProjectWithFile(file_name, _workspace_filename, true, true);
   if (current_project == "") current_project = _project_name;
   if (current_project == "") return;

   // Copy all the matches from the tree
   bool isSameFileName[];
   bool isSameDirectory[];
   bool isInProject[];
   bool isInWorkspace[];
   int matchIds[];
   _str captions[];
   int bitmaps[];
   int overlays[][];
   i := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   j := 0;
   while ( i > 0) {
      
      matchId := _TreeGetUserInfo(i);
      isSameFileName[j] = false;
      isInProject[j] = false;
      isInWorkspace[j] = false;
      matchIds[j] = matchId;
      captions[j] = _TreeGetCaption(i);
      _TreeGetInfo(i, auto show_children, bitmaps[j]);
      _TreeGetOverlayBitmaps(i, overlays[i]);
      tag_get_detail2(VS_TAGDETAIL_match_file, matchId, auto matchFilename); 

      if (!_CheckTimeout()) {
         if (_isFileInProject(_workspace_filename, current_project, matchFilename)) {
            // file is in the same project
            isInProject[j] = true;
            if (_file_eq(_strip_filename(file_name, 'PE'), _strip_filename(matchFilename, 'PE'))) {
               isSameFileName[j] = true;
            }
         } else if (_file_eq(_strip_filename(file_name, 'N'), _strip_filename(matchFilename, 'N'))) {
            // file is in the same directory
            isSameDirectory[j] = true;
            if (_file_eq(_strip_filename(file_name, 'PE'), _strip_filename(matchFilename, 'PE'))) {
               isSameFileName[j] = true;
            }
         } else if (_WorkspaceFindProjectWithFile(matchFilename, _workspace_filename, true, true)) {
            // file is in the current workspace
            isInWorkspace[j] = true;
            if (_file_eq(_strip_filename(file_name, 'PE'), _strip_filename(matchFilename, 'PE'))) {
               isSameFileName[j] = true;
            }
         }
      }

      // next please
      i = _TreeGetNextSiblingIndex(i);
      j++;
   }

   // Insert the preferred stock
   _TreeBeginUpdate(TREE_ROOT_INDEX);
   _TreeDelete(TREE_ROOT_INDEX, "C");

   // First insert files that have the same name and are in the same project
   for (i=0; i<isInProject._length(); i++) {
      if (isInProject[i] && isSameFileName[i]) {
         j = _TreeAddItem(TREE_ROOT_INDEX, captions[i],
                          TREE_ADD_AS_CHILD, bitmaps[i], bitmaps[i],
                          TREE_NODE_LEAF, 0, matchIds[i]);
         if (overlays[i] != null && overlays[i]._length() > 0) {
            _TreeSetOverlayBitmaps(j, overlays[i]);
         }
      }
   }
   // Next insert other files in the same project
   for (i=0; i<isInProject._length(); i++) {
      if (isInProject[i] && !isSameFileName[i]) {
         j = _TreeAddItem(TREE_ROOT_INDEX, captions[i],
                          TREE_ADD_AS_CHILD, bitmaps[i], bitmaps[i],
                          TREE_NODE_LEAF, 0, matchIds[i]);
         if (overlays[i] != null && overlays[i]._length() > 0) {
            _TreeSetOverlayBitmaps(j, overlays[i]);
         }
      }
   }
   // Using the same technique, insert files that are in the same directory
   for (i=0; i<isSameDirectory._length(); i++) {
      if (isSameDirectory[i] && isSameFileName[i]) {
         j = _TreeAddItem(TREE_ROOT_INDEX, captions[i],
                          TREE_ADD_AS_CHILD, bitmaps[i], bitmaps[i],
                          TREE_NODE_LEAF, 0, matchIds[i]);
         if (overlays[i] != null && overlays[i]._length() > 0) {
            _TreeSetOverlayBitmaps(j, overlays[i]);
         }
      }
   }
   for (i=0; i<isSameDirectory._length(); i++) {
      if (isSameDirectory[i] && !isSameFileName[i]) {
         j = _TreeAddItem(TREE_ROOT_INDEX, captions[i],
                          TREE_ADD_AS_CHILD, bitmaps[i], bitmaps[i],
                          TREE_NODE_LEAF, 0, matchIds[i]);
         if (overlays[i] != null && overlays[i]._length() > 0) {
            _TreeSetOverlayBitmaps(j, overlays[i]);
         }
      }
   }

   // Using the same technique again, insert files that are in the same workspace
   for (i=0; i<isInWorkspace._length(); i++) {
      if (isInWorkspace[i] && isSameFileName[i]) {
         j = _TreeAddItem(TREE_ROOT_INDEX, captions[i],
                          TREE_ADD_AS_CHILD, bitmaps[i], bitmaps[i],
                          TREE_NODE_LEAF, 0, matchIds[i]);
         if (overlays[i] != null && overlays[i]._length() > 0) {
            _TreeSetOverlayBitmaps(j, overlays[i]);
         }
      }
   }
   for (i=0; i<isInWorkspace._length(); i++) {
      if (isInWorkspace[i] && !isSameFileName[i]) {
         j = _TreeAddItem(TREE_ROOT_INDEX, captions[i],
                          TREE_ADD_AS_CHILD, bitmaps[i], bitmaps[i],
                          TREE_NODE_LEAF, 0, matchIds[i]);
         if (overlays[i] != null && overlays[i]._length() > 0) {
            _TreeSetOverlayBitmaps(j, overlays[i]);
         }
      }
   }

   // Now insert all the other files
   for (i=0; i<isInWorkspace._length(); i++) {
      if (!isInProject[i] && !isInWorkspace[i] && !isSameDirectory[i]) {
         j = _TreeAddItem(TREE_ROOT_INDEX, captions[i],
                          TREE_ADD_AS_CHILD, bitmaps[i], bitmaps[i],
                          TREE_NODE_LEAF, 0, matchIds[i]);
         if (overlays[i] != null && overlays[i]._length() > 0) {
            _TreeSetOverlayBitmaps(j, overlays[i]);
         }
      }
   }

   // that's all
   _TreeEndUpdate(TREE_ROOT_INDEX);
   _TreeTop();
}

static const TAG_NAVIGATION_PROMPT             = "Prompt with all choices";
static const TAG_NAVIGATION_PREFER_DEFINITION  = "Symbol definition (proc)";
static const TAG_NAVIGATION_PREFER_DECLARATION = "Symbol declaration (proto)";
static const TAG_NAVIGATION_ONLY_WORKSPACE     = "Only Show Symbols in Current Workspace";
static const TAG_NAVIGATION_ONLY_PROJECT       = "Only Show Symbols in Current Project";

static _str tag_select_callback(int sl_event, typeless user_data, typeless info=null)
{
   switch (sl_event) {
   case SL_ONINITFIRST:
      // move defs or procs up to the top of the list depending on the
      // user's preferences.
      if (!_no_child_windows()) {
         lang := _mdi.p_child.p_LangId;
         codehelpFlags := _GetCodehelpFlags(lang);
         tree_wid := _find_control("ctl_tree");
         if (tree_wid > 0) {
            if ((codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION) ||
                (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION)) {
               tree_wid.sortProcsAndProtos(codehelpFlags);
               tree_wid._TreeSortCol(-1);
               tree_wid._TreeSetHeaderClickable(1,1);
            }
            if (_workspace_filename != "" && (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT)) {
               tree_wid.sortInProjectAndWorkspace(_mdi.p_child.p_buf_name);
               tree_wid._TreeSortCol(-1);
               tree_wid._TreeSetHeaderClickable(1,1);
            }
         }
      }

      // Add custom controls to show proc/proto preference options
      // if the options are not already set
      noNavPreference := ((_mdi.p_child._GetCodehelpFlags() & (VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION|VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION)) == 0);
      last_command := name_name(last_index());
      if ((last_command == "push-tag" || 
           last_command == "find-tag" || 
           last_command == "f" ||
           last_command == "push-alttag" || 
           last_command == "push-tag-filter-overloads" &&
           last_command == "mou-push-tag" ||
           last_command == "gui-push-tag" ||
           last_command == "goto-tag" ||
           last_command == "gnu-goto-tag" ||
           last_command == "vi-split-to-tag" ) &&
          (_no_child_windows() == false) && 
          ((_mdi.p_child._GetCodehelpFlags() & VSCODEHELPFLAG_FIND_TAG_HIDE_OPTIONS) == 0 ||
           (last_command=="push-alttag" && noNavPreference)))  {
         bottom_wid := _find_control("ctl_bottom_pic");
         label1_wid := _create_window(OI_LABEL, bottom_wid, "Prioritize navigation to:", 0, 30, bottom_wid.p_width, 250, CW_CHILD);
         combo1_wid := _create_window(OI_COMBO_BOX, bottom_wid, "", 0, 30, bottom_wid.p_width, 300, CW_CHILD);
         label2_wid := _create_window(OI_LABEL, bottom_wid, "Restrict choices to:", 0, 390, bottom_wid.p_width, 250, CW_CHILD);
         combo2_wid := _create_window(OI_COMBO_BOX, bottom_wid, "", 0, 390, bottom_wid.p_width, 300, CW_CHILD);
         check3_wid := _create_window(OI_CHECK_BOX, bottom_wid, "Ignore forward class declarations", 0, 750, bottom_wid.p_width, 300, CW_CHILD);
         check4_wid := _create_window(OI_CHECK_BOX, bottom_wid, "Do not show these options again", 0, 1050, bottom_wid.p_width, 300, CW_CHILD);
         bottom_wid.p_height = 1500;
         bottom_wid.p_visible = bottom_wid.p_enabled = true;
         label1_wid.p_width = label1_wid._text_width(label1_wid.p_caption)+60;
         label2_wid.p_width = label1_wid.p_width;
         check3_wid.p_width = check3_wid._text_width(check3_wid.p_caption)+600;
         check4_wid.p_width = check4_wid._text_width(check4_wid.p_caption)+600;
         combo1_wid.p_name = "ctlnavigation";
         combo2_wid.p_name = "ctlnavchoices";
         check3_wid.p_name = "ctlignoreforwardclass";
         check4_wid.p_name = "ctlhideoptions";

         combo1_wid.p_style = PSCBO_NOEDIT;
         combo1_wid._lbadd_item(TAG_NAVIGATION_PROMPT);
         combo1_wid._lbadd_item(TAG_NAVIGATION_PREFER_DEFINITION);
         combo1_wid._lbadd_item(TAG_NAVIGATION_PREFER_DECLARATION);
         codehelpFlags := LanguageSettings.getCodehelpFlags(_mdi.p_child.p_LangId);
         value := "";
         if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION) {
            value = TAG_NAVIGATION_PREFER_DEFINITION;
         } else if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION) {
            value = TAG_NAVIGATION_PREFER_DECLARATION;
         } else {
            value = TAG_NAVIGATION_PROMPT;
         }
         combo1_wid._lbfind_and_select_item(value);
         combo1_wid.p_x = label1_wid.p_x_extent + 60;
         combo1_wid.p_width = combo1_wid._text_width(TAG_NAVIGATION_ONLY_WORKSPACE)+300;
         combo1_wid.p_eventtab2 = defeventtab _ul2_combobx;

         combo2_wid.p_style = PSCBO_NOEDIT;
         combo2_wid._lbadd_item(TAG_NAVIGATION_PROMPT);
         combo2_wid._lbadd_item(TAG_NAVIGATION_ONLY_WORKSPACE);
         combo2_wid._lbadd_item(TAG_NAVIGATION_ONLY_PROJECT);
         if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT) {
            value = TAG_NAVIGATION_ONLY_PROJECT;
         } else if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_WORKSPACE) {
            value = TAG_NAVIGATION_ONLY_WORKSPACE;
         } else {
            value = TAG_NAVIGATION_PROMPT;
         }
         combo2_wid._lbfind_and_select_item(value);
         combo2_wid.p_x = combo1_wid.p_x;
         combo2_wid.p_width = combo1_wid.p_width;
         combo2_wid.p_eventtab2 = defeventtab _ul2_combobx;

         check3_wid.p_value = (codehelpFlags & VSCODEHELPFLAG_FIND_FORWARD_CLASS_DECLARATIONS)? 0:1;
         check4_wid.p_value = 0;
      }
      // bind keys to commands to scroll the preview window
      p_active_form._MakePreviewWindowShortcuts();
      break;
   case SL_ONCLOSE:
      // check custom controls for proc/proto preference options
      if (!_no_child_windows()) {
         lang := _mdi.p_child.p_LangId;
         codehelpFlags := _GetCodehelpFlags(lang);

         wid := p_active_form._find_control("ctlnavigation");
         if (wid) {
            codehelpFlags &= ~(VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION | VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION);
            if (wid.p_text == TAG_NAVIGATION_PREFER_DEFINITION) {
               codehelpFlags |= VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION;
            } else if (wid.p_text == TAG_NAVIGATION_PREFER_DECLARATION) {
               codehelpFlags |= VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION;
            }
            // If they invokked this dialog using Ctrl+Alt+., then flip settings
            last_command = name_name(last_index());
            if (last_command == "push-alttag") {
               if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION) {
                  codehelpFlags |= VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION;
                  codehelpFlags &= ~ VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION;
               } else if (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION) {
                  codehelpFlags |= VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION;
                  codehelpFlags &= ~ VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION;
               }
            }
         }

         wid = p_active_form._find_control("ctlnavchoices");
         if (wid) {
            codehelpFlags &= ~(VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_WORKSPACE | VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT);
            if (wid.p_text == TAG_NAVIGATION_ONLY_WORKSPACE) {
               codehelpFlags |= VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_WORKSPACE;
            } else if (wid.p_text == TAG_NAVIGATION_ONLY_PROJECT) {
               codehelpFlags |= VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT;
            }
         }

         wid = p_active_form._find_control("ctlignoreforwardclass");
         if (wid) {
            if (wid.p_value) {
               codehelpFlags  &= ~VSCODEHELPFLAG_FIND_FORWARD_CLASS_DECLARATIONS;
            } else {
               codehelpFlags |= VSCODEHELPFLAG_FIND_FORWARD_CLASS_DECLARATIONS;
            }
         }

         wid = p_active_form._find_control("ctlhideoptions");
         if (wid) {
            if (wid.p_value) {
               codehelpFlags |= VSCODEHELPFLAG_FIND_TAG_HIDE_OPTIONS;
            } else {
               codehelpFlags  &= ~VSCODEHELPFLAG_FIND_TAG_HIDE_OPTIONS;
            }
         }

         if (codehelpFlags != _GetCodehelpFlags(lang)) {
            LanguageSettings.setCodehelpFlags(lang, codehelpFlags);
         }
      }
      kill_select_tag_timer();
      break;
   case SL_ONINIT:
      kill_select_tag_timer();
      break;
   case SL_ONSELECT:
      kill_select_tag_timer();
      if ( _GetTagwinWID(false) || tw_is_auto_form("_tbtagwin_form") ) {
         int timer_delay=max(200,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
         gTagSelectTimerId=_set_timer(timer_delay, _TagSelectTreeTimerCallback);
      }
      break;
   case ST_BUTTON_PRESS:
      // force tree sorting
      tree_wid := _find_control("ctl_tree");
      col := info;
      if (tree_wid > 0 && isinteger(col) && col >= 0) {
         tree_wid._TreeGetColButtonInfo(col,auto width,auto flags,auto state,auto caption);
         sort_options := "";
         if ( !(flags&TREE_BUTTON_SORT_DESCENDING) ) sort_options :+= "D";
         switch (col) {
         case 1: sort_options :+= "I"; break;
         case 2: sort_options :+= "F"; break;
         case 3: sort_options :+= "N"; break;
         }
         tree_wid._TreeSortCol(col, sort_options);
         if ( flags&TREE_BUTTON_SORT_DESCENDING ) {
            tree_wid._TreeSetColButtonInfo(col,width,flags&~TREE_BUTTON_SORT_DESCENDING,state,caption);
         } else {
            tree_wid._TreeSetColButtonInfo(col,width,flags|TREE_BUTTON_SORT_DESCENDING,state,caption);
         }
      }
      break;
   }
   return "";
}


/**
 * Display a dialog for selecting a tag match among the tags in
 * the current tag match set.
 * 
 * @return match ID > 0 on success, <0 on error,
 *         COMMAND_CANCELLED_RC on user cancellation.
 */
int tag_select_match(VSCodeHelpFlags codehelpFlags=VSCODEHELPFLAG_NULL)
{
   _str captions[];
   _str match_ids[];
   int pictures[];
   int overlays[];

   bool been_there_done_that:[];
   typeless match_id=0;
   caption := "";
   key := "";
   leaf_flag := 0;
   pic_member := 0;
   i_access := 0;
   i_type := 0;
   index := 0;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(false);

   m := 0;
   n := tag_get_num_of_matches();
   if (n == 0) {
      // error, no matches
      return BT_RECORD_NOT_FOUND_RC;
   } else if (n == 1) {
      // there can be only one
      return 1;
   }

   // if function help, list-members, member help, or mouse-over help is active,
   // close it first.
   TerminateMouseOverHelp();
   TerminateFunctionHelp(inOnDestroy:false, alsoTerminateAutoComplete:true);

   // load all the matches into an array
   tag_get_all_matches(auto all_matches);
   cb_prepare_expand(p_active_form,0,TREE_ROOT_INDEX);
   VS_TAG_BROWSE_INFO cm;

   // get the current project and the project that the current file is in
   current_project := relative_project := "";
   if (_workspace_filename != "" && (codehelpFlags & VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT)) {
      current_project = _project_name;
      relative_project = "";
      if (_isEditorCtl()) {
         relative_project = _WorkspaceFindProjectWithFile(p_buf_name, _workspace_filename, true, true);
         if (relative_project == _project_name) relative_project="";
      }
   }

   // first get the matches that have seek positions
   for (i:=1; i<=n; ++i) {
      tag_init_tag_browse_info(cm);
      tag_get_detail2(VS_TAGDETAIL_match_start_seekpos, i, cm.seekpos);
      tag_get_detail2(VS_TAGDETAIL_match_start_linenum, i, cm.line_no);
      if (cm.seekpos < 0 || (cm.seekpos==0 && cm.line_no>1)) {
         continue;
      }

      tag_get_match_info(i, cm);
      caption = tag_tree_make_caption_fast(VS_TAGMATCH_match, i, true, true, false);
      parse cm.file_name with auto dest_file_name "\1" auto outer_file_name;
      key = caption:+"\t":+dest_file_name:+"\t":+cm.type_name:+"\t":+cm.line_no;
      been_there_done_that:[key] = true;
      key = caption:+"\t":+dest_file_name:+"\t":+cm.type_name:+"\t":+cm.line_no:+"\t":+cm.seekpos;
      if (been_there_done_that._indexin(key)) {
         continue;
      }

      // display file name relative to workspace dir to save space
      rel_file_name := (_workspace_filename != "")? _RelativeToWorkspace(dest_file_name) : dest_file_name;
      line_annotation := "";
      if (_isEditorCtl() && _file_eq(dest_file_name, p_buf_name)) {
         line_annotation = "(in file) ";
      }
      if ((current_project  != "" && _isFileInProject(_workspace_filename, current_project, dest_file_name)) ||
          (relative_project != "" && _isFileInProject(_workspace_filename, relative_project, dest_file_name))) {
         line_annotation = "(in project) ";
      }

      match_id = i;
      match_ids[m] = i;
      captions[m] = caption:+"\t":+rel_file_name:+"\t":+line_annotation:+cm.line_no;

      tagType := tag_get_type_id(cm.type_name);
      pic_member = tag_get_bitmap_for_type(tagType, cm.flags, auto pic_overlay=0);
      pictures[m] = pic_member;
      overlays[m] = pic_overlay;
      been_there_done_that:[key] = true;
      m++;
   }

   for (i=1; i<=n; ++i) {
      tag_init_tag_browse_info(cm);
      tag_get_detail2(VS_TAGDETAIL_match_start_seekpos, i, cm.seekpos);
      tag_get_detail2(VS_TAGDETAIL_match_start_linenum, i, cm.line_no);
      if (cm.seekpos > 0 || (cm.seekpos==0 && cm.line_no==1)) {
         continue;
      }
      tag_get_match_info(i, cm);
      //if (_QLoadTagsSupported(cm.filename)) {
      //   continue;
      //}
      caption = tag_tree_make_caption_fast(VS_TAGMATCH_match, i, true, true, false);
      parse cm.file_name with auto dest_file_name "\1" auto outer_file_name;
      if (cm.tag_database != "") {
         key = caption:+"\t":+dest_file_name:+"\t":+cm.type_name:+"\t":+cm.line_no:+"\t":+cm.tag_database;
         if (been_there_done_that._indexin(key)) {
            continue;
         }
      }
      key = caption:+"\t":+dest_file_name:+"\t":+cm.type_name:+"\t":+cm.line_no;
      if (been_there_done_that._indexin(key)) {
         continue;
      }

      // display file name relative to workspace dir to save space
      rel_file_name := (_workspace_filename != "")? _RelativeToWorkspace(dest_file_name) : dest_file_name;
      line_annotation := "";
      if ((current_project  != "" && _isFileInProject(_workspace_filename, current_project, dest_file_name)) ||
          (relative_project != "" && _isFileInProject(_workspace_filename, relative_project, dest_file_name))) {
         line_annotation = "(in project) ";
      }

      match_id = i;
      match_ids[m] = i;
      captions[m] = caption:+"\t":+rel_file_name:+"\t":+line_annotation:+cm.line_no;
      tagType := tag_get_type_id(cm.type_name);
      pic_member = tag_get_bitmap_for_type(tagType, cm.flags, auto pic_overlay=0);
      pictures[m] = pic_member;
      overlays[m] = pic_overlay;
      been_there_done_that:[key] = true;
      m++;
   }

   if (match_ids._length() == 0) {
      return BT_RECORD_NOT_FOUND_RC;
   }
   if (match_ids._length() == 1) {
      return 1;  // == match_ids[0]
   }
   if (match_ids._length() > 1) {
      orig_use_timers := _use_timers;
      _use_timers = 0;

      // If we are sorting to prefer project, definitions or declarations, 
      // don't enable sort buttons in the tree
      columnInfo := (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_WRAP)",":+
                    (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_FILENAME|TREE_BUTTON_IS_FILENAME)",":+
                    (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_NUMBERS);
      if (codehelpFlags & (VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION|VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION|VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT)) {
         columnInfo= (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP)",":+
                     (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_IS_FILENAME)",":+
                     (TREE_BUTTON_PUSHBUTTON);
      }

      match_id = select_tree(captions, match_ids, pictures, overlays, 
                             null, tag_select_callback, null, 
                             "Select Symbol", 
                             SL_COLWIDTH|SL_SIZABLE|SL_RESTORE_XY|SL_RESTORE_HEIGHT|SL_USE_OVERLAYS|SL_DEFAULTCALLBACK, 
                             "Name,File,Line,", 
                             columnInfo,
                             true, 
                             "Select Symbol dialog", 
                             "find_tag"
                            );

      kill_tagwin_delay_timer();
      kill_select_tag_timer();

      _use_timers = orig_use_timers;
      if (match_id == "" || match_id == COMMAND_CANCELLED_RC) {
         return COMMAND_CANCELLED_RC;
      }
   }

   // restore matches in case if they were destroyed
   if (tag_get_num_of_matches() != n) {
      tag_clear_matches();
      foreach (cm in all_matches) {
         tag_insert_match_browse_info(cm);
      }
   }

   // return the selected match ID
   return match_id;
}


////////////////////////////////////////////////////////////////////////////////
defeventtab _tagging_excludes_form;

void _tagging_excludes_form_save_settings()
{
   ctlexclude_pathlist.p_user = false;
}

bool _tagging_excludes_form_is_modified()
{
   return ctlexclude_pathlist.p_user;
}

bool _tagging_excludes_form_apply()
{
   def_tagging_excludes="";
   wid := p_window_id;
   p_window_id=ctlexclude_pathlist;
   save_pos(auto p);
   _lbtop();
   _lbup();
   while (!_lbdown()) {
      txt := strip(_lbget_text());
      if (def_tagging_excludes != "") {
         def_tagging_excludes :+= PATHSEP:+txt;
      } else {
         def_tagging_excludes=txt;
      }
   }
   restore_pos(p);
   p_window_id=wid;
   if (isEclipsePlugin()) {
      _eclipse_set_tagging_excludes(def_tagging_excludes);
      if (_message_box("Retag your workspace now?","SlickEdit Core",MB_YESNO|MB_ICONQUESTION) == IDYES) {
         _eclipse_retag();
      }
   }
   return true;
}

static void add_path(_str path)
{
   save_pos(auto p);
   _lbtop();
   typeless status=_lbsearch(path,_fpos_case);
   if (!status) {
      _lbselect_line();
      return;
   }
   restore_pos(p);
   _lbadd_item(path);
}

void ctlexclude_pathlist.on_create()
{
   _str excludes = def_tagging_excludes;
   for (;;) {
      parse excludes with auto cur (PARSE_PATHSEP_RE),'r' excludes;
      if (cur=="") break;
      add_path(cur);
   }

   _tagging_excludes_form_initial_alignment();
}

static void _tagging_excludes_form_initial_alignment()
{
   // make the buttons the same width so they don't look goofy
   ctlexclude_add_path.p_width = ctlexclude_delete.p_width = ctlexclude_up.p_width =
      ctlexclude_down.p_width = ctlexclude_add_component.p_width;
}

void _tagging_excludes_form.on_resize()
{
   padding := ctlexclude_pathlist.p_x;

   widthDiff := p_width - (ctlexclude_add_component.p_x_extent + padding);
   heightDiff := p_height - (ctlexclude_pathlist.p_height + 2 * padding);

   if (widthDiff) {
      ctlexclude_add_component.p_x += widthDiff;
      ctlexclude_add_path.p_x = ctlexclude_delete.p_x = ctlexclude_up.p_x =
         ctlexclude_down.p_x = ctlexclude_add_component.p_x;
      ctlexclude_pathlist.p_width += widthDiff;
   }

   if (heightDiff) {
      ctlexclude_pathlist.p_height += heightDiff;
   }
}

int validateComponent(_str name)
{
   if (_isWindows()) {
      // '\ / : ? " < > |' are invalid filename characters on windows
      if (pos('[?"<>\|]', name, 1, 'r')) {
         _message_box("Path component name must be a valid filename.");
         return(1);
      } 
      colIndex := pos(':', name, 1); 
      if (colIndex > 0 && colIndex + 1 < length(name) && pos(':', name, colIndex + 1)) {
         _message_box("Path component name must be a valid filename.");
         return(1);
      }
   }
   return 0;
}

void ctlexclude_add_path.lbutton_up()
{
   typeless result = _ChooseDirDialog("","","",CDN_PATH_MUST_EXIST);
   if(result=="") {
      return;
   }
   path := strip(result,'B','"');
   _maybe_append_filesep(path);
   wid := p_window_id;
   _control ctlexclude_pathlist;
   p_window_id=ctlexclude_pathlist;
   add_path(path);
   p_window_id=wid;
   ctlexclude_pathlist.p_user=true;
}

void ctlexclude_add_component.lbutton_up()
{
   typeless result=show("-modal _textbox_form",
               "Enter the partial path component",
               0,//Flags,
               "",//Tb width
               "",//help item
               "",//Buttons and captions
               "",//retrieve name
               "-e validateComponent Path Component:");
   if (result != "" && _param1 != null) {
      path := strip(_param1,'B','"');
      _maybe_append_filesep(path);
      _maybe_prepend(path,FILESEP);
      path=".*":+path:+".*";
      wid := p_window_id;
      _control ctlexclude_pathlist;
      p_window_id=ctlexclude_pathlist;
      add_path(path);
      p_window_id=wid;
      ctlexclude_pathlist.p_user=true;
   }
}

void ctlexclude_delete.lbutton_up()
{
   wid := p_window_id;
   p_window_id=ctlexclude_pathlist;
   if (_lbget_seltext() == "") {
      return;
   }
   save_pos(auto p);
   top();up();
   bool ff;
   for (ff=true;;ff=false) {
      typeless status=_lbfind_selected(ff);
      if (status) break;
      _lbdelete_item();_lbup();
   }
   restore_pos(p);
   _lbselect_line();
   p_window_id=wid;
   ctlexclude_pathlist.p_user=true;
}

void ctlexclude_up.lbutton_up()
{
   wid := p_window_id;
   p_window_id=ctlexclude_pathlist;
   _str item=_lbget_seltext();
   if (item == "") {
      return;
   }
   orig_linenum := p_line;
   _lbdelete_item();
   if (p_line==orig_linenum) {
      _lbup();
   }
   _lbup();
   _lbadd_item(item);
   _lbselect_line();
   p_window_id=wid;
   ctlexclude_pathlist.p_user=true;
}

void ctlexclude_down.lbutton_up()
{
   wid := p_window_id;
   p_window_id=ctlexclude_pathlist;
   _str item=_lbget_seltext();
   if (item == "") {
      return;
   }
   _lbdelete_item();
   _lbadd_item(item);
   _lbselect_line();
   p_window_id=wid;
   ctlexclude_pathlist.p_user=true;
}


////////////////////////////////////////////////////////////////////////////////
defeventtab _tag_progress_form;
bool cancelTagProgressFormGlobal = false;

void ctlCancel.on_create()
{
   cancelTagProgressFormGlobal = false;
}

void ctlCancel.lbutton_up()
{
   cancelTagProgressFormGlobal = true;
}

bool getCancelTagProgressFormGlobal() {
   return cancelTagProgressFormGlobal;
}

int tagProgressCallback(int percentage, bool breakIfEditorVisible = false, typeless userData = "")
{
   // this is only currently used if the mdi window is hidden
   if(breakIfEditorVisible && _mdi.p_visible) {
      return 0;
   }

   cancelPressed := 0;

   // find the control
   int wid = _find_formobj("_tag_progress_form", "N");
   if(wid) {
      ctl_progress := wid._find_control("ctl_progress");
      if (!ctl_progress) ctl_progress = wid._find_control("ctlProgress");
      if (ctl_progress > 0) {
         ctl_progress.p_max = 100;
         ctl_progress.p_value = percentage;
         wid.refresh("W");
      }

      // handle messages
      int orig_use_timers=_use_timers;
      int orig_def_actapp=def_actapp;
      def_actapp=0;
      _use_timers=0;
      process_events(cancelTagProgressFormGlobal);
      _use_timers=orig_use_timers;
      def_actapp=orig_def_actapp;
      if(cancelTagProgressFormGlobal) {
         cancelPressed = 1;
      }
   }

   return cancelPressed;
}

/**
 * Build or rebuild (retag) the tagfile for each workspace that is specified. 
 *  
 * This command is invoked by the <code>vsmktags</code> utility. 
 * <pre> 
  *    Usage: vsmktags [Options] Workspace1 [Workspace2] ...
 * </pre>
 *  
 * @param arglist    argument list, usually a list of workspaces or tag files. 
 *                   <ul> 
 *                   <li><b>Workspace(n)</b>     Name of workspace or path to tag file to rebuild.
 *                                               Multiple workspaces can be specified.</li> 
 *                   <li><b>-retag</b>           Retag all files.  Defaults to incremental retagging.</li> 
 *                   <li><b>-refs=[on/off]</b>   Enable/disable references.  Defaults to no change.</li> 
 *                   <li><b>-thread=[on/off]</b> Enable/disable threaded tagging.  Default is on.</li> 
 *                   <li><b>-sc [configdir]</b>  SlickEdit configuration dir.</li> 
 *                   <li><b>-autotag=[lang]</b>  Launch the autotag dialog to build compiler tag files.</li>
 *                   </ul>
 *  
 * @example 
   Build tag file for all files in workspace.
 * <pre> 
 *    vsmktags workspace.vpw
 * </pre>
 *  
 * @return Returns 0 if successful.
 *
 * @see make_tags
 * @see gui_make_tags
 * @see autotag
 *
 * @categories Tagging_Functions
 */
_command int build_workspace_tagfiles(_str arglist='') name_info(FILE_ARG'*,'VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Tagging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // save original configuration settings
   orig_workspace_filename                        := _workspace_filename;
   orig_background_tagging_timeout                := def_background_tagging_timeout;
   orig_background_tagging_idle                   := def_background_tagging_idle;
   orig_background_tagging_threads                := def_background_tagging_threads;
   orig_background_reader_threads                 := def_background_reader_threads;
   orig_background_database_threads               := def_background_database_threads;
   orig_background_tagging_maximum_jobs           := def_background_tagging_maximum_jobs;
   orig_background_tagging_maximum_kbytes         := def_background_tagging_max_ksize;
   orig_background_tagging_minimize_write_locking := def_background_tagging_minimize_write_locking;
   orig_autotag_flags2                            := def_autotag_flags2;
   orig_actapp                                    := def_actapp;

   // fine-tune settings for top performance
   def_background_tagging_timeout = 600000;     // 10 minutes
   def_background_tagging_idle = 25;            // 10 microsections
   def_background_tagging_threads = 8;          // pedal to the metal
   def_background_reader_threads = 2;           // two parallel readers
   def_background_database_threads = 1;         // dedicated database thread
   def_background_tagging_maximum_jobs = 5000;
   def_background_tagging_max_ksize = 32000;
   def_background_tagging_minimize_write_locking=false;

   // make sure that we don't automatically rebuild any workspaces
   def_actapp = 0;
   def_autotag_flags2 = 0;
   def_autotag_flags2 |= AUTOTAG_BUFFERS_NO_THREADS;
   def_autotag_flags2 |= AUTOTAG_FILES_NO_THREADS;
   def_autotag_flags2 |= AUTOTAG_WORKSPACE_NO_THREADS;
   def_autotag_flags2 |= AUTOTAG_LANGUAGE_NO_THREADS;
   def_autotag_flags2 |= AUTOTAG_SILENT_THREADS;
   def_autotag_flags2 |= AUTOTAG_WORKSPACE_NO_OPEN;
   def_autotag_flags2 |= AUTOTAG_WORKSPACE_NO_ACTIVATE;

   // default tagging settings
   status := 0;
   _str origWorkspaceList[] = null;
   int  origWorkspaceRefs[] = null;
   runAutoTag := false;
   retagAll := false;
   useThread := true;
   refsAll := -1;
   autotagLang := "";

   // parse the options
   for (;;) {
      _str nextarg = parse_file(arglist);
      if (nextarg == "") break;

      if (_first_char(nextarg) == '-') {
         // -retag - full retag
         if (strieq(nextarg, "-retag")) {
            retagAll = true;

         // -refs=[on/off] - tag with refereces
         } else if (strieq(nextarg, "-refs")) {
            refsAll = 1;
         } else if (strieq(nextarg, "-refs=on")) {
            refsAll = 1;
         } else if (strieq(nextarg, "-refs=off")) {
            refsAll = 0;

         // -thread=[on/off] - tag with threads
         } else if (strieq(nextarg, "-thread")) {
            useThread = true;
         } else if (strieq(nextarg, "-thread=on")) {
            useThread = true;
         } else if (strieq(nextarg, "-thread=off")) {
            useThread = false;

         // -autotag - run autotag dialog
         } else if (strieq(substr(nextarg,1,8), "-autotag")) {
            parse nextarg with nextarg '=' autotagLang;
            runAutoTag = true;

         // unsupported argument
         } else {
            _message_box("The argument '" nextarg "' is not supported.");
            return -1;
         }
      } else {

         // must be a workspace name
         switch (lowcase(_get_extension(nextarg, true))) {
         case WORKSPACE_FILE_EXT:
         case PRJ_FILE_EXT:
            break;
         case TAG_FILE_EXT:
            break;
         case VCPP_PROJECT_WORKSPACE_EXT:
         case TORNADO_WORKSPACE_EXT:
         case VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT:
         case XCODE_PROJECT_EXT:
         case XCODE_PROJECT_LONG_BUNDLE_EXT:
         case XCODE_PROJECT_SHORT_BUNDLE_EXT:
         case VISUAL_STUDIO_SOLUTION_EXT:
         case JBUILDER_PROJECT_EXT:
         case MACROMEDIA_FLASH_PROJECT_EXT:
         case XCODE_PROJECT_EXT:
            break;
         default:
            // unsupported filename
            _message_box("The file '" nextarg "' does not appear to be a SlickEdit workspace or tag file.");
            return -1;
         }

         // add it to the list of tag files to rebuild
         origWorkspaceList :+= absolute(nextarg);
         origWorkspaceRefs :+= refsAll;
      }
   }

   // construct parallel arrays of workspace names and whether or not they
   // shoudl be built with references.
   _str workspaceList[] = null;
   int  workspaceRefs[] = null;

   // did they want to run autotag?
   if (runAutoTag) {
      workspaceList :+= "Auto-tag";
      workspaceRefs :+= 0;
   }

   // expand the workspace list (in case there are wildcards)
   // NOTE: there is nothing done here to prevent duplicates
   for (i := 0; i < origWorkspaceList._length(); i++) {
      if (!iswildcard(origWorkspaceList[i]) || file_exists(origWorkspaceList[i])) {
         // not a wildcard so just add it
         workspaceList :+= origWorkspaceList[i];
         workspaceRefs :+= origWorkspaceRefs[i];
         continue;
      }

      // is wildcard so expand it
      workspace := file_match(_maybe_quote_filename(origWorkspaceList[i]), 1);
      for (;;) {
         if (workspace == "") break;

         switch (lowcase(_get_extension(workspace, true))) {
         case WORKSPACE_FILE_EXT:
         case PRJ_FILE_EXT:
            // add to list
            workspaceList :+= workspace;
            workspaceRefs :+= origWorkspaceRefs[i];
            break;
         case TAG_FILE_EXT:
            // add to list
            workspaceList :+= workspace;
            workspaceRefs :+= origWorkspaceRefs[i];
            break;
         case VCPP_PROJECT_WORKSPACE_EXT:
         case TORNADO_WORKSPACE_EXT:
         case VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT:
         case XCODE_PROJECT_EXT:
         case VISUAL_STUDIO_SOLUTION_EXT:
         case JBUILDER_PROJECT_EXT:
         case MACROMEDIA_FLASH_PROJECT_EXT:
         case XCODE_PROJECT_EXT:
            // add to list
            workspaceList :+= workspace;
            workspaceRefs :+= origWorkspaceRefs[i];
            break;
         default:
            break;
         }

         // move next
         workspace = file_match(_maybe_quote_filename(origWorkspaceList[i]), 0);
      }
   }

   // show the form
   _nocheck _control ctlLogTree;
   _nocheck _control ctlProgress;
   wid := show("-xy -hidden _tag_progress_form");
   wid.p_caption = "Build Workspace Tag Files";
   wid.ctlProgress.p_visible = true;
   wid.p_visible = true;

   // put the list of workspaces into the form
   for (i = 0; i < workspaceList._length(); i++) {
      nodeIndex := wid.ctlLogTree._TreeAddItem(TREE_ROOT_INDEX, workspaceList[i], TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_EXPANDED);
      wid.ctlLogTree._TreeSetCheckable(nodeIndex, 1, 1);
      wid.ctlLogTree._TreeSetCheckState(nodeIndex, TCB_UNCHECKED);
   }
   //wid.ctlLogTree._TreeRefresh();
   wid.refresh("W");
   node := wid.ctlLogTree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);

   // tag each workspace
   for (i = 0; i < workspaceList._length(); i++) {
      wid.ctlLogTree._TreeSetCurIndex(node);
      wid.ctlLogTree._TreeSetCheckState(node, TCB_PARTIALLYCHECKED);
      wid.ctlLogTree._TreeRefresh();
      wid.ctlProgress.p_value = 0;

      // check if they just gave us a plain tag file
      workspace := workspaceList[i];
      isTagFile := (_file_eq(_get_extension(workspace, true), TAG_FILE_EXT));
      tagfilename := _strip_filename(workspace, "E") :+ PRJ_TAG_FILE_EXT;
      retag := retagAll;
      refs := false;
      flags := 0;

      // open the workspace (this will cause _MaybeRetagWorkspace to be run)
      if (!isTagFile && workspace != "Auto-tag") {
         status = workspace_open(workspace, "", "", true, false);
         if (status) break;
      }

      // determine if tag files should be built with references
      refsAllForWorkspace := refsAll;
      if (i < workspaceRefs._length()) {
         refsAllForWorkspace = workspaceRefs[i];
      }

      // see if the tag file flags match
      if (workspace != "Auto-tag") {
         status = tag_read_db(tagfilename);
         if (status < 0 || tag_current_version() < VS_TAG_LATEST_VERSION) {
            // error or out of date so must retag
            retag = true;

            // set refs flag
            switch (refsAllForWorkspace) {
            case 0:
               // noop
               break;
            case 1:
               flags = flags | VS_DBFLAG_occurrences;
               break;
            }
         } else {
            // get the flags
            flags = tag_get_db_flags();
            refs = (flags & VS_DBFLAG_occurrences) != 0;

            // check for references if necessary
            if (refsAllForWorkspace != -1) {
               // if refs were not there but were requested to be on, rebuild is required
               if (!refs && refsAllForWorkspace == 1) {
                  retag = true;
                  refs = true;

                  tag_open_db(tagfilename);
                  flags = flags | VS_DBFLAG_occurrences;
                  tag_set_db_flags(flags);

                  // if refs were there but were requested to be off, disable them
               } else if (refs && refsAllForWorkspace == 0) {
                  // TODO: this can be done quicker than rebuild
                  retag = true;
                  refs = false;

                  tag_open_db(tagfilename);
                  flags = flags & ~VS_DBFLAG_occurrences;
                  tag_set_db_flags(flags);
               }
            }
         }

         // if we are building using threads, release the write lock
         if (useThread) {
            tag_close_db(tagfilename, true);
            tag_unlock_db(tagfilename);
         }
      }

      // retag the workspace if necessary
      wid.ctlProgress.p_value = 0;
      if (isTagFile) {
         status = RetagFilesInTagFile(tagfilename,
                                      retag,                               // rebuild from scratch
                                      (refsAllForWorkspace==1),            // tag occurrences
                                      true,                                // remove missing files
                                      true,                                // remove without prompting
                                      useThread,                           // use threads
                                      true,                                // quiet
                                      true,                                // check all file dates
                                      !useThread,                          // allow cancellation
                                      true                                 // keep without prompting
                                      );
         if (status < 0) {
            _message_box("Error rebuilding tag file: "get_message(status, tagfilename));
         }
      } else if (workspace == "Auto-tag") {
         status = autotag(autotagLang);
      } else {
         status = _workspace_update_files_retag(retag,                     // rebuild from scratch
                                                true,                      // remove obsolete files
                                                true,                      // remove without prompting
                                                true,                      // quiet
                                                (refsAllForWorkspace==1),  // tag occurrences
                                                true,                      // check all file dates
                                                useThread,                 // use threads
                                                !useThread,                // allow cancellation
                                                true                       // keep without prompting
                                                );
         if (status < 0) {
            _message_box("Error retagging workspace: "get_message(status, tagfilename));
         }
      }

      wasCancelled := false;
      if (useThread) {
         // finish building the tag file on a thread.
         progress  := 0;
         iteration := 0;
         totalJobs := tag_get_num_async_tagging_jobs('U');
         tag_get_async_tag_file_builds(auto asyncTagDatabaseArray);
         numAsyncBuildsRunning := asyncTagDatabaseArray._length();
         for (j:=0; j<numAsyncBuildsRunning; j++) {
            tag_close_db(asyncTagDatabaseArray[j], true);
            if (!isTagFile && wid && _iswindow_valid(wid)) {
               nodeIndex := wid.ctlLogTree._TreeAddItem(node, asyncTagDatabaseArray[j], TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_CHILD);
               wid.ctlLogTree._TreeSetCheckable(nodeIndex, 1, 1);
               wid.ctlLogTree._TreeSetCheckState(nodeIndex, TCB_UNCHECKED);
            }
         }
         if (wid && _iswindow_valid(wid)) {
            wid.ctlLogTree._TreeSetCurIndex(node);
         }

         while (tag_get_num_async_tagging_jobs('U') > 0 || numAsyncBuildsRunning > 0) {
            if (_IsKeyPending()) {
               wasCancelled = true;
               break;
            }
            status = _ReportAsyncTaggingResults(true, wid);
            if (status < 0) {
               wasCancelled = true;
               break;
            }
            remainingJobs := tag_get_num_async_tagging_jobs('U');
            if (remainingJobs <= 0 && numAsyncBuildsRunning <= 0) {
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
                  delay(def_background_tagging_idle);
               } else {
                  delay(def_background_tagging_idle intdiv 10);
               }
               // now re-acquire the same number of read locks we had before
               while (lockCount > 0) {
                  tag_lock_context();
                  --lockCount;
               }
            }
            remainingJobs = tag_get_num_async_tagging_jobs('U');
            if (remainingJobs > totalJobs) totalJobs = remainingJobs;
            last_progress := progress;
            progress = ((totalJobs - remainingJobs)*100 intdiv totalJobs);
            if ((++iteration < 100 && totalJobs < 100) && progress > 10) progress = iteration intdiv 10;
            if (progress < last_progress) progress = last_progress;
            if (wid && _iswindow_valid(wid) && tagProgressCallback(progress, false)) {
               wasCancelled = true;
               break;
            }

            // check if jobs are complete
            numAsyncBuildsRunning = 0;
            tag_get_async_tag_file_builds(asyncTagDatabaseArray);
            for (j=0; j<asyncTagDatabaseArray._length(); j++) {
               isJobRunning := false;
               async_progress := 0;
               tag_check_async_tag_file_build(asyncTagDatabaseArray[j], isJobRunning, async_progress);
               if (isJobRunning) {
                  tag_close_db(asyncTagDatabaseArray[j], true);
                  ++numAsyncBuildsRunning;
               } else if (wid && _iswindow_valid(wid)) {
                  nodeIndex := wid.ctlLogTree._TreeSearch(node, asyncTagDatabaseArray[j]);
                  if (nodeIndex > 0) {
                     wid.ctlLogTree._TreeSetCheckState(nodeIndex, TCB_CHECKED);
                  }
               }
            }
         }
      }

      // close the tag file
      if (workspace != "Auto-tag") {
         tag_close_db(tagfilename, false);
      }

      // close the workspace
      if (!isTagFile && workspace != "Auto-tag") {
         status = workspace_close();
         if (status) break;
      }

      // check to see if cancel was pressed
      if (wasCancelled || getCancelTagProgressFormGlobal()) {
         break;
      }

      // workspace complete so show the checkmark(s)
      wid.ctlLogTree._TreeSetCheckState(node, TCB_CHECKED);
      childNode := wid.ctlLogTree._TreeGetFirstChildIndex(node);
      while (childNode > 0) {
         wid.ctlLogTree._TreeSetCheckState(childNode, TCB_CHECKED);
         childNode = wid.ctlLogTree._TreeGetNextSiblingIndex(childNode);
      }
      wid.ctlLogTree._TreeRefresh();
      node = wid.ctlLogTree._TreeGetNextSiblingIndex(node);
      if (node <= 0) break;
   }

   //_message_box("finished");
   if (_iswindow_valid(wid)) {
      wid._delete_window();
   }

   // restore settings
   def_background_tagging_timeout                = orig_background_tagging_timeout;
   def_background_tagging_idle                   = orig_background_tagging_idle;
   def_background_tagging_threads                = orig_background_tagging_threads;
   def_background_reader_threads                 = orig_background_reader_threads;
   def_background_database_threads               = orig_background_database_threads;
   def_background_tagging_maximum_jobs           = orig_background_tagging_maximum_jobs;
   def_background_tagging_max_ksize              = orig_background_tagging_maximum_kbytes;
   def_background_tagging_minimize_write_locking = orig_background_tagging_minimize_write_locking;
   def_autotag_flags2                            = orig_autotag_flags2;
   def_actapp                                    = orig_actapp;

   // restore original workspace
   if (orig_workspace_filename != "") {
      workspace_open(orig_workspace_filename, "", "", false, false);
   }

   // that's all folks
   return status;
}


//////////////////////////////////////////////////////////////////////////////
// Event table for generic tagging "Cancel" button.
//

static _str gdisabled_wid_list="";
static bool gbuild_cancel=false;
defeventtab _buildtag_form;
_buildcancel.lbutton_up()
{
   gbuild_cancel=true;
   _enable_non_modal_forms(true,0,gdisabled_wid_list);
   gdisabled_wid_list="";
   p_active_form._delete_window();
}
void _buildtag_form.on_close()
{
   if (_buildcancel.p_visible) {
      _buildcancel.call_event(_buildcancel,LBUTTON_UP,'W');
   }
}

_buildcancel.on_create(_str title=null,_str LabelText=null,bool allowCancel=true,bool showGuage=false)
{
   if (title!=null) {
      p_active_form.p_caption=title;
   }
   if (LabelText!=null) {
      ctllabel1.p_caption=LabelText;
   }
   gbuild_cancel=false;
   if (!allowCancel) {
      _buildcancel.p_visible=false;
   }
   if (!showGuage) {
      ctl_progress.p_visible=false;
   }
   if (allowCancel && !showGuage) {
      _buildcancel.p_x = (p_active_form.p_width-_buildcancel.p_width) intdiv 2;
   }
   if (!allowCancel && showGuage) {
      ctl_progress.p_width += (ctl_progress.p_x - _buildcancel.p_x);
      ctl_progress.p_x = _buildcancel.p_x;
      ctl_progress.p_max=ctl_progress.p_client_width;
   }
   ctllabel2.p_user = 0;
   ctl_progress.p_user = 0;
}
_buildcancel.on_destroy()
{
   gbuild_cancel=true;
   if (gdisabled_wid_list!="") {
      _enable_non_modal_forms(true,0,gdisabled_wid_list);
      gdisabled_wid_list="";
   }
}

void cancel_form_set_gauge_visible(bool visible)
{
   ctl_progress.p_width += (ctl_progress.p_x - _buildcancel.p_x);
   ctl_progress.p_x = _buildcancel.p_x;
   ctl_progress.p_max=ctl_progress.p_client_width;
   ctl_progress.p_visible=visible;
}

/**
 * Check if the cancel button on the cancel form has been hit.
 * 
 * @param checkFrequency    frequency (in ms) to check for cancellation
 * 
 * @return Return 'true' if cancelled, 'false' otherwise.
 *  
 * @see show_cancel_form
 * @see cancel_form_progress 
 * @see cancel_form_set_labels 
 * @see close_cancel_form 
 *  
 * @categories Forms
 */
bool cancel_form_cancelled(int checkFrequency=250)
{
   // check when this function was called 
   if (checkFrequency > 0) {
      static typeless last_time;
      typeless this_time = _time('b');
      if ( isnumber(last_time) && this_time-last_time < checkFrequency ) {
         return false;
      }
      last_time = this_time;
   }

   // prepare to safely call process events
   int orig_use_timers=_use_timers;
   int orig_def_actapp=def_actapp;
   def_actapp=0;
   _use_timers=0;
   orig_view_id := p_window_id;
   activate_window(VSWID_HIDDEN);
   int orig_hidden_buf_id=p_buf_id;
   typeless orig_hidden_pos;
   save_pos(orig_hidden_pos);

   // process mouse clicks, redraws, etc
   process_events(gbuild_cancel);

   // restore everything after calling process events
   activate_window(VSWID_HIDDEN);
   p_buf_id=orig_hidden_buf_id;
   restore_pos(orig_hidden_pos);
   if (_iswindow_valid(orig_view_id)) {
      activate_window(orig_view_id);
   }
   _use_timers=orig_use_timers;
   def_actapp=orig_def_actapp;
   return gbuild_cancel;
}
/**
 * Close the given cancel form instance.
 * 
 * @param buildform_wid    cancel form window ID (from {@link show_cancel_form}
 *  
 * @see show_cancel_form
 * @categories Forms
 */
void close_cancel_form(int buildform_wid)
{
   if (!buildform_wid) return;
   if (!gbuild_cancel) {
      _enable_non_modal_forms(true,0,gdisabled_wid_list);
      // workaround for disabled parent window
      int parent_form_wid = cancel_form_get_parent();
      restore_parent_disabled := false;
      if (parent_form_wid && !parent_form_wid.p_enabled) {
         parent_form_wid.p_enabled = true;
         restore_parent_disabled = false;
      }
      buildform_wid._delete_window();
      if (restore_parent_disabled) {
         parent_form_wid.p_enabled = false;
      }
   }
}
struct CANCEL_PARENT_INFO {
   _str name;
   int wid;
}gCancelParent;

/**
 * Set the parent for the cancel_form (see <B>show_cancel_form</B>
 *
 * When done, you can call this function with 0, but it is not necessary because of
 * the validation that is performed.
 *
 * @param ParentWid Window to set as parent
 */
void cancel_form_set_parent(int ParentWid)
{
   if ( _iswindow_valid(ParentWid) ) {
      gCancelParent.name=ParentWid.p_name;
      gCancelParent.wid=ParentWid;
   }else{
      gCancelParent.name="";
      gCancelParent.wid=0;
   }
}
/**
 * @return the current parent for the cancel_form (see <B>show_cancel_form</B>
 * If the last one set is invalid, it returns the current window id
 */
static int cancel_form_get_parent()
{
   // First be sure the window id is still valid
   if ( _iswindow_valid(gCancelParent.wid) ) {
      // Now check to see if it is still the same dialog
      if ( gCancelParent.name==gCancelParent.wid.p_name ) {
         return(gCancelParent.wid);
      }
   }
   // If the parent was invalid, we don't want to use it again
   gCancelParent.wid=0;
   gCancelParent.name="";
   return(p_window_id);
}

/**
 * Show the progress / cancel form.
 * 
 * @param title         Cancel form title
 * @param LabelText     initial label text (optional)
 * @param allowCancel   allow cancellation
 * @param showGuage     show progress bar
 * 
 * @return Returns the window ID of the form. 
 *  
 * @example 
 * <pre>
 *    progressWid := show_cancel_form("Percent complete", LabelText:null, allowCancel:true, showGuage:true);
 *    len := 10000000;
 *    for (i:=0; i<len; i++) {
 *        if (cancel_form_progress(progressWid, i, len)) {
 *           cancel_form_set_labels(progressWid, ((double)i/100000) :+" %");
 *           if (cancel_form_cancelled(100)) {
 *               break;
 *           }
 *        }
 *    }
 *    if (progressWid) {
 *       close_cancel_form(progressWid);
 *    }
 * </pre> 
 *  
 * @see show_cancel_form_on_top 
 * @see cancel_form_progress 
 * @see cancel_form_cancelled 
 * @see cancel_form_set_labels 
 * @see close_cancel_form
 * 
 * @categories Forms
 */
int show_cancel_form(_str title,_str LabelText=null,bool allowCancel=true,bool showGuage=false)
{
   gbuild_cancel=false;
   int wid = cancel_form_get_parent().show("_buildtag_form",title,LabelText,allowCancel,showGuage);
   gdisabled_wid_list=_enable_non_modal_forms(false,wid);
   return(wid);
}
/**
 * Show the cancel form, making sure it is on top of all other 
 * active forms. 
 * 
 * @param title         Cancel form title
 * @param LabelText     initial label text (optional)
 * @param allowCancel   allow cancellation
 * @param showGuage     show progress bar
 * 
 * @return Returns the window ID of the form. 
 *  
 * @see show_cancel_form
 * @see cancel_form_progress 
 * @see cancel_form_cancelled 
 * @see cancel_form_set_labels 
 * @see close_cancel_form 
 *  
 * @categories Forms
 */
int show_cancel_form_on_top(_str title,_str LabelText=null,bool allowCancel=true,bool showGuage=false)
{
   gbuild_cancel=false;
   int wid = cancel_form_get_parent().show("-mdi _buildtag_form",title,LabelText,allowCancel,showGuage);
   gdisabled_wid_list=_enable_non_modal_forms(false,wid);
   return(wid);
}
/**
 * Set the labels for the cancel form.
 * 
 * @param buildform_wid    cancel form window ID (from {@link show_cancel_form}
 * @param LabelText1       text for first label
 * @param LabelText2       text for second label 
 *  
 * @see show_cancel_form
 * @see cancel_form_progress 
 * @see cancel_form_cancelled 
 * @see close_cancel_form 
 *  
 * @categories Forms
 */
void cancel_form_set_labels(int buildform_wid,_str LabelText1="",_str LabelText2="")
{
   if (!buildform_wid) return;
   ctllabel1 := buildform_wid._find_control("ctllabel1");
   if (ctllabel1 > 0 && LabelText1 != null) {
      ctllabel1.p_caption=LabelText1;
   }

   ctllabel2 := buildform_wid._find_control("ctllabel2");
   if (ctllabel2 > 0 && LabelText2!=null) {
      ctllabel2.p_caption=LabelText2;
   }
}
void cancel_form_check_item(int buildform_wid, _str fileName, int progress=100)
{
   if (!buildform_wid) return;
   ctltree := buildform_wid._find_control("ctlLogTree");
   if (ctltree <= 0) return;
   currentIndex := ctltree._TreeCurIndex();
   if (currentIndex <= 0) currentIndex = TREE_ROOT_INDEX;
   nodeIndex := ctltree._TreeSearch(currentIndex, fileName, 'i', null, 0);
   if (nodeIndex <= 0) return;
   checkState := ctltree._TreeGetCheckState(nodeIndex);
   if (progress >= 100 && checkState != TCB_CHECKED) {
      ctltree._TreeSetCheckState(nodeIndex, TCB_CHECKED);
      ctltree._TreeRefresh();
   } else if (checkState == TCB_UNCHECKED) {
      ctltree._TreeSetCheckState(nodeIndex, TCB_PARTIALLYCHECKED);
      ctltree._TreeRefresh();
   }
}
/**
 * Update the progress bar for the cancel form.
 * 
 * @param buildform_wid    cancel form window ID (from {@link show_cancel_form}
 * @param n                number in range of [0 .. total]
 * @param total            scale progress based on this total number of items
 * 
 * @return Returns 'true' if the progress needle moved, 'false' otherwise. 
 *         This is a convenient way to limit how frequently other actions are done.
 *  
 * @see show_cancel_form
 * @see cancel_form_cancelled 
 * @see cancel_form_set_labels 
 * @see close_cancel_form 
 *  
 * @categories Forms
 */
bool cancel_form_progress(int buildform_wid, int n, int total)
{
   if (!buildform_wid) return false;
   if (total > 0) {
      ctllabel2 := buildform_wid._find_control("ctllabel2");
      ctl_progress := buildform_wid._find_control("ctl_progress");
      if (!ctl_progress) ctl_progress = buildform_wid._find_control("ctlProgress");
      pixel_width := ctl_progress.p_max;
      if (total > 200000) {
         total = total intdiv 1000;
         n = n intdiv 1000;
      }
      new_value := (n*pixel_width intdiv total);
      ctl_progress.p_user = total;
      ctllabel2.p_user = n;
      if (ctl_progress.p_value != new_value) {
         ctl_progress.p_value = new_value;
         ctl_progress.refresh('w');
         return true;
      }
      return(false);
   }
   return(false);
}
int cancel_form_max_label2_width(int buildform_wid)
{
   ctllabel1 := buildform_wid._find_control("ctllabel1");
   border_x := (ctllabel1 > 0)? ctllabel1.p_x : 0;
   return (_dx2lx(SM_TWIP,buildform_wid.p_client_width)-border_x*2);
}
int cancel_form_text_width(int buildform_wid, _str msg)
{
   ctllabel1 := buildform_wid._find_control("ctllabel1");
   if (ctllabel1 > 0) {
      return(ctllabel1._text_width(msg));
   }
   return length(msg);
}
/**
 * @return 
 * Return the form window ID for the current active progress form. 
 * Return 0 if there is no active cancel form. 
 *  
 * @categories Forms
 */
int cancel_form_wid()
{
   static int last_wid;
   wid := 0;
   if (_iswindow_valid(last_wid) &&
       last_wid.p_object==OI_FORM &&
       !last_wid.p_edit &&
       last_wid.p_name=="_buildtag_form"){
      wid=last_wid;
   }else{
      wid=_find_formobj("_buildtag_form",'N');
      last_wid=wid;
   }
   return(wid);
}
/**
 * This function is used to update the progress bar as a
 * single file is parsed.  This is used primarily for large
 * files, such as JAR files or .NET DLL's.
 */
int cancel_form_update_progress2(_str LabelText2, int n, int total)
{
   buildform_wid := cancel_form_wid();
   if (buildform_wid <= 0) {
      return 0;
   }

   buildform_cancelled := cancel_form_cancelled();
   if (buildform_cancelled) {
      return COMMAND_CANCELLED_RC;
   }

   int width=cancel_form_max_label2_width(buildform_wid);
   LabelText2=buildform_wid._ShrinkFilename(LabelText2,width);
   cancel_form_set_labels(buildform_wid,null,LabelText2);

   _control ctllabel2;
   int base_n=buildform_wid.ctllabel2.p_user;
   int base_total=buildform_wid.ctl_progress.p_user;
   int max_n=buildform_wid.ctl_progress.p_max;
   if (base_n == null || base_total == null || !isuinteger(base_n) || !isuinteger(base_total)) {
      return 1;
   }

   int total_total = total * base_total;
   int total_n     = total * base_n + n;

   if (total_total > 0) {
      buildform_wid.ctl_progress.p_value = (total_n*max_n) intdiv total_total;
   }

   return 1;
}

