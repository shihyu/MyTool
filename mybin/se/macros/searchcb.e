////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47103 $
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
#import "stdprocs.e"
#import "search.e"
#endregion

// Combobox on button bar with search info

#define SEARCHOPTION_DELIM "/"
defeventtab _tbsearch_hist_etab;

// Gets the value of the forms field from the current buffer which is
// a temp buffer.
static int get_data(_str contents,_str ControlName,_str &output,
                    _str RetrieveControlType,_str DefaultValue)
{
   parse contents with (_chr(0)RetrieveControlType' 'ControlName':') output (_chr(0)) ;
   if (output=="") {
      output=DefaultValue;
      return(1);
   }
   return(0);
}

// Will find control on button bar named '_bbcombo_search_hist' and get history
// of searches from .command buffer.
// arg(1) is the wid of the comboboxes list to initialize
// rescan the .command buffer
// finding the one on the button bar.
static int _search_hist_get_all(int window_id)
{
   p_window_id=window_id;
   int orig_view_id=p_window_id;
   _lbclear();
   int command_view_id;
   int status=_open_temp_view('.dialogs',command_view_id,orig_view_id,'+b');
   if (status) {
      return 0;
   }
   p_window_id=command_view_id;
   top();
   // Search for start of _find_form
   status=search('^_find_form\:','@r');
   if (!status) {
      get_line(auto line);
      typeless Nofdialogs;
      parse line with ':' Nofdialogs .;
      int i;
      for (i=0;i<Nofdialogs;++i) {
         p_window_id=command_view_id;
         down();
         get_line(auto contents);
         // Search for control after _find_form
         typeless string,backward,case_sensitive,word,re,wrap,mark,cursorend,coloroptions;
         get_data(contents,'_findstring',string,'cb',"");
         int bstatus=get_data(contents,'_findbackward',backward,'ra',0);
         get_data(contents,'_findcase',case_sensitive,'ch',0);
         get_data(contents,'_findword',word,'ch',0);
         get_data(contents,'_findre',re,'ch',0);
         get_data(contents,'_findwrap',wrap,'ch',0);
         get_data(contents,'_findmark',mark,'ch',0);
         get_data(contents,'_findcursorend',cursorend,'ch',0);
         get_data(contents,'ctlcoloroptions',coloroptions,'te',"");
         _str options='';
         if (!bstatus) {
            if(backward)options=options'-';
         }
         if(case_sensitive){
            options=options'E';
         }else{
            options=options'I';
         }
         if(word)options=options'W';
         if(re)options=options'R';
         if(wrap=='1')options=options'p';
         if(wrap=='2')options=options'?';
         if(mark)options=options'M';
         if(cursorend)options=options'>';
         _str exclude,sinclude;
         parse coloroptions with ',' exclude ',' sinclude;
         options=options:+exclude:+sinclude;
         p_window_id=orig_view_id;
         if (!already_exists(string,options,false)) {
            _lbadd_item(string:+SEARCHOPTION_DELIM:+options);
         }
      }
   }
   _delete_temp_view(command_view_id,0);
   p_window_id=orig_view_id;
   //_remove_duplicates();
   if (1/*posted*/ && p_Noflines) {
      _lbtop();
      p_parent.p_text=_lbget_text();
   }
   return(0);
}

// (options) is a set of search flags in numeric format.  This function
// reutrns the search flags as an options string
static _str search_flag2options(int options)
{
   _str new_options='';
   if (options&IGNORECASE_SEARCH) {
      new_options=new_options'I';
   }else{
      new_options=new_options'E';
   }
   if (options&MARK_SEARCH) {
      new_options=new_options'M';
   }
   if (options&POSITIONONLASTCHAR_SEARCH) {
      new_options=new_options'>';
   }
   if (options&REVERSE_SEARCH) {
      new_options=new_options'-';
   }
   if (options&RE_SEARCH) {
      new_options=new_options'R';
   }
   if (options&WORD_SEARCH) {
      new_options=new_options'W';
   }
   if (options&WRAP_SEARCH) {
      new_options=new_options'P';
   }
   return(new_options);
}

//Adds the proper line to the Search History Combo Box
//Also adds a phony gui find to the .command buffer
//If arg(3) is not null, (options) is converted from numeric to string format
void _menu_add_searchhist(_str string, typeless options, _str convert_options='')
{
   //if (!_mdi.p_button_bar) return;
   typeless eventtab=defeventtab _tbsearch_hist_etab;
   int i;
   for (i=1;i<=_last_window_id();++i) {
      if (_iswindow_valid(i) && !i.p_edit && i.p_eventtab==eventtab) {
         int wid=i;
         if (convert_options != '') {
            options=search_flag2options(options);
            convert_options='';
         }
         add_phony_gui_find(string,options);
         if (!wid.already_exists(string,options,true)) {
            int old_wid=p_window_id;
            p_window_id=wid;
            _lbdeselect_all();
            _lbtop();_lbup();
            _lbadd_item(string:+SEARCHOPTION_DELIM:+options);
            _lbselect_line();
            p_window_id=old_wid;
         }
      }
   }
}

//If "(string),(options)" does not exist in the list box, returns 0.
//If "(string),(options)" is already there, moves it to the top
static boolean already_exists(_str string,_str options,boolean doMove)
{
   save_pos(auto p);
   top();
   _str search_string='^?'_escape_re_chars(string:+SEARCHOPTION_DELIM:+options);
   int status=search(search_string,'r@');
   if (status) return false;
   if (!doMove) {
      restore_pos(p);
      return true;
   }
   get_line(auto line);
   _delete_line();
   top();up();
   insert_line(substr(line,1,1):+string:+SEARCHOPTION_DELIM:+options);
   return true;
}

//Drop down event handler for the search combo box
_tbsearch_hist_etab.on_drop_down(int reason)
{
   switch (reason) {
   case DROP_UP_SELECTED: //User picked from list and we need to find
      _str line=_lbget_text();
      p_window_id=_mdi.p_child;
      _str string=substr(line,1,lastpos(SEARCHOPTION_DELIM,line)-1);
      _str options=substr(line,lastpos(SEARCHOPTION_DELIM,line)+1);
      find(string,options);
      break;
   case DROP_UP:
      _mdi.p_child._set_focus();
      break;
   }
}

//someone hit enter in the combobox
_tbsearch_hist_etab.ENTER()
{
   int twid=p_window_id;
   _str line=twid.p_text;
   p_window_id=_mdi.p_child;
   _str string,options;
   if (pos(SEARCHOPTION_DELIM,line)) {
      string=substr(line,1,lastpos(SEARCHOPTION_DELIM,line)-1);
      options=substr(line,lastpos(SEARCHOPTION_DELIM,line)+1);
   }else{
      string=line;
      options=_search_default_options();
   }
   find(string,options);
   _mdi.p_child._set_focus();
}

_tbsearch_hist_etab.ESC()
{
   if (!_no_child_windows()) {
      _mdi.p_child._set_focus();
      p_window_id=_mdi.p_child;
      //This is to get rid of the cursor square in the edit window
      int status=up();
      if (!status) down();
   }
}

_tbsearch_hist_etab.on_create()
{
   int maybe_bbar_wid=p_parent;
   p_width=2500;
   _search_hist_get_all(p_window_id);
#if 0
   if (maybe_bbar_wid==_mdi.p_button_bar) {
      //this avoids some on_create events that happen when it is originally
      //placed on the template
      _post_call(find_index('_search_hist_get_all',PROC_TYPE),p_window_id);
   }
#endif
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
      p_visible=1;
      _set_focus();
      _lbdeselect_all();
      _lbselect_line();
      p_window_id=old_wid;
   }
}

// Dan added for search cb on button bar
// Just add stuff to .command buffer as if this had been executed from the
// dialog Find box.
static void add_phony_gui_find(_str string,_str options)
{
   int temp_view_id,orig_view_id;
   int status=_open_temp_view('.dialog',temp_view_id,orig_view_id,'+b');
   if (status) {
      return;
   }
   p_window_id=temp_view_id;
   top();
   status=search('^_find_form\:','@r');
   if (status) {
      bottom();
      insert_line('_find_form:0 0');
   }
   get_line(auto line);
   _str b4;
   typeless Nofdialogs;
   typeless NoflinesToCurRetrieve;
   parse line with b4':' Nofdialogs NoflinesToCurRetrieve;
   replace_line(b4':'(++Nofdialogs)' 'NoflinesToCurRetrieve);
   down(Nofdialogs-1);
   _str contents=' ';
   contents=contents:+_chr(0):+'cb _findstring:'string;
   if (pos('-',options)) {
      contents=contents:+_chr(0):+'ra _findbackward:1';
   }else{
      contents=contents:+_chr(0):+'ra _findforward:1';
   }
   // get wrap options
   int wrap_options=pos('p',options)? 1:0;
   if (pos('?',options)) wrap_options=2;
   //All the (!(!()) stuff just makes sure that we have a 1 or 0
   contents=contents:+_chr(0):+'ch _findcase:':+(!(!(pos('e',options))));
   contents=contents:+_chr(0):+'ch _findre:':+(!(!(pos('r',options))));
   contents=contents:+_chr(0):+'ch _findmark:':+(!(!(pos('m',options))));
   contents=contents:+_chr(0):+'ch _findcusorend:':+(!(!(pos('>',options))));
   contents=contents:+_chr(0):+'ch _findwrap:':+wrap_options;
   contents=contents:+_chr(0):+'ch _findword:':+(!(!(pos('w',options))));
   //the real options are all above here, the rest is just filler
   contents=contents:+_chr(0):+'ch _mfsubdir:0';
   contents=contents:+_chr(0):+'te _mffiles:';
   contents=contents:+_chr(0):+'ch _mfproject_files:0';
   contents=contents:+_chr(0):+'ch list_all:0';
   insert_line(contents);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id,0);
}
