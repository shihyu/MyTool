////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47351 $
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
#include "tagsdb.sh"
#include "search.sh"
#import "cbrowser.e"
#import "codehelp.e"
#import "context.e"
#import "files.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "project.e"
#import "pushtag.e"
#import "search.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagrefs.e"
#import "tags.e"
#import "tagwin.e"
#import "tbautohide.e"
#import "tbcmds.e"
#import "toolbar.e"
#import "treeview.e"
#import "util.e"
#import "wkspace.e"
#require "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#endregion

using se.lang.api.LanguageSettings;

//////////////////////////////////////////////////////////////////////////////
// String constants for find symbol form search types
//
#define VS_TAG_FIND_TYPE_CONTEXT          "<Use Context Tagging"VSREGISTEREDTM">"
#define VS_TAG_FIND_TYPE_BUFFER_ONLY      "<Current File>"
#define VS_TAG_FIND_TYPE_PROJECT_ONLY     "<Current Project>"
#define VS_TAG_FIND_TYPE_WORKSPACE_ONLY   "<Current Workspace>"
#define VS_TAG_FIND_TYPE_EXTENSION        "<\"%s\" Tag Files>"
#define VS_TAG_FIND_TYPE_ECLIPSE          "<\"%s\" Eclipse Tag Files>"
#define VS_TAG_FIND_TYPE_EVERYWHERE       "<All Tag Files>"


//////////////////////////////////////////////////////////////////////////////
// ignore changes to search field, etc, used during initialization
static boolean  gIgnoreChange = false;


//////////////////////////////////////////////////////////////////////////////
// update timer delay and ID
#define FIND_SYMBOL_TIMER_DELAY_MS 100
static typeless gFindSymbolTimerId = -1;

/**
 * Kill the existing find symbol update timer.
 */
static void killFindSymbolTimer()
{
   if (gFindSymbolTimerId != -1) {
      _kill_timer(gFindSymbolTimerId);
      gFindSymbolTimerId=-1;
   }
}

/**
 * Re-start the find symbol update timer.
 * @param timer_cb   timer callback function {@see findSymbols}
 */
static void startFindSymbolTimer(typeless timer_cb)
{
   killFindSymbolTimer();
   int timer_delay=max(FIND_SYMBOL_TIMER_DELAY_MS,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
   gFindSymbolTimerId=_set_timer(timer_delay, timer_cb);
}


//////////////////////////////////////////////////////////////////////////////
// module initialization code
//
definit()
{
   gIgnoreChange = false;
   gFindSymbolTimerId = -1;
}
defload()
{
   _eventtab_modify_find_symbol(0);
}

//////////////////////////////////////////////////////////////////////////////
// Find Symbol tool window
//
defeventtab _tbfind_symbol_form;

//////////////////////////////////////////////////////////////////////////////
// CONSTRUCTION AND DESTRUCTION
//

/**
 * Copies the key bindings for the given command to the
 * current form, binding them to invoke the given window's
 * event.
 * 
 * @param command_name        name of command to look up
 * @param event_wid           window to get target event from
 * @param event               event (for example LBUTTON_UP)
 * @param keys                (output) array of key indices bound
 */
void copy_key_bindings_to_form(_str command_name, int event_wid, 
                               _str event, int (&keys)[])
{
   // get the event index for the target event
   int event_index = eventtab_index(event_wid.p_eventtab,event_wid.p_eventtab,event2index(event));
   if (!event_index) return;

   // get the key table index for default keys
   _str keytab_name = "default_keys";
   int ktab_index=find_index(keytab_name,EVENTTAB_TYPE);

   // find the bindings for the given command
   VSEVENT_BINDING bindings[];
   bindings._makeempty();
   int index = find_index(command_name, COMMAND_TYPE);
   list_bindings(ktab_index,bindings,index);

   // bind the key to the form's event table
   binding_names := "";
   int i,n = bindings._length();
   for (i=0; i<n; ++i) {
      index = bindings[i].binding;
      if (index && (name_type(index) & (COMMAND_TYPE|PROC_TYPE))) {
         keys[keys._length()] = bindings[i].iEvent;
         set_eventtab_index(event_wid.p_active_form.p_eventtab, bindings[i].iEvent, event_index);
         if (binding_names != "") binding_names = binding_names :+ ", ";
         binding_names = binding_names :+ event2name(index2event(bindings[i].iEvent),'L');
      }
   }

   if (binding_names != "" && (event_wid.p_object==OI_IMAGE || event_wid.p_object==OI_PICTURE_BOX)) {
      event_wid.p_message = event_wid.p_message " (" binding_names ")";
   }
}

/**
 * Copies the key bindings for the given command to the current form.
 * 
 * @param command_name        name of command to look up
 */
void copy_default_key_bindings(_str command_name)
{
   // get the key table index for default keys
   _str keytab_name = "default_keys";
   int ktab_index=find_index(keytab_name,EVENTTAB_TYPE);

   // find the bindings for the given command
   VSEVENT_BINDING bindings[];
   bindings._makeempty();
   int index = find_index(command_name, COMMAND_TYPE);
   list_bindings(ktab_index,bindings,index);

   // bind the key to the form's event table
   int i,n = bindings._length();
   for (i=0; i<n; ++i) {
      index = bindings[i].binding;
      if (index && (name_type(index) & (COMMAND_TYPE|PROC_TYPE))) {
         set_eventtab_index(p_active_form.p_eventtab, bindings[i].iEvent, index);
      }
   }
}

/**
 * Make this form respond to the same keys for push-tag and
 * find references that are set in the editor control
 */
static void createFindSymbolShortcuts()
{
   _nocheck _control ctl_search_for;
   _nocheck _control ctl_goto_symbol;
   _nocheck _control ctl_find_references;
   _nocheck _control ctl_show_in_classes;
   int keys[];
   copy_key_bindings_to_form("push_tag", ctl_goto_symbol,     LBUTTON_UP, keys);
   copy_key_bindings_to_form("find_tag", ctl_goto_symbol,     LBUTTON_UP, keys);
   copy_key_bindings_to_form("push_ref", ctl_find_references, LBUTTON_UP, keys);
   copy_key_bindings_to_form("find_refs",ctl_find_references, LBUTTON_UP, keys);
   copy_key_bindings_to_form("cb_find",  ctl_show_in_classes, LBUTTON_UP, keys);
   ctl_search_for.p_user = keys;
}

/**
 * Remove the bindings that were set up in
 * {@link createFindSymbolShortCuts()}, above.
 */
static void unbindFindSymbolShortcuts()
{
   _nocheck _control ctl_search_for;
   typeless keys = ctl_search_for.p_user;
   int i,n = keys._length();
   for (i=0; i<n; ++i) {
      set_eventtab_index(p_active_form.p_eventtab, keys[i], 0);
   }

   msg := "";
   parse ctl_goto_symbol.p_message with msg '(' .; 
   ctl_goto_symbol.p_message = msg;
   parse ctl_find_references.p_message with msg '(' .;
   ctl_find_references.p_message = msg;
   parse ctl_show_in_classes.p_message with msg '(' .;
   ctl_show_in_classes.p_message =msg;
}

/**
 * Callback for key binding / emulation changes
 */
void _eventtab_modify_find_symbol(typeless keytab_used, _str event="")
{
   int kt_index = find_index("default_keys", EVENTTAB_TYPE);
   if (keytab_used && kt_index != keytab_used) {
      return;
   }
   int wid = _tbGetWid("_tbfind_symbol_form");
   if (wid != 0) {
      wid.unbindFindSymbolShortcuts();
      wid.createFindSymbolShortcuts();
   }
}

/**
 * Initialize form and restore last values
 */
void ctl_search_for.on_create()
{
   // hide the progress indicator
   ctl_progress.p_visible=false;

   // save the expanded/collapsed state of the options
   gIgnoreChange=true;
   ctl_options_button._retrieve_value();
   showSearchOptions();

   // adjust alignment for auto-sized button
   ctl_filter_label.p_y = ctl_filter_button.p_y = ctl_regex_type.p_y + ctl_regex_type.p_height + 90;
   ctl_filter_label.p_x = ctl_filter_button.p_x + ctl_filter_button.p_width + 25;

   // set up the tree columns and restore the column widths
   ctl_symbols._TreeSetColButtonInfo(0, ctl_symbols.p_width/2, TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT, 1, "Symbol");
   ctl_symbols._TreeSetColButtonInfo(1, ctl_symbols.p_width/3, TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_FILENAME|TREE_BUTTON_IS_FILENAME, 1, "File");
   ctl_symbols._TreeSetColButtonInfo(2, ctl_symbols.p_width/4, TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_NUMBERS, 1, "Line");
   ctl_symbols._TreeRetrieveColButtonInfo();

   // restore previous searches and last search string
   ctl_search_for._retrieve_list();
   ctl_search_for._retrieve_value();

   // restore previous search scope and options
   ctl_lookin.updateLookinOptions();
   ctl_lookin._retrieve_value();
   if (ctl_lookin.p_text=="") {
      ctl_lookin._cbset_text(VS_TAG_FIND_TYPE_CONTEXT);
   }

   // restore regular expression types and last regex used
   ctl_regex_type.updateRegexTypes();
   ctl_regex_type._retrieve_value();
   if (ctl_regex_type.p_text == "") {
      if (def_re_search == VSSEARCHFLAG_BRIEFRE) {
         ctl_regex_type.p_text = RE_TYPE_BRIEF_STRING;
      } else if (def_re_search == VSSEARCHFLAG_RE) {
         ctl_regex_type.p_text = RE_TYPE_SLICKEDIT_STRING;
      } else if (def_re_search == VSSEARCHFLAG_WILDCARDRE) {
         ctl_regex_type.p_text = RE_TYPE_WILDCARD_STRING;
      } else if (def_re_search == VSSEARCHFLAG_PERLRE) {
         ctl_regex_type.p_text = RE_TYPE_PERL_STRING;
      } else {
         ctl_regex_type.p_text = RE_TYPE_UNIX_STRING;
      }
   }

   // restore whether or not regex search should be used
   ctl_use_regex._retrieve_value();
   if (!ctl_use_regex.p_value) {
      ctl_regex_type.p_enabled = false;
   }

   // restore case sensitivity option
   ctl_case_sensitive._retrieve_value();

   // restore substring match option
   ctl_substring._retrieve_value();

   // disable the buttons (no results yet)
   ctl_goto_symbol.p_enabled     = false;
   ctl_find_references.p_enabled = false;
   ctl_show_in_classes.p_enabled = false;

   // make this for respond to keys to control the preview window
   ctl_symbols._MakePreviewWindowShortcuts();

   // make this form respond to the same keys for push-tag and
   // find references that are set in the editor control
   createFindSymbolShortcuts();

   // finished
   gIgnoreChange=false;
}

/**
 * Save settings before destroying form
 */
void _tbfind_symbol_form.on_destroy()
{
   // save all the search form options
   ctl_symbols._TreeAppendColButtonInfo();
   ctl_lookin._append_retrieve(ctl_lookin, ctl_lookin.p_text);
   ctl_search_for._append_retrieve(ctl_search_for, ctl_search_for.p_text);
   ctl_use_regex._append_retrieve(ctl_use_regex, ctl_use_regex.p_value);
   ctl_regex_type._append_retrieve(ctl_regex_type, ctl_regex_type.p_text);
   ctl_options_button._append_retrieve(ctl_options_button, ctl_options_button.p_value);
   ctl_case_sensitive._append_retrieve(ctl_case_sensitive, ctl_case_sensitive.p_value);
   ctl_substring._append_retrieve(ctl_substring, ctl_substring.p_value);

   // unbind keys copied in for push_tag and push_ref shortcuts
   unbindFindSymbolShortcuts();

   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id,ON_DESTROY,'2');
}


//////////////////////////////////////////////////////////////////////////////
// RESIZING CODE
//

/**
 * Update the display / non-display of search options
 */
static void showSearchOptions()
{
   // get total form width
   int form_width = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   form_width -= 2*ctl_options_frame.p_x;

   // disable and hide search options if hidden
   boolean showControls = ( ctl_options_button.p_value == 1);
   ctl_case_sensitive.p_enabled = ctl_case_sensitive.p_visible = showControls;
   ctl_substring.p_enabled   = ctl_substring.p_visible   = showControls;
   ctl_use_regex.p_enabled      = ctl_use_regex.p_visible      = showControls;
   ctl_regex_type.p_enabled     = ctl_regex_type.p_visible     = showControls;
   ctl_filter_button.p_enabled  = ctl_filter_button.p_visible  = showControls;
   ctl_filter_label.p_enabled   = ctl_filter_label.p_visible   = showControls;

   // update options strings and height of options frame
   if ( showControls ) {
      // set the filter caption, size the controls so they look nice
      setFilterCaption();

      ctl_options_label.p_caption = "Search options";
      ctl_options_label.p_height = 300;
      ctl_options_frame.p_height = ctl_options_label.p_y + ctl_filter_label.p_y + ctl_filter_label.p_height;
   } else {
      _str search_options = getSearchOptionsString();
      int label_width = ctl_options_label.p_width;
      if (label_width <= 0) label_width=1;
      int num_lines = ctl_options_label._text_width(search_options) intdiv label_width;
      ctl_options_label.p_caption = search_options;
      ctl_options_label.p_height = (num_lines+1) * ctl_options_label._text_height();
      ctl_options_frame.p_height = ctl_options_label.p_y + ctl_options_label.p_y + ctl_options_label.p_height;
   }
}

static void setFilterCaption()
{
   _str filter_options = getFilterOptionsString();
   ctl_filter_label.p_caption  = filter_options;

   // figure out how many lines this is so we can position it nicely with the button
   curWidth := ctl_filter_label.p_width;
   curHeight := ctl_filter_label.p_height;
   ctl_filter_label.p_word_wrap = false;
   ctl_filter_label.p_auto_size = true;

   // is this longer than one line?
   oneLine := true;
   if (ctl_filter_label.p_width > curWidth) {
      oneLine = false;
   }
   autoHeight := ctl_filter_label.p_height;

   // put everything back the way it was
   ctl_filter_label.p_auto_size = false;
   ctl_filter_label.p_word_wrap = true;
   ctl_filter_label.p_width = curWidth;
   ctl_filter_label.p_height = curHeight;

   if (oneLine) {
      if (autoHeight > ctl_filter_button.p_height) {
         ctl_filter_label.p_y = ctl_filter_button.p_y;
      } else {
         ctl_filter_label.p_y = ctl_filter_button.p_y + ((ctl_filter_button.p_height - autoHeight) intdiv 2);
      }
   } else {
      ctl_filter_label.p_y = ctl_filter_button.p_y;
   }
}

/**
 * Calculate whether we are using horizontal or vertical orientation
 */
static boolean isHorizontalOrientation()
{
   // make sure form is wide enough
   int min_width = ctl_regex_type.p_width + ctl_regex_type.p_x + ctl_search_for.p_x*4;
   return (p_width >= min_width*2 && p_width >= p_height);
}

/**
 * Resize the width of the Find Symbol tool window
 */
static void resizeFrameWidths()
{
   padding := ctl_search_for.p_x;

   // make sure form is wide enough
   int min_width = ctl_regex_type.p_width + ctl_regex_type.p_x + padding * 4;
   if (!tbIsWidDocked(p_active_form) && p_width < min_width) {
      p_width = min_width;
   }

   width := p_width;
   height := p_height;

   // horizontal or vertical layout
   int width_left  = width - 2 * padding;
   int width_right = width - 2 * padding;
   int x_right     = padding;
   if (isHorizontalOrientation()) {
      width_right = ctl_regex_type.p_width + ctl_regex_type.p_x + ctl_regex_type;
      width_left  = width - width_right - ctl_search_for.p_x*3;
      x_right = width - width_right - ctl_search_for.p_x;
   }

   // move the right hand side controls into place
   ctl_lookin_label.p_x = x_right;
   ctl_lookin.p_x = x_right;
   ctl_options_frame.p_x = x_right;
   ctl_goto_symbol.p_x = x_right;
   ctl_find_references.p_x = x_right + ctl_goto_symbol.p_width + ctl_search_for.p_x*2;
   ctl_show_in_classes.p_x = x_right;

   // stretch controls to full width of form
   int orig_tree_width = ctl_symbols.p_width;
   ctl_symbols.p_width = width_left;
   ctl_lookin.p_width = width_right;
   ctl_options_frame.p_width = width_right;
   ctl_options_label.p_width = ctl_options_frame.p_width - ctl_options_label.p_x;
   ctl_filter_label.p_width  = ctl_options_frame.p_width - ctl_filter_label.p_x;

   sizeBrowseButtonToTextBox(ctl_search_for.p_window_id, _re_button.p_window_id,
                             0, ctl_symbols.p_x + ctl_symbols.p_width);

   // position progress control
   ctl_progress.p_x     = ctl_search_for_label.p_x + ctl_search_for_label.p_width + ctl_filter_button.p_x;
   ctl_progress.p_width = width_left - ctl_progress.p_x;

   // scale tree buttons if the form has changed in size
   ctl_symbols._TreeScaleColButtonWidths(orig_tree_width);

   // right-justify command buttons
   ctl_goto_symbol.p_x     = width - 4*(ctl_search_for.p_x + ctl_goto_symbol.p_width);
   ctl_find_references.p_x = width - 3*(ctl_search_for.p_x + ctl_goto_symbol.p_width);
   ctl_show_in_classes.p_x = width - 2*(ctl_search_for.p_x + ctl_goto_symbol.p_width);
   ctl_tag_files.p_x       = width - 1*(ctl_search_for.p_x + ctl_goto_symbol.p_width);
}

/**
 * Resize the height of the Find Symbol tool window
 */
static void resizeFrameHeights()
{
   // force the search options to collapse/expand if needed
   showSearchOptions();
   padding := ctl_search_for_label.p_x;

   // horizontal or vertical layout?
   int y_bottom_left = p_height;
   int y_top_right = ctl_search_for_label.p_y;
   if (!isHorizontalOrientation()) {
      y_bottom_left = p_height;
      y_bottom_left -= (ctl_options_frame.p_y   - ctl_lookin_label.p_y);
      y_bottom_left -= ctl_options_frame.p_height;
      y_bottom_left -= ctl_search_for_label.p_y;
      y_bottom_left -= (ctl_show_in_classes.p_height + padding);
      y_top_right   = y_bottom_left;
   }

   // adjust height of symbol list (which is only stretchy part vertically)
   int symbols_height = y_bottom_left - ctl_symbols.p_y - ctl_search_for_label.p_y;
   if (symbols_height < 900) {
      y_top_right -= symbols_height;
      symbols_height = 900;
      y_top_right += 900;
   }
   ctl_symbols.p_height = symbols_height;

   // adjust location of options frame and buttons
   ctl_lookin_label.p_y    = y_top_right;
   ctl_lookin.p_y          = y_top_right+ctl_lookin_label.p_height+ctl_search_for_label.p_y;
   ctl_options_frame.p_y   = ctl_lookin.p_y+ctl_lookin.p_height;
   ctl_goto_symbol.p_y     = ctl_options_frame.p_y+ctl_options_frame.p_height+ctl_search_for_label.p_y;
   ctl_find_references.p_y = ctl_goto_symbol.p_y;
   ctl_show_in_classes.p_y = ctl_goto_symbol.p_y;
   ctl_tag_files.p_y       = ctl_goto_symbol.p_y;

   int diff = p_height - (ctl_show_in_classes.p_y + ctl_show_in_classes.p_height + padding);
   if (diff < 0 && !tbIsWidDocked(p_active_form)) {
      p_height -= diff;
   }
}

/**
 * Handle resizing of the Find Symbol tool window
 */
void _tbfind_symbol_form.on_resize()
{
   // if the minimum width has not been set, it will return 0
   if (!tbIsWidDocked(p_active_form) && !_minimum_width()) {
      int min_width = ctl_regex_type.p_width + ctl_regex_type.p_x + ctl_search_for.p_x * 4;
      _set_minimum_size(min_width, -1);
   }

   resizeFrameWidths();
   resizeFrameHeights();
}


//////////////////////////////////////////////////////////////////////////////
// SEARCH TEXT BOX CONTROL
//

/**
 * Reset timer to do search if text changes.
 */
void ctl_search_for.on_change(int reason)
{
   updateSearchResultsDelayed();
}

/**
 * Hide the find symbol form after user hits enter
 */
static void maybeHideFindSymbol()
{
   tagwin_wid := _tbGetWid("_tbfind_symbol_form");
   if (tagwin_wid) _tbDismiss(tagwin_wid);
}

/**
 * If they press "Enter", then jump to the first match
 */
void ctl_search_for.enter()
{
   if (gFindSymbolTimerId >= 0) {
      updateSearchResultsNoDelay();
   }
   if (ctl_symbols._TreeGetFirstChildIndex(TREE_ROOT_INDEX) < 0) {
      // do nothing
   } else if (ctl_symbols._TreeGetNumChildren(TREE_ROOT_INDEX) == 1) {
      call_event(ctl_goto_symbol.p_window_id, LBUTTON_UP);
      maybeHideFindSymbol();
   } else {
      ctl_symbols._set_focus();
   }
}

/**
 * When the search list gets focus, update it's history information
 */
void ctl_search_for.on_got_focus()
{
   if( ctl_search_for._ComboBoxListVisible() ) {
      // Do not attempt to update the list (and as a result p_text) if
      // the user is in the middle of selecting from the drop-down list.
      return;
   }
   ctl_search_for._lbclear();
   ctl_search_for._retrieve_list();
   ctl_search_for.p_sel_start  = 1;
   ctl_search_for.p_sel_length = p_text._length();
}

/**
 * When the list of symbols gets focus, immediately update the
 * currently selected item.
 */
void ctl_symbols.on_got_focus()
{
   if (gFindSymbolTimerId >= 0) {
      updateSearchResultsNoDelay();
   }
   call_event(CHANGE_SELECTED, ctl_symbols._TreeCurIndex(), ctl_symbols.p_window_id, ON_CHANGE, 'w');
}

void ctl_symbols.rbutton_up()
{
   // Get handle to menu:
   int index=find_index("_tagbookmark_menu",oi2type(OI_MENU));
   int menu_handle=p_active_form._menu_load(index,'P');

   // configure it for this dialog use
   int flags=def_find_symbol_flags;
   pushTgConfigureMenu(menu_handle, flags, false, false, false, true);

   VS_TAG_BROWSE_INFO cm;
   int status = p_active_form.getSelectedSymbol(cm);
   if (!status && cm.member_name != '') {
      // add specific items for Find Symbol tool window
      _menu_insert(menu_handle, 0, MF_ENABLED, '-');
      _menu_insert(menu_handle, 0, MF_ENABLED, "Show "cm.member_name" in symbol browser", "tag_find_symbol_show_in_class_browser");  
      _menu_insert(menu_handle, 0, MF_ENABLED, "Go to references to "cm.member_name, "tag_find_symbol_show_references");  
   }

   // Show menu:
   int x,y;
   mou_get_xy(x,y);
   _KillToolButtonTimer();
   call_list("_on_popup2", translate("_tagbookmark_menu", "_", "-"), menu_handle);
   status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}


//////////////////////////////////////////////////////////////////////////////
// SCOPE TO LOOK IN
//

/**
 * Update the search results if look-in scope changes.
 */
void ctl_lookin.on_change(int reason)
{
   updateSearchResultsDelayed();
}

/**
 * Update the list of tag files or tag file groups to look in
 */
static void updateLookinOptions()
{
   // prevent form from searching when then items are inserted
   boolean origIgnoreChange = gIgnoreChange;
   gIgnoreChange=true;

   // put in the standard, top four search types
   origText := p_text;
   _lbclear();
   _lbadd_item(VS_TAG_FIND_TYPE_CONTEXT);
   _lbadd_item(VS_TAG_FIND_TYPE_BUFFER_ONLY);
   _lbadd_item(VS_TAG_FIND_TYPE_PROJECT_ONLY);
   _lbadd_item(VS_TAG_FIND_TYPE_WORKSPACE_ONLY);

   // put in the current file extension first
   _str cur_mode_name = "";
   if (!_no_child_windows()) {
      cur_mode_name = _mdi.p_child.p_mode_name;
      if (cur_mode_name != '') {
         _str lang = _mdi.p_child.p_LangId;
         if (LanguageSettings.getTagFileList(lang)!='') {
            _lbadd_item(nls(VS_TAG_FIND_TYPE_EXTENSION,cur_mode_name));
         }
      }
   }

   // special case "C" tag files (for compiler tag files)
   typeless tag_files = tags_filename("c");
   if (tag_files != "") {
      _lbadd_item(nls(VS_TAG_FIND_TYPE_EXTENSION,'C'));
   }

   // add language-specific tag files
   _str langTagFilesTable:[];
   LanguageSettings.getTagFileListTable(langTagFilesTable);
   foreach (auto langId => . in langTagFilesTable) {

      mode_name := _LangId2Modename(langId);
      if (mode_name != cur_mode_name && mode_name != "C" && mode_name != "C/C++") {
         _lbadd_item(nls(VS_TAG_FIND_TYPE_EXTENSION,mode_name));
      }
   }

   // now put in the Eclipse Java / C tag files
   if(isEclipsePlugin()) {
      tag_files = _GetEclipseTagFiles("java");
      if (tag_files != "") {
         _lbadd_item(nls(VS_TAG_FIND_TYPE_ECLIPSE,"Java"));
      }
      tag_files = _GetEclipseTagFiles("c");
      if (tag_files != "") {
         _lbadd_item(nls(VS_TAG_FIND_TYPE_ECLIPSE,"C"));
      }
   }

   // now put in the compiler tags file names
   tag_files = compiler_tags_filename('c');
   _str filename=next_tag_file(tag_files,true);
   while (filename != '') {
      _lbadd_item(filename);
      filename=next_tag_file(tag_files,false);
   }

   // Finally, put in inidividual tag files
   tag_files = tags_filenamea();
   for (i:=0; i<tag_files._length(); ++i) {
      _lbadd_item(maybe_quote_filename(tag_files[i]));
   }
   
   // now put in an option to search All tag files
   _lbadd_item(VS_TAG_FIND_TYPE_EVERYWHERE);

   // now restore the original combo box text
   if (origText != "") {
      _cbset_text(origText);
   }

   // restore the ignore changes flag
   gIgnoreChange=origIgnoreChange;
}

/**
 * Look-in options could change if the current buffer changes
 */
void _switchbuf_find_symbol()
{
   int wid = _tbGetWid("_tbfind_symbol_form");
   if (wid != 0) {
      wid.ctl_lookin.updateLookinOptions();
   }
}

/**
 * Look-in options could change if tag files are added or removed
 */
void _TagFileAddRemove_find_symbol(_str file_name, _str options)
{
   int wid = _tbGetWid("_tbfind_symbol_form");
   if (wid != 0) {
      wid.ctl_lookin.updateLookinOptions();
   }
}

static _str getFirstFileExtension(_str tag_file)
{
   // open database
   status := tag_read_db(tag_file);
   if (status < 0) return '';

   // retrieve the first file extension type
   status = tag_find_language(auto lang);
   if (status) {
      tag_reset_find_language();
      return '';
   }

   // check for reject file extensions
   if (lang=='tagdoc') {
      status = tag_next_language(lang);
      if (status) {
         lang = _Ext2LangId(_strip_filename(tag_file,'pe'));
      }
   }

   // more than one file type in this tag file
   // can't just pick one
   tag_reset_find_language();
   return lang;
}

/**
 * @return Return an array of tag files to look in for the
 *         currently selected search context.  This may or may
 *         not include the workspace tag files and the current
 *         buffer.
 * 
 * @param lang          p_LangId for current buffer
 * @param buffer_name   p_buf_name for current buffer
 * @param use_buffer    (reference) true if we should search current buffer
 */
static typeless getTagFilesToLookin(_str &lang, 
                                    _str buffer_name,
                                    boolean &use_buffer)
{
   // initially empty array of tag files to return
   _str tag_files[];
   tag_files._makeempty();

   _str lookin = ctl_lookin.p_text;
   switch (lookin) {
   case VS_TAG_FIND_TYPE_CONTEXT:
      // context includes buffer and extension specific tag files
      use_buffer=true;
      return tags_filenamea(lang);

   case VS_TAG_FIND_TYPE_BUFFER_ONLY:
      // just buffer (no tag files)
      use_buffer=true;
      if (_isEditorCtl()) lang=p_LangId;
      return tag_files;

   case VS_TAG_FIND_TYPE_WORKSPACE_ONLY:
      // in workspace only, include buffer if it is in the workspace
      if (_project_name!='' && _WorkspaceFindFile(buffer_name) != "") {
         use_buffer = true;
      }
      tag_files[0] = project_tags_filename();
      lang = getFirstFileExtension(tag_files[0]);
      return tag_files;

   case VS_TAG_FIND_TYPE_PROJECT_ONLY:
      // in current project only, include buffer if it is in the workspace
      if (_project_name!='' && _projectFindFile(_workspace_filename, _project_name, _RelativeToProject(buffer_name)) != "") {
         use_buffer = true;
      }
      tag_files[0] = project_tags_filename();
      lang = getFirstFileExtension(tag_files[0]);
      return tag_files;

   case VS_TAG_FIND_TYPE_EVERYWHERE:
      // in all tag files, include the buffer too, why not?
      use_buffer=true;
      return ctl_lookin.tags_filenamea("");

   default:
      // look in a specific tag file, ignore the current buffer
      if (first_char(lookin)=='<') {
         _str mode_name = "";
         parse lookin with "<\"" mode_name "\"" .;
         _str selected_lang = _Modename2LangId(mode_name);
         if (lang==selected_lang) use_buffer = true;
         lang=selected_lang;
         return tags_filenamea(selected_lang);
      }
      tag_files[0] = lookin;
      lang = getFirstFileExtension(tag_files[0]);
      return tag_files;
   }
}


//////////////////////////////////////////////////////////////////////////////
// SYMBOL LIST
//

/**
 * Jump to selected symbol on double click or ENTER
 */
void ctl_symbols.lbutton_double_click()
{
   call_event(ctl_goto_symbol.p_window_id, LBUTTON_UP);
   maybeHideFindSymbol();
}
void ctl_symbols.ENTER()
{
   call_event(ctl_goto_symbol.p_window_id, LBUTTON_UP);
   maybeHideFindSymbol();
}

/**
 * Update property view and preview of the currently selected symbol
 */
static void updateSymbolPreview()
{
   int wid = _tbGetWid("_tbfind_symbol_form");
   if (wid != 0) {
      VS_TAG_BROWSE_INFO cm;
      int status = wid.getSelectedSymbol(cm);
      if (!status) {
         cb_refresh_output_tab(cm, true, true, false, APF_FIND_SYMBOL);
         cb_refresh_property_view(cm);
      }
   }
   killFindSymbolTimer();
}

/**
 * Preview symbol when paging through list.
 */
void ctl_symbols.on_change(int reason,int index)
{
   if (reason == CHANGE_SELECTED) {
      VS_TAG_BROWSE_INFO cm;
      int status = getSelectedSymbol(cm);
      if (!status) {
         startFindSymbolTimer(updateSymbolPreview);
      }
   } else if (reason == CHANGE_LEAF_ENTER) {
      call_event(ctl_goto_symbol.p_window_id, LBUTTON_UP);
      maybeHideFindSymbol();
   }
}

void ctl_symbols.on_highlight(int index, _str caption="")
{
   if (index < 0 || !def_tag_hover_delay) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   struct VS_TAG_BROWSE_INFO cm = _TreeGetUserInfo(index);
   _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
}

/**
 * Remove all items from the symbol list
 */
static void clearSymbolList()
{
   ctl_symbols._TreeDelete(TREE_ROOT_INDEX, 'C');
   ctl_symbols._TreeRefresh();
}

/**
 * Insert the current match set into the symbol list
 */
static void updateSymbolList(_str word, _str substring_word)
{
   // hash table for results we have already seen
   boolean been_there_done_that:[];
   been_there_done_that._makeempty();

   // caption and picture flags
   _str caption='';
   int leaf_flag=0;
   int pic_member=0;
   int i_access=0;
   int i_type=0;

   // get the regular expression options
   boolean case_sensitive  = ctl_case_sensitive.p_value >= 1;
   boolean substring       = ctl_substring.p_value >= 1;
   _str regex_options = getRegexSearchOption();
   _str case_options  = case_sensitive? 'e':'i';

   // make sure that symbol browser bitmaps are loaded and ready
   // and prepare tree for expansion
   cb_prepare_expand(p_active_form,ctl_symbols.p_window_id,TREE_ROOT_INDEX);
   ctl_symbols._TreeBeginUpdate(TREE_ROOT_INDEX);

   // for each symbol in the match set
   struct VS_TAG_BROWSE_INFO cm;
   int i=0,k=0,n = tag_get_num_of_matches();
   for (i=1; i<=n; ++i) {

      // get the symbol information
      tag_get_match_info(i, cm);

      // check if they hit escape or another key
      if ( (i%100)==0 && _IsKeyPending()) {
         break;
      }

      // limit results to items in current project?
      if (ctl_lookin.p_text == VS_TAG_FIND_TYPE_PROJECT_ONLY) {
         if (_project_name == '') continue;
         if (_projectFindFile(_workspace_filename, _project_name, _RelativeToProject(cm.file_name)) == "") {
            continue;
         }
      }

      // make sure that the word matches the substring or entire word
      if (substring || regex_options!="") {
         int sub_pos = 1;
         int word_pos = 1;
         if (substring_word!="") {
            sub_pos  = pos(substring_word, cm.member_name, 1, case_options:+regex_options);
         }
         if (word != "") {
            word_pos = pos(word, cm.member_name, 1, case_options:+regex_options);
         }
         if (sub_pos==0 && word_pos==0) {
            continue;
         }
         if (!substring && sub_pos!=1 && word_pos!=1) {
            continue;
         }
      }

      // make a caption for this symbol, including file name and line number
      caption = tag_tree_make_caption_fast(VS_TAGMATCH_match, i, true, true, false);
      caption = caption:+"\t":+cm.file_name:+"\t":+cm.line_no;

      // check if we have already added this item
      if (been_there_done_that._indexin(caption)) continue;
      been_there_done_that:[caption]=true;

      // select the symbol browser bitmap to show for this symbol
      tag_tree_filter_member2(0,0,cm.type_name,(cm.class_name!='')?1:0,cm.flags,i_access,i_type);
      tag_tree_select_bitmap(i_access,i_type,leaf_flag,pic_member);

      // add it to the tree and store symbol info in user info
      k=ctl_symbols._TreeAddItem(TREE_ROOT_INDEX, caption, 
                                 TREE_ADD_AS_CHILD, 
                                 pic_member, pic_member, TREE_NODE_LEAF, 0, cm);
   }

   // finished updating, now sort tree, jump to top, and refresh
   ctl_symbols._TreeEndUpdate(TREE_ROOT_INDEX);
   ctl_symbols._TreeSortCol();
   ctl_symbols._TreeTop();
   ctl_symbols._TreeRefresh();

   // disable/enable buttons
   boolean enabled = (k > 0);
   ctl_goto_symbol.p_enabled     = enabled;
   ctl_find_references.p_enabled = enabled;
   ctl_show_in_classes.p_enabled = enabled;
}

/**
 * Get the symbol information for the item currently selected
 * in the symbol list.
 * 
 * @param cm   (reference) set to symbol information for item
 * 
 * @return 0 on success, <0 on error.
 */
static int getSelectedSymbol(VS_TAG_BROWSE_INFO& cm)
{
   // save this symbol in the search history
   _append_retrieve(ctl_search_for, ctl_search_for.p_text);

   // get the currently selected item
   tag_browse_info_init(cm);
   int index = ctl_symbols._TreeCurIndex();
   if (index <= 0) {
      return STRING_NOT_FOUND_RC;
   }

   // browse info is stored in the user info
   cm = ctl_symbols._TreeGetUserInfo(index);
   if (cm == null) return STRING_NOT_FOUND_RC;

   // success
   return 0;
}


//////////////////////////////////////////////////////////////////////////////
// SEARCH OPTIONS GROUP
//

/**
 * @return Return a string representing the search options
 */
static _str getSearchOptionsString()
{
   // case sensitivity
   _str label="Search options: ";
   switch (ctl_case_sensitive.p_value) {
   case 0:
      label = label:+"Ignore case, ";
      break;
   case 1:
      label = label:+"Match case, ";
      break;
   case 2:
      // no label for both
      break;
   }

   // prefix or substring match
   switch (ctl_substring.p_value) {
   case 0:
      label = label:+"Prefix, ";
      break;
   case 1:
      label = label:+"Substring, ";
      break;
   case 2:
      // no label for both
      break;
   }

   // regular expression type
   if (ctl_use_regex.p_value) {
      label = label:+ctl_regex_type.p_text:+", ";
   }

   // symbol filters
   label = label:+getFilterOptionsString();
   return label;
}

/**
 * Toggle the search options as expanded or collapsed
 */
void ctl_options_button.lbutton_up()
{
   if (gIgnoreChange) {
      return;
   }
   p_value = (p_value==0)? 1:0;
   showSearchOptions();
   if (p_user == p_value) {
      return;
   }
   p_active_form.resizeFrameHeights();
   p_user = p_value;
}


//////////////////////////////////////////////////////////////////////////////
// CASE SENSITIVE CHECK BOX
//

void ctl_case_sensitive.lbutton_up()
{
   updateSearchResultsDelayed();
}

//////////////////////////////////////////////////////////////////////////////
// SUBSTRING MATCH CHECK BOX
//

void ctl_substring.lbutton_up()
{
   updateSearchResultsDelayed();
}


//////////////////////////////////////////////////////////////////////////////
// REGULAR EXPRESSION OPTIONS
//

/**
 * @return Return the search option (needed by {@link pos()} for the
 * selected regular expression.  (Unix='r', Brief='b', SlickEdit='r', 
 * and Wildcards='&').
 */
static _str getRegexSearchOption()
{
   if (ctl_use_regex.p_value == 0) {
      return '';
   }
   switch (ctl_regex_type.p_text) {
   case RE_TYPE_UNIX_STRING:        return 'u';
   case RE_TYPE_BRIEF_STRING:       return 'b';
   case RE_TYPE_SLICKEDIT_STRING:   return 'r';
   case RE_TYPE_PERL_STRING:        return 'l';
   case RE_TYPE_WILDCARD_STRING:    return '&';
   }
   return '';
}

/**
 * A change in regular expression types requires a symbol update
 */
void ctl_regex_type.on_change(int reason)
{
   if (reason == CHANGE_SELECTED && ctl_use_regex.p_value) {
      updateSearchResultsDelayed();
   }
}

/**
 * Initialize the list of regular expression types
 */
static void updateRegexTypes()
{
   boolean origIgnoreChange = gIgnoreChange;
   gIgnoreChange = true;
   _lbadd_item(RE_TYPE_UNIX_STRING);
   _lbadd_item(RE_TYPE_BRIEF_STRING);
   _lbadd_item(RE_TYPE_SLICKEDIT_STRING);
   _lbadd_item(RE_TYPE_PERL_STRING);
   _lbadd_item(RE_TYPE_WILDCARD_STRING);
   gIgnoreChange = origIgnoreChange;
}

/**
 * Turning on/off regular expression search forces a refresh
 */
void ctl_use_regex.lbutton_up()
{
   _re_button.p_enabled = ctl_regex_type.p_enabled = (p_value != 0);
   updateSearchResultsDelayed();
}


//////////////////////////////////////////////////////////////////////////////
// SYMBOL FILTER OPTIONS
//

/**
 * Shortcut to expand or collapse search options
 */
void _tbfind_symbol_form.'A-O'()
{
   int orig_wid = p_window_id;
   p_window_id = ctl_options_button.p_window_id;
   call_event(ctl_options_button.p_window_id, LBUTTON_UP);
   p_window_id = orig_wid;
}

/**
 * When the filter button is pressed, display the tag filter menu
 */
void ctl_filter_button.lbutton_up()
{
   // Get handle to menu:
   int orig_wid = p_window_id;
   int index=find_index("_tagbookmark_menu",oi2type(OI_MENU));
   int menu_handle=p_active_form._menu_load(index,'P');

   // configure it for this dialog use
   int flags=def_find_symbol_flags;
   pushTgConfigureMenu(menu_handle, flags, false, false, false, true);

   // Show menu:
   int x=0, y=0;
   mou_get_xy(x,y);
   _KillToolButtonTimer();
   int status=_menu_show(menu_handle,VPM_LEFTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
   p_window_id = orig_wid;
   p_value=0;
}

/**
 * If the filter options change, refresh the tag list
 */
void ctl_filter_button.on_change()
{
   // set the filter caption, size the controls so they look nice
   setFilterCaption();
   updateSearchResultsDelayed();
}

/**
 * @return Return a string representing the tag filtering options.
 */
static _str getFilterOptionsString()
{
   _str label = "Filters: ";
   _str positive_label = "";
   _str negative_label = "";
   int pflags = def_find_symbol_flags;  // for positive tests
   int nflags = def_find_symbol_flags;  // for negative tests

   // check if all the filters are turned on
   if ((pflags & VS_TAGFILTER_ANYTHING) == VS_TAGFILTER_ANYTHING) {
      label = label:+"All symbol types";
      return label;
   }

   // general categories for function types
   if ((pflags & VS_TAGFILTER_ANYPROC) == VS_TAGFILTER_ANYPROC) {
      positive_label = positive_label:+", All Functions";
      pflags &= ~VS_TAGFILTER_ANYPROC;
   } else if ((nflags & VS_TAGFILTER_ANYPROC) == 0) {
      negative_label = negative_label:+", No functions";
      nflags |= VS_TAGFILTER_ANYPROC;
   } else {
      if (pflags & VS_TAGFILTER_PROC) {
         positive_label = positive_label:+", Procs";
      }
      if ((nflags & VS_TAGFILTER_PROC) == 0) {
         negative_label = negative_label:+", No Procs";
      }

      if (pflags & VS_TAGFILTER_PROTO) {
         positive_label = positive_label:+", Prototypes";
      }
      if ((nflags & VS_TAGFILTER_PROTO) == 0) {
         negative_label = negative_label:+", No Prototypes";
      }

      if (pflags & VS_TAGFILTER_SUBPROC) {
         positive_label = positive_label:+", Subprocs";
      }
      if ((nflags & VS_TAGFILTER_SUBPROC) == 0) {
         negative_label = negative_label:+", No Subprocs";
      }
   }

   // general categories for variables
   if ((pflags & VS_TAGFILTER_ANYDATA) == VS_TAGFILTER_ANYDATA) {
      positive_label = positive_label:+", Variables";
      pflags &= ~VS_TAGFILTER_ANYDATA;
   } else if ((nflags & VS_TAGFILTER_ANYDATA) == 0) {
      negative_label = negative_label:+", No variables";
      nflags |= VS_TAGFILTER_ANYDATA;
   } else {
      if (pflags & VS_TAGFILTER_GVAR) {
         positive_label = positive_label:+", Global Variables";
      }
      if ((nflags & VS_TAGFILTER_GVAR) == 0) {
         negative_label = negative_label:+", No Global Variables";
      }

      if (pflags & VS_TAGFILTER_VAR) {
         positive_label = positive_label:+", Member Variables";
      }
      if ((nflags & VS_TAGFILTER_VAR) == 0) {
         negative_label = negative_label:+", No Member Variables";
      }

      if (pflags & VS_TAGFILTER_LVAR) {
         positive_label = positive_label:+", Local Variables";
      }
      if ((nflags & VS_TAGFILTER_LVAR) == 0) {
         negative_label = negative_label:+", No Local Variables";
      }

      if (pflags & VS_TAGFILTER_PROPERTY) {
         positive_label = positive_label:+", Properties";
      }
      if ((nflags & VS_TAGFILTER_PROPERTY) == 0) {
         negative_label = negative_label:+", No Properties";
      }
   }

   // general categories for classes
   if ((pflags & VS_TAGFILTER_ANYSTRUCT) == VS_TAGFILTER_ANYSTRUCT) {
      positive_label = positive_label:+", Structs and classes";
      pflags &= ~VS_TAGFILTER_ANYSTRUCT;
   } else if ((nflags & VS_TAGFILTER_ANYDATA) == 0) {
      negative_label = negative_label:+", No Structs or classes";
      nflags |= VS_TAGFILTER_ANYSTRUCT;
   } else {
      if (pflags & VS_TAGFILTER_STRUCT) {
         positive_label = positive_label:+", Structs";
      }
      if ((nflags & VS_TAGFILTER_STRUCT) == 0) {
         negative_label = negative_label:+", No Structs";
      }

      if (pflags & VS_TAGFILTER_UNION) {
         positive_label = positive_label:+", Unions";
      }
      if ((nflags & VS_TAGFILTER_UNION) == 0) {
         negative_label = negative_label:+", No Unions";
      }

      if (pflags & VS_TAGFILTER_INTERFACE) {
         positive_label = positive_label:+", Interfaces";
      }
      if ((nflags & VS_TAGFILTER_INTERFACE) == 0) {
         negative_label = negative_label:+", No Interfaces";
      }
   }

   // general categories for classes
   if ((pflags & VS_TAGFILTER_ANYCONSTANT) == VS_TAGFILTER_ANYCONSTANT) {
      positive_label = positive_label:+", Defines and constants";
      pflags &= ~VS_TAGFILTER_ANYCONSTANT;
   } else if ((nflags & VS_TAGFILTER_ANYDATA) == 0) {
      negative_label = negative_label:+", No Defines or constants";
      nflags |= VS_TAGFILTER_ANYCONSTANT;
   } else {
      if (pflags & VS_TAGFILTER_DEFINE) {
         positive_label = positive_label:+", Defines";
      }
      if ((nflags & VS_TAGFILTER_DEFINE) == 0) {
         negative_label = negative_label:+", No Defines";
      }

      if (pflags & VS_TAGFILTER_ENUM) {
         positive_label = positive_label:+", Enums";
      }
      if ((nflags & VS_TAGFILTER_ENUM) == 0) {
         negative_label = negative_label:+", No Enums";
      }

      if (pflags & VS_TAGFILTER_CONSTANT) {
         positive_label = positive_label:+", Constants";
      }
      if ((nflags & VS_TAGFILTER_CONSTANT) == 0) {
         negative_label = negative_label:+", No Constants";
      }
   }

   // set up states of the rest of the flags
   if (pflags & VS_TAGFILTER_TYPEDEF) {
      positive_label = positive_label:+", Typedefs";
   }
   if ((nflags & VS_TAGFILTER_TYPEDEF) == 0) {
      negative_label = negative_label:+", No Typedefs";
   }

   if (pflags & VS_TAGFILTER_LABEL) {
      positive_label = positive_label:+", Labels";
   }
   if ((nflags & VS_TAGFILTER_LABEL) == 0) {
      negative_label = negative_label:+", No Labels";
   }

   if (pflags & VS_TAGFILTER_PACKAGE) {
      positive_label = positive_label:+", Packages";
   }
   if ((nflags & VS_TAGFILTER_PACKAGE) == 0) {
      negative_label = negative_label:+", No Packages";
   }

   if (pflags & VS_TAGFILTER_DATABASE) {
      positive_label = positive_label:+", Databases";
   }
   if ((nflags & VS_TAGFILTER_DATABASE) == 0) {
      negative_label = negative_label:+", No Databases";
   }

   if (pflags & VS_TAGFILTER_GUI) {
      positive_label = positive_label:+", Forms";
   }
   if ((nflags & VS_TAGFILTER_GUI) == 0) {
      negative_label = negative_label:+", No Forms";
   }

   if (pflags & VS_TAGFILTER_INCLUDE) {
      positive_label = positive_label:+", Includes";
   }
   if ((nflags & VS_TAGFILTER_INCLUDE) == 0) {
      negative_label = negative_label:+", No Includes";
   }

   if (pflags & VS_TAGFILTER_ANNOTATION) {
      positive_label = positive_label:+", Annotations";
   }
   if ((nflags & VS_TAGFILTER_ANNOTATION) == 0) {
      negative_label = negative_label:+", No Annotations";
   }

   if (pflags & VS_TAGFILTER_UNKNOWN) {
      positive_label = positive_label:+", Unrecognized.";
   }
   if ((nflags & VS_TAGFILTER_UNKNOWN) == 0) {
      negative_label = negative_label:+", No Unrecognized Symbols";
   }

   if (pflags & VS_TAGFILTER_MISCELLANEOUS) {
      positive_label = positive_label:+", Misc.";
   }
   if ((nflags & VS_TAGFILTER_MISCELLANEOUS) == 0) {
      negative_label = negative_label:+", No Misc. Symbols";
   }

   // trim off leading commas
   positive_label = strip(positive_label, 'L', ', ');
   negative_label = strip(negative_label, 'L', ', ');

   // choose the lesser of two evils
   if (length(positive_label) <= length(negative_label)) {
      label = label:+positive_label;
   } else {
      label = label:+negative_label;
   }

   // absolutely no scope limitations?
   if ((pflags & VS_TAGFILTER_ANYSCOPE) == VS_TAGFILTER_ANYSCOPE) {
      return label;
   }

   // member access restrictions
   moreLabel := '';
   if ((pflags & VS_TAGFILTER_ANYACCESS) == VS_TAGFILTER_SCOPE_PUBLIC) {
      moreLabel = moreLabel:+", Public";
   } else if ((pflags & VS_TAGFILTER_ANYACCESS) == VS_TAGFILTER_SCOPE_PROTECTED) {
      moreLabel = moreLabel:+", Protected";
   } else if ((pflags & VS_TAGFILTER_ANYACCESS) == VS_TAGFILTER_SCOPE_PRIVATE) {
      moreLabel = moreLabel:+", Private";
   } else if ((pflags & VS_TAGFILTER_ANYACCESS) == VS_TAGFILTER_SCOPE_PACKAGE) {
      moreLabel = moreLabel:+", Package scope";
   } else if ((pflags & VS_TAGFILTER_ANYACCESS) == 0) {
      moreLabel = moreLabel:+", No access";
   } else {
      if (!(pflags & VS_TAGFILTER_SCOPE_PUBLIC)) {
         moreLabel = moreLabel:+", No public";
      }
      if (!(pflags & VS_TAGFILTER_SCOPE_PROTECTED)) {
         moreLabel = moreLabel:+", No protected";
      }
      if (!(pflags & VS_TAGFILTER_SCOPE_PRIVATE)) {
         moreLabel = moreLabel:+", No private";
      }
      if (!(pflags & VS_TAGFILTER_SCOPE_PACKAGE)) {
         moreLabel = moreLabel:+", No package scope";
      }
   }

   // static vs. non-static
   if (pflags & VS_TAGFILTER_SCOPE_STATIC) {
      moreLabel = moreLabel:+", Static";
   }

   // extern vs. non-extern
   if (pflags & VS_TAGFILTER_SCOPE_EXTERN) {
      moreLabel = moreLabel:+", Extern";
   }

   // make sure we don't have any ugly leading commas
   moreLabel = strip(moreLabel, 'L', ', ');
   label :+= moreLabel;

   return label;
}


//////////////////////////////////////////////////////////////////////////////
// SYMBOL SEARCHING LOGIC
//

/**
 * Find symbols matching the given word by search in tag files.
 * 
 * @param word             symbol or regular expression to search for
 * @param tag_files        array of tag files to search in
 * @param use_buffer       search in current buffer?
 * @param substring        expect a substring match?
 * @param case_sensitive   expect a case-sensitive match?
 * @param regex_type       use regular expression to do matching?
 * @param filter_flags     limit results to certain tag types
 * 
 * @return 0 on success, <0 if no symbols found
 */
static int findSymbolsInTagFiles(_str word,
                                 typeless tag_files, 
                                 boolean use_buffer,
                                 boolean substring,
                                 boolean case_sensitive,
                                 _str regex_type,
                                 int filter_flags
                                )
{
   // use for looking up tags later
   _str tag_name = "";
   _str type_name="";
   int tag_flags=0;

   // progress bar updating, count locals as 5%, context at 15%,
   // and divide the rest among the tag files.
   int progress_locals = 5;
   int progress_context = 15;
   int progress_tagfile = 80;
   ctl_progress.p_value=0;
   ctl_progress.refresh('w');
   if (tag_files._length()==0) {
      progress_locals  = 25;
      progress_context = 100;
      progress_tagfile = 0;
   }

   // number of results found so far
   int count = 0;

   // option for pos() for searching case-sensitive
   _str case_option = case_sensitive? 'e':'i';

   // search current buffer?
   if (use_buffer) {

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      // check locals in current function
      int i,n = tag_get_num_of_locals();
      for (i=1; i<=n; ++i) {
         tag_get_detail2(VS_TAGDETAIL_local_name, i, tag_name);
         int p = pos(word, tag_name, 1, case_option:+regex_type);
         if (!p) continue;
         if (!substring && p > 1) continue;
         tag_get_detail2(VS_TAGDETAIL_local_type, i, type_name);
         tag_get_detail2(VS_TAGDETAIL_local_flags, i, tag_flags);
         if (!tag_filter_type(0, filter_flags, type_name, tag_flags)) {
            continue;
         }
         ctl_progress.p_value = ((ctl_progress.p_max intdiv progress_locals) * i) intdiv n;
         ctl_progress.refresh('w');
         tag_insert_match_fast(VS_TAGMATCH_local, i);
         if (++count > def_tag_max_find_context_tags) {
            break;
         }
      }

      // check symbols in current buffer
      n = tag_get_num_of_context();
      for (i=1; i<=n; ++i) {
         tag_get_detail2(VS_TAGDETAIL_context_name, i, tag_name);
         int p = pos(word, tag_name, 1, case_option:+regex_type);
         if (!p) continue;
         if (!substring && p > 1) continue;
         tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
         tag_get_detail2(VS_TAGDETAIL_context_flags, i, tag_flags);
         if (!tag_filter_type(0, filter_flags, type_name, tag_flags)) {
            continue;
         }
         ctl_progress.p_value = (ctl_progress.p_max intdiv progress_locals) +
                                (ctl_progress.p_max intdiv progress_context) * i intdiv n;
         ctl_progress.refresh('w');
         tag_insert_match_fast(VS_TAGMATCH_context, i);
         if (++count > def_tag_max_find_context_tags) {
            break;
         }
      }
   }

   // done with current buffer, update progress
   int progress_increment = 0;
   if (tag_files._length() == 0) {
      ctl_progress.p_value = ctl_progress.p_max;
   } else {
      ctl_progress.p_value = ctl_progress.p_max intdiv 10;
      progress_increment = (ctl_progress.p_max - ctl_progress.p_value) intdiv tag_files._length();
   }
   ctl_progress.refresh('w');

   // now search in tag files
   int status = 0;
   int i=0;
   for (;;) {

      // number of potential matches found so far
      int progress_count = 0;

      // get the next tag file name (and open it)
      _str tag_filename = next_tag_filea(tag_files, i, true, true);
      if (tag_filename=="") break;

      // prefix match, not regular expression, so use fast lookup
      if (!substring && regex_type=="") {

         // find a prefix match
         status = tag_find_prefix(word, case_sensitive);
         while (status == 0) {

            // got one, make sure it matches filters
            tag_get_detail(VS_TAGDETAIL_type, type_name);
            tag_get_detail(VS_TAGDETAIL_flags, tag_flags);
            if (tag_filter_type(0, filter_flags, type_name, tag_flags)) {
               tag_insert_match_fast(VS_TAGMATCH_tag, 0);
               if (++count > def_tag_max_find_context_tags) {
                  break;
               }
            }

            // did the user hit a key?
            if (_IsKeyPending()) {
               break;
            }

            // update progress counter, do not let it overflow
            if (progress_count++ < progress_increment) {
               ctl_progress.p_value++;
               ctl_progress.refresh('w');
            }

            // next match please
            status = tag_next_prefix(word, case_sensitive);
         }
         tag_reset_find_tag();

      } else {

         // either substring match or regular expression

         // search for substring match
         status = tag_find_regex(word, case_option:+regex_type);
         while (status == 0) {

            // check if it is a regular expression, prefix match
            boolean use_match = true;
            if (!substring) {
               tag_get_detail(VS_TAGDETAIL_name, tag_name);
               int p = pos(word, tag_name, 1, case_option:+regex_type);
               if (p != 1) {
                  use_match = false;
               }
            }

            // check that it matches tag filters
            tag_get_detail(VS_TAGDETAIL_type, type_name);
            tag_get_detail(VS_TAGDETAIL_flags, tag_flags);
            if (!tag_filter_type(0, filter_flags, type_name, tag_flags)) {
               use_match = false;
            }

            // add it to the match set
            if (use_match) {
               tag_insert_match_fast(VS_TAGMATCH_tag, 0);
               if (++count > def_tag_max_find_context_tags) {
                  break;
               }
            }

            // update progress counter, do not let it overflow
            if (progress_count++ < progress_increment) {
               ctl_progress.p_value++;
               ctl_progress.refresh('w');
            }

            // did the user hit a key?
            if (_IsKeyPending()) {
               break;
            }

            // next match please
            status = tag_next_regex(word, case_option:+regex_type);
         }
         tag_reset_find_tag();
      }

      // finalize progress for this tag file
      ctl_progress.p_value = (ctl_progress.p_max intdiv progress_locals) +
                             (ctl_progress.p_max intdiv progress_context) +
                             (progress_increment);
      ctl_progress.refresh('w');
   }

   // max out progress count
   ctl_progress.p_value = ctl_progress.p_max;
   ctl_progress.refresh('w');

   // no matches, return error
   if (tag_get_num_of_matches() == 0) {
      return STRING_NOT_FOUND_RC;
   }

   // success!!!
   return 0;
}

/**
 * Use Context Tagging&reg; to find symbols somewhat intelligently.
 * 
 * @param idexp_info       expression info for search string
 * @param case_sensitive   case sensitive search?
 * @param filter_flags     symbol type filter flags
 * 
 * @return 0 on success, <0 on error or no symbols found.
 */
static int findSymbolsInContext(_str word, 
                                int editorctl_wid, _str lang,
                                boolean case_sensitive,
                                int filter_flags,
                                boolean substring_match,
                                _str &substring_word )
{
   // extract information about the current expression
   int orig_view_id=0;
   int temp_view_id=0;
   orig_view_id = _create_temp_view(temp_view_id);
   p_LangId=lang;
   insert_line(word);
   _end_line();
   VS_TAG_IDEXP_INFO idexp_info;
   struct VS_TAG_RETURN_TYPE visited:[];
   int status = _Embeddedget_expression_info(false, lang, idexp_info, visited);
   if (editorctl_wid) activate_window(editorctl_wid);
   if (status > 0) status = STRING_NOT_FOUND_RC;
   if (status < 0) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      return status;
   }

   // update the current context and locals
   _str errorArgs[];
   if (editorctl_wid) {
      _UpdateContext(true);
      _UpdateLocals(true,true);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // do we need to find all symbols and then filter
   // out the non-matches
   substring_word = idexp_info.lastid;
   if (substring_match) {
      idexp_info.lastid="";
   }

   // call the extension-specific (possibly embedded)
   // find tags function
   status = _Embeddedfind_context_tags(errorArgs,
                                       idexp_info.prefixexp,
                                       idexp_info.lastid,
                                       (int)_QROffset(),
                                       idexp_info.info_flags,
                                       idexp_info.otherinfo,
                                       false,
                                       def_tag_max_find_context_tags,
                                       false, case_sensitive,
                                       filter_flags,
                                       (VS_TAGCONTEXT_ALLOW_locals|VS_TAGCONTEXT_ALLOW_private|VS_TAGCONTEXT_ALLOW_protected|VS_TAGCONTEXT_ALLOW_package|VS_TAGCONTEXT_FIND_lenient),
                                       visited
                                      );

   // no matches, return error
   if (tag_get_num_of_matches() <= 0) {
      status = STRING_NOT_FOUND_RC;
   }

   // clean up the temp view
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);

   // that's all folks
   return status;
}

/**
 * Find all the symbols matching the given word using
 * the symbol search parameters specified on the 
 * Find Symbol form.
 * 
 * @param word    word to search for.
 */
static void findSymbols(_str word, _str &substring_word)
{
   // get the information about the current buffer
   _str lang = "";
   _str buffer_name = "";
   int editorctl_wid = 0;
   if (!_no_child_windows()) {
      editorctl_wid = _mdi.p_child;
      lang = editorctl_wid.p_LangId;
      buffer_name = editorctl_wid.p_buf_name;
   }

   // get the search options
   boolean case_sensitive  = ctl_case_sensitive.p_value >= 1;
   boolean substring       = ctl_substring.p_value >= 1;
   boolean use_context     = ctl_lookin.p_text == VS_TAG_FIND_TYPE_CONTEXT;
   boolean use_buffer      = use_context || ctl_lookin.p_text == VS_TAG_FIND_TYPE_BUFFER_ONLY;
   int use_regex           = ctl_use_regex.p_value;
   int filter_flags        = def_find_symbol_flags;
   typeless tag_files = getTagFilesToLookin(lang, buffer_name, use_buffer);

   // get regex options, defeat them if no regex chars
   _str regex_type = getRegexSearchOption();
   if (_escape_re_chars(word, regex_type) :== word) {
      regex_type = "";
      use_regex = 0;
   }

   // update the current context and locals
   if (editorctl_wid) {
      editorctl_wid._UpdateContext(true);
      editorctl_wid._UpdateLocals(true,true);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // first attempt to find symbols, using preferred options
   int status = STRING_NOT_FOUND_RC;

   if (use_context && !use_regex) {
      if (editorctl_wid!=0) {
   
         // use Context Tagging(R)
         status = findSymbolsInContext(word, editorctl_wid, lang, case_sensitive, def_find_symbol_flags, substring, substring_word);
   
         // didn't find anything? then try case-insensitive match
         if (status < 0 && ctl_case_sensitive.p_value == 2) {
            status = findSymbolsInContext(word, editorctl_wid, lang, false, def_find_symbol_flags, substring, substring_word);
         }
   
         // still didn't find anything, try defeating the substring match
         if (substring && word==substring_word) {
            tag_push_matches();
            status = findSymbolsInContext(word, editorctl_wid, lang, case_sensitive, def_find_symbol_flags, false, substring_word);
            tag_join_matches();
         }
      } else if (lang!='') {
         // use Context Tagging(R)
         status = findSymbolsInContext(word, 0, lang, case_sensitive, def_find_symbol_flags, substring, substring_word);
   
         // didn't find anything? then try case-insensitive match
         if (status < 0 && ctl_case_sensitive.p_value == 2) {
            status = findSymbolsInContext(word, 0, lang, false, def_find_symbol_flags, substring, substring_word);
         }
      }
   }

   // search for symbol in current buffer and tag files
   tag_push_matches();
   status = findSymbolsInTagFiles(word, tag_files, use_buffer, substring, case_sensitive, regex_type, filter_flags);
   tag_join_matches();

   // still haven't found anything, defeat case-sensitive and prefix match
   if (status < 0) {
      boolean try_again = false;
      if (ctl_case_sensitive.p_value == 2) {
         try_again = true;
         case_sensitive = false;
      }
      if (ctl_substring.p_value == 2) {
         try_again = true;
         substring = true;
      }
      if (try_again) {
         tag_push_matches();
         status = findSymbolsInTagFiles(word, tag_files, use_buffer, substring, case_sensitive, regex_type, filter_flags);
         tag_join_matches();
      }
   }
}

/**
 * Update the search results on the Find Symbol form.
 */
static void updateSearchResults()
{
   // not supposed to update right now
   if (gIgnoreChange) {
      return;
   }

   // get the search text, do not allow empty string
   _str word = ctl_search_for.p_text;
   if (word == '') {
      clearSymbolList();
      ctl_progress.p_visible=false;
      // disable the buttons (no results)
      ctl_goto_symbol.p_enabled     = false;
      ctl_find_references.p_enabled = false;
      ctl_show_in_classes.p_enabled = false;
      return;
   }

   // notify the user nicely
   message("Press Alt+S to stop search");
   mou_hour_glass(true);
   ctl_progress.p_visible=true;
   ctl_progress.p_value=0;
   ctl_progress.refresh('w');
   tag_push_matches();
   tag_clear_matches();

   // keep track of when we started
   typeless start_time = _time('b');

   // find symbols matching the search string
   _str substring_word=word;
   findSymbols(word, substring_word);

   // update the list of symbols
   updateSymbolList(word, substring_word);

   // now get our end time
   typeless end_time = _time('b');

   // calculate the elapsed time and force it to
   // always take at least a tenth second so that the
   // progress bar doesn't flash and go away too fast
   typeless elapsed = end_time - start_time;
   if (elapsed < 100) {
      delay(10 - elapsed intdiv 10);
   }

   // clear up user notifications
   tag_pop_matches();
   ctl_progress.p_visible = false;
   mou_hour_glass(false);
   clear_message();
}

/**
 * Update the search results on the Find Symbol form NOW.
 */
static void updateSearchResultsNoDelay()
{
   int wid = _tbGetWid("_tbfind_symbol_form");
   if (wid != 0) {
      wid.updateSearchResults();
   }
   killFindSymbolTimer();
}

/**
 * Update the search results on the Find Symbol form after
 * a slight delay (to allow for another keypress or event)
 */
static void updateSearchResultsDelayed()
{
   if (gIgnoreChange) {
      return;
   }

   // make the progress meter visible
   if (ctl_search_for.p_text != "") {
      ctl_progress.p_visible = true;
      ctl_progress.p_value = 0;
      ctl_progress.refresh('w');
   }

   // start the timer function
   startFindSymbolTimer(updateSearchResultsNoDelay);
}

//////////////////////////////////////////////////////////////////////////////
// COMMAND BUTTONS
//

/**
 * jump to the location of the item currently selected in the tree
 */
void ctl_goto_symbol.lbutton_up()
{
   VS_TAG_BROWSE_INFO cm;
   int status = getSelectedSymbol(cm);
   if (!status) {

      int mark=-1;
      int orig_buf_id=0;
      int editorctl_wid=0;
      if (!_no_child_windows()) {
         editorctl_wid = _mdi.p_child;
         mark = _alloc_selection('b');
         if (mark >= 0) {
            editorctl_wid._select_char(mark);
            editorctl_wid._ForwardBack_update();
            orig_buf_id = editorctl_wid.p_buf_id;
            editorctl_wid.mark_already_open_destinations();
         }
      }

      status = tag_edit_symbol(cm);

      if (!status && orig_buf_id != 0) {
         if (orig_buf_id==editorctl_wid.p_buf_id) {
            editorctl_wid._ForwardBack_push();
         }
         if (def_search_result_push_bookmark) {
            status = editorctl_wid.push_bookmark(mark);
         }
      }
   }
}

/**
 * find symbol references to the item currently selected in the tree
 */
void ctl_find_references.lbutton_up()
{
   VS_TAG_BROWSE_INFO cm;
   int status = getSelectedSymbol(cm);
   if (!status) {
      activate_references();
      refresh_references_tab(cm);
   }
}
_command void tag_find_symbol_show_references() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   int wid = _tbGetWid("_tbfind_symbol_form");
   if (wid != 0) {
      VS_TAG_BROWSE_INFO cm;
      int status = wid.getSelectedSymbol(cm);
      if (!status) {
         activate_references();
         refresh_references_tab(cm);
      }
   }
}

/**
 * show the item currently selected in the tree in the symbol browser
 */
void ctl_show_in_classes.lbutton_up()
{
   VS_TAG_BROWSE_INFO cm;
   int status = getSelectedSymbol(cm);
   if (!status) {
      tag_show_in_class_browser(cm);
   }
}
_command void tag_find_symbol_show_in_class_browser() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   int wid = _tbGetWid("_tbfind_symbol_form");
   if (wid != 0) {
      VS_TAG_BROWSE_INFO cm;
      int status = wid.getSelectedSymbol(cm);
      if (!status) {
         tag_show_in_class_browser(cm);
      }
   }
}


///////////////////////////////////////////////////////////////////////////////
// For saving and restoring the state of the find symbol tool window
// when the user undocks, pins, unpins, or redocks the window.
//
void _tbSaveState__tbfind_symbol_form(typeless& state, boolean closing)
{
   //if( closing ) {
   //   return;
   //}
   ctl_symbols._TreeSaveNodes(state);
}
void _tbRestoreState__tbfind_symbol_form(typeless& state, boolean opening)
{
   //if( opening ) {
   //   return;
   //}
   if (state == null) return;
   ctl_symbols._TreeRestoreNodes(state);

   boolean enabled = (ctl_symbols._TreeGetNumChildren(TREE_ROOT_INDEX) > 0);
   ctl_goto_symbol.p_enabled     = enabled;
   ctl_find_references.p_enabled = enabled;
   ctl_show_in_classes.p_enabled = enabled;
}

