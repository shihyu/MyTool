////////////////////////////////////////////////////////////////////////////////////
// $Revision: 41697 $
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
#import "main.e"
#import "menu.e"
#import "pip.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "upcheck.e"
#endregion

/** 
 * Enterprise Admin Options 
 * initial version SlickEdit 13.0.1 Sandra Gaskins 
 * updated version 15.0.1 for revised XML format 
 *  
 * To add new Enterprise Admin Options: 
 *  
 * 1.  Add a new flag to EnterpriseAdminOptions.  Make sure that it starts with 
 * "EAO_".
 *  
 * 2.  Add a case to the switch statement found in 
 * _eao_read_config_version1501().  Use the element name from Admin.xml as the 
 * key in the switch statement.  You do not need to update 
 * _eao_read_config_version1301(). 
 *  
 * 3.  Add a function to parse the element for your new option.  Add a call to 
 * this parse function to the switch statement you modified in step 2.  Also be 
 * sure and OR your flag(s) for that element into the handled variable.
 *  
 * 4.  Add a function to actually set the value.  It should take as a parameter 
 * the value parsed out of XML.  It should handle a blank value and set the 
 * default value when a blank parameter is sent. 
 *  
 * 5. Add a case to the switch statement in _eao_set_admin_option.  Use the flag
 * added in step 1 for the case.  Call the function added in step 4. 
 *  
 */

/**
 * Each of these flags corresponds to a Property in Admin.xml.  
 */
enum_flags EnterpriseAdminOptions {
   EAO_REGISTRATION,                   // Registration > menuItem
   EAO_AUTO_UPDATE_CHECK,              // AutoUpdate > check
   EAO_AUTO_UPDATE_MENU_ITEM,          // AutoUpdate > menuItem
   EAO_PIP_DEFAULT_ON,                 // Pip > onByDefault
   EAO_PIP_OPTIONS_VISIBLE,            // Pip > options
   EAO_AUTO_HOTFIX_PROMPT,             // AutoHotFix > prompt
   EAO_AUTO_HOTFIX_DIRECTORY,          // AutoHotFix > Directory
   EAO_AUTO_HOTFIX_MENU_ITEM,          // AutoHotFix > menuItem
};

// date that we checked Admin.xml file contents - if still has the same date, then
// we don't need to parse it again
_str def_eao_file_date = '';           

// flags which are DISABLED
int def_eao_disabled_flags = 0;

definit()
{
   // read the config now - we'll be setting the options after the mdi menu is loaded
   _eao_read_config();
}

/**
 * Reads the configuration file for the Enterprise Admin Options.  Sets 
 * appropriate values so that options can be enabled/disabled as necessary. 
 *  
 * The actual parsing is done by a version-specific callback. 
 */
static void _eao_read_config()
{
   // our file is in INSTALLDIR/sysconfig/options/Admin.xml
   file := get_env('VSROOT');
   _maybe_append_filesep(file);
   file :+= 'sysconfig'FILESEP'options'FILESEP'Admin.xml';

   // if file does not exist, then we can't do anything
   if (!file_exists(file)) {
      // if the date was already blank, then there is nothing really to do here
      if (def_eao_file_date != ''  && def_eao_file_date != 0) {
         // blank out the date
         def_eao_file_date = '';
         // reset all the options
         _eao_set_unhandled_options_to_default(0);
      }
   } else {
      // check the date of the file - if we're current, no need to do anything
      fileDate := _file_date(file, 'B');
      if (def_eao_file_date != '' && def_eao_file_date != 0 && def_eao_file_date == fileDate) return;

      // otherwise we save this date
      def_eao_file_date = fileDate;

      // reset our flags
      def_eao_disabled_flags = 0;

      // open up the file
      status := 0;
      xmlHandle := _xmlcfg_open(file, status);
      if (xmlHandle < 0) return;

      // see what version of the file this is...
      version := _version();
      index := _xmlcfg_find_child_with_name(xmlHandle, 0, 'AdminOptions');
      if (index > 0) {
         version = _xmlcfg_get_attribute(xmlHandle, index, 'Version');
      }

      // use the version to figure out which function to use to parse
      if (_version_compare(version, '15.0.1') >= 0) {
         _eao_read_config_version1501(xmlHandle);
      } else if (_version_compare(version, '13.0.1') >= 0) {
         _eao_read_config_version1301(xmlHandle);
      }

      // we're done with this ole file
      _xmlcfg_close(xmlHandle);
   }
}

/**
 * These methods are used to parse the Admin.xml file used for the Enterprise 
 * Admin Options.  Should the format of the XML file change, add another 
 * function named _eao_read_config_version<VERSION>, where VERSION is the 
 * SlickEdit version (minus the periods). 
 *  
 * Also be sure to add code to _eao_read_config that will direct appropriate 
 * versions to the new parsing function. 
 */
#region Enterprise Admin Options XML Parsing

/**
 * Reads the Admin.xml file when its version attribute is greater than or equal 
 * to 15.0.1. 
 * 
 * @param xmlHandle        handle to xml file
 */
static void _eao_read_config_version1501(int xmlHandle)
{
   // find our list of options
   adminOptions := _xmlcfg_find_child_with_name(xmlHandle, 0, 'AdminOptions');

   // go through each child and check out the elements
   handled := 0;
   child := _xmlcfg_get_first_child(xmlHandle, adminOptions);
   while (child > 0) {

      // we know what to do based on the element name
      name := _xmlcfg_get_name(xmlHandle, child);
      switch (name) { 
      case 'Registration':
         parseRegistrationElement(xmlHandle, child);
         handled |= EAO_REGISTRATION;
         break;
      case 'AutoUpdate':
         parseAutoUpdateElement(xmlHandle, child);
         handled |= (EAO_AUTO_UPDATE_CHECK | EAO_AUTO_UPDATE_MENU_ITEM);
         break;
      case 'Pip':
         parsePipElement(xmlHandle, child);
         handled |= (EAO_PIP_DEFAULT_ON | EAO_PIP_OPTIONS_VISIBLE);
         break;
      case 'AutoHotFix':
         parseAutoHotFixElement(xmlHandle, child);
         handled |= (EAO_AUTO_HOTFIX_PROMPT | EAO_AUTO_HOTFIX_DIRECTORY | EAO_AUTO_HOTFIX_MENU_ITEM);
         break;
      }

      child = _xmlcfg_get_next_sibling(xmlHandle, child);
   }
  
   _eao_set_unhandled_options_to_default(handled);
}

/**
 * Reads the Admin.xml file when its version attribute is between 13.0.1 and 
 * 15.0.1.  There is no need to add cases for new enterprise options to this 
 * function.  It is only kept for backwards compatability. 
 * 
 * @param xmlHandle        handle to xml file
 */
static void _eao_read_config_version1301(int xmlHandle)
{
   // read the Registration options
   _str categories[];
   _xmlcfg_find_simple_array(xmlHandle, '//Category', categories);

   handled := 0;

   // for each category, we look at the properties below
   for (i := 0; i < categories._length(); i++) {
      node := (int)categories[i];
      categoryName := _xmlcfg_get_attribute(xmlHandle, node, 'Name');

      // go through all the properties under this category
      index := _xmlcfg_get_first_child(xmlHandle, node);
      while (index > 0) {
         // get the value
         propertyValue := _xmlcfg_get_attribute(xmlHandle, index, 'Value');

         // get the property name
         propertyName := _xmlcfg_get_attribute(xmlHandle, index, 'Name');

         // use the category and property names to determine the flag
         function := categoryName'_'propertyName;
         flag := -1;
         switch (function) {
         case 'Registration_EnableRegistration':
            flag = EAO_REGISTRATION;
            break;
         case 'UpdateManager_AutoUpdateCheck':
            flag = EAO_AUTO_UPDATE_CHECK;
            break;
         case 'UpdateManager_AutoUpdateMenuItem':
            flag = EAO_AUTO_UPDATE_MENU_ITEM;
            break;
         case 'ProductImprovementProgram_OnByDefault':
            flag = EAO_PIP_DEFAULT_ON;
            break;
         case 'ProductImprovementProgram_OptionsVisible':
            flag = EAO_PIP_OPTIONS_VISIBLE;
            break;
         }

         if (flag >= 0) {
            _eao_set_admin_option(flag, propertyValue);
            handled |= flag;
         }

         // get the next property
         index = _xmlcfg_get_next_sibling(xmlHandle, index);
      }
   }

   _eao_set_unhandled_options_to_default(handled);
}

#endregion Enterprise Admin Options XML Parsing

/**
 * Sets all "Unhandled" enterprise options to their defaults (calls the set 
 * function with an empty string). 
 * 
 * @param handled             the flags of handled
 */
static void _eao_set_unhandled_options_to_default(int handled)
{
   // go through flags starting with MENU
   matchName := 'EAO-';
   index := name_match(matchName, 1, CONST_TYPE);
   while (index > 0) {

      // get the flag value so we can check to see if this flag is enabled or disabled
      flag := (int)name_info(index);

      if ((flag & handled) == 0) {
         _eao_set_admin_option(flag);
      }

      // next, please
      index = name_match(matchName, 0, CONST_TYPE);
   }
}

/**
 * Sets the enterprise option specified by the given flag to the given value. 
 * 
 * @param flag             option to set (see EnterpriseAdminOptions)
 * @param value            value to set it to, as parsed from XML.  Send a blank 
 *                         value to set it to default.
 */
static void _eao_set_admin_option(int flag, _str value = '')
{
   switch (flag) {
   case EAO_REGISTRATION:
      setRegistrationMenuItem(value);
      break;
   case EAO_AUTO_UPDATE_CHECK:
      setAutoUpdateCheck(value);
      break;
   case EAO_AUTO_UPDATE_MENU_ITEM:
      setAutoUpdateMenuItem(value);
      break;
   case EAO_PIP_DEFAULT_ON:
      setPipOnByDefault(value);
      break;
   case EAO_PIP_OPTIONS_VISIBLE:
      setPipOptionsVisible(value);
      break;
   case EAO_AUTO_HOTFIX_PROMPT:
      setAutoHotFixPrompt(value);
      break;
   case EAO_AUTO_HOTFIX_DIRECTORY:
      setAutoHotFixDirectory(value);
      break;
   case EAO_AUTO_HOTFIX_MENU_ITEM:
      setAutoHotFixMenuItem(value);
      break;
   }
}

/**
 * Handles the removal of menu items from the main menu (_mdi_menu) based on the
 * enterprise options specified in Admin.xml. 
 *  
 * This is an automatic callback. 
 * 
 * @param menuHandle                handle to loaded _mdi_menu
 * @param noChildWindows 
 */
void _init_menu_enterprise_options(int menuHandle, int noChildWindows)
{
   // find the help menu, we gotta remove some stuff
   index := _menu_find_loaded_menu_caption(menuHandle, 'Help', auto helpMenuHandle);
   if (index < 0) return;

   if (def_eao_disabled_flags & EAO_REGISTRATION) {
      _menuRemoveItemByCaption(helpMenuHandle, "Register Product...");
   }

   index = _menu_find_loaded_menu_caption(helpMenuHandle, 'Product Updates', auto updateMenuHandle);
   if (index < 0) return;

   if (def_eao_disabled_flags & EAO_AUTO_UPDATE_MENU_ITEM) {
      // delete the menu items that have to do with the auto update check
      _menuRemoveItemByCaption(updateMenuHandle, "New Updates...");
      _menuRemoveItemByCaption(updateMenuHandle, "Options...");
   }

   if (def_eao_disabled_flags & EAO_AUTO_HOTFIX_MENU_ITEM) {
      // delete the menu items that have to do with hot fixes
      _menuRemoveItemByCaption(updateMenuHandle, "Load Hot Fix...");
   }

   // do we have a valid auto hotfix directory?
   if (def_auto_hotfixes_path == '' || !def_hotfix_auto_prompt) {
      _menuRemoveItemByCaption(updateMenuHandle, "Apply Available Hot Fix...");
   }
}

/**
 * Parse the Enterprise Option(s) found within the Registration element.  This 
 * controls whether the registration menu item is available. 
 * 
 * @param xmlHandle                 handle to xml file
 * @param node                      element to parse
 */
static void parseRegistrationElement(int xmlHandle, int node)
{
   attrib := _xmlcfg_get_attribute(xmlHandle, node, 'menuItem', '1');
   setRegistrationMenuItem(attrib);
}

/**
 * Sets the Enterprise Option - Registration Menu Item
 * 
 * @param menuItem                  value from XML file
 */
static void setRegistrationMenuItem(_str value)
{
   if (!isinteger(value)) value = '1';

   if (value) {
      def_eao_disabled_flags &= ~EAO_REGISTRATION;
   } else {
      def_eao_disabled_flags |= EAO_REGISTRATION;
   }
}

/**
 * Parse the Enterprise Option(s) found within the AutoUpdate element.  This 
 * controls whether the auto update menu item is available and whether we 
 * perform the auto update check. 
 * 
 * @param xmlHandle                 handle to xml file
 * @param node                      element to parse
 */
void parseAutoUpdateElement(int xmlHandle, int node)
{
   // menu item
   menuItem := _xmlcfg_get_attribute(xmlHandle, node, 'menuItem', '1');
   setAutoUpdateMenuItem(menuItem);

   // do auto update check
   check := _xmlcfg_get_attribute(xmlHandle, node, 'check', '1');
   setAutoUpdateCheck(check);

}

/**
 * Sets the Enterprise Option - Auto Update Menu Item.
 * 
 * @param menuItem                  value from XML file
 */
static void setAutoUpdateMenuItem(_str menuItem)
{
   // show the menu item?
   if (!isinteger(menuItem)) menuItem = '1';

   if ((int)menuItem) {
      def_eao_disabled_flags &= ~EAO_AUTO_UPDATE_MENU_ITEM;
   } else {
      def_eao_disabled_flags |= EAO_AUTO_UPDATE_MENU_ITEM;
   }
}

/**
 * Sets the Enterprise Option - Auto Update Check.
 * 
 * @param check                  value from XML file
 */
static void setAutoUpdateCheck(_str check)
{
   // do auto update check?
   if (!isinteger(check)) check = '1';
   
   if ((int)check) {
      // set this to the default
      def_upcheck_fetch_interval = UPCHECK_DEFAULT_FETCH_INTERVAL;
   } else {
      // we set this to 0, which means NEVER!!!
      def_upcheck_fetch_interval = 0;  
   }
}

/**
 * Parse the Enterprise Option(s) found within the Pip element.  This controls 
 * whether the Product Improvement Program is on by default and whether PIP 
 * options are visible. 
 * 
 * @param xmlHandle                 handle to xml file
 * @param node                      element to parse
 */
static void parsePipElement(int xmlHandle, int node)
{
   attrib := _xmlcfg_get_attribute(xmlHandle, node, 'onByDefault');
   setPipOnByDefault(attrib);

   attrib = _xmlcfg_get_attribute(xmlHandle, node, 'options');
   setPipOptionsVisible(attrib);
}

/**
 * Sets the Enterprise Option - PIP On By Default.
 * 
 * @param onByDefault                  value from XML file
 */
static void setPipOnByDefault(_str onByDefault)
{
   if (!isinteger(onByDefault)) onByDefault = '1';

   if ((int)onByDefault) {
      _pip_start();
   } else {
      _pip_end();
   }
}

/**
 * Sets the Enterprise Option - PIP options visibility.
 * 
 * @param options                  value from XML file
 */
static void setPipOptionsVisible(_str options)
{
   if (!isinteger(options)) options = '1';

   def_pip_show_options = (((int)options) != 0);
}

/**
 * Parse the Enterprise Option(s) found within the AutoHotFix element.  This 
 * controls whether the we prompt before applying hot fixes we found and where 
 * we look for hot fixes. 
 * 
 * @param xmlHandle                 handle to xml file
 * @param node                      element to parse
 */
static void parseAutoHotFixElement(int xmlHandle, int node)
{
   menuItem := _xmlcfg_get_attribute(xmlHandle, node, 'menuItem');
   setAutoHotFixMenuItem(menuItem);

   prompt := _xmlcfg_get_attribute(xmlHandle, node, 'prompt');
   setAutoHotFixPrompt(prompt);

   dir := _xmlcfg_get_attribute(xmlHandle, node, 'directory');
   setAutoHotFixDirectory(dir);
}

/**
 * Sets the Enterprise Option - Auto Hot Fix Menu Item.
 * 
 * @param menuItem               value from xml file
 */
static void setAutoHotFixMenuItem(_str menuItem)
{
   // show the menu item?
   if (!isinteger(menuItem)) menuItem = '1';

   if ((int)menuItem) {
      def_eao_disabled_flags &= ~EAO_AUTO_HOTFIX_MENU_ITEM;
   } else {
      def_eao_disabled_flags |= EAO_AUTO_HOTFIX_MENU_ITEM;
   }
}

/**
 * Sets the Enterprise Option - Auto Hot Fix Prompt
 * 
 * @param prompt                  value from XML file
 */
static void setAutoHotFixPrompt(_str prompt)
{
   if (!isinteger(prompt)) prompt = '1';

   def_hotfix_auto_prompt = (((int)prompt) != 0);
}

/**
 * Sets the Enterprise Option - Auto Update Directory
 * 
 * @param dir                  value from XML file
 */
static void setAutoHotFixDirectory(_str dir)
{
#if __UNIX__
   dir = _unix_expansion(dir);
#endif

   _maybe_append_filesep(dir);
   dir = _replace_envvars(dir);

   def_auto_hotfixes_path = dir;
}
