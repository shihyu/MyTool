////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50020 $
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
#import "alias.e"
#import "backtag.e"
#import "clipbd.e"
#import "complete.e"
#import "dirlist.e"
#import "dirtree.e"
#import "drvlist.e"
#import "filelist.e"
#import "fileman.e"
#import "files.e"
#import "frmopen.e"
#import "guiopen.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "makefile.e"
#import "optionsxml.e"
#import "picture.e"
#import "print.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "stdprocs.e"
#import "stdcmds.e"
#import "tagform.e"
#import "tbfilelist.e"
#import "toolbar.e"
#import "treeview.e"
#import "util.e"
#import "vc.e"
#import "window.e"
#import "wkspace.e"
#endregion



//
// _tbopen_form
//

#define OPEN_TB_FORM_NAME_STRING '_tbopen_form'

#define TBOPEN_MINFORMWIDTH  7500
#define TBOPEN_MINFORMHEIGHT 3000

enum_flags OpenTBFileOrigins {
   OTBFO_DIR_ON_DISK          = 0x01,
   OTBFO_FILE_ON_DISK         = 0x02,
   OTBFO_PROJECT_FILE         = 0x04,
   OTBFO_WORKSPACE_FILE       = 0x08,
   OTBFO_HISTORY_FILE         = 0x10,
   OTBFO_OPEN_FILE            = 0x20,
};

enum_flags OPENTB_FLAGS {
   OPENTB_PREFIX_MATCH           = 0x01,
   OPENTB_SYNC_DIRECTORY         = 0x02,
// OPENTB_SHOW_HIDDEN_FILES      = 0x04,
   OPENTB_DISMISS_AFTER_SELECT   = 0x08,
   OPENTB_UPDATE_IMMEDIATELY     = 0x10,
   OPENTB_HIDE_DIRECTORIES       = 0x20,
   OPENTB_CLEAR_FILENAME_TEXTBOX = 0x40,
   OPENTB_RESTORE_COLUMN_WIDTHS  = 0x80,
};

int def_opentb_views = (OTBFO_PROJECT_FILE | OTBFO_OPEN_FILE);
int def_opentb_options = (OPENTB_SYNC_DIRECTORY | OPENTB_DISMISS_AFTER_SELECT | OPENTB_CLEAR_FILENAME_TEXTBOX);

defeventtab _tbopen_form;

#define DIR_PANEL_EXPANDED             _expand_dir_panel_button.p_user
/*
   Note: CUR_FILTER does NOT contain the same value as  _file_name_filter.p_text.
   Double quotes have been removed from CUR_FILTER.
*/
#define CUR_FILTER                     _file_name_filter.p_user
#define CUR_FILES_OF_TYPE              _files_of_type.p_user
#define CUR_TOTAL_FILTER               _files_of_type_label.p_user
#define CUR_DIR                        _opencd.p_user
#define OPEN_TB_RESIZING               _grabbar_vert.p_user
#define COLUMN_RESIZING                _grabbar_horz.p_user
#define CURRENT_VIEWS                  _options_link.p_user
#define CUR_FILES_ON_DISK_DIR          _filenameLabel.p_user
#define CUR_ALL_FILTER_TEXT            _opendrives_stub.p_user

// saved in _file_tree.p_user
#define OPEN_TB_FILE_TABLE             'OpenTBFileTable'
#define OPEN_TB_REFRESH_TIMER          'OpenTBRefreshTimer'
#define OPEN_TB_POSITION_TABLE         'OpenTBPositionTable'
#define OPEN_TB_PIC_INDEX_TABLE        'OpenTBPicIndexTable'

enum FileOnDiskType {
   FODT_DIRECTORY,
   FODT_FILE,
}



#define OTB_FILE_ORIGIN_DISK_DIR             'D'
#define OTB_FILE_ORIGIN_DISK_FILE            'F'
#define OTB_FILE_ORIGIN_PROJ                 'P'
#define OTB_FILE_ORIGIN_WKSPACE              'W'
#define OTB_FILE_ORIGIN_OPEN                 'O'
#define OTB_FILE_ORIGIN_HISTORY              'H'


static boolean ignore_change_cd_callback = false;
// Keeps track of which origin sets (OTBFO_*) need to
// be refreshed when the timer is triggered
static int timer_refresh_flags = 0;
// Sees if the next workspace refresh should clear out
// any previous results. 
static boolean force_refresh_workspace = false;
// Used by SuspendRefreshTimer and ResumeRefreshTimer. Prevents
// a bunch of refreshes that may affect the view state when
// going over multi-selected trees.
static boolean force_timer_delay = false;

boolean _show_hidden_files(boolean value = null)
{
   if (value == null) {
      value = def_filelist_show_dotfiles;
   } else {
      def_filelist_show_dotfiles = value;
      rescanFilesOnDisk();
      refreshFileTree('refreshFilesOnDisk');
   }

   return value;
}

int _open_tb_filelist_limit(int value = null)
{
   if (value == null) {
      // we just want the current value, so return it nicely
      value = def_filelist_limit;
   } else {
      def_filelist_limit = value;
      _update_tbfilelist_workspace();
      _maybeRefreshWorkspaceFiles();
   }

   return value;
}

int _open_tb_visible_views(int value = null)
{
   if (value == null) {
      // we just want the current value, so return it nicely
      value = def_opentb_views;
   } else {
      def_opentb_views = value;
      refreshFileTree('_open_tb_visible_views');
   }

   return value;
}

int _open_tb_options(int value = null)
{
   if (value == null) {
      // we just want the current value, please
      value = def_opentb_options;
   } else {
      // we are changing things, but what?
      changingPrefix := (def_opentb_options & OPENTB_PREFIX_MATCH) != (value & OPENTB_PREFIX_MATCH);
      turningSyncOn := ((def_opentb_options & OPENTB_SYNC_DIRECTORY) == 0) && (value & OPENTB_SYNC_DIRECTORY);
      changingShowDirs := (def_opentb_options & OPENTB_HIDE_DIRECTORIES) != (value & OPENTB_HIDE_DIRECTORIES);
      turnedOffRestoreColumns := (def_opentb_options&OPENTB_RESTORE_COLUMN_WIDTHS) &&
                                 !(value & OPENTB_RESTORE_COLUMN_WIDTHS);
      def_opentb_options = value;

      // we may need to do some refresher stuff...
      treeWid := getFileTree();
      if (treeWid > 0) {
         origWid := p_window_id;
         p_window_id = treeWid;
         boolean needARefresh = false;
         // refresh the files on disk - hidden files and directories may be appearing or disappearing
         if (changingShowDirs){
            needARefresh = true;
            FileListManager_RefreshDiskFiles(getFileListManagerHandle(), getCurrentFilesOnDiskDirectory(), doShowHiddenFiles());
         } else if (changingPrefix && CUR_FILTER != '') {
            // if we are changing whether we use prefix matches and are currently filtering, redo the filter
            needARefresh = true;
         } else if (turningSyncOn) {
            curDir := getcwd();
            _explorer_tree._set_current_path(curDir, false, doShowHiddenFiles(), false);
            needARefresh = true;
         }
         if ( turnedOffRestoreColumns ) {
            _TreeSizeColumnToContents(-1);
         }
         p_window_id = origWid;
         if(needARefresh) {
            refreshFileTree('_open_tb_options');
         }
      }
   }

   return value;
}

int _open_tb_orientation(int value = null)
{
   if (value == null) {
      value = def_opentb_orientation;
   } else {
      if (def_opentb_orientation != value) {
         def_opentb_orientation = value;

         // if the open tool window is open, call resize, so we'll change the orientation
         wid := _tbGetWid("_tbopen_form");
         if (wid != 0) {
            wid.call_event(wid, ON_RESIZE);
         }
      }
   }

   return value;
}

static int getFileTree()
{
   return _find_object(OPEN_TB_FORM_NAME_STRING'._file_tree', 'N');
}

static int getFileNameLabel()
{
   return _find_object(OPEN_TB_FORM_NAME_STRING'._filenameLabel', 'N');
}

static _str getFileNameFilter()
{
   // This is a little safer than using the CUR_FILTER #define, since who knows
   // what the current window id will be when callbacks are fired.
   int fnfId = _find_object(OPEN_TB_FORM_NAME_STRING'._file_name_filter', 'N');
   if(fnfId != 0) {
      return fnfId.p_user;
   }
   return '';
}

static int getOpenCDLabel(){
   return _find_object(OPEN_TB_FORM_NAME_STRING'._opencd', 'N');
}

static typeless * getPointerToFileHashTab()
{
   wid := getFileTree();
   if ( wid <= 0 ) return null;

   return _GetDialogInfoHtPtr(OPEN_TB_FILE_TABLE, wid);
}

static typeless * getPointerToRefreshTimer()
{
   wid := getFileTree();
   if ( wid <= 0 ) return null;

   return _GetDialogInfoHtPtr(OPEN_TB_REFRESH_TIMER, wid);
}

static typeless * getPointerToPositionTable()
{
   wid := getFileTree();
   if ( wid <= 0 ) return null;

   return _GetDialogInfoHtPtr(OPEN_TB_POSITION_TABLE, wid);
}

static typeless * getPointerToPicIndexTable()
{
   wid := getFileTree();
   if ( wid <= 0 ) return null;

   return _GetDialogInfoHtPtr(OPEN_TB_PIC_INDEX_TABLE, wid);
}

static int getFileListManagerHandle(){
   return FileListManager_GetHandle(OPEN_TB_FORM_NAME_STRING);
}

/**
 * The open tool window file tree is not updated immediately when the current 
 * project or workspace changes.  Instead, the old project files are removed. 
 * The new project files will be added when the tool window gets focus.  The 
 * user can set the Immediate Update option to immediately add the new project 
 * files. 
 *  
 * This function checks whether immediate update is currently on. 
 * 
 * @return           true if immediate update is on, false otherwise
 */
static boolean isUpdateImmediate()
{
   return (def_opentb_options & OPENTB_UPDATE_IMMEDIATELY) != 0;
}

static boolean doShowHiddenFiles()
{
   return def_filelist_show_dotfiles;
}

static boolean checkFilterView()
{
   boolean rescanWorkspace = false;
   /* By this point, the File List Manager has already been called to rescan the
      necessary file/origin sets. This method just places those sets into the
      control after filtering out unwanted sets and optional name fitering. */ 
   origWid := p_window_id;
   treeWid := getFileTree();
   if (treeWid <= 0) return rescanWorkspace;

   // Do we have any sort of filter? If so, then we'll want to add the views
   // that are specified in _open_tb_visible_views. Otherwise, we only
   // display disk files, and perhaps subdirectories.
   _str filter = getFileNameFilter();
   p_window_id = treeWid;

   int viewsToShow = FLMFOFLAG_DISKFILES;
   if(filter._length() > 0) {
      viewsToShow |= _open_tb_visible_views();
   }

   if((viewsToShow & OTBFO_PROJECT_FILE) || (viewsToShow & OTBFO_WORKSPACE_FILE)) {
      viewsToShow |= (OTBFO_PROJECT_FILE | OTBFO_WORKSPACE_FILE);
      if(filter != '') {
         rescanWorkspace = true;
      }
   }

   p_window_id = origWid;
   return rescanWorkspace;
}

/**
 * Refreshes the file listing tree control. 
 */
static void refreshFileTree(_str calledFrom=''){

   // Tracing code, can be removed
   /*
   if(calledFrom != '') {
      say('Called from: 'calledFrom);
   } else {
      say('Unknown caller');
   }
   */

   /* By this point, the File List Manager has already been called to rescan the
      necessary file/origin sets. This method just places those sets into the
      control after filtering out unwanted sets and optional name fitering. */ 
   origWid := p_window_id;
   treeWid := getFileTree();
   if (treeWid <= 0) return;

   // Do we have any sort of filter? If so, then we'll want to add the views
   // that are specified in _open_tb_visible_views. Otherwise, we only
   // display disk files, and perhaps subdirectories.
   _str filter = getFileNameFilter();
#if __UNIX__
   if (def_unix_expansion) filter = _unix_expansion(filter);
#endif
   p_window_id = treeWid;

   int viewsToShow = FLMFOFLAG_DISKFILES;
   if(filter._length() > 0) {
      viewsToShow |= _open_tb_visible_views();
   }
   if(!(_open_tb_options() & OPENTB_HIDE_DIRECTORIES)) {
      viewsToShow |= FLMFOFLAG_DIRECTORIES;
   }

   // This is a distinction without a difference...
   // Well, anyway, the Slick-C code only makes use of one flag option (for now), but
   // the C code can distinguish the file sets. So if either flag is set in Slick-C, set
   // them both for the C code to use.
   if((viewsToShow & OTBFO_PROJECT_FILE) || (viewsToShow & OTBFO_WORKSPACE_FILE)) {
      viewsToShow |= (OTBFO_PROJECT_FILE | OTBFO_WORKSPACE_FILE);
      if(filter != '') {
         rescanWorkspaceFiles();
      }
   }

   treeWid._TreeBeginUpdate(TREE_ROOT_INDEX);
   index:=FileListManager_InsertListIntoTree(getFileListManagerHandle(), getFileTree(), TREE_ROOT_INDEX, viewsToShow, filter , (def_opentb_options & OPENTB_PREFIX_MATCH)!=0,CUR_DIR,false,(def_opentb_options&OPENTB_RESTORE_COLUMN_WIDTHS)==0);
   treeWid._TreeEndUpdate(TREE_ROOT_INDEX);

   // Might need to update the selection if there is a filter
   if (filter._length()) {
      if (index > 0) {
         treeWid._TreeSetCurIndex(index);
         treeWid._TreeScroll(treeWid._TreeCurLineNumber());
         if (!treeWid._TreeUp()) treeWid._TreeDown();
         treeWid._TreeDeselectAll();
         treeWid._TreeSetCurIndex(index);
         treeWid._TreeSelectLine(index);
         treeWid._TreeRefresh();
      } else {
         int firstChild=treeWid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         if (firstChild>0) {
            // When type c:\path\, don't select the type line.
            if (last_char(filter)==FILESEP) {
               treeWid._TreeDeselectAll();
               treeWid._TreeSetCurIndex(firstChild);
               //treeWid._TreeSelectLine(firstChild);
               treeWid._TreeRefresh();
            } else {
               treeWid._TreeSetCurIndex(firstChild);
               treeWid._TreeScroll(treeWid._TreeCurLineNumber());
               if (!treeWid._TreeUp()) treeWid._TreeDown();
               treeWid._TreeDeselectAll();
               treeWid._TreeSetCurIndex(firstChild);
               treeWid._TreeSelectLine(firstChild);
               treeWid._TreeRefresh();
            }
         }
      }
   }
   p_window_id = origWid;
}

/**
 * Refreshes the list of files on disk. Does not repopulate the 
 * file tree. 
 */
static void rescanFilesOnDisk()
{
   _str currentDir = getCurrentFilesOnDiskDirectory();
   if(currentDir == "") {
      currentDir = getcwd();
   }
   FileListManager_RefreshDiskFiles(getFileListManagerHandle(), currentDir, doShowHiddenFiles());
}

/**
 * Refreshes the list of files on disk, and repopulates the file
 * tree, but only if the user has opted to display open buffers. 
 * This is on a timer for use in callback functions. 
 */
static void maybeRefreshFilesOnDisk(){
   // Don't bother if the window isn't open
   treeWid := getFileTree();
   if (treeWid <= 0) return;
   // Don't bother if we've already been asked to refresh
   // disk files/directories
   int * timer = getPointerToRefreshTimer();
   if (_timer_is_valid(*timer)) {
      if (((timer_refresh_flags & OTBFO_DIR_ON_DISK) != 0) ||
          ((timer_refresh_flags & OTBFO_FILE_ON_DISK) != 0)) return;
   }
   timer_refresh_flags |= OTBFO_FILE_ON_DISK;
   if(force_timer_delay == false) {
      startRefreshTimer();
   }
}

/**
 * Refreshes the list of currently open files. Does not 
 * repopulate the file tree. 
 */
static void rescanOpenFiles()
{
   FileListManager_RefreshOpenFiles(getFileListManagerHandle());
}

/**
 * Refreshes the list of currently open files, and repopulates 
 * the file tree. 
 */
static void refreshOpenFiles(){
   rescanOpenFiles();
   refreshFileTree('refreshOpenFiles');
}

/**
 * Refreshes the list of currently open files, and repopulates 
 * the file tree, but only if the user has opted to display open 
 * buffers. This is on a timer for use in callback functions.
 */
static void maybeRefreshOpenFiles(_str fileClosedPath = ''){
    // Don't bother if the window isn't open
    treeWid := getFileTree();
    if (treeWid <= 0) return;

    if (fileClosedPath :!= '') {
        /* Even if we're not going to do a full refresh
        of the open files, see if the file that was just
        closed does exist in the list. If so, change the
        document icon back to the "plain" variant.
        */
        _str fileName = _strip_filename(fileClosedPath, 'P');
        int foundEntry = treeWid._TreeSearch(TREE_ROOT_INDEX, fileName, 'PT');
        if (foundEntry > TREE_ROOT_INDEX) {
            int showChildren, bmpIdx1, bmpIdx2, moreFlags;
            treeWid._TreeGetInfo(foundEntry, showChildren, bmpIdx1, bmpIdx2, moreFlags);
            if (bmpIdx1 == _pic_otb_file_disk_open) {
                bmpIdx1 = bmpIdx2 = _pic_file;
                treeWid._TreeSetInfo(foundEntry, showChildren, bmpIdx1, bmpIdx2, moreFlags);
            }
        }
    }

    // Don't bother if the user doesn't want to display buffers
    if ((def_opentb_views & OTBFO_OPEN_FILE) == 0) {

        return;
    }

    // Don't bother if we've already been asked to refresh
    // open files
    int * timer = getPointerToRefreshTimer();
    if (_timer_is_valid(*timer)) {
        if ((timer_refresh_flags & OTBFO_OPEN_FILE) != 0) return;
    }
    timer_refresh_flags |= OTBFO_OPEN_FILE;
    if (force_timer_delay == false) {
        startRefreshTimer();
    }
}

/**
 * Refresh the list of file open history (MDI menu listing). 
 * Does not repopulates the file tree. 
 */
static void rescanHistoryFiles()
{
   FileListManager_RefreshFileHistory(getFileListManagerHandle());
}

/**
 * Refresh the list of file open history (MDI menu listing), and
 * repopulates the file tree.
 */
static void refreshHistoryFiles(){
   rescanHistoryFiles();
   refreshFileTree('refreshHistoryFiles');
}

/**
 * Refresh the list of file open history (MDI menu listing), and
 * repopulates the file tree, but only if user has chosen to 
 * display file history entries. This is on a timer for use in 
 * callback functions. 
 */
static void maybeRefreshHistoryFiles(){
   // Don't bother if the window isn't open
   treeWid := getFileTree();
   if (treeWid <= 0) return;

   // Don't bother if the user doesn't want to display history files
   if ((def_opentb_views & OTBFO_HISTORY_FILE) == 0) return;

   // Don't bother if we've already been asked to refresh
   // the file open history
   int * timer = getPointerToRefreshTimer();
   if (_timer_is_valid(*timer)) {
      if ((timer_refresh_flags & OTBFO_HISTORY_FILE) != 0) return;
   }
   timer_refresh_flags |= OTBFO_HISTORY_FILE;
   if(force_timer_delay == false) {
      startRefreshTimer();
   }
}

/**
 * Used by open tool window and workspace(files) tool window.
 * 
 * Refreshes the list of files in the current workspace. Does 
 * not repopulates the file tree.
 */
static void rescanWorkspaceFiles()
{
   FileListManager_RefreshWorkspaceFiles(getFileListManagerHandle(), force_refresh_workspace);
   force_refresh_workspace = false;
}

/**
 * Refreshes the list of files in the current workspace, and 
 * repopulates the file tree 
 */
static void refreshWorkspaceFiles()
{
   rescanWorkspaceFiles();
   if (isUpdateImmediate())
      refreshFileTree('refreshWorkspaceFiles');
}

/**
 * Refreshes the list of files in the current workspace, and 
 * repopulates the file tree, but only if the user has chosen 
 * that option. This is on a timer for use in callback 
 * functions. 
 */
void _maybeRefreshWorkspaceFiles()
{
   // Don't bother if the toolbar isn't open
   treeWid := getFileTree();
   if (treeWid <= 0) return;

   // Don't bother if the user doesn't want to display workspace files
   if ((def_opentb_views & OTBFO_PROJECT_FILE) == 0) return;

   // Don't bother if we've already been asked to refresh
   // project and/or workspace files
   int * timer = getPointerToRefreshTimer();
   if (_timer_is_valid(*timer)) {
      if (((timer_refresh_flags & OTBFO_PROJECT_FILE) != 0) ||
          ((timer_refresh_flags & OTBFO_WORKSPACE_FILE) != 0)) return;
   }
   timer_refresh_flags |= OTBFO_PROJECT_FILE;
   if(force_timer_delay == false) {
      startRefreshTimer();
   }
}

static void SuspendRefreshTimer(){
   force_timer_delay = true;
}

static void ResumeRefreshTimer(){
   force_timer_delay = false;
   if(timer_refresh_flags != 0) {
      startRefreshTimer();
   }
}

/**
 * Retrieves the directory that is currently being shown in the file tree.  This 
 * may differ from the directory selected in the directory tree if a path has 
 * been entered into the file name filter. 
 * 
 * @return           directory path to show
 */
static _str getCurrentFilesOnDiskDirectory()
{
   _str curFilesOnDiskDir = '';
   int filenameLabel = getFileNameLabel();
   if(filenameLabel) {
      curFilesOnDiskDir = filenameLabel.p_user;
   }
   if (curFilesOnDiskDir == ''){
      int opencdLabel = getOpenCDLabel();
      if(opencdLabel) {
         curFilesOnDiskDir = opencdLabel.p_user;
      }
   }
   if(curFilesOnDiskDir == '') {
      curFilesOnDiskDir = getcwd();
   }
   return curFilesOnDiskDir;
}

/**
 * Forces a refresh of the explorer tree
 */
static void refreshExplorerTree()
{
   _explorer_tree._set_current_path(_explorer_tree._get_current_path(), true, doShowHiddenFiles(), (def_opentb_options & OPENTB_SYNC_DIRECTORY) != 0);
}

void _explorer_tree.on_create(){
   _explorer_tree._set_cwd_callback(updateFileTreeDirectoryImmediate);
}

void _file_tree.on_create()
{
   // let's wait on the resizing - we'll get all of that out of the way in a minute
   OPEN_TB_RESIZING = true;

   CUR_FILTER = CUR_FILES_OF_TYPE = '';
   _clear_button.p_enabled = _new_file_button.p_enabled = (_file_name_filter.p_text != "");
   CUR_TOTAL_FILTER = null;
   FileListManager_SetExtensionFilter(getFileListManagerHandle(), null);

   _SetDialogInfoHt(OPEN_TB_REFRESH_TIMER, -1, _file_tree.p_window_id);
   _SetDialogInfoHt(OPEN_TB_FILE_TABLE, null, _file_tree.p_window_id);

   CURRENT_VIEWS = 0;
   CUR_FILES_ON_DISK_DIR = '';

   width := p_width;

   _file_tree._TreeSetColButtonInfo(0, floor(0.4 * width), 0, 0, "Name");
   _file_tree._TreeSetColButtonInfo(1, floor(0.6 * width), TREE_BUTTON_IS_FILENAME, 0, "Path");

   COLUMN_RESIZING = true;
   _file_tree._TreeRetrieveColButtonInfo(true);
   COLUMN_RESIZING = false;

   _SetDialogInfoHt(OPEN_TB_POSITION_TABLE, null, _file_tree.p_window_id);
   typeless (*pposTable):[] = getPointerToPositionTable();
   (*pposTable):["_formW"]= p_active_form.p_width;
   (*pposTable):["_formH"]= p_active_form.p_height;
   (*pposTable):["_file_treeW"]= _file_tree.p_width;
   (*pposTable):["_file_treeH"]= _file_tree.p_height;
   (*pposTable):["lastOrientation"]= 'H';

   retrieveValue := _expand_dir_panel_button._retrieve_value();
   if (retrieveValue != null && isinteger(retrieveValue)) _expand_dir_panel_button.p_value = retrieveValue;

   _options_link.p_mouse_pointer = MP_HAND;

   _str path;
   path=_explorer_tree._get_current_path();
   _set_opencd2(path, true);
   CUR_DIR = path;

   int wid;
   wid= p_window_id;
   p_window_id=_files_of_type;
   _str text, tp;
   text= def_file_types;
   for (;;) {
      parse text with tp ',' text;
      if (tp== "") break;
      parse tp with . '(' tp ')' .;
      _lbadd_item(tp);
   }
   p_window_id=wid;

   _files_of_type._set_sel(1,length(_files_of_type.p_text)+1);

   rescanWorkspaceFiles();
   rescanOpenFiles();
   rescanHistoryFiles();
   rescanFilesOnDisk();
   refreshFileTree('refreshFilesOnDisk');

   clear_message();
   ignore_change_cd_callback = false;

   OPEN_TB_RESIZING = false;
}

/**
 * Refilter files when the filter changes
 */
void _file_name_filter.on_change(int reason=CHANGE_OTHER)
{
   _clear_button.p_enabled = _new_file_button.p_enabled = (_file_name_filter.p_text != "");
   if (CUR_ALL_FILTER_TEXT == null || CUR_ALL_FILTER_TEXT :!= p_text) {
      // Update the tree right away, unless some other event is
      // holding up tree updates
      if(force_timer_delay == false) {
         checkFileNameFilter();
         refreshFileTree('_file_name_filter.on_change');
      } else{
         timer_refresh_flags |= OTBFO_FILE_ON_DISK;
      }
   }
}

/**
 * 
 * 
 * 
 * @return           true if we need to do a new filter of the tree, false 
 *                   otherwise
 */
static boolean checkFileNameFilter(boolean force = false)
{
   newFilesOnDiskDir := CUR_FILES_ON_DISK_DIR;
   newFilter := CUR_FILTER;

   // we have a file sep, so this might be a path
   if (CUR_ALL_FILTER_TEXT == null) CUR_ALL_FILTER_TEXT == '';

   filterText := strip(_file_name_filter.p_text, 'B', '"');

   // look for the last filesep character
   newLastFilesep := lastpos(FILESEP, filterText);
   newBeforeFilesep := substr(filterText, 1, newLastFilesep);

   // see if there are any wild cards in the directory part...
   wildCardsInDir := (pos('*', newBeforeFilesep) != 0);

   newFilter = filterText;
   if (!newLastFilesep || wildCardsInDir) {
      // there is no file sep, so this is just a plain filter
      newFilesOnDiskDir = "";
   } else {
   
      oldLastFilesep := lastpos(FILESEP, CUR_ALL_FILTER_TEXT);
      oldBeforeFilesep := substr(CUR_ALL_FILTER_TEXT, 1, oldLastFilesep);
      
      // see if the things before them match
      if (newBeforeFilesep != oldBeforeFilesep || force) {
         // we need to figure out our new directory
         absolutePath := checkPathForDoubleDots(newBeforeFilesep);
#if __UNIX__
         if (def_unix_expansion) absolutePath = _unix_expansion(absolutePath);
#endif

         // 12/8/2011 - We can't simply use absolute here because the partial
         // relative path typed into the filter might not be relative to the
         // actual directory of the editor.  If the user does not have 
         // OPENTB_SYNC_DIRECTORY on and has double clicked to change dirs, 
         // typing "relpath/" followed by enter will not work because relpath is
         // relative to what is displayed in the tool window but not the editor's
         // current directory on disk.  Use the caption above the directories.
         // This will be set correctly
         newFilesOnDiskDir = absolute(absolutePath,_opencd.p_caption);
      } 

   }

   // refresh the listing of files on disk with our new directory
   doFreshFilter := false;
   if (newFilesOnDiskDir != CUR_FILES_ON_DISK_DIR) {
      CUR_FILES_ON_DISK_DIR = newFilesOnDiskDir;
      rescanFilesOnDisk();
      doFreshFilter = true;
   }

   if (newFilter :!= CUR_FILTER) {
      CUR_FILTER = newFilter;
      doFreshFilter = true;
   }

   CUR_ALL_FILTER_TEXT = filterText;

   return doFreshFilter;
}

/**
 * Checks a path for any dirNameFILESEP..FILESEP combinations.  If one is found,
 * adjusts the path by removing the .. and the preceding directory name. 
 * 
 * @param path          path to check
 * 
 * @return              adjusted path
 */
static _str checkPathForDoubleDots(_str path)
{
   regexFilesep := FILESEP;
#if FILESEP == '\'
   regexFilesep :+= FILESEP;        // double it for the regex
#endif

   dotRegex := regexFilesep'..'regexFilesep;
   wholeRegex := regexFilesep'[~'regexFilesep']*'dotRegex;

   ddPos := pos(wholeRegex, path, 1, 'R');
   while (ddPos > 0) {
      // get the stuff around our /dir/../
      before := substr(path, 1, ddPos);
      after := substr(path, ddPos + 1);

      ddPos = pos(dotRegex, after, 1, 'R') + 4;
      after = substr(after, ddPos);

      // replace it with a filesep
      path = before :+ after;
      ddPos = pos(wholeRegex, path, 1, 'R');
   }

   return path;
}

static void startRefreshTimer()
{
   int * timer = getPointerToRefreshTimer();
   if (_timer_is_valid(*timer)) {
      _kill_timer(*timer);
      *timer = -1;
   }
   *timer = _set_timer(200, _refreshTimerProc);
}

static void maybeCheckViews()
{
   if (_file_name_filter.p_text != '') checkViews();
}

void checkViews()
{
   if (def_opentb_views != CURRENT_VIEWS) {
      
      viewsToRemove := 0;

      updateSort := false;

      curProject := (CURRENT_VIEWS & OTBFO_PROJECT_FILE) != 0;
      shouldProject := (def_opentb_views & OTBFO_PROJECT_FILE) != 0;
      if (curProject && !shouldProject) {
         // remove these
         viewsToRemove |= (OTBFO_PROJECT_FILE | OTBFO_WORKSPACE_FILE);
         updateSort = true;
      } else if (!curProject && shouldProject) {
         // add these
         rescanWorkspaceFiles();
      }

      curHistory := (CURRENT_VIEWS & OTBFO_HISTORY_FILE) != 0;
      shouldHistory := (def_opentb_views & OTBFO_HISTORY_FILE) != 0;
      if (curHistory && !shouldHistory) {
         // remove these
         viewsToRemove |= OTBFO_HISTORY_FILE;
         updateSort = true;
      } else if (!curHistory && shouldHistory) {
         // add these
         rescanHistoryFiles();
         CURRENT_VIEWS |= OTBFO_HISTORY_FILE;
         updateSort = true;
      }

      curOpen := (CURRENT_VIEWS & OTBFO_OPEN_FILE) != 0;
      shouldOpen := (def_opentb_views & OTBFO_OPEN_FILE) != 0;
      if (curOpen && !shouldOpen) {
         // remove these
         viewsToRemove |= OTBFO_OPEN_FILE;
         updateSort = true;
      } else if (!curOpen && shouldOpen) {
         // add these
         rescanOpenFiles();
         CURRENT_VIEWS |= OTBFO_OPEN_FILE;
         updateSort = true;
      }

      if (viewsToRemove != 0) {
         removeViews(viewsToRemove);
         updateSort = true;
      }

      if (updateSort) {
         refreshFileTree('checkViews');
      }
   }
}

void removeViews(int views)
{
   CURRENT_VIEWS &= ~views;
}

void _refreshTimerProc(){
   // Kill the timer once it's been hit
   int * timer = getPointerToRefreshTimer();
   if (timer == null) return;

   if (_timer_is_valid(*timer)) {
      _kill_timer(*timer);
      *timer = -1;
   }
   // Don't bother if there are no origin sets
   // that need updating
   if(timer_refresh_flags == 0)
      return;
   
   // Now look at the flags and update the File List Manager's sets
   int refreshFlags = timer_refresh_flags;
   int remainToRefresh = refreshFlags;
   _str filter = getFileNameFilter();

   if(refreshFlags & OTBFO_OPEN_FILE) {
      rescanOpenFiles();
      if(filter == '') {
         // If rescanning open files, but no filter is set,
         // the mark this as potentially complete
         remainToRefresh &= ~(OTBFO_OPEN_FILE);
      }
   }

   if(refreshFlags & OTBFO_HISTORY_FILE) {
      rescanHistoryFiles();
      if(filter == '') {
         // If rescanning history files, but no filter is set,
         // the mark this as potentially complete
         remainToRefresh &= ~(OTBFO_HISTORY_FILE);
      }
   }

   if((refreshFlags & OTBFO_DIR_ON_DISK) ||
      (refreshFlags & OTBFO_FILE_ON_DISK)) {
      rescanFilesOnDisk();
   }
   timer_refresh_flags = 0;
   // If we've only rescanned history and/or open files, and there is
   // no file name filter set, then this refresh doesn't need to trigger
   // a redraw of the tree. But the list of files will be up-to-date if
   // and when a filter is entered.
   if(remainToRefresh > 0) {
      refreshFileTree('_refreshTimerProc 'refreshFlags);
   }
}

/*
void _filterOpenTBTree()
{
   // filtering is on a timer - KILL IT!
   int * timer = getPointerToRefreshTimer();
   if (_timer_is_valid(*timer)) {
      _kill_timer(*timer);
      *timer = -1;
   }

   treeWid := getFileTree();
   if (treeWid > 0) {
      origWid := p_window_id;
      p_window_id = treeWid;
   
      checkFileNameFilter();
      checkViews();
      filter := buildFilterRegex();
      if (filter != '') treeWid._FilterTreeControl(filter, false, true, 'R');
   
      // do we pick something?
      filter = CUR_FILTER;
      if (filter != '') {
//#if FILESEP == '\'
//         filter = stranslate(filter, '\', '\\');
//#endif
         file_filter:=absolute(filter);
         file_filter=strip_filename(file_filter,'P')"\t"strip_filename(file_filter,'N');

         // Search for a disk file matching what user has typed
         index := treeWid._TreeSearch(TREE_ROOT_INDEX, file_filter, _fpos_case);
         if (index<0) {
            // Search for a file whose name part exactly matches what user has typed
            index = treeWid._TreeSearch(TREE_ROOT_INDEX, filter\t, 'P'_fpos_case);
            if (index < 0 && (def_opentb_options & OPENTB_PREFIX_MATCH) == 0) {
               // Select the first prefix match for what user has typed
               index= treeWid._TreeSearch(TREE_ROOT_INDEX, filter, 'PI');
            } 
         }

         if (index > 0) {
            
            treeWid._TreeSetCurIndex(index);
            treeWid._TreeScroll(treeWid._TreeCurLineNumber());
            if (!treeWid._TreeUp()) treeWid._TreeDown();
            _TreeDeselectAll();
            _TreeSetCurIndex(index);
            _TreeSelectLine(index);
         }
      } else {
         treeWid._TreeTop();
      }
      treeWid._TreeRefresh();

      p_window_id = origWid;
   }
}
*/ 
 
/*
static _str escapeFilterRegexChars(_str filter, _str regexFilesep)
{
   // slickedit regex chars 
   reChars := '*$+#@(){}~^[]|\:';
   for (i := 1;;) {
      i = verify(filter, reChars, 'm', i);
      if (!i) break;

      // see if the user is escaping a single wildcard character
      ch := substr(filter, i, 1);
      if (ch == '\' && length(filter) >= i + 1) {
         // get the next character - maybe a wild card
         ch2 := substr(filter, i + 1, 1);
#if __UNIX__
         // all these wild card characters are allowed to be in filenames on *NIX
         if (ch2 == '?' || ch2 == '*' || ch2 == '#') {
            i += 2;
            continue;
         }
#else
         // only the # is allowed in a filename on non-*NIX
         if (ch2 == '#') {
            i += 2;
            continue;
         }
#endif
      } else if (ch == '*') {
         // wildcards = change it to (any char except a filesep)
         filter = substr(filter, 1, i - 1) :+ '[~'regexFilesep']' :+ substr(filter, i);
         i += (4 + length(regexFilesep));
         continue;
      } else if (ch == '#') {
         // wildcards - replace it with a ':d' - single digit
         filter = substr(filter, 1, i - 1) :+ ':d' :+ substr(filter, i + 1);
         i += 2;
         continue;
      }

      filter = substr(filter, 1, i - 1) :+ '\' :+ substr(filter, i);
      i += 2;
   }

   return filter;
}
*/ 

/*
_str buildFilterRegex()
{
   // this is complicated!
   regexFilesep := FILESEP;
#if FILESEP == '\'
   regexFilesep :+= FILESEP;        // double it for the regex
#endif

   filesOfTypeFilter := stranslate(CUR_FILES_OF_TYPE, '|', ';');
   if (filesOfTypeFilter == ALLFILES_RE) filesOfTypeFilter = '';
   filesOfTypeFilter = stranslate(filesOfTypeFilter, '', '*.');

   // do some mods
   filter := CUR_FILTER;
   curDirFilter := '';
   if (filter != '') {

      // see if we are looking for file extensions twice
      if (filesOfTypeFilter != '') {
         // if the filter ends with a ., then just strip it off, please
         if (last_char(filter) == '.') filter = substr(filter, 1, length(filter) - 1);
         else if (endsWith(filter, filesOfTypeFilter, true, 'R')) {
            // if the files of type is included in the filter, then we 
            // don't worry so much about that
            filesOfTypeFilter = '';
         }
      }

      // find the last file separator in here
      lastFilesep := lastpos(regexFilesep, filter, "", 'R');
      afterFilesep := filter;
      if (lastFilesep) {
         // we only search for the last part in the current directory
         afterFilesep = substr(filter, lastFilesep + 1);
      }

      // make sure we're not making regexes that we don't know about
      curDirFilter = escapeFilterRegexChars(getCurrentFilesOnDiskDirectory() :+ afterFilesep, regexFilesep);
      filter = escapeFilterRegexChars(filter, regexFilesep);

      // check for preview matching...
      if ((def_opentb_options & OPENTB_PREFIX_MATCH) == 0) {
         filter = '?*'filter;
      } else {
         filter = '?*'regexFilesep :+ filter;
      }

      // say that we want this part to be the last part of the path - no file separators afterwards...
      if (filter != '') filter :+= '[~'regexFilesep']*';
      if (curDirFilter != '') if (curDirFilter != '') curDirFilter :+= '[~'regexFilesep']*';

   }

   totalFilter := '';
   if (filter != '' && filesOfTypeFilter != '') {
      // match directories in the current dir to just the filter part
      totalFilter = '(^:c*'OTB_FILE_ORIGIN_DISK_DIR':c*\,:d#\,'filter'$)';
      // match files in everything else with the whole filter and the files of type
      totalFilter :+= '|(^:c*\,:d#\,'filter'.('filesOfTypeFilter')$)';

      // search the current directory for this stuff
      if (curDirFilter != '') {
         // match directories in the current dir with the last part of the filter
         totalFilter :+= '|(^:c*'OTB_FILE_ORIGIN_DISK_DIR':c*\,:d#\,'curDirFilter'$)';
         // match files in the current dir with the last part of the filter plus the files of type
         totalFilter :+= '|(^:c*('OTB_FILE_ORIGIN_DISK_DIR'|'OTB_FILE_ORIGIN_DISK_FILE'):c*\,:d#\,'curDirFilter'.('filesOfTypeFilter')$)';
      }
   } else if (filter != '') {
      // match all files with the whole filter
      totalFilter = '(^:c*\,:d#\,'filter'$)';
      if (curDirFilter != '') {
         // match files/directories in the current directory with the last part of the filter
         totalFilter :+= '|(^:c*('OTB_FILE_ORIGIN_DISK_DIR'|'OTB_FILE_ORIGIN_DISK_FILE'):c*\,:d#\,'curDirFilter'$)';
      }
   } else if (filesOfTypeFilter != '') {
      totalFilter = '(^:c*'OTB_FILE_ORIGIN_DISK_DIR':c*\,:d#\,?*$)|(^:c*('OTB_FILE_ORIGIN_DISK_DIR'|'OTB_FILE_ORIGIN_DISK_FILE'):c*\,:d#\,?*.('filesOfTypeFilter')$)';
   } else {
      // here we just filter for the files in the current directory and the dirs
      totalFilter = '^:c*('OTB_FILE_ORIGIN_DISK_DIR'|'OTB_FILE_ORIGIN_DISK_FILE'):c*\,:d#\,?*$';
   }

   CUR_TOTAL_FILTER = totalFilter;

   return totalFilter;
}
*/

void _tbopen_form.'F5'()
{
   refreshOpenToolWindow(true);
}

/**
 * Forces a refresh of both the file tree and the explorer tree
 * (directory view), after updating the list of disk files
 */
static void refreshOpenToolWindow(boolean checkForWorkspaceRefresh = false)
{
   rescanFilesOnDisk();
   if (checkForWorkspaceRefresh && checkFilterView()) {
      workspace_refresh();  // refresh all workspace views
      return;
   }

   refreshFileTree('refreshFilesOnDisk');
   refreshExplorerTree();
}

static int open_file(_str file, int bufId, _str editOptions)
{
   if (bufId) {
      // open the existing file
      editOptions :+= ' +bi';
      return edit(strip(editOptions)" "bufId);
   } else {
      // just open the regular file on disk
      return edit(strip(editOptions)" "maybe_quote_filename(file),EDIT_DEFAULT_FLAGS);
   }
}

static boolean isTruncatedWarning(int treeIndex)
{
   _TreeGetInfo(treeIndex,auto state,auto bm1,auto bm2,auto nodeFlags);
   return((nodeFlags&TREENODE_FORCECOLOR)!=0);
}

static boolean isSelectedFileTreeItemDirectory(int treeIndex)
{
   if ( isTruncatedWarning(treeIndex) ) return false;
   // 11/14/2011
   // User info is set to 1 in PopulateTreeSorted if this is a directory, 0 if it
   // is a file
   info := _TreeGetUserInfo(treeIndex);
   boolean isDirectory = (info==1);

   return isDirectory;
}

static int getBufId(int index)
{
   // The current buffer ID  for an already open file is
   // assumed to be stashed in the tree item's user info.
   // Just return zero for now, unless we deem this worthy
   // of restoration.
   /*
   _str info = _TreeGetUserInfo(index);
   parse info with . ',' auto bufId ',' .;

   return (int)bufId;
   */
   return 0;
}

static _str getFilePath(int treeIndex)
{
   _str file, path;
   parse _TreeGetCaption(treeIndex) with file \t path;
   return concat_path_and_file(path, file);
}

static void openFileTreeFile(int treeIndex)
{
   // make double sure this is a file, not a directory
   if (isSelectedFileTreeItemDirectory(treeIndex)) return;

   filePath := getFilePath(treeIndex);
   bufId := getBufId(treeIndex);

   editOptions := '';
   open_file(filePath, (int)bufId, editOptions);
}

static void openFileTreeDirectory(int treeIndex)
{
   // make double sure this is a directory, not a file
   if (!isSelectedFileTreeItemDirectory(treeIndex)) return;

   _str file, path;
   parse _TreeGetCaption(treeIndex) with file \t path;
   if (path == '' && file == '..') {
      openFileTreeUpDirectory();
   } else {
      _str dirPath = concat_path_and_file(path, file);
      // just change the directory
      _explorer_tree._set_current_path(dirPath, 1, doShowHiddenFiles(), (def_opentb_options & OPENTB_SYNC_DIRECTORY) != 0);
      updateFileTreeDirectory(_explorer_tree._get_current_path(), true);
      _explorer_tree.p_redraw = true;
      _explorer_tree._TreeRefresh();
   }
}

static void openFileTreeUpDirectory()
{
   _str currDir = concat_path_and_file(CUR_DIR, '..');
   _explorer_tree._set_current_path(currDir, 1, doShowHiddenFiles(), (def_opentb_options & OPENTB_SYNC_DIRECTORY) != 0);
   updateFileTreeDirectory(_explorer_tree._get_current_path(), true);
   _explorer_tree.p_redraw = true;
   _explorer_tree._TreeRefresh();
}

// Callback handler for "cd" events. Do a delayed update
// of the file on disk
static void updateFileTreeDirectoryImmediate(_str path)
{
   updateFileTreeDirectory(path, true);
   if((def_opentb_options & OPENTB_SYNC_DIRECTORY) != 0) {
      chdir(path, 1);
      call_list("_cd_",path);
   }
}

// Handle a change in the current directory. If immediateUpdate, then repopulate
// the file tree right away. 
static void updateFileTreeDirectory(_str path, boolean immediateUpdate = false)
{
   CUR_DIR = path;
   _set_opencd2(path, true);
   // check this filter stuff, we may need to change 
   // if the directory changed...
   checkFileNameFilter(true);
   if((immediateUpdate == true) && (force_timer_delay == false)) {
      // Repopulate the file tree without delay. This was probably requested
      // from the user double-clicking a directory entry in the file tree.
      rescanFilesOnDisk();
      refreshFileTree('refreshFilesOnDisk');
   } else{
      // Queue the update of the file tree. Other changes
      // may be pending (like a workspace opening). Most likely
      // this request came as a side-effect of opening/closing
      // a workspace.
      timer_refresh_flags |= (OTBFO_DIR_ON_DISK | OTBFO_FILE_ON_DISK);
      maybeRefreshFilesOnDisk();
   }
}

static _str getLastOrientation()
{
   typeless * pposTable = getPointerToPositionTable();
   return (*pposTable):['lastOrientation'];
}

void _expand_dir_panel_button.lbutton_up()
{
   expandCollapseDirectoryPanel(p_value != 0);

   p_active_form.call_event(p_active_form, ON_RESIZE);

}

static void expandCollapseDirectoryPanel(boolean expand)
{
   if (DIR_PANEL_EXPANDED == expand) return;

   if (expand) {
      _explorer_tree.p_visible = true;

      if (getLastOrientation() == 'H') {
         _grabbar_vert.p_visible = true;
         _grabbar_horz.p_visible = false;
      } else {
         _grabbar_horz.p_visible = true;
         _grabbar_vert.p_visible = false;
      }

      _expand_dir_panel_button.p_value = 1;
   } else {
      _dir_frame.p_height = _opencd.p_height + (int)(1.5 * _opencd.p_y); 
      _explorer_tree.p_visible = false;
      _grabbar_horz.p_visible = _grabbar_vert.p_visible = false;

      _expand_dir_panel_button.p_value = 0;
   }

   DIR_PANEL_EXPANDED = expand;
}

void _clear_button.lbutton_up()
{
   clearFileNameFilter();
}

static void clearFileNameFilter()
{
   _file_name_filter.p_text = '';
   _file_name_filter._begin_line();
}

void _browse_button.lbutton_up()
{
   browseForFile();
}

void browseForFile()
{
   treeWid := getFileTree();
   result := browse_open();

   if ((result != COMMAND_CANCELLED_RC) && (def_opentb_options & OPENTB_DISMISS_AFTER_SELECT)) {
      _tbDismiss(treeWid.p_parent, true);
   }
   // After cancelling the standard open dialog set the focus back to the toolbar.
   if (result == COMMAND_CANCELLED_RC && !tbIsWidDocked(p_active_form)) {
      // Note: This fix ONLY works for windows.
      activate_toolbar(OPEN_TB_FORM_NAME_STRING, '');
   }

}

void _new_file_button.lbutton_up()
{
   createNewFile();
}

static void createNewFile()
{
   // we want to make a brand new file using the name in the filter
   filename := CUR_FILTER;
   if (filename == '') return;

   // make it in the current directory
   //filename = '"'getCurrentFilesOnDiskDirectory() :+ filename'"';
   // Best to use the real current directory
   filename=maybe_quote_filename(filename);

   openTB := p_active_form;

   if ( def_unix_expansion ) {
      filename = _unix_expansion(filename);
   }

   edit(filename);

   if (def_opentb_options & OPENTB_DISMISS_AFTER_SELECT) {
      _tbDismiss(openTB, true);
   }
}

static _str GetCurrentOpenTBFilename()
{
    _nocheck _control _explorer_tree;
   _str path=_explorer_tree._get_current_path();
   _str filename=path:+_lbget_text();
   return(maybe_quote_filename(filename));
}

static void _set_opencd2(_str value, boolean shrinkToFit = false)
{
   _str start="";
   _str rest="";
   if (value=='') {
      value=getcwd();
   }
   value=absolute(value);

   value = _prepare_filename_for_menu(value);
   for (;;){
      if (_opencd._text_width(value)<=_explorer_tree.p_width) break;
      /* Remove a path */
      if (substr(value,1,2)=='\\') {
         _str server,share_name;
         parse value with '\\' server '\' share_name '\' rest ;
         start='\\' server '\' share_name;
         if (rest!='') {
            start=start:+FILESEP;
         }
      } else {
         start=substr(value,1,3);
         rest=substr(value,4);
      }
      // Just incase server share name is very long
      if (rest=='..' || rest=='') {   // Bug Fix
         value='';break;
      }
      for (;;) {
         _str path;
         parse rest with  path (FILESEP) rest ;
         if (rest=='') {
            rest='..';
            break;
         }
         if (path!='..') {
            rest='..':+FILESEP:+rest;
            break;
         }
      }
      value=start :+ rest;
   }

   // we might want to shrink this filename to fit stuff...
   if (shrinkToFit) {
      value = _ShrinkFilename(value, _opencd.p_width);
   }

   _opencd.p_caption=value;
}


_tbopen_form.on_load()
{
   // these grabbar positions are in line with the last size of the tool 
   // window.  when the tool window is restored, it is not yet that size.  
   // it won't be that size until the very end of the loading process.  
   // so if we restore these positions too early (i.e. in the on_create), 
   // they'll get screwed up as the resize tries to align them with the 
   // sizes as they are during the creation, not as they will be at the end 
   // of the load.  just trust me on this.

   retrieveValue := _grabbar_vert._retrieve_value();
   if (retrieveValue != null && isinteger(retrieveValue)) _grabbar_vert.p_x = retrieveValue;

   retrieveValue = _grabbar_horz._retrieve_value();
   if (retrieveValue != null && isinteger(retrieveValue)) _grabbar_horz.p_y = retrieveValue;
}

int def_opentb_orientation;

enum OpenTbOrientation {
   OTBO_AUTO,
   OTBO_HORIZONTAL,
   OTBO_VERTICAL,
};

//2:16pm 7/20/2000 Tested after move from project.e
static void resizeOpen(typeless * pposTable)
{
   int containerW=_dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   int containerH=_dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);

   // determine padding
   hPad := _filenameLabel.p_x;
   vPad := _filenameLabel.p_y;

   // determine the orientation (horizontal vs vertical)
   lastOrientation := (*pposTable):["lastOrientation"];
   orientation := lastOrientation;
   // maybe we have the orientation specified by the user
   if (def_opentb_orientation == OTBO_AUTO) {
      if ((p_width < p_height && p_width < TBOPEN_MINFORMWIDTH)) {
         orientation = 'V';
      } else if (p_width > (*pposTable):["_formW"]) {
         orientation = 'H';
      }
   } else if (def_opentb_orientation == OTBO_HORIZONTAL) {
      orientation = 'H';
   } else {
      orientation = 'V';
   }
   
   // show/hide the grabbars depending on the orientation
   if (DIR_PANEL_EXPANDED) {
      if (orientation == 'H') {
         _grabbar_vert.p_visible = true;
         _grabbar_horz.p_visible = false;
      } else {
         _grabbar_horz.p_visible = true;
         _grabbar_vert.p_visible = false;
      }
   }

   if (orientation == 'V') {
      int availW = containerW - 2 * hPad;

      heightDiff := containerH - (_files_of_type.p_y + vPad + _files_of_type.p_height);

      // adjust the stuff at the bottom first...it's easy
      _files_of_type.p_x = _files_of_type_label.p_x = hPad;
      _files_of_type.p_y =  containerH - _files_of_type.p_height - vPad;
      _files_of_type_label.p_y = _files_of_type.p_y - _files_of_type_label.p_height;
      _files_of_type.p_width = availW;

      _dir_frame.p_x = hPad;
      _dir_frame.p_width = availW;

      _grabbar_horz.p_width = availW;
      _grabbar_horz.p_x = vPad;

      _file_tree.p_width = availW;
      _options_link.p_x = (_file_tree.p_x + (_file_tree.p_width - _options_link.p_width));

      _browse_button.p_x = (_file_tree.p_x + (_file_tree.p_width - _browse_button.p_width));
      _new_file_button.p_x = _browse_button.p_x - _new_file_button.p_width;
      _clear_button.p_x = _new_file_button.p_x - _clear_button.p_width;
      _file_name_filter.p_width = _clear_button.p_x - (_file_name_filter.p_x + hPad);

      // set these to the current value, so if we don't change them then nothing special happens
      grabbarMin := _grabbar_horz.p_y;
      grabbarMax := _grabbar_horz.p_y;

      // we don't want to adjust the grabbars when those are the things that are causing the resize
      adjustGrabbars := (heightDiff != 0);

      if (adjustGrabbars) {
         getGrabbarMinMax(grabbarMin, grabbarMax, orientation);
         if (grabbarMax < grabbarMin) expandCollapseDirectoryPanel(false);
      }

      if (DIR_PANEL_EXPANDED) {
         if (adjustGrabbars) {
            if (_grabbar_horz.p_y < grabbarMin) {
               _grabbar_horz.p_y = grabbarMin;
            } else if (_grabbar_horz.p_y > grabbarMax) {
               _grabbar_horz.p_y = grabbarMax;
            }
         }

         _file_tree.p_height = _grabbar_horz.p_y - _file_tree.p_y - (vPad intdiv 2);

         _dir_frame.p_y = _grabbar_horz.p_y + _grabbar_horz.p_height;
         _dir_frame.p_height = _files_of_type_label.p_y - _dir_frame.p_y - vPad;
      } else {
         _dir_frame.p_y = _files_of_type_label.p_y - _dir_frame.p_height - vPad;
         _file_tree.p_height = _dir_frame.p_y - _file_tree.p_y - vPad;

      }
   } else {
      // horizontal orientation here

      _files_of_type.p_visible = _files_of_type_label.p_visible = _dir_frame.p_visible = true;

      int availH = containerH - 
         (3 * vPad) - 
         _files_of_type_label.p_height - 
         _files_of_type.p_height;

      _grabbar_vert.p_height = availH;
      _grabbar_vert.p_y = vPad;

      // this spans the whole bottom
      _files_of_type.p_width = containerW - (2 * hPad);
      _files_of_type.p_x = _files_of_type_label.p_x = _file_tree.p_x;

      _files_of_type.p_y =  containerH - (_files_of_type.p_height + vPad);
      _files_of_type_label.p_y = _files_of_type.p_y - (_files_of_type_label.p_height + vPad);

      _file_tree.p_height = _files_of_type_label.p_y - (_file_tree.p_y + vPad);

      _dir_frame.p_y = vPad;
      _dir_frame.p_x = _grabbar_vert.p_x + _grabbar_vert.p_width + hPad;

      _browse_button.p_x = _grabbar_vert.p_x - (_browse_button.p_width + hPad);
      _new_file_button.p_x = _browse_button.p_x - _new_file_button.p_width;
      _clear_button.p_x = _new_file_button.p_x - _clear_button.p_width;
      _file_name_filter.p_width = _clear_button.p_x - (_file_name_filter.p_x + hPad);

      _options_link.p_x = _grabbar_vert.p_x - (_options_link.p_width + hPad);

      if (DIR_PANEL_EXPANDED) {
         _dir_frame.p_height = availH - _dir_frame.p_y;
         _file_tree.p_width = _grabbar_vert.p_x - (_file_tree.p_x + hPad);

         _dir_frame.p_width = containerW - hPad - _dir_frame.p_x;
      } else {
         _file_tree.p_width = containerW - (2 * hPad);
         _dir_frame.p_width = containerW - hPad - _dir_frame.p_x;
      }
   }

   // Update current directory label:
   _set_opencd2(CUR_DIR, true);

   (*pposTable):["lastOrientation"] = orientation;

   resizeDirFrame();
}

static void resizeDirFrame()
{
   padding := _explorer_tree.p_x;
   _opencd.p_width = _dir_frame.p_width - (padding * 3) - _expand_dir_panel_button.p_width;

   // only do resizing inside if this is expanded
   if (_expand_dir_panel_button.p_value) {
      _explorer_tree.p_height = _dir_frame.p_height - padding - _explorer_tree.p_y;
      _opendrives_stub.p_width = _explorer_tree.p_width = _dir_frame.p_width - (padding * 2);
   }
}

void _tbopen_form.on_resize()
{
   if (OPEN_TB_RESIZING) return;

   OPEN_TB_RESIZING = true;

   typeless (*pposTable):[] = getPointerToPositionTable();
   if( 0==pposTable -> _indexin("formWH") ) {
      (*pposTable):["formWH"]= p_active_form.p_width:+" ":+p_active_form.p_height;
   }

   // Resize the form
   resizeOpen(pposTable);

   // Save form's new XYWH
   (*pposTable):["formWH"]=p_active_form.p_width:+" ":+p_active_form.p_height;

   OPEN_TB_RESIZING = false;
}

void _tbopen_form.on_destroy()
{
   // save the current value in files of type
   _append_retrieve( _files_of_type, _files_of_type.p_text, "_tbopen_form._files_of_type" );

   // save the columns...
   _file_tree._TreeAppendColButtonInfo(true, '_file_tree');

   // save the grabbar position
   _append_retrieve(_grabbar_horz, _grabbar_horz.p_y, "_tbopen_form._grabbar_horz" );
   _append_retrieve(_grabbar_vert, _grabbar_vert.p_x, "_tbopen_form._grabbar_vert" );

   // and the expand value
   _append_retrieve(_expand_dir_panel_button, _expand_dir_panel_button.p_value, '_tbopen_form._expand_dir_panel_button');

   /*
   int * timer = getPointerToRefreshTimer();
   if (_timer_is_valid(*timer)) {
      _kill_timer(*timer);
      *timer = -1;
   }
   */

   call_event(p_window_id,ON_DESTROY,'2');
}

static boolean gUseCDTBOpen=true;
boolean _use_cd_tbopen(int newval=-1)
{
   if (newval>-1) {
      gUseCDTBOpen=newval!=0;
   }
   return(gUseCDTBOpen);
}


/**
 * Call-list callback.
 * <p>
 * This function is called by the cd command. Here we update the
 * current directory on the Open tool window.
 */
void _cd_tbopen(_str path='')
{
   
   if ((def_opentb_options & OPENTB_SYNC_DIRECTORY) == 0) return;
   if( !_use_cd_tbopen() || ignore_change_cd_callback) {
      return;
   }

   // Update directory listing only if Open tool window is active
   int wid = _tbGetWid("_tbopen_form");
   if( wid!=0 ) {

      if( path=="" ) path=getcwd();

      mou_hour_glass(1);

      int orig_wid=p_window_id;
      p_window_id=wid;

      //_openfile_list._flfilename(result,'',1); // Refresh File list
      _nocheck _control _explorer_tree;
      _nocheck _control _file_name_filter;


      _maybe_append_filesep(path);
      _file_name_filter.p_text='';
      _file_name_filter._begin_line();
      CUR_FILES_ON_DISK_DIR=path;
      _explorer_tree._set_current_path(path,false, doShowHiddenFiles(), (def_opentb_options & OPENTB_SYNC_DIRECTORY) != 0);
      _file_name_filter.updateFileTreeDirectory(path);

      p_window_id=orig_wid;
      mou_hour_glass(0);
   }
}

/**
 * Update open file list only if it is active.
 */
//2:36pm 7/20/2000 Tested after move from project.e
static void openActivated()
{
   // If Open tool window is not active, do nothing
   if( !_tbIsActive("_tbopen_form") ) {
      return;
   }

   // Refresh Open tab:
   _cd_tbopen();
#if __UNIX__
   // openActivated() gets called when we dock/undock the toolbar so we need
   // to clear the message from _cd_tbopen()
   clear_message();
#endif
}

/*
   The ENTER causes VSE to reapply the wildcards in the
   _files_of_type text box.
*/
void _files_of_type.'ENTER'()
{
   if (p_visible) {
      call_event(p_window_id,last_event(),'2');
      return;
   }

   _str textFilter= _files_of_type.p_text;
   int wid= p_window_id;
   _str currPath=_opencd.p_caption;
   if (pos("/",textFilter) != 1 && currPath== "//") {
      textFilter= "//"textFilter;
   }

}

void _files_of_type.on_change(int reason)
{
   if (CUR_FILES_OF_TYPE != p_text) {
      CUR_FILES_OF_TYPE = p_text;
      _str exts[];
      split(p_text, ';', exts);
      FileListManager_SetExtensionFilter(getFileListManagerHandle(), exts);
      refreshFileTree('_files_of_type.on_change');
   }
}
void _files_of_type.backspace,del()
{
   call_root_key(BACKSPACE);
}

boolean _OpenTBDisableRefreshCallback(boolean value)
{
   boolean old_value = ignore_change_cd_callback;
   ignore_change_cd_callback = value;
   return old_value;
}

/**
 * Catch Ctrl+C and Ctrl+Ins and copy the current filename to
 * the clipboard
 */
void _file_name_filter."C-C","C-ins"()
{
   if ( p_text=="" ) {
      _file_tree.call_event(_file_tree,C_C);
   }else{
      eventtabindex := find_index("_ul2_textbox",EVENTTAB_TYPE);
      if ( eventtabindex ) {
         _file_name_filter.call_event(eventtabindex,C_C,'E');
      }
   }
}

void _file_name_filter.'C- '()
{
   expand_alias();
   _file_name_filter.p_text = strip(_file_name_filter.p_text, 'B', '"');
   _file_name_filter._end_line();
}

void _file_name_filter.'S-ENTER'()
{
   createNewFile();
}

void _file_name_filter.ESC()
{
   _file_tree.call_event(_file_tree,ESC);
}

void _file_name_filter.pgup,"c-p"()
{
   _file_tree.call_event(_file_tree,PGUP);
}

void _file_name_filter.pgdn()
{
   _file_tree.call_event(_file_tree,PGDN);
}

void _file_name_filter."s-up"()
{
   _file_tree.call_event(_file_tree, S_UP);
}

void _file_name_filter."s-down"()
{
   _file_tree.call_event(_file_tree,S_DOWN);
}

void _file_name_filter."c-HOME"()
{
   _file_tree.call_event(_file_tree, HOME);
}

void _file_name_filter."c-END"()
{
   _file_tree.call_event(_file_tree, END);
}

/**
 * Move up in the file tree.  Catch the cursor up key, and the
 * Ctrl+I
 */
void _file_name_filter.up,"c-i"()
{
   _file_tree.call_event(_file_tree,last_event(),'W');
   //filterUpDown('u');
}

/**
 * Move down in the file tree.  Catch the cursor down key, and
 * the Ctrl+K
 */
void _file_name_filter.down,"c-k"()
{
   _file_tree.call_event(_file_tree,last_event(),'W');
   //filterUpDown('d');
}

void _file_name_filter.tab()
{  
   int wid=p_window_id;
   p_window_id=_file_tree;
   index := _TreeCurIndex();
   if ( index>=0 && !isTruncatedWarning(index) ) {
      cap := _TreeGetCaption(index);
      parse cap with auto justName "\t" .;
      newPath := justName;
      if ( isSelectedFileTreeItemDirectory(index) ) {
         _maybe_append_filesep(newPath);
      }
      // We're playing a trick here.  If what the user has typed is an just a 
      // filename, _file_path will return "", and we will just set p_text to 
      // the tree caption.  if the user has typed part of a path, this will
      // keep that. So if a user typed "path1/path2/fil", it will complete 
      // correctly.
      _file_name_filter.p_text = _file_path(_file_name_filter.p_text):+newPath;
      _file_name_filter._end_line();
   }
   p_window_id=wid;
}
#if 0
/* 
We may want to resurrect this code later if we don't like using 
file completion for the text box. 
 */
_str filenew_match(_str name,boolean find_first)
{
   _str f=file_or_dir_match(name,find_first,true,'');
   if (find_first && f=='') return(name);
   return(f);
}
:+
        'TBOPEN_FILE_ARG='TBOPEN_FILE_ARG' ';
#define TBOPEN_FILE_ARG  ("_tbopen_file:"(FILE_CASE_MATCH|AUTO_DIR_MATCH))
 /
 
_str _tbopen_file_match(_str name,boolean find_first) {
   static int gtreewid;
   static int gsibling;
   static _str gsearchString;
   static boolean gHasPath;
   if (find_first==1) {
      gtreewid=_find_object('_tbopen_form._file_tree','N',gtreewid);
      if (!gtreewid) return(name);
      int * timer = gtreewid.getPointerToRefreshTimer();
      if (_timer_is_valid(*timer)) {
         gtreewid.filterOpenTBTree();
      }

      gsibling=gtreewid._TreeGetFirstChildIndex(0);
      say('gsibling='gsibling);
      if (gsibling<=0) return(name);
      gHasPath=strip_filename(name,'n')!='';
      gsearchString=strip_filename(name,'p');
   } else if (find_first) {
      return(name);
   }
   if (gsibling<=0) {
      if (find_first) {
         return(name);
      }
      return('');
   }
   gsibling=gtreewid._TreeSearch(gsibling,gsearchString,'PS');
   //say('h2 gsibling='gsibling);
   if (gsibling<=0) {
      if (find_first) {
         return(name);
      }
      return('');
   }
   parse gtreewid._TreeGetCaption(gsibling) with auto file \t auto path;
   gsibling=gtreewid._TreeGetNextSiblingIndex(gsibling);
   if (gHasPath) {
      path :+= file;
      say(path'>');
      return(path);
   }
   say('file='file'>');
   return(file);
} 
#endif 
/* 
   We need this so that completion does not display a popup-list.
   WARNING: This could cause problems in the future if the on_change2
   for the text box starts doing something we need.
*/ 
void _file_name_filter.on_change2() {
}

/**
 * Put focus in the tree if they hit enter in the filter combo.
 */
void _file_name_filter.ENTER()
{
   filterText := strip(_file_name_filter.p_text, 'B', '"');
   absolutePath := absolute(getCurrentFilesOnDiskDirectory());
#if __UNIX__
   if (def_unix_expansion) absolutePath = _unix_expansion(absolutePath);
#endif

   if (filterText != '' && CUR_FILES_ON_DISK_DIR == absolutePath && _file_tree._TreeGetNumSelectedItems()==0) {

      status:=chdir(CUR_FILES_ON_DISK_DIR,1);
      if (status) {
         _message_box(nls('"%s" is not a valid path or access has been denied',absolutePath));
         _file_name_filter._set_focus();
         return;
      }
      _file_name_filter.p_text = '';
      _file_name_filter._begin_line();
      _explorer_tree._set_current_path(absolutePath, 1, doShowHiddenFiles(), (def_opentb_options & OPENTB_SYNC_DIRECTORY) != 0);
      updateFileTreeDirectory(absolutePath);
   } else {
      // that's not a good path, so just send this ENTER to the tree to figure out
      oldCurDir := CUR_DIR;
      wid := p_window_id;
      openedFile := _file_tree.fileTreeEnterOrDoubleClick();

      // sometimes the tree is closed, so we want to make sure here...
      if (_iswindow_valid(wid) && _tbGetWid("_tbopen_form")) {
         newWid := p_window_id;
         p_window_id = wid;

         // if the directory got changed because of what happened, 
         // OR we pressed Enter to open a file and the option to clear the textbox
         // on enter is on, then clear the filter...
         if ( CUR_DIR != oldCurDir || (openedFile && (def_opentb_options & OPENTB_CLEAR_FILENAME_TEXTBOX) ) ) {
            // 12/8/2011
            // We need to add an opiton to change clearing the filter. For the moment
            // This is secondary, so just leave it commented out.

            _file_name_filter.p_text = '';
            _file_name_filter._begin_line();
         }

         p_window_id = newWid;
      }
   }
}

void _file_name_filter.'C-ENTER'()
{
   filter := _file_name_filter.p_text;
   // is this a valid files of type filter?
   if (pos('(\*.:a#)(\;\*.:a#)@', filter, 1, 'R') == 1 || filter == '') {
      if (filter != '') {
         _files_of_type._lbadd_item_no_dupe(filter, '', LBADD_TOP, true);
      }

      // select it!
      _files_of_type.p_text = filter;
      _file_name_filter.p_text = '';
      _file_name_filter._begin_line();
   }
}

void _options_link.lbutton_up()
{
   config('File Options > Open');
}

void _grabbar_horz.lbutton_down()
{
   // figure out orientation
   min := 0;
   max := 0;

   getGrabbarMinMax(min, max);

   _ul2_image_sizebar_handler(min, max);
}

static void getGrabbarMinMax(int &min, int &max, _str orientation = '')
{
   typeless (*pposTable):[] = getPointerToPositionTable();

   // use what is saved in the table if we don't know any better
   if (orientation == '') orientation = (*pposTable):["lastOrientation"];

   min = max = 0;
   if (orientation == 'H') {      // horizontal
      min = 2 * _file_tree.p_x;
      max = p_active_form.p_width - min;
   } else {
      min = 2 * _file_tree.p_y;
      max = _files_of_type_label.p_y - min;
   }
}

// events for the file tree

void _file_tree."C-C","C-ins"()
{
   do {
      // Find out how many items are in the tree
      treewid := getFileTree();
      if ( !treewid ) break;

      treeCurIndex := treewid._TreeCurIndex();
      if ( treeCurIndex<0 ) break;

      curFilename := treewid._TreeGetCaption( treeCurIndex );
      parse curFilename with auto namePart "\t" auto pathPart;

      // copy this mess
      push_clipboard(pathPart:+namePart);
      message(pathPart:+namePart' copied to clipboard');
   } while (false);
}

void _file_tree.'BACKSPACE'()
{
   openFileTreeUpDirectory();
}

void _file_tree.rbutton_up()
{
   showRightClickMenu();
}

/** 
 * Performs the double click or enter operation on the files 
 * tree. 
 *  
 * @return boolean true if a file was opened
 */
static boolean fileTreeEnterOrDoubleClick()
{
   if (last_event()==LBUTTON_DOUBLE_CLICK) {
      // make sure we're not double-clicking on the column headings...
      x := mou_last_x();
      y := mou_last_y();
      index := _TreeGetIndexFromPoint(x,y,'P');
      if (index < 0) return false;
   }

   filesOpened := false;
   treeWid := p_window_id;
   filterWid := _file_name_filter.p_window_id;

   onlyOneDir := 0;

   _str filesToOpen[];

   // Stop any side-effect updates to the file tree
   SuspendRefreshTimer();
   int info;
   for (ff:=1;;ff=0) {
      index := treeWid._TreeGetNextSelectedIndex(ff,info);
      if (index <= 0) break;

      // we already saw at least one other selection, set this
      if (onlyOneDir) onlyOneDir = -1;       

      // is this a directory?  wait until the end to do this...
      if (isSelectedFileTreeItemDirectory(index)) {
         if (!onlyOneDir) onlyOneDir = index;
      } else {
         if ( !isTruncatedWarning(index) ) {
            // if we are dismissing after select, we need to open the files
            // after we dismiss - otherwise, files that are already opened will not be brought forward
            if (def_opentb_options & OPENTB_DISMISS_AFTER_SELECT) {
               filesToOpen[filesToOpen._length()] = getFilePath(index);
            } else {
               treeWid.openFileTreeFile(index);
               int showChildren, bmpIdx1, bmpIdx2, moreFlags;
               treeWid._TreeGetInfo(index, showChildren, bmpIdx1, bmpIdx2, moreFlags);
               if(bmpIdx1 == _pic_file) {
                  bmpIdx1 = bmpIdx2 = _pic_otb_file_disk_open;
                  treeWid._TreeSetInfo(index, showChildren, bmpIdx1, bmpIdx2, moreFlags);
               }
            }
            filesOpened = true;
         }
      }
   }

   if (onlyOneDir > 0) openFileTreeDirectory(onlyOneDir);

   treeWid._TreeDeselectAll();
   // Allow file tree to reflect updates
   ResumeRefreshTimer();

   if (filesOpened && (def_opentb_options & OPENTB_DISMISS_AFTER_SELECT)) {
      _tbDismiss(treeWid.p_parent, true);

      // now open all those files we saved the names for
      for (i := 0; i < filesToOpen._length(); i++) {
         open_file(filesToOpen[i], 0, '');
      }
   } else {
      /*
         Case handled by IF below: 
            Current directory is c:\temp
            user types c:\temp<ENTER>

         Want to change to this directory and
         list all the files in the current directory.
      */
      if (onlyOneDir>0 && _file_name_filter.p_text!='') {
         _file_name_filter.p_text = '';
         _file_name_filter._begin_line();
      }
   }
   return filesOpened;
}

/**
 * Also open files on double click or enter.
 */
void _file_tree.'ENTER',lbutton_double_click()
{
   fileTreeEnterOrDoubleClick();
}

#region Alt-Key Navigation

void _tbopen_form.'A-E'()
{
   _file_name_filter._set_focus();
}

void _tbopen_form.'A-N'()
{
   createNewFile();
}

void _tbopen_form.'A-D'()
{
   // Make sure the panel is expanded, and the selected entry in the tree is visible.
   if (!DIR_PANEL_EXPANDED) {
      expandCollapseDirectoryPanel(true);
      p_active_form.call_event(p_active_form, ON_RESIZE);
      _explorer_tree._TreeScroll(_explorer_tree._TreeCurLineNumber());
   }
 

   _explorer_tree._set_focus();
}

void _tbopen_form.'A-F'()
{
   _file_tree._set_focus();
}

void _tbopen_form.'A-B'()
{
   browseForFile();
}

void _tbopen_form.'A-C'()
{
   clearFileNameFilter();
}

void _tbopen_form.'A-T'()
{
   _files_of_type._set_focus();
}

#endregion Alt-Key Navigation

#region Got Focus Events
/**
 * When the form gets focus, we see if the file tree needs updating with the new
 * project and workspace files.
 */

/** 
 * When the filter text box gets focus, be sure at least one
 * line in the tree is selected. (suggested by HS2 of SlickEdit
 * Community fame)
 * 
 */
void _file_name_filter.on_got_focus()
{
   numSelected := _file_tree._TreeGetNumSelectedItems();
   if ( !numSelected ) {
      curIndex := _file_tree._TreeCurIndex();
      if ( curIndex>-1 ) {
         _file_tree._TreeSelectLine(curIndex);
      }
   }

   _file_name_filter.p_sel_start=1;
   _file_name_filter.p_sel_length = _file_name_filter.p_text._length();

   maybeCheckViews();
}

void _file_tree.on_got_focus()
{
   maybeCheckViews();
}

void _explorer_tree.on_got_focus()
{
   maybeCheckViews();
}

void _files_of_type.on_got_focus()
{
   maybeCheckViews();
}

_tbopen_form.on_got_focus()
{
   maybeCheckViews();
}

#endregion Got Focus Events

#region Callbacks

// handlers for new buffers, project changes, etc

/**
 * Called when a new file is opened.
 */
void _buffer_add_opentb(int newBufId, _str bufName, int bufFlags = 0)
{
   maybeRefreshOpenFiles();
}

/**
 * Called when a buffer is renamed.
 */
void _buffer_renamedAfter_opentb(int bufId, _str oldBufName, _str newBufName, int bufFlags)
{
   maybeRefreshOpenFiles(oldBufName);
}

/**
 * Called when the given file is closed.
 */
void _cbquit_opentb(int bufId, _str bufName, _str docName, int bufFlags)
{
   maybeRefreshOpenFiles(bufName);
}

/**
 * Called when the current file is renamed.
 */
void _document_renamedAfter_opentb(int bufId, _str oldBufName, _str newBufName, int bufFlags)
{
   _buffer_renamedAfter_opentb(bufId, oldBufName, newBufName, bufFlags);
}

/**
 * Gets called when a buffer becomes hidden.
 */
void _cbmdibuffer_hidden_tbopen()
{
   maybeRefreshOpenFiles();
}

/**
 * Gets called when a hidden buffer becomes unhidden.
 */
void _cbmdibuffer_unhidden_tbopen()
{
   maybeRefreshOpenFiles();
}

/**
 * Called when files are added to the workspace.
 */
void _workspace_file_add_opentb(_str projName, _str fileName)
{
   force_refresh_workspace = true;
   _maybeRefreshWorkspaceFiles();
}

/**
 * Called when a different project is opened (set active).
 */
void _prjopen_opentb()
{
   force_refresh_workspace = true;
   _maybeRefreshWorkspaceFiles();
}

/**
 * Called when the active project is closed.
 */
void _prjclose_opentb()
{
   force_refresh_workspace = true;
   _maybeRefreshWorkspaceFiles();
}

/**
 * Called when a different workspace is opened.
 */
void _workspace_opened_opentb()
{
   force_refresh_workspace = true;
   _maybeRefreshWorkspaceFiles();
}
/** 
 * Called when files are added to any project by any means 
 * (i.e. even if a project is inserted into a workspace) 
 */
void _prjupdate_opentb() 
{
   force_refresh_workspace = true;
   _maybeRefreshWorkspaceFiles();
}

/**
 * Called when the current workspace is closed.
 */
void _wkspace_close_opentb()
{
   // Has the workspace really been closed at this point? 
   // Do we need to delay this update somehow? Please God, not a timer...
   force_refresh_workspace = true;
   _maybeRefreshWorkspaceFiles();
}

void _workspace_refresh_open()
{
   force_refresh_workspace = true;
   _maybeRefreshWorkspaceFiles();
}

void _MenuAddFileHist_opentb(_str filename)
{
   maybeRefreshHistoryFiles();
}

void _MenuRemoveFileHist_opentb(_str filename)
{
   maybeRefreshHistoryFiles();
}

#endregion Callbacks

#region Context Menu

/**
 * Shows the context menu for the file tree.
 */
static void showRightClickMenu()
{
   // Find out how many items are in the tree
   treeWid := getFileTree();
   if (treeWid <= 0) return;
   numSelected := treeWid._TreeGetNumSelectedItems();
   if (numSelected <= 1) {
      // If there is <=1 item selected, call lbutton_down event to select
      call_event(p_window_id, LBUTTON_DOWN);
      treeWid._TreeRefresh();
   } 
   
   isDirOnly := false;
   isDotDotDir := false;
   numSelected = treeWid._TreeGetNumSelectedItems();
   if (numSelected == 1) {
      index := treeWid._TreeCurIndex();
      isDirOnly = isSelectedFileTreeItemDirectory(index);
      _str selDir = _TreeGetCaption(index);
      if(endsWith(selDir, "\\.\\.\\s*$", true, 'L')){
         isDotDotDir = true;
      }
   }

   // now locate the menu and throw that bad boy up
   menuIndex := find_index("_tbopen_menu", oi2type(OI_MENU));
   menuHandle := _mdi._menu_load(menuIndex, 'P');

   int x, y;
   mou_get_xy(x, y);

   // we disable a lot of stuff if we only have a directory selected
   if (isDirOnly) {
      _menu_set_state(menuHandle, "tbopen-menu-command execute", MF_GRAYED, 'M');
      _menu_set_state(menuHandle, "tbopen-menu-command print", MF_GRAYED, 'M');
      _menu_set_state(menuHandle, "tbopen-menu-command copy", MF_GRAYED, 'M');
      _menu_set_state(menuHandle, "tbopen-menu-command move", MF_GRAYED, 'M');
      _menu_set_state(menuHandle, "tbopen-menu-command delete", MF_GRAYED, 'M');
      _menu_set_state(menuHandle, "tbopen-menu-command checkin", MF_GRAYED, 'M');
      _menu_set_state(menuHandle, "tbopen-menu-command checkout", MF_GRAYED, 'M');
      _menu_set_state(menuHandle, "tbopen-menu-command touch", MF_GRAYED, 'M');
      _menu_set_state(menuHandle, "tbopen-menu-command attributes", MF_GRAYED, 'M');
      _menu_set_state(menuHandle, "tbopen-menu-command addtoproject", MF_GRAYED, 'M');
      if(isDotDotDir) {
         _menu_set_state(menuHandle, "tbopen-menu-command addfave", MF_GRAYED, 'M');
      }
   }
   else {
       // Add to Favorites is enabled when only dirs are selected
      _menu_set_state(menuHandle, "tbopen-menu-command addfave", MF_GRAYED, 'M');
   }

   // add to project
   if (_workspace_filename == '' || _project_name == '' ||_IsWorkspaceAssociated(_workspace_filename)) {
      _menu_set_state(menuHandle, "tbopen-menu-command addtoproject", MF_GRAYED, 'M');
   }

   // check/uncheck options
   if (_open_tb_options() & OPENTB_DISMISS_AFTER_SELECT) {
      _menu_set_state(menuHandle, "tbopen-menu-command dismiss", MF_CHECKED, 'M');
   }
   if (def_filelist_show_dotfiles) {
      _menu_set_state(menuHandle, "tbopen-menu-command showhidden", MF_CHECKED, 'M');
   }
   if (_open_tb_options() & OPENTB_PREFIX_MATCH) {
      _menu_set_state(menuHandle, "tbopen-menu-command prefix", MF_CHECKED, 'M');
   }
   if (_open_tb_options() & OPENTB_SYNC_DIRECTORY) {
      _menu_set_state(menuHandle, "tbopen-menu-command syncdir", MF_CHECKED, 'M');
   }
   if (!(_open_tb_options() & OPENTB_HIDE_DIRECTORIES)) {
      _menu_set_state(menuHandle, "tbopen-menu-command showdir", MF_CHECKED, 'M');
   }
   if (!(_open_tb_options() & OPENTB_RESTORE_COLUMN_WIDTHS)) {
      _menu_set_state(menuHandle, "tbopen-menu-command autocolumnwidths", MF_CHECKED, 'M');
   }

   // check/uncheck views
   if (_open_tb_visible_views() & OTBFO_PROJECT_FILE) {
      _menu_set_state(menuHandle, "tbopen-menu-command showproj", MF_CHECKED, 'M');
   }
   if (_open_tb_visible_views() & OTBFO_OPEN_FILE) {
      _menu_set_state(menuHandle, "tbopen-menu-command showopen", MF_CHECKED, 'M');
   }
   if (_open_tb_visible_views() & OTBFO_HISTORY_FILE) {
      _menu_set_state(menuHandle, "tbopen-menu-command showhist", MF_CHECKED, 'M');
   }

   status := _menu_show(menuHandle, VPM_RIGHTBUTTON, x-1, y-1);
}

static void executeFileTreeFiles(int treeWid)
{
   mou_hour_glass(1);

   int files[];
   treeWid.getSelectedFiles(files);

   SendErrMessage := false;
   foreach (auto index in files) {
      // get the filename
      parse _TreeGetCaption(index) with auto filename \t auto path;
      path :+= filename;

      // make sure this file can even be executed...
      isexe := false;
#if __UNIX__
      attrs := file_list_field(filename, DIR_ATTR_COL, DIR_ATTR_WIDTH);
      isexe = pos('x', attrs) != 0;
#else
      ext := _get_extension(filename);
      isexe = file_eq(ext, 'bat') || file_eq(ext, 'exe') || file_eq(ext, 'cmd') || file_eq(ext, 'com');
#endif

      // if it's executable, save it
      if (isexe) {
         shell(path, 'A');
         treeWid._TreeDeselectLine(index);
      } else SendErrMessage=true;
   }

   if (SendErrMessage) {
      _str msg='';
#if __UNIX__
      msg = nls('At least one file did not have execute permissions');
#else
      msg = nls('At least one file was not an executable');
#endif
      _message_box(msg);
   }

   mou_hour_glass(0);
}

/**
 * Grabs the list of selected tree indices in the files tree.  We do this first 
 * because sometimes when we do an action per file, the tree loses focus and our 
 * next selected index is lost. 
 * 
 * @param files                     array of indices
 * @param allowDirectories          whether we put selected indices which are 
 *                                  directories
 */
static void getSelectedFiles(int (&files)[], boolean allowDirectories = false)
{
   // save all the selected indices
   int info;
   for (ff:=1;;ff=0) {
      index := _TreeGetNextSelectedIndex(ff,info);
      if (index <= 0) break;

      // make double sure this is a file, not a directory
      if (allowDirectories || !isSelectedFileTreeItemDirectory(index)) files[files._length()] = index;
   }

}

static void printFileTreeFile(int index)
{
   // get the filename
   parse _TreeGetCaption(index) with auto filename \t auto path;
   path :+= filename;

   // bring up this file, please...
   status := 0;
   curBufId := getBufId(index);
   if (curBufId) {
      status = edit('+bi 'curBufId);
   } else {
      // open it up, but we'll remember that it wasn't open before
      status = _mdi.edit('"'path'"');
   }

   // print it and quit it
   if (!status) {
      _mdi.p_child.print();
      if (!curBufId) {
         _mdi.p_child.quit(false);
      }
   }
}

static void printFiles(int treeWid)
{
   mou_hour_glass(1);

   // save the current buffer so we can restore it later...
   bufId := -1;
   if (!_no_child_windows()) bufId = _mdi.p_child.p_buf_id;

   int files[];
   treeWid.getSelectedFiles(files);

   // now print each one
   foreach (auto index in files) {
      treeWid.printFileTreeFile(index);
      treeWid._TreeDeselectLine(index);
   }

   // restore the old buffer
   if (bufId >= 0) {
      _mdi.p_child.edit('+bi 'bufId);
   }

   mou_hour_glass(0);
   treeWid._TreeDeselectAll();

}

static void copyFiles(int treeWid, boolean rename = false)
{
   mou_hour_glass(1);

   // save the current buffer so we can restore it later...
   bufId := -1;
   if (!_no_child_windows()) bufId = _mdi.p_child.p_buf_id;

   int files[];
   treeWid.getSelectedFiles(files);

   // now copy each one
   doPrompt := true;
   destPath := '';
   foreach (auto index in files) {
      // get the filename
      parse _TreeGetCaption(index) with auto filename \t auto path;
      path :+= filename;

      if (doPrompt) {

         status := 0;
         if (!rename) {
            buttons := "OK,Apply to &All,Cancel:_cancel\tCopy file '"path"' to";
            status = show('-modal _textbox_form',
                           'Copy Files to Directory',
                           TB_RETRIEVE_INIT,                // Flags
                        '',                                 // width
                        '',                                 // help item
                        buttons,                            // Button List
                        'copyFileTreeFiles',                // retrieve name
                        '-bd Directory:');
         } else {
            buttons := "OK,Apply to &All,Cancel:_cancel\tMove/Rename file '"path"' to";
            status = show('-modal _textbox_form',
                          'Move/Rename Files',
                          TB_RETRIEVE_INIT,                   // Flags
                          '',                                 // width
                          '',                                 // help item
                          buttons,                            // Button List
                          '',                                 // retrieve name not used for renames
                          '-bd Directory/Filename:'path);
         }

         if (status == '') return;

         // get our destination path
         destPath = strip(_param1, 'B', '"');
         mou_hour_glass(1);
         if (def_unix_expansion) destPath = _unix_expansion(destPath);

         // check for Apply to All
         if (status == 2 && isdirectory(destPath) && destPath != '') {
            doPrompt = false;
         }

         // is this even valid?
         if (destPath == '') {
            mou_hour_glass(0);
            return;
         }

         // maybe add a file sep
         if (last_char(destPath) != FILESEP && isdirectory(destPath)) {
            destPath :+= FILESEP;
         }
      }

      destDir := _strip_filename(destPath, 'N');
      destName := _strip_filename(destPath, 'P');

      haveDir := (destDir != '');
      haveName := (destName != '');

      // compile the destination path based on what we have
      destination := '';
      if (haveDir && haveName) {
         // new path, new filename
         destination = destPath;
      } else if (!haveDir && haveName) {
         // same path, new filename
         destination = _strip_filename(path, 'N' ) :+ destName;
      } else if (haveDir && !haveName) {
         // new dir, same filename
         destination = destDir;
         _maybe_append_filesep(destination);
         destination :+= _strip_filename(path,'P');
      }

      if (!rename) {
         // copy the file over
         status := copy_file(path, destination);
         if (status) {
            _message_box(nls("Could not copy file '%s' to '%s'\n\n%s", filename, destination, get_message(status)));
            return;
         }
      } else {
         // here we are moving the file
         status := _file_move(destination, path);
         if (status) {
            _message_box(nls("Could not move file '%s' to '%s'\n\n%s", filename, destination, get_message(status)));
            return;
         }
      }

      treeWid._TreeDeselectLine(index);
   }

   // restore the old buffer
   if (bufId >= 0) {
      _mdi.p_child.edit('+bi 'bufId);
   }

   mou_hour_glass(0);
}


static boolean deleteFileTreeFile(int index, boolean multiFiles, boolean &doPrompt)
{
   // get the filename
   parse _TreeGetCaption(index) with auto filename \t auto path;
   path :+= filename;

   status := 0;
   if (doPrompt) {
      _str buttons;
      if (multiFiles) {
         buttons = "Yes,Yes to &All,No,Cancel:_cancel\tDelete file '"path"'?";
      } else {
         buttons = "Yes,No,Cancel:_cancel\tDelete file '"path"'?";
      }

      status = show('-modal _textbox_form',
                  'Delete File(s)',
                  TB_RETRIEVE_INIT, //Flags
                  '',//width
                  '',//help item
                  buttons,
                  'OpenTBMenuDeleteFile');
      if (status == '') return false;

      if (status == 2 && multiFiles) doPrompt = false;

      // check for cancel
      if ((multiFiles && status == 3) || (!multiFiles && status == 2)) return false;
   }

   status = recycle_file(path);
   if (status) {
      int result=_message_box(nls("Could not delete file '%s'\n%s\n\nContinue?", path, get_message(status)), '', MB_YESNOCANCEL|MB_ICONQUESTION);
      if (result != IDYES) return false;
   } else {
      /* this code is out of date, commenting it out for now. 8/25/2006 LB 
      if (FileInProject(filename)) {
         status=RemoveFromProjectAndVC(CurFilename,LastPromptRemoveProject,LastPromptRemoveVC);
         if (status==COMMAND_CANCELLED_RC) {
            return;
         }
      }
      */
   }

   return true;
}

static void deleteFiles(int treeWid)
{
   int files[];
   treeWid.getSelectedFiles(files);
   multiSelect := (files._length() > 1);

   // now copy each one
   doPrompt := true;
   foreach (auto index in files) {
      cont := deleteFileTreeFile(index, multiSelect, doPrompt);

      // see if user cancelled...
      if (!cont) break;

      treeWid._TreeDeselectLine(index);
   }

   mou_hour_glass(0);
}

static void checkinFileTreeFile(int index)
{
   // get the filename
   parse _TreeGetCaption(index) with auto filename \t auto path;
   path :+= filename;

// int orig_view_id=p_window_id;
   vccheckin(path);
// p_window_id=orig_view_id;

}

static void checkinFiles(int treeWid)
{
   int files[];
   treeWid.getSelectedFiles(files);

   // now copy each one
   doPrompt := true;
   foreach (auto index in files) {
      treeWid.checkinFileTreeFile(index);
      treeWid._TreeDeselectLine(index);
   }
}

static void checkoutFileTreeFile(int index)
{
   // get the filename
   parse _TreeGetCaption(index) with auto filename \t auto path;
   path :+= filename;

   vccheckout(path);
}

static void checkoutFiles(int treeWid)
{
   int files[];
   treeWid.getSelectedFiles(files);

   // now copy each one
   doPrompt := true;
   foreach (auto index in files) {
      treeWid.checkoutFileTreeFile(index);
      treeWid._TreeDeselectLine(index);
   }
}

static void touchFileTreeFile(int index)
{
   // get the filename
   parse _TreeGetCaption(index) with auto filename \t auto path;
   path :+= filename;

   int temp_view_id, orig_view_id;
   status := _open_temp_view('"'path'"', temp_view_id, orig_view_id);
   if (!status) {
      mou_hour_glass(1);
      _save_file('+o');
      p_window_id = orig_view_id;
      _delete_temp_view(temp_view_id);
      mou_hour_glass(0);
   }
}

static void touchFiles(int treeWid)
{
   int files[];
   treeWid.getSelectedFiles(files);

   // now copy each one
   doPrompt := true;
   foreach (auto index in files) {
      treeWid.touchFileTreeFile(index);
      treeWid._TreeDeselectLine(index);
   }
}

static void setAttributeForFileTreeFile(int index)
{
   // get the filename
   parse _TreeGetCaption(index) with auto filename \t auto path;
   path :+= filename;

   _str result;
#if __UNIX__
   result=show('-modal _unixfmattr_form', path, '', nls("?Sets the Read and Write permissions of the selected files."));
#else
   result=show('-modal _fmattr_form', path, '', nls("?Sets the Read Only, Hidden, System, and Archive attributes of the selected files."));
#endif

   if (result=='') return;

   parse result with . auto plus auto minus ;
   if (_param2 == '+') plus='';
   if (_param3 == '-') minus='';

   result = maybe_quote_filename(_param2' '_param3);
   _macro('m', _macro('s'));
   chmod(result' 'filename);
}

static void setAttributesForFiles(int treeWid)
{
   int files[];
   treeWid.getSelectedFiles(files);

   // now copy each one
   doPrompt := true;
   foreach (auto index in files) {
      treeWid.setAttributeForFileTreeFile(index);
      treeWid._TreeDeselectLine(index);
   }

   _mdi.p_child.for_each_buffer('maybe_set_readonly');
}

static void addFilesToProject(int treeWid)
{
   if (_workspace_filename=='') return;
   if (_IsWorkspaceAssociated(_workspace_filename)) return;

   if (_project_name=='') {
      _message_box(nls("No project open"));
      return;
   }

   handle := _ProjectHandle(_project_name);

   _str filenames[];
   _str relativeFilenames[];

   int orig_view_id=p_window_id;
   // save all the selected indices
   int info;
   for (ff:=1;;ff=0) {
      index :=  _TreeGetNextSelectedIndex(ff,info);
      if (index <= 0) break;

      // make double sure this is a file, not a directory
      if (!isSelectedFileTreeItemDirectory(index)){

         // get the filename
         parse _TreeGetCaption(index) with auto filename \t auto path;
         path :+= filename;

         relFilename := _RelativeToProject(path);
         Node := _ProjectGet_FileNode(handle, relFilename);
         if (Node < 0) {
            //Need to use the absolute filename for VCS's
            filenames[filenames._length()] = path;
            relativeFilenames[relativeFilenames._length()] = relFilename;
         }
      }
   }

   _ProjectAdd_Files(handle, relativeFilenames);
   status := _ProjectSave(handle);
   if (status) {
      _message_box(nls("Could not update project file '%s'\n%s",_project_name,get_message(status)));
      return;
   }

   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   _MaybeAddFilesToVC(filenames);
   AddFilesToTagFile(filenames, null, useThread);

   toolbarUpdateFilterList(_project_name);

   // Call callbacks that catch product updates
   call_list('_prjupdate_');

   // regenerate makefile
   _maybeGenerateMakefile(_project_name);
}

static void toggleOpenTBOption(int option)
{
   // change this option to the opposite of whatever it is now
   curValue := _open_tb_options();

   // we don't care what it is, as long as we're making it the opposite
   if (curValue & option) curValue &= ~option;
   else curValue |= option;

   // set the new value
   _open_tb_options(curValue);
}

static void toggleOpenTBView(int option)
{
   // change this option to the opposite of whatever it is now
   curValue := _open_tb_visible_views();

   // we don't care what it is, as long as we're making it the opposite
   if (curValue & option) curValue &= ~option;
   else curValue |= option;

   // set the new value
   _open_tb_visible_views(curValue);
}

static void addDirectoryToFavorites(){
   treeWid := getFileTree();
   int info;
   index := treeWid._TreeGetNextSelectedIndex(1,info);
   if (index <= 0) return;
   // is this a directory?
   if (isSelectedFileTreeItemDirectory(index)){
      parse treeWid._TreeGetCaption(index) with auto dir \t auto path;
      if(dir != "..") {
          _str fullPath = (path :+ dir);
         boolean addedPlace = _explorer_tree._add_favorite_place(fullPath);
      }
   }
}

static void copyPathToClipboard(){

   // Build up a space-separated list of all the selected
   // file and directory paths
   treeWid := getFileTree();
   int files[];
   treeWid.getSelectedFiles(files, true);

   _str allPaths = "";
   boolean first = true;
   boolean multiples = false;
   foreach (auto index in files) {
      parse _TreeGetCaption(index) with auto filename \t auto path;
      path :+= filename;
      path = maybe_quote_filename(path);
      if(first) {
         allPaths = path;
      } else {
         allPaths = allPaths :+ " " :+ path;
         multiples = true;
      }
      first = false;
   }

   // Put path string on the clipboard
   if(allPaths != "") {
      push_clipboard(allPaths);
      if(multiples) {
         message('Paths copied to clipboard');
      } else{
         message('Path copied to clipboard');
      }
   }
}

/**
 * This command handles all the menu commands from the Open Tool Window context 
 * menu. 
 * 
 * @param cmdline 
 * @return 
 */
_command void tbopen_menu_command(_str cmdline="") name_info(',')
{
   // make sure we are looking at the open toolbar now
   treeWid := getFileTree();
   if (treeWid <= 0) return;

   // parse the command and figure out what to do
   parse cmdline with auto cmd .;

   switch (upcase(cmd)) {
   case 'OPEN':
      // open the selected file
      treeWid.call_event(treeWid, ENTER);
      break;
   case 'EXECUTE':
      executeFileTreeFiles(treeWid);
      break;
   case 'REFRESH':
      // refresh the files list
      refreshOpenToolWindow(true);
      break;
   case 'ADDFAVE':
      addDirectoryToFavorites();
      break;
   case 'PATHTOCLIPBOARD':
      copyPathToClipboard();
      break;
   case 'PRINT':
      printFiles(treeWid);
      break;
   case 'COPY':
      copyFiles(treeWid);
      // refresh the files list
      refreshOpenToolWindow();
      break;
   case 'MOVE':
      copyFiles(treeWid, true);
      // refresh the files list
      refreshOpenToolWindow();
      break;
   case 'DELETE':
      deleteFiles(treeWid);
      // refresh the files list
      refreshOpenToolWindow();
      break;
   case 'CHECKIN':
      checkinFiles(treeWid);
      break;
   case 'CHECKOUT':
      checkoutFiles(treeWid);
      break;
   case 'TOUCH':
      touchFiles(treeWid);
      break;
   case 'ATTRIBUTES':
      setAttributesForFiles(treeWid);
      // refresh the files list
      refreshOpenToolWindow();
      break;
   case 'ADDTOPROJECT':
      addFilesToProject(treeWid);
      break;
   case 'DISMISS':
      // change this option to the opposite of whatever it is now
      toggleOpenTBOption(OPENTB_DISMISS_AFTER_SELECT);
      break;
   case 'SHOWHIDDEN':
      // change this option to the opposite of whatever it is now
      def_filelist_show_dotfiles = !def_filelist_show_dotfiles;
      rescanFilesOnDisk();
      refreshFileTree('refreshFilesOnDisk');
      break;
   case 'SYNCDIR':
      // change this option to the opposite of whatever it is now
      toggleOpenTBOption(OPENTB_SYNC_DIRECTORY);
      break;
   case 'SHOWDIR':
      // change this option to the opposite of whatever it is now
      toggleOpenTBOption(OPENTB_HIDE_DIRECTORIES);
      break;
   case 'PREFIX':
      // change this option to the opposite of whatever it is now
      toggleOpenTBOption(OPENTB_PREFIX_MATCH);
      break;
   case 'SHOWPROJ':
      // change this option to the opposite of whatever it is now
      toggleOpenTBView(OTBFO_PROJECT_FILE);
      break;
   case 'SHOWOPEN':
      // change this option to the opposite of whatever it is now
      toggleOpenTBView(OTBFO_OPEN_FILE);
      break;
   case 'SHOWHIST':
      // change this option to the opposite of whatever it is now
      toggleOpenTBView(OTBFO_HISTORY_FILE);
      break;
   case 'AUTOCOLUMNWIDTHS':
      // change this option to the opposite of whatever it is now
      toggleOpenTBOption(OPENTB_RESTORE_COLUMN_WIDTHS);
      break;
   }
}

#endregion Context Menu
