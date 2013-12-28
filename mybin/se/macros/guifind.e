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
#include "search.sh"
#import "bgsearch.e"
#import "compile.e"
#import "complete.e"
#import "dlgman.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "makefile.e"
#import "markfilt.e"
#import "menu.e"
#import "mfsearch.e"
#import "picture.e"
#import "projconv.e"
#import "recmacro.e"
#import "search.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbfind.e"
#import "wkspace.e"
#endregion

enum_flags MFSearchInitFlags {
   MFSEARCH_INIT_HISTORY   = 0x1,
   MFSEARCH_INIT_CURWORD   = 0x2,
   MFSEARCH_INIT_SELECTION = 0x4
};

//search globals
int old_search_flags;
int old_search_flags2;
_str old_search_string;

_command int gui_find_modal(...) name_info(','VSARG2_EDITORCTL)
{
   int was_recording = _macro();
   int result = show('-modal -reinit _gui_find_form', arg(1), p_window_id);
   _macro('m', was_recording);
   if (result == '') {
      _macro_delete_line();
      return(COMMAND_CANCELLED_RC);
   }
   if (_isEditorCtl()) {
      _ExitScroll();
   }
   return(l(_param1,_param2));
}

defeventtab _gui_find_form;

_findstring.on_create()
{
   _gui_find_form_initial_alignment();

   int wid = arg(2);
   _findok.p_user = wid;
   _findstring.p_text = old_search_string;
   if ((def_mfsearch_init_flags & MFSEARCH_INIT_CURWORD)
       && wid._isEditorCtl(false)) {
      int junk;
      _findstring.p_text = wid.cur_word(junk, '', 1);
   }
   if (def_mfsearch_init_flags & MFSEARCH_INIT_SELECTION) {
      if (wid._isEditorCtl(false) && wid.select_active2()) {
         int mark_locked = 0;
         if (_select_type('', 'S') == 'C') {
            mark_locked = 1;
            _select_type('', 'S', 'E');
         }
         _str str;
         wid.filter_init();
         wid.filter_get_string(str);
         wid.filter_restore_pos();
         _findstring.p_text = str;
         if (mark_locked) {
            _select_type('', 'S','C');
         }
      }
   }
   if (wid.p_HasBuffer && !wid.select_active2()) {
      _findmark.p_enabled = 0;
   }
   int flags = (def_find_init_defaults == 0) ? old_search_flags : _default_option('s');
   if (flags & VSSEARCHFLAG_REVERSE) {
      _findback.p_value = 1;
   } else {
      _findback.p_value=0;
   }
   _findcase.p_value = (int)!(flags & VSSEARCHFLAG_IGNORECASE);
   _findword.p_value = flags & VSSEARCHFLAG_WORD;
   _findmark.p_value = flags & VSSEARCHFLAG_MARK;
   _findwrap.p_value = ((flags & VSSEARCHFLAG_WRAP) ? 1 : 0) + ((flags & VSSEARCHFLAG_PROMPT_WRAP) ? 1 : 0);
   _findre.p_value = flags & (VSSEARCHFLAG_RE | VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE | VSSEARCHFLAG_PERLRE | VSSEARCHFLAG_WILDCARDRE);
   _findcursorend.p_value = flags & VSSEARCHFLAG_POSITIONONLASTCHAR;
   _findhidden.p_value = flags & VSSEARCHFLAG_HIDDEN_TEXT;
   _findre_type._lbadd_item(RE_TYPE_UNIX_STRING);
   _findre_type._lbadd_item(RE_TYPE_BRIEF_STRING);
   _findre_type._lbadd_item(RE_TYPE_SLICKEDIT_STRING);
   _findre_type._lbadd_item(RE_TYPE_PERL_STRING);
   _findre_type._lbadd_item(RE_TYPE_WILDCARD_STRING);
   if (flags & (VSSEARCHFLAG_RE | VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE | VSSEARCHFLAG_PERLRE | VSSEARCHFLAG_WILDCARDRE)) {
      _findre_type._init_re_type(flags & (VSSEARCHFLAG_RE | VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE | VSSEARCHFLAG_PERLRE | VSSEARCHFLAG_WILDCARDRE));
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
static void _gui_find_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(_findstring.p_window_id, ctlremenu.p_window_id);
}

_findok.lbutton_up()
{
   _str search_options;
   int wid = _findok.p_user;
   if (_findcase.p_value) {
      search_options = '';
   } else {
      search_options = 'I';
   }
   if (_findword.p_value) {
      search_options = search_options'W';
   }
   if (_findre.p_value) {
      switch (_findre_type.p_text) {
      case RE_TYPE_UNIX_STRING:      search_options = search_options'U'; break;
      case RE_TYPE_BRIEF_STRING:     search_options = search_options'B'; break;
      case RE_TYPE_SLICKEDIT_STRING: search_options = search_options'R'; break;
      case RE_TYPE_PERL_STRING:      search_options = search_options'L'; break;
      case RE_TYPE_WILDCARD_STRING:  search_options = search_options'&'; break;
      }        
   }
   if (_findwrap.p_value == 2) {
      search_options = search_options'?';
   } else if (_findwrap.p_value) {
      search_options = search_options'P';
   }
   if (_findmark.p_value && _findmark.p_enabled) {
      search_options = search_options'M';
   }
   if (_findback.p_value) {
      search_options = search_options'-';
   }
   if (_findcursorend.p_value) {
      search_options = search_options'>';
   }
   if (_findhidden.p_value) {
      search_options = search_options'H';
   }
   _param2 = search_options;
   _param1 = _findstring.p_text;
   p_active_form._delete_window(1);
}

void _findre.lbutton_up()
{
   _findre_type.p_enabled = ctlremenu.p_enabled =_findre.p_value ? true : false;
}

/**
 * Used to position the <b>Prompt Replace dialog box</b> and 
 * <b>Spelling dialog box</b> so that it does not overlap the line with an 
 * occurrence found.  If you have a similar dialog box, use this function.  
 * <i>form_wid</i> is the window id of the dialog box form.  
 * <i>buf_wid</i> is the window id of the window which displays the 
 * buffer.
 * 
 * @categories Form_Functions
 * 
 */ 
void _search_form_xy(int form_wid,int buf_wid)
{
   // Save the buffer (x,y), width, and height for manipulation
   int buf_x = buf_wid.p_x;
   int buf_y = buf_wid.p_y;
   _map_xy(buf_wid.p_xyparent, 0, buf_x, buf_y, buf_wid.p_xyscale_mode);
   _lxy2dxy(buf_wid.p_xyscale_mode, buf_x, buf_y);
   int caption_height = buf_wid._top_height();
   int buf_width = buf_wid.p_width;
   int buf_height = buf_wid.p_height;
   _lxy2dxy(buf_wid.p_xyscale_mode, buf_width, buf_height);
   int form_width = form_wid.p_width;
   int form_height = form_wid.p_height;
   _lxy2dxy(form_wid.p_xyscale_mode, form_width, form_height);
   // Get the height of one line in the buffer window
   int buf_line_height = buf_wid._text_height();
   int junk = 0;
   _lxy2dxy(buf_wid.p_scale_mode, junk, buf_line_height);
   buf_line_height = buf_line_height * 10;

   if (buf_line_height < buf_height intdiv 2) {
      buf_line_height = buf_height intdiv 2;
   }

   // Center the form within the buffer window
   int screen_x, screen_y,screen_width, screen_height;
   int x = (buf_x + (buf_width intdiv 2)) - (form_width intdiv 2);
   int y = buf_y + (buf_line_height) + caption_height;
   _GetScreen(screen_x, screen_y, screen_width, screen_height);
   if(y+form_height >= screen_height) {
      // Compute the midpoint of the buffer window in screen coords
      int buf_midpt_x = buf_x + (buf_width intdiv 2);
      int buf_midpt_y = buf_y + (buf_height intdiv 2);

      // Compute the midpoint of the screen
      int screen_midpt_x = (screen_width intdiv 2);
      int screen_midpt_y = (screen_height intdiv 2);

      boolean topflag = (buf_midpt_y < screen_midpt_y);
      boolean leftflag =(buf_midpt_x < screen_midpt_x);
      if(leftflag) {
         x = buf_x + buf_width;
      } else {
         x = buf_x - form_width;
      }
      if(topflag) {
         y = buf_y;
      } else {
         y = buf_y - form_height;
      }
      // Put final (x,y) coordinates back into scale mode of form
      _dxy2lxy(form_wid.p_xyscale_mode, x, y);
      form_wid.p_x = x;
      form_wid.p_y = y;
      form_wid._show_entire_form();
   } else {
      // Put final (x,y) coordinates back into scale mode of form
      _dxy2lxy(form_wid.p_xyscale_mode,x,y);
      form_wid.p_x = x;
      form_wid.p_y = y;
      form_wid._show_entire_form();
   }
}

_command list_search,bf() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _str search_string = '';
   _str search_options = '';
   _macro_delete_line();
   if ( arg(1)=='' ) {
      _message_box('Syntax: list-search /s[/[E][I][R][W]]  E=Exact case I=Ignore case R=R-E W=Word');
      command_put('list-search /');
      return(1);
   }
   if (arg() >= 2) {
      search_string = arg(1);
      search_options = arg(2);
      if (pos(1, search_options)) {
         typeless beg, en;
         parse search_options with beg '1' en;
         search_options = beg:+en;
      }
   } else {
      typeless delim;
      parse arg(1) with 1 delim +1 search_string (delim) search_options;
   }
   _macro_call('list_search', search_string, search_options);
   return(_mffind(search_string, search_options, MFFIND_BUFFER, "", MFFIND_GLOBAL, false, false, '', '', true, 0));
}

_command project_search,pf() name_info(','VSARG2_READ_ONLY)
{   
   _str search_string = '';
   _str search_options = '';
   _macro_delete_line();
   if ( arg(1)=='' ) {
      _message_box('Syntax: project-search /s[/[E][I][R][W]]  E=Exact case I=Ignore case R=R-E W=Word');
      command_put('project-search /');
      return(1);
   }
   if (arg() >= 2) {
      search_string = arg(1);
      search_options = arg(2);
      if (pos(1, search_options)) {
         typeless beg, en;
         parse search_options with beg '1' en;
         search_options = beg:+en;
      }
   } else {
      typeless delim;
      parse arg(1) with 1 delim +1 search_string (delim) search_options;
   }
   _macro_call('project_search', search_string, search_options);
   return(_mffind(search_string, search_options, 
                  MFFIND_BUFFER, "", 
                  MFFIND_GLOBAL|MFFIND_QUIET, 
                  true, false, 
                  ALLFILES_RE, '', true, 0));
}
_command workspace_search,wf() name_info(','VSARG2_READ_ONLY)
{   
   _str search_string = '';
   _str search_options = '';
   _macro_delete_line();
   if ( arg(1)=='' ) {
      _message_box('Syntax: workspace-search /s[/[E][I][R][W]]  E=Exact case I=Ignore case R=R-E W=Word');
      command_put('workspace-search /');
      return(1);
   }
   if (arg() >= 2) {
      search_string = arg(1);
      search_options = arg(2);
      if (pos(1, search_options)) {
         typeless beg, en;
         parse search_options with beg '1' en;
         search_options = beg:+en;
      }
   } else {
      typeless delim;
      parse arg(1) with 1 delim +1 search_string (delim) search_options;
   }
   _macro_call('project_search', search_string, search_options);
   return(_mffind(search_string, search_options, 
                  MFFIND_BUFFER, "", 
                  MFFIND_GLOBAL|MFFIND_QUIET, 
                  false, true,
                  ALLFILES_RE, '', true, 0));
}

/*
     This function is for SlickEdit only.  If you want to insert your own regular
     expressions or untranslated text into a text box or combo box, use the
     "ctlinsert" command.
*/
_command void regexinsert()
{
   _macro_delete_line();
   typeless re, rep;
   parse arg(1) with re rep;

   int re_search_syntax = def_re_search;
   int retype = _find_control('_findre_type');
   if (!retype) {
      // add this for Find Symbol form
      retype = _find_control('ctl_regex_type');
   }
   if (retype) {
      switch(retype.p_text) {
      case RE_TYPE_UNIX_STRING:      re_search_syntax = VSSEARCHFLAG_UNIXRE; break;
      case RE_TYPE_BRIEF_STRING:     re_search_syntax = VSSEARCHFLAG_BRIEFRE; break;
      case RE_TYPE_SLICKEDIT_STRING: re_search_syntax = VSSEARCHFLAG_RE; break;
      case RE_TYPE_PERL_STRING:      re_search_syntax = VSSEARCHFLAG_PERLRE; break;
      case RE_TYPE_WILDCARD_STRING:  re_search_syntax = VSSEARCHFLAG_WILDCARDRE; break;
      }
   }

   if (re=='escape') {
      _str options = 'R';
      if (re_search_syntax == VSSEARCHFLAG_UNIXRE) {
          options = 'U';
      } else if (re_search_syntax == VSSEARCHFLAG_BRIEFRE) {
          options = 'B';
      } else if (re_search_syntax == VSSEARCHFLAG_PERLRE) {
          options = 'L';
      } else if (re_search_syntax == VSSEARCHFLAG_WILDCARDRE) {
         options = '&';
      }
      int wid = p_prev;
      if (wid) {
         _str sel_text;
         int start_sel;
         if (wid.p_sel_length) {
            sel_text = substr(wid.p_text, wid.p_sel_start, wid.p_sel_length);
            start_sel = wid.p_sel_start;
         } else {
            sel_text = wid.p_text;
            start_sel = 1;
            wid._set_sel(1, length(sel_text) + 1);
         }
         _str escape_text = _escape_re_chars(sel_text,options);
         wid.keyin(escape_text);
         wid._set_sel(start_sel);
         int rewid=_find_control('_findre');
         if (!rewid) {
            rewid=_find_control('ctlre');
         }
         if (rewid) {
            rewid.p_value = 1;
            rewid.call_event(rewid,LBUTTON_UP);
         }
      }
      return;
   }
   if (rep == '') {
      if (re_search_syntax == VSSEARCHFLAG_UNIXRE || re_search_syntax == VSSEARCHFLAG_PERLRE) {
         switch (re) {
         case '?':
            re = '.';
            break;
         case '{%\c}':
            re = '(%\c)';
            break;
         case ':%\c':
            re = '{%\c,}';
            break;
         case '(%\c)':
            re = '(?:%\c)';
            break;
         default:
            if (substr(re,1,2) == '\g') {
               re = '\'((int)substr(re, 3) + 1);
            } else if (substr(re, 1, 1) == ':') {
               re = '\'re;
            }
         }
      } else if (re_search_syntax == VSSEARCHFLAG_BRIEFRE) {
         switch (re) {
         case '[^%\c]':
            re = '[~%\c]';
            break;
         case '^':
            re = '<';
            break;
         case '*':
            re = '@';
            break;
         case ':%\c,':
            re = '\:%\c,';
            break;
         case '(%\c)':
            re = '\(%\c)';
            break;
         default:
            if (substr(re, 1, 2) == '\g') {
               re = '\'((int)substr(re,3));
            } else if (substr(re,1,1)==':') {
               re = '\'re;
            }
         }
      } else if (re_search_syntax == VSSEARCHFLAG_WILDCARDRE) {
         //* ?
      }
   } else {
      if (re_search_syntax != VSSEARCHFLAG_RE) {
         if (substr(re, 1, 1) == '#') {
            re='\'((int)substr(re, 2) + 1);
         }
      }
   }
   typeless b4, after;
   parse re with b4 '%\c' after;
   int wid = p_prev;
   if (wid) {
      int start_pos;
      wid._set_focus();
      wid.keyin(b4);
      wid._get_sel(start_pos);
      wid.keyin(after);
      wid._set_sel(start_pos);
      int rewid=_find_control('_findre');
      if (!rewid) {
         rewid=_find_control('ctlre');
      }
      if (rewid) {
         rewid.p_value = 1;
         rewid.call_event(rewid,LBUTTON_UP);
      }
   }
}

void _on_popup2_re_menu(_str menu_name, int menu_handle)
{
   if (menu_name :!= "_re_menu") {
      return;
   }
   int re_search_syntax = def_re_search;
   int retype = _find_control('_findre_type');
   if (retype) {
      switch(retype.p_text) {
      case RE_TYPE_UNIX_STRING:      re_search_syntax = VSSEARCHFLAG_UNIXRE; break;
      case RE_TYPE_BRIEF_STRING:     re_search_syntax = VSSEARCHFLAG_BRIEFRE; break;
      case RE_TYPE_SLICKEDIT_STRING: re_search_syntax = VSSEARCHFLAG_RE; break;
      case RE_TYPE_PERL_STRING:      re_search_syntax = VSSEARCHFLAG_PERLRE; break;
      case RE_TYPE_WILDCARD_STRING:  re_search_syntax = VSSEARCHFLAG_WILDCARDRE; break;
      }
   }

   int re_index = 0;
   if (re_search_syntax == VSSEARCHFLAG_WILDCARDRE) {
      re_index = find_index("_wildcard_re_menu", oi2type(OI_MENU));
   } else {
      re_index = find_index("_default_re_menu", oi2type(OI_MENU));
   }
   if (re_index <= 0) {
      return;
   }
   int child = re_index.p_child;
   if (child) {
      int first_child = child;
      for (;;) {
         if (child.p_object == OI_MENU) {
            _menu_insert_submenu(menu_handle,-1,child,child.p_caption,child.p_categories,child.p_help,child.p_message);
         } else {
            _menu_insert(menu_handle,-1,0,
                         child.p_caption,
                         child.p_command,
                         child.p_categories,
                         child.p_help,
                         child.p_message
                        );
         }
         child=child.p_next;
         if (child == first_child) break;
      }
   }
}

// old gui find

/*
  Clark :
     * Added an if statement to the end of _findok.lbutton_up
     * Appended _command list_search to end of the file(hope the view stuff is ok)
     * Added _findmark.lbutton_up event handler for disabling list all occurences
       checkbox.
     * Forward/Backward and "Place Cursor at End" don't make sense when
       find all occurences is on.
     * Moved the number selected indicator into _mfhook.
       NOTE: Command Line Syntax: list-search <then use same syntax as find>
       EX  : list-search /^_command :w\((:w\,*)\)/?@$/RI-
         (I thought that this was the best way to make sure that you
          could enter flags form the command line)
*/

  _command_button _findok;
  _combo_box _findstring;
  _check_box _findcase;
  _check_box _findword;
  _check_box _findre;
  _check_box _findwrap;
  _check_box _findmark;
/*
_find_form and _replace_form
    _findstring.p_user=1     Indicates that retrieve list has been done
    MFFILES_TEXT=p_text   Save/restore text in ctlmffiles text box
    _mfmore.p_user=1         Indicates that buffer list has been filled.
    _replacestring.p_user=1  Indicates that retrieve list has been done
    _findre.p_user         Form parent
    
    ctlmffiles.p_cb_list_box.p_user Indicates that filespec list has been done
-----------------------------------------------------------------


*/

//#define MFFILES_TEXT _mfcurdir.p_user
#define FINDSTRING_RETRIEVE_DONE _findstring.p_user
#define MFFILES_RETRIEVE_LIST_DONE ctlmffiles.p_user
#define MFFILETYPES_RETRIEVE_LIST_DONE ctlmffiletypes.p_user
#define REPLACESTRING_RETRIEVE_DONE _replacestring.p_user
#define FORM_PARENT ctlfilesmenu.p_user

_str old_search_string,old_word_re,old_replace_string,old_go;
int def_mfsearch_init_flags;

#define COLOR2CHECKBOXTAB "OKNSCPL1234FA"
static _str gcolortab[]={
   "Other",
   "Keyword",
   "Number",
   "String",
   "Comment",
   "Preprocessing",
   "Line Number",
   "Punctuation",
   "Lib Symbol",
   "Operator",
   "User Defined",
   "Function",
   "Attribute",
};

defeventtab _find_form;
void ctlstop.lbutton_up()
{
   stop_search();
}

void ctlsynchronous.lbutton_up()
{
   _mfhook.call_event(CHANGE_SELECTED,_mfhave_input(),_mfhook,LBUTTON_UP,'');
}
void _mfUpdateFindDialog()
{
   int wid = _find_object('_find_form','N');
   if (wid) {
      wid._mfhook.call_event(CHANGE_SELECTED,wid._mfhave_input(),wid._mfhook,LBUTTON_UP,'');
   }
}
void _find_form.on_create()
{
   _find_form_initial_alignment();

   // The following nationalizes the content of the Elements combo box.
   //  Lookup language-specific values for gcolortab
   gcolortab[0] = get_message(VSRC_FF_OTHER);
   gcolortab[1] = get_message(VSRC_FF_KEYWORD);
   gcolortab[2] = get_message(VSRC_FF_NUMBER);
   gcolortab[3] = get_message(VSRC_FF_STRING);
   gcolortab[4] = get_message(VSRC_FF_COMMENT);
   gcolortab[5] = get_message(VSRC_FF_PREPROCESSING);
   gcolortab[6] = get_message(VSRC_FF_LINE_NUMBER);
   gcolortab[7] = get_message(VSRC_FF_SYMBOL1);
   gcolortab[8] = get_message(VSRC_FF_SYMBOL2);
   gcolortab[9] = get_message(VSRC_FF_SYMBOL3);
   gcolortab[10] = get_message(VSRC_FF_SYMBOL4);
   gcolortab[11] = get_message(VSRC_FF_FUNCTION);
   gcolortab[12] = get_message(VSRC_FF_ATTRIBUTE);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _find_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(_findstring.p_window_id, ctlremenu.p_window_id);
   sizeBrowseButtonToTextBox(ctlmffiles.p_window_id, ctlfilesmenu.p_window_id);
}

void _find_form.'F1'()
{
   help('Find Dialog Box');
}
void ctlnocolor.lbutton_up()
{
   ctlcoloroptions.p_text="";
   _findstring._set_focus();
}
void ctlcoloroptions.on_change()
{
   boolean DetermineColors=true;
   _str result;
   if (ctlcolor.p_enabled) {
      ctlnocolor.p_enabled=(p_text!="");
   } else {
      ctlnocolor.p_enabled=false;
      result='';
      DetermineColors=false;
   }
   if (DetermineColors) {
      _str IncludeChars, ExcludeChars;
      int i, j;
      parse p_text with IncludeChars','ExcludeChars',';
      result="";
      for (i=2;i<=length(IncludeChars);++i) {
         j=pos(substr(IncludeChars,i,1),COLOR2CHECKBOXTAB,1,'I');
         //messageNwait("i="i" j="j);
         if (j) {
            if (result=='') {
               result=gcolortab[j-1];
            } else {
               result=result:+', 'gcolortab[j-1];
            }
         }
      }
      for (i=2;i<=length(ExcludeChars);++i) {
         j=pos(substr(ExcludeChars,i,1),COLOR2CHECKBOXTAB,1,'I');
         if (j) {
            if (result=='') {
               result=get_message(VSRC_FF_NOT)' 'gcolortab[j-1];
            } else {
               result=result:+', 'get_message(VSRC_FF_NOT)' 'gcolortab[j-1];
            }
         }
      }
   }
   if (result=="") result="None";
   ctlcolorlabel.p_caption="Colors: "result;
}
void ctlcolor.lbutton_up()
{
   _str result=show('-modal _ccsearch_form',ctlcoloroptions.p_text);
   if (result!='') {
      ctlcoloroptions.p_text=_param1;
      _findstring._set_focus();
   }
}
#if 0
// I don't think it makes sense to have a save settings button
// because typically this dialog box shows that last search
_findsave_settings.lbutton_up()
{
   flags=0;
   flag_names='';
   if(!_findcase.p_value) {
      flags|=def_re_search;
      if (flag_names!='') flag_names=flag_names:+'|';
      flag_names=flag_names:+'IGNORECASE_SEARCH';
   }
   //if(_findword.p_value) flags|= WORD_SEARCH;
   if(_findre.p_value) {
      flags|=def_re_search;
      if (flag_names!='') flag_names=flag_names:+'|';
      if ( def_re_search==UNIXRE_SEARCH ) {
         flag_names=flag_names:+'UNIXRE_SEARCH';
      } else if ( def_re_search==BRIEFRE_SEARCH ) {
         flag_names=flag_names:+'BRIEFRE_SEARCH';
      } else {
         flag_names=flag_names:+'RE_SEARCH';
      }
   }
   if(_findwrap.p_value) {
      flags|=WRAP_SEARCH;
      if (flag_names!='') flag_names=flag_names:+'|';
      flag_names=flag_names:+'WRAP_SEARCH';
   }
   if(_findwrap.p_value==2) {
      flags|=PROMPT_WRAP_SEARCH;
      if (flag_names!='') flag_names=flag_names:+'|';
      flag_names=flag_names:+'PROMPT_WRAP_SEARCH';
   }
   //if(_findmark.p_value) flags|=MARK_SEARCH;
   //messageNwait('flags='(flags & IGNORECASE_SEARCH))
   _default_option('s',flags);
   _config_modify_flags(CFGMODIFY_OPTION);
   save_config();
   _macro('m',_macro('s'));
   _macro_append('_config_modify_flags(CFGMODIFY_OPTION);');
   _macro_call('_default_options',flag_names);
}
#endif
_findlist_all.lbutton_up()
{
   if (_findlist_all.p_visible) {
      ctlsearchbackward.p_enabled=_findcursorend.p_enabled=
           _findwrap.p_enabled=!_findlist_all.p_value;
   }
   int wid=_mfparent();
   if (!_findcursorend.p_enabled) {
      _findcursorend.p_value=0;
   }
   if (_findlist_all.p_value) {
      _findmark.p_enabled=0;
   } else if (!(wid.p_HasBuffer && !wid.select_active2())) {
      _findmark.p_enabled=1;
   }
}

_findstring.on_create()
{
   boolean doExpand=false;

   int wid=_mfparent(arg(2));
   if (!wid._isEditorCtl(false) ||
       (p_active_form.p_name=='_replace_form' && wid._QReadOnly())
       ) {
      doExpand=true;
   } else {
      ctlnocolor.p_enabled=ctlcolor.p_enabled=(wid.p_HasBuffer && wid.p_lexer_name!="");
   }
   // If parent window is not an MDI child window
   if (!wid.p_mdi_child) {
      _mfmore.p_visible=0;
      if(_find_control('_findlist_all') ){
         p_active_form.p_height=_findlist_all.p_y+p_active_form._top_height()+p_active_form._bottom_height();
         _findlist_all.p_visible=0;
      }
   }

   ctlnocolor.p_enabled=ctlcolor.p_enabled=(wid._isEditorCtl(false) && wid.p_lexer_name!="");
   //if (!widcolor.p_enabled) {
   //ctlcoloroptions.call_event(ctlcoloroptions,on_change);
#if 0
   if ((def_mfsearch_init_flags&MFSEARCH_INIT_HISTORY)/* &&
       !(def_mfsearch_init_flags&(MFSEARCH_INIT_CURWORD|MFSEARCH_INIT_SELECTION))*/) {
      _retrieve_prev_form();
   }
#endif
   _retrieve_prev_form();
   ctlmffiletypes._init_mffiletypes();
   if (_findstring.p_text:=='') {
      int replacestring_wid=_find_control('_replacestring');
      if (def_mfsearch_init_flags&MFSEARCH_INIT_HISTORY) {
         _findstring.p_text=old_search_string;
      }
      if (replacestring_wid) {
         replacestring_wid.p_text=old_replace_string;
      }
      int flags;
      if (_findstring.p_text!='') {
         flags=old_search_flags;
      } else {
         flags=_default_option('s');
      }
      if (flags & REVERSE_SEARCH) {
         ctlsearchbackward.p_value=1;
      } else {
         ctlsearchbackward.p_value=0;
      }
      if (_findstring.p_text:=='') {
         _findstring.p_text=old_search_string;
      }
      _findcase.p_value= (int)!(flags & IGNORECASE_SEARCH);
      _findword.p_value=flags & WORD_SEARCH;
      _findre.p_value=flags & (RE_SEARCH|UNIXRE_SEARCH|BRIEFRE_SEARCH);
      _findwrap.p_value=((flags & WRAP_SEARCH)? 1:0) + ((flags&PROMPT_WRAP_SEARCH)? 1:0);
      _findmark.p_value=flags & MARK_SEARCH;
   }
   _str word;
   int junk;
   if ((def_mfsearch_init_flags&MFSEARCH_INIT_CURWORD)
      && wid._isEditorCtl(false)) {
      word=wid.cur_word(junk,'',1);
      _findstring.p_text=word;
   }
   if (def_mfsearch_init_flags&MFSEARCH_INIT_SELECTION) {
      if (wid._isEditorCtl(false) && wid.select_active2()) {
         _str str;
         int mark_locked=0;
         if (_select_type('','S')=='C') {
            mark_locked=1;
            _select_type('','S','E');
         }
         wid.filter_init();
         wid.filter_get_string(str);
         wid.filter_restore_pos();
         //4:29pm 9/5/1996 Dan & Clark added to fix only search & replace on
         //first line after init with selectio
         _findstring.p_text=str;
         if (mark_locked) {
            _select_type('','S','C');
         }
      }
   }
   wid.refresh();
   wid=_mfparent();
   if (wid.p_HasBuffer && !wid.select_active2()) {
      _findmark.p_enabled=0;
   }
   _str search_options=arg(1);
   if (pos('-',search_options)) {
      ctlsearchbackward.p_value=1;
   }else if (def_keys=='brief-keys') {
      //In brief, if we aren't searching back, we are always searching forward.
      ctlsearchbackward.p_value=0;
   }
   if (pos('[rubRUB]',search_options,1,'r')) {
      _findre.p_value=1;
   }
   _str retype;
   if (def_re_search==UNIXRE_SEARCH) {
      retype='(UNIX)';
   } else if (def_re_search==BRIEFRE_SEARCH) {
      retype='(Brief)' ;
   } else {
      retype='(SlickEdit)';
   }
   _findre.p_caption=_findre.p_caption' 'retype;
   if (lowcase(p_active_form.p_name)!='_replace_form') {
      // Make sure the _no_child_windows is in here so that can't list
      // all occurrences when there are no MDI children.
      _findlist_all.p_enabled=!(_findmark.p_enabled&&_findmark.p_value)&& wid._isEditorCtl(false) && wid.p_mdi_child && !gbgm_search_state;
   }
   if(doExpand) _mfmore.call_event(_mfmore,LBUTTON_UP);
}
void _findstring.on_drop_down(int reason)
{
   if (FINDSTRING_RETRIEVE_DONE=='') {
      _retrieve_list();
      FINDSTRING_RETRIEVE_DONE=1; // Indicate that retrieve list has been done
   }
}
void _find_save_form_response()
{
   _save_form_response();
   if (ctlmffiles.p_text!='') {
      _append_retrieve(ctlmffiles,ctlmffiles.p_text);
   }
   if (ctlmffiletypes.p_text!='') {
      _append_retrieve(_control ctlmffiletypes,ctlmffiletypes.p_text);
   }
}
_findok.lbutton_up()
{
   int status=_mfget_result(_param3,_param4);
   if (status) return('');
   int wid=_mfparent();
   if (!wid.p_HasBuffer || (wid.p_window_flags & HIDE_WINDOW_OVERLAP)) {
      if (_param3=='') {
         _message_box(get_message(VSRC_FF_NO_FILES_SELECTED));
         p_window_id=_control ctlmffiles;_set_focus();
         _set_sel(1,length(p_text)+1);
         return('');
      }
   }
   _find_save_form_response();

   int mfflags=0;

   _param6='0';

   // IF we are doing a list all occurrences search
   if ((_findlist_all.p_value)&&(_findlist_all.p_enabled)&&(_findlist_all.p_visible)) {
      _param6=_param6:+'|MFFIND_CURBUFFERONLY';
      mfflags=MFFIND_CURBUFFERONLY;
   // IF we are doing a multi-file search or a project or workspace search
   } else if(_param3!='') {
      if (ctllistfilesonly.p_value) {
         _param6=_param6:+'|MFFIND_FILESONLY';
         mfflags|=MFFIND_FILESONLY;
      }
      if (ctlappend.p_value) {
         _param6=_param6:+'|MFFIND_APPEND';
         mfflags|=MFFIND_APPEND;
      }
      if (ctlmdichild.p_value) {
         _param6=_param6:+'|MFFIND_MDICHILD';
         mfflags|=MFFIND_MDICHILD;
      }
      if (ctlglobal.p_value) {
         _param6=_param6:+'|MFFIND_GLOBAL';
         mfflags|=MFFIND_GLOBAL;
      } else if (ctlsingle.p_value) {
         _param6=_param6:+'|MFFIND_SINGLE';
         mfflags|=MFFIND_SINGLE;
      }
      if (!ctlsynchronous.p_value) {
         _param6=_param6:+'|MFFIND_THREADED';
         mfflags|=MFFIND_THREADED;
      }
   }
   if (_param6!=0) {
      // remove the 0|
      _param6=substr(_param6,3);
   }
   _param5=mfflags;

   _str search_options;
   if (_findcase.p_value) {
      search_options= '';
   } else {
      search_options='I';
   }
   if (_findword.p_value) {
      search_options=search_options'W';
   }
   if (_findre.p_value) {
      if (def_re_search==UNIXRE_SEARCH) {
         search_options=search_options'U';
      } else if (def_re_search==BRIEFRE_SEARCH) {
         search_options=search_options'B';
      } else {
         search_options=search_options'R';
      }
   }
   if (_findwrap.p_value==2 && !_param5) {
      search_options=search_options'?';
   } else if (_findwrap.p_value && !_param5) {
      search_options=search_options'P';
   }
   if (_findmark.p_value && !_param5 && _findmark.p_enabled) {
      search_options=search_options'M';
   }
   if (ctlsearchbackward.p_value && !_param5) {
      search_options=search_options'-';
   }
   if (_findcursorend.p_value && !_param5) {
      search_options=search_options'>';
   }
   if (ctlcolor.p_enabled) {
      search_options=search_options:+ctlcoloroptions.p_text;
   }
   _param2=search_options;
   _param1= _findstring.p_text;
   p_active_form._delete_window(1);
}


defeventtab _replace_form;
void _findcase.lbutton_up()
{
   if (_findcase.p_value) {
      ctlpreservecase.p_value=0;
   }
}
void ctlpreservecase.lbutton_up()
{
   if (ctlpreservecase.p_value) {
      _findcase.p_value=0;
   }
}
void _replace_form.'F1'()
{
   help('Replace Dialog Box');
}
_mfhook.lbutton_up(int reason,typeless info)
{
   //_nocheck _control ctlmffiletypeslabel;
   if (reason==CHANGE_SELECTED) {
      if (p_active_form.p_name=='_find_form') {
         _nocheck _control ctlsynchronous;
         if (!(_default_option(VSOPTION_APIFLAGS)&0x80000000) && ctlsynchronous.p_visible) {
            ctlsynchronous.p_visible=0;
            ctlsynchronous.p_value=1;
         }
      }
      if (info) {
         int widcolor=_find_control('ctlcolor');
         if (widcolor) {
            ctlnocolor.p_enabled=widcolor.p_enabled=true;
            ctlcoloroptions.call_event(CHANGE_OTHER,ctlcoloroptions,ON_CHANGE,"W");
         }
         // Some files or bufers have been selected
         if (_findmark.p_enabled) _findmark.p_enabled=0;
         if (_findwrap.p_enabled) _findwrap.p_enabled=0;
         if (ctlsearchbackward.p_enabled) ctlsearchbackward.p_enabled=0;
         if (_findcursorend.p_enabled) {
            _findcursorend.p_value=0;
            _findcursorend.p_enabled=0;
         }
         if (lowcase(p_active_form.p_name)!='_replace_form') {
            _nocheck _control _findlist_all;
            if (_findlist_all.p_enabled) _findlist_all.p_enabled=0;
            _nocheck _control _findok;
            if (_findok.p_enabled && gbgm_search_state) {
               _findok.p_enabled=0;
            } else if (!_findok.p_enabled && !gbgm_search_state) {
               _findok.p_enabled=true;
            }
            if (!ctlsynchronous.p_enabled) ctlsynchronous.p_enabled=true;
            if (!_mfsubdir.p_enabled) _mfsubdir.p_enabled=true;
            if (!ctlmffiletypes.p_enabled) ctlmffiletypes.p_enabled=true;
            //if (!ctlmffiletypeslabel.p_enabled) ctlmffiletypeslabel.p_enabled=true;
         }
      } else {
         // No files or buffers are selected
         int widcolor=_find_control('ctlcolor');
         int wid=_mfparent();
         if (widcolor) {
            ctlnocolor.p_enabled=widcolor.p_enabled=(wid.p_HasBuffer && wid.p_lexer_name!="");
            //if (!widcolor.p_enabled) {
               ctlcoloroptions.call_event(ctlcoloroptions,on_change);
            //}
         }

         if (lowcase(p_active_form.p_name)!='_replace_form') {
            _nocheck _control _findlist_all;
            if (!_findlist_all.p_enabled) {
               _findlist_all.p_enabled=!(_findmark.p_enabled&&_findmark.p_value)&& wid._isEditorCtl(false) && wid.p_mdi_child && !gbgm_search_state;
               //_findlist_all.p_enabled=1;
            }
            if (!_findok.p_enabled) _findok.p_enabled=1;
            if (!_findmark.p_enabled) {
              wid=_mfparent();
              if (!_findlist_all.p_value && wid.p_HasBuffer && wid.select_active2()) {
                 _findmark.p_enabled=1;
              }
            }
            if (!_findwrap.p_enabled) _findwrap.p_enabled=!_findlist_all.p_value;
            if (!ctlsearchbackward.p_enabled) ctlsearchbackward.p_enabled=!_findlist_all.p_value;
            if (!_findcursorend.p_enabled) {
               _findcursorend.p_enabled=!_findlist_all.p_value;
            }
            if (ctlsynchronous.p_enabled) ctlsynchronous.p_enabled=false;
            if (_mfsubdir.p_enabled) _mfsubdir.p_enabled=false;
            if (ctlmffiletypes.p_enabled) ctlmffiletypes.p_enabled=false;
            //if (ctlmffiletypeslabel.p_enabled) ctlmffiletypeslabel.p_enabled=false;
         } else {
            if (!_findmark.p_enabled) {
               wid=_mfparent();
              if (wid.p_HasBuffer && wid.select_active2()) {
                 _findmark.p_enabled=1;
              }
            }
            if (!_findwrap.p_enabled) _findwrap.p_enabled=1;
            if (!ctlsearchbackward.p_enabled) ctlsearchbackward.p_enabled=1;
            if (!_findcursorend.p_enabled) _findcursorend.p_enabled=1;
         }
      }
      if (p_active_form.p_name=='_find_form') {
         _nocheck _control ctlmdichild,ctlappend,ctllistfilesonly;
         _nocheck _control ctlprompted,ctlsingle,ctlglobal;
         //ctlprompted.p_enabled=ctlsingle.p_enabled=ctlglobal.p_enabled=
         ctlmdichild.p_enabled=ctlappend.p_enabled=ctllistfilesonly.p_enabled=info;


         _nocheck _control ctlstop;
         _nocheck _control ctlsynchronous;
         ctlstop.p_enabled=gbgm_search_state!=0;
         //_nocheck _control ctlprompted;
         //_nocheck _control ctlglobal;
         //_nocheck _control ctlsingle;
         ctlglobal.p_enabled=ctlsingle.p_enabled=ctlprompted.p_enabled=(ctlsynchronous.p_value && info);
      }
   }
}
static boolean _mfhave_input()
{
   return((ctlmffiles.p_enabled && ctlmffiles.p_text!='') &&
           pos('<<',_mfmore.p_caption));
}
void ctlmffiles.on_change(int reason)
{
   _mfhook.call_event(CHANGE_SELECTED,_mfhave_input(),_mfhook,LBUTTON_UP,'');
}

void ctlmffiles.on_drop_down(int reason)
{
   if (MFFILES_RETRIEVE_LIST_DONE=='') {
      _lbclear();
      _retrieve_list();
      if (_project_name!='') {
         _lbbottom();
         _str WorkspacePath=_strip_filename(_workspace_filename,'N');
         _lbadd_item(WorkspacePath);
         _str ProjectPath=_parse_project_command('%rw','',_project_name,'');
         if (!file_eq(WorkspacePath,ProjectPath)) {
            _lbadd_item(ProjectPath);
         }
         if (mffind_have_buffers()) {
            _lbadd_item(MFFIND_BUFFERS);
         }
         if (_mfallow_workspacefiles()) {
            _lbadd_item(MFFIND_WORKSPACE_FILES);
         }
         if (_mfallow_prjfiles()) {
            _lbadd_item(MFFIND_PROJECT_FILES);
         }
      } else {
         if (mffind_have_buffers()) {
            _lbadd_item(MFFIND_BUFFERS);
         }
      }
      MFFILES_RETRIEVE_LIST_DONE=1; // Indicate that retrieve list has been done
   }
}
static _str _mffind_list_buffers_ft(int reason,var result,typeless key)
{
   _nocheck _control _sellist;
   _nocheck _control _sellistok;
   // Initialize or change selected
   if (reason==SL_ONINIT || reason==SL_ONSELECT) {
      if (_sellist.p_Nofselected > 0) {
         if (!_sellistok.p_enabled) {
             _sellistok.p_enabled = 1;
         }
      } else {
         _sellistok.p_enabled=0;
      }
      return('');
   }
   if (reason==SL_ONDEFAULT) {  // Enter callback?
      /* Save all files. */
      result='';
      int status=_sellist._lbfind_selected(1);
      while (!status) {
         _str text=_sellist._lbget_text();
         if (result=='') {
            result=text;
         } else {
            int newsize=length(result)+length(text)+1000;
            if (newsize>_default_option(VSOPTION_WARNING_STRING_LENGTH)) {
               _default_option(VSOPTION_WARNING_STRING_LENGTH,newsize);
            }
            strappend(result,';'text);
         }
         _str line;
         _sellist. get_line(line);
         status=_sellist._lbfind_selected(0);
      }
      return(1);
   }
   if (reason!=SL_ONUSERBUTTON && reason!=SL_ONLISTKEY){
      return('');
   }
   if ( key==4) { /* Invert. */
      _str junk;
      _sellist._lbinvert();
      _mffind_list_buffers_ft(SL_ONSELECT,junk,'');
      return('');
   }
   if ( key==5) { /* Save None. */
      _str junk;
      _sellist._lbdeselect_all();
      _mffind_list_buffers_ft(SL_ONSELECT,junk,'');
      return('');
   }
   return('');
}
void _mffind_list_buffers(_str (&array)[])
{
   // Fill the buffer list
   _str name=buf_match('',1);
   for (;;) {
      if (rc) break;
      if (name!='' && name!='.process' && name!=_grep_buffer){
         array[array._length()]=name;
      }
      name=buf_match('',0);
   }
}
static boolean mffind_have_buffers()
{
   _str array[];
   _mffind_list_buffers(array);
   return(array._length()!=0);
}
static void mffind_add_buffers(_str &append)
{
   int orig_view_id, temp_view_id;
   get_window_id(orig_view_id);
   _create_temp_view(temp_view_id);
   _str array[];
   _mffind_list_buffers(array);
   int i;
   for (i=0;i<array._length();++i) {
      // Fill the buffer list
      _lbadd_item(array[i]);
   }
   p_window_id=orig_view_id;

   _str buttons=nls('&Add Buffers,&Invert,&Clear');
   append=show('_sellist_form -mdi -modal',
               'Add Buffers',
               SL_VIEWID|SL_ALLOWMULTISELECT|SL_NOISEARCH|
               SL_DEFAULTCALLBACK,
               temp_view_id,
               buttons,
               "Add Buffers",        // help item name
               '',             // font
               _mffind_list_buffers_ft   // Call back function
              );
}
void _init_mffiletypes()
{
   if (MFFILETYPES_RETRIEVE_LIST_DONE=='') {
      _lbclear();
      _retrieve_list();
      _lbbottom();
      _str mode_name, wildcards='';
#if 0
      if (_project_name!='') {
         status=tag_read_db(_GetWorkspaceTagsFilename());
         if (!status) {
            status=tag_find_language(auto lang);
            if (!status) {
               wildcards=_GetWildcardsForLanguage(lang);
               if (wildcards!='') {
                  p_cb_list_box._lbadd_item(wildcards);
                  if (p_text=='') {
                     p_text=wildcards;
                  }
               }
            }
            tag_close_db(null,true);
         }
      }
#endif
      //if (wildcards=='') {
         wildcards=def_file_types;
         _str name, list;
         for (;;) {
            parse wildcards with name '('list')' ',' wildcards;
            if (name=='') break;
            _lbadd_item(list);
         }
         if (!_no_child_windows() && _mdi.p_child.p_LangId!='fundamental' && 
             _mdi.p_child.p_LangId!='process' && _mdi.p_child.p_LangId!='fileman' &&
             _mdi.p_child.p_LangId!=''   // grep mode
             ) {
            if (p_text=='') {
               list=_GetWildcardsForLanguage(_mdi.p_child.p_LangId);
               p_text=list;
            }
         }
         if (p_text=='') {
            p_text=_default_c_wildcards();
         }
      //}
      MFFILETYPES_RETRIEVE_LIST_DONE=1; // Indicate that retrieve list has been done
   }
}

_finddir.lbutton_up()
{
}

/**
 * Displays the <b>Replace dialog box</b>.
 * 
 * @return  Returns '' if dialog box is cancelled.   Otherwise, 1 is returned 
 * and the global variables _param1-_param5 are set as follows:
 * 
 * <dl>
 * <dt>_param1</dt><dd>Search string.</dd>
 * <dt> _param2</dt><dd>Replace string.</dd>
 * <dt>_param3</dt><dd>Search options.</dd>
 * <dt>_param4</dt><dd>Files to search through.</dd>
 * <dt>_param5</dt><dd>Buffers to search through.</dd>
 * </dl>
 * 
 * @example      _str show('-modal _replace_form')
 * 
 * @example
 * <pre>
 * _command gui_replace() 
 *         name_info(','VSARG2_ EDITORCTL)
 * {
 *    _macro_delete_line()
 *    result=show('-modal _replace_form',arg(1))
 *    if (result=='') {
 *       return(COMMAND_CANCELLED_RC);
 *    }
 *    _macro('m',_macro('s'))
 *    if (_param4=='' && _param5=='') {
 *       _macro_call('replace2', _param1, _param2, _param3)
 *       return(gui_replace2(_param1, _param2, _param3))
 *    } else {
 *       if (substr(_param5,1,1)=='@' && _macro()) {
 *          _message_box(nls("Sorry, can't generate macro code for this 
 * operation."));
 *       } else {
 *          _macro_call('_mfreplace', _param1, _param2, _param3, 
 * _param4, _param5)
 *       }
 *       return(_mfreplace(_param1, _param2, _param3, _param4, 
 * _param5));
 *    }
 * }
 * </pre>
 * 
 * @categories Forms
 * 
 */ 
_mfmore.on_create()
{
   if (pos('>',_mfmore.p_caption)) {
      _dmless();
   }
}

void _replaceok.on_create()
{
   _replace_form_initial_alignment();
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _replace_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(_findstring.p_window_id, ctl_image1.p_window_id);
   sizeBrowseButtonToTextBox(_replacestring.p_window_id, ctl_image2.p_window_id);
   sizeBrowseButtonToTextBox(ctlmffiles.p_window_id, ctlfilesmenu.p_window_id);
}

static boolean _mfallow_prjfiles()
{
   if (_project_name!='') {
      _str result;
      int status=_GetAssociatedProjectInfo(_project_name,result);
      if (status || result=='') {
         if(!_ProjectContains_Files(_ProjectHandle(_project_name))) {
            return(false);
         }
      }
      return(true);
   }
   return(false);
}

static boolean _mfallow_workspacefiles()
{
   int orig_view_id=p_window_id;
   if (_workspace_filename!='') {
      _str Files[];
      int status=_GetWorkspaceFiles(_workspace_filename,Files);
      if (status) {
         //here
         _message_box(get_message(VSRC_FF_COULD_NOT_OPEN_WORKSPACE_FILE,_workspace_filename,get_message(status)));
         return(false);
      }
      return(true);
   }
   return(false);
}

/*
   Stores and returns form parent.
*/
int _mfparent(...)
{
   if (arg()) {
      FORM_PARENT=arg(1);
   }
   return(FORM_PARENT);
}
_mfmore.lbutton_up()
{
   boolean isFindForm=p_active_form.p_name=='_find_form';
   if (isFindForm) {
#if 0
      // Clark: Removed this code which I don't think is needed anymore 
      //    because under Linux, the find dialog does not always resize correctly
      //    when expanding the dialog.
      if (pos('>',p_caption)) {
         _nocheck _control ctlmdichild;
         y=ctlmdichild.p_y+ctlmdichild.p_height+50;
         new_height=y+p_active_form._top_height()+p_active_form._bottom_height();
         if (p_active_form.p_height!=new_height) {
            p_active_form.p_height=new_height;
            // This forced update seems to fix a paint bug under OS/2
            p_active_form.refresh('w');
         }
      }
#endif
      _dmmoreless();
   } else {
      _dmmoreless();
   }
   // This forced update seems to fix a paint bug under OS/2
   p_active_form.refresh('w');
   if (pos('<',p_caption)) {
      _mfcurdir.p_caption=get_message(VSRC_FF_CURDIR_IS)' 'getcwd();
      _mfcurdir.p_visible=1;
      //ctlmffiles.p_text=MFFILES_TEXT;
      if( ctlmffiles.p_enabled ) {
         p_window_id=_control ctlmffiles;
         _set_sel(1,length(p_text)+1);
      } else {
         // ctlmffiles is disabled because "Search all project files" or
         // "Search all workspace files" is checked, so put focus back
         // on "OK" button so user can just hit ENTER.
         _nocheck _control _findok;
         _nocheck _control _replaceok;
         if( p_active_form.p_name=='_find_form' ) {
            p_window_id=_findok;
         } else {
            p_window_id=_replaceok;
         }
      }
   } else {
      _mfcurdir.p_visible=0;
      //MFFILES_TEXT=ctlmffiles.p_text;
      //ctlmffiles.p_text='';
   }
   _mfhook.call_event(CHANGE_SELECTED,_mfhave_input(),_mfhook,LBUTTON_UP,'');
   _set_focus();
}

/**
 * Validate the multi-file input and return only partially processed results.
 * _unix_expansion() is called and the +t option is added to <i>files</i>.
 * 
 * @param files      (Output) PATHSEP delimited files with &lt;Workspace&gt; and &lt;Project&gt;
 *                   stuff still present.
 * @param wildcards  (Output) Wildcards to search on.
 * 
 * @return Status is returned.  If non-zero, an error message box was displayed.
 *         IF status is zero, result is set to the result
 *         IF status is zero and result=='' then the user has not selected anything.
 */
int _mfget_result(_str &files,_str &wildcards)
{
   if (!_mfhave_input()) {
      files="";
      return(0);
   }
   int orig_wid=p_window_id;
   _str result='';
   _str tree_option='';
   if (_mfhave_input()) {
      result=_unix_expansion(ctlmffiles.p_text);
      if (result!='' && (_mfsubdir.p_value) && (_mfsubdir.p_enabled)) {
         tree_option='+t ';
      }
   }
   result=translate(result,FILESEP,FILESEP2);
   wildcards=ctlmffiletypes.p_text;
   if (wildcards=='') wildcards=ALLFILES_RE;
   files=tree_option:+result;
   return(0);
   // Pre checking takes too long.
#if 0
   line=result;
   Noffiles=0;
   one_file_found=0;
   first_file_not_found='';
   boolean include_workspace_files=false;
   boolean include_project_files=false;
   for (;;) {
      parse line with word (PATHSEP) line;
      if (word=='') break;
      if (strieq(word,MFFIND_PROJECT_FILES)) {
         include_project_files=true;
      } else if (strieq(word,MFFIND_WORKSPACE_FILES)) {
         include_workspace_files=true;
      } else {
         boolean isDirectory=!iswildcard(word) && (isdirectory(word) || last_char(word)==FILESEP);
         if (isDirectory) {
            _maybe_append_filesep(word);
         }
         _str list=wildcards;
         if (!isDirectory) {
            file_had_wildcards=true;
            list=strip_filename(word,'P');
            word=strip_filename(word,'N');
         }
         //_message_box('list='list);
         //_message_box('word='word);
         for (;;) {
            parse list with wildcard '[;:]','r' list;
            if (wildcard=='') {
               break;
            }
            ++Noffiles;
            filename=word:+wildcard;
            //_message_box('filename='filename' tree_option='tree_option);
            if (file_match('-pd 'tree_option:+maybe_quote_filename(filename),1)!='') {
               //_message_box('found one');
                one_file_found=1;
            } else if (!iswildcard(wildcard)) {
               _message_box('h1 'get_message(VSRC_FF_FILE_NOT_FOUND, filename));
               _mferror();
               return(1);
            } else {
               if (Noffiles==1) {
                  if (isDirectory) {
                     first_file_not_found=word;
                  } else {
                     first_file_not_found=filename;
                  }
               }
            }
         }
      }
   }
   if (!one_file_found && first_file_not_found!='' &&
       !include_workspace_files && !include_project_files) {
      _message_box(get_message(VSRC_FF_FILE_NOT_FOUND, first_file_not_found));
      _mferror();
      return(1);
   }
   return(0);
#endif
}


static void add_project_files()
{
   if (_project_name=='') {
      return;
   }
   int orig_view_id=p_window_id;
   int temp_view_id;
   //11:45am 8/18/1997
   //Dan changed for makefile support
   //status=_ini_get_section(_project_name,"FILES",temp_view_id);
   int status=GetProjectFiles(_project_name,temp_view_id);
   if (status) {
      p_window_id=orig_view_id;
      return;
   }
   p_window_id=temp_view_id;
   int mark_id=_alloc_selection();
   top();_select_line(mark_id);
   bottom();_select_line(mark_id);
   _shift_selection_right(mark_id);
   _deselect(mark_id);
   p_col=1;p_line=1;
   p_line=0;
   while (!down()) {
      get_line(auto line);
      replace_line('>'substr(line,2));
   }
   top();_select_line(mark_id);
   bottom();_select_line(mark_id);
   p_window_id=orig_view_id;
   bottom();
   _copy_to_cursor(mark_id);
   _free_selection(mark_id);
   _delete_temp_view(temp_view_id);
}

static void add_workspace_files()
{
   int i;
   if (_workspace_filename=='') {
      return;
   }
   int orig_view_id=p_window_id;
   //11:45am 8/18/1997
   //Dan changed for makefile support
   //status=_ini_get_section(_project_name,"FILES",temp_view_id);
   _str ProjectFiles[];
   ProjectFiles._makeempty();
   int status=_GetWorkspaceFiles(_workspace_filename,ProjectFiles);
   if (status) {
      return;
   }
   _str OrigProjectName=_project_name;
   _str workpace_path=_strip_filename(_workspace_filename,'N');
   for (i=0;i<ProjectFiles._length();++i) {
      _project_name=absolute(ProjectFiles[i],workpace_path);
      add_project_files();
   }
   _project_name=OrigProjectName;
}

static void _mferror()
{
   p_window_id=ctlmffiles;_set_sel(1,length(p_text)+1);_set_focus();
   if (pos('>',_mfmore.p_caption)) {
      _mfmore.call_event(_mfmore,LBUTTON_UP);
   }
   //_mfmore._dmmore('h');
}
_replaceall.lbutton_up()
{
   _replaceok.call_event('*',_replaceok,LBUTTON_UP,'');
}
_replaceok.lbutton_up()
{
   int status=_mfget_result(_param4,_param5);
   if (status) return('');
   int wid=_form_parent();
   if (!wid.p_HasBuffer || (wid.p_window_flags & HIDE_WINDOW_OVERLAP)||
       (wid._QReadOnly())) {
      if (_param4=='') {
         if(wid._QReadOnly()){
            _message_box(get_message(VSRC_FF_NO_FILES_SELECTED_READ_ONLY));
         } else {
            _message_box(get_message(VSRC_FF_NO_FILES_SELECTED));
         }
         p_window_id=_control ctlmffiles;
         _set_sel(1,length(p_text)+1);_set_focus();
         return('');
      }
   }
   _find_save_form_response();
   _str search_options;
   if (_findcase.p_value) {
      search_options= 'E';
   } else {
      search_options='I';
      if (_find_control('ctlpreservecase') && ctlpreservecase.p_value) {
         search_options=search_options:+'V';
      }
   }
   if (_findword.p_value) {
      search_options=search_options'W';
   }
   if (_findre.p_value) {
      if (def_re_search==UNIXRE_SEARCH) {
         search_options=search_options'U';
      } else if (def_re_search==BRIEFRE_SEARCH) {
         search_options=search_options'B';
      } else {
         search_options=search_options'R';
      }
   }
   if (_findwrap.p_value && _findwrap.p_enabled) {
      search_options=search_options'P';
   }
   if (_findmark.p_value && _findmark.p_enabled) {
      search_options=search_options'M';
   }
   if (ctlsearchbackward.p_value) {
      search_options=search_options'-';
   }
   if (_findcursorend.p_value) {
      search_options=search_options'>';
   }
   if (ctlcolor.p_enabled) {
      search_options=search_options:+ctlcoloroptions.p_text;
   }
   search_options=search_options:+arg(1);
   _param1= _findstring.p_text;
   _param2= _replacestring.p_text;
   _param3= search_options;
   p_active_form._delete_window(1);
}

void _replacestring.on_drop_down(int reason)
{
   if (REPLACESTRING_RETRIEVE_DONE=='') {
      _retrieve_list();
      REPLACESTRING_RETRIEVE_DONE=1; // Indicate that retrieve list has been done
   }
}
