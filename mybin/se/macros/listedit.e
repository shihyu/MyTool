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
#import "guiopen.e"
#import "picture.e"
#import "stdprocs.e"
#import "treeview.e"
#endregion

/**
 * This module implements generic code for implementing a list
 * editor using a tree control.  The generic dialog has the following
 * set of controls:
 * <pre>
 *      ------------------    ------
 *     |                  |    Edit
 *     |  Tree Control    |   ------
 *     |                  |
 *     |                  |   ------
 *     |                  |     Up
 *     |                  |   ------
 *     |                  |
 *     |                  |   ------
 *     |                  |    Down
 *     |                  |   ------
 *     |                  |       
 *     |                  |   ------
 *     |                  |   Delete
 *      ------------------    ------
 * </pre>
 * With the tab order being the tree, edit, up, down and then
 * delete.
 * The buttons are optional.  However, if you use the "Up" and
 * "Down" buttons, the "Edit" button must be on the form.
 * If you do not want it, simply add a button on the form in the
 * correct tab order and make it disabled and invisible.
 * <p>
 * Use this set of controls as follows:
 * <UL>
 * <LI>Have a tree control on your dialog.  Make sure it has
 *     "EditInPlace" turned on.
 * <LI>Open this form and copy the "Edit", "Up" and "Down" controls,
 *     then paste them on to your form, such that you inherit their
 *     event handlers.
 * <LI>Make sure the tab orders are correct.
 * <LI>Modify the "Edit" button's visibility, enabled state, and
 *     customize the event handler, if you wish to use it.
 * </UL>
 * The code uses the user info of the tree to store the string
 * used to show where to add an item.
 *
 * @author Dennis Brueni
 * @since  8.0
 */

/**
 * Message to display for new node
 */
#define LIST_EDITOR_BLANK_NODE_MSG  "<double click here to add another entry>"


/**
 * use these with _SetDialogInfo( ..., ctl_tree) and _GetDialogInfo(..., ctl_tree)
 */
#define LIST_EDITOR_ADD_CAPTION     (0)
#define LIST_EDITOR_EDIT_CALLBACK   (1)
#define LIST_EDITOR_IS_SORTED       (2)
#define LIST_EDITOR_DELETE_CALLBACK (3)
#define LIST_EDITOR_COMPLETION      (4)

///////////////////////////////////////////////////////////////////////////////
/**
 * Form used for modifying the a list of items stored in an
 * editable tree control.
 */
defeventtab _list_editor_form;

_nocheck _control ctl_tree;

static _str list_editor_default_edit();

/**
 * On create to create a generic instance of the list editor form.
 */
void _list_editor_form.on_create(_str dialogCaption='', _str listCaption='',
                                 _str list[]=null,
                                 typeless editCallback=list_editor_default_edit,
                                 _str addCaption=LIST_EDITOR_BLANK_NODE_MSG,
                                 _str helpItem='',
                                 boolean sorted = false,
                                 typeless deleteCallback=null,
                                 _str completionOption = "")
{
   _list_editor_form_initial_alignment();

   if (dialogCaption!='') {
      p_caption = dialogCaption;
   }
   if (listCaption!='') {
      ctl_list_label.p_caption=listCaption;
   }
   if (addCaption=='') {
      addCaption = LIST_EDITOR_BLANK_NODE_MSG;
   }

   // if the list is sorted, we don't care about up/down buttons
   _SetDialogInfo(LIST_EDITOR_IS_SORTED, sorted, ctl_tree);
   if (sorted) {
      ctl_up_btn.p_visible = false;
      ctl_down_btn.p_visible = false;
      ctl_del_button.p_y = ctl_up_btn.p_y;
   }

   _SetDialogInfo(LIST_EDITOR_ADD_CAPTION,addCaption,ctl_tree);
   _SetDialogInfo(LIST_EDITOR_EDIT_CALLBACK,editCallback,ctl_tree);
   _SetDialogInfo(LIST_EDITOR_DELETE_CALLBACK,deleteCallback,ctl_tree);
   _SetDialogInfo(LIST_EDITOR_COMPLETION,completionOption,ctl_tree);
   ctl_tree.list_editor_set_list(list,false,addCaption);

   p_help = helpItem;
}

/**
 * Handle the OK button being pressed.  Since the dialog is
 * normally modal, return the list of items.
 */
void ctl_ok_btn.lbutton_up()
{
   //_str result=ctl_tree._TreeGetDelimitedItemList("\1");
   _param1=list_editor_get_list();
   p_active_form._delete_window('ok');
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _list_editor_form_initial_alignment()
{
   rightAlign := p_active_form.p_width - ctl_tree.p_x;
   alignUpDownListButtons(ctl_tree, rightAlign, ctl_new_button.p_window_id,
                          ctl_up_btn.p_window_id, ctl_down_btn.p_window_id, ctl_del_button.p_window_id);
}

/**
 * Handle resizing of the list editor form.
 */
void _list_editor_form.on_resize()
{
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(ctl_ok_btn.p_width*4, ctl_ok_btn.p_height*8);
   }

   padding := ctl_tree.p_x;
   deltax := p_width - (ctl_new_button.p_x + ctl_new_button.p_width + padding);
   deltay := p_height - (ctl_ok_btn.p_y + ctl_ok_btn.p_height + padding);

   // move the OK and Cancel buttons
   ctl_ok_btn.p_y += deltay;
   ctl_cancel_btn.p_y = ctl_ok_btn.p_y;

   // resize the RHS buttons
   ctl_new_button.p_x += deltax;
   ctl_up_btn.p_x   = ctl_new_button.p_x;
   ctl_down_btn.p_x = ctl_new_button.p_x;
   ctl_del_button.p_x = ctl_new_button.p_x;

   // resize the main tree control
   ctl_tree.p_height += deltay;
   ctl_tree.p_width += deltax;
}

/**
 * Initialization code to do when form is created.
 * The current object must be the tree control.
 */
void list_editor_initialize(_str addCaption=LIST_EDITOR_BLANK_NODE_MSG)
{
   _str a[]; a._makeempty();
   list_editor_set_list(a,false,addCaption);
}

/**
 * Handle the on_change() event for the tree being edited.
 * The current object must be the tree control.
 *
 * @param reason     reason code sent to on_change() of tree control
 * @param index      tree index sent to on_change() of tree control
 */
int list_editor_on_change(int reason, int index, int column, _str &newCaption, int textBoxWid=0)
{
   if (reason == CHANGE_EDIT_OPEN_COMPLETE) {
      completion := _GetDialogInfo(LIST_EDITOR_COMPLETION,ctl_tree);
      if (textBoxWid !=0 && completion != "") {
         textBoxWid.p_completion = completion;
      }
   }

   if (reason == CHANGE_EDIT_OPEN) {
      // if this is the new entry node, clear the message
      if (strieq(newCaption, _GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree))) {
         newCaption = "";
      }
   }

   if (reason == CHANGE_EDIT_CLOSE) {
      // check the old caption to see if it is the new entry node
      boolean wasNewEntryNode = strieq(_TreeGetCaption(index), _GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree));

      if (wasNewEntryNode) {
         // unbold the existing node
         _TreeSetInfo(index, -1, -1, -1, 0);
      }

      // if the node changed and is now empty, delete it
      if (newCaption == "") {
         if (wasNewEntryNode) {
            newCaption = _GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree);
            return 0;
         } else {
            _TreeDelete(index);
            return DELETED_ELEMENT_RC;
         }
      }

      // make sure the last node in the tree is the new entry node
      if (wasNewEntryNode) {
         // bold the new entry node
         int newIndex = _TreeAddListItem(_GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree));
         _TreeSetInfo(newIndex, -1, -1, -1, TREENODE_BOLD);
      }
   }

   // that's all folks
   return 0;
}
int ctl_tree.on_change(int reason,int index,int col=-1,_str value="",int wid=0)
{
   if (reason==CHANGE_EDIT_OPEN || reason==CHANGE_EDIT_CLOSE || reason==CHANGE_EDIT_OPEN_COMPLETE) {
      return list_editor_on_change(reason,index,col,value,wid);

   } else if (reason == CHANGE_OTHER) {

      if (_GetDialogInfo(LIST_EDITOR_IS_SORTED, ctl_tree)) {
         origIndex := ctl_tree._TreeCurIndex();

         ctl_tree._TreeSortCaption(TREE_ROOT_INDEX);

         // find our 'add new item' line - will be first
         ctl_tree._TreeTop();

         addItemLine := ctl_tree._TreeCurIndex();
         // make sure this is the right one
         if (strieq(ctl_tree._TreeGetCaption(addItemLine), _GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree))) {
            // delete it
            ctl_tree._TreeDelete(addItemLine);

            // add it at the bottom - bold!
            int newIndex = ctl_tree._TreeAddListItem(_GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree));
            ctl_tree._TreeSetInfo(newIndex, -1, -1, -1, TREENODE_BOLD);
         }

      }
   }
   return 0;
}

/**
 * Handle the user hitting 'delete' in the tree node.
 * The current object (p_window_id) must be the tree control.
 */
void list_editor_delete()
{
   // with single node selection, if there is a current index, it is selected
   int index = ctl_tree._TreeCurIndex();
   if (index > 0) {
      // cannot delete new entry node
      if (strieq(ctl_tree._TreeGetCaption(index), _GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree))) {
         return;
      }

      caption := ctl_tree._TreeGetCaption(index);
      typeless delete_callback=_GetDialogInfo(LIST_EDITOR_DELETE_CALLBACK,ctl_tree);
      if (delete_callback!=null && _isfunptr(delete_callback)) {
         (*delete_callback)(caption);
      }

      ctl_tree._TreeDelete(index);
   }
}

void ctl_new_button.lbutton_up()
{
   int wid=p_window_id;

   typeless edit_callback=_GetDialogInfo(LIST_EDITOR_EDIT_CALLBACK,ctl_tree);
   if (edit_callback==null || !_isfunptr(edit_callback)) {
      edit_callback=list_editor_default_edit;
      _SetDialogInfo(LIST_EDITOR_EDIT_CALLBACK,edit_callback,ctl_tree);
      if (_GetDialogInfo(LIST_EDITOR_COMPLETION,ctl_tree) == "") {
         _SetDialogInfo(LIST_EDITOR_COMPLETION,FILE_ARG);
      }
   }

   _str result=(*edit_callback)();

   if (result=='') {
      return;
   }

   p_window_id=wid.list_editor_find_tree();
   index := _TreeAddListItem(result);
   _TreeSetCurIndex(index);
   p_window_id=wid;
}

void ctl_del_button.lbutton_up()
{
   list_editor_delete();
}

void ctl_tree.'DEL'()
{
   list_editor_delete();
}

/**
 * Find the tree control associated with this list editor button.
 */
int list_editor_find_tree()
{
   int wid = p_window_id;
   while (wid>=0 && wid.p_object!=OI_TREE_VIEW) {
      wid=wid.p_prev;
   }
   return wid;
}

/**
 * Move an item up in the list
 */
static void move_item_up()
{
   // find the tree control relative to the edit control
   int wid = p_window_id;
   p_window_id = list_editor_find_tree();

   // with single node selection, if there is a current index, it is selected
   int index = _TreeCurIndex();
   if (index > 0) {
      // handle special cases where this is the new entry node or the prev
      // node is the new entry node
      int prevIndex = _TreeGetPrevSiblingIndex(index);
      if (prevIndex == -1) return;
      if (strieq(_TreeGetCaption(index), _GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree))) return;
      if (strieq(_TreeGetCaption(prevIndex), _GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree))) return;

      _TreeMoveUp(index);

      // trigger the on_change event so that the data will be saved
      call_event(CHANGE_SELECTED, index,
                 find_index(p_active_form.p_name"."p_name, EVENTTAB_TYPE),
                 ON_CHANGE, 'E');
   }

   p_window_id = wid;
}

void ctl_up_btn.lbutton_up()
{
   move_item_up();
}

void _list_editor_form.'C-UP'()
{
   move_item_up();
}

/**
 * Shift an item down in the list
 */
static void move_item_down()
{
   // find the tree control relative to the edit control
   int wid = p_window_id;
   p_window_id = list_editor_find_tree();

   // with single node selection, if there is a current index, it is selected
   int index = _TreeCurIndex();
   if (index > 0) {
      // handle special cases where this is the new entry node or the next node
      // is the new entry node
      int nextIndex = _TreeGetNextSiblingIndex(index);
      if (nextIndex == -1) return;
      if (strieq(_TreeGetCaption(index), _GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree))) return;
      if (strieq(_TreeGetCaption(nextIndex), _GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree))) return;

      _TreeMoveDown(index);

      // trigger the on_change event so that the data will be saved
      call_event(CHANGE_SELECTED, index,
                 find_index(p_active_form.p_name"."p_name, EVENTTAB_TYPE),
                 ON_CHANGE, 'E');
   }

   p_window_id = wid;
}

void ctl_down_btn.lbutton_up()
{
   move_item_down();
}

_list_editor_form.'C-DOWN'()
{
   move_item_down();
}

static _str list_editor_default_edit()
{
   _str result=_OpenDialog('-modal',
                    'Choose File',        // Dialog Box Title
                    '',                   // Initial Wild Cards
                    "All Files (*.*)",    // File Type List
                    OFN_FILEMUSTEXIST     // Flags
                    );
   result=strip(result,'B','"');
   return result;
}

/**
 * Return the contents of the currently selected item.
 * If there is no current item, or the current item is
 * the "add new item" node, return ''.
 * <p>
 * The current control should be the tree control.
 */
_str list_editor_get_cur_item()
{
   // make sure the current node is sensible
   int index = _TreeCurIndex();
   if (index <= 0) {
      return('');
   }

   // is this the "add new item" node?
   _str caption=_TreeGetCaption(index);
   if (strieq(_TreeGetCaption(index), _GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree))) {
      return('');
   }

   // that's all folk;
   return caption;
}

/**
 * Modify the selected item in the tree, or add a new item
 * if the selected item is the "&lt;add new&gt; caption.
 *
 * The current control should be the tree control.
 */
void list_editor_set_cur_item(_str caption)
{
   // make sure the current node is sensible
   int index = _TreeCurIndex();
   if (index <= 0) {
      return;
   }

   addNewItem := strieq(_TreeGetCaption(index), _GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree));

   // unbold the existing node
   _TreeSetInfo(index, -1, -1, -1, 0);

   _TreeSetCaption(index,caption);

   // sort the list if necessary
   if (_GetDialogInfo(LIST_EDITOR_IS_SORTED, ctl_tree)) {
      _TreeSortCol();
   }

   // is this the "add new item" node?
   if (addNewItem) {

      // add and bold the new entry node
      int newIndex = _TreeAddListItem(_GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree));
      _TreeSetInfo(newIndex, -1, -1, -1, TREENODE_BOLD);
   }

   // that's all folk;
   _TreeRefresh();
}

/**
 * Returns list built from the tree delimited by the specified
 * delimiter.
 *
 * IMPORTANT: p_window_id *must* be a tree control
 *
 * @param delimiter
 *
 * @return
 */
typeless list_editor_get_list()
{
   _str list[]; list._makeempty();

   int index = ctl_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index >= 0) {
      // get the caption and skip the node reserved for new entry
      _str caption = ctl_tree._TreeGetCaption(index);
      if (!strieq(caption, _GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree))) {
         list[list._length()] = caption;
      }
      // move to next node
      index = ctl_tree._TreeGetNextSiblingIndex(index);
   }

   return list;
}

/**
 * Builds the tree from the list delimited by the specified
 * delimiter.
 *
 * IMPORTANT: p_window_id *must* be a tree control
 *
 * @param list             List of items to be entered into the tree
 * @param delimiter        Delimiter separating each item in the list
 * @param allowDuplicates  Allow duplicate nodes in the tree
 * @param addCaption       Caption to use when adding nodes
 */
void list_editor_set_list(_str list[], boolean allowDuplicates = false,
                          _str addCaption=LIST_EDITOR_BLANK_NODE_MSG)
{
   // remove previous list items
   _TreeDelete(TREE_ROOT_INDEX, 'C');

   // for each item in the array
   int i,n=list._length();
   for (i=0; i<n; ++i) {

      // make sure the node isnt already in the tree if duplicates are not allowed
      if (!allowDuplicates && _TreeSearch(TREE_ROOT_INDEX, list[i]) >= 0) {
         continue;
      }

      _TreeAddListItem(list[i]);
   }

   // sort the list if necessary
   if (_GetDialogInfo(LIST_EDITOR_IS_SORTED, ctl_tree)) {
      ctl_tree._TreeSortCol(0);
   }

   // add the node for new data
   _SetDialogInfo(LIST_EDITOR_ADD_CAPTION,addCaption,ctl_tree);
   int newIndex = _TreeAddListItem(addCaption);
   _TreeSetInfo(newIndex, -1, -1, -1, TREENODE_BOLD);
}


/**
 * Returns list built from the tree delimited by the specified
 * delimiter.
 * <p>
 * IMPORTANT: p_window_id *must* be a tree control
 *
 * @param delimiter
 *
 * @return items in list delimited by the given delimiter string
 */
_str list_editor_get_delimited_list(_str delimiter)
{
   _str list = '';

   int index = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index >= 0) {
      // get the caption and skip the node reserved for new entry
      _str caption = _TreeGetCaption(index);
      if (strieq(caption, _GetDialogInfo(LIST_EDITOR_ADD_CAPTION,ctl_tree))) {
         continue;
      }

      if (list != '') {
         list = list :+ delimiter :+ caption;
      } else {
         list = caption;
      }

      // move to next node
      index = _TreeGetNextSiblingIndex(index);
   }

   return list;
}

/**
 * Builds the tree from the list delimited by the specified
 * delimiter.
 *
 * IMPORTANT: p_window_id *must* be a tree control
 *
 * @param list      List of items to be entered into the tree
 * @param delimiter Delimiter separating each item in the list
 * @param allowDuplicates
 *                  Allow duplicate nodes in the tree
 */
void list_editor_set_delimited_list(_str list, _str delimiter,
                                    boolean allowDuplicates=false,
                                    _str addCaption=LIST_EDITOR_BLANK_NODE_MSG)
{
   // remove previous list items
   _TreeDelete(TREE_ROOT_INDEX, 'C');

   _str node;
   for(;;) {
      if (list == '') {
         break;
      }
      parse list with node (delimiter) list;
      if (node != '') {
         // make sure the node isnt already in the tree if duplicates are not allowed
         if (!allowDuplicates && _TreeSearch(TREE_ROOT_INDEX, node) >= 0) {
            continue;
         }

         _TreeAddListItem(node);
      }
   }

   // add the node for new data
   _SetDialogInfo(LIST_EDITOR_ADD_CAPTION,addCaption,ctl_tree);
   int newIndex = _TreeAddListItem(addCaption);
   _TreeSetInfo(newIndex, -1, -1, -1, TREENODE_BOLD);
}

