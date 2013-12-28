////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48506 $
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
#import "complete.e"
#import "menu.e"
#import "options.e"
#import "slickc.e"
#import "stdprocs.e"
#import "xmlcfg.e"
#require "CustomizationHandler.e"
#require "MenuControl.e"
#require "MenuModification.e"
#require "MenuSeparator.e"
#endregion

namespace sc.controls.customizations;

class MenuCustomizationHandler : CustomizationHandler {

   /**
    * Constructor.  Does nothing.
    */
   MenuCustomizationHandler() 
   { 
      m_modFile = _ConfigPath() :+ 'userMenus.xml';
      m_elementName = 'Menu';
      m_categoryName = 'Menus';
   }

   /**
    * Checks a menu for any changes that the user may have made to it and then 
    * writes those changes to an xml file so they can be restored later. 
    * 
    * @param menuName            name of menu to checkExistingSeparators
    * @param origMenuIndex       index of default menu
    * @param curMenuIndex        index of current menu
    * 
    * @return                    true if any changes were found (and written), 
    *                            false otherwise
    */
   public boolean saveMenuChanges(_str menuName, int origMenuIndex, int curMenuIndex)
   {
      // build a menu for each of these things
      UserControl origMenu[], curMenu[];
      Separator origSeps[], curSeps[];
      buildMenu(menuName, origMenuIndex, origMenu, origSeps);
      buildMenu(menuName, curMenuIndex, curMenu, curSeps);
   
      MenuModification dupes[];
      removeDuplicates(curMenu, dupes);

      // get our list of mods
      MenuModification mods[];
      compareControlLists(curMenu, origMenu, mods);

      // write the mods now
      if (dupes._length() || (mods != null && mods._length() > 0) || !compareSeparatorLists(origSeps, curSeps)) {
         writeMenuMods(menuName, mods, curSeps, dupes);
         return true;
      } else removeMenuMods(menuName);


      return false;
   }
   
   /**
    * Compares the identifying item of the controls to see if these two controls 
    * are the same.  Two controls can have varying other values (Help message, 
    * etc), but if their identifiers are the same, then they match. 
    * 
    * @param origItem      original UserControl
    * @param curItem       current UserControl
    * 
    * @return              true if the controls are the same, false otherwise
    */
   protected boolean compareIdentifiers(UserControl &origItem, UserControl &curItem)
   {
      // see if they match
      return (origItem.getIdentifier() == curItem.getIdentifier() && 
              ((MenuControl)origItem).getParentCaption() == ((MenuControl)curItem).getParentCaption());
   }

   /**
    * Compares the non-identifying item of the controls to see if these two 
    * controls have the same value members.   
    * 
    * @param origItem      original UserControl
    * @param curItem       current UserControl
    * 
    * @return              a UserModification object containing the differences 
    *                      between the two controls
    */
   protected UserModification compareNonIdentifiers(UserControl &origItem, UserControl &curItem)
   {
      // we do need to check for changes to the details
      MenuModification mm;

      MenuControl origMC = (MenuControl)origItem;
      MenuControl curMC = (MenuControl)curItem;

      changed := false;
   
      // we compare this because they might have changed the position of the &
      if (origItem.getCaption() != curItem.getCaption()) {
         mm.setCaption(curItem.getCaption());
         changed = true;
      }

      if (origItem.getCommand() != curItem.getCommand()) {
         mm.setCommand(curItem.getCommand());
         changed = true;
      }
   
      if (origItem.getMessage() != curItem.getMessage()) {
         mm.setMessage(curItem.getMessage());
         changed = true;
      }
   
      if (origMC.getHelp() != curMC.getHelp()) {
         mm.setHelp(curMC.getHelp());
         changed = true;
      }
   
      if (origMC.getCategories() != curMC.getCategories()) {
         mm.setCategories(curMC.getCategories());
         changed = true;
      }

      if (origMC.getSubMenu() != curMC.getSubMenu()) {
         mm.setSubMenu(curMC.getSubMenu());
         changed = true;
      }

      if (changed) {
         mm.setCaption(curItem.getCaption());
         mm.setParentCaption(curMC.getParentCaption());
         mm.setAction(MA_CHANGE);
         return mm;
      }
   
      return null;
   }

   /**
    * Finds a UserControl in a list of UserControls.
    * 
    * @param item          UserControl being sought
    * @param list          list of UserControls
    * 
    * @return              index in list of UserControl
    */
   protected int findItemInList(UserControl &item, UserControl (&list)[], int startIndex = 0, int endIndex = -1)
   {
      if (item == null || item.getCaption() == '') return NOT_FOUND;
      if (list == null || list._isempty()) return NOT_FOUND;
   
      caption := stranslate(item.getCaption(), '', '&');
   
      listLength := list._length();

      // check our input parameters
      checkStartEndValues(listLength, startIndex, endIndex);

      // check to see if it might be the first or last item
      index := checkForFirstAndLast(caption, listLength, startIndex, endIndex);
      if (index < 0) return index;

      // now find it, already
      parent := ((MenuControl)item).getParentCaption();
      for (i := startIndex; i <= endIndex; i++) {
         if (stranslate(list[i].getCaption(), '', '&') == caption && 
             ((MenuControl)list[i]).getParentCaption() == parent) return i;
      }
   
      return NOT_FOUND;
   }

   /**
    * Creates a UserModification appropriate for the changing of the given 
    * item.
    * 
    * @param list             list of UserControls
    * @param index            index of UserControl that we are interested in
    * 
    * @return                 UserModification object detailing changes
    */
   protected UserModification createChangeMod(UserControl (&list)[], int index)
   {
      if (index >= list._length()) return null;
   
      MenuModification mm;
      item := (MenuControl)list[index];
   
      // record the new position
      mm.setAction(MA_CHANGE);
      mm.setPrev(getPrevIdentifier(list, index));
      mm.setNext(getNextIdentifier(list, index));
   
      // record the stats
      mm.setCommand(item.getCommand());
      mm.setCaption(item.getCaption());
      mm.setMessage(item.getMessage());
      mm.setHelp(item.getHelp());
      mm.setParentCaption(item.getParentCaption());
      mm.setSubMenu(item.getSubMenu());
      mm.setCategories(item.getCategories());
   
      return mm;
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
      if (index >= list._length()) return null;
   
      MenuModification mm;
      item := (MenuControl)list[index];
   
      mm.setAction(MA_ADD);
      mm.setPrev(getPrevIdentifier(list, index));
      mm.setNext(getNextIdentifier(list, index));
   
      // record the stats
      mm.setCaption(item.getCaption());
      mm.setCommand(item.getCommand());
      mm.setMessage(item.getMessage());
      mm.setHelp(item.getHelp());
      mm.setParentCaption(item.getParentCaption());
      mm.setSubMenu(item.getSubMenu());
      mm.setCategories(item.getCategories());
   
      return mm;
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
   protected UserModification createRemoveMod(UserControl (&list)[], int index)
   {
      if (index >= list._length()) return null;
   
      MenuModification mm;
      item := (MenuControl)list[index];
   
      mm.setAction(MA_REMOVE);
      mm.setCaption(item.getCaption());
      mm.setParentCaption(item.getParentCaption());
   
      return mm;
   }

   /**
    * Takes an existing menu and compiles a MenuControl list of its controls. 
    * Also builds a list of the separators for a separate list.  This can also 
    * be called on a submenu. 
    * 
    * @param menuName            name of menu or submenu to build
    * @param menuIndex           index of menu or submenu
    * @param menu                list of controls
    * @param seps                list of separators
    */
   private void buildMenu(_str menuName, int menuIndex, UserControl (&menu)[], Separator (&seps)[])
   {
      // remove any &
      menuName = stranslate(menuName, '', '&');

      // save our first one so we know when we have looped around to the beginning
      origItem := menuItem := menuIndex.p_child;
      if (!menuItem) return;
   
      // this stuff is used to pull out the separators
      prev := FIRST_ITEM_TEXT;
      lastItemWasSep := false;
      MenuSeparator sep;
   
      do {
         if (menuItem.p_object == OI_MENU_ITEM && menuItem.p_caption == '-') {
            // this is a separator
            if (!lastItemWasSep) {
               sep.setPrevItem(prev);
               sep.setParentCaption(menuName);
               lastItemWasSep = true;
            }
         } else {
            // regular menu item...
            MenuControl item;
            parse menuItem.p_caption with auto caption \t .;
            item.setCaption(caption);
            item.setCommand('');
            item.setMessage(menuItem.p_message);
            item.setHelp(menuItem.p_help);
            item.setCategories(menuItem.p_categories);
            item.setParentCaption(menuName);
      
            // was the last item a separator?
            prev = item.getCaption();
            if (lastItemWasSep) {
               sep.setNextItem(item.getCaption());
               seps[seps._length()] = sep;
               lastItemWasSep = false;
            }

            if (menuItem.p_object == OI_MENU) {
               // build up the submenu then
               item.setSubMenu(true);
               menu[menu._length()] = item;
               buildMenu(getItemKey(menuItem.p_caption, menuName), menuItem, menu, seps);
            } else {
               // just a regular menu item - save it
               item.setCommand(menuItem.p_command);
               item.setSubMenu(false);
               menu[menu._length()] = item;
            }
         }
   
         // next, please
         menuItem = menuItem.p_next;
      } while (menuItem != origItem);
   
      // the last item was a separator...which is kinda weird, but we won't judge
      if (lastItemWasSep) {
         sep.setNextItem(LAST_ITEM_TEXT);
         seps[seps._length()] = sep;
      }
   }
   
   /**
    * Given an index into a UserControl list, retrieves the identifying text of 
    * the next item in the list, in this case, the caption.  If the item is the 
    * last one in the list, then LAST_ITEM_TEXT will be returned. 
    * 
    * @param controlList         list of UserControls
    * @param index               index of current item - we want identifier of 
    *                            next one
    * 
    * @return                    identifer of next item
    */
   protected _str getNextIdentifier(UserControl (&controlList)[], int index)
   {
      curParent := ((MenuControl)controlList[index]).getParentCaption();
      curCaption := getItemKey(controlList[index].getCaption(), curParent);
   
      index++;
      while (index < controlList._length()) {
         if (curParent != ((MenuControl)controlList[index]).getParentCaption()) {
            // make sure we're not looking at one of our own children
            if (((MenuControl)controlList[index]).getParentCaption() != curCaption) return LAST_ITEM_TEXT;
         } else return getItemKey(controlList[index].getCaption(), curParent);
   
         index++;
      }
   
      return LAST_ITEM_TEXT;
   }

   /**
    * Given an index into a UserControl list, retrieves the identifying text of 
    * the previous item in the list, in this case, the caption.  If the item is 
    * the first one in the list, then FIRST_ITEM_TEXT will be returned. 
    * 
    * @param controlList         list of UserControls
    * @param index               index of current item - we want identifier of 
    *                            previous one
    * 
    * @return                    identifer of previous item
    */
   protected _str getPrevIdentifier(UserControl (&controlList)[], int index)
   {
      ourParent := ((MenuControl)controlList[index]).getParentCaption();
   
      index--;
      while (index >= 0) {
         thisParent := ((MenuControl)controlList[index]).getParentCaption();
         thisCaption := controlList[index].getCaption();
         if (ourParent == thisParent) {
            return getItemKey(thisCaption, ourParent);
         } else {
            // this could be our parent!  MOM!  IT'S YOU!
            if (getItemKey(thisCaption, thisParent) == ourParent) {
               // we have the first born
               return FIRST_ITEM_TEXT;
            } 
         }

         index--;
      }
   
      return FIRST_ITEM_TEXT;
   }

   /**
    * Writes a set of modifications for a menu.
    * 
    * @param menuName            name of menu
    * @param mods                list of modifications to write
    * @param seps                list of separators
    * @param new                 whether this is a new menu 
    */
   private void writeMenuMods(_str menuName, MenuModification (&mods)[], Separator (&seps)[], 
                              MenuModification (&dupes)[], boolean new = false)
   {
      // open up our file
      xmlHandle := openModFile();
   
      // see if this node exists already
      categoryNode := getModCategory(xmlHandle, true);
      menuNode := getModItem(xmlHandle, categoryNode, menuName);
      if (new) _xmlcfg_add_attribute(xmlHandle, menuNode, 'New', 'True');
   
      // now write everything real pretty
      if (mods!= null && mods._length () > 0) writeMods(xmlHandle, menuNode, mods);
      writeSeparators(xmlHandle, menuNode, seps);
      writeDuplicates(xmlHandle, menuNode, dupes);
   
      // save it and close it
      _xmlcfg_save(xmlHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
      _xmlcfg_close(xmlHandle);
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
      CustomizationHandler.writeMod(xmlHandle, node, mod);

      // write all our info as attributes to this mod node
      MenuModification tm = (MenuModification)mod;

      value := tm.getParentCaption();
      if (value != null && value != '') _xmlcfg_add_attribute(xmlHandle, node, 'ParentCaption', value);
      value = tm.getHelp();
      if (value != null && value != '') _xmlcfg_add_attribute(xmlHandle, node, 'Help', value);
      value = tm.getCategories();
      if (value != null && value != '') _xmlcfg_add_attribute(xmlHandle, node, 'Categories', value);
      value = tm.getSubMenu();
      if (value != null && value != '') _xmlcfg_add_attribute(xmlHandle, node, 'SubMenu', value);
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
      // write the basics
      sepNode := CustomizationHandler.writeSeparator(xmlHandle, sepsCatNode, sep);

      // add the size
      _xmlcfg_add_attribute(xmlHandle, sepNode, 'ParentCaption', ((MenuSeparator)sep).getParentCaption());

      return sepNode;
   }

   /**
    * Removes a menu and all of its modifications from an xml file.
    * 
    * @param menuName         name of menu
    */
   public void removeMenuMods(_str menuName)
   {
      xmlHandle := openModFile(false);
      if (xmlHandle > 0) {
      
         // see if this node exists already
         categoryNode := getModCategory(xmlHandle, false);
   
         if (categoryNode > 0) {
            // find this menu and purge it
            removeMods(xmlHandle, categoryNode, menuName);

            // do we have any others?  we might could delete this file altogether...
            deleteFile := _xmlcfg_get_first_child(xmlHandle, categoryNode) < 0;

            // save it and close it
            _xmlcfg_save(xmlHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
            _xmlcfg_close(xmlHandle);

            // maybe delete it
            if (deleteFile) delete_file(m_modFile);
         }
      }
   }
  
   /**
    * Reads a single menu modification from an xml file.
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

         MenuModification mm;
         CustomizationHandler.readMod(xmlHandle, modNode, mm);

         if (attr._indexin('ParentCaption')) mm.setParentCaption(attr:['ParentCaption']);
         if (attr._indexin('Help')) mm.setHelp(attr:['Help']);
         if (attr._indexin('Categories')) mm.setCategories(attr:['Categories']);
         if (attr._indexin('SubMenu')) mm.setSubMenu(((int)attr:['SubMenu']) != 0);

         mod = mm;
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
      MenuSeparator menuSep;
      CustomizationHandler.readSeparator(xmlHandle, sepNode, menuSep);

      menuSep.setParentCaption(_xmlcfg_get_attribute(xmlHandle, sepNode, 'ParentCaption'));
      sep = menuSep;
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
      if (!CustomizationHandler.compareSeparators(origSep, curSep)) return false;
         
      return (((MenuSeparator)origSep).getParentCaption() == ((MenuSeparator)curSep).getParentCaption());
   }

   /** 
    * Goes through a menu and saves the position info for its children. 
    * 
    * @param menuName               name of parent menu
    * @param menuIndex              index of parent menu
    * @param parentIndexTable       table containing parent indices
    * @param subMenus               table containing submenus
    */
   private void getMenuPositionInfo(_str menuName, int menuIndex, _str (&parentIndexTable):[], STRARRAY (&subMenus):[])
   {
      parentIndexTable:[menuName] = menuIndex;
      getSubMenuPositionInfo(menuName, menuIndex, parentIndexTable, subMenus);
   }
   
   /**
    * Goes through a submenu and saves the position info for its children.
    * 
    * @param parentMenuName         name of parent menu
    * @param menuIndex              index of parent menu
    * @param parentIndexTable       table containing parent indices, keyed off 
    *                               full name of each menu item (parent menu
    *                               name > child menu name).  Values are window
    *                               id to menu item [space] window id to parent
    *                               menu item
    * @param subMenus               table containg submenus
    * @return 
    */
   private void getSubMenuPositionInfo(_str parentMenuName, int menuIndex, _str (&parentIndexTable):[], STRARRAY (&subMenus):[])
   {
      firstChild := menuItem := menuIndex.p_child;
   
      // create an array for the children of this menu
      STRARRAY thisMenu;
   
      do {
   
         if (menuItem <= 0) break;

         key := getItemKey(menuItem.p_caption, parentMenuName);
         parentIndexTable:[key] = menuItem' 'menuIndex;
         thisMenu[thisMenu._length()] = key;
   
         if (menuItem.p_object == OI_MENU) {
            // this is a submenu...
            getSubMenuPositionInfo(key, menuItem, parentIndexTable, subMenus);
         }
   
         menuItem = menuItem.p_next;
   
      } while (menuItem != firstChild);
   
      subMenus:[menuIndex] = thisMenu;
   }
   
   /**
    * Retrieves a menu items "key," which is used to locate it in the menu.
    * 
    * @param caption             caption of menu item
    * @param parent              caption of parent menu item
    * 
    * @return                    key
    */
   private _str getItemKey(_str caption, _str parent)
   {
      key := parent'>'caption;

      // go through and remove all the single &s
      ampPos := pos('&', key);
      while (ampPos) {
         // make sure the next thing is not also an &
         nextThing := substr(key, ampPos + 1, 1);
         if (nextThing != '&') {
            // remove it!
            before := substr(key, 1, ampPos - 1);
            after := substr(key, ampPos + 1);
            key = before :+ after;
         } else {
            ampPos += 2;
         }

         ampPos = pos('&', key, ampPos);
      }

      return key;
   }

   /**
    * Goes through a list of captions and returns the index of its position. 
    * Besides regular captions, also handles FIRST_ITEM_TEXT (returns 
    * FIRST_ITEM_INDEX) and LAST_ITEM_TEXT (returns LAST_ITEM_INDEX). 
    * 
    * @param caption             caption that we seek
    * @param list                list to look through
    * 
    * @return 
    */
   private int findCaptionInCaptionList(_str caption, _str (&list)[], int startIndex = -1, int endIndex = -1)
   {
      if (list == null || list._isempty()) return NOT_FOUND;

      caption = stranslate(caption, '', '&');
   
      listLength := list._length();
      // check our input parameters
      checkStartEndValues(listLength, startIndex, endIndex);

      // check to see if it might be the first or last item
      index := checkForFirstAndLast(caption, listLength, startIndex, endIndex);
      if (index < 0) return index;

      for (i := startIndex; i <= endIndex; i++) {
         if (stranslate(list[i], '', '&') == caption) return i;
      }
   
      return NOT_FOUND;
   }
   
   /**
    * Searches for a menu item in our tables to determine its parent menu window
    * id and position within that menu. 
    * 
    * @param caption                caption that we seek
    * @param parentIndexTable       a table containing information about window 
    *                               ids and parent window ids
    * @param subMenus               submenus mapped to parent window ids
    * @param parentIndex            parent index of caption we want
    * @param position               position within parent menu
    * 
    * @return                       true if we found this menu, false otherwise
    */
   private boolean findMenuItem(_str caption, _str parentIndexTable:[], STRARRAY subMenus:[], typeless &parentIndex, int &position, int findAfter = -1)
   {
      position = NOT_FOUND;
      if (caption == FIRST_ITEM_TEXT) {
         position = FIRST_ITEM_INDEX;
      } else if (caption == LAST_ITEM_TEXT) {
         position = LAST_ITEM_INDEX;
      } else if (parentIndexTable._indexin(caption)) {
         info := parentIndexTable:[caption];
         parse info with auto itemIndex parentIndex;
   
         parentMenu := subMenus:[parentIndex];
         position = findCaptionInCaptionList(caption, parentMenu, findAfter);
      }
   
      return (position != NOT_FOUND);
   }
   
   /**
    * Removes a menu item.
    * 
    * @param mod                       MenuModification that defines which menu 
    *                                  item to remove
    * @param parentIndexTable          a table containing information about window 
    *                                  ids and parent window ids
    * @param subMenus                  submenus mapped to parent window ids
    * 
    * @return                          true if we were able to remove the menu 
    *                                  item, false otherwise
    */
   private boolean removeItemFromMenu(MenuModification mod, _str (&parentIndexTable):[], STRARRAY (&subMenus):[])
   {
      parentIndex := position := NOT_FOUND;
   
      key := getItemKey(mod.getCaption(), mod.getParentCaption());
      if (findMenuItem(key, parentIndexTable, subMenus, parentIndex, position)) {
         if (!_menu_delete(parentIndex, position)) {
            // adjust the tables
            parentIndexTable._deleteel(key);
            subMenus:[parentIndex]._deleteel(position);

            return true;
         }
      }
   
      return false;
   }
   
   /**
    * Inserts a menu item described by a MenuModification into an existing menu. 
    *  
    * @param mod                    MenuModification describing new menu item
    * @param parentIndexTable       table containing indices of existing menu items 
    *                               and indices of their parents
    * @param subMenus               table of submenus and their child captions 
    * @param strictPositioning      whether to only insert when we 
    *                               match the before and after
    *                               items exactly
    * @param allowDupes             whether we allow the item to be 
    *                               inserted next to an item with
    *                               the same identifier
    * 
    * @return                       true if the menu item was inserted 
    *                               successfully, false otherwise
    */
   private boolean insertMenuItem(MenuModification mod, _str (&parentIndexTable):[], STRARRAY (&subMenus):[], 
                                  boolean strictPositioning = false, boolean allowDupes = false)
   {
      if (!parentIndexTable._indexin(mod.getParentCaption())) return false;
      
      typeless parentIndex;
      parse parentIndexTable:[mod.getParentCaption()] with parentIndex . ; 
      _str parentMenu[] = subMenus:[parentIndex];

      // figure out where to put this thing
      position := determineItemPosition(mod.getPrev(), mod.getNext(), parentMenu, strictPositioning);

      if (position >= 0) {
         // we found something, so put it there
         return insertItemIntoMenu(mod, parentIndex, position, parentIndexTable, subMenus, allowDupes);
      }

      // nope, couldn't do it
      return false;
   }

   /**
    * Given a "previous" and "next" item used to find an insertion point in a 
    * list, finds the before and after.   
    * 
    * @param prevItem               first item to find
    * @param nextItem               next item to find, must be found after the 
    *                               first one
    * @param list                   list to search (will be a list of captions 
    *                               in a submenu)
    * @param prevIndex              index of prevItem
    * @param nextIndex              index of nextItem
    * @param findAfter              where to start looking for prevItem
    */
   protected void findPrevAndNextItems(_str prevItem, _str nextItem, typeless (&list)[], int& prevIndex, int&nextIndex, int findAfter = -1)
   {
      prevIndex = findCaptionInCaptionList(prevItem, list, findAfter);
      nextIndex = findCaptionInCaptionList(nextItem, list, prevIndex + 1);
   }

   /**
    * Inserts a menu item into the specified position of an existing menu.
    * 
    * @param mod                    MenuModification definiting menu item to 
    *                               insert
    * @param parentIndex            window id of parent menu
    * @param position               position where menu item is to be inserted
    * @param parentIndexTable       a table containing information about window 
    *                               ids and parent window ids
    * @param subMenus               submenus mapped to parent window ids
    * @param allowDupes             whether we allow the item to be 
    *                               inserted next to an item with
    *                               the same identifier
    * 
    * @return                       true if menu item was inserted, false 
    *                               otherwise
    */
   private boolean insertItemIntoMenu(MenuModification mod, int parentIndex, int position, 
                                      _str (&parentIndexTable):[], STRARRAY (&subMenus):[], 
                                      boolean allowDupes = false)
   {
      flags := 0;
      if (mod.getSubMenu()) flags = MF_SUBMENU;

		// first, let's make sure this item isn't already there
		key := getItemKey(mod.getCaption(), mod.getParentCaption());
      if (!allowDupes) {
         if ((subMenus:[parentIndex]._length() >= position && subMenus:[parentIndex][position] == key) ||
             (position != 0 && (subMenus:[parentIndex][position - 1] == key))) {
            // it is either already in that position or in the position directly 
            // before it, no need to insert
            return true;
         }
      }


      if (!_menu_insert(parentIndex, position, flags, mod.getCaption(), mod.getCommand(), 
                        mod.getCategories(), mod.getHelp(), mod.getMessage())) {

         itemIndex := getIndexOfMenuItemInPosition(parentIndex, position);

         // adjust the tables and stuff
         parentIndexTable:[key] = itemIndex' 'parentIndex;
         subMenus:[parentIndex]._insertel(key, position);

         return true;
      }

      return false;
   }

   /**
    * Retrieves the window id of the menu item in the given position.
    * 
    * @param menuIndex              window id of parent menu
    * @param position               position of menu item that we seek
    * 
    * @return                       window id of menu item in the given position
    */
   private int getIndexOfMenuItemInPosition(int menuIndex, int position)
   {
      origItem := menuItem := menuIndex.p_child;
      if (!menuItem) return NOT_FOUND;
   
      count := 0;
      do {
   
         if (count == position) return menuItem;
   
         menuItem = menuItem.p_next;
         count++;
      } while (menuItem != origItem);
   
      return NOT_FOUND;
   }
   

   /**
    * Takes a list of modifications and a list of separators and applies them to 
    * the given control. 
    * 
    * @param name             name of control to affect
    * @param mods             list of mods to apply
    * @param seps             list of separators that should be in the control
    */
   protected void applyMods(_str name, UserModification (&mods)[], Separator (&seps)[], UserModification (&dupes)[])
   {
      // save the old version of this menu
      menuIndex := find_index(name, oi2type(OI_MENU));
      if (menuIndex <= 0) return;

      origMenuIndex := find_index(name :+ SE_ORIG_MENU_SUFFIX, oi2type(OI_MENU));

      if (origMenuIndex == 0) {
         // we do not have an original - so save the current one
         origMenuIndex = insert_name(name :+ SE_ORIG_MENU_SUFFIX, oi2type(OI_MENU), '', menuIndex);
      } else {
         // we already have an original version - we need to add our changes to that one
         delete_name(menuIndex);
         menuIndex = insert_name(name, oi2type(OI_MENU), '', origMenuIndex);
      }

      _str parentIndexTable:[];
      STRARRAY subMenus:[];
      getMenuPositionInfo(name, menuIndex, parentIndexTable, subMenus);
   
      MenuModification orphans[];
   
      // now go through the mods and change this default list
      MenuModification mod;
      int i;
      foreach (i => mod in mods) {
         applyMod(mod, parentIndexTable, subMenus, orphans);
      }
   
      foreach (i => mod in dupes) {
         applyMod(mod, parentIndexTable, subMenus, orphans);
      }
         
      // insert the separators
      checkExistingSeparators(name, menuIndex, seps, subMenus);
      insertMenuSeparators(seps, parentIndexTable, subMenus);

      // add the stuff we couldn't place at the end
      foreach (mod in orphans) {
         // if all else fails, we use the top level menu
         typeless parentIndex = menuIndex;
         // check for the parent menu as is
         if (parentIndexTable._indexin(mod.getParentCaption())) {
            parse parentIndexTable:[mod.getParentCaption()] with parentIndex . ;
         }

         position := (subMenus:[parentIndex])._length();
         insertItemIntoMenu(mod, parentIndex, position, parentIndexTable, subMenus);
      }

      // reload it if it's the mdi menu
      if (name_eq(name, translate(_cur_mdi_menu,'_','-'))) {
         _menu_mdi_update();
      }

      _set_object_modify(menuIndex);

   }

   /**
    * Takes the modification and applies it to the data structures representing 
    * our menu.  Then when we recreate the menu based on the structures, we will 
    * know where to put this new mod. 
    * 
    * @param mod                       MenuModification
    * @param parentIndexTable          table of parent menus
    * @param subMenus                  list of submenu captions
    * @param orphans                   list of modifications that we could not 
    *                                  apply - they will be inserted at the end
    *                                  of the menu
    */
   void applyMod(MenuModification mod, _str (&parentIndexTable):[], STRARRAY (&subMenus):[], MenuModification (&orphans)[])
   {
      switch (mod.getAction()) {
      case MA_ADD:
      case MA_DUPE:
         // insert an item into the menu
         if (!insertMenuItem(mod, parentIndexTable, subMenus, false, (mod.getAction() == MA_DUPE))) {
            // uh...we don't know what to do so just shove it at the end?
            orphans[orphans._length()] = mod;
         }
         break;
      case MA_REMOVE:
         removeItemFromMenu(mod, parentIndexTable, subMenus);
         break;
      case MA_CHANGE:
         // make sure we have it first

         int parentIndex, position;
         key := getItemKey(mod.getCaption(), mod.getParentCaption());
         if (parentIndexTable._indexin(key)) {
            if (mod.getPrev() != null && mod.getNext() != null &&
                mod.getPrev() != '' && mod.getNext() != '') {
               removeItemFromMenu(mod, parentIndexTable, subMenus);
               if (!insertMenuItem(mod, parentIndexTable, subMenus)) {
                  // uh...we don't know what to do so just shove it at the end?
                  orphans[orphans._length()] = mod;
               }
            } else {
               // only the data changed...
               typeless itemIndex;
               parse parentIndexTable:[key] with itemIndex .;
               itemIndex.p_caption = mod.getCaption();
               itemIndex.p_help = mod.getHelp();
               itemIndex.p_message = mod.getMessage();
               itemIndex.p_categories = mod.getCategories();

               // only menu items have commands
               if (itemIndex.p_object == OI_MENU_ITEM) {
                  cmd := mod.getCommand();
                  if (cmd != null && cmd != '') {
                     itemIndex.p_command = cmd;
                  }
               }
            }
         }
         break;
      }
   }

   /**
    * Goes through the separators that currently exist in the menu and 
    * determines if they are in the list of separators that we want to be in the 
    * menu.  If a separator is not in the list, we remove it.  If the separator 
    * IS in the list, we remove it from the list, so we know not to add it in. 
    *  
    * This method is called recursively. 
    *  
    * @param menuIndex           window id of menu to check separators for
    * @param seps                list of separators we want to be in this menu
    */
   private void checkExistingSeparators(_str parentMenuName, int parentMenuIndex, Separator (&seps)[], 
                                        STRARRAY (&subMenus):[])
   {
      origItem := menuItem := parentMenuIndex.p_child;
      if (!menuItem) return;
   
      Separator sep;
      lastItemWasSep := false;
      prev := FIRST_ITEM_TEXT;
      prevThing := 0;
      position := 0;
   
      do {
   
         // go ahead and grab the next menu item
         nextThing := menuItem.p_next;

         // is this a submenu?
         isSubMenu := (menuItem.p_object == OI_MENU);
   
         // keeps track of whether we deleted anything from the menu
         itemDeleted := false;

         // see if this is a separator
         if (menuItem.p_object == OI_MENU_ITEM && menuItem.p_caption == '-') {
            // if the last item was not a separator, go ahead 
            // and save this info
            if (!lastItemWasSep) {
               sep.setPrevItem(prev);
               lastItemWasSep = true;
            } else {
               // double separators are silly, so let's delete this one
               if (!_menu_delete(parentMenuIndex, position)) {
                  // remove it from the submenu listing
                  key := getItemKey('-', parentMenuName);
                  if (subMenus:[parentMenuIndex][position] == key) {
                     subMenus:[parentMenuIndex]._deleteel(position);

                     // go back one, so when we go ahead one at the end of 
                     // the loop, we'll be right again
                     position--;
                  }
               }
            }
         } else {
            // check for separators
            _str caption;
            parse menuItem.p_caption with caption \t .;
   
            // save this in case we have a separator next time
            prev = caption;

            // was the last thing a separator?
            if (lastItemWasSep) {
               sep.setNextItem(caption);
   
               // we have a completed sep now...see if it fits
               sepIndex := findSeparatorIndex(sep, seps);
               if (sepIndex >= 0) {
                  // we found it, so delete it from our list
                  seps._deleteel(sepIndex);
               } else {
                  // not in the list, so delete it from the menu
                  // go back one because the separator was one spot previous
                  position--;
                  if (!_menu_delete(parentMenuIndex, position)) {
                     itemDeleted = true;

                     // remove it from the submenu listing
                     key := getItemKey('-', parentMenuName);
                     if (subMenus:[parentMenuIndex][position] == key) {
                        subMenus:[parentMenuIndex]._deleteel(position);
                     }
                  }
               }
   
               lastItemWasSep = false;
            }
   
            // build up the submenu then
            if (isSubMenu && !itemDeleted) {
               key := getItemKey(menuItem.p_caption, parentMenuName);
               checkExistingSeparators(key, menuItem, seps, subMenus);
            }
         }
   
         position++;

         // did we delete the first thing in the menu?
         if (itemDeleted && prevThing == origItem) {
            // since our first original item has been deleted, we get a new one
            origItem = menuItem;
         }

         // we want to continue with the next item
         prevThing = menuItem;
         menuItem = nextThing;

      } while (menuItem != origItem);
   
      // do this handling one last time, in case our last menu item was a separator
      if (lastItemWasSep) {
         sep.setNextItem(LAST_ITEM_TEXT);
   
         // we have a completed sep now...see if it fits
         sepIndex := findSeparatorIndex(sep, seps);
         if (sepIndex >= 0) seps._deleteel(sepIndex);
         else {
            _menu_delete(parentMenuIndex, position);

            // remove it from the submenu listing
            key := getItemKey('-', parentMenuName);
            if (subMenus:[parentMenuIndex][position] == key) {
               subMenus:[parentMenuIndex]._deleteel(position);
            }
         }
      }
   }

   /**
    * Inserts the separators defined in the given list into the menu.
    * 
    * @param seps                      list of separators to be inserted
    * @param parentIndexTable          a table containing information about window 
    *                                  ids and parent window ids
    * @param subMenus                  submenus mapped to parent window ids
    */
   private void insertMenuSeparators(Separator (&seps)[], _str (&parentIndexTable):[], STRARRAY (&subMenus):[])
   {
      MenuSeparator sep;
      foreach (sep in seps) {

         // where would we be without parents?
         if (!parentIndexTable._indexin(sep.getParentCaption())) continue;

         // locate the before and after stuff
         int beforeParentIndex = NOT_FOUND, beforePos = NOT_FOUND, afterParentIndex = NOT_FOUND, afterPos = NOT_FOUND;

         prevKey := sep.getPrevItem();
         if (prevKey != FIRST_ITEM_TEXT) prevKey = getItemKey(prevKey, sep.getParentCaption());
         nextKey := sep.getNextItem();
         if (nextKey != LAST_ITEM_TEXT) nextKey = getItemKey(nextKey, sep.getParentCaption());

         typeless parentIndex;
         parse parentIndexTable:[sep.getParentCaption()] with parentIndex . ; 
         _str parentMenu[] = subMenus:[parentIndex];

         // figure out where to put this thing
         position := determineItemPosition(prevKey, nextKey, parentMenu, true);

         if (position >= 0) {
            // we found something, so put it there
            if (!_menu_insert(parentIndex, position, 0, '-')) {
               subMenus:[parentIndex]._insertel(getItemKey('-', sep.getParentCaption()), position);
            }
         }
      }
   }
}
