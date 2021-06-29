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
#include "se/ui/toolwindow.sh"
#include "dockchannel.sh"
#import "files.e"
#import "main.e"
#import "mprompt.e"
#import "listbox.e"
#import "stdprocs.e"
#import "se/ui/toolwindow.e"
#import "se/ui/mainwindow.e"
#endregion


_str _user_layouts_export_settings(_str& path)
{
   error := '';

   // we just copy over the whole user layout file
   layoutFile := _ConfigPath() :+ USR_LAYOUT_FILE;

   // make sure we have a path here
   if (file_exists(layoutFile)) {

      // rip out just the file name
      justFile := _strip_filename(layoutFile, 'P');
      if (copy_file(layoutFile, path :+ justFile)) {
         error = 'Error copying user layouts file, 'layoutFile'.';
      }
      path = justFile;
   }

   return error;
}

_str _user_layouts_import_settings(_str file)
{
   error := '';

   // first, check if we have an existing user layouts file
   layoutFile := _ConfigPath() :+ USR_LAYOUT_FILE;
   if (!file_exists(layoutFile)) {
      // nope!  this is easy, just copy it over
      if (copy_file(file, layoutFile)) {
         error = 'Error copying user layouts file, 'file'.';
      }

      // done here
      return error;
   }

   // we have to combine these files
   // first, get the list of existing layout names
   _str names[];
   getAllLayoutNames(names);

   // open up our file
   xmlHandle := _xmlcfg_open(file, auto status);
   if (xmlHandle < 0) {
      return 'Error opening layout file 'file'.  Error code = 'status'.';
   }

   // get the top node, go through the children
   parent := _xmlcfg_find_simple(xmlHandle, '//Layouts');
   child := _xmlcfg_get_first_child(xmlHandle, parent);
   while (child > 0) {
      // get the name
      lName := _xmlcfg_get_attribute(xmlHandle, child, 'Name');

      // is this name already being used?
      if (_inarray(lName, names)) {
         lName = createNewName(lName);

         // rename it
         _xmlcfg_set_attribute(xmlHandle, child, 'Name', lName);
      }

      // next!
      child = _xmlcfg_get_next_sibling(xmlHandle, child);
   }

   // now, open up the existing user file and find the parent node
   userHandle := openUserLayoutsFile();
   userParent := _xmlcfg_find_simple(xmlHandle, '//Layouts');

   // copy everything over
   _xmlcfg_copy(userHandle, userParent, xmlHandle, parent, VSXMLCFG_COPY_CHILDREN);

   // clean up after ourselves
   _xmlcfg_close(xmlHandle);

   _xmlcfg_save(userHandle, -1, VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
   _xmlcfg_close(userHandle);

   return error;
}

// default layout
static const DEFAULT_LAYOUT=     'Standard';

// defaults layout for new floating windows
_str def_default_floating_layout = DEFAULT_LAYOUT;

// property name for the current layout, used with _MDIGet/SetUserProperty()
static const CURRENT_LAYOUT_PROPERTY=  'CurrentLayout';

// system and user layout files
static const SYS_LAYOUT_FILE=    'syslayouts.xml';
static const USR_LAYOUT_FILE=    'ulayouts.xml';

/**
 * Opens the user layouts file, found in the config directory. 
 *  
 * @return int       view id to file
 */
static int openUserLayoutsFile()
{
   // open up the user layouts file
   path := _ConfigPath() :+ USR_LAYOUT_FILE;

   int xmlHandle;
   if (!file_exists(path)) {
      xmlHandle = _xmlcfg_create(path, VSENCODING_UTF8);

      // create the XML declaration
      declNode := _xmlcfg_add(xmlHandle, TREE_ROOT_INDEX, "xml", VSXMLCFG_NODE_XML_DECLARATION, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(xmlHandle, declNode, "version", "1.0");

      // create the DOCTYPE declaration
      doctypeNode := _xmlcfg_add(xmlHandle, TREE_ROOT_INDEX, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(xmlHandle, doctypeNode, "root",   "SlickLayouts");
      _xmlcfg_set_attribute(xmlHandle, doctypeNode, "SYSTEM", "http://www.slickedit.com/dtd/vse/19.0/slicklayouts.dtd");

      // create the top level element
      _xmlcfg_add(xmlHandle, TREE_ROOT_INDEX, "Layouts", VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   } else {
      xmlHandle = _xmlcfg_open(path, auto status);
   }

   // return the handle
   return xmlHandle;
}

/**
 * Opens the system layouts file.
 * 
 * @return int       view id to file
 */
static int openSystemLayoutsFile()
{
   // where is the file?
   path := _getSysconfigMaybeFixPath('gui' :+ FILESEP :+ SYS_LAYOUT_FILE);

   xmlHandle := _xmlcfg_open(path, auto status);

   // return the handle
   return xmlHandle;
}

/**
 * Retrieves all layout names, including both system and user 
 * layouts. 
 * 
 * @param layouts       array of names
 */
static void getAllLayoutNames(_str (&layouts)[])
{
   getSystemLayoutNames(layouts);
   getUserLayoutNames(layouts);
}

/**
 * Retrieves the system layout names.
 * 
 * @param layouts       array of names
 */
static void getSystemLayoutNames(_str (&layouts)[])
{
   // open up the system file
   xmlHandle := openSystemLayoutsFile();
   if (xmlHandle > 0) {
      // go get 'em
      getLayoutNamesFromFile(xmlHandle, layouts);

      // we're done, close it up
      _xmlcfg_close(xmlHandle);
   }
}

/**
 * Retrieves the user layout names.
 * 
 * @param layouts       array of names
 */
static void getUserLayoutNames(_str (&layouts)[])
{
   // open up the user file
   xmlHandle := openUserLayoutsFile();
   if (xmlHandle > 0) {
      getLayoutNamesFromFile(xmlHandle, layouts);
      _xmlcfg_close(xmlHandle);
   }
}

/**
 * Searches the current file for layouts.  Retrieves the names 
 * of the layouts found within. 
 *  
 * We assume the current window id is a layout file. 
 *  
 * @param layouts       array of names
 */
static void getLayoutNamesFromFile(int xmlHandle, _str (&layouts)[])
{
   // all the children should be Layouts, grab their names
   _xmlcfg_find_simple_array(xmlHandle, '//Layout/@Name', layouts, TREE_ROOT_INDEX, VSXMLCFG_FIND_VALUES | VSXMLCFG_FIND_APPEND);
}

/**
 * Finds the given layout's definition in the layout file(s). 
 * If the layout is successfully located, the by-ref values of 
 * xmlHandle and node are set to the file and node of the 
 * layout. The caller will need to take care of closing up the 
 * file. 
 *  
 * @param xmlHandle           (by-ref) if layout is found, this 
 *                            is set to the handle of the file
 *                            where it is located
 * @param node                (by-ref) if layout is found, this 
 *                            is set to the node where it is
 *                            located
 * @param layoutName          layout to find
 * @param userFileOnly        true to only search the user 
 *                            layouts file, false to search both
 *                            user and system files
 * 
 * @return int                true if we found the layout 
 */
static bool findLayout(int& xmlHandle, int &node, _str layoutName, bool userFileOnly = false)
{
   // first try the user layouts file
   xmlHandle = openUserLayoutsFile();
   node = findLayoutInFile(xmlHandle, layoutName);
   if (node > 0) return true;

   // did not find it, close the file
   _xmlcfg_close(xmlHandle);

   if (!userFileOnly) {
      // try the system layouts file
      xmlHandle = openSystemLayoutsFile();
      node = findLayoutInFile(xmlHandle, layoutName);

      if (node > 0) return true;
   }

   node = xmlHandle = -1;
   return false;
}

/**
 * Given an xmlHandle, looks for a layout in that file.
 * 
 * @param xmlHandle        xml file to check     
 * @param layoutName       layout name to look for
 * 
 * @return int             node where layout is located, 
 *                         negative value if it was not found
 */
static int findLayoutInFile(int xmlHandle, _str layoutName)
{
   ss := "//Layout[file-eq(@Name, '"layoutName"')]";
   node := _xmlcfg_find_simple(xmlHandle, ss);

   return node;
}

/**
 * Applies the given layout to the main window.
 * 
 * @param layoutName       name of layout to apply
 */
_command void applyLayout(_str layoutName='') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   setCurrentLayout(layoutName);
}

_command void applyLayoutAndSetDefault(_str layoutName='') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   setCurrentLayout(layoutName, true);
}

_command void applyLayoutToAll(_str layoutName='') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   setCurrentLayout(layoutName, true, true);
}

static void setCurrentLayout(_str layoutName = '', bool setDefault = false, bool applyToAll = false)
{
   if (layoutName == '') return;

   // get the layout info
   _str encoding;
   _str twNames[];
   getLayoutInfo(layoutName, twNames, encoding);
   
   // get the calling window, so we apply the non-duplicate tool windows to it
   curWid := _MDICurrent();

   if (applyToAll) {
      // apply to each of the floating document windows
      int wids[];
      _MDIGetMDIWindowList(wids);
      for (i := 0; i < wids._length(); i++) {
         thisWid := wids[i];
         if (thisWid != _mdi) {
            applyLayoutToWindow(wids[i], layoutName, twNames, encoding, (thisWid == curWid));
         }
      }
   } else {
      // just the current window
      applyLayoutToWindow(curWid, layoutName, twNames, encoding, true);
   }

   if (setDefault) {
      // change the current value
      def_default_floating_layout = layoutName;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

static void getLayoutInfo(_str layoutName, _str (&twNames)[], _str& encoding)
{
   // now we have to find where the layout is saved
   int xmlHandle, node;
   if (!findLayout(xmlHandle, node, layoutName)) return;

   // get the list of tool windows and the encoded string
   child := _xmlcfg_get_first_child(xmlHandle, node);
   while (child > 0) {
      name := _xmlcfg_get_name(xmlHandle, child);
      switch (name) {
      case 'ToolWindow':
         twNames[twNames._length()] = _xmlcfg_get_attribute(xmlHandle, child, 'Name');
         break;
      case 'State':
         // get child, which is CDATA
         cdataNode := _xmlcfg_get_first_child(xmlHandle, child, VSXMLCFG_NODE_CDATA);
         encoding = _xmlcfg_get_value(xmlHandle, cdataNode);
      }

      child = _xmlcfg_get_next_sibling(xmlHandle, child);
   }

   _xmlcfg_close(xmlHandle);
}

static void applyLayoutToWindow(int mdiWid, _str layout, _str (&twNames)[], _str encoding, bool applyNonDupes=false)
{
   // Need to restore focus to active editor after the dust settles
   int child_wid = mdiWid._MDIGetActiveMDIChild();

   tw_clear(mdiWid);

   // Duplicate the set of tool windows in this layout from src_mdi to apply to dst_mdi
   ToolWindowInfo* twinfo;
   int wids[];
   for ( i := 0; i < twNames._length(); ++i ) {

      // get the name from the line
      tw := twNames[i];

      twinfo = tw_find_info(tw);
      if ( twinfo && tw_is_allowed(tw, twinfo) ) {
         twWid := 0;
         if (twinfo->flags & TWF_SUPPORTS_MULTIPLE) {
            twWid = tw_load_form(tw);
         } else {
            if (applyNonDupes) {
               // find this tool window if it is already in use
               twWid = _find_formobj(tw, 'N');
               if (twWid > 0) {
                  // remove it from wherever it may be
                  tw_remove(twWid);
               } else {
                  // just load it
                  twWid = tw_load_form(tw);
               }
            } 
         }

         // if we have a wid, add it to our list
         if (twWid > 0) {
            twWid.p_tile_id = _create_tile_id();
            wids[wids._length()] = twWid;
         }
      }
   }

   // now apply the encoded string
   _MDIWindowRestoreLayout(mdiWid, encoding, WLAYOUT_MAINAREA, RESTORESTATE_NOINSTANCEMATCH, wids);

   // and set the property
   _MDISetUserProperty(mdiWid, CURRENT_LAYOUT_PROPERTY, layout);

   // Safe to call ON_CREATE for restore windows now. This is especially important for auto-hide windows,
   // since they would otherwise not have their ON_CREATE called until first show, which is too late for
   // functions like tw_find_form().
   wids._makeempty();
   tw_get_registered_windows(wids, mdiWid);
   int wid;
   foreach ( wid in wids ) {
      wid._on_create_tool_window(false);
   }

   // Restore focus
   if ( child_wid && _iswindow_valid(child_wid) ) {
      p_window_id = child_wid;
      _set_focus();
   }
}

static void writeLayout(int xmlHandle, _str layoutName)
{
   // collect the tool windows on this window
   int src_mdi = _MDICurrent();
   _str twNames[];

   int wids[];
   tw_get_registered_windows(wids, src_mdi);
   int i, n = wids._length();
   for ( i = 0; i < n; ++i ) {
      // save the name
      twNames[twNames._length()] = wids[i].p_name;
   }

   // find the Layouts category, make a new Layout node
   node := _xmlcfg_find_simple(xmlHandle, '/Layouts');
   node = _xmlcfg_add(xmlHandle, node, 'Layout', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);

   // add the name
   _xmlcfg_set_attribute(xmlHandle, node, 'Name', layoutName);

   // now write the tool windows
   for (i = 0; i < twNames._length(); i++) {
      twNode := _xmlcfg_add(xmlHandle, node, 'ToolWindow', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(xmlHandle, twNode, 'Name', twNames[i]);
   }

   // and the encoded layout string
   s := '';
   _MDIWindowSaveLayout(src_mdi, s, WLAYOUT_MAINAREA);
   sNode := _xmlcfg_add(xmlHandle, node, 'State', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   sNode = _xmlcfg_add(xmlHandle, sNode, '', VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_value(xmlHandle, sNode, s);
}

/**
 * Saves the existing configuration of tool windows and 
 * toolbars to the given layout name.
 * 
 * @param layoutName       layout name
 */
_command void saveCurrentLayout(_str layoutName = '') name_info(',')
{
   // get the layout name from the mdi window properties
   if (layoutName == '') {
      mdiWid := _MDICurrent();
      _MDIGetUserProperty(mdiWid, CURRENT_LAYOUT_PROPERTY, layoutName);
      if (layoutName == '') return;
   }

   // open up the user file
   xmlHandle := openUserLayoutsFile();

   // first, see if this is already in there - delete it
   deleteLayoutFromFile(xmlHandle, layoutName);

   // save it to our file
   writeLayout(xmlHandle, layoutName);

   // save the file and close up shop
   _xmlcfg_save(xmlHandle, -1, VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
   _xmlcfg_close(xmlHandle);
}

/**
 * Creates a suggested name for a new layout.
 * 
 * @param name       existing name, which may be already in use
 * 
 * @return _str      new name
 */
static _str createNewName(_str name)
{
   // get the existing list of layouts
   _str layouts[];
   getAllLayoutNames(layouts);

   // first try the old 'My' trick
   // make sure it hasn't been done already - that would look stupid
   if (substr(name, 1, 2) != 'My') {
      name = 'My' :+ upcase(substr(name, 1, 1)) :+ substr(name, 2);

      // not there, return it
      if (!_inarray(name, layouts)) return name;
   }

   // try adding numbers
   num := 1;
   while (_inarray(name :+ num, layouts)) {
      num++;
   }

   return (name :+ num);
}

/**
 * Saves the existing configuration of tool windows and toolbars 
 * to a new name.  Prompts for the new name.
 */
_command void saveCurrentLayoutAs() name_info(',')
{
   // get the list of existing layouts, so we know what names are taken
   _str slayouts[];
   getSystemLayoutNames(slayouts);
   _str ulayouts[];
   getUserLayoutNames(ulayouts);

   // get the current name to use as a suggestion
   mdiWid := _MDICurrent();
   _MDIGetUserProperty(mdiWid, CURRENT_LAYOUT_PROPERTY, auto curName);
   sugName := curName;
   if (sugName == '') sugName = 'MyLayout';
   if (_inarray(sugName, slayouts)) {
      // this is a system layout, so we need to come up with a better suggestion
      sugName = createNewName(sugName);
   }

   // first, get a new name
   newLayoutName := '';
   defCheck := 0;
   while (true) {

      result := show('-modal _save_layout_as_form', ulayouts, sugName, defCheck);

      if (result != IDOK || _param1 == '') return;
      newLayoutName = strip(_param1);
      defCheck = _param2;

      // make sure this name isn't already taken
      if (_inarray(newLayoutName, slayouts)) {
         _message_box("There is already a system layout with the name "newLayoutName".  Please select another name.");
      } else if (_inarray(newLayoutName, ulayouts)) {
         result = _message_box("There is already a user-defined layout with the name "newLayoutName". ":+
                               "Would you like to overwrite the existing layout?", 
                               'Save Layout As', MB_YESNO | MB_ICONQUESTION);
         if (result == IDYES) break;

      } else break;
   }

   // save it to the new name
   saveCurrentLayout(newLayoutName);

   // set new layout name as current
   _MDISetUserProperty(mdiWid, CURRENT_LAYOUT_PROPERTY, newLayoutName);

   // maybe set as default
   if (defCheck) {
      def_default_floating_layout = newLayoutName;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

/**
 * Deletes the current layout.  Sets the current layout to the 
 * default, but does not actually apply the default layout 
 * (toolbars and windows do not change). 
 */
_command void deleteLayout(_str layout='') name_info(',')
{
   if (layout == '') return;

   // verify user wants to do this
   result := _message_box('Are you sure you wish to delete the layout "'layout'?"', "Delete layout", MB_OKCANCEL | MB_ICONQUESTION);
   if (result == IDCANCEL) return;

   // delete it
   int xmlHandle, node;
   if (findLayout(xmlHandle, node, layout, true)) {
      status := _xmlcfg_delete(xmlHandle, node);
      _xmlcfg_save(xmlHandle, -1, VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
      _xmlcfg_close(xmlHandle);
   } 

   // if this was the current for any windows, then set that to blank
   int wids[];
   _MDIGetMDIWindowList(wids);
   for (i := 0; i < wids._length(); i++) {
      if (_MDIWindowHasMDIArea(wids[i]) && wids[i] != _mdi) {
         if (_MDIGetUserProperty(wids[i], CURRENT_LAYOUT_PROPERTY, auto thisLayout) && thisLayout == layout) {
            _MDISetUserProperty(wids[i], CURRENT_LAYOUT_PROPERTY, '');
         }
      }
   }
}

/**
 * Removes a the layout with the given name from the xml file 
 * specified by xmlHandle. 
 * 
 * @param xmlHandle        handle to xml file
 * @param layoutName       name of layout to delete
 */
static void deleteLayoutFromFile(int xmlHandle, _str layoutName)
{
   node := findLayoutInFile(xmlHandle, layoutName);
   if (node > 0) {
      _xmlcfg_delete(xmlHandle, node);
      _xmlcfg_save(xmlHandle, -1, VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
   }
}

/**
 * Resets the current layout to its last saved state. 
 * Same as re-applying the current layout, losing any changes 
 * made since the last apply. 
 */
_command void resetCurrentLayout() name_info(',')
{
   mdiWid := _MDICurrent();
   _MDIGetUserProperty(mdiWid, CURRENT_LAYOUT_PROPERTY, auto layoutName);

   // just like applying the current layout anew
   applyLayout(layoutName);
}

void insertLayoutsSubMenu(int menu_handle, int itemPos)
{
   // insert layouts submenu
   subMenuCategory := 'layouts';
   subMenuItemPos := 0;
   _menu_insert(menu_handle, itemPos++, MF_ENABLED|MF_SUBMENU,
                "Layouts", "", subMenuCategory, "", "Use layouts to set the tool windows that decorate floating document groups");

   subMenuHandle := 0;
   if(!_menu_find(menu_handle, subMenuCategory, subMenuHandle, auto menuPos, "C")) {

      // get the current layout name
      mdiWid := _MDICurrent();
      _MDIGetUserProperty(mdiWid, CURRENT_LAYOUT_PROPERTY, auto curLayout);

      int targetMenuHandle;
      _menu_get_state(subMenuHandle, menuPos, 0, "P", "", targetMenuHandle, "", "", "");

      // insert the user layouts
      _str ulayouts[];
      getUserLayoutNames(ulayouts);
      ulayouts._sort();

      if (ulayouts._length()) {
         insertLayoutsIntoMenu(targetMenuHandle, subMenuItemPos, ulayouts, 'applyLayout', 
                               'help Toolbar Layouts', 'Switch to another layout', curLayout);

         // spacer
         _menu_insert(targetMenuHandle,subMenuItemPos++,0,'-');
      }

      // now add the system layouts
      _str slayouts[];
      getSystemLayoutNames(slayouts);
      slayouts._sort();

      insertLayoutsIntoMenu(targetMenuHandle, subMenuItemPos, slayouts, 'applyLayout', 
                            'help Toolbar Layouts', 'Switch to another layout', curLayout);

      // spacer
      _menu_insert(targetMenuHandle,subMenuItemPos++,0,'-');

      // finally, the things you can do with a layout
      // determine whether the current layout is a system or user one
      curIsBlank := (curLayout == '');
      curIsSys := _inarray(curLayout, slayouts);

      _menu_insert(targetMenuHandle,subMenuItemPos++, curIsBlank || curIsSys ? MF_GRAYED : MF_ENABLED,
                   "Save layout", "saveCurrentLayout", "","","Save the current layout");
      _menu_insert(targetMenuHandle,subMenuItemPos++, MF_ENABLED,
                   "Save layout as...", "saveCurrentLayoutAs", "","","Saves the current layout with a new name");
      _menu_insert(targetMenuHandle,subMenuItemPos++, curIsBlank ? MF_GRAYED : MF_ENABLED,
                   "Reset layout", "resetCurrentLayout", "","","Resets the current layout back to the last save point");

      // delete is a submenu
      subMenuCategory = 'delete_layouts';
      _menu_insert(targetMenuHandle, subMenuItemPos++, MF_ENABLED|MF_SUBMENU,
                   "Delete layout", "", subMenuCategory, "", "Deletes a user-defined layout");

      if(!_menu_find(menu_handle, subMenuCategory, subMenuHandle, menuPos, "C")) {

         delSubMenuItemPos := 0;
         int delMenuHandle;
         _menu_get_state(subMenuHandle, menuPos, 0, "P", "", delMenuHandle, "", "", "");

         // insert the list of user layouts into the delete menu
         if (!ulayouts._length()) {
            // no user layouts, just a non-selectable item
            _menu_insert(delMenuHandle, delSubMenuItemPos++, MF_GRAYED, "No user-defined layouts", 
                         "", "", "", "");
         } else {

            insertLayoutsIntoMenu(delMenuHandle, delSubMenuItemPos, ulayouts, 'deleteLayout', 
                                  'help Toolbar Layouts', 'Deletes the selected layout');
         }
      }

      // spacer
      _menu_insert(targetMenuHandle,subMenuItemPos++,0,'-');

      subMenuCategory = 'apply_and_set_default_layout';
      _menu_insert(targetMenuHandle, subMenuItemPos++, MF_ENABLED|MF_SUBMENU,
                   "Apply layout and set default", "", subMenuCategory, "", 
                   "Applies a layout to the current window and sets as the default for all new floating document windows");

      if(!_menu_find(menu_handle, subMenuCategory, subMenuHandle, menuPos, "C")) {
         appSubMenuItemPos := 0;
         int appMenuHandle;
         _menu_get_state(subMenuHandle, menuPos, 0, "P", "", appMenuHandle, "", "", "");

         if (ulayouts._length()) {
            insertLayoutsIntoMenu(appMenuHandle, appSubMenuItemPos, ulayouts, 'applyLayoutAndSetDefault', 
                                  'help Toolbar Layouts', 'Applies the selected layout and sets it as default for new floating document windows',
                                  def_default_floating_layout);

            _menu_insert(appMenuHandle,appSubMenuItemPos++,0,'-');
         }

         insertLayoutsIntoMenu(appMenuHandle, appSubMenuItemPos, slayouts, 'applyLayoutAndSetDefault', 
                               'help Toolbar Layouts', 'Applies the selected layout and sets it as default for new floating document windows',
                               def_default_floating_layout);
      }

      subMenuCategory = 'apply_all_and_set_default_layout';
      _menu_insert(targetMenuHandle, subMenuItemPos++, MF_ENABLED|MF_SUBMENU,
                   "Apply layout to all and set default", "", subMenuCategory, "", 
                   "Applies a layout to all floating windows and sets as the default for new floating document windows");

      if(!_menu_find(menu_handle, subMenuCategory, subMenuHandle, menuPos, "C")) {
         appAllSubMenuItemPos := 0;
         int appAllMenuHandle;
         _menu_get_state(subMenuHandle, menuPos, 0, "P", "", appAllMenuHandle, "", "", "");

         if (ulayouts._length()) {
            insertLayoutsIntoMenu(appAllMenuHandle, appAllSubMenuItemPos, ulayouts, 'applyLayoutToAll', 
                                  'help Toolbar Layouts', 'Applies the selected layout to all floating windows and sets it as default for new floating document windows',
                                  def_default_floating_layout);

            _menu_insert(appAllMenuHandle,appAllSubMenuItemPos++,0,'-');
         }

         insertLayoutsIntoMenu(appAllMenuHandle, appAllSubMenuItemPos, slayouts, 'applyLayoutToAll', 
                               'help Toolbar Layouts', 'Applies the selected layout to all floating windows and sets it as default for new floating document windows',
                               def_default_floating_layout);
      }
   }
}

static void insertLayoutsIntoMenu(int menuHandle, int& menuPos, _str (&layouts)[], _str command, _str help, _str msg, _str checked='')
{
   for (i := 0; i < layouts._length(); i++) {
      layout := layouts[i];
      flags := layout == checked ? MF_ENABLED|MF_CHECKED : MF_ENABLED;
      _menu_insert(menuHandle, menuPos++, flags, layout, 
                   command' 'layout, "", 
                   help, msg);
   }
}

/**
 * Callback called when a new floating document window is 
 * created.   
 */
void _on_create_floating_mdi()
{
   // get the new window
   mdi_wid := p_window_id;

   // make sure it is a floating document window
   if ( _MDIWindowHasMDIArea(mdi_wid) ) {

      // are there any other floating document windows?
      int wids[];
      _MDIGetMDIWindowList(wids);
      floatingCount := 0;
      for (i := 0; i < wids._length(); i++) {
         if (_MDIWindowHasMDIArea(wids[i]) && wids[i] != _mdi) {
            floatingCount++;
         }
      }

      // one for the mdi window, one for the floater - if this 
      // is more than 2, then there are other floating windows, 
      // and we do not apply the non-duplicate tool windows
      applyNonDupes := (floatingCount == 1);

      _str twNames[];
      _str encoding;
      getLayoutInfo(def_default_floating_layout, twNames, encoding);
      applyLayoutToWindow(mdi_wid, def_default_floating_layout, twNames, encoding, applyNonDupes);
   }
}

defeventtab _save_layout_as_form;

void _ctl_ok.on_create(_str (&layouts)[], _str defaultName, int defCheck)
{
   // fill up the combo box
   for (i := 0; i < layouts._length(); i++) {
      _ctl_combo._lbadd_item(layouts[i]);
   }

   // set the default
   _ctl_combo.p_text = defaultName;

   _ctl_def_check.p_value = defCheck;
}

void _ctl_ok.lbutton_up()
{
   // set the name as param1
   _param1 = _ctl_combo.p_text;
   _param2 = _ctl_def_check.p_value;

   p_active_form._delete_window(IDOK);
}
