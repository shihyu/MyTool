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
#include "vsevents.sh"
#include "markers.sh"
#include "mfsearch.sh"
#include "xml.sh"
#import "bgsearch.e"
#import "bookmark.e"
#import "clipbd.e"
#import "compile.e"
#import "complete.e"
#import "context.e"
#import "cutil.e"
#import "dir.e"
#import "dlgman.e"
#import "docsearch.e"
#import "files.e"
#import "guicd.e"
#import "guifind.e"
#import "guiopen.e"
#import "guireplace.e"
#import "listbox.e"
#import "main.e"
#import "makefile.e"
#import "markfilt.e"
#import "mouse.e"
#import "mfsearch.e"
#import "mprompt.e"
#import "recmacro.e"
#import "combobox.e"
#import "help.e"
#import "refactor.e"
#import "optionsxml.e"
#import "picture.e"
#import "pip.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "propertysheetform.e"
#import "pushtag.e"
#import "saveload.e"
#import "search.e"
#import "sellist.e"
#import "seltree.e"
#import "slickc.e"
#import "sstab.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbcmds.e"
#import "tbdeltasave.e"
#import "tbsearch.e"
#import "toolbar.e"
#import "se/ui/twevent.e"
#import "util.e"
#import "wkspace.e"
#import "se/datetime/DateTimeFilters.e"
#import "se/datetime/DateTime.e"
#require "se/search/SearchResults.e"
#require "se/search/FindNextFile.e"
#import "se/search/SearchExpr.e"
#import "se/search/SearchColors.e"
#import "se/tags/TaggingGuard.e"
#import "se/ui/toolwindow.e"
#import "se/ui/twautohide.e"
#endregion
 
using namespace se.datetime;
 
using se.search.SearchResults;
using se.search.FindNextFile;

// current find toolbar mode
static const VSSEARCHMODE_FIND=              0;
static const VSSEARCHMODE_FINDINFILES=       1;
static const VSSEARCHMODE_REPLACE=           2;
static const VSSEARCHMODE_REPLACEINFILES=    3;
static const VSSEARCHMODE_FILES=             4;

static _str PUSER_LAST_GREP_ID(...) {
   if (arg()) _findgrep.p_user=arg(1);
   return _findgrep.p_user;
}
static _str PUSER_FILETYPELIST_INIT_DONE(...) {
   if (arg()) _findfiletypes.p_user=arg(1);
   return _findfiletypes.p_user;
}
static _str PUSER_FINDSTRING_INIT_DONE(...) {
   if (arg()) _findstring.p_user=arg(1);
   return _findstring.p_user;
}
static _str PUSER_REPLACESTRING_INIT_DONE(...) {
   if (arg()) _replacestring.p_user=arg(1);
   return _replacestring.p_user;
}
static _str PUSER_EXCLUDESTRING_INIT_DONE(...) {
   if (arg()) _findexclude.p_user=arg(1);
   return _findexclude.p_user;
}
static _str PUSER_FINDFILES_INIT_DONE(...) {
   if (arg()) _findfiles.p_user=arg(1);
   return _findfiles.p_user;
}
static _str PUSER_LAST_SHOW_SEARCH_OPTIONS(...) {
   if (arg()) _search_opt_button.p_user=arg(1);
   return _search_opt_button.p_user;
}
static _str PUSER_LAST_SHOW_RESULTS_OPTIONS(...) {
   if (arg()) _result_opt_button.p_user=arg(1);
   return _result_opt_button.p_user;
}

static const DLGINFO_CURRENT_SEARCH_WID= 0;
static const DLGINFO_CURRENT_BUFFER= 1;
static const DLGINFO_TIMER_ID= 2;

/**
 * Hide tab bar in find tool window.
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_find_hide_tabs = false;

/**
 * Maximum recommended number of bookmarks that should
 * be added to a buffer in a find all operation.
 *
 * @default 128
 * @categories Configuration_Variables
 */
int def_find_high_added_bookmarks = 128;

/**
 * Extra paramters for find/replace int files for extra
 * attributes (HIDDEN/SYSTEM) for Windows users.
 *
 * @default "
 * @categories Configuration_Variables
 */
_str def_find_file_attr_options = "";

/**
 * Maximum recommended number of cursors that should
 * be added to a buffer in a find all operation.
 *
 * @default 128
 * @categories Configuration_Variables
 */
int def_find_high_added_cursors = 128;

/**
 * Additional default options for Find and Replace tool window not
 * handled by _default_option('s') flags.
 *
 * @default 
 * @categories Configuration_Variables
 */
_str def_find_misc_options = "";

static bool ignore_change = false;
static int gon_create_init_find_mode = VSSEARCHMODE_FIND;
static int gon_create_window_id = -1;

static int gIncMarkerType;
static int gIncScrollMarkerType;


int _tbGetActiveFindAndReplaceForm()
{
   return tw_find_form('_tbfind_form');
}

/*** commands ***/

/**
 * Searches for a string you specify.  The Find and Replace tool window is displayed to prompt you for
 * the search string and options.
 *
 * @return Returns 0 if successful.
 * @see find_next
 * @see gui_replace
 * @see find
 * @see replace
 * @see find_prev
 * @appliesTo Edit_Window, Editor_Control
 * @categories File_Functions, Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 */
_command int tool_gui_find(...) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (p_active_form.p_modal) {
      return gui_find_modal();
   }
   mode := VSSEARCHMODE_FIND;
   if (!_isEditorCtl(false)) {
      mode = VSSEARCHMODE_FINDINFILES;
   }
   toolShowFind(mode, p_window_id, arg(1));
   _macro_delete_line();
   return 0;
}

_command void find_in_files(...) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   toolShowFind(VSSEARCHMODE_FINDINFILES, p_window_id, arg(1), arg(2));
   _macro_delete_line();
}

_command void find_in_workspace(...) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (isEclipsePlugin()) {
      int current_flags = def_mfsearch_init_flags;
      def_mfsearch_init_flags = MFSEARCH_INIT_SELECTION|MFSEARCH_INIT_AUTO_ESCAPE_REGEX;
      _eclipse_get_workspace_dir(auto wspace_dir);
      toolShowFind(VSSEARCHMODE_FINDINFILES, p_window_id, arg(1), wspace_dir);
      def_mfsearch_init_flags = current_flags;
   } else {
      toolShowFind(VSSEARCHMODE_FINDINFILES, p_window_id, arg(1), MFFIND_WORKSPACE_FILES);
   }
   _macro_delete_line();
}

_command void find_in_project(...) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (isEclipsePlugin()) {
      _eclipse_get_project_dir(auto proj_dir);
      toolShowFind(VSSEARCHMODE_FINDINFILES, p_window_id, arg(1), proj_dir);
   } else {
      toolShowFind(VSSEARCHMODE_FINDINFILES, p_window_id, arg(1), MFFIND_PROJECT_FILES);
   }
   _macro_delete_line();
}

_command void find_in_all_buffers(...) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   toolShowFind(VSSEARCHMODE_FINDINFILES, p_window_id, arg(1), MFFIND_BUFFERS);
   _macro_delete_line();
}

_command void find_in_current_buffer(...) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   toolShowFind(VSSEARCHMODE_FINDINFILES, p_window_id, arg(1), MFFIND_BUFFER);
   _macro_delete_line();
}

int _OnUpdate_tool_gui_replace(CMDUI &cmdui,int target_wid,_str command)
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

/**
 * Searches for a string you specify and replaces it with
 * another string you specify.  The Find and Replace tool window is
 * displayed to prompt you for the search and replace
 * options.
 *
 * @return Returns 0 if successful.
 *
 * @see find_next
 * @see gui_find
 * @see find
 * @see replace
 * @see gui_replace2
 * @see find_prev
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories File_Functions, Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 */
_command int tool_gui_replace(...) name_info(','VSARG2_REQUIRES_MDI)
{
   mode := VSSEARCHMODE_REPLACE;
   if (!_isEditorCtl(false)) {
      mode = VSSEARCHMODE_REPLACEINFILES;
   }
   toolShowFind(mode, p_window_id, arg(1));
   _macro_delete_line();
   return 0;
}

_command void replace_in_files(...) name_info(','VSARG2_EDITORCTL)
{
   toolShowFind(VSSEARCHMODE_REPLACEINFILES, p_window_id, arg(1));
   _macro_delete_line();
}

// deprecated commands
_command void find_collapsed() name_info(','VSARG2_EDITORCTL)
{
    tool_gui_find();
}

// deprecated commands
_command void replace_collapsed() name_info(','VSARG2_EDITORCTL)
{
   tool_gui_replace();
}

_command void find_file() name_info(',')
{
   toolShowFind(VSSEARCHMODE_FILES, p_window_id, arg(1));
   _macro_delete_line();
}

static void toolShowFind(int mode = -1, int window_id = -1, _str options = '', _str path = '')
{
   int was_recording = _macro();
   if (was_recording) {
      _macro('m', 0);
   }
   already_open := true;
   window_id = _validate_search_buffer(window_id);
   // if object not created, then just let on_load event handle initialization
   //if ( _find_formobj("_tbfind_form", 'n') == 0 ) {
   if (_tbGetActiveFindAndReplaceForm() == 0) {
      already_open = false;
      gon_create_init_find_mode = mode;
      gon_create_window_id = window_id;
   }

   int formid;
   if (isEclipsePlugin()) {
      show('-xy _tbfind_form');
      formid = _find_object('_tbfind_form._findstring');
      if (formid) {
         formid._set_focus();
      }
   } else {
      formid = activate_tool_window('_tbfind_form', true, '_findstring');
   }
   gon_create_window_id = -1;

   if (!formid) {
      return;
   }
   if (already_open) {
      // Initialize mode first since other calls are dependent open
      // the mode setting.
      formid._init_mode(mode);
      formid._init_current_search_buffer(window_id);
      formid._init_findstring(window_id);
   }
   formid._set_search_options(options, path);
   if ( !already_open && !tw_is_docked_window(formid) ) { //force it to resize
      formid._resize_frame_heights(true);
   }
   formid.p_user2 = '';
   _macro('m', was_recording);
   return;
}

void tool_find_update_options(_str search_string, _str replace_string, _str search_options, int search_range, int mfflags, _str misc_options, bool use_defaults = true)
{
   get_window_id(auto orig_wid);
   form_id := _tbGetActiveFindAndReplaceForm();
   if (form_id == 0) {
      return;
   }
   activate_window(form_id);
   ignore_change = true;
   if (search_string != '') {
      _findstring.p_text = search_string;
      _findstring.p_sel_start = 1;
      _findstring.p_sel_length = _findstring.p_text._length();
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
      if (pos('i', search_options, 1, 'I')) {
         _findcase.p_value = 0;
      } else if (pos('e', search_options, 1, 'I')) {
         _findcase.p_value = 1;
      } else {
         _findcase.p_value = 1;
      }

      if (pos('w', search_options, 1, 'I')) {
         _findword.p_value = 1;
      } else {
         _findword.p_value = 0;
      }

      if (pos('[rublRUBL&~]', search_options, 1, 'r')) {
         _findre.p_value = 1;
         _findre_type.p_enabled = true;
         if (pos('r', search_options, 1, 'I')) {
            _findre_type._init_re_type(VSSEARCHFLAG_RE);
         } else if (pos('u', search_options, 1, 'I')) {
            _findre_type._init_re_type(VSSEARCHFLAG_PERLRE);
         } else if (pos('b', search_options, 1, 'I')) {
            _findre_type._init_re_type(VSSEARCHFLAG_PERLRE);
         } else if (pos('l', search_options, 1, 'I')) {
            _findre_type._init_re_type(VSSEARCHFLAG_PERLRE);
         } else if (pos('~', search_options, 1)) {
            _findre_type._init_re_type(VSSEARCHFLAG_VIMRE);
         } else if (pos('&', search_options, 1)) {
            _findre_type._init_re_type(VSSEARCHFLAG_WILDCARDRE);
         }
         _re_button.p_enabled = true;
         _replace_re_button.p_enabled = true;
      } else {
         _findre.p_value = 0;
         _findre_type.p_enabled = false;
         _re_button.p_enabled = false;
         _replace_re_button.p_enabled = false;
      }

      if (pos('?', search_options, 1, 'I')) {
         _findwrap.p_value = 2;
      } else if (pos('p', search_options, 1, 'I')) {
         _findwrap.p_value = 1;
      } else {
         _findwrap.p_value = 0;
      }

      if (pos('>', search_options)) {
         _findcursorend.p_value = 1;
      } else if (pos('<', search_options)) {
         _findcursorend.p_value = 0;
      } else {
         _findcursorend.p_value = 0;
      }

      if (pos('-', search_options)) {
         _findback.p_value = 1;
      } else if (pos('+', search_options)) {
         _findback.p_value = 0;
      } else if (def_keys == "brief-keys") {
         //In brief, if we aren't searching back, we are always searching forward.
         _findback.p_value = 0;
      } else {
         _findback.p_value = 0;
      }

      if (pos('h', search_options, 1, 'I')) {
         _findhidden.p_value = 1;
      } else {
         _findhidden.p_value = 0;
      }
      
      if (pos('v', search_options, 1, 'I')) {
         _replacekeepcase.p_value = 1;
      } else {
         _replacekeepcase.p_value = 0;
      }

      if (pos('$', search_options, 1, 'I')) {
         _replacehilite.p_value = 1;
      } else {
         _replacehilite.p_value = 0;
      }

      colors := _ccsearch_strip_colors_from_options(search_options);
      if (colors != '') {
         _findcolorcheck.p_value = 1;
         _findcoloroptions.p_text = colors;
      } else {
         _findcolorcheck.p_value = 0;
      }  
   }

   if (search_range >= 0) {
      mode := _findtabs.p_ActiveTab;
      if (mode == VSSEARCHMODE_FIND || mode == VSSEARCHMODE_REPLACE) {
         _init_buffer_range(search_range);
      }
   }

   if (mfflags) {
      _set_results_options(mfflags);
   }
  
   if (misc_options != '') {
      if (def_keys == "brief-keys") {
         misc_options = stranslate(misc_options, '', '_findback');
      }
      _init_misc_search_opts(misc_options);
   }

   _update_color_options();
   ignore_change = false;
   activate_window(orig_wid);
}


/*** initialize options ***/
static int _space_controls_y(int ctrl_ids[], int pad_y, int cur_y, int align_x = -1)
{
   int i;
   for (i = 0; i < ctrl_ids._length(); ++i) {
      int wid = ctrl_ids[i];
      if (wid.p_visible) {
         wid.p_y = cur_y + pad_y;
         cur_y = wid.p_y_extent;
         if (align_x >= 0) {
            wid.p_x = align_x;
         }
      }
   }
   return(cur_y);
}

static void _resize_frame_widths(bool force_refresh = false)
{
   widthDiff := p_width - _findtabs.p_width;

   // only care about width changes for this
   if (!widthDiff && !force_refresh) return;

   _findtabs.sstAdjustHeightForNoContent();

   _findtabs.p_width += widthDiff;
   _findframe.p_width += widthDiff;
   _button_frame.p_x += widthDiff;
   _re_button.p_x += widthDiff;
   _replace_re_button.p_x += widthDiff;
   _findfiles_button.p_x += widthDiff;
   _findstring.p_width += widthDiff;
   _replacestring.p_width += widthDiff;
   _findbuffer.p_width += widthDiff;
   _findfiles.p_width += widthDiff;
   _findfiletypes.p_width += widthDiff;
   _editfiletypes.p_x += widthDiff;
   _findexclude.p_width += widthDiff;
   _search_frame.p_width += widthDiff;
   _files_frame.p_width += widthDiff;
   _show_search_options(_findtabs.p_ActiveTab);
   _show_results_options(_findtabs.p_ActiveTab);
   _resize_frame_heights(false);
}

static void _resize_frame_heights(bool resize_form = false)
{
   start_y := 0;
   int ctrl_ids[];
   ctrl_ids._makeempty();
   ctrl_ids[0] = _search_frame.p_window_id;
   ctrl_ids[1] = _files_frame.p_window_id;
   ctrl_ids[2] = _options_frame.p_window_id;
   ctrl_ids[3] = _results_frame.p_window_id;
   int curr_y = _space_controls_y(ctrl_ids, 0, start_y);
   _button_frame.p_y = curr_y;
   _findframe.p_y = _findtabs.p_visible ? _findtabs.p_height : 0;
   int w, h;
   _get_child_extents(_findframe.p_window_id, w, h, true);
   _findframe.p_height = h;
   if (!tw_is_docked_window(p_active_form) && resize_form) {
      int border_height = p_active_form.p_height - _dy2ly(p_active_form.p_xyscale_mode, p_active_form.p_client_height);
      _get_child_extents(p_active_form, w, h, true);
      p_active_form.p_height = border_height + h + 90;
#ifdef not_finished
      if ( !tw_is_auto_raised(p_active_form) && !isEclipsePlugin() ) {
         container_wid := _tbContainerFromWid(p_active_form);
         if (container_wid && container_wid != p_active_form) {
            container_wid.p_height = p_active_form.p_height;
         }
      }
#endif
   }
}

static void _show_search_text(int mode)
{
   switch (mode) {
   case VSSEARCHMODE_FIND:
      _find_label.p_visible         = true;
      ctlsearch_help.p_visible      = true;
      _findstring.p_visible         = true;
      _re_button.p_visible          = true;
      _replace_label.p_visible      = false;
      ctlreplace_help.p_visible     = false;
      _replacestring.p_visible      = false;
      _findbuffer.p_visible         = true;
      _findfiles.p_visible          = false;
      _replace_re_button.p_visible  = false;
      _findfiles_button.p_visible   = false;
      ctllookin_help.p_message="Scope to look for matches in";
      break;
   case VSSEARCHMODE_FINDINFILES:
      _find_label.p_visible         = true;
      ctlsearch_help.p_visible      = true;
      _findstring.p_visible         = true;
      _re_button.p_visible          = true;
      _replace_label.p_visible      = false;
      ctlreplace_help.p_visible     = false;
      _replacestring.p_visible      = false;
      _findbuffer.p_visible         = false;
      _findfiles.p_visible          = true;
      _replace_re_button.p_visible  = false;
      _findfiles_button.p_visible   = true;
      ctllookin_help.p_message="Scope to look for matches in, can be a file name or a top-level directory to search files in";
      break;
   case VSSEARCHMODE_REPLACE:
      _find_label.p_visible         = true;
      ctlsearch_help.p_visible      = true;
      _findstring.p_visible         = true;
      _re_button.p_visible          = true;
      _replace_label.p_visible      = true;
      ctlreplace_help.p_visible     = true;
      _replacestring.p_visible      = true;
      _findbuffer.p_visible         = true;
      _findfiles.p_visible          = false;
      _replace_re_button.p_visible  = true;
      _findfiles_button.p_visible   = false;
      ctllookin_help.p_message="Scope to look for matches in";
      break;
   case VSSEARCHMODE_REPLACEINFILES:
      _find_label.p_visible         = true;
      ctlsearch_help.p_visible      = true;
      _findstring.p_visible         = true;
      _replace_label.p_visible      = true;
      ctlreplace_help.p_visible     = true;
      _replacestring.p_visible      = true;
      _findbuffer.p_visible         = false;
      _findfiles.p_visible          = true;
      _replace_re_button.p_visible  = true;
      _findfiles_button.p_visible   = true;
      ctllookin_help.p_message="Scope to look for matches in, can be a file name or a top-level directory to search files in";
      break;
   case VSSEARCHMODE_FILES:
      _find_label.p_visible         = false;
      ctlsearch_help.p_visible      = false;
      _findstring.p_visible         = false;
      _re_button.p_visible          = false;
      _replace_label.p_visible      = false;
      ctlreplace_help.p_visible     = false;
      _replacestring.p_visible      = false;
      _findbuffer.p_visible         = false;
      _findfiles.p_visible          = true;
      _replace_re_button.p_visible  = false;
      _findfiles_button.p_visible   = true;
      ctllookin_help.p_message="Scope to look for files in, for example, a top-level directory to search";
      break;
   }

   int ctrl_ids[];
   ctrl_ids._makeempty();
   ctrl_ids[0] = _find_label.p_window_id;
   ctrl_ids[1] = _findstring.p_window_id;
   ctrl_ids[2] = _replace_label.p_window_id;
   ctrl_ids[3] = _replacestring.p_window_id;
   ctrl_ids[4] = _lookin_label.p_window_id;
   ctrl_ids[5] = _findbuffer.p_window_id;
   ctrl_ids[6] = _findfiles.p_window_id;
   _space_controls_y(ctrl_ids, 30, 30);
   sizeBrowseButtonToTextBox(_find_label.p_window_id, ctlsearch_help.p_window_id);
   sizeBrowseButtonToTextBox(_replace_label.p_window_id, ctlreplace_help.p_window_id);
   sizeBrowseButtonToTextBox(_lookin_label.p_window_id, ctllookin_help.p_window_id);

   _re_button.p_y = _findstring.p_y;
   _replace_re_button.p_y = _replacestring.p_y;
   _findfiles_button.p_y = _findfiles.p_y;

   int w, h;
   _get_child_extents(_search_frame.p_window_id, w, h, true);
   _search_frame.p_height = h;
}

static void _show_button_frame(int mode)
{
   // we need these to keep track of our button columns
   int button_col1[], button_col2[];
   button_col1._makeempty();
   button_col2._makeempty();

   search_wid := _get_current_search_wid();
   if ( search_wid == "" ) search_wid = 0;

   // show/hide based on current tab
   switch (mode) {
   case VSSEARCHMODE_FIND:
      button_col2[0] = _find_btn.p_window_id;
      _find_btn.p_default = true;
      _replace_btn.p_default = false;
      _replace_btn.p_visible = false;
      _replaceall_btn.p_visible = false;
      _replacepreview_btn.p_visible = false;
      _stop_btn.p_visible = false;
      break;

   case VSSEARCHMODE_FINDINFILES:
      button_col1[0] = _find_btn.p_window_id;
      button_col2[0] = _stop_btn.p_window_id;
      _find_btn.p_default = true;
      _replace_btn.p_default = false;
      _replace_btn.p_visible = false;
      _replaceall_btn.p_visible = false;
      _replacepreview_btn.p_visible = false;
      break;

   case VSSEARCHMODE_REPLACE:
      button_col1[0] = _replace_btn.p_window_id;
      button_col2[0] = _replaceall_btn.p_window_id;
      button_col2[1] = _replacepreview_btn.p_window_id;
      _find_btn.p_default = false;
      _replace_btn.p_default = true;
      _find_btn.p_visible = false;
      _stop_btn.p_visible = false;
      break;

   case VSSEARCHMODE_REPLACEINFILES:
      button_col1[0] = _replace_btn.p_window_id;
      button_col2[0] = _replaceall_btn.p_window_id;
      button_col2[1] = _replacepreview_btn.p_window_id;
      _find_btn.p_default = false;
      _replace_btn.p_default = true;
      _find_btn.p_visible = false;
      _stop_btn.p_visible = false;
      break;

   case VSSEARCHMODE_FILES:
      button_col1[0] = _find_btn.p_window_id;
      button_col2[0] = _stop_btn.p_window_id;
      _find_btn.p_default = true;
      _replace_btn.p_default = false;
      _replace_btn.p_visible = false;
      _replaceall_btn.p_visible = false;
      _replacepreview_btn.p_visible = false;
      _stop_btn.p_visible = true;
      break;
   }
   if (!_haveDiff()) {
      _replacepreview_btn.p_enabled = false;
   }

   // make the buttons in our columns visible
   for ( i := 0; i < button_col1._length(); ++i ) {
      button_col1[i].p_visible = true;
   }
   for ( i = 0; i < button_col2._length(); ++i ) {
      button_col2[i].p_visible = true;
   }

   // space them nicely
   _space_controls_y(button_col1, 0, _find_btn.p_y, 0);
   _space_controls_y(button_col2, 0, _find_btn.p_y, _find_btn.p_width + 20);

   int w, h;
   _get_child_extents(_button_frame.p_window_id, w, h, true);
   _button_frame.p_height = h;
}

static void _update_button_state(int mode)
{
   search_wid := _get_current_search_wid();
   if (search_wid == "") search_wid = 0;

   if (mode == VSSEARCHMODE_FINDINFILES || mode == VSSEARCHMODE_REPLACEINFILES || mode == VSSEARCHMODE_FILES) {
      if (mode == VSSEARCHMODE_FINDINFILES || mode == VSSEARCHMODE_FILES) {
         _find_btn.p_enabled = (gbgm_search_state == 0);
      } else {
         _find_btn.p_enabled = true;
      }
      _stop_btn.p_enabled = (gbgm_search_state != 0);
      _replace_btn.p_enabled        = true;
      _replaceall_btn.p_enabled     = true;
      _replacepreview_btn.p_enabled = true;
   } else {
      if (search_wid == 0) {
         if (mode == VSSEARCHMODE_FIND || mode == VSSEARCHMODE_REPLACE) {
            _find_btn.p_enabled           = false;
            _replace_btn.p_enabled        = false;
            _replaceall_btn.p_enabled     = false;
            _replacepreview_btn.p_enabled = false;
         }
      } else {
         _str bufname = search_wid.p_buf_name;
         if (mode == VSSEARCHMODE_FIND || mode == VSSEARCHMODE_REPLACE) {
            if (_findbuffer.p_text == SEARCH_IN_ALL_BUFFERS ||
                _findbuffer.p_text == SEARCH_IN_ALL_ECL_BUFFERS) {
               int child_windows = _mdi._no_child_windows();
               _find_btn.p_enabled           = (child_windows == 0);
               _replace_btn.p_enabled        = (child_windows == 0);
               _replaceall_btn.p_enabled     = (child_windows == 0);
               _replacepreview_btn.p_enabled = (child_windows == 0);
            } else {
               _find_btn.p_enabled           = (search_wid != 0);
               _replace_btn.p_enabled        = (search_wid != 0);
               _replaceall_btn.p_enabled     = (search_wid != 0);
               _replacepreview_btn.p_enabled = (search_wid != 0);
            }

            if ((bufname :== '') || _isGrepBuffer(bufname) || (beginsWith(bufname, '.process')) || _isDSBuffer(bufname) || (search_wid.p_buf_flags & VSBUFFLAG_HIDDEN)) {
               _replacepreview_btn.p_enabled = false;
            } else {
               _replacepreview_btn.p_enabled = true;
            }
         }
      }
   }
   if (!_haveDiff()) {
      _replacepreview_btn.p_enabled = false;
   }

   if (search_wid == 0) {
      _findlist_all.p_enabled = false;
      _findmark_all.p_enabled = false;
      _findbookmark_all.p_enabled = false;
      _findmc.p_enabled = false;
      _findinc.p_enabled = false;
   } else {
      _str bufname = search_wid.p_buf_name;
      if (_isGrepBuffer(bufname)) {
         _findlist_all.p_enabled = false;
         _findmark_all.p_enabled = false;
         _replacelist.p_enabled = false;
      } else {
         _findlist_all.p_enabled = true;
         _findmark_all.p_enabled = true;
         _replacelist.p_enabled = true;
      }
      if ((bufname :== '') || _isGrepBuffer(bufname) || (beginsWith(bufname, '.process')) || _isDSBuffer(bufname) || (search_wid.p_buf_flags & VSBUFFLAG_HIDDEN)) {
         _findbookmark_all.p_enabled = false;
      } else {
         _findbookmark_all.p_enabled = true;
      }
      _findinc.p_enabled = (search_wid.p_buf_size <= def_gui_find_incremental_search_max_buf_ksize*1024);
   }

   if (mode == VSSEARCHMODE_FIND) {
      switch (_findbuffer.p_text) {
      case SEARCH_IN_CURRENT_BUFFER:
      case SEARCH_IN_CURRENT_SELECTION:
      case SEARCH_IN_CURRENT_PROC:
         _findmc.p_enabled = (search_wid != 0);
         break;
      case SEARCH_IN_ALL_BUFFERS:
      case SEARCH_IN_ALL_ECL_BUFFERS:
      case MFFIND_PROJECT_FILES:
      case MFFIND_WORKSPACE_FILES:
         _findmc.p_enabled = false;
         break;
      }
   }

   if (mode == VSSEARCHMODE_FIND || mode == VSSEARCHMODE_REPLACE) {
      // special case to enable find with no child windows when searching project/workspace
      switch (_findbuffer.p_text) {
      case MFFIND_PROJECT_FILES:
      case MFFIND_WORKSPACE_FILES:
         _find_btn.p_enabled           = true;
         _replace_btn.p_enabled        = true;
         _replaceall_btn.p_enabled     = true;
         _replacepreview_btn.p_enabled = true;
         _findlist_all.p_enabled       = true;
         break;
      }
   }

   if (mode == VSSEARCHMODE_FIND || mode == VSSEARCHMODE_REPLACE) {
      switch (_findbuffer.p_text) {
      case SEARCH_IN_CURRENT_BUFFER:
      case SEARCH_IN_CURRENT_SELECTION:
      case SEARCH_IN_CURRENT_PROC:
         _mflistfilesonly.p_enabled = false;
         break;
      default:
         _mflistfilesonly.p_enabled = true;
         break;
      }
   } else if (mode == VSSEARCHMODE_FINDINFILES || mode == VSSEARCHMODE_REPLACEINFILES) {
      _mflistfilesonly.p_enabled = (_findfiles.p_text :!= SEARCH_IN_CURRENT_BUFFER);
   } else {
      _mflistfilesonly.p_enabled = true;
   }

   _update_grep_ab_option();
   _update_color_options();
   _update_file_buttons(mode);
}

static void _update_search_options(int mode)
{
   list_all := (_findlist_all.p_value != 0 && _findlist_all.p_enabled);
   _findwrap.p_enabled = _findcursorend.p_enabled = _findback.p_enabled = !(list_all && (mode == VSSEARCHMODE_FIND));
}

static void _show_search_options(int mode)
{
   // not visible?  don't bother!
   if (!_options_frame.p_visible) {
      return;
   }

   int ctrl_ids[];
   int w, h;
   int pad_h;
   int new_width = (_re_button.p_x_extent) - _results_frame.p_x;

   if (_search_opt_button.p_value == 0) {
      _str search_options = _get_search_options();
      label :=  "Search options: ":+_get_search_options_label(search_options);
      if (mode == VSSEARCHMODE_FIND || mode == VSSEARCHMODE_REPLACE) {
         if (pos('?', search_options, 1, 'I')) {
            strappend(label, ", Prompt at beginning/end");
         } else if (pos('P', search_options,1, 'I')) {
            strappend(label, ", Wrap at beginning/end");
         } else {
            strappend(label, ", No wrap");
         }
      }
      if (mode == VSSEARCHMODE_FIND) {
         if (_findinc.p_value) {
            strappend(label, ", Incremental search");
         }
         if (_findlist_all.p_value && _findlist_all.p_enabled) {
            strappend(label, ", List all");
         }
         if (_findmark_all.p_value && _findmark_all.p_enabled) {
            strappend(label, ", Highlight all");
         }
         if (_findbookmark_all.p_value && _findbookmark_all.p_enabled) {
            strappend(label, ", Bookmark all");
         }
         if (_findmc.p_value && _findmc.p_enabled) {
            strappend(label, ", Set multiple cursors");
         }
      }
      if (mode == VSSEARCHMODE_REPLACEINFILES) {
         if (_replaceleaveopen.p_value) {
            strappend(label, ", Leave modified files open");
         }
      }
      if (_findcolorcheck.p_value && _findcoloroptions.p_text != '') {
         strappend(label, ", "_findcolorlabel.p_caption);
      }

      _options_label.p_caption = label;
      _options_label.p_auto_size = false;
      _options_label.p_x_extent = _options_frame.p_width - 180;

      _oframe_1.p_visible = false;
      _oframe_2.p_visible = false;
      _oframe_3.p_visible = false;
      _findall_options.p_visible = false;
      pad_h = 90;
   } else {
      _options_label.p_caption = "Search options";
      _options_label.p_auto_size = true;
      _oframe_1.p_visible = true;
      switch (mode) {
      case VSSEARCHMODE_FIND:
         _oframe_2.p_visible = true;
         _oframe_3.p_visible = false;
         _findall_options.p_visible = true;
         break;
      case VSSEARCHMODE_FINDINFILES:
         _oframe_2.p_visible = false;
         _oframe_3.p_visible = false;
         _findall_options.p_visible = false;
         break;
      case VSSEARCHMODE_REPLACE:
         _oframe_2.p_visible = true;
         _oframe_3.p_visible = true;
         _findall_options.p_visible = false;
         _replacehilite.p_visible = true;
         _replaceleaveopen.p_visible = false;
         _replacelist.p_visible = true;
         ctrl_ids._makeempty();
         ctrl_ids[0] = _replacekeepcase.p_window_id;
         ctrl_ids[1] = _replacehilite.p_window_id;
         ctrl_ids[2] = _replaceleaveopen.p_window_id;
         ctrl_ids[3] = _replacelist.p_window_id;
         _space_controls_y(ctrl_ids, 30, -30);
         break;
      case VSSEARCHMODE_REPLACEINFILES:
         _oframe_2.p_visible = false;
         _oframe_3.p_visible = true;
         _findall_options.p_visible = false;
         _replacehilite.p_visible = false;
         _replaceleaveopen.p_visible = true;
         _replacelist.p_visible = false;
         ctrl_ids._makeempty();
         ctrl_ids[0] = _replacekeepcase.p_window_id;
         ctrl_ids[1] = _replacehilite.p_window_id;
         ctrl_ids[2] = _replaceleaveopen.p_window_id;
         ctrl_ids[3] = _replacelist.p_window_id;
         _space_controls_y(ctrl_ids, 30, -30);
         break;
      }
      _get_child_extents(_oframe_1.p_window_id, w, h, true);
      _oframe_1.p_height = h + 120;

      int start_y = _oframe_1.p_y;
      ctrl_ids._makeempty();
      ctrl_ids[0] = _oframe_2.p_window_id;
      ctrl_ids[1] = _oframe_3.p_window_id;
      ctrl_ids[2] = _findall_options.p_window_id;
      _space_controls_y(ctrl_ids, 0, start_y);
      pad_h = 60;

      _findcolorlabel.p_width = _findcolorlabel.p_parent.p_width - (2*_findcolorlabel.p_x);
   }
   _get_child_extents(_options_frame.p_window_id, w, h, true);
   if (w + 90 > new_width) {
      new_width = w + 90;
   }
   _options_label.p_width = new_width - (2 * _options_label.p_x);
   _get_child_extents(_options_frame.p_window_id, w, h, true); // must be called again to get correct height
   _options_frame.p_width = new_width;
   _options_frame.p_height = h + pad_h;

   _findcolormenu.p_x = _findcolorcheck.p_x_extent - _twips_per_pixel_x();

   if (mode == VSSEARCHMODE_FINDINFILES || mode == VSSEARCHMODE_REPLACEINFILES || mode == VSSEARCHMODE_FILES) {
      _update_findfilestats();
   }
}

static void _show_results_options(int mode)
{
   // not visible?  don't bother!
   if (!_results_frame.p_visible) {
      return;
   }

   // line the frame up with the menu button
   int new_width = (_re_button.p_x_extent) - _results_frame.p_x;

   int w, h;
   int pad_w, pad_h;

   if (_result_opt_button.p_value == 0) {
      _results_label.p_caption = "Results options: ":+_get_search_results_label();
      _results_label.p_auto_size = false;
      _results_label.p_x_extent = _results_frame.p_width - 180;

      _results_box.p_visible = false;
      _foreground_box.p_visible = false;
      pad_h = 90;

      _get_child_extents(_results_box.p_window_id, w, h, true);
      _results_box.p_height = h + pad_h;
   } else {
      _results_box.p_visible = true;
      switch (mode) {
      case VSSEARCHMODE_FINDINFILES:
         _foreground_box.p_visible = true;
         break;

      default:
         _foreground_box.p_visible = false;
         break;
      }
      _results_label.p_caption = "Results options";
      _results_label.p_auto_size = true;
      pad_h = 60;
      pad_w = 30;

      int start_y = _findgrep.p_y_extent + 60;
      int ctrl_ids[];
      ctrl_ids._makeempty();
      ctrl_ids[0] = _mfmdichild.p_window_id;
      ctrl_ids[1] = _mfappendgrep.p_window_id;
      ctrl_ids[2] = _mfmatchlines.p_window_id;
      ctrl_ids[3] = _mflistmatchonly.p_window_id;
      ctrl_ids[4] = _mflistcontext.p_window_id;
      ctrl_ids[5] = _mflistfilesonly.p_window_id;
      ctrl_ids[6] = _mfgrepab.p_window_id;
      _space_controls_y(ctrl_ids, 15, start_y);

      if (_mfgrepab.p_visible) {
         _mfgrepabmenu.p_y = _mfgrepab.p_y;
      }

      // update label
      grep_before_lines := 0; grep_after_lines := 0;
      if (_mfgrepablines.p_text != '')  {
         parse _mfgrepablines.p_text with auto b "," auto a;
         if (isinteger(b) && isinteger(a)) {
            grep_before_lines = (int)b;
            grep_after_lines = (int)a;
         }
      }
      caption := "List lines before/after (";
      caption :+= (grep_before_lines == 0) ? "0" : "-"grep_before_lines;
      caption :+= ",";
      caption :+= (grep_after_lines == 0) ? "0" : "+"grep_after_lines;
      caption :+= ")";
      _mfgrepab.p_caption = caption;
      _mfgrepabmenu.p_x = _mfgrepab.p_x_extent;

      _get_child_extents(_results_box.p_window_id, w, h, true);
      _results_box.p_width = w + pad_w;
      _results_box.p_height = h + pad_h;

      _foreground_box.p_x = _results_box.p_x_extent + pad_w;
   }

   _get_child_extents(_results_frame.p_window_id, w, h, true);
   if (w + 90 > new_width) {
      new_width = w + 90;
   }
   _results_label.p_width = new_width - (2 * _results_label.p_x);
   _get_child_extents(_results_frame.p_window_id, w, h, true); // must be called again to get correct height
   _results_frame.p_width = new_width;
   _results_frame.p_height = h + pad_h;
}

static void _update_grep_ab_option()
{
   enabled := !(_mflistfilesonly.p_visible && _mflistfilesonly.p_enabled && _mflistfilesonly.p_value) && !(_mflistmatchonly.p_visible && _mflistmatchonly.p_value);
   _mfgrepab.p_enabled = enabled;
   if (enabled) {
      grep_before_lines := 0; grep_after_lines := 0;
      if (_mfgrepablines.p_text != '') {
         parse _mfgrepablines.p_text with auto b "," auto a;
         if (isinteger(b) && isinteger(a)) {
            grep_before_lines = (int)b;
            grep_after_lines = (int)a;
         }
      }
      enabled = !(grep_before_lines == 0 && grep_after_lines == 0);
   }
   _mfgrepab.p_enabled = enabled;
}

static void _init_results_options(int mode)
{
   switch (mode) {
   case VSSEARCHMODE_FIND:
      _mfmatchlines.p_visible = true;
      _mflistmatchonly.p_visible = true;
      _mflistfilesonly.p_visible = true;
      _mflistcontext.p_visible = true;
      _mfgrepab.p_visible = true;
      _mfgrepabmenu.p_visible = true;
      break;

   case VSSEARCHMODE_REPLACE:
      _mfmatchlines.p_visible = true;
      _mflistmatchonly.p_visible = false;
      _mflistfilesonly.p_visible = true;
      _mflistcontext.p_visible = true;
      _mfgrepab.p_visible = false;
      _mfgrepabmenu.p_visible = false;
      break;

   case VSSEARCHMODE_FINDINFILES:
      _mfmatchlines.p_visible = true;
      _mflistmatchonly.p_visible = true;
      _mflistfilesonly.p_visible = true;
      _mflistcontext.p_visible = true;
      _mfgrepab.p_visible = true;
      _mfgrepabmenu.p_visible = true;
      break;

   case VSSEARCHMODE_REPLACEINFILES:
      _mfmatchlines.p_visible = true;
      _mflistmatchonly.p_visible = false;
      _mflistfilesonly.p_visible = true;
      _mflistcontext.p_visible = true;
      _mfgrepab.p_visible = false;
      _mfgrepabmenu.p_visible = false;
      break;

   case VSSEARCHMODE_FILES:
      _mfmatchlines.p_visible = false;
      _mflistmatchonly.p_visible = false;
      _mflistfilesonly.p_visible = false;
      _mflistcontext.p_visible = false;
      _mfgrepab.p_visible = false;
      _mfgrepabmenu.p_visible = false;
      break;
   }

   filesonly := (_mflistfilesonly.p_visible && _mflistfilesonly.p_enabled && _mflistfilesonly.p_value);
   
   _mflistmatchonly.p_enabled = !filesonly;
   _mfmatchlines.p_enabled = !(_mflistmatchonly.p_visible && _mflistmatchonly.p_value) && !filesonly;
   _mflistcontext.p_enabled = !filesonly;

  _update_grep_ab_option();
}

static void _showhide_controls(int mode, bool forceRefresh = false)
{
   if (mode == _findtabs.p_ActiveTab && !forceRefresh) return;
   search_wid := _get_current_search_wid();
   _findtabs.p_visible = def_find_hide_tabs ? false : true;
   old_ignore_change := ignore_change;
   ignore_change = true;
   _findtabs.p_ActiveTab = mode;
   ignore_change = old_ignore_change;
   clear_message();

   switch (mode) {
   case VSSEARCHMODE_FIND:
      _search_frame.p_visible    = true;
      _files_frame.p_visible     = false;
      _options_frame.p_visible   = true;
      _results_frame.p_visible   = (_findlist_all.p_value != 0 && _findlist_all.p_enabled);
      _button_frame.p_visible    = true;
      break;

   case VSSEARCHMODE_FINDINFILES:
      _search_frame.p_visible    = true;
      _files_frame.p_visible     = true;
      _options_frame.p_visible   = true;
      _results_frame.p_visible   = true;
      _button_frame.p_visible    = true;
      _findfiles._init_files_list(mode);
      _mfforegroundsearch.p_visible = true;
      _mfforegroundoptions.p_visible = true;
      _findinzipfiles.p_visible  = true;
      break;

   case VSSEARCHMODE_REPLACE:
      _search_frame.p_visible    = true;
      _files_frame.p_visible     = false;
      _options_frame.p_visible   = true;
      _results_frame.p_visible   = (_replacelist.p_value != 0 && _replacelist.p_enabled);
      _button_frame.p_visible    = true;
      break;

   case VSSEARCHMODE_REPLACEINFILES:
      _search_frame.p_visible    = true;
      _files_frame.p_visible     = true;
      _options_frame.p_visible   = true;
      _results_frame.p_visible   = true;
      _button_frame.p_visible    = true;
      _findfiles._init_files_list(mode);
      _mfforegroundsearch.p_visible = false;
      _mfforegroundoptions.p_visible = false;
      _findinzipfiles.p_visible  = false;
      break;

   case VSSEARCHMODE_FILES:
      _search_frame.p_visible    = true;
      _files_frame.p_visible     = true;
      _options_frame.p_visible   = false;
      _results_frame.p_visible   = true;
      _button_frame.p_visible    = true;
      _findfiles._init_files_list(mode);
      _mfforegroundsearch.p_visible = true;
      _mfforegroundoptions.p_visible = true;
      _findinzipfiles.p_visible  = true;
      break;
   }
   ignore_change = true;
   _show_search_text(mode);
   _show_button_frame(mode);
   _update_button_state(mode);
   _update_search_options(mode);
   _show_search_options(mode);
   _init_results_options(mode);
   _show_results_options(mode);
   _resize_frame_heights(true);
   _mfhook.call_event(CHANGE_SELECTED, (mode == VSSEARCHMODE_FINDINFILES), _mfhook, LBUTTON_UP, '');
   _findstring._show_textbox_error_color(false);
   ignore_change = old_ignore_change;

   // show warning message
   if ((mode == VSSEARCHMODE_FIND) && (search_wid != 0) && (search_wid.p_buf_size > def_gui_find_incremental_search_max_buf_ksize*1024)) {
      message('Incremental search disabled: File too large');
   }
}

static void _init_options(int flags)
{
   if (flags & VSSEARCHFLAG_REVERSE) {
      _findback.p_value = 1;
   } else {
      _findback.p_value = 0;
   }
   _findcase.p_value = (int)!(flags & VSSEARCHFLAG_IGNORECASE);
   _findword.p_value = flags & VSSEARCHFLAG_WORD;
   _findwrap.p_value = ((flags & VSSEARCHFLAG_WRAP) ? 1 : 0) + ((flags & VSSEARCHFLAG_PROMPT_WRAP) ? 1 : 0);
   _findcursorend.p_value = flags & VSSEARCHFLAG_POSITIONONLASTCHAR;
   _findhidden.p_value = flags & VSSEARCHFLAG_HIDDEN_TEXT;
   _findre.p_value = flags & (VSSEARCHFLAG_RE /*| VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE*/ | VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_VIMRE | VSSEARCHFLAG_WILDCARDRE);
   if (_findre.p_value) {
      _findre_type._init_re_type(flags & (VSSEARCHFLAG_RE /*| VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE*/ | VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_VIMRE | VSSEARCHFLAG_WILDCARDRE));
   } else {
      //if (def_re_search_flags & VSSEARCHFLAG_BRIEFRE) {
      //   _findre_type.p_text = RE_TYPE_BRIEF_STRING;
      //} else 
      if (def_re_search_flags & VSSEARCHFLAG_RE) {
         _findre_type.p_text = RE_TYPE_SLICKEDIT_STRING;
      } else if (def_re_search_flags & VSSEARCHFLAG_WILDCARDRE) {
         _findre_type.p_text = RE_TYPE_WILDCARD_STRING;
      } else if (def_re_search_flags & VSSEARCHFLAG_VIMRE) {
         _findre_type.p_text = RE_TYPE_VIM_STRING;
      } else /*if (def_re_search_flags & VSSEARCHFLAG_PERLRE)*/ {
         _findre_type.p_text = RE_TYPE_PERL_STRING;
      //} else {
      //   _findre_type.p_text = RE_TYPE_UNIX_STRING;
      }
      _findre_type.p_enabled = false;
      _re_button.p_enabled = false;
      _replace_re_button.p_enabled = false;
   }
   _replacekeepcase.p_value = flags & VSSEARCHFLAG_PRESERVE_CASE;
   _replacehilite.p_value = flags & VSSEARCHFLAG_REPLACEHILIGHT;

   _findinc.p_value = 0;
   _findlist_all.p_value = 0;
   _findmark_all.p_value = 0;
   _findmc.p_value = 0;
   _findbookmark_all.p_value = 0;
   _replaceleaveopen.p_value = 0;
   _replacelist.p_value = 0;
   _findcolorcheck.p_value = 0;
   _findcoloroptions.p_text = '';
   _showhide_controls(_findtabs.p_ActiveTab, true);
}

static void _set_search_options(_str search_options, _str path = '')
{
   if (search_options != '') {
       if (pos('i', search_options, 1, 'I')) {
          _findcase.p_value = 0;
       } else if (pos('e', search_options, 1, 'I')) {
          _findcase.p_value = 1;
       }

       if (pos('-', search_options)) {
          _findback.p_value = 1;
       } else if (pos('+', search_options)) {
          _findback.p_value = 0;
       } else if (def_keys == "brief-keys") {
          //In brief, if we aren't searching back, we are always searching forward.
          _findback.p_value = 0;
       }

       if (pos('w', search_options, 1, 'I')) {
          _findword.p_value = 1;
       }

       if (pos('h', search_options, 1, 'I')) {
          _findhidden.p_value = 1;
       }

       if (pos('?', search_options, 1, 'I')) {
          _findwrap.p_value = 2;
       } else if (pos('p', search_options, 1, 'I')) {
          _findwrap.p_value = 1;
       }

       if (pos('>', search_options)) {
          _findcursorend.p_value = 1;
       } else if (pos('<', search_options)) {
          _findcursorend.p_value = 0;
       } else {
          _findcursorend.p_value = 0;
       }

       if (pos('[rublRUBL&~]', search_options, 1, 'r')) {
          _findre.p_value = 1;
          _findre_type.p_enabled = true;
          if (pos('r', search_options, 1, 'I')) {
             _findre_type._init_re_type(VSSEARCHFLAG_RE);
          } else if (pos('u', search_options, 1, 'I')) {
             _findre_type._init_re_type(VSSEARCHFLAG_PERLRE);
          } else if (pos('b', search_options, 1, 'I')) {
             _findre_type._init_re_type(VSSEARCHFLAG_PERLRE);
          } else if (pos('l', search_options, 1, 'I')) {
             _findre_type._init_re_type(VSSEARCHFLAG_PERLRE);
          } else if (pos('~', search_options, 1)) {
             _findre_type._init_re_type(VSSEARCHFLAG_VIMRE);
          } else if (pos('&', search_options, 1)) {
             _findre_type._init_re_type(VSSEARCHFLAG_WILDCARDRE);
          }
          _re_button.p_enabled = true;
          _replace_re_button.p_enabled = true;
       }
   }

   switch (path) {
   case MFFIND_BUFFER:
   case MFFIND_BUFFER_DIR:
      if (_mffind_buffer_has_directory()) {
         _findfiles.p_text=path;
      }
      break;

   case MFFIND_BUFFERS:
      if (_mffind_have_buffers()) {
         _findfiles.p_text=path;
      }
      break;

   case MFFIND_PROJECT_FILES:
      if (_mfallow_prjfiles()) {
         _findfiles.p_text=path;
      }
      break;

   case MFFIND_WORKSPACE_FILES:
      if (_mfallow_workspacefiles()) {
         _findfiles.p_text=path;
      }
      break;

   default:
      if (path != '' && file_exists(path)) {
         _findfiles.p_text=path;
      }
      break;
   }
}

static void _set_results_options(int mfflags)
{
   _mfmdichild.p_value = mfflags & MFFIND_MDICHILD;
   _mflistfilesonly.p_value = mfflags & MFFIND_FILESONLY;
   _mfappendgrep.p_value = mfflags & MFFIND_APPEND;
   _mfmatchlines.p_value = mfflags & MFFIND_SINGLELINE;
   _mflistmatchonly.p_value = mfflags & MFFIND_MATCHONLY;
   _mfmatchlines.p_enabled = !(mfflags & MFFIND_FILESONLY) && !(mfflags & MFFIND_MATCHONLY);
   _mflistmatchonly.p_enabled = !(mfflags & MFFIND_FILESONLY);
   _mflistcontext.p_value = mfflags & MFFIND_LIST_CURRENT_CONTEXT;
   _update_grep_ab_option();
}

static void _init_findstring(int window_id)
{
   old_ignore_change := ignore_change;
   ignore_change = true;
   init_str := "";
   if (def_mfsearch_init_flags & MFSEARCH_INIT_HISTORY) {
      init_str = old_search_string;
   }
   if (window_id && window_id._isEditorCtl(false)) {
      str := "";
      if (def_mfsearch_init_flags & MFSEARCH_INIT_CURWORD) {
         str = window_id.cur_word(auto junk, '', true);
      }
      if ((def_mfsearch_init_flags & MFSEARCH_INIT_SELECTION) && window_id.select_active2()) {
         mark_locked := 0;
         if (_select_type('', 'S') == 'C') {
            mark_locked = 1;
            _select_type('', 'S', 'E');
         }
         window_id.filter_init();
         window_id.filter_get_string(str, 1024);
         window_id.filter_restore_pos();
         if (mark_locked) {
            _select_type('', 'S','C');
         }
      }
      if (str != '') {
         if ((def_mfsearch_init_flags & MFSEARCH_INIT_AUTO_ESCAPE_REGEX) && _findre.p_value) {
            options := 'R';
            switch (_findre_type.p_text) {
            case RE_TYPE_SLICKEDIT_STRING: options = 'R'; break;
            case RE_TYPE_PERL_STRING:      options = 'L'; break;
            case RE_TYPE_VIM_STRING:       options = '~'; break;
            case RE_TYPE_WILDCARD_STRING:  options = '&'; break;
            }
            str = _escape_re_chars(str, options);
         }
         init_str = str;
      }

      // auto initialize if selection available
      if (window_id.select_active2()) {
         start_col := end_col := 0;
         typeless junk;
         buf_name := "";
         Noflines := 0;
         window_id._get_selinfo(start_col, end_col, junk, '', buf_name, junk, junk, Noflines);
         if (_select_type('') == 'LINE' || Noflines > 1) {
            // if current selection is active, is not the previous search selection,
            // and is a multiline selection, initialize search range to current selection
            _init_buffer_range(VSSEARCHRANGE_CURRENT_SELECTION); old_search_range = VSSEARCHRANGE_CURRENT_SELECTION;
         }
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
   ignore_change = old_ignore_change;
}

static void _init_mode(int mode, bool forceRefresh = false)
{
   _findtabs._showhide_controls(mode, forceRefresh);
}

static int _validate_search_buffer(int search_wid)
{
   if (search_wid <= 0 || !_iswindow_valid(search_wid)) {
      search_wid = _MDIGetActiveMDIChild();
   }
   if (search_wid) {
      if (!search_wid.p_HasBuffer || (search_wid.p_window_flags & HIDE_WINDOW_OVERLAP)) {
         search_wid = 0;
      }
   }
   return(search_wid);
}

static bool ignore_switchbuf = false;
static void _init_current_search_buffer(int search_wid)
{
   if (ignore_switchbuf) {
      return;
   }
   search_bufname := "";
   int orig_wid;
   get_window_id(orig_wid);
   form_id := _tbGetActiveFindAndReplaceForm();
   if (form_id == 0) {
      return;
   }
   activate_window(form_id);

   if (search_wid && _iswindow_valid(search_wid) && search_wid.p_HasBuffer) {
      search_bufname = search_wid.p_buf_name;
   }
   if (search_wid == _GetDialogInfo(DLGINFO_CURRENT_SEARCH_WID, _control _find_btn)) {
      if (search_wid) {
         _findbuffer._init_buffers_list(search_wid);
         if (search_bufname == _GetDialogInfo(DLGINFO_CURRENT_BUFFER, _control _find_btn)) {
            activate_window(orig_wid);
            return;
         }
      }
   }

   _SetDialogInfo(DLGINFO_CURRENT_SEARCH_WID, search_wid, _control _find_btn);
   _SetDialogInfo(DLGINFO_CURRENT_BUFFER, search_bufname, _control _find_btn);

   mode := _findtabs.p_ActiveTab;
   _update_list_all_occurrences();
   _update_replace_list_all();
   _update_button_state(mode);
   _init_buffers_list(search_wid);
   activate_window(orig_wid);
}

static void _update_findfiles()
{
   if (ignore_switchbuf) {
      return;
   }
   if (p_text != '') {
      _mffindfiles_is_current_valid();

      // reset???
      if (p_text == '') {
         _lbtop();
         p_text = _lbget_text();
      }
   } 
}

static void _update_search_buffer(int switchbuf_wid=0)
{
   wid := (switchbuf_wid > 0) ? switchbuf_wid : p_window_id;
   if (ignore_change) {
      return;
   }

   formwid := _tbGetActiveFindAndReplaceForm();
   if (formwid == 0) {
      return;
   }

   // if there is a timer for updating the search buffer, kill it
   find_btn_wid := formwid._find_control("_find_btn");
   if (find_btn_wid > 0) {
      timer_id := formwid._GetDialogInfo(DLGINFO_TIMER_ID, find_btn_wid);
      if ( timer_id != null && _timer_is_valid(timer_id) ) {
         _kill_timer(timer_id);
         formwid._SetDialogInfo(DLGINFO_TIMER_ID,-1,find_btn_wid);
      }
   }

   // check active window id for buffer
   search_wid := 0;
   if (wid && _iswindow_valid(wid) && wid.p_HasBuffer && (wid != VSWID_HIDDEN)) {
      if (wid.p_mdi_child) {
         search_wid = _mdi.p_child.p_window_id;
      } else {
         if (wid.p_active_form && wid.p_active_form.p_isToolWindow && tw_is_visible_window(wid.p_active_form)) {
            search_wid = wid;
         } else if (!(wid.p_buf_flags & VSBUFFLAG_HIDDEN)) {
            search_wid = wid;
         }
      }
   }

   if (!search_wid && !_no_child_windows()) {
      search_wid = formwid._MDIGetActiveMDIChild();
   }
   ignore_change = true;
   formwid._init_current_search_buffer(search_wid);
   ignore_change = false;
}

static void tbFindFileChangeCallback(int switchbuf_wid=0)
{
   _update_search_buffer(switchbuf_wid);
}

static void _maybe_refresh_search_buffer(int switchbuf_wid=0)
{
   if (_in_batch_open_or_close_files()) {
      return;
   }

   formid := _tbGetActiveFindAndReplaceForm();
   if (formid == 0) {
      return;
   }

   find_btn_wid := formid._find_control("_find_btn");
   if (find_btn_wid > 0) {
      timer_id := formid._GetDialogInfo(DLGINFO_TIMER_ID, find_btn_wid);
      if (timer_id != null && timer_id != -1 && _timer_is_valid(timer_id)) {
         _kill_timer(timer_id);
      }
      timer_delay := max(200,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
      timer_id = _set_timer(timer_delay, tbFindFileChangeCallback, switchbuf_wid);
      formid._SetDialogInfo(DLGINFO_TIMER_ID, timer_id, find_btn_wid);
   }
}

void _cbquit_tbfind(int buffid, _str name, _str docname= '', int flags = 0)
{
   _maybe_refresh_search_buffer();
}

void _buffer_add_tbfind(int newbuffid, _str name, int flags = 0)
{
   if (flags & VSBUFFLAG_HIDDEN) return;
   _maybe_refresh_search_buffer(p_window_id);
}

void _cbmdibuffer_hidden_tbfind()
{
   _maybe_refresh_search_buffer();
}

void _cbmdibuffer_unhidden_tbfind()
{
   _buffer_add_tbfind(p_buf_id, p_buf_name, p_buf_flags);
}

void _switchbuf_tbfind(_str oldbuffname, _str flag)
{
   if (_in_batch_open_or_close_files()) return;
   switchbuf_wid := -1;
   wid := p_window_id;
   if (wid && _iswindow_valid(wid) && wid.p_HasBuffer && (wid != VSWID_HIDDEN)) {
      switchbuf_wid = wid;
   }

   _maybe_refresh_search_buffer(switchbuf_wid);
}

void _wkspace_close_tbfind()
{
   _maybe_refresh_search_buffer();
}

void _workspace_opened_tbfind()
{
   _maybe_refresh_search_buffer();
}

static void _init_re()
{
   //_findre_type._lbadd_item(RE_TYPE_UNIX_STRING);
   //_findre_type._lbadd_item(RE_TYPE_BRIEF_STRING);
   _findre_type._lbadd_item(RE_TYPE_SLICKEDIT_STRING);
   _findre_type._lbadd_item(RE_TYPE_PERL_STRING);
   _findre_type._lbadd_item(RE_TYPE_VIM_STRING);
   _findre_type._lbadd_item(RE_TYPE_WILDCARD_STRING);
}

const GREP_AUTO_INCREMENT = -2;
const GREP_NEW_WINDOW = -3;

static void _init_grepbuffers(bool forceRefresh = false)
{
   if (forceRefresh) PUSER_LAST_GREP_ID('');
   int last_grep_id = _get_last_grep_buffer();
   if (PUSER_LAST_GREP_ID() == '' || PUSER_LAST_GREP_ID() != last_grep_id) {
      old_text := _findgrep.p_text;
      _findgrep._lbclear();
      int i;
      for (i = 0; i <= last_grep_id; ++i) {
         _findgrep._lbadd_item('Search<'i'>');
      }
      _findgrep._lbadd_item('<New>');
      _findgrep._lbadd_item('<Auto Increment>');
      PUSER_LAST_GREP_ID(last_grep_id);
   }
}

static void _set_grep_buffer_id(int grep_id)
{
   PUSER_LAST_GREP_ID('');
   if (grep_id < 0) {
      if (grep_id == GREP_AUTO_INCREMENT) {
         _findgrep.p_text = '<Auto Increment>';
      } else if (grep_id == GREP_NEW_WINDOW) {
         last_grep_id := _get_last_grep_buffer();
         _findgrep.p_text = '<New>';
      }
   } else {
      _update_last_grep_buffer(grep_id);
      _findgrep.p_text = 'Search<'grep_id'>';
   }
}

static void _init_buffers_list(int search_wid)
{
   origText := _findbuffer.p_text;
   _str new_items[];
   new_items[new_items._length()]=SEARCH_IN_CURRENT_BUFFER; // default
   if (search_wid != 0) {
      if (search_wid.p_HasBuffer) {
         if (!search_wid._isnull_selection()) {
            new_items[new_items._length()]=SEARCH_IN_CURRENT_SELECTION;
         }
         if ((search_wid.p_lexer_name != '') && search_wid._allow_find_current_proc()) {
            new_items[new_items._length()]=SEARCH_IN_CURRENT_PROC;
         }
      }
   }
   if (!_no_child_windows()) {
      if (!isEclipsePlugin()) {
         new_items[new_items._length()]=SEARCH_IN_ALL_BUFFERS;
      } else {
         new_items[new_items._length()]=SEARCH_IN_ALL_ECL_BUFFERS;
      }
   }
   if (_mfallow_prjfiles()) {
      new_items[new_items._length()]=MFFIND_PROJECT_FILES;
   }
   if (_mfallow_workspacefiles()) {
      new_items[new_items._length()]=MFFIND_WORKSPACE_FILES;
   }
   changed:=false;
   if (_findbuffer.p_Noflines!=new_items._length()) {
      changed=true;
   } else if (new_items!=_findbuffer.p_user) {
      changed=true;
   }
   if (!changed) {
      return;
   }
   _findbuffer.p_user=new_items;
   _findbuffer._lbclear();
   for (i:=0;i<new_items._length();++i) {
      _findbuffer._lbadd_item(new_items[i]);
   }
   _findbuffer._show_textbox_error_color(false);
   _findbuffer._lbtop();
   if (origText != "") {
      if (_findbuffer._lbfind_item(origText) >= 0) {
         _findbuffer._cbset_text(origText);
      }
   }
}

static void _init_misc_search_opts(_str options)
{
   _str opt, rest;
   parse options with opt ";" rest;

   // check leading option
   switch (opt) {
   case 'tool':
      _findwrap.p_value = 0;
      _findcursorend.p_value = 0;
      _findback.p_value = 0;
      _findhidden.p_value = 0;
      _findinc.p_value = 0;
      _findlist_all.p_value = 0;
      _findmark_all.p_value = 0;
      _findmc.p_value = 0;
      _findbookmark_all.p_value = 0;
      _replacekeepcase.p_value = 0;
      _replacehilite.p_value = 0;
      _replaceleaveopen.p_value = 0;
      _replacelist.p_value = 0;
      _mfforegroundsearch.p_value = 0;
      _mfglobal.p_value = 1;
      _mfsinglefile.p_value = 0;
      _mfprompted.p_value = 0;
      _mfgrepab.p_value = 0;
      _findsubfolder.p_value = 0;
      _findinzipfiles.p_value = 0;
      _mffilesstats.p_value = 0;
      break;

   case 'mini':
      _findwrap.p_value = 0;
      _findback.p_value = 0;
      _findhidden.p_value = 0;
      _replacelist.p_value = 0;
      _mfgrepab.p_value = 0;
      break;
     
   case 'default':
      _findwrap.p_value = 0;
      _findcursorend.p_value = 0;
      _findback.p_value = 0;
      _findhidden.p_value = 0;
      break;
   }

   while (opt != '') {
      switch (opt) {
      case '_findwrap?':
         _findwrap.p_value = 2;
         break;
      case '_findwrap':
         _findwrap.p_value = 1;
         break;
      case '_findcursorend':
         _findcursorend.p_value = 1;
         break;
      case '_findback':
         _findback.p_value = 1;
         break;
      case '_findhidden':
         _findhidden.p_value = 1;
         break;

      case '_findlist_all':
         _findlist_all.p_value = 1;
         break;
      case '_findmark_all':
         _findmark_all.p_value = 1;
         break;
      case '_findmc':
         _findmc.p_value = 1;
         break;
      case '_findbookmark_all':
         _findbookmark_all.p_value = 1;
         break;
      case '_findinc':
         _findinc.p_value = 1;
         break;

      case '_replacekeepcase':
         _replacekeepcase.p_value = 1;
         break;
      case '_replacehilite':
         _replacehilite.p_value = 1;
         break;
      case '_replaceleaveopen':
         _replaceleaveopen.p_value = 1;
         break;
      case '_replacelist':
         _replacelist.p_value = 1;
         break;

      case '_mfforegroundsearch':
         _mfforegroundsearch.p_value = 1;
         break;
      case '_mfglobal':
         _mfglobal.p_value = 1;
         _mfsinglefile.p_value = 0;
         _mfprompted.p_value = 0;
         break;
      case '_mfsinglefile':
         _mfglobal.p_value = 0;
         _mfsinglefile.p_value = 1;
         _mfprompted.p_value = 0;
         break;
      case '_mfprompted':
         _mfglobal.p_value = 0;
         _mfsinglefile.p_value = 0;
         _mfprompted.p_value = 1;
         break;
      case '_mfgrepab':
         _mfgrepab.p_value = 1;
         break;

      case '_findsubfolder':
         _findsubfolder.p_value = 1;
         break;
      case '_findinzipfiles':
         _findinzipfiles.p_value = 1;
         break;
      case '_mffilesstats':
         _mffilesstats.p_value = 1;
         break;

      default:
         if (beginsWith(opt, '_mfgrepablines=')) {
            parse opt with '_mfgrepablines=' auto value;
            if (value != '') {
               _mfgrepablines.p_text = value;
            }
         } else if (beginsWith(opt, '_findcoloroptions=')) {
            parse opt with '_findcoloroptions=' auto value;
            if (value != '') {
               _findcoloroptions.p_text = value;
            }
         } else if (beginsWith(opt, '_mfgrepid=')) {
            parse opt with '_mfgrepid=' auto value;
            if (value != '') {
               _set_grep_buffer_id((int)value);
            }
         } else if (beginsWith(opt, '_findfilestats=')) {
            parse opt with '_findfilestats=' auto value;
            if (value != '') {
               _findfilestats.p_text = value;
            }
         }
         break;
      }
      parse rest with opt ";" rest;
   }
}

static _str _get_misc_search_opts()
{
   opts := "tool";

   if (_findwrap.p_value == 2) {
      _maybe_append(opts, ";"); strappend(opts, '_findwrap?');
   } else if (_findwrap.p_value == 1) {
      _maybe_append(opts, ";"); strappend(opts, '_findwrap');
   }  
   if (_findcursorend.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_findcursorend');
   }
   if (_findback.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_findback');
   }
   if (_findhidden.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_findhidden');
   }

   if (_findlist_all.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_findlist_all');
   }
   if (_findmark_all.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_findmark_all');
   }
   if (_findmc.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_findmc');
   }
   if (_findbookmark_all.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_findbookmark_all');
   }
   if (_findinc.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_findinc');
   }

   if (_replacekeepcase.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_replacekeepcase');
   }
   if (_replacehilite.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_replacehilite');
   }
   if (_replaceleaveopen.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_replaceleaveopen');
   }
   if (_replacelist.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_replacelist');
   }
   
   if (_findsubfolder.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_findsubfolder');
   }
   if (_findinzipfiles.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_findinzipfiles');
   }
   if (_mfforegroundsearch.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_mfforegroundsearch');
   }
   if (_mfglobal.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_mfglobal');
   } else if (_mfsinglefile.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_mfsinglefile');
   } else {
      _maybe_append(opts, ";"); strappend(opts, '_mfprompted');
   }
   if (_mfgrepab.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_mfgrepab');
   }
   if (_mfgrepablines.p_text != '') {
      _maybe_append(opts, ";"); strappend(opts, '_mfgrepablines='_mfgrepablines.p_text);
   }

   grep_id := 0;
   grep_buffer := _findgrep.p_text;
   if (pos('new', grep_buffer, 1, 'I')) {
      grep_id = GREP_NEW_WINDOW;
   } else if (pos('auto increment', grep_buffer, 1, 'I')) {
      grep_id = GREP_AUTO_INCREMENT;
   } else {
      parse grep_buffer with 'Search<' auto num '>';
      grep_id = (int)num;
   }
   _maybe_append(opts, ";"); strappend(opts, '_mfgrepid='grep_id);

   if (_findcoloroptions.p_text != '') {
      _maybe_append(opts, ";"); strappend(opts, '_findcoloroptions='_findcoloroptions.p_text);
   }
   if (_mffilesstats.p_value) {
      _maybe_append(opts, ";"); strappend(opts, '_mffilesstats');
   }
   if (_findfilestats.p_text != '') {
      _maybe_append(opts, ";"); strappend(opts, '_findfilestats='_findfilestats.p_text);
   }
   return opts;
}

static void doCurrentWordAtCursor()
{
   form_wid := p_active_form.p_window_id;
   search_wid := _get_current_search_wid();
   if (!search_wid || !_iswindow_valid(search_wid) || !search_wid._isEditorCtl(false)) {
      return;
   }

   word := search_wid.cur_word(auto junk, '', true);
   if (word :!= '') {
      if ((def_mfsearch_init_flags & MFSEARCH_INIT_AUTO_ESCAPE_REGEX) && _findre.p_value) {
         options := 'R';
         switch (_findre_type.p_text) {
         case RE_TYPE_SLICKEDIT_STRING: options = 'R'; break;
         case RE_TYPE_PERL_STRING:      options = 'L'; break;
         case RE_TYPE_VIM_STRING:       options = '~'; break;
         case RE_TYPE_WILDCARD_STRING:  options = '&'; break;
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
   search_wid := _get_current_search_wid();
   if (!search_wid || !_iswindow_valid(search_wid) || !search_wid._isEditorCtl(false) || !search_wid.select_active2()) {
      return;
   }

   mark_locked := 0;
   if (_select_type('', 'S') == 'C') {
      mark_locked = 1;
      _select_type('', 'S', 'E');
   }
   search_wid.filter_init();
   search_wid.filter_get_string(auto word);
   search_wid.filter_restore_pos();
   if (mark_locked) {
      _select_type('', 'S','C');
   }

   if (word :!= '') {
      if ((def_mfsearch_init_flags & MFSEARCH_INIT_AUTO_ESCAPE_REGEX) && _findre.p_value) {
         options := 'R';
         switch (_findre_type.p_text) {
         case RE_TYPE_SLICKEDIT_STRING: options = 'R'; break;
         case RE_TYPE_PERL_STRING:      options = 'L'; break;
         case RE_TYPE_VIM_STRING:       options = '~'; break;
         case RE_TYPE_WILDCARD_STRING:  options = '&'; break;
         }
         word = _escape_re_chars(word, options);
      }
      _findstring.p_text = word;
      _findstring._refresh_scroll();
      _findstring.end_line();
   }
}

void tbFind_SetFilelistGrepid(int grep_id)
{
   if (!_grep_buffer_exists(grep_id)) {
      return;
   }
   form_id := _tbGetActiveFindAndReplaceForm();
   if (form_id == 0) {
      return;
   }
   form_id._findfiles.p_text = "<SearchResults: ":+grep_id:+">";
}


/*** form functions ***/
defeventtab _tbfind_form;
void _findsubfolder.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   if (!_findsubfolder.p_value) {
      _findinzipfiles.p_value = 0;
   }
}


void _tbfind_form.on_create()
{
   _tbfind_form_initial_alignment();
   _gui_find_dismiss();
   _clear_last_found_cache();

   int i, j;
   ignore_change = true;
   _SetDialogInfo(DLGINFO_CURRENT_SEARCH_WID, 0, _control _find_btn);
   _SetDialogInfo(DLGINFO_CURRENT_BUFFER, "", _control _find_btn);

   int search_wid = gon_create_window_id;
   if (search_wid < 0) {
      search_wid = 0;
   }
   if (!search_wid || !_iswindow_valid(search_wid) || !search_wid.p_HasBuffer) {
      if (!_no_child_windows()) {
         search_wid = _MDIGetActiveMDIChild();
      }
   }
   _init_re();
   _init_grepbuffers();
   _init_grep_ab();
   _init_buffers_list(search_wid);
   if (_retrieve_prev_form() || def_find_init_defaults) {
      _init_options(_default_option('s'));
      if (def_find_init_defaults) {
         _init_misc_search_opts(def_find_misc_options);
      }
   }
   // set active tab after _retrieve_prev_form
   _findtabs.p_ActiveTab = gon_create_init_find_mode;
   // do this after the retrieve, b/c we use a def-var to save/retrieve 
   // the file types and we don't want them overwritten
   _findfiletypes._init_findfiletypes();
   _findfiletypes._init_findfiletypes_ext();
   _init_current_search_buffer(search_wid);
   _findfiles._update_findfiles(); PUSER_FINDFILES_INIT_DONE('');

   _findstring._retrieve_list(); PUSER_FINDSTRING_INIT_DONE(1);
   _replacestring._retrieve_list(); PUSER_REPLACESTRING_INIT_DONE(1);
   _findexclude._init_findfileexcludes();

   _replacestring.p_text = old_replace_string;
   _init_findstring(search_wid);
   ignore_change = false;
   if (_isUnix()) {
      _findfilesadv_button.p_enabled = false;
      _findfilesadv_button.p_visible = false;
   }

   tool_find_update_options('', '', old_search_options, old_search_range, old_search_mfflags, old_search_misc_options);
   _showhide_controls(_findtabs.p_ActiveTab, true);
   if (_findbuffer.p_text=='') {
      _findbuffer._lbtop();
      _findbuffer.p_text = _findbuffer._lbget_text();
   }
   if (_findgrep.p_text=='') {
      _findgrep._lbtop();
      _findgrep.p_text = _findgrep._lbget_text();
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _tbfind_form_initial_alignment()
{
   rightAlign := _findtabs.p_width - _find_label.p_x;

   sizeBrowseButtonToTextBox(_findstring.p_window_id, _re_button.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(_replacestring.p_window_id, _replace_re_button.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(_findfiles.p_window_id, _findfiles_button.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(_findsubfolder.p_window_id, _findfilesadv_button.p_window_id);
   sizeBrowseButtonToTextBox(_findfiletypes.p_window_id, _editfiletypes.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(_findcolorcheck.p_window_id, _findcolormenu.p_window_id);
   sizeBrowseButtonToTextBox(_mfgrepab.p_window_id, _mfgrepabmenu.p_window_id);
   sizeBrowseButtonToTextBox(_mffilesstats.p_window_id, _editfilestats.p_window_id);
   sizeBrowseButtonToTextBox(_find_label.p_window_id, ctlsearch_help.p_window_id);
   sizeBrowseButtonToTextBox(_replace_label.p_window_id, ctlreplace_help.p_window_id);
   sizeBrowseButtonToTextBox(_lookin_label.p_window_id, ctllookin_help.p_window_id);
   sizeBrowseButtonToTextBox(_findfiletypes_label.p_window_id, ctlinclude_help.p_window_id);
   sizeBrowseButtonToTextBox(_findexclude_label.p_window_id, ctlexclude_help.p_window_id);

   // match the other text/combo boxes to the new widths
   _findbuffer.p_width = _findexclude.p_width = _findstring.p_width;

   // now size the buttons at the bottom
   // first make sure the text fits inside
   _replacepreview_btn.p_auto_size = true;
   width := _replacepreview_btn.p_width;
   _replacepreview_btn.p_auto_size = false;
   if (!_haveDiff()) {
      _replacepreview_btn.p_enabled = false;
   }

   // match all the button widths
   _find_btn.p_width = _replace_btn.p_width = _replaceall_btn.p_width = _stop_btn.p_width = width;

   // make sure the frame is big enough
   _button_frame.p_width = (2 * width) + 20;

   _button_frame.p_x = rightAlign - _button_frame.p_width;
}

void ctlsearch_help.lbutton_down()
{
   search_flags := _get_search_flags();
   if (search_flags & VSSEARCHFLAG_WILDCARDRE) {
      help("wildcards");
   } else if (search_flags & VSSEARCHFLAG_VIMRE) {
      help("Vim regular expressions");
   } else if (search_flags & VSSEARCHFLAG_PERLRE) {
      help("Perl regular expressions");
   } else if (search_flags & VSSEARCHFLAG_RE) {
      help("SlickEdit regular expressions");
   } else {
      topic := _findtabs.p_ActiveHelp;
      if (topic != "") {
         help(topic);
      } else {
         help("Find and Replace tool window");
      }
   }
}

void ctlreplace_help.lbutton_down()
{
   search_flags := _get_search_flags();
   if (search_flags & VSSEARCHFLAG_VIMRE) {
      help("tagged expressions for Vim");
   } else if (search_flags & VSSEARCHFLAG_PERLRE) {
      help("tagged expressions for Perl");
   } else if (search_flags & VSSEARCHFLAG_RE) {
      help("tagged expressions for SlickEdit");
   } else {
      topic := _findtabs.p_ActiveHelp;
      if (topic != "") {
         help(topic);
      } else {
         help("replace");
      }
   }
}

void ctllookin_help.lbutton_down()
{
   topic := _findtabs.p_ActiveHelp;
   if (topic != "") {
      help(topic);
   } else {
      help("Find and Replace tool window");
   }
}

static bool ignore_close = false;
void _tbfind_form.on_destroy()
{
   _save_form_response();
   search_options := _get_search_options();
   search_wid := _get_current_search_wid();
   range_mode := ((_findtabs.p_ActiveTab == VSSEARCHMODE_FIND) || (_findtabs.p_ActiveTab == VSSEARCHMODE_REPLACE));
   search_range := range_mode ? _get_search_range(search_wid) : -1;
   mfflags := _get_mfflags(true);
   misc_options := _get_misc_search_opts();
   save_last_search('', search_options, search_range, mfflags, misc_options);
   search_string := _findstring.p_text;
   if (search_string != '') {
      _append_retrieve(0, search_string, "_tbfind_form._findstring");
   }
   replace_string := _replacestring.p_text;
   save_last_replace(replace_string);
   _end_incremental_search();
   toggle_search_flags(0, VSSEARCHFLAG_FINDHILIGHT);
   call_event(p_window_id, ON_DESTROY, '2');
   _clear_last_found_cache();
   ignore_change = false;
   ignore_switchbuf = false;
   ignore_close = false;

   timer_id := _GetDialogInfo(DLGINFO_TIMER_ID, _control _find_btn);
   if ( timer_id != null && _timer_is_valid(timer_id) ) {
      _kill_timer(timer_id);
      _SetDialogInfo(DLGINFO_TIMER_ID,-1, _control _find_btn);
   }
}

void _lostfocus_tbfind()
{
   _end_incremental_search();
}

void _tbfind_form.ESC()
{
   if (ArgumentCompletionKey(last_event())) {
      return;
   }
   ignore_change = true;
   ignore_switchbuf = true;
   current_wid := _get_current_search_wid();
   tw_dismiss(p_active_form);
   _show_current_search_window(current_wid);
}

void _tbfind_form.on_close()
{
   if (ignore_close) {
      return;
   }
   ignore_change = true;
   ignore_switchbuf = true;
   ignore_close = true;
   call_event(p_window_id, ON_CLOSE, '2');
}

void _tbfind_form.'C-A'-'C-Z','c-s-a'-'c-s-z','c-a-a'-'c-a-z',F1-F12,C_F12,A_F1-A_F12,S_F1-S_F12,'c-0'-'c-9','c-s-0'-'c-s-9','c-a-0'-'c-a-9','a-0'-'a-9','M-A'-'M-Z','M-0'-'M-9','S-M-A'-'S-M-Z','S-M-0'-'S-M-9'()
{
   if (ignore_change) {
      return;
   }
   _str key = last_event();
   _str keyname = name_on_key(key);

   _macro('m', _macro('s'));
   if (keyname == "gui-find") {
      _init_mode(VSSEARCHMODE_FIND);
      if (def_keys == "brief-keys") {
         _set_search_options("+");
      }
      return;
   } else if (keyname == "gui-find-backward") {
      _init_mode(VSSEARCHMODE_FIND);
      _set_search_options("-");
      return;
   } else if (keyname == "gui-find-regex") {
      _init_mode(VSSEARCHMODE_FIND);
      if (def_re_search_flags & VSSEARCHFLAG_PERLRE) {
         _set_search_options("L");
      } else if (def_re_search_flags & VSSEARCHFLAG_VIMRE) {
         _set_search_options("~");
      } else if (def_re_search_flags & VSSEARCHFLAG_WILDCARDRE) {
         _set_search_options("&");
      } else {
         _set_search_options("R");
      }
      return;
   } else if (keyname == "gui-replace") {
      _init_mode(VSSEARCHMODE_REPLACE);
      if (def_keys == "brief-keys") {
         _set_search_options("+");
      }
      return;
   } else if (keyname == "gui-replace-backward") {
      _init_mode(VSSEARCHMODE_REPLACE);
      _set_search_options("-");
      return;
   } else if (keyname == "gui-replace-regex") {
      _init_mode(VSSEARCHMODE_REPLACE);
      if (def_re_search_flags & VSSEARCHFLAG_PERLRE) {
         _set_search_options("L");
      } else if (def_re_search_flags & VSSEARCHFLAG_VIMRE) {
         _set_search_options("~");
      } else if (def_re_search_flags & VSSEARCHFLAG_WILDCARDRE) {
         _set_search_options("&");
      } else {
         _set_search_options("R");
      }
      return;
   } else if (keyname == "find-in-files") {
      _init_mode(VSSEARCHMODE_FINDINFILES);
      return;
   } else if (keyname == "replace-in-files") {
      _init_mode(VSSEARCHMODE_REPLACEINFILES);
      return;
  } else if (keyname == "find-file") {
      _init_mode(VSSEARCHMODE_FILES);
      return;
   } else if (keyname == "find-next") {
      _tbfind_OnFindNext(false);
      return;
   } else if (keyname == "find-prev") {
      _tbfind_OnFindNext(true);
      return;
   }

   switch (key) {
   case name2event('M_E'):
      if (_findcase.p_enabled && _findcase.p_visible) {
         _findcase.p_value= _findcase.p_value?0:1;
         _findcase._set_focus();
      }
      return;
   case name2event('C_W'):
      doCurrentWordAtCursor();
      return;
   case name2event('A_S_O'):
      _findcolormenu.call_event(_control _findcolormenu, LBUTTON_UP, "W");
      return;
   }
   _smart_toolwindow_hotkey();
#if 0
   if (key :== F7) {
      _retrieve_next_form('-',1); return;
   } else if (key :== F8) {
      _retrieve_next_form('',1); return;
   }

   // pass through to default eventtabs
   active_form_wid := p_active_form;
   int old_eventtab = active_form_wid.p_eventtab;
   active_form_wid.p_eventtab = 0;
   call_key(key);
   active_form_wid.p_eventtab = old_eventtab;
#endif
}

void _tbfind_form.'C-TAB','C-S-TAB'()
{
   _findtabs.call_event(_findtabs.p_eventtab2, last_event(), 'e');
}

void _tbfind_form.'A_S_O'()
{
   _findcolormenu.call_event(_control _findcolormenu, LBUTTON_UP, "W");
}

void _tbfind_form.on_got_focus()
{
   _update_search_buffer();
}

static void _switch_to_mini_find()
{
   int form_wid = _find_formobj("_tbfind_form", 'n');
   if (!form_wid) {
      return;
   }
   search_wid := form_wid._get_current_search_wid();
   if (!search_wid) {
      return;
   }
   replace_mode := (_findtabs.p_ActiveTab == VSSEARCHMODE_REPLACE || _findtabs.p_ActiveTab == VSSEARCHMODE_REPLACEINFILES);
   search_string := _findstring.p_text;
   replace_string  := (replace_mode) ? _replacestring.p_text : "";
   search_options := _get_search_options();
   range_mode := ((_findtabs.p_ActiveTab == VSSEARCHMODE_FIND) || (_findtabs.p_ActiveTab == VSSEARCHMODE_REPLACE));
   search_range := range_mode ? _get_search_range(search_wid) : -1;
   mfflags := _get_mfflags(true);
   misc_options := _get_misc_search_opts();
   form_wid._delete_window();

   if (!replace_mode) {
      search_wid.mini_gui_find();
   } else {
      search_wid.mini_gui_replace();
   }
   mini_find_update_options(search_string, replace_string, search_options, search_range, mfflags, misc_options, false);
}


// Special handling for find_next key binding
static void _tbfind_OnFindNext(bool doPrevious)
{
   int form_wid = _find_formobj("_tbfind_form", 'n');
   int search_wid;
   search_wid = (form_wid != 0) ? form_wid._get_current_search_wid() : _mdi._edit_window();
   if (search_wid) {
      search_text := _findstring.p_text;
      _str search_options = _get_search_options();
      get_window_id(auto orig_wid);
      activate_window(search_wid);
      // check to see if search find options are set
      if (!_search_last_found(search_text, search_options, old_search_range)) {
         search('', '@'search_options);
         save_search(old_search_string, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
         old_search_string = search_text;
         set_find_next_msg("Find", search_text, search_options, old_search_range);
         _save_last_found(search_text, search_options);
      }
      if (doPrevious) {
         _macro_call_maybe_stop('find_prev');
         search_wid.find_prev();
      } else {
         _macro_call_maybe_stop('find_next');
         search_wid.find_next();
      }
      activate_window(orig_wid);
   }
}

_command void tbfind_options_menu(_str cmdline = '') name_info(',' VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   form_wid := _tbGetActiveFindAndReplaceForm();
   if (!form_wid) {
      return;
   }
   _macro_delete_line();
   parse cmdline with auto cmd auto opt;
   switch (lowcase(cmd)) {
   case "^":
      doCurrentWordAtCursor();
      break;

   case "^&":
      doGetCurrentSelection();
      break;

   case "o":
      show_general_options(1);
      break;

   case "d":
      _init_options(_default_option('s'));
      _init_misc_search_opts(def_find_misc_options);
      break;

   case "c":
      _init_options(VSSEARCHFLAG_IGNORECASE);
      _set_results_options(MFFIND_GLOBAL);
      break;

   case "s":
      int search_flags = _get_search_flags();
      _default_option('S', search_flags);
      int retype = search_flags & (VSSEARCHFLAG_RE /*| VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE*/ | VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_VIMRE | VSSEARCHFLAG_WILDCARDRE);
      if (retype) {
         def_re_search_flags = retype;
      }
      def_find_misc_options = _get_misc_search_opts();
      _config_modify_flags(CFGMODIFY_DEFVAR);
      break;

   case "t":
      def_find_hide_tabs = !def_find_hide_tabs;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _showhide_controls(form_wid._findtabs.p_ActiveTab, true);
      break;

   case "z":
      clear_highlights();
      break;

   case "co":
      _update_color_search(opt);
      break;

   case "cc":
      _configure_color_search();
      break;

   case "ds":
      _switch_to_mini_find();
      break;
   }
}

void _tbfind_form.rbutton_up()
{
   int x = mou_last_x('M');
   int y = mou_last_y('M');
   if (y < 0 || (p_window_id == p_active_form)) {
      // non-client event pass-through to parent event-handler
      call_event(p_window_id, RBUTTON_UP, '2');
      return;
   }

   int flags, submenu_handle1, submenu_handle2;
   int index = find_index("_tbfindoptions_menu", oi2type(OI_MENU));
   int menu_handle = p_active_form._menu_load(index, 'P');
   _str menu_text = def_find_hide_tabs ? "Show Tabs" : "Hide Tabs";
   _menu_set_state(menu_handle, "tbfind_options_menu t", MF_ENABLED, 'M', menu_text);

   // add saved search expressions to menu
   _menu_get_state(menu_handle, 0, flags, 'p', '', submenu_handle1);

   _str array[];
   _get_saved_search_names(array);
   if (array._length() <= 0) {
      _menu_insert(submenu_handle1, 0, MF_GRAYED, "None", "", "", "", "");
   } else {
      int i;
      for (i = 0; i < array._length(); ++i) {
         menu_text = 'tbfind_expressions_menu a ':+ array[i];
         _menu_insert(submenu_handle1, i, MF_ENABLED, array[i], menu_text, "", "", "");
      }
   }

   search_wid := _get_current_search_wid();
   int status, mh, mpos;
   if (!search_wid || !search_wid._isEditorCtl(false)) {
      status = _menu_find(menu_handle, "tbfind_options_menu ds", mh, mpos, 'M');
      if (!status) {
         _menu_delete(mh, mpos);
      }
      status = _menu_find(menu_handle, "tbfind_options_menu ^", mh, mpos, 'M');
      if (!status) {
         _menu_delete(mh, mpos);
      }      
      status = _menu_find(menu_handle, "tbfind_options_menu ^&", mh, mpos, 'M');
      if (!status) {
         _menu_delete(mh, mpos);
      }
   }

   x = x - 100;
   y = y - 100;
   _lxy2dxy(p_scale_mode, x, y);
   _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   flags = VPM_LEFTALIGN | VPM_RIGHTBUTTON;
   status = _menu_show(menu_handle, flags, x, y);
   _menu_destroy(menu_handle);
}

void _tbfind_form.on_resize()
{
   ArgumentCompletionTerminate(true);
   _resize_frame_widths();
}

static int _get_current_search_wid()
{
   if ( p_active_form && p_active_form.p_name == "_tbfind_form" ) {
      int wid =  _GetDialogInfo(DLGINFO_CURRENT_SEARCH_WID, _control _find_btn);
      if (wid > 0 && _iswindow_valid(wid)) {
         return wid;
      }
   }
   return 0;
}

static int _activate_current_search_wid()
{
   window_id := _get_current_search_wid();
   if (window_id == 0) {
      return(0);
   }
   activate_window(window_id);
   _ExitScroll();
   return(window_id);
}

/*** find tabs ***/
void _findtabs.on_create()
{
   _findtabs.p_DocumentMode = true;
}

void _findtabs.on_change(int reason)
{
   if (ignore_change) {
      return;
   }
   if (reason == CHANGE_TABACTIVATED) {
      _showhide_controls(p_ActiveTab,true);
   }
}

/*** find matches ***/
int _search_next_in_project(_str search_text, _str search_options, bool search_workspace, bool search_current_buffer = true)
{
   typeless p;
   status := 0;
   cur_filename := "";
   search_backwards := (pos('-', search_options) != 0);
   get_window_id(auto orig_wid);

   if (_activate_current_search_wid()) {
      // only allow in mdi child
      if (!p_mdi_child) {
         return _search_current_buffer(search_text,search_options,VSSEARCHRANGE_CURRENT_BUFFER);
      }
      if (search_current_buffer) {
         // search current buffer first
         status = search(search_text, '@'search_options'<');
         if (!status) {
            activate_window(orig_wid);
            return _search_current_buffer(search_text,search_options,VSSEARCHRANGE_CURRENT_BUFFER);
         } else if (status != STRING_NOT_FOUND_RC) {
            return status;
         }
      }
   }

   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   orig_buf_id := 0;
   orig_window_id := 0;
   if (!_no_child_windows() && _mdi.p_child.pop_destination()) {
      orig_window_id = _mdi.p_child;
      orig_buf_id = _mdi.p_child.p_buf_id;
   }

   buf_id := 0;
   filename := '';
   if (search_workspace) {
      if (_workspace_filename != '') {
         FindNextFile.init_workspace_list(_workspace_filename);
         filename = FindNextFile.workspace_get_next_file(cur_filename);
      }
   } else {
      if (_project_name != '') {
         FindNextFile.init_project_list(_project_name);
         filename = FindNextFile.project_get_next_file(cur_filename);
      }
   }
   if (filename :== '') {
      activate_window(orig_wid);
      return FILE_NOT_FOUND_RC;
   }
   first_filename := filename;

   bool file_already_loaded;
   int temp_view_id,orig_view_id;
   for (;;) {
      status = _open_temp_view(strip(filename), temp_view_id, orig_view_id, '', file_already_loaded, false, true, 0, false, false);
      if (!status) {
         _updateTextChange(); 
         if (search_backwards) {
            bottom();
         } else {
            top(); up();
         }
         status = search(search_text, '@'search_options'<');
         if (!status) {
            save_pos(p); buf_id = p_buf_id;
            break;
         }
         _delete_temp_view(temp_view_id);
      }
      if (search_workspace) {
         filename = FindNextFile.workspace_get_next_file(filename);
      } else {
         filename = FindNextFile.project_get_next_file(filename);
      }
      if ((filename :== '') || (filename :== first_filename) || (filename :== cur_filename)) {
         status = FILE_NOT_FOUND_RC;
         break;
      }
   }
   if (!status && (buf_id > 0)) {
      int edit_status = edit('+q +bi 'buf_id);
      if (!edit_status) {
         restore_pos(p);
         _init_current_search_buffer(p_window_id);
         // do find
         find(search_text, '@'search_options);
         _mdi.p_child.push_destination(orig_window_id, orig_buf_id);
      }
      _delete_temp_view(temp_view_id);
   }
   activate_window(orig_wid);
   return status;
}

int _search_all_buffers(_str search_text, _str search_options)
{
   //say('_search_all_buffers');
   _macro_call('_search_all_buffers', search_text, search_options);
   if (_no_child_windows()) {
      return(FILE_NOT_FOUND_RC);
   }
   int was_recording = _macro('s');
   search_backwards := (pos('-', search_options) != 0);
   int status;
   int orig_wid;
   get_window_id(orig_wid);
   activate_window(_mdi.p_child);
   save_pos(auto p);
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   int orig_buf_id = p_buf_id;
   int first_buf_id = _mdi.p_child.p_buf_id;
   int current_buffer_id;
   p_buf_id = first_buf_id;
   restore_pos(p);
   for (;;) {
      current_buffer_id = p_buf_id;
      status = find(search_text, '@'search_options);
      if (!status) {
         save_pos(p);
         break;
      }
      restore_pos(p);
      _next_buffer('nr');
      if (p_buf_id == first_buf_id) {
         break;
      }
      save_pos(p); 
      if (search_backwards) {
         bottom();
      } else {
         top();
      }
   }
   p_buf_id = orig_buf_id;
   if (!status) {
      int edit_status = edit('-bp +q +bi 'current_buffer_id);
      if (!edit_status) {
         restore_pos(p);
         _init_current_search_buffer(p_window_id);
      }
   }
   activate_window(orig_wid);
   _macro('m', was_recording);
   return(status);
}

static int _search_current_buffer(_str search_text, _str search_options, int search_range)
{
   //say('_search_current_buffer');
   int status;
   int orig_wid;
   int was_recording = _macro('s');
   get_window_id(orig_wid);
   if (0 == _activate_current_search_wid()) {
      return(FILE_NOT_FOUND_RC);
   }
   int orig_mark = _duplicate_selection('');
   mark_id := 0;
   if (search_range == VSSEARCHRANGE_CURRENT_PROC) {
      mark_id = _get_proc_mark();
      _show_selection(mark_id);
   }
   status = find(search_text, search_options);
   _macro('m', was_recording);
   _macro_call_maybe_stop('find', search_text, search_options);
   if (!status) {
      if (mark_id) {
         if (mark_id == _duplicate_selection('')) {
            _show_selection(orig_mark);
            _free_selection(mark_id);
         } else {
            _free_selection(orig_mark);
         }
      }
   } else {
      _show_selection(orig_mark);
      if (mark_id) {
         _free_selection(mark_id);
      }
   }
   activate_window(orig_wid);
   _macro('m', was_recording);
   return(status);
}

static int _search_next(_str search_text, _str search_options, int search_range)
{
   //say('_search_next');
   int orig_wid;
   int status = STRING_NOT_FOUND_RC;
   get_window_id(orig_wid);
   if (!_activate_current_search_wid()) {
      if (search_range == VSSEARCHRANGE_PROJECT) {
         status = _search_next_in_project(search_text, search_options, false);
      } else if (search_range == VSSEARCHRANGE_WORKSPACE) {
         status = _search_next_in_project(search_text, search_options, true);
      }
      activate_window(orig_wid);
      return(status);
   }
   _macro('m', _macro('s'));
   _macro_call_maybe_stop('find_next');
   status = find_next();
   activate_window(orig_wid);
   return(status);
}

static int _search_continue()
{
   if (_findtabs.p_ActiveTab == VSSEARCHMODE_FIND) {
      if (_findinc.p_value && _findinc.p_enabled && def_find_close_on_default) {
         if (tw_is_auto_raised(p_active_form) || (!tw_is_auto_form(p_active_form.p_name) && !tw_is_docked(p_active_form.p_name))) {
            return (1);
         }
      }
   }
   return (0);
}

static int _search(_str search_text, _str search_options, int search_range)
{
   int status;
   list_all := (_findlist_all.p_value != 0) && _findlist_all.p_enabled;
   add_cursors := (_findmc.p_value != 0) && _findmc.p_enabled;

   mou_hour_glass(true);

   do_next := true;
   if (add_cursors || list_all) {
      do_next = false;
   }
   grep_id := 0;
   if (list_all) {
      grep_id = _get_grep_buffer_id();
   }

   status = _mark_all(search_text, search_options, search_range, grep_id);
   if (do_next && !_search_continue()) {
      if (!_search_last_found(search_text, search_options, search_range)) {
         old_search_range = search_range;
         if (search_range == VSSEARCHRANGE_ALL_BUFFERS) {
            status = _search_all_buffers(search_text, search_options);
         } else if (search_range == VSSEARCHRANGE_PROJECT) {
            status = _search_next_in_project(search_text, search_options, false);
         } else if (search_range == VSSEARCHRANGE_WORKSPACE) {
            status = _search_next_in_project(search_text, search_options, true);
         } else {
            status = _search_current_buffer(search_text, search_options, search_range);
         }
      } else {
         status = _search_next(search_text, search_options, search_range);
      }

      if (list_all) {
         SearchResults.resetFindMark(grep_id);
      }
   } else if (!list_all) {
      if (_findtabs.p_ActiveTab == VSSEARCHMODE_FIND && _findinc.p_value) {
         _begin_incremental_search();
      }
   }

   if (!status) {
      _findstring._show_textbox_error_color(false);
      _save_last_found(search_text, search_options);
   } else {
      message(get_message(status));
      _findstring._show_textbox_error_color(true);
      _findstring._set_focus();
   }
   mou_hour_glass(false);
   return(status);
}

static void _search_in_files(_str search_text, _str search_options)
{
   int grep_id = _get_grep_buffer_id();
   mfflags := 0;
   files := "";
   wildcards := "";
   exclude := "";
   int orig_wid;
   grep_before_lines := 0;
   grep_after_lines := 0;
   file_stats := '';
   _get_files_list(files, wildcards, exclude);
   if (files != '') {
      mfflags = _get_mfflags();
      _get_mfablines(mfflags, grep_before_lines, grep_after_lines);
      file_stats = (_mffilesstats.p_value) ? _findfilestats.p_text : "";
   }
   get_window_id(orig_wid);
   p_window_id = _mdi.p_child;
   _macro('m', _macro('s'));
   _macro_call('_mffind2',search_text, search_options, files, wildcards, exclude, mfflags, grep_id,grep_before_lines,grep_after_lines,file_stats);
   _mffind2(search_text, search_options, files, wildcards, exclude, mfflags, grep_id, grep_before_lines, grep_after_lines, file_stats);
   activate_window(orig_wid);
   if (_findtabs.p_ActiveTab == VSSEARCHMODE_FINDINFILES) {
      _find_btn.p_enabled = (gbgm_search_state == 0);
   } else {
      _find_btn.p_enabled = true;
   }
   _stop_btn.p_enabled = (gbgm_search_state != 0);
}

static void _search_files()
{
   int grep_id = _get_grep_buffer_id();
   int mfflags = MFFIND_FILESONLY;
   files := "";
   wildcards := "";
   excludes := "";
   file_stats := "";
   _get_files_list(files, wildcards, excludes);
   if (files != '') {
      if (_mfappendgrep.p_value)        mfflags |= MFFIND_APPEND;
      if (_mfmdichild.p_value)          mfflags |= MFFIND_MDICHILD;
      if (_findinzipfiles.p_value && _findinzipfiles.p_visible) {
         mfflags |= MFFIND_LOOKINZIPFILES;
      }
      file_stats = (_mffilesstats.p_value) ? _findfilestats.p_text : "";
   }

   _macro('m', _macro('s'));
   _macro_call('find_files_search',files, wildcards, excludes, mfflags, grep_id, file_stats);
   find_files_search(files, wildcards, excludes, mfflags, grep_id, file_stats);
}

void find_files_search(_str files, _str wildcards, _str excludes, int mfflags, int grep_id, _str file_stats='')
{
   int orig_wid;
   get_window_id(orig_wid);
   p_window_id = _mdi.p_child;

   start_bgsearch("","",
                  files,mfflags|MFFIND_FIND_FILES,
                  false,
                  false,
                  wildcards,
                  excludes,
                  true,
                  grep_id,
                  0,0,
                  file_stats);

   activate_window(orig_wid);
   if (orig_wid.p_mdi_child) {
      orig_wid._set_focus(); // may have lost focus to search results
   }
}

static bool _validate_find_paths(_str files, bool allow_simple_wildcard_suffix=false) {
   _str path;
   while (files!='') {
      path=parse_file_sepchar(files,';',false);
      if (substr(path,1,1)=='<') {
         continue;
      }
      path2:=path;
      _maybe_append_filesep(path2);
      if (!_findFirstTimeOut(path2,def_fileio_timeout,def_fileio_continue_to_timeout)) {
         /*
             isdirectory works for plugin://com_slickedit.base/
             chdir does not.
         */
         if (!isdirectory(path2)) {
            if (length(path2) && allow_simple_wildcard_suffix) {
               path3:=substr(path2,1,length(path2)-1);
               name:=_strip_filename(path3,'p');
               if (iswildcard(name) && isdirectory(_strip_filename(path3,'n'))) {
                  /* Allow this: 
                       Look in: c:\source\*.cpp
                     Caller uses *.cpp as the wildcards and ignores
                     the wildcards specified in "File types".
                  */
                  continue;
               }
            }
            _message_box(nls("Path '%s' does not exist",path));
            return true;
         }
#if 0
         // Could be an empty directory
         orig_cwd:=getcwd();
         status:=chdir(path,1);
         chdir(orig_cwd,1);
         if (status) {
            _message_box(nls("Path '%s' does not exist",path));
            return true;
         }
#endif
         //path=path:+'*';
         //if (file_match('+p +d +h +s '_maybe_quote_filename(path),1)=='') {
         //}

      }
   }
   return false;
}
static bool _validate_regex(_str search_text,_str re_syntax) {
   if (re_syntax=='') {
      return false;
   }
   status:=pos(search_text,'',1,re_syntax);
   if (status<0) {
      _message_box('Invalid regular expression');
      return true;
   }
   return false;
}
static void _begin_find()
{
   form_wid := p_active_form;
   _mffindNoMore(1);
   _mfrefNoMore(1);
   clear_scroll_highlights();
   search_text := _findstring.p_text;
   if (search_text :== '' && (form_wid._findtabs.p_ActiveTab != VSSEARCHMODE_FILES)) {
      return;
   }
   status := 0;
   mode := form_wid._findtabs.p_ActiveTab;

   current_wid := _get_current_search_wid();

   _str search_options = _get_search_options(-1,auto re_syntax);
   if (current_wid && current_wid._isEditorCtl(false)) {
      /* Setting focus here sets _MDICurrent(). That way
         if the Search Results tool window is docked to
         another MDI window, it will be found.

         If this causes problems, there aren't any great 
         solutions. 

         One alternate solution is to require each MDI window
         with an MDI area to "own" a Find And Replace tool window.
         Parenting would have to be done to the MDI window with
         MDI area.

         Possible TODO later
         If a modal has an editor control and a request for 
         the Find/replace tool window is made, a new instance
         should be created, parent to the form, disable all 
         multi-file tabs, could display modal so don't have to worry
         about form going away when Find/replace dialog is parented
         to it.
      */ 
      ignore_change = true;
      ignore_switchbuf = true;
      focus_wid := _get_focus();
      current_wid._set_focus();
      ignore_change = false;
      ignore_switchbuf = false;
   }
   switch (mode) {
   case VSSEARCHMODE_FIND:
   case VSSEARCHMODE_REPLACE:
      if (!current_wid) {
         message("No active window for search");
         return;
      }
      if(_validate_regex(_findstring.p_text,re_syntax)) {
         _findstring._set_focus();
         return;
      }
      status = _search(search_text, search_options, _get_search_range(current_wid));
      break;
   case VSSEARCHMODE_FINDINFILES:
      if(_validate_find_paths(_findfiles.p_text,true)) {
         _findfiles._set_focus();
         return;
      }
      if(_validate_regex(_findstring.p_text,re_syntax)) {
         _findstring._set_focus();
         return;
      }
      _search_in_files(search_text, search_options);
      break;

   case VSSEARCHMODE_FILES:
      if(_validate_find_paths(_findfiles.p_text,true)) {
         _findfiles._set_focus();
         return;
      }
      _search_files();
      break;
   }
   current_wid = _get_current_search_wid();
   _append_save_history(search_text, search_options);
   _tool_hide_on_default();
   _show_current_search_window(current_wid);

   pip_log_regex_search(search_options);
}

/**
 * Find all occurences of the word at the cursor in the current
 * file.  Results are listed and highlighted.  Comments and
 * Strings are not searched. Used in Eclipse emulation.
 *
 * @see find
 * @appliesTo Edit_Window, Editor_Control
 * @categories Search_Functions
 */
_command void quick_mark_all_occurences() name_info(','VSARG2_MARK|VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   _str cw = cur_word(auto sc);
   mark_all_occurences(cw,'WHP,XSC',0,0,0,true,true,false,true,false);
}

void _list_all_in_project(_str search_text, _str search_options, bool search_workspace, int mfflags, int grep_id, int grep_before_lines, int grep_after_lines)
{
   if (!(mfflags & (MFFIND_THREADED|MFFIND_GLOBAL))) {
      mfflags |= MFFIND_THREADED;
   }
   _mffind2(search_text, search_options, (search_workspace) ? "<Workspace>" : "<Project>", ALLFILES_RE, "", mfflags, grep_id, grep_before_lines, grep_after_lines);
} 

int mark_all_occurences(_str search_text, _str search_options, int search_range, int mfflags, int grep_id, bool show_hilite, bool list_all, bool show_bookmarks, bool scroll_markup, bool add_cursors=false, int grep_before_lines=0, int grep_after_lines=0)
{
   status := 0;
   num_matches := 0;
   int orig_wid; get_window_id(orig_wid);
   int was_recording = _macro('m', _macro('s'));
   _str new_search_options = search_options;
   SearchResults results;
   _macro_call('mark_all_occurences',search_text,search_options,search_range,mfflags,grep_id,show_hilite,list_all,show_bookmarks,scroll_markup,add_cursors,grep_before_lines,grep_after_lines);
   _macro('m', 0);
   if (show_hilite) {
      clear_highlights();
      new_search_options :+= '#';
   }
   if (scroll_markup) {
      clear_scroll_highlights();
      new_search_options :+= '%';
   }
   if (add_cursors) {
      new_search_options :+= '|';
   }
   list_workspace := list_all && ((search_range == VSSEARCHRANGE_WORKSPACE) || (search_range == VSSEARCHRANGE_PROJECT));
   num_files := 0;
   typeless s1, s2, s3, s4, s5; save_search(s1, s2, s3, s4, s5);
   if (search_range == VSSEARCHRANGE_ALL_BUFFERS) {
      activate_window(VSWID_HIDDEN);
      _safe_hidden_window();
      int orig_buf_id = p_buf_id;
      int first_buf_id = _mdi.p_child.p_buf_id;
      if (list_all) {
         _mdi.p_child.mark_already_open_destinations();
         topline := se.search.generate_search_summary(search_text, new_search_options, SEARCH_IN_ALL_BUFFERS, mfflags, "", "");
         results.initialize(topline, search_text, mfflags, grep_id, grep_before_lines, grep_after_lines);
      }
      p_buf_id = first_buf_id;
      for (;;) {
         if (!_isGrepBuffer(p_buf_name)) {
            num_matches += _find_all(search_text, new_search_options, show_bookmarks, list_all, &results);  ++num_files;
         }
         _next_buffer('nr');
         if (p_buf_id == first_buf_id) {
            break;
         }
      }
      p_buf_id = orig_buf_id;

   } else if (list_workspace) {
      _list_all_in_project(search_text, new_search_options, (search_range == VSSEARCHRANGE_WORKSPACE), mfflags, grep_id, grep_before_lines, grep_after_lines);
      list_all = false; // turn off results at bottom

   } else {
      if (list_all && _isGrepBuffer(p_buf_name)) {
         _message_box("Cannot perform operation in search results window.");
         list_all = false;
      } else {
         if (list_all) {
            _mdi.p_child.mark_already_open_destinations();
            topline := se.search.generate_search_summary(search_text, new_search_options, "", mfflags, "", "");
            results.initialize(topline, search_text, mfflags, grep_id, grep_before_lines, grep_after_lines);
         }
         int orig_mark = _duplicate_selection('');
         mark_id := 0;
         if (search_range == VSSEARCHRANGE_CURRENT_PROC) {
            mark_id = _get_proc_mark();
            _show_selection(mark_id);
            new_search_options :+= 'M';
         }
         num_matches = _find_all(search_text, new_search_options, show_bookmarks, list_all, &results);  ++num_files;
         if (mark_id) {
            if (mark_id == _duplicate_selection('')) {
               _show_selection(orig_mark);
               _free_selection(mark_id);
            } else {
               _free_selection(orig_mark);
            }
         }
         save_search(old_search_string, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
         save_last_search(search_text, new_search_options);
      }
   }
   restore_search(s1, s2, s3, s4, s5);
   if (num_matches) {
      message('Find "'search_text'", '_get_search_range_label(search_range)' found 'num_matches' occurrences');
      if (show_bookmarks) {
         activate_bookmarks();
         updateBookmarksToolWindow();
      }
      status = 0;
   } else if (!list_workspace) {
      message('No occurrences found.');
      status = STRING_NOT_FOUND_RC;
   }
   old_search_flags &= ~(VSSEARCHFLAG_FINDHILIGHT|VSSEARCHFLAG_SCROLLHILIGHT);
   if (list_all) {
      if (mfflags & MFFIND_FILESONLY) {
         results.done('Matching files: 'num_matches'     Total files searched: 'num_files);
      } else {
         results.done('Total found: ':+num_matches);
      }
      results.showResults();
      if (orig_wid.p_mdi_child) {
         orig_wid._set_focus(); // may have lost focus to search results
      }
   }
   _macro('m', was_recording);
   activate_window(orig_wid);
   return (status);
}

static int _mark_all(_str search_text, _str search_options, int search_range, int grep_id)
{
   int orig_wid; get_window_id(orig_wid);
   show_hilite := (_findmark_all.p_value != 0) && _findmark_all.p_enabled;
   show_bookmarks := (_findbookmark_all.p_value != 0) && _findbookmark_all.p_enabled;
   list_all := (_findlist_all.p_value != 0) && _findlist_all.p_enabled;
   add_cursors := (_findmc.p_value != 0) && _findmc.p_enabled;
   grep_before_lines := 0;
   grep_after_lines := 0;
   if (!show_hilite && !show_bookmarks && !list_all && !add_cursors) {
      return (0);
   }
   scroll_markup := show_hilite || list_all;
   mfflags := 0;
   if (list_all) {
      if (_mfappendgrep.p_value)        mfflags |= MFFIND_APPEND;
      if (_mfmdichild.p_value)          mfflags |= MFFIND_MDICHILD;
      if (_mfmatchlines.p_enabled && _mfmatchlines.p_value) mfflags |= MFFIND_SINGLELINE;
      if (_mflistmatchonly.p_enabled &&_mflistmatchonly.p_value) mfflags |= MFFIND_MATCHONLY;
      if (_mflistfilesonly.p_visible && _mflistfilesonly.p_enabled && _mflistfilesonly.p_value) mfflags |= MFFIND_FILESONLY;
      if (_mflistcontext.p_enabled && _mflistcontext.p_value) mfflags |= MFFIND_LIST_CURRENT_CONTEXT;
      _get_mfablines(mfflags, grep_before_lines, grep_after_lines);
   }

   int temp_view_id = 0;
   if (!_activate_current_search_wid()) {
       if (list_all && ((search_range == VSSEARCHRANGE_WORKSPACE) || (search_range == VSSEARCHRANGE_PROJECT))) {
          _create_temp_view(temp_view_id);
          activate_window(temp_view_id);
          top(); up();
       } else {
          return (0);
       }
   }

   save_pos(auto p);
   int status = mark_all_occurences(search_text, search_options, search_range, mfflags, grep_id, show_hilite, list_all, show_bookmarks, scroll_markup, add_cursors, grep_before_lines, grep_after_lines);
   if (list_all && !show_hilite && !show_bookmarks && !add_cursors) {
      restore_pos(p);
   }
   activate_window(orig_wid);
   if (temp_view_id) {
      _delete_temp_view(temp_view_id);
   }
   return (status);
}

int def_max_scrollbar_highlight=2000;

static int _find_all(_str search_text = '', _str search_options = '', bool addBookmark = false, bool listAll = false, SearchResults* results = null)
{
   if (search_text:=='') {
      return 0;
   }
   num_bookmarks := 0;
   num_matches := 0;

   last_line := -1;
   addCursors := false;
   addHighlights := false;
   markSearch := false;
   cursorEnd := false;
   filesOnly := false;
   if (pos('|',search_options)) {
      _searchResetAllMultiCursors();
      addCursors = true;

      if (pos('M',upcase(search_options))) {
         markSearch = true;
      }
      if (pos('>',search_options)) {
         cursorEnd = true;
      }
   }
   if (pos('#',search_options)) {
      addHighlights = true;
   }
   if (listAll && !addHighlights && !addCursors && !addBookmark) {
      if ((results != null) && (results->getMFFlags() & MFFIND_FILESONLY)) {
         filesOnly = true;
      }
   }

   if (listAll && p_buf_size<def_use_old_line_numbers_ksize*1024) {
      _SetAllOldLineNumbers();
   }
   save_pos(auto p);
   orig_SoftWrap:=p_SoftWrap;p_SoftWrap=false;
   search_mark := (pos('m', search_options, 1, 'I') != 0);
   if (search_mark) {
      _begin_select(); _begin_line();
   } else {
      top();
   }

   _str selection_markid = _alloc_selection();
   maybe_turn_off_scrollbar_highlight := true;
   typeless start_time=_time('b');
   status := search(search_text, 'xv,@'search_options'<+');
   save_search(auto ss1,auto ss2,auto ss3,auto ss4,auto ss5);
   re_search := (ss2 & (VSSEARCHFLAG_RE /*| VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE*/ | VSSEARCHFLAG_PERLRE|VSSEARCHFLAG_VIMRE | VSSEARCHFLAG_WILDCARDRE));
   if (!status) {
      // When adding cursors, must save/restore cursor where the first match is.
      // Otherwise, end up with an extra cursor.
      if (addCursors) {
         save_pos(p);
         _MaybeUnhideLine(selection_markid);
      }
      while (!status) {
         _MaybeUnhideLine();
         if (addBookmark && (last_line != p_RLine)) {
            if (num_bookmarks > def_find_high_added_bookmarks) {
               int result = _message_box("Adding a large number bookmarks to this buffer.  Continue adding bookmarks?", "", MB_YESNOCANCEL|MB_ICONQUESTION);
               if (result == IDCANCEL) {
                  break;
               } else if (result == IDNO) {
                   addBookmark = false;
               }
            }
            if (addBookmark) {
               if (isEclipsePlugin()) {
                  set_bookmark("Bookmark: '"get_bookmark_name()"'");
               } else{
                  set_bookmark('-r 'get_bookmark_name(), true);
               }
               last_line = p_RLine;
               ++num_bookmarks;
            }
         }
         if (addCursors) {
            _searchAddMultiCursor(markSearch, cursorEnd);
         }
         if (listAll && results != null) {
            results->insertCurrentMatch();
         }
         ++num_matches;
         if (filesOnly) {
            break;
         }
         typeless end_time=_time('b');
         if (end_time-start_time>500) { // More than .5 seconds?
            start_time=end_time;
            if (_IsKeyPending(false)) {
               int orig_def_actapp=def_actapp;
               def_actapp=0;
               save_search(ss1,ss2,ss3,ss4,ss5);
               flush_keyboard();
               int result1=_message_box('Would you like to cancel listing all occurences?','',MB_YESNO);
               restore_search(ss1,ss2,ss3,ss4,ss5);
               def_actapp=orig_def_actapp;
               if (result1!=IDNO) {
                  break;
               }
            }
         } 
         if (addCursors || (re_search && !def_search_result_list_nested_re_matches)) {
            match_len := match_length('');
            if (match_len > 0) {
               goto_point(match_length('s') + match_len - 1);
            }
         }

         status = repeat_search();
         if (maybe_turn_off_scrollbar_highlight && num_matches>def_max_scrollbar_highlight) {
            /*
                If have a large number of matches, updating the scrollbar can be too slow if in 
                line number mode. If we could force the scroll bar into byte mode, this could handle
                way more matches. Not sure handling more matches here is useful though.
            */
            save_search(ss1,ss2,ss3,ss4,ss5);
            ss2&= ~VSSEARCHFLAG_SCROLLHILIGHT;
            restore_search(ss1,ss2,ss3,ss4,ss5);
            maybe_turn_off_scrollbar_highlight=false;
         }
      }
      if (listAll && results != null) {
         results->endCurrentFile();
      }
      
      if ((!select_active() || !markSearch) && def_leave_selected) {
         if (!addCursors) {
            int amarkid = _duplicate_selection('');
            _show_selection(selection_markid);
            _free_selection(amarkid);
         } else {
            _free_selection(selection_markid);
            _deselect();
         }
      } else if (select_active() && !markSearch && _cursor_move_deselects()) {
         _free_selection(selection_markid);
         _deselect();
      } else {
         _free_selection(selection_markid);
         if (addCursors && markSearch) {
            _deselect();
         }
      }
   } else {
      _free_selection(selection_markid);
   }
   p_SoftWrap=orig_SoftWrap;
   restore_pos(p);
   return(num_matches);
}

/*** incremental search ***/
typedef struct {
   int  window_id;
   _str start_pos;
   _str last_pos;
   int  search_range;
   int  orig_mark;
   int  search_mark;
   int  last_status;
   bool macro_update;
} INCREMENTAL_SEARCH_STATE;

static INCREMENTAL_SEARCH_STATE is_state;

static int _buffer_incremental_search(_str search_text, _str search_options)
{
   int status;
   if (search_text :== '') {
      return(STRING_NOT_FOUND_RC);
   }
   status = search(search_text, 'xv,@'search_options);
   typeless junk;
   int search_flags;
   save_search(junk, search_flags, junk);
   if (status && (search_flags & VSSEARCHFLAG_WRAP)) {
      typeless p; save_pos(p);
      if (search_flags & VSSEARCHFLAG_REVERSE) {
         if (search_flags & VSSEARCHFLAG_MARK) {
            _end_select(); _end_line();
         } else {
            bottom();
         }
      } else {
         if (search_flags & VSSEARCHFLAG_MARK) {
            _begin_select(); _begin_line();
         } else {
            top(); up();
         }
      }
      status = search(search_text, 'xv,@'search_options);
      if (status) {
         restore_pos(p);
      }
   }
   if (!status) {
      save_pos(is_state.last_pos);
      _save_last_found(search_text, search_options);

      match_offset := match_length('S');
      match_len := match_length();
      _isearch_show_current(match_offset, match_len);
   }
   save_search(old_search_string, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
   return(status);
}

static void _init_incremental_search(int search_range)
{
   if ((p_window_id != is_state.window_id) || (search_range != is_state.search_range)) {
      //say('_init_incremental_search');
      is_state.window_id = p_window_id;
      save_pos(is_state.start_pos);
      is_state.last_pos = is_state.start_pos;
      _init_incremental_search_range(search_range);
      is_state.orig_mark = _duplicate_selection();
      is_state.macro_update = false;
   }
}

static void _update_last_search_macro(_str search_string, _str search_options)
{
   if (!is_state.macro_update) {
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
   if (!is_state.macro_update) {
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

static void _init_incremental_search_range(int search_range)
{
   is_state.search_range = search_range;
   if (is_state.search_mark) {
      _free_selection(is_state.search_mark);
      is_state.search_mark = 0;
   }
   if (search_range == VSSEARCHRANGE_CURRENT_SELECTION) {
      if ( !select_active() ) {
         is_state.search_mark = _alloc_selection();
         _select_line(is_state.search_mark);
         save_pos(auto p);
         top();
         _select_line(is_state.search_mark, 'E');
         bottom();
         _select_line(is_state.search_mark, 'E');
         restore_pos(p);
      } else {
         is_state.search_mark = _duplicate_selection();
      }
      if (_select_type(is_state.search_mark, 'S') == 'C') {
         _select_type(is_state.search_mark, 'S', 'E');
      }
   } else if (search_range == VSSEARCHRANGE_CURRENT_PROC) {
      is_state.search_mark = _get_proc_mark();
   }
   old_search_range = search_range;
}

static void _end_incremental_search()
{
   if (is_state.window_id != 0) {
      //say('_end_incremental_search');
      is_state.start_pos = '';
      is_state.window_id = 0;
      is_state.last_status = -1;
      if (is_state.search_mark) {
         _free_selection(is_state.search_mark);
      }
      is_state.search_mark = 0;
      if (is_state.orig_mark) {
         _free_selection(is_state.orig_mark);
      }
      is_state.orig_mark = 0;
      is_state.macro_update = false;
   }
   _incsearch_clear_markers();
}


static void _incsearch_init_markers()
{
   if (gIncMarkerType < 0) {
      gIncMarkerType = _MarkerTypeAlloc();
      _MarkerTypeSetFlags(gIncMarkerType, VSMARKERTYPEFLAG_AUTO_REMOVE);
      _MarkerTypeSetPriority(gIncMarkerType, 4);
   }
   if (gIncScrollMarkerType < 0) {
      gIncScrollMarkerType = _ScrollMarkupAllocType();
      _ScrollMarkupSetTypeColor(gIncScrollMarkerType, CFG_HILIGHT);
   }
}

static void _incsearch_clear_markers()
{
   if (gIncMarkerType >= 0){
      _StreamMarkerRemoveAllType(gIncMarkerType);
   }
   if (gIncScrollMarkerType >= 0) {
      _ScrollMarkupRemoveAllType(gIncScrollMarkerType);
   }
}

static int _isearch_mark_all(_str search_string, _str search_options)
{
   match_offset := -1;
   match_len := -1;
   markerID := -1;
   int showMarkers = def_search_incremental_highlight;
   showScrollMarkup := 1;
   num_matches := 0;

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

   _incsearch_init_markers();
   status := search(search_string, 'xv,@'search_options);
   if (!status) {
      lastOffset := -1;
      lastLine := -1;
      for (;;) {
         match_offset = match_length('S');
         match_len = match_length();
         if (match_offset == lastOffset) break;
         if (showMarkers) {
            markerID = _StreamMarkerAdd(p_window_id, match_offset, match_len, false, 0, gIncMarkerType, null);
            if (markerID >= 0) {
               _StreamMarkerSetTextColor(markerID, CFG_INC_SEARCH_MATCH);
               _StreamMarkerSetUserDataInt64(markerID, num_matches+1);
            }
         }
         if (lastLine != p_line) {
            _ScrollMarkupAddOffset(p_window_id, match_offset, gIncScrollMarkerType, match_len);
            lastLine = p_line;
         }
         lastOffset = match_offset;
         ++num_matches;
         if (def_gui_find_max_search_markers > 0 &&
             num_matches >= def_gui_find_max_search_markers) {
            _incsearch_clear_markers();
            break;
         }
         if (repeat_search()) break;
      }
   }
   restore_pos(p);
   return status;
}

static void _isearch_show_current(int match_offset, int match_len)
{
   if (!def_search_incremental_highlight) {
      return;
   }
   markerID := -1;
   _StreamMarkerFindList(auto list, p_window_id, match_offset, 1, 0, gIncMarkerType);
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
      markerID = _StreamMarkerAdd(p_window_id, match_offset, match_len, false, 0, gIncMarkerType, null);
   }
   _StreamMarkerSetTextColor(markerID, CFG_INC_SEARCH_CURRENT);
}

static void _begin_incremental_search()
{
   search_wid := _get_current_search_wid();
   if (!search_wid) {
      return;
   } else if (!_iswindow_valid(search_wid) || !search_wid.p_HasBuffer) {
      _init_current_search_buffer(0);
      return ;
   }
   search_text := _findstring.p_text;
   search_options := _get_search_options();
   search_range := _get_search_range(search_wid);

   get_window_id(auto orig_wid);
   if (0 == _activate_current_search_wid()) {
      return;
   }
   if (p_buf_size > def_gui_find_incremental_search_max_buf_ksize*1024) {
      message('Incremental search disabled: File too large');
      _incsearch_clear_markers();
      activate_window(orig_wid);
      return;
   }
   _mffindNoMore(1);
   _mfrefNoMore(1);
   _gui_find_dismiss();
   _incsearch_clear_markers();
   _init_incremental_search(search_range);
   curr_mark := _duplicate_selection('');
   restore_pos(is_state.start_pos);
   if (is_state.search_mark) {
      _show_selection(is_state.search_mark);
   }
   if (search_text :== '') {
      _maybe_remove_last_search_macro(search_options);
   } else {
      int was_recording = _macro('s');
      if (was_recording) {
         _macro('m', was_recording);
         _update_last_search_macro(search_text, search_options);
      }
      is_state.macro_update = true;
      _isearch_mark_all(search_text, search_options);
   }

   status := _buffer_incremental_search(search_text, search_options);
   if (!status) {
      _str selection_markid = _alloc_selection();
      _MaybeUnhideLine(selection_markid);
      p_LCHasCursor = false;
      if (def_leave_selected) {
         _show_selection(selection_markid);
         _free_selection(curr_mark);
      } else {
         _show_selection(curr_mark);
         _free_selection(selection_markid);
      }
   } else {
      if (search_text :== '') {
         restore_pos(is_state.start_pos);
         if (def_leave_selected) {
            mark_id := _duplicate_selection(is_state.orig_mark);
            _show_selection(mark_id);
            _free_selection(curr_mark);
         } else {
            _show_selection(curr_mark);
         }
      } else {
         restore_pos(is_state.last_pos);
         _show_selection(curr_mark);
      }
   }
   activate_window(orig_wid);
   if (!status || search_text :== '') {   // color coded feedback
      _findstring._show_textbox_error_color(false);
   } else {
      _findstring._show_textbox_error_color(true);
      if (!is_state.last_status) {
         _beep();
      }
   }
   is_state.last_status = status;
   _findstring._set_focus(); //keep focus on the textbox
   _findstring._set_sel(_findstring.p_sel_start+_findstring.p_sel_length); // workaround for losing focus on wrap prompt
}

static bool _search_incremental_last_found_status()
{
   return ((_findtabs.p_ActiveTab == VSSEARCHMODE_FIND) && (_findinc.p_value && _findinc.p_enabled) && (is_state.last_status == 0));
}

void _findstring.on_change(int reason)
{
   if (ignore_change) {
      return;
   }  

   if (_findinc.p_enabled) {
      if (_findtabs.p_ActiveTab == VSSEARCHMODE_FIND && _findinc.p_value && _findinc.p_enabled) {
         _begin_incremental_search();
      } else {
         _findstring._show_textbox_error_color(false);
      }
   } 
}

void _findstring.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      if (PUSER_FINDSTRING_INIT_DONE() == '') {
         _lbclear();
         _retrieve_list();
         PUSER_FINDSTRING_INIT_DONE(1);
      }
   }
}

void _find_btn.lbutton_up()
{
   _findstring._begin_find();
}

/*** replace ***/
static int _buffer_replace(_str search_text, _str search_options, _str replace_text, bool show_diff, int& num_replaced, bool multifile = false, SearchResults* results = null,bool close_mini_find_dialog=true)
{
   if (!p_HasBuffer || (p_window_flags & HIDE_WINDOW_OVERLAP)) {
      _message_box(get_message(VSRC_FF_NO_FILES_SELECTED));
      return(FILE_NOT_FOUND_RC);
   }
   int temp_view;
   int orig_view;
   int old_mark = _duplicate_selection('');
   temp_mark := 0;
   if (show_diff) {
      alreadyExists := true;
      int status = _open_temp_view(p_buf_name, temp_view, orig_view, "+d", alreadyExists, false, true);
      if (status < 0) {
         return(FILE_NOT_FOUND_RC);
      }
      if (pos('M', upcase(search_options))) {
         temp_mark = _clone_selection(orig_view, old_mark);
         _show_selection(temp_mark);
      }
   }

   doAll := pos('*', search_options, 1);
   _save_pos2(auto p);
   int status = gui_replace2(search_text, replace_text, search_options, false, multifile, results, show_diff, close_mini_find_dialog);
   num_replaced += _Nofchanges;
   if (doAll) {
      _restore_pos2(p);
   }

   if (show_diff) {
      if (_Nofchanges > 0) {
         replace_diff_add_file(p_buf_name, p_encoding);
         replace_diff_set_modified_file(p_window_id);
      }
      if (temp_mark) {
         // _buffer_replace changes the active selection so refetch it.
         temp_mark=_duplicate_selection('');
         _show_selection(old_mark);
         _free_selection(temp_mark);
      }
      _delete_temp_view(temp_view);
      activate_window(orig_view);
   }
   return(status);
}

static int _replace_all_in_project(_str search_text, _str search_options, _str replace_text, bool search_workspace, bool show_diff, SearchResults* results, int& num_replaced, bool close_mini_find_dialog=true)
{
   get_window_id(auto orig_wid);
   status := 0;
   save_pos(auto p);
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   num_matches := 0;
   buf_id := 0;
   filename := '';
   if (search_workspace) {
      if (_workspace_filename != '') {
         FindNextFile.init_workspace_list(_workspace_filename);
         filename = FindNextFile.workspace_get_next_file('');
      }
   } else {
      if (_project_name != '') {
         FindNextFile.init_project_list(_project_name);
         filename = FindNextFile.project_get_next_file('');
      }
   }
   if (filename :== '') {
      activate_window(orig_wid);
      return 0;
   }
   first_filename := filename;
   bool file_already_loaded;
   int temp_view_id,orig_view_id;
   for (;;) {
      status = _open_temp_view(strip(filename), temp_view_id, orig_view_id, '', file_already_loaded, false, true, 0, false, false);
      if (!status) {
         _updateTextChange();
         status = _buffer_replace(search_text, search_options, replace_text, show_diff, num_replaced, false, results, close_mini_find_dialog);
         _delete_temp_view(temp_view_id);
      }
      if (search_workspace) {
         filename = FindNextFile.workspace_get_next_file(filename);
      } else {
         filename = FindNextFile.project_get_next_file(filename);
      }
      if ((filename :== '') || (filename :== first_filename)) {
         status = FILE_NOT_FOUND_RC;
         break;
      }
   }
   activate_window(orig_wid);
   return(0);
}

static int _replace_in_project(_str search_text, _str search_options, _str replace_text, bool search_workspace, bool show_diff, SearchResults* results, int& num_replaced, bool close_mini_find_dialog=true)
{
   get_window_id(auto orig_wid);
   status := 0;
   // replace current buffer first
   start_buf_id := p_buf_id;
   status = _buffer_replace(search_text, search_options, replace_text, show_diff, num_replaced, true, results, close_mini_find_dialog);
   num_replaced += _Nofchanges;
   if (status == COMMAND_CANCELLED_RC) {
      return status;
   }
   init_filename := p_buf_name;
   save_pos(auto p);
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   num_matches := 0;
   buf_id := 0;
   filename := '';
   if (search_workspace) {
      if (_workspace_filename != '') {
         FindNextFile.init_workspace_list(_workspace_filename);
         filename = FindNextFile.workspace_get_next_file('');
      }
   } else {
      if (_project_name != '') {
         FindNextFile.init_project_list(_project_name);
         filename = FindNextFile.project_get_next_file('');
      }
   }
   if (filename :== '') {
      activate_window(orig_wid);
      return 0;
   }
   first_filename := filename;
   bool file_already_loaded;
   int temp_view_id,orig_view_id;
   for (;;) {
      status = _open_temp_view(strip(filename), temp_view_id, orig_view_id, '', file_already_loaded, false, true, 0, false, false);
      if (!status) {
         _updateTextChange();
         save_pos(auto tp);
         top(); up();
         status = search(old_search_string, search_options);
         if (!status) {
            buf_id = p_buf_id; save_pos(tp);
            edit('+q +bi 'buf_id);
            status = _buffer_replace(search_text, search_options, replace_text, show_diff, num_replaced, true, results, close_mini_find_dialog);
            if (status == COMMAND_CANCELLED_RC) {
               break;
            }
            restore_pos(tp);
            _delete_temp_view(temp_view_id, false);
         } else {
            restore_pos(tp);
            _delete_temp_view(temp_view_id);
         }
      }
      for (;;) {
         if (search_workspace) {
            filename = FindNextFile.workspace_get_next_file(filename);
         } else {
            filename = FindNextFile.project_get_next_file(filename);
         }
         if (filename :== '' || !_file_eq(filename, init_filename)) {
            break;
         }
      }
      if ((filename :== '') || (filename :== first_filename)) {
         status = FILE_NOT_FOUND_RC;
         break;
      }
   }
   edit('+q +bi 'start_buf_id);
   activate_window(orig_wid);
   return(0);
}

static int _replace_all_buffers(_str search_text, _str search_options, _str replace_text, bool show_diff, SearchResults* results, int& num_replaced, bool close_mini_find_dialog=true)
{
   if (_no_child_windows()) {
      return(FILE_NOT_FOUND_RC);
   }
   int all_status = STRING_NOT_FOUND_RC;
   int status;
   int orig_wid;
   replace_go := pos('*', search_options);
   get_window_id(orig_wid);

   int buffers[];
   activate_window(_mdi.p_child);
   int first_buf_id = _mdi.p_child.p_buf_id;
   for (;;) {
      if (p_HasBuffer && !(p_window_flags & HIDE_WINDOW_OVERLAP) && !_isGrepBuffer(p_buf_name)) {
         buffers[buffers._length()] = p_buf_id;
      }
      _mdi.p_child._next_buffer('r');
      if (_mdi.p_child.p_buf_id == first_buf_id) {
         break;
      }
   }
   _mdi.p_child.p_buf_id = first_buf_id;
   activate_window(orig_wid);
   int i;
   for (i = 0; i < buffers._length(); ++i) {
      edit('-bp +q +bi 'buffers[i]);
      typeless p; save_pos(p);
      if (i > 0) {
         top();      // start buffer at top, this is less confusing when switching buffers
      }
      status = _buffer_replace(search_text, search_options, replace_text, show_diff, num_replaced, (buffers._length() > 1), results, close_mini_find_dialog);
      if (status == COMMAND_CANCELLED_RC) {
         break;
      }
      restore_pos(p);
      if (!status ||_Nofchanges) {
         all_status = 0;
      }
   }
   edit('-bp +q +bi 'first_buf_id);
   activate_window(orig_wid);
   return(all_status);
}

int replace_buffer_text(_str search_text, _str search_options, _str replace_text, int search_range, bool show_diff, bool show_highlights, bool show_results = false, int mfflags = 0, int grep_id = 0, bool close_mini_find_dialog=true)
{
   num_replaced := 0;
   status := 0;
   if (show_diff && !_haveDiff()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Diff");
      return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
   }
   if (show_diff) {
      if (replace_diff_begin(search_range==VSSEARCHRANGE_CURRENT_BUFFER ||
                             search_range==VSSEARCHRANGE_CURRENT_PROC ||
                             search_range==VSSEARCHRANGE_CURRENT_SELECTION)) {
         return (0);
      }
   }
   if (show_highlights) {
      clear_highlights();
   }
   SearchResults results;
   if (show_results) {
      topline := se.search.generate_search_summary(search_text, search_options, "", mfflags, "", "", replace_text);
      results.initialize(topline, search_text, mfflags, grep_id);
   }
   _macro('m', _macro('s'));
   _macro_call('replace_buffer_text', search_text, search_options, replace_text, search_range, show_diff, show_highlights, show_results, mfflags, grep_id, close_mini_find_dialog);
   old_search_range = search_range;
   if (search_range == VSSEARCHRANGE_ALL_BUFFERS) {
      status = _replace_all_buffers(search_text, search_options, replace_text, show_diff, (show_results)?&results:null, num_replaced, close_mini_find_dialog);
   } else if (search_range == VSSEARCHRANGE_WORKSPACE || search_range == VSSEARCHRANGE_PROJECT) {
      status = _replace_in_project(search_text, search_options, replace_text, (search_range == VSSEARCHRANGE_WORKSPACE), show_diff, (show_results)?&results:null, num_replaced, close_mini_find_dialog);
   } else {
      status = _buffer_replace(search_text, search_options, replace_text, show_diff, num_replaced, false, (show_results)?&results:null, close_mini_find_dialog);
   }
   if (show_diff) {
      replace_diff_end(false, "Replace results");
   }
   if (show_results) {
      results.done('Total replaces: 'num_replaced);
      results.showResults();
   }
   return (status);
}

static void _replace(_str search_text, _str search_options, _str replace_text, int search_range, bool show_diff, bool show_highlights, bool show_results = false, int mfflags = 0, int grep_id = 0)
{
   int status;
   int orig_wid;
   get_window_id(orig_wid);
   if (0 == _activate_current_search_wid()) {
      return;
   }
   if(select_active2() && (def_mfsearch_init_flags & MFSEARCH_INIT_SELECTION)) {
      _begin_select();
   }
   typeless orig_mark = _duplicate_selection('');
   mark_id := 0;
   if (search_range == VSSEARCHRANGE_CURRENT_PROC) {
      mark_id = _get_proc_mark();
      _show_selection(mark_id);
   }
   _macro('m', _macro('s'));
   status = replace_buffer_text(search_text, search_options, replace_text, search_range, show_diff, show_highlights, show_results, mfflags, grep_id);
   if (mark_id) {
      // _buffer_replace changes the active selection so refetch it.
      mark_id=_duplicate_selection('');
      _show_selection(orig_mark);
      _free_selection(mark_id);
      _macro_call('_deselect');
   }
   activate_window(orig_wid);
   if (!status || (status == COMMAND_CANCELLED_RC)) {
      _findstring._show_textbox_error_color(false);
   } else {
      _findstring._show_textbox_error_color(true);
   }
   set_find_next_msg("Find", search_text, search_options, search_range);
}

static void _replace_in_files(_str search_string, _str replace_string, _str search_options,
                              _str files, _str wildcards=ALLFILES_RE, _str file_exclude = '',
                              int mfflags = 0, int grep_id = 0, bool show_diff = false)
{
   int orig_wid;
   get_window_id(orig_wid);
   activate_window(_mdi.p_child);
   _macro('m', _macro('s'));
   _macro_call('_mfreplace2',search_string, replace_string, search_options, files, wildcards, file_exclude, mfflags, grep_id, show_diff);
   _mfreplace2(search_string, replace_string, search_options, files, wildcards, file_exclude, mfflags, grep_id, show_diff);
   activate_window(orig_wid);
}

void _replacestring.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      if (PUSER_REPLACESTRING_INIT_DONE() == '') {
         _lbclear();
         _retrieve_list();
         PUSER_REPLACESTRING_INIT_DONE(1);
      }
   }
}

static void _begin_replace(_str options = '', bool show_diff = false)
{
   int window_id;
   form_id := p_active_form;

   // gather search/replace parameters
   search_wid := _get_current_search_wid();

   search_text := _findstring.p_text;
   replace_text := _replacestring.p_text;
   _str search_options = _get_search_options(-1,auto re_syntax):+options;
   int search_range = _get_search_range(search_wid);
   files := "";
   wildcards := "";
   exclude := "";
   grep_id := 0;
   mfflags := 0;
   show_highlights := false;
   show_results := false;
   int mode=_findtabs.p_ActiveTab;

   switch (mode) {
   case VSSEARCHMODE_REPLACE:
      if (!search_wid) {
         message('No active window for replace');
         return;
      }
      if(_validate_regex(_findstring.p_text,re_syntax)) {
         _findstring._set_focus();
         return;
      }
      show_highlights = (pos('$', search_options) != 0);
      show_results = (_replacelist.p_enabled && _replacelist.p_value);
      if (show_results) {
         if (_mfappendgrep.p_value)        mfflags |= MFFIND_APPEND;
         if (_mfmdichild.p_value)          mfflags |= MFFIND_MDICHILD;
         if (_mfmatchlines.p_enabled && _mfmatchlines.p_value) mfflags |= MFFIND_SINGLELINE;
         if (_mflistmatchonly.p_enabled && _mflistmatchonly.p_value) mfflags |= MFFIND_MATCHONLY;
         if (_mflistfilesonly.p_visible && _mflistfilesonly.p_enabled && _mflistfilesonly.p_value) mfflags |= MFFIND_FILESONLY;
         if (_mflistcontext.p_enabled && _mflistcontext.p_value) mfflags |= MFFIND_LIST_CURRENT_CONTEXT;
         grep_id = _get_grep_buffer_id();
      }
      break;
   case VSSEARCHMODE_REPLACEINFILES:
      if(_validate_find_paths(_findfiles.p_text,true)) {
         _findfiles._set_focus();
         return;
      }
      if(_validate_regex(_findstring.p_text,re_syntax)) {
         _findstring._set_focus();
         return;
      }
      grep_id = _get_grep_buffer_id();
      mfflags = (show_diff) ? MFFIND_DIFF : 0;
      _get_files_list(files, wildcards, exclude);
      if (files != '') {
         if (_mflistfilesonly.p_value)       mfflags |= MFFIND_FILESONLY;
         if (_mfappendgrep.p_value)          mfflags |= MFFIND_APPEND;
         if (_mfmdichild.p_value)            mfflags |= MFFIND_MDICHILD;
         if (_replaceleaveopen.p_value)      mfflags |= MFFIND_LEAVEOPEN;

         if (_mfmatchlines.p_enabled && _mfmatchlines.p_value) mfflags |= MFFIND_SINGLELINE;
         if (_mflistmatchonly.p_enabled && _mflistmatchonly.p_value) mfflags |= MFFIND_MATCHONLY;
         if (_mflistcontext.p_enabled && _mflistcontext.p_value) mfflags |= MFFIND_LIST_CURRENT_CONTEXT;
      }
      break;
   }

   unhide_toolwindow := false;
   get_window_id(window_id);
   // hide tool window, it may be in the way
   if (pos('*', options) == 0) {
      ignore_switchbuf = true;
      if ( tw_is_auto_raised(form_id) ) {
         tw_auto_lower(form_id);
         activate_window(window_id);
      } else if (!tw_is_docked_window(form_id)) {
         int mdi_wid=_MDIFromChild(p_active_form);
         mdi_wid.p_visible=false;
         //p_active_form.p_visible = false;
         unhide_toolwindow = true;
      }
      ignore_switchbuf = false;
   }

   _mffindNoMore(1);
   _mfrefNoMore(1);
   ignore_change = true;
   switch (mode) {
   case VSSEARCHMODE_REPLACE:
      _replace(search_text, search_options, replace_text, search_range, show_diff, show_highlights, show_results, mfflags, grep_id);
      break;
   case VSSEARCHMODE_REPLACEINFILES:
      _replace_in_files(search_text, replace_text, search_options, files, wildcards, exclude, mfflags, grep_id, show_diff);
      break;
   }
   ignore_change = false;

   // unhide toolwindow
   if (unhide_toolwindow && !def_find_close_on_default) {
      if (!tw_is_docked_window(form_id)) {
         int mdi_wid=_MDIFromChild(p_active_form);
         mdi_wid.p_visible=true;
         //p_active_form.p_visible = true;
      }
   }

   current_wid := _get_current_search_wid();
   _append_save_history(search_text, search_options);
   _tool_hide_on_default();
   _show_current_search_window(current_wid);
}

void _replace_btn.lbutton_up()
{
   _replacestring._begin_replace();
}

void _replaceall_btn.lbutton_up()
{
   _replacestring._begin_replace('*');
}

void _replacepreview_btn.lbutton_up()
{
   _replacestring._begin_replace('*', true);
}

/*** incremental search ***/
void _findinc.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   if (!_findinc.p_value) {
      _findstring._show_textbox_error_color(false);
      _end_incremental_search();
   }
   _init_buffers_list(_get_current_search_wid());
}

static void _refresh_incremental_search()
{
   if (ignore_change) {
      return;
   }
   if ((_findtabs.p_ActiveTab == VSSEARCHMODE_FIND) && _findinc.p_value && _findinc.p_enabled) {
      is_state.last_status = -1;
      is_state.last_pos = is_state.start_pos;
      _findstring.call_event(CHANGE_OTHER,_control _findstring, ON_CHANGE, "W");
   }
}

/*** match case ***/
void _findcase.lbutton_up()
{
   if (_findcase.p_value && _replacekeepcase.p_visible) {
      _replacekeepcase.p_value = 0;
   }
   _refresh_incremental_search();
}

/*** match whole word ***/
void _findword.lbutton_up()
{
   _refresh_incremental_search();
}

/*** search backwards ***/
void _findback.lbutton_up()
{
   _refresh_incremental_search();
}

/*** hidden search ***/
void _findhidden.lbutton_up()
{
   _refresh_incremental_search();
}

/*** preserve case ***/
void _replacekeepcase.lbutton_up()
{
   if (_replacekeepcase.p_value) {
      _findcase.p_value = 0;
   }
}

/*** highlight replaced text ***/
void _replacehilite.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   if (!_replacehilite.p_value) {
      _replacehilite.clear_highlights();
   }
}

/*** _mfforegroundsearch ***/
void _mfforegroundsearch.lbutton_up()
{
   _mfhook.call_event(CHANGE_SELECTED, _findtabs.p_ActiveTab == VSSEARCHMODE_FINDINFILES, _mfhook, LBUTTON_UP, '');
}

/*** stop ***/
void _stop_btn.lbutton_up()
{
   if (_get_focus()==p_window_id) {
      // Don't want focus sitting on a button that is going to be disabled
      _findstring._set_focus();
   }
   stop_search();
}

/*** _mfhook ***/
void _mfhook.lbutton_up(int reason, _str info)
{
   if (reason == CHANGE_SELECTED) {
      _nocheck _control _mfforegroundsearch;
      if (!(_default_option(VSOPTION_APIFLAGS) & 0x80000000) && _mfforegroundsearch.p_visible) {
         _mfforegroundsearch.p_visible = false;
         _mfforegroundsearch.p_value = 1;
      }
      _nocheck _control _mfprompted,_mfsinglefile,_mfglobal;
      _nocheck _control _mfforegroundsearch;

      int mode = _findtabs.p_ActiveTab;
      if (mode == VSSEARCHMODE_FINDINFILES || mode == VSSEARCHMODE_FILES) {
         _find_btn.p_enabled = (gbgm_search_state == 0);
         _stop_btn.p_enabled = (gbgm_search_state != 0);
      }
      _mfglobal.p_enabled = _mfsinglefile.p_enabled = _mfprompted.p_enabled = ((mode == VSSEARCHMODE_FINDINFILES) && (_mfforegroundsearch.p_value && info));
   }
}

void _tbFindUpdateBGSearchStatus()
{
   wid := _tbGetActiveFindAndReplaceForm();
   if (wid) {
      wid._mfhook.call_event(CHANGE_SELECTED, wid._findtabs.p_ActiveTab==VSSEARCHMODE_FINDINFILES, wid._mfhook,LBUTTON_UP, '');
   }
}

static void _update_list_all_occurrences()
{
   _update_search_options(_findtabs.p_ActiveTab);
   if (_findtabs.p_ActiveTab == VSSEARCHMODE_FIND) {
      _results_frame.p_visible = (_findlist_all.p_value != 0 && _findlist_all.p_enabled);
      _show_results_options(_findtabs.p_ActiveTab);
      _resize_frame_heights(true);
   }
}

void _findlist_all.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   if (_findtabs.p_ActiveTab == VSSEARCHMODE_FIND) {
      _update_list_all_occurrences();
   }
}

void _findmark_all.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   if (p_value == 0) {
      p_active_form.clear_highlights();
   }
}

void _findbookmark_all.lbutton_up()
{
   if (ignore_change) {
      return;
   }
}

static void _update_replace_list_all()
{
   if (_findtabs.p_ActiveTab == VSSEARCHMODE_REPLACE) {
      _results_frame.p_visible = (_replacelist.p_value != 0 && _replacelist.p_enabled);
      _show_results_options(_findtabs.p_ActiveTab);
      _resize_frame_heights(true);
   }
}

void _replacelist.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   if (_findtabs.p_ActiveTab == VSSEARCHMODE_REPLACE) {
      _update_replace_list_all();
   }
}

/*** color coded search ***/
static void _configure_color_search()
{
   _str result = show("-modal _ccsearch_form", _findcoloroptions.p_text, '1');
   if (result != '') {
      parse _param1 with auto IncludeChars ',' auto ExcludeChars ',';
      if (IncludeChars != '' || ExcludeChars != '') {
         _findcolorcheck.p_value = 1;
      }
      _findcoloroptions.p_text = _param1;
      _findstring._set_focus();
   }
}
static void _init_matchcolor_menu(int menu_handle)
{
   color_enabled := (_findcolorcheck.p_enabled && _findcolorcheck.p_value);
   menu_pos := 0;
   flags := MF_ENABLED;
   if (color_enabled) {
      if (_findcoloroptions.p_text == '') {
         flags = MF_ENABLED|MF_CHECKED;
      } 
      _menu_insert(menu_handle, menu_pos, flags, 'None', 'tbfind_options_menu co NONE', "", "", "");
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
      _menu_insert(menu_handle, menu_pos, flags, name, 'tbfind_options_menu co 'opt, "", "", "");
      ++menu_pos;
   }

   // non-preset color, add entry
   if ((_findcoloroptions.p_text != '') && !lastcolor_found) {
      name := _ccsearch_option_to_string(_findcoloroptions.p_text);
      flags = MF_ENABLED;
      command := 'tbfind_options_menu co '_findcoloroptions.p_text;
      if (color_enabled) {
         flags |= MF_CHECKED;
         command = '';
      }
      _menu_insert(menu_handle, 0, flags, name, command, "", "", "");
      if (!color_enabled) {
         _menu_insert(menu_handle, 1, 0, '-', "", "", "", "");
      }
   }

   // update configure command
   status := _menu_find(menu_handle, "docsearch_find_menu cc", auto mh, auto mpos, 'M');
   if (!status) {
      _str caption;
      _menu_get_state(mh, mpos, flags, 'P', caption);      
      _menu_set_state(mh, mpos, flags, 'P', caption, "tbfind_options_menu cc");
   }
}

static void _update_color_search(_str option)
{
   if (option == 'NONE') {
      option = '';
   }
   _findcolorcheck.p_value = (option != '') ? 1 : 0;
   _findcoloroptions.p_text = option;
   _findcoloroptions.call_event(CHANGE_OTHER, _control _findcoloroptions, ON_CHANGE, "W");
}

void _findcolormenu.lbutton_up()
{
   int index = find_index("_docsearchcolor_menu", oi2type(OI_MENU));
   int menu_handle = p_active_form._menu_load(index, 'P');
   int x = p_x + p_width;
   y := p_y;
   _lxy2dxy(SM_TWIP, x, y);
   _map_xy(p_xyparent, 0, x, y);
   _init_matchcolor_menu(menu_handle);
   int status = _menu_show(menu_handle, VPM_LEFTALIGN | VPM_RIGHTBUTTON, x, y);
   _menu_destroy(menu_handle);
}

void _findcoloroptions.on_change()
{
   _str result = _ccsearch_option_to_string(_findcoloroptions.p_text);
   if (_findcolorcheck.p_enabled) {
      if (_findcolorcheck.p_value) {
         _findcolorlabel.p_caption = ((result == "") ? "None" : result);
      } else {
         _findcolorlabel.p_caption = "None";
      }
   } else {
      _findcolorlabel.p_caption = "None";
   }
   _findcolorlabel.p_width = _findcolorlabel.p_parent.p_width - (2*_findcolorlabel.p_x);
   if (ignore_change) {
      return;
   }
   _show_search_options(_findtabs.p_ActiveTab);
   _resize_frame_heights(true);
   _refresh_incremental_search();
}

void _findcolorcheck.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   _update_color_options();
}

static void _update_color_options()
{
   search_wid := _get_current_search_wid();
   int mode = _findtabs.p_ActiveTab;
   color_enabled := true;
   if (mode == VSSEARCHMODE_FIND || mode == VSSEARCHMODE_REPLACE) {
      if (_findbuffer.p_text == MFFIND_PROJECT_FILES || _findbuffer.p_text == MFFIND_WORKSPACE_FILES) {
         color_enabled = true;
      } else if (_findbuffer.p_text == SEARCH_IN_ALL_BUFFERS ||
                 _findbuffer.p_text == SEARCH_IN_ALL_ECL_BUFFERS) {
         color_enabled = !_mdi._no_child_windows();
      } else {
         color_enabled = (search_wid != 0) && (search_wid.p_HasBuffer && search_wid.p_lexer_name != "");
      }
   }
   _findcolorcheck.p_enabled = _findcolormenu.p_enabled = _findcolorlabel.p_enabled = color_enabled;
   _findcoloroptions.call_event(CHANGE_OTHER,_control _findcoloroptions, ON_CHANGE, "W");
}

/*** _findfiles ***/

static bool _mfallow_project(_str project_name)
{
   if (_workspace_filename != '') {
      int i;
      _str array[]=null;
      _GetWorkspaceFiles(_workspace_filename, array);
      for (i = 0; i < array._length(); ++i) {
         if (_file_eq(project_name, array[i])) {
            return(true);
         }
      }
   }
   return(false);
}

bool _mfallow_prjfiles()
{
   if (_project_name != '') {
      result := "";
      int status = _GetAssociatedProjectInfo(_project_name,result);
      if (status || result == '') {
         if (!_ProjectContains_Files(_ProjectHandle(_project_name))) {
            return(false);
         }
      }
      return(true);
   }
   return(false);
}

bool _mfallow_workspacefiles()
{
   orig_view_id := p_window_id;
   if (_workspace_filename != '') {
      _str Files[];
      int status = _GetWorkspaceFiles(_workspace_filename, Files);
      if (status) {
         _message_box(get_message(VSRC_FF_COULD_NOT_OPEN_WORKSPACE_FILE, _workspace_filename, get_message(status)));
         return(false);
      }
      return(true);
   }
   return(false);
}

bool _mffind_have_buffers()
{
   _str array[];
   _tbfind_list_buffers(array, false);
   return(array._length() != 0);
}

bool _mffind_buffer_has_directory()
{
   if (!_no_child_windows()) {
      _str name = _mdi.p_child.p_buf_name;
      if (!(_mdi.p_child.p_buf_flags & VSBUFFLAG_HIDDEN)&& name != '' && !beginsWith(name, '.process') && !_isGrepBuffer(name)) {
         return (true);
      }
   }
   return (false);
}

static bool _mfallow_listprojectfiles()
{
   orig_view_id := p_window_id;
   if (_workspace_filename != '') {
      _str Files[];
      int status = _GetWorkspaceFiles(_workspace_filename, Files);
      if (status) {
         _message_box(get_message(VSRC_FF_COULD_NOT_OPEN_WORKSPACE_FILE, _workspace_filename, get_message(status)));
         return(false);
      } else if (Files._length() == 0) {
         return(false);
      }
      return(true);
   }
   return(false);
}

bool _mffind_disable_filetypes()
{
   _str curfile, list;
   parse _findfiles.p_text with curfile ";" list;
   while (curfile != '') {
      if (curfile != MFFIND_BUFFER && curfile != MFFIND_BUFFERS) {
         return(false);
      }
      parse list with curfile ";" list;
   }
   return(true);
}

bool _mffind_enable_subfolders()
{
   _str curfile, list;
   parse _findfiles.p_text with curfile ";" list;
   while (curfile != '') {
      if (curfile == MFFIND_BUFFER || curfile == MFFIND_BUFFERS || curfile == MFFIND_PROJECT_FILES || curfile == MFFIND_WORKSPACE_FILES) {
         parse list with curfile ";" list;
      } else {
         return (true);
      }
   }
   return(false);
}

static void _tbfind_list_buffers(_str (&array)[], bool sort)
{
   array._makeempty();
   // Fill the buffer list
   _str name = buf_match('', 1, 'B');
   for (;;) {
      if (rc) break;
      if ((name != '') && (!beginsWith(name, '.process')) && (!_isGrepBuffer(name))) {
         array[array._length()] = field(_strip_filename(name, 'P'), 13)'<'_strip_filename(name, 'N')'>';
      }
      name = buf_match('', 0, 'B');
   }
   if (sort) {
      array._sort();
   }
}

static bool _mffind_last_sorted = false;

static _str _get_buflist_name(_str result)
{
   if (_isno_name(result)) {
      return(result);
   }
   name := "";
   path := "";
   parse result with name'<'path'>';
   if (path != '') {
      result = path:+strip(name);
   }
   return(result);
}

static _str _mffind_list_buffers_callback(int reason, var result,typeless key)
{
   _nocheck _control _sellist;
   _nocheck _control _sellistok;
   if (reason == SL_ONINIT || reason == SL_ONSELECT) {
      if (_sellist.p_Nofselected > 0) {
         if (!_sellistok.p_enabled) {
            _sellistok.p_enabled = true;
         }
      } else {
         _sellistok.p_enabled = false;
      }
      return('');
   }
   if (reason == SL_ONDEFAULT) {  // Enter callback?
      /* Save all files. */
      result='';
      int status=_sellist._lbfind_selected(true);
      while (!status) {
         _str text = _sellist._lbget_text();
         name := _get_buflist_name(text);
         if (result == '') {
            result = name;
         } else {
            int newsize = length(result)+ length(text)+ 1000;
            if (newsize > _default_option(VSOPTION_WARNING_STRING_LENGTH)) {
               _default_option(VSOPTION_WARNING_STRING_LENGTH, newsize);
            }
            strappend(result, ";"name);
         }
         status = _sellist._lbfind_selected(false);
      }
      return(1);
   }
   if (reason != SL_ONUSERBUTTON && reason != SL_ONLISTKEY) {
      return('');
   }
   if (key == 4) { /* Invert. */
      _str junk;
      _sellist._lbinvert();
      _mffind_list_buffers_callback(SL_ONSELECT, junk, '');
      return('');
   }
   if (key == 5) { /* Clear */
      _str junk;
      _sellist._lbdeselect_all();
      _mffind_list_buffers_callback(SL_ONSELECT, junk,'');
      return('');
   }
   if (key == 6) { /* Order */
      _str junk;
      _str array[];
      _str selected:[];
      int status=_sellist._lbfind_selected(true);
      while (!status) {
         _str text=_sellist._lbget_text();
         selected:[text]=1;
         status = _sellist._lbfind_selected(false);
      }
      int i;
      _sellist._lbdeselect_all();
      _sellist._lbclear();
      _mffind_last_sorted = !_mffind_last_sorted;
      _tbfind_list_buffers(array, _mffind_last_sorted);
      for (i = 0; i < array._length(); ++i) {
         _sellist._lbadd_item(array[i]);
         if (selected._indexin(array[i])) {
            _sellist._lbselect_line();
         }
      }
      _mffind_list_buffers_callback(SL_ONSELECT, junk,'');
   }
   return('');
}

static void _mffind_add_buffers(_str &append)
{
   _str array[];
   _mffind_last_sorted = false;
   _tbfind_list_buffers(array, false);
   _str buttons = nls('&Add Buffers,&Invert,&Clear,&Order');
   append = show('_sellist_form -mdi -modal',
                 "Add Buffers",
                 SL_ALLOWMULTISELECT|SL_NOISEARCH|SL_SIZABLE|
                 SL_DEFAULTCALLBACK,
                 array,
                 buttons,
                 "Add Buffers",        // help item name
                 '',             // font
                 _mffind_list_buffers_callback   // Call back function
                );
}

static void _mffind_add_projects(_str& append)
{
   int i;
   append = '';
   if (_workspace_filename == '') {
      return;
   }
   _str projects[] = null;
   int status = _GetWorkspaceFiles(_workspace_filename, projects);
   if (status) {
      return;
   }
   _str result = select_tree(projects, null, null, null, null, null, null,
                             "Select projects",
                             SL_ALLOWMULTISELECT,
                             null, null, true);

   if (result == COMMAND_CANCELLED_RC || result == '') {
      return;
   }

   while (result != '') {
      prjname := "";
      parse result with prjname "\n" result;
      if (append != '') {
         append :+= ";";
      }
      append :+= "<Project: ":+prjname:+">";
   }
}

static void _mffind_add_filelist(_str &files_lookin)
{  
   files_lookin = '';
   _str result = _OpenDialog("-modal",
                             'Add File list',// title
                             '',// Initial wildcards
                             "Text Files (*.txt),All Files (*.*)",
                             OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT|OFN_SET_LAST_WILDCARDS);

   if (result == COMMAND_CANCELLED_RC || result == '') {
      return;
   }
   for (;;) {
      filename := parse_file(result);
      filename = strip(filename,'B','"');
      if (filename == '') break;

      _maybe_append(files_lookin, ";");
      files_lookin :+= "<Filelist: ":+filename:+">";
   }
}

_command void mffind_add(_str cmdline = '') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _macro_delete_line();
   _str action, append;
   parse cmdline with action append;
   wid := p_prev;
   _str result;
   switch (lowcase(action)) {
   case "workspace":
      if (!isEclipsePlugin()) {
         result = MFFIND_WORKSPACE_FILES;
      } else {
         _eclipse_get_workspace_dir(result);
      }
      break;
   case "project":
      if (!isEclipsePlugin()) {
         result = MFFIND_PROJECT_FILES;
      } else {
         _eclipse_get_project_dir(result);
      }
      break;
   case "list_projects":
      _mffind_add_projects(result);
      break;
   case "buffers":
      result = MFFIND_BUFFERS;
      break;
   case "buffer_dir":
      result = MFFIND_BUFFER_DIR;
      break;
   case "list_buffers":
      _mffind_add_buffers(result);
      break;
   case "current_buffer":
      result = MFFIND_BUFFER;
      break;
   case "filelist":
      _mffind_add_filelist(result);
      break;
   default:
      if (beginsWith(action, 'grep=')) {
         parse action with 'grep=' auto grep_id;
         if (grep_id != '' && isnumber(grep_id)) {
            result = "<SearchResults: ":+grep_id:+">";
         }
         break;

      } else {
         _str current_dir = getcwd();
         /*
           Might as well start at the current directory.  Could support user
           options to start at current project or current directory. Another
           nice addition for Windows would be to use the open dialog instead
           but add our own option for directories only (this is not
           trivial).  Microsoft Word does this.

           Note: As far as I (Clark) can tell, the if with def_change_dir never
           gets hit because _ChooseDirDialog does not change the directory on
           windows or unix. I tried the CDN_CHANGE_DIRECTORY option on windows
           and the directory still didn't change.
         */
         result = _ChooseDirDialog('Choose Directory',current_dir);
         if (!def_change_dir && current_dir != getcwd()) {
            cd(current_dir,'q');
         }
      }
      break;
   }
   if (result == '') {
      return;
   }
   line := wid.p_text;
   if (append == '') {
      _str old_completion = wid.p_completion; wid.p_completion = '';
      wid.p_text = result;
      wid.p_completion = old_completion;
      wid._end_line();
      wid._set_focus();
      wid.p_sel_start = 0;
      wid._refresh_scroll();
      wid.p_sel_length = length(result);
      return;
   }
   if (line != '') {
      line = strip(line, 'T'):+";":+result;
      result = ";":+result;
   } else {
      line = result;
   }
   _str old_completion = wid.p_completion; wid.p_completion = '';
   wid.p_text = line;
   wid.p_completion = old_completion;
   wid._end_line();
   wid._set_focus();
   wid.p_sel_start = length(line) - length(result)+1;
   wid._refresh_scroll();
   wid.p_sel_length = length(result);
}

int _OnUpdate_mffind_add(CMDUI cmdui,int target_wid,_str command)
{
   _str cmd, action, append;
   parse command with cmd action append;
   switch (lowcase(action)) {
   case "workspace":
      return((_mfallow_workspacefiles() || isEclipsePlugin()) ? MF_ENABLED : MF_GRAYED);
   case "project":
      return((_mfallow_prjfiles() || isEclipsePlugin()) ? MF_ENABLED : MF_GRAYED);
   case "list_projects":
      return(_mfallow_listprojectfiles() ? MF_ENABLED : MF_GRAYED);
   case "buffers":
      return(_mffind_have_buffers() ? MF_ENABLED : MF_GRAYED);
   case "buffer_dir":
      return(_mffind_buffer_has_directory() ? MF_ENABLED : MF_GRAYED);
   case "list_buffers":
      return(_mffind_have_buffers() ? MF_ENABLED : MF_GRAYED);
   case "current_buffer":
      return(_mffind_buffer_has_directory() ? MF_ENABLED : MF_GRAYED);
   default:
      return(MF_ENABLED);
   }
}

void _mffindfiles_is_current_valid()
{
   _str curfile, list;
   clear_findfiles := false;
   parse _findfiles.p_text with curfile ";" list;
   while (curfile != '' && !clear_findfiles) {
      switch (curfile) {
      case MFFIND_BUFFER:
      case MFFIND_BUFFER_DIR:
         if (!_mffind_buffer_has_directory()) {
           clear_findfiles=true;
         }
         break;

      case MFFIND_BUFFERS:
         if (!_mffind_have_buffers()) {
            clear_findfiles=true;
         }
         break;

      case MFFIND_PROJECT_FILES:
         if (!_mfallow_prjfiles()) {
            clear_findfiles=true;
         }
         break;

      case MFFIND_WORKSPACE_FILES:
         if (!_mfallow_workspacefiles()) {
            clear_findfiles=true;
         }
         break;

      default:
         if (pos("<Project: ", curfile)) {
            parse curfile with "<Project: " auto project_name ">";
            if (project_name == '' || !_mfallow_project(project_name)) {
               clear_findfiles=true;
            }
         }
         break;
      }

      parse list with curfile ";" list;
   }

   if (clear_findfiles) {
     _findfiles.p_text = '';
   }
}

const MFFIND_CUSTOM_RE = '^\<(Current Buffer|All Buffers|Current Buffer Directory|Project|Workspace)\>$';

static void _init_files_list(int mode, bool forceRefresh = false)
{
   if (forceRefresh) PUSER_FINDFILES_INIT_DONE('');
   if (PUSER_FINDFILES_INIT_DONE() == '') {
      //p_cb_list_box._lbdeselect_all();
      _lbclear();
      _retrieve_list();

      // remove <SLICKEDIT custom fields>
      _lbtop();
      status := _lbsearch(MFFIND_CUSTOM_RE, '@re');
      while (!status) {
         _lbdelete_item();
         status = _lbsearch(MFFIND_CUSTOM_RE, '@re');
      }
      _lbbottom();

      cwd := getcwd();
      _maybe_append_filesep(cwd);
      if (_project_name != '') {
         _lbbottom();
         WorkspacePath := _strip_filename(_workspace_filename, 'N');
         _lbadd_item_no_dupe(WorkspacePath, _fpos_case, LBADD_BOTTOM);
         _str ProjectPath = _parse_project_command('%rw', '', _project_name, '');
         if (!_file_eq(WorkspacePath, ProjectPath)) {
            _lbadd_item_no_dupe(ProjectPath, _fpos_case, LBADD_BOTTOM);
         }
         if (!_file_eq(WorkspacePath, cwd) && !_file_eq(ProjectPath, cwd)) {
            _lbadd_item_no_dupe(cwd, _fpos_case, LBADD_BOTTOM);
         }
         _lbbottom();
         if ((mode != VSSEARCHMODE_FILES) && _mffind_have_buffers()) {
            if (_mffind_buffer_has_directory()) {
               _lbadd_item(MFFIND_BUFFER);
            }
            _lbadd_item(MFFIND_BUFFERS);
         }
         if (_mfallow_prjfiles()) {
            _lbadd_item(MFFIND_PROJECT_FILES);
         }
         if (_mfallow_workspacefiles()) {
            _lbadd_item(MFFIND_WORKSPACE_FILES);
         }
         if (_mffind_buffer_has_directory()) {
            _lbadd_item(MFFIND_BUFFER_DIR);
         }
      } else {
         _lbadd_item_no_dupe(cwd, _fpos_case, LBADD_BOTTOM);
         _lbbottom();
         if (_mffind_have_buffers()) {
            if (_mffind_buffer_has_directory()) {
               _lbadd_item(MFFIND_BUFFER);
            }
            _lbadd_item(MFFIND_BUFFERS);
         }
         if (_mffind_buffer_has_directory()) {
            _lbadd_item(MFFIND_BUFFER_DIR);
         }
      }
      PUSER_FINDFILES_INIT_DONE(1);
   }
   if (p_text != '') {
      _mffindfiles_is_current_valid();
   } 
   if (p_text == '') {
      _lbtop();
      p_text = _lbget_text();
   }
   has_buffers_only := _mffind_disable_filetypes();
   _findfiletypes.p_enabled = _findexclude.p_enabled = ctlexclude_help.p_enabled = ctlinclude_help.p_enabled = _editfiletypes.p_enabled = !has_buffers_only;
}

void _findfiles.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      _findfiles._init_files_list(_findtabs.p_ActiveTab);
   }
}

static void _update_file_buttons(int mode)
{
   buffers_only := _mffind_disable_filetypes();
   enable_sub_folders :=_mffind_enable_subfolders();
   _findfiletypes.p_enabled = _findexclude.p_enabled = ctlinclude_help.p_enabled = _editfiletypes.p_enabled = _editfiletypes.p_enabled = !buffers_only;
   _findsubfolder.p_enabled = enable_sub_folders;
   _findinzipfiles.p_enabled = enable_sub_folders;
   if (enable_sub_folders) {
      if (mode == VSSEARCHMODE_FINDINFILES || mode == VSSEARCHMODE_FILES) {
         if (_findinzipfiles.p_value) {
            _findsubfolder.p_value = 1;
            _findsubfolder.p_enabled = false;
         } else {
            _findsubfolder.p_enabled = true;
         }
      } else if (mode == VSSEARCHMODE_REPLACEINFILES) {
         _findsubfolder.p_enabled = true;
      }
   }
}

void _findfiles.on_change(int reason)
{
   if (ignore_change) {
      return;
   }
   _mfhook.call_event(CHANGE_SELECTED, true, _mfhook, LBUTTON_UP, '');
   mode := _findtabs.p_ActiveTab;
   if (mode == VSSEARCHMODE_FINDINFILES || mode == VSSEARCHMODE_REPLACEINFILES) {
      _mflistfilesonly.p_enabled = (_findfiles.p_text :!= SEARCH_IN_CURRENT_BUFFER);
   } else {
      _mflistfilesonly.p_enabled = true;
   }
   _update_file_buttons(mode);
}

void _findinzipfiles.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   if (_findinzipfiles.p_value) {
      _findsubfolder.p_value = 1;
      _findsubfolder.p_enabled = false;
   } else {
      _findsubfolder.p_enabled = true;
   }
}

static void _update_findfilestats()
{
   if (_mffilesstats.p_value) {
      file_stats :=  _findfilestats.p_text;
      label := "";

      if (file_stats != '') {
         mffile_size := _mffind_file_stats_get_file_size(file_stats);
         if (mffile_size > 0) {
            label :+= "Size";
         }

         modified_op := _mffind_file_stats_get_file_modified(file_stats, auto dt1, auto dt2);
         if (modified_op != MFFILE_STAT_TIME_NONE) {
            _maybe_append(label, ",");
            label :+= "Modified Time";
         }
      }
      if (label :== "") {
         label = "None";
      }
      _findfilestats_label.p_caption = label;
      _findfilestats_label.p_visible = true;
   } else {
      _findfilestats_label.p_caption = "";
      _findfilestats_label.p_visible = false;
   }
}

void _mffilesstats.lbutton_up()
{
   _update_findfilestats();
}

void _editfilestats.lbutton_up()
{
   _mffind_configure_file_stats();
}

void _findfilestats.on_change()
{
   if (ignore_change) {
      return;
   }
   _update_findfilestats();
}

void _prjopen_tbfind_form(bool singleFileProject)
{
   if (singleFileProject) return;
   find_wid := _tbGetActiveFindAndReplaceForm();
   if (find_wid == 0) {
      return;
   }
   find_wid.PUSER_FINDFILES_INIT_DONE('');  // force refresh
}

static void _init_mffind_search_results(int menu_handle)
{
   int ids[];
   last_grep_id := _get_last_grep_buffer();
   for (i := 0; i < last_grep_id + 1; ++i) {
      if (_grep_buffer_has_results(i))
         ids[ids._length()] = i;
   }

   status := _menu_find(menu_handle, "sr", auto mh, auto mpos, 'C');
   if (!status) {
      if (ids._isempty()) {
         _menu_delete(mh, mpos);
      } else {
         _menu_get_state(mh, mpos, auto mf_flags, 'P', '', auto submenu_handle);
         for (i = 0; i < ids._length(); ++i) {
            caption := 'Search<'ids[i]'>';
            _menu_insert((int)submenu_handle, i, MF_ENABLED, caption, "mffind_add grep=":+ids[i], "", "", "");
         }
      }
   }

   status = _menu_find(menu_handle, "sra", mh, mpos, 'C');
   if (!status) {
      if (ids._isempty()) {
         _menu_delete(mh, mpos);
      } else {
         _menu_get_state(mh, mpos, auto mf_flags, 'P', '', auto submenu_handle);
         for (i = 0; i < ids._length(); ++i) {
            caption := 'Search<'ids[i]'>';
            _menu_insert((int)submenu_handle, i, MF_ENABLED, caption, "mffind_add grep=":+ids[i]:+" append", "", "", "");
         }
      }
   }
}

void _findfiles_button.lbutton_up()
{
   index := find_index("_mffind_menu", oi2type(OI_MENU));
   menu_handle := p_active_form._menu_load(index, 'P');
   x := p_x + p_width;
   y := p_y;
   _lxy2dxy(SM_TWIP, x, y);
   _map_xy(p_xyparent, 0, x, y);
   _init_mffind_search_results(menu_handle);
   status := _menu_show(menu_handle, VPM_LEFTALIGN | VPM_RIGHTBUTTON, x, y);
   _menu_destroy(menu_handle);
}

/*** _findbuffer ***/
static int _get_buffer_list_id()
{
   switch (p_text) {
   case SEARCH_IN_CURRENT_BUFFER:       return(1);
   case SEARCH_IN_CURRENT_SELECTION:    return(2);
   case SEARCH_IN_CURRENT_PROC:         return(3);
   case SEARCH_IN_ALL_BUFFERS:
   case SEARCH_IN_ALL_ECL_BUFFERS:      return(4);
   }
   return(0);
}

void _findbuffer.on_change(int reason)
{
   if (ignore_change) {
      return;
   }
   search_wid := _get_current_search_wid();
   if (_findtabs.p_ActiveTab == VSSEARCHMODE_FIND && _findinc.p_value && _findinc.p_enabled) {
      int search_range = _get_search_range(search_wid);
      if (search_wid) {
         int orig_wid;
         get_window_id(orig_wid);
         activate_window(search_wid);
         if (is_state.start_pos != '') {
            restore_pos(is_state.start_pos);
            _init_incremental_search_range(search_range);
         }
         activate_window(orig_wid);
         _refresh_incremental_search();
      }
   }
   mode := _findtabs.p_ActiveTab;
   _update_button_state(mode);
}

void _findbuffer.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      window_id := _get_current_search_wid();
      if (window_id && window_id._isEditorCtl(false)) {
         _init_buffers_list(window_id);
      }
   }
}

static void _init_buffer_range(int search_range)
{
   wid := _tbGetActiveFindAndReplaceForm();
   if (wid) {
      _str text;
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
      if (wid._findbuffer._lbfind_item(text) >= 0) {
         wid._findbuffer._cbset_text(text);
      }
   }
}

/*** File Types ***/
static void _init_findfiletypes(bool forceRefresh = false)
{
   // clear this so we will definitely refresh the list
   if (forceRefresh) PUSER_FILETYPELIST_INIT_DONE('');

   // has this been done already?
   if (PUSER_FILETYPELIST_INIT_DONE() == '') {

      // clear out the list
      _lbclear();

      item := '';
      list := def_find_file_types;
      while (list != '') {
         parse list with item ',' list;
         if (item != '') _lbadd_item(item);
      }

      _lbadd_item_no_dupe(MFFIND_BINARY_FILES, 'E', LBADD_BOTTOM);

      // say this has been done already
      PUSER_FILETYPELIST_INIT_DONE(1);
   }
}

static void _init_findfiletypes_ext()
{
   search_wid := _get_current_search_wid();
   wildcard := p_text;
   if ( search_wid && _iswindow_valid(search_wid) && search_wid.p_HasBuffer && search_wid.p_LangId != "fundamental" &&
        search_wid.p_LangId != "process" && search_wid.p_LangId != "fileman" &&
        search_wid.p_LangId != "grep"   // grep mode
      ) {
      if (wildcard == '') {
         _str list = _GetWildcardsForLanguage(search_wid.p_LangId);
         wildcard = list;
      }
   }
   if (wildcard == '') {
      wildcard = _default_c_wildcards();
   }

   // if this is in our list, it might be hidden inside a paren - like Ext Files (*.ext)
   textPos := pos('('wildcard'),', def_find_file_types);
   if (textPos) {
      // get the name
      name := strip(substr(def_find_file_types, 1, textPos - 1));
      lastCommaPos := lastpos(',', name);
      if (lastCommaPos) {
         name = strip(substr(name, lastCommaPos + 1));
      } // else - if no comma, then this is already at the front
      wildcard = name' ('wildcard')';
   }

   p_text = wildcard;
}

/**
 * Parses out the name part of the file type info from the 
 * actual file specification we'll use to search. 
 * 
 * @return _str 
 */
static _str getFindFileTypes()
{
   fileTypes := _findfiletypes.p_text;
   _str name=fileTypes;
   rest := "";
   fileTypes='';

   for (;;) {
      if (name == '' && rest=='') {
         break;
      }
      if (pos('^[^;\(]*\({?*}\)', name, 1, 'R')) {
         rest=strip(substr(name,pos('')+1));
         name=substr(name,pos('S0'),pos('0'));
      } else {
         parse name with  name ";" rest;
      }
      if (name!='') {
         _maybe_append(fileTypes, ";");
         strappend(fileTypes, name);
      }
      name=rest;
   }
   return fileTypes;
}

void _findfiletypes.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      _init_findfiletypes();
   }
}

// rebuild def_find_file_types
static void _remove_find_file_type(_str value)
{
   _str filter_names[];
   _str cur_filter;
   filters := def_find_file_types;
   while (filters:!='') {
      parse filters with cur_filter ',' filters;
      if (cur_filter!=value) {
         filter_names[filter_names._length()]=strip(cur_filter);
      }
   }

   result := "";
   int i;
   for (i=0; i < filter_names._length(); ++i) {
      if (result :!= '') {
         strappend(result,',');
      }
      strappend(result,filter_names[i]);
   }
   def_find_file_types = result;
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

void _findfiletypes.on_change2(int reason,_str value="")
{
   if (reason==CHANGE_DELKEY_2 && p_style==PSCBO_EDIT && p_AllowDeleteHistory) {
      if (pos(value, def_find_file_types, 1) ) {
         // Try to remove item from combo box
         status := _ComboBoxDelete(value);
         if ( !status ) {
            // If we removed the item successfully, remove it from 
            // def_find_file_types.
            _remove_find_file_type(value);
         }
      }
   }
} 

void _editfiletypes.lbutton_up()
{
   // use -new b/c this form is used in the options dialog, and
   // if that form has been opened there, this will just give
   // focus to the options
   result := show('-modal -new -xy _filter_form', def_find_file_types);
   if (result == 1) {
      // set the new value and refresh our combo
      def_find_file_types = _param1;
      _findfiletypes._init_findfiletypes(true);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

/*** Exclude Files ***/
void _init_findfileexcludes(bool forceRefresh = false)
{
   // clear this so we will definitely refresh the list
   if (forceRefresh) PUSER_EXCLUDESTRING_INIT_DONE('');

   // has this been done already?
   if (PUSER_EXCLUDESTRING_INIT_DONE() == '') {
      _lbclear();
      _retrieve_list();
      if (_default_option(VSOPTIONZ_DEFAULT_EXCLUDES) != '') {
         _lbadd_item_no_dupe(MFFIND_DEFAULT_EXCLUDES, 'E', LBADD_BOTTOM);
      }
      _lbadd_item_no_dupe(MFFIND_BINARY_FILES, 'E', LBADD_BOTTOM);
      PUSER_EXCLUDESTRING_INIT_DONE(1);
   }
}
void _findexclude.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      _init_findfileexcludes();
   }
}

/*** _findgrep ***/
void _findgrep.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      _init_grepbuffers();
   }
}

void _mflistfilesonly.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   _mfmatchlines.p_enabled = !_mflistmatchonly.p_value && !_mflistfilesonly.p_value;
   _mflistmatchonly.p_enabled = !_mflistfilesonly.p_value;
   _mflistcontext.p_enabled = !_mflistfilesonly.p_value;
   _update_grep_ab_option();
}

void _mflistmatchonly.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   _mfmatchlines.p_enabled = !_mflistmatchonly.p_value && !(_mflistfilesonly.p_visible && _mflistfilesonly.p_enabled && _mflistfilesonly.p_value);
   _update_grep_ab_option();
}

/*** use re types ***/
static void _init_re_type(int retype)
{
   if (retype) {
      //if (retype == VSSEARCHFLAG_UNIXRE) {
      //   p_text = RE_TYPE_UNIX_STRING;
      //} else if (retype == VSSEARCHFLAG_BRIEFRE) {
      //   p_text = RE_TYPE_BRIEF_STRING;
      //} else 
      if (retype == VSSEARCHFLAG_RE) {
         p_text = RE_TYPE_SLICKEDIT_STRING;
      } else if (retype == VSSEARCHFLAG_WILDCARDRE) {
         p_text = RE_TYPE_WILDCARD_STRING;
      } else if (retype == VSSEARCHFLAG_VIMRE) {
         p_text = RE_TYPE_VIM_STRING;
      } else if (retype == VSSEARCHFLAG_PERLRE) {
         p_text = RE_TYPE_PERL_STRING;
      }
      p_enabled = true;

      if (retype == VSSEARCHFLAG_WILDCARDRE) {
         _replace_re_button.p_enabled = false;
      }
   } else if (_findre.p_value == 0) {
      p_enabled = false;
   }
}

void _findre_type.on_change(int reason)
{
   if (_findre.p_value) {
      _replace_re_button.p_enabled = (_findre_type.p_text != RE_TYPE_WILDCARD_STRING);
   }
   _refresh_incremental_search();
}

void _findre.lbutton_up()
{
   _findre_type.p_enabled = _re_button.p_enabled = _replace_re_button.p_enabled = _findre.p_value ? true : false;
   if (_findre.p_value) {
      _replace_re_button.p_enabled = (_findre_type.p_text != RE_TYPE_WILDCARD_STRING);
   }
   _refresh_incremental_search();
}

void _search_opt_button.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   if (PUSER_LAST_SHOW_SEARCH_OPTIONS() == p_value) {
      return;
   }
   _show_search_options(_findtabs.p_ActiveTab);
   _resize_frame_heights(true);
   PUSER_LAST_SHOW_SEARCH_OPTIONS(p_value);
}

void _result_opt_button.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   if (PUSER_LAST_SHOW_RESULTS_OPTIONS() == p_value) {
      return;
   }
   _show_results_options(_findtabs.p_ActiveTab);
   _resize_frame_heights(true);
   PUSER_LAST_SHOW_RESULTS_OPTIONS(p_value);
}

/* advanced options */
static void _init_mffind_advanced_menu(int menu_handle)
{
   if (_isUnix()) {
      status := _menu_find(menu_handle, "mffind_advanced +h", auto mh, auto mpos, 'M');
      if (!status) {
         _menu_delete(mh, mpos);
      }
      status = _menu_find(menu_handle, "mffind_advanced +s", mh, mpos, 'M');
      if (!status) {
         _menu_delete(mh, mpos);
      }
   }
}

void _findfilesadv_button.lbutton_up()
{
   index := find_index("_mffind_advanced_menu", oi2type(OI_MENU));
   menu_handle := p_active_form._menu_load(index, 'P');
   x := p_x + p_width;
   y := p_y;
   _lxy2dxy(SM_TWIP, x, y);
   _map_xy(p_xyparent, 0, x, y);
   _init_mffind_advanced_menu(menu_handle);
   status := _menu_show(menu_handle, VPM_LEFTALIGN | VPM_RIGHTBUTTON, x, y);
   _menu_destroy(menu_handle);
}

static void _toggle_def_find_file_attr_flags(_str option)
{
   _str rest, arg1, out = "";
   append_option := true;
   parse def_find_file_attr_options with arg1 rest;
   while (arg1 != '') {
      if (option == arg1) {
         append_option = false;
      } else {
         strappend(out, arg1);
         strappend(out, " ");
      }
      parse rest with arg1 rest;
   }
   if (append_option) {
      strappend(out, option);
      strappend(out, " ");
   }
   def_find_file_attr_options = out;
   _config_modify_flags(CFGMODIFY_DEFVAR);
}


int _OnUpdate_mffind_advanced(CMDUI cmdui,int target_wid,_str command)
{
   form_wid := _tbGetActiveFindAndReplaceForm();
   _str cmd, action, val;
   parse command with cmd action val;
   switch (lowcase(action)) {
   case '+h':
   case '+s':
      return((pos(action, def_find_file_attr_options, 1) != 0) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
   case 'grepab':
      if (form_wid) {
         if (form_wid._mfgrepab.p_value) {
            grep_ab := form_wid._mfgrepablines.p_text;
            if (val == grep_ab) {
               return(MF_ENABLED|MF_CHECKED);
            }
         }
      }
      return(MF_ENABLED);
   default:
      return(MF_ENABLED);
   }
}

static void _mffind_configure_file_stats()
{
   result := show("-modal _mffind_file_stats_form",  _findfilestats.p_text);
   if (result != '') {
      _findfilestats.p_text = result;
      if (_findfilestats.p_text != '' && _mffilesstats.p_value == 0) {
         _mffilesstats.p_value = 1; // auto-enable
      } else if ( _mffilesstats.p_value == 1) {
         if (_findfilestats.p_text :== "" || _findfilestats.p_text :== "|") {
            _mffilesstats.p_value = 0;
         }
      }
      _update_findfilestats();
   }
}

_command void mffind_advanced(_str cmdline = '') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   form_wid := _tbGetActiveFindAndReplaceForm();
   if (!form_wid) {
      return;
   }

   _macro_delete_line();
   _str action, val;
   parse cmdline with action val;
   _str result;
   switch (lowcase(action)) {
   case '+f':
      _mffind_configure_file_stats();
      return;
   case '+h':
   case '+s':
      _toggle_def_find_file_attr_flags(action);
      return;

   case 'grepab':
      form_wid._mffind_set_grep_ab_lines(val);
      break;
   }
}

_menu _mfgrepab_menu {
   "-1,+1","mffind_advanced grepab 1,1","","","";
   "-2,+2","mffind_advanced grepab 2,2","","","";
   "-3,+3","mffind_advanced grepab 3,3","","","";
   "0,+1","mffind_advanced grepab 0,1","","","";
   "-1,0","mffind_advanced grepab 1,0","","","";
   "-","","","","";
   "Configure Before/After Match Lines","mffind_advanced grepab","","","";
}


static void _init_mfgrepab_menu(int menu_handle)
{
   // absub
   if (_mfgrepablines.p_text != '' ) {
      Nofitems := _menu_info(menu_handle);
      add_pos := -1;
      for (i := 0; i < Nofitems; ++i) {
         _menu_get_state(menu_handle, i, auto flags, "P", auto caption, auto command);
         if (command :== "") {
            add_pos = i;
            break;
         }
         parse command with "mffind_advanced grepab" auto val;
         if (val :== "") {
            break;
         }
         if (val == _mfgrepablines.p_text) {
            break;
         }
      }

      if (add_pos >= 0) {
         parse _mfgrepablines.p_text with auto before "," auto after;
         caption := "-":+before:+",+":+after;
         _menu_insert(menu_handle, add_pos, MF_ENABLED, caption, "mffind_advanced grepab ":+_mfgrepablines.p_text, "", "", "");
      }
   }
}

void _mfgrepabmenu.lbutton_up()
{
   int index = find_index("_mfgrepab_menu", oi2type(OI_MENU));
   int menu_handle = p_active_form._menu_load(index, 'P');
   int x = p_x + p_width;
   y := p_y;
   _lxy2dxy(SM_TWIP, x, y);
   _map_xy(p_xyparent, 0, x, y);
   _init_mfgrepab_menu(menu_handle);
   int status = _menu_show(menu_handle, VPM_LEFTALIGN | VPM_RIGHTBUTTON, x, y);
   _menu_destroy(menu_handle);
}

static void _init_grep_ab()
{
   _mfgrepablines.p_text = "1,1";
}

static void _mffind_set_grep_ab_lines(_str grep_ab = '')
{
   result := grep_ab;
   if (result == '') {
      lines := (_mfgrepablines.p_text :== '') ? "0,0" : _mfgrepablines.p_text;
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

   do_update := false;
   if (isinteger(result) && ((int)result >= 0)) {
      // set both
      _mfgrepablines.p_text = result','result;
      if (!_mfgrepab.p_value) {
         _mfgrepab.p_value = 1;
      }
      do_update = true;

   } else {
      parse result with auto before "," auto after;
      if (before != '' && isinteger(before) &&
          after != '' && isinteger(after)) {
         // sanity check?
         b := (int)before;
         if (b < 0) { // let user set -N for before line
            b = -b;
         }
         a := (int)after;
         if (a < 0) {
            _message_box("After value must be positive integer.");
            return;
         }
         _mfgrepablines.p_text = b','a;
         if (!_mfgrepab.p_value) {
            _mfgrepab.p_value = 1;
         }
         do_update = true;

      } else {
         // ERR'd
         _message_box("Values must be valid positive integers.");
      }
   }


   // update
   if (do_update) {
      mode := _findtabs.p_ActiveTab;
      _show_results_options(mode);
      _update_grep_ab_option();
   }
}

/*** Search and Replace Expressions ***/
int _OnUpdate_tbfind_expressions_menu(CMDUI cmdui, int target_wid, _str command)
{
   bInReplace  := false;
   bSearchLen  := false; 
   bReplaceLen := false;
   if (target_wid) {
      mode := target_wid._findtabs.p_ActiveTab;
      bInReplace = (mode == VSSEARCHMODE_REPLACE || mode == VSSEARCHMODE_REPLACEINFILES);
      bSearchLen = (length(target_wid._findstring.p_text) > 0);
      bReplaceLen = (length(target_wid._replacestring.p_text) > 0);
   }
   _str cmd, action, id;
   parse command with cmd action id;
   switch (lowcase(action)) {
   case 's':   return(bSearchLen ? MF_ENABLED : MF_GRAYED);
   case 'x':   return((_get_saved_search_count() > 0) ? MF_ENABLED : MF_GRAYED);
   case 'a':   return(MF_ENABLED);
   default:    return(MF_ENABLED);
   }
}

_command void tbfind_expressions_menu(_str cmdline = '') name_info(',' VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _macro_delete_line();
   _str action, type, expr, result;
   parse cmdline with action expr;
   switch (lowcase(action)) {
   case 's':   _save_current_search(); break;
   case 'x':   _remove_saved_search(); break;
   case 'a':   _apply_saved_search(expr); break;
   }
}

static void _save_current_search()
{
   SearchExprOptions expr;
   if (_findtabs.p_ActiveTab != VSSEARCHMODE_FILES) {
      replace_mode := ((_findtabs.p_ActiveTab == VSSEARCHMODE_REPLACE) || (_findtabs.p_ActiveTab == VSSEARCHMODE_REPLACEINFILES));
      expr.m_search_string    = _findstring.p_text;
      expr.m_replace_string   = replace_mode ? _replacestring.p_text : "";
      expr.m_search_flags     =_get_search_flags();
      expr.m_colors           = (_findcolorcheck.p_value) ? _findcoloroptions.p_text : '';
      expr.m_misc_options     = _get_misc_search_opts();
   } else {
      expr.m_search_string    = "";
      expr.m_replace_string   = "";
      expr.m_search_flags     = 0;
      expr.m_colors           = "";
      expr.m_misc_options     = "";
   }

   if (_findtabs.p_ActiveTab == VSSEARCHMODE_FINDINFILES || _findtabs.p_ActiveTab == VSSEARCHMODE_REPLACEINFILES || _findtabs.p_ActiveTab == VSSEARCHMODE_FILES) {
      expr.m_multifile = true;
      expr.m_files = _findfiles.p_text; 
      expr.m_file_types = getFindFileTypes();
      expr.m_file_excludes = _findexclude.p_text;
      expr.m_sub_folders = _findsubfolder.p_value;
      expr.m_file_stats_enabled = _mffilesstats.p_value;
      expr.m_file_stats = _findfilestats.p_text;
   } else {
      expr.m_multifile = false;
      expr.m_files = _findbuffer.p_text;
      expr.m_sub_folders = -1;
      expr.m_file_stats_enabled = -1;
      expr.m_file_stats = "";
   }

   grep_id := 0;
   grep_buffer := _findgrep.p_text;
   if (pos('new', grep_buffer, 1, 'I')) {
      grep_id = GREP_NEW_WINDOW;
   } else if (pos('auto increment', grep_buffer, 1, 'I')) {
      grep_id = GREP_AUTO_INCREMENT;
   } else {
      parse grep_buffer with 'Search<' auto num '>';
      grep_id = (int)num;
   }
   expr.m_grep_id = grep_id;
   expr.m_mfflags = _get_mfflags();
   _save_search_expression(expr);
}

static void _apply_saved_search(_str name)
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
   _init_options(expr.m_search_flags);
   _init_misc_search_opts(expr.m_misc_options);
   if (expr.m_multifile) {
      if (expr.m_files != '') {
         _findfiles.p_text = expr.m_files;
      }
      if (expr.m_files != '') {
         _findfiletypes.p_text = expr.m_file_types;
      }
      if (expr.m_file_excludes != '') {
         _findexclude.p_text =  expr.m_file_excludes;
      }
      if (expr.m_sub_folders >= 0) {
         _findsubfolder.p_value = expr.m_sub_folders;
      }
      if (expr.m_file_stats_enabled >= 0) {
         _mffilesstats.p_value = expr.m_file_stats_enabled;
      }  
      if (expr.m_file_stats != '') {
         _findfilestats.p_text = expr.m_file_stats;
      }

   } else if (expr.m_files != '') {
      _init_buffers_list(_get_current_search_wid());
      if (_findbuffer._lbfind_item(expr.m_files) >= 0) {
         _findbuffer._cbset_text(expr.m_files);
      }
   }
   if (expr.m_colors != '') {
      _findcoloroptions.p_text = expr.m_colors;
   } else {
      _findcoloroptions.p_text = "";
      _findcolorcheck.p_value = 0;
   }
   if (expr.m_grep_id != -1) {
      _set_grep_buffer_id(expr.m_grep_id);
   }
   if (expr.m_mfflags >= 0) {
      _set_results_options(expr.m_mfflags);
   }
   mode := _findtabs.p_ActiveTab;

   _update_list_all_occurrences();
   _update_replace_list_all();
   _update_button_state(mode);
   _update_search_options(mode);
   _show_search_options(mode);
   _init_results_options(mode);
   _show_results_options(mode);
   ignore_change = false;
}

/*** utility functions ***/
static int _get_proc_mark( )
{
   typeless p; save_pos(p);
   int mark_id = _alloc_selection();
   //_macro('m', _macro('s'));
   //_macro_call('select_proc');
   int status = select_proc(0, mark_id, 1);
   if (status == 0) {   //lock selection and mark it persistent
      if (_select_type(mark_id, 'S') == 'C') {
         _select_type(mark_id, 'S', 'E');
      }
      _select_type(mark_id, 'U', 'P');
      restore_pos(p);
   }
   return(mark_id);
}

// Allocates a selection in the current p_buf_id
static int _clone_selection(int src_wid, _str src_mark)
{
   int start_col, end_col, buf_id;
   _get_selinfo(start_col, end_col, buf_id, src_mark);
   if (buf_id != src_wid.p_buf_id) {
      return 0; // source selection and source view don't match, bad bad bad
   }
   if (p_buf_id == buf_id) { // current view and selection are the same
      return _duplicate_selection(src_mark);
   }
   int new_mark = _alloc_selection();
   if (new_mark < 0) {
      return (new_mark);
   }
   int start_line, end_line;
   _str mark_type = _select_type(src_mark, 'T');
   _str mark_style = _select_type(src_mark, 'S');
   if (mark_style == 'C') {  // lock selection
      _select_type(src_mark, 'S', 'E');
   }
   typeless p;
   src_wid.save_pos(p);
   src_wid._begin_select(src_mark);
   start_line = src_wid.p_RLine;
   src_wid._end_select(src_mark);
   end_line = src_wid.p_RLine;
   src_wid.restore_pos(p);
   if (mark_style == 'C') {   // reset select style
      _select_type(src_mark, 'S', 'C');
   }
   p_RLine = start_line; p_col = start_col;
   select_it(mark_type, new_mark);
   p_RLine = end_line; p_col = end_col;
   select_it(mark_type, new_mark);
   return new_mark;
}

static int _get_search_range(int search_wid)
{
   if ((_findtabs.p_ActiveTab == VSSEARCHMODE_FIND) || (_findtabs.p_ActiveTab == VSSEARCHMODE_REPLACE)) {
      switch (_findbuffer.p_text) {
      case SEARCH_IN_CURRENT_BUFFER:      
         return(VSSEARCHRANGE_CURRENT_BUFFER);

      case SEARCH_IN_CURRENT_SELECTION:   
         if (!search_wid || !search_wid.p_HasBuffer) {
            return(VSSEARCHRANGE_CURRENT_BUFFER);
         }
         return(VSSEARCHRANGE_CURRENT_SELECTION);

      case SEARCH_IN_CURRENT_PROC:
         if (!search_wid || !search_wid.p_HasBuffer) {
            return(VSSEARCHRANGE_CURRENT_BUFFER);
         }
         return(VSSEARCHRANGE_CURRENT_PROC);

      case SEARCH_IN_ALL_BUFFERS:
      case SEARCH_IN_ALL_ECL_BUFFERS:
         if (!search_wid || !search_wid.p_HasBuffer || !search_wid.p_mdi_child) {
            return(VSSEARCHRANGE_CURRENT_BUFFER);
         }
         return(VSSEARCHRANGE_ALL_BUFFERS);

      case MFFIND_PROJECT_FILES:
         return(VSSEARCHRANGE_PROJECT);

      case MFFIND_WORKSPACE_FILES:
         return(VSSEARCHRANGE_WORKSPACE);

      default:
         return(VSSEARCHRANGE_CURRENT_BUFFER);
      }
   } else {
      return(VSSEARCHRANGE_CURRENT_BUFFER);
   }
}

_str _get_search_range_label(int search_range)
{
   switch (search_range) {
   case VSSEARCHRANGE_CURRENT_BUFFER:     return(SEARCH_IN_CURRENT_BUFFER);
   case VSSEARCHRANGE_CURRENT_SELECTION:  return(SEARCH_IN_CURRENT_SELECTION); break;
   case VSSEARCHRANGE_CURRENT_PROC:       return(SEARCH_IN_CURRENT_PROC); break;

   case VSSEARCHRANGE_PROJECT:            return(MFFIND_PROJECT_FILES);
   case VSSEARCHRANGE_WORKSPACE:          return(MFFIND_WORKSPACE_FILES);
   case VSSEARCHRANGE_ALL_BUFFERS:
      if (!isEclipsePlugin()) {
         return(SEARCH_IN_ALL_BUFFERS);
      } else {
         return(SEARCH_IN_ALL_ECL_BUFFERS);
      }
      break;
   default:                               return(SEARCH_IN_CURRENT_BUFFER);
   }
}

static _str _get_search_options(int mode = -1,_str &re_syntax='')
{
   if (mode < 0) {
      mode = _findtabs.p_ActiveTab;
   }
   re_syntax='';
   search_range := _findbuffer.p_text;
   search_options := "";
   if (_findword.p_value) search_options :+= 'W';
   if (_findre.p_value) {
      switch (_findre_type.p_text) {
      //case RE_TYPE_UNIX_STRING:      search_options = search_options'U'; break;
      //case RE_TYPE_BRIEF_STRING:     search_options = search_options'B'; break;
      case RE_TYPE_SLICKEDIT_STRING: re_syntax='R';; break;
      case RE_TYPE_PERL_STRING:      re_syntax='L'; break;
      case RE_TYPE_VIM_STRING:       re_syntax='~'; break;
      case RE_TYPE_WILDCARD_STRING:  re_syntax='&'; break;
      }
      strappend(search_options,re_syntax);
   }
   switch (mode) {
   case VSSEARCHMODE_FIND:
      if (!_findcase.p_value) search_options :+= 'I';
      if (_findhidden.p_value) search_options :+= 'H';
      if (!_findlist_all.p_value) {
         if (_findback.p_value) search_options :+= '-';
         if (_findcursorend.p_value) search_options :+= '>';
      }
      if (_findwrap.p_value == 2) {
         search_options :+= '?';
      } else if (_findwrap.p_value) {
         search_options :+= 'P';
      }
      if (search_range == SEARCH_IN_CURRENT_SELECTION || search_range == SEARCH_IN_CURRENT_PROC) {
         search_options :+= 'M';
      }
      break;

   case VSSEARCHMODE_FINDINFILES:
      if (!_findcase.p_value) search_options :+= 'I';
      break;

   case VSSEARCHMODE_REPLACE:
      if (_findcase.p_value) {
         search_options :+= 'E';
      } else {
         search_options :+= 'I';
         if (_replacekeepcase.p_value) {
            search_options :+= 'V';
         }
      }
      if (_findhidden.p_value) search_options :+= 'H';
      if (_replacehilite.p_value) search_options :+= '$';
      if (_findback.p_value) search_options :+= '-';
      if (_findcursorend.p_value) search_options :+= '>';
      if (_findwrap.p_value == 2) {
         search_options :+= '?';
      } else if (_findwrap.p_value) {
         search_options :+= 'P';
      }
      if (search_range == SEARCH_IN_CURRENT_SELECTION || search_range == SEARCH_IN_CURRENT_PROC) {
         search_options :+= 'M';
      }
      break;

   case VSSEARCHMODE_REPLACEINFILES:
      if (_findcase.p_value) {
         search_options :+= 'E';
      } else {
         search_options :+= 'I';
         if (_replacekeepcase.p_value) {
            search_options :+= 'V';
         }
      }
      break;
   }
   if (_findcolorcheck.p_enabled && _findcolorcheck.p_value) search_options :+= _findcoloroptions.p_text;
   return(search_options);
}

static int _get_search_flags()
{
   search_flags := 0;
   search_flags |= _findcase.p_value ? 0: VSSEARCHFLAG_IGNORECASE;
   search_flags |= _findword.p_value ? VSSEARCHFLAG_WORD : 0;
   if (_findre.p_value) {
      switch (_findre_type.p_text) {
      //case RE_TYPE_UNIX_STRING:      search_flags |= VSSEARCHFLAG_UNIXRE; break;
      //case RE_TYPE_BRIEF_STRING:     search_flags |= VSSEARCHFLAG_BRIEFRE; break;
      case RE_TYPE_SLICKEDIT_STRING: search_flags |= VSSEARCHFLAG_RE; break;
      case RE_TYPE_PERL_STRING:      search_flags |= VSSEARCHFLAG_PERLRE; break;
      case RE_TYPE_VIM_STRING:       search_flags |= VSSEARCHFLAG_VIMRE; break;
      case RE_TYPE_WILDCARD_STRING:  search_flags |= VSSEARCHFLAG_WILDCARDRE; break;
      }
   }
   if (_findback.p_visible) {
      search_flags |= _findback.p_value ? VSSEARCHFLAG_REVERSE : 0;
   }
   if (_findhidden.p_visible) {
      search_flags |= _findhidden.p_value ? VSSEARCHFLAG_HIDDEN_TEXT : 0;
   }
   if (_findcursorend.p_visible) {
      search_flags |= _findcursorend.p_value ? VSSEARCHFLAG_POSITIONONLASTCHAR : 0;
   }
   if (_findwrap.p_visible) {
      if (_findwrap.p_value) {
         search_flags |= VSSEARCHFLAG_WRAP;
         if (_findwrap.p_value == 2) {
            search_flags |= VSSEARCHFLAG_PROMPT_WRAP;
         }
      }
   }
   return(search_flags);
}

static int _get_files_list(_str &files, _str &wildcards, _str &exclude)
{
   _str tree_option = _isUnix()?'':def_find_file_attr_options;
   result := "";
   result = _unix_expansion(_findfiles.p_text);
   if (result != '') {
      if ((_findinzipfiles.p_value && _findinzipfiles.p_visible && _findinzipfiles.p_enabled) ||
          (_findsubfolder.p_value && _findsubfolder.p_enabled)) {
         tree_option = '+t ' :+ tree_option;
      }
   }
   result = translate(result, FILESEP, FILESEP2);
   wildcards = getFindFileTypes();
   if (wildcards == '') wildcards = ALLFILES_RE;
   files = tree_option:+result;

   result = _unix_expansion(_findexclude.p_text);
   exclude = translate(result, FILESEP, FILESEP2);
   return(0);
}

// build label from search options
_str _get_search_options_label(_str search_options)
{
   line := "";
   if (pos('i', search_options, 1, 'I')) {
      strappend(line, "Ignore case");
   } else {
      strappend(line, "Match case");
   }
   if (pos('w', search_options, 1, 'I')) {
      strappend(line, ", Whole word");
   }
   if (pos('r', search_options, 1, 'I')) {
      strappend(line, ", "RE_TYPE_SLICKEDIT_STRING);
   } else if (pos('u', search_options, 1, 'I')) {
      strappend(line, ", "RE_TYPE_PERL_STRING);
   } else if (pos('~', search_options, 1, 'I')) {
      strappend(line, ", "RE_TYPE_VIM_STRING);
   //} else if (pos('b', search_options, 1, 'I')) {
   //   strappend(line, ", "RE_TYPE_BRIEF_STRING);
   } else if (pos('l', search_options, 1, 'I')) {
      strappend(line, ", "RE_TYPE_PERL_STRING); 
   } else if (pos('~', search_options, 1, 'I')) {
      strappend(line, ", "RE_TYPE_VIM_STRING); 
   } else if (pos('&', search_options, 1, 'I')) {
      strappend(line, ", "RE_TYPE_WILDCARD_STRING);
   }
   if (pos('-', search_options, 1, 'I')) {
      strappend(line, ", Search backward");
   }
   if (pos('h', search_options, 1, 'I')) {
      strappend(line, ", Search hidden text");
   }
   if (pos('#', search_options, 1, 'I')) {
      strappend(line, ", Show highlights");
   }
   if (pos('v', search_options, 1, 'I')) {
      strappend(line, ", Preserve case");
   }
   if (pos('$', search_options, 1, 'I')) {
      strappend(line, ", Highlight replaced text");
   }
   if (pos('[cx]', search_options, 1, 'RI')) {
      strappend(line, ", Match color");
   }
   return(line);
}

// build label from multi-file search options
static _str _get_search_results_label()
{
   line := "";
   strappend(line, _findgrep.p_text", ");
   if (_mfmdichild.p_value) {
      strappend(line, "Output to editor window, ");
   }
   if (_mflistfilesonly.p_value && _mflistfilesonly.p_enabled && _mflistfilesonly.p_visible) {
      strappend(line, "List filenames only, ");
   }
   if (_mfappendgrep.p_value) {
      strappend(line, "Append to output, ");
   }
   if (_mfmatchlines.p_value && _mfmatchlines.p_enabled) {
      strappend(line, "List matching lines once only, ");
   }
   if (_mflistmatchonly.p_value && _mflistmatchonly.p_enabled) {
      strappend(line, "List matches only, ");
   }
   if (_mflistcontext.p_value && _mflistcontext.p_visible) {
      strappend(line, "List current context, ");
   }
   if (_mfgrepab.p_value && _mfgrepab.p_enabled && _mfgrepab.p_visible) {
      grep_before_lines := 0; grep_after_lines := 0;
      if (_mfgrepablines.p_text != '')  {
         parse _mfgrepablines.p_text with auto b "," auto a;
         if (isinteger(b) && isinteger(a)) {
            grep_before_lines = (int)b;
            grep_after_lines = (int)a;
         }
      }
      caption := "List lines before/after (";
      caption :+= (grep_before_lines == 0) ? "0" : "-"grep_before_lines;
      caption :+= ",";
      caption :+= (grep_after_lines == 0) ? "0" : "+"grep_after_lines;
      caption :+= ")";
      strappend(line, caption);
   }
   if (_findtabs.p_ActiveTab == VSSEARCHMODE_FINDINFILES) {
      if (_mfforegroundsearch.p_value) {
         strappend(line, "Foreground search, ");
      }
   }
   line = substr(line, 1, length(line) - 2);
   return(line);
}

static int _get_grep_buffer_id()
{
   typeless grep_id;
   grep_buffer := _findgrep.p_text;
   if (pos('new', grep_buffer, 1, 'I')) {
      grep_id = add_new_grep_buffer();
      _init_grepbuffers(true);
      _findgrep.p_text = 'Search<' grep_id '>';
   } else if (pos('auto increment', grep_buffer, 1, 'I')) {
      grep_id = auto_increment_grep_buffer();
   } else {
      parse grep_buffer with 'Search<' grep_id '>';
   }
   return(grep_id);
}

static int _get_mfflags(bool allmodes=false)
{
   mfflags := 0;

   if (allmodes) {
      if (_mflistfilesonly.p_value)     mfflags |= MFFIND_FILESONLY;
      if (_mfappendgrep.p_value)        mfflags |= MFFIND_APPEND;
      if (_mfmdichild.p_value)          mfflags |= MFFIND_MDICHILD;
      if (!_mfforegroundsearch.p_value) {
         mfflags |= MFFIND_THREADED;
      } else {
         if (_mfglobal.p_value)            mfflags |= MFFIND_GLOBAL;
         else if (_mfsinglefile.p_value)   mfflags |= MFFIND_SINGLE;
      }
      if (_mfmatchlines.p_value)        mfflags |= MFFIND_SINGLELINE;
      if (_mflistmatchonly.p_value)     mfflags |= MFFIND_MATCHONLY;
      if (_mflistcontext.p_value)       mfflags |= MFFIND_LIST_CURRENT_CONTEXT;
      if (_findinzipfiles.p_value)      mfflags |= MFFIND_LOOKINZIPFILES;
      return mfflags;
   }
   switch (_findtabs.p_ActiveTab) {
   case VSSEARCHMODE_FIND:
      if (_mfappendgrep.p_value)                                        mfflags |= MFFIND_APPEND;
      if (_mfmdichild.p_value)                                          mfflags |= MFFIND_MDICHILD;
      if (_mflistfilesonly.p_enabled && _mflistfilesonly.p_value)       mfflags |= MFFIND_FILESONLY;
      if (_mfmatchlines.p_enabled && _mfmatchlines.p_value)             mfflags |= MFFIND_SINGLELINE;
      if (_mflistmatchonly.p_enabled &&_mflistmatchonly.p_value)        mfflags |= MFFIND_MATCHONLY;
      if (_mflistcontext.p_enabled && _mflistcontext.p_value)           mfflags |= MFFIND_LIST_CURRENT_CONTEXT;
      break;

   case VSSEARCHMODE_REPLACE:
      if (_mfappendgrep.p_value)                                        mfflags |= MFFIND_APPEND;
      if (_mfmdichild.p_value)                                          mfflags |= MFFIND_MDICHILD;
      if (_mflistfilesonly.p_enabled && _mflistfilesonly.p_value)       mfflags |= MFFIND_FILESONLY;
      if (_mfmatchlines.p_enabled && _mfmatchlines.p_value)             mfflags |= MFFIND_SINGLELINE;
      if (_mflistcontext.p_enabled && _mflistcontext.p_value)           mfflags |= MFFIND_LIST_CURRENT_CONTEXT;
      break;

   case VSSEARCHMODE_FINDINFILES:
      if (_mflistfilesonly.p_enabled && _mflistfilesonly.p_value)       mfflags |= MFFIND_FILESONLY;
      if (_mfappendgrep.p_value)                                        mfflags |= MFFIND_APPEND;
      if (_mfmdichild.p_value)                                          mfflags |= MFFIND_MDICHILD;
      if (!_mfforegroundsearch.p_value) {
         mfflags |= MFFIND_THREADED;
      } else {
         if (_mfglobal.p_value)            mfflags |= MFFIND_GLOBAL;
         else if (_mfsinglefile.p_value)   mfflags |= MFFIND_SINGLE;
      }
      if (_mfmatchlines.p_enabled && _mfmatchlines.p_value) mfflags |= MFFIND_SINGLELINE;
      if (_mflistmatchonly.p_enabled && _mflistmatchonly.p_value) mfflags |= MFFIND_MATCHONLY;
      if (_findinzipfiles.p_value && _findinzipfiles.p_visible) {
         mfflags |= MFFIND_LOOKINZIPFILES;
      }
      if (_mflistcontext.p_enabled && _mflistcontext.p_value) mfflags |= MFFIND_LIST_CURRENT_CONTEXT;
      break;

   case VSSEARCHMODE_REPLACEINFILES:
      if (_mflistfilesonly.p_enabled && _mflistfilesonly.p_value)       mfflags |= MFFIND_FILESONLY;
      if (_mfappendgrep.p_value)                                        mfflags |= MFFIND_APPEND;
      if (_mfmdichild.p_value)                                          mfflags |= MFFIND_MDICHILD;
      if (_replaceleaveopen.p_value)                                    mfflags |= MFFIND_LEAVEOPEN;
      if (_mfmatchlines.p_enabled && _mfmatchlines.p_value)             mfflags |= MFFIND_SINGLELINE;
      if (_mflistcontext.p_enabled && _mflistcontext.p_value)           mfflags |= MFFIND_LIST_CURRENT_CONTEXT;
      break;

   case VSSEARCHMODE_FILES:
      mfflags |= MFFIND_FILESONLY;
      if (_mfappendgrep.p_value)        mfflags |= MFFIND_APPEND;
      if (_mfmdichild.p_value)          mfflags |= MFFIND_MDICHILD;
      if (_findinzipfiles.p_value && _findinzipfiles.p_visible) {
         mfflags |= MFFIND_LOOKINZIPFILES;
      }
      break;
   }
   return mfflags;
}

static void  _get_mfablines(int mfflags, int& grep_before_lines, int& grep_after_lines)
{
   grep_before_lines = 0;
   grep_after_lines = 0;

   if ((mfflags & MFFIND_MATCHONLY) || (mfflags & MFFIND_FILESONLY)) {
      return;
   }

   if (_mfgrepab.p_visible && _mfgrepab.p_enabled && _mfgrepab.p_value) {
      if (_mfgrepablines.p_text != '')  {
         parse _mfgrepablines.p_text with auto b "," auto a;
         if (isinteger(b) && isinteger(a)) {
            grep_before_lines = (int)b;
            grep_after_lines = (int)a;
         }
      }
   }
}

static void _append_save_history(_str search_string, _str search_options)
{
   _save_form_response();

   search_wid := _get_current_search_wid();
   replace_mode := (_findtabs.p_ActiveTab == VSSEARCHMODE_REPLACE || _findtabs.p_ActiveTab == VSSEARCHMODE_REPLACEINFILES);
   replace_string := (replace_mode) ? _replacestring.p_text : '';
   range_mode := ((_findtabs.p_ActiveTab == VSSEARCHMODE_FIND) || (_findtabs.p_ActiveTab == VSSEARCHMODE_REPLACE));
   search_range := range_mode ? _get_search_range(search_wid) : -1;
   mfflags := _get_mfflags(true);
   misc_options := _get_misc_search_opts();
   colors := _findcoloroptions.p_text;
   save_last_search(search_string, search_options, search_range, mfflags, misc_options);
   save_last_replace(replace_string);

   PUSER_FINDSTRING_INIT_DONE('');
   if (replace_mode) {
      PUSER_REPLACESTRING_INIT_DONE('');
   }
   if (_findtabs.p_ActiveTab == VSSEARCHMODE_FINDINFILES || _findtabs.p_ActiveTab == VSSEARCHMODE_REPLACEINFILES || _findtabs.p_ActiveTab == VSSEARCHMODE_FILES) {
      if (_findfiles.p_text != '' || _findtabs.p_ActiveTab == VSSEARCHMODE_FILES) {
         switch (_findfiles.p_text) {
         case MFFIND_BUFFER:
         case MFFIND_BUFFERS:
         case MFFIND_BUFFER_DIR:
         case MFFIND_PROJECT_FILES:
         case MFFIND_WORKSPACE_FILES:
            break;

         default:
            _append_retrieve(_control _findfiles, _findfiles.p_text);
            break;
         }
         PUSER_FINDFILES_INIT_DONE('');
      }
      if (_findfiletypes.p_text != '') {
         // we use a def-var for this rather than the append/retrieve stuff
         prepend_new_file_type(_findfiletypes.p_text);

         PUSER_FILETYPELIST_INIT_DONE('');
      }
      if (_findexclude.p_text != '') {
         _append_retrieve(_control _findexclude, _findexclude.p_text);
         PUSER_EXCLUDESTRING_INIT_DONE('');
      }
   }
}

void prepend_new_file_type(_str text)
{
   // see if this is already in our list
   textPos := pos(','text',', ','def_find_file_types',');
   if (textPos) {
      // extract it from the middle so we can put it at the top
      before := substr(def_find_file_types, 1, textPos - 1);
      after := substr(def_find_file_types, textPos + length(text) + 1);

      def_find_file_types = text','before :+ after;
   } else {
      // maybe the file type is there without the name?
      textPos = pos('('text'),', def_find_file_types);
      if (textPos) {
         // extract this part, we're going to put it up front
         after := substr(def_find_file_types, textPos + length(text) + 3);
         before := substr(def_find_file_types, 1, textPos + length(text) + 1); 
         textPos = lastpos(',', before);
         if (textPos) {
            text = substr(before, textPos + 1);
            before = substr(before, 1, textPos);

            def_find_file_types = text','before :+ after;
         } // else - if no comma, then this is already at the front, do nothing
      } else {
         //not found, add it to front
          def_find_file_types = text','def_find_file_types;
      }
   }
}

static void _tool_hide_on_default()
{
   if (def_find_close_on_default) {
      ignore_change = true;
      tw_dismiss(p_active_form, true);
      ignore_change = false;
   }
}

static void _show_current_search_window(int window_id)
{
   if (window_id == 0 || !_iswindow_valid(window_id)) {
      return;
   }
   ignore_change = false;
   if (window_id.p_mdi_child) {
      window_id._set_focus();
   } else if (window_id.p_active_form.p_isToolWindow) {
      if (tw_is_wid_active(window_id.p_active_form)) {
         _str focus_wid = (window_id.p_active_form != window_id) ? window_id.p_name : '';
         activate_tool_window(window_id.p_active_form.p_name,true,focus_wid);
      }
   }
}

static void _show_textbox_error_color(bool show_error)
{
   p_forecolor = (show_error) ? 0x00FFFFFF : 0x80000008;
   p_backcolor = (show_error) ? 0x006666FF : 0x80000005;
}

/*** replace diff view ***/
static int replace_diff_handle = -1;
int replace_diff_begin(bool checkCurrentBufferOnly=false)
{
   if (!_haveDiff()) {
      replace_diff_handle = -1;
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Diff");
      return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
   }
   _project_disable_auto_build(true);
   status := 0;

   if (checkCurrentBufferOnly) {
      if (_mdi.p_child.p_modify && _mdi.p_child._need_to_save()) {
         status = prompt_for_save(nls("Files must be saved before search and replace preview.\n\nSave changes to '%s'?",_build_buf_name()), "", false);
         if (status==IDYES) {
            status=save();
         }
      }
   } else {
      status = _mdi.p_child.list_modified("Files must be saved before search and replace preview", true);
   }
   _project_disable_auto_build(false);
   if(status) {
      return -1;
   }
   handle := refactor_begin_transaction();
   if (handle < 0) {
      return -1;
   }
   replace_diff_handle = handle;
   return 0;
}

void replace_diff_add_file(_str buf_name, int encoding)
{
   if (replace_diff_handle < 0) {
      return;
   }
   refactor_add_file(replace_diff_handle, buf_name, '', '', '', '');
   refactor_set_file_encoding(replace_diff_handle, buf_name, _EncodingToOption(encoding));
}

void replace_diff_set_modified_file(int buf_wid)
{
   if (replace_diff_handle < 0) {
      return;
   }
   refactor_set_modified_file_contents(buf_wid, replace_diff_handle, buf_wid.p_buf_name);
}

void replace_diff_end(bool cancel_diff, _str results_name, _str mfUndoName = '')
{
   if (!_haveDiff()) {
      return;
   }
   if (replace_diff_handle < 0) {
      return;
   }
   if (refactor_count_modified_files(replace_diff_handle) <= 0) {
      cancel_diff = true;
   }
   if (cancel_diff) {
      refactor_cancel_transaction(replace_diff_handle);
      replace_diff_handle = -1;
      return;
   }
   status := 0;
   refactor_review_and_commit_transaction(replace_diff_handle, 
                                          status, '', 
                                          mfUndoName, '', 
                                          results_name, 
                                          quiet:true, 
                                          def_replace_preview_all_reverse_sides);
}

/*** last found cache ***/
static _str last_search_options = '';
static int last_search_flags = 0;

static void _clear_last_found_cache()
{
   last_search_options = '';
   last_search_flags = 0;
}

static bool _search_last_found(_str search_string, _str search_options, int search_range)
{
   if (search_string :== old_search_string &&
       last_search_flags == old_search_flags &&
       last_search_options == search_options &&
       search_range == old_search_range) {
      return(true);
   }
   return(false);
}

static void _save_last_found(_str search_string, _str search_options)
{
   last_search_options = search_options;
   last_search_flags = old_search_flags;
}

// if cursor is already at the end of the selection, go ahead move it to the
// beginning
static void _adjust_cursor_in_search_selection(_str mark_id)
{
    int first_col,last_col,buf_id;
   _get_selinfo(first_col,last_col,buf_id,mark_id);

   _str mark_type = _select_type(mark_id);
   if (old_search_flags & VSSEARCHFLAG_REVERSE) {
      if (_begin_select_compare(mark_id) == 0) {
         if (mark_type == 'BLOCK') {
            int columnStartPixel,columnEndPixel;
            _BlockSelGetStartAndEndPixel(columnStartPixel,columnEndPixel,mark_id);
            _BlockSelGetStartAndEndCol(first_col,last_col,columnStartPixel,columnEndPixel,mark_id);
            --last_col;
         }
         if (((mark_type == 'BLOCK') || (mark_type == 'CHAR')) && (p_col <= first_col)) {
            _end_select(mark_id);
         } else if ((mark_type == 'LINE') && (p_col <= first_col)) {
            _end_select(mark_id); _end_line();
         }
      }
   } else {
      if (_end_select_compare(mark_id) == 0) {
         if (mark_type == 'BLOCK') {
            int columnStartPixel,columnEndPixel;
            _BlockSelGetStartAndEndPixel(columnStartPixel,columnEndPixel,mark_id);
            _BlockSelGetStartAndEndCol(first_col,last_col,columnStartPixel,columnEndPixel,mark_id);
            --last_col;
         }
         if (((mark_type == 'BLOCK') || (mark_type == 'CHAR')) && (p_col >= last_col + _select_type(mark_id,'I'))) {
            _begin_select(mark_id);
         } else if ((mark_type == 'LINE') && (p_col >= _text_colc())) {
            _begin_select(mark_id); _begin_line();
         }
      }
   }
}

// compares last match selection with markid for equivalence
int _compare_select_match(_str markid = '')
{
   status := -1;
   if (def_leave_selected) {
       // get current selection info for last match found
      _str last_found = _alloc_selection();
      _select_match(last_found);
      status = _compare_selection(markid, last_found);
      _free_selection(last_found);
   }
   return (status);
}

// update current selection used for search in selection
void _update_old_search_mark()
{
   if (old_search_range == VSSEARCHRANGE_CURRENT_SELECTION) {
      if (!def_leave_selected) {
         // !def_leave_selected already behaves
         return;
      }
      if (select_active2()) {
         if (old_search_mark != '') {
            if (!_compare_select_match('')) {
               // still in last found
               return;
            }
         }
         int Noflines;
         typeless junk;
         _get_selinfo(junk, junk, junk, '', junk, junk, junk, Noflines);
         if (Noflines > 1) {
            _str new_search_mark = _duplicate_selection();
            if (_select_type(new_search_mark, 'S') == 'C') {
               _select_type(new_search_mark, 'S', 'E');
            }
            _select_type(new_search_mark, 'U', 'P');
            _adjust_cursor_in_search_selection(new_search_mark);
            _free_selection(old_search_mark);
            old_search_mark = new_search_mark;
         }
      }
   }
}

// based on the current search range, update the search mark if needed
bool _update_find_next_mark(_str& search_mark)
{
   show_mark := false;
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   if (old_search_range == VSSEARCHRANGE_CURRENT_SELECTION) {
      if (select_active()) {
         // replace current search mark with new locked selection
         if (search_mark != '') {
            _free_selection(search_mark);
            search_mark = '';
         }
         search_mark = _duplicate_selection();
         _adjust_cursor_in_search_selection(search_mark);
         show_mark = true;
      } else if (search_mark == '') {
         // no search mark, waiting for new user selection
         show_mark = false;
      } else if (!_in_selection(search_mark)) {
         // have a search mark, but moved cursor out of selection, free it
         // and wait for another selection
         _free_selection(search_mark);
         search_mark = '';
         show_mark = false;
      } else {
         show_mark = true;
      }
   } else if (old_search_range == VSSEARCHRANGE_CURRENT_PROC) {
      if (_in_selection(search_mark)) {
         show_mark = true;
      } else {
         // cursor moved outside of search mark, attempt to generate a new one
         if ((p_lexer_name != '') && _allow_find_current_proc()) {
            if (search_mark != '') {
               _free_selection(search_mark);
               search_mark = '';
            }
            search_mark = _get_proc_mark();
            if (search_mark) {
               show_mark = true;
            }
         }
      }
      if (!show_mark) {
         _free_selection(search_mark);
         search_mark = '';
         old_search_range = VSSEARCHRANGE_CURRENT_BUFFER;
         _init_buffer_range(VSSEARCHRANGE_CURRENT_BUFFER);
         set_find_next_msg("Find", old_search_string, old_search_flags, old_search_range);
      }
   } else {
      show_mark = false;
      if (search_mark) {
         _free_selection(search_mark);
         search_mark = '';
         if (old_search_range != VSSEARCHRANGE_CURRENT_BUFFER) {
            old_search_range = VSSEARCHRANGE_CURRENT_BUFFER;
            _init_buffer_range(VSSEARCHRANGE_CURRENT_BUFFER);
            set_find_next_msg("Find", old_search_string, old_search_flags, old_search_range);
         }
      }
   }
   restore_search(s1, s2, s3, s4, s5);
   return(show_mark);
}

/**
 * Clear highlights created by find/replace with highlighting matches enabled.
 *
 * @see find
 * @see replace
 * @see gui_find
 * @see gui_replace
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
_command void clear_highlights()
{
   _macro_call('clear_highlights');
   if (_no_child_windows()) {
      return;
   }

   int type = _GetTextColorMarkerType();
   if (!type) {
      return; 
   }
   int orig_view_id;
   get_window_id(orig_view_id);
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   int orig_buf_id = p_buf_id;
   int first_buf_id = _mdi.p_child.p_buf_id;
   p_buf_id = first_buf_id;
   for (;;) {
      if (!(p_buf_flags & VSBUFFLAG_HIDDEN) && !_isGrepBuffer(p_buf_name)) {
         _StreamMarkerRemoveType(p_window_id, type);
      }
      _next_buffer('hr');
      if (p_buf_id == first_buf_id) {
         break;
      }
   }
   p_buf_id = orig_buf_id;
   activate_window(orig_view_id);
   toggle_search_flags(0, VSSEARCHFLAG_FINDHILIGHT);
}

/**
 * Clear scroll markup created by find/replace with highlighting
 * matches or list all occurences enabled
 *
 * @see find
 * @see replace
 * @see gui_find
 * @see gui_replace
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 *
 */
_command void clear_scroll_highlights()
{
   scrollMarkType := _GetScrollColorMarkerType();
   if ( scrollMarkType!= 0) {
      _ScrollMarkupRemoveAllType(scrollMarkType);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Macro/Search helper functions
//

/**
 * List all occurrences in a buffer.
 *
 * @param search_text
 *                String to search for.
 * @param search_options
 *                Search options (@see find)
 * @param mfflags search results flags
 * @param grep_id ID of search results windows (0-max number).
 *
 * @return Number of occurrences
 *
 * @see search
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 */
void list_all_occurrences(_str search_text, _str search_options, int search_range, int mfflags, int grep_id, int grep_before_lines, int grep_after_lines)
{
   if (search_range == VSSEARCHRANGE_PROJECT || search_range == VSSEARCHRANGE_WORKSPACE) {
      _list_all_in_project(search_text, search_options, (search_range == VSSEARCHRANGE_WORKSPACE), mfflags, grep_id, grep_before_lines, grep_after_lines);
      save_last_search(search_text, search_options);
      return;
   }

   save_pos(auto p);
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   mark_all_occurences(search_text, search_options, search_range, mfflags, grep_id, false, true, false, false, false, grep_before_lines, grep_after_lines);
   restore_search(s1, s2, s3, s4, s5);
   restore_pos(p);
}

/**
 * Highlight all matching occurrences in a buffer.
 *
 * @param search_text
 *                String to search for.
 * @param search_options
 *                Search options (@see find)
 *
 * @return Number of occurrences
 *
 * @see search
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 */
void highlight_all_occurrences(_str search_text, _str search_options, int search_range)
{
   num_matches := 0;
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   mark_all_occurences(search_text, search_options, search_range, 0, 0, true, false, false, false, false);
   restore_search(s1, s2, s3, s4, s5);
}

/**
 * Bookmark all matching occurences in a buffer.
 *
 * @param search_text
 *                String to search for.
 * @param search_options
 *                Search options (@see find)
 *
 * @return Number of occurrences
 *
 * @see search
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Search_Functions
 */
void bookmark_all_occurrences(_str search_text, _str search_options, int search_range)
{
   num_matches := 0;
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   mark_all_occurences(search_text, search_options, search_range, 0, 0, false, false, true, false, false);
   restore_search(s1, s2, s3, s4, s5);
   activate_bookmarks();
   updateBookmarksToolWindow();
}

void multiselect_all_occurrences(_str search_text, _str search_options, int search_range)
{
   num_matches := 0;
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   mark_all_occurences(search_text, search_options, search_range, 0, 0, false, false, false, false, true);
   restore_search(s1, s2, s3, s4, s5);
}

void _UpgradeFindFileTypes(_str config_migrated_from_version)
{
   // if we did not upgrade from anything, don't worry about it
   if (config_migrated_from_version == '') return;

   // get the major version
   dotPos := pos('.', config_migrated_from_version);
   if (dotPos) {

      prevMajorVersion := (int)substr(config_migrated_from_version, 1, dotPos - 1);
      // we split alias expansion from syntax expansion in v15
      if (prevMajorVersion < 19) {
         // set equal to def-file-types
         def_find_file_types = def_file_types;
         _config_modify_flags(CFGMODIFY_DEFVAR);

         // then add the stuff that was in the combo box previously
         _str list[];
         retrieve_list_items('_tbfind_form._findfiletypes', list);
         for (i := list._length() - 1; i >= 0; i--) {
            prepend_new_file_type(list[i]);
         }
      }
   }
}
/*** module init ***/
definit()
{
   _clear_last_found_cache();

   if (def_max_mffind_output_ksize <= 0) {
      def_max_mffind_output_ksize = 2 * 1024;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   is_state.window_id = 0;

   gIncMarkerType = -1;
   gIncScrollMarkerType = -1;

   gon_create_window_id = -1;
}

defeventtab _mffind_file_stats_form;

static bool _ignore_timechange = false;

static int _mffind_filetime_op_value(_str value)
{
   switch (value) {
   case "Date Only":    return MFFILE_STAT_TIME_DATE;
   case "Before":       return MFFILE_STAT_TIME_BEFORE;
   case "After":        return MFFILE_STAT_TIME_AFTER;
   case "Range":        return MFFILE_STAT_TIME_RANGE;
   case "Not in Range": return MFFILE_STAT_TIME_NOT_RANGE;
   }
   return MFFILE_STAT_TIME_NONE;
}


static _str _mffind_filetime_op_name(int value)
{
   switch (value) {
   case MFFILE_STAT_TIME_DATE:      return "Date Only";
   case MFFILE_STAT_TIME_BEFORE:    return "Before";
   case MFFILE_STAT_TIME_AFTER:     return "After";
   case MFFILE_STAT_TIME_RANGE:     return "Range";
   case MFFILE_STAT_TIME_NOT_RANGE: return "Not in Range";
   }
   return "";
}

static _str localDateTime(_str strDt) 
{
   if (strDt == '') {
      return strDt;
   }
   DateTime dt = DateTime.fromString(strDt);
   result := dt.toStringParts(DT_LOCALTIME, DT_DATE);
   if (dt.hour() > 0 || dt.minute() > 0 || dt.second() > 0)  {
      strT := dt.toStringParts(DT_LOCALTIME, DT_TIME);
      result = result:+' ':+substr(strT, 1, 5);
      if (dt.second() > 0) {
         result = result:+substr(strT, 6, 3);
      }
   }
   return result;
}

_mffind_file_stats_form.on_create()
{
   ctldatetimeop._lbadd_item(_mffind_filetime_op_name(MFFILE_STAT_TIME_DATE));
   ctldatetimeop._lbadd_item(_mffind_filetime_op_name(MFFILE_STAT_TIME_BEFORE));
   ctldatetimeop._lbadd_item(_mffind_filetime_op_name(MFFILE_STAT_TIME_AFTER));
   ctldatetimeop._lbadd_item(_mffind_filetime_op_name(MFFILE_STAT_TIME_RANGE));
   ctldatetimeop._lbadd_item(_mffind_filetime_op_name(MFFILE_STAT_TIME_NOT_RANGE));
   ctltime1.p_auto_select = false; ctltime2.p_auto_select = false;
   sizeBrowseButtonToTextBox(ctldatetimeop.p_window_id, cltrange_menu.p_window_id);
   cltrange_menu.p_x = ctldatetimeop.p_x_extent - _twips_per_pixel_x();

   _ignore_timechange = true;
   _retrieve_prev_form();

   file_stats := arg(1);
   if (file_stats != '') {
      mffile_size := _mffind_file_stats_get_file_size(file_stats);
      if (mffile_size > 0) {
         cbfilesize.p_value = 1;
         ctlfilesize.p_text = mffile_size;
      } else {
         cbfilesize.p_value = 0;
      }

      modified_op := _mffind_file_stats_get_file_modified(file_stats, auto dt1, auto dt2);
      if (modified_op != MFFILE_STAT_TIME_NONE) {
         ctlmodified.p_value = 1;
         ctldatetimeop.p_text = _mffind_filetime_op_name(MFFILE_STAT_TIME_NONE);
         if (dt1 != '') {
            parse localDateTime(dt1) with auto d auto t;
            ctldate1.p_text = d;
            ctltime1.p_text = t;
         }
         if (dt2 != '') {
            parse localDateTime(dt2) with auto d auto t;
            ctldate2.p_text = d;
            ctltime2.p_text = t;
         }
      } else {
         ctlmodified.p_value = 0;
      }
   }
   cbfilesize.call_event(_control cbfilesize, LBUTTON_UP, "W");
   ctldatetimeop.call_event(CHANGE_OTHER, _control ctldatetimeop, ON_CHANGE, "W");
   _ignore_timechange = false;
}

_menu _ctldaterange_menu {
   "Today","mffind_file_stats_daterange 0d","","","";
   "Last Week","mffind_file_stats_daterange 1w","","","";
   "Last Month","mffind_file_stats_daterange 1m","","","";
   "Last 3 Months","mffind_file_stats_daterange 3m","","","";
   "Last Year","mffind_file_stats_daterange 1y","","","";
}

void cltrange_menu.lbutton_up()
{
   int index = find_index("_ctldaterange_menu", oi2type(OI_MENU));
   int menu_handle = p_active_form._menu_load(index, 'P');
   int x = p_x + p_width;
   y := p_y;
   _lxy2dxy(SM_TWIP, x, y);
   _map_xy(p_xyparent, 0, x, y);
   int status = _menu_show(menu_handle, VPM_LEFTALIGN | VPM_RIGHTBUTTON, x, y);
   _menu_destroy(menu_handle);
}

_command void mffind_file_stats_daterange(_str cmdline = '') name_info(',' VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   DateTime dt1, dt2;
   switch (lowcase(cmdline)) {
   case '0d':
      break;
   case '1w':
      dt1 = dt1.add(-7, DT_DAY); 
      break;
   case '1m':
      dt1 = dt1.add(-1, DT_MONTH);
      break;
   case '3m':
      dt1 = dt1.add(-3, DT_MONTH);
      break;
   case '1y':
      dt1 = dt1.add(-1, DT_YEAR);
      break;
   default:
      return;
   }

   ctldate1.p_text = dt1.toStringParts(DT_LOCALTIME, DT_DATE);

   mod_op := _mffind_filetime_op_value(ctldatetimeop.p_text);
   switch (mod_op) {
   case MFFILE_STAT_TIME_RANGE:
   case MFFILE_STAT_TIME_NOT_RANGE:
      ctldate2.p_text = dt2.toStringParts(DT_LOCALTIME, DT_DATE);
      break;
   }
}

void cbfilesize.lbutton_up()
{
   ctlfilesize.p_enabled = (cbfilesize.p_value != 0) ? true : false;
}

void ctlmodified.lbutton_up()
{
   mod_enabled := (ctlmodified.p_value != 0);
   mod_op := _mffind_filetime_op_value(ctldatetimeop.p_text);
   mod_date_op := (mod_op == MFFILE_STAT_TIME_DATE);
   mod_range_op := (mod_op == MFFILE_STAT_TIME_RANGE) || (mod_op == MFFILE_STAT_TIME_NOT_RANGE);

   ctldatetimeop.p_enabled = ctlcalendar1.p_enabled = ctlcalendar2.p_enabled = mod_enabled;
   ctldate1.p_enabled = mod_enabled;
   ctltime1.p_enabled = ctlspin1.p_enabled = (mod_enabled && !mod_date_op);
   ctldate2.p_enabled = (mod_enabled && mod_range_op);
   ctltime2.p_enabled = ctlspin2.p_enabled = (mod_enabled && mod_range_op);
   cltrange_menu.p_visible = true;
   cltrange_menu.p_enabled = mod_enabled;

   if (ctldate1.p_enabled && ctldate1.p_text :== '') {
      DateTime currentDateTime;
      ctldate1.p_text = currentDateTime.toStringParts(DT_LOCALTIME, DT_DATE);
   }
   if (ctldate2.p_enabled && ctldate2.p_text :== '') {
      DateTime currentDateTime;
      ctldate2.p_text = currentDateTime.toStringParts(DT_LOCALTIME, DT_DATE);
   }
   _ignore_timechange = true;
   if (ctltime1.p_enabled && ctltime1.p_text :== '') {
      ctltime1.p_text = _set_time_text(0, 0, -1);
   }
   if (ctltime2.p_enabled && ctltime2.p_text :== '') {
      ctltime2.p_text = _set_time_text(0, 0, -1);
   }
   _ignore_timechange = false;
}

void ctldatetimeop.on_change(int reason)
{
   ctlmodified.call_event(_control ctlmodified, LBUTTON_UP, "W");
}

/*
yyyy-mm-dd
*/
static void _parse_date_text(_str d, int& yyyy, int& mm, int& dd)
{
   parse d with auto YYYY "-" auto MM "-" auto DD .;
   yyyy = -1; mm = dd = 0;
   if (YYYY != '' && isinteger(YYYY)) {
      yyyy = (int)YYYY;
      if (MM != '' && isinteger(MM)) {
         mm = (int)MM;
      } else {
         mm = 1;
      }
      if (DD != '' && isinteger(DD)) {
         dd = (int)DD;
      } else {
         dd = 1;
      }
   }
}

void ctldate1.'S- ','C- '()
{
   p_text = _date('I');
   _set_sel(1);
}

void ctldate1.'range-first-char-key'-'range-last-char-key'()
{
   key := last_event();
   col := _get_sel();
   switch (key) {
   case '0':
   case '1':
   case '2':
   case '3':
   case '4':
   case '5':
   case '6':
   case '7':
   case '8':
   case '9':
   case ' ':
   case '-':
      break;

   default:
      return;
   }

   if (key == ' ') {
      if (p_text :== '') {
         p_text = _date('I');
         _set_sel(1);
         return;
      }
      _set_sel(col + 1);
      return;
   }

   d := p_text;
   _parse_date_text(d, auto yyyy, auto mm, auto dd);
   sep1 := sep2 := 0;
   sep1 = pos(d, '-', 1);
   if (sep1 > 0) {
      sep2 = pos(d, '-', sep1+1);
   }

   if (key == '-') {
      if (sep2 > 0) {
         return;
      }
   }
   keyin(key);
}

void ctlcalendar1.lbutton_up()
{
   textwid := p_prev;
   _parse_date_text(textwid.p_text, auto yyyy, auto mm, auto dd);
   if (!DateTime.validDate(yyyy, mm, dd)) {
      _parse_date_text(_date('I'), yyyy, mm, dd);
   }

   DateTime dt(yyyy, mm, dd);
   DateTime returnDate;
   show('-modal _calendar_form', dt, 0, null, &returnDate);
   if (returnDate != null) {
      parse returnDate.toString() with auto newDate 'T' .;
      textwid.p_text = newDate;
   } 
}

/*
00:00:00
*/
static void _parse_time_text(_str t, int& hh, int& mm, int& ss, bool includeSecs = false)
{
   parse t with auto HH ":" auto MM ":" auto SS;
   hh = mm = 0; ss = -1;
   if (HH != '' && isinteger(HH)) {
      hh = (int)substr(HH,1,2,'0');
      if (hh < 0 || hh > 23) {
          hh = 0;
      }
      if (MM != '' && isinteger(MM)) {
         mm = (int)substr(MM,1,2,'0');
         if (mm < 0 || mm > 59) {
             mm = 0;
         }
         if (SS != '' && isinteger(SS)) {
            ss = (int)substr(SS,1,2,'0');
            if (ss < 0 || ss > 59) {
                ss = 0;
            }
         }
      }
   }

   if (includeSecs && ss < 0) {
      ss = 0;
   }
}

static _str _set_time_text(int hh, int mm, int ss)
{
   v := "";
   if (hh < 0 || hh > 23) {
       hh = 0;
   }
   if (hh < 10) {
      v = "0":+hh;
   } else {
      v = hh;
   }

   if (mm < 0 || mm > 59) {
       mm = 0;
   }
   if (mm < 10) {
      v :+= ':0'mm;
   } else {
      v :+= ':':+mm;
   }

   if (ss > 59) {
      ss = 1;
   }
   if (ss < 0) {
   } else if (ss < 10) {
      v :+= ':0'ss;
   } else {
      v :+= ':':+ss;
   }
   return v;
}

static _str _set_time_column(_str t, int col, _str n)
{
   if (col == 3 || col == 6) {
      return t;
   }
   return ((col > 1) ? (substr(t, 1, col - 1):+n) : n):+substr(t, col + 1);
}

void ctltime1.'S- ','C- '()
{
   _ignore_timechange = true; 
   p_text = substr(_time('M'), 1, 5);
   _ignore_timechange = false;
   _set_sel(1);
}

void ctltime1.'range-first-char-key'-'range-last-char-key'()
{
   key := last_event();
   col := _get_sel();
   _parse_time_text(p_text, auto hh, auto mm, auto ss);
   t := _set_time_text(hh, mm, ss);

   switch (key) {
   case '0':
   case '1':
   case '2':
   case '3':
   case '4':
   case '5':
   case '6':
   case '7':
   case '8':
   case '9':
   case ' ':
   case ':':
      break;

   default:
      return;
   }

   if (key == ' ') {
      if (ss < 0) {
         if (col > 5) {
            _ignore_timechange = true; p_text = _set_time_text(hh, mm, 0); _ignore_timechange = false;
            _set_sel(7);
            return;
         }
      }
      if (col >= 9) {
         return;
      }
      if (col == 2 || col == 5) {
         col = col + 1;
      }
      _set_sel(col + 1);
      return;
   }

   if (key == ':') {
      if (col == 3 || col == 6) {
         if (ss < 0 && col == 6) {
            _ignore_timechange = true; p_text = _set_time_text(hh, mm, 0); _ignore_timechange = false;
         }
         _set_sel(col+1);
         return;
      }
      return;
   }

   if (col >= 9) {
      return;
   }
   if (col >= 6 && ss < 0) {
      t = t:+":00"; col = 7;
   }
   if (col == 3 || col == 6) {
      col = col + 1;
   }

   num := (int)key;
   switch (col) {
   case 1:
      if (num > 2) {
         _set_time_column(t, col, "0");
         col = col + 1;
      }  
      break;
   case 4:
   case 7:
      if (num > 5) {
         _set_time_column(t, col, "0");
         col = col + 1;
      }  
      break;
   }

   
   new_t := _set_time_column(t, col, key);
   _parse_time_text(new_t, hh, mm, ss);
   _ignore_timechange = true; p_text = _set_time_text(hh, mm, ss); _ignore_timechange = false;
   if (col < 9) {
      if (col == 2 || col == 5) {
         col = col + 1;
      }
      _set_sel(col + 1);
   }
}

void ctltime1.on_change()
{
   if (_ignore_timechange) {
      return;
   }
   t := p_text;
   _parse_time_text(t, auto hh, auto mm, auto ss);
   v := _set_time_text(hh, mm, ss);
   if (v != t) {
      col := _get_sel();
      p_text = v;
      _set_sel(col);
   }
}

static void _increment_hhmmss(int textwid, bool updown)
{
   col := textwid._get_sel();
   _parse_time_text(textwid.p_text, auto hh, auto mm, auto ss);
   if (col < 3) {
      if (updown) {
         hh = hh + 1;
         if (hh > 23) {
            hh = 0;
         }
      } else {
         hh = hh - 1;
         if (hh < 0) {
            hh = 23;
         }
      }
   } else if (col < 6) {
      if (updown) {
         mm = mm + 1;
         if (mm > 59) {
            mm = 0;
         }
      } else {
         mm = mm - 1;
         if (mm < 0) {
            mm = 59;
         }
      }
   } else {
      if (updown) {
         ss = ss + 1;
         if (ss > 59) {
            ss = 0;
         }
      } else {
         ss = ss - 1;
         if (ss < 0) {
            ss = 59;
         }
      }
   }

   _ignore_timechange = true;
   textwid.p_text = _set_time_text(hh, mm, ss);
   _ignore_timechange = true;
}

void ctlspin1.on_spin_up()
{
   textwid := p_prev;
   _increment_hhmmss(textwid, true);
}

void ctlspin1.on_spin_down()
{
   textwid := p_prev;
   _increment_hhmmss(textwid, false);
}

void ctlok.lbutton_up()
{
   // MAX FILE SIZE; MODIFIED_TIME_OP, "LOCAL TIME 1", "LOCAL TIME 2"
   mffile_size := "";
   mffile_modified := "";

   if (cbfilesize.p_value != 0) {
      mffile_size = ctlfilesize.p_text;
      if (!isinteger(mffile_size) || ((int)mffile_size < 0)) {
         _message_box(nls("Invalid File Size argument: '%s'", mffile_size));
         return;
      }
   }

   if (ctlmodified.p_value != 0) {
      mod_op := _mffind_filetime_op_value(ctldatetimeop.p_text);
      if (mod_op == MFFILE_STAT_TIME_NONE) {
         _message_box(nls("Invalid Modified File Time action '%s'", mod_op));
         return;
      }

      hh := mm := ss := 0;
      // validate date time
      _parse_date_text(ctldate1.p_text, auto YYYY, auto MM, auto DD);
      
      if (mod_op != MFFILE_STAT_TIME_DATE) {
         _parse_time_text(ctltime1.p_text, hh, mm, ss, true);
      }
      if (!DateTime.validDate(YYYY,MM,DD) || !DateTime.validTime(hh,mm,ss)) {
         v := ctldate1.p_text' 'ctltime1.p_text;
         _message_box(nls("Invalid Modified File Time argument [1]: '%s'", v));
         return;
      }

      DateTime posixtime(1970, 1, 1, 0, 0, 0, 1, DT_UTCTIME);
      DateTime dt1((int)YYYY,(int)MM,(int)DD,(int)hh,(int)mm,(int)ss);
      if (dt1 < posixtime) {
         v := ctldate1.p_text' 'ctltime1.p_text;
         _message_box(nls("Not valid a POSIX file date/time argument [1]: '%s'", v));
         return;
      }

      mffile_modified = mod_op:+',"':+dt1.toStringLocal():+'"';

      mod_range_op := (mod_op == MFFILE_STAT_TIME_RANGE) || (mod_op == MFFILE_STAT_TIME_NOT_RANGE);
      if (mod_range_op) {
         _parse_date_text(ctldate2.p_text, YYYY, MM, DD);
         _parse_time_text(ctltime2.p_text, hh, mm, ss, true);
         if (!DateTime.validDate(YYYY,MM,DD) || !DateTime.validTime(hh,mm,ss)) {
            v := ctldate2.p_text' 'ctltime2.p_text;
            _message_box(nls("Invalid Modified File Time argument [2]: '%s'", v));
            return;
         }

         DateTime dt2((int)YYYY,(int)MM,(int)DD,(int)hh,(int)mm,(int)ss);
         if (dt1 < posixtime) {
            v := ctldate2.p_text' 'ctltime2.p_text;
            _message_box(nls("Not valid a POSIX file date/time argument [2]: '%s'", v));
            return;
         }

         if (dt2 <= dt1) {
            v1 := ctldate1.p_text' 'ctltime1.p_text;
            v2 := ctldate2.p_text' 'ctltime2.p_text;
            _message_box(nls("Invalid Modified File Range argument [1] >= [2]: '%s' '%s'", v1, v2));
            return;
         }
         mffile_modified :+= ',"':+dt2.toStringLocal():+'"';
      }
   }

   _save_form_response();
   file_stats := mffile_size'|':+mffile_modified;
   p_active_form._delete_window(file_stats);
}


/**
 * Determines if the cursor is in a function body or statement scope.
 */
bool _allow_find_current_proc()
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // update the context and find the element under the cursor
   _UpdateContext(true);
   context_id := tag_current_context();
   if (context_id <= 0) {
      return false;
   }

   // check for function or statement
   tag_type := "";
   tag_get_detail2(VS_TAGDETAIL_context_type,context_id,tag_type);
   if (p_LangId == 'py' && tag_type == 'var') {
      // Look at the containing context instead to see if this decl is in a function or statement.
      tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, auto outer);
      if (outer > 0) {
         context_id = outer;
         tag_get_detail2(VS_TAGDETAIL_context_type, context_id, tag_type);
      }
   }

   if (!tag_tree_type_is_func(tag_type) && !tag_tree_type_is_statement(tag_type)) {
      return false;
   }

   // not in a function body or statement
   return true;
}

