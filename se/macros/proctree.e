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
#import "se/lang/api/LanguageSettings.e"
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
#import "help.e"
#import "jrefactor.e"
#import "listproc.e"
#import "main.e"
#import "math.e"
#import "picture.e"
#import "pushtag.e"
#import "quickrefactor.e"
#import "recmacro.e"
#import "refactor.e"
#import "seldisp.e"
#import "sellist.e"
#import "seltree.e"
#import "setupext.e"
#import "stdprocs.e"
#import "stdcmds.e"
#import "tagcalls.e"
#import "tagform.e"
#import "taggui.e"
#import "tagrefs.e"
#import "tags.e"
#import "tagwin.e"
#import "tbfind.e"
#import "toolbar.e"
#import "treeview.e"
#import "tbxmloutline.e"
#import "util.e"
#import "se/ui/toolwindow.e"
#import "se/ui/mainwindow.e"
#endregion

using se.lang.api.LanguageSettings;

defeventtab _tbproctree_form;

_tbproctree_form."F12"()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   } else if (def_keys == "eclipse-keys") {
      activate_editor();
   }
}

_tbproctree_form."C-M"()
{
   if (isEclipsePlugin()) {
      eclipse_maximize_part();
   }
}

//Trying to keep these together since we cant tag'em
static const TBPROCTREE_FORM= "_tbproctree_form";

// Key for per-buffer information whether to show statements or not
static const TBPROCTREE_SHOW_STATEMENTS_KEY= "ShowStatements";

// Key for per-buffer information what level to expand symbosl to
static const TBPROCTREE_EXPAND_LEVEL_KEY= "ExpandLevel";

//////////////////////////////////////////////////////////////////////////////
// Timer used for delaying updates after change-selected events,
// allowing you to quickly scroll through the items in the proc-tree
// It is safer for this to global instead of static.
//
int gProcTreeFocusTimerId = -1;

////////////////////////////////////////////////////////////////////////////// 
// Indicates that a switchbuf even happened, so we should not delay updating.
// We use this so that if a large number of files are opened in a batch,
// we only update the proc tree for the final one, as soon as the normal
// timer event comes along, rather than forcing an update for each and every one.
//
bool gProcTreeSwitchBufHappened = false;


struct DEFS_FORM_INFO {
   int m_form_wid;
   //int m_last_buf_id;
   int m_LastModified;
   int m_RLine;
   int m_RLine_LastModified;
};
static DEFS_FORM_INFO gDefsFormList:[];

static void _init_all_formobj(DEFS_FORM_INFO (&formList):[],_str formName) {
   int last = _last_window_id();
   int i;
   for (i=1; i<=last; ++i) {
      if (_iswindow_valid(i) && i.p_object == OI_FORM && !i.p_edit) {
         if (i.p_name:==formName) {
            formList:[i].m_form_wid=i;
            formList:[i].m_LastModified= -1;
            formList:[i].m_RLine= -1;
            formList:[i].m_RLine_LastModified= -1;
            //wid = i;
            //break;
         }
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
      gProcTreeFocusTimerId=-1;
      gProcTreeSwitchBufHappened=false;
   }
   gDefsFormList._makeempty();
   _init_all_formobj(gDefsFormList,TBPROCTREE_FORM);
}

/**
 * Get the proc tree WID. This normally comes from the Project toolbar
 * but can also come from the Eclipse plugin proc tree.
 *
 * @return proc tree
 */
int _tbGetActiveDefsForm()
{
   if (!_haveDefsToolWindow()) return 0;
   return tw_find_form(TBPROCTREE_FORM);
}

bool IsSpecialFile(_str a)
{
   a=strip(a,'b','"');
   return(a=="" ||
          beginsWith(a,".process") ||
          a=="Build (.process)" ||
          beginsWith(a,"Terminal (") ||
          substr(a,1,7)  == ".search" ||
          substr(a,1,7)  == "Search<" ||
          substr(a,1,7)  == "List of" ||
          substr(a,1,12) == "Directory of");
}

static void StoreSortOptions(_str Path, DefsToolWindowOptions BufferOptions)
{
   int OptionsTable:[];
   OptionsTable=p_user;
   temp := BufferOptions;
   temp &= ~(PROC_TREE_AUTO_EXPAND);
   Path=strip(Path,'B','"');
   OptionsTable:[Path]=temp;
   p_user=OptionsTable;
}

static DefsToolWindowOptions GetSortOptions(_str Path)
{
   Path=strip(Path,'B','"');
   int OptionsTable:[];
   OptionsTable=p_user;
   if (OptionsTable._varformat()!=VF_HASHTAB) {
      return(0);
   }
   if (OptionsTable._indexin(Path)) {
      return(DefsToolWindowOptions)(OptionsTable:[Path]);
   }else{
      return(0);
   }
}

/**
 * @return Return 'true' or 'false' depending on whether we should show statements 
 *         for the current file.
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
bool _QShowStatementsInDefs(_str langId="", bool ignorePerFileOption=false)
{
   // get the target editor control, usually _mdi.p_child
   target_wid := p_window_id;
   if ( !_isEditorCtl()) {
      if (_no_child_windows()) return false;
      target_wid = _MDIGetActiveMDIChild();
   }
   if ((langId == null || langId == "") && target_wid._isEditorCtl()) {
      langId = target_wid.p_LangId;
   }

   // always disabled if statement tagging is not supported
   if (!_haveContextTagging()) {
      return false;
   }
   if (!target_wid._are_statements_supported(langId)) {
      return false;
   }

   // get the analyzer for the current buffer
   if (target_wid._isEditorCtl()) {
      doShowStatements := target_wid._GetBufferInfoHt(TBPROCTREE_SHOW_STATEMENTS_KEY);
      if (doShowStatements != null && !ignorePerFileOption) {
         return doShowStatements;
      }
   }

   // global option is enabled?
   if (def_proc_tree_options & PROC_TREE_STATEMENTS) {
      return true;
   }

   // per-language option enabled?
   if (target_wid._GetCodehelpFlags(langId) & VSCODEHELPFLAG_SHOW_STATEMENTS_IN_DEFS) {
      return true;
   }

   // statements are turned off
   return false;
}

/**
 * Turn on setting to show statements in the Defs tool window for the current file. 
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
void _SetShowStatementsInDefs(bool yesno)
{
   // get the target editor control, usually _mdi.p_child
   target_wid := p_window_id;
   if ( !_isEditorCtl()) {
      if (_no_child_windows()) return;
      target_wid = _MDIGetActiveMDIChild();
   }
   if ( _isEditorCtl()) {
      target_wid._SetBufferInfoHt(TBPROCTREE_SHOW_STATEMENTS_KEY, yesno);
   }
}

/**
 * @return Return the number of levels to expand the Defs tool window for the current file. 
 *  
 * <ul> 
 *    <li>0 - Expand All</li>
 *    <li>1 - Expand One Level</li>
 *    <li>2 - Expand Two Levels</li>
 *    <li>-1 = Expand to Statement Level</li>
 * </ul>
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
int _QExpandLevelInDefs(_str langId="", bool ignorePerFileOption=false)
{
   // get the target editor control, usually _mdi.p_child
   target_wid := p_window_id;
   if ( !_isEditorCtl()) {
      if (_no_child_windows()) return 0;
      target_wid = _MDIGetActiveMDIChild();
   }
   if ((langId == null || langId == "") && target_wid._isEditorCtl()) {
      langId = target_wid.p_LangId;
   }

   // always disabled if tagging not available
   if (!_haveContextTagging()) {
      return 0;
   }

   // get the analyzer for the current buffer
   if (target_wid._isEditorCtl()) {
      doExpandLevel := target_wid._GetBufferInfoHt(TBPROCTREE_EXPAND_LEVEL_KEY);
      if (doExpandLevel != null && !ignorePerFileOption) {
         return doExpandLevel;
      }
   }

   // global option is enabled?
   if (def_proc_tree_expand_level <= 2) {
      return def_proc_tree_expand_level;
   }

   // per-language option enabled?
   //if (target_wid._GetCodehelpFlags(langId) & VSCODEHELPFLAG_SHOW_STATEMENTS_IN_DEFS) {
   //   return true;
   //}

   // default is to expand all
   return 0;
}

/**
 * Modify how many levels to expand the Defs tool window for the current file. 
 *
 * <ul> 
 *    <li>0 - Expand All</li>
 *    <li>1 - Expand One Level</li>
 *    <li>2 - Expand Two Levels</li>
 *    <li>-1 = Expand to Statement Level</li>
 * </ul> 
 *  
 * @categories Edit_Window_Methods, Editor_Control_Methods 
 */
void _SetExpandLevelInDefs(int level)
{
   // get the target editor control, usually _mdi.p_child
   target_wid := p_window_id;
   if ( !_isEditorCtl()) {
      if (_no_child_windows()) return;
      target_wid = _MDIGetActiveMDIChild();
   }
   if ( _isEditorCtl()) {
      target_wid._SetBufferInfoHt(TBPROCTREE_EXPAND_LEVEL_KEY, level);
   }
}

void _reset_defs_tool_window_options(_str langId=null)
{
   if (_no_child_windows()) {
      return;
   }

   orig_wid := p_window_id;
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   orig_buf_id := p_buf_id;
   for (;;) {
      doShowStatements := _GetBufferInfoHt(TBPROCTREE_SHOW_STATEMENTS_KEY);
      if (doShowStatements != null && (langId == null || langId == p_LangId)) {
         _SetBufferInfoHt(TBPROCTREE_SHOW_STATEMENTS_KEY, null);
      }
      doExpandLevel := _GetBufferInfoHt(TBPROCTREE_EXPAND_LEVEL_KEY);
      if (doExpandLevel != null && (langId == null || langId == p_LangId)) {
         _SetBufferInfoHt(TBPROCTREE_EXPAND_LEVEL_KEY, null);
      }
      _next_buffer('hr');
      if (p_buf_id == orig_buf_id) {
         break;
      }
   }

   // make sure that all the defs tool windows change
   foreach (auto i => auto v in gDefsFormList) {
      _ProcTreeOptionsChanged(v.m_form_wid);
   }

   // that's all folks
   activate_window(orig_wid);
}

static void SortProcTree(int ParentIndex, DefsToolWindowOptions Options, _str langId)
{
   if ((Options&PROC_TREE_SORT_LINENUMBER) || _QShowStatementsInDefs(langId)) {
      _TreeSortUserInfo(ParentIndex,'NT');
   } else if(Options&PROC_TREE_SORT_FUNCTION) {
      _TreeSortCaption(ParentIndex,'iT','N');
   }
}

//Arg(2)!="" means just add the file
static int MaybeAddFilename(_str BufName,int bufid)
{
   //say("MaybeAddFilename H"__LINE__": bufName="BufName);
   child_wid := _MDIGetActiveMDIChild();
   filename := _strip_filename(BufName,'P');
   filename=strip(filename,'B','"');
   path := BufName;
   if (BufName=="") {
      ctlcurpath.p_caption="";
      return TREE_ROOT_INDEX;
   }
   if (IsSpecialFile(BufName)) {
      filename=path;
   }

   // Only do the work to add this buffer if:
   // 1) It is the current MDI child, and
   // 2) It is not current.
   if( child_wid && bufid==child_wid.p_buf_id) {
      if (proctreeLastBufId() != bufid) {
         proctreeLastBufId(child_wid.p_buf_id);
         StoreSortOptions(child_wid.p_buf_id/*_maybe_quote_filename(path)*/, def_proc_tree_options);
         _TreeSetInfo(TREE_ROOT_INDEX,1);
         _TreeSetCaption(TREE_ROOT_INDEX,filename);
         _TreeDelete(TREE_ROOT_INDEX, "C");
         _TreeRefresh();
      }
      CaptionName := ctlcurpath._ShrinkFilename(stranslate(BufName,"&&","&"),_proc_tree.p_width);
      if (CaptionName!=ctlcurpath.p_caption) {
         ctlcurpath.p_caption=CaptionName;
      }
   }

   return TREE_ROOT_INDEX;
}

int GetProcTreeWID()
{
   // Access the proc tree in the Project toolbar...
   wid := _tbGetActiveDefsForm();
   if (wid) {
      wid=wid._proc_tree;
   }else{
      wid=0;
   }
   return(wid);
   //return(wid._find_control("_proc_tree"));
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
   DEFS_FORM_INFO v;
   int i;
   foreach (i => v in gDefsFormList) {
      int treewid=v.m_form_wid._proc_tree;
      if (treewid.proctreeLastBufId() == buf_id) {
         treewid._TreeDelete(TREE_ROOT_INDEX,'c');
         treewid.proctreeLastBufId(-1);
      }
      treewid.MaybeAddFilename(new_bufname,buf_id);
   }
}


void _buffer_add_proc_tree(int newbuffid, _str name, int flags = 0)
{
   if (flags & VSBUFFLAG_HIDDEN) {
      return;
   }
   if (_in_batch_open_or_close_files()) {
      gProcTreeSwitchBufHappened = true;
      return;
   }
#if 0
   DEFS_FORM_INFO v;
   int i;
   foreach (i => v in gDefsFormList) {
      _ProcTreeSetLastModified(v.m_form_wid);
   }
#endif
#if 1
   filename := _GetDocumentName();
   if (!IsSpecialFile(filename)) {
      filename=absolute(filename);
   }

   wid := p_window_id;
   DEFS_FORM_INFO v;
   foreach (v in gDefsFormList) {
      treewid := v.m_form_wid._proc_tree;
      treewid.p_visible=false;
      //_UpdateCurrentTag();
      orig_autotag_flags := def_autotag_flags2;
      def_autotag_flags2 = 0;
      treewid.MaybeAddFilename(filename,newbuffid);
      def_autotag_flags2 = orig_autotag_flags;
      treewid.p_visible=true;
   }
#endif
}

void _cbmdibuffer_hidden_proc_tree()
{
   _cbquit_proc_tree(p_buf_id,p_buf_name,p_DocumentName,p_buf_flags);
}

void _switchbuf_proc_tree(_str oldbuffname, _str flag)
{
   if (_in_batch_open_or_close_files()) {
      gProcTreeSwitchBufHappened = true;
      return;
   }
   p_window_id._UpdateCurrentTag();
   gProcTreeSwitchBufHappened = true;
}

void _cbquit_proc_tree(int buf_id,_str buf_name,_str DocumentName,int buf_flags)
{
   if (DocumentName!="") {
      buf_name=DocumentName;
   }
   filename := buf_name;
   if (!IsSpecialFile(filename)) {
      filename=_strip_filename(buf_name,'P');
   }
   DEFS_FORM_INFO v;
   foreach (v in gDefsFormList) {
      treewid := v.m_form_wid._proc_tree;
      if (treewid.proctreeLastBufId() == buf_id) {
         treewid._TreeDelete(TREE_ROOT_INDEX,'c');
         treewid.proctreeLastBufId(-1);
      }
   }
}
_str _GetDocumentName()
{
   if (p_DocumentName!="") {
      return(p_DocumentName);
   }
   if (p_buf_name!="" ) {
      return(p_buf_name);
   }
   return _BufName2Caption();
}


static _str getFileTreeLangId( int tree_index )
{
   lang := "";
   int ParentIndex = TREE_ROOT_INDEX;
   wid := p_active_form;
   //if (wid <= 0) return "";
   int bid=wid._proc_tree.proctreeLastBufId();
   if (bid<0) {
      return "";
   }
   orig_view_id := p_window_id;
   orig_wid := p_window_id;
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   int status=load_files("+q +bi "bid);
   if (!status) {
      lang = p_LangId;
   }
   p_window_id = orig_wid;
   p_window_id = orig_view_id;
   return lang;
}

_proc_tree.on_create()
{
   DEFS_FORM_INFO info;
   i := p_active_form;
   info.m_form_wid=p_active_form;
   //info.m_last_buf_id= -1;
   info.m_LastModified= -1;
   info.m_RLine= -1;
   info.m_RLine_LastModified= -1;
   gDefsFormList:[i]=info;
   reinit_proctree();
}
static void reinit_proctree() {
   int orig_autotag_flags = def_autotag_flags2;
   def_autotag_flags2 |= AUTOTAG_CURRENT_CONTEXT;
   if (orig_autotag_flags != def_autotag_flags2) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   ctlcurpath.p_caption="";
   ctlcurpath.p_width=0;
   if (_isMac()) {
      macSetShowsFocusRect(p_window_id, 0);
   }
   _proc_tree._MakePreviewWindowShortcuts();
}

///////////////////////////////////////////////////////////////////////////////
// For saving and restoring the state of the Defs tool window
// when the user undocks, pins, unpins, or redocks the window.
//
void _twSaveState__tbproctree_form(typeless& state, bool closing)
{
   //if( closing ) {
   //   return;
   //}
   _proc_tree._TreeSaveNodes(state);
}
void _twRestoreState__tbproctree_form(typeless& state, bool opening)
{
   //if( opening ) {
   //   return;
   //}
   if (state == null) return;
   _proc_tree._TreeRestoreNodes(state);
}

static void resizeProcs()
{
   containerW := _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   containerH := _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);

   if (!isEclipsePlugin()) {
      // Resize width:
      _proc_tree.p_width = containerW - 2 * _proc_tree.p_x;

      // Resize height:
      _proc_tree.p_y_extent = containerH ;

      int child_wid=_MDIGetActiveMDIChild();
      if (child_wid) {

         BufName := child_wid._GetDocumentName();
         _str CaptionName=ctlcurpath._ShrinkFilename(stranslate(BufName,"&&","&"),_proc_tree.p_width);
         if (CaptionName!=ctlcurpath.p_caption) {
            ctlcurpath.p_caption=CaptionName;
         }
      }
   }
   _proc_tree.resizeProcTreeFirstColumn();
}

static void resizeProcTreeFirstColumn()
{
   _TreeSizeColumnToContents(0);
   colwidth := _TreeColWidth(0);
   if (colwidth > p_width) {
      _TreeColWidth(0, p_width);
   } else if (colwidth < p_width intdiv 2) {
      _TreeColWidth(0, p_width intdiv 2);
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

/**
 * Used to indicate the current buffer has switched when deciding whether
 * to update the current context or not. Used by _UpdateCurrentTag, et al.
 * 
 * @param buf_id (optional). Pass in value >=0 to set the last buf_id.
 * 
 * @return The last buf_id that the Procs tree knows about.
 */
static int proctreeLastBufId(int buf_id=-2)
{
   if( buf_id>= -1) {
      _TreeSetUserInfo(TREE_ROOT_INDEX, buf_id);
   }
   last_buf_id := _TreeGetUserInfo(TREE_ROOT_INDEX);
   if (isinteger(last_buf_id)) return last_buf_id;
   return -1;
}

static void _UpdateCurrentTag2(int form_wid,
                               DEFS_FORM_INFO &formInfo,
                               long elapsed,
                               int child_wid,
                               bool AlwaysUpdate,
                               bool ForceUpdate=false)
{
   // bail out if focus in in the proctree
   treewid  := form_wid._proc_tree;
   focuswid := _get_focus();
   if (!focuswid && child_wid) {
      return;
   }

   // is the tree empty, and not forcing update, and not first time here
   isEmpty := (treewid._TreeGetFirstChildIndex(TREE_ROOT_INDEX) < 0);
   if (focuswid==treewid && !AlwaysUpdate && !isEmpty /*&& child_wid*/) {
      return;
   }

   // no child windows, then bail out of here
   if (!child_wid) {
      //int treewid=m_form_wid._proc_tree;
      if (treewid.proctreeLastBufId()>=0) {
         treewid._TreeDelete(TREE_ROOT_INDEX,'c');
         treewid.proctreeLastBufId(-1);
      }
      if (form_wid.ctlcurpath.p_caption!="") {
         form_wid.ctlcurpath.p_caption="";
         form_wid.ctlcurpath.p_width=0;
      }
      return;
   }

   // If the proc tab is not current, do not update.
   if( !tw_is_wid_active(form_wid) ) {
      return;
   }

   // tree not initialized yet?
   index := TREE_ROOT_INDEX;
   wasEmptyFileNode := false;
   if( treewid.proctreeLastBufId() != child_wid.p_buf_id ) {
      // New buffer or we have switched buffers
      wasEmptyFileNode=true;
      index = -1;
   }

   // find the index of the current buffer
   filename := _strip_filename(child_wid._GetDocumentName(),'P');
   if (IsSpecialFile(_maybe_quote_filename(child_wid._GetDocumentName()))) {
      filename=_maybe_quote_filename(child_wid._GetDocumentName());
   }

   // get file extension (mode name)
   lang := child_wid.p_LangId;

   // no current tree index, then bail out?
   curIndex := treewid._TreeCurIndex();
   if (curIndex < 0) {
      return;
   }

   // not a hidden buffer, maybe add the filename
   if (index < 0 && !(child_wid.p_buf_flags&VSBUFFLAG_HIDDEN)) {
      index=treewid.MaybeAddFilename(child_wid._GetDocumentName(),child_wid.p_buf_id);
   }
   if ( index<0 ) {
      return;
   }
   wasEmptyFileNode = ( 0==treewid._TreeGetNumChildren(index) );

   // set the current filename caption on top of proc tree
   orig_wid := p_window_id;
   p_window_id=treewid;
   // get the index of the current function and parent
   OpenIndex := TREE_ROOT_INDEX;
   OrigParentIndex := OpenIndex;

   // get complete file path and options
   se.tags.TaggingGuard sentry;
   doStatementTagging := child_wid._QShowStatementsInDefs(lang);
   doExpandLevel      := child_wid._QExpandLevelInDefs(lang);
   NewPath:=_TreeGetUserInfo(index);
   sortop := GetSortOptions(NewPath);
   state := 0;
   _TreeGetInfo(index,state);
   //say("_UpdateCurrentTag: h1 - state="state);
   OrigNumDown := -1;
   AddedTags := 0;
   origCap := _TreeGetCaption(_TreeCurIndex());
   NeedRefresh := false;
   NewFile := !(child_wid.p_buf_id==proctreeLastBufId());
   NeedsUpdate := ((child_wid.p_LastModified!=formInfo.m_LastModified) || NewFile || ForceUpdate);
   if (NeedsUpdate) {
      formInfo.m_RLine_LastModified=child_wid.p_LastModified-1;
      //child_wid.p_ModifyFlags&=~MODIFYFLAG_PROCTREE_SELECTED;
   }
   if (isEmpty || !state) NeedsUpdate=true;
   CanUpdateFast := false;
   if (NeedsUpdate && elapsed > def_update_context_fast_ms) {
      if (doStatementTagging) {
         CanUpdateFast = child_wid._UpdateStatementsIsFast();
      } else {
         CanUpdateFast = child_wid._UpdateContextIsFast();
      }
   }
   if (NeedsUpdate && (AlwaysUpdate || CanUpdateFast || elapsed >= def_update_tagging_idle)) {

      //say("_UpdateCurrentTag: ****************************************");
      //_StackDump();
      //say("_UpdateCurrentTag: ****************************************");

      // if the context is not yet up-to-date, then don't update yet
      if (!AlwaysUpdate && !child_wid._ContextIsUpToDate(elapsed, doStatementTagging? MODIFYFLAG_STATEMENTS_UPDATED:MODIFYFLAG_CONTEXT_UPDATED)) {
         //say("_UpdateCurrentTag2: context not up-to-date");
         return;
      }

      // do not let writers sneak in and modify the context while we are
      // upating the tree control
      sentry.lockContext(false);

      // add the tags, simply transfer over from context tree
      if ( doStatementTagging ) {
         child_wid._UpdateStatements(true, ForceUpdate);
      } else {
         child_wid._UpdateContext(true, ForceUpdate);
      }

      //say("_UpdateCurrentTag");
      cb_prepare_expand(p_active_form,p_window_id,index);
      _TreeBeginUpdate(index,"","T");
      force_leaf := (def_proc_tree_options&PROC_TREE_NO_STRUCTURE)? -1:1;
      if (force_leaf==1 && (def_proc_tree_options&PROC_TREE_AUTO_STRUCTURE)) {
         force_leaf=0;
      }
 
      show_statements := doStatementTagging? 1:0;
      if (doStatementTagging && doExpandLevel < 0) {
         show_statements = -1;
      }
      tag_tree_insert_context(p_window_id, 
                              index, 
                              def_proctree_flags, 
                              1, 
                              force_leaf,
                              0,
                              show_statements);
      _TreeEndUpdate(index);
      _TreeSizeColumnToContents(-1);
      SortProcTree(index, def_proc_tree_options, lang);
      if (NeedsUpdate) {
         formInfo.m_LastModified=child_wid.p_LastModified;
         //child_wid.p_ModifyFlags|=MODIFYFLAG_PROCTREE_UPDATED;
         formInfo.m_RLine_LastModified=child_wid.p_LastModified-1;
         //child_wid.p_ModifyFlags&=~MODIFYFLAG_PROCTREE_SELECTED;
      }
      proctreeLastBufId(child_wid.p_buf_id);
      NeedRefresh=true;

   } else if ((sortop & def_proc_tree_options) &&
             ((child_wid.p_LastModified!=formInfo.m_LastModified) &&
              !AlwaysUpdate)) {
      p_window_id=orig_wid;
      return;
   }

   // do not update the current tag as often
   if (!AlwaysUpdate && !NeedsUpdate && elapsed < (def_update_tagging_idle intdiv 4)) {
      p_window_id=orig_wid;
      return;
   }

   // do not let writers sneak in and modify the context while we are
   // upating the tree control
   sentry.lockContext(false);

   // if auto-expand is on, always find the current tag.
   findCurrentProc := ((def_proc_tree_options & PROC_TREE_AUTO_EXPAND) || isEclipsePlugin());

   // for Ant, expand 2 levels when a new file is displayed
   if (NewFile && child_wid.p_LangId == "ant") {
      doExpandLevel = 2;
   }

   if( /*((def_proc_tree_options&PROC_TREE_AUTO_EXPAND) || isEclipsePlugin()) &&*/ wasEmptyFileNode && doExpandLevel>0 ) {
      // First time filling in the tree for the file node, so use def_proc_tree_expand_level
      p_window_id.expandToLevel(index,doExpandLevel);

   } else {
      // if auto-expand is on, or if in outline mode, or if the node is already expanded, find the current tag
      //say("_UpdateCurrentTag: h2 - findCurrentProc="findCurrentProc"  state="state);
      if (!findCurrentProc && state > 0) {
         findCurrentProc=true;
      }
      if (def_proc_tree_options & PROC_TREE_AUTO_COLLAPSE) {
         //collapseCurrentNodeToLevel(_TreeCurIndex(), doExpandLevel);
      }
   }

   if ( findCurrentProc && _TreeGetFirstChildIndex(index)>=0 ) {
      // has the selected item in the proc tree been updated
      // or has the current line changed
      EditorLN := child_wid.p_RLine;
      EditorPT := child_wid._QROffset();
      if (AlwaysUpdate || (child_wid.p_LastModified!=formInfo.m_RLine_LastModified) || formInfo.m_RLine!=EditorLN) {

         if( doStatementTagging ) {
            child_wid._UpdateStatements(true,ForceUpdate);
         } else {
            child_wid._UpdateContext(true,ForceUpdate);
         }

         if (isOutlineViewActive(child_wid) == false) {
            currentWindowID := p_window_id;
            p_window_id = child_wid;
            current_id := tag_current_context(allow_outline_only:true);
            if (current_id > 0) {
               tag_get_detail2(VS_TAGDETAIL_context_type,  current_id, auto current_type_name);
               tag_get_detail2(VS_TAGDETAIL_context_flags, current_id, auto current_tag_flags);
               if (!tag_filter_type(tag_get_type_id(current_type_name), def_proctree_flags, current_type_name, current_tag_flags)) {
                  current_id = 0;
               }
               type_id := tag_get_type_id(current_type_name);
               if (type_id <= def_cb_filter_by_types._length() && !def_cb_filter_by_types[type_id]) {
                  current_id = 0;
               }
            }
            nearest_id := tag_nearest_context(EditorLN, def_proctree_flags, find_tag_below:false, filter_by_types:true);
            if (doStatementTagging) {
               current_id = tag_current_statement();
               nearest_id = tag_nearest_statement(EditorLN, def_proctree_flags, false);
               if (!current_id) current_id = tag_current_context(allow_outline_only:true);
               if (!nearest_id) nearest_id = tag_nearest_context(EditorLN, def_proctree_flags, find_tag_below:false, filter_by_types:true);
               if (current_id > 0) {
                  tag_get_detail2(VS_TAGDETAIL_statement_type,  current_id, auto current_type_name);
                  tag_get_detail2(VS_TAGDETAIL_statement_flags, current_id, auto current_tag_flags);
                  if (!tag_filter_type(tag_get_type_id(current_type_name), def_proctree_flags, current_type_name, current_tag_flags)) {
                     current_id = 0;
                  }
                  type_id := tag_get_type_id(current_type_name);
                  if (type_id <= def_cb_filter_by_types._length() && !def_cb_filter_by_types[type_id]) {
                     current_id = 0;
                  }
               }
            }
            // If we're between functions, but in a comment, find the next item after the comment.
            if (current_id != nearest_id && _in_comment()) {
               orig_nearest_id := nearest_id;
               nearest_id = tag_nearest_context(EditorLN, def_proctree_flags, find_tag_below:true, filter_by_types:true);
               if (doStatementTagging) {
                  nearest_id = tag_nearest_statement(EditorLN, def_proctree_flags, true);
               }
               if (!nearest_id) nearest_id = orig_nearest_id;
               // make sure that the next one after the current isn't TOO far after.
               tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, nearest_id, auto nearest_start_seekpos);
               tag_get_detail2(VS_TAGDETAIL_context_end_seekpos,   current_id, auto current_end_seekpos);
               if (doStatementTagging) {
                  tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, nearest_id, nearest_start_seekpos);
                  tag_get_detail2(VS_TAGDETAIL_statement_end_seekpos,   current_id, current_end_seekpos);
               }
               if (nearest_start_seekpos > current_end_seekpos) {
                  nearest_id = orig_nearest_id;
               }
            }
            // make sure that the next one after the current isn't TOO far after.
            if (nearest_id > 0 && current_id > 0) {
               tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, nearest_id, auto nearest_start_seekpos);
               tag_get_detail2(VS_TAGDETAIL_context_end_seekpos,   nearest_id, auto nearest_end_seekpos);
               tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, current_id, auto current_start_seekpos);
               tag_get_detail2(VS_TAGDETAIL_context_end_seekpos,   current_id, auto current_end_seekpos);
               if (doStatementTagging) {
                  tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, nearest_id, nearest_start_seekpos);
                  tag_get_detail2(VS_TAGDETAIL_statement_end_seekpos,   nearest_id, nearest_end_seekpos);
                  tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, current_id, current_start_seekpos);
                  tag_get_detail2(VS_TAGDETAIL_statement_end_seekpos,   current_id, current_end_seekpos);
               }
               if (nearest_start_seekpos > current_start_seekpos && nearest_end_seekpos < current_end_seekpos) {
                  current_id = nearest_id;
               }
               if (abs(nearest_start_seekpos-EditorPT) < abs(current_start_seekpos-EditorPT)) {
                  current_id = nearest_id;
               }
            }
            if (!current_id) {
               current_id = nearest_id;
            }
            p_window_id = currentWindowID;
   
            line_num := 0;
            if (doStatementTagging) {
               tag_get_detail2(VS_TAGDETAIL_statement_line, current_id, line_num);
            } else {
               tag_get_detail2(VS_TAGDETAIL_context_line, current_id, line_num);
            }
            nearLine := 0;
   
            if (state <= 0) {
               _TreeSetInfo(index,1);
            }
   
            nearIndex := _TreeSearch(index,"","T",line_num);
            if (nearIndex <= 0) {
               NeedRefresh=true;
               nearIndex = index;
            }
            if (index==0 && nearIndex==0) {
               nearIndex=_TreeGetFirstChildIndex(index);
               if (nearIndex < 0) nearIndex=0;
            }
   
            // just in case if we can get closer by matching captions, let's try that
            current_caption := tag_tree_make_caption_fast(VS_TAGMATCH_context, current_id, false, true, true);
            if (nearIndex > 0 && _TreeGetCaption(nearIndex) != current_caption) {
               captionIndex := _TreeSearch(index, current_caption, 'T');
               if (captionIndex > 0) {
                  captionInfo := _TreeGetUserInfo(captionIndex);
                  if (captionInfo == line_num) {
                     nearIndex = captionIndex;
                  }
               }
            }

            if (_TreeCurIndex()!=nearIndex) {
               if (def_proc_tree_options & PROC_TREE_AUTO_COLLAPSE) {
                  collapseCurrentNodeToLevel(index, doExpandLevel);
               }
               NeedRefresh=true;
               if (def_proc_tree_options & PROC_TREE_AUTO_EXPAND) {
                  _TreeSetCurIndex(nearIndex);
               } else {
                  expandedIndex := _TreeGetExpandedIndex(nearIndex);
                  _TreeSetCurIndex(expandedIndex);
               }
            }
         } else {
            // find the closest tree item to the current line
            nearIndex := get_nearest_tree_index_context(treewid, EditorLN, TREE_ROOT_INDEX, EditorPT);
            if ((nearIndex >= 0) && (treewid._TreeCurIndex() != nearIndex)) {
               if (def_proc_tree_options & PROC_TREE_AUTO_COLLAPSE) {
                  collapseCurrentNodeToLevel(index, doExpandLevel);
               }
               NeedRefresh = true;
               if (def_proc_tree_options & PROC_TREE_AUTO_EXPAND) {
                  _TreeSetCurIndex(nearIndex);
               } else {
                  expandedIndex := _TreeGetExpandedIndex(nearIndex);
                  _TreeSetCurIndex(expandedIndex);
               }
               treewid._TreeSizeColumnToContents(-1);
            }
         }

         formInfo.m_RLine=EditorLN;
         formInfo.m_RLine_LastModified=child_wid.p_LastModified;
         //child_wid.p_ModifyFlags |= MODIFYFLAG_PROCTREE_SELECTED;
      }
   } else {
      cur_index := _TreeCurIndex();
      while (cur_index > 0 && cur_index!=index) {
         cur_index=_TreeGetParentIndex(cur_index);
      }
      if (cur_index < 0) {
         _TreeSetCurIndex(index);
      }
   }

   // switched to a different file, so resize first column
   if (wasEmptyFileNode) {
      resizeProcTreeFirstColumn();
   }

   // Force tree refresh if necessary
   if (NeedRefresh) {
      _TreeRefresh();
   }

   p_window_id=orig_wid;
}

void _UpdateCurrentTag(bool AlwaysUpdate=false)
{
   // IF outline nag screen happened and we are recursing
   static int grecurse;
   if (grecurse) {
      // Just get out
      return;
   }

   // get out if not enough time passed by
   elapsed := _idle_time_elapsed();
   if (!AlwaysUpdate && elapsed < 60) {
      return;
   }

   always_update := (AlwaysUpdate || gProcTreeSwitchBufHappened);
   gProcTreeSwitchBufHappened = false;

   ++grecurse;
   DEFS_FORM_INFO v;
   foreach (auto i => v in gDefsFormList) {
      child_wid := i._MDIGetActiveMDIChild();
      _UpdateCurrentTag2(v.m_form_wid,gDefsFormList:[i],elapsed,child_wid,always_update);
   }
   --grecurse;

#if 0
   child_wid := 0;
   int mdi_wid=_mdi;

   if (!_no_child_windows()) {
      mdi_wid=_MDICurrent();
      if (!mdi_wid) {
         mdi_wid=_mdi;
      }
      child_wid=_MDICurrentChild(mdi_wid);
      if (!child_wid) {
         child_wid=_mdi.p_child;
      }
   }

   DEFS_FORM_INFO v;
   int i;
   foreach (i => v in gDefsFormList) {
      int mdi_wid2=_MDIFromChild(v.m_form_wid);
      //say("mdi_wid2="mdi_wid2" mdi_wid="mdi_wid);
      /*say("h1 "_MDICurrentChild(mdi_wid2));
      if (_MDICurrentChild(mdi_wid2)) {
         say("buf="_MDICurrentChild(mdi_wid2).p_buf_id);
         say("h2 "_MDICurrentChild(mdi_wid));
         if (_MDICurrentChild(mdi_wid)) {
            say("buf="_MDICurrentChild(mdi_wid).p_buf_id);
         }
      } */
      if (!child_wid || !mdi_wid2 || !_MDICurrentChild(mdi_wid2) || 
          _MDICurrentChild(mdi_wid2).p_buf_id==child_wid.p_buf_id) {
         //say(mdi_wid2" form_wid="v.m_form_wid);
         _UpdateCurrentTag2(v.m_form_wid,gDefsFormList:[i],elapsed,child_wid,AlwaysUpdate);
      }
   }
#endif
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
int get_nearest_tree_index_context(int treewid, 
                                   int editorLine, 
                                   int rootIndex=TREE_ROOT_INDEX, 
                                   long editorOffset=0)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   childIndex := treewid._TreeGetFirstChildIndex(rootIndex);
   // make sure there is a child
   lastWinningChildID    := -1;
   lastWinningDistance   := 1000000;
   lastWinningOffsetDist := 1000000L;
   while (childIndex >= 0) {
      // get the user info, this is the context ID of that node
      typeless ctxID = treewid._TreeGetUserInfo(childIndex);
      // if the user info is not an integer, then something is screwy and we should bail
      if (!isinteger(ctxID)) break;

      ctxID++;
      if (ctxID >= 0) {
         temp1 := treewid._TreeGetCaption(childIndex);
         tag_get_context_info(ctxID, auto cm);
         curDistance := editorLine - cm.line_no;
         if ((curDistance >= 0) && (curDistance < lastWinningDistance)) {
            // we have found an item that comes before the current
            // editor line, so record it
            lastWinningChildID = childIndex;
            lastWinningDistance = curDistance;
         }

         if (curDistance == 0 && editorOffset > 0 && cm.seekpos > 0) {
            curOffsetDistance := editorOffset - cm.seekpos;
            if (curOffsetDistance >= 0 && curOffsetDistance < lastWinningOffsetDist) {
               lastWinningChildID = childIndex;
               lastWinningDistance = curDistance;
               lastWinningOffsetDist = curOffsetDistance;
            }
         }

      }
      childIndex = treewid._TreeGetNextSiblingIndex(childIndex);
   }

   // did we find any matches here?
   if (lastWinningChildID > -1) {
      // see if we have any closer children
      closerChild := get_nearest_tree_index_context(treewid, editorLine, lastWinningChildID, editorOffset);
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
   index := _TreeCurIndex();
   call_event(CHANGE_LEAF_ENTER,index,p_window_id,ON_CHANGE,'w');
}

void _proc_tree." "()
{
   index := _TreeCurIndex();
   if (index <= TREE_ROOT_INDEX) return;
   int ParentIndex=TREE_ROOT_INDEX;
   orig_wid := p_window_id;
   int child_wid= _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }
   if (ParentIndex>=0) {
      int bufid=proctreeLastBufId();
      if (bufid>=0) {
         edit("+bi "bufid);
         p_window_id=orig_wid;
         child_wid=_MDIGetActiveMDIChild();
      }
   }
   if (def_search_result_push_bookmark) {
      child_wid.push_bookmark();
      child_wid.mark_already_open_destinations();
   }
   int LineNumber=_TreeGetUserInfo(index);
   ParentIndex=_TreeGetParentIndex(index);
   path := _TreeGetCaption(ParentIndex);
   CaptionName := ctlcurpath._ShrinkFilename(stranslate(path,"&&","&"),_proc_tree.p_width);
   if (ctlcurpath.p_caption!=CaptionName) {
      ctlcurpath.p_caption=CaptionName;
   }
   child_wid.p_line=LineNumber;

   if (child_wid.p_scroll_left_edge>=0) {
      child_wid.p_scroll_left_edge= -1;
   }
   if (child_wid._lineflags() & HIDDEN_LF) {
      child_wid.expand_line_level();
   }
   child_wid.center_line();
   child_wid.push_destination();
}


// Get the information about the tag currently selected
// in the proc tree.
//
static int _ProcTreeTagInfo(struct VS_TAG_BROWSE_INFO &cm,
                            _str &proc_name, _str &path, int &LineNumber, int index,int f)
{
   // get the symbol browser form window id
   tag_init_tag_browse_info(cm);
   if (!f) {      
      f = _tbGetActiveDefsForm();
      if (!f) {
         return 0;
      }
   }
   _nocheck _control _proc_tree;

   // find the tag name, file and line number
   if(index == -1) {
      index = f._proc_tree._TreeCurIndex();
   }
   if( index <= 0 ) {
      // Probably nothing in the tree, so bail
      return 0;
   }
   child_wid := f._MDIGetActiveMDIChild();
   LineNumber = f._proc_tree._TreeGetUserInfo(index);

   // if this is the outline view, then a tree node's user data is the 
   // context ID, so just use that   
   if (isOutlineViewActive(child_wid) == true) {
      tag_lock_context();
      int ctxID = f._proc_tree._TreeGetUserInfo(index) + 1;
      tag_get_context_info(ctxID, cm);
      proc_name = cm.member_name;
      path = cm.file_name;
      LineNumber = cm.line_no;
      tag_unlock_context();
      return ctxID;
   }

   bid := f._proc_tree.proctreeLastBufId();
   path="";
   orig_wid := p_window_id;
   if (bid>=0) {
      p_window_id=VSWID_HIDDEN;
      _safe_hidden_window();
      int status=load_files("+q +bi "bid);
      if (!status) {
         path=p_buf_name;
      }
      cm.language=p_LangId;
      cm.file_name=p_buf_name;
   } else {
      cm.language="";
      cm.file_name="";
   }

   if (child_wid) {
      if (child_wid._QShowStatementsInDefs(cm.language)) {
         child_wid._UpdateStatements(true,false);
      } else {
         child_wid._UpdateContext(true,false);
      }
   }

   p_window_id=orig_wid;
   _str caption = f._proc_tree._TreeGetCaption(index);
   tag_tree_decompose_caption(caption,proc_name);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // get the remainder of the information
   //return _GetContextTagInfo(cm, "", proc_name, path, LineNumber);
   cm.tag_database   = "";
   cm.category       = "";
   cm.qualified_name = "";
   cm.seekpos=0;
   if (child_wid) {
      i := tag_find_context_iterator(proc_name, true, true);
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_line, i, auto context_line);
         tag_get_detail2(VS_TAGDETAIL_context_included_by, i, auto included_by_file);
         if (context_line == LineNumber) {
            tag_get_context_browse_info(i, auto icm);
            if ((file_eq(icm.file_name,path) || file_eq(included_by_file,path) || (icm.flags & SE_TAG_FLAG_EXTERN_MACRO))) {
               cm = icm;
               tag_get_detail2(VS_TAGDETAIL_context_language_id, i, cm.language);
               if (cm.type_name=="include" && cm.return_type!="" && file_exists(cm.return_type)) {
                  path=cm.file_name=cm.return_type;
                  LineNumber=cm.line_no=1;
               }
               // 4:57:47 PM 1/23/2003
               // If we find a match, return the context id
               return i;
            }
         }
         i = tag_next_context_iterator(proc_name, i, true, true);
      }

      // try again, using only the line number
      n := tag_get_num_of_context();
      i = tag_nearest_context(LineNumber);
      while (i > 0 && i < n) {
         tag_get_detail2(VS_TAGDETAIL_context_line, i, auto context_line);
         tag_get_detail2(VS_TAGDETAIL_context_included_by, i, auto included_by_file);
         if (context_line == LineNumber) {
            tag_get_context_browse_info(i, auto icm);
            if ((file_eq(icm.file_name,path) || file_eq(included_by_file,path) || (icm.flags & SE_TAG_FLAG_EXTERN_MACRO))) {
               cm = icm;
               tag_get_detail2(VS_TAGDETAIL_context_language_id, i, cm.language);
               if (cm.type_name=="include" && cm.return_type!="" && file_exists(cm.return_type)) {
                  path=cm.file_name=cm.return_type;
                  LineNumber=cm.line_no=1;
               }
               // 4:57:47 PM 1/23/2003
               // If we find a match, return the context id
               return i;
            }
         }
         if (context_line > LineNumber+100) {
            break;
         }
         i++;
      }
   }

   // did not find a match, really quite depressing, use what we know
   cm.member_name = proc_name;
   cm.type_name   = "";
   cm.file_name   = path;
   cm.line_no     = LineNumber;
   cm.class_name  = "";
   cm.flags       = SE_TAG_FLAG_NULL;
   cm.arguments   = "";
   cm.return_type = "";
   cm.exceptions  = "";
   cm.class_parents = "";
   cm.template_args = "";
   if (cm.language==null) {
      cm.language = "";
   }
   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// This is the timer callback.  Whenever the current index (cursor position)
// for the proc tree is changed, a timer is started/reset.  If no
// activity occurs within a set amount of time, this function is called to
// update the output window.
//
static void _ProcTreeFocusTimerCallback(int form_wid)
{
   // kill the timer
   _kill_timer(gProcTreeFocusTimerId);
   gProcTreeFocusTimerId=-1;

   if (!_iswindow_valid(form_wid) || form_wid.p_name!=TBPROCTREE_FORM) {
      return;
   }

   // get the symbol browser form window id
   _nocheck _control _proc_tree;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   if (!_ProcTreeTagInfo(auto cm, auto proc_name, auto path, auto LineNumber, -1, form_wid)) {
      return;
   }

   // find the output tagwin and update it
   cb_refresh_output_tab(cm, true, true, false, APF_DEFS);

   // update the properties and arguments tool windows
   cb_refresh_property_view(cm);
   cb_refresh_arguments_view(cm);

   // Do not update call tree or references tab unless this option is enabled
   if (!(def_autotag_flags2 & AUTOTAG_UPDATE_CALLSREFS)) {
      return;
   }

   // find the output references tab and update it
   form_wid = _GetReferencesWID(true);
   if (form_wid && proc_name != "") {
      refresh_references_tab(cm);
   }

   // find the call tree view and update it
   //say("_ProcTreeFocusTimerCallback: cm.seekpos="cm.seekpos" end="cm.end_seekpos" file="cm.file_name);
   cb_refresh_calltree_view(cm);
   cb_refresh_callertree_view(cm, expandChildren:false);
}

static bool _DidDefsExceedLimits(int index)
{
   if (_TreeGetNumChildren(TREE_ROOT_INDEX) > 1) return false;
   cap := _TreeGetCaption(index);
   parse cap with auto test_name "\t" auto test_class;
   if (length(test_class) > 0) return false;
   int LineNumber=_TreeGetUserInfo(index);
   tag_get_detail2(VS_TAGDETAIL_context_line, 1, auto test_line);
   if (LineNumber != 1) return false;
   return true;
}

_str _proc_tree.on_change(int reason,int index)
{
   //say("_proc_tree.on_change H"__LINE__": IN");
   //if (!(def_autotag_flags2 & AUTOTAG_CURRENT_CONTEXT)) {
   //   return("");
   //}
   if (reason==CHANGE_SCROLL) return("");
   if (index < 0) return("");

   child_wid := _MDIGetActiveMDIChild();
   form_wid := p_active_form;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // make sure that the on_change can't call itself recursively
   static bool onChangeRecursing;
   if (onChangeRecursing) return "";
   onChangeRecursing=true;

   status := 0;
   depth  := _TreeGetDepth(index);
   //say("depth="depth" index="index" reason="reason);

   if (depth>0 && (reason==CHANGE_LEAF_ENTER)) {

      //say("_proc_tree.on_change H"__LINE__": CHANGE_LEAF_ENTER");
      ParentIndex := TREE_ROOT_INDEX;
      if (child_wid && def_search_result_push_bookmark) {
         child_wid.push_bookmark();
         child_wid.mark_already_open_destinations();
      }
      int LineNumber=_TreeGetUserInfo(index);
      cap := _TreeGetCaption(index);
      ParentIndex=_TreeGetParentIndex(index);
      path := _TreeGetCaption(ParentIndex);
      CaptionName := ctlcurpath._ShrinkFilename(stranslate(path,"&&","&"),_proc_tree.p_width);
      if (ctlcurpath.p_caption!=CaptionName) {
         ctlcurpath.p_caption=CaptionName;
      }
      exceeded_limits_for_tree := _DidDefsExceedLimits(index);
      if (child_wid) {
         p_window_id=child_wid;

         maybe_deselect(true);
         if (exceeded_limits_for_tree || _DidUpdateContextExceedLimits()) {
            if (_QShowStatementsInDefs(p_LangId)) {
               _UpdateStatements(true,true);
            } else {
               _UpdateContext(true,true);
            }
            onChangeRecursing = false;
            gProcTreeSwitchBufHappened = false;
            _UpdateCurrentTag2(form_wid, gDefsFormList:[form_wid], 0, child_wid, true, true);
            return("");
         }
         if (_ProcTreeTagInfo(auto cm, auto proc_name, path, LineNumber, -1, form_wid) > 0) {
            parse cm.file_name with auto file_name "\1" auto included_by;
            if (_file_eq(p_buf_name, cm.file_name) || !file_exists(file_name)) {
               _GoToROffset(cm.seekpos);
            } else {
               _cb_goto_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no, false, cm.language);
            }
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
      }

   } else if (depth>0 && reason==CHANGE_SELECTED) {

      // kill the existing timer
      if (gProcTreeFocusTimerId!= -1) {
         _kill_timer(gProcTreeFocusTimerId);
         gProcTreeFocusTimerId=-1;
      }
      // don't create a new timer unless there is something to update
      if ((_GetTagwinWID() || _GetReferencesWID() || _GetCBrowserCallTreeWID() ||
           _GetCBrowserPropsWID() || _GetCBrowserArgsWID()) && _get_focus()==p_window_id) {
         timer_delay := max(200,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
         gProcTreeFocusTimerId=_set_timer(timer_delay,_ProcTreeFocusTimerCallback,p_active_form);
      }
   }
   onChangeRecursing=false;
   //say("_proc_tree.on_change H"__LINE__": OUT");
   return("");
}

void _proc_tree.on_highlight(int index, _str caption="")
{
   if (!def_tag_hover_preview) return;
   if (index < 0) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }

   // find the tag name, file and line number
   if (_ProcTreeTagInfo(auto cm, auto proc_name, auto path, auto LineNumber, index, p_active_form)) {
      _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
   }
}

_command void proctree_references() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      return;
   } else if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Defs tool window");
      return;
   }

   form_wid := _tbGetActiveDefsForm();
   if (!form_wid) {
      _message_box("References not available");
      return;
   }
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   if (_ProcTreeTagInfo(auto cm, auto proc_name, auto path, auto LineNumber, -1, form_wid) <= 0) {
      _message_box("References not available");
      return;
   }

   // check if the current workspace tag file or extension specific
   // tag file requires occurrences to be tagged.
   if (_MaybeRetagOccurrences(cm.tag_database) == COMMAND_CANCELLED_RC) {
      return;
   }

   // If form already exists, reuse it.  Otherwise, create it
   int refs_form_wid = _GetReferencesWID();
   if (!refs_form_wid) {
      if(!isEclipsePlugin()) {
         refs_form_wid=activate_tool_window("_tbtagrefs_form");
      }
   }
   if (refs_form_wid) {
      _ActivateReferencesWindow();
   }

   // find the output references tab and update it
   refs_form_wid = _GetReferencesWID();
   if (refs_form_wid && proc_name != "") {
      refresh_references_tab(cm,true);
   }
}

_command void proctree_calltree() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Call tree");
      return;
   } else if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Defs tool window");
      return;
   }

   form_wid := _tbGetActiveDefsForm();
   if (!form_wid) {
      _message_box("Call tree not available");
      return;
   }
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   if (_ProcTreeTagInfo(auto cm, auto proc_name, auto path, auto LineNumber, -1, form_wid) <= 0) {
      _message_box("Call tree not available");
      return;
   }
   // find the output references tab and update it


   f := activate_tool_window("_tbsymbolcalls_form", true, "ctl_call_tree_view");
   if ( f > 0 ) {
      _nocheck _control ctl_call_tree_view;
      f.cb_refresh_calltree_view(cm, f);
      f.ctl_call_tree_view._TreeTop();
   }
   //if (form_wid && proc_name != "") {
   //   form_wid.show("-xy _cbcalls_form", cm);
   //}
}

_command void proctree_callers() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Callers tree");
      return;
   } else if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Defs tool window");
      return;
   }

   form_wid := _tbGetActiveDefsForm();
   if (!form_wid) {
      _message_box("Callers tree not available");
      return;
   }
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   if (_ProcTreeTagInfo(auto cm, auto proc_name, auto path, auto LineNumber, -1, form_wid) <= 0) {
      _message_box("Callers tree not available");
      return;
   }
   // find the output references tab and update it


   f := activate_tool_window("_tbsymbolcallers_form", true, "ctl_call_tree_view");
   if ( f > 0 ) {
      _nocheck _control ctl_call_tree_view;
      f.cb_refresh_callertree_view(cm, f);
      f.ctl_call_tree_view._TreeTop();
   }
   //if (form_wid && proc_name != "") {
   //   form_wid.show("-xy _cbcalls_form", cm);
   //}
}

_command void proctree_props(int tab_number=0) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging");
      return;
   } else if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Defs tool window");
      return;
   }

   form_wid := _tbGetActiveDefsForm();
   if (!form_wid) {
      _message_box("Tag properties not available");
      return;
   }
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   if (_ProcTreeTagInfo(auto cm, auto proc_name,auto path, auto LineNumber, -1, form_wid) <= 0) {
      _message_box("Tag properties not available");
      return;
   }
   // find the output references tab and update it
   
   f := activate_tool_window("_tbsymbol_props_form");
   cb_refresh_property_view(cm,f);
}
_command void proctree_args() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging");
      return;
   } else if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Defs tool window");
      return;
   }

   form_wid := _tbGetActiveDefsForm();
   if (!form_wid) {
      _message_box("Tag arguments not available");
      return;
   }
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   if (_ProcTreeTagInfo(auto cm, auto proc_name,auto path, auto LineNumber, -1, form_wid) <= 0) {
      _message_box("Tag arguments not available");
      return;
   }
   // find the output references tab and update it
   
   f := activate_tool_window("_tbsymbol_args_form");
   cb_refresh_arguments_view(cm,f);
}

/**
 * Trigger a java refactoring operation for the currently
 * selected symbol in the proc tree
 *
 * @param params The refactoring to run
 */
_command void proctree_jrefactor(_str params = "") name_info(','VSARG2_EDITORCTL)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      return;
   } else if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Defs tool window");
      return;
   }

   form_wid := _tbGetActiveDefsForm();
   if (!form_wid) {
      _message_box("Tag information not available");
      return;
   }
   int child_wid=form_wid._MDIGetActiveMDIChild();
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   if (_ProcTreeTagInfo(auto cm, auto procName, auto path, auto lineNumber, -1, form_wid) <= 0) {
      _message_box("Tag information not available");
      return;
   }

   // trigger the requested refactoring
   switch(params) {
   case "add_import":
      refactor_add_import(false, cm, child_wid.p_buf_name);
      break;
   case "goto_import":
      refactor_goto_import(false, cm, child_wid.p_buf_name);
      break;
   case "organize_imports_options":
      refactor_organize_imports_options();
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
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      return;
   } else if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Defs tool window");
      return;
   }

   form_wid := _tbGetActiveDefsForm();
   if (!form_wid) {
      _message_box("Tag information not available");
      return;
   }
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   if (_ProcTreeTagInfo(auto cm, auto procName, auto path, auto lineNumber, -1, form_wid) <= 0) {
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
         if(cm.type_name == "proto" || cm.type_name == "procproto") {
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
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Refactoring");
      return;
   } else if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Defs tool window");
      return;
   }

   form_wid := _tbGetActiveDefsForm();
   if (!form_wid) {
      _message_box("Tag information not available");
      return;
   }
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   if (_ProcTreeTagInfo(auto cm, auto procName, auto path, auto lineNumber,-1,form_wid) <= 0) {
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
         if(cm.type_name == "proto" || cm.type_name == "procproto") {
            if(!refactor_convert_proto_to_proc(cm)) {
               _message_box("Cannot perform modify parameters refactoring because the function definition could not be found",
                            "Modify Parameters");
               break;
            }
         }
         refactor_start_modify_params(cm);
         break;

      case "quick_modify_params":
         if(cm.type_name == "proto" || cm.type_name == "procproto") {
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
   gDefsFormList._deleteel(p_active_form);
}

static void AddLanguageSpecificItems(int tree_index,int menu_handle)
{
   lang := getFileTreeLangId(tree_index);
   if (!_are_statements_supported(lang)) {
      _menu_set_state(menu_handle,"statements",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"lang_statements",MF_GRAYED,'C');
   }

   depth := -1;
   int orig_tree_index=tree_index;
   if (tree_index <= TREE_ROOT_INDEX) {
      return;
   }

   //int func_index=find_index("_"ext"_mod_proctree_menu",PROC_TYPE);
   func_index := _FindLanguageCallbackIndex("_%s_mod_proctree_menu",lang);
   if (func_index) {
      call_index(menu_handle,orig_tree_index,func_index);
   }
}

void _proc_tree.rbutton_up()
{
   // kill the refresh timer, prevents delays before the menu comes
   // while the refreshes are finishing up.
   if (gProcTreeFocusTimerId!= -1) {
      _kill_timer(gProcTreeFocusTimerId);
      gProcTreeFocusTimerId=-1;
   }
   child_wid := _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }

   inOutlineView := isOutlineViewActive(child_wid);
   orig_autotag_flags := def_autotag_flags2;
   def_autotag_flags2 = 0;
   _proc_tree.call_event(_proc_tree,LBUTTON_DOWN);
   menu_index  := find_index("_tagbookmark_menu",oi2type(OI_MENU));
   menu_handle := _mdi._menu_load(menu_index,'P');
   index := _proc_tree._TreeCurIndex();

   lang := getFileTreeLangId(index);
   doShowStatements := child_wid._QShowStatementsInDefs(lang);
   doExpandLevel := child_wid._QExpandLevelInDefs(lang);
   expand_level_caption := "";

   if (doShowStatements) {
      _menu_set_state(menu_handle,"sortfunc",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"sortlinenum",MF_GRAYED|MF_CHECKED,'C');
   } else if (def_proc_tree_options&PROC_TREE_SORT_FUNCTION) {
      _menu_set_state(menu_handle,"sortfunc",MF_CHECKED,'C');
   } else if ( def_proc_tree_options&PROC_TREE_SORT_LINENUMBER) {
      _menu_set_state(menu_handle,"sortlinenum",MF_CHECKED,'C');
   }

   if (inOutlineView) {
      _menu_set_state(menu_handle,"nesting",MF_CHECKED|MF_GRAYED,'C');
      expand_level_caption = "Outline View";
   } else if (!(def_proc_tree_options&PROC_TREE_NO_STRUCTURE)) {
      _menu_set_state(menu_handle,"nesting",MF_CHECKED,'C');
      expand_level_caption = "Flag View";
   }

   if (def_proc_tree_options&PROC_TREE_SINGLE_CLICK) {
      _menu_set_state(menu_handle,"singleclick",MF_CHECKED,'C');
   }

   // Have statements override the settings for sorting. If statements
   // are on only sort by line number should be supported.
   if (doShowStatements) {
      if (_are_statements_supported(lang) && _haveContextTagging() && !inOutlineView) {
         _menu_set_state(menu_handle,"statements",MF_CHECKED,'C');
         _menu_set_state(menu_handle,"sortlinenum",MF_CHECKED|MF_GRAYED,'C');
         _menu_set_state(menu_handle,"sortfunc",MF_UNCHECKED|MF_GRAYED,'C');
      } else {
         _menu_set_state(menu_handle,"statements",MF_CHECKED|MF_GRAYED,'C');
         _menu_set_state(menu_handle,"expandtostatements",MF_GRAYED,'C');
      }
   } else{
      if (_are_statements_supported(lang) && _haveContextTagging() && !inOutlineView) {
         _menu_set_state(menu_handle,"statements",MF_UNCHECKED,'C');
      } else {
         _menu_set_state(menu_handle,"statements",MF_UNCHECKED|MF_GRAYED,'C');
      }
      _menu_set_state(menu_handle,"filter_statements",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"all_statements",MF_GRAYED,'C');
   }

   // Update state for option to always show statements for a given language
   _menu_get_state(menu_handle,"lang_statements",auto mf_flags,'C',auto caption);
   caption = nls(caption, _LangId2Modename(lang));
   if (!_haveContextTagging() || !_are_statements_supported(lang)) {
      status := _menu_find(menu_handle,"lang_statements",auto mh,auto mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"statements",mh,mpos,'C');
      if (!status) {
         _menu_delete(mh,mpos);
      }
   } else if (child_wid._QShowStatementsInDefs(lang,true)) {
      _menu_set_state(menu_handle,"lang_statements",MF_CHECKED,'C',caption);
   } else {
      _menu_set_state(menu_handle,"lang_statements",MF_UNCHECKED,'C',caption);
   }

   expand_auto_caption := "";
   if (def_proc_tree_options & PROC_TREE_AUTO_EXPAND) {
      _menu_set_state(menu_handle,"autoexpand",MF_CHECKED,'C');
      expand_auto_caption = ", Auto +";
   } else {
      _menu_set_state(menu_handle,"autoexpand",MF_UNCHECKED,'C');
   }

   mf_disable_collapse := (def_proc_tree_options & PROC_TREE_AUTO_EXPAND)? 0:MF_GRAYED;
   if ((def_proc_tree_options&PROC_TREE_AUTO_COLLAPSE) && (def_proc_tree_options&PROC_TREE_AUTO_EXPAND)) {
      _menu_set_state(menu_handle,"autocollapse",MF_CHECKED|mf_disable_collapse,'C');
      expand_auto_caption = ", Auto +/-";
   } else {
      _menu_set_state(menu_handle,"autocollapse",MF_UNCHECKED|mf_disable_collapse,'C');
   }

   switch (doExpandLevel) {
   case 0:
      _menu_get_state(menu_handle, "expandchildren", mf_flags, 'C', expand_level_caption);
      _menu_set_state(menu_handle,"expandchildren",MF_CHECKED,'C');
      break;
   case 1:
      _menu_get_state(menu_handle, "expandonelevel", mf_flags, 'C', expand_level_caption);
      _menu_set_state(menu_handle,"expandonelevel",MF_CHECKED,'C');
      break;
   case 2:
      _menu_get_state(menu_handle, "expandtwolevels", mf_flags, 'C', expand_level_caption);
      _menu_set_state(menu_handle,"expandtwolevels",MF_CHECKED,'C');
      break;
   case -1:
      if (doShowStatements) {
         _menu_get_state(menu_handle, "expandtostatements", mf_flags, 'C', expand_level_caption);
         _menu_set_state(menu_handle,"expandtostatements",MF_CHECKED,'C');
      } else {
         _menu_get_state(menu_handle, "expandchildren", mf_flags, 'C', expand_level_caption);
         _menu_set_state(menu_handle,"expandtostatements",MF_GRAYED,'C');
         _menu_set_state(menu_handle,"expandchildren",MF_CHECKED,'C');
      }
      break;
   }

   expansion_caption := "";
   _menu_get_state(menu_handle, "expansion", mf_flags, 'C', expansion_caption);
   if (expand_level_caption != "") {
      expansion_caption :+= ' (';
      expansion_caption :+= expand_level_caption;
      if (expand_auto_caption != "") {
         expansion_caption :+= expand_auto_caption;
      }
      expansion_caption :+= ')';
   }
   _menu_set_state(menu_handle, "expansion", MF_ENABLED, 'C', expansion_caption);

   if (inOutlineView || (def_proc_tree_options&PROC_TREE_NO_STRUCTURE)) {
      _menu_set_state(menu_handle,"autoexpand",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"autocollapse",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"expandchildren",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"expandonelevel",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"expandtwolevels",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"expandtostatements",MF_GRAYED,'C');
   }

   if (!_istagging_supported(lang)) {
      _menu_set_state(menu_handle,"properties",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"arguments",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"references",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"calltree",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"callertree",MF_GRAYED,'C');
   } else if (!pos('(',_proc_tree._TreeGetCaption(index)) && !pos('=',_proc_tree._TreeGetCaption(index))) {
      _menu_set_state(menu_handle,"arguments",MF_GRAYED,'C');
   }

   if (inOutlineView) {
      _menu_set_state(menu_handle,"outline_view",MF_CHECKED,'C');
   }

   // configure the display filtering flags
   pushTgConfigureMenu(menu_handle, def_proctree_flags, 
                       include_proctree:true, 
                       include_casesens:false, 
                       include_sort:false, 
                       include_save_print:true, 
                       include_search_results:false,
                       include_statements:doShowStatements);

   AddLanguageSpecificItems(index,menu_handle);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // populate refactoring submenu
   if(_ProcTreeTagInfo(auto refcm, auto procName, auto path, auto lineNumber, index,p_active_form) > 0) {
      addCPPRefactoringMenuItems(menu_handle, "proctree", refcm);
      addQuickRefactoringMenuItems(menu_handle, "proctree", refcm);
   } else {
      addCPPRefactoringMenuItems(menu_handle, "proctree", null);
      addQuickRefactoringMenuItems(menu_handle, "proctree", null);
   }

   // populate organize imports submenu
   if(_ProcTreeTagInfo(auto oicm, procName, path, lineNumber, index,p_active_form) > 0) {
      addOrganizeImportsMenuItems(menu_handle, "proctree", oicm, false, child_wid.p_buf_name, child_wid.p_LangId);
   } else {
      addOrganizeImportsMenuItems(menu_handle, "proctree", null, false, child_wid.p_buf_name, child_wid.p_LangId);
   }

   int x,y;
   mou_get_xy(x,y);
   _KillToolButtonTimer();
   DelaySetting := 0;
   TreeDisablePopup(DelaySetting);
   
   call_list("_on_popup2_",translate("_tagbookmark_menu","_","-"),menu_handle);

   tree_wid := p_window_id;
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   p_window_id = tree_wid;
   def_autotag_flags2 = orig_autotag_flags;
   _menu_destroy(menu_handle);
   TreeEnablePopup(DelaySetting);
}

void _proc_tree.lbutton_up()
{
   if (!(def_proc_tree_options&PROC_TREE_SINGLE_CLICK)) {
      return;
   }
   if (_IsKeyDown(CTRL) || _IsKeyDown(SHIFT)) {
      return;
   }

   // If there is a pending on-change, kill the timer
   if (gProcTreeFocusTimerId != -1) {
      _kill_timer(gProcTreeFocusTimerId);
      gProcTreeFocusTimerId=-1;
   }
   index := _TreeCurIndex();
   if ( index > 0 ) {
      call_event(CHANGE_LEAF_ENTER,index,p_window_id,ON_CHANGE,'w');
   }
}

static void CollapseAll(int index)
{
   if ( index > 0 ) {
      _TreeSetInfo(index,0);
   }
}

static void ExpandAll(int index)
{
   _TreeSetInfo(index,1);

   index = _TreeGetFirstChildIndex(index);
   while (index > 0) {
      _TreeGetInfo(index, auto show_children);
      if (show_children == 0) ExpandAll(index);
      index = _TreeGetNextSiblingIndex(index);
   }
}

static void TraverseTopLevel(typeless pfn)
{
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      if (index<0) break;
      nextindex := _TreeGetNextSiblingIndex(index);
      (*pfn)(index);
      index=nextindex;
   }
}

_command void ProcTreeRunMenu() name_info(','VSARG2_CMDLINE|VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (arg(1)=="") {
      return;
   }
   FormName := p_active_form.p_name;
   child_wid := _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }

   olddef_proc_tree_options  := def_proc_tree_options;
   olddef_tag_select_options := def_tag_select_options;

   filename := _strip_filename(child_wid._GetDocumentName(),'P');
   path := child_wid._GetDocumentName();
   langId := child_wid.p_LangId;
   origShowStatements := child_wid._QShowStatementsInDefs(langId);
   origExpandLevel    := child_wid._QExpandLevelInDefs(langId);
   if (IsSpecialFile(path)) filename=path;
   index := TREE_ROOT_INDEX;

   switch (lowcase(arg(1))) {
   case "sortfunc":
      if (FormName=="_tag_select_form") {
         def_tag_select_options|=PROC_TREE_SORT_FUNCTION;
         def_tag_select_options&=~PROC_TREE_SORT_LINENUMBER;
      } else {
         def_proc_tree_options|=PROC_TREE_SORT_FUNCTION;
         def_proc_tree_options&=~PROC_TREE_SORT_LINENUMBER;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      break;
   case "sortlinenum":
      if (FormName=="_tag_select_form") {
         def_tag_select_options|=PROC_TREE_SORT_LINENUMBER;
         def_tag_select_options&=~PROC_TREE_SORT_FUNCTION;
      } else {
         def_proc_tree_options|=PROC_TREE_SORT_LINENUMBER;
         def_proc_tree_options&=~PROC_TREE_SORT_FUNCTION;
      }
      break;
   case "hierarchy":
   case "nesting":
      if (def_proc_tree_options&PROC_TREE_NO_STRUCTURE) {
         def_proc_tree_options&=~PROC_TREE_NO_STRUCTURE;
      }else{
         def_proc_tree_options|=PROC_TREE_NO_STRUCTURE;
      }
      _TreeDelete(TREE_ROOT_INDEX, 'C');
      break;
   case "singleclick":
      if (def_proc_tree_options & PROC_TREE_SINGLE_CLICK) {
         def_proc_tree_options &= ~PROC_TREE_SINGLE_CLICK;
      } else {
         def_proc_tree_options |= PROC_TREE_SINGLE_CLICK;
      }
      break;

   case "statements":
      child_wid._SetBufferInfoHt(TBPROCTREE_SHOW_STATEMENTS_KEY, !origShowStatements);
      _ProcTreeOptionsChanged(p_active_form);
      if (origShowStatements) {
         def_proc_tree_options&=~PROC_TREE_STATEMENTS;
      }
      _TreeDelete(TREE_ROOT_INDEX, 'C');
      break;
   case "lang_statements":
      if (origShowStatements) {
         def_proc_tree_options &= ~PROC_TREE_STATEMENTS;
      }
      codehelpFlags := _GetCodehelpFlags(langId);
      codehelpFlags ^= VSCODEHELPFLAG_SHOW_STATEMENTS_IN_DEFS;
      LanguageSettings.setCodehelpFlags(langId, codehelpFlags);
      _reset_defs_tool_window_options(langId);
      break;

   case "autoexpand":
      if (def_proc_tree_options&PROC_TREE_AUTO_EXPAND) {
         // turning auto-expand off, so let's collapse the tree to defaults
         // unless the current option is to expand all already
         def_proc_tree_options&=~PROC_TREE_AUTO_EXPAND;
         if (origExpandLevel > 0) {
            expandToLevel(TREE_ROOT_INDEX, origExpandLevel);
            expandedIndex := _TreeGetExpandedIndex(_TreeCurIndex());
            _TreeSetCurIndex(expandedIndex);
         }
      } else {
         // turning auto-expand on, so leave things alone unless
         // the current expansion option is Expand All
         def_proc_tree_options|=PROC_TREE_AUTO_EXPAND;
         if (index!=_TreeCurIndex() && index>=0 && origExpandLevel==0) {
            TraverseTopLevel(ExpandAll);
         }
      }
      break;

   case "autocollapse":
      if (def_proc_tree_options&PROC_TREE_AUTO_COLLAPSE) {
         def_proc_tree_options&=~PROC_TREE_AUTO_COLLAPSE;
      } else {
         def_proc_tree_options|=PROC_TREE_AUTO_COLLAPSE;
         if (index != _TreeCurIndex() && index>=0) {
            TraverseTopLevel(CollapseAll);
            _TreeSetInfo(index,1);
         }
      }
      break;

   case "expandchildren":
      child_wid._SetBufferInfoHt(TBPROCTREE_EXPAND_LEVEL_KEY, 0);
      proctree_expand_children(p_active_form._proc_tree);
      break;

   case "expandonelevel":
      child_wid._SetBufferInfoHt(TBPROCTREE_EXPAND_LEVEL_KEY, 1);
      proctree_expand_onelevel(p_active_form._proc_tree);
      break;

   case "expandtwolevels":
      child_wid._SetBufferInfoHt(TBPROCTREE_EXPAND_LEVEL_KEY, 2);
      proctree_expand_twolevels(p_active_form._proc_tree);
      break;

   case "expandtostatements":
      def_proc_tree_expand_level = -1;
      child_wid._SetBufferInfoHt(TBPROCTREE_EXPAND_LEVEL_KEY, -1);
      _ProcTreeOptionsChanged(p_active_form);
      _TreeDelete(TREE_ROOT_INDEX, 'C');
      break;
   }

   if (olddef_tag_select_options != def_tag_select_options) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _tagselect_refresh_symbols();
      _macro('m',_macro('s'));
      _macro_append("def_tag_select_options="def_tag_select_options";");
   }
   if (olddef_proc_tree_options != def_proc_tree_options) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _ProcTreeOptionsChanged(p_active_form);
      if (!_no_child_windows()) {
         child_wid._UpdateCurrentTag(true);
      }
      SortProcTree(TREE_ROOT_INDEX,def_proc_tree_options,langId);
      _macro('m',_macro('s'));
      _macro_append("def_proc_tree_options="def_proc_tree_options";");
   }
   if (origExpandLevel != def_proc_tree_expand_level) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _ProcTreeOptionsChanged(p_active_form);
      if (!_no_child_windows()) {
         child_wid._UpdateCurrentTag(true);
      }
      _macro('m',_macro('s'));
      _macro_append("def_proc_tree_expand_level="def_proc_tree_expand_level";");
   }
   child_wid._set_focus();
}

static void _ProcTreeSetLastModified(int form_wid,int LastModified=-1, int RLine_LastModified=-1) {
   DEFS_FORM_INFO *pinfo=gDefsFormList._indexin(form_wid);
   if (pinfo) {
      pinfo->m_LastModified=LastModified;
      pinfo->m_RLine_LastModified= RLine_LastModified;
   }
}
void _ProcTreeOptionsChanged(int form_wid)
{
   _ProcTreeSetLastModified(form_wid);
}

void _xml_mod_proctree_menu(int menu_handle,int tree_index)
{
   int state,bm1,bm2;
   _TreeGetInfo(tree_index,state,bm1,bm2);
   int child_wid= _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }

   static bool in_xml_mod_proctree_menu;
   if (in_xml_mod_proctree_menu) return;
   in_xml_mod_proctree_menu=true;

   delete_menu_caption := "";
   delete_help_caption := "";
   xml_delete_command  := "ProcTreeXMLRunMenu delete";
   if (bm1==_pic_xml_tag || bm1==_pic_xml_target || bm1==_pic_xml_taguse) {
      delete_menu_caption=nls("Delete Element");
      delete_help_caption=nls("Deletes this element");
   }else if (bm1==_pic_xml_attr) {
      delete_menu_caption=nls("Delete Attribute");
      delete_help_caption=nls("Deletes this attribute");
   }

   status := 0;
   num_items_added := 0;
   buffer_ro_status := (child_wid._QReadOnly()? MF_GRAYED:MF_ENABLED);
   if (delete_help_caption != "") {
      status = _menu_insert(menu_handle,num_items_added,buffer_ro_status,
                            delete_menu_caption,xml_delete_command,"ncw",
                            "popup-imessage "delete_help_caption,
                            delete_help_caption
                            );
      ++num_items_added;
   }
   if (bm1==_pic_xml_tag || bm1==_pic_xml_target || bm1==_pic_xml_taguse) {
      status=_menu_insert(menu_handle,num_items_added,buffer_ro_status,
                          "Add Element...","ProcTreeXMLRunMenu addelement","ncw",
                          "popup-imessage "nls("Add an element"),
                          "Add an element"
                          );
      ++num_items_added;
   }
   status=_menu_insert(menu_handle,num_items_added,buffer_ro_status,
                       "Add Attribute...","ProcTreeXMLRunMenu addattr","ncw",
                       "popup-imessage "nls("Add an attribute"),
                       "Add element"
                       );
   ++num_items_added;
   status=_menu_insert(menu_handle,num_items_added,MF_ENABLED,
                       "XPath search...","ProcTreeXMLRunMenu xpathsearch","ncw",
                       "popup-imessage "nls("Run an XPath search"),
                       "XPath search"
                       );
   ++num_items_added;
   _menu_insert(menu_handle,num_items_added,MF_ENABLED,"-");
   in_xml_mod_proctree_menu=false;
}

static bool is_invalid_xml_element_name(_str name)
{
   ch := substr(name,1,1);
   /*if (!isalpha(ch) && ch!="_") {
      _message_box(nls("Element names must start with letters or '_'"));
      return(true);
   }*/
   // Cannot start with "xml" in any case
   if (strieq("xml",substr(name,1,3))) {
      _message_box(nls("Element names cannot start with XML"));
      return(true);
   }
   // Other characters that cannot be in the string
   if (pos(" <>=",substr(name,2))) {
      _message_box(nls("Element names cannot contain space,'<','>', or '='"));
      return(true);
   }
   return(false);
}

static bool is_invalid_xml_attribute_name(_str name)
{
   ch := substr(name,1,1);
   /*if (!isalpha(ch) && ch!="_") {
      _message_box(nls("Element names must start with letters or '_'"));
      return(true);
   }*/
   // Other characters that cannot be in the string
   if (pos(" <>=",substr(name,2))) {
      _message_box(nls("Element names cannot contain space,'<','>', or '='"));
      return(true);
   }
   return(false);
}

_command void ProcTreeXMLRunMenu(_str command_name="")
{
   if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Defs tool window");
      return;
   }
   if (command_name=="" || p_name!="_proc_tree") return;

   switch (lowcase(command_name)) {
   case "delete" :
      DeleteCurTagInProcTreeXML();
      break;
   case "addattr" :
      AddAttribute();
      break;
   case "addelement" :
      AddElement();
      break;
   case "xpathsearch" :
      XPathSearch();
      break;
   }
}

static void maybe_go_left()
{
   left();
   left_char := get_text(-1);
   if (left_char:!="/") {
      right();
   }
}
static void AddAttribute()
{
   int child_wid= _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }
   _str result = show("-modal _textbox_form",
                      "Add Attribute", // Form caption
                      TB_RETRIEVE_INIT,  //flags
                      "", //use default textbox width
                      "", //Help item.
                      "", //Buttons and captions
                      "add_attribute", //Retrieve Name
                      "-e "is_invalid_xml_element_name" Attribute name:",
                      "Attribute value:"
                     );
   if ( result=="" ) {
      return;
   }
   _str attribute_name=_param1;
   _str attribute_value=_param2;

   int file_index=TREE_ROOT_INDEX;
   filename := _TreeGetCaption(file_index);

   int tree_index,state,bm1,bm2;
   tree_index=_TreeCurIndex();

   node_is_attribute := false;
   _TreeGetInfo(tree_index,state,bm1,bm2);
   if (bm1==_pic_xml_attr) {
      node_is_attribute=true;
   }

   multi_line_begin_tag := false;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   context_id := _ProcTreeTagInfo(auto cm, auto proc_name, auto path, auto LineNumber, -1, p_active_form);
   if (context_id <= 0) return;

   int parent_context_id;
   if (node_is_attribute) {
      tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, parent_context_id);
   }else {
      parent_context_id=context_id;
   }

   wid := p_window_id;
   p_window_id=child_wid;

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

   quote_char := '"';
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
      _first_non_blank();
      _insert_text(attribute_name"="quote_char:+attribute_value:+quote_char);
   }else{
      int end_seek_pos;
      tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, parent_context_id, end_seek_pos);
      _GoToROffset(end_seek_pos);
      left();
      maybe_go_left();
      _insert_text(" "attribute_name"="quote_char:+attribute_value:+quote_char);
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
   int child_wid= _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }
   _str result = show("-modal _textbox_form",
                      "XPath Search", // Form caption
                      TB_RETRIEVE_INIT,  //flags
                      "", //use default textbox width
                      "", //Help item.
                      "", //Buttons and captions
                      "xpathsearch", //Retrieve Name
                      "XPath search string:"
                     );
   if ( result=="" ) {
      return;
   }
   _str xpath_query=_param1;

   int file_index=TREE_ROOT_INDEX;
   filename := _TreeGetCaption(file_index);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   _ProcTreeTagInfo(auto cm, auto proc_name, auto path, auto LineNumber, -1, p_active_form);

   if (child_wid._QShowStatementsInDefs()) {
      child_wid._UpdateStatements(true,false);
   } else {
      child_wid._UpdateContext(true,false);
   }

   status := 0;
   int xml_handle=_xmlcfg_open_from_buffer(child_wid,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if (xml_handle<0) {
      _message_box(nls("Could not open file '%s'\n\n%s",filename,get_message(status)));
      return;
   }
   typeless found_indexes[]=null;
   status=_xmlcfg_find_simple_array(xml_handle,xpath_query,found_indexes);

   wid := p_window_id;
   p_window_id=child_wid;

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
      if (result!="" && result!=COMMAND_CANCELLED_RC) {
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
   cap := "";
   int last_node_type=_xmlcfg_get_type(xml_handle,xml_index);
   name := _xmlcfg_get_name(xml_handle,xml_index);
   path_separator := "/";
   if (last_node_type==VSXMLCFG_NODE_ATTRIBUTE) {
      cap="@"name;
      path_separator="";
   }else{
      cap=name;
   }
   for (;;) {
      xml_index=_xmlcfg_get_parent(xml_handle,xml_index);
      if (xml_index==TREE_ROOT_INDEX) break;
      cap=_xmlcfg_get_name(xml_handle,xml_index):+path_separator:+cap;
      path_separator="/";
   }
   cap=path_separator:+cap;
   return(cap);
}

static void DeleteCurTagInProcTreeXML()
{
   child_wid := _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   if (child_wid._QShowStatementsInDefs()) {
      child_wid._UpdateStatements(true,false);
   } else {
      child_wid._UpdateContext(true,false);
   }

   file_index := TREE_ROOT_INDEX;
   filename := _TreeGetCaption(file_index);

   context_id := _ProcTreeTagInfo(auto cm, auto proc_name, auto path, auto LineNumber, -1, p_active_form);
   if (context_id <= 0) return;

   wid := p_window_id;
   p_window_id=child_wid;
   markid := _alloc_selection();
   _GoToROffset(cm.seekpos);
   status := _select_char(markid);
   if (status) {
      clear_message();
      return;
   }
   first_line := p_line;
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
   if (strip(line)=="") {
      _delete_line();
   }
   _first_non_blank();

   _set_focus();
   p_window_id=wid;
}

static void AddElement()
{
   child_wid := _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }
   result := show("-modal _xml_add_element_form");
   if (result=="") {
      return;
   }
   form_wid := p_active_form;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   if (child_wid._QShowStatementsInDefs()) {
      child_wid._UpdateStatements(true,false);
   } else {
      child_wid._UpdateContext(true,false);
   }

   element_name := _param1;
   end_tag_required := _param2;
   node_type := end_tag_required?VSXMLCFG_NODE_ELEMENT_START_END:VSXMLCFG_NODE_ELEMENT_START;

   file_index := TREE_ROOT_INDEX;
   filename := _TreeGetCaption(file_index);


   wid := p_window_id;
   p_window_id=child_wid;
   context_id := _ProcTreeTagInfo(auto cm, auto proc_name, auto path, auto LineNumber, -1, form_wid);
   if (context_id <= 0) return;
   _GoToROffset(cm.end_seekpos);
   left();

   left();
   split_current_tag := (get_text(-1):=="/");
   right();

   indent_amount := LanguageSettings.getSyntaxIndent(_edit_window().p_LangId);

   element_tag := "";
   if (end_tag_required) {
      element_tag="<"element_name"></"element_name">";
   }else{
      element_tag="<"element_name"/>";
   }

   // remove the / at the end of the tag and insert a new end tag
   if (split_current_tag) {
      // use the line where the tag starts to get the indent_str
      typeless cur_pos;
      save_pos(cur_pos);
      p_line=cm.line_no;
      get_line(auto cur_line);
      restore_pos(cur_pos);
      indent_str := "";
      p := pos('[~\t ]',cur_line,1,'r');
      if (p>1) {
         indent_str=substr(cur_line,1,p-1);
      }
      get_line(cur_line);
      int cursor_offset=text_col(cur_line,p_col,'P');
      leading := substr(cur_line,1,cursor_offset-2);
      trailing := substr(cur_line,cursor_offset+1);
      if (cm.line_no!=cm.end_line_no) {
         replace_line(leading">");
         insert_line(indent_str"</"proc_name">"trailing);
         p_col=text_col(indent_str"</"proc_name);
      } else {
         replace_line(leading"></"proc_name">"trailing);
      }
   }

   if (cm.line_no!=cm.end_line_no) {
      // use the line where the tag starts to get the indent_str
      typeless cur_pos;
      save_pos(cur_pos);
      p_line=cm.line_no;
      get_line(auto cur_line);
      restore_pos(cur_pos);
      indent_str := "";
      p := pos('[~\t ]',cur_line,1,'r');
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
      status := search('/','@hck-');
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
   child_wid._set_focus();
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

defeventtab _xml_add_element_form;

void ctlok.on_create()
{
   _retrieve_prev_form();
}

void ctlok.lbutton_up()
{
   if (is_invalid_xml_element_name(ctlelement_name.p_text)) {
      ctlelement_name._text_box_error(nls("%s is not a valid element name",ctlelement_name.p_text));
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

   child := _TreeGetFirstChildIndex(index);
   while( child>0 ) {
      expandToLevel(child,level-1);
      child=_TreeGetNextSiblingIndex(child);
   }
}

// Expand children index node to the specified level.
// Assumes that the active window is a tree control.
static void collapseCurrentNodeToLevel(int top_index, int level)
{
   //say("collapseCurrentNodeToLevel H"__LINE__": level="level);
   if( level <= 0 ) {

      child_was_statement := false;
      this_is_statement   := false;
      index := _TreeCurIndex();
      while (index > 0) {
         if (_ProcTreeTagInfo(auto cm, auto proc_name, auto depth,  auto LineNumber, index, p_active_form)) {
            //say("collapseCurrentNodeToLevel H"__LINE__": level="depth" line="LineNumber" symbols="cm.member_name);
            //tag_browse_info_dump(cm, "collapseCurrentNodeToLevel", 1);
            if (tag_tree_type_is_statement(cm.type_name) || (cm.flags & SE_TAG_FLAG_IGNORE)) {
               //say("collapseCurrentNodeToLevel H"__LINE__": is statement");
               this_is_statement = true;
               _TreeGetInfo(index,auto show_children);
               if (show_children > 0) {
                  //say("collapseCurrentNodeToLevel H"__LINE__": COLLAPSING");
                  _TreeGetInfo(index,0);
               }
            } else {
               //say("collapseCurrentNodeToLevel H"__LINE__": NOT STATEMENT, child_was_statement="child_was_statement);
               if (child_was_statement) {
                  _TreeGetInfo(index,auto show_children);
                  if (show_children > 0) {
                     //say("collapseCurrentNodeToLevel H"__LINE__": COLLAPSING");
                     _TreeSetInfo(index, 0);
                  }
               }
               break;
            }
         }
         if (!this_is_statement && !child_was_statement) {
            //say("collapseCurrentNodeToLevel H"__LINE__": STOPPING");
            break;
         }
         index = _TreeGetParentIndex(index);
         child_was_statement = this_is_statement;
      }
      return;
   }

   top_depth := _TreeGetDepth(top_index);
   index := _TreeCurIndex();
   depth := _TreeGetDepth(index);

   while (index > 0 && depth-top_depth >= level) {
      _TreeGetInfo(index,auto show_children);
      if (show_children > 0) {
         _TreeSetInfo(index, 0);
      }
      index = _TreeGetParentIndex(index);
      --depth;
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
_command void proctree_expand_onelevel(_str tree_wid="", _str tree_index="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Defs tool window");
      return;
   }

   int treeWid;
   if( tree_wid!="" && isinteger(tree_wid) ) {
      treeWid=(int)tree_wid;
   } else {
      treeWid=GetProcTreeWID();
   }
   if( !treeWid ) return;

   int index;
   if( tree_index!="" && isinteger(tree_index) ) {
      index=(int)tree_index;
   } else {
      index=TREE_ROOT_INDEX;
   }
   if( index<0 ) return;

   mou_hour_glass(true);
   treeWid.p_redraw=false;

   def_proc_tree_expand_level=1;
   treeWid.expandToLevel(index,1);

   currentIndex  := treeWid._TreeCurIndex();
   if (def_proc_tree_options & PROC_TREE_AUTO_EXPAND) {
      treeWid._TreeSetCurIndex(currentIndex);
   } else {
      expandedIndex := treeWid._TreeGetExpandedIndex(currentIndex);
      treeWid._TreeSetCurIndex(expandedIndex);
   }

   treeWid.p_redraw=true;
   treeWid._TreeRefresh();
   mou_hour_glass(false);
}

/**
 * Expand the current file's children by 2 levels.
 * <p>
 * Optionally pass in the tree window id and index to expand
 * as arg(1) and arg(2) respectively. Otherwise, the tree window
 * id and index are calculated.
 * </p>
 */
_command void proctree_expand_twolevels(_str tree_wid="", _str tree_index="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Defs tool window");
      return;
   }

   int treeWid;
   if( tree_wid!="" && isinteger(tree_wid) ) {
      treeWid=(int)tree_wid;
   } else {
      treeWid=GetProcTreeWID();
   }
   if( !treeWid ) return;

   int index;
   if( tree_index!="" && isinteger(tree_index) ) {
      index=(int)tree_index;
   } else {
      index=TREE_ROOT_INDEX;
   }
   if( index<0 ) return;

   mou_hour_glass(true);
   treeWid.p_redraw=false;

   def_proc_tree_expand_level=2;
   treeWid.expandToLevel(index,2);

   currentIndex  := treeWid._TreeCurIndex();
   if (def_proc_tree_options & PROC_TREE_AUTO_EXPAND) {
      treeWid._TreeSetCurIndex(currentIndex);
   } else {
      expandedIndex := treeWid._TreeGetExpandedIndex(currentIndex);
      treeWid._TreeSetCurIndex(expandedIndex);
   }

   treeWid.p_redraw=true;
   treeWid._TreeRefresh();
   mou_hour_glass(false);
}

/**
 * Expand the current file's children recursively.
 * <p>
 * Optionally pass in the tree window id and index to expand
 * as arg(1) and arg(2) respectively. Otherwise, the tree window
 * id and index are calculated.
 * </p>
 */
_command void proctree_expand_children(_str tree_wid="", _str tree_index="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Defs tool window");
      return;
   }

   int treeWid;
   if( tree_wid!="" && isinteger(tree_wid) ) {
      treeWid=(int)tree_wid;
   } else {
      treeWid=GetProcTreeWID();
   }
   if( !treeWid ) return;

   int index;
   if( tree_index!="" && isinteger(tree_index) ) {
      index=(int)tree_index;
   } else {
      index=TREE_ROOT_INDEX;
      def_proc_tree_expand_level=0;
   }
   if( index<0 ) return;

   mou_hour_glass(true);
   treeWid.p_redraw=false;

   count := 0;
   treeWid.do_expand_children(index,count,false);

   treeWid.p_redraw=true;
   mou_hour_glass(false);
}

/**
 * Set a breakpoint or watchpoing on the current item selected
 * in the "Defs" tool window.
 */
_command int proctree_set_breakpoint() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG;
   } else if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Defs tool window");
      return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG;
   }

   form_wid := _tbGetActiveDefsForm();
   if (!form_wid) {
      _message_box("Set breakpoint requires a symbol.");
      return 0;
   }
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // find the tag name, file and line number
   if (_ProcTreeTagInfo(auto cm, auto proc_name, auto path, auto LineNumber, -1, form_wid) <= 0) {
      _message_box("Set breakpoint requires a symbol.");
      return 0;
   }

   return debug_set_breakpoint_on_tag(cm);
}


