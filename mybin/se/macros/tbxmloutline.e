////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38278 $
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
#import "main.e"
#import "cbrowser.e"
#include "slick.sh"
#include "xml.sh"
#import "xmlcfg.e"
#include "listbox.sh"
#import "listbox.e"
#import "xmlwrap.e"
#import "proctree.e"
#import "fileman.e"
#import "projutil.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

// used for managing previous combo box settings on the forms
#define LAST_SELECTED_TEXT 'LastSelectedText'
#define LAST_EDITED_RULE 'LastEditedRule'
// the name of the file where schemes are defined
#define SCHEMES_FILENAME 'outlineviewschemes.xml'
// the name of the file where the scheme mapping is defined
#define SCHEME_MAP_FILENAME 'outlineviewschememap.xml'
#define XML_NAG 'The Defs tool window now supports a customizable outline view for XML files.  Would you like to set that up now?'
#define ECLIPSE_XML_NAG 'The Outline view now supports a customizable view for XML files.  Would you like to set that up now?'

// whether or not the outline view is enabled
boolean def_outline_view_enabled = false;
// whether or not the schemes need to be reloaded
boolean def_refresh_schemes = false;
// whether or not the user has been nagged to try out this great feature
boolean def_outline_view_tryme_nag_shown = false;

/**
 * The struct that represents a single formatting rule. 
 *  
 * nodeType - The XML element the rule represents 
 * ruleFormat - The format string applied by the rule 
 * autoExpand - Whether nodes of this type should be expanded by default 
 */
struct outlineViewRule {
   _str nodeType;
   _str ruleFormat;
   boolean autoExpand;
};

/**
 * The struct that represents a single rule set, or scheme.  A scheme 
 * is nothing more than a named hashtable of outlineViewRule instances, keyed by 
 * their nodeType in lowercase. 
 */
struct outlineViewScheme {
   _str name;
   outlineViewRule rules:[];
};

/**
 * The struct that represents a single scheme mapping. 
 *  
 * criteria - The criteria that determines whether or not the mapping is a 
 *            match. 
 * schemeName - The scheme that applies if the criteria is a match. 
 */
struct schemeMapEntry {
   _str criteria;
   _str schemeName;
};

/**
 * The collection of mapping for schemes.  There are currently two sets; files 
 * and extensions.  Any file:scheme mapping goes in fileSchemeMap, and any 
 * extension:scheme mapping goes in extensionSchemeMap.  Both are keyed by the 
 * schemeName of the schemeMapEntry in lowercase. 
 */
struct schemeMap {
   schemeMapEntry fileSchemeMap:[];
   schemeMapEntry extensionSchemeMap:[];
};

// the hashtable of formatting schemes
static outlineViewScheme g_schemes:[];
// the scheme map, which tells us which scheme to apply
static schemeMap g_schemeMap;
// the current scheme being edited, used for sharing that scheme between dialogs
static outlineViewScheme* g_curEditScheme;
// the current rule being edited, used for sharing that rule between dialogs
static outlineViewRule* g_curEditRule;
// whether or not we're in the middle of nagging the user (to prevent subsequent nags)
static boolean g_isBusyNaggingUserFlag = false;

definit()
{
   g_schemes._makeempty();
   g_schemeMap.fileSchemeMap._makeempty();
   g_schemeMap.extensionSchemeMap._makeempty();
   g_curEditRule = null;

   loadOutlineViewSchemes();
   loadSchemeMap();
}

/**
 * Toggles between the outline view being on and being off.
 */
_command void tagOutlineViewToggle()
{
   // flip the flag
   def_outline_view_enabled = !def_outline_view_enabled;
   _config_modify_flags(CFGMODIFY_DEFDATA);
   // force an update of the defs window
   _UpdateCurrentTag(true);
}

#region Enabling / disabling the menu for the outline view

/**
 * Returns menu flags to indicate menu state for the outline view toggle. 
 * 
 * @param checkable - Whether the menu item is checkable or not.
 */
int getOutlineViewToggleEnablement(boolean checkable)
{
   if (isCurrentBufferSupportedForOutlineView() == true) {
      if (checkable == true) {
         if (def_outline_view_enabled == true) {
            return (MF_CHECKED | MF_ENABLED);
         } else {
            return (MF_UNCHECKED | MF_ENABLED);
         }
      } else {
         return MF_ENABLED;
      }
   }
   return (MF_UNCHECKED | MF_GRAYED);
}

// callback for enabling/disabling the menus
int _OnUpdate_tagOutlineViewToggle(CMDUI &cmdui,int target_wid,_str command)
{
   return getOutlineViewToggleEnablement(true);
}

boolean isOutlineViewActive()
{
   if (def_outline_view_enabled == true) {
      return isCurrentBufferSupportedForOutlineView();
   }
   return false;
}

/**
 * Returns menu flags to indicate menu state for the outline view menus given 
 * the current state. 
 * 
 * @param checkable - Whether the menu item is checkable or not.
 */
int getOutlineViewMenuEnablement(boolean checkable)
{
   if (isCurrentBufferSupportedForOutlineView() == true) {
      return MF_ENABLED;
   } else {
      return MF_GRAYED;
   }
}

// callback for enabling/disabling the menus
int _OnUpdate_tagShowOutlineRules(CMDUI &cmdui,int target_wid,_str command)
{
   return getOutlineViewMenuEnablement(true);
}

// callback for enabling/disabling the menus
int _OnUpdate_tagSelectOutlineRules(CMDUI &cmdui,int target_wid,_str command)
{
   return getOutlineViewMenuEnablement(true);
}

#endregion

/**
 * Displays the outline view formatting rules editor.  If the current document 
 * doesn't support the outline view, it will show a warning message that the 
 * rules can't be editted. 
 */
_command void tagShowOutlineRules() name_info(',')
{
   _str langID = _mdi.p_child.p_LangId;
   if (isLanguageSupportedForOutlineView(langID) == false) {
      _message_box('This document does not support Outline View');
      return;
   }
   show('_outline_view_config_form');
}

/**
 * Handling code for the _outline_view_config_form form.
 */
defeventtab _outline_view_config_form;

/**
 * Shows the dialog for editting the outline view formatting rules.  This dialog 
 * is only available is the current buffer language is supported by the outline 
 * view. 
 */
_command void tagSelectOutlineRules() name_info(',')
{
   _str langID = _mdi.p_child.p_LangId;
   if (isLanguageSupportedForOutlineView(langID) == false) {
      _message_box('This document does not support Outline View');
      return;
   }
   show('_select_outline_view_format_form');
}

/**
 * Returns true of the current buffer is supported by the outline view, false if 
 * not. 
 */
boolean isCurrentBufferSupportedForOutlineView()
{
   _str langID = _mdi.p_child.p_LangId;
   return isLanguageSupportedForOutlineView(langID);
}

/**
 * Handles the nagging (or prompting, depending on taste) of the outline view 
 * for trying new things or setting up something that needs setting up.  It 
 * guides the user towards using the outline view for the first time and also 
 * guides them towards how to set up their first rule scheme.  This function is 
 * mainly called by the C code when the Defs window is updated.  Note that most
 * of the time, the function exits immediately, so it's not an overhead on DEFs 
 * updating. 
 */
void maybeOutlineViewNag()
{
   // if we've nagged the user before, then just get out
   if (def_outline_view_tryme_nag_shown == true) {
      return;
   }

   // if the current buffer doesn't support outline view, no need to nag
   if (isCurrentBufferSupportedForOutlineView() == false) {
      return;
   }
   // if we're busy nagging the user, just get out, thank you
   if (g_isBusyNaggingUserFlag == true) {
      return;
   }
   
   // set up the flag that says we should do nothing here if we're nagging the user
   g_isBusyNaggingUserFlag = true;

   // see if there's a scheme associated with this doc type
   _str schemeName = getOutlineSchemeNameForCurrentFile();
   _str fileName = _mdi.p_child.p_buf_name;
   _str fileKey = lowcase(fileName);

   // here's where we do the big nag check.  The first block tests the case where
   // the document supports the outline view, outline view is off and the user hasn't 
   // been nagged yet (they probably don't know about it)
   if (def_outline_view_enabled == false)
   {
      // if we are in here, this will result in a nag, so turn this flag off
      def_outline_view_tryme_nag_shown = true;
      _config_modify_flags(CFGMODIFY_DEFDATA);

      // this first check tests the case where the user has outline view turned off, 
      // the file is supoported for outlione view and there's no scheme for it, and 
      // this nag has never been shown
      _str msg = '';
      if (schemeName == '') {
         if (isEclipsePlugin()) {
            msg = ECLIPSE_XML_NAG; 
         } else {
            msg = XML_NAG;
         }
         typeless status = _message_box(msg,'',MB_YESNO|MB_ICONQUESTION);
         if (status == IDYES) {
            schemeName = show('-modal _outline_view_config_form');
            if (schemeName != '') {
               associateSchemeWithCurrentBuffer(schemeName);
               // turn on the outline view
               def_outline_view_enabled = true;
               _UpdateCurrentTag(true);
            }
         }
      } else {
         // this first check tests the case where the user has outline view turned off, 
         // the file is supoported for outlione view and there IS a scheme for it, and 
         // this nag has never been shown
         if (isEclipsePlugin()) {
            msg = ECLIPSE_XML_NAG; 
         } else {
            msg = XML_NAG;
         }
         typeless status = _message_box(msg,'',MB_YESNO|MB_ICONQUESTION);
         if (status == IDYES) {
            // turn on the outline view
            def_outline_view_enabled = true;
            _UpdateCurrentTag(true);
         }
      }
   } else if ((def_outline_view_enabled == true) && (schemeName :== '')) {
      // so turn this flag off
      def_outline_view_tryme_nag_shown = true;
      _config_modify_flags(CFGMODIFY_DEFDATA);

      // this next check tests the case where the user the file is supoported for outlione 
      // view, outline view is on and there's no scheme for it
      _str msg = 'You have not set up outline formatting for this type of XML document.  Would you like to do that now?';
      typeless status = _message_box(msg,'',MB_YESNO|MB_ICONQUESTION);
      if (status == IDYES) {
         schemeName = show('-modal _outline_view_config_form');
         if (schemeName != '') {
            associateSchemeWithCurrentBuffer(schemeName);
         }
      }
   }
   // now flag that we're done nagging the user
   g_isBusyNaggingUserFlag = false;
}

/**
 * Returns true of the specified language ID is supported by the outline view, 
 * false if not. 
 * 
 * @param langID : the language ID to check for outline view support, can be 
 *               gotten using .p_langID
 */
boolean isLanguageSupportedForOutlineView(_str langID)
{
   // the following is a list of what constitutes support for the outline view.
   // currently it's just the document inheriting from XML.
   boolean isSuppoprted = _LanguageInheritsFrom('xml', langID);
   // don't allow ant or HTML, they're tagged differently
   isSuppoprted = isSuppoprted && (strieq(langID, 'ant') == false);
   isSuppoprted = isSuppoprted && (strieq(langID, 'html') == false);
   isSuppoprted = isSuppoprted && (strieq(langID, 'android') == false);
   return isSuppoprted;
}

/**
 * Initializer for the scheme editor.
 */
void _outline_view_config_form.on_load()
{
   int i;
   _str schemeName;
   outlineViewScheme scheme;

   // populate the scheme combo box
   foreach (schemeName => scheme in g_schemes) {
      _combo_scheme._lbadd_item(scheme.name);
   }

   // get the scheme for this buffer
   schemeName = getOutlineSchemeNameForCurrentFile();
   _combo_scheme._lbfind_and_select_item(schemeName, '', true);

   // load the icons up in the combo (not yet)
   /*
   int i = 0;
   int j = 0;
   int picMatrix[][] = getAccessPicMatrix();
   _combo_image.p_cb_list_box._lbclear();
   _combo_image.p_cb_list_box.p_picture = picMatrix[0][0];
   for (i = 0; i < picMatrix._length(); i++) {
      for (j = 0; j < picMatrix[i]._length(); j++) {
         _str id = picMatrix[i][j];
         _combo_image.p_cb_list_box._lbadd_item(id, 60, picMatrix[i][j]);
      }
   }
   _combo_image.p_cb_list_box.p_picture = picMatrix[0][0];
   _combo_image.p_cb_list_box.p_pic_point_scale = 8;
   */
}

/**
 * Handler for resizing of the scheme editor.
 */
void _outline_view_config_form.on_resize()
{
   int buttonWidth = 1100;
   int buttonHeight = 340;

   // get the dimensions of the dialog
   int width = _dx2lx(p_active_form.p_xyscale_mode, p_active_form.p_client_width);
   int height = _dy2ly(p_active_form.p_xyscale_mode, p_active_form.p_client_height);

   // size the top controls
   _button_delete_scheme.p_x = width - buttonWidth - 100;
   _button_new_scheme.p_x = _button_delete_scheme.p_x - buttonWidth - 50;
   _combo_scheme.p_width = _button_new_scheme.p_x - _combo_scheme.p_x - 70;

   // size the OK and cancel buttons
   _button_cancel.p_x = width - buttonWidth - 100;
   _button_cancel.p_y = height - 500;
   _button_ok.p_x = _button_cancel.p_x - buttonWidth - 50;
   _button_ok.p_y = _button_cancel.p_y;

   // size the element list
   _lb_elements.p_height = _button_cancel.p_y - _lb_elements.p_y - buttonHeight - 100;
   _button_new_element.p_y = _lb_elements.p_y + _lb_elements.p_height + 50;
   _button_delete_element.p_y = _button_new_element.p_y;

   // size the frame
   _frame_el_props.p_width = width - _frame_el_props.p_x - 100;
   _frame_el_props.p_height = _lb_elements.p_height;
   _text_format.p_width = _frame_el_props.p_width - _text_format.p_x - 150;
   ctllabel6.p_width = _frame_el_props.p_width - ctllabel6.p_x - 150;
   ctllabel8.p_width = ctllabel6.p_width;
}

/**
 * Returns a pointer to the scheme currently selected in the scheme combo box.
 */
outlineViewScheme* getCurrentScheme()
{
   // get the selected scheme
   _str selSchemeName = _combo_scheme._lbget_text();
   _str key = lowcase(selSchemeName);
   return g_schemes._indexin(key);
}

void _combo_scheme.on_change(int reason)
{
   _str elementName;
   outlineViewRule rule;

   // get the active scheme (selected in the list box)
   g_curEditScheme = getCurrentScheme();
   // populate the list box
   _lb_elements._lbclear();
   if (g_curEditScheme) {
      foreach (elementName => rule in g_curEditScheme->rules) {
         _lb_elements._lbadd_item(rule.nodeType);
      }
      _lb_elements._lbsort();
      _lb_elements._lbtop();
      _lb_elements._lbselect_line();
      _lb_elements.call_event(CHANGE_OTHER, _lb_elements, ON_CHANGE, 'w');
   }
}

void _button_ok.lbutton_up()
{
   // get the selected scheme name
   _str selSchemeName = _combo_scheme._lbget_text();

   // save the newly defined rule sets
   saveOutlineViewRules();

   // see if we need to associate the current scheme with the current file
   if (isCurrentBufferSupportedForOutlineView() == true) {
      associateSchemeWithCurrentBuffer(selSchemeName);
   }

   // flag that the defs window needs refreshing
   def_refresh_schemes = true;
   // kill this dialog and return the selected scheme name
   p_active_form._delete_window(selSchemeName);
}

/**
 * Updates the scheme map file to associate the current buffer file name to a 
 * specific scheme.
 * 
 * @param schemeName - the scheme to associate with the current buffer file name
 */
void associateSchemeWithCurrentBuffer(_str schemeName)
{
   // add a map entry for this file
   _str fileName = _mdi.p_child.p_buf_name;
   _str fileKey = lowcase(fileName);
   if (g_schemeMap.fileSchemeMap._indexin(fileKey)) {
      schemeMapEntry mapEntry = g_schemeMap.fileSchemeMap:[fileKey];
      schemeName = schemeName;
   } else {
      schemeMapEntry mapEntry;
      mapEntry.criteria = fileName;
      mapEntry.schemeName = schemeName;
      g_schemeMap.fileSchemeMap:[fileKey] = mapEntry;
   }
   // save the new association
   saveSchemeMap();
}

/**
 * Updates the scheme map file to associate the current buffer's extension 
 * to a specific scheme. 
 * 
 * @param schemeName - the scheme to associate with the current buffer's 
 *                   extension
 */
void associateSchemeWithCurrentBufferExtension(_str schemeName)
{
   _str fileName = _mdi.p_child.p_buf_name;
   _str bufExt = _get_extension(fileName);
   _str extKey = lowcase(bufExt);

   // the user decided to apply this scheme to all files with the 
   // current exxtension.  First, go through the list of files and 
   // remove all entries that have this extension
   _str key = '';
   schemeMapEntry mapEntry;
   foreach (key => mapEntry in g_schemeMap.fileSchemeMap) {
      _str curExt = _get_extension(mapEntry.criteria);
      if (stricmp(curExt, bufExt) == 0) {
         g_schemeMap.fileSchemeMap._deleteel(key);
      }
   }
   // now add the entry to the extension list
   // add a map entry for this file
   mapEntry.criteria = bufExt;
   mapEntry.schemeName = _combo_scheme.p_text;
   g_schemeMap.extensionSchemeMap:[extKey] = mapEntry;
   // save the new association
   saveSchemeMap();
}

void _button_cancel.lbutton_up()
{
   p_active_form._delete_window();
}

void _button_new_scheme.lbutton_up()
{
   // the dialog already checks to make sure that the scheme name is unique
   outlineViewScheme newScheme;
   newScheme.name = show('-modal _new_outline_view_scheme_form');
   _str newSchemeKey = lowcase(newScheme.name);
   // a name of blank will indicate that the user wants to cancel
   if (newScheme.name != '')
   {
      // add the scheme to the collection and rebuild the list
      g_schemes:[newSchemeKey] = newScheme;
      // add it to the combo list
      _combo_scheme._lbadd_item(newScheme.name);
      // sort the combo list
      _combo_scheme._lbsort();
      _combo_scheme.p_text = newScheme.name;
      // update the elements list
      _lb_elements._lbselect_line();
      _lb_elements.call_event(CHANGE_OTHER, _lb_elements, ON_CHANGE, 'w');
   }
}

void _button_delete_scheme.lbutton_up()
{
   _str selSchemeName = _combo_scheme.p_text;
   if (selSchemeName == '') {
      return;
   }
   // remove it from the hashtable
   _str key = lowcase(selSchemeName);
   g_schemes._deleteel(key);
   // remove the current item
   int retVal = _combo_scheme._lbdelete_item();
   if (retVal != BOTTOM_OF_FILE_RC) {
      // update the selection
      _combo_scheme._lbselect_line();
      _combo_scheme.p_text = _combo_scheme._lbget_text();
   } else {
      _combo_scheme._lbclear();
      _combo_scheme.p_text = '';
   }
   _lb_elements.call_event(CHANGE_OTHER, _lb_elements, ON_CHANGE, 'w');
}

void _button_new_element.lbutton_up()
{
   // the dialog already checks to make sure that the element name is unique
   outlineViewRule newRule;
   g_curEditRule = &newRule;
   int retVal = show('-modal _new_outline_view_rule_form');
   if (retVal == 0) {
      _str newRuleKey = lowcase(newRule.nodeType);
      // a name of blank will indicate that the user wants to cancel
      if (newRuleKey != '') {
         // get the active scheme (selected in the list box)
         outlineViewScheme* curScheme = getCurrentScheme();
         if (curScheme != null) {
            // add the scheme to the collection and rebuild the list
            curScheme->rules:[newRuleKey] = newRule;
            // add it to the list box
            _lb_elements._lbadd_item(newRule.nodeType);
            // sort the list
            _lb_elements._lbsort();
            // select it in the list
            _lb_elements._lbselect_line();
            _lb_elements.call_event(CHANGE_OTHER, _lb_elements, ON_CHANGE, 'w');
         }
      }
   }
}

void _button_delete_element.lbutton_up()
{
   _str selElementName = _lb_elements._lbget_seltext();
   if (selElementName == '') {
      return;
   }
   // get the current scheme
   outlineViewScheme* curScheme = getCurrentScheme();
   if (curScheme != null) {
      // remove the currently selected item from the scheme in memory
      selElementName = _lb_elements._lbget_seltext();
      // find the rule in the hashtable for that item
      _str key = lowcase(selElementName);
      curScheme->rules._deleteel(key);
      // remove the current item
      _lb_elements._lbdelete_item();
      // update the selection
      _lb_elements._lbselect_line();
      _lb_elements.call_event(CHANGE_OTHER, _lb_elements, ON_CHANGE, 'w');
   }
}

void _lb_elements.on_change(int reason)
{
   boolean elementFound = false;

   UpdateCurrentElement();
   // get the active scheme (selected in the list box)
   outlineViewScheme* curScheme = getCurrentScheme();
   if (curScheme != null) {
      _str selectedElementName = _lb_elements._lbget_seltext();
      if (selectedElementName != '') {
         // find it in the hashtable
         _str key = lowcase(selectedElementName);
         if (curScheme->rules._indexin(key)) {
            outlineViewRule rule = curScheme->rules:[key];
            _text_format.p_text = rule.ruleFormat;
            if (rule.autoExpand == true) {
               _check_autoexpand.p_value = 1;
            } else {
               _check_autoexpand.p_value = 0;
            }
            elementFound = true;
         }
      }
   }
   if (elementFound == false) {
      _text_format.p_text = '';
      _check_autoexpand.p_value = 0;
   }
}

/**
 * Updates the outline view rule in memory that is being edited in the dialog. 
 * All of the information in the attribute section of the dialogg is copied to 
 * the proper outline view rule. 
 */
void UpdateCurrentElement()
{
   // get the active scheme (selected in the list box)
   outlineViewScheme* curScheme = getCurrentScheme();
   if (curScheme) {
      // get the name of the previously selected item
      _str previousElementName = _GetDialogInfoHt(LAST_SELECTED_TEXT, _lb_elements.p_window_id);
      if ((previousElementName != null) && (previousElementName != '')) {
         // find the rule in the hashtable for that item
         _str key = lowcase(previousElementName);
         outlineViewRule* rule = curScheme->rules._indexin(key);
         if (rule) {
            // update the info for that rule
            rule->ruleFormat = _text_format.p_text;
            rule->autoExpand = (_check_autoexpand.p_value != 0);
         }
      }
   }
   // get the name of the currently selected item
   _str selectedElementName = _lb_elements._lbget_seltext();
   if (selectedElementName != null) {
      // update the name of the currently selected item
      _SetDialogInfoHt(LAST_SELECTED_TEXT, selectedElementName, _lb_elements.p_window_id);
   } else {
      _SetDialogInfoHt(LAST_SELECTED_TEXT, '', _lb_elements.p_window_id);
   }
}

#region Load / save functions

/**
 * Returns the folder in the user's config directory where the scheme and map 
 * files should be. 
 * 
 * @return _str - See description
 */
_str getUserOutlineSchemeDir() {
   _str schemesDir = _ConfigPath() :+ 'formatschemes' :+ FILESEP :+ 'outlineschemes' :+ FILESEP;
   if (!isdirectory(schemesDir)) {
      int status = make_path(schemesDir);
      if (status!=0) {
         _str msg = "Error creating directory:\n\n":+
                    schemesDir:+"\n\n":+
                    get_message(status);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return "";
      }
   }
   return schemesDir;
}

/**
 * Returns the folder in SlickEdit's install directory where the scheme and map 
 * files should be. 
 * 
 * @return _str - See description
 */
_str getShippedOutlineSchemeDir() {
   // assign to a variable so we can inspect the value when debugging
   _str schemesDir = get_env('VSROOT') :+ 'sysconfig' :+ FILESEP :+ 'formatschemes' :+ FILESEP :+ 'outlineschemes' :+ FILESEP;
   return schemesDir;
}

/**
 * Loads the outline view schemes into memory.  If the file doesn't exist in the 
 * user's config foler, a default one is copied from the install folder. 
 */
void loadOutlineViewSchemes()
{
   _str hashKey = '';
   _str configFileName = getUserOutlineSchemeDir() :+ SCHEMES_FILENAME;
   if (file_exists(configFileName) == false) {
      _str defaultConfigFileName = getShippedOutlineSchemeDir() :+ SCHEMES_FILENAME;
      copy_file(defaultConfigFileName, configFileName);
   }

   int status;
   int configHandle = _xmlcfg_open(configFileName, status);
   if (status != 0) {
      return;
   }

   g_schemes._makeempty();
   _str schemeNodes[];
   _str ruleNodes[];
   int i, j;
   _xmlcfg_find_simple_array(configHandle, '//scheme', schemeNodes);
   for (i = 0; i < schemeNodes._length(); i++) {
      outlineViewScheme scheme;
      int schemeNode = (int)schemeNodes[i];
      // get the name of the scheme
      scheme.name = _xmlcfg_get_attribute(configHandle, schemeNode, 'name', '');
      hashKey = lowcase(scheme.name);
      if (!(g_schemes._indexin(hashKey))) {
         g_schemes:[hashKey] = scheme;
      }
      // get a pointer to the new one in the collection
      outlineViewScheme* curScheme = &(g_schemes:[hashKey]);
      // get the rules for this scheme
      int ruleNode = _xmlcfg_get_first_child(configHandle, schemeNode);
      while (ruleNode >= 0) {
         outlineViewRule rule;
         // get the name of the node this applies to
         rule.nodeType = _xmlcfg_get_attribute(configHandle, ruleNode, 'nodetype', '');
         hashKey = lowcase(rule.nodeType);
         int ruleValueNode = _xmlcfg_get_first_child(configHandle, ruleNode, VSXMLCFG_NODE_PCDATA | VSXMLCFG_NODE_CDATA);
         if (ruleValueNode >= 0) {
            rule.ruleFormat = _xmlcfg_get_value(configHandle, ruleValueNode);
            _str autoExpandValue = _xmlcfg_get_attribute(configHandle, ruleNode, 'autoexpand');
            if ((autoExpandValue != null)  && (autoExpandValue :== '1')) {
               rule.autoExpand = true;
            } else {
               rule.autoExpand = false;
            }
            // make sure it's not a duplicate rule
            if (!(curScheme->rules._indexin(hashKey))) {
               curScheme->rules:[hashKey] = rule;
            }
         }
         // try to get the next
         ruleNode = _xmlcfg_get_next_sibling(configHandle, ruleNode);
      }
   }
   // close the XML DOM
   _xmlcfg_close(configHandle);

   return;
}

/**
 * Saves the outline view schemes to their proper file in the user's config 
 * folder.
 */
void saveOutlineViewRules()
{
   int rootNode = TREE_ROOT_INDEX;
   int configHandle = TREE_ROOT_INDEX;
   int curSchemeNode = TREE_ROOT_INDEX;
   int status = 0;

   // first, make sure the current item is updated
   UpdateCurrentElement();

   // now create the file
   _str configFileName = getUserOutlineSchemeDir() :+ SCHEMES_FILENAME;
   // if the file doesn't exist, then create it, otherwise just open it
   if (file_exists(configFileName) == true) {
      delete_file(configFileName);
   }

   // create the tree
   configHandle = _xmlcfg_create(configFileName, VSENCODING_UTF8);
   if (configHandle < 0) {
      _message_box('Could not save outline view rules to 'configFileName);
      return;
   }
   // create the XML declaration
   int xmldecl = _xmlcfg_add(configHandle, TREE_ROOT_INDEX, 'xml', VSXMLCFG_NODE_XML_DECLARATION, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(configHandle, xmldecl, 'version', '1.0');
   _xmlcfg_set_attribute(configHandle, xmldecl, 'encoding', 'UTF-8');
   // add the main node
   rootNode = _xmlcfg_add(configHandle, TREE_ROOT_INDEX, 'outlineviewdata', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);

   // now we're good to add the schemes
   outlineViewScheme scheme;
   outlineViewRule rule;
   _str schemeName;
   _str elementName;
   foreach (schemeName => scheme in g_schemes) {
      // add the scheme to the XML
      curSchemeNode = _xmlcfg_add(configHandle, rootNode, 'scheme', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(configHandle, curSchemeNode, 'name', scheme.name);
      // now add the rules
      foreach (elementName => rule in scheme.rules) {
         // only include the rule if there's a format for it
         if (rule.ruleFormat != "") {
            int curRuleNode = _xmlcfg_add(configHandle, curSchemeNode, 'rule', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
            _xmlcfg_set_attribute(configHandle, curRuleNode, 'nodetype', rule.nodeType);
            _xmlcfg_add(configHandle, curRuleNode, rule.ruleFormat, VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            if (rule.autoExpand == true) {
               _xmlcfg_set_attribute(configHandle, curRuleNode, 'autoexpand', '1');
            } else {
               _xmlcfg_set_attribute(configHandle, curRuleNode, 'autoexpand', '0');
            }
         }
      }
   }
   // all done, save the XML
   _xmlcfg_save(configHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE|VSXMLCFG_SAVE_PCDATA_INLINE);
   // close the XML DOM
   _xmlcfg_close(configHandle);
}

/**
 * Loads the outline view scheme map into memory.  If the file doesn't exist in
 * the user's config foler, a default one is copied from the install folder. 
 */
void loadSchemeMap()
{
   // clear the existing scheme map
   g_schemeMap._makeempty();

   // if the map file doesn't exist, then just return the language ID
   _str configFileName = getUserOutlineSchemeDir() :+ SCHEME_MAP_FILENAME;
   if (file_exists(configFileName) == false) {
      _str defaultConfigFileName = getShippedOutlineSchemeDir() :+ SCHEME_MAP_FILENAME;
      copy_file(defaultConfigFileName, configFileName);
   }
   // load the file
   int status;
   int configHandle = _xmlcfg_open(configFileName, status);
   if (status != 0) {
      return;
   }

   boolean schemeNameFound = false;
   int i, j;
   _str fileSchemeNodes[];
   _xmlcfg_find_simple_array(configHandle, '//filemap/schememapentry', fileSchemeNodes);
   for (i = 0; i < fileSchemeNodes._length(); i++) {
      schemeMapEntry curEntry;
      // get the name of the scheme
      int fileSchemeNode = (int)fileSchemeNodes[i];
      int tempNode = _xmlcfg_get_first_child(configHandle, fileSchemeNode);
      if (tempNode >= 0) {
         int valueNode = _xmlcfg_get_first_child(configHandle, tempNode, VSXMLCFG_NODE_PCDATA | VSXMLCFG_NODE_CDATA);
         if (valueNode >= 0) {
            curEntry.criteria = _xmlcfg_get_value(configHandle, valueNode);
         } else {
            continue;
         }
      }
      tempNode = _xmlcfg_get_next_sibling(configHandle, tempNode);
      if (tempNode >= 0) {
         int valueNode = _xmlcfg_get_first_child(configHandle, tempNode, VSXMLCFG_NODE_PCDATA | VSXMLCFG_NODE_CDATA);
         if (valueNode >= 0) {
            curEntry.schemeName = _xmlcfg_get_value(configHandle, valueNode);
         } else {
            continue;
         }
      }
      // add it to the map
      _str key = curEntry.criteria;
      key = lowcase(key);
      g_schemeMap.fileSchemeMap:[key] = curEntry;
   }
   _str extensionSchemeNodes[];
   _xmlcfg_find_simple_array(configHandle, '//extensionmap/schememapentry', extensionSchemeNodes);
   for (i = 0; i < extensionSchemeNodes._length(); i++) {
      schemeMapEntry curEntry;
      // get the name of the scheme
      int extensionSchemeNode = (int)extensionSchemeNodes[i];
      int tempNode = _xmlcfg_get_first_child(configHandle, extensionSchemeNode);
      if (tempNode >= 0) {
         int valueNode = _xmlcfg_get_first_child(configHandle, tempNode, VSXMLCFG_NODE_PCDATA | VSXMLCFG_NODE_CDATA);
         if (valueNode >= 0) {
            curEntry.criteria = _xmlcfg_get_value(configHandle, valueNode);
         } else {
            continue;
         }
      }
      tempNode = _xmlcfg_get_next_sibling(configHandle, tempNode);
      if (tempNode >= 0) {
         int valueNode = _xmlcfg_get_first_child(configHandle, tempNode, VSXMLCFG_NODE_PCDATA | VSXMLCFG_NODE_CDATA);
         if (valueNode >= 0) {
            curEntry.schemeName = _xmlcfg_get_value(configHandle, valueNode);
         } else {
            continue;
         }
      }
      // add it to the map
      _str key = curEntry.criteria;
      key = lowcase(key);
      g_schemeMap.extensionSchemeMap:[key] = curEntry;
   }
   // close the XML DOM
   _xmlcfg_close(configHandle);
}

/**
 * Saves the outline view scheme map to the proper file in the user's 
 * config folder. 
 */
void saveSchemeMap()
{
   int rootNode = TREE_ROOT_INDEX;
   int configHandle = TREE_ROOT_INDEX;
   int curSchemeNode = TREE_ROOT_INDEX;
   int status = 0;

   // now create the file
   _str mapFileName = getUserOutlineSchemeDir() :+ SCHEME_MAP_FILENAME;
   // if the file doesn't exist, then create it, otherwise just open it
   if (file_exists(mapFileName) == true) {
      delete_file(mapFileName);
   }

   // create the tree
   configHandle = _xmlcfg_create(mapFileName, VSENCODING_UTF8);
   if (configHandle < 0) {
      _message_box('Could not save outline view scheme map to 'mapFileName);
      return;
   }
   // create the XML declaration
   int xmldecl = _xmlcfg_add(configHandle, TREE_ROOT_INDEX, 'xml', VSXMLCFG_NODE_XML_DECLARATION, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(configHandle, xmldecl, 'version', '1.0');
   _xmlcfg_set_attribute(configHandle, xmldecl, 'encoding', 'UTF-8');
   // add the main node
   rootNode = _xmlcfg_add(configHandle, TREE_ROOT_INDEX, 'outlineviewschememap', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);

   // now we're good to add the file name scheme maps
   int fileMapRootNode = _xmlcfg_add(configHandle, rootNode, 'filemap', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   schemeMapEntry mapEntry;
   _str fileName;
   foreach (fileName => mapEntry in g_schemeMap.fileSchemeMap) {
      // add the scheme map entry
      int schemeMapEntryRoot = _xmlcfg_add(configHandle, fileMapRootNode, 'schememapentry', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      int schemeMapEntryFileNameNode = _xmlcfg_add(configHandle, schemeMapEntryRoot, 'criteria', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add(configHandle, schemeMapEntryFileNameNode, mapEntry.criteria, VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
      int schemeMapEntrySchemeNameNode = _xmlcfg_add(configHandle, schemeMapEntryRoot, 'schemename', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add(configHandle, schemeMapEntrySchemeNameNode, mapEntry.schemeName, VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
   }

   // now we're good to add the extension scheme maps
   int extensionMapRootNode = _xmlcfg_add(configHandle, rootNode, 'extensionmap', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   _str extension;
   foreach (extension => mapEntry in g_schemeMap.extensionSchemeMap) {
      // add the scheme map entry
      int schemeMapEntryRoot = _xmlcfg_add(configHandle, extensionMapRootNode, 'schememapentry', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      int schemeMapEntryFileNameNode = _xmlcfg_add(configHandle, schemeMapEntryRoot, 'criteria', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add(configHandle, schemeMapEntryFileNameNode, mapEntry.criteria, VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
      int schemeMapEntrySchemeNameNode = _xmlcfg_add(configHandle, schemeMapEntryRoot, 'schemename', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add(configHandle, schemeMapEntrySchemeNameNode, mapEntry.schemeName, VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
   }

   // all done, save the XML
   _xmlcfg_save(configHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE|VSXMLCFG_SAVE_PCDATA_INLINE);
   // close the XML DOM
   _xmlcfg_close(configHandle);
}

#endregion

/**
 * Retrieves an array of all unique elements in the current buffer's XML.
 * 
 * @return _str - An array of unique XML elements in the current buffer.
 */
_str getXmlElementsInBuffer() []
{
   _str elements[];
   // parse the current buffer with xmlcfg
   int status;
   int xmlDocument = _xmlcfg_open_from_buffer(_mdi.p_child, status);
   if (xmlDocument < 0) {
      return elements;
   }
   // get the unique elements
   _str elementsHash:[];
   getXmlElements2(xmlDocument, TREE_ROOT_INDEX, elementsHash);
   // close the XML DOM
   _xmlcfg_close(xmlDocument);
   // transfer them to an array and sort
   int i = 0;
   _str elementName;
   foreach (elementName => auto v in elementsHash) {
      elements[i] = elementName;
      i++;
   }
   elements._sort();
   // return the unique element names
   return elements;
}

/**
 * Recursive inner version of getXmlElementsInBuffer().
 * 
 * @author shackett (1/7/2010)
 * 
 * @param xmlDocument - xmlcfg handle to the XML in the current buffer
 * @param parentXmlElement - The handle to the parent, or root, in the recursive 
 *                         walk of the XML tree.
 * @param elements - A hashtable of unique elements found in the XML document
 */
void getXmlElements2(int xmlDocument, int parentXmlElement, _str (&elements):[])
{
   int childXmlElement = _xmlcfg_get_first_child(xmlDocument, parentXmlElement);
   while (childXmlElement > 0) {
      _str elementName = _xmlcfg_get_name(xmlDocument, childXmlElement);
      // make sure the element's not already in the list.  Also, don't include the
      // main 'xml' node
      if (!(elements._indexin(elementName)) && (stricmp(elementName, 'xml') != 0)) {
         elements:[elementName] = elementName;
      }
      getXmlElements2(xmlDocument, childXmlElement, elements);
      childXmlElement = _xmlcfg_get_next_sibling(xmlDocument, childXmlElement);
   }
}

/**
 * Inspects the scheme map entries in g_schemeMap and returns the scheme that 
 * applies to the current buffer. 
 * 
 * @return _str - the name of the scheme that applies to the current buffer.
 */
_str getOutlineSchemeNameForCurrentFile()
{
   _str schemeName = '';
   boolean customSchemeFound = false;
   
   // is there a scheme mapped for this file name?
   _str fileName = _mdi.p_child.p_buf_name;
   _str fileKey = lowcase(fileName);
   if (g_schemeMap.fileSchemeMap._indexin(fileKey)) {
      schemeMapEntry mapEntry = g_schemeMap.fileSchemeMap:[fileKey];
      schemeName = mapEntry.schemeName;
      customSchemeFound = true;
   }
   // is there a scheme mapped for this extension?
   if (customSchemeFound == false) {
      _str extKey = _get_extension(_mdi.p_child.p_buf_name);
      extKey = lowcase(extKey);
      if (g_schemeMap.extensionSchemeMap._indexin(extKey)) {
         schemeMapEntry mapEntry = g_schemeMap.extensionSchemeMap:[extKey];
         schemeName = mapEntry.schemeName;
      }
   }

   // otherwise, just try to get the scheme from the language ID
   return schemeName;
}

/**
 * Handler for the _new_outline_view_rule_form form
 */
defeventtab _new_outline_view_rule_form;

void _new_outline_view_rule_form.on_load()
{
   int i;
   // populate the format rule list box
   _str elements[] = getXmlElementsInBuffer();
   for (i = 0; i < elements._length(); i++) {
      _combo_element._lbadd_item(elements[i]);
   }
   // set the focus on the combo
   _combo_element._set_focus();
}

void _button_ok.lbutton_up()
{
   // determine if this element name is in the list
   _str newElementName = _combo_element.p_cb_text_box.p_text;
   _str newElementNameKey = lowcase(newElementName);
   if (g_curEditScheme->rules._indexin(newElementNameKey)) {
      _message_box('An element with this name already exists.');
      return;
   }
   if (g_curEditRule != null) {
      g_curEditRule->nodeType = _combo_element.p_text;
      g_curEditRule->ruleFormat = _text_format.p_text;
      p_active_form._delete_window(0);
   } else {
      p_active_form._delete_window(-1);
   }
}

void _button_cancel.lbutton_up()
{
   p_active_form._delete_window(-1);
}

/**
 * Handler for the _new_outline_view_scheme_form form
 */
defeventtab _new_outline_view_scheme_form;

void _button_ok.lbutton_up()
{
   // determine if this scheme name is in the list
   _str newSchemeNameKey = lowcase(_text_scheme.p_text);
   if (g_schemes._indexin(newSchemeNameKey)) {
      _message_box('A scheme with this name already exists.');
      return;
   }
   // return the scheme name
   p_active_form._delete_window(_text_scheme.p_text);
}

void _button_cancel.lbutton_up()
{
   p_active_form._delete_window();
}

/**
 * Handler for the _select_outline_view_format_form form
 */
defeventtab _select_outline_view_format_form;

void _select_outline_view_format_form.on_load()
{
   _str schemeName = '';
   outlineViewScheme scheme;

   // get the current extension of the file
   _str curExt = _get_extension(_mdi.p_child.p_buf_name);
   optFormatSel2.p_caption = 'Use this scheme for all files with extension "'curExt'"';

   // populate the scheme combo box
   foreach (schemeName => scheme in g_schemes) {
      _combo_scheme._lbadd_item(scheme.name);
   }
   // get the scheme for this buffer
   schemeName = getOutlineSchemeNameForCurrentFile();
   _combo_scheme._lbfind_and_select_item(schemeName, '', true);

   // now we need to set which option button is active, so see if there's a
   // match for this extension
   _str key = lowcase(curExt);
   if (g_schemeMap.extensionSchemeMap._indexin(key)) {
      optFormatSel2.p_value = 1;
   } else {
      optFormatSel1.p_value = 1;
   }
}

void _button_ok.lbutton_up()
{
   _str fileName = _mdi.p_child.p_buf_name;
   _str bufExt = _get_extension(fileName);

   // determine whether the user picked to apply the scheme to the file 
   // or to the extension
   if (optFormatSel1.p_value == 1) {
      associateSchemeWithCurrentBuffer(_combo_scheme.p_text);
   } else {
      associateSchemeWithCurrentBufferExtension(_combo_scheme.p_text);
   }

   // kill the dialog
   p_active_form._delete_window(0);
}

void _button_cancel.lbutton_up()
{
   p_active_form._delete_window(-1);
}

void _button_config.lbutton_up()
{
   _str curSelection = _combo_scheme.p_text;
   _str schemeName = show('-modal _outline_view_config_form');
   // a name of blank will indicate that the user wants to cancel
   if (schemeName != '')
   {
      // re-populate the scheme combo box
      outlineViewScheme scheme;
      _combo_scheme._lbclear();
      _str temp;
      foreach (temp => scheme in g_schemes) {
         _combo_scheme._lbadd_item(scheme.name);
      }
      if (_combo_scheme._lbfind_and_select_item(schemeName)) {
         _combo_scheme._lbfind_and_select_item(curSelection, '', true);
      }
   }
}


