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
#pragma option(pedantic, on)
#region Imports
#include "slick.sh"
#include "markers.sh"
#require "Message.e"
#require "MessageCollection.e"
#require "se/lineinfo/LineInfoBrowser.e"
#require "se/util/Subject.e"
#import "seek.e"
#import "stdprocs.e"
#import "tagwin.e"
#import "toolbar.e"
#import "treeview.e"
#import "cbrowser.e"
#import "context.e"
#import "files.e"
#import "listbox.e"
#import "se/ui/toolwindow.e"
#import "se/ui/mainwindow.e"
#endregion

static const SHOW_ALL= "(show all)";
static const MESSAGE_LIST_FORM_NAME_STRING=  "_tbmessages_browser_form";
struct MESSAGE_LIST_FORM_INFO {
   int m_form_wid;
};
static MESSAGE_LIST_FORM_INFO gMessageListFormList:[];

static void _init_all_formobj(MESSAGE_LIST_FORM_INFO (&formList):[],_str formName) {
   int last = _last_window_id();
   int i;
   for (i=1; i<=last; ++i) {
      if (_iswindow_valid(i) && i.p_object == OI_FORM && !i.p_edit) {
         if (i.p_name:==formName) {
            formList:[i].m_form_wid=i;
            //wid = i;
            //break;
         }
      }
   }
}

definit()
{
   // IF editor is initializing from invocation
   //if (arg(1)!='L') {
   //}
   gMessageListFormList._makeempty();
   _init_all_formobj(gMessageListFormList,MESSAGE_LIST_FORM_NAME_STRING);
}

static int _tbGetActiveMessageListForm()
{
   return tw_find_form(MESSAGE_LIST_FORM_NAME_STRING);
}

namespace se.messages;

using se.util.Subject;


class MessageBrowser : se.lineinfo.LineInfoBrowser {
   public Message* m_messages[];
   public int m_creators:[][];
   public int m_types:[][];
   public bool m_NeedToRefreshMessages;

   MessageBrowser()
   {
      m_NeedToRefreshMessages=true;
   }

   ~MessageBrowser()
   {
      // make sure we always detach here, otherwise the Observers
      // will be pointing at nothingness
      detach();
   }

   void update(Subject* subject)
   {
      m_NeedToRefreshMessages=true;

      // Need to do this now.  m_messages references pointers from the sending
      // MessagingCollection, and the MessagingCollection's array of Messages 
      // is being changed, so we have to assume these pointers are invalid.
      m_messages._makeempty();
      m_creators._makeempty();
      m_types._makeempty();
      _UpdateMessages(true);
   }

   void removeSubject(Subject* subject)
   {
   }

   void reportCreators(_str* (&creators):[][])
   {
   }

   void reportTypes(_str* (&types):[][])
   {
   }

   void refreshMessages(int form_wid) {
      //say('refresh messages');
      m_messages._makeempty();
      m_creators._makeempty();
      m_types._makeempty();

      se.messages.MessageCollection* mCollection = get_messageCollection();
      if (mCollection) {
         mCollection->getMessages(m_messages);
         int i;
         for (i = 0; i < m_messages._length(); ++i) {
            m_creators:[m_messages[i]->m_creator] :+= i;
            m_types:[m_messages[i]->m_type] :+= i;
         }
      }

      //Update the toolwindow.
      form_wid.refreshMessageBrowser(this);
      m_NeedToRefreshMessages=false;
   }

   void attach()
   {
      se.messages.MessageCollection* mCollection = get_messageCollection();
      if (mCollection && ((*mCollection) instanceof se.messages.MessageCollection)) {
         mCollection->attachObserver(&this);
      }
   }

   void detach()
   {
      se.messages.MessageCollection* mCollection = get_messageCollection();
      if (mCollection && ((*mCollection) instanceof se.messages.MessageCollection)) {
         mCollection->detachObserver(&this);
      }
   }

   /**
    * Opens the file associated with the message and goes to the 
    * proper line and, possibly, column. If the marker isn't where
    * it was last reported, update the message to the new location. 
    *  
    * @return Returns true if the message's location was updated.
    * 
    */
   public bool goToMessageCodeLocation(int index)
   {
      // can't do anything with a negative index
      if (index < 0) return false;

      if (m_messages[index]->m_sourceFile != "") {

         sourceFile := "";
         isChanged := false;

         sourceFile = _maybe_quote_filename(m_messages[index]->m_sourceFile);
         if (sourceFile == "") return false;
         int child_wid=_MDIGetActiveMDIChild();
         if (child_wid) {
            child_wid._set_focus();
         }
         edit(sourceFile, EDIT_DEFAULT_FLAGS);

         // Prefer stream markers to line markers.
         if (m_messages[index]->m_smarkerID > -1) {
            VSSTREAMMARKERINFO sInfo;
            if (_StreamMarkerGet(m_messages[index]->m_smarkerID, sInfo)) {
               m_messages[index]->m_lineVisited = true;
               return isChanged;
            }
            // Use execute so command takes care of deselecting if necessary
            execute('seek 'sInfo.StartOffset);
            //_GoToROffset(sInfo.StartOffset);
         } else if (m_messages[index]->m_lmarkerID > -1) {
            VSLINEMARKERINFO lInfo;
            if (_LineMarkerGet(m_messages[index]->m_lmarkerID, lInfo)) {
               m_messages[index]->m_lineVisited = true;
               return isChanged;
            }
            if (lInfo.LineNum > 0) {
               // Use execute so command takes care of deselecting if necessary
               execute('goto_line 'lInfo.LineNum);
               //_mdi.p_child.p_RLine = lInfo.LineNum;
               _mdi.p_child.p_col = 1;
            }
         }

         if (m_messages[index]->m_lineNumber != _mdi.p_child.p_RLine) {
            m_messages[index]->m_lineNumber = _mdi.p_child.p_RLine;
            isChanged = true;
         }
         if (m_messages[index]->m_colNumber != _mdi.p_child.p_col) {
            m_messages[index]->m_colNumber = _mdi.p_child.p_col;
            isChanged = true;
         }

         m_messages[index]->m_lineVisited = true;

         return isChanged;
      }

      return false;
   }
};

namespace default;

static void _UpdateMessagesOne(int form_wid,MESSAGE_LIST_FORM_INFO &formInfo,long elapsed,int child_wid,bool AlwaysUpdate) {
   //int child_wid=_mdi.p_child;
   if( !tw_is_wid_active(form_wid) ) {
      return;
   }

   se.messages.MessageBrowser* messageBrowser = _GetDialogInfoHtPtr("messageBrowser", form_wid);
   if (!messageBrowser) {
      return;
   }
   if (!child_wid) {
      if (messageBrowser->m_NeedToRefreshMessages) {
         messageBrowser->refreshMessages(form_wid);
      }
      return;
   }
   // maybe should check for focus on "_message_tree" control
   /*if (child_wid != _get_focus() &&
       !messageBrowser->m_NeedToRefreshMessages
       ) {
      return;
   }*/
   /*
   If SlickEdit has not computed the line number, there can't be any
      messages since the messages may require line numbers.
   */

   if (child_wid.point('L') < 0) {
      if (messageBrowser->m_NeedToRefreshMessages) {
         messageBrowser->refreshMessages(form_wid);
      }
      return;
   }


   messageMarker := "-1 -1";
   int lMarkers[];  //All line markers
   int scMarkers[]; //All stream markers under cursor
   int sMarkers[];  //All stream markers
   int i;
   lineModified := false;
   
   // Figure out which Messages are on the current line, and mark them as
   // (un)modified.
   se.messages.MessageCollection* mCollection = get_messageCollection();
   mCollection->startBatch();
   _str sLineOffset;
   parse child_wid.point() with sLineOffset .;
   long lineOffset = (long)sLineOffset;
   lineLen := child_wid._line_length(true);
   _StreamMarkerFindList(sMarkers, child_wid, lineOffset, lineLen,
                         VSNULLSEEK, 0);
   se.messages.Message* msgPtr;
   int msgIndex;
   for (i = 0; i < sMarkers._length(); ++i) {
      int *pi=mCollection->m_sMarkers._indexin(sMarkers[i]);
      if (pi) {
         msgIndex = *pi;
         mCollection->getMessage(msgPtr, msgIndex);
         if (msgPtr) {
            if (child_wid._lineflags() & MODIFY_LF) {
               if (!msgPtr->m_lineModified) {
                  lineModified = true;
               }
               msgPtr->m_lineModified = true;
            } else if (msgPtr->m_lineModified) {
               msgPtr->m_lineModified = false;
               lineModified = true;
            }
         }
      }
   }
   _LineMarkerFindList(lMarkers, child_wid, child_wid.p_RLine, 0, false);
   for (i = 0; i < lMarkers._length(); ++i) {
      if (mCollection->m_lMarkers._indexin(lMarkers[i])) {
         msgIndex = mCollection->m_lMarkers:[lMarkers[i]];
         mCollection->getMessage(msgPtr, msgIndex);
         if (msgPtr) {
            if (child_wid._lineflags() & MODIFY_LF) {
               if (!msgPtr->m_lineModified) {
                  lineModified = true;
               }
               msgPtr->m_lineModified = true;
            } else if (msgPtr->m_lineModified) {
               msgPtr->m_lineModified = false;
               lineModified = true;
            }
         }
      }
   }
   mCollection->endBatch();
   needToRefresh := messageBrowser->m_NeedToRefreshMessages || lineModified;
   /*if (lineModified) {
      mCollection->notifyObservers();
   } */

   // Prefer stream markers over line markers.
   _StreamMarkerFindList(scMarkers, child_wid, child_wid._nrseek(), 1,
                         VSNULLSEEK, 0);

   // 5/11/2012 - Go through any stream markers on the line, ignore any that 
   // are used for scroll markers. There will be at least one because we use
   // stream markers for the scroll markup.
   foundStreamMarker := false;
   if (sMarkers._length() > 0) {
      for (i = 0; i < sMarkers._length(); ++i) {
         if ( mCollection->m_sMarkers._indexin(sMarkers[i]) ) {
            _StreamMarkerGet(sMarkers[i],auto info);
            if ( !(_MarkerTypeGetFlags(info.type)&VSMARKERTYPEFLAG_DRAW_SCROLL_BAR_MARKER) ) {
               // If the cursor is on a stream marker listed in the browser,
               // we've found what we want.
               foundStreamMarker = true;
               messageMarker = "-1 "sMarkers[i];
               break;
            }
         }
      }
   } 
   if ( !foundStreamMarker ) {
      // If the cursor is not on a stream marker, the next thing to check for is
      // line markers.
      //_LineMarkerFindList(lMarkers, child_wid, child_wid.p_RLine, 0, 0);
      if (lMarkers._length() > 0) {
         for (i = 0; i < lMarkers._length(); ++i) {
            if (mCollection->m_lMarkers._indexin(lMarkers[i])) {
               messageMarker = lMarkers[i]" -1";
               break;
            }
         }
      }
      if (messageMarker == "-1 -1") {
         // Finally, look for stray stream markers on the current line.
         for (i = 0; i < sMarkers._length(); ++i) {
            if (mCollection->m_sMarkers._indexin(sMarkers[i])) {
               // If the line contains a stream markers listed in the
               // browser, we'll take it as a last resort.
               messageMarker = "-1 "sMarkers[i];
               break;
            }
         }
      }
   }
   if (needToRefresh) {
      messageBrowser->refreshMessages(form_wid);
   }
   
   _str lastMessage = _GetDialogInfoHt("lastMessage", form_wid);
   if (lastMessage != messageMarker) {
      form_wid.selectMessage(*messageBrowser, messageMarker);
      lastMessage = messageMarker;
      _SetDialogInfoHt("lastMessage", lastMessage, form_wid);
   }
}
void _UpdateMessages(bool AlwaysUpdate=false) {
   elapsed := _idle_time_elapsed();

   MESSAGE_LIST_FORM_INFO v;
   int i;
   foreach (i => v in gMessageListFormList) {
      int child_wid=i._MDIGetActiveMDIChild();
      _UpdateMessagesOne(v.m_form_wid,gMessageListFormList:[i],elapsed,child_wid,AlwaysUpdate);
   }
}

/**
 * Attempt to use the information in the message list tool window, including 
 * steam markers and line markers to map the given line number from error 
 * parsing to the actual line number the code is currently located on. 
 * Code could have been moved on account of edits, diff operations, 
 * beautification, auto-reload.  The line and stream markers track these 
 * changes accurately. 
 * 
 * @param sourceFile        name of source file (usually p_buf_name)
 * @param newLineNumber     (output) set to (adjusted) line number
 * @param newColumn         (output) set to (adjusted) column number
 * @param origLineNumber    original line number (as seen in error message)
 * @param origColumn        (optional) original column (as seen in error message)
 * 
 * @return Returns 'true' if the message could be mapped, 'false' otherwise.
 */
bool MessageBrowserMaybeMapLocation(_str sourceFile,
                                    int &newLineNumber, int &newColumn,
                                    int origLineNumber, int origColumn=0)
{
   newLineNumber = origLineNumber;
   newColumn     = origColumn? origColumn : newColumn;

   se.messages.MessageCollection* messages = null;
   form_wid := _tbGetActiveMessageListForm();
   if (form_wid > 0 && _iswindow_valid(form_wid)) {
      messages = form_wid.get_messageCollection();
   }
   if (!messages) {
      messages = _GetDialogInfoHtPtr("messageCollection", _app);
   }
   if (!messages) {
      return false;
   }

   return messages->mapCodeLocation(sourceFile, newLineNumber, newColumn, origLineNumber, origColumn);
}

_command void delete_message() name_info(',')
{
   form_wid := _tbGetActiveMessageListForm();
   if ((form_wid > 0) && _iswindow_valid(form_wid)) {
      form_wid.deleteMessage();
   }
}

_command void show_message_source() name_info(',')
{
   form_wid := _tbGetActiveMessageListForm();
   if ((form_wid > 0) && _iswindow_valid(form_wid)) {
      form_wid.goToMessage();
   }
}

defeventtab _tbmessages_browser_form;
void _tbmessages_browser_form.on_create()
{

   MESSAGE_LIST_FORM_INFO info;
   i := p_active_form;
   info.m_form_wid=p_active_form;
   gMessageListFormList:[i]=info;

   se.messages.MessageBrowser tempBrowser;
   _SetDialogInfoHt("messageBrowser", tempBrowser, p_active_form);

   lastMessage := "";
   _SetDialogInfoHt("lastMessage", lastMessage, p_active_form);

   _creator_label.p_x = 60;
   _creator_combo.p_y = 96;
   _creator_label.p_y = _creator_combo.p_y +
                        (_creator_combo.p_height - _creator_label.p_height) intdiv 2;
   _creator_combo.p_x = _creator_label.p_x_extent + 60;
   _type_label.p_y = _creator_label.p_y;
   _type_combo.p_y = _creator_combo.p_y;

   _message_tree.p_x = _creator_label.p_x;
   _message_tree.p_y = _creator_combo.p_y_extent + 60;

   _message_tree.p_AlwaysColorCurrent = true;
   _message_tree.p_Gridlines = TREE_GRID_BOTH;
   _message_tree._TreeSetColButtonInfo(0, 500, TREE_BUTTON_PUSHBUTTON|
                                       TREE_BUTTON_SORT_NUMBERS|
                                       TREE_BUTTON_SORT_COLUMN_ONLY, 0, "No.");
   _message_tree._TreeSetColButtonInfo(1, 500, TREE_BUTTON_PUSHBUTTON|
                                       TREE_BUTTON_SORT|
                                       TREE_BUTTON_SORT_COLUMN_ONLY, 0, "Type");
   _message_tree._TreeSetColButtonInfo(2, 2000, TREE_BUTTON_PUSHBUTTON|
                                       TREE_BUTTON_SORT_FILENAME|
                                       TREE_BUTTON_SORT_COLUMN_ONLY|
                                       TREE_BUTTON_IS_FILENAME, 0,
                                       "Source File");
   _message_tree._TreeSetColButtonInfo(3, 500, TREE_BUTTON_PUSHBUTTON|
                                       TREE_BUTTON_SORT_NUMBERS|
                                       TREE_BUTTON_SORT_COLUMN_ONLY|
                                       TREE_BUTTON_AL_RIGHT, 0, "Line");
   _message_tree._TreeSetColButtonInfo(4, 2000, TREE_BUTTON_PUSHBUTTON|
                                       TREE_BUTTON_SORT_COLUMN_ONLY|
                                       TREE_BUTTON_SORT|
                                       TREE_BUTTON_WRAP, 0, "Description");
   _message_tree._TreeSetColButtonInfo(5, 500, TREE_BUTTON_PUSHBUTTON|
                                       TREE_BUTTON_SORT_COLUMN_ONLY|
                                       TREE_BUTTON_SORT|TREE_BUTTON_AUTOSIZE, 0,
                                       "Creator");
}

void _tbmessages_browser_form.on_load()
{
   se.messages.MessageCollection* mCollection = get_messageCollection();
   se.messages.MessageBrowser* messageBrowser = _GetDialogInfoHtPtr("messageBrowser", p_active_form);
   if (messageBrowser) {
      messageBrowser->attach();
      messageBrowser->refreshMessages(p_active_form);
   }
}

void _tbmessages_browser_form.on_destroy()
{
   se.messages.MessageBrowser* messageBrowser = _GetDialogInfoHtPtr("messageBrowser", p_active_form);
   if (messageBrowser) {
      messageBrowser->detach();
   }
   _message_tree._TreeAppendColButtonInfo();
   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id, ON_DESTROY, "2");

   gMessageListFormList._deleteel(p_active_form);
}

// See _twSaveState__tbproctree_form and friends.
// 
void _twSaveState__tbmessages_browser_form(typeless& state, bool closing)
{
   _message_tree._TreeAppendColButtonInfo();
}

void _twRestoreState__tbmessages_browser_form(typeless& state, bool opening)
{
   _message_tree._TreeRetrieveColButtonInfo();
}

void _tbmessages_browser_form.on_resize()
{
   int width = _dx2lx(p_active_form.p_xyscale_mode,
                      p_active_form.p_client_width);
   int height = _dy2ly(p_active_form.p_xyscale_mode,
                       p_active_form.p_client_height);

   _type_label.p_x = _creator_combo.p_x_extent + 60;
   _type_combo.p_x = _type_label.p_x_extent + 60;
   _clear_button.p_x = _type_combo.p_x_extent + 60;

   orig_tree_width := _message_tree.p_width;
   _message_tree.p_y = _clear_button.p_y_extent + 60;
   //_message_tree.p_width = width - 120;
   _message_tree.p_width = width - 2*_message_tree.p_x;
   _message_tree.p_y_extent = height - 60;
   if ( !(p_window_flags & VSWFLAG_ON_RESIZE_ALREADY_CALLED) ) {
      // First time
      _message_tree._TreeRetrieveColButtonInfo();
   } else {
      _message_tree._TreeScaleColButtonWidths(orig_tree_width, true);
   }
}

static void refreshMessageBrowser(se.messages.MessageBrowser& messageBrowser)
{
   _creator_combo.p_text = "";
   _type_combo.p_text = "";
   _creator_combo._lbclear();
   _type_combo._lbclear();
   _message_tree._TreeBeginUpdate(TREE_ROOT_INDEX);
   _message_tree._TreeDelete(TREE_ROOT_INDEX, 'C');

   _creator_combo._lbadd_item(SHOW_ALL);
   foreach (auto creator => . in messageBrowser.m_creators) {
      _creator_combo._lbadd_item(creator);
   }
   _creator_combo._lbtop();
   _creator_combo.p_text = _creator_combo._lbget_text();

   _type_combo._lbadd_item(SHOW_ALL);
   foreach (auto type => . in messageBrowser.m_types) {
      _type_combo._lbadd_item(type);
   }
   _type_combo._lbtop();
   _type_combo.p_text = _type_combo._lbget_text();

   _str row;
   int i;
   int index;
   bool isRowColorSet;
   for (i = 0; i < messageBrowser.m_messages._length(); ++i) {
      row = makeMessageCaption(messageBrowser.m_messages[i], i+1);
      index = _message_tree._TreeAddItem(TREE_ROOT_INDEX, row,
                                         TREE_ADD_AS_CHILD,
                                         messageBrowser.m_messages[i]->m_markerPic,
                                         messageBrowser.m_messages[i]->m_markerPic,
                                         -1, 0, i);
      colorRow(messageBrowser, _message_tree, index, i);
   }
   _message_tree._TreeEndUpdate(TREE_ROOT_INDEX);
   _message_tree._TreeRefresh();
}

void _creator_combo.on_change()
{
   maybeFilterMessages();
}

void _type_combo.on_change()
{
   maybeFilterMessages();
}

static void maybeFilterMessages()
{
   if (_GetDialogInfoHt("maybeFilterMessages") == true) {
      return;
   }
   _SetDialogInfoHt("maybeFilterMessages", true);
   creator := _creator_combo.p_text;
   type := _type_combo.p_text;
   if (creator == SHOW_ALL) creator = "";
   if (type == SHOW_ALL) type = "";
   _message_tree.filterMessages(creator, type);
   _SetDialogInfoHt("maybeFilterMessages", false);
}

void _clear_button.lbutton_up()
{
   creator := _creator_combo.p_text;
   type := _type_combo.p_text;

   if (creator == SHOW_ALL) {
      creator = null;
   }
   if (type == SHOW_ALL) {
      type = null;
   }

   se.messages.MessageCollection* mCollection = get_messageCollection();
   mCollection->removeMessages(creator, type);
}

void _message_tree.DEL()
{
   deleteMessage();
}

void _message_tree.rbutton_up()
{
   menuName := "_message_tree_menu";
   int menuIDX = find_index(menuName, oi2type(OI_MENU));
   if (!menuIDX) {
      return;
   }

   int menuHandle = p_active_form._menu_load(menuIDX, 'P');
   if (menuHandle < 0) {
      _message_box("Unable to load menu: \"":+menuName:+"\"","",
                   MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   int x = VSDEFAULT_INITIAL_MENU_OFFSET_X;
   int y = VSDEFAULT_INITIAL_MENU_OFFSET_Y;
   x = mou_last_x('M') - x;
   y = mou_last_y('M') - y;
   _lxy2dxy(p_scale_mode, x, y);
   _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   int flags = VPM_LEFTALIGN|VPM_RIGHTBUTTON;

   treeIDX := _message_tree._TreeCurIndex();
   int msgIDX = getMessageIDX(treeIDX);
   if (msgIDX < 0) {
      return;
   }
   
   se.messages.MessageCollection* mCollection = get_messageCollection();
   se.messages.Message* tmpMsg;
   mCollection->getMessage(tmpMsg, msgIDX);

   if (tmpMsg->m_sourceFile != "") {
      _menu_insert(menuHandle, -1, MF_ENABLED, "-", "", "", "", "");
      _menu_insert(menuHandle, -1, MF_ENABLED, "&Go to Message",
                   "show-message-source", "", "", "");
   }

   if (tmpMsg->m_menuItems._length() > 0) {
      _menu_insert(menuHandle, -1, MF_ENABLED, "-", "", "", "", "");
   }

   int i;
   for (i = 0; i < tmpMsg->m_menuItems._length(); ++i) {
      _menu_insert(menuHandle, -1, MF_ENABLED, tmpMsg->m_menuItems[i].m_menuText,
                   tmpMsg->m_menuItems[i].m_callback" "tmpMsg, "", "", "");
   }

   int status = _menu_show(menuHandle, flags, x, y);
   _menu_destroy(menuHandle);
}

void _message_tree.on_change(int reason, int index) 
{
   se.messages.MessageBrowser* messageBrowser = _GetDialogInfoHtPtr("messageBrowser", p_active_form);
   if (!messageBrowser) {
      return;
   }
   row := "";
   sourceFile := "";
   int i;
   int twid;
   line := 0;
   column := 0;

   switch (reason) {
   case CHANGE_BUTTON_PRESS:
      break;

   case CHANGE_SELECTED:
      i = getMessageIDX(index);
      if (i < 0) {
         break;
      }

      tag_init_tag_browse_info(auto cm);
      if ( i < 0 || i >= messageBrowser->m_messages._length() )  break;
      if ( messageBrowser->m_messages[i] == null ) break;
      cm.file_name = messageBrowser->m_messages[i]->m_sourceFile;
      cm.line_no = messageBrowser->m_messages[i]->m_lineNumber;
      cm.type_name = "message";
      cm.member_name = messageBrowser->m_messages[i]->m_type" "i+1;
      cb_refresh_output_tab(cm, true, true, false, APF_MESSAGE_LIST);
      break;

   case CHANGE_LEAF_ENTER:
      windowID := p_window_id;
      i = getMessageIDX(index);
      if (messageBrowser->goToMessageCodeLocation(i)) {
         row = makeMessageCaption(messageBrowser->m_messages[i], i+1);
         index = windowID._TreeSearch(TREE_ROOT_INDEX, "", "", i);
         windowID._TreeSetCaption(index, row);
      }
      colorRow(*messageBrowser, windowID, index, i);
      windowID._TreeRefresh(); // Immediately recolor the visited row.


      break;

   default:
      break;
   }
}

static void filterMessages(_str creator="", _str type="")
{
   origFlags := 0;
   showChildren := 0;
   bm1 := bm2 := 0;

   curIndex := _TreeCurIndex();
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   lastIndex := TREE_ROOT_INDEX;
   while (index > 0) {
      messageText := _TreeGetCaption(index);
      parse messageText with . "\t" auto typeText "\t" . "\t" . "\t" . "\t" auto creatorText "\t" .;

      creatorMatch := ((creator != "") && (creator == creatorText));
      typeMatch    := ((type != "") && (type == typeText));

      flags := 0;
      if ((creator != "") && (type != "")) {
         flags = (creatorMatch && typeMatch) ? 0 : TREENODE_HIDDEN;
      } else if (creator != "") {
         flags = (creatorMatch) ? 0 : TREENODE_HIDDEN;
      } else if (type != "") {
         flags = (typeMatch) ? 0 : TREENODE_HIDDEN;
      }

      if ((index == curIndex) && (flags & TREENODE_HIDDEN)) {
         curIndex = TREE_ROOT_INDEX;
      }

      // Get the original tree flags for this node.
      _TreeGetInfo(index, showChildren, bm1, bm2, origFlags, auto lineNumber, TREENODE_HIDDEN);

      // Did the hidden flag change?
      if ((flags & TREENODE_HIDDEN) != (origFlags & TREENODE_HIDDEN)) {
         origFlags &= ~TREENODE_HIDDEN;
         flags |= origFlags;
         _TreeSetInfo(index, showChildren, bm1, bm2, flags, 0, TREENODE_HIDDEN);
         lastIndex = index;
      }

      index = _TreeGetNextSiblingIndex(index);
   }

   if (lastIndex > TREE_ROOT_INDEX) {
      _TreeGetInfo(lastIndex, showChildren, bm1, bm2, origFlags);
      _TreeSetInfo(lastIndex, showChildren, bm1, bm2, origFlags, 1);
   }

   int newIndex;
   newIndex = _TreeCurIndex();
   int nextIndex;
   if (curIndex == TREE_ROOT_INDEX) {
      nextIndex = _TreeGetNextIndex(TREE_ROOT_INDEX);
      newIndex = (nextIndex > 0) ? nextIndex : TREE_ROOT_INDEX;
   }

   if (newIndex > TREE_ROOT_INDEX) {
      _TreeSetCurIndex(newIndex);
      if (curIndex != newIndex) {
         call_event(CHANGE_SELECTED, newIndex, p_window_id, ON_CHANGE, 'W');
      }
   }
   _TreeRefresh();
}

static int getMessageIDX(int treeIDX)
{
   userInfo := "";
   result := -1;

   if (treeIDX <= TREE_ROOT_INDEX) {
      return result;
   }

   form_wid := _tbGetActiveMessageListForm();
   if (!form_wid) {
      return -1;
   }
   int treeWID = form_wid._message_tree;
   userInfo = treeWID._TreeGetUserInfo(treeIDX);

   if (isinteger(userInfo)) {
      result = (int)userInfo;
   }

   return result;
}

static void selectMessage(se.messages.MessageBrowser& messageBrowser, _str messageMarker)
{
   wid := p_window_id;
   p_window_id = _message_tree;

   messageMarkerIDs := "-1 -1";
   int msgIDX;

   treeIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);

   for (;;) {
      msgIDX = getMessageIDX(treeIndex);
      if ((msgIDX < 0) || (msgIDX >= messageBrowser.m_messages._length())) break;
      if (!messageBrowser.m_messages[msgIDX]) break;
      messageMarkerIDs = messageBrowser.m_messages[msgIDX]->m_lmarkerID" ":+
                         messageBrowser.m_messages[msgIDX]->m_smarkerID;
      if (messageMarkerIDs == messageMarker) {
         break;
      }

      treeIndex = _TreeGetNextSiblingIndex(treeIndex);
      if (treeIndex < 0) {
         break;
      }
   }
   if (treeIndex>0) {
      _TreeSelectLine(treeIndex);
      _TreeSetCurIndex(treeIndex);
   }
   
   p_window_id = wid;
}

static void deleteMessage()
{
   treeIDX := _message_tree._TreeCurIndex();
   int msgIDX = getMessageIDX(treeIDX);
   if (msgIDX < 0) {
      return;
   }

   se.messages.MessageCollection* mCollection = get_messageCollection();
   mCollection->removeMessage(msgIDX);
}

static void goToMessage()
{
   _message_tree.call_event(CHANGE_LEAF_ENTER, _message_tree._TreeCurIndex(), 0,
                            _message_tree, ON_CHANGE, 'w');
}

static _str makeMessageCaption(se.messages.Message* msg, int i)
{
   _str row = i;
   row :+= "\t";
   row :+= msg->m_type;
   row :+= "\t";
   row :+= msg->m_sourceFile;
   row :+= "\t";
   row :+= msg->m_lineNumber;
   row :+= "\t";
   row :+= msg->getDescription();
   row :+= "\t";
   row :+= msg->m_creator;
   return row;
}

static void colorRow(se.messages.MessageBrowser& messageBrowser, int windowID, int treeIDX, int msgIDX)
{
   isRowColorSet := false;
   if (messageBrowser.m_messages[msgIDX]->m_lineModified) {
      windowID._TreeSetRowColor(treeIDX, _hex2dec(def_message_modified_color), 0,
                                F_INHERIT_BG_COLOR);
      isRowColorSet = true;
   }
   if (!isRowColorSet && messageBrowser.m_messages[msgIDX]->m_lineVisited) {
      windowID._TreeSetRowColor(treeIDX, _hex2dec(def_message_visited_color), 0,
                                F_INHERIT_BG_COLOR);
      isRowColorSet = true;
   }
   if (!isRowColorSet) {
      windowID._TreeSetRowColor(treeIDX, 0, 0,
                                F_INHERIT_FG_COLOR | F_INHERIT_BG_COLOR);
   }
}

_str def_message_visited_color = "0xEDB012";  // Color is in BGR format, not RGB
_str def_message_modified_color = "0x0000FF"; //
