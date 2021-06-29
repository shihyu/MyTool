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
#include "markers.sh"
#include "color.sh"
#include "minihtml.sh"
#include "autocomplete.sh"
#import "sc/lang/ScopedTimeoutGuard.e"
#import "se/tags/TaggingGuard.e"
#import "se/lang/api/LanguageSettings.e"
#import "alias.e"
#import "autobracket.e"
#import "beautifier.e"
#import "c.e"
#import "cbrowser.e"
#import "ccode.e"
#import "cfg.e"
#import "codehelp.e"
#import "compword.e"
#import "context.e"
#import "dlgman.e"
#import "guireplace.e"
#import "html.e"
#import "ini.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "notifications.e"
#import "pushtag.e"
#import "recmacro.e"
#import "saveload.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tagform.e"
#import "tags.e"
#import "treeview.e"
#import "vc.e"
#import "vi.e"
#endregion

using se.lang.api.LanguageSettings;


///////////////////////////////////////////////////////////////////////////////
// AUTO COMPLETION (autocomplete.e)
//
// Author:  Dennis Brueni
// History:
//    07-14-2005:  initial version
//
///////////////////////////////////////////////////////////////////////////////
// This module implements the automatical completion system for SlickEdit.
//
// Automatic completion provides a comprehensive system to tie together
// many of the most important features of SlickEdit into one consistent
// framework.  Auto-completion works by dynamically suggesting completion
// possibilities when they are discovered, and providing a one key solution
// for selecting to perform the auto-completion, when is then executed as
// if the specific command had actually been typed.
//
// This frees the user from having to remember the key combination
// associated with various completion mechanisms, all they really need
// to remember is Space key.  And if they are an advanced user, they also
// can use Ctrl+Shift+Space to incrementally pull in part of the word.
//
// The features pulled into this system include:
//
//    1) Language specific syntax expansion
//    2) Keyword completion
//    3) Alias expansion
//    4) Symbol completion using tagging
//    5) Complete prev/next matches
//
// For the text box and combo box controls, this same system supplements
// the existing completion mechanisms by providing a dynamic system for
// displaying the matches, much like that used by the Windows file chooser.
//
// For the SlickEdit command line, this system supplements command history
// as well as command argument completion using the same display mechanism.
//
///////////////////////////////////////////////////////////////////////////////


// Tree control on _auto_complete_list_form
// This is used in a few places outside of the
// tree's event table
_control ctltree;


///////////////////////////////////////////////////////////////////////////////
/**
 * Return the configuration variable <i>def_auto_complete_options</i>.
 * 
 * @return int 
 * @see    def_auto_complete_options
 */
AutoCompleteFlags GetDefAutoCompleteOptions() {
   return def_auto_complete_options;
}

/**
 * Minimum expandable symbol length to trigger auto completion.
 * <p>
 * The actual configurable options are stored per extension in
 * def_autocompletemin_[ext].  This is used as a global default setting.
 *
 * @default 1
 * @categories Configuration_Variables
 */
int def_auto_complete_minimum_length = 1;

/**
 * Delay before auto completion is displayed (in milliseconds).
 * <p>
 * Not used when auto completion is active.
 *
 * @default 250 milliseconds
 * @categories Configuration_Variables
 */
int def_auto_complete_idle_time = 250;

/**
 * Delay before auto completion list is updated (in milliseconds).
 * <p>
 * When auto completion is active, this is the delay before it is updated
 * when you are typing identifier characters.  Not used when auto completion
 * list is not displayed.
 *
 * @default 50 milliseconds
 * @categories Configuration_Variables
 */
int def_auto_complete_update_idle_time = 50;

/**
 * Auto-complete should stop searching for completions after this 
 * amount of time.  This is done to prevent large typing delays. 
 *
 * @default 500 milliseconds (1/2 second)
 * @categories Configuration_Variables
 */
int def_auto_complete_timeout_time = 500;

/**
 * Auto-complete should stop searching for completions after this 
 * amount of time.  This is done to prevent large delays. 
 * This setting is used when auto-complete is forced by invoking 
 * list-members (but not auto-list members). 
 *
 * @default 15000 milliseconds (15 seconds)
 * @categories Configuration_Variables
 */
int def_auto_complete_timeout_forced = 15000;

/**
 * Maximum number of items to find for auto symbol completion
 *
 * @default 100
 * @categories Configuration_Variables
 */
int def_auto_complete_max_symbols = 100;

/**
 * Maximum number of items to find for auto word completion
 *
 * @default 100
 * @categories Configuration_Variables
 */
int def_auto_complete_max_words = 100;

/**
 * Maximum number of symbols to display function prototypes for
 *
 * @default 20
 * @categories Configuration_Variables
 */
int def_auto_complete_max_prototypes = 20;


///////////////////////////////////////////////////////////////////////////////

/**
 * This struct is used to control the auto completion gui and results.
 */
struct AUTO_COMPLETE_RESULTS {

   // window id of editor control, text box, or combo box
   int editor;
   // buffer identifier of last completion (editor.p_buf_id)
   int buffer;
   // line offset of last completion
   typeless lineoffset;
   // column number of last completion (editor.p_col)
   int column;
   // p_col for start of prefix
   int start_col;
   // p_col for the end of the word (including all chars to replace)
   int end_col;
   // last modify type for buffer
   long lastModified;

   // Context Tagging symbol information
   VS_TAG_IDEXP_INFO idexp_info;
   // word prefix
   _str prefix;
   // Is this the auto-list members case where they typed an operator
   bool operatorTyped;
   // Is this the auto-list compatible parameters case where they typed a paren or comma?
   bool wasListParameters;
   // Is this iteration forcing showing categories
   bool doShowCategories;

   // Expected type for listing compatible values for arguments
   _str expected_type;
   // Expected return type for listing compatible values for arguments
   VS_TAG_RETURN_TYPE expected_rt;
   // Expected name for argument being listed
   _str expected_name;
   // information about symbols we already looked up
   VS_TAG_RETURN_TYPE visited:[];

   // start column to begin removing old identifier at
   int removeStartCol;
   // number of characters to remove
   int removeLen;

   // allow insertion of longest unique prefix
   bool allowInsertLongest;
   // allow showing info and comments for this item?
   bool allowShowInfo;
   // only allow explicit replace action
   bool allowImplicitReplace;
   // was auto-complete forced or invoked on timer
   bool wasForced;
   // was auto-complete forced or invoked on timer
   bool wasListSymbols;
   // was this the first attempt to list symbols?
   bool wasFirstSubwordMatchingAttempt;
   // is auto-complete active?
   bool isActive;
   // may need to restart auto-complete
   bool maybeRestartListParametersAfterKey;

   // original content of line
   _str origLineContent;
   // original start column
   int origCol;
   // original word prefix
   _str origPrefix;

   // position to move to when replacing word
   typeless replaceWordPos;
   // modify date of buffer, to verify before replacing word
   int replaceWordLastModified;

   // completed words and thier comment information
   AUTO_COMPLETE_INFO words[];
   // index of current words selected
   int wordIndex;
   // was there an exact match found?
   bool foundExactMatch;

   // picture type created by _MarkerTypeAlloc
   int markerType;
   // picture index created by _StreamMarkerAdd
   int streamMarkerIndex;
   // window id of comment form (for single matches)
   int commentForm;
   // window id of list form (for multiple matches)
   int listForm;
   // timer id for displaying auto completion items and comments
   int timerId;

   // ignore any switch-buffer events that may be triggered while
   // auto-complete is updating it's list of results
   bool ignoreSwitchBufAndModuleLoadEvents;
};

///////////////////////////////////////////////////////////////////////////////

// auto completion results
static AUTO_COMPLETE_RESULTS gAutoCompleteResults;

///////////////////////////////////////////////////////////////////////////////
// maps a priority number to a category name.  This way we do not have
// to store the category name for every single auto-complete result.
//
static _str gAutoCompleteCategoryNames:[];

///////////////////////////////////////////////////////////////////////////////
// picture of light bulb shown in gutter of editor control
int _pic_light_bulb=0;
int _pic_keyword=0;
int _pic_syntax=0;
int _pic_alias=0;
int _pic_surround_alias=0;
int _pic_complete_next=0;
int _pic_complete_prev=0;


///////////////////////////////////////////////////////////////////////////////
defeventtab auto_complete_key_overrides;
def ESC=AutoCompleteDoKey;         // cancel auto complete
def C_C=AutoCompleteDoKey;         // copy comments
def C_A=AutoCompleteDoKey;         // select all comments
def C_U=AutoCompleteDoKey;         // deselect all comments
def C_G=AutoCompleteDoKey;         // maybe cancel
def ENTER=AutoCompleteDoKey;       // auto complete on ENTER
def TAB=AutoCompleteDoKey;         // next auto completion choice
def S_TAB=AutoCompleteDoKey;       // prev auto completion choice
def BACKSPACE=AutoCompleteDoKey;   // backspace
def DEL=AutoCompleteDoKey;         // delete
def UP=AutoCompleteDoKey;          // next auto completion
def DOWN=AutoCompleteDoKey;        // prev auto completion
def LEFT=AutoCompleteDoKey;        // move cursor to the left
def RIGHT=AutoCompleteDoKey;       // move corsor to the right
def PGDN=AutoCompleteDoKey;        // page down auto completions
def PGUP=AutoCompleteDoKey;        // page up auto completions
def C_I=AutoCompleteDoKey;         // next auto completion
def C_K=AutoCompleteDoKey;         // prev auto completion
def C_PGDN=AutoCompleteDoKey;      // next auto completion comment
def C_PGUP=AutoCompleteDoKey;      // prev auto completion comment
def S_PGDN=AutoCompleteDoKey;      // page down comments
def S_PGUP=AutoCompleteDoKey;      // page up comments
def S_HOME=AutoCompleteDoKey;      // top of comments
def S_END=AutoCompleteDoKey;       // bottom of comments
def S_DOWN=AutoCompleteDoKey;      // move auto-complete list above line
def S_UP=AutoCompleteDoKey;        // move auto-complete list below line
def S_LEFT=AutoCompleteDoKey;      // move auto-complete comments to left
def S_RIGHT=AutoCompleteDoKey;     // move auto-complete comment to right
def "C- "=AutoCompleteDoKey;       // insert longest unique prefix completion
def "C-S- "=AutoCompleteDoKey;     // complete one character
def " "-\127=AutoCompleteDoKey;    // update auto complete
def "A-."=AutoCompleteDoKey;       // cycle through categories
def "M-."=AutoCompleteDoKey;       // cycle through categories
def "A-M-."=AutoCompleteDoKey;     // cycle through categories
def "A-,"=AutoCompleteDoKey;       // force list-compatible symbols
def "M-,"=AutoCompleteDoKey;       // force list-compatible symbols
def "A-M-,"=AutoCompleteDoKey;     // force list-compatible symbols

///////////////////////////////////////////////////////////////////////////////
// initialization code ran when editor is started
//
definit()
{
   gAutoCompleteResults.origLineContent=null;
   gAutoCompleteResults.removeLen=0;
   gAutoCompleteResults.allowInsertLongest=true;
   gAutoCompleteResults.allowShowInfo=false;
   gAutoCompleteResults.allowImplicitReplace=false;
   gAutoCompleteResults.wasForced=false;
   gAutoCompleteResults.wasListSymbols=false;
   gAutoCompleteResults.wasListParameters=false;
   gAutoCompleteResults.wasFirstSubwordMatchingAttempt=true;
   gAutoCompleteResults.doShowCategories=false;
   gAutoCompleteResults.operatorTyped=false;
   // initialize results struct
   gAutoCompleteResults.editor=0;
   gAutoCompleteResults.buffer=0;
   gAutoCompleteResults.lineoffset=0;
   gAutoCompleteResults.column=0;
   gAutoCompleteResults.start_col= -1;
   gAutoCompleteResults.end_col=-1;
   gAutoCompleteResults.lastModified=0;
   gAutoCompleteResults.words._makeempty();
   gAutoCompleteResults.wordIndex=-1;
   gAutoCompleteResults.foundExactMatch=false;
   gAutoCompleteResults.isActive=false;
   gAutoCompleteResults.maybeRestartListParametersAfterKey = false;
   gAutoCompleteResults.markerType=-1;
   gAutoCompleteResults.streamMarkerIndex=-1;
   gAutoCompleteResults.commentForm=0;
   gAutoCompleteResults.listForm=0;
   gAutoCompleteResults.timerId=-1;
   gAutoCompleteResults.ignoreSwitchBufAndModuleLoadEvents=false;
   gAutoCompleteResults.replaceWordPos="";
   gAutoCompleteResults.expected_type="";
   gAutoCompleteResults.expected_name="";
   gAutoCompleteResults.visited._makeempty();
   tag_idexp_info_init(gAutoCompleteResults.idexp_info);
   tag_return_type_init(gAutoCompleteResults.expected_rt);

   processAutoCompleteOptions := LanguageSettings.getAutoCompleteOptions("process");
   processAutoCompleteOptions &= ~(AUTO_COMPLETE_UNIQUE|AUTO_COMPLETE_WORDS|AUTO_COMPLETE_KEYWORDS|AUTO_COMPLETE_NO_INSERT_SELECTED);
   value:=LanguageSettings.getAutoCompleteOptions("process", processAutoCompleteOptions|AUTO_COMPLETE_ENABLE);
   if (value!=processAutoCompleteOptions) {
      LanguageSettings.setAutoCompleteOptions("process", processAutoCompleteOptions);
   }
   

   gAutoCompleteCategoryNames._makeempty();
   gAutoCompleteCategoryNames:[(int)AUTO_COMPLETE_KEYWORD_PRIORITY        ] = "Keywords";
   gAutoCompleteCategoryNames:[(int)AUTO_COMPLETE_SYNTAX_PRIORITY         ] = "Syntax Expansion";
   gAutoCompleteCategoryNames:[(int)AUTO_COMPLETE_ALIAS_PRIORITY          ] = "Aliases";
   gAutoCompleteCategoryNames:[(int)AUTO_COMPLETE_COMPATIBLE_PRIORITY     ] = "Compatible";
   gAutoCompleteCategoryNames:[(int)AUTO_COMPLETE_LOCALS_PRIORITY         ] = "Locals";
   gAutoCompleteCategoryNames:[(int)AUTO_COMPLETE_MEMBERS_PRIORITY        ] = "Members";
   gAutoCompleteCategoryNames:[(int)AUTO_COMPLETE_CURRENT_FILE_PRIORITY   ] = "Current file";
   gAutoCompleteCategoryNames:[(int)AUTO_COMPLETE_SYMBOL_PRIORITY         ] = "Symbols";
   gAutoCompleteCategoryNames:[(int)AUTO_COMPLETE_SUBWORD_PRIORITY        ] = "Subwords";
   gAutoCompleteCategoryNames:[(int)AUTO_COMPLETE_WORD_COMPLETION_PRIORITY] = "Words";
   gAutoCompleteCategoryNames:[(int)AUTO_COMPLETE_FILES_PRIORITY          ] = "Files";
   gAutoCompleteCategoryNames:[(int)AUTO_COMPLETE_ARGUMENT_PRIORITY       ] = "Arguments";
}

bool isAutoCompletePoundIncludeSupported(_str langId)
{
   return (pos(" "langId" ", AUTOCOMPLETE_POUND_INCLUDE_LANGS) != 0);
}

static const AUTOCOMPLETE_POUND_INCLUDE_LANGS=        " c e ansic m ch as java cfscript phpscript idl cs applescript ";
void _UpgradeAutoCompleteSettings(_str config_migrated_from_version)
{
   // if we did not upgrade from anything, don't worry about it
   if (config_migrated_from_version == "") return;

   // get the major/minor version
   parse config_migrated_from_version with auto major "." auto minor "." auto revision "." .;

   // we changed up this option in v16
   if (major < 16) {

      // this is the value we are going to set everything to
      value := def_c_expand_include;

      _str poundIncludeLangs[];
      split(strip(AUTOCOMPLETE_POUND_INCLUDE_LANGS, "B", " "), " ", poundIncludeLangs);
      for (i := 0; i < poundIncludeLangs._length(); i++) {
         langId := poundIncludeLangs[i];

         if (langId == "e") {
            // this was on by default for slick-c, let's leave it that way
            LanguageSettings.setAutoCompletePoundIncludeOption(langId, AC_POUND_INCLUDE_QUOTED_ON_SPACE);
         } else {
            LanguageSettings.setAutoCompletePoundIncludeOption(langId, value);
         }
      }
   }

   // increase the delay before showing symbols in the preview window after mouse-hover over
   if (major == 16 || major == 17) {
      if (def_tag_hover_delay == 50) {
         def_tag_hover_delay = 500;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
   }
}

/**
 * Auto-complete replace word callback for syntax expansions. 
 *  
 * Note that syntax expansion keys off of all the text from the start of 
 * the current line, so the removeStartCol needs to be adjusted to reflect 
 * the first non-blank column of the line. 
 * 
 * @param insertWord       (input) selected word
 * @param prefix           (input) word prefix under cursor
 * @param removeStartCol   (output) set to column where completion was done
 * @param removeLen        (output) set to length of completion
 * @param onlyInsertWord   (input) only insert new word, do not expand syntax
 * @param symbol           (input) symbol information (always null)
 */
void _autocomplete_space(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol)
{
   // do not modify read-only files
   if (_QReadOnly()) {
      _readonly_error(0);
      return;
   }

   // move to beginning of word to replace
   p_col -= length(prefix);

   // now move to the beginning of the line, because syntax expansion
   // works from the first non-blank column.
   orig_col := p_col;
   _first_non_blank();
   removeStartCol = p_col;

   // calculate the number of characters of text to replace
   removeLen = length(prefix);
   if (p_col < orig_col && lowcase(get_text(orig_col-p_col)) == lowcase(substr(insertWord,1,orig_col-p_col))) {
      removeLen += (orig_col - p_col);
   }

   // now replace the word
   _delete_text(removeLen);
   _insert_text(insertWord);

   // and then invoke syntax expansion on space
   if (!onlyInsertWord && last_event() != " " && last_event() != ";") {
      autocomplete_space();
   }
}
///////////////////////////////////////////////////////////////////////////////
/**
 * SPACE BAR in auto complete mode
 * <p>
 * New binding of SPACE key when in auto complete mode.
 * Executes the underlying binding for the space key.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void autocomplete_space() name_info(","VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   AutoCompleteDefaultKey(" ", doTerminate:true, called_from_AutoCompleteDoKey:false);
}

///////////////////////////////////////////////////////////////////////////////

/**
 * Get the auto complete picture type.
 * <p>
 * If <code>def_auto_complete_options</CODE> has the AUTO_COMPLETE_SHOW_BAR
 * option set, then set flags to draw the original word with the expansion bar.
 *
 * @param resetFlags    Force the picture flags to be updated.
 *                      Use this when def_auto_complete_options changes.
 *
 * @return Integer handle for the pic type.
 *
 * @see _MarkerTypeAlloc
 * @see _MarkerTypeSetFlags
 */
static int AutoCompleteGetPicType(bool resetFlags=false)
{
   if (gAutoCompleteResults.markerType <= 0) {
      gAutoCompleteResults.markerType = _MarkerTypeAlloc();
      if (gAutoCompleteResults.markerType < 0) {
         return gAutoCompleteResults.markerType;
      }
      resetFlags=true;
   }
   if (resetFlags) {
      //auto_complete_options := AutoCompleteGetOptions();
      //int pic_flags = VSMARKERTYPEFLAG_DRAW_NONE;
      //if (auto_complete_options & AUTO_COMPLETE_SHOW_BAR) {
      //   pic_flags = VSMARKERTYPEFLAG_DRAW_EXPANSION;
      //}
      //_MarkerTypeSetFlags(gAutoCompleteResults.markerType, pic_flags);
   }

   return gAutoCompleteResults.markerType;
}

/**
 * Get the auto complete picture that is displayed in the gutter
 * when a completion becomes available.
 */
static int AutoCompleteGetPicture()
{
   auto_complete_options := AutoCompleteGetOptions();
   if (!(auto_complete_options & AUTO_COMPLETE_SHOW_BULB)) {
      if (p_KeepPictureGutter) p_KeepPictureGutter = false;
      return 0;
   }
   if (_pic_light_bulb <= 0) {
      _pic_light_bulb = _find_or_add_picture("_ed_lightbulb.svg");
   }
   if (!p_KeepPictureGutter) {
      p_KeepPictureGutter = true;
      refresh();
   }
   return _pic_light_bulb;
}

/**
 * Display the list of auto-completion results
 *
 * @return 1 on success
 */
static int AutoCompleteShowList(bool doListMembers)
{
   // terminate mouse-over help if it is active
   TerminateMouseOverHelp();

   // get the screen position of the editor control
   wx := 0;
   wy := 0;
   _map_xy(p_window_id,0,wx,wy,SM_TWIP);
   wy += _dy2ly(SM_TWIP, p_font_height);

   // get the position of the start of the word
   cy := p_cursor_y;
   cx := p_cursor_x;
   px := _text_width(gAutoCompleteResults.prefix);
   px = _lx2dx(p_xyscale_mode, px);
   cx -= px;
   cy += 1;
   _dxy2lxy(SM_TWIP, cx, cy);

   // adjust position of form so we don't overlap function help
   function_help_form_wid := ParameterHelpFormWid();
   if (function_help_form_wid > 0) {
      fx := function_help_form_wid.p_x;
      fw := function_help_form_wid.p_height;
      fy := function_help_form_wid.p_y;
      fh := function_help_form_wid.p_height;
      if ( wy+cy <= fy+fh && wx+cx <= fx+fw ) {
         cy += fh;
      }
   }

   // get text positioning information
   tx := (gAutoCompleteResults.start_col-p_col)*p_font_width+p_cursor_x;
   ty := p_cursor_y;
   th := p_font_height;

   // now show the window
   list_wid := 0;
   orig_wid := p_window_id;
   cx += wx;
   cy += wy;
   if (gAutoCompleteResults.listForm <= 0) {

      list_wid = show("-hidden -nocenter _auto_complete_list_form",
                      gAutoCompleteResults.words,
                      gAutoCompleteResults.wordIndex);
      if (list_wid != 0) {
         list_wid._move_window(cx,cy,list_wid.p_width,list_wid.p_height);
         list_wid._get_window(cx,cy,wx,wy);
         orig_wid.AutoCompletePositionForm(list_wid, function_help_form_wid);
         auto_complete_options := AutoCompleteGetOptions();
         if (doListMembers || (auto_complete_options & AUTO_COMPLETE_SHOW_LIST)) {
            list_wid._ShowWindow(SW_SHOWNOACTIVATE);
         }
         list_wid.ctltree.p_MouseActivate=MA_NOACTIVATE;
         gAutoCompleteResults.listForm = list_wid;
         // color the current node if they have an item selected
         if (gAutoCompleteResults.wordIndex>=0 && gAutoCompleteResults.allowImplicitReplace) {
            list_wid.ctltree.p_AlwaysColorCurrent=true;
         }
      }

      // make sure focus goes back to the editor
      p_window_id = orig_wid;
      _set_focus();

   } else {

      // update the current list of items
      tree_wid := AutoCompleteGetTreeWid();
      if (tree_wid > 0) {
         list_wid = gAutoCompleteResults.listForm;
         if (gAutoCompleteResults.wordIndex < 0 || !gAutoCompleteResults.allowImplicitReplace) {
            gAutoCompleteResults.allowImplicitReplace=false;
            gAutoCompleteResults.allowShowInfo=false;
         }
         tree_wid.AutoCompleteUpdateList(gAutoCompleteResults.words,
                                         gAutoCompleteResults.wordIndex);
         if (tree_wid._TreeGetNumChildren(TREE_ROOT_INDEX) > 0) {
            orig_wid.AutoCompletePositionForm(list_wid, function_help_form_wid);
         } else {
            AutoCompleteTerminate();
         }
      } else {
         gAutoCompleteResults.listForm = 0;
         list_wid = 0;
      }
   }

   // success
   return 0;
}

/**
 * Reposition the auto-complete list form compensating for the available 
 * screen real-estate and the location of the function parameter help form. 
 * The current window should be the editor control. 
 * 
 * @param form_wid                  auto-complete list form
 * @param function_help_form_wid    function help form window ID
 * @param prefer_positioning_above  try to position form above or below line?
 */
static void AutoCompletePositionForm(int auto_complete_list_form_wid,
                                     int function_help_form_wid,
                                     bool prefer_positioning_above=false)
{
   // get the text position information
   //    tx  x cooridinate of pivot identifier
   //    ty  y cooridinate of pivot line
   //    th  line height
   col := gAutoCompleteResults.start_col;
   tx := (col-p_col)*p_font_width+p_cursor_x;
   ty := p_cursor_y;
   th := p_font_height;

   // get the X and Y position
   x := tx;
   y := ty+th;
   _map_xy(p_window_id,0,x,y);

   // adjust the position to compenate for the height of the
   // function help form if it is currently being displayed.
   if (function_help_form_wid && _iswindow_valid(function_help_form_wid)) {
      fy := _ly2dy(SM_TWIP,function_help_form_wid.p_y);
      fx := _ly2dy(SM_TWIP,function_help_form_wid.p_x);
      fw := _ly2dy(SM_TWIP,function_help_form_wid.p_width);
      if ( y<=fy  && x <= fx+fw ) {
         y = fy+_ly2dy(SM_TWIP,function_help_form_wid.p_height);
      }
   }

   // get the total size of the screen (for the current monitor)
   vx := vy := vw := vh := 0;
   _GetVisibleScreenFromPoint(x,y,vx,vy,vw,vh);

   // do not let the form come up off-screen to the left
   if ( x < vx ) {
      x = vx;
   }

   // get the height of the auto-complete list form in pixels
   h := _ly2dy(auto_complete_list_form_wid.p_xyscale_mode,auto_complete_list_form_wid.p_height);

   // check if we can just reduce height of form to fit on screen
   if (y+h > vy+vh && y+th*10 < vy+vh) {
      h = vy+vh-y-1;
   }

   // otherwise check if we should move the list form above the current line
   if ((y+h >= vy+vh && ty >= h) ||
       (prefer_positioning_above && ty-h >= vy) ||
       (y+h >= vy+vh && ty<h && (ty-h > (vy+vh)-(y+h)))) {

      // calculate the new x,y position for the form
      x = tx;
      y = ty-h;
      _map_xy(p_window_id,0,x,y);

      // compensate for the function help form, in case
      // if it is also positioned above the current line.
      if (function_help_form_wid) {
         by := y+_ly2dy(SM_TWIP,auto_complete_list_form_wid.p_height);
         fy := _ly2dy(SM_TWIP,function_help_form_wid.p_y);
         fx := _ly2dy(SM_TWIP,function_help_form_wid.p_x);
         fw := _ly2dy(SM_TWIP,function_help_form_wid.p_width);
         if ( by > fy && x <= fx+fw ) {
            y -= (by-fy);
         }
      }
   }

   // make sure the form is not cut off on the right
   w := _lx2dx(auto_complete_list_form_wid.p_xyscale_mode,auto_complete_list_form_wid.p_width);
   if ( x+w >= vx+vw ) {
      x = vx+vw-w;
   }

   // move the window to the new calculated position
   junk := cw := ch := 0;
   auto_complete_list_form_wid._get_window(junk,junk,cw,ch);
   _dxy2lxy(auto_complete_list_form_wid.p_xyscale_mode,x,y);
   _dxy2lxy(auto_complete_list_form_wid.p_xyscale_mode,w,h);
   auto_complete_list_form_wid._move_window(x,y,w,h);
   if (h != ch) {
      _nocheck _control ctltree;
      auto_complete_list_form_wid.ctltree.AutoCompleteUpdateListHeight(ch,vh,false);
   }
}

/**
 * Display the comments for the currently selected item
 *
 * @return 1 on success
 */
static int AutoCompleteShowComments(bool prefer_left_placement=false)
{
   // make sure the timer is dead
   AutoCompleteKillTimer();

   // Standard edition doesn't swing this way
   if (!_haveContextTagging()) {
      return 0;
   }

   // blow away the previous comment
   comment_wid := AutoCompleteGetCommentsWid();
   if (comment_wid != 0) {
      comment_wid._delete_window();
      gAutoCompleteResults.commentForm = 0;
   }

   // are we suppose to display comments?
   auto_complete_options := AutoCompleteGetOptions();
   if (!(auto_complete_options & AUTO_COMPLETE_SHOW_DECL) &&
       !(auto_complete_options & AUTO_COMPLETE_SHOW_COMMENTS)) {
      return 0;
   }

   // make sure that auto complete is active
   editorctl_wid := AutoCompleteGetEditorWid();
   if (!_iswindow_valid(editorctl_wid)) {
      return 0;
   }

   // save the original window ID, and switch to the editor
   orig_wid := p_window_id;
   p_window_id = editorctl_wid;

   // make sure that the current word index is valid
   int word_index = gAutoCompleteResults.wordIndex;
   if (word_index < 0 || word_index >= gAutoCompleteResults.words._length()) {
      p_window_id = orig_wid;
      return 0;
   }

   // make sure we have the symbol comments up to date
   VS_TAG_BROWSE_INFO cm = gAutoCompleteResults.words[word_index].symbol;
   if (cm != null) {
      if (cm.member_name=="") {
         cm.member_name=gAutoCompleteResults.words[word_index].displayWord;
      }
      cb_refresh_output_tab(cm,true);
   }

   // make sure we have the symbol comments up to date
   AutoCompleteGetSymbolComments();

   // get the auto complete info for this item
   AUTO_COMPLETE_INFO info = gAutoCompleteResults.words[word_index];
   prefix := gAutoCompleteResults.prefix;
   //say("prefix="prefix);

   // if they want comments, but not the word, display the word as comments
   comments := info.comments;
   tree_wid := AutoCompleteGetTreeWid();
   if (!(auto_complete_options & AUTO_COMPLETE_SHOW_WORD) && comments == "" && tree_wid == 0) {
      comments = info.displayWord;
   }

   // and now for the comments (if there are any)
   if (comments != "" || info.symbol != null) {

      // get the screen position of the editor control
      wx := wy := 0;
      _map_xy(p_window_id,0,wx,wy,SM_TWIP);
      wy += _dy2ly(SM_TWIP, p_font_height);

      // get the position of the start of the word
      cy := p_cursor_y;
      cx := p_cursor_x;
      cx -= _text_width(prefix);
      cy += 1;
      _dxy2lxy(SM_TWIP, cx, cy);

      // adjust position of form so we don't overlap function help
      function_help_form_wid := ParameterHelpFormWid();
      if (function_help_form_wid > 0 && _iswindow_valid(function_help_form_wid)) {
         fx := 0;
         fy := function_help_form_wid.p_y;
         fh := function_help_form_wid.p_height;
         if ( wy+cy <= fy+fh ) {
            cy += fh;
         }
      }

      if (tree_wid > 0 && _iswindow_valid(tree_wid) && tree_wid.p_active_form.p_visible) {
         cy= gAutoCompleteResults.listForm.p_y;
         cx= gAutoCompleteResults.listForm.p_x+gAutoCompleteResults.listForm.p_width;
         int char_h = tree_wid.p_line_height;
         int first_visible = tree_wid._TreeScroll();
         int current_line  = tree_wid._TreeCurLineNumber();
         if (current_line > first_visible) {
            int delta_h = _twips_per_pixel_y() * char_h * (current_line - first_visible);
            cy += delta_h;
         }
         
      }  else {
         tree_wid = 0;
         cx += wx;
         cy += wy;
      }

      // now show the window
      comment_wid = show("-hidden -nocenter -new _function_help_form", editorctl_wid, tree_wid);
      if (comment_wid != 0) {
         gAutoCompleteResults.commentForm = comment_wid;
         cw := ch := 0;
         comment_wid._move_window(cx,cy,
                                  gAutoCompleteResults.commentForm.p_width,
                                  gAutoCompleteResults.commentForm.p_height);
         comment_wid._get_window(cx,cy,cw,ch);

         // get the total size of the screen (for the current monitor)
         vx := vy := vw := vh := 0;
         _GetVisibleScreenFromPoint(cx,cy,vx,vy,vw,vh);

         // move the comment over to the left of the list if it doesn't
         // fit on the right hand side of the list.
         tx := (gAutoCompleteResults.start_col-p_col)*p_font_width+p_cursor_x;
         if (cx+cw > _dx2lx(SM_TWIP,vx+vw) && _dx2lx(SM_TWIP,tx)+wx-cw > _dx2lx(SM_TWIP,vx) ) {
            cx = _dx2lx(SM_TWIP,tx)+wx-cw;
            comment_wid._move_window(cx,cy,cw,ch);
         }
         //comment_wid._ShowWindow(SW_SHOWNOACTIVATE);

         _nocheck _control ctlminihtml1;
         VSAUTOCODE_ARG_INFO list[];
         int been_there:[];
         int seen_that:[];

         tag_autocode_arg_info_init(list[0]);
         list[0].prototype = info.displayWord;
         list[0].tagList[0].comments = info.comments;
         list[0].tagList[0].comment_flags = info.comment_flags;
         if (info.symbol != null) {
            list[0].prototype = extension_get_decl(cm.language, cm, VSCODEHELPDCLFLAG_VERBOSE);
            list[0].tagList[0].filename = cm.file_name;
            list[0].tagList[0].linenum  = cm.line_no;
            list[0].tagList[0].taginfo = tag_compose_tag_browse_info(cm);
            list[0].tagList[0].browse_info = cm;
         }

         // keep track of duplicate entries
         seen_that:[list[0].prototype] = 0;
         if (info.symbol != null) {
            been_there:[cm.file_name":"cm.line_no] = 0;
         }

         i := j := 1;
         n := gAutoCompleteResults.words._length();
         for (i=0; i<n; i++) {
            VS_TAG_BROWSE_INFO cmi = gAutoCompleteResults.words[i].symbol;
            if (i != gAutoCompleteResults.wordIndex && cmi != null ) {
               if ((cm.member_name == cmi.member_name) &&
                   (cm.class_name == cmi.class_name) &&
                   (cm.type_name == cmi.type_name ||
                    (tag_tree_type_is_func(cm.type_name) == tag_tree_type_is_func(cmi.type_name) &&
                     tag_tree_type_is_data(cm.type_name) == tag_tree_type_is_data(cmi.type_name) &&
                     tag_tree_type_is_class(cm.type_name) == tag_tree_type_is_class(cmi.type_name) &&
                     tag_tree_type_is_package(cm.type_name) == tag_tree_type_is_package(cmi.type_name)
                    )
                   )
                  ) {
                  prototype := extension_get_decl(cmi.language, cmi, VSCODEHELPDCLFLAG_VERBOSE);
                  if (seen_that._indexin(prototype)) {
                     // if this is a total duplicate then forget about it.
                     if (been_there._indexin(cmi.file_name":"cmi.line_no)) {
                        continue;
                     }
                     k := seen_that:[prototype];
                     m := list[k].tagList._length();
                     if (k < 0 || k >= list._length()) continue;
                     list[k].tagList[m].filename = cmi.file_name;
                     list[k].tagList[m].linenum  = cmi.line_no;
                     list[k].tagList[m].taginfo = tag_compose_tag_browse_info(cmi);
                     list[k].tagList[m].browse_info = cmi;
                     list[k].tagList[m].comments = null;
                     list[k].tagList[m].comment_flags = VSCODEHELP_COMMENTFLAG_HTML;

                  } else if (!info.displayArguments || 
                             !tag_tree_compare_args(cm.arguments, cmi.arguments, true)) {

                     tag_autocode_arg_info_from_browse_info(auto dup_info, cmi, prototype);
                     dup_info.tagList[0].comments = null;
                     dup_info.tagList[0].comment_flags = VSCODEHELP_COMMENTFLAG_HTML;
                     seen_that:[prototype] = j;
                     list[j++] = dup_info;
                  }
               }
            }
         }
         HYPERTEXTSTACK stack;
         stack.HyperTextTop=0;
         stack.HyperTextMaxTop=stack.HyperTextTop;
         stack.s[stack.HyperTextTop].TagIndex=0;
         stack.s[stack.HyperTextTop].TagList=list;
         comment_wid.ctlminihtml1.p_user=stack;
         comment_wid.ShowCommentHelp(doFunctionHelp:false, 
                                     prefer_left_placement,
                                     comment_wid, 
                                     AutoCompleteGetEditorWid(),
                                     do_not_move_form:false, 
                                     gAutoCompleteResults.visited);
      }

      // make sure focus goes back to the editor
      p_window_id = editorctl_wid;
      _set_focus();
   }

   // that's all folks
   p_window_id = orig_wid;
   return 1;
}

/**
 * Set up the auto completion for the given word
 *
 * @return 1 on success
 */
static int AutoCompleteShowInfo(bool doHide=false)
{
   // make sure that auto complete is active
   editorctl_wid := AutoCompleteGetEditorWid();
   if (!_iswindow_valid(editorctl_wid) || !gAutoCompleteResults.allowShowInfo) {
      return 0;
   }

   
   // save the original window ID, and switch to the editor
   orig_wid := p_window_id;
   p_window_id = editorctl_wid;

   // out with the old
   if (gAutoCompleteResults.streamMarkerIndex >= 0) {
      _StreamMarkerRemove(gAutoCompleteResults.streamMarkerIndex);
      gAutoCompleteResults.streamMarkerIndex=-1;
   }

   auto_complete_options := AutoCompleteGetOptions(p_LangId);

   prefix := gAutoCompleteResults.prefix;
   word_index := gAutoCompleteResults.wordIndex;
   AUTO_COMPLETE_INFO info;
   if (word_index >= 0 && word_index < gAutoCompleteResults.words._length()) {
      // get the auto complete info for this item
      info=gAutoCompleteResults.words[word_index];
      if (!(auto_complete_options & AUTO_COMPLETE_NO_INSERT_SELECTED)) {
         word := info.insertWord;
         insertWord := info.insertWord;
         if (insertWord!=null) {
            word=insertWord;
         }
         AutoCompleteReplaceWord(info.pfnReplaceWord, prefix, word, true, info.symbol);
         //bool useQuickPrefix;
         prefix=getNewPrefix();
      }
   }

   // put together the auto complete suggestion message
   suggestion := "Auto complete \"" :+ prefix :+ "\".  " :+
                 "To set options, go to " :+
                 "Document > "_LangGetModeName(p_LangId)" Options and select Auto-Complete.";

   // in with the new
   int pic_type   = AutoCompleteGetPicType(true);
   int pic_bitmap = AutoCompleteGetPicture();
   int pic_range = _StreamMarkerAdd(p_window_id, _QROffset()-length(prefix), length(prefix), true, pic_bitmap, pic_type, suggestion);
   if (pic_range < 0) {
      AutoCompleteTerminate();
      p_window_id = orig_wid;
      return pic_range;
   }
   //if (auto_complete_options & AUTO_COMPLETE_SHOW_BAR) {
   //   _LineMarkerSetStyleColor(pic_range, _rgb(0,0,96));
   //}
   gAutoCompleteResults.streamMarkerIndex = pic_range;

   tree_wid := AutoCompleteGetTreeWid();
   if (word_index >= 0 && 
       word_index < gAutoCompleteResults.words._length()) {
      // and now for a floating box with the rest of the expansion
      if ((auto_complete_options & AUTO_COMPLETE_SHOW_WORD)  &&
          gAutoCompleteResults.allowImplicitReplace ) {

         // make sure the item is highlighted
         if (tree_wid > 0) {
            tree_wid.p_AlwaysColorCurrent = true;
         }

         // is there text after the cursor on this line?
         hasTextAfter := false;
         line := "";
         get_line(line);
         line=strip(line,'T');
         if ( p_col!=text_col(_rawText(line))+1 ) {
            hasTextAfter=true;
         }

         // compute position for text box
         // move up one line if there is text already there
         carot := "";
         int x=p_cursor_x+3;
         int y=p_cursor_y-1;
         // adjust x-position if we are also replacing the
         // word prefix, and not just appending to the word.
         word := strip(info.displayWord,'L','"');
         if (prefix != substr(word,1,length(prefix))) {
            x -= (p_font_width*length(prefix));
            hasTextAfter = true;
         }
         if (hasTextAfter) {
            y -= p_font_height;
            //carot=">";
            //x -= _text_width(carot);
         }

         _map_xy(p_window_id,0,x,y);

         // display the auto completion information
         if (length(word) > length(prefix)) {
            _str suffix = word;
            if (pos(prefix, word, 1, 'i') == 1) {
               suffix = substr(word,length(prefix)+1);
            }
            _bbhelp("",p_window_id,x,y,
                    carot:+suffix,
                    p_font_name,_StrFontSize2PointSizeX10(p_font_size),0,
                    _rgb(0,0,0)/*p_forecolor*/,
                    _rgb(224,224,255)/*p_backcolor*/);
         } else {
            _bbhelp('C');
         }
      }

   } else {

      // update the current item in the list view
      if (tree_wid > 0) {
         AutoCompleteDeselect();
         tree_wid._TreeRefresh();
      } else {
         gAutoCompleteResults.listForm = 0;
      }

      // get rid of the rest of the word hint
      _bbhelp('C');

   }

   // that's all folks
   p_window_id = orig_wid;
   return 1;
}

/**
 * Deselect any item currently selected by auto completion
 */
static void AutoCompleteDeselect()
{
   tree_wid := AutoCompleteGetTreeWid();
   if (tree_wid > 0) {
      index := tree_wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if (index < 0) index = TREE_ROOT_INDEX;
      tree_wid.p_enabled=false;
      tree_wid._TreeSetCurIndex(index);
      tree_wid.p_enabled=true;
   }
   gAutoCompleteResults.wordIndex=-1;
   _bbhelp('C');
}

/**
 * Reselect the given word.  This is necessary to make sure the same 
 * word stays selected for certain completion operations.
 */
static void AutoCompleteSelectWord(int categoryLevel, _str word)
{
   // check if we are invoking strict case-sensitivity rules
   // it depends on the situation in which we were invoked
   strictCaseSensitivity := false;
   if (gAutoCompleteResults.wasListSymbols) {
      strictCaseSensitivity = (_GetCodehelpFlags() & VSCODEHELPFLAG_LIST_MEMBERS_CASE_SENSITIVE) != 0;
   } else if (gAutoCompleteResults.wasForced) {
      strictCaseSensitivity = (_GetCodehelpFlags() & VSCODEHELPFLAG_IDENTIFIER_CASE_SENSITIVE) != 0;
   } else {
      strictCaseSensitivity = !(AutoCompleteGetOptions() & AUTO_COMPLETE_NO_STRICT_CASE);
   }

   tree_wid := AutoCompleteGetTreeWid();
   if (tree_wid > 0) {
      index := tree_wid._TreeSearch(TREE_ROOT_INDEX, "", "", categoryLevel);
      if (index < 0) index = TREE_ROOT_INDEX;
      index = tree_wid._TreeSearch(index, word);
      if (index < 0 && !strictCaseSensitivity) {
         index = tree_wid._TreeSearch(index, word, 'I');
      }
      if (index > 0) {
         tree_wid.p_enabled=false;
         tree_wid._TreeSetCurIndex(index);
         gAutoCompleteResults.wordIndex = tree_wid._TreeGetUserInfo(index);
         tree_wid.p_enabled=true;
      }
   }
}

_str AutoCompleteParagraphTag()
{
   return('<P style="margin-top:0pt;margin-bottom:0pt;" class="JavadocDescription">');
}

/**
 * Add an auto-complete category to the catalog of completion 
 * categories. 
 */
void AutoCompleteAddCategory(int priorityLevel, _str categoryName)
{
   gAutoCompleteCategoryNames:[priorityLevel] = categoryName;
}

/**
 * Is the given word match a symbol?
 */
static bool AutoCompleteWordIsSymbol(AUTO_COMPLETE_INFO &word)
{
   if (word.symbol == null) {
      return false;
   }
   if (word.priorityLevel < AUTO_COMPLETE_FIRST_SYMBOL_PRIORITY) {
      return false;
   }
   if (word.priorityLevel > AUTO_COMPLETE_LAST_SYMBOL_PRIORITY) {
      return false;
   }
   return true;
}

/**
 * Add an item to the array of auto completions being populated by
 * one of the auto completion callbacks.
 *
 * @param words      array of completion results
 * @param priority   priority for this result category
 * @param word       completion word
 * @param command    command for processing word
 * @param comments   description of word
 * @param symbol     symbol information
 */
void AutoCompleteAddResult(AUTO_COMPLETE_INFO (&words)[],
                           AutoCompletePriorities priority,
                           _str displayWord,
                           void (*pfnReplaceWord)(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol)=null,
                           _str comments="",
                           VS_TAG_BROWSE_INFO &symbol=null,
                           bool caseSensitive=true,
                           int bitmapIndex=0,
                           _str insertWord=null
                           )
{
   //say("AutoCompleteAddResult: word="displayWord);
   AUTO_COMPLETE_INFO info;
   info.priorityLevel = priority;
   info.displayWord  = displayWord;
   info.displayArguments = false;
   info.comments = comments;
   info.comment_flags = VSCODEHELP_COMMENTFLAG_HTML;
   info.pfnReplaceWord=pfnReplaceWord;
   info.symbol   = symbol;
   info.caseSensitive=caseSensitive;
   info.bitmapIndex=bitmapIndex;
   if (insertWord==null) {
      info.insertWord=displayWord;
   } else {
      info.insertWord=insertWord;
   }
   //_dump_var(info, "AutoCompleteAddResult H"__LINE__": info");
   words :+= info;
}

/**
 * Indicate that there was an exact match to the word prefix.
 * This will disable auto-selection.
 */
void AutoCompleteFoundExactMatch()
{
   gAutoCompleteResults.foundExactMatch = true;
}

/**
 * Generate a suggestion for what would be expanded by syntax expansion
 * (space expansion). 
 * <p> 
 * This function calls the extension specific callback function
 * _[ext]_get_syntax_completions(var words, _str prefix='') 
 *  
 * @param options     auto completion options
 *
 * @return 0 on success, <0 on error.
 */
static int AutoCompleteGetSyntaxExpansion(AutoCompleteFlags options, bool forceUpdate=false)
{   
   // get the current line
   orig_line := "";
   get_line(orig_line);

   // set min_abbrev to -1 if we are forcing the list no matter what
   min_abbrev := (forceUpdate? -1 : 0);

   // now find the callback and call it
   index := _FindLanguageCallbackIndex("_%s_get_syntax_completions", p_LangId);
   if (index > 0) {
      return call_index(gAutoCompleteResults.words, strip(orig_line), min_abbrev, index);
   }
   return STRING_NOT_FOUND_RC;
}

/**
 * For case insensetive languages, call the extension specific 
 * callback to adjust the keyword case of keywords, and syntax 
 * expansion results. 
 *  
 * @param kw   keyword or string to adjust case of 
 * @return keyword in language specific case 
 */
_str AutoCompleteKeywordCase(_str kw, _str sample="")
{
   // do nothing for case sensitive languages
   if (p_EmbeddedCaseSensitive) return kw;

   // get index of keyword_case callback function
   keyword_case_index := _FindLanguageCallbackIndex("_%s_keyword_case");
   if (!keyword_case_index) return kw;

   // call the extension specific function
   return call_index(kw, false, sample, keyword_case_index);
}

/**
 * Generic function used for finding the syntax expansion hints
 * available, assuming we are given a list of "space words", as
 * normally required by {@link min_abbrev2()}.
 * <p>
 * Unless the <code>min_abbrev</code> argument is explicitely passed in,
 * this function assumes that the minimum expandable keyword length is
 * stored in the 3rd item of "name_info" for the current extension.
 *
 * @param words         array of auto complete items
 * @param space_words   language specific array or hash table
 *                      of completion keywords
 * @param min_abbrev    minimum keyword prefix length
 */
int AutoCompleteGetSyntaxSpaceWords(var words, typeless &space_words, _str prefix="", int min_abbrev=0)
{
   // get the current line
   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line,'T');
   orig_word := strip(line);
   if ( line!="" && p_col!=text_col(_rawText(line))+1 ) {
      return STRING_NOT_FOUND_RC;
   }

   // did they give us a min_abbrev argument
   if (min_abbrev == 0) {
      tmp_abbrev := LanguageSettings.getMinimumAbbreviation(p_LangId);
      if (isnumber(tmp_abbrev)) {
         min_abbrev = tmp_abbrev;
      }
      tmp_abbrev = LanguageSettings.getAutoCompleteMinimumLength(p_LangId);
      if (isnumber(tmp_abbrev) && tmp_abbrev < min_abbrev) {
         min_abbrev = tmp_abbrev;
      }
   }

   // is the word under the cursor shorter than the min_abbrev setting?
   if (length(orig_word) < min_abbrev) {
      return STRING_NOT_FOUND_RC;
   }

   // find matches among the space words
   aliasfilename := "";

   // if syntax expansion is turned off, we need to turn it on for just a second
   synExpOff := !LanguageSettings.getSyntaxExpansion(p_LangId);
   if (synExpOff) LanguageSettings.setSyntaxExpansion(p_LangId, true);
   word := min_abbrev2(orig_word,space_words,"",aliasfilename,false,true);

   // turn it back off now
   if (synExpOff) LanguageSettings.setSyntaxExpansion(p_LangId, false);

   if (aliasfilename==null || (word=="" && min_abbrev>0)) {
      return STRING_NOT_FOUND_RC;
   }

   // get picture indexes for _f_code.svg
   if (!_pic_syntax) {
      _pic_syntax = load_picture(-1,"_f_code.svg");
      if (_pic_syntax >= 0) {
         set_name_info(_pic_syntax, "Syntax expansion");
      }
   }

   // add each match
   _str all_matches = word;
   while (all_matches != "") {

      // get the match word
      parse all_matches with word ";" all_matches;

      // get the syntax expansion information for this word
      SYNTAX_EXPANSION_INFO sei;
      sei.statement="";
      if (space_words._varformat()==VF_HASHTAB && space_words._indexin(lowcase(word))) {
         sei = space_words:[lowcase(word)];
      }

      // skip this word if it is an exact match and syntax
      // expansion does nothing special with it
      if (word==orig_word && space_words._varformat()==VF_HASHTAB) {
         if (sei.statement=="" || sei.statement == orig_word) {
            continue;
         }
      }

      // get the comment for this word
      _str insertWord = word;
      bigComment :=  "Syntax expansion for ":+word;
      if (sei.statement != "") {
         word = sei.statement;
         bigComment = word:+"<hr>":+AutoCompleteParagraphTag():+bigComment;
      }

      // if the language is case in-sensitive, try to auto-case the keywords
      word = AutoCompleteKeywordCase(word, orig_word);
      insertWord = AutoCompleteKeywordCase(insertWord, orig_word);

      // add it to the list of results
      AutoCompleteAddResult(words, 
                            AUTO_COMPLETE_SYNTAX_PRIORITY,
                            word,
                            _autocomplete_space, 
                            bigComment,
                            null, 
                            p_EmbeddedCaseSensitive, 
                            _pic_syntax, 
                            insertWord);
   }

   // success
   return 0;
}

/**
 * Get the list of keywords that could be automatically completed
 * based on the current identifier prefix.
 *
 * @param options     auto completion options 
 * @param forceUpdate ignore min-abbrev settings 
 *
 * @return 0 on success, <0 on error.
 */
static int AutoCompleteGetKeywords(AutoCompleteFlags options, bool forceUpdate=false)
{
   // get the correct lexer name
   lexer_name := p_EmbeddedLexerName;
   if (lexer_name=="") lexer_name = p_lexer_name;

   // Do we even have a lexer for this mode?
   if (lexer_name == "") {
      return STRING_NOT_FOUND_RC;
   }

   // Are we in a comment or a string, then bail out
   color := _clex_find(0,'G');
   if (color == CFG_STRING || color == CFG_COMMENT) {
      return STRING_NOT_FOUND_RC;
   }

   // cope with case-sensitivity issues
   prefix := gAutoCompleteResults.prefix;
   case_sensitive := p_EmbeddedCaseSensitive;
   if (!case_sensitive) {
      prefix=upcase(prefix);
   }

   // special case for preprocessing keywords
   preprocessingPrefix := "";
   if ((gAutoCompleteResults.idexp_info != null) && 
       (gAutoCompleteResults.idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING)) {
      if (gAutoCompleteResults.idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING_ARGS) {
         return STRING_NOT_FOUND_RC;
      }
      preprocessingPrefix = gAutoCompleteResults.idexp_info.prefixexp;
      prefix = preprocessingPrefix :+ prefix;
   }

   // did they give us a min_abbrev argument
   // is the word under the cursor shorter than the min_abbrev setting?
   if (!forceUpdate && !_LanguageInheritsFrom("xml") && !_LanguageInheritsFrom("html") && !_LanguageInheritsFrom("dtd")) {
      min_abbrev := 0;
      tmp_abbrev := LanguageSettings.getMinimumAbbreviation(p_LangId);
      if (isnumber(tmp_abbrev)) {
         min_abbrev = tmp_abbrev;
      }
      tmp_abbrev = LanguageSettings.getAutoCompleteMinimumLength(p_LangId);
      if (isnumber(tmp_abbrev) && tmp_abbrev < min_abbrev) {
         min_abbrev = tmp_abbrev;
      }
      if (length(prefix) < min_abbrev) {
         return STRING_NOT_FOUND_RC;
      }
   }

   // get the color coding profile for this language
   handle := _plugin_get_profile(VSCFGPACKAGE_COLORCODING_PROFILES,lexer_name);
   if (handle<0) {
      return FILE_NOT_FOUND_RC;
   }

   // create a hash table of words we have already seen
   // (these are words suggested by syntax expansion)
   bool syntax_words:[];
   n := gAutoCompleteResults.words._length();
   for (i:=0; i<n; ++i) {
      space_word := gAutoCompleteResults.words[i].insertWord;
      if (!case_sensitive) space_word = upcase(space_word);
      syntax_words:[space_word] = true;
   }

   // get picture indexes for _keyword.svg
   if (!_pic_keyword) {
      _pic_keyword = load_picture(-1,"_f_keyword.svg");
      if (_pic_keyword >= 0) {
         set_name_info(_pic_keyword, "Keyword");
      }
   }

   profile_node:=_xmlcfg_set_path(handle,"/profile");
   int array[];
   _xmlcfg_list_properties(array,handle,profile_node,'^(k|lib|pp)'VSXMLCFG_PROPERTY_SEPARATOR,'r');
   // create a temporary view and search for the keywords
   for (i=0;i<array._length();++i) {
      node := array[i];
      parse _xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_NAME) with auto section (VSXMLCFG_PROPERTY_SEPARATOR) auto cur;
      attrs_node := _xmlcfg_get_first_child(handle,node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      doAdd := false;
      tcase_sensitive := case_sensitive;
      if (attrs_node>=0) {
         // check for attrs node with no attributes
         while (attrs_node>=0) {
            send:=_xmlcfg_get_attribute(handle,attrs_node,"end");
            if (send=="") {
               sflags:=_xmlcfg_get_attribute(handle,attrs_node,"flags");
               if (pos(' regex ',' 'sflags' ')) {
                  break;
               }
               scase_sensitive:=_xmlcfg_get_attribute(handle,attrs_node,"case_sensitive");
               if (scase_sensitive!="") {
                  tcase_sensitive=(scase_sensitive==1) ;
               }
               doAdd=true;
               break;
            }
            attrs_node=_xmlcfg_get_next_sibling(handle,attrs_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
         }
      } else {
         doAdd=true;
      }
      if (!doAdd) {
         continue;
      }
      kw := (tcase_sensitive)? cur : upcase(cur);
      //if (section=="csk") kw=cur;
      if (syntax_words._indexin(kw)) continue;
      if (kw==prefix) {
         AutoCompleteFoundExactMatch();
      }
      if (prefix=="" || pos(prefix,kw)==1) {
         // call extension specific keyword case function
         if (section=="k") {
            cur = AutoCompleteKeywordCase(cur, gAutoCompleteResults.prefix);
         }
         insertWord := cur;
         if (preprocessingPrefix != "" && pos(preprocessingPrefix, cur) == 1) {
            insertWord = substr(cur,length(preprocessingPrefix)+1);
         }

         // now insert the keyword
         AutoCompleteAddResult(gAutoCompleteResults.words, 
                               AUTO_COMPLETE_KEYWORD_PRIORITY,
                               cur, 
                               null, 
                               "Keyword: ":+cur, 
                               null,
                               tcase_sensitive, //(case_sensitive || (section=="csk")),
                               _pic_keyword,
                               insertWord);
         syntax_words:[kw] = true;
      }
   }
   _xmlcfg_close(handle);
   return(0);
}

/**
 * Generate a suggestion for what would be expanded by the "expand-alias" command.
 * <P>
 * NOTE: aliases must be an exact match, so there can be only one
 *
 * @param options     auto completion options
 *
 * @return 0 on success, <0 on error.
 */
static int AutoCompleteGetAliasExpansion(AutoCompleteFlags options, bool forceUpdate=false)
{
   return find_alias_completions(gAutoCompleteResults.words, forceUpdate);
}

static int AutoCompleteGetAllSymbols(_str (&errorArgs)[],
                                     AutoCompleteFlags auto_complete_options,
                                     AutoCompleteSubwordPattern auto_complete_subword_option,
                                     bool forceUpdate,
                                     _str lastid,
                                     _str lastid_prefix,
                                     bool matchAnyWord,
                                     bool caseSensitive,
                                     SETagContextFlags context_flags,
                                     AutoCompletePriorities symbol_priority,
                                     VS_TAG_IDEXP_INFO idexp_info,
                                     int &num_symbols, int max_symbols,
                                     VS_TAG_RETURN_TYPE (&visited):[],
                                     int depth=0)
{
   if (_chdebug) {
      isay(depth, "AutoCompleteGetAllSymbols: lastid="lastid" lastid_prefix="lastid_prefix" caseSensitive="caseSensitive" matchAnyWord="matchAnyWord" force="forceUpdate);
   }

   // first try matching entire word under the cursor
   origNumWords := gAutoCompleteResults.words._length();
   symbolsStatus := 0;
   status := AutoCompleteGetSymbolMatches(errorArgs,
                                          auto_complete_options,
                                          auto_complete_subword_option,
                                          forceUpdate,
                                          lastid, 
                                          matchAnyWord,
                                          caseSensitive,
                                          context_flags,
                                          symbol_priority,
                                          gAutoCompleteResults.idexp_info,
                                          num_symbols, max_symbols,
                                          gAutoCompleteResults.visited,
                                          depth+1);
   if (!symbolsStatus && status < 0) symbolsStatus = status;
   if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
   if (_CheckTimeout()) {
      return VSCODEHELPRC_LIST_MEMBERS_TIMEOUT;
   }
   if (gAutoCompleteResults.words._length() - origNumWords > def_auto_complete_max_symbols) {
      return VSCODEHELPRC_LIST_MEMBERS_LIMITED;
   }

   // then try finding word matching the word prefix to the left of the cursor
   if (length(lastid_prefix) < length(lastid)) {
      _str newErrorArgs[];
      status = AutoCompleteGetSymbolMatches(newErrorArgs,
                                            auto_complete_options,
                                            auto_complete_subword_option,
                                            forceUpdate,
                                            lastid_prefix, 
                                            matchAnyWord,
                                            caseSensitive,
                                            context_flags,
                                            symbol_priority,
                                            gAutoCompleteResults.idexp_info,
                                            num_symbols, max_symbols,
                                            gAutoCompleteResults.visited,
                                            depth+1);
      if (!symbolsStatus && status < 0) {
         errorArgs = newErrorArgs;
         symbolsStatus = status;
      }
      if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
      if (_CheckTimeout()) {
         return VSCODEHELPRC_LIST_MEMBERS_TIMEOUT;
      }
      if (gAutoCompleteResults.words._length() - origNumWords > def_auto_complete_max_symbols) {
         return VSCODEHELPRC_LIST_MEMBERS_LIMITED;
      }
   }

   // check if we are invoking strict case-sensitivity rules
   strictCaseSensitivity := false;
   if (forceUpdate) {
      strictCaseSensitivity = (_GetCodehelpFlags() & VSCODEHELPFLAG_LIST_MEMBERS_CASE_SENSITIVE) != 0;
   } else {
      strictCaseSensitivity = !(auto_complete_options & AUTO_COMPLETE_NO_STRICT_CASE);
   }

   if (caseSensitive && !strictCaseSensitivity) {
      _str newErrorArgs[];
      status = AutoCompleteGetSymbolMatches(newErrorArgs,
                                            auto_complete_options,
                                            auto_complete_subword_option,
                                            forceUpdate,
                                            lastid, 
                                            matchAnyWord, 
                                            caseSensitive:false,
                                            context_flags,
                                            symbol_priority,
                                            gAutoCompleteResults.idexp_info,
                                            num_symbols, max_symbols,
                                            gAutoCompleteResults.visited,
                                            depth+1);
      if (!symbolsStatus && status < 0) {
         errorArgs = newErrorArgs;
         symbolsStatus = status;
      }
      if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
      if (_CheckTimeout()) {
         return VSCODEHELPRC_LIST_MEMBERS_TIMEOUT;
      }
      if (gAutoCompleteResults.words._length() - origNumWords > def_auto_complete_max_symbols) {
         return VSCODEHELPRC_LIST_MEMBERS_LIMITED;
      }

      if (length(lastid_prefix) < length(lastid)) {
         newErrorArgs._makeempty();
         status = AutoCompleteGetSymbolMatches(newErrorArgs,
                                               auto_complete_options,
                                               auto_complete_subword_option,
                                               forceUpdate,
                                               lastid_prefix,
                                               matchAnyWord, 
                                               caseSensitive:false,
                                               context_flags,
                                               symbol_priority,
                                               gAutoCompleteResults.idexp_info,
                                               num_symbols, max_symbols,
                                               gAutoCompleteResults.visited,
                                               depth+1);
         if (!symbolsStatus && status < 0) {
            errorArgs = newErrorArgs;
            symbolsStatus = status;
         }
         if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
         if (_CheckTimeout()) {
            return VSCODEHELPRC_LIST_MEMBERS_TIMEOUT;
         }
         if (gAutoCompleteResults.words._length() - origNumWords > def_auto_complete_max_symbols) {
            return VSCODEHELPRC_LIST_MEMBERS_LIMITED;
         }
      }
   }
   
   if (matchAnyWord &&
       gAutoCompleteResults.words._length() <= origNumWords &&
       length(lastid_prefix) > 0 && 
       !(idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING   ) &&
       !(idexp_info.info_flags & VSAUTOCODEINFO_IN_STRING_OR_NUMBER)) {
      _str newErrorArgs[];
      status = AutoCompleteGetSymbols(newErrorArgs,
                                      auto_complete_options,
                                      forceUpdate,
                                      lastid_prefix: "",
                                      matchAnyWord,
                                      caseSensitive,
                                      SE_TAG_FILTER_ANYTHING,
                                      context_flags,
                                      symbol_priority,
                                      idexp_info,
                                      num_symbols, max_symbols,
                                      gAutoCompleteResults.visited,
                                      depth+1);
      if (!symbolsStatus && status < 0) {
         errorArgs = newErrorArgs;
         symbolsStatus = status;
      }
      if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
      if (_CheckTimeout()) {
         return VSCODEHELPRC_LIST_MEMBERS_TIMEOUT;
      }
      if (gAutoCompleteResults.words._length() - origNumWords > def_auto_complete_max_symbols) {
         return VSCODEHELPRC_LIST_MEMBERS_LIMITED;
      }
   }

   return symbolsStatus;
}

static int AutoCompleteGetSymbolMatches(_str (&errorArgs)[],
                                        AutoCompleteFlags auto_complete_options,
                                        AutoCompleteSubwordPattern auto_complete_pattern,
                                        bool forceUpdate,
                                        _str lastid_pattern,
                                        bool matchAnyWord,
                                        bool caseSensitive,
                                        SETagContextFlags context_flags,
                                        AutoCompletePriorities symbol_priority,
                                        VS_TAG_IDEXP_INFO idexp_info,
                                        int &num_symbols, int max_symbols,
                                        VS_TAG_RETURN_TYPE (&visited):[],
                                        int depth=0)
{
   if (_chdebug) {
      isay(depth, "AutoCompleteGetAllSymbolMatchess: lastid_pattern="lastid_pattern" caseSensitive="caseSensitive" matchAnyWord="matchAnyWord" force="forceUpdate);
      tag_dump_context_flags(context_flags, "AutoCompleteGetSymbolMatches", depth);
   }

   // get the pattern matching options
   doPatternMatching := false;
   pattern_flags := SE_TAG_CONTEXT_MATCH_PREFIX;
   if (_haveContextTagging() && /*matchAnyWord && */ (auto_complete_pattern != AUTO_COMPLETE_SUBWORD_MATCH_NONE)) {
      codehelpFlags := _GetCodehelpFlags(p_LangId);
      doPatternMatching = true;
      if (forceUpdate) {
         doPatternMatching = !(codehelpFlags & VSCODEHELPFLAG_LIST_MEMBERS_NO_SUBWORD_MATCHES);
         if (doPatternMatching && gAutoCompleteResults.wasFirstSubwordMatchingAttempt) {
            if (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_ONLY_ON_RETRY) {
               doPatternMatching = false;
            }
         }
      } else {
         doPatternMatching = (auto_complete_options & AUTO_COMPLETE_SUBWORD_MATCHES) != 0;
      }
      if (lastid_pattern == "" && doPatternMatching) {
         doPatternMatching = false;
      }
      if (doPatternMatching) {
         // do not allow pattern matching or if in preprocessing or a string or number
         if ((idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING) ||
             (idexp_info.info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) ||
             (idexp_info.info_flags & VSAUTOCODEINFO_IN_STRING_OR_NUMBER)) {
            doPatternMatching = false;
         } else {
            pattern_flags = AutoCompleteGetSubwordPatternFlags(p_LangId);
         }
         if (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_WORKSPACE_ONLY) {
            pattern_flags |= SE_TAG_CONTEXT_ONLY_WORKSPACE;
            if (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_INC_AUTO_UPDATED) {
               pattern_flags |= SE_TAG_CONTEXT_INCLUDE_AUTO_UPDATED;
            }
            if (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_INC_COMPILER) {
               pattern_flags |= SE_TAG_CONTEXT_INCLUDE_COMPILER;
            }
            if (codehelpFlags & VSCODEHELPFLAG_SUBWORD_MATCHING_RELAX_ORDER) {
               pattern_flags |= SE_TAG_CONTEXT_MATCH_RELAX_ORDER;
            }
         }
         // special case searching for globals to make it more restrictive
         if (!forceUpdate && (auto_complete_options & AUTO_COMPLETE_SUBWORD_NO_GLOBALS)) {
            if (!(context_flags & SE_TAG_CONTEXT_NO_GLOBALS) &&
                !(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS) &&
                !(context_flags & SE_TAG_CONTEXT_ONLY_INCLASS) &&
                !(context_flags & SE_TAG_CONTEXT_ONLY_THIS_CLASS) &&
                !(context_flags & SE_TAG_CONTEXT_ONLY_THIS_FILE) &&
                !(context_flags & SE_TAG_CONTEXT_ONLY_CONTEXT)) {
               if (idexp_info.prefixexp == "" || idexp_info.prefixexp == "::" || idexp_info.prefixexp == "new") {
                  // disable pattern matching if they are allowing searching for globals
                  doPatternMatching = false;
               } else if (length(lastid_pattern) < AutoCompleteGetMinimumLength(p_LangId)+1) { 
                  // do not allow pattern matching if the pattern is too short
                  doPatternMatching = false;
               }
            }
         }
      }
      if (_chdebug && doPatternMatching) {
         isay(depth, "AutoCompleteGetSymbolMatches: USING PATTERN MATCHING");
      }
   }

   origNumWords := gAutoCompleteResults.words._length();
   symbolsStatus := 0;
   status := AutoCompleteGetSymbols(errorArgs,
                                    auto_complete_options,
                                    forceUpdate,
                                    lastid_pattern,
                                    matchAnyWord || doPatternMatching, 
                                    caseSensitive,
                                    SE_TAG_FILTER_ANYTHING,
                                    context_flags, 
                                    symbol_priority,
                                    gAutoCompleteResults.idexp_info,
                                    num_symbols, max_symbols,
                                    gAutoCompleteResults.visited,
                                    depth+1);
   if (!symbolsStatus && status < 0) symbolsStatus = status;
   if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
   if (_CheckTimeout()) {
      return VSCODEHELPRC_LIST_MEMBERS_TIMEOUT;
   }
   if (gAutoCompleteResults.words._length() - origNumWords > def_auto_complete_max_symbols) {
      return VSCODEHELPRC_LIST_MEMBERS_LIMITED;
   }

   // try patterning matching using the identifier under the cursor
   if (lastid_pattern != "" && doPatternMatching) {
      // if we are looking for global variables
      // try matching symbols whose first character matches
      orig_num_symbols := num_symbols;
      if (!(context_flags & SE_TAG_CONTEXT_NO_GLOBALS)) {
         _str newErrorArgs[];
         status = AutoCompleteGetSymbols(newErrorArgs,
                                         auto_complete_options,
                                         forceUpdate,
                                         lastid_pattern,
                                         matchAnyWord || doPatternMatching, 
                                         caseSensitive,
                                         SE_TAG_FILTER_ANYTHING,
                                         context_flags | pattern_flags | SE_TAG_CONTEXT_MATCH_FIRST_CHAR, 
                                         symbol_priority,
                                         gAutoCompleteResults.idexp_info,
                                         num_symbols, max_symbols,
                                         gAutoCompleteResults.visited,
                                         depth+1);
         if (!symbolsStatus && status < 0) {
            errorArgs = newErrorArgs;
            symbolsStatus = status;
         }
         if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
         if (_CheckTimeout()) {
            return VSCODEHELPRC_LIST_MEMBERS_TIMEOUT;
         }
         if (gAutoCompleteResults.words._length() - origNumWords > def_auto_complete_max_symbols) {
            return VSCODEHELPRC_LIST_MEMBERS_LIMITED;
         }
         // if first character matching yielded matches, 
         // then do not do general matching (for performance)
         if (!status && !symbolsStatus && num_symbols > orig_num_symbols) {
            if (_GetCodehelpFlags() & VSCODEHELPFLAG_SUBWORD_MATCHING_GLOBALS_FIRST_CHAR) {
               return symbolsStatus;
            }
         }
      }

      // then try general pattern matching
      if (length(lastid_pattern) > 1 || (context_flags & SE_TAG_CONTEXT_NO_GLOBALS)) {
         _str newErrorArgs[];
         status = AutoCompleteGetSymbols(newErrorArgs,
                                         auto_complete_options,
                                         forceUpdate,
                                         lastid_pattern,
                                         matchAnyWord || doPatternMatching, 
                                         caseSensitive,
                                         SE_TAG_FILTER_ANYTHING,
                                         context_flags | pattern_flags,
                                         symbol_priority,
                                         gAutoCompleteResults.idexp_info,
                                         num_symbols, max_symbols,
                                         gAutoCompleteResults.visited,
                                         depth+1);
         if (!symbolsStatus && status < 0) {
            errorArgs = newErrorArgs;
            symbolsStatus = status;
         }
         if (doPatternMatching) {
            gAutoCompleteResults.wasFirstSubwordMatchingAttempt = false;
         }
         if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
         if (_CheckTimeout()) {
            return VSCODEHELPRC_LIST_MEMBERS_TIMEOUT;
         }
         if (gAutoCompleteResults.words._length() - origNumWords > def_auto_complete_max_symbols) {
            return VSCODEHELPRC_LIST_MEMBERS_LIMITED;
         }
      }
   }

   return symbolsStatus;
}

/**
 * Generate a suggestion for what would be completed by the 
 * "codehelp_complete" command.
 *
 * @param options     auto completion options
 *
 * @return 0 on success, <0 on error.
 */
static int AutoCompleteGetSymbols(_str (&errorArgs)[],
                                  AutoCompleteFlags auto_complete_options, 
                                  bool forceUpdate,
                                  _str lastid_prefix,
                                  bool matchAnyWord,
                                  bool caseSensitive,
                                  SETagFilterFlags filter_flags,
                                  SETagContextFlags context_flags,
                                  AutoCompletePriorities symbol_priority,
                                  VS_TAG_IDEXP_INFO idexp_info,
                                  int &num_symbols, int max_symbols,
                                  VS_TAG_RETURN_TYPE (&visited):[],
                                  int depth=0)
{
   if (_chdebug) {
      isay(depth, "AutoCompleteGetSymbols: lastid_prefix="lastid_prefix" caseSensitive="caseSensitive" force="forceUpdate);
      tag_dump_context_flags(context_flags, "AutoCompleteGetSymbols", depth);
   }

   // Make sure that tagging is supported for this extension
   if (!_istagging_supported(p_LangId)) {
      //say("AutoCompleteGetSymbols: TAGGING NOT SUPPORTED");
      return TAGGING_NOT_SUPPORTED_FOR_FILE_RC;
   }

   // Make sure the current context is up-to-date the first time we start
   // auto-complete, but let the old results ride as we are typing.
   // This gives us a slightly better response type while typing and
   // refreshing the auto complete list.
   isActive := AutoCompleteActive();
   if (!isActive) {
      MaybeBuildTagFile(p_LangId,false,true);
      _UpdateContextAndTokens(true,forceUpdate);
      _UpdateLocals(true);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // compose the expansion prefix
   word := "";
   orig_word := idexp_info.lastid;
   if (!forceUpdate && orig_word == "") {
      //say("AutoCompleteGetSymbols: EMPTY PREFIX");
      return VSCODEHELPRC_CONTEXT_NOT_VALID;
   }
   if (!forceUpdate && idexp_info.lastidstart_col+length(idexp_info.lastid) != p_col) {
      //say("AutoCompleteGetSymbols: INVALID COLUMN");
      return STRING_NOT_FOUND_RC;
   }
   
   tag_push_matches();
   tag_clear_matches();
   save_pos(auto p);
   status := _Embeddedfind_context_tags(idexp_info.errorArgs, 
                                        idexp_info.prefixexp,
                                        lastid_prefix,
                                        idexp_info.lastidstart_offset,
                                        idexp_info.info_flags, 
                                        idexp_info.otherinfo,
                                        false, max_symbols,
                                        false, caseSensitive,
                                        filter_flags,
                                        context_flags,
                                        visited, depth+1);
   restore_pos(p);
   if (status < 0) {
      tag_pop_matches();
      //say("AutoCompleteGetSymbols: FIND CONTEXT TAGS FAILED status="status);
      errorArgs = idexp_info.errorArgs;
      if (errorArgs._length()==0) errorArgs[1] = lastid_prefix;
      return status;
   }

   // no matches, then we are out of here
   num_matches := tag_get_num_of_matches();
   if (num_matches <= 0) {
      tag_pop_matches();
      //say("AutoCompleteGetSymbols: NO MATCHES");
      if (errorArgs._length()<=1 || length(errorArgs[1]) < length(lastid_prefix)) {
         errorArgs[1] = lastid_prefix;
      }
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // look up the replace symbol callback for this language
   void (*pfnReplaceWord)(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol) = null;
   index := _FindLanguageCallbackIndex("_%s_autocomplete_replace_symbol", p_LangId);
   if (index > 0) {
      pfnReplaceWord = name_index2funptr(index);
   }

   // get the auto completion options
   case_options := caseSensitive? "":"I";

   // add each match to the list
   for (i:=1; i <= num_matches; ++i) {

      // get the symbol information
      tag_get_match_info(i, auto cm);
      if (_chdebug) {
         tag_browse_info_dump(cm, "AutoCompleteGetSymbols["i"]");
      }

      // skip anonymous identifiers
      if (cm.flags & SE_TAG_FLAG_ANONYMOUS) {
         if (_chdebug) {
            say("AutoCompleteGetSymbols H"__LINE__": ANONYMOUS");
         }
         continue;
      }

      // get the completed symbol name
      word = cm.member_name;
      // check for overloaded operators
      if (cm.flags & SE_TAG_FLAG_OPERATOR) {
         word = "operator ":+cm.member_name;
      }
      if (_chdebug) {
         say("AutoCompleteGetSymbols H"__LINE__": WORD="word);
      }
      if (word == orig_word) {
         if (_chdebug) {
            say("AutoCompleteGetSymbols H"__LINE__": FOUND EXACT");
         }
         AutoCompleteFoundExactMatch();
      }

      // Add the single unique match with it's comments
      if (!matchAnyWord && lastid_prefix!="" && pos(lastid_prefix, word, 1, case_options) != 1) {
         if (_chdebug) {
            say("AutoCompleteGetSymbols H"__LINE__": NOT A PREFIX MATCH");
         }
         continue;
      }
      if (!forceUpdate && _file_eq(cm.file_name,p_buf_name) && cm.line_no == p_RLine && (cm.name_seekpos <= 0 || ((_QROffset() >= cm.name_seekpos-2) && (_QROffset() <= cm.name_seekpos+length(cm.member_name)+2)))) {
         if (_chdebug) {
            say("AutoCompleteGetSymbols H"__LINE__": FILE AND LINE MATCHES CURRENT SYMBOL");
         }
         continue;
      }

      // Add the single unique match with it's comments
      AutoCompleteAddResult(gAutoCompleteResults.words,
                            symbol_priority,
                            word,
                            pfnReplaceWord,
                            cm.doc_comments, 
                            cm);
   }

   // success
   tag_pop_matches();
   num_symbols += num_matches;
   if (_chdebug) {
      //_dump_var(gAutoCompleteResults.words, "AutoCompleteGetSymbols H"__LINE__": words");
      say("AutoCompleteGetSymbols: SUCCESS, num matches="num_matches);
   }
   return 0;
}

/**
 * Generate a suggestion for what would be completed by the 
 * function argument listing of symbols with compatible values
 *
 * @param options     auto completion options
 *
 * @return 0 on success, <0 on error.
 */
static int AutoCompleteGetCompatibleValues(_str (&errorArgs)[],
                                           AutoCompleteFlags options, 
                                           bool forceUpdate,
                                           _str lastid_prefix,
                                           bool caseSensitive,
                                           VS_TAG_IDEXP_INFO idexp_info,
                                           _str expected_type,
                                           VS_TAG_RETURN_TYPE rt,
                                           _str expected_name,
                                           VS_TAG_RETURN_TYPE (&visited):[],
                                           int depth=0
                                           )
{
   if (_chdebug) {
      isay(depth, "AutoCompleteGetCompatibleValues: HERE");
   }
   // Completely disable this feature for SlickEdit Standard
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // Make sure that tagging is supported for this extension
   if (!_istagging_supported(p_LangId)) {
      return TAGGING_NOT_SUPPORTED_FOR_FILE_RC;
   }

   // Make sure the current context is up-to-date the first time we start
   // auto-complete, but let the old results ride as we are typing.
   // This gives us a slightly better response type while typing and
   // refreshing the auto complete list.
   isActive := AutoCompleteActive();
   if (!isActive) {
      MaybeBuildTagFile(p_LangId,false,true);
      _UpdateContextAndTokens(true,forceUpdate);
      _UpdateLocals(true);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // compose the expansion prefix
   word := "";
   orig_word := idexp_info.lastid;

   // make sure that we aren't looking for an empty string
   if (!forceUpdate && idexp_info.lastidstart_col+length(idexp_info.lastid) != p_col) {
      return VSCODEHELPRC_CONTEXT_NOT_VALID;
   }
   
   // look up the compatible symbol matches   
   tag_push_matches();
   tag_clear_matches();
   status := _Embeddedinsert_auto_params(errorArgs,
                                         gAutoCompleteResults.editor,
                                         0, // insert into match set
                                         idexp_info.prefixexp,
                                         idexp_info.lastid,
                                         lastid_prefix,
                                         idexp_info.lastidstart_offset,
                                         expected_type,
                                         rt,
                                         expected_name,
                                         idexp_info.info_flags,
                                         idexp_info.otherinfo,
                                         visited);  
   if (status < 0) {
      tag_pop_matches();
      return status;
   }

   // no matches, then we are out of here
   num_matches := tag_get_num_of_matches();
   if (num_matches <= 0) {
      tag_pop_matches();
      errorArgs[1] = lastid_prefix;
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // look up the replace symbol callback for this language
   void (*pfnReplaceWord)(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol) = null;
   index := _FindLanguageCallbackIndex("_%s_autocomplete_replace_symbol", p_LangId);
   if (index > 0) {
      pfnReplaceWord = name_index2funptr(index);
   }

   // get the auto completion options
   auto_complete_options := AutoCompleteGetOptions();
   case_options := caseSensitive? "":"I";

   // add each match to the list
   for (i:=1; i <= num_matches; ++i) {

      // get the symbol information
      tag_get_match_info(i, auto cm);

      // get the completed symbol name
      word = cm.member_name;
      if (word == orig_word) {
         AutoCompleteFoundExactMatch();
      }
      if (lastid_prefix!="" && pos(lastid_prefix, word, 1, case_options) != 1) {
         //continue;
      }
      if (_file_eq(cm.file_name,p_buf_name) && cm.line_no == p_RLine) {
         continue;
      }

      // Add the single unique match with it's comments
      AutoCompleteAddResult(gAutoCompleteResults.words, 
                            AUTO_COMPLETE_COMPATIBLE_PRIORITY,
                            word,
                            pfnReplaceWord, //_symbol_autocomplete,
                            "", 
                            cm);
   }

   // success
   tag_pop_matches();
   return 0;
}
/**
 * 
 * 
 * @author dbrueni (1/11/18)
 */
static void AutoCompleteGetSymbolComments()
{
   int word_index = gAutoCompleteResults.wordIndex;
   if (word_index < 0 || word_index >= gAutoCompleteResults.words._length()) {
      return;
   }

   if (gAutoCompleteResults.words[word_index].comments != "") {
      return;
   }

   if (gAutoCompleteResults.words[word_index].symbol == null) {
      return;
   }

   // get the editor control and make it current
   orig_wid := p_window_id;
   editorctl_wid := AutoCompleteGetEditorWid();
   if (!_iswindow_valid(editorctl_wid)) {
      return;
   }
   p_window_id = editorctl_wid;

   // get the symbol information for the current item
   VS_TAG_BROWSE_INFO cm = gAutoCompleteResults.words[word_index].symbol;

   // get the create a symbol declaration
   tag_info := "";
   auto_complete_options := AutoCompleteGetOptions();
   if (auto_complete_options & AUTO_COMPLETE_SHOW_DECL) {
      tag_info=extension_get_decl(p_LangId, cm, VSCODEHELPDCLFLAG_VERBOSE);
      tag_info="";
   }

   comment_flags := VSCODEHELP_COMMENTFLAG_HTML;
   comment_info  := "";
   if (_haveContextTagging() && (auto_complete_options & AUTO_COMPLETE_SHOW_COMMENTS)) {

      if (GetCommentInfoForSymbol(cm, comment_flags, comment_info, gAutoCompleteResults.visited)) {
         // we can use the comments attached to the symbol by tagging
      } else if (cm.file_name != "") {
         _ExtractTagComments2(comment_flags,
                              comment_info, 150,   /*_xmlcfg_find_simple has large comment */
                              cm.member_name, cm.file_name, cm.line_no
                              );
      }
      if (comment_info!="") {
         param_name := (cm.type_name=="param")? cm.member_name:"";
         _make_html_comments(comment_info,comment_flags,cm.return_type,param_name,true,cm.language);
      }
   }

   // concatenate the comment information
   comments := tag_info;
   if (tag_info == "") {
      comments = comment_info;
   } else if (comment_info != "") {
      comments :+= "<hr>" :+ comment_info;
   }

   // restore the window ID and upate the comments
   p_window_id = orig_wid;
   gAutoCompleteResults.words[word_index].comments = comments;
   gAutoCompleteResults.words[word_index].comment_flags = comment_flags|VSCODEHELP_COMMENTFLAG_HTML;
}

/**
 * Generate a suggestion for what could be completed by the "complete-list" command.
 *
 * @param options     auto completion options
 *
 * @return 0 on success, <0 on error.
 */
static int AutoCompleteGetWordCompletions(AutoCompleteFlags options, _str prefixexp="", bool forceUpdate=false)
{
   find_complete_list_completions(gAutoCompleteResults.words, def_auto_complete_max_words, prefixexp, forceUpdate);
   return 0;
}

/**
 * Generate suggestions for extension-specific completions.
 * In particular, generate suggestions for command arguments in
 * the process buffer.
 *
 * @param options     auto completion options
 *
 * @return 0 on success, <0 on error.
 */
static void AutoCompleteGetLanguageSpecificArguments(AutoCompleteFlags options, bool forceUpdate=false)
{
   index := _FindLanguageCallbackIndex("_%s_autocomplete_get_arguments");
   if (index) {
      call_index(gAutoCompleteResults.words, forceUpdate, index);
   }
}

/**
 * Generate suggestions for what could be expanded using
 * argument completion for the current object.
 */
static int AutoCompleteGetArguments(int options)
{
   callback_name := "";
   typeless completion_flags=0;
   parse p_completion with callback_name ":" completion_flags;
   if (callback_name == NONE_ARG) {
      return STRING_NOT_FOUND_RC;
   }

   index := find_index(callback_name:+"_match",PROC_TYPE|COMMAND_TYPE);
   if (!index || !index_callable(index)) {
      return STRING_NOT_FOUND_RC;
   }

   find_first := true;
   for (;; find_first=false) {
      _str result = call_index(p_text, find_first, index);
      if (result == "") {
         break;
      }

      if (p_completion==TAG_ARG) {
         tag_decompose_tag_browse_info(result, auto cm);
         AutoCompleteAddResult(gAutoCompleteResults.words, 
                               AUTO_COMPLETE_ARGUMENT_PRIORITY,
                               cm.member_name, 
                               null, 
                               "", 
                               cm);
      } else {
         AutoCompleteAddResult(gAutoCompleteResults.words, 
                               AUTO_COMPLETE_ARGUMENT_PRIORITY,
                               result,
                               null,
                               "Argument "result);
      }
   }

   return 0;
}

///////////////////////////////////////////////////////////////////////////////

/**
 * Is auto completion active?
 */
bool AutoCompleteActive()
{
   return gAutoCompleteResults.editor != 0 && gAutoCompleteResults.isActive;
}
/**
 * Should we restart auto-list-parameters (after use typed space, for example)?
 */
bool AutoCompleteDoRestartListParameters()
{
   if (AutoCompleteActive()) return false;
   if (gAutoCompleteResults.wasListParameters) {
      return gAutoCompleteResults.maybeRestartListParametersAfterKey;
   }
   return false;
}

/**
 * @return Return the window ID of the editor control
 * displaying auto completion results right now.
 */
static int AutoCompleteGetEditorWid()
{
   int wid = gAutoCompleteResults.editor;
   if (wid > 0 && _iswindow_valid(wid) && wid._isEditorCtl()) {
      return wid;
   }
   return 0;
}
/**
 * @return Return the window ID of the tree being
 * displaying the list of auto complete results.
 */
static int AutoCompleteGetTreeWid()
{
   _nocheck _control ctltree;
   int wid = gAutoCompleteResults.listForm;
   if (wid > 0 && _iswindow_valid(wid) && wid._find_control("ctltree")) {
      return wid.ctltree;
   }
   return 0;
}
/**
 * @return Return the window ID of the comment form
 * displaying the comments for the selected completion.
 */
static int AutoCompleteGetCommentsWid()
{
   int wid = gAutoCompleteResults.commentForm;
   if (wid > 0 && _iswindow_valid(wid)) {
      return wid;
   }
   return 0;
}

/**
 * Break out of auto completion mode.
 */
void AutoCompleteTerminate()
{
   // clear out auto-complete results
   gAutoCompleteResults.idexp_info = null;
   gAutoCompleteResults.expected_rt = null;
   gAutoCompleteResults.expected_type="";
   gAutoCompleteResults.expected_name="";
   gAutoCompleteResults.visited._makeempty();
   gAutoCompleteResults.words._makeempty();
   gAutoCompleteResults.origLineContent=null;
   gAutoCompleteResults.removeLen=0;
   gAutoCompleteResults.allowInsertLongest=true;
   gAutoCompleteResults.allowShowInfo=false;
   gAutoCompleteResults.allowImplicitReplace=false;
   gAutoCompleteResults.wordIndex = -1;
   gAutoCompleteResults.wasForced = false;
   gAutoCompleteResults.wasListSymbols = false;
   gAutoCompleteResults.wasFirstSubwordMatchingAttempt = true;
   gAutoCompleteResults.ignoreSwitchBufAndModuleLoadEvents=false;

   // make sure that auto complete is actually active
   orig_wid := p_window_id;
   editorctl_wid := AutoCompleteGetEditorWid();
   if (!_iswindow_valid(editorctl_wid)) {
      return;
   }
   p_window_id = editorctl_wid;

   // first kill the pesky timer
   AutoCompleteKillTimer();

   // uncomment this to debug when auto-complete fails
   /*
   if (AutoCompleteActive()) {
      say("AutoCompleteTerminate H"__LINE__": AUTO COMPLETE TERMINATED ******");
      _StackDump();
      _dump_var(gAutoCompleteResults);
      say("AutoCompleteTerminate H"__LINE__": I WILL BE BACK. ***************");
   } 
   */ 

   // remove the light bulb picture
   doRefresh := false;
   if (gAutoCompleteResults.streamMarkerIndex >= 0) {
      _StreamMarkerRemove(gAutoCompleteResults.streamMarkerIndex);
      gAutoCompleteResults.streamMarkerIndex=-1;
      doRefresh = true;
   }

   // remove the word completion
   _bbhelp('C');

   // remove the comment form
   comment_wid := AutoCompleteGetCommentsWid();
   if (comment_wid != 0) {
      comment_wid._delete_window();
      doRefresh=true;
   }
   gAutoCompleteResults.commentForm = 0;

   // remove the list form
   list_wid := AutoCompleteGetTreeWid();
   if (list_wid != 0) {
      gAutoCompleteResults.listForm._delete_window();
      doRefresh=true;
   }
   gAutoCompleteResults.listForm = 0;

   // remove the event table from the editor control
   _RemoveEventtab(defeventtab auto_complete_key_overrides);
   gAutoCompleteResults.editor = 0;
   gAutoCompleteResults.isActive = false;

   // this is a good place to instrument this if we want to catch
   // when auto-complete closes unexpectedly
   //_StackDump();

   // reset the position information
   gAutoCompleteResults.lineoffset  = 0;
   gAutoCompleteResults.column = 0;
   gAutoCompleteResults.buffer = 0;
   gAutoCompleteResults.lastModified = 0;

   // no current item
   gAutoCompleteResults.wordIndex = -1;

   // force refresh if necessary
   if (doRefresh) {
      refresh();
   }

   // restore the original window, if still valid
   if (_iswindow_valid(orig_wid)) {
      p_window_id = orig_wid;
   }
}

// Is the prefix in the list
static bool AutoCompletePrefixValid(_str prefix)
{
   // not in list help?
   if (AutoCompleteGetEditorWid() != 0) {
      return false;
   }

   if (_last_char(prefix)=="(") {
      return false;
   }

   int i;
   count := gAutoCompleteResults.words._length();
   for (i=0;i<count;++i) {
      if(strieq(substr(gAutoCompleteResults.words[i].insertWord,1,length(prefix)),prefix)) {
         return(true);
      }
   }

   return false;
}

static _str getNewPrefix()
{
   adjustCol := 0;
   if (gAutoCompleteResults.removeLen &&
       gAutoCompleteResults.removeStartCol<=gAutoCompleteResults.start_col
       ) {
      adjustCol=gAutoCompleteResults.removeLen;
   }
   //say(gAutoCompleteResults.removeStartCol" "gAutoCompleteResults.start_col" p="gAutoCompleteResults.prefix" rl="gAutoCompleteResults.removeLen" c="adjustCol);
   return(_expand_tabsc(gAutoCompleteResults.start_col+adjustCol,p_col-gAutoCompleteResults.start_col-adjustCol));
}
static void getQuickPrefix(bool &useQuickPrefix,bool &needsUpdate=false,_str key="")
{
   if (AutoCompleteGetEditorWid() != 0) {
      if (gAutoCompleteResults.editor == p_window_id &&
          gAutoCompleteResults.lineoffset == point() &&
          gAutoCompleteResults.buffer == p_buf_id &&
          gAutoCompleteResults.start_col >= 0 &&
          gAutoCompleteResults.start_col <= p_col
          ) {
         gAutoCompleteResults.prefix=getNewPrefix();
         if (gAutoCompleteResults.prefix!="" && AutoCompletePrefixValid(gAutoCompleteResults.prefix:+key)) {
            useQuickPrefix=true;
         }
      }

      if (gAutoCompleteResults.editor  != p_window_id ||
          gAutoCompleteResults.lineoffset != point() ||
          (gAutoCompleteResults.column != p_col && !useQuickPrefix) ||
          gAutoCompleteResults.buffer  != p_buf_id) {
         needsUpdate=true;
      }
   }
}

void _MaybeUpdateAutoCompleteInfo(bool AlwaysUpdate=false)
{
   AutoCompleteUpdateInfo(AlwaysUpdate);
}

/**                                   
 * Update the completion suggestions.  This function is called from the
 * auto-save timer, and synchronously from <code>AutoCompleteDoKey()</code>
 * and the <code>autocomplete</code> command.
 *
 * @param alwaysUpdate     Update now, do not wait for idle timer
 * @param forceUpdate      Force update, independent of auto complete options
 *
 * @return 0 on success, <0 on error.
 *
 * @see autocomplete
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Completion_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
int AutoCompleteUpdateInfo(bool alwaysUpdate=false, 
                           bool forceUpdate=false,
                           bool doInsertLongest=false,
                           bool operatorTyped=false,
                           bool prefixMatch=true,
                           VS_TAG_IDEXP_INFO idexp_info=null,
                           _str expected_type=null,
                           VS_TAG_RETURN_TYPE expected_rt=null,
                           _str expected_name=null,
                           bool selectMatchingItem=false,
                           bool doListParameters=false,
                           bool isFirstAttempt=true,
                           _str (&errorArgs)[]=null
                          )
{
   // turn off auto-copmlete if we have mulitple cursors
   if (_MultiCursorAlreadyLooping()) {
      //say("AutoCompleteUpdateInfo: MULTIPLE CURSORS");
      return 0;
   }

   // have we waited long enough yet?
   errorArgs._makeempty();
   wasActive := AutoCompleteActive();
   idle := (wasActive? def_auto_complete_update_idle_time:def_auto_complete_idle_time);
   elapsed := _idle_time_elapsed();
   if (!alwaysUpdate && !forceUpdate && elapsed < idle) {
      // are we half-way there, maybe we should just do it down if this
      // is a small buffer with fast performance statistics
      if ((elapsed > idle intdiv 2) && _isEditorCtl() && _UpdateContextAndTokensIsFast()) {
         // faster auto-complete for faster files
      } else {
         //say("AutoCompleteUpdateInfo: NOT ENOUGH IDLE TIME ELAPSED");
         return 0;
      }
   }

   // switch to the editor that has focus
   focus_wid := _get_focus();

   // has it been too long (15 seconds) since the last character was typed ?
   if (!wasActive && !alwaysUpdate && !forceUpdate && 
       elapsed > def_auto_complete_timeout_forced) {
      //say("AutoCompleteUpdateInfo: TOO LATE - DEADLINE EXPIRED");
      return 0;
   }

   // make sure the focus wid is valid
   if (!_iswindow_valid(focus_wid)) {
      if (focus_wid) {
         AutoCompleteTerminate();
      } else if (!gAutoCompleteResults.ignoreSwitchBufAndModuleLoadEvents) {
         AutoCompleteTerminate();
      }
      //say("AutoCompleteUpdateInfo: FOCUS WINDOWS NOT VALID");
      return INVALID_OBJECT_HANDLE_RC;
   }

   // If one of the auto complete dialogs has obtained focus,
   // just parlay that focus to the editor control
   if (wasActive) {
      if (focus_wid == gAutoCompleteResults.listForm ||
          focus_wid.p_active_form == gAutoCompleteResults.listForm ||
          focus_wid == AutoCompleteGetTreeWid() ||
          focus_wid == gAutoCompleteResults.commentForm ||
          focus_wid.p_active_form == gAutoCompleteResults.commentForm) {
         focus_wid = gAutoCompleteResults.editor;
      }
   }

   // make sure the focus wid is an editor control
   if (!focus_wid._isEditorCtl()) {
      AutoCompleteTerminate();
      //say("AutoCompleteUpdateInfo: FOCUS WINDOW NOT AN EDITOR CONTROL");
      return INVALID_OBJECT_HANDLE_RC;
   }

   // no auto-complete in hex mode
   if (focus_wid.p_hex_mode == HM_HEX_ON) {
      AutoCompleteTerminate();
      //say("AutoCompleteUpdateInfo: HEX MODE");
      return VSRC_CFG_HEX_MODE_COLOR;
   }

   // ok, now switch to the designated editor control
   orig_wid := p_window_id;
   p_window_id = focus_wid;

   // if the context is not yet up-to-date, then don't update yet
   // unless we are forcing update, then update it immediately
   if (!alwaysUpdate && !forceUpdate && !wasActive && !_ContextIsUpToDate(elapsed, MODIFYFLAG_CONTEXT_UPDATED|MODIFYFLAG_TOKENLIST_UPDATED)) {
      p_window_id = orig_wid;
      //say("AutoCompleteUpdateInfo: CONTEXT NOT YET UP-TO-DATE");
      return 0;
   }

   // is there a selection active
   wasForced := (wasActive && gAutoCompleteResults.wasForced);
   if (!forceUpdate && !wasForced && select_active()) {
      AutoCompleteTerminate();
      p_window_id = orig_wid;
      //say("AutoCompleteUpdateInfo: SELECTION CURRENTLY ACTIVE");
      return 0;
   }

   // is word completion active?
   if (!forceUpdate && CompleteWordActive()) {
      AutoCompleteTerminate();
      p_window_id = orig_wid;
      //say("AutoCompleteUpdateInfo: COMPLETE WORD ACTIVE");
      return COMMAND_CANCELLED_RC;
   }

   // is auto completion completely disabled?
   auto_complete_options := AutoCompleteGetOptions();
   if (!forceUpdate && !(auto_complete_options & AUTO_COMPLETE_ENABLE) && !wasActive) {
      if ((!operatorTyped && !doListParameters) || !(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS)) {
         AutoCompleteTerminate();
         p_window_id = orig_wid;
         //say("AutoCompleteUpdateInfo: AUTO COMPLETE DISABLED");
         return VSRC_COMMAND_IS_DISABLED_FOR_THIS_OBJECT_OR_STATE;
      }
   }

   // disable auto-complete options that do not apply if we don't have context tagging
   if (!_haveContextTagging()) {
      auto_complete_options &= ~AUTO_COMPLETE_MEMBERS;
      auto_complete_options &= ~AUTO_COMPLETE_SHOW_COMMENTS;
      auto_complete_options &= ~AUTO_COMPLETE_EXTENSION_ARGS;
      auto_complete_options &= ~AUTO_COMPLETE_LANGUAGE_ARGS;
      auto_complete_options &= ~AUTO_COMPLETE_ARGUMENTS;
      auto_complete_options &= ~AUTO_COMPLETE_SHOW_PROTOTYPES;
   }

   // has the cursor moved, then blow away the previous suggestion
   origForceUpdate := forceUpdate;
   needsUpdate := forceUpdate;
   if (!forceUpdate && !wasActive && alwaysUpdate) {
      needsUpdate = true;
   }
   useQuickPrefix := false;
   getQuickPrefix(useQuickPrefix, needsUpdate);
   if (!wasActive && expected_type != null && expected_type != "") forceUpdate = true;

   // still up to date with modify flags?
   //say("h2 force="forceUpdate" needsUpdate="needsUpdate" updated="(p_ModifyFlags & MODIFYFLAG_AUTO_COMPLETE_UPDATED));
   if (!forceUpdate && !needsUpdate && ((p_ModifyFlags & MODIFYFLAG_AUTO_COMPLETE_UPDATED))) {
      p_window_id = orig_wid;
      if (_chdebug) {
         say("AutoCompleteUpdateInfo: ALREADY UP-TO-DATE OR INACTIVE");
      }
      return 0;
   }

   // The buffer hasn't changed, yet p_Modified was reset.
   // A tag file update must have reset p_ModifyFlags.
   if (!forceUpdate && !needsUpdate && 
       (gAutoCompleteResults.lastModified == p_LastModified) &&
       (!(p_ModifyFlags & MODIFYFLAG_AUTO_COMPLETE_UPDATED))) {
      operatorTyped = gAutoCompleteResults.operatorTyped;
      idexp_info = gAutoCompleteResults.idexp_info;
      expected_type = gAutoCompleteResults.expected_type;
      expected_rt   = gAutoCompleteResults.expected_rt;
      expected_name = gAutoCompleteResults.expected_name;
      doListParameters = gAutoCompleteResults.wasListParameters;
      useQuickPrefix = false;
      needsUpdate = true;
   }

   // has the buffer been modified?
   if (!forceUpdate && !needsUpdate && !p_modify) {
      p_window_id = orig_wid;
      //say("AutoCompleteUpdateInfo: BUFFER IS UNCHANGED");
      return 0;
   }

   // Determine which timeout amount to use.
   // Give it more time if it was forced by typing a keystroke.
   timeout_time := def_auto_complete_timeout_time;
   if (alwaysUpdate && forceUpdate && !operatorTyped) {
      timeout_time = def_auto_complete_timeout_forced;
   }

   // check if the tag database is busy and we can't get a lock.
   se.tags.TaggingGuard sentry;
   status := 0;
   dbName := _GetWorkspaceTagsFilename();
   if (dbName != "" && _haveContextTagging()) {
      haveDBLock := tag_trylock_db(dbName);
      if (!forceUpdate && !haveDBLock) {
         p_window_id = orig_wid;
         //say("AutoCompleteUpdateInfo: COULD NOT GET DATABASE LOCK");
         return TAGGING_TIMEOUT_RC;
      }

      // replace the trylock with a guard to handle all function return paths
      status = sentry.lockDatabase(dbName, timeout_time);
      if (haveDBLock) {
         tag_unlock_db(dbName);
      }
      if (status < 0) {
         p_window_id = orig_wid;
         //say("AutoCompleteUpdateInfo: DATABASE LOCK TIMED OUT");
         return status;
      }
   }

   // update modify flags and positional information
   p_ModifyFlags |= MODIFYFLAG_AUTO_COMPLETE_UPDATED;

   // Verify that we are at the end of an identifier
   if (!origForceUpdate && p_col==1) {
      AutoCompleteTerminate();
      p_window_id = orig_wid;
      //say("AutoCompleteUpdateInfo: END OF IDENTIFIER");
      return 0;
   }
   
   // Need to add _extra_word_chars for fundamental mode and 
   // when in comments or strings in order to support auto completion
   // on text words.
   // Here I add the _extra_word_chars for all cases but if this causes
   // a problem we should change this.
   //
   ch := get_text();
   word_chars := _clex_identifier_chars():+_extra_word_chars;
   if (!forceUpdate && 
       !gAutoCompleteResults.wasForced && 
       !gAutoCompleteResults.wasListSymbols && idexp_info==null && 
       pos('^['word_chars']$',ch,1,'re') > 0) {
      AutoCompleteTerminate();
      p_window_id = orig_wid;
      //say("AutoCompleteUpdateInfo: NOT ON AN ID CHAR");
      return VSCODEHELPRC_CONTEXT_NOT_VALID;
   }

   // add file separate character for directory lookups
   extra_chars := "";
   if (_LanguageInheritsFrom("bat") || 
       _LanguageInheritsFrom("process") || 
       _LanguageInheritsFrom("bourneshell") ||
       _LanguageInheritsFrom("csh") ||
       _LanguageInheritsFrom("ini") ||
       _LanguageInheritsFrom("mak") ||
       _LanguageInheritsFrom("powerwhell")) {
      extra_chars = _escape_re_chars(FILESEP);
      if (_isWindows()) {
         extra_chars :+= _escape_re_chars(FILESEP2);
         extra_chars :+= _escape_re_chars(":");
      }
   }

   // check that the last key press event was an identifier character
   // Also allow ON_KEYSTATECHANGE because they may have just released SHIFT
   wasForced = (wasActive && gAutoCompleteResults.wasForced);
   if (!forceUpdate && !operatorTyped) {
      // There has been an edit and a key has been pressed.
      lev := event2name(last_event(null,true));
      // Active, Terminate the list if the prefix changes
      // non-active, Start the list if a valid key is pressed.
      if (length(lev) == 1 && !pos('^['extra_chars:+word_chars']$', lev, 1, 'r') &&
          // We definitely don't want the list to close when pressing <Backspace>.
          // This is also nice for other keys like <Del>,upcase-word, etc.
          !useQuickPrefix &&
          !(lev=='"' && wasActive && get_text()=='"') &&
          !(last_event(null,true)==BACKSPACE && wasActive) &&
          !(last_event(null,true)==TAB && wasActive)
          ) {
         //say("lev="lev" index="event2index(last_event(null,true)));
         AutoCompleteTerminate();
         //say("AutoCompleteUpdateInfo: LAST KEY PRESS WAS NOT ID CHAR");
         return 0;
      }
   }

   status=0;
   if (!wasActive) {
      gAutoCompleteResults.operatorTyped=operatorTyped;
      gAutoCompleteResults.wasListParameters=doListParameters;
      gAutoCompleteResults.doShowCategories=false;
      gAutoCompleteResults.wasForced=forceUpdate;
      gAutoCompleteResults.wasFirstSubwordMatchingAttempt = isFirstAttempt;
      gAutoCompleteResults.expected_type=expected_type;
      gAutoCompleteResults.expected_rt=expected_rt;
      gAutoCompleteResults.expected_name=expected_name;
      gAutoCompleteResults.visited._makeempty();
      gAutoCompleteResults.wasListSymbols = (idexp_info != null);
   } else if ((expected_type != null && expected_type != "") || expected_rt != null) {
      gAutoCompleteResults.expected_type=expected_type;
      gAutoCompleteResults.expected_rt=expected_rt;
      gAutoCompleteResults.expected_name=expected_name;
      gAutoCompleteResults.wasListSymbols = true;
      forceUpdate = (forceUpdate || gAutoCompleteResults.wasForced);
      if (!isFirstAttempt) {
         gAutoCompleteResults.wasFirstSubwordMatchingAttempt = false;
      }
   } else {
      expected_type = gAutoCompleteResults.expected_type;
      expected_rt   = gAutoCompleteResults.expected_rt;
      expected_name = gAutoCompleteResults.expected_name;
      forceUpdate = (forceUpdate || gAutoCompleteResults.wasForced);
      if (!isFirstAttempt) {
         gAutoCompleteResults.wasFirstSubwordMatchingAttempt = false;
      }
   }
   
   gAutoCompleteResults.lineoffset = point();
   gAutoCompleteResults.column = p_col;
   gAutoCompleteResults.buffer = p_buf_id;
   gAutoCompleteResults.lastModified = p_LastModified;
   if (!wasActive || gAutoCompleteResults.editor != p_window_id) {
      gAutoCompleteResults.editor = p_window_id;
      gAutoCompleteResults.editor._AddEventtab(defeventtab auto_complete_key_overrides);
   }

   // temporarily disable auto-complete switch-buf and module load hooks
   // they will be re-enabled by AutoCompleteTerminate(), or immedately after
   // this function finishes gathering results.
   gAutoCompleteResults.ignoreSwitchBufAndModuleLoadEvents = true;

   // modify flags
   FAKEOUT_MODIFY_FLAGS := (MODIFYFLAG_CONTEXT_UPDATED|MODIFYFLAG_LOCALS_UPDATED|MODIFYFLAG_STATEMENTS_UPDATED);

   // enable symbols if they forced update
   symbolsStatus := 0;
   isListSymbols := gAutoCompleteResults.wasListSymbols;
   origIdExpression := gAutoCompleteResults.idexp_info;
   if (isListSymbols) {
      auto_complete_options |= AUTO_COMPLETE_SYMBOLS;
   }
   
   if (useQuickPrefix) {
      gAutoCompleteResults.idexp_info.lastid=gAutoCompleteResults.prefix;
      // Forget about a minimum since the list is already up.  Can't do this
      // if a call back is defined!!!
      //if ((!origForceUpdate && length(complete_arg)<auto_complete_minimum) ) {
      //   AutoCompleteTerminate();
      //    p_window_id = orig_wid;
      //   return 0;
      //}
   } else {
      auto_complete_minimum := AutoCompleteGetMinimumLength(p_LangId);
      index := _FindLanguageCallbackIndex("_%s_autocomplete_get_prefix");
      int start_col;
      prefix_set := false;
      if (index_callable(index)) {
         prefix_set=true;
         col := 0;
         _str complete_arg=null;
         status=call_index(gAutoCompleteResults.prefix,start_col,complete_arg,index);
         if (complete_arg==null) {
            complete_arg=gAutoCompleteResults.prefix;
         }
         if (status < 0 || (!origForceUpdate && length(complete_arg)<auto_complete_minimum) ) {
            AutoCompleteTerminate();
            p_window_id = orig_wid;
            //say("AutoCompleteUpdateInfo: IDENTIFIER IS EMPTY");
            errorArgs = idexp_info.errorArgs;
            return status;
         }
      } else {
         save_pos(auto p);
         left();
         ch = get_text();
         restore_pos(p);
         if (!forceUpdate && !isListSymbols &&
             !pos('^['extra_chars:+word_chars']$',ch,1,'re')) {
            AutoCompleteTerminate();
            p_window_id = orig_wid;
            //say("AutoCompleteUpdateInfo: ON FIRST CHAR OF IDENTIFIER");
            return VSCODEHELPRC_CONTEXT_NOT_VALID;
         }

         // Verify that the prefix length is long enough
         status = search('['word_chars']#|$', '@-rh');
         if (status < 0 || at_end_of_line()) {
            restore_pos(p);
            if (forceUpdate || isListSymbols) {
               start_col = gAutoCompleteResults.column;
            } else {
               AutoCompleteTerminate();
               p_window_id = orig_wid;
               //say("AutoCompleteUpdateInfo: PREFIX LENGTH TOO SHORT");
               return 0;
            }
         } else {
            start_col = p_col;
            ch = get_text();
         }

         // verify that we landed in the same word we started in
         save_pos(auto start_p);
         status = search('[^'extra_chars:+word_chars']|$', '@rh');
         if (status < 0 || p_col < gAutoCompleteResults.column) {
            restore_pos(p);
            if (forceUpdate || isListSymbols) {
               start_col = gAutoCompleteResults.column;
               gAutoCompleteResults.end_col = start_col;
               ch = get_text();
            } else {
               AutoCompleteTerminate();
               p_window_id = orig_wid;
               //say("AutoCompleteUpdateInfo: NOT IN WORD ANYMORE");
               return VSCODEHELPRC_CONTEXT_NOT_VALID;
            }
         } else {
            gAutoCompleteResults.end_col = p_col;
            restore_pos(start_p);
         }
         
         if (!forceUpdate && isdigit(ch)) {
            restore_pos(p);
            AutoCompleteTerminate();
            p_window_id = orig_wid;
            //say("AutoCompleteUpdateInfo: SITTING ON NUMBER");
            return VSCODEHELPRC_CONTEXT_NOT_VALID;
         }
         if (gAutoCompleteResults.column > start_col) {
            gAutoCompleteResults.prefix = get_text(gAutoCompleteResults.column-start_col);
         } else {
            gAutoCompleteResults.prefix = "";
         }
         restore_pos(p);
         if (!forceUpdate && !isListSymbols && !status && gAutoCompleteResults.column - start_col < auto_complete_minimum) {
            AutoCompleteTerminate();
            p_window_id = orig_wid;
            //say("AutoCompleteUpdateInfo: IDEXP_INFO IDENTIFIER IS EMPTY");
            return 0;
         }
      }

      // look up the identifier prefix expression
      if (_istagging_supported()) {
         int orig_flag=gAutoCompleteResults.editor.p_ModifyFlags&FAKEOUT_MODIFY_FLAGS;
         if (wasActive) {
            gAutoCompleteResults.editor.p_ModifyFlags|= FAKEOUT_MODIFY_FLAGS;
         }
         ext := "";
         typeless r1,r2,r3,r4,r5;
         save_search(r1,r2,r3,r4,r5);
         if (idexp_info == null) {
            tag_idexp_info_init(idexp_info);
            status = _Embeddedget_expression_info(operatorTyped, 
                                                  ext, 
                                                  idexp_info, 
                                                  gAutoCompleteResults.visited);
         } else {
            status = 0;
         }
         gAutoCompleteResults.idexp_info=idexp_info;
         if (!status && idexp_info != null && idexp_info.lastid != null && idexp_info.lastid != "") {
            gAutoCompleteResults.end_col = idexp_info.lastidstart_col + length(idexp_info.lastid);
         }
         restore_search(r1,r2,r3,r4,r5);
         if (status < 0) {
            // if the get_expression_info callback fails, we won't get any symbols
            auto_complete_options &= ~AUTO_COMPLETE_SYMBOLS;
            errorArgs = idexp_info.errorArgs;
            symbolsStatus = status;
         } else if (isListSymbols) {
            auto_complete_options &= ~AUTO_COMPLETE_WORDS;
            auto_complete_options &= ~AUTO_COMPLETE_ALIAS;
            if (!(idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING) ||
                (idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING_ARGS)) {
               auto_complete_options &= ~AUTO_COMPLETE_KEYWORDS;
               auto_complete_options &= ~AUTO_COMPLETE_SYNTAX;
            }
         } else if (idexp_info.prefixexp != "") {
            // if there is a prefix expression, turn off syntax and keywords
            auto_complete_options &= ~AUTO_COMPLETE_ALIAS;
            if (!(idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING) ||
                (idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING_ARGS)) {
               auto_complete_options &= ~AUTO_COMPLETE_KEYWORDS;
               auto_complete_options &= ~AUTO_COMPLETE_SYNTAX;
            }
         } else if ((expected_type != null && expected_type != "") || expected_rt != null) {
            auto_complete_options &= ~AUTO_COMPLETE_ALIAS;
            auto_complete_options &= ~AUTO_COMPLETE_SYNTAX;
            auto_complete_options &= ~AUTO_COMPLETE_KEYWORDS;
         }
         // this lastid should be more accurate than the word search
         if (!status && idexp_info.lastid != "" && !prefix_set && p_col > idexp_info.lastidstart_col) {
            gAutoCompleteResults.prefix = substr(idexp_info.lastid, 1, p_col-idexp_info.lastidstart_col);
         }
         if (!status && 
             !(idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING_ARGS) &&
              (idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING)) {
            auto_complete_options &= ~AUTO_COMPLETE_SYMBOLS;
            auto_complete_options &= ~AUTO_COMPLETE_WORDS;
         }
         if (wasActive) {
            gAutoCompleteResults.editor.p_ModifyFlags&= ~FAKEOUT_MODIFY_FLAGS;
            gAutoCompleteResults.editor.p_ModifyFlags|= orig_flag;
         }
      }
      gAutoCompleteResults.start_col=start_col;
   }

   // if we backspaced entirely over our prefix expression,
   // then shut down auto-complete.
   if (wasActive && //!forceUpdate &&
       origIdExpression != null && origIdExpression.prefixexp != "" &&
       idexp_info != null &&  idexp_info.prefixexp == "") {
      AutoCompleteTerminate();
      p_window_id = orig_wid;
      //say("AutoCompleteUpdateInfo: DELETED PREFIX EXPRESSION");
      return 0;
   }

   // We have to finish updating within this time period
   // More time is allowed for manually updating.
   sc.lang.ScopedTimeoutGuard timeout;
   if (timeout_time) {
      _SetTimeout(timeout_time);
   }

   // start embedded mode
   typeless orig_values;
   int embedded = _EmbeddedStart(orig_values);

   // attempt to find multiple matches?
   gAutoCompleteResults.words._makeempty();
   gAutoCompleteResults.foundExactMatch=false;
   gAutoCompleteResults.allowInsertLongest=true;
   gAutoCompleteResults.removeLen=0;
   gAutoCompleteResults.origPrefix=gAutoCompleteResults.prefix;
   get_line(gAutoCompleteResults.origLineContent);
   gAutoCompleteResults.origCol=p_col;
   gAutoCompleteResults.replaceWordPos="";
   gAutoCompleteResults.doShowCategories=false;

   // look for syntax expansion opportunities
   orig_word := word := comments := command := "";
   if ((auto_complete_options & AUTO_COMPLETE_SYNTAX) && !_CheckTimeout()) {
      AutoCompleteGetSyntaxExpansion(auto_complete_options, forceUpdate);
   }

   // Look for keywords, by looking at color coding
   if ((auto_complete_options & AUTO_COMPLETE_KEYWORDS) && !_CheckTimeout()) {
      AutoCompleteGetKeywords(auto_complete_options, forceUpdate);
   }

   // Look for alias expansion opportunities
   if ((auto_complete_options & AUTO_COMPLETE_ALIAS) && !_CheckTimeout()) {
      AutoCompleteGetAliasExpansion(auto_complete_options, forceUpdate);
   }

   // Look for symbols matching the return type specified
   if ((expected_type != null && expected_type != "") || (expected_rt != null)) {
      if ((auto_complete_options & AUTO_COMPLETE_SYMBOLS) && _istagging_supported() && !_CheckTimeout()) {
         prefix := gAutoCompleteResults.prefix;
         lastid := gAutoCompleteResults.idexp_info.lastid;
         orig_flag := gAutoCompleteResults.editor.p_ModifyFlags&FAKEOUT_MODIFY_FLAGS;
         if (wasActive) {
            gAutoCompleteResults.editor.p_ModifyFlags |= FAKEOUT_MODIFY_FLAGS;
         }
         gAutoCompleteResults.visited._makeempty();
         status = AutoCompleteGetCompatibleValues(errorArgs, auto_complete_options,
                                                  forceUpdate,
                                                  lastid, p_EmbeddedCaseSensitive,
                                                  gAutoCompleteResults.idexp_info,
                                                  gAutoCompleteResults.expected_type,
                                                  gAutoCompleteResults.expected_rt,
                                                  gAutoCompleteResults.expected_name,
                                                  gAutoCompleteResults.visited);
         if (!symbolsStatus && status < 0) symbolsStatus = status;
         if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
         if (length(prefix) < length(lastid) && !_CheckTimeout()) {
            gAutoCompleteResults.visited._makeempty();
            status = AutoCompleteGetCompatibleValues(errorArgs,
                                                     auto_complete_options,
                                                     forceUpdate,
                                                     prefix, p_EmbeddedCaseSensitive,
                                                     gAutoCompleteResults.idexp_info,
                                                     gAutoCompleteResults.expected_type,
                                                     gAutoCompleteResults.expected_rt,
                                                     gAutoCompleteResults.expected_name,
                                                     gAutoCompleteResults.visited);
            if (!symbolsStatus && status < 0) symbolsStatus = status;
            if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
         }

         // check if we are invoking strict case-sensitivity rules
         strictCaseSensitivity := false;
         if (forceUpdate) {
            strictCaseSensitivity = (_GetCodehelpFlags() & VSCODEHELPFLAG_LIST_MEMBERS_CASE_SENSITIVE) != 0;
         } else {
            strictCaseSensitivity = !(auto_complete_options & AUTO_COMPLETE_NO_STRICT_CASE);
         }

         if (p_EmbeddedCaseSensitive && !strictCaseSensitivity) {
            gAutoCompleteResults.visited._makeempty();
            status = AutoCompleteGetCompatibleValues(errorArgs,
                                                     auto_complete_options,
                                                     forceUpdate,
                                                     lastid, false,
                                                     gAutoCompleteResults.idexp_info,
                                                     gAutoCompleteResults.expected_type,
                                                     gAutoCompleteResults.expected_rt,
                                                     gAutoCompleteResults.expected_name,
                                                     gAutoCompleteResults.visited);
            if (!symbolsStatus && status < 0) symbolsStatus = status;
            if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
            if (length(prefix) < length(lastid) && !_CheckTimeout()) {
               gAutoCompleteResults.visited._makeempty();
               status = AutoCompleteGetCompatibleValues(errorArgs,
                                                        auto_complete_options,
                                                        forceUpdate,
                                                        prefix, false,
                                                        gAutoCompleteResults.idexp_info,
                                                        gAutoCompleteResults.expected_type,
                                                        gAutoCompleteResults.expected_rt,
                                                        gAutoCompleteResults.expected_name,
                                                        gAutoCompleteResults.visited);
               if (!symbolsStatus && status < 0) symbolsStatus = status;
               if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
            }
         }
         if (!prefixMatch && length(prefix) > 0 && 
             origForceUpdate && isListSymbols && !_CheckTimeout()) {
            gAutoCompleteResults.visited._makeempty();
            status = AutoCompleteGetCompatibleValues(errorArgs,
                                                     auto_complete_options,
                                                     forceUpdate,
                                                     "", p_EmbeddedCaseSensitive,
                                                     gAutoCompleteResults.idexp_info,
                                                     gAutoCompleteResults.expected_type,
                                                     gAutoCompleteResults.expected_rt,
                                                     gAutoCompleteResults.expected_name,
                                                     gAutoCompleteResults.visited);
            if (!symbolsStatus && status < 0) symbolsStatus = status;
            if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
         }
         if (wasActive) {
            gAutoCompleteResults.editor.p_ModifyFlags&= ~FAKEOUT_MODIFY_FLAGS;
            gAutoCompleteResults.editor.p_ModifyFlags|= orig_flag;
         }

         // need to have categories turned on for auto-list complatible symbols to work.
         // Otherwise, they will be mixed together with everything else.
         if ( !(auto_complete_options & AUTO_COMPLETE_SHOW_CATEGORIES) && 
              (gAutoCompleteResults.words._length() > 0) ) {
            gAutoCompleteResults.doShowCategories=true;
         }
      }
   }

   // Look for symbols matching the current prefix
   if (_istagging_supported() && !_CheckTimeout() && gAutoCompleteResults.idexp_info != null) {

      auto_complete_subword_option := AutoCompleteGetSubwordPatternOption(p_LangId);
      lastid := gAutoCompleteResults.idexp_info.lastid;
      start_col := gAutoCompleteResults.idexp_info.lastidstart_col;
      lastid_prefix := gAutoCompleteResults.prefix;
      if (p_col > start_col) lastid_prefix = substr(lastid,1,p_col-start_col);
      orig_flag := gAutoCompleteResults.editor.p_ModifyFlags&FAKEOUT_MODIFY_FLAGS;
      if (wasActive) {
         gAutoCompleteResults.editor.p_ModifyFlags |= FAKEOUT_MODIFY_FLAGS;
      }
      if (_chdebug) {
         say("AutoCompleteUpdateInfo: GET SYMBOLS lastid="lastid" lastid_prefix="lastid_prefix);
      }

      num_symbols := 0;
      max_symbols := def_auto_complete_max_symbols;
      if (operatorTyped) max_symbols = def_tag_max_list_matches_symbols;
      if (forceUpdate) max_symbols = def_tag_max_list_members_symbols;
      if (idexp_info.prefixexp == "") {
         // Local variables
         if (auto_complete_options & AUTO_COMPLETE_LOCALS) {
            _UpdateContextAndTokens(true,forceUpdate);
            _UpdateLocals(true);
            status = AutoCompleteGetAllSymbols(errorArgs,
                                               auto_complete_options,
                                               auto_complete_subword_option,
                                               forceUpdate || isListSymbols,
                                               lastid, lastid_prefix, 
                                               !prefixMatch && origForceUpdate && isListSymbols,
                                               p_EmbeddedCaseSensitive,
                                               SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_CONTEXT_ONLY_LOCALS,
                                               AUTO_COMPLETE_LOCALS_PRIORITY,
                                               gAutoCompleteResults.idexp_info,
                                               num_symbols, max_symbols,
                                               gAutoCompleteResults.visited, 1);
            if (_chdebug) {
               say("AutoCompleteUpdateInfo H"__LINE__": LOCALS status="status" gAutoCompleteResults.words.length="gAutoCompleteResults.words._length());
            }
            if (!symbolsStatus && status < 0) symbolsStatus = status;
            if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
         }
         // Members of the current class
         if (auto_complete_options & AUTO_COMPLETE_MEMBERS) {
            status = AutoCompleteGetAllSymbols(errorArgs,
                                               auto_complete_options,
                                               auto_complete_subword_option,
                                               forceUpdate || isListSymbols,
                                               lastid, lastid_prefix, 
                                               !prefixMatch && origForceUpdate && isListSymbols,
                                               p_EmbeddedCaseSensitive,
                                               SE_TAG_CONTEXT_ONLY_INCLASS|SE_TAG_CONTEXT_NO_GLOBALS,
                                               AUTO_COMPLETE_MEMBERS_PRIORITY,
                                               gAutoCompleteResults.idexp_info,
                                               num_symbols, max_symbols,
                                               gAutoCompleteResults.visited, 1);
            if (_chdebug) {
               say("AutoCompleteUpdateInfo H"__LINE__": MEMBERS status="status" gAutoCompleteResults.words.length="gAutoCompleteResults.words._length());
            }
            if (!symbolsStatus && status < 0) symbolsStatus = status;
            if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
         }
         // Current file
         if (auto_complete_options & AUTO_COMPLETE_CURRENT_FILE) {
            status = AutoCompleteGetAllSymbols(errorArgs,
                                               auto_complete_options,
                                               auto_complete_subword_option,
                                               forceUpdate || isListSymbols,
                                               lastid, lastid_prefix, 
                                               !prefixMatch && origForceUpdate && isListSymbols,
                                               p_EmbeddedCaseSensitive,
                                               SE_TAG_CONTEXT_ONLY_THIS_FILE|SE_TAG_CONTEXT_ONLY_CONTEXT,
                                               AUTO_COMPLETE_CURRENT_FILE_PRIORITY,
                                               gAutoCompleteResults.idexp_info,
                                               num_symbols, max_symbols,
                                               gAutoCompleteResults.visited, 1);
            if (_chdebug) {
               say("AutoCompleteUpdateInfo H"__LINE__": CURRENT FILE status="status" gAutoCompleteResults.words.length="gAutoCompleteResults.words._length());
            }
            if (!symbolsStatus && status < 0) symbolsStatus = status;
            if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
         }
      }

      if (auto_complete_options & AUTO_COMPLETE_SYMBOLS) {
         status = AutoCompleteGetAllSymbols(errorArgs,
                                            auto_complete_options,
                                            auto_complete_subword_option,
                                            forceUpdate || isListSymbols,
                                            lastid, lastid_prefix,
                                            !prefixMatch && origForceUpdate && isListSymbols,
                                            p_EmbeddedCaseSensitive,
                                            SE_TAG_CONTEXT_ALLOW_LOCALS,
                                            AUTO_COMPLETE_SYMBOL_PRIORITY,
                                            gAutoCompleteResults.idexp_info,
                                            num_symbols, max_symbols,
                                            gAutoCompleteResults.visited, 1);
         if (_chdebug) {
            say("AutoCompleteUpdateInfo H"__LINE__": SYMBOLS status="status" gAutoCompleteResults.words.length="gAutoCompleteResults.words._length());
         }
         if (!symbolsStatus && status < 0) symbolsStatus = status;
         if (!status && symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) symbolsStatus=0;
      }
      if (wasActive) {
         gAutoCompleteResults.editor.p_ModifyFlags&= ~FAKEOUT_MODIFY_FLAGS;
         gAutoCompleteResults.editor.p_ModifyFlags|= orig_flag;
      }
      if (_chdebug) {
         say("AutoCompleteUpdateInfo: GET SYMBOLS num="num_symbols" max="max_symbols);
      }
   }

   // Look for complete-list matches
   if ((auto_complete_options & AUTO_COMPLETE_WORDS) && !_CheckTimeout()) {
      prefixexp := "";
      if (gAutoCompleteResults.idexp_info != null && gAutoCompleteResults.idexp_info.prefixexp != null) {
         prefixexp = gAutoCompleteResults.idexp_info.prefixexp;
      }
      AutoCompleteGetWordCompletions(auto_complete_options, prefixexp, forceUpdate);
   }

   // look for extension specific auto complete arguments
   if ((auto_complete_options & AUTO_COMPLETE_LANGUAGE_ARGS) && !_CheckTimeout()) {
      AutoCompleteGetLanguageSpecificArguments(auto_complete_options, forceUpdate);
   }

   // did we run out of time?
   ranOutOfTime := (_CheckTimeout() != 0);

   // we may have "no symbols found" error because of the timeout
   if (ranOutOfTime && 
       gAutoCompleteResults.words._length() > 0 && 
       symbolsStatus == VSCODEHELPRC_NO_SYMBOLS_FOUND) {
      symbolsStatus = VSCODEHELPRC_LIST_MEMBERS_TIMEOUT;
   }

   // did we get any results?
   if (gAutoCompleteResults.words._length() == 0 || 
       (!forceUpdate && !isListSymbols && ranOutOfTime && 
        symbolsStatus != VSCODEHELPRC_LIST_MEMBERS_LIMITED &&
        symbolsStatus != VSCODEHELPRC_LIST_MEMBERS_TIMEOUT)) {
      if (embedded == 1) {
         _EmbeddedEnd(orig_values);
      }
      AutoCompleteTerminate();
      //say("AutoCompleteUpdateInfo: NO MATCHES");
      if (symbolsStatus < 0) {
         if (_chdebug) {
            say("AutoCompleteUpdateInfo: SYMBOL ERROR status="symbolsStatus);
         }
         return symbolsStatus;
      }
      errorArgs[1] = gAutoCompleteResults.prefix;
      if (_chdebug) {
         say("AutoCompleteUpdateInfo: NO COMPLETIONS FOUND");
      }
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // did the user complete the entire match
   foundExactMatch := gAutoCompleteResults.foundExactMatch;
   if (foundExactMatch && !ranOutOfTime && !forceUpdate &&
       !isListSymbols && gAutoCompleteResults.idexp_info != null) {
      AUTO_COMPLETE_INFO ac = gAutoCompleteResults.words[0];
      if (ac.insertWord == gAutoCompleteResults.idexp_info.lastid) {
         AutoCompleteTerminate();
         //say("AutoCompleteUpdateInfo: FOUND EXACT MATCH TO WHAT WAS TYPED");
         if (embedded == 1) {
            _EmbeddedEnd(orig_values);
         }
         return 0;
      }
   }

   // if we found one exact syntax expansion match
   // allow AUTO_COMPLETE_UNIQUE to highlight it
   if (foundExactMatch && !ranOutOfTime && gAutoCompleteResults.words._length()==1) {
      AUTO_COMPLETE_INFO ac = gAutoCompleteResults.words[0];
      if (ac.displayWord != ac.insertWord) {
         foundExactMatch=false;
      }
   }

   // is there exactly one match?
   if (!foundExactMatch && !ranOutOfTime && 
       (auto_complete_options & AUTO_COMPLETE_UNIQUE) && 
       (auto_complete_options & AUTO_COMPLETE_NO_INSERT_SELECTED)) {
      _str word_0 = gAutoCompleteResults.words[0].insertWord;
      n := gAutoCompleteResults.words._length();
      for (i:=0; i<n; ++i) {
         if (gAutoCompleteResults.words[i].insertWord != word_0) {
            word_0 = "";
            break;
         }
      }
      if (word_0 != "") {
         gAutoCompleteResults.wordIndex = 0;
         gAutoCompleteResults.allowImplicitReplace = true;
         gAutoCompleteResults.allowShowInfo = true;
         selectMatchingItem = true;
      }
   }

   // check if we are invoking strict case-sensitivity rules
   // it depends on the situation in which we were invoked
   strictCaseSensitivity := p_EmbeddedCaseSensitive;
   if (gAutoCompleteResults.wasListSymbols) {
      strictCaseSensitivity = (_GetCodehelpFlags() & VSCODEHELPFLAG_LIST_MEMBERS_CASE_SENSITIVE) != 0;
   } else if (forceUpdate) {
      strictCaseSensitivity = (_GetCodehelpFlags() & VSCODEHELPFLAG_IDENTIFIER_CASE_SENSITIVE) != 0;
   } else {
      strictCaseSensitivity = !(AutoCompleteGetOptions() & AUTO_COMPLETE_NO_STRICT_CASE);
   }

   // if they forced list-symbols and found an exact match
   // then go ahead and select the symbol match.
   if (forceUpdate && selectMatchingItem &&
       isListSymbols && gAutoCompleteResults.idexp_info != null) {
      lastid := gAutoCompleteResults.idexp_info.lastid;
      n := gAutoCompleteResults.words._length();
      for (i:=0; i<n; ++i) {
         if (gAutoCompleteResults.words[i].insertWord == lastid) {
            gAutoCompleteResults.wordIndex = i;
            gAutoCompleteResults.allowImplicitReplace=selectMatchingItem;
            gAutoCompleteResults.allowShowInfo=selectMatchingItem;
            foundExactMatch = true;
            if (_chdebug) {
               say("AutoCompleteUpdateInfo H"__LINE__": found case-sensitive exact match at index: "i" word="gAutoCompleteResults.words[i].insertWord);
            }
            break;
         }
      }
      // try again, case-insensitive
      if (i >= n && !strictCaseSensitivity) {
         for (i=0; i<n; ++i) {
            if (strieq(gAutoCompleteResults.words[i].insertWord, lastid)) {
               gAutoCompleteResults.wordIndex = i;
               gAutoCompleteResults.allowImplicitReplace=selectMatchingItem;
               gAutoCompleteResults.allowShowInfo=selectMatchingItem;
               foundExactMatch = true;
               if (_chdebug) {
                  say("AutoCompleteUpdateInfo H"__LINE__": found case-insensitive exact match at index: "i" word="gAutoCompleteResults.words[i].insertWord);
               }
               break;
            }
         }
      }
   }

   // if there wasn't an exact match, but they forced list symbols, try to select a match
   if (!foundExactMatch && forceUpdate && isListSymbols && gAutoCompleteResults.idexp_info != null) {

      lastid := gAutoCompleteResults.idexp_info.lastid;
      n := gAutoCompleteResults.words._length();
      for (i:=0; i<n; ++i) {
         if (pos(lastid, gAutoCompleteResults.words[i].insertWord) == 1) {
            gAutoCompleteResults.wordIndex = i;
            gAutoCompleteResults.allowImplicitReplace=selectMatchingItem;
            gAutoCompleteResults.allowShowInfo=selectMatchingItem;
            if (_chdebug) {
               say("AutoCompleteUpdateInfo H"__LINE__": found case-sensitive prefix match for whole word at index: "i" word="gAutoCompleteResults.words[i].insertWord);
            }
            break;
         }
      }
      // try again, case-insensitive
      if (i >= n && !strictCaseSensitivity) {
         for (i=0; i<n; ++i) {
            if (pos(lastid, gAutoCompleteResults.words[i].insertWord,1,'i') == 1) {
               gAutoCompleteResults.wordIndex = i;
               gAutoCompleteResults.allowImplicitReplace=selectMatchingItem;
               gAutoCompleteResults.allowShowInfo=selectMatchingItem;
               if (_chdebug) {
                  say("AutoCompleteUpdateInfo H"__LINE__": found case-insensitive prefix match for whole word at index: "i" word="gAutoCompleteResults.words[i].insertWord);
               }
               break;
            }
         }
      }
      // if we can't find a word match, try to find a prefix match
      prefix := gAutoCompleteResults.prefix;
      if (gAutoCompleteResults.wordIndex < 0 && prefix != lastid) {
         for (i=0; i<n; ++i) {
            if (pos(prefix, gAutoCompleteResults.words[i].insertWord) == 1) {
               gAutoCompleteResults.wordIndex = i;
               gAutoCompleteResults.allowImplicitReplace=selectMatchingItem;
               gAutoCompleteResults.allowShowInfo=selectMatchingItem;
               if (_chdebug) {
                  say("AutoCompleteUpdateInfo H"__LINE__": found case-sensitive prefix match at index: "i" word="gAutoCompleteResults.words[i].insertWord);
               }
               break;
            }
         }
         // try again, case-insensitive
         if (i >= n && !strictCaseSensitivity) {
            for (i=0; i<n; ++i) {
               if (pos(prefix, gAutoCompleteResults.words[i].insertWord,1,'i') == 1) {
                  gAutoCompleteResults.wordIndex = i;
                  gAutoCompleteResults.allowImplicitReplace=selectMatchingItem;
                  gAutoCompleteResults.allowShowInfo=selectMatchingItem;
                  if (_chdebug) {
                     say("AutoCompleteUpdateInfo H"__LINE__": found case-insensitive prefix match at index: "i" word="gAutoCompleteResults.words[i].insertWord);
                  }
                  break;
               }
            }
         }
      }
   }

   // check how many unique completions are available.
   options := AutoCompleteGetOptions(p_LangId);
   if (doInsertLongest && !ranOutOfTime && gAutoCompleteResults.allowInsertLongest) {
      bool uniqueWords:[];
      n := gAutoCompleteResults.words._length();
      for (i:=0; i<n; ++i) {
         uniqueWords:[gAutoCompleteResults.words[i].insertWord] = true;
      }
      if (AutoCompleteInsertLongestPrefix() && uniqueWords._length() == 1) {
         AutoCompleteTerminate();
         //say("AutoCompleteUpdateInfo H"__LINE__": INSERTED LONGEST PREFIX");
         if (embedded == 1) {
            _EmbeddedEnd(orig_values);
         }
         return 0;
      }
   }

   // Now set up the auto complete GUI with our results
   gAutoCompleteResults.ignoreSwitchBufAndModuleLoadEvents = false;
   gAutoCompleteResults.maybeRestartListParametersAfterKey = false;
   gAutoCompleteResults.isActive = true;
   AutoCompleteShowList(isListSymbols);
   AutoCompleteShowInfo();
   AutoCompleteStartTimer();
   refresh();

   // clean up and return
   if (embedded == 1) {
      _EmbeddedEnd(orig_values);
   }
   p_window_id = orig_wid;

   // notify the use that auto-list members or auto-list parameters/values happened
   if (!wasActive && isListSymbols && operatorTyped) {
      if ((expected_type != null && expected_type != "") || (expected_rt != null)) {
         if (ParameterHelpActive()) {
            notifyUserOfFeatureUse(NF_AUTO_LIST_COMPATIBLE_PARAMS);
         } else {
            notifyUserOfFeatureUse(NF_AUTO_LIST_COMPATIBLE_VALUES);
         }
      } else {
         notifyUserOfFeatureUse(NF_AUTO_LIST_MEMBERS);
      }
   }
   if (!wasActive && isListSymbols && !operatorTyped && doListParameters) {
      notifyUserOfFeatureUse(NF_AUTO_LIST_COMPATIBLE_PARAMS);
   }

   //say("AutoCompleteUpdateInfo: FINISHED");
   if (symbolsStatus < 0) {
      return symbolsStatus;
   }
   return 0;
}

/**
 * @return 
 * Return 'true' if a symbol completion or list symbols command was repeated. 
 */
bool AutoCompleteCommandRepeated()
{
   // check if this is our first try or second try at this
   last_name := name_name(prev_index('','C'));
   switch (last_name) {
   case "autocomplete":
   case "codehelp-complete":
   case "codehelp-autocomplete":
   case "codehelp-trace-autocomplete":
   case "codehelp-trace-complete":
   case "codehelp-trace-list-symbols":
   case "list-symbols":
      return true;
   }
   return false;
}

/**
 * Update auto complete information on demand.  Note that normally,
 * invocation of auto complete mode happens automatically.
 * <p>
 * Automatic completion provides a comprehensive system to tie together
 * many of the most important features of SlickEdit into one consistent
 * framework.  Automatic completion works by dynamically suggesting completion
 * possibilities when they are discovered, and providing a one key solution
 * for selecting to perform the auto-completion, when is then executed as
 * if the specific command had actually been typed.
 * <p>
 * This frees the user from having to remember the key combination
 * associated with various completion mechanisms, all they really need
 * to remember is Space key.  And if they are an advanced user, they also
 * can use Ctrl+Shift+Space to incrementally pull in part of an auto
 * completion.
 * <p>
 * The features pulled into this system include:
 * <ul>
 * <li>Language specific syntax expansion
 * <li>Alias expansion
 * <li>Symbol completion using tagging
 * <li>Complete prev/next matches
 * <li>Command line history
 * <li>Command argument completion
 * <li>Text box dialog completion
 * </ul>
 * <p>
 * For the text box and combo box controls, this same system supplements
 * the existing completion mechanisms by providing a dynamic system for
 * displaying the matches, much like that used by the Windows file chooser.
 * <p>
 * For the SlickEdit command line, this system supplements command history
 * as well as command argument completion using the same display mechanism.
 *
 * @see c_space
 * @see expand_alias
 * @see codehelp_complete
 * @see complete_next
 * @see complete_prev
 * @see file_match
 * @see tag_match
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Completion_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command int autocomplete() name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   index := last_index('','C');
   prev := prev_index('','C');

   if (AutoCompleteActive() && AutoCompleteRunCommand()) {
      last_index(index,'C');
      prev_index(prev,'C');
      return 0;
   }
   _str errorArgs[];
   status := AutoCompleteUpdateInfo(alwaysUpdate:true,
                                    forceUpdate:true,
                                    doInsertLongest:true,
                                    operatorTyped:false,
                                    prefixMatch:true,
                                    idexp_info:null,
                                    expected_type:null,
                                    expected_rt:null,
                                    expected_name:null,
                                    selectMatchingItem:false,
                                    doListParameters:false,
                                    isFirstAttempt: !AutoCompleteCommandRepeated(),
                                    errorArgs);
   if (status < 0) {
      msg := _CodeHelpRC(status,errorArgs);
      message(msg);
   }

   last_index(index,'C');
   prev_index(prev,'C');
   return status;
}
_command int codehelp_trace_autocomplete(_str force="") name_info(','VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   index := last_index('','C');
   prev := prev_index('','C');

   if (AutoCompleteActive() && AutoCompleteRunCommand()) {
      last_index(index,'C');
      prev_index(prev,'C');
      return 0;
   }

   orig_chdebug := _chdebug;
   _chdebug = 1;
   _str errorArgs[];
   status := AutoCompleteUpdateInfo(alwaysUpdate:true,
                                    forceUpdate: (force!=""),
                                    doInsertLongest:true,
                                    operatorTyped:false,
                                    prefixMatch:true,
                                    idexp_info:null,
                                    expected_type:null,
                                    expected_rt:null,
                                    expected_name:null,
                                    selectMatchingItem:false,
                                    doListParameters:false,
                                    isFirstAttempt: !AutoCompleteCommandRepeated(),
                                    errorArgs);
   _chdebug = orig_chdebug;
   if (status < 0) {
      msg := _CodeHelpRC(status,errorArgs);
      message(msg);
   }

   last_index(index,'C');
   prev_index(prev,'C');
   return status;
}

/**
 * @return Returns the name of the autocomplete function pointer function 
 */
static _str AutoCompleteGetReplaceWordFunctionName(typeless fp)
{
   if (fp == null) return "";
   if (fp == _autocomplete_space)         return "_autocomplete_space";
   if (fp == _autocomplete_expand_alias)  return "_autocomplete_expand_alias";
   if (fp == _autocomplete_process)       return "_autocomplete_process";
   if (fp == _autocomplete_prev)          return "_autocomplete_prev";
   if (fp == _autocomplete_next)          return "_autocomplete_next";
   if (_isfunptr(fp)) {
      if (substr((_str)fp, 1, 1) :== "&") {
         int index = (int)substr((_str)fp, 2);
         if (name_type(index) == PROC_TYPE) {
            return translate(name_name(index), "_", "-");
         }
      }
   }
   return "";
}

/**
 * Perform the command suggested by the auto completion
 */
bool AutoCompleteRunCommand(_str terminationKey="")
{
   // make sure completion results are active
   if (!AutoCompleteActive()) {
      return false;
   }

   // if the termination key was not space, tab, or enter, then
   // do not replace the word.
   if (!gAutoCompleteResults.allowImplicitReplace &&
       terminationKey :!= " " && terminationKey :!= "\t" && terminationKey :!= ENTER) {
      return false;
   }

   // make sure that the editor is still ready to go
   editorctl_wid := AutoCompleteGetEditorWid();
   if (!_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl() ||
       gAutoCompleteResults.lineoffset != editorctl_wid.point() ||
       gAutoCompleteResults.column != editorctl_wid.p_col ||
       gAutoCompleteResults.buffer != editorctl_wid.p_buf_id ) {
      return false;
   }

   // make sure the current item selected is valid
   word_index := gAutoCompleteResults.wordIndex;
   if (word_index < 0 || word_index >= gAutoCompleteResults.words._length()) {
      return false;
   }

   // save the original window ID and make the editor current
   orig_wid := p_window_id;
   p_window_id = editorctl_wid;

   // start embedded mode
   typeless orig_values;
   int embedded = _EmbeddedStart(orig_values);

   // look up callback for replacing symbols (before and after)
   void (*pfnBeforeReplaceAction)(AUTO_COMPLETE_INFO &word, VS_TAG_IDEXP_INFO &idexp_info, _str terminationKey) = null;
   index := _FindLanguageCallbackIndex("_%s_autocomplete_before_replace", p_LangId);
   if (index > 0) {
      pfnBeforeReplaceAction = name_index2funptr(index);
   }
   bool (*pfnAfterReplaceAction)(AUTO_COMPLETE_INFO &word, VS_TAG_IDEXP_INFO &idexp_info, _str terminationKey) = null;
   index = _FindLanguageCallbackIndex("_%s_autocomplete_after_replace", p_LangId);
   if (index > 0) {
      pfnAfterReplaceAction = name_index2funptr(index);
   }

   // replace the prefix with the selected word
   word := gAutoCompleteResults.words[word_index];
   prefix := gAutoCompleteResults.prefix;
   idexp_info := gAutoCompleteResults.idexp_info;
   if (pfnBeforeReplaceAction != null && word.symbol != null) {
      (*pfnBeforeReplaceAction)(word, idexp_info, terminationKey);
   }
   AutoCompleteReplaceWordForEachMultiCursor(word.pfnReplaceWord, prefix, word.insertWord, false, word.symbol);
   AutoCompleteTerminate();

   // call language specific post-processing function
   doDefaultActions := true;
   if (pfnAfterReplaceAction != null && word.symbol != null) {
      doDefaultActions = (*pfnAfterReplaceAction)(word, idexp_info, terminationKey);
   }

   // call generic function to deal with jumping into function arg help
   doBeautify := true;
   if (doDefaultActions && AutoCompleteWordIsSymbol(word)) {

      // if option to insert an open paren for functions is enabled
      if (_GetCodehelpFlags() & VSCODEHELPFLAG_INSERT_OPEN_PAREN) {
         // and the termination key is space or tab or enter
         if (terminationKey=="" || terminationKey==TAB || terminationKey==ENTER) {
            // and we aren't in some crazy special case
            info_flags := (idexp_info != null)? idexp_info.info_flags : 0;
            if (!(info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) &&
                !(info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN)) {
               // and this genuinely is a function type
               if (tag_tree_type_is_func(word.symbol.type_name) &&
                   word.symbol.type_name != "selector" && 
                   word.symbol.type_name != "staticselector" &&
                   idexp_info.otherinfo != "@selector") {
                  // does this caption have a parenthesis? (is it a function?)
                  caption := tag_make_caption_from_browse_info(word.symbol, include_class:true, include_args:false, include_tab:false);
                  if (pos("(", caption)) {
                     // if we have an open paren, then insert open paren and go directly
                     // into function help, unless name is already followed by a paren.
                     // kind of language specific...
                     last_event("(");
                     auto_functionhelp_key();
                     doBeautify = false;
                  }
               }
            }
         }
      }

      // generic handling for quotes, parens, and braces as insertions
      if (word.insertWord == "\"\"" || 
          word.insertWord == "''" || 
          word.insertWord == "``" || 
          word.insertWord == "()" || 
          word.insertWord == "[]") {
         if (get_text(2, (int)_QROffset()-2) == word.insertWord) {
            p_col -= 2;
            _delete_text(2);
            if (!AutoBracketKeyin(_first_char(word.insertWord))) {
               keyin(_last_char(word.insertWord));
            }
         }
      }
   }

   // get out of embedded language mode
   if (embedded == 1) {
      _EmbeddedEnd(orig_values);
   }

   // we did it!
   if (_iswindow_valid(orig_wid)) {
      p_window_id = orig_wid;
   }

   if (doBeautify && beautify_alias_expansion(p_LangId)) {
      long markers[];

      save_pos(auto pp);
      p_col=1;
      low := _QROffset();
      _end_line();
      high := _QROffset();
      restore_pos(pp);

      bflags := BEAUT_FLAG_TYPING|BEAUT_FLAG_COMPLETION;
      if (high > low) {
         if (should_beautify_range(low, high, bflags)) {
            if (!_macro('S')) {
               _undo('S');
            }

            new_beautify_range(low, high, markers, true, false, false, bflags);
         }
      }
   }

   return true;
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Get the auto complete options wich are a bitset of
 * <code>AUTO_COMPLETE_*</code>.
 * <p>
 * The options are stored per extension type.  If the options
 * are not yet defined for an extension, then use
 * <code>def_auto_complete_options</code> as the default.
 *
 * @param lang    language ID -- see {@link p_LangId}
 *
 * @return bitset of AUTO_COMPLETE_* options.
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Completion_Functions
 */
AutoCompleteFlags AutoCompleteGetOptions(_str lang="")
{
   if (lang=="") {
      editorctl_wid := AutoCompleteGetEditorWid();
      if (_iswindow_valid(editorctl_wid) && editorctl_wid._isEditorCtl()) {
         lang = editorctl_wid.p_LangId;
      } else if (_isEditorCtl()) {
         lang = p_LangId;
      } else {
         return def_auto_complete_options;
      }
   }

   return (AutoCompleteFlags)LanguageSettings.getAutoCompleteOptions(lang, def_auto_complete_options);
}
static AutoCompleteFlags AutoCompleteGetOptionsMaybeShowCategories(_str lang="")
{
   auto_complete_options := AutoCompleteGetOptions(lang);
   if ( gAutoCompleteResults.doShowCategories ) {
      auto_complete_options |= AUTO_COMPLETE_SHOW_CATEGORIES;
   }
   return auto_complete_options;
}
/**
 * Set the auto complete options wich are a bitset of
 * <code>AUTO_COMPLETE_*</code>.
 * <p>
 * The options are stored per extension type using
 * <code>def_autocomplete_[ext]</code>.
 *
 * @param lang    language ID -- see {@link p_LangId}
 * @param flags   bitset of AUTO_COMPLETE_* options
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Completion_Functions
 */
void AutoCompleteSetOptions(_str lang, AutoCompleteFlags flags)
{
   LanguageSettings.setAutoCompleteOptions(lang, flags);
}

/**
 * Get the minimum length identifier prefix that will
 * allow auto complete to be triggered.  This is closely
 * related to the mimimum expandable keyword length common
 * to most language specific syntax expansion options.
 * <p>
 * This settings is stored per extension type.  If the options
 * are not yet defined for an extension, then use
 * <code>def_auto_complete_minimum_length</code> as the default.
 *
 * @param lang    language ID -- see {@link p_LangId}
 *
 * @return minimum length setting
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Completion_Functions
 */
int AutoCompleteGetMinimumLength(_str lang)
{
   if (lang=="" && _isEditorCtl()) {
      lang = p_LangId;
   }

   return LanguageSettings.getAutoCompleteMinimumLength(lang);
}
/**
 * Get the minimum length identifier prefix that will
 * allow auto complete to be triggered.  This is closely
 * related to the mimimum expandable keyword length common
 * to most language specific syntax expansion options.
 * <p>
 * This settings is stored per extension type.  If the options
 * are not yet defined for an extension, then use
 * <code>def_auto_complete_minimum_length</code> as the default.
 *
 * @param lang    language ID -- see {@link p_LangId}
 * @param min     minimum prefix length
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Completion_Functions
 */
void AutoCompleteSetMinimumLength(_str lang, int min)
{
   LanguageSettings.setAutoCompleteMinimumLength(lang, min);
}

/** 
 * @return 
 * Gets setting specifying how Auto-Complete looks for subword pattern matches.
 *
 * @param lang    language ID -- see {@link p_LangId}
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Completion_Functions
 */
AutoCompleteSubwordPattern AutoCompleteGetSubwordPatternOption(_str lang)
{
   if (lang=="" && _isEditorCtl()) {
      lang = p_LangId;
   }

   return LanguageSettings.getAutoCompleteSubwordPatternOption(lang);
}
/** 
 * @return 
 * Translates auto-complete subword completion strategy setting to context 
 * tagging flags to pass to context tagging related functions.
 *
 * @param lang    language ID -- see {@link p_LangId}
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * @categories Completion_Functions
 */
SETagContextFlags AutoCompleteGetSubwordPatternFlags(_str lang)
{
   if (lang=="" && _isEditorCtl()) {
      lang = p_LangId;
   }

   subword_option := LanguageSettings.getAutoCompleteSubwordPatternOption(lang);
   switch (subword_option) {
   case AUTO_COMPLETE_SUBWORD_MATCH_NONE:          return SE_TAG_CONTEXT_MATCH_PREFIX;
   case AUTO_COMPLETE_SUBWORD_MATCH_STSK_SUBWORD:  return SE_TAG_CONTEXT_MATCH_STSK_SUBWORD;
   case AUTO_COMPLETE_SUBWORD_MATCH_STSK_ACRONYM:  return SE_TAG_CONTEXT_MATCH_STSK_ACRONYM;
   case AUTO_COMPLETE_SUBWORD_MATCH_STSK_PURE:     return SE_TAG_CONTEXT_MATCH_STSK_PURE;
   case AUTO_COMPLETE_SUBWORD_MATCH_SUBSTRING:     return SE_TAG_CONTEXT_MATCH_SUBSTRING;
   case AUTO_COMPLETE_SUBWORD_MATCH_SUBWORD:       return SE_TAG_CONTEXT_MATCH_SUBWORD;
   case AUTO_COMPLETE_SUBWORD_MATCH_CHAR_BITSET:   return SE_TAG_CONTEXT_MATCH_CHAR_BITSET;
   }
   return SE_TAG_CONTEXT_MATCH_PREFIX;
}

///////////////////////////////////////////////////////////////////////////////

// returns 0 if there were not overloaded tags to cycle through
// otherwise, return "inc" on success.
static int AutoCompleteNextComment(int inc)
{
   VSAUTOCODE_ARG_INFO (*plist)[];
   _nocheck _control ctlminihtml1;
   form_wid := gAutoCompleteResults.commentForm;
   if (!_iswindow_valid(form_wid)) {
      return 0;
   }

   prefer_left_placement := false;
   list_wid := gAutoCompleteResults.listForm;
   if (_iswindow_valid(list_wid) && form_wid.p_x < list_wid.p_x) {
      prefer_left_placement = true;
   }
   
   TagIndex := 0;
   HYPERTEXTSTACK stack = form_wid.ctlminihtml1.p_user;
   if (stack.HyperTextTop>=0) {
      TagIndex=stack.s[stack.HyperTextTop].TagIndex;
      plist= &stack.s[stack.HyperTextTop].TagList;
   }

   int orig_TagIndex=TagIndex;
   TagIndex+=inc;
   if (TagIndex<0 && plist->_length() > 0) {
      TagIndex=plist->_length()-1;
   } else if (TagIndex>=plist->_length()) {
      TagIndex=0;
   }
   if (TagIndex!=orig_TagIndex) {
      if (stack.HyperTextTop>=0) {
         stack.s[stack.HyperTextTop].TagIndex=TagIndex;
         form_wid.ctlminihtml1.p_user=stack;
      } else {
         //gFunctionHelpTagIndex=TagIndex;
      }
      form_wid.ShowCommentHelp(doFunctionHelp:false, 
                               prefer_left_placement:true,
                               form_wid, 
                               AutoCompleteGetEditorWid(),
                               do_not_move_form:false, 
                               gAutoCompleteResults.visited);
   }
   return 0;
}

/**
 * Callback for handling keypresses during auto complete mode.
 * This function passes through to the default key mappings
 * for handling one key press.
 * <p>
 * NOTE: If 'key' is bound to a macro that closes the current
 * window and leaves focus in another window, especially one
 * that is not an editor control, and the window ID found in
 * <code>gAutoCompleteResults.editor</code> is recycled, we may
 * add the event tab back to the wrong window.
 *
 * @param key           key press
 * @param doTerminate   force auto complete to terminate
 */
static void AutoCompleteDefaultKey(_str key,
                                   bool doTerminate,
                                   bool called_from_AutoCompleteDoKey=true)
{
   last_index(prev_index("",'C'),'C');
   _RemoveEventtab(defeventtab auto_complete_key_overrides);

   if (doTerminate) {
      AutoCompleteTerminate();
      if (called_from_AutoCompleteDoKey && _macro('KI')) _macro('KK',key);
      maybe_dokey(key);
   } else {
      editorctl_wid := p_window_id;
      if (called_from_AutoCompleteDoKey && _macro('KI')) _macro('KK',key);
      maybe_dokey(key);
      if (_iswindow_valid(editorctl_wid) && AutoCompleteActive()) {
         editorctl_wid._AddEventtab(defeventtab auto_complete_key_overrides);
      }
   }
}
int _UTF8CharRead2OrMore(int i,_str &str,int &ch32) {
    int first = _asc(substr(str,i,1));
    if ((first & 0xe0) == 0xc0) { //110, 2 byte encoding
        if (i + 2 -1 > length(str)) {
            ch32 = -1;
            return 1;
        }
        // 5 bits of first byte and 6 bits from second byte
        ch32 = (((first & 0x1f)) << 6) | (_asc(substr(str,i+1,1)) & 0x3f);
        return 2;
    }
    if ((first & 0xf0) == 0xe0) { //1110, 3 byte encoding
        if (i + 3 -1 > length(str)) {
            ch32 = -1;
            return 1;
        }
        // 4 bits of first byte, 6 bits from second,6 bits from third
        ch32 = (((first & 0xf)) << 12) |
                (((_asc(substr(str,i+1,1)) & 0x3f)) << 6) |
                (((_asc(substr(str,i+2,1)) & 0x3f)));
        return 3;
    }
    if ((first & 0xf8) == 0xf0) { //11110, 4 byte encoding
        if (i + 4 -1 > length(str)) {
            ch32 = -1;
            return 1;
        }
        // 4 bits of first byte, 6 bits from second-forth
        ch32 = (((first & 0x7)) << 18) |
                (((_asc(substr(str,i+1,1)) & 0x3f)) << 12) |
                (((_asc(substr(str,i+2,1)) & 0x3f)) << 6) |
                (((_asc(substr(str,i+3,1)) & 0x3f)));
        return 4;
    }
    if ((first & 0xfc) == 0xf8) { //111110, 5 byte encoding
        if (i + 5 -1 > length(str)) {
            ch32 = -1;
            return 1;
        }
        // 4 bits of first byte, 6 bits from second-fifth
        ch32 = (((first & 0x3)) << 24) |
                (((_asc(substr(str,i+1,1)) & 0x3f)) << 18) |
                (((_asc(substr(str,i+2,1)) & 0x3f)) << 12) |
                (((_asc(substr(str,i+3,1)) & 0x3f)) << 6) |
                (((_asc(substr(str,i+4,1)) & 0x3f)));
        return 5;
    }
    if ((first & 0xfe) == 0xfc) { //1111110, 6 byte encoding
        if (i + 6 -1 > length(str)) {
            ch32 = -1;
            return 1;
        }
        // 4 bits of first byte, 6 bits from second-fifth
        ch32 = (((first & 0x1)) << 30) |
                (((_asc(substr(str,i+1,1)) & 0x3f)) << 24) |
                (((_asc(substr(str,i+2,1)) & 0x3f)) << 18) |
                (((_asc(substr(str,i+3,1)) & 0x3f)) << 12) |
                (((_asc(substr(str,i+4,1)) & 0x3f)) << 6) |
                (((_asc(substr(str,i+5,1)) & 0x3f)));
        return 6;
    }
    ch32 = -1;
    return 1;
}
int _UTF8CountChars(_str str) {
   i := 1;
   count := 0;
   for (;i<=length(str);++count) {
      ch := substr(str,i,1);
      if (_asc(ch)>=128) {
         auto len=_UTF8CharRead2OrMore(i,str,auto ch32);
         i+=len;
      } else {
         ++i;
      }
   }
   return count;
}
void _kbdmacro_add_string(_str str) {
   i := 1;
   for (;i<=length(str);) {
      ch := substr(str,i,1);
      if (_asc(ch)>=128) {
         auto len=_UTF8CharRead2OrMore(i,str,auto ch32);
         _macro('KK',_UTF8Chr(ch32));
         i+=len;
      } else {
         _macro('KK',ch);
         ++i;
      }
   }
}

static void AutoCompleteReplaceWordForEachMultiCursor(
   void (*pfnReplaceWord)(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol),
   _str prefix,
   _str insertWord,
   bool onlyInsertWord,
   struct VS_TAG_BROWSE_INFO symbol
   ) 
{
   target_wid := p_window_id;
   //activate_window(target_wid);
   already_looping := _MultiCursorAlreadyLooping();
   multicursor     := !already_looping && _MultiCursor();

   if (_QReadOnly()) {
      _readonly_error(0);
      return;
   }

   if (gAutoCompleteResults.origLineContent!=null) {
      replace_line(gAutoCompleteResults.origLineContent);
      p_col=gAutoCompleteResults.origCol;
      prefix=gAutoCompleteResults.origPrefix;
      gAutoCompleteResults.removeLen=0;
      gAutoCompleteResults.origLineContent=null;
   }

   for (ff:=true;;ff=false) {
      if (_MultiCursor()) {
         if (!_MultiCursorNext(ff)) {
            break;
         }
      }
      AutoCompleteReplaceWord(pfnReplaceWord, prefix, insertWord, onlyInsertWord, symbol);
      if (!multicursor) {
         if (!already_looping) _MultiCursorLoopDone();
         break;
      }
      if (target_wid!=p_window_id) {
         _MultiCursorLoopDone();
         break;
      }
   }
   activate_window(target_wid);
}

static void AutoCompleteReplaceWord(
   void (*pfnReplaceWord)(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol),
   _str prefix,
   _str insertWord,
   bool onlyInsertWord,
   struct VS_TAG_BROWSE_INFO symbol
   )
{
   if (_QReadOnly()) {
      _readonly_error(0);
      return;
   }

   save_pos(auto cur_pos);
   if (onlyInsertWord && p_undo_steps) {
      //say((gAutoCompleteResults.replaceWordPos==cur_pos)" "p_undo_steps" "(gAutoCompleteResults.replaceWordLastModified==p_LastModified));
      if (gAutoCompleteResults.replaceWordPos==cur_pos &&
          gAutoCompleteResults.replaceWordLastModified==p_LastModified
          ) {
         _undo();
         //_str line;get_line(line);say("line="line);
      } else {
         // Save the old buffer pos information.  Otherwise, undo will cause cursor to jump around
         _next_buffer('hr');_prev_buffer('hr');
      }
   }
   if (gAutoCompleteResults.origLineContent!=null) {
      replace_line(gAutoCompleteResults.origLineContent);
      p_col=gAutoCompleteResults.origCol;
      prefix=gAutoCompleteResults.origPrefix;
      gAutoCompleteResults.removeLen=0;
      gAutoCompleteResults.origLineContent=null;
   }

   // calculate whether or not we should delete the part of the
   // identifier to the right of the cursor
   numExtraChars := (gAutoCompleteResults.end_col-p_col);
   if (!(_GetCodehelpFlags() & VSCODEHELPFLAG_REPLACE_IDENTIFIER) ||
       (numExtraChars <= 0) ||
       ((_GetCodehelpFlags() & VSCODEHELPFLAG_PRESERVE_IDENTIFIER) &&
        !(gAutoCompleteResults.wasForced) &&
        (gAutoCompleteResults.operatorTyped || gAutoCompleteResults.wasListParameters))) {
      numExtraChars = 0;
   }

   utf8_extraChars := get_text(numExtraChars);
   if (pfnReplaceWord!=null) {
      if (numExtraChars > 0) _delete_text(numExtraChars);
      gAutoCompleteResults.removeLen=0;
      (*pfnReplaceWord)(insertWord,prefix,
                        gAutoCompleteResults.removeStartCol,
                        gAutoCompleteResults.removeLen,
                        onlyInsertWord, symbol);
   } else {
      p_col -= length(prefix);
      _delete_text(length(prefix)+numExtraChars);
      _insert_text(insertWord);
   }
   // for macro recording, just insert the rest of the word
   _macro('m',_macro('s'));
   if (gAutoCompleteResults.origLineContent!=null) {
      _macro_append("replace_line("_quote(gAutoCompleteResults.origLineContent)");");
      _macro_append("p_col="gAutoCompleteResults.origCol";");
   }
   if (_macro('KI')) {
      // Remove keys for displaying or scrolling list
      //_str string=_macro('KG');   // Fetch current recording

      _str chars=prefix;
      if (p_UTF8) {
         chars=prefix;
      } else {
         chars=_MultiByteToUTF8(prefix);
      }
      int count=_UTF8CountChars(chars);
      i := 0;
      for (;i<count;++i) {
         // Assume backspace deletes a character
         _macro('KK',name2event("BACKSPACE"));
      }
      count=_UTF8CountChars(utf8_extraChars);
      i=0;
      for (;i<count;++i) {
         // Assume del deletes a character after the cursor
         _macro('KK',name2event("DEL"));
      }
      _kbdmacro_add_string(insertWord);
   }
   replaceFunction := AutoCompleteGetReplaceWordFunctionName(pfnReplaceWord);
   if (replaceFunction != "") {
      if (numExtraChars > 0) {
         _macro_append("_delete_text("numExtraChars");");
      }
      _macro_append(replaceFunction"("_quote(insertWord)","_quote(prefix)","gAutoCompleteResults.removeStartCol","gAutoCompleteResults.removeLen","onlyInsertWord");");
   } else {
      // IF there is a keyboard macro beging recorded
      if (length(prefix) > 0) {
         _macro_append("p_col -= "length(prefix)";");
      }
      if (length(prefix)+numExtraChars > 0) {
         _macro_append("_delete_text("length(prefix)+numExtraChars");");
      }
      _macro_append("_insert_text("_quote(insertWord)");");
   }
   //if (didInsertSpace) {
   //   _macro_append("_insert_text(\" \");");
   //}

   save_pos(gAutoCompleteResults.replaceWordPos);
   gAutoCompleteResults.replaceWordLastModified=p_LastModified;
   gAutoCompleteResults.column=p_col;
   ParameterHelpSetSelectedSymbol(symbol);
   p_ModifyFlags |= MODIFYFLAG_AUTO_COMPLETE_UPDATED;
}

/**
 *
 */
static bool AutoCompleteInsertLongestPrefix(bool forceSymbolCompletion=false)
{
   // make sure completion results are active
   editorctl_wid := AutoCompleteGetEditorWid();
   if (editorctl_wid == 0) {
      return false;
   }
   if (!forceSymbolCompletion && !gAutoCompleteResults.allowInsertLongest) {
      return(false);
   }
   
   // make sure that the editor is still ready to go
   editorctl_wid = AutoCompleteGetEditorWid();
   if (!_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl() ||
       gAutoCompleteResults.lineoffset != editorctl_wid.point()) {
      return false;
   }

   // try to update the auto-complete prefix info if necessary
   if (gAutoCompleteResults.column != editorctl_wid.p_col ||
       gAutoCompleteResults.buffer != editorctl_wid.p_buf_id ) {
      useQuickPrefix := false;
      needsUpdate := false;
      origAutoCompleteResults := gAutoCompleteResults;
      getQuickPrefix(useQuickPrefix,needsUpdate);
      if (!useQuickPrefix ||
          gAutoCompleteResults.column != editorctl_wid.p_col ||
          gAutoCompleteResults.buffer != editorctl_wid.p_buf_id ) {
         gAutoCompleteResults = origAutoCompleteResults;
         return false;
      }
   }

   // Only do this once until the buffer is modified.
   gAutoCompleteResults.allowInsertLongest=false;

   // no matches?
   if (gAutoCompleteResults.words._length() <= 0) {
      return false;
   }

   // nothing selected already, see if there is a unique match prefix
   prefix := gAutoCompleteResults.prefix;
   longest_word   := "";
   longest_prefix := ""; //gAutoCompleteResults.words[0].word;
   longest_prefix = null;
   int i, n = gAutoCompleteResults.words._length();
   void (*pfnReplaceWord)(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol)=null;
   VS_TAG_BROWSE_INFO cm = null;

   // check if we are invoking strict case-sensitivity rules
   // it depends on the situation in which we were invoked
   strictCaseSensitivity := false;
   if (gAutoCompleteResults.wasListSymbols) {
      strictCaseSensitivity = (_GetCodehelpFlags() & VSCODEHELPFLAG_LIST_MEMBERS_CASE_SENSITIVE) != 0;
   } else if (forceSymbolCompletion) {
      strictCaseSensitivity = (_GetCodehelpFlags() & VSCODEHELPFLAG_IDENTIFIER_CASE_SENSITIVE) != 0;
   } else {
      strictCaseSensitivity = !(AutoCompleteGetOptions() & AUTO_COMPLETE_NO_STRICT_CASE);
   }

   caseSensitive := strictCaseSensitivity;
   if (caseSensitive && !editorctl_wid.p_EmbeddedCaseSensitive) {
      caseSensitive = false;
   }

   for (i=0; i<n; ++i) {
      // do not do this for aliases
      if ((typeless)gAutoCompleteResults.words[i].pfnReplaceWord == (typeless)_autocomplete_expand_alias) {
         return false;
      }

      // make sure prefix matches
      word := gAutoCompleteResults.words[i].insertWord;
      /*
         Case 1: not prefix match
            prefix = a   word= ddd

         case 2:
            prefix= c:\p  word=c:\program files

            longest=p

      */
      ignore_case := (caseSensitive && gAutoCompleteResults.words[i].caseSensitive? "":"I");
      if (length(prefix) > 0 && pos(prefix, word,1,ignore_case) != 1) continue;
      if (longest_prefix==null) {
         longest_prefix=word;
         longest_word=word;
      } else if (length(word) > length(longest_prefix)) {
         longest_word=word;
      }

      // trim word until prefix fits
      count := 0;
      while (pos(longest_prefix, word,1,ignore_case) != 1 && longest_prefix!="") {
         longest_prefix = substr(longest_prefix,1,length(longest_prefix)-1);
      }

      //longest=substr(longest,length(prefix)+1);
      //say("longest_prefix="longest_prefix);

      // trimmed all the way down to original prefix, then bail
      if (length(longest_prefix) == length(prefix)) {
         if (!forceSymbolCompletion) return false;
         if (length(longest_word) > length(longest_prefix)) return false;
         gAutoCompleteResults.wasForced=forceSymbolCompletion;
      }
      pfnReplaceWord=gAutoCompleteResults.words[i].pfnReplaceWord;
      cm=gAutoCompleteResults.words[i].symbol;
   }

   // make sure that the editor is still ready to go
   editorctl_wid = AutoCompleteGetEditorWid();
   if (!_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl() ||
       gAutoCompleteResults.lineoffset != editorctl_wid.point() ||
       gAutoCompleteResults.column != editorctl_wid.p_col ||
       gAutoCompleteResults.buffer != editorctl_wid.p_buf_id ) {
      return false;
   }

   // save the original window ID and make the editor current
   orig_wid := p_window_id;
   p_window_id = editorctl_wid;
   if (longest_prefix==null || longest_prefix == "") {
      return(false);
   }
   //say("result longest_prefix="longest_prefix);

   // replace the prefix with the selected word
   AutoCompleteReplaceWordForEachMultiCursor(pfnReplaceWord, prefix, longest_prefix, onlyInsertWord:true, cm);

   // now update the information
   if (AutoCompleteActive()) {
      AutoCompleteUpdateInfo(alwaysUpdate:true);
      AutoCompleteShowInfo();
   }
   p_window_id = orig_wid;
   return true;
}

/**
 * Skip categories when moving up and down in the auto-complete tree.
 * The current object is expected to be the tree control.
 *
 * @param direction  down=1, up=-1
 *
 * @return -1 if tree top/bottom is hit, 0 on success
 */
static int AutoCompleteTreeSkipCategories(AutoCompleteFlags auto_complete_options, int direction)
{
   if (auto_complete_options & AUTO_COMPLETE_SHOW_CATEGORIES) {
      // If we are on a category
      cur_index := _TreeCurIndex();
      while (cur_index > 0 && _TreeGetParentIndex(cur_index) == TREE_ROOT_INDEX) {
         // Move off the category.
         if (direction > 0) {
            if (_TreeDown()) return -1;
         } else {
            if (_TreeUp()) return -1;
         }
         cur_index = _TreeCurIndex();
      }
   }

   return 0;
}

/**
 * Process keyboard event occuring while auto complete is active.
 * Maps UP/DOWN to scrolling up/down the list, etc.
 */
void AutoCompleteDoKey()
{
   //say("AutoCompleteDoKey: last="event2name(last_event()));
   if (_macro('KI')) _macro('KD');
   _macro_delete_line();
   _macro('m',_macro('s'));
   doTerminate := false;
   key := last_event(null,true);
   origKey := key;
   unique := false;
   index := 0;

   // By default, auto-complete should not be restarted by function help
   gAutoCompleteResults.maybeRestartListParametersAfterKey = false;

   // not in an editor control
   if (!_isEditorCtl()) {
      return;
   }

   // get the auto complete tree
   // if it is gone, then auto complete is gone
   tree_wid := AutoCompleteGetTreeWid();
   if (tree_wid <= 0) {
      AutoCompleteDefaultKey(key, doTerminate:false);
      AutoCompleteTerminate();
      return;
   }

   //say("AutoCompleteDoKey: key="key"=");
   auto_complete_options := AutoCompleteGetOptionsMaybeShowCategories();
   if (length(key)==1 && _asc(_maybe_e2a(key))>=27 && key:!=" " && key:!="(") {
      if (AutoCompleteActive()) {
         // IF this is a word character
         useQuickPrefix := false;
         forceUpdate := false;
         getQuickPrefix(useQuickPrefix,forceUpdate,key);
         word_chars := _clex_identifier_chars();
         if (key!=FILESEP &&
             (pos('['word_chars']',key,1,'r') ||
             (useQuickPrefix))) {
            AutoCompleteDefaultKey(key, doTerminate:false);
            _bbhelp('C');
            AutoCompleteUpdateInfo(alwaysUpdate:false);
         } else {
            // NOT a word character
            if (gAutoCompleteResults.allowImplicitReplace) {
               AutoCompleteRunCommand(key);
            }
            // if they key is the same character as the last char of the
            // item that was expanded, then delete the last char inserted
            // so that executing the key does not create a duplicate
            if (p_col > 1 && key == get_text_left() && !pos(key, "%.-+<>\\/")) {
               left();
               _delete_text(1);
            }
            if (key:==FILESEP) {
               AutoCompleteDefaultKey(key, doTerminate:false);
               AutoCompleteDeselect();
               AutoCompleteUpdateInfo(alwaysUpdate:false);
               gAutoCompleteResults.allowShowInfo=true;
               gAutoCompleteResults.allowImplicitReplace=true;
            } else {
               isPrefixValid := AutoCompletePrefixValid(gAutoCompleteResults.prefix:+key);
               AutoCompleteDefaultKey(key, doTerminate: !isPrefixValid);
            }
         }
      } else {
         // DJB (09/24/2005) -- Auto Complete is not active
         // so do not mess about with event tables.
         AutoCompleteDefaultKey(key, doTerminate:true);
      }
      return;
   }

   // get the comment form window ID, if available
   word_index  := gAutoCompleteResults.wordIndex;
   comment_wid := AutoCompleteGetCommentsWid();
   tree_status := 0;

   // handle tab and shift-tab, depending on options
   switch (key) {
   case " ":
      if (_GetCodehelpFlags() & VSCODEHELPFLAG_SPACE_COMPLETION) {
         if (gAutoCompleteResults.allowImplicitReplace) {
            if (AutoCompleteInsertLongestPrefix()) return;
         }
      }
      break;
   case name2event("C- "):
      if (AutoCompleteInsertLongestPrefix(true)) {
         return;
      }
      break;
   case TAB:
      // If an item is selected, then make tab finish the completion
      // unless they are using tab to cycle through choices
      if (!(auto_complete_options & AUTO_COMPLETE_TAB_NEXT)) {
         if (gAutoCompleteResults.allowImplicitReplace) {
            if (word_index >= 0 && word_index < gAutoCompleteResults.words._length()) {
               AutoCompleteRunCommand(key);
               return;
            }
         }
      }
      // Try to insert longest unique prefix, return if so
      if (auto_complete_options & AUTO_COMPLETE_TAB_INSERTS_PREFIX) {
         if (AutoCompleteInsertLongestPrefix()) return;
         if (auto_complete_options & AUTO_COMPLETE_TAB_NEXT) break;
         if (!gAutoCompleteResults.allowImplicitReplace) {
            gAutoCompleteResults.allowImplicitReplace = true;
            auto_complete_options |= AUTO_COMPLETE_TAB_NEXT;
         }
      }
      // if "Tab cycles through choices" then handle it below (like DOWN)
      if (auto_complete_options & AUTO_COMPLETE_TAB_NEXT) break;
      // If an item is selected, then make tab finish the completion
      if (word_index >= 0 && word_index < gAutoCompleteResults.words._length()) {
         AutoCompleteRunCommand(key);
         return;
      }
      // otherwise, terminate list help and do default action for tab
      if (!(auto_complete_options & AUTO_COMPLETE_TAB_INSERTS_PREFIX)) {
         AutoCompleteTerminate();
         AutoCompleteDefaultKey(key, doTerminate:true);
      }
      return;
   case S_TAB:
      if (auto_complete_options & AUTO_COMPLETE_TAB_NEXT) break;
      AutoCompleteTerminate();
      AutoCompleteDefaultKey(key, doTerminate:true);
      return;
   }

   // handle other key presses
   switch (key) {
   case name2event(" "):
      doSpaceKey := true;
      if (word_index >= 0 && word_index < gAutoCompleteResults.words._length() && gAutoCompleteResults.allowImplicitReplace) {
         doSpaceKey = ((_GetCodehelpFlags() & VSCODEHELPFLAG_SPACE_INSERTS_SPACE) ||
                       gAutoCompleteResults.words[word_index].pfnReplaceWord == _autocomplete_space ||
                       gAutoCompleteResults.words[word_index].pfnReplaceWord == _autocomplete_expand_alias
                      );
         AutoCompleteRunCommand(key);
      }
      if (doSpaceKey) {
         gAutoCompleteResults.maybeRestartListParametersAfterKey = true;
         AutoCompleteDefaultKey(key, doTerminate:true);
         gAutoCompleteResults.maybeRestartListParametersAfterKey = false;
      }
      return;
   case name2event("C- "):
      // force sub-word pattern matching (second attempt)
      if ( (gAutoCompleteResults.wasForced && gAutoCompleteResults.wasListSymbols) && 
           (gAutoCompleteResults.wasFirstSubwordMatchingAttempt) &&
          !(_GetCodehelpFlags() & VSCODEHELPFLAG_LIST_MEMBERS_NO_SUBWORD_MATCHES) &&
           (_GetCodehelpFlags() & VSCODEHELPFLAG_SUBWORD_MATCHING_ONLY_ON_RETRY) ) {
         AutoCompleteDefaultKey(key, doTerminate:true);
         AutoCompleteUpdateInfo(alwaysUpdate:true,
                                forceUpdate:true,
                                doInsertLongest:false,
                                selectMatchingItem:true,
                                isFirstAttempt:false);

      } else if (word_index >= 0 && word_index < gAutoCompleteResults.words._length()) {
         // If an item is selected, then make ctrl+space finish the completion
         AutoCompleteRunCommand(key);
      } else {
         AutoCompleteDefaultKey(key, doTerminate:true);
      }
      break;
   case name2event("("):
      doOpenParenKey := true;
      if (word_index >= 0 && word_index < gAutoCompleteResults.words._length() && gAutoCompleteResults.allowImplicitReplace) {
         doOpenParenKey = !(gAutoCompleteResults.words[word_index].pfnReplaceWord == _autocomplete_space ||
                            gAutoCompleteResults.words[word_index].pfnReplaceWord == _autocomplete_expand_alias
                           );
         AutoCompleteRunCommand(key);
      }
      if (doOpenParenKey) {
         AutoCompleteDefaultKey(key, doTerminate:true);
      }
      return;
   case ENTER:
      if (word_index >= 0 && word_index < gAutoCompleteResults.words._length()) {
         if (gAutoCompleteResults.allowImplicitReplace || (auto_complete_options & AUTO_COMPLETE_ENTER_ALWAYS_INSERTS)) {
            gAutoCompleteResults.allowImplicitReplace=true;
            AutoCompleteRunCommand(key);
         } else {
            AutoCompleteTerminate();
         }
         if (origKey:==ENTER && beginsWith(p_buf_name,".process") && 
             (!(auto_complete_options & AUTO_COMPLETE_NO_INSERT_SELECTED))) {
            AutoCompleteDefaultKey(key, doTerminate:true);
         }
      } else {
         gAutoCompleteResults.maybeRestartListParametersAfterKey = true;
         AutoCompleteDefaultKey(key, doTerminate:true);
         gAutoCompleteResults.maybeRestartListParametersAfterKey = false;
      }
      return;
   case BACKSPACE:
   case DEL:
      AutoCompleteDefaultKey(key, doTerminate:false);
      if (p_col < gAutoCompleteResults.start_col) {
         AutoCompleteTerminate();
         return;
      }
      if (p_col == gAutoCompleteResults.start_col && !gAutoCompleteResults.wasListSymbols) {
         if (!gAutoCompleteResults.wasForced || !gAutoCompleteResults.allowImplicitReplace) {
            AutoCompleteTerminate();
            return;
         }
      }
      AutoCompleteDeselect();
      AutoCompleteUpdateInfo(alwaysUpdate:false, forceUpdate:false);
      return;
   case LEFT:
   case RIGHT:
      AutoCompleteDefaultKey(key, doTerminate:false);
      if (!_clex_is_identifier_char(get_text()) && p_col != gAutoCompleteResults.end_col) {
         AutoCompleteTerminate();
         return;
      }
      AutoCompleteDeselect();
      AutoCompleteUpdateInfo(alwaysUpdate:false, forceUpdate:false);
      return;
   case name2event("C-S- "):
      if (word_index >= 0 && word_index < gAutoCompleteResults.words._length()) {
         categoryLevel := gAutoCompleteResults.words[word_index].priorityLevel;
         word := gAutoCompleteResults.words[word_index].insertWord;
         prefix := gAutoCompleteResults.prefix;
         key = substr(word, length(prefix)+1, 1);
         if (key != "") {
            AutoCompleteDefaultKey(key, doTerminate:false);
            AutoCompleteUpdateInfo(alwaysUpdate:true);
            AutoCompleteSelectWord(categoryLevel, word);
         } else {
            message("No more characters to insert for '"word"'");
         }
      } else {
         message("No completion selected.");
      }
      return;
   case C_G:
      if (!iscancel(key)) {
         AutoCompleteDefaultKey(key, doTerminate:false);
         return;
      }
      if (gAutoCompleteResults.origLineContent!=null && !(auto_complete_options & AUTO_COMPLETE_NO_INSERT_SELECTED)) {
         replace_line(gAutoCompleteResults.origLineContent);
         p_col=gAutoCompleteResults.origCol;
      }
      AutoCompleteTerminate();
      return;
   case ESC:
      if (gAutoCompleteResults.origLineContent!=null && !(auto_complete_options & AUTO_COMPLETE_NO_INSERT_SELECTED)) {
         replace_line(gAutoCompleteResults.origLineContent);
         p_col=gAutoCompleteResults.origCol;
      }
      AutoCompleteTerminate();
      if (def_keys == "vi-keys" && def_vim_esc_codehelp) {
         vi_escape();
      }
      return;

   case name2event("c-pgdn"):
      if (comment_wid != 0) {
         AutoCompleteNextComment(1);
      } else {
         AutoCompleteDefaultKey(key, doTerminate:false);
      }
      return;
   case name2event("c-pgup"):
      if (comment_wid != 0) {
         AutoCompleteNextComment(-1);
      } else {
         AutoCompleteDefaultKey(key, doTerminate:false);
      }
      return;

   case name2event("s-pgdn"):
   case name2event("s-pgup"):
   case name2event("s-home"):
   case name2event("s-end"):
      if (comment_wid != 0) {
         _nocheck _control ctlminihtml1;
         int wid=comment_wid.ctlminihtml1;
         if (wid) {
            switch (key) {
            case name2event("s-pgdn"):
               wid.call_event(wid,PGDN,'W');
               return;
            case name2event("s-pgup"):
               wid.call_event(wid,PGUP,'W');
               return;
            case name2event("s-home"):
               wid.call_event(wid,HOME,'W');
               return;
            case name2event("s-end"):
               wid.call_event(wid,END,'W');
               return;
            }
         }
      }
      AutoCompleteDefaultKey(key, doTerminate:false);
      return;

   case S_TAB:
   case UP:
   case C_I:
      if (tree_wid.p_active_form.p_visible || key==S_TAB) {
         // skip over category nodes if necessary
         if (gAutoCompleteResults.allowShowInfo) {
            gAutoCompleteResults.allowShowInfo=false;
            tree_status = tree_wid._TreeUp();
         }
         if (!tree_status) {
            tree_status = tree_wid.AutoCompleteTreeSkipCategories(auto_complete_options,-1);
         }
         if (tree_status<0) {
            tree_status=0;
            tree_wid._TreeBottom();
         }
         tree_status = tree_wid.AutoCompleteTreeSkipCategories(auto_complete_options,-1);
         // record which item is highlighted
         if (tree_status < 0) {
            gAutoCompleteResults.wordIndex = -1;
         } else {
            gAutoCompleteResults.wordIndex = tree_wid._TreeGetUserInfo(tree_wid._TreeCurIndex());
         }
         // we can show items and allow replacements now
         gAutoCompleteResults.allowShowInfo=true;
         gAutoCompleteResults.allowImplicitReplace=true;
         tree_wid.p_AlwaysColorCurrent = true;
         AutoCompleteShowInfo();
         AutoCompleteStartTimer();
      } else {
         AutoCompleteDefaultKey(key, doTerminate:true);
      }
      return;
   case TAB:
   case DOWN:
   case C_K:
      if (tree_wid.p_active_form.p_visible || key==TAB) {
         // skip over category nodes if necessary
         if (gAutoCompleteResults.allowShowInfo) {
            gAutoCompleteResults.allowShowInfo=false;
            tree_status = tree_wid._TreeDown();
         }
         if (!tree_status) {
            tree_status = tree_wid.AutoCompleteTreeSkipCategories(auto_complete_options,1);
         }
         if (tree_status < 0) {
            tree_status=0;
            tree_wid._TreeTop();
         }
         tree_status = tree_wid.AutoCompleteTreeSkipCategories(auto_complete_options,1);
         // record which item is highlighted
         if (tree_status < 0) {
            gAutoCompleteResults.wordIndex = -1;
         } else {
            gAutoCompleteResults.wordIndex = tree_wid._TreeGetUserInfo(tree_wid._TreeCurIndex());
         }
         // we can show items and allow replacements now
         gAutoCompleteResults.allowShowInfo=true;
         gAutoCompleteResults.allowImplicitReplace=true;
         tree_wid.p_AlwaysColorCurrent = true;
         AutoCompleteShowInfo();
         AutoCompleteStartTimer();
      } else {
         AutoCompleteDefaultKey(key, doTerminate:true);
      }
      return;
   case PGUP:
      if (tree_wid.p_active_form.p_visible) {
         gAutoCompleteResults.allowShowInfo=false;
         tree_wid._TreePageUp();
         cur_index := tree_wid._TreeCurIndex();
         if (cur_index > 0 && AutoCompleteIsOnCategoryNode(index)) {
            tree_wid._TreeDown();
         }
         gAutoCompleteResults.wordIndex = tree_wid._TreeGetUserInfo(tree_wid._TreeCurIndex());
         gAutoCompleteResults.allowShowInfo=true;
         gAutoCompleteResults.allowImplicitReplace=true;
         tree_wid.p_AlwaysColorCurrent = true;
         AutoCompleteShowInfo();
         AutoCompleteStartTimer();
      } else {
         AutoCompleteDefaultKey(key, doTerminate:true);
      }
      return;
   case PGDN:
      if (tree_wid.p_active_form.p_visible) {
         gAutoCompleteResults.allowShowInfo=false;
         tree_wid._TreePageDown();
         cur_index := tree_wid._TreeCurIndex();
         if (cur_index > 0 && AutoCompleteIsOnCategoryNode(index)) {
            tree_wid._TreeUp();
         }
         gAutoCompleteResults.wordIndex = tree_wid._TreeGetUserInfo(tree_wid._TreeCurIndex());
         gAutoCompleteResults.allowShowInfo=true;
         gAutoCompleteResults.allowImplicitReplace=true;
         tree_wid.p_AlwaysColorCurrent = true;
         AutoCompleteShowInfo();
         AutoCompleteStartTimer();
      } else {
         AutoCompleteDefaultKey(key, doTerminate:true);
      }
      return;
   case name2event("A-."):
   case name2event("M-."):
   case name2event("A-M-."):
      if (tree_wid.p_active_form.p_visible) { 
         if (AutoCompleteGetOptionsMaybeShowCategories() & AUTO_COMPLETE_SHOW_CATEGORIES) {
            cur_index := tree_wid._TreeCurIndex();
            if (tree_wid._TreeGetDepth(cur_index) == 2) {
               cur_index = tree_wid._TreeGetParentIndex(cur_index);
            }
            if (tree_wid._TreeGetDepth(cur_index) == 1) {
               cur_index = tree_wid._TreeGetNextSiblingIndex(cur_index);
            }
            if (cur_index > 0) {
               tree_wid._TreeSetCurIndex(cur_index);
            } else {
               if ( (gAutoCompleteResults.wasForced && gAutoCompleteResults.wasListSymbols) && 
                    (gAutoCompleteResults.wasFirstSubwordMatchingAttempt) &&
                   !(_GetCodehelpFlags() & VSCODEHELPFLAG_LIST_MEMBERS_NO_SUBWORD_MATCHES) &&
                    (_GetCodehelpFlags() & VSCODEHELPFLAG_SUBWORD_MATCHING_ONLY_ON_RETRY) ) {
                  AutoCompleteDefaultKey(key, doTerminate:true);
                  AutoCompleteUpdateInfo(alwaysUpdate:true, forceUpdate:true, prefixMatch:false, isFirstAttempt:false);
                  tree_wid = AutoCompleteGetTreeWid();
                  if (tree_wid <= 0) {
                     return;
                  }
               }
               tree_wid._TreeTop();
            }
            cur_index = tree_wid._TreeCurIndex();
            topLine := tree_wid._TreeCurLineNumber();
            if (topLine > 0) tree_wid._TreeScroll(topLine);
            gAutoCompleteResults.wordIndex = -1;
            gAutoCompleteResults.allowShowInfo=false;
            tree_wid.p_AlwaysColorCurrent = true;
            AutoCompleteShowInfo();
            AutoCompleteStartTimer();
         } else {
            AutoCompleteDefaultKey(key, doTerminate:true);
            if (gAutoCompleteResults.wasListSymbols && 
                gAutoCompleteResults.wasFirstSubwordMatchingAttempt &&
                !(_GetCodehelpFlags() & VSCODEHELPFLAG_LIST_MEMBERS_NO_SUBWORD_MATCHES) &&
                 (_GetCodehelpFlags() & VSCODEHELPFLAG_SUBWORD_MATCHING_ONLY_ON_RETRY)) {
               AutoCompleteDefaultKey(key, doTerminate:true);
               AutoCompleteUpdateInfo(alwaysUpdate:true, forceUpdate:true, prefixMatch:false, isFirstAttempt:false);
            }
         }
      }
      return;

   case name2event("A-,"):
   case name2event("M-,"):
   case name2event("A-M-,"):
      // force list compatible values
      AutoCompleteDefaultKey(key, doTerminate:true);
      return;

   case name2event("s-up"):
      if (tree_wid.p_active_form.p_visible) {
         function_help_form_wid := ParameterHelpReposition(aboveCurrentLine:true);
         if (_iswindow_valid(gAutoCompleteResults.listForm)) {
            AutoCompletePositionForm(gAutoCompleteResults.listForm,
                                     function_help_form_wid,
                                     true /*above*/);
         }
         if ( _iswindow_valid(comment_wid) && comment_wid.p_active_form.p_visible ) {
            AutoCompleteShowComments( comment_wid.p_active_form.p_x < tree_wid.p_active_form.p_x );
         }
      } else {
         AutoCompleteDefaultKey(key, doTerminate:true);
      }
      return;
   case name2event("s-down"):
      if (tree_wid.p_active_form.p_visible) {
         tree_wid.p_active_form.p_x > 
         function_help_form_wid := ParameterHelpReposition(aboveCurrentLine:false);
         if (_iswindow_valid(gAutoCompleteResults.listForm)) {
            AutoCompletePositionForm(gAutoCompleteResults.listForm,
                                     function_help_form_wid,
                                     false /*below*/);
         }
         if ( _iswindow_valid(comment_wid) && comment_wid.p_active_form.p_visible ) {
            AutoCompleteShowComments( comment_wid.p_active_form.p_x < tree_wid.p_active_form.p_x );
         }
      } else {
         AutoCompleteDefaultKey(key, doTerminate:true);
      }
      return;

   case name2event("s-left"):
      if ( _iswindow_valid(comment_wid) && comment_wid.p_active_form.p_visible ) {
         AutoCompleteShowComments(true);
      } else {
         AutoCompleteDefaultKey(key, doTerminate:true);
      }
      return;
   case name2event("s-right"):
      if ( _iswindow_valid(comment_wid) && comment_wid.p_active_form.p_visible ) {
         AutoCompleteShowComments(false);
      } else {
         AutoCompleteDefaultKey(key, doTerminate:true);
      }
      return;

   case C_C:
      if (_iswindow_valid(gAutoCompleteResults.commentForm)) {
         _nocheck _control ctlminihtml1;
         _nocheck _control ctlminihtml2;
         form_wid := gAutoCompleteResults.commentForm;
         if (form_wid.ctlminihtml1._minihtml_isTextSelected()) {
             form_wid.ctlminihtml1._minihtml_command("copy");
             form_wid.ctlminihtml1._minihtml_command("deselect");
            return;
         } else if (form_wid.ctlminihtml2._minihtml_isTextSelected()) {
            form_wid.ctlminihtml2._minihtml_command("copy");
            form_wid.ctlminihtml2._minihtml_command("deselect");
            return;
         }
      }
      if (_iswindow_valid(gAutoCompleteResults.listForm) && 
          gAutoCompleteResults.wordIndex >= 0 &&
          gAutoCompleteResults.allowShowInfo ) {
         tree_wid = AutoCompleteGetTreeWid();
         index = tree_wid._TreeCurIndex();
         tree_wid._TreeCopyContents(index, false);
         return;
      } 
      AutoCompleteDefaultKey(key, doTerminate:true);
      return;
   case C_A:
      if (_iswindow_valid(gAutoCompleteResults.commentForm)) {
         _nocheck _control ctlminihtml1;
         _nocheck _control ctlminihtml2;
         form_wid := gAutoCompleteResults.commentForm;
         if (!form_wid.ctlminihtml1._minihtml_isTextSelected() &&
             !form_wid.ctlminihtml2._minihtml_isTextSelected()) {
            form_wid.ctlminihtml2._minihtml_command("deselect");
            form_wid.ctlminihtml1._minihtml_command("selectall");
            return;
         } else if (!form_wid.ctlminihtml2._minihtml_isTextSelected()) {
            form_wid.ctlminihtml1._minihtml_command("deselect");
            form_wid.ctlminihtml2._minihtml_command("selectall");
            return;
         } else {
            form_wid.ctlminihtml1._minihtml_command("deselect");
            form_wid.ctlminihtml1._minihtml_command("deselect");
         }
      }
      AutoCompleteDefaultKey(key, doTerminate:true);
      return;
   case C_U:
      if (_iswindow_valid(gAutoCompleteResults.commentForm)) {
         _nocheck _control ctlminihtml1;
         _nocheck _control ctlminihtml2;
         form_wid := gAutoCompleteResults.commentForm;
         if (form_wid.ctlminihtml1._minihtml_isTextSelected() ||
             form_wid.ctlminihtml2._minihtml_isTextSelected()) {
            form_wid.ctlminihtml1._minihtml_command("deselect");
            form_wid.ctlminihtml2._minihtml_command("deselect");
            return;
         }
      }
      AutoCompleteDefaultKey(key, doTerminate:true);
      return;

   default:
      return;
   }
}

///////////////////////////////////////////////////////////////////////////////
defeventtab _auto_complete_list_form;

ctltree.on_create(AUTO_COMPLETE_INFO (&words)[], int current)
{
   // add the completion words to the tree
   AutoCompleteUpdateList(words, current);

   // size the tree
   p_active_form.p_MouseActivate=MA_NOACTIVATE;
   y := ctltree.p_height;
   h := _moncfg_retrieve_value("_auto_complete_list_form.p_height");
   if (isinteger(h)) y=(int)h;
   ctltree.AutoCompleteUpdateListHeight(y,0,true, auto verticalScrollBarNeeded);
   ctltree.AutoCompleteUpdateListWidth(0, verticalScrollBarNeeded);
}

// resize the form
void ctlsizebar.lbutton_down()
{
   mou_mode(1);
   mou_release();
   mou_capture();
   selected_wid := p_window_id;
   p_window_id=selected_wid.p_parent;

   // height of one line in the tree control
   int delta_h = _twips_per_pixel_y() * ctltree.p_line_height;

   // loop until we get the mouse-up event
   int orig_y=p_active_form.p_height;
   y := 0;
   for (;;) {
      _str event=get_event();
      switch (event) {
      case MOUSE_MOVE:
         y = ctltree._update_list_height(mou_last_y('M'),false);
         continue;
      case LBUTTON_UP:
         y = ctltree._update_list_height(mou_last_y('M'),true);
         _moncfg_append_retrieve(0, ctltree.p_height, ctltree.p_active_form.p_name:+".p_height");
         mou_mode(0);
         mou_release();

         // scroll the current item in the tree into view
         char_h := ctltree.p_line_height;
         first_visible := ctltree._TreeScroll();
         current_line  := ctltree._TreeCurLineNumber();
         if (char_h > 0 && current_line > first_visible && 
             (current_line-first_visible)*delta_h >= ctltree.p_height) {
            max_lines := ctltree.p_height intdiv (_twips_per_pixel_y()*char_h);
            if (current_line > max_lines) {
               ctltree._TreeScroll(current_line - max_lines + 1);
            } else {
               ctltree._TreeScroll(0);
            }
         }

         // now update the comments if they were displayed before
         if (_iswindow_valid(gAutoCompleteResults.commentForm)) {
            AutoCompleteShowComments( gAutoCompleteResults.commentForm.p_x < p_active_form.p_x );
         }
         p_window_id=selected_wid;
         return;
      }
   }
}

/**
 * Update the tree control containing the list of completions
 * <p>
 * The completions are separated into categories (folders).
 * Each item in the tree uses it's tree index to refer back
 * to the index of that item in the list of words.
 *
 * @param words      list of auto complete items
 * @param current    index of word in list to make active
 */
static void AutoCompleteUpdateList(AUTO_COMPLETE_INFO (&words)[], int current)
{
   // make sure auto-complete is active
   editorctl_wid := AutoCompleteGetEditorWid();
   if (!_iswindow_valid(editorctl_wid)) {
      return;
   }

   // set up symbol browser bitmaps
   hadItemSelected := gAutoCompleteResults.allowImplicitReplace;
   cb_prepare_expand(p_active_form, p_window_id, TREE_ROOT_INDEX);

   // set up the tree for updating
   gAutoCompleteResults.isActive=false;
   auto_complete_options := AutoCompleteGetOptionsMaybeShowCategories(editorctl_wid.p_LangId);
   p_LevelIndent = _dx2lx(SM_TWIP, 4);
   _TreeSetInfo(TREE_ROOT_INDEX, 1, -1, 01, TREENODE_HIDEINDICATOR);
   _TreeBeginUpdate(TREE_ROOT_INDEX, "", "T");

   // if the list is too long, then do not show function arguments
   int categories:[];
   showAllPrototypes := false;
   i := 0;
   n := words._length();
   if (auto_complete_options & AUTO_COMPLETE_SHOW_PROTOTYPES) {
      showAllPrototypes = true;
      if (n > def_auto_complete_max_prototypes) {
         bool uniqueCaptions:[];
         bool uniqueWords:[];
         for (i=0; i<n; ++i) {
            word_caption := words[i].displayWord;
            uniqueWords:[word_caption] = true;
            if (words[i].symbol != null) {
               VS_TAG_BROWSE_INFO cm = words[i].symbol;
               word_caption = tag_make_caption_from_browse_info(cm, include_class:false, include_args:true, include_tab:false);
               if (_chdebug) {
                  tag_browse_info_dump(cm, "AutoCompleteUpdateList["i"]");
                  say("AutoCompleteUpdateList H"__LINE__": word_caption="word_caption);
               }
            }
            uniqueCaptions:[word_caption] = true;
            if (uniqueWords._length() > 1 && 
                uniqueCaptions._length() > def_auto_complete_max_prototypes) {
               showAllPrototypes = false;
               break;
            }
         }
      }
   }

   // get the word under the curser
   lastid := gAutoCompleteResults.prefix;
   if (gAutoCompleteResults.idexp_info != null) {
      lastid = gAutoCompleteResults.idexp_info.lastid;
   }

   // update all the words
   cur_index := 0;
   for (i=0; i<n; ++i) {

      // create a new folder?
      folder_name := "Category";
      if (gAutoCompleteCategoryNames._indexin(words[i].priorityLevel)) {
         folder_name = gAutoCompleteCategoryNames:[words[i].priorityLevel];
      }
      int folder_index = TREE_ROOT_INDEX;
      if ((auto_complete_options & AUTO_COMPLETE_SHOW_CATEGORIES) && folder_name != "") {
         if (categories._indexin(folder_name)) {
            folder_index = categories:[folder_name];
         } else {
            folder_pic := 0;
            if (auto_complete_options & AUTO_COMPLETE_SHOW_ICONS) {
               folder_pic = _pic_fldopen;
            }
            folder_index = _TreeAddItem(TREE_ROOT_INDEX, folder_name, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_EXPANDED, TREENODE_BOLD|TREENODE_HIDEINDICATOR, words[i].priorityLevel);
            categories:[folder_name] = folder_index;
         }
      }

      // get symbol information?
      word_pic := 0;
      word_overlay := 0;
      word_caption := words[i].displayWord;
      if (auto_complete_options & AUTO_COMPLETE_SHOW_ICONS) {
         if (words[i].bitmapIndex != 0) {
            word_pic=words[i].bitmapIndex;
         } else if (words[i].symbol != null) {
            VS_TAG_BROWSE_INFO cm = words[i].symbol;
            tagType := tag_get_type_id(cm.type_name);
            word_pic = tag_get_bitmap_for_type(tagType, cm.flags, word_overlay);
         }
      }
      if (words[i].symbol != null && words[i].symbol.member_name != "") {
         cm := words[i].symbol;
         if ((auto_complete_options & AUTO_COMPLETE_SHOW_PROTOTYPES) && 
             (showAllPrototypes || cm.member_name == lastid)) {
             words[i].displayArguments = true;
             word_caption = tag_make_caption_from_browse_info(cm, include_class:false, include_args:true, include_tab:false);
         } else {
             word_caption = tag_make_caption_from_browse_info(cm, include_class:false, include_args:false, include_tab:false);
         }
      }

      // add the word to the list
      if (_chdebug) {
         say("AutoCompleteUpdateList: word_caption="word_caption);
      }
      word_index := _TreeAddItem(folder_index, word_caption, TREE_ADD_AS_CHILD|TREE_OVERLAY_BITMAP1, word_overlay, word_pic, TREE_NODE_LEAF, 0, i);

      // is this the current item selected?
      if (i == current) {
         cur_index = word_index;
      }
   }

   // that's all folks
   _TreeEndUpdate(TREE_ROOT_INDEX);

   // set the current item
   if (cur_index != 0 && _TreeCurIndex() != cur_index) {
      _TreeSetCurIndex(cur_index);
   }

   // deselect if there was no item auto-selected before
   if (!hadItemSelected) {
      AutoCompleteDeselect();
   }

   // now sort
   if (auto_complete_options & AUTO_COMPLETE_SHOW_CATEGORIES) {
      // sort the categories by priority
      _TreeSortUserInfo(TREE_ROOT_INDEX, 'N');

      // sort the tree nodes, and hide the duplicates
      tree_index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (tree_index > 0) {
         _TreeSortCaption(tree_index,'ub');
         tree_index = _TreeGetNextSiblingIndex(tree_index);
      }
   } else {
      // no categories, just sort the tree nodes, and hide the duplicates
      _TreeSortCaption(TREE_ROOT_INDEX, 'ub');
   }

   // make sure we aren't on the root node
   if (!hadItemSelected || _TreeCurIndex() <= 0) {
      _TreeTop();
      _TreeScroll(_TreeCurLineNumber());
   }

   // update the size of the list form
   AutoCompleteUpdateListHeight(0,0,true,auto verticalScrollBarNeeded);
   AutoCompleteUpdateListWidth(0,verticalScrollBarNeeded);
   gAutoCompleteResults.isActive=true;
   gAutoCompleteResults.maybeRestartListParametersAfterKey = false;
   _TreeRefresh();
}

// update the width of the code help tree control, assume that
// the current object is the tree control.
static void AutoCompleteUpdateListWidth(int initial_width=0, bool verticalScrollBarNeeded=false)
{
   // get the auto complete options
   auto_complete_options := AutoCompleteGetOptionsMaybeShowCategories();

   // get the size of the visible screen
   _GetVisibleScreen(auto vx, auto vy, auto vwidth, auto vheight);

   // get the tree icon size, symbol bitmaps are double-wide
   // We add 6 if there is a bitmap to mirror spacing which is hard-coded
   // in the tree control.  +3 if there is no bitmap.
   bitmap_width := 0;
   if (auto_complete_options & AUTO_COMPLETE_SHOW_ICONS) {
      bitmap_width = _dx2lx(SM_TWIP, _TreeGetIconWidth()+6);
   } else {
      bitmap_width = _dx2lx(SM_TWIP, 3);
   }
   // adjust width of form to accomodate longer captions
   tree_scrollbar_width  := (verticalScrollBarNeeded? _dx2lx(SM_TWIP,_TreeGetVScrollBarWidth()) : 0);
   tree_border_width    := _dx2lx(SM_TWIP,_TreeGetBorderWidth());
   form_width := _dx2lx(p_xyscale_mode, vwidth);
   level_indent := p_LevelIndent + _dx2lx(SM_TWIP, 4);
   border_width := 2*tree_border_width + tree_scrollbar_width + bitmap_width + level_indent;
   max_width := 0;
   if (auto_complete_options & AUTO_COMPLETE_SHOW_CATEGORIES) {
      border_width += level_indent;
   }
   if (initial_width > border_width) {
      max_width = initial_width - border_width;
   }

   // go through each category and each list of items underneath
   cat_index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (cat_index > 0) {
      // get the width of the caption
      int caption_width = _text_width(_TreeGetCaption(cat_index));
      if (caption_width > max_width) {
         max_width = caption_width;
      }

      // go through the items underneath
      tag_index := _TreeGetFirstChildIndex(cat_index);
      while (tag_index > 0) {
         // check the width of this caption
         caption_width = _text_width(_TreeGetCaption(tag_index));
         if (caption_width > max_width) {
            max_width = caption_width;
         }
         // next please
         tag_index = _TreeGetNextSiblingIndex(tag_index);
      }

      // next category please
      cat_index = _TreeGetNextSiblingIndex(cat_index);
   }

   // clip form if it is too wide
   if (max_width+border_width > form_width) {
      max_width = form_width - border_width;
   }

   // adjust the with of the tree and the form
   p_width = max_width+border_width;
   _nocheck _control ctlsizebar;
   p_active_form.ctlsizebar.p_width=p_width;
   p_active_form.p_width=p_active_form._left_width()*2+p_width;
}

static int AutoCompleteUpdateListHeight(int initial_height=0, 
                                        int screen_height=0,
                                        bool countLines=false,
                                        bool &verticalScrollBarNeeded=true)
{
   // get the size of the visible screen
   _GetVisibleScreen(auto vx, auto vy, auto vwidth, auto vheight);
   form_height := _dy2ly(p_xyscale_mode, vheight);

   // count the number of lines in the tree
   line_count := 0;
   if (countLines) {
      show_children := bm1 := bm2 := line_number := tree_flags := 0;
      cat_index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (cat_index > 0) {
         // go through the items underneath
         tag_index := _TreeGetFirstChildIndex(cat_index);
         while (tag_index > 0) {
            _TreeGetInfo(tag_index, show_children, bm1, bm2, tree_flags, line_number, TREENODE_HIDDEN);
            if (!(tree_flags & TREENODE_HIDDEN)) {
               line_count++;
            }
            tag_index = _TreeGetNextSiblingIndex(tag_index);
         }

         // next category please
         _TreeGetInfo(cat_index, show_children, bm1, bm2, tree_flags, line_number, TREENODE_HIDDEN);
         if (!(tree_flags & TREENODE_HIDDEN)) {
            line_count++;
         }
         cat_index = _TreeGetNextSiblingIndex(cat_index);
      }
   }

   // get the original form height, and last sizing state
   y := initial_height;
   if (y==0 || countLines) {
      h := _moncfg_retrieve_value(p_active_form.p_name:+".p_height");
      if (isinteger(h)) y=(int)h;
   }

   // compute the new size
   verticalScrollBarNeeded=true;
   delta_h := _twips_per_pixel_y() * p_line_height;
   if (line_count>=1 && y > delta_h*line_count) {
      if (line_count < 4) line_count = 4;
      y = delta_h*line_count;
      verticalScrollBarNeeded=false;
   } else if (y < delta_h*4) {
      y = delta_h*4;
      verticalScrollBarNeeded=false;
   } else if (y > (form_height*3) intdiv 4) {
      y = (form_height*3) intdiv 4;
   }

   //say("AutoCompleteUpdateListHeight: screen_height="screen_height" y="y" p_y="p_active_form.p_y" logical_screen_height="_dy2ly(SM_TWIP,screen_height));
   if (screen_height > 0 &&  p_active_form.p_y + y > _dy2ly(SM_TWIP,screen_height)) {
      y = _dy2ly(SM_TWIP,screen_height) - p_active_form.p_y;
      verticalScrollBarNeeded=true;
   }

   // snap position of form to even line position
   border_width := _dy2ly(SM_TWIP,_TreeGetBorderWidth());
   y = ((y+delta_h intdiv 2) intdiv delta_h) * delta_h + _top_height()*2 + 2*border_width;

   // update the tree and form height
   p_height = y;
   _nocheck _control ctlsizebar;
   p_active_form.ctlsizebar.p_y = p_height;
   p_active_form.p_height = p_active_form.ctlsizebar.p_y + p_active_form.ctlsizebar.p_height;
   return y;
}

void ctltree.lbutton_double_click()
{
   gAutoCompleteResults.allowImplicitReplace=true;
   AutoCompleteRunCommand();
}

static bool AutoCompleteIsOnCategoryNode(int index)
{
   // check that we aren't on a category node
   editor_wid := AutoCompleteGetEditorWid();
   lang := editor_wid? editor_wid.p_LangId : "";
   auto_complete_options := AutoCompleteGetOptionsMaybeShowCategories(lang);
   if (auto_complete_options & AUTO_COMPLETE_SHOW_CATEGORIES) {
      if (index <= 0 || _TreeGetParentIndex(index) == TREE_ROOT_INDEX) {
         return true;
      }
   }
   return false;
}

void ctltree.on_change(int reason, int index)
{
   //say("reason="reason" CHANGE_SELECTED="CHANGE_SELECTED" index="index);
   switch (reason) {
   case CHANGE_SELECTED:
      // tree can be temporarily disabled by AutoCompleteDeselect()
      if (!p_enabled || index == TREE_ROOT_INDEX) {
         gAutoCompleteResults.wordIndex=-1;
         AutoCompleteShowComments(false);
         _bbhelp('C');
         return;
      }

      // check that we aren't on a category node
      if (AutoCompleteIsOnCategoryNode(index)) {
         p_AlwaysColorCurrent=false;
         gAutoCompleteResults.wordIndex=-1;
         AutoCompleteShowComments(false);
         _bbhelp('C');
         return;
      }
      
      // check if the current item has changed from what we think it is.
      word_index := gAutoCompleteResults.wordIndex;
      user_index := _TreeGetUserInfo(index);
      if (!p_AlwaysColorCurrent && gAutoCompleteResults.isActive) {
         if (word_index < 0) {
            if (user_index < 0 || user_index >= gAutoCompleteResults.words._length()) {
               return;
            }
            gAutoCompleteResults.wordIndex = user_index;
         }
         gAutoCompleteResults.allowImplicitReplace=true;
         gAutoCompleteResults.allowShowInfo=true;
         p_AlwaysColorCurrent = true;
      }

      // if the item has changed, make the necessary adjustments.
      if (user_index != word_index) {
         gAutoCompleteResults.wordIndex = user_index;
         if (p_active_form.p_visible) {
            AutoCompleteShowInfo();
            AutoCompleteStartTimer();
         }
      }
   }
}

void ctltree.ESC()
{
   auto_complete_options := AutoCompleteGetOptions();
   if (gAutoCompleteResults.origLineContent!=null && !(auto_complete_options & AUTO_COMPLETE_NO_INSERT_SELECTED)) {
      replace_line(gAutoCompleteResults.origLineContent);
      p_col=gAutoCompleteResults.origCol;
   }
   AutoCompleteTerminate();
}

///////////////////////////////////////////////////////////////////////////////
/**
 * Kill the timer used to update the auto-complete information,
 * including comments and the rest of the word.
 */
static void AutoCompleteKillTimer()
{
   if (gAutoCompleteResults.timerId != -1) {
      _kill_timer(gAutoCompleteResults.timerId);
      gAutoCompleteResults.timerId = -1;
   }
}
/**
 * Start the auto complete timer, whose callback is used
 * to update the auto-complete comments.
 */
static void AutoCompleteStartTimer()
{
   AutoCompleteKillTimer();
   if (AutoCompleteActive() && gAutoCompleteResults.allowShowInfo) {
      int timer_delay=max(100,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
      gAutoCompleteResults.timerId = _set_timer(timer_delay, AutoCompleteShowComments);
   }
}


///////////////////////////////////////////////////////////////////////////////
/**
 * Kill auto completion if we switch buffers.
 */
void _switchbuf_autocomplete()
{
   // on got focus
   if (arg(2)=='W' && gAutoCompleteResults.editor == p_window_id) {
      return;
   }
   if (gAutoCompleteResults.ignoreSwitchBufAndModuleLoadEvents) {
      return;
   }
   // kill auto complete
   AutoCompleteTerminate();
}
/**
 * Kill auto complete if we load a new module
 */
void _on_load_module_autocomplete(_str module)
{
   if (gAutoCompleteResults.ignoreSwitchBufAndModuleLoadEvents) {
      return;
   }
   // kill auto complete
   AutoCompleteTerminate();
}

////////////////////////////////////////////////////////////////////////////////
/** 
 * Force the auto-complete information to update again if the tag files change.
 */
void _TagFileAddRemove_autocomplete(_str file_name, _str options)
{
   if (!_haveContextTagging()) return;
   if (AutoCompleteActive()) {
      editorctl_wid := AutoCompleteGetEditorWid();
      if (editorctl_wid <= 0) return;
      editorctl_wid.p_ModifyFlags &= ~(MODIFYFLAG_AUTO_COMPLETE_UPDATED); 
   }
}
/** 
 * Force the auto-complete information to update again if the a tag file is 
 * marked as updated.
 */
void _TagFileRefresh_autocomplete()
{
   if (!_haveContextTagging()) return;
   if (AutoCompleteActive()) {
      editorctl_wid := AutoCompleteGetEditorWid();
      if (editorctl_wid <= 0) return;

      // DJB - don't do this because it causes auto-complete to refresh
      // just because the current buffer was retagged by background tagging
      // which can effect what item is selected (but not really produce any
      // other meaningful results).

      //editorctl_wid.p_ModifyFlags &= ~(MODIFYFLAG_AUTO_COMPLETE_UPDATED); 
   }
}

