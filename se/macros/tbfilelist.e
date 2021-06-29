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
#include "project.sh"
#import "cbrowser.e"
#import "clipbd.e"
#import "complete.e"
#import "context.e"
#import "diff.e"
#import "files.e"
#import "fileman.e"
#import "guiopen.e"
#import "help.e"
#import "listproc.e"
#import "main.e"
#import "picture.e"
#import "project.e"
#import "projutil.e"
#import "sellist.e"
#import "stdprocs.e"
#import "tagwin.e"
#import "tbcontrols.e"
#import "tbopen.e"
#import "tbsearch.e"
#import "se/ui/toolwindow.e"
#import "se/ui/mainwindow.e"
#import "se/ui/twevent.e"
#import "treeview.e"
#import "window.e"
#import "wkspace.e"
#endregion

//////////////////////////////////////////////////////////////////////////////
// Name of file list tool window form
//
static const TBFILES_FORM=  "_tbfilelist_form";
const DOCUMENT_TAB_FORM= "_document_tab_choose_file_form";

//////////////////////////////////////////////////////////////////////////////
// Constants used in dialog info
//
static const FILELIST_PATHS_STABILIZED=            'pathsStabilized';
static const FILELIST_RESIZE_TO_TREE_WIDTH=        'resizeToTreeWidth';
static const FILELIST_PROJECT_LIST_MODIFY=         'ProjectListModify';
static const FILELIST_WORKSPACE_LIST_MODIFY=       'WorkspaceListModify';
static const FILELIST_TIMER_ID=                    'TimerId';
static const FILELIST_FILTER_TEXT=                 'oldtext';
static const FILELIST_PRJ_FILTER_TEXT=             'projectoldtext';
static const FILELIST_WKSP_FILTER_TEXT=            'workspaceoldtext';
static const FILELIST_IGNORE_CBQUIT=               "ignore_cbquit_callback";
static const FILELIST_CURRENT_EDITOR_WID=          "editorctl_wid";
static const FILELIST_HASH_TAB=                    "filelist";
static const FILELIST_SHOW=                        'filelist_show';
static const FILELIST_IGNORE_SSTAB_ON_CHANGE=      "ignore_sstab_on_change";

//////////////////////////////////////////////////////////////////////////////
// forward declarations
// 

enum FILELIST_SHOW_STATE { 
   FILELIST_SHOW_OPEN_FILES,
   FILELIST_SHOW_PROJECT_FILES,
   FILELIST_SHOW_WORKSPACE_FILES,
   FILELIST_SHOW_DOCUMENT_TABS,
   FILELIST_SHOW_LAST
};

enum_flags FILELIST_FLAGS {
   FILELIST_NONE                         = 0x0
   ,FILELIST_DISMISS_ON_SELECTION        = 0x8
   ,FILELIST_PREFIX_MATCH                = 0x10 // No longer used, use
                                                // def_filelist_match_style.    
   ,FILELIST_RESTORE_COLUMN_WIDTHS       = 0x20
   ,FILELIST_SHOW_ABSOLUTE_PATHS         = 0x40
   ,FILELIST_MULTIPLE_FILTERS            = 0x80
};

/*
  Dan and I(clark) decided to put the active tab in
  a static variable which is auto restored since tabs are
  clicked on frequently and we didn't want the state file
  written.

  We could change this to just store dialog info vrestore.slk. 
  Can't rely on on_destroy though because it happens after
  the vrestore.slk file is written. Simply write dialog
  info when switch tabs.
*/
auto gfilelist_show = FILELIST_SHOW_OPEN_FILES;
auto gfilelist_pending_buffer_add_callback=false;
auto gfilelist_pending_project_change_callback=false;

FILELIST_FLAGS def_filelist_flags  =FILELIST_DISMISS_ON_SELECTION;
auto def_filelist_limit  = 5000;
int def_filelist_wc_ext_match_style = OPENTB_WC_RECURSIVE_EXACT_MATCHING;
int def_filelist_wc_match_style = OPENTB_WC_RECURSIVE_EXACT_MATCHING;
int def_filelist_non_wc_match_style = OPENTB_WC_RECURSIVE_CONTAINS_MATCHING;


static FILELIST_SHOW_STATE getFilelistShowState()
{
   _nocheck _control ctl_file_list;
   return _GetDialogInfoHt(FILELIST_SHOW, ctl_file_list);
}

struct TBFILES_FORM_INFO {
   int m_form_wid;
   bool m_force_refresh_workspace;
};
static TBFILES_FORM_INFO gtbFilesFormList:[];

static void _init_all_formobj(TBFILES_FORM_INFO (&formList):[],_str formName) {
   int last = _last_window_id();
   int i;
   for (i=1; i<=last; ++i) {
      if (_iswindow_valid(i) && i.p_object == OI_FORM && !i.p_edit) {
         if (i.p_name:==formName) {
            formList:[i].m_form_wid=i;
            formList:[i].m_force_refresh_workspace=true;
         }
      }
   }
}
/**
 * Called when this module is loaded (before defload).  Used to
 * initialize the timer variable and window IDs.
 */
definit()
{
   // IF editor is initializing from invocation
   if (arg(1)!='L') {

      // This has to be posted to be sure that the module
      // with _find_formobj is loaded
      //_post_call(restoreButton);
   }else{
      // Only want to do this if the module was reloaded
#if 0
      _pic_treesave=_update_picture(-1,'_f_save.svg');
      _pic_treesave_blank=_update_picture(-1,'_f_blank.svg');
#endif
   }

   _nocheck _control ctl_file_list;
   _nocheck _control ctl_project_list;
   _nocheck _control ctl_workspace_list;

   gtbFilesFormList._makeempty();
   _init_all_formobj(gtbFilesFormList,TBFILES_FORM);

   // THIS SHOULD NOT BE REQUIRED, BUT SOMETHING IS RESETTING THESE EVENTTABLES!!!!!
   filelist_eventtab_index := find_index("_tbfilelist_form.ctl_file_list",EVENTTAB_TYPE);
   if ( filelist_eventtab_index ) {
      TBFILES_FORM_INFO v;
      int form_wid;
      foreach (form_wid => v in gtbFilesFormList) {
         form_wid.ctl_project_list.p_eventtab=filelist_eventtab_index;
         form_wid.ctl_workspace_list.p_eventtab=filelist_eventtab_index;
      }
   }
   gfilelist_pending_buffer_add_callback=false;
   gfilelist_pending_project_change_callback=false;
}

//////////////////////////////////////////////////////////////////////////////
// Files Tool window
// 
defeventtab _tbfilelist_form;
// User wanted Ctrl+Shift+E and Ctrl+Shift+B to switch between the Buffers tab and Workspace tab
// of the Files tool winodw hwne the Filter text box has focus. For now, be conservative 
// and don't take over too many keys here. If another user wants access to more keys could use 
// key list from _tbfind_form tool window.
void _tbfilelist_form./*'C-A'-'C-Z',*/F2-F4,               'c-s-a'-'c-s-z','c-a-a'-'c-a-z','a-m-a'-'a-m-z','M-A'-'M-Z','S-M-A'-'S-M-Z'()
//void _tbfind_form.'C-A'-'C-Z','c-s-a'-'c-s-z','c-a-a'-'c-a-z',F1-F12,C_F12,A_F1-A_F12,S_F1-S_F12,'c-0'-'c-9','c-s-0'-'c-s-9','c-a-0'-'c-a-9','a-0'-'a-9','M-A'-'M-Z','M-0'-'M-9','S-M-A'-'S-M-Z','S-M-0'-'S-M-9'()
{
   _smart_toolwindow_hotkey();
}
void _tbfilelist_form.'C-TAB','C-S-TAB'()
{
   ctl_sstab.call_event(ctl_sstab.p_eventtab2, last_event(), 'e');
}
void ctl_sstab.on_change(int reason)
{
   typeless ignore_sstab_on_change=_GetDialogInfoHt(FILELIST_IGNORE_SSTAB_ON_CHANGE,_control ctl_file_list);
   if (ignore_sstab_on_change) {
      return;
   }
   prevColWidths := "";
   prevTreeWid := FileListGetCurrentTreeWid(getFilelistShowState());
   if ( prevTreeWid ) {
      prevTreeWid.getColWidths(prevColWidths);
   }

   if ( reason == CHANGE_TABACTIVATED ) {
      tabWID := 0;
      switch ( p_ActiveTab ) {
      case FILELIST_SHOW_DOCUMENT_TABS:
         showDocumentTabs();
         if ( prevColWidths != "" ) {
            ctl_file_list.getColWidths(auto currColWidths);
            if ( currColWidths != prevColWidths ) {
               ctl_file_list.setColWidths(prevColWidths);
            }
         }
         tabWID = ctl_file_list;
         if ( _GetDialogInfoHt("calledSizeColumns", ctl_file_list)!=1 ) {
            _SetDialogInfoHt("calledSizeColumns", 1, ctl_file_list);
            // We could be becoming  visible the first time, so see if we need 
            // to size columns to ontents
            _post_call(sizeColumns,ctl_file_list);
         }
         ctl_filter.forceFilterList(true);
         break;
      case FILELIST_SHOW_OPEN_FILES:
         showOpenFiles();
         if ( prevColWidths != "" ) {
            ctl_file_list.getColWidths(auto currColWidths);
            if ( currColWidths != prevColWidths ) {
               ctl_file_list.setColWidths(prevColWidths);
            }
         }
         tabWID = ctl_file_list;
         if ( _GetDialogInfoHt("calledSizeColumns", ctl_file_list)!=1 ) {
            _SetDialogInfoHt("calledSizeColumns", 1, ctl_file_list);
            // We could be becoming  visible the first time, so see if we need 
            // to size columns to ontents
            _post_call(sizeColumns,ctl_file_list);
         }
         //ctl_filter.forceFilterList(true);
         break;
      case FILELIST_SHOW_PROJECT_FILES:
         showProjectFiles();
         if ( prevColWidths != "" ) {
            ctl_project_list.getColWidths(auto currColWidths);
            if ( currColWidths != prevColWidths ) {
               ctl_project_list.setColWidths(prevColWidths);
            }
         }
         tabWID = ctl_project_list;
         // Now filter in showProjectFiles
//         ctl_proj_filter.forceFilterList(true);
         break;
      case FILELIST_SHOW_WORKSPACE_FILES:
         showWorkspaceFiles();
         if ( prevColWidths != "" ) {
            ctl_workspace_list.getColWidths(auto currColWidths);
            if ( currColWidths != prevColWidths ) {
               ctl_workspace_list.setColWidths(prevColWidths);
            }
         }
         tabWID = ctl_workspace_list;
         // Now filter in showWorkspaceFiles
//         ctl_wksp_filter.forceFilterList(true);
         break;
      }

      // find the tag name, file and line number
      if (tabWID && tabWID.FileListGetInfo(auto path,auto LineNumber)) {
         FileListUpdatePreview(path,LineNumber);
      }

      // If we set the tree control for what changed, resize the columns to be
      // sure the columns match the (new current) filter.
      if ( tabWID ) sizeColumns(tabWID);
   }
}

/**
 * On got focus event for the tree list controls.  Selects the
 * current line if there is a line, and one item or less is
 * selected.
 */
static void fileListTreeOnGotFocus()
{  
   curindex := _TreeCurIndex();
   if ( curindex < 0 ) {
      curindex=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if ( curindex>-1 ) {
         _TreeSelectLine(curindex);
      }
   }else{
      numSelected := _TreeGetNumSelectedItems();
      if ( 0 == numSelected ) {
         _TreeSelectLine(curindex);
     }
   }
}

static void filelist_rclickmenu()
{
   // Find out how many items are in the tree
   formwid := p_active_form;
   treewid := formwid.FileListGetCurrentTreeWid();
   if ( !treewid ) return;

   numSelected := _TreeGetNumSelectedItems();
   if ( numSelected<=1 ) {
      // If there is <=1 item selected, call lbutton_down event to select
      call_event(p_window_id,LBUTTON_DOWN);
      treewid._TreeRefresh();
   }
   int MenuIndex=find_index("_tbfilelist_menu",oi2type(OI_MENU));
   int menu_handle=_mdi._menu_load(MenuIndex,'P');

   int x,y;
   mou_get_xy(x,y);

   if ( def_one_file=="" ) {
      status := _menu_find(menu_handle,"tbfilelist-menu-command open-current",auto output_menu_handle,auto output_menu_pos,'M');
      if ( !status ) {
         _menu_delete(output_menu_handle,output_menu_pos);
      }
   }
   if ( treewid.p_name=="ctl_project_list" || treewid.p_name=="ctl_workspace_list" ) {
      // these items only apply to the files list
      status := _menu_find(menu_handle,"tbfilelist-menu-command save",auto output_menu_handle,auto output_menu_pos,'M');
      if ( !status ) {
         _menu_delete(output_menu_handle,output_menu_pos);
      }
      status = _menu_find(menu_handle,"tbfilelist-menu-command close",output_menu_handle,output_menu_pos,'M');
      if ( !status ) {
         _menu_delete(output_menu_handle,output_menu_pos);
      }
      status = _menu_find(menu_handle,"tbfilelist-menu-command addToProject",output_menu_handle,output_menu_pos,'M');
      if ( !status ) {
         _menu_delete(output_menu_handle,output_menu_pos);
      }
   } else {
      status := _menu_find(menu_handle,"tbfilelist-menu-command relativepaths",auto output_menu_handle,auto output_menu_pos,'M');
      if ( !status ) {
         _menu_delete(output_menu_handle,output_menu_pos);
      }
   }

   // no workspace open?
   if (_workspace_filename == "") {
      status := _menu_find(menu_handle,"tbfilelist-menu-command addToProject",auto output_menu_handle, auto output_menu_pos,'M');
      if ( !status ) {
         _menu_delete(output_menu_handle,output_menu_pos);
      }
   }

   if ( def_filelist_flags&FILELIST_DISMISS_ON_SELECTION ) {
      _menu_set_state(menu_handle,"tbfilelist-menu-command dismiss",MF_CHECKED,'M');
   }
   if ( def_filelist_flags&FILELIST_PREFIX_MATCH ) {
      _menu_set_state(menu_handle,"tbfilelist-menu-command prefixmatch",MF_CHECKED,'M');
   }
   if ( !(def_filelist_flags&FILELIST_RESTORE_COLUMN_WIDTHS) ) {
      _menu_set_state(menu_handle,"tbfilelist-menu-command autocolumnwidths",MF_CHECKED,'M');
   }
   if ( !(def_filelist_flags&FILELIST_SHOW_ABSOLUTE_PATHS) ) {
      _menu_set_state(menu_handle,"tbfilelist-menu-command relativepaths",MF_CHECKED,'M');
   }
   if ( def_filelist_flags&FILELIST_MULTIPLE_FILTERS ) {
      _menu_set_state(menu_handle,"tbfilelist-menu-command multiplefilters",MF_CHECKED,'M');
   }

   switch ( def_filelist_wc_ext_match_style ) {
   case OPENTB_WC_RECURSIVE_CONTAINS_MATCHING:
      _menu_set_state(menu_handle,"tbfilelist-menu-command wc_ext recursiveContains",MF_CHECKED,'M');
      break;
   case OPENTB_WC_RECURSIVE_EXACT_MATCHING:
      _menu_set_state(menu_handle,"tbfilelist-menu-command wc_ext recursiveExact",MF_CHECKED,'M');
      break;
   case OPENTB_WC_RECURSIVE_PREFIX_MATCHING:
      _menu_set_state(menu_handle,"tbfilelist-menu-command wc_ext recursivePrefix",MF_CHECKED,'M');
      break;
   }
   switch ( def_filelist_wc_match_style ) {
   case OPENTB_WC_RECURSIVE_CONTAINS_MATCHING:
      _menu_set_state(menu_handle,"tbfilelist-menu-command wc recursiveContains",MF_CHECKED,'M');
      break;
   case OPENTB_WC_RECURSIVE_EXACT_MATCHING:
      _menu_set_state(menu_handle,"tbfilelist-menu-command wc recursiveExact",MF_CHECKED,'M');
      break;
   case OPENTB_WC_RECURSIVE_PREFIX_MATCHING:
      _menu_set_state(menu_handle,"tbfilelist-menu-command wc recursivePrefix",MF_CHECKED,'M');
      break;
   }
   switch ( def_filelist_non_wc_match_style ) {
   case OPENTB_WC_RECURSIVE_CONTAINS_MATCHING:
      _menu_set_state(menu_handle,"tbfilelist-menu-command non_wc recursiveContains",MF_CHECKED,'M');
      break;
   case OPENTB_WC_RECURSIVE_EXACT_MATCHING:
      _menu_set_state(menu_handle,"tbfilelist-menu-command non_wc recursiveExact",MF_CHECKED,'M');
      break;
   case OPENTB_WC_RECURSIVE_PREFIX_MATCHING:
      _menu_set_state(menu_handle,"tbfilelist-menu-command non_wc recursivePrefix",MF_CHECKED,'M');
      break;
   }
   status := _menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

/**
 * Sets bit flag <B>flagToFlip</B> in variable <B>flagVar</B>.
 * Also sets _config_modify
 * @param flagVar Variable that contains big flags
 * @param flagToFlip bit flag to change
 * @param onlyRemove if true, remove flagToFlip if it is in
 *                   flagVar, but do not set it if it is not
 */
static void set_defvar_flag(FILELIST_FLAGS &flagVar,FILELIST_FLAGS flagToFlip,bool onlyRemove=false)
{
   if ( flagVar&flagToFlip ) {
      flagVar &= ~flagToFlip;
   }else{
      if ( !onlyRemove ) {
         flagVar |= flagToFlip;
      }
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

int _OnUpdate_tbfilelist_menu_command(CMDUI& cmdui, int target_wid, _str command)
{
   parse command with . auto name; 
   if (target_wid && target_wid.p_object==OI_TREE_VIEW) {
      treewid := p_active_form.FileListGetCurrentTreeWid();
      if (name=='open' || name=='open-current' || name=='diff' || name=='addToProject' || name=='save' || name=='close') {
         index := treewid._TreeGetNextSelectedIndex(1,auto info);
         if (index>=0) {
            return MF_ENABLED;
         }
         return MF_GRAYED;
      }
      if (name=='copy-name' || name=='copy-path') {
         index:=treewid._TreeCurIndex();
         if (index>0) {
            return MF_ENABLED;
         }
         return MF_GRAYED;
      }
   }
   return MF_ENABLED;
}
_command void tbfilelist_menu_command(_str cmdline="") name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   formwid := tbGetActiveFilesForm();
   if ( !formwid ) return;

   treewid := formwid.FileListGetCurrentTreeWid();
   if ( !treewid ) return;

   _str arg1=parse_file(cmdline);
   switch ( arg1 ) {
   case "open":
      treewid.open_selected_files();
      break;
   case "open-current":
      treewid.open_selected_file_in_current_window();
      break;
   case "copy-name":
   case "copy-path":
      {
         index:=_TreeCurIndex();
         if (index>0) {
            _str editCommands[];
            treewid.FileListEditFile(index,'',&editCommands,true);
            if (editCommands._length()) {
               if (arg1=='copy-name') {
                  push_clipboard(_strip_filename(editCommands[0],'p'));
               } else {
                  push_clipboard(editCommands[0]);
               }
            }
         }
      }
      break;
   case "save":
      _nocheck _control ctl_save_button;
      formwid.ctl_save_button.call_event(formwid.ctl_save_button,LBUTTON_UP);
      break;
   case "diff":
      if (!_haveDiff()) {
         popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Diff");
         return;
      }
      _nocheck _control ctl_diff_button;
      formwid.ctl_diff_button.call_event(formwid.ctl_diff_button,LBUTTON_UP);
      break;
   case "close":
      _nocheck _control ctl_close_button;
      formwid.ctl_close_button.call_event(formwid.ctl_close_button,LBUTTON_UP);
      break;
   case "addToProject":
      add_selected_files_to_project();
      break;
   case "viewopen":
      formwid.showOpenFiles();
      break;
   case "viewproject":
      formwid.showProjectFiles();
      break;
   case "viewworkspace":
      formwid.showWorkspaceFiles();
      break;
   case "dismiss":
      set_defvar_flag(def_filelist_flags,FILELIST_DISMISS_ON_SELECTION);
      break;
   case "autocolumnwidths":
      set_defvar_flag(def_filelist_flags,FILELIST_RESTORE_COLUMN_WIDTHS);
      sizeColumns(treewid);
      break;
   case "relativepaths":
      set_defvar_flag(def_filelist_flags,FILELIST_SHOW_ABSOLUTE_PATHS);
      filterWid := formwid.FileListGetCurrentFilterWid();
      if ( filterWid ) filterWid.forceFilterList();
      break;
   case "multiplefilters":
      set_defvar_flag(def_filelist_flags,FILELIST_MULTIPLE_FILTERS);
      break;
   case "refresh":
      workspace_refresh();  // has callbacks to refresh tool windows
      break;
   case "wc_ext":
      {
         _str arg2=parse_file(cmdline);
         switch (arg2) {
         case "recursiveContains":
            def_filelist_wc_ext_match_style = OPENTB_WC_RECURSIVE_CONTAINS_MATCHING;
            break;
         case "recursiveExact":
            def_filelist_wc_ext_match_style = OPENTB_WC_RECURSIVE_EXACT_MATCHING;
            break;
         }
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      break;

   case "wc":
      {
         _str arg2=parse_file(cmdline);
         switch (arg2) {
         case "recursiveContains":
            def_filelist_wc_match_style = OPENTB_WC_RECURSIVE_CONTAINS_MATCHING;
            break;
         case "recursiveExact":
            def_filelist_wc_match_style = OPENTB_WC_RECURSIVE_EXACT_MATCHING;
            break;
         case "recursivePrefix":
            def_filelist_wc_match_style = OPENTB_WC_RECURSIVE_PREFIX_MATCHING;
            break;
         }
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      break;

   case "non_wc":
      {
         _str arg2=parse_file(cmdline);
         switch (arg2) {
         case "recursiveContains":
            def_filelist_non_wc_match_style = OPENTB_WC_RECURSIVE_CONTAINS_MATCHING;
            break;
         case "recursiveExact":
            def_filelist_non_wc_match_style = OPENTB_WC_RECURSIVE_EXACT_MATCHING;
            break;
         case "recursivePrefix":
            def_filelist_non_wc_match_style = OPENTB_WC_RECURSIVE_PREFIX_MATCHING;
            break;
         }
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      break;
   }
}

static void forceFilterList(bool doSelect=false)
{
   _control ctl_file_list;
   _SetDialogInfoHt(FILELIST_FILTER_TEXT,null,ctl_file_list);
   _SetDialogInfoHt(FILELIST_PRJ_FILTER_TEXT,null,ctl_file_list);
   _SetDialogInfoHt(FILELIST_WKSP_FILTER_TEXT,null,ctl_file_list);
   call_event(CHANGE_OTHER,p_window_id,ON_CHANGE,'W');
   p_window_id._set_focus();

   if ( doSelect && p_text!="" ) {
      _set_sel(1,length(p_text)+1);
   }
}

void _tbfilelist_form.on_load()
{
   textwid := FileListGetCurrentFilterWid();
   if ( textwid ) {
      textwid._set_focus();
   }
   treewid := FileListGetCurrentTreeWid();
   if ( treewid ) {
      origWID := p_window_id;
      p_window_id=treewid;
      curindex := _TreeCurIndex();
      if ( curindex > -1 ) {
         _TreeDeselectAll();
         _TreeSelectLine(curindex);
      }
      p_window_id=origWID;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Files tool window event handlers
//

void ctl_file_list.on_got_focus()
{
   // Call the fileListTreeOnGotFocus function to select the current line
   fileListTreeOnGotFocus();
}

static _str getAbsoluteFilePathInFileList(_str filePath)
{
   if (def_filelist_flags & FILELIST_SHOW_ABSOLUTE_PATHS) {
      return filePath;
   }
   if ( p_active_form.ctl_sstab.p_ActiveTab == FILELIST_SHOW_DOCUMENT_TABS ) {
      return filePath;
   }
   relative_to_dir := "";
   if ( p_active_form.ctl_sstab.p_ActiveTab == FILELIST_SHOW_OPEN_FILES ) {
      relative_to_dir = getcwd();
   } else if ( p_active_form.ctl_sstab.p_ActiveTab == FILELIST_SHOW_PROJECT_FILES ) {
      relative_to_dir = _strip_filename(_project_name, 'N');
   } else if ( p_active_form.ctl_sstab.p_ActiveTab == FILELIST_SHOW_WORKSPACE_FILES ) {
      relative_to_dir = _strip_filename(_workspace_filename, 'N');
   }
   return absolute(filePath, relative_to_dir);
}

int getAbsoluteFilenameInFilesToolWindow(int treeWID,int treeIndex,_str &filename)
{
   if ( treeWID<0 || !_iswindow_valid(treeWID) ) {
      return -1;
   }
   curFilename := treeWID._TreeGetCaption(treeIndex);
   parse curFilename with auto namePart "\t" auto pathPart;
   name=strip_buffer_id(namePart);
   pathPart = treeWID.getAbsoluteFilePathInFileList(pathPart);
   filename = pathPart:+name;
   return 0;
}

void ctl_file_list."C-C","C-ins"()
{
   // Find out how many items are in the tree
   treeCurIndex := _TreeCurIndex();
   if ( treeCurIndex<0 ) return;
   treewid := p_window_id;
   orig_wid := _create_temp_view(auto temp_wid=0);
   if (treewid._TreeGetNumSelectedItems() > 1) {
      int info;
      for (ff:=1;;ff=0) {
         index := treewid._TreeGetNextSelectedIndex(ff,info);
         if (index <= 0) break;
         curFilename := treewid._TreeGetCaption(index);
         parse curFilename with auto namePart "\t" auto pathPart;
         namePart=strip_buffer_id(namePart);
         pathPart = treewid.getAbsoluteFilePathInFileList(pathPart);
         insert_line(pathPart:+namePart);
      }
      select_all_line();
      copy_to_clipboard();
      _deselect();

   } else {
      curFilename := treewid._TreeGetCaption(treeCurIndex);
      parse curFilename with auto namePart "\t" auto pathPart;
      namePart=strip_buffer_id(namePart);
      pathPart = treewid.getAbsoluteFilePathInFileList(pathPart);
      insert_line(pathPart:+namePart);
      copy_to_clipboard();
   }
   activate_window(treewid);
   _delete_temp_view(temp_wid);
}

/**
 * Also open files on Alt+E, Command+E 
 * Not specifying 'Enter' key here as that is 
 * generated from the OnChange/LeafEnter event 
 */
void ctl_file_list."A-E","M-E"()
{
   open_selected_files();
}

void ctl_file_list.lbutton_up()
{
   if (p_active_form.p_name == DOCUMENT_TAB_FORM) {
      open_selected_files();
   }
}

void ctl_file_list."C-S","A-S","M-S","A-W"()
{
   if ( p_name=="ctl_file_list" ) {
      save_current_item();
   }
}

static void maybeSelectOneLine()
{
   numSelected := _TreeGetNumSelectedItems();
   if ( !numSelected ) {
      curIndex := _TreeCurIndex();
      if ( curIndex>-1 ) {
         _TreeSelectLine(curIndex);
      }
   }
}

void ctl_file_list."A-C","M-C","A-D","M-D",DEL()
{
   if (p_active_form._find_control("ctl_sstab") <= 0) return;
   curFocusWID := _get_focus();

   if ( p_name=="ctl_file_list" ) {
      if (_TreeGetNumSelectedItems() > 1) {
         call_event(_control ctl_close_button,LBUTTON_UP);
      } else {
         close_current_item();
      }
      maybeSelectOneLine();
   }
   if ( _get_focus() != curFocusWID ) curFocusWID._set_focus();
}

void ctl_file_list.rbutton_up()
{
   if (p_active_form._find_control("ctl_sstab") <= 0) return;
   filelist_rclickmenu();
}

/**
 * Called when the tool window is instantiated.
 */
void ctl_file_list.on_create(FILELIST_FLAGS flags=FILELIST_NONE,FILELIST_SHOW_STATE filelist_show=FILELIST_SHOW_LAST, int editorctl_wid=0)
{
   if ( p_name=="ctl_file_list" ) {
      TBFILES_FORM_INFO info;

      info.m_form_wid=p_active_form;
      info.m_force_refresh_workspace=true;
      if (p_active_form.p_name==TBFILES_FORM) {
         gtbFilesFormList:[p_active_form]=info;
      }
   }
   // set up the column buttons
   initTree();

   // Determine which file list to show
   if (filelist_show==FILELIST_SHOW_LAST) {
      if (p_active_form._find_control("ctl_sstab") > 0) {
         if (!isinteger(gfilelist_show)) {
            gfilelist_show=FILELIST_SHOW_OPEN_FILES;
         }
         filelist_show=gfilelist_show;
      } else if (def_one_file != "") {
         filelist_show=FILELIST_SHOW_DOCUMENT_TABS;
      } else {
         filelist_show=FILELIST_SHOW_OPEN_FILES;
      }
   }
   if (!_haveSmartOpen()) {
      switch ((int)filelist_show) {
      case (int)FILELIST_SHOW_WORKSPACE_FILES:
      case (int)FILELIST_SHOW_PROJECT_FILES:
      case (int)FILELIST_SHOW_LAST:
         filelist_show=FILELIST_SHOW_OPEN_FILES;
         break;
      }
   }
   _SetDialogInfoHt(FILELIST_SHOW,filelist_show,ctl_file_list);

   list_to_show := "";
   if ( filelist_show== FILELIST_SHOW_OPEN_FILES || filelist_show == FILELIST_SHOW_DOCUMENT_TABS ) {
      list_to_show = "ctl_file_list";
   } else if ( filelist_show== FILELIST_SHOW_PROJECT_FILES ) {
      list_to_show = "ctl_project_list";
   } else if ( filelist_show== FILELIST_SHOW_WORKSPACE_FILES ) {
      list_to_show = "ctl_workspace_list";
   }

   // This event table is used for all 3 buttons so we only want this called once!
   if (p_name == list_to_show) {
      if (editorctl_wid==0 && !_no_child_windows()) editorctl_wid=_mdi.p_child;
      _SetDialogInfoHt(FILELIST_IGNORE_SSTAB_ON_CHANGE, 0, ctl_file_list);
      _SetDialogInfoHt(FILELIST_CURRENT_EDITOR_WID, editorctl_wid, ctl_file_list);
      _SetDialogInfoHt(FILELIST_HASH_TAB,null,ctl_file_list);

      _SetDialogInfoHt(FILELIST_FILTER_TEXT,null,ctl_file_list);
      _SetDialogInfoHt(FILELIST_PRJ_FILTER_TEXT,null,ctl_file_list);
      _SetDialogInfoHt(FILELIST_WKSP_FILTER_TEXT,null,ctl_file_list);


      _SetDialogInfoHt(FILELIST_IGNORE_CBQUIT,"0",ctl_file_list);


      _SetDialogInfoHt(FILELIST_PROJECT_LIST_MODIFY,"1",ctl_file_list);  // Need to update project list
      _SetDialogInfoHt(FILELIST_WORKSPACE_LIST_MODIFY,"1",ctl_file_list); // Need to update workspace list

      if ( filelist_show== FILELIST_SHOW_DOCUMENT_TABS ) {
         showDocumentTabs();
      } else if ( filelist_show== FILELIST_SHOW_OPEN_FILES ) {
         showOpenFiles();
      } else if ( filelist_show== FILELIST_SHOW_PROJECT_FILES ) {
         showProjectFiles();
      } else if ( filelist_show== FILELIST_SHOW_WORKSPACE_FILES ) {
         showWorkspaceFiles();
      }

      if ( p_name=="ctl_file_list" ) {
         _TreeGetSortCol(auto col, auto order);
         // if we are sorting by path, we need to make sure the filenames got sorted first
         if (col == 1) {
            // Path sort is stabilized, but not necessarily with first column 
            // (filename column) until it has been sorted once itself.
            // Check to be sure that the filename column is sorted once
            pathsStabilized := _GetDialogInfoHt(FILELIST_PATHS_STABILIZED, ctl_file_list);  // Need to update project list
            if ( pathsStabilized!=1 ) {
               _TreeSortCol(0);
               _TreeSortCol(1, (order == TREEVIEW_DESCENDINGORDER) ? 'FD' : 'F');
               _SetDialogInfoHt(FILELIST_PATHS_STABILIZED,1,ctl_file_list);  // Need to update project list
            }
         }
      }
   }
   if (p_active_form._find_control("ctl_sstab") > 0) {
      ctl_sstab.p_DocumentMode = true;
   } else if (p_active_form.p_name == DOCUMENT_TAB_FORM) {
      DocumentTabFileListResize();
   }
   if (!_haveSmartOpen() && p_name=='ctl_workspace_list') {
      if (p_active_form._find_control("ctl_sstab") > 0) {
         _SetDialogInfoHt(FILELIST_IGNORE_SSTAB_ON_CHANGE, 1, ctl_file_list);
         ctl_sstab.p_ActiveTab = FILELIST_SHOW_WORKSPACE_FILES;
         ctl_sstab._deleteActive();
         ctl_sstab.p_ActiveTab = FILELIST_SHOW_PROJECT_FILES;
         ctl_sstab._deleteActive();
         _SetDialogInfoHt(FILELIST_IGNORE_SSTAB_ON_CHANGE, 0, ctl_file_list);
      }
   }

}

/** 
 * Occasionally there is an issue where the columns get all 
 * collapsed and the caption does not appear.  If the columns 
 * are too short, set them to the width of the tree. 
 */
static void FixColumns()
{
   numCols := _TreeGetNumColButtons();
   for ( i:=0;i<numCols;++i ) {
      _TreeGetColButtonInfo(i,auto colWidth,auto buttonFlagsCol,auto stateCol,auto captionCol);
      if ( colWidth<200 ) {
         colWidth = p_width intdiv 2;
         setColWidths(colWidth' 'colWidth);
         break;
      }
   }
}

static const DEFAULT_COLUMN_WIDTH= 1;

static void initTree()
{
   treeWid := p_window_id;
   flags := TREE_BUTTON_SORT|TREE_BUTTON_SORT_FILENAME;
   _TreeSetColButtonInfo(0,DEFAULT_COLUMN_WIDTH,flags,0,"Name");
   _TreeSetColButtonInfo(1,DEFAULT_COLUMN_WIDTH,flags|TREE_BUTTON_IS_FILENAME,0,"Path");
   FileListManager_SetDisplayCallback(treeWid.getFileListManagerHandle(), treeWid);
}

// Was used for debugging
//static _str getWidths()
//{
//   allWidth := "";
//   int numButtons=_TreeGetNumColButtons();
//   for (i:=0;i<numButtons;++i) {
//      _TreeGetColButtonInfo(i,auto width,auto flags,auto state,auto caption);
//      allWidth=allWidth:+" ":+width;
//   }
//   return strip(allWidth);
//}

/**
 * Called when the tool window is closed.
 */
void _tbfilelist_form.on_destroy()
{
   if (p_active_form._find_control("ctl_sstab") > 0) {
      gfilelist_show=getFilelistShowState();
      gtbFilesFormList._deleteel(p_active_form);
   }
   cur_tree_wid := FileListGetCurrentTreeWid();
   if ( cur_tree_wid ) {
      cur_tree_wid._TreeAppendColButtonInfo(true);

      cur_tree_wid._TreeAppendColButtonInfo(true,"ctl_project_list");
      cur_tree_wid._TreeAppendColButtonInfo(true,"ctl_workspace_list");
      cur_tree_wid._TreeAppendColButtonInfo(true,"ctl_file_list");
      // Call user-level2 ON_DESTROY so that tool window docking info is saved
      call_event(p_window_id,ON_DESTROY,'2');
   }
}

/**
 * Called when the tool window is resized.
 */
void _tbfilelist_form.on_resize()
{
   if (p_active_form._find_control("ctl_sstab") <= 0) {
      return;
   }
   int containerW = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   int containerH = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   clientWidth := containerW;
   
   // resize the tab control
   ctl_sstab.p_width = containerW;
   ctl_sstab.p_height = containerH;
   containerW = ctl_sstab.p_child.p_width;
   containerH = ctl_sstab.p_child.p_height;
      
   // resize toolbar buttons if they are too large 
   // (allow them to be at most 33% larger)
   max_button_height := ctl_filter.p_y_extent;
   max_button_height += (max_button_height intdiv 3);

   ctl_save_button.resizeToolButton(max_button_height);
   ctl_close_button.resizeToolButton(max_button_height);
   ctl_diff_button.resizeToolButton(max_button_height);
         
   // resize the x-positions of the toolbar buttons
   int hspace = _dx2lx(SM_TWIP, def_toolbar_pic_hspace);
   alignControlsHorizontal(containerW - ctl_diff_button.p_width*3 - hspace*4,
                           0,
                           hspace,
                           ctl_save_button.p_window_id,
                           ctl_close_button.p_window_id,
                           _haveDiff()? ctl_diff_button.p_window_id : 0);

   // everybody step to the far left
   ctl_file_list.p_x = 0;
   if (_haveSmartOpen()) {
      ctl_project_list.p_x = 0;
      ctl_workspace_list.p_x = 0;
   }

   // resize the width of the filter controls
   ctl_filter.p_width = ctl_save_button.p_x - ctlfilter_label.p_x - ctl_filter.p_x;
   ctl_file_list.p_width = containerW - ctl_filter.p_x - ctlfilter_label.p_x; 
   if (_haveSmartOpen()) {
      ctl_proj_filter.p_x_extent = containerW - ctlfilter_label.p_x; 
      ctl_wksp_filter.p_width = containerW - ctl_proj_filter.p_x - ctlfilter_label.p_x; 
   }
   
   // resize the list widths
   ctl_file_list.p_width = containerW - ctl_file_list.p_x*2;
   if (_haveSmartOpen()) {
      ctl_project_list.p_width = containerW - ctl_file_list.p_x*2;
      ctl_workspace_list.p_width = containerW - ctl_file_list.p_x*2;
   }

   // reposition the file list to make room for icons, if necessary
   y1 := ctl_save_button.p_y_extent + ctl_save_button.p_y;
   y2 := ctl_filter.p_y_extent + ctl_filter.p_y;
   ctl_file_list.p_y = (y1 > y2)?  y1:y2;
   if ( y1 < y2 ) {
      ctl_save_button.p_y  = (y2 - ctl_save_button.p_height) intdiv 2;
      ctl_close_button.p_y = (y2 - ctl_close_button.p_height) intdiv 2;
      ctl_diff_button.p_y  = (y2 - ctl_diff_button.p_height) intdiv 2;
   }
   if (!_haveDiff()) {
      ctl_diff_button.p_enabled = false;
      ctl_diff_button.p_visible = false;
   }

   // resize the list heights
   ctl_file_list.p_y_extent = containerH ;
   if (_haveSmartOpen()) {
      ctl_project_list.p_y_extent = containerH ;
      ctl_workspace_list.p_y_extent = containerH ;
   }
   
   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      // First time
      ctl_file_list._TreeRetrieveColButtonInfo(true);
      if ( ctl_sstab.p_ActiveTab == FILELIST_SHOW_DOCUMENT_TABS ) {
         sizeColumns(ctl_file_list);
      } else if ( ctl_sstab.p_ActiveTab == FILELIST_SHOW_OPEN_FILES ) {
         sizeColumns(ctl_file_list);
      } else if ( ctl_sstab.p_ActiveTab == FILELIST_SHOW_PROJECT_FILES ) {
         sizeColumns(ctl_project_list);
      } else if ( ctl_sstab.p_ActiveTab == FILELIST_SHOW_WORKSPACE_FILES ) {
         sizeColumns(ctl_workspace_list);
      }
   }

   // Only scale the buttons for the ctl_file_list tree, when the user clicks
   // a button, they will be sized to match the last one.
   ctl_file_list.maybeScaleButtons();
   ctl_file_list.FixColumns();
}

static void maybeScaleButtons()
{
   // Get size of the column buttons
   _TreeGetColButtonInfo(0,auto bw1,auto bf1,auto state1,auto cap1);
   _TreeGetColButtonInfo(0,auto bw2,auto bf2,auto state2,auto cap2);

   // Check to see if the size of the column buttons matches the default width
   // OR resizeToTreeWidth is true.  Because the tool window code will send us
   // multiple resize events, we will set a flag after the first time so we can
   // continue to resize until we are called and the form is visible
   if ( (bw1==DEFAULT_COLUMN_WIDTH && bw2==DEFAULT_COLUMN_WIDTH) || 
        _GetDialogInfoHt(FILELIST_RESIZE_TO_TREE_WIDTH,ctl_file_list)==true ) {
      if ( p_active_form.p_visible ) {
         _SetDialogInfoHt(FILELIST_RESIZE_TO_TREE_WIDTH,false,ctl_file_list);
      }else{
         _SetDialogInfoHt(FILELIST_RESIZE_TO_TREE_WIDTH,true,ctl_file_list);
         _TreeScaleColButtonWidths(ctl_file_list.p_width);
      }
   }
}

static void maybeSetColWidths(_str target_col_widths)
{
   _str cur_col_widths;
   getColWidths(cur_col_widths);
   if ( cur_col_widths!=target_col_widths ) {
      setColWidths(target_col_widths);
   }
}

static void getColWidths(_str &col_widths)
{
   col_widths = "";
   int numButtons=_TreeGetNumColButtons();
   int width,flags,state;
   _str caption;
   for (i:=0;i<numButtons;++i) {
      _TreeGetColButtonInfo(i,width,flags,state,caption);
      col_widths :+= " ":+width;
   }
}

static void setColWidths(_str col_widths)
{
   for (i:=0;;++i) {
      parse col_widths with auto new_width col_widths;
      if ( new_width=="" ) break;
      _TreeGetColButtonInfo(i,auto cur_width,auto cur_flags,auto cur_state,auto cur_caption);
      _TreeSetColButtonInfo(i,(int)new_width,cur_flags,cur_state,cur_caption);
   }
}


static void sizeColumns(int treeWID)
{
   if ( !(def_filelist_flags&FILELIST_RESTORE_COLUMN_WIDTHS) ){
      treeWID._TreeSizeColumnToContents(-1);
   }
}

static void showDocumentTabs()
{
   if (p_active_form._find_control("ctl_sstab") > 0) {
      showOpenFiles();
      return;
   }
   if ( ctl_file_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX) < 0 ) {
      ctl_file_list.FileListUpdateDocumentTabs();
      //if (ctl_file_list._TreeGetNumChildren(TREE_ROOT_INDEX) <= 1) {
      //   ctl_file_list.FileListUpdateOpenFiles();
      //}
   }
}

static void showOpenFiles()
{
   if (p_active_form._find_control("ctl_sstab") > 0) {
      if ( ctl_sstab.p_ActiveTab != FILELIST_SHOW_OPEN_FILES ) {
         ctl_sstab.p_ActiveTab = FILELIST_SHOW_OPEN_FILES;
      }
      _SetDialogInfoHt(FILELIST_SHOW,FILELIST_SHOW_OPEN_FILES,ctl_file_list);
      gfilelist_show=FILELIST_SHOW_OPEN_FILES;
   }
   _str old_text=null;
   if (!(def_filelist_flags&FILELIST_MULTIPLE_FILTERS)) {
      old_text=_GetDialogInfoHt(FILELIST_FILTER_TEXT,_control ctl_file_list);
   }
   if (old_text!=null) {
      changed:=ctl_filter.p_text:!=old_text;
      ctl_filter.p_text=old_text;
      if ( old_text!="" ) {
         ctl_filter._set_sel(1,length(old_text)+1);
      }
      if (changed) {
         wid := ctl_filter.nextTreeControlWid();
         if ( wid ) {
            wid.FileListFilterFiles(old_text);
            sizeColumns(wid);
            wid._TreeRefresh();
         }
      }
   } else {
      ctl_filter.forceFilterList(true);
   }
}

static void showProjectFiles()
{
   if (p_active_form._find_control("ctl_sstab") > 0) {
      if ( ctl_sstab.p_ActiveTab != FILELIST_SHOW_PROJECT_FILES ) {
         ctl_sstab.p_ActiveTab = FILELIST_SHOW_PROJECT_FILES;
      }
      _SetDialogInfoHt(FILELIST_SHOW,FILELIST_SHOW_PROJECT_FILES,ctl_file_list);
      gfilelist_show=FILELIST_SHOW_PROJECT_FILES;
   }
   _str old_text=null;
   if (!(def_filelist_flags&FILELIST_MULTIPLE_FILTERS)) {
      old_text=_GetDialogInfoHt(FILELIST_PRJ_FILTER_TEXT,_control ctl_file_list);
   }
   if (old_text!=null) {
      changed:=ctl_proj_filter.p_text:!=old_text;
      ctl_proj_filter.p_text=old_text;
      if ( old_text!="" ) {
         ctl_proj_filter._set_sel(1,length(old_text)+1);
      }
      if (changed) {
         wid := ctl_proj_filter.nextTreeControlWid();
         if ( wid ) {
            wid.FileListFilterFiles(old_text);
            sizeColumns(wid);
            wid._TreeRefresh();
         }
      }
   } else {
      ctl_proj_filter.forceFilterList(true);
   }
}

static void showWorkspaceFiles()
{
   if (p_active_form._find_control("ctl_sstab") > 0) {
      if ( ctl_sstab.p_ActiveTab != FILELIST_SHOW_WORKSPACE_FILES ) {
         ctl_sstab.p_ActiveTab = FILELIST_SHOW_WORKSPACE_FILES;
      }
      _SetDialogInfoHt(FILELIST_SHOW,FILELIST_SHOW_WORKSPACE_FILES,ctl_file_list);
      gfilelist_show=FILELIST_SHOW_WORKSPACE_FILES;
   }
   _str old_text=null;
   if (!(def_filelist_flags&FILELIST_MULTIPLE_FILTERS)) {
      old_text=_GetDialogInfoHt(FILELIST_WKSP_FILTER_TEXT,_control ctl_file_list);
   }
   if (old_text!=null) {
      changed:=ctl_wksp_filter.p_text:!=old_text;
      ctl_wksp_filter.p_text=old_text;
      if ( old_text!="" ) {
         ctl_wksp_filter._set_sel(1,length(old_text)+1);
      }
      if (changed) {
         wid := ctl_wksp_filter.nextTreeControlWid();
         if ( wid ) {
            wid.FileListFilterFiles(old_text);
            sizeColumns(wid);
            wid._TreeRefresh();
         }
      }
   } else {
      ctl_wksp_filter.forceFilterList(true);
   }
}

#if 0
static _str get_text_reason(int reason)
{
   switch ( reason ) {
   case CHANGE_SELECTED:
      return "CHANGE_SELECTED";
   case CHANGE_PATH:
      return "CHANGE_PATH";
   case CHANGE_FILENAME:
      return "CHANGE_FILENAME";
   case CHANGE_DRIVE:
      return "CHANGE_DRIVE";
   case CHANGE_EXPANDED:
      return "CHANGE_EXPANDED";
   case CHANGE_COLLAPSED:
      return "CHANGE_COLLAPSED";
   case CHANGE_LEAF_ENTER:
      return "CHANGE_LEAF_ENTER";
   case CHANGE_SCROLL:
      return "CHANGE_SCROLL";
   case CHANGE_EDIT_OPEN:
      return "CHANGE_EDIT_OPEN";
   case CHANGE_EDIT_CLOSE:
      return "CHANGE_EDIT_CLOSE";
   case CHANGE_EDIT_QUERY:
      return "CHANGE_EDIT_QUERY";
   case CHANGE_EDIT_OPEN_COMPLETE:
      return "CHANGE_EDIT_OPEN_COMPLETE";
   }
   return "UNKOWN EVENT "reason;
}
#endif

/**
 * Called to handle tree events, expand, collapse, change selected.
 * 
 * @param reason  event code
 * @param index   tree node affected
 */
void ctl_file_list.on_change(int reason,int index)
{
   if (reason==CHANGE_SCROLL) return;

   status := 0;

   if (reason==CHANGE_SELECTED) {

      // kill the existing timer
      int timer_id = _GetDialogInfoHt(FILELIST_TIMER_ID,ctl_file_list);
      if ( timer_id != null && _timer_is_valid(timer_id) ) {
         _kill_timer(timer_id);
      }
      _SetDialogInfoHt(FILELIST_TIMER_ID,-1,ctl_file_list);

      // don't create a new timer unless there is something to update
      if (_GetTagwinWID()) {
         focus_wid  := _get_focus();
         filter_wid := FileListGetCurrentFilterWid();
         if ( focus_wid == p_window_id || focus_wid == filter_wid ) {
            int timer_delay=max(200,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
            timer_id = _set_timer(timer_delay,FileListFocusTimerCallback,p_active_form' 'p_window_id);
            _SetDialogInfoHt(FILELIST_TIMER_ID,timer_id,ctl_file_list);
         }

      }
   } else if (reason==CHANGE_COLLAPSED) {
      save_buffer_from_tree_index(index);  
   } else if ( reason==CHANGE_LEAF_ENTER ) {
      open_selected_files();
   }
}


//////////////////////////////////////////////////////////////////////////////
// Toolbar button handlers
//

/**
 * Open the selected files, current object must be the tree control
 */
static void open_selected_file_in_current_window()
{
   int info;
   index := _TreeGetNextSelectedIndex(1,info);
   if ( index <= 0 ) return; 
   FileListEditFile(index,"-w");
}
static void open_selected_files()
{
   cur_tree_wid := p_window_id;
   ff := 1;
   info := 0;
   status := 0;

   // Save the edit commands in an array and run them later.  If the toolwindow 
   // is not dockable it will cause a problem if we do this before closing 
   // the window
   STRARRAY editCommands;

   // Set up edit options to attempt to open the window in the current
   // document tab group rather than moving focus to another window.
   edit_options := "";
   if (def_one_file != "" && p_active_form._find_control("ctl_sstab") <= 0) {
      edit_options = "+wg":+def_document_tab_list_buffers_open_where;
   }

   for (;;ff=0) {
      index := cur_tree_wid._TreeGetNextSelectedIndex(ff,info);
      if (ff && index <= 0) {
         gui_open();
         return;
      }
      if (index <= 0) break;
      status = cur_tree_wid.FileListEditFile(index,edit_options,&editCommands);
   }
   _TreeDeselectAll();
   if ( def_filelist_flags&FILELIST_DISMISS_ON_SELECTION && !status ) {
      tw_dismiss(p_active_form, true);
   }
   len := editCommands._length();
   for ( i:=0;i<len;++i ) {
      edit(editCommands[i]);
   }
}

static void add_selected_files_to_project()
{
   cur_tree_wid := p_window_id;
   ff := 1;
   files := "";
   int info;
   for (;;ff=0) {
      index := cur_tree_wid._TreeGetNextSelectedIndex(ff,info);
      if (index <= 0) break;

      curFilename := _TreeGetCaption(index);
      parse curFilename with curFilename "\t" auto curFilepath;
      curFilename=strip_buffer_id(curFilename);
      curFilepath = getAbsoluteFilePathInFileList(curFilepath);
      files :+= _maybe_quote_filename(curFilepath:+curFilename) :+ ' ';
   }

   project_add_files_prompt_project(files);
}

/**
 * Diff the selected files
 */
void ctl_diff_button.lbutton_up()
{
   ctl_file_list.diff_all_selected_buffers();
}

static void diff_all_selected_buffers()
{
   if (!_haveDiff()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Diff");
      return;
   }
   ff := 1;
   int info;
   prevIndex := TREE_ROOT_INDEX;
   gotOne := false;
   for (;;ff=0) {
      index := _TreeGetNextSelectedIndex(ff,info);
      if ( index <= 0 ) {
         if (ff) {
            index = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
            prevIndex = index;
         } else if (prevIndex) {
            index = _TreeGetNextSiblingIndex(prevIndex);
            prevIndex = index;
         }
      }
      if (index <= 0) break;
      bufid := _TreeGetUserInfo(index);
      if (!isnumber(bufid)) continue;
      orig_view_id := p_window_id;
      p_window_id=VSWID_HIDDEN;
      _safe_hidden_window();
      int status=load_files('+bi 'bufid);
      if (status) {
         continue;
      }
      if ( p_modify ) {
         gotOne = true;
         _DiffModal("-bi1 -d2 -r2 "bufid" "_maybe_quote_filename(p_buf_name));
      }
      p_window_id=orig_view_id;
   }
   _UpdateFileListModifiedFiles(true);
   if ( !gotOne ) {
      _message_box(nls("Files are not modified.\n\nThis feature compares files in memory with files on disk."));
   }
}

/**
 * Save the selected files
 */
void ctl_save_button.lbutton_up()
{
   ctl_file_list.save_all_selected_buffers();
}

static void save_all_selected_buffers()
{
   ff := 1;
   int info;
   for (;;ff=0) {
      index := _TreeGetNextSelectedIndex(ff,info);
      if (ff && index <= 0) {
         save_all();
         return;
      }
      if (index <= 0) break;
      bufid := _TreeGetUserInfo(index);
      if (!isnumber(bufid)) continue;
      orig_view_id := p_window_id;
      p_window_id=VSWID_HIDDEN;
      _safe_hidden_window();
      int status=load_files('+bi 'bufid);
      if (status) {
         continue;
      }
      save();                                                               
      p_window_id=orig_view_id;
   }
   _UpdateFileListModifiedFiles(true);
}

static void save_buffer_from_tree_index(int index)
{
   if (index <= 0) return;
   bufid := _TreeGetUserInfo(index);
   if (!isnumber(bufid)) return;
   orig_view_id := p_window_id;
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   int status=load_files('+bi 'bufid);
   if (status) {
      p_window_id=orig_view_id;
      return;
   }
   save();                                                               
   p_window_id=orig_view_id;
   _UpdateFileListModifiedFiles(true);
}

static void save_current_item()
{
   index := _TreeCurIndex();
   if ( index>-1 ) {
      save_buffer_from_tree_index(index);
   }
}

static void close_current_item()
{
   index := _TreeCurIndex();
   if ( index>TREE_ROOT_INDEX ) {
      close_buffer_from_tree_index(index);
   }
}

static void close_buffer_from_tree_index(int index)
{
   bufid := ctl_file_list._TreeGetUserInfo(index);
   if ( bufid!=null ) {
      orig_view_id := p_window_id;
      int status=edit('+bi 'bufid);
      _mdi.p_child.quit();
      p_window_id=orig_view_id;
      _set_focus();
   }
}

/**
 * Handle the close file button, closes selected buffers
 */
void ctl_close_button.lbutton_up()
{
   mou_hour_glass(true);

   // get a list of the selected items
   int buffers_to_close[];
   buffers_to_close._makeempty();
   bufid := 0;

   int info;
   for (ff:=1;;ff=0) {
      index := ctl_file_list._TreeGetNextSelectedIndex(ff,info);
      if (index <= 0 && ff) index = ctl_file_list._TreeCurIndex();
      if (index <= 0) break;
      bufid = ctl_file_list._TreeGetUserInfo(index);
      if (!isnumber(bufid)) continue;
      buffers_to_close[buffers_to_close._length()] = bufid;
   }

   int (*pbuffer_id_hash):[] = ctl_file_list.GetPointerToFileListHashTab();
   if ( pbuffer_id_hash == null ) return;

   _SetDialogInfoHt(FILELIST_IGNORE_CBQUIT,"1",ctl_file_list);
   wid := p_window_id;
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   int old_def_actapp = def_actapp;
   def_actapp &= ~ACTAPP_AUTORELOADON;
   for (i:=0; i<buffers_to_close._length(); ++i) {
      bufid = buffers_to_close[i];
      if ( bufid!=null ) {
         status := load_files("+bi "bufid);
         if ( !status ) {
         
            bufId := p_buf_id;
            filename := FileListGetDocumentName();
            treeIndex := -1;
         
            message("Closing ":+p_buf_name);
            status = FileListQuitFile(filename);

            // user may have cancelled if file was modified
            if ( status==COMMAND_CANCELLED_RC ) {
               break;
            }

            // remove it from the hash table
            if ( (*pbuffer_id_hash)._indexin(filename) ) {
               treeIndex = (*pbuffer_id_hash):[filename];
               (*pbuffer_id_hash)._deleteel(filename);
            }else if ( (*pbuffer_id_hash)._indexin(bufId) ) {
               treeIndex = (*pbuffer_id_hash):[bufId];
               (*pbuffer_id_hash)._deleteel(bufId);
            }

            // remove it from the tree
            if ( treeIndex>-1 ) {
               wid.ctl_file_list._TreeDelete(treeIndex);
            }
         }
      }
   }
   def_actapp = old_def_actapp;
   wid.ctl_file_list.maybeSelectOneLine();

   p_window_id=wid;
   _SetDialogInfoHt(FILELIST_IGNORE_CBQUIT,"0",ctl_file_list);
   mou_hour_glass(false);
   clear_message();
}

static int FileListQuitFile(_str bufName)
{
   //if ( substr(name,1,1)=='.' ) {
   //   p_window_id=orig_wid;_set_focus();
   //   _message_box(nls("Can't close buffer starting with '.'"));
   //   return("");
   //}
   if ( index_callable(find_index("delphiIsRunning",PROC_TYPE)) ) {
      if ( delphiIsRunning() && delphiIsBufInDelphi(bufName) ) {
         return delphiCloseBuffer( bufName );
      }
   }
   return _save_non_active(bufName,true,SV_RETURNSTATUS,def_display_buffer_id);
}

//////////////////////////////////////////////////////////////////////////////
// File name filter handlers
//

/**
 * Catch Ctrl+C and Ctrl+Ins and copy the current filename to
 * the clipboard
 */
void ctl_filter."C-C","C-ins"()
{
   if ( p_text=="" ) {
      ctl_file_list.call_event(ctl_file_list,C_C);
   }else{
      eventtabindex := find_index("_ul2_textbox",EVENTTAB_TYPE);
      if ( eventtabindex ) {
         ctl_filter.call_event(eventtabindex,C_C,'E');
      }
   }
}

void ctl_filter."C-S","A-S","M-S","A-W"()
{
   if ( p_name == "ctl_filter" ) {
      ctl_file_list.save_current_item();
   }
}

void ctl_filter."A-E","M-E"()
{
   treewid := nextTreeControlWid();
   treewid.open_selected_files();
}

void ctl_filter."A-C","M-C","A-D","M-D"()
{
   if (last_event():==name2event("M-C") && !_default_option(VSOPTION_MAC_USE_COMMAND_KEY_FOR_DIALOG_HOT_KEYS)) {
      copy_to_clipboard();
      return;
   }
   if ( p_name == "ctl_filter" ) {

      // we only do this for the file list, so make sure 
      // we are looking at the right thing
      treewid := nextTreeControlWid();
      if (treewid.p_name == 'ctl_file_list') {
         if (ctl_file_list._TreeGetNumSelectedItems() > 1) {
            call_event(_control ctl_close_button,LBUTTON_UP);
         } else {
            ctl_file_list.close_current_item();
         }
         ctl_file_list.maybeSelectOneLine();
      }
   }
}

/**
 * Shortcuts for switching between Files tool window modes
 */
void ctl_filter."A-B"()
{
   if (p_active_form._find_control("ctl_sstab") <= 0) return;
   p_active_form.showOpenFiles();
}
void ctl_filter."A-P"()
{
   if (p_active_form._find_control("ctl_sstab") <= 0) return;
   p_active_form.showProjectFiles();
}
void ctl_filter."A-W"()
{
   if (p_active_form._find_control("ctl_sstab") <= 0) return;
   p_active_form.showWorkspaceFiles();
}
void ctl_file_list."A-B"()
{
   if (p_active_form._find_control("ctl_sstab") <= 0) return;
   p_active_form.showOpenFiles();
}
void ctl_file_list."A-P"()
{
   if (p_active_form._find_control("ctl_sstab") <= 0) return;
   p_active_form.showProjectFiles();
}
void ctl_file_list."A-W"()
{
   if (p_active_form._find_control("ctl_sstab") <= 0) return;
   p_active_form.showWorkspaceFiles();
}

void ctl_filter."C-="()
{
   if (p_active_form._find_control("ctl_sstab") <= 0) return;
   ctl_file_list.diff_all_selected_buffers();
}
void ctl_file_list."C-="()
{
   if (p_active_form._find_control("ctl_sstab") <= 0) return;
   ctl_file_list.diff_all_selected_buffers();
}

static _str _get_filter_group()
{
   if (!_find_control("ctl_sstab")) {
      return FILELIST_FILTER_TEXT;
   }
   tabNumber := p_active_form.ctl_sstab.p_ActiveTab;
   switch ( tabNumber ) {
   case FILELIST_SHOW_DOCUMENT_TABS:
   case FILELIST_SHOW_OPEN_FILES:
      return FILELIST_FILTER_TEXT;
   case FILELIST_SHOW_PROJECT_FILES:
      return FILELIST_PRJ_FILTER_TEXT;
   case FILELIST_SHOW_WORKSPACE_FILES:
      return FILELIST_WKSP_FILTER_TEXT;
   }
   return FILELIST_FILTER_TEXT;
}

/**
 * Refilter files when the filter changes
 */
void ctl_filter.on_change(int reason=CHANGE_OTHER)
{
   formwid := p_active_form;
   if ( formwid ) {
      filter_text := _get_filter_group();
      _str oldtext=_GetDialogInfoHt(filter_text,formwid.ctl_file_list);
      if (oldtext==null || oldtext:!= p_text) {
         wid := nextTreeControlWid();
         if ( wid ) {
            wid.FileListFilterFiles(p_text);
            _SetDialogInfoHt(filter_text,p_text,formwid.ctl_file_list);
            sizeColumns(wid);
            wid._TreeRefresh();
         }
      }
   }
}

void ctl_filter.ESC()
{
   ctl_file_list.call_event(ctl_file_list,ESC);
}

/**
 * Move the current line up or down in the tree.  Up is the
 * default
 * @param direction 'u' for up, 'd' for down
 */
static void filterUpDown(_str direction='u')
{
   goingup := lowcase(direction)=='u';
   treewid := nextTreeControlWid();
   if ( treewid ) {
      wid := p_window_id;
      p_window_id=treewid;
      curindex := _TreeCurIndex();
      if ( curindex>-1 ) {
         newindex := -1;
         if ( goingup ) {
            newindex = _TreeGetPrevIndex(curindex);
         }else{
            newindex = _TreeGetNextIndex(curindex);
         }
         // Removing this because it causes bottom to top wrapping
         //if ( newindex<0 ) {
         //   newindex=_TreeGetIndexFromLineNumber(_TreeScroll());
         //}
         if ( newindex>-1 ) {
            _TreeDeselectAll();
            _TreeSetCurIndex(newindex);
            _TreeSelectLine(newindex);
         }
      }
      p_window_id=wid;
   }
}

static int nextTreeControlWid()
{
   wid := p_next;
   while ( wid != p_window_id ) {
      if (wid.p_object == OI_TREE_VIEW ) return wid;
      wid = wid.p_next;
   }
   return 0;
}

void ctl_filter.pgup,"s-up"()
{
   curTreeWID := nextTreeControlWid();
   curTreeWID.call_event(curTreeWID,S_UP);
}
void ctl_filter.pgup,"s-down"()
{
   curTreeWID := nextTreeControlWid();
   curTreeWID.call_event(curTreeWID,S_DOWN);
}
/**
 * Move up in the file tree.  Catch the cursor up key, and the
 * Ctrl+I
 */
void ctl_filter.up/*,"c-i"*/()
{
   filterUpDown('u');
}

/**
 * Move down in the file tree.  Catch the cursor down key, and
 * the Ctrl+K
 */
void ctl_filter.down/*,"c-k"*/()
{
   filterUpDown('d');
}

void ctl_filter.pgup/*,"c-p"*/()
{
   curTreeWID := nextTreeControlWid();
   curTreeWID.call_event(curTreeWID,PGUP);
}

void ctl_filter.pgdn/*,"c-n"*/()
{
   curTreeWID := nextTreeControlWid();
   curTreeWID.call_event(curTreeWID,PGDN);
}

void ctl_filter.c_home/*,"c-u"*/()
{
   if (last_event():==HOME) {
      get_command(auto text,auto start_sel,auto end_sel);
      if (text:!="" || start_sel>1 || end_sel>1) {
         _set_sel(1);
         return;
      }
   }
   curTreeWID := nextTreeControlWid();
   curTreeWID.call_event(curTreeWID,HOME);
}
void ctl_file_list.c_home() {
   p_window_id.call_event(p_window_id,HOME);
}

void ctl_filter.c_end/*,"c-o"*/()
{
   if (last_event():==END) {
      get_command(auto text,auto start_sel,auto end_sel);
      if (text:!="" || start_sel>1 || end_sel>1) {
         _set_sel(length(text)+1);
         return;
      }
   }
   curTreeWID := nextTreeControlWid();
   curTreeWID.call_event(curTreeWID,END);
}
void ctl_file_list.c_end() {
   p_window_id.call_event(p_window_id,END);
}
void ctl_filter.c_down,'c-s-down'()
{
   curTreeWID := nextTreeControlWid();
   curTreeWID.call_event(curTreeWID,S_DOWN);
}
void ctl_file_list.'c-s-down'() {
   p_window_id.call_event(p_window_id,S_DOWN);
}
void ctl_filter.c_up,'c-s-up'()
{
   curTreeWID := nextTreeControlWid();
   curTreeWID.call_event(curTreeWID,S_UP);
}

void ctl_file_list.c_up,'c-s-up'() {
   p_window_id.call_event(p_window_id,S_UP);
}
void ctl_filter.c_down,'c-s-home'()
{
   curTreeWID := nextTreeControlWid();
   curTreeWID.call_event(curTreeWID,S_HOME);
}
void ctl_file_list.c_down,'c-s-home'() {
   p_window_id.call_event(p_window_id,S_HOME);
}

void ctl_filter.'c-s-end'()
{
   curTreeWID := nextTreeControlWid();
   curTreeWID.call_event(curTreeWID,S_END);
}

void ctl_file_list.'c-s-end'() {
   p_window_id.call_event(p_window_id,S_END);
}

void ctl_filter.a_a,'c-s-a'()
{
   curTreeWID := nextTreeControlWid();
   curTreeWID.call_event(curTreeWID,C_A);
}
void ctl_file_list.a_a,'c-s-a'() {
   p_window_id.call_event(p_window_id,C_A);
}

/*  
    Try to use some keys based on users emulation.

    Note: Unfortunately, this code breaks Ctrl+A for the text box.
*/
void ctl_filter.c_a-c_z()
{
   switch (name_on_key(last_event())) {
   case 'select-all':
      {
         int curTreeWID;
         curTreeWID = nextTreeControlWid();
         curTreeWID.call_event(curTreeWID,C_A);
      }
      return;
   case 'cursor-up':
      call_event(p_window_id,UP,'W');
      return;
   case 'cursor-down':
      call_event(p_window_id,DOWN,'W');
      return;
   case 'page-up':
      call_event(p_window_id,PGUP,'W');
      return;
   case 'page-down':
      call_event(p_window_id,PGDN,'W');
      return;
   case 'top-of-buffer':
      call_event(p_window_id,HOME,'W');
      return;
   case 'bottom-of-buffer':
      call_event(p_window_id,END,'W');
      return;
   case 'linewrap-delete-char':
   case 'delete-char':
      call_event(p_window_id,DEL,'W');
      return;
   }
   if (def_cua_textbox) {
      call_event(defeventtab  _ul2_textbox2,last_event(),'E');
   } else {
      call_event(defeventtab  _ul2_textbox,last_event(),'E');
   }
}


/**
 * Put focus in the tree if they hit enter in the filter combo.
 */
void ctl_filter.ENTER()
{
   origWID := p_window_id;
   curTreeWID := nextTreeControlWid();
   nofselected := curTreeWID._TreeGetNumSelectedItems();

   if ( 0==nofselected && p_text!="" ) {
      // If there is text in the textbox, and nothing is selected
      filename := absolute(p_text);
      _mdi.edit(_maybe_quote_filename(filename),EDIT_DEFAULT_FLAGS);
      origWID.p_text="";
      if ( def_filelist_flags&FILELIST_DISMISS_ON_SELECTION ) {
         tw_dismiss(p_active_form);
      }
      return;
   }

   curTreeWID.open_selected_files();
   if (!(def_filelist_flags&FILELIST_DISMISS_ON_SELECTION)) {
      origWID.p_text="";origWID._begin_line();
   }
}

/** 
 * When the filter text box gets focus, be sure at least one
 * line in the tree is selected. (suggested by HS2 of SlickEdit
 * Community fame)
 * 
 */
void ctl_filter.on_got_focus()
{
   curTreeWID := nextTreeControlWid();
   curTreeWID.maybeSelectOneLine();

   p_sel_start  = 1;
   p_sel_length = p_text._length();
}

//////////////////////////////////////////////////////////////////////////////
// Support functions
//

/**
 * @return Return the window ID of the file list tool window.
 */
static int tbGetActiveFilesForm()
{
   if ( p_active_form.p_name == TBFILES_FORM ) {
      return p_active_form;
   } else if ( p_active_form.p_name == DOCUMENT_TAB_FORM ) {
      return p_active_form;
   }
   return tw_find_form(TBFILES_FORM);
}

// Current object should be file list form
//
static int FileListGetCurrentFilterWid(int tabNumber=-1)
{
   if ( tabNumber < 0 ) {
      if (p_active_form._find_control("ctl_sstab") > 0) {
         tabNumber = p_active_form.ctl_sstab.p_ActiveTab;
      } else if (p_active_form._find_control("ctl_filter") > 0) {
         return p_active_form.ctl_filter.p_window_id;
      } else {
         return 0;
      }
   }
   switch ( tabNumber ) {
   case FILELIST_SHOW_DOCUMENT_TABS:
   case FILELIST_SHOW_OPEN_FILES:
      return p_active_form.ctl_filter.p_window_id;
   case FILELIST_SHOW_PROJECT_FILES:
      return p_active_form.ctl_proj_filter.p_window_id;
   case FILELIST_SHOW_WORKSPACE_FILES:
      return p_active_form.ctl_wksp_filter.p_window_id;
   }
   return 0;
}

static int FileListGetCurrentTreeWid(int tabNumber=-1)
{
   if ( tabNumber < 0 ) {
      if (p_active_form._find_control("ctl_sstab") > 0) {
         tabNumber = p_active_form.ctl_sstab.p_ActiveTab;
      } else if (p_active_form._find_control("ctl_file_list") > 0) {
         return p_active_form.ctl_file_list.p_window_id;
      } else {
         return 0;
      }
   }
   switch ( tabNumber ) {
   case FILELIST_SHOW_DOCUMENT_TABS:
   case FILELIST_SHOW_OPEN_FILES:
      return p_active_form.ctl_file_list.p_window_id;
   case FILELIST_SHOW_PROJECT_FILES:
      return p_active_form.ctl_project_list.p_window_id;
   case FILELIST_SHOW_WORKSPACE_FILES:
      return p_active_form.ctl_workspace_list.p_window_id;
   }
   return 0;
}

// Current object should be file list form
//
static int FileListGetEditorCtlWid()
{
   tree_wid := FileListGetCurrentTreeWid(-1);
   if (tree_wid <= 0) return tree_wid;
   editorctl_wid:=tree_wid._MDIGetActiveMDIChild();
   //editorctl_wid := _GetDialogInfoHt(FILELIST_CURRENT_EDITOR_WID,tree_wid);
   if ( editorctl_wid != null && _iswindow_valid(editorctl_wid) && editorctl_wid._isEditorCtl()) {
      return editorctl_wid;
   }
   if (_no_child_windows()) return 0;
   return _mdi.p_child;
}

/**
 * @return Return the window ID of the tree control on 
 *         the file list tool window.
 */
static int FileListGetFileTreeWid()
{
   return ctl_file_list;
}

static void FileListUpdatePreview(_str path,int LineNumber)
{

   // find the output tagwin and update it
   tag_init_tag_browse_info(auto cm, path, "", SE_TAG_TYPE_FILE, SE_TAG_FLAG_NULL, path, LineNumber);
   cb_refresh_output_tab(cm, true, true, false, APF_FILES);
}

static void SetFileListHashTab(int (&newValue):[])
{
   _SetDialogInfoHt(FILELIST_HASH_TAB,newValue,p_window_id);
}

static typeless *GetPointerToFileListHashTab()
{
   return _GetDialogInfoHtPtr(FILELIST_HASH_TAB,p_window_id);
}

/**
 * Find the specified node in the Files tree.
 * The current object must be the Files tree.
 * 
 * @param bufid_or_key  buffer id or search key
 * @return tree index of item on success, <0 if not found
 */
static int FileListFindNode(_str bufid_or_key)
{
   int (*pBufIdHash):[] = GetPointerToFileListHashTab();
   if ( pBufIdHash == null ) {
      return -1;
   }
   if (!(*pBufIdHash)._indexin(bufid_or_key)) {
      return -1;
   }

   return (*pBufIdHash):[bufid_or_key];
}

static _str strip_buffer_id(_str filename,int &buf_id=0) {
   if (substr(filename,1,9)=='Untitled<') {
      return filename;
   }
   _str sbuf_id;
   parse filename with filename '<' sbuf_id '>';
   if (!isinteger(sbuf_id)) {
      buf_id= -1;
   } else {
      buf_id=(int)sbuf_id;
   }
   return filename;
}

/**
 * @return Return the display name for this buffer.
 *         The current object must be an editor control.
 */
static _str FileListGetDocumentName()
{
   if (p_DocumentName != "") {
      if (def_display_buffer_id) {
         return p_DocumentName"<"p_buf_id">";
      }
      return p_DocumentName;
   }
   if (p_buf_name != "") {
      if (def_display_buffer_id) {
         return p_buf_name"<"p_buf_id">";
      }
      return p_buf_name;
   }
   return "Untitled<"p_buf_id">";
}

static void storeInHashtab(typeless *pHashtab,int buf_id,int index=-1,_str file="")
{
   if ( pHashtab!=null ) {
      if (buf_id > 0) {
         (*pHashtab):[buf_id] = index;
         //say('FileListAddFile adding 'buf_id'='index);
      } else {
         (*pHashtab):[file] = index;
         //say('FileListAddFile adding 'file'='index);
      }
   }
}

/**
 * Add the current file to the file list.
 * This function is like {@link FileListAddFile},
 * except that it is specifically for open files.
 * The current object is expected to be the 
 * editor control.
 * 
 * @param tree_wid      File list tree control to insert into
 * @param isCurrent     Is this the current open buffer?
 * 
 * @return <0 on error, index of tree node otherwise
 */
static int FileListAddBuffer(int tree_wid, bool isCurrent)
{
   // Do not insert hidden files
   if (p_buf_flags & VSBUFFLAG_HIDDEN) {
      return -1;
   }

   // get the buffer ID and display buffer name 
   buf_id   := p_buf_id;
   buf_name := FileListGetDocumentName();
   if (buf_name=="") return(-1);
   if (_file_eq(_strip_filename(buf_name,'P'),_WINDOW_CONFIG_FILE)) {
      return -1;
   }

   // get just the file name, no path, no quotes
   filename := _strip_filename(buf_name,'P');
   filename=strip(filename,'B','"');

   // check if the file is modified
   flags := 0;
   star := "";
   if (tbfilelist_is_modified()) {
      flags = TREENODE_FORCECOLOR|TREENODE_ITALIC;
      star='*';
   }

   // is this the current buffer?
   if (isCurrent) {
      flags |= TREENODE_BOLD;
   }

   // set the hidden flag if this file should be hidden
   if (tree_wid.p_active_form.ctl_filter.p_text != "" && 
      pos(tree_wid.p_active_form.ctl_filter.p_text, buf_name, 1, '&') <= 0) {
      flags |= TREENODE_HIDDEN;
   }

   // should this file use a special bitmap?
   Taggable := _istagging_supported();
   pic_file := getBitmapForCurrentBuffer(auto pic_overlay);

   // check if the buffer is already in the list
   index := tree_wid.FileListFindNode(buf_id);
   if (index > -1) {
      // check if the file type or modify state has changed

      tree_wid._TreeGetInfo(index,auto orig_state,auto bmindex,auto bmindex2,auto orig_flags);
      if (bmindex2 != pic_file || flags != orig_flags) {
         tree_wid._TreeSetInfo(index,orig_state,pic_file,pic_file,flags);
      }
      // put together the new caption and check if it has changed
      path := _strip_filename(buf_name, 'N');
      caption := filename:+star"\t"path:+star;
      if (caption != tree_wid._TreeGetCaption(index)) {
         tree_wid._TreeSetCaption(index, caption);
      }
   } else {
      // not in the list, so add it
      parent_index := TREE_ROOT_INDEX;
      index = tree_wid._FileListAddFile(parent_index,
                                        buf_name,
                                        tree_wid.p_parent.ctl_filter.p_text,
                                        buf_id,
                                        pic_file,
                                        flags);
      // add the file modified overlay if necessary
      if ( index > 0 && pic_overlay > 0 ) {
         int overlayList[];
         overlayList[0] = pic_overlay;
         tree_wid._TreeSetOverlayBitmaps(index, overlayList);
      }
      // add the file to the quick-lookup hash table
      if ( index > 0) {
         pHashtab := tree_wid.GetPointerToFileListHashTab();
         if ( pHashtab == null ) {
            int newHashtab:[];
            storeInHashtab(&newHashtab,buf_id,index,buf_name);
            tree_wid.SetFileListHashTab(newHashtab);
         } else {
            storeInHashtab(pHashtab,buf_id,index,buf_name);
         }
      }
      if ( isCurrent ) {
         tree_wid._TreeSetCurIndex(index);
      }
   }
   // return the tree index of the file
   return(index);
}

/**
 * Is NOT a general is modified funciton, excludes '.' buffers,
 * and buffers w/ THROW_AWAY_CHANGES 
 *  
 * p_window_id and p_buf_id must already be set 
 */
static bool tbfilelist_is_modified()
{
   modified := false;
   if ( p_modify ) {
      modified = _need_to_save();
   }
   return modified!=0;
}

/**
 * Update the list of open files in the editor.
 * The current object should be the tree control. 
 */
static void FileListUpdateOpenFiles()
{
   // save the window ID for the File list tree
   tree_wid := p_window_id;

   tree_wid._TreeDelete(TREE_ROOT_INDEX,'C');

   int (*pbuffer_id_hash):[] = tree_wid.GetPointerToFileListHashTab();
   if ( pbuffer_id_hash!=null ) {
      *pbuffer_id_hash=null;
   }

   // keep track of the current buffer ID
   editorctl_wid := p_active_form.FileListGetEditorCtlWid();
   cur_buf_id := editorctl_wid? editorctl_wid.p_buf_id : _mdi.p_child.p_buf_id;

   // switch to the hidden window
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   status := load_files('+q +bi 'cur_buf_id);

   // cycle through the open buffers and add them 
   index := 0;
   for (;;) {
      _next_buffer('HR');
      index = FileListAddBuffer(tree_wid, cur_buf_id==p_buf_id);
      if (p_buf_id==cur_buf_id) break;
   }

   if ( def_filelist_flags&FILELIST_RESTORE_COLUMN_WIDTHS ) {
//      tree_wid._TreeRetrieveColButtonInfo(true);
   }
   // restore back to the tree control
   p_window_id=tree_wid;
}


/**
 * Update the list of open files in the editor.
 * The current object should be the tree control. 
 */
static void FileListUpdateDocumentTabs()
{
   // tab groups not supported?
   if ( !(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) ) {
      return;
   }

   // save the window ID for the File list tree
   tree_wid := p_window_id;
   tree_wid._TreeDelete(TREE_ROOT_INDEX,'C');

   // get pointer to file list hash table
   int (*pbuffer_id_hash):[] = tree_wid.GetPointerToFileListHashTab();
   if ( pbuffer_id_hash!=null ) {
      *pbuffer_id_hash=null;
   }

   // keep track of the current buffer ID
   editorctl_wid := p_active_form.FileListGetEditorCtlWid();
   if ( editorctl_wid == 0 ) return;
   cur_buf_id := editorctl_wid.p_buf_id;

   // Find the first tab
   wid := editorctl_wid;
   for (;;) {
      wid = _MDINextDocumentWindow(wid,def_document_tab_list_option,false);
      if (!wid) break;
      wid.FileListAddBuffer(tree_wid, cur_buf_id==wid.p_buf_id);
      if (!wid || wid==editorctl_wid) {
         break;
      }
   }

   // restore back to the tree control
   p_window_id=tree_wid;
}


static int getFileListManagerHandle(){
   return FileListManager_GetHandle(TBFILES_FORM:+p_active_form);
}

/**
 * Update the list of files in the current workspace.
 * The current object should be the tree control.
 * 
 */
static void FileListUpdateWorkspace(int viewsToShow=OTBFO_WORKSPACE_FILE|OTBFO_PROJECT_FILE)
{
   filter_wid := FileListGetCurrentFilterWid();
   if ( filter_wid <= 0 ) return;
   filter := filter_wid.p_text;
   if (_isUnix()) {
      if (def_unix_expansion) filter = _unix_expansion(filter);
   }

   // This is a distinction without a difference...
   // Well, anyway, the Slick-C code only makes use of one flag option (for now), but
   // the C code can distinguish the file sets. So if either flag is set in Slick-C, set
   // them both for the C code to use.
   if (viewsToShow & (OTBFO_WORKSPACE_FILE|OTBFO_PROJECT_FILE)) {
      FileListManager_RefreshWorkspaceFiles(getFileListManagerHandle(), gtbFilesFormList:[p_active_form].m_force_refresh_workspace);
      gtbFilesFormList:[p_active_form].m_force_refresh_workspace = false;
   } else if (viewsToShow & OTBFO_OPEN_FILE) {
      FileListManager_RefreshOpenFiles(getFileListManagerHandle());
   }

   _TreeBeginUpdate(TREE_ROOT_INDEX);
   int match_style=(def_filelist_flags&FILELIST_PREFIX_MATCH)?OPENTB_WC_RECURSIVE_PREFIX_MATCHING:OPENTB_WC_RECURSIVE_CONTAINS_MATCHING;
   index:=FileListManager_InsertListIntoTree(getFileListManagerHandle(), 
                                             p_window_id, TREE_ROOT_INDEX, 
                                             viewsToShow, filter,
                                             false, // not used
                                             "",
                                             false,
                                             (def_filelist_flags&FILELIST_RESTORE_COLUMN_WIDTHS)==0,
                                             (def_filelist_flags&FILELIST_SHOW_ABSOLUTE_PATHS)==0,
                                             def_filelist_wc_ext_match_style,
                                             def_filelist_wc_match_style,
                                             def_filelist_non_wc_match_style
                                             );
   _TreeEndUpdate(TREE_ROOT_INDEX);

   // Might need to update the selection if there is a filter
   if (filter._length()) {
      if (index > 0) {
         _TreeSetCurIndex(index);
         _TreeScroll(_TreeCurLineNumber());
         if (!_TreeUp()) _TreeDown();
         _TreeDeselectAll();
         _TreeSetCurIndex(index);
         _TreeSelectLine(index);
         _TreeRefresh();
      } else {
         firstChild := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         if (firstChild>0) {
            // When type c:\path\, don't select the type line.
            if (_last_char(filter)==FILESEP) {
               _TreeDeselectAll();
               _TreeSetCurIndex(firstChild);
               //_TreeSelectLine(firstChild);
               _TreeRefresh();
            } else {
               _TreeSetCurIndex(firstChild);
               _TreeScroll(_TreeCurLineNumber());
               if (!_TreeUp()) _TreeDown();
               _TreeDeselectAll();
               _TreeSetCurIndex(firstChild);
               _TreeSelectLine(firstChild);
               _TreeRefresh();
            }
         }
      }
   }
   // Restore the col button info
   if ( def_filelist_flags&FILELIST_RESTORE_COLUMN_WIDTHS ) {
//      _TreeRetrieveColButtonInfo(true);
   }
   //_TreeSortCol();
}

#if 0 //12:56pm 4/26/2012
/**
 * Called when files are added to the workspace.
 */
void _workspace_file_add_filelist(_str projName, _str fileName)
{
   tbfilelist_force_refresh_workspace = true;

   mou_hour_glass(true);
   _workspace_opened_filelist();
   _prjopen_filelist();
   _maybeRefreshWorkspaceFiles();

   mou_hour_glass(false);
}
#endif

/**
 * Called when a different project is opened (set active).
 */
void _prjopen_filelist(bool singleFileProject)
{
   if (singleFileProject) return;
   _maybeRefreshWorkspaceFiles();
   _maybeRefreshFilelistWorkspaceFiles();
#if 0
   TBFILES_FORM_INFO v;
   int form_wid;
   foreach (form_wid => v in gtbFilesFormList) {
      form_wid.ctl_project_list.FileListUpdateWorkspace(OTBFO_PROJECT_FILE);
   }
#endif
}

/**
 * Called when the active project is closed.
 */
void _prjclose_filelist(bool singleFileProject)
{
   if (singleFileProject) return;
   orig_project_name:=_project_name;_project_name="";
   _maybeRefreshWorkspaceFiles();
   _maybeRefreshFilelistWorkspaceFiles();
   _project_name=orig_project_name;
}

/**
 * Called when a different workspace is opened.
 */
void _workspace_opened_filelist()
{
   _maybeRefreshWorkspaceFiles();
   _maybeRefreshFilelistWorkspaceFiles();
#if 0
   TBFILES_FORM_INFO v;
   int form_wid;
   foreach (form_wid => v in gtbFilesFormList) {
      form_wid.ctl_workspace_list.FileListUpdateWorkspace(OTBFO_WORKSPACE_FILE);
      // _prjopen_filelist will catch the project, do not need to update here
   }
#endif
}
/** 
 * Called when files are added to any project by any means 
 * (i.e. even if a project is inserted into a workspace) 
 */
void _prjupdate_filelist() 
{
   _maybeRefreshWorkspaceFiles();
   _maybeRefreshFilelistWorkspaceFiles();
}

/**
 * Called when the current workspace is closed.
 */
void _wkspace_close_filelist()
{
   _maybeRefreshWorkspaceFiles();
   _maybeRefreshFilelistWorkspaceFiles();
}

void _update_tbfilelist_workspace()
{
   _maybeRefreshFilelistWorkspaceFiles();
}

static void _maybeRefreshFilelistWorkspaceFiles()
{
   // this definitely needs to be set - we need a refresh,
   // we just don't know if the list is showing right now

   TBFILES_FORM_INFO v;
   int form_wid;
   do_post := false;
   foreach (form_wid => v in gtbFilesFormList) {
      if (form_wid.ctl_sstab.p_ActiveTab ==  FILELIST_SHOW_WORKSPACE_FILES ||
          form_wid.ctl_sstab.p_ActiveTab ==  FILELIST_SHOW_PROJECT_FILES) {
         do_post=true;
         break;
      }
   }
   if (do_post) {
      if (gfilelist_pending_project_change_callback==false) {
         gfilelist_pending_project_change_callback=true;
         _post_call(FileListProjectChangeCallback);
      }
   }
}

/**
 * Get the information about the tag currently selected
 * in the file list.  The current object should be the tree control.
 * 
 * @param path          path to the file
 * @param LineNumber    line number for preview
 * @param index         (optional) tree node index other than current
 * 
 * @return 0 on failure, 1 on success.
 */
static int FileListGetInfo(_str &path, int &LineNumber, int index=-1)
{
   // find the tag name, file and line number
   if (index == -1) {
      index = _TreeCurIndex();
   }
   if (index <= 0) {
      // Probably nothing in the tree, so bail
      return 0;
   }
   buf_id := _TreeGetUserInfo(index);

   // If this is the project/workspace tree, just go to bottom...
   if ( p_name != "ctl_file_list" ) {
      _TreeGetInfo(index,auto state,auto bm1,auto bm2,auto nodeFlags);
      if ( nodeFlags&TREENODE_FORCECOLOR ) {
         // This is the warning message that the list was truncated
         return COMMAND_CANCELLED_RC;
      }
      buf_id="";
   }

   if (buf_id == '-') {
      // category
      return 0;

   } else if (isnumber(buf_id)) {

      // buffer ID
      orig_view_id := p_window_id;
      orig_wid := p_window_id;
      p_window_id=VSWID_HIDDEN;
      _safe_hidden_window();
      path="";
      int status=load_files('+q +bi 'buf_id);
      if (!status) {
         path=p_buf_name;
      }

      path=p_buf_name;
      LineNumber=p_line;
      p_window_id=orig_view_id;
      p_window_id=orig_wid;

   } else {
      // If there is no user info, just get the filename from the tree caption
      curFilename := _TreeGetCaption(index);
      parse curFilename with curFilename "\t" auto curFilepath "\t";
      curFilename=strip_buffer_id(curFilename);
      curFilepath = getAbsoluteFilePathInFileList(curFilepath);
      path = curFilepath:+curFilename;
      LineNumber = 1;
   }
   return 1;
}

/**
 * Open the file at the designated index in the file list. 
 * 
 * @param tree_index   tree node (file to open) 
 * @param edit_options options to use when editing file 
 * @param pEditCommands Pointer to a STRARRAY (optional).  If 
 *                      specified, do not run edit commmands,
 *                      store them in this array
 * 
 * @return 0 on success, <0 on error. 
 */
static int FileListEditFile(int tree_index,_str edit_options="",STRARRAYPTR pEditCommands=null,bool return_filenames=false)
{
   tree_wid := p_window_id;
   if (tree_index <= 0) return 0;
   buf_id := _TreeGetUserInfo(tree_index);
   // If this is the project/workspace tree, just go to bottom...
   if ( p_name!="ctl_file_list" ) {
      _TreeGetInfo(tree_index,auto state,auto bm1,auto bm2,auto nodeFlags);
      if ( nodeFlags&TREENODE_FORCECOLOR ) {
         // This is the warning message that the list was truncated
         return COMMAND_CANCELLED_RC;
      }
      buf_id="";
   }
   status := 0;
   if (buf_id == '-') {
      return FILE_NOT_FOUND_RC;
   }else if ( buf_id == "" ) {
      // If there is no user info, just get the filename from the tree caption
      curFilename := _TreeGetCaption(tree_index);
      parse curFilename with curFilename "\t" auto curFilepath "\t";
      curFilename=strip_buffer_id(curFilename);
      curFilepath = getAbsoluteFilePathInFileList(curFilepath);

      if (pEditCommands==null) {
         status = edit(edit_options:+" ":+_maybe_quote_filename(curFilepath:+curFilename),EDIT_DEFAULT_FLAGS);
      } else {
         if (return_filenames) {
            pEditCommands->[pEditCommands->_length()]=curFilepath:+curFilename;
         } else {
            pEditCommands->[pEditCommands->_length()]=edit_options:+" ":+_maybe_quote_filename(curFilepath:+curFilename);
         }
      }
      return status;
   }
   if (isnumber(buf_id)) {

      if (pEditCommands==null) {
         status = edit(edit_options:+" ":+"+bi ":+buf_id);
      } else {
         if (return_filenames) {
            status=_open_temp_view('',auto temp_wid,auto orig_wid,'+bi 'buf_id);
            if (!status) {
               pEditCommands->[pEditCommands->_length()]=temp_wid.p_buf_name;
               _delete_temp_view(temp_wid);
               p_window_id=orig_wid;
            }
         } else {
            pEditCommands->[pEditCommands->_length()]=edit_options:+" ":+"+bi ":+buf_id;
         }
      }

      // We were calling FileListUpdateOpenFiles here, but we can't do that 
      // because we may be called here while looping through the selected files 
      // and we cannot delete and re-fill the list.
      return status;
   }
   // we're calling edit, and it goes thru "normal channels" but it is getting 
   // the pointer for the workspace tab
   if (pEditCommands==null) {
      status = edit(edit_options:+" ":+_maybe_quote_filename(buf_id),EDIT_DEFAULT_FLAGS);
   } else {
      if (return_filenames) {
         pEditCommands->[pEditCommands->_length()]=buf_id;
      } else {
         pEditCommands->[pEditCommands->_length()]=edit_options:+" ":+_maybe_quote_filename(buf_id);
      }
   }

   return status;
}

/**
 * Filter all the files in the file list according to the given
 * filter regular expression.  This simply marks the files that
 * do not match the filter as hidden tree nodes, and the other
 * files as non-hidden.  The current object is expected to be
 * the file list tree control.
 * 
 * @param filter_re  Regular expression to match files against  
 */
static void FileListFilterFiles(_str filter_re)
{
   switch (p_name) {
   case "ctl_project_list":
      FileListUpdateWorkspace(OTBFO_PROJECT_FILE);
      break;
   case "ctl_workspace_list":
      FileListUpdateWorkspace(OTBFO_WORKSPACE_FILE|OTBFO_PROJECT_FILE);
      break;
   case "ctl_file_list":
   default:
      FileListUpdateWorkspace(OTBFO_OPEN_FILE);
      int newHashtab:[];
      child_index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (child_index > 0) {
         buf_id := _TreeGetUserInfo(child_index);
         buf_name := _TreeGetCaption(child_index,1):+_TreeGetCaption(child_index,0);
         storeInHashtab(&newHashtab,buf_id,child_index,buf_name);

         // If this node is the current file, set it to be the current index
         if ( !_no_child_windows() && _file_eq(_mdi.p_child.p_buf_name,buf_name) ) {
            _TreeSetCurIndex(child_index);
         }
         child_index = _TreeGetNextSiblingIndex(child_index);
      }
      SetFileListHashTab(newHashtab);
      _UpdateFileListModifiedFilesOne(p_active_form,true,true);
      break;
   }
   // do we pick something?
   parse filter_re with filter_re "*" .; 
   parse filter_re with filter_re "?" .; 
   if ( filter_re != "") {
      // do a prefix match selection...
      index := _TreeSearch(TREE_ROOT_INDEX, filter_re, 'P', null, 0);
      if (index > 0) {
         _TreeSetCurIndex(index);
         _TreeScroll(_TreeCurLineNumber());
         if (!_TreeUp()) _TreeDown();
         _TreeDeselectAll();
         _TreeSetCurIndex(index);
         _TreeSelectLine(index);
      } else {
         // just select the current line
         index = _TreeCurIndex();
         if (index > 0) {
            _TreeDeselectAll();
            _TreeSelectLine(index);
         }
      }
   }

   //_TreeRefresh();
   return;
}

static void select_top_line()
{
   scroll := _TreeScroll();
   newindex := _TreeGetIndexFromLineNumber(scroll);
   if ( newindex>-1 ) {
      _TreeDeselectAll();
      _TreeSetCurIndex(newindex);
      _TreeSelectLine(newindex);
   }
}

/**
 * This is the timer callback.  Whenever the current index 
 * (cursor position) for the file list is changed, a timer 
 * is started/reset.  If no activity occurs within a set 
 * amount of time, this function is called to update the 
 * preview window.
 */
static void FileListFocusTimerCallback(_str form_and_tree_wid)
{
   // get the class browser form window id
   parse form_and_tree_wid with auto form_wid ' ' auto tree_wid;
   if (!isinteger(form_wid) || !isinteger(tree_wid)) {
      return;
   }
   f := (int)form_wid;
   if (!_iswindow_valid(f) ||
       (f.p_name!=TBFILES_FORM && f.p_name!=DOCUMENT_TAB_FORM)) {
      return;
   }
   t := (int)tree_wid;
   if (!_iswindow_valid(t) || t.p_object != OI_TREE_VIEW) {
      return;
   }

   // kill the timer
   timer_id := _GetDialogInfoHt(FILELIST_TIMER_ID,f.ctl_file_list);
   if ( timer_id != null && _timer_is_valid(timer_id) ) {
      _kill_timer(timer_id);
   }
   _SetDialogInfoHt(FILELIST_TIMER_ID,-1,f.ctl_file_list);

   // find the tag name, file and line number
   if (t.FileListGetInfo(auto path,auto LineNumber)) {
      FileListUpdatePreview(path,LineNumber);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Auto save timer entry point for updating file mod status
//

void _cbsave_filelist()
{
   if (batch_call_list("_UpdateFileListModifiedFiles",true)) {
      return;
   }
   _UpdateFileListModifiedFiles(true);
}
static void _UpdateFileListModifiedFilesOne(int formwid,bool forceUpdate=false,bool fileListIsUpToDate=false) {
   if (_no_child_windows()) {
      return;
   }

   FILELIST_SHOW_STATE filelist_show=formwid.getFilelistShowState();
   if ( forceUpdate || 
        filelist_show==FILELIST_SHOW_OPEN_FILES ||
        filelist_show==FILELIST_SHOW_DOCUMENT_TABS ) {
      treewid := formwid._find_control("ctl_file_list");
      if ( !treewid ) return;
      filterwid := formwid._find_control("ctl_filter");
      if ( !filterwid ) return;
      int (*pBufIdHash):[] = treewid.GetPointerToFileListHashTab();
      child_index := treewid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if (!fileListIsUpToDate && (child_index<0 || pBufIdHash==null)) {
         // if gbuffer_id_hash==null prbly means that the module was reloaded.
         //treewid.FileListUpdateOpenFiles();
         treewid.FileListFilterFiles(filterwid.p_text);
         pBufIdHash = treewid.GetPointerToFileListHashTab();
      }

      typeless time = _GetDialogInfoHt("time",formwid.ctl_file_list);
      if ( time==null ) time=0;
      typeless time_now = _time('B');


      if ( forceUpdate || (_idle_time_elapsed() > 250 && (((time_now - time) < 0) || ((time_now-time) > 1000)))) {
         file_list := formwid.FileListGetFileTreeWid();
         if (!file_list) return;
         // keep track of the current buffer ID
         editorctl_wid := formwid.FileListGetEditorCtlWid();
         cur_buf_id := editorctl_wid? editorctl_wid.p_buf_id : _mdi.p_child.p_buf_id;

         if ( !forceUpdate && (_get_focus() == file_list) ) {
            // Check if the wrong buffer is bolded.
            //index:=(*pBufIdHash):[cur_buf_id];
            index := -1;
            if (pBufIdHash && (*pBufIdHash)._indexin(cur_buf_id)) {
               index=(*pBufIdHash):[cur_buf_id];
               if (index==null) index= -1;
            }
            if ( index>=0 ) {
               treewid._TreeGetInfo(index,auto state,auto bm1,auto bm2, auto nodeFlags);
               orig_nodeFlags:=nodeFlags;
               orig_state:=state;
               if ( editorctl_wid.tbfilelist_is_modified() ) {            
                  nodeFlags|=TREENODE_FORCECOLOR|TREENODE_ITALIC;
                  state=1;
               }else{
                  nodeFlags&=~(TREENODE_ALTCOLOR|TREENODE_FORCECOLOR|TREENODE_ITALIC);
                  state=0;
               }
               nodeFlags|=TREENODE_BOLD;
               if (orig_nodeFlags==nodeFlags && orig_state==state) {
                  //say('blow this off');
                  return;
               }
               // do this now

            } else {
               //say('not found blow this off');
               return;
            }
         }

         int status=_open_temp_view("",auto temp_wid,auto orig_wid,'+bi 'cur_buf_id);
         if (!status) {
            // cycle through the open buffers and add them 
            for (;;) {
               _next_buffer('HR');

               //index:=(*pBufIdHash):[p_buf_id];
               index := -1;
               if (pBufIdHash && (*pBufIdHash)._indexin(p_buf_id)) {
                  index=(*pBufIdHash):[p_buf_id];
                  if (index==null) index= -1;
               }
               if ( index > 0 && treewid._TreeIndexIsValid(index) ) {
                  treewid._TreeGetInfo(index,auto state,auto bm1,auto bm2, auto nodeFlags);
                  if ( tbfilelist_is_modified() ) {            
                     nodeFlags|=TREENODE_FORCECOLOR|TREENODE_ITALIC;
                  }else{
                     nodeFlags&=~(TREENODE_ALTCOLOR|TREENODE_FORCECOLOR|TREENODE_ITALIC);
                  }
                  bm2 = getBitmapForCurrentBuffer(bm1);
                  if ( p_buf_id==cur_buf_id ) {
                     nodeFlags|=TREENODE_BOLD;
                  }else{
                     nodeFlags&=~TREENODE_BOLD;
                  }
                  // We have to use -1 for the bitmap indexes.  If we don't 
                  // use -1, it will use the bitmap index and skip the overlays.
                  treewid._TreeSetInfo(index,state,-1,-1,nodeFlags);
               }

               if (p_buf_id==cur_buf_id) break;
            }
            _delete_temp_view(temp_wid);
            p_window_id=orig_wid;
         }

         file_list._TreeRefresh();
         time = _time('B');
         _SetDialogInfoHt("time",time,formwid.ctl_file_list);
      }
   }
}


/**
 * check every buffer for modified status once every second approx.<P>
 * gets called from the autosave call list
 */
void _UpdateFileListModifiedFiles(bool forceUpdate=false)
{
   TBFILES_FORM_INFO v;
   int form_wid;
   foreach (form_wid => v in gtbFilesFormList) {
      _UpdateFileListModifiedFilesOne(form_wid,forceUpdate);
   }

}

static int getBitmapForCurrentBuffer(int &pic_overlay=0)
{
   pic_file := 0;
   pic_overlay = 0;
   if (p_LangId=="fileman") {
      pic_file = _pic_fldopen;
   } else if (p_LangId=="process") {
      pic_file = _pic_build12;
   } else if (_isGrepBuffer(p_buf_name)) {
      pic_file = _pic_search12;
   } else {
      if (_istagging_supported()) {
         pic_file = _pic_file;
      } else {
         pic_file = _pic_file_d;
      }
      if ( tbfilelist_is_modified() ) {
         pic_overlay = _pic_file_mod_overlay;
      }
   }
   return pic_file;
}

#if 0
//////////////////////////////////////////////////////////////////////////////
// Editor hook functions
//

/**
 * gets called when active buffer is switched
 *
 * @param oldbuffname
 *               name of buffer being switched from
 * @param flag   flag = 'Q' if file is being closed
 *               flag = 'W' if focus is being indicated
 */
void _switchbuf_filelist(_str oldbuffname, _str flag)
{
   // "Q" option. Not sure if this is the best course
   // of action don't want a Slick-C stack.
   if (!_isEditorCtl(false)) {
      return;
   }
   if (!def_switchbuf_filelist) return;

   TBFILES_FORM_INFO v;
   int form_wid;
   foreach (form_wid => v in gtbFilesFormList) {
      tree_wid := form_wid.FileListGetFileTreeWid();
      if (!tree_wid) return;
      int (*pbuffer_id_hash):[] = tree_wid.GetPointerToFileListHashTab();
      if ( pbuffer_id_hash == null ) return;
      //index := (*pbuffer_id_hash):[p_buf_id];
      index := -1;
      if ((*pbuffer_id_hash)._indexin(p_buf_id)) {
         index=(*pbuffer_id_hash):[p_buf_id];
         if (index==null) index= -1;
      }
      if ( index>=0 ) {
         tree_wid._TreeSetCurIndex(index);
         // DO NOT update the bold here because doing an immediate update
         // causes a complete tree page refresh and this looks bad
         // when multiple files are closed.
      }
   }
}
#endif

/**
 * Called when the current file is renamed.
 */
void _document_renamedAfter_filelist(int buf_id,_str old_bufname,_str new_bufname,int buf_flags)
{
   if (buf_flags & VSBUFFLAG_HIDDEN) return;
   TBFILES_FORM_INFO v;
   int form_wid;
   foreach (form_wid => v in gtbFilesFormList) {
      tree_wid := form_wid.FileListGetFileTreeWid();
      if (!tree_wid) return;
      filter_wid := form_wid.FileListGetCurrentFilterWid();
      if (!filter_wid) return;
      //tree_wid.FileListUpdateOpenFiles();
      tree_wid.FileListFilterFiles(filter_wid.p_text);
   }
}

/**
 * Called when the current file is renamed.
 */
void _buffer_renamedAfter_filelist(int buf_id,_str old_bufname,_str new_bufname,int buf_flags)
{
   if (buf_flags & VSBUFFLAG_HIDDEN) return;
   TBFILES_FORM_INFO v;
   int form_wid;
   foreach (form_wid => v in gtbFilesFormList) {
      tree_wid := form_wid.FileListGetFileTreeWid();
      if (!tree_wid) return;
      filter_wid := form_wid.FileListGetCurrentFilterWid();
      if (!filter_wid) return;
      //tree_wid.FileListUpdateOpenFiles();
      tree_wid.FileListFilterFiles(filter_wid.p_text);
   }
}
static void FileListBufferAddCallback() 
{
   TBFILES_FORM_INFO v;
   int form_wid;
   foreach (form_wid => v in gtbFilesFormList) {
      typeless ignore_cbquit_callback=_GetDialogInfoHt(FILELIST_IGNORE_CBQUIT,form_wid.ctl_file_list);
      if ( ignore_cbquit_callback) continue;

      tree_wid := form_wid.FileListGetFileTreeWid();
      if (!tree_wid) continue;
      if ( tree_wid.p_name!="ctl_file_list" ) continue;
      wid := p_window_id;
      p_window_id=tree_wid;
      filter_wid := form_wid.FileListGetCurrentFilterWid();
      if (!filter_wid) continue;
      FileListFilterFiles(filter_wid.p_text);
      tree_wid._TreeSortCol();
      sizeColumns(tree_wid);
      p_window_id=wid;
   }
   gfilelist_pending_buffer_add_callback=false;
}
static void FileListProjectChangeCallback() 
{
   TBFILES_FORM_INFO v;
   int form_wid;
   foreach (form_wid => v in gtbFilesFormList) {
      if (form_wid.ctl_sstab.p_ActiveTab ==  FILELIST_SHOW_WORKSPACE_FILES ||
          form_wid.ctl_sstab.p_ActiveTab ==  FILELIST_SHOW_PROJECT_FILES) {
         tree_wid := form_wid.FileListGetCurrentTreeWid();
         if (!tree_wid) continue;
         wid := p_window_id;
         p_window_id=tree_wid;
         filter_wid := form_wid.FileListGetCurrentFilterWid();
         if (!filter_wid) continue;
         gtbFilesFormList:[form_wid].m_force_refresh_workspace = true;
         FileListFilterFiles(filter_wid.p_text);
         //sizeColumns(tree_wid);
         p_window_id=wid;
      }
   }
   gfilelist_pending_project_change_callback=false;
}

/**
 * Called when a new file is opened.
 */
void _buffer_add_filelist(int newbuffid, _str name, int flags = 0)
{
   if (flags & VSBUFFLAG_HIDDEN) return;

   TBFILES_FORM_INFO v;
   int form_wid;
   foreach (form_wid => v in gtbFilesFormList) {
      tree_wid := form_wid.FileListGetFileTreeWid();
      if (!tree_wid) return;
      index := FileListAddBuffer(tree_wid, true);
   }

   if (gtbFilesFormList._length()) {
      if (gfilelist_pending_buffer_add_callback==false) {
         gfilelist_pending_buffer_add_callback=true;
         _post_call(FileListBufferAddCallback);
      }
   }
}

/**
 * Called when the current file is switched to a hidden state.
 */
void _cbmdibuffer_hidden_filelist()
{
   _cbquit_filelist(p_buf_id,p_buf_name,p_DocumentName,p_buf_flags);
}
/**
 * Gets called when a hidden buffer becomes unhidden.
 */
void _cbmdibuffer_unhidden_filelist()
{
   _buffer_add_filelist(p_buf_id,p_buf_name,p_buf_flags);
}

/**
 * Called when the given files is closed.
 */
void _cbquit_filelist(int buf_id,_str buf_name,_str DocumentName,int buf_flags)
{
   TBFILES_FORM_INFO v;
   int form_wid;
   foreach (form_wid => v in gtbFilesFormList) {
      typeless ignore_cbquit_callback=_GetDialogInfoHt(FILELIST_IGNORE_CBQUIT,form_wid.ctl_file_list);
      if ( ignore_cbquit_callback ) continue;

      tree_wid := form_wid.FileListGetFileTreeWid();
      if (!tree_wid) continue;

      int (*pbuffer_id_hash):[]=tree_wid.GetPointerToFileListHashTab();
      if ( pbuffer_id_hash == null ) return;
      //index := (*pbuffer_id_hash):[buf_id];
      index := -1;
      if ((*pbuffer_id_hash)._indexin(buf_id)) {
         index=(*pbuffer_id_hash):[buf_id];
         if (index==null) index= -1;
      }
      if ( index>=0 ) {
         tree_wid._TreeDelete(index);
         if ((*pbuffer_id_hash)._indexin(buf_id)) {
            (*pbuffer_id_hash)._deleteel(buf_id);
         }
      } else {
         if ( buf_flags & VSBUFFLAG_HIDDEN ) return;
         index = TREE_ROOT_INDEX;
         tree_wid._TreeDelete(index,'c');
         (*pbuffer_id_hash)._makeempty();
         index = tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         while (index > 0) {
            (*pbuffer_id_hash):[tree_wid._TreeGetCaption(index)] = index;
            index = tree_wid._TreeGetNextSiblingIndex(index);
         }
      }
   }
}


void _workspace_refresh_filelist()
{
   _workspace_opened_filelist();
   //_prjopen_filelist();
}

#if 0
static void restoreButton()
{
   formwid:=tbGetActiveFilesForm();

   if ( formwid ) {
      wid := p_window_id;
      p_window_id=formwid;
      if ( gfilelist_show==FILELIST_SHOW_DOCUMENT_TABS ) {
         showDocumentTabs();
      }else if ( gfilelist_show==FILELIST_SHOW_OPEN_FILES ) {
         showOpenFiles();
      }else if ( gfilelist_show== FILELIST_SHOW_PROJECT_FILES ) {
         showProjectFiles();
      }else if ( gfilelist_show==FILELIST_SHOW_WORKSPACE_FILES ) {
         showWorkspaceFiles();
      }
      p_window_id=wid;
   }else{
      _post_call(restoreButton);
   }
}
#endif

void _FilelistSelectCurrentBuffer()
{
   if ( !_no_child_windows() ) {
      bufname := p_buf_name;
      formwid := _find_formobj("_tbfilelist_form",'N');
      if ( formwid ) {
         wid := p_window_id;
         _nocheck _control ctl_file_list;
         p_window_id=formwid.ctl_file_list;
         index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         for (;index>-1;) {
            curcaption := _TreeGetCaption(index);
            parse curcaption with auto justname auto path;
            justname=strip_buffer_id(justname);
            path = getAbsoluteFilePathInFileList(path);
            if ( _file_eq(bufname,path:+justname) ) {
               _TreeDeselectAll();
               _TreeSelectLine(index);
               break;
            }
            index=_TreeGetNextSiblingIndex(index);
         }
         p_window_id=wid;
      }        
   }
}

bool _project_save_restore_done;
int _srg_tbfilelist(_str option="",_str info="")
{
   //say('_srg_tbfilelist');
   if ( option=='R' || option=='N' ) {
      typeless temp="";
      parse info with . temp .;
      gfilelist_show=temp;
   } else if(!_project_save_restore_done) {
      insert_line('TBFILELIST: 0 'gfilelist_show);
   }
   return(0);
}

/**
 * Need to be able to call this from proctree.e and cbrowser.e
 */
int _GetFilesToolTreeWID()
{
   int wid = _find_formobj("_tbfilelist_form",'n');
   return wid;
}

defeventtab _document_tab_choose_file_form;

static void DocumentTabFileListResize()
{
   // Set up basic layout of form
   ctl_filter.p_x = 30;
   ctl_filter.p_y = 30;
   ctl_filter.p_x_extent = ctl_file_list.p_width ;
   ctl_file_list.p_x = 30;
   ctl_file_list.p_y = ctl_filter.p_height+60;

   // Get the editor control this tab is associated with
   editorctl_wid := FileListGetEditorCtlWid();
   if ( editorctl_wid == 0 ) editorctl_wid = _mdi.p_child;

   // compute width to size buffer list to
   max_width := _dx2lx(SM_TWIP, editorctl_wid.p_width);
   ctl_file_list.p_width = max_width intdiv 10;
   orig_bold := ctl_file_list.p_font_bold;
   ctl_file_list.p_font_bold = true;
   ctl_file_list._TreeSizeColumnToContents(-1);
   ctl_file_list.p_font_bold = orig_bold;
   _TreeGetColButtonInfo(0, auto fileWidth, auto fileFlags, auto fileState, auto fileCaption);
   _TreeGetColButtonInfo(1, auto pathWidth, auto pathFlags, auto pathState, auto pathCaption);
   required_width := fileWidth + pathWidth + 360;
   if (required_width > max_width) required_width = max_width;
   hasScrollBar := (required_width+360 >= max_width)? 1:0;
   ctl_file_list.p_width = required_width;
   ctl_filter.p_width = required_width;

   borderWidth := _TreeGetBorderWidth() * _twips_per_pixel_y();

   // compute height to size buffer list to
   max_height := _dy2ly(SM_TWIP, editorctl_wid.p_height) - ctl_file_list.p_y;
   if (max_height < 0) max_height = 1000;
   numFiles := ctl_file_list._TreeGetNumChildren(TREE_ROOT_INDEX);
   line_height := _twips_per_pixel_y()*ctl_file_list.p_line_height;
   headerHeight := _TreeGetHeaderHeight()*_twips_per_pixel_y();
   // Since we are trying to make the tree the exact height of the lines in it,
   // we have to know exactly how big to make it. This means besides knowign the
   // height of a line, we have to know the height of the header, and the width
   // of the border (and then multiply the border width by two, because it will
   // be on the top and the bottom.
   required_height := headerHeight + ((numFiles+hasScrollBar)*line_height) + (2*borderWidth);
   if (required_height > max_height) required_height = max_height;
   ctl_file_list.p_height = required_height;

   // First time
   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      ctl_file_list._TreeRetrieveColButtonInfo(true);
      if ( numFiles > 0 ) {
         ctl_file_list.p_font_bold = true;
         ctl_file_list._TreeSizeColumnToContents(-1);
         ctl_file_list.p_font_bold = orig_bold;
      }
   }
}

static void kill_document_tab_choose_file_form(int editorctl_wid=0)
{
   list_wid := _find_formobj(DOCUMENT_TAB_FORM, "n");
   if (list_wid > 0) {
      list_wid._delete_window();
      if (_iswindow_valid(editorctl_wid) && editorctl_wid._isEditorCtl()) {
         activate_window(editorctl_wid);
      }
      return;
   }
}

void _document_tab_choose_file_form.ESC()
{
   // Get the editor control this tab is associated with
   editorctl_wid := FileListGetEditorCtlWid();
   p_active_form._delete_window();
   if (_iswindow_valid(editorctl_wid) && editorctl_wid._isEditorCtl()) {
      activate_window(editorctl_wid);
   }
}

void _document_tab_choose_file_form.on_lost_focus()
{
   int modal_wid=_ModalDialog();
   if (modal_wid && modal_wid.p_parent==ctl_filter) {
      return;
   }
   // Check if focus switched away from our form
   wid := _get_focus();
   if (wid > 0) {
      switch (wid.p_object) {
      case OI_FORM:
      case OI_TREE_VIEW:
      case OI_TEXT_BOX:
         if (wid.p_active_form.p_name == DOCUMENT_TAB_FORM) return;
         break;
      default:
         break;
      }
   }

   // Get the editor control this tab is associated with
   editorctl_wid := FileListGetEditorCtlWid();
   if ( editorctl_wid == 0 ) return;
   _post_call(kill_document_tab_choose_file_form, editorctl_wid);
}

/**
 * Set to the time the file list was closed. 
 * This is utilized by the document tabs drop-down to check 
 * if the window had just been closed if the user clicks on 
 * the button again to close the drop-down. 
 */
int _DocumentTabChooseFileFormTimeElapsedSinceClosing(bool resetTime=false) 
{
   static long close_time;
   long now = (long)_time('B');
   if (resetTime) close_time = now;
   return (int)(now - close_time);
}

void _document_tab_choose_file_form.on_destroy()
{
   cur_tree_wid := FileListGetCurrentTreeWid();
   if ( cur_tree_wid ) {
      cur_tree_wid._TreeAppendColButtonInfo(true);
   }
   _DocumentTabChooseFileFormTimeElapsedSinceClosing(true);
}

#if 0
Should not need this
void _switchbuf_document_tab_choose_file_form(_str oldbuffname="", _str flag=0)
{
   editorctl_wid := FileListGetEditorCtlWid(true);
   if ( editorctl_wid == 0 ) return;
   _post_call(kill_document_tab_choose_file_form, editorctl_wid);
}
#endif
