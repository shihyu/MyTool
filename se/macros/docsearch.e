////////////////////////////////////////////////////////////////////////////////////
// Copyright 2016 SlickEdit Inc. 
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
#include "vsevents.sh"
#include "markers.sh"
#include "mfundo.sh"
#include "xml.sh"
#import "bind.e"
#import "codehelp.e"
#import "clipbd.e"
#import "cua.e"
#import "cutil.e"
#import "dlgman.e"
#import "files.e"
#import "guifind.e"
#import "guireplace.e"
#import "listbox.e"
#import "markfilt.e"
#import "makefile.e"
#import "main.e"
#import "menu.e"
#import "mouse.e"
#import "mprompt.e"
#import "picture.e"
#import "projconv.e"
#import "pushtag.e"
#import "recmacro.e"
#import "search.e"
#import "searchcb.e"
#import "seek.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbfind.e"
#import "tbsearch.e"
#import "wkspace.e"
#import "color.e"
#import "se/ui/mainwindow.e"
#import "se/ui/twevent.e"
#import "se/ui/EventUI.e"
#require "se/ui/DocSearchForm.e"
#require "se/search/FindNextFile.e"
#import "se/search/ISearchFunctor.e"
#import "se/search/SearchExpr.e"
#import "se/search/SearchColors.e"

static const DOCSEARCH_MINIMUM_WIDTH_PIXELS = 200;

int def_gui_find_default = 0;
int def_gui_find_max_search_markers = 8192;
int def_gui_find_incremental_search_max_buf_ksize = 50000;
bool def_mini_find_close_on_default = false;

static int gDSMarkerType;
static int gDSMarkerCurrentType;
static int gDSScrollMarkerType;
static int gDSMatchScrollMarkerType;

static int _pic_toggle_up;
static int _pic_toggle_down;

using se.search.FindNextFile;
using se.ui.DocSearchForm;

struct DSParams {
   int   m_status;         // last search status
   int   m_lastModified;

   int   m_marker_id;      // current match stream marker id
   int   m_scrollmarker_id;// current match scroll marker id
   int   m_orig_mark;      // orig mark
   int   m_search_mark;    // incremental search start position mark
   int   m_match_mark;     // last match position mark
   int   m_proc_mark;      // current procedure mark
   int   m_last_mark;      // last mark search -- DO NOT FREE
   _str  m_last_mark_info; 

   int   m_match_length;   // last match length          match_length()
   int   m_match_start;    // last match start           match_length('S')
   int   m_match_replace;  // last match replace column  match_length('P')

   int   m_num_matches;

   int   m_grep_id;

   bool  m_grep_ab;
   int   m_grep_before_lines;
   int   m_grep_after_lines;

   int   m_options;        // options not on form
   int   m_mfflags;
   bool  m_listreplace;

   _str  m_scroll_info;

   bool m_tooltip;
   bool m_update;
   bool m_disable_occurences;
   bool m_macro_last_search;

   int   m_start_mark;
   bool m_start_wrap;

   bool m_match_prev;      // last match next or prev
};

static DSParams s_params;
extern void _ComboBoxCommand(_str command);
defeventtab _ul2_combobx_docsearch _inherit _ul2_combobx;
void _ul2_combobx_docsearch.F4()
{
   call_event(defeventtab _document_search_form,F4, 'E');
}

defeventtab _editorctl_resize_helper;
def on_resize=_on_ds_resize;

defeventtab _document_search_form;
static bool ignore_change = false;
static bool ignore_text_change = false;
static bool ignore_switchbuf = false;
static bool update_menu_hotkeys = true;
static bool already_hit_event = false;

definit()
{
   gDSMarkerType = -1;
   gDSMarkerCurrentType = -1;
   gDSScrollMarkerType = -1;
   gDSMatchScrollMarkerType = -1;

   if ( arg(1)=='L' ) {
      bitmapsDialogsDir := _getSlickEditInstallPath():+VSE_BITMAPS_DIR:+FILESEP:+"dialogs":+FILESEP;
      load_picture(-1, bitmapsDialogsDir:+'_tdown2.ico');
      load_picture(-1, bitmapsDialogsDir:+'_tup2.ico');
      load_picture(-1, '_f_arrow_left.svg');
      load_picture(-1, '_f_arrow_right.svg');
      _pic_toggle_up=_update_picture(-1,bitmapsDialogsDir:+'_tup2.ico');
      _pic_toggle_down=_update_picture(-1,bitmapsDialogsDir:+'_tdown2.ico');
   }

   ignore_change = false;
   ignore_text_change = false;
   ignore_switchbuf = false;
   update_menu_hotkeys = true;
   already_hit_event = false;
}

static int P_USER_MINIFIND_WID(...) {
   if (arg()) _findframe.p_user=arg(1);
   return _findframe.p_user;
}
static int P_USER_MINIFIND_ISEARCH(...) {
   if (arg()) ctl_findnext.p_user=arg(1);
   return ctl_findnext.p_user;
}
static int P_USER_MINIFIND_RE(...) {
   if (arg()) ctl_regex.p_user=arg(1);
   return ctl_regex.p_user;
}
static _str P_USER_MINIFIND_FIND_LIST_REFRESH(...) {
   if (arg()) _findstring.p_user=arg(1);
   return _findstring.p_user;
}
static _str P_USER_MINIFIND_REPLACE_LIST_REFRESH(...) {
   if (arg()) _replacestring.p_user=arg(1);
   return  _replacestring.p_user;
}

static int _show_mini_form(bool replace_mode, ...)
{
   int form_wid = _find_formobj('_document_search_form','N');
   if (form_wid) {
      // recycle form?
      get_window_id(auto wid);
      activate_window(form_wid);
      editorctl_wid := P_USER_MINIFIND_WID();
      activate_window(wid);
      if (wid == editorctl_wid) {
         form_wid._ds_reinit_form(p_window_id, replace_mode);
         return 0;
      }
      form_wid._delete_window();
   }
   mode := (replace_mode) ? 'R' : 'F';
   show('-child -NOCENTER _document_search_form', p_window_id, mode, arg(2));
   //mini_find_update_options('', '', old_search_options, old_search_range, old_search_mfflags, old_search_misc_options);
   return 0;
}

/**
 * Searches for a string you specify. 
 * 
 * <p> This either displays the
 * Mini Find and Replace dialog or the Find and Replace tool
 * window.
 *
 * @return Returns 0 if successful.
 * @see find_next
 * @see gui_replace
 * @see find
 * @see replace
 * @see find_prev
 * @see list_search
 * @see keep_search
 * @see delete_search
 * @appliesTo Edit_Window, Editor_Control
 * @categories File_Functions, Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 */
_command int gui_find(...) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   _macro_delete_line();
   if (def_gui_find_default) {
      return tool_gui_find(arg(1));
   }
   if (!_isEditorCtl(false)) {
      find_in_files();
      return 0;
   }

   return _show_mini_form(false, arg(1));
}

/**
 * Searches for a string you specify and replaces it with
 * another string you specify.
 *  
 * <p> This either displays the
 * Mini Find and Replace dialog or the Find and Replace tool
 * window.
 *
 * @return Returns 0 if successful.
 *
 * @see find_next
 * @see gui_find
 * @see find
 * @see replace
 * @see gui_replace2
 * @see find_prev
 * @see list_search
 * @see keep_search
 * @see delete_search
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories File_Functions, Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 */
_command int gui_replace(...) name_info(','VSARG2_EDITORCTL)
{
   _macro_delete_line();
   if (def_gui_find_default) {
      return tool_gui_replace(arg(1));
   }
   if (!_isEditorCtl(false)) {
      replace_in_files();
      return 0;
   }
   return _show_mini_form(true, arg(1));
}

int _OnUpdate_gui_replace(CMDUI &cmdui,int target_wid,_str command)
{
   /* 
      Note: the gui_replace command has a weird feature where it allows you
      to invoke a replace command on an MDI readonly file and prompts you for
      options. Seems to me this should be disabled which would force the user
      to turn off Protect Read Only mode or click the "RO" status button. The
      tricky part in doing this is that the gui_replace dialog is modeless
      and it would need to detect the change in "RO" status.

      IF MDI not supported and target is not an editor control
         OR target is an editor control that is not MDI and target is readonly
   */
   if ( ( !(_default_option(VSOPTION_APIFLAGS) &VSARG2_REQUIRES_MDI) && 
          !(target_wid && target_wid._isEditorCtl()))
      || (target_wid && target_wid._isEditorCtl() && !target_wid.p_mdi_child && target_wid._QReadOnly())) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}


int _OnUpdate_mini_gui_replace(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_gui_replace(cmdui,target_wid,command));
}

_command int mini_gui_find(...) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   return _show_mini_form(false, arg(1));
}

_command int mini_gui_replace(...) name_info(','VSARG2_EDITORCTL)
{
   return _show_mini_form(true, arg(1));
}

void _gui_find_dismiss()
{
   int form_wid = _find_formobj('_document_search_form','N');
   if (!form_wid) {
      return;
   }
   form_wid._delete_window();
}

void mini_find_update_options(_str search_string, _str replace_string, _str search_options, int search_range, int mfflags, _str misc_options, bool use_defaults = true)
{
   get_window_id(auto orig_wid);
   int form_wid = _find_formobj('_document_search_form','N');
   if (form_wid == 0) {
      return;
   }
   activate_window(form_wid);
   ignore_change = true;
   if (search_string != '') {
      _findstring.p_text = search_string;
   }

   if (replace_string != '') {
      _replacestring.p_text = replace_string;
   }

   if (use_defaults && def_find_init_defaults) {
      search_options = ''; misc_options = '';
   }

   if (search_options != '') {
      if (def_keys == "brief-keys") {
          search_options = stranslate(search_options, '', '-');
          search_options :+= '+';
      }
      options := s_params.m_options;

      if (pos('I', search_options, 1, 'I')) {
         ctl_matchcase.p_value = 0;
      } else if (pos('E', search_options, 1, 'I')) {
         ctl_matchcase.p_value = 1;
      } else {
         ctl_matchcase.p_value = 1;
      }

      if (pos('W', search_options, 1, 'I')) {
         ctl_matchword.p_value = 1;
      } else {
         ctl_matchword.p_value = 0;
      }

      if (pos('[RUBL&~]', search_options, 1, 'r')) {
         ctl_regex.p_value = 1;
         if (pos('r', search_options, 1, 'I')) {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_RE);
         } else if (pos('u', search_options, 1, 'I')) {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_PERLRE);
         } else if (pos('b', search_options, 1, 'I')) {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_PERLRE);
         } else if (pos('l', search_options, 1, 'I')) {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_PERLRE);
         } else if (pos('&', search_options, 1)) {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_WILDCARDRE);
         } else if (pos('~', search_options, 1)) {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_VIMRE);
         }
      } else {
         ctl_regex.p_value = 0;
      }

      if (pos('V', search_options, 1, 'I')) {
         ctl_preservecase.p_value = 1;
         ctl_matchcase.p_value = 0;
      } 

      if (pos('-', search_options)) {
         options |= VSSEARCHFLAG_REVERSE;
      } else if (pos('+', search_options) || def_keys == "brief-keys") {
         options &= ~VSSEARCHFLAG_REVERSE;
      }

      if (pos('H', search_options, 1, 'I')) {
         options |= VSSEARCHFLAG_HIDDEN_TEXT;
      } 

      if (pos('$', search_options, 1, 'I')) {
         options |= VSSEARCHFLAG_REPLACEHILIGHT;
      }

      if (pos('?', search_options, 1, 'I')) {
         options |= VSSEARCHFLAG_PROMPT_WRAP|VSSEARCHFLAG_WRAP;
      } else if (pos('P', search_options, 1, 'I')) {
         options |= VSSEARCHFLAG_WRAP;
         options &= ~(VSSEARCHFLAG_PROMPT_WRAP);
      }

      colors := _ccsearch_strip_colors_from_options(search_options);
      if (colors != '') {
         ctl_matchcolor.p_value = 1;
         _findcoloroptions.p_text = colors;
      } else {
         ctl_matchcolor.p_value = 0;
      }

      s_params.m_options = options;
   }

   if (mfflags != 0) {
      s_params.m_mfflags = mfflags & (MFFIND_MDICHILD|MFFIND_APPEND|MFFIND_FILESONLY|MFFIND_SINGLELINE|MFFIND_MATCHONLY|MFFIND_LIST_CURRENT_CONTEXT);
   }

   if (misc_options != '') {
      if (def_keys == "brief-keys") {
          misc_options = stranslate(misc_options, '', '_findback');
      }
      _init_misc_search_opts(misc_options);
   }
   if (search_range >= 0) {
      _ds_set_search_range(search_range);
   }
   _update_button_styles();

   ignore_change = false;
   activate_window(orig_wid);
}

extern int _ScrollMarkupGetWidth();
extern void _EditorGetScrollBarSize(int wid, int& width, int& height, int option);
extern void _FormWindowOnTopHint(int wid, int onoff);

static void _update_form_xy(int form_wid, int editorctl_wid)
{
   if (!editorctl_wid || !editorctl_wid._isEditorCtl(false)) {
      return;
   }
   wx := 0;
   wy := form_wid.p_y;
   ww := editorctl_wid.p_client_width;
   wh := editorctl_wid.p_client_height;
   _dxy2lxy(SM_TWIP, ww, wh);
   //_map_xy(editorctl_wid, 0, wx, wy, SM_TWIP);

   // get scroll bar and scroll markup offsets
   //_EditorGetScrollBarSize(editorctl_wid, auto vsbw, auto vsbh, 0);
   //right_margin := _ScrollMarkupGetWidth() + vsbw + 1;
   right_margin:=0;
   // Always make room for markup scroll bar so the
   // minifind dialog doesn't shift around when typing.
   if (_default_option(VSOPTION_VERTICAL_SCROLL_BAR) && !editorctl_wid.p_scroll_has_markup) {
      right_margin+=_ScrollMarkupGetWidth();
   }
   x := wx + ww - (form_wid.p_width + _dx2lx(SM_TWIP, right_margin));
   y := wy;
   fw := form_wid.p_width;
   if (x < 0) {
      fw = (form_wid.p_width + x);
      x = 0;
   }
   // minimum size
   // DOCSEARCH_MINIMUM_WIDTH_PIXELS
   if (fw < DOCSEARCH_MINIMUM_WIDTH_PIXELS*_twips_per_pixel_x()) {
      fw = DOCSEARCH_MINIMUM_WIDTH_PIXELS*_twips_per_pixel_x();
   }
   form_wid._move_window(x, y, fw, form_wid.p_height);
}

// parent move
void _on_ds_move(int form_wid, int editorctl_wid)
{
   get_window_id(auto orig_wid);
   activate_window(form_wid);
   _update_form_xy(form_wid, editorctl_wid);
   if (_replaceframe.p_visible) {
      _ds_update_tooltip(P_USER_MINIFIND_WID(), _findstring.p_text, _replacestring.p_text);
   }
   activate_window(orig_wid);
}

// parent resize
void _on_ds_resize()
{
   int form_wid = _find_formobj('_document_search_form','N');
   if (!form_wid) {
      return;
   }
   get_window_id(auto orig_wid);
   editorctl_wid := form_wid.P_USER_MINIFIND_WID();
   if (orig_wid != editorctl_wid) {
      return;
   }
   _on_ds_move(form_wid, editorctl_wid);
   activate_window(orig_wid);
}


static void _ds_set_editor_wid(int form_wid, int editorctl_wid)
{
   get_window_id(auto orig_wid);
   activate_window(form_wid);
   P_USER_MINIFIND_WID(editorctl_wid);
   _init_matchcolor(editorctl_wid);

   if (!editorctl_wid || !editorctl_wid._isEditorCtl(false)) {
      ctl_findprev.p_enabled = false;
      ctl_findnext.p_enabled = false;
      ctl_findnext_menu.p_enabled = false;
      ctl_replacere_menu.p_enabled = false;
      ctl_replacenext.p_enabled = false;
      ctl_replaceall.p_enabled = false;
      _findrange.p_enabled = false;

      activate_window(orig_wid);
      return;
   }

   activate_window(editorctl_wid);
   s_params.m_lastModified = p_LastModified;

   s_params.m_orig_mark = _alloc_selection();
   _select_char(s_params.m_orig_mark, 'EN');

   s_params.m_search_mark = _alloc_selection();
   _select_char(s_params.m_search_mark, 'EN');

   // clear old search scroll highlights
   clear_highlights();
   clear_scroll_highlights();
   _ExitScroll();

   key_callback_index := find_index('_ds_key_callback', PROC_TYPE);
   text_change_callback_index := find_index('_ds_text_change_callback', PROC_TYPE);
   DocSearchForm.init(form_wid, editorctl_wid, key_callback_index, text_change_callback_index);
   _AddEventtab(defeventtab _editorctl_resize_helper);
   activate_window(orig_wid);
}
 
static void _ds_unlink_editor_window(int editorctl_wid)
{
   get_window_id(auto orig_wid);
   _ds_clear_markers();
   if (editorctl_wid && _iswindow_valid(editorctl_wid) && editorctl_wid._isEditorCtl()) {
      _ds_dismiss_tooltip(editorctl_wid);
      editorctl_wid._RemoveEventtab(defeventtab _editorctl_resize_helper);
      activate_window(editorctl_wid);
      DocSearchForm.destroy();
   }
   if (s_params.m_orig_mark >= 0) {
      _free_selection(s_params.m_orig_mark);
      s_params.m_orig_mark = -1;
   }
   if (s_params.m_search_mark >= 0) {
      _free_selection(s_params.m_search_mark);
      s_params.m_search_mark = -1;
   }
   if (s_params.m_match_mark >= 0) {
      _free_selection(s_params.m_match_mark);
      s_params.m_match_mark = -1;
   }
   if (s_params.m_proc_mark >= 0) {
      _free_selection(s_params.m_proc_mark);
      s_params.m_proc_mark = -1;
   }
   activate_window(orig_wid);
}

static void _ds_save_state()
{
   replace_mode := _replaceframe.p_visible;
   _str state = ctl_matchcase.p_value:+" ":+
      ctl_matchword.p_value:+" ":+
      ctl_regex.p_value:+" ":+
      P_USER_MINIFIND_RE():+" ":+
      ctl_matchcolor.p_value:+" ":+
      ctl_preservecase.p_value:+" ":+
      s_params.m_grep_id:+" ":+
      s_params.m_options:+" ":+
      s_params.m_listreplace:+" ":+
      s_params.m_mfflags:+" ":+
      replace_mode:+" ":+
      P_USER_MINIFIND_ISEARCH():+" ":+
      s_params.m_grep_ab:+" ":+
      s_params.m_grep_before_lines:+" ":+
      s_params.m_grep_after_lines;
      
   ignore_change = true;
   _otheroptions.p_text = state;
   ignore_change = false;

   _findrange._append_retrieve(_control _findrange, _findrange.p_text);
   _findcoloroptions._append_retrieve(_findcoloroptions,_findcoloroptions.p_text);
}

static void _ds_restore_state(_str state, bool update_mode)
{
   if (state == '') {
      return;
   }
   typeless match_case = '', match_word = '', regex = '', user_re = '', match_color = '', preserve_case = '', options = '', 
      grep_id = '', mfflags = '', listreplace = '', replace_mode = '', isearch = '', grep_ab = '', grep_before_lines = '', grep_after_lines = '';

   parse state with match_case match_word regex user_re match_color preserve_case grep_id options listreplace mfflags replace_mode isearch grep_ab grep_before_lines grep_after_lines;

   old_ignore := ignore_change;
   ignore_change = true;
   if (match_case != '') {
      ctl_matchcase.p_value = (int)match_case;
   }
   if (match_word != '') {
      ctl_matchword.p_value = (int)match_word;
   }
   if (regex != '') {
      ctl_regex.p_value = (int)regex;
   }
   if (match_color != '') {
      ctl_matchcolor.p_value = (int)match_color;
   }
   if (preserve_case != '') {
      ctl_preservecase.p_value = (int)preserve_case;
   }
   if (user_re != '') {
      if ((int)user_re & VSSEARCHFLAG_PERLRE) {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_PERLRE);
      } else if ((int)user_re & VSSEARCHFLAG_VIMRE) {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_VIMRE);
      } else if ((int)user_re & VSSEARCHFLAG_WILDCARDRE) {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_WILDCARDRE);
      } else {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_RE);
      }
   }
   if (options != '') {
      s_params.m_options = (int)options;
   }
   if (listreplace != '') {
      s_params.m_listreplace = listreplace;
   }
   if (grep_id != '') {
      s_params.m_grep_id = (int)grep_id;
   }
   if (mfflags != '') {
      s_params.m_mfflags = (int)mfflags;
   }
   if (isearch != '') {
      P_USER_MINIFIND_ISEARCH((int)isearch);
   }
   if (grep_ab != '') {
      s_params.m_grep_ab = grep_ab;
   }
   if (grep_before_lines != '') {
      s_params.m_grep_before_lines = (int)grep_before_lines;
   }
   if (grep_after_lines != '') {
      s_params.m_grep_after_lines = (int)grep_after_lines;
   }
   if (update_mode) {
      _showhide_controls(replace_mode);
   }
   _update_button_styles();
   ignore_change = old_ignore;
}

/* Hotkeys for platform:
   Win/Linux         Mac 
   Esc               Esc                  Exit Mini Find 
   Ctrl+W            Ctrl+W               Get Word at Cursor 
   Ctrl+Shift+Space  Ctrl+Shift+Space     Complete Word at Cursor
   Ctrl+\            Command+\            Cycle Look-in 
   Ctrl+/            Command+/            Toggle highlighting
   Alt+F,Alt+Enter   Command+D            Find tools menu
   Alt+C             Command+E            Toggle Match Case
   Alt+W             Command+W            Toggle Match Word
   Alt+T,Alt+U       Command+T,Command+U  Toggle Regex
   Alt+Shift+T       Command+Shift+T      Regex menu
   Alt+O             Command+O            Toggle Color Search
   Alt+Shift+O       Command+Shift+O      Color Search Config menu
   Alt+K             Command+K            Look in combo [<Current Buffer>…]
   Alt+P             Command+P            Toggle Wrap Search
   Alt+B             Command+B            Toggle Search Backwards
   Alt+H             Command+H            Toggle Search Hidden 
   Alt+L             Command+L            List all occurrences (last grep buffer)
   Alt+Shift+L       Command+Shift+L      List all occurrences <New>
   Alt+Shift+I       Command+Shift+I      List all occurrences <AutoIncrement>
   Alt+0             Command+0            List all Search<0>
   Alt+1             Command+1            List all Search<1>
   Alt+2             Command+2            List all Search<2>
   Alt+3             Command+3            List all Search<3>
   Alt+4             Command+4            List all Search<4>
   Alt+5             Command+5            List all Search<5>
   Alt+6             Command+6            List all Search<6>
   Alt+7             Command+7            List all Search<7>
   Alt+8             Command+8            List all Search<8>
   Alt+9             Command+9            List all Search<9>
   Alt+G             Command+Q            Highlight All occurrences
   Alt+M             Command+M            Bookmark All occurrences
   Alt+S             Command+S            MultiSelect All occurrences
   Alt+R             Command+N            Replace Next occurrence
   Alt+A             Command+U            Replace All occurrences
   Alt+I             Command+I            Preview Replace All
   Alt+Shift+R       Command+Shift+R      Replace Regex menu
   Alt+V             Command+J            Toggle Replace: Preserve Case
   Alt+Shift+H       Command+Shift+Q      Toggle Replace Highlight
   Alt+Shift+U       Command+Shift+U      List replaced occurrences
   Alt+Shift+K       Command+Shift+K      Keep Replace
   Alt+Shift+X       Command+Shift+X      Delete Replace
   Ctrl+Tab                               Toggle Find/Replace
   Enter                                  Find Next
   Shift+Enter                            Find Previous
*/

static void _update_menu_caption(int item, _str key)
{
   parse item.p_caption with auto caption "\t" .;
   item.p_caption = caption :+ "\t" :+ _key_for_display(name2event(key));
}

static void _update_menu_command(int item, _str command, _str command2='')
{
   key := P_USER_MINIFIND_WID()._where_is(command);
   if (key:=='' && command2!='') {
      key=P_USER_MINIFIND_WID()._where_is(command2);
   }
   if (key != '') {
      parse item.p_caption with auto caption "\t" .;
      item.p_caption = caption :+ "\t" :+ key;
   }  else {
      parse item.p_caption with auto caption "\t" .;
      item.p_caption = caption;
   }
}

static void _update_menu_items(int menu_index, int item)
{
   if (!item) {
      return;
   }
   int first = item;
   do {
      if (item.p_object==OI_MENU) {
         _update_menu_items(item, item.p_child);
      } else {
         key := "";
         switch (item.p_command) {
         case "docsearch_find_menu next":
            _update_menu_command(item, "find-next","search-again");
            break;
         case "docsearch_find_menu prev":
            _update_menu_command(item, "find-prev");
            break;
         case "docsearch_find_menu preview":
            key = (_isMac()) ? "M_I" : "A_I";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu ^":
            key = "C_W";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu ^&":
            key = "C-S-W";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu ^+":
            key = "C-S- ";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu p":
            key = (_isMac()) ? "M_P" : "A_P";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu -":
            key = (_isMac()) ? "M_B" : "A_B";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu h":
            key = (_isMac()) ? "M_H" : "A_H";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu #":
            key = (_isMac()) ? "M_Q" : "A_G";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu m":
            key = (_isMac()) ? "M_M" : "A_M";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu |":
            key = (_isMac()) ? "M_S" : "A_S";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu $":
            key = (_isMac()) ? "M_S_Q" : "A_S_H";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu list_replace":
            key = (_isMac()) ? "M_S_U" : "A_S_U";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu grep new":
            key = (_isMac()) ? "M_S_L" : "A_S_L";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu grep auto":
            key = (_isMac()) ? "M_S_I" : "A_S_I";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu find-in-files":
            _update_menu_command(item, "find-in-files");
            break;
         case "docsearch_find_menu replace-in-files":
            _update_menu_command(item, "replace-in-files");
            break;
         case "docsearch_find_menu toggle_hilite":
            key = (_isMac()) ? "M_/" : "C_/";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu keep":
            key = (_isMac()) ? "M_S_K" : "A_S_K";
            _update_menu_caption(item, key);
            break;
         case "docsearch_find_menu delete":
            key = (_isMac()) ? "M_S_X" : "A_S_X";
            _update_menu_caption(item, key);
            break;

         }
      }
      item = item.p_next;
   } while (item != first);
}

static void _update_button_label(_str ctrl, _str key)
{
   caption := ctrl.p_message :+ " (" :+ _key_for_display(name2event(key)) :+ ")";
   ctrl.p_message = caption;
}

static void _update_hotkey_labels()
{
   key := P_USER_MINIFIND_WID()._where_is('find-next');
   if (key:=='') {
      // Brief key binding
      key=P_USER_MINIFIND_WID()._where_is('search-again');
   }
   caption := ctl_findnext.p_message :+ " (" :+ key :+ ")";
   ctl_findnext.p_message = caption;

   key = P_USER_MINIFIND_WID()._where_is('find-prev');
   caption = ctl_findprev.p_message :+ " (" :+ key :+ ")";
   ctl_findprev.p_message = caption;

   if (_isMac()) {
      _update_button_label(ctl_findnext_menu.p_window_id, 'M_D');
      _update_button_label(ctl_replacenext.p_window_id, 'M_N');
      _update_button_label(ctl_replaceall.p_window_id, 'M_A');
      _update_button_label(ctl_preservecase.p_window_id, 'M_J');
      _update_button_label(ctl_matchcase.p_window_id, 'M_E');
      _update_button_label(ctl_matchword.p_window_id, 'M_W');
      _update_button_label(ctl_regex.p_window_id, 'M_T');
      _update_button_label(ctl_regex_menu.p_window_id, 'M_S_T');
      _update_button_label(ctl_matchcolor.p_window_id, 'M_O');
      _update_button_label(ctl_matchcolor_menu.p_window_id, 'M_S_O');
   } else {
      _update_button_label(ctl_findnext_menu.p_window_id, 'A_F');
      _update_button_label(ctl_replacenext.p_window_id, 'A_R');
      _update_button_label(ctl_replaceall.p_window_id, 'A_A');
      _update_button_label(ctl_preservecase.p_window_id, 'A_V');
      _update_button_label(ctl_matchcase.p_window_id, 'A_C');
      _update_button_label(ctl_matchword.p_window_id, 'A_W');
      _update_button_label(ctl_regex.p_window_id, 'A_T');
      _update_button_label(ctl_regex_menu.p_window_id, 'A_S_T');
      _update_button_label(ctl_matchcolor.p_window_id, 'A_O');
      _update_button_label(ctl_matchcolor_menu.p_window_id, 'A_S_O');
   }

   if (update_menu_hotkeys) {
      int menu_index = find_index("_docsearchfind_menu", oi2type(OI_MENU));
      if (menu_index) {
         _update_menu_items(menu_index, menu_index.p_child);
      }
      update_menu_hotkeys = false;
   }
}

void _document_search_form.'range-first-nonchar-key'-'all-range-last-nonchar-key'()
/*  'C-A'-'C-Z','c-s-a'-'c-s-z','c-a-a'-'c-a-z','a-a'-'a-z','a-s-a'-'a-s-z','c-0'-'c-9','c-s-0'-'c-s-9',\
                           'c-a-0'-'c-a-9','a-0'-'a-9','M-A'-'M-Z','M-0'-'M-9','S-M-A'-'S-M-Z','S-M-0'-'S-M-9','C-S- ',\
                            F1-F12,C_F1-C_F12,A_F1-A_F12,S_F1-S_F12,'c-a-s-a'-'c-a-s-z','c-a-s-0'-'s-m-9'()
 */
{
   if (ignore_change) {
      return;
   }
   if (already_hit_event) {
      return;
   }
   if (last_event():==ENTER || last_event():==TAB || last_event():==S_TAB) {
      etab_index:=find_index('_document_search_form',EVENTTAB_TYPE);
      set_eventtab_index(etab_index,event2index(last_event()),0);
      already_hit_event = true;
      p_window_id.call_event(p_window_id, last_event(), "W"); 
      already_hit_event = false;
      return;
   }
   // Dont' need to check ESC here because it's 
   // overridden below. This is here just in case function order changes.
   if (last_event():==ESC) {
      ctl_close.call_event(_control ctl_close, LBUTTON_UP, "W");
      return;
   }
   editorctl_wid := P_USER_MINIFIND_WID();
   search_range := _ds_get_search_range();
   _str key = last_event();
   _str command = name_on_key(key);
   switch (command) {
   case "gui-find":
   case "gui-find-backward":
   case "gui-find-regex":
   case "gui-replace":
   case "gui-replace-backward":
   case "gui-replace-regex":
   case "tool-gui-find":
   case "tool-gui-replace":
   case "find-in-files":
   case "replace-in-files":
   case "find-file":
      _ds_translate_command(command);
      return;
   case "search-again":
   case "find-next":
      doNext();
      return;
   case "find-prev":
      doNext(true);
      return;
   default:
      break;
   }
   if (key:==F4 && (p_window_id == _findstring || p_window_id == _replacestring)) {
      _ComboBoxCommand('f4');
      return;
   }

   switch (key) {
   case name2event('C-W'):
      if (p_window_id == _findstring) {
         doCurrentWordAtCursor();
      }
      return;
   case name2event('C-S-W'):
      if (p_window_id == _findstring) {
         doGetCurrentSelection();
      }
      return;
   case name2event('C-S- '):
      if (p_window_id == _findstring) {
         doWordCompletion();
      }
      return;
   case name2event('C_TAB'):
      _togglemode.call_event(_control _togglemode, LBUTTON_UP, "W");
      return;
   case name2event('S_ENTER'):
      doNext(true);
      return;
   case name2event('A_ENTER'):
   case name2event('M_D'):
   case name2event('A_F'):
      ctl_findnext_menu.call_event(_control ctl_findnext_menu, LBUTTON_UP, "W");
      return;
   case name2event('M_E'):
   case name2event('A_C'):
      ctl_matchcase.call_event(_control ctl_matchcase, LBUTTON_UP, "W");
      return;
   case name2event('M_W'):
   case name2event('A_W'):
      ctl_matchword.call_event(_control ctl_matchword, LBUTTON_UP, "W");
      return;
   case name2event('M_T'):
   case name2event('M_U'):
   case name2event('A_T'):
   case name2event('A_U'):
      ctl_regex.call_event(_control ctl_regex, LBUTTON_UP, "W");
      return;
   case name2event('M_S_T'):
   case name2event('A_S_T'):
      if (ctl_regex_menu.p_visible) {
         ctl_regex_menu.call_event(_control ctl_regex_menu, LBUTTON_UP, "W");
      }
      return;
   case name2event('M_O'):
   case name2event('A_O'):
      ctl_matchcolor.call_event(_control ctl_matchcolor, LBUTTON_UP, "W");
      return;
   case name2event('M_S_O'):
   case name2event('A_S_O'):
      ctl_matchcolor_menu.call_event(_control ctl_matchcolor_menu, LBUTTON_UP, "W");
      return;
   case name2event('M_K'):
   case name2event('A_K'):
      _findrange._set_focus();
      return;
   case name2event('M_P'):
   case name2event('A_P'):
      s_params.m_options = s_params.m_options ^ VSSEARCHFLAG_WRAP; 
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      return;
   case name2event('M_B'):
   case name2event('A_B'):
      s_params.m_options = s_params.m_options ^ VSSEARCHFLAG_REVERSE; 
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      return;
   case name2event('M_H'):
   case name2event('A_H'):
      s_params.m_options = s_params.m_options ^ VSSEARCHFLAG_HIDDEN_TEXT; 
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      return;
   case name2event('M_,'):
   case name2event('A_,'):
      s_params.m_options = s_params.m_options ^ VSSEARCHFLAG_POSITIONONLASTCHAR; 
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      return;
   case name2event('M_L'):
   case name2event('A_L'):
      doListAll(-1);
      return;
   case name2event('M_S_L'):
   case name2event('A_S_L'):
      doListAll(GREP_NEW_WINDOW);
      return;
   case name2event('M_S_I'):
   case name2event('A_S_I'):
      doListAll(GREP_AUTO_INCREMENT);
      return;
   case name2event('M_0'):
   case name2event('A_0'):
      doListAll(0);
      return;
   case name2event('M_1'):
   case name2event('A_1'):
      doListAll(1);
      return;
   case name2event('M_2'):
   case name2event('A_2'):
      doListAll(2);
      return;
   case name2event('M_3'):
   case name2event('A_3'):
      doListAll(3);
      return;
   case name2event('M_4'):
   case name2event('A_4'):
      doListAll(4);
      return;
   case name2event('M_5'):
   case name2event('A_5'):
      doListAll(5);
      return;
   case name2event('M_6'):
   case name2event('A_6'):
      doListAll(6);
      return;
   case name2event('M_7'):
   case name2event('A_7'):
      doListAll(7);
      return;
   case name2event('M_8'):
   case name2event('A_8'):
      doListAll(8);
      return;
   case name2event('M_9'):
   case name2event('A_9'):
      doListAll(9);
      return;
   case name2event('M_Q'):
   case name2event('A_G'):
      if (search_range != VSSEARCHRANGE_PROJECT && search_range != VSSEARCHRANGE_WORKSPACE) {
         doHighlight();
      }
      return;
   case name2event('M_M'):
   case name2event('A_M'):
      if (search_range != VSSEARCHRANGE_PROJECT && search_range != VSSEARCHRANGE_WORKSPACE) {
         doBookmarks();
      }
      return;
   case name2event('M_S'):
   case name2event('A_S'):
      if (search_range != VSSEARCHRANGE_ALL_BUFFERS && search_range != VSSEARCHRANGE_PROJECT && search_range != VSSEARCHRANGE_WORKSPACE) {
         doMultiSelect();
      }
      return;
   case name2event('M_\'):
   case name2event('C_\'):
      _ds_cycle_range(1);
      return;
   case name2event('M_S_\'):
   case name2event('C_S_\'):
      _ds_cycle_range(-1);
      return;
   case name2event('M_/'):
   case name2event('C_/'):
      def_search_incremental_highlight = (def_search_incremental_highlight) ? 0 : 1;
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      return;
   case name2event('C_S_ENTER'):
      _ds_goto_start();
      return;
   case name2event('A_S_X'):
      doDeleteSearch();
      return;
   case name2event('A_S_K'):
      doKeepSearch();
      return;
   }

   if (_replaceframe.p_visible) {
      switch (key) {
      case name2event('M_N'):
      case name2event('A_R'):
         doReplace();
         return;
      case name2event('M_A'):
      case name2event('A_A'):
         doReplace(true);
         return;
      case name2event('M_I'):
      case name2event('A_I'):
         doReplace(true, true);
         return;
      case name2event('M_S_R'):
      case name2event('A_S_R'):
         if (ctl_replacere_menu.p_visible) {
            ctl_replacere_menu.call_event(_control ctl_replacere_menu, LBUTTON_UP, "W");
         }
         break;
      case name2event('M_J'):
      case name2event('A_V'):
         ctl_preservecase.call_event(_control ctl_preservecase, LBUTTON_UP, "W");
         return;
      case name2event('M_S_Q'):
      case name2event('A_S_H'):
         s_params.m_options = s_params.m_options ^ VSSEARCHFLAG_REPLACEHILIGHT;
         if (!(s_params.m_options & VSSEARCHFLAG_REPLACEHILIGHT)) {
            editorctl_wid.clear_highlights();
         }
         return;
      case name2event('M_S_U'):
      case name2event('A_S_U'):
         s_params.m_listreplace = !s_params.m_listreplace;
         return;
      }
   }

   if (p_object == OI_TEXT_BOX || p_object == OI_COMBO_BOX) {
      already_hit_event = true;
      _smart_toolwindow_hotkey();
      already_hit_event = false;
   }
}

void _document_search_form.on_create(int editorctl_wid, _str mode, _str search_options="")
{  
   _ds_init_markers();
   _ComboBoxSetPlaceHolderText(_findstring.p_window_id, "Find");
   _ComboBoxSetPlaceHolderText(_replacestring.p_window_id, "Replace");
   _findstring.p_eventtab2=defeventtab _ul2_combobx_docsearch;
   _replacestring.p_eventtab2=defeventtab _ul2_combobx_docsearch;
   _findstring.p_AllowDeleteHistory=true;
   _replacestring.p_AllowDeleteHistory=true;     
   s_params.m_status = -1;
   s_params.m_lastModified = editorctl_wid.p_LastModified;
   s_params.m_marker_id = -1;
   s_params.m_scrollmarker_id = -1;
   s_params.m_orig_mark = -1;
   s_params.m_search_mark = -1;
   s_params.m_match_mark = -1;
   s_params.m_proc_mark = -1;
   s_params.m_last_mark = -1;
   s_params.m_last_mark_info = '';
   s_params.m_match_length = 0;
   s_params.m_match_start = 0;
   s_params.m_match_replace = 0;
   s_params.m_num_matches = 0;
   s_params.m_grep_id = 0;
   s_params.m_grep_before_lines = 1;
   s_params.m_grep_after_lines = 1;
   s_params.m_options = 0;
   s_params.m_mfflags = 0;
   s_params.m_listreplace = false;
   s_params.m_scroll_info = '';
   s_params.m_tooltip = false;
   s_params.m_update = true;
   s_params.m_disable_occurences = false;
   s_params.m_macro_last_search = false;
   s_params.m_start_mark = -1;
   s_params.m_start_wrap = false;
   s_params.m_match_prev = false;

   P_USER_MINIFIND_WID(0);
   P_USER_MINIFIND_RE(VSSEARCHFLAG_PERLRE);
   if (def_re_search_flags & VSSEARCHFLAG_PERLRE) {
      P_USER_MINIFIND_RE(VSSEARCHFLAG_PERLRE);
   } else if (def_re_search_flags & VSSEARCHFLAG_VIMRE) {
      P_USER_MINIFIND_RE(VSSEARCHFLAG_VIMRE);
   } else if (def_re_search_flags & VSSEARCHFLAG_WILDCARDRE) {
      P_USER_MINIFIND_RE(VSSEARCHFLAG_WILDCARDRE);
   } else {
      P_USER_MINIFIND_RE(VSSEARCHFLAG_RE);
   }
   P_USER_MINIFIND_ISEARCH(true);

   typeless value = _moncfg_retrieve_value("_document_search_form.p_width");
   if (value != '') {
      p_active_form.p_width = value;
   }
   p_active_form.p_y = 0;
   _update_form_xy(p_active_form.p_window_id, editorctl_wid);
   _ds_set_editor_wid(p_active_form.p_window_id, editorctl_wid);

   ignore_change = true;
   show_replace_frame := (mode :== 'R');
   _update_hotkey_labels();
   _init_search_range(editorctl_wid);
   if (_retrieve_prev_form() || def_find_init_defaults) {
      _init_search_flags(_default_option('S'));
   } else {
      _ds_restore_state(_otheroptions.p_text, (mode :== 'RELOAD'));
   }
   _findstring._retrieve_list("_tbfind_form._findstring"); P_USER_MINIFIND_FIND_LIST_REFRESH(1);
   _replacestring._retrieve_list("_tbfind_form._replacestring");  P_USER_MINIFIND_REPLACE_LIST_REFRESH(1);
   if (mode != 'RELOAD') {
      _init_findstring(editorctl_wid);
      if (editorctl_wid._isEditorCtl(false) && editorctl_wid.select_active2()) {
         typeless junk;
         editorctl_wid._get_selinfo(auto start_col, auto end_col, junk, '', auto buf_name, junk, junk, auto Noflines);
         if (_select_type('') == 'LINE' || Noflines > 1) {
            _findrange._cbset_text(SEARCH_IN_CURRENT_SELECTION); old_search_range = VSSEARCHRANGE_CURRENT_SELECTION;
         }
      }
   }
   if (search_options != '') {
      _ds_set_search_options(search_options);
   } else {
      mini_find_update_options('', '', old_search_options, old_search_range, old_search_mfflags, old_search_misc_options);
   }
   _showhide_controls(show_replace_frame);
   _resize_frame_widths();
   _update_button_styles();
   _ds_update_color_label();
   //_findlabel.p_forecolor = 0x80000011; // inactive color
   ignore_change = false;
   already_hit_event = false;
}

static void _ds_update_history()
{
   search_string := _findstring.p_text;
   replace_string := _replacestring.p_text;
   search_options := _ds_get_search_options();
   mfflags := s_params.m_mfflags;
   search_range := _ds_get_search_range();
   save_last_search('', search_options, search_range, mfflags, _get_misc_search_opts());
   if (search_string != '') {
      _append_retrieve(0, search_string, "_tbfind_form._findstring");
   }
   save_last_replace(replace_string);
   if (!s_params.m_status) {
      _menu_add_searchhist(search_string, search_options);
   }
}

static void _ds_exit(int form_wid)
{
   editorctl_wid := P_USER_MINIFIND_WID();
   _ds_clear_markers();
   get_window_id(auto wid);
   activate_window(form_wid);
   _ds_save_state();
   _ds_update_history();
   _save_form_response();
   _moncfg_append_retrieve(0, p_active_form.p_width, "_document_search_form.p_width");
   if (editorctl_wid && _iswindow_valid(editorctl_wid) && editorctl_wid._isEditorCtl()) {
      _ds_dismiss_tooltip(editorctl_wid);
      editorctl_wid._RemoveEventtab(defeventtab _editorctl_resize_helper);
      activate_window(editorctl_wid);
      DocSearchForm.destroy();
   }
   if (s_params.m_orig_mark >= 0) {
      _free_selection(s_params.m_orig_mark);
      s_params.m_orig_mark = -1;
   }
   if (s_params.m_search_mark >= 0) {
      _free_selection(s_params.m_search_mark);
      s_params.m_search_mark = -1;
   }
   if (s_params.m_match_mark >= 0) {
      _free_selection(s_params.m_match_mark);
      s_params.m_match_mark = -1;
   }
   if (s_params.m_proc_mark >= 0) {
      _free_selection(s_params.m_proc_mark);
      s_params.m_proc_mark = -1;
   }
   activate_window(wid);
}

static void _ds_reinit_form(int editorctl_wid, bool replace_mode=false)
{
   ignore_change = true;
   _showhide_controls(replace_mode);
   _resize_frame_widths();

   _init_findstring(editorctl_wid);
   _replacestring.p_text = old_replace_string;
   _init_search_range(editorctl_wid, _findrange.p_text);
   if (editorctl_wid.select_active2()) {
      typeless junk;
      editorctl_wid._get_selinfo(auto start_col, auto end_col, junk, '', auto buf_name, junk, junk, auto Noflines);
      if (_select_type('') == 'LINE' || Noflines > 1) {
         _findrange._cbset_text(SEARCH_IN_CURRENT_SELECTION);
      }
   }
   P_USER_MINIFIND_WID(0);
   _ds_reset_marks();
   _ds_set_editor_wid(p_active_form.p_window_id, editorctl_wid);
   ignore_change = false;
   doUpdate();
   _findstring._set_focus();
}

/** 
 * Bring up mini-find dialog with already <Current Procedure> 
 * already selected (if applicable). 
 */
_command void mini_find_in_current_proc(...) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   int form_wid = _find_object('_document_search_form','N');
   if (form_wid) {
      // recycle form?
      get_window_id(auto wid);
      activate_window(form_wid);
      editorctl_wid := P_USER_MINIFIND_WID();
      activate_window(wid);
      if (wid == editorctl_wid) {
         form_wid._ds_reinit_form(p_window_id, false);
         return;
      }
      form_wid._delete_window();
   } else {
      mode := 'F';
      form_wid = show('-child -NOCENTER _document_search_form', p_window_id, mode, arg(2));
   }
   if ( form_wid ) {
      form_wid._findrange.p_text = SEARCH_IN_CURRENT_PROC;
   }
   _macro_delete_line();
}

void _document_search_form.on_close()
{
   ctl_close.call_event(_control ctl_close, LBUTTON_UP, "W");   
}

void _document_search_form.on_destroy()
{
   form_wid := p_active_form.p_window_id;
   _ds_exit(form_wid);
}

void _document_search_form.on_load()
{
   doUpdate();
}

static int DOCSEARCH_AFTER_BUTTON_SPACE_DX() {
   return  (_twips_per_pixel_x()*2);
}
static int DOCSEARCH_AFTER_MENU_SPACE_DX() {
   return  (DOCSEARCH_AFTER_BUTTON_SPACE_DX()*2);
}

static void _resize_and_position_options() {
   //return;
   if (p_active_form.p_visible) {
      return;
   }
   maxwidth := 0;
   maxheight := 0;
   ctl_matchcase.p_auto_size=true;
   if(ctl_matchcase.p_width>maxwidth) maxwidth=ctl_matchcase.p_width;
   if(ctl_matchcase.p_height>maxheight) maxheight=ctl_matchcase.p_height;

   ctl_matchword.p_auto_size=true;
   if(ctl_matchword.p_width>maxwidth) maxwidth=ctl_matchword.p_width;
   if(ctl_matchword.p_height>maxheight) maxheight=ctl_matchword.p_height;
   ctl_regex.p_auto_size=true;
   if(ctl_regex.p_width>maxwidth) maxwidth=ctl_regex.p_width;
   if(ctl_regex.p_height>maxheight) maxheight=ctl_regex.p_height;

   sizeBrowseButtonToTextBox(ctl_regex.p_window_id, ctl_regex_menu.p_window_id);
   int menu_width=ctl_regex_menu.p_width/*-2*_twips_per_pixel_x()*/;

   ctl_matchcolor.p_auto_size=true;
   if(ctl_matchcolor.p_width>maxwidth) maxwidth=ctl_matchcolor.p_width;
   if(ctl_matchcolor.p_height>maxheight) maxheight=ctl_matchcolor.p_height;

   ctl_replaceall.p_auto_size=true;
   if(ctl_replaceall.p_width>maxwidth) maxwidth=ctl_replaceall.p_width;
   if(ctl_replaceall.p_height>maxheight) maxheight=ctl_replaceall.p_height;

   ctl_preservecase.p_auto_size=true;
   if(ctl_preservecase.p_width>maxwidth) maxwidth=ctl_preservecase.p_width;
   if(ctl_preservecase.p_height>maxheight) maxheight=ctl_preservecase.p_height;

   _findrange.p_auto_size=true;
   //if(_findrange.p_width>maxwidth) maxwidth=_findrange.p_width;
   if(_findrange.p_height>maxheight) maxheight=_findrange.p_height;

   if (_optionsframe.p_height<maxheight) {
      _optionsframe.p_height=maxheight;
   }

   int x=ctl_matchcase.p_x;
   int y=(_optionsframe.p_height-maxheight) intdiv 2;
   ctl_matchcase.p_y=y;
   ctl_matchcase.p_auto_size=false;
   ctl_matchcase.p_width=maxwidth;ctl_matchcase.p_height=maxheight;

   ctl_matchword.p_y=y;
   ctl_matchword.p_auto_size=false;
   ctl_matchword.p_x=ctl_matchcase.p_x_extent+DOCSEARCH_AFTER_BUTTON_SPACE_DX();
   ctl_matchword.p_width=maxwidth;ctl_matchword.p_height=maxheight;

   ctl_regex.p_y=y;
   ctl_regex.p_auto_size=false;
   ctl_regex.p_x=ctl_matchword.p_x_extent+DOCSEARCH_AFTER_BUTTON_SPACE_DX();
   ctl_regex.p_width=maxwidth;ctl_regex.p_height=maxheight;

   sizeBrowseButtonToTextBox(ctl_regex.p_window_id, ctl_regex_menu.p_window_id);

   ctl_matchcolor.p_y=y;
   ctl_matchcolor.p_auto_size=false;
   ctl_matchcolor.p_x=ctl_regex_menu.p_x_extent+DOCSEARCH_AFTER_MENU_SPACE_DX();
   ctl_matchcolor.p_width=maxwidth;ctl_matchcolor.p_height=maxheight;

   sizeBrowseButtonToTextBox(ctl_matchcolor.p_window_id, ctl_matchcolor_menu.p_window_id);

   _findrange.p_y=y;
   _findrange.p_auto_size=false;
   _findrange.p_x=ctl_matchcolor_menu.p_x_extent+DOCSEARCH_AFTER_MENU_SPACE_DX();
   /*_findrange.p_width=menu_width;*/_findrange.p_height=maxheight;

   _findlabel.p_auto_size=false;
   _findlabel.p_y=y;
   _findlabel.p_height=maxheight;
}
static void _resize_frame_heights() 
{
   _resize_and_position_options();

   dy := 30;
   if (_findframe.p_visible) {
      _findframe.p_y = dy;
      dy += _findframe.p_height;
   }
   if (_replaceframe.p_visible) {
      _replaceframe.p_y = dy;
      dy += _replaceframe.p_height;
   }
   if (_optionsframe.p_visible) {
      _optionsframe.p_y = dy;
      dy += _optionsframe.p_height;
   }
   p_active_form.p_height = dy + 60;
   ctl_sizegrip.p_y = p_active_form.p_height - ctl_sizegrip.p_height;
}

static void _resize_replace_frame_widths()
{
   // replace frame
   if (!_replaceframe.p_visible) {
      return;
   }
   int maxwidth=ctl_matchcase.p_width;
   int maxheight=ctl_matchcase.p_height;
   int menu_width=ctl_regex_menu.p_width;
   //dx := _replaceframe.p_width - (_dx2lx(SM_TWIP, 4) + ctl_preservecase.p_width);
   /*ctl_preservecase.p_x = dx;
   dx -= ctl_replaceall.p_width;
   ctl_replaceall.p_x = dx;
   dx -= ctl_replacenext.p_width;
   ctl_replacenext.p_x = dx;*/

   ctl_replacere_menu.p_visible = (ctl_regex.p_value != 0);
   /*if (ctl_replacere_menu.p_visible) {
      dx -= ctl_replacere_menu.p_width;
      ctl_replacere_menu.p_x = dx;
   } */

   spacer := _dx2lx(SM_TWIP, 2);
   //dw := dx - (_replacestring.p_x + spacer);
   dw := (_findstring.p_x_extent) - (_replacestring.p_x);
   if (ctl_replacere_menu.p_visible) {
      dw-=menu_width+DOCSEARCH_AFTER_MENU_SPACE_DX();
   }
   
   _replacestring.p_width = dw;


   int y=(_replaceframe.p_height-maxheight) intdiv 2;
   int dx=_replacestring.p_x_extent+DOCSEARCH_AFTER_BUTTON_SPACE_DX()*2;
   if (ctl_replacere_menu.p_visible) {
      sizeBrowseButtonToTextBox(_replacestring.p_window_id, ctl_replacere_menu.p_window_id);
      dx=ctl_replacere_menu.p_x_extent+DOCSEARCH_AFTER_MENU_SPACE_DX();
   }
   ctl_replacenext.p_y=y;
   ctl_replacenext.p_auto_size=false;
   ctl_replacenext.p_x=dx;
   ctl_replacenext.p_width=maxwidth;ctl_replacenext.p_height=maxheight;

   
   ctl_replaceall.p_y=y;
   ctl_replaceall.p_auto_size=false;
   ctl_replaceall.p_x=ctl_replacenext.p_x_extent+DOCSEARCH_AFTER_BUTTON_SPACE_DX();
   ctl_replaceall.p_width=maxwidth;ctl_replaceall.p_height=maxheight;

   ctl_preservecase.p_y=y;
   ctl_preservecase.p_auto_size=false;
   ctl_preservecase.p_x=ctl_replaceall.p_x_extent+DOCSEARCH_AFTER_BUTTON_SPACE_DX();
   ctl_preservecase.p_width=maxwidth;ctl_preservecase.p_height=maxheight;
}

static void _resize_options_widths(_str msg = '')
{
   dx := _findstring.p_x_extent + DOCSEARCH_AFTER_BUTTON_SPACE_DX();
   dw := _optionsframe.p_width - (dx + DOCSEARCH_AFTER_BUTTON_SPACE_DX());
   lw := _findlabel.p_width;
   if (msg != "") {
      lw = _findlabel._text_width(msg);
   }
   if (lw < dw) {
      lw = dw;
   }
   if ((lw > _findlabel.p_width) && (lw < (_optionsframe.p_width - _findrange.p_x))) {
      _findlabel.p_width = lw;
   }
   lx := _optionsframe.p_width - (_findlabel.p_width + DOCSEARCH_AFTER_BUTTON_SPACE_DX() + DOCSEARCH_AFTER_BUTTON_SPACE_DX());
   _findlabel.p_x = lx;
   _findrange.p_width = lx - (_findrange.p_x + DOCSEARCH_AFTER_BUTTON_SPACE_DX());
}

static void _resize_frame_widths() 
{
   spacer := DOCSEARCH_AFTER_BUTTON_SPACE_DX();
   dw := p_width;
   _findframe.p_x_extent = dw ;
   _replaceframe.p_x_extent = dw ;
   _optionsframe.p_x_extent = dw ;
   
   int maxwidth=ctl_matchcase.p_width;
   int maxheight=ctl_matchcase.p_height;
   int menu_width=ctl_regex_menu.p_width;
   int y=(_findframe.p_height-maxheight) intdiv 2;

   // find frame
   dx := _findframe.p_width - spacer;
   sizeBrowseButtonToTextBox(_findstring.p_window_id, 
                             ctl_findnext_menu.p_window_id, 
                             ctl_close.p_window_id,
                             _findframe.p_width);
   sizeBrowseButtonToTextBox(_findstring.p_window_id, 
                             ctl_findprev.p_window_id, 
                             ctl_findnext.p_window_id,
                             ctl_findnext_menu.p_x);

   _resize_replace_frame_widths();
   _resize_options_widths();
}

static void _update_button_styles()
{
   ctl_matchcase.p_style = (ctl_matchcase.p_value) ? PSPIC_BUTTON : PSPIC_FLAT_BUTTON;
   ctl_matchword.p_style = (ctl_matchword.p_value) ? PSPIC_BUTTON : PSPIC_FLAT_BUTTON;
   ctl_regex.p_style = (ctl_regex.p_value) ? PSPIC_BUTTON : PSPIC_FLAT_BUTTON;
   ctl_matchcolor.p_style = (ctl_matchcolor.p_value) ? PSPIC_BUTTON : PSPIC_FLAT_BUTTON;
   ctl_preservecase.p_style = (ctl_preservecase.p_value) ? PSPIC_BUTTON : PSPIC_FLAT_BUTTON;
}

void _document_search_form.on_resize()
{
   _picframe.p_width = p_width;
   _picframe.p_height = p_height;
   _resize_frame_widths();
}

bool _ds_key_callback(int form_wid, _str key, _str command)
{
   status := false;
   get_window_id(auto orig_wid);
   activate_window(form_wid);
   if (key == ESC) {
      ctl_close.call_event(_control ctl_close, LBUTTON_UP, "W");   
      activate_window(orig_wid);
      return(true);
   }
   switch (command) {
   case 'find_next':
   case 'search_again':
      doNext(false);
      return(true);

   case 'find_prev':
      doNext(true);
      return(true);
   }
   return(false);
}

bool _gui_find_next(bool doPrev=false)
{
   int form_wid = _find_formobj('_document_search_form','N');
   if (!form_wid) {
      return(false);
   }
   get_window_id(auto wid);
   if (form_wid.P_USER_MINIFIND_WID() == wid) {
      form_wid.doNext(doPrev);
      return(true);
   }
   form_wid._delete_window();
   return(false);
}

static void _ds_clear_offsets(int editorctl_wid, int start_offset, int end_offset)
{
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      return;
   }
   if (def_search_incremental_highlight) {
      return;
   }

   search_string := _findstring.p_text;
   if (search_string :== '') {
      return;
   }

   // find markers
   if (start_offset > 0) {
      --start_offset;
   }
   _StreamMarkerFindList(auto list, editorctl_wid, start_offset, end_offset - start_offset + 2, 0, gDSMarkerType);
   if (list._isempty()) {
      return;
   }

   VSSTREAMMARKERINFO info;
   foreach (auto id in list) {
      if (_StreamMarkerGet(id, info)) {
         continue;
      }
      _StreamMarkerRemove(id);
      if (s_params.m_marker_id == id) {
         s_params.m_marker_id = -1;
      }
   }
}

void _ds_text_change_callback(int form_wid, int editorctl_wid, int start_offset, int end_offset)
{
   if (ignore_text_change) {
      return;
   }
   get_window_id(auto wid);
   activate_window(form_wid);
   _ds_clear_offsets(editorctl_wid, start_offset, end_offset);
   _ds_dismiss_tooltip(P_USER_MINIFIND_WID());
   activate_window(wid);
}

static void _ds_goto_start()
{
   editorctl_wid := P_USER_MINIFIND_WID();
   if (s_params.m_orig_mark >= 0) {
      editorctl_wid._begin_select(s_params.m_orig_mark);
   }
}

static void _ds_goto_wrap()
{
   editorctl_wid := P_USER_MINIFIND_WID();
   if (s_params.m_start_mark >= 0) {
      editorctl_wid._begin_select(s_params.m_start_mark);
   }
}

static void _ds_show_proc()
{
   editorctl_wid := P_USER_MINIFIND_WID();
   get_window_id(auto wid);
   activate_window(editorctl_wid);
   if (s_params.m_proc_mark >= 0) {
      mark_id := _duplicate_selection('');
      dmark_id := _duplicate_selection(s_params.m_proc_mark);
      _show_selection(dmark_id);
      _free_selection(mark_id);
   }
   activate_window(wid);
}

static void _ds_search_forward()
{
   editorctl_wid := P_USER_MINIFIND_WID();
   reverse_search := (s_params.m_options & VSSEARCHFLAG_REVERSE);

   if (reverse_search) {
      s_params.m_options &= ~VSSEARCHFLAG_REVERSE;
      status := s_params.m_status;
      doSearch();  // update search flags
      if (status) {
         return;  // return if not set previously
      }
   }
   doNext();
}

static void _ds_search_backward()
{
   editorctl_wid := P_USER_MINIFIND_WID();
   reverse_search := (s_params.m_options & VSSEARCHFLAG_REVERSE);
   if (!reverse_search) {
      s_params.m_options |= VSSEARCHFLAG_REVERSE;
      status := s_params.m_status;
      doSearch(); // update search flags
      if (status) {
         return; // return if not set previously
      }
   }
   doNext();
}

static void _ds_cycle_range(int dir=1)
{
   if (!_findrange.p_enabled) {
      return;
   }

   editorctl_wid := P_USER_MINIFIND_WID;
   range = _findrange.p_text;

   int i;
   for (i = 0; i < 6; ++i) {
      switch(range) {
         case SEARCH_IN_CURRENT_BUFFER:    range = (dir > 0) ? SEARCH_IN_CURRENT_SELECTION : MFFIND_WORKSPACE_FILES; break;  
         case SEARCH_IN_CURRENT_SELECTION: range = (dir > 0) ? SEARCH_IN_CURRENT_PROC : SEARCH_IN_CURRENT_BUFFER;    break;
         case SEARCH_IN_CURRENT_PROC:      range = (dir > 0) ? SEARCH_IN_ALL_BUFFERS : SEARCH_IN_CURRENT_SELECTION;  break;
         case SEARCH_IN_ALL_BUFFERS:       range = (dir > 0) ? MFFIND_PROJECT_FILES  : SEARCH_IN_CURRENT_PROC;       break;
         case MFFIND_PROJECT_FILES:        range = (dir > 0) ? MFFIND_WORKSPACE_FILES : SEARCH_IN_ALL_BUFFERS;       break;
         case MFFIND_WORKSPACE_FILES:      range = (dir > 0) ? SEARCH_IN_CURRENT_BUFFER : MFFIND_PROJECT_FILES;      break;
      }

      if (_findrange._lbfind_item(range) >= 0) { // find item in list if available
         break;
      }
   }
   if (range != _findrange.p_text) {
      _findrange.p_text = range;  // on_change will do update
   }
}

void _document_search_form.ESC()
{
   ctl_close.call_event(_control ctl_close, LBUTTON_UP, "W");
}

static void _ds_set_replace_mode(bool show_replace)
{
   form_wid := p_active_form.p_window_id;
   editorctl_wid := P_USER_MINIFIND_WID();
   form_wid._showhide_controls(show_replace);
   if (show_replace) {
      // may need to toggle preserve case here
      if (!s_params.m_status) {
         old_search_flags = (ctl_preservecase.p_value) ? (old_search_flags | VSSEARCHFLAG_PRESERVE_CASE) : (old_search_flags & ~VSSEARCHFLAG_PRESERVE_CASE);
      }
      _ds_update_tooltip(P_USER_MINIFIND_WID(), _findstring.p_text, _replacestring.p_text);
   } else {
      _ds_dismiss_tooltip(editorctl_wid);
   }
   _ds_update_editor_scroll(editorctl_wid, form_wid);
}

void _togglemode.ENTER,lbutton_up,down,up()
{
   _ds_set_replace_mode(!_replaceframe.p_visible);
}

void ctl_sizegrip.lbutton_down()
{
   orig_wid := p_window_id;
   form_wid := p_active_form.p_window_id;
   editorctl_wid := P_USER_MINIFIND_WID();

   fx := form_wid.p_x; fy := form_wid.p_y;
   fw := form_wid.p_width; fh := form_wid.p_height;
   lastx := form_wid.mou_last_x('M');
   rightx := fx + fw;
   minx := 32;
   //_EditorGetScrollBarSize(editorctl_wid, auto vsbw, auto vsbh, 0);
   //right_margin := _ScrollMarkupGetWidth() + vsbw + 1;
   right_margin:=0;
   // Always make room for markup scroll bar so the
   // minifind dialog doesn't shift around when typing.
   if (_default_option(VSOPTION_VERTICAL_SCROLL_BAR) && !editorctl_wid.p_scroll_has_markup) {
      right_margin+=_ScrollMarkupGetWidth();
   }
   maxx := editorctl_wid.p_client_width - (DOCSEARCH_MINIMUM_WIDTH_PIXELS + right_margin);
   
   mou_mode(1);
   mou_release();
   editorctl_wid.mou_capture();

   se.util.MousePointerGuard mousePointerSentry(MP_DEFAULT,editorctl_wid);
   mousePointerSentry.setMousePointer(MP_SIZEHORZ);

   int x, y, dx, dw;
   event := "";
   done := false;
   do {
      event = editorctl_wid.get_event();
      switch (event) {
      case MOUSE_MOVE:
         x = editorctl_wid.mou_last_x(''); y = 0;
         if (x < minx || x > maxx) {
            continue;
         }
         //_map_xy(editorctl_wid, 0, x, y, SM_PIXEL);
         _dxy2lxy(SM_TWIP, x, y);
         dx = x - lastx; dw = rightx - dx;
         if (dx != form_wid.p_x) {
            form_wid._move_window(dx,fy,dw,fh);
         }
         break;

      case LBUTTON_UP:
      case ESC:
         done = true;
         break;
      }

   } while( !done );
   // Release the mouse from its servitude
   mou_mode(0);
   editorctl_wid.mou_release();
}

static void _showhide_controls(bool show_replace_frame)
{
   _findframe.p_visible = true;
   _replaceframe.p_visible = show_replace_frame;
   _optionsframe.p_visible = true;
   _resize_frame_heights();
   if (show_replace_frame) {
      _togglemode.p_picture = _pic_toggle_up;
   } else {
      _togglemode.p_picture = _pic_toggle_down;
   }
}

static void _init_findstring(int editorctl_wid)
{
   init_str := '';
   if (def_mfsearch_init_flags & MFSEARCH_INIT_HISTORY) {
      init_str = old_search_string;
   }
   if (editorctl_wid && editorctl_wid._isEditorCtl(false)) {
      str := "";
      if (def_mfsearch_init_flags & MFSEARCH_INIT_CURWORD) {
         str = editorctl_wid.cur_word(auto junk, '', true);
      }
      if ((def_mfsearch_init_flags & MFSEARCH_INIT_SELECTION) && editorctl_wid.select_active2()) {
         mark_locked := 0;
         if (_select_type('', 'S') == 'C') {
            mark_locked = 1;
            _select_type('', 'S', 'E');
         }

         editorctl_wid.filter_init();
         editorctl_wid.filter_get_string(str, 1024);
         editorctl_wid.filter_restore_pos();

         if (mark_locked) {
            _select_type('', 'S','C');
         }
      }
      if (str != '') {
         if ((def_mfsearch_init_flags & MFSEARCH_INIT_AUTO_ESCAPE_REGEX) && ctl_regex.p_value) {
            options := 'R';
            re_flags := P_USER_MINIFIND_RE();
            if (re_flags & VSSEARCHFLAG_PERLRE) {
               options = 'L';
            } else if (re_flags & VSSEARCHFLAG_VIMRE) {
               options = '~';
            } else if (re_flags & VSSEARCHFLAG_WILDCARDRE) {
               options = '&';
            } else {
               options = 'R';
            }
            str = _escape_re_chars(str, options);
         }
         init_str = str;
      }
   }
   _findstring._refresh_scroll();
   _findstring._set_focus();
   _findstring._show_textbox_error_color(false);

   if (init_str != '') {
      index := _findstring._lbfind_item(init_str);
      if (index < 0) {
         _findstring._lbtop(); _findstring._lbup();
         _findstring._lbadd_item(init_str);
         _findstring._lbselect_line();
      } else {
         if (index > 0) {
            _findstring._lbtop(); _findstring._lbup();
         } else {
            _findstring._lbtop();
         }
      }
      _findstring.p_text = init_str;
   }
   _findstring.p_sel_start = 1;
   _findstring.p_sel_length = _findstring.p_text._length();
   _replacestring.p_text = old_replace_string;
}

static void _ds_reset_marks()
{
   if (s_params.m_orig_mark >= 0) {
      _free_selection(s_params.m_orig_mark);
      s_params.m_orig_mark = -1;
   }
   if (s_params.m_search_mark >= 0) {
      _free_selection(s_params.m_search_mark);
      s_params.m_search_mark = -1;
   }
   if (s_params.m_match_mark >= 0) {
      _free_selection(s_params.m_match_mark);
      s_params.m_match_mark = -1;
   }
   if (s_params.m_proc_mark >= 0) {
      _free_selection(s_params.m_proc_mark);
      s_params.m_proc_mark = -1;
   }
   if (s_params.m_start_mark >= 0) {
      _free_selection(s_params.m_start_mark);
      s_params.m_start_mark = -1;
   }
   s_params.m_start_wrap = false;
}

static void _ds_reset_start_mark()
{
   if (s_params.m_start_mark >= 0) {
      _free_selection(s_params.m_start_mark);
      s_params.m_start_mark = -1;
   }
   s_params.m_start_wrap = false;
}

static void _show_textbox_error_color(bool show_error)
{
   p_forecolor = (show_error) ? 0x00FFFFFF : 0x80000008;
   p_backcolor = (show_error) ? 0x006666FF : 0x80000005;
}

// Since the controls are inside a frame we need to do some
// hocky code to get better order of the controls.
void _findstring.TAB() {
   if(_replaceframe.p_visible) {
      _replacestring._set_focus();
      return;
   }
   call_event(defeventtab _ainh_dlg_manager,TAB,'E');
}
void _replacestring.TAB() {
   p_window_id=_findstring;
   call_event(defeventtab _ainh_dlg_manager,TAB,'E');
}
void _replacestring.S_TAB() {
   _findstring._set_focus();
}
void ctl_findnext_menu.TAB() {
   if(_replaceframe.p_visible) {
      if (ctl_replacere_menu.p_visible) {
         ctl_replacere_menu._set_focus();
      } else {
         ctl_replacenext._set_focus();
      }
      return;
   }
   call_event(defeventtab _ainh_dlg_manager,TAB,'E');
}
void ctl_replacere_menu.S_TAB() {
   ctl_findnext_menu._set_focus();
}
void ctl_replacenext.S_TAB() {
   if (ctl_replacere_menu.p_visible) {
      ctl_replacere_menu._set_focus();
   } else {
      ctl_findnext_menu._set_focus();
   }
}
void ctl_findprev.S_TAB() {
   _replacestring._set_focus();
}

static void _do_gui_find()
{
   editorctl_wid := P_USER_MINIFIND_WID();
   if (s_params.m_status || !editorctl_wid._ds_on_mark_pos(s_params.m_match_mark)) {
      s_params.m_update = false;
      s_params.m_status = -1;
      if (s_params.m_match_mark >= 0) {
         _free_selection(s_params.m_match_mark);
         s_params.m_match_mark = -1;
      }
      s_params.m_match_length = 0;
      s_params.m_match_start = 0;
      doNext(false, false, true);

   } else {
      ctl_close.call_event(_control ctl_close, LBUTTON_UP, "W");
   }
}

void _findstring.ENTER()
{
   if (def_mini_find_close_on_default) {
      replace_mode := _replaceframe.p_visible;
      if (replace_mode) {
         _do_gui_replace();
      } else {
         _do_gui_find();
      }
      return;
   }
   doNext();
}

void _findstring.on_change()
{
   if (ignore_change) {
      return;
   }
   _ds_reset_start_mark();
   editorctl_wid := P_USER_MINIFIND_WID();
   if (editorctl_wid.p_buf_size > def_gui_find_incremental_search_max_buf_ksize*1024) {
      message('Incremental search disabled: File too large');
      return;
   }
   doUpdate();
   doSearch();
}

void _findstring.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      if (P_USER_MINIFIND_FIND_LIST_REFRESH() == '') {
         _lbclear();
         _retrieve_list("_tbfind_form._findstring");
         P_USER_MINIFIND_FIND_LIST_REFRESH(1);
      }
   }
}

void ctl_close.lbutton_up()
{
   parent_wid:=p_active_form.p_parent;
   p_active_form._delete_window();
   // We could look into why delete window does set the focus for us correctly.
   // For now, just correct the focus after closing the dialog.
   parent_wid._set_focus();
}

void ctl_findnext.ENTER,lbutton_up()
{
   doNext();
}
void ctl_findprev.ENTER,lbutton_up()
{
   doNext(true);
}

static void _init_search_options_menu(int menu_handle)
{
   replace_mode := _replaceframe.p_visible;
   options := s_params.m_options;
   listreplace := s_params.m_listreplace;

   status := _menu_find(menu_handle, "docsearch_find_menu $", auto mh, auto mpos, 'M');
   if (!status) {
      if (!replace_mode) {
         _menu_delete(mh, mpos);
      } else {
         flags := MF_ENABLED;
         if (options & VSSEARCHFLAG_REPLACEHILIGHT) {
            flags |= MF_CHECKED;
         }
         _menu_set_state(mh, mpos, flags, 'P');
      }
   }
   status = _menu_find(menu_handle, "docsearch_find_menu list_replace", mh, mpos, 'M');
   if (!status) {
      if (!replace_mode) {
         _menu_delete(mh, mpos);
      } else {
         flags := MF_ENABLED;
         if (listreplace) {
            flags |= MF_CHECKED;
         }
         _menu_set_state(mh, mpos, flags, 'P');
      }
   }
   if (!replace_mode) {
      status = _menu_find(menu_handle, "docsearch_find_menu preview", mh, mpos, 'M');
      if (!status) {
         _menu_delete(mh, mpos);
      }
      status = _menu_find(menu_handle, "docsearch_find_menu replace-in-files", mh, mpos, 'M');
      if (!status) {
         _menu_delete(mh, mpos);
      }
   } else {
      status = _menu_find(menu_handle, "docsearch_find_menu find-in-files", mh, mpos, 'M');
      if (!status) {
         _menu_delete(mh, mpos);
      }
   }

   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid.select_active2()) {
      status = _menu_find(menu_handle, "docsearch_find_menu ^&", mh, mpos, 'M');
      if (!status) {
         _menu_delete(mh, mpos);
      }
   }
}

static void _init_search_results_menu(int menu_handle)
{
   int mf_flags, submenu_handle;
   status := _menu_find(menu_handle, "findall", auto mh, auto mpos, 'C');
   if (status) {
      return;
   }
   _menu_get_state(mh, mpos, mf_flags, 'P', '', submenu_handle);


   last_grep_id := _get_last_grep_buffer();
   int i;
   for (i = 0; i < last_grep_id + 1; ++i) {
      caption := 'Search<'i'>';
      if (i < 10) {
         caption :+= "\tAlt+":+i;
      }
      _menu_insert(submenu_handle, i, MF_ENABLED, caption, "docsearch_find_menu grep "i, "", "", "");
   }

   status = _menu_find(submenu_handle, "docsearch_find_menu mfflag ab", mh, mpos, 'M');
   if (!status) {
      caption := "List lines before/after (";
      caption :+= (s_params.m_grep_before_lines == 0) ? "0" : "-"s_params.m_grep_before_lines;
      caption :+= ",";
      caption :+= (s_params.m_grep_after_lines == 0) ? "0" : "+"s_params.m_grep_after_lines;
      caption :+= ")";

      _menu_get_state(mh, mpos, mf_flags, "P");
      _menu_set_state(mh, mpos, mf_flags, "P", caption);
   }

   if (s_params.m_grep_before_lines > 0 || s_params.m_grep_after_lines > 0) {
      // absub
      status = _menu_find(submenu_handle, "absub", mh, mpos, 'C');
      if (!status) {
         _menu_get_state(mh, mpos, mf_flags, 'P', '', submenu_handle);
         grep_ab := s_params.m_grep_before_lines:+",":+s_params.m_grep_after_lines; 
         add_pos := -1;
         Nofitems := _menu_info(submenu_handle);
         for (i = 0; i < Nofitems; ++i) {
            _menu_get_state(submenu_handle, i, auto flags, "P", auto caption, auto command);
            if (command :== "") {
               add_pos = i;
               break; // got to keep'em separated
            }
            parse command with "docsearch_find_menu grepab" auto val;
            if (val :== "") {
               break;
            }
            if (val == grep_ab) {
               break;
            }
         }

         if (add_pos >= 0) {
            caption := "-":+s_params.m_grep_before_lines:+",+":+s_params.m_grep_after_lines;
            _menu_insert(submenu_handle, add_pos, MF_ENABLED, caption, "docsearch_find_menu grepab ":+grep_ab, "", "", "");
         }
      }
   }
}

static void _init_regex_menu(int menu_handle)
{
   regex_value := ctl_regex.p_value;
   re_search_syntax := P_USER_MINIFIND_RE();

   status := _menu_find(menu_handle, 'resub', auto mh, auto mpos, 'C');
   if (status) {
      return;
   }
   if (!regex_value) {
      _menu_delete(mh, mpos);
      return;
   }

   _menu_get_state(mh, mpos, 0, "P", "", auto mc, "", "", "");
   if (!isinteger(mc)) {
      return;
   }
  
   re_index := 0;
   if (re_search_syntax & VSSEARCHFLAG_WILDCARDRE) {
      re_index = find_index("_wildcard_re_menu", oi2type(OI_MENU));
   } else {
      re_index = find_index("_default_re_menu", oi2type(OI_MENU));
   }
   if (!re_index) {
      return;
   }

   int sub_menu_handle = (int)mc;
   int child = re_index.p_child;
   if (child) {
      int first_child = child;
      for (;;) {
         if (child.p_object == OI_MENU) {
            _menu_insert_submenu(sub_menu_handle,-1,child,child.p_caption,child.p_categories,child.p_help,child.p_message);
         } else {
            _menu_insert(sub_menu_handle,-1,0,
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

static void _init_search_expressions_menu(int menu_handle)
{
   status := _menu_find(menu_handle, 'sexpr', auto mh, auto mpos, 'C');
   if (status) {
      return;
   }
   _menu_get_state(mh, mpos, 0, "P", "", auto mc, "", "", "");
   _str array[];
   _get_saved_search_names(array);
   int submenu_handle = (int)mc;
   if (array._length() <= 0) {
      _menu_insert(submenu_handle, 0, MF_GRAYED, "None", "", "", "", "");
   } else {
      int i;
      for (i = 0; i < array._length(); ++i) {
         menu_cmd := 'docsearch_find_menu se ':+ array[i];
         _menu_insert(submenu_handle, i, MF_ENABLED, array[i], menu_cmd, "", "", "");
      }
   }
}

static int _get_search_flags()
{
   search_flags := 0;
   search_flags |= ctl_matchcase.p_value ? 0: VSSEARCHFLAG_IGNORECASE;
   search_flags |= ctl_matchword.p_value ? VSSEARCHFLAG_WORD : 0;
   if (ctl_regex.p_value) {
      re_flags := P_USER_MINIFIND_RE();
      if (re_flags & VSSEARCHFLAG_PERLRE) {
         search_flags |= VSSEARCHFLAG_PERLRE;
      } else if (re_flags & VSSEARCHFLAG_VIMRE) {
         search_flags |= VSSEARCHFLAG_VIMRE;
      } else if (re_flags & VSSEARCHFLAG_WILDCARDRE) {
         search_flags |= VSSEARCHFLAG_WILDCARDRE;
      } else {
         search_flags |= VSSEARCHFLAG_RE;
      }
   }
   search_flags |= ctl_regex.p_value ? P_USER_MINIFIND_RE() : 0;


   search_flags |= s_params.m_options;
   return(search_flags);
}

static void _init_search_flags(int search_flags)
{
   ctl_matchcase.p_value = (search_flags & VSSEARCHFLAG_IGNORECASE) ? 0 : 1;
   ctl_matchword.p_value = (search_flags & VSSEARCHFLAG_WORD) ? 1 : 0;
   re_flags := (search_flags & (VSSEARCHFLAG_RE|VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_VIMRE|VSSEARCHFLAG_WILDCARDRE));
   ctl_regex.p_value = (re_flags) ? 1 : 0;
   if (re_flags) {
      if (re_flags & VSSEARCHFLAG_PERLRE) {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_PERLRE);
      } else if (re_flags & VSSEARCHFLAG_VIMRE) {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_VIMRE);
      } else if (re_flags & VSSEARCHFLAG_WILDCARDRE) {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_WILDCARDRE);
      } else {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_RE);
      }
   }
   ctl_preservecase.p_value = (search_flags & VSSEARCHFLAG_PRESERVE_CASE) ? 1 : 0;

   s_params.m_options = search_flags & (VSSEARCHFLAG_REVERSE|VSSEARCHFLAG_HIDDEN_TEXT|VSSEARCHFLAG_REPLACEHILIGHT|VSSEARCHFLAG_POSITIONONLASTCHAR);
   if (search_flags & VSSEARCHFLAG_WRAP) {
      s_params.m_options |= VSSEARCHFLAG_WRAP;
   }
   if (search_flags & VSSEARCHFLAG_PROMPT_WRAP) {
      s_params.m_options |= VSSEARCHFLAG_PROMPT_WRAP;
   }
}

static _str _get_misc_search_opts()
{
   opts := "mini";

   option := s_params.m_options;
   if (s_params.m_options & VSSEARCHFLAG_WRAP) {
      if (s_params.m_options & VSSEARCHFLAG_PROMPT_WRAP) {
         _maybe_append(opts, ";"); strappend(opts, "_findwrap?");
      } else {
         _maybe_append(opts, ";"); strappend(opts, "_findwrap");
      }
   }
   if (s_params.m_options & VSSEARCHFLAG_REVERSE) {
      _maybe_append(opts, ";"); strappend(opts, "_findback");
   }
   if (s_params.m_options & VSSEARCHFLAG_HIDDEN_TEXT) {
      _maybe_append(opts, ";"); strappend(opts, "_findhidden");
   }
   if (s_params.m_options & VSSEARCHFLAG_POSITIONONLASTCHAR) {
      _maybe_append(opts, ";"); strappend(opts, '_findcursorend');
   }
   if (s_params.m_options & VSSEARCHFLAG_REPLACEHILIGHT) {
      _maybe_append(opts, ";"); strappend(opts, '_replacehilite');
   }
   if (s_params.m_listreplace) {
      _maybe_append(opts, ";"); strappend(opts, "_replacelist");
   }
   if (s_params.m_grep_ab) {
      _maybe_append(opts, ";"); strappend(opts, "_mfgrepab");
   }
   if ((s_params.m_grep_before_lines > 0) || (s_params.m_grep_after_lines > 0)) {
      lines := (s_params.m_grep_before_lines >= 0) ? s_params.m_grep_before_lines : "0";
      lines :+= ","; 
      lines :+= (s_params.m_grep_after_lines >= 0) ? s_params.m_grep_after_lines : "0";
      _maybe_append(opts, ";"); strappend(opts, "_mfgrepablines="lines);
   }
   if (_findcoloroptions.p_text != '') {
      _maybe_append(opts, ";"); strappend(opts, '_findcoloroptions='_findcoloroptions.p_text);
   }
   _maybe_append(opts, ";"); strappend(opts, '_mfgrepid='s_params.m_grep_id);
   return opts;
}

static void _init_misc_search_opts(_str options)
{
   _str opt, rest, v;
   parse options with opt ";" rest;

   if (opt == 'mini') {
      s_params.m_listreplace = false;
      s_params.m_grep_ab = false;

   } else if (opt == 'tool') {
      s_params.m_options &= ~(VSSEARCHFLAG_WRAP|VSSEARCHFLAG_PROMPT_WRAP|VSSEARCHFLAG_REVERSE|VSSEARCHFLAG_HIDDEN_TEXT|VSSEARCHFLAG_POSITIONONLASTCHAR|VSSEARCHFLAG_PRESERVE_CASE|VSSEARCHFLAG_REPLACEHILIGHT);
      s_params.m_listreplace = false;
      s_params.m_grep_ab = false;

      ctl_preservecase.p_value = 0;
   }

   while (opt != '') {
      switch (opt) {
      case '_findwrap?':
         s_params.m_options |= (VSSEARCHFLAG_WRAP|VSSEARCHFLAG_PROMPT_WRAP);
         break;
      case '_findwrap':
         s_params.m_options |= VSSEARCHFLAG_WRAP;
         break;
      case '_findcursorend':
         s_params.m_options |= VSSEARCHFLAG_POSITIONONLASTCHAR;
         break;
      case '_findback':
         s_params.m_options |= VSSEARCHFLAG_REVERSE;
         break;
      case '_findhidden':
         s_params.m_options |= VSSEARCHFLAG_HIDDEN_TEXT;
         break;

      case '_replacekeepcase':
         ctl_preservecase.p_value = 1;
         ctl_matchcase.p_value = 0;
         break;

      case '_replacehilite':
         s_params.m_options |= VSSEARCHFLAG_REPLACEHILIGHT;
         break;
      case '_replaceleaveopen':
         // not used here
         break;
      case '_replacelist':
         s_params.m_listreplace = true;
         break;

      case '_mfgrepab':
         s_params.m_grep_ab = true;
         break;

      default:
         if (beginsWith(opt, '_mfgrepablines=')) {
            parse opt with '_mfgrepablines=' v;
            if (v != '') {
               _ds_set_grep_ab_lines(v, false);
            }
         } else if (beginsWith(opt, '_findcoloroptions=')) {
            parse opt with '_findcoloroptions=' v;
            if (v != '') {
               _findcoloroptions.p_text = v;
            }
         } else if (beginsWith(opt, '_mfgrepid=')) {
            parse opt with '_mfgrepid=' v;
            if (v != '') {
               s_params.m_grep_id = (int)v;
            }
         }
         break;
      }
      parse rest with opt ";" rest;
   }
   _update_button_styles();
}

static void _ds_save_search_expression()
{
   replace_mode := _replaceframe.p_visible;
   SearchExprOptions expr;
   expr.m_search_string = _findstring.p_text;
   expr.m_replace_string = (replace_mode) ? _replacestring.p_text : "";
   expr.m_replace_mode = replace_mode;
   expr.m_search_flags = _get_search_flags();
   expr.m_misc_options = _get_misc_search_opts();
   expr.m_colors = (ctl_matchcolor.p_value) ? _findcoloroptions.p_text : "";
   expr.m_multifile = false;
   expr.m_files = _findrange.p_text;
   expr.m_file_types = "";
   expr.m_file_excludes = "";
   expr.m_grep_id = s_params.m_grep_id;
   expr.m_mfflags = s_params.m_mfflags;

   _save_search_expression(expr);
}

static void _ds_apply_search_expression(_str name)
{
   SearchExprOptions expr;
   status := _retrieve_saved_search(name, expr);
   if (status) {
      return;
   }

   ignore_change = true;
   _findstring.p_text = expr.m_search_string;
   _findstring.p_sel_start = 1;
   _findstring._refresh_scroll();
   _findstring._set_sel(1, length(_findstring.p_text)+1);
   if (expr.m_replace_mode || expr.m_replace_string != '') {
      _replacestring.p_text = expr.m_replace_string;
   }
   _init_search_flags(expr.m_search_flags);
   // ignoring misc
   if (!expr.m_multifile) {
      editorctl_wid := P_USER_MINIFIND_WID();
      if (expr.m_files != '') {
         range := _ds_get_search_range(expr.m_files);
         _init_search_range(editorctl_wid, range);
      }
   }
   if (expr.m_colors != '') {
      ctl_matchcolor.p_value = 1;
      _findcoloroptions.p_text = expr.m_colors;
   } else {
      ctl_matchcolor.p_value = 0;
   }
   if (expr.m_grep_id != -1) {
      s_params.m_grep_id = s_params.m_grep_id;
      if (expr.m_grep_id >= 0) {
         _update_last_grep_buffer(s_params.m_grep_id);
      }
   }
   if (expr.m_mfflags >= 0) {
      s_params.m_mfflags = expr.m_mfflags & (MFFIND_MDICHILD|MFFIND_APPEND|MFFIND_FILESONLY|MFFIND_SINGLELINE|MFFIND_MATCHONLY|MFFIND_LIST_CURRENT_CONTEXT);
   }
   _init_misc_search_opts(expr.m_misc_options);
   _update_button_styles();
   ignore_change = false;
   _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
}

void ctl_findnext_menu.ENTER,lbutton_up,down,up()
{
   form_wid := p_active_form.p_window_id;

   int index = find_index("_docsearchfind_menu", oi2type(OI_MENU));
   int menu_handle = form_wid._menu_load(index, 'P');
   int x = p_x + p_width;
   y := p_y;
   _lxy2dxy(SM_TWIP, x, y);
   _map_xy(p_xyparent, 0, x, y);
   _init_search_options_menu(menu_handle);
   _init_search_results_menu(menu_handle);
   
   _init_regex_menu(menu_handle);
   _init_search_expressions_menu(menu_handle);
   int status = _menu_show(menu_handle, VPM_LEFTALIGN | VPM_RIGHTBUTTON, x, y);
   _menu_destroy(menu_handle);
}

static int _ds_get_grep_buffer_id(_str grep_arg)
{
   grep_id := 0;
   if (isinteger(grep_arg)) {
      if (grep_arg == GREP_AUTO_INCREMENT) {
         grep_id = GREP_AUTO_INCREMENT;
      } else if (grep_arg == GREP_NEW_WINDOW) {
         grep_id = GREP_NEW_WINDOW;
      } else {
         grep_id = (int)grep_arg;
      }
      return grep_id;
   } else if (lowcase(grep_arg) == 'new') {
      grep_id = add_new_grep_buffer();

   } else if (lowcase(grep_arg) == 'auto') {
      grep_id = GREP_AUTO_INCREMENT;
   }
   return(grep_id);
}

static int _ds_set_grep_buffer_id(int grep_id)
{
   if (grep_id < 0) {
      if (grep_id == GREP_AUTO_INCREMENT) {
         grep_id = auto_increment_grep_buffer();
         s_params.m_grep_id = GREP_AUTO_INCREMENT;

      } else if (grep_id == GREP_NEW_WINDOW) {
         grep_id = add_new_grep_buffer();
         s_params.m_grep_id = grep_id;
      }
      if (grep_id < 0) {
         if (s_params.m_grep_id == GREP_AUTO_INCREMENT) {
            grep_id = auto_increment_grep_buffer();

         } else if (s_params.m_grep_id == GREP_NEW_WINDOW) {
            grep_id = add_new_grep_buffer();
            s_params.m_grep_id = grep_id;

         } else {
            grep_id = s_params.m_grep_id;
         }
      }
      
   } else {
      s_params.m_grep_id = grep_id;
   }
   return(grep_id);
}

static void _ds_set_grep_ab_lines(_str grep_ab='', bool update_flag=true)
{
   result := grep_ab;
   if (result == '') {
      lines := (s_params.m_grep_before_lines >= 0) ? s_params.m_grep_before_lines : "0";
      lines :+= ","; 
      lines :+= (s_params.m_grep_after_lines >= 0) ? s_params.m_grep_after_lines : "0";

      status := textBoxDialog("Set Search Results Before/After Lines", 0, 0, "", "", "", 
                              "Before/After lines (before, after):":+lines);
      if (status < 0) {
         return;
      }
      result = strip(_param1);
   }


   if (result == '') {
      return;
   }
   if (isinteger(result) && ((int)result >= 0)) {
      // set both
      //_mfgrepab.p_text = result','result;
      s_params.m_grep_before_lines = s_params.m_grep_after_lines = (int)result;

   } else {
      parse result with auto before "," auto after;
      if ((before != '') && (isinteger(before)) &&
          (after != '') && (isinteger(after))) {
         
         b := (int)before;
         if (b < 0) { // let user set -N for before line
            b = -b;
         }
         a := (int)after;
         if (a < 0) {
            _message_box("After value must be positive integer.");
            return;
         }
         s_params.m_grep_before_lines = b;
         s_params.m_grep_after_lines = a;

      } else {
         // ERR'd
         _message_box("Values must be valid positive integers.");
      }
   }
   
   if (update_flag && !s_params.m_grep_ab) {
      // enable if options applied
      if (s_params.m_grep_before_lines > 0 || s_params.m_grep_after_lines > 0) {
         s_params.m_grep_ab = true;
      }
   }
}

int _OnUpdate_docsearch_find_menu(CMDUI cmdui, int target_wid, _str command)
{
   _str cmd, action, extra;
   parse command with cmd action extra;
   replace_mode := _replaceframe.p_visible;
   re_flags := (target_wid.ctl_regex.p_value) ? target_wid.P_USER_MINIFIND_RE() : 0;
   options := s_params.m_options;
   listreplace := s_params.m_listreplace;
   mfflags := s_params.m_mfflags;
   search_range := target_wid._ds_get_search_range();
   isearch := target_wid.P_USER_MINIFIND_ISEARCH();
   editorctl_wid := target_wid.P_USER_MINIFIND_WID();
   isearch_enabled := (editorctl_wid != 0) && (editorctl_wid.p_buf_size <= def_gui_find_incremental_search_max_buf_ksize*1024);
   grep_ab := s_params.m_grep_before_lines:+",":+s_params.m_grep_after_lines;

   switch (lowcase(action)) {
   case 'p':
      return((options & VSSEARCHFLAG_WRAP) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
   case 'p?':
      if (options & VSSEARCHFLAG_WRAP) {
         return((options & VSSEARCHFLAG_PROMPT_WRAP) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
      }
      return(MF_GRAYED);
   case '-':
      return((options & VSSEARCHFLAG_REVERSE) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
   case 'h':
      return((options & VSSEARCHFLAG_HIDDEN_TEXT) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
   case '>':
      return((options & VSSEARCHFLAG_POSITIONONLASTCHAR) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
   case '$':
      return((options & VSSEARCHFLAG_REPLACEHILIGHT) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
   case 'list_replace':
      return((listreplace) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
   case '|':
      if (search_range == VSSEARCHRANGE_ALL_BUFFERS || search_range == VSSEARCHRANGE_PROJECT || search_range == VSSEARCHRANGE_WORKSPACE) {
         return(MF_GRAYED);
      }
      return(MF_ENABLED);
   case '#':
   case 'm':
      if (search_range == VSSEARCHRANGE_PROJECT || search_range == VSSEARCHRANGE_WORKSPACE) {
         return(MF_GRAYED);
      }
      return(MF_ENABLED);

   case 'reperl':
      return((re_flags & VSSEARCHFLAG_PERLRE) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
   case 'revim':
      return((re_flags & VSSEARCHFLAG_VIMRE) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
   case 'rese':
      return((re_flags & VSSEARCHFLAG_RE) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
   case 'rewc':
      return((re_flags & VSSEARCHFLAG_WILDCARDRE) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);

   case 'mfflag':
      switch(extra) {
      case 'e':
         return((mfflags & MFFIND_MDICHILD) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
      case 'a':
         return((mfflags & MFFIND_APPEND) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
      case 'fo':
         return((mfflags & MFFIND_FILESONLY) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
      case 'o':
         if (mfflags & (MFFIND_FILESONLY|MFFIND_MATCHONLY)) {
            return((mfflags & MFFIND_SINGLELINE) ? MF_GRAYED|MF_CHECKED : MF_GRAYED);
         }
         return((mfflags & MFFIND_SINGLELINE) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
      case 'm':
         if (mfflags & MFFIND_FILESONLY) {
            return((mfflags & MFFIND_MATCHONLY) ? MF_GRAYED|MF_CHECKED : MF_GRAYED);
         }
         if (replace_mode) {
            return((mfflags & MFFIND_MATCHONLY) ? MF_GRAYED|MF_CHECKED : MF_GRAYED);
         } 
         return((mfflags & MFFIND_MATCHONLY) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
      case 'c':
         if (mfflags & MFFIND_FILESONLY) {
            return((mfflags & MFFIND_LIST_CURRENT_CONTEXT) ? MF_GRAYED|MF_CHECKED : MF_GRAYED);
         }
         return((mfflags & MFFIND_LIST_CURRENT_CONTEXT) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);

      case 'ab':
          if (mfflags & (MFFIND_FILESONLY|MFFIND_MATCHONLY)) {
             return((s_params.m_grep_ab) ? MF_GRAYED|MF_CHECKED : MF_GRAYED);
         }
         return((s_params.m_grep_ab) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
      }
      return(MF_ENABLED);
  
   case 'grepab':
      if (!s_params.m_grep_ab) {
         return (MF_ENABLED);
      }
      return (extra == grep_ab) ? (MF_ENABLED|MF_CHECKED) : (MF_ENABLED);

   case 'toggle_hilite':
      return((def_search_incremental_highlight) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
   case 'toggle_isearch':
      return((isearch_enabled ? MF_ENABLED : MF_GRAYED) | (isearch ? MF_CHECKED : MF_UNCHECKED));

   default:
      return(MF_ENABLED);
   }
}

_command void docsearch_find_menu(_str cmdline = '') name_info(',' VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _macro_delete_line();
   form_wid := p_active_form.p_window_id;
   if (!form_wid) {
      return;
   }
   replace_mode := _replaceframe.p_visible;
   search_string := _findstring.p_text;
   replace_string := (replace_mode) ? _replacestring.p_text : '';
   search_range := _ds_get_search_range();
   search_options := _ds_get_search_options();
   search_colors := (ctl_matchcolor.p_value) ? _findcoloroptions.p_text : "";
   mfflags := s_params.m_mfflags;
   misc_options := _get_misc_search_opts();
   editorctl_wid := P_USER_MINIFIND_WID();
   isearch := P_USER_MINIFIND_ISEARCH();
   
   parse cmdline with auto cmd auto opt;
   switch (lowcase(cmd)) {
   case "next":
      doNext();
      break;

   case "prev":
      doNext(true);
      break;

   case "preview":
      doReplace(true, true);
      break;

   case "p":
      s_params.m_options = s_params.m_options ^ VSSEARCHFLAG_WRAP; 
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      break;

   case "p?":
      if (s_params.m_options & VSSEARCHFLAG_WRAP) {
         if (s_params.m_options & VSSEARCHFLAG_PROMPT_WRAP) {
            s_params.m_options &= ~(VSSEARCHFLAG_PROMPT_WRAP);
         } else {
            s_params.m_options |= (VSSEARCHFLAG_PROMPT_WRAP);
         }
      } else {
         s_params.m_options &= ~(VSSEARCHFLAG_PROMPT_WRAP);
      }
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      break;

   case "-":
      s_params.m_options = s_params.m_options ^ VSSEARCHFLAG_REVERSE; 
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      break;

   case "h":
      s_params.m_options = s_params.m_options ^ VSSEARCHFLAG_HIDDEN_TEXT; 
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      break;

   case ">":
      s_params.m_options = s_params.m_options ^ VSSEARCHFLAG_POSITIONONLASTCHAR; 
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      break;

   // Replace flags
   case "$":
      s_params.m_options = s_params.m_options ^ VSSEARCHFLAG_REPLACEHILIGHT;
      if (!(s_params.m_options & VSSEARCHFLAG_REPLACEHILIGHT)) {
         editorctl_wid.clear_highlights();
      }
      break;

   case "list_replace":
      s_params.m_listreplace = !s_params.m_listreplace; 
      break;

   case "grep":
      grep_id := _ds_get_grep_buffer_id(opt);
      doListAll(grep_id);
      break;

   case "mfflag":
      switch (opt) {
      case "e":
         s_params.m_mfflags = s_params.m_mfflags ^ MFFIND_MDICHILD; 
         break;
      case "a":
         s_params.m_mfflags = s_params.m_mfflags ^ MFFIND_APPEND;
         break;
      case "fo":
         s_params.m_mfflags = s_params.m_mfflags ^ MFFIND_FILESONLY;
         break;
      case "o":
         s_params.m_mfflags = s_params.m_mfflags ^ MFFIND_SINGLELINE;
         break;
      case "m":
         s_params.m_mfflags = s_params.m_mfflags ^ MFFIND_MATCHONLY;
         break;
      case "c":
         s_params.m_mfflags = s_params.m_mfflags ^ MFFIND_LIST_CURRENT_CONTEXT;
         break;
      case "ab":
         s_params.m_grep_ab  = !s_params.m_grep_ab; 
         break;
      }
      break;

   case "grepab":
      _ds_set_grep_ab_lines(opt);
      break;

   case "|":
      doMultiSelect();
      break;

   case "m":
      doBookmarks();
      break;

   case "#":
      doHighlight();
      break;

   case "^":
      doCurrentWordAtCursor();
      break;

   case "^+":
      doWordCompletion();
      break;

   case "^&":
      doGetCurrentSelection();
      break;

   // Search expressions
   case "se":
      _ds_apply_search_expression(opt);
      break;
   case "se_save":
      _ds_save_search_expression();
      break;
   case "se_remove":
      _remove_saved_search();
      break;

   // Regular expressions
   case "reperl":
      P_USER_MINIFIND_RE(VSSEARCHFLAG_PERLRE);
      if (!form_wid.ctl_regex.p_value) {
         form_wid.ctl_regex.p_value = 1;
         form_wid.ctl_regex.p_style = PSPIC_BUTTON;
      }
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      
      break;

   case "revim":
      P_USER_MINIFIND_RE(VSSEARCHFLAG_VIMRE);
      if (!form_wid.ctl_regex.p_value) {
         form_wid.ctl_regex.p_value = 1;
         form_wid.ctl_regex.p_style = PSPIC_BUTTON;
      }
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      
      break;

   case "rese":
      P_USER_MINIFIND_RE(VSSEARCHFLAG_RE);
      if (!form_wid.ctl_regex.p_value) {
         form_wid.ctl_regex.p_value = 1;
         form_wid.ctl_regex.p_style = PSPIC_BUTTON;
      }
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      break;

   case "rewc":
      P_USER_MINIFIND_RE(VSSEARCHFLAG_WILDCARDRE);
      if (!form_wid.ctl_regex.p_value) {
         form_wid.ctl_regex.p_value = 1;
         form_wid.ctl_regex.p_style = PSPIC_BUTTON;
      }
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      break;

   // color coding search
   case "co":
      _ds_update_color_search(opt);
      break;

   case "cc":
      _ds_configure_color_search();
      break;

   case "toggle_hilite":
      def_search_incremental_highlight = (def_search_incremental_highlight) ? 0 : 1;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      break;

   case "toggle_isearch":
      P_USER_MINIFIND_ISEARCH(((isearch) ? 0 : 1));
      if (!P_USER_MINIFIND_ISEARCH()) {
         _ds_reset_match_marker();
         
      } else {
         _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      }
      break;

   case "find-in-files":
      find_in_files();
      tool_find_update_options(search_string, replace_string, search_options, -1, mfflags, misc_options, false);
      return;

   case "replace-in-files":
      replace_in_files();
      tool_find_update_options(search_string, replace_string, search_options, -1, mfflags, misc_options, false);
      break;

   case "keep":
      doKeepSearch();
      break;

   case "delete":
      doDeleteSearch();
      break;
   }
}

void ctl_replacere_menu.ENTER,lbutton_up,down,up()
{
   form_wid := p_active_form.p_window_id;

   int index = find_index("_rerep_menu", oi2type(OI_MENU));
   int menu_handle = form_wid._menu_load(index, 'P');
   int x = p_x + p_width;
   y := p_y;
   _lxy2dxy(SM_TWIP, x, y);
   _map_xy(p_xyparent, 0, x, y);
   int status = _menu_show(menu_handle, VPM_LEFTALIGN | VPM_RIGHTBUTTON, x, y);
   _menu_destroy(menu_handle);
}

static void _ds_update_tooltip(int editorctl_wid, _str search_string, _str replace_string)
{
   if (def_disable_replace_tooltip || search_string :== '' || replace_string :== '') {
      _ds_dismiss_tooltip(editorctl_wid);
      return;
   }
   if (s_params.m_status) {
      _ds_dismiss_tooltip(editorctl_wid);
      return;
   }
   if (s_params.m_lastModified != editorctl_wid.p_LastModified) {
      _ds_dismiss_tooltip(editorctl_wid);
      return;
   }

   get_window_id(auto orig_wid);
   activate_window(editorctl_wid);
   if (s_params.m_match_mark > 0) {
      if (!_ds_on_mark_pos(s_params.m_match_mark)) {
         _ds_dismiss_tooltip(editorctl_wid);
         activate_window(orig_wid);
         return;
      }

      restore_search(old_search_string, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
      save_pos(auto p);
      //_begin_select(s_params.m_match_mark);
      goto_point(s_params.m_match_start);
      x := p_cursor_x;
      y := p_cursor_y + p_font_height;

      //say('update_tooltip:'p_line','p_col','x','y);
      _map_xy(p_window_id, 0, x, y);
      new_text := get_replace_text(replace_string);
      if (!rc) {
         new_text = expand_tabs(new_text);
         _bbhelp('', p_window_id, x, y, new_text,
                 p_font_name,_StrFontSize2PointSizeX10(p_font_size),0,
                 _rgb(255,255,255), _rgb(255,0,0),0,1);
         restore_pos(p);
         s_params.m_tooltip = true;
         s_params.m_scroll_info = p_scroll_left_edge' '_scroll_page();
      } else {
         _ds_dismiss_tooltip(editorctl_wid);
      }

   } else {
      _ds_dismiss_tooltip(editorctl_wid);
   }
   activate_window(orig_wid);
}

void _replacestring.on_change()
{
   if (ignore_change) {
      return;
   }
   _ds_update_tooltip(P_USER_MINIFIND_WID(), _findstring.p_text, _replacestring.p_text);
}

void _replacestring.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      if (P_USER_MINIFIND_REPLACE_LIST_REFRESH() == '') {
         _lbclear();
         _retrieve_list("_tbfind_form._replacestring");
         P_USER_MINIFIND_REPLACE_LIST_REFRESH(1);
      }
   }
}

static void _do_gui_replace()
{
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      return;
   }

   search_string := _findstring.p_text;
   if (search_string :== '') {
      return;
   }
   replace_string := _replacestring.p_text;
   search_options := _ds_get_search_options();
   search_range := _ds_get_search_range();
   show_results := s_params.m_listreplace;
   show_highlights := (pos('$', search_options) != 0);
   grep_id := _ds_set_grep_buffer_id(s_params.m_grep_id);
   ctl_close.call_event(_control ctl_close, LBUTTON_UP, "W");

   activate_window(editorctl_wid);
   _ds_begin_mark(search_options, search_range, auto mark_info);
   replace_buffer_text(search_string, search_options, replace_string, search_range, false, show_highlights, show_results, s_params.m_mfflags, grep_id);
   if (search_range == VSSEARCHRANGE_CURRENT_PROC) {
      _deselect();   
      s_params.m_proc_mark = -1; // mark already deleted
   }
   set_find_next_msg("Find", search_string, search_options, search_range);
}

void _replacestring.ENTER()
{
   if (def_mini_find_close_on_default) {
      _do_gui_replace();
      return;
   }
   ctl_replacenext.call_event(_control ctl_replacenext, LBUTTON_UP, "W");
}

void ctl_replacenext.ENTER,lbutton_up()
{
   doReplace();
}

void ctl_replaceall.ENTER,lbutton_up()
{
   doReplace(true);
}

void ctl_preservecase.ENTER,lbutton_up()
{
   p_value = (p_value) ? 0 : 1;
   p_style = (p_value) ? PSPIC_BUTTON : PSPIC_FLAT_BUTTON;
   update_find := false;
   if (p_value) {
      ctl_matchcase.p_value = 0;
      ctl_matchcase.p_style = (ctl_matchcase.p_value) ? PSPIC_BUTTON : PSPIC_FLAT_BUTTON;
      update_find = true;
   }
   if (!s_params.m_status) {
      if (update_find) {
         _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
      } else {
         old_search_flags = (ctl_preservecase.p_value) ? (old_search_flags | VSSEARCHFLAG_PRESERVE_CASE) : (old_search_flags & ~VSSEARCHFLAG_PRESERVE_CASE);
      }
      _replacestring.call_event(CHANGE_OTHER, _control _replacestring, ON_CHANGE, "W");
   }
}

void ctl_matchcase.ENTER,lbutton_up()
{
   p_value = (p_value) ? 0 : 1;
   p_style = (p_value) ? PSPIC_BUTTON : PSPIC_FLAT_BUTTON;
   update_replace := false;
   if (p_value && ctl_preservecase.p_visible) {
      ctl_preservecase.p_value = 0;
      ctl_preservecase.p_style = (ctl_preservecase.p_value) ? PSPIC_BUTTON : PSPIC_FLAT_BUTTON;
      update_replace = true;
   }
   _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
   if (update_replace) {
      _replacestring.call_event(CHANGE_OTHER, _control _replacestring, ON_CHANGE, "W");
   }
}

void ctl_matchword.ENTER,lbutton_up()
{
   p_value = (p_value) ? 0 : 1;
   p_style = (p_value) ? PSPIC_BUTTON : PSPIC_FLAT_BUTTON;
   _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
}

void ctl_regex.ENTER,lbutton_up()
{
   p_value = (p_value) ? 0 : 1;
   p_style = (p_value) ? PSPIC_BUTTON : PSPIC_FLAT_BUTTON;
   _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
}

void ctl_regex_menu.ENTER,lbutton_up,down,up()
{
   form_wid := p_active_form.p_window_id;

   int index = find_index("_docsearchre_menu", oi2type(OI_MENU));
   int menu_handle = form_wid._menu_load(index, 'P');
   int x = p_x + p_width;
   y := p_y;
   _lxy2dxy(SM_TWIP, x, y);
   _map_xy(p_xyparent, 0, x, y);
   int status = _menu_show(menu_handle, VPM_LEFTALIGN | VPM_RIGHTBUTTON, x, y);
   _menu_destroy(menu_handle);
}

void ctl_matchcolor.ENTER,lbutton_up()
{
   p_value = (p_value) ? 0 : 1;
   p_style = (p_value) ? PSPIC_BUTTON : PSPIC_FLAT_BUTTON;
   _ds_update_color_label();
   _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
}

static void _init_matchcolor_menu(int menu_handle)
{
   color_enabled := (ctl_matchcolor.p_enabled && ctl_matchcolor.p_value);
   menu_pos := 0;
   flags := MF_ENABLED;
   if (color_enabled) {
      if (_findcoloroptions.p_text == '') {
         flags = MF_ENABLED|MF_CHECKED;
      } 
      _menu_insert(menu_handle, menu_pos, flags, 'None', 'docsearch_find_menu co NONE', "", "", "");
      ++menu_pos;
      _menu_insert(menu_handle, menu_pos, 0, '-', "", "", "", "");
      ++menu_pos;
   }

   lastcolor_found := false;  // last color in preset list?
   foreach (auto opt in def_search_color_presets) {
      name := _ccsearch_option_to_string(opt);
      flags = MF_ENABLED;
      if (color_enabled && (opt == _findcoloroptions.p_text)) {
         flags |= MF_CHECKED;
      }
      if (opt == _findcoloroptions.p_text) {
         lastcolor_found = true;
      }  
      _menu_insert(menu_handle, menu_pos, flags, name, 'docsearch_find_menu co 'opt, "", "", "");
      ++menu_pos;
   }

   // non-preset color, add entry
   if ((_findcoloroptions.p_text != '') && !lastcolor_found) {
      name := _ccsearch_option_to_string(_findcoloroptions.p_text);
      flags = MF_ENABLED;
      command := 'docsearch_find_menu co '_findcoloroptions.p_text;
      if (color_enabled) {
         flags |= MF_CHECKED;
         command = '';
      }
      _menu_insert(menu_handle, 0, flags, name, command, "", "", "");
      if (!color_enabled) {
         _menu_insert(menu_handle, 1, 0, '-', "", "", "", "");
      }
   }
}

void _init_matchcolor(int editorctl_wid)
{
   color_enabled := true;
   search_range := _ds_get_search_range();
   switch (search_range) {
   case VSSEARCHRANGE_ALL_BUFFERS:
   case VSSEARCHRANGE_PROJECT:
   case VSSEARCHRANGE_WORKSPACE:
      color_enabled = true;
      break;

   default:
      color_enabled = (editorctl_wid != 0) && (editorctl_wid.p_HasBuffer && editorctl_wid.p_lexer_name != "");
      break;
   }
   ctl_matchcolor.p_enabled = ctl_matchcolor_menu.p_enabled = color_enabled;
   ctl_matchcolor.p_visible = ctl_matchcolor_menu.p_visible = color_enabled;
}

void ctl_matchcolor_menu.ENTER,lbutton_up,down,up()
{
   form_wid := p_active_form.p_window_id;

   int index = find_index("_docsearchcolor_menu", oi2type(OI_MENU));
   int menu_handle = form_wid._menu_load(index, 'P');
   int x = p_x + p_width;
   y := p_y;
   _lxy2dxy(SM_TWIP, x, y);
   _map_xy(p_xyparent, 0, x, y);
   _init_matchcolor_menu(menu_handle);
   int status = _menu_show(menu_handle, VPM_LEFTALIGN | VPM_RIGHTBUTTON, x, y);
   _menu_destroy(menu_handle);
}

static void _init_search_range(int editorctl_wid, _str old_range = "")
{
   temp := ignore_change;
   ignore_change = true;
   if (old_range == "") {
      old_range = _findrange.p_text;
   }
   _findrange._lbclear();
   if (editorctl_wid != 0) {
      _findrange._lbadd_item(MFFIND_BUFFER);
      if (editorctl_wid.p_HasBuffer) {
         if (!editorctl_wid._isnull_selection()) {
            _findrange._lbadd_item(SEARCH_IN_CURRENT_SELECTION);
         }
         if ((editorctl_wid.p_lexer_name != '') && editorctl_wid._in_function_scope()) {
            _findrange._lbadd_item(SEARCH_IN_CURRENT_PROC);
         }
      } 
      if (!_no_child_windows() && editorctl_wid.p_mdi_child) {
         _findrange._lbadd_item(MFFIND_BUFFERS);
      }

      if (editorctl_wid.p_mdi_child) {
         if (_project_name != "") {
            _findrange._lbadd_item(MFFIND_PROJECT_FILES);
         }
         if (_workspace_filename != "") {
            _findrange._lbadd_item(MFFIND_WORKSPACE_FILES);
         } 
      }
   }

   if (old_range != "") {
      if (_findrange._lbfind_item(old_range) >= 0) {
         _findrange._cbset_text(old_range);
      }
   }
   if (!editorctl_wid || !editorctl_wid._isEditorCtl(false)) {
      _findrange.p_enabled = false;
   }
   ignore_change = temp;
}

void _findrange.on_drop_down(int reason)
{
   if (reason == DROP_INIT) {
      editorctl_wid := P_USER_MINIFIND_WID();
      if (editorctl_wid && editorctl_wid._isEditorCtl(false)) {
         _init_search_range(editorctl_wid, p_text);
      }
   }
}

void _findrange.on_change(int reason)
{
   if (ignore_change) {
      return;
   }
   s_params.m_status = -1;
   doUpdate();
   refresh("A");
}
 
void _otheroptions.on_change()
{
   if (ignore_change) {
      return;
   }
   
   old_ignore := ignore_change;
   ignore_change = true;
   if (_otheroptions.p_text != '') {
      _ds_restore_state(_otheroptions.p_text, true);
   }
   ignore_change = old_ignore;
}
 
/*** color coded search ***/
void _ds_configure_color_search()
{
   _str result = show("-modal _ccsearch_form", _findcoloroptions.p_text, '1');
   if (result != '') {
      _ds_update_color_search(_param1);
      _findstring._set_focus();
   }
}

void _ds_update_color_search(_str option)
{
   if (option != 'NONE') {
      _findcoloroptions.p_text = option;
   } else {
      option = '';
   }
   ctl_matchcolor.p_value = (option != '') ? 1 : 0;
   ctl_matchcolor.p_style = (ctl_matchcolor.p_value) ? PSPIC_BUTTON : PSPIC_FLAT_BUTTON;
   _ds_update_color_label();
   _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
}

void _ds_update_color_label()
{
   msg := "Match colors (Alt+O)";
   if (ctl_matchcolor.p_enabled && ctl_matchcolor.p_value) {
      name := _ccsearch_option_to_string(_findcoloroptions.p_text);
      msg :+= ":\n":+name;
   }
   ctl_matchcolor.p_message = msg;
}

// ****************************************************************************
static void _ds_init_markers()
{
   if (gDSMarkerType < 0) {
      gDSMarkerType = _MarkerTypeAlloc();
      _MarkerTypeSetFlags(gDSMarkerType, VSMARKERTYPEFLAG_AUTO_REMOVE);
      _MarkerTypeSetPriority(gDSMarkerType, 4);
   }
   if (gDSMarkerCurrentType < 0) {
      gDSMarkerCurrentType = _MarkerTypeAlloc();
      _MarkerTypeSetFlags(gDSMarkerCurrentType, VSMARKERTYPEFLAG_AUTO_REMOVE|VSMARKERTYPEFLAG_DRAW_BOX);
      _MarkerTypeSetPriority(gDSMarkerCurrentType, 0);
   }
   if (gDSScrollMarkerType < 0) {
      gDSScrollMarkerType = _ScrollMarkupAllocType();
      _ScrollMarkupSetTypeColor(gDSScrollMarkerType, CFG_HILIGHT);
   }
   if (gDSMatchScrollMarkerType < 0) {
      gDSMatchScrollMarkerType = _ScrollMarkupAllocType();
      _ScrollMarkupSetTypeColor(gDSMatchScrollMarkerType, CFG_INC_SEARCH_CURRENT);
   }
}

void _MaybeScrollMarkupUpdateAllModels(bool AlwaysUpdate=false)
{
   _ScrollMarkupUpdateAllModels();
}

static void _ds_clear_markers()
{
   if (gDSMarkerType >= 0) {
      _StreamMarkerRemoveAllType(gDSMarkerType);
   }
   if (gDSMarkerCurrentType >= 0) {
      _StreamMarkerRemoveAllType(gDSMarkerCurrentType);
   }
   if (gDSScrollMarkerType >= 0) {
      _ScrollMarkupRemoveAllType(gDSScrollMarkerType);
   }
   if (gDSMatchScrollMarkerType >= 0) {
      _ScrollMarkupRemoveAllType(gDSMatchScrollMarkerType);
   }
   s_params.m_marker_id = -1;   
   s_params.m_scrollmarker_id = -1;
   s_params.m_update = true;
}

static void _ds_dismiss_tooltip(int editorctl_wid)
{
   if (s_params.m_tooltip) {
      editorctl_wid._bbhelp('C');
      s_params.m_tooltip = false;
   }
}

static void _ds_translate_command(_str keyname)
{
   form_wid := p_active_form.p_window_id;
   replace_mode := _replaceframe.p_visible;
   // check toggle
   switch (keyname) {
   case "gui-find":
      if (replace_mode) {
         _ds_set_replace_mode(false);
         if (def_keys == "brief-keys") {
            s_params.m_options &= ~VSSEARCHFLAG_REVERSE;
         }
         return;
      }
      break;

   case "gui-find-backward":
      if (replace_mode) {
         _ds_set_replace_mode(false);
         s_params.m_options |= VSSEARCHFLAG_REVERSE;
         return;
      }
      break;

   case "gui-find-regex":
      if (replace_mode) {
         _ds_set_replace_mode(false);
         ctl_regex.p_value = 1;
         if (def_re_search_flags & VSSEARCHFLAG_PERLRE) {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_PERLRE);
         } else if (def_re_search_flags & VSSEARCHFLAG_VIMRE) {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_VIMRE);
         } else if (def_re_search_flags & VSSEARCHFLAG_WILDCARDRE) {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_WILDCARDRE);
         } else {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_RE);
         }
         ctl_regex.p_style = PSPIC_BUTTON;
         _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
         return;
      }
      break;

   case "gui-replace":
      if (!replace_mode) {
         _ds_set_replace_mode(true);
         if (def_keys == "brief-keys") {
            s_params.m_options &= ~VSSEARCHFLAG_REVERSE;
         }
         return;
      }
      break;

   case "gui-replace-backward":
      if (!replace_mode) {
         _ds_set_replace_mode(true);
         s_params.m_options |= VSSEARCHFLAG_REVERSE;
         return;
      }
      break;

   case "gui-replace-regex":
      if (!replace_mode) {
         _ds_set_replace_mode(true);
         ctl_regex.p_value = 1;
         if (def_re_search_flags & VSSEARCHFLAG_PERLRE) {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_PERLRE);
         } else if (def_re_search_flags & VSSEARCHFLAG_VIMRE) {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_VIMRE);
         } else if (def_re_search_flags & VSSEARCHFLAG_WILDCARDRE) {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_WILDCARDRE);
         } else {
            P_USER_MINIFIND_RE(VSSEARCHFLAG_RE);
         }
         ctl_regex.p_style = PSPIC_BUTTON;
         _findstring.call_event(CHANGE_OTHER, _control _findstring, ON_CHANGE, "W");
         return;
      }
      break;
   }
   editorctl_wid := P_USER_MINIFIND_WID();

   search_string := _findstring.p_text;
   replace_string := (replace_mode) ? _replacestring.p_text : '';
   search_options := _ds_get_search_options();
   search_range := _ds_get_search_range();
   mfflags := s_params.m_mfflags;
   grep_id := s_params.m_grep_id;
   misc_options := _get_misc_search_opts();

   p_active_form._delete_window();
   if (_iswindow_valid(editorctl_wid) && editorctl_wid._isEditorCtl()) {
      activate_window(editorctl_wid);
   } else {
      editorctl_wid = _MDIGetActiveMDIChild();
      if (_iswindow_valid(editorctl_wid) && editorctl_wid._isEditorCtl()) {
         activate_window(editorctl_wid);
      } else {
         return;
      }
   }

   // fixup options
   switch(keyname) {
   case "gui-find":
   case "gui-replace":
      if (def_keys == "brief-keys") {
         search_options = stranslate(search_options, '', '-');
      }
      break;

   case "gui-find-backward":
   case "gui-replace-backward":
      search_options = stranslate(search_options, '', '+');
      search_options :+= '-';
      break;

   case "gui-find-regex":
   case "gui-replace-regex":
      search_options = stranslate(search_options, '', 'R', 'I');
      search_options = stranslate(search_options, '', 'L', 'I');
      search_options = stranslate(search_options, '', '~');
      search_options = stranslate(search_options, '', '&');
      if (def_re_search_flags & VSSEARCHFLAG_PERLRE) {
         search_options :+= 'L';
      } else if (def_re_search_flags & VSSEARCHFLAG_VIMRE) {
         search_options :+= '~';
      } else if (def_re_search_flags & VSSEARCHFLAG_WILDCARDRE) {
         search_options :+= '&';
      } else {
         search_options :+= 'R';
      }
      break;
   }

   switch (keyname) {
   case "gui-find":
   case "gui-find-backward":
   case "gui-find-regex":
   case "tool-gui-find":
      tool_gui_find();
      tool_find_update_options(search_string, replace_string, search_options, search_range, mfflags, misc_options, false);
      return;
   case "gui-replace":
   case "gui-replace-backward":
   case "gui-replace-regex":
   case "tool-gui-replace":
      tool_gui_replace();
      tool_find_update_options(search_string, replace_string, search_options, search_range, mfflags, misc_options, false);
      return;

   case "find-in-files":
      find_in_files();
      tool_find_update_options(search_string, replace_string, search_options, -1, mfflags, misc_options, false);
      return;

   case "replace-in-files":
      replace_in_files();
      tool_find_update_options(search_string, replace_string, search_options, -1, mfflags, misc_options, false);
      return;

   case "find-file":
      find_file();
      tool_find_update_options(search_string, replace_string, search_options, -1, mfflags, misc_options, false);
      return;
   }
}

static void _ds_set_search_options(_str search_options)
{
   if (pos('I', search_options, 1, 'I')) {
      ctl_matchcase.p_value = 0;
   } else if (pos('E', search_options, 1, 'I')) {
      ctl_matchcase.p_value = 1;
   }

   if (pos('W', search_options, 1, 'I')) {
      ctl_matchword.p_value = 1;
   }

   if (pos('[RUBL&~]', search_options, 1, 'r')) {
      ctl_regex.p_value = 1;
      if (pos('r', search_options, 1, 'I')) {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_RE);
      } else if (pos('u', search_options, 1, 'I')) {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_PERLRE);
      } else if (pos('b', search_options, 1, 'I')) {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_PERLRE);
      } else if (pos('l', search_options, 1, 'I')) {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_PERLRE);
      } else if (pos('&', search_options, 1)) {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_WILDCARDRE);
      } else if (pos('~', search_options, 1)) {
         P_USER_MINIFIND_RE(VSSEARCHFLAG_VIMRE);
      }
   }

   options := s_params.m_options;
   if (pos('-', search_options)) {
      options |= VSSEARCHFLAG_REVERSE;
   } else if (pos('+', search_options) || def_keys == "brief-keys") {
      options &= ~VSSEARCHFLAG_REVERSE;
   }

   if (pos('H', search_options, 1, 'I')) {
      options |= VSSEARCHFLAG_HIDDEN_TEXT;
   }

   if (pos('$', search_options, 1, 'I')) {
      options |= VSSEARCHFLAG_REPLACEHILIGHT;
   }

   if (pos('?', search_options, 1, 'I')) {
      options |= VSSEARCHFLAG_PROMPT_WRAP|VSSEARCHFLAG_WRAP;
   } else if (pos('p', search_options, 1, 'I')) {
      options |= VSSEARCHFLAG_WRAP;
   }

   if (pos('>', search_options)) {
      options |= VSSEARCHFLAG_POSITIONONLASTCHAR;
   } else if (pos('<', search_options)) {
      options &= ~VSSEARCHFLAG_POSITIONONLASTCHAR;
   }

   s_params.m_options = options;
}

static _str _ds_get_search_options()
{
   search_options := "";
   if (!ctl_matchcase.p_value) search_options :+= 'I';
   if (ctl_matchword.p_value) search_options :+= 'W';
   if (ctl_regex.p_value) {
      re_flags := P_USER_MINIFIND_RE();
      if (re_flags & VSSEARCHFLAG_PERLRE) {
         search_options :+= 'L';
      } else if (re_flags & VSSEARCHFLAG_VIMRE) {
         search_options :+= '~';
      } else if (re_flags & VSSEARCHFLAG_WILDCARDRE) {
         search_options :+= '&';
      } else {
         search_options :+= 'R';
      }
   }
 
   options := s_params.m_options;
   if (options & VSSEARCHFLAG_WRAP) {
      if (options & VSSEARCHFLAG_PROMPT_WRAP) {
         search_options :+= 'P?';
      } else {
         search_options :+= 'P';
      }
   }
   if (options & VSSEARCHFLAG_REVERSE) {
      search_options :+= '-';
   } else {
      search_options :+= '+';
   }
   if (options & VSSEARCHFLAG_HIDDEN_TEXT) {
      search_options :+= 'H';
   }
   if (options & VSSEARCHFLAG_POSITIONONLASTCHAR) {
      search_options :+= '>';
   }
   if (options & VSSEARCHFLAG_HIDDEN_TEXT) {
      search_options :+= 'H';
   }

   if (_replaceframe.p_visible) {
      if (ctl_preservecase.p_value) {
         search_options :+= 'V';
      }
      if (options & VSSEARCHFLAG_REPLACEHILIGHT) {
         search_options :+= '$';
      }
   }

   if (ctl_matchcolor.p_enabled && ctl_matchcolor.p_value) {
      search_options :+= _findcoloroptions.p_text;
   }

   search_range := _findrange.p_text;
   if (search_range == SEARCH_IN_CURRENT_SELECTION || search_range == SEARCH_IN_CURRENT_PROC) {
      search_options :+= 'M';
   }
   return search_options;
}

static int _ds_get_search_range(_str range="")
{
   if (range == "") {
      range = _findrange.p_text;
   }
   switch (range) {
   case SEARCH_IN_CURRENT_BUFFER:      return(VSSEARCHRANGE_CURRENT_BUFFER);
   case SEARCH_IN_CURRENT_SELECTION:   return(VSSEARCHRANGE_CURRENT_SELECTION);
   case SEARCH_IN_CURRENT_PROC:        return(VSSEARCHRANGE_CURRENT_PROC);
   case SEARCH_IN_ALL_BUFFERS:
   case SEARCH_IN_ALL_ECL_BUFFERS:     return(VSSEARCHRANGE_ALL_BUFFERS);
   case MFFIND_PROJECT_FILES:          return(VSSEARCHRANGE_PROJECT);
   case MFFIND_WORKSPACE_FILES:        return(VSSEARCHRANGE_WORKSPACE);
   default:                            return(VSSEARCHRANGE_CURRENT_BUFFER);
   }
   return(VSSEARCHRANGE_CURRENT_BUFFER);
}

static void _ds_set_search_range(int search_range)
{
   text := "";
   switch (search_range) {
   case VSSEARCHRANGE_CURRENT_BUFFER:     text = SEARCH_IN_CURRENT_BUFFER; break;
   case VSSEARCHRANGE_CURRENT_SELECTION:  text = SEARCH_IN_CURRENT_SELECTION; break;
   case VSSEARCHRANGE_CURRENT_PROC:       text = SEARCH_IN_CURRENT_PROC; break;
   case VSSEARCHRANGE_ALL_BUFFERS:        
      if (!isEclipsePlugin()) {
         text = SEARCH_IN_ALL_BUFFERS;
      } else {
         text = SEARCH_IN_ALL_ECL_BUFFERS;
      }
      break;
   case VSSEARCHRANGE_PROJECT:            text = MFFIND_PROJECT_FILES; break;
   case VSSEARCHRANGE_WORKSPACE:          text = MFFIND_WORKSPACE_FILES; break;
   default:                               text = SEARCH_IN_CURRENT_BUFFER; break;
   }

   if (text != '') {
      if (_findrange._lbfind_item(text) >= 0) {
         _findrange._cbset_text(text);
      }
   }
}

static bool _ds_check_search_timer(typeless& start_time)
{
   return false;
}

static int _ds_mark_all(int wid, _str search_string, _str search_options, int& num_matches)
{
   match_offset := -1;
   match_len := -1;
   markerID := -1;
   int showMarkers = def_search_incremental_highlight;
   showScrollMarkup := 1;
   num_matches = 0;

   save_pos(auto p);
   search_options = stranslate(search_options, '', '-');  // remove reverse search
   mark_search := (pos('M', search_options, 1, 'i') != 0);
   if (mark_search) {
      mark_id := _duplicate_selection('');
      _begin_select(mark_id); _begin_line();
   } else {
      top(); _begin_line();
      //bottom(); _end_line();
   }

   typeless start_time = _time('b');
   status := search(search_string, 'xv,@'search_options);
   if (!status) {
      lastOffset := -1;
      lastLine := -1;
      for (;;) {
         match_offset = match_length('S');
         match_len = match_length();
         if (match_offset == lastOffset) break;
         if (showMarkers) {
            markerID = _StreamMarkerAdd(p_window_id, match_offset, match_len, false, 0, gDSMarkerType, null);
            if (markerID >= 0) {
               _StreamMarkerSetTextColor(markerID, CFG_INC_SEARCH_MATCH);
               _StreamMarkerSetUserDataInt64(markerID, num_matches+1);
            }
         }
         if (lastLine != p_line) {
            _ScrollMarkupAddOffset(wid, match_offset, gDSScrollMarkerType, match_len);
            lastLine = p_line;
         }
         lastOffset = match_offset;
         ++num_matches;
         if (def_gui_find_max_search_markers > 0 &&
             num_matches >= def_gui_find_max_search_markers) {
            _ds_clear_markers();
            break;
         }
         /*
         typeless t = _time('b');
         if (t - start_time > 200) { // More than .2 seconds?
            start_time = t;
            if (_IsKeyPending(false)) {
               flush_keyboard();
               break;
            }
         }*/
         if (repeat_search()) break;
      }
   }
   restore_pos(p);
   return status;
}

static void _update_last_search_macro(_str search_string, _str search_options)
{
   if (!s_params.m_macro_last_search) {
      _macro_call_maybe_stop('find', search_string, search_options);
      return;
   }
   _str line=_macro_get_line();
   param1 := "";
   parse line with "if (find(" param1 ")) stop();";
   if (param1 != '') {
      _macro_delete_line();
   }
   _macro_call_maybe_stop('find', search_string, search_options);
}

static void _maybe_remove_last_search_macro(_str search_options)
{
   if (!s_params.m_macro_last_search) {
      return;
   }
   int was_recording = _macro('s');
   if (!was_recording) {
      return;
   }
   _str line=_macro_get_line();
   param1 := "";
   parse line with "if (find(" param1 ")) stop();";
   if (param1 != '') {
      _macro_delete_line();
   }
}

// search current document
static int _ds_search(_str search_string, _str search_options, bool nowrap = false)
{
   int was_recording = _macro('s');
   if (was_recording) {
      _macro('m', was_recording);
      _update_last_search_macro(search_string, search_options);
   }
   s_params.m_macro_last_search = true;
   save_pos(auto p);
   status := search(search_string, 'xv,@'search_options);
   if (status && status != INVALID_REGULAR_EXPRESSION_RC) {
      wrap_search := (pos('p', search_options, 1, 'I') != 0);
      if (wrap_search && !nowrap) {
         reverse_search := (pos('-', search_options) != 0);
         mark_search := (pos('m', search_options, 1, 'I') != 0);
         mark_id := _duplicate_selection('');
         if (mark_search) {
            if (reverse_search) {
               _end_select(mark_id); _end_line();
            } else {
               _begin_select(mark_id); _begin_line();
            }
         } else {
            if (reverse_search) {
               bottom();
            } else {
               top(); up();
            }
         }
         status = search(search_string, 'xv,@'search_options);
         if (status) {
            restore_pos(p);
         }
      }
   }

   if (status) {
      message(get_message(status));
   }
   return status;
}

// TODO: can we this be better?
struct DSMark {
   int m_wid;
   int m_id;
   int m_mark;
};

static void _ds_begin_mark(_str search_options, int search_range, DSMark& info)
{
   info.m_wid = p_window_id;
   info.m_id = _duplicate_selection('');
   info.m_mark = -1;
   if (search_range == VSSEARCHRANGE_CURRENT_SELECTION) {
      if (select_active2()) {
         info.m_mark = _duplicate_selection(info.m_id);
         _show_selection(info.m_mark);
         style := _select_type('', 'S');
         if ((_cursor_move_deselects() || _cursor_move_extendssel()) && style == 'C') {
            _select_type('', 'S', 'E');
         }

         _get_selinfo(auto first_col,auto last_col, auto buf_id, info.m_id);
         reverse_search := (pos('-', search_options) != 0);
         mark_type := _select_type(info.m_id);
         if (reverse_search) {
            if (_begin_select_compare(info.m_id) <= 0) {
               if (mark_type == 'BLOCK') {
                  int columnStartPixel,columnEndPixel;
                  _BlockSelGetStartAndEndPixel(columnStartPixel,columnEndPixel,info.m_id);
                  _BlockSelGetStartAndEndCol(first_col,last_col,columnStartPixel,columnEndPixel,info.m_id);
                  --last_col;
               }
               if (((mark_type == 'BLOCK') || (mark_type == 'CHAR')) && (p_col <= first_col)) {
                  _end_select(info.m_id);
               } else if ((mark_type == 'LINE') && (p_col <= first_col)) {
                  _end_select(info.m_id); _end_line();
               }
            }
         } else {
            if (_end_select_compare(info.m_id) >= 0) {
               if (mark_type == 'BLOCK') {
                  int columnStartPixel,columnEndPixel;
                  _BlockSelGetStartAndEndPixel(columnStartPixel,columnEndPixel,info.m_id);
                  _BlockSelGetStartAndEndCol(first_col,last_col,columnStartPixel,columnEndPixel,info.m_id);
                  --last_col;
               }
               if (((mark_type == 'BLOCK') || (mark_type == 'CHAR')) && (p_col >= last_col + _select_type(info.m_id,'I'))) {
                  _begin_select(info.m_id);
               } else if ((mark_type == 'LINE') && (p_col >= _text_colc())) {
                  _begin_select(info.m_id); _begin_line();
               }
            }
         }
      }
   } else if (search_range == VSSEARCHRANGE_CURRENT_PROC) {
      mark_id := s_params.m_proc_mark;
      if (mark_id >= 0) {
         if (_in_selection(mark_id)) {
            _show_selection(mark_id);
         } else {
            _free_selection(mark_id);
            mark_id = -1;
         }
      }

      if (mark_id < 0) {
         if ((p_lexer_name != '') && _in_function_scope()) {
            save_pos(auto p);
            mark_id = _alloc_selection();
            status := select_proc(0, mark_id, 1);
            if (!status) {   //lock selection and mark it persistent
               if (_select_type(mark_id, 'S') == 'C') {
                  _select_type(mark_id, 'S', 'E');
               }
               _select_type(mark_id, 'U', 'P');
               restore_pos(p);
               _show_selection(mark_id);
            } else {
               _free_selection(mark_id);
               mark_id = -1;
            }
         }
      }
      s_params.m_proc_mark = mark_id;

   } else { 
      maybe_deselect();
   }
}

static void _ds_end_mark(DSMark& info)
{
   if (info.m_id > 0) {
      if (p_window_id == info.m_wid) {
         _show_selection(info.m_id);
         if (info.m_mark > 0) {
            _free_selection(info.m_mark);
         }
      }
   }
}

static _str _ds_get_sel_info(int mark_id)
{
   typeless junk;
   _get_selinfo(auto start_col, auto end_col, auto buf_id, mark_id, junk, junk, junk, auto Noflines);

   start_mark := '';
   save_pos(auto p);
   prev_select_type := '';
   if(_select_type(mark_id, 'S') == 'C') {
      prev_select_type = 'C';
      _select_type(mark_id, 'S', 'E');
   }
   status := _begin_select(mark_id);
   if (status) {
      start_mark = p_line;
   }
   restore_pos(p);   
   if (prev_select_type != '') {
      _select_type(mark_id, 'S', prev_select_type);
   }

   return _select_type(mark_id):+start_mark:+start_col:+end_col:+buf_id:+Noflines;
}

static void _ds_begin_update(int search_range)
{
   if (search_range == VSSEARCHRANGE_CURRENT_SELECTION) {
       mark_id := _duplicate_selection('');
       if (!select_active2()) {
          if (s_params.m_last_mark >= 0) {
             s_params.m_last_mark = -1;
             s_params.m_last_mark_info = '';
          }
       } else {
          s_params.m_last_mark = mark_id;
          s_params.m_last_mark_info = _ds_get_sel_info(mark_id);
       }
 
   } else {
      s_params.m_last_mark = -1;
      s_params.m_last_mark_info = '';
   }

   if (search_range != VSSEARCHRANGE_CURRENT_PROC) {
      if (s_params.m_proc_mark >= 0) {
         _free_selection(s_params.m_proc_mark);
         s_params.m_proc_mark = -1;
      }
   }
}

static int doUpdate()
{
   form_wid := p_active_form.p_window_id;
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      _findstring._show_textbox_error_color(true);
      return -1;
   }
   if (editorctl_wid.p_buf_size > def_gui_find_incremental_search_max_buf_ksize*1024) {
      s_params.m_disable_occurences = true;
      return 0;
   }
   num_matches := 0;
   status := 0;
   search_string := _findstring.p_text;
   search_options := _ds_get_search_options();
   search_range := _ds_get_search_range();
   activate_window(editorctl_wid);
   _ds_clear_markers();
   _ds_begin_update(search_range);
   save_pos(auto p);
   if (search_string :!= '') {
      _ds_begin_mark(search_options, search_range, auto mark_info);
      status = _ds_mark_all(editorctl_wid, search_string, search_options, num_matches);
      _ds_end_mark(mark_info);
   }
   restore_pos(p);
   activate_window(form_wid);
   err_status := (search_string != '') && (status != 0);
   _findstring._show_textbox_error_color(err_status);
   s_params.m_num_matches = num_matches;
   s_params.m_update = false;
   s_params.m_lastModified = editorctl_wid.p_LastModified;
   s_params.m_disable_occurences = (def_gui_find_max_search_markers > 0) && (num_matches >= def_gui_find_max_search_markers);
   _ds_update_match_label(form_wid);
   if (search_string :!= '') {
      if (!status) {
         set_find_next_msg("Find", search_string, search_options, search_range);
      } else {
         set_find_next_msg("");
         message(get_message(status));
      }
   }
   return status;
}

static void _dsreplace_refresh_scroll()
{
   match_id := _alloc_selection();
   _select_match(match_id);
   save_pos(auto p);
   save_search(auto search_string,auto search_flags, auto junk);
   _get_selinfo(auto start_col, auto end_col, auto buf_id, match_id);
   if (search_flags & VSSEARCHFLAG_POSITIONONLASTCHAR) {
      _begin_select(match_id);
      if (_end_select_compare(match_id)) {
         _end_select(match_id);
         _begin_line();
      }
      start_col = p_col;
      restore_pos(p);
      p_col = start_col;
      _refresh_scroll();
      p_col = end_col;
   } else {
      _end_select(match_id);
      if (_begin_select_compare(match_id)) {
         _begin_select(match_id);
         _end_line();
      }
      end_col = p_col;
      restore_pos(p);
      p_col = end_col;
      _refresh_scroll();
      p_col = start_col;
   }
   _refresh_scroll();
   _free_selection(match_id);
}

static void _ds_select_match(int search_range)
{
   _dsreplace_refresh_scroll();
   if (search_range == VSSEARCHRANGE_CURRENT_SELECTION) {
      return;
   }
   if (select_active2()) {
      style := _select_type('', 'S');
      if ((_cursor_move_deselects() || _cursor_move_extendssel()) && _select_type('', 'S') == 'C') {
         return;
      }
   }
   if (def_leave_selected) {
      mark_id := _duplicate_selection('');
      match_id := _alloc_selection();
      _select_match(match_id);
      _show_selection(match_id);
      _free_selection(mark_id);
   }
} 

static void _ds_update_current_mark()
{
   match_offset := match_length('S');
   match_len := match_length();

   if (s_params.m_match_mark < 0) {
      s_params.m_match_mark = _alloc_selection();
   } else {
      _deselect(s_params.m_match_mark);
   }
   _select_char(s_params.m_match_mark, 'EN');
   s_params.m_match_length = match_len;
   s_params.m_match_start = match_offset;

   if (s_params.m_start_mark < 0) {
      s_params.m_start_mark = _duplicate_selection(s_params.m_match_mark);
   }

   if (def_search_incremental_highlight) {
      if (s_params.m_marker_id >= 0) {
         if (!_StreamMarkerGet(s_params.m_marker_id, auto info)) {
            if (s_params.m_disable_occurences) {
               _StreamMarkerRemove(s_params.m_marker_id);
            } else {
               // change marker color
               _StreamMarkerSetTextColor(s_params.m_marker_id, CFG_INC_SEARCH_MATCH);
               _StreamMarkerSetType(s_params.m_marker_id, gDSMarkerType);
            }
         }
         s_params.m_marker_id = -1;
      }
   } else {
      s_params.m_marker_id = -1;
   }
   if (s_params.m_scrollmarker_id > 0) {
      _ScrollMarkupRemove(p_window_id, s_params.m_scrollmarker_id);
      s_params.m_scrollmarker_id = -1;
   }

   markerID := -1;
   if (def_search_incremental_highlight) {
      _StreamMarkerFindList(auto list, p_window_id, match_offset, 1, 0, gDSMarkerType);
      if  (list._length() > 0) {
         markerID = list[0];
         _StreamMarkerGet(markerID, auto info);
         if (info.StartOffset != match_offset) {
            markerID = -1;
         }
         if (list._length() > 1) {
            for (i := 1; i < list._length(); ++i) {
               _StreamMarkerGet(list[i], info);
               if (info.StartOffset == match_offset && info.Length == match_len) {
                  markerID = list[i];
                  break;
               }
            }
         }
      }
      if (markerID < 0) {
         markerID = _StreamMarkerAdd(p_window_id, match_offset, match_len, false, 0, gDSMarkerCurrentType, null);
      } else {
         _StreamMarkerSetType(markerID, gDSMarkerCurrentType);
      }
      if (markerID >= 0) {
         _StreamMarkerSetTextColor(markerID, CFG_INC_SEARCH_CURRENT);
         if (_isDarkColorBackground()) {
            _StreamMarkerSetStyleColor(markerID,-1 /* don't draw a box */);
            //_StreamMarkerSetStyleColor(markerID,/*255 170 0 orange*/ 0x00AAff);
         }
      }
   }
   s_params.m_marker_id = markerID;
   s_params.m_scrollmarker_id = _ScrollMarkupAddOffset(p_window_id, match_offset, gDSMatchScrollMarkerType, match_len);
   //goto_point(match_offset + match_len);
}

static void _ds_update_match_label(int form_wid)
{
   msg := "";
   index := -1;
   if (s_params.m_marker_id >= 0) {
      index = _StreamMarkerGetUserDataInt64(s_params.m_marker_id);
   }
   if (index > 0) {
      msg = index:+" of ":+s_params.m_num_matches;
   } else if (s_params.m_num_matches > 0) {
      max_count := ((def_gui_find_max_search_markers > 0) && (s_params.m_num_matches >= def_gui_find_max_search_markers));
      msg = s_params.m_num_matches:+((max_count) ? "+" : ""):+" ":+((s_params.m_num_matches == 1) ? "match" : "matches");
   }

   if (msg != '') {
      form_wid._resize_options_widths(msg);
   }
   form_wid._findlabel.p_caption = msg;
}

static void doSearch()
{
   if (!P_USER_MINIFIND_ISEARCH()) {
      _ds_reset_match_marker();
      return;
   }
   _mffindNoMore(1);
   _mfrefNoMore(1);
   form_wid := p_active_form.p_window_id;
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      _findstring._show_textbox_error_color(true);
      return;
   }
   search_string := _findstring.p_text;
   search_options := _ds_get_search_options();
   search_range := _ds_get_search_range();
   replace_mode := _replaceframe.p_visible;
   replace_string := _replacestring.p_text;

   activate_window(editorctl_wid);
   if (search_range != VSSEARCHRANGE_CURRENT_SELECTION) {
      if (select_active2() && _cursor_move_deselects()) {
         _deselect();
      }
   } else {
      if (select_active2()) {
         style := _select_type('', 'S');
         if ((_cursor_move_deselects() || _cursor_move_extendssel()) && style == 'C') {
            _select_type('', 'S', 'E');
         }
      }
   }

   if (old_search_mark != '') {
      _free_selection(old_search_mark);
      old_search_mark = '';
   }
   save_pos(auto p);
   if (s_params.m_status == -1) {
      _deselect(s_params.m_search_mark);
      _select_char(s_params.m_search_mark, 'EN');
   } else {
      _begin_select(s_params.m_search_mark);
   }
   status := 0;
   if (search_string :!= '') {
      _ds_begin_mark(search_options, search_range, auto mark_info);
      status = _ds_search(search_string, search_options);
      if (!status && old_search_flags & VSSEARCHFLAG_MARK) {
         old_search_mark = _duplicate_selection();
      }
      _ds_end_mark(mark_info);
      s_params.m_status = status;
      save_search(old_search_string, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
      old_search_range = search_range;

      if (!status) {
         _MaybeUnhideLine();
         _ds_update_current_mark();
         _ds_select_match(search_range);
         _ds_update_editor_scroll(editorctl_wid, form_wid);
         p_scroll_left_edge = -1;
      } else {
         restore_pos(p);
      }
   } else {
      if (replace_mode) {
         _ds_dismiss_tooltip(editorctl_wid);
      }
      _ds_reset_editor_scroll(editorctl_wid, form_wid);
      _maybe_remove_last_search_macro(search_options);
      // clear last match
      if (s_params.m_match_mark >= 0) {
         _free_selection(s_params.m_match_mark);
         s_params.m_match_mark = -1;
      }
      s_params.m_match_length = 0;
      s_params.m_match_start = 0;
   }

   _ds_update_match_label(form_wid);
   if (search_string :!= '') {
      if (!status) {
         set_find_next_msg("Find", search_string, search_options, search_range);
         message(old_search_message);
      } else {
         set_find_next_msg("");
         message(get_message(status));
      }
   }
   if (replace_mode) {
      if (!s_params.m_status) {
         _ds_update_tooltip(editorctl_wid, search_string, replace_string);
      } else {
         _ds_dismiss_tooltip(editorctl_wid);
      }
   }
   activate_window(form_wid);
}

static bool _ds_confirm_wrap(int search_flags, int search_range)
{
   reverse_search := (search_flags & VSSEARCHFLAG_REVERSE) != 0;
   mark_search := (search_flags & VSSEARCHFLAG_MARK) != 0;

   if (mark_search && def_search_auto_wrap_procedure && search_range == VSSEARCHRANGE_CURRENT_PROC) {
      return true;
   }

   _str range_name = (mark_search) ? "selection" : "file";
   if (!(search_flags & VSSEARCHFLAG_WRAP)) {
      if (reverse_search) {
         message(nls("Beginning of ":+range_name:+" reached"));
      } else {
         message(nls("End of ":+range_name:+" reached"));
      }
      return false;
   }
   if (!(search_flags & VSSEARCHFLAG_PROMPT_WRAP)) {
      return true;
   }

   save_pos(auto p);
   orig_offset := _QROffset();
   if (mark_search) {
      mark_id := _duplicate_selection('');
      if (reverse_search) {
         _end_select(mark_id); _end_line();
      } else {
         _begin_select(mark_id); _begin_line();
      }
   } else {
      if (reverse_search) {
         bottom();
      } else {
         top(); up();
      }
   }
   status := repeat_search();
   if (!status && (_QROffset() == orig_offset)) {
      status = STRING_NOT_FOUND_RC;
   }
   restore_pos(p);
   if (status) {
      return false;
   }
   _str msg;
   if (reverse_search) {
      msg = nls("Beginning of ":+range_name:+" reached.  Continue searching at the end?");
   } else {
      msg = nls("End of ":+range_name:+" reached.  Continue searching at the beginning?");
   }
   clear_message();
   status = _message_box(msg,'',MB_YESNOCANCEL);
   if (status != IDYES) {
      if (reverse_search) {
         message(nls("Beginning of ":+range_name:+" reached"));
      } else {
         message(nls("End of ":+range_name:+" reached"));
      }
      return false;
   }
   return true;
}

static int _ds_next(_str search_string, _str search_options, int search_range, bool doPrev, bool& wrap, bool doReplaceNext)
{
   int was_recording = _macro('s');
   if (was_recording) {
      _macro('m', was_recording);
      _macro_call_maybe_stop('find_next', doPrev);
   }
   s_params.m_macro_last_search = false;
   mark_id := _duplicate_selection('');
   save_pos(auto p);
   flags := old_search_flags;
   if (doPrev) {
      flags = (flags ^ VSSEARCHFLAG_REVERSE);
   }
   mark_search := (pos('M', search_options, 1, 'i') != 0);
   if (mark_search) {
      flags |= VSSEARCHFLAG_MARK;
   } else {
      flags &= ~VSSEARCHFLAG_MARK;
   }
   restore_search(search_string, flags, old_word_re, old_search_reserved, old_search_flags2);
   status := 0;
   if (!doReplaceNext) {
      status = repeat_search();
   } else {
      status = repeat_search('', _text_colc(s_params.m_match_replace, 'I'), 1);
   }
   if (status && status != INVALID_REGULAR_EXPRESSION_RC) {
      if (p_mdi_child) {
         editorctl_wid := p_window_id;
         switch (search_range) {
         case VSSEARCHRANGE_ALL_BUFFERS:
            _default_option(VSOPTION_INITIALLY_DISABLE_EDITOR_CONTROL_KEY_INPUT, 1);
            status = _find_next_all_buffers(doPrev);
            if (editorctl_wid == p_window_id) {
               _default_option(VSOPTION_INITIALLY_DISABLE_EDITOR_CONTROL_KEY_INPUT, 0);
            }
            break;
         case VSSEARCHRANGE_PROJECT:
            _default_option(VSOPTION_INITIALLY_DISABLE_EDITOR_CONTROL_KEY_INPUT, 1);
            status = _find_next_in_project(false, doPrev);
            if (editorctl_wid == p_window_id) {
               _default_option(VSOPTION_INITIALLY_DISABLE_EDITOR_CONTROL_KEY_INPUT, 0);
            }
            break;
         case VSSEARCHRANGE_WORKSPACE:
            _default_option(VSOPTION_INITIALLY_DISABLE_EDITOR_CONTROL_KEY_INPUT, 1);
            status = _find_next_in_project(true, doPrev);
            if (editorctl_wid == p_window_id) {
               _default_option(VSOPTION_INITIALLY_DISABLE_EDITOR_CONTROL_KEY_INPUT, 0);
            }
            break;
         }
      }
      if (status) {
         if (_ds_confirm_wrap(flags, search_range)) {
            if (flags & VSSEARCHFLAG_MARK) {
               if (flags & VSSEARCHFLAG_REVERSE) {
                  _end_select(mark_id); _end_line();
               } else {
                  _begin_select(mark_id); _begin_line(); up();
               }
            } else {
               if (flags & VSSEARCHFLAG_REVERSE) {
                  bottom();
               } else {
                  top(); up();
               }
            }
            restore_search(search_string, flags, old_word_re, old_search_reserved, old_search_flags2);
            status = repeat_search();
            if (status) {
               restore_pos(p);
            }
            _show_selection(mark_id);
         }
         if (!status) {
            wrap = true;
         }
      }
   } else if (status) {
      message(get_message(status));
   }
   return status;
}

static void _ds_reload_form(int editorctl_wid)
{
   int form_wid = _find_formobj('_document_search_form','N');
   if (form_wid) {
      // old form may not be dead, kill it
      form_wid._delete_window();
   }

   activate_window(editorctl_wid);
   status := show('-child -NOCENTER _document_search_form', p_window_id, 'RELOAD');
   if (status == '') {
      return;
   }
   form_wid = (int)status;
   activate_window(form_wid);
   search_string := _findstring.p_text;
   search_options := _ds_get_search_options();
   doUpdate();
   activate_window(editorctl_wid);
   if (select_active2() && _cursor_move_deselects()) {
      _deselect();
   }
   status = search(search_string, search_options);
   s_params.m_status = status;
   if (!status) {
      _MaybeUnhideLine();
      _ds_update_current_mark();
      _ds_select_match(0);
      _ds_update_editor_scroll(editorctl_wid, form_wid);
      _deselect(s_params.m_orig_mark);
      _select_char(s_params.m_orig_mark, 'EN');
      if (s_params.m_search_mark >= 0) {
         _free_selection(s_params.m_search_mark);
         s_params.m_search_mark = -1;
      }
   }
   _default_option(VSOPTION_INITIALLY_DISABLE_EDITOR_CONTROL_KEY_INPUT,0);
}

static bool _ds_on_mark_pos(int mark_id)
{
   if (mark_id < 0) {
      return false;
   }
   save_pos(auto p);
   cur_pos := point('l')" "p_col" "point();
   _begin_select(mark_id); 
   last_pos := point('l')" "p_col" "point();
   restore_pos(p);
   return (cur_pos:==last_pos);
}

static void _ds_reset_editor_scroll(int editorctl_wid, int form_wid)
{
   editorctl_wid._refresh_scroll();
   form_wid.p_y = 0;
}

static void _ds_update_editor_scroll(int editorctl_wid, int form_wid)
{
   get_window_id(auto orig_wid);

   activate_window(form_wid);
   search_string := _findstring.p_text;
   replace_string := _replacestring.p_text;
   replace_mode := _replaceframe.p_visible;
   form_wid._get_window(auto fx, auto fy, auto fw, auto fh);
   _lxy2dxy(form_wid.p_xyscale_mode, fx, fy);
   _lxy2dxy(form_wid.p_xyscale_mode, fw, fh);

   activate_window(editorctl_wid);
   _refresh_scroll();
   at_mark := _ds_on_mark_pos(s_params.m_match_mark);
   update_tooltip := false;
   if (replace_mode) {
      if (def_disable_replace_tooltip || (search_string :== '') || (replace_string :== '') ||
          s_params.m_status || (s_params.m_lastModified != editorctl_wid.p_LastModified) ||
          (s_params.m_match_mark < 0) || !at_mark) {
         update_tooltip = false;
      } else {
         update_tooltip = true;
      }
   }
   if (!s_params.m_status && at_mark) {
      tx := p_cursor_x; ty := p_cursor_y; th := p_font_height;
      if (replace_mode && update_tooltip) {
         th = (p_font_height * 2);
      }
      // try adjusting scroll pos first
      if (ty < fh) {
         set_scroll_pos(p_left_edge, fh + th + 1);
         _refresh_scroll();
         tx = p_cursor_x; ty = p_cursor_y;
      }
      if (ty < fh) {
         fy =_dy2ly(form_wid.p_xyscale_mode, ty + th + 1);
         form_wid.p_y = fy;

      } else if (ty + th > fh) {
         // re-anchor to top
         if (fy > 0) {
            form_wid.p_y = 0;
         }
      }

   } else {
      if (fy > 0) {
         form_wid.p_y = 0;
      }
   }

   if (replace_mode) {
      _ds_update_tooltip(editorctl_wid, search_string, replace_string);
   }
   refresh();
   activate_window(orig_wid);
}

static void _ds_reset_match_marker()
{
   if (s_params.m_match_mark >= 0) {
      _free_selection(s_params.m_match_mark);
      s_params.m_match_mark = -1;
   }

   s_params.m_match_length = 0;
   s_params.m_match_start = 0;

   if (s_params.m_marker_id >= 0) {
      if (!_StreamMarkerGet(s_params.m_marker_id, auto info)) {
         if (s_params.m_disable_occurences) {
            _StreamMarkerRemove(s_params.m_marker_id);
         } else {
            // change marker color
            _StreamMarkerSetTextColor(s_params.m_marker_id, CFG_INC_SEARCH_MATCH);
            _StreamMarkerSetType(s_params.m_marker_id, gDSMarkerType);
         }
      }
      s_params.m_marker_id = -1;
   }
}

static void _ds_begin_next(int editorctl_wid, int search_range)
{
   if (search_range == VSSEARCHRANGE_CURRENT_PROC) {
      if (s_params.m_proc_mark >= 0) {
         if (!editorctl_wid._in_selection(s_params.m_proc_mark)) {
            _free_selection(s_params.m_proc_mark);
            s_params.m_proc_mark = -1;
            s_params.m_update = true;
         }
      } else {
         if ((editorctl_wid.p_lexer_name != '') && editorctl_wid._in_function_scope()) {
            s_params.m_update = true;
         }
      }

   } else if (search_range == VSSEARCHRANGE_CURRENT_SELECTION) {
      mark_id := _duplicate_selection('');
      if (!editorctl_wid.select_active2()) {
         if (s_params.m_last_mark >= 0) {
            s_params.m_last_mark = -1;
            s_params.m_last_mark_info = '';
            s_params.m_update = true;
         }
      } else {
         if (s_params.m_last_mark != mark_id) {
            s_params.m_last_mark = -1;
            s_params.m_last_mark_info = '';
            s_params.m_update = true;
         } else {
            info := editorctl_wid._ds_get_sel_info(mark_id);
            if (info != s_params.m_last_mark_info) {
               s_params.m_last_mark = -1;
               s_params.m_last_mark_info = '';
               s_params.m_update = true;
            }
         }

         // lock selection
         style := _select_type('', 'S');
         if ((editorctl_wid._cursor_move_deselects() || editorctl_wid._cursor_move_extendssel()) && style == 'C') {
            _select_type('', 'S', 'E');
         }      
      }
   }
}

static void _ds_check_start_mark(int search_range)
{
   if (search_range == VSSEARCHRANGE_ALL_BUFFERS ||
       search_range == VSSEARCHRANGE_PROJECT ||
       search_range == VSSEARCHRANGE_WORKSPACE) {
      return;
   }

   if (!s_params.m_start_wrap) {
      return;
   }

   if (s_params.m_start_mark >= 0) {
      offset := _QROffset();
      save_pos(auto p);
      _begin_select(s_params.m_start_mark);
      mark_offset := _QROffset();
      restore_pos(p);
      if (offset >= mark_offset) {
         message("Past starting point for search/replace"); _beep();

         // clear match/status
         if (search_range != VSSEARCHRANGE_CURRENT_SELECTION) {
             _deselect();
         }
         _ds_reset_start_mark();
      }
   }
}

static int doNext(bool doPrev=false, bool doReplaceNext=false, bool closeOnExit=false)
{
   form_wid := p_active_form.p_window_id;
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      return STRING_NOT_FOUND_RC;
   }
   _mffindNoMore(1);
   _mfrefNoMore(1);
   search_string := _findstring.p_text;
   if (search_string :== '') {
      return 0;
   }
   search_options := _ds_get_search_options();
   search_range := _ds_get_search_range();
   replace_string := _replacestring.p_text;
   replace_mode := _replaceframe.p_visible;
   reverse_search := (pos('-', search_options) != 0);
   _ds_begin_next(editorctl_wid, search_range);
   if (s_params.m_update) {
      doUpdate();
   }
   _ds_save_state();
   status := s_params.m_status;
   search_wrapped := false;
   at_mark := editorctl_wid._ds_on_mark_pos(s_params.m_match_mark);
   if (status == -1) {
      // editor may have been reset
      // check if there is a current match marker, may need to use repeat_search for next
      if (at_mark) {
         status = 0;
      }
   } else if (status == STRING_NOT_FOUND_RC) {
      old_wrap := old_search_flags & VSSEARCHFLAG_WRAP;
      if (!old_wrap && (doPrev != s_params.m_match_prev) && (s_params.m_num_matches > 0)) {
         // changing directions, reset to default search
         status = -1;
      }
   }
   if (replace_mode) {
      s_params.m_tooltip = true;
   }
   activate_window(editorctl_wid);

   // clear old mark
   if (old_search_mark != '') {
      _free_selection(old_search_mark);
      old_search_mark = '';
   }
   
   buf_name := editorctl_wid.p_buf_name;
   buf_id := editorctl_wid.p_buf_id;
   _ds_begin_mark(search_options, search_range, auto mark_info);
   ignore_switchbuf = true;
   if (status == -1) {
      options := search_options;
      if (reverse_search && doPrev) {
         options = stranslate(options, '', '-');
      } else if (doPrev) {
         options :+= '-';
      }
      status = _ds_search(search_string, options, true);
      if (status && status != INVALID_REGULAR_EXPRESSION_RC) {
         save_search(old_search_string, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
         if (reverse_search) {
            old_search_flags |= VSSEARCHFLAG_REVERSE;
         } else {
            old_search_flags &= ~VSSEARCHFLAG_REVERSE;
         }
         status = _ds_next(search_string, search_options, search_range, doPrev, search_wrapped, false);
      }

   } else {
      status = _ds_next(search_string, search_options, search_range, doPrev, search_wrapped, doReplaceNext);
   }
   ignore_switchbuf = false;

   save_search(old_search_string, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
   if (reverse_search) {
      old_search_flags |= VSSEARCHFLAG_REVERSE;
   } else {
      old_search_flags &= ~VSSEARCHFLAG_REVERSE;
   }
   old_search_range = search_range;
   if (!status && old_search_flags & VSSEARCHFLAG_MARK) {
      old_search_mark = _duplicate_selection();
   }
   _ds_end_mark(mark_info);
   if (!status && (editorctl_wid != p_window_id)) {
      if (closeOnExit) {
         _MaybeUnhideLine();
         _deselect();
         _ds_select_match(search_range);
         if (replace_mode) {
            _ds_dismiss_tooltip(editorctl_wid);
         }
         _gui_find_dismiss();
         _default_option(VSOPTION_INITIALLY_DISABLE_EDITOR_CONTROL_KEY_INPUT,0);
         save_last_search(search_string, search_options);

      } else {
         _post_call(_ds_reload_form, p_window_id);
      }
      return status;
   }
   s_params.m_status = status;
   s_params.m_match_prev = doPrev;
   if (!status) {
      _MaybeUnhideLine();
      _ds_update_current_mark();
      _deselect(s_params.m_search_mark);
      _select_char(s_params.m_search_mark, 'EN');
      _ds_select_match(search_range);
      p_scroll_left_edge = -1;
      if (search_wrapped && !s_params.m_start_wrap) {
         s_params.m_start_wrap = true;
      }
   } else {
      if (replace_mode) {
         _ds_dismiss_tooltip(editorctl_wid);
      }
      _ds_reset_match_marker();
   }

   activate_window(form_wid);
   _findstring._append_retrieve(_control _findstring, _findstring.p_text, "_tbfind_form._findstring");
   P_USER_MINIFIND_FIND_LIST_REFRESH('');
   if (closeOnExit) {
      ctl_close.call_event(_control ctl_close, LBUTTON_UP, "W");
      return status;
   }
   _ds_update_editor_scroll(editorctl_wid, form_wid);
   _ds_update_match_label(form_wid);
   return status;
}

static void doReplace(bool doAll=false, bool doPreview=false)
{
   form_wid := p_active_form.p_window_id;
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      return;
   }
   search_string := _findstring.p_text;
   if (search_string :== '') {
      return;
   }
   replace_string := _replacestring.p_text;
   search_options := _ds_get_search_options();
   search_range := _ds_get_search_range();
   _ds_save_state();
   if (!doAll) {
      s_params.m_tooltip = true;

      if (s_params.m_status || (s_params.m_lastModified != editorctl_wid.p_LastModified)) {
         if (!doUpdate()) {
            status := doNext(false);
            if (!status) {
               editorctl_wid._ds_check_start_mark(search_range);
            }
         }
         return;
      }

      // check position from last match
      if (!editorctl_wid._ds_on_mark_pos(s_params.m_match_mark)) {
         if (doNext(false)) {
            message("No more occurrences");
         }
         return;
      }

      // TODO this could be better
      if (editorctl_wid._QReadOnly()) {
         int status = editorctl_wid._prompt_readonly_file();
         if (status) {
            return;
         }
      }
   }

   activate_window(editorctl_wid);
   _ds_begin_mark(search_options, search_range, auto mark_info);
   ignore_text_change = true;
   status := STRING_NOT_FOUND_RC;
   if (doAll) {
      show_results := s_params.m_listreplace;
      show_highlights := (pos('$', search_options) != 0);
      grep_id := _ds_set_grep_buffer_id(s_params.m_grep_id);

      save_pos(auto p);
      wrap_search :=  (pos('p', search_options, 1, 'I') != 0);
      if (wrap_search) {
         search_mark := (pos('m', search_options, 1, 'I') != 0);
         if (search_mark && select_active2()) {
            _begin_select(); _begin_line();
         } else {
            top();
         }
      }
      status = replace_buffer_text(search_string, search_options'*', replace_string, search_range, doPreview, show_highlights, show_results, s_params.m_mfflags, grep_id, false);
      _ds_dismiss_tooltip(editorctl_wid);
      if (search_range == VSSEARCHRANGE_CURRENT_PROC) {
         _deselect();   
         s_params.m_proc_mark = -1; // mark already deleted
      }

      // clear last match
      s_params.m_status = -1;
      if (s_params.m_match_mark >= 0) {
         _free_selection(s_params.m_match_mark);
         s_params.m_match_mark = -1;
      }
      s_params.m_match_length = 0;
      s_params.m_match_start = 0;
      restore_pos(p);

   } else {
      restore_search(search_string, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
      _begin_select(s_params.m_match_mark);
      status = search_replace(replace_string);
      s_params.m_match_replace = match_length('P');
      save_search(old_search_string, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
      _ds_end_mark(mark_info);
      if (!status) {
         msg := "Replace";
         msg :+= ' "':+search_string:+'", "':+replace_string:+'"';
         if (search_options:!= '') {
            msg :+= ', ':+_get_search_options_label(search_options);
         }
         if (search_range != VSSEARCHRANGE_CURRENT_BUFFER) {
            msg :+= ', ':+_get_search_range_label(search_range);
         }
         message(msg);
      } else {
         message("Replace: "get_message(status));
      }
   }
   old_replace_string = replace_string;
   _updateTextChange();
   ignore_text_change = false;

   activate_window(form_wid);
   _replacestring._append_retrieve(_control _replacestring, _replacestring.p_text, "_tbfind_form._replacestring");
   P_USER_MINIFIND_REPLACE_LIST_REFRESH('');

   if (!status) {
      // buffer modified, update markers
      if (!doUpdate()) {
         if (!doAll) {
            status = doNext(false, true);
            if (!status) {
               editorctl_wid._ds_check_start_mark(search_range);
            }

            // swap find_next with search_replace()
            _macro('m', _macro('s'));
            _macro_delete_line();
            _macro_call_maybe_stop('search_replace', replace_string, 'R');
            _macro_call('_deselect');
         }

      } else {
         _ds_reset_editor_scroll(editorctl_wid, form_wid);
         // clear last match
         s_params.m_status = -1;
         if (s_params.m_match_mark >= 0) {
            _free_selection(s_params.m_match_mark);
            s_params.m_match_mark = -1;
         }
         s_params.m_match_length = 0;
         s_params.m_match_start = 0;
         _ds_update_match_label(form_wid);
         set_find_next_msg("Find", search_string, search_options, search_range);
         if (search_range != VSSEARCHRANGE_CURRENT_SELECTION) {
            _deselect();
         }
         message("No more occurrences");
      }
   }
}

static void doListAll(int grep_id = -1)
{
   form_wid := p_active_form.p_window_id;
   focus_wid := _get_focus();
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      return;
   }

   search_string := _findstring.p_text;
   search_options := _ds_get_search_options();
   search_range := _ds_get_search_range();
   grep_id = _ds_set_grep_buffer_id(grep_id);
   colors := _findcoloroptions.p_text;
   activate_window(editorctl_wid);

   mfflags := s_params.m_mfflags;
   if (mfflags & MFFIND_MATCHONLY) {
      mfflags &= ~MFFIND_SINGLELINE;
   }
   grep_before_lines := 0; grep_after_lines := 0;
   if (!(mfflags & MFFIND_MATCHONLY) && !(mfflags & MFFIND_FILESONLY)) {
      grep_before_lines = (s_params.m_grep_ab) ? s_params.m_grep_before_lines : 0;
      grep_after_lines = (s_params.m_grep_ab) ? s_params.m_grep_after_lines : 0;
   }
   switch (search_range) {
   case VSSEARCHRANGE_CURRENT_BUFFER:
   case VSSEARCHRANGE_CURRENT_SELECTION:
   case VSSEARCHRANGE_CURRENT_PROC:
      mfflags &= ~MFFIND_FILESONLY;
      break;
   }

   list_all_occurrences(search_string, search_options, search_range, mfflags, grep_id, grep_before_lines, grep_after_lines);
   activate_window(form_wid);
   if (focus_wid && _iswindow_valid(focus_wid)) {
      focus_wid._set_focus();
   }
   form_wid.ctl_close.call_event(_control ctl_close, LBUTTON_UP, "W");
}

static void doHighlight()
{
   form_wid := p_active_form.p_window_id;
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      return;
   }

   search_string := _findstring.p_text;
   search_options := _ds_get_search_options();
   search_range := _ds_get_search_range();
   colors := _findcoloroptions.p_text;
   activate_window(editorctl_wid);
   highlight_all_occurrences(search_string, search_options, search_range);
   activate_window(form_wid);
   ctl_close.call_event(_control ctl_close, LBUTTON_UP, "W");
}

static void doBookmarks()
{
   form_wid := p_active_form.p_window_id;
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      return;
   }

   search_string := _findstring.p_text;
   search_options := _ds_get_search_options();
   search_range := _ds_get_search_range();
   colors := _findcoloroptions.p_text;
   activate_window(editorctl_wid);
   bookmark_all_occurrences(search_string, search_options, search_range);
   activate_window(form_wid);
   ctl_close.call_event(_control ctl_close, LBUTTON_UP, "W");
}

static void doMultiSelect()
{
   form_wid := p_active_form.p_window_id;
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      return;
   }
   search_string := _findstring.p_text;
   search_options := _ds_get_search_options();
   search_range := _ds_get_search_range();
   colors := _findcoloroptions.p_text;
   activate_window(editorctl_wid);
   multiselect_all_occurrences(search_string, search_options, search_range);
   activate_window(form_wid);
   ctl_close.call_event(_control ctl_close, LBUTTON_UP, "W");
}

static _str _ds_get_word_completion()
{
   match := "";
   int i = _text_colc(p_col, "P");
   lineLen := _line_length();
   if(i > lineLen) {
      return "";
   }
   save_pos(auto p);
   p_col = _text_colc(i, "I");
   status := 0;
   int origOffset = (int)_QROffset();
   int mark = _alloc_selection();
   pselect_word(mark);
   _free_selection(mark);

   int newOffset = (int)_QROffset();
   if(newOffset > origOffset) {
      int matchOffset = origOffset;
      int matchLength = newOffset - origOffset;
      match = get_text(matchLength, matchOffset);
   }
   restore_pos(p);
   return match;
}

static void doWordCompletion()
{
   form_wid := p_active_form.p_window_id;
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      return;
   }
   search_string := _findstring.p_text;
   activate_window(editorctl_wid);
   save_pos(auto p);
   if (s_params.m_status || (s_params.m_match_mark < 0 || !_ds_on_mark_pos(s_params.m_match_mark))) {
      search_string = "";
   } 
   // look ahead if on current match
   if (!s_params.m_status && s_params.m_match_length > 0 && s_params.m_match_mark > 0 && _ds_on_mark_pos(s_params.m_match_mark)) {
      //long start = _nrseek();
      _nrseek(s_params.m_match_start + s_params.m_match_length);
   }
   word := _ds_get_word_completion();
   restore_pos(p);
   activate_window(form_wid);
   if (word :!= '') {
      _findstring.p_text = search_string:+word;
      _findstring._refresh_scroll();
      _findstring.end_line();
   }
}

static void doCurrentWordAtCursor()
{
   form_wid := p_active_form.p_window_id;
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      return;
   }
   word := editorctl_wid.cur_word(auto junk, '', true);
   if (word :!= '') {
      if ((def_mfsearch_init_flags & MFSEARCH_INIT_AUTO_ESCAPE_REGEX) && ctl_regex.p_value) {
         options := 'R';
         re_flags := P_USER_MINIFIND_RE();
         if (re_flags & VSSEARCHFLAG_PERLRE) {
            options = 'L';
         } else if (re_flags & VSSEARCHFLAG_VIMRE) {
            options = '~';
         } else if (re_flags & VSSEARCHFLAG_WILDCARDRE) {
            options = '&';
         } else {
            options = 'R';
         }
         word = _escape_re_chars(word, options);
      }
      _findstring.p_text = word;
      _findstring._refresh_scroll();
      _findstring.end_line();
   }
}

static void doGetCurrentSelection()
{
   form_wid := p_active_form.p_window_id;
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false) || !editorctl_wid.select_active2()) {
      return;
   }

   mark_locked := 0;
   if (_select_type('', 'S') == 'C') {
      mark_locked = 1;
      _select_type('', 'S', 'E');
   }
   editorctl_wid.filter_init();
   editorctl_wid.filter_get_string(auto word);
   editorctl_wid.filter_restore_pos();
   if (mark_locked) {
      _select_type('', 'S','C');
   }

   if (word :!= '') {
      if ((def_mfsearch_init_flags & MFSEARCH_INIT_AUTO_ESCAPE_REGEX) && ctl_regex.p_value) {
         options := 'R';
         re_flags := P_USER_MINIFIND_RE();
         if (re_flags & VSSEARCHFLAG_PERLRE) {
            options = 'L';
         } else if (re_flags & VSSEARCHFLAG_VIMRE) {
            options = '~';
         } else if (re_flags & VSSEARCHFLAG_WILDCARDRE) {
            options = '&';
         } else {
            options = 'R';
         }
         word = _escape_re_chars(word, options);
      }
      _findstring.p_text = word;
      _findstring._refresh_scroll();
      _findstring.end_line();
   }
}

void _switchbuf_docsearch(_str oldbuffname, _str flag)
{
   if (ignore_switchbuf) {
      return;
   }
   int form_wid = _find_formobj('_document_search_form','N');
   if (!form_wid) {
      return;
   }
   // "Q" option. Not sure if this is the best course
   // of action don't want a Slick-C stack.
   if (!_isEditorCtl(false)) {
      return;
   }
   get_window_id(auto orig_wid);
   activate_window(form_wid);
   editorctl_wid := P_USER_MINIFIND_WID();
   activate_window(orig_wid);
   if (DocSearchForm.switchBuffer(editorctl_wid, p_buf_id, p_buf_name)) {
      _ds_unlink_editor_window(editorctl_wid);
      _ds_set_editor_wid(form_wid, editorctl_wid);
      form_wid.doUpdate();
   }
}

static void _ds_idle_update(int form_wid, int editorctl_wid)
{
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      return;
   }
   search_range := _ds_get_search_range();
   if (s_params.m_lastModified != editorctl_wid.p_LastModified) {
      s_params.m_status = -1;
      if (editorctl_wid.select_active2() && (search_range != VSSEARCHRANGE_CURRENT_SELECTION)) {
         mark_id := _duplicate_selection('');
         temp_id := _alloc_selection(); _show_selection(temp_id);
         doUpdate();
         if (s_params.m_tooltip) {
            _ds_dismiss_tooltip(editorctl_wid);
         }
         _show_selection(mark_id);
         _free_selection(temp_id);

      } else {
         doUpdate();
         if (s_params.m_tooltip) {
            _ds_dismiss_tooltip(editorctl_wid);
         }
      }
      refresh("A");
   } else {
      if (search_range == VSSEARCHRANGE_CURRENT_PROC) {
         if (s_params.m_proc_mark >= 0) {
            if (!editorctl_wid._in_selection(s_params.m_proc_mark)) {
               _free_selection(s_params.m_proc_mark);
               s_params.m_proc_mark = -1;
               s_params.m_status = -1;
               doUpdate();
               refresh("A");
            }
         }

      } else if (search_range == VSSEARCHRANGE_CURRENT_SELECTION) {
         mark_id := _duplicate_selection('');
         if (!editorctl_wid.select_active2()) {
            if (s_params.m_last_mark >= 0) {
               s_params.m_last_mark = -1;
               s_params.m_last_mark_info = '';
               s_params.m_status = -1;
               doUpdate();
               refresh("A");
            }
         } else {
            info := editorctl_wid._ds_get_sel_info(mark_id);
            if (info != s_params.m_last_mark_info) {
               s_params.m_last_mark = -1;
               s_params.m_last_mark_info = '';
               s_params.m_status = -1;
               doUpdate();
               refresh("A");
            } else {
               if (s_params.m_last_mark != mark_id) {
                  s_params.m_last_mark = mark_id;
               }
            }
         }
      }
   }

   replace_mode := _replaceframe.p_visible;
   if (replace_mode && s_params.m_tooltip) {
      scroll_info := editorctl_wid.p_scroll_left_edge' 'editorctl_wid._scroll_page();
      if (!editorctl_wid._ds_on_mark_pos(s_params.m_match_mark)) {
         _ds_dismiss_tooltip(editorctl_wid);
      } else if (s_params.m_scroll_info != scroll_info) {
         _ds_dismiss_tooltip(editorctl_wid);
      }
   }
}

void _UpdateDocsearch(bool AlwaysUpdate=false)
{
   if (def_gui_find_default) {
      return;
   }
   if (!AlwaysUpdate && _idle_time_elapsed() < 250) {
      return;
   }
   int form_wid = _find_formobj('_document_search_form','N');
   if (!form_wid) {
      return;
   }
   get_window_id(auto orig_wid);
   activate_window(form_wid);
   _ds_idle_update(form_wid, P_USER_MINIFIND_WID());
   activate_window(orig_wid);
}

class KeepSearchFunctor : se.search.ISearchFunctor {
   bool exec(_str search_string, _str search_options) {
      if (_QReadOnly()) {
         int status = _prompt_readonly_file();
         if (status == COMMAND_CANCELLED_RC) {
            return(true);
         } else if (status) {
            return(false);
         }
      }
      keep_search(search_string, search_options);
      return(false);
   }
};

void ds_keep_search(_str search_string, _str search_options, int search_range)
{
   KeepSearchFunctor func;
   FindNextFile.forEachRange(search_string, search_options, search_range, func);
}

static void doKeepSearch()
{
   form_wid := p_active_form.p_window_id;
   focus_wid := _get_focus();
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      return;
   }
   search_string := _findstring.p_text;
   search_options := _ds_get_search_options();
   search_range := _ds_get_search_range();
   activate_window(editorctl_wid);
   _macro('m', _macro('s'));
   _macro_call('ds_keep_search', search_string, search_options, search_range);
   ds_keep_search(search_string, search_options, search_range);
   activate_window(form_wid);
   if (focus_wid && _iswindow_valid(focus_wid)) {
      focus_wid._set_focus();
   }
   form_wid.ctl_close.call_event(_control ctl_close, LBUTTON_UP, "W");
}

class DeleteSearchFunctor : se.search.ISearchFunctor {
   bool exec(_str search_string, _str search_options) {
      if (_QReadOnly()) {
         int status = _prompt_readonly_file();
         if (status == COMMAND_CANCELLED_RC) {
            return(true);
         } else if (status) {
            return(false);
         }
      }
      delete_search(search_string, search_options'*');
      return(false);
   }
};

void ds_delete_search(_str search_string, _str search_options, int search_range)
{
   DeleteSearchFunctor func;
   FindNextFile.forEachRange(search_string, search_options, search_range, func);
}

static void doDeleteSearch()
{
   form_wid := p_active_form.p_window_id;
   focus_wid := _get_focus();
   editorctl_wid := P_USER_MINIFIND_WID();
   if (!editorctl_wid || !_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl(false)) {
      return;
   }
   search_string := _findstring.p_text;
   search_options := _ds_get_search_options();
   search_range := _ds_get_search_range();
   activate_window(editorctl_wid);
   _macro('m', _macro('s'));
   _macro_call('ds_delete_search', search_string, search_options, search_range);
   ds_delete_search(search_string, search_options, search_range);
   activate_window(form_wid);
   if (focus_wid && _iswindow_valid(focus_wid)) {
      focus_wid._set_focus();
   }
   form_wid.ctl_close.call_event(_control ctl_close, LBUTTON_UP, "W");
}


