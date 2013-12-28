////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50444 $
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
#include "treeview.sh"
#include "tagsdb.sh"
#include "xml.sh"
#import "cbrowser.e"
#import "combobox.e"
#import "complete.e"
#import "fileman.e"
#import "files.e"
#import "guiopen.e"
#import "math.e"
#import "print.e"
#import "proctree.e"
#import "search.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tbautohide.e"
#import "util.e"
#import "wkspace.e"
#import "sc/controls/Table.e"
#require "sc/lang/String.e"
#include "filewatch.sh"
#endregion

using namespace sc.controls;

/*
    For on_change function with CHANGE_EDIT_OPEN,
    CHANGE_EDIT_CLOSE, and CHANGE_EDIT_QUERY
    reasons:
      arg(1) is reason
      arg(2) is index
      arg(3) is col.  col can be -1 if there are no columns.
      arg(4) is the text.  For CHANGE_EDIT_OPEN, modify the text to be
             what you want to be in the text box.  For CHANGE_EDIT_CLOSE
             ,modify the text to be what you want to go back into the tree
             control.  Changing text has no effect for CHANGE_EDIT_QUERY,
             but it is still provided so that this may be used to help make
             the decision weather or not to allow a window to be created.

      When you get an event with reason CHANGE_EDIT_OPEN, you can
      prevent an edit box from coming up by returning -1.

      When you get an event with reason CHANGE_EDIT_CLOSE, you can
      prevent changes from being made to the edit box from coming up by
      returning -1.

      When you get an event with reason CHANGE_EDIT_QUERY, you can
      prevent an edit box from coming up by returning -1.

      For any of these events, if you delete the node, return  DELETED_ELEMENT_RC.

      If you catch the change collapsed event, you should return '', or -1 if
      you do not want to change the current node.  If you want to change the
      current node, return the index of the new current node.  Do not return
      0 unless you want the root node to be set active.  This will do screwy
      things if you do it by accident since in most cases it is not visible.
*/

using sc.lang.String;

#define FILE_DEPTH     1
#define FUNCTION_DEPTH 2

/**
 * Command used by right-click context menus for trees.  Expands all the nodes 
 * in the tree. 
 * 
 * @param treeWid          window id of treeview to act upon, to use the current 
 *                         object, send nothing
 */
_command void TreeExpandAll(int treeWid = 0) name_info(',')
{
   // get our tree window id
   if (treeWid == 0) treeWid = p_window_id;
   
   // make sure this is a tree, please
   if (treeWid.p_object != OI_TREE_VIEW) return;

   // now, get to it
   treeWid._TreeExpandAll();
}

/**
 * Command used by right-click context menus for trees.  Expands children of the 
 * given node. 
 * 
 * @param treeWid          window id of treeview to act upon, send 0 to use the 
 *                         current object
 * @param index            index to expand, send -1 to use the tree's current 
 *                         index
 */
_command void TreeExpandChildren(int treeWid = 0, int index = -1) name_info(',')
{
   // get our tree window id
   if (treeWid == 0) treeWid = p_window_id;

   // make sure this is a tree!
   if (treeWid.p_object != OI_TREE_VIEW) return;

   // what index are we expanding?
   if (index < 0) index = treeWid._TreeCurIndex();

   // now expand it!
   treeWid._TreeExpandChildren(index);
}

/**
 * Command used by right-click context menus for trees.  Expands children of the 
 * given node. 
 * 
 * @param levels           how many levels to expand, send -1 to expand all 
 *                         children of this node
 * @param treeWid          window id of treeview to act upon, send 0 to use the 
 *                         current object
 * @param index            index to expand, send -1 to use the tree's current 
 *                         index
 */
_command void TreeExpandChildrenNLevels(int levels = -1, int treeWid = 0, int index = -1) name_info(',')
{
   // get our tree window id
   if (treeWid == 0) treeWid = p_window_id;

   // make sure this is a tree!
   if (treeWid.p_object != OI_TREE_VIEW) return;

   // what index are we expanding?
   if (index < 0) index = treeWid._TreeCurIndex();

   // now expand it!
   treeWid._TreeExpandChildren(index, levels);
}

/**
 * Command used by right-click context menus for trees.  Collapses all nodes in 
 * the tree. 
 * 
 * @param treeWid          window id of treeview to act upon, send 0 to use the 
 *                         current object
 */
_command void TreeCollapseAll(int treeWid = 0) name_info(',')
{
   // get our tree window id
   if (treeWid == 0) treeWid = p_window_id;
   
   // make sure this is a tree, please
   if (treeWid.p_object != OI_TREE_VIEW) return;

   // now, get to it
   treeWid._TreeCollapseAll();
}

/**
 * Collapses all nodes in the treeview except for the given node.
 * 
 * @param treeWid          window id of treeview to act upon, send 0 to use the 
 *                         current object
 * @param index            index to NOT collapse, send 0 to use the current 
 *                         index
 */
_command void TreeCollapseOthers(int treeWid = 0, int index = -1) name_info(',')
{
   // get our tree window id
   if (treeWid == 0) treeWid = p_window_id;
   
   // make sure this is a tree, please
   if (treeWid.p_object != OI_TREE_VIEW) return;

   // what index are we NOT collapsing?
   if (index < 0) index = treeWid._TreeCurIndex();

   // now, get to it
   treeWid._TreeCollapseOthers(index);
}

defeventtab _ul2_tree;

void _ul2_tree.HOME()
{
   _TreeCommand("home");
}

void _ul2_tree.END()
{
   _TreeCommand("end");
}

void _ul2_tree.PGUP,'C-P'()
{
   _TreeCommand("pageup");
}

void _ul2_tree.PGDN,'C-N'()
{
   _TreeCommand("pagedown");
}

int _ul2_tree.up,'C-I'()
{
   _TreeCommand("up");
   return(0);
}

int _ul2_tree.down,'C-K'()
{
   _TreeCommand("down");
   return(0);
}

int _ul2_tree.s_down()
{
   _TreeCommand("s-down");
   return(0);
}

int _ul2_tree.s_up()
{
   _TreeCommand("s-up");
   return 0;
}

int _ul2_tree.s_home()
{
   _TreeCommand("s-home");
   return 0;
}

int _ul2_tree.s_end()
{
   _TreeCommand("s-end");
   return 0;
}

int _ul2_tree.'c-s-home'()
{
   _TreeCommand("c-s-home");
   return 0;
}

int _ul2_tree.'c-s-end'()
{
   _TreeCommand("c-s-end");
   return 0;
}

void _ul2_tree.right()
{
#if 0
   int index=_TreeCurIndex();
   if (index<0) return;
   int state=0;
   _TreeGetInfo(index,state);
   if (state == TREE_NODE_COLLAPSED) {
      int wid=p_window_id;
      call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');
      p_window_id=wid;
      _TreeSetInfo(index,1);
   }else if (state == TREE_NODE_EXPANDED) {
      int ChildIndex=_TreeGetFirstChildIndex(index);
      if (ChildIndex<0) return;
      int bm1=0, bm2=0, flags=0;
      _TreeGetInfo(ChildIndex,state,bm1,bm2,flags);
      //Gotta keep hunting until we find a child that is not hidden
      while (flags&TREENODE_HIDDEN) {
         ChildIndex=_TreeGetNextSiblingIndex(ChildIndex);
         if (ChildIndex<0) break;
         _TreeGetInfo(ChildIndex,state,bm1,bm2,flags);
      }
      if (ChildIndex<0) return;
      _TreeSetCurIndex(ChildIndex);
   }
#endif
}

int _ul2_tree.'C-A'()
{
   _TreeCommand("c-a");
   return(0);
}
void _ul2_tree.ENTER,LBUTTON_DOUBLE_CLICK(_str eventName="")
{
   _str event=last_event();
   int orig_wid=p_window_id;
   int index=_TreeCurIndex();
   if (index<0) {
      return;
   }

   int x=0, y=0;
   if (p_EditInPlace && index > 0) {
      if (last_event()==ENTER) {
         x=0;
      }else{
         mou_get_xy(x,y);
         _map_xy(0,p_window_id,x,y);
      }
      x=_dx2lx(SM_TWIP,x);
      int firstx=0;
      int HSP=0;
      _TreeGetCurCoord(index,firstx,y,HSP);
      int numbuttons=_TreeGetNumColButtons();
      if (!numbuttons) {
         _TreeEditNode(index,0);
         return;
      }
      
      col := getTreeColFromMouse();
      boolean found=false;
      if ( col>-1 ) {
         found = false;
         if (numbuttons) {
            int width=0;
            int flags=_TreeGetNodeEditStyle(index,col);
            if ( flags<0 ) {
               flags = _TreeGetColEditStyle(col);
            }
            if ( isEditableTreeNode(flags) ) {
               found = true;
            }
         }
         if (found) {
            status := _TreeEditNode(index,col);
            if (!status) {
               return;
            }
         }
      }
   }

   origLastEvent := last_event();

   if (last_event() == LBUTTON_DOUBLE_CLICK) {
      x=mou_last_x();
      y=mou_last_y();
      index=_TreeGetIndexFromPoint(x,y,'P');
      if (index>=0) {
         if (p_multi_select!=MS_NONE) {
            int state=0;
            _TreeGetInfo(index,state);
            boolean WasSelected = _TreeIsSelected(index);
            boolean CurrentIndex = (_TreeCurIndex() == index);
            _TreeDeselectAll();
            _TreeSelectLine(index);
            if (!CurrentIndex) {
               _TreeSetCurIndex(index);  
            } else if (!WasSelected) {
               p_window_id.call_event(CHANGE_SELECTED, index, p_window_id, ON_CHANGE, 'W');
            }
         } else {
            _TreeSetCurIndex(index);
         }
      } else {
         return;
      }

   }

   // Either not "edit in place" or the current column is not editable
   int wid=0;
   p_window_id=orig_wid;
   int OrigState=0;
   _TreeGetInfo(index,OrigState);

   if ( OrigState==TREE_NODE_LEAF ) {
      if ( origLastEvent== LBUTTON_DOUBLE_CLICK ) {
         wid=p_window_id;
         call_event(CHANGE_LEAF_ENTER,index,p_window_id,ON_CHANGE,'w');
         if (_iswindow_valid(wid)) {
            p_window_id=wid;
         }
      }
      return;
   }
   //Have to call the event first so the user has a chance to fill things in
   //before _TreeSetState scrolls them.
   wid=p_window_id;
   if (index==TREE_ROOT_INDEX && OrigState>0) {
      return;
   }
   /*
     For the explorer tree, we need to know if the expand or collapse event
     is due to ENTER or DOUBLE-CLICK. Other calls currently don't specify
     the event parameter which makes this inconsistent but this is good
     enough for now.
   */
   typeless new_index=call_event(OrigState?CHANGE_COLLAPSED:CHANGE_EXPANDED,index,event,p_window_id,ON_CHANGE,'w');
   p_window_id=wid;
   if (new_index!='' && new_index!=-1) {
      _TreeSetInfo(new_index,(int)!OrigState);
   } else {
      _TreeSetInfo(index,(int)!OrigState);
   }
}

int _ul2_tree.'C-C'()
{
   return _TreeCopyContents(_TreeCurIndex(), false);
}

void _ul2_tree.'A-UP'()
{
   int index=_TreeCurIndex();
   if (index<0) {
      return;
   }
   index=_TreeGetPrevSiblingIndex(_TreeCurIndex());
   if (index>=0) {
      if (p_multi_select) {
         _TreeDeselectAll();
      }
      _TreeSetCurIndex(index);
      if (p_multi_select) {
         _TreeSelectLine(index);
      }
   }
}

void _ul2_tree.'A-DOWN'()
{
   int index=_TreeCurIndex();
   if (index<0) {
      return;
   }
   index=_TreeGetNextSiblingIndex(index);
   if (index>=0) {
      if (p_multi_select) {
         _TreeDeselectAll();
      }
      _TreeSetCurIndex(index);
      if (p_multi_select) {
         _TreeSelectLine(index);
      }
   }
}

static boolean isEditableTreeNode(int flags)
{
   return ( flags!=0 );
}

int getTreeColFromMouse()
{
   int x=0, y=0;
   if (last_event()==ENTER) {
      x=0;
   }else{
      mou_get_xy(x,y);
      _map_xy(0,p_window_id,x,y);
   }
   x=_dx2lx(SM_TWIP,x);

   int numbuttons=_TreeGetNumColButtons();
   int index=_TreeCurIndex();
   _TreeGetCurCoord(index,auto firstx,y,auto HSP);
   x += HSP;
   boolean found=false;
   int lastx=0;
   int i;
   int col=-1;
   for (i=0;i<numbuttons;++i) {
      if (lastx+_TreeColWidth(i)>x) {
         found=true;
         col=i;
         break;
      }
      lastx+=_TreeColWidth(i);
   }
   return col;
}


static int TreeFindSelected2(int index)
{
   int state=0, bm1=0, bm2=0, flags=0;
   for (;;) {
      if (_TreeIsSelected(index)) {
         return(index);
      }
      index=_TreeGetNextIndex(index);
      if (index<0) break;
   }
   return(-1);
}

/**
 * Deprecated use _TreeGetNextSelectedIndex
 */
int _TreeFindSelected(boolean ff)
{
   say('_TreeFindSelected is deprecated, use _TreeGetNextSelectedIndex');
   return -1;
}

void _TreeSafeDelete(int index,_str option="")
{
   DeleteChildWindows(p_window_id);
   _TreeDelete(index,option);
}

#if 0
static void changeSelectedEvent(int newIndex)
{
   if (newIndex<0) {
      return;
   }
   DeleteChildWindows(p_window_id);
   int cols[];
   if ( LineHasComboBox(newIndex,cols) ) {

      // Delete any child combo boxes

      int len=cols._length();
      int childWindowIDs[];
      int origwid=p_window_id;
      int i;
      int lastChildWID=0;

      // Create all necessary combo boxes
      // Save all the window IDs so we can delete them later
      // 
      // Save the last one separately so we can select the 
      // text in the last one
      for (i=0;i<len;++i) {
         int numbuttons=_TreeGetNumColButtons();
         int newWid=0;
         int status=EditTreeNode(newIndex,numbuttons,cols[i],"",newWid);
         if ( !status ) {
            lastChildWID=childWindowIDs[childWindowIDs._length()]=newWid;
         }
         p_window_id=origwid;
      }

      if ( lastChildWID && _iswindow_valid(lastChildWID) ) {
         // Select text in the last combo box we created
         //lastChildWID._set_sel(1,length(lastChildWID.p_text)+1);
      }
   }
}

void _ul2_tree.on_change2(int reason,int NewIndex)
{
   switch (reason) {
   case CHANGE_FLAGS:
      {
         changeSelectedEvent(_TreeCurIndex());
         break;
      }
   case CHANGE_BUTTON_SIZE:
      {
         DeleteChildWindows(p_window_id);
         break;
      }
   case CHANGE_BUTTON_SIZE_RELEASE:
      {
         changeSelectedEvent(_TreeCurIndex());
         break;
      }
   case CHANGE_SCROLL:
      {
         DeleteChildWindows(p_window_id);
         break;
      }
   case CHANGE_SELECTED:
      {
         int lastIndex=_GetDialogInfoHt("lastindex",p_window_id,true);
   
         if ( /*lastIndex!=null &&*/ lastIndex!=NewIndex ) {
            changeSelectedEvent(NewIndex);
         }
         _SetDialogInfoHt("lastindex",NewIndex,p_window_id,true);
      }
      break;
   }
   return;
}
#endif

_ul2_tree.c_up()
{
   int orig_scroll=_TreeScroll();
   if (orig_scroll > 0) {
      DeleteChildWindows(p_window_id);
      _TreeScroll(orig_scroll-1);
   }
}
_ul2_tree.c_down()
{
   int orig_scroll=_TreeScroll();
   DeleteChildWindows(p_window_id);
   _TreeScroll(orig_scroll+1);
}

void _ul2_tree.rbutton_down()
{
   int x=mou_last_x();
   int y=mou_last_y();
   int index=_TreeGetIndexFromPoint(x,y,'P');
   if (index>=0) {
      _TreeGetSelectionIndices(auto indexList);
      int i = 0;
      boolean cur_selected = false;
      for (i = 0; i < indexList._length(); i++) {
         if (index == indexList[i]) {
            cur_selected = true;
            break;
         }
      }
      _TreeSetCurIndex(index);
      if (cur_selected) {
         _TreeSelectIndices(indexList);
      }
   }
}

void _ul2_tree."c-lbutton-down"()
{
   int x=mou_last_x();
   int y=mou_last_y();
   int index=_TreeGetIndexFromPoint(x,y,'P');
   if (index>=0) {
      if (p_multi_select!=MS_NONE) {
         int state=0, bm1=0, bm2=0, flags=0;
//         _TreeGetInfo(index,state,bm1,bm2,flags);
         if (_TreeIsSelected(index)) {
            boolean WasSelected=true;
            //_TreeSetInfo(index,state,bm1,bm2,flags&~TREENODE_SELECTED);
            _TreeDeselectLine(index);
            if (WasSelected) {
               call_event(CHANGE_SELECTED,index,p_window_id,ON_CHANGE,'W');
            }
         }else{
            boolean WasSelected=false;
            //_TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_SELECTED);
            _TreeSelectLine(index);
            if (!WasSelected) {
               call_event(CHANGE_SELECTED,index,p_window_id,ON_CHANGE,'W');
            }
         }
      } else {
         _TreeSetCurIndex(index);
      }
      //call_event(index,p_window_id,ON_CHANGE,'W');
      //Don't need this because _TreeSetCurIndex calls event
   }
}

static int MyTreeGetPrevIndex(int index) {return(_TreeGetPrevIndex(index));}
static int MyTreeGetNextIndex(int index) {return(_TreeGetNextIndex(index));}


static void TreeShiftSelect2(int NumSelected,int OrigLN,int NewLN,
                             int OrigIndex,typeless pfn)
{
   /*
      If one or less nodes are selected, we can pretty much just go ahead
      and select from the original position to the new position.  The
      only glitch is the state of the original line.  If it is not selected,
      we select it.  If it is selected, we leave it alone
   */
   int index=0;
   int extra=0;
   //Going up...
   if (NumSelected==1) {
      //Start one line up
      index=(*pfn)(OrigIndex);
   }else{
      index=OrigIndex;
      extra=1;
   }
   int i,diff=OrigLN-NewLN;
   if (diff<0) diff=-diff;
   for (i=0;i<diff+extra;++i) {
      //_TreeGetInfo(index,state,bm1,bm2,flags);
      //_TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_SELECTED);
      _TreeSelectLine(index);
      index=(*pfn)(index);
      if (index<0) break;//Can't happen
   }
}

void _ul2_tree.left()
{
   int index=_TreeCurIndex();
   if (index<0) return;
   int state=0;
   _TreeGetInfo(index,state);
   if (state==TREE_NODE_EXPANDED) {
      int wid=p_window_id;
      call_event(CHANGE_COLLAPSED,index,p_window_id,ON_CHANGE,'w');
      p_window_id=wid;
      _TreeSetInfo(index,TREE_NODE_COLLAPSED);
   }else{
      int ParentIndex=_TreeGetParentIndex(index);
      if (ParentIndex>=0 &&
          (p_ShowRoot || ParentIndex!=TREE_ROOT_INDEX)) {
         _TreeSetCurIndex(ParentIndex);
      }
   }
}

void _ul2_tree.'Pad-Minus'()
{
   int index=_TreeCurIndex();
   int state=0;
   _TreeGetInfo(index,state);
   if (state==TREE_NODE_LEAF) {
      return;
   }
   int wid=p_window_id;
   call_event(CHANGE_COLLAPSED,index,p_window_id,ON_CHANGE,'w');
   p_window_id=wid;
   _TreeSetInfo(index,TREE_NODE_COLLAPSED);
}

void _ul2_tree.'Pad-Plus'()
{
   int index=_TreeCurIndex();
   int state=0;
   _TreeGetInfo(index,state);
   if (state==TREE_NODE_LEAF) {
      return;
   }
   int wid=p_window_id;
   call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');
   p_window_id=wid;
   _TreeSetInfo(index,TREE_NODE_EXPANDED);
}

int TreeAddItemMacro(/*int TreeWindowID,*/
                     int RelativeIndex,
                     _str Caption,
                     int Flags,
                     int NonCurrentBMIndex,
                     int CurrentBMIndex,
                     int State)
{
   int index=/*TreeWindowID.*/_TreeAddItem(RelativeIndex,
                                       Caption,
                                       Flags,
                                       NonCurrentBMIndex,
                                       CurrentBMIndex,
                                       State);
   return(index);
}

void TreeSetUserInfoMacro(int Index,
                          typeless info)
{
   _TreeSetUserInfo(Index,info);
   //say('p_window_id='p_window_id' p_object='p_object);
}

void TreeDisablePopup(int &Delay)
{
   Delay=p_delay;
   p_delay=-1;
   _bbhelp('C');
}

void TreeEnablePopup(int Delay)
{
   if(!_isEditorCtl(false)) {
      p_delay=Delay;
   }
}

void _ul2_tree.' '()
{
   _str lastevent=last_event();
   _str EventName=event2name(lastevent);
   call_event(EventName,defeventtab _ul2_tree,ENTER,'E');
}

static _str _tree_search_string = '';  // incremental search string
static typeless _tree_search_time = 0; // time since last key

// incremental searching
void _ul2_tree.\33-\255()
{
   if (p_EditInPlace) {
      _str lastevent=last_event();
      _str EventName=event2name(lastevent);
      //say('eventname='eventname);
      call_event(EventName,p_window_id,ENTER,'W');
   } else {
      // get current index and parent, done if root
      int currIndex = _TreeCurIndex();
      if (currIndex <= 0) {
         return;
      }
      int parentIndex = _TreeGetParentIndex(currIndex);

      // get last key event, skip space
      _str key=last_event();
   #if 0
      if (key:==' ') {
         call_event(defeventtab _ul2_tree,' ','E');
         return;
      }
   #endif

      // track key presses
      typeless curr_time = _time('B');
      typeless time_diff = (curr_time - _tree_search_time);
      _tree_search_time = curr_time;
      if ((time_diff < 0) || (time_diff > 1000)) { // reset search string if time_diff is out of range
         _tree_search_string = '';
      }
      if (_tree_search_string != key) { 
         // don't append if repeating first letter
         strappend(_tree_search_string, key);
      }
      key = _tree_search_string;

      _str cap = _TreeGetCaption(currIndex);
      if ((length(key) > 1) && (pos(key, cap, 1, 'I') == 1)) {
         // current caption already matches
         return; 
      }

      // search for item with this prefix
      int newIndex = _TreeSearch(currIndex, key, 'PIS');

      // didn't find it, start from top
      if (newIndex <= 0) {
         newIndex=_TreeSearch(parentIndex, key, 'PI');
         if (newIndex < 0) {
            return;
         }
      }

      if (newIndex>=0) {
         // select the item
         _TreeSetCurIndex(newIndex);
         _TreeSelectLine(newIndex, true);
      }
   }
}

/* This expects the active window to be a tree view.
 * Saves the scroll position and the current item in the tree.
 * Use _TreeRestorePos() to restore current item and scroll position.
 */
void _TreeSavePos(typeless &p)
{
   p=_TreeCurLineNumber()" "_TreeScroll();
}

/* This expects the active window to be a tree view.
 * Restores the scroll position and the current item in the tree.
 * Use _TreeSavePos() to save current item and scroll position.
 */
void _TreeRestorePos(typeless p)
{
   typeless linenumber="", scroll="";
   parse p with linenumber scroll;
   if( !isinteger(linenumber) || linenumber<0 ) {
      linenumber= -1;
   }
   if( !isinteger(scroll) || scroll<0 ) {
      scroll= -1;
   }
   _TreeCurLineNumber(linenumber);
   _TreeScroll(scroll);
}

/**
 * Retrieves the text for a particular column of a particular tree item.
 * 
 * @param index         tree item
 * @param col           column in tree (0 - based)
 *    
 * @return              section of tree item's caption that is in that column 
 *  
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
_str _TreeGetTextForCol(int index,int col)
{
   _str cap=_TreeGetCaption(index);
   _str allcaps[];
   split(cap,"\t",allcaps);
   return(allcaps[col]);
}

void _TreeSetTextForCol(int index,int col,_str NewText)
{
   _str cap=_TreeGetCaption(index);
   _str begcap='',endcap='';
   boolean addedSpace=false;
   int i;
   for (i=0;i<=col;++i) {
      _str cur="";
      parse cap with cur "\t" cap;
      if (i<col|| i>col) {
         if (begcap:=='') {
            begcap=cur"\t";
         }else{
            begcap=begcap:+cur"\t";
         }
      }else if (i==col) {
         if (begcap:=='') {
            begcap=NewText"\t";
         }else{
            begcap=begcap:+NewText"\t";
         }
      }
   }
   begcap=substr(begcap,1,length(begcap)-1);
   if (cap!='') {
      begcap=begcap"\t"cap;
   }
   _TreeSetCaption(index,begcap);
}

static int gTextBoxWid=-1;
static int gInLostFocusEvent=0;

definit()
{
   gTextBoxWid=-1;
   gInLostFocusEvent=0;
}

#if 0
static void EditTreeNode2(int index,int x,int y,int width,int height,
                          int numbuttons=0,int col=-1,_str EventName='',
                          int flags=0,int &tbwid=0)
{
   if (gTextBoxWid>=0) {
      if (!_iswindow_valid(gTextBoxWid)) {
         gTextBoxWid=-1;
      }else if (gTextBoxWid.p_object!=OI_TEXT_BOX) {
         gTextBoxWid=-1;
      }
      if (gTextBoxWid!=-1) {
         return;
      }
   }
   int treewid=p_window_id;
   _str cur="";
   _str cap=treewid._TreeGetCaption(index);
   if (numbuttons) {
      int i;
      for (i=0;i<=col;++i) {
         parse cap with cur "\t" cap;
      }
   }else{
      cur=cap;
   }
   //treewid.p_clip_controls=1;
   /*_str TextCopy=cur;
   status=call_event(CHANGE_EDIT_QUERY,index,col,TextCopy,p_window_id,ON_CHANGE,'W');
   if (status==-1) {
      return;
   }*/
   typeless status="";
   if ( flags!=0 || treewid.p_EditInPlace) {
      status=call_event(CHANGE_EDIT_OPEN,index,col,cur,p_window_id,ON_CHANGE,'W');
      if (status==-1) {
         return;
      }
   }
   //3:40:48 PM 8/21/2001
   //Might want to use a different constant, but just trying this out
   if (status==DELETED_ELEMENT_RC) {
      //origwid._delete_window(COMMAND_CANCELLED_RC);
      return;
   }
   int object_index=OI_TEXT_BOX;
   if ( flags&TREE_BUTTON_EDITABLE ) {
      object_index=OI_TEXT_BOX;
   }
   if ( flags&TREE_BUTTON_COMBO || _TreeGetComboDataNodeCol(index,col) ) {
      object_index=OI_COMBO_BOX;
   }
   // Want to be sure the same window id is active after _create_window
   int orig_wid=p_window_id;
   tbwid=_create_window(object_index,p_window_id,'',x,y,width,height,CW_CHILD);
   p_window_id=orig_wid;
   tbwid._set_focus();
   gTextBoxWid=tbwid;
   if (EventName:=='') {
      tbwid.p_text=cur;
      if ( object_index==OI_TEXT_BOX ) {
         tbwid._set_sel(1,length(tbwid.p_text)+1);
      }
   }else{
      tbwid.p_text=EventName;
      if ( object_index==OI_TEXT_BOX ) {
         tbwid._set_sel(length(tbwid.p_text)+1);
      }
   }
   tbwid.p_auto_size=0;
   tbwid.p_height=height;
   tbwid.p_font_name=treewid.p_font_name;
   tbwid.p_font_size=treewid.p_font_size;
   if (object_index==OI_TEXT_BOX && tbwid.p_height>=(tbwid._text_height()*2)) {
      tbwid.p_word_wrap=1;
   }
   _SetDialogInfoHt("columndata",treewid' 'index' 'col,tbwid,true);
   AddChildWindowToList(treewid,tbwid);
   //tbwid.p_border_style=BDS_NONE;
   _str eventtab_name="";

   // These are in this order w/o an else deliberately, it could be both
   if ( flags&TREE_BUTTON_EDITABLE || treewid.p_EditInPlace ) {
      eventtab_name="_ul2_TreeTextBox";
   }
   if ( flags&TREE_BUTTON_COMBO || treewid._TreeGetComboDataNodeCol(index,col) ) {
      eventtab_name="_ul2_TreeComboBox";
      _str combodata[]=null;
      treewid._TreeGetComboDataNodeCol(index,col,combodata,auto styleFlags);
      if ( combodata==null ) {
         treewid._TreeGetComboDataColumn(col,combodata);
      }
      if ( combodata!=null ) {
         int len=combodata._length();
         int i;
         int wid=p_window_id;
         p_window_id=tbwid.p_cb_list_box;
         for (i=0;i<len;++i) {
            _lbadd_item(combodata[i]);
         }
         // Be sure the item in the textbox selected
         status = _lbsearch(p_parent.p_text);
         if ( !status ) _lbselect_line();
         p_window_id=wid;
         if ( styleFlags>-1 ) flags=styleFlags;
         if ( flags&TREE_BUTTON_EDITABLE ) {
            tbwid.p_style=PSCBO_EDIT;
         }else{
            tbwid.p_style=PSCBO_NOEDIT;
         }
         treewid._set_focus();
      }
   }
   //index=find_index('_ul2_TreeTextBox',EVENTTAB_TYPE);
   index=find_index(eventtab_name,EVENTTAB_TYPE);
   if (index) {
      tbwid.p_eventtab=index;
   }
   typeless pfnCreateFunction=_TreeGetTextboxCreateFunction(col);
   if ( pfnCreateFunction==null ) {
      pfnCreateFunction=_TreeGetTextboxCreateFunction();
   }
   if ( pfnCreateFunction._varformat()==VF_FUNPTR ) {
      p_window_id=tbwid;
      (*pfnCreateFunction)();
      p_window_id=orig_wid;
   }
   // 6:20:15 PM 8/22/2001
   // Wanted to use this to be able to let the user put a '...' image control
   // after the textbox or something, but it would not work
   //status=treewid.call_event(CHANGE_EDIT_OPEN_COMPLETE,index,col,cur,treewid,ON_CHANGE,'W');
}
#endif

static void AddChildWindowToList(int ParentWID,int ChildWID)
{
   int childwindowlist[];
   childwindowlist=_GetDialogInfoHt("childwindowlist",ParentWID,true);
   childwindowlist[childwindowlist._length()]=ChildWID;
   _SetDialogInfoHt("childwindowlist",childwindowlist,ParentWID,true);
}

static void GetChildWindowToList(int ParentWID,int ChildWID,int (&childwindowlist)[])
{
   childwindowlist=_GetDialogInfoHt("childwindowlist",ParentWID,true);
}

static void DeleteChildWindows(int ParentWID)
{
   return ;
   int childwindowlist[];
   childwindowlist=_GetDialogInfoHt("childwindowlist",ParentWID,true);
   int i,len=childwindowlist._length();
   for (i=0;i<len;++i) {
      if ( _iswindow_valid(childwindowlist[i]) ) {
         childwindowlist[i]._delete_window();
      }
   }
   ClearChildWindowToList(ParentWID);
}

static void ClearChildWindowToList(int ParentWID)
{
   _SetDialogInfoHt("childwindowlist",null,ParentWID,true);
}

void _StopEditInPlace()
{
   if (gTextBoxWid>0) {
      gTextBoxWid.call_event(gTextBoxWid,ESC);
   }
}

void _SetEditInPlaceCompletion(_str completion)
{
   if (gTextBoxWid>0) {
      gTextBoxWid.p_completion=completion;
   }
}

#if 0
int _TreeEditNode(int index,int col=-1)
{
   int numbuttons=_TreeGetNumColButtons();
   return(EditTreeNode(index,numbuttons,col));
}

static int EditTreeNode(int index,int numbuttons=0,int col=-1,_str EventName='',int &newwid=0)
{
   _TreeGetInfo(index,auto nodeState,auto bm1,auto bm2,auto nodeFlags);
   if ( nodeFlags&TREENODE_DISABLED ) {
      DeleteChildWindows(p_window_id);
      return -1;
   }
   int width=0, flags=0, state=0;
   _str caption="";
   if (col>=0 && _TreeGetNumColButtons()>0) {
      _TreeGetColButtonInfo(col,width,flags,state,caption);
      if ( !isEditableTreeNode(flags) ) {
         if ( !_TreeGetComboDataNodeCol(index,col) ) return(-1);
      }
   }
   int x=0, y=0, HSP=0, height=0;
   _TreeGetCurCoord(index,x,y,HSP,height);
   if (y<0) {
      _TreeScroll(_TreeScroll()+1);
      _TreeGetCurCoord(index,x,y,HSP,height);
   }
   _str TextCopy=_TreeGetCaption(index);
   typeless status=call_event(CHANGE_EDIT_QUERY,index,col,TextCopy,p_window_id,ON_CHANGE,'W');
   if (status==-1) {
      return(-1);
   }
   //3:40:48 PM 8/21/2001
   //Might want to use a different constant, but just trying this out
   if (status==DELETED_ELEMENT_RC) {
      //origwid._delete_window(COMMAND_CANCELLED_RC);
      return(status);
   }
   if (numbuttons) {
      if (col==0) {
         width=_TreeColWidth(0)-x;
      }else{
         int lastx=0;
         int i;
         for (i=0;i<col;++i) {
            lastx+=_TreeColWidth(i);
         }
         x=lastx;
         width=_TreeColWidth(i);
         if (i==numbuttons-1) {
            int clientwidth=_dx2lx(SM_TWIP,p_client_width);
            width=clientwidth-x+HSP;
         }
      }
   }else{
      width=_dx2lx(SM_TWIP,p_client_width)-x;
   }
   x-=HSP;
   x=max(x,0);

   EditTreeNode2(index,x,y-(2*_twips_per_pixel_y()),width,max(height,285),numbuttons,col,EventName,flags,newwid);
   return(0);
}
#endif

_ul2_tree.tab()
{
   /*if (p_EditInPlace) {
      index=_TreeCurIndex();
      if (index >= 0) {
         EditTreeNode(index,_TreeGetNumColButtons(),0);
      }
   }else{
      call_event(p_active_form,TAB);
   }*/
   call_event(p_active_form,TAB);
}

/*void _ul2_tree.lbutton_double_click()
{
   if (p_EditInPlace) {
      mou_get_xy(x,y);
      _map_xy(0,p_window_id,x,y);
      x=_dx2lx(SM_TWIP,x);
      int index=_TreeCurIndex();
      _TreeGetCurCoord(index,firstx,y,HSP);
      int numbuttons=_TreeGetNumColButtons();
      if (!numbuttons) {
         EditTreeNode(index);
         return;
      }

      int col=0;
      int lastx=0;
      x+=HSP;
      numbuttons=_TreeGetNumColButtons();
      if (x<_TreeColWidth(0)) {
         col=0;
      }else{
         boolean found=false;
         for (i=0;i<numbuttons-1;++i) {
            if (lastx+_TreeColWidth(i)>x) {
               found=true;
               break;
            }
            lastx+=_TreeColWidth(i);
         }
         col=i;
      }
      if (numbuttons) {
         _TreeGetColButtonInfo(col,width,flags);
         if (! isEditableTreeNode(flags) ) {
            return;
         }
      }
      EditTreeNode(index,numbuttons,col);
   }
}*/

// 6:20:15 PM 8/22/2001
// Wanted to use this to be able to let the user put a '...' image control
// after the textbox or something, but it would not work
/*static int gRegisteredItems:[][];
void _TreeEditRegisterWindow(int wid)
{
   gRegisteredItems:[p_window_id][gRegisteredItems:[wid]._length()]=wid;
}

static boolean _TreeEditWindowIsRegistered(int wid)
{
   int temparray[]=gRegisteredItems:[wid];
   for (i=0;i<temparray._length();++i) {
      if (temparray[i]==wid ) {
         return(true);
      }
   }
   return(false);
}*/

defeventtab _ul2_TreeTextBox _inherit _ul2_textbox;

// 6:20:15 PM 8/22/2001
// Wanted to use this to be able to let the user put a '...' image control
// after the textbox or something, but it would not work
/*_ul2_TreeTextBox.on_create()
{
   gRegisteredItems:[p_window_id]=null;
}

_ul2_TreeTextBox.on_destroy()
{
   int temparray[]=gRegisteredItems:[p_window_id];
   for (i=0;i<temparray._length();++i) {
      if (_iswindow_valid(temparray[i])) {
         temparray[i]._delete_window();
      }
   }
   gRegisteredItems:[p_window_id]=null;
}*/

void _ul2_TreeTextBox.up()
{
   _TextboxUpDown('U');
}

void _ul2_TreeTextBox.down()
{
   _TextboxUpDown('D');
}

void _ul2_TreeTextBox.esc()
{
   gTextBoxWid=-1;
   _delete_window();
}

#if 0
static void TreeTextBoxTab(int direction=1)
{
   typeless TreeWID="";
   typeless CaptionIndex="";
   typeless Column="";
   int i=0;
   int width=0, flags=0, state=0;
   _str caption="";
   //Move edit box to next "cell".  If edited, and nowhere to go, make un-edited.
   _str columndata=_GetDialogInfoHt("columndata",p_window_id,true);
   if (columndata!=null) {
      parse columndata with TreeWID CaptionIndex Column .;
      if (!TreeWID._TreeGetNumColButtons()) {
         call_event(p_window_id,ENTER);//Close the current textbox
         if (direction>0) {
            CaptionIndex=TreeWID._TreeGetNextIndex(CaptionIndex);
         }else{
            CaptionIndex=TreeWID._TreeGetPrevIndex(CaptionIndex);
         }
         if (CaptionIndex>-1) {
            TreeWID._TreeSetCurIndex(CaptionIndex);
            TreeWID.EditTreeNode(CaptionIndex);
         }
      }else{
         int NextIndex=CaptionIndex,NextCol=Column,
             NumButtons=TreeWID._TreeGetNumColButtons();

         if (direction>0) {
            boolean NextLine=false;
            int NextColumn=0;
            for (i=0;i<NumButtons;++i) {
               NextColumn=i+Column+1;
               if (NextColumn>=NumButtons) {
                  NextColumn-=NumButtons;
                  NextLine=true;
               }
               TreeWID._TreeGetColButtonInfo(NextColumn,width,flags,state,caption);
               if ( isEditableTreeNode(flags) ) {
                  break;
               }
            }
            if (NextLine) {
               CaptionIndex=TreeWID._TreeGetNextIndex(CaptionIndex);
               call_event(p_window_id,ENTER);
               if (CaptionIndex==-1) {
                  return;
               }
               if (TreeWID.p_multi_select!=MS_NONE) {
                  TreeWID._TreeDeselectAll();
               }
               TreeWID._TreeSetCurIndex(CaptionIndex);
               if (TreeWID.p_multi_select!=MS_NONE) {
                  TreeWID._TreeSelectLine(CaptionIndex);
               }
               for (i=0;i<TreeWID._TreeGetNumColButtons();++i) {
                  TreeWID._TreeGetColButtonInfo(i,width,flags,state,caption);
                  if ( isEditableTreeNode(flags) ) {
                     TreeWID.EditTreeNode(CaptionIndex,NumButtons,i);
                     break;
                  }
               }
            }else{
               call_event(p_window_id,ENTER);//Close the current textbox
               if (TreeWID.p_multi_select!=MS_NONE) {
                  TreeWID._TreeDeselectAll();
               }
               TreeWID.EditTreeNode(CaptionIndex,NumButtons,NextColumn);
               if (TreeWID.p_multi_select!=MS_NONE) {
                  TreeWID._TreeSelectLine(CaptionIndex);
               }
            }
         }else{
            boolean PrevLine=false;
            int PrevColumn=0;

            for (i=0;i<NumButtons;++i) {
               PrevColumn=(Column-1)-i;
               if (PrevColumn<0) {
                  PrevColumn+=NumButtons;
                  PrevLine=true;
               }
               TreeWID._TreeGetColButtonInfo(PrevColumn,width,flags,state,caption);
               if ( isEditableTreeNode(flags) ) {
                  break;
               }
            }

            if (PrevLine) {
               Column=NumButtons-1;
               CaptionIndex=TreeWID._TreeGetPrevIndex(CaptionIndex);
               call_event(p_window_id,ENTER);
               if (CaptionIndex==-1) {
                  return;
               }
               if (TreeWID.p_multi_select!=MS_NONE) {
                  TreeWID._TreeDeselectAll();
               }
               TreeWID._TreeSetCurIndex(CaptionIndex);
               TreeWID.EditTreeNode(CaptionIndex,NumButtons,PrevColumn);
               if (TreeWID.p_multi_select!=MS_NONE) {
                  TreeWID._TreeSelectLine(CaptionIndex);
               }
            }else{
               call_event(p_window_id,ENTER);//Close the current textbox
               if (TreeWID.p_multi_select!=MS_NONE) {
                  TreeWID._TreeDeselectAll();
               }
               TreeWID.EditTreeNode(CaptionIndex,NumButtons,PrevColumn);
               if (TreeWID.p_multi_select!=MS_NONE) {
                  TreeWID._TreeSelectLine(CaptionIndex);
               }
            }
         }
      }
   }
}

void _ul2_TreeTextBox.tab()
{
   TreeTextBoxTab();
}

void _ul2_TreeTextBox.s_tab()
{
   TreeTextBoxTab(-1);
}

void _ul2_TreeTextBox.enter,on_lost_focus)
{
   treeTextBoxLostFocus();
}
#endif

/**
 * Used to a list style treeview(treeview control
 * with column buttons turned on).  Easier to use
 * because index defaults to TREE_ROOT_INDEX, and
 * TREE_ADD_AS_CHILD is always or'd into the flags.
 *
 * @param ItemText Text for this line.  Use a tab character to start a new column.
 * @param Flags    Flags to add this item.  TREE_ADD_AS_CHILD will always be or'd in.
 * @param Index    Index to add item under.  Defaults to TREE_ROOT_NODE.
 * @param ShowChildren
 *                 This is the same as the ShowChildren state on _TreeAddItem.  Set to 1 or 0
 *                 if you wish to have children show.  It defaults to TREE_NODE_LEAF because
 *                 you don't normally want children in this style of tree.
 * @param userInfo  Allows you to specify per-node user data.
 *                  See {@link _TreeSetUserInfo}.
 *
 * @return Returns the index of the new tree item.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
int _TreeAddListItem(_str ItemText,int Flags=0,int Index=TREE_ROOT_INDEX,int ShowChildren=TREE_NODE_LEAF,typeless userInfo=null)
{
   Flags|=TREE_ADD_AS_CHILD;
   return(_TreeAddItem(Index,ItemText,Flags,-1,-1,ShowChildren,0,userInfo));
}

/**
 * Save the column widths for the current tree control.
 *
 * @see _TreeRetrieveColButtonWidths()
 * @see _TreeAppendColButtonInfo()
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeAppendColButtonWidths(boolean dockingSameAsFloating=false,_str controlName="")
{
   _str widths='';
   int i,n=_TreeGetNumColButtons();
   for (i=0; i<n; ++i) {
      typeless bw=0, bf=0, bs=0, caption="";
      _TreeGetColButtonInfo(i,bw,bf,bs,caption);
      widths=widths' 'bw;
   }
   if (n > 0) {
      widths=substr(widths,2);
      if ( controlName=="" ) {
         controlName = p_name;
      }
      if (p_DockingArea && !dockingSameAsFloating) { //The toolwindow is not docked.
         _append_retrieve(0, widths, p_active_form.p_name'.'controlName'.button_widths');
      } else if (_tbIsAutoWid(p_active_form)) { //The toolwindow is docked and not pinned.
         _append_retrieve(0, widths, p_active_form.p_name'.'controlName'.button_widths_unpinned');
      } else {                                  //The toolwindow is docked and pinned.
         _append_retrieve(0, widths, p_active_form.p_name'.'controlName'.button_widths_pinned');
         //_append_retrieve(0, widths, p_active_form.p_name'.'controlName'.button_widths2');
      }
   }
}

/**
 * Restore the column widths for the current tree control.
 *
 * @see _TreeAppendColButtonWidths()
 * @see _TreeRetrieveColButtonInfo()
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeRetrieveColButtonWidths(boolean dockingSameAsFloating=false, _str controlName="")
{
   _str widths;
   if ( controlName=="" ) {
      controlName = p_name;
   }
   if (p_DockingArea && !dockingSameAsFloating) { //The toolwindow is not docked.
      widths=_retrieve_value(p_active_form.p_name'.'controlName'.button_widths');
   } else {                                  //The toolwindow is docked ...
      if (_tbIsAutoWid(p_active_form)) {     // ... and unpinned.
         widths=_retrieve_value(p_active_form.p_name'.'controlName'.button_widths_unpinned');
      } else {                               // ... and pinned.
         widths=_retrieve_value(p_active_form.p_name'.'controlName'.button_widths_pinned');
      }
      if (widths == '') {                    // ... and was saved pre-13.0.1.0.
         widths=_retrieve_value(p_active_form.p_name'.'controlName'.button_widths2');
      }
   }
   int bw=0, bf=0, bs=0;
    _str caption="";
   typeless w="";
   int i,n=_TreeGetNumColButtons();
   for (i=0; i<n; ++i) {
      if (widths=='') {
         break;
      }
      parse widths with w widths;
      if (isinteger(w)) {
         _TreeGetColButtonInfo(i,bw,bf,bs,caption);
         _TreeSetColButtonInfo(i,w, bf,bs,caption);
         p_scroll_bars = SB_BOTH;
      }
   }
}

/**
 * Save the column number and direction for sorting the current tree control.
 *
 * @see _TreeRetrieveColButtonSorting()
 * @see _TreeAppendColButtonInfo()
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeAppendColButtonSorting(boolean dockingSameAsFloating=false,_str controlName="")
{
   _TreeGetSortCol(auto sort_column=-1,auto direction=-1);
   if (sort_column < 0) return;

   if ( controlName=="" ) {
      controlName = p_name;
   }
   if (sort_column >= 0) {
      if (p_DockingArea && !dockingSameAsFloating) { //The toolwindow is not docked.
         _append_retrieve(0, sort_column' 'direction, p_active_form.p_name'.'controlName'.button_sort');
      } else if (_tbIsAutoWid(p_active_form)) { //The toolwindow is docked and not pinned.
         _append_retrieve(0, sort_column' 'direction, p_active_form.p_name'.'controlName'.button_sort_unpinned');
      } else {                                  //The toolwindow is docked and pinned.
         _append_retrieve(0, sort_column' 'direction, p_active_form.p_name'.'controlName'.button_sort_pinned');
         //_append_retrieve(0, sort_column' 'direction, p_active_form.p_name'.'controlName'.button_sort2');
      }
   }
}

/**
 * Restore the column number and direction for sorting the current tree control.
 *
 * @see _TreeAppendColButtonSorting()
 * @see _TreeRetrieveColButtonInfo()
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeRetrieveColButtonSorting(boolean dockingSameAsFloating=false,_str controlName="")
{
   _str sort_options;
   if ( controlName=="" ) {
      controlName = p_name;
   }
   if (p_DockingArea && !dockingSameAsFloating) { //The toolwindow is not docked.
      sort_options=_retrieve_value(p_active_form.p_name'.'controlName'.button_sort');
   } else {                                  //The toolwindow is docked ...
      if (_tbIsAutoWid(p_active_form)) {     // ... and unpinned.
         sort_options=_retrieve_value(p_active_form.p_name'.'controlName'.button_sort_unpinned');
      } else {                               // ... and pinned.
         sort_options=_retrieve_value(p_active_form.p_name'.'controlName'.button_sort_pinned');
      }
      if (sort_options == '') {              // ... and was saved pre-13.0.1.0
         sort_options=_retrieve_value(p_active_form.p_name'.'controlName'.button_sort2');
      }
   }

   typeless sort_column=0;
   typeless direction=0;
   parse sort_options with sort_column direction;

   if (!isuinteger(sort_column) || sort_column >= _TreeGetNumColButtons()) {
      return;
   }
   if (direction!=TREEVIEW_ASCENDINGORDER && direction!=TREEVIEW_DESCENDINGORDER) {
      return;
   }

   // get the existing sort flags
   int bw, bf, s;
   _str caption;
   _TreeGetColButtonInfo(sort_column, bw, bf, s, caption);

   // build the new sort, adding in the retrieved order
   sortOrder := direction == TREEVIEW_ASCENDINGORDER ? '' : 'D';

   if (bf & TREE_BUTTON_SORT_EXACT) {
      sortOrder :+= 'E';
   }
   if (bf & TREE_BUTTON_SORT_FILENAME) {
      sortOrder :+= 'F';
   }
   if (bf & TREE_BUTTON_SORT_NUMBERS) {
      sortOrder :+= 'N';
   }
   _TreeSortCol(sort_column, sortOrder);
   p_scroll_bars = SB_BOTH;
}

/**
 * Save the column widths and sorting options for the current tree control.
 *
 * @see _TreeRetrieveColButtonInfo()
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeAppendColButtonInfo(boolean dockingSameAsFloating=false,_str controlName="")
{
   _TreeAppendColButtonWidths(dockingSameAsFloating,controlName);
   _TreeAppendColButtonSorting(dockingSameAsFloating,controlName);
}

/**
 * Restore the column widths and sorting options for the current tree control.
 *
 * @see _TreeAppendColButtonInfo()
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeRetrieveColButtonInfo(boolean dockingSameAsFloating=false)
{
   _TreeRetrieveColButtonWidths(dockingSameAsFloating);
   _TreeRetrieveColButtonSorting(dockingSameAsFloating);
}

/**
 * Scale the column widths for the current tree control
 * when the tree is resized.
 *
 * @param orig_tree_width   original 'p_width' of tree (before resize)
 */
void _TreeScaleColButtonWidths(int orig_tree_width, boolean useWholeWidth = false)
{
   _str caption;
   int bw,bf,bs;

   // calcuate the total width of columns
   int tw=0;
   int i,n=_TreeGetNumColButtons();
   if (n==0) return;
   for (i=0; i<n; ++i) {
      _TreeGetColButtonInfo(i,bw,bf,bs,caption);
      tw+=bw;
   }

   // calculate the visable drawing area
   int vis_width=_dx2lx(SM_TWIP,p_client_width);
   // sometimes when we use the client width, there is a little bit left over
   if (useWholeWidth) {
      vis_width=p_width;
   }

   orig_tree_width=orig_tree_width-(p_width-vis_width);

   // special cases, where we shouldn't scale columns
   // basically, when the total column widths don't
   // span the entire tree.
   if (tw > vis_width && vis_width > orig_tree_width) {
      return;
   }
   if (tw < vis_width && vis_width < orig_tree_width) {
      return;
   }

   // calcualate column scaling ratio
   double ratio = 1.0;
   if (tw != 0) {
      ratio=(double)vis_width / (double)tw;
   }

   // scale all the columns
   for (i=0; i<n; ++i) {
      _TreeGetColButtonInfo(i,bw,bf,bs,caption);
      bw=(int)(bw*ratio);
      if (tw==0) bw=vis_width intdiv n;
      _TreeSetColButtonInfo(i,bw,bf,bs,caption);
   }
   p_scroll_bars = SB_BOTH;
}

/**
 * Adjust the width of the last item in the tree to span width of tree
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 *
 */
void _TreeAdjustLastColButtonWidth()
{
   int bw=0, bf=0, bs=0;
    _str caption="";
   int tw=0;
   int i,n=_TreeGetNumColButtons();
   for (i=0; i<n; ++i) {
      _TreeGetColButtonInfo(i,bw,bf,bs,caption);
      tw+=bw;
   }
   if (n>0 && (tw>p_width || tw-bw<p_width)) {
      _TreeSetColButtonInfo(n-1,p_width-(tw-bw),bf,bs,caption);
      p_scroll_bars = SB_BOTH;
   }
}

/**
 * Return the approximately the amount of space before the
 * left edge of the caption in a tree control.
 */
int _TreeGetLeftPadding()
{
   int width=0;
   width+=p_after_pic_indent_x;
   width+=p_LevelIndent;
   if (p_ExpandPicture > 0 || p_CollapsePicture > 0 || p_LeafPicture > 0) {
      width+=200;
   }
   int index = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index > 0) {
      int show_children=0, ncur_bm=0, cur_bm=0;
      _TreeGetInfo(index,show_children,ncur_bm,cur_bm);
      if (ncur_bm > 0 || cur_bm > 0) {
         width+=300;
      }
   }
   return width;
}

/**
 * Adjust all the column widths so that the column names all
 * fit.
 *
 * If there is extra width in the tree, it can be added to the
 * specified column.  If no column is specified, the tree
 * automatically adds that extra to the last column.
 *
 * @param extraGoesTo
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
void _TreeAdjustColumnWidthsByColumnCaptions(int extraGoesTo = -1)
{
   int width, flags, state;
   _str caption;

   // get the width for each column
   total := 0;
   int colWidths[];
   numCols := _TreeGetNumColButtons();
   for (i := 0; i < numCols; i++) {
      _TreeGetColButtonInfo(i, width, flags, state, caption);

      colWidths[i] = _text_width(caption) + _text_height();
      total += colWidths[i];
   }

   // these columns require more space than we have...
   if (total > p_width) {
      // divy it up by ratio
      ratio := (double)p_width / (double)total;
      for (i = 0; i < numCols; i++) {
         colWidths[i] = (int)(colWidths[i] * ratio);
      }
   } else {
      if (extraGoesTo >= 0 && extraGoesTo < numCols) {
         // add the extra to whatever column was specified
         colWidths[extraGoesTo] += (p_width - total);
      }
   }

   // now set widths for each column
   for (i = 0; i < numCols; i++) {
      _TreeGetColButtonInfo(i, width, flags, state, caption);
      _TreeSetColButtonInfo(i, colWidths[i], flags, state, caption);
   }
   p_scroll_bars = SB_BOTH;
}

/**
 * Adjust the widths of one or all tree columns depending on
 * the text in the tree.
 *
 * @param col        column to adjust, -1 to adjust all columns
 *
 * @return if given a specific column, return the width of that
 *         column.  If adjusting all columns, return the total
 *         width of all columns.
 *
 * @appliesTo Tree_View
 *
 * @categories Tree_View_Methods
 */
int _TreeAdjustColumnWidths(int col=-1, int *pNumWrappedRows=null)
{
   _str caption,rest;
   int index,bw,bf,bs,tw=0;

   if (col >= 0) {
      // doing just one column
      int widest=0;
      index = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index>0) {
         rest=_TreeGetCaption(index);
         for (bw=0; bw<=col; ++bw) {
            parse rest with caption "\t" rest;
         }
         bw=_text_width(caption);
         if (bw > widest) {
            widest=bw;
         }
         index = _TreeGetNextIndex(index);
      }
      if (col==0) {
         widest+=_TreeGetLeftPadding();
      }
      widest+=_text_height();
      _TreeGetColButtonInfo(col,bw,bf,bs,caption);
      bw=_text_width(caption)+_text_height()*2;
      if (bw > widest) {
         widest=bw;
      }
      _TreeSetColButtonInfo(col,widest,bf,bs,caption);
      p_scroll_bars = SB_BOTH;
      return widest;

   }

   // needed later
   int buttonwidth=0;
   int buttonflags=0;
   int state=0;

   // faster code for doing all columns
   int num_wrappable=0;
   int colwidths[]; colwidths._makeempty();
   int i,n=_TreeGetNumColButtons();
   for (i=0; i<n; ++i) {
      // Go through and get all of the button widths.  These will be the minimum
      // width for each col
      _TreeGetColButtonInfo(i,buttonwidth,buttonflags,state,caption);
      colwidths[i]=_text_width(caption);
      if (buttonflags & TREE_BUTTON_WRAP) {
         num_wrappable++;
      }
   }

   // this is for calculating (roughly) how many rows will be wrapped
   int dummy=0;
   int screen_width = _dx2lx(SM_TWIP, _screen_width());
   if (num_wrappable <= 0 || pNumWrappedRows==null) {
      pNumWrappedRows = &dummy;
   }
   *pNumWrappedRows = 0;

   // go through each item in tree, decompose caption once
   int sc=0, ncb=0;
   index = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index > 0) {
      _TreeGetInfo(index,sc,ncb);
   }
   while (index>0) {
      int rowWidth = 0;
      rest=_TreeGetCaption(index);
      for (i=0; rest!='' && i<n; ++i) {
         parse rest with caption "\t" rest;
         bw=_text_width(caption);
         rowWidth+=bw;
         if (i==0) {
            int indent=_TreeGetDepth(index);
            bw += p_LevelIndent*indent * 4 /*fudge*/;
         }
         if (bw > colwidths[i]) {
            colwidths[i]=bw;
         }
      }
      *pNumWrappedRows += (rowWidth intdiv screen_width);
      index = _TreeGetNextIndex(index);
   }

   // calculate the total width needed
   for (i=0;i<n;++i) {
      //if (i==0) {
      //   colwidths[i]+=_TreeGetLeftPadding();
      //}

      // _text_height() is to offset the width of the bitmap that may be displayed
      // to show sort order
      colwidths[i]+=_text_height();
      tw+=colwidths[i];
   }

   // is the total width more than the screen dimensions?
   if (tw > screen_width && num_wrappable > 0) {
      int excess_width = tw-screen_width;
      for (i=0; i<n; ++i) {
         _TreeGetColButtonInfo(i,buttonwidth,buttonflags,state,caption);
         if (buttonflags & TREE_BUTTON_WRAP) {
            if (colwidths[i] > screen_width intdiv n && colwidths[i] - (excess_width intdiv num_wrappable) > 0) {
               colwidths[i] -= (excess_width intdiv num_wrappable);
               tw -= (excess_width intdiv num_wrappable);
               if (colwidths[i] < screen_width intdiv n) {
                  tw += (screen_width intdiv n) - colwidths[i];
                  colwidths[i] = screen_width intdiv n;
               }
            }
         }
      }
   }
   if (!(p_scroll_bars&SB_HORIZONTAL) && tw > p_width) {
      lastColIndex := colwidths._length()-1;
      if ( lastColIndex>0 ) {

         // We need to be sure that the last column isn't too wide because this
         // causes weird scrolling issues in the new tree control.  Nothing we
         // can do here will be perfect, so just keep it simple and scale down
         // the columns to the actual tree width
         double ratio = (double)p_width / (double)tw;
         for (i = 0; i < n; i++) {
            colwidths[i] = floor(colwidths[i] * ratio);
         }
      }
   }

   // now set widths for each column
   for (i=0;i<n;++i) {
      _TreeGetColButtonInfo(i,bw,bf,bs,caption);
      _TreeSetColButtonInfo(i,colwidths[i],bf,bs,caption);
   }
   p_scroll_bars = SB_BOTH;

   // return total width of all columns
   return tw;
}

/**
 * Returns the index in the tree for the specified path.
 * If it is not there, it puts the path in one dir at a time
 * and returns the index to the last one
 *
 * @param Path       Path to put in
 * @param BasePath   The name of the path at the "root" level of the tree
 *                   (actually, show root should be off).
 * @param PathTable  Used internally, should initially be null
 * @param FolderIndex
 *                   Index for folder bitmaps
 * @param OurFilesep
 *
 * @return index folder for <B>Path</B>
 */
int _TreeGetPathIndex(_str Path,_str BasePath,int (&PathTable):[],
                      int FolderIndex=_pic_fldopen,_str OurFilesep=FILESEP,
                      int state=1)
{
   _str PathsToAdd[];int count=0;
   _str OtherPathsToAdd[];
   int Othercount=0;
   Path=strip(Path,'B','"');
   BasePath=strip(BasePath,'B','"');
   if (PathTable._indexin(_file_case(Path))) {
      return(PathTable:[_file_case(Path)]);
   }
   int Parent=TREE_ROOT_INDEX;
   for (;;) {
      if (Path=='') {
         break;
      }
      PathsToAdd[count++]=Path;
      Path=substr(Path,1,length(Path)-1);
      _str tPath=_strip_filename(Path,'N');
      if (file_eq(Path:+OurFilesep,BasePath) || file_eq(tPath,Path)) break;
      if (isunc_root(Path)) break;
      Path=tPath;
      if (PathTable._indexin(_file_case(Path))) {
         Parent=PathTable:[_file_case(Path)];
         break;
      }
   }
   PathsToAdd._sort('F');
   int i;
   for (i=0;i<PathsToAdd._length();++i) {
      Parent=_TreeAddItem(Parent,
                          PathsToAdd[i],
                          TREE_ADD_AS_CHILD/*|TREE_ADD_SORTED_FILENAME*/,
                          FolderIndex,
                          FolderIndex,
                          state);
      PathTable:[_file_case(PathsToAdd[i])]=Parent;
   }
   return(Parent);
}

/**
 * Copy the content of a tree or a selected node into clipboard.
 * 
 * @param index index of the top node.
 * @param walk_tree if true, descend the tree.
 * 
 * @return int 0 on success, and non-zero on failure.
 */
int _TreeCopyContents(int index=TREE_ROOT_INDEX, boolean walk_tree=true)
{
   typeless writebuf = 0;
   int orig_viewid = _create_temp_view(writebuf);
   activate_window(orig_viewid);
   if (walk_tree) {
      walk_and_print_tree(index, writebuf);
      writebuf.format_tree_columns();
   } else {
      _str caption = _TreeGetCaption(index);
      writebuf._insert_text(caption);
   }
   writebuf.select_all();
   writebuf.copy_to_clipboard();

   _delete_temp_view(writebuf);
   return 0;
}

/**
 * Save the contents of a tree.
 * Current object is a tree control.
 *
 * @param file_name     (optional) full path to file to save to
 */
int _TreeSaveContents(int index=TREE_ROOT_INDEX, _str file_name=null)
{
   _str fn;
   if (file_name==null) {
      // base default file name on tree caption
      file_name = _TreeGetCaption(index);
      parse file_name with file_name "\t" .;
      if (file_name == '' || (index==TREE_ROOT_INDEX && !p_ShowRoot)) {
         file_name="tree.txt";
      } else {
         file_name=file_name:+".txt";
      }
      // Prompt for file name
      typeless result=_mdi._OpenDialog(
                  '-modal',
                  'Save Tree as Text',// title
                  "",// Initial wildcards
                  "Text file(*.txt),All Files (*.*)",
                  //"Tag Files (tags.slk;*"TAG_FILE_EXT")",
                  OFN_NODATASETS |OFN_SAVEAS,
                  ".txt", // Default extension
                  /*
                     The logic here is that typically all user
                     created tag files have the name "tags.vtg".
                     This prevents the user from having a
                     tag file conflict with a project tag file
                     which has the same extension.
                  */
                  file_name /*"*"TAG_FILE_EXT */ // Initial filename
                  //_tagfiles_path()
                  );// Initial directory
      if (result=='') return 0;
      _str ext=_get_extension(result);

//      gui_save_as();
      fn = result; //mktemp();
   } else {
      fn = file_name;
   }
   int orig_wid = p_window_id;
   typeless writebuf=0;
   int orig_viewid = _create_temp_view(writebuf);
   activate_window(orig_viewid);
   p_window_id = orig_wid;
   mou_hour_glass(1);
   walk_and_print_tree(index, writebuf);
   writebuf.format_tree_columns();
   mou_hour_glass(0);
   p_window_id = writebuf;
   p_buf_name = strip(fn,'B','"');
   save();
   p_window_id = orig_viewid;
   edit(maybe_quote_filename(fn));
   _str bfiledate = _file_date(p_buf_name,'B');
   _ReloadCurFile(p_window_id,bfiledate,false,true,null,false);
   _delete_temp_view(writebuf);
   return(0);
}

static void walk_and_print_tree(int index, CTL_EDITOR writebuf, int indent=0)
{
   int show_children=0;
   int bm_index=0;
   _str myline;
   _str prefix;
   _TreeGetInfo(index,show_children,bm_index);
   if (!(index==TREE_ROOT_INDEX && !p_ShowRoot)) {
      myline = _TreeGetCaption(index);
      int origview = p_window_id;
      p_window_id = writebuf;
      int syntax_indent=p_SyntaxIndent;
      if (!syntax_indent) {
         syntax_indent=3;
      }
      myline = substr(" ", 1, indent*syntax_indent) :+
                getTextSymbolFromBitmapId(bm_index) :+ " " :+ myline;
      insert_line(myline);
      p_window_id = origview;
   }
   if (show_children == TREE_NODE_EXPANDED) {
      index = _TreeGetFirstChildIndex(index);
      while (index > 0) {
         walk_and_print_tree(index,writebuf, indent+1);
         index = _TreeGetNextSiblingIndex(index);
      }
   }
}

/**
 * recursively walks the tree and outputs it to the vsapi 
 * console window. This function should be called with no 
 * parameters specified to print the whole tree. 
 * 
 * @author shackett (6/16/2010)
 * @param index - the current tree node index
 * @param indent - the current indentation level
 */
void walk_and_say_tree(int index=TREE_ROOT_INDEX, int indent=0)
{
   int show_children=0;
   int bm_index=0;
   _str myline;
   _str prefix;
   _TreeGetInfo(index,show_children,bm_index);
   myline = index :+ ' ' :+ _TreeGetCaption(index);
   myline = substr(" ", 1, indent*3) :+ getTextSymbolFromBitmapId(bm_index) :+ " " :+ myline;
   say(myline);
   index = _TreeGetFirstChildIndex(index);
   while (index > 0) {
      walk_and_say_tree(index, indent+1);
      index = _TreeGetNextSiblingIndex(index);
   }
}

static void format_tree_columns()
{
   // Are there any tabs in this file?
   // If not, then there are not columns to format
   top();_begin_line();
   status := search("\t","@h");
   if (status < 0) {
      return;
   }

   // To preserve existing spacing, replace spaces with a special char 
   top();_begin_line();
   search(" ","@h","\1");

   // Replace the tabs with single spaces, 
   // this makes it easier for format_columns()
   top();_begin_line();
   search("\t","@h"," ");

   // Format the column data in the whole file
   select_all();
   format_columns();
   _deselect();

   // Now put the spaces back in.
   // If their data had \1 in it, that's really too bad...
   top();_begin_line();
   search("\1","@h"," ");
}

/**
 * Print the contents of a tree.
 * Current object is a tree control.
 */
int _TreePrintContents(int index=TREE_ROOT_INDEX)
{
   int orig_wid = p_window_id;
   typeless writebuf=0;
   int orig_viewid = _create_temp_view(writebuf);
   activate_window(orig_viewid);
   p_window_id = orig_wid;
   walk_and_print_tree(index, writebuf);
   writebuf.format_tree_columns();
   p_window_id = writebuf;
   _str fn = mktemp();
   _save_file(maybe_quote_filename(fn));
   edit(maybe_quote_filename(fn));
   gui_print();
   close_buffer();
   p_window_id = orig_viewid;
   _delete_temp_view(writebuf);
   delete_file(fn);
   return(0);
}


/**
 * This command was requested by HP.
 * They wanted a way to print the call tree.
 * What this command will do is dump the call
 * tree contents to a buffer and print that
 * buffer.  HP wanted this on HPUX, where we do
 * not support graphics printing.
 */
_command void tree_to_buf()
{
   int i;
   int treewid = GetProcTreeWID();

   int index = treewid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      treewid._TreePrintContents(index);
      index = treewid._TreeGetNextSiblingIndex(index);
   }
}


struct TREE_COPY_INFO {
   _str caption;
   int bm1,bm2;
   int flags;
   int state;
   typeless userinfo;
};

/**
 * Will copy all nodes under SrcIndex, and deposit under
 * DestIndex
 *
 * @param SrcIndex
 * @param DestIndexParent
 * @param SrcWID
 * @param DestWID
 * @param CopyUserInfo
 *
 * @return 0 on success.
 *  
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
int _TreeCopy(int SrcIndexParent,int DestIndexParent,
              int SrcWID=-1,int DestWID=-1,
              boolean CopyUserInfo=false,boolean CopySibs=false)
{
   TREE_COPY_INFO info;
   //GetAllInfo(SrcIndex,info,SrcWID);
   if (SrcWID<0) {
      SrcWID=p_window_id;
   }
   if (DestWID<0) {
      DestWID=p_window_id;
   }

   int src_child_index;
   if (CopySibs) {
      src_child_index=SrcIndexParent;
   }else{
      src_child_index=SrcWID._TreeGetFirstChildIndex(SrcIndexParent);
   }
   int next_dest_index=DestWID._TreeAddItem(DestIndexParent,"",TREE_ADD_AS_CHILD);
   for (;;) {
      if (src_child_index<0) break;

      int src_sub_child_index=SrcWID._TreeGetFirstChildIndex(src_child_index);
      if (src_sub_child_index>=0) {
         DestWID._TreeCopy(src_sub_child_index,next_dest_index,SrcWID,DestWID,CopyUserInfo,true);
      }

      CopyNodeInfo(src_child_index,SrcWID,next_dest_index,DestWID,CopyUserInfo);

      src_child_index=SrcWID._TreeGetNextSiblingIndex(src_child_index);
      if (src_child_index>=0) {
         next_dest_index=DestWID._TreeAddItem(next_dest_index,"");
      }
   }
   return(0);
}

/**
 * Recursively copies a node and all of its children and all of 
 * their properties to a destination node, where it is added as 
 * a child. This function differs from _TreeCopy because it 
 * copies just the node specified and all of its children, 
 * where _TreeCopy just copies the children. It also returns the 
 * index of the copied tree node. 
 * 
 * @author shackett (6/16/2010)
 * 
 * @param TreeWID - the wid of the tree control
 * @param SrcIndexParent - the tree node to copy
 * @param DestIndexParent - the node to copy to
 * 
 * @return int - the index of the copied tree node
 */
int _TreeCopy2(int TreeWID, int SrcIndexParent, int DestIndexParent)
{
   TREE_COPY_INFO info;
   //GetAllInfo(SrcIndex,info,SrcWID);
   if (TreeWID < 0) {
      TreeWID = p_window_id;
   }
   if (SrcIndexParent < 0) {
      return -1;
   }

   int src_child_index;
   int next_dest_index = TreeWID._TreeAddItem(DestIndexParent,"",TREE_ADD_AS_CHILD);
   CopyNodeInfo(SrcIndexParent, TreeWID, next_dest_index, TreeWID, true);
   _str cap = TreeWID._TreeGetCaption(SrcIndexParent);
   int childCount = TreeWID._TreeGetNumChildren(SrcIndexParent);
   int src_sub_child_index = TreeWID._TreeGetFirstChildIndex(SrcIndexParent);
   while (src_sub_child_index >= 0) {
       _TreeCopy2(TreeWID, src_sub_child_index, next_dest_index);
       src_sub_child_index = TreeWID._TreeGetNextSiblingIndex(src_sub_child_index);
   }
   return next_dest_index;
}

static void CopyNodeInfo(int SrcIndex,int SrcWID,int DestIndex,int DestWID,boolean CopyUserInfo)
{
   _str cap=SrcWID._TreeGetCaption(SrcIndex);
   DestWID._TreeSetCaption(DestIndex,cap);
   int state=0, bm1=0, bm2=0, flags=0;
   SrcWID._TreeGetInfo(SrcIndex,state,bm1,bm2,flags);
   DestWID._TreeSetInfo(DestIndex,state,bm1,bm2,flags);
   if (CopyUserInfo) {
      typeless userinfo=SrcWID._TreeGetUserInfo(SrcIndex);
      DestWID._TreeSetUserInfo(DestIndex,userinfo);
   }
}

int _TreeSaveDataXML(int xml_handle,int tree_index=TREE_ROOT_INDEX,int xml_index=-1,
                     pfnTreeSaveCallback pfnCallback=null)
{
   if (xml_index<0) {
      xml_index=_xmlcfg_add(xml_handle,TREE_ROOT_INDEX,"Tree",VSXMLCFG_NODE_ELEMENT_START_END,TREE_ADD_AS_CHILD);
   }
   TreeSaveData2xml(_TreeGetFirstChildIndex(tree_index),xml_handle,xml_index,pfnCallback);
   int status=_xmlcfg_save(xml_handle,-1,VSXMLCFG_SAVE_ALL_ON_ONE_LINE);

   return(status);
}

static void TreeSaveData2xml(int tree_index,int xml_handle,int xml_index,
                             pfnTreeSaveCallback pfnCallback=null)
{
   int state=0, bm1=0, bm2=0, node_flags=0;
   int add_flags=VSXMLCFG_ADD_AS_CHILD;
   for (;;) {
      if (tree_index<0) break;
      _str cap=_TreeGetCaption(tree_index);
      xml_index=_xmlcfg_add(xml_handle,xml_index,"TreeNode",VSXMLCFG_NODE_ELEMENT_START,add_flags);
      add_flags=0;

      _TreeGetInfo(tree_index,state,bm1,bm2,node_flags);
      _xmlcfg_add_attribute(xml_handle,xml_index,"Cap",cap);
      _xmlcfg_add_attribute(xml_handle,xml_index,"State",state);
      _xmlcfg_add_attribute(xml_handle,xml_index,"BM1",name_name(bm1));
      _xmlcfg_add_attribute(xml_handle,xml_index,"BM2",name_name(bm2));
      _xmlcfg_add_attribute(xml_handle,xml_index,"Flags",node_flags);
      if (pfnCallback) {
         (*pfnCallback)(xml_handle,xml_index,tree_index);
      }

      int cindex=_TreeGetFirstChildIndex(tree_index);
      if (cindex>-1) {
         TreeSaveData2xml(cindex,xml_handle,xml_index);
      }
      tree_index=_TreeGetNextSiblingIndex(tree_index);
   }
}

int _TreeLoadDataXML(int xml_handle,int xml_parent_index,int tree_index=TREE_ROOT_INDEX,
                     pfnTreeLoadCallback pfnCallback=null)
{
   int status=TreeLoadData2xml(tree_index,xml_handle,_xmlcfg_get_first_child(xml_handle,xml_parent_index),pfnCallback);

   return(status);
}

static int TreeLoadData2xml(int tree_index,int xml_handle,int xml_index,
                             pfnTreeLoadCallback pfnCallback=null)
{
   int add_flags=TREE_ADD_AS_CHILD;
   int BMHash:[]=null;
   for (;;) {
      if (xml_index<0) break;
      _str name=_xmlcfg_get_name(xml_handle,xml_index);
      if (name=="TreeNode") {
         _str cap=_xmlcfg_get_attribute(xml_handle,xml_index,"Cap");
         int state=_xmlcfg_get_attribute(xml_handle,xml_index,"State");
         _str bm1=_xmlcfg_get_attribute(xml_handle,xml_index,"BM1");
         _str bm2=_xmlcfg_get_attribute(xml_handle,xml_index,"BM2");
         int node_flags=_xmlcfg_get_attribute(xml_handle,xml_index,"Flags");
         if (!BMHash._indexin(bm1)) {
            BMHash:[bm1]=find_index(bm1,PICTURE_TYPE);
         }
         if (!BMHash._indexin(bm2)) {
            BMHash:[bm2]=find_index(bm2,PICTURE_TYPE);
         }

         tree_index=_TreeAddItem(tree_index,cap,add_flags,BMHash:[bm1],BMHash:[bm2],state,node_flags);
         if (pfnCallback) (*pfnCallback)(xml_handle,xml_index,tree_index);
         add_flags=0;

         int xml_cindex=_xmlcfg_find_child_with_name(xml_handle,xml_index,"TreeNode");
         if (xml_cindex>-1) {
            TreeLoadData2xml(tree_index,xml_handle,xml_cindex);
         }
      }
      xml_index=_xmlcfg_get_next_sibling(xml_handle,xml_index);
   }
   return 0;
}

/**
 * Do something recursively over each node in a tree
 * 
 * @param index Index of node to start descending from
 * @param callback A function pointer that does the stuff
 * @param extra An extra object to be passed to the callback; can be anything
 */
void _TreeDoRecursively(int index, pfnTreeDoRecursivelyCallback callback, typeless &extra, boolean firstTime=true)
{
   if (callback) {
      (*callback)(index, extra);
   }
   int cindex = _TreeGetFirstChildIndex(index);
   if (cindex > -1) {
      _TreeDoRecursively(cindex, callback, extra, false);
   }
   if (firstTime) {
      return;
   }
   for ( ; ; ) {
      int sindex = _TreeGetNextSiblingIndex(index);
      if (sindex < 0) {
         break;
      }
      if (callback) {
         (*callback)(sindex, extra);
      }
      index = sindex;
      cindex = _TreeGetFirstChildIndex(index);
      if (cindex > -1) {
         _TreeDoRecursively(cindex, callback, extra, false);
      }
   }   
}

/**
 * Get a a list of tree indices for all the tree items currently selected
 * 
 * @param indices (Output) Will hold the list of tree indices
 *
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
void _TreeGetSelectionIndices(int (&indices)[])
{
   indices._makeempty();

   int info;
   for ( ff:=1;;ff=0 ) {
      int index=_TreeGetNextSelectedIndex(ff,info);
      if ( index<0 ) break;
      indices[indices._length()] = index;
   }
}

void _TreeSelectIndices(int (&indices)[])
{
   foreach (auto curIndex in indices) {
      _TreeSelectLine(curIndex);
   }
}

/**
 * Sorts entire tree from index down
 * @PARAM index index to start sorting at, defaults to the root node
 */
void _TreeSortTree(int index=TREE_ROOT_INDEX)
{
   for ( ;; ) {
      _TreeSortCaption(index,'FP');
      int cindex=_TreeGetFirstChildIndex(index);
      if ( cindex>-1 ) {
         _TreeSortTree(cindex);
      }
      index=_TreeGetNextSiblingIndex(index);
      if ( index<0 ) break;
   }
}

#if 0 //10:49am 9/1/2011
defeventtab _ul2_TreeComboBox _inherit _ul2_combobx;

/**
 * Drops the combo box up.
 */
void _ul2_TreeComboBox.A_UP()
{
   if (p_cb_list_box.p_visible) {
      call_event(p_window_id,F4);
   } 
}

/**
 * Drops the combo box down.
 */
void _ul2_TreeComboBox.A_DOWN()
{
   if (!p_cb_list_box.p_visible) {
      call_event(p_window_id,F4);
   } 
}

/**
 * Toggles the combo box up and down.
 */
void _ul2_TreeComboBox.F4()
{
   // if the combo box is already down, then pull it up
   if (p_cb_list_box.p_visible) {
      p_cb_list_box.p_visible=0;
      call_event(DROP_UP,p_window_id,ON_DROP_DOWN,'');
   } else {
      // otherwise we want to drop it down
      if (!p_cb_picture.p_enabled || p_cb_picture.p_picture!=_pic_cbarrow) return;

      if (p_cb_list_box.p_scroll_left_edge>=0) {
         p_cb_list_box.p_scroll_left_edge= -1;
      }
      if (p_style==PSCBO_NOEDIT) {
         p_cb_text_box.p_sel_length=0;
      }
      call_event(DROP_DOWN,p_window_id,ON_DROP_DOWN,'');
      _cbi_search();
      p_cb_list_box._lbselect_line();
      p_cb_list_box.p_visible=1;
   }
}

void _ul2_TreeComboBox.on_change(int reason)
{
   if (reason == CHANGE_CLINE_NOTVIS) {         // mouse wheel used to scroll value
      _str columndata=_GetDialogInfoHt("columndata",p_window_id,true);
      _str treewid,index,col;
      parse columndata with treewid index col;
      treewid.call_event(CHANGE_EDIT_CLOSE,index,col,p_text,treewid,ON_CHANGE,'W');
   }
}

void _ul2_TreeComboBox.on_drop_down(int reason)
{
   _str columndata=_GetDialogInfoHt("columndata",p_window_id,true);
   _str treewid,index,col;
   parse columndata with treewid index col;
   if ( reason==DROP_UP ) {
      treewid.call_event(CHANGE_EDIT_CLOSE,index,col,p_text,treewid,ON_CHANGE,'W');
   }else if ( reason==DROP_DOWN ) {
      // Fix the width of the combo box list. These can be very narrow while the
      // items in them are wider and cannot be seen
      int wid=p_window_id;
      p_window_id=p_cb_list_box;

      int longest=_find_longest_line();
      list_width:=longest+ p_width-_dx2lx(p_xyscale_mode,p_client_width)+200;
      p_width = max(p_width,list_width);

      p_window_id=wid;
   }
   sc.controls.Table table=_GetDialogInfoHt("TableThis",(int)treewid,true);
   if ( table!=null ) {
      // Convert tree node index into a line number.  Teporarily set the current 
      // index to the newly added index, call _TreeCurLineNumber(), then 
      // restore the original index.
      int wid=p_window_id;
      p_window_id=(int)treewid;
      origIndex := _TreeCurIndex();
      _TreeSetCurIndex((int)index);
      rowY := _TreeCurLineNumber();
      _TreeSetCurIndex(origIndex);
      p_window_id=wid;
      table.onComboDropEvent(reason,(int)rowY,(int)col);
   }
   treewid._set_focus();
}

//void _ul2_TreeComboBox.esc()                                  
//{
//   gTextBoxWid=-1;
//   _delete_window();
//}

void _ul2_TreeComboBox.tab()
{
   TreeTextBoxTab();
}

void _ul2_TreeComboBox.s_tab()
{
   TreeTextBoxTab(-1);
}

void _ul2_TreeComboBox.enter,on_got_focus()
{
   lastClickTime := _GetDialogInfoHt("lastClickTime",p_parent,true);
   if ( lastClickTime==null ) return;
   String lastClickTimeStr;
   lastClickTimeStr.set(lastClickTime);
   String curTime;
   curTime.set(_time('b'));
   delta := curTime.toInt()-lastClickTimeStr.toInt();

   dct := _default_option(VSOPTION_DOUBLE_CLICK_TIME);

   if ( delta<=dct ) {
      call_event(p_window_id,LBUTTON_DOUBLE_CLICK);
   }
   _set_sel(0,0);
}

void _ul2_TreeComboBox.enter,on_lost_focus()
{
   // see if we changed our selection - call the appropriate events, if so
   if (p_cb_list_box.p_visible) {
      _str text=p_cb_list_box._lbget_seltext();
      if (p_style==PSCBO_EDIT) {
          p_cb_text_box._set_sel(1,length(text)+1);
      }
      p_cb_list_box.p_visible=0;
      if (p_text!=text && p_cb_list_box._lbisline_selected()) {
         p_text=text;
      }
      p_parent.refresh('w');
      call_event(DROP_UP,p_cb,ON_DROP_DOWN,'');
      if (p_cb_list_box._lbisline_selected()) {
         p_cb.call_event(DROP_UP_SELECTED,p_cb,ON_DROP_DOWN,'');
      }
   }

   _str columndata=_GetDialogInfoHt("columndata",p_window_id,true);
   if ( columndata!=null ) {
      parse columndata with auto treewid auto index auto col;
      treewid._set_focus();
   }
}

void _ul2_TreeComboBox.lbutton_down()
{
   if ( p_cb_active == p_cb_picture || p_cb_list_box.p_visible ) {
      // If the picture (drop button) is active, just drop down the list
      // otherwise, do nothing in case a double click is coming
      call_event(defeventtab _ul2_combobx,LBUTTON_DOWN,'E');
   } 
}

void _ul2_TreeComboBox.lbutton_double_click()
{
   do {
      if ( p_cb_active == p_cb_picture  ) {
         // If we got a double click on the picture (drop button), just show the
         // list even thought it was a double click
         call_event(defeventtab _ul2_combobx,LBUTTON_DOWN,'E');
         break;
      }
      if ( p_style==PSCBO_NOEDIT ) {
         // If this is a no edit combo box, select the next item in the list
         int wid=p_window_id;
         p_window_id=p_cb_list_box;
         status := _lbdown();
         if ( status ) {
            _lbtop();
         }
         p_parent.p_text = _lbget_text();
         p_window_id=wid;
         wid.call_event(CHANGE_CLINE_NOTVIS,wid,ON_CHANGE,'W');
      }
   } while ( false );
}

void _ul2_TreeComboBox.on_destroy()
{
   _str columndata=_GetDialogInfoHt("columndata",p_window_id,true);
   if ( columndata!=null ) {
      _str treewid,index,col;
      parse columndata with treewid index col;
      if ( _iswindow_valid((int)treewid) ) {
         treewid._TreeSetTextForCol((int)index,(int)col,p_text);
      }
   }
}

static void treeTextBoxLostFocus()
{
   int origwid=p_window_id;
   _str origwinName=p_name;
   typeless treewid="";

   // 6:20:15 PM 8/22/2001
   // Wanted to use this to be able to let the user put a '...' image control
   // after the textbox or something, but it would not work
   //if (_TreeEditWindowIsRegistered(_get_focus())) return;
   if (gInLostFocusEvent) return;
   ArgumentCompletionTerminate(true);
   int i;
   for (i=0;i<=_last_window_id();++i) {
      if (_iswindow_valid(i) && i.p_object==OI_FORM && i.p_modal) {
         if (i.p_parent==p_window_id) {
            // Modal dialog attatched to this control.
            // List clipboards dialog is probably up.
            return;
         }
      }
   }

   _str columndata=_GetDialogInfoHt("columndata",p_window_id,true);
   if (columndata!=null) {
      typeless captionindex="", column="";
      parse columndata with treewid captionindex column .;

      _str ModifiedText=p_text;
      gInLostFocusEvent=1;
      typeless status=treewid.call_event(CHANGE_EDIT_CLOSE,captionindex,column,ModifiedText,treewid,ON_CHANGE,'W');
      gInLostFocusEvent=0;
      if (status==-1) {
         gTextBoxWid._set_focus();
         return;
      }
      //3:40:48 PM 8/21/2001
      //Might want to use a different constant, but just trying this out
      if (status==DELETED_ELEMENT_RC) {
         // Have to force a refresh here.
         // We can take this out when vbegin_paint/vend_paint is out of
         // the treeview control.
         if (_iswindow_valid(treewid)) {
            treewid._TreeRefresh();
         }
         if ( _iswindow_valid(origwid) && origwid.p_name==origwinName ) {
            origwid._delete_window(COMMAND_CANCELLED_RC);
         }
         gTextBoxWid=-1;

#if __UNIX__
         // 1/11/08 - sg
         // commented this out because of use in options dialog property sheets - pressing OK button on form 
         // while in edit mode did not cause the button event to be called
         // 6.12.08 - sg
         // commented this back in for UNIX - user can press enter twice to enter 
         // the text box value and then close the dialog
         if(_iswindow_valid(treewid)){
            treewid._set_focus();
         }
#endif

         return;
      }

      _str cap=treewid._TreeGetCaption(captionindex);
      _str begcap='',endcap='';
      int numbuttons=treewid._TreeGetNumColButtons();
      if (numbuttons) {
         treewid._TreeSetTextForCol(captionindex,column,ModifiedText);
      }else{
         treewid._TreeSetCaption(captionindex,ModifiedText);
      }
      treewid.call_event(CHANGE_OTHER,captionindex,column,ModifiedText,treewid,ON_CHANGE,'W');
   }
   if ( _iswindow_valid(origwid) && origwid.p_name==origwinName ) {
      // 3:59:08 PM 2/27/2008 DWH
      // Have to check that this window is valid, one of the callbacks may have 
      // eliminated it somehow
      origwid._delete_window();
   }
   gTextBoxWid=-1;
   gInLostFocusEvent=0;
   if(_iswindow_valid(treewid)){
      treewid._set_focus();
   }
}

#if 0 //10:26am 6/8/2011
/**
 * 
 * @param column    0 based
 * @param dataLines Each array item is a separate line
 */
void _TreeSetComboDataCol(int column,_str (&dataLines)[],int styleFlags=-1)
{
   // Will probably take this out when the tree only "pops up" a column
   int junk;
   TreeDisablePopup(junk);

   TreeSetComboData("col",column,dataLines,styleFlags);
}

void _TreeSetComboDataNodeCol(int nodeId,int col,_str (&dataLines)[],int styleFlags=-1)
{
   _str nodeCol=nodeId:+",":+col;
   TreeSetComboData("nodecol",nodeCol,dataLines,styleFlags);
}
#endif

void _TreeSetTextboxCreateFunction(typeless textboxEventtabName,int col=-1)
{
   _SetDialogInfoHt("textboxCreateFunction:":+col,textboxEventtabName,p_window_id,true);
}

typeless _TreeGetTextboxCreateFunction(int col=-1)
{
   return(_GetDialogInfoHt("textboxCreateFunction:":+col,p_window_id,true));
}

static void TreeSetComboData(_str prefix,_str id,_str (&dataLines)[],int styleFlags)
{
   _str key=prefix:+":":+id;
   _SetDialogInfoHt("coldata:":+key,dataLines,p_window_id,true);
   _SetDialogInfoHt("styleFlags:":+key,styleFlags,p_window_id,true);
}


boolean _TreeGetComboDataColumn(int column,_str (&dataLines)[]=null,int &styleFlags=-1)
{
   TreeGetComboData("col",column,dataLines,styleFlags);
   return dataLines!=null;
}

boolean _TreeGetComboDataNodeCol(int nodeId,int col,_str (&dataLines)[]=null,int &styleFlags=-1)
{
   _str nodeCol=nodeId:+",":+col;
   TreeGetComboData("nodecol",nodeCol,dataLines,styleFlags);
   return dataLines!=null;
}

static void TreeGetComboData(_str prefix,_str id,_str (&dataLines)[],int &styleFlags)
{
   _str key=prefix:+":":+id;
   dataLines=_GetDialogInfoHt("coldata:":+key,p_window_id,true);
   styleFlags=_GetDialogInfoHt("styleFlags:":+key,p_window_id,true);
   if ( styleFlags==null ) styleFlags=-1;
}
#endif


/**
 * Gets the caption of the currently selected item in the tree
 * 
 * @return caption of currently selected item in tree 
 *  
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
_str _TreeGetCurCaption()
{
   curIndex := _TreeCurIndex();
   if (curIndex >= 0) {
      return _TreeGetCaption(curIndex);
   }

   return '';
}


/**
 * Returns whether the the tree item specified by index has any children.
 * 
 * @param index  tree node to check for children
 * 
 * @return whether node at index has any children 
 *  
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
boolean _TreeDoesItemHaveChildren(int index)
{
   return (_TreeGetFirstChildIndex(index) != -1);
}

/**
 * Determines whether the given node is a child of the parent
 * node.
 *
 * @param parent
 * @param child
 *
 * @return boolean
 *
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
boolean _TreeIsItemChild(int parent, int child)
{
   childParent := _TreeGetParentIndex(child);
   while (childParent > 0) {
      // is this the parent we are looking for
      if (childParent == parent) return true;

      // go up another level
      childParent = _TreeGetParentIndex(childParent);
   }

   return false;
}

/**
 * Returns whether the the tree item specified by index is
 * hidden.
 *
 * @param index  tree node to check for hiddenness
 *
 * @return whether node at index is hidden
 *
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
boolean _TreeIsItemHidden(int index)
{
   _TreeGetInfo(index, auto sc, auto ncbmi, auto cbmi, auto flags, auto lineNumber, TREENODE_HIDDEN);
   return ((flags & TREENODE_HIDDEN) != 0);
}

/**
 * Save the specified node and all of it's children.
 * This is used in conjunction with {@link _TreeRestoreNodes} to
 * save and restore the contents of a tree control to a Slick-C&reg;
 * data structure.
 * 
 * @param state   (output) filled with state of specified tree node
 * @param index   (input)  tree node to start from
 * 
 * @see _TreeCopy
 * @see _TreeRestoreNodes
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
void _TreeSaveNodes(TREENODESTATE &state, int index=TREE_ROOT_INDEX)
{
   _TreeGetInfo(index, state.show_children, state.bm1, state.bm2, state.flags);
   state.caption = _TreeGetCaption(index);
   state.current = (index == _TreeCurIndex());
   state.children._makeempty();
   state.user_info = _TreeGetUserInfo(index);

   int numChildren=0;
   if (state.show_children >= 0) {
      int child = _TreeGetFirstChildIndex(index);
      while (child > 0) {
         _TreeSaveNodes(state.children[numChildren++], child);
         child = _TreeGetNextSiblingIndex(child);
      }
   }
}

/**
 * Restore the specified node and all of it's children.
 * This is used in conjunction with {@link _TreeSaveNodes} to
 * save and restore the contents of a tree control to a Slick-C&reg;
 * data structure.  This function will also restore the
 * corresponding node as the current tree index.
 * 
 * @param state   (input)  filled with state of specified tree node
 * @param index   (input)  tree node to start from
 * 
 * @see _TreeCopy
 * @see _TreeSaveNodes
 *  
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
void _TreeRestoreNodes(TREENODESTATE &state, int parent=-1)
{
   current := -1;
   root := (parent < 0)? TREE_ROOT_INDEX:parent;
   _TreeBeginUpdate(root, 'T');
   TreeRestoreNodesRecursive(state, current, parent);
   _TreeEndUpdate(root);
   if (current >= 0) {
      _TreeSetCurIndex(current);
   }
}

static void TreeRestoreNodesRecursive(TREENODESTATE &state, int &current, int parent=-1)
{
   int index = TREE_ROOT_INDEX;
   if (parent < 0) {
      _TreeSetInfo(TREE_ROOT_INDEX, state.show_children, state.bm1, state.bm2, state.flags);
      _TreeSetCaption(TREE_ROOT_INDEX, state.caption);
      _TreeSetUserInfo(TREE_ROOT_INDEX, state.user_info);

   } else {

      index = _TreeAddItem(parent, state.caption, TREE_ADD_AS_CHILD, 
                           state.bm1, state.bm2, state.show_children, state.flags, state.user_info);
      if (index < 0) return;
   }

   int i,n = state.children._length();
   for (i=0; i<n; ++i) {
      TreeRestoreNodesRecursive(state.children[i], current, index);
   }

   if (state.current) {
      current = index;
   }
}

/**
 * Collapses all the nodes in a tree.
 * 
 * @param collapseRoot     True to collapse the root node, false to 
 *                         leave it expanded
 *  
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
void _TreeCollapseAll(boolean collapseRoot = false) 
{
   mou_hour_glass(1);

   // start at the top of the tree
   _TreeTop();

   // collapse the current node and all below it
   _TreeCollapseChildren(TREE_ROOT_INDEX, collapseRoot);

   mou_hour_glass(0);
}

/**
 * Collapses the children of the given node.
 * 
 * @param index            Node whose children need collapsing
 * @param collapseThis     whether to collapse the current node 
 * @param recurse          whether to recurse down to all children
 *  
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
void _TreeCollapseChildren(int index, boolean collapseThis = false, boolean recurse = true)
{
   show_children := TREE_NODE_COLLAPSED;
   _TreeGetInfo(index, show_children);

   // this node is a leaf - just return
   if (show_children == TREE_NODE_LEAF) {
      return;
   }

   // do we want to collapse all children?
   if (recurse) {

      // go through children and close their children
      i := _TreeGetFirstChildIndex(index);
      while (i > 0) {
         _TreeCollapseChildren(i, true, true);
   
         i = _TreeGetNextSiblingIndex(i);
      }
   }

   // this node is expanded, let's collapse it
   if (collapseThis && show_children == TREE_NODE_EXPANDED) {
      wid := p_window_id;
      call_event(CHANGE_COLLAPSED, index, p_window_id, ON_CHANGE, 'w');
      p_window_id = wid;

      _TreeSetInfo(index, TREE_NODE_COLLAPSED);
   }
}

/**
 * Collapses all other nodes in the tree except for the current one (and the 
 * path leading to it). 
 * 
 * @param index            node to leave uncollapsed
 *  
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
void _TreeCollapseOthers(int index)
{
   // get our parent
   parent := _TreeGetParentIndex(index);
   while (parent > 0) {

      // go through the siblings, collapse each one
      sibling := _TreeGetFirstChildIndex(parent);
      while (sibling > 0) {
         // check for our magic index
         if (sibling != index) {
            // collapse this fellow
            _TreeCollapseChildren(sibling, true, true);
         }
   
         // get the next one
         sibling = _TreeGetNextSiblingIndex(sibling);
      }
   }
}

/**
 * Expands all the nodes in a tree.
 * 
 *  
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
void _TreeExpandAll()
{
   mou_hour_glass(1);

   // expand everything beneath the root node
   _TreeExpandChildren(TREE_ROOT_INDEX);

   mou_hour_glass(0);
}

/**
 * Expands the children of the given node.
 * 
 * @param index            Node whose children need expanding 
 * @param recurse          whether to recurse down to all children
 *  
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
void _TreeExpandChildren(int index, int levels = -1)
{
   _TreeExpandNode(index);
   levels--;
   // do we want to expand all children?
   if (levels) {

      // go through children and expand their children
      i := _TreeGetFirstChildIndex(index);
      while (i > 0) {
         _TreeExpandChildren(i, levels);
   
         i = _TreeGetNextSiblingIndex(i);
      }
   }
}

/**
 * Expands the given node (or current node).
 * 
 * @param index            Node whose children need expanding 
 *  
 * @appliesTo Tree_View
 * @categories Tree_View_Methods
 */
void _TreeExpandNode(int index = -1)
{
   if (index == -1) index = _TreeCurIndex();

   show_children := 0;
   _TreeGetInfo(index, show_children);

   // this node is a leaf - just return
   if (show_children == TREE_NODE_LEAF) return;

   // this node is collapsed, let's expand it
   if (show_children == TREE_NODE_COLLAPSED) {
      wid := p_window_id;
      call_event(CHANGE_EXPANDED, index, p_window_id, ON_CHANGE, 'w');
      p_window_id = wid;
      _TreeSetInfo(index, TREE_NODE_EXPANDED);
   }
}

int _treeview_filename_callback(int WID,int treeIndex,_str &filename)
{
   switch ( WID.p_name ) {
   case "_proj_tooltab_tree":
      {
         if (_projecttbIsProjectFileNode(treeIndex) == true) {
            cap := WID._TreeGetCaption(treeIndex);
            parse cap with "\t" filename;
            return 0;
         }
         break;
      }
   case "ctl_file_list":
   case "ctl_project_list":
   case "ctl_workspace_list":
      {
         if ( WID.p_parent.p_parent.p_parent.p_name=="_tbfilelist_form" ) {
            cap := WID._TreeGetCaption(treeIndex);
            parse cap with auto justName "\t" auto justPath;
            filename = justPath:+justName;
            return 0;
         }
         break;
      }
   case "_file_tree":
      {
         if ( WID.p_parent.p_name=="_tbopen_form" ) {
            cap := WID._TreeGetCaption(treeIndex);
            parse cap with auto justName "\t" auto justPath;
            filename = justPath:+justName;
            return 0;
         }
         break;
      }
   }
   return -1;
}

/*static*/ void treeRefreshCallback()
{
   WATCHED_FILE_INFO fileList[];
   _GetUpdatedFileInfoList(fileList);
//   say('treeRefreshCallback fileList._length()='fileList._length());
   if ( fileList._length()>0 ) {

      fid := _find_formobj("_tbprojects_form",'N');
      if ( fid ) {
         wid := fid._find_control("_proj_tooltab_tree");
         if ( wid ) {
//            say('treeRefreshCallback 10 calling _TreeRefresh');
            wid._TreeRefresh();
         }
      }

      fid = _find_formobj("_tbopen_form",'N');
      if ( fid ) {
         wid := fid._find_control("_file_tree");
         if ( wid ) {
//            say('treeRefreshCallback 20 calling _TreeRefresh');
            wid._TreeRefresh();
         }
      }
   }
}

defeventtab _treeview_edit_form;
#define DEUBUGGING_TREE_EDIT 0

static int visibleTextBoxWID()
{
   textWID := 0;
   if ( ctltext1.p_visible ) {
      textWID = ctltext1;
   } else if ( ctlcombo_edit.p_visible ) {
      textWID = ctlcombo_edit;
   } else if ( ctlcombo_noedit.p_visible ) {
      textWID = ctlcombo_noedit;
   }
   return textWID;
}

#define COMBO_BOX_Y_OFFSET 2
#define TEXT_BOX_Y_OFFSET  1

static void shiftDownForm(int wid)
{
   if ( !_iswindow_valid(wid) ) {
      return;
   }
   switch ( wid.p_object ) {
   case OI_COMBO_BOX:
      wid.p_parent.p_y += _dx2lx(SM_TWIP,COMBO_BOX_Y_OFFSET);
      break;
   case OI_TEXT_BOX:
      wid.p_parent.p_y += _dx2lx(SM_TWIP,TEXT_BOX_Y_OFFSET);
      break;
   }
}

void _treeview_edit_form.on_resize()
{
   // Figure out what is visible
   textWID := visibleTextBoxWID();

   if ( textWID ) {
      formid := p_window_id;
      int wid=p_window_id;
      p_window_id=textWID;
      p_x = 0;
      p_y = 0;
      if ( ctlimage1.p_visible ) {
         // If the image control (button) is visible, make some room for it and
         // position it appropriately

         p_width = formid.p_width-ctlimage1.p_width;
         ctlimage1.p_x = p_x+p_width;
         ctlimage1.p_y = 0;
         ctlimage1.p_height = p_height;
      } else {
         p_width = formid.p_width;
      }
      if ( p_height > formid.p_height ) {
         formid.p_height = p_height;
      } else {
         p_height = formid.p_height;
      }
      p_window_id=wid;
   } else {
      if ( ctlimage1.p_visible ) {
         // If the image control (button) is visible, make some room for it and
         // position it appropriately
         ctlimage1.p_x = p_width - ctlimage1.p_width;
         ctlimage1.p_y = 0;

         if ( ctltext1.p_height > p_height ) {
            p_height = ctltext1.p_height;
         }
         ctlimage1.p_height = p_height;
      }
   }
   if ( textWID ) {
      if ( _GetDialogInfoHt("pendingShiftFormDown")!=1 ) {
         _SetDialogInfoHt("pendingShiftFormDown",1);
         _post_call(shiftDownForm,textWID);
      }
   }
}

void ctltext1.on_create(int editFlags=TREE_EDIT_TEXTBOX, _str info = '')
{                      
   // Set the color to match the backgrond color of the tree control.
   // Might need to do more work here to match the background color for the
   // particular node/column we are using
   int wid   = 0;
   int index = 0;
   int col   = 0;
   if (info != '') {
      parse info with auto sWID auto sIndex auto sCol;
      wid = (int) sWID;
      index = (int) sIndex;
      col = (int) sCol;
   }

   p_parent.p_backcolor = p_parent.p_parent.p_backcolor;

   visibleWID := 0;

   if ( editFlags&TREE_EDIT_BUTTON ) {
      visibleWID = ctltext1;

      ctlcombo_edit.p_visible = 0;
      ctlcombo_noedit.p_visible = 0;

      if ( !(editFlags&TREE_EDIT_TEXTBOX) ) {

         // Use the text box to show the background - IMPORTANT: we have to do 
         // this because the image cannot get focus
         ctltext1.p_ReadOnly = 1;
         ctltext1.p_border_style = BDS_NONE;
         if ( wid!=0 && index!=0 && col!=0 ) {
            // Set the background color on the textbox and form to match
            wid._TreeGetColor(index,col,auto fgcolor,auto bgcolor,auto flags);
            ctltext1.p_backcolor = p_parent.p_backcolor = bgcolor;
         }
      }
   }

   if ( editFlags&TREE_EDIT_TEXTBOX ) {
      ctlcombo_edit.p_visible = 0;
      ctlcombo_noedit.p_visible = 0;
      visibleWID = ctltext1;
   }
   if ( editFlags&TREE_EDIT_COMBOBOX ) {
      ctltext1.p_visible = 0;
      ctlcombo_edit.p_visible = 0;
      visibleWID = ctlcombo_noedit;
   }
   if ( editFlags&TREE_EDIT_EDITABLE_COMBOBOX ) {
      ctltext1.p_visible = 0;
      ctlcombo_noedit.p_visible = 0;
      visibleWID = ctlcombo_edit;
   }
   if ( !(editFlags&TREE_EDIT_BUTTON) ) {
      ctlimage1.p_visible = 0;
   }

   if (visibleWID != ctlimage1) {
      ctlimage1.p_tab_index = visibleWID.p_tab_index +1;
   }
}
int _treeEditSendOpenEvent(_str info)
{
   parse info with auto sWID auto sIndex auto sCol;
   int wid = (int) sWID;
   if ( !_iswindow_valid(wid) ) return 0;
   int index = (int) sIndex;
   if ( index<0 ) return 0;
   int col = (int) sCol;
   text := wid._TreeGetTextForCol(index,col);
   status := wid.call_event(CHANGE_EDIT_PROPERTY,index,col,text,wid,ON_CHANGE,'w');
   if ( status&TREE_EDIT_COLUMN_BIT ) {
      wid._TreeEditNode(index,status&(~TREE_EDIT_COLUMN_BIT));
   }
   return 0;
}

static void closeEditorCallback(_str info)
{
   parse info with auto sformWID auto sindex auto scol auto ssaveData;
   int formWID = (int)sformWID;
   int index = (int)sindex;
   int col = (int)scol;
   int saveData = (int)ssaveData;

   if ( !_iswindow_valid(formWID) ) {
      return;
   }
   if ( _GetDialogInfoHt("listDown",formWID)==1 ) {
      return;
   }
   if ( _GetDialogInfoHt("inLbuttonUp",formWID)==1 ) {
      return;
   }
   _nocheck _control ctltree1;
   formWID.p_parent._TreeCloseEditor(index,col,saveData);
}

static void post_close_editor(int formWID,int index,int col,int saveData)
{
   if ( _GetDialogInfoHt("closePosted")!=1 ) {
      _SetDialogInfoHt("closePosted",1);
      _post_call(closeEditorCallback,formWID' 'index' 'col' 'saveData);
   }
}

static void editorEventCallback(_str info)
{
   parse info with auto sWID auto event auto sReason;
   int tbOrCbWID = (int)sWID;
   if ( !_iswindow_valid(tbOrCbWID) ) {
      return;
   }
   int formWID = tbOrCbWID.p_parent;
   int reason = -1;
   if ( isinteger(sReason) ) reason = (int)sReason;

   if ( _GetDialogInfoHt("inLbuttonUp",formWID)==1 ) {
      return;
   }
   if ( _GetDialogInfoHt("listDown",formWID)==1 ) {
      // 11/8/2011
      // We have to check for CHANGE_CLINE and let it through.  DROP_UP and
      // CHANGE_CLINE come in different order on Windows/Unix and Mac.  So we
      // have to let this one through even if the list is down.
      if ( reason!=CHANGE_CLINE ) return;
   }

   int wid=p_window_id;
   p_window_id=tbOrCbWID;
   switch ( event ) {
   case "on_change":
      switch ( reason ) {
      case CHANGE_OTHER:
      case CHANGE_CLINE:
      case CHANGE_CLINE_NOTVIS:
      case CHANGE_CLINE_NOTVIS2:
      case CHANGE_SELECTED:
         callCloseEditor(1,1,0);
         _SetDialogInfoHt("calledClose",1,formWID);
      }
      break;
   case "on_lost_focus":
      if ( _get_focus()!=tbOrCbWID ) {
         callCloseEditor(1,1);
         _SetDialogInfoHt("calledClose",1,formWID);
      }
      break;
   case "enter":
      callCloseEditor(1,1,1,1);
      _SetDialogInfoHt("calledClose",1,formWID);
      break;
   case "esc":
      callCloseEditor(0,0,1,1);
      _SetDialogInfoHt("calledClose",1,formWID);
      break;
   }
   p_window_id=wid;
}

static void editorEvent(_str info)
{
   _post_call(editorEventCallback,info);
}

void ctlcombo_edit.on_lost_focus()
{
   editorEvent(p_window_id' on_lost_focus ');
}

void ctlcombo_edit.enter()
{
   editorEvent(p_window_id' enter ');
}

void ctlcombo_edit.esc()
{
   editorEvent(p_window_id' esc ');
}

void ctlcombo_edit.on_drop_down(int reason)
{
   switch ( reason ) {
   case DROP_DOWN:
      _SetDialogInfoHt("listDown",1);
      break;
   case DROP_UP:
      _SetDialogInfoHt("listDown",0);
      break;
   }
}

void ctlcombo_edit.on_change(int reason)
{
   if ( !p_visible ) return ;
   if ( _GetDialogInfoHt("inOnChange")==1 ){
      return;
   }
   _SetDialogInfoHt("inOnChange",1);
   // We only want to commit data immediately for the PSCBO_NOEDIT style.
   // The combo box could have the PSCBO_EDIT style, in which case we
   // want enter to set the data (just like a textbox)
   if ( p_style==PSCBO_NOEDIT ) {
      switch ( reason ) {
      case CHANGE_OTHER:
      case CHANGE_CLINE:
      case CHANGE_CLINE_NOTVIS:
      case CHANGE_CLINE_NOTVIS2:
      case CHANGE_SELECTED:
         editorEvent(p_window_id' on_change 'reason);
         break;
      }
   }
   _SetDialogInfoHt("inOnChange",0);
}

void ctltext1.on_change()
{
}

static void callCloseEditor(int callEvent,int saveData,int closeEditor=1,int setParentFocus=0)
{
   if ( !p_visible ) {
      return;
   }

   index := _GetDialogInfoHt("treeIndex");
   col   := _GetDialogInfoHt("treeCol");
   if (!isinteger(index) || !isinteger(col)) return;

   deletedElement := false;

   _str text = "";
   if ( callEvent ) {
      text = p_text;
      status := p_parent.p_parent.call_event(CHANGE_EDIT_CLOSE,index,col,text,p_parent.p_parent,ON_CHANGE,'w');
      if ( status==-1 ) {
         post_set_focus(ctltext1);
         p_parent.p_parent._TreeSetEditorState(TREEVIEWEEDITOR_ERROR);
         return;
      }
      origInOnChange   := _GetDialogInfoHt("inOnChange");
      _SetDialogInfoHt("inOnChange",1);
      p_text = text;
      _SetDialogInfoHt("inOnChange",origInOnChange);
      if ( status==DELETED_ELEMENT_RC ) {
         deletedElement = true;
         saveData = 0;
      }
   }
   if ( closeEditor ) {
      // 10/24/2011
      // Need to commit data immediate - there are things places where after
      // CHANGE_EDIT_CLOSE we use CHANGE_OTHER to review data in the tree.
      // Since post_close_editor uses _post_call, the data has to be set 
      // before that
      if ( saveData ) {
         p_parent.p_parent._TreeCommitEditorData(index,col);
      }
      // Already saved the data, so we can pass 0 here
      post_close_editor(p_parent,index,col,0);

      // In case we hit escape, so get the index right
      if ( !deletedElement && (p_parent.p_parent._TreeCurIndex()!=index) ) {
//         say('callCloseEditor setting index to 'p_parent.p_parent._TreeGetCaption(index));
//         p_parent.p_parent._TreeSetCurIndex(index);
      }
   } else if ( saveData ) {
      p_parent.p_parent._TreeCommitEditorData(index,col);
   }
   if ( setParentFocus ) {
      post_set_focus(p_parent.p_parent);
   }
   // There are places we look for this CHANGE_OTHER to look at the tree data
   // after the CHANGE_EDIT_CLOSE.
   p_parent.p_parent.call_event(CHANGE_OTHER,index,col,text,p_parent.p_parent,ON_CHANGE,'w');
}

void ctltext1.on_lost_focus()
{
   editorEvent(p_window_id' on_lost_focus ');
}

void ctltext1.enter()
{
   editorEvent(p_window_id' enter ');
}

void ctltext1.esc()
{
   editorEvent(p_window_id' esc ');
}

static void posted_set_focus_callback(int wid)
{
   if ( !_iswindow_valid(wid) ) {
      return;
   }
   wid._set_focus();
   if ( wid.p_object==OI_TEXT_BOX || wid.p_object==OI_COMBO_BOX ) {
      wid._set_focus();
      wid._set_sel(1,length(wid.p_text)+1);
   }
}

static void post_set_focus(int wid)
{
   _post_call(posted_set_focus_callback,wid);
}

void ctlimage1.lbutton_down()
{
   _SetDialogInfoHt("inLbuttonUp",1);
}

void ctlimage1.lbutton_up()
{
   if ( !p_visible ) {
      return;
   }
   textWID := visibleTextBoxWID();
   int wid=p_window_id;

   _str text = "";
   focusWID := 0;
   if ( ctltext1.p_visible ) {
      focusWID = ctltext1;
   } else if ( ctlcombo_noedit.p_visible ) {
      focusWID = ctlcombo_noedit;
   } else if ( ctlcombo_edit.p_visible ) {
      focusWID = ctlcombo_edit;
   }

   if (focusWID) {
      text = focusWID.p_text;
   }

   // Set the window id to the parent tree while we make the on_change call
   // There is a form that is the parent of the image control, so the 
   // tree is p_parent.p_parent
   ArgumentCompletionTerminate();
   index := _GetDialogInfoHt("treeIndex");
   col   := _GetDialogInfoHt("treeCol");
   if (!isinteger(index) || !isinteger(col)) return;
   p_window_id=p_parent.p_parent;
   _TreeGetColor(index,col,auto origFGColor,auto origBGColor,auto origFlags);
   call_event(CHANGE_NODE_BUTTON_PRESS,_TreeCurIndex(),-1,text,textWID,p_window_id,ON_CHANGE,'W');
   _TreeGetColor(index,col,auto curFGColor,auto curBGColor,auto curFlags);
   p_window_id=wid;
   if ( ctltext1.p_ReadOnly && origBGColor!=curBGColor ) {
      ctltext1.p_backcolor = p_parent.p_backcolor = curBGColor;
   }
   _SetDialogInfoHt("inLbuttonUp",0);

   if (focusWID) {
      focusWID._set_focus();
   }
}
