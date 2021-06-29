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
#include "plugin.sh"
#import "cfg.e"
#import "files.e"
#import "main.e"
#import "sstab.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbshell.e"
#import "os2cmds.e"
#import "complete.e"
#import "autocomplete.e"
#import "dir.e"
#import "error.e"
#import "markfilt.e"
#import "cua.e"
#import "mouse.e"
#import "clipbd.e"
#import "fileman.e"
#import "sellist2.e"
#import "guiopen.e"
#import "menu.e"
#import "xmldoc.e"
#import "beautifier.e"
#import "se/ui/toolwindow.e"
#endregion


static const TBTERMINAL_FORM_NAME_STRING= '_tbterminal_form';
static const TBINTERACTIVE_FORM_NAME_STRING= '_tbinteractive_form';

struct TBTERMINAL_FORM_INFO {
   int m_form_wid;
};
TBTERMINAL_FORM_INFO gtbTerminalFormList:[];
TBTERMINAL_FORM_INFO gtbInteractiveFormList:[];

static const TERMINAL_CONTAINER='_terminal_container';

static void _init_all_formobj(TBTERMINAL_FORM_INFO (&formList):[],_str formName) {
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
static bool isInteractiveForm() {
   return p_active_form.p_name:==TBINTERACTIVE_FORM_NAME_STRING;
}

defeventtab _tbterminal_form;

definit()
{
   gtbTerminalFormList._makeempty();
   _init_all_formobj(gtbTerminalFormList,TBTERMINAL_FORM_NAME_STRING);
   gtbInteractiveFormList._makeempty();
   _init_all_formobj(gtbInteractiveFormList,TBINTERACTIVE_FORM_NAME_STRING);
}

static int getTerminalForm()
{
   formwid := tw_find_form(TBTERMINAL_FORM_NAME_STRING);
   if ( formwid ) {
      return formwid;
   }
   return 0;
}

static bool ignore_change = false;

void _tbterminal_form.on_create()
{
   TBTERMINAL_FORM_INFO info;
   i := p_active_form;
   info.m_form_wid=p_active_form;
   if (isInteractiveForm()) {
      gtbInteractiveFormList:[i]=info;
   } else {
      gtbTerminalFormList:[i]=info;
   }

   ignore_change = true;
   _terminal_tab.p_DocumentMode = true;
   _update_terminal_tabs(p_active_form.p_window_id);
   ignore_change = false;
   _sort_tabs(_control _terminal_tab);
   if (!isInteractiveForm()) {
      _terminal_tab.p_ClosableTabs=_terminal_tab.p_NofTabs>1;
   } else {
      _terminal_tab.p_ClosableTabs=true;
   }
   //_show_terminal_tab(0, p_active_form.p_window_id);

}

void _tbterminal_form.on_destroy()
{
   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id,ON_DESTROY,'2');
   if (isInteractiveForm()) {
      gtbInteractiveFormList._deleteel(p_active_form);
   } else {
      gtbTerminalFormList._deleteel(p_active_form);
   }
}

void _tbterminal_form.on_resize()
{
   // RGH - 4/26/2006
   // For the plugin, resize the SWT container then do the normal resize
   int clientW = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   int clientH = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   _terminal_tab.p_width = clientW - 2 * _terminal_tab.p_x;
   _terminal_tab.p_y_extent = clientH - _terminal_tab.p_x;
   // resize editor controls within each active tab
   int first_child = _terminal_tab.p_child;
   if (first_child) {
      int child = first_child;
      do {
         _str idname;
         idname=child.p_user;
         //parse child.p_name with (TERMINAL_CONTAINER) idname;
         edit_wid := _find_control( '_terminal'idname );
         if ( edit_wid ) {
            edit_wid.p_width = child.p_width;
            edit_wid.p_height = child.p_height;
         }
         child = child.p_next;
      } while ( child != first_child );
   }
   ctlnew_wid:=_find_control('ctlnew');
   if (ctlnew_wid) {
      ctlnew_wid.p_height=p_active_form.p_height;
      ctlnew_wid.p_width=p_active_form.p_width;
   }
}

static void _close_tab(int tab_index,int form_wid) {
   int tab_id= form_wid._terminal_tab;
   int orig_tab = tab_id.p_ActiveTab;
   if (tab_id.p_NofTabs <= 1 && !form_wid.isInteractiveForm()) {
      // not allowed
      return;
   }

   tab_id.p_ActiveTab = tab_index;
   int cid = tab_id._getActiveWindow();
   idname:=cid.p_user;
   //parse cid.p_name with (TERMINAL_CONTAINER) auto idname;
   
   editorctl_wid:=form_wid._find_control("_terminal":+idname);

   //editorctl_wid:=form_wid._find_control("_terminal":+idname);
   for (i:=0;i<_process_error_file_stack._length();++i) {
      if (_process_error_file_stack[i]==editorctl_wid.p_buf_name) {
         _process_error_file_stack._deleteel(i);
         break;
      }
   }

   int orig_wid;
   get_window_id(orig_wid);
   
   TBTERMINAL_FORM_INFO v;
   int i2;
   TBTERMINAL_FORM_INFO tblist:[];
   if (!form_wid.isInteractiveForm()) {
      tblist=gtbTerminalFormList;
   } else {
      tblist=gtbInteractiveFormList;
   }
   foreach (i2 => v in tblist) {
      if (v.m_form_wid==form_wid) {
         continue;
      }
      int tab_id2 = v.m_form_wid._terminal_tab;
      int cid2 = tab_id2.sstContainerByName(TERMINAL_CONTAINER:+idname);
      if (cid2) {
         tab_id2.p_ActiveTab = cid2.p_ActiveOrder;
         tab_id2._deleteActive();
         if (!form_wid.isInteractiveForm()) {
            tab_id2.p_ClosableTabs=tab_id2.p_NofTabs>1;
         } else if (tab_id2.p_NofTabs==0) {
            _create_tree_control(v.m_form_wid,tab_id2);
         }
      }
   }
   
   activate_window(orig_wid);
   
   if (( editorctl_wid.p_buf_flags & VSBUFFLAG_HIDDEN) && !_DialogViewingBuffer(editorctl_wid.p_buf_id,editorctl_wid)) {
      editorctl_wid._delete_buffer();
   }

   // delete from active tab list
   //int cid = tab_id._getActiveWindow();
   //typeless idname;
   //parse cid.p_name with (TERMINAL_CONTAINER) idname;
   tab_id._deleteActive();
   if (tab_index != orig_tab) {
      tab_id.p_ActiveTab = orig_tab;
   }
   if (!form_wid.isInteractiveForm()) {
      tab_id.p_ClosableTabs=tab_id.p_NofTabs>1;
   } else if (tab_id.p_NofTabs==0) {
      _create_tree_control(form_wid,tab_id);
   }
}
static void _create_tree_control(int form_wid,int tab_id) {
   tab_id.p_visible=false;
   browse_button_height := 300;
   ctlnew_wid:=_create_window(OI_TREE_VIEW, form_wid, '',
                       0,
                       0,
                       form_wid.p_width, form_wid.p_height,//width and height
                       CW_CHILD);
   //ctlnew_wid.p_caption="New...";
   //ctlnew_wid.p_auto_size=true;
   ctlnew_wid.p_visible=true;
   ctlnew_wid.p_name='ctlnew';
   ctlnew_wid.p_help='';
   ctlnew_wid.p_eventtab=defeventtab _interactive_new_tree;
   ctlnew_wid.p_eventtab2=defeventtab _ul2_tree;
   ctlnew_wid._update_profile_list();
}
static void _update_profile_list() {
   _TreeDelete(TREE_ROOT_INDEX, 'C');
   _str langs[];
   _GetAllLangIds(langs);
   for (i:=0;i<langs._length();++i) {
      langid:=langs[i];
      _str profileNames[];
      _plugin_list_profiles(vsCfgPackage_for_LangInteractiveProfiles(langid),profileNames);
      if (profileNames._length()) {
         if (profileNames._length()==1) {
            _TreeAddItem(TREE_ROOT_INDEX, _LangGetModeName(langid), TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF,0,_interactive_get_idname(langid,profileNames[0]));
         } else {
            parent:=_TreeAddItem(TREE_ROOT_INDEX, _LangGetModeName(langid), TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_EXPANDED);
            for (j:=0;j<profileNames._length();++j) {
               _TreeAddItem(parent, profileNames[j], TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF,0,_interactive_get_idname(langid,profileNames[j]));
            }
         }
      }
   }
}
static void _update_terminal_tabs(int form_wid)
{
   int tab_id = form_wid._terminal_tab;

   int cid = tab_id._getActiveWindow();
   orig_idname:=cid.p_user;
   //parse cid.p_name with (TERMINAL_CONTAINER) auto orig_idname2;

   while (tab_id.p_NofTabs > 0) tab_id._deleteActive();
   _str array_idnames[];
   if (isInteractiveForm()) {
      _interactive_list_idnames(array_idnames);
   } else {
      _terminal_list_idnames(array_idnames);
   }
   if (array_idnames._length()==0) {
      if (isInteractiveForm()) {
         _create_tree_control(form_wid,tab_id);
      } else {
         // Want at least one tab.
         form_wid._create_terminal_tab(tab_id, _terminal_new_idname());
      }
   } else {
      for (i:=0;i<array_idnames._length();++i) {
         form_wid._create_terminal_tab(tab_id, array_idnames[i]);
      }
   }

   // restore old tab if possible
   cid = tab_id.sstContainerByName(TERMINAL_CONTAINER:+orig_idname);
   if (cid) {
      tab_id.p_ActiveTab = cid.p_ActiveOrder;
   }
}


static int clicked_tabid = -1;
_command void cbmenu_terminal(_str cmdline = "") name_info(',' VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _macro_delete_line();
   form_wid := p_active_form;
   if (p_active_form.p_name:!=TBTERMINAL_FORM_NAME_STRING && p_active_form.p_name:!=TBINTERACTIVE_FORM_NAME_STRING) {
       return;
   }
   _str command;
   _str id;
   parse cmdline with command id;
   switch (lowcase(command)) {
   case 'open':
      if (id=='') {
         if (form_wid.isInteractiveForm()) {
         } else {
            id=_terminal_new_idname();
            _add_new_terminal_tab(id);
         }
      } else {
         if (form_wid.isInteractiveForm()) {
            start_process(false,true,false,true,id);
         } else {
            _add_new_terminal_tab(id);
         }
      }
      break;

   case 'closetab':
      if ( clicked_tabid >= 0 ) {
         _close_tab(clicked_tabid,form_wid);
      }
      break;

   }
}

void _terminal_tab.rbutton_up()
{
   int tabi = mou_tabid();
   if (tabi < 0) {
      clicked_tabid = -1;
      p_active_form.call_event(p_active_form, RBUTTON_UP);
      return;
   }
   // get the menu form
   int index = find_index("_tbterminal_menu", oi2type(OI_MENU));
   if (!index) {
      clicked_tabid = -1;
      return;
   }
   clicked_tabid = tabi;

   int menu_handle = p_active_form._menu_load(index, 'P');
   //int mf_flags;
   int submenu_handle=menu_handle;
   //_menu_get_state(menu_handle, 0, mf_flags, 'p', "", submenu_handle);
   int i, j;

   int tab_id = p_active_form._terminal_tab;

   if (isInteractiveForm()) {
      _str langs[];
      _GetAllLangIds(langs);
      for (i=0;i<langs._length();++i) {
         langid:=langs[i];
         _str profileNames[];
         _plugin_list_profiles(vsCfgPackage_for_LangInteractiveProfiles(langid),profileNames);
         if (profileNames._length()) {
            if (profileNames._length()==1) {
               _menu_insert(menu_handle, -1, MF_ENABLED, _LangGetModeName(langid), "cbmenu_terminal open "_interactive_get_idname(langid,profileNames[0]), "", "", "");
            } else {
               _menu_insert(menu_handle, -1, MF_ENABLED|MF_SUBMENU, _LangGetModeName(langid));
               typeless submenu_handle2;
               _menu_get_state(menu_handle,_menu_info(menu_handle)-1, auto mf_flags,'P',auto caption, submenu_handle2);
               for (j=0;j<profileNames._length();++j) {
                  _menu_insert(submenu_handle2, -1, MF_ENABLED, profileNames[j], "cbmenu_terminal open "_interactive_get_idname(langid,profileNames[j]), "", "", "");
                  //ctlnew_wid._TreeAddItem(parent, profileNames[j], TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF,0,_interactive_get_idname(langid,profileNames[j]));
               }
            }
         }
      }
   } else {
      _str idnames[]; 
      _terminal_list_idnames(idnames);
      for (i=0;i<idnames._length();++i) {
         idname:=idnames[i];
         int cid = tab_id.sstContainerByName(TERMINAL_CONTAINER:+idname);
         if (!cid) {
            _menu_insert(submenu_handle, -1, MF_ENABLED, _terminal_idname_to_tab_name(idname), 'cbmenu_terminal open 'idname, "", "", "");
         }
      }

      _menu_insert(submenu_handle, -1, MF_ENABLED, "New", "cbmenu_terminal open", "", "", "");
      if (tab_id.p_NofTabs <= 1) {
         _menu_set_state(menu_handle, 2, MF_GRAYED, 'P');
      }
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
   _str idlist[];
   int first_child = tab_id.p_child;
   int child = first_child;
   do {
      //parse child.p_name with (TERMINAL_CONTAINER) auto idname;
      idname:=child.p_user;
      idlist[idlist._length()] = idname;
      child = child.p_next;
   } while ( child != first_child );

   idlist._sort('i');

   found := 0;
   foreach (auto i in idlist) {
      int cid = tab_id.sstContainerByName(TERMINAL_CONTAINER:+i);
      if (cid) {
         cid.p_ActiveOrder = found++;
      }
   }
}

static int _create_terminal_tab(int tab_id, _str idname)
{
   if (idname=='') {
      return 0;
   }
   if (isInteractiveForm()) {
      ctlnew_wid:=_find_control('ctlnew');
      if (ctlnew_wid) {
         ctlnew_wid._delete_window();
         tab_id.p_visible=true;
      }
   }
   int new_tab = tab_id.p_NofTabs;
   ++tab_id.p_NofTabs;
   tab_id.p_ActiveTab = new_tab;
   if (isInteractiveForm()) {
      tab_id.p_ActiveCaption = _interactive_idname_to_tab_name(idname);
   } else {
      tab_id.p_ActiveCaption = _terminal_idname_to_tab_name(idname);
   }

   int container_id = tab_id._getActiveWindow();
   container_id.p_name = TERMINAL_CONTAINER:+idname;
   container_id.p_user=idname;
   int edit_id = _create_window(OI_EDITOR, container_id, "", 0, 30, container_id.p_width, container_id.p_height, CW_CHILD|CW_HIDDEN);
   edit_id.p_name = '_terminal'idname;
   edit_id.p_MouseActivate = MA_NOACTIVATE;
   edit_id.p_scroll_bars = SB_BOTH;
   edit_id.p_tab_index=new_tab+1;
   buffer_name :=  _process_buffer_name(idname);
   
   parse buf_match(buffer_name,1,'vhx') with auto buf_id .;
   int temp_view=0;
   int orig_wid=p_window_id;
   if (buf_id=='') {
      orig_wid = _find_or_create_temp_view(temp_view, '-fshowextraline +futf8 +t', buffer_name, false, VSBUFFLAG_THROW_AWAY_CHANGES | VSBUFFLAG_HIDDEN | VSBUFFLAG_KEEP_ON_QUIT);
      buf_id=temp_view.p_buf_id;
   }
   docname(tab_id.p_ActiveCaption);
   edit_id._delete_buffer();
   activate_window(orig_wid);
   edit_id.p_buf_id = (int)buf_id;
   edit_id.p_eventtab= defeventtab _tbterminal_form._terminal_tab;
   if (isInteractiveForm()) {
      // Setup in start_process2()
      //edit_id._SetEditorLanguage('process');
   } else {
      //edit_id.p_eventtab= defeventtab _tbterminal_form._terminal_tab;
      edit_id._SetEditorLanguage('process');
   }
   edit_id.p_UTF8 = true;
   edit_id.p_visible = true;
   //edit_id.p_window_flags |= (OVERRIDE_CURLINE_RECT_WFLAG | CURLINE_RECT_WFLAG);
   //edit_id.p_KeepPictureGutter = true;
   bottom();
   if (temp_view) {
      _delete_temp_view(temp_view);
      activate_window(orig_wid);
   }

   if (!ignore_change) {
      _sort_tabs(tab_id);
      tab_id.p_ActiveTab = container_id.p_ActiveOrder;   //set active tab after sorting
      p_active_form.call_event(p_active_form, ON_RESIZE, 'W');
   }
   if (!isInteractiveForm()) {
      tab_id.p_ClosableTabs=tab_id.p_NofTabs>1;
   } else {
      _terminal_tab.p_ClosableTabs=true;
   }
   return edit_id;
}

static int _show_terminal_tab(_str idname, int form_wid=-1)
{
   /*if (form_wid < 0) {
      form_wid = getTerminalForm();
   } */
   if (form_wid>0) {
      if (idname=='') {
         idname=_terminal_new_idname();
      }
       int tab_id = form_wid._terminal_tab;
       int cid = tab_id.sstContainerByName(TERMINAL_CONTAINER:+idname);
       if (cid) {
          tab_id.p_ActiveTab = cid.p_ActiveOrder;
          return form_wid._find_control("_terminal":+idname);
       } else {
          return form_wid._create_terminal_tab(form_wid._terminal_tab, idname);
       }
    }
   return 0;
}

_str _get_active_terminal_view()
{
   int tab_id = _find_object(TBTERMINAL_FORM_NAME_STRING"._terminal_tab", "n");
   if (tab_id) {
      int active_id = tab_id._getActiveWindow();
      idname:=active_id.p_user;
      //parse active_id.p_name with (TERMINAL_CONTAINER) auto idname;
      if (idname != "") {
         return "_terminal":+idname;
      }
   }
   return ("");
}

_str _get_active_interactive_view()
{
   int tab_id = _find_object(TBINTERACTIVE_FORM_NAME_STRING"._terminal_tab", "n");
   if (tab_id) {
      int active_id = tab_id._getActiveWindow();
      if (active_id==0) {
         return 'ctlnew';
      }
      idname:=active_id.p_user;
      //parse active_id.p_name with (TERMINAL_CONTAINER) auto idname;
      if (idname != "") {
         return "_terminal":+idname;
      }
   }
   return 'ctlnew';
}

static void _add_new_terminal_tab(_str idname,TBTERMINAL_FORM_INFO (&terminalFormList):[]=gtbTerminalFormList)
{
   int orig_wid;
   get_window_id(orig_wid);
   
   TBTERMINAL_FORM_INFO v;
   int i;
   foreach (i => v in terminalFormList) {
      _show_terminal_tab(idname, v.m_form_wid);
   }
   
   activate_window(orig_wid);
}
static void _maybe_update_profile_list(int form_wid) {
   ctlnew_wid:=form_wid._find_control('ctlnew');
   if (ctlnew_wid>0) {
      ctlnew_wid._update_profile_list();
   }
}
void _cbinteractive_profiles_changed_tool_window()
{
   int orig_wid;
   get_window_id(orig_wid);
   
   TBTERMINAL_FORM_INFO v;
   int i;
   foreach (i => v in gtbInteractiveFormList) {
      _maybe_update_profile_list(v.m_form_wid);
   }
   
   activate_window(orig_wid);
}

/*
void _terminal_tab.'ENTER'() {
    _build_tab_enter();
}
void _terminal_tab.'TAB'()
{
   process_tab();
} 
*/

void _terminal_tab.on_change(int reason, int arg1 = 0, int arg2 = 0)
{
   if (reason == CHANGE_TAB_CLOSE_BUTTON_CLICKED) {
      // arg1 is the tab the user clicked to close
      if( arg1 >= 0 ) {
         _close_tab(arg1,p_active_form);
      }
   }
}

int _toolShowTerminal(_str idname) {

   int formwid = activate_tool_window('_tbterminal_form', true, '', false);
   if ( formwid > 0 ) {
      _add_new_terminal_tab(idname);
      editorctl_wid:=_show_terminal_tab(idname,formwid);
      return editorctl_wid;
   }
   return 0;
}

int _toolShowInteractive(_str idname) {

   int formwid = activate_tool_window('_tbinteractive_form', true, '', false);
   if ( formwid > 0 ) {
      _add_new_terminal_tab(idname,gtbInteractiveFormList);
      editorctl_wid:=_show_terminal_tab(idname,formwid);
      return editorctl_wid;
   }
   return 0;
}

defeventtab _interactive_new_tree;
/*void _interactive_new_tree.'ENTER',lbutton_double_click()
{
   
}    */
void _interactive_new_tree.on_change(int reason,int index) {
   switch (reason) {
   case CHANGE_LEAF_ENTER:
      //say('CHANGE_LEAF_ENTER');
      //say(_TreeGetUserInfo(index));
      
      start_process(false,true,false,true,_TreeGetUserInfo(index));
      //_show_terminal_tab(_TreeGetUserInfo(index), p_active_form);
      break;
   }
}

void _exit_terminal() {
   _str idnames[];
   int i;
   _terminal_list_idnames(idnames,true);
   for (i=0;i<idnames._length();++i) {
      _process_info('q',idnames[i]);
   }
   _interactive_list_idnames(idnames,true);
   for (i=0;i<idnames._length();++i) {
      _process_info('q',idnames[i]);
   }
}


static const INTERACTIVE_PROFILE_LANGUAGE_ID= "interactive_langId";
defeventtab _interactive_profiles_form;
void ctlprofiles.on_change(int reason,int index)
{
    //say('reason='reason);
    update_buttons();
}
static void update_buttons() {
   langId := _GetDialogInfoHt(INTERACTIVE_PROFILE_LANGUAGE_ID);
   if (langId==null || langId=='') langId='py';
   index:=ctlprofiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index<0) {
      ctledit.p_enabled=false;
      ctldelete.p_enabled=false;
      ctlcopy.p_enabled=false;
      //ctlcreatecopy.p_caption="New...";
      return;
   }
   index=ctlprofiles._TreeCurIndex();
   ctlcopy.p_enabled=true;
   ctledit.p_enabled=true;
   profileName := ctlprofiles._TreeGetCaption(index);
   if (_plugin_has_builtin_profile(vsCfgPackage_for_LangInteractiveProfiles(langId),profileName)) {
      ctldelete.p_enabled=false;
   } else {
      ctldelete.p_enabled=true;
   }
}
static void update_profile_list() {
   langId := _GetDialogInfoHt(INTERACTIVE_PROFILE_LANGUAGE_ID);
   //ctlprofiles._lbclear();
   ctlprofiles._TreeDelete(TREE_ROOT_INDEX,'C');
   _str profileNames[];
   _plugin_list_profiles(vsCfgPackage_for_LangInteractiveProfiles(langId),profileNames);
   for (i:=0;i<profileNames._length();++i) {
      ctlprofiles._TreeAddItem(TREE_ROOT_INDEX,profileNames[i],TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF);
   }
   update_buttons();
}
void ctldelete.lbutton_up() {
   langId := _GetDialogInfoHt(INTERACTIVE_PROFILE_LANGUAGE_ID);
   index:=ctlprofiles._TreeCurIndex();
   if (index<0) {
      return;
   }
   ctlprofiles._TreeGetInfo(index,auto showChildren,auto nonCurrentBMIndex,auto currentBMIndex,auto nodeFlags,auto lineNumber);
   profileName := ctlprofiles._TreeGetCaption(index);
   status := _message_box("Are you sure you want to delete the profile '"profileName"'?  This action can not be undone.", "Confirm Profile Delete", MB_YESNO | MB_ICONEXCLAMATION);
   if (status == IDYES) {
      _plugin_delete_profile(vsCfgPackage_for_LangInteractiveProfiles(langId),profileName);
      /*status=_fileProjectDeleteProfile(langId, profileName);
      if (status) {
         return;
      } */
      ctlprofiles._TreeDelete(index);
      //IF the node we deleted was bold
      if (nodeFlags & TREENODE_BOLD) {
         index=ctlprofiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         if (index>0) {
            index=ctlprofiles._TreeCurIndex();
            ctlprofiles._TreeSetInfo(index,TREE_NODE_LEAF,-1,-1,TREENODE_BOLD);
         }
      }
      update_buttons();
      call_list('_cbinteractive_profiles_changed_');
   }
}
static bool _dont_check_program() {
   return false;
}
void ctledit.lbutton_up() {
   langId := _GetDialogInfoHt(INTERACTIVE_PROFILE_LANGUAGE_ID);
   index:=ctlprofiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index<0) {
      return;
   }
   _str orig_profileNames[];
   _plugin_list_profiles(vsCfgPackage_for_LangInteractiveProfiles(langId),orig_profileNames);

   _str profileName=ctlprofiles._TreeGetCaption(ctlprofiles._TreeCurIndex());
   args:=_plugin_get_property(vsCfgPackage_for_LangInteractiveProfiles(langId),profileName,'command');
   pgm:=parse_file(args,false);
   use_pty:=_plugin_get_property(vsCfgPackage_for_LangInteractiveProfiles(langId),profileName,'use_pty',0);
   if (!isinteger(use_pty)) {
      use_pty=0;
   }
   _str result;
   if (_isUnix()) {
      result = show("-modal _textbox_form",
                    profileName' Profile Settings', // Form caption
                    0,                // Flags
                    0,                // Use default textbox width
                    "",               // Help item
                    "Save Settings,Cancel:_cancel\t",
                    "",               // Retrieve Name
                     '-e '_dont_check_program' -c 'PATH_SEARCH_NOQUOTES_ARG:+_chr(0)"-bfnq Program:"pgm,
                     "Arguments:"args,
                    '-checkbox Use Pseudo TTY:'use_pty
                    );
   } else {
      result = show("-modal _textbox_form",
                    profileName' Profile Settings', // Form caption
                    0,                // Flags
                    0,                // Use default textbox width
                    "",               // Help item
                    "Save Settings,Cancel:_cancel\t",
                    "",               // Retrieve Name
                     '-e '_dont_check_program' -c 'PATH_SEARCH_NOQUOTES_ARG:+_chr(0)"-bfnq Program:"pgm,
                     "Arguments:"args
                    );
   }
   if (result==1) {
      command:=_maybe_quote_filename(_param1);
      if (_param2!='') {
         strappend(command,' '_param2);
      }
      _plugin_set_property(vsCfgPackage_for_LangInteractiveProfiles(langId),profileName,VSCFGPROFILE_INTERACTIVE_VERSION,'command',command);
      if (_isUnix()) {
         _plugin_set_property(vsCfgPackage_for_LangInteractiveProfiles(langId),profileName,VSCFGPROFILE_INTERACTIVE_VERSION,'use_pty',_param3);
      }
   }

#if 0
   handle:=_fileProjectEditProfile(langId,profileName);
   if (handle<0) {
      return;
   }
   displayName := '"'profileName'"';
   /*_MDICurrent().*/show('-modal -xy _project_form',displayName,handle);
#endif

   // We may have a added a profile
   _str profileNames[];
   _plugin_list_profiles(vsCfgPackage_for_LangInteractiveProfiles(langId),profileNames);
   if (profileNames!=orig_profileNames) {
      update_profile_list();
   }
}
static void _interactive_add_profile(_str langId,_str profileName,_str copyFrom='') {
   _str profileNames[];
   _plugin_list_profiles(vsCfgPackage_for_LangInteractiveProfiles(langId),profileNames);
   for (i:=0;i<profileNames._length();++i) {
      if (strieq(profileNames[i],profileName)) {
         _message_box(nls('Profile %s already exists',profileName));
         return;
      }
   }

   dest_handle := -1;
   if (copyFrom!='') {
      dest_handle=_plugin_get_profile(vsCfgPackage_for_LangInteractiveProfiles(langId),copyFrom);
   }
   if (dest_handle<0) {
      dest_handle=_xmlcfg_create_profile(auto profile_node,vsCfgPackage_for_LangInteractiveProfiles(langId),profileName,VSCFGPROFILE_INTERACTIVE_VERSION);
   } else {
      profile_node:=_xmlcfg_get_document_element(dest_handle);
      _xmlcfg_set_attribute(dest_handle,profile_node,VSXMLCFG_PROFILE_NAME,_plugin_append_profile_name(vsCfgPackage_for_LangInteractiveProfiles(langId),profileName));
   }
   _plugin_set_profile(dest_handle);
   _xmlcfg_close(dest_handle);
}
static void copy_or_new(bool doCopy=false) {
   langId := _GetDialogInfoHt(INTERACTIVE_PROFILE_LANGUAGE_ID);
   curProfileName := "";
   if (doCopy) {
      index:=ctlprofiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if (index>0) {
         curProfileName = ctlprofiles._TreeGetCaption(ctlprofiles._TreeCurIndex());
      }
   }
   _str profileName;
   status:=_plugin_prompt_add_profile(vsCfgPackage_for_LangInteractiveProfiles(langId),profileName,curProfileName);
   if (status) {
      return;
   }
   _interactive_add_profile(langId, profileName, curProfileName);
   update_profile_list();
   index:=ctlprofiles._TreeSearch(TREE_ROOT_INDEX,profileName,'i');
   if (index>0) {
      ctlprofiles._TreeSetCurIndex(index);
   }
   call_list('_cbinteractive_profiles_changed_');
}
void ctlcopy.lbutton_up() {
   copy_or_new(true);
}
void ctlnew.lbutton_up() {
   copy_or_new(false);
}

/*void _interactive_profiles_form_restore_state(_str options) {
    beautifier_schedule_deferred_update(100, p_active_form, '_bc_update_preview_cb');
} */

void _interactive_profiles_form_init_for_options(_str langId)
{
   //langId := _get_language_form_lang_id();
   //if (langId==null || langId=='') langId='py';
   _SetDialogInfoHt(INTERACTIVE_PROFILE_LANGUAGE_ID,langId);

   update_profile_list();
}
bool _interactive_profiles_form_apply()
{
   //langId := _GetDialogInfoHt(INTERACTIVE_PROFILE_LANGUAGE_ID);
   //_str default_profile=_findDefaultProfile();
   //_fileProjectSetDefaultProfile(langId,default_profile);
   //_SetDialogInfoHt(FILEPROJECT_ORIG_DEFAULT_PROFILE,default_profile);
   return true;
}

bool _interactive_profiles_form_is_modified()
{
   //origDefaultProfileName:=_GetDialogInfoHt(FILEPROJECT_ORIG_DEFAULT_PROFILE);
   //_str default_profile=_findDefaultProfile();

   //return !strieq(origDefaultProfileName,default_profile);
   return false;
}
_str _interactive_profiles_form_export_settings(_str &file, _str &args, _str langId)
{
   error := '';
   dest_handle:=_xmlcfg_create('',VSENCODING_UTF8);
   NofProfiles:=_xmlcfg_export_profiles(dest_handle,vsCfgPackage_for_LangInteractiveProfiles(langId));
   if (!NofProfiles) {
      _xmlcfg_close(dest_handle);
      return error;
   }

   justName:=vsCfgPackage_for_LangInteractiveProfiles(langId)'.cfg.xml';
   destFilename:=file:+justName;
   status:=_xmlcfg_save(dest_handle,-1,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE,destFilename);
   if (status) {
      error=get_message(status);
   }
   //_showxml(dest_handle);
   _xmlcfg_close(dest_handle);
   file=justName;
   return error;
}

_str _interactive_profiles_form_import_settings(_str &file, _str &args, _str langId)
{
   error := '';
   if (file!='') {
      _xmlcfg_import_from_file(file);
      call_list('_cbinteractive_profiles_changed_');
   }
   return error;
}


/**
 * Extension speicific callback for process buffer to
 * insert argument completions for files / directories
 * visible in the current directory of the process buffer.
 */
void _process_autocomplete_get_arguments(typeless &words)
{
   if (!_isEditorCtl() || p_window_state=='I') {
      return;
   }
   idname:=_ConcurProcessName();
   if (idname!=null && _process_is_interactive_idname(idname)) {
      // don't add any completion words
      return;
   }
   last_event(TAB);
   process_tab(true,words);
}

int _process_autocomplete_get_prefix(_str &word,int &word_start_col=0,_str &complete_arg=null,int &start_word_col=0)
{
   args_to_command := true;
   return_val := false;
   line := "";
   col := 1;
   line=_expand_tabsc();
   col=p_col;

   _str temp_line=line;

   name_prefix := "";
   int match_flags=FILE_CASE_MATCH;
   completion_info := "f:"(FILE_CASE_MATCH)"*";

   // IF we are selecting files
   // For compatibility with bash throw in '='.  This is so that
   //     ./configure --prefix=/gtk<Tab>
   // works just like the bash shell.  Not sure we = was added.  We
   // may have to add back slash support so a\=b works for a file
   // or directory named "a=b".
   _str alternate_temp_line=translate(temp_line,"   ","=>|<");
   // Translate redirection characters to space
   temp_line=alternate_temp_line;

   // IF the current and previous characters are space
   if (col>1 && substr(temp_line,col-1,2,"*"):=="  ") {
      // Split the line so we insert a word here instead of replacing
      // the next word.
      temp_line=substr(temp_line,1,col);
   }

   /* if the current character is a space and the previous character is not. */
   /* Try to expand the current argument on the command line. */
   int arg_number= _get_arg_number(temp_line,col,word,start_word_col,args_to_command,completion_info);
   complete_arg=word;
   word_start_col=start_word_col;
   if (substr(word,1,1)=='"') {
      word=substr(word,2);
      ++word_start_col;
   }
   name := _strip_filename(word,'p');
   word_start_col+=length(word)-length(name);
   word=name;
   //say("get_prefix: word="word" autocomp_col="col" start_col="start_word_col);
   return(0);
}

static bool _process_bufferr_filenameNeedsToBeQuoted(_str filename) {
   if (_isUnix()) {
      return  pos('[ &><|*?\[\]()!'';]',filename,1,'r')!=0;
   }
   return  pos('[ &]',filename,1,'r') || pos('^^',filename);
}
void _autocomplete_process(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol)
{
   //say("_autocomplete_process: i="insertWord" p="prefix);
   autocomplete_start_col := 0;
   word := "";
   complete_arg := "";
   int start_word_col;
   /*
       This function could work better if it also supported a\<space>b.
       It's just a lot of work (even the secsh shell would need to be modified) and
       very little pay back. So far, no users have complained about this.

       There are the following problems with the current implementation:
          * Users should not type \<space> in the process buffer. 
            Must use double quotes.
          * The problem with using double quotes is that you can insert filenames
            which require quotes before then end of the command line because the
            first double quote is assumed to end at the end of the command line.
   */
   _process_autocomplete_get_prefix(word,autocomplete_start_col,complete_arg,start_word_col);

   removeStartCol=start_word_col;
   starts_with_quote := substr(complete_arg,1,1)=='"';
   path := _strip_filename(strip(complete_arg,'L','"'),'n');
   if (def_unix_expansion && !starts_with_quote && 
       _process_bufferr_filenameNeedsToBeQuoted(path:+insertWord)) {
      path=_unix_expansion(path);
   }
   p_col-=length(complete_arg);
   hadQuote := get_text()=="";
   _delete_text(length(complete_arg));
   if (starts_with_quote ||
       _process_bufferr_filenameNeedsToBeQuoted(path:+insertWord)
       ) {
      _insert_text('"'path:+insertWord);
      if (!hadQuote) {
         removeLen=1;
      }
   } else {
      removeLen=0;
      _insert_text(path:+insertWord);
   }
}

/**
 * Handle the TAB key in the process buffer.  Tab will invoke the
 * auto complete system if it is not already active in order to list
 * file completions.
 *
 * @param autoCompleteAlreadyRunning    Is auto-complete already active?
 * @param autoCompleteWords             List of completions to add to
 */
_command void process_tab(_str autoCompleteAlreadyRunning="", typeless &autoCompleteWords=null) name_info(','VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   //bsay("process_tab: running"autoCompleteAlreadyRunning);
   if ( !command_state() && p_window_state:!='I') {
      idname:=_ConcurProcessName();
      if (_process_is_interactive_idname(idname)) {
         /*
            Could do better here.

            Simple enhancement: Indent by the syntax indent defined for this language.
         */
         call_root_key(last_event());
         return;
      }
      int col;
      if ( _process_info('c') ) {
         col=_process_info('c');
      } else {
         col=1;
      }
      if (p_line!=p_Noflines ||
          p_col<col
         ) {
         if (autoCompleteAlreadyRunning!=true) {
            call_root_key(last_event());
            return;
         }
      } else {
         if (autoCompleteAlreadyRunning!=true) {
            autocomplete();
            return;
         }
      }
      _str cmd=_expand_tabsc(col,-1,'S');
      _str cur;
      parse cmd with cur .;
      do_files := true;
      if (_file_eq("cd",cur) || _file_eq("pushd",cur) || _file_eq("rmdir",cur)) {
         do_files=false;
      }
      // at this point, doAutoComplete will always be true
      doAutoComplete := (autoCompleteAlreadyRunning==true);
      if (do_files) {
         maybe_list_matches("f:"(FILE_CASE_MATCH)"*" /*MULTI_FILE_ARG*/,"",true,true,true,"path_search:"(FILE_CASE_MATCH|REMOVE_DUPS_MATCH)"*",doAutoComplete,autoCompleteWords,false,false,col);
      } else {
         maybe_list_matches("dir:"(FILE_CASE_MATCH)"*" /*MULTI_FILE_ARG*/,"",true,true,true,"path_search:"(FILE_CASE_MATCH|REMOVE_DUPS_MATCH)"*",doAutoComplete,autoCompleteWords,false,false,col);
      }
      return;
   }
   call_root_key(last_event());

}
void _process_common_command_after(_str cmd,_str idname='') {
   _str cur,temp;
   parse cmd with cur temp;
   if (_file_eq("cd",cur) || _file_eq("pushd",cur)) {
      /*
        Minor bug:  The dos "cd" command does not change the active drive
           when a different drive is specified than the current drive.  The "vs" cd
           command changes the active drive.
        Minor bug:  The dos "cd" command supports multiple commands on one line.  The "vs"
           cd commands does not.
      */
      if (_isUnix()) {
         temp=_unix_expansion(temp);
      }
      if (_file_eq("cd",cur)) {
         if (temp=='' && (_isUnix() || _isMac())) {
            temp=_unix_expansion('~');
         }
         cd("-p -a "temp);
      } else {
         pushd("-p -a "temp);
      }
   } else if (_file_eq("popd",cur)) {
      popd();
   }
   /*
      For now, key off of send_on_enter. If that's not good enough, this
      could be changed to check if this is an interactive terminal.
   */
   _insert_retrieve(_process_retrieve_id(idname),cmd);

   // If the command shell has exited, the close the build window
   if (def_close_build_window_on_exit) {
      if (_process_info("x") || !_process_info("r")) {
         quit();
      }
   }
}
bool _process_within_submission() {
   if (command_state()) {
      return false;
   }
   idname:=_ConcurProcessName();
   rp_linenum:=_process_get_read_point_linenum();
   typeless send_on_enter=_process_info('E',idname);
   if (!(_process_info('b') && 
            ((!send_on_enter && p_line==p_Noflines) || 
             (send_on_enter && p_line>=rp_linenum)
            ) 
        )
      ) {
      return false;
   }
   return true;
}
/**
 * New binding of ENTER key when in process mode.  When invoked
 * while the cursor is on the last line of the build window, a
 * blank line is inserted after the current line and the contents of the
 * current line after the "read point" is inserted in the ".process-
 * command" retrieve buffer for latter use by the <b>process_up</b> or
 * <b>process_down</b> command.  Otherwise the fundamental mode
 * ENTER key binding is executed.  Process output is inserted at the
 * character before the "read point".
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void process_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if ( !command_state() && p_window_state:!='I') {
      idname:=_ConcurProcessName();
      if (idname!=null && _process_info('E',idname) && def_interactive_split_enter && _process_within_submission()) {
         split_insert_line();
         return;
      }
      if (select_active2() && _within_selection()) {
         copy_to_clipboard();
         // Not sure why this seemed to emulate a DOS terminal but tried to immediately run the selection
#if 0
         command := "";
         int first_col,last_col,buf_id;
         _get_selinfo(first_col,last_col,buf_id);
         if (_select_type('','I')) ++last_col;
         if (_select_type()=="LINE") {
            command=_expand_tabsc();
         } else {
            command=_expand_tabsc(first_col,last_col-first_col);
         }
         _deselect();
         concur_command(command);
#endif
         return;
      }
      rp_linenum:=_process_get_read_point_linenum();
      typeless send_on_enter=_process_info('E',idname);
      if (!_process_within_submission()) {
         if (!_process_info('',idname)) {
            start_process(false,true,false,true,idname);
            return;
         }
         call_root_key(last_event());
         return;
      }
      orig_view_id := p_window_id;
      if ( def_auto_reset ) {
         if (p_buf_name!='.process') {
            reset_next_error("0","",0);
         } else {
            reset_next_error("","",0);
         }
         /* clear_message */
      }
      if (p_buf_name!='.process') {
         _push_next_error_terminal(true);
      }
      p_window_id=orig_view_id;

      _str cmd;
      if (!send_on_enter) {
         int col;
         if ( _process_info('c') ) {
            col=_process_info('c');
         } else {
            col=1;
         }
         cmd=_expand_tabsc(col,-1,'S');
         p_col=col;
         _delete_text(-1);
         if (_NeedVslickErrorInfo2(cmd) && !_process_is_interactive_idname(idname)) {
            _insert_text(_VslickErrorInfo():+"\n"cmd"\n");
         }else{
            _insert_text(cmd"\n");
         }
         _process_common_command_after(cmd,idname);
      } else {
         save_pos(auto p);
         _begin_line();
         status:=search('[^ \t]','@r');
         _first_non_blank();
         all_blank_lines:=status!=0; //p_col>_text_colc(0,'L');
         restore_pos(p);
         if (_process_is_interactive_idname(_ConcurProcessName()) && _interactive_smart_enter('nosplit_insert_line')) {
            if (p_col!=1 && !all_blank_lines) {
               return;
            }
            p_col=1;
         }
         if (send_on_enter) { 
            _process_info('R',idname);
         }
      }
      return;
   }
   call_root_key(last_event());

}
void _process_select_submission(_str markid='') {
   goto_read_point();
   if (_process_info('c')) {
      p_col=_process_info('c');
   } else {
      p_col=1;
   }
   mstyle := "";
   if ( def_persistent_select=='Y' ) {
      mstyle='EP';
   } else {
      mstyle='E';
   }
   _deselect(markid);
   _select_char(markid,mstyle);
   bottom();
   _select_char(markid,mstyle);
}
_command void process_select_all() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_TEXT_BOX|VSARG2_READ_ONLY|LASTKEY_ARG2)
{
   if (command_state()) {
      call_root_key(last_event());
      return;
   }
   if (!_process_within_submission() || select_active2() || (last_event():==C_A && name_on_key(C_A):!='select-all')) {
      call_root_key(last_event());
      return;
   }
   _process_select_submission();
   if (_isnull_selection()) {
      _deselect();
      call_root_key(last_event());
      return;
   }
   _cua_select=1;
}
/**
 * New binding of HOME key when in process mode.  When invoked
 * while the cursor is on the last line of the build window, the
 * cursor is moved to column one or the "read point" column if the cursor
 * is on the line containing the "read point".  Otherwise the fundamental
 * mode HOME key binding is executed.  Process output is inserted at
 * the character before the "read point".
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void process_begin_line() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      _begin_line();
      return;
   }
   if ( _process_info('c') && _process_info('c')<p_col  || (_process_info('c')==p_col && name_on_key(last_event())!='brief-home')) {
      p_col=_process_info('c');
      if ( p_left_edge && p_col<p_char_width-2 ) {
         set_scroll_pos(0,p_cursor_y);
      }
      return;
   }
   call_root_key(last_event(),true);

}
/**
 * New binding of UP key when in process mode.  When invoked while
 * the cursor is on the last line of the build window, the
 * previous command is retrieved from the ".process" buffer.
 * Otherwise the fundamental mode UP key binding is executed.
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void process_up(_str do_prev='') name_info(','VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   idname:=_ConcurProcessName();
   if ( ! command_state() && _process_info('b') && idname!=null && name_name(prev_index()):!="root-keydef" && !_in_selection() ) {
      send_on_enter:=_process_info('E',idname);
      rp_linenum:=_process_get_read_point_linenum();
      if ( (!_process_info('E',idname) && p_line:==p_Noflines) || 
           (_process_info('E',idname) && p_line>=rp_linenum)
         ) {
         _str text;
         if (do_prev) {
            text=pretrieve_prev(_process_retrieve_id(idname));
         } else {
            text=pretrieve_next(_process_retrieve_id(idname));
         }
         
         int ModifyFlags=p_ModifyFlags;
         if (!_process_info('E',idname)) {
            int col;
            if ( _process_info('c') ) {
               col=_process_info('c');
            } else {
               col=1;
            }
            _str line=_expand_tabsc(1,col-1,'S');
            replace_line(line);
         } else {
            p_line=rp_linenum;
            p_col=_process_info('c');
            _delete_text(-2);
         }
         _end_line();_insert_text(text);
         p_ModifyFlags=ModifyFlags;
         set_scroll_pos(0,p_cursor_y);
         _end_line();
         return;
      }

   }
   call_root_key(last_event());

}
/**
 * New binding of DOWN key when in process mode.  When invoked
 * while the cursor is on the last line of the build window, the
 * next command is retrieved from the "process-buffer".  Otherwise the
 * fundamental mode key DOWN key binding is executed.
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void process_down() name_info(','VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   process_up(0);

}
/**
 * New binding of BACKSPACE key when in process mode.  When
 * invoked while the cursor is on the last line of the build window,
 * deletes character to the left of the cursor unless cursor is in
 * column 1 or at "read point".  Otherwise the fundamental mode
 * BACKSPACE key binding is executed.  Process output is inserted at
 * the character before the "read point".
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void process_rubout() name_info(','VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   // IF running UNIX pseudo TTY and entering password (text hidden) at current cursor position
   if (! command_state() && _process_info('h')) {
      // send backspace character
      _process_info('k');
      return;
   }
   idname:=_ConcurProcessName();
   if ( ! command_state() && _process_info('b') &&
        (_process_info('c')==p_col ||
         (! _process_info('c') && p_line:==p_Noflines && p_col==1 && !_process_info('E',idname))
        )
      ) {
      return;
   }
   call_root_key(last_event());

}
bool _interactive_smart_enter(_str fall_thru_command) {
   if (_process_info('b') && 
       (_process_is_interactive_idname(_ConcurProcessName()) && _process_within_submission())
      ) {
      langid:=_interactive_get_lang_from_idname(_ConcurProcessName());
      _str szEventTableName=_LangGetProperty(langid,VSLANGPROPNAME_EVENTTAB_NAME);
      if (szEventTableName!="") {
         mode_eventtab:=_eventtab_get_mode_keys(szEventTableName);
         int enter_index=eventtab_index(mode_eventtab,mode_eventtab,event2index(ENTER));
         if (enter_index) {
            rp_linenum:=_process_get_read_point_linenum(auto rp_col);
            rel_linenum:=p_line-rp_linenum+1;rel_col:=p_col;
            //say('***rel_line='rel_linenum' rel_col='rel_col);
            if (_process_info('c')) {
               rel_col-=_process_info('c')-1;
            }
            save_pos(auto p);
            markid:=_alloc_selection();
            _process_select_submission(markid);
            last_event(ENTER);
            orig_wid:=_create_temp_view(auto temp_wid);
            _SetEditorLanguage(langid);
            insert_line('');_end_line();_delete_text(-2);
            _move_to_cursor(markid);_deselect(markid);
            p_line=rel_linenum;p_col=rel_col;
            //say('h1 Noflines='p_Noflines);
            CMDUI cmdui;cmdui.menu_handle=0;cmdui.button_wid=0;
            flags:=_OnUpdate_toggle_beautify_on_edit(cmdui,temp_wid,'');
            // Turn off beautify while typing if it's on.
            if ((flags & MF_ENABLED) && (flags & MF_CHECKED)) {
               toggle_beautify_on_edit();
               _smart_enter_with_fall_thru(enter_index,fall_thru_command);
               toggle_beautify_on_edit();
            } else {
               _smart_enter_with_fall_thru(enter_index,fall_thru_command);
            }
            //say('h2 Noflines='p_Noflines);
            new_rel_col:=p_col;new_rel_line:=p_line;
            //say('new_rel_line='new_rel_line' new_rel_col='new_rel_col' len='_line_length(false));
            top();_select_char(markid);
            _select_char(markid);bottom();
            _delete_text(-2);
            _select_char(markid);
            //say('h3 Noflines='p_Noflines);
            //say('Noflines='orig_wid.p_Noflines);
            orig_wid.goto_read_point();orig_wid.p_col=rp_col;
            orig_wid._copy_to_cursor(markid);
            //say((rp_linenum+new_rel_line-1)' rp_linenum-'rp_linenum' new_rel_line='new_rel_line);
            new_linenum:=rp_linenum+new_rel_line-1;
            orig_wid.restore_pos(p);
            down();
            if (orig_wid.p_line!=new_linenum) {
               orig_wid.p_line=new_linenum;
            }
            orig_wid.p_col=new_rel_col;
            //say('new_rel_col='new_rel_col);
            _free_selection(markid);
            _delete_temp_view(temp_wid);
            p_window_id=orig_wid;
            return true;
         } else {
            execute(fall_thru_command);
         }
      }
   }
   return false;
}

int _OnUpdate_interactive_load_file(CMDUI cmdui, int target_wid, _str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   idname:=target_wid._ConcurProcessName();
   if (idname==null) {
      _str profileNames[];
      _plugin_list_profiles(vsCfgPackage_for_LangInteractiveProfiles(target_wid.p_LangId),profileNames);
      if (!profileNames._length()) {
         if (cmdui.menu_handle) {
            _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
            _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
            return MF_DELETED;
         }
         return MF_GRAYED;
      }
   } else if (!_process_is_interactive_idname(idname)) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED;
      }
      return MF_GRAYED;
   }
   return(MF_ENABLED);
}
int _OnUpdate_interactive_load_selection(CMDUI cmdui, int target_wid, _str command) {
   return _OnUpdate_interactive_load_file(cmdui,target_wid,command);
}
_command void interactive_load_file() name_info(','VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK) {
   interactive_load_selection('F');
}
_command void interactive_load_selection(_str option='') name_info(','VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK) {

   option=upcase(option);
   _str profileNames[];
   _plugin_list_profiles(vsCfgPackage_for_LangInteractiveProfiles(p_LangId),profileNames);
   _str idname=null;
   int temp_wid=-1;
   orig_wid:=p_window_id;
   save_pos(auto p);
   if (!profileNames._length()) {
      if (!_process_is_interactive_idname(_ConcurProcessName())){
         if (_ConcurProcessName()=='' || _process_is_terminal_idname(_ConcurProcessName())){
            return;
         }
         _message_box("No interactive profiles defined for this language type");
         return;
      }
      idname= _ConcurProcessName();
      if (option=='F') {
         typeless filename=_OpenDialog('-modal',
                                     'Load File',
                                     '',      // Initial wildcards
                                     def_file_types,
                                     OFN_FILEMUSTEXIST,
                                                '',
                                                ''
                                     );
         if (filename=='') {
            return;
         }
         filename = parse_file(filename,false);
         _open_temp_view(filename,temp_wid,orig_wid);
      }
   }
   if (idname==null) {
      _str list[];
      for (i:=0;i<profileNames._length();++i) {
         idname=_interactive_get_idname(p_LangId,profileNames[i]);
         process_buffer_name:=_process_buffer_name(idname);
         if (buf_match(_maybe_quote_filename(process_buffer_name),1,'hx')!='') {
            list[list._length()]= idname;
         }
      }
      if (list._length()==1) {
         idname=list[0];
      } else if (profileNames._length()==1) {
         idname=_interactive_get_idname(p_LangId,profileNames[0]);
      } else {
         _str buttons = nls('&Add Buffers,&Invert,&Clear,&Order');
         profileName:= p_window_id.show('_sellist_form -modal',
                       "Choose Interactive Profile",
                       SL_SELECTCLINE,
                       profileNames
                      );
         orig_wid._set_focus();
         if (profileName=='') {
            return;
         }
         idname=_interactive_get_idname(p_LangId,profileName);
      }
   }
   //if (!_process_is_interactive_idname(_ConcurProcessName())) {
   //}
   int markid=-1;
   if (option=='F') {
      markid=_alloc_selection();
      top();
      if (p_line!=0) {
         _select_char(markid);
         bottom();
         _select_char(markid);
      }
   } else {
      if (!select_active2()) {
         markid=_alloc_selection();
         _begin_line();_select_char(markid);
         _end_line();_select_char(markid);
         if (_select_type(markid)=='') {
            restore_pos(p);
            clear_message();
            _free_selection(markid);
            return;
         }
      }
   }
   _str orig_max = _default_option(VSOPTION_WARNING_STRING_LENGTH);
   _default_option(VSOPTION_WARNING_STRING_LENGTH,0x7FFFFFFF);
   text:=_GetSelectedText(markid,-1,null);
   _default_option(VSOPTION_WARNING_STRING_LENGTH, orig_max);
   if (markid!='') {
      _free_selection(markid);
   }
   if (temp_wid>=0) {
      _delete_temp_view(temp_wid);
   }
   p_window_id=orig_wid;
   if (text==null) {
      message("No text to load");
   }
   status:=concur_command(text,false,true,false,false,idname);
   if(!_process_is_interactive_idname(_ConcurProcessName())){
      restore_pos(p);
   }
   if (!status) {
      _set_focus();
   }
}

static void start_interactive(_str langid,_str profileName='') {
    if (profileName=='') {
       if (_plugin_has_profile(vsCfgPackage_for_LangInteractiveProfiles(langid),_LangGetModeName(langid))) {
          profileName=_LangGetModeName(langid);
       } else {
          _str profileNames[];
          _plugin_list_profiles(vsCfgPackage_for_LangInteractiveProfiles(p_LangId),profileNames);
          if (!profileNames._length()) {
             return;
          }
          profileName=profileNames[0]; // Not great, but better than nothing.
       }
    }
    start_process(false,true,false,true,_interactive_get_idname(langid,profileName));
}
_command void start_interactive_clojure() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   start_interactive('clojure');
}
_command void start_interactive_coffeescript() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   start_interactive('coffeescript');
}
_command void start_interactive_csharp() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   start_interactive('cs');
}
_command void start_interactive_groovy() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   start_interactive('groovy');
}
_command void start_interactive_haskell() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   start_interactive('haskell');
}
_command void start_interactive_lua() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   start_interactive('lua');
}
_command void start_interactive_php() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   start_interactive('phpscript');
}
_command void start_interactive_perl() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   start_interactive('pl');
}
_command void start_interactive_powershell() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   start_interactive('powershell');
}
_command void start_interactive_python2() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   if (_isWindows()) {
      start_interactive_python();
      return;
   }
   start_interactive('py','Python2');
}
_command void start_interactive_python3() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   if (_isWindows()) {
      start_interactive_python();
      return;
   }
   start_interactive('py','Python3');
}
_command void start_interactive_python() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   if (_isUnix()) {
      start_interactive_python3();
      return;
   }
   start_interactive('py');
}
_command void start_interactive_r() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   start_interactive('r');
}
_command void start_interactive_ruby() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   start_interactive('ruby');
}
_command void start_interactive_scala() name_info(','VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   start_interactive('scala');
}
