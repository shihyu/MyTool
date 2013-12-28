////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46533 $
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
#include "dirlist.sh"
#import "dirlist.e"
#import "stdprocs.e"
#import "treeview.e"
#import "mprompt.e"
#endregion

/**
 * Explorer Tree callback for when the working directory needs
 * to be changed
 */
typedef void (*pfnExpTreeCWDCallback_t)(_str id);

//
//    User level 2 inheritance for DIRECTORY TREE
//

defeventtab _ul2_dirtree _inherit _ul2_tree;

// Note:
// Will give undefined result for dataset (e.g. OS/390) path, so do your checking
// before you call this function.
static boolean haveAtleastOneChildDirectory(_str path)
{
   if( last_char(path)!=FILESEP ) {
      path=path:+FILESEP;
   }
   boolean foundAnything = false;
   _str result = file_match(maybe_quote_filename(path:+ALLFILES_RE)' +X +D +S -P -V',1);
   while( result!="" ) {
      if( last_char(result)==FILESEP && result!=".":+FILESEP && result!="..":+FILESEP ) {
         result=substr(result,1,length(result)-1);
         result=substr(result,lastpos(FILESEP,result)+1);
         if( result!="." && result!=".." ) {
            // We have subdirectories
            foundAnything = true;
            break;
         }
      }
      result = file_match(maybe_quote_filename(path)' +X +D +S -P -V',0);
   }
   // No child directories
   return foundAnything; 
}

static itemType2PicIndex(int itemType)
{
   int pic = 0;
   switch( itemType ) {
   case DLITEMTYPE_FOLDER_OPEN:
      pic=_pic_fldopen;
      break;
   case DLITEMTYPE_FOLDER_AOPEN:
      pic=_pic_fldaop;
      break;
   case DLITEMTYPE_FOLDER_CLOSED:
      pic=_pic_fldclos;
      break;
   case DLITEMTYPE_LEAF:
      pic=_pic_fldclos;
      break;
   }
   return pic;
}

// Note:
// It is expected that fullPath is NOT quoted.
static boolean cbAddChildItem(_str item, int itemType, _str fullPath)
{
   // Item inserted into tree is a leaf node until proven otherwise
   int showChildren = -1;
   if( itemType!=DLITEMTYPE_LEAF ) {
      showChildren = 0;
   }
   // add it to the tree
   int index = _TreeCurIndex();
   if( index<0 ) {
      // Root
      index=TREE_ROOT_INDEX;
   }
   int pic = itemType2PicIndex(itemType);
   index=_TreeAddItem(index,item,TREE_ADD_AS_CHILD,pic,pic,showChildren);
   _TreeSetCurIndex(index);
   return true;
}

// Note:
// It is expected that fullPath is NOT quoted.
static boolean cbAddSiblingItem(_str item, int itemType, _str fullPath)
{
   // Item inserted into tree is a leaf node until proven otherwise
   int showChildren = -1;
   if( itemType!=DLITEMTYPE_LEAF ) {
      showChildren = 0;
   }
   // add it to the tree
   int index = _TreeCurIndex();
   if( index<0 ) {
      // Root
      index=TREE_ROOT_INDEX;
   }
   int pic = itemType2PicIndex(itemType);
   index=_TreeAddItem(index,item,0,pic,pic,showChildren);
   _TreeSetCurIndex(index);
   return true;
}

static void cbSavePos(_str id="")
{
   if( id=="" ) {
      id="unnamed_pos";
   }
   DirListObject_t dlo = _dlGetDirListObject();
   typeless p;
   _TreeSavePos(p);
   dlo.ht:[id]=p;
   _dlSetDirListObject(dlo);
}

static void cbRestorePos(_str id="")
{
   if( id=="" ) {
      id="unnamed_pos";
   }
   DirListObject_t dlo = _dlGetDirListObject();
   if( dlo.ht._indexin(id) ) {
      typeless p = dlo.ht:[id];
      _TreeRestorePos(p);
      //dlo.ht._deleteel("pos");
      //_dlSetDirListObject(dlo);
   }
}

static void cbClear()
{
   _TreeDelete(TREE_ROOT_INDEX,'C');
}

static void cbSelectItem()
{
   int index = _TreeCurIndex();
   _TreeDeselectAll();
   _TreeSelectLine(index);
}

static void cbDeselectItem()
{
   int index = _TreeCurIndex();
   _TreeDeselectLine(index);
}

static void cbDeselectAll()
{
   _TreeDeselectAll();
}

static void cbSortChildren()
{
   int index = _TreeCurIndex();
   // Note:
   // Sort is case-insensitive by default (which is what we want).
   _TreeSortCaption(index,'2');
}

static void cbTop()
{
   _TreeTop();
}

static void cbBottom()
{
   _TreeBottom();
}

static boolean cbGotoParent()
{
   int index = _TreeCurIndex();
   if( index<=TREE_ROOT_INDEX ) {
      return false;
   }
   index=_TreeGetParentIndex(index);
   if( index>TREE_ROOT_INDEX ) {
      _TreeSetCurIndex(index);
      return true;
   }
   return false;
}

static boolean cbGotoFirstChild()
{
   int index = _TreeCurIndex();
   if( index<TREE_ROOT_INDEX ) {
      return false;
   }
   index=_TreeGetFirstChildIndex(index);
   if( index>TREE_ROOT_INDEX ) {
      _TreeSetCurIndex(index);
      return true;
   }
   // No children
   return false;
}

static boolean cbGotoNextSibling()
{
   int index = _TreeCurIndex();
   if( index<TREE_ROOT_INDEX ) {
      return false;
   }
   index=_TreeGetNextSiblingIndex(index);
   if( index>TREE_ROOT_INDEX ) {
      _TreeSetCurIndex(index);
      return true;
   }
   // No next sibling
   return false;
}

static void cbGetItem(_str& item)
{
   item="";
   int index = _TreeCurIndex();
   if( index>TREE_ROOT_INDEX ) {
      item=_TreeGetCaption(index);
   }
}

static void cbSetItem(_str item, int itemType)
{
   int index = _TreeCurIndex();
   if( index>TREE_ROOT_INDEX ) {
      _TreeSetCaption(index,item);
      // A leaf until proven otherwise
      int ShowChildren = -1;
      switch( itemType ) {
      case DLITEMTYPE_FOLDER_OPEN:
         ShowChildren=1;
         break;
      case DLITEMTYPE_FOLDER_AOPEN:
         ShowChildren=1;
         break;
      case DLITEMTYPE_FOLDER_CLOSED:
         ShowChildren=0;
         break;
      }
      int pic = itemType2PicIndex(itemType);
      _TreeSetInfo(index,ShowChildren,pic,pic);
   }
}

static void cbDeleteChildren()
{
   int index = _TreeCurIndex();
   if( index>=TREE_ROOT_INDEX ) {
      _TreeDelete(index,'C');
   }
}

static void cbDeleteItem()
{
   int index = _TreeCurIndex();
   if( index>TREE_ROOT_INDEX ) {
      _TreeDelete(index);
   }
}

// Nothing to do for a tree control.
static void cbAdjustScroll()
{
}

/**
 * Initialize directory tree Directory List Object.
 * <p>
 * IMPORTANT: <br>
 * This must be called before anything else so that callbacks are registered
 * before an attempt is made to call them. Call this function early (e.g in
 * an ON_CREATE or ON_CREATE2 event).
 * <p>
 * IMPORTANT: <br>
 * Current window must be tree control.
 */
void _dirtreeInit()
{
   // Initialize the DirectoryListObject with our directory list tree callbacks
   DirListObject_t dlo;
   _dlDirListObjectInit(dlo);
   dlo.pfnViewAddChildItem=cbAddChildItem;
   dlo.pfnViewAddSiblingItem=cbAddSiblingItem;
   dlo.pfnViewSavePos=cbSavePos;
   dlo.pfnViewRestorePos=cbRestorePos;
   dlo.pfnViewClear=cbClear;
   dlo.pfnViewSelectItem=cbSelectItem;
   dlo.pfnViewDeselectItem=cbDeselectItem;
   dlo.pfnViewDeselectAll=cbDeselectAll;
   dlo.pfnViewSortChildren=cbSortChildren;
   dlo.pfnViewTop=cbTop;
   dlo.pfnViewBottom=cbBottom;
   dlo.pfnViewGotoParent=cbGotoParent;
   dlo.pfnViewGotoFirstChild=cbGotoFirstChild;
   dlo.pfnViewGotoNextSibling=cbGotoNextSibling;
   dlo.pfnViewGetItem=cbGetItem;
   dlo.pfnViewSetItem=cbSetItem;
   dlo.pfnViewDeleteChildren=cbDeleteChildren;
   dlo.pfnViewDeleteItem=cbDeleteItem;
   dlo.pfnViewAdjustScroll=cbAdjustScroll;
   _dlSetDirListObject(dlo);
}

// _ul2_dirtree.ON_CREATE2
//
// Called if you have set user-level-2 inheritance on a control for a form.
// Directory tree is automatically populated with the current working directory.
//
// Note:
// If you do not want a directory automatically populated, then do not
// set p_eventtab2=_ul2_dirtree. Instead call _dirtreeInit() to initialize
// the directory tree.
//
// Example:
// defeventtab form1;
// void tree1.on_create()
// {
//    _dirtreeInit();
// }
void _ul2_dirtree.on_create2()
{
   _dirtreeInit();

   p_redraw=0;
   _dlpath("");
   p_redraw=1;
}

/**
 * ON_CHANGE event is called with reason for event.
 * Typically, this event will be overridden by the dialog using
 * the directory tree control. In order to call the base ON_CHANGE event
 * handler for a directory tree, use call_event.
 * 
 * @param reason    Reason for ON_CHANGE event. One of CHANGE_* constants.
 * @param nodeIndex Index of tree node affected.
 * @param force     Force action even if already in an ON_CHANGE event.
 *                  Note that only the current event handler's action is
 *                  forced and not chained to _ul2_tree.ON_CHANGE.
 *                  Defaults to false.
 */
void _ul2_dirtree.on_change(int reason, int nodeIndex, boolean force=false)
{
   if( !force && _dlInOnChange() ) {
      // Recursion not allowed!
      return;
   }
   boolean old_inOnChange = _dlInOnChange(1);
   switch( reason ) {
   case CHANGE_EXPANDED:
      {
         // The node expanded is not necessarily the current node, so we
         // must temporarily set it current so that _dlBuildSelectedPath()
         // will work, then set it back.  Resetting the current node will
         // change the scroll so save and restore that as as well
         int oldIndex = _TreeCurIndex();
         oldScroll := _TreeScroll();
         if( oldIndex!=nodeIndex ) {
            _TreeSetCurIndex(nodeIndex);
         }
         mou_hour_glass(1);
         _str new_path = _dlBuildSelectedPath();
         _dlpathChildren(new_path);
         if( oldIndex!=nodeIndex ) {
            _TreeSetCurIndex(oldIndex);
            _TreeScroll(oldScroll);
         }
         mou_hour_glass(0);
      }
      break;
   }
   _dlInOnChange((int)old_inOnChange);
}


///////////////////////////////////////////////////////////////////////////
// Explorer Tree
///////////////////////////////////////////////////////////////////////////

#define ETDATA_MYCOMPUTER 0
#define ETDATA_NETWORK 1
#define ETDATA_FAVORITES 2

/**
 * Event table for "Explorer Tree". Specialization of the 
 * dirtree event table. Used to create a Windows Explorer-like 
 * control for use in the Open dialog.  
 */
defeventtab _ul2_explorertree _inherit _ul2_dirtree;

// Holds the user-defined favorite places
static _str _fav_places:[];

void _ul2_explorertree.on_create2()
{
   //_fav_places._makeempty();
   _etInitCallbacks();
   p_redraw=0;
   _etInitUI();
   _set_current_path("");
   p_redraw=1;
}

/**
 * ON_CHANGE event is called with reason for event.
 * Typically, this event will be overridden by the dialog using
 * the directory tree control. In order to call the base ON_CHANGE event
 * handler for a directory tree, use call_event.
 * 
 * @param reason    Reason for ON_CHANGE event. One of CHANGE_* constants.
 * @param nodeIndex Index of tree node affected.
 * @param force     Force action even if already in an ON_CHANGE event.
 *                  Note that only the current event handler's action is
 *                  forced and not chained to _ul2_tree.ON_CHANGE.
 *                  Defaults to false.
 */
void _ul2_explorertree.on_change(int reason, int nodeIndex, _str event = '')
{
   if( _dlInOnChange() ) {
      // Recursion not allowed!
      return;
   }
   boolean old_inOnChange = _dlInOnChange(1);
   oldScroll := _TreeScroll();
   if( reason == CHANGE_EXPANDED)
   {
         int computerNode = _GetDialogInfo(ETDATA_MYCOMPUTER, p_window_id );
#if !__UNIX__
         int networkNode = _GetDialogInfo(ETDATA_NETWORK, p_window_id );
#else
         // Not implementing network browsing on *nix, for now
         int networkNode = -2;
#endif
         int favesNode = _GetDialogInfo(ETDATA_FAVORITES, p_window_id );

         // The node expanded is not necessarily the current node, so we
         // must temporarily set it current so that _dlBuildSelectedPath()
         // will work, then set it back.  Resetting the current node will
         // change the scroll so save and restore that as as well
         int oldIndex = _TreeCurIndex();
         if( oldIndex!=nodeIndex ) {
            _TreeSetCurIndex(nodeIndex);
         }
         mou_hour_glass(1);
         if( nodeIndex == networkNode ) {
            // Handle expansion of the top-level network node
            _etExpandNetwork(networkNode);
         }
         else if( nodeIndex != computerNode && nodeIndex != favesNode ) {

            // See if this node is an expansion of a network computer
            int nShowChildren, nBMI1, nBMI2;
            _TreeGetInfo(nodeIndex, nShowChildren, nBMI1, nBMI2);
            if(nBMI1 == _pic_otb_server) {
               _etExpandNetworkComputerNode();
            }
            else{
               // Handle expansion of drive paths below the top level
               _str new_path = _etBuildSelectedPath();
               if( new_path != "" ) {
                  _etpathChildren(new_path);
               }
            }
         }

         if( oldIndex!=nodeIndex ) {
            _TreeSetCurIndex(oldIndex);
         }
         _TreeScroll(oldScroll);
         mou_hour_glass(0);
   } else if( reason == CHANGE_COLLAPSED ) {
      // if the current node has been collapsed into invisibility, then
      // set the current node to be the collapsed parent node
      int oldIndex = _TreeCurIndex();
      if( oldIndex!=nodeIndex && _TreeIsItemChild(nodeIndex, oldIndex)) {
         _TreeSetCurIndex(nodeIndex);
      }

   }

   // Double-clicks and ENTER key cause a change to the current
   // working directory.
   if( (reason == CHANGE_LEAF_ENTER) || (event == ENTER) || (event == LBUTTON_DOUBLE_CLICK) ) {
      pfnExpTreeCWDCallback_t cb = _GetDialogInfoHt("cwdcb", p_window_id, true);
      if( cb ) {
         (*cb)(_etBuildSelectedPath());
      }
      if ( reason==CHANGE_EXPANDED ) {
         _TreeScroll(oldScroll);
      }
      p_redraw = true;
      _TreeRefresh();
   }
   _dlInOnChange((int)old_inOnChange);
}

/**
 * Handles Delete key, to remove a favorite place
 */
void _ul2_explorertree.DEL(){
   _explorerTree_MaybeDeleteFavorite();
}

/**
 * Mouse handler, displays the explorer tree context menu
 */
void _ul2_explorertree.rbutton_up(){
   _explorerTree_ShowContextMenu();
}

/**
 * Handles delete key or context menu 'Remove Favorite' commands
 */
static void _explorerTree_MaybeDeleteFavorite(){
   int index = _TreeCurIndex();
   int favesNode = _GetDialogInfo(ETDATA_FAVORITES, p_window_id );
   int maybeFaveRoot = _TreeGetParentIndex(index);
   if( _explorerTree_SelectedIsFavorite() ) {
      _str faveName = _TreeGetCaption(index);
      // Prompt to remove
      _remove_favorite_place(faveName, true);
   }
}

/**
 * Handles the "Add Favorite" context menu command
 */
static void _explorerTree_MaybeAddFavorite(){
   _str path = _etBuildSelectedPath();
   if( path._length() > 3 ) {
      _add_favorite_place(path, true);
   }
}

/**
 * Determines if the selected item is an immediate child of the 
 * "Favorites" category.
 * 
 * @return boolean True, if a favorite
 */
static boolean _explorerTree_SelectedIsFavorite(){
   int favesNode = _GetDialogInfo(ETDATA_FAVORITES, p_window_id );
   int index = _TreeCurIndex();
   int maybeFaveRoot = _TreeGetParentIndex(index);
   if( maybeFaveRoot == favesNode ){
      return true;
   }
   return false;
}

/**
 * Determines if the selected item is one of the top level 
 * nodes, like 'Favorites', 'Computer', or 'Network', or an 
 * immediate child of 'Network' or 'Computer' 
 * @return boolean True, if a special top-level node
 */
static boolean _explorerTree_SelectedIsTopLevelNode(){
   int index = _TreeCurIndex();
   int parentIndex = _TreeGetParentIndex(index);
   int favesNode = _GetDialogInfo(ETDATA_FAVORITES, p_window_id);
   int compNode = _GetDialogInfo(ETDATA_MYCOMPUTER, p_window_id);
   #if !__UNIX__
   int netNode = _GetDialogInfo(ETDATA_NETWORK, p_window_id);
   return ((index == favesNode) || (index == compNode) || (parentIndex == compNode) || (index == netNode) || (parentIndex == netNode));
   #else
   return ((index == favesNode) || (index == compNode) || (parentIndex == compNode));
   #endif
}



/**
 * Displays the explorer tree context menu
 */
void _explorerTree_ShowContextMenu(){
   // Load the teeny-tiny explorer tree menu
   // Just has commands for adding and removing favorites
   menuIndex := find_index("_explorerTree_menu", oi2type(OI_MENU));
   menuHandle := _mdi._menu_load(menuIndex, 'P');
   if( menuHandle ) {
      int enableAdd = MF_GRAYED;
      int enableDelete = MF_GRAYED;
      // Examine the selection. 
      if( _explorerTree_SelectedIsFavorite() ) {
         // If the item *is* a favorite, then enable the "Remove Favorite" menu item
         enableDelete = MF_ENABLED;
      }
      else{
         // If the item is *not* a top-level node (we already know it's not a favorite)
         // then enable the "Add Favorite"
         if( _explorerTree_SelectedIsTopLevelNode() == false ) {
            enableAdd = MF_ENABLED;
         }
      }
      _menu_set_state(menuHandle, "explorertree-menu-command addfave", enableAdd, 'M');
      _menu_set_state(menuHandle, "explorertree-menu-command delfave", enableDelete, 'M');
      int x, y;
      mou_get_xy(x, y);
      status := _menu_show(menuHandle, VPM_RIGHTBUTTON, x-1, y-1);
   }

}

/**
 * Handles command events from the explorer tree context menu
 * 
 * @param cmdline 'addFave' or 'delFave' command
 */
_command void explorertree_menu_command(_str cmdline="") name_info(',') {
   // parse the command and figure out what to do
   parse cmdline with auto cmd .;
   switch (upcase(cmd)) {
   case 'ADDFAVE':
      _explorerTree_MaybeAddFavorite();
      break;
   case 'DELFAVE':
      _explorerTree_MaybeDeleteFavorite();
      break;
   }
}


static void etcbSetItem(_str item, int itemType)
{
   int index = _TreeCurIndex();
   if( index>TREE_ROOT_INDEX ) {
      _TreeSetCaption(index,item);
      // A leaf until proven otherwise
      int ShowChildren = -1;
      switch( itemType ) {
      case DLITEMTYPE_FOLDER_OPEN:
         ShowChildren=1;
         break;
      case DLITEMTYPE_FOLDER_AOPEN:
         ShowChildren=1;
         break;
      case DLITEMTYPE_FOLDER_CLOSED:
         ShowChildren=0;
         break;
      }
      _TreeSetInfo(index,ShowChildren);
   }
}

// Note:
// It is expected that fullPath is NOT quoted.
static boolean etcbAddChildItem(_str item, int itemType, _str fullPath)
{
   // Item inserted into tree is a leaf node until proven otherwise
   int showChildren = -1;
   if( itemType!=DLITEMTYPE_LEAF ) {
      showChildren = 0;
   }
   // add it to the tree
   int index = _TreeCurIndex();
   if( index<0 ) {
      // Root
      index=TREE_ROOT_INDEX;
   }
   int pic = itemType2PicIndex(itemType);
   index=_TreeAddItem(index,item,TREE_ADD_AS_CHILD,pic,pic,showChildren);
   _TreeSetCurIndex(index);
   return true;
}

// Note:
// It is expected that fullPath is NOT quoted.
static boolean etcbAddSiblingItem(_str item, int itemType, _str fullPath)
{
   // Item inserted into tree is a leaf node until proven otherwise
   int showChildren = -1;
   if( itemType!=DLITEMTYPE_LEAF ) {
      showChildren = 0;
   }
   int index = _TreeCurIndex();
   if( index<0 ) {
      // Root
      index=TREE_ROOT_INDEX;
   }
   int pic = itemType2PicIndex(itemType);
   index=_TreeAddItem(index,item,TREE_ADD_AFTER,pic,pic,showChildren);
   _TreeSetCurIndex(index);
   return true;
}


/**
 * Initialize the DirectoryListObject with our tree callbacks. 
 * Mostly the same as the _ul2_dirtree 
 */
static void _etInitCallbacks()
{
   DirListObject_t dlo;
   _dlDirListObjectInit(dlo);
   dlo.pfnViewAddChildItem=etcbAddChildItem;
   dlo.pfnViewAddSiblingItem=etcbAddSiblingItem;
   dlo.pfnViewSavePos=cbSavePos;
   dlo.pfnViewRestorePos=cbRestorePos;
   dlo.pfnViewClear=cbClear;
   dlo.pfnViewSelectItem=cbSelectItem;
   dlo.pfnViewDeselectItem=cbDeselectItem;
   dlo.pfnViewDeselectAll=cbDeselectAll;
   dlo.pfnViewSortChildren=cbSortChildren;
   dlo.pfnViewTop=cbTop;
   dlo.pfnViewBottom=cbBottom;
   dlo.pfnViewGotoParent=cbGotoParent;
   dlo.pfnViewGotoFirstChild=cbGotoFirstChild;
   dlo.pfnViewGotoNextSibling=cbGotoNextSibling;
   dlo.pfnViewGetItem=cbGetItem;
   dlo.pfnViewSetItem=etcbSetItem;
   dlo.pfnViewDeleteChildren=cbDeleteChildren;
   dlo.pfnViewDeleteItem=cbDeleteItem;
   dlo.pfnViewAdjustScroll=cbAdjustScroll;
   _dlSetDirListObject(dlo);
}

/**
 *  Initializes the top-level folder structure of the explorer
 *  tree control. Creates the "Computer", "Network", and
 *  "Favorites" folders.
 */
static void _etInitUI()  
{
   // Create the top-level items
   int index_faves = _TreeAddItem(TREE_ROOT_INDEX, "Favorites", TREE_ADD_AS_CHILD, _pic_otb_favorites, _pic_otb_favorites, 0);
   _SetDialogInfo(ETDATA_FAVORITES, index_faves, p_window_id, false);
   int index_computer = _TreeAddItem(TREE_ROOT_INDEX, "Computer", TREE_ADD_AS_CHILD, _pic_otb_computer, _pic_otb_computer, 0);
   _SetDialogInfo(ETDATA_MYCOMPUTER, index_computer, p_window_id, false);
#if !__UNIX__
   int index_network = _TreeAddItem(TREE_ROOT_INDEX, "Network", TREE_ADD_AS_CHILD, _pic_otb_network, _pic_otb_network, 0);
   _SetDialogInfo(ETDATA_NETWORK, index_network, p_window_id, false);
#endif

   // Populate drive letters
   _str DriveList[];
#if __UNIX__
   DriveList[0]='/';
#else
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   _insert_drive_list();
   top();up();
   while ( !down() ) {
      get_line(auto line);
      DriveList[DriveList._length()]=strip(line);
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
#endif

   _TreeBeginUpdate(index_computer,'T');
   int i;
   for ( i=0;i<DriveList._length();++i ) {
      int picture=0;
      int drType = _drive_type(DriveList[i]);
      switch( drType) {
      case DRIVE_FIXED:
         picture = _pic_otb_fixed;
         break;
      case DRIVE_REMOTE:
         picture = _pic_otb_remote;
         // TODO: For remote drive, we need to get the share
         // name. Then we'll need to account for this share name
         // when searching the tree
         break;
      case DRIVE_CDROM:
         picture = _pic_otb_cdrom;
         break;
      default:
         picture = _pic_otb_floppy;
         break;
      }
      _TreeAddItem(index_computer,DriveList[i],TREE_ADD_AS_CHILD,picture,picture,0);
   }
   _TreeEndUpdate(index_computer);

   // Populate favorites
   _explorerTree_InitFavePlacesCache();
   _str lastData= '';
   if(!_fav_places._isempty() && index_faves > 0) {
      _TreeBeginUpdate(index_faves, "T");
      _str favName;
      foreach (favName => auto v in _fav_places ) {
         _TreeAddItem(index_faves, favName, TREE_ADD_AS_CHILD, _pic_fldclos12, _pic_fldclos12, 0);
      }
      _TreeEndUpdate(index_faves);
   }
   // Don't expand the network until asked
}

/**
 * @return Full path of selected explorer tree item.
 */
_str _etBuildSelectedPath()
{
   // TODO: Need to detect our "special" nodes. If this is the "Computer"
   // node, this is expanding to show the list of drives.
   // If it's another top-level node (like "Favorites" , "Network", or "Recent"), then
   // the way it's populated will be special.

   int networkNode = _GetDialogInfo(ETDATA_NETWORK, p_window_id);
   int computerNode = _GetDialogInfo(ETDATA_MYCOMPUTER, p_window_id);
   int favesNode = _GetDialogInfo(ETDATA_FAVORITES, p_window_id);
   
   DirListObject_t dlo = _dlGetDirListObject();
   (*dlo.pfnViewSavePos)("_etBuildSelectedPath");

   _str path = "";
   _str dir = "";
   boolean keepGoing = true;
   while(keepGoing) {
      int nodeIndex = _TreeCurIndex();
      _str prevDir = dir;
      dir = _TreeGetCaption(nodeIndex);

      // Stop at the top-level "Network" node
      if(nodeIndex == networkNode) {
         keepGoing = false;
         // Make the UNC name complete with \\server\share
         path = FILESEP :+ FILESEP :+ path;
         continue;
      }

      // Shouldn't get here, since isdrive() should short-circuit this
      if(nodeIndex == computerNode) {
         keepGoing = false;
         continue;
      }

      // Favorites are expanded a little differently
      if(nodeIndex == favesNode) {
         keepGoing = false;
         _str faveName = prevDir;
         // Look up the favorite in the hashtable, and replace the value
         // with the expanded full path
         if (_fav_places._indexin(faveName))
         {
            path = substr(path, faveName._length() + 1);
            path = strip(path, "B", FILESEP);

            _str faveFullPath = _fav_places:[faveName];
            faveFullPath = strip(faveFullPath, "T", FILESEP);
            
            if( path :== "" ) {
               path = faveFullPath :+ FILESEP;
            }
            else {
               path = faveFullPath :+ FILESEP :+ path :+ FILESEP;
            }
         }
         continue;
      }

      if( dir != "" ) {
         if( last_char(dir)==FILESEP ) {
            path= (dir :+ path);
         } else {
            path= (dir :+ FILESEP :+ path);
         }

         if( isdrive(dir) ) {
            keepGoing = false;
         }
      }
      else{
         keepGoing = false;
         continue;
      }

      if( !(*dlo.pfnViewGotoParent)() ) {
         keepGoing = false;
      } 
   }

   // Special case for clicking/enter on just the NETWORK
   // top-level node.
   if( path :== "\\\\" ) {
      path = "";
   }

   if( (path != "") && (last_char(path) != FILESEP) ) {
      path = path :+ FILESEP;
   }

   (*dlo.pfnViewRestorePos)("_etBuildSelectedPath");
   return path;
}

/**
 * Expands the top-level "Network" list, to get a list of 
 * computers on the primary domain. Windows only.
 * 
 */
static void _etExpandNetwork(int networkNode = -1)
{
#if !__UNIX__
   // Do not expand if we've already populated the listing,
   // or if we don't have a network node
   if(networkNode < 0) {
      networkNode = _GetDialogInfo(ETDATA_NETWORK, p_window_id);
   }
   if(networkNode < 0) {
      return;
   }
   int childIdx = _TreeGetFirstChildIndex(networkNode);
   if(childIdx > 0) {
      // See if this first child item was automatically populated
      int nShowChildren, nBMIIndex;
      _TreeGetInfo(childIdx, nShowChildren, nBMIIndex);
      if( nBMIIndex == _pic_otb_server ) {
         return;
      }
   }

   // Get the listing of computers on the domain
   _str ComputerList[];
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   NTNetGetDomainComputers(temp_view_id);
   top();up();
   while ( !down() ) {
      get_line(auto line);
      ComputerList[ComputerList._length()]=strip(line);
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);

   _TreeBeginUpdate(networkNode, "T");
   int i;
   for ( i=0;i<ComputerList._length();++i ) {
      _TreeAddItem(networkNode,ComputerList[i],TREE_ADD_AS_CHILD,_pic_otb_server,_pic_otb_server,0);
   }
   _TreeEndUpdate(networkNode);
#endif
}

/**
 * Expands a computer name under the "Network" list, to get a
 * list of shares for the specified machine. The server node in 
 * question must be the current tree node. Windows only. 
 */
static void _etExpandNetworkComputerNode()
{
#if !__UNIX__
   // Do not expand if we've already populated the listing
   _str serverName = _TreeGetCurCaption();
   int serverIdx = _TreeCurIndex();

   int firstChild = _TreeGetFirstChildIndex(serverIdx);
   if(firstChild > 0) {
      return;
   }

   _str ShareList[];
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   NTNetGetComputerShares(temp_view_id, serverName);
   top();up();
   while ( !down() ) {
      get_line(auto line);
      ShareList[ShareList._length()]=strip(line);
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);

   _TreeBeginUpdate(serverIdx, "T");
   int i;
   for ( i=0;i<ShareList._length();++i ) {
      _TreeAddItem(serverIdx,ShareList[i],TREE_ADD_AS_CHILD,_pic_otb_share,_pic_otb_share,0);
   }
   _TreeEndUpdate(serverIdx);
#endif
}

/**
 * Fill in the sibling children directories for the path passed in under the current item.
 * <p>
 * IMPORTANT: <br>
 * Current window must be directory list control (e.g. list box, tree).
 *
 * @param parentPath Parent directory to use when filling in the directory list
 *                   control with sibling children.
 * @param showDotFiles whether or not to show UNIX dot files.
 *
 */
void _etpathChildren(_str parentPath, boolean showDotFiles=true)
{
   // TODO: Need to detect our "special" nodes. If this is the "Computer"
   // node, this is expanding to show the list of drives.
   // If it's another top-level node (like "Favorites" or "Recent"), then
   // the way it's populated will be special.
   // For this we'll need an "_etExpandSpecialFolder" method

   DirListObject_t dlo = _dlGetDirListObject();
   if( last_char(parentPath)==FILESEP ) {
      parentPath=substr(parentPath,1,length(parentPath)-1);
   }

   // Do a FILE-MATCH to get the directories under the current
   // working directory.
   _str match_dir = parentPath:+FILESEP;
   _str maybe_quoted_path = maybe_quote_filename(match_dir:+ALLFILES_RE);
   _str flagDotFiles = showDotFiles ? '+U +H' : '-U -H';
   _str dir = file_match(maybe_quoted_path' 'flagDotFiles' +X +D -P -V',1);
   boolean listingRootDir = ( maybe_quoted_path == FILESEP:+ALLFILES_RE );
   // Note:
   // We build a list of siblings, then add in case the callbacks want to do
   // find_first/find_next. Otherwise the callback's find_first/next would
   // stomp on our find_first/next.
   _str siblings[]; siblings._makeempty();
   for(;;) {
      if( dir=="" ) {
         break;
      }
      if( last_char(dir)==FILESEP && dir!=".":+FILESEP && dir!="..":+FILESEP ) {
         dir=substr(dir,1,length(dir)-1);
         dir=substr(dir,lastpos(FILESEP,dir)+1);
         if( dir!="." && dir!=".." ) {
            siblings[siblings._length()]=dir;
         }
      }
      maybe_quoted_path=maybe_quote_filename(match_dir:+ALLFILES_RE);
      dir=file_match(maybe_quoted_path' 'flagDotFiles' +X +D -P -V',0);
   }
   // Insert sibling children.
   // Save the position in the directory list because we will need to
   // sort the children under this node later.
   (*dlo.pfnViewSavePos)("parent");
   (*dlo.pfnViewDeleteChildren)();
   boolean first_sib_added = false;
   int i;
   for( i=0; i<siblings._length(); ++i ) {
      _str sibPath=parentPath:+FILESEP:+siblings[i];
      if( !first_sib_added ) {
         first_sib_added=(*dlo.pfnViewAddChildItem)(siblings[i],DLITEMTYPE_FOLDER_CLOSED,sibPath);
      } else {
         (*dlo.pfnViewAddSiblingItem)(siblings[i],DLITEMTYPE_FOLDER_CLOSED,sibPath);
      }
   }
   (*dlo.pfnViewRestorePos)("parent");
   if( first_sib_added ) {
      // Sort all the children we just inserted
      (*dlo.pfnViewSortChildren)();
   } else {
      // No children added, so make this a leaf node instead
      _str item;
      (*dlo.pfnViewGetItem)(item);
      (*dlo.pfnViewSetItem)(item,DLITEMTYPE_LEAF);
   }
   // TODO: Perhaps don't force the scrolling in all cases
   (*dlo.pfnViewAdjustScroll)();
}

_str _get_current_path(){
   return ( _dlGetPath() );
}

/**
 * Sets the callback that the explorer tree will invoke when a 
 * change/navigation in the tree requires the working directory 
 * to be changed. 
 * 
 * @param cb Address of callback function. 
 * Signature: void cbfunc(_str cwd)
 */
void _set_cwd_callback(pfnExpTreeCWDCallback_t cb){
   _SetDialogInfoHt("cwdcb",cb,p_window_id,true);
}

/**
 * Replace _dlpath() function when using the explorer tree. 
 * Similar behavior and function. 
 */
_str _set_current_path(_str newPath=null, 
             boolean doRefresh=false, 
             boolean show_dotfiles=true, 
             boolean doCd=true)
{
   if( newPath==null ) {
      return _get_current_path();
   }

   // Set path
   //
   typeless orig_path = _dlGetPath();
   _str param = newPath;
   if( param=="" ) {
      param=orig_path;
   }

   // Send CHANGE_PATH in an ON_CHANGE event if called with a specific path
   boolean do_changepath = ( param != "" );
   if( !doRefresh ) doCd = false;
   _dlSetPath(param,doCd);
   if( file_eq(_dlGetPath(),orig_path) && !doRefresh ) {
      return orig_path;
   }

   // Parse parts of path for display
   //
   _str currentPath = _dlGetPath();
   #if !__UNIX__
   if( (length(currentPath) > 3)  && (last_char(currentPath)==FILESEP) ) {
      currentPath=strip(currentPath, "T", FILESEP);
   }
   #endif
   #if __UNIX__
   if( last_char(currentPath)==FILESEP ) {
      currentPath=strip(currentPath, "T", FILESEP);
   }
   if( currentPath == "" ) {
      currentPath = "/";
   }
   #endif
   _select_path(currentPath);

   // Insert sibling children
   _etpathChildren(currentPath, show_dotfiles);

   //
   // Notify the directory list control that the current item has changed
   //

   if( do_changepath ) {
      call_event(CHANGE_PATH, 0, p_window_id,ON_CHANGE,'');
   }

   return ( _dlGetPath() );
}

void _select_path(_str newPath)
{
   //say('_select_path(newPath='newPath' )');
   _str drive_or_root = "";
   _str path = "";
   _dlParseParts(newPath,drive_or_root,path);
   //say('   drive is 'drive_or_root);
   //say('   path is 'path);

   // Display path heierarchy
   //
   DirListObject_t dlo = _dlGetDirListObject();

   // is the drive the currently active folder?
   int itemType = 0;
   if( file_eq(drive_or_root,_dlGetPath())) {
      itemType=DLITEMTYPE_FOLDER_AOPEN;
   } else {
      // no, just a regular open folder
      itemType=DLITEMTYPE_FOLDER_OPEN;
   }

   // Save the current index
   int currIdx = _TreeCurIndex();

   // Find the appropriate starting location, if available
   // If it's a drive letter, it goes under the "Computer" node
   // If it's a UNC path, it goes under the "Network" node
   // Stuff under the "Favorites" node is not addressable with this function
   int searchUnderIdx = _GetDialogInfo(ETDATA_MYCOMPUTER, p_window_id );
   _str first_item = drive_or_root;
   boolean isUNCName = false;
#if _NAME_HAS_DRIVE
   if (substr(drive_or_root,1,2)=='\\') {
      // Special case of \\server\sharename\.. . We do not want the trailing
      // backslash displayed (looks ugly). In this case, drive_or_root
      // may contain the *entire* path to be found
      parse newPath with (FILESEP) (FILESEP) first_item (FILESEP) path;
      isUNCName = true;
      searchUnderIdx = _GetDialogInfo(ETDATA_NETWORK, p_window_id );
   }
   else{
      // Trim off the trailing slash of a drive letter
      first_item=strip(drive_or_root, "T", FILESEP);
   }
#endif
   int driveRoot = _TreeSearch(searchUnderIdx, first_item, "I");
   if( driveRoot < 0 ) {
      // Add the drive or network name if not already in the list
      _TreeSetCurIndex(searchUnderIdx);
      (*dlo.pfnViewAddChildItem)(first_item,itemType,newPath);
   }
   else {
      _TreeSetCurIndex(driveRoot);
   }

   _str item = "";
   _str dir = "";
   while( path!="" ) {

      parse path with dir (FILESEP) path;

      if( path=="" ) {
         itemType=DLITEMTYPE_FOLDER_AOPEN;;
      } else {
         itemType=DLITEMTYPE_FOLDER_OPEN;;
      }
      item=dir;
      // See if the item already exists
      int currNode = _TreeCurIndex();
      int foundIdx = _TreeSearch(currNode, item);
      if( foundIdx > 0 ) {
         _TreeSetCurIndex(foundIdx);
      }
      else {
         (*dlo.pfnViewAddChildItem)(item,itemType,newPath);
      }
   }
}

#region Favorites management

#define EXPLORERTREE_FAVORITES_FILE 'etfaves.xml'
/** 
 * Adds an item to the user-defined favorite places
 * @param path Full directory path to be added to the favorites
 * @param doPrompt If true, display a prompt dialog to allow the 
 *                 user to pick a shorter "friendly name" for
 *                 the selected directory
 * 
 * @return boolean True, if a new place was added. May also 
 *         return true if the same place already exists, but is
 *         now given a different friendly name
 */
boolean _add_favorite_place(_str path, boolean doPrompt=true)
{
   if( path == null || path :== "" ) {
      return false;
   }

   _str friendlyName = strip(path, 'T', FILESEP);
   int lastSep = lastpos(FILESEP, friendlyName);
   if( lastSep > 0 && lastSep < friendlyName._length()) {
      friendlyName = substr(friendlyName, lastSep + 1);
   }
   if (doPrompt) {
      // Show dialog to ask user to give this a friendly name
      // By default the friendly name will be the full path
      int result = textBoxDialog("Add Favorite", // Form caption
                                 0,              // Flags
                                 0,              // Use default textbox width
                                 "",             // Help item
                                 "Ok,Cancel:_cancel\tFull path: " path, // Buttons and captions
                                 "",             // Retrieve Name
                                 "Short Name :" :+ friendlyName); // Input fields
      if (result==COMMAND_CANCELLED_RC) {
         return false;
      }
      friendlyName = _param1;
      if( friendlyName :== "" ) {
         return false;
      }
   }

   // Add to favorite places hash
   _fav_places:[friendlyName] = path;

   // Add to favorites storage
   _explorerTree_AddFavoriteToConfigFile(friendlyName, path);

   // Add to the tree
   _explorerTree_AddFavoriteToTree(friendlyName);
   return true;
}

/** 
 *  Adds the user-defined favorite to config storage (Currently:
 *  etfaves.xml in the config directory)
*/ 
static void _explorerTree_AddFavoriteToConfigFile(_str faveName, _str favePath){
   int xHandle = _explorerTree_OpenFavoritesConfigFile();
   if( xHandle >= 0 ) {
      // See if it's already defined. If so, just overwrite the @path attribute
      _str faveXpath = '//Favorite[@name="' :+ (faveName) :+ '"]';
      int faveIdx = _xmlcfg_find_simple(xHandle, faveXpath, TREE_ROOT_INDEX);
      if( faveIdx < 0 )
      {
         // Not yet defined. Add the new node.
         int docRoot = _xmlcfg_get_first_child(xHandle, TREE_ROOT_INDEX);
         if( docRoot > 0 ) {
            faveIdx = _xmlcfg_add(xHandle, docRoot, 'Favorite', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
            if( faveIdx > 0 ) {
               _xmlcfg_set_attribute(xHandle, faveIdx, 'name', faveName);
            }
         }
      }
      if( faveIdx > 0 ) {
         _str favePathEncoded = _explorerTree_EncodeFavoriteWithEnvVars(favePath);
         _xmlcfg_set_attribute(xHandle, faveIdx, 'path', favePathEncoded);
      }
      _xmlcfg_save(xHandle, -1, 0);
      _xmlcfg_close(xHandle);
   }
}

/**
 * Adds a user-defined favorite to the tree control
 */
static void _explorerTree_AddFavoriteToTree(_str faveName){
   int favesNode = _GetDialogInfo(ETDATA_FAVORITES, p_window_id);
   if( favesNode > 0 ) {
      int foundFave = _TreeSearch(favesNode, faveName, "I");
      if( foundFave > 0 ) {
         _TreeBeginUpdate(foundFave, "T");
         _TreeDelete(foundFave, "C");
         _TreeEndUpdate(foundFave);
      } else{
         _TreeAddItem(favesNode, faveName, TREE_ADD_AS_CHILD, _pic_fldclos12, _pic_fldclos12, 0);
      }
   }
}

/**
 * Removes an item from the user-defined favorite places
 * 
 * @param friendlyName 
 * 
 * @return boolean 
 */
boolean _remove_favorite_place(_str friendlyName, boolean doPrompt = false)
{
   boolean found = false;

   if (doPrompt) {
      _str res = _message_box("Remove favorite '"friendlyName"' ?","Remove Favorite", MB_YESNO|MB_ICONQUESTION);
      if( res == IDNO ) {
         return false;
      }
   }

   // Remove from the favorites cache
   if (_fav_places._indexin(friendlyName)) {
      _fav_places._deleteel(friendlyName);
      found = true;
   }
   if( found ) {
      // Remove from favorites storage (XML config file)
      _explorerTree_RemoveFavoriteFromConfigFile(friendlyName);
      // Remove from the tree control
      _explorerTree_RemoveFavoriteFromTree(friendlyName);
   }
   return found;
}

/** Removes the user-defined favorite from config storage
  (Currently: etfaves.xml in the config directory) 
*/ 
static void _explorerTree_RemoveFavoriteFromConfigFile(_str faveName){
   int xHandle = _explorerTree_OpenFavoritesConfigFile();
   if( xHandle >= 0 ) {
      // See if such a node is already defined
      _str faveXpath = '//Favorite[@name="' :+ (faveName) :+ '"]';
      int faveIdx = _xmlcfg_find_simple(xHandle, faveXpath, TREE_ROOT_INDEX);
      if( faveIdx > 0 ) {
         _xmlcfg_delete(xHandle, faveIdx);
         _xmlcfg_save(xHandle, -1, 0);
      }
      _xmlcfg_close(xHandle);
   }
}

/**
 * Removes a user-defined favorite from the tree control
 */
static void _explorerTree_RemoveFavoriteFromTree(_str faveName){
   int favesNode = _GetDialogInfo(ETDATA_FAVORITES, p_window_id);
   if( favesNode > 0 ) {
      int foundFave = _TreeSearch(favesNode, faveName, "I");
      if( foundFave > 0 ) {
         _TreeDelete(foundFave);
      }
   }
}

/**
 * Modifies a favorite path by substituting any portions that could be 
 * represented with common environment variables. 
 * 
 * @param directoryPath Absolute directory path to be stored in the favorites 
 *                      file.
 * @return Directory with portions replaced with %vars% 
 * @remarks This way the etfaves.xml is more usable if you move it from one 
 *          machine to another. More of your favorites will survive the move.
 */
static _str _explorerTree_EncodeFavoriteWithEnvVars(_str directoryPath){
   directoryPath = _encode_vsenvvars(directoryPath, false, false);
#if !__UNIX__
   directoryPath = _encode_env_root(directoryPath, false, "PROGRAMFILES", false);
   directoryPath = _encode_env_root(directoryPath, false, "SystemRoot", false);
   return _encode_env_root(directoryPath, false, "USERPROFILE", false);
#else
   return _encode_env_root(directoryPath, false, "HOME", false);
#endif
}

/**
 * Opens the etfaves.xml configuration file, or creates with 
 * some default values if not found in the config directory
 * @return Handle to the XML file
 */
static int _explorerTree_OpenFavoritesConfigFile()
{
   int openStatus = 0;
   _str config_file = _ConfigPath() :+ EXPLORERTREE_FAVORITES_FILE;
   int xml_handle = _xmlcfg_open(config_file, openStatus, VSXMLCFG_OPEN_REFCOUNT /*| VSXMLCFG_OPEN_ADD_ALL_PCDATA*/);
   // Create starter file if new
   if (xml_handle < 0 || openStatus < 0) {
      xml_handle = _xmlcfg_create(config_file, VSENCODING_UTF8, VSXMLCFG_CREATE_IF_EXISTS_CLEAR);
      if( xml_handle >= 0 ) {
         int docRoot = _xmlcfg_add(xml_handle, TREE_ROOT_INDEX, 'Favorites', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
         if(docRoot >= 0) {
            // Create the default favorite places
            #if !__UNIX__
            _str myDocs = '';
            ntGetSpecialFolderPath(myDocs, CSIDL_PERSONAL);
            if (myDocs != '') {
               _str myDocsEncoded = _explorerTree_EncodeFavoriteWithEnvVars(myDocs);
               int docsNode = _xmlcfg_add(xml_handle, docRoot, 'Favorite', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
               if( docsNode > 0 ) {
                  _xmlcfg_set_attribute(xml_handle, docsNode, 'name', 'Documents');
                  _xmlcfg_set_attribute(xml_handle, docsNode, 'path', myDocsEncoded);
               }
            }
            _str myDesktop ='';
            ntGetSpecialFolderPath(myDesktop, CSIDL_DESKTOP);
            if (myDesktop != '') {
               _str myDesktopEncoded = _explorerTree_EncodeFavoriteWithEnvVars(myDesktop);
               int desktopNode = _xmlcfg_add(xml_handle, docRoot, 'Favorite', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
               if( desktopNode > 0 ) {
                  _xmlcfg_set_attribute(xml_handle, desktopNode, 'name', 'Desktop');
                  _xmlcfg_set_attribute(xml_handle, desktopNode, 'path', myDesktopEncoded);
               }
            }
            _str myPublic ='';
            ntGetSpecialFolderPath(myPublic, CSIDL_COMMON_DOCUMENTS);
            if (myPublic != '') {
               _str myPublicEncoded = _explorerTree_EncodeFavoriteWithEnvVars(myPublic);
               int publicNode = _xmlcfg_add(xml_handle, docRoot, 'Favorite', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
               if( publicNode > 0 ) {
                  _xmlcfg_set_attribute(xml_handle, publicNode, 'name', 'Public');
                  _xmlcfg_set_attribute(xml_handle, publicNode, 'path', myPublicEncoded);
               }
            }
            #else
            _str homePath = get_env('HOME');
            if (homePath != '') {
               int homeNode = _xmlcfg_add(xml_handle, docRoot, 'Favorite', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
               if( homeNode > 0 ) {
                  _xmlcfg_set_attribute(xml_handle, homeNode, 'name', 'Home');
                  _xmlcfg_set_attribute(xml_handle, homeNode, 'path', '%HOME%');
               }
            }
            #endif
         }
         _xmlcfg_save(xml_handle, -1, 0/*, null, VSENCODING_UTF8*/);
      }
   }
   return xml_handle;
}

/**
 * Read favorites from config/storage if not already read
 */
static void _explorerTree_InitFavePlacesCache()
{
   if (_fav_places._isempty()) {
      int xHandle = _explorerTree_OpenFavoritesConfigFile();
      if( xHandle >= 0 ) {
         typeless faveNodes[];
         _xmlcfg_find_simple_array(xHandle, "//Favorite", faveNodes);
         foreach(auto idx in faveNodes)
         {
            _str name = _xmlcfg_get_attribute(xHandle, idx, 'name');
            _str path = _xmlcfg_get_attribute(xHandle, idx, 'path');
            if( path != "" && name != "" ) {
               _str pathDecoded = _replace_envvars(path);
               _fav_places:[name] = pathDecoded;
            }
         }
         _xmlcfg_close(xHandle);
      }
   }
}
#endregion

definit(){
   if (arg(1)!='L') {
      _fav_places._makeempty();
   }
}
