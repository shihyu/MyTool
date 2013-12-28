////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47103 $
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
#import "dirtree.e"
#import "listbox.e"
#endregion


//
//    User level 2 inheritance for DIRECTORY LIST BOX
//

defeventtab _ul2_dirlist _inherit _ul2_listbox;

// Extra list box line spacing
#define PIC_SPACE_Y 45
// Indent for list box bitmap
#define PIC_INDENT_X 100
// Value by which to indent each icon in a file list dialog
#define INDENT_FLD 100
#define FIRST_INDENT_FLD 100

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

static boolean cbAddChildItem(_str item, int itemType, _str fullPath)
{
   int indent = FIRST_INDENT_FLD;
   if( p_Noflines>0 ) {
      _str citem;
      int cindent, cpic;
      _lbget_item(citem,cindent,cpic);
      indent = cindent + INDENT_FLD;
   }
   int pic = itemType2PicIndex(itemType);
   _lbadd_item(item,indent,pic);
   return true;
}

static boolean cbAddSiblingItem(_str item, int itemType, _str fullPath)
{
   int indent = FIRST_INDENT_FLD;
   if( p_Noflines>0 ) {
      // Not used
      _str citem;
      _str cpic;
      _lbget_item(citem,indent,cpic);
   }
   int pic = itemType2PicIndex(itemType);
   _lbadd_item(item,indent,pic);
   return true;
}

static void cbSavePos(_str id="")
{
   if( id=="" ) {
      id="unnamed_pos";
   }
   DirListObject_t dlo = _dlGetDirListObject();
   save_pos(auto p);
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
      restore_pos(p);
      //_dlSetDirListObject(dlo);
      //p_user2=dlo;
   }
}

static void cbClear()
{
   _lbclear();
}

static void cbSelectItem()
{
   _lbselect_line();
}

static void cbDeselectItem()
{
   _lbdeselect_line();
}

static void cbDeselectAll()
{
   _lbdeselect_all();
}

// Note:
// Only children at the same indent-level are sorted.
static void cbSortChildren()
{
   save_pos(auto p);

   if( !down() ) {
      _str item;
      int indent, pic;
      _lbget_item(item,indent,pic);
      int match_indent = indent;
      int start_line = p_line;
      while( !down() ) {
         _lbget_item(item,indent,pic);
         if( indent!=match_indent ) {
            up();
            break;
         }
      }
      if( p_line != start_line ) {
         _lbsort('i',start_line,p_line);
      }
   }

   restore_pos(p);
}

static void cbTop()
{
   _lbtop();
}

static void cbBottom()
{
   _lbbottom();
}

static boolean cbGotoParent()
{
   _str item;
   int indent, pic;
   _lbget_item(item,indent,pic);
   if( indent==FIRST_INDENT_FLD ) {
      // Already at the root
      return false;
   }
   search('^?':+indent-INDENT_FLD,'r-');
   return true;
}

static boolean cbGotoFirstChild()
{
   _str item;
   int indent, pic;
   _lbget_item(item,indent,pic);
   if( down() ) {
      // At bottom of directory list
      return false;
   }
   int parent_indent = indent;
   _lbget_item(item,indent,pic);
   if( indent==(parent_indent+INDENT_FLD) ) {
      return true;
   }
   // Failed to find first child
   up();
   return false;
}

static boolean cbGotoNextSibling()
{
   int orig_line = p_line;
   _str item;
   int sib_indent, pic;
   _lbget_item(item,sib_indent,pic);
   while( !down() ) {
      int indent;
      _lbget_item(item,indent,pic);
      if( indent==sib_indent ) {
         // Found a sibling
         return true;
      } else if( indent<sib_indent ) {
         // No longer under the parent
         break;
      }
   }
   // Failed to find sibling
   p_line=orig_line;
   return false;
}

static void cbGetItem(_str& item)
{
   // Not used
   int indent, pic;
   _lbget_item(item,indent,pic);
}

static void cbSetItem(_str item, int itemType)
{
   _str citem;
   int indent, cpic;
   _lbget_item(citem,indent,cpic);
   // Indent remains the same
   int pic = itemType2PicIndex(itemType);
   _lbset_item(item,indent,pic);
}

static void cbDeleteChildren()
{
   save_pos(auto p);

   if( !down() ) {
      _str item;
      int indent, pic;
      _lbget_item(item,indent,pic);
      int match_indent = indent;
      int start_line = p_line;
      int count = 1;
      while( !down() ) {
         _lbget_item(item,indent,pic);
         if( indent<match_indent ) {
            // Done
            up();
            break;
         }
         ++count;
      }
      p_line=start_line;
      while( count-- > 0 ) {
         _delete_line();
      }
   }

   restore_pos(p);
}

static void cbDeleteItem()
{
   cbDeleteChildren();
   _delete_line();
}

/**
 * Display the current line as the second row of the listbox if 
 * possible. This is purely aesthetic. 
 */
static void cbAdjustScroll()
{
   int current_line = p_line;
   if( current_line > 1 ) {
      p_line = current_line - 1;
      _lbline_to_top();
      p_line = current_line;
   }
}

/**
 * Initialize directory list box Directory List Object.
 * <p>
 * IMPORTANT: <br>
 * This must be called before anything else so that callbacks are registered
 * before an attempt is made to call them. Call this function early (e.g in
 * an ON_CREATE or ON_CREATE2 event).
 * <p>
 * IMPORTANT: <br>
 * Current window must be tree control.
 */
void _dirlistboxInit()
{
   // Initialize the DirectoryListObject with our directory list listbox callbacks
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

// _ul2_dirlist.ON_CREATE2
//
// Called if you have set user-level-2 inheritance on a control for a form.
// Directory list box is automatically populated with the current working directory.
//
// Note:
// If you do not want a directory automatically populated, then do not
// set p_eventtab2=_ul2_dirlist. Instead call _dirlistboxInit() to initialize
// the directory list box.
//
// Example:
// defeventtab form1;
// void list1.on_create()
// {
//    _dirlistboxInit();
// }
void _ul2_dirlist.on_create2()
{
   _dirtreeInit();
   //_dirlistboxInit();

   p_redraw=0;
   if (p_object==OI_LIST_BOX) {
      p_picture=_pic_fldclos;
      p_pic_space_y=PIC_SPACE_Y;
      p_pic_point_scale=8;
   }
   _dlpath("");
   p_redraw=1;
}

void _ul2_dirlist.enter,lbutton_double_click()
{
   mou_hour_glass(1);
   _str new_path = _dlBuildSelectedPath();
   _dlpath(new_path,1);
   //_lbselect_line();
   mou_hour_glass(0);
   // Reset the button press counting
   get_event('B');
}

#if 0
void _ul2_dirlist.on_got_focus()
{
   typeless was_selected = _lbisline_selected();
   _lbselect_line();
   if( !was_selected ) {
      call_event(CHANGE_SELECTED,p_window_id,ON_CHANGE,"");
   }
}

void _ul2_dirlist.on_lost_focus()
{

   typeless was_selected = _lbisline_selected();
   _lbdeselect_line();
   if( was_selected ) {
      call_event(CHANGE_SELECTED,p_window_id,ON_CHANGE,"");
   }

}#endif

#if 0
void _ul2_dirlist.\27-\255()
{
   _lbdeselect_line();
   _str key = last_event();
   typeless bp = point();
   save_pos(auto p);
   _end_line();
   int status = search(LB_PICTURE_RE:+key,'r@I'/*_fpos_case*/);
   if( status ) {
      _lbtop();
      status=search(LB_PICTURE_RE:+key,'r@I'/*_fpos_case*/);
   }
   //_lbdeselect_all();
   _lbselect_line();
   typeless bp2 = point();
   if( status || bp2==bp ) {
      restore_pos(p);
   } else {
      call_event(CHANGE_SELECTED,p_window_id,ON_CHANGE,"");
   }
}
#endif
