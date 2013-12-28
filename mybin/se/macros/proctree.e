////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50350 $
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
#include "xml.sh"
#require "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "cbrowser.e"
#import "context.e"
#import "cua.e"
#import "cutil.e"
#import "debug.e"
#import "debuggui.e"
#import "diff.e"
#import "eclipse.e"
#import "files.e"
#import "jrefactor.e"
#import "listproc.e"
#import "main.e"
#import "picture.e"
#import "pushtag.e"
#import "quickrefactor.e"
#import "recmacro.e"
#import "refactor.e"
#import "seldisp.e"
#import "sellist.e"
#import "seltree.e"
#import "stdprocs.e"
#import "stdcmds.e"
#import "tagform.e"
#import "tagrefs.e"
#import "tags.e"
#import "tagwin.e"
#import "tbfind.e"
#import "toolbar.e"
#import "treeview.e"
#import "tbxmloutline.e"
#import "util.e"
#endregion

using se.lang.api.LanguageSettings;

defeventtab _tbproctree_form;

_tbproctree_form.'F12'()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   } else if (def_keys == 'eclipse-keys') {
      activate_editor();
   }
}

_tbproctree_form.'C-M'()
{
   if (isEclipsePlugin()) {
      eclipse_maximize_part();
   }
}

//Trying to keep these together since we cant tag'em
#define PROCTREE_TB_FORM_NAME_STRING '_tbproctree_form'
#define PROC_TREE_NAME '_proc_tree'

//////////////////////////////////////////////////////////////////////////////
// Timer used for delaying updates after change-selected events,
// allowing you to quickly scroll through the items in the proc-tree
// It is safer for this to global instead of static.
//
int gProcTreeFocusTimerId = -1;

// Caching.
static int gLastTreeWID = 0;

// Proc tree container forn name.
static _str gProcTreeContainerFormName = PROCTREE_TB_FORM_NAME_STRING;

// List of proc trees.
struct PROCTREEASSOCIATIONINFO {
   int procTree; // proc tree window ID
   int bufID; // associated buffer ID
};
static PROCTREEASSOCIATIONINFO gProcTreeWIDList[];


//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (before defload).  Used to
// initialize the timer variable and window IDs.
//
definit()
{
   // IF editor is initalizing from invocation
   if (arg(1)!='L') {
      gProcTreeFocusTimerId=-1;
   }
   gLastTreeWID = 0;
   gProcTreeContainerFormName = PROCTREE_TB_FORM_NAME_STRING;
   gProcTreeWIDList._makeempty();
}

/**
 * Get the proc tree WID. This normally comes from the Project toolbar
 * but can also come from the Eclipse plugin proc tree.
 *
 * @return proc tree
 */
static int getProcTreeForm()
{
   int formwid = _find_formobj(gProcTreeContainerFormName,'N');

   // This is normally for the Eclipse plugin... where the proc tree
   // form contains another form (from the resource template).
   if (formwid && formwid.p_child && formwid.p_child.p_object == OI_FORM) {
      formwid = formwid.p_child;
   }
   return(formwid);
}

static int proctree_file_depth()
{
   if ((def_proc_tree_options & PROC_TREE_NO_BUFFERS) || isEclipsePlugin()) {
      return 0;
   }
   return 1;
}
static int proctree_symbol_depth()
{
   if ((def_proc_tree_options & PROC_TREE_NO_BUFFERS) || isEclipsePlugin()) {
      return 1;
   }
   return 2;
}

static boolean IsSpecialFile(_str a)
{
   a=strip(a,'b','"');
   return(a=='' ||
          a=='.process' ||
          substr(a,1,7)=="List of" ||
          substr(a,1,12)=="Directory of");
}

static int FindNode(_str Caption,int bufid)
{
   if ((def_proc_tree_options & PROC_TREE_NO_BUFFERS)|| isEclipsePlugin()) {
      if (_TreeCurIndex() < 0) {
         _TreeSetCurIndex(TREE_ROOT_INDEX);
      }
      if (bufid==_mdi.p_child.p_buf_id) {
         return TREE_ROOT_INDEX;
      }
      return -1;
   }
   Caption=strip(Caption,'B','"');
   return(_TreeSearch(TREE_ROOT_INDEX,Caption,_fpos_case,bufid));
}

static void StoreSortOptions(_str Path,int BufferOptions)
{
   int OptionsTable:[];
   OptionsTable=p_user;
   int temp;
   temp=BufferOptions;
   temp&=~(PROC_TREE_AUTO_EXPAND|PROC_TREE_ONLY_TAGGABLE);
   Path=strip(Path,'B','"');
   OptionsTable:[Path]=temp;
   p_user=OptionsTable;
}

static int GetOptions(_str Path)
{
   Path=strip(Path,'B','"');
   int OptionsTable:[];
   OptionsTable=p_user;
   if (OptionsTable._varformat()!=VF_HASHTAB) {
      return(0);
   }
   if (OptionsTable._indexin(Path)) {
      return(OptionsTable:[Path]);
   }else{
      return(0);
   }
}

static void SortProcTree(int ParentIndex,int Options)
{
   boolean bForceLineNumberSort = _are_statements_supported(getFileTreeLangId(ParentIndex)) && (Options&PROC_TREE_STATEMENTS);

   if (Options&PROC_TREE_SORT_LINENUMBER || bForceLineNumberSort) {
      _TreeSortUserInfo(ParentIndex,'NT');
   } else if(Options&PROC_TREE_SORT_FUNCTION) {
      _TreeSortCaption(ParentIndex,'iT','N');
   }
}

//Arg(2)!='' means just add the file
static int MaybeAddFilename(_str BufName,int bufid)
{
   _str filename=_strip_filename(BufName,'P');
   filename=strip(filename,'B','"');
   _str path=BufName;
   if (BufName=='') return(-1);
   if (IsSpecialFile(BufName)) {
      filename=path;
   }

   if ((def_proc_tree_options & PROC_TREE_NO_BUFFERS) || isEclipsePlugin()) {
      // Only do the work to add this buffer if:
      // 1) It is the current MDI child, and
      // 2) It is not current.
      if( bufid==_mdi.p_child.p_buf_id && _TreeGetUserInfo(TREE_ROOT_INDEX)!=bufid ) {
         _TreeSetUserInfo(TREE_ROOT_INDEX,_mdi.p_child.p_buf_id);
         StoreSortOptions(_mdi.p_child.p_buf_id/*maybe_quote_filename(path)*/,def_proc_tree_options);
         _TreeSetInfo(TREE_ROOT_INDEX,1);
         _TreeSetCaption(TREE_ROOT_INDEX,filename);
         _TreeDelete(TREE_ROOT_INDEX, "C");
         _TreeRefresh();

         _str CaptionName=ctlcurpath._ShrinkFilename(stranslate(BufName,'&&','&'),_proc_tree.p_width);
         if (CaptionName!=ctlcurpath.p_caption) {
            ctlcurpath.p_caption=CaptionName;
         }
      }
      return TREE_ROOT_INDEX;
   }

   boolean Taggable=_mdi.p_child._istagging_supported();
   int index=FindNode(filename,bufid);
   if (index >= 0) {
      //Look to see if the mode has changed
      int state=0;
      int bmindex,bmindex2;
      _TreeGetInfo(index,state,bmindex,bmindex2);
      //if (Taggable && bmindex==_pic_sm_file_d) {
      //   _TreeSetInfo(index,state,_pic_sm_file,_pic_sm_file);
      //}else if (!Taggable && bmindex==_pic_sm_file) {
      //   _TreeSetInfo(index,state,_pic_sm_file_d,_pic_sm_file_d);
      //   if (_TreeGetFirstChildIndex(index)>=0) _TreeDelete(index,'C');
      //}
      if (Taggable && bmindex==_pic_file_d12) {
         _TreeSetInfo(index,state,_pic_file12,_pic_file12);
      }else if (!Taggable && bmindex==_pic_file12) {
         _TreeSetInfo(index,state,_pic_file_d12,_pic_file_d12);
         if (_TreeGetFirstChildIndex(index)>=0) _TreeDelete(index,'C');
      }
   } else {
      //int InitState=(int) (!(!(def_proc_tree_options&(PROC_TREE_AUTO_EXPAND|PROC_TREE_NO_BUFFERS))));
      int InitState=(int) ((def_proc_tree_options&(PROC_TREE_AUTO_EXPAND|PROC_TREE_NO_BUFFERS))||isEclipsePlugin());
      if (Taggable || !(def_proc_tree_options&PROC_TREE_ONLY_TAGGABLE)) {
         //pic_index=Taggable?_pic_sm_file:_pic_sm_file_d;
         int pic_index=Taggable?_pic_file12:_pic_file_d12;
         if (!Taggable) {
            InitState=-1;
         }
         index=_TreeAddItem(TREE_ROOT_INDEX,//Relative Index
                            filename,       //Caption
                            TREE_ADD_AS_CHILD|TREE_ADD_SORTED_FILENAME, //Flags
                            pic_index,   //Collapsed Bitmap Index
                            pic_index,   //Expanded Bitmap Index
                            InitState,   //Initial State
                            0,           //More tree flags
                            bufid);      //User Info

         // the node will default to showing its children (symbol info), but the info
         // has not been added until the first tagging pass after it is opened.  to avoid
         // having the file appear to be expanded before its children are added, collapse
         // the node.
         if (index > 0) {
            _TreeSetInfo(index, 0);
         }

         StoreSortOptions(bufid/*maybe_quote_filename(path)*/,def_proc_tree_options);

         _mdi.p_child.p_ModifyFlags&=~MODIFYFLAG_PROCTREE_UPDATED;
         _mdi.p_child.p_ModifyFlags&=~MODIFYFLAG_PROCTREE_SELECTED;
      }
      //say "Inserting file: "filename
   }
   _str CaptionName=ctlcurpath._ShrinkFilename(stranslate(BufName,'&&','&'),_proc_tree.p_width);
   if (CaptionName!=ctlcurpath.p_caption) {
      ctlcurpath.p_caption=CaptionName;
   }
   return(index);
}

int GetProcTreeWID()
{
   // Access the proc tree in the Project toolbar...
   int wid=0;
   if (gLastTreeWID &&
       _iswindow_valid(gLastTreeWID) &&
       gLastTreeWID.p_object==OI_TREE_VIEW &&
       !gLastTreeWID.p_edit &&
       gLastTreeWID.p_name==PROC_TREE_NAME){

      wid=gLastTreeWID;
   }else{
      wid = getProcTreeForm();
      if (wid) {
         wid=wid._proc_tree;
      }else{
         wid=0;
      }
      gLastTreeWID=wid;
   }
   return(wid);
   //return(wid._find_control('_proc_tree'));
}

/**
 * Set the proc tree container form name. VSE looks for the proc tree
 * control in this form. The default form is the Project toolbar.
 *
 * @param containerFormName
 */
_command void proctree_setFormName(_str containerFormName=PROCTREE_TB_FORM_NAME_STRING)
{
   // Start using the proc tree from this container form.
   gProcTreeContainerFormName = containerFormName;

   // Reinitialize the new proc tree.
   gLastTreeWID = 0;
   int procTreeWid = GetProcTreeWID();
   if (!procTreeWid) return;
   procTreeWid.p_user = 0;
   procTreeWid.proctree_update_buffers();
   procTreeWid.call_event(procTreeWid,ON_CREATE);
   if (!_no_child_windows()) {
      _mdi.p_child.p_ModifyFlags &= ~MODIFYFLAG_PROCTREE_SELECTED;
      _mdi.p_child.p_ModifyFlags &= ~MODIFYFLAG_PROCTREE_UPDATED;
   }

   // Add proc tree to the end of the list, if needed.
   if (isEclipsePlugin()) {
      int i;
      boolean found = false;
      int count = gProcTreeWIDList._length();
      for (i=0; i<count; i++) {
         if (gProcTreeWIDList[i].procTree == procTreeWid) {
            found = true;
            break;
         }
      }
      if (!found) {
         gProcTreeWIDList[count].procTree = procTreeWid;
         gProcTreeWIDList[count].bufID = _mdi.p_child.p_buf_id;
      }
   }
}

void _document_renamed_proc_tree(int buf_id,_str old_bufname,_str new_bufname,int buf_flags)
{
   _buffer_renamed_proc_tree(buf_id,old_bufname,new_bufname,buf_flags);
}
void _buffer_renamed_proc_tree(int buf_id,_str old_bufname,_str new_bufname,int buf_flags)
{
   if (buf_flags & VSBUFFLAG_HIDDEN) {
      return;
   }
   if (old_bufname=='') {
      //Came form _document_renamed_proc_tree and just used the old docname, which
      //was blank
      int orig_view_id=p_window_id;
      p_window_id=VSWID_HIDDEN;
      _safe_hidden_window();
      int status=load_files('+bi 'buf_id);
      if (status) {
         return;//We can't find it....
      }
      old_bufname=p_buf_name;
      p_window_id=orig_view_id;
   }
   int treewid=GetProcTreeWID();
   if (!treewid) return;
   _str filename=old_bufname;
   if (!IsSpecialFile(filename)) {
      filename=_strip_filename(old_bufname,'P');
   }
   int index=treewid.FindNode(filename,buf_id);
   if (index>0) {
      treewid._TreeDelete(index);
   } else if (index==0) {
      treewid._TreeDelete(index,'c');
   }
   treewid.MaybeAddFilename(new_bufname,buf_id);
}


void _buffer_add_proc_tree(int newbuffid, _str name, int flags = 0)
{
   if (flags & VSBUFFLAG_HIDDEN) {
      return;
   }
   _str filename=_GetDocumentName();
   int treewid=GetProcTreeWID();
   if (!treewid) {
      return;
   }
   int wid=p_window_id;
   treewid.p_visible=0;
   //_UpdateCurrentTag();
   if (!IsSpecialFile(filename)) {
      filename=absolute(filename);
   }
   int orig_autotag_flags = def_autotag_flags2;
   def_autotag_flags2 = 0;
   treewid.MaybeAddFilename(filename,newbuffid);
   def_autotag_flags2 = orig_autotag_flags;
   treewid.p_visible=1;
   p_window_id=wid;
}

void _cbmdibuffer_hidden_proc_tree()
{
   _cbquit_proc_tree(p_buf_id,p_buf_name,p_DocumentName,p_buf_flags);
}

void _cbquit_proc_tree(int buf_id,_str buf_name,_str DocumentName,int buf_flags)
{
   int index;
   int treewid;

   if (DocumentName!="") {
      buf_name=DocumentName;
   }
   _str filename=buf_name;
   if (!IsSpecialFile(filename)) {
      filename=_strip_filename(buf_name,'P');
   }
   if (!isEclipsePlugin()) {
      treewid=GetProcTreeWID();
      if (!treewid) return;
      index=treewid.FindNode(filename,buf_id);
      if (index>0) {
         treewid._TreeDelete(index);
      } else if (index==0) {
         treewid._TreeDelete(index,'c');
      }
   } else {
      // The Eclipse plugin uses multiple proc trees. So in addition to
      // updating the the active proc tree (code above), all remaining
      // proc trees must also be updated in the same way.
      //
      // Remove the proc tree from list.
      int i;
      for (i=0; i<gProcTreeWIDList._length(); i++) {
         if (gProcTreeWIDList[i].bufID == buf_id) {
            gProcTreeWIDList._deleteel(i);
            break;
         }
      }

      // Remove invalid proctrees. Start from the end to avoid
      // indexing problem. This is needed because some buffers can be
      // created but _cbquit_proc_tree() may never get called for them
      // which causes invalid cached proctrees.
      boolean validTree;
      for (i=gProcTreeWIDList._length()-1; i>=0; i--) {
         validTree = false;
         treewid = gProcTreeWIDList[i].procTree;
         if (_iswindow_valid(treewid)
             && treewid.p_object == OI_TREE_VIEW
             && treewid.p_name == "_proc_tree"
             ) {
            if (treewid.p_parent && treewid.p_parent.p_parent) {
               // Double ancestor because the Eclipse proctree is
               // inside the form that is also the child of another form.
               int formWID = treewid.p_parent.p_parent;
               if (formWID.p_object == OI_FORM
                   && pos("ctlEclipseProcTreeForm", formWID.p_name, 1, "I") == 1
                   ) {
                  validTree = true;
               }
            }
         }
         if (!validTree) gProcTreeWIDList._deleteel(i);
      }

      // Update the remaining proc trees.
      for (i=0; i<gProcTreeWIDList._length(); i++) {
         treewid = gProcTreeWIDList[i].procTree;
         index = treewid.FindNode(filename,buf_id);
         if (index>0) {
            treewid._TreeDelete(index);
         } else if (index==0) {
            treewid._TreeDelete(index,'c');
         }
      }
   }
}
static _str _GetDocumentName()
{
   if (p_DocumentName!='') {
      return(p_DocumentName);
   }
   return(p_buf_name);
}


int getFileTreeIndex( int tree_index )
{
   // Find the parent that is just below the root depth == 1 ( the current file we we are in )
   // get the index of the current function and parent
   while( ( tree_index >= 0 ) && ( getProcTreeForm()._proc_tree._TreeGetDepth(tree_index) > proctree_file_depth() ) ) {
      tree_index = getProcTreeForm()._proc_tree._TreeGetParentIndex(tree_index);
   }

   return tree_index;
}

static _str getFileTreeLangId( int tree_index )
{
   _str lang='';
   int ParentIndex = getFileTreeIndex(tree_index);
   if (ParentIndex < 0) return lang;
   int bid=getProcTreeForm()._proc_tree._TreeGetUserInfo(ParentIndex);
   int orig_view_id=p_window_id;
   int orig_wid=p_window_id;
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   int status=load_files('+q +bi 'bid);
   if (!status) {
      lang = p_LangId;
   }
   p_window_id = orig_wid;
   p_window_id = orig_view_id;
   return lang;
}

_proc_tree.on_create()
{
   int orig_autotag_flags = def_autotag_flags2;
   def_autotag_flags2 |= AUTOTAG_CURRENT_CONTEXT;
   if (orig_autotag_flags != def_autotag_flags2) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   ctlcurpath.p_caption='';
   ctlcurpath.p_width=0;
   #if __MACOSX__
   macSetShowsFocusRect(p_window_id, 0);
   #endif
   _proc_tree._MakePreviewWindowShortcuts();
}

///////////////////////////////////////////////////////////////////////////////
// For saving and restoring the state of the Defs tool window
// when the user undocks, pins, unpins, or redocks the window.
//
void _tbSaveState__tbproctree_form(typeless& state, boolean closing)
{
   //if( closing ) {
   //   return;
   //}
   _proc_tree._TreeSaveNodes(state);
}
void _tbRestoreState__tbproctree_form(typeless& state, boolean opening)
{
   //if( opening ) {
   //   return;
   //}
   if (state == null) return;
   _proc_tree._TreeRestoreNodes(state);
}

static void resizeProcs()
{
   int containerW = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   int containerH = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);

   if (!isEclipsePlugin()) {
      // Resize width:
      _proc_tree.p_width = containerW - 2 * _proc_tree.p_x;

      // Resize height:
      _proc_tree.p_height = containerH - _proc_tree.p_y;

      // DJB 03-14-2007 -- Resize the file label
      if (!_no_child_windows()) {
         _str BufName = _mdi.p_child._GetDocumentName();
         _str CaptionName=ctlcurpath._ShrinkFilename(stranslate(BufName,'&&','&'),_proc_tree.p_width);
         if (CaptionName!=ctlcurpath.p_caption) {
            ctlcurpath.p_caption=CaptionName;
         }
      }
   }
}

_tbproctree_form.on_got_focus()
{
   _UpdateCurrentTag(true);
}

_tbproctree_form.on_resize()
{
   resizeProcs();
}

static void proctree_update_buffers()
{
   //_TreeBeginUpdate(TREE_ROOT_INDEX);

   if ((!(def_proc_tree_options & PROC_TREE_NO_BUFFERS)) && !isEclipsePlugin()) {
      int first=_mdi.p_child.p_buf_id;
      int index=0;
      int longest=0;
      mou_hour_glass(1);
      for (;;) {
         _mdi.p_child._next_buffer('HR');
         _str restore_filename=editor_name('p'):+_WINDOW_CONFIG_FILE;
         if (!(_mdi.p_child.p_buf_flags&VSBUFFLAG_HIDDEN) &&
             !(file_eq(_strip_filename(_mdi.p_child._GetDocumentName(),'P'),_WINDOW_CONFIG_FILE))) {
            index=MaybeAddFilename(_mdi.p_child._GetDocumentName(),_mdi.p_child.p_buf_id);
         }
         if (_mdi.p_child.p_buf_id==first) break;
      }
      if (index>=0) {
         _TreeSetCurIndex(index);
         _TreeRefresh();
      }
      mou_hour_glass(0);
   }

   //_TreeEndUpdate(TREE_ROOT_INDEX);
}

static boolean TaggingSupportedForFileNode(int index)
{
   int bufid=_TreeGetUserInfo(index);
   int orig_view_id=p_window_id;
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   int status=load_files('+Q +bi 'bufid);
   if (status) {
      p_window_id=orig_view_id;
      return(false);
   }
   boolean taggable=_istagging_supported();
   p_window_id=orig_view_id;
   return(taggable);
}

static int getExpandLevel()
{
   // Default to normal processing.
   // See comment on def_proc_tree_expand_level.
   int level = 0;
   if( def_proc_tree_expand_level>=0 && def_proc_tree_expand_level<=2 ) {
      level=def_proc_tree_expand_level;
   }
   return level;
}

/**
 * Used to indicate the current buffer has switched when deciding whether
 * to update the current context or not. Used by _UpdateCurrentTag, et al.
 * 
 * @param buf_id (optional). Pass in value >=0 to set the last buf_id.
 * 
 * @return The last buf_id that the Procs tree knows about.
 */
static int proctreeLastBufId(int buf_id=-1)
{
   static int last_buf_id;
   if( buf_id>=0 ) {
      last_buf_id=buf_id;
   }
   return last_buf_id;
}

/**
 * Used to indicate current line has changed when deciding whether
 * to find the current tag or not. Used by _UpdateCurrentTag, et al.
 * 
 * @param linenum (optional). Pass in value >=0 to set the last line number.
 * 
 * @return The last line number that the Procs tree knows about.
 */
static int proctreeLastLinenum(int linenum=-1)
{
   static int last_linenum;
   if( linenum>=0 ) {
      last_linenum=linenum;
   }
   return last_linenum;
}

//Arg(1)!='' means do not add tags
void _UpdateCurrentTag(boolean AlwaysUpdate=false)
{
   // check arguments
   // Tan and Clark study effects of AUTOTAG_CURRENT_CONTEXT
   // and found that it is simpler if AUTOTAG_BUFFERS effects
   // the proc tree as well.  There's no need for another
   // option.
   //
   // Update: the proctree depending on autotag buffers
   // confused some windows users, so removing this check
   // Dennis 11/23/99
   //
   //if (!(def_autotag_flags2 & AUTOTAG_BUFFERS)) {
      //return;
   //}

   // bail out if focus in in the proctree
   int treewid=GetProcTreeWID();
   int focuswid=_get_focus();
   if (!treewid || !focuswid) {
      return;
   }

   // is the tree empty, and not forcing update, and not first time here
   boolean isEmpty=(treewid._TreeGetFirstChildIndex(TREE_ROOT_INDEX) < 0);
   if (focuswid==treewid && !AlwaysUpdate && !isEmpty) {
      return;
   }

   // no child windows, then bail out of here
   if (_no_child_windows()) {
      treewid.ctlcurpath.p_caption='';
      treewid.ctlcurpath.p_width=0;
      return;
   }

   // If the proc tab is not current, do not update.
   if( !_tbIsWidActive(getProcTreeForm()) ) {
      return;
   }

   // tree not initialized yet?
   if (isEmpty) {
      treewid.proctree_update_buffers();
   }

   boolean wasEmptyFileNode = false;
   if( ((def_proc_tree_options&PROC_TREE_NO_BUFFERS) || isEclipsePlugin()) && proctreeLastBufId()!=_mdi.p_child.p_buf_id ) {
      // New buffer or we have switched buffers
      wasEmptyFileNode=true;
   }

   // find the index of the current buffer
   _str filename=_strip_filename(_mdi.p_child._GetDocumentName(),'P');
   if (IsSpecialFile(maybe_quote_filename(_mdi.p_child._GetDocumentName()))) {
      filename=maybe_quote_filename(_mdi.p_child._GetDocumentName());
   }
   //Cannot get here if no child windows, so this is ok
   int index=treewid.FindNode(filename,_mdi.p_child.p_buf_id);

   // get file extension (mode name)
   _str lang=_mdi.p_child.p_LangId;

   // no current tree index, then bail out?
   int curIndex=treewid._TreeCurIndex();
   if (curIndex < 0) {
      return;
   }

   // not a hidden buffer, maybe add the filename
   if (!index && !(_mdi.p_child.p_buf_flags&VSBUFFLAG_HIDDEN)) {
      index=treewid.MaybeAddFilename(_mdi.p_child._GetDocumentName(),_mdi.p_child.p_buf_id);
   }
   if (index<0 || (index==0 && !(def_proc_tree_options&PROC_TREE_NO_BUFFERS))) {
      return;
   }

   if( !wasEmptyFileNode && !((def_proc_tree_options&PROC_TREE_NO_BUFFERS) || isEclipsePlugin()) ) {
      wasEmptyFileNode = ( 0==treewid._TreeGetNumChildren(index) );
   }

   // set the current filename caption on top of proc tree
   int orig_wid=p_window_id;
   p_window_id=treewid;
   // get the index of the current function and parent
   int OpenIndex=_TreeCurIndex();
   while (_TreeGetDepth(OpenIndex)>proctree_file_depth()) {
      OpenIndex=_TreeGetParentIndex(OpenIndex);
   }
   int OrigParentIndex=OpenIndex;

   // get complete file path and options
   se.tags.TaggingGuard sentry;
   _str NewPath=_TreeGetUserInfo(index);
   int sortop=GetOptions(NewPath);
   int state=0;
   _TreeGetInfo(index,state);
   //say('_UpdateCurrentTag: h1 - state='state);
   int OrigNumDown=-1;
   int AddedTags=0;
   _str origCap=_TreeGetCaption(_TreeCurIndex());
   boolean NeedRefresh=false;
   boolean NewFile = !(_mdi.p_child.p_buf_id==proctreeLastBufId());
   boolean NeedsUpdate=(!(_mdi.p_child.p_ModifyFlags&MODIFYFLAG_PROCTREE_UPDATED) || NewFile);
   if (NeedsUpdate) {
      _mdi.p_child.p_ModifyFlags&=~MODIFYFLAG_PROCTREE_SELECTED;
   }
   if (isEmpty || !state) NeedsUpdate=true;
   if (AlwaysUpdate || (NeedsUpdate && (_idle_time_elapsed()>=def_update_tagging_idle))) {

      //say("_UpdateCurrentTag: ****************************************");
      //_StackDump();
      //say("_UpdateCurrentTag: ****************************************");

      // if the context is not yet up-to-date, then don't update yet
      if (!AlwaysUpdate && 
          !(_mdi.p_child.p_ModifyFlags & MODIFYFLAG_CONTEXT_UPDATED) &&
          _idle_time_elapsed() < def_update_tagging_idle+def_update_tagging_extra_idle) {
         return;
      }

      // do not let writers sneak in and modify the context while we are
      // upating the tree control
      sentry.lockContext(false);

      // add the tags, simply transfer over from context tree
      if( def_proc_tree_options&PROC_TREE_STATEMENTS ) {
         _mdi.p_child._UpdateContext(true,false, VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);
      } else {
         _mdi.p_child._UpdateContext(true,false, VS_UPDATEFLAG_context );
      }

      //say("_UpdateCurrentTag");
      cb_prepare_expand(p_active_form,p_window_id,index);
      _TreeBeginUpdate(index,'','T');
      //_TreeDelete(index,'C');
      int force_leaf = (def_proc_tree_options&PROC_TREE_NO_STRUCTURE)? -1:1;
      if (force_leaf==1 && (def_proc_tree_options&PROC_TREE_AUTO_STRUCTURE)) {
         force_leaf=0;
      }

      tag_tree_insert_context(p_window_id, index, def_proctree_flags, 1, force_leaf, 0,
                              def_proc_tree_options&PROC_TREE_STATEMENTS);
      _TreeEndUpdate(index);
      SortProcTree(index,def_proc_tree_options);
      if (NeedsUpdate == true) {
         _mdi.p_child.p_ModifyFlags|=MODIFYFLAG_PROCTREE_UPDATED;
         _mdi.p_child.p_ModifyFlags&=~MODIFYFLAG_PROCTREE_SELECTED;
      }
      proctreeLastBufId(_mdi.p_child.p_buf_id);
      NeedRefresh=true;

   } else if ((sortop & def_proc_tree_options) &&
              ((def_proc_tree_options&(PROC_TREE_AUTO_EXPAND|PROC_TREE_NO_BUFFERS)) || isEclipsePlugin()) &&
             (!(_mdi.p_child.p_ModifyFlags&MODIFYFLAG_PROCTREE_UPDATED) &&
              !AlwaysUpdate)) {
      p_window_id=orig_wid;
      return;
   }

   // do not update the current tag as often
   if (!AlwaysUpdate && !NeedsUpdate && _idle_time_elapsed() < (def_update_tagging_idle intdiv 4)) {
      p_window_id=orig_wid;
      return;
   }

   // do not let writers sneak in and modify the context while we are
   // upating the tree control
   sentry.lockContext(false);

   boolean findCurrentProc = false;
   int level = getExpandLevel();
   // for Ant, expand 2 levels when a new file is displayed
   if (NewFile && _mdi.p_child.p_LangId == "ant") {
      level = 2;
   }
   if( ((def_proc_tree_options&(PROC_TREE_AUTO_EXPAND|PROC_TREE_NO_BUFFERS)) || isEclipsePlugin()) &&
       wasEmptyFileNode && level>0 ) {

      // First time filling in the tree for the file node, so use def_proc_tree_expand_level
      p_window_id.expandToLevel(index,level);
      // Setting last linenum and p_ModifyFlags will force the tree to
      // stay expanded to the level we specify UNTIL the user moves the
      // cursor or switches buffers.
      proctreeLastLinenum(_mdi.p_child.p_RLine);
      _mdi.p_child.p_ModifyFlags |= MODIFYFLAG_PROCTREE_SELECTED;
      findCurrentProc=false;
   } else {
      // if auto-expand is on, or if in outline mode, or if the node is already expanded, find the current tag
      findCurrentProc = ((def_proc_tree_options&(PROC_TREE_AUTO_EXPAND|PROC_TREE_NO_BUFFERS)) || 
                         isEclipsePlugin() )? true:false;
      //say('_UpdateCurrentTag: h2 - findCurrentProc='findCurrentProc'  state='state);
      if (!findCurrentProc && state > 0) {
         findCurrentProc=true;
      }
      //say('_UpdateCurrentTag: h3 - findCurrentProc='findCurrentProc);
   }

   if( findCurrentProc && _TreeGetFirstChildIndex(index)>=0 ) {
      // has the selected item in the proc tree been updated
      // or has the current line changed
      int EditorLN = _mdi.p_child.p_RLine;
      if( !(_mdi.p_child.p_ModifyFlags&MODIFYFLAG_PROCTREE_SELECTED) ||
          proctreeLastLinenum()!=EditorLN ) {

         if( def_proc_tree_options&PROC_TREE_STATEMENTS ) {
            _mdi.p_child._UpdateContext(true,false, VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);
         } else {
            _mdi.p_child._UpdateContext(true,false, VS_UPDATEFLAG_context );
         }

         if (isOutlineViewActive() == false) {
            int currentWindowID = p_window_id;
            p_window_id = _mdi.p_child;
            int context_id = tag_nearest_context(EditorLN, def_proctree_flags, false, true);
            int current_id = tag_current_context();
            //If we're between functions, but in a comment, find the next context.
            if (current_id != context_id && _in_comment()) {
               orig_context_id := context_id;
               context_id = tag_nearest_context(EditorLN, def_proctree_flags, true, true);
               // make sure that the next one after the current isn't TOO far after.
               if (context_id > 0 && current_id > 0) {
                  tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, auto context_start_seekpos);
                  tag_get_detail2(VS_TAGDETAIL_context_end_seekpos,   current_id, auto current_end_seekpos);
                  if (context_start_seekpos > current_end_seekpos) {
                     context_id = orig_context_id;
                  }
               }
            }
            p_window_id = currentWindowID;
   
            int line_num=0;
            tag_get_detail2(VS_TAGDETAIL_context_line, context_id, line_num);
            int nearLine = 0;
   
            if (state <= 0) {
               _TreeSetInfo(index,1);
            }
   
            int nearIndex = _TreeSearch(index,'','T',line_num);
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
            int treeRoot = TREE_ROOT_INDEX;
            if (proctree_file_depth() == 1) {
               treeRoot = index;
            }
            // find the closest tree item to the current line
            int nearIndex = get_nearest_tree_index_context(treewid, EditorLN, treeRoot);
            if ((nearIndex >= 0) && (treewid._TreeCurIndex() != nearIndex)) {
               NeedRefresh = true;
               treewid._TreeSetCurIndex(nearIndex);
            }
         }

         proctreeLastLinenum(EditorLN);
         _mdi.p_child.p_ModifyFlags |= MODIFYFLAG_PROCTREE_SELECTED;
      }
   } else {
      int cur_index=_TreeCurIndex();
      while (cur_index > 0 && cur_index!=index) {
         cur_index=_TreeGetParentIndex(cur_index);
      }
      if (cur_index < 0) {
         _TreeSetCurIndex(index);
      }
   }

   // collapse old file node if it was left open
   int CurIndex=_TreeCurIndex();
   if (CurIndex < 0) {
      return;
   }
   while (_TreeGetDepth(CurIndex) > proctree_file_depth()) {
      CurIndex=_TreeGetParentIndex(CurIndex);
   }
   if (OpenIndex!=CurIndex &&
       OpenIndex!=_TreeGetParentIndex(CurIndex) &&
       //(def_proc_tree_options&PROC_TREE_AUTO_EXPAND) &&
       TaggingSupportedForFileNode(OpenIndex)) {
      if (OpenIndex > 0) {
         _TreeSetInfo(OpenIndex,0);
      }
      NeedRefresh=true;
   }
   // expand current file index if autoexpand
   if (_TreeGetParentIndex(CurIndex)==TREE_ROOT_INDEX &&
       ((def_proc_tree_options&(PROC_TREE_AUTO_EXPAND|PROC_TREE_NO_BUFFERS)) || isEclipsePlugin()) &&
       TaggingSupportedForFileNode(CurIndex)) {
      _TreeSetInfo(CurIndex,1);
   }
   if (NeedRefresh) {
      _TreeRefresh(); //here!!!!!!!!!!!!!!!!!!!
   }

   p_window_id=orig_wid;
}

/**
 * Returns the tree node index that represents the tag closest to, but not 
 * below, the current line in the editor. 
 * 
 * @param editorLine - The current line in the editor (or any line you wish to 
 *                   search for)
 * @param rootIndex - The root in the tree used for recursive calls (should not 
 *                  be specified in normal calling)
 */
int get_nearest_tree_index_context(int treewid, int editorLine, int rootIndex=TREE_ROOT_INDEX)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   struct VS_TAG_BROWSE_INFO cm;

   int childIndex = treewid._TreeGetFirstChildIndex(rootIndex);
   // make sure there is a child
   int lastWinningChildID = -1;
   int lastWinningDistance = 1000000;
   while (childIndex >= 0) {
      // get the user info, this is the context ID of that node
      typeless ctxID = treewid._TreeGetUserInfo(childIndex);
      // if the user info is not an integer, then something is screwy and we should bail
      if (!isinteger(ctxID)) break;

      ctxID++;
      if (ctxID >= 0) {
         _str temp1 = treewid._TreeGetCaption(childIndex);
         tag_get_context_info(ctxID, cm);
         int curDistance = editorLine - cm.line_no;
         if ((curDistance >= 0) && (curDistance < lastWinningDistance)) {
            // we have found an item that comes before the current
            // editor line, so record it
            lastWinningChildID = childIndex;
            lastWinningDistance = curDistance;
         } 
      }
      childIndex = treewid._TreeGetNextSiblingIndex(childIndex);
   }
   // did we find any matches here?
   if (lastWinningChildID > -1) {
      // see if we have any closer children
      int closerChild = get_nearest_tree_index_context(treewid, editorLine, lastWinningChildID);
      if (closerChild > -1) {
         return closerChild;
      } else {
         return lastWinningChildID;
      }
   }
   // if we got here, then we have no hope
   return rootIndex;
}

_proc_tree.lbutton_double_click()
{
   // If there is a pending on-change, kill the timer
   if (gProcTreeFocusTimerId != -1) {
      _kill_timer(gProcTreeFocusTimerId);
      gProcTreeFocusTimerId=-1;
   }
   int index=_TreeCurIndex();
   if (_TreeGetDepth(index)==proctree_file_depth()) {
      if (!( (def_proc_tree_options&(PROC_TREE_AUTO_EXPAND|PROC_TREE_NO_BUFFERS)) || isEclipsePlugin())) {
         int bufid=_TreeGetUserInfo(index);
         int fid=p_active_form;
         int status=edit('+bi 'bufid);
         fid._proc_tree.call_event(find_index('_ul2_tree',EVENTTAB_TYPE),LBUTTON_DOUBLE_CLICK,'E');
         return('');
      }
   }
   //call_event(find_index('_ul2_tree',EVENTTAB_TYPE),LBUTTON_DOUBLE_CLICK,'E');
   call_event(CHANGE_LEAF_ENTER,index,p_window_id,ON_CHANGE,'w');
}

void _proc_tree.' '()
{
   int index=_TreeCurIndex();
   if (_TreeGetDepth(index)>=proctree_symbol_depth()) {
      int ParentIndex=_TreeGetParentIndex(index);
      while (_TreeGetDepth(ParentIndex)>proctree_file_depth()) {
         ParentIndex=_TreeGetParentIndex(ParentIndex);
      }
      int orig_wid=p_window_id;
      if (_no_child_windows()) {
         return;
      }
      if (def_search_result_push_bookmark) {
         _mdi.p_child.push_bookmark();
         _mdi.p_child.mark_already_open_destinations();
      }
      if (ParentIndex>=0) {
         int bufid=_TreeGetUserInfo(ParentIndex);
         edit('+bi 'bufid);
         p_window_id=orig_wid;
      }
      int LineNumber=_TreeGetUserInfo(index);
      ParentIndex=_TreeGetParentIndex(index);
      _str path=_TreeGetCaption(ParentIndex);
      _str CaptionName=ctlcurpath._ShrinkFilename(stranslate(path,'&&','&'),_proc_tree.p_width);
      if (ctlcurpath.p_caption!=CaptionName) {
         ctlcurpath.p_caption=CaptionName;
      }
      _mdi.p_child.p_line=LineNumber;

      if (_mdi.p_child.p_scroll_left_edge>=0) {
         _mdi.p_child.p_scroll_left_edge= -1;
      }
      if (_mdi.p_child._lineflags() & HIDDEN_LF) {
         _mdi.p_child.expand_line_level();
      }
      _mdi.p_child.center_line();
      _mdi.p_child.push_destination();

   } else if (index > 0 && _TreeGetDepth(index)==proctree_file_depth()) {

      // just jump to the file they selected
      int orig_wid=p_window_id;
      if (!_no_child_windows() && def_search_result_push_bookmark) {
         _mdi.p_child.push_bookmark();
         _mdi.p_child.mark_already_open_destinations();
      }
      int bufid=_TreeGetUserInfo(index);
      edit('+bi 'bufid);
      p_window_id=orig_wid;
      _mdi.p_child.push_destination();
   }
}


// Get the information about the tag currently selected
// in the proc tree.
//
static int _ProcTreeTagInfo(struct VS_TAG_BROWSE_INFO &cm,
                            _str &proc_name, _str &path, int &LineNumber, int index = -1)
{
   // get the symbol browser form window id
   tag_browse_info_init(cm);
   int f = getProcTreeForm();
   if (!f) {
      return 0;
   }
   _nocheck _control _proc_tree;

   // find the tag name, file and line number
   if(index == -1) {
      index = f._proc_tree._TreeCurIndex();
   }
   if( index<0 ) {
      // Probably nothing in the tree, so bail
      return 0;
   }
   LineNumber=f._proc_tree._TreeGetUserInfo(index);
   int ParentIndex=f._proc_tree._TreeGetParentIndex(index);
   if (ParentIndex < proctree_file_depth()) {

      // ok, the tag information is just the selected file
      int bid=f._proc_tree._TreeGetUserInfo(index);
      int orig_view_id=p_window_id;
      int orig_wid=p_window_id;
      p_window_id=VSWID_HIDDEN;
      _safe_hidden_window();
      path='';
      int status=load_files('+q +bi 'bid);
      if (!status) {
         path=p_buf_name;
      }
      cm.member_name = (p_DocumentName != "")? p_DocumentName : _strip_filename(p_buf_name,"P");
      cm.type_name = "file";
      cm.language=p_LangId;
      path=cm.file_name=p_buf_name;
      LineNumber=cm.line_no=p_line;
      p_window_id=orig_view_id;
      p_window_id=orig_wid;
      return -1;
   }

   // if this is the outline view, then a tree node's user data is the 
   // context ID, so just use that   
   if (isOutlineViewActive() == true) {
      tag_lock_context();
      int ctxID = f._proc_tree._TreeGetUserInfo(index) + 1;
      tag_get_context_info(ctxID, cm);
      proc_name = cm.member_name;
      path = cm.file_name;
      LineNumber = cm.line_no;
      tag_unlock_context();
      return ctxID;
   }

   while (f._proc_tree._TreeGetDepth(ParentIndex)>proctree_file_depth()) {
      ParentIndex=f._proc_tree._TreeGetParentIndex(ParentIndex);
   }
   int bid=f._proc_tree._TreeGetUserInfo(ParentIndex);
   int orig_view_id=p_window_id;
   int orig_wid=p_window_id;
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   path='';
   int status=load_files('+q +bi 'bid);
   if (!status) {
      path=p_buf_name;
   }
   cm.language=p_LangId;
   cm.file_name=p_buf_name;

   if( def_proc_tree_options&PROC_TREE_STATEMENTS )
      _mdi.p_child._UpdateContext(true,false, VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);
   else
      _mdi.p_child._UpdateContext(true,false, VS_UPDATEFLAG_context );

   p_window_id=orig_view_id;
   p_window_id=orig_wid;
   _str caption = f._proc_tree._TreeGetCaption(index);
   tag_tree_decompose_caption(caption,proc_name);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // get the remainder of the information
   //return _GetContextTagInfo(cm, '', proc_name, path, LineNumber);
   cm.tag_database   = '';
   cm.category       = '';
   cm.qualified_name = '';
   cm.seekpos=0;
   int i = tag_find_context_iterator(proc_name, true, true);
   while (i > 0) {
      int context_line;
      _str context_file;
      tag_get_detail2(VS_TAGDETAIL_context_line, i, context_line);
      tag_get_detail2(VS_TAGDETAIL_context_file, i, context_file);
      if (context_line == LineNumber &&
          (file_eq(context_file,path) || (cm.flags&VS_TAGFLAG_extern_macro))) {
         tag_get_context_info(i, cm);
         if (cm.type_name=='include' && cm.return_type!='' && file_exists(cm.return_type)) {
            path=cm.file_name=cm.return_type;
            LineNumber=cm.line_no=1;
         }
         // 4:57:47 PM 1/23/2003
         // If we find a match, return the context id
         return i;
      }
      i = tag_next_context_iterator(proc_name, i, true, true);
   }

   // did not find a match, really quite depressing, use what we know
   cm.member_name = proc_name;
   cm.type_name   = '';
   cm.file_name   = path;
   cm.line_no     = LineNumber;
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
   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// This is the timer callback.  Whenever the current index (cursor position)
// for the proc tree is changed, a timer is started/reset.  If no
// activity occurs within a set amount of time, this function is called to
// update the output window.
//
static void _ProcTreeFocusTimerCallback()
{
   // kill the timer
   _kill_timer(gProcTreeFocusTimerId);
   gProcTreeFocusTimerId=-1;

   // get the symbol browser form window id
   int f = getProcTreeForm();
   if (!f) {
      return;
   }
   _nocheck _control _proc_tree;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   struct VS_TAG_BROWSE_INFO cm;
   _str proc_name;
   _str path;
   int LineNumber=0;
   if (!_ProcTreeTagInfo(cm,proc_name,path,LineNumber)) {
      return;
   }

   // find the output tagwin and update it
   cb_refresh_output_tab(cm, true, true, false, APF_DEFS);

   // update the properties toolbar
   cb_refresh_property_view(cm);

   // Do not update call tree or references tab unless this option is enabled
   if (!(def_autotag_flags2 & AUTOTAG_UPDATE_CALLSREFS)) {
      return;
   }

   // find the output references tab and update it
   f = _GetReferencesWID(true);
   if (f && proc_name != '') {
      refresh_references_tab(cm);
   }

   // find the call tree view and update it
   //say("_ProcTreeFocusTimerCallback: cm.seekpos="cm.seekpos" end="cm.end_seekpos" file="cm.file_name);
   cb_refresh_calltree_view(cm);
}

_str _proc_tree.on_change(int reason,int index)
{
   //if (!(def_autotag_flags2 & AUTOTAG_CURRENT_CONTEXT)) {
   //   return('');
   //}
   if (reason==CHANGE_SCROLL) return('');
   if (index < 0) return('');

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // make sure that the on_change can't call itself recursively
   static boolean onChangeRecursing;
   if (onChangeRecursing) return '';
   onChangeRecursing=true;

   int status=0;
   int depth=_TreeGetDepth(index);
   //say("depth="depth" index="index" reason="reason);

   if (depth==proctree_file_depth() && reason==CHANGE_LEAF_ENTER) {
      _str NewFile=_TreeGetCaption(index);
      int bufid=_TreeGetUserInfo(index);
      int sortop=GetOptions(bufid);
      //Find old tree node and close it
      _str OldPath=_mdi.p_child._GetDocumentName();
      int OldIndex=FindNode(_strip_filename(_mdi.p_child._GetDocumentName(),'P'),_mdi.p_child.p_buf_id);
      if (OldIndex > 0 && TaggingSupportedForFileNode(OldIndex)) {
         _TreeSetInfo(OldIndex,0);
      }
      //Open file that we clicked on
      int treewid=p_window_id;
      _str buf_option='';
      if(isEclipsePlugin()) {
         NewFile = _find_buffer_name(bufid);
         _eclipse_open(0, NewFile);
      } else {
         status=edit('+bi 'bufid);
      }
      
      p_window_id=treewid;
      _str new_index='';
      int show_children=0;

      _TreeGetInfo(index,show_children);
      //int orig_proc_tree_options=def_proc_tree_options;
      //def_proc_tree_options|=PROC_TREE_AUTO_EXPAND;
      if (_TreeGetFirstChildIndex(index)<0 ||
          !(_mdi.p_child.p_ModifyFlags&MODIFYFLAG_PROCTREE_UPDATED)) {
         _UpdateCurrentTag(true);
         _TreeGetInfo(index,show_children);
      }
      if (show_children <= 0) {
         _UpdateCurrentTag(true);
         _TreeSetInfo(index,1);
      }
      onChangeRecursing=false;
      return(new_index);

   } else if (depth==proctree_file_depth() && reason==CHANGE_EXPANDED) {
      _str NewFile=_TreeGetCaption(index);
      int bufid=_TreeGetUserInfo(index);
      int sortop=GetOptions(bufid);
      //Find old tree node and close it
      _str OldPath=_mdi.p_child._GetDocumentName();
      int OldIndex=FindNode(_strip_filename(_mdi.p_child._GetDocumentName(),'P'),_mdi.p_child.p_buf_id);
      if (OldIndex > 0 && TaggingSupportedForFileNode(OldIndex)) {
         _TreeSetInfo(OldIndex,0);
      }
      //Open file that we clicked on
      int treewid=p_window_id;
      _str buf_option='';
      int oldid=_get_focus();
      int orig_buf_id = _mdi.p_child.p_buf_id;
      if(isEclipsePlugin()) {
         NewFile = _find_buffer_name(bufid);
         _eclipse_open(0, NewFile);
      } else {
         _mdi.p_child.load_files('+q +bi 'bufid);
      }

      p_window_id=treewid;
      _str new_index='';
      int show_children=0;

      _TreeGetInfo(index,show_children);
      //int orig_proc_tree_options=def_proc_tree_options;
      //def_proc_tree_options|=PROC_TREE_AUTO_EXPAND;
      if (_TreeGetFirstChildIndex(index)<0 ||
          !(_mdi.p_child.p_ModifyFlags&MODIFYFLAG_PROCTREE_UPDATED)) {
         if (show_children <= 0) _TreeSetInfo(index,1);
         _UpdateCurrentTag(true);
         _TreeGetInfo(index,show_children);
      }
      if (show_children <= 0) {
         _TreeSetInfo(index,1);
         _UpdateCurrentTag(true);
      }

      if(isEclipsePlugin()) {
         oldid._set_focus();
      }
      //def_proc_tree_options=orig_proc_tree_options;
      onChangeRecursing=false;
      return(new_index);

   }else if (depth>=proctree_symbol_depth() && (reason==CHANGE_LEAF_ENTER)) {

      int ParentIndex=_TreeGetParentIndex(index);
      if (ParentIndex > 0) {
         while (_TreeGetDepth(ParentIndex)>proctree_file_depth()) {
            ParentIndex=_TreeGetParentIndex(ParentIndex);
         }
      }
      if (!_no_child_windows() && def_search_result_push_bookmark) {
         _mdi.p_child.push_bookmark();
         _mdi.p_child.mark_already_open_destinations();
      }
      if (ParentIndex>=0) {
         int bufferid=_TreeGetUserInfo(ParentIndex);
         if (1/*!file_eq(filename,_mdi.p_child._GetDocumentName())*/) {
            int wid=p_window_id;
            status=edit('+bi 'bufferid);
            p_window_id=wid;
         }
      }
      int LineNumber=_TreeGetUserInfo(index);
      _str cap=_TreeGetCaption(index);
      ParentIndex=_TreeGetParentIndex(index);
      _str path=_TreeGetCaption(ParentIndex);
      _str CaptionName=ctlcurpath._ShrinkFilename(stranslate(path,'&&','&'),_proc_tree.p_width);
      if (ctlcurpath.p_caption!=CaptionName) {
         ctlcurpath.p_caption=CaptionName;
      }
      p_window_id=_mdi.p_child;

      maybe_deselect(true);
      struct VS_TAG_BROWSE_INFO cm;
      _str proc_name;
      if (_ProcTreeTagInfo(cm,proc_name,path,LineNumber) > 0) {
         _GoToROffset(cm.seekpos);
      } else {
         p_RLine=LineNumber;// fallback
      }

      if (p_scroll_left_edge>=0) {
         p_scroll_left_edge= -1;
      }
      if (_lineflags() & HIDDEN_LF) {
         expand_line_level();
      }
      push_destination();
      center_line();
      _set_focus();

   }else if (depth>0 && reason==CHANGE_SELECTED) {

      // kill the existing timer
      if (gProcTreeFocusTimerId!= -1) {
         _kill_timer(gProcTreeFocusTimerId);
         gProcTreeFocusTimerId=-1;
      }
      // don't create a new timer unless there is something to update
      if ((_GetTagwinWID() || _GetReferencesWID() || _GetCBrowserCallTreeWID() ||
           _GetCBrowserPropsWID()) && _get_focus()==p_window_id) {
         int timer_delay=max(200,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
         gProcTreeFocusTimerId=_set_timer(timer_delay,_ProcTreeFocusTimerCallback);
      }
   }
   onChangeRecursing=false;
   return('');
}

void _proc_tree.on_highlight(int index, _str caption="")
{
   if (index < 0 || !def_tag_hover_preview) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }

   // find the tag name, file and line number
   struct VS_TAG_BROWSE_INFO cm;
   _str proc_name;
   _str path;
   int LineNumber=0;
   if (_ProcTreeTagInfo(cm,proc_name,path,LineNumber,index)) {
      _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
   }
}

_command void proctree_references() name_info(','VSARG2_EDITORCTL)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   struct VS_TAG_BROWSE_INFO cm;
   _str proc_name;
   _str path;
   int LineNumber=0;
   if (_ProcTreeTagInfo(cm,proc_name,path,LineNumber) <= 0) {
      _message_box("References not available");
      return;
   }

   // check if the current workspace tag file or extension specific
   // tag file requires occurrences to be tagged.
   if (_MaybeRetagOccurrences(cm.tag_database) == COMMAND_CANCELLED_RC) {
      return;
   }

   // If form already exists, reuse it.  Otherwise, create it
   int formwid = _GetReferencesWID();
   if (!formwid) {
      if(!isEclipsePlugin()) {
         formwid=activate_toolbar("_tbtagrefs_form","");
      }
   }
   if (formwid) {
      _ActivateReferencesWindow();
   }

   // find the output references tab and update it
   int f = _GetReferencesWID();
   if (f && proc_name != '') {
      refresh_references_tab(cm,true);
   }
}

_command void proctree_calltree() name_info(','VSARG2_EDITORCTL)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   struct VS_TAG_BROWSE_INFO cm;
   _str proc_name;
   _str path;
   int LineNumber=0;
   if (_ProcTreeTagInfo(cm,proc_name,path,LineNumber) <= 0) {
      _message_box("Call tree not available");
      return;
   }
   // find the output references tab and update it
   int f = getProcTreeForm();
   if (f && proc_name != '') {
      f.show("-xy _cbcalls_form", cm);
   }
}

_command void proctree_props(int tab_number=0) name_info(','VSARG2_EDITORCTL)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   struct VS_TAG_BROWSE_INFO cm;
   _str proc_name;
   _str path;
   int LineNumber=0;
   if (_ProcTreeTagInfo(cm,proc_name,path,LineNumber) <= 0) {
      _message_box("Tag properties not available");
      return;
   }
   // find the output references tab and update it
   
   int f = activate_toolbar("_tbprops_form","");
   //tbShow("_tbprops_form");
   cb_refresh_property_view(cm);
   //int f=_find_formobj('_tbprops_form','N');
   _nocheck _control ctl_props_sstab;
   if (f) {
      f.ctl_props_sstab.p_ActiveTab = tab_number;
   }
}
_command void proctree_args() name_info(','VSARG2_EDITORCTL)
{
   proctree_props(1);
}

/**
 * Trigger a java refactoring operation for the currently
 * selected symbol in the proc tree
 *
 * @param params The refactoring to run
 */
_command void proctree_jrefactor(_str params = "") name_info(','VSARG2_EDITORCTL)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   struct VS_TAG_BROWSE_INFO cm;
   _str procName;
   _str path;
   int status,lineNumber = 0;
   if (_ProcTreeTagInfo(cm, procName, path, lineNumber) <= 0) {
      _message_box("Tag information not available");
      return;
   }

   // trigger the requested refactoring
   switch(params) {
         case "add_import":
         jrefactor_add_import(false, cm, _mdi.p_child.p_buf_name);
         break;
      case "organize_imports_options":
         jrefactor_organize_imports_options();
         break;
   }
}


/**
 * Trigger a refactoring operation for the currently
 * selected symbol in the proc tree
 *
 * @param params The refactoring to run
 */
_command void proctree_quick_refactor(_str params = "") name_info(','VSARG2_EDITORCTL)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   struct VS_TAG_BROWSE_INFO cm;
   _str procName;
   _str path;
   int status,lineNumber = 0;
   if (_ProcTreeTagInfo(cm, procName, path, lineNumber) <= 0) {
      _message_box("Tag information not available");
      return;
   }

   // trigger the requested refactoring
   switch(params) {
      case "quick_encapsulate_field":
         refactor_start_quick_encapsulate(cm);
         break;
      case "quick_rename":
         refactor_quick_rename_symbol(cm);
         break;
      case "quick_modify_params":
         if(cm.type_name == 'proto' || cm.type_name == 'procproto') {
            if(!refactor_convert_proto_to_proc(cm)) {
               _message_box("Cannot perform quick modify parameters refactoring because the function definition could not be found",
                            "Quick Modify Parameters");
               break;
            }
         }
         refactor_start_quick_modify_params(cm);
         break;

      // proctree doesn't have any info about local variables
      //case "local_to_field": break;
   }
}
/**
 * Trigger a refactoring operation for the currently
 * selected symbol in the proc tree
 *
 * @param params The refactoring to run
 */
_command void proctree_refactor(_str params = "") name_info(','VSARG2_EDITORCTL)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   struct VS_TAG_BROWSE_INFO cm;
   _str procName;
   _str path;
   int status,lineNumber = 0;
   if (_ProcTreeTagInfo(cm, procName, path, lineNumber) <= 0) {
      _message_box("Tag information not available");
      return;
   }

   // trigger the requested refactoring
   switch(params) {
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
         if(cm.type_name == 'proto' || cm.type_name == 'procproto') {
            if(!refactor_convert_proto_to_proc(cm)) {
               _message_box("Cannot perform modify parameters refactoring because the function definition could not be found",
                            "Modify Parameters");
               break;
            }
         }
         refactor_start_modify_params(cm);
         break;

      case "quick_modify_params":
         if(cm.type_name == 'proto' || cm.type_name == 'procproto') {
            if(!refactor_convert_proto_to_proc(cm)) {
               _message_box("Cannot perform quick modify parameters refactoring because the function definition could not be found",
                            "Quick Modify Parameters");
               break;
            }
         }
         refactor_start_quick_modify_params(cm);
         break;

      // proctree doesn't have any info about local variables
      //case "local_to_field": break;
   }
}

void _proc_tree.on_destroy()
{
   p_window_id=_mdi.p_child;
   int first=p_buf_id;
   for (;;) {
      p_ModifyFlags&=~MODIFYFLAG_PROCTREE_UPDATED;
      p_ModifyFlags&=~MODIFYFLAG_PROCTREE_SELECTED;
      _next_buffer('HR');
      if (p_buf_id==first) break;
   }
}

static void AddLanguageSpecificItems(int tree_index,int menu_handle)
{
   _str lang = getFileTreeLangId(tree_index);
   if (!_are_statements_supported(lang)) {
      _menu_set_state(menu_handle,"statements",MF_GRAYED,'C');
   }

   int depth=-1;
   int orig_tree_index=tree_index;
   if (tree_index <= TREE_ROOT_INDEX) {
      return;
   }
   for (;;) {
      tree_index=_TreeGetParentIndex(tree_index);
      depth=_TreeGetDepth(tree_index);
      if (depth<=proctree_file_depth()) {
         break;
      }
   }
   if (depth==-1 || depth<proctree_file_depth()) {
      // This is pretty paranoid, but if anything went wrong the loop
      // above would be inifinte
      return;
   }

   //int func_index=find_index('_'ext'_mod_proctree_menu',PROC_TYPE);
   func_index := _FindLanguageCallbackIndex('_%s_mod_proctree_menu',lang);
   if (func_index) {
      call_index(menu_handle,orig_tree_index,func_index);
   }
}

_proc_tree.rbutton_up()
{
   // kill the refresh timer, prevents delays before the menu comes
   // while the refreshes are finishing up.
   if (gProcTreeFocusTimerId!= -1) {
      _kill_timer(gProcTreeFocusTimerId);
      gProcTreeFocusTimerId=-1;
   }

   int orig_autotag_flags = def_autotag_flags2;
   def_autotag_flags2 = 0;
   _proc_tree.call_event(_proc_tree,LBUTTON_DOWN);
   int index=find_index("_tagbookmark_menu",oi2type(OI_MENU));
   int menu_handle=_mdi._menu_load(index,'P');
   index=_proc_tree._TreeCurIndex();
   if (def_proc_tree_options&PROC_TREE_SORT_FUNCTION) {
      _menu_set_state(menu_handle,"sortfunc",MF_CHECKED,'C');
   }else if (def_proc_tree_options&PROC_TREE_SORT_LINENUMBER) {
      _menu_set_state(menu_handle,"sortlinenum",MF_CHECKED,'C');
   }
   if (!(def_proc_tree_options&PROC_TREE_NO_STRUCTURE)) {
      _menu_set_state(menu_handle,"nesting",MF_CHECKED,'C');
   }

   // Have statements override the settings for sorting. If statements
   // are on only sort by line number should be supported.
   lang := getFileTreeLangId(index);
   if (def_proc_tree_options&PROC_TREE_STATEMENTS && _are_statements_supported(lang)) {
      _menu_set_state(menu_handle,"statements",MF_CHECKED,'C');
      _menu_set_state(menu_handle,"sortlinenum",MF_CHECKED|MF_GRAYED,'C');
      _menu_set_state(menu_handle,"sortfunc",MF_UNCHECKED,'C');
      _menu_set_state(menu_handle,"sortfunc",MF_GRAYED,'C');
   } else{
      _menu_set_state(menu_handle,"statements",MF_UNCHECKED,'C');
      _menu_set_state(menu_handle,"filter_statements",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"all_statements",MF_GRAYED,'C');
   }

   if (def_proc_tree_options&PROC_TREE_AUTO_EXPAND) {
      _menu_set_state(menu_handle,"autoexpand",MF_CHECKED,'C');
      //_menu_set_state(menu_handle,"expandchildren",MF_GRAYED,'C');
      //_menu_set_state(menu_handle,"expandonelevel",MF_GRAYED,'C');
      //_menu_set_state(menu_handle,"expandtwolevels",MF_GRAYED,'C');
   }else{
      _menu_set_state(menu_handle,"autoexpand",MF_UNCHECKED,'C');
   }

   if (def_proc_tree_options&PROC_TREE_ONLY_TAGGABLE) {
      _menu_set_state(menu_handle,"nontaggable",MF_UNCHECKED,'C');
   }else{
      _menu_set_state(menu_handle,"nontaggable",MF_CHECKED,'C');
   }
   if (def_proc_tree_options&PROC_TREE_NO_BUFFERS) {
      if (!isEclipsePlugin()) {
         _menu_set_state(menu_handle,"showfiles",MF_UNCHECKED,'C');
      } else {
         _menu_set_state(menu_handle,"showfiles",MF_GRAYED,'C');
      }
      _menu_set_state(menu_handle,"nontaggable",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"autoexpand",MF_GRAYED,'C');
   }else{
      _menu_set_state(menu_handle,"showfiles",MF_CHECKED,'C');
   }
   if (index<=0 || _proc_tree._TreeGetDepth(index) <= proctree_file_depth()) {
      _menu_set_state(menu_handle,"properties",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"arguments",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"references",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"calltree",MF_GRAYED,'C');
   } else if (!pos('(',_proc_tree._TreeGetCaption(index))) {
      _menu_set_state(menu_handle,"arguments",MF_GRAYED,'C');
   }

   // configure the display filtering flags
   pushTgConfigureMenu(menu_handle, def_proctree_flags, true, false, false, true);

   AddLanguageSpecificItems(index,menu_handle);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // populate refactoring submenu
   struct VS_TAG_BROWSE_INFO refcm;
   _str procName, path;
   int lineNumber = 0;
   if(_ProcTreeTagInfo(refcm, procName, path, lineNumber, index) > 0) {
      addCPPRefactoringMenuItems(menu_handle, "proctree", refcm);
      addQuickRefactoringMenuItems(menu_handle, "proctree", refcm);
   } else {
      addCPPRefactoringMenuItems(menu_handle, "proctree", null);
      addQuickRefactoringMenuItems(menu_handle, "proctree", null);
   }

   // populate organize imports submenu
   struct VS_TAG_BROWSE_INFO oicm;
   if(_ProcTreeTagInfo(oicm, procName, path, lineNumber, index) > 0) {
      addOrganizeImportsMenuItems(menu_handle, "proctree", oicm, false, _mdi.p_child.p_buf_name);
   } else {
      addOrganizeImportsMenuItems(menu_handle, "proctree", null, false, _mdi.p_child.p_buf_name);
   }

   int x,y;
   mou_get_xy(x,y);
   _KillToolButtonTimer();
   int DelaySetting=0;
   TreeDisablePopup(DelaySetting);
   
   call_list('_on_popup2_',translate("_tagbookmark_menu",'_','-'),menu_handle);

   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   def_autotag_flags2 = orig_autotag_flags;
   _menu_destroy(menu_handle);
   TreeEnablePopup(DelaySetting);
}

static void DeleteUntaggableFileNodes(int index)
{
   _str filename=_TreeGetCaption(index);

   //We don't want to delete files that that have a taggable mode different
   //from the extension
   int temp_view_id=0,orig_view_id=0;
   int status=_open_temp_view('',temp_view_id,orig_view_id,'+bi '_TreeGetUserInfo(index));
   if (status) return;
   _str lang = p_LangId;
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   if (!_istagging_supported(lang)) {
      if (index > 0) {
         _TreeDelete(index);
      } else {
         _TreeDelete(index,'c');
      }
   }
}

static void AddUntaggableFiles()
{
   int first=_mdi.p_child.p_buf_id;
   int index=0;
   int longest=0;
   for (;;) {
      _mdi.p_child._next_buffer('HR');
      _str restore_filename=editor_name('p'):+_WINDOW_CONFIG_FILE;
      if (!(_mdi.p_child.p_buf_flags&VSBUFFLAG_HIDDEN) &&
          !(file_eq(_strip_filename(_mdi.p_child._GetDocumentName(),'P'),_WINDOW_CONFIG_FILE))) {
         index=MaybeAddFilename(_mdi.p_child._GetDocumentName(),_mdi.p_child.p_buf_id);
      }
      if (_mdi.p_child.p_buf_id==first) break;
   }
   if (index>=0) {
      _TreeSetCurIndex(index);
   }
}

static void CollapseAll(int index)
{
   if (index > 0 && TaggingSupportedForFileNode(index)) {
      _TreeSetInfo(index,0);
   }
}

static void ExpandAll(int index)
{
   if (TaggingSupportedForFileNode(index)) {
      _TreeSetInfo(index,1);
   }
}

static void TraverseFiles(typeless pfn)
{
   int index=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      if (index<0) break;
      int nextindex=_TreeGetNextSiblingIndex(index);
      (*pfn)(index);
      index=nextindex;
   }
}

_command ProcTreeRunMenu() name_info(','VSARG2_CMDLINE)
{
   if (arg(1)=='') {
      return('');
   }
   _str FormName=p_active_form.p_name;
   int olddef_proc_tree_sort=def_proc_tree_options;
   int olddef_tag_select_sort=def_tag_select_options;
   _str filename=_strip_filename(_mdi.p_child._GetDocumentName(),'P');
   _str path=_mdi.p_child._GetDocumentName();
   if (IsSpecialFile(path)) filename=path;
   int index=FindNode(filename,_mdi.p_child.p_buf_id);

   switch (lowcase(arg(1))) {
   case 'sortfunc':
      if (FormName=='_tag_select_form') {
         def_tag_select_options|=PROC_TREE_SORT_FUNCTION;
         def_tag_select_options&=~PROC_TREE_SORT_LINENUMBER;
      } else {
         def_proc_tree_options|=PROC_TREE_SORT_FUNCTION;
         def_proc_tree_options&=~PROC_TREE_SORT_LINENUMBER;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      break;
   case 'sortlinenum':
      if (FormName=='_tag_select_form') {
         def_tag_select_options|=PROC_TREE_SORT_LINENUMBER;
         def_tag_select_options&=~PROC_TREE_SORT_FUNCTION;
      } else {
         def_proc_tree_options|=PROC_TREE_SORT_LINENUMBER;
         def_proc_tree_options&=~PROC_TREE_SORT_FUNCTION;
      }
      break;
   case 'hierarchy':
   case 'nesting':
      if (def_proc_tree_options&PROC_TREE_NO_STRUCTURE) {
         def_proc_tree_options&=~PROC_TREE_NO_STRUCTURE;
      }else{
         def_proc_tree_options|=PROC_TREE_NO_STRUCTURE;
      }
      if (index!=_TreeCurIndex() && index>=0) {
         TraverseFiles(CollapseAll);
         if (index > 0 && TaggingSupportedForFileNode(index)) {
            _TreeSetInfo(index,0);
         }
      }
      break;
   case 'statements':
      if (def_proc_tree_options&PROC_TREE_STATEMENTS) {
         def_proc_tree_options&=~PROC_TREE_STATEMENTS;
      }else{
         // Turn off sort by function name and turn on sort by line number when turning
         // on statements
         if (FormName=='_tag_select_form') {
            def_tag_select_options|=PROC_TREE_SORT_LINENUMBER;
            def_tag_select_options&=~PROC_TREE_SORT_FUNCTION;
         } else {
            def_proc_tree_options|=PROC_TREE_SORT_LINENUMBER;
            def_proc_tree_options&=~PROC_TREE_SORT_FUNCTION;
         }
         def_proc_tree_options|=PROC_TREE_STATEMENTS;
      }

      if (index!=_TreeCurIndex() && index>=0) {
         TraverseFiles(CollapseAll);
         if (index > 0 && TaggingSupportedForFileNode(index)) {
            _TreeSetInfo(index,0);
         }
      }
      break;

   case 'autoexpand':
      if (def_proc_tree_options&PROC_TREE_AUTO_EXPAND) {
         def_proc_tree_options&=~PROC_TREE_AUTO_EXPAND;
         TraverseFiles(CollapseAll);
      }else{
         def_proc_tree_options|=PROC_TREE_AUTO_EXPAND;
         if (index!=_TreeCurIndex() && index>=0) {
            TraverseFiles(CollapseAll);
            if (TaggingSupportedForFileNode(index)) {
               _TreeSetInfo(index,1);
            }
         }
      }
      break;

   case 'expandchildren':
         proctree_expand_children();
      break;

   case 'expandonelevel':
         proctree_expand_onelevel();
      break;

   case 'expandtwolevels':
         proctree_expand_twolevels();
      break;

   case 'nontaggable':
      if (def_proc_tree_options&PROC_TREE_ONLY_TAGGABLE) {
         def_proc_tree_options&=~PROC_TREE_ONLY_TAGGABLE;
         AddUntaggableFiles();
      }else{
         def_proc_tree_options|=PROC_TREE_ONLY_TAGGABLE;
         TraverseFiles(DeleteUntaggableFileNodes);
      }
      break;
   case 'showfiles':
      if (def_proc_tree_options&PROC_TREE_NO_BUFFERS) {
         def_proc_tree_options&=~PROC_TREE_NO_BUFFERS;
      }else{
         def_proc_tree_options|=PROC_TREE_NO_BUFFERS;
      }
      _TreeDelete(TREE_ROOT_INDEX,'c');
      proctree_update_buffers();

      // Set last buf_id to something invalid so that _UpdateCurrentTag()
      // knows it is filling in the tree for the first time.
      proctreeLastBufId(0);
      // Set last line number to current MDI child's line number so that
      // _UpdateCurrentTag() knows NOT to find the current tag in the tree.
      proctreeLastLinenum(_mdi.p_child.p_RLine);
      // Make the Procs tree believe it is selected so that _UpdateCurrentTag()
      // does not try to expand to the current tag.
      _mdi.p_child.p_ModifyFlags |= MODIFYFLAG_PROCTREE_SELECTED;

      _UpdateCurrentTag(true);
      index=FindNode(filename,_mdi.p_child.p_buf_id);
      break;
   }
   if (olddef_tag_select_sort!=def_tag_select_options) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _tagselect_refresh_symbols();
      _macro('m',_macro('s'));
      _macro_append("def_tag_select_options="def_tag_select_options";");
   }
   if (olddef_proc_tree_sort!=def_proc_tree_options && !_no_child_windows()) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _mdi.p_child._ProcTreeOptionsChanged();
      _mdi.p_child._UpdateCurrentTag(true);
      if (index>=0) {
         SortProcTree(index,def_proc_tree_options);
         // Do not expand the index here. Let _UpdateCurrentTag() take care
         // of it on the timer. This is necessary because toggling "Display Files" off
         // when "Auto Expand" is off should NOT expand the tree.
         //_TreeSetInfo(index,1);
      }
      _macro('m',_macro('s'));
      _macro_append("def_proc_tree_options="def_proc_tree_options";");
   }
   _mdi.p_child._set_focus();
}

void _ProcTreeOptionsChanged()
{
   _safe_hidden_window();
   int view_id;
   save_view(view_id);
   int first_buf_id=p_buf_id;
   for (;;) {
      if (!(p_buf_flags&VSBUFFLAG_HIDDEN)) {
         p_ModifyFlags &= ~(MODIFYFLAG_PROCTREE_UPDATED|MODIFYFLAG_PROCTREE_SELECTED);
      }
      _next_buffer('HNR');
      if (p_buf_id == first_buf_id) {
         break;
      }
   }
   activate_window(view_id);
}

void _xml_mod_proctree_menu(int menu_handle,int tree_index)
{
   if (_no_child_windows()) {
      return;
   }
   int state,bm1,bm2;
   _TreeGetInfo(tree_index,state,bm1,bm2);

   _str delete_menu_caption='';
   _str delete_help_caption='';
   _str xml_delete_command='ProcTreeXMLRunMenu delete';
   if (bm1==_pic_xml_tag || bm1==_pic_xml_target) {
      delete_menu_caption=nls("Delete Element");
      delete_help_caption=nls("Deletes this element");
   }else if (bm1==_pic_xml_attr) {
      delete_menu_caption=nls("Delete Attribute");
      delete_help_caption=nls("Deletes this attribute");
   }
   int num_items_added=0;
   int status=0;
   int buffer_ro_status=(_mdi.p_child._QReadOnly()? MF_GRAYED:MF_ENABLED);
   status=_menu_insert(menu_handle,num_items_added,buffer_ro_status,
                       delete_menu_caption,xml_delete_command,"ncw",
                       "popup-imessage "delete_help_caption,
                       delete_help_caption
                       );
   ++num_items_added;
   if (bm1==_pic_xml_tag || bm1==_pic_xml_target) {
      status=_menu_insert(menu_handle,num_items_added,buffer_ro_status,
                          "Add Element...","ProcTreeXMLRunMenu addelement","ncw",
                          "popup-imessage "nls('Add an element'),
                          'Add an element'
                          );
      ++num_items_added;
   }
   status=_menu_insert(menu_handle,num_items_added,buffer_ro_status,
                       "Add Attribute...","ProcTreeXMLRunMenu addattr","ncw",
                       "popup-imessage "nls('Add an attribute'),
                       'Add element'
                       );
   ++num_items_added;
   status=_menu_insert(menu_handle,num_items_added,MF_ENABLED,
                       "XPath search...","ProcTreeXMLRunMenu xpathsearch","ncw",
                       "popup-imessage "nls('Run an XPath search'),
                       'XPath search'
                       );
   ++num_items_added;
   _menu_insert(menu_handle,num_items_added,MF_ENABLED,"-");
}

static boolean is_invalid_xml_element_name(_str name)
{
   _str ch=substr(name,1,1);
   /*if (!isalpha(ch) && ch!='_') {
      _message_box(nls("Element names must start with letters or '_'"));
      return(true);
   }*/
   // Cannot start with "xml" in any case
   if (strieq('xml',substr(name,1,3))) {
      _message_box(nls("Element names cannot start with XML"));
      return(true);
   }
   // Other characters that cannot be in the string
   if (pos(' <>=',substr(name,2))) {
      _message_box(nls("Element names cannot contain space,'<','>', or '='"));
      return(true);
   }
   return(false);
}

static boolean is_invalid_xml_attribute_name(_str name)
{
   _str ch=substr(name,1,1);
   /*if (!isalpha(ch) && ch!='_') {
      _message_box(nls("Element names must start with letters or '_'"));
      return(true);
   }*/
   // Other characters that cannot be in the string
   if (pos(' <>=',substr(name,2))) {
      _message_box(nls("Element names cannot contain space,'<','>', or '='"));
      return(true);
   }
   return(false);
}

_command void ProcTreeXMLRunMenu(_str command_name='')
{
   if (command_name=='' || p_name!='_proc_tree') return;

   switch (lowcase(command_name)) {
   case 'delete' :
      DeleteCurTagInProcTreeXML();
      break;
   case 'addattr' :
      AddAttribute();
      break;
   case 'addelement' :
      AddElement();
      break;
   case 'xpathsearch' :
      XPathSearch();
      break;
   }
}

static int GetFileIndexFromProcTree()
{
   int file_index=_TreeCurIndex();
   while (_TreeGetDepth(file_index) != proctree_file_depth()) {
      file_index=_TreeGetParentIndex(file_index);
   }
   return(file_index);
}

static void maybe_go_left()
{
   left();
   _str left_char=get_text(-1);
   if (left_char:!='/') {
      right();
   }
}
static void AddAttribute()
{
   _str result = show('-modal _textbox_form',
                      'Add Attribute', // Form caption
                      TB_RETRIEVE_INIT,  //flags
                      '', //use default textbox width
                      '', //Help item.
                      '', //Buttons and captions
                      'add_attribute', //Retrieve Name
                      '-e 'is_invalid_xml_element_name' Attribute name:',
                      'Attribute value:'
                     );
   if ( result=='' ) {
      return;
   }
   _str attribute_name=_param1;
   _str attribute_value=_param2;

   int file_index=GetFileIndexFromProcTree();
   _str filename=_TreeGetCaption(file_index);

   int tree_index,state,bm1,bm2;
   tree_index=_TreeCurIndex();

   boolean node_is_attribute=false;
   _TreeGetInfo(tree_index,state,bm1,bm2);
   if (bm1==_pic_xml_attr) {
      node_is_attribute=true;
   }

   boolean multi_line_begin_tag=false;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   struct VS_TAG_BROWSE_INFO cm;
   _str proc_name;
   _str path;
   int LineNumber=0;
   int context_id=_ProcTreeTagInfo(cm,proc_name,path,LineNumber);
   if (context_id <= 0) return;

   int parent_context_id;
   if (node_is_attribute) {
      tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, parent_context_id);
   }else {
      parent_context_id=context_id;
   }

   int wid=p_window_id;
   p_window_id=_mdi.p_child;

   _str start_linenum;
   _str start_seek_pos;
   _str end_of_begin_seek_pos;
   _str end_linenum;
   tag_get_detail2(VS_TAGDETAIL_context_start_linenum, parent_context_id, start_linenum);

   tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, parent_context_id, end_of_begin_seek_pos);
   save_pos(auto p);
   _GoToROffset((long)end_of_begin_seek_pos);
   end_linenum=p_line;
   restore_pos(p);

   multi_line_begin_tag=start_linenum!=end_linenum;

   _str quote_char='"';
   if (pos('"',attribute_value)) {
      quote_char="'";
   }

   if (multi_line_begin_tag) {
      _GoToROffset((long)end_of_begin_seek_pos);
      left();
      maybe_go_left();
      split_line();
      down();
      // When we split the line, the > moved down, so if we call
      // first_non_blank, this will put us right at the beginning.
      first_non_blank();
      _insert_text(attribute_name'='quote_char:+attribute_value:+quote_char);
   }else{
      int end_seek_pos;
      tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, parent_context_id, end_seek_pos);
      _GoToROffset(end_seek_pos);
      left();
      maybe_go_left();
      _insert_text(' 'attribute_name'='quote_char:+attribute_value:+quote_char);
   }
   _set_focus();
   p_window_id=wid;
}

/**
 * Made to work with the proctree.  File to be searched must be the active mdi
 * child.
 */
static void XPathSearch()
{
   _str result = show('-modal _textbox_form',
                      'XPath Search', // Form caption
                      TB_RETRIEVE_INIT,  //flags
                      '', //use default textbox width
                      '', //Help item.
                      '', //Buttons and captions
                      'xpathsearch', //Retrieve Name
                      'XPath search string:'
                     );
   if ( result=='' ) {
      return;
   }
   _str xpath_query=_param1;

   int file_index=GetFileIndexFromProcTree();
   _str filename=_TreeGetCaption(file_index);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   struct VS_TAG_BROWSE_INFO cm;
   _str proc_name;
   _str path;
   int LineNumber=0;
   _ProcTreeTagInfo(cm,proc_name,path,LineNumber);

   if( def_proc_tree_options&PROC_TREE_STATEMENTS )
      _mdi.p_child._UpdateContext(true,false, VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);
   else
      _mdi.p_child._UpdateContext(true,false, VS_UPDATEFLAG_context );

   int status=0;
   int xml_handle=_xmlcfg_open_from_buffer(_mdi.p_child,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if (xml_handle<0) {
      _message_box(nls("Could not open file '%s'\n\n%s",filename,get_message(status)));
      return;
   }
   typeless found_indexes[]=null;
   status=_xmlcfg_find_simple_array(xml_handle,xpath_query,found_indexes);

   int wid=p_window_id;
   p_window_id=_mdi.p_child;

   long path_table:[]=null;
   _str path_list[]=null;
   int bm_list[]=null;

   save_pos(auto p);
   int i,len=found_indexes._length();
   for (i=0;i<len;++i) {
      long seekpos;
      _xmlcfg_get_seekpos_from_node(xml_handle,found_indexes[i],status,seekpos);
      if (!status) {
         _GoToROffset(seekpos);
         path=GetWholePath(xml_handle,found_indexes[i]);
         if (_xmlcfg_get_type(xml_handle,found_indexes[i])==VSXMLCFG_NODE_ATTRIBUTE) {
            bm_list[i]=_pic_xml_attr;
         }else{
            bm_list[i]=_pic_xml_tag;
         }
         path_table:[path"\t"p_line]=seekpos;
         path_list[i]=path"\t"p_line;
      }
   }
   restore_pos(p);
   if (path_list._length()) {
      result=select_tree(path_list,null,bm_list,bm_list,null,null,null,null,0,"Path,Line Number",(TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT)','(TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_NUMBERS));
      if (result!='' && result!=COMMAND_CANCELLED_RC) {
         long new_seekpos=path_table:[result];
         if (new_seekpos!=null) {
            _GoToROffset(new_seekpos);
         }
      }
   }

   p_window_id=wid;
   _xmlcfg_close(xml_handle);
}


static _str GetWholePath(int xml_handle,int xml_index)
{
   _str cap='';
   int last_node_type=_xmlcfg_get_type(xml_handle,xml_index);
   _str name=_xmlcfg_get_name(xml_handle,xml_index);
   _str path_separator='/';
   if (last_node_type==VSXMLCFG_NODE_ATTRIBUTE) {
      cap='@'name;
      path_separator='';
   }else{
      cap=name;
   }
   for (;;) {
      xml_index=_xmlcfg_get_parent(xml_handle,xml_index);
      if (xml_index==TREE_ROOT_INDEX) break;
      cap=_xmlcfg_get_name(xml_handle,xml_index):+path_separator:+cap;
      path_separator='/';
   }
   cap=path_separator:+cap;
   return(cap);
}

static void DeleteCurTagInProcTreeXML()
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   if( def_proc_tree_options&PROC_TREE_STATEMENTS )
      _mdi.p_child._UpdateContext(true,false, VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);
   else
      _mdi.p_child._UpdateContext(true,false, VS_UPDATEFLAG_context );

   int file_index=_TreeCurIndex();
   while (_TreeGetDepth(file_index) != proctree_file_depth()) {
      file_index=_TreeGetParentIndex(file_index);
   }
   _str filename=_TreeGetCaption(file_index);

   struct VS_TAG_BROWSE_INFO cm;
   _str proc_name;
   _str path;
   int LineNumber=0;
   int context_id = _ProcTreeTagInfo(cm,proc_name,path,LineNumber);
   if (context_id <= 0) return;

   int wid=p_window_id;
   p_window_id=_mdi.p_child;
   int markid=_alloc_selection();
   _GoToROffset(cm.seekpos);
   int status=_select_char(markid);
   if (status) {
      clear_message();
      return;
   }
   int first_line=p_line;
   status=_GoToROffset(cm.end_seekpos);
   if (status) {
      clear_message();
      return;
   }
   status=_select_char(markid);
   if (status) {
      clear_message();
      return;
   }
   _delete_selection(markid);
   _free_selection(markid);

   p_line=first_line;
   get_line(auto line);
   if (strip(line)=='') {
      _delete_line();
   }
   first_non_blank();

   _set_focus();
   p_window_id=wid;
}

static void AddElement()
{
   _str result = show('-modal _xml_add_element_form');
   if ( result=='' ) {
      return;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   if( def_proc_tree_options&PROC_TREE_STATEMENTS )
      _mdi.p_child._UpdateContext(true,false, VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);
   else
      _mdi.p_child._UpdateContext(true,false, VS_UPDATEFLAG_context );

   _str element_name=_param1;
   int end_tag_required=_param2;
   int node_type=end_tag_required?VSXMLCFG_NODE_ELEMENT_START_END:VSXMLCFG_NODE_ELEMENT_START;

   int file_index=GetFileIndexFromProcTree();
   _str filename=_TreeGetCaption(file_index);

   struct VS_TAG_BROWSE_INFO cm;

   int wid=p_window_id;
   p_window_id=_mdi.p_child;
   _str proc_name;
   _str path;
   int LineNumber=0;
   int context_id = _ProcTreeTagInfo(cm,proc_name,path,LineNumber);
   if (context_id <= 0) return;
   _GoToROffset(cm.end_seekpos);
   left();

   left();
   boolean split_current_tag=(get_text(-1):=='/');
   right();

   _str indent_amount = LanguageSettings.getSyntaxIndent(_edit_window().p_LangId);

   _str element_tag='';
   if (end_tag_required) {
      element_tag='<'element_name'></'element_name'>';
   }else{
      element_tag='<'element_name'/>';
   }

   // remove the / at the end of the tag and insert a new end tag
   if (split_current_tag) {
      // use the line where the tag starts to get the indent_str
      typeless cur_pos;
      save_pos(cur_pos);
      p_line=cm.line_no;
      get_line(auto cur_line);
      restore_pos(cur_pos);
      _str indent_str='';
      int p=pos('[~\t ]',cur_line,1,'r');
      if (p>1) {
         indent_str=substr(cur_line,1,p-1);
      }
      get_line(cur_line);
      int cursor_offset=text_col(cur_line,p_col,'P');
      _str leading=substr(cur_line,1,cursor_offset-2);
      _str trailing=substr(cur_line,cursor_offset+1);
      if (cm.line_no!=cm.end_line_no) {
         replace_line(leading'>');
         insert_line(indent_str'</'proc_name'>'trailing);
         p_col=text_col(indent_str'</'proc_name);
      } else {
         replace_line(leading'></'proc_name'>'trailing);
      }
   }

   if (cm.line_no!=cm.end_line_no) {
      // use the line where the tag starts to get the indent_str
      typeless cur_pos;
      save_pos(cur_pos);
      p_line=cm.line_no;
      get_line(auto cur_line);
      restore_pos(cur_pos);
      _str indent_str='';
      int p=pos('[~\t ]',cur_line,1,'r');
      if (p>1) {
         indent_str=substr(cur_line,1,p-1);
      }
      int new_indent_length=length(indent_str)+(int)indent_amount;
      indent_str=indent_string(new_indent_length);
      up();
      insert_line(indent_str:+element_tag);
      p_col=length(expand_tabs(indent_str))+length(element_name)+3;
   }else{
      _GoToROffset(cm.end_seekpos);
      if (split_current_tag) {
         p_col+=2;
      }
      save_pos(auto p);
      int status=search('/','@hck-');
      if (status || p_line!=cm.line_no) {
         restore_pos(p);
         // If we don't find it in keyword color, look for it in unknown color
         status=search('/','@hcu-');
      }
      if (p_line!=cm.line_no && !split_current_tag) {
         // If this happens, we are in pretty bad shape. Better to do nothing.
         restore_pos(p);
         status=1;
      }
      if (!status) {
         left();
         _insert_text(element_tag);
         if (end_tag_required) {
            p_col-=length(element_name)+3;
         }
      }
   }
   p_window_id=wid;
   _mdi.p_child._set_focus();
}

static void ReplaceXMLBuffer(int xml_handle)
{
   delete_all();
   int indent;
   if (p_indent_with_tabs) {
      indent=-1;
   }else{
      indent=LanguageSettings.getSyntaxIndent(_edit_window()p_LangId);
   }
   _xmlcfg_save_to_buffer(0,xml_handle,indent,VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR);
   _set_focus();
   p_ModifyFlags=0;
}

static int OpenXMLBufferAndFindNode(_str filename,long seekpos,int &xml_handle,int &xml_index)
{
   int status;
   xml_handle=-1;xml_index=-1;
   xml_handle=_xmlcfg_open_from_buffer(_mdi.p_child,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if (xml_handle>-1) {
      xml_index=_xmlcfg_get_node_from_seekpos(xml_handle,seekpos);
   }
   if (xml_index<0) {
      _xmlcfg_close(xml_handle);
      xml_handle=-1;
   }
   return(status);
}

defeventtab _xml_add_element_form;

void ctlok.on_create()
{
   _retrieve_prev_form();
}

void ctlok.lbutton_up()
{
   if (is_invalid_xml_element_name(ctlelement_name.p_text)) {
      ctlelement_name._text_box_error(nls('%s is not a valid element name',ctlelement_name.p_text));
      return;
   }
   _save_form_response();
   _param1=ctlelement_name.p_text;
   _param2=ctlstart_end.p_value;
   p_active_form._delete_window(0);
}

// Expand children index node to the specified level.
// Assumes that the active window is a tree control.
static void expandToLevel(int index, int level)
{
   if( level<0 ) {
      return;
   }
   if( level==0 ) {
      // Collapse all children
      do_collapse_children(index);
      return;
   }

   int show_children;
   _TreeGetInfo(index,show_children);
   if( show_children==0 ) {
      _TreeSetInfo(index,1);
   }

   int child = _TreeGetFirstChildIndex(index);
   while( child>0 ) {
      expandToLevel(child,level-1);
      child=_TreeGetNextSiblingIndex(child);
   }
}

/**
 * Expand the current file's children by 1 level.
 * <p>
 * Optionally pass in the tree window id and index to expand
 * as arg(1) and arg(2) respectively. Otherwise, the tree window
 * id and index are calculated.
 * </p>
 */
_command void proctree_expand_onelevel() name_info(','VSARG2_EDITORCTL)
{
   int treeWid;
   if( arg(1)!="" && isinteger(arg(1)) ) {
      treeWid=(int)arg(1);
   } else {
      treeWid=GetProcTreeWID();
   }
   if( !treeWid ) return;

   int index;
   if( arg(2)!="" && isinteger(arg(2)) ) {
      index=(int)arg(2);
   } else {
      index=getFileTreeIndex(treeWid._TreeCurIndex());
   }
   if( index<0 ) return;

   mou_hour_glass(1);
   treeWid.p_redraw=false;

   treeWid.expandToLevel(index,1);
   treeWid._TreeSetCurIndex(treeWid._TreeCurIndex());

   treeWid.p_redraw=true;
   treeWid._TreeRefresh();
   mou_hour_glass(0);
}

/**
 * Expand the current file's children by 2 levels.
 * <p>
 * Optionally pass in the tree window id and index to expand
 * as arg(1) and arg(2) respectively. Otherwise, the tree window
 * id and index are calculated.
 * </p>
 */
_command void proctree_expand_twolevels() name_info(','VSARG2_EDITORCTL)
{
   int treeWid;
   if( arg(1)!="" && isinteger(arg(1)) ) {
      treeWid=(int)arg(1);
   } else {
      treeWid=GetProcTreeWID();
   }
   if( !treeWid ) return;

   int index;
   if( arg(2)!="" && isinteger(arg(2)) ) {
      index=(int)arg(2);
   } else {
      index=getFileTreeIndex(treeWid._TreeCurIndex());
   }
   if( index<0 ) return;

   mou_hour_glass(1);
   treeWid.p_redraw=false;

   treeWid.expandToLevel(index,2);
   treeWid._TreeSetCurIndex(treeWid._TreeCurIndex());

   treeWid.p_redraw=true;
   treeWid._TreeRefresh();
   mou_hour_glass(0);
}

/**
 * Expand the current file's children recursively.
 * <p>
 * Optionally pass in the tree window id and index to expand
 * as arg(1) and arg(2) respectively. Otherwise, the tree window
 * id and index are calculated.
 * </p>
 */
_command void proctree_expand_children() name_info(','VSARG2_EDITORCTL)
{
   int treeWid;
   if( arg(1)!="" && isinteger(arg(1)) ) {
      treeWid=(int)arg(1);
   } else {
      treeWid=GetProcTreeWID();
   }
   if( !treeWid ) return;

   int index;
   if( arg(2)!="" && isinteger(arg(2)) ) {
      index=(int)arg(2);
   } else {
      index=getFileTreeIndex(treeWid._TreeCurIndex());
   }
   if( index<0 ) return;

   mou_hour_glass(1);
   treeWid.p_redraw=false;

   int count = 0;
   treeWid.do_expand_children(index,count,false);

   treeWid.p_redraw=true;
   mou_hour_glass(0);
}

/**
 * Set a breakpoint or watchpoing on the current item selected
 * in the "Defs" tool window.
 */
_command int proctree_set_breakpoint() name_info(','VSARG2_EDITORCTL)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   struct VS_TAG_BROWSE_INFO cm;
   _str proc_name;
   _str path;
   int LineNumber=0;
   if (_ProcTreeTagInfo(cm,proc_name,path,LineNumber) <= 0) {
      _message_box("Set breakpoint requires a symbol.");
      return 0;
   }

   return debug_set_breakpoint_on_tag(cm);
}

