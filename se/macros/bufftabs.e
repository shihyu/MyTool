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
#include "ftp.sh"
#include "diff.sh"
#import "cbrowser.e"
#import "clipbd.e"
#import "context.e"
#import "diff.e"
#import "dlgman.e"
#import "files.e"
#import "ftp.e"
#import "help.e"
#import "listproc.e"
#import "main.e"
#import "menu.e"
#import "moveedge.e"
#import "rte.e"
#import "sellist.e"
#import "sstab.e"
#import "stdprocs.e"
#import "tagwin.e"
#import "tbcmds.e"
#import "tbcontrols.e"
#import "tbsearch.e"
#import "tbdeltasave.e"
#import "toolbar.e"
#import "window.e"
#import "se/ui/toolwindow.e"
#import "se/ui/mainwindow.e"
#endregion

//#define FILETABS_CONTROL "FileTabsControl"
//#define FILETABS_KEY     "FileTabs"
static const FILETABS_NO_NAME= "Untitled<";
static const FILETABS_MAX_TABS= 255;

static const TBFILETABS_FORM= '_tbbufftabs_form';

/**
 * Indicates sort order for file tabs tool window and document tabs.
 * The default order is alphabetical.  It can also be set to
 * most recently visited, most recently opened, or manual.
 *
 * @default Alphabetical
 * @categories Configuration_Variables
 */
int def_file_tab_sort_order = FILETAB_ALPHABETICAL;

/**
 * Indicates the position where new tabs should be added when
 * a new file is opened and the file tabs are not being sorted
 * (Manual positioning).
 *
 * @default Right
 * @categories Configuration_Variables
 * @see def_file_tab_sort_order
 */
int def_file_tab_new_file_position = FILETAB_NEW_FILE_ON_RIGHT;

/**
 * Set to true for Close buttons on tabs. This applies to both
 * File Tabs tool window, and MDI document tabs.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_document_tabs_closable = true;

/**
 * Option for file tab orientation to be below the editor
 * control instead of above (the default behavior).
 * This only applies to the MDI document tabs.
 *
 * @default Top
 * @categories Configuration_Variables
 */
int def_document_tabs_orientation = SSTAB_OTOP;

/**
 * If 'true', the File tabs toolbar will display bitmaps next to file tabs
 * for "special" buffers, including, but not limited to:  The Build
 * window, file manager windows, and search result windows.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_file_tabs_uses_pictures = true;

/**
 * If 'true', The File tabs toolbar will compress the names of files
 * that differ from the previous file in the list only by extension.
 * This saves space and helps group associated files.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_file_tabs_abbreviates_files = true;

/**
 * If 'true', The document tabs will hide the extensions of
 * files in the list {@link def_file_tabs_hidden_extensions} in
 * order to save space.
 *
 * @default false
 * @categories Configuration_Variables
 * @see def_file_tabs_hidden_extensions
 */
bool def_file_tabs_hide_known_extensions = false;

/**
 * A space-separated list of file extensions that the document
 * tabs will hide rather than showing the entire file name.
 * This is only used if {@link def_file_tabs_hide_known_extensions}
 * is set to 'true'.
 *
 * @default "cpp cxx java cs cob for pl1 lua tcl vhd go py ada pas"
 * @categories Configuration_Variables
 * @see def_file_tabs_hide_known_extensions
 */
_str def_file_tabs_hidden_extensions = "cpp cxx java cs cob for pl1 lua tcl vhd go py ada pas";


/* array of buffer ids - contains the order in which they were opened.
This is not static so that this module can be loaded without clearing
it out.
*/
int gfiletabs_buffers_opened[];

/* array of buffer ids - contains the order in which they were
   put by the user in manual file tab mode.

This is not static so that this module can be loaded without clearing
it out.
*/
int gManualTabsOrder[];

// struct to be used in array indexed by buffid
struct tabs_t {
   int tabid;
   _str buffname;
   bool modified;
   _str caption;
   int picture;
};

// struct that contains 2 arrays of data, one indexed by tabid
// and the other indexed by buffid

struct tabs_data {
   int tab_order[];
   tabs_t buffid_order[];
   int clicked_tabid;
   int shiftLeftTabID;
   bool resize_flag;
   bool change_refresh;
   typeless update_time;
   bool pending_refresh;
   int do_not_refresh;
};

tabs_data gtbFileTabsData;

enum_flags FileTabNoRefreshFlags {
   FILE_TAB_NO_REFRESH,
   FILE_TAB_NO_REFRESH_ON_FOCUS,
};

struct TBFILETABS_FORM_INFO {
   int m_form_wid;
};
static TBFILETABS_FORM_INFO gtbFileTabsFormList:[];

static void _init_all_formobj(TBFILETABS_FORM_INFO (&formList):[],_str formName) {
   int last = _last_window_id();
   int i;
   for (i=1; i<=last; ++i) {
      if (_iswindow_valid(i) && i.p_object == OI_FORM && !i.p_edit) {
         if (i.p_name:==formName) {
            formList:[i].m_form_wid=i;
         }
      }
   }
}
int _tbGetActiveFileTabsForm()
{
   if (!_haveFileTabsWindow()) return 0;
   return tw_find_form(TBFILETABS_FORM);
}


int _sr_bufftabs(_str option = "",_str info = "",_str restoreFromInvocation = "",_str relativeToDir = null)
{
   // don't even bother with this unless we have manual tab order
   if (def_file_tab_sort_order != FILETAB_MANUAL) return 0;

   // figure out whether we are saving or restoring data
   if (option=='R' || option=='N') {
      // restoring!

      parse info with auto nOfLines .;
      if (nOfLines) {
         int bufNamesToIds:[];
         getBufNamesToIds(bufNamesToIds);

         gManualTabsOrder._makeempty();
         for (i := 0; i < nOfLines; i++) {
            down();
            get_line(auto bufName);

            if (bufNamesToIds._indexin(bufName)) {
               gManualTabsOrder[gManualTabsOrder._length()] = bufNamesToIds:[bufName];
            }
         }
         refresh_file_tabs();
      }
   } else {
      // saving!
      if (gManualTabsOrder._length()) {
         _str bufIdsToNames:[];
         getBufIdsToNames(bufIdsToNames);

         // create an array of buffer names first, just in case we don't get a match
         _str bufNames[];
         for (i := 0; i < gManualTabsOrder._length(); i++) {
            if (bufIdsToNames._indexin(gManualTabsOrder[i])) {
               bufNames[bufNames._length()] = bufIdsToNames:[gManualTabsOrder[i]];
            }
         }

         insert_line('BUFFTABS: 'bufNames._length());
         for (i = 0; i < bufNames._length(); i++) {
            insert_line(bufNames[i]);
         }
		}
   }

   return 0;
}

static void getBufNamesToIds(int (&bufNamesToIds):[])
{
   buf_info := buf_match("", 1, "V");
   loop {
      if (rc) break;

      parse buf_info with auto buf_id . . auto buf_name;

      if (buf_name == "") {
         buf_name = FILETABS_NO_NAME:+buf_id'>';
      }

      bufNamesToIds:[_file_case(buf_name)] = (int)buf_id;

      buf_info = buf_match("", 0, "V");
   }
}

static void getBufIdsToNames(_str (&bufIdsToNames):[])
{
   buf_info := buf_match("", 1, "V");
   loop {
      if (rc) break;

      parse buf_info with auto buf_id . . auto buf_name;

      if (buf_name == "") {
         buf_name = FILETABS_NO_NAME:+buf_id'>';
      }

      bufIdsToNames:[buf_id] = _file_case(buf_name);

      buf_info = buf_match("", 0, "V");
   }
}

void set_file_tabs_closable(bool value)
{
   TBFILETABS_FORM_INFO v;
   int i;
   foreach (i => v in gtbFileTabsFormList) {
      _nocheck _control ctlsstab1;
      sstabwid := i.ctlsstab1;
      sstabwid.p_ClosableTabs = value;
   }
   tab_refresh();
}

_command void set_file_tab_sort_order(int value = -1) name_info(','VSARG2_CMDLINE|VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if ( value == -1 ) {
      return;
   }

   def_file_tab_sort_order = value;

   TBFILETABS_FORM_INFO v;
   int i;
   foreach (i => v in gtbFileTabsFormList) {
      _nocheck _control ctlsstab1;
      sstabwid := i.ctlsstab1;
      // all the file tab moving is handled in the c code now...yay!
      sstabwid.p_MovableTabs = (def_file_tab_sort_order == FILETAB_MANUAL);
   }
   tab_refresh();

   _config_modify_flags(CFGMODIFY_DEFVAR);
   // Setting p_ClosableTabs forces refresh of document tabs
   _mdi.p_ClosableTabs = _mdi.p_ClosableTabs;
}

int file_tabs_sort_order(int value = null)
{
   if (value == null) {
      value = def_file_tab_sort_order;
   } else {
      set_file_tab_sort_order(value);
   }

   return value;
}

bool file_tabs_abbreviate_caption(bool value = null)
{
   if (value == null) {
      value = def_file_tabs_abbreviates_files;
   } else {
      def_file_tabs_abbreviates_files = value;
      if (_haveFileTabsWindow()) {
         refresh_file_tabs();
      }
      _mdi.p_ClosableTabs = _mdi.p_ClosableTabs;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   return value;
}

bool file_tabs_hide_known_extensions(bool value = null)
{
   if (value == null) {
      value = def_file_tabs_hide_known_extensions;
   } else {
      def_file_tabs_hide_known_extensions = value;
      if (_haveFileTabsWindow()) {
         refresh_file_tabs();
      }
      _mdi.p_ClosableTabs = _mdi.p_ClosableTabs;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   return value;
}

_str file_tabs_hidden_extensions(_str value = null)
{
   if (value == null) {
      value = def_file_tabs_hidden_extensions;
   } else {
      def_file_tabs_hidden_extensions = value;
      if (_haveFileTabsWindow()) {
         refresh_file_tabs();
      }
      _mdi.p_ClosableTabs = _mdi.p_ClosableTabs;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   return value;
}

_command void set_file_tabs_new_file_position(int value = -1) name_info(',')
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return;
   }
   file_tabs_new_file_position(value);
}

int file_tabs_new_file_position(int value = null)
{
   if ( value == null ) {
      value = def_file_tab_new_file_position;
   } else {
      def_file_tab_new_file_position = value;
      if (_haveFileTabsWindow()) {
         refresh_file_tabs();
      }
      _config_modify_flags(CFGMODIFY_DEFVAR);
      // Setting p_ClosableTabs forces refresh of document tabs
      _mdi.p_ClosableTabs = _mdi.p_ClosableTabs;
   }

   return value;
}

/**
 * @return Returns a pointer to the file tabs meta-data which
 *         is stored in the user data of the file tabs toolbar's
 *         tab control.  This behaves like a singleton in the sense
 *         that if the structure is not allocated, it will initialize
 *         one and return a pointer to that.  This function can
 *         not return null.
 *         The current object must be the tab control for the
 *         File Tabs tool window.
 */
static tabs_data* getFileTabsData()
{
   //int ctlsstab = get_tab_control();
   //_assert(p_window_id == ctlsstab);
   if (!gtbFileTabsData._length()) {
      gtbFileTabsData.clicked_tabid = -1;
      gtbFileTabsData.shiftLeftTabID = -1;
      gtbFileTabsData.change_refresh = false;
      gtbFileTabsData.pending_refresh = false;
      gtbFileTabsData.resize_flag = false;
      gtbFileTabsData.update_time = 0;
      gtbFileTabsData.do_not_refresh = 0;
   }
   return &gtbFileTabsData; //_GetDialogInfoHtPtr(FILETABS_KEY, p_window_id);
}

definit()
{
   // only clear this out if no buffers are currently open
   gtbFileTabsFormList._makeempty();
   _init_all_formobj(gtbFileTabsFormList,TBFILETABS_FORM);
   if (!gtbFileTabsFormList._length()) {
      gtbFileTabsData._makeempty();
   }
   buf_info := buf_match("", 1, "V");
   if (rc) {
      gfiletabs_buffers_opened._makeempty();
      gManualTabsOrder._makeempty();
   } else {
      sstabwid := get_tab_control();
      if (sstabwid > 0) {
         gManualTabsOrder._makeempty();
         getTabOrderFromTabs(sstabwid);
      }
   }
}

/**
 * Adds a newly opened buffer into our arrays which we use to keep track of tab
 * order.
 *
 * @param bufId
 * @param bufName
 */
static void addBufferToFileTabArrays(int bufId)
{
   // see if this is already in our MRO list
   index := findBufferInMROList(bufId);
   if (index >= 0) {
      // remove it - this will automatically shift everything
      gfiletabs_buffers_opened._deleteel(index);
   }

   // add it to the end of the list
   gfiletabs_buffers_opened[gfiletabs_buffers_opened._length()] = bufId;

   // now, look at the order of our manual array
   index = findBufferInManualOrderList(bufId);
   if (index < 0) {
      switch (def_file_tab_new_file_position) {
      case FILETAB_NEW_FILE_ON_RIGHT:
         // open new files on right - so we go in order of the gfiletabs_buffers_opened array
         gManualTabsOrder[gManualTabsOrder._length()] = bufId;
         break;
      case FILETAB_NEW_FILE_ON_LEFT:
         // open new files on left - go backwards of gfiletabs_buffers_opened array
         gManualTabsOrder._insertel(bufId, 0);
         break;
      case FILETAB_NEW_FILE_TO_RIGHT:
      case FILETAB_NEW_FILE_TO_LEFT:
         if (!_no_child_windows()) {
            int buffers[];
            _getBufferIdList(0, buffers);
            if (buffers._length() >= 2) {
               index = findBufferInManualOrderList(buffers[1]);
               if (index >= 0) {
                  if (def_file_tab_new_file_position == FILETAB_NEW_FILE_TO_LEFT) {
                     gManualTabsOrder._insertel(bufId, index);
                  } else {
                     gManualTabsOrder._insertel(bufId, index+1);
                  }
                  break;
               }
            }
         }
         gManualTabsOrder._insertel(bufId, 0);
         break;
      }
   }

}

/**
 * Finds the given buffer id in our MRO list of buffers.
 *
 * @param bufId
 *
 * @return int
 */
static int findBufferInMROList(int bufId)
{
   for (index := 0; index < gfiletabs_buffers_opened._length(); ++index) {
      if (gfiletabs_buffers_opened[index] == bufId) {
         return index;
      }
   }

   return -1;
}

/**
 * Finds the buffer name in our list of manually ordered file tabs.
 *
 * @param bufName
 *
 * @return int
 */
static int findBufferInManualOrderList(int bufId)
{
   if (!gManualTabsOrder._length()) return -1;

   for (index := 0; index < gManualTabsOrder._length(); ++index) {
      if (gManualTabsOrder[index] == bufId) {
         return index;
      }
   }

   return -1;
}

static void removeBufferFromFileTabArrays(int bufId)
{
   index := findBufferInMROList(bufId);
   if (index >= 0) {
      // remove it - this will automatically shift everything
      gfiletabs_buffers_opened._deleteel(index);
   }

   index = findBufferInManualOrderList(bufId);
   if (index >= 0) {
      // remove it - this will automatically shift everything
      gManualTabsOrder._deleteel(index);
   }
}

// bitmap indexes for tab icons for special file types
int _pic_directory_tab=0;
int _pic_build_tab=0;
int _pic_search_tab=0;
int _pic_diff_tab=0;
int _pic_deltasave_tab=0;

defeventtab _tbbufftabs_form;

defload()
{
   // force pictures to load when state file builds
   _fileman_get_file_picture("");
   _process_get_file_picture("");
   _search_get_file_picture("");
   _diff_get_file_picture("");
   _deltasave_get_file_picture("");

   tab_refresh();
}

/*
    ------------------------------
           Form Events
    ------------------------------
 */


/**
 * Cleans up the list data structure when the buffer
 * tabs toolbar is destroyed.
 */
void ctlsstab1.on_destroy()
{
   //say('in the destroy');
   tabs_data* ptabsdata = getFileTabsData();
   ptabsdata->buffid_order._makeempty();
   ptabsdata->tab_order._makeempty();
   //_SetDialogInfoHt(FILETABS_CONTROL, null, _mdi);

   gtbFileTabsFormList._deleteel(p_active_form);
}

/**
 * Catches the creation of the tab control and builds the toolbar.
 */
void ctlsstab1.on_create()
{
   TBFILETABS_FORM_INFO info;

   info.m_form_wid=p_active_form;
   gtbFileTabsFormList:[p_active_form]=info;

   //say('in the on_create');
   formwid := p_active_form;

   ctlsstab1.p_MovableTabs = (def_file_tab_sort_order == FILETAB_MANUAL);
   ctlsstab1.p_ClosableTabs = document_tabs_closable();
   if (_isMac()) {
      //ctlsstab1.p_DocumentMode = true;
      ctlsstab1.p_DocumentMode = true;
   } else {
      ctlsstab1.p_DocumentMode = true;
   }
   // Draw tabs differently for documents
   //ctlsstab1.p_style = PSSSTAB_DOCUMENT_TABS;
   ctlsstab1.p_AllowScrollWheel = false;

   tab_refresh();
}

/**
 * Active tab changes, change the current buffer.
 * On-change event for the tab control.
 */
void ctlsstab1.on_change(int reason, int arg1 = 0, int arg2 = 0)
{
   // gchange_refresh is a flag so that the switch
   // can be skipped in the case where we know that
   // the active buffer has already been changed
   int sstabWid = ctlsstab1;
   tabs_data* ptabsdata = getFileTabsData();

   if (reason == CHANGE_TABMOVED) {
      sortTabDataWithTabOrder(ctlsstab1);
      // Apply this manual move to all other File Tabs tool windows
      write_tabs(true,sstabWid);
   } else if (reason == CHANGE_TAB_CLOSE_BUTTON_CLICKED) {
      // arg1 is the tab the user clicked to close
      if( arg1 >= 0 ) {
         ptabsdata->clicked_tabid = arg1;
         buff_menu_close();
      }
   } else {
      // gchange_refresh is a flag so that the switch
      // can be skipped in the case where we know that
      // the active buffer has already been changed

      if ((reason == CHANGE_TABACTIVATED) && !(ptabsdata->change_refresh)) {
//       say('changed, active tab: 'p_ActiveTab);
         if ((ptabsdata->tab_order._length() < p_ActiveTab)) {
            // invaild tab somehow - need to rebuild
            //say('about to rebuild the tabs');
            tab_refresh();
            return;
         }
         int status = edit('+Q +BI ' :+ (ptabsdata->tab_order[p_ActiveTab]),EDIT_DEFAULT_FLAGS|EDIT_NOEXITSCROLL);
         if (status) {
            tab_refresh();
         }
      }
   }
}

void ctlsstab1.on_change2(int reason)
{
   if (reason == CHANGE_TAB_DROP_DOWN_CLICK) {
      sstDropDownList(getFileTabInfoForDropDownList);
   } else {
      call_event(reason, defeventtab _ul2_sstabb, ON_CHANGE2, 'E');
   }
}

void ctlsstab1.on_highlight(int index=0, _str caption="")
{
   if (!def_tag_hover_preview) return;
   if (index < 0) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata != null && index >= 0 && index < ptabsdata->tab_order._length()) {
      int buf_id = ptabsdata->tab_order[index];
      if (buf_id > 0) {
         orig_wid := p_window_id;
         p_window_id=VSWID_HIDDEN;
         _safe_hidden_window();
         int status=load_files('+q +bi 'buf_id);
         if (!status && p_buf_name != "") {
            member_name := (p_DocumentName != "")? p_DocumentName : _strip_filename(p_buf_name,'P');
            tag_init_tag_browse_info(auto cm, member_name, "", SE_TAG_TYPE_FILE, SE_TAG_FLAG_NULL, p_buf_name, p_line);
            cm.language  = p_LangId;
            _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
         }
         p_window_id=orig_wid;
      }
   }
}

void getFileTabInfoForDropDownList(int tabNum, _str &tabCaption, _str& tabToolTip)
{
   SSTABCONTAINERINFO info;
   _getTabInfo(tabNum,info);
   tabToolTip = info.tooltip;

   // remove any '*' signifying a modified tab
   tabToolTip = strip(tabToolTip, 'T', '*');
   tabToolTip = strip(tabToolTip, 'B', ' ');

   tabCaption = _strip_filename(tabToolTip, 'P');

   // check for ampersands in the file names - double
   // them or they will show up as hotkeys
   tabCaption = _prepare_filename_for_menu(tabCaption);
}


static void sortFileTabsByArray()
{
	if (!gManualTabsOrder._length()) return;

	// first we map buffer ids to names, so we can recognize buffers from their names alone
	tabs_data* ptabsdata = getFileTabsData();

	i := 0;
   tabId := 0;
	numBuffers := gManualTabsOrder._length();
	while (i < numBuffers) {
		// get the buffer name
      bufId := gManualTabsOrder[i];

      // we have to make sure that this buffer id is in the list - if we have more
      // files than the max amount of buffers, some might be missing
      if (!ptabsdata->buffid_order[bufId]._isempty()) {
         // now put that one in the next position in our data
         ptabsdata->buffid_order[bufId].tabid = tabId;
         ptabsdata->tab_order[tabId] = bufId;

         tabId++;
      }

      // update our counters
      i++;
	}
}

static void sortTabDataWithTabOrder(int sstabwid)
{
	if (sstabwid > 0) {
		getTabOrderFromTabs(sstabwid);
		sortFileTabsByArray();
	}
}

static void getTabOrderFromTabs(int sstabwid)
{
   int bufNamesToIds:[];
   getBufNamesToIds(bufNamesToIds);

   // go through each tab and extract the info - we are really just
   // trying to put everything in order that the tabs are already
   gManualTabsOrder._makeempty();
   _str found:[];
   for (tabPos := 0; tabPos < sstabwid.p_NofTabs; ++tabPos) {
      // get the tooltip info - it contains the entire path
      tabToolTip := sstabwid.sstGetTabToolTip(tabPos);

      SSTABCONTAINERINFO tabinfo;
      info := sstabwid._getTabInfo(tabPos,tabinfo);
      if (tabToolTip == "") {
         tabToolTip = sstabwid.sstGetTabCaption(tabPos);
      }

      if (tabToolTip != "") {
         // remove any '*' signifying a modified tab
         tabToolTip = strip(tabToolTip, 'T', '*');
         tabToolTip = strip(tabToolTip, 'B', ' ');
         tabToolTip = _file_case(tabToolTip);

         // we don't want any duplicates
         if (!found._indexin(tabToolTip) && bufNamesToIds._indexin(tabToolTip)) {
            gManualTabsOrder[gManualTabsOrder._length()] = bufNamesToIds:[tabToolTip];
            found:[tabToolTip] = 1;
         }
      }
   }
}

/**
 * Resizes the tab control when the form gets resized.<P>
 * Also resizes the form height when it is too short to fit the tab control.
 */
void _tbbufftabs_form.on_resize()
{
   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata->resize_flag) {
      return;
   }
   ptabsdata->resize_flag = true;
   ctlsstab1.sstAdjustHeightForNoContent();

   pic_size := 16;
   parse def_toolbar_tab_pic_size with auto w 'x' auto h;
   if ( isinteger(w) ) pic_size = (int)w;
   if ( ctlsstab1.p_height < _dy2ly(SM_TWIP,pic_size) ) {
      ctlsstab1.p_height = _dy2ly(SM_TWIP,pic_size);
   }


   int minH = ctlsstab1.p_y_extent;

   if ( p_height != minH ) {
      p_height = minH;
   }

   ctlsstab1.p_x_extent = p_width ;

   p_visible = true;

   ptabsdata->resize_flag = false;
}

/*
    ------------------------------
           Callbacks
    ------------------------------
 */


/**
 * Get a picture id for the given buffer tab
 * Assumes the current window ID is an editor control.
 */
int buff_tabs_get_picture(_str name)
{
   // no pictures, ok, fine
   if (!def_file_tabs_uses_pictures) {
      return 0;
   }

   // look up extension specific callback
   picture := 0;
   index := _FindLanguageCallbackIndex("_%s_get_file_picture");
   if (index > 0) {
      picture = call_index(name,index);
   }

   // check for other editor [hidden] buffers
   if (!picture) {
      if (beginsWith(name,'.process')) {
         picture = _process_get_file_picture(name);
      } else if (_isGrepBuffer(name)) {
         picture = _search_get_file_picture(name);
      } else if (_isInterleavedDiffBufferName(name)) {
         picture = _diff_get_file_picture(name);
      } else if (_isDSBuffer(name)) {
         picture = _deltasave_get_file_picture(name);
      }
   }

   // that's all folks
   if (picture < 0) picture=0;
   return picture;
}

int _fileman_get_file_picture(_str name)
{
   if (!_pic_directory_tab) {
      _pic_directory_tab = _find_or_add_picture("tbopen.svg");
   }
   return _pic_directory_tab;
}
int _process_get_file_picture(_str name)
{
   if (!_pic_build_tab) {
      _pic_build_tab = _find_or_add_picture("tbbuild.svg");
   }
   return _pic_build_tab;
}
int _search_get_file_picture(_str name)
{
   if (!_pic_search_tab) {
      _pic_search_tab = _find_or_add_picture("tbsearch.svg");
   }
   return _pic_search_tab;
}
int _diff_get_file_picture(_str name)
{
   if (!_pic_diff_tab) {
      _pic_diff_tab = _find_or_add_picture("tbdiff.svg");
   }
   return _pic_diff_tab;
}
int _deltasave_get_file_picture(_str name)
{
   if (!_pic_deltasave_tab) {
      _pic_deltasave_tab = _find_or_add_picture("tbbackup_history.svg");
   }
   return _pic_deltasave_tab;
}

/**
 * Return true or false depending on whether we
 * should consider this buffer as modified or not.
 */
bool buff_tabs_get_modify(_str buffname)
{
   if (beginsWith(buffname,".process")) {
      return false;
   } else if (_isGrepBuffer(buffname)) {
      return false;
   } else if (buffname=="") {
      return false;
   }
   return p_modify;
}

/**
 * Create a caption from buffer/document name passed in that is
 * suitable for display on a File tab.
 *
 * @param name
 *
 * @return Caption string suitable for display on a File tab.
 */
static _str createCaptionName(_str name)
{
   if( name == "" ) {
      return "";
   }
   _str captionName = name;
   if( ftpIsFTPDocname(name) ) {
      // Find the matching connection profile so we can intelligently
      // strip the path based on the server type.
      _str host, port, path;
      _ftpParseAddress(name,host,port,path);
      _str list[];
      if( 0 == _ftpHostNameToCurrentConnection(host,list) ) {
         // We have to be lazy and use the first match in the list since
         // we do not currently map specific buffers to specific connections.
         FtpConnProfile* fcp_p = _ftpIsCurrentConnProfile(list[0]);
         if( fcp_p ) {
            captionName = _ftpStripFilename(fcp_p,path,'p');
         }
      } else {
         // Probably autorestoring an ftp file without a current connection,
         // so guess at the server type (UNIX). This will work out in most
         // cases even if the server type is not UNIX.
         FtpConnProfile fcp;
         _ftpInitConnProfile(fcp);
         fcp.system = FTPSYST_UNIX;
         captionName = _ftpStripFilename(&fcp,path,'p');
      }
   } else {
      captionName = _strip_filename(name,'p');
   }

   // if there are any &s, then double them, otherwise it will show up as an
   // underline on the next character
   captionName = _prepare_filename_for_menu(captionName);

   return captionName;
}

/**
 * Create a caption from buffer/document name passed in that is
 * suitable for display as the hover-over full name.
 *
 * @param bufName      Name of buffer.
 * @param documentName Document name of buffer.
 *
 * @return Caption string suitable for display as the hover-over
 *         full name.
 */
static _str createFullName(_str bufName, _str documentName="")
{
   _str fullName = bufName;
   if( documentName != "" ) {
      fullName = documentName;
   }
   return fullName;
}

/**
 * Adds a tab for a new buffer.
 *
 * @param newbuffid p_buf_id of the new buffer
 * @param name      p_buf_name of the new buffer
 * @param flags
 */
void _buffer_add_tabs(int newbuffid, _str name, int flags = 0)
{
   if ( p_buf_flags & VSBUFFLAG_HIDDEN ) {
      //say("_buffer_add_tabs: HIDDEN");
      return;
   }

   // add this buffer to our list of opened buffers
   addBufferToFileTabArrays(newbuffid);

   // make sure that the tab control exists
   sstabwid := get_tab_control();
   if (!sstabwid) {
      //say('no tab control');
      return;
   }

   // bail out if there is a refresh pending
   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata==null || ptabsdata->pending_refresh) {
      //say("_buffer_add_tabs: SKIPPING");
      return;
   }

// say('trying to add: 'name' flags: 'flags', bufid: 'newbuffid);
   if ( sstabwid.have_tab(newbuffid) ) {
//    say("   _buffer_add_tabs: already a tab for this buffer");
      return;
   }
   // check to see if the maximum number of tabs has already been reached
   if (sstabwid.p_NofTabs==FILETABS_MAX_TABS) {
//    say('too many tabs open already (MAX_TABS reached)');
      return;
   }

   // if we are getting tons of these messages, then batch together
   // into one call to refresh the buffer list
   if (batch_call_list("refresh_file_tabs")) {
      ptabsdata->pending_refresh = true;
//    say("_buffer_add_tabs: PENDING");
      return;
   }

   //say('really adding: 'name);
   TBFILETABS_FORM_INFO v;
   int i;
   foreach (i => v in gtbFileTabsFormList) {
      _nocheck _control ctlsstab1;
      sstabwid = i.ctlsstab1;
      // make sure that the tab control is visible
      sstabwid.p_visible = true;
      // if there are not any tabs currently, add one
      if (sstabwid.p_NofTabs==0) {
         sstabwid.p_NofTabs++;
      }
   }

   temp_name := "";
   if (p_DocumentName!="") {
      temp_name = createCaptionName(p_DocumentName);
   } else {
      temp_name = createCaptionName(name);
   }
   if (temp_name == "") {
      temp_name = FILETABS_NO_NAME:+newbuffid'>';
   }

   tabs_t *ptab = &ptabsdata->buffid_order[newbuffid];
   ptab->buffname = createFullName(p_buf_name,p_DocumentName);
   ptab->caption  = temp_name;
   ptab->picture  = buff_tabs_get_picture(p_buf_name);
   ptab->modified = buff_tabs_get_modify(p_buf_name);
   gchange_orig := ptabsdata->change_refresh;
   ptabsdata->change_refresh = true;

   // manual order is sorted by whatever order the tabs are in
   // if we want the new tab to be on the left, we have to do some special stuff
   if (def_file_tab_sort_order == FILETAB_MANUAL && def_file_tab_new_file_position == FILETAB_NEW_FILE_ON_LEFT) {

      // insert this tab at the beginning
      ptabsdata->tab_order._insertel(newbuffid, 0);
      ptab->tabid = 0;

      // now go through all the others and adjust their tab ids
      for (i = 0; i < ptabsdata -> tab_order._length(); i++) {
         buffId := ptabsdata -> tab_order[i];

         if (ptabsdata -> buffid_order[buffId] != null) {
            ptabsdata -> buffid_order[buffId].tabid = i;
         }
      }

   } else if (def_file_tab_sort_order == FILETAB_MANUAL) {

      // insert this tab at the beginning
      index := findBufferInManualOrderList(newbuffid);
      ptabsdata->tab_order._insertel(newbuffid, index);
      ptab->tabid = index;

      // now go through all the others and adjust their tab ids
      for (i = index; i < ptabsdata -> tab_order._length(); i++) {
         buffId := ptabsdata -> tab_order[i];
         if (ptabsdata -> buffid_order[buffId] != null) {
            ptabsdata -> buffid_order[buffId].tabid = i;
         }
      }

   } else {
      ptabsdata->tab_order[ptabsdata->tab_order._length()] = newbuffid;
      ptab->tabid    = ptabsdata->tab_order._length()-1;
   }

   // we don't
   int status = write_tabs(def_file_tab_sort_order != FILETAB_MANUAL);
   if (status) {
      //say('status exception in write tabs');
   }
   foreach (i => v in gtbFileTabsFormList) {
      _nocheck _control ctlsstab1;
      sstabwid = i.ctlsstab1;
      // set the active tab to be the file just opened
      sstabwid.p_ActiveTab = ptab->tabid;
   }
   ptabsdata->change_refresh = gchange_orig;
   //say('exiting the add tab');
}

/**
 * Catches the callbacks for buffers getting renamed and updates the file tab information.
 *
 * @param buffid  p_buf_id of the buffer in question
 * @param oldname old p_buf_name
 * @param newname new p_buf_name
 * @param flags
 */
void _buffer_renamed_tabs(int buffid, _str oldname, _str newname, int flags)
{
   //say('buff renamed.  old name: 'oldname);
   sstabwid := get_tab_control();
   if (!sstabwid) {
      return;
   }

   // bail out if there is a refresh pending
   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata==null || ptabsdata->pending_refresh) {
      //say("_buffer_renamed_tabs: SKIPPING");
      return;
   }

   // if we are getting tons of these messages, then batch together
   // into one call to refresh the buffer list
   if (batch_call_list("refresh_file_tabs")) {
      ptabsdata->pending_refresh = true;
      //say("_buffer_renamed_tabs: PENDING");
      return;
   }

   if (!sstabwid.have_tab(buffid)) {
      // no tab, so we are potentially adding one
      _buffer_add_tabs(buffid,newname);
      return;
   } else {
      //say('renaming: 'oldname' to: 'newname);
      tabs_t *ptab = &ptabsdata->buffid_order[buffid];
      ptab->buffname = createFullName(newname);
      ptab->caption  = createCaptionName(newname);
      ptab->picture  = buff_tabs_get_picture(newname);
      write_tabs();
      TBFILETABS_FORM_INFO v;
      int i;
      foreach (i => v in gtbFileTabsFormList) {
         _nocheck _control ctlsstab1;
         sstabwid = i.ctlsstab1;
         sstabwid.p_ActiveTab = ptab->tabid;
      }
      // close the tab with the old name
      //_cbquit_tabs(buffid,oldname,"",0);
      // open a tab with the new name
      //_buffer_add_tabs(buffid,newname);
   }
}

/**
 * Gets called when p_DocumentName is changed.<P>
 * Simply passes this on to _buffer_renamed_tabs with the correct parameters.
 *
 * @param bufid   p_buf_id of the buffer
 * @param oldname old p_DocumentName of the buffer
 * @param newname new p_DocumentName of the buffer
 * @param flags
 */
void _document_renamed_tabs(int bufid,_str oldname,_str newname,int flags)
{
   if (!gtbFileTabsFormList._length()) return;

   // bail out if there is a refresh pending
   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata==null || ptabsdata->pending_refresh) {
      //say("_document_renamed_tabs: SKIPPING");
      return;
   }

   // if we are getting tons of these messages, then batch together
   // into one call to refresh the buffer list
   if (batch_call_list("refresh_file_tabs")) {
      ptabsdata->pending_refresh = true;
      //say("_document_renamed_tabs: PENDING");
      return;
   }

   //say('document renamed');
   if (newname=="") {
      // need to switch to p_buf_name for the label now
      orig_view_id := p_window_id;
      int temp_view_id;
      int status = _open_temp_view("",temp_view_id,orig_view_id,'+bi ':+bufid);
      _buffer_renamed_tabs(bufid,oldname,p_buf_name,flags);
      p_window_id = orig_view_id;
      _delete_temp_view(temp_view_id,true);
   } else {
      _buffer_renamed_tabs(bufid,oldname,newname,flags);
   }
}


/**
 * Gets called when a buffer is closed.
 *
 * @param buffid  p_buf_id of the buffer that was closed
 * @param name    p_buf_name of the buffer that was closed
 * @param docname p_DocumentName of the buffer that was closed
 * @param flags   assumed to be 0
 */
void _cbquit_tabs(int buffid, _str name, _str docname= "", int flags = 0)
{
   // remove this buffer from our list
   removeBufferFromFileTabArrays(buffid);

   sstabwid := get_tab_control();
   if (sstabwid == 0) {
//    say('cannot get the tab control');
      return;
   }

   // bail out if there is a refresh pending
   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata==null || ptabsdata->pending_refresh) {
      //say("_cbquit_tabs: SKIPPING");
      return;
   }

   if (sstabwid.have_tab(buffid) /*|| name == ""*/) {

      // if we are getting tons of these messages, then batch together
      // into one call to refresh the buffer list
      if (batch_call_list("refresh_file_tabs")) {
         ptabsdata->pending_refresh = true;
         //say("_cbquit_tabs: PENDING");
         return;
      }

      gchange_orig := ptabsdata->change_refresh;
      ptabsdata->change_refresh = true;

      TBFILETABS_FORM_INFO v;
      int i;
      foreach (i => v in gtbFileTabsFormList) {
         _nocheck _control ctlsstab1;
         sstabwid = i.ctlsstab1;
         // set the active tab to the one that is closing
         sstabwid.p_ActiveTab = ptabsdata->buffid_order[buffid].tabid;
      }

      // tries to make sure that the tab is the correct
      // tab name for the buffer that was closed
      int x;
      for (x = sstabwid.p_ActiveTab+1;x<ptabsdata->tab_order._length(); ++x) {
         --ptabsdata->buffid_order[ptabsdata->tab_order[x]].tabid;
      }

      // delete the info from our data
      ptabsdata->tab_order._deleteel(ptabsdata->buffid_order[buffid].tabid);
      ptabsdata->buffid_order[buffid]._makeempty();

      foreach (i => v in gtbFileTabsFormList) {
         _nocheck _control ctlsstab1;
         sstabwid = i.ctlsstab1;
         // delete it only if there are other tabs
         if (sstabwid.p_NofTabs > 1) {
            sstabwid._deleteActive();
         }

         // it's all gone, hide the tabs and clear the data
         if (ptabsdata->tab_order._length()==0) {
            sstabwid.p_visible = false;
            ptabsdata->buffid_order._makeempty();
            ptabsdata->tab_order._makeempty();
         }
      }

      ptabsdata->change_refresh = gchange_orig;

      // maybe have to fix the file names
      if (def_file_tabs_abbreviates_files) {
         write_tabs();
      }
   }
}


/**
 * gets called when active buffer is switched
 *
 * @param oldbuffname
 *               name of buffer being switched from
 * @param flag   flag = 'Q' if file is being closed
 *               flag = 'W' if focus is being indicated
 */
void _switchbuf_tabs(_str oldbuffname, _str flag)
{
// say('switchbuf, bufname = '_mdi.p_child.p_buf_name);
   //say('flags: 'flag);
   if ((HaveBuffer()) && (_mdi.p_child._no_child_windows()==0)) {
      sstabwid := get_tab_control();
      if (!sstabwid) {
         return;
      }

      // if the current tab already points to the current buffer, return
      tabs_data* ptabsdata = getFileTabsData();
      if (ptabsdata==null || ptabsdata->pending_refresh) {
//       say("   _switchbuf_tabs: SKIPPING");
         return;
      }

      // if we don't have a tab for it, maybe add it, but definitely return
      if (!sstabwid.have_tab(_mdi.p_child.p_buf_id)) {
//       say('   switchbuf is adding a tab: '_mdi.p_child.p_buf_name' '_mdi.p_child.p_buf_id);
         _buffer_add_tabs(_mdi.p_child.p_buf_id,_mdi.p_child.p_buf_name);
         return;
      }

      // we might already be on the current tab - particularly
      //  if the buffer change was caused by clicking a file tab
      if (ptabsdata->buffid_order[ptabsdata->tab_order[sstabwid.p_ActiveTab]].buffname == _mdi.p_child.p_buf_name &&
          (def_file_tab_sort_order != FILETAB_MOST_RECENTLY_VIEWED || sstabwid.p_ActiveTab == 0)) {
         // no switching necessary
//       say("   _switchbuf_tabs: nothing necessary");
         return;
      }

      // sometimes we don't want to refresh after the got focus event
      if ((ptabsdata -> do_not_refresh & FILE_TAB_NO_REFRESH_ON_FOCUS) && event2name(last_event()) == 'ON-GOT-FOCUS') {
//       say("   _switchbuf_tabs: not refresh on got focus");
         return;
      } else {
         // remove this flag if it's there
         ptabsdata -> do_not_refresh &= ~FILE_TAB_NO_REFRESH_ON_FOCUS;
      }

      // if we are getting tons of these messages, then batch together
      // into one call to refresh the buffer list
      // only do this when opening (E) and closing (Q)
      flag = upcase(flag);
      if ((flag == 'E' || flag == 'Q') && batch_call_list("refresh_file_tabs")) {
         ptabsdata->pending_refresh=true;
//       say("   _switchbuf_tabs: PENDING");
         return;
      }

      if (substr(oldbuffname,1,1) == '.' && (flag == 'Q')) {
         int x;
         for (x=0; x<ptabsdata->tab_order._length();x++) {
            if (ptabsdata->buffid_order[ptabsdata->tab_order[x]].buffname==oldbuffname) {
               // calling the close callback to clean up the tabs
               _cbquit_tabs(ptabsdata->tab_order[x], oldbuffname);
               return;
            }
         }
      }

      // everything is correct and the active tab needs to be updated
      gchange_orig := ptabsdata->change_refresh;
      ptabsdata->change_refresh = true;

      // the tabs only need refreshing in this case if we have Most Recently Viewed mode
      // however, we must check the do_not_refresh value
      if (def_file_tab_sort_order == FILETAB_MOST_RECENTLY_VIEWED && ((ptabsdata -> do_not_refresh & FILE_TAB_NO_REFRESH) == 0)) {
         int status = write_tabs();
         if (status) {
            //say('status exception in write tabs');
         }
      }

      TBFILETABS_FORM_INFO v;
      int i;
      foreach (i => v in gtbFileTabsFormList) {
         _nocheck _control ctlsstab1;
         sstabwid = i.ctlsstab1;
         sstabwid.p_ActiveTab = ptabsdata->buffid_order[_mdi.p_child.p_buf_id].tabid;
      }
      ptabsdata->change_refresh = gchange_orig;
   }
}

void _cbsave_tabs(...)
{
   sstabwid := get_tab_control();
   if (!sstabwid) {
      return;
   }

   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata==null || ptabsdata->pending_refresh) {
      //say("_cbsave_tabs: SKIPPING");
      return;
   }

   if (!ptabsdata->buffid_order[p_buf_id]._isempty()) {

      if (batch_call_list("_update_mod_file_status")) {
         //say("_cbsave_tabs: PENDING");
         return;
      }

      origChangeRefresh := ptabsdata->change_refresh;
      ptabsdata->change_refresh = true;

      TBFILETABS_FORM_INFO v;
      int i;
      foreach (i => v in gtbFileTabsFormList) {
         _nocheck _control ctlsstab1;
         sstabwid = i.ctlsstab1;
         x := ptabsdata->buffid_order[p_buf_id].tabid;
         orig_active := sstabwid.p_ActiveTab;
         _update_modified(sstabwid, x);
         sstabwid.p_ActiveTab = orig_active;
      }

      ptabsdata->change_refresh = origChangeRefresh;
   }
}

static void _update_modified(int sstabwid, int x)
{
   tabs_data* ptabsdata = getFileTabsData();
   tabs_t *ptab = &ptabsdata->buffid_order[ptabsdata->tab_order[x]];
   cur_buf_id := ptabsdata->tab_order[x];
   if ((buff_tabs_get_modify(p_buf_name)) &&
       (substr(ptab->buffname,1,1)) != '.') {
      if (!ptab->modified) {
         sstabwid.p_ActiveTab = x;
         ptab->modified = true;
         // adding a * to the tooltip
         if (ptab->buffname != "") {
            sstabwid.p_ActiveToolTip = ptab->buffname:+' *';
         }

         // setting the bitmap to indicate the file as modified
         typeless mc;
         if (_default_option(VSOPTION_TAB_MODIFIED_COLOR)) {
            _str c=_default_color(CFG_MODIFIED_FILE_TAB);
            parse c with mc .;
            sstabwid.p_ActiveColor = mc;
            if(endsWith(sstabwid.p_ActiveCaption,' *')) {
               sstabwid.p_ActiveCaption=substr(sstabwid.p_ActiveCaption,1,length(sstabwid.p_ActiveCaption)-2);
            }
         } else {
            mc = 0;
            sstabwid.p_ActiveColor = mc;
            if(!endsWith(sstabwid.p_ActiveCaption,' *')) {
               sstabwid.p_ActiveCaption=sstabwid.p_ActiveCaption' *';
            }
         }
      }
   } else {
      if ((substr(ptab->buffname,1) != '.') && ptab->modified) {
         sstabwid.p_ActiveTab = x;
         ptab->modified = false;
         // removing a * from the tooltip
         if (ptab->buffname != "") {
            sstabwid.p_ActiveToolTip = ptab->buffname;
         }
         // clearing the bitmap that indicated modified status
         sstabwid.p_ActiveColor = 0;
         if(endsWith(sstabwid.p_ActiveCaption,' *')) {
            sstabwid.p_ActiveCaption=substr(sstabwid.p_ActiveCaption,1,length(sstabwid.p_ActiveCaption)-2);
         }
      }
   }
}

/**
 * check every buffer for modified status once every second approx.<P>
 * gets called from the autosave call list
 */
void _update_mod_file_status(bool AlwaysUpdate=false)
{
   if (!_haveFileTabsWindow()) {
      return;
   }
   if (_mdi.p_child._no_child_windows()) {
      return;
   }
   if (!AlwaysUpdate && _idle_time_elapsed() < 250) {
      return;
   }
   sstabwid := get_tab_control();
   if (!sstabwid || !sstabwid.p_visible) {
      return;
   }
   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata==null) return;
   if (ptabsdata->pending_refresh) {
      //say("_update_mod_file_status: HANDLE PENDING REFRESH");
      refresh_file_tabs();
   }
   typeless time = ptabsdata->update_time;
   typeless time_now = _time('B');
   if (((time_now - time) < 0) || ((time_now-time) > 1000)) {
      if (!HaveBuffer()) {
         return;
      }
      gchange_orig := ptabsdata->change_refresh;
      ptabsdata->change_refresh = true;
      int temp_view_id;
      typeless orig_view_id = _create_temp_view(temp_view_id);
      typeless orig_buf_id = p_buf_id;


      TBFILETABS_FORM_INFO v;
      int i;
      foreach (i => v in gtbFileTabsFormList) {
         _nocheck _control ctlsstab1;
         sstabwid = i.ctlsstab1;
         curBufId := i._MDIGetActiveMDIChild();
         if (!curBufId) {
            curBufId=_mdi.p_child;
         }
         curBufId= curBufId.p_buf_id;
         if (!ptabsdata->buffid_order[curBufId]._isempty()) {
            sstabwid.p_ActiveTab = ptabsdata->buffid_order[curBufId].tabid;
         }

         int temp_tabid = sstabwid.p_ActiveTab;
         int x;
         if (orig_view_id != "") {
            for (x = 0; x<ptabsdata->tab_order._length(); ++x) {
               p_buf_id = ptabsdata->tab_order[x];
               _update_modified(sstabwid, x);
            }
         }
         if (sstabwid.p_NofTabs > 0) {
            sstabwid.p_ActiveTab = temp_tabid;
         }
      }

      if (orig_view_id != "") {
         p_buf_id = orig_buf_id;
         p_window_id=orig_view_id;
         _delete_temp_view(temp_view_id,true);
      }

      ptabsdata->change_refresh = gchange_orig;
      ptabsdata->update_time = _time('B');
   }
}


/**
 * Gets called when a buffer becomes hidden.
 */
void _cbmdibuffer_hidden_btabs(...)
{
   //say('p_buf_name being hidden: '_mdi.p_child.p_buf_name);
   if(!isEclipsePlugin() && p_HasBuffer) {

      // add this to our list of opened buffers as if we had closed it
      removeBufferFromFileTabArrays(p_buf_id);

      //No buf tabs in the plugin
      sstabwid := get_tab_control();
      if (!sstabwid) return;

      // bail out if there is a refresh pending
      tabs_data* ptabsdata = getFileTabsData();
      if (ptabsdata==null || ptabsdata->pending_refresh) {
         //say("_cbmdibuffer_hidden_btabs: SKIPPING");
         return;
      }

      if (sstabwid.have_tab(p_buf_id)) {
         _cbquit_tabs(p_buf_id, p_buf_name, p_DocumentName);
      }
   }
}

/**
 * Gets called when a hidden buffer becomes unhidden.
 */
void _cbmdibuffer_unhidden_btabs()
{
   // add it to our list as if it had just been opened
   addBufferToFileTabArrays(p_buf_id);

   //say('p_buf_name being unhidden: 'p_buf_name);
   sstabwid := get_tab_control();
   if (!sstabwid) return;

   // bail out if there is a refresh pending
   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata==null || ptabsdata->pending_refresh) {
      //say("_cbmdibuffer_unhidden_btabs: SKIPPING");
      return;
   }

   if (!(p_buf_flags&VSBUFFLAG_HIDDEN) && !sstabwid.have_tab(p_buf_id)) {
      //say('calling buffer add tabs from unhidden');
      _buffer_add_tabs(p_buf_id,p_buf_name);
   }

   return;
}


/*
    ------------------------------
           static functions
    ------------------------------
 */


/**
 * Gets a handle on the tab control.
 *
 * @return
 */
static int get_tab_control()
{
   if (!_haveFileTabsWindow()) return 0;
   formwid := _tbGetActiveFileTabsForm();
   if (!formwid) {
      return(0);
   }
   sstabwid := formwid._find_control('ctlsstab1');
   if (!sstabwid) {
      return(0);
   }

   return(sstabwid);
}

/**
 * Builds the buffer list/tab control from scratch.
 * The current object must be the tab control.
 *
 * @param start_buf_id
 *               p_buf_id to start with
 */
static void tab_refresh(int start_buf_id=-1)
{
   int i;
   TBFILETABS_FORM_INFO v;
   // clear out all our data, ready to start anew
   tabs_data* ptabsdata = getFileTabsData();

   // we might be set to not refresh this stuff
   if (ptabsdata -> do_not_refresh & FILE_TAB_NO_REFRESH) return;

   ptabsdata->change_refresh = true;
   ptabsdata->buffid_order._makeempty();
   ptabsdata->tab_order._makeempty();

   // we need to extract all the buffer ids
   // also build names for nameless buffers without them
   orig_view_id := p_window_id;
   int temp_view_id;
   _create_temp_view(temp_view_id);

   // we need to find our own starting buffer because one was not sent in
   if (start_buf_id<0) {

      // do we have any open buffers?  this might be super easy!
      if (!HaveBuffer()) {
         // this should mean that there are no user windows - just make the tabs invisible
         foreach (i => v in gtbFileTabsFormList) {
            sstabwid := i.ctlsstab1;
            sstabwid.p_visible = false;
         }
         ptabsdata->change_refresh = false;
         ptabsdata->pending_refresh = false;
         p_window_id=orig_view_id;
         return;
      } else {
         // we have at least one file open
         if (_mdi.p_child._no_child_windows()) {
            _mdi.p_child._next_buffer('NR');
         }

         start_buf_id=_mdi.p_child.p_buf_id;
         foreach (i => v in gtbFileTabsFormList) {
            sstabwid := i.ctlsstab1;
            sstabwid.p_visible = true;
         }
      }
   }

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id, true);
   orig_view_id=p_window_id;
   _open_temp_view("",temp_view_id,orig_view_id,'+bi 'start_buf_id);
   temp_name := "";
   foreach (i => v in gtbFileTabsFormList) {
      sstabwid := i.ctlsstab1;
      // add a tab - just one
      if (sstabwid.p_NofTabs == 0) {
         sstabwid.p_NofTabs++;
      }
   }

   // go through all the buffers and add them to our super duper list
   for (;;) {

      // determine the caption name
      if (p_DocumentName!="") {
         temp_name = createCaptionName(p_DocumentName);
      } else {
         temp_name = createCaptionName(p_buf_name);
      }

      // no name - we number it untitled and assign it a number that will mean nothing to the user
      if (temp_name == "") {
         temp_name = FILETABS_NO_NAME:+p_buf_id'>';
      }

      // load up all the data into our tabs_data
      ptabsdata->tab_order[ptabsdata->tab_order._length()] = p_buf_id;
      tabs_t *ptab = &ptabsdata->buffid_order[p_buf_id];
      ptab->buffname = createFullName(p_buf_name,p_DocumentName);
      ptab->caption  = temp_name;
      ptab->picture  = buff_tabs_get_picture(p_buf_name);
      ptab->modified = buff_tabs_get_modify(p_buf_name);
      ptab->tabid    = ptabsdata->tab_order._length()-1;

      // move along to the next buffer, please
      _next_buffer('NR');

      // are we at the end?
      if (p_buf_id==start_buf_id || ptabsdata->tab_order._length() == FILETABS_MAX_TABS) {
         // now we turn a data array into lovely clickable file tabs
         int status = write_tabs();
         if (status) {
            //say('status exception in write tabs');
         }
         break;
      }
   }

   // all done now, clean up our mess
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id, true);
   ptabsdata->change_refresh = false;
   ptabsdata->pending_refresh = false;
}

/**
 * Sorts the list based on filename and then buf_id.
 */
static void maybe_sort_tabs(tabs_data* ptabsdata)
{
   // don't sort an empty array
   if (ptabsdata == null) return;

   // what we do depends on our sorting method
   switch (def_file_tab_sort_order) {
   case FILETAB_ALPHABETICAL:
      // create some temporary data
      _str temp_data[] = null;

      // load up the buffer names into a temporary array so we can sort by them
      typeless buf_id, caption, buffname;
      for (x:=0;x<ptabsdata->tab_order._length();x++) {
         buf_id = ptabsdata->tab_order[x];

         caption = ptabsdata->buffid_order[buf_id].caption;
         buffname = ptabsdata->buffid_order[buf_id].buffname;

         // we add the buffname in - it contains the whole path - that way the secondary sort is by path and
         // files with the same name will always show up in the same order
         temp_data[x] = strip(caption' 'buffname' 'buf_id);
      }

      // DJB 01-22-2009 -- Always sort case-insensitive
      temp_data._sort('I');

      // now transfer the sort order over to our ptabsdata
      for (x=0;x<ptabsdata->tab_order._length();x++) {
         data := strip(temp_data[x]);
         lastSpace := lastpos(' ', data);
         if (lastSpace) {
            buf_id = substr(data, lastSpace);
            ptabsdata->buffid_order[buf_id].tabid = x;
            ptabsdata->tab_order[x] = buf_id;
         }
      }
      break;
   case FILETAB_MOST_RECENTLY_OPENED:
      i := 0;
      numBuffers := gfiletabs_buffers_opened._length();
      tabPos := 0;
      while (i < numBuffers) {
         // get the buffer id that was opened
         bufId := 0;
         // new buffers are added to gfiletabs_buffers_opened at the end
         switch (def_file_tab_new_file_position) {
         case FILETAB_NEW_FILE_ON_RIGHT:
         case FILETAB_NEW_FILE_TO_RIGHT:
            // open new files on right - so we go in order of the gfiletabs_buffers_opened array
            bufId = gfiletabs_buffers_opened[i];
            break;
         case FILETAB_NEW_FILE_ON_LEFT:
         case FILETAB_NEW_FILE_TO_LEFT:
            // open new files on left - go backwards of gfiletabs_buffers_opened array
            bufId = gfiletabs_buffers_opened[numBuffers - i - 1];
            break;
         }

         // we have to make sure that this buffer id is in the list - if we have more
         // files than the max amount of buffers, some might be missing
         if (!ptabsdata -> buffid_order[bufId]._isempty()) {
            // now put that one in the next position in our data
            ptabsdata->buffid_order[bufId].tabid = tabPos;
            ptabsdata->tab_order[tabPos] = bufId;

            // update our counters
            tabPos++;
         }

         i++;
      }
      break;
   case FILETAB_MOST_RECENTLY_VIEWED:
      if (!ptabsdata->tab_order._length()) break;

      int buffers[];
      _getBufferIdList(0, buffers);

      tabPos = 0;
      for (i = 0; i < buffers._length(); i++) {

         bufId := buffers[i];

         // we have to make sure that this buffer id is in the list - if we have more
         // files than the max amount of buffers, some might be missing
         if (!ptabsdata -> buffid_order[bufId]._isempty()) {
            ptabsdata -> buffid_order[bufId].tabid = tabPos;
            ptabsdata -> tab_order[tabPos] = bufId;

            // update the tab counter
            tabPos++;
         }
      }

      break;
	case FILETAB_MANUAL:
		sortFileTabsByArray();
      break;
   }

}

static bool isTabDataNull(tabs_t &ptab)
{
    return (ptab == null || (ptab.buffname == null && ptab.caption == null));
}

/**
 * Writes out the information from list
 * to the buffer tab toolbar.  Returns 0
 * if successful.
 *
 * @return
 */
static int write_tabs(bool doSort = true,int skip_sstabwid=-1)
{

   tabs_data* ptabsdata = getFileTabsData();
   // sort the tabs
   if (doSort) {
      maybe_sort_tabs(ptabsdata);
   }
   TBFILETABS_FORM_INFO v;
   int i;
   foreach (i => v in gtbFileTabsFormList) {
      sstabwid := i.ctlsstab1;
      if (skip_sstabwid==sstabwid) {
         continue;
      }
      gchange_orig := ptabsdata->change_refresh;
      ptabsdata->change_refresh = true;
      //int orig_tab = sstabwid.p_ActiveTab;
      // make sure that we have the correct number of tabs
      if (ptabsdata->tab_order._length() < FILETABS_MAX_TABS) {
         // may need to add tabs
         while (sstabwid.p_NofTabs < ptabsdata->tab_order._length()) {
            sstabwid.p_NofTabs++;
         }
         // may need to remove tabs
         while (sstabwid.p_NofTabs > ptabsdata->tab_order._length() && sstabwid.p_NofTabs > 1) {
            sstabwid._deleteActive();
         }
      } else {
         // may need to add tabs
         while (sstabwid.p_NofTabs < FILETABS_MAX_TABS) {
            sstabwid.p_NofTabs++;
         }
      }

      // Get the list of hidden file extensions
      hidden_extensions := " ":+_file_case(def_file_tabs_hidden_extensions):+" ";

      // now iterate through and create tabs
      last_buffname := "";
      for (x:=0;x<ptabsdata->tab_order._length();x++) {
         sstabwid.p_ActiveTab = x;
         if (ptabsdata->buffid_order[ptabsdata->tab_order[x]]._isempty()) {
            // if the index does not exist for some reason,
            // restore the original state and return an error
            ptabsdata->change_refresh = gchange_orig;
            return(1);
         }

         // get a pointer to this buffer's file information
         // this should never be null, but play it safe
         tabs_t *ptab = &ptabsdata->buffid_order[ptabsdata->tab_order[x]];
         if (isTabDataNull(*ptab)) continue;

         // check if this filename differs from the previous only
         // by file extension, then only display the extension
         // for this buffer.
         caption := ptab->caption;
         if (def_file_tabs_abbreviates_files && last_buffname!="" && ptab->buffname != "") {
            ext := _get_extension(ptab->buffname, true);
            if (ext != "") {
               fn1 := _strip_filename(last_buffname, 'e');
               fn2 := _strip_filename(ptab->buffname,'e');
               if (_file_eq(fn1, fn2)) {
                  caption = ext;
               }
            }
         }
         last_buffname = ptab->buffname;

         // Check if the file ends in one of the extensions which the User
         // has chosen to hide in order to conserve space
         if (def_file_tabs_hide_known_extensions &&
             caption==ptab->caption && ptab->buffname != "" &&
             _default_option(VSOPTION_TAB_TITLE) == VSOPTION_TAB_TITLE_SHORT_NAME) {
            ext := _file_case(_get_extension(ptab->buffname, false));
            if (pos(" "ext" ", hidden_extensions) > 0) {
               caption = _strip_filename(ptab->buffname, 'pe');
            }
         }

         // set up the caption and picture
         // set the caption to a blank at first, so we make sure and
         // resize the tab width according to the text
         sstabwid.p_ActiveCaption = "";
         sstabwid.p_ActiveCaption = caption;
         sstabwid.p_ActivePicture = ptab->picture;

         // set up the buffer color
         star := "";
         if (ptab->modified && ((substr(ptab->buffname,1,1)) != '.')) {
            typeless fg = 0x80000008;
            if ( _default_option(VSOPTION_TAB_MODIFIED_COLOR) ) {
               _str cfg = _default_color(CFG_MODIFIED_FILE_TAB);
               parse cfg with fg .;
               if(endsWith(sstabwid.p_ActiveCaption,' *')) {
                  sstabwid.p_ActiveCaption=substr(sstabwid.p_ActiveCaption,1,length(sstabwid.p_ActiveCaption)-2);
               }
            } else {
               if(!endsWith(sstabwid.p_ActiveCaption,' *')) {
                  sstabwid.p_ActiveCaption=sstabwid.p_ActiveCaption' *';
               }
            }
            sstabwid.p_ActiveColor = fg;
            star = " *";
         } else {
            sstabwid.p_ActiveColor = 0x80000008;
            if(endsWith(sstabwid.p_ActiveCaption,' *')) {
               sstabwid.p_ActiveCaption=substr(sstabwid.p_ActiveCaption,1,length(sstabwid.p_ActiveCaption)-2);
            }
         }

         // set the buffer tooltip to the full buffer name
         if (ptab->buffname != "") {
            sstabwid.p_ActiveToolTip = ptab->buffname :+ star;
         } else {
            sstabwid.p_ActiveToolTip = "";
         }
      }
      ptabsdata->change_refresh = gchange_orig;
   }

   //say('done writing the tabs');
   return(0);
}

/**
 * Handles the right mouse button click event.
 */
void ctlsstab1.rbutton_up()
{
   // get the current tab id
   tabs_data* ptabsdata = getFileTabsData();
   int tabi = mou_tabid();
   if (tabi < 0) {
      ptabsdata->clicked_tabid = -1;
      p_active_form.call_event(p_active_form, RBUTTON_UP);
      return;
   }
   // get the menu form
   int index=find_index("_bufftabs_menu",oi2type(OI_MENU));
   if (!index) {
      ptabsdata->clicked_tabid = -1;
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');

   ptabsdata->clicked_tabid = tabi;
   bufferId := ptabsdata->tab_order[ptabsdata->clicked_tabid];
   tabs_t *ptab = &ptabsdata->buffid_order[bufferId];
   _str buf_name = ptab->buffname;
   if (buf_name == "") {
      buf_name = ptab->caption;
   }
   file_name_only := _prepare_filename_for_menu(_strip_filename(buf_name, 'P'));
   buf_name_empty := (ptab->buffname == "") ? true : false;

   // build the menu
   itemPos := 0;
   _menu_insert(menu_handle,itemPos++,MF_ENABLED,
                "&Save "file_name_only,"buff-menu-save","","",'Save 'buf_name);
   _menu_insert(menu_handle,itemPos++,MF_ENABLED,
                "&Close "file_name_only,"buff-menu-close","","",'Close 'buf_name);
   if (ptab->modified) {
      _menu_insert(menu_handle,itemPos++,MF_ENABLED,
                   "&Diff "file_name_only,"diff -bi1 -d2 "bufferId" "_maybe_quote_filename(buf_name),"","",'Diff 'buf_name);
   }
   _menu_insert(menu_handle,itemPos++,MF_ENABLED,
                "Add "file_name_only" to project...","project_add_files_prompt_project "buf_name,"","",'Add 'buf_name' to project');
   _menu_insert(menu_handle,itemPos++,0,'-');
   _menu_insert(menu_handle,itemPos++,MF_ENABLED,
                "Save A&ll","buff-menu-save all","","",'Save all files');
   _menu_insert(menu_handle,itemPos++,MF_ENABLED,
                "Close &All","buff-menu-close all","","",'Close all files');
   _menu_insert(menu_handle,itemPos++,MF_ENABLED,
                "Close &Others","buff-menu-close others","","",'Close all but 'buf_name);
   _menu_insert(menu_handle,itemPos++,MF_ENABLED,
                "&List Open Files...","list-buffers","","",'Lists all open buffers.');
   _menu_insert(menu_handle,itemPos++,0,'-');
   if (ptabsdata->clicked_tabid != p_ActiveTab) {
      ptab = &ptabsdata->buffid_order[ptabsdata->tab_order[p_ActiveTab]];
      buf_name = ptab->buffname;
      if (buf_name == "") {
         buf_name = ptab->caption;
      }
      _menu_insert(menu_handle,itemPos++,MF_ENABLED,
                   "Split &Horizontal with "buf_name,"buff-menu-split H","","",'Split Horizontal with 'buf_name);
      _menu_insert(menu_handle,itemPos++,MF_ENABLED,
                   "Split &Vertical with "buf_name,"buff-menu-split V","","",'Split Vertical with 'buf_name);
   } else {
      _menu_insert(menu_handle,itemPos++,MF_ENABLED,
                   "Split &Horizontal","buff-menu-split H","","",'Split Horizontal');
      _menu_insert(menu_handle,itemPos++,MF_ENABLED,
                   "Split &Vertical","buff-menu-split V","","",'Split Vertical');
   }
   _menu_insert(menu_handle,itemPos++,0,'-');
   _menu_insert(menu_handle,itemPos++,(buf_name_empty) ? MF_GRAYED : MF_ENABLED,
                "Copy &Full Path to Clipboard","buff-menu-clipboard","","",'Copy path name to clipboard.');

   _menu_insert(menu_handle,itemPos++,0,'-');
   // insert file tab sort order
   subMenuCategory := 'file tab sort orders';
   subMenuItemPos := 0;
   _menu_insert(menu_handle,itemPos++,MF_ENABLED|MF_SUBMENU,
                "File tab sort order","",subMenuCategory,"","Select the order in which file tabs should appear");

   subMenuHandle := 0;
   if(!_menu_find(menu_handle, subMenuCategory, subMenuHandle, auto menuPos, "C")) {

      int targetMenuHandle;
      _menu_get_state(subMenuHandle, menuPos, 0, "P", "", targetMenuHandle, "", "", "");

      _menu_insert(targetMenuHandle,subMenuItemPos++,MF_ENABLED|(def_file_tab_sort_order==FILETAB_ALPHABETICAL ? MF_CHECKED:MF_UNCHECKED),
                   "Alphabetical", "set-file-tab-sort-order "FILETAB_ALPHABETICAL, "","","Sort file tabs in alphabetical order by name");
      _menu_insert(targetMenuHandle,subMenuItemPos++,MF_ENABLED|(def_file_tab_sort_order==FILETAB_MOST_RECENTLY_OPENED ? MF_CHECKED:MF_UNCHECKED),
                   "Most recently opened", "set-file-tab-sort-order "FILETAB_MOST_RECENTLY_OPENED, "","","Sort file tabs by order in which they were opened");
      _menu_insert(targetMenuHandle,subMenuItemPos++,MF_ENABLED|(def_file_tab_sort_order==FILETAB_MOST_RECENTLY_VIEWED ? MF_CHECKED:MF_UNCHECKED),
                   "Most recently viewed", "set-file-tab-sort-order "FILETAB_MOST_RECENTLY_VIEWED, "","","Sort file tabs by order in which they were viewed");
      _menu_insert(targetMenuHandle,subMenuItemPos++,MF_ENABLED|(def_file_tab_sort_order==FILETAB_MANUAL ? MF_CHECKED:MF_UNCHECKED),
                   "Manual", "set-file-tab-sort-order "FILETAB_MANUAL, "","","Sort file tabs by dragging and dropping them in order manually");
   }

   if (def_file_tab_sort_order == FILETAB_MANUAL) {
      // insert file tab sort order
      subMenuCategory = 'new file tab positions';
      subMenuItemPos = 0;
      _menu_insert(menu_handle, itemPos++,
                   ((def_file_tab_sort_order==FILETAB_MOST_RECENTLY_OPENED || def_file_tab_sort_order==FILETAB_MANUAL) ? MF_ENABLED : MF_GRAYED) | MF_SUBMENU,
                   "New file tab position","",subMenuCategory,"","Specify whether to open new tabs on the right or the left of the file tabs toolbar");

      subMenuHandle = 0;
      if(!_menu_find(menu_handle, subMenuCategory, subMenuHandle, menuPos, "C")) {

         int targetMenuHandle;
         _menu_get_state(subMenuHandle, menuPos, 0, "P", "", targetMenuHandle, "", "", "");

         _menu_insert(targetMenuHandle,subMenuItemPos++,MF_ENABLED|(def_file_tab_new_file_position==FILETAB_NEW_FILE_ON_RIGHT ? MF_CHECKED:MF_UNCHECKED),
                      "New files on right", "set-file-tabs-new-file-position "FILETAB_NEW_FILE_ON_RIGHT,
                      "","","New file tabs appear on the right side of the file tabs toolbar.");

         _menu_insert(targetMenuHandle,subMenuItemPos++,MF_ENABLED|(def_file_tab_new_file_position==FILETAB_NEW_FILE_ON_LEFT ? MF_CHECKED:MF_UNCHECKED),
                      "New files on left", "set-file-tabs-new-file-position "FILETAB_NEW_FILE_ON_LEFT,
                      "","","New file tabs appear on the left side of the file tabs toolbar.");

         _menu_insert(targetMenuHandle,subMenuItemPos++,MF_ENABLED|(def_file_tab_new_file_position==FILETAB_NEW_FILE_TO_RIGHT ? MF_CHECKED:MF_UNCHECKED),
                      "New files to right of current file", "set-file-tabs-new-file-position "FILETAB_NEW_FILE_TO_RIGHT,
                      "","","New file tabs appear to the right of the current file in the file tabs toolbar.");

         _menu_insert(targetMenuHandle,subMenuItemPos++,MF_ENABLED|(def_file_tab_new_file_position==FILETAB_NEW_FILE_TO_LEFT ? MF_CHECKED:MF_UNCHECKED),
                      "New files to left of current file", "set-file-tabs-new-file-position "FILETAB_NEW_FILE_TO_LEFT,
                      "","","New file tabs appear to the left of the current file in the file tabs toolbar.");
      }
   }

   _menu_insert(menu_handle,itemPos++,MF_ENABLED|MF_UNCHECKED,
                "Toggle File Tab Orientation","buff-menu-toggle-orientation","","",'Toggle orientation of file tabs within the tool window');
   _menu_insert(menu_handle,itemPos++,(def_file_tab_sort_order==FILETAB_ALPHABETICAL ? MF_ENABLED:MF_GRAYED)|(def_file_tabs_abbreviates_files? MF_CHECKED:MF_UNCHECKED),
                "Abbreviate Similar Files","buff-menu-toggle-abbrev","","",'Abbreviate file names that differ only by extension');
   _menu_insert(menu_handle,itemPos++,MF_ENABLED|(def_file_tabs_uses_pictures? MF_CHECKED:MF_UNCHECKED),
                "Show Pictures","buff-menu-toggle-pics","","",'Show pictures for Build Window, Search Results, File Manager, etc.');
   // 5/6/2013 - rb
   // Note this menu item was removed in v18 to be consistent with MDI document tabs
   // which now share the same option. The setting is in the Options panel and I really
   // do not believe you need to be able to toggle this from the tool window.
   //_menu_insert(menu_handle,itemPos++,MF_ENABLED|(document_tabs_closable()? MF_CHECKED:MF_UNCHECKED),
   //             "Show close buttons","buff-menu-toggle-closable","","",'Show close buttons on individual tabs.');

   // Show the menu.
   x := 100;
   y := 100;
   x=mou_last_x('M')-x;y=mou_last_y('M')-y;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   int flags=VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   int status=_menu_show(menu_handle,flags,x,y);
   _menu_destroy(menu_handle);
   // set the focus back
   if (_mdi.p_child._no_child_windows()==0) {
      _mdi.p_child._set_focus();
   }
}

/*
The "s-lbutton_down" and lbutton_up pair allow shift-left click closing of file
tabs.
*/
void ctlsstab1."s-lbutton_down"()
{
   tabs_data* ptabsdata = getFileTabsData();
   ptabsdata->shiftLeftTabID = mou_tabid();
}
void ctlsstab1.lbutton_up()
{
   if (p_NofTabs) {
      /*
         If we click on the active tab of an MDI window with no child edit
         windows, we don't get an on_change event BECAUSE the current tab
         didn't change.

         Here we check if there are no edit windows and do the on_change
         code.
      */
      int child_wid=_MDICurrentChild(0);
      if (!child_wid) {
         tabs_data* ptabsdata = getFileTabsData();
         if ((ptabsdata->tab_order._length() < p_ActiveTab)) {
            // invaild tab somehow - need to rebuild
            //say('about to rebuild the tabs');
            tab_refresh();
         } else {
            int status = p_window_id.edit('+Q +BI ' :+ (ptabsdata->tab_order[p_ActiveTab]),EDIT_DEFAULT_FLAGS|EDIT_NOEXITSCROLL);
            if (status) {
               tab_refresh();
            }
         }
      }
   }
   int tabi = mou_tabid();
   tabs_data* ptabsdata = getFileTabsData();
   if (tabi != ptabsdata->shiftLeftTabID) {
      ptabsdata->shiftLeftTabID = -1;
      ptabsdata->clicked_tabid = -1;
      return;
   }
   ptabsdata->shiftLeftTabID = -1;
   ptabsdata->clicked_tabid = tabi;
   buff_menu_close();
}

void ctlsstab1.mbutton_up()
{
   tabs_data* ptabsdata = getFileTabsData();
   ptabsdata->clicked_tabid = -1;
   int tabi = mou_tabid();
   if( tabi >= 0 ) {
      ptabsdata->clicked_tabid = tabi;
      buff_menu_close();
   }
}

/**
 * Command for the right-click buff tabs menu, saves the clicked tab.
 *
 * * @param options   <ul><li>empty string => just save the current tab
 *                      <li>"all" => save all,
 *
 * @return
 */
_command buff_menu_save(_str option="") name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
   }
   sstabwid := get_tab_control();
   if (!sstabwid) return 0;

   // make sure the file tabs are up-to-date
   tabs_data* ptabsdata =getFileTabsData();
   if (ptabsdata==null) return 0;
   if (ptabsdata->pending_refresh) {
      refresh_file_tabs();
   }

   status := 0;
   if (option=='all') {
      int i,n = ptabsdata->tab_order._length();
      for (i=n-1; i>=0; --i) {
         //if (buf_name==".process") continue;
         int buf_id = ptabsdata->tab_order[i];
         typeless buf_flags = _BufQFlags(buf_id);
         if (buf_flags & (VSBUFFLAG_THROW_AWAY_CHANGES|VSBUFFLAG_HIDDEN)) {
            continue;
         }
         tabs_t *ptab = &ptabsdata->buffid_order[ptabsdata->tab_order[i]];
         _str buf_name = ptab->buffname;
         if (buf_name == "") {
            buf_name = ptab->caption;
            typeless result = _message_box(nls("Save changes to '%s'?",buf_name),"",MB_ICONQUESTION|MB_YESNO);
            if (result == IDNO) {
               continue;
            }
         }

         typeless ModifyFlags;
         parse buf_match(ptab->buffname, 1, 'vx') with . ModifyFlags .;
         if ((int)ModifyFlags & 1) {
            status = _save_non_active(buf_name, false, 0);
            if (status == COMMAND_CANCELLED_RC) {
               break;
            }
         }
      }
      return (status);
   }
   if (option=="" && ptabsdata->clicked_tabid >= 0) {
      tabs_t *ptab = &ptabsdata->buffid_order[ptabsdata->tab_order[ptabsdata->clicked_tabid]];
      _str buf_name = ptab->buffname;
      if (buf_name == "") {
         buf_name = ptab->caption;
      }
      status=_save_non_active(buf_name, false, 0);
      ptabsdata->clicked_tabid = -1;
      return (status);
   }
   return (status);
}

/**
 * Command for the right-click buff tabs menu, closes the clicked tab.
 *
 * @param options   <ul><li>empty string => just close the current tab
 *                      <li>"all" => close all,
 *                      <li>"others" => close all but the current tab</ul>
 *
 * @return
 */
_command buff_menu_close(_str option="") name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
   }
   sstabwid := get_tab_control();
   if (!sstabwid) return 0;

   // make sure the file tabs are up-to-date
   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata==null) return 0;
   if (ptabsdata->pending_refresh) {
      refresh_file_tabs();
   }

   if (option!="") {
      int old_def_actapp = def_actapp;
      def_actapp &= ~ACTAPP_AUTORELOADON;
      int i,n = ptabsdata->tab_order._length();
      for (i=n-1; i>=0; --i) {
         if (ptabsdata->clicked_tabid >= 0 && i == ptabsdata->clicked_tabid && option=='others') {
            continue;
         }
         tabs_t *ptab = &ptabsdata->buffid_order[ptabsdata->tab_order[i]];
         _str buf_name = ptab->buffname;
         if (buf_name == "") {
            buf_name = ptab->caption;
         }
         int buf_id = ptabsdata->tab_order[i];
         int status = _save_non_active(buf_name, true);
         if (status == COMMAND_CANCELLED_RC) {
            break;
         }
         if (!status && sstabwid.have_tab(buf_id)){ // manual removal
            _cbquit_tabs(buf_id, buf_name);
         }
      }
      def_actapp = old_def_actapp;
   }
   if (option=="" && ptabsdata->clicked_tabid >= 0) {
      tabs_t *ptab = &ptabsdata->buffid_order[ptabsdata->tab_order[ptabsdata->clicked_tabid]];
      _str buf_name = ptab->buffname;
      if (buf_name == "") {
         buf_name = ptab->caption;
      }
      int buf_id = ptabsdata->tab_order[ptabsdata->clicked_tabid];
      int status=_save_non_active(buf_name, true);
      if (!status && sstabwid.have_tab(buf_id)) { // manual removal
         _cbquit_tabs(buf_id, buf_name);
      }
      ptabsdata->clicked_tabid = -1;
      return(status);
   }
   return(0);
}

/**
 * Command for the right-click buff tabs menu, creates split
 * window with the clicked tab.
 *
 * @param options   <ul><li>empty string => just close the current tab
 *                      <li>"all" => close all,
 *                      <li>"others" => close all but the current tab</ul>
 *
 * @return
 */
_command void buff_menu_split(_str option = 'H') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return;
   }
   sstabwid := get_tab_control();
   if (!sstabwid) return;

   // make sure the file tabs are up-to-date
   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata==null) return;
   if (ptabsdata->pending_refresh) {
      refresh_file_tabs();
   }

   buffer_name := "";
   int buf_id = ptabsdata->tab_order[ptabsdata->clicked_tabid];
   if (ptabsdata->clicked_tabid != p_ActiveTab) {
      _str clicked_buf_name = ptabsdata->buffid_order[ptabsdata->tab_order[ptabsdata->clicked_tabid]].buffname;
      if (clicked_buf_name != _mdi.p_child.p_buf_name) {
         buffer_name = "+bi "ptabsdata->tab_order[ptabsdata->clicked_tabid];
      }
   }

   int orig_wid;
   get_window_id(orig_wid);
   activate_window(_mdi.p_child.p_window_id);
   if (option == 'H') {
      hsplit_window(buffer_name);
   } else {
      vsplit_window(buffer_name);
   }

   activate_window(orig_wid);
   ptabsdata->clicked_tabid = -1;
}

/**
 * Command for right-click command to copy file name and/or path
 * to clipboard.
 *
 * @param options   <ul><li>options to pass to strip_filename
 *                  command
 *
 * @return
 */
_command void buff_menu_clipboard(_str option="") name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return;
   }
   sstabwid := get_tab_control();
   if (!sstabwid) return;

   // make sure the file tabs are up-to-date
   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata==null) return;
   if (ptabsdata->pending_refresh) {
      refresh_file_tabs();
   }

   buf_id := ptabsdata->tab_order[ptabsdata->clicked_tabid];
   buffer_name := ptabsdata->buffid_order[buf_id].buffname;
   if (buffer_name == "" || buffer_name == null) {
      return;
   }
   if (option != "") {
      buffer_name = _strip_filename(buffer_name, option);
   } else {
      buffer_name = _maybe_quote_filename(buffer_name);
   }
   _copy_text_to_clipboard(buffer_name);
   ptabsdata->clicked_tabid = -1;
}

_command void buff_menu_toggle_abbrev() name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   def_file_tabs_abbreviates_files = !def_file_tabs_abbreviates_files;
   if (_haveFileTabsWindow()) {
      refresh_file_tabs();
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
   // Setting p_ClosableTabs forces refresh of document tabs
   _mdi.p_ClosableTabs = _mdi.p_ClosableTabs;
}

_command void buff_menu_toggle_pics() name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   def_file_tabs_uses_pictures = !def_file_tabs_uses_pictures;
   if (_haveFileTabsWindow()) {
      refresh_file_tabs();
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

_command void buff_menu_toggle_closable() name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return;
   }
   document_tabs_closable(!document_tabs_closable());
}

_command void buff_menu_toggle_orientation() name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return;
   }
   // check if file tabs are currently displayed
   formwid := _tbGetActiveFileTabsForm();
   if (!formwid) return;

   // find the index of the object
   sstab := find_index('_tbbufftabs_form.ctlsstab1', OBJECT_TYPE);
   if (!sstab) return;
   // hide the file tabs while we change it up
   toggle_bufftabs();

   // change the orientation
   if (sstab.p_Orientation == SSTAB_OTOP) {
      sstab.p_Orientation = SSTAB_OBOTTOM;
   } else {
      sstab.p_Orientation = SSTAB_OTOP;
   }

   _config_modify_flags(CFGMODIFY_RESOURCE);

   // now show again, it's all different!
   toggle_bufftabs();
}

void buff_maybe_reorient(int oldSide, int newSide)
{
   // if we are not changing sides, then we don't care
   if (oldSide == newSide) return;

   // it must be top or bottom, or it's just confusing
   if (newSide != DOCKINGAREA_BOTTOM && newSide != DOCKINGAREA_TOP) return;

   // find the index of the object
   sstab := find_index('_tbbufftabs_form.ctlsstab1', OBJECT_TYPE);
   if (!sstab) return;

   // if we were not previously docked, then go to whatever the default is
   if (oldSide == 0) {
      if (newSide == DOCKINGAREA_BOTTOM) {
         sstab.p_Orientation = SSTAB_OBOTTOM;
      } else {
         sstab.p_Orientation = SSTAB_OTOP;
      }
   } else {
      // make sure we hadn't changed from the default wherever we were before
      if (oldSide == DOCKINGAREA_BOTTOM && sstab.p_Orientation == SSTAB_OBOTTOM) {
         sstab.p_Orientation = SSTAB_OTOP;
      } else if (oldSide == DOCKINGAREA_TOP && sstab.p_Orientation == SSTAB_OTOP) {
         sstab.p_Orientation = SSTAB_OBOTTOM;
      }
   }
   _config_modify_flags(CFGMODIFY_RESOURCE);
}

/**
 * Force a refresh of the file tabs toolbar.
 */
_command void refresh_file_tabs() name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return;
   }
   tab_refresh();
}

/**
 * Activates the next buffer tab.  Wraps around at the end.
 */
_command void next_buff_tab() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_LINEHEX)
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return;
   }
   sstabwid := get_tab_control();
   if ( !sstabwid ) {
      next_doc_tab();
      return;
   }

   // make sure the file tabs are up-to-date
   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata==null) return;
   if (ptabsdata->pending_refresh) {
      refresh_file_tabs();
   }

   // if we are in Most Recently Viewed mode, we do not want to reorder
   // the tabs - doing so will just cause next_buff_tab to go back and
   //  forth between the same two tabs ALL DAY LONG
   prevRefreshValue := ptabsdata -> do_not_refresh;
   if (def_file_tab_sort_order == FILETAB_MOST_RECENTLY_VIEWED) {
      ptabsdata -> do_not_refresh |= FILE_TAB_NO_REFRESH;
   }

   // tabs go from 0...sstabwid.p_NofTabs -1
   if (sstabwid.p_ActiveTab == (sstabwid.p_NofTabs - 1)) {
      // on last tab
      sstabwid.p_ActiveTab = 0;
   } else {
      sstabwid.p_ActiveTab++;
   }

   // set this back, please
   if (def_file_tab_sort_order == FILETAB_MOST_RECENTLY_VIEWED) {
      ptabsdata -> do_not_refresh = (prevRefreshValue | FILE_TAB_NO_REFRESH_ON_FOCUS);
   }
}

/**
 * Activates the previous buffer tab.  Wraps around at the end.
 */
_command void prev_buff_tab() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_LINEHEX)
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return;
   }
   sstabwid := get_tab_control();
   if ( !sstabwid ) {
      prev_doc_tab();
      return;
   }

   // make sure the file tabs are up-to-date
   tabs_data* ptabsdata = getFileTabsData();
   if (ptabsdata==null) return;
   if (ptabsdata->pending_refresh) {
      refresh_file_tabs();
   }

   // if we are in Most Recently Viewed mode, we do not want to reorder
   // the tabs - doing so will just cause next_buff_tab to go back and
   //  forth between the same two tabs ALL DAY LONG
   prevRefreshValue := ptabsdata -> do_not_refresh;
   if (def_file_tab_sort_order == FILETAB_MOST_RECENTLY_VIEWED) {
      ptabsdata -> do_not_refresh |= FILE_TAB_NO_REFRESH;
   }

   // tabs go from 0...sstabwid.p_NofTabs -1
   if (sstabwid.p_ActiveTab == 0) {
      sstabwid.p_ActiveTab = sstabwid.p_NofTabs - 1;
   } else {
      sstabwid.p_ActiveTab--;
   }

   // set this back, please
   if (def_file_tab_sort_order == FILETAB_MOST_RECENTLY_VIEWED) {
      ptabsdata -> do_not_refresh = (prevRefreshValue | FILE_TAB_NO_REFRESH_ON_FOCUS);
   }
}

/**
 * Returns true if a tab exists that matches the designated buffer id.
 * The current object must be the tab control for the File Tabs toolbar.
 *
 * @return
 */
static bool have_tab(int buff_id)
{
// say('in have_tab - looking for 'buff_id);
   tabs_data* ptabsdata = getFileTabsData();
   result := false;
   if (ptabsdata->buffid_order[buff_id]._isempty()) {
      // could potentially try searching all the tabs here
      //say('could not find the buff id in the array');
      return(result);
   }
   _str buffname = ptabsdata->buffid_order[buff_id].buffname;
   if (buffname == "" || buffname == null) {
      buffname = ptabsdata->buffid_order[buff_id].caption;
      if (buffname == "" || buffname == null) return false;
   }

   gchange_orig := ptabsdata->change_refresh;
   ptabsdata->change_refresh = true;
   orig_tabid := p_ActiveTab;
   p_ActiveTab = ptabsdata->buffid_order[buff_id].tabid;

   _str tabname = p_ActiveToolTip;
   if (tabname == "") {
      tabname = p_ActiveCaption;
   }
   if (_file_eq(tabname,buffname) ||
       _file_eq(tabname,buffname' *')) {
      //say('setting true');
      result = true;
   } else {
      //say('setting false');
      result = false;
   }
   p_ActiveTab = orig_tabid;
   ptabsdata->change_refresh = gchange_orig;
   return(result);
}

/*
    ------------------------------
           debug stuff
    ------------------------------
 */

void buff_detect_corruption()
{
   sstabwid := get_tab_control();
   if (!sstabwid) {
      return;
   }

   // go through each tab and extract the info - we are really just
   // trying to put everything in order that the tabs are already
   _str found:[];
   for (tabPos := 0; tabPos < sstabwid.p_NofTabs; ++tabPos) {
      // get the tooltip info - it contains the entire path
      tabToolTip := sstabwid.sstGetTabToolTip(tabPos);

      SSTABCONTAINERINFO info;
      _getTabInfo(tabPos,info);

      if (tabToolTip != "") {
         // remove any '*' signifying a modified tab
         tabToolTip = strip(tabToolTip, 'T', '*');
         tabToolTip = strip(tabToolTip, 'B', ' ');
         tabToolTip = _file_case(tabToolTip);

         // we don't want any duplicates
         if (found._indexin(tabToolTip)) {
            //_message_box("CORRUPTION!");
            _StackDump();
            break;
         }
         found:[tabToolTip] = tabToolTip;
      }
   }
}

/**
 * For debug purposes, prints out summary.
 */
_command void buff_debug() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return;
   }
   sstabwid := get_tab_control();
   if (!sstabwid) {
      say("buff_debug: no file tabs");
      return;
   }
   say('number of tabs: 'sstabwid.p_NofTabs);
   say('current tab: 'sstabwid.p_ActiveTab);
   say('current tab caption: 'sstabwid.p_ActiveCaption);
   say('current tab tooltip: 'sstabwid.p_ActiveToolTip );
   say('length: 'getFileTabsData()->tab_order._length());
}

_command void buff_debug_tab_info(_str msg = "") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return;
   }
   if (msg != "") {
      dsay('--->'upcase(msg)'<---');
   }

   sstabwid := get_tab_control();
   if (!sstabwid) {
      dsay("   buff_debug_tab_info: no file tabs");
      return;
   }

   // now go through each tab and extract the info
   SSTABCONTAINERINFO info;
   for (tabPos := 0; tabPos < sstabwid.p_NofTabs; ++tabPos) {
      // get the tooltip info - it contains the entire path
      sstabwid._getTabInfo(tabPos,info);
      dsay('---');
      _dump_var(info);
   }
}

/**
 * for debug purposes only, lists all of the data.
 */
_command void buff_reportarrays(_str debug = "") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return;
   }
   dsay('--------------------------------------------');
   if (debug != "") dsay(debug);
   sstabwid := get_tab_control();
   if (!sstabwid) {
      dsay("buff_debug: no file tabs");
      return;
   }
   dsay('--------------------------------------------');
   if (debug != "") say(debug);
   dsay('The current state of the data is as follows:');
   tabs_data* ptabsdata = getFileTabsData();

   if (!ptabsdata->tab_order._length()) {
      dsay('   no tab data');
   } else {
      for (x:=0; x<ptabsdata->tab_order._length(); x++) {
         dsay('tab id: 'ptabsdata->buffid_order[ptabsdata->tab_order[x]].tabid);
         dsay('   buff id:'ptabsdata->tab_order[x]);
         dsay('   buff name:'ptabsdata->buffid_order[ptabsdata->tab_order[x]].buffname);
      }
   }
   dsay('Manual Buffer Order');
   for (i := 0; i < gManualTabsOrder._length(); i++) {
      dsay('   'i' - 'gManualTabsOrder[i]);
   }

   dsay('Tab Info');
   SSTABCONTAINERINFO info;
   // now go through each tab and extract the info
   for (tabPos := 0; tabPos < sstabwid.p_NofTabs; ++tabPos) {
      // get the tooltip info - it contains the entire path
      sstabwid._getTabInfo(tabPos,info);
      dsay('---');
      _dump_var(info);
   }
   dsay('--------------------------------------------');
}

