////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50281 $
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
#include "eclipse.sh"
#include "slick.sh"
#include "search.sh"
#include "tagsdb.sh"
#import "annotations.e"
#import "bookmark.e"
#import "cbrowser.e"
#import "clipbd.e"
#import "context.e"
#import "eclipse.e"
#import "files.e"
#import "guifind.e"
#import "listbox.e"
#import "main.e"
#import "mfsearch.e"
#import "moveedge.e"
#import "picture.e"
#import "pushtag.e"
#import "search.e"
#import "seldisp.e"
#import "sstab.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagwin.e"
#import "tbfind.e"
#import "toolbar.e"
#require "se/search/SearchResults.e"
#endregion

defeventtab    _tbsearch_form;
static int     grep_buffers[];
static _str    grep_caption:[];
static int     last_grep_id;
static int     current_grep_id;

_tbsearch_form.'F12'()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   }
}

_tbsearch_form.'C-S-PAD-SLASH'()
{
   if (isEclipsePlugin()) {
      collapse_all();
   }
}

_tbsearch_form.'C-M'()
{
   if (isEclipsePlugin()) {
      eclipse_maximize_part();
   }
}

definit()
{
   _reset_grep_buffers();
}

int _srg_search_results(_str option='',_str info='')
{
   if (option=='R' || option=='N') {
      grep_buffers._makeempty();
      grep_caption._makeempty();
      _str grep_id;
      parse info with grep_id info;
      while (grep_id != '') {
         if (grep_id < def_max_search_results_buffers) {
            int id = grep_buffers._length();
            grep_buffers[id] = (int)grep_id;
            grep_caption:[grep_id] = "";
            last_grep_id = (int)grep_id;
         }
         parse info with grep_id info;
      }
      if (grep_buffers._isempty()) {
         grep_buffers[0] = 0;
         grep_caption:[0] = "";
         grep_buffers[1] = 1;
         grep_caption:[1] = "";
         last_grep_id = 1;
      }
   } else {
      _str line = '';
      int i;
      for (i = 0; i < grep_buffers._length(); ++i) {
         if (length(line)) {
            strappend(line, ' ');
         }
         strappend(line, grep_buffers[i]);
      }
      insert_line('SEARCH_RESULTS: ':+line);
   }
   return(0);
}

void toolShowSearch(int grep_id = -1)
{
   int form_id = activate_toolbar('_tbsearch_form', '');
   if (form_id && (grep_id >= 0) && (grep_id < last_grep_id)) {
      _show_grep_buffer(grep_id);
   }
}

void toolSearchScroll()
{
   /*
      If the search results window is already displayed, scroll to the end.
   */
   _str ctlname=_get_active_grep_view();
   if (ctlname!='') {
      int wid=_find_object('_tbsearch_form.'ctlname,'N');
      if (wid) {
         wid.bottom(); wid._begin_line();
      }
   }
}

void updateSearchToolWindow()
{
   int form_id = _find_object("_tbsearch_form","n");
   if (form_id) {
      call_event(form_id.p_window_id, ON_LOAD);
   }
}

void _tbsearch_form.on_create()
{
   _search_tab.p_DocumentMode = true;
}

void _tbsearch_form.on_load()
{
   int i;
   int tab_id = _find_object("_tbsearch_form._search_tab", "n");
   while (tab_id.p_NofTabs > 0)  tab_id._deleteActive();
   for (i = 0; i < grep_buffers._length(); ++i) _create_grep_buffer(tab_id, grep_buffers[i]);
   if(0 == (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
       p_active_form.p_enabled = false;
   }

   typeless last_tab = _retrieve_value("_tbsearch_form.last_tab");
   if (isinteger(last_tab)) {
      tab_id.p_ActiveTab = last_tab;
   }

   // set focus on search results editor control
   int cid = tab_id._getActiveWindow();
   typeless grep_id;
   parse cid.p_name with "_search_container" grep_id;
   int wid=_find_object('_tbsearch_form._search'grep_id,'N');
   if (wid) {
      wid._set_focus();
   }
   if (isEclipsePlugin() && current_grep_id != null && current_grep_id >= 0) {
      _show_grep_buffer(current_grep_id);
   }
}

int _eclipse_getSearchQFormWid()
{
   int formWid = _find_object(ECLIPSE_SEARCHOUTPUT_CONTAINERFORM_NAME,'n');
   if (formWid > 0) {
      return formWid.p_child;
   }
   return 0;
}

void _tbsearch_form.on_destroy()
{
   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id,ON_DESTROY,'2');

   int last_tab = _search_tab.p_ActiveTab;
   _append_retrieve(0, last_tab, "_tbsearch_form.last_tab");
}

void _tbsearch_form.on_resize()
{
   int old_wid;
   // RGH - 4/26/2006
   // For the plugin, resize the SWT container then do the normal resize
   if (isEclipsePlugin()) {
      int searchForm = _eclipse_getSearchQFormWid();
      if(!searchForm) return;
      old_wid = p_window_id;
      // RGH - 4/26/2006
      // Switch p_window_id to the SWT container so we can access the right controls
      p_window_id = searchForm;
      eclipse_resizeContainer(searchForm);
   }
   int clientW = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   int clientH = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   _search_tab.p_width = clientW - 2 * _search_tab.p_x;
   _search_tab.p_height = clientH - _search_tab.p_y - _search_tab.p_x;
   // resize editor controls within each active tab
   int first_child = _search_tab.p_child;
   int child = first_child;
   do {
      typeless grep_id;
      parse child.p_name with "_search_container" grep_id;
      int edit_wid = _find_control( '_search'grep_id );
      if ( edit_wid ) {
         edit_wid.p_width = child.p_width;
         edit_wid.p_height = child.p_height;
      }
      child = child.p_next;
   } while ( child != first_child );

   // RGH - 4/26/2006
   // Switch back p_window_id
   if (isEclipsePlugin()) {
      p_window_id = old_wid;
   }
}

void _tbsearch_form.ESC()
{
   _tbDismiss(p_active_form);
}

static void _hide_tab(int tab_index)
{
   int tab_id = _find_object("_tbsearch_form._search_tab", "n");
   int orig_tab = tab_id.p_ActiveTab;
   tab_id.p_ActiveTab = tab_index;

   // delete from active tab list
   int cid = tab_id._getActiveWindow();
   int i;
   typeless grep_id;
   parse cid.p_name with "_search_container" grep_id;
   for (i = 0; i < grep_buffers._length(); ++i) {
      if (grep_buffers[i] == grep_id) {
         grep_buffers._deleteel(i);
      }
   }
   tab_id._deleteActive();
   if (tab_index != orig_tab) {
      tab_id.p_ActiveTab = orig_tab;
   }
}

static int clicked_tabid = -1;
_command void search_tab_menu(_str cmdline = '') name_info(',' VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _macro_delete_line();
   _str command;
   typeless id;
   parse cmdline with command id;
   switch (lowcase(command)) {
   case 'open':
      if (id < 0) {
         add_new_grep_buffer();
      } else {
         _show_grep_buffer(id);
      }
      break;

   case 'closetab':
      if( clicked_tabid >= 0 ) {
         _hide_tab(clicked_tabid);
      }
      break;
   }
}

void _search_tab.rbutton_up()
{
   int tabi = mou_tabid();
   if (tabi < 0) {
      clicked_tabid = -1;
      p_active_form.call_event(p_active_form, RBUTTON_UP);
      return;
   }
   // get the menu form
   int index = find_index("_tbsearch_menu", oi2type(OI_MENU));
   if (!index) {
      clicked_tabid = -1;
      return;
   }
   clicked_tabid = tabi;

   int buffers_len = grep_buffers._length();
   int menu_handle = p_active_form._menu_load(index, 'P');
   int mf_flags, submenu_handle;
   _menu_get_state(menu_handle, 0, mf_flags, 'p', '', submenu_handle);
   int i, j;
   for (i = 0, j = 0; i < last_grep_id; ++i) {
      if (grep_buffers[j] == i) {
         ++j; continue;
      }
      _menu_insert(submenu_handle, -1, MF_ENABLED, 'Search<'i'>', 'search_tab_menu open 'i, "", "", "");
   }
   if (buffers_len < def_max_search_results_buffers) {
      _menu_insert(submenu_handle, -1, MF_ENABLED, "New", "search_tab_menu open -1", "", "", "");
   }
   if (buffers_len == 1) {
      _menu_set_state(menu_handle, 2, MF_GRAYED, 'P');
   }
   int x = 100;
   int y = 100;
   x = mou_last_x('M') - x;
   y = mou_last_y('M') - y;
   _lxy2dxy(p_scale_mode, x, y);
   _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   int flags = VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   int status = _menu_show(menu_handle, flags, x, y);
   _menu_destroy(menu_handle);
}

static void _sort_tabs(int tab_id, boolean reverse_order)
{
   int i;
   if ( tab_id.p_NofTabs < 1 ) {
      return;
   }
   grep_buffers._sort('N');
   int len = grep_buffers._length();
   for (i = 0; i < len; ++i) {
      int cid = tab_id.sstContainerByName('_search_container'grep_buffers[i]);
      if (cid) {
         cid.p_ActiveOrder = reverse_order ? 0 : i;
      }
   }
}

static void _create_grep_buffer(int tab_id, int grep_id)
{
   int new_tab = tab_id.p_NofTabs;
   ++tab_id.p_NofTabs;
   tab_id.p_ActiveTab = new_tab;
   tab_id.p_ActiveCaption = 'Search<'grep_id'>';
   if (grep_caption:[grep_id] != '') {
      tab_id.p_ActiveToolTip =  "Last Search: "grep_caption:[grep_id];
   }
   int container_id = tab_id._getActiveWindow();
   container_id.p_name = '_search_container'grep_id;
   int edit_id = _create_window(OI_EDITOR, container_id, "", 0, 30, container_id.p_width, container_id.p_height, CW_CHILD|CW_HIDDEN);
   edit_id.p_name = '_search'grep_id;
   edit_id.p_MouseActivate = MA_NOACTIVATE;
   edit_id.p_scroll_bars = SB_BOTH;
   _str grep_buffer_name = '.search'grep_id;
   int temp_grep_view;
   int orig_wid = _find_or_create_temp_view(temp_grep_view, '', grep_buffer_name, false, VSBUFFLAG_THROW_AWAY_CHANGES | VSBUFFLAG_HIDDEN | VSBUFFLAG_KEEP_ON_QUIT);
   docname('Search<'grep_id'>');
   activate_window(orig_wid);
   edit_id._delete_buffer();
   edit_id.p_buf_id = temp_grep_view.p_buf_id;
   edit_id.grep_mode();
   edit_id.p_UTF8 = true;
   edit_id.p_visible = true;
   edit_id.p_window_flags |= (OVERRIDE_CURLINE_RECT_WFLAG | CURLINE_RECT_WFLAG);
   edit_id.p_KeepPictureGutter = true;
   top();
   _sort_tabs(tab_id, true);
   tab_id.p_ActiveTab = container_id.p_ActiveOrder;   //set active tab after sorting
}

static void _show_grep_buffer(int grep_id)
{
   int i;
   int len = grep_buffers._length();
   boolean found = false;
   for (i = 0; i < len; ++i) {
      if (grep_buffers[i] == grep_id) {
         found = true;
         break;
      }
   }
   int tab_id = _find_object("_tbsearch_form._search_tab", "n");
   if (!found) {
      grep_buffers[len] = grep_id;
      if (!grep_caption._indexin(grep_id)) {
         grep_caption:[grep_id] = "";
      }
      grep_buffers._sort('N');
      if (tab_id) {
         _create_grep_buffer(tab_id, grep_id);
      }
   } else {
      if (tab_id) {
         int cid = tab_id.sstContainerByName('_search_container'grep_id);
         if (cid) {
            tab_id.p_ActiveTab = cid.p_ActiveOrder;
            tab_id.p_ActiveToolTip = "Last Search: "grep_caption:[grep_id];
         }
         int edit_id = tab_id._find_control( '_search'grep_id );
         edit_id.grep_mode();
      }
   }
}

_str get_grep_buffer_filename(_str buf_name)
{
   return (buf_name:+".grep");
}

int _get_last_grep_buffer()
{
   return (last_grep_id);
}

_str _get_active_grep_view()
{
   int tab_id = _find_object("_tbsearch_form._search_tab", "n");
   if (tab_id) {
      typeless grep_id;
      int active_id = tab_id._getActiveWindow();
      parse active_id.p_name with "_search_container" grep_id;
      if (grep_id != '') {
         return "_search":+grep_id;
      }
   }
   return ('');
}

void set_grep_buffer(int grep_id, _str search_text)
{
   if (grep_id < 0 || grep_id >= def_max_search_results_buffers) {
      grep_id = 0;
   }
   grep_caption:[grep_id] = search_text;
   _grep_buffer = '.search'grep_id;
   //make sure temp view exists
   int temp_grep_view;
   int orig_wid = _find_or_create_temp_view(temp_grep_view, '', _grep_buffer, false, VSBUFFLAG_THROW_AWAY_CHANGES | VSBUFFLAG_HIDDEN | VSBUFFLAG_KEEP_ON_QUIT);
   docname('Search<'grep_id'>');
   p_UTF8 = true;
   activate_window(orig_wid);
   _show_grep_buffer(grep_id);
   current_grep_id = grep_id;
}

int auto_increment_grep_buffer()
{
   int grep_id = -1;
   int i;
   for (i = 0; i < grep_buffers._length(); ++i) {
      if (grep_buffers[i] > current_grep_id) {
         grep_id = grep_buffers[i];
         break;
      }
   }
   if (grep_id == -1) {
      grep_id = grep_buffers[0];
   }
   _show_grep_buffer(grep_id);
   return (grep_id);
}

int add_new_grep_buffer()
{
   int grep_id;
   if (last_grep_id + 1 < def_max_search_results_buffers) {
      grep_id = ++last_grep_id;
   } else {
      _message_box("Cannot create any more Search Results buffers.");
      grep_id = current_grep_id;
   }
   if (grep_id < 0) {
      grep_id = 0;
   }
   int orig_wid;
   get_window_id(orig_wid);
   _show_grep_buffer(grep_id);
   activate_window(orig_wid);
   return (grep_id);
}

_command void add_grep_buffer()
{
   add_new_grep_buffer();
}

static void _reset_grep_buffers()
{
   grep_buffers._makeempty();
   grep_caption._makeempty();
   grep_buffers[0] = 0;
   grep_caption:[0] = "";
   grep_buffers[1] = 1;
   grep_caption:[1] = "";
   last_grep_id = 1;
   current_grep_id = -1;
}

int _OnUpdate_grep_last(CMDUI &cmdui,int target_wid,_str command)
{
   if (_grep_buffer == '' || buf_match(_grep_buffer, 1, 'hx') == '') {
      return (MF_GRAYED);
   }
   return (MF_ENABLED);
}

_command void grep_mode() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _SetEditorLanguage('grep');
}

/**
 * Displays selection list of files/buffers and occurrences found by the
 * last multi-file find performed (See <b>Find dialog box</b>).  When a file or
 * buffer is chosen, the file is opened and the cursor is placed on the first
 * occurrence of the search string.  Use the <b>find_next</b> command  (Ctrl+G)
 * to find the next occurrence of the search string.
 *
 * @return Returns 0 if a file from the list is selected for editing.
 *
 * @see find
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 *
 */
_command int grep_last() name_info(','VSARG2_REQUIRES_MDI)
{
   _str filename = '';
   if (_grep_buffer != '') {
      filename = buf_match(_grep_buffer, 1, 'hx');
   }
   if (filename == '') {
      _message_box(nls('Use Find command on Search menu first to build a list.'));
      return (1);
   }

   int status;
   if (def_one_file == '') {
      status = edit('+b 'maybe_quote_filename(filename), EDIT_NOADDHIST);
   } else {
      int wid = window_match(filename, 1, 'hx');
      if (wid) {
         status = edit('+b 'maybe_quote_filename(filename), EDIT_NOADDHIST);
      } else {
         int mx, my, mwidth, mheight, x, y, width, height;
         _get_max_window(mx, my, mwidth, mheight);
         x = 0;
         width = mwidth;    //_mdi.p_width-_mdi._left_width()*2
         height = _ly2ly(SM_TWIP,SM_PIXEL, 2300);
         y = my + mheight - height;
         if (y < my) y = my;
         status = edit('+i:'x' 'y' 'width' 'height' n +b 'maybe_quote_filename(filename), EDIT_NOADDHIST);
      }
   }
   if (!status) {
      grep_mode();
   }
   return (status);
}

_command void grep_lbutton_double_click,grep_goto_mouse() name_info(','VSARG2_NOEXIT_SCROLL|VSARG2_CMDLINE|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || p_window_state:=='I' ) {
      try_calling(eventtab_index(_default_keys,
                          _default_keys,event2index(LBUTTON_DOUBLE_CLICK)));
      return;
   }
   if(mou_last_x() < p_windent_x) {
      int status = plusminus('M');
      if (!status) {
         return;
      }
   }
   grep_goto();
}

_command void grep_enter() name_info(','VSARG2_NOEXIT_SCROLL|VSARG2_CMDLINE|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || p_window_state:=='I' ) {
      try_calling(eventtab_index(_default_keys,
                          _default_keys,event2index(ENTER)));
      return;
   }
   grep_goto();
}

_command int grep_goto() name_info(','VSARG2_NOEXIT_SCROLL|VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   _str filename;
   int linenum, col;
   int status = _mffindGetDest(filename, linenum, col);
   if(status == 0) {
      status = _mffindGoTo(filename,linenum,col,true);
   }
   return (status);
}

_command void grep_delete() name_info(','VSARG2_NOEXIT_SCROLL|VSARG2_CMDLINE|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if( command_state() || p_window_state:=='I') {
      call_root_key(last_event());
      return;
   }
   int mark_id = _alloc_selection();
   _select_line(mark_id);
   _str filename;
   int linenum, col;
   int status = se.search.parse_line(filename, linenum, col);
   if (!status && linenum == -1) {
      // on a file line, delete all results for this file
      while (!down()) {
         if ((_lineflags() & LEVEL_LF) <= NEXTLEVEL_LF) {
            break;
         }
      }
      if ((_lineflags() & LEVEL_LF) <= NEXTLEVEL_LF) {
         up();
      }

      _select_line(mark_id);
      _extend_outline_selection(mark_id);
      _begin_select(mark_id);
   }
   _delete_selection(mark_id);
   _free_selection(mark_id);
}

_command void grep_next_file(_str dir = '') name_info(','VSARG2_NOEXIT_SCROLL|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _str options = "@rih";
   typeless p; save_pos(p);
   if (dir == '-') {
      strappend(options, "-");
      up(); _begin_line();
   } else {
      _end_line();
   }
   if (search("^ *file", options) != 0) {
      restore_pos(p);
   }
   _grep_cursor();
}

_command void grep_prev_file() name_info(','VSARG2_NOEXIT_SCROLL|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   grep_next_file('-');
}

_command void grep_page_cursor() name_info(','VSARG2_NOEXIT_SCROLL|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   call_root_key(last_event());
   if( command_state() || p_window_state:=='I') {
      return;
   }
   _grep_cursor();
}

//void _search0.up,down,pgup,pgdn,lbutton_down()
_command void grep_cursor() name_info(','VSARG2_NOEXIT_SCROLL|VSARG2_CMDLINE|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   call_root_key(last_event());
   if( command_state() || p_window_state:=='I') {
      return;
   }
   _grep_cursor();
}

static void _grep_cursor()
{
   // now get the destination information and
   // submit it to the preview window
   _str filename;
   int linenum, col;
   int status = _mffindGetDest(filename, linenum, col, true);
   if(status == 0) {
      VS_TAG_BROWSE_INFO cm;
      tag_browse_info_init(cm);
      cm.member_name = "Search result";
      cm.file_name = filename;
      cm.line_no   = linenum;
      cm.column_no = col;
      cb_refresh_output_tab(cm, true, true, false, APF_SEARCH_RESULTS);
   }
}

_command void grep_esc() name_info(','VSARG2_NOEXIT_SCROLL|VSARG2_CMDLINE|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if(p_mdi_child || command_state() || p_window_state:=='I') {
      try_calling(eventtab_index(_default_keys,
                          _default_keys,event2index(ESC)));
      return;
   }
   if (!_no_child_windows()) {
      p_window_id = _mdi.p_child;
      _mdi.p_child._set_focus();
   } else {
      _cmdline._set_focus();
   }
}
int _OnUpdate_grep_command_menu(CMDUI cmdui, int target_wid, _str command)
{
   _str filename;
   int linenum = -1;
   int col = -1;
   _str cmd, option;
   parse command with cmd option;
   switch (lowcase(option)) {
   case 'c':         // clear all
   case 'h':         // collapse all
   case 'x':         // expand all
   case 'a':         // align columns
      return ((target_wid.p_Noflines > 1) ? MF_ENABLED : MF_GRAYED);
   case 'g':         // goto line
      if (target_wid.p_Noflines > 1) {
        int status = se.search.parse_line(filename, linenum, col);
        if (!status) {
           _menu_set_state(cmdui.menu_handle,
                           cmdui.menu_pos, MF_ENABLED, 'P', ((linenum == -1) ? "Go to File" : "Go to Line"));
           return MF_ENABLED;
        }
      }
      return (MF_GRAYED);
   case 'b':         // bookmark
      if (target_wid.p_Noflines > 1) {
        int status = se.search.parse_line(filename, linenum, col);
        return ((!status && (linenum != -1)) ? MF_ENABLED : MF_GRAYED);
      }
      return (MF_GRAYED);
   case 's':         // open in mdi
      return ((target_wid.p_HasBuffer && !target_wid.p_mdi_child) ?  MF_ENABLED : MF_GRAYED);
   }
   return (MF_ENABLED);
}

_command void grep_command_menu(_str cmdline = '') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _macro_delete_line();
   switch (lowcase(cmdline)) {
   case 'g':   // goto line
      grep_goto();
      break;
   case 's':   // open in mdi
      edit('+q +b 'maybe_quote_filename(p_buf_name), EDIT_NOADDHIST);
      grep_mode();
      break;
   case 'c':   // clear all
      _lbclear(); p_undo_steps = 0;
      p_col = 1;
      _mffindNoMore(1);
      break;
   case 'h':   // collapse all
      collapse_all();
      break;
   case 'x':   // expand all
      expand_all();
      break;
   case 'a':   // align columns
      _align_columns();
      break;
   case 'b':   // bookmark
      _add_bookmark();
      break;
   }
}

// returns true if buffer name matches exactly .search#nn
boolean _isGrepBuffer(_str name)
{
   _str regexp = '^.search:n$';
   return (pos(regexp, name, 1, 'R') == 1);
}

static void _align_columns()
{
   if (!p_HasBuffer || !_isGrepBuffer(p_buf_name)) {
      return;
   }

   int max_line = 0;
   int max_col = 0;
   _str line, prefix, line_num, col_num;
   save_pos(auto p);
   top(); up();
   while (!down()) {
      int lflags = _lineflags() & LEVEL_LF;
      if (lflags == (NEXTLEVEL_LF << 1)) {
         get_line(line);
         parse line with line_num col_num ':';
         if (isinteger(line_num) && isinteger(col_num)) {
            int line_width = length(line_num);
            int col_width = length(col_num);
            if (line_width > max_line) {
               max_line = line_width;
            }
            if (col_width > max_col) {
               max_col = col_width;
            }
         }
      } 
   }

   top(); up();
   while (!down()) {
      int lflags = _lineflags() & LEVEL_LF;
      if (lflags == (NEXTLEVEL_LF << 1)) {
         get_line(line);
         parse line with line_num col_num ':';
         if (isinteger(line_num) && isinteger(col_num)) {
            int line_width = length(line_num);
            int col_width = length(col_num);
            _begin_line();

            parse line with prefix ':';
            _delete_text(length(prefix));
            prefix = "  " :+ substr("", 1, max_line - line_width) :+ line_num :+ " " :+ substr("", 1, max_col - col_width) :+ col_num;
            _insert_text(prefix);
         }
      }
   }
   restore_pos(p);
}

static void _add_bookmark()
{
   _str filename = "";
   int linenum = -1;
   int col = -1;
   int status = se.search.parse_line(filename, linenum, col);
   if (!status && (linenum != -1) && (col != -1)) {
      int orig_wid;
      int temp_view_id = 0;
      boolean file_already_loaded = false;
      status = _open_temp_view(maybe_quote_filename(filename), temp_view_id, orig_wid,'', file_already_loaded);
      if (!status) {
         p_line = linenum;
         // use bookmark prompt or just automate it like find?
         _str bookmarkName = filename"_"linenum;
         set_bookmark('-r 'bookmarkName);
         activate_window(orig_wid);
         _delete_temp_view(temp_view_id, !file_already_loaded);
      }
   }
}

static void _grep_remove_line(int linenum)
{
   int cur_line = p_line;
   p_line = linenum;
   _delete_line();
   p_line = cur_line - 1;
}

static void _search_filter(_str search_text, _str search_options, boolean keep_matches, boolean remove_duplicate_lines)
{
   if (!p_HasBuffer || !_isGrepBuffer(p_buf_name)) {
      return;
   }
   int n_lines = p_Noflines;
   int last_file_line = -1;
   int last_linenum = -1;
   int cur_lines_in_file = 0;
   top(); up();
   while (!down()) {
      int lflags = _lineflags() & LEVEL_LF;
      if (lflags == NEXTLEVEL_LF) { // file line
         if ((last_file_line > 0) && (cur_lines_in_file <= 0) ) {
            _grep_remove_line(last_file_line);
         }
         last_file_line = p_line;
         last_linenum = -1;
         cur_lines_in_file = 0;
      } else if (lflags == (NEXTLEVEL_LF << 1)) {
         _str line, col, text;
         get_line(line);
         parse line with line col ':' text;
         if (isinteger(line) && isinteger(col)) {
            boolean found = (search_text == '') ? keep_matches : (pos(search_text, text, 1, search_options) != 0);
            int cur_line = (int)line;
            if (remove_duplicate_lines && (last_linenum == cur_line)) {
               if (_delete_line()) break;
               up();
            } else if (found != keep_matches) {
               if (_delete_line()) break;
               up();
            } else {
               ++cur_lines_in_file;
            }
            last_linenum = cur_line;
         }
      }
   }
   if ((last_file_line > 0) && (cur_lines_in_file <= 0) ) {
      _grep_remove_line(last_file_line);
   }
   int lines_removed = n_lines - p_Noflines;
   if (lines_removed) {
      message("Filter search results, removed "lines_removed" lines");
   } else {
      message("Filter search results, no matching lines found");
   }
   top();
}

_command void filter_search_results( ) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   int result = show('-modal -reinit _tbsearch_filter_form', p_window_id);
   if (result != '') {
      _search_filter(_param1, _param2, _param3, _param4);
   }
}

defeventtab _tbsearch_filter_form;
_findok.on_create()
{
   _tbsearch_filter_form_initial_alignment();

   int wid = arg(1);
   _findstring.p_text = old_search_string;
   if ((def_mfsearch_init_flags & MFSEARCH_INIT_CURWORD) && wid._isEditorCtl()) {
      int junk;
      _findstring.p_text = wid.cur_word(junk, '', 1);
   }
   int search_flags = old_search_flags;
   _findcase.p_value = (int)!(search_flags & VSSEARCHFLAG_IGNORECASE);
   _findre.p_value = search_flags & (VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE);
   _findre_type._lbadd_item(RE_TYPE_UNIX_STRING);
   _findre_type._lbadd_item(RE_TYPE_BRIEF_STRING);
   _findre_type._lbadd_item(RE_TYPE_SLICKEDIT_STRING);
   _findre_type._lbadd_item(RE_TYPE_PERL_STRING);
   _findre_type._lbadd_item(RE_TYPE_WILDCARD_STRING);
   if (_findre.p_value) {
      _findre_type._init_re_type(search_flags & (VSSEARCHFLAG_RE|VSSEARCHFLAG_UNIXRE|VSSEARCHFLAG_BRIEFRE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_WILDCARDRE));
   } else {
      if (def_re_search == VSSEARCHFLAG_BRIEFRE) {
         _findre_type.p_text = RE_TYPE_BRIEF_STRING;
      } else if (def_re_search == VSSEARCHFLAG_RE) {
         _findre_type.p_text = RE_TYPE_SLICKEDIT_STRING;
      } else if (def_re_search == VSSEARCHFLAG_WILDCARDRE) {
         _findre_type.p_text = RE_TYPE_WILDCARD_STRING;
      } else if (def_re_search == VSSEARCHFLAG_PERLRE) {
         _findre_type.p_text = RE_TYPE_PERL_STRING;
      } else {
         _findre_type.p_text = RE_TYPE_UNIX_STRING;
      }
      ctlremenu.p_enabled = false;
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _tbsearch_filter_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(_findstring.p_window_id, ctlremenu.p_window_id);
}

_findok.lbutton_up()
{
   _str search_string = _findstring.p_text;
   _str search_options = '';
   if (!_findcase.p_value) {
      search_options = 'I';
   }
   if (_findre.p_value) {
      switch (_findre_type.p_cb_text_box.p_text) {
      case RE_TYPE_UNIX_STRING:      search_options = search_options'U'; break;
      case RE_TYPE_BRIEF_STRING:     search_options = search_options'B'; break;
      case RE_TYPE_SLICKEDIT_STRING: search_options = search_options'R'; break;
      case RE_TYPE_PERL_STRING:      search_options = search_options'L'; break;
      case RE_TYPE_WILDCARD_STRING:  search_options = search_options'&'; break;
      }
   }
   old_search_string = search_string;
   boolean keep_matches = (ctlradio1.p_value == 1);
   boolean remove_lines = (_filterlines.p_value == 1);
   _param1 = search_string;
   _param2 = search_options;
   _param3 = keep_matches;
   _param4 = remove_lines;
   p_active_form._delete_window(1);
}

void _findre.lbutton_up()
{
   _findre_type.p_enabled = ctlremenu.p_enabled = _findre.p_value ? true : false;
}

