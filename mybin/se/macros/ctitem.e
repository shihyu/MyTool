////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#include "codetemplate.sh"
#import "codetemplate.e"
#import "main.e"
#import "stdprocs.e"
#endregion


//
// Item list eventtab
//

defeventtab _ctItemList_etab _inherit _ul2_tree;

/**
 * Add a template file to the item list.
 * 
 * @param filename Template filename (.setemplate).
 * 
 * @return true on success.
 */
static boolean _ctItemListAddTemplate(_str filename)
{
   if( _ctIsTemplateFile(filename) ) {
      ctTemplateDetails_t details; details._makeempty();
      int status = _ctTemplateGetTemplate(filename,&details,null);
      if( status!=0 ) {
         _str msg = "Error adding template \"":+filename:+"\". ":+get_message(status);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return false;
      }
      _str Name = details.Name;
      if( Name=="" ) {
         Name="<No Name>";
      }
      int SortOrder = details.SortOrder;
      int pic = _pic_file;
      // info=SortOrder|Name|filename
      // Store SortOrder number first, Name second so sorting works.
      // Store the full path to .setemplate file so we do not have to divine it later.
      _str info = SortOrder'|'Name'|'filename;
      _TreeAddItem(TREE_ROOT_INDEX,Name,TREE_ADD_AS_CHILD,pic,pic,-1,0,info);
      // All good
      return true;
   }
   // Not a template file
   return false;
}

/**
 * Indicate whether we are in the middle of an on_change event for the directory list.
 * Used to disallow recursion.
 * 
 * @param onoff 0 = Not in an on_change event. <br>
 *              1 = In an on_change event. <br>
 *              -1 = Return current value without setting.
 * 
 * @return Previous value. Current value if -1 specified.
 */
boolean _ctItemListInOnChange(int onoff=-1)
{
   typeless old_onoff = _GetDialogInfoHt("InOnChange",p_window_id,true);
   if( old_onoff == null ) {
      old_onoff = false;
   }
   if( onoff > -1 ) {
      _SetDialogInfoHt("InOnChange",( onoff != 0 ),p_window_id,true);
   }
   return old_onoff;
}

/**
 * List template items under path.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 * 
 * @param path Path containing template directories. A template directory is
 *             a directory containing a .setemplate file.
 */
void _ctItemListInit(_str path)
{
   boolean old_inOnChange = _ctItemListInOnChange(1);

   _TreeDelete(TREE_ROOT_INDEX,'C');

   if( path=="" ) {
      // Nothing to list
      _ctItemListInOnChange((int)old_inOnChange);
      return;
   }
   _maybe_append_filesep(path);

   // Recursively list all template files under path
   _str result = file_match(maybe_quote_filename(path:+"*":+CT_EXT)' +T -X -D +S -P -V',1);
   while( result!="" ) {
      _str filename = absolute(result,path);
      if( _ctIsTemplateFile(filename) ) {
         _ctItemListAddTemplate(filename);
      }
      result = file_match(maybe_quote_filename(path:+"*":+CT_EXT)' +T -X -D +S -P -V',0);
   }

   // Sort on SortOrder, Name
   _TreeSortUserInfo(TREE_ROOT_INDEX);
   _TreeTop();
   _ctItemListInOnChange((int)old_inOnChange);
   int index = _TreeCurIndex();
   //if( index>0 ) {
      call_event(CHANGE_SELECTED,index,p_window_id,ON_CHANGE,'w');
   //}
}

// Override me
void _ctItemList_etab.on_create(_str path="")
{
   _ctItemListInit(path);
}

// Override me
void _ctItemList_etab.on_change(int reason, int nodeIndex)
{
   if( _ctItemListInOnChange() ) {
      // Recursion not allowed!
      return;
   }
   boolean old_inOnChange = _ctItemListInOnChange(1);
   switch( reason ) {
   case CHANGE_SELECTED:
      break;
   case CHANGE_COLLAPSED:
      break;
   case CHANGE_EXPANDED:
      break;
   case CHANGE_LEAF_ENTER:
      break;
   }
   _ctItemListInOnChange((int)old_inOnChange);
}

/**
 * Test item list for current item. Optionally retreive current item in item list.
 * 
 * @param templateFilename (optional) (output). Template filename for current
 *                         item in item list.
 * @param itemName         (optional) (output). Item name. This is the caption
 *                         of the current item.
 * 
 * @return true if there is a current item in item list.
 */
boolean _ctItemListGetCurrentItem(_str& templateFilename=null, _str& itemName=null)
{
   int index = _TreeCurIndex();
   if( index<=0 ) {
      return false;
   }
   if( templateFilename!=null || itemName!=null ) {
      _str info = _TreeGetUserInfo(index);
      _str SortOrder, Name, filename;
      parse info with SortOrder'|'Name'|'filename;
      if( templateFilename!=null ) {
         templateFilename=filename;
      }
      if( itemName!=null ) {
         itemName=_TreeGetCaption(index);
      }
   }
   return true;
}

/**
 * Set the current item in the item list by item name (caption).
 * 
 * @param itemName
 * 
 * @return true on success.
 */
boolean _ctItemListSetCurrentItem(_str itemName)
{
   if( itemName==null || itemName=="" ) {
      _TreeTop();
      return true;
   }
   int index = _TreeSearch(TREE_ROOT_INDEX,itemName);
   if( index>0 ) {
      _TreeSetCurIndex(index);
      return true;
   }
   // Not found
   return false;
}
