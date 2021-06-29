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
#import "listbox.e"
#import "se/ui/mainwindow.e"
#import "stdprocs.e"
#import "search.e"
#endregion

// Combobox on button bar with search info

static const SEARCHOPTION_DELIM= "/";
defeventtab _tbsearch_hist_etab;

void _menu_add_searchhist(_str string, _str options)
{
   //if (!_mdi.p_button_bar) return;
   search_text := string:+SEARCHOPTION_DELIM:+options;
   typeless eventtab=defeventtab _tbsearch_hist_etab;
   int wid;
   for (wid=1;wid<=_last_window_id();++wid) {
      if (_iswindow_valid(wid) && !wid.p_edit && wid.p_eventtab==eventtab) {
         wid._lbdeselect_all();
         wid._lbfind_and_delete_item(search_text);
         wid._lbtop(); wid._lbup();
         wid._lbadd_item(search_text);
         wid._lbselect_line();
         wid.p_sel_start = 1; wid.p_sel_length = 0;
         wid._refresh_scroll();
      }
   }
   _append_retrieve(0, search_text, "_tbsearch_hist_etab.p_user");
}

void _tbsearch_hist_etab.on_drop_down(int reason)
{
   if (_no_child_windows()) return;

   int target_wid = _MDIGetActiveMDIChild();
   if (!target_wid) return;

   switch (reason) {
   case DROP_UP_SELECTED: //User picked from list and we need to find
      _str line=_lbget_text();
      activate_window(target_wid);
      string := substr(line,1,lastpos(SEARCHOPTION_DELIM,line)-1);
      options := substr(line,lastpos(SEARCHOPTION_DELIM,line)+1);
      find(string,options);
      break;
   case DROP_UP:
      target_wid._set_focus();
      break;
   }
}

void _tbsearch_hist_etab.ENTER()
{
   if (_no_child_windows()) return;

   int target_wid = _MDIGetActiveMDIChild();
   if (!target_wid) return;

   line := p_text;
   activate_window(target_wid);
   p_window_id=_mdi.p_child;
   _str string,options;
   if (pos(SEARCHOPTION_DELIM,line)) {
      string=substr(line,1,lastpos(SEARCHOPTION_DELIM,line)-1);
      options=substr(line,lastpos(SEARCHOPTION_DELIM,line)+1);
   } else {
      string=line;
      options=_search_default_options();
   }
   find(string,options);
   target_wid._set_focus();
}

void _tbsearch_hist_etab.ESC()
{
   if (!_no_child_windows()) {
      int target_wid = _MDIGetActiveMDIChild();
      if (!target_wid) return;

      target_wid._set_focus();
      activate_window(target_wid);
   }
}

_tbsearch_hist_etab.on_create()
{
   maybe_bbar_wid := p_parent;
   p_width=2500;
   p_AllowDeleteHistory=true;
   _retrieve_list("_tbsearch_hist_etab.p_user");
   _lbtop();
   _lbselect_line();
   p_sel_start = 1; p_sel_length = 0;
   _refresh_scroll();
}
// returns the window id of the first search history combo box.
// returns 0 if there isn't one.
static int search_hist_combo_wid()
{
   //if (_mdi.p_button_bar) {
      typeless eventtab=defeventtab _tbsearch_hist_etab;
      int i;
      for (i=1;i<=_last_window_id();++i) {
         if (_iswindow_valid(i) && !i.p_edit && i.p_eventtab==eventtab) {
            return(i);
         }
      }
   //}
   return(0);
}

// Actvates the listbox of the first search history combo box found on the
// button bar
_command void maybe_active_search_hist_list()
{
   int wid=search_hist_combo_wid();
   if (wid) {
      int old_wid=p_window_id;
      wid._set_sel(1,length(wid.p_text)+1);
      p_window_id=wid;
      p_visible=true;
      _set_focus();
      _lbdeselect_all();
      _lbselect_line();
      p_window_id=old_wid;
   }
}
