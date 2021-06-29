/////////////////////////////////////////////////////////////////////////////////////
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
#include "diff.sh"
#include "minihtml.sh"
#import "combobox.e"
#import "complete.e"
#import "context.e"
#import "se/datetime/DateTime.e"
#import "se/datetime/DateTimeInterval.e"
#import "se/tags/TaggingGuard.e"
#import "diff.e"
#import "diffedit.e"
#import "diffmf.e"
#require "se/diff/DiffSession.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "ini.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "picture.e"
#import "saveload.e"
#import "sellist.e"
#import "seltree.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "taggui.e"
#import "tags.e"
#import "tbcontrols.e"
#import "varedit.e"
#import "help.e"
#import "math.e"
#endregion

using namespace se.diff;
using namespace se.datetime;

defeventtab _diffsetup_form;
#define SOURCE_DIFF_TOGGLE_ENABLE_DISABLE  0

static const SETUP_DIALOG_HEIGHT=    7500;
static const SETUP_DIALOG_MIN_WIDTH= 11145;

void ctlfile_list_open.lbutton_up()
{
   filename := ctlpath1.p_text;
   initialDirectory := absolute(filename);
   if ( !isdirectory(initialDirectory) ) {
      initialDirectory = _file_path(initialDirectory);
   }
   result := _OpenDialog('-modal',
                      '',                   // Dialog Box Title
                      'Select file to diff',                   // Initial Wild Cards
                      '',
                      OFN_FILEMUSTEXIST,
                      '',
                      '',
                      initialDirectory
                      );
   if ( result!="" ) {
      ctlfile_list.p_text = result;
   }
}
//////////////////////////////////////////////////////////////////////////////
// handle resizing form, moving vertical divider between tag files
// on the left and source files on the left.
//
_divider.lbutton_down()
{
   clientWidth  := p_active_form.p_width;
   _ul2_image_sizebar_handler(ctlok.p_width, clientWidth-200);
}


void _diffsetup_form.on_resize()
{
   clientWidth  := p_width;
   clientHeight := p_height;

   xbuffer := ctlsession_tree.p_x;
   
   ctlsession_tree.p_redraw = false;
   //ctlsession_tree.p_redraw = true;

   if ( ctlsession_tree.p_visible ) {
      ctlsstab1.p_x = _divider.p_x_extent;
   }

   ctlsstab1.p_width = (clientWidth-xbuffer) - (_divider.p_x_extent);
   ctlsession_tree.p_width = _divider.p_x-xbuffer;

   ctlsstab1.sizeFilesFrame();
}

static void sizePathFrame(int tabClientWidth)
{
   pictureWID := p_child;
   pathWID := pictureWID.p_child;
   button1WID := pathWID.p_next;
   //button2WID := button1WID.p_next;
   typeWID := button1WID.p_next;
   //buttonBufferMiddle := button2WID.p_x - (button1WID.p_x_extent);
   buttonBufferX := button1WID.p_x - (pathWID.p_x_extent);
   buttonSpace := buttonBufferX + button1WID.p_width+pathWID.p_x;

   frameWidth := tabClientWidth - (2*p_x);
   p_width = pictureWID.p_width = frameWidth;

   typeWID.p_width = pathWID.p_width = (frameWidth - pathWID.p_x) - buttonSpace;
   button1WID.p_x = pathWID.p_x_extent+buttonBufferX;
}

static void sizeFilesFrame()
{
   tabClientWidth  := p_child.p_width;
   padding := ctlsession_tree.p_x;
   ctlminihtml1.p_width = (tabClientWidth - ctlminihtml1.p_x) - padding;

   ctlpath1_frame.sizePathFrame(tabClientWidth);
   ctlpath2_frame.sizePathFrame(tabClientWidth);

   frameWidth:=tabClientWidth-2*ctlfolderoptions.p_x;
   ctlfolderoptions.p_width=frameWidth;

   ctlfilespecs.p_width = frameWidth - (ctlfilespecs.p_x+ctlfilespecs_label.p_x);
   ctlexclude_filespecs.p_width = frameWidth - (ctlexclude_filespecs.p_x+ctlfilespecs_label.p_x);
   ctlfile_list.p_width = frameWidth - (ctlexclude_filespecs.p_x+ctlfilespecs_label.p_x+ctlfile_list_open.p_width);

   ctlfile_list_open.p_x = ctlfile_list.p_x_extent/*-(_twips_per_pixel_x()*2)*/;
}

void ctlcode_diff.lbutton_up()
{
   origChangeDialog := setChangingDialog(true);

   if ( p_value ) {
      ctldiff_code.p_picture = _pic_diff_code_bitmap;
   }else{
      ctldiff_code.p_picture = _pic_del_diff_code_bitmap;
   }
   max_button_height := ctlpath2_frame.p_y - (ctlpath1_frame.p_y_extent);
   ctldiff_code.resizeToolButton(max_button_height);

   _control ctlcode_diff_skip_comments;
   _control ctlcode_diff_skip_line_numbers;
   _control ctlcode_diff_use_token_mapping;
   _control ctlcode_diff_edit_token_mapping;
   ctlcode_diff_skip_comments.p_enabled = p_value!=0;
   ctlcode_diff_skip_line_numbers.p_enabled = p_value!=0;
   ctlcode_diff_use_token_mapping.p_enabled = p_value!=0;
   ctlcode_diff_edit_token_mapping.p_enabled = (p_value!=0 && ctlcode_diff_use_token_mapping.p_value!=0);

   setChangingDialog(origChangeDialog);
}

void ctlcode_diff_skip_comments.lbutton_up()
{
   origChangeDialog := setChangingDialog(true);
   setChangingDialog(origChangeDialog);
}
void ctlcode_diff_skip_line_numbers.lbutton_up()
{
   origChangeDialog := setChangingDialog(true);
   setChangingDialog(origChangeDialog);
}
void ctlcode_diff_use_token_mapping.lbutton_up()
{
   origChangeDialog := setChangingDialog(true);
   _control ctlcode_diff_edit_token_mapping;
   ctlcode_diff_edit_token_mapping.p_enabled = (p_value!=0 && ctlcode_diff.p_value!=0);
   setChangingDialog(origChangeDialog);
}

void ctlcode_diff_edit_token_mapping.lbutton_up()
{
   // translate semicolon separators to tabs for tree columns
   cap_array := def_sourcediff_token_mappings;
   foreach (auto i => auto pair in def_sourcediff_token_mappings) {
      cap_array[i] = stranslate(pair, "\t", ";");
   }

   // show editable list
   result := select_tree(cap_array,
                         caption:   "Source Diff Token Mapping", 
                         sl_flags:  SL_ADDBUTTON|SL_DELETEBUTTON|SL_GET_TREEITEMS|SL_GET_ITEMS_RAW|SL_SIZABLE|SL_ALLOWMULTISELECT,
                         col_names: "Left,Right",
                         col_flags: (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT) :+ "," (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT),
                         help_item: "Source Diff");
   if (result == COMMAND_CANCELLED_RC) {
      return;
   }

   // translate the results back to semicolon separated items in array
   result = stranslate(result, ";", "\t");
   split(result, "\n", cap_array);
   def_sourcediff_token_mappings = cap_array;
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
void ctlfilespecs.on_change2(int reason,_str value="")
{
   if ( reason==CHANGE_DELKEY_2  
        && p_style==PSCBO_EDIT
        && p_AllowDeleteHistory ) {
      historyFilename := _ConfigPath():+DIFFMAP_FILENAME;
      status := _ini_delete_item(historyFilename,"FilespecsHistory",value);
      _ComboBoxDelete(value);
   }
}
void ctlexclude_filespecs.on_change2(int reason,_str value="")
{
   if ( reason==CHANGE_DELKEY_2  
        && p_style==PSCBO_EDIT
        && p_AllowDeleteHistory ) {
      historyFilename := _ConfigPath():+DIFFMAP_FILENAME;
      status := _ini_delete_item(historyFilename,"ExcludeFilespecsHistory",value);
      _ComboBoxDelete(value);
   }
}
void ctlmismatch_size_date.lbutton_up()
{
   ctlmismatch_date_only.p_enabled = ctlmismatch_size_date.p_value!=0;
}

static const LOAD_BUTTON_CAPTION= 'Previous diff...';

////////////////////////////////////////////////////////////////////////////////
//
// gMapInfo is a hashtable of all of the path mapping information.  For example:
// gMapInfo:['e:\']=g:\<ASCII1>\\rodney
static _str gMapInfo(...):[] {
   if (arg()) ctlpath1.p_user=arg(1);
   return ctlpath1.p_user;
}

////////////////////////////////////////////////////////////////////////////////
// gPath1Names is an array in the order of the path1 entries.  We need this to
// to preserve the order because we cannot count on the order of a hashtable
// Now use _SetDialogInfoHt(Path1Names)
//#define gPath1Names         ctlpath1.p_cb_list_box.p_user

////////////////////////////////////////////////////////////////////////////////
// Set to 1 if the user has typed in the "Path 2" combobox (ctlpath2)
static _str gPath2Modified(...) {
   if (arg()) ctlpath2.p_user=arg(1);
   return ctlpath2.p_user;
}

////////////////////////////////////////////////////////////////////////////////
// Set to 1 if in the SetupMappedPaths function
// Now use _SetDialogInfoHt("gInSetupMappedPaths");
//#define gInSetupMappedPaths ctlpath2.p_cb_list_box.p_user

// Indexes for _SetDialogInfo and _GetDialogInfo
static const RESTORE_FROM_INI=     0;
static const LAST_TEXTBOX_WID=     1;

static int gTimerHandle=-1;

void ctlpath1.on_got_focus()
{
   ArgumentCompletionTerminate();
   ctlmove_path.p_picture = _pic_diff_path_down;
   ctlmove_path.p_message = "Copy Path 1 to Path 2";
   max_button_height := ctlpath2_frame.p_y - (ctlpath1_frame.p_y_extent);
   ctlmove_path.resizeToolButton(max_button_height);
}

void ctlpath2.on_got_focus()
{
   ArgumentCompletionTerminate();
   ctlmove_path.p_picture = _pic_diff_path_up;
   ctlmove_path.p_message = "Copy Path 2 to Path 1";
   max_button_height := ctlpath2_frame.p_y - (ctlpath1_frame.p_y_extent);
   ctlmove_path.resizeToolButton(max_button_height);
}

/**
 * Call with true when modifying textboxes or checkboxes and 
 * with false when done 
 * 
 * @param setting true if programatically setting dialog items
 */
static bool setChangingDialog(bool setting)
{
   orig := getChangingDialog();
   _SetDialogInfoHt("changingDialog",setting);
   return orig;
}

static bool getChangingDialog()
{
   changing := _GetDialogInfoHt("changingDialog");
   if ( changing==null ) {
      changing = false;
   }
   return changing;
}

void ctlmove_path.lbutton_up()
{
   origChangeDialog := setChangingDialog(true);
   curWID := 0;
   lastWID := 0;
   origDiffEditOptions := def_diff_edit_flags;
   def_diff_edit_flags |= DIFFEDIT_NO_AUTO_MAPPING;

   if ( ctlmove_path.p_picture==_pic_diff_path_up ) {
      curWID = ctlpath1;
      lastWID = ctlpath2;
      p_message = "Copy Path 1 to Path 2";
   } else {
      curWID = ctlpath2;
      lastWID = ctlpath1;
      p_message = "Copy Path 2 to Path 1";
   }
   curWID.p_text = lastWID.p_text;
   curWID._set_focus();
   curWID._end_line();

   def_diff_edit_flags = origDiffEditOptions;
   setChangingDialog(origChangeDialog);
}

static void swapPath()
{
   origChangeDialog := setChangingDialog(true);
   curWID := 0;
   lastWID := 0;
   // 3/16/2016
   // Removing "Use file on disk" checkboxes
   //int curCBWID = 0;
   //int lastCBWID = 0;
   completion1 := ctlpath1.p_completion;
   completion2 := ctlpath2.p_completion;

   // Have to set p_completion to keep combo from dropping down when the
   // text is set
   ctlpath1.p_completion = NONE_ARG;
   ctlpath2.p_completion = NONE_ARG;

   origDiffEditOptions := def_diff_edit_flags;
   def_diff_edit_flags |= DIFFEDIT_NO_AUTO_MAPPING;

   // 3/16/2016
   // Removing "Use file on disk" checkboxes
   //_nocheck _control ctlpath1_on_disk;
   //_nocheck _control ctlpath2_on_disk;
   if ( ctlmove_path.p_picture==_pic_diff_path_up ) {
      curWID = ctlpath1;
      // 3/16/2016
      // Removing "Use file on disk" checkboxes
      //curCBWID = ctlpath1_on_disk;

      lastWID = ctlpath2;
      // 3/16/2016
      // Removing "Use file on disk" checkboxes
      //lastCBWID = ctlpath2_on_disk;
   } else {
      curWID = ctlpath2;
      // 3/16/2016
      // Removing "Use file on disk" checkboxes
      //curCBWID = ctlpath2_on_disk;

      lastWID = ctlpath1;
      // 3/16/2016
      // Removing "Use file on disk" checkboxes
      //lastCBWID = ctlpath1_on_disk;
   }

   tempName := curWID.p_text;
   curWID.p_text = lastWID.p_text;
   lastWID.p_text = tempName;

   // 3/16/2016
   // Removing "Use file on disk" checkboxes
   //tempVal := curCBWID.p_value;
   //curCBWID.p_value = lastCBWID.p_value;
   //lastCBWID.p_value = tempVal;

   ctlpath1.p_completion = completion1;
   ctlpath2.p_completion = completion2;

   curWID._set_focus();
   curWID._end_line();

   def_diff_edit_flags = origDiffEditOptions;
   setChangingDialog(origChangeDialog);
}

void ctlswap_path.lbutton_up()
{
   swapPath();
}

static void setLinkButtonPicture()
{
   if ( def_diff_edit_flags&DIFFEDIT_NO_AUTO_MAPPING ) {
      ctllink.p_picture = _pic_del_linked_bitmap;
      ctlauto_mapping.p_value = 0;
   }else{
      ctllink.p_picture = _pic_linked_bitmap;
      ctlauto_mapping.p_value = 1;
   }
   max_button_height := ctlpath2_frame.p_y - (ctlpath1_frame.p_y_extent);
   ctllink.resizeToolButton(max_button_height);
}

static void setDocButtonPicture()
{
   pic_name := name_name(ctlFilenamesOnly.p_picture);
   parse pic_name with pic_name "@" .;
   if ( _file_eq(pic_name, "bbdiff.svg" ) ) {
      ctlFilenamesOnly.p_picture = _pic_del_diff_doc_bitmap;
   }else{
      ctlFilenamesOnly.p_picture = _pic_diff_doc_bitmap;
   }
   max_button_height := ctlpath2_frame.p_y - (ctlpath1_frame.p_y_extent);
   ctlFilenamesOnly.resizeToolButton(max_button_height);
}

void ctllink.lbutton_up(_str value='')
{
   _SetDialogInfoHt("inLinkButton",1);
   if (value=='') {
      // Toggle
      if ( (def_diff_edit_flags&DIFFEDIT_NO_AUTO_MAPPING)) {
         def_diff_edit_flags &= ~DIFFEDIT_NO_AUTO_MAPPING;
      }else{
         def_diff_edit_flags |= DIFFEDIT_NO_AUTO_MAPPING;
      }
   } else {
      if (value) {
         def_diff_edit_flags &= ~DIFFEDIT_NO_AUTO_MAPPING;
      }else{
         def_diff_edit_flags |= DIFFEDIT_NO_AUTO_MAPPING;
      }
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
   setLinkButtonPicture();
   _SetDialogInfoHt("inLinkButton",0);
}

void ctldiff_code.lbutton_up()
{
   _SetDialogInfoHt("inDiffCodeButton",1);
   ctlcode_diff.p_value = (int)!ctlcode_diff.p_value;
   ctlcode_diff.call_event(ctlcode_diff,LBUTTON_UP);
   _SetDialogInfoHt("inDiffCodeButton",0);
}

void ctlFilenamesOnly.lbutton_up()
{
   _SetDialogInfoHt("inFilenamesOnly",1);
   setDocButtonPicture();
   _SetDialogInfoHt("inFilenamesOnly",0);
}

void ctlauto_mapping.lbutton_up()
{
   inLinkButton := _GetDialogInfoHt("inLinkButton");

   // If we are already in code from the ctllink button or the
   // dialog is coming up, stop
   if ( inLinkButton==1 || !p_active_form.p_visible ) return;

   ctllink.call_event(ctlauto_mapping.p_value,ctllink,LBUTTON_UP,'W');
}

static bool OptionsOnly()
{
   SSTABCONTAINERINFO info;
   ctlsstab1._getTabInfo(0,info);
   return ( !info.enabled || ctlsstab1.p_ActiveCaption == 'Options' );
}

void _diffsetup_form.on_load()
{
   ctlpath1._set_focus();
   if (OptionsOnly()) {
      ctltree1._set_focus();
      ctlsstab1.p_ActiveTab=1;
   }else{
      ctlsstab1.p_ActiveTab=0;
   }
   _set_minimum_size(SETUP_DIALOG_MIN_WIDTH, SETUP_DIALOG_HEIGHT);
   _set_maximum_size(-1, SETUP_DIALOG_HEIGHT);
   retrieveDialogGeometry();
}

static void retrieveDialogGeometry()
{
   historyFilename := _ConfigPath():+DIFFMAP_FILENAME;
   _ini_get_value(historyFilename,"SetupGeometry","_divider.p_x",auto x);
   _ini_get_value(historyFilename,"SetupGeometry","dialogWidth",auto width);
   if ( x!="" ) {
      _divider.p_x = (int)x;
   }
   if ( width!="" ) {
      p_active_form.p_width = (int)width;
   }
}

ctlsstab1.on_change(int reason,int tabIndex=0)
{
   switch (reason) {
   case CHANGE_TABACTIVATED:
      if (tabIndex==0) {
         // This keeps the dialog from doing some ugly things if
         // the "Files" tab is activated by pressing F7/F8
         ctlsstab1.refresh();
         ctlok.p_caption="Diff";
         sizeButtons(-250);
      }else if (tabIndex==1) {
         // Options tab activated.
         ctltree1._set_focus();
         ctlok.p_caption="Save Options";
         sizeButtons(250);
      }
      break;
   }
}

static void sizeButtons(int offset)
{
   ctlok.p_width += offset;
   ctlsave_session.p_x += offset;
   ctldeletesession.p_x += offset;
   ctldeletesession.p_next.p_x += offset;
   ctldeletesession.p_next.p_next.p_x += offset;
   ctldeletesession.p_next.p_next.p_next.p_x += offset;
}

static const SESSION_CAPTION_RECENT= "Recent sessions";
static const SESSION_CAPTION_YESTERDAY= "Yesterday";
static const SESSION_CAPTION_TODAY= "Today";
static const SESSION_CAPTION_OLDER= "Older";
static const SESSION_CAPTION_NAMED= "Named sessions";
static const COMPARE_WHOLE_FILES= "Compare lines: all";
static const COMPARE_LINE_RANGE=  "Compare lines: range...";
static const COMPARE_ALL_SYMBOLS= "Compare symbols: all";
static const COMPARE_CUR_SYMBOL=  "Compare symbols: current symbol in file[ $$$ ]...";
static const COMPARE_ONE_SYMBOL=  "Compare symbols: choose symbol...";
static const PRO_ONLY= "(Pro Only)";
static const USERINFO_DELIMITER= "===";

static void setupSessionTree(bool loadFromDisk=false,bool selectMostRecent=false,bool &selectedSession=false)
{
   selectedSession = false;
   wid := p_window_id;
   _control ctlsession_tree;
   p_window_id=ctlsession_tree;
   _TreeDelete(TREE_ROOT_INDEX,'C');

   if ( loadFromDisk ) {
      // We are initializing
      DiffSessionCollection diffSessionData;
      _SetDialogInfoHt("diffSessions",diffSessionData);
   }
   DiffSessionCollection *pdiffSessionData = _GetDialogInfoHtPtr("diffSessions");
   if ( loadFromDisk ) {
      pdiffSessionData->loadSessions();
   }

   recentSessionIndex := _TreeAddItem(TREE_ROOT_INDEX,SESSION_CAPTION_RECENT,TREE_ADD_AS_CHILD,_pic_project,_pic_project);

   todaySessionIndex := _TreeAddItem(recentSessionIndex,SESSION_CAPTION_TODAY,TREE_ADD_AS_CHILD,_pic_project,_pic_project);
   yesterdaySessionIndex := _TreeAddItem(todaySessionIndex,SESSION_CAPTION_YESTERDAY,0,_pic_project,_pic_project);
   olderSessionIndex := _TreeAddItem(yesterdaySessionIndex,SESSION_CAPTION_OLDER,0,_pic_project,_pic_project);

   namedSessionIndex := _TreeAddItem(TREE_ROOT_INDEX,SESSION_CAPTION_NAMED,TREE_ADD_AS_CHILD,_pic_project,_pic_project);

   insertSessionsInTree(recentSessionIndex,namedSessionIndex,todaySessionIndex,yesterdaySessionIndex,olderSessionIndex,*pdiffSessionData);

   selectIndex := recentSessionIndex;

   if ( selectMostRecent ) {
      mostRecentIndex := _TreeGetFirstChildIndex(recentSessionIndex);
      if ( mostRecentIndex>-1 ) {
         _TreeGetInfo(mostRecentIndex,auto state,auto nonCurrentBMIndex);

         // If there is a folder here (like "Today" or "yesterday", get
         // the first child of that.
         if ( nonCurrentBMIndex==_pic_project ) {
            mostRecentIndex = _TreeGetFirstChildIndex(mostRecentIndex);
         }
         selectIndex = mostRecentIndex;
         if ( selectIndex>-1 ) {
            _TreeSetCurIndex(selectIndex);
            sessionTreeOnChange(CHANGE_SELECTED,selectIndex);
            selectedSession = true;
         }
      }
   }

   p_window_id=wid;
}

static void setSymbolAndLineRange(_str pathNum,_str symbolName,int firstLine,int lastLine)
{
   if ( symbolName!="" ) {
      findCaption(COMPARE_ONE_SYMBOL);
      setSymbolCaption(pathNum,symbolName);
      setSymbolVisible(pathNum,true);
      setLineRangeCaption(pathNum,firstLine,lastLine);
      setLineRangeVisible(pathNum,true);
   }else{
      setSymbolVisible(pathNum,false);
      if ( firstLine!=0 ) {
         setLineRangeCaption(pathNum,firstLine,lastLine);
         setLineRangeVisible(pathNum,true);
      }else{
         setLineRangeCaption(pathNum,0,0);
         setLineRangeVisible(pathNum,false);
      }
   }
}

static bool isValidSessionNode(int nodeIndex)
{
   valid := false;

   _TreeGetInfo(nodeIndex,auto state,auto bmIndex);
   valid = nodeIndex != TREE_ROOT_INDEX && bmIndex != _pic_project;

   return valid;
}

static bool isNamedSessionNode(int nodeIndex)
{
   valid := false;

   _TreeGetInfo(nodeIndex,auto state,auto bmIndex);
   if ( bmIndex!=_pic_project ) {
      for ( ;; ) {
         nodeIndex = _TreeGetParentIndex(nodeIndex);
         if ( nodeIndex<0 ) break;
         _TreeGetInfo(nodeIndex,state,bmIndex);
         if ( bmIndex==_pic_project ) {
            cap := _TreeGetCaption(nodeIndex);
            if ( cap == SESSION_CAPTION_NAMED ) {
               valid = true;
               break;
            }
         }
      }
   }
   return valid;
}

static bool isProDiffRestore(DIFF_SETUP_DATA &curSetupData)
{
   if ( isdirectory(curSetupData.file1.fileName) &&
        isdirectory(curSetupData.file2.fileName)
        ) {
      return true;
   }
   if ( curSetupData.Recursive!=0 ) {
      return true;
   }
   if ( curSetupData.file1.symbolName!="" ||
        curSetupData.file2.symbolName!="" ) {
      return true;
   }
   return false;
}

static void sessionTreeOnChange(int reason,int index)
{
   curIndex := _TreeCurIndex();
   if ( curIndex>-1 && isValidSessionNode(curIndex) ) {
      parse _TreeGetUserInfo(curIndex) with auto sessionDate (USERINFO_DELIMITER) auto sessionID;
      sessionName := "";
      if ( sessionID=="" ) {
         sessionName = _TreeGetCaption(index);
      }
      DiffSessionCollection *pdiffSessionData = _GetDialogInfoHtPtr("diffSessions");
      DIFF_SETUP_DATA curSetupData = pdiffSessionData->getSession(sessionID);
      if ( curSetupData!=null ) {
   
         origChangingDialog := setChangingDialog(true);
         if ( !_haveProDiff() && isProDiffRestore(curSetupData) ) {
            return;
         }
         ctlpath1.p_text = curSetupData.file1.fileName;
         ctlpath2.p_text = curSetupData.file2.fileName;
         ctlsymbol1combo.fillInSymbolCombo();
         ctlsymbol2combo.fillInSymbolCombo();

         ctlfilespecs.p_text = curSetupData.FileSpec;
         ctlexclude_filespecs.p_text = curSetupData.ExcludeFileSpec;
         setChangingDialog(origChangingDialog);

         // 3/16/2016
         // Removing "Use file on disk" checkboxes
         //ctlpath1_on_disk.p_value = (int)curSetupData.file1.useDisk;
         //ctlpath2_on_disk.p_value = (int)curSetupData.file2.useDisk;
         loadFile2FromDisk := _file_eq(curSetupData.file1.fileName,curSetupData.file2.fileName);
   
         if ( curSetupData.file1.symbolName!="" ) {
            curSetupData.file1.firstLine=0;
            curSetupData.file1.lastLine=0;
            status := _GetLineRangeWithFunctionInfo(curSetupData.file1.fileName,curSetupData.file1.symbolName,auto TagInfo="",curSetupData.file1.firstLine,curSetupData.file1.lastLine,true,false);
            if ( !status ) {
               setLineRangeCaption('1',curSetupData.file1.firstLine,curSetupData.file1.lastLine);
               setLineRangeVisible('1',true);

               setSymbolCaption('1',curSetupData.file1.symbolName);
               setSymbolVisible('1',true);
            }
         }
   
         if ( curSetupData.file2.symbolName!="" ) {
            curSetupData.file2.firstLine=0;
            curSetupData.file2.lastLine=0;
            status := _GetLineRangeWithFunctionInfo(curSetupData.file2.fileName,curSetupData.file2.symbolName,auto TagInfo="",curSetupData.file2.firstLine,curSetupData.file2.lastLine,true,loadFile2FromDisk);
         }
         ctlsymbol1combo.setSymbolAndLineRange('1',curSetupData.file1.symbolName,curSetupData.file1.firstLine,curSetupData.file1.lastLine);
         ctlsymbol2combo.setSymbolAndLineRange('2',curSetupData.file2.symbolName,curSetupData.file2.firstLine,curSetupData.file2.lastLine);
         if ( curSetupData.DiffTags ) {
            ctlsymbol1combo.findCaption(COMPARE_ALL_SYMBOLS);
         }
         SetDiffCompareOptionsOnDialog(curSetupData.compareOptions);

         ctlrecursive.p_value = (int)curSetupData.Recursive;
         ctlrun_in_foreground.p_value = (int)curSetupData.runInForeground;
#if 0
         // Only set recursive if it was set in this session and this is a
         // multi-file diff.  This way the diff will be right when switching
         // from a file to a multi-file diff.
         if ( ctltype_mf.p_value && ctltype_mf.p_enabled ) {
            ctlrecursive.p_value = (int)curSetupData.Recursive;
            ctlrun_in_foreground.p_value = (int)curSetupData.runInForeground;
         } else {
            ctltype_text.p_value = 1;
         }
#endif
      }


      if ( curSetupData.file1.symbolName==""  && curSetupData.file2.symbolName=="" ) {
         if ( curSetupData.file1.firstLine >0 ) {
            setLineRangeCaption('1',curSetupData.file1.firstLine,curSetupData.file1.lastLine);
            setLineRangeVisible('1',true);
            ctlsymbol1combo.findCaption(COMPARE_LINE_RANGE);
         }
         if ( curSetupData.file2.firstLine>0 ) {
            setLineRangeCaption('2',curSetupData.file2.firstLine,curSetupData.file2.lastLine);
            setLineRangeVisible('2',true);
            ctlsymbol2combo.findCaption(COMPARE_LINE_RANGE);
         }
      }
      if ( curSetupData.fileListFile==null ) {
         ctlfile_list.p_text = "";
      } else {
         ctlfile_list.p_text = curSetupData.fileListFile;
      }

      ctldeletesession.p_enabled = true;
      _SetDialogInfoHt("lastSessionID",curSetupData.sessionID);
   }else{
      ctldeletesession.p_enabled = false;
   }
}

void ctlsession_tree.on_change(int reason,int index)
{
   if ( reason==CHANGE_LEAF_ENTER ) {
      if ( ctlsstab1.p_ActiveCaption!='Options' ) {
         ctlok.call_event(ctlok,LBUTTON_UP);
         return;
      }
   }
   if ( reason==CHANGE_BUTTON_SIZE ) {
      return;
   }
   origChangeDialog := getChangingDialog();
   if ( origChangeDialog ) {
      return;
   }
   setChangingDialog(true);
   sessionTreeOnChange(reason,index);
   setChangingDialog(origChangeDialog);
}

static void insertSessionsInTree(int recentSessionIndex,int namedSessionIndex,int todaySessionIndex,
                                 int yesterdaySessionIndex,int olderSessionIndex,
                                 DiffSessionCollection &allDiffSessionData)
{
   se.datetime.DateTimeInterval todayTest(DTI_AUTO_TODAY);
   se.datetime.DateTimeInterval yesterdayTest(DTI_AUTO_YESTERDAY);

   numTodaySessions := numYesterdaySessions := numOlderSessions := 0;
   allDiffSessionData.enumerateSessionIDs(auto sessionIDs);
   foreach ( auto curSessionID in sessionIDs ) {
      curDiffSession := allDiffSessionData.getSession(curSessionID);
      if ( curDiffSession.sessionName==DiffSessionCollection.getDefaultSessionName() ) {
         se.datetime.DateTime sessionDate = se.datetime.DateTime.fromString( curDiffSession.sessionDate );
         parentIndex := -1;
   
         if ( todayTest.filter(sessionDate) ) {
            ++numTodaySessions;
         }else if ( yesterdayTest.filter(sessionDate) ) {
            ++numYesterdaySessions;
         }else{
            ++numOlderSessions;
         }
      }
   }
   foreach ( curSessionID in sessionIDs ) {
      curDiffSession := allDiffSessionData.getSession(curSessionID);
      bitmapIndex := getBitmapIndexForSession(curDiffSession);
      cap := curDiffSession.sessionName;
      if ( curDiffSession.sessionName==DiffSessionCollection.getDefaultSessionName()  ) {
         if ( _last_char(curDiffSession.file1.fileName)==FILESEP &&
              _last_char(curDiffSession.file2.fileName)==FILESEP ) {
            cap = curDiffSession.file1.fileName:+" <===> ":+curDiffSession.file2.fileName;
         }else{
            justname1 := _strip_filename(curDiffSession.file1.fileName,'p');
            justname2 := _strip_filename(curDiffSession.file2.fileName,'p');
            if ( _file_eq(justname1,justname2) ) {
               cap = justname1;
            }else{
               cap = justname1:+" <===> ":+justname2;
            }
         }
         se.datetime.DateTime sessionDate = se.datetime.DateTime.fromString(curDiffSession.sessionDate);
         parentIndex := -1;

         if ( todayTest.filter(sessionDate) ) {
            parentIndex = todaySessionIndex;
         }else if ( yesterdayTest.filter(sessionDate) ) {
            parentIndex = yesterdaySessionIndex;
         }else{
            parentIndex = olderSessionIndex;
         }

         newIndex := _TreeAddItem(parentIndex,cap,TREE_ADD_AS_CHILD,bitmapIndex,bitmapIndex,-1,0,curDiffSession.sessionDate:+USERINFO_DELIMITER:+curSessionID);
      }else{
         cap = curDiffSession.sessionName;
         newIndex := _TreeAddItem(namedSessionIndex,cap,TREE_ADD_AS_CHILD,bitmapIndex,bitmapIndex,-1,0,curDiffSession.sessionDate:+USERINFO_DELIMITER:+curSessionID);
      }
   }
   deleteOrSort(numTodaySessions,todaySessionIndex,'D');
   deleteOrSort(numYesterdaySessions,yesterdaySessionIndex,'D');
   deleteOrSort(numOlderSessions,olderSessionIndex,'D');
   _TreeSortCaption(namedSessionIndex);
}

static void deleteOrSort(int numSessions,int index,_str sortOptions)
{
   if ( numSessions>0 ) {
      _TreeSortUserInfo(index,sortOptions);
   }else{
      _TreeDelete(index);
   }
}

static void oncreateMultiFileAndCaption()
{
   if ( !_haveProDiff() ) {
#if 0
      ctltype_mf.p_caption = "Compare Two Folders "PRO_ONLY;
      ctltype_mf.p_enabled = false;
#endif
      ctlrecursive.p_enabled = false;
      ctlrun_in_foreground.p_enabled = false;

      ctlfilespecs_label.p_enabled = false;
      ctlfilespecs.p_enabled = false;
      ctlexclude_filespecs_label.p_enabled = false;
      ctlexclude_filespecs.p_enabled = false;
      ctlfile_list.p_prev.p_enabled = false;
      ctlfile_list.p_enabled = false;
      ctlfile_list_open.p_enabled = false;
      ctlload.p_enabled = false;
      p_active_form.p_caption = "DIFFzilla"VSREGISTEREDTM" Standard";
      //ctlfolderoptions.p_enabled=false;
      ctlfolderoptions.p_caption='Folder options 'PRO_ONLY;
   } else {
      p_active_form.p_caption = "DIFFzilla"VSREGISTEREDTM" Pro";
#if 0
      if ( _MFDiffStillFillingIn() ) {
         ctltype_text.p_value=1;
         ctltype_mf.p_enabled = false;
         ctlrecursive.p_enabled = false;
         ctlrun_in_foreground.p_enabled = false;
      }
#endif
   }
}

static int getBitmapIndexForSession(DIFF_SETUP_DATA diffSession)
{
   bitmapIndex := 0;
   if ( _last_char(diffSession.file1.fileName)==FILESEP &&
        _last_char(diffSession.file2.fileName)==FILESEP ) {
      bitmapIndex = _pic_fldopen;
   }else{
      if ( diffSession.file1.symbolName!="" || diffSession.file2.symbolName!="" ) {
         bitmapIndex = _pic_diff_one_symbol;
      }else if ( diffSession.DiffTags ) {
         bitmapIndex = _pic_diff_all_symbols;
      }else{
         bitmapIndex = _pic_file;
      }
   }
   return bitmapIndex;
}


void ctlok.on_create(_str filename1='',bool OptionsOnly=false,
                     bool RestoreFromINI=false,DIFF_INFO info=null,
                     bool removeDialogOptions=false)
{
   origChangeDialog := setChangingDialog(true);
   gTimerHandle=-1;
#if 0 //3:58pm 3/1/2010
   setOkButtonCaption();
#endif

   // Old line number data is probably invalid...
   ClearLineNumbers();

   setupFont();
   _diffsetup_form_initial_alignment();
   oncreateMultiFileAndCaption();
   oncreateFiles(filename1,OptionsOnly,info);

   origDiffCode := ctldiff_code.p_picture;
   // Have to do this first, mostly to be sure that ctlrecursive.p_value is set
   // so that if the user changes from a file diff restored from the last 
   // session to a multi-file diff, the option is still set properly

   if ( def_diff_edit_flags&DIFFEDIT_CURFILE_INIT ) {
      // Use the filename passed in.  This will be the current filename or
      // the directory name
      ctlpath1.p_text=filename1;
   }else{
      _retrieve_prev_form();
   }
   setupSessionTree(true,!(def_diff_edit_flags&DIFFEDIT_CURFILE_INIT),auto selectedSession);
   if ( !(def_diff_edit_flags&DIFFEDIT_CURFILE_INIT) && !selectedSession ) {
      _retrieve_prev_form();
   }
   ctldiff_code.p_picture = origDiffCode;
#if 0
   if ( _MFDiffStillFillingIn() ) {
      ctlrun_in_foreground.p_enabled = false;
   }
#endif

   oncreateOptions(removeDialogOptions);
   _SetDialogInfo(RESTORE_FROM_INI,RestoreFromINI);
   ctlsymbol1combo.call_event(CHANGE_CLINE,ctlsymbol1combo,ON_CHANGE,'W');
   ctlsymbol2combo.call_event(CHANGE_CLINE,ctlsymbol2combo,ON_CHANGE,'W');
#if SOURCE_DIFF_TOGGLE_ENABLE_DISABLE
   enableDisableSourceDiff();
#endif 
   ctlpath1._set_sel(1,ctlpath1.p_text._length()+1);

   if ( info!=null ) {
      // 09/30/2016 -- force file diff mode
      //ctltype_text.p_value=1;

      if ( info.iViewID1.p_buf_name=="" ) {
         ctlpath1.p_text = "Untitled<"info.iViewID1.p_buf_id'>';
      } else {
         ctlpath1.p_text = info.iViewID1.p_buf_name;
      }
      if ( info.iViewID2.p_buf_name=="" ) {
         ctlpath2.p_text = "Untitled<"info.iViewID2.p_buf_id'>';
      } else {
         ctlpath2.p_text = info.iViewID2.p_buf_name;
      }
      if ( info.lineRange1!=null && info.lineRange1!="" ) {
         status := ctlsymbol1combo.p_cb_list_box._lbsearch(COMPARE_LINE_RANGE);
         if ( !status ) {
            ctlsymbol1combo.p_text=ctlsymbol1combo.p_cb_list_box._lbget_text();
            text:=ctlsymbol1combo.p_cb_list_box._lbget_text();
            parse info.lineRange1 with auto firstLine1 '-' auto lastLine1;
            ctlpath1_firstline.p_text = firstLine1;
            ctlpath1_lastline.p_text = lastLine1;
         }
      }
      if ( info.lineRange2!=null && info.lineRange2!="" ) {
         status := ctlsymbol2combo.p_cb_list_box._lbsearch(COMPARE_LINE_RANGE);
         if ( !status ) {
            ctlsymbol2combo.p_text=ctlsymbol2combo.p_cb_list_box._lbget_text();
            text:=ctlsymbol2combo.p_cb_list_box._lbget_text();
            parse info.lineRange2 with auto firstLine2 '-' auto lastLine2;
            ctlpath2_firstline.p_text = firstLine2;
            ctlpath2_lastline.p_text = lastLine2;
         }
      }
      // 3/16/2016
      // Removing "Use file on disk" checkboxes
      //ctlpath2_on_disk.p_value = 0;
   }

   setChangingDialog(origChangeDialog);
   ctlcode_diff_skip_comments.p_enabled = ctlcode_diff.p_value!=0;
   ctlcode_diff_skip_line_numbers.p_enabled = ctlcode_diff.p_value!=0;
   ctlcode_diff_use_token_mapping.p_enabled = ctlcode_diff.p_value!=0;
   ctlcode_diff_edit_token_mapping.p_enabled = ctlcode_diff.p_value!=0;
}

static void _diffsetup_form_initial_alignment()
{
   max_button_height := ctlpath2_frame.p_y - (ctlpath1_frame.p_y_extent);
   ctllink.resizeToolButton(max_button_height);
   ctlmove_path.resizeToolButton(max_button_height);
   ctlswap_path.resizeToolButton(max_button_height);
   ctldiff_code.resizeToolButton(max_button_height);
   ctlFilenamesOnly.resizeToolButton(max_button_height);

   // size the buttons to the textbox
   rightAlign := ctlpath1_pic.p_width - ctlpath1.p_x;
   sizeBrowseButtonToTextBox(ctlpath1.p_window_id, ctlbrowsedir.p_window_id);
   sizeBrowseButtonToTextBox(ctlpath2.p_window_id, ctlimage1.p_window_id);
   sizeBrowseButtonToTextBox(ctlfilespecs_label.p_window_id, ctlinclude_help.p_window_id);
   sizeBrowseButtonToTextBox(ctlexclude_filespecs_label.p_window_id, ctlexclude_help.p_window_id);
   sizeBrowseButtonToTextBox(ctlfile_list.p_window_id, ctlfile_list_open.p_window_id);
   label_edge := max(ctlfilespecs_label.p_x_extent,  ctlexclude_filespecs_label.p_x_extent, ctlfile_list_label.p_x_extent);
   ctlinclude_help.p_x = label_edge+_dx2lx(SM_TWIP,2);
   ctlexclude_help.p_x = ctlinclude_help.p_x;
   ctlfilespecs.p_x = ctlinclude_help.p_x_extent+_dx2lx(SM_TWIP,2);
   ctlexclude_filespecs.p_x = ctlfilespecs.p_x;
   ctlfile_list.p_x = ctlfilespecs.p_x;
   ctlfilespecs.p_x_extent = ctlpath2.p_x_extent;
   ctlexclude_filespecs.p_width = ctlfilespecs.p_width;
   ctlfile_list.p_width = ctlfilespecs.p_width;

   // keep these buttons from getting smooshed
   buttonSpace := 10;
   px := ctlsstab1.p_child.p_width - (ctllink.p_width + ctlmove_path.p_width + ctlswap_path.p_width +
                                      ctldiff_code.p_width + 4 * buttonSpace);
   px = px intdiv 2;
   alignControlsHorizontal(px, ctllink.p_y, buttonSpace,
                           ctllink.p_window_id,
                           ctlmove_path.p_window_id,
                           ctlswap_path.p_window_id,
                           ctldiff_code.p_window_id,
                           ctlFilenamesOnly.p_window_id);

}

static void setupFont()
{
   ctlminihtml1._minihtml_UseDialogFont();
}

static void ClearLineNumbers()
{
   origChangeDialog := setChangingDialog(true);
   ctlpath1_firstline.p_text='';
   ctlpath1_lastline.p_text='';
   ctlpath2_firstline.p_text='';
   ctlpath2_lastline.p_text='';
   setChangingDialog(origChangeDialog);
}

static void oncreateFiles(_str filename1,bool OptionsOnly,DIFF_INFO &info=null)
{
   origChangeDialog := setChangingDialog(true);
   do {
      if (OptionsOnly) {
         ctlsstab1._setEnabled(0,0); // Files tab
         ctlsstab1.p_ActiveTab=1;    // Options tab
         ctlsession_tree.p_visible = ctlsession_tree.p_prev.p_visible = false;
         ctlsstab1.p_x = ctlsession_tree.p_x;
         ctlsave_session.p_visible = false;
         ctlsave_session.p_next.p_next.p_x = ctlsave_session.p_x;

         ctldeletesession.p_visible = false;
         ctldeletesession.p_next.p_next.p_x = ctldeletesession.p_x;

         break;
      }
      ctlminihtml1.p_backcolor=0x80000022;
      _str HtmlLine='To compare directories, set <B>Path 1</B> and <B>Path 2</B> to directory names, and then set <B>Filespecs</B> to a semicolon deilimited list of wildcards (<B>ex:</B> *.cpp;*.h), and <B>Exclude Filespecs</B> to a wildcard list you do not want included in the compare (<B>ex:</B>junk*;.svn/).<P>Use the <B>'LOAD_BUTTON_CAPTION'</B> button to load results of saved directory compares.<P>When comparing files, if the filenames only differ by path, you only need to specify a directory for <B>Path 2</B>.<P>Use F7/F8 to select past dialog responses.';
      ctlminihtml1.p_text=HtmlLine;
      if (def_diff_edit_flags & DIFFEDIT_CURFILE_INIT) {
         // Use the filename passed in.  This will be the current filename or
         // the directory name
         ctlpath1.p_text=filename1;
      }
   
      wid := p_window_id;
      p_window_id=ctlpath2;
      _lbbottom();
      _lbadd_item('');
      LoadHistory("Path2History");
      p_window_id=wid;
#if 0
      if (!ctltype_text.p_value && !dialogInFolderMode()) {
         // If no radio button is selected, select one
   
         ctltype_text.p_value=1;
      }
#endif
      //ctlmore.call_event(ctlmore,LBUTTON_UP);
   
      _str MapInfo:[]=null;
      _str Path1Names[]=null;
      LoadMapInfo(Path1Names,MapInfo);
      gMapInfo(MapInfo);
      _SetDialogInfoHt("Path1Names",Path1Names);

      if ( def_diff_flags&DIFF_NO_SOURCE_DIFF ) {
         ctldiff_code.p_picture = _pic_del_diff_code_bitmap;
      }else{
         ctldiff_code.p_picture = _pic_diff_code_bitmap;
      }
   
      ctlfilespecs.LoadHistory("FilespecsHistory");
      ctlexclude_filespecs.LoadHistory("ExcludeFilespecsHistory");
      if (_default_option(VSOPTIONZ_DEFAULT_EXCLUDES) != '') {
         ctlexclude_filespecs._lbadd_item_no_dupe(MFFIND_DEFAULT_EXCLUDES, 'E', LBADD_BOTTOM);
      }
      ctlexclude_filespecs._lbadd_item_no_dupe(MFFIND_BINARY_FILES, 'E', LBADD_BOTTOM);
   
      ctlpath1.LoadHistory("Path1History");
   
      ctlpath1.SetupMappedPaths(ctlpath1.p_text);
   
      if ( def_diff_edit_flags&DIFFEDIT_NO_AUTO_MAPPING ) {
         ctllink.p_picture = _pic_del_linked_bitmap;
      }else{    
         ctllink.p_picture = _pic_linked_bitmap;
      }
      ctlsymbol1combo.fillInSymbolCombo();
      ctlsymbol2combo.fillInSymbolCombo();
   
      //ctlsymbol1combo.p_text = ctlsymbol1combo.p_cb_list_box._lbget_text();
      //ctlsymbol2combo.p_text = ctlsymbol2combo.p_cb_list_box._lbget_text();
   } while (false);
   setChangingDialog(origChangeDialog);
}

/**
 * Since the captions used in the diff type combo boxes have 
 * replacable parts ("###"), this funciton takes captions that 
 * were built from the these and decides of they match them. 
 * 
 * @param modifiedCaption Caption with "###" replaced with 
 *                        something
 * @param caption COMPARE_WHOLE_FILES, COMPARE_ONE_SYMBOL, or 
 *                COMPARE_ALL_SYMBOLS
 * 
 * @return bool true if <b>modifiedCaption</b> "matches" 
 *         <b>caption</b>
 */
static bool matchCaptionPrefix(_str modifiedCaption,_str origCaption)
{
   match := false;
   p := pos('(\#\#\#)|(\$\$\$)', origCaption,1,'r');
   // Compare the strings up to the "###" in origCaption
   if ( p ) {
      origCaption = substr(origCaption,1,p-1);
      modifiedCaption = substr(modifiedCaption,1,p-1);
      match = origCaption == modifiedCaption;
   }else{
      match = modifiedCaption == origCaption;
   }
   return match;
}

static void findCaption(_str origCaption)
{
   origChangeDialog := setChangingDialog(true);
   p := pos('(\#\#\#)|(\$\$\$)', origCaption,1,'r');
   if ( p ) {
      origCaption = substr(origCaption,1,p-1);
   }
   top();
   status := search('^'_escape_re_chars(origCaption),'@r');
   if ( !status ) {
      p_text = _lbget_text();
   }
   setChangingDialog(origChangeDialog);
}

static int getCurLineNumber(_str filename,bool isBufferID)
{
   orig_wid := p_window_id;
   p_window_id = HIDDEN_WINDOW_ID;
   _safe_hidden_window();

   lineNumber := 0;
   status := 0;
   if ( isBufferID ) {
      status = load_files('+q +bi 'filename);
   } else {
      status = load_files('+q +b 'filename);
   }
   if ( !status ) {
      lineNumber = p_line;
   }

   p_window_id = orig_wid;
   return lineNumber;
}

void ctlsymbol1combo.on_change(int reason)
{
   origChangeDialog := setChangingDialog(true);
   switch ( reason ) {
   case CHANGE_CLINE_NOTVIS:
   case CHANGE_CLINE:
      {
         pathNum := getPathNumForSymbolCombo();
         if ( !_haveProDiff() && pos(PRO_ONLY,p_text) ) {
            status := _lbsearch(COMPARE_WHOLE_FILES);
            if ( !status ) {
               p_text = _lbget_text();
            }
         } else if (  matchCaptionPrefix(p_text,COMPARE_WHOLE_FILES) ) {
            setLineRangeVisible(pathNum,false);
            setSymbolCaption(pathNum,"");
            setSymbolVisible(pathNum,false);
         }else if ( matchCaptionPrefix(p_text,COMPARE_ONE_SYMBOL) ) {
         }else if ( matchCaptionPrefix(p_text,COMPARE_LINE_RANGE) ) {
            startLine := endLine := 0;
            pathControlName := "ctlpath":+pathNum;
            pathControlWID := _find_control(pathControlName);
            isBufferID := false;
            filename := "";
            if ( pathControlWID ) {
               if ( pathControlName=="ctlpath2" ) {
                  filename=GetPath2Filename(false);
               } else {
                  filename = pathControlWID.p_text;
                  if ( _diff_is_untitled_filename(filename) ) {
                     parse pathControlWID.p_text with 'Untitled<','e' filename '>';
                     isBufferID = true;
                  }
               }
            }
            startLine = getCurLineNumber(filename,isBufferID);
            if ( !origChangeDialog ) {
               show('-modal _diffsetup_line_range_form',&startLine,&endLine,filename,isBufferID);
               if ( startLine!=0 && endLine!=0 ) {
                  startControlName := "ctlpath":+pathNum:+"_firstline";
                  startControlWID := _find_control(startControlName);
                  if ( startControlWID ) {
                     startControlWID.p_text = startLine;
                  }
   
                  endControlName := "ctlpath":+pathNum:+"_lastline";
                  endControlWID := _find_control(endControlName);
                  if ( endControlWID ) {
                     endControlWID.p_text = endLine;
                  }
               }
               setLineRangeVisible(pathNum,true);
            }else{
               setLineRangeVisible(pathNum,true);
            }
            setSymbolVisible(pathNum,false);
         }else if ( matchCaptionPrefix(p_text,COMPARE_CUR_SYMBOL) ) {
            // 11:01:25 AM 4/9/2009 Pulled this for right now
            //_message_box("ctlsymbol1combo.on_change: COMPARE_CUR_SYMBOL");
            mou_hour_glass(true);
            curFilenameInDialog := p_prev.p_prev.p_text;
            if ( pathNum=='2' ) {
               curFilenameInDialog = GetPath2Filename();
            }

            startLineNumber := endLineNumber := 0;

            parse p_text with '[ ' auto symbolName ',' auto tagInfo ']' .;

            // 3/16/2016
            // Removing "Use file on disk" checkboxes
            status := _GetLineRangeWithFunctionInfo(curFilenameInDialog,symbolName,tagInfo,startLineNumber,endLineNumber,true);
            if ( !status ) {
               setLineRangeCaption(pathNum,startLineNumber,endLineNumber);
               setLineRangeVisible(pathNum,true);

               setSymbolCaption(pathNum,symbolName);
               setSymbolVisible(pathNum,true);
            }
            mou_hour_glass(false);
            if ( pathNum=='1' ) {
               // If we were dealing with the path 1 combo box, try to find
               // the same symbol in the other file
               mou_hour_glass(true);
               _str filename2=GetPath2Filename();

               startLineNumber2 := endLineNumber2 := 0;
               // 3/16/2016
               // Removing "Use file on disk" checkboxes
               loadFile2FromDisk := _file_eq(curFilenameInDialog,filename2);
               status=_GetLineRangeWithFunctionInfo(filename2,symbolName,tagInfo,startLineNumber2,endLineNumber2,true,loadFile2FromDisk);
               if ( !status ) {
                  setLineRangeCaption('2',startLineNumber2,endLineNumber2);
                  setLineRangeVisible('2',true);

                  setSymbolCaption('2',symbolName);
                  setSymbolVisible('2',true);
               }
               mou_hour_glass(false);
               ctlok._set_focus();
            }
            ctlok._set_focus();

         } else if ( matchCaptionPrefix(p_text,COMPARE_ALL_SYMBOLS) ) {
            setLineRangeVisible(pathNum,false);
            setSymbolVisible(pathNum,false);
         }
      }
      break;
   }
   _begin_line();
   setChangingDialog(origChangeDialog);
}

void ctlsymbol1combo.on_drop_down(int reason)
{
   switch ( reason ) {
   case DROP_DOWN:
      {
         fillInSymbolCombo();
         break;
      }
   case DROP_UP_SELECTED:
       if ( matchCaptionPrefix(p_text,COMPARE_ONE_SYMBOL) ) {
         origChangeDialog := setChangingDialog(true);
         pathNum := getPathNumForSymbolCombo();
         showLineCaption := false;
         startLineNumber1 := endLineNumber1 := 0;
         status := showSymbolDialog(startLineNumber1,endLineNumber1,auto symbolName,auto tagInfo,origChangeDialog);
         if ( !status ) {
            setLineRangeCaption(pathNum,startLineNumber1,endLineNumber1);
            setLineRangeVisible(pathNum,true);

            setSymbolCaption(pathNum,symbolName);
            setSymbolVisible(pathNum,true);

            if ( pathNum=='1' ) {
               // If we were dealing with the path 1 combo box, try to find
               // the same symbol in the other file
               mou_hour_glass(true);
               _str filename1=_diff_absolute(ctlpath1.p_text);
               _str filename2=GetPath2Filename();

               // 3/16/2016
               // Removing "Use file on disk" checkboxes
               loadFile2FromDisk := _file_eq(filename1,filename2);
               startLineNumber2 := endLineNumber2 := 0;
               status=_GetLineRangeWithFunctionInfo(filename2,symbolName,tagInfo,startLineNumber2,endLineNumber2,true,loadFile2FromDisk);
               if ( !status ) {
                  setLineRangeCaption('2',startLineNumber2,endLineNumber2);
                  setLineRangeVisible('2',true);

                  setSymbolCaption('2',symbolName);
                  setSymbolVisible('2',true);

                  ctlsymbol2combo.p_text = COMPARE_ONE_SYMBOL;
               }
               mou_hour_glass(false);
               ctlok._set_focus();
            }
            _begin_line();
            setChangingDialog(origChangeDialog);
         }
      }
   }
}

static _str getCurTagFromCurBuffer()
{
   // Update the context message, if current context is local variable
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _mdi.p_child._UpdateContext(true);

   local_id := _mdi.p_child.tag_current_local();
   type_name := "";
   symbolName := "";
   if (local_id > 0 && (def_context_toolbar_flags&CONTEXT_TOOLBAR_DISPLAY_LOCALS) ) {
      //say("_UpdateContextWindow(): local_id="local_id);
      tag_get_detail2(VS_TAGDETAIL_local_type,local_id,type_name);
      tag_get_detail2(VS_TAGDETAIL_local_flags,local_id,auto tag_flags);
      symbolName = tag_tree_make_caption_fast(VS_TAGMATCH_local,local_id,true,true,false);
      pic_index := tag_get_bitmap_for_type(tag_get_type_id(type_name), tag_flags);
      //ContextMessage(caption, pic_index);
      _mdi.p_child.p_ModifyFlags |= MODIFYFLAG_CONTEXTWIN_UPDATED;
   }else{
      int context_id = _mdi.p_child.tag_current_context();
      if (context_id > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);
         tag_get_detail2(VS_TAGDETAIL_context_flags,context_id,auto tag_flags);
         symbolName = tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,true,true,false);
         pic_index := tag_get_bitmap_for_type(tag_get_type_id(type_name), tag_flags);
         _mdi.p_child.p_ModifyFlags |= MODIFYFLAG_CONTEXTWIN_UPDATED;
      }
   }
   curBufferTag := symbolName:+',':+type_name;
   if ( strip(curBufferTag)==',' ) curBufferTag = "";
   return curBufferTag;
}
static void fillInSymbolComboAndTextBox()
{
   origChangeDialog := setChangingDialog(true);
   fillInSymbolCombo();
   p_text = _lbget_text();
   setChangingDialog(origChangeDialog);
}

static _str getPathNumForSymbolCombo()
{
   pathNum := "";
   if ( p_prev.p_prev.p_name=="ctlpath1" ) {
      pathNum = "1";
   }else if ( p_prev.p_prev.p_name=="ctlpath2" ) {
      pathNum = "2";
   }
   return pathNum;
}

static void fillInSymbolCombo()
{
   origChangeDialog := setChangingDialog(true);
   pathNum := getPathNumForSymbolCombo();
   //curFilenameInDialog := p_prev.p_prev.p_text;

   curFilename := p_prev.p_prev.p_text;

   symbolName := "";

   pathReplacement := pathNum;
   path2Exists := false;
   curPathExists := false;
   diffing_folders:=dialogInFolderMode_slow();

   if ( pathNum=='1' ) {
      if ( !diffing_folders && file_exists(curFilename) ) {
         pathReplacement = curFilename;
         curPathExists = true;
      }
   }else if ( pathNum=='2' ) {
      curFilename = GetPath2Filename();
      if ( !diffing_folders && file_exists(curFilename) ) {
         pathReplacement = curFilename;
         curPathExists = true;
      }
   }
   //remainingWidth := p_width - _text_width(COMPARE_ONE_SYMBOL);
   //pathReplacement = _ShrinkFilename(pathReplacement,remainingWidth);
   if (!curPathExists) {
      _lbclear();
      _lbadd_item(COMPARE_WHOLE_FILES); 
      p_text=COMPARE_WHOLE_FILES;
      _lbtop();
   } else {
      if (!p_Noflines) {
         _lbadd_item(COMPARE_WHOLE_FILES); 
         p_text=COMPARE_WHOLE_FILES;
      }
      if (p_Noflines<=1 /*_lbfind_item(COMPARE_LINE_RANGE,0)*/) {
         _lbadd_item(COMPARE_LINE_RANGE);
         proOnlySuffix := "";
         if ( !_haveProDiff() ) proOnlySuffix = ' 'PRO_ONLY;

         if ( pathNum=='1') {
            _lbadd_item(COMPARE_ALL_SYMBOLS:+proOnlySuffix);
         }
         _lbadd_item(COMPARE_ONE_SYMBOL:+proOnlySuffix);
      }
   }

   if ( !curPathExists ) {
      orig_wid:=p_window_id;
      p_window_id=p_next.p_next;

      // Line range label
      p_visible = false;

      // Start line
      p_next.p_visible = false;

      // middle
      p_next.p_next.p_visible = false;

      // End line
      p_next.p_next.p_next.p_visible = false;

      // Symbol label
      p_next.p_next.p_next.p_next.p_visible = false;

      p_window_id=orig_wid;
   }
   setChangingDialog(origChangeDialog);
}

static int LoadMapInfo(_str (&Path1Names)[],_str (&MapInfo):[])
{
   _str HistoryFilename=_ConfigPath():+DIFFMAP_FILENAME;
   temp_view_id := 0;
   int status=_ini_get_section(HistoryFilename,"mappings",temp_view_id);
   if (status) {
      return(status);
   }
   line := "";
   CurPath := "";
   MappedPaths := "";
   orig_view_id := p_window_id;
   p_window_id=temp_view_id;
   top();up();
   while (!down()) {
      get_line(line);
      parse line with CurPath (_chr(1)) MappedPaths;
      CurPath=_file_case(CurPath);
      _maybe_append_filesep(CurPath);
      if (MapInfo._indexin(CurPath)) {
         MapInfo:[CurPath] :+= _chr(1):+MappedPaths;
      }else{
         MapInfo:[CurPath]=MappedPaths;
         Path1Names :+= _file_case(CurPath);
      }
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

static const COMPARE_OPTION_CAPTION= "File Compare Options";
static const DIALOG_OPTION_CAPTION=  "Dialog Setup";

static void oncreateOptions(bool removeDialogOptions)
{
   origChangeDialog := setChangingDialog(true);
   //ctlminihtml2.p_backcolor=0x80000022;
   wid := p_window_id;
   _control ctltree1;
   p_window_id=ctltree1;
   int options_index=_TreeAddItem(TREE_ROOT_INDEX,"Options",TREE_ADD_AS_CHILD);
   int first_active_index=_TreeAddItem(options_index,COMPARE_OPTION_CAPTION,TREE_ADD_AS_CHILD,0,0,-1);
   if (!removeDialogOptions) {
      _TreeAddItem(options_index,DIALOG_OPTION_CAPTION,TREE_ADD_AS_CHILD,0,0,-1);
   }
   _TreeSetCurIndex(first_active_index);
   p_window_id=wid;

   int client_width=_dx2lx(SM_TWIP,ctlsstab1.p_client_width);

   ctlcompare_options_pic.p_y=ctledit_options_pic.p_y=ctltree1.p_y;
   ctlcompare_options_pic.p_x=ctledit_options_pic.p_x=(ctltree1.p_x*2)+ctltree1.p_width;

   ctlcompare_options_pic.p_x_extent = client_width;
   ctledit_options_pic.p_x_extent = client_width;

   ctlcompare_options_pic.p_border_style=BDS_NONE;
   ctledit_options_pic.p_border_style=BDS_NONE;

   SetDiffCompareOptionsOnDialog(def_diff_flags);
   SetDiffEditOptionsOnDialog();

   // Change for editor control.
   // OEM's don't ship vs.exe so can't support spawning vs.exe
   if (_default_option(VSOPTION_APIFLAGS)&0x80000000 &&  _haveProDiff()) {
      ctlseparate_process.p_visible=true;
   } else {
      ctlseparate_process.p_visible=false;

      diff := ctlshow_margin_buttons.p_y - ctlseparate_process.p_y;
      ctlshow_margin_buttons.p_y -= diff;
      ctlnum_saved_sessions.p_y -= diff;
      ctlnum_saved_sessions.p_prev.p_y -= diff;
      ctltop.p_parent.p_y -= diff;
      ctlhistory.p_parent.p_y -= diff;
   }
   if ( !_haveProDiff()) {
      ctlcode_diff.p_visible = false;
      ctlcode_diff_skip_comments.p_visible = false;
      ctlcode_diff_skip_line_numbers.p_visible = false;
      ctlcode_diff_use_token_mapping.p_visible = false;
      ctlcode_diff_edit_token_mapping.p_visible = false;
      ctlalways_compare_files.p_parent.p_visible = false;
      ctldiff_code.p_visible = false;
      ctlFilenamesOnly.p_visible = false;

      // These are in the middle of the options
      ctlautoclose.p_visible = false;
      ctlnoexitprompt.p_visible = false;

      // Calculate the amount of space used by these controls
      space := ctlnum_saved_sessions.p_y - ctlautoclose.p_y;

      // Move the other controls up so we don't have a gap
      //ctlbuttons_at_top.p_y -= space;
      //ctlshow_current_context.p_y -= space;
      //ctlshow_margin_buttons.p_y -= space;

      ctllabel27.p_y -= space;
      ctlnum_saved_sessions.p_y -= space;
      frame2.p_y -= space;
      frame4.p_y -= space;
   }
   setLinkButtonPicture();
   setChangingDialog(origChangeDialog);
   ctlintraline_length_limit.p_text = def_diff_max_intraline_len intdiv 1024;
   ctltimeout.p_text = _default_option(VSOPTION_DIFF_TIMEOUT_IN_SECONDS);
}

static void SetDiffCompareOptionsOnDialog(int diffOptions)
{
   origChangeDialog := setChangingDialog(true);
   ctlexpand_tabs.p_value=diffOptions&DIFF_EXPAND_TABS;
   ctlignore_leading_spaces.p_value=diffOptions&DIFF_IGNORE_LSPACES;
   ctlignore_trailing_spaces.p_value=diffOptions&DIFF_IGNORE_TSPACES;
   ctlignore_spaces.p_value=diffOptions&DIFF_IGNORE_SPACES;
   ctlignore_case.p_value=diffOptions&DIFF_IGNORE_CASE;
   ctlno_compare_eol.p_value=diffOptions&DIFF_DONT_COMPARE_EOL_CHARS;
   ctlskip_leading.p_value=diffOptions&DIFF_LEADING_SKIP_COMMENTS;
   ctlcode_diff.p_value=(int)!(diffOptions&DIFF_NO_SOURCE_DIFF);
   ctlcode_diff_skip_comments.p_value=diffOptions&DIFF_SKIP_ALL_COMMENTS;
   ctlcode_diff_skip_line_numbers.p_value=diffOptions&DIFF_SKIP_LINE_NUMBERS;
   ctlcode_diff_use_token_mapping.p_value=diffOptions&DIFF_USE_SOURCE_DIFF_TOKEN_MAPPINGS;

   if ( diffOptions&DIFF_MFDIFF_REQUIRE_TEXT_MATCH ) {
      ctlalways_compare_files.p_value = 1;
   }else if ( diffOptions&DIFF_MFDIFF_REQUIRE_SIZE_DATE_MATCH ) {
      ctlmismatch_size_date.p_value = 1;
   }
   if ( diffOptions&DIFF_MFDIFF_SIZE_ONLY_MATCH_IS_MISMATCH ) {
      ctlmismatch_date_only.p_value = 1;
   }
   if ( !ctlalways_compare_files.p_value && !ctlmismatch_size_date.p_value ) {
      ctlmismatch_size_date.p_value = 1;
   }
   ctlintraline_length_limit.p_x = ctlintraline_length_limit.p_prev.p_x_extent+_twips_per_pixel_x();
   ctlspin1.p_x = ctlintraline_length_limit.p_x_extent+(_twips_per_pixel_x());
   ctlspin1.p_next.p_x = ctlspin1.p_x_extent;

   ctltimeout.p_x = ctltimeout.p_prev.p_x_extent+_twips_per_pixel_x();
   ctlspin2.p_x = ctltimeout.p_x_extent+(_twips_per_pixel_x());
   ctlspin2.p_next.p_x = ctlspin2.p_x_extent;

#if 0 //3:11pm 10/21/2018
   if (!_default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS)) {
      ctlinterleaved.p_visible=false;
      diff := ctlcode_diff.p_y - ctlskip_leading.p_y;
      ctlcode_diff.p_y -= diff;
      ctlcode_diff_skip_comments.p_y -= diff;
      ctlcode_diff_skip_line_numbers.p_y -= diff;
      ctlcode_diff_use_token_mapping.p_y -= diff;
      ctlcode_diff_edit_token_mapping.p_y -= diff;
      ctlframe1.p_y -= diff;

      ctlintraline_length_limit.p_prev.p_y -= diff;
      ctlintraline_length_limit.p_y -= diff;
      ctlspin1.p_y -= diff;
      ctlspin1.p_next.p_y -= diff;
   }
#endif
   setChangingDialog(origChangeDialog);
}

static void SetDiffEditOptionsOnDialog()
{
   origChangeDialog := setChangingDialog(true);
   ctlshow_gauge.p_value=def_diff_edit_flags&DIFFEDIT_SHOW_GAUGE;
   ctljump.p_value=def_diff_edit_flags&DIFFEDIT_AUTO_JUMP;

   // Don't set this here, will be handled by setLinkButtonPicture
   //ctlauto_mapping.p_value=(int)!(def_diff_edit_flags&DIFFEDIT_NO_AUTO_MAPPING);

   ctlautoclose.p_value=def_diff_edit_flags&DIFFEDIT_AUTO_CLOSE;
   ctlnoexitprompt.p_value=def_diff_edit_flags&DIFFEDIT_NO_PROMPT_ON_MFCLOSE;
   ctlbuttons_at_top.p_value=def_diff_edit_flags&DIFFEDIT_BUTTONS_AT_TOP;
   ctlshow_current_context.p_value=(def_diff_edit_flags&DIFFEDIT_HIDE_CURRENT_CONTEXT)? 0:1;
   ctlseparate_process.p_value=def_diff_edit_flags&DIFFEDIT_SPAWN_MFDIFF;
   ctlshow_margin_buttons.p_value=(def_diff_edit_flags&DIFFEDIT_HIDE_MARGIN_BUTTONS)?0:1;
   ctlnum_saved_sessions.p_text = def_diff_num_sessions;

   if (!_haveCurrentContextToolBar()) {
      ctlshow_current_context.p_value = 0;
      ctlshow_current_context.p_enabled = false;
   }

   if (def_diff_edit_flags&DIFFEDIT_START_AT_TOP) {
      ctltop.p_value=1;
   }else{
      ctlfirst.p_value=1;
   }
   if (def_diff_edit_flags&DIFFEDIT_CURFILE_INIT) {
      ctlcurfile.p_value=1;
   }else{
      ctlhistory.p_value=1;
   }
   setChangingDialog(origChangeDialog);
}

void ctltree1.on_change(int reason,int index)
{
   if (index<=0) {
      return;
   }
   caption := _TreeGetCaption(index);
   switch (caption) {
   case COMPARE_OPTION_CAPTION:
      ctlcompare_options_pic.p_visible=true;
      ctledit_options_pic.p_visible=false;
      break;
   case DIALOG_OPTION_CAPTION:
      ctlcompare_options_pic.p_visible=false;
      ctledit_options_pic.p_visible=true;
      break;
   }
}

static void _DiffInitSetupData(DIFF_SETUP_DATA &diffSetupData)
{
   DiffSessionCollection.initSessionData(diffSetupData);
}

void _DiffInitGSetupData()
{
   _DiffInitSetupData(gDiffSetupData);
}
static bool diff_setup_file_eq(DIFF_SETUP_FILE_DATA &a,DIFF_SETUP_FILE_DATA &b) {
   eq:=true;
   if (a.readOnly!=b.readOnly) eq=false;
   if (a.isBuffer!=b.isBuffer) eq=false;
   if (a.preserve!=b.preserve) eq=false;
   if (a.bufferIndex!=b.bufferIndex) eq=false;
   if (a.viewID!=b.viewID) eq=false;
   if (a.fileTitle!=b.fileTitle) eq=false;
   if (a.fileName!=b.fileName) eq=false;
   if (a.firstLine!=b.firstLine) eq=false;
   if (a.lastLine!=b.lastLine) eq=false;
   if (a.symbolName!=b.symbolName) eq=false;
   if (a.rangeSpecified!=b.rangeSpecified) eq=false;
   if (a.getBufferIndex!=b.getBufferIndex) eq=false;
   if (a.isViewID!=b.isViewID) eq=false;
   if (a.tryDisk!=b.tryDisk) eq=false;
   if (a.bufferState!=b.bufferState) eq=false;
   if (a.useDisk!=b.useDisk) eq=false;
   return eq;
}
static bool diff_setup_eq(DIFF_SETUP_DATA &curSetupData,DIFF_SETUP_DATA &gDiffSetupData) {
   eq:=true;
   if(!diff_setup_file_eq(curSetupData.file1,gDiffSetupData.file1)) eq=false;
   if(!diff_setup_file_eq(curSetupData.file2,gDiffSetupData.file2)) eq=false;
   //if(curSetupData.Quiet!=gDiffSetupData.Quiet) eq=false;
   if(curSetupData.Interleaved!=gDiffSetupData.Interleaved) eq=false;
   //if(curSetupData.Modal!=gDiffSetupData.Modal) eq=false;
   //if(curSetupData.NoMap!=gDiffSetupData.NoMap) eq=false;
   //if(curSetupData.ViewOnly!=gDiffSetupData.ViewOnly) eq=false;
   //if(curSetupData.Comment!=gDiffSetupData.Comment) eq=false;
   //if(curSetupData.CommentButtonCaption!=gDiffSetupData.CommentButtonCaption) eq=false;
   //if(curSetupData.DialogTitle!=gDiffSetupData.DialogTitle) eq=false;
   if(curSetupData.FileSpec!=gDiffSetupData.FileSpec) eq=false;
   if(curSetupData.ExcludeFileSpec!=gDiffSetupData.ExcludeFileSpec) eq=false;
   if(curSetupData.Recursive!=gDiffSetupData.Recursive) eq=false;
   //if(curSetupData.ImaginaryLineCaption!=gDiffSetupData.ImaginaryLineCaption) eq=false;
   //if(curSetupData.AutoClose!=gDiffSetupData.AutoClose) eq=false;
   if(curSetupData.RecordFileWidth!=gDiffSetupData.RecordFileWidth) eq=false;
   //if(curSetupData.ShowAlways!=gDiffSetupData.ShowAlways) eq=false;
   //if(curSetupData.ParentWIDToRegister!=gDiffSetupData.ParentWIDToRegister) eq=false;
   //if(curSetupData.OkPtr!=gDiffSetupData.OkPtr) eq=false;
   if(curSetupData.DiffTags!=gDiffSetupData.DiffTags) eq=false;
   //if(curSetupData.FileListInfo!=gDiffSetupData.FileListInfo) eq=false;
   if(curSetupData.DiffStateFile!=gDiffSetupData.DiffStateFile) eq=false;
   if(curSetupData.CompareOnly!=gDiffSetupData.CompareOnly) eq=false;
   //if(curSetupData.SaveButton1Caption!=gDiffSetupData.SaveButton1Caption) eq=false;
   //if(curSetupData.SaveButton2Caption!=gDiffSetupData.SaveButton2Caption) eq=false;
   //if(curSetupData.SetOptionsOnly!=gDiffSetupData.SetOptionsOnly) eq=false;
   //if(curSetupData.sessionDate!=gDiffSetupData.sessionDate) eq=false;
   //if(curSetupData.sessionName!=gDiffSetupData.sessionName) eq=false;
   if(curSetupData.compareOptions!=gDiffSetupData.compareOptions) eq=false;
   //say(curSetupData.compareOptions' 'dec2hex(gDiffSetupData.compareOptions));
   //if(curSetupData.sessionID!=gDiffSetupData.sessionID) eq=false;
   //if(curSetupData.balanceBuffersFirst!=gDiffSetupData.balanceBuffersFirst) eq=false;
   //if(curSetupData.noSourceDiff!=gDiffSetupData.noSourceDiff) eq=false;
   //if(curSetupData.VerifyMFDInput!=gDiffSetupData.VerifyMFDInput) eq=false;
   //if(curSetupData.dialogWidth!=gDiffSetupData.dialogWidth) eq=false;
   //if(curSetupData.dialogHeight!=gDiffSetupData.dialogHeight) eq=false;
   //if(curSetupData.dialogX!=gDiffSetupData.dialogX) eq=false;
   //if(curSetupData.dialogY!=gDiffSetupData.dialogY) eq=false;
   //if(curSetupData.windowState!=gDiffSetupData.windowState) eq=false;
   //if(curSetupData.specifiedSourceDiffOnCommandLine!=gDiffSetupData.specifiedSourceDiffOnCommandLine) eq=false;
   //if(curSetupData.posMarkerID!=gDiffSetupData.posMarkerID) eq=false;
   //if(curSetupData.vcType!=gDiffSetupData.vcType) eq=false;
   //if(curSetupData.matchMode2!=gDiffSetupData.matchMode2) eq=false;
   //if(curSetupData.gotDataFromFile!=gDiffSetupData.gotDataFromFile) eq=false;
   //if(curSetupData.usedGlobalData!=gDiffSetupData.usedGlobalData) eq=false;
   if(curSetupData.fileListFile!=gDiffSetupData.fileListFile) eq=false;
   if(curSetupData.compareFilenamesOnly!=gDiffSetupData.compareFilenamesOnly) eq=false;
   //if(curSetupData.isvsdiff!=gDiffSetupData.isvsdiff) eq=false;
   //if(curSetupData.pointToGoto!=gDiffSetupData.pointToGoto) eq=false;
   if(curSetupData.runInForeground!=gDiffSetupData.runInForeground) eq=false;
   return eq;
}
int ctlok.lbutton_up()
{
   //if(handleChangeInSessionsTree()) return 1;
   status := 0;
   do {
      status = okOptions();
      if (status) break;

      // Save dialog size/position info for vsdiff case up front.  If this is 
      // the OptionsOnly case, we will return early.
      x := y := width := height := 0;
      _DiffGetDimensionsAndState(x,y,width,height);
   
      //_message_box('sessions visible='ctlsession_tree.p_visible);
      //_message_box('restore=' _GetDialogInfo(RESTORE_FROM_INI));
      if ( _GetDialogInfo(RESTORE_FROM_INI) ) {
         if (ctlsession_tree.p_visible) {
            _DiffWriteConfigInfoToIniFile("VSDiffGeometry",x,y,width,height);
         } else { 
            _ini_set_value(_ConfigPath():+DIFFMAP_FILENAME,'VSDiffGeometry','def_diff_flags',def_diff_flags);
            _ini_set_value(_ConfigPath():+DIFFMAP_FILENAME,'VSDiffGeometry','def_diff_edit_flags',def_diff_edit_flags);
         }
      }

      haveUntitledBuffer := _diff_is_untitled_filename(ctlpath1.p_text) ||
         _diff_is_untitled_filename(ctlpath2.p_text);
      if (OptionsOnly()) {
         if ( !haveUntitledBuffer ) {
            ctlsstab1._save_form_response();
         }
         ctlsstab1.p_ActiveTab=0;
         if ( ctlsstab1.p_ActiveEnabled ) {
            gDiffSetupData.SetOptionsOnly=true;
            return(0);
         }
         p_active_form._delete_window(0);
         return(0);
      }
      status=okFiles();
      if (status) break;
      if ( !_diff_is_untitled_filename(ctlpath1.p_text) ) {
         ctlsstab1._save_form_response();
      }

      if ( _haveProDiff() &&
           ctlcode_diff.p_enabled && 
           ctlcode_diff.p_value ) {
         gDiffSetupData.balanceBuffersFirst = true;
         gDiffSetupData.file2.readOnly = DIFF_READONLY_SOURCEDIFF;
      }
      pic_name := name_name(ctlFilenamesOnly.p_picture);
      parse pic_name with pic_name "@" .;
      if ( _file_eq(pic_name, "bbdiff_names.svg") ) {
         gDiffSetupData.compareFilenamesOnly = true;
      }

      if ( !haveUntitledBuffer ) {
         bool changed=true;
         DiffSessionCollection *pdiffSessionData = _GetDialogInfoHtPtr("diffSessions");
         GetCompareOptionsFromDialog(gDiffSetupData.compareOptions,auto diffMaxIntralineLen,auto diffTimeout);
         recentSessionsIndex := ctlsession_tree._TreeSearch(TREE_ROOT_INDEX,SESSION_CAPTION_RECENT);
         if (recentSessionsIndex>=0) {
            firstChildIndex := ctlsession_tree._TreeGetFirstChildIndex(recentSessionsIndex);
            if (firstChildIndex>=0) {
               firstChildIndex = ctlsession_tree._TreeGetFirstChildIndex(firstChildIndex);
               if (firstChildIndex>=0) {
                  parse ctlsession_tree._TreeGetUserInfo(firstChildIndex) with . (USERINFO_DELIMITER) auto sessionID;
                  if (sessionID!=null && sessionID!='') {
                     DIFF_SETUP_DATA curSetupData = pdiffSessionData->getSession(sessionID);
                     if (curSetupData!=null) {
                        changed=!diff_setup_eq(curSetupData,gDiffSetupData);
                     }
                  }
               }
            }
         }
         if (changed) {
            pdiffSessionData->addSession(gDiffSetupData);
         }
      }
      p_active_form._delete_window(0);
   } while (false);
   return(status);
}

static int checkDiffSessionName(_str sessionName)
{
   status := 0;
   p := pos('\[|\]|\:',sessionName,1,'r');
   if ( p ) {
      _message_box(nls("Sessions names cannot contain '[' ']' or ':' characters"));
      status = 1;
   }
   return status;
}

static int getSessionIndex(_str sessionName,DIFF_SETUP_DATA (&allDiffSessionData)[])
{
   index := -1;
   foreach ( auto curIndex => auto curSession in allDiffSessionData ) {
      if ( curSession.sessionName==sessionName ) {
         index = curIndex;
         break;
      }
   }
   return index;
}

void ctlsave_session.lbutton_up()
{
   status:=okFiles();
   if (status) {
      return;
   }
   /*if(handleChangeInSessionsTree()) {
      return;
   } */
   do {

      DiffSessionCollection *pdiffSessionData =_GetDialogInfoHtPtr("diffSessions");
      lastSessionID := _GetDialogInfoHt("lastSessionID");
      sessionName := "";
      if ( lastSessionID!=null && lastSessionID>-1 ) {
         DIFF_SETUP_DATA diffsession = pdiffSessionData->getSession(lastSessionID);
         defaultSession := pdiffSessionData->getDefaultSessionName();
         if ( diffsession.sessionName!=defaultSession ) {
            sessionName = diffsession.sessionName;
         }
      }

      status=show('-modal _textbox_form',
                      'Save Session',
                      TB_RETRIEVE_INIT, //Flags
                      '',//width
                      '',//help item
                      '',
                      '',
                      "-e "checkDiffSessionName" Session Name:"sessionName
                      );
      if ( status=="" ) break;
      sessionName = _param1;

      sessionIndex := -1;
      if ( pdiffSessionData->sessionExists(sessionName,sessionIndex) ) {
         result := _message_box(nls("Do you wish to replace the existing session '%s'",sessionName),"",MB_YESNO);
         if ( result!=IDYES ) {
            break;
         }
         pdiffSessionData->deleteSession(sessionIndex);
      }

      DIFF_SETUP_DATA origSetupData = gDiffSetupData;
      okFiles(true);
      newDiffSession := gDiffSetupData;
      se.datetime.DateTime curDate;
      newDiffSession.sessionDate = curDate.toString();
      newDiffSession.sessionName = sessionName;

      GetCompareOptionsFromDialog(auto compareOptions=0,auto diffMaxIntralineLen=0,auto diffTimeout=0);
      newDiffSession.compareOptions = compareOptions;

      pdiffSessionData->addSession(newDiffSession,sessionName);
      pdiffSessionData->saveSessions();

      bitmapIndex := getBitmapIndexForSession(newDiffSession);

      wid := p_window_id;
      p_window_id=ctlsession_tree;
      namedSessionIndex := _TreeSearch(TREE_ROOT_INDEX,SESSION_CAPTION_NAMED);
      existingSesionIndex := _TreeSearch(namedSessionIndex,sessionName);
      if ( existingSesionIndex>-1 ) {
         _TreeDelete(existingSesionIndex);
      }

      if ( namedSessionIndex>-1 ) {
         newIndex := _TreeAddItem(namedSessionIndex,sessionName,TREE_ADD_AS_CHILD,bitmapIndex,bitmapIndex,-1,0,newDiffSession.sessionDate:+USERINFO_DELIMITER:+newDiffSession.sessionID);
         _TreeSortCaption(namedSessionIndex);
      }
      p_window_id=wid;
      
      gDiffSetupData = origSetupData;

      ctlsession_tree.p_enabled = true;
      ctlsession_tree.p_prev.p_enabled  = true;
      ctlsave_session.p_enabled = false;
      ctlsave_session.p_enabled = true;

   } while ( false );
}

void ctldeletesession.lbutton_up()
{
   ctlsession_tree.call_event(ctlsession_tree,DEL);
}

void ctlsession_tree.del()
{
   index := ctlsession_tree._TreeCurIndex();
   _TreeGetInfo(index,auto state,auto bm1);
   if ( bm1!=_pic_project ) {
      DiffSessionCollection *pdiffSessionData = _GetDialogInfoHtPtr("diffSessions");
      orig := getChangingDialog();
      _SetDialogInfoHt("changingDialog",true);
      status := DelSessionFromTree(index,*pdiffSessionData);
      _SetDialogInfoHt("changingDialog",orig);
   }
}

/**
 * @param index 
 * 
 * @return int 0 if successful
 */
static int DelSessionFromTree(int treeNodeIndex,DiffSessionCollection &diffSessionData)
{
   userInfo := _TreeGetUserInfo(treeNodeIndex);
   cap := _TreeGetCaption(treeNodeIndex);

   parse userInfo with auto dateString (USERINFO_DELIMITER) auto sessionID;

   status := diffSessionData.deleteSession(sessionID);
   if ( !status ) {
      _TreeDelete(treeNodeIndex);
      sessionTreeOnChange(CHANGE_SELECTED,_TreeCurIndex());
   }
   return status;
}

void ctlok.on_destroy()
{
   killEnableControlTimer(p_active_form);
   DiffSessionCollection *pdiffSessionData = _GetDialogInfoHtPtr("diffSessions");

   pdiffSessionData->saveSessions();

   saveDialogGeometry();
}

static void saveDialogGeometry()
{
   historyFilename := _ConfigPath():+DIFFMAP_FILENAME;
   _ini_set_value(historyFilename,"SetupGeometry","_divider.p_x",_divider.p_x);
   _ini_set_value(historyFilename,"SetupGeometry","dialogWidth",p_active_form.p_width);
}

void ctlload.lbutton_up()
{
   typeless result=_OpenDialog('-modal',
                      'Open Diff State File',                   // Dialog Box Title
                      '',                   // Initial Wild Cards
                      'Diff State Files (*.':+DIFF_STATEFILE_EXT:+')',       // File Type List
                      OFN_FILEMUSTEXIST,
                      DIFF_STATEFILE_EXT
                      );
   if (result=='') return;
   _str filename=result;
   spawn := ctlseparate_process.p_value&&ctlseparate_process.p_visible;
   if ( !_diff_is_untitled_filename(ctlpath1.p_text) ) {
      _save_form_response();
   }
   p_active_form._delete_window();
   refresh();
   if (spawn) {
      _str cmdline=_maybe_quote_filename(editor_name('P'):+'vs');//editor name
      cmdline :+= ' +new -q -st 0 -mdihide -p diff -loadstate 'filename;
      typeless status=shell(cmdline,'QA');
   }else{
      _DiffLoadDiffStateFile(filename);
   }
}

static int okOptions()
{
   compareOptions := 0;
   diffMaxIntralineLen := 0;
   diffTimeout := 0;
   GetCompareOptionsFromDialog(compareOptions,diffMaxIntralineLen,diffTimeout);

   editOptions := def_diff_edit_flags;
   expertMode  := 0;
   numSessions := def_diff_num_sessions;
   maxIntralineDiffLen:= def_diff_max_intraline_len;

   status := 0;
   do {
      if (def_diff_flags!=compareOptions) {
         def_diff_flags=compareOptions;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }

      status = GetDiffEditOptionsFromDialog(editOptions,expertMode,numSessions);
      if ( status ) break;
   
      if ( def_diff_edit_flags!=editOptions ) {
         def_diff_edit_flags=editOptions;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
   
      if ( def_diff_num_sessions!=numSessions ) {
         def_diff_num_sessions = numSessions;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      if ( def_diff_max_intraline_len!=diffMaxIntralineLen ) {
         def_diff_max_intraline_len = diffMaxIntralineLen;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      if ( _default_option(VSOPTION_DIFF_TIMEOUT_IN_SECONDS)!=diffTimeout ) {
         _default_option(VSOPTION_DIFF_TIMEOUT_IN_SECONDS,diffTimeout);
      }
   } while (false);
   return status;
}


static void GetCompareOptionsFromDialog(int &options, int &diffMaxIntralineLen, int &diffTimeout)
{
   options=0;
   if (ctlexpand_tabs.p_value) {
      options|=DIFF_EXPAND_TABS;
   }
   if (ctlignore_leading_spaces.p_value) {
      options|=DIFF_IGNORE_LSPACES;
   }
   if (ctlignore_trailing_spaces.p_value) {
      options|=DIFF_IGNORE_TSPACES;
   }
   if (ctlignore_spaces.p_value) {
      options|=DIFF_IGNORE_SPACES;
   }
   if (ctlignore_case.p_value) {
      options|=DIFF_IGNORE_CASE;
   }
   if (ctlno_compare_eol.p_value) {
      options|=DIFF_DONT_COMPARE_EOL_CHARS;
   }
   if (ctlskip_leading.p_value) {
      options|=DIFF_LEADING_SKIP_COMMENTS;
   }
   if ( ctlalways_compare_files.p_value ) {
      options|=DIFF_MFDIFF_REQUIRE_TEXT_MATCH;
   }else if ( ctlmismatch_size_date.p_value ) {
      options|=DIFF_MFDIFF_REQUIRE_SIZE_DATE_MATCH;
   }
   if ( ctlmismatch_date_only.p_enabled && ctlmismatch_date_only.p_value ) {
      options|=DIFF_MFDIFF_SIZE_ONLY_MATCH_IS_MISMATCH;
   }
   if ( !ctlcode_diff.p_value ) {
      options|=DIFF_NO_SOURCE_DIFF;
   }
   if ( ctlcode_diff_skip_comments.p_value ) {
      options|=DIFF_SKIP_ALL_COMMENTS;
   }
   if ( ctlcode_diff_skip_line_numbers.p_value ) {
      options|=DIFF_SKIP_LINE_NUMBERS;
   }
   if ( ctlcode_diff_use_token_mapping.p_value ) {
      options|=DIFF_USE_SOURCE_DIFF_TOKEN_MAPPINGS;
   }
   if ( isinteger(ctlintraline_length_limit.p_text) ) {
      diffMaxIntralineLen = (int)ctlintraline_length_limit.p_text*1024;
   }
   if ( isinteger(ctltimeout.p_text) ) {
      diffTimeout = (int)ctltimeout.p_text;
   }
}

static int GetDiffEditOptionsFromDialog(int &options,int &expert_mode,int &num_sessions)
{
   status := 0;
   do {
      options = 0;
      expert_mode = 0;
      if ( !isinteger(ctlnum_saved_sessions.p_text) || ctlnum_saved_sessions.p_text<0 ) {
         ctlnum_saved_sessions._text_box_error("This field must be a positive integer");
         status = 1;
         break;
      }
      num_sessions = (int)ctlnum_saved_sessions.p_text;
      if (ctlshow_gauge.p_value) {
         options|=DIFFEDIT_SHOW_GAUGE;
      }
      if (ctljump.p_value) {
         options|=DIFFEDIT_AUTO_JUMP;
      }
      if (!ctlauto_mapping.p_value) {
         options|=DIFFEDIT_NO_AUTO_MAPPING;
      }
      if (ctlautoclose.p_value) {
         options|=DIFFEDIT_AUTO_CLOSE;
      }
      if (ctlnoexitprompt.p_value) {
         options|=DIFFEDIT_NO_PROMPT_ON_MFCLOSE;
      }
      if (ctlbuttons_at_top.p_value) {
         options|=DIFFEDIT_BUTTONS_AT_TOP;
      }
      if (!ctlshow_current_context.p_value && _haveCurrentContextToolBar()) {
         options|=DIFFEDIT_HIDE_CURRENT_CONTEXT;
      }
      if (ctlseparate_process.p_value) {
         options|=DIFFEDIT_SPAWN_MFDIFF;
      }
      if (!ctlshow_margin_buttons.p_value) {
         options|=DIFFEDIT_HIDE_MARGIN_BUTTONS;
      }
   
      if (ctltop.p_value) {
         options|=DIFFEDIT_START_AT_TOP;
      }else if (ctlfirst.p_value) {
         options|=DIFFEDIT_START_AT_FIRST_DIFF;
      }
      if (ctlcurfile.p_value) {
         options|=DIFFEDIT_CURFILE_INIT;
      }
   } while (false);
   return status;
}

static int okFiles(bool quiet=false)
{
   _DiffInitGSetupData();
   gDiffSetupData.Interleaved=ctlinterleaved.p_value!=0;
   status := 0;
   diffing_folders:=dialogInFolderMode_slow();
   if (diffing_folders && !_haveProDiff()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Multi-file diff");
      ctlsstab1.p_ActiveTab=0;
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if ( !quiet ) {
      status = CheckForValidFilenames(diffing_folders,false,ctlpath1_firstline.p_visible && ctlpath1_firstline.p_text!="");
      if (status) {
         return(status);
      }
   }
   if ( diffing_folders ) {
      if ( !quiet ) {
         status=CheckDirectories();
         if (status) {
            return(status);
         }
      }
      if ( diffing_folders &&
           _MFDiffStillFillingIn()
            ) {
         _message_box(nls("Only one multi-file diff may be run at a time"));
         return 1;
      }
      GetDataForMultiFile();

   }else if (!diffing_folders || symbolCompareOptionIsSet() ) {
      if ( !quiet ) {
         status=CheckForValidFilenames(diffing_folders,false,true);
         if (status) return(status);
      }

      if ( !diffing_folders &&
           _DiffIsDirectory(ctlpath1.p_text) &&
           _DiffIsDirectory(ctlpath2.p_text) &&
           _MFDiffStillFillingIn()
            ) {
         _message_box(nls("Only one multi-file diff may be run at a time"));
         return 1;
      }

      status=CheckLineRanges();
      if (status) return(status);

      status=CheckFileWidth();
      if (status) return(status);

      GetDataForTwoFiles();
      gDiffSetupData.fileListFile = ctlfile_list.p_text;
   }
   return(0);
}

static int CheckFileWidth()
{
   return 0;
   //if (ctlfile_width.p_text!='' &&
   //    (!isinteger(ctlfile_width.p_text) || ctlfile_width.p_text<0) ) {
   //   ctlfile_width._text_box_error(nls("Record file width must be a positive integer"));
   //   ctlsstab1.p_ActiveTab=0;
   //   return(1);
   //}
   //return(0);
}

static int CheckForValidFilenames(bool diffing_folders, bool UseFastIsDir=true,bool compareRegions=false)
{
   int status=ctlpath1.CheckForValidFilenames2(diffing_folders,UseFastIsDir);
   if (status) return(status);

   status=ctlpath2.CheckForValidFilenames2(diffing_folders,UseFastIsDir);
   if (status) return(status);

   if ( !compareRegions ) {
      status=ValidateBuffers();
      if (status) {
         ctlpath2._text_box_error(nls("You must specify two separate files"));
         return(1);
      }
   }
   if ( ctlfile_list.p_text!="" && !file_exists(ctlfile_list.p_text) ) {
      ctlfile_list._text_box_error("List file does not exist");
      return 1;
   }

   return(0);
}

static int ValidateBuffers()
{
   _str filename1=_diff_absolute(ctlpath1.p_text);
   _str filename2=_diff_absolute(GetPath2Filename());

   _str buf1=buf_match(filename1,1,'E');
   isbuf1:=buf1!='';

   _str buf2=buf_match(filename2,1,'E');
   isbuf2:=buf2!='';

   if ( _file_eq(filename1,filename2) ) {
      isbuf2 = false;
   }
   file_or_buffer_matches := (buf1!="" && isbuf1==isbuf2);

   if (_file_eq(filename1,filename2) && file_or_buffer_matches) {
      return(1);
   }
   return(0);
}

static int CheckForValidFilenames2(bool diffing_folders,bool UseFastIsDir=true)
{
   if (p_text=='') {
      _text_box_error("This item must be a valid path or filename");
      ctlsstab1.p_ActiveTab=0;
      return(FILE_NOT_FOUND_RC);
   }
   filename := p_text;
   filename=strip(filename,'B','"');
   ends_with_wildcard:=p_window_id==ctlpath1 && EndsWithWildcard(p_text);

   origFilename := filename;
   exists := file_exists(filename);
   if ( !exists && ends_with_wildcard && !diffing_folders ) {
      if ( !_haveProDiff() ) {
         _text_box_error(get_message(VSRC_FEATURE_REQUIRES_PRO_EDITION));
         ctlsstab1.p_ActiveTab=0;
         return VSRC_FEATURE_REQUIRES_PRO_EDITION;
      }
      if (ends_with_wildcard) {
         filename=_strip_filename(filename,'N');
      }
   }
   if (p_window_id==ctlpath2) {
      filename=GetPath2Filename(UseFastIsDir);
      filename=strip(filename,'B','"');
   }
   if ( filename=="" ) {
      _text_box_error("This item must be a valid path or filename");
      return(FILE_NOT_FOUND_RC);
   }
   if ( !_file_eq(origFilename,filename) ) {
      exists = file_exists(filename);
   }
   if (!exists) {
      isUntitledBuffer := _diff_is_untitled_filename(filename);
      if ( isUntitledBuffer ) return 0;
      absfilename := _diff_absolute(filename);
      if ( buf_match(absfilename,1,'E')=='' && !_diff_is_http_filename(absfilename)) {
         // Check to see if this is a direectory (and if a directory is allowed)
         // We don't check before here because we don't want toc all 
         // isdirectory if we don't have to.
         if ( isdirectory(filename) ) return 0;
         _text_box_error("This item must be a valid path or filename");
         ctlsstab1.p_ActiveTab=0;
         return(FILE_NOT_FOUND_RC);
      }
   }
   return(0);
}

static void GetDataForTwoFiles()
{
   GetDataForMultiFile(false);
   if ( _diff_is_http_filename(ctlpath1.p_text) ) {
      gDiffSetupData.file1.fileName=ctlpath1.p_text;
   } else if ( _diff_is_untitled_filename(ctlpath1.p_text) ) {
      parse ctlpath1.p_text with (NO_NAME) auto bufId1Str '>';
      gDiffSetupData.file1.bufferIndex = (int)bufId1Str;
   }else{
      gDiffSetupData.file1.fileName=_diff_absolute(strip(ctlpath1.p_text));
   }
   NamesMatch := FilenamesInDialogMatch();
   gDiffSetupData.file1.isBuffer=false;
   // 3/16/2016
   // Removing "Use file on disk" checkboxes
   /*if (ctlpath1_on_disk.p_enabled && ctlpath1_on_disk.p_value) {
      gDiffSetupData.file1.isBuffer=false;
      gDiffSetupData.file1.useDisk=true;
   }else*/ if (buf_match(gDiffSetupData.file1.fileName,1,'E')!='') {
      // if ctlpath1_on_disk.p_enabled==1, we should have the buffer open, but did
      // not specify the file on disk, so we want the buffer
      gDiffSetupData.file1.isBuffer=true;
      gDiffSetupData.file1.useDisk=false;
   }

   if (_diff_is_http_filename(ctlpath2.p_text)) {
      gDiffSetupData.file2.fileName=ctlpath2.p_text;
   } else if ( _diff_is_untitled_filename(ctlpath2.p_text) ) {
      parse ctlpath2.p_text with (NO_NAME) auto bufId2Str '>';
      gDiffSetupData.file2.bufferIndex = (int)bufId2Str;
   }else{
      gDiffSetupData.file2.fileName=GetPath2Filename(false);
   }

   gDiffSetupData.file2.isBuffer=false;
   // 3/16/2016
   // Removing "Use file on disk" checkboxes
   /*if (ctlpath2_on_disk.p_enabled && ctlpath2_on_disk.p_value) {
      gDiffSetupData.file2.isBuffer=false;
      gDiffSetupData.file2.useDisk=true;
   }else*/ if (buf_match(gDiffSetupData.file2.fileName,2,'E')!='') {
      // if ctlpath2_on_disk.p_enabled==2, we should have the buffer open, but did
      // not specify the file on disk, so we want the buffer
      if (!NamesMatch || !gDiffSetupData.file1.isBuffer) {
         gDiffSetupData.file2.isBuffer=true;
         gDiffSetupData.file1.useDisk=false;
      }
   }

   gDiffSetupData.DiffTags=symbolCompareOptionIsSet();
   if (!gDiffSetupData.DiffTags/* && ctlmore.p_caption=='&More <<'*/) {
      if (ctlpath1_firstline.p_visible && ctlpath1_firstline.p_text!='') {
         gDiffSetupData.file1.firstLine=(int)ctlpath1_firstline.p_text;
      }
      if (ctlpath1_lastline.p_visible && ctlpath1_lastline.p_text!='') {
         gDiffSetupData.file1.lastLine=(int)ctlpath1_lastline.p_text;
      }
      if (ctlpath2_firstline.p_visible && ctlpath2_firstline.p_text!='') {
         gDiffSetupData.file2.firstLine=(int)ctlpath2_firstline.p_text;
      }
      if (ctlpath2_lastline.p_visible && ctlpath2_lastline.p_text!='') {
         gDiffSetupData.file2.lastLine=(int)ctlpath2_lastline.p_text;
      }
   }
   if (ctlfile_width.p_text!='') {
      gDiffSetupData.RecordFileWidth=(int)ctlfile_width.p_text;
   }
   if ( ctlpath1symbolname.p_visible ) {
      parse ctlpath1symbolname.p_caption with "Symbol: " auto symbol1;
      // In the caption tehre may be double ampersands
      gDiffSetupData.file1.symbolName = stranslate(symbol1,'&','&&');
   }
   if ( ctlpath2symbolname.p_visible ) {
      parse ctlpath2symbolname.p_caption with "Symbol: " auto symbol2;
      // In the caption tehre may be double ampersands
      gDiffSetupData.file2.symbolName = stranslate(symbol2,'&','&&');
   }
   if ( _file_eq(gDiffSetupData.file1.fileName,gDiffSetupData.file2.fileName) ) {
      gDiffSetupData.file2.tryDisk=1;
   }
}

static int CheckDirectories()
{
   path1 := ctlpath1.p_text;
   if (EndsWithWildcard(path1)) {
      path1=_strip_filename(path1,'N');
   }
   if (!_DiffIsDirectory(path1)) {
      ctlpath1._text_box_error(nls("'%s' is not a valid path",path1));
      ctlsstab1.p_ActiveTab=0;
      return(1);
   }
   path2 := ctlpath2.p_text;
   if (!_DiffIsDirectory(path2)) {
      ctlpath2._text_box_error(nls("'%s' is not a valid path",path2));
      ctlsstab1.p_ActiveTab=0;
      return(1);
   }
   path1=_diff_absolute(path1);
   path2=_diff_absolute(path2);
   if (_file_eq(path1,path2)) {
      ctlpath2._text_box_error(nls("You must specify two separate paths"));
      return(1);
   }
   return(0);
}

static void GetDataForMultiFile(bool diffing_folders=true)
{
   if (_diff_is_untitled_filename(ctlpath1.p_text) || _diff_is_untitled_filename(ctlpath2.p_text)) {
      return;
   }
   if (EndsWithWildcard(ctlpath1.p_text)) {
      gDiffSetupData.file1.fileName=absolute(_strip_filename(ctlpath1.p_text,'N'));
      gDiffSetupData.FileSpec=_strip_filename(ctlpath1.p_text,'P');
      gDiffSetupData.file2.fileName=absolute(ctlpath2.p_text);
   }else{
      gDiffSetupData.file1.fileName=absolute(ctlpath1.p_text);
      gDiffSetupData.file2.fileName=absolute(ctlpath2.p_text);
      if (gDiffSetupData.FileSpec=='') {
         gDiffSetupData.FileSpec=ctlfilespecs.p_text;
         if (gDiffSetupData.FileSpec=='' && diffing_folders) {
            gDiffSetupData.FileSpec=ALLFILES_RE;
         }
      }else{
         gDiffSetupData.FileSpec=gDiffSetupData.FileSpec';'ctlfilespecs.p_text;
      }
      gDiffSetupData.fileListFile = ctlfile_list.p_text;
   }
   strip(gDiffSetupData.file1.fileName,'B','"');
   strip(gDiffSetupData.file2.fileName,'B','"');
   _maybe_append_filesep(gDiffSetupData.file1.fileName);
   _maybe_append_filesep(gDiffSetupData.file2.fileName);
   gDiffSetupData.ExcludeFileSpec=ctlexclude_filespecs.p_text;
   gDiffSetupData.Recursive=ctlrecursive.p_value!=0;
   gDiffSetupData.runInForeground=ctlrun_in_foreground.p_value!=0;
}

/**
 * Handles command events from the explorer tree context menu
 * 
 * @param cmdline 'addFave' or 'delFave' command
 */
_command void cbmenu_diffpath(_str cmdline="") name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY) {
   // parse the command and figure out what to do
   parse cmdline with auto cmd .;
   _str result='';
   origChangeDialog := setChangingDialog(true);
   wid := p_window_id;
   switch (upcase(cmd)) {
   case 'DIRECTORY':
      {
         _str init_dir= wid.p_prev.p_text;
         if (init_dir == "") {
            if (wid.p_prev == wid._find_control("ctlpath2")){
               path1 := wid._find_control("ctlpath1");
               if (path1 && path1.p_text != "") {
                  init_dir = _parent_path(path1.p_text);
               }
            }
         }
         if (!isdirectory(init_dir)) {
            // if it's not a directory maybe it's a filename...strip it off and try that
            init_dir = _strip_filename(init_dir, 'N');
            if (!isdirectory(init_dir)) {
               init_dir= "";
            }
         }
         if ( init_dir=="" ) {
            if ( !_no_child_windows() ) {
               init_dir=_mdi.p_child.p_buf_name;
            }else{
               init_dir = getcwd();
               _maybe_append_filesep(init_dir);
            }
            if ( init_dir!="" ) {
               init_dir = _file_path(init_dir);
            }
         }
         result = _ChooseDirDialog('',init_dir);
         if( result=='' ) break;
      }
      break;
   case 'FILE':
      initialDirectory := absolute(p_prev.p_text);
      if ( !isdirectory(initialDirectory) ) {
         initialDirectory = _file_path(initialDirectory);
      }
      result=_OpenDialog('-modal',
                         '',                   // Dialog Box Title
                         'Select file to diff',                   // Initial Wild Cards
                         '',
                         OFN_FILEMUSTEXIST,
                         '',
                         '',
                         initialDirectory
                         );
      break;
   case 'BUFFER':
      width := 0;
      temp_view_id := 0;
      int orig_view_id=_create_temp_view(temp_view_id);
      _build_buf_list(width,p_buf_id);
      top();up();
      p_window_id=orig_view_id;
      result=show('-modal _sellist_form',
                  'Choose a Buffer',
                  SL_VIEWID,
                  temp_view_id);
      if (result!='') {
         result=_buflist_name(' 'result);;
#if 0
         p_prev.p_prev.p_text=_buflist_name(' 'result);

         // Now we have to shut off the "use file on disk" checkbox.
         // If we are in the path one frame, there is an extra control 
         //  (More >> button).
         switch (p_prev.p_prev.p_name) {
         case 'ctlpath1':
         case 'ctlpath2':
            p_next.p_next.p_value=0;
            break;
         }
         p_prev.p_prev._set_focus();
#endif
      }
      break;
   }
   if (result!='') {
      result = strip(result,'B','"');
      p_window_id=wid.p_prev;
      p_text=result;
      end_line();
      _set_focus();
   }
   setChangingDialog(origChangeDialog);
}

void _browserefs.lbutton_up()
{
   origChangeDialog := setChangingDialog(true);
   do {
      wid := p_window_id;
   
      typeless result=_OpenDialog('-new -mdi -modal',
                         'Add Filename',
                         '',      // Initial wildcards
                         //'*.c;*.h',
                         def_file_types,
                         OFN_ALLOWMULTISELECT,
                         '',      // Default extension
                         '',      // Initial filename
                         ''       // Initial directory
                         );
      if (result=='') break;
      cur := "";
      all_items := "";
      p_window_id=wid.p_prev;
      for (;;) {
         cur=parse_file(result);
         cur=strip(cur,'B','"');
         if (cur=='') break;
         cur=_maybe_quote_filename(_strip_filename(cur,'P'));
         if (cur!='') {
            all_items :+= ' 'cur;
         }
      }
      all_items=strip(all_items);
      if (p_text=='') {
         p_text=all_items;
      }else{
         p_text :+= ' 'all_items;
      }
      end_line();
      p_window_id=wid;
      _set_focus();
   } while (false);
   setChangingDialog(origChangeDialog);
}

static bool dialogInFolderMode_slow()
{
   filename:=strip(ctlpath1.p_text,'B','"');
   if (EndsWithWildcard(filename)) {
      return true;
   }
   if (_DiffIsDirectory(filename)) {
      return true;
   }
   return false;
   //return ctltype_mf.p_value && ctltype_mf.p_enabled;
}

/**
 * Enable and disable controls based on whether the dialog is in
 * two file or mult-file mode
 */
static void enableCommonControls()
{
   if ( _haveProDiff() ) {
      ctlfilespecs_label.p_enabled = ctlinclude_help.p_enabled = ctlfilespecs.p_enabled = (ctlfile_list.p_text=="");
      ctlexclude_filespecs_label.p_enabled = ctlexclude_help.p_enabled = ctlexclude_filespecs.p_enabled = (ctlfile_list.p_text=="");
   }
#if 0
   ctlrecursive.p_enabled = dialogInFolderMode();
   ctlrun_in_foreground.p_enabled = dialogInFolderMode();
   if ( dialogInFolderMode() ) {
      ctlfilespecs_label.p_enabled = ctlinclude_help.p_enabled = ctlfilespecs.p_enabled = (ctlfile_list.p_text=="");
      ctlexclude_filespecs_label.p_enabled = ctlexclude_help.p_enabled = ctlexclude_filespecs.p_enabled = (ctlfile_list.p_text=="");
      ctlfile_list.p_enabled = ctlfile_list.p_prev.p_enabled = true;
   } else {
      ctlfilespecs_label.p_enabled = ctlinclude_help.p_enabled = ctlfilespecs.p_enabled = false;
      ctlexclude_filespecs_label.p_enabled = ctlexclude_help.p_enabled = ctlexclude_filespecs.p_enabled = false;
      ctlfile_list.p_enabled = ctlfile_list.p_prev.p_enabled = false;
   }
#endif

   ctlpath1.p_completion = FILENOQUOTES_ARG;
   ctlpath2.p_completion = FILENOQUOTES_ARG;
#if 0
   if (ctltype_mf.p_value) {
      ctlpath1.p_completion = DIRNOQUOTES_ARG;
      ctlpath2.p_completion = DIRNOQUOTES_ARG;
   } else {
      ctlpath1.p_completion = FILENOQUOTES_ARG;
      ctlpath2.p_completion = FILENOQUOTES_ARG;
   }
#endif
}

/**
 * Kill the timer used to enable or disable controls.  It is 
 * stored using _SetDialogInfoHt 
 * 
 * @param formWID Window id of the dialog box, this can change 
 *                since this is a timer callback
 */
static void killEnableControlTimer(CTL_FORM formWID)
{
   if ( !_iswindow_valid(formWID) || p_active_form.p_name!="_diffsetup_form" ) {
      return;
   }
   timerHandle := _GetDialogInfoHt("timerHandle",formWID);
   if ( timerHandle !=null ) {
      _SetDialogInfoHt("timerHandle",null);
      _kill_timer(timerHandle);
   }
}

/**
 * Enable controls according to what has happened in the dialog. 
 * This checks for expert mode which may further switch what 
 * mode the dialog is in (two files or multi-file) 
 * 
 * @param formWID Window id of the dialog box, this can change 
 *                since this is a timer callback
 */
static void enableControlCallback(CTL_FORM formWID)
{
   killEnableControlTimer(formWID);

   // Check to be very sure the right form is still active
   if ( !_iswindow_valid(formWID) || formWID.p_name!="_diffsetup_form" ) return;

   wid := p_window_id;
   p_window_id = formWID;
   enableCommonControls();

   p_window_id=wid;
}

/**
 * Set a timer to enable and disable controls on this dialog. 
 * Store the timer using _SetDialogInfoHt 
 */
static void setEnableControlTimer()
{
   if ( _GetDialogInfoHt("inSetTimer")==1 ) return;
   _SetDialogInfoHt("inSetTimer",1);
   killEnableControlTimer(p_active_form);
   timerHandle := _set_timer(100,enableControlCallback,p_active_form);
   _SetDialogInfoHt("timerHandle",timerHandle);
   _SetDialogInfoHt("inSetTimer",0);
}

void ctlpath1.on_change2(int reason,_str value="")
{
   if ( reason==CHANGE_DELKEY_2  
        && p_style==PSCBO_EDIT
        && p_AllowDeleteHistory ) {
      historyFilename := _ConfigPath():+DIFFMAP_FILENAME;
      status := _ini_delete_item(historyFilename,"Path1History",value);
      _ComboBoxDelete(value);
   }
   if (p_style==PSCBO_EDIT && p_completion!='') {
      ArgumentCompletionUpdateTextBox();
   }
}
static void handle_path_slash() {
   if (!_isUnix() || !def_unix_expansion) {
      keyin('/');
      return;
   }
   if (p_text=='~') {
      text:=_unix_expansion(p_text'/');
      set_command(text,length(text)+1);
   } else {
      keyin('/');
   }
}
void ctlpath1.'/'() {
   handle_path_slash();
}
void ctlpath2.'/'() {
   handle_path_slash();
}
void ctlfile_list.'/'() {
   handle_path_slash();
}

// Eventtable shared by both textboxes
void ctlpath1.on_change(int reason)
{
   if ( !getChangingDialog() ) {
      ctlsymbol1combo.p_text=COMPARE_WHOLE_FILES;
      ctlsymbol2combo.p_text=COMPARE_WHOLE_FILES;
      setSymbolCaption(1,"");
      setSymbolCaption(2,""); 
      setLineRangeCaption(1,0,0);
      setLineRangeVisible(1,false);
      setLineRangeCaption(2,0,0);
      setLineRangeVisible(2,false);
   }
   origChangeDialog := setChangingDialog(true);
   if (p_window_id==ctlpath1) {
      if ( !(def_diff_edit_flags&DIFFEDIT_NO_AUTO_MAPPING) ) {
         if ( _GetDialogInfoHt("path2SetByUser")!=true ) {
            SetupMappedPaths(ctlpath1.p_text);
         }
         //p_next.p_next.p_next.fillInSymbolComboAndTextBox();
         //ctlsymbol2combo.fillInSymbolComboAndTextBox();
      }
   }else if (p_window_id==ctlpath2 && _GetDialogInfoHt("InSetupMappedPaths")!=1 && p_active_form.p_visible) {
      gPath2Modified(1);
   }
   setChangingDialog(origChangeDialog);
   setEnableControlTimer();
#if SOURCE_DIFF_TOGGLE_ENABLE_DISABLE
   enableDisableSourceDiff();
#endif 
}


/**
 * @param filename 
 * 
 * @return bool returns true if <B>filename</B> has color coding
 */
static bool fileHasColorCoding(_str filename)
{
   langID := _DiffFilename2LangId(filename);
   _GetLanguageSetupOptions(langID, auto setup);

   hasColorCoding := false;
   if ( setup.lexer_name!="" ) {
      hasColorCoding = true;
   }
   return hasColorCoding;
}

#if SOURCE_DIFF_TOGGLE_ENABLE_DISABLE
/** 
 * Enable or disable source diff button between path1 and path2 
 * depending on whether or not the files have color coding 
 */
static void enableDisableSourceDiff()
{
   enableSourceDiff := true;
   file2HasColorCoding := false;
   file1HasColorCoding := fileHasColorCoding(ctlpath1.p_text);
   if ( file1HasColorCoding ) {
      file2HasColorCoding = fileHasColorCoding(GetPath2Filename());
   }
   enableSourceDiff = file1HasColorCoding && file2HasColorCoding;

   if ( enableSourceDiff != ctldiff_code.p_enabled ) {
      ctldiff_code.p_enabled = enableSourceDiff;
   }
}
#endif 

void ctlpath2.on_change2(int reason,_str value="")
{
   if ( reason==CHANGE_DELKEY_2  
        && p_style==PSCBO_EDIT
        && p_AllowDeleteHistory ) {
      if ( _last_char(value)==FILESEP ) {
         // Directory mode
      } else {
         historyFilename := _ConfigPath():+DIFFMAP_FILENAME;
         _ini_delete_item(historyFilename,"Path2History",value);
         _ComboBoxDelete(value);
      }
   }
   if (p_style==PSCBO_EDIT && p_completion!='') {
      ArgumentCompletionUpdateTextBox();
   }
}

void ctlpath2.on_change(int reason)
{
   if ( !getChangingDialog() ) {
#if 0
      // This also clears ctlpath1 line range settings which
      // we don't want
      ctlsymbol2combo.p_text=COMPARE_WHOLE_FILES;
      setSymbolCaption(1,"");
      setSymbolCaption(2,""); 
      setLineRangeCaption(1,0,0);
      setLineRangeVisible(1,false);
      setLineRangeCaption(2,0,0);
      setLineRangeVisible(2,false);
#endif

      _SetDialogInfoHt("path2SetByUser",true);
   }

#if SOURCE_DIFF_TOGGLE_ENABLE_DISABLE
   enableDisableSourceDiff();
#endif 
   setEnableControlTimer();
}

static void SetupMappedPaths(_str Path)
{
   origChangeDialog := setChangingDialog(true);
   do {
      SetText := p_active_form.p_visible;
      _str MapInfo:[]=null;
      MapInfo=gMapInfo();
   
      _str Path1Names[]=null;
      Path1Names=_GetDialogInfoHt("Path1Names");
   
      if (MapInfo._varformat()!=VF_HASHTAB) {
         // Nothing loaded yet...
         break;
      }
      _SetDialogInfoHt("InSetupMappedPaths",1);
      _str MappedPaths[]=null;
      _str MappedPathsTable:[];
   
      if (_DiffIsDirectory(Path,true)) {
         _maybe_append_filesep(Path);
      }else{
         Path=_strip_filename(Path,'N');
      }
      unCasedPath := Path;
      Path = _file_case(Path);
   
      int i,len_path=length(Path);

      for (i=0;i<Path1Names._length();++i) {
         _str cur_path=Path1Names[i];
         len_cur_path := length(cur_path);

         if (len_cur_path<=len_path) {
            if (substr(Path,1,len_cur_path)==cur_path) {
               AddToArray(MapInfo:[cur_path],MappedPaths,MappedPathsTable,substr(Path,len_cur_path+1),substr(unCasedPath,len_cur_path+1));
            }
         }
      }
   
      wid := p_window_id;
      p_window_id=ctlpath2;
      oldComplete := p_completion;
      p_completion = "";
      if (MappedPaths._length()) {
         _str items[]=null;
         GetHistoryItems(items);
         _lbclear();
         for (i=0;i<MappedPaths._length();++i) {
            _lbadd_item(MappedPaths[i]);
         }
         ReplaceHistoryItems(items);
         _lbtop();
      }
      _str text=ctlpath2._lbget_text();
      if (gPath2Modified()!=1 && text!='' && SetText/* &&
          !file_eq(text,_file_path(ctlpath2.p_text))*/ ) {
         ctlpath2.p_text=text;
      }else {
         ctlpath2._lbup();
      }
      p_completion = oldComplete;
      p_window_id=wid;
      _SetDialogInfoHt("InSetupMappedPaths",0);
   } while (false);
   setChangingDialog(origChangeDialog);
}

static void GetHistoryItems(_str (&items)[])
{
   _lbtop();_lbup();
   typeless status=_lbsearch('^$','r');
   if (status) {
      return;
   }
   for (;;) {
      status=_lbdown();
      if (status) break;
      items :+= _lbget_text();
   }
}

static void ReplaceHistoryItems(_str (&items)[])
{
   // This has to insert the blank item or it will cause other problems
   _lbbottom();
   _lbadd_item('');
   int i;
   for (i=0;i<items._length();++i) {
      _lbadd_item(items[i]);
   }
}

static void AddToArray(_str PathList,_str (&MappedPaths)[],_str (&MappedPathsTable):[],_str SuffixPath,_str unCasedSuffixPath)
{
   _str chr1=_chr(1);

   // This is a little error correction.  Not sure how these entries got in,
   // but I want to get them out
   while (pos(chr1:+chr1,PathList)) {
      PathList=stranslate(PathList,chr1,chr1:+chr1);
   }

   cur := "";
   for (;;) {
      parse PathList with cur (chr1) PathList;
      if (cur=='') break;
      _maybe_append_filesep(cur);
      whole_path := cur:+unCasedSuffixPath;
      if (!MappedPathsTable._indexin(_file_case(whole_path))) {
         MappedPaths :+= whole_path;
         MappedPathsTable:[_file_case(whole_path)]='';
      }
   }
}

void ctlsstab1.'A-n','A-N'()
{
   ctlpath1.MaybeInsertCurBufName();
}

void ctlpath1.'A-n','A-N'()
{
   MaybeInsertCurBufName();
}

void ctlpath2.'A-N'()
{
   MaybeInsertCurBufName();
}

static void MaybeInsertCurBufName()
{
   if (!_no_child_windows()) {
      p_text=_mdi.p_child.p_buf_name;
      _end_line();
   }
}

static bool symbolCompareOptionIsSet()
{
   return matchCaptionPrefix(ctlsymbol1combo.p_text,COMPARE_ALL_SYMBOLS);
}

static bool EndsWithWildcard(_str Path)
{
   Path=strip(Path,'B','"');
   p := lastpos(FILESEP,Path);
   if (!p) {
      return(false);
   }
   maybe_wildcard := substr(Path,p+1);
   if (iswildcard(maybe_wildcard)) {
      if (_isUnix()) {
         if (file_exists(Path)) {
            return false;
         }
      }
      return true;
   }
   return false;
}

static int showSymbolDialog(int &startLineNumber,int &endLineNumber,_str &symbolName,_str &tagInfo,bool findMatchAndReturn=false)
{
   //if (p_parent.p_height < p_y) {
   //   ctlmore.call_event(ctlmore,LBUTTON_UP);
   //}
   path1file := strip(ctlpath1.p_text,'B','"');
   if (!file_exists(path1file) || path1file=='') {
      _str msg=nls("File '%s1' does not exist.",path1file);
      if (path1file=='') {
         msg=nls("You must first fill in a filename");
      }
      _message_box(msg);
      return 1;
   }
   filename := "";
   _control ctlsymbol1combo,ctlsymbol2combo;
   if ( p_window_id==ctlsymbol1combo ) {
      filename = ctlpath1.p_text;
   }else if ( p_window_id==ctlsymbol2combo ) {
      filename = GetPath2Filename();
      // 3/16/2016
      // Removing "Use file on disk" checkboxes
      //useDisk  = ctlpath2_on_disk.p_value!=0;
   }
   filename=strip(filename,'B','"');
   FunctionName := "";
   parse ctlpath1symbolname.p_caption with 'Symbol:' symbolName;
   mou_hour_glass(true);
   // 3/16/2016
   // Removing "Use file on disk" checkboxes
   int status=_GetLineRangeWithFunctionInfo(filename,symbolName,tagInfo,startLineNumber,endLineNumber,findMatchAndReturn);
   FunctionName = symbolName;
   mou_hour_glass(false);
   return status;
}

/**
 * @param path "1" or "2"
 * @param visible 
 */
static void setLineRangeVisible(_str pathNum,bool visible)
{
   firstWID := _find_control("ctlpath":+pathNum:+"_firstline");
   if ( firstWID ) {
      firstWID.p_visible = visible;
      firstWID.p_next.p_visible = visible;
      firstWID.p_next.p_next.p_visible = visible;
      // Symbol label
      firstWID.p_next.p_next.p_next.p_visible = visible;
      firstWID.p_prev.p_visible = visible;
   }
}

/**
 * @param path "1" or "2"
 * @param visible 
 */
static void setLineRangeCaption(_str pathNum,int startLine,int endLine)
{
   origChangeDialog := setChangingDialog(true);
   firstWID := _find_control("ctlpath":+pathNum:+"_firstline");
   if ( firstWID ) {
      firstWID.p_text = startLine;
      firstWID.p_next.p_next.p_text = endLine;
   }
   setChangingDialog(origChangeDialog);
}

static void setSymbolCaption(_str pathNum,_str symbolCaption)
{
   firstWID := _find_control("ctlpath":+pathNum:+"symbolname");
   if ( firstWID ) {
      firstWID.p_caption = "Symbol: ":+stranslate(symbolCaption,"&&","&");
   }
}

static void setSymbolVisible(_str pathNum,bool visible)
{
   firstWID := _find_control("ctlpath":+pathNum:+"symbolname");
   if ( firstWID ) {
      firstWID.p_visible = visible;
   }
}

int _GetLineRangeWithFunctionInfo(_str filename,
                                  _str &FunctionName, _str &TagInfo,
                                  int &StartLineNumber,int &EndLineNumber,
                                  bool find_match_and_return=false,
                                  bool AlwaysLoadFromDisk=false)
{
   tag_name := "";
   tag_tree_decompose_caption(FunctionName,tag_name);
   int status;
   CommentLineNumber := 0;
   if (find_match_and_return) {
      status=FindSymbolInfo(filename,tag_name,FunctionName,
                            StartLineNumber,EndLineNumber,CommentLineNumber,TagInfo,
                            null,AlwaysLoadFromDisk);
   } else {
      status=GetSymbolInfo(filename,FunctionName,
                           StartLineNumber,EndLineNumber,CommentLineNumber,TagInfo,
                           null,AlwaysLoadFromDisk);
   }
   StartLineNumber=CommentLineNumber;
   if (!status) {
      //_str caption='';
      //parse FunctionName with caption "\t" .;
      //p_next.p_next.p_next.p_next.p_next.p_next.p_caption='Symbol:'caption;
      //p_next.p_next.p_next.p_next.p_next.p_next.p_user=FunctionName;
   }
   return(status);
}

static _str GetPath2Filename(bool UseFastIsDir=true)
{
   path := strip(ctlpath2.p_text);
   filename := "";
   if ( _diff_is_http_filename(path) 
        ||  diff_is_ftp_filename(path)
        || _diff_is_untitled_filename(path)
       ) {
      return(path);
   }
   _str abspath=_diff_absolute(path);

   // if path 2 is a directory, be sure we check if the dialog is in folder 
   // mode.  If it is, we don't want to append a filename.
   if ( _DiffIsDirectory(abspath,UseFastIsDir) && !dialogInFolderMode_slow() ) {
      filename=absolute(ctlpath1.DiffSetupBuildFilename(path));
   }else if ( _DiffIsDirectory(abspath,UseFastIsDir) ) {
      filename=abspath;
   }else if (file_match2(path,1,'-d -p')!='') {
      filename=absolute(path);
   }else if (buf_match(absolute(path),1,'E')!='') {
      filename=absolute(path);
   }else if ( _diff_is_untitled_filename(path) ) {
      filename=path;
   }else{
      return('');
   }
   return(filename);
}

static int CheckLineRanges()
{
   // 10:03:20 PM 10/23/2008
   // Doing this in new _diffsetup_line_range_form, and these are captions now
   // so they cannot be changed.  We don't have to do this anymore
   //int status=ctlpath1_firstline.CheckLineRangeOnDialog();
   //if (status) return(status);
   //
   //status=ctlpath2_firstline.CheckLineRangeOnDialog();
   //if (status) return(status);

   if (FilenamesInDialogMatch()) {
      if ( ctlpath1_firstline.p_visible ) {
         bool collision=CheckForLineCollisions((typeless)ctlpath1_firstline.p_text,
                                                  (typeless)ctlpath1_firstline.p_next.p_next.p_text,
                                                  (typeless)ctlpath2_firstline.p_text,
                                                  (typeless)ctlpath2_firstline.p_next.p_next.p_text);
         // 3/16/2016
         // Removing "Use file on disk" checkboxes
         if (collision/* && ctlpath1_on_disk.p_value == ctlpath2_on_disk.p_value*/) {
            _message_box(nls("Line ranges in the same file cannot overlap"));
            return(1);
         }
      }
   }

   return(0);
}

static bool NumberInRange(int a,int b,int c) {
   return (a!='' && a>=b && a<=c);
}

static bool CheckForLineCollisions(int rangeOneStart,int rangeOneEnd,
                                      int rangeTwoStart,int rangeTwoEnd)
{
   return(NumberInRange(rangeOneStart,rangeTwoStart,rangeTwoEnd) ||
          NumberInRange(rangeOneEnd,rangeTwoStart,rangeTwoEnd)   ||
          NumberInRange(rangeTwoStart,rangeOneStart,rangeOneEnd) ||
          NumberInRange(rangeTwoEnd,rangeOneStart,rangeOneEnd) );
}

static bool FilenamesInDialogMatch()
{
   filename1 := absolute(ctlpath1.p_text);
   _str filename2=GetPath2Filename();
   return(_file_eq(filename1,filename2));
}

static int CheckLineRangeOnDialog()
{
   error_message := "Line ranges must be valid integers greater than 0";
   int nextwid=p_next.p_next;
   if (p_text=='' || nextwid.p_text=='') {
      _text_box_error(error_message);
      return(1);
   }
   //if (p_text=='' && nextwid.p_text!='') {
   //   _text_box_error(error_message);
   //   return(1);
   //}
   //if (p_text!='' && nextwid.p_text=='') {
   //   nextwid._text_box_error(error_message);
   //   return(1);
   //}
   if (!isinteger(p_text)) {
      _text_box_error(error_message);
      return(1);
   }
   next_text := nextwid.p_text;
   if (!isinteger(next_text)) {
      nextwid._text_box_error(error_message);
      return(1);
   }
   if (p_text<1) {
      _text_box_error(error_message);
      return(1);
   }
   if (nextwid.p_text<1) {
      nextwid._text_box_error(error_message);
      return(1);
   }
   if (next_text<p_text) {
      _text_box_error("Illegal range");
      return(1);
   }
   return(0);
}

bool _DiffIsDirectory(_str Path,bool FastCheck=false)
{
   Path=strip(Path);
   Path=strip(Path,'B','"');
   Path=strip(Path);
   if (_file_eq(substr(Path,1,6),'ftp://')) {
      return(false);
   }
   if (_last_char(Path)==FILESEP) {
      return true;
   }
   if (FastCheck) {
      return(_last_char(Path)==FILESEP);
   }
   isDirStr := isdirectory(Path);
   isdir := strip(isDirStr)!=0 && strip(isDirStr)!="";
   if ( isdir ) {
      return(isdir);
   }
   if ( (_FileQType(Path)==VSFILETYPE_JAR_FILE || _FileQType(Path)==VSFILETYPE_GZIP_FILE  || _FileQType(Path)==VSFILETYPE_TAR_FILE) && _last_char(Path)==FILESEP ) {
      return true;
   }
   return false;
}

_str _diff_absolute(_str filename)
{
   if (_diff_is_http_filename(filename) ||
       diff_is_ftp_filename(filename) ||
       buf_match(filename,1,'E')!="") {
      return(filename);
   }
   return(absolute(filename));
}

bool _diff_is_http_filename(_str filename)
{
   return(_isHTTPFile(filename)!=0);
}

bool _diff_is_untitled_filename(_str filename)
{
   return substr(filename,1,length(NO_NAME))==NO_NAME;
}

static bool diff_is_ftp_filename(_str filename)
{
   return(strieq(substr(translate(filename,'/','\'),1,6),'ftp://'));
}

static _str DiffSetupBuildFilename(_str Path)
{
   _maybe_append_filesep(Path);
   filename := _diff_absolute(Path):+_strip_filename(p_text,'P');
   return(filename);
}

static void LoadHistory(_str SectionName)
{
   _str HistoryFilename=_ConfigPath():+DIFFMAP_FILENAME;
   temp_view_id := 0;
   orig_view_id := p_window_id;
   int status=_ini_get_section(HistoryFilename,SectionName,temp_view_id);
   if (status) return;
   p_window_id=temp_view_id;
   top();up();
   while (!down()) {
      line := "";
      get_line(line);
      p_window_id=orig_view_id;
      _lbadd_item(line);
      p_window_id=temp_view_id;
   }
   p_window_id=orig_view_id;
   _lbtop();
   _delete_temp_view(temp_view_id);
}


defeventtab _diffsetup_line_range_form;

void ctlok.on_create(int *pStartLinenum,int *pEndLinenum,_str filename="",bool isBufferID=false)
{
   // Don't initialize pStartLinenum because it is either initialized to 0 or 
   // the current line number already  
   //*pStartLinenum = 0;
   *pEndLinenum   = 0;
   if ( filename == "" ) {
      ctledit1.p_visible     = false;
      ctlnotelabel.p_visible = false;
   }else{
      wid := p_window_id;
      p_window_id=ctledit1;

      // Open filename passed in, 
      options := "";
      if ( isBufferID ) {
         options = "+bi "filename;
         filename="";
      }
      status := _open_temp_view(filename,auto temp_wid,auto orig_wid,options);
      if ( !status ) {
         p_window_id = temp_wid;
         _SetEditorLanguage();
         lang := p_LangId;
         markid := _alloc_selection();
         top();_select_line(markid);
         bottom();_select_line(markid);
         p_window_id = orig_wid;

         status=_copy_to_cursor(markid);
         _SetEditorLanguage(lang);
         top();
         status=_delete_line();
         if ( pStartLinenum && *pStartLinenum!=0 ) {
            p_line = *pStartLinenum;
         }

         // Give this buffer a name so we can check to be sure it is deleted
         p_buf_name = "TEMP VERSION OF "filename;
         _free_selection(markid);
         _SetDialogInfoHt("fileInMem",0);
         _SetDialogInfoHt("origReadOnly",p_ReadOnly);
         _delete_temp_view(temp_wid);
         p_ReadOnly  = true;
      }else{

      }
      p_window_id = wid;
   }
   _SetDialogInfoHt("pStartLinenum",pStartLinenum);
   _SetDialogInfoHt("pEndLinenum",pEndLinenum);
}

void ctlok.lbutton_up()
{
   if ( ctlstart_line.CheckLineRangeOnDialog() ) {
      return;
   }
   int *pStartLinenum = _GetDialogInfoHt("pStartLinenum");
   int *pEndLinenum   = _GetDialogInfoHt("pEndLinenum");
   *pStartLinenum = (int)ctlstart_line.p_text;
   *pEndLinenum = (int)ctlend_line.p_text;
   p_active_form._delete_window();
}

void _diffsetup_line_range_form.on_resize()
{
   if ( _GetDialogInfoHt("inOnResize")!=null ) {
      return;
   }
   _SetDialogInfoHt("inOnResize",1);
   yBuffer := ctledit1.p_y;
   topY := ctledit1.p_y;
   leftX := ctledit1.p_x;

   clientWidth := _dx2lx(SM_TWIP,p_client_width);
   clientWidthDiff := p_active_form.p_width - clientWidth;

   clientHeight := _dy2ly(SM_TWIP,p_client_height);
   clientHeightDiff := p_active_form.p_height - clientHeight;

   ctlstart_line.p_prev.p_x = leftX;
   ctlstart_line.p_x = ctlstart_line.p_prev.p_x + ctlstart_line.p_prev.p_width + leftX;

   ctlend_line.p_prev.p_x = ctlstart_line.p_prev.p_x;
   ctlend_line.p_x = ctlstart_line.p_x;

   ctlnotelabel.p_x = ctlstart_line.p_x_extent+leftX;
   ctlstart_line.p_y = topY + yBuffer;

   ctlok.p_x = ctlstart_line.p_prev.p_x;
   ctlok.p_next.p_x = ctlok.p_x_extent+leftX;

   if ( ctledit1.p_visible ) {
      ctledit1.p_y = topY;
      editSpace := clientHeight - (2*topY);
      editSpace -= (2*ctlstart_line.p_height)+(2*topY);
      editSpace -= ctlok.p_height+topY;

      ctledit1.p_height = editSpace;

      topY = ctledit1.p_y_extent+yBuffer;
      ctledit1.p_width = clientWidth - (2*leftX);
   }

   {
      ctlstart_line.p_y = topY;
      ctlstart_line.p_prev.p_y = topY;
      ctlnotelabel.p_y = topY;
   
      ctlend_line.p_y = ctlstart_line.p_y_extent+yBuffer;
      ctlend_line.p_prev.p_y = ctlstart_line.p_y_extent+yBuffer;
   
      ctlok.p_y = ctlend_line.p_y_extent+yBuffer;
      ctlok.p_next.p_y = ctlend_line.p_y_extent+yBuffer;
   
      if ( !ctledit1.p_visible ) {
         p_active_form.p_width = ctlend_line.p_x_extent+leftX+clientWidthDiff;
         p_active_form.p_height = ctlok.p_y_extent+yBuffer+clientHeightDiff;
         p_active_form.p_border_style = BDS_DIALOG_BOX;
      }
   }


   _SetDialogInfoHt("inOnResize",null);
}

void ctledit1.lbutton_down()
{
   mou_click();
   if ( select_active() ) {
      _select_type('','T',"LINE");
   }
}

void ctledit1.'range-first-nonchar-key'-'all-range-last-nonchar-key',' ', 'range-first-mouse-event'-'all-range-last-mouse-event',ON_SELECT()
{
   lineRangeFormEditControlEventHandler();
}
  
static void lineRangeFormEditControlEventHandler()
{
   origChangeDialog := setChangingDialog(true);
   do {
      typeless lastevent=last_event();
      _str eventname=event2name(lastevent);
      if (eventname=='F1') {
         p_active_form.call_event(defeventtab _ainh_dlg_manager,F1,'e');
         break;
      }
      if (eventname=='A-F4' || eventname=='ESC') {
         ctlcancel.call_event(ctlcancel,LBUTTON_UP);
         return;
      }else if ( eventname=='TAB' ) {
         // We cannot edit, so do not allow tab, just change focus
         ctlstart_line._set_focus();
         break;
      }else if ( eventname=='S-TAB' ) {
         // We cannot edit, so do not allow tab, just change focus
         ctlcancel._set_focus();
         break;
      }
      typeless junk='';
      int key_index=event2index(lastevent);
      int name_index=eventtab_index(
         _default_keys,ctledit1.p_mode_eventtab,key_index);
      command_name := name_name(name_index);
   
      //This is to handle C-X combinations
      if (name_type(name_index)==EVENTTAB_TYPE) {
         int eventtab_index2=name_index;
         typeless event2=get_event('k');
         key_index=event2index(event2);
         name_index=eventtab_index(eventtab_index2,eventtab_index2,key_index);
         command_name=name_name(name_index);
      }
      index := find_index(command_name,COMMAND_TYPE);
      if (index && index_callable(index)) {
         call_index(index);
         if ( select_active() ) {
             _select_type('','T',"LINE");
            _str old_mark;
            mark_status := 1;
            mark_status=save_selection(old_mark);
              save_pos(auto p);
             _begin_select();
            ctlstart_line.p_text = p_line;
            _end_select();
            ctlend_line.p_text = p_line;
            restore_pos(p);
            restore_selection(old_mark);
         }
      }
   } while (false);
   setChangingDialog(origChangeDialog);
}
