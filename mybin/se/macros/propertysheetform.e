////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49909 $
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
#include "slick.sh"
#include "treeview.sh"
#require "se/options/AllLanguagesTable.e"
#require "se/options/DependencyTree.e"
#require "se/options/NumericProperty.e"
#require "se/options/Path.e"
#require "se/options/Property.e"
#require "se/options/PropertyGetterSetter.e"
#require "se/options/PropertyGroup.e"
#require "se/options/PropertySheet.e"
#require "se/options/Select.e"
#import "alllanguages.e"
#import "dlgman.e"
#import "guicd.e"
#import "guiopen.e"
#import "math.e"
#import "optionsxml.e"
#import "se/options/OptionsCheckBoxTree.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "treeview.e"

using se.options.DependencyTree;
using se.options.NumericProperty;
using se.options.Path;
using se.options.Property;
using se.options.PropertyGetterSetter;
using se.options.PropertyGroup;
using se.options.PropertySheet;
using se.options.Select;
using se.options.SettingInfo;
using se.options.AllLanguagesTable;
using namespace se.options;

#define BOOLEAN_PROPERTY_USES_SWITCH true

#define PROPERTY_SHEET           'propertySheet'
#define PROPERTY_DEPENDENCIES    'propertyDependencies'
#define HELP_HANDLE              'helpHandle'
/**
 * Determines what the purpose of this options dialog is - one of the 
 * OptionsPurpose enum. 
 */
#define PURPOSE         'optionsPurpose'
#define DEFAULT_DIALOG_BORDER 120          // default space between border of form and controls

#define PS_PROMPT       OP_QUICK_START + 1

#define NEUTRAL_PROPERTY_VALUE      'Languages Differ'

 // size of the modified property sheet column (column 0)
#define MODIFIED_OPTION_COLUMN_SIZE    600

double optColPerc = 0.45;           // percentage of remainding width that goes into option column (column 1)
boolean resizing = false;           // whether we are currently resizing the property sheet

defload()
{
   optColPerc = 0.45;
}

/**
 * Shows a property sheet dialog.  The info for the property sheet can either be 
 * retrieved from sysconfig/options/propertysheets.xml or sent in as an XML 
 * string.  The properties can then have their values set by the sheet or they 
 * can be returned in a key/value hashtable.  Keys will be retrieved from the 
 * property sheet xml (Key attribute or if none exists, Caption attribute).  
 * 
 * @param xmlInfoOrPSName              either the name of a propertysheet found 
 *                                     in propertysheets.xml (with attribute
 *                                     Name) or an xml string containing info
 * @param setValues                    true to have the property sheet set the 
 *                                     property values, false to just return
 *                                     them in a hash table.  If false,
 *                                     key/value pairs will be found in the
 *                                     hashtable in _param1.
 * 
 * @return                             0 for success, error code otherwise
 */
int showPropertySheetOptions(_str xmlInfoOrPSName, boolean setValues)
{
   // get our parser set up - make sure the XML is valid OR that we can find the right sheet info
   se.options.OptionsXMLParser parser;
   PropertySheet ps;
   status := 0;
   psName := '';
   if (substr(xmlInfoOrPSName, 1, 1) == '<') {
      status = parser.buildPropertySheetFromXMLString(xmlInfoOrPSName, ps);
      psName = ps.getCaption();
   } else {
      status = parser.buildPropertySheetFromFile(xmlInfoOrPSName, ps);
      psName = xmlInfoOrPSName;
   }
   // error
   if (status) return status;

   // show the property sheet
   psWid := show('-mdi _property_sheet_form', setValues ? OP_CONFIG : PS_PROMPT);
   psWid.p_name = '_'psName'_property_sheet_form';

   if (!setValues) psWid.maybeLoadPreviousPropertySheetValues(ps);

   psWid.loadProperties(ps);
   psWid.p_caption = ps.getCaption();

   status = (int)_modal_wait(psWid);

   return status;
}

/**
 * When using the Property Sheet to prompt for values (as opposed to getting and 
 * setting options), you can save the user's previous answers for prompts. 
 * These values are restored here. 
 * 
 * 
 * @param ps               PropertySheet
 */
void maybeLoadPreviousPropertySheetValues(PropertySheet &ps)
{
   for (i := 0; i < ps.getNumItems(); i++) {

      // make sure this is a property, not a group
      if (ps.getTypeAtIndex(i) != TMT_PROPERTY) continue;

      Property * p = ps.getPropertyByIndex(i);
      if (p != null) {
         key := p -> getKey();
         if (key == '') key = p -> getCaption();

         value := _retrieve_value(p_active_form.p_name'.'key);
         p -> setValue(value);
      }
   }
}

/**
 * This form is meant only as a template for the property sheet 
 * displayed on the options dialog. 
 */
defeventtab _property_sheet_form;

void _property_sheet_form.on_destroy()
{
   PropertySheet * ps = _property_sheet_form_get_property_sheet_data();

   if (ps != null) {
      langId := ps -> getLanguage();
      if (langId != '') {
         psName := getPropertySheetName();
         all_langs_mgr.removeFormListings(psName, langId);
      }
   }
}

void _property_sheet_form_init_for_options(PropertySheet &ps, int help = 0)
{
   if (help) _SetDialogInfoHt(HELP_HANDLE, help);

   loadProperties(ps);

   _ctl_help_panel.p_visible = _ctl_ok.p_visible =
      _ctl_cancel.p_visible = _ctl_help.p_visible = false;

   _ctl_property_sheet.p_height = p_height - (DEFAULT_DIALOG_BORDER * 2);

   _ctl_property_sheet.p_help = ps.getSystemHelp();
}

void _property_sheet_form_init_for_summary(PropertySheetItem (&ps)[], int help = 0)
{
   loadPropertySheetItems(ps, false);

   _ctl_help_panel.p_visible = _ctl_ok.p_visible =
      _ctl_cancel.p_visible = _ctl_help.p_visible = false;

   _ctl_property_sheet.p_height = p_height - (DEFAULT_DIALOG_BORDER * 2);

   if (help) _SetDialogInfoHt(HELP_HANDLE, help);
}

boolean _property_sheet_form_is_modified()
{
   PropertySheet * ps = _property_sheet_form_get_property_sheet_data();

   langId := ps -> getLanguage();
   if (langId == ALL_LANGUAGES_ID) {
      psName := getPropertySheetName();
      return all_langs_mgr.isAllLanguagesModified(psName);
   } else {
      return ps -> isModified();
   }
}

boolean _property_sheet_form_apply(int &changeEventsTriggered, _str (&appliedProperties)[])
{
   PropertySheet * ps = _property_sheet_form_get_property_sheet_data();
   psName := getPropertySheetName();
   applySuccess := true;

   for (i := 0; i < ps -> getNumItems(); i++) {
      // we don't want to try and apply a property group
      if (ps -> getTypeAtIndex(i) != TMT_PROPERTY) continue;

      Property *p = ps -> getPropertyByIndex(i);

      if (p != null && isPropertyModified(*p, i)) {

         propApplySuccess := false;

         SettingInfo info = p -> getSettingInfo();
         if (p -> getLanguage() == ALL_LANGUAGES_ID) {
            propName := getPropertyName(i);
            value := all_langs_mgr.getLanguageValue(psName, propName, ALL_LANGUAGES_ID);
            if (value != null) {
               propApplySuccess = setPropertyValueForAllLanguages(info, value);
            }
         } else {
            // set the new value
            if (p -> isCheckable()) {
               propApplySuccess = PropertyGetterSetter.setCheckedSetting(info, p -> getActualValue(), p -> getCheckState());
            } else {
               propApplySuccess = PropertyGetterSetter.setSetting(info, p -> getActualValue());
            }
         }

         if (propApplySuccess) {

            // apply date changed to XML DOM
            appliedProperties[appliedProperties._length()] = p -> getCaption();

            // check for any special events
            changeEventsTriggered |= p -> getChangeEventFlags();

            // set as applied
            p -> setApplied();

            // take away the "modified" mark in the tree
            treeIndex := i + 1;
            caption := _ctl_property_sheet._TreeGetCaption(treeIndex);
            caption = translate(caption, '', '*');
            _ctl_property_sheet._TreeSetCaption(treeIndex, caption);
         }

         applySuccess = applySuccess || propApplySuccess;
      }
   }

   return applySuccess;
}

void _property_sheet_form_mark_special_properties(_str (&attributes):[])
{
   PropertySheet * ps = _property_sheet_form_get_property_sheet_data();
   psName := getPropertySheetName();

   // go through the properties and see if we need to update them
   int i;
   for (i = 0; i < ps -> getNumItems(); i++) {

      // make sure this is a property, not a group
      if (ps -> getTypeAtIndex(i) != TMT_PROPERTY) continue;

      Property * p = ps -> getPropertyByIndex(i);
      treeIndex := i + 1;

      if (p != null) {

         // we might need to refresh the value for language properties 
         // (because of possible changes to other languages and ALL LANGUAGES)
         if (p -> getLanguage() != '') {
            if (setLanguagePropertyValue((*p), psName, i, false)) {
               caption := getPropertyTreeCaption(*p, i);
               _ctl_property_sheet._TreeSetCaption(treeIndex, caption);
            }
         }

         pIndex := p -> getIndex();

         // first set it to a neutral color
         _ctl_property_sheet._TreeSetRowColor(treeIndex, 0, 0, F_INHERIT_FG_COLOR | F_INHERIT_BG_COLOR);

         if (attributes._indexin(pIndex)) {
            // attribute string = bgColor fgColor icon flags
            typeless bgColor, fgColor, icon, flags;
            parse attributes:[pIndex] with bgColor',' fgColor',' icon',' flags;

            // set up the colors for the row
            colorFlags := 0;
            if (!isinteger(bgColor)) {
               bgColor = 0;
               colorFlags |= F_INHERIT_BG_COLOR;
            }
            if (!isinteger(fgColor)) {
               fgColor = 0;
               colorFlags |= F_INHERIT_FG_COLOR;
            }
            _ctl_property_sheet._TreeSetRowColor(treeIndex, fgColor, bgColor, colorFlags);

            // set up the icon and other markings
            int sc, bm1, bm2, curFlags;
            _ctl_property_sheet._TreeGetInfo(treeIndex, sc, bm1, bm2, curFlags);
            if (!isinteger(flags)) flags = 0;
            if (isinteger(icon)) {
               bm1 = bm2 = icon;
            }
            _ctl_property_sheet._TreeSetInfo(treeIndex, sc, bm1, bm2, curFlags | flags);
         }

         // if it's a color node, we gots to show the color!
         if (p -> _typename() == 'se.options.ColorProperty') {
            color := p -> getActualValue();
            if (color != null) {
               _ctl_property_sheet._TreeSetColor(treeIndex, 2, 0, hex2dec(color), F_INHERIT_FG_COLOR);
            }
         }
      }
   }
}

void loadProperties(PropertySheet &ps)
{
   _SetDialogInfoHt(PROPERTY_SHEET, ps);
   PropertySheet * psPtr = _property_sheet_form_get_property_sheet_data();

   _str values:[];

   _ctl_property_sheet._TreeBeginUpdate(TREE_ROOT_INDEX);

   numCols := _ctl_property_sheet._TreeGetNumColButtons();

   isAllLangs := (psPtr -> getLanguage() == ALL_LANGUAGES_ID);

   // now let's get the data in there!
   firstProp := 0;

   for (i := 0; i < psPtr -> getNumItems(); i++) {
      type := psPtr -> getTypeAtIndex(i);
      if (type == TMT_GROUP) {
         PropertyGroup *pg = psPtr -> getPropertyGroupByIndex(i);
         if (pg != null) {
            caption := \tpg -> getCaption()\t;
            // this is hacky - if we don't have any text in the last column, then the color
            //  will not extend all the way out
            if (numCols == 4) {
               caption :+= \t;
            }
            rowID := _ctl_property_sheet._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0, -1);

            // change the background color to be gray
            _ctl_property_sheet._TreeSetRowColor(rowID, 0, PROPERTY_GROUP_COLOR, F_INHERIT_FG_COLOR);

            int sc, bm1, bm2, flags, line;
            _ctl_property_sheet._TreeGetInfo(rowID, sc, bm1, bm2, flags);
            _ctl_property_sheet._TreeSetInfo(rowID, sc, bm1, bm2, flags | TREENODE_BOLD);

         }
      } else if (type == TMT_PROPERTY) {
         Property * p = psPtr -> getPropertyByIndex(i);

         addPropertyToSheet(*p, i, values, !isAllLangs);
         if (!firstProp) firstProp = i + 1;
      }
   }

   _ctl_property_sheet._TreeEndUpdate(TREE_ROOT_INDEX);

   // select the first property (not property group)
   _ctl_property_sheet._TreeSetCurIndex(firstProp);
   _ctl_property_sheet._TreeSelectLine(firstProp, true);
   _ctl_property_sheet.call_event(CHANGE_SELECTED, firstProp, _ctl_property_sheet, ON_CHANGE, 'W');
}

void loadPropertySheetItems(PropertySheetItem (&ps)[], boolean enabled = true)
{
   _ctl_property_sheet._TreeBeginUpdate(TREE_ROOT_INDEX);

   // now let's get the data in there!
   for (i := 0; i < ps._length(); i++) {
      caption := ''\tps[i].Caption\tps[i].Value;
      rowID := _ctl_property_sheet._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, enabled ? 0 : TREENODE_DISABLED, 0);
   }

   _ctl_property_sheet._TreeEndUpdate(TREE_ROOT_INDEX);

   // select the first property (not property group)
   _ctl_property_sheet._TreeSetCurIndex(0);
   _ctl_property_sheet._TreeSelectLine(0, true);
}

/**
 * Adds a property to the GUI property sheet.
 * 
 * @param tree       window id of tree (property sheet)
 * @param p          property to be added
 * @param index      index of property in property sheet
 * @param values     hashtable of property captions and values so far (for dependencies)
 * @param parent     index to add property after
 */
boolean addPropertyToSheet(Property &p, int index, _str (&values):[], boolean useSwitch = BOOLEAN_PROPERTY_USES_SWITCH)
{
   // get the value of this property
   if (p.getActualValue() == null) {
      setPropertyValue(p, index);
   }

   // keep track of caption/value pairs for dependencies
   values:[p.getCaption()] = p.getDisplayValue();

   treeIndex := index + 1;

   caption := getPropertyTreeCaption(p, index);

   rowID := _ctl_property_sheet._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0, p.getIndex());

   if (values != null && !p.m_dependencies.evaluate(values)) {
      // check dependencies to see if this item should be disabled
      disableProperty(treeIndex);
   }

   // change the background color to be the one we've selected
   _str choices[];
   switch (p.getPropertyType()) {
   case COLOR_PROPERTY:
      _ctl_property_sheet._TreeSetColor(rowID, 2, 0, hex2dec(p.getActualValue()), F_INHERIT_FG_COLOR);
      _ctl_property_sheet._TreeSetNodeEditStyle(rowID, 2, TREE_EDIT_BUTTON);
      break;
   case SELECT_PROPERTY:
      ((Select)p).getChoices(choices);
      _ctl_property_sheet._TreeSetComboDataNodeCol(rowID, 2, choices);
      _ctl_property_sheet._TreeSetNodeEditStyle(rowID, 2, TREE_EDIT_COMBOBOX);
      break;
   case BOOLEAN_PROPERTY:
      if (useSwitch) {
         purpose := _GetDialogInfoHt(PURPOSE);
         // Import/Export case: Read-only values, so show text instead of Switch
         if( purpose != OP_EXPORT && purpose != OP_IMPORT ) {
            value := ( p.getActualValue() == "True" );
            _ctl_property_sheet._TreeSetSwitchState(rowID,2,value);
         }
      } else {
         ((BooleanProperty)p).getChoices(choices);
         _ctl_property_sheet._TreeSetComboDataNodeCol(rowID, 2, choices);
         _ctl_property_sheet._TreeSetNodeEditStyle(rowID, 2, TREE_EDIT_COMBOBOX);
      }
      break;
   case DIRECTORY_PATH_PROPERTY:
   case FILE_PATH_PROPERTY:
      _ctl_property_sheet._TreeSetNodeEditStyle(rowID, 2, TREE_EDIT_TEXTBOX | TREE_EDIT_BUTTON);
      break;
   }

   if (p.isCheckable()) {
      _ctl_property_sheet._TreeSetCheckState(rowID, p.getCheckState());
   }

   // add any dependencies this option may have to other options
   _str optDeps:[];
   p.m_dependencies.getOptionTypes(optDeps);
   if (!optDeps._isempty()) {

      // me may need to create the dependency tree if nothing else has done it
      DependencyTree * dt = getPropertyDependencyTree();
      if (dt == null) {
         DependencyTree newTree;
         _SetDialogInfoHt(PROPERTY_DEPENDENCIES, newTree);
         dt = getPropertyDependencyTree();
      }

      // now add our dependencies...we are so dependent.
      foreach (auto depCaption => auto depValue in optDeps) {
         dt -> addDependency(depCaption, depValue, treeIndex);
      }
   }

   return true;
}

/**
 * Determines if the property specified has been modified from its original 
 * value.  Handles ALL LANGUAGES special cases. 
 * 
 * @param p                Property
 * @param propIndex        index of property in the Property Sheet
 * 
 * @return                 true if the property has been modified, false 
 *                         otherwise
 */
static boolean isPropertyModified(Property &p, int propIndex)
{
   if (p.getLanguage() == ALL_LANGUAGES_ID) {
      psName := getPropertySheetName();
      propName := getPropertyName(propIndex);

      return all_langs_mgr.hasAllLanguagesBeenSetForControl(psName, propName);
   } else {
      return p.isModified();
   }
}

/**
 * Builds and returns a property's caption as it should appear in the 
 * PropertySheet GUI.  Columns are separated by tabs, so the return value can be 
 * sent directly to _TreeSetCaption(). 
 * 
 * @param p                Property
 * @param propIndex        index of property in tree
 * 
 * @return 
 */
static _str getPropertyTreeCaption(Property &p, int propIndex)
{
   caption := '';

   // first we check if it's modified - then we need an asterisk
   if (isPropertyModified(p, propIndex)) {
      caption = '*'\t;
   } else {
      caption = \t;
   }

   caption :+= p.getCaption()\t;

   if (p.getActualValue() != null) {
      caption :+= p.getDisplayValue();
   } else {
      // this is hopefully an ALL LANGUAGES setting where the languages did not all match
      caption :+= NEUTRAL_PROPERTY_VALUE;
   }

   return caption;
}

static void setPropertyValue(Property &p, int propIndex)
{
   SettingInfo info = p.getSettingInfo();
   if (info != null) {
      if (p.isCheckable()) {
         PropertyGetterSetter.getCheckedSetting(info, auto value, auto checkState);
         p.setValue(value);
         p.setCheckState(checkState);
      } else {
         if (info.Language == '') {
            p.setValue(PropertyGetterSetter.getSetting(info));
         } else {
            // we might have to do some special footwork for a language
            psName := getPropertySheetName();
            setLanguagePropertyValue(p, psName, propIndex);
         }
      }
   }
}

static boolean setLanguagePropertyValue(Property &p, _str psName, int propIndex, boolean mustSet = true)
{
   didSet := false;

   SettingInfo info = p.getSettingInfo();
   // we might have to do some special footwork for a language
   if (info.Language == ALL_LANGUAGES_ID) {

      propName := getPropertyName(propIndex);
      if (mustSet || all_langs_mgr.doesAnyLanguageOverrideAllLanguages(psName, propName)) {
         value := getPropertyValueForAllLanguages(psName, propName, info);
         p.setValue(value);
         didSet = true;
      }
   } else {
      // this is just a plain old language, but we need to see if 
      // ALL LANGUAGES might have an overriding value
      propName := getPropertyName(propIndex);
      if (all_langs_mgr.doesAllLanguagesOverride(psName, propName, info.Language)) {
         p.setValue(all_langs_mgr.getLanguageValue(psName, propName, ALL_LANGUAGES_ID));
         didSet = true;
      } else if (mustSet) {
         // nothing special here, just get the value, okay?
         if (p.isCheckable()) {
            PropertyGetterSetter.getCheckedSetting(info, auto value, auto checkState);
            p.setValue(value);
            p.setCheckState(checkState);
         } else {
            p.setValue(PropertyGetterSetter.getSetting(info));
         }
         didSet = true;
      } 
   } 

   return didSet;
}

/**
 * Retrieves the value of a Property for all languages.  If all the languages do 
 * not have the same value for the property, then null is returned.  If the 
 * value has been changed (but not yet applied) in this session of the options 
 * dialog, then the changed value is used. 
 * 
 * @param psName                    name of property sheet (see 
 *                                  getPropertySheetName())
 * @param propName                  name of property (see getPropertyName())
 * @param info                      SettingInfo object used to retrieve the 
 *                                  current value
 * @param exclusions                any languages which should be excluded
 * 
 * @return                          string representation of current value for 
 *                                  all languages, null if all languages do not
 *                                  match
 */
static _str getPropertyValueForAllLanguages(_str psName, _str propName, SettingInfo &info, _str exclusions = '')
{
   SettingInfo infoCopy = info;

   allLangsValue := all_langs_mgr.getLanguageValue(psName, propName, ALL_LANGUAGES_ID);
   _str value = null;

   // go through all the languages
   langId := getFirstLangId();
   while (langId != '') {

      // first determine if we exclude this language
      if (!pos(','langId',', ','exclusions',')) {

         // check if the value has been saved in the all languages table
         langValue := all_langs_mgr.getLanguageValue(psName, propName, langId);
         if (langValue == null) {
            if (allLangsValue != null) {
               langValue = allLangsValue;
            } else {
               infoCopy.Language = langId;
               langValue = PropertyGetterSetter.getSetting(infoCopy);
            }
         }

         // now that we have our value, we can compare it to all the other values!
         if (value == null) {
            value = langValue;
         } else if (value != langValue) {
            value = null;
            break;
         } 
      }

      langId = getNextLangId();
   }

   return value;
}

/**
 * Sets a Property for all languages.
 * 
 * @param info             SettingInfo object used to set the Property value
 * @param value            value to be set
 * @param exclusions       any languages which are excluded
 * 
 * @return                 true if property was set successfully for AT LEAST 
 *                         ONE language
 */
static boolean setPropertyValueForAllLanguages(SettingInfo &info, _str value, _str exclusions = '')
{
   SettingInfo infoCopy = info;
   success := false;

   // go through all the languages
   langId := getFirstLangId();
   while (langId != '') {

      // first determine if we exclude this language
      if (!pos(','langId',', ','exclusions',')) {

         infoCopy.Language = langId;
         success = PropertyGetterSetter.setSetting(infoCopy, value) || success;

      }

      langId = getNextLangId();
   }

   return success;
}

/**
 * Retrieves a pointer to the PropertySheet object associated with this property
 * sheet form. 
 * 
 * @return                 pointer to a PropertySheet
 */
PropertySheet * _property_sheet_form_get_property_sheet_data()
{
   return _GetDialogInfoHtPtr(PROPERTY_SHEET);
}

/**
 * Retrieves a pointer to the PropertyDependencyTree used to disable and enable 
 * properties on this property sheet form. 
 * 
 * @return                 pointer to a PropertyDependencyTree
 */
DependencyTree * getPropertyDependencyTree()
{
   return _GetDialogInfoHtPtr(PROPERTY_DEPENDENCIES);
}

/**
 * Retrieves the window id of the help label for the property 
 * sheet.  On standalone property sheets, this is on the form 
 * itself.  On embedded property sheets, this is often on the 
 * parent form (e.g. the options dialog)
 * 
 * @return int 
 */
int getHelpLabelHandle()
{
   return _GetDialogInfoHt(HELP_HANDLE);
}

/**
 * Determines if this property sheet form is currently embedded in the options 
 * dialog or if it is a free agent. 
 * 
 * @return                 true if the property sheet is embedded in the 
 *                         options, false if it is a standalone form
 */
static boolean isPropertySheetEmbeddedInOptions()
{
   return (!_ctl_ok.p_visible);
}

/**
 * Retrieves the name for a property.  This name, along with the property
 * sheet name, is used to identify this specific property for All 
 * Languages.  See getPropertySheetName().
 * 
 * @param propIndex        index of property within the current PropertySheet 
 *                         (0-based)
 * 
 * @return                 "name" of property
 */
static _str getPropertyName(int propIndex)
{
   PropertySheet * ps = _property_sheet_form_get_property_sheet_data();
   caption := ps -> getPropertyPath(propIndex);
   caption = stranslate(caption, '', ' ');

   return caption;
}

/**
 * Retrieves the name for a property sheet.  This name is used to 
 * identify this specific property sheet for All Languages. 
 * 
 * @return                 "name" of property
 */
static _str getPropertySheetName()
{
   PropertySheet * ps = _property_sheet_form_get_property_sheet_data();
   caption := ps -> getCaption();
   caption = stranslate(caption, '', ' ');

   return caption;
}

/**
 * Create event for property sheet.  Initializes tree.
 */
void _property_sheet_form.on_create(int purpose = OP_CONFIG) 
{
   form := 0;
   protect := 0;
   switch (purpose) {
   case OP_IMPORT:
      _ctl_property_sheet._TreeSetColButtonInfo(0, MODIFIED_OPTION_COLUMN_SIZE, TREE_BUTTON_AL_CENTER | TREE_BUTTON_FIXED_WIDTH, -1, 'Import');
      _ctl_property_sheet._TreeSetColButtonInfo(1, 3000, -1, -1, 'Option');
      _ctl_property_sheet._TreeSetColButtonInfo(2, 3000, -1, -1, 'Value');
      
      form = getOptionsFormFromEmbeddedDialog();
      protect = _GetDialogInfoHt(PROTECT, form);
      if (protect) {
         _ctl_property_sheet._TreeSetColButtonInfo(3, MODIFIED_OPTION_COLUMN_SIZE * 2, -1, -1, 'Protections');
      }

      break;
   case OP_EXPORT:
      _ctl_property_sheet._TreeSetColButtonInfo(0, MODIFIED_OPTION_COLUMN_SIZE, TREE_BUTTON_AL_CENTER | TREE_BUTTON_FIXED_WIDTH, -1, 'Export');
      _ctl_property_sheet._TreeSetColButtonInfo(1, 3000, -1, -1, 'Option');
      _ctl_property_sheet._TreeSetColButtonInfo(2, 3000, -1, -1, 'Value');

      form = getOptionsFormFromEmbeddedDialog();
      protect = _GetDialogInfoHt(PROTECT, form);
      if (protect) {
         _ctl_property_sheet._TreeSetColButtonInfo(3, MODIFIED_OPTION_COLUMN_SIZE * 2, 0, -1, 'Protections');
         _ctl_property_sheet._TreeSetColEditStyle(3, TREE_EDIT_COMBOBOX);
      }
      break;
   default:
      _ctl_property_sheet._TreeSetColButtonInfo(0, MODIFIED_OPTION_COLUMN_SIZE, TREE_BUTTON_AL_RIGHT | TREE_BUTTON_FIXED_WIDTH, -1, '');
      _ctl_property_sheet._TreeSetColButtonInfo(1, 3000, -1, -1, 'Option');
      _ctl_property_sheet._TreeSetColButtonInfo(2, 3000, 0, -1, 'Value');
      _ctl_property_sheet._TreeSetColEditStyle(2, TREE_EDIT_TEXTBOX);
      break;
   }

   _SetDialogInfoHt(PURPOSE, purpose);

   size_property_sheet_columns();
   _SetDialogInfoHt(HELP_HANDLE, _ctl_help_panel);
   _ctl_help_panel._minihtml_UseDialogFont();
   _ctl_help_panel.p_backcolor = 0x80000022;
}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window(COMMAND_CANCELLED_RC);
}

void _ctl_ok.lbutton_up()
{
   // find out if we are setting our options or merely prompting for values here
   purpose := _GetDialogInfoHt(PURPOSE);
   if (purpose == OP_CONFIG) {
      // we want to apply all our settings now
      _property_sheet_form_apply(null, null);
   } else {
      // we are just prompting for values, so compile our caption/value pairs and return them
      PropertySheet * ps = _property_sheet_form_get_property_sheet_data();
      _str values:[];

      for (i := 0; i < ps -> getNumItems(); i++) {

         // make sure this is a property, not a group
         if (ps -> getTypeAtIndex(i) != TMT_PROPERTY) continue;

         Property * p = ps -> getPropertyByIndex(i);
         treeIndex := i + 1;

         if (p != null) {
            key := p -> getKey();
            if (key == '') key = p -> getCaption();
            values:[key] = p -> getActualValue();

            _append_retrieve(0, values:[key], p_active_form.p_name'.'key);
         }
      }

      _param1 = values;
      p_active_form._delete_window(0);
   }
}

void _property_sheet_form.on_got_focus()
{
   if (isPropertySheetEmbeddedInOptions()) {
      _ctl_property_sheet._set_focus();
   }
}

/**
 * Resize event of a property sheet form.  Resizes the contained
 * property sheet.
 */
void _property_sheet_form.on_resize()
{
   _ctl_property_sheet.p_visible = false;
   // available width and height
   width := _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width) - (DEFAULT_DIALOG_BORDER * 2);
   height := _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height) - (DEFAULT_DIALOG_BORDER * 2);

   // resize the property sheet to match
   if (_ctl_property_sheet.p_width != width) {
      origTreeWidth := _ctl_property_sheet.p_width;
      widthDiff := width - origTreeWidth;
      _ctl_property_sheet.p_width = _ctl_help_panel.p_width = width;
      _ctl_ok.p_x += widthDiff;
      _ctl_cancel.p_x += widthDiff;
      _ctl_help.p_x += widthDiff;

      // no point in doing this if the columns haven't been loaded up yet
      if (_ctl_property_sheet._TreeGetNumColButtons() >= 3) {
         _ctl_property_sheet.scale_property_sheet_columns(origTreeWidth);
      }

      // temporary hack to make the tree show up after we resize
      if (!_ctl_property_sheet._TreeUp()) {
         _ctl_property_sheet._TreeDown();
      } else {
         _ctl_property_sheet._TreeDown();
         _ctl_property_sheet._TreeUp();
      }
   }

   if (isPropertySheetEmbeddedInOptions()) {
      if (_ctl_property_sheet.p_height != height) {
         _ctl_property_sheet.p_height = height;
      }
   } else {
      heightDiff := height - (_ctl_ok.p_y + _ctl_ok.p_height);
      if (heightDiff) {
         _ctl_ok.p_y += heightDiff;
         _ctl_cancel.p_y += heightDiff;
         _ctl_help.p_y += heightDiff;
         _ctl_help_panel.p_y += heightDiff;

         _ctl_property_sheet.p_height += heightDiff;
      }
   }

   _ctl_property_sheet.p_visible = true;
}

static void scale_property_sheet_columns(int origWidth)
{
   // subtract out the first column - we are leaving that alone
   colWidth := _TreeColWidth(0);
   origWidth -= colWidth;
   curWidth := p_width - colWidth;

   // calculate the change in the width
   double ratio = (double)curWidth / (double)origWidth;

   // scale all the columns
   n := _TreeGetNumColButtons();
   for (i := 1; i < n; ++i) {
      colWidth = _TreeColWidth(i);

      colWidth = (int)(colWidth * ratio);

      _TreeColWidth(i, colWidth);
   }
}

/**
 * Saves the proportional sizes of the columns in the property sheet so that
 * they can be restored later.
 */
void save_property_sheet_column_sizes()
{
   totalWidth := _ctl_property_sheet.p_width;
   totalWidth -= MODIFIED_OPTION_COLUMN_SIZE;

   // save the other two columns as percentage of the rest of the whole (for resizing purposes)
   width := _ctl_property_sheet._TreeColWidth(1);
   optColPerc = ((double)width / totalWidth);
}

/**
 * Resizes property sheet columns to keep their relative sizes.
 */
void size_property_sheet_columns()
{
   // property sheet has three columns...usually!
   totalWidth := _ctl_property_sheet.p_width;

   if (_ctl_property_sheet._TreeGetNumColButtons() == 3) {
      // the first one should always be width = modColSize
      totalWidth -= MODIFIED_OPTION_COLUMN_SIZE;

      // the other two should be 45/55 of the remaining space
      col1Width := (int)(totalWidth * optColPerc);
      _ctl_property_sheet._TreeSetColButtonInfo(0, MODIFIED_OPTION_COLUMN_SIZE);
      _ctl_property_sheet._TreeSetColButtonInfo(1, col1Width);
      _ctl_property_sheet._TreeSetColButtonInfo(2, totalWidth - col1Width);
   } else {
      // we've got 4!
      totalWidth -= (MODIFIED_OPTION_COLUMN_SIZE * 3);
      col1Width := (int)(totalWidth * optColPerc);
      _ctl_property_sheet._TreeSetColButtonInfo(0, MODIFIED_OPTION_COLUMN_SIZE);
      _ctl_property_sheet._TreeSetColButtonInfo(1, col1Width);
      _ctl_property_sheet._TreeSetColButtonInfo(2, totalWidth - col1Width);
      _ctl_property_sheet._TreeSetColButtonInfo(3, (MODIFIED_OPTION_COLUMN_SIZE * 2));
   }
}

// Calls the option change callback with this property,
// if it exists.
static void maybe_fire_change_callback(Property *p)
{

   typeless idx = _GetDialogInfoHt(OPTIONS_CHANGE_CALLBACK_KEY);


   if (idx != null) {
      call_index(p, (int)idx);
      return;
   }

   // We may be embedded in another form.  Do a quick search,
   // and squirrel away anything we find.
   int form = p_active_form.p_parent;

   while (form && form.p_object != OI_FORM) {
      form = form.p_parent;
   }

   idx = _GetDialogInfoHt(OPTIONS_CHANGE_CALLBACK_KEY, form);

   if (idx != null) {
      call_index(p, (int)idx);
      _SetDialogInfoHt(OPTIONS_CHANGE_CALLBACK_KEY, (int)idx);
   }
}

/**
 * Changes the check state value for a property with an attached
 * checkbox.
 *
 * @param treeIndex
 * @param checkState
 */
static void changePropertyCheckState(int treeIndex, int checkState)
{
   PropertySheet * ps = _property_sheet_form_get_property_sheet_data();

   psIndex := treeIndex - 1;
   if (ps -> getTypeAtIndex(psIndex) != TMT_PROPERTY) return;

   Property * p = ps -> getPropertyByIndex(psIndex);
   p -> updateCheckState(checkState);

   maybe_fire_change_callback(p);

   // if our value was modified from its original state, then we need to show a star
   newCaption := getPropertyTreeCaption(*p, psIndex);
   _ctl_property_sheet._TreeSetCaption(treeIndex, newCaption);
}

/**
 * Handles change events for individual properties.  Updates the value in our 
 * data storage and any GUI changes that happen. 
 * 
 * @param treeIndex           index of property being changed in tree
 * @param caption             the new caption of the "Value" column - used with 
 *                            combo boxes and textboxes to determine what the
 *                            user changed the value to
 */
static void changePropertyValue(int treeIndex, _str caption = '')
{
   // if they just "changed" the property to the neutral value, then we don't care
   if (caption == NEUTRAL_PROPERTY_VALUE) return;

   PropertySheet * ps = _property_sheet_form_get_property_sheet_data();

   psIndex := treeIndex - 1;
   if (ps -> getTypeAtIndex(psIndex) != TMT_PROPERTY) return;

   newCaption := '';
   Property * p = ps -> getPropertyByIndex(psIndex);

   // now figure out what to do about it
   value := '';
   curValue := '';

   if (p -> hasClickEvent()) {
      // some properties have specific events that we call when they are double-clicked
      value = call_index(p -> getActualValue(), p -> getClickEvent());
   } else {
      switch (p -> getPropertyType()) {
      case BOOLEAN_PROPERTY:
         value = caption;
         curValue = p -> getActualValue();
         break;
      case COLOR_PROPERTY:
         curValue = p -> getActualValue();
         value = caption;
         break;
      case NUMERIC_PROPERTY:
         value = caption;
         NumericProperty n = (NumericProperty)*p;
         _str error = n.validateNumeric(value);
         if (error != '') {
            error = _message_box(error, '', MB_OK | MB_ICONEXCLAMATION);
            value = '';
         }
         curValue = p -> getActualValue();
         break;
      case FILE_PATH_PROPERTY:
      case DIRECTORY_PATH_PROPERTY:
         Path pathP = (Path)*p;
         if (caption == '') {
            caption = DEFAULT_PATH;
            value = '';
         } else {
            value = caption;
         }
         curValue = p -> getActualValue();
         break;
      case SELECT_PROPERTY:
         value = caption;
         curValue = p -> getDisplayValue();
         break;
      case TEXT_PROPERTY:
         value = caption;
         curValue = p -> getActualValue();
         break;
      }
   }

   if ((value != '' || caption == DEFAULT_PATH) && value != curValue) {
      p -> updateValue(value);
      maybe_fire_change_callback(p);

      langId := p -> getLanguage();
      if (langId != '') {
         psName := getPropertySheetName();
         propName := getPropertyName(psIndex);
         if (p -> isModified()) {
            all_langs_mgr.setLanguageValue(psName, propName, langId, p -> getActualValue());
         } else {
            if (langId != ALL_LANGUAGES_ID || p -> getDisplayValue() != NEUTRAL_PROPERTY_VALUE) all_langs_mgr.removeLanguageValue(psName, propName, langId);
         }
      }

      // do this after we may need to remove the language value - in case the all languages status changes
      changePropertyInTree(ps, psIndex);

   } else value = '';
}

/**
 * Handles the GUI aspect of changing a property.  Updates the modified status 
 * (asterisk in the first column) and the new caption.
 * 
 * @param ps               pointer to the current PropertySheet
 * @param psIndex          index of property that changed
 */
static void changePropertyInTree(PropertySheet * ps, int psIndex)
{
   // we check to see if it's modified - we might just be changing back to our original value
   Property * p = ps -> getPropertyByIndex(psIndex);
   newCaption := getPropertyTreeCaption(*p, psIndex);

   treeIndex := psIndex + 1;
   _ctl_property_sheet._TreeSetCaption(treeIndex, newCaption);
   if (p -> getPropertyType() == COLOR_PROPERTY) {
      _ctl_property_sheet._TreeSetColor(treeIndex, 2, 0, hex2dec(p -> getActualValue()), F_INHERIT_FG_COLOR);
      _ctl_property_sheet._TreeRefresh();
   }

   checkPropertyForDependencies(p -> getCaption(), p -> getDisplayValue());
}

/**
 * Determines if a property has any other properties depending on its value.  If 
 * so, determines if these properties should be enabled or disabled based on the 
 * option's new value. 
 * 
 * @param caption             caption of property that changed
 * @param value               new value of property
 */
static void checkPropertyForDependencies(_str caption, _str value)
{
   DependencyTree * dt = getPropertyDependencyTree();
   if (dt != null && dt -> isDependedOn(caption)) {
      int pal[];
      dt -> getDependencies(caption, pal);

      if (!pal._isempty()) {

         // we need the property sheet to get the properties to reevaluate their dependencies
         PropertySheet * ps = _property_sheet_form_get_property_sheet_data();

         int treeIndex;
         foreach (treeIndex in pal) {
            psIndex := treeIndex - 1;
            Property * dependentP = ps -> getPropertyByIndex(psIndex);
            if (dependentP != null) {
               if (dependentP -> m_dependencies.reevaluate(caption, value)) {
                  enableProperty(treeIndex);
               } else {
                  disableProperty(treeIndex);
               }
            }
         }
      }
   }
}

/** 
 * Enables a property by turning its color to black.
 * 
 */
static void enableProperty(int treeIndex)
{
   int sc, bm1, bm2, flags;
   _ctl_property_sheet._TreeGetInfo(treeIndex, sc, bm1, bm2, flags);

   // only change it if the node is currently disabled
   if (flags & TREENODE_DISABLED) {
      _ctl_property_sheet._TreeSetInfo(treeIndex, sc, bm1, bm2, flags & ~TREENODE_DISABLED);
   }
}

/** 
 * Disables a property by turning its color to gray.
 * 
 */
static void disableProperty(int treeIndex)
{
   int sc, bm1, bm2, flags;
   _ctl_property_sheet._TreeGetInfo(treeIndex, sc, bm1, bm2, flags);

   if ((flags & TREENODE_DISABLED) == 0) {
      _ctl_property_sheet._TreeSetInfo(treeIndex, sc, bm1, bm2, flags | TREENODE_DISABLED);
   }
}

/**
 * Mark this property as protected, which prevents the user from editing it.
 * 
 * @param treeWid                window id of property sheet containing property
 * @param pIndex                 index of property in the property sheet (GUI 
 */
static void protectProperty(int treeIndex, _str protectColor, int protectIcon)
{
   int sc, bm1, bm2, flags;
   _ctl_property_sheet._TreeGetInfo(treeIndex, sc, bm1, bm2, flags);
   _ctl_property_sheet._TreeSetInfo(treeIndex, sc, protectIcon, protectIcon, flags | TREENODE_DISABLED | TREENODE_BOLD);
   
   _ctl_property_sheet._TreeSetColor(treeIndex, 1, 0, hex2dec(protectColor), F_INHERIT_FG_COLOR);
   _ctl_property_sheet._TreeSetColor(treeIndex, 2, 0, hex2dec(protectColor), F_INHERIT_FG_COLOR);
}

/**
 * Catches property sheet changes, including column resizing, 
 * selection changes, and completion of embedded text box 
 * editing. 
 * 
 * @return int 
 */
int _ctl_property_sheet.on_change(int reason, int index, int col = -1, _str value = "", int wid = 0)
{
   switch (reason) {
   case CHANGE_EDIT_OPEN:
      {
         // verify that we want to open up this line for editing
         PropertySheet * ps = _property_sheet_form_get_property_sheet_data();

         psIndex := index - 1;
         if (ps -> getTypeAtIndex(psIndex) != TMT_PROPERTY) return -1;

         // everything else is good
         return 0;
      }
   case CHANGE_EDIT_CLOSE:
      if (index > 0) {

         purpose := _GetDialogInfoHt(PURPOSE);
         if (purpose == OP_CONFIG || purpose == OP_QUICK_START || purpose == PS_PROMPT) {
            PropertySheet * ps = _property_sheet_form_get_property_sheet_data();
            psIndex := index - 1;
            if (ps -> getTypeAtIndex(psIndex) != TMT_PROPERTY) return -1;

            Property * p = ps -> getPropertyByIndex(psIndex);
            propType := p->getPropertyType();

            changePropertyValue(index, value);

            // this is a hack - if you don't return this, then the treeview will
            // try and change its own caption
            return DELETED_ELEMENT_RC;
         } else if (purpose == OP_EXPORT) {
            se.options.OptionsCheckboxTree * cbTree =_GetDialogInfoHt(CHECKBOXTREE, p_window_id, true);
            if ( cbTree != null ) {
               cbTree -> setPropertyProtectionStatus(index, value);
            }
         }

      }
      break;
   case CHANGE_SELECTED:
      // we need to update the help information
      if (index > 0) {
         PropertySheet * ps = _property_sheet_form_get_property_sheet_data();
         if (ps != null) {
            helpInfo := ps -> getDialogHelpOfItem(index - 1);
            helpHandle := getHelpLabelHandle();
            helpHandle.p_text = helpInfo;
         }
      }
      break;
   case CHANGE_NODE_BUTTON_PRESS:
      {
         // paths and color properties have buttons
         PropertySheet * ps = _property_sheet_form_get_property_sheet_data();
         psIndex := index - 1;

         Property * p = ps -> getPropertyByIndex(psIndex);
         if (p -> getPropertyType() == COLOR_PROPERTY) {
            if (getColor(p, value)) {
               changePropertyValue(index, value);
            }
         } else {
            if (getPath(p, value) && wid) {
               wid.p_text = value;
               changePropertyValue(index, value);
            }
         }
      }
      break;
   case CHANGE_EDIT_PROPERTY:
      {
         purpose := _GetDialogInfoHt(PURPOSE);
         if (purpose == OP_CONFIG || purpose == OP_QUICK_START || purpose == PS_PROMPT) {
            // see if this node is disabled - means we can't change value
            if (isPropertyEnabled(index)) {

               // we would like to edit this one, please
               return TREE_EDIT_COLUMN_BIT|2;
            }
         } else if (purpose == OP_EXPORT) {
            form := getOptionsFormFromEmbeddedDialog();
            protect := _GetDialogInfoHt(PROTECT, form);
            if (protect) {
               return TREE_EDIT_COLUMN_BIT|3;
            }
         }
      }
      break;
   case CHANGE_CHECK_TOGGLED:
      {
         purpose := _GetDialogInfoHt(PURPOSE);
         if (purpose == OP_IMPORT || purpose == OP_EXPORT) {

            if (index > 0) {
               se.options.OptionsCheckboxTree * cbTree =_GetDialogInfoHt(CHECKBOXTREE, p_window_id, true);
               if (cbTree != null) {
                  cbTree -> onCheckChangedEvent(index);
               }
            }
         } else if (purpose == OP_CONFIG) {
            // property sheet with checkboxes - neat!
            changePropertyCheckState(index, _ctl_property_sheet._TreeGetCheckState(index));
         }
      }
      break;
   case CHANGE_SWITCH_TOGGLED:
      if (index > 0) {

         purpose := _GetDialogInfoHt(PURPOSE);
         if( purpose == OP_CONFIG || purpose == OP_QUICK_START || purpose == PS_PROMPT ) {
            PropertySheet* ps = _property_sheet_form_get_property_sheet_data();
            psIndex := index - 1;
            if( ps->getTypeAtIndex(psIndex) != TMT_PROPERTY ) {
               return -1;
            }

            Property* p = ps->getPropertyByIndex(psIndex);
            propType := p->getPropertyType();
            value = _ctl_property_sheet._TreeGetSwitchState(index,col);

            changePropertyValue(index,value?"True":"False");
         }

      }
      break;
   }

   return 0;
}

static boolean getColor(Property * p, _str &value)
{
   curValue := p -> getActualValue();
   color := hex2dec(curValue);
   typeless new_color = show("-modal _color_picker_form", color);
   if (new_color == '' || new_color == color) {
      value = '';
   } else value = dec2hex(new_color);

   return (value != '');
}

static boolean getPath(Property * p, _str &value)
{
   Path pathP = (Path)*p;
   if (pathP.allowMultiplePaths()) {
      value = show('-modal _edit_paths_form', pathP.getCaption(), pathP.getActualValue(), pathP.getDelimiter(), (pathP.getPathType() == DIRECTORYPATH));
   } else {
      curPath := pathP.getActualValue();
      curPath = _replace_envvars(curPath);

      if (p -> getPropertyType() == DIRECTORY_PATH_PROPERTY) {

         value = show('-modal _cd_form', pathP.getCaption(),
                      true,               // expand_alias_invisible,
                      true,               // process_chdir_invisible,
                      true,               // save_settings_invisible,
                      false,              // ShowRecursive,
                      '',                 // find_file,
                      curPath,            // find_path,
                      true,               // path_must_exist,
                      true,               // allow_create_directory,
                      false);             // change_directory

      } else {
         // do we have a current value? - use that as the initial path/filename
         curFile := '';
         if (curPath != '') {
            // split into filename and path
            curFile = _strip_filename(curPath, 'P');
            curPath = _strip_filename(curPath, 'N');
         }

         // prompt for stuff
         value = _OpenDialog('-new -modal',     // show arguments
                               pathP.getCaption(),//caption,                                       // title
                               '',                                            // initial wildcards
                               '',                                            // file filters
                               OFN_FILEMUSTEXIST,                             // flags
                               '',                                            // default extension
                               curFile,                                       // initial filename
                               curPath                                        // initial directory
                               );
      }
   }

   return (value != '');
}

/**
 * Determines whether the index specified on the current 
 * property sheet is enabled. 
 * 
 * @param index      index to check
 * 
 * @return           true if enabled, false otherwise
 */
static boolean isPropertyEnabled(int index)
{
   int ch, bm1, bm2, flags;
   _ctl_property_sheet._TreeGetInfo(index, ch, bm1, bm2, flags);
   return ((flags & TREENODE_DISABLED) == 0);
}

/**
 * Gets the window id of the embedded combo box.  If there is 
 * none on this line of the property sheet, then 0 is returned. 
 * 
 * @param index      line of property sheet to check
 * 
 * @return           window id of combo box, 0 if one is not 
 *                   present
 */
static int getEmbeddedComboWid(int index)
{
   return 0;
   // now see if it has a combo box
   _str a[];
   _ctl_property_sheet._TreeGetComboDataNodeCol(index, 2, a);
   if (a != null) {
      // it does!  so let's find it and send this event to it
      // the p_child of the tree is the combo box...man, that's lucky
      return p_window_id.p_child;
   }

   return 0;
}

/**
 * Catch the ALT-<letter> events.  If they cannot be performed 
 * for the options dialog itself, then pass the event along to 
 * the right panel containing the options. 
 * 
 */
void _property_sheet_form.A_A-A_Z,A_0-A_9,'M-A'-'M-Z'()
{
   typeless event = last_event();
   typeless id = '';
   parse event2name(event) with '[AM]-','r' id;

   // if we have a property sheet, then we try and do a prefix match - 
   // grab the first property that starts with this letter
   index := searchProperties(id, _ctl_property_sheet._TreeGetFirstChildIndex(TREE_ROOT_INDEX));
   if (index > 0) {
      // select the item
      _ctl_property_sheet._TreeSetCurIndex(index);
      _ctl_property_sheet._TreeSelectLine(index, true);
   } 
}

static typeless propSheetSearchTime = 0;
static _str propSheetSearchString = '';

void _ctl_property_sheet.\33-\255()
{
   index := _ctl_property_sheet._TreeCurIndex();
   if (index <= 0) return;

   // get last key event, skip space
   key := last_event();

   // track key presses
   typeless curr_time = _time('B');
   time_diff := (curr_time - propSheetSearchTime);
   propSheetSearchTime = curr_time;

   // reset search string if time_diff is out of range
   if ((time_diff < 0) || (time_diff > 1000)) propSheetSearchString = '';

   // don't append if repeating first letter
   if (propSheetSearchString != key) strappend(propSheetSearchString, key);

   key = propSheetSearchString;

   // check to see if current caption matches
   caption := _ctl_property_sheet._TreeGetCaption(index);
   parse caption with .\tcaption\t.;
   if ((length(key) > 1) && (pos(key, caption, 1, 'I'))) {
      return; 
   }

   // and...search!
   index = searchProperties(propSheetSearchString, _ctl_property_sheet._TreeGetFirstChildIndex(TREE_ROOT_INDEX));
   if (index > 0) {
      // select the item
      _TreeSetCurIndex(index);
      _TreeSelectLine(index, true);
   }
}

/**
 * Searches through a property sheet for a prefix match of the 
 * properties' captions. 
 * 
 * @param string     prefex string to match
 * @param index      first index to check, then will check 
 *                   siblings
 * 
 * @return           index of found match, -1 if no match is 
 *                   found
 */
int searchProperties(_str string, int index)
{
   while (index > 0) {

      // see if this has children - if so, it's a property group, 
      // and we need to search its children
      child := _ctl_property_sheet._TreeGetFirstChildIndex(index);
      if (child > 0) {
         child = searchProperties(string, child);

         if (child > 0) return child;
      } else {
         // get the caption - we want the second column's goodies
         caption := _ctl_property_sheet._TreeGetCaption(index);
         parse caption with .\tcaption\t.;
   
         // check for the search string
         if (pos('^'string, caption, 1, 'IR')) return index;
      }

      // get the next sibling
      index = _ctl_property_sheet._TreeGetNextSiblingIndex(index);
   }

   return -1;
}

void _ctl_property_sheet.'TAB'()
{
   p_active_form.p_parent._next_control();
}
