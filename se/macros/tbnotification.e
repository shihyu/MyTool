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
#import "files.e"
#import "help.e"
#import "notifications.e"
#import "optionsxml.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbcontrols.e"
#import "treeview.e"
#import "util.e"
#require "se/datetime/DateTime.e"
#endregion

using namespace se.datetime;

int def_notification_tool_window_log_size = 50;

defeventtab _tbnotification_form;

static _str CURRENT_TB_FEATURE(...) {
   if (arg()) _ctl_desc.p_user=arg(1);
   return _ctl_desc.p_user;
}
static bool NOTIFICATION_TB_RESIZING(...) {
   if (arg()) _ctl_notes_tree.p_user=arg(1);
   return _ctl_notes_tree.p_user;
}

static const NOTETB_V_DESC_HEIGHT=1500;
static const NOTETB_H_DESC_WIDTH= 3600;

static const NOTESTB_TREE_COL_EVENT=            0;
static const NOTESTB_TREE_COL_TIME=             1;
static const NOTESTB_TREE_COL_FILE=             2;
static const NOTESTB_TREE_COL_LINE=             3;

_ctl_notes_tree.on_create()
{
   NOTIFICATION_TB_RESIZING(false);
   CURRENT_TB_FEATURE("");

   colSlice := _ctl_notes_tree.p_width intdiv 10;

   // set up our columns and what not
   _ctl_notes_tree._TreeSetColButtonInfo(NOTESTB_TREE_COL_EVENT, colSlice * 3, TREE_BUTTON_PUSHBUTTON | TREE_BUTTON_SORT, -1, 'Event');
   _ctl_notes_tree._TreeSetColButtonInfo(NOTESTB_TREE_COL_TIME, colSlice * 2, TREE_BUTTON_PUSHBUTTON | TREE_BUTTON_SORT_DATE | TREE_BUTTON_SORT_TIME, -1, 'Time');
   _ctl_notes_tree._TreeSetColButtonInfo(NOTESTB_TREE_COL_FILE, colSlice * 4, TREE_BUTTON_IS_FILENAME | TREE_BUTTON_PUSHBUTTON | TREE_BUTTON_SORT, -1, 'File');
   _ctl_notes_tree._TreeSetColButtonInfo(NOTESTB_TREE_COL_LINE, colSlice, TREE_BUTTON_PUSHBUTTON | TREE_BUTTON_SORT_NUMBERS, -1, 'Line');

   refreshNotificationTree();

   _ctl_notes_tree._TreeTop();
   _ctl_notes_tree._TreeRefresh();
}

void _tbnotification_form.on_resize()
{
   if (NOTIFICATION_TB_RESIZING()) return;

   NOTIFICATION_TB_RESIZING(true);

   width := _dx2lx(p_active_form.p_xyscale_mode, p_active_form.p_client_width);
   height := _dy2ly(p_active_form.p_xyscale_mode, p_active_form.p_client_height);

   // determine padding
   padding := _ctl_notes_tree.p_x;

   // determine the current orientation (horizontal vs vertical)
   orientation := (_ctl_notes_tree.p_x == _ctl_desc.p_x) ? 'V' : 'H';

   // determine the new orientation
   heightFactor := (double)height / (double)NOTETB_V_DESC_HEIGHT;
   widthFactor := (double)width / (double)NOTETB_H_DESC_WIDTH;
   orientation = heightFactor > widthFactor ? 'V' : 'H';

   // we need this to scale the column widths
   origTreeWidth := _ctl_notes_tree.p_width;
   
   if (orientation == 'H') {
      _ctl_desc.p_width = NOTETB_H_DESC_WIDTH;
      _ctl_desc.p_x = width - _ctl_desc.p_width - padding - _ctl_clear_btn.p_width - padding;

      _ctl_desc.p_y = _ctl_feature_options_btn.p_y_extent;
      _ctl_desc.p_y_extent = height - padding;

      _ctl_notes_tree.p_x_extent = _ctl_desc.p_x - padding;
      _ctl_notes_tree.p_y_extent = height - padding;

      // adjust positions of notification buttons
      space_x := _dy2ly(SM_TWIP,def_toolbar_pic_vspace);
      _ctl_notification_options_btn.p_x = _ctl_notes_tree.p_x_extent + padding;
      _ctl_feature_help_btn.p_x = _ctl_notification_options_btn.p_x_extent + space_x;
      _ctl_feature_options_btn.p_x = _ctl_feature_help_btn.p_x_extent + space_x;
      _ctl_clear_btn.p_x = _ctl_feature_options_btn.p_x_extent + space_x;
      _ctl_notification_options_btn.p_y = padding;
      _ctl_feature_help_btn.p_y = padding;
      _ctl_feature_options_btn.p_y = padding;
      _ctl_clear_btn.p_y = padding;

   } else {

      _ctl_desc.p_height = NOTETB_V_DESC_HEIGHT;
      _ctl_desc.p_y = height - _ctl_desc.p_height - padding;
      _ctl_desc.p_x = _ctl_notes_tree.p_x;

      _ctl_notes_tree.p_width = width - _ctl_clear_btn.p_width - 3*padding;
      _ctl_notes_tree.p_y_extent = _ctl_desc.p_y - padding;
      _ctl_desc.p_width = _ctl_notes_tree.p_width;

      // adjust positions of notification buttons
      space_y := _dy2ly(SM_TWIP,def_toolbar_pic_vspace);
      _ctl_clear_btn.p_x = width - _ctl_clear_btn.p_width - padding;
      _ctl_notification_options_btn.p_x = _ctl_clear_btn.p_x;
      _ctl_feature_help_btn.p_x = _ctl_clear_btn.p_x;
      _ctl_feature_options_btn.p_x = _ctl_clear_btn.p_x;
      _ctl_notification_options_btn.p_y = padding;
      _ctl_feature_help_btn.p_y = _ctl_notification_options_btn.p_y_extent + space_y;
      _ctl_feature_options_btn.p_y = _ctl_feature_help_btn.p_y_extent + space_y;
      _ctl_clear_btn.p_y = _ctl_feature_options_btn.p_y_extent + space_y;

   }

   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      // First time
      _ctl_notes_tree._TreeRetrieveColButtonInfo();
   }

   _ctl_notes_tree._TreeScaleColButtonWidths(origTreeWidth);


   NOTIFICATION_TB_RESIZING(false);
}

void _tbnotification_form.on_destroy()
{
   _ctl_notes_tree._TreeAppendColButtonInfo();
}

void refreshNotificationTree()
{
   tree := _find_object('_tbnotification_form._ctl_notes_tree', 'n');
   if (!tree) return;

   selCaption := tree._TreeGetCurCaption();
   if (tree._TreeCurIndex() == tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX)) {
      selCaption = "";
   }

   tree._TreeBeginUpdate(TREE_ROOT_INDEX);

   // clear out the tree first
   tree._TreeDelete(TREE_ROOT_INDEX, "C");

   // now get the list of notifications from the logger
   NOTIFICATION_INFO log[];
   getNotificationLogArray(log, def_notification_tool_window_log_size);

   NOTIFICATION_INFO info;
   int y, m, d, h, min, s, ms;
   for (i := 0; i < log._length(); i++) {
      info = log[i];
      caption := getNotificationTypeAndEventName(info.AlertGroupID, info.Feature, info.SecondFeature);

      // don't do anything with the date until after we've added the item
      caption :+= \t" ";
      
      caption :+= \tinfo.Filename;
      if (info.LineNumber) {
         caption :+= \tinfo.LineNumber;
      }

      // add this to the tree - with the feature number as the user info
      index := tree._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0, info.Feature"\t"info.AlertGroupID);

      DateTime dt();
      dt = DateTime.fromTimeF(info.Timestamp);
      dt.toParts(y, m, d, h, min, s, ms);
      tree._TreeSetDateTime(index, 1, y, m, d, h, min, s, ms);
   }

   tree._TreeEndUpdate(TREE_ROOT_INDEX);

   if (selCaption != "") {
      selIndex := tree._TreeSearch(TREE_ROOT_INDEX, selCaption);
      if (selIndex > 0) {
         tree._TreeSetCurIndex(selIndex);
      }
   } else {
      tree._TreeTop();
   }
}

void _ctl_notes_tree.on_change()
{
   // we need to update the information on the right now
   if (arg() >= 2) {
      reason := arg(1);
      switch (reason) {
      case CHANGE_SELECTED:
         showInfoForCurrentNotification();
         return;
      }
   }

   if (_ctl_notes_tree._TreeCurIndex() <= 0) {
      clearCurrentNotificationInfo();
   }
}

/**
 * Displays the context menu for the notifications tree.
 * 
 * @param int x         x position
 * @param int y         y position
 */
void _ctl_notes_tree.rbutton_up(int x = -1, int y = -1)
{
   // find the menu
   menu_name := "_tbnotifications_tree_menu";
   index := find_index(menu_name, oi2type(OI_MENU));
   if (index == 0) {
      return;
   }

   // try to load 'er up
   handle := p_active_form._menu_load(index, 'p');
   if (handle < 0) {
      msg := "Unable to load menu \"" :+ menu_name :+ "\"";
      _message_box(msg, "", MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   parse CURRENT_TB_FEATURE() with auto feature "\t" auto alertGroupId;
   if (CURRENT_TB_FEATURE() != "") {
      featureName := getNotificationEventName(alertGroupId, feature);

      // put the name of the current feature in the menu item captions
      _menu_set_state(handle, 'configure-notification-feature', MF_ENABLED | MF_UNCHECKED, 'M', featureName' options');
      _menu_set_state(handle, 'show-help-for-notification-feature', MF_ENABLED | MF_UNCHECKED, 'M', featureName' help');
   } else {
      _menu_set_state(handle, 'configure-notification-feature', MF_GRAYED | MF_UNCHECKED, 'M', 'Options');
      _menu_set_state(handle, 'show-help-for-notification-feature', MF_GRAYED | MF_UNCHECKED, 'M', 'Help');
   }

   // if we got no x and y, use some defaults
   if (x == y && x == -1) {
      x = mou_last_x('m') - VSDEFAULT_INITIAL_MENU_OFFSET_X; 
      y = mou_last_y('m') - VSDEFAULT_INITIAL_MENU_OFFSET_Y;
      _lxy2dxy(p_scale_mode, x, y);
      _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   }

   // show the menu already
   int flags = VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   _menu_show(handle, flags, x, y);
   _menu_destroy(handle);
}

void _ctl_notes_tree.on_got_focus()
{
   if (!_find_control("_ctl_notes_tree")) return;
   showInfoForCurrentNotification();
}

static void showInfoForCurrentNotification()
{
   curIndex := _ctl_notes_tree._TreeCurIndex();
   if (curIndex > 0) {
   
      // get the user info of the selected node - it contains the feature number
      feature := _ctl_notes_tree._TreeGetUserInfo(curIndex);
      if (feature != null && feature != "") {
         CURRENT_TB_FEATURE(feature);
         parse feature with feature "\t" auto alertGroupId;
         _ctl_desc.p_caption = getNotificationEventDescription(alertGroupId, feature);

         // update the tooltips in the buttons
         featureName := getNotificationEventName(alertGroupId, feature);
         _ctl_feature_options_btn.p_message = featureName' options';
         _ctl_feature_help_btn.p_message = featureName' help';

         _ctl_feature_options_btn.p_enabled = true;
         _ctl_feature_help_btn.p_enabled = true;
      }
   } else {
      clearCurrentNotificationInfo();
   }
}

static void clearCurrentNotificationInfo()
{
   CURRENT_TB_FEATURE("");
   _ctl_desc.p_caption = "";

   // update the tooltips in the buttons
   _ctl_feature_options_btn.p_message = 'Options';
   _ctl_feature_help_btn.p_message = 'Help';

   _ctl_feature_options_btn.p_enabled = false;
   _ctl_feature_help_btn.p_enabled = false;
}

void _ctl_notes_tree.lbutton_double_click()
{
   curIndex := _ctl_notes_tree._TreeCurIndex();
   if (curIndex > 0) {
      // we need the file name and the line number
      filename := _ctl_notes_tree._TreeGetTextForCol(curIndex, NOTESTB_TREE_COL_FILE);
      if (filename._varformat()!=VF_LSTR && !isinteger(filename)) {
         return;
      }
      if (get_extension(filename) == TAG_FILE_EXT) return;
      filename = _maybe_quote_filename(filename);

      lineNumber := 1;
      lineNumberText := _ctl_notes_tree._TreeGetTextForCol(curIndex, NOTESTB_TREE_COL_LINE);
      if (isinteger(lineNumberText)) lineNumber = (int)lineNumberText;

      if (!edit(filename)) {
         goto_line(lineNumber);
         p_col = 1;
      }
   }
}

void _ctl_feature_help_btn.lbutton_up()
{
   show_help_for_notification_feature();
}

void _ctl_feature_options_btn.lbutton_up()
{
   if (CURRENT_TB_FEATURE() != "") {
      // extract the filename from this line
      curIndex := _ctl_notes_tree._TreeCurIndex();
      if (curIndex > 0) {
         filename := _ctl_notes_tree._TreeGetTextForCol(curIndex, NOTESTB_TREE_COL_FILE);

         // If the filename is a tag file, then bring up the Tag Files dialog
         if (get_extension(filename) == TAG_FILE_EXT) {
            gui_make_tags(filename);
            return;
         }

         // bring up the possibly language-specific options for this notification
         langId := _Filename2LangId(filename);
         feature := _ctl_notes_tree._TreeGetUserInfo(curIndex);
         parse CURRENT_TB_FEATURE() with feature "\t" auto alertGroupId;
         configure_notification_feature(alertGroupId, feature, langId);
      }
   }
}

void _ctl_notification_options_btn.lbutton_up()
{
   configure_notifications();
}

void _ctl_clear_btn.lbutton_up()
{
   // clear the list of notifications - we want a fresh slate
   clear_notifications();

   clearCurrentNotificationInfo();
}
/**
 * Called when a different workspace is opened.
 */
void _workspace_opened_notifications()
{
   // clear the list of notifications - we want a fresh slate
   // we do this when a new workspace is opened (in addition to when one is closed) 
   // in case the user was editing files without a workspace open - they might have 
   // notifications from that
   clear_notifications();
}

/**
 * Called when the current workspace is closed.
 */
void _wkspace_close_notifications()
{
   // clear the list of notifications - they were associated with this workspace
   clear_notifications();
}

/**
 * Clears the notifications in the notification tool window.
 * Merges these into the permanet log.
 */
_command void clear_notifications() name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   // this method saves the current log to the permanent log and then clears the current one
   mergeNotificationLog(true);

   // now refresh the tree
   refreshNotificationTree();
}

/**
 * Opens the options dialog to and displays the Notifications 
 * options node.   
 * 
 * @param feature          the NotificationFeature to select on 
 *                         the options node.
 */
_command void configure_notifications(_str feature = "") name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (feature == "") {
      tree := _find_object('_tbnotification_form._ctl_notes_tree', 'n');
      if (tree > 0 && CURRENT_TB_FEATURE() != "") {
         feature = CURRENT_TB_FEATURE();
      }
   }

   config('Notifications', 'N', feature);
}

/**
 * Shows the options to configure a specific NotificationFeature.
 *  
 * @param alertGroupId        ALERT_GRP_* 
 * @param feature             feature to show options for
 * @param langId              language to configure.  If no language is specified, 
 *                            then the language of the current editor window is used
 */
_command void configure_notification_feature(_str alertGroupId="", _str feature = "", _str langId = "") name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (feature == "") {
      tree := _find_object('_tbnotification_form._ctl_notes_tree', 'n');
      if (tree > 0 && CURRENT_TB_FEATURE() != "") {
         parse CURRENT_TB_FEATURE() with feature "\t" alertGroupId;
      }  
   }

   _str optionsCommand, optionsArg1, optionsArg2;
   getNotificationEventOptionsInfo(alertGroupId, feature, optionsCommand, optionsArg1, optionsArg2);
   if (optionsCommand != "") {
      // find the command
      index := find_index(optionsCommand, PROC_TYPE | COMMAND_TYPE);
      if (index) {
         if (langId != "" && optionsCommand == 'config' && optionsArg2 == 'L') {
            langId = _LangGetModeName(langId);
            optionsArg1 = langId ' > 'optionsArg1; 
         }
         if (optionsArg2 != "") {
            call_index(optionsArg1, optionsArg2, index);
         } else if (optionsArg1 != "") {
            call_index(optionsArg1, index);
         } else {
            call_index(index);
         }
      }
   }
}

/**
 * Shows help information for a specific NotificationFeature.
 * 
 * @param feature             feature to show help for
 */
_command void show_help_for_notification_feature(_str alertGroupId = "", _str feature = "") name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (feature == "") {
      tree := _find_object('_tbnotification_form._ctl_notes_tree', 'n');
      if (tree > 0 && CURRENT_TB_FEATURE() != "") {
         parse CURRENT_TB_FEATURE() with feature "\t" alertGroupId;
      }
   }

   helpInfo := getNotificationEventHelp(alertGroupId, feature);
   if (helpInfo != "" && !isinteger(helpInfo)) {
      help(helpInfo);
   }
}
