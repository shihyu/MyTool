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
/**
 * [?4/?27/?2017 4:08 PM] Dennis Brueni: 
OK, I do svn-history on macros/diffedit.e (from the trunk), select r61182 and diff with r60875, and it gives me revisions 60875 and 59311.
It claims that it’s giving the right versions, but you can see the $VERSION string that they aren’t.
I mean $Revision comment.

 */
#include "slick.sh"
#include "diff.sh"
#include "markers.sh"
#include "vsevents.sh"
#include "markers.sh"
#import "se/lang/api/LanguageSettings.e"
#import "alias.e"
#import "clipbd.e"
#import "codehelp.e"
#import "compile.e"
#import "complete.e"
#import "context.e"
#import "cua.e"
#import "diff.e"
#import "diffmf.e"
#import "difftags.e"
#import "dlgman.e"
#import "fileman.e"
#import "fileproject.e"
#import "files.e"
#import "guifind.e"
#import "guiopen.e"
#import "help.e"
#import "hex.e"
#import "html.e"
#import "keybindings.e"
#import "main.e"
#import "markfilt.e"
#import "menu.e"
#import "mouse.e"
#import "mprompt.e"
#import "pmatch.e"
#import "project.e"
#import "projutil.e"
#import "saveload.e"
#import "search.e"
#import "seek.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "util.e"
#import "vicmode.e"
#import "viimode.e"
#import "wfont.e"
#import "window.e"
#import "xml.e"
#endregion


static const MATCHING_LINE= 0x0;
static const INSERTED_LINE= 0x1;
static const CHANGED_LINE=  0x2;
static const DELETED_LINE=  0x4;


using se.lang.api.LanguageSettings;

void _diffedit_UpdateForm();
static bool in_cua_select;
static DIFF_UPDATE_INFO gDiffUpdateInfo={-1};
static int LastActiveEditWindowWID=0;

static void diff_quote_key();
static void diff_select_line();
static void diff_select_word();
static void diff_select_full_word();
static void diff_select_whole_word();
static void diff_select_subword();
static void diff_select_char();
static void diff_cua_select();
static void diff_deselect();
static void diff_mode_split_insert_line();
static void diff_multi_delete(...);
static void diff_rubout();
static void diff_linewrap_rubout();
static void diff_linewrap_delete_char(...);
static void diff_delete_char();
static void diff_cut_line();
static void diff_delete_line();
static void diff_paste();
static void diff_list_clipboards();
static void diff_copy_to_clipboard();
static void diff_copy_word();
static void diff_move_text_tab();
static void diff_ctab();
static void diff_cut_end_line();
static void diff_cut_word();
static void diff_delete_word();
static void diff_prev_word();
static void diff_next_word();
static void diff_complete_prev();
static void diff_complete_next();
static void diff_complete_more();
int _diff_save();
static int diff_find_next();
static int diff_find_prev();

static void diff_bas_enter();
static void diff_c_enter();
static void diff_cmd_enter();
static void diff_for_enter();
static void diff_pascal_enter();
static void diff_prg_enter();

static void diff_mode_space();
static void diff_expand_alias();
static void diff_undo();
static void diff_undo_cursor();
static void diff_command(...);
static void diff_command_and_update(...);
static void diff_maybe_deselect_command(...);
static void diff_shift_selection_right();
static void diff_shift_selection_left();
static void diff_maybe_complete();
static void diff_close_form();
static void diff_next_window(bool find_backward=false);
static int diff_exit();
static void diff_mou_click();
static void diff_cursor_left();
static void diff_cursor_right();
static void diff_mou_select_word();
static void diff_mou_select_line();
static void diff_end_line();
static void diff_find_matching_paren();
static void diff_join_line();
static void diff_find(...);
static void diff_mou_extend_selection();
static void diff_push_tag();
static void diff_pop_bookmark();
static void diff_cbacktab();
static void diff_next_proc();
static void diff_prev_proc();
static void diff_next_tag();
static void diff_prev_tag();
static void diff_find_re();
static void diff_html_key();
static void diff_find_backwards();
static void diff_right_side_of_window();
static void diff_left_side_of_window();
static void diff_vi_restart_word();
static void diff_vi_ptab();
static void diff_vi_pbacktab();
static void diff_vi_begin_next_line();
static void diff_codehelp_complete();
static int diff_quit();
static void diff_gui_goto_line();
static void diff_fast_scroll();
static void diff_scroll_page_down();
static void diff_scroll_page_up();
static int diff_next_difference(...);
static int diff_prev_difference();
static void diff_paste_replace_word();

struct DiffCommandInfo {
   bool supportedInStandardEdition;
   typeless typelessCommand;
};

//Don't put any of the "maybe-case-word" commands or "maybe-case-backspace"
//commands in this list.
static DiffCommandInfo DiffCommands:[]={
   "wh"                        => { true, wh },
   "list-symbols"              => { false, list_symbols },
   "function-argument-help"    => { false, function_argument_help },
   "quote-key"                 => { false, diff_quote_key },
   "maybe-complete"            => { false, diff_maybe_complete },
   "split-insert-line"         => { false, diff_mode_split_insert_line },
   "maybe-split-insert-line"   => { false, diff_mode_split_insert_line },
   "nosplit-insert-line"       => { false, diff_mode_split_insert_line },
   "nosplit-insert-line-above" => { false, diff_mode_split_insert_line },
   "rubout"                    => { false, diff_rubout },
   "linewrap-rubout"           => { false, diff_linewrap_rubout },
   "linewrap-delete-char"      => { false, diff_linewrap_delete_char },
   "vi-forward-delete-char"    => { false, diff_linewrap_delete_char },
   "delete-char"               => { false, diff_delete_char },
   "cut-line"                  => { false, diff_cut_line },
   "join-line"                 => { false, diff_join_line },
   "cut"                       => { false, diff_cut_line },
   "delete-line"               => { false, diff_delete_line },
   "brief-delete"              => { false, diff_linewrap_delete_char },
   "list-clipboards"           => { false, diff_list_clipboards },
   "paste"                     => { false, diff_paste },
   "paste-replace-word"        => { false, diff_paste_replace_word },
   "brief-paste"               => { false, diff_paste },
   "emacs-paste"               => { false, diff_paste },
   "find-next"                 => { false, diff_find_next },
   "search-again"              => { true, diff_find_next },
   "ispf-rfind"                => { false, diff_find_next },
   "find-prev"                 => { false, diff_find_prev },

   "c-enter"                   => { false, diff_mode_split_insert_line },
   "c-space"                   => { false, diff_mode_space },

   "html-enter"                => { false, diff_mode_split_insert_line },

   "slick-enter"               => { false, diff_mode_split_insert_line },
   "slick-space"               => { false, diff_mode_space },

   "cmd-enter"                 => { false, diff_mode_split_insert_line },
   "cmd-space"                 => { false, diff_mode_space },

   "for-enter"                 => { false, diff_mode_split_insert_line },
   "for-space"                 => { false, diff_mode_space },

   "sql-enter"                 => { false, diff_mode_split_insert_line },
   "sql-space"                 => { false, diff_mode_space },

   "plsql-enter"               => { false, diff_mode_split_insert_line },
   "plsql-space"               => { false, diff_mode_space },

   "sqlserver-enter"           => { false, diff_mode_split_insert_line },
   "sqlserver-space"           => { false, diff_mode_space },

   "pascal-enter"              => { false, diff_mode_split_insert_line },
   "pascal-space"              => { false, diff_mode_space },

   "prg-enter"                 => { false, diff_mode_split_insert_line },
   "prg-space"                 => { false, diff_mode_space },

   "expand-alias"              => { false, diff_expand_alias },

   "undo"                      => { true, diff_undo },
   "undo-cursor"               => { true, diff_undo },
   "select-line"               => { true, diff_select_line },
   "brief-select-line"         => { true, diff_select_line },
   "select-char"               => { true, diff_select_char },
   "brief-select-char"         => { true, diff_select_char },
   "cua-select"                => { true, diff_cua_select },
   "deselect"                  => { true, diff_deselect },
   "shift-selection-right"     => { true, diff_shift_selection_right },
   "shift-selection-left"      => { true, diff_shift_selection_left },
   "copy-to-clipboard"         => { true, diff_copy_to_clipboard },
   "append-to-clipboard"       => { true, diff_append_to_clipboard },
   "copy-word"                 => { true, diff_copy_word },

   "select-word"               => { false, diff_select_word },
   "select-whole-word"         => { false, diff_select_whole_word },
   "select-full-word"          => { false, diff_select_full_word },
   "select-subword"            => { false, diff_select_subword },

   "next-window"               => { true, diff_next_window },
   "prev-window"               => { true, diff_next_window },
   //I can get away with this because there are only 2 windows!!!

   "bottom-of-buffer"          => { true, {diff_maybe_deselect_command,bottom_of_buffer} },

   "top-of-buffer"             => { true, {diff_maybe_deselect_command,top_of_buffer} },

   "page-up"                   => { true, {diff_maybe_deselect_command,page_up} },

   "vi-page-up"                => { true, {diff_maybe_deselect_command,page_up} },

   "page-down"                 => { true, {diff_maybe_deselect_command,page_down} },

   "vi-page-down"              => { true, {diff_maybe_deselect_command,page_down} },

   "cursor-left"               => { true, {diff_maybe_deselect_command,cursor_left} },
   "vi-cursor-left"            => { true, {diff_maybe_deselect_command,cursor_left} },

   "cursor-right"              => { true, {diff_maybe_deselect_command,cursor_right} },
   "vi-cursor-right"           => { true, {diff_maybe_deselect_command,cursor_right} },

   "cursor-up"                 => { true, {diff_maybe_deselect_command,cursor_up} },
   "vi-prev-line"              => { true, {diff_maybe_deselect_command,cursor_up} },

   "cursor-down"               => { true, {diff_maybe_deselect_command,cursor_down} },
   "vi-next-line"              => { true, {diff_maybe_deselect_command,cursor_down} },

   "begin-line"                => { true, {diff_maybe_deselect_command,begin_line} },

   "begin-line-text-toggle"    => { true, {diff_maybe_deselect_command,begin_line_text_toggle} },

   "brief-home"                => { true, {diff_maybe_deselect_command,begin_line} },

   "vi-begin-line"             => { true, {diff_maybe_deselect_command,begin_line} },

   "vi-begin-line-insert-mode" => { true, {diff_maybe_deselect_command,begin_line} },

   "brief-end"                 => { true, {diff_maybe_deselect_command,end_line} },

   //"end-line"                => { true, {diff_maybe_deselect_command,end_line} },

   "end-line"                  => { true, diff_end_line },
   "end-line-text-toggle"      => { true, {diff_maybe_deselect_command,end_line_text_toggle} },
   "end-line-ignore-trailing-blanks" => { true, {diff_maybe_deselect_command,end_line_ignore_trailing_blanks} },

   "vi-end-line"               => { true, {diff_maybe_deselect_command,end_line} },

   "vi-end-line-append-mode"   => { true, {diff_maybe_deselect_command,end_line} },
   "mou-click"                 => { true, diff_mou_click },
   "mou-extend-selection"      => { true, diff_mou_extend_selection },
   "mou-select-word"           => { true, diff_mou_select_word },
   "mou-select-line"           => { true, diff_mou_select_line },
   "move-text-tab"             => { false, diff_move_text_tab },
   "vi-move-text-tab"          => { false, diff_move_text_tab },
   "move-text-tab"             => { false, diff_move_text_tab },
   "ctab"                      => { false, diff_ctab },
   "cbacktab"                  => { false, diff_cbacktab },
   "brief-tab"                 => { false, diff_move_text_tab },
   "smarttab"                  => { false, diff_ctab },
   "gnu-ctab"                  => { false, diff_ctab },
   "c-tab"                     => { false, diff_ctab },
   "cob-tab"                   => { false, diff_ctab },
   "cut-end-line"              => { false, diff_cut_end_line },
   "cut-word"                  => { false, diff_cut_word },
   "delete-word"               => { false, diff_delete_word },
   "prev-word"                 => { true, diff_prev_word },
   "next-word"                 => { true, diff_next_word },
   "complete-prev"             => { false, diff_complete_prev },
   "complete-next"             => { false, diff_complete_next },
   "complete-more"             => { false, diff_complete_more },
   "save"                      => { true, _diff_save },
   "brief-save"                => { true, _diff_save },
   "c-endbrace"                => { false, c_endbrace },
   "find-matching-paren"       => { true, diff_find_matching_paren },
   "gui-find"                  => { true, diff_find },
   "push-tag"                  => { false, diff_push_tag },
   "pop-bookmark"              => { false, diff_pop_bookmark },
   "next-proc"                 => { false, diff_next_proc },
   "prev-proc"                 => { false, diff_prev_proc },
   "next-tag"                  => { false, diff_next_tag },
   "prev-tag"                  => { false, diff_prev_tag },
   "re-search"                 => { true, diff_find_re },
   "html-key"                  => { false, diff_html_key },
   "search-forward"            => { true, diff_find },
   "search-backward"           => { true, diff_find_backwards },
   "gui-find-backward"         => { true, diff_find_backwards },
   "re-toggle"                 => { true, re_toggle },
   "case-toggle"               => { true, case_toggle },
   "right-side-of-window"      => { true, diff_right_side_of_window },
   "left-side-of-window"       => { true, diff_left_side_of_window },
   "vi-restart-word"           => { true, diff_vi_restart_word },
   "vi-ptab"                   => { false, diff_vi_ptab },
   "vi-pbacktab"               => { false, diff_vi_pbacktab },
   "vi-begin-next-line"        => { true, diff_vi_begin_next_line },
   "codehelp-complete"         => { false, diff_codehelp_complete },
   "quit"                      => { true, diff_quit },
   "close-window"              => { true, diff_quit },
   "safe-exit"                 => { true, diff_quit },
   "insert-toggle"             => { true, insert_toggle },
   "gui-goto-line"             => { true, diff_gui_goto_line },
   "fast-scroll"               => { true, diff_fast_scroll },
   "scroll-page-down"          => { true, diff_scroll_page_down },
   "scroll-page-up"            => { true, diff_scroll_page_up },
   "diff-next-diff"            => { true, diff_next_difference },
   "diff-prev-diff"            => { true, diff_prev_difference },
   "view-specialchars-toggle"  => { false, view_specialchars_toggle },
   "view-line-numbers-toggle"  => { false, view_line_numbers_toggle },
   "diff-close-and-edit"       => { false, diff_close_and_edit },
   "wfont-zoom-in"             => { true, {diff_command_and_update, wfont_zoom_in }},
   "wfont-zoom-out"            => { true, {diff_command_and_update, wfont_zoom_out }},
   "wfont-unzoom"              => { true, {diff_command_and_update, wfont_unzoom }},
};

#if 0 //4:17pm 5/10/2019
/**
 * Commands added here will give a message that the command 
 * cannot be run in diff and offer the user a chance to close 
 * the diff and run the command. 
 * 
 */
static _str DiffCloseAndRunCommands:[]={
   "project-build" =>  1 ,
   "load"          =>  1 ,
};
#endif

static DIFF_DELETE_ITEM gBufferListTable:[][];

definit()
{
   gDiffUpdateInfo.timer_handle=-1;
   gDiffUpdateInfo.list._makeempty();
   gBufferListTable._makeempty();
}

#if 0 //4:17pm 5/10/2019
static int diff_close_and_run_command(_str command_name) 
{
   result := _message_box(nls("The %s command cannot be run in diff\n\nWould you like to close diff and run it now?",command_name),"",MB_YESNO);
   if ( result == IDYES ) {
      name_index := find_index(command_name,COMMAND_TYPE);
      diff_close_form();
      if ( _no_child_windows() ) {
         call_index(name_index);
      } else {
         origWID := p_window_id;
         p_window_id = _mdi.p_child;
         call_index(name_index);
         p_window_id = origWID;
      }
      return 1;
   }
   return 0;
}
#endif

static void diff_load() 
{
   result := _message_box(nls("The load command cannot be run in diff\n\nWould you like to close diff and run it now?"),"",MB_YESNO);
   if ( result == IDYES ) {
      _nocheck _control _ctlfile1;
      _nocheck _control _ctlfile2;
      DIFF_MISC_INFO misc=_GetDialogInfo(DIFFEDIT_CONST_MISC_INFO,_ctlfile1);
      bufName := "";
      if ( p_window_id == _ctlfile1) {
         bufName = _diffGetFilenameFromDialog(misc,'1');
      } else if ( p_window_id == _ctlfile2 ) {
         bufName = _diffGetFilenameFromDialog(misc,'2');
      }
      diff_close_form();
      if (!_no_child_windows()) {
         _mdi.p_child.load(bufName);
      }
   }
}

static void diffSetSuspendStatus(int bufID,bool suspendStatus)
{
   DIFF_DELETE_ITEM itemList[];
   _nocheck _control _ctlfile1;
   itemList = _GetDialogInfoHt("DeleteList",_ctlfile1);
   
   for ( i:=0;i<itemList._length();++i ) {
      int curBufID;
      if ( itemList[i].isView ) {
         curBufID = itemList[i].item.p_buf_id;
      }else{
         curBufID = itemList[i].item;
      }

      if ( curBufID == bufID ) {
         itemList[i].isSuspended = suspendStatus;
      }
   }

   _SetDialogInfoHt("DeleteList",itemList,_ctlfile1);
}

/**
 * @param bufID id to suspend status for
 * 
 */
static void diffSuspendDelete(int bufID)
{
   diffSetSuspendStatus(bufID,true);
}

static bool diffIsSuspendedDelete(int bufID)
{
   DIFF_DELETE_ITEM itemList[];
   _nocheck _control _ctlfile1;
   itemList = _GetDialogInfoHt("DeleteList",_ctlfile1);
   
   for ( i:=0;i<itemList._length();++i ) {
      int curBufID;
      if ( itemList[i].isView ) {
         curBufID = itemList[i].item.p_buf_id;
      }else{
         curBufID = itemList[i].item;
      }

      if ( curBufID == bufID ) {
         return itemList[i].isSuspended;
      }
   }
   return false;
}

static void setMarkerID(int &origFilePosMarker)
{
   save_pos(auto p);
   while ( _lineflags()&NOSAVE_LF ) {
      if ( up() ) break;
   }
   if ( !p_line ) {
      restore_pos(p);
      while ( _lineflags()&NOSAVE_LF ) {
         if ( down() ) break;
      }
   }
   origFilePosMarker=_alloc_selection('B');
   if (origFilePosMarker>=0) {
      _select_char(origFilePosMarker);
   }
   restore_pos(p);
}

defeventtab _diff_form;

void ctloptions.lbutton_up()
{
   orig_diff_flags := def_diff_flags;
   show('-modal _diffsetup_form','',true,false,null,true);
   if ( orig_diff_flags!=def_diff_flags ) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
      result := _message_box(nls("Re-Diff files now?"),"",MB_YESNO);
      if ( result==IDYES ) {
         _control _ctlfile1;
         _SetDialogInfoHt("lastDiffOptions",null,_ctlfile1);
         ctlrediff.call_event(ctlrediff,LBUTTON_UP);
      }
   }
}

static void diff_goto_line(int lineNumber,bool useRLine=true)
{
   _str old_scroll_style=_scroll_style();
   _scroll_style('c');

   if ( useRLine ) {
      p_RLine= lineNumber;
   } else {
      p_line = lineNumber;
   }

   _scroll_style(old_scroll_style);
}

void _ctlfile1line.lbutton_up()
{
   editorWID := _control _ctlfile1;
   otherWID  := _control _ctlfile2;
   if ( p_name == "_ctlfile2line" ) {
      editorWID = _control _ctlfile2;
      otherWID  = _control _ctlfile1;
   }
   result := show('-modal _textbox_form',
                  'Go to line',          // Caption
                   TB_RETRIEVE,          // flags
                   0,                    // Default text box width
                   'line navigation',      // help item
                   '',                   // Buttons and captions
                   'gui_goto_line',      // retrieve name
                   '-r 0,2147483647 Line Number (1 - 'editorWID.p_RNoflines'):'editorWID.p_RLine
                   );
   if ( result=="" ) return;
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');

   lineNumber := _param1;
   _param1 = "";

   editorWID.diff_goto_line(lineNumber);
   otherWID.diff_goto_line(editorWID.p_line,false);

   // Update the line number indicators
   _ctlfile1line.p_caption=_ctlfile1.p_line'/'(_ctlfile1.p_Noflines);
   _ctlfile2line.p_caption=_ctlfile2.p_line'/'(_ctlfile2.p_Noflines);
}

int _diff_copy_button(int markerType,int markerIndex)
{
   // Markers are deleted in diff_copy_block


   _control _ctlcopy_left;
   _control _ctlcopy_right;
   copyLeftType := _GetDialogInfoHt("copyLeftType",_ctlfile1);
   copyRightType := _GetDialogInfoHt("copyRightType",_ctlfile1);
   _ctlfile1.diff_deselect();
   _ctlfile2.diff_deselect();
   _LineMarkerGet(markerIndex,auto info);

   _ctlfile1.p_line = info.LineNum;
   _ctlfile2.p_line = info.LineNum;

   status := 0;

   if ( markerType==copyLeftType ) {
      status = _ctlcopy_left.call_event(_ctlcopy_left,LBUTTON_UP);
   } else if ( markerType==copyRightType ) {
      if ( _find_control('_ctlcopy_right') ) {
         status = _ctlcopy_right.call_event(_ctlcopy_right,LBUTTON_UP);
      } else if ( _find_control('ctlCopyBlock') ) {
         _nocheck _control ctlCopyBlock;
         status = ctlCopyBlock.call_event(ctlCopyBlock,LBUTTON_UP);
      } 
   }

   rc = status;
   return status;
}

void ctltypetoggle.lbutton_up()
{
   _SetDialogInfoHt("inTypeToggle",1,_ctlfile1);
   // if file 2 was copy used for Source diff, realFile2Name is set to the the name
   // of the file that it is a copy of
   realFile2Name := "";
   sourceDiff := false;

   // Check the caption.  We don't actually change it because the dialog is 
   // going to be closed and relaunched.
   if ( p_caption=="Source Diff" ) {
      sourceDiff = true;
   }else if ( p_caption=="Line Diff" ) {
      _str FileTitles=_DiffGetDialogTitles();
      File1Title := strip(parse_file(FileTitles),'B','"');
      File2Title := strip(parse_file(FileTitles),'B','"');
      realFile2Name = StripFileOrBuffer(File2Title);
   }

   _nocheck _control _ctlfile1;
   _str bufInfo1=_GetDialogInfo(DIFFEDIT_CONST_BUFFER_INFO1,_ctlfile1);
   _str bufInfo2=_GetDialogInfo(DIFFEDIT_CONST_BUFFER_INFO2,_ctlfile1);
   _str VCDiffType=_GetDialogInfo(DIFFEDIT_VC_DIFF_TYPE,_ctlfile1);
   DIFF_MISC_INFO misc=_GetDialogInfo(DIFFEDIT_CONST_MISC_INFO,_ctlfile1);
   DIFF_READONLY_TYPE readOnly1=_GetDialogInfo(DIFFEDIT_READONLY1_VALUE,_ctlfile1);
   DIFF_READONLY_TYPE readOnly2=_GetDialogInfo(DIFFEDIT_READONLY2_VALUE,_ctlfile1);
   parse bufInfo1 with auto bufID1 auto file1inmem auto file1readonly;
   parse bufInfo2 with auto bufID2 auto file2inmem auto file2readonly;

   _ctlfile1.setMarkerID(auto origFile1PosMarker);
   _SetDialogInfoHt("origFile1PosMarker",origFile1PosMarker,_ctlfile1);
   seek := _ctlfile1._QROffset();
   bufID1 = misc.WholeFileBufId1;
   bufID2 = misc.WholeFileBufId2;
   closeBuffer2Option := misc.closeBuffer2 ? " -internalclosebuffer2 " : "";



   wasModal := p_active_form.p_modal;
   formWID := p_active_form;
   status := _ctlclose.call_event(_ctlclose,LBUTTON_UP);

   // Build string of buffer and window IDs to pass to diff to remember to delete
   // when we aren't toggling
   DIFF_DELETE_ITEM itemList[] = gBufferListTable:[formWID];
   itemListOption := "";
   if ( itemList._length()>0 ) {
      for (i:=0;i<itemList._length();++i) {
         windowStr := itemList[i].isView?"w:":"";
         if (i==0) {
            itemListOption = "-deletebufferlist "windowStr:+itemList[i].item;
         } else {
            itemListOption = itemListOption :+ ","windowStr:+itemList[i].item;
         }
      }
   }
   gBufferListTable._deleteel(formWID);

   if ( VCDiffType!="") {
      // If this is a version control diff, set a global variable for the type
      // The caller will have to call diff again with the proper option.
      _param1 = sourceDiff?"code":"line";
      return;
   }
   // At this point, file 1 is open, because we set its inmem state
   // to 1. File 2 is open if it was a 'real' file.  If it was a
   // copy made for source diff, we let it close

   modalOption :=  wasModal? "-modal":"";
   _str sourceDiffOptions = sourceDiff ? "-sourcediff" : "";
   _str readOnly1Option = readOnly1==DIFF_READONLY_SET_BY_USER ? "-r1" : "";
   _str readOnly2Option = readOnly2==DIFF_READONLY_SET_BY_USER ? "-r2" : "";
   _str diffParentOption = misc.DiffParentWID ? "-RegisterAsMFDChild "misc.DiffParentWID : "";
   file2Option := "";
   file2Spec := "";
   if ( realFile2Name=="" ) {
      file2Spec = bufID2;
      file2Option  = "-bi2";
   }else{
      file2Spec = _maybe_quote_filename(realFile2Name);
   }

   diff(sourceDiffOptions:+' ':+itemListOption:+' ':+readOnly1Option:+' ':+closeBuffer2Option:+' ':+diffParentOption' ':+modalOption:+' -point ':+seek' ':+readOnly2Option:+' -bi1 ':+file2Option:+' -bufferstate1 'file1inmem' -bufferstate2 'file2inmem' 'bufID1' 'file2Spec);
}


static int getDiffFormFromBufID(int bufID)
{
   last := _last_window_id();
   formWID := 0;

   for (i:=1; i<=last; ++i) {
      if (_iswindow_valid(i) && 
          (i.p_name=="_ctlfile1" || i.p_name=="_ctlfile2") &&
          (i.p_parent) && _isdiff_form(i.p_parent.p_name) ) {
         if (!bufID || bufID==i.p_buf_id) {
            if (!i.p_edit && i.p_visible) {
               return i.p_parent;
            }
         }
      }
   }
   return(0);
}

/** 
 * Change the in memory status of bufID.  This is used in case a 
 * file was diffed and not already open in the editor, and then 
 * is opened while the file is being diffed. 
 */
static void changeInMem(int bufID,bool newInMem)
{
   formWID := getDiffFormFromBufID(bufID);
   if (formWID!=null) {
      index := 0;
      if (formWID._ctlfile1.p_buf_id==bufID) {
         index = DIFFEDIT_CONST_BUFFER_INFO1;
      }else if (formWID._ctlfile2.p_buf_id==bufID) {
         index = DIFFEDIT_CONST_BUFFER_INFO2;
      }
      bufInfo := _GetDialogInfo(index,formWID._ctlfile1);
      if (bufInfo!=null) {
         parse bufInfo with auto diffBufID auto fileInMem auto fileReadOnly;
         bufInfo = diffBufID' 'newInMem' 'fileReadOnly;
         _SetDialogInfo(index,bufInfo,formWID._ctlfile1);
      }
   }
}

/** 
 * This is called when a file that was not already open when it 
 * was diffed is opened and unhidden. 
 */
void _cbmdibuffer_unhidden_diffedit()
{
   if (_isdiffed(p_buf_id)) {
      last := _last_window_id();

      // Find the diff dialog that has this buffer
      formWID := getDiffFormFromBufID(p_buf_id);
      if (formWID) {
         // Tell the editor that the file was already in memmory so the 
         // readonly property is reset properly
         changeInMem(p_buf_id,true);

         // Remove the buffer ID from the list of buffers to be deleted
         removeFromDeleteList(p_buf_id,formWID);

         // Set a flag to blast the undo when we close the diff, because since
         // the file was opened after the diff was already opened, we cannot
         // let the user undo into where the imaginary lines were inserted
         _SetDialogInfoHt("blastUndoInfo",p_window_id,formWID._ctlfile1);
      }
   }
}

static void removeFromDeleteList(int bufID,int formWID)
{
   DIFF_DELETE_ITEM deleteList[] = _GetDialogInfoHt("DeleteList",formWID._ctlfile1);
   len := deleteList._length();
   for (i:=0;i<len;++i) {
      curBufID := 0;
      if (deleteList[i].isView) {
         curBufID = deleteList[i].item.p_buf_id;
      } else {
         curBufID = deleteList[i].item;
      }
      if ( bufID == curBufID ) {
         deleteList._deleteel(i);
         break;
      }
   }
   _SetDialogInfoHt("DeleteList",deleteList,formWID._ctlfile1);
}

void _ctlfile1_readonly.lbutton_up()
{
   _ctlfile1.p_ProtectReadOnlyMode=(p_value)?VSPROTECTREADONLYMODE_ALWAYS:VSPROTECTREADONLYMODE_NEVER;
}
void _ctlfile2_readonly.lbutton_up()
{
   _ctlfile2.p_ProtectReadOnlyMode=(p_value)?VSPROTECTREADONLYMODE_ALWAYS:VSPROTECTREADONLYMODE_NEVER;
}

void _PositionDiffLegendLabels()
{
   if ( !_find_control('ctlconflictindicator') ) {
      return;
   }
   ctlconflictindicator.p_width=ctlconflictindicator._text_width(ctlconflictindicator.p_caption);
   ctlconflictindicator.p_height=ctlconflictindicator._text_height();
   ctlconflictindicator.p_x=_ctlcopy_right.p_x;

   typeless bg,fg;
   parse _default_color(CFG_MODIFIED_LINE) with fg bg .;
   _ctlmodified_label.p_width=_ctlmodified_label._text_width(_ctlmodified_label.p_caption);
   _ctlmodified_label.p_forecolor=fg;
   _ctlmodified_label.p_backcolor=bg;
   parse _default_color(CFG_INSERTED_LINE) with fg bg .;
   _ctlmodified_label.p_x=_ctlinserted_label.p_x_extent+(_twips_per_pixel_x()*3);
   _ctlinserted_label.p_width=_ctlinserted_label._text_width(_ctlinserted_label.p_caption);
   _ctlinserted_label.p_forecolor=fg;
   _ctlinserted_label.p_backcolor=bg;
   parse _default_color(CFG_NOSAVE_LINE) with fg bg .;
   _ctlimaginary_label.p_x=_ctlmodified_label.p_x_extent+(_twips_per_pixel_x()*3);
   _ctlimaginary_label.p_width=_ctlimaginary_label._text_width(_ctlimaginary_label.p_caption);
   _ctlimaginary_label.p_forecolor=fg;
   _ctlimaginary_label.p_backcolor=bg;
   parse _default_color(CFG_IMAGINARY_SPACE) with fg bg .;
   ctlbuffered_label.p_x=_ctlimaginary_label.p_x_extent+(_twips_per_pixel_x()*3);
   ctlbuffered_label.p_width=_ctlimaginary_label._text_width(_ctlimaginary_label.p_caption);
   ctlbuffered_label.p_forecolor=fg;
   ctlbuffered_label.p_backcolor=bg;
}

static _str StripFileOrBuffer(_str name)
{
   p := lastpos('(',name);
   if (p<2) {
      return(name);
   }
   return(substr(name,1,p-1));
}

/**
 * Form with editors and scroll bars must be active when this is called
 */
void _DiffSetupScrollBars()
{
   vscroll1.p_max=_ctlfile1.p_Noflines-_ctlfile1.p_char_height;

   vscroll1.p_large_change=_ctlfile1.p_char_height-1;
   _DiffVscrollSetLast(vscroll1.p_value);

   _DiffHscrollSetLast(hscroll1.p_value);
}

#if 1 /*__MACOSX__*/
    void macSetStandaloneDiffzilla(int formWid);
#endif

static int diff_push_tag_in_file(_str proc_name, _str file_name, _str class_name, _str type_name, int line_no)
{
   diff_push_tag_line(line_no);
   return 0;
}

void _ctlfile1.on_create(_str name1NoType='', _str name2NoType='', _str diffOptions='')
{
   if (_isMac()) {
      if(_default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS) == SW_HIDE) {
          macSetStandaloneDiffzilla(p_active_form);
      }
   }
   call_list('_diffOnStart_');
   _DiffSetupScrollBars();
   _DiffSetNeedRefresh(true);
   LastActiveEditWindowWID=_ctlfile1;
   //_ctlmodified_label
   _PositionDiffLegendLabels();
   IsDiff := diffOptions=='diff';
   if ( _find_control('_ctlfile1label') ) {
      // Because of clipboard inheritance, these may not be there
      _ctlfile1label.p_caption=name1NoType;
      _ctlfile2label.p_caption=name2NoType;
   }else{
      _DiffSetFileLabelsMissing();
   }
   name1NoType=StripFileOrBuffer(name1NoType);
   name2NoType=StripFileOrBuffer(name2NoType);
   if ( !_find_control('_ctlfile1line') ) {
      _DiffSetLineNumLabelsMissing();
   }
   if ( !_find_control('_ctlfile1_readonly') ) {
      _DiffSetReadOnlyCBMissing();
   }
   if ( !_find_control('_ctlnext_difference') ) {
      _DiffSetNextDiffMissing();
   }
   if ( !_find_control('_ctlclose') ) {
      _DiffSetCloseMissing();
   }
   if ( !_find_control('_ctlcopy_right') ) {
      _DiffSetCopyMissing();
   }
   if ( !_find_control('_ctlcopy_left') ) {
      _DiffSetCopyLeftMissing();
   }

   _DiffSetDialogTitles(name1NoType,name2NoType);
   _ctlfile1.p_scroll_left_edge=-1;
   _ctlfile2.p_scroll_left_edge=-1;

   foundContextCombo := _find_control("ctlcontextCombo1");
   if (_haveCurrentContextToolBar() && foundContextCombo && !(def_diff_edit_flags&DIFFEDIT_HIDE_CURRENT_CONTEXT)) {
      ctlcontextCombo1.context_window_set_editor_wid(_ctlfile1);
      ctlcontextCombo2.context_window_set_editor_wid(_ctlfile2);

      ctlcontextCombo1.context_window_set_push_tag_pointer(diff_push_tag_in_file);
      ctlcontextCombo2.context_window_set_push_tag_pointer(diff_push_tag_in_file);
   } else if (foundContextCombo) {
      ctlcontextCombo1.p_enabled = ctlcontextCombo2.p_enabled = false;
      ctlcontextCombo1.p_visible = ctlcontextCombo2.p_visible = false;
   }

   if ( p_active_form.p_name=='_diff_form' ) {
      if (!VF_IS_STRUCT(gDiffUpdateInfo)) {
         gDiffUpdateInfo.timer_handle=-1;
      }
      len := gDiffUpdateInfo.list._length();
      gDiffUpdateInfo.list[len].wid=p_active_form;
      gDiffUpdateInfo.list[len].isdiff=IsDiff;
      gDiffUpdateInfo.list[len].NeedToSetupHScroll=false;
      if (gDiffUpdateInfo.timer_handle<0) {
         gDiffUpdateInfo.timer_handle=_set_timer(100,_diffedit_UpdateForm);
      }
   }

   _SetDialogInfo(DIFFEDIT_CONST_HAS_MODIFY,false);
}

void _DiffAddWindow(int wid,bool isDiff)
{
   len := gDiffUpdateInfo.list._length();
   gDiffUpdateInfo.list[len].wid=wid;
   gDiffUpdateInfo.list[len].isdiff=isDiff;
   gDiffUpdateInfo.list[len].NeedToSetupHScroll=false;
   if (gDiffUpdateInfo.timer_handle<0) {
      gDiffUpdateInfo.timer_handle=_set_timer(100,_diffedit_UpdateForm);
   }
}

void _DiffRemoveWindow(int wid,bool isDiff)
{
   for (i:=0;i<gDiffUpdateInfo.list._length();++i) {
      if (gDiffUpdateInfo.list[i].wid==wid) {
         gDiffUpdateInfo.list._deleteel(i);
         break;
      }
   }
   if (!gDiffUpdateInfo.list._length() && gDiffUpdateInfo.timer_handle>-1) {
      _kill_timer(gDiffUpdateInfo.timer_handle);
      gDiffUpdateInfo.timer_handle=-1;
   }
}

static bool isNotFileOrBuffer()
{
   parse p_caption with '(' auto fileBufferOrVersion ')';
   if ( lowcase(fileBufferOrVersion)!="file" && lowcase(fileBufferOrVersion)!="buffer" ) {
      return true;
   }
   return false;
}

/** 
 * Version numbers, not "File" or "Buffer" 
 */
static bool bothSidesHaveVersions()
{
   return _ctlfile1label.isNotFileOrBuffer() && _ctlfile2label.isNotFileOrBuffer();
}

static edit_window_rbutton_up()
{
   if (!select_active()) {
      mou_click();
   }

   otherwid := GetOtherWid(auto wid);
   otherwid.p_line = p_line;

   inImaginary := _lineflags() & NOSAVE_LF;
   int index=find_index("_diff_menu",oi2type(OI_MENU));
   int menu_handle=_mdi._menu_load(index,'P');
   int x,y;
   mou_get_xy(x,y);
   status := _menu_find(menu_handle,"diff-edit-menu align", auto outputHandle, auto outputMenuPos, 'M');
   if (pos('History Diff',p_active_form.p_caption)) {
      if (pos('Backup History',p_active_form.p_caption) ) {
         // Have to check for this because we want to allow this for the left 
         // pane in backup history, as long as the left pane is actually the
         // current file.
         _nocheck _control ctllabel1;
         _nocheck _control ctltype_combo;
         if (p_name=='_ctlfile2' || ctltype_combo.p_text!=LOCAL_FILE_CAPTION) {
            _menu_delete(outputHandle,outputMenuPos);
         }
      } else {
         _menu_delete(outputHandle,outputMenuPos);
      }
   } else {
      if ( p_name=='_ctlfile2' && _ctlfile2_readonly.p_value ) {
         _menu_delete(outputHandle,outputMenuPos);
      }
      if (_ctlfile1label.bothSidesHaveVersions() && _ctlfile2label.bothSidesHaveVersions()) {
         outputHandle=0;
         outputMenuPos=0;
         status = _menu_find(menu_handle,"diff-edit-menu close-and-edit", outputHandle, outputMenuPos, 'M');
         if (!status) {
            _menu_delete(outputHandle,outputMenuPos);
         }
      }
   }

   alignPending := _ctlfile1.p_mouse_pointer == MP_ARROW || _ctlfile2.p_mouse_pointer == MP_ARROW;

   if ( alignPending ) {
      _menu_delete(menu_handle,0);
      _menu_insert(menu_handle,0,MF_ENABLED,"Cancel Align With","diff_edit_menu cancel-align");
   } else {
      // If we are on an imaginary line, remove the "Align with..." item from the
      // menu.  We know it is the 0th item in the menu.
      if ( inImaginary ) {
         _menu_delete(menu_handle,0);
      }
   }
   status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

void _DiffRemoveImaginaryLines()
{
   //No longer need to save_pos and restore_pos because we only do this on the
   //way out, and it sometimes causes invalid point errors
   oldmodify := p_modify;
   top();up();
   while (!down()) {
      if (_lineflags()&NOSAVE_LF) {
         _delete_line();up();
      }
   }
   p_modify=oldmodify;
}

#if 1
void _DiffClearLineFlagsMacro()
{
   save_pos(auto p);
   top();up();
   while (!down()) {
      _lineflags(0,MODIFY_LF|INSERTED_LINE_LF);
   }
   restore_pos(p);
}
#endif

static void diffUnsuspendItems()
{
   DIFF_DELETE_ITEM itemList[];
   itemList = _GetDialogInfoHt("DeleteList",_ctlfile1);
   for ( i:=0;i<itemList._length();++i ) {
      itemList[i].isSuspended = false;
   }
   _SetDialogInfoHt("DeleteList",itemList,_ctlfile1);
}

static void diffDeleteItems()
{
   DIFF_DELETE_ITEM itemList[];
   itemList = _GetDialogInfoHt("DeleteList",_ctlfile1);
   
   deletedBufferList := "";
   INTARRAY bufferIDsToRemove;
   for ( i:=0;i<itemList._length();++i ) {
      if ( !itemList[i].isSuspended ) {
         if ( itemList[i].isView ) {
            if ( !pos(' 'itemList[i].item.p_buf_id' ',' 'deletedBufferList' ') ) {
               deletedBufferList :+= ' 'itemList[i].item.p_buf_id;
               ARRAY_APPEND(bufferIDsToRemove, i);
               itemList[i].item._delete_buffer();
            }
            itemList[i].item._delete_window();
         }else{
            if ( !pos(' 'itemList[i].item' ',' 'deletedBufferList' ') ) {
               if ( !maybeDeleteBuffer(itemList[i].item,deletedBufferList, bufferIDsToRemove) ) {
                  ARRAY_APPEND(bufferIDsToRemove, i);
               }
            }
         }
      }
   }
   for ( i=bufferIDsToRemove._length()-1;i>=0;--i ) {
      itemList._deleteel(bufferIDsToRemove[i]);
   }

   _SetDialogInfoHt("DeleteList",itemList,_ctlfile1);
}

static int maybeDeleteBuffer(int bufID,_str &deletedBufferList, INTARRAY &bufferIDsToRemove)
{
   origWID := p_window_id;
   p_window_id=HIDDEN_WINDOW_ID;
   _safe_hidden_window();
   status := load_files('+bi 'bufID);
   if ( !status ) {
      if ( diffSafeToDeleteBuffer(p_buf_id,p_window_id,p_buf_flags) ) {
         deletedBufferList :+= ' 'p_buf_id;
         ARRAY_APPEND(bufferIDsToRemove,p_buf_id);
         _delete_buffer();
         p_window_id = origWID;
         return 0;
      }
   }
   p_window_id=origWID;
   return 1;
}

/**
 * Determines if there is another window viewing a buffer.  This function also
 * searchings windows created by _create_temp_view() and
 * _open_temp_view() functions (for diff).  Also checks MDI
 * children.
 *
 * @param buf_id    Buffer id
 * @param skip_wid  Window to ignore
 *
 * @return Returns true if there is a window other than <i>skip_wid</i> displaying this buffer.
 */
static bool diffDialogViewingBuffer(int buf_id,int skip_wid=0)
{
   int i;
   for (i=1;i<=_last_window_id();++i) {
      if (i!=skip_wid && _iswindow_valid(i) &&
          i.p_HasBuffer && i.p_buf_id==buf_id && i!=VSWID_HIDDEN &&
          !i.p_IsMinimap && i.p_name!='_ctlfile1' && i.p_name!='_ctlfile2'
          ) {
         return(true);
      }
   }
   return(false);
}

/**
 * Tests whether it is safe to delete a buffer currently being
 * viewed by a dialog or a view created by
 * _create_temp_view() or _open_temp_view() (for diff).
 * 
 * Difference for diff is that this will also check MDI
 * children.
 *
 * @param buf_id    Buffer id.  p_buf_id.
 * @param skip_dialog_wid
 *                  Window ID (p_window_id) of the dialog window viewing
 *                  this buffer.  This should be 0 when calling to delete
 *                  a buffer viewed by _create_temp_view() or _open_temp_view().
 * @param buf_flags Buffer flags (p_buf_flags) of the buffer you might delete.
 * @return Returns true if it is safe to delete the buffer.
 */
static bool diffSafeToDeleteBuffer(int buf_id,int skip_dialog_wid=0,int buf_flags=0)
{
   return(!(buf_flags & VSBUFFLAG_KEEP_ON_QUIT) &&
          !diffDialogViewingBuffer(buf_id,skip_dialog_wid));
}

static void cleanupSourceDiffMarkers(_str name)
{
   diffCodeMarkerType := _GetDialogInfoHt(name,_ctlfile2);

   if (diffCodeMarkerType) {
      _StreamMarkerRemoveType(_ctlfile1,diffCodeMarkerType);
      _StreamMarkerRemoveType(_ctlfile2,diffCodeMarkerType);
      _MarkerTypeFree(diffCodeMarkerType);
   }
}
static void cleanupScrollMarkers(_str name)
{
   diffScrollMarkupType := _GetDialogInfoHt(name,_ctlfile1);
   if ( diffScrollMarkupType ) {
      _StreamMarkerRemoveType(_ctlfile1,diffScrollMarkupType);
      _MarkerTypeFree(diffScrollMarkupType);
   }
}

static void saveAllPositions(int bufID, STRHASHTAB &positions)
{
   count := 0;
   for (i:=1;i<=_last_window_id();++i) {
      if ( _iswindow_valid(i) &&
           i != HIDDEN_WINDOW_ID &&
           i.p_object==OI_EDITOR &&
           !i.p_IsMinimap &&
          i.p_HasBuffer && i.p_buf_id == bufID && !i.p_IsTempEditor && !(i.p_buf_flags&VSBUFFLAG_HIDDEN) ) {
         i.save_pos(auto p,1);
         positions:[i] = p;
         ++count;
      }
   }
}

static void restoreAllPositions(int bufID, STRHASHTAB &positionList)
{
   foreach ( auto curWID => auto p in positionList ) {
      if ( curWID.p_buf_id==bufID ) {
         curWID.restore_pos(p);
      }
   }
}

_str _diffGetFilenameFromDialog(DIFF_MISC_INFO &misc,_str which)
{
   origWID := p_window_id;
   filename := "";
   p_window_id = HIDDEN_WINDOW_ID;
   status := 0;

   if ( which=='1' ) {
      status = load_files('+bi 'misc.WholeFileBufId1);
   } else {
      status = load_files('+bi 'misc.WholeFileBufId2);
   }
   if (!status) {
      filename = p_buf_name;
   } else {
      // Buffer ID may be invalid
      clear_message();
   }
   p_window_id = origWID;
   return filename;
}

static int resetReadOnly(int bufID,int inmem,int origReadOnly)
{
   status := 0;
   if (inmem || diffIsSuspendedDelete(bufID)) {
      origWID := p_window_id;
      p_window_id = HIDDEN_WINDOW_ID;
      _safe_hidden_window();
      status = load_files('+bi 'bufID);
      if (!status) {
         p_readonly_mode=origReadOnly!=0;
      }
      p_window_id = origWID;
   }
   return status;
}

static void removeMarginButtonFromList(INTARRAY &list)
{
   len := list._length();
   for (i:=0;i<len;++i) {
      VSLINEMARKERINFO info;
      _LineMarkerGet(list[i], info);
      if (info.BMIndex==_pic_merge_left || info.BMIndex==_pic_merge_right) {
         _LineMarkerRemove(list[i]);
      }
   }
}

/** 
 * Removes copy button from margin if it is in the list of 
 * bitmaps 
 * 
 * @param linenum NOT a real line number
 */
static void removeMarginButtonsFromLine(int lineNum)
{
   _LineMarkerFindList(auto list, _ctlfile1, lineNum, VSNULLSEEK, true );
   removeMarginButtonFromList(list);

   list = null;

   _LineMarkerFindList(list, _ctlfile2, lineNum, VSNULLSEEK, true );
   removeMarginButtonFromList(list);
}

static void diffStoreUndeletedItems()
{
   DIFF_DELETE_ITEM itemList[];
   itemList = _GetDialogInfoHt("DeleteList",_ctlfile1);

   gBufferListTable:[p_active_form] = itemList;
}

_ctlfile1.on_destroy()
{
   call_list('_diffOnExit_');
   inTypeToggle := _GetDialogInfoHt("inTypeToggle",_ctlfile1);
   if (inTypeToggle==null) inTypeToggle=0;

   DIFF_MISC_INFO misc=_GetDialogInfo(DIFFEDIT_CONST_MISC_INFO,_ctlfile1);
   do {
      modifiedMarkerType := _GetDialogInfoHt("modifiedMarkerType",_ctlfile1);
      insertedMarkerType := _GetDialogInfoHt("insertedMarkerType",_ctlfile1);
      _StreamMarkerRemoveAllType(insertedMarkerType);
      _StreamMarkerRemoveAllType(modifiedMarkerType);
      if (modifiedMarkerType!=null) _MarkerTypeFree(modifiedMarkerType);
      if (insertedMarkerType!=null) _MarkerTypeFree(insertedMarkerType);
      _SetDialogInfoHt("modifiedMarkerType",null,_ctlfile1);
      _SetDialogInfoHt("insertedMarkerType",null,_ctlfile1);

      copyLeftType := _GetDialogInfoHt("copyLeftType",_ctlfile1);
      copyRightType := _GetDialogInfoHt("copyRightType",_ctlfile1);
      _LineMarkerRemoveType(_ctlfile1,copyRightType);
      _LineMarkerRemoveType(_ctlfile2,copyLeftType);

      if (!VF_IS_STRUCT(misc)) {
         //Things are not set up correctly
         if ( (!gDiffUpdateInfo.list._length() || (gDiffUpdateInfo.list._length()==1 && gDiffUpdateInfo.list[0].wid==p_active_form) )
              && gDiffUpdateInfo.timer_handle>-1) {
            _kill_timer(gDiffUpdateInfo.timer_handle);
            gDiffUpdateInfo.timer_handle=-1;
            if (gDiffUpdateInfo.list._length()==1) {
               gDiffUpdateInfo.list=null;
            }
         }
         break;
      } else {
         _DiffRemoveWindow(_ctlfile1.p_parent,true);
      }
      if (misc.SoftWrap1!=null) _ctlfile1.p_SoftWrap=misc.SoftWrap1;
      if (misc.SoftWrap2!=null) _ctlfile2.p_SoftWrap=misc.SoftWrap2;
      fid := p_active_form;
      if (substr(p_active_form.p_caption,1,5)!='Merge') {
         DiffFreeAllColorInfo(_ctlfile1.p_buf_id);
         DiffFreeAllColorInfo(_ctlfile2.p_buf_id);
      }
      _DiffSetBuffersAreDiffed(false, misc);

      filename1 := _diffGetFilenameFromDialog(misc,'1');
      filename2 := _diffGetFilenameFromDialog(misc,'2');
      if ( filename2 == "" ) {
         // For source diff there will not be a buffer name becuase the buffer 
         // that is there is the one we balanced
         filename2 = _GetDialogInfoHt("Buf2Name",_ctlfile1);
      }
      _str bufInfo1=_GetDialogInfo(DIFFEDIT_CONST_BUFFER_INFO1,_ctlfile1);
      if ( bufInfo1==null ) bufInfo1='';
   
      i := 0;
      _str bufInfo2=_GetDialogInfo(DIFFEDIT_CONST_BUFFER_INFO2,_ctlfile1);
      if ( bufInfo2==null ) bufInfo2='';
      if (bufInfo1==null && bufInfo2==null) {
         for (i=0;i<gDiffUpdateInfo.list._length();++i) {
            if (gDiffUpdateInfo.list[i].wid==fid) {
               gDiffUpdateInfo.list._deleteel(i);
               break;
            }
         }
         if (!gDiffUpdateInfo.list._length() && gDiffUpdateInfo.timer_handle>-1) {
            _kill_timer(gDiffUpdateInfo.timer_handle);
            gDiffUpdateInfo.timer_handle=-1;
         }
         break;
      }
   
      wid := 0;
      typeless status=0;
      typeless bufid1='';
      typeless bufid2='';
      typeless file1inmem='';
      typeless file2inmem='';
      typeless file1readonly='';
      typeless file2readonly='';
      parse bufInfo1 with bufid1 file1inmem file1readonly;
      parse bufInfo2 with bufid2 file2inmem file2readonly;
      if ( inTypeToggle==1 ) {
         if (!file1inmem) {
            diffSuspendDelete(misc.WholeFileBufId1);
            resetReadOnly(misc.WholeFileBufId1,file1inmem,file1readonly);
         }
         if (!file2inmem || misc.closeBuffer2) {
            diffSuspendDelete(misc.WholeFileBufId2);
            resetReadOnly(misc.WholeFileBufId2,file1inmem,file2readonly);
         }
      }
      if (bufInfo1!='') {
         if (misc.WholeFileBufId1>=0 && _ctlfile1.p_buf_id != misc.WholeFileBufId1) {
            //Have to do this because _delete_temp_view will not delete the buffer.
            //DiffQuitView(misc.SymbolViewId1);
            // Since we're overlaying the buffer, we have to save the original 
            // file position
            resetReadOnly(misc.WholeFileBufId1,file1inmem,file1readonly);
         }else{
            _ctlfile1.p_readonly_mode=file1readonly;
   
            if (_ctlfile1.p_buser!='') {
               _ctlfile1.p_color_flags=_ctlfile1.p_buser;
            }
            //Now blow away undo
            _ctlfile1._DiffRemoveImaginaryLines();
            wid=p_window_id;
            _ctlfile1._DiffClearLineFlags();
            if (misc.OrigEncoding1!=-1 &&
                misc.OrigEncoding1!=_ctlfile1.p_encoding) {
               if (!p_modify) {
                  _ctlfile1.load_files(def_load_options' +d +r '_EncodingToOption(misc.OrigEncoding1)' '_ctlfile1.p_buf_name);
               }
            }
         }
      }
      if ( bufInfo2!='' ) {
         if (misc.WholeFileBufId2>=0 && _ctlfile2.p_buf_id != misc.WholeFileBufId2) {
            //Have to do this because _delete_temp_view will not delete the buffer.
            //DiffQuitView(misc.SymbolViewId2);
            if (misc.WholeFileBufId2!=misc.WholeFileBufId1) {
               //If the parent file is not the same file

               // Since we're overlaying the buffer, we have to save the original 
               // file position
               resetReadOnly(misc.WholeFileBufId2,file2inmem,file2readonly);
            }
         }else{
            _ctlfile2.p_readonly_mode=file2readonly;
            //10:55am 9/5/1997
            //If it was the same buffer this can happen
            if (_ctlfile2.p_buser!='') {
               _ctlfile2.p_color_flags=_ctlfile2.p_buser;
            }
            //Now blow away undo
            _ctlfile2._DiffRemoveImaginaryLines();
            wid=p_window_id;
            _ctlfile2._DiffClearLineFlags();
            if (misc.OrigEncoding2!=-1 &&
                misc.OrigEncoding2!=_ctlfile2.p_encoding) {
               if (!p_modify) {
                  _ctlfile2.load_files(def_load_options' +d +r '_EncodingToOption(misc.OrigEncoding2)' '_ctlfile2.p_buf_name);
               }
            }
            p_window_id=wid;
         }
      }
      // This can be a blank filename with a \ appended to it because we do that
      // so we don't confuse files with buffers.
      if ( _diffGetFilenameFromDialog(misc,'1')=="" || filename1=='\' ) {
         _kill_timer(gDiffUpdateInfo.timer_handle);
         gDiffUpdateInfo.timer_handle=-1;
         if ( isinteger(misc.DiffParentWID) && misc.DiffParentWID>0 ) {
            misc.DiffParentWID._set_focus();
         }
         break;
      }
   
      typeless File1Date='';
      typeless File2Date='';
      state := 0;
      bm1 := 0;
      BM2 := 0;
      flags := 0;
      if (misc!=null && misc.DiffParentWID!='' && _iswindow_valid(misc.DiffParentWID) &&
          misc.DiffParentWID.p_name=='_difftree_output_form' &&
          !misc.DiffParentWID.p_edit) {
         _nocheck _control tree1,tree2;
         index1 := index2 := 0;
   
         index1=misc.DiffParentWID.tree1._TreeCurIndex();
         index2=misc.DiffParentWID.tree2._TreeCurIndex();
         if (DialogIsDiff()) {
            DiffTextChangeCallback(0,_ctlfile1.p_buf_id);
            DiffTextChangeCallback(0,_ctlfile2.p_buf_id);
         }
         _UpdateFileBitmaps(filename1,index1,misc.DiffParentWID.tree1,
                            filename2,index2,misc.DiffParentWID.tree2);
         wid=p_window_id;
         p_window_id=misc.DiffParentWID;
         tree1._TreeGetInfo(index1,state,bm1,BM2,flags);
   
         tree1._set_focus();
         if (!(flags&TREENODE_HIDDEN) && def_diff_edit_flags&DIFFEDIT_AUTO_JUMP) {
            _nocheck _control ctlnext_mismatch;
            ctlnext_mismatch.call_event(ctlnext_mismatch,LBUTTON_UP);
         }
         p_window_id=wid;
         File1Date=_file_date(filename1,'B');
         File2Date=_file_date(filename2,'B');
         if (File1Date!=misc.Buf1StartTime) {
            p_window_id=misc.DiffParentWID;
            p_window_id=wid;
         }
         if (File2Date!=misc.Buf2StartTime) {
            p_window_id=misc.DiffParentWID;
            p_window_id=wid;
         }
         if (_isUnix()) {
            // force the parent windows to be displayed on top of z-order
            misc.DiffParentWID._set_foreground_window();
         }
      } else if ( misc!=null && misc.DiffParentWID!='' && _iswindow_valid(misc.DiffParentWID) &&
                  misc.DiffParentWID.p_name=='_git_repository_browser_form' &&
                  !misc.DiffParentWID.p_edit ) {
         misc.DiffParentWID._set_focus();
      }

      p_window_id=_ctlfile1;
      _deselect();
      p_window_id=_ctlfile2;
      _deselect();
      for (i=0;i<gDiffUpdateInfo.list._length();++i) {
         if (gDiffUpdateInfo.list[i].wid==fid) {
            gDiffUpdateInfo.list._deleteel(i);
            break;
         }
      }
      if (!gDiffUpdateInfo.list._length() && gDiffUpdateInfo.timer_handle>-1) {
         _kill_timer(gDiffUpdateInfo.timer_handle);
         gDiffUpdateInfo.timer_handle=-1;
      }
      if (_default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS)==SW_HIDE  &&
          p_active_form.p_visible) {
         x := y := width := height := 0;
         window_state := "";
         _DiffGetDimensionsAndState(x,y,width,height,window_state);
   
         _DiffWriteConfigInfoToIniFile("VSDiffGeometry",x,y,width,height,window_state);
      }
   
      // Clean up any stream markers used by Source Diff
      cleanupSourceDiffMarkers("diffCodeInsertedMarkerType");
      cleanupSourceDiffMarkers("diffCodeModifiedMarkerType");
      cleanupSourceDiffMarkers("diffCodeDeletedMarkerType");

      // Clean up any stream markers used by scroll markup
      cleanupScrollMarkers("diffScrollMarkupModifiedType");
      cleanupScrollMarkers("diffScrollMarkupInsertedType");
      cleanupScrollMarkers("diffScrollMarkupDeletedType");

      // Clean up book mark bitmaps
      if (wid && _iswindow_valid(wid)) {
         bookmarkMarkerType := _GetDialogInfoHt("bookmarkMarkerType",wid.p_active_form);
         if ( bookmarkMarkerType!=null ) {
            _LineMarkerRemoveAllType(bookmarkMarkerType);
         }
      }

      // Clean up markers used for alignments
      DIFF_ALIGN alignments[];
      alignments = _GetDialogInfoHt("alignments");
      len := alignments._length();
      for (i=0;i<len;++i) {
         _free_selection(alignments[i].markid1);
         _free_selection(alignments[i].markid2);
      }
      _SetDialogInfoHt("alignments",null);
      diffHandle := _GetDialogInfoHt("diffHandle",_ctlfile1);
      if (diffHandle!=null && diffHandle>=0) {
         SEDiffFreeInfo(diffHandle);
      }
      balanceHandle  := _GetDialogInfoHt("balanceHandle",_ctlfile1);
      if (balanceHandle!=null && balanceHandle>=0) {
         SEDiffFreeBalanceInfo(balanceHandle);
      }
   } while ( false );

   blastUndoInfoWID := _GetDialogInfoHt("blastUndoInfo",_ctlfile1);
   if ( blastUndoInfoWID!=null ) {
      blastUndoInfoWID._BlastUndoInfo();
   }
   diffDeleteItems();
   diffStoreUndeletedItems();

   _str bufInfo2=_GetDialogInfo(DIFFEDIT_CONST_BUFFER_INFO2,_ctlfile1);
   if ( bufInfo2!=null ) {
      parse bufInfo2 with auto bufID2 auto file2inmem auto file2readonly;
      // The whole/orig buffer for source diff isn't deleted in the list.  We 
      // have to keep the buffer open while we're toggling.  If file 2 was already
      // in memory, we can't close it now, the temp buffer will be closed by
      // diffDeleteItems. 
      //  
      // If we are doing backup history diff or svc_history_diff there 
      // is no parent buffer, so misc.WholeFileBufId2 can be -1. 

#if 0 //11:34am 12/4/2019
      if ( misc.WholeFileBufId2>0 && (misc.closeBuffer2 && inTypeToggle!=1) ) {
         origWID := p_window_id;
         p_window_id = HIDDEN_WINDOW_ID;
         _safe_hidden_window();
         origBufID := p_buf_id;
         status := load_files('+bi 'misc.WholeFileBufId2);
         say('_ctlfile1.on_destroy 10 trying to delete buffer misc.WholeFileBufId2='misc.WholeFileBufId2' status='status);
         if (!status) {
            _delete_buffer();
         }
         say('_ctlfile1.on_destroy 20 origBufID='origBufID);
         status = load_files('+bi 'origBufID);
         say('_ctlfile1.on_destroy 30 load_files status='status);
         p_window_id = origWID;
      }
#endif
   }

   vscroll1._ScrollMarkupUnassociateEditor(_ctlfile1);

   if (_isMac()) {
      if(_default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS) == SW_HIDE
         && misc.DiffParentWID==0) {
          exit(0);
      }
   }
}
void _DiffGetDimensionsAndState(int &DialogX,int &DialogY,int &DialogWidth,int &DialogHeight,
                                 _str &WindowState='')
{
   WindowState=p_active_form.p_window_state;
   if ( WindowState=='M' ) {
      // Have to change the state back so that we can get the info for the
      // normalized dialog
      p_active_form.p_window_state='N';
   }
   DialogX=_lx2dx(SM_TWIP,p_active_form.p_x);
   DialogY=_ly2dy(SM_TWIP,p_active_form.p_y);
   DialogWidth=_lx2dx(SM_TWIP,p_active_form.p_width);
   DialogHeight=_ly2dy(SM_TWIP,p_active_form.p_height);

}

void _DiffSetupHorizontalScrollBar()
{
   longestline1 := _ctlfile1._find_longest_line();
   longestline2 := _ctlfile2._find_longest_line();
   if (!_ctlfile1.p_fixed_font || _ctlfile1.p_UTF8) {
      longestline1=_lx2dx(SM_TWIP,longestline1);
      longestline2=_lx2dx(SM_TWIP,longestline2);
   }else{
      // We want the horizontal scroll bar to scroll the longest line in the 
      // file to the right edge of the screen.  So start with the width of the 
      // longest line, and subtract the width of the buffer plus the width of
      // one character.
      longestline1=(longestline1-(_dx2lx(SM_TWIP,_ctlfile1.p_client_width)-_ctlfile1._text_width("W"))) intdiv _ctlfile1._text_width("W");
      longestline2=(longestline2-(_dx2lx(SM_TWIP,_ctlfile2.p_client_width)-_ctlfile2._text_width("W"))) intdiv _ctlfile2._text_width("W");
   }
   hscroll1.p_max=max(longestline1,longestline2);
   hscroll1.p_min=0;
   if (_ctlfile1.p_fixed_font) {
      hscroll1.p_large_change=_ctlfile1.p_char_height-1;
   }else{
      hscroll1.p_large_change=_dx2lx(SM_TWIP,_ctlfile1.p_client_width);
   }
   SetHScrollFlag(p_active_form,false);
}

void vscroll1.on_change(int reason=0,long seekPos=0)
{
   if ( reason==CHANGE_SCROLL_MARKER_CLICKED ) {
      // User clicked a scroll marker for a difference
      diff_seek(seekPos);
      return ;
   }
   if (p_object==OI_VSCROLL_BAR) {
      int last_vscroll=_DiffVscrollGetLast();

      if (last_vscroll==null || last_vscroll=='') return;

      wid := p_window_id;
      if (vscroll1.p_value<last_vscroll) {
         p_window_id=_ctlfile1;
         _scroll_page('u',last_vscroll-vscroll1.p_value);
         p_window_id=_ctlfile2;
         _scroll_page('u',last_vscroll-vscroll1.p_value);
      }else if (vscroll1.p_value>last_vscroll) {
         p_window_id=_ctlfile1;
         _scroll_page('d',vscroll1.p_value-last_vscroll);
         p_window_id=_ctlfile2;
         _scroll_page('d',vscroll1.p_value-last_vscroll);
      }
      p_window_id=wid;
      _DiffVscrollSetLast(p_value);
   }else if (p_object==OI_HSCROLL_BAR) {
      if (_DiffHscrollGetLast()=='') return;
      _ctlfile1.p_scroll_left_edge=hscroll1.p_value;
      _ctlfile2.p_scroll_left_edge=hscroll1.p_value;
   }
}
vscroll1.on_scroll()
{
   if (p_object==OI_VSCROLL_BAR) {
      int last_vscroll=_DiffVscrollGetLast();

      if (last_vscroll==null || last_vscroll=='') return('');//Cursor moved

      if (vscroll1.p_value<last_vscroll) {
         //Should scroll up
         p_window_id=_ctlfile1;
         _scroll_page('u',last_vscroll-vscroll1.p_value);
         p_window_id=_ctlfile2;
         _scroll_page('u',last_vscroll-vscroll1.p_value);
      }else if (vscroll1.p_value>last_vscroll) {
         //Should scroll down
         p_window_id=_ctlfile1;
         _scroll_page('d',vscroll1.p_value-last_vscroll);
         p_window_id=_ctlfile2;
         _scroll_page('d',vscroll1.p_value-last_vscroll);
      }
      _DiffVscrollSetLast(vscroll1.p_value);
   }else if (p_object==OI_HSCROLL_BAR) {
      if (_DiffHscrollGetLast()=='') return('');//Cursor moved
      _ctlfile1.p_scroll_left_edge=hscroll1.p_value;
      _ctlfile2.p_scroll_left_edge=hscroll1.p_value;
      _DiffHscrollSetLast(hscroll1.p_value);
   }
   p_active_form.refresh();
}

// Making non static for wayback machine use
void _DiffUpdateScrollThumbs(bool updateImmediately=false)
{
   static int numbehind;
   if ( !updateImmediately ) {
      if (numbehind < 50) {
         ++numbehind;
         return;
      }
   }
   numbehind=0;
   _DiffVscrollSetLast('');
   int YInLines=_ctlfile1.p_cursor_y intdiv _ly2dy(SM_TWIP,_ctlfile1._text_height());
   vscroll1.p_value=_ctlfile1.p_line-YInLines;
   _DiffVscrollSetLast(_ctlfile1.p_line-YInLines);
   vscroll1.refresh();
}
static void change_edit_window()
{
   if (_get_focus()==_ctlfile1) {
      _ctlfile2._set_focus();
   }else if (_get_focus()==_ctlfile2) {
      _ctlfile1._set_focus();
   }
   p_active_form.refresh();
}


#if 0
_ctlfile1.TAB()
{
   p_window_id=_ctlfile2;
   _set_focus();
}

_ctlfile2.TAB()
{
   p_window_id=_ctlfile1;
   _set_focus();
}
#endif

static int _dont_use_diff_command=0;

static _str DiffMessageBox(_str msg, int mb_flags=MB_OK|MB_ICONEXCLAMATION,int default_button=0)
{
   //refresh();
   return _message_box(nls("%s",msg),"SlickEdit",mb_flags,default_button);
}

static int FindButtonWithShortcut(_str key)
{
   val := (arg(1)!='');
   p_enabled=val;
   wid := p_window_id;
   while (p_child) {
      p_window_id=p_child;
      firstwid := p_window_id;
      for (;;) {
         p_window_id=p_next;
         if (p_object==OI_COMMAND_BUTTON) {
            if (pos('&'key,p_caption,1,'i')) {
               rv := p_window_id;
               p_window_id=wid;
               return(rv);
            }
         }
         if (p_window_id==firstwid) break;
      }
   }
   p_window_id=wid;
   return(0);
}

static void _EditControlEventHandler()
{
   typeless lastevent=last_event();
   _str eventname=event2name(lastevent);
   //messageNwait("_EditControlEventHandler: eventname="eventname" _select_type()="_select_type());
   if (eventname=='F1') {
      p_active_form.call_event(defeventtab _ainh_dlg_manager,F1,'e');
      return;
      //help('Diff Dialog box');
   }
   if (eventname=='A-F4' || eventname=='ESC') {
      diff_close_form();
      return;
   }
   if (eventname=='MOUSE-MOVE') {
      return;
   }
   if (eventname=='RBUTTON-DOWN') {
      edit_window_rbutton_up();
      return;
   }
   if (eventname=='C-S-LBUTTON-DOWN') {
      diff_mou_click();
      return;
   }
   wid := 0;
   if (substr(eventname,1,2)=='A-') {
      //If we're in an edit control, we still want the buttons to work
      wid=p_active_form.FindButtonWithShortcut(substr(eventname,3));
      if (wid) {
         wid.call_event(wid,lastevent);
         return;
      }
   }
   fid := p_active_form;
   typeless junk='';
   int key_index=event2index(lastevent);
   name_index := eventtab_index(_default_keys,_ctlfile1.p_mode_eventtab,key_index);
   command_name := name_name(name_index);

   diffMode_index := _eventtab_get_mode_keys('diff_keys');
   if ( diffMode_index ) {
      diffMode_name_index:=eventtab_index(diffMode_index,diffMode_index,key_index);
      if ( diffMode_name_index ) {
         command_name=name_name(diffMode_name_index);
      }
   }

   //This is to handle C-X combinations
   if (name_type(name_index)==EVENTTAB_TYPE) {
      int eventtab_index2=name_index;
      typeless event2=get_event('k');
      key_index=event2index(event2);
      name_index=eventtab_index(eventtab_index2,eventtab_index2,key_index);
      command_name=name_name(name_index);
   }
   //oldevent=last_event();_message_box("h1");last_event(oldevent);
   //messageNwait("_EditControlEventHandler: name="command_name);
   //DiffMessage('command_name='command_name);
   UsingMerge := !DialogIsDiff();
   if (!_dont_use_diff_command) {
      //messageNwait("h2 _EditControlEventHandler: eventname="eventname" _select_type()="_select_type()" command_name="command_name);
      if (DiffCommands._indexin(command_name)) {
         if ( !_haveProDiff() && !DiffCommands:[command_name].supportedInStandardEdition ) {
            message(get_message(VSRC_FEATURE_REQUIRES_PRO_EDITION));
            return;
         }
         if ( DiffEditorIsReadOnly()  ) {
            CMDUI cmdui;
            cmdui.menu_handle=0;
            cmdui.menu_pos=0;
            cmdui.inMenuBar=false;
            cmdui.button_wid=1;

            _OnUpdateInit(cmdui,p_window_id);

            cmdui.button_wid=0;

            int mfflags=_OnUpdate(cmdui,p_window_id,command_name);

            if (!mfflags || (mfflags&MF_ENABLED)) {
               //Command is allowed, everything is cool.
            }else{
               //Command is not allowed, so beep at user and return
               _beep();
               if ( p_window_id==_ctlfile2 ) {
                  if ( maybeSwitchToLineDiff() ) {
                     return;
                  }else{
                     _message_box(nls("Command not allowed in Read Only mode"));
                  }
               }else{
                  _message_box(nls("Command not allowed in Read Only mode"));
               }
               return;
            }
         }
         int OldFlags=_lineflags();
         OrigLine := p_line;
         old_drag_drop := def_dragdrop;
         def_dragdrop=false;
         switch (DiffCommands:[command_name].typelessCommand._varformat()) {
         case VF_FUNPTR:
            if (pos('\-space$',command_name,1,'r')) {
               if ( !DiffEditorIsReadOnly() ) {
                  diff_mode_space();
               }
            }else if (pos('\-enter$',command_name,1,'r') ||
                      pos('\-insert-line',command_name,1,'r')
                      ) {
               if ( !DiffEditorIsReadOnly() ) {
                  _str old_keys=def_keys;
                  def_keys='windows-keys';
                  root_binding_index := 0;
                  int event_index=event2index(last_event());
                  index_used := eventtab_index(_default_keys,p_mode_eventtab,event_index,'U');
                  orig_modify := false;
                  if (index_used==p_mode_eventtab) {
                     //There is a mode binding
                     index_used=eventtab_index(_default_keys,p_mode_eventtab,event_index);
                     //Get root binding
                     root_binding_index=eventtab_index(_default_keys,_default_keys,event_index);
                     orig_modify=_eventtab_get_modify(_default_keys);
                     set_eventtab_index(_default_keys,event_index,find_index('split-insert-line',COMMAND_TYPE));

                  }
                  //set_eventtab_index(keytab_used,keyindex,command_index);
                  diff_mode_split_insert_line();
                  if (index_used==p_mode_eventtab) {
                     set_eventtab_index(_default_keys,event_index,root_binding_index);
                     _eventtab_set_modify(_default_keys,orig_modify);
                  }
                  def_keys=old_keys;
               }
            }else{
               typeless status=(*DiffCommands:[command_name].typelessCommand)();
               if (command_name=='quit' && status!=COMMAND_CANCELLED_RC) {
                  def_dragdrop=old_drag_drop;
                  return;
               }
               if (
                   (command_name=='fast-scroll') ||
                   (command_name=='scroll-page-down') ||
                   (command_name=='scroll-page-up') ) {
                  def_dragdrop=old_drag_drop;
                  return;
               }
            }
            break;
         case VF_ARRAY:
            junk=(*DiffCommands:[command_name].typelessCommand[0])(DiffCommands:[command_name].typelessCommand[1]);
            break;
         }
         def_dragdrop=old_drag_drop;
      #if 0
      else if (DiffCloseAndRunCommands._indexin(command_name)) {
         if (diff_close_and_run_command(command_name)) {
            return;
         }
      }
      #endif
      } else{
         if (command_name=='') {
            // This could be an unbound num-pad key.  Num pad keys have different 
            // names, and are handled by _diff_docharkey
            _diff_docharkey();
            return;
         }
         if (!DiffEditorIsReadOnly() && pos('\-space$',command_name,1,'r')) {
            if (command_name=='ext-space') {
               diff_ext_space();
            }else{
               diff_mode_space();
            }
         }else if (!DiffEditorIsReadOnly() && pos('\-enter$',command_name,1,'r')) {
            diff_mode_split_insert_line();
         }else if (!DiffEditorIsReadOnly() && pos('maybe-case-backspace$',command_name,1,'r')) {
            diff_maybe_case_backspace(command_name);
         }else if (!DiffEditorIsReadOnly() && pos('\-backspace$',command_name,1,'r')) {
            diff_rubout();
         }else if (command_name=="auto-codehelp-key" ||
                   command_name=="auto-functionhelp-key") {
            _diff_docharkey();
         }else{
            // make sure that this really is a command, and not a stray event
            command_index := find_index(command_name, COMMAND_TYPE);
            eventtb_index := find_index(command_name, EVENTTAB_TYPE);
            if (!command_index && eventtb_index) {
               return;
            }
            DiffMessageBox(nls("Command '%s' is not allowed in Diff mode",command_name));
         }
      }
      //messageNwait("h3 _EditControlEventHandler: eventname="eventname" _select_type()="_select_type());
   }else{
      index := find_index(command_name,COMMAND_TYPE);
      if (index && index_callable(index)) {
         call_index(index);
      }
   }

   // 3:04:05 PM 3/1/2010 
   // It is possible that the keyboard command that was run above has actually 
   // caused the dialog to close, check to see if the window is still there.
   windowStillExists := false;
   for (i:=0;i<gDiffUpdateInfo.list._length();++i) {
      if (gDiffUpdateInfo.list[i].wid==fid) {
         windowStillExists = true;
         break;
      }
   }
   if ( !windowStillExists ) return;
   _ctlfile1.p_scroll_left_edge=-1;
   _ctlfile2.p_scroll_left_edge=-1;
   otherwid := GetOtherWid(wid);
   int wid_sle=p_scroll_left_edge;
   p_window_id=otherwid;
   p_scroll_left_edge=wid_sle;
   p_window_id=wid;//Yuck!!!!!!!!! I don't know if this really is the best
   //way to do this, but it keeps both cursors in view

   //_diffedit_UpdateForm(_ctlfile1.p_line);
   //_post_call(_diffedit_UpdateForm,_ctlfile1.p_line);
   _DiffSetNeedRefresh(true);
}

_ctlfile1.on_lost_focus()
{
   LastActiveEditWindowWID=_ctlfile1;
}

_ctlfile2.on_lost_focus()
{
   LastActiveEditWindowWID=_ctlfile2;
}

static void ScrollDown(int Noflines)
{
   int last_vscroll=_DiffVscrollGetLast();

   if (last_vscroll+Noflines>vscroll1.p_max) {
      Noflines=vscroll1.p_max-last_vscroll;
   }
   //Should scroll down
   p_window_id=_ctlfile1;
   _scroll_page('d',Noflines);
   p_window_id=_ctlfile2;
   _scroll_page('d',Noflines);

   int newval=last_vscroll+Noflines;
   _DiffVscrollSetLast(newval);
   vscroll1.p_value=newval;
}
static void ScrollUp(int Noflines)
{
   int last_vscroll=_DiffVscrollGetLast();

   if (last_vscroll-Noflines<vscroll1.p_min) {
      Noflines=last_vscroll-vscroll1.p_min;
   }
   //Should scroll down
   p_window_id=_ctlfile1;
   _scroll_page('u',Noflines);
   p_window_id=_ctlfile2;
   _scroll_page('u',Noflines);

   int newval=last_vscroll-Noflines;
   _DiffVscrollSetLast(newval);
   vscroll1.p_value=newval;
}
void _ctlfile1.on_vsb_line_down()
{
   p_window_id.ScrollDown(1);
}
void _ctlfile2.on_vsb_line_down()
{
   p_window_id.ScrollDown(1);
}
void _ctlfile1.on_vsb_line_up()
{
   p_window_id.ScrollUp(1);
}
void _ctlfile2.on_vsb_line_up()
{
   p_window_id.ScrollUp(1);
}
//Not sure about portablity

//defeventtab _diff_form.ctlfile1;
//_ctlfile1.\0-\32,\129-MBUTTON_UP,'S-LBUTTON-DOWN'-ON_SELECT()
_ctlfile1.'range-first-nonchar-key'-'all-range-last-nonchar-key',' ', 'range-first-mouse-event'-'all-range-last-mouse-event',ON_SELECT()
{
   _EditControlEventHandler();
}

//Not sure about portability
//_ctlfile2.\0-\33,\129-ON_SELECT()
//_ctlfile2.\0-\32,\129-MBUTTON_UP,'S-LBUTTON-DOWN'-ON_SELECT()
_ctlfile2.'range-first-nonchar-key'-'all-range-last-nonchar-key',' ', 'range-first-mouse-event'-'all-range-last-mouse-event',ON_SELECT()
{
   _EditControlEventHandler();
}

static void MaybeMakeLineReal()
{
   if (!(_lineflags()&NOSAVE_LF)) {
      return;
   }
   _lineflags(0,NOSAVE_LF);
   int lineflags=_lineflags();
   line := "";
   get_line(line);
   if (!DialogIsDiff()) {
      _lineflags(0,~lineflags);
      _lineflags(lineflags,lineflags);
   }
   if (line=="Imaginary Buffer Line") {
      safe_replace_line('');
   }
}

void _maybe_case_word(bool autocase,_str &gWord,int &gWordEndOffset);

static int gWordEndOffset=-1;
static _str gWord;

static void diff_maybe_case_backspace(_str cmdname)
{
   if (OnImaginaryLine()) {
      return;
   }
   if (select_active() && _within_char_selection()) {
      //DiffMessage('Mark deletes not yet available');
      diff_linewrap_delete_char('delete-selection');
      return;
   }
   wasCol1 := p_col==1;
   wid := 0;
   otherwid := p_window_id.GetOtherWid(wid);
   wid._undo('S');
   otherwid._undo('S');


   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);

   autoCase := LanguageSettings.getAutoCaseKeywords(p_LangId);

   _maybe_case_backspace(autoCase,gWord,gWordEndOffset);

   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
   commandindex := find_index(cmdname,COMMAND_TYPE);
   prev_index(commandindex,'C');

   if (wasCol1) {
      save_pos(auto p);
      wid.DiffInsertImaginaryBufferLine();
      restore_pos(p);
      otherwid.p_line = wid.p_line;
      otherwid.p_col = wid.p_col;
   } else {
      otherwid.left();
   }
   AddUndoNothing(otherwid);

   _DiffSetNeedRefresh(true);
}

static void diff_maybe_case_word(_str cmdname)
{
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);

   autoCase := LanguageSettings.getAutoCaseKeywords(p_LangId);

   _maybe_case_word(autoCase,gWord,gWordEndOffset);

   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }


   commandindex := find_index(cmdname,COMMAND_TYPE);
   prev_index(commandindex,'C');
}

static void diff_xml_slash()
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   old_num_lines := p_Noflines;
   old_linenum := p_line;
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   xml_slash();
   AddUndoNothing(otherwid);
}

static void diff_html_lt()
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   old_num_lines := p_Noflines;
   old_linenum := p_line;
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   html_lt();
   AddUndoNothing(otherwid);
}

static void diff_html_gt()
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   old_num_lines := p_Noflines;
   old_linenum := p_line;
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   html_gt();
   AddUndoNothing(otherwid);
}

static void diff_ext_space()
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   old_num_lines := p_Noflines;
   old_linenum := p_line;
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   ext_space();
   if (wid.p_Noflines>old_num_lines) {
      int i,origwid=p_window_id;
      p_window_id=otherwid;
      p_line=old_linenum;
      for (i=1;i<=wid.p_Noflines-old_num_lines;++i) {
         //DiffInsertColorInfo(p_buf_id,p_line);
         //InsertImaginaryLine();
         DiffInsertImaginaryBufferLine();
      }
      p_window_id=origwid;
   }
   AddUndoNothing(otherwid);
}

static void diff_html_key()
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   old_num_lines := p_Noflines;
   old_linenum := p_line;
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   html_key();
   if (wid.p_Noflines>old_num_lines) {
      int i,origwid=p_window_id;
      p_window_id=otherwid;
      p_line=old_linenum;
      for (i=0;i<wid.p_Noflines-old_num_lines;++i) {
         //DiffInsertColorInfo(p_buf_id,p_line);
         //InsertImaginaryLine();
         DiffInsertImaginaryBufferLine();
      }
      p_window_id=origwid;
   }
   AddUndoNothing(otherwid);
}

static void diff_lang_key(_str Language)
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   old_num_lines := p_Noflines;
   old_linenum := p_line;
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   //html_key();
   index := find_index(Language'-key',COMMAND_TYPE);
   if (index && index_callable(index)) {
      call_index(index);
      if (wid.p_Noflines>old_num_lines) {
         int i,origwid=p_window_id;
         p_window_id=otherwid;
         p_line=old_linenum;
         for (i=1;i<wid.p_Noflines-old_num_lines;++i) {
            DiffInsertImaginaryBufferLine();
         }
         p_window_id=origwid;
      }
      AddUndoNothing(otherwid);
   }
}

static void _diff_docharkey()
{
   if ( !_haveProDiff() ) {
      message(get_message(VSRC_FEATURE_REQUIRES_PRO_EDITION));
      return;
   }
   _str key=last_event();
   _str eventName=event2name(key);
   _str cmdname=name_name(eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(key)));
   switch (cmdname) {
   case 'c-endbrace':
      c_endbrace();
      return;
   case 'auto-codehelp-key':
   case 'java-auto-codehelp-key':
      diff_auto_codehelp_key();
      return;
   case 'java-auto-functionhelp-key':
   case 'auto-functionhelp-key':
      diff_auto_functionhelp_key();
      return;
   case 'html-key':
      diff_html_key();
      return;
   case 'perl-key':
      diff_lang_key('perl');
      return;
   case 'ext-space':
      diff_ext_space();
      return;
   case 'xml-slash':
      diff_xml_slash();
      return;
   case 'html-lt':
      diff_html_lt();
      return;
   case 'html-gt':
      diff_html_gt();
      return;
   default:
      if (pos('maybe-case-word$',cmdname,1,'r')) {
         diff_maybe_case_word(cmdname);
         return;
      }else if ( pos('^PAD-',eventName,1,'R') ) {
         DiffPadChar(eventName,key);
      }else{
         // 6/19/2007 - rb,cm
         // Could probably use either isprint() or isnormal_char(), but less
         // is better in this case we think.
         if( isprint(key) ) {
            keyin(key);
         }
      }
      return;
   }
}

static void DiffPadChar(_str eventName,_str key)
{
   wid := p_window_id;
   otherwid := GetOtherWid(wid);
   p_window_id=wid;

   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   switch (eventName) {
   case 'PAD-STAR':
      keyin('*');
      break;
   case 'PAD-SLASH':
      keyin('/');
      break;
   case 'PAD-MINUS':
      keyin('-');
      break;
   case 'PAD-PLUS':
      keyin('+');
      break;
   default:
      keyval := key2ascii(key);
      if (keyval!="") {
         _ctlfile1._undo('S');
         _ctlfile2._undo('S');
         keyin(keyval);
         otherwid.right();
         AddUndoNothing(otherwid);
      }
   }
   otherwid.right();
   AddUndoNothing(otherwid);
}

//_ctlfile1.'a'-'z','A'-'Z','0-9',',',"'",'"','?','/','.','<','>'()
int _ctlfile1.\33-'range-last-char-key'()
{
   if ( !_haveProDiff() ) return 0;
   if ( DiffEditorIsReadOnly() ) {
      _message_box(nls("Command not allowed in Read Only mode"));
      return(1);
   }
   if (_GetDialogInfoHt("lastWasDiffCommand")==1) {
      _SetDialogInfoHt("lastWasDiffCommand",0);
      _ctlfile1._undo('S');
      _ctlfile2._undo('S');
      AddUndoNothing(_ctlfile2);
   }
   MaybeMakeLineReal();
   if ((!select_active() ||
       ( _select_type('','U')=='P' && _select_type('','S')=='E' ))
       ) {
      //!_within_char_selection keeps us from deleting selections created
      //by word completion
      _diff_docharkey();
      _ctlfile2.right();
      AddUndoNothing(_ctlfile2);
   }else{
      if (!_within_char_selection() ) {
         deselect();
         _diff_docharkey();
         _ctlfile2.right();
         AddUndoNothing(_ctlfile2);
      } else {
         diff_multi_delete();
      }
   }
   _DiffSetNeedRefresh(true);
   // 8:34:27 PM 2/19/2002
   // This code is not quite fast enough to keep, but I do
   // not want to lose it right now
   //SetHScrollFlag(p_active_form);
   return(0);
}

//_ctlfile2.'a'-'z','A'-'Z'()
int _ctlfile2.\33-'range-last-char-key'()
{
   if ( !_haveProDiff() ) return 0;
   if ( DiffEditorIsReadOnly() ) {
      if ( maybeSwitchToLineDiff() ) {
         return 0;
      }else{
         _message_box(nls("Command not allowed in Read Only mode"));
      }
      return(1);
   }
   MaybeMakeLineReal();
   int lineflags=_lineflags();
   if (!select_active() ||
       ( _select_type('','U')=='P' && _select_type('','S')=='E' )) {
      _diff_docharkey();
      _ctlfile1.right();
      AddUndoNothing(_ctlfile1);//This had _ctlfile2, but I think it was wrong
   }else{
      if (!_within_char_selection() ) {
         deselect();
         _diff_docharkey();
         _ctlfile1.right();
         AddUndoNothing(_ctlfile1);
      } else {
         diff_multi_delete();
      }
   }
   if (!DialogIsDiff()) {
      _lineflags(0,~lineflags);
      _lineflags(lineflags,lineflags);
      lineflags=_lineflags();
   }
   _DiffSetNeedRefresh(true);
   return(0);
}

_control _ctlnext_difference;
_control _ctlprev_difference;

_ctlfile1.C_F6()
{
   if ( _DiffGetNextDiffMissing()!=1 ) {
      call_event(_ctlnext_difference,LBUTTON_UP);
   }
}

_ctlfile2.C_F6()
{
   if ( _DiffGetNextDiffMissing()!=1 ) {
      call_event(_ctlnext_difference,LBUTTON_UP);
   }
}

_ctlfile1.'C-S-F6'()
{
   if ( _DiffGetNextDiffMissing()!=1 ) {
      call_event(_ctlprev_difference,LBUTTON_UP);
   }
}

_ctlfile2.'C-S-F6'()
{
   if ( _DiffGetNextDiffMissing()!=1 ) {
      call_event(_ctlprev_difference,LBUTTON_UP);
   }
}

_ctlfile1.'C-tab'()
{
   diff_next_window();
}

_ctlfile2.'C-tab'()
{
   diff_next_window();
}


_ctlfile1.'C-S-tab'()
{
   diff_next_window(true);
}

_ctlfile2.'C-S-tab'()
{
   diff_next_window(true);
}

static bool OnLastLine()
{
   //I wanted this to be a define, but there were problems with calling it
   //ex:  wid.OnLastLine()
   return(p_line==p_Noflines);
}


void _diff_form.on_got_focus()
{
   _ctlfile1.hex_off();
   _ctlfile2.hex_off();
   _ctlfile1._diff_show_all();
   _ctlfile2._diff_show_all();
   SetLineLabelWidths();
}

static void GetVisibleControlList(_str &widlist)
{
   p_window_id=p_active_form;
   int wid=p_child;
   int first=wid;
   widlist='';
   for (;;) {
      if (wid.p_visible) {
         if (widlist=='') {
            widlist=wid;
         }else{
            widlist :+= ' 'wid;
         }
      }
      wid=wid.p_next;
      if (wid==first) break;
   }
}

static void SetListVisibleProperty(_str widlist,int value)
{
   cur := "";
   for (;;) {
      parse widlist with cur widlist;
      if (cur=='') break;
      cur.p_visible=value!=0;
   }
}


static int ResizeWithButtonsAtTop(int availablespace,bool tworows)
{
   int client_width=_dx2lx(SM_TWIP,p_active_form.p_client_width);
   int border_width=p_active_form.p_width-client_width;

   int xbuffer=_ctlfile1.p_x;

   _ctlfile2.p_width=_ctlfile1.p_width=(availablespace-vscroll1.p_width) intdiv 2;
   vscroll1.p_x=(_ctlfile1.p_x_extent)-_twips_per_pixel_x();
   _ctlfile2.p_x=vscroll1.p_x_extent-_twips_per_pixel_x();
   hscroll1.p_width=(_ctlfile2.p_x_extent-_ctlfile1.p_x)/*-_twips_per_pixel_x()*/;


   int buttonHeight=_ctlcopy_right.p_height+xbuffer/*+_ctlseparater.p_height*/;
   if (tworows) {
      buttonHeight*=2;
   }

   int buttonBuffer=_ctlcopy_right_line.p_x-(_ctlcopy_right.p_x_extent);

   int client_height=_dy2ly(SM_TWIP,p_active_form.p_client_height);

   _ctlfile1.p_height=client_height-(hscroll1.p_height+_ctlfile2_readonly.p_height+_ctlfile1.p_y+(3*xbuffer));
   _ctlseparater.p_width=p_active_form.p_width;
   _ctlfile2.p_height=_ctlfile1.p_height;
   _ctlfile2_readonly.p_y=_ctlfile1_readonly.p_y=_ctlfile1.p_y_extent+hscroll1.p_height+xbuffer;

   vscroll1.p_height=_ctlfile2.p_height;
   hscroll1.p_y=(_ctlfile1.p_y_extent)-_twips_per_pixel_y();

   _ctlfile2_readonly.p_x=_ctlfile2.p_x;
   ctlbuffered_label.p_y=_ctlmodified_label.p_y=_ctlinserted_label.p_y=_ctlimaginary_label.p_y=ctlconflictindicator.p_y=_ctlfile1_readonly.p_y;
   _ctlfile1line.p_y=_ctlfile1_readonly.p_y;


   PlaceBottomRowButtons(xbuffer,true);
   _ctlseparater.p_y=_ctlclose.p_y_extent+xbuffer;

   int secondRowY=_ctlseparater.p_y_extent+xbuffer;

   _ctlcopy_right.p_y=_ctlcopy_right_line.p_y=_ctlcopy_right_all.p_y=_ctlfile1save.p_y=\
      _ctlcopy_left.p_y=_ctlcopy_left_line.p_y=_ctlcopy_left_all.p_y=_ctlfile2save.p_y=secondRowY;

   _ctlfile2label.p_x=_ctlfile2.p_x;


   _ctlcopy_left.p_x=_ctlfile2.p_x;
   _ctlcopy_left_line.p_x=_ctlcopy_left.p_x_extent+buttonBuffer;

   _ctlcopy_left_all.p_x=_ctlcopy_left_line.p_x_extent+buttonBuffer;
   _ctlfile2save.p_x=_ctlcopy_left_all.p_x_extent+buttonBuffer;

   _ctlfile1label.p_y=_ctlfile2label.p_y=buttonHeight+xbuffer+xbuffer;
   ctlcontextCombo1.p_y = ctlcontextCombo2.p_y = _ctlfile1label.p_y_extent+xbuffer;
   ctlcontextCombo1.p_width = ctlcontextCombo2.p_width = _ctlfile1.p_width;
   ctlcontextCombo2.p_x = _ctlfile2.p_x;

   if (_haveCurrentContextToolBar() && !(def_diff_edit_flags&DIFFEDIT_HIDE_CURRENT_CONTEXT)) {
      _ctlfile1.p_y=_ctlfile2.p_y=ctlcontextCombo1.p_y_extent + xbuffer;
   } else {
      _ctlfile1.p_y=_ctlfile2.p_y=ctlcontextCombo1.p_y;
   }

   vscroll1.p_y=_ctlfile1.p_y;
   hscroll1.p_y=(_ctlfile1.p_y_extent)-_twips_per_pixel_y();
   return(0);
}

static const FILE_LABEL_Y= 180;

static void resizeMiddleDialog(int xbuffer, bool tworows)
{
   _ctlfile2.p_height=_ctlfile1.p_height;
   vscroll1.p_height=_ctlfile2.p_height;
   hscroll1.p_y=(_ctlfile1.p_y_extent)-_twips_per_pixel_y();
   _ctlclose.p_x=_ctlfile1.p_x;

   _ctlfile1_readonly.p_y=_ctlfile1.p_y_extent+hscroll1.p_height+xbuffer;
   _ctlfile2_readonly.p_y=_ctlfile1.p_y_extent+hscroll1.p_height+xbuffer;
   _ctlfile2_readonly.p_x=_ctlfile2.p_x;
   if (tworows) {
      ctlbuffered_label.p_y=_ctlmodified_label.p_y=_ctlinserted_label.p_y=_ctlimaginary_label.p_y=ctlconflictindicator.p_y=_ctlfile1_readonly.p_y_extent+xbuffer;
   }else{
      ctlbuffered_label.p_y=_ctlmodified_label.p_y=_ctlinserted_label.p_y=_ctlimaginary_label.p_y=ctlconflictindicator.p_y=_ctlfile1_readonly.p_y;
   }
   _ctlfile1line.p_y=_ctlfile1_readonly.p_y;


   _ctlcopy_right.p_y=_ctlmodified_label.p_y_extent+xbuffer;

   _ctlcopy_right.p_x=_ctlfile1.p_x;_ctlcopy_left.p_x=_ctlfile2.p_x;
   _ctlcopy_right_line.p_x=_ctlcopy_right.p_x_extent+xbuffer;
   _ctlcopy_right_all.p_x=_ctlcopy_right_line.p_x_extent+xbuffer;
   _ctlcopy_right_line.p_y=_ctlcopy_right_all.p_y=_ctlfile2save.p_y=_ctlcopy_right.p_y;
   _ctlfile1save.p_x=_ctlcopy_right_all.p_x_extent+xbuffer;
   _ctlfile1save.p_y=_ctlcopy_right_all.p_y;
   _ctlcopy_left_line.p_y=_ctlcopy_left_all.p_y=_ctlfile1save.p_y;
   _ctlcopy_left_line.p_x=_ctlcopy_left.p_x_extent+xbuffer;
   _ctlcopy_left_all.p_x=_ctlcopy_left_line.p_x_extent+xbuffer;
   _ctlfile2save.p_x=_ctlcopy_left_all.p_x_extent+xbuffer;

   _ctlcopy_left.p_y=_ctlcopy_right.p_y;
}

void _diff_form.on_resize()
{
   static int in_on_resize;
   if (in_on_resize) return;
   in_on_resize=1;
   typeless width='';
   typeless height='';
   _str FormSize=_GetDialogInfo(DIFFEDIT_CONST_FORM_SIZE);
   if (FormSize!=null) {
      parse FormSize with width height .;
      if (width==p_active_form.p_width && height==p_active_form.p_height &&
         arg(1)!='F' &&!(def_diff_edit_flags&DIFFEDIT_BUTTONS_AT_TOP)) {
         in_on_resize=0;
         return;
      }
   }

   // make sure we enforce a minimum size - all the buttons should be visible
   minWidth := ctltypetoggle.p_x_extent;
   if ( p_active_form.p_width < minWidth ) {
      p_active_form.p_width = minWidth;
   }

   int xbuffer=_ctlfile1.p_x;

   widlist := "";
   GetVisibleControlList(widlist);
   tworows := true;
   SetListVisibleProperty(widlist,0);

   int availablespace=p_active_form.p_width-(xbuffer*2);

   typeless status=0;
   if ((def_diff_edit_flags&DIFFEDIT_BUTTONS_AT_TOP) && tworows) {
      status=ResizeWithButtonsAtTop(availablespace,tworows);
      SetListVisibleProperty(widlist,1);
      FormSize=p_active_form.p_width' 'p_active_form.p_height;
      _SetDialogInfo(DIFFEDIT_CONST_FORM_SIZE,FormSize);

      p1 := 1;
      vscroll1.p_max=_ctlfile1.p_Noflines-_ctlfile1.p_char_height;

      SetLineLabelWidths();
      SetHScrollFlag(p_active_form);
      MaybeHide(_ctlimaginary_label);
      MaybeHide(_ctlmodified_label);
      MaybeHide(_ctlinserted_label);
      in_on_resize=0;
      return;
   }
   _ctlfile1label.p_y=_ctlfile2label.p_y=FILE_LABEL_Y;
   if (_haveCurrentContextToolBar() && !(def_diff_edit_flags&DIFFEDIT_HIDE_CURRENT_CONTEXT)) {
      _ctlfile1.p_y=_ctlfile2.p_y=ctlcontextCombo1.p_y_extent + xbuffer;
   } else {
      _ctlfile1.p_y=_ctlfile2.p_y=ctlcontextCombo1.p_y;
   }
   vscroll1.p_y=_ctlfile2.p_y;


   _ctlfile2.p_width=_ctlfile1.p_width=(availablespace-vscroll1.p_width) intdiv 2;
   ctlcontextCombo1.p_width = ctlcontextCombo2.p_width = _ctlfile1.p_width;
   vscroll1.p_x=(_ctlfile1.p_x_extent)-_twips_per_pixel_x();
   _ctlfile2.p_x = ctlcontextCombo2.p_x=vscroll1.p_x_extent-_twips_per_pixel_x();
   hscroll1.p_width=(_ctlfile2.p_x_extent-_ctlfile1.p_x)/*-_twips_per_pixel_x()*/;

   if ( !_haveProDiff() ) {
      _ctlfile1.p_height=((p_active_form.p_client_height*_twips_per_pixel_y())-_ctlfile1.p_y)-(xbuffer*7)-_ctlclose.p_height-hscroll1.p_height-_ctlfile1line.p_height-_ctlfile2_readonly.p_height-(_twips_per_pixel_y()*2);

      resizeMiddleDialog(xbuffer,tworows);

      _ctlseparater.p_y=_ctlcopy_left.p_y;
   } else {
      _ctlfile1.p_height=((p_active_form.p_client_height*_twips_per_pixel_y())-_ctlfile1.p_y)-(xbuffer*7)-_ctlclose.p_height-hscroll1.p_height-_ctlfile1line.p_height-_ctlfile2_readonly.p_height-_ctlcopy_right.p_height-(_twips_per_pixel_y()*2);

      resizeMiddleDialog(xbuffer,tworows);

      _ctlseparater.p_y=_ctlcopy_left.p_y_extent+(xbuffer*2);
   }
   _ctlseparater.p_width=p_active_form.p_width;


   PlaceBottomRowButtons(xbuffer);

   _ctlfile1label.p_auto_size=false;
   _ctlfile2label.p_auto_size=false;
   _ctlfile1label.p_width=_ctlfile1.p_width;_ctlfile2label.p_width=_ctlfile2.p_width;

   fob := "";
   _str FileTitles=_DiffGetDialogTitles();
   File1Title := strip(parse_file(FileTitles),'B','"');
   File2Title := strip(parse_file(FileTitles),'B','"');
   if (_ctlfile1.p_buf_name!='') {
      _ctlfile1label.GetFileOrBuffer(fob);
      _ctlfile1label.p_caption=File1Title:+fob;
   }
   if (_ctlfile2.p_buf_name!='') {
      _ctlfile2label.GetFileOrBuffer(fob);
      _ctlfile2label.p_caption=File2Title:+fob;
   }

   _ctlfile1label.DiffShrinkFilename(File1Title, _ctlfile1label.p_width);
   _ctlfile2label.DiffShrinkFilename(File2Title, _ctlfile2label.p_width);

   SetListVisibleProperty(widlist,1);
   FormSize=p_active_form.p_width' 'p_active_form.p_height;
   _SetDialogInfo(DIFFEDIT_CONST_FORM_SIZE,FormSize);

   p1 := 1;
   _DiffSetupScrollBars();

   SetLineLabelWidths();
   SetHScrollFlag(p_active_form);

   in_on_resize=0;
}

void _ctlfile1.on_resize()
{
   _DiffSetupScrollBars();
}

static void MaybeHide(int wid)
{
   if (_ctlfile1line.p_y==wid.p_y &&
       _ctlfile1line.p_x < wid.p_x_extent) {
      wid.p_visible=false;
   }else{
      wid.p_visible=true;
   }
}

static void PlaceBottomRowButtons(int xbuffer,bool BottomRowOnTop=false)
{
   _ctlclose.p_y=_ctlseparater.p_y_extent+(xbuffer);

   if (BottomRowOnTop) {
      _ctlclose.p_y=xbuffer;
      _ctlnext_difference.p_y=_ctlprev_difference.p_y=_ctlclose.p_y;
   }else{
      _ctlnext_difference.p_y=_ctlprev_difference.p_y=_ctlclose.p_y;
   }

   _ctlfile1label.p_x=_ctlfile1.p_x;_ctlfile2label.p_x=_ctlfile2.p_x;

   _ctlfile1label.p_width=_ctlfile1.p_width;_ctlfile2label.p_width=_ctlfile2.p_width;
   ctloptions.p_y = ctlrediff.p_y = _ctlfind.p_y=_ctlundo.p_y=_ctlclose.p_y;
   _ctlhelp.p_y=_ctlundo.p_y;
   if ( _ctlundo.p_visible ) {
      _ctlhelp.p_x=_ctlundo.p_x_extent+xbuffer;
   }
   _ctlok.p_y=_ctlhelp.p_y;
   _ctlok.p_x=_ctlhelp.p_x_extent+xbuffer;
   ctltypetoggle.p_y = _ctlok.p_y;
   lastWID := _ctlok;
   if ( _ctlok.p_visible ) {
      lastWID = _ctlok;
   }else{
      lastWID = _ctlhelp;
   }
   ctltypetoggle.p_x = lastWID.p_x_extent + xbuffer;
}

static void clearBufferSettings()
{
   DiffFreeAllColorInfo(p_buf_id);
   _DiffRemoveImaginaryLines();
   _DiffRemoveImaginaryLines();
   _DiffClearLineFlags();
}

static int onUpdate_diff_toggle_intraline_color(CMDUI &cmdui,int target_wid,_str command)
{
   if (!target_wid) {
      return MF_GRAYED;
   }
   DIFF_MISC_INFO misc=_DiffGetMiscInfo();
   if (misc.IntraLineIsOff==1) {
      return(MF_ENABLED);
   }else if (misc.IntraLineIsOff==0) {
      return(MF_ENABLED|MF_CHECKED);
   }
   return(MF_ENABLED);
}

int _OnUpdate_diff_edit_menu(CMDUI &cmdui,int target_wid,_str command)
{
   parse command with auto menu_command auto commandToRun;
   switch (commandToRun) {
   case "align":
      return MF_ENABLED;
   case "cancel-align":
      return MF_ENABLED;
   case "toggle-intraline":
      return onUpdate_diff_toggle_intraline_color(cmdui,target_wid,command);
   case "close-and-edit":
      // For backup hsitory bufName is getting set because it intiially comes
      // up with the local file open, so we have to do further checks to see if
      // close-and-edit is allowed
      isHistoryDiff := pos('History Diff - ',p_active_form.p_caption,1);
      _nocheck _control ctltype_combo;
      if ( isHistoryDiff && (p_window_id==_ctlfile2 || ctltype_combo.p_text!=LOCAL_FILE_CAPTION) ) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_GRAYED;
      }

      return MF_ENABLED;
   case "copy-selection-to-other-window":
      {
         menuCaption := "Copy selection to ";
         if (p_window_id==_ctlfile1 ) {
            if ( !_find_control("_ctlfile2_readonly") || _ctlfile2_readonly.p_value) {
               _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
               return MF_DELETED;
            }
            menuCaption :+= _ctlfile2._DiffGetDocumentName();
         } else if (p_window_id==_ctlfile2) {
            if ( !_find_control("_ctlfile1_readonly") || _ctlfile1_readonly.p_value) {
               _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
               return MF_DELETED;
            }
            menuCaption :+= _ctlfile1._DiffGetDocumentName();
         }
         _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,MF_ENABLED,'P',menuCaption);
         return select_active()!=0?MF_ENABLED:MF_GRAYED;
      }
   }
   return MF_GRAYED;
}

_command void diff_edit_menu(_str cmdline="") name_info(','VSARG2_REQUIRES_PRO_EDITION/*|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION*/)
{
   if (cmdline=="") {
      return;
   }
   switch (lowcase(cmdline)) {
   case "align":
      diff_align_with();
      break;
   case "cancel-align":
      diff_cancel_align_with();
      break;
   case "toggle-intraline":
      diff_toggle_intraline_color();
      break;
   case "close-and-edit":
      diff_close_and_edit();
      break;
   case "copy-selection-to-other-window":
      diff_copy_selection_to_other_window();
      break;
   }
}

static void diff_cancel_align_with()
{
   if ( p_name != "_ctlfile1" && p_name != "_ctlfile2" ) {
      return;
   }
   _SetDialogInfoHt("pending1",null);
   _SetDialogInfoHt("pending2",null);
   _ctlfile1.p_mouse_pointer = _ctlfile2.p_mouse_pointer = MP_DEFAULT;
}

static void diff_align_with()
{
   nextWID := _ctlfile2;
   index := "pending1";
   if ( p_window_id == _ctlfile2 ) {
      nextWID = _ctlfile1;
      index = "pending2";

      // Use _set_focus so user does not have to click twice in other window
      _ctlfile1._set_focus();
   } else {
      // Use _set_focus so user does not have to click twice in other window
      _ctlfile2._set_focus();
   }
   _save_pos2(auto p);
   _begin_line();
   offset := _QROffset();
   _SetDialogInfoHt(index,offset);
   _restore_pos2(p);
   nextWID.p_mouse_pointer = MP_ARROW;
}

static void rediff()
{
   if (!_haveDiff()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Diff");
      return;
   }
   _ctlfile1.save_pos(auto p);
   _ctlfile2.save_pos(auto q);
   line1 := _ctlfile1.p_line;
   line2 := _ctlfile2.p_line;
   _ctlfile1.clearBufferSettings();
   _ctlfile2.clearBufferSettings();
   // Clean up any stream markers used by Source Diff

   // Clean up any stream markers used by scroll markup
   cleanupScrollMarkers("diffScrollMarkupModifiedType");
   cleanupScrollMarkers("diffScrollMarkupInsertedType");
   cleanupScrollMarkers("diffScrollMarkupDeletedType");

   gaugeWID := 0;
   gaugeFormWID := 0;
   if ( def_diff_edit_flags&DIFFEDIT_SHOW_GAUGE ) {
      gaugeFormWID = show('-mdi _difftree_progress_form');
      _DiffSetupProgressForFile(gaugeFormWID,gaugeWID);
   }
   DIFF_INFO info;

   info.iViewID1 = _ctlfile1;
   info.iViewID2 = _ctlfile2;
   info.iOptions = _GetDialogInfoHt("lastDiffOptions",_ctlfile1);
   if ( info.iOptions==null ) {
      info.iOptions = def_diff_flags;
   }
   info.iNumDiffOutputs = 0;
   info.iIsSourceDiff = false;
   info.loadOptions = def_load_options;
   info.iGaugeWID = gaugeWID;
   info.iMaxFastFileSize = def_max_fast_diff_size;
   info.lineRange1 = "1";
   info.lineRange2 = "1";
   info.iSmartDiffLimit = def_smart_diff_limit;
   info.imaginaryText = null;
   info.tokenExclusionMappings=null;
   info.alignments = null;

   getAlignments(auto alignmentList);

   info.alignments = alignmentList;

   status := Diff(info,auto junk);
   _ctlfile1.restore_pos(p);
   _ctlfile2.restore_pos(q);

   _ctlfile1.p_line = line1;
   _ctlfile2.p_line = line2;
   //_ctlfile1._BlastUndoInfo();
   //_ctlfile2._BlastUndoInfo();
   _DiffSetupScrollBars();
   gaugeFormWID._delete_window();
}

void ctlrediff.lbutton_up()
{
    getAlignments(auto alignmentList);
    if ( alignmentList._length()>0 ) {
       status := _message_box(nls("Clear alignments?"),"",MB_YESNO);
       if ( status==IDYES ) {
          _SetDialogInfoHt("alignments",null);
       }
    }
    rediff();
    if ( LastActiveEditWindowWID ) {
       LastActiveEditWindowWID._set_focus();
    }
}

static void SetLineLabelWidths()
{
   if ( _DiffGetLineNumLabelsMissing()!=1 ) {
      int textwidth1=_ctlfile1line._text_width(_ctlfile1.p_line'/'_ctlfile1.p_Noflines);
      int textwidth2=_ctlfile2line._text_width(_ctlfile2.p_line'/'_ctlfile2.p_Noflines);
      _ctlfile1line.p_x=(_ctlfile1.p_x_extent)-textwidth1;
      _ctlfile2line.p_y=_ctlfile1line.p_y;
      _ctlfile2line.p_x=((_ctlfile2.p_x_extent)-textwidth2)-300;
   }
}

static void diff_mode_split_insert_line()
{
   //Shut off the intra-line diffing while we do this.
   //Otherwise, the callback will hit in them middle of the
   //split and diff lines that are not really side by side
   if (DialogIsDiff()) {
      DiffTextChangeCallback(0,_ctlfile1.p_buf_id);
      DiffTextChangeCallback(0,_ctlfile2.p_buf_id);
   }
   otherwid := GetOtherWid(auto wid);
   wid._undo('S');
   otherwid._undo('S');

   _UndoPushModify(otherwid);

   if ( wid._lineflags()&NOSAVE_LF ) {
      // If this is an imaginary buffer line, go to the end of the line before
      // the user presses enter so we do not split the line
      _end_line();
   }
   oldlinenum := p_line;
   oldline := "";
   get_line(oldline);

   mode_name := "";
   key_index := 0;
   index := 0;
   lastEventName := event2name(last_event());
   if ( lastEventName :== "ENTER" 
        || lastEventName :== "C-ENTER" 
        || lastEventName :== "S-ENTER" 
        || lastEventName :== "C-S-ENTER" 
        ) {
      key_index=event2index(last_event());
      index=eventtab_index(_default_keys,p_mode_eventtab,key_index);
   } else {
      parse lowcase(p_mode_name) with mode_name '-' .;
      index=find_index(mode_name'_enter',COMMAND_TYPE);
   }
   oldro := p_readonly_mode;
   p_readonly_mode=false;
   if (!index) {
      wid.split_insert_line();
   }else{
      //index=find_index(arg(1)'_enter',COMMAND_TYPE);
      call_index(index);
   }
   p_readonly_mode=oldro;
   wid=p_window_id;
   p_window_id=otherwid;
   if (wid.p_Noflines!=otherwid.p_Noflines) {
      p_line=oldlinenum;
      DiffInsertImaginaryBufferLine();
      otherwid.p_line=wid.p_line;
      AddUndoNothing(otherwid);
   }
   p_window_id=wid;
   if (DialogIsDiff()) {
      //Turn the intra-line diffing back on
      DiffTextChangeCallback(1,_ctlfile1.p_buf_id);
      DiffTextChangeCallback(1,_ctlfile2.p_buf_id);
   }
   _UndoPopModify(otherwid);

   _DiffSetupScrollBars();
}

static void FixCaption(int wid,bool modify)
{
   if (length(wid.p_caption)<2) {
      return;
   }
   str := substr(wid.p_caption,length(wid.p_caption)-1);
   cap := wid.p_caption;
   if (str==' *') {
      cap=substr(cap,1,length(wid.p_caption)-2);
   }
   if (modify) {
      cap :+= ' *';
   }
   if (cap!=wid.p_caption) {
      wid.p_caption=cap;
   }
}

static void DiffLabelCopyButtons()
{
   if ( _DiffCopyMissing()==1 ) {
      return;
   }
   diff_label_copy_buttons(_ctlcopy_right, _ctlcopy_right_line,
                           _ctlcopy_left,  _ctlcopy_left_line);
}

void diff_label_copy_buttons( int r_copy_block,   int r_copy_line,
                              int l_copy_block=0, int l_copy_line=0,
                              bool reverse_left_and_right = false )
{
   if (reverse_left_and_right) {
      diff_label_copy_buttons( l_copy_block, l_copy_line,
                               r_copy_block, r_copy_line);
      return;
   }

   line := "";
   if (!_ctlfile1.p_line) {
      if (r_copy_block) r_copy_block.p_enabled=false;
      if (r_copy_line)  r_copy_line.p_enabled=false;
      if (l_copy_block) l_copy_block.p_enabled=false;
      if (l_copy_line)  l_copy_line.p_enabled=false;
   }else{
      int file1line_modified=_ctlfile1._lineflags()&MODIFY_LF;
      int file1line_inserted=_ctlfile1._lineflags()&INSERTED_LINE_LF;
      int file2line_modified=_ctlfile2._lineflags()&MODIFY_LF;
      int file2line_inserted=_ctlfile2._lineflags()&INSERTED_LINE_LF;
      if (file1line_inserted) {
         if (r_copy_block) r_copy_block.p_enabled=true;
         if (l_copy_block) l_copy_block.p_enabled=true;
         _ctlfile1.get_line(line);
         if (_ctlfile1._lineflags()&NOSAVE_LF) {//Inserted Line
            if (l_copy_block) l_copy_block.p_caption='<<Block';
            if (r_copy_block) r_copy_block.p_caption='Del Block';
            if (r_copy_line)  r_copy_line.p_enabled=false;
            if (l_copy_line)  l_copy_line.p_enabled=true;
         }else{//Deleted Line
            if (r_copy_block) r_copy_block.p_enabled=true;
            if (l_copy_block) l_copy_block.p_enabled=true;
            if (l_copy_block) l_copy_block.p_caption='Del Block';
            if (r_copy_block) r_copy_block.p_caption='Block>>';
            if (r_copy_line)  r_copy_line.p_enabled=true;
            if (l_copy_line)  l_copy_line.p_enabled=false;
         }
      }else if (file2line_inserted) {
         if (r_copy_block) r_copy_block.p_enabled=true;
         if (l_copy_block) l_copy_block.p_enabled=true;
         _ctlfile1.get_line(line);
         if (_ctlfile1._lineflags()&NOSAVE_LF) {//Inserted Line
            if (l_copy_block) l_copy_block.p_caption='<<Block';
            if (r_copy_block) r_copy_block.p_caption='Del Block';
            if (r_copy_line)  r_copy_line.p_enabled=false;
            if (l_copy_line)  l_copy_line.p_enabled=true;
         }else{//Deleted Line
            if (r_copy_block) r_copy_block.p_enabled=true;
            if (l_copy_block) l_copy_block.p_enabled=true;
            if (l_copy_block) l_copy_block.p_caption='Del Block';
            if (r_copy_block) r_copy_block.p_caption='Block>>';
            if (r_copy_line)  r_copy_line.p_enabled=true;
            if (l_copy_line)  l_copy_line.p_enabled=false;
         }
      }else if (file1line_modified||file2line_modified) {
         if (r_copy_block) r_copy_block.p_enabled=true;
         if (l_copy_block) l_copy_block.p_enabled=true;
         if (r_copy_line)  r_copy_line.p_enabled=true;
         if (l_copy_line)  l_copy_line.p_enabled=true;
         if (l_copy_block) l_copy_block.p_caption='<<Block';
         if (r_copy_block) r_copy_block.p_caption='Block>>';
      }else{
         if (l_copy_block) l_copy_block.p_caption='<<Block';
         if (r_copy_block) r_copy_block.p_caption='Block>>';
         if (r_copy_block) r_copy_block.p_enabled=false;
         if (l_copy_block) l_copy_block.p_enabled=false;
         if (r_copy_line)  r_copy_line.p_enabled=false;
         if (l_copy_line)  l_copy_line.p_enabled=false;
      }
   }
}

static bool DialogIsDiff()
{
   //return(p_active_form.p_caption=='Diff');
   int i;
   for (i=0;i<gDiffUpdateInfo.list._length();++i) {
      if (gDiffUpdateInfo.list[i].wid==p_active_form &&
         gDiffUpdateInfo.list[i].isdiff) {
         return(true);
      }
   }
   return(false);
}

static void UpdateForm2()
{
   if (arg(1)!='') {
      if (_ctlfile1.p_line!=arg(1)) {
         return;
      }
   }
   if (!_find_control('_ctlfile1')) {
      return;
   }
   if ( !_DiffGetNeedRefresh() ) {
      return;
   }

   if (!_GetDialogInfo(DIFFEDIT_CONST_HAS_MODIFY)) {
      _SetDialogInfo(DIFFEDIT_CONST_FILE1_MODIFY,_ctlfile1.p_modify);
      _ctlfile1.p_modify=false;
      _SetDialogInfo(DIFFEDIT_CONST_FILE2_MODIFY,_ctlfile2.p_modify);
      _ctlfile2.p_modify=false;
      _SetDialogInfo(DIFFEDIT_CONST_HAS_MODIFY,true);
   }

   if ( _DiffGetLineNumLabelsMissing()!=1 ) {
      _ctlfile1line.p_caption=_ctlfile1.p_RLine'/'(_ctlfile1.p_Noflines-_ctlfile1.p_NofNoSave);
      _ctlfile2line.p_caption=_ctlfile2.p_RLine'/'(_ctlfile2.p_Noflines-_ctlfile2.p_NofNoSave);
   }
   SetLineLabelWidths();
   if (DialogIsDiff()) {
      DiffLabelCopyButtons();
   } else if (!_DiffCopyLeftMissing()) {
      diff_label_copy_buttons(0, 0, _ctlcopy_left,  _ctlcopy_left_line);
   }
   if ( _DiffGetFileLabelsMissing()!=1 ) {
      FixCaption(_ctlfile1label,_ctlfile1.p_modify||_GetDialogInfo(DIFFEDIT_CONST_FILE1_MODIFY));
      FixCaption(_ctlfile2label,_ctlfile2.p_modify||_GetDialogInfo(DIFFEDIT_CONST_FILE2_MODIFY));
   }
   int YInLines=_ctlfile1.p_cursor_y intdiv _ctlfile1.p_font_height;

   //vscroll1.p_user='';
   _DiffVscrollSetLast('');
   vscroll1.p_value=_ctlfile1.p_line-YInLines;
   //vscroll1.p_user=_ctlfile1.p_line-YInLines;
   _DiffVscrollSetLast(_ctlfile1.p_line-YInLines);

   _DiffHscrollSetLast('');
   hscroll1.p_value=_ctlfile1.p_left_edge;
   _DiffHscrollSetLast(_ctlfile1.p_left_edge);

   if (DialogIsDiff() && _DiffCopyMissing()!=1) {
      _str files_matched=_DiffGetFilesMatch();
      _ctlcopy_right_all.p_enabled=files_matched!='Files Match';
      _ctlcopy_left_all.p_enabled=files_matched!='Files Match';
   }
   _DiffSetNeedRefresh(false);
}

void _diffedit_UpdateForm()
{
   //We have to do all these cascading checks because we get called on a timer
   //and some parts may be filled in, but not other parts.
   i := 0;
   if (gDiffUpdateInfo.list._varformat()==VF_ARRAY) {
      for (i=0;i<gDiffUpdateInfo.list._length();++i) {
         if (VF_IS_STRUCT(gDiffUpdateInfo.list[i])) {
            if (VF_IS_INT(gDiffUpdateInfo.list[i].wid)) {
               if (_iswindow_valid(gDiffUpdateInfo.list[i].wid)) {
                  gDiffUpdateInfo.list[i].wid.UpdateForm2();
                  if (gDiffUpdateInfo.list[i].NeedToSetupHScroll) {
                     formWID := gDiffUpdateInfo.list[i].wid;
                     formWID._DiffSetupHorizontalScrollBar();
                     formWID.vscroll1.p_large_change=formWID._ctlfile1.p_char_height-1;
                  }
               }
            }
         }
      }
   }
}

static void SetHScrollFlag(int formwid,bool value=true)
{
   i := 0;
   if (gDiffUpdateInfo.list._varformat()==VF_ARRAY) {
      for (i=0;i<gDiffUpdateInfo.list._length();++i) {
         if (VF_IS_STRUCT(gDiffUpdateInfo.list[i])) {
            if (gDiffUpdateInfo.list[i].wid==formwid) {
               gDiffUpdateInfo.list[i].NeedToSetupHScroll=value;
               break;
            }
         }
      }
   }
}

int DiffModifiedFiles()
{
   i := 0;
   if (gDiffUpdateInfo.list._varformat()==VF_ARRAY) {
      for (i=0;i<gDiffUpdateInfo.list._length();++i) {
         if (VF_IS_STRUCT(gDiffUpdateInfo.list[i])) {
            int formwid=gDiffUpdateInfo.list[i].wid;
            wid := p_window_id;
            p_window_id=formwid;
            if (_ctlfile1.p_modify || _ctlfile2.p_modify) {
               p_window_id=wid;
               return(formwid);
            }
            p_window_id=wid;
         }
      }
   }
   return(0);
}

static void diff_maybe_deselect_command(...)
{
   diff_maybe_deselect();
   diff_command(arg(1));
   wid := 0;
   otherwid := GetOtherWid(wid);
   otherwid.p_col=wid.p_col;
   otherwid.p_line=wid.p_line;
   _DiffUpdateScrollThumbs();
}

static void diff_command_and_update() {
   diff_command(arg(1));
   wid := 0;
   otherwid := GetOtherWid(wid);
   otherwid.p_col=wid.p_col;
   otherwid.p_line=wid.p_line;
   _DiffUpdateScrollThumbs();
}

static void diff_command(...)
{
   wid := 0;
   otherwid := GetOtherWid(wid);
#if 0 //4:14pm 9/12/2019
   //This is the only way I could compare to see if it was a pointer to undo
   typeless str_uc=undo_cursor;
   typeless str_u=undo;
   if (arg(1)!=str_u && arg(1)!=str_uc) {
      if (in_cua_select) {
         if (p_window_id==_ctlfile1) {
            _ctlfile2._undo('S');
         }else{
            _ctlfile1._undo('S');
         }
      }else{
         _ctlfile1._undo('S');
         _ctlfile2._undo('S');
      }
   }
#endif
#if 0 //4:31pm 9/13/2019
   lastCommandName := _GetDialogInfoHt("lastCommandName",_ctlfile1);
   if (lastCommandName!=null) {
      say('diff_command lastCommandName='lastCommandName);
   }
   if ( lastCommandName=="select-char" || lastCommandName=="select-line" ) {
      if ( wid.select_active() ) {
         say('diff_command AddUndoNothing('otherwid.p_name')');
         AddUndoNothing(otherwid);
      } else if ( otherwid.select_active() ) {
         say('diff_command AddUndoNothing('wid.p_name')');
         AddUndoNothing(wid);
      }
   }
#endif

   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   typeless ptr=arg(1);
   p_window_id=wid;
   typeless junk=(*ptr)();
   p_window_id=otherwid;
   junk=(*ptr)();
   p_window_id=wid;
   otherwid.p_col=wid.p_col;
   _SetDialogInfoHt("lastWasDiffCommand",1);
}

_ctlcopy_left.lbutton_up()
{
   if ( _ctlfile1.DiffEditorIsReadOnly() ) {
      _message_box(nls("Command not allowed in Read Only mode"));
      return(1);
   }
   formWid := p_active_form;
   switch (_ctlcopy_left.p_caption) {
   case 'Del Block':
      _ctlfile2.diff_delete_block();
      break;
   case '<<Block':
      _ctlfile2.diff_copy_block();
      break;
   }
   if (!_iswindow_valid(formWid)) return(0);
   _DiffSetNeedRefresh(true);
   ReturnFocusToEditWindow();

   return(0);
}

_ctlcopy_left_all.lbutton_up()
{
   if ( _ctlfile1.DiffEditorIsReadOnly() ) {
      _message_box(nls("Command not allowed in Read Only mode"));
      return(1);
   }
   mou_hour_glass(true);
   p_window_id=_ctlfile2;
   _set_focus();
   _ctlfile2.top();_ctlfile2.up();
   _ctlfile1.top();_ctlfile1.up();
   int old=def_diff_edit_flags;
   def_diff_edit_flags|=DIFFEDIT_AUTO_JUMP;
   diff_next_difference('','No Messages');
   if (DialogIsDiff()) {
      DiffTextChangeCallback(0,_ctlfile1.p_buf_id);
      DiffTextChangeCallback(0,_ctlfile2.p_buf_id);
   }
   typeless status=0;
   for (;;) {
      status=_ctlfile2.diff_copy_block('No Messages', true,  true);
      if (status) break;
   }
   if (DialogIsDiff()) {
      DiffClearAllColorInfo(_ctlfile1.p_buf_id);
      DiffClearAllColorInfo(_ctlfile2.p_buf_id);
   }
   refresh();//This is important.  Otherwise, the callback gets called with most of the file
   if (DialogIsDiff()) {
      DiffTextChangeCallback(1,_ctlfile1.p_buf_id);
      DiffTextChangeCallback(1,_ctlfile2.p_buf_id);
   }
   def_diff_edit_flags=old;
   _DiffSetNeedRefresh(true);
   p_window_id=_ctlfile2;
   ReturnFocusToEditWindow();
   mou_hour_glass(false);
   return(0);
}

static void merge_copy_block()
{
   int lineflags=_lineflags();
   curflag := 0;
   if (lineflags&MODIFY_LF) {
      curflag=MODIFY_LF;
   }else if (lineflags&INSERTED_LINE_LF) {
      curflag=INSERTED_LINE_LF;
   }
   if (!curflag) {
      return;
   }
   while (!up()) {
      if (!(_lineflags()&(curflag|NOSAVE_LF))) {
         down();
         break;
      }
   }
   _ctlfile2.p_line=p_line;
   for (;;) {
      if (!(_lineflags()&NOSAVE_LF)) {
         line := "";
         get_line(line);
         _ctlfile2._lineflags(0,~curflag);
         _ctlfile2._lineflags(curflag,curflag);
         _ctlfile2.safe_replace_line(line);
      }
      if (down() || _ctlfile2.down()) break;
      if (!(_lineflags()&(curflag|NOSAVE_LF))) {
         break;
      }
   }
}

static void CopyFile1Block()
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   p_window_id=_ctlfile1;
   old_line1 := _ctlfile1.p_line;
   old_line2 := _ctlfile2.p_line;
   while (_lineflags()&(MODIFY_LF|NOSAVE_LF)) {
      _ctlfile1.up();_ctlfile2.up();
   }
   //_ctlfile1.diff_copy_block('',false);
   _ctlfile1.merge_copy_block();
   _ctlfile1.p_line=old_line1;
   _ctlfile2.p_line=old_line2;
   AddUndoNothing(_ctlfile2);
}

void _DiffAddUndoOther(int buf_id)
{
   int i;
   for (i=0;i<gDiffUpdateInfo.list._length();++i) {
      int fid=gDiffUpdateInfo.list[i].wid;
      if (fid._ctlfile1.p_buf_id==buf_id) {
         fid._ctlfile2._undo('S');
         AddUndoNothing(fid._ctlfile2);
         return;
      }
      if (fid._ctlfile2.p_buf_id==buf_id) {
         fid._ctlfile1._undo('S');
         AddUndoNothing(fid._ctlfile1);
         return;
      }
   }
}
static void diff_quote_key()
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   wid := 0;
   otherwid := GetOtherWid(wid);
   wid.quote_key();
   AddUndoNothing(otherwid);
}

static void diff_auto_functionhelp_key()
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   wid := 0;
   otherwid := GetOtherWid(wid);
   wid.auto_functionhelp_key();
   AddUndoNothing(otherwid);
}
static void diff_auto_codehelp_key()
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   wid := 0;
   otherwid := GetOtherWid(wid);
   wid.auto_codehelp_key();
   AddUndoNothing(otherwid);
}

static void diff_codehelp_complete()
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   wid := 0;
   otherwid := GetOtherWid(wid);
   oldcol := wid.p_col;
   wid.codehelp_complete();
   if (wid.p_col!=oldcol) {
      AddUndoNothing(otherwid);
   }
}

static void diff_gui_goto_line()
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   wid := 0;
   otherwid := GetOtherWid(wid);
   origParam1 := _param1;
   wid.gui_goto_line();
   _param1 = origParam1;
   otherwid.p_line=wid.p_line;
   wid.center_line();
   otherwid.center_line();
}

static void diff_seek(long seekPos)
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   _ctlfile1.goto_point(seekPos);
   _ctlfile1.p_scroll_left_edge=-1;
   _ctlfile2.p_scroll_left_edge=-1;
   _ctlfile2.p_line = _ctlfile1.p_line;
   _ctlfile1.center_line();
   _ctlfile2.center_line();
   _DiffUpdateScrollThumbs(true);
   _DiffSetNeedRefresh(true);
}

static void diff_fast_scroll()
{
   if (last_event()==ON_SB_END_SCROLL) {
      return;
   }

   int key=event2index(last_event());
   key&=(~VSEVFLAG_ALL_SHIFT_FLAGS);

   newVal := 0;
   switch (index2event(key)) {
   case WHEEL_RIGHT:
   case WHEEL_DOWN:
      newVal = vscroll1.p_value+1;
      break;
   case WHEEL_LEFT:
   case WHEEL_UP:
      newVal = vscroll1.p_value-1;
      break;
   }
   if ( newVal >=0 && newVal <= vscroll1.p_max ) {
      vscroll1.p_value = newVal;
   }
}

static void diff_scroll_page_down()
{
   vscroll1.p_value+=vscroll1.p_large_change;
}

static void diff_scroll_page_up()
{
   vscroll1.p_value-=vscroll1.p_large_change;
}

static int diff_quit()
{
   return(_ctlclose.call_event(_ctlclose,LBUTTON_UP));
}

static void CopyFile2Block()
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   p_window_id=_ctlfile1;
   old_line1 := _ctlfile1.p_line;
   old_line2 := _ctlfile2.p_line;
   while (!(_lineflags()&MODIFY_LF)) {
      _ctlfile1.down();_ctlfile2.down();
   }
   //_ctlfile1.diff_copy_block('',false);
   _ctlfile1.merge_copy_block();
   _ctlfile1.p_line=old_line1;
   _ctlfile2.p_line=old_line2;
   AddUndoNothing(_ctlfile1);
}

void diff_copy_line(int wid1,int wid2)
{
   wid1.p_scroll_left_edge=-1;
   wid2.p_scroll_left_edge=-1;
   ReadOnlyCheckBoxWID := _find_control(wid2.p_name'_readonly');
   if (ReadOnlyCheckBoxWID) {
      if (ReadOnlyCheckBoxWID.p_value) {
         _message_box(nls("Command not allowed in Read Only mode"));
         return;
      }
   }
   line := "";
   wid1._undo('S');
   wid2._undo('S');
   wid1.get_line(line);
   wid1._lineflags(0,NOSAVE_LF);
   wid2._lineflags(0,NOSAVE_LF);
   wid2.safe_replace_line(line);
   wid1._lineflags(0,MODIFY_LF|INSERTED_LINE_LF);
   wid2._lineflags(0,MODIFY_LF|INSERTED_LINE_LF);
   removeMarginButtonsFromLine(_ctlfile1.p_line);
   wid1.down();
   wid2.down();
   wid1.refresh('w');
   wid2.refresh('w');
   ReturnFocusToEditWindow();
   _DiffSetNeedRefresh(true);
}

int _ctlcopy_right_line.lbutton_up()
{
   if (DialogIsDiff()) {
      if ( _ctlfile2.DiffEditorIsReadOnly() ) {

         if ( maybeSwitchToLineDiff() ) {
            return 0;
         }else{
            _message_box(nls("Command not allowed in Read Only mode"));
         }

         return(1);
      }
      diff_copy_line(_ctlfile1,_ctlfile2);
   }else{
      _ctlfile1._undo('s');
      _ctlfile2._undo('s');
      wid := p_window_id;
      p_window_id=_ctlfile1;
      save_pos(auto p);
      top();up();
      while (!diff_next_difference()) {
         _ctlcopy_right.call_event(_ctlcopy_right,LBUTTON_UP);
         AddUndoNothing(_ctlfile1);
      }
      restore_pos(p);
      _ctlfile2.p_line=p_line;
      p_window_id=wid;
   }
   return(0);
}
int _ctlcopy_left_line.lbutton_up()
{
   diff_copy_line(_ctlfile2,_ctlfile1);
   return(0);
}

/** 
 * Prompt user to switch to line diff so that they can  
 * 
 * @return bool non-zero if user clicks Line Diff button
 */
static bool promptForLineDiff(bool &turnOffSourceDiff)
{
   turnOffSourceDiff = false;
   DIFF_READONLY_TYPE readOnly2=_GetDialogInfo(DIFFEDIT_READONLY2_VALUE,_ctlfile1);
   result := 0;
   if ( readOnly2!=DIFF_READONLY_SET_BY_USER ) {

      // Only show checkbox if Source Diff is turned on
      checkboxCaption := "";
      if ( !(def_diff_flags&DIFF_NO_SOURCE_DIFF) ) {
         checkboxCaption = "-CHECKBOX Set default to Line Diff";
      }
      result = textBoxDialog("Source Diff",
                              TB_RETRIEVE,
                              0,
                              '',
                              "Line Diff,Cancel:_cancel\t-html In <B>Source Diff</B> the file on the right is always read only.  You can edit both sides by using <B>Line Diff</B>.",//Button List
                              "",
                              checkboxCaption);
      if ( result==1 ) {
         if ( _param1==1 ) {
            // Checkbox was on
            turnOffSourceDiff = true;
         }
      }
   }
   return (result>0);
}

static int maybeSwitchToLineDiff()
{
   if (! _find_control("ctltypetoggle") ) {
      return 0;
   }
   if ( ctltypetoggle.p_caption=="Line Diff" ) {
      // We are in source diff, and could change to line diff
      switchToLineDiff := promptForLineDiff(auto turnOffSourceDiff);
      if ( switchToLineDiff ) {
         if ( turnOffSourceDiff==1 ) {
            def_diff_flags |= DIFF_NO_SOURCE_DIFF;
         }
         ctltypetoggle.call_event(ctltypetoggle,LBUTTON_UP);
      }
      return 1;
   }
   return 0;
}

int _ctlcopy_right.lbutton_up()
{
   if ( _ctlfile2.DiffEditorIsReadOnly() ) {

      if ( maybeSwitchToLineDiff() ) {
         return 0;
      }else{
         _message_box(nls("Command not allowed in Read Only mode"));
      }

      return(1);
   }
   formWid := p_active_form;
   if (DialogIsDiff()) {
      switch (_ctlcopy_right.p_caption) {
      case 'Del Block':
         _ctlfile1.diff_delete_block();
         break;
      case 'Block>>':
         _ctlfile1.diff_copy_block();
         break;
      }
      if (!_iswindow_valid(formWid)) return(0);
   }else{
      CopyFile1Block();
      _ctlcopy_right.p_enabled=false;
   }
   _DiffSetNeedRefresh(true);
   p_window_id=_ctlfile1;
   _ctlfile1.refresh('w');
   _ctlfile2.refresh('w');
   ReturnFocusToEditWindow();
   return(0);
}

int _ctlcopy_right_all.lbutton_up()
{
   if ( _ctlfile2.DiffEditorIsReadOnly() ) {
      if ( maybeSwitchToLineDiff() ) {
         return 0;
      }else{
         _message_box(nls("Command not allowed in Read Only mode"));
      }
      return(1);
   }
   typeless status=0;
   mou_hour_glass(true);
   p_window_id=_ctlfile1;
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   if (DialogIsDiff()) {
      _ctlfile2.top();_ctlfile2.up();
      _ctlfile1.top();_ctlfile1.up();
      int old=def_diff_edit_flags;
      def_diff_edit_flags|=DIFFEDIT_AUTO_JUMP;
      diff_next_difference('','No Messages');
      if (DialogIsDiff()) {
         DiffTextChangeCallback(0,_ctlfile1.p_buf_id);
         DiffTextChangeCallback(0,_ctlfile2.p_buf_id);
      }
      for (;;) {
         status=_ctlfile1.diff_copy_block('No Messages', true,  true);
         if (status) break;
      }
      if (DialogIsDiff()) {
         DiffTextChangeCallback(1,_ctlfile1.p_buf_id);
         DiffTextChangeCallback(1,_ctlfile2.p_buf_id);
         DiffClearAllColorInfo(_ctlfile1.p_buf_id);
         DiffClearAllColorInfo(_ctlfile2.p_buf_id);
      }
      def_diff_edit_flags=old;
      _DiffSetNeedRefresh(true);
   }else{
      CopyFile2Block();
      _ctlcopy_right_all.p_enabled=false;
   }
   p_window_id=_ctlfile1;
   ReturnFocusToEditWindow();
   mou_hour_glass(false);
   return(0);
}

static void diff_find(...)
{
   origParam1 := _param1;
   typeless findarg=arg(1);
   wid := p_window_id;
   if (wid != _ctlfile1 && wid != _ctlfile2) {
      wid = LastActiveEditWindowWID;
   }
   typeless status=wid.gui_find_modal(findarg);
   if (wid==_ctlfile1) {
      _ctlfile2.p_col = _ctlfile1.p_col;
      _ctlfile2.p_line=_ctlfile1.p_line;
      _ctlfile2.set_scroll_pos(_ctlfile1.p_left_edge,_ctlfile1.p_cursor_y);
   }else if (wid==_ctlfile2) {
      _ctlfile1.p_col = _ctlfile2.p_col;
      _ctlfile1.p_line=_ctlfile2.p_line;
      _ctlfile1.set_scroll_pos(_ctlfile2.p_left_edge,_ctlfile2.p_cursor_y);
   }
   if (status && status!=COMMAND_CANCELLED_RC) {
      clear_message();
      _message_box(nls("String not found"));
   } else if ( !status ) {
      if ( wid==_ctlfile1 ) {
         _ctlfile1._set_focus();
      } else if ( wid==_ctlfile2 ) {
         _ctlfile2._set_focus();
      }
   }
   _param1 = origParam1;
}

static void diff_find_re()
{
   diff_find('-r');
}

static void diff_find_backwards()
{
   diff_find('-');
}

_ctlfind.lbutton_up()
{
   diff_find();
   _DiffSetNeedRefresh(true);
}

int _ctlfile1save.lbutton_up()
{
   typeless status=0;
   if (DialogIsDiff()) {
      status=_ctlfile1._diff_save();
      if ( !status ) {
         _SetDialogInfo(DIFFEDIT_CONST_FILE1_MODIFY,false);
      }
      ReturnFocusToEditWindow();
      return(status);
   }else{
      _ctlfile1._undo('s');
      _ctlfile2._undo('s');
      wid := p_window_id;
      p_window_id=_ctlfile1;
      save_pos(auto p);
      top();up();
      while (!diff_next_difference()) {
         _ctlcopy_right_all.call_event(_ctlcopy_right_all,LBUTTON_UP);
         AddUndoNothing(_ctlfile1);
      }
      restore_pos(p);
      _ctlfile2.p_line=p_line;
      p_window_id=wid;
   }
   return(0);
}

int _ctlfile2save.lbutton_up()
{
   typeless status=_ctlfile2._diff_save();
   if ( !status ) {
      _SetDialogInfo(DIFFEDIT_CONST_FILE2_MODIFY,false);
   }
   ReturnFocusToEditWindow();
   return(status);
}

void diffStartNewUndoStep(_str buf_name)
{
   if ( buf_name=="" ) return;
   wid:=window_match(buf_name,1,"xn",-1,"VG,VM,VA,GMA");
   if (wid) {
      wid._undo('s');
      return;
   }
   origWID := p_window_id;
   p_window_id = HIDDEN_WINDOW_ID;
   _safe_hidden_window();
   status := load_files('+b 'buf_name);
   if ( !status ) {
      _undo('s');
   }
   p_window_id = origWID;
}

static void ReplaceMarkedSelection(int &MarkId,int MarkedBufId,int OldMarkId,int SourceViewId,_str origFile1PosMarker = '')
{
   orig_view_id := p_window_id;
   p_window_id=SourceViewId;
   int NewMarkId=_alloc_selection();
   saveAllPositions(MarkedBufId ,auto positionList);
   diffStartNewUndoStep(SourceViewId.p_buf_name);
   if (origFile1PosMarker!='' && origFile1PosMarker!=null ) {
      _begin_select(origFile1PosMarker);
   }
   top();
   _select_line(NewMarkId);
   bottom();
   status:=_select_line(NewMarkId);

   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   status=load_files('+bi 'MarkedBufId);

   // save bookmark, breakpoint, and annotation information
   status=_begin_select(OldMarkId);
   startRLine := p_RLine;
   status=_end_select(OldMarkId);
   endRLine := p_RLine;
   _SaveMarkersInFile(auto markerSaves, startRLine, endRLine);

   status=_begin_select(OldMarkId);
   orig_linenum := p_line;
   origModify := p_modify;
   status=_delete_selection(OldMarkId);
   if (p_line==orig_linenum) {
      //It should be safe to use p_line and p_Noflines here because the
      //whole file should be in memory anyway.
      up();
   }
   status=_copy_to_cursor(NewMarkId);
   _free_selection(OldMarkId);

   _RestoreMmrkersInFile(markerSaves);
   //_free_selection(NewMarkId);
   {
      top();up();
      while (!down()) {
         flags := _lineflags(0, MODIFY_LF | INSERTED_LINE_LF );
      }
   }
   MarkId=NewMarkId;
   p_modify = origModify;
   p_window_id=orig_view_id;
   restoreAllPositions(MarkedBufId, positionList);
}

static int SaveBuffer(int BufId)
{
   orig_view_id := p_window_id;
   infoWID := _ctlfile1;
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   int orig_buf_id=p_buf_id;
   typeless status=load_files('+bi 'BufId);
   if (status) {
      return(status);
   }
   _str options = build_save_options(p_buf_name)" -l";
   if (isEclipsePlugin()) {
      options = "-CFE "options;
   }

   modifiedMarkerType := _GetDialogInfoHt("modifiedMarkerType",infoWID);
   insertedMarkerType := _GetDialogInfoHt("insertedMarkerType",infoWID);
   markerIndexes := _GetDialogInfoHt("markerIndexes",infoWID);

   SEDiffSetFlagsFromMarkers(orig_view_id,p_window_id,modifiedMarkerType,insertedMarkerType);
   status = SEDiffGetChecksum(p_window_id, auto origChecksum);
   // 10/19/2020
   // Can't use low-level save here because callbacks won't be called, most 
   // notably the one for FTP upload.  All of the other callbacks have been
   // checked to be sure they're safe
   status = (int)save_file(_maybe_quote_filename(p_buf_name),options);
   status = SEDiffGetChecksum(p_window_id, auto afterChecksum);

   if (status) {
      _message_box(nls("Could not save file '%s'\n\n%s",p_buf_name,get_message(status)));
      return(status);
   }
   status=load_files('+bi 'orig_buf_id);
   p_window_id=orig_view_id;
   _DiffSetNeedRefresh(true);
   return(status);
}

static bool DiffEditorIsReadOnly()
{
   if ( _DiffGetReadOnlyCBMissing()==1 ) {
      isro := _DiffGetReadOnly()==1;
      return(isro);
   }
   int readonly_cb_wid=p_name=='_ctlfile1'?_ctlfile1_readonly:_ctlfile2_readonly;
   return(readonly_cb_wid.p_value!=0);
}

int _diff_save()
{
   typeless status=0;
   result := "";
   options := " -l";

   wid := 0;
   otherwid := GetOtherWid(wid);

   /**
    * _diff_save is not called from Eclipse.  This is here as a 
    * workaround in case you are editing within DIFFzilla on an 
    * open buffer.  The buffer itself will not be marked as 
    * "dirty", so when it is saved from diffedit, _eclipse_save 
    * will not do anything. 
    *  
    * To get around this we tell SlickEdit that save was called 
    * from Eclipse, so SlickEdit does the saving. 
    */ 
   if (isEclipsePlugin()) {
      options = "-CFE "options;
   }
   if ( DiffEditorIsReadOnly() ) {
      //_message_box(get_message(COMMAND_NOT_ALLOWED_IN_READ_ONLY_MODE_RC));
      //return(COMMAND_NOT_ALLOWED_IN_READ_ONLY_MODE_RC);
      status=_DiffGetSaveAsInfo(options,result,p_name);
      if ( status ) {
         return(status);
      }
   }else{
      diffsave_callback_index := find_index("_diff_save_callback1",PROC_TYPE|COMMAND_TYPE);
      if (diffsave_callback_index && index_callable(diffsave_callback_index)) {
         _str FileTitles=_DiffGetDialogTitles();
         File1Title := strip(parse_file(FileTitles),'B','"');
         File2Title := strip(parse_file(FileTitles),'B','"');

         title := "";
         id := 0;
         if (p_window_id==_ctlfile1) {
            id=1;
            title=File1Title;
         }else{
            id=2;
            title=File2Title;
         }
         status=call_index(p_window_id,id,title,diffsave_callback_index);
         return(status);
      }

      _ctlfile1._undo('S');
      _ctlfile2._undo('S');
      DIFF_MISC_INFO misc=_DiffGetMiscInfo();
      onlyOverlay := _GetDialogInfoHt("onlyOverlay",_ctlfile2);
      if (p_window_id==_ctlfile1 &&
          misc!=null &&
          misc.WholeFileBufId1>=0) {
         if ( misc.MarkId1>0 ) {
            _ctlfile1._save_pos2(auto p);
            origFile1PosMarker := "";
            origFile1PosMarker = _GetDialogInfoHt("origFile1PosMarker",_ctlfile1);
            ReplaceMarkedSelection(misc.MarkId1,misc.WholeFileBufId1,misc.MarkId1,p_window_id,origFile1PosMarker);
            _ctlfile1._restore_pos2(p);
            _SetDialogInfo(DIFFEDIT_CONST_MISC_INFO,misc,_ctlfile1);
            if ( onlyOverlay!=1 ) {
               status=SaveBuffer(misc.WholeFileBufId1);
            }
            if (!status) {
               p_modify=false;
            }
            return(status);
         }
      } else if (p_window_id==_ctlfile2 &&
                misc!=null &&
                misc.WholeFileBufId2>=0) {
         if ( misc.MarkId2>0 ) {
            _ctlfile2._save_pos2(auto p);
            ReplaceMarkedSelection(misc.MarkId2,misc.WholeFileBufId2,misc.MarkId2,p_window_id);
            _ctlfile2._restore_pos2(p);
            _SetDialogInfo(DIFFEDIT_CONST_MISC_INFO,misc,_ctlfile1);
            if ( onlyOverlay!=1 ) {
               status=SaveBuffer(misc.WholeFileBufId2);
            }
            if (!status) {
               p_modify=false;
            }
            return(status);
         }
      } else if (p_buf_name=="") {
         status=_DiffGetSaveAsInfo(options,result,p_name);
         if ( status ) {
            return(status);
         }
      }
   }
   _project_disable_auto_build(true);
   p_AllowSave=true;
   // Do not have to use _maybe_quote_filename() here because result comes from
   // _SetDialogInfo and it will quote the file name piece if necessary. If we
   // call _maybe_quote_filename(), there may be options before the file name which
   // will cause us to quote it un-necessarily
   int rv=save(options" "result);
   AddUndoNothing(otherwid);
   _DiffSetNeedRefresh(true);
   _project_disable_auto_build(false);
   return(rv);
}

static int _DiffGetSaveAsInfo(_str &options,_str &result,_str windowName)
{
   result=_OpenDialog('-new -modal',
        'Save As',
        _last_wildcards,     // Initial wildcards
        //'*.c;*.h',
        def_file_types,  // file types
        OFN_SET_LAST_WILDCARDS|OFN_SAVEAS,
        def_ext,      // Default extensions
        "", // Initial filename
        '',      // Initial directory
        '',      // Reserved
        "Save As dialog box"
        );
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   lang := p_LangId;
   if (_file_eq(lang,"fundamental")) {
      //name(result);
   } else {
      //name(result);
      if (p_LangId == 'fundamental' ||
          _file_eq(_get_extension(p_buf_name),'sql')
          ) {
         _SetEditorLanguage(lang);
      }
      _DiffSetDocumentName("");
   }
   p_buf_flags&=~VSBUFFLAG_PROMPT_REPLACE;
   if ( p_active_form.p_name=='_diff_form' ) {
      labelwid := 0;
      if (p_window_id==_ctlfile1) {
         labelwid=_ctlfile1label;
      }else{
         labelwid=_ctlfile2label;
      }
      labelwid.p_caption=p_buf_name'(Buffer)';//File cannot be modified
   }
   return(0);
}

_ctlnext_difference.lbutton_up(bool startAtLine0=false)
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   if (startAtLine0) {
      _ctlfile1.p_line=_ctlfile2.p_line=0;
   }
   status := _ctlfile1.diff_next_difference();
   if (status!=-1) {
      _DiffSetNeedRefresh(true);
      ReturnFocusToEditWindow();
   }
}

static void ReturnFocusToEditWindow()
{
   if (_iswindow_valid(LastActiveEditWindowWID)) {
      LastActiveEditWindowWID._set_focus();
   }
}

void _ctlprev_difference.lbutton_up()
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   if (_ctlfile1.diff_next_difference('-') < 0) return;
   //this is a nasty little trick I'm playing to get the scroll to
   //refresh properly
   p_window_id=_ctlfile1;
   _scroll_page('d',1);
   _scroll_page('u',1);
   p_window_id=_ctlfile2;
   _scroll_page('d',1);
   _scroll_page('u',1);
   _DiffSetNeedRefresh(true);
   ReturnFocusToEditWindow();
}

static void diff_mode_space()
{
   otherwid := GetOtherWid(auto wid);
   old_num_lines := p_Noflines;
   old_linenum := p_line;
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');

   mode_name := "";
   key_index := 0;
   index := 0;
   if ( wid.select_active() ) {
      if (!_within_char_selection() ) {
         deselect();
         _diff_docharkey();
         _ctlfile2.right();
         AddUndoNothing(_ctlfile2);
      } else {
         diff_multi_delete();
      }
      return;
   }
   _UndoPushModify(otherwid);
   if (last_event():==' ') {
      key_index=event2index(last_event());
      index=eventtab_index(_default_keys,p_mode_eventtab,key_index);
   } else {
      parse lowcase(p_mode_name) with mode_name '-' .;
      index=find_index(mode_name'_space',COMMAND_TYPE);
      if (index <= 0) {
         key_index=event2index(last_event());
         index=eventtab_index(_default_keys,p_mode_eventtab,key_index);
      }
   }
   if (index) {
      call_index(index);
   }else{
      maybe_complete();
   }
   if (wid.p_Noflines>old_num_lines) {
      int i,origwid=p_window_id;
      p_window_id=otherwid;
      p_line=old_linenum;
      int numLinesInserted = wid.p_Noflines-old_num_lines;
      for (i=1;i<=numLinesInserted;++i) {
         DiffInsertImaginaryBufferLine();
      }
      for (i=old_linenum;i<=old_linenum+((wid.p_Noflines-old_num_lines)*2)+1;++i) {
         // Callbacks come at inconvenient times.  Fix where lines where the 
         // wrong lines were compared.
         DiffUpdateColorInfo(_ctlfile1,i,_ctlfile2,i,0,1,false,false);
      }
      p_line=origwid.p_line;
      p_window_id=origwid;
   }
   _UndoPopModify(otherwid);
   AddUndoNothing(otherwid);
}

static void diff_move_text_tab()
{
   wid := p_window_id;
   if (NoSaveLine(p_line)) {
      _beep();
      return;
   }
   otherwid := 0;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   wid.move_text_tab();
   AddUndoNothing(otherwid);
}

static void diff_ctab()
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   wid.c_tab();
   AddUndoNothing(otherwid);
   otherwid.p_col=wid.p_col;
}

static void diff_cbacktab()
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   wid.cbacktab();
   otherwid.cbacktab();
   AddUndoNothing(otherwid);
}

static void diff_delete_or_cut_word(typeless *pfn)
{
   otherwid := 0;
   wid := p_window_id;
   if (NoSaveLine(p_line)) {
      _beep();
      return;
   }
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   oldwid := p_window_id;
   p_window_id=wid;
   origNumLines := wid.p_Noflines;

   bline := 0;
   eline := 0;
   typeless markid=_alloc_selection();
   WillJoinLine := false;
   save_pos(auto p);
   if (!pselect_word(markid)) {
      _begin_select(markid);
      bline=p_line;
      _end_select(markid);
      eline=p_line;
      p_line=bline;
      WillJoinLine=bline!=eline;
      if (WillJoinLine) {
         if (p_Noflines>p_line) {
            //We are not on the last line
            if (NoSaveLine(p_line+1)) {
               //The next line is an imaginary buffer line
               _free_selection(markid);
               _beep();
               restore_pos(p);
               return;//Blow out so we don't bring up the imaginary line
            }
         }
      }
   }
   _free_selection(markid);

   restore_pos(p);
   (*pfn)();
   ln := p_line;
   col := p_col;

   if (wid.p_Noflines!=origNumLines) {
      //InsertImaginaryLine();
      DiffInsertImaginaryBufferLine();
   }
   p_line=ln;p_col=col;
   AddUndoNothing(otherwid);
   p_window_id=oldwid;
}

static void diff_cut_word()
{
   diff_delete_or_cut_word(delete_word);
}
static void diff_delete_word()
{
   diff_delete_or_cut_word(cut_word);
}

static void diff_prev_or_next_word(typeless *pfn)
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');

   //AddUndoNothing did not want to work on this one so I gave in and did
   //it the hard way.. shouldn't cause a problem
   (*pfn)();
   oldwid := p_window_id;
   p_window_id=otherwid;
   (*pfn)();
   p_window_id=oldwid;
   //AddUndoNothing(otherwid);
   otherwid.p_line=wid.p_line;
   otherwid.p_col=wid.p_col;
   otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
}

static void diff_prev_word()
{
   diff_prev_or_next_word(prev_word);
}

static void diff_next_word()
{
   diff_prev_or_next_word(next_word);
}

static void diff_word_complete(_str fname)
{
   //This seems really screwy, but I gotta do some screwy stuff with undo...
   otherwid := 0;
   wid := p_window_id;
   if (NoSaveLine(p_line)) {
      _beep();
      return;
   }
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   wid._undo('S');
   otherwid._undo('S');
   typeless was_selected=select_active();
   index := find_index(fname,COMMAND_TYPE);
   typeless rv=call_index(index);
   if (rv==1 && was_selected) {
      index1 := find_index('complete-prev',COMMAND_TYPE);
      index2 := find_index('complete-next',COMMAND_TYPE);
      index3 := find_index('complete-more',COMMAND_TYPE);
      pi := prev_index();
      last_command_was_complete_command := (pi==index1||pi==index2||pi==index3);
      if (last_command_was_complete_command) {
         //say('AddUndoNothing 1');
         //AddUndoNothing(otherwid);
      }
   }
   if (rv==1) {
      AddUndoNothing(otherwid);
   }
   prev_index(index);
}

static void diff_complete_prev()
{
   diff_word_complete('complete-prev');
}

static void diff_complete_next()
{
   diff_word_complete('complete-next');
}

static void diff_complete_more()
{
   diff_word_complete('complete-more');
}

static void diff_find_matching_paren()
{
   wid := 0;
   otherwid := GetOtherWid(wid);
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   typeless status=find_matching_paren();
   if (!status) {
      otherwid.p_line=wid.p_line;
      otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
      //AddUndoNothing(otherwid);
      //Do not need to add undo information for this operation
   }
}

static void diff_cut_end_line()
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');

   origNumLines := wid.p_Noflines;

   p_window_id=wid;
   cut_end_line();

   ln := p_line;
   col := p_col;

   if (wid.p_Noflines!=origNumLines) {
      //InsertImaginaryLine();
      DiffInsertImaginaryBufferLine();
   }
   p_line=ln;p_col=col;
   AddUndoNothing(otherwid);
}

static void diff_expand_alias()
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   old_num_lines := p_Noflines;
   old_linenum := p_line;
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');

#if 0
   parse lowcase(p_mode_name) with mode_name '-' .;
   index=find_index(mode_name'_space',COMMAND_TYPE);
   if (index) {
      //wid.c_space();
      call_index(index);
   }else{
      maybe_complete();
   }
#endif
   i := 0;
   expand_alias();
   AddUndoNothing(otherwid);
   if (wid.p_Noflines>old_num_lines) {
      otherwid.p_line=old_linenum;
      for (i=1;i<=wid.p_Noflines-old_num_lines;++i) {
         //otherwid.InsertImaginaryLine();
         otherwid.DiffInsertImaginaryBufferLine();
      }
   }
}
static void diff_list_clipboards()
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   old_num_lines := p_Noflines;
   old_linenum := p_line;
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');

   list_clipboards_modal();
   AddUndoNothing(otherwid);
   if (wid.p_Noflines>old_num_lines) {
      otherwid.p_line=old_linenum;
      for (i:=1;i<=wid.p_Noflines-old_num_lines;++i) {
         //otherwid.InsertImaginaryLine();
         otherwid.DiffInsertImaginaryBufferLine();
      }
   }
}

static void diff_undo()
{
   status1 := _ctlfile1.undo();
   status2 := _ctlfile2.undo();
   //say('diff_undo status1='status1' status2='status2);
   if ( status1<0 && status2>=0 ) {
      _ctlfile1.p_line = _ctlfile2.p_line;
   } else if ( status1>=0 && status2<0 ) {
      _ctlfile2.p_line = _ctlfile1.p_line;
   }
   otherwid := GetOtherWid(auto wid);
   otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);

   _DiffSetNeedRefresh(true);
}

static void diff_push_bookmark(int &wid,int &otherwid)
{
   DIFF_MISC_INFO misc=_DiffGetMiscInfo();
   wid = otherwid = 0;
   otherwid=GetOtherWid(wid);

   otherwid._undo('S');
   wid._undo('S');

   _str Bookmarks[];
   Bookmarks=misc.Bookmarks;
   if (Bookmarks._varformat()!=VF_ARRAY) {
      Bookmarks._makeempty();
   }

   // Add bookmark bitmap. Get type, alloc if necessary
   bookmarkMarkerType := _GetDialogInfoHt("bookmarkMarkerType",wid.p_active_form);
   if ( bookmarkMarkerType==null ) {
      bookmarkMarkerType = _MarkerTypeAlloc();
      _SetDialogInfoHt("bookmarkMarkerType",bookmarkMarkerType,wid.p_active_form);
   }

   // Get pic index, find if necessary
   bookmarkPicIndex := _GetDialogInfoHt("bookmarkPicIndex",wid.p_active_form);
   if ( bookmarkPicIndex==null ) {
      bookmarkPicIndex = find_index("_ed_bookmark_pushed.svg",PICTURE_TYPE);
      _SetDialogInfoHt("bookmarkPicIndex",bookmarkPicIndex,wid.p_active_form);
   }
   // Finally, add bitmap to line
   lmIndex := _LineMarkerAdd(wid, wid.p_line, false, 0,
                             bookmarkPicIndex, bookmarkMarkerType,
                             "");

   Bookmarks[Bookmarks._length()]=wid.p_line','wid.p_col','wid.p_left_edge','wid.p_cursor_y','lmIndex;
   misc.Bookmarks=Bookmarks;

   _SetDialogInfo(DIFFEDIT_CONST_MISC_INFO,misc,_ctlfile1);
}

static void diff_push_tag()
{
   diff_push_bookmark(auto wid, auto otherwid);
   int status=wid.goto_context_tag();
   if (status) {
      return;
   }

   otherwid.p_line=wid.p_line;
   otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
}

static void diff_push_tag_line(int linenum)
{
   diff_push_bookmark(auto wid,auto otherwid);

   otherwid.p_RLine = wid.p_RLine = linenum;
   wid.center_line();
   otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
}

static void diff_next_proc()
{
   wid := 0;
   otherwid := GetOtherWid(wid);

   otherwid._undo('S');
   wid._undo('S');

   typeless status=wid.next_proc();
   otherwid.p_line=wid.p_line;
   otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
}

static void diff_prev_proc()
{
   wid := 0;
   otherwid := GetOtherWid(wid);

   otherwid._undo('S');
   wid._undo('S');

   typeless status=wid.prev_proc();
   otherwid.p_line=wid.p_line;
   otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
}

static void diff_next_tag()
{
   wid := 0;
   otherwid := GetOtherWid(wid);

   otherwid._undo('S');
   wid._undo('S');

   typeless status=wid.next_tag();
   otherwid.p_line=wid.p_line;
   otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
}

static void diff_prev_tag()
{
   wid := 0;
   otherwid := GetOtherWid(wid);

   otherwid._undo('S');
   wid._undo('S');

   typeless status=wid.prev_tag();
   otherwid.p_line=wid.p_line;
   otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
}

static void diff_pop_bookmark()
{
   DIFF_MISC_INFO misc=_DiffGetMiscInfo();
   _str Bookmarks[];
   Bookmarks=misc.Bookmarks;
   if (Bookmarks._varformat()!=VF_ARRAY) {
      Bookmarks._makeempty();
   }
   if (!Bookmarks._length()) {
      _beep();
      return;
   }
   typeless line='';
   typeless col='';
   typeless leftedge='';
   typeless cursory='';
   parse Bookmarks[Bookmarks._length()-1] with line ',' col ',' leftedge \
                                               ',' cursory ',' auto lmIndex ;
   Bookmarks._deleteel(Bookmarks._length()-1);
   misc.Bookmarks = Bookmarks;
   _DiffSetMiscInfo(misc);

   wid := 0;
   otherwid := GetOtherWid(wid);

   otherwid._undo('S');
   wid._undo('S');

   wid.p_line=line;
   wid.p_col=col;
   wid.set_scroll_pos(leftedge,cursory);
   if ( isinteger(lmIndex) ) {
      wid._LineMarkerRemove((int)lmIndex);
   }

   otherwid.p_line=wid.p_line;
   otherwid.p_col=wid.p_col;
   otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
}

static void diff_undo_cursor()
{
   lindex := last_index('','C');
   pindex := prev_index('','C');
   _ctlfile2._undo('C');
   last_index(lindex,'C');prev_index(pindex,'C');
   _ctlfile1._undo('C');
   _DiffVscrollSetLast('');
   int YInLines=_ctlfile1.p_cursor_y intdiv _ctlfile1.p_font_height;
   vscroll1.p_value=_ctlfile1.p_line-YInLines;
   _DiffVscrollSetLast(_ctlfile1.p_line-YInLines);
   p_window_id=LastActiveEditWindowWID;
   wid := 0;
   OtherWid := GetOtherWid(wid);
   OtherWid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
   _DiffSetNeedRefresh(true);
   prev_index(0,'C');
   last_index(0,'C');
}

static void diff_select_line()
{
   otherwid := GetOtherWid(auto wid);
   otherwid._undo('S');
   wid._undo('S');
   wid.select_line();
}

static void diff_select_word()
{
   otherwid := GetOtherWid(auto wid);
   otherwid._undo('S');
   wid._undo('S');
   wid.select_word();
   otherwid.p_line = wid.p_line;
}

static void diff_select_subword()
{
   otherwid := GetOtherWid(auto wid);
   otherwid._undo('S');
   wid._undo('S');
   wid.select_subword();
   otherwid.p_line = wid.p_line;
}

static void diff_select_full_word()
{
   otherwid := GetOtherWid(auto wid);
   otherwid._undo('S');
   wid._undo('S');
   wid.select_full_word();
   otherwid.p_line = wid.p_line;
}

static void diff_select_whole_word()
{
   otherwid := GetOtherWid(auto wid);
   otherwid._undo('S');
   wid._undo('S');
   wid.select_whole_word();
   otherwid.p_line = wid.p_line;
}

static void diff_select_char()
{
   otherwid := GetOtherWid(auto wid);
   otherwid._undo('S');
   wid._undo('S');
   wid.select_char();
}

static void diff_deselect()
{
   if (!select_active()) return;
   otherwid := GetOtherWid(auto wid);
   wid._undo('S');
   otherwid._undo('S');
   wid.deselect();
}

static int GetOtherWid(int &wid)
{
   otherwid := 0;
   wid=p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   } else if ( wid==_ctlfile2 ) {
      otherwid=_ctlfile1;
   } else if ( wid==ctlcontextCombo1 ) {
      wid = _ctlfile1;
      otherwid=_ctlfile2;
   } else if ( wid==ctlcontextCombo2 ) {
      wid = _ctlfile2;
      otherwid=_ctlfile1;
   }
   return(otherwid);
}

static void diff_shift_selection_right()
{
   wid := 0;
   otherwid := GetOtherWid(wid);
   wid._undo('S');
   otherwid._undo('S');

   wid.shift_selection_right();

   AddUndoNothing(otherwid);
   _DiffSetNeedRefresh(true);
}

static void diff_shift_selection_left()
{
   wid := 0;
   otherwid := p_window_id.GetOtherWid(wid);
   wid._undo('S');
   otherwid._undo('S');

   wid.shift_selection_left();

   AddUndoNothing(otherwid);
   _DiffSetNeedRefresh(true);
}

static void diff_maybe_complete()
{
   wid := 0;
   otherwid := p_window_id.GetOtherWid(wid);
   wid._undo('S');
   otherwid._undo('S');

   wid.maybe_complete();
   otherwid.right();
   AddUndoNothing(otherwid);
   _DiffSetNeedRefresh(true);
}

static void diff_mou_select_word()
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   otherwid._undo('S');
   wid._undo('S');
   wid.mou_select_word();
   AddUndoNothing(otherwid);
}

static void diff_mou_select_line()
{
   otherwid := 0;
   wid := p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   otherwid._undo('S');
   wid._undo('S');
   wid.mou_select_line();
   AddUndoNothing(otherwid);
}

static void diff_rubout()
{
   if (OnImaginaryLine()) {
      return;
   }
   if (select_active() && _within_char_selection()) {
      //DiffMessage('Mark deletes not yet available');
      diff_linewrap_delete_char('delete-selection');
      return;
   }
   if (p_col==1) {
      return;
   }
   wid := 0;
   otherwid := p_window_id.GetOtherWid(wid);
   wid._undo('S');
   otherwid._undo('S');

   wid.rubout();
   otherwid.left();
   AddUndoNothing(otherwid);

   _DiffSetNeedRefresh(true);
}

static int OnImaginaryLine()
{
   return(_lineflags()&NOSAVE_LF);
}

static void diff_linewrap_rubout()
{
   if (OnImaginaryLine()) {
      return;
   }
   if (select_active() && _within_char_selection()) {
      diff_linewrap_delete_char('delete-selection');
      return;
   }
   wid := 0;
   otherwid := p_window_id.GetOtherWid(wid);
   orig_numlines := p_Noflines;
   wid._undo('S');
   otherwid._undo('S');

   orig_line := "";
   if (!wid.up()) {
      wid.get_line(orig_line);wid.down();
   }
   wid.linewrap_rubout();
   if (wid.p_Noflines<orig_numlines) {
      MaybeMakeLineReal();
      DiffInsertImaginaryBufferLine();
      up();_end_line();
      AddUndoNothing(otherwid);
      otherwid.p_line=wid.p_line;
      wid.p_col=length(orig_line)+1;
   }
   AddUndoNothing(otherwid);

   _DiffSetNeedRefresh(true);
}

static void diff_multi_delete(...)
{
   if ((arg(1)==''||p_word_wrap_style&WORD_WRAP_WWS) && OnImaginaryLine()) {
      if (p_col>=length(_expand_tabsc())) return;
   }
   if (p_col > _text_colc()) {
      if (!down()) {
         if (OnImaginaryLine()) {
            if (arg(1)=='' ||
                arg(1)=='linewrap-delete-char'||
                arg(1)=='delete-char') {
               DiffMessageBox('Cannot split Imaginary line');
               up();
               return;
            }
         }
         up();
      }
   }

   wid := 0;
   otherwid := p_window_id.GetOtherWid(wid);
   orig_numlines := p_Noflines;
   wid._undo('S');
   otherwid._undo('S');

   origline := wid.p_line;
   onlast := OnLastLine();
   int isimaginary=wid._lineflags()&NOSAVE_LF;
   if (isimaginary && !DialogIsDiff()) {
      return;
   }
   oldmodify := false;
   oldwid := 0;
   switch (arg(1)) {
   case 'cut':
      wid.cut();break;
   case 'linewrap-delete-char':
      wid.linewrap_delete_char();break;
   case 'delete-char':
      wid.linewrap_delete_char();break;
   case 'cut-line':
      oldmodify=wid.p_modify;
      wid.cut_line();
      if (isimaginary) wid.p_modify=oldmodify;
      break;
   case 'delete-line':
      oldmodify=p_modify;
      wid._delete_line();
      if (isimaginary) p_modify=oldmodify;
      break;
   case 'delete-selection':
      wid.delete_selection();break;
   default:
      wid._begin_select();
      oldwid=p_window_id;p_window_id=wid;
      _delete_selection();
      p_window_id=oldwid;
      wid.keyin(last_event());
      break;
   }

   i := 0;
   old_col := 0;
   cur_num_lines := 0;
   if (wid.p_Noflines<orig_numlines) {
      cur_num_lines=wid.p_Noflines;
      otherwid.p_line=origline;
      if (!wid.OnLastLine()) {
         otherwid.p_line=wid.p_line;
      }
      wasModified := p_modify;
      wasOtherModified := otherwid.p_modify;
      _UndoPushModify(otherwid);

      for (i=1;i<=orig_numlines-cur_num_lines;++i) {
         old_col=p_col;
         if (!otherwid.OnImaginaryLine()) {
            if (!onlast) {
               up();
            }
            //InsertImaginaryLine();
            DiffInsertImaginaryBufferLine();
            if (!onlast) {
               down();
            }
            otherwid.set_line_inserted();
            otherwid.down();
            AddUndoNothing(otherwid);
         }else{
            AddUndoNothing(wid);
            wid=p_window_id;
            p_window_id=otherwid;
            oldmodify=p_modify;
            isimaginary=_lineflags()&NOSAVE_LF;
            _delete_line();
            if (isimaginary) {
               p_modify=oldmodify;
            }
            p_window_id=wid;
         }
         p_col=old_col;
      }
      _UndoPopModify(otherwid);
      otherwid.p_line=wid.p_line;
   }
   if (_lineflags()&MODIFY_LF) {
      otherwid._lineflags(MODIFY_LF,MODIFY_LF);
   }
   AddUndoNothing(otherwid);

   otherwid.set_scroll_pos(otherwid.p_left_edge,wid.p_cursor_y);
   _DiffSetNeedRefresh(true);
   _DiffSetupScrollBars();
}

static void diff_linewrap_delete_char(...)
{
   if (select_active()) {
      diff_multi_delete('delete-selection');
      return;
   }
   diff_multi_delete('linewrap-delete-char');
}

static void diff_delete_char()
{
   if (select_active()) {
      diff_multi_delete('delete-selection');
      return;
   }
   diff_multi_delete('delete-char');
}

static void diff_cut_line()
{
   if (select_active()) {
      //DiffMessage('Mark deletes not yet available');
      diff_multi_delete('cut');
      return;
   }
   diff_multi_delete('cut-line');
}

static void diff_join_line()
{
   lf := 0;
   wid := 0;
   otherwid := GetOtherWid(wid);
   origNumLines := p_Noflines;
   typeless status=down();
   if (!status) {
      lf=_lineflags();
      up();
   }
   if (lf&NOSAVE_LF) {
      DiffMessageBox('Cannot join Imaginary line');
      return;
   }
   wid._undo('S');
   otherwid._undo('S');
   join_line();
   save_pos(auto p);
   if (origNumLines!=p_Noflines) {
      int nlines=otherwid.GetNumberOfImaginaryLines(1);
      if (!nlines) {
         //InsertImaginaryLine();
         DiffInsertImaginaryBufferLine();
      }else{
         otherwid._delete_line();
      }
   }
   restore_pos(p);
   AddUndoNothing(otherwid);
}

static void diff_delete_line()
{
   if (select_active()) {
      //DiffMessage('Mark deletes not yet available');
      diff_multi_delete('delete-selection');
      return;
   }
   diff_multi_delete('delete-line');
}

static void AddUndoNothing(int wid)
{
   // Setting lineflags to themselves will set undo information
   origWID := p_window_id;
   p_window_id = wid;

   oldmodify := p_modify;
   oldflags := _lineflags();

   // Toggle MODIFY_LF to be sure some undo
   // information is created.
   if ( oldflags&MODIFY_LF ) {
      _lineflags(0,MODIFY_LF);
      _lineflags(MODIFY_LF,MODIFY_LF);
   } else {
      _lineflags(MODIFY_LF,MODIFY_LF);
      _lineflags(0,MODIFY_LF);
   }
   p_modify = oldmodify;
   p_window_id = origWID;
}

static _str GetClipboardType(...)
{
   retval := "";
   noflines := "";
   view_id := 0;
   get_window_id(view_id);
   int status=find_view('.clipboards');
   if ( ! status ) {
      line := "";
      get_line(line);
      mark_name := "";
      parse line with ':' mark_name noflines . ;
      if( !pos(' 'mark_name' ',' LINE CHAR BLOCK ') ) {
         retval='invalid';
      } else {
         retval=mark_name' 'noflines;
      }
   } else {
      // This should never happen unless clipbd.e has
      // not been loaded.
      retval='No clipboards';
   }
   clipbd_view_id := 0;
   get_window_id(clipbd_view_id);
   activate_window(view_id);
   arg(1)=noflines;
   return(retval);
}

static void diff_next_window(bool find_backward=false)
{
   if ( _jaws_mode() ) {
      if ( find_backward ) {
         _prev_control();
      }else{
         _next_control();
      }
   }else{
      wid := 0;
      otherwid := GetOtherWid(wid);
      otherwid._set_focus();
   }
}

static void diff_append_to_clipboard()
{
   wid := 0;
   otherwid := GetOtherWid(wid);

   wid._undo('S');
   otherwid._undo('S');

   typeless was_selected=select_active();
   wid.append_to_clipboard();
   //4:27pm 4/14/1998
   //Only want this if there was a selection
   if (was_selected) {
      AddUndoNothing(otherwid);
   }
}

static void diff_copy_to_clipboard()
{
   wid := 0;
   otherwid := GetOtherWid(wid);

   wid._undo('S');
   otherwid._undo('S');

   typeless was_selected=select_active();
   wid.copy_to_clipboard();
   //4:27pm 4/14/1998
   //Only want this if there was a selection
   if (was_selected) {
      AddUndoNothing(otherwid);
   }
}

static void diff_copy_word()
{
   wid := 0;
   otherwid := GetOtherWid(wid);
   if (NoSaveLine(p_line)) {
      _beep();
      return;
   }

   bline := 0;
   eline := 0;
   typeless markid=_alloc_selection();
   WillJumpLine := false;
   save_pos(auto p);
   if (!pselect_word(markid)) {
      _begin_select(markid);
      bline=p_line;
      _end_select(markid);
      eline=p_line;
      p_line=bline;
      WillJumpLine=bline!=eline;
      if (WillJumpLine) {
         if (p_Noflines>p_line) {
            //We are not on the last line
            if (NoSaveLine(p_line+1)) {
               //The next line is an imaginary buffer line
               _free_selection(markid);
               _beep();
               restore_pos(p);
               return;//Blow out so we don't bring up the imaginary line
            }
         }
      }
   }
   restore_pos(p);
   _free_selection(markid);
   wid._undo('S');
   otherwid._undo('S');
   wid.copy_word();
   //4:27pm 4/14/1998
   //This seems to mess things up
   //AddUndoNothing(otherwid);
   otherwid.p_line=wid.p_line;
}

static int GetNumberOfImaginaryLines(int noflines)
{
   save_pos(auto p);
   i := count := 0;
   for (i=1;i<=noflines;++i) {
      if (_lineflags()&NOSAVE_LF) {
         ++count;
      }
      if (down()) {
         break;
      }
   }
   restore_pos(p);
   return(count);
}

static void diff_paste_replace_word()
{
   wid := 0;
   otherwid := GetOtherWid(wid);
   wid._undo('S');otherwid._undo('S');
   paste_replace_word();
   AddUndoNothing(otherwid);
}

static void diff_paste()
{
   wid := 0;
   otherwid := GetOtherWid(wid);
   orig_numlines := p_Noflines;
   wid._undo('S');otherwid._undo('S');

   typeless noflines_pasted='';//passed by reference to GetClipboardType
   typeless ctype=GetClipboardType(noflines_pasted);
   typeless type='';
   parse ctype with type . ;
   int noflines_imaginary=GetNumberOfImaginaryLines(noflines_pasted);
   moved := false;
   i := 0;
   lf := 0;
   if (noflines_imaginary>noflines_pasted) {
      for (i=1;i<=noflines_pasted;++i) {
         if (type=='LINE') {
            lf=_lineflags();
            if (lf&NOSAVE_LF) {
               _delete_line();
               moved=true;
            }
         }else{
            MaybeMakeLineReal();
         }
      }
   }else if (noflines_imaginary<=noflines_pasted) {
      //say('noflines_imaginary='noflines_imaginary);
      for (i=1;i<=noflines_imaginary;++i) {
         if (type=='LINE') {
            lf=_lineflags();
            if (lf&NOSAVE_LF) {
               _delete_line();
               moved=true;
            }
         }else{
            MaybeMakeLineReal();
         }
      }
   }
   typeless seltype='';
   SelSize := 0;
   if (wid.select_active()) {
      seltype=_select_type('','S');
      _begin_select();
      FirstLine := p_line;
      _end_select();
      LastLine := p_line;
      SelSize=LastLine-FirstLine;
      _select_type('','S',seltype);
      if (_select_type()=='LINE') {
         ++SelSize;
      }
   }
   if (moved && p_line!=p_Noflines) {
      up();
   }
   insert_after := ( (type=='CHAR') || (strip(upcase(def_line_insert))=='A') );
   origline := wid.p_line;
   origotherline := otherwid.p_line;
   if (DialogIsDiff()) {
      DiffTextChangeCallback(0,_ctlfile1.p_buf_id);
      DiffTextChangeCallback(0,_ctlfile2.p_buf_id);
   }
   wid.paste();AddUndoNothing(otherwid);
   if (DialogIsDiff()) {
      DiffTextChangeCallback(1,_ctlfile1.p_buf_id);
      DiffTextChangeCallback(1,_ctlfile2.p_buf_id);
   }
   cur_numlines := wid.p_Noflines;
   if (cur_numlines>orig_numlines) {
      for (i=1;i<=cur_numlines-orig_numlines/*-noflines_imaginary*/;++i) {
         //otherwid.InsertImaginaryLine();
         otherwid.DiffInsertImaginaryBufferLine();
         if (!insert_after) otherwid.up();
         AddUndoNothing(otherwid);
         if (!insert_after) otherwid.down();
      }
   }else if (cur_numlines<orig_numlines) {
      for (i=1;i<=(orig_numlines-cur_numlines)-SelSize;++i) {
         //InsertImaginaryLine();
         otherwid.DiffInsertImaginaryBufferLine();
         if (!insert_after) otherwid.up();
         otherwid.AddUndoNothing(otherwid);
         if (!insert_after) otherwid.down();
      }
      if (SelSize>0) {
         save_pos(auto p);
         for (i=0;i<SelSize;++i) {
            DiffInsertImaginaryBufferLine();
         }
         restore_pos(p);
      }
   }
   //fsay('origline='origline' wid.p_line='wid.p_line' noflines_pasted='noflines_pasted' p_Noflines='p_Noflines);
   //say('origline='origline' wid.p_line='wid.p_line' noflines_pasted='noflines_pasted' p_Noflines='p_Noflines);
   if (DialogIsDiff()) {
      if (noflines_pasted=='') {
         DiffUpdateColorInfo(_ctlfile1,_ctlfile1.p_line,_ctlfile2,_ctlfile2.p_line,0,1,true,false);
      }else{
         for (i=origline+1;i<wid.p_line+noflines_pasted-1;++i) {
            //fsay('diffing i='i);
            //say('diffing i='i);
            DiffUpdateColorInfo(_ctlfile1,i,_ctlfile2,i,0,1,true,false);
         }
      }
   }
   otherwid.p_line=wid.p_line;
   otherwid.set_scroll_pos(otherwid.p_left_edge,wid.p_cursor_y);
   _DiffSetupScrollBars();
}

static void diff_close_form()
{
   if ( _DiffGetCloseMissing()!=1 ) {
      _ctlclose.call_event(_ctlclose,LBUTTON_UP);
   }else{
      wid := _find_control("ctlclose");
      if ( wid ) {
         wid.call_event(wid,LBUTTON_UP);
      } else {
         p_active_form._delete_window();
      }
   }
}

static void diff_cua_select()
{
   wid := 0;
   otherwid := GetOtherWid(wid);
   in_cua_select=true;_argument=1;
   cua_select();
   _argument="";
   in_cua_select=false;
   AddUndoNothing(otherwid);
   _dont_use_diff_command=1;
   otherwid.p_line=wid.p_line;
   _dont_use_diff_command=0;
}

#pragma option(deprecateconst,off)

static void diff_maybe_deselect()
{
   if (in_cua_select) return;
   if (select_active()) {
      if ( _select_type('','U')!='P') {
         diff_deselect();
      }
   }
}
static void addCopyButtonsToCurrentLines()
{
   copyLeftType := _GetDialogInfoHt("copyLeftType",_ctlfile1);
   copyRightType := _GetDialogInfoHt("copyRightType",_ctlfile1);
   _LineMarkerAdd(_ctlfile1,_ctlfile1.p_line,false,1,_pic_merge_right,copyRightType,"Copy this block to the other file");
   _LineMarkerAdd(_ctlfile2,_ctlfile2.p_line,false,1,_pic_merge_left,copyLeftType,"Copy this block to the other file");
}

static bool didLineCopy(_str origEventName)
{
   wid := 0;
   otherwid := GetOtherWid(wid);
   origLineNumber := p_line;
   _LineMarkerFindList(auto list1,p_window_id,p_line,VSNULLSEEK,true);
   widCopyRight := _find_control("_ctlcopy_right");
   widCopyRightLine := _find_control("_ctlcopy_right_line");
   widCopyLeft := _find_control("_ctlcopy_left");
   widCopyLeftLine := _find_control("_ctlcopy_left_line");
   diff_label_copy_buttons(widCopyRight, widCopyRightLine,
                           widCopyLeft,  widCopyLeftLine);
   INTARRAY list2;
   if (origEventName=="C-S-LBUTTON-DOWN") {
      // If we were on the bitmap, we have to get rid of it when we're done
      // because it no longer will work because the first line will not 
      // have lineflags set
      if ( list1._length()>0 && _lineflags()&(VSLF_NOSAVE|VSLF_MODIFY|VSLF_INSERTED_LINE) ) {
         _LineMarkerFindList(list2,otherwid,otherwid.p_line,VSNULLSEEK,true);
         if (list2._length()>0) {
            deselect();
         }
      }
      buttonWID := (p_window_id==_ctlfile1)?_ctlcopy_right_line:_ctlcopy_left_line;
      if (buttonWID.p_enabled) {
         buttonWID.call_event(buttonWID,LBUTTON_UP);
      }
      if (!_iswindow_valid(wid)) return true;
      if ( _lineflags()&(VSLF_NOSAVE|VSLF_MODIFY|VSLF_INSERTED_LINE) ) {
         addCopyButtonsToCurrentLines();
      }
      return true;
   } else if (list1._length()>0) {

      deselect();
      buttonWID := (p_window_id==_ctlfile1)?widCopyRight:widCopyLeft;
      flagsBeforeCopy := _lineflags();
      if (buttonWID!=0 && buttonWID.p_enabled) {
         status := buttonWID.call_event(buttonWID,LBUTTON_UP);
      }
      if (!_iswindow_valid(wid)) return true;
      if (_iswindow_valid(otherwid)) {
         otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
      }
      return true;
   }
   return false;
}

static void diff_mou_click()
{
   wid := 0;
   otherwid := GetOtherWid(wid);
   wid._undo('s');
   otherwid._undo('s');
   origEventName := event2name(last_event());
   wid.mou_click();
   AddUndoNothing(otherwid);
   otherwid.p_line=wid.p_line;
   otherwid.p_col=wid.p_col;
   otherwid.refresh('W');
   _DiffSetNeedRefresh(true);

   int mx=mou_last_x('D');
   int my=mou_last_y('D');
   wx := wy := 0;
   _map_xy(p_window_id,0,wx,wy);
   mx-=wx;my-=wy;
   marginWidth := _lx2dx(SM_TWIP,_default_option('l'));

   //if (mx<=marginWidth) {
   if (mou_last_x() < _adjusted_windent_x()) {
      if ( didLineCopy(origEventName) ) {
         return;
      }
   }

   //otherwid.set_scroll_pos(otherwid.p_left_edge,wid.p_cursor_y);
   otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
   //AddUndoNothing(otherwid);

   if ( wid.p_mouse_pointer == MP_ARROW ) {
      DIFF_ALIGN align;
      if ( _lineflags()&NOSAVE_LF ) {
         return;
      }
      long setSeekPos = 0;
      _save_pos2(auto p);
      _begin_line();
      if ( wid.p_name=="_ctlfile1" ) {
         setSeekPos = align.pos1 = _QROffset();
         align.lineNum1 = p_RLine;
         align.pos2 = _GetDialogInfoHt("pending2");
         _SetDialogInfoHt("pending2",null);
      }else if (wid.p_name=="_ctlfile2") {
         align.pos1 = _GetDialogInfoHt("pending1");
         setSeekPos = align.pos2 = _QROffset();
         align.lineNum2 = p_RLine;
         _SetDialogInfoHt("pending1",null);
      }
      _restore_pos2(p);
      wid.p_mouse_pointer = MP_DEFAULT;
      addToGlobalAligns(align);
      rediff();

      // Get scroll positions right
      _ctlfile1.top(); 
      _ctlfile2.top(); 
      if ( wid.p_name=="_ctlfile1" ) {
         _ctlfile1._GoToROffset(setSeekPos);
         _ctlfile2.p_line = p_line;
      }else if (wid.p_name=="_ctlfile2") {
         _ctlfile2._GoToROffset(setSeekPos);
         _ctlfile1.p_line = p_line;
      }

      //_ctlfile1._BlastUndoInfo();
      //_ctlfile2._BlastUndoInfo();
      if ( LastActiveEditWindowWID ) {
         LastActiveEditWindowWID._set_focus();
      }
   }
}

/**
 * Get line the specified alignment is on 
 *  
 * @param wid Window ID that <b>markid</b> is in
 * @param markid Mark ID that represents this alignment
 * 
 * @return int 
 */
static void getAlignmentLineAndSeek(int wid, int markid, int &lineNum, long &seekPos)
{
   seekPos = 0;
   origWID := p_window_id;
   p_window_id = wid;
   _save_pos2(auto p);
   _begin_select(markid);
   seekPos = _QROffset();
   lineNum = p_line;
   _restore_pos2(p);
   p_window_id = origWID;
}

/** 
 * Get alignments from the mark ids. Even though we have stored 
 * DIFF_ALIGN structs in _GetDialogInfoHt("alignments"), we have 
 * to get these from the selections because the files may have 
 * been edited and the line positions might be out of date. 
 * 
 * @param alignmentList returns list of alignments with 
 *                      positiosn and markids set properly.
 */
static void getAlignments(DIFF_ALIGN (&alignmentList)[])
{
   DIFF_ALIGN alignments[];
   alignments = _GetDialogInfoHt("alignments");
   len := alignments._length();
   for (i:=0;i<len;++i) {
      getAlignmentLineAndSeek(_ctlfile1,alignments[i].markid1,auto lineNum1, auto seekPos1);
      getAlignmentLineAndSeek(_ctlfile2,alignments[i].markid2,auto lineNum2, auto seekPos2);
      alignmentList[i].pos1 = seekPos1;
      alignmentList[i].pos2 = seekPos2;
      alignmentList[i].markid1 = alignments[i].markid1;
      alignmentList[i].markid2 = alignments[i].markid2;
      alignmentList[i].lineNum1 = lineNum1;
      alignmentList[i].lineNum2 = lineNum2;
   }
}

/** 
 * Get the alignments, and then remove any that are colliding. 
 * This can happen when there are two marks and lines are 
 * deleted.  The marks move and can be cascaded onto the same 
 * line. 
 */
static void reduceAlignments()
{
   DIFF_ALIGN alignments[];

   // Have to call getAlignments here because if we use what's in 
   // _GetDialogInfoHt we may get outdated line positions because
   // the user may have edited the file.
   getAlignments(alignments);
   int reductionTable:[];


   // Algorithm: If the left line is not an index in the hash table, 
   // store the current index with left line number as the hash table
   // index.

   // If the left line is an index in the table, add the value stored (index)
   // to delList, then store the current entry in the hasntable. This way
   // when items collide, the most recently added one is kept.
   // 
   INTARRAY delList;
   len := alignments._length();
   for (i:=0;i<len;++i) {
      if ( reductionTable:[alignments[i].pos1]==null ) {
         reductionTable:[alignments[i].pos1] = i;
      } else {
         ARRAY_APPEND(delList,reductionTable:[alignments[i].pos1]);
         reductionTable:[alignments[i].pos1] = i;
      }
   }

   // Repeat the above algorithm, but us the right line number as the 
   // hash table index.
   reductionTable = null;
   for (i=0;i<len;++i) {
      if ( reductionTable:[alignments[i].pos2]==null ) {
         reductionTable:[alignments[i].pos2] = i;
      } else {
         ARRAY_APPEND(delList,reductionTable:[alignments[i].pos2]);
         reductionTable:[alignments[i].pos2] = i;
      }
   }
   
   // Finally, remove the collided items.  Go through delList backwards
   // (so the indexes do not shift) and free the selections and
   // delete the items from the array
   len = delList._length();
   for (i=len-1;i>=0;--i) {
      _free_selection(alignments[delList[i]].markid1);
      _free_selection(alignments[delList[i]].markid2);
      alignments._deleteel(delList[i]);
   }
   elimnateCrossovers(alignments);
   // Store the reduced table
   _SetDialogInfoHt("alignments",alignments);
}

static void elimnateCrossovers(DIFF_ALIGN (&alignments)[])
{
   // Alignments are added one at a time so we only have
   // to check the last one to see if it is criss-crossed.
   len := alignments._length();
   if ( len<2 ) return;
   lastAlignment := alignments[len-1];
   INTARRAY delList;
   for (i:=len-2;i>=0;--i) {
      if ( (alignments[i].pos1 > lastAlignment.pos1 && 
            alignments[i].pos2 < lastAlignment.pos2)
         ||(alignments[i].pos1 < lastAlignment.pos1 && 
            alignments[i].pos2 > lastAlignment.pos2)
            ) {
         ARRAY_APPEND(delList,i);
      }
   }
   len = delList._length();
   for (i=len-1;i>=0;--i) {
      alignments._deleteel(delList[i]);
   }
}

/** 
 * Set a mark on line <b>markpos</b> in window <b>wid</b> 
 * 
 * @param wid ID of window to set mark in
 * @param markid Mark ID returned from _alloc_selection
 * @param markpos line number to put mark on
 */
static void setAlignmentMark(int wid,int markid,long markpos)
{
   origWID := p_window_id;
   p_window_id = wid;
   save_pos(auto p);
   if ( isnumber(markpos) ) {
      _GoToROffset(markpos);
   } else {
      p_RLine = (int)markpos;
   }
   _select_line(markid);
   restore_pos(p);
   p_window_id = origWID;
}

/** 
 * Set an alignment in the diff form 
 * 
 * @param alignment DIFF_ALIGN structure with the pos1 and pos2
 *                  fields filled in.  This function will fill
 *                 in the markid fields.
 */
static void setAlignment(DIFF_ALIGN &alignment)
{
   alignment.markid1 = _alloc_selection('B');
   alignment.markid2 = _alloc_selection('B');
   setAlignmentMark(_ctlfile1,alignment.markid1,alignment.pos1);
   setAlignmentMark(_ctlfile2,alignment.markid2,alignment.pos2);
}

/**
 * Add <b>alignment</b> to the table of alignments stored on the 
 * dialog 
 * 
 * @param alignment DIFF_ALIGN structure with the pos1 and pos2 
 *                  fields filled in.  This function will call
 *                  <b>setAlignment</b> to fill in the markid
 *                  fields.
 */
static void addToGlobalAligns(DIFF_ALIGN &alignment)
{
   DIFF_ALIGN alignments[] = _GetDialogInfoHt("alignments");
   setAlignment(alignment);
   alignments :+= alignment;
   _SetDialogInfoHt("alignments",alignments);

   alignmentTypes2 := _GetDialogInfoHt("alignments");


   reduceAlignments();

   alignmentTypes2 = _GetDialogInfoHt("alignments");
}

static void diff_mou_extend_selection()
{
   wid := 0;
   otherwid := GetOtherWid(wid);
   wid._undo('s');
   otherwid._undo('s');
   wid.mou_extend_selection();
   AddUndoNothing(otherwid);
   otherwid.p_line=wid.p_line;
   otherwid.p_col=wid.p_col;
   otherwid.refresh('W');
   _DiffSetNeedRefresh(true);
   //otherwid.set_scroll_pos(otherwid.p_left_edge,wid.p_cursor_y);
   otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
   //AddUndoNothing(otherwid);
}

static int MaybeSaveFile(bool InMem=false,_str controlNameSuffix="")
{
   DIFF_MISC_INFO misc=_DiffGetMiscInfo();
   if (p_modify) {
      controlName := '1';
      if (p_name=='_ctlfile2save' || p_name=='_ctlfile2') {
         controlName = '2';
      }
      buf_name := "";

      // If we stored a buffer ID for this temp p_buf_name, this was an untitled
      // buffer and we want to prompt them to save it with the original buffer
      // ID
      buf_id := _GetDialogInfoHt(p_buf_name, _ctlfile1);
      if (buf_id!=null) {
         buf_name = "Untitled <"buf_id">";
         _SetDialogInfoHt("onlyOverlay",1,_ctlfile2);
      } else {
         buf_name = _diffGetFilenameFromDialog(misc,controlName);
         if ( buf_name=="" ) {
            buf_name=_DiffGetDocumentName();
            if (buf_name=="") {
               buf_name=p_buf_name;
            }
         }
      }
      int result=prompt_for_save(nls("Do you wish to save changes to '%s'",buf_name));
      wid := 0;
      name := "";
      labelname := "";
      typeless preserve1='';
      typeless preserve2='';
      parse misc.PreserveInfo with preserve1 preserve2;
      switch (result) {
      case IDNO:
#if 0
         labelname=p_name'label';
         wid=p_active_form._find_control(labelname);
         if (wid) {
            if (InMem) {
               // 4:52:03 PM 1/19/2003
               // If the file is in memory we want to undo back to where we were.
               // The old method of checkin the dialog is no longer good enough
               // because we can't count on the name of the label
               if (p_undo_steps) {
                  while (_undo('C')!=NOTHING_TO_UNDO_RC);
                  //This is to be sure that we avoid those rare cases
                  //where modify is on and after all steps are undone
                  //if the user has specified the -preserve option(s).
                  //Also, this will bail'em out if they did not set undo
                  //high enough
                  if (p_window_id==_ctlfile1 && preserve1) {
                     p_modify=false;
                  }
                  if (p_window_id==_ctlfile2 && preserve2) {
                     p_modify=false;
                  }
               }
               clear_message();
            }
         }
#endif
         if (!DialogIsDiff()) {
            return(2);
         }else{
            return(0);
         }
      case IDCANCEL:
         return(COMMAND_CANCELLED_RC);
      case IDYES:
         preserve1=strip(preserve1);
         if (preserve1=='') {
            preserve1=0;
         }
         preserve2=strip(preserve2);
         if (preserve2=='') {
            preserve2=0;
         }
         if (p_window_id==_ctlfile1 && preserve1) {
            return(0);
         }
         if (p_window_id==_ctlfile2 && preserve2) {
            return(0);
         }
         name=substr(p_name,1,9);
         wid=p_active_form._find_control(name'save');
         if (wid) {
            typeless status=wid.call_event(wid,LBUTTON_UP);
            if (DialogIsDiff()) {
               return(status);
            }else{
               return(1);
            }
         }
         return(1);
      }
   }
   return(0);
}

/**
 * 
 * Gets filename of buffer <B>bufid</B>
 * 
 * @param int bufid buffer id to get filename of
 * 
 * @return _str filename of buffer <B>bufid</B>
 */
_str GetFilenameFromBufId(int bufid)
{
   orig_view_id := p_window_id;
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   int origbid=p_buf_id;
   int status=load_files('+bi 'bufid);
   if (status) {
      load_files('+bi 'origbid);
      p_window_id=orig_view_id;
      return('');
   }
   _str filename=p_buf_name;
   load_files('+bi 'origbid);
   p_window_id=orig_view_id;
   return(filename);
}

int _ctlclose.lbutton_up()
{
   DIFF_MISC_INFO misc=_DiffGetMiscInfo();
   _str bufInfo1=_GetDialogInfo(DIFFEDIT_CONST_BUFFER_INFO1,_ctlfile1);
   _str bufInfo2=_GetDialogInfo(DIFFEDIT_CONST_BUFFER_INFO2,_ctlfile1);
   bufid1 := file1inmem := file1readonly := bufid2 := file2inmem := file2readonly := "";

   if ( bufInfo1==null ) {
      return(0);
   }
   parse bufInfo1 with bufid1 file1inmem file1readonly;
   if ( bufInfo2==null ) {
      return(0);
   }
   parse bufInfo2 with bufid2 file2inmem file2readonly;

   typeless status=0;
   if (DialogIsDiff()) {
      status=_ctlfile1.MaybeSaveFile((int)file1inmem!=0);
      if (status) {
         return(status);
      }
   }
   SavedFile2 := 0;
   status=_ctlfile2.MaybeSaveFile((int)file2inmem!=0);
   if (!status) {
      SavedFile2=1;
   }else{
      if (status==2) {
         SavedFile2=2;
      }else if (status==1) {
         SavedFile2=1;
      }else return(status);
   }

   if (_GetDialogInfo(DIFFEDIT_CONST_HAS_MODIFY)) {
      if (_GetDialogInfo(DIFFEDIT_CONST_FILE1_MODIFY)) {
         _ctlfile1.p_modify=true;
      }

      if (_GetDialogInfo(DIFFEDIT_CONST_FILE2_MODIFY)) {
         _ctlfile2.p_modify=true;
      }
   }

   _str filename1=_ctlfile1.p_buf_name;
   _str filename2=_ctlfile2.p_buf_name;

   if (misc.WholeFileBufId1>-1) {
      filename1=GetFilenameFromBufId(misc.WholeFileBufId1);
   }
   if (misc.WholeFileBufId2>-1) {
      filename2=GetFilenameFromBufId(misc.WholeFileBufId2);
   }

   file1datemismatch := (misc.File1Date!=_file_date(_ctlfile1.p_buf_name,'B'));
   file2datemismatch := (misc.File2Date!=_file_date(_ctlfile2.p_buf_name,'B'));

   if (misc.RefreshTagsOnClose &&
       (file1datemismatch || file2datemismatch) ) {
      _nocheck _control tree1;
      if (_iswindow_valid(misc.DiffParentWID) &&
          misc.DiffParentWID.p_name=='_difftree_output_form') {
         state := 0;
         misc.DiffParentWID.tree1._TreeGetInfo(misc.TagParentIndex1,state);
         if (state>0) {
            if (misc.WholeFileBufId1>-1) {
               bufid1=misc.WholeFileBufId1;
            }else{
               bufid1=_ctlfile1.p_buf_id;
            }
            if (misc.WholeFileBufId2>-1) {
               bufid2=misc.WholeFileBufId2;
            }else{
               bufid2=_ctlfile2.p_buf_id;
            }
            _ctlfile1._DiffRemoveImaginaryLines();
            _ctlfile2._DiffRemoveImaginaryLines();
            misc.DiffParentWID._DiffExpandTags2(bufid1,bufid2,misc.TagParentIndex1,misc.TagParentIndex2,'+bi','+bi');
         }
      }
   }
   if (SavedFile2) {
      p_active_form._delete_window(SavedFile2);
      return(SavedFile2);
   }

   p_active_form._delete_window(COMMAND_CANCELLED_RC);
   return(COMMAND_CANCELLED_RC);
}

int _DiffShowComment()
{
   DIFF_MISC_INFO misc=_DiffGetMiscInfo();
   int wid=show('_showbuf_form');
   if (!wid) {
      return(0);
   }
   _nocheck _control list1;
   wid.p_caption='Comment';
   wid.list1._delete_line();
   wid.list1._insert_text(strip(misc.Comment,'B','"'));
   _modal_wait(wid);
   return(0);
}

int _ctlok.lbutton_up()
{
   typeless pfn=0;
   typeless status=0;
   typeless result=0;
   int vf=p_user._varformat();
   if (p_user!='' && (vf==VF_FUNPTR) ||
       (vf==VF_LSTR && substr(p_user,1,1))) {
      pfn=p_user;
      status=(*pfn)();
      return(status);
   }
   if (_ctlfile2.p_modify) {
      result=prompt_for_save(nls("Do you wish to save changes to '%s'?", _ctlfile2.p_buf_name));
      if (result==IDYES) {
         _project_disable_auto_build(true);
         _ctlfile2.p_AllowSave=true;
         _ctlfile2.save("+n");
         _project_disable_auto_build(false);
      }else if (result==IDCANCEL) {
         return(0);
      }
   }
   p_active_form._delete_window(0);
   return(0);
}

void _ctlundo.lbutton_up()
{
   if (DialogIsDiff()) {
      diff_undo_cursor();
   }
}
static void GetFileOrBuffer(_str &Label)
{
   //Need to trim off (File) or (Buffer) (maybe a modified indicator) from label
   lp := lastpos('(',p_caption);
   if (!lp) {//Filename not really there yet
      Label='';
      return;
   }
   str := substr(p_caption,lp);
   p_caption=substr(p_caption,1,lp-1);
   Label=str;
}

static void DiffShrinkFilename(_str filename, int width)
{
   //Need to trim off (File) or (Buffer) (maybe a modified indicator) from label
   lp := lastpos('(',p_caption);
   if (!lp) {//Filename not really there yet
      return;
   }
   str := "";
   GetFileOrBuffer(str);
   p_caption=_ShrinkFilename(filename,width-_text_width(str)):+str;
}

_command void cmd_message_box(_str msg="") name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   _message_box(nls("%s",msg));
}

int _OnUpdate_diff_toggle_intraline_color(CMDUI &cmdui,int target_wid,_str command)
{
   if (!target_wid) return MF_GRAYED;
   DIFF_MISC_INFO misc=_DiffGetMiscInfo();
   if (misc.IntraLineIsOff==1) {
      return(MF_ENABLED);
   }else if (misc.IntraLineIsOff==0) {
      return(MF_ENABLED|MF_CHECKED);
   }
   return(MF_ENABLED);
}

static void diff_toggle_intraline_color()
{
   DIFF_MISC_INFO misc=_DiffGetMiscInfo();
   if (misc.IntraLineIsOff==1) {
      misc.IntraLineIsOff=0;
      DiffIntraLineColoring(1,_ctlfile1.p_buf_id);
      DiffIntraLineColoring(1,_ctlfile2.p_buf_id);
   }else{
      misc.IntraLineIsOff=1;
      DiffIntraLineColoring(0,_ctlfile1.p_buf_id);
      DiffIntraLineColoring(0,_ctlfile2.p_buf_id);
   }
   _SetDialogInfo(DIFFEDIT_CONST_MISC_INFO,misc,_ctlfile1);
   _ctlfile1.refresh('W');
   _ctlfile2.refresh('W');
}

static int GetLineStatus(int leftWID, int rightWID)
{
   int flag1=leftWID._lineflags();
   int flag2=rightWID._lineflags();
   if ( (!(flag1&MODIFY_LF) && !(flag1&INSERTED_LINE_LF)) &&
        (!(flag2&MODIFY_LF) && !(flag2&INSERTED_LINE_LF))) {
      return(MATCHING_LINE);
   }
   // Have to check del/ins first.  A line could be inserted, and then modified
   // This could cause us to delete a bigger block than the user would figure.
   if (flag1&NOSAVE_LF) {
      return(DELETED_LINE);
   }
   if (flag2&NOSAVE_LF) {
      return(INSERTED_LINE);
   }
   if ( (flag1&MODIFY_LF) || (flag2&MODIFY_LF) ) {
      return(CHANGED_LINE);
   }

   if (flag1&(NOSAVE_LF|INSERTED_LINE_LF) &&
       flag2&(NOSAVE_LF|INSERTED_LINE_LF)) {
      //12:05pm 6/11/1999
      //Funny merge case with soft collision
      return(INSERTED_LINE);
   }

   //message('flag1='flag1' flag2='flag2' _ctlfile1.p_line='_ctlfile1.p_line' _ctlfile2.p_line='_ctlfile2.p_line);
   //_message_box(nls("How did I get here"));
   return(0);
}

int def_diff_next_hack=0;

static _str GetFlags(int OrigLineFlag,.../*MergeDialog*/)
{
   typeless list='';
   if (def_diff_next_hack) {
      switch (OrigLineFlag) {
      case MATCHING_LINE:
         list=INSERTED_LINE|DELETED_LINE;break;
      case INSERTED_LINE:
         list=DELETED_LINE;break;
      case CHANGED_LINE:
         list=INSERTED_LINE|DELETED_LINE;break;
      case DELETED_LINE:
         list=INSERTED_LINE;break;
      }
   }
   if (arg(2)=='') {
      switch (OrigLineFlag) {
      case MATCHING_LINE:
         list=INSERTED_LINE|CHANGED_LINE|DELETED_LINE;break;
      case INSERTED_LINE:
         list=CHANGED_LINE|DELETED_LINE;break;
      case CHANGED_LINE:
         list=INSERTED_LINE|DELETED_LINE;break;
      case DELETED_LINE:
         list=INSERTED_LINE|CHANGED_LINE;break;
      }
   }else{
      switch (OrigLineFlag) {
      case MATCHING_LINE:
         list=INSERTED_LINE|CHANGED_LINE|DELETED_LINE;break;
      case INSERTED_LINE:
         list=DELETED_LINE;break;
      case CHANGED_LINE:
         list=INSERTED_LINE|DELETED_LINE;break;
      case DELETED_LINE:
         list=INSERTED_LINE|CHANGED_LINE;break;
      }
   }
   return(list);
}

static void diff_end_line()
{
   wid := 0;
   otherwid := p_window_id.GetOtherWid(wid);
   wid._undo('S');
   otherwid._undo('S');
   if (!(otherwid._lineflags()&NOSAVE_LF)) {
      wid.end_line();
      otherwid.end_line();
   }else{
      diff_maybe_deselect_command(end_line);
   }
}

static int FlagTable[]={
   INSERTED_LINE|CHANGED_LINE|DELETED_LINE,//Matching line
   CHANGED_LINE|DELETED_LINE,
   INSERTED_LINE|DELETED_LINE,
   0,//These are in hex, so there isn't a 3
   INSERTED_LINE|CHANGED_LINE
};

static int NoChangeFlagTable[]={
   INSERTED_LINE|DELETED_LINE,//Matching line
   DELETED_LINE,
   INSERTED_LINE|DELETED_LINE,
   0,//These are in hex, so there isn't a 3
   INSERTED_LINE
};

/**
 * Moves to the next (or previous) difference in two windows by looking at lineflags
 *
 * @param leftWID   Window id of left editor control
 * @param rightWID  Window id of left editor control
 * @param direction '' (default) to move forward(down)
 *                  '-' to move backward(up)
 *
 * @return
 */
int _DiffNextDifference(int leftWID, int rightWID,_str direction='',_str nomsgs='',
                        bool closeMessage=true)
{
   wid := p_window_id;
   wid=leftWID;
   rightWID.p_line=leftWID.p_line;//Just in case

   leftWID.p_col=1;rightWID.p_col=1;
   leftWID._refresh_scroll();
   rightWID._refresh_scroll();

   int line1flag=leftWID._lineflags();
   int line2flag=rightWID._lineflags();

   typeless list='';
   typeless orig=GetLineStatus(leftWID, rightWID);
      if (def_diff_next_hack) {
         list=NoChangeFlagTable[orig];
      }else{
         list=FlagTable[orig];
      }
   found := 0;
   typeless p,p2;
   leftWID.save_pos(p);
   rightWID.save_pos(p2);

   typeless cur=0;
   typeless difftype=0;
   isDiffDialog := DialogIsDiff();
   if (direction=='') {
      while (!(leftWID.down()||rightWID.down())) {
         cur=GetLineStatus(leftWID, rightWID);
         if (cur!=orig && !(orig&list)) {
            list |= orig;
         }
         if (cur&list) {
            found=1;
            break;
         }
      }
   }else{
      while (!(leftWID.up()||rightWID.up())) {
         cur=GetLineStatus(leftWID, rightWID);
         if (cur!=orig && !(orig&list)) list=list|orig;
         if (cur&list) {
            //Don't want to find adjacent changes
            orig=GetLineStatus(leftWID, rightWID);
            found=1;
            difftype=GetLineStatus(leftWID, rightWID);
            while (!(leftWID.up()||rightWID.up())) {
               if (!leftWID.p_line || !rightWID.p_line) {
                  leftWID.down();rightWID.down();
                  break;
               }
               cur=GetLineStatus(leftWID, rightWID);
               if (cur!=difftype) {
                  leftWID.down();rightWID.down();
                  break;
               }
            }
            break;
         }
      }
   }
   if (!found) {
      leftWID.restore_pos(p);
      rightWID.restore_pos(p2);
      if (leftWID.p_parent && leftWID.p_parent.p_visible) {//Form may not be visible
         refresh();
         if (nomsgs!='No Messages') {
            DIFF_MISC_INFO misc=_DiffGetMiscInfo();
            if (misc.AutoClose && direction!='-') {
               if (_find_control('_ctlclose')) {
                  _ctlclose.call_event(_ctlclose,LBUTTON_UP);
               }
               return(-1);
            }else{
               if ( closeMessage ) {
                  if (DiffMessageBox(get_message(VSDIFF_NO_MORE_DIFFERENCES_CLOSE_RC),MB_YESNO,IDNO) == IDYES) {
                     if (_find_control('_ctlclose')) {
                        _ctlclose.call_event(_ctlclose,LBUTTON_UP);
                     }
                     return(-1);
                  }
               } else {
                  DiffMessageBox(get_message(VSDIFF_NO_MORE_DIFFERENCES_RC));
               }
            }
         }
      }
      return(1);
   }

   leftWID.center_line();
   rightWID.center_line();
   p_window_id=wid;

   line1 := "";
   line2 := "";
   if (leftWID._line_length()<=def_diff_max_intraline_len &&
       rightWID._line_length()<=def_diff_max_intraline_len) {
      if (!(leftWID._lineflags()&NOSAVE_LF) && !(rightWID._lineflags()&NOSAVE_LF)) {
         leftWID.get_line_raw(line1);
         rightWID.get_line_raw(line2);
         i := 1;
         while ( (substr(line1,i,1) == substr(line2,i,1) ) &&
                 i<=length(line1) && i<=length(line2)) ++i;
         leftWID.p_col=rightWID.p_col=text_col(line1,i,'I');
      }else{
         leftWID._begin_line();
         rightWID._begin_line();
      }
   }

   leftWID.p_scroll_left_edge=rightWID.p_scroll_left_edge=-1;
   return(0);
}

static int diff_next_difference(...)
{
   int status=_DiffNextDifference(_ctlfile1,_ctlfile2,arg(1),arg(2));
   return( status );
}

static void diff_close_and_edit()
{
   bufName := "";
   _str p;
   DIFF_MISC_INFO misc=_GetDialogInfo(DIFFEDIT_CONST_MISC_INFO,_ctlfile1);
   if ( p_window_id == _ctlfile1) {
      bufName = _diffGetFilenameFromDialog(misc,'1');
      save_pos(p);
   } else if ( p_window_id == _ctlfile2 ) {
      if ( _ctlfile2_readonly.p_value ) {
         return;
      }
      bufName = _diffGetFilenameFromDialog(misc,'2');
      save_pos(p);
   }
   diff_close_form();
   edit(_maybe_quote_filename(bufName));
   restore_pos(p);
}

static int diff_prev_difference()
{
   return(diff_next_difference("-"));
}

_command void diff_next_diff() name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   // This is just a stub so that diff_next_difference will get called
}

_command void diff_prev_diff() name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   // This is just a stub so that diff_prev_difference will get called
}

static int NoSaveLine(int LineNumber)
{
   OrigLineNum := p_line;
   p_line=LineNumber;
   line := "";
   get_line(line);
   //rv=line=='Imaginary Buffer Line';
   int rv=_lineflags()&NOSAVE_LF;
   p_line=OrigLineNum;
   return(rv);
}

void diff_delete_block(_str NoMessageStr='')
{
   diff_copy_block(NoMessageStr, true, true/*doDeleteBlock*/);
}

static void diff_right_side_of_window()
{
   wid := 0;
   otherwid := GetOtherWid(wid);
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   typeless old_scroll=_scroll_style();
   _scroll_style('S 0');
   orig_left_edge := p_left_edge;
   p_cursor_x=p_client_width-1;
   while (p_left_edge!=orig_left_edge) {
      --p_col;
      set_scroll_pos(orig_left_edge,p_cursor_y);
   }
   _scroll_style(old_scroll);
   otherwid.p_col=p_col;
}

static void diff_left_side_of_window()
{
   wid := 0;
   otherwid := GetOtherWid(wid);
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   p_cursor_x=0;
   otherwid.p_col=p_col;
}

int diff_copy_block(_str NoMessageStr='',
                    bool ResetLineFlags=true,
                    bool doDeleteBlock=false)
{
   NoMessages := (NoMessageStr=='No Messages');
   if (!NoMessages) {
      _ctlfile1._undo('S');
      _ctlfile2._undo('S');
   }
   wid := 0;
   otherwid := GetOtherWid(wid);
   delete_block := (doDeleteBlock && (wid._lineflags()&NOSAVE_LF));
   typeless orig=GetLineStatus(_ctlfile1, _ctlfile2);
   while ((_lineflags()&NOSAVE_LF) && !doDeleteBlock) {
      if (!NoMessages) {
         DiffMessageBox('Cannot copy imaginary block');
      }else if (NoMessages) {
         if (diff_next_difference('',NoMessageStr)) return(1);
      }
      return(0);
   }
   if (orig==MATCHING_LINE) {
      if (!NoMessages) {
         DiffMessageBox('Block already matches');
      }
      return(1);
   }
   while (GetLineStatus(_ctlfile1, _ctlfile2)==orig) {
      wid.up();otherwid.up();
   }
   wid.down();otherwid.down();
   topln := wid.p_line;
   typeless status=0;
   while (GetLineStatus(_ctlfile1, _ctlfile2)==orig) {
      status=wid.down() || otherwid.down();
      if (status) break;
   }
   if (!status) {
      wid.up();otherwid.up();
   }
   bottomln := p_line;
   wid.p_line=topln-1;otherwid.p_line=wid.p_line;
   count := 0;
   int numLines = bottomln-(topln-1);

   if (status==0) {
      removeMarginButtonsFromLine(topln);
   }

   hadImaginaryLine := false;
//   _CallbackBufSuspendAll(_ctlfile1.p_buf_id,1);
//   _CallbackBufSuspendAll(_ctlfile2.p_buf_id,1);
   wasModified := wid.p_modify;
   wasOtherModified := otherwid.p_modify;
   _UndoPushModify(wid);
   for (;;) {
      status=wid.down()||otherwid.down();
      if (status) break;
      if (delete_block) {
         if (count>bottomln-topln) break;
      }else{
         if (status||wid.p_line>bottomln) break;
      }
      if (delete_block) {
         wid.DeleteLineMaybeNoModify();wid.up();
         otherwid.DeleteLineMaybeNoModify();otherwid.up();
         ++count;
      }else{
         line := "";
         wid.get_line(line);
         hadImaginaryLine = ((wid._lineflags()&NOSAVE_LF)!=0) || ((otherwid._lineflags()&NOSAVE_LF)!=0);
         otherwid._lineflags(0,NOSAVE_LF);//Get rid of any nosave flags
         otherwid.safe_replace_line(line);
         if (ResetLineFlags) {
            wid.set_line_normal();
         }
         otherwid.set_line_normal();
      }
      if ( hadImaginaryLine ) {
         DiffUpdateColorInfo(_ctlfile1,_ctlfile1.p_line-1,_ctlfile2,_ctlfile2.p_line-1,0,1,false,false);
      } else {
         // Have to do this manually because we suspended callback so that we do 
         // not add scroll markers
         DiffUpdateColorInfo(_ctlfile1,_ctlfile1.p_line,_ctlfile2,_ctlfile2.p_line,0,1,false,false);
      }
   }
   AddUndoNothing(otherwid);
   _UndoPopModify(wid);
//   _CallbackBufSuspendAll(_ctlfile1.p_buf_id,0);
//   _CallbackBufSuspendAll(_ctlfile2.p_buf_id,0);

   if (def_diff_edit_flags&DIFFEDIT_AUTO_JUMP) {
      int flags1=wid._lineflags();
      int flags2=otherwid._lineflags();
      if ((flags1&MODIFY_LF || flags1&INSERTED_LINE_LF || flags1&NOSAVE_LF) ||
          (flags2&MODIFY_LF || flags2&INSERTED_LINE_LF || flags2&NOSAVE_LF)) {
         //We are on the next error already
         return(0);
      }
      status=diff_next_difference('',NoMessageStr);
      return(status);
   }
   return(0);
}
int diff_copy_selection_to_other_window(_str NoMessageStr='',
                                        bool ResetLineFlags=true,
                                        bool doDeleteBlock=false)
{
   NoMessages := (NoMessageStr=='No Messages');
   if (!NoMessages) {
      _ctlfile1._undo('S');
      _ctlfile2._undo('S');
   }
   wid := 0;
   otherwid := GetOtherWid(wid);
   delete_block := (doDeleteBlock && (wid._lineflags()&NOSAVE_LF));
   typeless orig=GetLineStatus(_ctlfile1, _ctlfile2);
   while ((_lineflags()&NOSAVE_LF) && !doDeleteBlock) {
      if (!NoMessages) {
         DiffMessageBox('Cannot copy imaginary block');
      }else if (NoMessages) {
         if (diff_next_difference('',NoMessageStr)) return(1);
      }
      return(0);
   }
   if (orig==MATCHING_LINE) {
      if (!NoMessages) {
         DiffMessageBox('Block already matches');
      }
      return(1);
   }
   save_pos(auto p);
   wid._begin_select();
   topln := wid.p_line;
   wid._end_select();
   typeless status=0;
   bottomln := p_line;
   count := 0;
   int numLines = bottomln-topln;

   if (status==0) {
      removeMarginButtonsFromLine(topln);
   }

   hadImaginaryLine := false;
   wasModified := wid.p_modify;
   wasOtherModified := otherwid.p_modify;
   _UndoPushModify(otherwid);
   otherwid.p_line = wid.p_line = topln-1;
   for (;;) {
      status=wid.down()||otherwid.down();
      if (status) break;
      if (delete_block) {
         if (count>bottomln-topln) break;
      }else{
         if (status||wid.p_line>bottomln) break;
      }
      if (delete_block) {
         wid.DeleteLineMaybeNoModify();wid.up();
         otherwid.DeleteLineMaybeNoModify();otherwid.up();
         ++count;
      }else{
         line := "";
         wid.get_line(line);
         hadImaginaryLine = ((wid._lineflags()&NOSAVE_LF)!=0) || ((otherwid._lineflags()&NOSAVE_LF)!=0);
         otherwid._lineflags(0,NOSAVE_LF);//Get rid of any nosave flags
         otherwid.safe_replace_line(line);
         if (ResetLineFlags) {
            wid.set_line_normal();
         }
         otherwid.set_line_normal();
      }
      if ( hadImaginaryLine ) {
         DiffUpdateColorInfo(_ctlfile1,_ctlfile1.p_line-1,_ctlfile2,_ctlfile2.p_line-1,0,1,false,false);
      } else {
         // Have to do this manually because we suspended callback so that we do 
         // not add scroll markers
         DiffUpdateColorInfo(_ctlfile1,_ctlfile1.p_line,_ctlfile2,_ctlfile2.p_line,0,1,false,false);
      }
   }
   _UndoPopModify(otherwid);

   _DiffSetNeedRefresh(true);
#if 0 //11:08am 9/6/2019
   if (def_diff_edit_flags&DIFFEDIT_AUTO_JUMP) {
      int flags1=wid._lineflags();
      int flags2=otherwid._lineflags();
      if ((flags1&MODIFY_LF || flags1&INSERTED_LINE_LF || flags1&NOSAVE_LF) ||
          (flags2&MODIFY_LF || flags2&INSERTED_LINE_LF || flags2&NOSAVE_LF)) {
         //We are on the next error already
         return(0);
      }
      status=diff_next_difference('',NoMessageStr);
      return(status);
   }
#endif
   return(0);
}

static int diff_find_next()
{
   typeless status=find_next();
   if (/*LastActiveEditWindowWID*/_get_focus()==_ctlfile1) {
      _ctlfile2.p_col = _ctlfile1.p_col;
      _ctlfile2.p_line=_ctlfile1.p_line;
      _ctlfile2.set_scroll_pos(_ctlfile1.p_left_edge,_ctlfile1.p_cursor_y);
   }else if (/*LastActiveEditWindowWID*/_get_focus()==_ctlfile2) {
      _ctlfile1.p_col = _ctlfile2.p_col;
      _ctlfile1.p_line=_ctlfile2.p_line;
      _ctlfile1.set_scroll_pos(_ctlfile2.p_left_edge,_ctlfile2.p_cursor_y);
   }
   if (status) {
      clear_message();
      _message_box(nls("String not found"));
   }
   //ReturnFocusToEditWindow();
   return(status);
}

static int diff_find_prev()
{
   typeless status=find_prev();
   if (/*LastActiveEditWindowWID*/_get_focus()==_ctlfile1) {
      _ctlfile2.p_col = _ctlfile1.p_col;
      _ctlfile2.p_line=_ctlfile1.p_line;
      _ctlfile2.set_scroll_pos(_ctlfile1.p_left_edge,_ctlfile1.p_cursor_y);
   }else if (/*LastActiveEditWindowWID*/_get_focus()==_ctlfile2) {
      _ctlfile1.p_col = _ctlfile2.p_col;
      _ctlfile1.p_line=_ctlfile2.p_line;
      _ctlfile1.set_scroll_pos(_ctlfile2.p_left_edge,_ctlfile2.p_cursor_y);
   }
   if (status) {
      clear_message();
      _message_box(nls("String not found"));
   }
   //ReturnFocusToEditWindow();
   return(status);
}

static void DeleteLineMaybeNoModify()
{
   old := p_modify;
   int imaginary=_lineflags()&NOSAVE_LF;
   _delete_line();
   if (imaginary) {
      p_modify=old;
   }
}

static void set_line_inserted()
{
   _lineflags(0,INSERTED_LINE_LF|MODIFY_LF);
   _lineflags(INSERTED_LINE_LF,INSERTED_LINE_LF);
}
static void set_line_normal()
{
   _lineflags(0,INSERTED_LINE_LF|MODIFY_LF);
}

static int matching_tileid_exists(int tileid)
{
   buf_name2 := "";
   int tile_id=p_tile_id;
   first_window_id := p_window_id;
   typeless w2_view_id='';
   wid2 := 0;
   for (;;) {
      _next_window('HF');
      if ( p_window_id==first_window_id ) break;
      if ( p_tile_id==tile_id && !(p_window_flags &HIDE_WINDOW_OVERLAP)) {
         if ( w2_view_id!='' ) {
            w2_view_id='error';
            break;
         }
         w2_view_id=p_window_id;
         wid2=p_window_id;
         buf_name2=p_buf_name;
      }
   }
   return(wid2);
}
static void safe_replace_line(_str line)
{
   int old_TruncateLength=p_TruncateLength;
   p_TruncateLength=0;
   replace_line(line);
   p_TruncateLength=old_TruncateLength;
}

static void diff_vi_restart_word()
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   wid := p_window_id;
   OtherWid := GetOtherWid(wid);
   wid.vi_restart_word();
   AddUndoNothing(OtherWid);
}

static void diff_vi_ptab()
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   wid := p_window_id;
   OtherWid := GetOtherWid(wid);
   wid.vi_ptab();
   AddUndoNothing(OtherWid);
}

static void diff_vi_pbacktab()
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   wid := p_window_id;
   OtherWid := GetOtherWid(wid);
   wid.vi_pbacktab();
   AddUndoNothing(OtherWid);
}

static void diff_vi_begin_next_line()
{
   _ctlfile1._undo('S');
   _ctlfile2._undo('S');
   wid := p_window_id;
   OtherWid := GetOtherWid(wid);
   wid.vi_begin_next_line();
   OtherWid.p_line=p_line;
   OtherWid.p_col=p_col;
}

/**
 * Indicate that the buffers associated with the current Diff window 
 * are being diffed. 
 * 
 * @param addOrRemove   'true' means these buffers are being diffed 
 *                      'false' indicates they are no longer being diffed
 * @param misc          diff miscellaneous information struct 
 */
void _DiffSetBuffersAreDiffed(bool addOrRemove, DIFF_MISC_INFO misc=null)
{
   if (misc == null) {
      misc=_DiffGetMiscInfo();
      if (misc == null || !VF_IS_STRUCT(misc)) return;
   }

   _ctlfile1.set_buffer_isdiffed(_ctlfile1.p_buf_id, addOrRemove);
   _ctlfile2.set_buffer_isdiffed(_ctlfile2.p_buf_id, addOrRemove);
   if (misc.WholeFileBufId1>-1) {
      set_buffer_isdiffed(misc.WholeFileBufId1, addOrRemove);
   }
   if (misc.WholeFileBufId2>-1) {
      set_buffer_isdiffed(misc.WholeFileBufId2, addOrRemove);
   }
}

static void set_buffer_isdiffed(int buf_id, bool addOrRemove)
{
   // invalid buffer id?
   if (buf_id < 0) return;
   // already have an editor control with this buffer?
   if (_isEditorCtl(true) && buf_id == p_buf_id) {
      origCount := _GetBufferInfoHt(DIFFEDIT_CONST_BUFFER_IS_DIFFED);
      if (origCount ==  null) {
         // buffer was not being diffed before, initialize count to 1
         if (addOrRemove) {
            _SetBufferInfoHt(DIFFEDIT_CONST_BUFFER_IS_DIFFED, 1);
         }
      } else if (addOrRemove) {
         // increment count
         _SetBufferInfoHt(DIFFEDIT_CONST_BUFFER_IS_DIFFED, origCount+1);
      } else if (origCount > 1) {
         // decrement count
         _SetBufferInfoHt(DIFFEDIT_CONST_BUFFER_IS_DIFFED, origCount-1);
      } else {
         // clear counter entirely
         _SetBufferInfoHt(DIFFEDIT_CONST_BUFFER_IS_DIFFED, null);
      }
      return;
   }
   // otherwise open the buffer in a hidden window 
   origWID := p_window_id;
   p_window_id = HIDDEN_WINDOW_ID;
   _safe_hidden_window();
   status := load_files('+bi 'buf_id);
   if (!status) {
      set_buffer_isdiffed(buf_id, addOrRemove);
   }
   p_window_id = origWID;
}


/**
 * Set the "Files match" item that we keep track of
 */
void _DiffSetFilesMatch(_str FilesMatchInfo)
{
   _SetDialogInfo(DIFFEDIT_CONST_FILES_MATCH,FilesMatchInfo,_ctlfile1);
}
/**
 * Get the "Files match" item that we keep track of
 */
_str _DiffGetFilesMatch()
{
   return(_GetDialogInfo(DIFFEDIT_CONST_FILES_MATCH,_ctlfile1));
}

/**
 * Set the dialog titles item that we keep track of
 */
void _DiffSetDialogTitles(_str File1Title,_str File2Title)
{
   _SetDialogInfo(DIFFEDIT_CONST_FILE_TITLES,_maybe_quote_filename(File1Title)' '_maybe_quote_filename(File2Title),_ctlfile1);
}
/**
 * Get the dialog titles item that we keep track of
 */
_str _DiffGetDialogTitles()
{
   return(_GetDialogInfo(DIFFEDIT_CONST_FILE_TITLES,_ctlfile1));
}

/**
 * Set the previous vertical scroll position
 */
void _DiffVscrollSetLast(typeless LastVScrollPos)
{
   _SetDialogInfo(DIFFEDIT_CONST_LAST_VSCROLL,LastVScrollPos,_ctlfile1);
}
/**
 * Get the previous vertical scroll position
 */
int _DiffVscrollGetLast()
{
   return(_GetDialogInfo(DIFFEDIT_CONST_LAST_VSCROLL,_ctlfile1));
}

/**
 * Set the previous horizontal scroll position
 */
void _DiffHscrollSetLast(typeless LastHScrollPos)
{
   _SetDialogInfo(DIFFEDIT_CONST_LAST_HSCROLL,LastHScrollPos,_ctlfile1);
}
/**
 * Get the previous horizontal scroll position
 */
int _DiffHscrollGetLast()
{
   return(_GetDialogInfo(DIFFEDIT_CONST_LAST_HSCROLL,_ctlfile1));
}

/**
 * Set the refresh flag
 */
void _DiffSetNeedRefresh(bool NeedRefresh)
{
   _SetDialogInfo(DIFFEDIT_CONST_NEED_REFRESH,NeedRefresh,_ctlfile1);
}
/**
 * Get the refresh flag
 */
bool _DiffGetNeedRefresh()
{
   return(_GetDialogInfo(DIFFEDIT_CONST_NEED_REFRESH,_ctlfile1));
}

void _DiffSetMiscInfo(DIFF_MISC_INFO &misc)
{
   _SetDialogInfo(DIFFEDIT_CONST_MISC_INFO,misc,_ctlfile1);
}

DIFF_MISC_INFO _DiffGetMiscInfo()
{
   return(_GetDialogInfo(DIFFEDIT_CONST_MISC_INFO,_ctlfile1));
}

/**
 * Set flag to let us know that the File title labels are missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
void _DiffSetFileLabelsMissing()
{
   _SetDialogInfo(DIFFEDIT_CONST_FILE_LABELS_MISSING,1,_ctlfile1);
}
/**
 * Set flag to let us know that the File title labels are missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
bool _DiffGetFileLabelsMissing()
{
   return(_GetDialogInfo(DIFFEDIT_CONST_FILE_LABELS_MISSING,_ctlfile1));
}

/**
 * Set flag to let us know that the line number labels are missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
void _DiffSetLineNumLabelsMissing()
{
   _SetDialogInfo(DIFFEDIT_CONST_LINENUM_LABELS_MISSING,1,_ctlfile1);
}
/**
 * Get flag to let us know that the line number labels are missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
bool _DiffGetLineNumLabelsMissing()
{
   return(_GetDialogInfo(DIFFEDIT_CONST_LINENUM_LABELS_MISSING,_ctlfile1));
}

/**
 * Set the flag to let us know that the line number labels are missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
void _DiffSetReadOnlyCBMissing()
{
   _SetDialogInfo(DIFFEDIT_CONST_READONLY_CB_MISSING,1,_ctlfile1);
}
/**
 * Get the flag to let us know that the line number labels are missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
bool _DiffGetReadOnlyCBMissing()
{
   return(_GetDialogInfo(DIFFEDIT_CONST_READONLY_CB_MISSING,_ctlfile1));
}

/**
 * Set the flag to let us know that the file 1 is readonly, even if the
 * checkboxes are missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
void _DiffSetReadOnly(int value)
{
   id := 0;
   if ( p_name=='_ctlfile1' ) {
      id=DIFFEDIT_CONST_READONLY_SET1;
   }else if ( p_name=='_ctlfile2' ) {
      id=DIFFEDIT_CONST_READONLY_SET2;
   }
   _SetDialogInfo(id,value,_ctlfile1);
}
/**
 * Set the flag to let us know that the file 1 is readonly, even if the
 * checkboxes are missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
bool _DiffGetReadOnly()
{
   id := 0;
   if ( p_name=='_ctlfile1' ) {
      id=DIFFEDIT_CONST_READONLY_SET1;
   }else if ( p_name=='_ctlfile2' ) {
      id=DIFFEDIT_CONST_READONLY_SET2;
   }
   return(_GetDialogInfo(id,_ctlfile1));
}

/**
 * Set the flag to let us know that the Next/Prev diff buttons are missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
void _DiffSetNextDiffMissing()
{
   _SetDialogInfo(DIFFEDIT_CONST_LINE_NEXT_DIFF_MISSING,1,_ctlfile1);
}
/**
 * Get the flag to let us know that the Next/Prev diff buttons are missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
bool _DiffGetNextDiffMissing()
{
   return(_GetDialogInfo(DIFFEDIT_CONST_LINE_NEXT_DIFF_MISSING,_ctlfile1));
}

/**
 * Set the flag to let us know that the Close button is missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
void _DiffSetCloseMissing()
{
   _SetDialogInfo(DIFFEDIT_CONST_CLOSE_MISSING,1,_ctlfile1);
}
/**
 * Get the flag to let us know that the Close button is missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
bool _DiffGetCloseMissing()
{
   return(_GetDialogInfo(DIFFEDIT_CONST_CLOSE_MISSING,_ctlfile1));
}

/**
 * Set the flag to let us know that the Copy buttons are missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
void _DiffSetCopyMissing()
{
   _SetDialogInfo(DIFFEDIT_CONST_COPY_MISSING,1,_ctlfile1);
}
void _DiffSetCopyLeftMissing()
{
   _SetDialogInfo(DIFFEDIT_CONST_COPY_LEFT_MISSING,1,_ctlfile1);
}
/**
 * Get the flag to let us know that the Copy buttons are missing
 * Pieces of the dialog may be copied to other dialogs, and this may be missing
 */
bool _DiffCopyMissing()
{
   return(_GetDialogInfo(DIFFEDIT_CONST_COPY_MISSING,_ctlfile1));
}
bool _DiffCopyLeftMissing()
{
   return(_GetDialogInfo(DIFFEDIT_CONST_COPY_LEFT_MISSING,_ctlfile1));
}

void _before_context_combo_select_diffedit(int comboBoxWID)
{
   if ( comboBoxWID.p_name=='ctlcontextCombo1' ||
        comboBoxWID.p_name=='ctlcontextCombo2' ) {
      _ctlfile1._undo('S');
      _ctlfile2._undo('S');
   }
}

void _after_context_combo_select_diffedit(int comboBoxWID)
{
   if ( comboBoxWID.p_name=='ctlcontextCombo1' ||
        comboBoxWID.p_name=='ctlcontextCombo2' ) {
      origWID := p_window_id;
      otherWID := 0;
      if ( p_window_id == ctlcontextCombo1 ) {
         p_window_id = _ctlfile2;
         otherWID = _ctlfile1;
      } else if ( p_window_id == ctlcontextCombo2 ) {
         p_window_id = _ctlfile1;
         otherWID = _ctlfile2;
      }
      p_line = otherWID.p_line;
      center_line();
      otherWID._set_focus();
      refresh();
      p_window_id = origWID;
   }
}
