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
#pragma option(metadata,"dirlist.e")

/* SlickEdit PRIVATE API.
 * View-independent callbacks, objects and constants for a directory list.
 */

/** Open folder */
const DLITEMTYPE_FOLDER_OPEN=   0;
/** Active open folder */
const DLITEMTYPE_FOLDER_AOPEN=  1;
/** Closed folder */
const DLITEMTYPE_FOLDER_CLOSED= 2;
/** Leaf (no children) */
const DLITEMTYPE_LEAF=          3;

/**
 * Add item as child of current item in directory list view.
 * 
 * @param item     Text item to add.
 * @param itemType Item type. One of DLITEMTYPE_* constants.
 * @param fullPath Full path of directory item being added.
 * 
 * @return true if the child was added; false otherwise.
 */
typedef bool (*pfnDLViewAddChildItem_t)(_str item, int itemType, _str fullPath);

/**
 * Add item as sibling of current item in directory list view.
 * 
 * @param item Text item to add.
 * @param itemType Item type. One of DLITEMTYPE_* constants.
 * @param fullPath Full path of directory item being added.
 * 
 * @return true if the child was added; false otherwise.
 */
typedef bool (*pfnDLViewAddSiblingItem_t)(_str item, int itemType, _str fullPath);

/**
 * Save the current position in directory list view.
 */
typedef void (*pfnDLViewSavePos_t)(_str id);

/**
 * Restore position in directory list view from previously saved position.
 */
typedef void (*pfnDLViewRestorePos_t)(_str id);

/**
 * Clear the directory list view.
 */
typedef void (*pfnDLViewClear_t)();

/**
 * Select the current item in the directory list view.
 */
typedef void (*pfnDLViewSelectItem_t)();

/**
 * De-select the current item in the directory list view.
 */
typedef void (*pfnDLViewDeselectItem_t)();

/**
 * De-select all items in the directory list view.
 */
typedef void (*pfnDLViewDeselectAll_t)();

/**
 * Sort the children of the current item in the directory list view.
 */
typedef void (*pfnDLViewSortChildren_t)();

/**
 * Set cursor to top of directory list view.
 */
typedef void (*pfnDLViewTop_t)();

/**
 * Set cursor to bottom of directory list view.
 */
typedef void (*pfnDLViewBottom_t)();

/**
 * Set cursor to parent of current item.
 */
typedef bool (*pfnDLViewGotoParent_t)();

/**
 * Set cursor to first child of current item.
 */
typedef bool (*pfnDLViewGotoFirstChild_t)();

/**
 * Set cursor to next sibling of current item.
 */
typedef bool (*pfnDLViewGotoNextSibling_t)();

/**
 * Get current item text.
 */
typedef void (*pfnDLViewGetItem_t)(_str& item);

/**
 * Set current item text.
 */
typedef void (*pfnDLViewSetItem_t)(_str item, int itemType);

/**
 * Delete children of current item.
 */
typedef void (*pfnDLViewDeleteChildren_t)();

/**
 * Delete current item including all children.
 */
typedef void (*pfnDLViewDeleteItem_t)();

/**
 * Use this callback to adjust final scroll position of the current
 * item in directory list view.
 */
typedef void (*pfnDLViewAdjustScroll_t)();

/**
 * Directory List Object structure. This structure encapsulates the
 * callbacks and data necessary to implement the model and view for
 * a directory list.
 */
typedef struct {

   //
   // public:
   //

   pfnDLViewAddChildItem_t pfnViewAddChildItem;
   pfnDLViewAddSiblingItem_t pfnViewAddSiblingItem;
   pfnDLViewSavePos_t pfnViewSavePos;
   pfnDLViewRestorePos_t pfnViewRestorePos;
   pfnDLViewClear_t pfnViewClear;
   pfnDLViewSelectItem_t pfnViewSelectItem;
   pfnDLViewDeselectItem_t pfnViewDeselectItem;
   pfnDLViewDeselectAll_t pfnViewDeselectAll;
   pfnDLViewSortChildren_t pfnViewSortChildren;
   pfnDLViewTop_t pfnViewTop;
   pfnDLViewBottom_t pfnViewBottom;
   pfnDLViewGotoParent_t pfnViewGotoParent;
   pfnDLViewGotoFirstChild_t pfnViewGotoFirstChild;
   pfnDLViewGotoNextSibling_t pfnViewGotoNextSibling;
   pfnDLViewGetItem_t pfnViewGetItem;
   pfnDLViewSetItem_t pfnViewSetItem;
   pfnDLViewDeleteChildren_t pfnViewDeleteChildren;
   pfnDLViewDeleteItem_t pfnViewDeleteItem;
   pfnDLViewAdjustScroll_t pfnViewAdjustScroll;

   //
   // private:
   //

   // Current path
   _str path;
   // Arbitrary data specific to control used to implement display (e.g. listbox, tree)
   typeless ht:[];
   // Are we in an on-change event?
   // This is used by specific control used to implement display (e.g. listbox, tree)
   bool inOnChange;
} DirListObject_t;

