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
#import "se/lang/api/LanguageSettings.e"
#import "se/search/SearchResults.e"
#import "se/tags/TaggingGuard.e"
#import "c.e"
#import "cbrowser.e"
#import "codehelp.e"
#import "context.e"
#import "files.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "project.e"
#import "proctree.e"
#import "projutil.e"
#import "pushtag.e"
#import "search.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagrefs.e"
#import "tags.e"
#import "tagwin.e"
#import "tbcmds.e"
#import "toolbar.e"
#import "se/ui/toolwindow.e"
#import "se/ui/twevent.e"
#import "treeview.e"
#import "util.e"
#import "wkspace.e"
#endregion

using se.lang.api.LanguageSettings;

//////////////////////////////////////////////////////////////////////////////
// String constants for find symbol form search types
//
const VS_TAG_FIND_TYPE_CONTEXT=          "<Use Context Tagging"VSREGISTEREDTM">";
const VS_TAG_FIND_TYPE_BUFFER_ONLY=      "<Current File>";
const VS_TAG_FIND_TYPE_ALL_BUFFERS=      "<All Open Files>";
const VS_TAG_FIND_TYPE_PROJECT_ONLY=     "<Current Project>";
const VS_TAG_FIND_TYPE_SAME_PROJECTS=    "<Projects Containing Current File>";
const VS_TAG_FIND_TYPE_WORKSPACE_ONLY=   "<Current Workspace>";
const VS_TAG_FIND_TYPE_WORKSPACE_PLUS=   "<Current Workspace and Language Tag Files>";
const VS_TAG_FIND_TYPE_EXTENSION=        "<\"%s\" Tag Files>";
const VS_TAG_FIND_TYPE_ECLIPSE=          "<\"%s\" Eclipse Tag Files>";
const VS_TAG_FIND_TYPE_EVERYWHERE=       "<All Tag Files>";

const VS_TAG_FIND_SUBWORD_PATTERN_MATCH= "Subword pattern matching";

//////////////////////////////////////////////////////////////////////////////
/**
 * Toolbar orientation flags (automatic, vertical, horizontal, standard, hybrid) 
 * These flags are used by more than one tool window, it is up to the tool 
 * window which options are supported. 
 */
enum TOOLBAR_LAYOUT_ORIENTATION {
   /**
    * Automatic choice of orientation based on tool window shape (tall vs. wide)
    */
   TOOLBAR_LAYOUT_ORIENTATION_AUTOMATIC = 0,
   /**
    * Vertical (stacked) orientation
    */
   TOOLBAR_LAYOUT_ORIENTATION_VERTICAL = 1,
   /**
    * Horizontal orientation
    */
   TOOLBAR_LAYOUT_ORIENTATION_HORIZONTAL = 2,
   /**
    * Standard orientation for this tool window
    */
   TOOLBAR_LAYOUT_ORIENTATION_STANDARD = 3,
   /**
    * Another alternate orientation that is not horizontal or vertical.
    */
   TOOLBAR_LAYOUT_ORIENTATION_HYBRID = 4,
};

/** 
 * Find symbol tool window orientation preferences.
 * <ul> 
 * <li>0 -- automatic 
 * <li>1 -- vertical 
 * <li>2 -- horizontal 
 * </ul> 
 *  
 * @categories Configuration_Variables
 */
int def_find_symbol_orientation = TOOLBAR_LAYOUT_ORIENTATION_AUTOMATIC;

static const FIND_SYMBOL_MIN_LIST_HEIGHT = 900;
static const FIND_SYMBOL_MIN_LIST_WIDTH  = 2400;

//////////////////////////////////////////////////////////////////////////////
// ignore changes to search field, etc, used during initialization
static bool gIgnoreSearchChange = false;
static bool gIgnoreSelectChange = false;


//////////////////////////////////////////////////////////////////////////////
// update timer delay and ID
static const FIND_SYMBOL_TIMER_DELAY_MS= 100;


//////////////////////////////////////////////////////////////////////////////
// expression to initialize find symbol tool window with
static _str gFindSymbolExpression = "";


static const FIND_SYMBOL_DLGINFO_OPTIONS_TIMER_ID = 1;
static const FIND_SYMBOL_DLGINFO_UPDATE_TIMER_ID  = 2;
//static const FIND_SYMBOL_DLGINFO_EXPRESSION       = 3;


/**
 * Kill the existing find symbol update timer.
 */
static void killFindSymbolUpdateTimer()
{
   form_wid := _tbGetActiveFindSymbolForm();
   if (form_wid == 0) {
      return;
   }
   stop_wid := form_wid._find_control("ctl_search_stop");
   if (stop_wid != 0) {
      stop_wid.p_user = true;
   }

   // if there is a timer for updating the search buffer, kill it
   timer_id := _GetDialogInfo(FIND_SYMBOL_DLGINFO_UPDATE_TIMER_ID, form_wid);
   if ( timer_id != null && timer_id != -1 && _timer_is_valid(timer_id) ) {
      _kill_timer(timer_id);
      _SetDialogInfo(FIND_SYMBOL_DLGINFO_UPDATE_TIMER_ID, -1, form_wid);
   }
}

/**
 * Re-start the find symbol update timer.
 * @param timer_cb   timer callback function {@see findSymbols}
 */
static void startFindSymbolUpdateTimer(typeless timer_cb)
{
   form_wid := _tbGetActiveFindSymbolForm();
   if (form_wid == 0) {
      return;
   }

   stop_wid := form_wid._find_control("ctl_search_stop");
   if (stop_wid != 0) {
      stop_wid.p_user = true;
   }

   killFindSymbolUpdateTimer();

   timer_delay := max(FIND_SYMBOL_TIMER_DELAY_MS,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
   timer_id    := _set_timer(timer_delay, timer_cb);

   _SetDialogInfo(FIND_SYMBOL_DLGINFO_UPDATE_TIMER_ID, timer_id, form_wid);
}

/**
 * Kill the existing find symbol options timer.
 */
static void killFindSymbolOptionsTimer()
{
   form_wid := _tbGetActiveFindSymbolForm();
   if (form_wid == 0) {
      return;
   }
   stop_wid := form_wid._find_control("ctl_search_stop");
   if (stop_wid != 0) {
      stop_wid.p_user = true;
   }

   // if there is a timer for updating the search buffer, kill it
   timer_id := _GetDialogInfo(FIND_SYMBOL_DLGINFO_OPTIONS_TIMER_ID, form_wid);
   if ( timer_id != null && timer_id != -1 && _timer_is_valid(timer_id) ) {
      _kill_timer(timer_id);
      _SetDialogInfo(FIND_SYMBOL_DLGINFO_OPTIONS_TIMER_ID, -1, form_wid);
   }
}

/**
 * Re-start the find symbol options timer.
 * @param timer_cb   timer callback function {@see findSymbols}
 */
static void startFindSymbolOptionsTimer(typeless timer_cb)
{
   form_wid := _tbGetActiveFindSymbolForm();
   if (form_wid == 0) {
      return;
   }
   stop_wid := form_wid._find_control("ctl_search_stop");
   if (stop_wid != 0) {
      stop_wid.p_user = true;
   }

   killFindSymbolOptionsTimer();

   timer_delay := max(FIND_SYMBOL_TIMER_DELAY_MS,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
   timer_id    := _set_timer(timer_delay, timer_cb);

   _SetDialogInfo(FIND_SYMBOL_DLGINFO_OPTIONS_TIMER_ID, timer_id, form_wid);
}

static int _tbGetActiveFindSymbolForm()
{
   return tw_find_form("_tbfind_symbol_form");
}


//////////////////////////////////////////////////////////////////////////////
// module initialization code
//
definit()
{
   gIgnoreSearchChange = false;
   gIgnoreSelectChange = false;
   gFindSymbolExpression = "";
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
 * @param bind_key_to_form    (optional) set key binding on form containing event_wid 
 */
void copy_key_bindings_to_form(_str command_name, int event_wid, 
                               _str event, int (&keys)[],
                               bool bind_key_to_form=false)
{
   // get the event index for the target event
   event_index := eventtab_index(event_wid.p_eventtab,event_wid.p_eventtab,event2index(event));
   if (!event_index) return;

   // get the key table index for default keys
   keytab_name := "default_keys";
   ktab_index  := find_index(keytab_name,EVENTTAB_TYPE);

   // find the bindings for the given command
   VSEVENT_BINDING bindings[];
   bindings._makeempty();
   index := find_index(command_name, COMMAND_TYPE);
   list_bindings(ktab_index,bindings,index);

   // bind the key to the form's event table
   binding_names := "";
   n := bindings._length();
   for (i:=0; i<n; ++i) {
      index = bindings[i].binding;
      if (index && (name_type(index) & (COMMAND_TYPE|PROC_TYPE))) {
         if (bindings[i].iEvent != event2index(event)) {
            keys[keys._length()] = bindings[i].iEvent;
            if (bind_key_to_form) {
               set_eventtab_index(event_wid.p_active_form.p_eventtab, bindings[i].iEvent, event_index);
            }
            if (binding_names != "") binding_names :+= ", ";
            binding_names :+= event2name(index2event(bindings[i].iEvent),'L');
         }
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
void copy_default_key_bindings(_str command_name, int wid=0)
{
   // get the key table index for default keys
   keytab_name := "default_keys";
   ktab_index := find_index(keytab_name,EVENTTAB_TYPE);

   // find the bindings for the given command
   VSEVENT_BINDING bindings[];
   bindings._makeempty();
   index := find_index(command_name, COMMAND_TYPE);
   list_bindings(ktab_index,bindings,index);

   // bind the key to the form's event table
   if (wid==0) wid=p_active_form;
   n := bindings._length();
   for (i:=0; i<n; ++i) {
      index = bindings[i].binding;
      if (index && (name_type(index) & (COMMAND_TYPE|PROC_TYPE))) {
         set_eventtab_index(wid.p_eventtab, bindings[i].iEvent, index);
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
   parse ctl_goto_symbol.p_message with msg "(" .; 
   ctl_goto_symbol.p_message = msg;
   parse ctl_find_references.p_message with msg "(" .;
   ctl_find_references.p_message = msg;
   parse ctl_show_in_classes.p_message with msg "(" .;
   ctl_show_in_classes.p_message =msg;
}

/**
 * Callback for key binding / emulation changes
 */
void _eventtab_modify_find_symbol(typeless keytab_used, _str event="")
{
   kt_index := find_index("default_keys", EVENTTAB_TYPE);
   if (keytab_used && kt_index != keytab_used) {
      return;
   }
   wid := _tbGetActiveFindSymbolForm();
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
   ctl_search_stop.p_enabled = false;
   ctl_search_stop.p_user = false;

   // save the expanded/collapsed state of the options
   gIgnoreSearchChange = true;
   gIgnoreSelectChange = true;
   ctl_options_button._retrieve_value();
   showSearchOptions();

   // adjust alignment for auto-sized button
   ctl_options_button.resizeToolButton(ctl_options_label.p_height);
   ctl_filter_button.resizeToolButton(ctl_options_label.p_height);
   ctl_filter_label.p_y = ctl_filter_button.p_y = ctl_regex_type.p_y_extent + 90;
   ctl_filter_label.p_x = ctl_filter_button.p_x_extent + _dx2lx(SM_TWIP,5);
   ctl_options_label.p_x = ctl_options_button.p_x_extent + _dx2lx(SM_TWIP,5);

   // special case for line column width
   line_column_width := min(ctl_symbols._text_width("123456"), ctl_symbols.p_width intdiv 12);

   // set up the tree columns and restore the column widths
   ctl_symbols._TreeSetColButtonInfo(0, ctl_symbols.p_width intdiv 3, TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT, 1, "Symbol");
   ctl_symbols._TreeSetColButtonInfo(1, ctl_symbols.p_width intdiv 6, TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT, 0, "Package/Class");
   ctl_symbols._TreeSetColButtonInfo(2, ctl_symbols.p_width intdiv 6, TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_FILENAME|TREE_BUTTON_IS_FILENAME, 0, "File");
   ctl_symbols._TreeSetColButtonInfo(3, ctl_symbols.p_width intdiv 4, TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_FILENAME|TREE_BUTTON_IS_FILENAME, 0, "Path");
   ctl_symbols._TreeSetColButtonInfo(4, line_column_width,            TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT|TREE_BUTTON_SORT_NUMBERS, 0, "Line");

   // restore previous searches and last search string
   ctl_search_for._retrieve_list();
   ctl_search_for._retrieve_value();

   // restore previous search scope and options
   ctl_lookin.updateLookinOptions();
   ctl_lookin._retrieve_value();
   if (ctl_lookin.p_text=="") {
      ctl_lookin._cbset_text(VS_TAG_FIND_TYPE_CONTEXT);
   }

   // seed search box with expression if given
   if (gFindSymbolExpression != "") {
      ctl_search_for._cbset_text(gFindSymbolExpression);
      gFindSymbolExpression = "";
   }

   // restore regular expression types and last regex used
   ctl_regex_type.updateRegexTypes();
   ctl_regex_type._retrieve_value();
   if (ctl_regex_type.p_text == "") {
      //if (def_re_search_flags & VSSEARCHFLAG_BRIEFRE) {
      //   ctl_regex_type.p_text = RE_TYPE_BRIEF_STRING;
      //} else 
      if (def_re_search_flags & VSSEARCHFLAG_RE) {
         ctl_regex_type.p_text = RE_TYPE_SLICKEDIT_STRING;
      } else if (def_re_search_flags & VSSEARCHFLAG_WILDCARDRE) {
         ctl_regex_type.p_text = RE_TYPE_WILDCARD_STRING;
      } else if (def_re_search_flags & VSSEARCHFLAG_VIMRE) {
         ctl_regex_type.p_text = RE_TYPE_VIM_STRING;
      } else /*if (def_re_search_flags & VSSEARCHFLAG_PERLRE)*/ {
         ctl_regex_type.p_text = RE_TYPE_PERL_STRING;
      //} else {
      //   ctl_regex_type.p_text = RE_TYPE_UNIX_STRING;
      }
   }

   // restore whether or not regex search should be used
   ctl_use_regex._retrieve_value();
   if (!ctl_use_regex.p_value) {
      ctl_regex_type.p_enabled = false;
   }

   // restore case sensitivity option
   ctl_case_sensitive._retrieve_value();

   // restore qualified name matching option
   ctl_qualified_name._retrieve_value();

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
   gIgnoreSearchChange = false;
   gIgnoreSelectChange = false;
   gFindSymbolExpression = "";
}

/**
 * Save settings before destroying form
 */
void _tbfind_symbol_form.on_destroy()
{
   // make sure time function stops first
   ctl_search_stop.p_user = true;

   // save all the search form options
   ctl_symbols._TreeAppendColButtonInfo();
   ctl_lookin._append_retrieve(ctl_lookin, ctl_lookin.p_text);
   ctl_search_for._append_retrieve(ctl_search_for, ctl_search_for.p_text);
   ctl_use_regex._append_retrieve(ctl_use_regex, ctl_use_regex.p_value);
   ctl_regex_type._append_retrieve(ctl_regex_type, ctl_regex_type.p_text);
   ctl_options_button._append_retrieve(ctl_options_button, ctl_options_button.p_value);
   ctl_case_sensitive._append_retrieve(ctl_case_sensitive, ctl_case_sensitive.p_value);
   ctl_qualified_name._append_retrieve(ctl_qualified_name, ctl_qualified_name.p_value);
   ctl_substring._append_retrieve(ctl_substring, ctl_substring.p_value);

   // knock off any timer functions
   killFindSymbolUpdateTimer();
   killFindSymbolOptionsTimer();

   // unbind keys copied in for push_tag and push_ref shortcuts
   unbindFindSymbolShortcuts();
   gFindSymbolExpression = "";

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
   showControls := ( ctl_options_button.p_value == 1);
   ctl_case_sensitive.p_enabled = ctl_case_sensitive.p_visible = showControls;
   ctl_qualified_name.p_enabled = ctl_qualified_name.p_visible = showControls;
   ctl_substring.p_enabled      = ctl_substring.p_visible      = showControls;
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
      ctl_options_frame.p_height = ctl_options_label.p_y + ctl_filter_label.p_y_extent;
   } else {
      _str search_options = getSearchOptionsString();
      int label_width = ctl_options_label.p_width;
      if (label_width <= 0) label_width=1;
      int num_lines = ctl_options_label._text_width(search_options) intdiv label_width;
      ctl_options_label.p_caption = search_options;
      ctl_options_label.p_height = (num_lines+1) * ctl_options_label._text_height();
      ctl_options_frame.p_height = ctl_options_label.p_y + ctl_options_label.p_y_extent;
   }
}

static void setFilterCaption()
{
   filter_options := getFilterOptionsString(def_find_symbol_flags);
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
static bool isHorizontalOrientation()
{
   // Calculate the minimum sizes
   //    
   //    min_vertical_width    - minimum width required for vertical orientation (width of search options)
   //    min_horizontal_width  - minimum width required for horizontal orientation (twice the min vertical width plus some extra)
   //    min_horizontal_height - minimum height required for horizontal orientation (symbol list y position + min list height)
   //    min_vertical_height   - minimum height required for veritical orientation (symbol list min size + options min size)
   //                            this is calculated based on whether or not options are collapsed.
   //
   min_vertical_width    := ctl_regex_type.p_x_extent + ctl_search_for.p_x*4;
   min_horizontal_width  := min_vertical_width + FIND_SYMBOL_MIN_LIST_WIDTH;
   min_horizontal_height := ctl_symbols.p_y + FIND_SYMBOL_MIN_LIST_HEIGHT;
   min_vertical_height   := min_horizontal_height + (ctl_goto_symbol.p_y_extent - ctl_lookin_label.p_y);

   // is dialog large enough for vertical orientation ?
   if (p_width >= min_vertical_width && p_height >= min_vertical_height) {
      // force vertical if it isn't wide enough for horizontal
      if (p_width < min_horizontal_width) {
         return false;
      }
      // Did they force vertical orientation?
      if (def_find_symbol_orientation == TOOLBAR_LAYOUT_ORIENTATION_VERTICAL) {
         return false;
      }
      // large enough for vertical orientation, and taller than it is wide
      if (p_height > p_width) {
         return false;
      }
   }

   // is dialog large enough for horizontal orientation ?
   if (p_width >= min_horizontal_height && p_height >= min_horizontal_height) {
      // force horizontal if it is too short for vertical
      if (p_height < min_vertical_height) {
         return true;
      }
      // Did they force horizontal orientation?
      if (def_find_symbol_orientation == TOOLBAR_LAYOUT_ORIENTATION_HORIZONTAL) {
         return true;
      }
      // large enough for horizontal orientation, and much wider than it is tall
      if (p_width > 3*p_height) {
         return true;
      }
   }

   // wide enough for (wider) horizontal orientation
   // choose that if the height is too small for vertical.
   if (p_width >= min_horizontal_width) {
      return (p_height <= min_vertical_height);
   }

   // tall enough for (taller) vertical orientation
   if (p_height >= min_vertical_height) {
      return !(p_width <= min_vertical_width);
   }

   // make sure form is wide enough
   return (p_width >= min_horizontal_height && p_height < min_vertical_height);
}

/**
 * Resize the width of the Find Symbol tool window
 */
static void resizeFrameWidths()
{
   // make sure form is wide enough
   padding := ctl_search_for.p_x;
   min_width := ctl_regex_type.p_x_extent + padding*4;
   if (!tw_is_docked_window(p_active_form) && p_width < min_width) {
      p_width = min_width;
   }

   // available space and border usage
   avail_width  := _dx2lx(SM_TWIP,p_client_width)  - 2*padding;
   avail_height := _dy2ly(SM_TWIP,p_client_height) - 2*padding;

   // horizontal or vertical layout
   width_left  := avail_width;
   width_right := avail_width;
   x_right     := padding;
   if (isHorizontalOrientation()) {
      width_right = ctl_regex_type.p_x_extent + padding;
      width_left  = avail_width - width_right - padding;
      x_right = avail_width - width_right + padding;
   }

   // move the right hand side controls into place
   ctl_lookin_label.p_x = x_right;
   ctl_lookin.p_x = x_right;
   ctl_options_frame.p_x = x_right;
   ctl_goto_symbol.p_x = x_right;
   ctl_find_references.p_x = x_right + ctl_goto_symbol.p_width + padding*2;
   ctl_show_in_classes.p_x = x_right;

   // stretch controls to full width of form
   orig_tree_width := ctl_symbols.p_width;
   ctl_search_for_label.p_x = ctl_search_for.p_x;
   ctl_symbols.p_x = ctl_search_for.p_x;
   ctl_symbols.p_width = width_left;
   ctl_lookin.p_width = width_right;
   ctl_options_frame.p_width = width_right;
   ctl_options_label.p_x_extent = ctl_options_frame.p_width ;
   ctl_filter_label.p_x_extent = ctl_options_frame.p_width ;

   sizeBrowseButtonToTextBox(ctl_search_for_label.p_window_id, 
                             ctl_search_for_help.p_window_id);
   sizeBrowseButtonToTextBox(ctl_search_for_label.p_window_id, 
                             ctl_search_stop.p_window_id);
   sizeBrowseButtonToTextBox(ctl_search_for.p_window_id, 
                             _re_button.p_window_id,
                             ctl_search_refresh.p_window_id, 
                             ctl_symbols.p_x_extent);

   // position progress control
   ctl_search_stop.p_x = ctl_search_for_help.p_x_extent;
   ctl_progress.p_x = ctl_search_stop.p_x_extent + 2*padding;
   ctl_progress.p_x_extent = width_left;

   // scale tree buttons if the form has changed in size
   ctl_symbols._TreeScaleColButtonWidths(orig_tree_width, true);

   // right-justify command buttons
   ctl_goto_symbol.p_x     = avail_width - 4*(ctl_search_for.p_x + ctl_goto_symbol.p_width);
   ctl_find_references.p_x = avail_width - 3*(ctl_search_for.p_x + ctl_goto_symbol.p_width);
   ctl_show_in_classes.p_x = avail_width - 2*(ctl_search_for.p_x + ctl_goto_symbol.p_width);
   ctl_tag_files.p_x       = avail_width - 1*(ctl_search_for.p_x + ctl_goto_symbol.p_width);
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
   y_bottom_left := p_height;
   y_top_right   := ctl_search_for_label.p_y;
   if (!isHorizontalOrientation()) {
      y_bottom_left = p_height;
      y_bottom_left -= (ctl_options_frame.p_y   - ctl_lookin_label.p_y);
      y_bottom_left -= ctl_options_frame.p_height;
      y_bottom_left -= ctl_search_for_label.p_y;
      y_bottom_left -= (ctl_show_in_classes.p_height + padding);
      y_top_right   = y_bottom_left;
   }

   // adjust height of symbol list (which is only stretchy part vertically)
   symbols_height := y_bottom_left - ctl_symbols.p_y - ctl_search_for_label.p_y;
   if (symbols_height < FIND_SYMBOL_MIN_LIST_HEIGHT) {
      y_top_right -= symbols_height;
      symbols_height = FIND_SYMBOL_MIN_LIST_HEIGHT;
      y_top_right += FIND_SYMBOL_MIN_LIST_HEIGHT;
   }
   ctl_symbols.p_height = symbols_height;

   // adjust location of options frame and buttons
   ctl_lookin_label.p_y    = y_top_right;
   ctl_lookin.p_y          = y_top_right+ctl_lookin_label.p_height+ctl_search_for_label.p_y;
   ctl_options_frame.p_y   = ctl_lookin.p_y_extent + padding;
   ctl_goto_symbol.p_y     = ctl_options_frame.p_y_extent+ctl_search_for_label.p_y;
   ctl_find_references.p_y = ctl_goto_symbol.p_y;
   ctl_show_in_classes.p_y = ctl_goto_symbol.p_y;
   ctl_tag_files.p_y       = ctl_goto_symbol.p_y;

   // force a minimum height
   min_height := ctl_symbols.p_y + FIND_SYMBOL_MIN_LIST_HEIGHT;
   if (p_height < min_height && !tw_is_docked_window(p_active_form)) {
      p_height = min_height;
   }
}

/**
 * Handle resizing of the Find Symbol tool window
 */
void _tbfind_symbol_form.on_resize()
{
   // if the minimum width has not been set, it will return 0
   if (!tw_is_docked_window(p_active_form) && !_minimum_width()) {
      min_width := ctl_regex_type.p_x_extent + ctl_search_for.p_x*4;
      _set_minimum_size(min_width, -1);
   }
   if (ctl_search_for.p_x < 60) {
      ctl_search_for.p_x = 60;
   }

   resizeFrameWidths();
   resizeFrameHeights();

   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      // First time
      ctl_symbols._TreeRetrieveColButtonInfo();
   }
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

void ctl_search_refresh.lbutton_up()
{
   ctl_search_stop.p_user=0;
   updateSearchResultsDelayed();
}

/**
 * Hide the find symbol form after user hits enter
 */
static void maybeHideFindSymbol()
{
   tagwin_wid := _tbGetActiveFindSymbolForm();
   if ( tagwin_wid ) {
      tw_dismiss(tagwin_wid);
   }
}

/**
 * If they press "Enter", then jump to the first match
 */
void ctl_search_for.enter()
{
   timer_id := _GetDialogInfo(FIND_SYMBOL_DLGINFO_UPDATE_TIMER_ID, p_active_form);
   if ( timer_id != null && timer_id != -1 && _timer_is_valid(timer_id) ) {
      updateSearchResultsNoDelay();
   }
   if (ctl_symbols._TreeGetFirstChildIndex(TREE_ROOT_INDEX) < 0) {
      // do nothing
   } else if (ctl_symbols._TreeGetNumChildren(TREE_ROOT_INDEX) == 1) {
      call_event(ctl_goto_symbol.p_window_id, LBUTTON_UP);
      maybeHideFindSymbol();
   } else if (ctl_symbols._TreeCurIndex() == 0 ||
              ctl_symbols.p_AlwaysColorCurrent == false) {
      ctl_symbols._set_focus();
   } else {
      call_event(ctl_symbols.p_window_id, LBUTTON_DOUBLE_CLICK);
      maybeHideFindSymbol();
   }
}

/**
 * If they press "Enter", then jump to the first match
 */
void ctl_search_for.down()
{
   if (ctl_symbols._TreeGetFirstChildIndex(TREE_ROOT_INDEX) < 0) {
      // do nothing
   } else {
      ctl_symbols._TreeDown();
   }
}

/**
 * If they press "Enter", then jump to the first match
 */
void ctl_search_for.up()
{
   if (ctl_symbols._TreeGetFirstChildIndex(TREE_ROOT_INDEX) < 0) {
      // do nothing
   } else {
      ctl_symbols._TreeUp();
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
   if (gFindSymbolExpression != "") {
      ctl_search_for._cbset_text(gFindSymbolExpression);
      gFindSymbolExpression = "";
   }
   ctl_search_for.p_sel_start  = 1;
   ctl_search_for.p_sel_length = length(ctl_search_for.p_text);
}

/**
 * When the list of symbols gets focus, immediately update the
 * currently selected item.
 */
void ctl_symbols.on_got_focus()
{
   gFindSymbolExpression = "";
   timer_id := _GetDialogInfo(FIND_SYMBOL_DLGINFO_UPDATE_TIMER_ID, p_active_form);
   if ( timer_id != null && timer_id != -1 && _timer_is_valid(timer_id) ) {
      updateSearchResultsNoDelay();
   }
   call_event(CHANGE_SELECTED, ctl_symbols._TreeCurIndex(), ctl_symbols.p_window_id, ON_CHANGE, 'w');
}


void _tbfind_symbol_form.on_got_focus()
{
   if (!_find_control("ctl_lookin")) return;
   p_active_form.ctl_lookin.updateLookinOptions();
}

void _tbfind_symbol_form.on_change(int reason)
{
   if (reason == CHANGE_AUTO_SHOW) {
      if (!_find_control("ctl_lookin")) return;
      p_active_form.ctl_lookin.updateLookinOptions();
   }
}

void ctl_symbols.rbutton_up()
{
   // Get handle to menu:
   index := find_index("_tagbookmark_menu",oi2type(OI_MENU));
   menu_handle := p_active_form._menu_load(index,'P');

   // configure it for this dialog use
   flags := def_find_symbol_flags;
   pushTgConfigureMenu(menu_handle, flags, 
                       include_proctree:false, 
                       include_casesens:false, 
                       include_sort:false, 
                       include_save_print:true, 
                       include_search_results:true,
                       include_refs_results:true);

   status := p_active_form.getSelectedSymbol(auto cm);
   if (!status && cm.member_name != "") {
      // add specific items for Find Symbol tool window
      _menu_insert(menu_handle, 0, MF_ENABLED, "-");
      _menu_insert(menu_handle, 0, MF_ENABLED, "Show "cm.member_name" in symbol browser", "tag_find_symbol_show_in_class_browser");  
      _menu_insert(menu_handle, 0, MF_ENABLED, "Go to references to "cm.member_name, "tag_find_symbol_show_references");  
   }

   // Show menu:
   mou_get_xy(auto x,auto y);
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
   // turn off the timer now
   killFindSymbolOptionsTimer();

   // prevent form from searching when then items are inserted
   origIgnoreSearchChange := gIgnoreSearchChange;
   origIgnoreSelectChange := gIgnoreSelectChange;
   gIgnoreSearchChange = true;
   gIgnoreSelectChange = true;

   // put in the standard, top four search types
   origText := p_text;
   _lbclear();
   _lbadd_item(VS_TAG_FIND_TYPE_CONTEXT);
   _lbadd_item(VS_TAG_FIND_TYPE_BUFFER_ONLY);
   _lbadd_item(VS_TAG_FIND_TYPE_ALL_BUFFERS);
   _lbadd_item(VS_TAG_FIND_TYPE_PROJECT_ONLY);
   _lbadd_item(VS_TAG_FIND_TYPE_SAME_PROJECTS);
   _lbadd_item(VS_TAG_FIND_TYPE_WORKSPACE_ONLY);
   _lbadd_item(VS_TAG_FIND_TYPE_WORKSPACE_PLUS);

   // put in the current file extension first
   cur_mode_name := "";
   if (!_no_child_windows()) {
      cur_mode_name = _mdi.p_child.p_mode_name;
      if (cur_mode_name != "") {
         _str lang = _mdi.p_child.p_LangId;
         if (LanguageSettings.getTagFileList(lang)!="") {
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

      mode_name := _LangGetModeName(langId);
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
   tag_files = compiler_tags_filename("c");
   filename := next_tag_file(tag_files,true);
   while (filename != "") {
      _lbadd_item(filename);
      filename=next_tag_file(tag_files,false);
   }

   // Finally, put in individual tag files
   tag_files = tags_filenamea();
   for (i:=0; i<tag_files._length(); ++i) {
      _lbadd_item(_maybe_quote_filename(tag_files[i]));
   }
   
   // now put in an option to search All tag files
   _lbadd_item(VS_TAG_FIND_TYPE_EVERYWHERE);

   // now restore the original combo box text
   redoSearch := false;
   if (origText != "") {
      // if it is there, grab it
      if (_lbfind_and_select_item(origText, "", true) < 0) {
         // it wasn't there, so it is not available anymore - clear the search
         if (ctl_search_for.p_text != "") {
            ctl_search_for.p_text = "";
            redoSearch = true;
         }
      }
   }

   // restore the ignore changes flag
   gIgnoreSearchChange = origIgnoreSearchChange;
   gIgnoreSelectChange = origIgnoreSelectChange;

   if (redoSearch) {
      updateSearchResultsNoDelay();
   }
}

/**
 * Maybe clear the find symbol results when a project is closed
 */
void _prjclose_find_symbol(bool singleFileProject)
{
   if (singleFileProject) return;
   wid := _tbGetActiveFindSymbolForm();
   if (wid != 0) {
      // were we searching in the project?
      if (wid.ctl_search_for.p_text != "" && 
          wid.ctl_lookin.p_text == VS_TAG_FIND_TYPE_PROJECT_ONLY) {
         // just clear everything out
         wid.ctl_search_for.p_text = "";
      }
   }
}

void _wkspace_close_find_symbol()
{
   wid := _tbGetActiveFindSymbolForm();
   if (wid != 0) {
      // were we searching in the project?
      if (wid.ctl_search_for.p_text != "" && 
          (wid.ctl_lookin.p_text == VS_TAG_FIND_TYPE_WORKSPACE_ONLY ||
           wid.ctl_lookin.p_text == VS_TAG_FIND_TYPE_WORKSPACE_PLUS)) {
         // just clear everything out
         wid.ctl_search_for.p_text = "";
      }
   }
}

/**
 * Timer callback to update lookin options for find symbol form.
 */
static void updateLookinOptionsTimerCB()
{
   wid := _tbGetActiveFindSymbolForm();
   if (wid != 0) {
      wid.ctl_lookin.updateLookinOptions();
   }
}

/**
 * Look-in options could change if the current buffer changes
 */
void _switchbuf_find_symbol()
{
   if (_in_batch_open_or_close_files()) return;
   wid := _tbGetActiveFindSymbolForm();
   if (wid != 0) {
      startFindSymbolOptionsTimer(updateLookinOptionsTimerCB);
   }
}



/**
 * Look-in options could change if tag files are added or removed
 */
void _TagFileAddRemove_find_symbol(_str file_name, _str options)
{
   wid := _tbGetActiveFindSymbolForm();
   if (wid != 0) {
      startFindSymbolOptionsTimer(updateLookinOptionsTimerCB);
   }
}

static _str getFirstFileExtension(_str tag_file)
{
   if (!_haveContextTagging()) {
      return "";
   }
   // open database
   status := tag_read_db(tag_file);
   if (status < 0) return "";

   // retrieve the first file extension type
   status = tag_find_language(auto lang);
   if (status) {
      tag_reset_find_language();
      return "";
   }

   // check for reject file extensions
   if (lang=="tagdoc") {
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
                                    bool &use_buffer)
{
   // initially empty array of tag files to return
   _str tag_files[];

   lookin := ctl_lookin.p_text;
   switch (lookin) {
   case VS_TAG_FIND_TYPE_CONTEXT:
      // context includes buffer and extension specific tag files
      use_buffer=true;
      tag_files = tags_filenamea(lang);
      return tag_files;

   case VS_TAG_FIND_TYPE_BUFFER_ONLY:
   case VS_TAG_FIND_TYPE_ALL_BUFFERS:
      // just buffer (no tag files)
      use_buffer=true;
      if (_isEditorCtl()) lang=p_LangId;
      return tag_files;

   case VS_TAG_FIND_TYPE_WORKSPACE_ONLY:
      // in workspace only, include buffer if it is in the workspace
      if (_project_name!="" && _WorkspaceFindFile(buffer_name, _workspace_filename, true, false, true) != "") {
         use_buffer = true;
      }
      tag_files = project_tags_filenamea();
      lang = getFirstFileExtension(tag_files[0]);
      return tag_files;

   case VS_TAG_FIND_TYPE_WORKSPACE_PLUS:
      // in workspace only, include buffer if it is in the workspace
      if (_project_name!="" && _WorkspaceFindFile(buffer_name, _workspace_filename, true, false, true) != "") {
         use_buffer = true;
      }
      tag_files = tags_filenamea(lang);
      return tag_files;

   case VS_TAG_FIND_TYPE_PROJECT_ONLY:
      // in current project only, include buffer if it is in the workspace
      if (_project_name!="" && _projectFindFile(_workspace_filename, _project_name, _RelativeToProject(buffer_name)) != "") {
         use_buffer = true;
      }
      tag_files[0] = project_tags_filename_only();
      lang = getFirstFileExtension(tag_files[0]);
      return tag_files;

   case VS_TAG_FIND_TYPE_SAME_PROJECTS:
      if (buffer_name != "") {
         tag_files._makeempty();
         bool foundTagFiles:[];
         refs_projects := _WorkspaceFindAllProjectsWithFile(buffer_name);
         foreach (auto one_project in refs_projects) {
            proj_tagfile := project_tags_filename_only(one_project);
            if (proj_tagfile == "") continue;
            if (foundTagFiles._indexin(_file_case(proj_tagfile))) continue;
            foundTagFiles:[_file_case(proj_tagfile)] = true;
            tag_files :+= proj_tagfile;
         }
         if (tag_files._length() <= 0) {
            tag_files[0] = workspace_tags_filename_only();
         }
      } else {
         if (_project_name!="" && _WorkspaceFindFile(buffer_name, _workspace_filename, true, false, true) != "") {
            use_buffer = true;
         }
         tag_files = project_tags_filenamea();
         lang = getFirstFileExtension(tag_files[0]);
      }
      return tag_files;

   case VS_TAG_FIND_TYPE_EVERYWHERE:
      // in all tag files, include the buffer too, why not?
      use_buffer=true;
      return ctl_lookin.tags_filenamea("");

   default:
      // look in a specific tag file, ignore the current buffer
      if (_first_char(lookin)=="<") {
         mode_name := "";
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
   wid := _tbGetActiveFindSymbolForm();
   if (wid != 0) {
      status := wid.getSelectedSymbol(auto cm);
      if (!status) {
         cb_refresh_output_tab(cm, true, true, false, APF_FIND_SYMBOL);
         cb_refresh_property_view(cm);
         cb_refresh_arguments_view(cm);
      }
   }
   killFindSymbolUpdateTimer();
}

/**
 * Preview symbol when paging through list.
 */
void ctl_symbols.on_change(int reason,int index)
{
   if (reason == CHANGE_SELECTED) {
      if (gIgnoreSelectChange) {
         return;
      }
      status := getSelectedSymbol(auto cm);
      if (!status) {
         startFindSymbolUpdateTimer(updateSymbolPreview);
      }
   } else if (reason == CHANGE_LEAF_ENTER) {
      call_event(ctl_goto_symbol.p_window_id, LBUTTON_UP);
      maybeHideFindSymbol();
   }
}

void ctl_symbols.on_highlight(int index, _str caption="")
{
   if (!def_tag_hover_preview) return;
   if (index < 0) {
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

static bool checkStopCondition()
{
   if ( ctl_search_stop.p_user ) {
      return true;
   }

   // prepare to safely call process events
   orig_use_timers := _use_timers;
   orig_def_actapp := def_actapp;
   def_actapp=0;
   _use_timers=0;
   orig_view_id := p_window_id;
   activate_window(VSWID_HIDDEN);
   orig_hidden_buf_id := p_buf_id;
   save_pos(auto orig_hidden_pos);

   // process mouse clicks, redraws, etc
   cancel := false;
   process_events(cancel);

   // restore everything after calling process events
   activate_window(VSWID_HIDDEN);
   p_buf_id=orig_hidden_buf_id;
   restore_pos(orig_hidden_pos);
   if (_iswindow_valid(orig_view_id)) {
      activate_window(orig_view_id);
   }
   _use_timers=orig_use_timers;
   def_actapp=orig_def_actapp;
   if (!_iswindow_valid(orig_view_id)) {
      return true;
   }

   if ( cancel ) {
      return true;
   }
   if ( ctl_search_stop.p_user ) {
      return true;
   }
   focus_wid := _get_focus();
   if (!focus_wid || focus_wid.p_active_form != ctl_search_stop.p_active_form) {
      return true;
   }

   // all clear to keep going
   return false;
}

/**
 * Determine if the given symbol matches the current search pattern and options.
 * 
 * @param search_for       symbol pattern - text in "Search for:" text box
 * @param search_word_only the part of the search term after then last package separator 
 * @param class_name       symbol class name 
 * @param tag_name         symbol tag name 
 * @param symbol_name      symbol name (optionally including class name) 
 * @param exact_match      exact (whole word) match or prefix match (false)
 * @param case_sensitive   case sensitive (true) or case-insensitive (false)
 * @param substring        do a substring match (true) or prefix match (false)
 * @param regex_type       regular expression type 
 * @param qualify_class    are they searching based on class/tag, not just tag name? 
 * 
 * @return Returns 'true' if the symbol matches, 'false' otherwise.
 */
static bool tagSymbolMatchesPattern(_str search_for, 
                                    _str search_word_only,
                                    _str class_name,
                                    _str tag_name,
                                    bool exact_match, 
                                    bool case_sensitive, 
                                    _str regex_type,
                                    _str regex_separator,
                                    bool substring, 
                                    bool qualify_class)
{
   // no search expression?
   if (search_for == "") {
      return true;
   }

   // put together class and tag name
   class_and_tag := tag_name;
   if ( qualify_class && class_name != "" ) {
      class_name = stranslate(class_name, VS_TAGSEPARATOR_package, VS_TAGSEPARATOR_class);
      if (regex_type !='' && regex_type != 's' && regex_separator != "") {
         class_name = stranslate(class_name, regex_separator, VS_TAGSEPARATOR_package);
      }
      class_and_tag = class_name :+ VS_TAGSEPARATOR_package :+ tag_name;
   }

   // make sure that the word matches the substring, pattern, or entire word
   //say("tagSymbolMatchesPattern H"__LINE__": search_for="search_for" class_and_tag="class_and_tag" regex_type="regex_type);
   sub_pos := 1;
   if (regex_type == 's') {
      sub_matches := tag_matches_symbol_name_pattern(search_for, class_and_tag, exact_match, case_sensitive, SE_TAG_CONTEXT_MATCH_STSK_SUBWORD);
      if (!sub_matches) {
         return false;
      }
   } else {
      case_option := case_sensitive? 'e':'i';
      sub_pos = pos(search_for, class_and_tag, 1, case_option:+regex_type);
      if (sub_pos <= 0) {
         return false;
      }
   }

   if ( qualify_class && class_name != "" ) {
      // the match *must* involve the tag name, not just the class
      // try matching just the class, if it matches, kick it out
      if (regex_type == 's') {
         p := tag_matches_symbol_name_pattern(search_for, class_name, exact_match, case_sensitive, SE_TAG_CONTEXT_MATCH_STSK_SUBWORD)? 1:0;
         if (p > 0) {
            return false;
         }
      } else {
         case_option := case_sensitive? 'e':'i';
         p := pos(search_for, class_name, 1, case_option:+regex_type);
         if (p > 0) {
            return false;
         }
      }
   }

   // if this is a prefix match, either the tag or class needs to match
   if (!substring) {

      // if this is a prefix match, the tag name should match the word
      have_word_prefix := true;
      if (qualify_class && class_name != "" && search_word_only != "" && search_for != search_word_only) {
         if (regex_type == 's') {
            fc_search_for  := _first_char(search_word_only);
            fc_symbol_name := _first_char(tag_name);
            have_word_prefix = ((fc_search_for == fc_symbol_name) ||
                                (!case_sensitive && lowcase(fc_search_for) == lowcase(fc_symbol_name)));
         } else {
            case_option := case_sensitive? 'e':'i';
            p := pos(search_word_only, tag_name, 1, case_option:+regex_type);
            have_word_prefix = (p == 1);
         }
      }

      // does the class name match the pattern prefix?
      have_class_prefix := true;
      if (regex_type == 's') {
         fc_search_for  := _first_char(search_for);
         fc_symbol_name := _first_char(class_and_tag);
         have_class_prefix = ((fc_search_for == fc_symbol_name) ||
                              (!case_sensitive && lowcase(fc_search_for) == lowcase(fc_symbol_name)));
      } else {
         // does the class name match the pattern prefix?
         have_class_prefix = (sub_pos == 1);
      }

      // if neither prefix matches, then toss this result
      if (!have_word_prefix && !have_class_prefix) {
         return false;
      }
   }

   // looks good enough to me
   return true;
}

/**
 * Insert the current match set into the symbol list
 */
static int updateSymbolList()
{
   // hash table for results we have already seen
   bool been_there_done_that:[];
   been_there_done_that._makeempty();

   // get the regular expression options
   enabled         := false;
   num_items_added := 0;

   // get the caption of the current item selected
   current_item  := "";
   current_index := ctl_symbols._TreeCurIndex();
   if (current_index > 0) {
      current_item = ctl_symbols._TreeGetCaption(current_index);
   }

   // get the list of projects to check if files belong to
   _str found_in_projects[];
   if (ctl_lookin.p_text == VS_TAG_FIND_TYPE_PROJECT_ONLY && _project_name != "") {
      found_in_projects[0] = _project_name;
   } else if (ctl_lookin.p_text == VS_TAG_FIND_TYPE_SAME_PROJECTS && _workspace_filename != "") {
      // get the information about the current buffer
      if (!_no_child_windows()) {
         editorctl_wid := _mdi.p_child;
         buffer_name := editorctl_wid.p_buf_name;
         found_in_projects = _WorkspaceFindAllProjectsWithFile(buffer_name, _workspace_filename, true);
      }
      if (found_in_projects._length() <= 0 && _project_name != "") {
         found_in_projects[0] = _project_name;
      }
   }

   // make sure that symbol browser bitmaps are loaded and ready
   // and prepare tree for expansion
   cb_prepare_expand(p_active_form,ctl_symbols.p_window_id,TREE_ROOT_INDEX);
   ctl_symbols._TreeBeginUpdate(TREE_ROOT_INDEX);

   // for each symbol in the match set
   struct VS_TAG_BROWSE_INFO cm;
   n := tag_get_num_of_matches();
   for (i:=1; i<=n; ++i) {

      // get the symbol information
      tag_get_match_info(i, cm);
      //say("updateSymbolList H"__LINE__": cm.tag="cm.member_name);

      // check if they hit escape or another key
      if ( (i % def_tag_max_find_context_tags)==0 && checkStopCondition()) {
         break;
      }

      // limit search results to items in the calculated set of projects.
      if (found_in_projects._length() >= 1) {
         foundInProject := false;
         foreach (auto one_project in found_in_projects) {
            if (one_project == "") continue;
            if (_isFileInProject(_workspace_filename, one_project, cm.file_name)) {
               foundInProject = true;
               break;
            }
         }
         if (!foundInProject) {
            continue;
         }
      }

      // make sure that the word matches the substring, pattern, or entire word
      //if (!tagSymbolMatchesPattern(word, substring_word,
      //                             class_name, tag_name,
      //                             exact_match:false, case_sensitive, 
      //                             regex_type, regex_separator, 
      //                             substring, qualify_class)) {
      //   continue;
      //}

      // make a caption for this symbol, including file name and line number
      caption := tag_tree_make_caption_fast(VS_TAGMATCH_match, i, include_class:true, include_args:true, include_tab:true);
      if (!pos("\t", caption)) caption :+= "\t";
      caption  :+= "\t":+_strip_filename(cm.file_name,'P'):+"\t":+_strip_filename(cm.file_name,'N'):+"\t":+cm.line_no;

      // check if we have already added this item
      if (been_there_done_that._indexin(caption)) continue;
      been_there_done_that:[caption]=true;

      // select the symbol browser bitmap to show for this symbol
      pic_member := tag_get_bitmap_for_type(tag_get_type_id(cm.type_name), cm.flags, auto pic_overlay);

      // add it to the tree and store symbol info in user info
      enabled = true;
      num_items_added++;
      k := ctl_symbols._TreeAddItem(TREE_ROOT_INDEX, caption, 
                                    TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1, 
                                    pic_overlay, pic_member, TREE_NODE_LEAF, 0, cm);
   }

   // finished updating, now sort tree, jump to top, and refresh
   ctl_symbols._TreeEndUpdate(TREE_ROOT_INDEX);
   ctl_symbols._TreeSortCol();
   ctl_symbols._TreeTop();
   ctl_symbols._TreeRefresh();
   
   // reposition the tree back on the previously selected item
   if (current_item != "") {
      current_index = ctl_symbols._TreeSearch(TREE_ROOT_INDEX, current_item);
      if (current_index > 0) ctl_symbols._TreeSetCurIndex(current_index);
   }

   // disable/enable buttons
   ctl_goto_symbol.p_enabled     = enabled;
   ctl_find_references.p_enabled = enabled;
   ctl_show_in_classes.p_enabled = enabled;
   return num_items_added;
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
   tag_init_tag_browse_info(cm);
   index := ctl_symbols._TreeCurIndex();
   if (index <= 0) {
      return STRING_NOT_FOUND_RC;
   }

   // browse info is stored in the user info
   cm = ctl_symbols._TreeGetUserInfo(index);
   if (cm == null) {
      return STRING_NOT_FOUND_RC;
   }
   if (!(cm instanceof VS_TAG_BROWSE_INFO)) {
      return STRING_NOT_FOUND_RC;
   }
   if ( cm.member_name==null && cm.file_name==null ) {
      return STRING_NOT_FOUND_RC;
   }

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
   label := "Search options: ";
   switch (ctl_case_sensitive.p_value) {
   case 0:
      label :+= "Ignore case, ";
      break;
   case 1:
      label :+= "Match case, ";
      break;
   case 2:
      // no label for both
      break;
   }

   // qualified name or symbol name only
   switch (ctl_qualified_name.p_value) {
   case 0:
      label :+= "Name Only, ";
      break;
   case 1:
      label :+= "Package/Class/Name, ";
      break;
   case 2:
      // no label for both
      break;
   }

   // prefix or substring match
   switch (ctl_substring.p_value) {
   case 0:
      label :+= "Prefix, ";
      break;
   case 1:
      label :+= "Substring, ";
      break;
   case 2:
      // no label for both
      break;
   }

   // regular expression type
   if (ctl_use_regex.p_value) {
      label :+= ctl_regex_type.p_text:+", ";
   }

   // symbol filters
   label :+= getFilterOptionsString(def_find_symbol_flags);
   return label;
}

/**
 * Toggle the search options as expanded or collapsed
 */
void ctl_options_button.lbutton_up()
{
   if (gIgnoreSearchChange || gIgnoreSelectChange) {
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
// STOP SEARCHING NOW
//

void ctl_search_stop.lbutton_up()
{
   ctl_search_stop.p_user=true;
}

//////////////////////////////////////////////////////////////////////////////
// CASE SENSITIVE CHECK BOX
//

void ctl_case_sensitive.lbutton_up()
{
   updateSearchResultsDelayed();
}

//////////////////////////////////////////////////////////////////////////////
// PACKAGE/CLASS/NAME MATCH CHECK BOX
//

void ctl_qualified_name.lbutton_up()
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
      return "";
   }
   switch (ctl_regex_type.p_text) {
   //case RE_TYPE_UNIX_STRING:        return "u";
   //case RE_TYPE_BRIEF_STRING:       return "b";
   case RE_TYPE_SLICKEDIT_STRING:   return "r";
   case RE_TYPE_PERL_STRING:        return "l";
   case RE_TYPE_VIM_STRING:         return "~";
   case RE_TYPE_WILDCARD_STRING:    return "&";
   case VS_TAG_FIND_SUBWORD_PATTERN_MATCH: return 's';
   }
   return "";
}

/**
 * A change in regular expression types requires a symbol update
 */
void ctl_regex_type.on_change(int reason)
{
   switch (reason) {
   case CHANGE_SELECTED:
   case CHANGE_CLINE:
   case CHANGE_CLINE_NOTVIS:
      updateSearchResultsDelayed();
      break;
   }
}

/**
 * Initialize the list of regular expression types
 */
static void updateRegexTypes()
{
   // prevent form from searching when then items are inserted
   origIgnoreSearchChange := gIgnoreSearchChange;
   origIgnoreSelectChange := gIgnoreSelectChange;
   gIgnoreSearchChange = true;
   gIgnoreSelectChange = true;

   _lbadd_item(VS_TAG_FIND_SUBWORD_PATTERN_MATCH);
   _lbadd_item(RE_TYPE_SLICKEDIT_STRING);
   _lbadd_item(RE_TYPE_PERL_STRING);
   _lbadd_item(RE_TYPE_VIM_STRING);
   _lbadd_item(RE_TYPE_WILDCARD_STRING);
   //_lbadd_item(RE_TYPE_UNIX_STRING);
   //_lbadd_item(RE_TYPE_BRIEF_STRING);

   // restore the ignore changes flag
   gIgnoreSearchChange = origIgnoreSearchChange;
   gIgnoreSelectChange = origIgnoreSelectChange;

}

/**
 * Turning on/off regular expression search forces a refresh
 */
void ctl_use_regex.lbutton_up()
{
   _re_button.p_enabled = ctl_regex_type.p_enabled = (p_value != 0);
   if (p_value != 0 && !ctl_substring.p_value) {
      ctl_substring.p_value = 1;
   }
   updateSearchResultsDelayed();
}


//////////////////////////////////////////////////////////////////////////////
// SYMBOL FILTER OPTIONS
//

/**
 * Shortcut to expand or collapse search options
 */
void _tbfind_symbol_form."A-O"()
{
   orig_wid := p_window_id;
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
   orig_wid := p_window_id;
   index := find_index("_tagbookmark_menu",oi2type(OI_MENU));
   menu_handle := p_active_form._menu_load(index,'P');

   // configure it for this dialog use
   flags := def_find_symbol_flags;
   pushTgConfigureMenu(menu_handle, flags, 
                       include_proctree:false, 
                       include_casesens:true, 
                       include_sort:false, 
                       include_save_print:true);

   // Show menu:
   mou_get_xy(auto x, auto y);
   _KillToolButtonTimer();
   status := _menu_show(menu_handle,VPM_LEFTBUTTON,x-1,y-1);
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
_str getFilterOptionsString(SETagFilterFlags filter_flags)
{
   label := "Filters: ";
   positive_label := "";
   negative_label := "";
   filter_flags &= SE_TAG_FILTER_ANYTHING;
   pflags := filter_flags;  // for positive tests
   nflags := filter_flags;  // for negative tests

   // check if all the filters are turned on
   if ((pflags & SE_TAG_FILTER_ANYTHING) == SE_TAG_FILTER_ANYTHING) {
      label :+= "All symbol types";
      return label;
   }

   // member access restrictions
   moreLabel := "";
   if ((pflags & SE_TAG_FILTER_ANY_SCOPE) != SE_TAG_FILTER_ANY_SCOPE) {

      // access restrictions
      skip_static_and_extern := false;
      if ((pflags & SE_TAG_FILTER_ANY_ACCESS) == SE_TAG_FILTER_SCOPE_PUBLIC) {
         moreLabel :+= ", Public";
         skip_static_and_extern = true;
      } else if ((pflags & SE_TAG_FILTER_ANY_ACCESS) == SE_TAG_FILTER_SCOPE_PROTECTED) {
         moreLabel :+= ", Protected";
         skip_static_and_extern = true;
      } else if ((pflags & SE_TAG_FILTER_ANY_ACCESS) == SE_TAG_FILTER_SCOPE_PRIVATE) {
         moreLabel :+= ", Private";
         skip_static_and_extern = true;
      } else if ((pflags & SE_TAG_FILTER_ANY_ACCESS) == SE_TAG_FILTER_SCOPE_PACKAGE) {
         moreLabel :+= ", Package scope";
         skip_static_and_extern = true;
      } else if ((pflags & SE_TAG_FILTER_ANY_ACCESS) == 0) {
         moreLabel :+= ", No access";
         skip_static_and_extern = true;
      } else {
         if (!(pflags & SE_TAG_FILTER_SCOPE_PUBLIC)) {
            moreLabel :+= ", No public";
         }
         if (!(pflags & SE_TAG_FILTER_SCOPE_PROTECTED)) {
            moreLabel :+= ", No protected";
         }
         if (!(pflags & SE_TAG_FILTER_SCOPE_PRIVATE)) {
            moreLabel :+= ", No private";
         }
         if (!(pflags & SE_TAG_FILTER_SCOPE_PACKAGE)) {
            moreLabel :+= ", No package scope";
         }
      }

      // static vs. non-static
      if (!skip_static_and_extern) {
         if ((pflags & (SE_TAG_FILTER_SCOPE_STATIC|SE_TAG_FILTER_SCOPE_EXTERN)) != (SE_TAG_FILTER_SCOPE_STATIC|SE_TAG_FILTER_SCOPE_EXTERN)) {
            if (pflags & SE_TAG_FILTER_SCOPE_STATIC) {
               moreLabel :+= ", Static";
            } else {
               moreLabel :+= ", No static";
            }
            // extern vs. non-extern
            if (pflags & SE_TAG_FILTER_SCOPE_EXTERN) {
               moreLabel :+= ", Extern";
            } else {
               moreLabel :+= ", No extern";
            }
         }
      }
   }

   // names for quick filters
   filter_flags &= ~SE_TAG_FILTER_ANY_SCOPE;
   filter_flags &= ~SE_TAG_FILTER_STATEMENT;
   switch (filter_flags) {
   case SE_TAG_FILTER_ANY_PROCEDURE_NO_PROTOTYPE:  return label :+ "Functions only"       :+ moreLabel;
   case SE_TAG_FILTER_PROTOTYPE:                   return label :+ "Prototypes only"      :+ moreLabel;
   case SE_TAG_FILTER_ANY_DATA:                    return label :+ "Data only"            :+ moreLabel;
   case SE_TAG_FILTER_ANY_STRUCT:                  return label :+ "Structs/classes only" :+ moreLabel;
   case SE_TAG_FILTER_ANY_CONSTANT:                return label :+ "Constants only"       :+ moreLabel;
   case SE_TAG_FILTER_ANYTHING:                    return label :+ "All symbol types"     :+ moreLabel;
   }

   // general categories for function types
   if ((pflags & SE_TAG_FILTER_ANY_PROCEDURE) == SE_TAG_FILTER_ANY_PROCEDURE_NO_PROTOTYPE) {
      positive_label :+= ", Functions";
      pflags &= ~SE_TAG_FILTER_ANY_PROCEDURE;
   } else if ((pflags & SE_TAG_FILTER_ANY_PROCEDURE) == SE_TAG_FILTER_ANY_PROCEDURE) {
      positive_label :+= ", All Functions";
      pflags &= ~SE_TAG_FILTER_ANY_PROCEDURE;
   } else if ((pflags & SE_TAG_FILTER_ANY_PROCEDURE) == SE_TAG_FILTER_PROTOTYPE) {
      positive_label :+= ", Prototypes";
      pflags &= ~SE_TAG_FILTER_ANY_PROCEDURE;
   } else if ((nflags & SE_TAG_FILTER_ANY_PROCEDURE) == 0) {
      negative_label :+= ", No functions";
      nflags |= SE_TAG_FILTER_ANY_PROCEDURE;
   } else {
      if (pflags & SE_TAG_FILTER_PROCEDURE) {
         positive_label :+= ", Procs";
      }
      if ((nflags & SE_TAG_FILTER_PROCEDURE) == 0) {
         negative_label :+= ", No Procs";
      }

      if (pflags & SE_TAG_FILTER_PROTOTYPE) {
         positive_label :+= ", Prototypes";
      }
      if ((nflags & SE_TAG_FILTER_PROTOTYPE) == 0) {
         negative_label :+= ", No Prototypes";
      }

      if (pflags & SE_TAG_FILTER_SUBPROCEDURE) {
         positive_label :+= ", Subprocs";
      }
      if ((nflags & SE_TAG_FILTER_SUBPROCEDURE) == 0) {
         negative_label :+= ", No Subprocs";
      }
   }

   // general categories for variables
   if ((pflags & SE_TAG_FILTER_ANY_DATA) == SE_TAG_FILTER_ANY_DATA) {
      positive_label :+= ", Variables";
      pflags &= ~SE_TAG_FILTER_ANY_DATA;
   } else if ((nflags & SE_TAG_FILTER_ANY_DATA) == 0) {
      negative_label :+= ", No variables";
      nflags |= SE_TAG_FILTER_ANY_DATA;
   } else {
      if (pflags & SE_TAG_FILTER_GLOBAL_VARIABLE) {
         positive_label :+= ", Global Variables";
      }
      if ((nflags & SE_TAG_FILTER_GLOBAL_VARIABLE) == 0) {
         negative_label :+= ", No Global Variables";
      }

      if (pflags & SE_TAG_FILTER_MEMBER_VARIABLE) {
         positive_label :+= ", Member Variables";
      }
      if ((nflags & SE_TAG_FILTER_MEMBER_VARIABLE) == 0) {
         negative_label :+= ", No Member Variables";
      }

      if (pflags & SE_TAG_FILTER_LOCAL_VARIABLE) {
         positive_label :+= ", Local Variables";
      }
      if ((nflags & SE_TAG_FILTER_LOCAL_VARIABLE) == 0) {
         negative_label :+= ", No Local Variables";
      }

      if (pflags & SE_TAG_FILTER_PROPERTY) {
         positive_label :+= ", Properties";
      }
      if ((nflags & SE_TAG_FILTER_PROPERTY) == 0) {
         negative_label :+= ", No Properties";
      }
   }

   // general categories for classes
   if ((pflags & SE_TAG_FILTER_ANY_STRUCT) == SE_TAG_FILTER_ANY_STRUCT) {
      positive_label :+= ", Structs and classes";
      pflags &= ~SE_TAG_FILTER_ANY_STRUCT;
   } else if ((nflags & SE_TAG_FILTER_ANY_DATA) == 0) {
      negative_label :+= ", No Structs or classes";
      nflags |= SE_TAG_FILTER_ANY_STRUCT;
   } else {
      if (pflags & SE_TAG_FILTER_STRUCT) {
         positive_label :+= ", Structs";
      }
      if ((nflags & SE_TAG_FILTER_STRUCT) == 0) {
         negative_label :+= ", No Structs";
      }

      if (pflags & SE_TAG_FILTER_UNION) {
         positive_label :+= ", Unions";
      }
      if ((nflags & SE_TAG_FILTER_UNION) == 0) {
         negative_label :+= ", No Unions";
      }

      if (pflags & SE_TAG_FILTER_INTERFACE) {
         positive_label :+= ", Interfaces";
      }
      if ((nflags & SE_TAG_FILTER_INTERFACE) == 0) {
         negative_label :+= ", No Interfaces";
      }
   }

   // general categories for classes
   if ((pflags & SE_TAG_FILTER_ANY_CONSTANT) == SE_TAG_FILTER_ANY_CONSTANT) {
      positive_label :+= ", Defines and constants";
      pflags &= ~SE_TAG_FILTER_ANY_CONSTANT;
   } else if ((nflags & SE_TAG_FILTER_ANY_DATA) == 0) {
      negative_label :+= ", No Defines or constants";
      nflags |= SE_TAG_FILTER_ANY_CONSTANT;
   } else {
      if (pflags & SE_TAG_FILTER_DEFINE) {
         positive_label :+= ", Defines";
      }
      if ((nflags & SE_TAG_FILTER_DEFINE) == 0) {
         negative_label :+= ", No Defines";
      }

      if (pflags & SE_TAG_FILTER_ENUM) {
         positive_label :+= ", Enums";
      }
      if ((nflags & SE_TAG_FILTER_ENUM) == 0) {
         negative_label :+= ", No Enums";
      }

      if (pflags & SE_TAG_FILTER_CONSTANT) {
         positive_label :+= ", Constants";
      }
      if ((nflags & SE_TAG_FILTER_CONSTANT) == 0) {
         negative_label :+= ", No Constants";
      }
   }

   // set up states of the rest of the flags
   if (pflags & SE_TAG_FILTER_TYPEDEF) {
      positive_label :+= ", Typedefs";
   }
   if ((nflags & SE_TAG_FILTER_TYPEDEF) == 0) {
      negative_label :+= ", No Typedefs";
   }

   if (pflags & SE_TAG_FILTER_LABEL) {
      positive_label :+= ", Labels";
   }
   if ((nflags & SE_TAG_FILTER_LABEL) == 0) {
      negative_label :+= ", No Labels";
   }

   if (pflags & SE_TAG_FILTER_PACKAGE) {
      positive_label :+= ", Packages";
   }
   if ((nflags & SE_TAG_FILTER_PACKAGE) == 0) {
      negative_label :+= ", No Packages";
   }

   if (pflags & SE_TAG_FILTER_DATABASE) {
      positive_label :+= ", Databases";
   }
   if ((nflags & SE_TAG_FILTER_DATABASE) == 0) {
      negative_label :+= ", No Databases";
   }

   if (pflags & SE_TAG_FILTER_GUI) {
      positive_label :+= ", Forms";
   }
   if ((nflags & SE_TAG_FILTER_GUI) == 0) {
      negative_label :+= ", No Forms";
   }

   if (pflags & SE_TAG_FILTER_INCLUDE) {
      positive_label :+= ", Includes";
   }
   if ((nflags & SE_TAG_FILTER_INCLUDE) == 0) {
      negative_label :+= ", No Includes";
   }

   if (pflags & SE_TAG_FILTER_ANNOTATION) {
      positive_label :+= ", Annotations";
   }
   if ((nflags & SE_TAG_FILTER_ANNOTATION) == 0) {
      negative_label :+= ", No Annotations";
   }

   if (pflags & SE_TAG_FILTER_UNKNOWN) {
      positive_label :+= ", Unrecognized.";
   }
   if ((nflags & SE_TAG_FILTER_UNKNOWN) == 0) {
      negative_label :+= ", No Unrecognized Symbols";
   }

   if (pflags & SE_TAG_FILTER_MISCELLANEOUS) {
      positive_label :+= ", Misc.";
   }
   if ((nflags & SE_TAG_FILTER_MISCELLANEOUS) == 0) {
      negative_label :+= ", No Misc. Symbols";
   }

   // trim off leading commas
   positive_label = strip(positive_label, "L", ", ");
   negative_label = strip(negative_label, "L", ", ");

   // choose the lesser of two evils
   if (length(positive_label) <= length(negative_label)) {
      label :+= positive_label;
   } else {
      label :+= negative_label;
   }

   // absolutely no scope limitations?
   if ((pflags & SE_TAG_FILTER_ANY_SCOPE) == SE_TAG_FILTER_ANY_SCOPE) {
      return label;
   }

   return label :+ moreLabel;
}

//////////////////////////////////////////////////////////////////////////////
/**
 * Insert a symbol into the tree control containing the list of symbols 
 * in the standard way needed by the Find Symbol tool window. 
 * 
 * @param match_type          VS_TAGMATCH_*
 * @param local_or_context_id 0 if inserting current tag from database, 
 *                            otherwise, specifies the unique integer ID of the item from the context,
 *                            locals, or match set, as specified by <i>match_type</i>.
 *  
 * @return Returns the tree index of the symbol.
 */
static int findSymbolInsertTag(int match_type,int local_or_context_id)
{
   // create the baseline caption
   caption := tag_tree_make_caption_fast(match_type, local_or_context_id, 
                                         include_class:true, 
                                         include_args:true, 
                                         include_tab:true);

   // get the tag information to plug into user info
   VS_TAG_BROWSE_INFO cm =null;
   if ( match_type == VS_TAGMATCH_local ) {
      tag_get_local_browse_info(local_or_context_id, cm);
   } else if (match_type == VS_TAGMATCH_context) {
      tag_get_context_browse_info(local_or_context_id, cm);
   } else if (match_type == VS_TAGMATCH_match) {
      tag_get_match_browse_info(local_or_context_id, cm);
   } else {
      tag_get_tag_browse_info(cm);
   }

   // construct the rest of the caption
   if (!pos("\t", caption)) caption :+= "\t";
   caption :+= "\t":+_strip_filename(cm.file_name,'P');
   caption :+= "\t":+_strip_filename(cm.file_name,'N');
   caption :+= "\t":+cm.line_no;

   // get the picture indexes
   pic_member := tag_get_bitmap_for_type(tag_get_type_id(cm.type_name), cm.flags, auto pic_overlay);

   // now insert into the tree control
   k := ctl_symbols._TreeAddItem(TREE_ROOT_INDEX, caption, 
                                 TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1, 
                                 pic_overlay, pic_member, TREE_NODE_LEAF, 0, cm);
   return k;
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
                                 _str &substring_word,
                                 typeless tag_files, 
                                 bool use_buffer,
                                 bool substring,
                                 bool exact_match,
                                 bool case_sensitive,
                                 bool qualify_class,
                                 _str regex_type,
                                 SETagFilterFlags filter_flags
                                )
{
   // use for looking up tags later
   class_name := "";
   tag_name   := "";
   type_name := "";
   tag_flags := SE_TAG_FLAG_NULL;

   // save the "Look in" label so we can restore when we are done
   orig_lookin_label := ctl_lookin_label.p_caption;

   // progress bar updating, count locals as 5%, context at 15%,
   // and divide the rest among the tag files.
   progress_locals := 5;
   progress_context := 15;
   progress_tagfile := 80;
   ctl_progress.p_value=0;
   ctl_progress.refresh('w');
   if (tag_files._length()==0) {
      progress_locals  = 25;
      progress_context = 100;
      progress_tagfile = 0;
   }

   // number of results found so far
   VS_TAG_BROWSE_INFO cm=null;
   count := 0;
   p := 0;

   // option for pos() for searching case-sensitive
   case_option :=  case_sensitive? "e":"i";
   using_regex := (regex_type != '' && regex_type != 's');

   // if we are qualifying the symbol with it's class name, we need to
   // simplify the pattern with respect to class separators
   regex_separator := "";
   if (qualify_class && !using_regex) {
      word = stranslate(word, VS_TAGSEPARATOR_package, '::');
      word = stranslate(word, VS_TAGSEPARATOR_package, ':');
      word = stranslate(word, VS_TAGSEPARATOR_package, '.');
   } else if ( qualify_class && using_regex ) {
      if (pos("::", word) || pos("\\:", word) || pos("[:]", word)) {
         regex_separator = "::";
      } else if (pos("\\.", word) || pos("[.]", word)) {
         regex_separator = ".";
      }
   }

   // isolate the last word of the expression
   word_only := word;
   if (qualify_class) {
      last_sep := lastpos(VS_TAGSEPARATOR_package, word);
      if (last_sep > 0) word_only = substr(word, last_sep+1);
   }
   substring_word = word_only;
   word_prefix := "";
   if (!substring && (regex_type == '' || regex_type == 's')) {
      word_prefix = _first_char(word_only);
   }

   // search current buffer?
   if (use_buffer) {

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      ctl_lookin_label.p_caption = orig_lookin_label:+" ":+VS_TAG_FIND_TYPE_BUFFER_ONLY;

      // check locals in current function
      n := tag_get_num_of_locals();
      for (i:=1; i<=n; ++i) {

         // get the tag name to match against (maybe qualify with class name)
         tag_get_detail2(VS_TAGDETAIL_local_name, i, tag_name);
         tag_get_detail2(VS_TAGDETAIL_local_class, i, class_name);

         // now do the pattern match
         if (!tagSymbolMatchesPattern(word, word_only, 
                                      class_name, tag_name,
                                      exact_match, case_sensitive, 
                                      regex_type, regex_separator, 
                                      substring, qualify_class)) {
            continue;
         }

         // make sure the tag type and flags match
         tag_get_detail2(VS_TAGDETAIL_local_type, i, type_name);
         tag_get_detail2(VS_TAGDETAIL_local_flags, i, tag_flags);
         if (!tag_filter_type(SE_TAG_TYPE_NULL, filter_flags, type_name, (int)tag_flags)) {
            continue;
         }

         // got a match
         new_value := ((ctl_progress.p_max intdiv progress_locals) * i) intdiv n;
         ctl_progress.p_value = max(ctl_progress.p_value, new_value);
         ctl_progress.refresh('w');
         tag_insert_match_fast(VS_TAGMATCH_local, i);
         findSymbolInsertTag(VS_TAGMATCH_local, i);
         if (++count > def_tag_max_find_context_tags) {
            break;
         }
      }

      // check symbols in current buffer
      n = tag_get_num_of_context();
      for (i=1; i<=n; ++i) {

         // get the tag name to match against (maybe qualify with class name)
         tag_get_detail2(VS_TAGDETAIL_context_name, i, tag_name);
         tag_get_detail2(VS_TAGDETAIL_context_class, i, class_name);

         // now do the pattern match
         if (!tagSymbolMatchesPattern(word, word_only, 
                                      class_name, tag_name,
                                      exact_match, case_sensitive, 
                                      regex_type, regex_separator, 
                                      substring, qualify_class)) {
            continue;
         }

         // make sure the tag type and flags match
         tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
         tag_get_detail2(VS_TAGDETAIL_context_flags, i, tag_flags);
         if (!tag_filter_type(SE_TAG_TYPE_NULL, filter_flags, type_name, (int)tag_flags)) {
            continue;
         }

         // got a match
         new_value := (ctl_progress.p_max intdiv progress_locals) +
                      (ctl_progress.p_max intdiv progress_context) * i intdiv n;
         ctl_progress.p_value = max(ctl_progress.p_value, new_value);
         ctl_progress.refresh('w');
         tag_insert_match_fast(VS_TAGMATCH_context, i);
         findSymbolInsertTag(VS_TAGMATCH_context, i);
         if (++count > def_tag_max_find_context_tags) {
            break;
         }
      }
   }

   // done with current buffer, update progress
   progress_increment := 0;
   if (tag_files._length() == 0) {
      ctl_progress.p_value = ctl_progress.p_max;
   } else {
      new_value := ctl_progress.p_max intdiv 10;
      ctl_progress.p_value = max(ctl_progress.p_value, new_value);
      progress_increment = (ctl_progress.p_max - ctl_progress.p_value) intdiv tag_files._length();
   }
   ctl_progress.refresh('w');

   // now search in tag files
   keep_going := true;
   was_cancelled := false;
   iterations := 0;
   status := 0;
   i := 0;
   while (keep_going) {

      // number of potential matches found so far
      progress_count := 0;

      // get the next tag file name (and open it)
      tag_filename := next_tag_filea(tag_files, i, true, true);
      if (tag_filename=="") break;
      ctl_lookin_label.p_caption = orig_lookin_label:+" ":+_strip_filename(tag_filename, 'P');

      // prefix match, not regular expression, so use fast lookup
      if (qualify_class || (!substring && regex_type == 's')) {
         // find a prefix match
         status = tag_find_prefix(word_prefix, case_sensitive);
         while (status == 0) {

            // did the user stop the search?
            if ( (++iterations % 1000) == 0 ) {
               if (checkStopCondition()) {
                  keep_going = false;
                  was_cancelled = true;
                  break;
               }
               if (progress_count++ < progress_increment) {
                  ctl_progress.p_value++;
                  ctl_progress.refresh('w');
               }
            }

            // match against class name and symbol name
            tag_get_detail(VS_TAGDETAIL_name, tag_name);
            tag_get_detail(VS_TAGDETAIL_class_name, class_name);

            // now do the pattern match
            if (!tagSymbolMatchesPattern(word, word_only, 
                                         class_name, tag_name,
                                         exact_match, case_sensitive, 
                                         regex_type, regex_separator, 
                                         substring, qualify_class)) {
               status = tag_next_prefix(word_prefix, case_sensitive, null, true);
               continue;
            }

            // got one, make sure it matches filters
            tag_get_detail(VS_TAGDETAIL_type, type_name);
            tag_get_detail(VS_TAGDETAIL_flags, tag_flags);
            if (tag_filter_type(SE_TAG_TYPE_NULL, filter_flags, type_name, (int)tag_flags)) {
               tag_insert_match_fast(VS_TAGMATCH_tag, 0);
               findSymbolInsertTag(VS_TAGMATCH_tag, 0);
               if (++count > def_tag_max_find_context_tags) {
                  keep_going = false;
                  break;
               }
            }

            // update progress counter, do not let it overflow
            if (progress_count++ < progress_increment) {
               ctl_progress.p_value++;
               ctl_progress.refresh('w');
            }

            // next match please
            status = tag_next_prefix(word_prefix, case_sensitive);
         }
         tag_reset_find_tag();

      } else if (!substring && regex_type=="") {

         orig_count := count;
         if (exact_match) {
            // find an exact match
            status = tag_find_equal(word, case_sensitive);
            while (status == 0) {

               // did the user stop the search?
               if ( (++iterations % 500) == 0 ) {
                  if (checkStopCondition()) {
                     keep_going = false;
                     was_cancelled = true;
                     break;
                  }
                  if (progress_count++ < progress_increment) {
                     ctl_progress.p_value++;
                     ctl_progress.refresh('w');
                  }
               }

               // got one, make sure it matches filters
               tag_get_detail(VS_TAGDETAIL_type, type_name);
               tag_get_detail(VS_TAGDETAIL_flags, tag_flags);
               if (tag_filter_type(SE_TAG_TYPE_NULL, filter_flags, type_name, (int)tag_flags)) {
                  tag_insert_match_fast(VS_TAGMATCH_tag, 0);
                  findSymbolInsertTag(VS_TAGMATCH_tag, 0);
                  if (++count > def_tag_max_find_context_tags) {
                     keep_going = false;
                     break;
                  }
               }

               // update progress counter, do not let it overflow
               if (progress_count++ < progress_increment) {
                  ctl_progress.p_value++;
                  ctl_progress.refresh('w');
               }

               // next match please
               status = tag_next_equal(case_sensitive);
            }
         }

         if (count == orig_count || !exact_match) {
            // find a prefix match
            status = tag_find_prefix(word, case_sensitive);
            while (status == 0) {

               // did the user stop the search?
               if ( (++iterations % 500) == 0 ) {
                  if (checkStopCondition()) {
                     keep_going = false;
                     was_cancelled = true;
                     break;
                  }
                  if (progress_count++ < progress_increment) {
                     ctl_progress.p_value++;
                     ctl_progress.refresh('w');
                  }
               }

               // got one, make sure it matches filters
               tag_get_detail(VS_TAGDETAIL_type, type_name);
               tag_get_detail(VS_TAGDETAIL_flags, tag_flags);
               if (tag_filter_type(SE_TAG_TYPE_NULL, filter_flags, type_name, (int)tag_flags)) {
                  tag_insert_match_fast(VS_TAGMATCH_tag, 0);
                  findSymbolInsertTag(VS_TAGMATCH_tag, 0);
                  if (++count > def_tag_max_find_context_tags) {
                     keep_going = false;
                     break;
                  }
               }

               // update progress counter, do not let it overflow
               if (progress_count++ < progress_increment) {
                  ctl_progress.p_value++;
                  ctl_progress.refresh('w');
               }

               // next match please
               status = tag_next_prefix(word, case_sensitive);
            }
         }
         tag_reset_find_tag();

      } else {

         // either substring match or regular expression
         // never have to worry about class qualification here

         // search for substring match
         status = tag_find_regex(word, case_option:+regex_type);
         while (status == 0) {

            // did the user stop the search?
            if ( (++iterations % 500) == 0 ) {
               if (checkStopCondition()) {
                  keep_going = false;
                  was_cancelled = true;
                  break;
               }
               if (progress_count++ < progress_increment) {
                  ctl_progress.p_value++;
                  ctl_progress.refresh('w');
               }
            }

            // check if it is a regular expression, prefix match
            tag_get_detail(VS_TAGDETAIL_name, tag_name);
            use_match := true;
            if (!substring) {
               tag_get_detail(VS_TAGDETAIL_name, tag_name);
               if (regex_type == 's') {
                  fc_word := _first_char(word);
                  fc_name := _first_char(tag_name);
                  use_match = (fc_word == fc_name);
                  if (!case_sensitive && !use_match) {
                     use_match = (lowcase(fc_word) == lowcase(fc_name));
                  }
               } else {
                  p = pos(word_only, tag_name, 1, case_option:+regex_type);
                  if (p != 1) {
                     use_match = false;
                  }
               }
            }

            // check that it matches tag filters
            tag_get_detail(VS_TAGDETAIL_type, type_name);
            tag_get_detail(VS_TAGDETAIL_flags, tag_flags);
            if (!tag_filter_type(SE_TAG_TYPE_NULL, filter_flags, type_name, (int)tag_flags)) {
               use_match = false;
            }

            // add it to the match set
            if (use_match) {
               tag_insert_match_fast(VS_TAGMATCH_tag, 0);
               findSymbolInsertTag(VS_TAGMATCH_tag, 0);
               if (++count > def_tag_max_find_context_tags) {
                  keep_going = false;
                  break;
               }
            }

            // next match please
            status = tag_next_regex(word, case_option:+regex_type);
         }
         tag_reset_find_tag();
      }

      // finalize progress for this tag file
      new_value := (ctl_progress.p_max intdiv progress_locals) +
                   (ctl_progress.p_max intdiv progress_context) +
                   (progress_increment*i);
      ctl_progress.p_value = max(ctl_progress.p_value, new_value);
      ctl_progress.refresh('w');
   }

   // max out progress count
   ctl_lookin_label.p_caption = orig_lookin_label;
   ctl_progress.p_value = ctl_progress.p_max;
   ctl_progress.refresh('w');

   // cancelled, return 0
   if (was_cancelled) {
      return COMMAND_CANCELLED_RC;
   }

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
                                int editorctl_wid, 
                                _str lang,
                                bool exact_match,
                                bool case_sensitive,
                                _str regex_type,
                                SETagFilterFlags filter_flags,
                                bool substring_match,
                                _str &substring_word,
                                struct VS_TAG_RETURN_TYPE (&visited):[]
                                )
{
   // extract information about the current expression
   orig_view_id := 0;
   temp_view_id := 0;
   orig_view_id = _create_temp_view(temp_view_id);
   p_LangId=lang;
   insert_line(word);
   _end_line();
   VS_TAG_IDEXP_INFO idexp_info;
   int status = _Embeddedget_expression_info(false, lang, idexp_info, visited);
   if (editorctl_wid) activate_window(editorctl_wid);
   if (status > 0) status = STRING_NOT_FOUND_RC;
   if (status < 0) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      return status;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // update the current context and locals
   _str errorArgs[];
   if (editorctl_wid) {
      _UpdateContextAndTokens(true);
      _UpdateLocals(true,true);
   }

   // do we need to find all symbols and then filter
   // out the non-matches
   substring_word = idexp_info.lastid;
   if (substring_match) {
      idexp_info.lastid = "";
      exact_match = false;
   }

   // context tags to use for searching for matches in context
   context_flags := (SE_TAG_CONTEXT_ALLOW_LOCALS    |
                     SE_TAG_CONTEXT_ALLOW_PRIVATE   |
                     SE_TAG_CONTEXT_ALLOW_PROTECTED |
                     SE_TAG_CONTEXT_ALLOW_PACKAGE   |
                     SE_TAG_CONTEXT_FIND_LENIENT);

   // plug in pattern flags if we are using a kind of search pattern
   pattern_flags := SE_TAG_CONTEXT_NULL;
   if ( regex_type == 's' ) {
      pattern_flags = SE_TAG_CONTEXT_MATCH_STSK_SUBWORD;
      if (!substring_match) {
         pattern_flags |= SE_TAG_CONTEXT_MATCH_FIRST_CHAR;
      }
      if (!substring_match) {
         idexp_info.lastid = _first_char(idexp_info.lastid);
      }
   } else if ( regex_type != '' ) {
      exact_match = false;
      if (substring_match) {
         idexp_info.lastid = "";
      } else {
         idexp_info.lastid = _first_char(idexp_info.lastid);
      }
   }

   // call the extension-specific (possibly embedded) find tags function
   status = _Embeddedfind_context_tags(errorArgs,
                                       idexp_info.prefixexp,
                                       idexp_info.lastid,
                                       (int)_QROffset(),
                                       idexp_info.info_flags,
                                       idexp_info.otherinfo,
                                       find_parents:true,
                                       def_tag_max_find_context_tags,
                                       exact_match, case_sensitive,
                                       filter_flags,
                                       context_flags|pattern_flags,
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
static int findSymbols(_str word, _str &substring_word, bool exact_match=false)
{
   // get the information about the current buffer
   lang := "";
   buffer_name := "";
   editorctl_wid := 0;
   if (!_no_child_windows()) {
      editorctl_wid = _mdi.p_child;
      lang = editorctl_wid.p_LangId;
      buffer_name = editorctl_wid.p_buf_name;
   }

   // get the search options
   case_sensitive := ctl_case_sensitive.p_value >= 1;
   substring      := ctl_substring.p_value >= 1;
   qualify_class  := ctl_qualified_name.p_value >= 1;
   use_context    := ctl_lookin.p_text == VS_TAG_FIND_TYPE_CONTEXT;
   all_buffers    := ctl_lookin.p_text == VS_TAG_FIND_TYPE_ALL_BUFFERS;
   use_buffer     := use_context || all_buffers || ctl_lookin.p_text == VS_TAG_FIND_TYPE_BUFFER_ONLY;
   use_regex      := ctl_use_regex.p_value;
   filter_flags   := def_find_symbol_flags;
   tag_files      := getTagFilesToLookin(lang, buffer_name, use_buffer);

   // get regex options, defeat them if no regex chars
   regex_type := getRegexSearchOption();
   if (regex_type != 's' && _escape_re_chars(word, regex_type) :== word) {
      regex_type = "";
      use_regex = 0;
   }
   if (!use_regex) {
      regex_type = "";
   }

   // save the original buffer for searching all buffers
   orig_buf_id := 0;
   if (editorctl_wid) {
      orig_buf_id = editorctl_wid.p_buf_id;
   }

   // force use of context tagging if the expression is not a simple identifier
   // and we are not doing a regular expression search
   if (!use_context && editorctl_wid != 0) {
      use_context = (pos(word, editorctl_wid._clex_identifier_notre(), 1, 'r') > 0);
   }

   // potentially loop through all open buffers
   status := 0;
   for (;;) {

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      // skip hidden buffers
      if (editorctl_wid && all_buffers && (editorctl_wid.p_buf_flags & VSBUFFLAG_HIDDEN)) {
         editorctl_wid._next_buffer('HR');
         if (editorctl_wid.p_buf_id == orig_buf_id) {
            break;
         }
      }

      // skip special files
      if (editorctl_wid && all_buffers && IsSpecialFile(editorctl_wid._GetDocumentName())) {
         editorctl_wid._next_buffer('HR');
         if (editorctl_wid.p_buf_id == orig_buf_id) {
            break;
         }
      }

      // update the current context and locals
      if (editorctl_wid) {
         editorctl_wid._UpdateContextAndTokens(true);
         editorctl_wid._UpdateLocals(true,true);
      }

      // first attempt to find symbols, using preferred options
      struct VS_TAG_RETURN_TYPE visited:[];
      status = STRING_NOT_FOUND_RC;

      if (use_context) {
         if (editorctl_wid!=0) {
      
            // use Context Tagging(R)
            tag_clear_matches();
            status = findSymbolsInContext(word, editorctl_wid, lang, exact_match, case_sensitive, regex_type, def_find_symbol_flags, substring, substring_word, visited);
            if (status == COMMAND_CANCELLED_RC) break;
         
            // didn't find anything? then try case-insensitive match
            if (status < 0 && ctl_case_sensitive.p_value == 2) {
               status = findSymbolsInContext(word, editorctl_wid, lang, exact_match, false, regex_type, def_find_symbol_flags, substring, substring_word, visited);
               if (status == COMMAND_CANCELLED_RC) break;
            }
      
            // still didn't find anything, try defeating the substring match
            if (substring && word==substring_word) {
               tag_push_matches();
               status = findSymbolsInContext(word, editorctl_wid, lang, exact_match, case_sensitive, regex_type, def_find_symbol_flags, false, substring_word, visited);
               tag_join_matches();
               if (status == COMMAND_CANCELLED_RC) break;
            }
         } else if (lang!="") {
            // use Context Tagging(R)
            status = findSymbolsInContext(word, 0, lang, exact_match, case_sensitive, regex_type, def_find_symbol_flags, substring, substring_word, visited);
            if (status == COMMAND_CANCELLED_RC) break;
      
            // didn't find anything? then try case-insensitive match
            if (status < 0 && ctl_case_sensitive.p_value == 2) {
               status = findSymbolsInContext(word, 0, lang, exact_match, false, regex_type, def_find_symbol_flags, substring, substring_word, visited);
               if (status == COMMAND_CANCELLED_RC) break;
            }
         }

         // check if we have any matches from context
         have_non_match := false;
         tag_name := "";
         class_name := "";
         VS_TAG_BROWSE_INFO good_matches[];
         for (j:=tag_get_num_of_matches(); j > 0; j--) {
            tag_get_detail2(VS_TAGDETAIL_match_name,  j, tag_name);
            tag_get_detail2(VS_TAGDETAIL_match_class, j, class_name);
            if (tagSymbolMatchesPattern(substring_word, substring_word, 
                                        class_name, tag_name,
                                        exact_match, case_sensitive, 
                                        regex_type, '', 
                                        substring, qualify_class)) {
               tag_get_match_browse_info(j, auto jcm);
               findSymbolInsertTag(VS_TAGMATCH_match, j);
               good_matches :+= jcm;
            } else {
               have_non_match = true;
            }
         }
         if (false && have_non_match) {
            tag_clear_matches();
            foreach (auto jcm in good_matches) {
               tag_insert_match_browse_info(jcm);
            }
         }
      }

      // search for symbol in current buffer and tag files
      if (!use_context || qualify_class || tag_get_num_of_matches() <= 0) {
         tag_push_matches();
         status = findSymbolsInTagFiles(word, substring_word, tag_files, use_buffer, substring, exact_match, case_sensitive, qualify_class, regex_type, filter_flags);
         tag_join_matches();
         if (status == COMMAND_CANCELLED_RC) break;

         // still haven't found anything, defeat case-sensitive and prefix match
         if (status < 0) {
            try_again := false;
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
               status = findSymbolsInTagFiles(word, substring_word, tag_files, use_buffer, substring, exact_match, case_sensitive, qualify_class, regex_type, filter_flags);
               tag_join_matches();
               if (status == COMMAND_CANCELLED_RC) break;
            }
         }
      }

      // was the search cancelled?
      if (status == COMMAND_CANCELLED_RC) {
         break;
      }

      // search other open buffers
      if (!all_buffers || !editorctl_wid) {
         break;
      }

      // next buffer please
      editorctl_wid._next_buffer('hr');
      if (editorctl_wid.p_buf_id == orig_buf_id) {
         break;
      }

      // update current language
      lang = editorctl_wid.p_LangId;
   }

   // was the search cancelled?
   if (status == COMMAND_CANCELLED_RC) {
      return COMMAND_CANCELLED_RC;
   }

   return 0;
}

/**
 * Update the search results on the Find Symbol form.
 */
static void updateSearchResults()
{
   // not supposed to update right now
   if (gIgnoreSearchChange) {
      return;
   }

   // get the search text, strip spaces and do not allow empty string
   // if the search string ends with a space, force a word match
   word := ctl_search_for.p_text;
   forceWordMatch := (_last_char(word) :== " ");
   word = strip(word);
   if (word == "") {
      clearSymbolList();
      ctl_progress.p_visible=false;
      // disable the buttons (no results)
      ctl_goto_symbol.p_enabled     = false;
      ctl_find_references.p_enabled = false;
      ctl_show_in_classes.p_enabled = false;
      return;
   }

   // enable the stop button
   ctl_search_stop.p_user = false;
   ctl_search_stop.p_enabled = true;
   origIgnoreSelectChange := gIgnoreSelectChange;
   gIgnoreSelectChange = true;

   // notify the user nicely
   message("Hit any key or press the 'Stop' button next to 'Search for:' to stop Find Symbol search.");
   ctl_progress.p_visible=true;
   ctl_progress.p_value=0;
   ctl_progress.refresh('w');
   tag_push_matches();
   tag_clear_matches();

   // get the caption for the current item selected
   // then wipe the tree except for that item
   current_item := "";
   current_info := null;
   current_pic  := 0;
   current_over := 0;
   current_index := ctl_symbols._TreeCurIndex();
   if (current_index > 0) {
      current_item = ctl_symbols._TreeGetCaption(current_index);
      current_info = ctl_symbols._TreeGetUserInfo(current_index);
      ctl_symbols._TreeGetInfo(current_index, auto ShowChildren, current_pic, current_over);
   }
   ctl_symbols._TreeDelete(TREE_ROOT_INDEX, 'C');
   if (current_index > 0) {
      ctl_symbols._TreeAddItem(TREE_ROOT_INDEX, 
                               current_item, 
                               TREE_ADD_AS_CHILD, 
                               current_pic, current_over, 
                               TREE_NODE_LEAF, 0,
                               current_info);
   }

   // keep track of when we started
   typeless start_time = _time('b');

   // find symbols matching the search string
   substring_word := word;
   status := findSymbols(word, substring_word, forceWordMatch);

   // update the list of symbols
   num_matches := updateSymbolList();

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
   gIgnoreSelectChange = origIgnoreSelectChange;
   ctl_progress.p_visible = false;
   ctl_search_stop.p_enabled = false;
   ctl_search_stop.p_user = false;
   if (status == COMMAND_CANCELLED_RC) {
      message("Find Symbol search cancelled.");
   } else {
      clear_message();
   }
}

/**
 * Update the search results on the Find Symbol form NOW.
 */
static void updateSearchResultsNoDelay()
{
   wid := _tbGetActiveFindSymbolForm();
   if (wid != 0) {
      killFindSymbolUpdateTimer();
      wid.updateSearchResults();
   }
}

/**
 * Update the search results on the Find Symbol form after
 * a slight delay (to allow for another keypress or event)
 */
static void updateSearchResultsDelayed()
{
   if (gIgnoreSearchChange) {
      return;
   }

   // force stop any existing search
   ctl_search_stop.p_user = true;

   // make the progress meter visible
   if (ctl_search_for.p_text != "") {
      ctl_progress.p_visible = true;
      ctl_progress.p_value = 0;
      ctl_progress.refresh('w');
   }

   // start the timer function
   startFindSymbolUpdateTimer(updateSearchResultsNoDelay);
}

//////////////////////////////////////////////////////////////////////////////
// COMMAND BUTTONS
//

/**
 * jump to the location of the item currently selected in the tree
 */
void ctl_goto_symbol.lbutton_up()
{
   status := getSelectedSymbol(auto cm);
   if (!status) {

      mark := -1;
      orig_buf_id := 0;
      editorctl_wid := 0;
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
   status := getSelectedSymbol(auto cm);
   if (!status) {
      activate_references();
      refresh_references_tab(cm);
   }
}
_command void tag_find_symbol_show_references() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   wid := _tbGetActiveFindSymbolForm();
   if (wid != 0) {
      status := wid.getSelectedSymbol(auto cm);
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
   status := getSelectedSymbol(auto cm);
   if (!status) {
      tag_show_in_class_browser(cm);
   }
}
_command void tag_find_symbol_show_in_class_browser() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   wid := _tbGetActiveFindSymbolForm();
   if (wid != 0) {
      status := wid.getSelectedSymbol(auto cm);
      if (!status) {
         tag_show_in_class_browser(cm);
      }
   }
}

/**
 * Activate the Find Symbol tool window and initialize it with the 
 * expression under the cursor. 
 *  
 * @param exp   [optional] expression to seed Find Symbol tool window with
 *  
 * @see push_tag 
 * @see grep_tag 
 * @see gui_push_tag 
 * @see activate_find_symbol
 * 
 * @categories Tagging_Functions
 */
_command void activate_find_symbol_with_curexp(_str exp="")  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Find Symbol");
      return;
   }

   editorctl_wid := 0;
   if (_isEditorCtl()) {
      editorctl_wid = p_window_id;
   } else if (!_no_child_windows()) {
      editorctl_wid = _mdi.p_child;
   }
   if (exp != "") {
      gFindSymbolExpression = exp;
   } else if (editorctl_wid != 0) {
      // get the expression to evaluate
      VS_TAG_IDEXP_INFO idexp_info;
      tag_idexp_info_init(idexp_info);
      struct VS_TAG_RETURN_TYPE visited:[];
      status := editorctl_wid._Embeddedget_expression_info(false, auto lang, idexp_info, visited);
      if (status == 0) {
         gFindSymbolExpression = idexp_info.prefixexp:+idexp_info.lastid;
      }
   }

   activate_find_symbol();
   updateSearchResultsNoDelay();
}

/**
 * Activate the Find Symbol tool window and initialize it with the 
 * identifier under the cursor. 
 *  
 * @param id   [optional] identifier to seed Find Symbol tool window with
 *  
 * @see push_tag 
 * @see grep_tag 
 * @see gui_push_tag 
 * @see activate_find_symbol
 * 
 * @categories Tagging_Functions
 */
_command void activate_find_symbol_with_identifier(_str id="")  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Find Symbol");
      return;
   }

   editorctl_wid := 0;
   if (_isEditorCtl()) {
      editorctl_wid = p_window_id;
   } else if (!_no_child_windows()) {
      editorctl_wid = _mdi.p_child;
   }
   gFindSymbolExpression = (id != "")? id : editorctl_wid.cur_identifier(auto start_col);

   activate_find_symbol();
   updateSearchResultsNoDelay();
}


///////////////////////////////////////////////////////////////////////////////
// For saving and restoring the state of the find symbol tool window
// when the user undocks, pins, unpins, or redocks the window.
//
void _twSaveState__tbfind_symbol_form(typeless& state, bool closing)
{
   //if( closing ) {
   //   return;
   //}
   ctl_symbols._TreeSaveNodes(state);
   ctl_symbols._TreeAppendColButtonInfo();
}
void _twRestoreState__tbfind_symbol_form(typeless& state, bool opening)
{
   //if( opening ) {
   //   return;
   //}
   if (state == null) return;
   ctl_symbols._TreeRestoreNodes(state);
   ctl_symbols._TreeRetrieveColButtonInfo();

   enabled := (ctl_symbols._TreeGetNumChildren(TREE_ROOT_INDEX) > 0);
   ctl_goto_symbol.p_enabled     = enabled;
   ctl_find_references.p_enabled = enabled;
   ctl_show_in_classes.p_enabled = enabled;
}

void tbfindsymbol_copy_to_search_results(int grep_id = 0)
{
   se.search.SearchResults results;
   search_text := strip(ctl_search_for.p_text);
   line := 'Find Symbol "':+search_text:+'"';
   results.initialize(line, "<Find Symbol>", 0, grep_id);
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   num_found := 0;

   _str taginfo:[][];
   _str filenames[];
   while (index > 0) {
      struct VS_TAG_BROWSE_INFO cm = _TreeGetUserInfo(index);
      if (!taginfo._indexin(cm.file_name)) {
         filenames[filenames._length()] = cm.file_name;
      } 
      caption := _TreeGetCaption(index);
      parse caption with auto symbol_name "\t" .;

      lineinfo := cm.line_no:+" : ":+symbol_name;
      len := taginfo:[cm.file_name]._length();
      idx := len;
      // quick and dirty sort on insert 
      for (i := 0; i < len; ++i) {
         parse taginfo:[cm.file_name][i] with auto line_no " : " .;
         if (cm.line_no < (int)line_no) {
            idx = i;
            break;
         }
      }
      taginfo:[cm.file_name]._insertel(lineinfo, idx);
      index = _TreeGetNextSiblingIndex(index);
      num_found++;
   }
   filenames._sort("F");

   foreach (auto f in filenames) {
      results.insertFileLine(f, false);
      foreach (auto lineinfo in taginfo:[f]) {
         parse lineinfo with auto linenum " : " auto symbol_name;
         results.insertResult((int)linenum, 1, " ":+symbol_name);
      }
   }

   num_files := filenames._length();
   text := "Total found: ":+num_found:+"     Total files: ":+num_files;
   results.done(text);
   results.showResults();
   _mfrefIsActive=false;
}

void tbfindsymbol_copy_to_refs_results(int grep_id = 0)
{
   regex_opts  := getRegexSearchOption();
   case_opts   := (ctl_case_sensitive.p_value >= 1)? 'e':'i';
   search_text := strip(ctl_search_for.p_text);
   look_in     := strip(ctl_lookin.p_text);
   struct VS_TAG_BROWSE_INFO tagInfoList[];

   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      cm := _TreeGetUserInfo(index);
      if (cm != null && cm instanceof VS_TAG_BROWSE_INFO) {
         tagInfoList :+= cm;
      }
      index = _TreeGetNextSiblingIndex(index);
   }

   refs_push_list_of_symbols(search_text, case_opts:+regex_opts, look_in, tagInfoList);
}

