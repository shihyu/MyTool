////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50640 $
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
#include "cvs.sh"
#include "debug.sh"
#include "perforce.sh"
#include "slick.sh"
#include "subversion.sh"
#include "git.sh"
#include "mercurial.sh"
#require "sc/controls/customizations/ToolbarCustomizationHandler.e"
#require "sc/controls/customizations/MenuCustomizationHandler.e"
#require "se/options/OptionsTree.e"
#require "se/options/OptionsConfigTree.e"
#require "se/options/OptionsImportTree.e"
#require "se/options/OptionsExportTree.e"
#require "se/lang/api/LanguageSettings.e"
#require "se/alias/AliasFile.e"
#import "adaptiveformatting.e"
#import "beautifier.e"
#import "box.e"
#import "c.e"
#import "clipbd.e"
#import "codehelp.e"
#import "codetemplate.e"
#import "complete.e"
#import "config.e"
#import "cvs.e"
#import "debuggui.e"
#import "dlgman.e"
#import "filecfg.e"
#import "fileman.e"
#import "files.e"
#import "guiopen.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "mprompt.e"
#import "options.e"
#import "packs.e"
#import "picture.e"
#import "recmacro.e"
#import "search.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "treeview.e"
#import "vlstobjs.e"
#import "xmlwrap.e"
#import "se/ui/NavMarker.e"
#import "se/options/OptionsCheckBoxTree.e"
#require "se/datetime/DateTime.e"

using se.lang.api.LanguageSettings;
using se.options.OptionsConfigTree;
using se.options.OptionsExportTree;
using se.options.OptionsImportTree;
using se.options.OptionsTree;
using se.datetime.DateTime;
using namespace se.options;
using namespace sc.controls.customizations;

#define OPTIONSFILE "SlickEditOptions"
#define COREOPTIONSFILE "SlickEditCorePreferences"

#define PROPERTY_GROUP_COLOR        12632256

/**
 * Checks for any changes to all toolbars and then saves changes in an XML file.
 */
void checkForChangesToToolbars()
{
   ToolbarCustomizationHandler tch;
   tch.saveToolbarChanges();
}

/**
 * Resets any changes that were saved to a toolbar in an XML file.
 * 
 * @param FormName         name of toolbar to reset
 */
void resetToolbarXMLChanges(_str FormName)
{
   // remove any changes from the xml file
   ToolbarCustomizationHandler tch();
   tch.removeToolbarMods(FormName);
}

/**
 * This command brings up the export groups editor.  From here, you can make 
 * changes to your export groups and then export the options within a group. 
 *  
 * There are several options you can use to alter the behavior of this command. 
 * <-p> - to see export groups which contain protections 
 * <-g groupName> - load up dialog with a specific group chosen 
 */
_command void export_groups() name_info(',')
{
   admin := false;
   groupName := '';
   
   // go through args
   args := arg(1);
   currentArg := '';
   while (args != '') {
      parse args with currentArg args;
      switch (lowcase(currentArg)) {
      case '-p':
         admin = true;
         break;
      case '-g':
         parse args with groupName args;
         break;
      }
   }
   
   // now load up the dialog with these options
   show('-modal -xy _options_tree_form', OP_EXPORT, groupName, false, admin);
}

/**
 * This command starts the process of exporting user options.  This assumes you 
 * either want to export all your options or already have set up a group to 
 * export.  To set up export groups, see {@link export_groups}.
 * 
 * @param options          specify options to define how the export should work 
 *                         -p - Admin mode, used to specifying protections
 *                         -g <groupname>, used to specify a particular group to
 *                          export
 *                         -a - export all options.  Cannot be used with -p or
 *                          -g.
 */
_command void export_options(_str options = '') name_info(',')
{
   admin := false;
   all := false;
   groupName := '';
   
   // go through args
   currentArg := '';
   while (options != '') {
      parse options with currentArg options;
      switch (lowcase(currentArg)) {
      case '-p':
         if (!all) admin = true;
         break;
      case '-g':
         if (!all) parse options with groupName options;
         break;
      case '-a':
         all = true;
         admin = false;
         groupName = '';
         break;
      }
   }
   
   OptionsExportTree optionsExportTree;
   if (optionsExportTree.init()) {
      
      package := '';
      protectionCode := '';
      
      _str groups:[];
      if (all) {
         groups:[ALL_OPTIONS_GROUP] = false;
      } else {
         optionsExportTree.getExportGroupNamesAndProtections(groups);
         if (groupName != '' && groups._indexin(groupName)) {
            _str temp:[];
            temp:[groupName] = groups:[groupName];
            groups = temp;
         }
      }
         
      result := p_active_form.show('-modal _export_options_form', groups, admin);
      if (result == IDOK) {
         package = _param1;
         protectionCode = _param2;
         if (!all) groupName = _param3;

         refresh();
         
         optionsExportTree.export(package, protectionCode, groupName);
      }
      
      optionsExportTree.close();
   }
}

_command void import_options() name_info(',')
{
   show('-modal -xy _options_tree_form', OP_IMPORT);
}

/**
 * Enables/disables the Next and Previous buttons on the options dialog when in 
 * Quick Start Wizard mode.  When disabling, the p_enabled values of the buttons 
 * are stored in the nextEnabled and prevEnabled parameters.  When enabling, the 
 * p_enabled values of the buttons are restored to the values of the nextEnabled 
 * and prevEnabled parameters. 
 * 
 * @param doDisable                 true to disable the buttons, false to 
 *                                  restore them to their previous states
 * @param nextEnabled               whether the next button is/was enabled
 * @param prevEnabled               whether the prev button is/was enabled
 */
void disableEnableNextPreviousOptionsButtons(boolean doDisable, boolean &nextEnabled, boolean &prevEnabled)
{
   // make sure we still have an options form to go to
   optionsForm := getOptionsFormFromEmbeddedDialog(); 
   if (optionsForm <= 0) return;

   origWid := p_window_id;
   p_window_id = optionsForm;

   _ctl_cancel.p_enabled = _ctl_apply.p_enabled = _ctl_help.p_enabled = !doDisable;

   if (doDisable) {
      // in this case, we disable the buttons after saving their states
      nextEnabled = _ctl_ok.p_enabled;
      prevEnabled = _ctl_previous.p_enabled;

      _ctl_ok.p_enabled = _ctl_previous.p_enabled = false;
   } else {
      // restore them now
      _ctl_ok.p_enabled = nextEnabled;
      _ctl_previous.p_enabled = prevEnabled;
   }

   p_window_id = origWid;
}

/**
 * This command clears all the options protections that exist for this user.  If 
 * the options dialog is opened when this command is called, the dialog is 
 * closed and then re-opened after the protections are cleared. 
 */
_command void clear_all_protections() name_info(',')
{
   // make sure the options dialog is closed
   optionsWid := getOptionsForm(OP_CONFIG, false);
   wasOpen := (optionsWid > 0);
   if (wasOpen) {
      p_window_id = optionsWid;
   
      // in this case, we have to close this options dialog by cancelling first - hopefully this won't come up often
      cancelBtn := _find_control('_ctl_cancel');
      cancelBtn.call_event(false, cancelBtn, LBUTTON_UP, 'W');
   }

   // open up the config parser
   se.options.OptionsConfigurationXMLParser configParser;
   configParser.clearAllProtections();

   // reopen the options dialog
   if (wasOpen) config();
}

// THESE ARE USED TO RETRIEVE THINGS FOR THE OPTIONS DIALOG USING _GetDialogInfoHtPtr()
/**
 * Search is on a timer - the search does not actually start
 * until the user pauses in typing.  
 */
#define SEARCH_TIMER    'searchTimer'
/**
 * We put a pause before we show the right panel corresponding 
 * to the chosen node - makes things load faster. 
 */
#define DISPLAY_TIMER   'displayTimer'
/**
 * Our main object
 */
#define OPTIONS         'options'
/**
 * Whether this is the first time the tree index has been 
 * changed.  A hokey way to set the search box to be the 
 * selected item on open (what with the timers screwing up the 
 * easy way). 
 */
#define FIRST_TIME      'firstTime'
/**
 * Determines what the purpose of this options dialog is - one of the 
 * OptionsPurpose enum. 
 */
#define PURPOSE         'optionsPurpose'
/**
 * Whether this run of the options export was performed with the administrator 
 * command to enable protections. 
 */
#define PROTECT         'protectOptions'
/**
 * Used to specify that we want to export ALL of our options.
 */
#define ALL_OPTIONS_GROUP     'All Options'
/**
 * Object used to change the tree index (usually tree, but sometimes buttons)
 */
#define CAUSED_TREE_CHANGE    'causedTreeChange'

/**
 * Determines if the options dialog is currently open with the given purpose.
 * 
 * @param purpose             member of the OptionsPurpose enum
 * 
 * @return                    true if the options dialog (with the given 
 *                            purpose) is open, false otherwise
 */
boolean isOptionsOpen(int purpose)
{
   form := getOptionsFormName(purpose);
   return (_find_formobj(form,'n') != 0);
}

/**
 * Retrieves the options dialog window id, but only when called from a dialog 
 * embedded into the options dialog. 
 * 
 * @return                    window id of options dialog
 */
int getOptionsFormFromEmbeddedDialog()
{
   // find out the purpose of this options
   form := p_active_form;                    // property sheet or embedded dialog
   if (form > 0) form = form.p_parent;      // _ctl_frame
   if (form > 0) form = form.p_parent;      // _options_tree_form
   
   return form;
}

void setOptionsTreeChangeCause(int value, int wid = 0)
{
   _SetDialogInfoHt(CAUSED_TREE_CHANGE, value, wid);
}

int getOptionsTreeChangeCause()
{
   return _GetDialogInfoHt(CAUSED_TREE_CHANGE);
}

typeless * getOptionsDisplayTimerPtr()
{
   return _GetDialogInfoHtPtr(DISPLAY_TIMER);
}

typeless * getOptionsSearchTimerPtr()
{
   return _GetDialogInfoHtPtr(SEARCH_TIMER);
}

/**
 * The options dialog has many purposes (see OptionsPurpose enum).  The name of 
 * the form itself changes upon open depending on its purpose.  Given a purpose, 
 * this function returns the name of the options dialog. 
 * 
 * @param purpose             purpose of options dialog to check
 * 
 * @return                    name of options dialog
 */
static _str getOptionsFormName(int purpose)
{
   form := '_options_tree_form';
   switch (purpose) {
   case OP_CONFIG:
      form = '_options_config_tree_form';
      break;
   case OP_EXPORT:
      form = '_options_export_tree_form';
      break;
   case OP_IMPORT:
      form = '_options_import_tree_form';
      break;
   case OP_QUICK_START:
      form = '_options_quick_start_tree_form';
      break;
   }
   
   return form;
}

/**
 * Shows the Aliases editor within the options dialog based on 
 * the specified filename - either a Language-Specific Aliases 
 * node or the Global Aliases. 
 * 
 * @param _str filename       alias filename to open
 * @param _str args           arguments to be sent to alias 
 *                            editor
 * 
 */
void showAliasEditorForFilename(_str filename, _str args = '')
{
   // we're given a file - we must figure out which language it is or if it's global aliases
   modename := '';

   // check for the directory alias file
   aliasfilename := seGetSlickEditAliasFile();

   // not equal, check the language aliases
   if (filename != aliasfilename) {
      index := name_match("def-alias-", 1, MISC_TYPE);
      for (;;) {
         if (!index) break;
         langFilename := name_info(index);
         if (filename == langFilename) {
            _str lang;
            parse name_name(index) with 'def-alias-'lang;
            modename = _LangId2Modename(lang);
            break;
         }
         index = name_match("def-alias-", 0, MISC_TYPE);
      }
   }

   // if we can't find a mode name, then just show the global aliases
   if (modename == '') {
      config('Global Aliases');
   } else {
      config(modename' > Aliases', 'L', args);
   }
}

/**
 * Shows a specified options node for the given mode name.
 * 
 * @param _str modeName       language whose options we want to 
 *                            see
 * @param _str options        an optional specific node to see 
 *                            (leave blank to just see the
 *                            language category node)
 * @param _str args           any arguments to send to the node
 * 
 */
void showOptionsForModename(_str modeName, _str options = '', _str args = '')
{
   if (options != '') modeName :+= ' > 'options;
   optWid := config(modeName, 'L', args);
}

/** 
 * Shows the language-specific Adaptive Formatting options. To
 * be used when the options dialog is already open to a
 * language-specific node.
 * 
 */
void showAdaptiveFormattingOptionsForLanguage()
{
   // we should be currently looking at something with a mode name in the frame caption
   wid := getOptionsForm();
   if (wid) {
      
      wid = wid._find_control('_ctl_frame');
      if (wid) {
         _str modeName = wid.p_caption;
         parse modeName with modeName '>' .;
   
         showOptionsForModename(strip(modeName), 'Adaptive Formatting');
      }
   }
}

/**
 * Adds a new language to the current options dialog.
 * 
 * @param _str langId       new language id
 * 
 */
void addNewLanguageToOptionsXML(_str langId)
{
   optWid := getOptionsForm();
   if (optWid) {
      OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS, optWid);
      optionsConfigTree -> addNewLanguage(langId);
   }
}

/**
 * Removes a language from the current options dialog.
 * 
 * @param _str language       language name
 * 
 */
void removeLanguageFromOptionsXML(_str language)
{
   optWid := getOptionsForm();
   if (optWid) {
      se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS, optWid);
      optionsConfigTree -> removeLanguage(language);
   }
}

/**
 * This function should be called from the apply callback of 
 * _language_general_forms, where users can rename languages. 
 * The modename is scheduled for renaming during the apply, but 
 * the renaming does not occur until all other options are 
 * applied. 
 * 
 * @param _str modeName          old mode name
 * @param _str newModeName       new mode name
 * 
 */
void scheduleModeNameForRenaming(_str modeName, _str newModeName)
{
   // we don't bother if the options aren't open - they'll pick up the new 
   // mode name during the next open

   optWid := getOptionsForm();
   if (optWid) {
      se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS, optWid);
      optionsConfigTree -> addLanguageToRename(modeName, newModeName);
   }
}

/**
 * Returns the text to be displayed in an adaptive formatting 
 * link (such as on the Language-Specific Indent settings page).
 * 
 * @param _str langId         language ID we want the text for   
 * @param int flag            adaptive formatting setting
 * 
 * @return _str               the text to put on an adaptive 
 *                            formatting link
 */
_str getAdaptiveLinkText(_str langId, int flag)
{
   // first check if it has been turned on/off while the options has been opened
   isOn := isModifiedAdaptiveFormattingOn(langId, flag);

   if (isOn) return '(Adaptive ON)';
   else return '(Adaptive OFF)';
}

/**
 * Retrieves a list of languages which have the given option 
 * protected.  Path must be the end of a subpath to a 
 * language-specific option, for instance 'Indent > Syntax 
 * Indent'. 
 * 
 * @param _str optionsPath       options subpath 
 * @param _str langs[]           list of langIDs 
 * 
 */
void getLanguagesWithOptionProtected(_str optionsPath, _str (&langs)[])
{
   optWid := getOptionsForm();
   if (optWid) {
      se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS, optWid);
      optionsConfigTree -> getLangIdsWithOptionProtected(optionsPath, langs);
   }
}

/**
 * Adds a new version control provider to the current options 
 * dialog. 
 * 
 * @param _str newVCP       new version control provider 
 * 
 */
void addNewVersionControlProviderToOptionsXML(_str newVCP)
{
   optWid := getOptionsForm();
   if (optWid) {
      se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS, optWid);
      optionsConfigTree -> addNewVersionControlProvider(newVCP);
   }
}

/**
 * Removes a version control provider from the current options 
 * dialog. 
 * 
 * @param _str vcp       version control provider to be removed
 * 
 */
void removeVersionControlProviderFromOptionsXML(_str vcp)
{
   optWid := getOptionsForm();
   if (optWid) {
      se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS, optWid);
      optionsConfigTree -> removeVersionControlProvider(vcp);
   }
}

/** 
 * Renames one of the version control providers.  This is only 
 * available for providers added by the user.
 * 
 * @param _str oldVCName         old provider name
 * @param _str newVCName         new provider name
 * 
 */
void renameVersionControlProvider(_str oldVCName, _str newVCName)
{
   // we don't bother if the options aren't open - they'll pick up the new 
   // mode name during the next open
   optWid := getOptionsForm();
   if (optWid) {
      se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS, optWid);
      optionsConfigTree -> renameVersionControlProvider(oldVCName, newVCName);
   }
}

/** 
 * Goes to the specified child node under the current options 
 * dialog node.  Must be called while the options dialog is 
 * opened. 
 * 
 * @param _str childNode         child node to visit
 * 
 */
_command void goToChildNode(_str childNode = '') name_info(',')
{
   // we should be currently looking at something with a mode name in the frame caption
   wid := getOptionsForm();
   if (wid) {
      
      wid = wid._find_control('_ctl_frame');
      if (wid) {
         node := wid.p_caption;
         if (childNode != '') {
            node :+= ' > 'childNode;
         }
   
         config(node);
      } else if (beautifier_profile_editor_active()) {
         beautifier_profile_editor_goto(childNode);
      }
   }
}

#region Special Exclusion and Visibility Functions

/**
 * The options dialog has a distinction between Exclusions and 
 * Visibility.  Options which are excluded will not be available 
 * throughout the options dialog session.  They are based on 
 * permanent settings like the machine or whether we are using 
 * Eclipse.  Option visibility is based on temporary settings, 
 * such as emulation. 
 */

/**
 * Determines whether the Encoding option would be unavailable 
 * at this point. 
 * 
 * @return boolean            true if EXcluded, false if 
 *                            included
 */
boolean isEncodingExcluded()
{
   return !_UTF8();
}

/**
 * Determines whether the VCPP Setup options would be 
 * visible at this point. 
 *  
 * Included as a Visibility setting because it relies partially 
 * on a _default_option setting. 
 *  
 * @return boolean            true if visible, false if 
 *                            invisible
 */
boolean isVCPPSetupVisible()
{
   if (_win32s()==1) return false;

   if (__UNIX__) return false;

   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_VCPP_SETUP)) return false;

   return true;
}

/**
 * Determines whether the ISPF options would be visible at this 
 * point. 
 *  
 * Included as a Visibility setting because it relies on the 
 * current emulation. 
 *  
 * @return boolean            true if visible, false if 
 *                            invisible
 */
boolean isISPFOptionsVisible()
{
   return (def_keys == 'ispf-keys');
}

/**
 * Determines whether the Vim options would be visible at this 
 * point. 
 *  
 * Included as a Visibility setting because it relies on the 
 * current emulation. 
 *  
 * @return boolean            true if visible, false if 
 *                            invisible
 */
boolean areVimOptionsVisible()
{
   return (def_keys == 'vi-keys');
}

/**
 * Determines whether the PVCS-specific options should be visible.
 * 
 * @param vcs                 current version control system
 * 
 * @return boolean            true if excluded, false if included
 */
boolean isUsePVCSWildcardsExcludedForVCP(_str vcs)
{
   return (pos('PVCS', vcs) == 0);
}

/**
 * Determines whether the language-specific file options are excluded for the 
 * current language. 
 * 
 * @param langId              lang id to check for
 * 
 * @return boolean            true if excluded, false if included
 */
boolean isFileOptionExcludedForLanguage(_str langId)
{
   return (langId == ALL_LANGUAGES_ID);
}

boolean isExpandXMLDOCOptionExcludedForLanguage(_str langId)
{
   return (langId != 'c');
}

boolean isNewBeautifierOptionExcludedForLanguage(_str langId)
{
   return (!new_beautifier_supported_language(langId));
}

boolean isLangAutoClosePadBracesExcludedForLanguage(_str langId)
{
   keytab := LanguageSettings.getKeyTableName(langId);
   if (keytab != '') {
      switch (keytab) { // known keytables to support close brace insertion commands
      case 'matlab-keys':
         return false;
      }
   }

   return true;
}

boolean isLangAutoCloseAdvanceBraceExcludedForLanguage(_str langId)
{
   return (isLangAutoCloseBraceExcludedForLanguage(langId) || 
      !supports_advanced_bracket_cfg(langId));
}

boolean isLangAutoCloseBraceExcludedForLanguage(_str langId)
{
   keytab := LanguageSettings.getKeyTableName(langId);
   if (keytab != '') {
      switch (keytab) { // known keytables to support close brace insertion commands
      case 'awk-keys':
      case 'c-keys':
      case 'slick-keys':
      case 'java-keys':
      case 'actionscript-keys':
      case 'vera-keys':
      case 'perl-keys':
      case 'tcl-keys':
      case 'ruby-keys':
      case 'css-keys':
         return false;
         break;
      case 'matlab-keys':
//    case 'scala-keys':
         return false;
      }
   }

   return true;
}

#endregion Special Exclusion and Visibility Functions

#region Export/Import functions for nodes without dialogs

/**
 * Some options are still controlled outside of the existing options dialog, and 
 * yet we wish to have a way to export/import them.  This way, they don't have 
 * actual dialogs that will appear in the Options Dialog, but they will have 
 * export/import callbacks. 
 */

_str _project_templates_export_settings(_str &path)
{
   error := '';

   // this one is easy
   justFilename := VSCFGFILE_USER_PRJTEMPLATES;
   templateFile := _ConfigPath() :+ justFilename;
   if (file_exists(templateFile)) {
      // copy this file to our new path
      if (copy_file(templateFile, path :+ justFilename)) {
         error = 'Error copying project templates file 'templateFile'.' :+ OPTIONS_ERROR_DELIMITER;
      } path = justFilename;
   }

   return error;
}

_str _project_templates_import_settings(_str &file)
{
   status := importProjectPacks(file);

   if (status) {
      return 'Error importing project templates from 'file;
   } else return '';
}

_str _menu_customizations_export_settings(_str &path)
{
   error := '';

   // see if we have made any customizations for our menu
   justFilename := 'userMenus.xml';
   menuFile := _ConfigPath() :+ justFilename;
   if (file_exists(menuFile)) {
      // copy this file to our new path
      if (copy_file(menuFile, path :+ justFilename)) {
         error = 'Error copying menu customization file 'menuFile'.' :+ OPTIONS_ERROR_DELIMITER;
      } path = justFilename;
   }

   return error;
}

_str _menu_customizations_import_settings(_str &file)
{
   error := '';

   // we should have a file here with some customization in it
   MenuCustomizationHandler mch;
   mch.importChanges(file);

   return error;
}

_str _toolbar_customizations_export_settings(_str &path)
{
   error := '';

   // see if we have made any customizations for our menu
   justFilename := 'userToolbars.xml';
   tbFile := _ConfigPath() :+ justFilename;
   if (file_exists(tbFile)) {
      // copy this file to our new path
      if (copy_file(tbFile, path :+ justFilename)) {
         error = 'Error copying toolbar customization file 'tbFile'.' :+ OPTIONS_ERROR_DELIMITER;
      } path = justFilename;
   }

   return error;
}

_str _toolbar_customizations_import_settings(_str &file)
{
   error := '';

   // we should have a file here with some customization in it
   ToolbarCustomizationHandler tch;
   tch.importChanges(file);

   return error;
}

_str _user_recorded_macros_export_settings(_str &path)
{
   error := '';

   files := '';

   // find the vusermacs
   userMacs := _macro_path(USERMACS_FILE :+ _macro_ext) :+ USERMACS_FILE :+ _macro_ext;
   if (file_exists(userMacs)) {
      // copy the file over
      if (copy_file(userMacs, path :+ USERMACS_FILE :+ _macro_ext)) {
         error = 'Error copying user macro file 'userMacs'.' :+ OPTIONS_ERROR_DELIMITER;
      } else files :+= USERMACS_FILE :+ _macro_ext',';
   }

   macFilePattern := _ConfigPath() :+ 'lastmac';
   
   // get each file that exists here
   filePath := file_match("-du "maybe_quote_filename(macFilePattern), 1);
   while (filePath != "") {

      // Strip the source directory part.
      fileName := _strip_filename(filePath, 'P');

      // make sure this matches the pattern
      if (pos('lastmac?*.e$', fileName, 1, 'R') == 1) {

         // copy the file over
         if (copy_file(filePath, path :+ fileName)) {
            error :+= 'Error copying user macro file 'filePath'.' :+ OPTIONS_ERROR_DELIMITER;
         } else files :+= fileName',';
      }

      filePath = file_match("-du "maybe_quote_filename(macFilePattern), 0);
   }

   // remove the last comma on the list of files
   if (files != '') {
      files = substr(files, 1, length(files) - 1);
      path = files;
   }

   return error;
}

_str _user_recorded_macros_import_settings(typeless &path)
{
   error := '';

   configDir := _ConfigPath();

   // is this an array of files or just a single file?
   if (path._typename() == '_str') {
      error = importUserMacroFile(configDir, path);
   } else {
      _str macFile;
      foreach (macFile in path) {
         error :+= importUserMacroFile(configDir, macFile);
      }
   }

   return error;
}

static _str importUserMacroFile(_str configDir, _str path)
{
   error := '';

   filename := _strip_filename(path,  'P');

   if (file_eq(USERMACS_FILE :+ _macro_ext, filename)) {
      userMacs := _macro_path(USERMACS_FILE :+ _macro_ext) :+ USERMACS_FILE :+ _macro_ext;
      if (file_exists(userMacs)) {
         // we want to append the file contents here...
         if (append_file_contents(path, userMacs, '// These macros imported on '_date()'.', '// End imported macros.')) {
            error = 'Error adding macros from 'filename' to 'USERMACS_FILE :+ _macro_ext'.' :+ OPTIONS_ERROR_DELIMITER;
         } else if (makeNload(userMacs, true, true)) {
            error = 'Error loading user macro file 'userMacs'.' :+ OPTIONS_ERROR_DELIMITER;
         }
         
         return error;
      } 
   } 

   if (!copy_file(path, configDir :+ filename)) {
      // load this bad boy up
      if (makeNload(configDir :+ filename, true, true)) {
         error = 'Error loading user macro file 'configDir :+ filename'.' :+ OPTIONS_ERROR_DELIMITER;
      }
   } else error = 'Error copying user macro file 'filename'.' :+ OPTIONS_ERROR_DELIMITER;

   return error;
}

// man, this is goofy
#define FILESEP_STANDIN       '=+-+='

_str _code_templates_export_settings(_str &path)
{
   error := '';
   files := '';

   // first do the templates options file
   filePath := _ctOptionsGetOptionsFilename();
   if (file_exists(filePath)) {
      fileName := _strip_filename(filePath, 'P');
   
      // copy the file over
      if (copy_file(filePath, path :+ fileName)) {
         error :+= 'Error copying code template options file 'filePath'.' :+ OPTIONS_ERROR_DELIMITER;
      } else files :+= fileName',';
   }

   // now figure out where the templates are
   templatesDir := _ctGetUserItemTemplatesDir();
   _maybe_append_filesep(templatesDir);

   // grab all the files underneath the template dir
   filePath = file_match("+t "maybe_quote_filename(templatesDir), 1);
   while (filePath != "") {
      // Skip the directory entries.
      if (last_char(filePath) != FILESEP) {

         // get the path relative to the templates dir
         newName := relative(filePath, templatesDir);

         // change the fileseps to something else - we do this because 
         // we cannot copy the whole directory structure to the export 
         // file.  So we preserve the directory structure in the filename
         newName = stranslate(newName, FILESEP_STANDIN, FILESEP);

         // copy the file
         status := copy_file(filePath, path :+ newName);
         if (status) {
            error :+= 'Error copying code template file 'filePath' ('status').' :+ OPTIONS_ERROR_DELIMITER;
         } else files :+= newName',';
      } 

      filePath = file_match("+t "maybe_quote_filename(templatesDir), 0);
   }

   // remove the last comma on the list of files
   if (files != '') {
      files = substr(files, 1, length(files) - 1);
      path = files;
   }

   return error;
}

_str _code_templates_import_settings(typeless &path)
{
   error := '';

   templatesDir := _ctGetUserItemTemplatesDir();
   _maybe_append_filesep(templatesDir);

   // is this an array of files or just a single file?
   if (path._typename() == '_str') {
      error = importCodeTemplateFile(templatesDir, path);
   } else {
      foreach (auto templateFile in path) {
         error :+= importCodeTemplateFile(templatesDir, templateFile);
      }
   }

   return error;
}

static _str importCodeTemplateFile(_str templatesDir, _str path)
{
   error := '';

   filename := _strip_filename(path, 'P');

   // is this the options file?
   if (file_eq(filename, CTOPTIONS_FILENAME)) {
      // we want to merge the options here
      if (_ctOptions_ImportOptions(path)) {
         error = 'Error adding options to existing code template parameters.' :+ OPTIONS_ERROR_DELIMITER;
      }
   } else {
  
      // get it down to just the filename
      newPath := _strip_filename(path, 'P');

      // this filename is actually the whole path we need to create 
      // under our templates dir
      newPath = stranslate(newPath, FILESEP, FILESEP_STANDIN);

      // make sure the path exists
      make_path(_strip_filename(templatesDir :+ newPath, 'N'));

      // just a template file, so copy it
      status := copy_file(path, templatesDir :+ newPath);
      if (status) {
         error = 'Error copying code template file 'filename' ('status').' :+ OPTIONS_ERROR_DELIMITER;
      }
   }

   return error;
}

_str _formatting_schemes_export_settings(_str &path)
{
   error := '';

   files := '';
   schemeDir := getUserXWSchemesDir() :+ FILESEP;
   
   // get each file that exists here
   filePath := file_match("-du "maybe_quote_filename(schemeDir), 1);
   while (filePath != "") {

      // Strip the source directory part.
      fileName := _strip_filename(filePath, 'P');

      // make sure this matches the pattern
      if (pos('?#.xml$', fileName, 1, 'R') == 1) {

         // copy the file over
         status := copy_file(filePath, path :+ fileName);
         if (status) {
            error :+= 'Error copying formatting scheme file 'filePath'(error code = 'status').' :+ OPTIONS_ERROR_DELIMITER;
         } else files :+= fileName',';
      }

      filePath = file_match("-du "maybe_quote_filename(schemeDir), 0);
   }

   // remove the last comma on the list of files
   if (files != '') {
      files = substr(files, 1, length(files) - 1);
      path = files;
   }


   return error;
}

_str _formatting_schemes_import_settings(typeless &path)
{
   error := '';

   schemeDir := getUserXWSchemesDir() :+ FILESEP;
   // is this an array of files or just a single file?
   if (path._typename() == '_str') {
      error = importFormattingSchemeFile(schemeDir, path);
   } else {
      _str formattingFile;
      foreach (formattingFile in path) {
         error :+= importFormattingSchemeFile(schemeDir, formattingFile);
      }
   }

   return error;
}

static _str importFormattingSchemeFile(_str schemeDir, _str formattingFile)
{
   error := '';

   filename := _strip_filename(formattingFile, 'P');
   schemeName := _strip_filename(filename, 'E');

   if (!XW_readXWSchemeFromFile(schemeName, formattingFile)) {
      error = 'Error reading formatting scheme from file 'filename'.' :+ OPTIONS_ERROR_DELIMITER;
   }
   else if (!XW_saveXWScheme(XW_schemes:[schemeName])) {
      error = 'Error savingn new formatting scheme 'schemeName'.' :+ OPTIONS_ERROR_DELIMITER;
   }

   return error;
}

_str _user_created_forms_export_settings(typeless &path)
{
   filenameOnly := 'userForms.e';
   error := '';

   if (writeUserObjectsExportFile(path :+ filenameOnly, OI_FORM, error)) {
      path = filenameOnly;
   }

   return error;
}

_str _user_created_forms_import_settings(typeless &path)
{
   return importUserObjectsFile(path);
}

_str _user_created_menus_export_settings(typeless &path)
{
   filenameOnly := 'userMenus.e';
   error := '';

   if (writeUserObjectsExportFile(path :+ filenameOnly, OI_MENU, error)) {
      path = filenameOnly;
   }

   return error;
}

_str _user_created_menus_import_settings(typeless &path)
{
   return importUserObjectsFile(path);
}

static boolean writeUserObjectsExportFile(_str filename, int objectType, _str &error)
{
   error = '';

   // open up a temp view for this
   found := false;
   tempView := 0;
   origView := _create_temp_view(tempView);
   if (origView <= 0) {
      error = 'Unable to open temp view.';
   } else {
      // insert this at the top so it will run properly
      insert_line('#include "slick.sh"');
      insert_line('');

      // stick this at the bottom - we're making a batch macro, you know
      insert_line('defmain()');
      insert_line('{');
      insert_line('_config_modify_flags(CFGMODIFY_RESOURCE);');
      insert_line('}');
      insert_line('');

      index := name_match('', 1, OBJECT_TYPE);

      for (;;) {
         if (!index) break;

         if (index.p_object == objectType) {
   
            /* Don't list source code for forms marked as system forms. */
            typeless flags = name_info(index);
            if (!isinteger(flags)) flags = 0;
   
            if ((flags & FF_SYSTEM) == 0) {
               name := name_name(index);
               name = translate(name, '_', '-');
               _insert_form(index, 0, 3, name);
   
               found = true;
            }
         }
         index = name_match('', 0, OBJECT_TYPE);
      }

      // did we write anything?  save it!
      if (found) {
         if (_save_file(maybe_quote_filename(filename)) < 0) error = 'Error saving objects file.';
      } 
      
      p_window_id = origView;
      _delete_temp_view(tempView, true);
   }

   return (found && error == '');
}

_str importUserObjectsFile(_str file)
{
   error := '';
   configFile := _ConfigPath() :+ _strip_filename(file, 'P');
   
   do {
      // this file is still embedded in the zip, so let's copy it somewhere 
      // we can run it
      if (copy_file(file, configFile)) {
         error = 'Error copying user toolbar file 'file'.';
         break;
      }

      // we have a file, so lets run it as a batch macro
      status := shell(maybe_quote_filename(configFile), 'Q');
      if (status) {
         error = 'Could not run batch file 'configFile'.  Error code = 'status'.';
         break;
      } 

      // delete the file, just for neatness
      delete_file(configFile);
      delete_file(configFile'x');

   } while (false);

   return error;
}

#endregion Export/Import functions for nodes without dialogs

/**
 * Some of the Select properties have choices that need to be generated at 
 * runtime.  The functions to do this must take a string array that they will 
 * then fill. 
 *  
 * Each string should be 'DisplayValue,ActualValue'.  If one of the values is a 
 * default choice for the Select, then ',default' should be added to the end of 
 * the string. 
 */
#region Fill Combo Box Methods

/**
 * Returns a list of possible encoding values.
 *  
 * @return STRARRAY        encoding values
 */
void _flo_get_encoding_list(_str (&list)[])
{
   // Get the encoding list.
   OPENENCODINGTAB openEncodingTab[];
   _EncodingListInit(openEncodingTab);

   skipFlag := OEFLAG_REMOVE_FROM_OPEN;

   int i;
   openEncodingTab[0].text = 'Default';

   // set the default to equal a single space, so as not to be confused with a blank
   list[0] = 'Default'OPTIONS_CHOICE_DELIMITER' ';

   for (i = 1; i < openEncodingTab._length(); ++i) {
      if (!(skipFlag & openEncodingTab[i].OEFlags)) {
         text := openEncodingTab[i].text:+OPTIONS_CHOICE_DELIMITER;
         if (openEncodingTab[i].option) {
            text :+= strip(openEncodingTab[i].option);
         } else if (openEncodingTab[i].codePage >= 0) {
            text :+= '+fcp'openEncodingTab[i].codePage;
         } 
         list[list._length()] = text;
      }
   }
}

/**
 * Returns a list of possible Visual C++ versions.
 *  
 * @return STRARRAY        Visual C++ versions
 */
void _vcppsetup_get_version_list(_str (&list)[])
{
   list[0] = 'Use Latest Version,0';
   int origID, tempID;
   origID = _create_temp_view(tempID);
   VCPPListAvailableVersions();

   // now go through and grab each line
   top();
   up();
   _str line;
   while (!down()) {
      get_line(line);
      line = strip(line);

      value := -1;
      if (pos(' 4.x ',' 'line' ')) {
         value = 4;
      }else if (pos(' 5.x ',' 'line' ')) {
         value = 5;
      }else if (pos(' 6.x ',' 'line' ')) {
         value = 6;
      }else if (pos(' 7.x?',' 'line' ',1,'r')) {
         value = 7;
      }else if (pos(' 8.x?',' 'line' ',1,'r')) {
         value = 8;
      }

      if (value > 0) {
         list[list._length()] = line :+ OPTIONS_CHOICE_DELIMITER :+ OPTIONS_CHOICE_DELIMITER :+ value;
      }
   }

   list._sort();

   p_window_id = origID;
}

/**
 * Retrieves a list of available formats for a value type for 
 * the Debugger Options > Numbers node.  
 *  
 * @return           array of possible values
 */
void _debug_options_get_numbers_list(_str (&list)[])
{
   int base_list[];
   dbg_get_supported_format_list(base_list);

   // alright, this is cheap
   // if we don't have a project open, then there is no debugger to ask about this, so 
   // we just use this
   if (base_list._length() == 0) {
      list[0] = "Char" :+ OPTIONS_CHOICE_DELIMITER :+ 256;
      list[1] = "Decimal" :+ OPTIONS_CHOICE_DELIMITER :+ 10;
      list[2] = "Hexadecimal" :+ OPTIONS_CHOICE_DELIMITER :+ 16;
      list[3] = "Default" :+ OPTIONS_CHOICE_DELIMITER :+ 0;
      list[4] = "Octal" :+ OPTIONS_CHOICE_DELIMITER :+ 8;
      list[5] = "Binary" :+ OPTIONS_CHOICE_DELIMITER :+ 2;
   }

   int i;
   for (i = 0; i < base_list._length(); ++i) {
      // This is the base format for each type, so there is no "natural"
      if (base_list[i]!=VSDEBUG_BASE_DEFAULT) {
         // this list is in display value, internal value
         list[list._length()] = dbg_get_format_name(base_list[i]) :+ OPTIONS_CHOICE_DELIMITER :+ base_list[i];
      }
   }
}

/**
 * Retrieves a list of MSDN help collections available on this machine.  Used 
 * for Help Options > General > MSDN help collection. 
 * 
 * @param list          list of collections
 */
void _help_options_get_MSDN_collection_list(_str (&list)[])
{
   numColls := msdn_num_collections();

   if (numColls == 0) {
      list[0] = 'None installed' :+ OPTIONS_CHOICE_DELIMITER :+ '' :+ OPTIONS_CHOICE_DELIMITER :+ 'default';
   } else {
      haveDefault := false;
      for(i := 0; i < numColls; ++i)
      {
         _str collection = "";
         _str url = "";
         if(msdn_collection_info(i, collection, url) == 0)
         {
            text := collection :+ OPTIONS_CHOICE_DELIMITER :+ url;
            // look for a "ms.vscc.*" collection, which will be a Visual Studio combined help
            // collection (and our default)
            if(!haveDefault && pos("ms\\.vscc", url, 1, "IR") > 0) {
               text :+= OPTIONS_CHOICE_DELIMITER :+ 'default';
               haveDefault = true;
            }
            list[list._length()] = text;
         }
      }
   }
}

/**
 * Retrieves the list of menus for use in the Language > General > Context menus 
 * options. 
 * 
 * @param list             list of menus
 */
void _lang_menu_get_menus(_str (&list)[])
{
   index := name_match('', 1, oi2type(OI_MENU));
   while (index) {
      menu_name := name_name(index);
      menu_name = stranslate(menu_name, '_', '-');
      list[list._length()] = menu_name;
      
      index = name_match('', 0, oi2type(OI_MENU));
   }
}

/**
 * Retrieves the list of XML Wrap Formatting schemes for use in XML/HTML 
 * Formatting Options > Auto formatting options. 
 * 
 * @param list             list of formatting schemes
 */
void _lang_xml_wrap_get_formatting_schemes(_str (&list)[])
{
   list[0]='None' :+ OPTIONS_CHOICE_DELIMITER :+ OPTIONS_CHOICE_DELIMITER :+ 'default';
   _str list2[];
   XW_schemeNamesM(list2);
   foreach (auto scheme in list2) {
      list[list._length()] = scheme :+ OPTIONS_CHOICE_DELIMITER :+ scheme;
   }
}

#endregion Fill Combo Box Methods

#region Property Dependency Functions
/**
 * These functions determine if individual properties should be enabled at any 
 * given time. 
 */

/**
 * The functions determines whether Auto list members related options are 
 * currently enabled for the given language.  These options are found on 
 * Language > Context Tagging. 
 * 
 * @param langID           language to check 
 * 
 * @return                 true if these options are available, false otherwise
 */
boolean _lang_list_members_enabled(_str langID)
{
   return (_FindLanguageCallbackIndex("_%s_get_expression_info", langID) != 0 ||
           _FindLanguageCallbackIndex("vs%s_get_expression_info", langID) != 0 ||
           _FindLanguageCallbackIndex("_%s_get_idexp", langID) != 0);
}

/**
 * The functions determines whether autocomplete related options are 
 * currently enabled for the given language.  These options are found on 
 * Language > Context Tagging. 
 * 
 * @param langID           language to check 
 * 
 * @return                 true if these options are available, false otherwise
 */
boolean _lang_auto_complete_tagging_enabled(_str langID)
{
   return (_FindLanguageCallbackIndex("vs%s_list_tags", langID) != 0 ||
           _FindLanguageCallbackIndex("%s_proc_search", langID) != 0 ||
           _FindLanguageCallbackIndex("_%s_find_context_tags", langID) != 0 ||
           _lang_list_members_enabled(langID));
}
 
/**
 * The functions determines whether Doc comment related options are 
 * currently enabled for the given language.  These options are found on 
 * Language > Comments. 
 * 
 * @param langID           language to check 
 * 
 * @return                 true if these options are available, false otherwise
 */
boolean _lang_doc_comments_enabled(_str langID)
{
   return (_LanguageInheritsFrom('c', langID) ||
       _LanguageInheritsFrom('java', langID) ||
       _LanguageInheritsFrom('js', langID) ||
       _LanguageInheritsFrom('cfscript', langID) ||
       _LanguageInheritsFrom('e', langID) ||
       _LanguageInheritsFrom('rul', langID) ||
       _LanguageInheritsFrom('phpscript', langID) ||
       _LanguageInheritsFrom('idl', langID) ||
       _LanguageInheritsFrom('antlr', langID) ||
       _LanguageInheritsFrom('tagdoc', langID) ||
       _LanguageInheritsFrom('m', langID) ||
       _LanguageInheritsFrom('applescript', langID) ||
       _LanguageInheritsFrom('cs', langID) ||
       _LanguageInheritsFrom('as', langID) ||
       _LanguageInheritsFrom('vera', langID) ||
       _LanguageInheritsFrom('verilog', langID) ||
       _LanguageInheritsFrom('systemverilog', langID)); 
}
 
/**
 * The functions determines whether line comment related options are 
 * currently enabled for the given language.  These options are found on 
 * Language > Comments. 
 * 
 * @param langID           language to check 
 * 
 * @return                 true if these options are available, false otherwise
 */
boolean _lang_line_comments_enabled(_str langID)
{
   // does this language have line comments?
   lexer_name := LanguageSettings.getLexerName(langID);
   if (lexer_name=='') lexer_name = _LangId2Modename(langID);
   
   if (lexer_name != '') {
      _str commentChars[];
      _getLineCommentChars(commentChars, lexer_name);
      return (commentChars._length() > 0);
   }
   
   return false;
}
 
/**
 * The functions determines whether smartpaste related options are 
 * currently enabled for the given language.  These options are found on 
 * Language > Indent. 
 * 
 * @param langID           language to check 
 * 
 * @return                 true if these options are available, false otherwise
 */
boolean _lang_smartpaste_enabled(_str langID)
{
   do {
      smartpasteIndex := _FindLanguageCallbackIndex('%s_smartpaste', langID);
      if (!smartpasteIndex) break;
      
      syntaxIndent := LanguageSettings.getSyntaxIndent(langID);
      if (syntaxIndent == '' || syntaxIndent <= 0) break;
      
      smartIndent := LanguageSettings.getIndentStyle(langID);
      if (smartIndent != INDENT_SMART) break;
      
      return true;
   } while (false);

   return false;

}
 
/**
 * The functions determines whether smart tab related options are 
 * currently enabled for the given language.  These options are found on 
 * Language > Indent. 
 * 
 * @param langID           language to check 
 * 
 * @return                 true if these options are available, false otherwise
 */
boolean _lang_smart_tab_enabled(_str langID)
{
   do {
      
      smartpasteIndex := 0;
      _get_smarttab(langID, smartpasteIndex);
      if (!smartpasteIndex) break;
      
      keyTable := LanguageSettings.getKeyTableName(langID);
      if (keyTable == '') break;
      
      index := find_index(keyTable, EVENTTAB_TYPE);
      command := name_name(eventtab_index(index, index, event2index(TAB)));
      
      if (!(command == 'smarttab' || command == 'c-tab' || command == 'gnu-ctab' ||
          _is_smarttab_supported(langID))) {
         break;
      }
      
      return true;
      
   } while (false);
   
   return false;
}
 
/**
 * The functions determines whether Auto Syntax Help is currently enabled for 
 * the given language.  This options are found on Language > Language Formatting
 * Options of some languages. 
 * 
 * @param langID           language to check 
 * 
 * @return                 true if these options are available, false otherwise
 */
boolean _lang_auto_syntax_help_enabled(_str langID)
{
   license := _default_option(VSOPTION_PACKFLAGS1);
   
   return (license & VSPACKFLAG1_COB) || (license & VSPACKFLAG1_ASM);
}
 
#endregion Property Dependency Functions

/**
 * This is not ideal, but we needed an easy way to set and get 
 * options that used old, cumbersome ways of being sought and 
 * got.  For all these methods, the same method is used to get 
 * and set the value.  To retrieve the value, call the method 
 * with no parameters. 
 */
#region Get/Set Methods

#if __PCDOS__
boolean _help_options_use_msdn_help(boolean value = null)
{
   if (value == null) {
      value = (def_msdn_coll != '');
   } else {
      if (value) {

         // set a default value
         _str list[];
         numColls := msdn_num_collections();
         for(i := 0; i < numColls; ++i)
         {
            _str collection = "";
            _str url = "";
            if(msdn_collection_info(i, collection, url) == 0)
            {
               if(pos("ms\\.vscc", url, 1, "IR") > 0) {
                  def_msdn_coll = url;
                  break;
               }
            }
         }
      } else def_msdn_coll = '';
   }

   return value;
}
#endif 

/**
 * ISPF Options - Home Key Property 
 * <br> Gets/sets the behavior of the home key in the ispf 
 * emulation. 
 *  
 * @param _str value       new value (leave out to retrieve the 
 *                         value)
 * 
 * @return _str            value of ispf home key
 */
_str _ispfo_home_key(_str value = null)
{
   index := eventtab_index(_default_keys, _default_keys,event2index(HOME));
   if (value == null) {
      value = (int)(name_name(index)=='ispf-home');
   } else if (value != (int)(name_name(index)=='ispf-home')) {
      if (value) {
         set_eventtab_index(_default_keys, event2index(HOME), find_index('ispf-home', COMMAND_TYPE));
         _macro_append("set_eventtab_index(_default_keys,event2index(HOME),find_index('ispf-home',COMMAND_TYPE));");
      } else {
         set_eventtab_index(_default_keys, event2index(HOME), find_index('begin-line-text-toggle', COMMAND_TYPE));
         _macro_append("set_eventtab_index(_default_keys,event2index(HOME),find_index('begin-line-text-toggle',COMMAND_TYPE));");
      }
      _config_modify_flags(CFGMODIFY_KEYS);
   }

   return value;
}

/**
 * ISPF Options - Prefix Area Width 
 * <br> Gets/sets the prefix area width in the ispf emulation. 
 *  
 * @param _str value       new value (leave blank to retrieve 
 *                         the value)
 * 
 * @return _str            current value
 */
_str _ispfo_prefix_area_width(_str value = null)
{
   if (value == null) {
      value = _default_option(VSOPTION_LINE_NUMBERS_LEN);
   } else if (_default_option(VSOPTION_LINE_NUMBERS_LEN) != value) {
      _default_option(VSOPTION_LINE_NUMBERS_LEN, value);
      _macro_append('_default_option(VSOPTION_LINE_NUMBERS_LEN,'value');');
      _LCUpdateOptions();
   }

   return value;
}

/**
 * ISPF Options - Display Prefix Area For Readonly Files 
 * <br> Gets/sets whether to display the prefix area for 
 * readonly files in the ispf emulation. 
 *  
 * @param _str value       new value (leave blank to retrieve 
 *                         the value)
 * 
 * @return _str            current value
 */
_str _ispfo_display_prefix_area_for_ro_files(_str value = null)
{
   if (value == null) {
      value = _default_option(VSOPTION_LCREADONLY);
   } else if (_default_option(VSOPTION_LCREADONLY) != value) {
      _default_option(VSOPTION_LCREADONLY, value);
      _macro_append('_default_option(VSOPTION_LCREADONLY,'value');');
      _LCUpdateOptions();
   }

   return value;
}

/**
 * Visual C++ Options - Visual C++ Loses Focus 
 * <br> Specifies which files are saved when Visual C++ loses 
 * focus.  Value may be one of the following:
 * <UL>
 * <LI><B>C</B> - Save current file in Visual C++.
 * <LI><B>A</B> - Save all files in Visual C++.
 * <LI><B>N</B> - Save no files in Visual C++ (default).
 * </UL>
 *  
 * @param _str value       new value (leave out to retrieve the 
 *                         value)
 * 
 * @return _str            current value
 */
_str _vcppsetup_vcpp_loses_focus(_str value = null)
{
   _str t1, t2;

   if (value == null) {
      parse def_vcpp_save with t1 t2;

      // sometimes the value is blank, so we give them the default
      if (t1 == '') {
         t1 = 'N';
      }

      value = t1;
   } else {
      parse def_vcpp_save with t1 t2;
      def_vcpp_save = value' 't2;
   }

   return value;
}

/**
 * Visual C++ Options - Suppress Visual C++ Reload Prompt 
 * <br> When set to true, the Visual C++ reload prompt is not 
 *  
 * @param boolean value    new value (leave out to retrieve 
 *                         the value)
 * 
 * @return boolean         current value
 */
boolean vcppsetup_suppress_reload_prompt(boolean value = null)
{
   _str t1, t2;

   if (value == null) {
      parse def_vcpp_save with t1 t2;

      // if the value is blank, we give them the default (false)
      t2 = upcase(t2);
      value = (t2 == 'Y');

   } else {
      parse def_vcpp_save with t1 t2;

      if (value) t2 = 'Y';
      else t2 = 'N';

      def_vcpp_save = t1' 't2;
   }

   return value;
}

_str _vc_setup_executable(_str provID, _str value = null) 
{
   if (value == null) {
      switch (provID) {
      case 'CVS':
         if (def_cvs_info.cvs_exe_name == null || def_cvs_info.cvs_exe_name == '' || !file_exists(def_cvs_info.cvs_exe_name)) {
            // Can't find cvs executable.
            def_cvs_info.cvs_exe_name = path_search(CVS_EXE_NAME);
         }
         value = def_cvs_info.cvs_exe_name;
         break;
      case 'Perforce':
         if (def_perforce_info.p4_exe_name == null || def_perforce_info.p4_exe_name == '' || !file_exists(def_perforce_info.p4_exe_name)) {
            // Can't find svn executable.
            def_perforce_info.p4_exe_name = path_search(P4_EXE_NAME);
         }
         value = def_perforce_info.p4_exe_name;break;
      case 'Subversion':
         if (def_svn_info.svn_exe_name == null || def_svn_info.svn_exe_name == '' || !file_exists(def_svn_info.svn_exe_name)) {
            // Can't find svn executable.
            def_svn_info.svn_exe_name = path_search(SVN_EXE_NAME);
         }
         value = def_svn_info.svn_exe_name;
         break;
      case 'Git':
         if (def_git_info.git_exe_name == null || def_git_info.git_exe_name == '' || !file_exists(def_git_info.git_exe_name)) {
            // Can't find git executable.
            def_git_info.git_exe_name = path_search(GIT_EXE_NAME);
         }
         value = def_git_info.git_exe_name;
         break; 
      case 'Mercurial':
         if (def_hg_info.hg_exe_name == '' || !file_exists(def_hg_info.hg_exe_name)) {
            // Can't find git executable.
            def_hg_info.hg_exe_name = path_search(HG_EXE_NAME);
         }
         value = def_hg_info.hg_exe_name;
         break; 
      } 
   } else {
      value = strip(value, 'B', '"');
      if (value != '' && file_exists(value)) {
         switch (provID) {
         case 'CVS':
            def_cvs_info.cvs_exe_name = value;
            break;
         case 'Perforce':
            def_perforce_info.p4_exe_name = value;
            break;
         case 'Subversion':
            def_svn_info.svn_exe_name = value;
            break;
         case 'Git':
            def_git_info.git_exe_name = value;
            break;
         case 'Mercurial':
            def_hg_info.hg_exe_name = value;
            break;
         } 
      }
   }
   return value;
}

/**
 * Help Options - Word Help Filename 
 * <br> Specifies the Word Help files (.idx or .mvb) used by the
 * wh, wh2, and wh3 commands. 
 *  
 * @param _str value       new value (leave out to retrieve the 
 *                         value)
 * 
 * @return _str            current value
 */
_str _word_help_filenames(_str value = null)
{
   if (value == null) {
      value = def_wh;
   } else {
      curVal := _word_help_filenames();
      if (curVal != value) {
         _macro_append("def_wh="_quote(value)';');
      }
      def_wh = value;
   }

   return value;
}

/**
 * Options - Key Message Delay 
 * <br> Maximum delay, in tenths of a second, between two key 
 * combinations when used as a single key binding. 
 *  
 * @param _str value       new value (leave out to retrieve the 
 *                         value)
 * 
 * @return _str            current value
 */
_str _keymsg_delay(_str value = null) 
{
   if (value == null) {
      value = get_event('D');
   } else {
      get_event('D'value);
   }

   return value;
}

/**
 * Redefine Common Key Options - Backspace 
 * <br> Defines the behavior of the backspace key.  Possible 
 * values: 
 * <UL> 
 * <LI><B>'rubout'</B> - Cursor stops at column 1
 * <LI><B>'linewrap-rubout'</B> - Cursor wraps to previous line 
 * (Default) 
 * </UL> 
 *  
 * @param _str value       new value (leave out to retrieve the 
 *                         value)
 * 
 * @return _str            current value
 */
_str _rdck_backspace(_str command = null)
{
   return _rdck_key_command(BACKSPACE, command);
}

/**
 * Redefine Common Key Options - Delete 
 * <br> Defines the behavior of the delete key.  Possible 
 * values: 
 * <UL> 
 * <LI><B>'delete-char'</B> - Next line only joins when word 
 * wrap is on 
 * <LI><B>'linewrap-delete-char'</B> - Next line always joins (Default)
 * </UL> 
 *  
 * @param _str value       new value (leave out to retrieve the 
 *                         value)
 * 
 * @return _str            current value
 */
_str _rdck_delete(_str command = null)
{
   return _rdck_key_command(DEL, command);
}

/**
 * Redefine Common Key Options - End key 
 * <br> Defines the behavior of the end key.  Possible 
 * values: 
 * <UL> 
 * <LI><B>'end-line'</B> - Moves cursor to end of line 
 * (Default) 
 * <LI><B>'end-line-text-toggle'</B> - Toggles cursor between 
 * end of line and last non-whitespace character 
 * </UL> 
 *  
 * @param _str value       new value (leave out to retrieve the 
 *                         value)
 * 
 * @return _str            current value
 */
_str _rdck_end(_str command = null)
{
   return _rdck_key_command(END, command);
}

/**
 * Redefine Common Key Options - Enter key 
 * <br> Defines the behavior of the enter key.  Possible 
 * values: 
 * <UL> 
 * <LI><B>'nosplit-insert-line'</B> - Inserts blank line after 
 * current line without splitting current line 
 * <LI><B>'split-insert-line'</B> - Splits current line at 
 * cursor (Default) 
 * <LI><B>'maybe-split-insert-line'</B> - Splits current line 
 * only when Start in Insert Mode is on 
 * </UL> 
 *  
 * @param _str value       new value (leave out to retrieve the 
 *                         value)
 * 
 * @return _str            current value
 */
_str _rdck_enter(_str command = null)
{
   if (command == null) {
      command = _rdck_key_command(ENTER, command);
   } else {
      _rdck_key_command(ENTER, command);

      ctrl_enter_alt := '';
      ctrl_enter_key := name2event("C_ENTER");
      ctrl_enter_index := event2index(ctrl_enter_key);
      ctrl_enter_cmd := eventtab_index(_default_keys, _default_keys, ctrl_enter_index);

      if (ctrl_enter_cmd) {
         ctrl_enter_name := name_name(ctrl_enter_cmd);
         if (command == 'nosplit-insert-line') {
            // Enter is now on nosplit, so move Ctrl+Enter to split
            if (ctrl_enter_name == 'nosplit-insert-line' || ctrl_enter_name == 'nosplit-insert-line-above') {
               ctrl_enter_alt = 'split-insert-line';
            }
         } else {
            // Enter is now on split, so move Ctrl+Enter to nosplit
            if (ctrl_enter_name == 'split-insert-line') {
               if (def_keys == 'vsnet_keys') {
                  ctrl_enter_alt = 'nosplit-insert-line-above';
               } else {
                  ctrl_enter_alt = 'nosplit-insert-line';
               }
            }
         }
      }
      if (ctrl_enter_alt != '') {
         set_eventtab_index(_default_keys, ctrl_enter_index, find_index(ctrl_enter_alt, COMMAND_TYPE));
         _macro('m',_macro('s'));
         _macro_append("set_eventtab_index(_default_keys, "event2index(ctrl_enter_key)", find_index("_quote(ctrl_enter_alt)", COMMAND_TYPE));");
      }
   }

   return command;
}

/**
 * Redefine Common Key Options - Home key 
 * <br> Defines the behavior of the home key.  Possible values: 
 * <UL> 
 * <LI><B>'begin-line'</B> - Moves cursor to column one
 * <LI><B>'begin-line-text-toggle'</B> - Toggles cursor between 
 * first non-blank character and column one (Default) 
 * </UL> 
 *  
 * @param _str value       new value (leave out to retrieve the 
 *                         value)
 * 
 * @return _str            current value
 */
_str _rdck_home(_str command = null)
{
   return _rdck_key_command(HOME, command);
}

/**
 * Gets or sets the value for a Redefine Common Keys option. 
 * This function is not meant to be used directly.  To set a 
 * redefine common keys option, see the functions listed below 
 * according to each option. 
 * 
 * @param _str keyEvent          key being set.  Possible values
 * <UL> 
 * <LI><B>HOME</B> - see {@link _rdck_home()}
 * <LI><B>ENTER</B> - see {@link _rdck_enter()}
 * <LI><B>END</B> - see {@link _rdck_end()}
 * <LI><B>DEL</B> - see {@link _rdck_delete()}
 * <LI><B>BACKSPACE</B> - see {@link _rdck_backspace()}
 * </UL> 
 * @param _str command           new value (send null to 
 *                               retrieve current value)
 * 
 * @return _str                  current value
 */
_str _rdck_key_command(_str keyEvent, _str command = null)
{
   if (command == null) {
      index := eventtab_index(_default_keys, _default_keys, event2index(keyEvent));
      command = name_name(index);
   } else {
      command = lowcase(command);
      set_eventtab_index(_default_keys, event2index(keyEvent), find_index(command, COMMAND_TYPE));
      _config_modify_flags(CFGMODIFY_KEYS);
      _macro('m',_macro('s'));
      _macro_append("set_eventtab_index(_default_keys, "event2index(keyEvent)", find_index("_quote(command)", COMMAND_TYPE));");
   }

   return command;
}


#region Context Tagging Options

/**
 * Gets/sets the context tagging option of starting background 
 * tagging after so many minutes idle. 
 * 
 * @param int value           the new value to set - use null 
 *                            to get the current value
 * 
 * @return int                the current value
 */
int _cto_start_after_minutes_idle(int value = null)
{
   return _cto_bgtag_option(0, value);
} 

/**
 * Gets/sets the context tagging option of the maximum number of
 * files to tag during background tagging. 
 * 
 * @param int value           the new value to set - use null 
 *                            to get the current value
 * 
 * @return int                the current value
 */
int _cto_max_files_to_tag(int value = null)
{
   return _cto_bgtag_option(2, value);
}

/**
 * Gets/sets the context tagging option of the maximum number of
 * files to consider during background tagging. 
 * 
 * @param int value           the new value to set - use null 
 *                            to get the current value
 * 
 * @return int                the current value
 */
int _cto_max_files_to_consider(int value = null)
{
   return _cto_bgtag_option(1, value);
}

/**
 * Gets/sets the context tagging option of the amount of minutes
 * to wait after background tagging has completed to begin 
 * again. 
 * 
 * @param int value           the new value to set - use null 
 *                            to get the current value
 * 
 * @return int                the current value
 */
int _cto_timeout(int value = null)
{
   return _cto_bgtag_option(3, value);
}

/**
 * Gets/sets the context tagging option specified by the index. 
 *  These values are kept in a string that must be parsed, or
 * you can use this function to fetch/set them individually.
 *  
 * @param int index           the index of the value that you 
 *            wish to get/set.  Accepted values:
 * <pre> 
 *             0 - Start after seconds idle
 *             1 - max number of files to consider
 *             2 - max number of files to tag
 *             3 - background tagging timeout value.
 * </pre> 
 *            See def_bgtag_options for more info. 
 * @param int value           the new value to set - use null 
 *                            to get the current value
 * 
 * @return int                the current value
 */
int _cto_bgtag_option(int index, int value = null)
{
   _str a[];
   split(def_bgtag_options, ' ', a);
   // we simple return the value at the given index
   if (value == null) {
      if (a._length() > index) {
         value = (int)a[index];
      } else {
         // use the default - this is a bit hokey
         split('30 10 3 600', ' ', a);
         value = (int)a[index];
      }
   } else {
      // here we've got to save the new value
      a[index] = value;

      // and then build up our string again to be set
      options := '';
      foreach (auto opt in a) {
         options = options' 'opt;
      }

      def_bgtag_options = strip(options);
   }
   return value;
}

#endregion Context Tagging Options

#region File Load/Save/AutoSave/Backup Options

/**
 * Gets/sets file load option - Encoding.  Call with no parameters to retrieve 
 * current value. 
 * 
 * @param value 
 * 
 * @return _str 
 */
_str _flo_encoding(_str value = null)
{
   if (value == null) {
      value = def_encoding;
   } else {
      def_encoding = value;
   }

   return value;
}

/**
 * Gets/sets file load option - Load entire file.  Call with no 
 * parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _flo_load_entire_file(int value = null)
{
   return _file_load_option('L', value);
}

/**
 * Gets/sets file load option - Count number of lines.  Call 
 * with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _flo_count_number_of_lines(int value = null)
{
   return _file_load_option('LC', value);
}

/**
 * Gets/sets file load option - Truncate file at End of File. 
 * Call with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _flo_truncate_file_at_eof(int value = null)
{
   return _file_load_option('LZ', value);
}

/**
 * Gets/sets file load option - Use UNDO.  Call 
 * with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _flo_use_undo(int value = null)
{
   return _file_load_option('U', value);
}

/**
 * Gets/sets file load option - Max number of UNDO steps.  Call 
 * with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set 
 * 
 * @return int          current value
 */
int _flo_max_undo_steps(int value = null)
{
   return _file_load_option('U', value, true);
}

/**
 * Gets/sets file load option - Count number of lines.  Call 
 * with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _flo_fast_line_count(int value = null)
{
   return _file_load_option('LF', value);
}

/**
 * Gets/sets file load option - Show End of File character. 
 * Call with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _flo_show_eof_character(int value = null)
{
   return _file_load_option('LE', value);
}

/**
 * Gets/sets file load option - Expand tabs to spaces.  Call 
 * with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _flo_load_expand_tabs(int value = null)
{
   return _file_load_option('E', value);
}

/**
 * Gets/sets file load option - Enable file locking.  Call 
 * with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _flo_file_locking(int value = null)
{
   return _file_load_option('N', value);
}
 
/**
 * Gets/sets file load option - Reinsert new file after current
 * buffer. Call with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _flo_reinsert_after_current(int value = null)
{
   return _file_load_option('BP', value);
}


/**
 * Gets/sets file load option - Save/restore file position.  Call with no 
 * parameters to retrieve current value. 
 * 
 * @param value         new value to set (null to retrieve current)
 * 
 * @return boolean      current value
 */
boolean _flo_save_file_pos(boolean value = null)
{
   if (value == null) {
      // just return the value
      value = (def_max_filepos != 0);
   } else { 
      // we are setting the new value - make sure 
      // it's not the same as the old one
      if (value && def_max_filepos <= 0) {
         _flo_max_file_pos(200);
      } else if (!value && def_max_filepos > 0) {
         _flo_max_file_pos(0);
      }
   }

   return value;
}

/**
 * Gets/sets file load option - Max files.  Call with no parameters to retrieve 
 * the current value. 
 * 
 * @param value         new value to set (null to retrieve current)
 * 
 * @return int          current value 
 */
int _flo_max_file_pos(int value = null)
{
   if (value == null) {
      value = def_max_filepos;
   } else {
      def_max_filepos = value;
      _per_file_data_update_max_records(def_max_filepos);
   }

   return value;
}

/**
 * Gets/sets file load option - Append End of File character. 
 * Call with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _fso_append_eof(int value = null)
{
   return _file_save_option('Z', value);
}

/**
 * Gets/sets file load option - Remove End of File Character. 
 * Call with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _fso_remove_eof(int value = null)
{
   return _file_save_option('ZR', value);
}

/**
 * Gets/sets file save option - Expand tabs to spaces upon save.
 * Call with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _fso_expand_tabs(int value = null)
{
   return _file_save_option('E', value);
}

/**
 * Gets/sets file save option - Strip trailing spaces upon save.
 * Call with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _fso_strip_spaces(int value = null)
{
   if (value == null) {
      strValue := _file_save_select('S', value, '', true);
      switch (strValue) {
      case '-':
         value = STSO_OFF;
         break;
      case '+':
         value = STSO_STRIP_ALL;
         break;
      case 'M':
         value = STSO_STRIP_MODIFIED;
         break;
      }
   } else {
      strValue := '';
      switch (value) {
      case STSO_OFF:
         strValue = '-';
         break;
      case STSO_STRIP_ALL:
         strValue = '+';
         break;
      case STSO_STRIP_MODIFIED:
         strValue = 'M';
         break;
      }

      _file_save_select('S', strValue, '', true);
   }

   return value;
}

/**
 * Gets/sets file save option - Reset line modify flags upon
 * save. Call with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set (boolean as 0/1)
 * 
 * @return int          current value (boolean as 0/1)
 */
int _fso_reset_line_modify(int value = null)
{
   return _file_save_option('L', value);
}

/**
 * Gets/sets file save option - Save line format. Call with no 
 * parameters to retrieve current value. 
 * 
 * @param int value     new value to set, one of four string 
 *                      values:<pre>
 *                      A - Automatic
 *                      D - DOS
 *                      M - Mac
 *                      U - Unix</pre>
 * 
 * @return _str         current value (see above)
 */
_str _fso_line_format(_str value = null)
{
   return _file_save_select('F', value, 'A');
}

/**
 * Gets/sets file autosave option - Save after period of 
 * inactivity. This value is set in units of seconds.  Call with
 * no parameters to retrieve current value. 
 * 
 * @param int value     new value to set
 * 
 * @return _str         current value 
 */
int _faso_save_after_inactivity(int value = null)
{
   _str inactive, t1;
   parse def_as_timer_amounts with inactive t1;

   if (value == null) {
      if (inactive == '') {
         inactive = 's60';
      }

      // grab the number
      amount := (int)substr(inactive, 2);

      // check for minutes - we want seconds
      unit := substr(inactive, 1, 1);
      if (unit == 'm' || amount < 0) {
         // multiply the value by 60
         amount *= 60;
      }

      // check for smallest interval
      if (amount > 0 && amount < SMALLEST_INTERVAL) {
         amount = SMALLEST_INTERVAL;
      } 

      value = amount;
   } else {
      def_as_timer_amounts = 's'value' 't1;
   }

   return value;
}


/**
 * Gets/sets file autosave option - Save after period of 
 * time. This value is set in units of seconds.  Call with
 * no parameters to retrieve current value. 
 * 
 * @param int value     new value to set
 * 
 * @return _str         current value 
 */
int _faso_save_after_time(int value = null)
{
   _str time, t1, t2;
   parse def_as_timer_amounts with t1 time t2;

   if (value == null) {
      if (time == '') {
         time = 's60';
      }

      // grab the number
      amount := (int)substr(time, 2);

      // check for minutes - we want seconds
      unit := substr(time, 1, 1);
      if (unit == 'm' || amount < 0) {
         // multiply the value by 60
         amount *= 60;
      }

      if (amount > 0 && amount < SMALLEST_INTERVAL) {
         amount = SMALLEST_INTERVAL;
      }

      value = amount;
   } else {
      def_as_timer_amounts = t1' s'value' 't2;
   }

   return value;
}

/**
 * File Options > Backup > Limit backup size.  Gets/sets this 
 * option.  To get the current value, call with no parameters. 
 * 
 * @param value      value to set
 * 
 * @return           current value
 */
boolean _fbuo_limit_backup_size(boolean value = null)
{
   if (value == null) {
      value = (def_maxbackup != '' && isinteger(def_maxbackup) && (int)def_maxbackup);
   } else {
      if (value && def_maxbackup == '' || !isinteger(def_maxbackup) || (int)def_maxbackup == 0) {
         def_maxbackup = 5000*1024;       // set it to the default
      } else if (!value) {
         def_maxbackup = '';              // we're setting it to false
      }
   }
   return value;
}

/**
 * File Options > Backup > Maximum backup size.  Gets/sets this 
 * option.  To get the current value, call with no parameters. 
 * 
 * @param value      value to set
 * 
 * @return           current value
 */
int _fbuo_max_backup_size(int value = null)
{
   if (value == null) {
      if (def_maxbackup == '' || !isinteger(def_maxbackup)) {
         value = 0;
      } else value = (int)def_maxbackup;
   } else {
      if (value) {
         def_maxbackup = value;
      } else def_maxbackup = '';
   }

   return value;
}

/**
 * Gets/sets file backup option - Backup file options.
 * Call with no parameters to retrieve current value.
 * 
 * @param _str value    new value to set, one of five string 
 *                      values:<pre>
 *                      DB - Same directory as *.BAK
 *                      -D - Global nested directories
 *                      DK - Use child directory
 *                      +D - Global directory
 *                      DD - Create backup history on save (secret)
 *                      </pre>
 *  
 * @param boolean retDefaultIfInvalid  
 * 
 * @return _str         current value 
 */
_str _fbuo_backup_directory_location(_str value = null)
{ 
   ss := '[+|-]D(:c):0,1( |$)';
   col := pos(ss, def_save_options, 1, 'R');

   if (value == null) {
      // grab the whole section, starting with the +/-
      nextSpace := pos(' ', def_save_options, col);
      if (!nextSpace) nextSpace = -1;
      value = strip(substr(def_save_options, col, nextSpace - col));

      // if we have two letters, then we don't care about the +/-
      if (length(value) == 3) value = substr(value, 2);
   } else {
      newValue := value;
      if (pos('[+|-]', value, 1, 'R') != 1) {
         newValue = '+'value;
      }

      // did we find it?
      if (col) {
         // yup, we gotta build a new string, so get what's before and after the option
         _str before = '', after = '';
         before = substr(def_save_options, 1, col - 1);
   
         nextSpace := pos(' ', def_save_options, col);
         if (nextSpace) {
            after = substr(def_save_options, nextSpace);   // find the next space
         }
         def_save_options = before :+ newValue :+ after;
      } else {
         // if it's not in there, that means it's off - to turn it on, just add to the existing string
         def_save_options = def_save_options :+ newValue;
      }
   }

   return value;
}

/**
 * Gets/sets file backup option - Backup directory path. Call 
 * with no parameters to retrieve current value. 
 * 
 * @param int value     new value to set 
 * 
 * @return int          current value 
 */
_str _fbuo_backup_directory_path(_str value = null)
{
   if (value == null) {
      value = get_env("VSLICKBACKUP");
      value = _encode_vsenvvars(value, false, false);
   } else {
      value = strip(value, 'B', '"');
      value = _encode_vsenvvars(value, false, false);
      _ConfigEnvVar("VSLICKBACKUP", value);
      _macro_call("_ConfigEnvVar", "VSLICKBACKUP", value);
   }

   return value;
}

static enum MakeBackupFilesOption {
   MBFO_OFF = 0,
   MBFO_BACKUP_FILE = 1,
   MBFO_BACKUP_HISTORY = 2
}

/**
 * Gets/sets file backup option - Make backup files. Call with no parameters to 
 * retrieve current value. 
 *  
 * For SE 13.0.1, we changed the way this was viewed in the options, adding 
 * "Create backup history" as a possible value of this option. 
 *  
 * @param int value     new value to set 
 * 
 * @return int          current value 
 */
int _fbuo_make_backup_files(int value = null)
{
   if (value == null) {
      // get the actual value of this option
      value = _file_save_option('O', null, false, true);
      if (value) {
         // check to see if backup history is on - if it is, we 
         // change the return value to that.  Otherwise, the value remains at 1.
         if (_fbuo_backup_directory_location() == 'DD') value = MBFO_BACKUP_HISTORY;
      } // else we know it's just off
   } else {
      // first find out if backup history is turned on
      backupHistoryOn := _fbuo_backup_directory_location() == 'DD'; 

      switch (value) {
      case MBFO_OFF:
      case MBFO_BACKUP_FILE:
         // set the actual option to whatever our value is
         _file_save_option('O', value, false, true);

         // if backup history is on, we just turn it off (and set it to the default)
         if (backupHistoryOn) {
            _fbuo_backup_directory_location('+D');
         }
         break;
      case MBFO_BACKUP_HISTORY:
         // turn them both on
         _file_save_option('O', MBFO_BACKUP_FILE, false, true);
         _fbuo_backup_directory_location('DD');
         break;
      }
   }

   return value;
}

/**
 * Gets a file load or save option which has several different 
 * possible values, rather than just a +/- indicating on or off. 
 * 
 * @param boolean load        true to use def_load_options, 
 *                            false to use def_save_options
 * @param _str key            key of option to look for - see
 *                            def_load_options and def_save_options
 * @param _str defaultChoice  the default choice if an option
 *                            cannot be determined
 * @param boolean checkPlusMinus
 *                            if there is no choice after the
 *                            key, then we return the plus or
 *                            minus
 * 
 * @return _str               the current option
 */
_str _get_load_save_select(boolean load, _str key, _str defaultChoice, boolean checkPlusMinus = false)
{
   _str list, value;

   // are we using load or save options?
   if (load) {
      list = def_load_options;
   } else {
      list = def_save_options;
   }

   // figure out what we're searching for
   ss := '[+|-]'key'(:c):0,1( |$)';
   col := pos(ss, list, 1, 'R');

   // did we find it?
   if (col) {
      // then whip it out!
      suffix := substr(list, col + length(key) + 1, 1);
      if (suffix == ' ') {
         if (checkPlusMinus) {
            value = substr(list, col, 1);
         } else {
            value = defaultChoice;
         }
      } else {
         value = suffix;
      }
   } else {
      // use the default
      value = defaultChoice;
   }

   return value;
}

/**
 * Sets a file load or save option which has several different 
 * possible values, rather than just a +/- indicating on or off. 
 * 
 * @param boolean load        true to use def_load_options, 
 *                            false to use def_save_options
 * @param _str key            key of option to look for - see
 *                            def_load_options and def_save_options
 * @param _str value          the new value
 * @param _str defaultChoice  the default choice if an option
 *                            cannot be determined
 * 
 * @return _str               the current option
 */
_str _set_load_save_select(boolean load, _str key, _str value, _str defaultChoice)
{
   // make sure we're not going through all this trouble to set what's already there
   if (value != _get_load_save_select(load, key, defaultChoice)) {

      // are we using load options or save options?
      _str list;
      if (load) {
         list = def_load_options;
      } else {
         list = def_save_options;
      }

      // figure out what we're looking for
      ss := '[+|-]'key'(:c):0,1( |$)';
      col := pos(ss, list, 1, 'R');

      // did we find it?
      if (col) {
         // yup, we gotta build a new string, so get what's before and after the option
         _str before = '', mid = '', after = '';
         before = substr(list, 1, col - 1);

         nextSpace := pos(' ', list, col);
         if (nextSpace) {
            after = substr(list, nextSpace);   // find the next space
         }

         // for the default, we just remove the thing
         if (value != defaultChoice) {
            // maybe the plus or minus is the value
            if (value == '+' || value == '-') {
               mid = value :+ key;
            } else {
               // or maybe it's another letter
               mid = "+" :+ key :+ value;
            }
            list = before :+ mid :+ after;
         } else {
            list = strip(before)' 'strip(after);
         }
      } else {
         // if it's not in there, that means it's off - to turn it on, just add to the existing string
         // for default choice, we just leave it blank
         if (value != defaultChoice) {
            if (value == '+' || value == '-') {
               list = list :+ ' ' :+ value :+ key;
            } else {
               // or maybe it's another letter
               list = list :+ " +" :+ key :+ value;
            }
         }
      }

      if (load) {
         def_load_options = list;
      } else {
         def_save_options = list;
      }
   }
   return value;
}

/**
 * Handles all the get/set methods for file load options which 
 * have multiple possible values (as opposed to on/off). 
 * Determines if we are setting the value or asking for it and 
 * calls the appropriate methods. 
 * 
 * @param _str key               the "key" of our value - how we 
 *                               locate it within the def_load_options
 * @param _str value             the new value - will be null 
 *                               when we are only retrieving a value
 * @param _str defaultChoice     the default value
 * 
 * @return _str                  the current value
 */
_str _file_load_select(_str key, _str value = null, _str defaultChoice = '')
{
   // we want the value
   if (value == null) {
      value = _get_load_save_select(true, key, defaultChoice);
   } else {          // we want to change the value
      _set_load_save_select(true, key, value, defaultChoice);
   }

   return value;
}

/**
 * Handles all the get/set methods for file save options which 
 * have multiple possible values (as opposed to on/off). 
 * Determines if we are setting the value or asking for it and 
 * calls the appropriate methods. 
 * 
 * @param _str key               the "key" of our value - how we 
 *                               locate it within the def_load_options
 * @param _str value             the new value - will be null 
 *                               when we are only retrieving a value
 * @param _str defaultChoice     the default value
 * @param boolean checkPlusMinus
 *                            if there is no choice after the
 *                            key, then we return the plus or
 *                            minus
 * 
 * @return _str                  the current value
 */
_str _file_save_select(_str key, _str value = null, _str defaultChoice = '', boolean checkPlusMinus = false)
{
   // we want the value
   if (value == null) {
      value = _get_load_save_select(false, key, defaultChoice, checkPlusMinus);
   } else {             // we want to change the value
      _set_load_save_select(false, key, value, defaultChoice);
   }

   return value;
}

/** 
 * This method is used to get or set the current value for a 
 * file load option.  See definitions of def_load_options for 
 * more information. 
 * 
 * @param key                    the letter sequence to search 
 *                               for, for this option of
 *                               interest
 * @param value                  the new value to set - null 
 *                               when you just want to retrieve
 *                               the value
 * @param getNum                 whether to get the numeric 
 *                               value, as some options are
 *                               followed by a :##
 * @param backwards              whether this option is 
 *                               "backwards," meaning '+' -> off
 *                               and '-' -> on.
 * 
 * @return int                   the value retrieved, either a 
 *                               numeric or a boolean as an int (0/1)
 */
int _file_load_option(_str key, int value = null, boolean useNum = false, boolean backwards = false)
{
   // we want the value
   if (value == null) {
      value = _get_load_save_option(true, key, useNum, backwards);
   } else {             // we want to change the value
      _set_load_save_option(true, key, value, useNum, backwards);
   }

   return value;
}

/** 
 * This method is used to get or set the current value for a 
 * file save option.  See definitions def_save_options for more 
 * information. 
 * 
 * @param key                    the letter sequence to search 
 *                               for, for this option of
 *                               interest
 * @param value                  the new value to set - null 
 *                               when you just want to retrieve
 *                               the value
 * @param getNum                 whether to get the numeric 
 *                               value, as some options are
 *                               followed by a :##
 * @param backwards              whether this option is 
 *                               "backwards," meaning '+' -> off
 *                               and '-' -> on.
 * 
 * @return int                   the value retrieved, either a 
 *                               numeric or a boolean as an int (0/1)
 */
int _file_save_option(_str key, int value = null, boolean useNum = false, boolean backwards = false)
{
   // we want the value
   if (value == null) {
      value = _get_load_save_option(false, key, useNum, backwards);
   } else {             // we want to change the value
      _set_load_save_option(false, key, value, useNum, backwards);
   }

   return value;
}

/** 
 * Translates an int and a boolean into a plus or a minus sign. 
 * 
 * @param value            the integer value - usually, a 
 *                         non-zero value means a plus ('+'),
 *                         while a zero means a minus ('-')
 *
 * @param backwards        whether to switch the plus/minus
 *                         relationship
 * 
 * @return _str            either a plus or a minus
 */
_str getPlusMinus(int value, boolean backwards)
{
   _str op;
   // regular ole plus = nonzero, minus = 0;
   if (!backwards) {
      if (value) {
         op = '+';
      } else {
         op = '-';
      }
   } else {
      // backwards!  regular ole minus = nonzero, plus = 0;
      if (value) {
         op = '-';
      } else {
         op = '+';
      }
   }
   return op;
}

/** 
 * This method is used to save a new value for the file load and 
 * file save options.  See definitions of def_load_options and 
 * def_save_options for more information. 
 * 
 * @param load                   true to use load options, false 
 *                               to use save options
 * @param key                    the letter sequence to search 
 *                               for, for this option of
 *                               interest
 * @param value                  the value to be set, either a 
 *                               numeric value or a boolean as
 *                               an int (0/1)
 * @param getNum                 whether to save the numeric 
 *                               value, as some options are
 *                               followed by a :##
 * @param backwards              whether this option is 
 *                               "backwards," meaning '+' -> off
 *                               and '-' -> on.
 * 
 */
void _set_load_save_option(boolean load, _str key, int value, boolean setNum = false, boolean backwards = false)
{
   _str list;
   // are we using load options or save options?
   if (load) {
      list = def_load_options;
   } else {
      list = def_save_options;
   }
   list=strip(list);

   // figure out what we're looking for
   ss := '(\+|\-)'key'(\::d#):0,1( |$)';
   col := pos(ss, list, 1, 'R');
   // did we find it?
   if (col) {
      if (setNum) {        // we want what's after the colon
         col = pos(':', list, col);
         before := substr(list, 1, col);
         after := substr(list, pos('( |$)', list, col, 'R'));

         list = before :+ value :+ after;
      } else {
         // find + or - and return based on that
         before := substr(list, 1, col - 1);
         after := substr(list, col + length(key) + 1);            // add 1 for the +/- sign

         // we may have to switch up based on backwards param
         list = before :+ getPlusMinus(value, backwards) :+ key :+ after;
      }
   } else {
      // if it's not in there, that means it's off - to turn it on, just add to the existing string
      if (setNum) {
         list = list :+ ' ' :+ getPlusMinus(value, backwards) :+ key :+ ':' :+ value;
      } else {
         if (value) {
            list = list :+ ' ' :+ getPlusMinus(value, backwards) :+ key;
         } 
      }
   }

   // now set it
   if (load) {
      def_load_options = list;
   } else {
      def_save_options = list;
   }
}

/** 
 * This method is used to get the current value for the file
 * load and file save options.  See definitions of 
 * def_load_options and def_save_options for more information. 
 * 
 * @param load                   true to use load options, false 
 *                               to use save options
 * @param key                    the letter sequence to search 
 *                               for, for this option of
 *                               interest
 * @param getNum                 whether to get the numeric 
 *                               value, as some options are
 *                               followed by a :##
 * @param backwards              whether this option is 
 *                               "backwards," meaning '+' -> off
 *                               and '-' -> on.
 * 
 * @return int                   the value retrieved, either a 
 *                               numeric or a boolean as an int (0/1)
 */
int _get_load_save_option(boolean load, _str key, boolean getNum = false, boolean backwards = false)
{
   _str list;
   // are we using load or save?
   if (load) {
      list = def_load_options;
   } else {
      list = def_save_options;
   }

   // figure out what we're searching for
   ss := '(\+|\-)'key'(\::d#):0,1( |$)';
   col := pos(ss, list, 1, 'R');

   // did we find it?
   if (col) {
      if (getNum) {        // we want what's after the colon
         col = pos(':', list, col) + 1;
         num := substr(list, col, pos(' ', list, col) - col);
         if (isinteger(num)) {
            return (int)num;
         } else {
            return 0;
         }
      } else {
         // see if it matches this version of ON
         if (substr(list, col, 1) == getPlusMinus(1, backwards)){
            return 1;
         } else {
            return 0;
         }
      }
   }

   // if we get here, that means we found a great big nothing - that means it's off
   // but if backwards is true, that means it's on...
   return (int)(backwards);
}

/** 
 * File load option - whether to load files partially.  To 
 * retrieve the current value, call with no parameters.   
 * 
 * @param value            the new value to be set, an int that 
 *                         will be interpreted as a bool
 * 
 * @return int             the current value
 */
int _flo_load_partial(int value = null)
{
   typeless on, num;
   parse def_max_loadall with on num;
   if (value == null) {
      value = on;
   } else {
      def_max_loadall = value' 'num;
   }

   return value;
}

/** 
 * File load options - get/set the value for loading a file 
 * partially if it is larger than a certain size.  To get, call 
 * with no parameters. 
 * 
 * @param value            the new value to set, must be a 
 *                         positive integer
 * 
 * @return int             the current value
 */
int _flo_load_partial_if_larger_than(int value = null)
{
   typeless on, num;
   parse def_max_loadall with on num;
   if (value == null) {
      value = num;
   } else {
      def_max_loadall = on' 'value;
   }

   return value;
}

#region File Load/Save/Backup Options

/** 
 * Spill File Path - get/set the value for the directory for
 * spill and temporary files.  To get current value, call with 
 * no parameters.  This function may seem redundant to 
 * _spill_file_path(), but a non-builtins function was needed 
 * for the options dialog. 
 * 
 * @param value            the new value to set
 * 
 * @return _str             the current value
 */
_str _spill_file_path_option(_str value = null)
{
   if (value != null) {
      // make sure we don't have any quotes hanging around
      value = strip(value, 'B', '"');

      // make sure this path exists, please
      if (!file_exists(value)) value = null;

      _macro_call('_spill_file_path',value);
   }
   return _spill_file_path(value);
}

/** 
 * Command Line Completion - When set to True, a pop-up list of
 * possible commands and argument completions is displayed for 
 * partially typed commands and arguments on the SlickEdit 
 * command line. 
 * 
 * @param value            the new value to set
 * 
 * @return boolean         the current value
 */
boolean _command_line_completion(boolean value = null)
{
   if (value == null) {
      value = ((def_argument_completion_options & VSARGUMENT_COMPLETION_COMMANDLINE) != 0);
   } else {
      if (value) {
         def_argument_completion_options |= VSARGUMENT_COMPLETION_COMMANDLINE;
         def_argument_completion_options |= VSARGUMENT_COMPLETION_ENABLE;
         _macro_append("def_argument_completion_options |= VSARGUMENT_COMPLETION_ENABLE;");
         _macro_append("def_argument_completion_options |= VSARGUMENT_COMPLETION_COMMANDLINE;");
      } else {
         def_argument_completion_options &= ~VSARGUMENT_COMPLETION_COMMANDLINE;
         _macro_append("def_argument_completion_options &= ~VSARGUMENT_COMPLETION_COMMANDLINE;");
      }
   }

   return value;
}

/** 
 * Buffer Cache Size - Specifies the maximum amount of memory, 
 * in kilobytes, used to store text buffer data. A value that is 
 * less than zero specifies all available memory. May seem 
 * redundant to _cache_size(), but a non-builtin method was 
 * needed for the options dialog 
 * 
 * @param value         the new value to set
 * 
 * @return _str         the current value
 */
_str _buffer_cache_size(_str cache = null)
{
   if (cache == null) {
      parse _cache_size() with cache .;
   } else {
      cache_size(cache' -1');
      _macro_call('cache_size', cache' -1');
   }

   return cache;
}

/** 
 * Start in Insert Mode - Specifies the default insert/replace 
 * editing mode to use each time the editor is invoked.  True 
 * indicates insert mode, false indicates overstrike mode. 
 * 
 * @param value            the new value to set, leave blank to 
 *                         retrieve current value (boolean as
 *                         0/1)
 * 
 * @return int             the current value (boolean as 0/1)
 */
int _start_in_insert_mode(int value = null)
{
   // if default value is used, then we return the current value
   if (value == null) {
      value = _mdi.p_child._insert_state("", 'D');
   } else {
      _mdi.p_child._insert_state(value, 'D');
   }

   return value;
}

/** 
 * Alt Menu Hotkeys - When set to True, "Alt"-prefixed keyboard
 * shortcuts display the corresponding drop-down menu. When set 
 * to False, you can be more selective about key bindings 
 * because you are permitted to bind Alt keys you normally could 
 * not, such as Alt+F. Set to False if you bind Alt keys that 
 * are normally menu keys; otherwise, you will lose these key 
 * bindings. 
 * 
 * @param value            the new value to set, leave blank to 
 *                         retrieve current value (boolean as
 *                         0/1)
 * 
 * @return int             the current value (boolean as 0/1)
 */
int _alt_menu_hotkeys(int value = null)
{
   // just return the value
   if (value == null) {
      return (int)(def_alt_menu != 0);
   } else {
      _str macro='';
      _str filename='';
      typeless status=0;

      //guisetup relies on def_alt_menu being up to date.
      //altsetup release on def_gui being up to date.
      macro = 'altsetup';
      filename = get_env('VSROOT')'macros' :+ FILESEP :+ (macro :+ _macro_ext'x');
      if (!file_exists(filename)) {
         filename = get_env('VSROOT')'macros' :+ FILESEP :+ (macro :+ _macro_ext);
      }
      if (!file_exists(filename)) {
         _message_box(nls("File '%s' not found", macro :+ _macro_ext'x'));
         return(FILE_NOT_FOUND_RC);
      }
      _macro('m', 0);
      _no_mdi_bind_all = 1;
      macro = maybe_quote_filename(macro);
      status = shell(macro' 'number2yesno(value));
      _no_mdi_bind_all = 0;
      _macro('m', _macro('s'));
      _macro_call('shell', macro' 'number2yesno(value));
      if (status) {
         _message_box(nls("Unable to set alt menu hotkeys.\n\nError probably caused by missing macro compiler or incorrect macro compiler version."));
         return(1);
      }
   }

   return value;
}

/** 
 * Command Line Prompting - When set to True, pressing a key 
 * binding that normally opens a dialog box causes the SlickEdit 
 * command line to prompt for arguments instead of opening the 
 * dialog. 
 * 
 * @param value            the new value to set, leave blank to 
 *                         retrieve current value (boolean as
 *                         0/1)
 * 
 * @return int             the current value (boolean as 0/1)
 */
_str _command_line_prompting(_str value = null)
{
   // just return the value
   if (value == null) {
      return (!def_gui);
   } else {
      _str macro='';
      _str filename='';
      typeless status=0;

      macro='guisetup';
      filename=get_env('VSROOT')'macros':+FILESEP:+(macro:+_macro_ext'x');
      if (filename=='') {
         filename=get_env('VSROOT')'macros':+FILESEP:+(macro:+_macro_ext);
      }
      if (filename=='') {
         _message_box("File '%s' not found",macro:+_macro_ext'x');
         return(FILE_NOT_FOUND_RC);
      }

      _macro('m',0);
      _no_mdi_bind_all=1;
      macro=maybe_quote_filename(macro);
      status=shell(macro' 'number2yesno(!(int)value));
      _no_mdi_bind_all=0;
      _macro('m',_macro('s'));
      _macro_call('shell',macro' 'number2yesno(!(int)value));
      if (status) {
         _message_box(nls("Unable to set cmdline prompt option.\n\nError probably caused by missing macro compiler or incorrect macro compiler version."));
         return(1);
      }
   }
   return value;
}

#region Search Options
/** 
 * Search Options - Use Regular Expression 
 * <br>When set to True, search commands default to regular 
 * expression searching. 
 * 
 * @param value            the new value to set, leave blank to 
 *                         retrieve current value 
 * 
 * @return int             the current value 
 */
boolean _so_regular_expression(boolean value = null)
{
   int so = _default_option('S');

   // just return the value
   if (value == null) {
      value = ((so & (VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE | VSSEARCHFLAG_RE | VSSEARCHFLAG_WILDCARDRE | VSSEARCHFLAG_PERLRE)) != 0);
   } else {
      if (value) {
         so |= def_re_search;
      } else {
         so &= ~def_re_search;
      }
      _default_option('S', so);
      _macro_call("_default_option", 'S', so);
   }
   return value;
}

/** 
 * Search Options - Regular Expression Type
 * <br>Sets the type of regular expression to use while 
 * searching.  Possible values: 
 *  
 * <UL>
 * <LI><B>VSSEARCHFLAG_UNIXRE</B> - Unix.
 * <LI><B>VSSEARCHFLAG_BRIEFRE</B> - Brief.
 * <LI><B>VSSEARCHFLAG_RE</B> - SlickEdit.
 * <LI><B>VSSEARCHFLAG_PERLRE</B> - Perl.
 * <LI><B>VSSEARCHFLAG_WILDCARDRE</B> - Wildcard.
 * </UL>
 * 
 * @param value            the new value to set, leave blank to 
 *                         retrieve current value 
 * 
 * @return int             the current value 
 */
int _so_regular_expression_type(int value = null)
{
   if (value == null) {
      value = def_re_search;
   } else {

      // check to see if this option is turned on, then OR it into the search options
      if (_so_regular_expression()) {
         so := _default_option('S');

         // first we get rid of all the other search options (could just 
         // get rid of the current, but this is super safe)
         so &= ~(VSSEARCHFLAG_UNIXRE | VSSEARCHFLAG_BRIEFRE | VSSEARCHFLAG_RE | VSSEARCHFLAG_WILDCARDRE | VSSEARCHFLAG_PERLRE);
         so |= value;

         _default_option('S', so);
         _macro_call('_default_option','S', so);
      }

      def_re_search = value;
      _macro_append('def_re_search = 'def_re_search';');
   }

   return value;
}

/**
 * Search Options > Wrap at beginning/end.  Gets/sets the 
 * current value.  Send in null to retrieve the current value.
 * 
 * @param value         value to set, null to retrieve only
 * 
 * @return              current value
 */
int _so_wrap_at_beginning_end(int value = null)
{
   // this may seem silly to get a function to do this, however, since 
   // two of the options have flags which 'overlap,' it's impossible to tell which is on
   promptWrapFlag := VSSEARCHFLAG_PROMPT_WRAP | VSSEARCHFLAG_WRAP;
   so := _default_option('S');

   if (value == null) {

      // check the prompt value first
      if ((so & promptWrapFlag) == promptWrapFlag) {
         value = promptWrapFlag;
      } else if ((so & VSSEARCHFLAG_WRAP) == VSSEARCHFLAG_WRAP) {
         value = VSSEARCHFLAG_WRAP;
      } else value = 0;
   } else {
      // first get rid of the old option - this flag will get rid of them all
      so &= ~promptWrapFlag;

      // now throw in the new one and set the value
      so |= value;
      _default_option('S', so);
      _macro_call('_default_option','S', so);
   }

   return value;
}

#endregion Search Options

/** 
 * Smooth Vertical Scroll - When set to True, editor windows 
 * scroll line-by-line when the cursor moves out of view. When 
 * set to False, the cursor is centered and the text is scrolled 
 * half the height of the window when the cursor moves out of 
 * view. 
 *  
 * @param value            the new value to set, leave blank to 
 *                         retrieve current value 
 * 
 * @return boolean         the current value 
 */
boolean _smooth_vertical_scroll(boolean value = null)
{
   typeless style='';
   typeless num='';
   parse _scroll_style() with style num;

   style = (strip(upcase(style)));

   // Values for scroll style
   // H - smooth scrolling on for only vert
   // S - smooth scrolling on for both horz and vert (or any letter besides H,C,V)
   // C - smooth scrolling off for both horz and vert
   // V - smooth scrolling on for only horz
   if (value == null) {
      if (style == 'C' || style == 'V') {
         value = false;
      } else value = true;
   } else {
      _str newStyle = style;

      if (value) {
         switch (style) {
         case 'V':
            newStyle = 'S';
            break;
         case 'C':
            newStyle = 'H';
            break;
         }
      } else {
         switch (style) {
         case 'S':
            newStyle = 'V';
            break;
         case 'H':
            newStyle = 'C';
            break;
         }
      }
      if (newStyle != style) {
         newStyle = newStyle :+ ' ' :+ num;
         _scroll_style(newStyle);
         _macro_call('_scroll_style('newStyle')');
      }
   }
   return value;
}

/** 
 * Smooth Horizontal Scroll - When set to True, editor windows 
 * scroll line-by-line when the cursor moves out of view. When 
 * set to False, the cursor is centered and the text is scrolled 
 * half the height of the window when the cursor moves out of 
 * view. 
 *  
 * @param value            the new value to set, leave blank to 
 *                         retrieve current value 
 * 
 * @return boolean         the current value 
 */
boolean _smooth_horizontal_scroll(boolean value = null)
{
   typeless style='';
   typeless num='';
   parse _scroll_style() with style num;

   style = (strip(upcase(style)));

   // Values for scroll style
   // H - smooth scrolling on for only vert
   // S - smooth scrolling on for both horz and vert (or any letter besides H,C,V)
   // C - smooth scrolling off for both horz and vert
   // V - smooth scrolling on for only horz
   if (value == null) {
      if (style == 'C' || style == 'H') {
         value = false;
      } else value = true;
   } else {
      _str newStyle = style;

      if (value) {
         switch (style) {
         case 'H':
            newStyle = 'S';
            break;
         case 'C':
            newStyle = 'V';
            break;
         }
      } else {
         switch (style) {
         case 'S':
            newStyle = 'H';
            break;
         case 'V':
            newStyle = 'C';
            break;
         }
      }
      if (newStyle != style) {
         newStyle = newStyle :+ ' ' :+ num;
         _scroll_style(newStyle);
         _macro_call('_scroll_style('newStyle')');
      }
   }
   return value;
}

/** 
 * Sets whether or not to use a block cursor.  Specify 'y' to 
 * use vertical cursor and 'n' to use a block cursor.  Calling 
 * this method with no parameters will return y/n depending on 
 * the current value. 
 * 
 * @param value         new value (leave blank to retrieve 
 *                      current)
 * 
 * @return _str         current value
 */
boolean _use_vertical_cursor(boolean value = null)
{
   _str newCP, cp;
   newCP = cp = _cursor_shape();
   value = checkStringOption(newCP, '-v ', value);

   if (cp != newCP) {
      _cursor_shape(newCP);
      _macro_call('_cursor_shape', newCP);
   }

   return value;
}


/** 
 * RTF Clipboard Format. 
 *  
 * @param value         new value (leave blank to retrieve 
 *                      current)
 * 
 * @return boolean         current value 
 *  
 * @deprecated 
 */
boolean _rtf_clipboard_format(boolean value = null)
{
   return value;
}

/** 
 * HTML Clipboard Format.  Calling this method with no 
 * parameters will return y/n depending on the current value. 
 * 
 * @param value         new value (leave blank to retrieve 
 *                      current)
 * 
 * @return boolean         current value
 */
boolean _html_clipboard_format(boolean value = null)
{
   _str format = def_clipboard_formats;
   value = checkStringOption(format, 'H', value);

   // did the format change?
   if (format != def_clipboard_formats) {
      def_clipboard_formats = format;
      _macro_call('def_clipboard_formats="'format'"');
   }

   return value;
}

/** 
 * Some options are set by adding string literals to a setting. 
 * For example, see setting RTF Clipboard format.  This method 
 * parses those options to either get or set the current value. 
 * 
 * @param current          current string containing setting
 * @param option           option we are looking for (such as 
 *                         '-v')
 * @param value            whether this value should be on or 
 *                         off (leave blank to retrieve current
 *                         value)
 * 
 * @return boolean         current value
 */
boolean checkStringOption(_str &current, _str option, boolean value = null)
{
   // find it to see if it's on or off
   int vPos = pos(option, current);

   // we just want to retrieve the value here
   if (value == null) {
      value = (vPos != 0);
   } else {
      // we're setting the value now
      if (value && !vPos) {
         current = option :+ current;
      } else if (!value && vPos) {
         current = substr(current, 1, vPos - 1) :+ substr(current, vPos + option._length());
      }
   }

   return value;
}

/**
 * Gets or sets the option found at Tools > Options > Editing > Selections > 
 * Extend selection as cursor moves.  To retrieve the current value, call the 
 * function with no arguments. 
 * 
 * @param value            the new value to be set
 * 
 * @return                 the current value
 */
boolean _selections_extend_selections_with_cursor(boolean value = null)
{
   cPosition := pos('C', def_select_style);
   
   if (value == null) {
      value = (cPosition != 0);
   } else {
      if (value && !cPosition) {
         style := stranslate(def_select_style, 'C', 'E');
         if (style == def_select_style) {
            def_select_style = 'C' :+ def_select_style;
         } else def_select_style = style;
      } else if (!value && cPosition) {
         def_select_style = stranslate(def_select_style, 'E', 'C');
      }
   }
   
   return value;
}

/**
 * Gets or sets the option found at Tools > Options > Editing > Selections > 
 * Inclusive character selection.  To retrieve the current value, call the 
 * function with no arguments. 
 * 
 * @param value            the new value to be set
 * 
 * @return                 the current value
 */
boolean _selections_inclusive_character_selection(boolean value = null)
{
   iPosition := pos('I', def_select_style);
   
   if (value == null) {
      value = (iPosition != 0);
   } else {
      if (value && !iPosition) {
         style := stranslate(def_select_style, 'I', 'N');
         if (style == def_select_style) {
            def_select_style = 'I' :+ def_select_style;
         } else def_select_style = style;
      } else if (!value && iPosition) {
         def_select_style = stranslate(def_select_style, 'N', 'I');
      }
   }
   
   return value;
}

/**
 * Gets/Sets the emulation.
 * 
 * @param value            current value to set, leave null to just return the 
 *                         current value
 * 
 * @return                 current value
 */
_str _emulation_option(_str value = null)
{
   if (value == null) {
      value = def_keys;
   } else {
      emulation := getEmulationFromKeys(value);

      def_emulation_was_selected=true;
      if (def_keys != value) {
         switchEmulation(emulation, 1, 1);
      }
   }
   
   return value;
}

/**
 * Gets/sets the comment block setting - First line is top.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
boolean _lang_block_comment_first_line_is_top(_str langID, boolean value = null)
{
   return _lang_block_comment_setting(langID, CS_FIRST_LINE_IS_TOP, value);
}

/**
 * Gets/sets the comment block setting - Last line is bottom.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
boolean _lang_block_comment_last_line_is_bottom(_str langID, boolean value = null)
{
   return _lang_block_comment_setting(langID, CS_LAST_LINE_IS_BOTTOM, value);
}

/**
 * Gets/sets the comment block setting - top left corner.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
_str _lang_comment_block_top_left_corner(_str langID, _str value = null)
{
   return _lang_block_comment_setting(langID, CS_TLC, value);
}

/**
 * Gets/sets the comment block setting - top horizontal side.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
_str _lang_comment_block_top_side(_str langID, _str value = null)
{
   return _lang_block_comment_setting(langID, CS_TOP_SIDE, value);
}

/**
 * Gets/sets the comment block setting - top right corner.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
_str _lang_comment_block_top_right_corner(_str langID, _str value = null)
{
   return _lang_block_comment_setting(langID, CS_TRC, value);
}

/**
 * Gets/sets the comment block setting - left vertical side.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
_str _lang_comment_block_left_side(_str langID, _str value = null)
{
   return _lang_block_comment_setting(langID, CS_LEFT_SIDE, value);
}

/**
 * Gets/sets the comment block setting - right vertical side.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
_str _lang_comment_block_right_side(_str langID, _str value = null)
{
   return _lang_block_comment_setting(langID, CS_RIGHT_SIDE, value);
}

/**
 * Gets/sets the comment block setting - bottom left corner.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
_str _lang_comment_block_bottom_left_corner(_str langID, _str value = null)
{
   return _lang_block_comment_setting(langID, CS_BLC, value);
}

/**
 * Gets/sets the comment block setting - bottom horizontal side.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
_str _lang_comment_block_bottom_side(_str langID, _str value = null)
{
   return _lang_block_comment_setting(langID, CS_BOTTOM_SIDE, value);
}

/**
 * Gets/sets the comment block setting - bottom right corner
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
_str _lang_comment_block_bottom_right_corner(_str langID, _str value = null)
{
   return _lang_block_comment_setting(langID, CS_BRC, value);
}

/**
 * Gets/sets the comment block setting - left line comment.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
_str _lang_left_line_comment(_str langID, _str value = null)
{
   return _lang_block_comment_setting(langID, CS_LINE_LEFT, value);
}

/**
 * Gets/sets the comment block setting - right line comment.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
_str _lang_right_line_comment(_str langID, _str value = null)
{
   return _lang_block_comment_setting(langID, CS_LINE_RIGHT, value);
}

/**
 * Gets/sets the comment block setting - line comment mode.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
int _lang_line_comment_mode(_str langID, int value = null)
{
   return _lang_block_comment_setting(langID, CS_LINE_COMMENT_MODE, value);
}

/**
 * Gets/sets the comment block setting - line comment column.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
int _lang_line_comment_column(_str langID, int value = null)
{
   return _lang_block_comment_setting(langID, CS_LINE_COMMENT_COL, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Enable comment wrap.
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
boolean _lang_enable_comment_wrap(_str langID, boolean value = null)
{
   return _lang_comment_wrap_option(langID, CW_ENABLE_COMMENT_WRAP, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Enable block comment 
 * wrap. 
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
boolean _lang_enable_block_comment_wrap(_str langID, boolean value = null)
{
   return _lang_comment_wrap_option(langID, CW_ENABLE_BLOCK_WRAP, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Enable line comment 
 * wrap.
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
boolean _lang_enable_line_comment_wrap(_str langID, boolean value = null)
{
   return _lang_comment_wrap_option(langID, CW_ENABLE_LINEBLOCK_WRAP, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Enable doc comment 
 * wrap.
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
boolean _lang_enable_doc_comment_wrap(_str langID, boolean value = null)
{
   return _lang_comment_wrap_option(langID, CW_ENABLE_DOCCOMMENT_WRAP, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Preserve width on 
 * existing comments. 
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
boolean _lang_preserve_width_on_existing_comments(_str langID, boolean value = null)
{
   return _lang_comment_wrap_option(langID, CW_AUTO_OVERRIDE, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Javadoc auto indent. 
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
boolean _lang_javadoc_auto_indent(_str langID, boolean value = null)
{
   return _lang_comment_wrap_option(langID, CW_JAVADOC_AUTO_INDENT, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Comment wrap width.
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
int _lang_comment_wrap_width(_str langID, int value = null)
{
   int choices[];
   choices[0] = CW_USE_FIXED_WIDTH;
   choices[1] = CW_USE_FIRST_PARA;
   choices[2] = CW_USE_FIXED_MARGINS;
   
   if (value == null) {
      value = choices[0];
      for (i := 0; i < choices._length(); i++) {
         if (_lang_comment_wrap_option(langID, choices[i], null)) {
            value = choices[i];
            break;
         }
      }
   } else {
      for (i := 0; i < choices._length(); i++) {
         newValue := (value == choices[i]);
         _lang_comment_wrap_option(langID, choices[i], newValue);
      }
   }
   
   return value;
}

/**
 * Gets/Sets the language-specific comment wrap option - Use max right column 
 * (when used with the Fixed width comment width setting). 
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
boolean _lang_comment_wrap_use_max_right_column_fixed(_str langID, boolean value = null)
{
   return _lang_comment_wrap_option(langID, CW_MAX_RIGHT, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Use max right column 
 * (when used with the Automatic width comment width setting). 
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
boolean _lang_comment_wrap_use_max_right_column_auto(_str langID, boolean value = null)
{
   return _lang_comment_wrap_option(langID, CW_MAX_RIGHT_DYN, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Max right column 
 * position (when used with the Fixed width comment width setting). 
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
int _lang_comment_wrap_max_right_column_position_fixed(_str langID, int value = null)
{
   return _lang_comment_wrap_option(langID, CW_MAX_RIGHT_COLUMN, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Max right column 
 * position (when used with the Automatic width comment width setting). 
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
int _lang_comment_wrap_max_right_column_position_auto(_str langID, int value = null)
{
   return _lang_comment_wrap_option(langID, CW_MAX_RIGHT_COLUMN_DYN, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Right column 
 * position. 
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
int _lang_comment_wrap_right_column_position(_str langID, int value = null)
{
   return _lang_comment_wrap_option(langID, CW_RIGHT_MARGIN, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Fixed width size.
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
int _lang_comment_wrap_fixed_width_size(_str langID, int value = null)
{
   return _lang_comment_wrap_option(langID, CW_FIXED_WIDTH_SIZE, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Match previous 
 * paragraph. 
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
boolean _lang_comment_wrap_match_previous_paragraph(_str langID, boolean value = null)
{
   return _lang_comment_wrap_option(langID, CW_MATCH_PREV_PARA, value);
}

/**
 * Gets/Sets the language-specific comment wrap option - Start wrapping from.
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
int _lang_comment_wrap_start_wrapping_from(_str langID, int value = null)
{
   return _lang_comment_wrap_option(langID, CW_LINE_COMMENT_MIN, value);
}

/**
 * Gets/Sets a language-specific comment wrap option.
 * 
 * @param langID           language id
 * @param option           option we're interested in, one of the 
 *                         CommentWrapSettings enum
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
typeless _lang_comment_wrap_option(_str langID, int option, typeless value)
{
   if (value == null) {
      value = _GetCommentWrapFlags(option, langID);
   } else {
      _SetCommentWrapFlags(option, value, langID);
   }
   
   return value;
}

/**
 * Gets/Sets the language-specific xml wrap option - Default formatting scheme.
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
_str _lang_xml_wrap_formatting_scheme(_str langID, _str value = null)
{
   return _lang_xml_wrap_option(langID, value, XW_DEFAULT_SCHEME);
}

/**
 * Gets/Sets the language-specific xml wrap option - Enable content wrapping.
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
boolean _lang_xml_wrap_enable_content_wrapping(_str langID, boolean value = null)
{
   return _lang_xml_wrap_option(langID, value, XW_ENABLE_CONTENTWRAP);
}

/**
 * Gets/Sets the language-specific xml wrap option - Enable tag layout.
 * 
 * @param langID           language id
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
boolean _lang_xml_wrap_enable_tag_layout(_str langID, boolean value = null)
{
   return _lang_xml_wrap_option(langID, value, XW_ENABLE_TAGLAYOUT);
}

/**
 * Gets/Sets a language-specific xml wrap option.
 * 
 * @param langID           language id
 * @param option           option we're interested in, XW_ENABLE_CONTENTWRAP, 
 *                         XW_ENABLE_TAGLAYOUT, or XW_DEFAULT_SCHEME
 * @param value            value to set, null to just return current value
 * 
 * @return                 current value
 */
typeless _lang_xml_wrap_option(_str langID, typeless value, int option)
{
   if (value == null) {
      value = _GetXMLWrapFlags(option, langID);
   } else {
      _SetXMLWrapFlags(option, value, langID);
   }
   
   return value;
}

/**
 * Gets/sets the list of file extensions for this language.
 * 
 * @param langID           language id
 * @param value            list of file extensions we want to set for this 
 *                         language, null to retrieve current value
 * 
 * @return                 current list of file extensions for language
 */
_str _lang_file_extensions(_str langID, _str value = null)
{
   if (value == null) {
      value = get_file_extensions_sorted(langID);
   } else {
      update_file_extensions(langID, value);
   }

   return value;
}

/**
 * Gets/sets the list of reference languages for this language.
 *
 * @param langID           language id
 * @param value            list of file extensions we want to set for this
 *                         language, null to retrieve current value
 *
 * @return                 current list of file extensions for language
 */
_str _lang_referenced_in_langs(_str langID, _str value = null)
{
   if (value == null) {
      value = get_referenced_in_languages(langID);
   } else {
      update_referenced_in_languages(langID, value);
   }

   return value;
}

/**
 * Gets/sets the left side code margin.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
_str _lang_left_code_margin(_str langID, _str value = null)
{
   return _lang_code_margins(langID, 'L', value);
}

/**
 * Gets/sets the right side code margin.
 * 
 * @param langID              language this setting applies to
 * @param value               value to set, null to just return the current 
 *                            value
 * 
 * @return                    current value
 */
_str _lang_right_code_margin(_str langID, _str value = null)
{
   return _lang_code_margins(langID, 'R', value);
}

_str _lang_left_margin(_str langID, _str value = null)
{
   return _lang_margins(langID, 'L', value);
}

_str _lang_right_margin(_str langID, _str value = null)
{
   return _lang_margins(langID, 'R', value);
}

_str _lang_new_paragraph_margin(_str langID, _str value = null)
{
   return _lang_margins(langID, 'P', value);
}

_str _lang_margins(_str langID, _str margin, _str value = null)
{
   typeless leftm = "", rightm = "", param = "";
   parse LanguageSettings.getMargins(langID) with leftm rightm param;
   if (param == '') param = leftm;
   
   if (value == null) {
      switch (margin) {
      case 'L':
         value = leftm;
         break;
      case 'R':
         value = rightm;
         break;
      case 'P':
         value = param;
         break;
      }
   } else {
      switch (margin) {
      case 'L':
         leftm = value;
         break;
      case 'R':
         rightm = value;
         break;
      case 'P':
         param = value;
         break;
      }
      
      LanguageSettings.setMargins(langID, leftm' 'rightm' 'param);
   }
   
   return value;
}

_str _lang_code_margins(_str langID, _str margin, _str value = null)
{
   typeless leftcm = "", rightcm = "";
   parse LanguageSettings.getCodeMargins(langID) with leftcm rightcm;
   
   if (value == null) {
      switch (margin) {
      case 'L':
         value = leftcm;
         break;
      case 'R':
         value = rightcm;
         break;
      }
   } else {
      switch (margin) {
      case 'L':
         leftcm = value;
         break;
      case 'R':
         rightcm = value;
         break;
      }
      
      LanguageSettings.setCodeMargins(langID, leftcm' 'rightcm);
   }
   
   return value;
}

int _lang_dynamic_surround_on(_str langID, int value = null)
{
   if (value != null) {
      if (value && !(def_surround_mode_options & VS_SURROUND_MODE_ENABLED)) {
         def_surround_mode_options = 0xFFFF;
      }
      
      if (value) value = def_surround_mode_options;
   }
   
   return _lang_option(langID, 'surround', true, value);

}

int _lang_smart_tab(_str langID, int value = null)
{
   if (value == null) {
      value = _get_smarttab(langID, auto smartpasteIndex);
      if (value < 0) value = abs(value);
   
      if (value == VSSMARTTAB_MAYBE_REINDENT_STRICT) {
         value = VSSMARTTAB_MAYBE_REINDENT;
      }
   } else {
      curValue := _lang_smart_tab(langID);
      if (!(value == VSSMARTTAB_MAYBE_REINDENT && curValue == VSSMARTTAB_MAYBE_REINDENT_STRICT)) {
         _lang_option(langID, 'smarttab', def_smarttab, value);
      }
   }
   
   return value;   
}

boolean _lang_smart_tab_strict(_str langID, boolean value = null)
{
   if (value == null) {
      smartTab := _get_smarttab(langID, auto smartpasteIndex);
      if (smartTab < 0) smartTab = abs(smartTab);
      
      value = (smartTab == VSSMARTTAB_MAYBE_REINDENT_STRICT);
   } else {
      if (value) {
         _lang_option(langID, 'smarttab', def_smarttab, VSSMARTTAB_MAYBE_REINDENT_STRICT);
      } else {
         if (_lang_smart_tab_strict(langID)) {
            _lang_option(langID, 'smarttab', def_smarttab, VSSMARTTAB_MAYBE_REINDENT);
         }
      }
   }
   
   return value;
}

typeless _lang_option(_str langID, _str key, typeless defaultVal, typeless value = null)
{
   key = 'def-'key'-'langID;
   index := find_index(key, MISC_TYPE);
   
   if (value == null) {
      if (index <= 0 || name_info(index) == '') {
         value = defaultVal;
      } else {
         value = name_info(index);
      }
   } else {
      if (index <= 0) {
         index = insert_name(key, MISC_TYPE, value);
      } else {
         set_name_info(index, value);
      }
   }
   
   return value;
}

_str _lang_embedded_lexer(_str langID, _str value = null)
{
   key := '';
   defaultVal := '';
   htmlBased := false;
   switch (langID) {
   case 'cob':
   case 'cob74':
   case 'cob2000':
      key = VSCOBOL_SQL_LEXER_NAME;
      defaultVal = 'PL/SQL';
      break;
   case 'html':
   case 'cfml':
      key = VSHTML_ASP_LEXER_NAME;
      defaultVal = 'VBScript';
      htmlBased = true;
      break;
   }
      
   index := find_index(key, MISC_TYPE);
   
   if (value == null) {
      if (!index) index = insert_name(key, MISC_TYPE, defaultVal);
      value = name_info(index);
      
      if (htmlBased) {
         switch (value) {
         case "VB":
            value = "Visual Basic";
            break;
         case "C#":
            value = "CSharp";
            break;
         }
      }
   } else {
      if (!index) index = insert_name(key, MISC_TYPE, value);
      else set_name_info(index, value);
   }
      
   return value;   
}

/**
 * Gets or sets the new window height value.
 * 
 * @param value   the value to set (null to retrieve value), 
 *                values are as follows:
 * <pre>
 *  1 - use current window to set a custom size
 *  0 - use default
 * -1 - use maximum available
 * -2 - use the size of the window currently active when new window is opened 
 * -3 - use a custom size (does not set anything) 
 * </pre>
 * 
 * @return        the current new window height value
 */
int _new_window_height(int value = null)
{
   if (value == null) {
      // we just want the current value
      value = _default_option(VSOPTION_NEW_WINDOW_HEIGHT, value);
      if (value > 0) {
         // if the value is greater than 0, then we know it's a custom value
         value = -3;
      }
   } else {
      // we are setting it!
      // if it's -3, then we know it's a custom value
      if (value > -3) {
         // here we want the current window's height
         if (value == 1) {
            _default_option(VSOPTION_NEW_WINDOW_HEIGHT, _mdi.p_child.p_height);
         } else {
            _default_option(VSOPTION_NEW_WINDOW_HEIGHT, value);
         }
      }
   }

   return value;
}

/**
 * Sets the new window height value as a custom value.
 * 
 * @param value      new value (null to retrieve current)
 * 
 * @return           current value
 */
int _custom_window_height(int value = null)
{
   if (value == null) {
      // we just want the current value
      value = _default_option(VSOPTION_NEW_WINDOW_HEIGHT, value);
      if (value < 0) value = 0;
   } else {
      if (value > 0) {
         _default_option(VSOPTION_NEW_WINDOW_HEIGHT, value);
      }
   }

   return value;
}

/**
 * Gets or sets the new window width value.
 * 
 * @param value   the value to set (null to retrieve value), 
 *                values are as follows:
 * <pre>
 *  1 - use current window to set a custom size
 *  0 - use default
 * -1 - use maximum available
 * -2 - use the size of the window currently active when new window is opened 
 * -3 - use a custom size (does not set anything) 
 * </pre>
 * 
 * @return        the current new window width value
 */
int _new_window_width(int value = null)
{
   if (value == null) {
      // we just want the current value
      value = _default_option(VSOPTION_NEW_WINDOW_WIDTH, value);
      if (value > 0) {
         // if the value is greater than 0, then we know it's a custom value
         value = -3;
      }
   } else {
      // we are setting it!
      // if it's -2, then we know it's a custom value
      if (value > -3) {
         // here we want the current window's width
         if (value == 1) {
            _default_option(VSOPTION_NEW_WINDOW_WIDTH, _mdi.p_child.p_width);
         } else {
            _default_option(VSOPTION_NEW_WINDOW_WIDTH, value);
         }
      }
   }

   return value;
}

/**
 * Sets the new window width value as a custom value.
 * 
 * @param value      new value (null to retrieve current)
 * 
 * @return           current value
 */
int _custom_window_width(int value = null)
{
   if (value == null) {
      // we just want the current value
      value = _default_option(VSOPTION_NEW_WINDOW_WIDTH, value);
      if (value < 0) value = 0;
   } else {
      if (value > 0) {
         _default_option(VSOPTION_NEW_WINDOW_WIDTH, value);
      }
   }

   return value;
}

/**
 * Debugger Options > Numbers > Short.  Set by sending value, 
 * retrieve by sending null. 
 *  
 * @param value      value to set, null to retrieve current 
 *                   value
 * 
 * @return           current value
 */
int _dbgo_short_format(int value = null)
{
   if (value == null) {
      value = get_debug_number_format('short');
   } else {
      set_debug_number_format('short', value);
   }

   return value;
}

/**
 * Debugger Options > Numbers > Int.  Set by sending value, 
 * retrieve by sending null. 
 *  
 * @param value      value to set, null to retrieve current 
 *                   value
 * 
 * @return           current value
 */
int _dbgo_int_format(int value = null)
{
   if (value == null) {
      value = get_debug_number_format('int');
   } else {
      set_debug_number_format('int', value);
   }

   return value;
}

/**
 * Debugger Options > Numbers > Long.  Set by sending value, 
 * retrieve by sending null. 
 *  
 * @param value      value to set, null to retrieve current 
 *                   value
 * 
 * @return           current value
 */
int _dbgo_long_format(int value = null)
{
   if (value == null) {
      value = get_debug_number_format('long');
   } else {
      set_debug_number_format('long', value);
   }

   return value;
}

/**
 * Debugger Options > Numbers > Unsigned.  Set by sending value,
 * retrieve by sending null. 
 *  
 * @param value      value to set, null to retrieve current 
 *                   value
 * 
 * @return           current value
 */
int _dbgo_unsigned_format(int value = null)
{
   if (value == null) {
      value = get_debug_number_format('unsigned');
   } else {
      set_debug_number_format('unsigned', value);
   }

   return value;
}

/**
 * Debugger Options > Numbers > Floats.  Set by sending value, 
 * retrieve by sending null. 
 *  
 * @param value      value to set, null to retrieve current 
 *                   value
 * 
 * @return           current value
 */
int _dbgo_float_format(int value = null)
{
   if (value == null) {
      value = get_debug_number_format('float');
   } else {
      set_debug_number_format('float', value);
   }

   return value;
}

/**
 * Debugger Options > Numbers > Double.  Set by sending value, 
 * retrieve by sending null. 
 *  
 * @param value      value to set, null to retrieve current 
 *                   value
 * 
 * @return           current value
 */
int _dbgo_double_format(int value = null)
{
   if (value == null) {
      value = get_debug_number_format('double');
   } else {
      set_debug_number_format('double', value);
   }

   return value;
}

/**
 * Debugger Options > Numbers > Char.  Set by sending value, 
 * retrieve by sending null. 
 *  
 * @param value      value to set, null to retrieve current 
 *                   value
 * 
 * @return           current value
 */
int _dbgo_char_format(int value = null)
{
   if (value == null) {
      value = get_debug_number_format('char');
   } else {
      set_debug_number_format('char', value);
   }

   return value;
}

/**
 * Retrieves the current format of a value type for the Debugger 
 * Options > Numbers node.  Receives one of six types: short, 
 * int, long, float, double, char.
 *  
 * @param type       type to retrieve
 * 
 * @return           current value
 */
int get_debug_number_format(_str type)
{
   format := def_debug_number_formats:[type].base;
   if (format == null || format == VSDEBUG_BASE_DEFAULT) {
      if (type == 'char') {
         format = VSDEBUG_BASE_CHAR;
      } else {
         // No "natural" here, because the base type is "natural"
         // VSDEBUG_BASE_NATURAL will only be returned if no base type has been
         // set, and if that happens, we'll go with Decimal for now.
         format = VSDEBUG_BASE_DECIMAL;
      }
   }
   return format;
}

/**
 * Sets the current format of a value type for the Debugger 
 * Options > Numbers node.  Receives one of six types: short, 
 * int, long, float, double, char.
 *  
 * @param type       type to set
 * @param value      value to set
 */
void set_debug_number_format(_str type, int value)
{
   if (def_debug_number_formats:[type].base != value) {
      def_debug_number_formats:[type].base = value;
      _config_modify_flags(CFGMODIFY_DEFVAR);

      // Update the debugger in case anything changed
      // 
      // Have to do this twice because the first time will turn all of the changed
      // items red
      debug_gui_update_all_vars();
      debug_gui_update_all_vars();
   }
}

int _edit_show_nav_hints(int value = null)
{
   // just return the value
   if (value == null) {
      return def_display_nav_hints;
   } else {
      def_display_nav_hints = value;
      _reset_se_ui_NavMarker();
   }
   return value;
}

boolean _ant_options_identify_ant(_str lang, boolean value = null)
{
   if (value == null) {
      value = def_antmake_identify;
   } else {
      def_antmake_identify = value;
      _set_ant_options((int)def_antmake_identify, def_max_ant_file_size);
   }

   return value;
}

#endregion Get/Set Methods

/**
 * This function allows you to show the options dialog with a
 * specific node already brought up.  You can specify a node 
 * either by giving its caption or by specifying an embedded 
 * dialog's form name. 
 * 
 * @param nodeName  name of the node, embedded dialog, or 
 *                  language and subnode to show
 * @param options   whether the nodename parameter is a node 
 *                  name or an option.  Specify 'N' for a node
 *                  name, 'D' for a dialog, 'L' for a language
 *                  node, 'V' for a version control provider,
 *                  'S' to specify a search term. You may also
 *                  specify a '+' to say that the node should be
 *                  expanded.
 *  
 * @param arguments (use only with embedded dialogs) any 
 *                  arguments to send to the embedded dialog
 * 
 * @return the window id of the options dialog
 */
_command int config(_str nodeName = '', _str options = 'N', _str arguments = '', boolean reOpen = false) name_info(',')
{
   if (p_window_id == VSWID_HIDDEN) {
      p_window_id = _mdi;
   }
   _macro_delete_line();

   options = upcase(options);
   doExpand := false;
   if (pos('+', options)) {
      parse options with '+'options;
      doExpand = true;
   }

   wid := getOptionsForm(OP_CONFIG, false);
   isOpen := (wid > 0);

   if (isOpen) {
      p_window_id = wid;
   
      // in this case, we have to close this options dialog by cancelling first - hopefully this won't come up often
      if (reOpen) {
         cancelBtn := _find_control('_ctl_cancel');
         cancelBtn.call_event(false, cancelBtn, LBUTTON_UP, 'W');
         isOpen = false;
      } else {
         // show them that it was already open.  they'll feel so silly.
         wid._set_focus();
      }
   }

   if (!isOpen) {
      openStr := "-mdi -xy _options_tree_form";

      switch (options) {
      case 'D':
      case 'L':
      case 'S':
      case 'V':
         wid = show(openStr, OP_CONFIG, '', false);
         break;
      case 'N':
         wid = show(openStr, OP_CONFIG, nodeName, (nodeName == ''), false, arguments);
         break;
      }
   } 

   // make sure we have a valid window - sometimes the options XML is screwy.
   if (_iswindow_valid(wid)) {
      if (options == 'S') {
         wid.clearSearch();
         wid.doSearch(nodeName);
      } else {
         if (!showOptionsNode(wid, isOpen, nodeName, options, arguments)) {
            // try opening the node after clearing search and favorites
            if (wid.areWeShowingFavorites()) {
               wid.showAll();
               showOptionsNode(wid, isOpen, nodeName, options, arguments);
            } else if (wid.areWeSearching()) {
               wid.clearSearch();
               showOptionsNode(wid, isOpen, nodeName, options, arguments);
            }
         }
      
         // expand this node, please
         if (doExpand) {
            p_window_id = wid;
            treeWid := _find_control('_ctl_tree');
            treeWid._TreeExpandNode();
         }
      }
   }

   return wid;
}

/**
 * Shows a node in the options tree.  Presumes that the options are already 
 * open. 
 * 
 * 
 * @param wid              window id of options dialog
 * @param isOpen           whether the options dialog was open before we ever 
 *                         started down this path
 * @param nodeName         depends on the options argument
 * @param options          'N' - show the node with the caption defined by 
 *                         nodeName
 *                         'D' - show the node that displays the form named in
 *                         nodeName
 *                         'V' - show the version control node named in nodeName
 *                         'L' - show the language node named in nodeName 
 * @param arguments        any arguments to be sent to the displayed now
 * 
 * @return                 true if we were able to show the node, false 
 *                         otherwise
 */
static boolean showOptionsNode(int wid, boolean isOpen, _str nodeName = '', _str options = 'N', _str arguments = '')
{
   success := false;
   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS, wid);
   switch (options) {
   case 'D':
      success = optionsTree -> showDialogNode(nodeName, arguments, ISEB_SELECT_TOP);
      break;
   case 'V':
      _str vcName = '', node = '';
      parse nodeName with vcName' > 'node;
      success = optionsTree -> showVersionControlNode(vcName, node, arguments, ISEB_SELECT_TOP);
      break;
   case 'L':
      _str mode = '';
      parse nodeName with mode' > 'node;

      // see if this is a mode, it might be part of a path
      if (mode != '') {
         langId := _Modename2LangId(mode);
         if (langId == '') {
            // the nodeName was the path, we're supposed to use the language of the current buffer
            mode = '';
            node = nodeName;
         }
      }

      if (mode == '') mode = _LangId2Modename(_mdi.p_child.p_LangId);
      success = optionsTree -> showLanguageNode(mode, node, arguments, ISEB_RETURN);
      if (!success) {
         // maybe this language does not have the appropriate feature
         // try All Languages
         success = optionsTree -> showLanguageNode('All Languages', node, arguments, ISEB_RETURN);
      }
      break;
   case 'N':
      if (isOpen && nodeName != '') {
         success = optionsTree -> showNode(nodeName, false, ISEB_SELECT_TOP, arguments);
      } 
      break;
   }

   return success;
}

/**
 * Retrieves the window id of the options form.
 * 
 * @param purpose             the purpose of the options dialog that we're 
 *                            looking for (on of the OptionsPurpose enum)
 * @param embedded            whether this is being called from a dialog 
 *                            embedded inside the options dialog.
 * 
 * @return                    window id of options dialog
 */
int getOptionsForm(int purpose = OP_CONFIG, boolean embedded = true)
{
   // we are definitely calling this from an embedded form
   if (embedded) {
      return getOptionsFormFromEmbeddedDialog();
   } else {
      form := getOptionsFormName(purpose);
      return _find_formobj(form,'n');
   }
}

/**
 * Used to show options that correspond to the old Tools > 
 * Options > General form. 
 * 
 * @param _str tabNum         old tab number we want to visit
 */
void show_general_options(_str tabNum)
{
   switch(tabNum) {
   case 0:
      tabNum = 'Appearance > General';
      break;
   case 1:
      tabNum = 'Editing > Search';
      break;
   case 2:
      tabNum = 'Editing > Selections';
      break;
   case 3:
      tabNum = 'Appearance > Special Characters';
      break;
   case 4:
      tabNum = 'Appearance > General';
      break;
   case 5:
      tabNum = 'Application Options > Exit';
      break;
   case 6:
      tabNum = 'Application Options > Virtual Memory';
      break;
   }
   config(tabNum);
}

/**
 * The main form for the options dialog.
 */
defeventtab _options_tree_form;

/**
 * Check for Eclipse and maybe set the title differently. 
 */
void _options_tree_form.on_create()
{
   if (isEclipsePlugin()) {
      p_caption = "SlickEdit Preferences";
   }
   //_ctl_search.p_completion = OPTIONS_SEARCH_ARG;
   //_ctl_search.p_ListCompletions = true;
}

/**
 * Closes the options dialog.
 */
void _options_tree_form.on_destroy()
{
   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
   if (optionsTree != null) {
   
      if (!isOptionsOpen(_GetDialogInfoHt(PURPOSE))) {
         optionsTree -> cancel();
         optionsTree -> close();
      }
      optionsTree -> _makeempty();
      optionsTree = null;
   }

   int * timer = getOptionsSearchTimerPtr();
   if (_timer_is_valid(*timer)) {
      _kill_timer(*timer);
      *timer = -1;
   }

   timer = getOptionsDisplayTimerPtr();
   if (_timer_is_valid(*timer)) {
      _kill_timer(*timer);
      *timer = -1;
   }

   // save the last export group we worked with
   if (_ctl_export_groups.p_visible) {
      _append_retrieve(_ctl_export_groups, _ctl_export_groups.p_text, p_active_form.p_name'._ctl_export_groups');
   }
}

/**
 * If we are already showing favorites, shows the entire options
 * tree.  Otherwise, shows only the favorite nodes.
 */
void _ctl_show_favorites.lbutton_up()
{
   // clear the search
   clearSearch();

   // are we showing favorites or showing all
   if (areWeShowingFavorites()) {
      showAll();
   } else {
      showOnlyFavorites();
   }
}

void _options_tree_form.'A-LEFT', 'BACK-BUTTON-DOWN'()
{
   go_back_to_options_node();
}

/**
 * When called from a context menu from the Options tree, 
 * compiles the options path to the currently selected tree node 
 * and copies the path to the clipboard. 
 */
_command void copy_options_path() name_info(',')
{
   // we need to determine if the active form is an options form
   isOptions := (pos('_options:a+_tree_form', p_active_form.p_name, 1, 'R') != 1);

   // now get the tree
   if (isOptions) {
      path := '';

      // get our tree
      _control _ctl_tree;
      index := _ctl_tree._TreeCurIndex();

      // go through path and append captions
      while (index > 0) {
         caption := _ctl_tree._TreeGetCaption(index);
         caption = strip(caption, 'T', '*');
         caption = strip(caption);
         if (path != '') {
            path = caption' > 'path;
         } else path = caption;

         // get the parent
         index = _ctl_tree._TreeGetParentIndex(index);
      }

      // use the purpose to show the path
      purpose := _GetDialogInfoHt(PURPOSE);
      if (purpose == OP_QUICK_START) {
         path = 'Tools > Quick Start Configuration > 'path;
      } else {
         if (!isEclipsePlugin()) {
            path = 'Tools > Options > 'path;
         } else {
            path = 'Window > SlickEdit Preferences > 'path;
         }
      }

      // copy this mess
      push_clipboard(path);
      message(path' copied to clipboard');
   } 
}

/**
 * Command used by the options dialog to go back in the 
 * options history. 
 * 
 * @param _str caption        optional caption of node we want 
 *                            to see (if left blank, then just
 *                            go back once).
 */
_command void go_back_to_options_node(_str caption = '') name_info(',')
{
   // clear the search
   clearSearch();

   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
   optionsTree -> goBack(caption);
}

void _options_tree_form.'A-RIGHT', 'FORWARD-BUTTON-DOWN'()
{
   go_forward_to_options_node();
}

/**
 * Command used by the options dialog to go forward in the 
 * options history. 
 * 
 * @param _str caption        optional caption of node we want 
 *                            to see (if left blank, then just
 *                            go forward once).
 */
_command void go_forward_to_options_node(_str caption = '') name_info(',')
{
   // clear the search
   clearSearch();

   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
   optionsTree -> goForward(caption);
}

/**
 * Creates and displays a list of previously visited nodes by
 * their captions.
 */
static void nav_back_menu()
{
   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
   _str a[] = optionsTree -> getBackList();
   show_options_navigation_menu(a, 'go_back_to_options_node');
}

/**
 * Creates and displays a list of previously visited nodes by
 * their captions.
 */
static void nav_forward_menu()
{
   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
   _str a[] = optionsTree -> getForwardList();
   show_options_navigation_menu(a, 'go_forward_to_options_node');
}

/**
 * Displays a navigation menu listing a set of nodes that were 
 * previously visited.  Nodes are listed by caption, so user can 
 * select one of these entries and return to that node. 
 * 
 * @param _str[] a            list of entries in menu
 * @param _str command        command to be performed when 
 *                            selection is made
 * 
 */
static void show_options_navigation_menu(_str a[], _str command)
{
   // delete any previous incarnations of this menu
   index := find_index("_temp_options_nav_menu", oi2type(OI_MENU));
   if (index > 0) {
      delete_name(index);
   }

   index = insert_name("_temp_options_nav_menu", oi2type(OI_MENU));
   int i;
   for (i = 0; i < a._length(); ++i) {
      caption := a[i];
      if (caption == "") continue;
      _menu_insert(index, -1, 0, caption, command' 'caption);
   }

   // Show the menu
   menu_handle := p_active_form._menu_load(index, 'P');
   x := 100;
   y := 100;
   x = mou_last_x('M') - x;
   y = mou_last_y('M') - y;
   _lxy2dxy(p_scale_mode, x, y);
   _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   int status = _menu_show(menu_handle, VPM_LEFTALIGN | VPM_RIGHTBUTTON, x, y);
   _menu_destroy(menu_handle);

   // Delete temporary menu resource
   delete_name(index);
}

/**
 * Goes up oto the parent category in the options history.
 */
void _ctl_go_up.lbutton_up()
{
   // clear the search
   clearSearch();

   index := _ctl_tree._TreeCurIndex();
   index = _ctl_tree._TreeGetParentIndex(index);
   if (index > 0) {
      _ctl_tree._TreeSetCurIndex(index);
   }
}

/**
 * Goes back one entry in the options history.
 */
void _ctl_go_back.lbutton_up(int reason=0)
{
   if( reason == CHANGE_SPLIT_BUTTON ) {
      // Drop-down menu
      nav_back_menu();
      return;
   }

   // clear the search
   clearSearch();

   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
   optionsTree -> goBack();
}

/**
 * Goes forward one entry in the options history.
 */
void _ctl_go_forward.lbutton_up(int reason=0)
{
   if( reason == CHANGE_SPLIT_BUTTON ) {
      // Drop-down menu
      nav_forward_menu();
      return;
   }

   // clear the search
   clearSearch();

   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
   optionsTree -> goForward();
}

#define RESIZING _ctl_ok.p_user                 // whether we are currently resizing the options
#define HORZ_BORDER _ctl_cancel.p_user          // the size of the horizontal border of options form
#define VERT_BORDER _ctl_apply.p_user           // the size of the vertical border of options form

/**
 * Handles the resize of the form, which occurs when the form
 * embedded inside it needs a larger space than what was 
 * previously there or when the user resizes it manually.  Moves
 * other controls accordingly. 
 */
void _options_tree_form.on_resize()
{
   if (RESIZING) return;
   RESIZING = true;

   // available width and height
   width := p_width;
   height := p_height;

   // under normal circumstances, these should line up.
   widthDiff := width - (_ctl_frame.p_x + _ctl_frame.p_width + DEFAULT_DIALOG_BORDER);
   if (widthDiff) {
      _ctl_frame.p_width += widthDiff;
   }

   heightDiff := height - (_ctl_ok.p_y + _ctl_ok.p_height + DEFAULT_DIALOG_BORDER);
   if (heightDiff) {
      _ctl_frame.p_height += heightDiff;
   }

   if (widthDiff || heightDiff) {
      alignControlsToFrame();
      resizeFrameChild();
   }

   RESIZING = false;
}

/**
 * Add this in so that if the Dialog font is so big that the OK and Cancel 
 * buttons are off-screen, these actions still get done. 
 *  
 * 8.24.09 - sg 
 */
void _options_tree_form.ENTER()
{
   if (p_window_id.p_name == '_ctl_search') {
      /** 
       * If ENTER is pressed on the search box, we assume that the user has finished 
       * entering the search term and go ahead with our search (rather than waiting on
       * the timer).  Some users press enter on the search, not realizing that the 
       * search is incremental. 
       *  
       * We tried doing this is a _ctl_search.ENTER event handler, but this one was 
       * overriding it. 
       */
      search_options(_ctl_search.p_window_id);
   } else {
      call_event(_ctl_ok, LBUTTON_UP, 'W');
   }
}

void _options_tree_form.esc,A_F4,'M-F4',on_close()
{
   call_event(_ctl_cancel, LBUTTON_UP, 'W');
}

/**
 * Aligns the rest of the controls on the options dialog to
 * align with the frame (which has already been resized).
 */
void alignControlsToFrame()
{
   widthDiff := (_ctl_frame.p_x + _ctl_frame.p_width) - (_ctl_help.p_x + _ctl_help.p_width);
   heightDiff := (_ctl_frame.p_y + _ctl_frame.p_height + _ctl_help_label.p_height + DEFAULT_DIALOG_BORDER) - 
      (_ctl_tree.p_y + _ctl_tree.p_height);

   if (widthDiff || heightDiff) {
      _ctl_help.p_visible = _ctl_apply.p_visible = _ctl_cancel.p_visible = _ctl_ok.p_visible =
         _ctl_go_forward.p_visible = _ctl_go_back.p_visible = _ctl_go_up.p_visible =
         _ctl_help_label.p_visible = _ctl_tree.p_visible =
         _ctl_favorites.p_visible = _ctl_previous.p_visible = false;

      if (widthDiff) {
         _ctl_help.p_x += widthDiff;
         _ctl_apply.p_x += widthDiff;
         _ctl_cancel.p_x += widthDiff;
         _ctl_ok.p_x += widthDiff;
         _ctl_previous.p_x += widthDiff;
         _ctl_go_forward.p_x += widthDiff;
         _ctl_go_back.p_x += widthDiff;
         _ctl_go_up.p_x += widthDiff;
      
         _ctl_help_label.p_width += widthDiff;
      }
   
      if (heightDiff) {
         _ctl_tree.p_height += heightDiff;
         _ctl_help_label.p_y += heightDiff;
      
         _ctl_help.p_y += heightDiff;
         _ctl_apply.p_y += heightDiff;
         _ctl_cancel.p_y += heightDiff;
         _ctl_ok.p_y += heightDiff;
         _ctl_previous.p_y += heightDiff;
         _ctl_favorites.p_y += heightDiff;
      }

      _ctl_help.p_visible = _ctl_ok.p_visible = _ctl_cancel.p_visible = _ctl_help_label.p_visible = 
         _ctl_tree.p_visible = true;

      purpose := _GetDialogInfoHt(PURPOSE);
      _ctl_apply.p_visible = (purpose != OP_IMPORT);
      _ctl_favorites.p_visible = (purpose == OP_CONFIG);
      _ctl_previous.p_visible = (purpose == OP_QUICK_START);
      _ctl_go_forward.p_visible = _ctl_go_back.p_visible = _ctl_go_up.p_visible = (purpose != OP_QUICK_START);
   }
}

/**
 * Grabs the window id of the currently visible options panel 
 * (on the right side of the options dialog). 
 * 
 * @return window id of current options panel, -1 if none is 
 *         found
 */
static int getCurrentOptionsPanel()
{
   // find the frames visible child
   int wid, firstWid;
   wid = firstWid = _ctl_frame.p_child;
   for(;;) {
      if (!wid) return -1;
      if (wid.p_visible) break;

      wid = wid.p_next;
      if (wid == firstWid) return -1;
   }

   return wid;
}

/**
 * Resizes the panel inside the right side frame.
 */
void resizeFrameChild()
{
   wid := getCurrentOptionsPanel();
   if (wid < 0) return;

   wid.p_visible = false;

   width := _ctl_frame.p_width - (FRAME_PADDING * 2);
   height := _ctl_frame.p_height - (FRAME_PADDING * 2);

   if (wid) {
      if (width != wid.p_width) wid.p_width = width;
      if (height != wid.p_height) wid.p_height = height;
   }

   wid.refresh();
   wid.p_visible = true;
}

/**
 * Displays the context menu for the options tree.
 * 
 * @param int x         x position
 * @param int y         y position
 */
void _ctl_tree.rbutton_up(int x = -1, int y = -1)
{
   // find the menu
   menu_name := "_options_tree_menu";
   index := find_index(menu_name, oi2type(OI_MENU));
   if (index == 0) {
      return;
   }

   // try to load 'er up
   handle := p_active_form._menu_load(index, 'p');
   if(handle < 0) {
      msg := "Unable to load menu \"":+menu_name:+"\"";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   // see if we are currently selecting a node with children
   showChildren := 0;
   _ctl_tree._TreeGetInfo(_ctl_tree._TreeCurIndex(), showChildren);
   if (showChildren) {
      // no children - remove the expand all children option
      int menuHandle, itemPos;
      if (!_menu_find(handle, 'expand-options-children', menuHandle, itemPos, 'M')) {
         _menu_delete(handle, itemPos);
      }
   }

   // if we got no x and y, use some defaults
   if (x == y && x == -1) {
      x = mou_last_x('m') - VSDEFAULT_INITIAL_MENU_OFFSET_X; 
      y = mou_last_y('m') - VSDEFAULT_INITIAL_MENU_OFFSET_Y;
      _lxy2dxy(p_scale_mode, x, y);
      _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   }

   // show the menu already
   int flags = VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   _menu_show(handle, flags, x, y);
   _menu_destroy(handle);
}

void _ctl_tree.ENTER()
{
   call_event(p_active_form, ENTER, 'W');
}

static void callBaseEvent(_str event)
{
   call_event(defeventtab _ainh_dlg_manager, event, 'E');
}

static void setFocusOnCurrentOptionsPanel()
{
   rightPanel := getCurrentOptionsPanel();
   if (rightPanel.p_child) {
      rightPanel.p_child._set_focus();
   } else {
      rightPanel._set_focus();
   }
}

// these events handle tabbing through the options dialog, including tabbing into
// the hosted forms embedded in the right panel
// depending on the usage of the options dialog form, different controls are
// before/after the embedded form in the tab order
void _ctl_favorites.'TAB'()
{
   _ctl_ok._set_focus();
   setFocusOnCurrentOptionsPanel();
}

void _ctl_tree.'TAB'()
{
   purpose := _GetDialogInfoHt(PURPOSE);
   if (purpose == OP_CONFIG) {
      callBaseEvent(TAB);
   } else {
//    _ctl_ok._set_focus();
      setFocusOnCurrentOptionsPanel();
   }
}

void _ctl_ok.'S-TAB'()
{
   purpose := _GetDialogInfoHt(PURPOSE);
   if (purpose != OP_QUICK_START || !_ctl_previous.p_enabled) {
      setFocusOnCurrentOptionsPanel();
   } else {
      callBaseEvent(S_TAB);
   }
}

void _ctl_previous.'S-TAB'()
{
   setFocusOnCurrentOptionsPanel();
}

static void adjustNavigationButtons()
{
   // get the width and height of the icon buttons
   _ctl_go_forward.p_auto_size = _ctl_go_back.p_auto_size = _ctl_go_up.p_auto_size = true;

   // adjust x positioning
   x := _ctl_frame.p_x + _ctl_frame.p_width;
   x -= _ctl_go_forward.p_width;
   _ctl_go_forward.p_x = x;
   x -= _ctl_go_back.p_width;
   _ctl_go_back.p_x = x;
   x -= _ctl_go_up.p_width;
   _ctl_go_up.p_x = x;

   // figure out the tallest button - on some platforms
   // they are not all the same
   h := max(_ctl_go_forward.p_height, _ctl_go_back.p_height);
   h = max(h, _ctl_go_up.p_height);

   _ctl_go_forward.p_auto_size = _ctl_go_back.p_auto_size = _ctl_go_up.p_auto_size = false;
   _ctl_go_forward.p_height = _ctl_go_back.p_height = _ctl_go_up.p_height = h;

   // adjust frame position
   _ctl_frame.p_height -= (_ctl_go_back.p_y+h - _ctl_frame.p_y);
   _ctl_frame.p_y = _ctl_go_back.p_y+h;
}

/** 
 * Initializes the _options_tree_form by building the tree based 
 * on XML.   
 */
void _ctl_tree.on_create(int purpose = OP_CONFIG, _str nodeOrGroup = '', boolean restoreLast = true, boolean protect = false, _str arguments = '')
{
   RESIZING = false;

   // set up timers
   _SetDialogInfoHt(SEARCH_TIMER, -1);
   _SetDialogInfoHt(DISPLAY_TIMER, -1);
   _SetDialogInfoHt(CAUSED_TREE_CHANGE, _ctl_tree);
   _SetDialogInfoHt(PURPOSE, purpose);

   // this is kinda kooky - we change the form name to suit the purpose
   p_active_form.p_name = getOptionsFormName(purpose);
   
   // save border sizes for use in resizing
   HORZ_BORDER = p_active_form.p_width - _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   VERT_BORDER = p_active_form.p_height - _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);

   // adjust button heights for different icon sizes
   adjustNavigationButtons();

   // clear tree
   _ctl_tree._TreeDelete(TREE_ROOT_INDEX, 'C');

   // do a little magic on the help blurb to make it look good
   _ctl_help_label._minihtml_UseDialogFont();
   _ctl_help_label.p_backcolor = 0x80000022;

   // this is our first time
   _SetDialogInfoHt(FIRST_TIME, true);
   
   file := '';                       
   if (purpose == OP_CONFIG) {
      if (nodeOrGroup == '' && restoreLast) {
         nodeOrGroup = _ctl_tree._retrieve_value();
      }

      se.options.OptionsConfigTree temp;
      _SetDialogInfoHt(OPTIONS, temp);

      _ctl_previous.p_visible = false;
      hideExportGroups();

   } else if (purpose == OP_IMPORT) {
      se.options.OptionsImportTree temp;
      _SetDialogInfoHt(OPTIONS, temp);

      // we want our initial path to be in the parent of the config dir
      path := _ConfigPath();
      path = substr(path, 1, length(path) - 1);
      path = _strip_filename(path, 'N');

      // prompt for the path to save the export package
      format_list := 'SlickEdit Export Files(*.zip),All Files('ALLFILES_RE')';

      version := _version();
      parse version with version'.' .;

      zipFile := '';
      if (isEclipsePlugin()) {
          zipFile = COREOPTIONSFILE'.zip';
      } else {
          zipFile = OPTIONSFILE :+ version'.zip';
      }

      wid := p_window_id;
      zipFile = _OpenDialog('-new -mdi -modal',
                            'Open export package',
                            '',     // Initial wildcards
                            format_list,  // file types
                            OFN_FILEMUSTEXIST,
                            ".zip",  // Default extensions
                            zipFile, // Initial filename
                            path,    // Initial directory
                            '',      // Reserved
                            "Standard Open dialog box"
                            );

      // restore focus to where it was before
      p_window_id = wid;

      if (zipFile == '') {
         p_active_form._delete_window();
         return;
      }
      file = strip(zipFile, 'B', '"');

      // do some gui stuff to make the dialog look right
      _ctl_previous.p_visible = false;
      _ctl_apply.p_visible = false;
      _ctl_ok.p_caption = '&Import';
      _ctl_ok.p_x = _ctl_cancel.p_x;
      _ctl_cancel.p_x = _ctl_apply.p_x;

      hideExportGroups();
      hideFavoritesAndSearch();
   } else if (purpose == OP_EXPORT) {
      se.options.OptionsExportTree temp;
      _SetDialogInfoHt(OPTIONS, temp);
      _SetDialogInfoHt(PROTECT, protect);

      ctllabel1.p_caption = 'Export Group:';
      _ctl_export_groups.p_x = _ctl_search.p_x;
      _ctl_export_groups.p_y = _ctl_search.p_y;
      _ctl_new_export_group.p_x = _ctl_clear_search.p_x;
      _ctl_new_export_group.p_y = _ctl_clear_search.p_y;

      _ctl_ok.p_caption = '&Export';
      _ctl_apply.p_caption = '&Save';

      hideFavoritesAndSearch(_ctl_search_descriptions.p_y);
      _ctl_previous.p_visible = false;
   } else if (purpose == OP_QUICK_START) {
      se.options.OptionsConfigTree temp;
      _SetDialogInfoHt(OPTIONS, temp);

      _ctl_ok.p_caption = '&Next';
      _ctl_apply.p_caption = '&Finish';
      _ctl_previous.p_enabled = false;
      
      // get xml file sysconfig/options directory
      file = get_env('VSROOT')'sysconfig'FILESEP'options'FILESEP'quickStartConfig.xml';
      hideFavoritesAndSearch();
      hideExportGroups();
      hideNavigationButtons();

      p_active_form.p_caption = 'Quick Start Configuration Wizard';
   }

   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
   if (optionsTree -> init(_ctl_tree.p_window_id, _ctl_frame.p_window_id, _ctl_help_label.p_window_id, file)) {
   
      if (purpose == OP_EXPORT) initExportGroupsComboBox(nodeOrGroup);
      else if (purpose == OP_IMPORT) {
         se.options.OptionsImportTree * optionsImportTree = _GetDialogInfoHtPtr(OPTIONS);
         protect = optionsImportTree -> areAnyImportedItemsProtected();
         _SetDialogInfoHt(PROTECT, protect);
      }
   
      if (purpose == OP_CONFIG && nodeOrGroup != '') {
         optionsTree -> showNode(nodeOrGroup, false, ISEB_SELECT_TOP, arguments);
      } else {
         if (_ctl_tree._TreeCurIndex() == 0) {
            index := _ctl_tree._TreeGetFirstChildIndex(0);
            optionsTree -> goToTreeNode(index);
         }
      }
      updateShowFavoritesButton();
   } else {
      p_active_form._delete_window();
   }
}

void hideExportGroups()
{
   _ctl_export_groups.p_visible = false;
   _ctl_new_export_group.p_visible = false;
}

void hideFavoritesAndSearch(int treeY = -1)
{
   if (treeY == -1) treeY = _ctl_frame.p_y;
   
   _ctl_show_favorites.p_visible = _ctl_favorites.p_visible = false;
   _ctl_search.p_visible = false;
   ctllabel1.p_visible = false;
   _ctl_clear_search.p_visible = false;
   _ctl_search_descriptions.p_visible = false;

   _ctl_tree.p_y = treeY;
   _ctl_tree.p_height = (_ctl_help_label.p_y + _ctl_help_label.p_height) - _ctl_tree.p_y;
}

void hideNavigationButtons()
{
   _ctl_go_up.p_visible = _ctl_go_back.p_visible = _ctl_go_forward.p_visible = false;
}

void initExportGroupsComboBox(_str selGroup)
{
   if (!_ctl_export_groups.p_visible) return;

   se.options.OptionsExportTree * optionsExportTree = _GetDialogInfoHtPtr(OPTIONS);
   _str list[];
   optionsExportTree -> getExportGroupNames(list);
   foreach (auto groupName in list) {
      _ctl_export_groups._lbadd_item(groupName);
   }

   if (selGroup == '') {
      selGroup = _retrieve_value(p_active_form.p_name'._ctl_export_groups');
   }

   // select the one we want
   _ctl_export_groups._lbfind_and_select_item(selGroup, '', true);
}

void _ctl_export_groups.on_change(int reason)
{
   se.options.OptionsExportTree * optionsExportTree = _GetDialogInfoHtPtr(OPTIONS);
   optionsExportTree -> showExportGroup(_ctl_export_groups.p_text);
}

/** 
 * Handles tree change event, specifically when a node is 
 * expanded and when a node is selected.  All other change 
 * events are ignored. 
 * 
 * @param reason     reason for change
 */
void _ctl_tree.on_change(int reason, int treeIndex=0)
{
   switch (reason) {
   case CHANGE_EXPANDED:
      // check to see if children have already been added
      if (!_ctl_tree._TreeDoesItemHaveChildren(treeIndex)) {
         se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
         optionsTree -> expandTreeNode(treeIndex);
      } 
      break;
   case CHANGE_SELECTED:
      if (treeIndex <= 0) return;
      
      // do we delay the viewing of the right panel?  sometimes...
      se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
      if (optionsTree -> isOptionsChangeDelayed()) {

         int * timer = getOptionsDisplayTimerPtr();
         if (_timer_is_valid(*timer)) {
            _kill_timer(*timer);
            *timer = -1;
         }

         changeWid := getOptionsTreeChangeCause();

         *timer = _set_timer(150, find_index('showOptionsPanel', PROC_TYPE), p_active_form' 'changeWid);

         // reset the change wid to the tree
         setOptionsTreeChangeCause(_ctl_tree);
      } else {
         // no!  show it now!
         optionsTree -> resetOptionsChangeDelay();
         showOptionsPanel(p_active_form);
      }
      break;
   case CHANGE_CHECK_TOGGLED:
      purpose := _GetDialogInfoHt(PURPOSE);
      if (purpose == OP_IMPORT || purpose == OP_EXPORT) {

         if (treeIndex > 0) {
            se.options.OptionsCheckboxTree * cbTree =_GetDialogInfoHtPtr(CHECKBOXTREE, p_window_id, true);
            if (cbTree != null) {
               cbTree -> onCheckChangedEvent(treeIndex);
            }
         }
      }
      break;
   }
}

/**
 * Shows the current panel for the selected tree index.  Is 
 * frequently used as a callback for a timer so that panels are 
 * delayed in displaying. 
 * 
 * @param index         current tree index
 */
void showOptionsPanel(_str info)
{
   typeless optionsWid, focusControl;
   parse info with optionsWid focusControl;

   origWid := p_window_id;
   if (optionsWid > 0) {

      p_window_id = optionsWid._ctl_tree.p_window_id;
      index := _TreeCurIndex();

      int * timer = getOptionsDisplayTimerPtr();
      if (_timer_is_valid(*timer)) {
         _kill_timer(*timer);
         *timer = -1;
      }

      se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS, optionsWid);
      optionsTree -> goToTreeNode(index);
   
      updateFavoriteButton(index);
      updateNavigationButtons();
      updateNextPreviousButtons(index);
      //updateApplyButton();

      // is this our first time?  we want the search box to be selected
      if (_GetDialogInfoHt(FIRST_TIME, optionsWid)) {
         p_window_id = optionsWid;
         _SetDialogInfoHt(FIRST_TIME, false);
         if (_ctl_search.p_visible) _ctl_search._set_focus();
         
      } else {
         p_window_id = origWid;
         if (focusControl > 0) {
            focusControl._set_focus();
         }
      }

   }
}

/**
 * Updates the enabled status of the options navigator buttons
 * depending on where the user sits in the options navigator
 * history.
 */
void updateNavigationButtons()
{
   if (!_ctl_go_back.p_visible) return;

   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
   _ctl_go_back.p_enabled = optionsTree -> canGoBack();
   _ctl_go_forward.p_enabled = optionsTree -> canGoForward();
   _ctl_go_up.p_enabled = _ctl_tree._TreeGetDepth(_ctl_tree._TreeCurIndex()) > 1;
}

void updateNextPreviousButtons(int curIndex)
{
   if (!_ctl_previous.p_visible) return;

   // we assume that there is only one level, since this is only used on the quick start
   _ctl_previous.p_enabled = (_ctl_tree._TreeGetPrevSiblingIndex(curIndex) != -1);
   _ctl_ok.p_enabled = (_ctl_tree._TreeGetNextSiblingIndex(curIndex) != -1);
}

/**
 * Updates the text of the favorite button depending on the 
 * current node.  If node is already a favorite, button will say 
 * 'Remove [caption] from Favorites'.  Otherwise, button will
 * say 'Add [caption] to Favorites'. 
 * 
 * @param int treeIndex       currently selected tree index
 */
void updateFavoriteButton(int treeIndex)
{
   if (!_ctl_favorites.p_visible) return;

   caption := _ctl_tree._TreeGetCaption(treeIndex);
   caption = stranslate(caption, '', '*');
   caption = stranslate(caption, '&&', '&');

   se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS);
   if (optionsConfigTree -> isNodeFavorited(treeIndex)) {
      _ctl_favorites.p_caption = 'Remove 'caption' from &Favorites';
   } else {
      _ctl_favorites.p_caption = 'Add 'caption' to &Favorites';
   }

   textSize := _text_width(_ctl_favorites.p_caption);
   // check if text is too large for button
   if (textSize + 100 > _ctl_favorites.p_width) {
      _ctl_favorites.p_width = textSize + 100;
   } else {
      // our target size for this button
      targetSize := _ctl_tree.p_width;
      if (_ctl_favorites.p_width != targetSize && textSize < targetSize - 100) {
         _ctl_favorites.p_width = targetSize;
      }
   }
}

/**
 * Enables or disables the apply button based on whether there
 * are any un-applied changes.
 */
void updateApplyButton()
{
   purpose := _GetDialogInfoHt(PURPOSE);
   if (purpose == OP_CONFIG) {
      se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS);
      //_ctl_apply.p_enabled = optionsConfigTree -> areOptionsModified(false, false);
      _ctl_apply.p_enabled = true;
   }
}

/**
 * Updates whether the 'Show Favorites' button is enabled 
 * or disabled based on whether the options dialog contains 
 * favorites. 
 */
void updateShowFavoritesButton()
{
   if (!_ctl_show_favorites.p_visible) return;

   se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS);
   _ctl_show_favorites.p_enabled = optionsConfigTree -> doWeHaveAnyFavorites();
}

/**
 * Adds or removes currently selected node in tree from the list
 * of favorites.
 */
void _ctl_favorites.lbutton_up()
{
   se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS);
   if (pos('Add', _ctl_favorites.p_caption)) {
      optionsConfigTree -> addFavoriteNode();

      // if we're looking at favorites, refresh them
      if (areWeShowingFavorites()) {
         optionsConfigTree -> showOnlyFavorites();
      }
   } else {
      optionsConfigTree -> removeFavoriteNode();

      // if we're looking at favorites, refresh them
      if (areWeShowingFavorites()) {
         // if we are out of favorites, we gotta show all
         if (optionsConfigTree -> doWeHaveAnyFavorites()) {
            optionsConfigTree -> showOnlyFavorites();
         } else {
            _ctl_show_favorites.call_event(_ctl_show_favorites, LBUTTON_UP);
         }
      }
   }
   updateFavoriteButton(_ctl_tree._TreeCurIndex());
   updateShowFavoritesButton();
}

/** 
 * Applies all changes made to the options.
 */
void _ctl_apply.lbutton_up()
{
   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
   optionsTree -> apply();

   // this is the FINISH button for quick start, so we need to close
   purpose := _GetDialogInfoHt(PURPOSE);
   if (purpose == OP_QUICK_START) {
      p_active_form._delete_window();
   }
}

void _options_tree_form.f1() 
{
   // we need to query the options to find out what our current p_help tag is
   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);

   helpstr := optionsTree -> getCurrentSystemHelp();
   // Be sure to allow helpID:helpFilename.  Some OEMs are using this
   parse helpstr with auto helpID ':' auto helpFilename;

   help(helpID,helpFilename);
}
/**
 * User needs help!
 */
void _ctl_help.lbutton_up()
{
   // we need to query the options to find out what our current p_help tag is
   se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
   helpstr := optionsTree -> getCurrentSystemHelp();
   // Be sure to allow helpID:helpFilename.  Some OEMs are using this
   parse helpstr with auto helpID ':' auto helpFilename;

   help(helpID, helpFilename);
}

/**
 * Catch the ALT-<letter> events.  If they cannot be performed 
 * for the options dialog itself, then pass the event along to 
 * the right panel containing the options. 
 * 
 */
void _options_tree_form.A_A-A_Z,A_0-A_9,'M-A'-'M-Z'()
{
   typeless event = last_event();
   typeless id = '';
   parse event2name(event) with '[AM]-','r' id;

   do {
      // try to perform the event on the options dialog itself
      typeless status = _dmDoLetter(id);
      if (!status) break;

      // that didn't work - try it on the frame child
      rightPanel := getCurrentOptionsPanel();
      status = rightPanel._dmDoLetter(id);
      if (!status) break;

      // one more thing - if we have Alt-O, we just send it to the Options panel
      if (upcase(id) == 'O') rightPanel._set_focus();

   } while (false);
}

static boolean areWeSearching()
{
   return (_ctl_search.p_text != '');
}

/** 
 * Initiates a search using the search term entered.  Search is 
 * incremental.
 */
void _ctl_search.on_change()
{
   if (_ctl_search.p_text != '') {
      int * timer = getOptionsSearchTimerPtr();
      if (_timer_is_valid(*timer)) {
         _kill_timer(*timer);
         *timer = -1;
      }
   
      cbIndex := find_index('search_options', PROC_TYPE);
   
      // how long is the timer?
      timerLength := 200;
      if (length(_ctl_search.p_text) < 3) {
         // for short strings, give a little more time to type
         // short strings return so many results
         timerLength = 500;
      }
   
      *timer = _set_timer(timerLength, cbIndex, _ctl_search.p_window_id);
   } else {
      search_options(_ctl_search.p_window_id);
   }
}

/**
 * Searches the options for the search term specified in the 
 * search text box. 
 * 
 * @param int searchID        window id of search text box.
 */
void search_options(int searchID)
{
   p_window_id = searchID.p_parent;

   // search is on a timer - KILL IT!
   int * timer = getOptionsSearchTimerPtr();
   if (_timer_is_valid(*timer)) {
      _kill_timer(*timer);
      *timer = -1;
   }

   // if we are looking only at favorites, clear them and show all before we search
   if (_ctl_search.p_text != '' && areWeShowingFavorites()) {
      showAll();
   }

   searchOptions := '';
   if (_ctl_search_descriptions.p_value) {
      searchOptions = 'D';
   }

   se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS);
   optionsConfigTree -> searchOptions(searchID.p_text, searchOptions);

   // make sure we keep focus here in case user is still typing word
   searchID._set_focus();
}

/**
 * Handles 'Clear Search' button by, surprisingly enough,
 * clearing the search.
 */
void _ctl_clear_search.lbutton_up()
{
   clearSearch();
   se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS);
   optionsConfigTree -> clearSearch();
}

/**
 * Handles the 'Search descriptions' checkbox by immediately doing a search with 
 * the new option turned to the new value. 
 */
void _ctl_search_descriptions.lbutton_up()
{
   if (_ctl_search.p_text != '') {
      search_options(_ctl_search.p_window_id);
   } 
}

void _ctl_new_export_group.lbutton_up()
{
   // get the new name and possible source export group
   se.options.OptionsExportTree * optionsExportTree = _GetDialogInfoHtPtr(OPTIONS);
   _str list[];
   optionsExportTree -> getExportGroupNames(list);
   result := show('-mdi -modal _new_export_group_form', list); 

   if (result == IDOK) {
      // create it
      groupName := _param1;
      copyFromGroupName := _param2;
      optionsExportTree -> createNewExportGroup(groupName, copyFromGroupName);
   
      // now select the new group
      _ctl_export_groups._lbadd_item(groupName);
      _ctl_export_groups._lbfind_and_select_item(groupName);
      call_event(CHANGE_OTHER, _ctl_export_groups, ON_CHANGE, "W");
   }
}

/** 
 * Checks for changes which have not been applied and applies
 * them.  Closes form.
 */
void _ctl_ok.lbutton_up()
{
   purpose := _GetDialogInfoHt(PURPOSE);

   if (purpose == OP_CONFIG) {
      se.options.OptionsConfigTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
      if (optionsTree -> apply()) {
         _ctl_tree.saveOptionsTreeLocation(optionsTree);
         optionsTree -> close();
      } else return;
   } else if (purpose == OP_IMPORT) {
      se.options.OptionsImportTree * optionsImportTree = _GetDialogInfoHtPtr(OPTIONS);
      if (optionsImportTree -> apply()) {
         optionsImportTree -> close();
      } else return;
   } else if (purpose == OP_EXPORT) {
      // save our changes
      se.options.OptionsExportTree * optionsExportTree = _GetDialogInfoHtPtr(OPTIONS);
      if (optionsExportTree -> apply()) {
         // now we do the export
         group := _ctl_export_groups._lbget_text();
         protect := _GetDialogInfoHt(PROTECT);
         boolean table:[];
         table:[group] = protect && optionsExportTree -> doesGroupHaveProtections();
         result := show('-mdi -modal _export_options_form', table, protect);
         if (result == IDOK) {
   
            package := _param1;
            protectionCode := _param2;
   
            optionsExportTree -> export(package, protectionCode, group);
            
            optionsExportTree -> close();
         } else return;
      } else return;
   } else if (purpose == OP_QUICK_START) {
      // get the current tree index
      curIndex := _ctl_tree._TreeCurIndex();

      setOptionsTreeChangeCause(_ctl_ok);
      _ctl_tree._TreeDown();
      return;
   }

   p_active_form._delete_window();
}

void saveOptionsTreeLocation(OptionsTree * optionsTree) 
{
   index :=_ctl_tree._TreeCurIndex();
   if (index < 0) return;
  
   captionPath := optionsTree -> getTreeNodePath(index);
   if (!pos('Search Results', captionPath)) {
      _append_retrieve(0, captionPath, p_active_form.p_name'.'p_name);
   }
}

/** 
 * Closes options dialog.  If changes have been made, but not 
 * applied, user is prompted to apply or throw away these 
 * changes. 
 */
void _ctl_cancel.lbutton_up(boolean cancelButton = true)
{
   purpose := _GetDialogInfoHt(PURPOSE);
   if (purpose == OP_CONFIG || purpose == OP_QUICK_START) {
      se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS);
      if (optionsConfigTree -> areOptionsModified(true, true)) {

          status := _message_box("Changes have been made but not applied.", "SlickEdit Options", MB_APPLYDISCARDCANCEL, IDAPPLY);
          switch(status) {
          case IDAPPLY:
              if (!optionsConfigTree -> apply()) return;
              break;
          case IDDISCARD:
              optionsConfigTree -> cancel();
              break;
          case IDCANCEL:
              return;
              break;
          default:
              break;
         }

      }
      _ctl_tree.saveOptionsTreeLocation(optionsConfigTree);
      optionsConfigTree -> close();
   } else {
      se.options.OptionsTree * optionsTree = _GetDialogInfoHtPtr(OPTIONS);
      optionsTree -> cancel();
      optionsTree -> close();
   }
   p_active_form._delete_window();
}

void _ctl_previous.lbutton_up()
{
   purpose := _GetDialogInfoHt(PURPOSE);
   // this should really only be active for quick start...
   if (purpose == OP_QUICK_START) {
      // get the current tree index
      curIndex := _ctl_tree._TreeCurIndex();
      setOptionsTreeChangeCause(_ctl_previous);
      _ctl_tree._TreeUp();
   }
}

/**
 * Refreshes the tree to show all options nodes.
 */
void showAll()
{
   _ctl_show_favorites.p_caption = '&Show Favorites';
   se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS);
   optionsConfigTree -> showAll();
}

/**
 * Prunes the options tree down to just nodes which have been
 * designated as favorites.
 */
void showOnlyFavorites()
{
   _ctl_show_favorites.p_caption = '&Show All';
   se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS);
   optionsConfigTree -> showOnlyFavorites();
}

/**
 * Clears the options search.
 */
void clearSearch()
{
   // clear the search
   if (_ctl_search.p_text != '') {
      _ctl_search.p_text = '';
      _ctl_search._begin_line();
   }
}

/**
 * Performs an immediate options search.
 * 
 * @param searchString 
 */
void doSearch(_str searchString)
{
   _ctl_search.p_text = searchString;
}

/**
 * Determines whether the tree is currently 'pruned' down to 
 * just the favorites nodes or is showing all nodes. 
 * 
 * @return boolean      true if showing only favorites, false if 
 *                      showing all nodes
 */
boolean areWeShowingFavorites()
{
   // button will say 'Show Favorites' if we are showing all
   return (pos('Favorites', _ctl_show_favorites.p_caption) == 0);
}

/**
 * Search options categories for categories that match the 
 * string in 'name' 
 * 
 * @param name          name to match
 * @param find_first    'true' to find first, 'false' to find next
 * 
 * @return <code>name</code> if <code>find_first</code> is true, '' otherwise.
 * 
 * @categories Completion_Functions
 */
_str options_match(_str name,boolean find_first)
{
   static _str matches[];
   static int next_i;

   if ( find_first ) {

      searchOptions := '';
      origWid := p_window_id;
      formWid := getOptionsForm(OP_CONFIG,false);
      if (formWid == 0) {
         return('');
      }
      p_window_id = formWid._ctl_search.p_parent;
      if (formWid._ctl_search_descriptions.p_value) {
         searchOptions = 'D';
      }

      matches._makeempty();
      next_i = 0;
      se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS, formWid);
      if (optionsConfigTree != null) {
         optionsConfigTree->searchOptions(name,searchOptions);
         optionsConfigTree->buildSearchNodeList(matches);
      }
      p_window_id = origWid;
   }

   if (next_i < matches._length()) {
      return matches[next_i++];
   }

   return('');

}

/**
 * This form displays a list of all the changes the user has 
 * made to his/her options.  Can be filtered by a time range to 
 * narrow down the list. 
 */
defeventtab _options_history_form;

#region Options Dialog Helper Functions

/**
 * Performs the first search by changing the filter.
 */
void _options_history_form_init_for_options()
{
   _ctl_filter._lbfind_and_select_item('Anytime');
}

/**
 * This form is never modified.
 * 
 * @return boolean 
 */
boolean _options_history_form_is_modified()
{
   return false;
}

/**
 * Re-selects filter again so that the search will be performed
 * again, thus refreshing results.
 */
void _options_history_form_restore_state()
{
   // resize appropriately
   width := p_parent.p_width;
   if (p_width < width - (FRAME_PADDING * 2)) {
      p_width = width - (FRAME_PADDING * 2);
   }

   // grab history again in case it changed
   _ctl_filter._lbfind_and_select_item(_ctl_filter.p_text);
}

#endregion Options Dialog Helper Functions

/**
 * Catches filter combo box event.  Takes the selection and
 * populates the history tree accordingly.
 */
void _ctl_filter.on_change(int reason)
{   
   changeFlags := 0;
   switch (_ctl_filter.p_text) {
   case 'Anytime':
      changeFlags = DC_EVER;
      break;
   case 'Today':
      changeFlags = DC_TODAY;
      break;
   case 'Yesterday':
      changeFlags = DC_YESTERDAY;
      break;
   case 'Within the last week':
      changeFlags = DC_WITHIN_LAST_WEEK;
      break;
   case 'Within the last month':
      changeFlags = DC_WITHIN_LAST_MONTH;
      break;
   }
   if (changeFlags) {
      populate_history(changeFlags);
   }
}

/**
 * Creates history form.  Initializes tree and combo box.
 */
void _ctl_history_tree.on_create()
{
   if (isEclipsePlugin()) {
       _ctl_history_tree._TreeSetColButtonInfo(0, 2500, TREE_BUTTON_SORT | TREE_BUTTON_PUSHBUTTON, -1, 'Preference');
   } else {
       _ctl_history_tree._TreeSetColButtonInfo(0, 2500, TREE_BUTTON_SORT | TREE_BUTTON_PUSHBUTTON, -1, 'Option');
   }
   _ctl_history_tree._TreeSetColButtonInfo(1, 2000, TREE_BUTTON_SORT | TREE_BUTTON_PUSHBUTTON, -1, 'Path');
   _ctl_history_tree._TreeSetColButtonInfo(2, 1000, TREE_BUTTON_SORT_DATE | TREE_BUTTON_SORT_TIME | TREE_BUTTON_PUSHBUTTON, -1, 'Date Changed');
   _ctl_history_tree._TreeSetColButtonInfo(3, 1000, TREE_BUTTON_SORT | TREE_BUTTON_PUSHBUTTON, -1, 'Method');

   _ctl_filter._lbadd_item('Anytime');
   _ctl_filter._lbadd_item('Today');
   _ctl_filter._lbadd_item('Yesterday');
   _ctl_filter._lbadd_item('Within the last week');
   _ctl_filter._lbadd_item('Within the last month');
}

/**
 * Resize event for history form.  Handles resizing of columns
 * to keep them proportional.
 */
void _options_history_form.on_resize()
{
   double ratios[];
   save_column_width_ratios(_ctl_history_tree.p_window_id, ratios);

   _ctl_history_tree.p_visible = _lbl_results.p_visible = false;

   // fix height
   heightDiff := p_height - (DEFAULT_DIALOG_BORDER * 2) - (_ctl_history_tree.p_y + _ctl_history_tree.p_height);
   _ctl_history_tree.p_height += heightDiff;

   // change width
   width := p_width - (DEFAULT_DIALOG_BORDER * 2);
   _ctl_history_tree.p_width = width;

   // align label
   _lbl_results.p_width = ((_ctl_history_tree.p_x + width) - _lbl_results.p_x);

   restore_column_width_ratios(_ctl_history_tree.p_window_id, ratios);

   _ctl_history_tree.p_visible = _lbl_results.p_visible = true;
}

/**
 * Saves the ratios of column width to total tree width of each 
 * column in a tree. 
 * 
 * @param int tree                        window id of tree
 * @param double(&ratios)[] ratios        array of ratios
 * 
 */
void save_column_width_ratios(int tree, double (&ratios)[])
{
   numCols := tree._TreeGetNumColButtons();
   width := tree.p_width;

   int i, colWidth, flags, state, caption;
   for (i = 0; i < numCols; i++) {
      tree._TreeGetColButtonInfo(i, colWidth, flags, state, caption);
      ratios[i] = ((double)colWidth / (double)width);
   }
}

/**
 * Restores the relative column widths in a tree based on an 
 * array of ratios. 
 * 
 * @param int tree               window id of tree
 * @param double[] ratios        array of ratios to restore
 * 
 */
void restore_column_width_ratios(int tree, double ratios[])
{
   numCols := tree._TreeGetNumColButtons();
   width := tree.p_width;

   int i;
   for (i = 0; i < numCols; i++) {
      colWidth := (int)(ratios[i] * width);
      tree._TreeSetColButtonInfo(i, colWidth);
   }
}

/**
 * When a history entry is selected, that entry is shown in the
 * options tree.
 */
void _ctl_history_tree.' ', lbutton_double_click()
{
   caption := _ctl_history_tree._TreeGetCurCaption();
   if (caption != null) {
      _str a[];
      split(caption, \t, a);

      se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS, getOptionsForm());
      if (a._length() > 1) {
         optionsConfigTree -> showSearchNode(a[1], a[0]);
      } else {
         optionsConfigTree -> showSearchNode('', a[0]);
      }
   }
}  

/**
 * Throws the ENTER event to the parent form, which will cause 
 * the options dialog to close. 
 */
void _ctl_history_tree.ENTER()
{
   call_event(p_parent, ENTER);
}

/**
 * Populates the history tree with the options change history.
 * 
 * @param _str[] a 
 */
void populate_history(int changeFlag)
{
   se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS, getOptionsForm());
   _str history[]; 
   optionsConfigTree -> buildRecentlyChangedList(changeFlag, history);

   // update label
   results := history._length();
   if (results == 0) {
      _lbl_results.p_caption = 'No results found';
   } else if (results == 1) {
      _lbl_results.p_caption = '1 result found';
   } else {
      _lbl_results.p_caption = results' results found';
   }

   // update tree
   _ctl_history_tree._TreeBeginUpdate(TREE_ROOT_INDEX);

   _str item, date;
   int y, m, d, h, min, s, ms;
   foreach (item in history) {
      index := _ctl_history_tree._TreeAddItem(TREE_ROOT_INDEX, item, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      parse item with . \t . \t date \t . ;
      DateTime dt = DateTime.fromTimeF(date);
      dt.toParts(y, m, d, h, min, s, ms);
      _ctl_history_tree._TreeSetDateTime(index, 2, y, m, d, h, min, s, ms);
   }

   // figure out which column was being sorted...
   _ctl_history_tree._TreeSortCol(getCurrentSortColumn(_ctl_history_tree, 2));

   _ctl_history_tree._TreeEndUpdate(TREE_ROOT_INDEX);
   _ctl_history_tree._TreeRefresh();
}

/**
 * Retrieves the currently sorted column of the given tree.  If 
 * none is found, the default is returned. 
 * 
 * @param tree                handle to tree
 * @param defaultSortCol      default return value 
 * 
 * @return 
 */
int getCurrentSortColumn(int tree, int defaultSortCol)
{
   numCols := tree._TreeGetNumColButtons();
   int i, width, flags, state;
   _str caption;
   for (i = 0; i < numCols; i++) {
      tree._TreeGetColButtonInfo(i, width, flags, state, caption);
      if (flags & TREE_BUTTON_PUSHED) return i;
   }

   return defaultSortCol;
}

/**
 * This form appears in the options dialog whenever a Category 
 * node is selected.  Displays information about the selected 
 * category. 
 */
defeventtab _options_category_help_form;

/**
 * Resizes the help text.
 */
void _options_category_help_form.on_resize()
{
   _ctl_html_help.p_visible = false;
   _ctl_html_help.p_width = p_width - (DEFAULT_DIALOG_BORDER * 2);
   _ctl_html_help.p_height = p_height - (DEFAULT_DIALOG_BORDER * 2);

   _ctl_html_help._minihtml_ShrinkToFit();
   _ctl_html_help.p_visible = true;
}

/**
 * Sets the help text.
 * 
 * @param _str help 
 */
void _ctl_html_help.on_create(_str help)
{
   _ctl_html_help.p_text = help;
   _ctl_html_help._minihtml_UseDialogFont();
   _ctl_html_help.p_backcolor = 0x80000022;
   _ctl_html_help._minihtml_ShrinkToFit();
}

/**
 * This form shows the results from a search within the options 
 * dialog. 
 */
defeventtab _options_search_results_form;

#region Options Dialog Helper Functions

/**
 * Initializes the form by populating the search tree for the first time.
 */
void _options_search_results_form_init_for_options()
{
   populate_search_tree();
}

/**
 * Check to see if a new search has been performed by 
 * repopulating the tree. 
 */
void _options_search_results_form_restore_state()
{
   // resize appropriately
   width := p_parent.p_width;
   if (p_width < width - (FRAME_PADDING * 2)) {
      p_width = width - (FRAME_PADDING * 2);
   }

   populate_search_tree();
}

#endregion Options Dialog Helper Functions

/**
 * Handles resizing for the search results form.  Resizes
 * columns so that they will keep the same relative sizes.
 */
void _options_search_results_form.on_resize()
{
   double ratios[];
   save_column_width_ratios(_ctl_search_results.p_window_id, ratios);

   _ctl_search_results.p_visible = _lbl_results.p_visible = false;

   // fix height
   heightDiff := p_height - (DEFAULT_DIALOG_BORDER * 2) - (_ctl_search_results.p_y + _ctl_search_results.p_height);
   _ctl_search_results.p_height += heightDiff;

   // change width
   width := p_width - (DEFAULT_DIALOG_BORDER * 2);
   _ctl_search_results.p_width = width;

   // align label
   _lbl_results.p_width = ((_ctl_search_results.p_x + width) - _lbl_results.p_x);

   restore_column_width_ratios(_ctl_search_results.p_window_id, ratios);

   _ctl_search_results.p_visible = _lbl_results.p_visible = true;
}

/**
 * Create event for search results page.  Prepares and populates
 * tree.
 */
void _ctl_search_results.on_create()
{
   colSlice := _ctl_search_results.p_width / 3;

   _ctl_search_results._TreeSetColButtonInfo(0, colSlice, TREE_BUTTON_SORT | TREE_BUTTON_PUSHBUTTON, -1, 'Option');
   _ctl_search_results._TreeSetColButtonInfo(1, colSlice * 2, TREE_BUTTON_SORT | TREE_BUTTON_PUSHBUTTON, -1, 'Path');
}

/**
 * If a node in the search results tree is double-clicked, takes
 * the user to that node in the options tree.
 */
void _ctl_search_results.' ', lbutton_double_click() 
{
   caption := _ctl_search_results._TreeGetCurCaption();
   _str a[];
   split(caption, \t, a);

   se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS, getOptionsForm());
   if (a._length() > 1) {
      optionsConfigTree -> showSearchNode(a[1], a[0]);
   } else {
      optionsConfigTree -> showSearchNode('', a[0]);
   }
}

/**
 * Throws the ENTER event to the parent form, which will cause 
 * the options dialog to close. 
 */
void _ctl_search_results.ENTER()
{
   call_event(p_parent, ENTER);
}

/**
 * Fills the search results tree with results from the search
 * performed in the options dialog.
 */
void populate_search_tree()
{
   _ctl_search_results._TreeDelete(TREE_ROOT_INDEX, 'C');

   _str a[];
   se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS, getOptionsForm());
   optionsConfigTree -> buildSearchNodeList(a);

   // update label
   results := a._length();
   if (results == 0) {
      _lbl_results.p_caption = 'No results found';
   } else if (results == 1) {
      _lbl_results.p_caption = '1 result found';
   } else {
      _lbl_results.p_caption = results' results found';
   }

   _ctl_search_results._TreeBeginUpdate(TREE_ROOT_INDEX);

   _str s;
   foreach (s in a) {
      _ctl_search_results._TreeAddItem(TREE_ROOT_INDEX, s, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
   }

   _ctl_search_results._TreeEndUpdate(TREE_ROOT_INDEX);
}

defeventtab _new_export_group_form;

_ctl_ok.on_create(_str groups[])
{
   // populate the combo box
   foreach (auto groupName in groups) {
      _ctl_existing_groups._lbadd_item(groupName);
   }

   // select the top one
   _ctl_existing_groups._lbtop();
   _ctl_existing_groups._lbselect_line();
   _ctl_existing_groups.p_text = _ctl_existing_groups._lbget_text();

   _ctl_existing_groups.p_enabled = false;
}

void _ctl_copy_settings.lbutton_up()
{
   _ctl_existing_groups.p_enabled = (_ctl_copy_settings.p_value != 0);
}

void _ctl_ok.lbutton_up()
{
   // validate our stuff - make sure we don't have any existing export 
   // groups with this name
   groupName := _ctl_export_group_name.p_text;
   copyGroupName := _ctl_existing_groups._lbget_text();
   if (!_ctl_existing_groups._lbfind_and_select_item(groupName, 'E')) {
      _message_box('An export group by this name already exists.  Please choose another name.');
      return;
   } 
   
   _param1 = groupName;
   if (_ctl_copy_settings.p_value) _param2 = copyGroupName;
   else _param2 = '';

   p_active_form._delete_window(IDOK);
}

defeventtab _export_options_form;

#define EXPORT_GROUPS         _ctl_ok.p_user             // hashtable of the available export groups 
                                                         // and whether they have protections associated with them
#define USER_CHANGED_PATH     _ctl_path.p_user           // whether the user has modified the path, either manually 
                                                         // or by browsing

_export_options_form.on_create()
{
    if (isEclipsePlugin()) {
        p_caption="Export Preferences";
    }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _export_options_form_initial_alignment()
{
   rightAlign := _ctl_export_group_combo.p_x + _ctl_export_group_combo.p_width;
   sizeBrowseButtonToTextBox(_ctl_path.p_window_id, _ctl_browse.p_window_id, 0, rightAlign);
}

void _ctl_ok.on_create(_str (&groups):[], boolean protect)
{
   _export_options_form_initial_alignment();

   _ctl_export_group_combo.p_text = '';

   EXPORT_GROUPS = groups;
   if (groups._length() == 1) {
      // we only have one group, so it must be the one
      boolean protectedGroup;
      _str name;
      foreach (name => protectedGroup in groups) {
         _ctl_export_group.p_caption = 'Export group:  'name;
         _ctl_export_group_combo.p_text = name;
         if (!protectedGroup) protect = protectedGroup;
      }
      _ctl_export_group.p_width = (_ctl_protection_code.p_x + _ctl_protection_code.p_width) - _ctl_export_group.p_x;
      _ctl_export_group_combo.p_visible = false;
   } else {
      foreach (auto group => . in groups) {
         _ctl_export_group_combo._lbadd_item(group);
      }
      // select the top one
      _ctl_export_group_combo._lbtop();
      _ctl_export_group_combo._lbselect_line();
      _ctl_export_group_combo.p_text = _ctl_export_group_combo._lbget_text();
      call_event(CHANGE_OTHER, _ctl_export_group_combo, ON_CHANGE, "W");
   }
   
   if (!protect) {
      _ctl_protection_label.p_visible = _ctl_protection_code.p_visible = _ctl_protection_help_label.p_visible = false;
      shift := _ctl_ok.p_y - _ctl_protection_code.p_y;
      _ctl_ok.p_y = _ctl_cancel.p_y = _ctl_help.p_y = _ctl_protection_code.p_y;
      
      p_active_form.p_height -= shift;
   }

   // load the initial file and directory
   USER_CHANGED_PATH = false;
   setSuggestedFilename();
}

void _ctl_export_group_combo.on_change(int reason)
{
   if (_ctl_export_group_combo.p_text != '' && _ctl_protection_label.p_visible) {
      protectedGroup := (EXPORT_GROUPS:[_ctl_export_group_combo.p_text] != 0);
      _ctl_protection_label.p_enabled = _ctl_protection_code.p_enabled = _ctl_protection_help_label.p_enabled = protectedGroup;
   }

   setSuggestedFilename();
}

static void setSuggestedFilename()
{
   // if the user set the path on their own, we don't mess with it
   if (USER_CHANGED_PATH) return;
      
   path := _ConfigPath();
   path = substr(path, 1, length(path) - 1);
   path = _strip_filename(path, 'N');

   version := _version();
   parse version with version'.' .;

   // get a group name? - not if we selected ALL OPTIONS
   group := '';
   if (_ctl_export_group_combo.p_text != ALL_OPTIONS_GROUP) {
      group = _ctl_export_group_combo.p_text;
      group = _cap_word(strip(group));
      
      // remove spaces and do some camel casing
      startPos := pos(' ', group);
      while (startPos) {
         begin := substr(group, 1, startPos - 1);
         after := substr(group, startPos + 1);

         group = begin :+ _cap_word(after);

         startPos = pos(' ', group);
      }
   }

   if (isEclipsePlugin()) {
      path :+= COREOPTIONSFILE'.zip';  
   } else {
      path :+= 'SlickEdit'group'Options'version'.zip';
   }
   _ctl_path.p_text = path;

   USER_CHANGED_PATH = false;
}

void _ctl_browse.lbutton_up()
{
   path := _ctl_path.p_text;
   zipFile := browseForZipFile(path);
   
   if (zipFile != '') {
      _ctl_path.p_text = zipFile;
      _ctl_path._begin_line();
      USER_CHANGED_PATH = true;
   }
}

void _ctl_path.on_change()
{
   USER_CHANGED_PATH = true;
}

static _str browseForZipFile(_str path)
{
   zipFile := _strip_filename(path, 'P');
   path = _strip_filename(path, 'N');

   format_list := 'SlickEdit Export Files(*.zip),All Files('ALLFILES_RE')';

   zipFile = _OpenDialog('-new -modal',
                         'Save export package to',
                         '',     // Initial wildcards
                         format_list,  // file types
								 OFN_SAVEAS|OFN_NOOVERWRITEPROMPT,  // flags - standard save as, do not prompt to overwrite
                         ".zip",  // Default extensions
                         zipFile, // Initial filename
                         path,    // Initial directory
                         '',      // Reserved
                         "Standard Open dialog box"
                         );

   return zipFile;
}

static _str checkForExistingZipFile(_str zipFile)
{
   // see if the file already exists
   if (file_exists(zipFile)) {

      zipPath := _strip_filename(zipFile, 'N');

      // what is our rev file name?
      filenameOnly := _strip_filename(zipFile, 'E');
      filenameOnly = _strip_filename(filenameOnly, 'P');
      extOnly := _get_extension(zipFile);

      rev := 1;
      revFilename := '';
      do {
         rev++;
         revFilename = filenameOnly :+ 'Rev' :+ rev :+ '.' :+ extOnly;
      } while (file_exists(zipPath :+ revFilename));

      // maybe the user told us what to do before...
      action := def_export_filename_action;
      if (!action) {
         action = show('-mdi -modal _export_options_file_exists_form', zipFile, revFilename);
      }

      switch (action) {
      case EFA_OVERWRITE:
         // overwrite the existing file
         zipFile = zipFile;
         break;
      case EFA_REV:
         // use the suggested rev file
         zipFile = zipPath :+ revFilename;
         break;
      case EFA_BROWSE:
         // we want to try browsing again, it was fun
         zipFile = browseForZipFile(zipFile);
         break;
      case 0:
         // this is a cancel option - just get out of here
         zipFile = '';
         break;
      }
   }

   return zipFile;
}

void _ctl_ok.lbutton_up()
{
   // validate our path
   if (_ctl_path.p_text == '') {
      _message_box("You must select a path for the export package");
      return;
   } else {
      _ctl_path.p_text = checkForExistingZipFile(_ctl_path.p_text);
      if (_ctl_path.p_text == '') {
         p_active_form._delete_window(IDCANCEL);
         return;
      }
   }

   if (_ctl_protection_code.p_visible && _ctl_protection_code.p_text == '') {
      _message_box("You must specify a protection code for the export package");
      return;
   }
   
   if (_ctl_export_group_combo.p_visible) {
      if (_ctl_export_group_combo.p_text == '') {
         _message_box("You must specify a protection code for the export package");
         return;
      } else _param3 = _ctl_export_group_combo.p_text;
   } else {
      name := '';
      parse _ctl_export_group.p_caption with 'Export group:  'name;
      _param3 = name;
   }
   
   _param1 = strip(_ctl_path.p_text, 'B', '"');
   _param2 = _ctl_protection_code.p_text;

   p_active_form._delete_window(IDOK);
}

/**
 * IF the user tries to create an options export package using a filename that 
 * already exists, we prompt with a few options:  overwrite the file, rev the 
 * filename, or browse for a new filename. 
 */
defeventtab _export_options_file_exists_form;

int def_export_filename_action = 0;

#define ALWAYS_DO_VALUE          ctl_cb_always_do.p_user

enum_flags ExportFilenameAction {
   EFA_OVERWRITE,
   EFA_REV,
   EFA_BROWSE
};

void ctl_ok.on_create(_str filename, _str revFilename)
{
   ALWAYS_DO_VALUE = 0;

   // set up our label
   ctl_info.p_caption = 'A file with the name 'filename' already exists.  What would you like to do?';

   // suggest a filename
   ctl_rb_create_rev.p_caption = 'Create a file with the name 'revFilename;

   // what did we decide to do last time?
   action := ctl_rb_overwrite._retrieve_value();
   switch (action) {
   case EFA_REV:
      ctl_rb_create_rev.p_value = 1;
      break;
   case EFA_BROWSE:
      ctl_rb_browse.p_value = 1;
      break;
   case EFA_OVERWRITE:
   default:
      ctl_rb_overwrite.p_value = 1;
      break;
   }
}

void ctl_ok.lbutton_up()
{
   // figure out our action here
   action := 0;
   if (ctl_rb_overwrite.p_value) {
      action = EFA_OVERWRITE;
   } else if (ctl_rb_create_rev.p_value) {
      action = EFA_REV;
   } else action = EFA_BROWSE;

   // save the value of our action
   ctl_rb_overwrite._append_retrieve(ctl_rb_overwrite, action);

   // check the value of the checkbox - do we need to keep doing this?
   if (ctl_cb_always_do.p_value) def_export_filename_action = action;

   p_active_form._delete_window(action);
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window(0);
}

void ctl_rb_overwrite.lbutton_up()
{
   ctl_cb_always_do.p_enabled = (ctl_rb_browse.p_value == 0);

   if (!ctl_cb_always_do.p_enabled) {
      ALWAYS_DO_VALUE = ctl_cb_always_do.p_value;
      ctl_cb_always_do.p_value = 0;
   } else {
      ctl_cb_always_do.p_value = ALWAYS_DO_VALUE;
   }
}

defeventtab _export_import_options_access_form;

boolean _export_import_options_access_form_is_modified()
{
   return false;
}

_ctl_export_label.on_create()
{
    if (isEclipsePlugin()) {
        _ctl_export_label.p_caption='Exporting preferences is one way to back up your SlickEdit settings.  You can also share your settings with other SlickEdit users with this feature.  Use Export Groups to pick and choose which options you want to export.';
    }
}

_ctl_import_label.on_create()
{
    if (isEclipsePlugin()) {
        _ctl_import_label.p_caption='You can import the settings of other users using the Import Preferences feature.  You can also restore settings that you backed up earlier using the Export Preferences feature.  Once you pick a package to import, you can preview the settings within and choose which ones to import.';

    }
}

_ctl_export_frame.on_create()
{
    if (isEclipsePlugin()) {
        _ctl_export_frame.p_caption="Export Preferences";
    }
}

_ctl_import_frame.on_create()
{
    if (isEclipsePlugin()) {
        _ctl_import_frame.p_caption="Import Preferences";
    }
}

_ctl_export_all_button.on_create()
{
    if (isEclipsePlugin()) {
        _ctl_export_all_button.p_caption="Export All Preferences...";
        _ctl_export_all_button.p_width=2000;
    }
}

_ctl_import_button.on_create()
{
    if (isEclipsePlugin()) {
        _ctl_import_button.p_caption="Import Preferences...";
    }
}

static boolean warnAboutOpenOptions()
{
   se.options.OptionsConfigTree * optionsConfigTree = _GetDialogInfoHtPtr(OPTIONS);
   if (optionsConfigTree -> areOptionsModified()) {

      buttons := "&Apply,&Discard Changes,Cancel:_cancel\t-html Options Changes have been made but not applied.";

      status := _message_box("Options Changes have been made but not applied.", "SlickEdit Options", MB_APPLYDISCARDCANCEL, IDAPPLY);
      switch(status) {
      case IDAPPLY:
          if (!optionsConfigTree -> apply()) return true;
          break;
      case IDDISCARD:
          optionsConfigTree -> cancel();
          break;
      case IDCANCEL:
          return false;
          break;
      default:
          break;
      }
/*
      status := textBoxDialog('SlickEdit Options',
                              0,
                              0,
                              'Options Dialog',
                              buttons);
      if (status == 1) {            // Apply - the first button
         if (!optionsConfigTree -> apply()) return true;
      } else if (status == 2) {     // Discard Changes - the second button
         optionsConfigTree -> cancel();
      } else {                      // Cancel our cancellation
         return false;
      }
*/
   }

   return true;
}

_ctl_export_all_button.lbutton_up()
{
   // check for options mods and maybe do not proceed
   optionsWid := getOptionsFormFromEmbeddedDialog();
   if (optionsWid.warnAboutOpenOptions()) {

      // get rid of this window
      optionsWid._delete_window();

      // now let's do it!
      _mdi.export_options('-a');
   }
}

_ctl_export_groups_button.lbutton_up()
{
   // check for options mods and maybe do not proceed
   optionsWid := getOptionsFormFromEmbeddedDialog();
   if (optionsWid.warnAboutOpenOptions()) {
      // get rid of this window
      optionsWid._delete_window();

      // now let's do it!
      _mdi.export_groups();
   }
}

_ctl_import_button.lbutton_up()
{
   // check for options mods and maybe do not proceed
   optionsWid := getOptionsFormFromEmbeddedDialog();
   if (optionsWid.warnAboutOpenOptions()) {
      // get rid of this window
      optionsWid._delete_window();

      // now let's do it!
      _mdi.import_options();
   }
}

/**
 * This event table sets up the event handlers for forms which 
 * are embedded in the options dialog. 
 */
defeventtab _options_etab2;

/**
 * When we press ESC on a form within the options dialog, we
 * want the whole form to exit (cancel).
 */
void _options_etab2.ESC, A_F4, 'M-F4'()
{
   form := getOptionsFormFromEmbeddedDialog();
   p_window_id = form;
   call_event(form, ESC, 'W');
}

/**
 * When we press an Alt+KEY on an embedded options form, we
 * might want to go to a control on the options parent form
 */
void _options_etab2.'M-A'-'M-Z',A_A-A_Z,A_0-A_9()
{
   orig := p_window_id;
   _dmDoDialogHotkey();

   origString := MakeTabIndexString(orig);
   currString := MakeTabIndexString(p_window_id);

   // if the new tab index is less than or the same as the original tab index,
   // then we know that we have looped back around - so we try the parent form
   if (origString >= currString) {
      optForm := getOptionsFormFromEmbeddedDialog();
      event := last_event();
      optForm.call_event(optForm, event, 'W');
   }
}

/**
 * When we press ENTER on a form within the options dialog, we
 * want the whole form to apply and exit (OK).
 */
void _options_etab2.ENTER()
{
   form := getOptionsFormFromEmbeddedDialog();
   p_window_id = form;
   call_event(form, ENTER, 'W');
}

void _options_etab2.'TAB'()
{
   orig := p_window_id;
   _next_control();

   // if the new tab index is less than the original tab index, 
   // then we know that we have looped back around - so we TAB 
   // out of the panel
   origString := MakeTabIndexString(orig);
   currString := MakeTabIndexString(p_window_id);
   if (origString >= currString) {
      p_active_form.p_parent._next_control();
   }
}

void _options_etab2.'S-TAB'()
{
   orig := p_window_id;
   _prev_control();

   // if the new tab index is more than the original tab index,
   // then we know that we have looped back around - so we TAB
   // out of the panel
   origString := MakeTabIndexString(orig);
   currString := MakeTabIndexString(p_window_id);
   if (origString < currString) {
      p_active_form.p_parent._prev_control();
   }
}
