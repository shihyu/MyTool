////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50437 $
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
#include "xml.sh"
#import "bgsearch.e"
#import "bookmark.e"
#import "clipbd.e"
#import "compile.e"
#import "complete.e"
#import "cutil.e"
#import "dir.e"
#import "dlgman.e"
#import "files.e"
#import "guicd.e"
#import "guifind.e"
#import "guireplace.e"
#import "listbox.e"
#import "main.e"
#import "makefile.e"
#import "markfilt.e"
#import "mouse.e"
#import "mfsearch.e"
#import "recmacro.e"
#import "combobox.e"
#import "refactor.e"
#import "optionsxml.e"
#import "picture.e"
#import "pip.e"
#import "projconv.e"
#import "project.e"
#import "saveload.e"
#import "search.e"
#import "sellist.e"
#import "seltree.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbautohide.e"
#import "tbcmds.e"
#import "tbdeltasave.e"
#import "tbsearch.e"
#import "toolbar.e"
#import "wkspace.e"
#require "se/search/SearchResults.e"
#import "sstab.e"
#endregion
 
using se.search.SearchResults;

#define DLGINFO_CURRENT_SEARCH_WID 0
#define DLGINFO_CURRENT_BUFFER 1

/**
 * Hide tab bar in find tool window.
 *
 * @default false
 * @categories Configuration_Variables
 */
boolean def_find_hide_tabs = false;

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
_str def_find_file_attr_flags = "";


static boolean ignore_change = false;
static int current_find_mode = VSSEARCHMODE_FIND;

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
_command int gui_find(...) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (p_active_form.p_modal) {
      return gui_find_modal();
   }
   toolShowFind(VSSEARCHMODE_FIND, p_window_id, arg(1));
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
   if (select_active()) {
      int current_flags = def_mfsearch_init_flags;
      def_mfsearch_init_flags = MFSEARCH_INIT_SELECTION;
      if (isEclipsePlugin()) {
         _eclipse_get_workspace_dir(auto wspace_dir);
         toolShowFind(VSSEARCHMODE_FINDINFILES, p_window_id, arg(1), wspace_dir);
      } else {
         toolShowFind(VSSEARCHMODE_FINDINFILES, p_window_id, arg(1), _GetWorkspaceDir());
      }
      def_mfsearch_init_flags = current_flags;
   } else {
      _message_box("Command requires active selection.");
   }
   _macro_delete_line();
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
_command int gui_replace(...) name_info(','VSARG2_REQUIRES_MDI)
{
   toolShowFind(VSSEARCHMODE_REPLACE, p_window_id, arg(1));
   _macro_delete_line();
   return 0;
}

_command void replace_in_files() name_info(','VSARG2_EDITORCTL)
{
   toolShowFind(VSSEARCHMODE_REPLACEINFILES, p_window_id, arg(1));
   _macro_delete_line();
}

// deprecated commands
_command void find_collapsed() name_info(','VSARG2_EDITORCTL)
{
    gui_find();
}

// deprecated commands
_command void replace_collapsed() name_info(','VSARG2_EDITORCTL)
{
   gui_replace();
}

static void toolShowFind(int mode = -1, int window_id = -1, _str options = '', _str path = '')
{
   int was_recording = _macro();
   if (was_recording) {
      _macro('m', 0);
   }
   boolean already_open = true;
   window_id = _validate_search_buffer(window_id);
   // if object not created, then just let on_load event handle initialization
   if (_find_object("_tbfind_form", 'n') == 0) {
      already_open = false;
      current_find_mode = mode;
   }
   int formid;
   if (isEclipsePlugin()) {
      show('-xy _tbfind_form');
      formid = _find_object('_tbfind_form._findstring');
      if (formid) {
         formid._set_focus();
      }
   } else {
      formid = activate_toolbar("_tbfind_form", '_findstring');
   }

   if (!formid) {
      return;
   }
   if (already_open) {
      formid._init_current_search_buffer(window_id);
      formid._init_mode(mode);
      formid._init_findstring(window_id);
   }
   formid._set_search_options(options, path);
   if (!already_open && !tbIsDocked("_tbfind_form")) { //force it to resize
      formid._resize_frame_heights(true);
   }
   _macro('m', was_recording);
   return;
}

/*** initialize options ***/
static int _space_controls_y(int ctrl_ids[], int pad_y, int cur_y, int align_x = -1)
{
   int i;
   for (i = 0; i < ctrl_ids._length(); ++i) {
      int wid = ctrl_ids[i];
      if (wid.p_visible) {
         wid.p_y = cur_y + pad_y;
         cur_y = wid.p_y + wid.p_height;
         if (align_x >= 0) {
            wid.p_x = align_x;
         }
      }
   }
   return(cur_y);
}

static void _resize_frame_widths(boolean force_refresh = false)
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
   _findexclude.p_width += widthDiff;
   _search_frame.p_width += widthDiff;
   _files_frame.p_width += widthDiff;
   _show_search_options();
   _show_results_options();
   _resize_frame_heights(false);
}

static void _resize_frame_heights(boolean resize_form = false)
{
   int start_y = 0;
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
   if (!tbIsDocked(p_active_form.p_name) && resize_form) {
      int border_height = p_active_form.p_height - _dy2ly(p_active_form.p_xyscale_mode, p_active_form.p_client_height);
      _get_child_extents(p_active_form, w, h, true);
      p_active_form.p_height = border_height + h + 90;
      
      if (!_tbIsAutoShownWid(p_active_form) && !isEclipsePlugin()) {
         int container_wid = _tbContainerFromWid(p_active_form);
         if (container_wid && container_wid != p_active_form) {
            container_wid.p_height = p_active_form.p_height;
         }
      }
   }
}

static void _show_search_text()
{
   switch (current_find_mode) {
   case VSSEARCHMODE_FIND:
      _find_label.p_visible         = true;
      _findstring.p_visible         = true;
      _replace_label.p_visible      = false;
      _replacestring.p_visible      = false;
      _findbuffer.p_visible         = true;
      _findfiles.p_visible          = false;
      _replace_re_button.p_visible  = false;
      _findfiles_button.p_visible   = false;
      break;
   case VSSEARCHMODE_FINDINFILES:
      _find_label.p_visible         = true;
      _findstring.p_visible         = true;
      _replace_label.p_visible      = false;
      _replacestring.p_visible      = false;
      _findbuffer.p_visible         = false;
      _findfiles.p_visible          = true;
      _replace_re_button.p_visible  = false;
      _findfiles_button.p_visible   = true;
      break;
   case VSSEARCHMODE_REPLACE:
      _find_label.p_visible         = true;
      _findstring.p_visible         = true;
      _replace_label.p_visible      = true;
      _replacestring.p_visible      = true;
      _findbuffer.p_visible         = true;
      _findfiles.p_visible          = false;
      _replace_re_button.p_visible  = true;
      _findfiles_button.p_visible   = false;
      break;
   case VSSEARCHMODE_REPLACEINFILES:
      _find_label.p_visible         = true;
      _findstring.p_visible         = true;
      _replace_label.p_visible      = true;
      _replacestring.p_visible      = true;
      _findbuffer.p_visible         = false;
      _findfiles.p_visible          = true;
      _replace_re_button.p_visible  = true;
      _findfiles_button.p_visible   = true;
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
   _space_controls_y(ctrl_ids, 15, 30);

   _re_button.p_y = _findstring.p_y;
   _replace_re_button.p_y = _replacestring.p_y;
   _findfiles_button.p_y = _findfiles.p_y;

   int w, h;
   _get_child_extents(_search_frame.p_window_id, w, h, true);
   _search_frame.p_height = h;
}

static void _show_button_frame()
{
   // we need these to keep track of our button columns
   int button_col1[], button_col2[];
   button_col1._makeempty();
   button_col2._makeempty();

   int search_wid = _get_current_search_wid();
   if ( search_wid == "" ) search_wid = 0;

   // show/hide based on current tab
   switch (current_find_mode) {
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
   }

   // make the buttons in our columns visible
   int i;
   for ( i = 0; i < button_col1._length(); ++i ) {
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

static void _update_button_state()
{
   int search_wid = _get_current_search_wid();
   if ( search_wid == "" ) search_wid = 0;

   if (current_find_mode == VSSEARCHMODE_FINDINFILES || current_find_mode == VSSEARCHMODE_REPLACEINFILES) {
      _find_btn.p_enabled           = true;
      _replace_btn.p_enabled        = true;
      _replaceall_btn.p_enabled     = true;
      _replacepreview_btn.p_enabled = true;
      _stop_btn.p_enabled = (gbgm_search_state != 0);
   } else {
      if (search_wid == 0) {
         if (current_find_mode == VSSEARCHMODE_FIND || current_find_mode == VSSEARCHMODE_REPLACE) {
            _find_btn.p_enabled           = false;
            _replace_btn.p_enabled        = false;
            _replaceall_btn.p_enabled     = false;
            _replacepreview_btn.p_enabled = false;
         }
      } else {
         _str bufname = search_wid.p_buf_name;
         if (current_find_mode == VSSEARCHMODE_FIND || current_find_mode == VSSEARCHMODE_REPLACE) {
            if (_findbuffer.p_text == SEARCH_IN_ALL_BUFFERS ||
                _findbuffer.p_text == SEARCH_IN_ALL_ECL_BUFFERS) {
               int child_windows = _mdi._no_child_windows();
               _find_btn.p_enabled           = (child_windows == 0);
               _replace_btn.p_enabled        = (child_windows == 0);
               _replaceall_btn.p_enabled     = (child_windows == 0);
               _replacepreview_btn.p_enabled = (child_windows == 0);
            } else {
               _find_btn.p_enabled           = (search_wid != 0);
               _replace_btn.p_enabled        = (search_wid != 0 && (search_wid.p_mdi_child != 0));
               _replaceall_btn.p_enabled     = (search_wid != 0 && (search_wid.p_mdi_child != 0));
               _replacepreview_btn.p_enabled = (search_wid != 0 && (search_wid.p_mdi_child != 0));
            }

            if ((bufname :== '') || _isGrepBuffer(bufname) || (bufname == '.process') || _isDSBuffer(bufname) || (search_wid.p_buf_flags & VSBUFFLAG_HIDDEN)) {
               _replacepreview_btn.p_enabled = false;
            } else {
               _replacepreview_btn.p_enabled = true;
            }
         }
      }
   }

   // find color button needs to be updated
   if (current_find_mode == VSSEARCHMODE_FIND || current_find_mode == VSSEARCHMODE_REPLACE) {
      if (_findbuffer.p_text == SEARCH_IN_ALL_BUFFERS ||
          _findbuffer.p_text == SEARCH_IN_ALL_ECL_BUFFERS) {
         _findcolor.p_enabled = !_mdi._no_child_windows();
      } else {
         _findcolor.p_enabled = (search_wid != 0) && (search_wid.p_HasBuffer && search_wid.p_lexer_name != "");
      }
   } else {
      _findcolor.p_enabled = true;
   }
}

static void _update_search_options()
{
   boolean list_all = (_findlist_all.p_value != 0 && _findlist_all.p_enabled);
   _findwrap.p_enabled = _findcursorend.p_enabled = _findback.p_enabled = !(list_all && (current_find_mode == VSSEARCHMODE_FIND));
}

static void _show_search_options()
{
   int ctrl_ids[];
   int w, h;
   int pad_h;
   int new_width = (_re_button.p_x + _re_button.p_width) - _results_frame.p_x;

   if (_search_opt_button.p_value == 0) {
      _str search_options = _get_search_options();
      _str label = "Search options: ":+_get_search_options_label(search_options);
      if (current_find_mode == VSSEARCHMODE_FIND || current_find_mode == VSSEARCHMODE_REPLACE) {
         if (pos('P', search_options, 1, 'I')) {
            strappend(label, ", Wrap at beginning/end");
         } else if (pos('?', search_options,1, 'I')) {
            strappend(label, ", Prompt at beginning/end");
         } else {
            strappend(label, ", No wrap");
         }
      }
      if (current_find_mode == VSSEARCHMODE_FIND) {
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
      }
      if (current_find_mode == VSSEARCHMODE_REPLACEINFILES) {
         if (_replaceleaveopen.p_value) {
            strappend(label, ", Leave modified files open");
         }
      }
      if (_findcoloroptions.p_text != '') {
         strappend(label, ", "_findcolorlabel.p_caption);
      }

      _options_label.p_caption = label;
      _options_label.p_auto_size = false;
      _options_label.p_width = _options_frame.p_width - _options_label.p_x - 180;

      _oframe_1.p_visible = false;
      _oframe_2.p_visible = false;
      _oframe_3.p_visible = false;
      _findall_options.p_visible = false;
      pad_h = 90;
   } else {
      _options_label.p_caption = "Search options";
      _options_label.p_auto_size = true;
      _oframe_1.p_visible = true;
      switch (current_find_mode) {
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
}

static void _show_results_options()
{
   // not visible?  don't bother!
   if (!_results_frame.p_visible) {
      return;
   }

   // line the frame up with the menu button
   int new_width = (_re_button.p_x + _re_button.p_width) - _results_frame.p_x;

   int w, h;
   int pad_h;

   if (_result_opt_button.p_value == 0) {
      _results_label.p_caption = "Results options: ":+_get_search_results_label();
      _results_label.p_auto_size = false;
      _results_label.p_width = _results_frame.p_width - _results_label.p_x - 180;

      _results_box.p_visible = false;
      _foreground_box.p_visible = false;
      pad_h = 90;
   } else {
      _results_box.p_visible = true;
      switch (current_find_mode) {
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
   }

   _get_child_extents(_results_box.p_window_id, w, h, true);
   _results_box.p_height = h + pad_h;

   _get_child_extents(_results_frame.p_window_id, w, h, true);
   if (w + 90 > new_width) {
      new_width = w + 90;
   }
   _results_label.p_width = new_width - (2 * _results_label.p_x);
   _get_child_extents(_results_frame.p_window_id, w, h, true); // must be called again to get correct height
   _results_frame.p_width = new_width;
   _results_frame.p_height = h + pad_h;
}

static void _init_results_options(int mode)
{
   switch (mode) {
   case VSSEARCHMODE_FIND:
   case VSSEARCHMODE_REPLACE:
       _mflistfilesonly.p_visible = false;
      break;

   case VSSEARCHMODE_FINDINFILES:
   case VSSEARCHMODE_REPLACEINFILES:
      _mflistfilesonly.p_visible = true;
      break;
   }
   _mflistmatchonly.p_enabled = !_mflistfilesonly.p_visible || !_mflistfilesonly.p_value;
   _mfmatchlines.p_enabled = !_mflistmatchonly.p_value && (!_mflistfilesonly.p_visible || !_mflistfilesonly.p_value);
}

static void _showhide_controls(int mode, boolean forceRefresh = false)
{
   if (mode == current_find_mode && !forceRefresh) return;
   int search_wid = _get_current_search_wid();
   _findtabs.p_visible = def_find_hide_tabs ? false : true;
   ignore_change = true;
   _findtabs.p_ActiveTab = mode;
   ignore_change = false;

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
      _findfiles._init_files_list();
      _mfforegroundsearch.p_visible = true;
      _mfforegroundoptions.p_visible = true;
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
      _findfiles._init_files_list();
      _mfforegroundsearch.p_visible = false;
      _mfforegroundoptions.p_visible = false;
      break;
   }
   current_find_mode = mode;
   _show_search_text();
   _show_button_frame();
   _update_button_state();
   _update_search_options();
   _show_search_options();
   _init_results_options(mode);
   _show_results_options();
   _resize_frame_heights(true);
   _mfhook.call_event(CHANGE_SELECTED, (mode == VSSEARCHMODE_FINDINFILES), _mfhook, LBUTTON_UP, '');
   _findstring._show_textbox_error_color(false);
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
   _findre.p_value = flags & (VSSEARCHFLAG_RE | VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE | VSSEARCHFLAG_PERLRE | VSSEARCHFLAG_WILDCARDRE);
   if (_findre.p_value) {
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
      _findre_type.p_enabled = false;
      _re_button.p_enabled = false;
      _replace_re_button.p_enabled = false;
   }
   _replacekeepcase.p_value = flags & VSSEARCHFLAG_PRESERVE_CASE;
   _replacehilite.p_value = flags & VSSEARCHFLAG_REPLACEHILIGHT;

   _findinc.p_value = 0;
   _findlist_all.p_value = 0;
   _findmark_all.p_value = 0;
   _findbookmark_all.p_value = 0;
   _replaceleaveopen.p_value = 0;
   _replacelist.p_value = 0;
   _findcoloroptions.p_text = '';
   _showhide_controls(current_find_mode, true);
}

static void _set_search_options(_str search_options, _str path = '')
{
   if (pos('-', search_options)) {
      _findback.p_value = 1;
   } else if (def_keys == "brief-keys") {
      //In brief, if we aren't searching back, we are always searching forward.
      _findback.p_value = 0;
   }
   if (pos('[rubRUB&]', search_options, 1, 'r')) {
      _findre.p_value = 1;
      if (pos('r', search_options, 1, 'I')) {
         _findre_type._init_re_type(VSSEARCHFLAG_RE);
      } else if (pos('u', search_options, 1, 'I')) {
         _findre_type._init_re_type(VSSEARCHFLAG_UNIXRE);
      } else if (pos('b', search_options, 1, 'I')) {
         _findre_type._init_re_type(VSSEARCHFLAG_BRIEFRE);
      } else if (pos('l', search_options, 1, 'I')) {
         _findre_type._init_re_type(VSSEARCHFLAG_PERLRE);
      } else if (pos('&', search_options, 1)) {
         _findre_type._init_re_type(VSSEARCHFLAG_WILDCARDRE);
      }
   }
   if (path != '' && file_exists(path)) {
      _findfiles.p_text=path;
   }
}

static void _set_results_options(int mfflags)
{
   // apply mfflags
   if (!(_default_option(VSOPTION_APIFLAGS) & 0x80000000) && _mfforegroundsearch.p_visible) {
      _mfforegroundsearch.p_visible = false;
      _mfforegroundsearch.p_value = 1;
   }
   _mfmdichild.p_value = mfflags & MFFIND_MDICHILD;
   _mflistfilesonly.p_value = mfflags & MFFIND_FILESONLY;
   _mfappendgrep.p_value = mfflags & MFFIND_APPEND;
   _mfmatchlines.p_value = mfflags & MFFIND_SINGLELINE;
   _mflistmatchonly.p_value = mfflags & MFFIND_MATCHONLY;
   _mfforegroundsearch.p_value = (mfflags & MFFIND_THREADED) ? 1 : 0;
   _mfglobal.p_enabled = _mfsinglefile.p_enabled = _mfprompted.p_enabled = (_mfforegroundsearch.p_value == 1) ? true : false;
   if (mfflags & MFFIND_GLOBAL) {
      _mfglobal.p_value = 1;
      _mfsinglefile.p_value = 0;
      _mfprompted.p_value = 0;
   } else if (mfflags & MFFIND_SINGLE) {
      _mfglobal.p_value = 0;
      _mfsinglefile.p_value = 1;
      _mfprompted.p_value = 0;
   } else {
      _mfglobal.p_value = 0;
      _mfsinglefile.p_value = 0;
      _mfprompted.p_value = 1;
   }
   _mfmatchlines.p_enabled = !(mfflags & MFFIND_FILESONLY) && !(mfflags & MFFIND_MATCHONLY);
   _mflistmatchonly.p_enabled = !(mfflags & MFFIND_FILESONLY);
}

static void _init_findstring(int window_id)
{
   ignore_change = true;
   _findstring.p_sel_start = 1;
   if (def_mfsearch_init_flags & MFSEARCH_INIT_HISTORY) {
      _findstring.p_text = old_search_string;
   }
   if (window_id && window_id._isEditorCtl(false)) {
      if (def_mfsearch_init_flags & MFSEARCH_INIT_CURWORD) {
         int junk;
         _findstring.p_text = window_id.cur_word(junk, '', 1);
      }
      if (def_mfsearch_init_flags & MFSEARCH_INIT_SELECTION && window_id.select_active2()) {
         int mark_locked = 0;
         if (_select_type('', 'S') == 'C') {
            mark_locked = 1;
            _select_type('', 'S', 'E');
         }
         _str str;
         window_id.filter_init();
         window_id.filter_get_string(str);
         window_id.filter_restore_pos();
         _findstring.p_text = str;
         if (mark_locked) {
            _select_type('', 'S','C');
         }
      }
      // auto initialize if selection available
      if (window_id.select_active2()) {
         int start_col=0, end_col=0;
         typeless junk;
         _str buf_name='';
         int Noflines = 0;
         window_id._get_selinfo(start_col, end_col, junk, '', buf_name, junk, junk, Noflines);
         if (_select_type('') == 'LINE' || Noflines > 1) {
            // if current selection is active, is not the previous search selection,
            // and is a multiline selection, initialize search range to current selection
            _init_buffer_range(VSSEARCHRANGE_CURRENT_SELECTION);
         }
      }
   }
   _findstring._refresh_scroll();
   _findstring.p_sel_length = _findstring.p_text._length();
   _findstring._set_focus();
   _findstring._show_textbox_error_color(false);
   ignore_change = false;
}

static void _init_mode(int mode, boolean forceRefresh = false)
{
   _findtabs._showhide_controls(mode, forceRefresh);
}

static int _validate_search_buffer(int search_wid)
{
   if (search_wid <= 0 || !_iswindow_valid(search_wid)) {
      search_wid = _mdi._edit_window();
   }
   if (search_wid) {
      if (!search_wid.p_HasBuffer || (search_wid.p_window_flags & HIDE_WINDOW_OVERLAP)) {
         search_wid = 0;
      }
   }
   return(search_wid);
}

static boolean ignore_switchbuf = false;
static void _init_current_search_buffer(int search_wid)
{
   if (ignore_switchbuf) {
      return;
   }
   _str search_bufname = "";
   int orig_wid;
   get_window_id(orig_wid);
   int form_id = _find_object("_tbfind_form", "n");
   if (form_id == 0) {
      return;
   }
   activate_window(form_id);
   search_wid = _validate_search_buffer(search_wid);
   if (search_wid) {
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
   /*
   if (search_wid) {
      if (search_wid == _find_object("_tbshell_form._shellEditor")) {
         _buffer_label.p_caption = "Build";
      } else if (search_wid == _find_object("_tboutputwin_form.ctloutput")) {
         _buffer_label.p_caption = "Output";
      } else if (_isGrepBuffer(search_wid.p_buf_name)) {
         typeless grep_id;
         parse search_wid.p_buf_name with ".search" grep_id;
         _buffer_label.p_caption = "Search<"grep_id">";
      } else if (search_wid.p_name == "list1" && search_wid.p_active_form.p_modal) {
         _buffer_label.p_caption = search_wid.p_active_form.p_caption;   //diff/history/other
      } else {
         _buffer_label.p_caption = strip_filename(search_wid.p_buf_name, 'P');
      }
   } else {
      _buffer_label.p_caption = "";
   }
   */
   _SetDialogInfo(DLGINFO_CURRENT_SEARCH_WID, search_wid, _control _find_btn);
   _SetDialogInfo(DLGINFO_CURRENT_BUFFER, search_bufname, _control _find_btn);
   if (search_wid == 0) {
      _findlist_all.p_enabled = true;
      _findmark_all.p_enabled = true;
      _findbookmark_all.p_enabled = true;
      _update_list_all_occurrences();
      _update_replace_list_all();
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
      if ((bufname :== '') || _isGrepBuffer(bufname) || (bufname == '.process') || _isDSBuffer(bufname) || (search_wid.p_buf_flags & VSBUFFLAG_HIDDEN)) {
         _findbookmark_all.p_enabled = false;
      } else {
         _findbookmark_all.p_enabled = true;
      }
      _update_list_all_occurrences();
      _update_replace_list_all();
   }
   _findfiles.p_user = '';
   _update_button_state();
   // set defaults
   if (_findbuffer.p_text=='') {
      _findbuffer._lbtop();
      _findbuffer.p_text = _lbget_text();
   }
   if (_findgrep.p_text=='') {
      _findgrep._lbtop();
      _findgrep.p_text = _lbget_text();
   }
   activate_window(orig_wid);
}

static void _update_search_buffer()
{
   int formid = _find_object("_tbfind_form", 'n');
   if (formid == 0) {
      return;
   }
   int window_id = 0;
   if (_mdi.p_child._no_child_windows() == 0) {
      if (p_HasBuffer) {
         if (p_mdi_child) {
            window_id = _mdi.p_child.p_window_id;
         } else {
            window_id = p_window_id;
         }
      } else {
         window_id = _mdi.p_child.p_window_id;
      }
   }
   formid._init_current_search_buffer(window_id);
}

void _cbmdibuffer_hidden_tbfind()
{
   _update_search_buffer();
}

void _switchbuf_tbfind(_str oldbuffname, _str flag)
{
   _update_search_buffer();
}

static void _init_re()
{
   _findre_type._lbadd_item(RE_TYPE_UNIX_STRING);
   _findre_type._lbadd_item(RE_TYPE_BRIEF_STRING);
   _findre_type._lbadd_item(RE_TYPE_SLICKEDIT_STRING);
   _findre_type._lbadd_item(RE_TYPE_PERL_STRING);
   _findre_type._lbadd_item(RE_TYPE_WILDCARD_STRING);
}

static void _init_grepbuffers(boolean forceRefresh = false)
{
   if (forceRefresh) _findgrep.p_user = '';
   int last_grep_id = _get_last_grep_buffer();
   if (_findgrep.p_user == '' || _findgrep.p_user != last_grep_id) {
      _str old_text = _findgrep.p_text;
      _findgrep._lbclear();
      int i;
      for (i = 0; i < last_grep_id + 1; ++i) {
         _findgrep._lbadd_item('Search<'i'>');
      }
      if (last_grep_id + 1 < def_max_search_results_buffers) {
         _findgrep._lbadd_item('<New>');
      }
      _findgrep._lbadd_item('<Auto Increment>');
      _findgrep.p_user = last_grep_id;
   }
}

static void _init_buffers_list(int search_wid)
{
   origText := _findbuffer.p_text;
   _findbuffer._lbclear();
   if (search_wid != 0) {
      _findbuffer._lbadd_item(SEARCH_IN_CURRENT_BUFFER);
      if (search_wid.p_HasBuffer) {
         if (!search_wid._isnull_selection()) {
            _findbuffer._lbadd_item(SEARCH_IN_CURRENT_SELECTION);
         }
         if ((search_wid.p_lexer_name != '') && search_wid._in_function_scope()) {
            _findbuffer._lbadd_item(SEARCH_IN_CURRENT_PROC);
         }
      }
      if (!_no_child_windows() && !_findinc.p_value) {
         if (!isEclipsePlugin()) {
            _findbuffer._lbadd_item(SEARCH_IN_ALL_BUFFERS);
         } else {
            _findbuffer._lbadd_item(SEARCH_IN_ALL_ECL_BUFFERS);
         }
      }
      _findbuffer._show_textbox_error_color(false);
   } else {
      if (!isEclipsePlugin()) {
         _findbuffer._lbadd_item(SEARCH_IN_NONE);
      } else {
         _findbuffer._lbadd_item(SEARCH_IN_ECL_NONE);
      }
      _findbuffer._lbtop();
      _findbuffer._show_textbox_error_color(true);
   }
   if (origText != "") {
      _findbuffer._cbset_text(origText);
   }
}

/*** form functions ***/
defeventtab _tbfind_form;

void _tbfind_form.on_create()
{
   _tbfind_form_initial_alignment();

   int i, j;
   ignore_change = true;
   _SetDialogInfo(DLGINFO_CURRENT_SEARCH_WID, 0, _control _find_btn);
   _SetDialogInfo(DLGINFO_CURRENT_BUFFER, "", _control _find_btn);

   int search_wid = _get_focus();
   if (!_iswindow_valid(search_wid) || !search_wid.p_HasBuffer) {
      search_wid = _mdi._edit_window();
   }
   _init_re();
   _init_grepbuffers();
   _init_buffers_list(search_wid);
   _findfiletypes._init_findfiletypes();
   _findfiletypes._init_findfiletypes_ext();
   if (_retrieve_prev_form() || def_find_init_defaults) {
      _init_options(_default_option('s'));
   }
   _init_current_search_buffer(search_wid);
   _showhide_controls(current_find_mode, true);

   _findstring._retrieve_list(); _findstring.p_user = 1;
   _replacestring._retrieve_list(); _replacestring.p_user = 1;
   _findexclude._retrieve_list(); _findexclude.p_user = 1;

   _replacestring.p_text = old_replace_string;
   _init_findstring(search_wid);
   ignore_change = false;
#if __UNIX__
   _findfilesadv_button.p_enabled = false;
   _findfilesadv_button.p_visible = false;
#endif
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

   // match the other text/combo boxes to the new widths
   _findbuffer.p_width = _findfiletypes.p_width = _findexclude.p_width = _findstring.p_width;

   // now size the buttons at the bottom
   // first make sure the text fits inside
   _replacepreview_btn.p_auto_size = true;
   width := _replacepreview_btn.p_width;
   _replacepreview_btn.p_auto_size = false;

   // match all the button widths
   _find_btn.p_width = _replace_btn.p_width = _replaceall_btn.p_width = _stop_btn.p_width = width;

   // make sure the frame is big enough
   _button_frame.p_width = (2 * width) + 20;

   _button_frame.p_x = rightAlign - _button_frame.p_width;
}

void _tbfind_form.on_destroy()
{
   _save_form_response();
   _end_incremental_search();
   toggle_search_flags(0, VSSEARCHFLAG_FINDHILIGHT);
   call_event(p_window_id, ON_DESTROY, '2');
   _clear_last_found_cache();
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
   int current_wid = _get_current_search_wid();
   _tbDismiss(p_active_form);
   _show_current_search_window(current_wid);
}

void _tbfind_form.'C-A'-'C-Z','c-s-a'-'c-s-z','c-a-a'-'c-a-z',F1-F12,C_F12,A_F1-A_F12,S_F1-S_F12,'c-0'-'c-9','c-s-0'-'c-s-9','c-a-0'-'c-a-9','a-0'-'a-9','M-A'-'M-Z','M-0'-'M-9','S-M-A'-'S-M-Z','S-M-0'-'S-M-9'()
{
   if (ignore_change) {
      return;
   }
   _str key = last_event();
   _str keyname = name_on_key(key);

   _macro('m', _macro('s'));
   if (keyname == "gui-find" ) {
      _init_mode(VSSEARCHMODE_FIND);
      return;
   } else if (keyname == "gui-replace" ) {
      _init_mode(VSSEARCHMODE_REPLACE);
      return;
   } else if (keyname == "find-in-files" ) {
      _init_mode(VSSEARCHMODE_FINDINFILES);
      return;
   } else if (keyname == "replace-in-files" ) {
      _init_mode(VSSEARCHMODE_REPLACEINFILES);
      return;
   } else if (keyname == "find-next" ) {
      _tbfind_OnFindNext(false);
      return;
   } else if (keyname == "find-prev" ) {
      _tbfind_OnFindNext(true);
      return;
   }

   _smart_toolbar_hotkey();
#if 0
   if (key :== F7) {
      _retrieve_next_form('-',1); return;
   } else if (key :== F8) {
      _retrieve_next_form('',1); return;
   }

   // pass through to default eventtabs
   int active_form_wid = p_active_form;
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

// Special handling for find_next key binding
static void _tbfind_OnFindNext(boolean doPrevious)
{
   int form_wid = _find_formobj("_tbfind_form", 'n');
   int search_wid;
   search_wid = (form_wid != 0) ? form_wid._get_current_search_wid() : _mdi._edit_window();
   if (search_wid) {
      if (doPrevious) {
         _macro_call('find_prev');
         search_wid.find_prev();
      } else {
         _macro_call('find_next');
         search_wid.find_next();
      }
   }
}

_command void tbfind_options_menu(_str cmdline = '') name_info(',' VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _macro_delete_line();
   switch (lowcase(cmdline)) {
   case "o":
      show_general_options(1);
      break;

   case "d":
      _init_options(_default_option('s'));
      break;

   case "c":
      _init_options(VSSEARCHFLAG_IGNORECASE);
      _set_results_options(MFFIND_GLOBAL);
      break;

   case "s":
      int search_flags = _get_search_flags();
      _default_option('S', search_flags);
      int retype = search_flags & (VSSEARCHFLAG_RE | VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE | VSSEARCHFLAG_PERLRE | VSSEARCHFLAG_WILDCARDRE);
      if (retype) {
         def_re_search = retype;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      break;

   case "t":
      def_find_hide_tabs = !def_find_hide_tabs;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _showhide_controls(current_find_mode, true);
      break;

   case "z":
      clear_highlights();
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
   _menu_get_state(submenu_handle1, 0, flags, 'p', '', submenu_handle2);

   _str array[];
   _get_saved_search_names(array);
   if (array._length() <= 0) {
      _menu_insert(submenu_handle2, 0, MF_GRAYED, "None", "", "", "", "");
   } else {
      int i;
      for (i = 0; i < array._length(); ++i) {
         menu_text = 'tbfind_expressions_menu a ':+ i;
         _menu_insert(submenu_handle2, i, MF_ENABLED, array[i], menu_text, "", "", "");
      }
   }
   x = x - 100;
   y = y - 100;
   _lxy2dxy(p_scale_mode, x, y);
   _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   flags = VPM_LEFTALIGN | VPM_RIGHTBUTTON;
   int status = _menu_show(menu_handle, flags, x, y);
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
      if ( wid > 0 && _iswindow_valid(wid) ) {
         return wid;
      }
   }
   return 0;
}

static int _activate_current_search_wid()
{
   int window_id = _get_current_search_wid();
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
      _showhide_controls(p_ActiveTab);
   }
}

/*** find matches ***/
int _search_all_buffers(_str search_text, _str search_options)
{
   //say('_search_all_buffers');
   _macro_call('_search_all_buffers', search_text, search_options);
   if (_no_child_windows()) {
      return(FILE_NOT_FOUND_RC);
   }
   int was_recording = _macro('s');
   boolean search_backwards = (pos('-', search_options) != 0);
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
      int edit_status = edit('+q +bi 'current_buffer_id);
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
   get_window_id(orig_wid);
   if (0 == _activate_current_search_wid()) {
      return(FILE_NOT_FOUND_RC);
   }
   int prev_mark = _duplicate_selection('');
   int mark_id = 0;
   if (search_range == VSSEARCHRANGE_CURRENT_PROC) {
      mark_id = _get_proc_mark();
      _show_selection(mark_id);
   }
   int was_recording = _macro('s');
   _macro('m', was_recording);
   _macro_call('find', search_text, search_options);
   status = find(search_text, search_options);
   if (!status) {
      if (mark_id) {
         if (mark_id == _duplicate_selection('')) {
            _show_selection(prev_mark);
            _free_selection(mark_id);
         } else {
            _free_selection(prev_mark);
            if (was_recording) {
               _macro_call('_deselect');
            }
         }
      }
   } else {
      _show_selection(prev_mark);
      if (mark_id) {
         _free_selection(mark_id);
      }
   }
   activate_window(orig_wid);
   _macro('m', was_recording);
   return(status);
}

static int _search_next(int search_range)
{
   //say('_search_next');
   int orig_wid;
   int status;
   get_window_id(orig_wid);
   if (0 == _activate_current_search_wid()) {
      return(FILE_NOT_FOUND_RC);
   }
   _macro('m', _macro('s'));
   _macro_call('find_next');
   status = find_next();
   activate_window(orig_wid);
   return(status);
}

static int _search_continue()
{
   if (current_find_mode == VSSEARCHMODE_FIND) {
      if (_findinc.p_value && def_find_close_on_default) {
         if (_tbIsAutoShownWid(p_active_form) || (!_tbIsAutoHidden(p_active_form.p_name) && !tbIsDocked(p_active_form.p_name))) {
            return (1);
         }
      }
   }
   return (0);
}

static int _search(_str search_text, _str search_options, int search_range)
{
   int status;
   boolean list_all = (_findlist_all.p_value != 0) && _findlist_all.p_enabled;
   mou_hour_glass(1);
   status = _mark_all(search_text, search_options, search_range);
   if (!list_all && !_search_continue()) {
      if (!_search_last_found(search_text, search_options, search_range)) {
         old_search_range = search_range;
         if (search_range == VSSEARCHRANGE_ALL_BUFFERS) {
            status = _search_all_buffers(search_text, search_options);
         } else {
            status = _search_current_buffer(search_text, search_options, search_range);
         }
      } else {
         status = _search_next(search_range);
         if (status == STRING_NOT_FOUND_RC && (search_range == VSSEARCHRANGE_ALL_BUFFERS)) {
            status = _search_all_buffers(search_text, search_options);
         }
      }
   } else {
      if (current_find_mode == VSSEARCHMODE_FIND && _findinc.p_value) {
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
   mou_hour_glass(0);
   return(status);
}

static void _search_in_files(_str search_text, _str search_options)
{
   int grep_id = _get_grep_buffer_id();
   int mfflags = 0;
   _str files = '';
   _str wildcards = '';
   _str exclude = '';
   int orig_wid;
   _get_files_list(files, wildcards, exclude);
   if (files != '') {
      if (_mflistfilesonly.p_value)     mfflags |= MFFIND_FILESONLY;
      if (_mfappendgrep.p_value)        mfflags |= MFFIND_APPEND;
      if (_mfmdichild.p_value)          mfflags |= MFFIND_MDICHILD;
      if (!_mfforegroundsearch.p_value) mfflags |= MFFIND_THREADED;
      if (_mfglobal.p_value)            mfflags |= MFFIND_GLOBAL;
      else if (_mfsinglefile.p_value)   mfflags |= MFFIND_SINGLE;

      if (_mfmatchlines.p_enabled && _mfmatchlines.p_value) mfflags |= MFFIND_SINGLELINE;
      if (_mflistmatchonly.p_enabled && _mflistmatchonly.p_value) mfflags |= MFFIND_MATCHONLY;
   }
   get_window_id(orig_wid);
   p_window_id = _mdi.p_child;
   _macro('m', _macro('s'));
   _macro_call('_mffind2',search_text, search_options, files, wildcards, exclude, mfflags, grep_id);
   _mffind2(search_text, search_options, files, wildcards, exclude, mfflags, grep_id);
   activate_window(orig_wid);
   _stop_btn.p_enabled = gbgm_search_state != 0;
}

static void _begin_find()
{
   _mffindNoMore(1);
   _mfrefNoMore(1);
   _str search_text = _findstring.p_text;
   if (search_text :== '') {
      return;
   }
   int status = 0;
   int current_wid = _get_current_search_wid();
   _str search_options = _get_search_options();
   switch (current_find_mode) {
   case VSSEARCHMODE_FIND:
   case VSSEARCHMODE_REPLACE:
      status = _search(search_text, search_options, _get_search_range());
      break;
   case VSSEARCHMODE_FINDINFILES:
      _search_in_files(search_text, search_options);
      break;
   }
   current_wid = _get_current_search_wid();
   _append_save_history();
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
   mark_all_occurences(cw,'WHP,XSC',0,0,0,1,1,0,1);
}

int mark_all_occurences(_str search_text, _str search_options, int search_range, int mfflags, int grep_id, boolean show_hilite, boolean list_all, boolean show_bookmarks,boolean scroll_markup)
{
   int status = 0;
   int num_matches = 0;
   int orig_wid; get_window_id(orig_wid);
   int was_recording = _macro('m', _macro('s'));
   _str new_search_options = search_options;
   SearchResults results;
   _macro_call('mark_all_occurences',search_text,search_options,search_range,mfflags,grep_id,show_hilite,list_all,show_bookmarks,scroll_markup);
   _macro('m', 0);
   if (show_hilite) {
      clear_highlights();
      new_search_options = new_search_options:+'#';
   }
   if ( scroll_markup ) {
      clear_scroll_highlights();
      new_search_options = new_search_options:+'%';
   }
   typeless s1, s2, s3, s4, s5; save_search(s1, s2, s3, s4, s5);
   if (search_range == VSSEARCHRANGE_ALL_BUFFERS) {
      activate_window(VSWID_HIDDEN);
      _safe_hidden_window();
      int orig_buf_id = p_buf_id;
      int first_buf_id = _mdi.p_child.p_buf_id;
      if (list_all) {
         topline := se.search.generate_search_summary(search_text, search_options, "", mfflags, "", "");
         results.initialize(topline, search_text, mfflags, grep_id);
      }
      p_buf_id = first_buf_id;
      for (;;) {
         if (!_isGrepBuffer(p_buf_name)) {
            num_matches += _find_all(search_text, new_search_options, show_bookmarks, list_all, &results);
         }
         _next_buffer('nr');
         if (p_buf_id == first_buf_id) {
            break;
         }
      }
      p_buf_id = orig_buf_id;
   } else {
      if (list_all && _isGrepBuffer(p_buf_name)) {
         _message_box("Cannot perform operation in search results window.");
         list_all = false;
      } else {
         if (list_all) {
            topline := se.search.generate_search_summary(search_text, search_options, "", mfflags, "", "");
            results.initialize(topline, search_text, mfflags, grep_id);
         }
         int prev_mark = _duplicate_selection('');
         int mark_id = 0;
         if (search_range == VSSEARCHRANGE_CURRENT_PROC) {
            mark_id = _get_proc_mark();
            _show_selection(mark_id);
         }
         num_matches = _find_all(search_text, new_search_options, show_bookmarks, list_all, &results);
         if (old_search_mark != '') {
            _free_selection(old_search_mark);
            old_search_mark = '';
         }
         if (mark_id) {
            old_search_mark = mark_id;
         }
         _show_selection(prev_mark);
      }
   }
   save_search(old_search_string, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
   restore_search(s1, s2, s3, s4, s5);
   if (num_matches) {
      message('List all, "'search_text'", '_get_search_range_label(search_range)' found 'num_matches' occurrences');
      if (show_bookmarks) {
         activate_bookmarks();
         updateBookmarksToolWindow();
      }
      status = 0;
   } else {
      message('No occurrences found.');
      status = STRING_NOT_FOUND_RC;
   }
   if (show_hilite) {
      old_search_flags &= (~VSSEARCHFLAG_FINDHILIGHT);  // don't carrying highlight to find-next
   }
   if (list_all) {
      results.done('Total found: ':+num_matches);
      results.showResults();
      orig_wid._set_focus(); // may have lost focus to search results
   }
   _macro('m', was_recording);
   activate_window(orig_wid);
   return (status);
}


static int _mark_all(_str search_text, _str search_options, int search_range)
{
   int orig_wid; get_window_id(orig_wid);
   boolean show_hilite = (_findmark_all.p_value != 0) && _findmark_all.p_enabled;
   boolean show_bookmarks = (_findbookmark_all.p_value != 0) && _findbookmark_all.p_enabled;
   boolean list_all = (_findlist_all.p_value != 0) && _findlist_all.p_enabled;
   if (!show_hilite && !show_bookmarks && !list_all) {
      return (0);
   }
   boolean scroll_markup = show_hilite || list_all;
   int mfflags = 0;
   int grep_id = 0;
   if (list_all) {
      if (_mfappendgrep.p_value)        mfflags |= MFFIND_APPEND;
      if (_mfmdichild.p_value)          mfflags |= MFFIND_MDICHILD;
      if (_mfmatchlines.p_enabled && _mfmatchlines.p_value) mfflags |= MFFIND_SINGLELINE;
      if (_mflistmatchonly.p_enabled &&_mflistmatchonly.p_value) mfflags |= MFFIND_MATCHONLY;
      grep_id = _get_grep_buffer_id();
   }

   if (0 == _activate_current_search_wid()) {
      return (STRING_NOT_FOUND_RC);
   }

   int status = mark_all_occurences(search_text,search_options,search_range,mfflags,grep_id,show_hilite,list_all,show_bookmarks,scroll_markup);
   activate_window(orig_wid);
   return (status);
}

static int _find_all(_str search_text = '', _str search_options = '', boolean addBookmark = false, boolean listAll = false, SearchResults* results = null)
{
   if (search_text:=='') {
      return 0;
   }
   int num_bookmarks = 0;
   int num_matches = 0;
   int last_line = -1;

   if (listAll) {
      _SetAllOldLineNumbers();
   }
   typeless p; save_pos(p);
   boolean search_mark = (pos('m', search_options, 1, 'I') != 0);
   if (search_mark) {
      _begin_select(); _begin_line();
   } else {
      top();
   }
   int status = search(search_text, 'xv,@'search_options'<+');
   if (!status) {
      while (!status) {
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
         if (listAll && results != null) {
            results->insertCurrentMatch();
         }
         ++num_matches;
         _MaybeUnhideLine();
         status = repeat_search();
      }
   }
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
   }
   save_search(old_search_string, old_search_flags, old_word_re, null, old_search_flags2);
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
      is_state.orig_mark = _duplicate_selection('');
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
         is_state.search_mark = 0;
      }
   }
}

static void _begin_incremental_search()
{
   _str search_text = _findstring.p_text;
   _str search_options = _get_search_options();
   int search_range = _get_search_range();
   int search_wid = _get_current_search_wid();
   int status;
   int orig_wid;
   get_window_id(orig_wid);
   if (0 == _activate_current_search_wid()) {
      return;
   }
   _init_incremental_search(search_range);
   _str prev_mark = _duplicate_selection('');
   restore_pos(is_state.start_pos);
   if (is_state.search_mark) {
      _show_selection(is_state.search_mark);
   }
   status = _buffer_incremental_search(search_text, search_options);
   if (!status) {
      _str selection_markid = _alloc_selection();
      _MaybeUnhideLine(selection_markid);
      p_LCHasCursor = 0;
      if (def_leave_selected) {
         _show_selection(selection_markid);
         if (prev_mark != is_state.orig_mark) {
            _free_selection(prev_mark);
         }
      } else {
         _show_selection(prev_mark);
         _free_selection(selection_markid);
      }
   } else {
      if (search_text :== '') {
         restore_pos(is_state.start_pos);
         if (def_leave_selected) {
            _show_selection(is_state.orig_mark);
            if (prev_mark != is_state.orig_mark) {
               _free_selection(prev_mark);
            }
         } else {
            _show_selection(prev_mark);
         }
      } else {
         restore_pos(is_state.last_pos);
         _show_selection(prev_mark);
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

static boolean _search_incremental_last_found_status()
{
   return ((current_find_mode == VSSEARCHMODE_FIND) && (_findinc.p_value) && (is_state.last_status == 0));
}

void _findstring.on_change(int reason)
{
   if (ignore_change) {
      return;
   }
   if (current_find_mode == VSSEARCHMODE_FIND && _findinc.p_value) {
      _begin_incremental_search();
   } else {
      _findstring._show_textbox_error_color(false);
   }
}

void _findstring.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      if (p_user == '') {
         _lbclear();
         _retrieve_list();
         p_user = 1;
      }
   }
}

void _find_btn.lbutton_up()
{
   _findstring._begin_find();
}

/*** replace ***/
static int _buffer_replace(_str search_text, _str search_options, _str replace_text, boolean show_diff, int& num_replaced, boolean multifile = false, SearchResults* results = null)
{
   if (!p_HasBuffer || (p_window_flags & HIDE_WINDOW_OVERLAP) || !p_mdi_child) {
      _message_box(get_message(VSRC_FF_NO_FILES_SELECTED));
      return(FILE_NOT_FOUND_RC);
   }
   int temp_view;
   int orig_view;
   int old_mark = _duplicate_selection('');
   int temp_mark = 0;
   if (show_diff) {
      boolean alreadyExists = true;
      int status = _open_temp_view(p_buf_name, temp_view, orig_view, "+d", alreadyExists, false, true);
      if (status < 0) {
         return(FILE_NOT_FOUND_RC);
      }
      if (pos('M', upcase(search_options))) {
         temp_mark = _clone_selection(orig_view, old_mark);
         _show_selection(temp_mark);
      }
   }

   int status = gui_replace2(search_text, replace_text, search_options, false, multifile, results, show_diff);
   num_replaced += _Nofchanges;
   if (show_diff) {
      if (_Nofchanges > 0) {
         replace_diff_add_file(p_buf_name, p_encoding);
         replace_diff_set_modified_file(p_window_id);
      }
      _show_selection(old_mark);
      if (temp_mark) {
         _free_selection(temp_mark);
      }
      _delete_temp_view(temp_view);
      activate_window(orig_view);
   }
   return(status);
}

static int _replace_all_buffers(_str search_text, _str search_options, _str replace_text, boolean show_diff, SearchResults* results, int& num_replaced)
{
   if (_no_child_windows()) {
      return(FILE_NOT_FOUND_RC);
   }
   int all_status = STRING_NOT_FOUND_RC;
   int status;
   int orig_wid;
   int replace_go = pos('*', search_options);
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
      edit('+q +bi 'buffers[i]);
      typeless p; save_pos(p);
      if (i > 0) {
         top();      // start buffer at top, this is less confusing when switching buffers
      }
      status = _buffer_replace(search_text, search_options, replace_text, show_diff, num_replaced, (buffers._length() > 1), results);
      num_replaced += _Nofchanges;
      if (status == COMMAND_CANCELLED_RC) {
         break;
      }
      restore_pos(p);
      if (!status ||_Nofchanges) {
         all_status = 0;
      }
   }
   edit('+q +bi 'first_buf_id);
   activate_window(orig_wid);
   return(all_status);
}

int replace_buffer_text(_str search_text, _str search_options, _str replace_text, int search_range, boolean show_diff, boolean show_highlights, boolean show_results = false, int mfflags = 0, int grep_id = 0)
{
   int num_replaced = 0;
   int status = 0;
   if (show_diff) {
      if (replace_diff_begin())
         return (0);
   }
   if (show_highlights) {
      clear_highlights();
   }
   SearchResults results;
   if (show_results) {
      topline := se.search.generate_search_summary(search_text, search_options, "", mfflags, "", "", replace_text);
      results.initialize(topline, search_text, mfflags, grep_id);
   }
   if(select_active2() && (def_mfsearch_init_flags & MFSEARCH_INIT_SELECTION)) {
      _begin_select();
   }
   _macro_call('replace_buffer_text', search_text, search_options, replace_text, search_range, show_diff, show_highlights, show_results, mfflags, grep_id);
   old_search_range = search_range;
   if (search_range == VSSEARCHRANGE_ALL_BUFFERS) {
      status = _replace_all_buffers(search_text, search_options, replace_text, show_diff, (show_results)?&results:null, num_replaced);
   } else {
      typeless orig_mark = _duplicate_selection('');
      int mark_id = 0;
      if (search_range == VSSEARCHRANGE_CURRENT_PROC) {
         mark_id = _get_proc_mark();
         _show_selection(mark_id);
      }
      status = _buffer_replace(search_text, search_options, replace_text, show_diff, num_replaced, false, (show_results)?&results:null);
      if (mark_id) {
         _show_selection(orig_mark);
         _free_selection(mark_id);
         _macro_call('_deselect');
      }
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

static void _replace(_str search_text, _str search_options, _str replace_text, int search_range, boolean show_diff, boolean show_highlights, boolean show_results = false, int mfflags = 0, int grep_id = 0)
{
   int status;
   int orig_wid;
   get_window_id(orig_wid);
   if (0 == _activate_current_search_wid()) {
      return;
   }
   _macro('m', _macro('s'));
   status = replace_buffer_text(search_text, search_options, replace_text, search_range, show_diff, show_highlights, show_results, mfflags, grep_id);
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
                              int mfflags = 0, int grep_id = 0, boolean show_diff = false)
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
      if (p_user == '') {
         _lbclear();
         _retrieve_list();
         p_user = 1;
      }
   }
}

static void _begin_replace(_str options = '', boolean show_diff = false)
{
   int window_id;
   int form_id = p_active_form;

   // gather search/replace parameters
   _str search_text = _findstring.p_text;
   _str replace_text = _replacestring.p_text;
   _str search_options = _get_search_options():+options;
   int search_range = _get_search_range();
   _str files = '';
   _str wildcards = '';
   _str exclude = '';
   int grep_id = 0;
   int mfflags = 0;
   boolean show_highlights = false;
   boolean show_results = false;

   switch (current_find_mode) {
   case VSSEARCHMODE_REPLACE:
      show_highlights = (pos('$', search_options) != 0);
      show_results = (_replacelist.p_enabled && _replacelist.p_value);
      if (show_results) {
         if (_mfappendgrep.p_value)        mfflags |= MFFIND_APPEND;
         if (_mfmdichild.p_value)          mfflags |= MFFIND_MDICHILD;
         if (_mfmatchlines.p_enabled && _mfmatchlines.p_value) mfflags |= MFFIND_SINGLELINE;
         if (_mflistmatchonly.p_enabled && _mflistmatchonly.p_value) mfflags |= MFFIND_MATCHONLY;
         grep_id = _get_grep_buffer_id();
      }
      break;
   case VSSEARCHMODE_REPLACEINFILES:
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
      }
      break;
   }

   boolean unhide_toolwindow = false;
   get_window_id(window_id);
   // hide tool window, it may be in the way
   if (pos('*', options) == 0) {
      ignore_switchbuf = true;
      if (_tbIsAutoShownWid(form_id)) {
         _tbAutoHide(form_id);
         activate_window(window_id);
      } else if (!tbIsWidDocked(form_id)) {
#if __UNIX__
         if (isEclipsePlugin()) {
            if (p_active_form.p_parent._isEditorCtl()) {
               p_active_form.p_visible=false;
            } else {
               p_active_form.p_parent.p_visible=false;
            }
         } else {
            p_active_form.p_parent.p_visible= false;
         }
#else
         p_active_form.p_visible = false;
#endif
         unhide_toolwindow = true;
      }
      ignore_switchbuf = false;
   }

   _mffindNoMore(1);
   _mfrefNoMore(1);
   ignore_change = true;
   switch (current_find_mode) {
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
      if (!tbIsWidDocked(form_id)) {
#if __UNIX__
         if (isEclipsePlugin()) {
            if (p_active_form.p_parent._isEditorCtl()) {
               p_active_form.p_visible=true;
            } else {
               p_active_form.p_parent.p_visible=true;
            }
         } else {
            p_active_form.p_parent.p_visible = true;
         }
#else
         p_active_form.p_visible = true;
#endif
      }
   }

   int current_wid = _get_current_search_wid();
   _append_save_history();
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
   if ((current_find_mode == VSSEARCHMODE_FIND) && _findinc.p_value) {
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
   _mfhook.call_event(CHANGE_SELECTED, current_find_mode == VSSEARCHMODE_FINDINFILES, _mfhook, LBUTTON_UP, '');
}

/*** stop ***/
void _stop_btn.lbutton_up()
{
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
      _stop_btn.p_enabled = gbgm_search_state != 0;
      _mfglobal.p_enabled = _mfsinglefile.p_enabled = _mfprompted.p_enabled = ((current_find_mode == VSSEARCHMODE_FINDINFILES) && (_mfforegroundsearch.p_value && info));
   }
}

void _tbFindUpdateBGSearchStatus()
{
   int wid = _find_object("_tbfind_form", 'N');
   if (wid) {
      wid._mfhook.call_event(CHANGE_SELECTED, current_find_mode==VSSEARCHMODE_FINDINFILES, wid._mfhook,LBUTTON_UP, '');
   }
}

static void _update_list_all_occurrences()
{
   _update_search_options();
   if (current_find_mode == VSSEARCHMODE_FIND) {
      _results_frame.p_visible = (_findlist_all.p_value != 0 && _findlist_all.p_enabled);
      _show_results_options();
      _resize_frame_heights(true);
   }
}

void _findlist_all.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   if (current_find_mode == VSSEARCHMODE_FIND) {
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
   if (current_find_mode == VSSEARCHMODE_REPLACE) {
      _results_frame.p_visible = (_replacelist.p_value != 0 && _replacelist.p_enabled);
      _show_results_options();
      _resize_frame_heights(true);
   }
}

void _replacelist.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   if (current_find_mode == VSSEARCHMODE_REPLACE) {
      _update_replace_list_all();
   }
}

/*** color coded search ***/
#define COLOR2CHECKBOXTAB "OKNSCPL1234FA"
static _str gcolortab[] = {
   "Other",
   "Keyword",
   "Number",
   "String",
   "Comment",
   "Preprocessing",
   "Line Number",
   "Symbol 1",
   "Symbol 2",
   "Symbol 3",
   "Symbol 4",
   "Function",
   "Attribute",
};

void _findcolor.lbutton_up()
{
   _str result = show("-modal _ccsearch_form", _findcoloroptions.p_text);
   if (result != '') {
      _findcoloroptions.p_text = _param1;
      _findstring._set_focus();
   }
}

void _findcoloroptions.on_change()
{
   _str IncludeChars, ExcludeChars;
   _str result = "";
   int i, j;
   parse p_text with IncludeChars','ExcludeChars',';
   result = "";
   for (i = 2; i <= length(IncludeChars); ++i) {
      j = pos(substr(IncludeChars, i, 1), COLOR2CHECKBOXTAB, 1, 'I');
      if (j) {
         if (result == '') {
            result = gcolortab[j-1];
         } else {
            result = result:+', 'gcolortab[j-1];
         }
      }
   }
   for (i  = 2; i <= length(ExcludeChars); ++i) {
      j = pos(substr(ExcludeChars, i, 1), COLOR2CHECKBOXTAB, 1, 'I');
      if (j) {
         if (result == '') {
            result = get_message(VSRC_FF_NOT)' 'gcolortab[j-1];
         } else {
            result = result:+', 'get_message(VSRC_FF_NOT)' 'gcolortab[j-1];
         }
      }
   }
   _findcolorlabel.p_caption = "Colors: " :+ ((result == "") ? "None" : result);
   if (result == "") {
      _findcolorlabel.p_enabled = false;
   } else {
      _findcolorlabel.p_enabled = true;
   }
   _findcolorlabel.p_width = _findcolorlabel.p_parent.p_width - (2*_findcolorlabel.p_x);
   if (ignore_change) {
      return;
   }
   _show_search_options();
   _resize_frame_heights(true);
}

/*** _findfiles ***/
static boolean _mfallow_prjfiles()
{
   if (_project_name != '') {
      _str result = '';
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

static boolean _mfallow_workspacefiles()
{
   int orig_view_id = p_window_id;
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

static boolean _mffind_have_buffers()
{
   _str array[];
   _tbfind_list_buffers(array, false);
   return(array._length() != 0);
}

static boolean _mffind_buffer_has_directory()
{
   if (!_no_child_windows()) {
      _str name = _mdi.p_child.p_buf_name;
      if (!(_mdi.p_child.p_buf_flags & VSBUFFLAG_HIDDEN)&& name != '' && name != '.process' && !_isGrepBuffer(name)) {
         return (true);
      }
   }
   return (false);
}

static boolean _mfallow_listprojectfiles()
{
   int orig_view_id = p_window_id;
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

static boolean _mffind_disable_filetypes()
{
   _str curfile, list;
   parse _findfiles.p_text with curfile ';' list;
   while (curfile != '') {
      if (curfile != MFFIND_BUFFER && curfile != MFFIND_BUFFERS) {
         return(false);
      }
      parse list with curfile ';' list;
   }
   return(true);
}

static boolean _mffind_disable_subfolders()
{
   _str curfile, list;
   parse _findfiles.p_text with curfile ';' list;
   while (curfile != '') {
      if (curfile == MFFIND_BUFFER || curfile == MFFIND_BUFFERS || curfile == MFFIND_PROJECT_FILES || curfile == MFFIND_WORKSPACE_FILES) {
         parse list with curfile ';' list;
      } else {
         return (true);
      }
   }
   return(false);
}

static void _tbfind_list_buffers(_str (&array)[], boolean sort)
{
   array._makeempty();
   // Fill the buffer list
   _str name = buf_match('', 1);
   for (;;) {
      if (rc) break;
      if ((name != '') && (name != '.process') && (!_isGrepBuffer(name))) {
         array[array._length()] = field(_strip_filename(name, 'P'), 13)'<'_strip_filename(name, 'N')'>';
      }
      name = buf_match('', 0);
   }
   if (sort) {
      array._sort();
   }
}

static boolean _mffind_last_sorted = false;

static _str _get_buflist_name(_str result)
{
   if (_isno_name(result)) {
      return(result);
   }
   _str name = "";
   _str path = "";
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
            _sellistok.p_enabled = 1;
         }
      } else {
         _sellistok.p_enabled = 0;
      }
      return('');
   }
   if (reason == SL_ONDEFAULT) {  // Enter callback?
      /* Save all files. */
      result='';
      int status=_sellist._lbfind_selected(1);
      while (!status) {
         _str text = _sellist._lbget_text();
         _str name = _get_buflist_name(text);
         if (result == '') {
            result = name;
         } else {
            int newsize = length(result)+ length(text)+ 1000;
            if (newsize > _default_option(VSOPTION_WARNING_STRING_LENGTH)) {
               _default_option(VSOPTION_WARNING_STRING_LENGTH, newsize);
            }
            strappend(result, ';'name);
         }
         status = _sellist._lbfind_selected(0);
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
      int status=_sellist._lbfind_selected(1);
      while (!status) {
         _str text=_sellist._lbget_text();
         selected:[text]=1;
         status = _sellist._lbfind_selected(0);
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
      _str prjname = '';
      parse result with prjname "\n" result;
      if (append != '') {
         append = append:+def_mffind_pathsep;
      }
      append = append:+"<Project: ":+prjname:+">";
   }
}

_command void mffind_add(_str cmdline = '') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _macro_delete_line();
   _str action, append;
   parse cmdline with action append;
   int wid = p_prev;
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
   default:
      {
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
   }
   if (result == '') {
      return;
   }
   _str line = wid.p_text;
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
      line = strip(line, 'T'):+def_mffind_pathsep:+result;
      result = def_mffind_pathsep:+result;
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
      return(_mffind_have_buffers() ? MF_ENABLED : MF_GRAYED);
   default:
      return(MF_ENABLED);
   }
}

static void _init_files_list(boolean forceRefresh = false)
{
   if (forceRefresh) p_user = '';
   if (p_user == '') {
      //p_cb_list_box._lbdeselect_all();
      _lbclear();
      _retrieve_list();
      _str cwd = getcwd();
      if (last_char(cwd) != FILESEP) {
         cwd = cwd:+FILESEP;
      }
      if (_project_name != '') {
         _lbbottom();
         _str WorkspacePath = _strip_filename(_workspace_filename, 'N');
         _lbadd_item_no_dupe(WorkspacePath, 'E', LBADD_BOTTOM);
         _str ProjectPath = _parse_project_command('%rw', '', _project_name, '');
         if (!file_eq(WorkspacePath, ProjectPath)) {
            _lbadd_item_no_dupe(ProjectPath, 'E', LBADD_BOTTOM);
         }
         if (!file_eq(WorkspacePath, cwd) && !file_eq(ProjectPath, cwd)) {
            _lbadd_item_no_dupe(cwd, 'E', LBADD_BOTTOM);
         }
         _lbbottom();
         if (_mffind_have_buffers()) {
            _lbadd_item(MFFIND_BUFFER);
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
         _lbadd_item_no_dupe(cwd, 'E', LBADD_BOTTOM);
         _lbbottom();
         if (_mffind_have_buffers()) {
            _lbadd_item(MFFIND_BUFFER);
            _lbadd_item(MFFIND_BUFFERS);
         }
         if (_mffind_buffer_has_directory()) {
            _lbadd_item(MFFIND_BUFFER_DIR);
         }
      }
      p_user = 1;
   }
   if (p_text == '') {
      _lbtop();
      p_text = _lbget_text();
   }
   boolean has_buffers_only = _mffind_disable_filetypes();
   _findfiletypes.p_enabled = !has_buffers_only;
   _findexclude.p_enabled = !has_buffers_only;
}

void _findfiles.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      _findfiles._init_files_list();
   }
}

void _findfiles.on_change(int reason)
{
   _mfhook.call_event(CHANGE_SELECTED, true, _mfhook, LBUTTON_UP, '');
   boolean buffers_only = _mffind_disable_filetypes();
   _findfiletypes.p_enabled = !buffers_only;
   _findexclude.p_enabled = !buffers_only;
   _findsubfolder.p_enabled = _mffind_disable_subfolders();
}

void _prjopen_tbfind_form()
{
   int files_id = _find_object("_tbfind_form._findfiles", "n");
   if (files_id == 0) {
      return;
   }
   files_id.p_user = ''; // force refresh
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
   if (current_find_mode == VSSEARCHMODE_FIND && _findinc.p_value) {
      int search_range = _get_search_range();
      int search_wid = _get_current_search_wid();
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
   _update_button_state();
}

void _findbuffer.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      if (_tbIsAutoShownWid(p_active_form) || tbIsDocked(p_active_form.p_name)) {
         int window_id = _get_current_search_wid();
         if (window_id && window_id._isEditorCtl(false)) {
            _init_buffers_list(window_id);
         }
      }
   }
}

static void _init_buffer_range(int search_range)
{
   int wid = _find_object("_tbfind_form", 'N');
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
      default:                               text = SEARCH_IN_CURRENT_BUFFER; break;
      }
      wid._findbuffer._cbset_text(text);
   }
}

/*** File Types ***/

static void _init_findfiletypes(boolean forceRefresh = false)
{
   if (forceRefresh) _findfiletypes.p_user = '';
   if (_findfiletypes.p_user == '') {
      _init_filters();
      _findfiletypes.p_user = 1; // Indicate that retrieve list has been done
   }
}

static void _init_findfiletypes_ext()
{
   int search_wid = _get_current_search_wid();
   _str wildcard = p_text;
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
   p_text = wildcard;
}

void _findfiletypes.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      _init_findfiletypes();
   }
}

/*** Exclude Files ***/
void _findexclude.on_drop_down(int reason)
{
   if (reason == DROP_DOWN) {
      if (p_user == '') {
         _lbclear();
         _retrieve_list();
         p_user = 1;
      }
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
}

void _mflistmatchonly.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   _mfmatchlines.p_enabled = !_mflistmatchonly.p_value && (!_mflistfilesonly.p_visible || !_mflistfilesonly.p_value);
}

/*** use re types ***/
void _init_re_type(int retype)
{
   if (retype) {
      if (retype == VSSEARCHFLAG_UNIXRE) {
         p_text = RE_TYPE_UNIX_STRING;
      } else if (retype == VSSEARCHFLAG_BRIEFRE) {
         p_text = RE_TYPE_BRIEF_STRING;
      } else if (retype == VSSEARCHFLAG_RE) {
         p_text = RE_TYPE_SLICKEDIT_STRING;
      } else if (retype == VSSEARCHFLAG_WILDCARDRE) {
         p_text = RE_TYPE_WILDCARD_STRING;
      } else if (retype == VSSEARCHFLAG_PERLRE) {
         p_text = RE_TYPE_PERL_STRING;
      }
      p_enabled = true;
   } else if (_findre.p_value == 0) {
      p_enabled = false;
   }
}

void _findre_type.on_change(int reason)
{
   _refresh_incremental_search();
}

void _findre.lbutton_up()
{
   _findre_type.p_enabled = _re_button.p_enabled = _replace_re_button.p_enabled = _findre.p_value ? true : false;
   _refresh_incremental_search();
}

void _search_opt_button.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   if (p_user == p_value) {
      return;
   }
   _show_search_options();
   _resize_frame_heights(true);
   p_user = p_value;
}

void _result_opt_button.lbutton_up()
{
   if (ignore_change) {
      return;
   }
   if (p_user == p_value) {
      return;
   }
   _show_results_options();
   _resize_frame_heights(true);
   p_user = p_value;
}

/* advanced options */
static void _toggle_def_find_file_attr_flags(_str option)
{
   _str rest, arg1, out = "";
   boolean append_option = true;
   parse def_find_file_attr_flags with arg1 rest;
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
   def_find_file_attr_flags = out;
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

int _OnUpdate_mffind_advanced(CMDUI cmdui,int target_wid,_str command)
{
   _str cmd, action, append;
   parse command with cmd action append;
   switch (lowcase(action)) {
   case '+h':
   case '+s':
      return((pos(action, def_find_file_attr_flags, 1) != 0) ? MF_ENABLED|MF_CHECKED : MF_ENABLED);
   default:
      return(MF_ENABLED);
   }
}

_command void mffind_advanced(_str cmdline = '') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _macro_delete_line();
   _str action, append;
   parse cmdline with action append;
   _str result;
   switch (lowcase(action)) {
   case '+h':
   case '+s':
      _toggle_def_find_file_attr_flags(action);
      return;
   }
}

/*** Search and Replace Expressions ***/
#define SEARCH_EXPRESSIONS_FILENAME 'searches.xml'
static int _saved_searches_handle;

static int _open_saved_search_index()
{
   if (_saved_searches_handle < 0) {
      int status;
      _str filename = _ConfigPath() :+ SEARCH_EXPRESSIONS_FILENAME;
      int handle = _xmlcfg_open(filename, status, VSXMLCFG_OPEN_REFCOUNT);
      if (handle < 0 && status) {
         handle = _xmlcfg_create(filename, VSENCODING_UTF8);
         _xmlcfg_add(handle, TREE_ROOT_INDEX, "Searches", VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      }
      _saved_searches_handle = handle;
   }
   return (_saved_searches_handle);
}

static void _close_saved_search_index()
{
   if (_saved_searches_handle < 0) {
      return;
   }
   if (_xmlcfg_get_modify(_saved_searches_handle)) {
      _xmlcfg_save(_saved_searches_handle, -1, VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR, null, VSENCODING_UTF8);
   }
   _xmlcfg_close(_saved_searches_handle);
   _saved_searches_handle = -1;
}

static void _write_saved_search(_str name,
                                _str search_string, _str replace_string,
                                int search_flags, _str color_flags,
                                boolean multifile, _str file_types, _str file_excludes)
{
   int handle = _open_saved_search_index();
   if (handle < 0) {
      return;
   }
   int parent_node = _xmlcfg_find_simple(handle, '//Searches', TREE_ROOT_INDEX );
   int node = _xmlcfg_add(handle, parent_node, "State", VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   if (node > 0) {
      _xmlcfg_add_attribute(handle, node, "Name", name);
      _xmlcfg_add_attribute(handle, node, "Search", search_string);
      _xmlcfg_add_attribute(handle, node, "Replace", replace_string);
      _xmlcfg_add_attribute(handle, node, "Flags", search_flags);
      _xmlcfg_add_attribute(handle, node, "Colors", color_flags);
      if (multifile) {
         int file_node = _xmlcfg_add(handle, node, "Files", VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
         if (file_node > 0) {
            _xmlcfg_add_attribute(handle, file_node, "Types", file_types);
            _xmlcfg_add_attribute(handle, file_node, "Excludes", file_excludes);
         }
      }
   }
}

static void _read_saved_search(int node, _str& name,
                                _str& search_string, _str& replace_string,
                                int& search_flags, _str& color_flags,
                                boolean& multifile, _str& file_types, _str& file_excludes)
{
   int handle = _open_saved_search_index();
   if (handle < 0) {
      return;
   }
   name = _xmlcfg_get_attribute(handle, node, "Name", 0);
   search_string = _xmlcfg_get_attribute(handle, node, "Search", 0);
   replace_string = _xmlcfg_get_attribute(handle, node, "Replace", 0);
   search_flags = _xmlcfg_get_attribute(handle, node, "Flags", 0);
   color_flags = _xmlcfg_get_attribute(handle, node, "Colors", 0);
   int file_index = _xmlcfg_find_child_with_name(handle, node, "Files");
   if (file_index < 0) {
      multifile = false;
      file_types = "";
      file_excludes = "";
   } else {
      multifile = true;
      file_types = _xmlcfg_get_attribute(handle, file_index, "Types");
      file_excludes = _xmlcfg_get_attribute(handle, file_index, "Excludes");
   }
}

static void _delete_saved_search(_str node)
{
   int handle = _open_saved_search_index();
   if (handle < 0) {
      return;
   }
   if (node > 0) {
      _xmlcfg_delete(handle, (typeless)node);
   }
}

static int _find_saved_search(_str name)
{
   int handle = _open_saved_search_index();
   if (handle < 0) {
      return (-1);
   }
   return _xmlcfg_find_simple(handle, '//Searches/State[@Name="' :+ (name) :+ '"]', TREE_ROOT_INDEX);
}

static void _get_saved_search_names(_str (&array)[], boolean needs_replace = false, boolean needs_files = false)
{
   int handle = _open_saved_search_index();
   if (handle < 0) {
      return;
   }
   int i;
   typeless nodes[];
   _xmlcfg_find_simple_array(handle, '//Searches/State', nodes);
   for (i = 0; i < nodes._length(); ++i) {
      int node = nodes[i];
      if (needs_replace && (_xmlcfg_get_attribute(handle, node, "Replace", 0) :== "")) {
         continue;
      }
      if (needs_files && (_xmlcfg_find_child_with_name(handle, node, "Files") < 0)) {
         continue;
      }
      array[array._length()] = _xmlcfg_get_attribute(handle, node, "Name", 0);
   }
}

static void _get_saved_search_nodes(int (&array)[], boolean needs_replace = false, boolean needs_files = false)
{
   int handle = _open_saved_search_index();
   if (handle < 0) {
      return;
   }
   int i;
   typeless nodes[];
   _xmlcfg_find_simple_array(handle, '//Searches/State', nodes);
   for (i = 0; i < nodes._length(); ++i) {
      int node = nodes[i];
      if (needs_replace && (_xmlcfg_get_attribute(handle, node, "Replace", 0) :== "")) {
         continue;
      }
      if (needs_files && (_xmlcfg_find_child_with_name(handle, node, "Files") < 0)) {
         continue;
      }
      array[array._length()] = node;
   }
}

static int _get_saved_search_count()
{
   int handle = _open_saved_search_index();
   if (handle < 0) {
      return (0);
   }
   typeless nodes[];
   _xmlcfg_find_simple_array(handle, '//Searches/State', nodes);
   return (nodes._length());
}

static _str _remove_saved_search_callback(int reason, var result, _str key)
{
   _nocheck _control _sellist;
   _nocheck _control _sellistok;
   // Initialize or change selected
   if (reason == SL_ONINIT || reason == SL_ONSELECT) {
      if (_sellist.p_Nofselected > 0) {
         if (!_sellistok.p_enabled) {
            _sellistok.p_enabled = 1;
         }
      } else {
         _sellistok.p_enabled = 0;
      }
      return('');
   }
   if (reason == SL_ONDEFAULT) {
      int nodes[];
      _get_saved_search_nodes(nodes);
      int status = _sellist._lbfind_selected(1);
      while (!status) {
         int line = _sellist.p_line - 1;
         _delete_saved_search(nodes[line]);
         status = _sellist._lbfind_selected(0);
      }
      return(1);
   }
   if (reason != SL_ONUSERBUTTON && reason != SL_ONLISTKEY) {
      return('');
   }
   if (key == 4) { /* Invert */
      _str junk;
      _sellist._lbinvert();
      _remove_saved_search_callback(SL_ONSELECT, junk, '');
      return('');
   }
   if (key == 5) { /* Clear */
      _str junk;
      _sellist._lbdeselect_all();
      _remove_saved_search_callback(SL_ONSELECT, junk,'');
      return('');
   }
   return('');
}

static void _remove_saved_search()
{
   _str array[];
   _get_saved_search_names(array);
   _str buttons = nls('&Remove,&Invert,&Clear');
   show('_sellist_form -mdi -modal',
        "Remove Saved Search",
        SL_ALLOWMULTISELECT|SL_NOISEARCH|
        SL_DEFAULTCALLBACK,
        array,
        buttons,
        "Remove Saved Search",       // help item name
        '',                         // font
        _remove_saved_search_callback       // Call back function
       );
   _close_saved_search_index();
}

static void _save_current_search()
{
   _str searchstr = _findstring.p_text;
   _str replacestr = ((current_find_mode == VSSEARCHMODE_REPLACE) ||
                      (current_find_mode == VSSEARCHMODE_REPLACEINFILES)) ? _replacestring.p_text : "";
   typeless result = show('-modal _textbox_form',
                          "New Saved Search Expression Name",   // Form caption
                          0,  //flags
                          "", //use default textbox width
                          "", //Help item.
                          "", //Buttons and captions
                          "", //Retrieve Name
                          'New Saved Search Expression Name:'searchstr );
   if (result == "") {
      return;
   }
   _str array[];
   _get_saved_search_names(array);
   int len = array._length();
   int n;
   for (n = 0; n < len; ++n) {
      if (_param1 == array[n]) {
         break;
      }
   }
   if (n < len) {
      result = _message_box(nls("Saved Search name already exists.  Would you like to replace it?"), '', MB_YESNO|MB_ICONQUESTION);
      if (result == IDNO) {
         return;
      }
      if (result == IDYES) {
         int nodes[];
         _get_saved_search_nodes(nodes);
         _delete_saved_search(nodes[n]);
      }
   }
   boolean multifile = false;
   _str file_types = "", file_excludes = "";
   if (current_find_mode == VSSEARCHMODE_FINDINFILES || current_find_mode == VSSEARCHMODE_REPLACEINFILES) {
      multifile = true;
      file_types = _findfiletypes.p_text;
      file_excludes = _findexclude.p_text;
   }
   _write_saved_search(_param1, searchstr, replacestr, _get_search_flags(), _findcoloroptions.p_text, multifile, file_types, file_excludes);
   _close_saved_search_index();
}


static void _apply_saved_search(int index)
{
   int nodes[];
   _get_saved_search_nodes(nodes);
   _str name, search_string, replace_string, color_flags, file_types, file_excludes;
   int search_flags;
   boolean multifile;
   _read_saved_search(nodes[index], name, search_string, replace_string, search_flags, color_flags, multifile, file_types, file_excludes);
   _findstring.p_text = search_string;
   _findstring.p_sel_start = 1;
   _findstring._refresh_scroll();
   _findstring._set_sel(1, length(_findstring.p_text)+1);
   _replacestring.p_text = replace_string;
   _init_options(search_flags);
   if (multifile) {
      _findfiletypes.p_text = file_types;
      _findexclude.p_text =  file_excludes;
   }
   _findcoloroptions.p_text = color_flags;
}

int _OnUpdate_tbfind_expressions_menu(CMDUI cmdui, int target_wid, _str command)
{
   _str cmd, action, type, id;
   int mode = current_find_mode;
   boolean bInReplace = (mode == VSSEARCHMODE_REPLACE || mode == VSSEARCHMODE_REPLACEINFILES);
   boolean bSearchLen = (length(target_wid._findstring.p_text) > 0);
   boolean bReplaceLen = (length(target_wid._replacestring.p_text) > 0);
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
   _str action, type, id, result;
   parse cmdline with action id;
   switch (lowcase(action)) {
   case 's':   _save_current_search(); break;
   case 'x':   _remove_saved_search(); break;
   case 'a':   _apply_saved_search((int)id); break;
   }
}

static _str _list_saved_searches_callback(int reason, var result, typeless key)
{
   _nocheck _control _sellist;
   if (reason == SL_ONDEFAULT) {
      result = _sellist.p_line - 1; // just want the line/index number
      return (1);
   }
   return ('');
}

static int _list_saved_searches(boolean needs_replace, boolean needs_files)
{
   _str array[];
   _get_saved_search_names(array, needs_replace, needs_files);
   if (array._length() == 0) {
      return (-1);
   }
   typeless result = show('_sellist_form -mdi -modal',
        "Saved Searches",
        SL_NOISEARCH|SL_DEFAULTCALLBACK,
        array,
        "",   // buttons
        "",   // help item name
        "",   // font
        _list_saved_searches_callback   // Call back function
        );
   if (result == "") {
      return (-1);
   }
   int nodes[];
   _get_saved_search_nodes(nodes, needs_replace, needs_files);
   return (nodes[result]);
}

/**
 * Search for text in buffer using search string and search
 * options stored from an entry in the saved search expressions
 * list.
 *
 * @param name Saved search expression name.  If no name is
 *             passed in, a selection list is displayed to pick
 *             from the list of saved expressions.
 * @see find
 * @appliesTo Edit_Window, Editor_Control @categories
 * Search_Functions
 */
_command void find_search_expression(_str name = '') name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (_get_saved_search_count() == 0) {
      message("No saved searches.");
      return;
   }
   int node;
   if (name :== "") {
      node = _list_saved_searches(false, false);
      if (node < 0) {
         return;
      }
   } else {
      node = _find_saved_search(name);
      if (node < 0) {
         message("Saved search name not found");
         return;
      }
   }
   typeless junk;
   _str search_string, color_flags;
   int search_flags;
   _read_saved_search(node, junk, search_string, junk, search_flags, color_flags, junk, junk, junk);
   find(search_string, make_search_options(search_flags):+color_flags);
}

/**
 * Replace text in buffer using search string, replace string,
 * and search options stored from an entry in the saved search
 * expressions list.
 *
 * @param name Saved search expression name.  If no name is
 *             passed in, a selection list is displayed to pick
 *             from the list of saved expressions.
 * @param go   Replace all without prompt.
 * @see find
 * @appliesTo Edit_Window, Editor_Control @categories
 * Search_Functions
 */
_command void replace_search_expression(_str name = '', boolean go = false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (_get_saved_search_count() == 0) {
      message("No saved searches.");
      return;
   }
   int node;
   if (name :== "") {
      node = _list_saved_searches(true, false);
      if (node < 0) {
         return;
      }
   } else {
      node = _find_saved_search(name);
      if (node < 0) {
         message("Saved search name not found");
         return;
      }
   }

   typeless junk;
   _str search_string, replace_string, color_flags;
   int search_flags;
   _read_saved_search(node, junk, search_string, replace_string, search_flags, color_flags, junk, junk, junk);
   replace(search_string, replace_string, make_search_options(search_flags):+color_flags);
}

_command void replace_all_search_expression(_str name = '') name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   replace_search_expression(name, true);
}

/*** utility functions ***/
static int _get_proc_mark( )
{
   typeless p; save_pos(p);
   int mark_id = _alloc_selection();
   _macro('m', _macro('s'));
   _macro_call('select_proc');
   int status = select_proc('', mark_id, 1);
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

static int _get_search_range()
{
   if ((current_find_mode == VSSEARCHMODE_FIND) || (current_find_mode == VSSEARCHMODE_REPLACE)) {
      switch (_findbuffer.p_text) {
      case SEARCH_IN_CURRENT_BUFFER:      return(VSSEARCHRANGE_CURRENT_BUFFER);
      case SEARCH_IN_CURRENT_SELECTION:   return(VSSEARCHRANGE_CURRENT_SELECTION);
      case SEARCH_IN_CURRENT_PROC:        return(VSSEARCHRANGE_CURRENT_PROC);
      case SEARCH_IN_ALL_BUFFERS:
      case SEARCH_IN_ALL_ECL_BUFFERS:     return(VSSEARCHRANGE_ALL_BUFFERS);
      default:                            return(VSSEARCHRANGE_CURRENT_BUFFER);
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

static _str _get_search_options(int mode = -1)
{
   if (mode < 0) {
      mode = current_find_mode;
   }
   _str search_range = _findbuffer.p_text;
   _str search_options = '';
   if (_findword.p_value) search_options = search_options'W';
   if (_findre.p_value) {
      switch (_findre_type.p_text) {
      case RE_TYPE_UNIX_STRING:      search_options = search_options'U'; break;
      case RE_TYPE_BRIEF_STRING:     search_options = search_options'B'; break;
      case RE_TYPE_SLICKEDIT_STRING: search_options = search_options'R'; break;
      case RE_TYPE_PERL_STRING:      search_options = search_options'L'; break;
      case RE_TYPE_WILDCARD_STRING:  search_options = search_options'&'; break;
      }
   }
   switch (mode) {
   case VSSEARCHMODE_FIND:
      if (!_findcase.p_value) search_options = search_options'I';
      if (_findhidden.p_value) search_options = search_options'H';
      if (!_findlist_all.p_value) {
         if (_findback.p_value) search_options = search_options'-';
         if (_findcursorend.p_value) search_options = search_options'>';
      }
      if (_findwrap.p_value == 2) {
         search_options = search_options'?';
      } else if (_findwrap.p_value) {
         search_options = search_options'P';
      }
      if (search_range == SEARCH_IN_CURRENT_SELECTION || search_range == SEARCH_IN_CURRENT_PROC) {
         search_options = search_options'M';
      }
      break;

   case VSSEARCHMODE_FINDINFILES:
      if (!_findcase.p_value) search_options = search_options'I';
      break;

   case VSSEARCHMODE_REPLACE:
      if (_findcase.p_value) {
         search_options = search_options'E';
      } else {
         search_options = search_options'I';
         if (_replacekeepcase.p_value) {
            search_options = search_options'V';
         }
      }
      if (_findhidden.p_value) search_options = search_options'H';
      if (_replacehilite.p_value) search_options = search_options'$';
      if (_findback.p_value) search_options = search_options'-';
      if (_findcursorend.p_value) search_options = search_options'>';
      if (_findwrap.p_value == 2) {
         search_options = search_options'?';
      } else if (_findwrap.p_value) {
         search_options = search_options'P';
      }
      if (search_range == SEARCH_IN_CURRENT_SELECTION || search_range == SEARCH_IN_CURRENT_PROC) {
         search_options = search_options'M';
      }
      break;

   case VSSEARCHMODE_REPLACEINFILES:
      if (_findcase.p_value) {
         search_options = search_options'E';
      } else {
         search_options = search_options'I';
         if (_replacekeepcase.p_value) {
            search_options = search_options'V';
         }
      }
      break;
   }
   if (_findcolor.p_enabled) search_options = search_options:+_findcoloroptions.p_text;
   return(search_options);
}

static int _get_search_flags()
{
   int search_flags = 0;
   search_flags |= _findcase.p_value ? 0: VSSEARCHFLAG_IGNORECASE;
   search_flags |= _findword.p_value ? VSSEARCHFLAG_WORD : 0;
   if (_findre.p_value) {
      switch (_findre_type.p_text) {
      case RE_TYPE_UNIX_STRING:      search_flags |= VSSEARCHFLAG_UNIXRE; break;
      case RE_TYPE_BRIEF_STRING:     search_flags |= VSSEARCHFLAG_BRIEFRE; break;
      case RE_TYPE_SLICKEDIT_STRING: search_flags |= VSSEARCHFLAG_RE; break;
      case RE_TYPE_PERL_STRING:      search_flags |= VSSEARCHFLAG_PERLRE; break;
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
#if __UNIX__
   _str tree_option = '';
#else
   _str tree_option = def_find_file_attr_flags;
#endif
   _str result = '';
   result = _unix_expansion(_findfiles.p_text);
   if (result != '' && (_findsubfolder.p_value) && (_findsubfolder.p_enabled)) {
      tree_option = '+t ' :+ tree_option;
   }
   result = translate(result, FILESEP, FILESEP2);
   wildcards = _findfiletypes.p_text;
   if (wildcards == '') wildcards = ALLFILES_RE;
   files = tree_option:+result;

   result = _unix_expansion(_findexclude.p_text);
   exclude = translate(result, FILESEP, FILESEP2);
   return(0);
}

// build label from search options
_str _get_search_options_label(_str search_options)
{
   _str line = "";
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
      strappend(line, ", "RE_TYPE_UNIX_STRING);
   } else if (pos('b', search_options, 1, 'I')) {
      strappend(line, ", "RE_TYPE_BRIEF_STRING);
   } else if (pos('l', search_options, 1, 'I')) {
      strappend(line, ", "RE_TYPE_PERL_STRING); 
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
   return(line);
}

// build label from multi-file search options
static _str _get_search_results_label()
{
   _str line = "";
   strappend(line, _findgrep.p_text", ");
   if (_mfmdichild.p_value) {
      strappend(line, "Output to editor window, ");
   }
   if (_mflistfilesonly.p_value && _mflistfilesonly.p_visible) {
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
   if (current_find_mode == VSSEARCHMODE_FINDINFILES) {
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
   _str grep_buffer = _findgrep.p_text;
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

static void _append_save_history()
{
   _save_form_response();
   _append_retrieve(_control _findstring, _findstring.p_text);
   _findstring.p_user = '';
   if (current_find_mode == VSSEARCHMODE_REPLACE || current_find_mode == VSSEARCHMODE_REPLACEINFILES) {
      _append_retrieve(_control _replacestring, _replacestring.p_text);
      _replacestring.p_user = '';
   }
   if (current_find_mode == VSSEARCHMODE_FINDINFILES || current_find_mode == VSSEARCHMODE_REPLACEINFILES) {
      if (_findfiles.p_text != '') {
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
         _findfiles.p_user = '';
      }
      if (_findfiletypes.p_text != '') {
         _append_retrieve(_control _findfiletypes, _findfiletypes.p_text);
         _findfiletypes.p_user = '';
      }
      if (_findexclude.p_text != '') {
         _append_retrieve(_control _findexclude, _findexclude.p_text);
         _findexclude.p_user = '';
      }
   }
}

static void _tool_hide_on_default()
{
   if (def_find_close_on_default) {
      _tbDismiss(p_active_form);
   }
}

_str _find_buffer_name(int buffer_id)
{
   _str info = buf_match('', 1, 'V');
   for (;;) {
      if (rc) { break; }
      _str buf_id;
      _str buf_name;
      parse info with buf_id . . buf_name;
      if (buf_id == buffer_id) {
         return buf_name;
      }
      info = buf_match('', 0, 'V');
   }
   return '';
}

static void _show_current_search_window(int window_id)
{
   if (window_id == 0 || !_iswindow_valid(window_id)) {
      return;
   }
   ignore_change = false;
   if (window_id.p_mdi_child) {
      window_id._set_focus();
   } else if (_tbFind(window_id.p_active_form.p_name) != null) {
      _str focus_wid = (window_id.p_active_form != window_id) ? window_id.p_name : '';
      activate_toolbar(window_id.p_active_form.p_name, focus_wid);
   } 
}

static void _show_textbox_error_color(boolean show_error)
{
   p_forecolor = (show_error) ? 0x00FFFFFF : 0x80000008;
   p_backcolor = (show_error) ? 0x006666FF : 0x80000005;
}

/*** module init ***/
definit()
{
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
   _clear_last_found_cache();

   if (def_max_mffind_output <= 0) {
      def_max_mffind_output = 2 * 1024 * 1024;
   }

   _saved_searches_handle = -1;

   is_state.window_id = 0;
}

defeventtab _ccsearch_form;
void ctlok.lbutton_up()
{
   int i;
   _str IncludeChars = "";
   _str ExcludeChars = "";
   for ( i = 1;i <= gcolortab._length(); ++i) {
      int wid = _find_control('check'i);
      if (wid.p_value == 0) {
         ExcludeChars = ExcludeChars:+substr(COLOR2CHECKBOXTAB,i,1);
      } else if (wid.p_value == 1) {
         IncludeChars = IncludeChars:+substr(COLOR2CHECKBOXTAB,i,1);
      }
   }
   if (IncludeChars == "" && ExcludeChars == "") {
      _param1 = "";
      p_active_form._delete_window(1);
      return;
   }
   if (IncludeChars != '') {
      IncludeChars = 'C'IncludeChars;
   }
   if (ExcludeChars != '') {
      ExcludeChars = 'X'ExcludeChars;
   }
   _param1 = IncludeChars',':+ExcludeChars',';
   p_active_form._delete_window(1);
}

void ctlreset.lbutton_up()
{
   int i;
   for (i = 1; i <= gcolortab._length(); ++i) {
      int wid = _find_control('check'i);
      wid.p_value = 2;
   }
}

void ctlok.on_create()
{
   _str IncludeChars, ExcludeChars;
   int i, j;
   parse arg(1) with IncludeChars','ExcludeChars',';
   for (i = 2; i <= length(IncludeChars); ++i) {
      j = pos(substr(IncludeChars, i, 1, 'I'), COLOR2CHECKBOXTAB);
      if (j) {
         int wid = _find_control('check'j);
         if (wid) {
            wid.p_value = 1;
         }
      }
   }
   for (i = 2;i <= length(ExcludeChars); ++i) {
      j = pos(substr(ExcludeChars, i, 1, 'I'),COLOR2CHECKBOXTAB);
      if (j) {
         int wid = _find_control('check'j);
         if (wid) {
            wid.p_value = 0;
         }
      }
   }
}

/*** replace diff view ***/
static int replace_diff_handle = -1;
int replace_diff_begin()
{
   _project_disable_auto_build(true);
   int status = _mdi.p_child.list_modified("Files must be saved before search and replace preview", true);
   _project_disable_auto_build(false);
   if(status) {
      return -1;
   }
   int handle = refactor_begin_transaction();
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

void replace_diff_end(boolean cancel_diff, _str results_name, _str mfUndoName = '')
{
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
   int status = 0;
   refactor_review_and_commit_transaction(replace_diff_handle, status, '', mfUndoName, '', results_name, true);
}

/*** last found cache ***/
static _str last_search_options = '';
static int last_search_flags = 0;

static void _clear_last_found_cache()
{
   last_search_options = '';
   last_search_flags = 0;
}

static boolean _search_last_found(_str search_string, _str search_options, int search_range)
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
         if (((mark_type == 'BLOCK') || (mark_type == 'CHAR')) && (p_col <= first_col)) {
            _end_select(mark_id);
         } else if ((mark_type == 'LINE') && (p_col <= first_col)) {
            _end_select(mark_id); _end_line();
         }
      }
   } else {
      if (_end_select_compare(mark_id) == 0) {
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
   int status = -1;
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
boolean _update_find_next_mark(_str& search_mark)
{
   boolean show_mark = true;
   if (old_search_range == VSSEARCHRANGE_CURRENT_SELECTION) {
      if (!def_leave_selected) {
         // !def_leave_selected already behaves
         show_mark = false;
      } else if (select_active()) {
         // replace current search mark with new locked selection
         if (search_mark != '') {
            _free_selection(search_mark);
            search_mark = '';
         }
         search_mark = _duplicate_selection();
         _adjust_cursor_in_search_selection(search_mark);
      } else if (search_mark == '') {
         // no search mark, waiting for new user selection
         show_mark = false;
      } else if (!_in_selection(search_mark)) {
         // have a search mark, but moved cursor out of selection, free it
         // and wait for another selection
         _free_selection(search_mark);
         search_mark = '';
         show_mark = false;
      }
   } else if (old_search_range == VSSEARCHRANGE_CURRENT_PROC) {
      if (!_in_selection(search_mark)) {
         // cursor moved outside of search mark, attempt to generate a new one
         if ((p_lexer_name != '') && _in_function_scope()) {
            if (search_mark != '') {
               _free_selection(search_mark);
               search_mark = '';
            }
            search_mark = _get_proc_mark();
         } else {
            // can't generate one, don't keep trying
            _free_selection(search_mark);
            search_mark = '';
            show_mark = false;
            old_search_range = VSSEARCHRANGE_CURRENT_BUFFER;
            _init_buffer_range(VSSEARCHRANGE_CURRENT_BUFFER);
            set_find_next_msg("Find", old_search_string, old_search_flags, old_search_range);
         }
      }
   } else {
      _free_selection(search_mark);
      search_mark = '';
      show_mark = false;
      old_search_range = VSSEARCHRANGE_CURRENT_BUFFER;
      _init_buffer_range(VSSEARCHRANGE_CURRENT_BUFFER);
      set_find_next_msg("Find", old_search_string, old_search_flags, old_search_range);
   }
   return(show_mark);
}

/*
int _update_find_next_wrap()
{
   if (old_search_range != VSSEARCHRANGE_ALL_BUFFERS || !p_mdi_child || _no_child_windows()) {
      return STRING_NOT_FOUND_RC;
   }
   typeless p1, p3, p4, p5;
   int search_flags;
   save_search(p1, search_flags, p3, p4, p5);
   restore_search(p1, search_flags | VSSEARCHFLAG_NO_MESSAGE, p3, p4, p5);
   boolean do_prev = (search_flags & REVERSE_SEARCH) ? true : false;
   int status = STRING_NOT_FOUND_RC;

   int temp_view_id;
   int next_buf_id;
   int jump_to_view;
   int first_buf_id = p_buf_id;
   typeless orig_view_id = _create_temp_view(temp_view_id);
   typeless orig_buf_id = p_buf_id;
   typeless p;
   if (orig_view_id != "") {
      p_buf_id = first_buf_id;
      if (do_prev) {
         _prev_buffer('NR');
      } else {
         _next_buffer('NR');
      }
      while (p_buf_id != first_buf_id) {
         if (do_prev) {
            bottom();
         } else {
            top(); up();
         }
         status = repeat_search();
         if (!status) {
            jump_to_view = window_match(p_buf_name, 1, 'x');
            next_buf_id = p_buf_id;
            save_pos(p);
            break;
         }
         if (do_prev) {
            _prev_buffer('NR');
         } else {
            _next_buffer('NR');
         }
      }
      p_buf_id = orig_buf_id;
      p_window_id = orig_view_id;
      _delete_temp_view(temp_view_id, true);
   }
   restore_search(p1, search_flags, p3, p4, p5);
   if (!status) {
      jump_to_view._set_focus();
      jump_to_view.restore_pos(p);
   }
   return status;
}
*/

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
int list_all_occurrences(_str search_text, _str search_options, int mfflags, int grep_id)
{
   int num_matches = 0;
   _SetAllOldLineNumbers();
   typeless p; save_pos(p);
   boolean search_mark = (pos('m', search_options, 1, 'I') != 0);
   if (search_mark) {
      _begin_select(); _begin_line();
   } else {
      top();
   }
   int orig_wid;
   get_window_id(orig_wid);

   _str topline = se.search.generate_search_summary(search_text, search_options, "", mfflags, "", "");
   SearchResults results;
   results.initialize(topline, search_text, mfflags, grep_id);
   int status = search(search_text, 'xv,@'search_options'+');
   if (!status) {
      while (!status) {
         results.insertCurrentMatch();
         ++num_matches;
         status = repeat_search();
      }
   }
   results.done('Total found: ':+num_matches);
   results.showResults();
   orig_wid._set_focus(); // may have lost focus to search results
   restore_pos(p);
   return(num_matches);
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
int highlight_all_occurrences(_str search_text, _str search_options)
{
   int num_matches = 0;
   typeless p; save_pos(p);
   boolean search_backwards = (pos('-', search_options) != 0);
   boolean search_mark = (pos('m', search_options, 1, 'I') != 0);
   if (search_backwards) {
      if (search_mark) {
         _end_select(); _end_line();
      } else {
         bottom();
      }
   } else {
      if (search_mark) {
         _begin_select(); _begin_line();
      } else {
         top();
      }
   }
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   strappend(search_options,'#');
   int status = search(search_text, 'xv,@'search_options);
   if (!status) {
      while (!status) {
         ++num_matches;
         _MaybeUnhideLine();
         status = repeat_search();
      }
   }
   restore_pos(p);
   save_search(old_search_string, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
   old_search_flags &= (~VSSEARCHFLAG_FINDHILIGHT);  // don't carrying highlight
   restore_search(s1, s2, s3, s4, s5);
   return(num_matches);
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
int bookmark_all_occurrences(_str search_text, _str search_options)
{
   int num_matches = 0;
   typeless p; save_pos(p);
   boolean search_backwards = (pos('-', search_options) != 0);
   boolean search_mark = (pos('m', search_options, 1, 'I') != 0);
   if (search_backwards) {
      if (search_mark) {
         _end_select(); _end_line();
      } else {
         bottom();
      }
   } else {
      if (search_mark) {
         _begin_select(); _begin_line();
      } else {
         top();
      }
   }
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   int status = search(search_text, 'xv,@'search_options);
   if (!status) {
      while (!status) {
         ++num_matches;
         _MaybeUnhideLine();
         if (num_matches > def_find_high_added_bookmarks) {
            int result = _message_box("Adding a large number bookmarks to this buffer.  Continue adding bookmarks?", "", MB_YESNOCANCEL|MB_ICONQUESTION);
            if (result == IDCANCEL || result == IDNO) {
               break;
            }
         }
          set_bookmark('-r 'get_bookmark_name(), true);
         _end_line();
         status = repeat_search();
      }
   }
   restore_pos(p);
   save_search(old_search_string, old_search_flags, old_word_re, old_search_reserved, old_search_flags2);
   restore_search(s1, s2, s3, s4, s5);
   activate_bookmarks();
   updateBookmarksToolWindow();
   return(num_matches);
}

