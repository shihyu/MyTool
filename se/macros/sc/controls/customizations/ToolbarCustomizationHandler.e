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
#import "options.e"
#import "stdprocs.e"
#import "tbcontrols.e"
#import "tbdefault.e"
#import "tbprops.e"
#import "toolbar.e"
#import "xmlcfg.e"
#require "CustomizationHandler.e"
#require "ToolbarControl.e"
#require "ToolbarModification.e"
#require "ToolbarSeparator.e"
#endregion

namespace sc.controls.customizations;

class ToolbarCustomizationHandler : CustomizationHandler {

   ToolbarCustomizationHandler()
   {
      m_modFile = _ConfigPath() :+ 'userToolbars.xml';
      m_elementName = 'Toolbar';
      m_categoryName = 'Toolbars';
   }

   /**
    * Compares a pair of ToolbarControls to see if their non-identifying members
    * match.
    *
    * @param origItem         default toolbar item
    * @param curItem          current toolbar item
    *
    * @return                 ToolbarModification object populated with changes
    *                         differences between toolbar items
    */
   protected UserModification compareNonIdentifiers(UserControl &origItem, UserControl &curItem)
   {
      ToolbarModification tm;
      changed := false;

      ToolbarControl origTC = (ToolbarControl)origItem;
      ToolbarControl curTC = (ToolbarControl)curItem;

      if (origTC.getMessage() != curTC.getMessage()) {
         tm.setMessage(curTC.getMessage());
         changed = true;
      }

      // original toolbar information might not have ".svg" extension
      if (!_file_eq(origTC.getPicture(), curTC.getPicture()) && 
          !_file_eq(origTC.getPicture(), _strip_filename(curTC.getPicture(),'pe'))) {
         tm.setPicture(curTC.getPicture());
         changed = true;
      }

      if (origTC.getCaption() != curTC.getCaption()) {
         tm.setCaption(curTC.getCaption());
         changed = true;
      }

      if (changed) {
         tm.setType(curTC.getType());
         tm.setCommand(curTC.getCommand());
         tm.setAction(MA_CHANGE);
         return tm;
      } else {
         // nothing changed here...
         return null;
      }

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
   protected UserModification createChangeMod(UserControl (&list)[], int index)
   {
      if (index >= list._length()) return null;

      ToolbarModification tm;
      item := (ToolbarControl)list[index];

      // record the new position
      tm.setAction(MA_CHANGE);
      tm.setPrev(getPrevIdentifier(list, index));
      tm.setNext(getNextIdentifier(list, index));

      // record the stats
      tm.setCommand(item.getCommand());
      tm.setMessage(item.getMessage());
      tm.setPicture(item.getPicture());
      tm.setCaption(item.getCaption());
      tm.setType(item.getType());

      return tm;
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

      ToolbarModification tm;
      item := (ToolbarControl)list[index];

      tm.setAction(MA_ADD);
      tm.setPrev(getPrevIdentifier(list, index));
      tm.setNext(getNextIdentifier(list, index));

      // record the stats
      tm.setCommand(item.getCommand());
      tm.setMessage(item.getMessage());
      tm.setPicture(item.getPicture());
      tm.setCaption(item.getCaption());
      tm.setType(item.getType());

      return tm;
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

      ToolbarModification tm;
      item := list[index];

      tm.setAction(MA_REMOVE);
      tm.setCommand(item.getCommand());

      return tm;
   }

   /**
    * Checks an existing toolbar to see if it has been altered by the user.
    *
    * @param tbIndex             index of toolbar in names table
    * @param tbName              name of toolbar
    * @param mods                list of mods
    * @param curSeps             current list of separators existing in toolbar
    *
    * @return                    true if toolbar has been changed, false otherwise
    */
   private bool checkToolbarForChanges(int tbIndex, _str tbName, ToolbarModification (&mods)[], Separator (&curSeps)[], ToolbarModification (&dupes)[])
   {
      // get the current and original configuration
      UserControl origControls[], currentControls[];
      Separator origSeps[];
      getOriginalToolbarInfo(tbName, origControls, origSeps);
      generateToolbarControlList(tbIndex, currentControls, curSeps);

      // remove any duplicates and maybe log them
      removeDuplicates(currentControls, dupes);

      // do our comparison
      compareControlLists(currentControls, origControls, mods);

      // check whether anything changed
      if (dupes._length() || (mods != null && mods._length() > 0) || !compareSeparatorLists(origSeps, curSeps)) {
         return true;
      }

      // nothing changed here...
      return false;
   }

   /**
    * Removes a toolbar and all of its modifications from an xml file.
    *
    * @param toolbar         name of toolbar
    */
   public void removeToolbarMods(_str tbName)
   {
      xmlHandle := openModFile(false);
      if (xmlHandle > 0) {

         // see if this node exists already
         categoryNode := getModCategory(xmlHandle, false);

         if (categoryNode > 0) {
            // find this toolbar and purge it
            removeMods(xmlHandle, categoryNode, tbName);

            // do we have any others?  we might could delete this file altogether...
            deleteFile := _xmlcfg_get_first_child(xmlHandle, categoryNode) < 0;

            // save it and close it
            _xmlcfg_save(xmlHandle, -1, VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
            _xmlcfg_close(xmlHandle);

            // maybe delete it
            if (deleteFile) delete_file(m_modFile);
         }
      }
   }

   /**
    * Retrieves information about a toolbar's original configuration.
    *
    *
    * @param tbName           name of toolbar
    * @param origList         list of toolbar controls to be populated
    * @param origSeps         list of toolbar separators to be populated
    */
   private void getOriginalToolbarInfo(_str tbName, UserControl (&origList)[], Separator (&origSeps)[])
   {
      tbName = stranslate(tbName, '_', '-');

      // get the list of TBCONTROLs
      TBCONTROL tempList[];
      _tbGetDefaultToolbarControlList(tbName, tempList);

      prev := FIRST_ITEM_TEXT;
      lastItemWasSep := false;

      // go through, pulling out the separators and converting everything
      // else to ToolbarControls
      ToolbarSeparator sep;
      for (i := 0; i < tempList._length(); i++) {

         // get the type
         type := _tbGetToolbarControlType(tempList[i]);

         if (type == TBCT_SEPARATOR) {
            // we handle separators a little differently
            if (!lastItemWasSep) {
               sep.setPrevItem(prev);
               sep.setSize((int)substr(tempList[i].name, 7));

               lastItemWasSep = true;
            }
         } else {
            // check and see if the last thing was a separator
            ToolbarControl tbc;

            tbc.setType(type);
            switch (type) {
            case TBCT_PIC_BUTTON:
               tbc.setCommand(tempList[i].command);
               tbc.setMessage(tempList[i].msg);
               picFilename := tempList[i].name;
               if (_get_extension(picFilename) == "") picFilename :+= ".svg";
               tbc.setPicture(picFilename);
               break;
            case TBCT_USER_BUTTON:
               // this shouldn't come up...
               tbc.setCommand(tempList[i].command);
               tbc.setMessage(tempList[i].msg);
               tbc.setCaption(tempList[i].name);
               break;
            case TBCT_COMBO:
               tbc.setCommand(strip(tempList[i].name));
               break;
            }

            if (lastItemWasSep) {
               sep.setNextItem(tbc.getCommand());
               origSeps[origSeps._length()] = sep;
               lastItemWasSep = false;
            }
            prev = tbc.getCommand();

            origList[origList._length()] = tbc;
         }

      }

      // see if we have a separator hanging out here
      if (lastItemWasSep) {
         sep.setNextItem(LAST_ITEM_INDEX);
         origSeps[origSeps._length()] = sep;
      }
   }

   /**
    * Generates a list of UserControls and Separators that define this toolbar.
    * 
    * @param index               index of toolbar
    * @param tbcList             list of UserControls to be populated
    * @param seps                list of Separators to be populated
    */
   private void generateToolbarControlList(int index, UserControl (&tbcList)[], Separator (&seps)[])
   {
      ToolbarSeparator sep;
      prev := FIRST_ITEM_TEXT;
      lastItemWasSep := false;

      child := index.p_child;
      if (child <= 0) return;

      for (;;) {
         ToolbarControl tbc;
         thisItemIsSep := false;

         switch (child.p_object) {
         case OI_IMAGE:
            if (child.p_picture == 0) {
               if (child.p_style == PSPIC_HIGHLIGHTED_BUTTON || child.p_style == PSPIC_FLAT_BUTTON) {
                  // a user button
                  tbc.setType(TBCT_USER_BUTTON);
                  tbc.setCommand(child.p_command);
                  tbc.setMessage(child.p_message);
                  tbc.setCaption(child.p_caption);
               } else {
                  // we got us a separator!
                  if (!lastItemWasSep && isnumber(substr(child.p_message, 6))) {
                     sep.setPrevItem(prev);
                     sep.setSize((int)substr(child.p_message, 6));
                     thisItemIsSep = true;
                     lastItemWasSep = true;
                  }
               }
            } else {
               // this is a regular ole picture button
               tbc.setType(TBCT_PIC_BUTTON);
               tbc.setCommand(child.p_command);
               tbc.setMessage(child.p_message);
               tbc.setPicture(name_name(child.p_picture));
            }
            break;
         case OI_COMBO_BOX:
            tbc.setType(TBCT_COMBO);
            tbc.setCommand(child.p_name);
            tbc.setMessage(child.p_message);
            break;
         default:
            continue;
         }

         // non-separators only, please
         if (!thisItemIsSep) {
            if (lastItemWasSep) {
               sep.setNextItem(tbc.getCommand());
               seps[seps._length()] = sep;
               lastItemWasSep = false;
            }

            prev = tbc.getCommand();
            tbcList[tbcList._length()] = tbc;
         }

         // next please
         child = child.p_next;
         if (child == index.p_child) child = 0;
         if (!child) break;
      }

      if (lastItemWasSep) {
         sep.setNextItem(LAST_ITEM_INDEX);
         seps[seps._length()] = sep;
      }
   }

   /**
    * Writes a set of toolbar modifications to the XML file.
    * 
    * @param xmlHandle                    handle to XML file
    * @param categoryNode                 node containing all Toolbar 
    *                                     modifications
    * @param tbName                       name of the toolbar
    * @param mods                         list of ToolbarModifications to be 
    *                                     written
    * @param seps                         list of Separators to be written
    */
   private void writeToolbarMods(int xmlHandle, int categoryNode, _str tbName, ToolbarModification (&mods)[],
                         Separator (&seps)[], ToolbarModification (&dupes)[])
   {
      // see if this node exists already
      tbNode := getModItem(xmlHandle, categoryNode, tbName);

      // now write everything real pretty
      if (mods!= null && mods._length () > 0) writeMods(xmlHandle, tbNode, mods);

      writeSeparators(xmlHandle, tbNode, seps);

      writeDuplicates(xmlHandle, tbNode, dupes);
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
      ToolbarModification tm = (ToolbarModification)mod;

      value := tm.getPicture();
      if (value != null && value != '') _xmlcfg_add_attribute(xmlHandle, node, 'Picture', value);
      value = tm.getType();
      if (value != null && value != -1) _xmlcfg_add_attribute(xmlHandle, node, 'Type', value);
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
      _xmlcfg_add_attribute(xmlHandle, sepNode, 'Size', ((ToolbarSeparator)sep).getSize());

      return sepNode;
   }

   /**
    * Checks the installed toolbars for any changes the user might have made to
    * their buttons.  Saves these changes in an XML file so they can be restored
    * later.
    */
   public void saveToolbarChanges()
   {
      xmlHandle := openModFile();
      if (xmlHandle < 0) {
         // this really shouldn't happen, but let's fail gracefully, alright?
         return;
      }

      toolbarsNode := getModCategory(xmlHandle);

      modified := false;

      // go through all the toolbars, see what is modified.
      for (i := 0; i < def_toolbartab._length(); ++i) {
         tbName := def_toolbartab[i].FormName;
         tbIndex := find_index(tbName, oi2type(OI_FORM));
         if (tbIndex > 0) {

            typeless tbFlags = name_info(tbIndex);
            if (!isinteger(tbFlags)) tbFlags = 0;

            if ((tbFlags & FF_SYSTEM) && _tbIsCustomizeableToolbar(tbIndex)) {
               // check this one out...
               ToolbarModification mods[];
               Separator seps[];
               ToolbarModification dupes[];

               if (checkToolbarForChanges(tbIndex, tbName, mods, seps, dupes)) {
                  writeToolbarMods(xmlHandle, toolbarsNode, tbName, mods, seps, dupes);
                  modified = true;
               } else if (removeMods(xmlHandle, toolbarsNode, tbName)) {
                  modified = true;
               }
            }
         }
      }

      // do we have any others?  we might could delete this file altogether...
      deleteFile := _xmlcfg_get_first_child(xmlHandle, toolbarsNode) < 0;

      if (modified) {
         _xmlcfg_save(xmlHandle, -1, VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
      }
      _xmlcfg_close(xmlHandle);

      // maybe delete it
      if (deleteFile) delete_file(m_modFile);

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

         ToolbarModification tm;
         CustomizationHandler.readMod(xmlHandle, modNode, tm);

         pic := attr:["Picture"];
         if (pic != "" && pic!=null) pic = _tbGetUpdatedIconName(pic);
         if (pic == "") pic = attr:["Picture"];

         if (attr._indexin('Picture')) tm.setPicture(pic);
         if (attr._indexin('Type')) tm.setType((int)attr:['Type']);

         mod = tm;
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
      ToolbarSeparator tSep;

      CustomizationHandler.readSeparator(xmlHandle, sepNode, tSep);
      tSep.setSize(_xmlcfg_get_attribute(xmlHandle, sepNode, 'Size'));

      sep = tSep;
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
   protected bool compareSeparators(Separator &origSep, Separator &curSep)
   {
      if (!CustomizationHandler.compareSeparators(origSep, curSep)) return false;

      return (((ToolbarSeparator)origSep).getSize() == ((ToolbarSeparator)curSep).getSize());
   }

   /**
    * Takes a list of modifications and a list of separators and applies them to
    * the given control.
    *
    * @param name             name of control to affect
    * @param mods             list of mods to apply
    * @param seps             list of separators that should be in the control
    */
   void applyMods(_str name, UserModification (&mods)[], Separator (&seps)[], UserModification (&dupes)[])
   {
      // get the defaults for this toolbar
      UserControl origControls[];
      Separator origSeps[];
      getOriginalToolbarInfo(name, origControls, origSeps);

      ToolbarControl orphans[];

      // now go through the mods and change this default list
      ToolbarModification tm;
      foreach (tm in mods) {
         applyMod(origControls, orphans, tm);
      }

      // next, insert our duplicates
      foreach (tm in dupes) {
         applyMod(origControls, orphans, tm);
      }

      // add the stuff we couldn't place at the end
      ToolbarControl tbc;
      foreach (tbc in orphans) {
         origControls[origControls._length()] = tbc;
      }

      // now insert all the separators
      ToolbarSeparator sep;
      foreach (sep in seps) {
         ToolbarControl spaceTBC;
         spaceTBC.setCommand('space'sep.getSize());
         spaceTBC.setType(TBCT_SEPARATOR);
         insertItemIntoList(spaceTBC, sep.getPrevItem(), sep.getNextItem(), origControls, true);
      }

      applyUserControlList(name, origControls);
   }

   /**
    * Applies a ToolbarModification to our list of toolbar controls.  Later, 
    * when we recreate the toolbar based on the control array, our modifications 
    * will be included. 
    * 
    * 
    * @param origControls                 list of ToolbarControls - the toolbar 
    *                                     as it stands now
    * @param orphans                      list of modifications which we could 
    *                                     not insert (MA_ADD or MA_DUPE)
    * @param tm                           ToolbarModification to add
    */
   void applyMod(UserControl (&origControls)[], ToolbarControl (&orphans)[], ToolbarModification &tm)
   {
      ToolbarControl tbc;

      switch (tm.getAction()) {
      case MA_ADD:
      case MA_DUPE:
         // insert an item into the control list
         tbc.setCommand(tm.getCommand());
         tbc.setType(tm.getType());
         tbc.setCaption(tm.getCaption());
         tbc.setMessage(tm.getMessage());
         tbc.setPicture(tm.getPicture());

         // stick our new item in
         if (insertItemIntoList(tbc, tm.getPrev(), tm.getNext(), origControls, (tm.getAction() == MA_DUPE)) < 0) {
            // uh...we don't know what to do so just shove it at the end?
            orphans[orphans._length()] = tbc;
         }
         break;
      case MA_REMOVE:
         curIndex := findIdInList(tm.getCommand(), origControls);
         if (curIndex >= 0) origControls._deleteel(curIndex);
         break;
      case MA_CHANGE:
         // make sure we have it first
         curIndex = findIdInList(tm.getCommand(), origControls);
         if (curIndex >= 0) {
            // first make any changes
            tbc = (ToolbarControl)origControls[curIndex];
            tbc.setType(tm.getType());

            if (tm.getPicture() != '' && tm.getPicture() != null) tbc.setPicture(tm.getPicture());
            if (tm.getMessage() != '' && tm.getMessage() != null) tbc.setMessage(tm.getMessage());
            if (tm.getCaption() != '' && tm.getCaption() != null) tbc.setCaption(tm.getCaption());

            // see if we need to move it
            if (tm.getPrev() != null && tm.getNext() != null &&
                tm.getPrev() != '' && tm.getNext() != '') {
               newIndex := insertItemIntoList(tbc, tm.getPrev(), tm.getNext(), origControls);
               if (newIndex >= 0) {
                   if (newIndex <= curIndex) curIndex++;
                   origControls._deleteel(curIndex);
               }
            } else origControls[curIndex] = tbc;
         }
         break;
      }
   }

   /**
    * Takes a list of UserControls and creates a living, breathing toolbar out 
    * of it. 
    * 
    * @param formName               name of toolbar
    * @param list                   list of UserControls
    */
   void applyUserControlList(_str formName, UserControl (&list)[])
   {
      origFormWid := p_active_form;
      origWid := p_window_id;

      oldFormIndex := find_index(formName, oi2type(OI_FORM));
      if (!oldFormIndex) return;

      // get the form all ready
      //visibleWid := _tbIsVisible(formName);
      visibleWid := _tbGetWid(formName);
      formWid := _create_window(OI_FORM, _desktop, "", 0, 0, 2000, 900, CW_PARENT | CW_HIDDEN, BDS_SIZABLE);
      formWid.p_name = formName;
      formWid.p_caption = oldFormIndex.p_caption;
      formWid.p_tool_window = true;
      formWid.p_CaptionClick = true;
      formWid.p_eventtab2 = find_index("_qtoolbar_etab2", EVENTTAB_TYPE);

      for (i := 0; i < list._length(); ++i) {
         ToolbarControl tbc = (ToolbarControl)list[i];

         if (tbc.getType() == TBCT_PIC_BUTTON) {
            wid := _create_window(OI_IMAGE, formWid, "", 0, 0, 0, 0, CW_CHILD);
            wid.p_tab_index = i + 1;

            ico_picname := tbc.getPicture();
            svg_picname := tbc.getPicture();
            ico_picname = _strip_filename(ico_picname, 'pe');
            svg_picname = _strip_filename(svg_picname, 'pe');
            if (!endsWith(ico_picname,".ico",true,'i')) {
               ico_picname :+= ".ico";
            }
            if (!endsWith(svg_picname,".svg",true,'i')) {
               svg_picname :+= ".svg";
            }
            picIndex := find_index(svg_picname, PICTURE_TYPE);
            if ( !picIndex ) {
               picIndex = find_index(ico_picname, PICTURE_TYPE);
            }
            if ( !picIndex ) {
               // maybe we can try and load up this picture?
               ico_picfile := "";
               svg_picfile := "";
               if (_strip_filename(tbc.getPicture(), 'n') == "") {
                  // no path, try adding the bitmaps dir
                  pic_style := tbNormalizeBitmapStyle(def_toolbar_pic_style);
                  if ( pic_style == "green" )  pic_style = "blue";
                  if ( pic_style == "orange" ) pic_style = "blue";
                  if ( pic_style == "grey" )   pic_style = "blue";
                  if ( pic_style == "white" )  pic_style = "blue";
                  ico_picfile = _getSlickEditInstallPath():+VSE_BITMAPS_DIR:+FILESEP:+"tb":+def_toolbar_pic_style:+FILESEP:+ico_picname;
                  svg_picfile = _getSlickEditInstallPath():+VSE_BITMAPS_DIR:+FILESEP:+"tb":+def_toolbar_pic_style:+FILESEP:+svg_picname;
               } else {
                  ico_picfile = tbc.getPicture();
                  svg_picfile = _strip_filename(ico_picfile,'e'):+".svg";
               }
               if (file_exists(svg_picfile)) {
                  picIndex = _find_or_add_picture(svg_picfile);
               } else if ( file_exists(ico_picfile) ) {
                  picIndex = _find_or_add_picture(ico_picfile);
               }
            }

            if (picIndex <= 0) continue;

            wid.p_auto_size = true;
            wid.p_picture = picIndex;
            wid.p_command = tbc.getCommand();
            wid.p_message = tbc.getMessage();
            wid.p_style = PSPIC_HIGHLIGHTED_BUTTON;
            wid.p_eventtab2 = defeventtab _ul2_picture;
         } else {
            SPECIALCONTROL psc = null;

            specialControlKey := '';
            if (tbc.getType() == TBCT_USER_BUTTON) specialControlKey = 'button';
            else specialControlKey = tbc.getCommand();

            if (specialControlKey != '') _tbGetSpecialControl(specialControlKey, psc);

            if (psc != null) {
               wid := _create_window(psc.object, formWid, "", 0, 0, 0, 0, CW_CHILD);
               wid.p_tab_index = i + 1;
               if (psc.eventtab_name != "") wid.p_eventtab = find_index(psc.eventtab_name, EVENTTAB_TYPE);
               if (psc.eventtab2_name != "") wid.p_eventtab2 = find_index(psc.eventtab2_name, EVENTTAB_TYPE);

               switch (tbc.getType()) {
               case TBCT_COMBO:
                  wid.p_name = tbc.getCommand();
                  wid.p_width = psc.width;
                  wid.p_message = psc.description;
                  break;
               case TBCT_SEPARATOR:
                  wid.p_picture = 0;
                  wid.p_message = specialControlKey;
                  wid.p_style = PSPIC_TOOLBAR_DIVIDER_VERT;
                  break;
               case TBCT_USER_BUTTON:
                  wid.p_picture = 0;
                  wid.p_message = tbc.getMessage();
                  wid.p_style = PSPIC_HIGHLIGHTED_BUTTON;
                  wid.p_caption = tbc.getCaption();
                  wid.p_command = tbc.getCommand();

                  wid.p_eventtab = defeventtab _toolbar_customization_form.ctlpicture;
                  wid.p_eventtab2 = defeventtab _ul2_picture;
                  break;
               }
            }
         }
      }

      delete_name(oldFormIndex);

      typeless junk1,junk2;
      formWid._tbResizeButtonBar2(junk1, junk2);

      status := formWid._update_template();
      set_name_info(status, FF_SYSTEM);
      _set_object_modify(status);
      formWid._delete_window();

      if (visibleWid) _tbRedisplay(visibleWid);

      p_window_id = origWid;
   }

   /**
    * Inserts a ToolbarControl into our list of UserControls into the 
    * appropriate place based on the surrounding commands.  If the correct 
    * position cannot be determined, then we return an error. 
    * 
    * @param tbc                       ToolbarControl we want to insert
    * @param commandBefore             command of ToolbarControl that comes just 
    *                                  before
    * @param commandAfter              command of ToolbarControl that comes just 
    *                                  after
    * @param list                      list of UserControls where our control 
    *                                  should be inserted
    * 
    * @return                          if the control was inserted, we return 
    *                                  its index in the list, otherwise we
    *                                  return -1
    */
   private int insertItemIntoList(ToolbarControl tbc, _str commandBefore, _str commandAfter, UserControl (&list)[], bool strictPositioning = false)
   {
      // figure out where to put this thing
      position := determineItemPosition(commandBefore, commandAfter, list, strictPositioning);

      if (position >= 0) {
         // we found something, so put it there
         list._insertel(tbc, position);
      }

      // send back what we got
      return position;
   }

}
