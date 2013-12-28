////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47140 $
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
#include "diff.sh"
#include "minihtml.sh"
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
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "varedit.e"
#endregion

using namespace se.diff;
using namespace se.datetime;

int def_diff_dialog_expert_mode=0;

defeventtab _diffsetup_form;

#define SOURCE_DIFF_TOGGLE_ENABLE_DISABLE 0

#define SETUP_DIALOG_HEIGHT    6750
#define SETUP_DIALOG_MIN_WIDTH 11145

void _diffsetup_form.on_resize()
{
   clientWidth  := p_width;
   clientHeight := p_height;

   xbuffer := ctlsession_tree.p_x;
   
   ctlsession_tree.p_redraw = 0;
   ctlsession_tree.p_width = (int)round(clientWidth*.215,0);
   //ctlsession_tree.p_redraw = 1;

   if ( ctlsession_tree.p_visible ) {
      ctlsstab1.p_x = ctlsession_tree.p_x + ctlsession_tree.p_width + xbuffer;
   }
   ctlsstab1.p_width = (int)round(clientWidth*.785,0) - (3*xbuffer);

   ctlsstab1.sizeFilesFrame();
}

static void sizePathFrame(int tabClientWidth)
{
   widthDiff := tabClientWidth - (p_width + 2*p_x);
   p_width += widthDiff;
   pictureWID := p_child;
   pictureWID.p_width += widthDiff;

   pathWID := pictureWID.p_child;
   button1WID := pathWID.p_next;
   button2WID := button1WID.p_next;
   typeWID := button2WID.p_next;

   pathWID.p_width += widthDiff;
   button1WID.p_x += widthDiff;
   button2WID.p_x += widthDiff;
   typeWID.p_width += widthDiff;
}

static void sizeFilesFrame()
{
   clientWidth  := p_child.p_width;
   padding := ctlsession_tree.p_x;
   ctlminihtml1.p_width = (clientWidth - ctlminihtml1.p_x) - padding;

   ctlpath1_frame.sizePathFrame(clientWidth);
   ctlpath2_frame.sizePathFrame(clientWidth);

   ctlfilespecs.p_width = clientWidth - (ctlfilespecs.p_x+padding);
   ctlexclude_filespecs.p_width = clientWidth - (ctlexclude_filespecs.p_x+padding);
}

void ctlcode_diff.lbutton_up()
{
   origChangeDialog := setChangingDialog(true);

   if ( p_value ) {
      ctldiff_code.p_picture = _pic_diff_code_bitmap;
   }else{
      ctldiff_code.p_picture = _pic_del_diff_code_bitmap;
   }

   setChangingDialog(origChangeDialog);
}
void ctlexpand_tabs.lbutton_up()
{
   handleChangeInSessionsTree();
}
void ctlfilespecs.on_change(int reason)
{
   handleChangeInSessionsTree();
}
void ctlpath1_firstline.on_change()
{
   handleChangeInSessionsTree();
}
void ctlrecursive.lbutton_up()
{
   handleChangeInSessionsTree();
}
void ctltype_text.lbutton_up()
{
   ArgumentCompletionTerminate();
   setEnableControlTimer();
   handleChangeInSessionsTree();
}
void ctlmismatch_size_date.lbutton_up()
{
   ctlmismatch_date_only.p_enabled = ctlmismatch_size_date.p_value!=0;
   handleChangeInSessionsTree();
}

#define LOAD_BUTTON_CAPTION 'Previous diff...'

////////////////////////////////////////////////////////////////////////////////
//
// gMapInfo is a hashtable of all of the path mapping information.  For example:
// gMapInfo:['e:\']=g:\<ASCII1>\\rodney\
#define gMapInfo            ctlpath1.p_user

////////////////////////////////////////////////////////////////////////////////
// gPath1Names is an array in the order of the path1 entries.  We need this to
// to preserve the order because we cannot count on the order of a hashtable
// Now use _SetDialogInfoHt(Path1Names)
//#define gPath1Names         ctlpath1.p_cb_list_box.p_user

////////////////////////////////////////////////////////////////////////////////
// Used to keep track of if we have expanded the dialog once for some sizing
// issues
#define EXPANDED_ONCE       ctlmore.p_user

////////////////////////////////////////////////////////////////////////////////
// Used to keep track of info when the user clicks the "Symbol..." button and
// selects something
#define gTagInfo            ctlpath1symbolname.p_user


////////////////////////////////////////////////////////////////////////////////
// Set to 1 if the user has typed in the "Path 2" combobox (ctlpath2)
#define gPath2Modified      ctlpath2.p_user

////////////////////////////////////////////////////////////////////////////////
// Set to 1 if in the SetupMappedPaths function
// Now use _SetDialogInfoHt("gInSetupMappedPaths");
//#define gInSetupMappedPaths ctlpath2.p_cb_list_box.p_user

#define ArrayAppend(a,b) a[a._length()]=b

// Indexes for _SetDialogInfo and _GetDialogInfo
#define RESTORE_FROM_INI     0
#define LAST_TEXTBOX_WID     1

static int gTimerHandle=-1;

void ctlpath1.on_got_focus()
{
   ArgumentCompletionTerminate();
   ctlmove_path.p_picture = _pic_diff_path_down;
   ctlmove_path.p_message = "Copy Path 1 to Path 2";
}

void ctlpath2.on_got_focus()
{
   ArgumentCompletionTerminate();
   ctlmove_path.p_picture = _pic_diff_path_up;
   ctlmove_path.p_message = "Copy Path 2 to Path 1";
}

/**
 * Call with true when modifying textboxes or checkboxes and 
 * with false when done 
 * 
 * @param setting true if programatically setting dialog items
 */
static boolean setChangingDialog(boolean setting)
{
   orig := getChangingDialog();
   _SetDialogInfoHt("changingDialog",setting);
   return orig;
}

static boolean getChangingDialog()
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
   int curWID = 0;
   int lastWID = 0;
   origDiffEditOptions := def_diff_edit_options;
   def_diff_edit_options |= DIFFEDIT_NO_AUTO_MAPPING;

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

   def_diff_edit_options = origDiffEditOptions;
   setChangingDialog(origChangeDialog);
}

static void swapPath()
{
   origChangeDialog := setChangingDialog(true);
   int curWID = 0;
   int lastWID = 0;
   int curCBWID = 0;
   int lastCBWID = 0;
   completion1 := ctlpath1.p_completion;
   completion2 := ctlpath2.p_completion;

   // Have to set p_completion to keep combo from dropping down when the
   // text is set
   ctlpath1.p_completion = NONE_ARG;
   ctlpath2.p_completion = NONE_ARG;

   origDiffEditOptions := def_diff_edit_options;
   def_diff_edit_options |= DIFFEDIT_NO_AUTO_MAPPING;

   _nocheck _control ctlpath1_on_disk;
   _nocheck _control ctlpath2_on_disk;
   if ( ctlmove_path.p_picture==_pic_diff_path_up ) {
      curWID = ctlpath1;
      curCBWID = ctlpath1_on_disk;

      lastWID = ctlpath2;
      lastCBWID = ctlpath2_on_disk;
   } else {
      curWID = ctlpath2;
      curCBWID = ctlpath2_on_disk;

      lastWID = ctlpath1;
      lastCBWID = ctlpath1_on_disk;
   }

   tempName := curWID.p_text;
   curWID.p_text = lastWID.p_text;
   lastWID.p_text = tempName;

   tempVal := curCBWID.p_value;
   curCBWID.p_value = lastCBWID.p_value;
   lastCBWID.p_value = tempVal;

   ctlpath1.p_completion = completion1;
   ctlpath2.p_completion = completion2;

   curWID._set_focus();
   curWID._end_line();

   def_diff_edit_options = origDiffEditOptions;
   setChangingDialog(origChangeDialog);
}

void ctlswap_path.lbutton_up()
{
   swapPath();
}

static void setLinkButtonPicture()
{
   if ( def_diff_edit_options&DIFFEDIT_NO_AUTO_MAPPING ) {
      ctllink.p_picture = _pic_del_linked_bitmap;
      ctlauto_mapping.p_value = 0;
   }else{
      ctllink.p_picture = _pic_linked_bitmap;
      ctlauto_mapping.p_value = 1;
   }
}

void ctllink.lbutton_up()
{
   _SetDialogInfoHt("inLinkButton",1);
   if ( def_diff_edit_options&DIFFEDIT_NO_AUTO_MAPPING ) {
      def_diff_edit_options &= ~DIFFEDIT_NO_AUTO_MAPPING;
   }else{
      def_diff_edit_options |= DIFFEDIT_NO_AUTO_MAPPING;
   }
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

void ctlauto_mapping.lbutton_up()
{
   inLinkButton := _GetDialogInfoHt("inLinkButton");

   // If we are already in code from the ctllink button or the
   // dialog is coming up, stop
   if ( inLinkButton==1 || !p_active_form.p_visible ) return;

   ctllink.call_event(ctllink,LBUTTON_UP);
}

static boolean OptionsOnly()
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
}

ctlsstab1.on_change(int reason,int tabIndex=0)
{
   switch (reason) {
   case CHANGE_TABACTIVATED:
      if (tabIndex==0) {
         // This keeps the dialog from doing some ugly things if
         // the "Files" tab is activated by pressing F7/F8
         ctlsstab1.refresh();
      }else if (tabIndex==1) {
         // Options tab activated.
         ctltree1._set_focus();
      }
      break;
   }
}

#define SESSION_CAPTION_CURRENT "Current session"
#define SESSION_CAPTION_RECENT "Recent sessions"
#define SESSION_CAPTION_YESTERDAY "Yesterday"
#define SESSION_CAPTION_TODAY "Today"
#define SESSION_CAPTION_OLDER "Older"
#define SESSION_CAPTION_NAMED "Named sessions"
#define COMPARE_WHOLE_FILES "Compare lines: all"
#define COMPARE_LINE_RANGE  "Compare lines: range..."
#define COMPARE_ALL_SYMBOLS "Compare symbols: all"
#define COMPARE_CUR_SYMBOL  "Compare symbols: current symbol in file[ $$$ ]..."
#define COMPARE_ONE_SYMBOL  "Compare symbols: choose symbol..."
#define USERINFO_DELIMITER "==="

static void setupSessionTree(boolean loadFromDisk=false,boolean selectMostRecent=false,boolean &selectedSession=false)
{
   selectedSession = false;
   int wid=p_window_id;
   _control ctlsession_tree;
   p_window_id=ctlsession_tree;
   _TreeDelete(TREE_ROOT_INDEX,'C');

   if ( loadFromDisk ) {
      // We are initializing
      DiffSessionColletction diffSessionData;
      _SetDialogInfoHt("diffSessions",diffSessionData);
   }
   DiffSessionColletction *pdiffSessionData = _GetDialogInfoHtPtr("diffSessions");
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

static boolean isValidSessionNode(int nodeIndex)
{
   boolean valid = false;

   _TreeGetInfo(nodeIndex,auto state,auto bmIndex);
   valid = nodeIndex != TREE_ROOT_INDEX && bmIndex != _pic_project;

   return valid;
}

static boolean isNamedSessionNode(int nodeIndex)
{
   boolean valid = false;

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

static void sessionTreeOnChange(int reason,int index)
{
   curIndex := _TreeCurIndex();
   if ( curIndex>-1 && isValidSessionNode(curIndex) ) {
      parse _TreeGetUserInfo(curIndex) with auto sessionDate (USERINFO_DELIMITER) auto sessionID;
      DiffSessionColletction *pdiffSessionData = _GetDialogInfoHtPtr("diffSessions");
      DIFF_SETUP_DATA curSetupData = pdiffSessionData->getSession((int)sessionID);
      if ( curSetupData!=null ) {
   
         origChangingDialog := setChangingDialog(true);
         ctlpath1.p_text = curSetupData.File1Name;
         ctlpath2.p_text = curSetupData.File2Name;
         ctlsymbol1combo.fillInSymbolCombo();
         ctlsymbol2combo.fillInSymbolCombo();

         ctlfilespecs.p_text = curSetupData.FileSpec;
         ctlexclude_filespecs.p_text = curSetupData.ExcludeFileSpec;
         setChangingDialog(origChangingDialog);

         ctlpath1_on_disk.p_value = (int)!curSetupData.File1IsBuffer;
         ctlpath2_on_disk.p_value = (int)!curSetupData.File2IsBuffer;
   
         if ( curSetupData.Symbol1Name!="" ) {
            curSetupData.File1FirstLine=0;
            curSetupData.File1LastLine=0;
            status := GetLineRangeWithFunctionInfo(curSetupData.File1Name,curSetupData.Symbol1Name,auto TagInfo="",curSetupData.File1FirstLine,curSetupData.File1LastLine,true,ctlpath1_on_disk.p_value!=0);
            if ( !status ) {
               setLineRangeCaption('1',curSetupData.File1FirstLine,curSetupData.File1LastLine);
               setLineRangeVisible('1',true);

               setSymbolCaption('1',curSetupData.Symbol1Name);
               setSymbolVisible('1',true);
            }
         }
   
         if ( curSetupData.Symbol2Name!="" ) {
            curSetupData.File2FirstLine=0;
            curSetupData.File2LastLine=0;
            status := GetLineRangeWithFunctionInfo(curSetupData.File2Name,curSetupData.Symbol2Name,auto TagInfo="",curSetupData.File2FirstLine,curSetupData.File2LastLine,true,ctlpath2_on_disk.p_value!=0);
         }
         ctlsymbol1combo.setSymbolAndLineRange('1',curSetupData.Symbol1Name,curSetupData.File1FirstLine,curSetupData.File1LastLine);
         ctlsymbol2combo.setSymbolAndLineRange('2',curSetupData.Symbol2Name,curSetupData.File2FirstLine,curSetupData.File2LastLine);
         if ( curSetupData.DiffTags ) {
            ctlsymbol1combo.findCaption(COMPARE_ALL_SYMBOLS);
         }
         SetDiffCompareOptionsOnDialog(curSetupData.compareOptions);

         expertModeEnableControls();

         // Only set recursive if it was set in this session and this is a
         // multi-file diff.  This way the diff will be right when switching
         // from a file to a multi-file diff.
         if ( ctltype_mf.p_value ) {
            ctlrecursive.p_value = (int)curSetupData.Recursive;
         }
      }


      if ( curSetupData.Symbol1Name==""  && curSetupData.Symbol2Name=="" ) {
         if ( curSetupData.File1FirstLine >0 ) {
            setLineRangeCaption('1',curSetupData.File1FirstLine,curSetupData.File1LastLine);
            setLineRangeVisible('1',true);
            ctlsymbol1combo.findCaption(COMPARE_LINE_RANGE);
         }
         if ( curSetupData.File2FirstLine>0 ) {
            setLineRangeCaption('2',curSetupData.File2FirstLine,curSetupData.File2LastLine);
            setLineRangeVisible('2',true);
            ctlsymbol2combo.findCaption(COMPARE_LINE_RANGE);
         }
      }

      ctldeletesession.p_enabled = 1;
      _SetDialogInfoHt("lastSessionID",curSetupData.sessionID);
   }else{
      ctldeletesession.p_enabled = 0;
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
   origChangeDialog := getChangingDialog();
   if ( origChangeDialog ) {
      return;
   }
   setChangingDialog(true);
   sessionTreeOnChange(reason,index);
   setChangingDialog(origChangeDialog);
}

static void insertSessionsInTree(int recentSessionIndex,int namedSessionIndex,int todaySessionIndex,int yesterdaySessionIndex,int olderSessionIndex,DiffSessionColletction &allDiffSessionData)
{

   se.datetime.DateTimeInterval todayTest(DTI_AUTO_TODAY);
   se.datetime.DateTimeInterval yesterdayTest(DTI_AUTO_YESTERDAY);

   int numTodaySessions=0,numYesterdaySessions=0,numOlderSessions=0;
   allDiffSessionData.enumerateSessionIDs(auto sessionIDs);
   foreach ( auto curSessionID in sessionIDs ) {
      curDiffSession := allDiffSessionData.getSession(curSessionID);
      if ( curDiffSession.sessionName==DiffSessionColletction.getDefaultSessionName() ) {
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
      if ( curDiffSession.sessionName==DiffSessionColletction.getDefaultSessionName()  ) {
         if ( last_char(curDiffSession.File1Name)==FILESEP &&
              last_char(curDiffSession.File2Name)==FILESEP ) {
            cap = curDiffSession.File1Name:+" <===> ":+curDiffSession.File2Name;
         }else{
            justname1 := _strip_filename(curDiffSession.File1Name,'p');
            justname2 := _strip_filename(curDiffSession.File2Name,'p');
            if ( file_eq(justname1,justname2) ) {
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

static int getBitmapIndexForSession(DIFF_SETUP_DATA diffSession)
{
   bitmapIndex := 0;
   if ( last_char(diffSession.File1Name)==FILESEP &&
        last_char(diffSession.File2Name)==FILESEP ) {
      bitmapIndex = _pic_fldopen;
   }else{
      if ( diffSession.Symbol1Name!="" || diffSession.Symbol2Name!="" ) {
         bitmapIndex = _pic_diff_one_symbol;
      }else if ( diffSession.DiffTags ) {
         bitmapIndex = _pic_diff_all_symbols;
      }else{
         bitmapIndex = _pic_file;
      }
   }
   return bitmapIndex;
}


void ctlok.on_create(_str filename1='',boolean OptionsOnly=false,boolean RestoreFromINI=false)
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
   oncreateFiles(filename1,OptionsOnly);

   origDiffCode := ctldiff_code.p_picture;
   // Have to do this first, mostly to be sure that ctlrecursive.p_value is set
   // so that if the user changes from a file diff restored from the last 
   // session to a multi-file diff, the option is still set properly

   if ( def_diff_edit_options&DIFFEDIT_CURFILE_INIT ) {
      // Use the filename passed in.  This will be the current filename or
      // the directory name
      ctlpath1.p_text=filename1;
   }else{
      _retrieve_prev_form();
   }
   setupSessionTree(true,!(def_diff_edit_options&DIFFEDIT_CURFILE_INIT),auto selectedSession);
   if ( !(def_diff_edit_options&DIFFEDIT_CURFILE_INIT) && !selectedSession ) {
      _retrieve_prev_form();
   }
   ctldiff_code.p_picture = origDiffCode;

   oncreateOptions();
   _SetDialogInfo(RESTORE_FROM_INI,RestoreFromINI);
   ctlsymbol1combo.call_event(CHANGE_CLINE,ctlsymbol1combo,ON_CHANGE,'W');
   ctlsymbol2combo.call_event(CHANGE_CLINE,ctlsymbol2combo,ON_CHANGE,'W');
#if SOURCE_DIFF_TOGGLE_ENABLE_DISABLE
   enableDisableSourceDiff();
#endif 
   ctlpath1._set_sel(1,ctlpath1.p_text._length()+1);
   setChangingDialog(origChangeDialog);
}

static void _diffsetup_form_initial_alignment()
{
   if (!_default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS)) {
      ctlpath1_buffer.p_visible=ctlpath2_buffer.p_visible=0;
   }

   // size the buttons to the textbox
   rightAlign := ctlpath1_pic.p_width - ctlpath1.p_x;
   sizeBrowseButtonToTextBox(ctlpath1.p_window_id, ctlbrowsedir.p_window_id, ctlpath1_buffer.p_window_id);
   sizeBrowseButtonToTextBox(ctlpath2.p_window_id, ctlimage1.p_window_id, ctlpath2_buffer.p_window_id);

   // keep these buttons from getting smooshed
   buttonSpace := 10;
   px := ctlsstab1.p_child.p_width - (ctllink.p_width + ctlmove_path.p_width + ctlswap_path.p_width +
                                      ctldiff_code.p_width + 3 * buttonSpace);
   px = px intdiv 2;
   ctllink.p_x = px;
   ctlmove_path.p_x = ctllink.p_x + ctllink.p_width + buttonSpace;
   ctlswap_path.p_x = ctlmove_path.p_x + ctlmove_path.p_width + buttonSpace;
   ctldiff_code.p_x = ctlswap_path.p_x + ctlswap_path.p_width + buttonSpace;
}

static void setupFont()
{
   _str font_name='';
   typeless font_size='';
   typeless flags='';
   typeless charset='';
   parse _default_font(CFG_DIALOG) with font_name','font_size','flags','charset;
   //parse _default_font(CFG_FUNCTION_HELP) with font_name','font_size','flags','charset;
   if (!isinteger(charset)) charset=-1;
   if (!isinteger(font_size)) font_size=8;
   if (font_name!="") {
      ctlminihtml1._minihtml_SetProportionalFont(font_name,charset);
   }
   if (isinteger(font_size)) {
      ctlminihtml1._minihtml_SetProportionalFontSize(3,font_size*10);
   }
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

static void oncreateFiles(_str filename1,boolean OptionsOnly)
{
   origChangeDialog := setChangingDialog(true);
   do {
      if (OptionsOnly) {
         ctlsstab1._setEnabled(0,0); // Files tab
         ctlsstab1.p_ActiveTab=1;    // Options tab
         ctlsession_tree.p_visible = ctlsession_tree.p_prev.p_visible = 0;
         ctlsstab1.p_x = ctlsession_tree.p_x;
         ctlsave_session.p_visible = 0;
         ctlsave_session.p_next.p_next.p_x = ctlsave_session.p_x;

         ctldeletesession.p_visible = 0;
         ctldeletesession.p_next.p_next.p_x = ctldeletesession.p_x;

         break;
      }
      ctlminihtml1.p_backcolor=0x80000022;
      _str HtmlLine='To compare directories, set <B>Path 1</B> and <B>Path 2</B> to directory names, and then set <B>Filespecs</B> to a list of wildcards (<B>ex:</B>*.c *.h), and <B>Exclude Filespecs</B> to a list of wildcards you do not want included in the compare (<B>ex:</B>junk*).<P>Use the <B>'LOAD_BUTTON_CAPTION'</B> button to load results of saved directory compares.<P>When comparing files, if the filenames only differ by path, you only need to specify a directory for <B>Path 2</B>.<P>Use F7/F8 to select past dialog responses.';
      ctlminihtml1.p_text=HtmlLine;
      if (def_diff_edit_options & DIFFEDIT_CURFILE_INIT) {
         // Use the filename passed in.  This will be the current filename or
         // the directory name
         ctlpath1.p_text=filename1;
      }
   
      int wid=p_window_id;
      p_window_id=ctlpath2;
      _lbbottom();
      _lbadd_item('');
      LoadHistory("Path2History");
      p_window_id=wid;
   
      if (!ctltype_text.p_value && !dialogInFolderMode()) {
         // If no radio button is selected, select one
   
         ctltype_text.p_value=1;
      }
      //ctlmore.call_event(ctlmore,LBUTTON_UP);
   
      _str MapInfo:[]=null;
      _str Path1Names[]=null;
      LoadMapInfo(Path1Names,MapInfo);
      gMapInfo=MapInfo;
      _SetDialogInfoHt("Path1Names",Path1Names);

      if ( def_diff_options&DIFF_NO_SOURCE_DIFF ) {
         ctldiff_code.p_picture = _pic_del_diff_code_bitmap;
      }else{
         ctldiff_code.p_picture = _pic_diff_code_bitmap;
      }
   
   
      ctlfilespecs.LoadHistory("FilespecsHistory");
      ctlexclude_filespecs.LoadHistory("ExcludeFilespecsHistory");
   
      ctlpath1.LoadHistory("Path1History");
   
      ctlpath1.SetupMappedPaths(ctlpath1.p_text);
   
      if ( def_diff_edit_options&DIFFEDIT_NO_AUTO_MAPPING ) {
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
 * @return boolean true if <b>modifiedCaption</b> "matches" 
 *         <b>caption</b>
 */
static boolean matchCaptionPrefix(_str modifiedCaption,_str origCaption)
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
   status := search('^?'_escape_re_chars(origCaption),'@r');
   if ( !status ) {
      p_text = _lbget_text();
   }
   setChangingDialog(origChangeDialog);
}

static int getCurLineNumber(_str filename)
{
   orig_wid := p_window_id;
   p_window_id = HIDDEN_WINDOW_ID;
   _safe_hidden_window();

   lineNumber := 0;
   status := load_files('+b 'filename);
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
         if (  matchCaptionPrefix(p_text,COMPARE_WHOLE_FILES) ) {
            setLineRangeVisible(pathNum,false);
            setSymbolCaption(pathNum,"");
            setSymbolVisible(pathNum,false);
         }else if ( matchCaptionPrefix(p_text,COMPARE_ONE_SYMBOL) ) {
            showLineCaption := false;
            int startLineNumber1 = 0,endLineNumber1 = 0;
            status := showSymbolDialog(startLineNumber1,endLineNumber1,auto symbolName,auto tagInfo,origChangeDialog);
            if ( !status ) {
               setLineRangeCaption(pathNum,startLineNumber1,endLineNumber1);
               setLineRangeVisible(pathNum,true);

               setSymbolCaption(pathNum,symbolName);
               setSymbolVisible(pathNum,true);

               if ( pathNum=='1' ) {
                  // If we were dealing with the path 1 combo box, try to find
                  // the same symbol in the other file
                  gTagInfo=tagInfo;
                  mou_hour_glass(1);
                  _str filename2=GetPath2Filename();

                  int startLineNumber2 = 0,endLineNumber2 = 0;
                  status=GetLineRangeWithFunctionInfo(filename2,symbolName,tagInfo,startLineNumber2,endLineNumber2,true,ctlpath2_on_disk.p_value!=0);
                  if ( !status ) {
                     setLineRangeCaption('2',startLineNumber2,endLineNumber2);
                     setLineRangeVisible('2',true);

                     setSymbolCaption('2',symbolName);
                     setSymbolVisible('2',true);

                     ctlsymbol2combo.p_text = COMPARE_ONE_SYMBOL;
                  }
                  mou_hour_glass(0);
                  ctlok._set_focus();
               }
            }
         }else if ( matchCaptionPrefix(p_text,COMPARE_LINE_RANGE) ) {
            int startLine=0,endLine=0;
            pathControlName := "ctlpath":+pathNum;
            pathControlWID := _find_control(pathControlName);
            _str filename = "";
            if ( pathControlWID ) {
               filename = pathControlWID.p_text;
            }
            startLine = getCurLineNumber(filename);
            if ( !origChangeDialog ) {
               show('-modal _diffsetup_line_range_form',&startLine,&endLine,filename);
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
            mou_hour_glass(1);
            curFilenameInDialog := p_prev.p_prev.p_prev.p_text;
            if ( pathNum=='2' ) {
               curFilenameInDialog = GetPath2Filename();
            }

            int startLineNumber = 0,endLineNumber = 0;

            parse p_text with '[ ' auto symbolName ',' auto tagInfo ']' .;

            status := GetLineRangeWithFunctionInfo(curFilenameInDialog,symbolName,tagInfo,startLineNumber,endLineNumber,true,!ctlpath1_on_disk.p_value);
            if ( !status ) {
               setLineRangeCaption(pathNum,startLineNumber,endLineNumber);
               setLineRangeVisible(pathNum,true);

               setSymbolCaption(pathNum,symbolName);
               setSymbolVisible(pathNum,true);
            }
            mou_hour_glass(0);
            if ( pathNum=='1' ) {
               // If we were dealing with the path 1 combo box, try to find
               // the same symbol in the other file
               gTagInfo=tagInfo;
               mou_hour_glass(1);
               _str filename2=GetPath2Filename();

               int startLineNumber2 = 0,endLineNumber2 = 0;
               status=GetLineRangeWithFunctionInfo(filename2,symbolName,tagInfo,startLineNumber2,endLineNumber2,true,!ctlpath1_on_disk.p_value);
               if ( !status ) {
                  setLineRangeCaption('2',startLineNumber2,endLineNumber2);
                  setLineRangeVisible('2',true);

                  setSymbolCaption('2',symbolName);
                  setSymbolVisible('2',true);
               }
               mou_hour_glass(0);
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
   }
}

static _str getCurTagFromCurBuffer()
{
   // Update the context message, if current context is local variable
   _mdi.p_child._UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int local_id = _mdi.p_child.tag_current_local();
   _str type_name = "";
   _str symbolName = "";
   if (local_id > 0 && (def_context_toolbar_flags&CONTEXT_TOOLBAR_DISPLAY_LOCALS) ) {
      //say("_UpdateContextWindow(): local_id="local_id);
      tag_get_detail2(VS_TAGDETAIL_local_type,local_id,type_name);
      tag_get_detail2(VS_TAGDETAIL_local_flags,local_id,auto flags);
      symbolName = tag_tree_make_caption_fast(VS_TAGMATCH_local,local_id,true,true,false);
      //tag_tree_filter_member(0, type_name, 0, flags, i_access, i_type);
      //tag_tree_select_bitmap(i_access, i_type, leaf_flag, pic_index);
      tag_tree_get_bitmap(0,0,type_name,'',flags,auto leaf_flag,auto pic_index);
      //ContextMessage(caption, pic_index);
      _mdi.p_child.p_ModifyFlags |= MODIFYFLAG_CONTEXTWIN_UPDATED;
   }else{
      int context_id = _mdi.p_child.tag_current_context();
      if (context_id > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);
         tag_get_detail2(VS_TAGDETAIL_context_flags,context_id,auto flags);
         symbolName = tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,true,true,false);
         //tag_tree_filter_member(0, type_name, 0, flags, i_access, i_type);
         //tag_tree_select_bitmap(i_access, i_type, leaf_flag, pic_index);
         tag_tree_get_bitmap(0,0,type_name,'',flags,auto leaf_flag,auto pic_index);
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
   _str pathNum="";
   if ( p_prev.p_prev.p_prev.p_name=="ctlpath1" ) {
      pathNum = "1";
   }else if ( p_prev.p_prev.p_prev.p_name=="ctlpath2" ) {
      pathNum = "2";
   }
   return pathNum;
}

static void fillInSymbolCombo()
{
   origChangeDialog := setChangingDialog(true);
   pathNum := getPathNumForSymbolCombo();
   curFilenameInDialog := p_prev.p_prev.p_prev.p_text;

   curFilename := p_prev.p_prev.p_prev.p_text;
   curComboWidth := p_prev.p_prev.p_prev.p_width;

   int wid=p_window_id;
   _lbclear();
   symbolName := "";
   curBufName := "";
   if ( !_no_child_windows() ) {
      curBufName = _mdi.p_child.p_buf_name;
   }

   pathReplacement := pathNum;
   path2Exists := false;
   curPathExists := false;

   if ( pathNum=='1' ) {
      if ( !isdirectory(curFilename) && file_exists(curFilename) ) {
         pathReplacement = curFilename;
         curPathExists = true;
      }
   }else if ( pathNum=='2' ) {
      curFilename = GetPath2Filename();
      if ( !isdirectory(curFilename) && file_exists(curFilename) ) {
         pathReplacement = curFilename;
         curPathExists = true;
      }
   }
   remainingWidth := p_width - _text_width(COMPARE_ONE_SYMBOL);
   pathReplacement = _ShrinkFilename(pathReplacement,remainingWidth);

   _lbadd_item(COMPARE_WHOLE_FILES);    
   _lbadd_item(COMPARE_LINE_RANGE);
   if ( pathNum=='1' ) {
      _lbadd_item(COMPARE_ALL_SYMBOLS);
   }
   // 11:19:29 AM 4/9/2009 pulling this for now
   //if ( file_eq(curFilename,curBufName) ) {
   //    //comboBoxItem := stranslate(COMPARE_CUR_SYMBOL,pathReplacement,"###");
   //    comboBoxItem := stranslate(COMPARE_CUR_SYMBOL,symbolName,"$$$");
   //    _lbadd_item(comboBoxItem);
   //}
   if ( curPathExists ) {
      _lbadd_item(COMPARE_ONE_SYMBOL);
   }
   _lbtop();
   p_window_id=wid;
   setChangingDialog(origChangeDialog);
}

static int LoadMapInfo(_str (&Path1Names)[],_str (&MapInfo):[])
{
   _str path=_ConfigPath();
   _maybe_append_filesep(path);
   _str HistoryFilename=path:+DIFFMAP_FILENAME;
   int temp_view_id=0;
   int status=_ini_get_section(HistoryFilename,"mappings",temp_view_id);
   if (status) {
      return(status);
   }
   _str line='';
   _str CurPath='';
   _str MappedPaths='';
   int orig_view_id=p_window_id;
   p_window_id=temp_view_id;
   top();up();
   while (!down()) {
      get_line(line);
      parse line with CurPath (_chr(1)) MappedPaths;
      CurPath=_file_case(CurPath);
      _maybe_append_filesep(CurPath);
      if (MapInfo._indexin(CurPath)) {
         MapInfo:[CurPath]=MapInfo:[CurPath]:+_chr(1):+MappedPaths;
      }else{
         MapInfo:[CurPath]=MappedPaths;
         ArrayAppend(Path1Names,_file_case(CurPath));
      }
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

#define COMPARE_OPTION_CAPTION "File Compare Options"
#define DIALOG_OPTION_CAPTION  "Dialog Setup"

static void oncreateOptions()
{
   origChangeDialog := setChangingDialog(true);
   //ctlminihtml2.p_backcolor=0x80000022;
   int wid=p_window_id;
   _control ctltree1;
   p_window_id=ctltree1;
   int options_index=_TreeAddItem(TREE_ROOT_INDEX,"Options",TREE_ADD_AS_CHILD);
   int first_active_index=_TreeAddItem(options_index,COMPARE_OPTION_CAPTION,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeAddItem(options_index,DIALOG_OPTION_CAPTION,TREE_ADD_AS_CHILD,0,0,-1);
   _TreeSetCurIndex(first_active_index);
   p_window_id=wid;

   int client_width=_dx2lx(SM_TWIP,ctlsstab1.p_client_width);

   ctlcompare_options_pic.p_y=ctledit_options_pic.p_y=ctltree1.p_y;
   ctlcompare_options_pic.p_x=ctledit_options_pic.p_x=(ctltree1.p_x*2)+ctltree1.p_width;

   ctlcompare_options_pic.p_width=client_width-ctlcompare_options_pic.p_x;
   ctledit_options_pic.p_width=client_width-ctledit_options_pic.p_x;

   ctlcompare_options_pic.p_border_style=BDS_NONE;
   ctledit_options_pic.p_border_style=BDS_NONE;

   SetDiffCompareOptionsOnDialog(def_diff_options);
   SetDiffEditOptionsOnDialog();

   // Change for editor control.
   // OEM's don't ship vs.exe so can't support spawning vs.exe
   if (_default_option(VSOPTION_APIFLAGS)&0x80000000) {
      ctlseparate_process.p_visible=1;
   } else {
      ctlseparate_process.p_visible=0;
   }
   setLinkButtonPicture();
   ctlexpert_mode.p_value = def_diff_dialog_expert_mode;
   setChangingDialog(origChangeDialog);
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

   if (!_default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS)) {
      ctlinterleaved.p_visible=0;
   }
   setChangingDialog(origChangeDialog);
}

static void SetDiffEditOptionsOnDialog()
{
   origChangeDialog := setChangingDialog(true);
   ctlshow_gauge.p_value=def_diff_edit_options&DIFFEDIT_SHOW_GAUGE;
   ctljump.p_value=def_diff_edit_options&DIFFEDIT_AUTO_JUMP;

   // Don't set this here, will be handled by setLinkButtonPicture
   //ctlauto_mapping.p_value=(int)!(def_diff_edit_options&DIFFEDIT_NO_AUTO_MAPPING);

   ctlautoclose.p_value=def_diff_edit_options&DIFFEDIT_AUTO_CLOSE;
   ctlnoexitprompt.p_value=def_diff_edit_options&DIFFEDIT_NO_PROMPT_ON_MFCLOSE;
   ctlbuttons_at_top.p_value=def_diff_edit_options&DIFFEDIT_BUTTONS_AT_TOP;
   ctlseparate_process.p_value=def_diff_edit_options&DIFFEDIT_SPAWN_MFDIFF;

   ctlnum_saved_sessions.p_text = def_diff_num_sessions;

   if (def_diff_edit_options&DIFFEDIT_START_AT_TOP) {
      ctltop.p_value=1;
   }else{
      ctlfirst.p_value=1;
   }
   if (def_diff_edit_options&DIFFEDIT_CURFILE_INIT) {
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
   _str caption=_TreeGetCaption(index);
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
   DiffSessionColletction.initSessionData(diffSetupData);
}

void _DiffInitGSetupData()
{
   _DiffInitSetupData(gDiffSetupData);
}

int ctlok.lbutton_up()
{
   status := 0;
   do {
      status = okOptions();
      if (status) break;
      haveUntitledBuffer := _diff_is_untitled_filename(ctlpath1.p_text) ||
         _diff_is_untitled_filename(ctlpath2.p_text);
      if (OptionsOnly()) {
         if ( !haveUntitledBuffer ) {
            ctlsstab1._save_form_response();
         }
         p_active_form._delete_window(0);
         gDiffSetupData.SetOptionsOnly=true;
         return(0);
      }
      status=okFiles();
      if (status) break;
      if ( !_diff_is_untitled_filename(ctlpath1.p_text) ) {
         ctlsstab1._save_form_response();
      }
   
      int x=0,y=0,width=0,height=0;
      _DiffGetDimensionsAndState(x,y,width,height);
   
      if ( _GetDialogInfo(RESTORE_FROM_INI) ) {
         _DiffWriteConfigInfoToIniFile("DiffSetupGeometry",x,y,width,height);
      }

      if ( ctldiff_code.p_enabled && 
           ctldiff_code.p_picture==_pic_diff_code_bitmap ) {
         gDiffSetupData.balanceBuffersFirst = true;
         gDiffSetupData.ReadOnly2 = DIFF_READONLY_SOURCEDIFF;
      }

      if ( !haveUntitledBuffer ) {
         DiffSessionColletction *pdiffSessionData = _GetDialogInfoHtPtr("diffSessions");
         pdiffSessionData->addSession(gDiffSetupData);
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

#if 0 //4:04pm 3/1/2010
void ctlsave_session.lbutton_up()
{
   do {
      DiffSessionColletction *pdiffSessionData =_GetDialogInfoHtPtr("diffSessions");
      lastSessionID := _GetDialogInfoHt("lastSessionID");
      if ( lastSessionID==null || lastSessionID<0 ) {
         break;
      }
      DIFF_SETUP_DATA lastSession = pdiffSessionData->getSession(lastSessionID);

      DIFF_SETUP_DATA origSetupData = gDiffSetupData;
      okFiles(true);
      newDiffSession := gDiffSetupData;
      se.datetime.DateTime curDate;
      newDiffSession.sessionDate = curDate.toString();
      newDiffSession.sessionName = lastSession.sessionName;

      GetCompareOptionsFromDialog(auto compareOptions=0);
      newDiffSession.compareOptions = compareOptions;

      pdiffSessionData->replaceSession(newDiffSession,lastSessionID);
      pdiffSessionData->saveSessions();

      bitmapIndex := getBitmapIndexForSession(newDiffSession);

      //int wid=p_window_id;
      //p_window_id=ctlsession_tree;
      //namedSessionIndex := _TreeSearch(TREE_ROOT_INDEX,SESSION_CAPTION_NAMED);
      //existingSesionIndex := _TreeSearch(namedSessionIndex,sessionName);
      //if ( existingSesionIndex>-1 ) {
      //   _TreeDelete(existingSesionIndex);
      //}
      //
      //if ( namedSessionIndex>-1 ) {
      //   newIndex := _TreeAddItem(namedSessionIndex,sessionName,TREE_ADD_AS_CHILD,bitmapIndex,bitmapIndex,-1,0,newDiffSession.sessionDate:+USERINFO_DELIMITER:+newDiffSession.sessionID);
      //   _TreeSortCaption(namedSessionIndex);
      //}
      //p_window_id=wid;
      
      gDiffSetupData = origSetupData;

      ctlsession_tree.p_enabled = true;
      ctlsession_tree.p_prev.p_enabled  = true;
      ctlsave_session.p_enabled = false;
      ctlsave_session_as.p_enabled = true;

   } while ( false );
}
#endif

void ctlsave_session.lbutton_up()
{
   do {

      DiffSessionColletction *pdiffSessionData =_GetDialogInfoHtPtr("diffSessions");
      lastSessionID := _GetDialogInfoHt("lastSessionID");
      sessionName := "";
      if ( lastSessionID!=null && lastSessionID>-1 ) {
         DIFF_SETUP_DATA diffsession = pdiffSessionData->getSession(lastSessionID);
         defaultSession := pdiffSessionData->getDefaultSessionName();
         if ( diffsession.sessionName!=defaultSession ) {
            sessionName = diffsession.sessionName;
         }
      }

      int status=show('-modal _textbox_form',
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

      GetCompareOptionsFromDialog(auto compareOptions=0);
      newDiffSession.compareOptions = compareOptions;

      pdiffSessionData->addSession(newDiffSession,sessionName);
      pdiffSessionData->saveSessions();

      bitmapIndex := getBitmapIndexForSession(newDiffSession);

      int wid=p_window_id;
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
      DiffSessionColletction *pdiffSessionData = _GetDialogInfoHtPtr("diffSessions");
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
static int DelSessionFromTree(int treeNodeIndex,DiffSessionColletction &diffSessionData)
{
   userInfo := _TreeGetUserInfo(treeNodeIndex);
   cap := _TreeGetCaption(treeNodeIndex);

   parse userInfo with auto dateString (USERINFO_DELIMITER) auto sessionID;

   status := diffSessionData.deleteSession((int)sessionID);
   _TreeDelete(treeNodeIndex);
   return 0;
}

void ctlok.on_destroy()
{
   killEnableControlTimer(p_active_form);
   DiffSessionColletction *pdiffSessionData = _GetDialogInfoHtPtr("diffSessions");

   // Don't save the current session, this is only there for protection as we type
   int currentSessionID = -1;
   if ( pdiffSessionData->sessionExists(SESSION_CAPTION_CURRENT,currentSessionID) ) {
      pdiffSessionData->deleteSession(currentSessionID);
   }

   pdiffSessionData->saveSessions();
}

#define DIFF_STATEFILE_EXT 'dif'

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
   boolean spawn=ctlseparate_process.p_value&&ctlseparate_process.p_visible;
   if ( !_diff_is_untitled_filename(ctlpath1.p_text) ) {
      _save_form_response();
   }
   p_active_form._delete_window();
   refresh();
   if (spawn) {
      _str cmdline=maybe_quote_filename(editor_name('P'):+'vs');//editor name
      cmdline=cmdline' +new -q -st 0 -mdihide -p diff -loadstate 'filename;
      typeless status=shell(cmdline,'QA');
   }else{
      _DiffLoadDiffStateFile(filename);
   }
}

static int okOptions()
{
   compareOptions := 0;
   GetCompareOptionsFromDialog(compareOptions);

   editOptions := def_diff_edit_options;
   expertMode  := def_diff_dialog_expert_mode;
   numSessions := def_diff_num_sessions;

   status := 0;
   do {
      if (def_diff_options!=compareOptions) {
         def_diff_options=compareOptions;
         _config_modify_flags(CFGMODIFY_DEFDATA);
      }

      status = GetDiffEditOptionsFromDialog(editOptions,expertMode,numSessions);
      if ( status ) break;
   
      if ( def_diff_edit_options!=editOptions ) {
         def_diff_edit_options=editOptions;
         _config_modify_flags(CFGMODIFY_DEFDATA);
      }
   
      if ( def_diff_dialog_expert_mode!=expertMode ) {
         def_diff_dialog_expert_mode = expertMode;
         _config_modify_flags(CFGMODIFY_DEFDATA);
      }
   
      if ( def_diff_num_sessions!=numSessions ) {
         def_diff_num_sessions = numSessions;
         _config_modify_flags(CFGMODIFY_DEFDATA);
      }
   } while (false);
   return status;
}


static void GetCompareOptionsFromDialog(int &options)
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
      if (ctlseparate_process.p_value) {
         options|=DIFFEDIT_SPAWN_MFDIFF;
      }
   
      if (ctltop.p_value) {
         options|=DIFFEDIT_START_AT_TOP;
      }else if (ctlfirst.p_value) {
         options|=DIFFEDIT_START_AT_FIRST_DIFF;
      }
      if (ctlcurfile.p_value) {
         options|=DIFFEDIT_CURFILE_INIT;
      }
      if ( ctlexpert_mode.p_value ) {
         expert_mode = 1;
      }
   } while (false);
   return status;
}

static int okFiles(boolean quiet=false)
{
   _DiffInitGSetupData();
   gDiffSetupData.Interleaved=ctlinterleaved.p_value!=0;
   int status = 0;
   if ( !quiet ) {
      status = CheckForValidFilenames(1,false,ctlpath1_firstline.p_visible && ctlpath1_firstline.p_text!="");
      if (status) {
         return(status);
      }
   }
   if ( dialogInFolderMode() ) {
      if ( !quiet ) {
         status=CheckDirectories();
         if (status) {
            return(status);
         }
      }
      GetDataForMultiFile();

   }else if (ctltype_text.p_value || symbolCompareOptionIsSet() ) {
      if ( !quiet ) {
         status=CheckForValidFilenames(false,false,true);
         if (status) return(status);
      }

      status=CheckLineRanges();
      if (status) return(status);

      status=CheckFileWidth();
      if (status) return(status);

      GetDataForTwoFiles();
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

static int CheckForValidFilenames(boolean NonBlankOnly=false,boolean UseFastIsDir=true,boolean compareRegions=false)
{
   int status=ctlpath1.CheckForValidFilenames2(NonBlankOnly,false,UseFastIsDir);
   if (status) return(status);

   status=ctlpath2.CheckForValidFilenames2(NonBlankOnly,true,UseFastIsDir);
   if (status) return(status);

   if ( !compareRegions ) {
      status=ValidateBuffers();
      if (status) {
         ctlpath2._text_box_error(nls("You must specify two separate files"));
         return(1);
      }
   }

   return(0);
}

static int ValidateBuffers()
{
   _str filename1=_diff_absolute(ctlpath1.p_text);
   _str filename2=_diff_absolute(GetPath2Filename());

   boolean isbuf1=!ctlpath1_on_disk.p_value;
   boolean isbuf2=!ctlpath2_on_disk.p_value;

   if (isbuf1) {
      _str buf1=buf_match(filename1,1,'E');
      isbuf1=buf1!='';
   }

   if (isbuf2) {
      _str buf2=buf_match(filename2,1,'E');
      isbuf2=buf2!='';
   }

   boolean file_or_buffer_matches=(isbuf1==isbuf2);

   if (file_eq(filename1,filename2) && file_or_buffer_matches) {
      return(1);
   }
   return(0);
}

static int CheckForValidFilenames2(boolean NonBlankOnly,boolean AllowDirectories=true,
                                   boolean UseFastIsDir=true)
{
   if (p_text=='') {
      _text_box_error("This item must be a valid path or filename");
      ctlsstab1.p_ActiveTab=0;
      return(FILE_NOT_FOUND_RC);
   }
   if ( EndsWithWildcard(p_text) && !dialogInFolderMode() ) {
      _text_box_error("To perform this operation, select 'Multi-File' above");
      ctlsstab1.p_ActiveTab=0;
      return(FILE_NOT_FOUND_RC);
   }
   if (NonBlankOnly) {
      return(0);
   }
   _str filename=p_text;
   if (p_window_id==ctlpath2) {
      filename=GetPath2Filename(UseFastIsDir);
   }
   filename=strip(filename,'B','"');
   if (!AllowDirectories) {
      if (isdirectory(filename)) {
         _text_box_error("For this operation, this must be a filename");
         return(FILE_NOT_FOUND_RC);
      }
   }
   if (!file_exists(filename)) {
      isUntitledBuffer := _diff_is_untitled_filename(filename);
      if (buf_match(filename,1,'E')=='' && !_diff_is_http_filename(filename) &&
          !isUntitledBuffer) {
         _text_box_error("This item must be a valid path or filename");
         ctlsstab1.p_ActiveTab=0;
         return(FILE_NOT_FOUND_RC);
      }
   }
   return(0);
}

static void GetDataForTwoFiles()
{
   if ( _diff_is_http_filename(ctlpath1.p_text) ) {
      gDiffSetupData.File1Name=ctlpath1.p_text;
   } else if ( _diff_is_untitled_filename(ctlpath1.p_text) ) {
      parse ctlpath1.p_text with (NO_NAME) auto bufId1Str '>';
      gDiffSetupData.BufferIndex1 = (int)bufId1Str;
   }else{
      gDiffSetupData.File1Name=_diff_absolute(ctlpath1.p_text);
   }
   boolean NamesMatch=FilenamesInDialogMatch();
   gDiffSetupData.File1IsBuffer=false;
   if (ctlpath1_on_disk.p_enabled && ctlpath1_on_disk.p_value) {
      gDiffSetupData.File1IsBuffer=false;
   }else if (buf_match(gDiffSetupData.File1Name,1,'E')!='') {
      // if ctlpath1_on_disk.p_enabled==1, we should have the buffer open, but did
      // not specify the file on disk, so we want the buffer
      gDiffSetupData.File1IsBuffer=true;
   }

   if (_diff_is_http_filename(ctlpath2.p_text)) {
      gDiffSetupData.File2Name=ctlpath2.p_text;
   } else if ( _diff_is_untitled_filename(ctlpath2.p_text) ) {
      parse ctlpath2.p_text with (NO_NAME) auto bufId2Str '>';
      gDiffSetupData.BufferIndex2 = (int)bufId2Str;
   }else{
      gDiffSetupData.File2Name=GetPath2Filename(false);
   }

   gDiffSetupData.File2IsBuffer=false;
   if (ctlpath2_on_disk.p_enabled && ctlpath2_on_disk.p_value) {
      gDiffSetupData.File2IsBuffer=false;
   }else if (buf_match(gDiffSetupData.File2Name,2,'E')!='') {
      // if ctlpath2_on_disk.p_enabled==2, we should have the buffer open, but did
      // not specify the file on disk, so we want the buffer
      if (!NamesMatch || !gDiffSetupData.File1IsBuffer) {
         gDiffSetupData.File2IsBuffer=true;
      }
   }

   gDiffSetupData.DiffTags=symbolCompareOptionIsSet();
   if (!gDiffSetupData.DiffTags/* && ctlmore.p_caption=='&More <<'*/) {
      if (ctlpath1_firstline.p_visible && ctlpath1_firstline.p_text!='') {
         gDiffSetupData.File1FirstLine=(int)ctlpath1_firstline.p_text;
      }
      if (ctlpath1_lastline.p_visible && ctlpath1_lastline.p_text!='') {
         gDiffSetupData.File1LastLine=(int)ctlpath1_lastline.p_text;
      }
      if (ctlpath2_firstline.p_visible && ctlpath2_firstline.p_text!='') {
         gDiffSetupData.File2FirstLine=(int)ctlpath2_firstline.p_text;
      }
      if (ctlpath2_lastline.p_visible && ctlpath2_lastline.p_text!='') {
         gDiffSetupData.File2LastLine=(int)ctlpath2_lastline.p_text;
      }
   }
   if (ctlfile_width.p_text!='') {
      gDiffSetupData.RecordFileWidth=(int)ctlfile_width.p_text;
   }
   if ( ctlpath1symbolname.p_visible ) {
      parse ctlpath1symbolname.p_caption with "Symbol: " auto symbol1;
      gDiffSetupData.Symbol1Name = symbol1;
   }
   if ( ctlpath2symbolname.p_visible ) {
      parse ctlpath2symbolname.p_caption with "Symbol: " auto symbol2;
      gDiffSetupData.Symbol2Name = symbol2;
   }
}

static int CheckDirectories()
{
   _str path1=ctlpath1.p_text;
   if (EndsWithWildcard(path1)) {
      path1=_strip_filename(path1,'N');
   }
   if (!isdirectory(path1)) {
      ctlpath1._text_box_error(nls("'%s' is not a valid path",path1));
      ctlsstab1.p_ActiveTab=0;
      return(1);
   }
   _str path2=ctlpath2.p_text;
   if (!isdirectory(path2)) {
      ctlpath2._text_box_error(nls("'%s' is not a valid path",path2));
      ctlsstab1.p_ActiveTab=0;
      return(1);
   }
   path1=_diff_absolute(path1);
   path2=_diff_absolute(path2);
   if (file_eq(path1,path2)) {
      ctlpath2._text_box_error(nls("You must specify two separate paths"));
      return(1);
   }
   return(0);
}

static void GetDataForMultiFile()
{
   if (EndsWithWildcard(ctlpath1.p_text)) {
      gDiffSetupData.File1Name=absolute(_strip_filename(ctlpath1.p_text,'N'));
      gDiffSetupData.FileSpec=_strip_filename(ctlpath1.p_text,'P');
   }else{
      gDiffSetupData.File1Name=absolute(ctlpath1.p_text);
   }
   gDiffSetupData.File2Name=absolute(ctlpath2.p_text);
   if (gDiffSetupData.FileSpec=='') {
      gDiffSetupData.FileSpec=ctlfilespecs.p_text;
      if (gDiffSetupData.FileSpec=='') {
         gDiffSetupData.FileSpec=ALLFILES_RE;
      }
   }else{
      gDiffSetupData.FileSpec=gDiffSetupData.FileSpec' 'ctlfilespecs.p_text;
   }
   strip(gDiffSetupData.File1Name,'B','"');
   strip(gDiffSetupData.File2Name,'B','"');
   _maybe_append_filesep(gDiffSetupData.File1Name);
   _maybe_append_filesep(gDiffSetupData.File2Name);
   gDiffSetupData.ExcludeFileSpec=ctlexclude_filespecs.p_text;
   gDiffSetupData.Recursive=ctlrecursive.p_value!=0;
}

void ctlbrowsedir.lbutton_up()
{
   origChangeDialog := setChangingDialog(true);
   do {
      typeless dummy='';
      typeless result='';
      int wid=p_window_id;
      if ( p_active_form.p_name=="_diffsetup_form" && dialogInFolderMode() ) {
         _str init_dir= wid.p_prev.p_text;
         if (init_dir == "") {
            if (wid.p_prev == wid._find_control("ctlpath2")){
               int path1 = wid._find_control("ctlpath1");
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
      }else{
         _str initialDirectory = absolute(p_prev.p_text);
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
      }
      if ( result=='' ) break;
      result = strip(result,'B','"');
      p_window_id=wid.p_prev;
      p_text=result;
      end_line();
      _set_focus();
      setChangingDialog(origChangeDialog);
   }while (false);
}

void _browserefs.lbutton_up()
{
   origChangeDialog := setChangingDialog(true);
   do {
      int wid=p_window_id;
   
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
      _str cur='';
      _str all_items='';
      p_window_id=wid.p_prev;
      for (;;) {
         cur=parse_file(result);
         cur=strip(cur,'B','"');
         if (cur=='') break;
         cur=maybe_quote_filename(_strip_filename(cur,'P'));
         if (cur!='') {
            all_items=all_items' 'cur;
         }
      }
      all_items=strip(all_items);
      if (p_text=='') {
         p_text=all_items;
      }else{
         p_text=p_text' 'all_items;
      }
      end_line();
      p_window_id=wid;
      _set_focus();
   } while (false);
   setChangingDialog(origChangeDialog);
}

void ctlpath1_buffer.lbutton_up()
{
   int width=0;
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   _build_buf_list(width,p_buf_id);
   top();up();
   p_window_id=orig_view_id;
   typeless result=show('-modal _sellist_form',
               'Choose a Buffer',
               SL_VIEWID,
               temp_view_id);
   if (result!='') {
      p_prev.p_prev.p_text=_buflist_name(' 'result);

      // Now we have to shut off the "use file on disk" checkbox.
      // If we are in the path one frame, there is an extra control 
      //  (More >> button).
      switch (p_prev.p_prev.p_name) {
      case 'ctlpath1':
      case 'ctlpath2':
         if ( p_next.p_next.p_enabled ) {
            p_next.p_next.p_value=0;
         }
         break;
      }
      p_prev.p_prev._set_focus();
   }
}
#define ControlExtent(a) (a.p_y+a.p_height)

/**
 * @return boolean return the value of the expert mode check box
 *         on the dialog rather than def_diff_expert_mode
 */
static boolean dialogInExpertMode()
{
   return ctlexpert_mode.p_value!=0;
}

/**
 * @return boolean return true if the "Compare Folders" radio 
 *         button is selected
 */
static boolean dialogInFolderMode()
{
   return ctltype_mf.p_value && ctltype_mf.p_enabled;
}

/**
 * If the dialog is in "expert mode", this function will set
 * ctltype_mf or ctltype_text according to what is in the path
 * text boxes, rather than the other way around.
 * 
 * Be sure to call this before other enable/disable functions
 * since they will check the value of these radio buttons
 */
static void expertModeEnableControls()
{
   if (!symbolCompareOptionIsSet()) {
      if (strip(ctlpath1.p_text)!='' && _DiffIsDirectory(ctlpath1.p_text,true) ||
          EndsWithWildcard(ctlpath1.p_text)) {
         ctltype_mf.p_value=1;
      }else{
         ctltype_text.p_value=1;
      }
   }
   path1filename := ctlpath1.p_text;
   path2filename := GetPath2Filename();
   _str lang1 = _DiffFilename2LangId(path1filename);
   _str lang2 = _DiffFilename2LangId(path2filename);
   if (symbolCompareOptionIsSet() && p_active_form.p_visible) {
      ctltype_text.p_value=1;
   }
}

/**
 * Enable and disable controls based on whether the dialog is in
 * two file or mult-file mode
 */
static void enableCommonControls()
{
   ctlfilespecs_label.p_enabled = ctlfilespecs.p_enabled = dialogInFolderMode();
   ctlrecursive.p_enabled = dialogInFolderMode();
   ctlexclude_filespecs_label.p_enabled = ctlexclude_filespecs.p_enabled = dialogInFolderMode();
   ctlsymbol1combo.p_enabled = ctlsymbol2combo.p_enabled = !dialogInFolderMode();

   if ( dialogInFolderMode()  ) {
      ctlpath1_on_disk.p_enabled = ctlpath2_on_disk.p_enabled = false;
   } else {
      SetupBufferCBs();
   }

   if (ctltype_mf.p_value) {
      ctlpath1.p_completion = DIRNOQUOTES_ARG;
      ctlpath2.p_completion = DIRNOQUOTES_ARG;
   } else {
      ctlpath1.p_completion = FILENOQUOTES_ARG;
      ctlpath2.p_completion = FILENOQUOTES_ARG;
   }
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
   if ( !_iswindow_valid(formWID) || p_active_form.p_name=="_diffsetup_form" ) return;
   timerHandle := _GetDialogInfoHt("timerHandle",formWID);
   if ( timerHandle !=null ) {
      _kill_timer(timerHandle);
      _SetDialogInfoHt("timerHandle",null);
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

   int wid = p_window_id;
   p_window_id = formWID;

   if ( dialogInExpertMode() ) {
      origChangeDialog := setChangingDialog(true);

      // If the paths are the same, bail.  Since we just looking to see if the 
      // dialog changed, we can check for exact match rather than file_eq.
      firstPath  := _GetDialogInfoHt("firstPath");
      secondPath := _GetDialogInfoHt("secondPath");
      if ( ctlpath1.p_text!=firstPath || ctlpath2.p_text!=secondPath ) {
         expertModeEnableControls();
         _SetDialogInfoHt("firstPath",ctlpath1.p_text);
         _SetDialogInfoHt("secondPath",ctlpath2.p_text);
      }
      setChangingDialog(origChangeDialog);
   }
   enableCommonControls();

   p_window_id=wid;
}

/**
 * Set a timer to enable and disable controls on this dialog. 
 * Store the timer using _SetDialogInfoHt 
 */
static void setEnableControlTimer()
{
   killEnableControlTimer(p_active_form);
   timerHandle := _set_timer(100,enableControlCallback,p_active_form);
   _SetDialogInfoHt("timerHandle",timerHandle);
}

// Eventtable shared by both textboxes
void ctlpath1.on_change(int reason)
{
   if ( !getChangingDialog() ) {
      setSymbolCaption(1,"");
      setSymbolCaption(2,""); 
      setLineRangeCaption(1,0,0);
      setLineRangeVisible(1,false);
      setLineRangeCaption(2,0,0);
      setLineRangeVisible(2,false);
   }
   origChangeDialog := setChangingDialog(true);
   if (p_window_id==ctlpath1) {
      if ( !(def_diff_edit_options&DIFFEDIT_NO_AUTO_MAPPING) ) {
         if ( _GetDialogInfoHt("path2SetByUser")!=true ) {
            SetupMappedPaths(ctlpath1.p_text);
         }
         p_next.p_next.p_next.fillInSymbolComboAndTextBox();
         ctlsymbol2combo.fillInSymbolComboAndTextBox();
      }
   }else if (p_window_id==ctlpath2 && _GetDialogInfoHt("InSetupMappedPaths")!=1 && p_active_form.p_visible) {
      gPath2Modified=1;
   }
   setChangingDialog(origChangeDialog);
   setEnableControlTimer();
   handleChangeInSessionsTree();
#if SOURCE_DIFF_TOGGLE_ENABLE_DISABLE
   enableDisableSourceDiff();
#endif 
}


/**
 * @param filename 
 * 
 * @return boolean returns true if <B>filename</B> has color 
 *         coding
 */
static boolean fileHasColorCoding(_str filename)
{
   langID := _DiffFilename2LangId(filename);
   _GetLanguageSetupOptions(langID, auto setup);

   boolean hasColorCoding = false;
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

/**
 * Save current session in memory 
 * 
 * @return int sessionID for current session we saved
 */
static int saveCurrentSession()
{
   DiffSessionColletction *pdiffSessionData =_GetDialogInfoHtPtr("diffSessions");
   int curSessionID = -1;
   okFiles(true);
   if ( pdiffSessionData->sessionExists(SESSION_CAPTION_CURRENT,curSessionID) ) {
      gDiffSetupData.sessionName = SESSION_CAPTION_CURRENT;
      pdiffSessionData->replaceSession(gDiffSetupData,curSessionID);
   }else{
      DIFF_SETUP_DATA curSession = gDiffSetupData;
      curSessionID = pdiffSessionData->addSession(curSession,SESSION_CAPTION_CURRENT);
   }
   return curSessionID;
}

/**
 * Call saveCurrentSession to save the session in memory, and add a node for 
 * SESSION_CAPTION_RECENT (or select it). 
 * 
 */
static void saveCurrentSessionNode()
{
   int wid=p_window_id;
   p_window_id=ctlsession_tree;

   recentSessionsIndex := _TreeSearch(TREE_ROOT_INDEX,SESSION_CAPTION_RECENT);
   if ( recentSessionsIndex>-1 ) {
      curSessionID := saveCurrentSession();

      currentSessionIndex := _TreeSearch(recentSessionsIndex,SESSION_CAPTION_CURRENT);
      origChangingDialog := getChangingDialog();
      setChangingDialog(1);
      if ( currentSessionIndex < 0 ) {
         addFlags := TREE_ADD_AS_CHILD;
         relativeIndex := recentSessionsIndex;

         firstChildIndex := _TreeGetFirstChildIndex(recentSessionsIndex);
         if ( firstChildIndex > -1 ) {
            addFlags = TREE_ADD_BEFORE;
            relativeIndex = firstChildIndex;
         }
         currentSessionIndex = _TreeAddItem(relativeIndex,SESSION_CAPTION_CURRENT,addFlags,_pic_file,_pic_file,-1,0,"":+USERINFO_DELIMITER:+curSessionID);
      }
      if ( currentSessionIndex > -1 ) {
         _TreeSetCurIndex(currentSessionIndex);
      }
      setChangingDialog(origChangingDialog);
   }

   p_window_id=wid;
}

static void handleChangeInSessionsTree()
{
   if ( !getChangingDialog() ) {
      saveCurrentSessionNode();
      // Old code to handle disabling tree on typing, save this for now
      //int wid=p_window_id;
      //p_window_id=ctlsession_tree;
      //
      //p_enabled = false;
      //p_prev.p_enabled  = false;
      //
      //index := _TreeCurIndex();
      //
      //if ( isNamedSessionNode(index) ) {
      //   ctlsave_session.p_enabled = true;
      //   ctlsave_session_as.p_enabled = true;
      //}else{
      //   ctlsave_session.p_enabled = false;
      //   ctlsave_session_as.p_enabled = true;
      //}
      //
      //
      //DiffSessionColletction *pdiffSessionData = _GetDialogInfoHtPtr("diffSessions");
      //sessionID := _GetDialogInfoHt("lastSessionID");
      //if ( sessionID!=null && sessionID>-1 ) {
      //   DIFF_SETUP_DATA curSetupData = pdiffSessionData->getSession((int)sessionID);
      //}
      //
      //p_window_id=wid;
   }
}

void ctlpath2.on_change(int reason)
{
   handleChangeInSessionsTree();
   if ( !getChangingDialog() ) {
      SetupBufferCBsForMatchingFilenames();
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
      boolean SetText=p_active_form.p_visible;
      _str MapInfo:[]=null;
      MapInfo=gMapInfo;
   
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
      Path=_file_case(Path);
   
      int i,len_path=length(Path);
   
      for (i=0;i<Path1Names._length();++i) {
         _str cur_path=Path1Names[i];
         int len_cur_path=length(cur_path);
         if (len_cur_path<=len_path) {
            if (substr(Path,1,len_cur_path)==cur_path) {
               AddToArray(MapInfo:[cur_path],MappedPaths,MappedPathsTable,substr(Path,len_cur_path+1));
            }
         }
      }
   
      int wid=p_window_id;
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
      if (gPath2Modified!=1 && text!='' && SetText/* &&
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
      ArrayAppend(items,_lbget_text());
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

static void AddToArray(_str PathList,_str (&MappedPaths)[],_str (&MappedPathsTable):[],_str SuffixPath='')
{
   _str chr1=_chr(1);

   // This is a little error correction.  Not sure how these entries got in,
   // but I want to get them out
   while (pos(chr1:+chr1,PathList)) {
      PathList=stranslate(PathList,chr1,chr1:+chr1);
   }

   _str cur='';
   for (;;) {
      parse PathList with cur (chr1) PathList;
      if (cur=='') break;
      _maybe_append_filesep(cur);
      _str whole_path=cur:+SuffixPath;
      if (!MappedPathsTable._indexin(_file_case(whole_path))) {
         ArrayAppend(MappedPaths,whole_path);
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

static boolean symbolCompareOptionIsSet()
{
   return matchCaptionPrefix(ctlsymbol1combo.p_text,COMPARE_ALL_SYMBOLS);
}

static boolean EndsWithWildcard(_str Path)
{
   int p=lastpos(FILESEP,Path);
   if (!p) {
      return(false);
   }
   _str maybe_wildcard=substr(Path,p+1);
   return(iswildcard(maybe_wildcard));
}

static int showSymbolDialog(int &startLineNumber,int &endLineNumber,_str &symbolName,_str &tagInfo,boolean findMatchAndReturn=false)
{
   //if (p_parent.p_height < p_y) {
   //   ctlmore.call_event(ctlmore,LBUTTON_UP);
   //}
   _str path1file=strip(ctlpath1.p_text,'B','"');
   if (!file_exists(path1file) || path1file=='') {
      _str msg=nls("File '%s1' does not exist.",path1file);
      if (path1file=='') {
         msg=nls("You must first fill in a filename");
      }
      _message_box(msg);
      return 1;
   }
   _str filename='';
   _control ctlsymbol1combo,ctlsymbol2combo;
   boolean useDisk = false;
   if ( p_window_id==ctlsymbol1combo ) {
      filename = ctlpath1.p_text;
      useDisk  = ctlpath1_on_disk.p_value!=0;
   }else if ( p_window_id==ctlsymbol2combo ) {
      filename = GetPath2Filename();
      useDisk  = ctlpath2_on_disk.p_value!=0;
   }
   filename=strip(filename,'B','"');
   _str FunctionName='';
   parse ctlpath1symbolname.p_caption with 'Symbol:' symbolName;
   mou_hour_glass(1);
   int status=GetLineRangeWithFunctionInfo(filename,symbolName,tagInfo,startLineNumber,endLineNumber,findMatchAndReturn,useDisk);
   FunctionName = symbolName;
   mou_hour_glass(0);
   return status;
}

/**
 * @param path "1" or "2"
 * @param visible 
 */
static void setLineRangeVisible(_str pathNum,boolean visible)
{
   firstWID := _find_control("ctlpath":+pathNum:+"_firstline");
   if ( firstWID ) {
      firstWID.p_visible = visible;
      firstWID.p_next.p_visible = visible;
      firstWID.p_next.p_next.p_visible = visible;
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
      firstWID.p_caption = "Symbol: ":+symbolCaption;
   }
}

static void setSymbolVisible(_str pathNum,boolean visible)
{
   firstWID := _find_control("ctlpath":+pathNum:+"symbolname");
   if ( firstWID ) {
      firstWID.p_visible = visible;
   }
}

static int GetLineRangeWithFunctionInfo(_str filename,
                                        _str &FunctionName, _str &TagInfo,
                                        int &StartLineNumber,int &EndLineNumber,
                                        boolean find_match_and_return=false,
                                        boolean AlwaysLoadFromDisk=false)
{
   _str tag_name='';
   tag_tree_decompose_caption(FunctionName,tag_name);
   int status;
   int CommentLineNumber = 0;
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

static _str GetPath2Filename(boolean UseFastIsDir=true)
{
   _str filename='';
   if ( _diff_is_http_filename(ctlpath2.p_text) 
        ||  diff_is_ftp_filename(ctlpath2.p_text)
        || _diff_is_untitled_filename(ctlpath2.p_text)
       ) {
      return(ctlpath2.p_text);
   }
   _str Path='';
   _str abspath=_diff_absolute(ctlpath2.p_text);
   if (_DiffIsDirectory(abspath,UseFastIsDir)) {
      Path=ctlpath2.p_text;
      filename=absolute(ctlpath1.DiffSetupBuildFilename(Path));
   }else if (file_match2(ctlpath2.p_text,1,'-d -p')!='') {
      filename=absolute(ctlpath2.p_text);
   }else if (buf_match(ctlpath2.p_text,1,'E')!='') {
      filename=ctlpath2.p_text;
   }else if ( _diff_is_untitled_filename(ctlpath1.p_text) ) {
      filename=ctlpath2.p_text;
   }else{
      return('');
   }
   return(filename);
}

static void SetupBufferCBs()
{
   int status=SetupBufferCBsForMatchingFilenames();
   if (status) {
      return;
   }
   _str filename1=ctlpath1.p_text;
   _str filename2=GetPath2Filename();

   _str bufname1=buf_match(_diff_absolute(filename1),1,'E');
   if (bufname1=='') {
      ctlpath1_on_disk.p_value=0;
      ctlpath1_on_disk.p_enabled=0;
   }else{
      if (diff_is_ftp_filename(bufname1) ||
          _diff_is_http_filename(bufname1)) {
         ctlpath1_on_disk.p_value=0;
         ctlpath1_on_disk.p_enabled=0;
      }else{
         ctlpath1_on_disk.p_enabled=1;
      }
   }

   _str bufname2=buf_match(_diff_absolute(filename2),1,'E');
   if (bufname2=='') {
      ctlpath2_on_disk.p_value=0;
      ctlpath2_on_disk.p_enabled=0;
   }else{
      if (diff_is_ftp_filename(bufname2) ||
          _diff_is_http_filename(bufname2)) {
         ctlpath2_on_disk.p_value=0;
         ctlpath2_on_disk.p_enabled=0;
      }else{
         ctlpath2_on_disk.p_enabled=1;
      }
   }

   if (ctlpath1_on_disk.p_enabled &&
       ctlpath2_on_disk.p_enabled &&
       file_eq(bufname1,bufname2)) {
      ctlpath2_on_disk.p_value=1;
      ctlpath2_on_disk.p_enabled=0;
   }
}

void ctlpath1_on_disk.lbutton_up()
{
   if ( p_active_form.p_name=="_diffsetup_form" ) {
      SetupBufferCBsForMatchingFilenames();
      handleChangeInSessionsTree();
   }
}
#if 0 //3:57pm 3/1/2010
void ctlsstab1.on_change(int reason)
{
   if ( reason==CHANGE_TABACTIVATED) {
      setOkButtonCaption();
   }
}

void setOkButtonCaption()
{
   _str tabcaption=lowcase(ctlsstab1.p_ActiveCaption);
   if ( tabcaption=='options' ) {
      ctlok.p_caption="Save";
   }else{
      ctlok.p_caption="OK";
   }
}
#endif

static int SetupBufferCBsForMatchingFilenames()
{
   if (FilenamesInDialogMatch()) {
      ctlpath1_on_disk.p_value=0;
      ctlpath1_on_disk.p_enabled=0;

      ctlpath2_on_disk.p_value=1;
      ctlpath2_on_disk.p_enabled=0;
      return(1);
   }
   return(0);
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
         boolean collision=CheckForLineCollisions((typeless)ctlpath1_firstline.p_text,
                                                  (typeless)ctlpath1_firstline.p_next.p_next.p_text,
                                                  (typeless)ctlpath2_firstline.p_text,
                                                  (typeless)ctlpath2_firstline.p_next.p_next.p_text);
         if (collision && ctlpath1_on_disk.p_value == ctlpath2_on_disk.p_value) {
            _message_box(nls("Line ranges in the same file cannot overlap"));
            return(1);
         }
      }
   }

   return(0);
}

#define NumberInRange(a,b,c) (a!='' && a>=b && a<=c)

static boolean CheckForLineCollisions(int rangeOneStart,int rangeOneEnd,
                                      int rangeTwoStart,int rangeTwoEnd)
{
   return(NumberInRange(rangeOneStart,rangeTwoStart,rangeTwoEnd) ||
          NumberInRange(rangeOneEnd,rangeTwoStart,rangeTwoEnd)   ||
          NumberInRange(rangeTwoStart,rangeOneStart,rangeOneEnd) ||
          NumberInRange(rangeTwoEnd,rangeOneStart,rangeOneEnd) );
}

static boolean FilenamesInDialogMatch()
{
   _str filename1=absolute(ctlpath1.p_text);
   _str filename2=GetPath2Filename();
   return(file_eq(filename1,filename2));
}

static int CheckLineRangeOnDialog()
{
   _str error_message="Line ranges must be valid integers greater than 0";
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
   _str next_text=nextwid.p_text;
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

_str _DiffIsDirectory(_str Path,boolean FastCheck=false)
{
   Path=strip(Path);
   Path=strip(Path,'B','"');
   Path=strip(Path);
   if (file_eq(substr(Path,1,6),'ftp://')) {
      return(0);
   }
   if (FastCheck) {
      return(last_char(Path)==FILESEP);
   }
   isDirStr := isdirectory(Path);
   isdir := strip(isDirStr)!=0 && strip(isDirStr)!="";
   return(isdir);
}

_str _diff_absolute(_str filename)
{
   if (_diff_is_http_filename(filename) ||
       diff_is_ftp_filename(filename)) {
      return(filename);
   }
   return(absolute(filename));
}

boolean _diff_is_http_filename(_str filename)
{
   return(_isHTTPFile(filename)!=0);
}

boolean _diff_is_untitled_filename(_str filename)
{
   return substr(filename,1,length(NO_NAME))==NO_NAME;
}

static boolean diff_is_ftp_filename(_str filename)
{
   return(strieq(substr(translate(filename,'/','\'),1,6),'ftp://'));
}

static _str DiffSetupBuildFilename(_str Path)
{
   if (last_char(Path)!=FILESEP) {
      Path=Path:+FILESEP;
   }
   _str filename=_diff_absolute(Path):+_strip_filename(p_text,'P');
   return(filename);
}

static void LoadHistory(_str SectionName)
{
   _str path=_ConfigPath();
   if (last_char(path)!=FILESEP) path=path:+FILESEP;
   _str HistoryFilename=path:+DIFFMAP_FILENAME;
   int temp_view_id=0;
   int orig_view_id=p_window_id;
   int status=_ini_get_section(HistoryFilename,SectionName,temp_view_id);
   if (status) return;
   p_window_id=temp_view_id;
   top();up();
   while (!down()) {
      _str line='';
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

void ctlok.on_create(int *pStartLinenum,int *pEndLinenum,_str filename="")
{
   // Don't initialize pStartLinenum because it is either initialized to 0 or 
   // the current line number already  
   //*pStartLinenum = 0;
   *pEndLinenum   = 0;
   if ( filename == "" ) {
      ctledit1.p_visible     = false;
      ctlnotelabel.p_visible = false;
   }else{
      int wid=p_window_id;
      p_window_id=ctledit1;

      // Open filename passed in, 
      status := _open_temp_view(filename,auto temp_wid,auto orig_wid);
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

   ctlnotelabel.p_x = ctlstart_line.p_x + ctlstart_line.p_width+leftX;
   ctlstart_line.p_y = topY + yBuffer;

   ctlok.p_x = ctlstart_line.p_prev.p_x;
   ctlok.p_next.p_x = ctlok.p_x+ctlok.p_width+leftX;

   if ( ctledit1.p_visible ) {
      ctledit1.p_y = topY;
      editSpace := clientHeight - (2*topY);
      editSpace -= (2*ctlstart_line.p_height)+(2*topY);
      editSpace -= ctlok.p_height+topY;

      ctledit1.p_height = editSpace;

      topY = ctledit1.p_y+ctledit1.p_height+yBuffer;
      ctledit1.p_width = clientWidth - (2*leftX);
   }

   {
      ctlstart_line.p_y = topY;
      ctlstart_line.p_prev.p_y = topY;
      ctlnotelabel.p_y = topY;
   
      ctlend_line.p_y = ctlstart_line.p_y+ctlstart_line.p_height+yBuffer;
      ctlend_line.p_prev.p_y = ctlstart_line.p_y+ctlstart_line.p_height+yBuffer;
   
      ctlok.p_y = ctlend_line.p_y+ctlend_line.p_height+yBuffer;
      ctlok.p_next.p_y = ctlend_line.p_y+ctlend_line.p_height+yBuffer;
   
      if ( !ctledit1.p_visible ) {
         p_active_form.p_width = ctlend_line.p_x+ctlend_line.p_width+leftX+clientWidthDiff;
         p_active_form.p_height = ctlok.p_y+ctlok.p_height+yBuffer+clientHeightDiff;
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
      _str command_name=name_name(name_index);
   
      //This is to handle C-X combinations
      if (name_type(name_index)==EVENTTAB_TYPE) {
         int eventtab_index2=name_index;
         typeless event2=get_event('k');
         key_index=event2index(event2);
         name_index=eventtab_index(eventtab_index2,eventtab_index2,key_index);
         command_name=name_name(name_index);
      }
      int index=find_index(command_name,COMMAND_TYPE);
      if (index && index_callable(index)) {
         call_index(index);
         if ( select_active() ) {
             _select_type('','T',"LINE");
            _str old_mark;
            int mark_status=1;
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
