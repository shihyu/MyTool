////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48683 $
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
#import "briefutl.e"
#import "clipbd.e"
#import "files.e"
#import "listbox.e"
#import "mouse.e"
#import "picture.e"
#import "stdprocs.e"
#import "tbautohide.e"
#import "toolbar.e"
#import "treeview.e"
#import "recmacro.e"
#import "seek.e"
#import "util.e"
#endregion

/**
 * Displays and activates the Clipboards toolbar, which displays 
 * selection list and previews of recently used clipboards. 
 * 
 * @appliesTo Edit_Window
 * @categories Buffer_Functions
 */
_command void list_clipboards() name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   if (!Nofclipboards) {
      message('No clipboards');
      return;
   }
   /*
      Can only run the clipboard tool window for mdi child edit windows.
      Otherwise the current dialog disappears when the clipboard tool window
      is displayed and/or when the clipboard tool window is closed.

      For v18, we might need to also check whether the mdi child is
      clipped to the mdi frame.
   */
   if (!p_mdi_child) {
      _default_option(VSOPTION_STAY_IN_GET_STRING_COUNT,1);
      list_clipboards_modal();
      _default_option(VSOPTION_STAY_IN_GET_STRING_COUNT,0);
      return;
   }
   if (p_active_form.p_modal) {
      list_clipboards_modal();
      return;
   }
   _macro_delete_line();

   int window_id = p_window_id;
   boolean already_open = true;
   if (_find_object("_tbclipboard_form", 'n') == 0) {
      already_open = false;
   }

   int formid = activate_toolbar("_tbclipboard_form", 'ctl_filter');
   if (!formid) {
      return;
   }
   if (already_open) {
      _nocheck _control ctl_clipboard_list;
      formid.ctl_clipboard_list._TreeTop();
   }
   formid._set_target_window(window_id);
}

int _OnUpdate_list_clipboards(CMDUI &cmdui,int target_wid,_str command)
{
   if (!target_wid || (!target_wid._isEditorCtl() && target_wid.p_object != OI_TEXT_BOX)) {
      return(MF_GRAYED);
   }
   if (target_wid._isEditorCtl() && target_wid._QReadOnly()) {
      return(MF_GRAYED);
   }
   if (target_wid.p_object == OI_TEXT_BOX && target_wid.p_ReadOnly) {
      return(MF_GRAYED);
   }
   // IF we don't have any internal clipboards
   if (!Nofclipboards) {
      // Return BOTH GRAYED and ENABLED.  This is because the command
      // should remain enabled so that it can be ran from a keystroke
      // or the command line, but it should appear grayed on the menu
      // and button bars.  This allows list-clipboards to report that
      // there are no clipboards.
      return(MF_GRAYED|MF_ENABLED);
   }
   return(MF_ENABLED);
}

defeventtab _tbclipboard_form;

void _tbclipboard_form.on_create()
{
   // retrieve saved divider positions
   typeless xpos = _retrieve_value("_tbclipboard_form.ctl_v_divider.p_x");
   if (isinteger(xpos)) {
      ctl_v_divider.p_x = xpos;
   }
   typeless ypos = _retrieve_value("_tbclipboard_form.ctl_h_divider.p_y");
   if (isinteger(ypos)) {
      ctl_h_divider.p_y = ypos;
   }

   // prefer horizontal or vertical view or allow auto
   typeless prefs = _retrieve_value("_tbclipboard_form.ctl_h_divider.p_user");
   if (isinteger(prefs)) {
      ctl_h_divider.p_user = prefs;
   } else {
      ctl_h_divider.p_user = -1;
   }
   ctl_clipboard_list.p_user = 0;
   call_event(p_active_form, ON_RESIZE, 'w');
}

void _tbclipboard_form.on_load()
{
   _list_clipboards();

   ctl_clipboard_list._TreeTop();
   ctl_clipboard_list.call_event(CHANGE_SELECTED, ctl_clipboard_list._TreeCurIndex(), ctl_clipboard_list.p_window_id, ON_CHANGE, 'W');
}

void _tbclipboard_form.on_destroy()
{
   _append_retrieve(0, ctl_v_divider.p_x, "_tbclipboard_form.ctl_v_divider.p_x");
   _append_retrieve(0, ctl_h_divider.p_y, "_tbclipboard_form.ctl_h_divider.p_y");
   _append_retrieve(0, ctl_h_divider.p_user, "_tbclipboard_form.ctl_h_divider.p_user");

   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id, ON_DESTROY, '2');
}

void ctl_clipboard_list.on_create()
{
   _TreeSetColButtonInfo(0, 1000, 0, 0, 'Name');
   _TreeSetColButtonInfo(1, 1000, 0, 0, 'Type');
   _TreeSetColButtonInfo(2, 1000, 0, 0, 'Lines');
   _TreeSetColButtonInfo(3, 1000, TREE_BUTTON_AUTOSIZE, 0, 'Text');
}

void ctl_clipboard_preview.on_create()
{
   p_window_flags &= ~(CURLINE_COLOR_WFLAG);
   p_window_flags |= VSWFLAG_NOLCREADWRITE;
   p_MouseActivate = MA_NOACTIVATE;
   p_LCBufFlags &= ~(VSLCBUFFLAG_LINENUMBERS | VSLCBUFFLAG_LINENUMBERS_AUTO | VSLCBUFFLAG_READWRITE);
   p_word_wrap_style &= ~WORD_WRAP_WWS;
   p_SoftWrap = false;
   p_line_numbers_len = 0;
   p_undo_steps = 0;
   p_ReadOnly = true;
}

#define CLIPBD_FILTER_TEXT       ctl_filter.p_user

/**
 * Refilter files when the filter changes
 */
void ctl_filter.on_change(int reason=CHANGE_OTHER)
{
   filter_clipboards();
}

/**
 * Filter all the clipboards in the file list according to the
 * given filter regular expression.  This simply marks the lines
 * that do not match the filter as hidden tree nodes, and the
 * other lines as non-hidden.  The current object is expected to
 * be the clipboard list tree control.
 *
 * @param filter_re  Regular expression to match files against
 */
static void filter_clipboards(boolean force = false)
{
   if (force || CLIPBD_FILTER_TEXT == null || CLIPBD_FILTER_TEXT :!= ctl_filter.p_text) {
      origWid := p_window_id;
      p_window_id = ctl_clipboard_list;
      _FilterTreeControl(ctl_filter.p_text, false, true);
      // do a prefix match selection...
      index := _TreeSearch(TREE_ROOT_INDEX, ctl_filter.p_text, 'P');
      if (index > 0) {
         _TreeSetCurIndex(index);
         _TreeScroll(_TreeCurLineNumber());
         if (!_TreeUp()) _TreeDown();
         _TreeDeselectAll();
         _TreeSetCurIndex(index);
         _TreeSelectLine(index);
      }

      _TreeRefresh();
      index = _TreeCurIndex();
      p_window_id = origWid;

      CLIPBD_FILTER_TEXT = ctl_filter.p_text;

      _set_clipboard_preview(index);
   }
}

void ctl_filter.ESC()
{
   ctl_clipboard_list.call_event(ctl_clipboard_list,ESC);
}

void ctl_filter.DEL()
{
   ctl_clipboard_list.call_event(ctl_clipboard_list,DEL);
}

void ctl_filter.'c_enter'()
{
   ctl_clipboard_list.paste_clipboard_without_setting_current();
}

void ctl_filter.pgup,"s-up"()
{
   ctl_clipboard_list.call_event(ctl_clipboard_list,S_UP);
}
void ctl_filter.pgup,"s-down"()
{
   ctl_clipboard_list.call_event(ctl_clipboard_list,S_DOWN);
}

/**
 * Move up in the file tree.  Catch the cursor up key, and the
 * Ctrl+I
 */
void ctl_filter.up,"c-i"()
{
   ctl_clipboard_list.call_event(ctl_clipboard_list,UP);
}

/**
 * Move down in the file tree.  Catch the cursor down key, and
 * the Ctrl+K
 */
void ctl_filter.down,"c-k"()
{
   ctl_clipboard_list.call_event(ctl_clipboard_list,DOWN);
}

void ctl_filter.pgup,"c-p"()
{
   ctl_clipboard_list.call_event(ctl_clipboard_list,PGUP);
}

void ctl_filter.pgdn,"c-n"()
{
   ctl_clipboard_list.call_event(ctl_clipboard_list,PGDN);
}

void ctl_filter.home,"c-u"()
{
   ctl_clipboard_list.call_event(ctl_clipboard_list,HOME);
}

void ctl_filter.end,"c-o"()
{
   ctl_clipboard_list.call_event(ctl_clipboard_list,END);
}

/**
 * Put focus in the tree if they hit enter in the filter combo.
 */
void ctl_filter.ENTER()
{
   ctl_clipboard_list.call_event(ctl_clipboard_list,ENTER);
}

/**
 * When the filter text box gets focus, be sure at least one
 * line in the tree is selected.
 *
 */
void ctl_filter.on_got_focus()
{
   ctl_clipboard_list.call_event(CHANGE_SELECTED, ctl_clipboard_list._TreeCurIndex(), ctl_clipboard_list.p_window_id, ON_CHANGE, 'W');

   p_sel_start  = 1;
   p_sel_length = p_text._length();
}

static typeless ClipCommands:[] = {
   "bottom-of-buffer"          =>'',
   "top-of-buffer"             =>'',
   "page-up"                   =>'',
   "vi-page-up"                =>'',
   "page-down"                 =>'',
   "vi-page-down"              =>'',
   "cursor-left"               =>'',
   "cursor-right"              =>'',
   "cursor-up"                 =>'',
   "cursor-down"               =>'',
   "begin-line"                =>'',
   "begin-line-text-toggle"    =>'',
   "brief-home"                =>'',
   "vi-begin-line"             =>'',
   "vi-begin-line-insert-mode" =>'',
   "brief-end"                 =>'',
   "end-line"                  =>'',
   "vi-end-line"               =>'',
   "brief-end"                 =>'',
   "vi-end-line-append-mode"   =>'',
   "deselect"                  =>'',
   "mou-click"                 =>'',
   "mou-select-word"           =>'',
   "mou-select-line"           =>'',
   "select-char"               =>'',
   "select-line"               =>'',
   "select-block"              =>'',
   "select-word"               =>'',
   "select-all"                =>'',
   "next-word"                 =>'',
   "prev-word"                 =>'',
   "copy-to-clipboard"         =>'',
   "append-to-clipboard"       =>''
};

void ctl_clipboard_preview.\0-ON_SELECT()
{
   _str lastevent = last_event();
   if (lastevent == ESC) {
      p_active_form.call_event(p_active_form, ESC);
      return;
   }
   int key_index = event2index(lastevent);
   int name_index = eventtab_index(_default_keys, ctl_clipboard_preview.p_mode_eventtab, key_index);
   _str command_name = name_name(name_index);
   if (ClipCommands._indexin(command_name)) {
      switch (ClipCommands:[command_name]._varformat()) {
      case VF_FUNPTR:
         _str junk = (*ClipCommands:[command_name])();
         break;
      case VF_LSTR:
         call_index(name_index);
         break;
      }
   }
}

void ctl_clipboard_preview.wheel_down,wheel_up()
{
   fast_scroll();
}

void ctl_clipboard_preview.'c-wheel-down'()
{
   scroll_page_down();
}

void ctl_clipboard_preview.'c-wheel-up'()
{
   scroll_page_up();
}

void ctl_v_divider.lbutton_down()
{
   _ul2_image_sizebar_handler(ctl_clipboard_list.p_x, ctl_clipboard_preview.p_x + ctl_clipboard_preview.p_width);
}

void ctl_h_divider.lbutton_down()
{
   _ul2_image_sizebar_handler(ctl_clipboard_list.p_y, ctl_clipboard_preview.p_y + ctl_clipboard_preview.p_height);
}

void _tbclipboard_form.on_resize()
{
   int clientW = _dx2lx(p_active_form.p_xyscale_mode, p_active_form.p_client_width);
   int clientH = _dy2ly(p_active_form.p_xyscale_mode, p_active_form.p_client_height);
   padding := ctl_filter_label.p_x;

   // some things are the same, no matter the orientation
   ctl_filter_label.p_y = padding;

   ctl_filter.p_x = ctl_filter_label.p_x + ctl_filter_label.p_width + padding;
   ctl_filter.p_y = padding;

   ctl_clipboard_list.p_x = padding;

   boolean displayHorz = (ctl_h_divider.p_user < 0) ? (p_width < p_height) : ctl_h_divider.p_user;
   if (displayHorz) {
      // tall display

      ctl_filter.p_width = clientW - padding - ctl_filter.p_x;

      ctl_clipboard_list.p_y = ctl_filter.p_y + ctl_filter.p_height + padding;
      ctl_clipboard_list.p_width = clientW - (2 * padding);
      ctl_clipboard_list.p_height = ctl_h_divider.p_y - ctl_clipboard_list.p_y;

      ctl_h_divider.p_x = ctl_clipboard_preview.p_x = padding;
      ctl_clipboard_preview.p_y = ctl_h_divider.p_y + ctl_h_divider.p_height;
      ctl_clipboard_preview.p_width = clientW - (2 * padding);
      ctl_clipboard_preview.p_height = clientH - padding - ctl_clipboard_preview.p_y;

      ctl_h_divider.p_visible = true;
      ctl_v_divider.p_visible = false;
      ctl_h_divider.p_width = clientW - (2 * padding);
   } else {
      // wide display

      ctl_filter.p_width = ctl_v_divider.p_x - ctl_filter.p_x;

      ctl_clipboard_list.p_y = ctl_filter.p_y + ctl_filter.p_height + padding;
      ctl_clipboard_list.p_width = ctl_v_divider.p_x - ctl_clipboard_list.p_x;
      ctl_clipboard_list.p_height = clientH - padding - ctl_clipboard_list.p_y;

      ctl_v_divider.p_y = ctl_clipboard_preview.p_y = padding;
      ctl_clipboard_preview.p_x = ctl_v_divider.p_x + ctl_v_divider.p_width;
      ctl_clipboard_preview.p_width = clientW - padding - ctl_clipboard_preview.p_x;
      ctl_clipboard_preview.p_height = clientH - (2 * padding);

      ctl_h_divider.p_visible = false;
      ctl_v_divider.p_visible = true;
      ctl_v_divider.p_height = clientH - (2 * padding);
   }
}

static void _show_target_window(int window_id)
{
   if (window_id <= 0 || !_iswindow_valid(window_id)) {
      return;
   }
   if (window_id == _cmdline) {
      _cmdline.p_visible = 1;
      _cmdline._set_focus();
   } else if (window_id.p_mdi_child) {
      window_id._set_focus();
   } else if (_tbFind(window_id.p_active_form.p_name) != null) {
      _str focus_wid = (window_id.p_active_form != window_id) ? window_id.p_name : '';
      activate_toolbar(window_id.p_active_form.p_name, focus_wid);
   }
}

static void _set_target_window(int window_id)
{
   if (window_id == ctl_clipboard_preview.p_window_id) {
      // ignore preview window as a target
      return;
   }
   if (window_id <= 0 || !_iswindow_valid(window_id)) {
      window_id = _mdi._edit_window();
   }
   ctl_clipboard_list.p_user = window_id;
}

static void _list_clipboards()
{
   int clip_wid = ctl_clipboard_list.p_window_id;
   int orig_wid = p_window_id;
   int orig_view_id = 0;
   int temp_view_id = 0;
   _str caption;
   _str line;
   _str name, type, count, text;
   ctl_clipboard_list._TreeBeginUpdate(TREE_ROOT_INDEX);
   ctl_clipboard_list._TreeDelete(TREE_ROOT_INDEX, "C");

   orig_view_id = _create_temp_view(temp_view_id);
   if (orig_view_id == '') return;
   _get_clipboard_list(temp_view_id);
   top(); up();
   while (!down()) {
      get_line(line);
      parse line with name type count text;
      text = expand_tabs(text);
      caption = name :+ "\t" :+ type :+ "\t" :+ count :+ "\t" :+ text;
      clip_wid._TreeAddItem(TREE_ROOT_INDEX,
                            strip(caption),
                            TREE_ADD_AS_CHILD,
                            0, 0, TREE_NODE_LEAF,
                            0, text);
   }

   // grab last modified from the clipboard
   activate_window(_clipboards_view_id);
   last_mod := p_LastModified;

   activate_window(orig_wid);
   _delete_temp_view(temp_view_id);
   ctl_clipboard_list._TreeEndUpdate(TREE_ROOT_INDEX);
   ctl_clipboard_list._TreeAdjustColumnWidthsByColumnCaptions();
   ctl_clipboard_preview.p_user = last_mod;

   filter_clipboards(true);
}

void _set_clipboard_preview(int index)
{
   if (index <= TREE_ROOT_INDEX || ctl_clipboard_list._TreeIsItemHidden(index)) {
      ctl_clipboard_preview._lbclear();
      ctl_clipboard_preview.p_redraw = true;
      return;
   }
   boolean preview_clipped = false;
   int orig_wid = p_window_id;
   int preview_wid = ctl_clipboard_preview.p_window_id;
   _str caption = ctl_clipboard_list._TreeGetCaption(index);
   long clip_offset = 0;
   typeless i;
   parse caption with i .;

   activate_window(_clipboards_view_id);
   save_pos(auto p);
   goto_named_clipboard(i);
   _get_clipboard_header(auto type, auto Noflines, auto name, auto col, auto utf8, auto lexername);
   markid := _alloc_selection();
   orig_utf8 := p_UTF8;
   p_UTF8 = utf8;
   down(); _begin_line(); clip_offset = _nrseek();
   _select_line(markid); _select_type(markid, 'S', 'E');
   down(Noflines - 1); _end_line();
   if (def_clipboards_max_preview > 0 && _nrseek() - clip_offset > def_clipboards_max_preview) {
      _nrseek(clip_offset + def_clipboards_max_preview);
      _select_type(markid, 'T', 'CHAR');
      _select_char(markid);
      preview_clipped = true;
   } else {
      _select_line(markid);
   }
   activate_window(preview_wid);
   _lbclear();
   top(); up();
   if (_select_type(markid) != 'LINE') {
      insert_line(''); _delete_text(2);
   }
   p_UTF8 = utf8;
   _copy_to_cursor(markid);
   if (preview_clipped) {
      bottom();
      _str info = "";
      int lines_not_displayed = Noflines - p_Noflines;
      if (lines_not_displayed > 0) {
         info = info :+ "+" :+ lines_not_displayed :+ " lines ";
      }
      info = info :+ "(Clipboard exceeds max preview size)";
      insert_line(info);
      _lineflags(NOSAVE_LF, NOSAVE_LF);
      top(); up(); p_scroll_left_edge = -1;
   }
   p_lexer_name = lexername;
   p_color_flags = (lexername == '') ? 0 : LANGUAGE_COLOR_FLAG;
   _use_source_window_font(utf8 ? CFG_UNICODE_SOURCE_WINDOW : CFG_SBCS_DBCS_SOURCE_WINDOW);
   activate_window(_clipboards_view_id);
   _free_selection(markid);
   restore_pos(p);
   p_UTF8 = orig_utf8;
   activate_window(orig_wid);
   preview_wid.refresh('W');
   preview_wid.p_redraw = true;
}

static void _delete_clipboard()
{
   index := _TreeCurIndex();
   if (index <= TREE_ROOT_INDEX || _TreeIsItemHidden(index)) {
      return;
   }
   typeless name;
   caption := _TreeGetCaption(index);
   cur_line := _TreeCurLineNumber();
   parse caption with name . ;
   free_clipboard(name);
   _list_clipboards();
   _TreeCurLineNumber(cur_line);
}

static void _clear_clipboard()
{
   ctl_clipboard_list._TreeDelete(TREE_ROOT_INDEX, "C");
   ctl_clipboard_preview._lbclear();
   reset_clipboards();
   ctl_clipboard_preview.p_user = _clipboards_view_id.p_LastModified;
}

static void _push_clipboard()
{
   index := _TreeCurIndex();
   if (index <= TREE_ROOT_INDEX || _TreeIsItemHidden(index)) {
      return;
   }
   typeless name;
   caption := _TreeGetCaption(index);
   parse caption with name . ;
   _set_current_clipboard(name);
   _list_clipboards();
   _TreeTop();
   call_event(CHANGE_SELECTED, _TreeCurIndex(), p_window_id, ON_CHANGE, 'W');

   _macro('m', _macro('s'));
   _macro_call('_set_current_clipboard', name);
}

static void _save_clipboard()
{
   index := _TreeCurIndex();
   if (index <= TREE_ROOT_INDEX || _TreeIsItemHidden(index)) {
      return;
   }

   _str caption = ctl_clipboard_list._TreeGetCaption(index);
   typeless name;
   parse caption with name .;
   write_clipboard(name);
}

static void _paste_clipboard(int target_wid)
{
   index := _TreeCurIndex();
   if (index <= TREE_ROOT_INDEX || _TreeIsItemHidden(index)) {
      return;
   }
   if (!Nofclipboards || target_wid <= 0) {
      return;
   }
   if (target_wid._isEditorCtl() && target_wid._QReadOnly()) {
      message("This command is not allowed in Read Only mode");
      return;
   }

   orig_wid := p_window_id;
   typeless name;
   caption := _TreeGetCaption(index);
   parse caption with name . ;

   typeless status = _set_current_clipboard(name);
   if (status) {
      return;
   }
   activate_window(target_wid);

   _PasteWithBlockModeSupport();
   activate_window(orig_wid);

   _macro('m', _macro('s'));
   _macro_call('_set_current_clipboard', name);
   _macro_call('_PasteWithBlockModeSupport');
}
static void _paste_named_clipboard(int target_wid, _str name)
{
   if (!Nofclipboards || target_wid <= 0) {
      return;
   }
   if (target_wid._isEditorCtl() && target_wid._QReadOnly()) {
      message("This command is not allowed in Read Only mode");
      return;
   }

   orig_wid := p_window_id;
   activate_window(target_wid);
   _PasteWithBlockModeSupport(name);
   activate_window(orig_wid);

   _macro('m', _macro('s'));
   _macro_call('_PasteWithBlockModeSupport', name);
}

void ctl_clipboard_list.on_change(int reason, int index)
{
   if (reason == CHANGE_SELECTED) {
      _set_clipboard_preview(index);
   }
}

void ctl_clipboard_list.del()
{
   _delete_clipboard();
}

void ctl_clipboard_list.enter()
{
   ctl_clipboard_list.call_event(ctl_clipboard_list, LBUTTON_DOUBLE_CLICK, 'w');
}

void ctl_clipboard_list.lbutton_double_click()
{
   int target_wid = ctl_clipboard_list.p_user;
   _paste_clipboard(target_wid);

   // the default behavior here is to mimic the o.g. list-clipboards list box.
   // dismiss the tool window and return focus to the original target window
   _tbDismiss(p_active_form);
   _show_target_window(target_wid);
}

// paste clipboard without setting it as current clipboard item
void ctl_clipboard_list.'c_enter'()
{
   paste_clipboard_without_setting_current();
}

static void paste_clipboard_without_setting_current()
{
   index := _TreeCurIndex();
   if (index <= TREE_ROOT_INDEX || _TreeIsItemHidden(index)) {
      return;
   }

   typeless name;
   caption := _TreeGetCaption(index);
   parse caption with name . ;

   int target_wid = ctl_clipboard_list.p_user;
   _paste_named_clipboard(target_wid, name);
}

void ctl_clipboard_list.rbutton_up()
{
   // get the menu form
   index := find_index("_tbclipboard_menu", oi2type(OI_MENU));
   if (!index) {
      return;
   }

   tree_index := _TreeCurIndex();
   menu_handle := p_active_form._menu_load(index, 'P');
   if (Nofclipboards <= 0 || tree_index <= TREE_ROOT_INDEX) {
      _menu_set_state(menu_handle, "0", MF_GRAYED, 'P');
      _menu_set_state(menu_handle, "1", MF_GRAYED, 'P');
      _menu_set_state(menu_handle, "2", MF_GRAYED, 'P');
      _menu_set_state(menu_handle, "3", MF_GRAYED, 'P');
   }
   if (ctl_h_divider.p_user < 0) {
      _menu_set_state(menu_handle, "tbclip_menu viewauto", MF_CHECKED, 'M');
   } else if (ctl_h_divider.p_user > 0) {
      _menu_set_state(menu_handle, "tbclip_menu viewhorz", MF_CHECKED, 'M');
   } else {
      _menu_set_state(menu_handle, "tbclip_menu viewvert", MF_CHECKED, 'M');
   }

   // Show menu:
   int x, y;
   mou_get_xy(x, y);
   int status = _menu_show(menu_handle, VPM_RIGHTBUTTON, x - 1, y - 1);
   _menu_destroy(menu_handle);
}

_command void tbclip_menu(_str cmdline = '') name_info(',' VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _nocheck _control ctl_clipboard_list;
   _macro_delete_line();
   _str command;
   typeless id;
   parse cmdline with command id;
   switch (lowcase(command)) {
   case 'delete':
      ctl_clipboard_list._delete_clipboard();
      break;
   case 'clear':
      ctl_clipboard_list._clear_clipboard();
      break;
   case 'set':
      ctl_clipboard_list._push_clipboard();
      break;
   case 'save':
      ctl_clipboard_list._save_clipboard();
      break;
   case 'viewauto':
      ctl_h_divider.p_user = -1;
      call_event(p_active_form, ON_RESIZE, 'w');
      break;
   case 'viewhorz':
      ctl_h_divider.p_user = 1;
      call_event(p_active_form, ON_RESIZE, 'w');
      break;
   case 'viewvert':
      ctl_h_divider.p_user = 0;
      call_event(p_active_form, ON_RESIZE, 'w');
      break;
   }
}

int _GetTBClipboardWID()
{
   int wid = _find_formobj('_tbclipboard_form', 'n');
   if(wid > 0 && _iswindow_valid(wid) && _tbIsWidActive(wid)) {
      return wid;
   }
   return 0;
}

void _UpdateClipboards()
{
   int wid = _GetTBClipboardWID();
   if (wid > 0) {
      orig_wid := p_window_id;
      last_mod := _clipboards_view_id.p_LastModified;
      activate_window(wid.p_active_form);
      if (last_mod != ctl_clipboard_preview.p_user) {
         _list_clipboards();
         ctl_clipboard_list.call_event(CHANGE_SELECTED, ctl_clipboard_list._TreeCurIndex(), ctl_clipboard_list.p_window_id, ON_CHANGE, 'W');
      }
      activate_window(orig_wid);
   }
}

void _switchbuf_tbclipbd(_str oldbuffname, _str flag)
{
   int formid = _find_object("_tbclipboard_form", 'n');
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
   formid._set_target_window(window_id);
}

