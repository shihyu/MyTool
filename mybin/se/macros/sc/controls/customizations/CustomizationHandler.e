////////////////////////////////////////////////////////////////////////////////////
// $Revision: 41923 $
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
#include "xml.sh"
#import "stdprocs.e"
#import "xmlcfg.e"
#require "Separator.e"
#require "UserModification.e"
#require "UserControl.e"
#endregion

namespace sc.controls.customizations;

#define LAST_ITEM_TEXT        'LAST_ITEM'                // how we designate the last item in a list
#define FIRST_ITEM_TEXT       'FIRST_ITEM'               // how we designate the first item in a list
#define LAST_ITEM_INDEX       -1                         // index of "last item"
#define FIRST_ITEM_INDEX      -2                         // index of "first item"
#define NOT_FOUND             -3                         // index of an item which is not found

#define MODIFICATION_LIST_ELEMENT   'Modifications'
#define MODIFICATION_ELEMENT        'Modification'
#define SEPARATOR_LIST_ELEMENT      'Separators'
#define SEPARATOR_ELEMENT           'Separator'
#define DUPLICATE_LIST_ELEMENT      'Duplicates'
#define DUPLICATE_ELEMENT           'Duplicate'


class CustomizationHandler {

   protected _str m_modFile = '';
   protected _str m_elementName = '';
   protected _str m_categoryName = '';

   CustomizationHandler() { }

   /**
    * Opens or optionally creates a file to contain user modifications. 
    * 
    * @param create           whether to create the file if it does not already 
    *                         exist
    * 
    * @return                 xml handle to file, 0 if file does not exist and was 
    *                         not created
    */
   protected int openModFile(boolean create = true)
   {
      xmlHandle := 0;
      if (!file_exists(m_modFile) && create) {
         xmlHandle = _xmlcfg_create(m_modFile, VSENCODING_UTF8);
         _xmlcfg_add(xmlHandle, TREE_ROOT_INDEX, 'xml version="1.0" encoding="UTF-8"', 
                     VSXMLCFG_NODE_XML_DECLARATION, VSXMLCFG_ADD_AS_CHILD);
      } else {
         xmlHandle = _xmlcfg_open(m_modFile, VSENCODING_UTF8);
      }
   
      return xmlHandle;
   }
   
   /**
    * Retrieves or optionally creates an XML category for user modifications. 
    * 
    * 
    * @param xmlHandle        xml handle to file
    * @param title            title of category to find/create
    * @param create           whether to create the category if it does not already 
    *                         exist
    * 
    * @return                 index of category, < 0 if categorey does not exist 
    *                         and was not created
    */
   protected int getModCategory(int xmlHandle, boolean create = true)
   {
      categoryNode := _xmlcfg_find_simple(xmlHandle, '//'m_categoryName);
      if (categoryNode < 0 && create) {
         categoryNode = _xmlcfg_add(xmlHandle, TREE_ROOT_INDEX, m_categoryName, 
                                    VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      }
   
      return categoryNode;
   }
   
   /**
    * Retrieves or optionally creates a modification item in the xml file.  If the 
    * node exists, it is deleted. 
    * 
    * 
    * @param xmlHandle           xml handle to file
    * @param categoryNode        index of category containing mod nodes
    * @param title               element name
    * @param name                modification name
    * @param create              whether to create the node if it does not already 
    *                            exist
    * 
    * @return                    index of mod node, < 0 if node does not exist and 
    *                            was not created
    */
   protected int getModItem(int xmlHandle, int categoryNode, _str name, boolean create = true)
   {
      node := _xmlcfg_find_simple(xmlHandle, "//"m_elementName"[@Name='"name"']", categoryNode);
      if (node < 0 && create) {
         node = _xmlcfg_add(xmlHandle, categoryNode, m_elementName, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_add_attribute(xmlHandle, node, 'Name', name);
      } else if (node > 0) {
         _xmlcfg_delete(xmlHandle, node, true);
      }
   
      return node;
   }
   
   /**
    * Compares a default menu or toolbar configuration to the current one.  Creates 
    * a list of modifications. 
    * 
    * 
    * @param callbackKey            key to use to find callbacks for comparing
    * @param curList                current configuration
    * @param origList               original configuration
    * @param mods                   list of mods      
    */
   protected void compareControlLists(typeless (&curList)[], typeless (&origList)[], typeless (&mods)[])
   {
      origIndex := 0;
      curIndex := 0;
   
      UserModification removeMods[];
      UserModification tempMods[];

      while ((origIndex < origList._length() || curIndex < curList._length())) {
         // get the items from each list
         UserControl origItem = null;
         UserControl curItem = null;
         if (origIndex < origList._length()) origItem = origList[origIndex];
         if (curIndex < curList._length()) curItem = curList[curIndex];
         
         // see if they match
         if (origItem != null && curItem != null && compareIdentifiers(origItem, curItem)) {
            // we do need to check for changes to the details
            typeless mod = compareNonIdentifiers(origItem, curItem);
            if (mod != null) mods[mods._length()] = mod;
   
            // advance both iterators
            origIndex++;
            curIndex++;
         } else {
   
            // see if the items exist in the other lists
            origIndexInCurrent := NOT_FOUND;
            if (origItem != null) origIndexInCurrent = findItemInList(origItem, curList);
            curIndexInOrig := NOT_FOUND;
            if (curItem != null) curIndexInOrig = findItemInList(curItem, origList);
   
            // now we have a table
            typeless mod;
            if (origIndexInCurrent >= 0 && curIndexInOrig >= 0) {
               // both of these items aren't really where they were before...

               origMovement := origIndexInCurrent - origIndex;
               curMovement := curIndexInOrig - curIndex;

               // create one for the item in the current list
               if (curMovement > 0 && curMovement >= origMovement) {
                  mod = createChangeMod(curList, curIndex);
                  if (mod != null) tempMods[curIndex] = mod;

                  curIndex++;
               } else if (curIndexInOrig < origIndex) {
                  // since this item was found earlier in the list, we have already handled it
                  curIndex++;
               }

               // create one for the item in the original list
               if (origMovement > 0 && origMovement >= curMovement &&
                   !(origMovement == curMovement && origMovement == 1)) {

                  mod = createChangeMod(curList, origIndexInCurrent);
                  if (mod != null) tempMods[origIndexInCurrent] = mod;

                  origIndex++;
               } else if (origIndexInCurrent < curIndex) {
                  // since this item was found earlier in the list, we have already handled it
                  origIndex++;
               }

            } else {
               if (curItem != null) {
                  if (curIndexInOrig < 0) {
                     // not in the original, but it's here now - must have been added
                     mod = createAddMod(curList, curIndex);
                     if (mod != null) {
                        tempMods[curIndex] = mod;
                     }
                     
                     curIndex++;
                  } else if (curIndexInOrig < origIndex) {
                     // since this item was found earlier in the list, we have already handled it
                     curIndex++;
                  }
               }

               if (origItem != null) {
                  if (origIndexInCurrent < 0) {
                     // this item was removed.  poof!
                     mod = createRemoveMod(origList, origIndex);
                     if (mod != null) removeMods[removeMods._length()] = mod;
   
                     origIndex++;
                  } else if (origIndexInCurrent < curIndex) {
                     // since this item was found earlier in the list, we have already handled it
                     origIndex++;
                  }
               }
            }
         }
      }

      // now we organize the mods so that the removes are at the front, and 
      // everything is in order of its order in the list
      UserModification mod;
      foreach (mod in removeMods) {
         mods[mods._length()] = mod;
      }
      foreach (mod in tempMods) {
         if (mod != null) mods[mods._length()] = mod;            
      }
   }
   
   /**
    * Compares a pair of UserControls to see if their identifiers match. 
    * Identifiers vary depending on what kind of UserControl is in use.  This 
    * function should be overwritten. 
    * 
    * @param origItem         default item
    * @param curItem          current item
    * 
    * @return                 true if their identifiers match, false otherwise
    */
   protected boolean compareIdentifiers(UserControl &origItem, UserControl &curItem)
   {
      if (origItem == null && curItem == null) {
         // this should really never happen...
      } else if (origItem == null || curItem == null) {
         // only one of them is null?
         return false;
      } else {
         // see if they match
         return (origItem.getIdentifier() == curItem.getIdentifier());
      }

      return false;
   }

   /**
    * Compares a pair of UserControls to see if their non-identifying members
    * match.  This function should be overwritten.
    * 
    * @param origItem         default item
    * @param curItem          current item
    * 
    * @return                 UserModification object populated with changes 
    *                         differences between items
    */
   protected UserModification compareNonIdentifiers(UserControl &origItem, UserControl &curItem)
   {
      return null;
   }

   /**
    * Finds a UserControl in a list of UserControls.  This function should be 
    * overwritten. 
    * 
    * @param item          UserControl being sought
    * @param list          list of UserControls
    * 
    * @return              index in list of UserControl
    */
   protected int findItemInList(UserControl &item, UserControl (&list)[], int startIndex = 0, int endIndex = -1)
   {
      if (item == null || item.getIdentifier() == '') return NOT_FOUND;
      id := item.getIdentifier();

      return findIdInList(id, list, startIndex, endIndex);
   }

   /**
    * Finds a control identifier in a list of UserControls.  This function should 
    * be overwritten. 
    * 
    * @param item          UserControl being sought
    * @param list          list of UserControls
    * 
    * @return              index in list of UserControl
    */
   protected int findIdInList(_str id, UserControl (&list)[], int startIndex = 0, int endIndex = -1)
   {
      if (id == null || id == '') return NOT_FOUND;
      if (list == null || list._isempty()) return NOT_FOUND;

      listLength := list._length();
      checkStartEndValues(listLength, startIndex, endIndex);

      // check to see if it might be the first or last item
      index := checkForFirstAndLast(id, listLength, startIndex, endIndex);
      if (index < 0) return index;

      // now go through them all
      for (i := startIndex; i <= endIndex; i++) {
         if (list[i].getIdentifier() == id) return i;
      }
   
      return NOT_FOUND;
   }

   /**
    * Makes sure that the startIndex and endIndex values sent to 
    * findIdInList (or similar function) make sense. 
    * 
    * @param listLength             length of list we are searching
    * @param startIndex             starting index of our search
    * @param endIndex               ending index of our search
    */
   protected void checkStartEndValues(int listLength, int& startIndex, int& endIndex)
   {
      // if no startIndex was sent, then just use the first thing
      if (startIndex < 0/* || startIndex >= listLength*/) startIndex = 0;

      // if no endIndex was sent OR if it's past the end of the list, 
      // just go to the end of the list
      if (endIndex == -1 || endIndex >= listLength) endIndex = listLength - 1;
   }

   /**
    * Checks for a first item or last item when searching for an 
    * item in a list (like findIdInList or similar).  This only 
    * checks for the FIRST_ITEM_TEXT and LAST_ITEM_TEXT.  If the id 
    * is neither of those values, then 0 will be returned and the 
    * full list should be searched for a match. 
    * 
    * @param id                     id we are searching for
    * @param listLength             length of list
    * @param startIndex             starting index of our search
    * @param endIndex               ending index of our search
    * 
    * @return int                   negative value if we found the 
    *                               answer, 0 if we should search
    *                               through the list itself
    */
   protected int checkForFirstAndLast(_str id, int listLength, int startIndex, int endIndex)
   {
      // check for these guys
      if (id == FIRST_ITEM_TEXT) {
         if (startIndex <= 0) {
            return FIRST_ITEM_INDEX;
         } else return NOT_FOUND;
      }
      if (id == LAST_ITEM_TEXT) {
         if (endIndex == listLength - 1) {
            return LAST_ITEM_INDEX;
         } else return NOT_FOUND;
      }

      return 0;
   }

   /**
    * Creates a UserModification appropriate for the removal of the given 
    * item.  This function should be overwritten. 
    * 
    * @param list             list of UserControls
    * @param index            index of UserControl that we are interested in
    * 
    * @return                 UserModification object detailing removal
    */
   protected UserModification createChangeMod(UserControl (&list)[], int index)
   {
      return null;
   }

   /**
    * Creates a UserModification appropriate for the addition of the given 
    * item.  This function should be overwritten. 
    * 
    * @param list             list of UserControls
    * @param index            index of UserControl that we are interested in
    * 
    * @return                 UserModification object detailing addition
    */
   protected UserModification createAddMod(UserControl (&list)[], int index)
   {
      return null;
   }

   /**
    * Creates a UserModification appropriate for the changing of the given 
    * item.  This function should be overwritten. 
    * 
    * @param list             list of UserControls
    * @param index            index of UserControl that we are interested in
    * 
    * @return                 UserModification object detailing changes
    */
   protected UserModification createRemoveMod(UserControl (&list)[], int index)
   {
      return null;
   }

   /**
    * Creates a UserModification appropriate for the adding in a UserControl 
    * that has the same identifier as a UserControl that occurred earlier in our 
    * list. 
    * 
    * @param list             list of UserControls
    * @param index            index of UserControl that we are interested in
    * 
    * @return                 UserModification object detailing duplicated 
    *                         control
    */
   protected UserModification createDupeMod(UserControl (&list)[], int index)
   {
      UserModification um = createChangeMod(list, index);
      um.setAction(MA_DUPE);

      return um;
   }

   /**
    * Given a "previous" and "next" item used to find an insertion point in a 
    * list, finds the before and after. 
    *  
    * This method can be overridden. 
    * 
    * @param prevItem               first item to find
    * @param nextItem               next item to find, must be found after the 
    *                               first one
    * @param list                   list to search
    * @param prevIndex              index of prevItem
    * @param nextIndex              index of nextItem
    * @param findAfter              where to start looking for prevItem
    */
   protected void findPrevAndNextItems(_str prevItem, _str nextItem, typeless (&list)[], int& prevIndex, int&nextIndex, int findAfter = -1)
   {
      prevIndex = findIdInList(prevItem, list, findAfter);
      nextIndex = findIdInList(nextItem, list, prevIndex == NOT_FOUND ? findAfter : prevIndex + 1);
   }

   /**
    * Determines where an item should be entered in a list.
    * 
    * @param prevItem               item that should come directly before our 
    *                               item
    * @param nextItem               item that should come directly after our 
    *                               item
    * @param list                   list where item will be inserted
    * @param strict                 Whether we want strict positioning - that 
    *                               is, prevItem must be right before nextItem
    *                               in the list.  If strict is off, we will try
    *                               to find either prevItem or nextItem and go
    *                               by that (priority to prevItem).  Since
    *                               sometimes the list is still being changed,
    *                               we cannot always ensure that we will find
    *                               both surrounding items.
    * 
    * @return int                   index where item should be inserted, 
    *                               NOT_FOUND if nothing could be determined
    */
   protected int determineItemPosition(_str prevItem, _str nextItem, typeless (&list)[], boolean strict)
   {
      newPos := NOT_FOUND;
      findAfter := -1;
      listLength := list._length();

      // go looking for the previous and next items
      int prevIndex, nextIndex;
      findPrevAndNextItems(prevItem, nextItem, list, prevIndex, nextIndex, findAfter);

      firstNonStrictPos := NOT_FOUND;

      // we might have several possible positions to look at
      while (prevIndex != NOT_FOUND || nextIndex != NOT_FOUND) {

         // we try this twice - once with strict settings, once without
         strictPos := determinePositionFromSurroundingPositions(prevIndex, nextIndex, listLength, true);
         nonStrictPos := determinePositionFromSurroundingPositions(prevIndex, nextIndex, listLength, false);

         if (strictPos != NOT_FOUND) {
            // if we found a strict match, then we want to just use that
            newPos = strictPos;
         } else if (nonStrictPos != NOT_FOUND && firstNonStrictPos == NOT_FOUND) {
            // we found a non-strict match, so save it in case we can't find a strict one
            firstNonStrictPos = nonStrictPos;
         }

         // if we have not set the new position, then keep trying
         if (newPos != NOT_FOUND) break;

         // this didn't work, so find the next kind
         if (prevIndex == FIRST_ITEM_INDEX) {
            findAfter = 1;
         } else if (prevIndex == LAST_ITEM_INDEX) {
            findAfter = listLength - 1;
         } else {
            findAfter = prevIndex + 1;
         }
         findPrevAndNextItems(prevItem, nextItem, list, prevIndex, nextIndex, findAfter);

         // if we have found a non-strict match and either of the surrounding 
         // items is NOT_FOUND, then we know we cannot get a strict match, so quit now
         if ((prevIndex == NOT_FOUND || nextIndex == NOT_FOUND) && firstNonStrictPos != NOT_FOUND) break;
      }

      // we have gotten all the way here with nothing
      if (newPos == NOT_FOUND && !strict && firstNonStrictPos != NOT_FOUND) {
         // we can use the non-strict match anyway
         newPos = firstNonStrictPos;
      }

      return newPos;
   }

   /**
    * Given a beforeIndex and an afterIndex, determines the position of a 
    * new item.  Since we are often working with a partial list, we cannot 
    * always just stick something between the between the before and after 
    * indices. 
    * 
    * @param beforeIndex               index of item found before the new item 
    * @param afterIndex                index of item found after the new item
    * @param listLength                length of list (currently)
    * @param strict                    whether we require the new item to be 
    *                                  exactly between the before and after
    *                                  items or if we allow only a partial match
    *                                  due to the list being in-progress.
    *    
    * @return int                      index where new item should be inserted, 
    *                                  NOT_FOUND if not index is determined
    */
   protected int determinePositionFromSurroundingPositions(int beforeIndex, int afterIndex, int listLength, boolean strict)
   {
      newPos := NOT_FOUND;

      if (beforeIndex == FIRST_ITEM_INDEX) {
         // item is the first item in the list
         if (!strict || 
             afterIndex == 0 ||
             (afterIndex == LAST_ITEM_INDEX && listLength == 0)) {
            newPos = 0;
         }
      } else if (afterIndex == LAST_ITEM_INDEX) {
         // item is the last item in the list
         if (!strict || beforeIndex == listLength - 1) {
            newPos = listLength;
         }
      } else if (beforeIndex >= 0) {
         // item is somewhere in the middle
         if (!strict || afterIndex == beforeIndex + 1) {
            newPos = beforeIndex + 1;
         }
      } else if (afterIndex >= 0) {
         // this really only applies to non-strict searches, as other 
         // ones would have been caught by the previous if-block
         if (!strict || beforeIndex == afterIndex - 1) {
            newPos = afterIndex;
         }
      }

      return newPos;
   }

   /**
    * Locates a UserControl with the given caption in a list of UserControls. 
    * Can also handle FIRST_ITEM_TEXT and LAST_ITEM_TEXT as the caption 
    * parameter. 
    * 
    * @param command          caption that we seek
    * @param list             list of UserControls to check
    * 
    * @return                 index of UserControl with caption, NOT_FOUND if 
    *                         no such UserControl exists in this list
    */
   protected int findCaptionInList(_str caption, UserControl (&list)[])
   {
      if (caption == null || caption == '') return NOT_FOUND;
   
      caption = stranslate(caption, '', '&');
   
      if (caption == FIRST_ITEM_TEXT) return FIRST_ITEM_INDEX;
      if (caption == LAST_ITEM_TEXT) return LAST_ITEM_INDEX;
   
      for (i := 0; i < list._length(); i++) {
         if (stranslate(list[i].getCaption(), '', '&') == caption) return i;
      }
   
      return NOT_FOUND;
   }

   /**
    * Given an index into a UserControl list, retrieves the identifying text of 
    * the next item in the list.  If the item is the last one in the list, then 
    * LAST_ITEM_TEXT will be returned.  This function should be overwritten. 
    * 
    * @param controlList         list of UserControls
    * @param index               index of current item - we want identifier of 
    *                            next one
    * 
    * @return                    identifer of next item
    */
   protected _str getNextIdentifier(UserControl (&controlList)[], int index)
   {
      index++;
      if (index < controlList._length()) {
         return controlList[index].getIdentifier();
      }

      return LAST_ITEM_TEXT;
   }

   /**
    * Given an index into a UserControl list, retrieves the identifying text of 
    * the previous item in the list.  If the item is the first one in the list, 
    * then FIRST_ITEM_TEXT will be returned.  This function should be 
    * overwritten. 
    * 
    * @param controlList         list of UserControls
    * @param index               index of current item - we want identifier of 
    *                            previous one
    * 
    * @return                    identifer of previous item
    */
   protected _str getPrevIdentifier(UserControl (&controlList)[], int index)
   {
      index--;
      if (index >= 0) {
         return controlList[index].getIdentifier();
      }

      return FIRST_ITEM_TEXT;
   }

   /**
    * Removes a toolbar or menu (and any modifications) from the XML file.  
    * 
    * @param xmlHandle              xml file handle
    * @param categoryNode           category 
    * @param itemName               element name to search for 
    * @param tbName                 name of toolbar that we seek
    * 
    * @return                       whether anything was deleted
    */
   protected boolean removeMods(int xmlHandle, int categoryNode, _str name)
   {
      if (xmlHandle > 0 && categoryNode > 0) {
         // find this menu and purge it
         tbNode := getModItem(xmlHandle, categoryNode, name, false);
         if (tbNode > 0) {
            _xmlcfg_delete(xmlHandle, tbNode);
            return true;
         }
      }
   
      return false;
   }

   /**
    * Writes all modifications to an xml file.
    * 
    * 
    * @param xmlHandle        xml handle to file
    * @param node             parent node of these modifications
    * @param mods             list of mods to write
    */
   protected void writeMods(int xmlHandle, int node, typeless (&mods)[])
   {
      // create a category that will contain all our modifications
      modsCatNode := _xmlcfg_add(xmlHandle, node, MODIFICATION_LIST_ELEMENT, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   
      // now write each one
      typeless mod;
      foreach (mod in mods) {
         modNode := _xmlcfg_add(xmlHandle, modsCatNode, MODIFICATION_ELEMENT, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         writeMod(xmlHandle, modNode, mod);
      }
   }
   
   /**
    * Writes a single UserModification to an xml file.  The node should be 
    * already created.  This writes the member variables as attributes. 
    * 
    * @param xmlHandle           xml handle to file
    * @param node                modification node
    * @param mod                 UserModification we wish to write
    */
   protected void writeMod(int xmlHandle, int node, UserModification &mod)
   {
      value := mod.getCommand();
      if (value != null && value != '') _xmlcfg_add_attribute(xmlHandle, node, 'Command', value);
      value = mod.getCaption();
      if (value != null && value != '') _xmlcfg_add_attribute(xmlHandle, node, 'Caption', value);
      value = mod.getAction();
      if (value != null && value != '') _xmlcfg_add_attribute(xmlHandle, node, 'Action', value);
      value = mod.getMessage();
      if (value != null && value != '') _xmlcfg_add_attribute(xmlHandle, node, 'Message', value);
      value = mod.getPrev();
      if (value != null && value != '') _xmlcfg_add_attribute(xmlHandle, node, 'Prev', value);
      value = mod.getNext();
      if (value != null && value != '') _xmlcfg_add_attribute(xmlHandle, node, 'Next', value);
   }
   
   /**
    * Writes out the list of separators for a modified menu or toolbar.
    * 
    * 
    * @param xmlHandle        xml handle to file
    * @param node             parent node of separator category
    * @param seps             list of separators
    */
   protected void writeSeparators(int xmlHandle, int node, Separator (&seps)[])
   {
      if (seps._length() == 0) return;
   
      sepsCatNode := _xmlcfg_add(xmlHandle, node, SEPARATOR_LIST_ELEMENT, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   
      Separator sep;
      foreach (sep in seps) {
         writeSeparator(xmlHandle, sepsCatNode, sep);
      }
   }

   /**
    * Writes out one Separator.  May be overwritten to write out 
    * specific kind of Separator. 
    * 
    * @param xmlHandle        handle of xml file
    * @param sepsCatNode      category of separators - parent of 
    *                         new node
    * @param sep              separator to write
    *  
    * @return                 xml node of written separator
    */
   protected int writeSeparator(int xmlHandle, int sepsCatNode, Separator &sep)
   {
      sepNode := _xmlcfg_add(xmlHandle, sepsCatNode, SEPARATOR_ELEMENT, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(xmlHandle, sepNode, 'ItemBefore', sep.getPrevItem());
      _xmlcfg_add_attribute(xmlHandle, sepNode, 'ItemAfter', sep.getNextItem());

      return sepNode;
   }
   
   /**
    * Reads and applies changes from the standard control file found in the 
    * configuration directory. 
    */
   public void restoreChanges()
   {
      xmlHandle := openModFile(false);
      if (xmlHandle > 0) {
         readAndApplyFileChanges(xmlHandle);
         _xmlcfg_close(xmlHandle);
      }

   }

   /**
    * Reads and applies changes found in a specified file.
    * 
    * @param file                   name of file where changes can be found
    */
   public void importChanges(_str file)
   {
      // first open up our file
      importHandle := _xmlcfg_open(file, VSENCODING_UTF8);
      if (importHandle > 0) {
         // now send this off to be read and applied
         readAndApplyFileChanges(importHandle);

         // now we have to merge these changes with any existing changes
         origHandle := openModFile(false);
         if (origHandle > 0) {
            origCategoryNode := getModCategory(origHandle, false);
            importCategoryNode := getModCategory(importHandle, false);

            if (origCategoryNode > 0 && importCategoryNode > 0) {
               
               // go through each control individually
               importNode := _xmlcfg_get_first_child(importHandle, importCategoryNode);
               while (importNode > 0) {
                  name := _xmlcfg_get_attribute(importHandle, importNode, 'Name');

                  // see if we can find this in the original file
                  ss := "//"m_elementName"[@Name='"name"']";
                  origNode := _xmlcfg_find_simple(origHandle, ss, origCategoryNode);
                  if (origNode > 0) {
                     // clear it out, we want to only save the imported stuff
                     _xmlcfg_delete(origHandle, origNode, true);
                     _xmlcfg_copy(origHandle, origNode, importHandle, importNode, VSXMLCFG_COPY_CHILDREN);
                  } else {
                     // create a new node to put this information
                     _xmlcfg_copy(origHandle, origCategoryNode, importHandle, importNode, VSXMLCFG_COPY_AS_CHILD);
                  }

                  // now to the next set
                  importNode = _xmlcfg_get_next_sibling(importHandle, importNode);
               }

               _xmlcfg_save(origHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
            }

            _xmlcfg_close(origHandle);
         } else {
            copy_file(file, m_modFile);
         }

         _xmlcfg_close(importHandle);
      }
   }

   /**
    * Reads a file of modifications for controls and then applies them. 
    *  
    * @param xmlHandle              handle to xml file containing modifications 
    */
   private void readAndApplyFileChanges(int xmlHandle)
   {
      if (xmlHandle < 0) return;

      categoryNode := getModCategory(xmlHandle, false);

      if (categoryNode > 0) {

         mou_hour_glass(1);

         // go through each control individually
         node := _xmlcfg_get_first_child(xmlHandle, categoryNode);
         while (node > 0) {
            name := _xmlcfg_get_attribute(xmlHandle, node, 'Name');

            // read in the control and the separators
            UserModification mods[];
            Separator seps[];
            UserModification dupes[];
            readMods(xmlHandle, node, mods, seps, dupes);

            // now apply everything so this matches
            applyMods(name, mods, seps, dupes);

            node = _xmlcfg_get_next_sibling(xmlHandle, node);
         }

         mou_hour_glass(0);
      }
   }

   /**
    * Takes a list of modifications and a list of separators and applies them to 
    * the given control. Should be overwritten by inherited classes.
    * 
    * @param name             name of control to affect
    * @param mods             list of mods to apply
    * @param seps             list of separators that should be in the control
    */
   protected void applyMods(_str name, UserModification (&mods)[], Separator (&seps)[], UserModification (&dupes)[])
   {
   }

   /**
    * Reads a list of separators into an array.
    * 
    * 
    * @param xmlHandle           xml handle to file
    * @param node                node which may or may not contain a list of 
    *                            separators
    * @param seps                array which will be loaded with separators from 
    *                            xml
    */
   protected void readSeparators(int xmlHandle, int node, Separator (&seps)[])
   {
      sepsCatNode := _xmlcfg_find_child_with_name(xmlHandle, node, SEPARATOR_LIST_ELEMENT);
      if (sepsCatNode > 0) {
         sepNode := _xmlcfg_get_first_child(xmlHandle, sepsCatNode);
         while (sepNode > 0) {
            readSeparator(xmlHandle, sepNode, auto sep);
            seps[seps._length()] = sep;
   
            sepNode = _xmlcfg_get_next_sibling(xmlHandle, sepNode);
         }
      }
   }
   
   /**
    * Reads a single separator from the xml file.
    * 
    * @param xmlHandle           handle of xml file
    * @param sepNode             node containing separator info
    * @param sep                 Separator 
    */
   protected void readSeparator(int xmlHandle, int sepNode, Separator &sep)
   {
      sep.setPrevItem(_xmlcfg_get_attribute(xmlHandle, sepNode, 'ItemBefore'));
      sep.setNextItem(_xmlcfg_get_attribute(xmlHandle, sepNode, 'ItemAfter'));
   }

   /**
    * Reads the list of modifications, including the separators.
    * 
    * @param xmlHandle           handle of xml file
    * @param node                node containing modifications and separators
    * @param mods                array of mods to be populated
    * @param seps                array of separators to be populated
    */
   protected void readMods(int xmlHandle, int node, UserModification (&mods)[], Separator (&seps)[], UserModification (&dupes)[])
   {
      // read our list of modifications
      readModList(xmlHandle, node, MODIFICATION_LIST_ELEMENT, mods);
   
      // find the separators
      readSeparators(xmlHandle, node, seps);

      // and now the duplicates - which is just a list of mods, really
      readModList(xmlHandle, node, DUPLICATE_LIST_ELEMENT, dupes);
   }

   /**
    * Reads the list of modifications.  Both Modifications and Duplicates are 
    * written as Modifications. 
    * 
    * @param xmlHandle           handle of xml file
    * @param node                node containing modifications
    * @param listElementName     name of element containing each modification
    * @param mods                list to be filled with modifications
    */
   protected void readModList(int xmlHandle, int node, _str listElementName, UserModification (&mods)[])
   {
      modsCatNode := _xmlcfg_find_child_with_name(xmlHandle, node, listElementName);

      if (modsCatNode > 0) {
         // go through all the children
         modNode := _xmlcfg_get_first_child(xmlHandle, modsCatNode); 
         while (modNode > 0) {
            UserModification mod;
            mod.setCaption('');
      
            readMod(xmlHandle, modNode, mod);
            mods[mods._length()] = mod;
      
            modNode = _xmlcfg_get_next_sibling(xmlHandle, modNode);
         }
      }
   }

   /**
    * Reads a single toolbar or menu modification from an xml file.
    * 
    * 
    * @param xmlHandle              xml handle to file
    * @param modNode                xml node containing mod information
    * @param mod                    mod where info can be stored
    */
   protected void readMod(int xmlHandle, int modNode, UserModification &mod)
   {
      if (modNode > 0) {
   
         _str attr:[];
         _xmlcfg_get_attribute_ht(xmlHandle, modNode, attr);

         if (attr._indexin('Caption')) mod.setCaption(attr:['Caption']);
         if (attr._indexin('Command')) mod.setCommand(attr:['Command']);
         if (attr._indexin('Action')) mod.setAction((int)attr:['Action']);
         if (attr._indexin('Message')) mod.setMessage(attr:['Message']);
         if (attr._indexin('Prev')) mod.setPrev(attr:['Prev']);
         if (attr._indexin('Next')) mod.setNext(attr:['Next']);
      }
   }

   /**
    * Compares two lists of separators - the default and current lists.  Looks 
    * to see if separators have been moved, removed, or added. 
    * 
    * @param origSeps         original list of separators
    * @param curSeps          current list of separators
    * 
    * @return                 true if separators have changed, false otherwise
    */
   protected boolean compareSeparatorLists(Separator (&origSeps)[], Separator (&curSeps)[])
   {
      if (origSeps._length() != curSeps._length()) return false;
   
      for (i := 0; i < origSeps._length(); i++) {
         if (!compareSeparators(origSeps[i], curSeps[i])) return false;
      }
   
      return true;
   }

   /**
    * Compares two individual separators to see if they match.  Can be overwritten 
    * by inheriting classes. 
    * 
    * @param origSep           
    * @param curSep 
    * 
    * @return 
    */
   protected boolean compareSeparators(Separator &origSep, Separator &curSep)
   {
      if (origSep.getPrevItem() != curSep.getPrevItem() || 
          origSep.getNextItem() != curSep.getNextItem()) {
         return false;
      }

      return true;
   }

   /**
    * Finds a specific separator in a list of Separators and returns its index.
    * 
    * @param sep              Separator that we are looking for
    * @param seps             list of Separators in which we hope to find our 
    *                         Separator
    * 
    * @return                 index of Separator, -1 if it was not found
    */
   protected int findSeparatorIndex(Separator sep, Separator (&seps)[])
   {
      for (i := 0; i < seps._length(); i++) {
         if (seps[i].getNextItem() == sep.getNextItem() && seps[i].getPrevItem() == sep.getPrevItem()) return i;
      }
   
      return -1;
   }
   
   /**
    * Removes all duplicated UserControls from the list.  Leaves the item that
    * comes first in the list and removes the second (and any others).  An item
    * is considered a duplicate if it has the same identifier as a UserControl
    * found earlier in the list.
    *  
    * @param controlList         list of UserControls, may contain duplicates 
    * @param dupes               list of duplicates, to be populated 
    */
   protected void removeDuplicates(UserControl (&controlList)[], typeless (&dupes)[])
   {
      // make a hash table to keep track of what we have seen
      _str items:[];

      listLength := controlList._length();
      for (i := 1; i < listLength; i++) {
         UserControl curItem = controlList[i];
         id := curItem.getIdentifier();
         
         if (items._indexin(id)) {
            UserModification um = createDupeMod(controlList, i);

            // oh no, here it is - that means this item is a duplicate!
            dupes[dupes._length()] = um;
            
            // remove this one from the list
            controlList._deleteel(i);

            // adjust the index and length
            i--;
            listLength--;
         } else {
            items:[id] = i;
         }
      }
   }  

   /**
    * Writes the list of duplicates to the xml file.  Duplicates are written as 
    * modifications, but under a separate node than the other modifications. 
    * 
    * @param xmlHandle           handle of xml file
    * @param node                node of section containing all modifications 
    *                            and duplicates
    * @param dupes               list of duplicates to be written
    */
   protected void writeDuplicates(int xmlHandle, int node, typeless (&dupes)[])
   {
      // create a category that will contain all our modifications
      modsCatNode := _xmlcfg_add(xmlHandle, node, 'Duplicates', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   
      // now write each one
      typeless dupe;
      foreach (dupe in dupes) {
         dupeNode := _xmlcfg_add(xmlHandle, modsCatNode, 'Duplicate', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         writeMod(xmlHandle, dupeNode, dupe);
      }
   }
}

