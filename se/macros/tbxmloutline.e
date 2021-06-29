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
#include "listbox.sh"
#include "xml.sh"
#import "main.e"
#import "cbrowser.e"
#import "xmlcfg.e"
#import "listbox.e"
#import "xmlwrap.e"
#import "proctree.e"
#import "fileman.e"
#import "projutil.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "se/ui/mainwindow.e"
#import "cfg.e"
#endregion

// used for managing previous combo box settings on the forms
static const LAST_SELECTED_TEXT= 'LastSelectedText';
static const XML_NAG= 'The Defs tool window now supports a customizable outline view for XML files.  Would you like to set that up now?';
static const ECLIPSE_XML_NAG= 'The Outline view now supports a customizable view for XML files.  Would you like to set that up now?';

// whether or not the outline view is enabled
bool def_outline_view_enabled = false;
// whether or not the user has been nagged to try out this great feature
bool def_outline_view_tryme_nag_shown = false;

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
   bool autoExpand;
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
static bool g_schemes_loaded;
// the scheme map, which tells us which scheme to apply
static schemeMap g_schemeMap;
static bool g_schemeMap_loaded;
// the current scheme being edited, used for sharing that scheme between dialogs
static outlineViewScheme* g_curEditScheme;
// the current rule being edited, used for sharing that rule between dialogs
static outlineViewRule* g_curEditRule;
// whether or not we're in the middle of nagging the user (to prevent subsequent nags)
static bool g_isBusyNaggingUserFlag = false;

definit()
{
   g_schemes._makeempty();
   g_schemeMap.fileSchemeMap._makeempty();
   g_schemeMap.extensionSchemeMap._makeempty();
   g_curEditRule = null;

   g_schemes_loaded=false;
   g_schemeMap_loaded=false;
}

/*
  Rules                 (XML elements) are case sensitive (stored as properties)
  Profiles              Case insensitive
  filenames/extensions  Converted to _file_case(key)
*/
static _str rule_case(_str key) {
   return key;
}

static void RetagOutlineViewBuffers()
{
   // Reset the modify flags for all "C/C++" buffers
   orig_window := p_window_id;
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   orig_buf_id := p_buf_id;
   for (;;) {
      if (isLanguageSupportedForOutlineView(p_LangId)) {
         ++p_LastModified;
      }
      _next_buffer('hr');
      if (p_buf_id == orig_buf_id) {
         break;
      }
   }
   // Finally, update the current buffer, and the tool windows
   // viewing the tagging information for that buffer.
   activate_window(orig_window);
}
/**
 * Toggles between the outline view being on and being off.
 */
_command void tagOutlineViewToggle()
{
   // flip the flag
   def_outline_view_enabled = !def_outline_view_enabled;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   // force an update of the defs window
   RetagOutlineViewBuffers();
   _UpdateCurrentTag(true);
}

#region Enabling / disabling the menu for the outline view

/**
 * Returns menu flags to indicate menu state for the outline view toggle. 
 * 
 * @param checkable - Whether the menu item is checkable or not.
 */
static int getOutlineViewToggleEnablement(bool checkable)
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

bool isOutlineViewActive(int child_wid= -1)
{
   if (def_outline_view_enabled == true) {
      return isCurrentBufferSupportedForOutlineView(child_wid);
   }
   return false;
}

/**
 * Returns menu flags to indicate menu state for the outline view menus given 
 * the current state. 
 * 
 * @param checkable - Whether the menu item is checkable or not.
 */
static int getOutlineViewMenuEnablement(bool checkable)
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
   int child_wid = _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }
   langID := child_wid.p_LangId;
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
   int child_wid = _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }
   langID := child_wid.p_LangId;
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
bool isCurrentBufferSupportedForOutlineView(int child_wid=-1)
{
   if (child_wid<=0) {
      if (child_wid==0) {
         return false;
      }
      child_wid = _MDIGetActiveMDIChild();
      if (!child_wid) {
         return false;
      }
   }
   langID := child_wid.p_LangId;
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
   
   int child_wid = _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }
   // set up the flag that says we should do nothing here if we're nagging the user
   g_isBusyNaggingUserFlag = true;

   // see if there's a scheme associated with this doc type
   _str schemeName = getOutlineSchemeNameForCurrentFile();
   _str fileName = child_wid.p_buf_name;
   fileKey := _file_case(fileName);

   // here's where we do the big nag check.  The first block tests the case where
   // the document supports the outline view, outline view is off and the user hasn't 
   // been nagged yet (they probably don't know about it)
   if (def_outline_view_enabled == false) {
      // if we are in here, this will result in a nag, so turn this flag off
      def_outline_view_tryme_nag_shown = true;
      _config_modify_flags(CFGMODIFY_DEFVAR);

      // this first check tests the case where the user has outline view turned off, 
      // the file is supoported for outlione view and there's no scheme for it, and 
      // this nag has never been shown
      msg := "";
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
               RetagOutlineViewBuffers();
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
            RetagOutlineViewBuffers();
            _UpdateCurrentTag(true);
         }
      }
   } else if ((def_outline_view_enabled == true) && (schemeName :== '')) {
      // so turn this flag off
      def_outline_view_tryme_nag_shown = true;
      _config_modify_flags(CFGMODIFY_DEFVAR);

      // this next check tests the case where the user the file is supoported for outlione 
      // view, outline view is on and there's no scheme for it
      msg := "You have not set up outline formatting for this type of XML document.  Would you like to do that now?";
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
bool isLanguageSupportedForOutlineView(_str langID) {
   // the following is a list of what constitutes support for the outline view.
   // currently it's just the document inheriting from XML.
   isSupported := _LanguageInheritsFrom('xml', langID);
   // don't allow ant or HTML, they're tagged differently
   isSupported = isSupported && (strieq(langID, 'ant') == false);
   isSupported = isSupported && (strieq(langID, 'html') == false);
   isSupported = isSupported && (strieq(langID, 'cfml') == false);
   isSupported = isSupported && (strieq(langID, 'android') == false);
   // also do not allow outline on XSD Schema or JSP tag lib files
   isSupported = isSupported && (strieq(langID, 'xsd') == false);
   isSupported = isSupported && (strieq(langID, 'tld') == false);
   return isSupported;
}

/**
 * Initializer for the scheme editor.
 */
void _outline_view_config_form.on_load()
{
   maybe_loadOutlineViewSchemes();
   maybe_loadSchemeMap();
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
   i := 0;
   j := 0;
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
   buttonWidth := 1100;
   buttonHeight := 340;

   // get the dimensions of the dialog
   int width = _dx2lx(p_active_form.p_xyscale_mode, p_active_form.p_client_width);
   int height = _dy2ly(p_active_form.p_xyscale_mode, p_active_form.p_client_height);

   // size the top controls
   _button_delete_scheme.p_x = width - buttonWidth - 100;
   _button_new_scheme.p_x = _button_delete_scheme.p_x - buttonWidth - 50;
   _combo_scheme.p_x_extent = _button_new_scheme.p_x - 70;

   // size the OK and cancel buttons
   _button_cancel.p_x = width - buttonWidth - 100;
   _button_cancel.p_y = height - 500;
   _button_ok.p_x = _button_cancel.p_x - buttonWidth - 50;
   _button_ok.p_y = _button_cancel.p_y;

   // size the element list
   _lb_elements.p_y_extent = _button_cancel.p_y - buttonHeight - 100;
   _button_new_element.p_y = _lb_elements.p_y_extent + 50;
   _button_delete_element.p_y = _button_new_element.p_y;

   // size the frame
   _frame_el_props.p_x_extent = width - 100;
   _frame_el_props.p_height = _lb_elements.p_height;
   _text_format.p_x_extent = _frame_el_props.p_width - 150;
   ctllabel6.p_x_extent = _frame_el_props.p_width - 150;
   ctllabel8.p_width = ctllabel6.p_width;
}

/**
 * Returns a pointer to the scheme currently selected in the scheme combo box.
 */
static outlineViewScheme* getCurrentScheme()
{
   // get the selected scheme
   selSchemeName := _combo_scheme.p_text;
   key := lowcase(selSchemeName);
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

   // first, make sure the current item is updated
   UpdateCurrentElement();

   // save the newly defined rule sets
   saveOutlineViewRules();

   // see if we need to associate the current scheme with the current file
   if (isCurrentBufferSupportedForOutlineView() == true) {
      associateSchemeWithCurrentBuffer(selSchemeName);
   }

   tag_recache_xmloutlineview_profiles();
   // kill this dialog and return the selected scheme name
   p_active_form._delete_window(selSchemeName);
}

/**
 * Updates the scheme map file to associate the current buffer file name to a 
 * specific scheme.
 * 
 * @param schemeName - the scheme to associate with the current buffer file name
 */
static void associateSchemeWithCurrentBuffer(_str schemeName)
{
   int child_wid = _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }
   // add a map entry for this file
   _str fileName = child_wid.p_buf_name;
   fileKey := _file_case(fileName);

   schemeMapEntry mapEntry;
   mapEntry.criteria = fileName;
   mapEntry.schemeName = schemeName;
   g_schemeMap.fileSchemeMap:[fileKey] = mapEntry;

   // save the new association
   saveSchemeMap();
   RetagOutlineViewBuffers();
}

/**
 * Updates the scheme map file to associate the current buffer's extension 
 * to a specific scheme. 
 * 
 * @param schemeName - the scheme to associate with the current buffer's 
 *                   extension
 */
static void associateSchemeWithCurrentBufferExtension(_str schemeName)
{
   int child_wid = _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }
   maybe_loadSchemeMap();
   _str fileName = child_wid.p_buf_name;
   _str bufExt = _get_extension(fileName);
   extKey := _file_case(bufExt);

   // the user decided to apply this scheme to all files with the 
   // current exxtension.  First, go through the list of files and 
   // remove all entries that have this extension
   key := "";
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
   RetagOutlineViewBuffers();
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
   newSchemeKey := lowcase(newScheme.name);
   // a name of blank will indicate that the user wants to cancel
   if (newScheme.name != '') {
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
   selSchemeName := _combo_scheme.p_text;
   if (selSchemeName == '') {
      return;
   }
   // remove it from the hashtable
   key := lowcase(selSchemeName);
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
      _str newRuleKey = rule_case(newRule.nodeType);
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
      _str key = rule_case(selElementName);
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
   elementFound := false;

   UpdateCurrentElement();
   // get the active scheme (selected in the list box)
   outlineViewScheme* curScheme = getCurrentScheme();
   if (curScheme != null) {
      _str selectedElementName = _lb_elements._lbget_seltext();
      if (selectedElementName != '') {
         // find it in the hashtable
         _str key = rule_case(selectedElementName);
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
static void UpdateCurrentElement()
{
   // get the active scheme (selected in the list box)
   outlineViewScheme* curScheme = getCurrentScheme();
   if (curScheme) {
      // get the name of the previously selected item
      _str previousElementName = _GetDialogInfoHt(LAST_SELECTED_TEXT, _lb_elements.p_window_id);
      if ((previousElementName != null) && (previousElementName != '')) {
         // find the rule in the hashtable for that item
         _str key = rule_case(previousElementName);
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
 * Returns the folder in SlickEdit's install directory where the scheme and map 
 * files should be. 
 * 
 * @return _str - See description
 */
_str getShippedOutlineSchemeDir() {
   // assign to a variable so we can inspect the value when debugging
   _str schemesDir = _getSysconfigPath() :+ 'formatschemes' :+ FILESEP :+ 'outlineschemes' :+ FILESEP;
   return schemesDir;
}

static void maybe_loadOutlineViewSchemes() {
   if (g_schemes_loaded) {
      return;
   }
   g_schemes_loaded=true;
   loadOutlineViewSchemes();
}
/**
 * Loads the outline view schemes from the given file into memory.
 */
static int loadOutlineViewSchemes()
{
   g_schemes._makeempty();
   _str profileNames[];
   _plugin_list_profiles(VSCFGPACKAGE_XMLOUTLINEVIEW_PROFILES,profileNames);
   for (i := 0; i < profileNames._length(); i++) {
      int handle=_plugin_get_profile(VSCFGPACKAGE_XMLOUTLINEVIEW_PROFILES,profileNames[i]);
      if (handle<0) {
         continue;
      }
      outlineViewScheme scheme;
      // get the name of the scheme
      scheme.name = profileNames[i];
      hashKey := lowcase(scheme.name);
      g_schemes:[hashKey] = scheme;
      // get a pointer to the new one in the collection
      outlineViewScheme* curScheme = &(g_schemes:[hashKey]);
      // get the rules for this scheme
      profileNode:=_xmlcfg_set_path(handle,"/profile");
      int ruleNode = _xmlcfg_get_first_child(handle, profileNode,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      while (ruleNode >= 0) {
         outlineViewRule rule;
         // get the name of the node this applies to
         rule.nodeType = _xmlcfg_get_attribute(handle, ruleNode, VSXMLCFG_PROPERTY_NAME, '');
         parse _xmlcfg_get_attribute(handle, ruleNode, VSXMLCFG_PROPERTY_VALUE, '') with auto autoExpandValue ';' auto text;
         hashKey = rule_case(rule.nodeType);
         
         rule.ruleFormat = text;
         if ((autoExpandValue != null)  && (autoExpandValue :== '1')) {
            rule.autoExpand = true;
         } else {
            rule.autoExpand = false;
         }
         // make sure it's not a duplicate rule
         if (!(curScheme->rules._indexin(hashKey))) {
            curScheme->rules:[hashKey] = rule;
         }
         
         // try to get the next
         ruleNode = _xmlcfg_get_next_sibling(handle, ruleNode,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      }
      _xmlcfg_close(handle);
   }
   return profileNames._length();
}

/**
 * Saves the outline view profiles
 */
static void saveOutlineViewRules()
{
   outlineViewScheme scheme;
   outlineViewRule rule;
   foreach (auto profileName => scheme in g_schemes) {
      handle := _xmlcfg_create('', VSENCODING_UTF8);
      if (handle < 0) return; // This is really bad
      profileNode:=_xmlcfg_set_path(handle,"/profile");
      _xmlcfg_set_attribute(handle,profileNode,VSXMLCFG_PROFILE_NAME,_plugin_append_profile_name(VSCFGPACKAGE_XMLOUTLINEVIEW_PROFILES,profileName));
      _xmlcfg_set_attribute(handle,profileNode,VSXMLCFG_PROFILE_VERSION,VSCFGPROFILE_XMLOUTLINEVIEW_VERSION);

      // now add the rules
      foreach (auto elementName => rule in scheme.rules) {
         // only include the rule if there's a format for it
         if (rule.ruleFormat != "") {
            node:=_xmlcfg_add_property(handle,profileNode, rule.nodeType,(rule.autoExpand?'1':'0'):+';':+rule.ruleFormat);
         }
      }
      _plugin_set_profile(handle);
      _xmlcfg_close(handle);
   }
}

static void maybe_loadSchemeMap() {
   if (g_schemeMap_loaded) {
      return;
   }
   g_schemeMap_loaded=true;
   loadSchemeMap();
}
/**
 * Loads the outline view scheme map into memory.  If the file doesn't exist in
 * the user's config foler, a default one is copied from the install folder. 
 */
static void loadSchemeMap()
{
   // clear the existing scheme map
   g_schemeMap._makeempty();
   // load the file
   int handle = _plugin_get_profile(VSCFGPACKAGE_XMLOUTLINEVIEW,VSCFGPROFILE_XMLOUTLINEVIEW_FILEMAP);
   if (handle>=0) {
      _str properties[];
      _xmlcfg_find_simple_array(handle, '/profile/p', properties);
      for (i := 0; i < properties._length(); i++) {
         int node = (int)properties[i];
         schemeMapEntry curEntry;
         curEntry.criteria=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_NAME);
         curEntry.schemeName=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
         // add it to the map
         _str key = curEntry.criteria;
         key = stranslate(key, FILESEP, FILESEP2);
         key = _replace_envvars(key);
         key = _file_case(key);
         g_schemeMap.fileSchemeMap:[key] = curEntry;
      }
      _xmlcfg_close(handle);
   }
   handle = _plugin_get_profile(VSCFGPACKAGE_XMLOUTLINEVIEW,VSCFGPROFILE_XMLOUTLINEVIEW_EXTENSIONMAP);
   if (handle>=0) {
      _str properties[];
      _xmlcfg_find_simple_array(handle, '/profile/p', properties);
      for (i := 0; i < properties._length(); i++) {
         int node = (int)properties[i];
         schemeMapEntry curEntry;
         curEntry.criteria=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_NAME);
         curEntry.schemeName=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
         // add it to the map
         _str key = curEntry.criteria;
         key = _file_case(key);
         g_schemeMap.extensionSchemeMap:[key] = curEntry;
      }
      _xmlcfg_close(handle);
   }
}

static void saveProfileMap(schemeMapEntry (&fileSchemeMap):[],_str profileName) {

   handle := _xmlcfg_create('', VSENCODING_UTF8);
   if (handle < 0) return; // This is really bad
   profileNode:=_xmlcfg_set_path(handle,"/profile");
   _xmlcfg_set_attribute(handle,profileNode,VSXMLCFG_PROFILE_NAME,_plugin_append_profile_name(VSCFGPACKAGE_XMLOUTLINEVIEW,profileName));
   _xmlcfg_set_attribute(handle,profileNode,VSXMLCFG_PROFILE_VERSION,VSCFGPROFILE_XMLOUTLINEVIEW_VERSION);

   schemeMapEntry mapEntry;
   _str fileName;
   foreach (fileName => mapEntry in g_schemeMap.fileSchemeMap) {
      node:=_xmlcfg_add_property(handle,profileNode, mapEntry.criteria,mapEntry.schemeName);
   }
   _plugin_set_profile(handle);
   _xmlcfg_close(handle);
}
   
/**
 * Saves the outline view scheme map to the proper file in the user's 
 * config folder. 
 */
static void saveSchemeMap()
{
   saveProfileMap(g_schemeMap.fileSchemeMap,VSCFGPROFILE_XMLOUTLINEVIEW_FILEMAP);
   saveProfileMap(g_schemeMap.extensionSchemeMap,VSCFGPROFILE_XMLOUTLINEVIEW_EXTENSIONMAP);
}

#endregion

/**
 * Retrieves an array of all unique elements in the current buffer's XML.
 * 
 * @return _str - An array of unique XML elements in the current buffer.
 */
static _str getXmlElementsInBuffer() []
{
   _str elements[];
   int child_wid = _MDIGetActiveMDIChild();
   if (!child_wid) {
      return elements;
   }
   // parse the current buffer with xmlcfg
   int status;
   int xmlDocument = _xmlcfg_open_from_buffer(child_wid, status);
   if (xmlDocument < 0) {
      return elements;
   }
   // get the unique elements
   _str elementsHash:[];
   getXmlElements2(xmlDocument, TREE_ROOT_INDEX, elementsHash);
   // close the XML DOM
   _xmlcfg_close(xmlDocument);
   // transfer them to an array and sort
   i := 0;
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
static void getXmlElements2(int xmlDocument, int parentXmlElement, _str (&elements):[])
{
   int childXmlElement = _xmlcfg_get_first_child(xmlDocument, parentXmlElement);
   while (childXmlElement > 0) {
      elementName := _xmlcfg_get_name(xmlDocument, childXmlElement);
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
   maybe_loadOutlineViewSchemes();
   maybe_loadSchemeMap();
   schemeName := "";
   customSchemeFound := false;
   
   int child_wid = _MDIGetActiveMDIChild();
   if (!child_wid) {
      return '';
   }
   // is there a scheme mapped for this file name?
   _str fileName = child_wid.p_buf_name;
   fileKey := _file_case(fileName);
   if (g_schemeMap.fileSchemeMap._indexin(fileKey)) {
      schemeMapEntry mapEntry = g_schemeMap.fileSchemeMap:[fileKey];
      schemeName = mapEntry.schemeName;
      customSchemeFound = true;
   }
   // is there a scheme mapped for this extension?
   if (customSchemeFound == false) {
      _str extKey = _get_extension(child_wid.p_buf_name);
      extKey = _file_case(extKey);
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
   _str newElementNameKey = rule_case(newElementName);
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
   newSchemeNameKey := lowcase(_text_scheme.p_text);
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
   maybe_loadOutlineViewSchemes();
   maybe_loadSchemeMap();
   schemeName := "";
   outlineViewScheme scheme;

   int child_wid = _MDIGetActiveMDIChild();
   // get the current extension of the file
   curExt := "";
   if (child_wid) curExt=_get_extension(child_wid.p_buf_name);
   optFormatSel2.p_caption = 'Use this scheme for all files with extension "'curExt'"';

   // Add the "Default" scheme if we don't already have one
   if (!g_schemes._indexin("Default")) {
      _combo_scheme._lbadd_item("Default");
   }

   // populate the scheme combo box
   foreach (schemeName => scheme in g_schemes) {
      _combo_scheme._lbadd_item(scheme.name);
   }

   // get the scheme for this buffer
   schemeName = getOutlineSchemeNameForCurrentFile();
   _combo_scheme._lbfind_and_select_item(schemeName, '', true);

   // now we need to set which option button is active, so see if there's a
   // match for this extension
   key := _file_case(curExt);
   if (g_schemeMap.extensionSchemeMap._indexin(key)) {
      optFormatSel2.p_value = 1;
   } else {
      optFormatSel1.p_value = 1;
   }
}

void _button_ok.lbutton_up()
{
   int child_wid = _MDIGetActiveMDIChild();
   if (!child_wid) {
      return;
   }
   _str fileName = child_wid.p_buf_name;
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
   curSelection := _combo_scheme.p_text;
   _str schemeName = show('-modal _outline_view_config_form');
   // a name of blank will indicate that the user wants to cancel
   if (schemeName != '') {
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


