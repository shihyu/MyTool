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
#import "bookmark.e"
#import "complete.e"
#import "cbrowser.e"
#import "clipbd.e"
#import "context.e"
#import "eclipse.e"
#import "files.e"
#import "guicd.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "mfsearch.e"
#import "moveedge.e"
#import "mprompt.e"
#import "picture.e"
#import "pushtag.e"
#import "search.e"
#import "seldisp.e"
#import "sstab.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagrefs.e"
#import "tagwin.e"
#import "tbfind.e"
#import "util.e"
#import "se/ui/toolwindow.e"
#import "se/ui/twevent.e"
#import "se/search/SearchResults.e"
#endregion


static const TBSEARCH_FORM_NAME_STRING= '_tbsearch_form';

struct TBSEARCH_FORM_INFO {
   int m_form_wid;
};
TBSEARCH_FORM_INFO gtbSearchFormList:[];

static void _init_all_formobj(TBSEARCH_FORM_INFO (&formList):[],_str formName) {
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

defeventtab _tbsearch_form;
static int     last_grep_id;
static int     current_grep_id = -1;

definit()
{
   gtbSearchFormList._makeempty();
   _init_all_formobj(gtbSearchFormList,TBSEARCH_FORM_NAME_STRING);

   last_grep_id = def_initial_search_results_buffers - 1;
   if (last_grep_id < 0) {
      last_grep_id = 0;
   }
   current_grep_id = -1;
}

_tbsearch_form.'F12'()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   } else {
      call_event(defeventtab _toolwindow_etab2,last_event(),'E');
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

static int getSearchForm()
{
   formwid := tw_find_form(TBSEARCH_FORM_NAME_STRING);
   if ( formwid ) {
      return formwid;
   }
   return 0;
}

int _srg_search_results(_str option="",_str info="")
{
   /*
   if (option=='R' || option=='N') {
      grep_buffers._makeempty();
      grep_caption._makeempty();
      _str grep_id;
      parse info with grep_id info;
      while (grep_id != "") {
         if (grep_id < def_max_search_results_buffers) {
            id := grep_buffers._length();
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
      line := "";
      int i;
      for (i = 0; i < grep_buffers._length(); ++i) {
         if (length(line)) {
            strappend(line, ' ');
         }
         strappend(line, grep_buffers[i]);
      }
      insert_line('SEARCH_RESULTS: ':+line);
   } 
   */ 
   return(0);
}

void toolShowSearch(int grep_id = -1)
{
#if 0
   int child_wid=_tbGetActiveMDIChild();
   if (child_wid) {
      // Since the find dialog box is a tool window
      // the current mdi window doesn't help. Set
      // the focus to the correct MDI child so
      // the correct MDICurrent() is used.
      child_wid._set_focus();
   }
   say('t1 child='_mdi.p_child.p_buf_name);
#endif
   if ((grep_id < 0) && (grep_id > last_grep_id)) {
      return;
   }
   if (gtbSearchFormList._isempty() || gtbSearchFormList._length() == 0) {
      wid := activate_tool_window(TBSEARCH_FORM_NAME_STRING);
      if (wid > 0) {
         _show_grep_buffer(grep_id, wid);
      }
      return;
   }

   TBSEARCH_FORM_INFO v;
   int i;
   foreach (i => v in gtbSearchFormList) {
      if ( v.m_form_wid > 0 && tw_is_auto(v.m_form_wid) ) {
         tw_auto_raise(v.m_form_wid);
         call_event(CHANGE_AUTO_SHOW, v.m_form_wid, ON_CHANGE, 'W');
      }
      tw_set_active(v.m_form_wid);
      _show_grep_buffer(grep_id, v.m_form_wid);
   }
}

void toolSearchScroll()
{
   /*
      If the search results window is already displayed, scroll to the end.
   */
   _str ctlname=_get_active_grep_view();
   if (ctlname!="") {
      int wid=_MDIFindFormObject(_MDICurrent(),TBSEARCH_FORM_NAME_STRING'.'ctlname,'N');
      if (wid) {
         wid.bottom(); wid._begin_line();
      }
   }
}

static bool ignore_change = false;

void _tbsearch_form.on_create()
{
   TBSEARCH_FORM_INFO info;
   i := p_active_form;
   info.m_form_wid=p_active_form;
   gtbSearchFormList:[i]=info;

   ignore_change = true;
   _search_tab.p_DocumentMode = true;
   int count = def_initial_search_results_buffers;
   if (count < last_grep_id) {
      count = last_grep_id + 1;
   }
   if (count < 0) {
      count = 1;
   }
   _update_search_buffers_count(p_active_form.p_window_id, count);
   ignore_change = false;
   _sort_tabs(_search_tab);
   _show_grep_buffer(0, p_active_form.p_window_id);

}

void _tbsearch_form.on_load()
{
   if (isEclipsePlugin() && current_grep_id != null && current_grep_id >= 0) {
      _show_grep_buffer(current_grep_id,p_active_form);
   }
}

int _eclipse_getSearchQFormWid()
{
   int formWid = _MDIFindFormObject(_MDICurrent(),ECLIPSE_SEARCHOUTPUT_CONTAINERFORM_NAME,'n');
   if (formWid > 0) {
      return formWid.p_child;
   }
   return 0;
}

void _tbsearch_form.on_destroy()
{
   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id,ON_DESTROY,'2');
   gtbSearchFormList._deleteel(p_active_form);
}

void _tbsearch_form.on_resize()
{
   int old_wid;
   // RGH - 4/26/2006
   // For the plugin, resize the SWT container then do the normal resize
   if (isEclipsePlugin()) {
      searchForm := _eclipse_getSearchQFormWid();
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
   _search_tab.p_y_extent = clientH - _search_tab.p_x;
   // resize editor controls within each active tab
   int first_child = _search_tab.p_child;
   int child = first_child;
   do {
      typeless grep_id;
      parse child.p_name with "_search_container" grep_id;
      edit_wid := _find_control( '_search'grep_id );
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

static void _hide_tab(int tab_index,int form_wid) {
   int tab_id= form_wid._search_tab;
   int orig_tab = tab_id.p_ActiveTab;
   if (tab_id.p_NofTabs <= 1) {
      // not allowed
      return;
   }

   tab_id.p_ActiveTab = tab_index;

   // delete from active tab list
   int cid = tab_id._getActiveWindow();
   int i;
   typeless grep_id;
   parse cid.p_name with "_search_container" grep_id;
   tab_id._deleteActive();
   if (tab_index != orig_tab) {
      tab_id.p_ActiveTab = orig_tab;
   }
}

_str _check_search_tabs(_str count)
{
   if (!isinteger(count)) {
      _message_box('Invalid setting.');
      return(INVALID_ARGUMENT_RC);
   }
   if ((int)count < 1) {
      _message_box('Count must be at least 1.');
      return(INVALID_ARGUMENT_RC);
   }
   return(0);
}

static void _update_search_buffers_count(int form_wid, int count)
{
   int i;
   if (count > 0) {
      int tab_id = form_wid._search_tab;
      int orig_tab = tab_id.p_ActiveTab;

      int cid = tab_id._getActiveWindow();
      typeless grep_id;
      parse cid.p_name with "_search_container" grep_id;

      while (tab_id.p_NofTabs > 0) tab_id._deleteActive();
      for (i = 0; i < count; ++i) {
         form_wid._create_grep_buffer(tab_id, i);
      }

      // restore old grep container, if still around
      cid = tab_id.sstContainerByName('_search_container'grep_id);
      if (cid) {
         tab_id.p_ActiveTab = cid.p_ActiveOrder;
      }
   }
}

static void _set_search_buffers_count(int count)
{
   if (count < 1) {
      return;
   }
   last_grep_id = count - 1;

   TBSEARCH_FORM_INFO v;
   int i;
   foreach (i => v in gtbSearchFormList) {
      _update_search_buffers_count(v.m_form_wid, count);
   }
}

_command void set_search_results_buffers(_str count = "") name_info(','VSARG2_REQUIRES_MDI)
{
   if (count == "" || !isinteger(count) ) {
      int value = last_grep_id + 1;
      status := textBoxDialog("Set Search Results Tabs", 0, 0, "", "", "", 
                              "-e _check_search_tabs Set Number of Tabs:"value);
      if (status < 0) {
         return;
      }
      count = _param1;
   }
   _set_search_buffers_count((int)count);
}

static int clicked_tabid = -1;
_command void search_tab_menu(_str cmdline = "") name_info(',' VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _macro_delete_line();
   form_wid := p_active_form;
   if (p_active_form.p_name:!=TBSEARCH_FORM_NAME_STRING) {
       return;
   }
   _str command;
   typeless id;
   parse cmdline with command id;
   switch (lowcase(command)) {
   case 'open':
      if (id < 0) {
         add_new_grep_buffer(form_wid);
      } else {
         _show_grep_buffer(id,form_wid);
      }
      break;

   case 'closetab':
      if ( clicked_tabid >= 0 ) {
         _hide_tab(clicked_tabid,form_wid);
      }
      break;

   case 'settab':
      {
         int count = last_grep_id + 1;
         status := textBoxDialog("Set Search Results Tabs", 0, 0, "", "", "", 
                                "-e _check_search_tabs Set Number of Tabs:"count);
         if (status < 0) {
            return;
         }
         _set_search_buffers_count((int)_param1);
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

   int menu_handle = p_active_form._menu_load(index, 'P');
   int mf_flags, submenu_handle;
   _menu_get_state(menu_handle, 0, mf_flags, 'p', "", submenu_handle);
   int i, j;

   int tab_id = p_active_form._search_tab;
   for (i = 0; i <= last_grep_id; ++i) {
      int cid = tab_id.sstContainerByName('_search_container'i);
      if (!cid) {
         _menu_insert(submenu_handle, -1, MF_ENABLED, 'Search<'i'>', 'search_tab_menu open 'i, "", "", "");
      }
   }
   _menu_insert(submenu_handle, -1, MF_ENABLED, "New", "search_tab_menu open -1", "", "", "");
   if (tab_id.p_NofTabs <= 1) {
      _menu_set_state(menu_handle, 2, MF_GRAYED, 'P');
   }

   x := 100;
   y := 100;
   x = mou_last_x('M') - x;
   y = mou_last_y('M') - y;
   _lxy2dxy(p_scale_mode, x, y);
   _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   int flags = VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   int status = _menu_show(menu_handle, flags, x, y);
   _menu_destroy(menu_handle);
}

static void _sort_tabs(int tab_id)
{
   if (tab_id.p_NofTabs < 1) {
      return;
   }

   // build id list
   int idlist[];
   int first_child = tab_id.p_child;
   int child = first_child;
   do {
      typeless grep_id;
      parse child.p_name with "_search_container" grep_id;
      idlist[idlist._length()] = grep_id;
      child = child.p_next;
   } while ( child != first_child );

   idlist._sort('N');

   found := 0;
   foreach (auto i in idlist) {
      int cid = tab_id.sstContainerByName('_search_container'i);
      if (cid) {
         cid.p_ActiveOrder = found++;
      }
   }
}

static void _create_grep_buffer(int tab_id, int grep_id)
{
   if (grep_id < 0) {
      return;
   }
   int new_tab = tab_id.p_NofTabs;
   ++tab_id.p_NofTabs;
   tab_id.p_ActiveTab = new_tab;
   tab_id.p_ActiveCaption = 'Search<'grep_id'>';

   int container_id = tab_id._getActiveWindow();
   container_id.p_name = '_search_container'grep_id;
   int edit_id = _create_window(OI_EDITOR, container_id, "", 0, 30, container_id.p_width, container_id.p_height, CW_CHILD|CW_HIDDEN);
   edit_id.p_name = '_search'grep_id;
   edit_id.p_MouseActivate = MA_NOACTIVATE;
   edit_id.p_scroll_bars = SB_BOTH;
   edit_id.p_tab_index=grep_id+1;
   grep_buffer_name :=  '.search'grep_id;
   int temp_grep_view;
   int orig_wid = _find_or_create_temp_view(temp_grep_view, '-fshowextraline +futf8 +t', grep_buffer_name, false, VSBUFFLAG_THROW_AWAY_CHANGES | VSBUFFLAG_HIDDEN | VSBUFFLAG_KEEP_ON_QUIT);
   docname('Search<'grep_id'>');
   edit_id._delete_buffer();
   activate_window(orig_wid);
   edit_id.p_buf_id = temp_grep_view.p_buf_id;
   edit_id.grep_mode();
   edit_id.p_UTF8 = true;
   edit_id.p_visible = true;
   edit_id.p_window_flags |= (OVERRIDE_CURLINE_RECT_WFLAG | CURLINE_RECT_WFLAG);
   edit_id.p_KeepPictureGutter = true;
   top();

   if (!ignore_change) {
      _sort_tabs(tab_id);
      tab_id.p_ActiveTab = container_id.p_ActiveOrder;   //set active tab after sorting
      p_active_form.call_event(p_active_form, ON_RESIZE, 'W');
   }
}

static void _show_grep_buffer(int grep_id, int form_wid=-1)
{
   if (grep_id < 0) {
      grep_id = 0;
   }
   if (form_wid < 0) {
      form_wid = getSearchForm();
   }
   if (form_wid) {
       int tab_id = form_wid._search_tab;
       int cid = tab_id.sstContainerByName('_search_container'grep_id);
       if (cid) {
          tab_id.p_ActiveTab = cid.p_ActiveOrder;
       } else {
          form_wid._create_grep_buffer(form_wid._search_tab, grep_id);
       }
    }
}

bool _grep_buffer_exists(int grep_id) 
{
   return ((grep_id >= 0) && (buf_match('.search':+grep_id, 1, 'hx') != ''));
}

bool _grep_buffer_has_results(int grep_id) 
{
   if (grep_id >= 0) {
      buf_info := buf_match('.search':+grep_id, 1, 'hxv');
      if (buf_info != '') {
         parse buf_info with auto buf_id .;

         orig_view_id := p_window_id;
         p_window_id = VSWID_HIDDEN;
         orig_buf_id := p_buf_id;
         _safe_hidden_window();
         p_buf_id = (int)buf_id;
         status := (p_Noflines > 1); 
         p_buf_id = orig_buf_id;
         p_window_id = orig_view_id;
         return status;
      }
   }
   return false;
}

_str get_grep_buffer_filename(_str buf_name)
{
   return (buf_name:+".grep");
}

int _get_last_grep_buffer()
{
   return (last_grep_id);
}

void _update_last_grep_buffer(int grep_id)
{
   if (grep_id < 0) {
      grep_id = 0;
   }
   if (grep_id > last_grep_id) {
      last_grep_id = grep_id;
   }
}

_str _get_active_grep_view()
{
   int tab_id = _find_object(TBSEARCH_FORM_NAME_STRING"._search_tab", "n");
   if (tab_id) {
      typeless grep_id;
      int active_id = tab_id._getActiveWindow();
      parse active_id.p_name with "_search_container" grep_id;
      if (grep_id != "") {
         return "_search":+grep_id;
      }
   }
   return ("");
}
int _get_active_grep_wid()
{
   int tab_id = _find_object(TBSEARCH_FORM_NAME_STRING"._search_tab", "n");
   if (tab_id) {
      typeless grep_id;
      int active_id = tab_id._getActiveWindow();
      parse active_id.p_name with "_search_container" grep_id;
      if (grep_id != "") {
         return _find_object(TBSEARCH_FORM_NAME_STRING"._search":+grep_id, "n");
      }
   }
   return 0;
}

void set_grep_buffer(int grep_id, _str search_text)
{
   if (grep_id < 0) {
      grep_id = 0;
   }
   if (grep_id > last_grep_id) {
      last_grep_id = grep_id;
   }
   _grep_buffer = '.search'grep_id;
   //make sure temp view exists
   int temp_grep_view;
   int orig_wid = _find_or_create_temp_view(temp_grep_view, '-fshowextraline +futf8 +t', _grep_buffer, false, VSBUFFLAG_THROW_AWAY_CHANGES | VSBUFFLAG_HIDDEN | VSBUFFLAG_KEEP_ON_QUIT);
   docname('Search<'grep_id'>');
   p_UTF8 = true;
   activate_window(orig_wid);

   TBSEARCH_FORM_INFO v;
   int i;
   foreach (i => v in gtbSearchFormList) {
      _show_grep_buffer(grep_id, v.m_form_wid);
   }
   current_grep_id = grep_id;
}

/*
   Use the next grep buffer. This doesn't create a new
   grep buffer.
*/
int auto_increment_grep_buffer()
{
   grep_id := -1;
   if (current_grep_id < 0) {
      grep_id = 0;
   } else if (current_grep_id + 1 > last_grep_id) {
      grep_id = 0;
   } else {
      grep_id = current_grep_id + 1;
   }
   if (grep_id == -1) {
      grep_id = 0;
   }
   return (grep_id);
}

int add_new_grep_buffer(int form_wid=-1)
{
   int grep_id;
   grep_id = ++last_grep_id;
   if (grep_id < 0) {
      grep_id = 0;
   }
   int orig_wid;
   get_window_id(orig_wid);
   if (form_wid < 0) {
      TBSEARCH_FORM_INFO v;
      int i;
      foreach (i => v in gtbSearchFormList) {
         _show_grep_buffer(grep_id, v.m_form_wid);
      }
   } else {
      _show_grep_buffer(grep_id, form_wid);
   }
   activate_window(orig_wid);
   return (grep_id);
}

_command void add_grep_buffer()
{
   add_new_grep_buffer();
}

int _OnUpdate_grep_last(CMDUI &cmdui,int target_wid,_str command)
{
   if (_grep_buffer == "" || buf_match(_grep_buffer, 1, 'hx') == "") {
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
   filename := "";
   if (_grep_buffer != "") {
      filename = buf_match(_grep_buffer, 1, 'hx');
   }
   if (filename == "") {
      _message_box(nls('Use Find command on Search menu first to build a list.'));
      return (1);
   }

   int status;
   if (def_one_file == "") {
      status = edit('+b '_maybe_quote_filename(filename), EDIT_NOADDHIST);
   } else {
      wid := window_match(filename, 1, 'hx');
      if (wid) {
         status = edit('+b '_maybe_quote_filename(filename), EDIT_NOADDHIST);
      } else {
         int mx, my, mwidth, mheight, x, y, width, height;
         _get_max_window(mx, my, mwidth, mheight);
         x = 0;
         width = mwidth;    //_mdi.p_width-_mdi._left_width()*2
         height = _ly2ly(SM_TWIP,SM_PIXEL, 2300);
         y = my + mheight - height;
         if (y < my) y = my;
         status = edit('+i:'x' 'y' 'width' 'height' n +b '_maybe_quote_filename(filename), EDIT_NOADDHIST);
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
   if (!status) {
      status = _mffindGoTo(filename,linenum,col,true);
   } else if (status != NO_MORE_FILES_RC && status != STRING_NOT_FOUND_RC) {
      message("Error Parsing Search Results");
   }
   return (status);
}

_command int grep_open_file() name_info(','VSARG2_NOEXIT_SCROLL|VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   _str filename;
   int linenum, col;
   int status = _mffindGetDest(filename, linenum, col);
   if (!status) {
      status = _mffindGoTo(filename,linenum,col,false,true);
   } else if (status != NO_MORE_FILES_RC && status != STRING_NOT_FOUND_RC) {
      message("Error Parsing Search Results");
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

   get_line(auto line);
   parse line with auto word auto rest;
   is_func := se.search._grep_is_context_word(lowcase(word));
   is_file := (lowcase(word) == 'file');
   level := (_lineflags() & LEVEL_LF);
   if (is_func || is_file) {
      _select_line(mark_id);
      while (!down()) {
         get_line(line);
         parse line with line rest;
         if (is_file) {
            if ((lowcase(line) == 'file')) {
               break;
            }
         } else if (is_func) {
            if ((lowcase(line) == 'file') || se.search._grep_is_context_word(lowcase(line)) || ((_lineflags() & LEVEL_LF) <= level)) {
               break;
            }
         }
      }
      if ((_lineflags() & LEVEL_LF) <= level) {
         up();
      }
      _select_line(mark_id);
      _extend_outline_selection(mark_id);
      _begin_select(mark_id);
      _delete_selection(mark_id);
      _free_selection(mark_id);
      return;
   } 

   if (!beginsWith(line, "[ ]#:i :i\\:", false, 'R')) {
      _select_line(mark_id);
      _delete_selection(mark_id);
      _free_selection(mark_id);
      return;
   }

   start_line := p_line;
   while (!up()) {
      get_line(line);
      if (!beginsWith(line, "[ ]#-\\:", false, 'R')) {
         down(); break;
      }
   }
   _select_line(mark_id);
   p_line = start_line;
   while (!down()) {
      get_line(line);
      if (!beginsWith(line, "[ ]#\\+\\:", false, 'R')) {
         if (!beginsWith(line, def_search_result_separator_char:+"#\\:", false, 'R')) {
            up();
         }
         break;
      }
   }
   _select_line(mark_id);
   _extend_outline_selection(mark_id);
   _begin_select(mark_id);
   _delete_selection(mark_id);
   _free_selection(mark_id);
}

_command void grep_next_file(_str dir = "") name_info(','VSARG2_NOEXIT_SCROLL|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   options := "@rih";
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
      tag_init_tag_browse_info(auto cm, "Search result", "", SE_TAG_TYPE_NULL, SE_TAG_FLAG_NULL, filename, linenum);
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
   int child_wid=_MDICurrentChild(0);
   if (child_wid) {
       p_window_id=child_wid;
      _set_focus();
   } else {
      _cmdline._set_focus();
   }
}
int _OnUpdate_grep_command_menu(CMDUI cmdui, int target_wid, _str command)
{
   _str filename;
   linenum := -1;
   col := -1;
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
   case 'l':
      return ((target_wid.p_HasBuffer && target_wid.p_Noflines > 1) ?  MF_ENABLED : MF_GRAYED);
   case 'f':
      return ((target_wid.p_HasBuffer && target_wid.p_Noflines > 1) ?  MF_ENABLED : MF_GRAYED);
   case 'w':
      if (target_wid.p_HasBuffer && target_wid.p_Noflines > 1) {
         int status = se.search.parse_line(filename, linenum, col);
         if (status || filename :== '') {
            _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
            return MF_DELETED;
         }
         caption := "Open ":+_strip_filename(filename, 'P'):+" in New Tab";
         _menu_set_state(cmdui.menu_handle,
                         cmdui.menu_pos, MF_ENABLED, 'P', caption);
         return MF_ENABLED;
      }
      return (MF_GRAYED);
   }
   return (MF_ENABLED);
}

_command void grep_command_menu(_str cmdline = "") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _macro_delete_line();
   switch (lowcase(cmdline)) {
   case 'g':   // goto line
      grep_goto();
      break;
   case 's':   // open in mdi
      edit('+q +b '_maybe_quote_filename(p_buf_name), EDIT_NOADDHIST);
      grep_mode();
      break;
   case 'c':   // clear all
      _lbclear(); p_undo_steps = 0;
      p_col = 1;
      _mffindNoMore(1);
      break;
   case 'h':   // collapse all
      collapse_all('C',1);
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
   case 'l':   // filelist
      _edit_filelist();
      break;
   case 'f':   // find in files results
      _find_in_files_filelist();
      break;
   case 'r':   // send to referencesfilelist
      _grep_symbollist(auto tagList, auto search_text, auto search_opts);
      refs_push_list_of_symbols(search_text, search_opts, "", tagList);
      break;
   case 'w':   // open in new tab
      grep_open_file();
      break;
   }
}

// returns true if buffer name matches exactly .search#nn
bool _isGrepBuffer(_str name)
{
   regexp := "^.search:n$";
   return (pos(regexp, name, 1, 'R') == 1);
}

static void _align_columns()
{
   if (!p_HasBuffer || !_isGrepBuffer(p_buf_name)) {
      return;
   }

   max_line := 0;
   max_col := 0;
   _str line, prefix, line_num, col_num;
   save_pos(auto p);
   top(); up();
   while (!down()) {
      get_line(line);
      ch := _first_char(strip(line));
      if (ch == '-' || ch == '+' || ch == ':' || ch == def_search_result_separator_char) {
         continue;
      }

      parse line with line_num col_num ':';
      if (isinteger(line_num) && isinteger(col_num)) {
         line_width := length(line_num);
         col_width := length(col_num);
         if (line_width > max_line) {
            max_line = line_width;
         }
         if (col_width > max_col) {
            max_col = col_width;
         }
      }
   }

   top(); up();
   while (!down()) {
      get_line(line);
      ch := _first_char(strip(line));
      if (ch == '-' || ch == '+' || ch == ':' || ch == def_search_result_separator_char) {
         _begin_line();

         parse line with prefix ':';
         _delete_text(length(prefix));
         pad_width := 3 + max_line + max_col;
         prefix = strip(prefix);
         prefix = substr("", 1, pad_width - length(prefix)):+prefix;
         _insert_text(prefix);
      } else {
         parse line with line_num col_num ':';
         if (isinteger(line_num) && isinteger(col_num)) {
            line_width := length(line_num);
            col_width := length(col_num);
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

static void _grep_collapse_files()
{
   if (!p_HasBuffer || !_isGrepBuffer(p_buf_name)) {
      return;
   }

   save_pos(auto p);
   top(); up();
   status := search("^ *file", "@rih");
   while (!status) {
      if (_lineflags() & MINUSBITMAP_LF) {
         plusminus();
      }
      status = repeat_search();
   }

   restore_pos(p);
}

static void _add_bookmark()
{
   filename := "";
   linenum := -1;
   col := -1;
   int status = se.search.parse_line(filename, linenum, col);
   if (!status && (linenum != -1) && (col != -1)) {
      int orig_wid;
      temp_view_id := 0;
      file_already_loaded := false;
      status = _open_temp_view(_maybe_quote_filename(filename), temp_view_id, orig_wid,"", file_already_loaded);
      if (!status) {
         p_line = linenum;
         // use bookmark prompt or just automate it like find?
         bookmarkName :=  filename"_"linenum;
         set_bookmark('-r 'bookmarkName);
         activate_window(orig_wid);
         _delete_temp_view(temp_view_id, !file_already_loaded);
      }
   }
}

static void _edit_filelist()
{
   if (!p_HasBuffer || !_isGrepBuffer(p_buf_name)) {
      return;
   }
   parse p_buf_name with '.search' auto grep_id;
   if (grep_id != '' && isnumber(grep_id)) {
      grep_filelist((int)grep_id);
   }
}  

static void _grep_symbollist(VS_TAG_BROWSE_INFO (&tagList)[], _str &search_text, _str &search_opts)
{
   if (!p_HasBuffer || !_isGrepBuffer(p_buf_name)) {
      return;
   }
   parse p_buf_name with '.search' auto grep_id;
   if (grep_id == '' || !isnumber(grep_id)) {
      return;
   }
   if (!_grep_buffer_exists((int)grep_id)) {
      message('Search Results <':+grep_id:+'> does not exist.');
      return;
   }
   get_window_id(auto orig_window_id);
   _grep_make_symbollist((int)grep_id, tagList, search_text, search_opts);
   activate_window(orig_window_id);
}

static void _find_in_files_filelist()
{
   if (!p_HasBuffer || !_isGrepBuffer(p_buf_name)) {
      return;
   }
   parse p_buf_name with '.search' auto grep_id;
   if (grep_id != '' && isnumber(grep_id)) {
      find_in_files();
      tbFind_SetFilelistGrepid((int)grep_id);
   }
}  

static void _grep_remove_line(int linenum)
{
   cur_line := p_line;
   p_line = linenum;
   _delete_line();
   p_line = cur_line - 1;
}

static int _search_filter_line(_str line, int &last_linenum, _str search_text, _str search_options, bool keep_matches, bool remove_duplicate_lines)
{
   _str linenum, col, text;
   status := 0;
   ch := _first_char(strip(line));
   if ((ch == '-') || (ch == '+') || (ch == ':') || (ch :== def_search_result_separator_char)) {
      _delete_line(); up();
      return status;
   }
   parse line with linenum col ':' text;
   if (isinteger(linenum) && isinteger(col)) {
      found := (search_text == "") ? keep_matches : (pos(search_text, text, 1, search_options) != 0);
      int cur_line = (int)linenum;
      if (remove_duplicate_lines && (last_linenum == cur_line)) {
         _delete_line(); up();
      } else if (found != keep_matches) {
         _delete_line(); up();
      } else {
         status = 1;
      }
      last_linenum = cur_line;
   }
   return status;
}

static int _search_filter_func(_str search_text, _str search_options, bool keep_matches, bool remove_duplicate_lines)
{
   last_line := p_line;
   lines_count := 0;
   last_linenum := -1;
   get_line(auto line);
   while (!down()) {
      get_line(line);
      parse line with auto first_word auto rest;
      if ((lowcase(first_word) == 'file') || se.search._grep_is_context_word(lowcase(first_word))) {
         up();
         break;
      }
      status := _search_filter_line(line, last_linenum, search_text, search_options, keep_matches, remove_duplicate_lines);
      if (status) {
         ++lines_count;
      }
   }
   if ((last_line > 0) && (lines_count <= 0) ) {
      _grep_remove_line(last_line);
      return 0;
   }
   return lines_count;
}

static void _search_filter(_str search_text, _str search_options, bool keep_matches, bool remove_duplicate_lines)
{
   if (!p_HasBuffer || !_isGrepBuffer(p_buf_name)) {
      return;
   }
   n_lines := p_Noflines;
   last_file_line := -1;
   last_linenum := -1;
   cur_lines_in_file := 0;
   save_pos(auto p); top(); up();
   while (!down()) {
      get_line(auto line);
      parse line with auto first_word auto rest;
      if (lowcase(first_word) == 'file') {
         if ((last_file_line > 0) && (cur_lines_in_file <= 0) ) {
            _grep_remove_line(last_file_line);
         }
         last_file_line = p_line;
         last_linenum = -1;
         cur_lines_in_file = 0;
      } else if (se.search._grep_is_context_word(lowcase(first_word))) {
         status := _search_filter_func(search_text, search_options, keep_matches, remove_duplicate_lines);
         if (status) {
            ++cur_lines_in_file;
         }
         last_linenum = -1;
      } else {
         status := _search_filter_line(line, last_linenum, search_text, search_options, keep_matches, remove_duplicate_lines);
         if (status) {
            ++cur_lines_in_file;
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
   restore_pos(p);
}

static void _grep_remove_file()
{
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   mark_id := _alloc_selection();
   _select_line(mark_id); _end_line();
   status := search('^file ', '@rih');
   if (status) {
      bottom();
   }
   up();
   _select_line(mark_id);
   _extend_outline_selection(mark_id);
   _delete_selection(mark_id);
   _free_selection(mark_id);
   restore_search(s1, s2, s3, s4, s5);
}

static void _search_filter_files(_str files_include, _str files_exclude)
{
   if (!p_HasBuffer || !_isGrepBuffer(p_buf_name)) {
      return;
   }
   save_pos(auto p); top(); up();
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   status := search('^file ', '@rih');
   while (!status) {
      get_line(auto filename);
      parse filename with . filename;
      if ((files_include != '') &&  !_FileRegexMatchExcludePath(files_include, filename)) {
         _grep_remove_file(); up();
      } else if ((files_exclude != '') && _FileRegexMatchExcludePath(files_exclude, filename)) {
         _grep_remove_file(); up();
      }
      status = repeat_search();
   }
   restore_search(s1, s2, s3, s4, s5);
   restore_pos(p);
}

static void _grep_strip_context_lines()
{
   if (!p_HasBuffer || !_isGrepBuffer(p_buf_name)) {
      return;
   }
   save_pos(auto p); top(); up();
   base_level := NEXTLEVEL_LF + NEXTLEVEL_LF;
   top(); up();
   while (!down()) {
      get_line(auto line);
      parse line with auto first_word .;
      if (se.search._grep_is_context_word(lowcase(first_word))) {
         _delete_line(); up();
         continue;
      }
      level := (_lineflags() & LEVEL_LF);
      if (level > base_level) {
         _lineflags(base_level, LEVEL_LF); 
      }
   }
   restore_pos(p);
}

int _OnUpdate_filter_search_results(CMDUI &cmdui, int target_wid, _str command)
{
   if (!target_wid._isEditorCtl(false) || !_isGrepBuffer(target_wid.p_buf_name)) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED;
      }
   }
   parse command with auto cmd_name auto arg1 .;
   has_results := (target_wid.p_Noflines > 1);

   if (arg1 :== '') {
      if (has_results) {
         return(MF_ENABLED);
      }
      return(MF_GRAYED);
   }

   target_wid.get_line(auto line);
   parse line with auto first_word auto rest;

   is_file := (lowcase(first_word) == 'file');
   is_context := se.search._grep_is_context_word(lowcase(first_word));
   is_selected := (target_wid.select_active() != 0);
   if (is_selected) {
      target_wid._get_selinfo(auto start_col, auto end_col, auto junk, '', junk, junk, junk, auto Noflines);
      if ((Noflines > 1) || (end_col - start_col > 1024)) {
         is_selected = false;
      }
   }

   flags := MF_GRAYED;
   switch (arg1) {
   case '-lines':
      flags = (has_results) ? MF_ENABLED : MF_GRAYED;
      break;

   case '-file':
      flags = (is_file) ? MF_ENABLED : MF_DELETED;
      break;

   case '-path':
   case '+path':
      flags = (is_file) ? MF_ENABLED : MF_DELETED;
      if (is_file) {
         pathname := _strip_filename(rest, 'N'); 
         _menu_get_state(cmdui.menu_handle, command, auto fl, "m", auto caption);
         _menu_set_state(cmdui.menu_handle, cmdui.menu_pos, MF_ENABLED, 'P', caption:+pathname);
      }
      break;

   case '-text':
   case '+text':
      flags = (is_selected && has_results) ? MF_ENABLED : MF_DELETED;
      if (flags & MF_ENABLED) {
         mark_locked := 0;
         if (_select_type('', 'S') == 'C') {
            mark_locked = 1;
            _select_type('', 'S', 'E');
         }

         target_wid.filter_init();
         target_wid.filter_get_string(auto search_text);
         target_wid.filter_restore_pos();

         if (mark_locked) {
            _select_type('', 'S','C');
         }
         _menu_get_state(cmdui.menu_handle, command, auto fl, "m", auto caption, command);
         _menu_set_state(cmdui.menu_handle, cmdui.menu_pos, MF_ENABLED, 'P', caption, command:+" "search_text);
      }
      break;

   case '-context':
      flags = (is_context) ? MF_ENABLED : MF_DELETED;
      break;
   }

   if ((flags & MF_DELETED) && cmdui.menu_handle) {
      _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
   }
   return(flags);
}


_command void filter_search_results(_str options = '') name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (options != '') {
      line := "";
      search_text := "";

      parse options with auto arg1 auto arg2;
      switch (arg1) {
      case '-file':
         grep_delete();
         break;

      case '+path':
      case '-path':
         get_line(line);
         parse line with "File " search_text;
         if (search_text != '') {
            search_text = _strip_filename(search_text, 'N'); 
            _search_filter_files((arg1 :== '+path') ? search_text : '', (arg1 :== '-path') ? search_text : '');
         }
         break;

      case '+text':
      case '-text':
         search_text = arg2;

      case '-lines':
         keep_matches := (arg1 :== '+text');
         remove_duplicate_lines := (arg1 :== '-lines');
         _search_filter(search_text, '', keep_matches, remove_duplicate_lines);
         break;

      case '-context':
         _grep_strip_context_lines();
         break;
      }
      return;
   }

   int result = show('-modal -reinit _tbsearch_filter_form', p_window_id);
   if (result == 0) {
      _search_filter(_param1, _param2, _param3, _param4);
   } else if (result == 1) {
      _search_filter_files(_param1, _param2);
   }
}

defeventtab _tbsearch_filter_form;
_findok.on_create()
{
   _tbsearch_filter_form_initial_alignment();

   _findre_type._lbadd_item(RE_TYPE_SLICKEDIT_STRING);
   _findre_type._lbadd_item(RE_TYPE_PERL_STRING);
   _findre_type._lbadd_item(RE_TYPE_VIM_STRING);
   _findre_type._lbadd_item(RE_TYPE_WILDCARD_STRING);

   // add some filespecs to our combo
   ctlinclude.add_filetypes_to_combo();
   ctlinclude._retrieve_list();
   ctlexclude._retrieve_list();

   _retrieve_prev_form();
   ctlremenu.p_enabled = (_findre.p_value != 0);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _tbsearch_filter_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(_findstring.p_window_id, ctlremenu.p_window_id);
   sizeBrowseButtonToTextBox(ctlinclude_label.p_window_id, ctlinclude_help.p_window_id);
   sizeBrowseButtonToTextBox(ctlexclude_label.p_window_id, ctlexclude_help.p_window_id);
}

_findok.lbutton_up()
{
   status := 0;
   if (ctlsstab1.p_ActiveTab == 0) {
      search_string := _findstring.p_text;
      search_options := "";
      if (!_findcase.p_value) {
         search_options = 'I';
      }
      if (_findre.p_value) {
         switch (_findre_type.p_cb_text_box.p_text) {
         //case RE_TYPE_UNIX_STRING:      search_options = search_options'U'; break;
         //case RE_TYPE_BRIEF_STRING:     search_options = search_options'B'; break;
         case RE_TYPE_SLICKEDIT_STRING: search_options = search_options'R'; break;
         case RE_TYPE_PERL_STRING:      search_options = search_options'L'; break;
         case RE_TYPE_VIM_STRING:       search_options = search_options'~'; break;
         case RE_TYPE_WILDCARD_STRING:  search_options = search_options'&'; break;
         }
      }
      keep_matches := (ctlradio1.p_value == 1);
      remove_lines := (_filterlines.p_value == 1);
      _param1 = search_string;
      _param2 = search_options;
      _param3 = keep_matches;
      _param4 = remove_lines;
   } else if (ctlsstab1.p_ActiveTab == 1) {
      status = 1;
      _param1 = ctlinclude.p_text;
      _param2 = ctlexclude.p_text;
   }
   _save_form_response();
   p_active_form._delete_window(status);
}

void _findre.lbutton_up()
{
   _findre_type.p_enabled = ctlremenu.p_enabled = _findre.p_value ? true : false;
}

_command void grep_align_columns(int grep_id = -1) name_info(',')
{
   get_window_id(auto orig_wid);
   wid := se.search._get_grep_buffer_view((int)grep_id,true);
   if (wid) {
      wid._align_columns();
   }
   activate_window(orig_wid);
}

_command void grep_collapse_all(int grep_id = -1) name_info(',')
{
   get_window_id(auto orig_wid);
   wid := se.search._get_grep_buffer_view(grep_id,true);
   if (wid) {
      wid.collapse_all('C',1);
   }
   activate_window(orig_wid);
}

_command void grep_expand_all(int grep_id = -1) name_info(',')
{
   get_window_id(auto orig_wid);
   wid := se.search._get_grep_buffer_view(grep_id,true);
   if (wid) {
      wid.expand_all();
   }
   activate_window(orig_wid);
}

_command void grep_collapse_files(int grep_id = -1) name_info(',')
{
   get_window_id(auto orig_wid);
   wid := se.search._get_grep_buffer_view(grep_id,true);
   if (wid) {
      wid._grep_collapse_files();
   }
   activate_window(orig_wid);
}

int _grep_make_filelist(int grep_id, int filelist_wid)
{
   if (!_grep_buffer_exists(grep_id)) {
      return -1;
   }
   results_wid := se.search._get_grep_buffer_view(grep_id);
   activate_window(results_wid);
   save_pos(auto p); top(); up();
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   status := search('^file ', '@rih');
   while (!status) {
      get_line(auto filename);
      parse filename with . filename;
      activate_window(filelist_wid);
      insert_line(filename);
      activate_window(results_wid);
      status = repeat_search();
   }
   restore_search(s1, s2, s3, s4, s5);
   restore_pos(p);
   activate_window(filelist_wid);
   top(); up();
   sort_buffer(_fpos_case);
   _remove_duplicates(_fpos_case);
   return 0;
}

_command void grep_filelist(int grep_id = 0) name_info(',')
{
   if (!_grep_buffer_exists(grep_id)) {
      message('Search Results <':+grep_id:+'> does not exist.');
      return;
   }
   get_window_id(auto orig_window_id);
   status := edit('+futf8 +t');
   if (status) {
      return;
   }
   filelist_wid := p_window_id;
   _delete_line();
   _grep_make_filelist(grep_id, filelist_wid);
   activate_window(orig_window_id);
}


int _grep_make_symbollist(int grep_id, VS_TAG_BROWSE_INFO (&tagList)[], _str &search_text, _str &search_opts)
{
   if (!_grep_buffer_exists(grep_id)) {
      return -1;
   }
   results_wid := se.search._get_grep_buffer_view(grep_id);
   activate_window(results_wid);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   save_pos(auto p); 
   top();
   get_line(auto currentLine);
   parse currentLine with "Find " . "\"" search_text "\"," currentLine;
   search_opts = 'i';
   while (currentLine != "") {
      parse currentLine with auto option ',' currentLine;
      if (option == "Match case") {
         search_opts = 'e';
      } else if (option == "Regular expression (SlickEdit)") {
         search_opts :+= 'R';
      } else if (option == "Regular expression (Perl)") {
         search_opts :+= 'L';
      } else if (option == "Regular expression (Vim)") {
         search_opts :+= '~';
      } else if (option == "Wildcards (*,?)") {
         search_opts :+= '&';
      } else if (option == "Whole word") {
         search_opts :+= 'w';
      }
   }

   VS_TAG_BROWSE_INFO cm;
   currentFile := "";
   loop {
      get_line(currentLine);
      if (pos("File ", currentLine, 1, 'i') == 1) {
         parse currentLine with . currentFile;
         down();
      }

      status := _open_temp_view(currentFile, auto temp_view_id, auto orig_view_id, '', auto buffer_already_exists, doClear:false, doSelectEditorLanguage:true);
      if (status >= 0) {
         _UpdateContext(true, true);
         loop {
            results_wid.get_line(currentLine);
            parse currentLine with auto lineNumber auto columnNumber ':' auto restOfLine;
            if (isinteger(lineNumber) && isinteger(columnNumber)) {
               p_RLine = (int)lineNumber;
               p_col   = (int)columnNumber;
               context_id := tag_current_context();
               if (context_id > 0) {
                  tag_get_context_browse_info(context_id, cm);
               } else {
                  tag_browse_info_init(cm);
                  cm.member_name = "no current context";
                  cm.type_name = "statement";
                  cm.line_no = (int)lineNumber;
                  cm.seekpos = _QROffset();
               }
               cm.file_name = currentFile;
               cm.name_line_no = (int)lineNumber;
               cm.name_seekpos = _QROffset();
               tagList :+= cm;
            }
            // stop here
            if (pos("File ", currentLine, 1, 'i') == 1) {
               break;
            }
            // next please
            if (results_wid.down()) {
               break;
            }
         }

         _delete_temp_view(temp_view_id);
         activate_window(results_wid);
      }

      // found a file line, go process it right away
      if (pos("File ", currentLine, 1, 'i') == 1) {
         continue;
      }

      // next please
      if (down()) {
         break;
      }
   }
   restore_search(s1, s2, s3, s4, s5);
   restore_pos(p);
   return 0;
}

