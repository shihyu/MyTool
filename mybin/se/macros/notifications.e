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
#include "slick.sh"
#include "xml.sh"
#import "commentformat.e"
#import "help.e"
#import "listbox.e"
#import "math.e"
#import "optionsxml.e"
#import "quickstart.e"
#import "stdprocs.e"
#import "tbnotification.e"
#import "toast.e"
#import "xmlcfg.e"
#import "xmlwrap.e"
#import "toast.e"
#require "se/datetime/DateTime.e"
#endregion

using namespace se.datetime;

/**
 * How to add a feature to the notifications system: 
 *  
 * 1. Add an enum for your feature to the NotificationFeature enum. 
 *  
 * 2. Add an ALERT_ constant for your feature to toast.e under editing alerts. 
 *  
 * 3. Add information about your feature to sysconfig/alert_config.xml. 
 *  
 * 4. Add information to the notification_info array.  Your line must be the 
 * same index as the value of the enum added in step 1.  The info will be put 
 * into a NOTIFICATION_FEATURE_INFO struct.  See the declaration of that struct 
 * for info on the fields. 
 *  
 * 5. Add calls to notifyUserOfFeatureUse() where you want the notification to
 * happen.  If your notification is not buffer-related, then be sure and use '' 
 * for the filename and 0 for the line number. 
 *  
 * 6. Put default notification method in definit().  After v15, you will need to
 * add these by checking for null in def_notification_actions[FEATURE_NAME], 
 * since the user will already have this array in a previous form. 
 *  
 * 7. If you do not want to use the generic Notification dialog, write your own
 * and call notifyUserOfFeatureUse() with the noGenericDialog argument set to 
 * true. See adaptiveformatting.e for examples on how to handle this case. 
 */

enum NotificationFeature {
   NF_ADAPTIVE_FORMATTING,
   NF_ALIAS_EXPANSION,
   NF_AUTO_SYMBOL_TRANSLATION,
   NF_COMMENT_WRAP,
   NF_DOC_COMMENT_EXPANSION,
   NF_DYNAMIC_SURROUND,
   NF_HTML_XML_FORMATTING,
   NF_INSERT_RIGHT_BRACKET,
   NF_INSERT_MATCHING_PARAMETERS,
   NF_SMART_PASTE,
   NF_SYNTAX_EXPANSION,
   NF_AUTO_CLOSE_VISITED_FILE,
   NF_AUTO_CASE_KEYWORD,
   NF_AUTO_CLOSE_COMPLETION,
   NF_AUTO_LIST_MEMBERS,
   NF_AUTO_DISPLAY_PARAM_INFO,
   NF_AUTO_LIST_COMPATIBLE_PARAMS,
   NF_AUTO_LIST_COMPATIBLE_VALUES,
   NF_LARGE_FILE_EDITING,
};

enum NotificationMethod {
   NL_DIALOG,
   NL_ALERT_WITH_TOAST,
   NL_ALERT_NO_TOAST,
   NL_MESSAGE,
   NL_NONE,
};

static _str notification_method_labels[] = _reinit {
   "Dialog",
   "Status line icon with pop-up",
   "Status line icon, no pop-up",
   "Message line",
   "None",
};

struct NOTIFICATION_ACTION {
   NotificationMethod Method;
   boolean Log;
};

struct NOTIFICATION_FEATURE_INFO {
   _str Name;                 // name of feature (for use in the display)
   _str Description;          // a brief description for the user
   _str HelpLink;             // the p_help for this feature
   _str OptionsCommand;       // the command to see the options for this feature
   _str OptionsArgument1;     // first argument sent to the configuration command ('' if none)
   _str OptionsArgument2;     // second argument sent to the configuration command ('' if none)
   int AlertId;               // id used to send a toast message about this feature
};

struct NOTIFICATION_INFO {
   int Feature;
   _str Timestamp;
   _str Filename;
   int LineNumber;
   int SecondFeature;
};

int def_max_note_log_count = 1000;        // maximum number of notifications to keep in the log file

NOTIFICATION_ACTION def_notification_actions[];

static NOTIFICATION_FEATURE_INFO notification_info[]= _reinit {
   {"Adaptive Formatting", "Adaptive Formatting scans your file for you to determine which coding styles are in use in the current file.  These style settings are then used so that your new code will match the existing coding style of the file.", "Adaptive Formatting", "config", "Adaptive Formatting", "L", ALERT_ADAPTIVE_FORMATTING},
   {"Auto-Alias Expansion", "If you type an alias identifer and press space, that alias is automatically expanded for you.", "Language-Specific Aliases", "config", "Aliases", "L", ALERT_ALIAS_EXPANSION},
   {"Auto Symbol Translation", "Auto Symbol Translation automatically converts a character or sequence of characters to the appropriate entity reference, saving you from having to repeatedly guess at the correct entity or look up reference charts. ", "Auto Symbol Translation", "config", "Formatting", "L", ALERT_AUTO_SYMBOL_TRANSLATION},
   {"Comment Wrap", "Comments are automatically wrapped to the next line as you type, eliminating the need to constantly reformat your comments manually.", "Comment Wrapping", "config", "Comment Wrap", "L", ALERT_COMMENT_WRAP},
   {"Doc Comment Expansion", "When you type the start characters for one of certain comment formats and press Enter on a line directly above a function, class, or variable, SlickEdit automatically inserts a skeleton doc comment for that style.", "Doc Comments", "config", "Comments", "L", ALERT_DOC_COMMENT_EXPANSION},
   {"Dynamic Surround", "Dynamic Surround provides a convenient way to surround a group of statements with a block statement, indented to the correct levels according to your preferences.  SlickEdit enters Dynamic Surround mode automatically after you expand a block statement.  A box is drawn as a visual guide, and you can pull the subsequent lines of code or whole statements into the block by using the Up, Down, PgUp, or PgDn keys.  Dynamic Surround stays active until you press ESC.", "Dynamic Surround", "config", "Indent", "L", ALERT_DYNAMIC_SURROUND},
   {"XML/HTML Formatting", "Content in XML and HTML files may be set to automatically wrap and format as you edit. XML/HTML Formatting is essentially comprised of two features: Content Wrap, which wraps the content between tags, and Tag Layout, which formats tags according to a specified layout.", "XML/HTML Formatting", "config", "Formatting", "L", ALERT_HTML_XML_FORMATTING},
   {"Auto-Insert >", "You can type the open brace of a start tag (<), and SlickEdit automatically inserts the closing brace (>) while leaving the cursor positioned between the braces, ready for you to type the tag.", "HTML Formatting", "config", "Formatting", "L", ALERT_INSERT_RIGHT_BRACKET},
   {"Auto-Insert Matching Parameters", "When parameter information is displayed and the name of the current formal parameter matches the name of a symbol in the current scope of the appropriate type or class, the name is automatically inserted. ", "Context Tagging Options (Language-Specific)", "config", "Context Tagging":+VSREGISTEREDTM, "L", ALERT_INSERT_MATCHING_PARAMETERS},
   {"SmartPaste", "When pasting lines of text into a source file, SmartPaste reindents the added lines according to the surrounding code.", "SmartPaste", "config", "Indent", "L", ALERT_SMART_PASTE},
   {"Syntax Expansion", "Syntax Expansion is a feature designed to minimize keystrokes, increasing your code editing efficiency.  When you type certain keywords and then press the space bar or Enter key, Syntax Expansion inserts a default template that is specifically designed for this statement.", "Syntax Expansion", "config", "Indent", "L", ALERT_SYNTAX_EXPANSION},
   {"Auto-Close Visited File", "When a file is opened as a result of a symbol navigation or search operation, but not modified, it can be closed automatically after navigating away from it.", "Automatically close visited files", "config", "Bookmarks", "", ALERT_AUTO_CLOSE},
   {"Auto Case Keywords", "When a keyword is typed in a case-insensitive language, SlickEdit will modify the case of the keyword as you type the last letter.", "Auto case keywords", "config", "Formatting", "L", ALERT_AUTO_CASE_KEYWORD},
   {"Auto-Close Completion", "Auto-Close inserts matching closing punctuation when opening punctuation is entered. ", "Auto-Close Options (Language-Specific)", "config", "Auto-Close", "L", ALERT_AUTO_CLOSE_COMPLETIONS},
   {"Auto-List Members", "Typing a member access operator (e.g. \".\" or \"->\" in C++) will trigger SlickEdit to display a list of the members for the corresponding type. ", "List Members", "config", "Context Tagging", "L", ALERT_AUTO_LIST_MEMBERS},
   {"Auto-Display Parameter Information", "The prototype and comments for a function are automatically displayed when a function operator such as the open parenthesis is typed, and the current argument is highlighted within the displayed prototype.", "Parameter Information", "config", "Context Tagging", "L", ALERT_AUTO_DISPLAY_PARAM_INFO},
   {"Auto-List Compatible Parameters", "Compatible variables are automatically listed when you are typing the arguments to a function call. ", "Auto List Compatible Parameters", "config", "Context Tagging", "L", ALERT_AUTO_LIST_COMPATIBLE_PARAMS},
   {"Auto-List Compatible Values", "Compatible variables are automatically listed when you are typing the right hand side of an assignment statement. ", "Auto List Compatible Values", "config", "Context Tagging", "L", ALERT_AUTO_LIST_COMPATIBLE_VALUES},
   {"Large File Editing", "SlickEdit can edit files up to 2GB in size by reading the file block-by-block instead of reading the entire file.", "Load partially for large files", "config", "Load", "", ALERT_LARGE_FILE_SUPPORT},
};

static int logHandle = 0;                 // handle to xml file containing our notification log
static int logNode = 0;                   // top level "Notifications" node in the xml log file 
static int logCount = -1;                 // number of notifications in our file

definit()
{
   if (def_notification_actions == null) {
      // pull some of these from previous nag dialogs
      NOTIFICATION_ACTION action;
      action.Log = true;

      action.Method = def_warn_adaptive_formatting ? NL_ALERT_WITH_TOAST : NL_MESSAGE;
      def_notification_actions[NF_ADAPTIVE_FORMATTING] = action;

      action.Method = NL_ALERT_NO_TOAST;
      def_notification_actions[NF_ALIAS_EXPANSION] = action;

      action.Method = def_nag_symbolTranslation ? NL_ALERT_WITH_TOAST : NL_MESSAGE;
      def_notification_actions[NF_AUTO_SYMBOL_TRANSLATION] = action;

      action.Method = NL_ALERT_NO_TOAST;
      def_notification_actions[NF_COMMENT_WRAP] = action;

      action.Method = def_nag_doccomment_expansion ? NL_ALERT_NO_TOAST : NL_MESSAGE;
      def_notification_actions[NF_DOC_COMMENT_EXPANSION] = action;

      action.Method = NL_MESSAGE;
      def_notification_actions[NF_DYNAMIC_SURROUND] = action;

      action.Method = NL_ALERT_WITH_TOAST;
      def_notification_actions[NF_HTML_XML_FORMATTING] = action;

      action.Method = NL_ALERT_NO_TOAST;
      def_notification_actions[NF_INSERT_RIGHT_BRACKET] = action;

      action.Method = NL_ALERT_NO_TOAST;
      def_notification_actions[NF_INSERT_MATCHING_PARAMETERS] = action;

      action.Method = NL_NONE;
      def_notification_actions[NF_SMART_PASTE] = action;

      action.Method = NL_ALERT_WITH_TOAST;
      def_notification_actions[NF_SYNTAX_EXPANSION] = action;

      action.Method = NL_ALERT_NO_TOAST;
      def_notification_actions[NF_AUTO_CLOSE_VISITED_FILE] = action;

      action.Method = NL_ALERT_NO_TOAST;
      def_notification_actions[NF_AUTO_CASE_KEYWORD] = action;

      action.Method = NL_ALERT_WITH_TOAST;
      def_notification_actions[NF_AUTO_CLOSE_COMPLETION] = action;

      action.Method = NL_ALERT_WITH_TOAST;
      def_notification_actions[NF_AUTO_LIST_MEMBERS] = action;

      action.Method = NL_ALERT_WITH_TOAST;
      def_notification_actions[NF_AUTO_DISPLAY_PARAM_INFO] = action;

      action.Method = NL_ALERT_WITH_TOAST;
      def_notification_actions[NF_AUTO_LIST_COMPATIBLE_PARAMS] = action;

      action.Method = NL_ALERT_WITH_TOAST;
      def_notification_actions[NF_AUTO_LIST_COMPATIBLE_VALUES] = action;

      action.Method = NL_ALERT_WITH_TOAST;
      def_notification_actions[NF_LARGE_FILE_EDITING] = action;
   }

   // these things were added after v15
   maybeInitNewNotification(NF_AUTO_CASE_KEYWORD, NL_ALERT_NO_TOAST, true);
   maybeInitNewNotification(NF_AUTO_CLOSE_COMPLETION, NL_ALERT_WITH_TOAST, true);
   maybeInitNewNotification(NF_AUTO_LIST_MEMBERS, NL_ALERT_WITH_TOAST, true);
   maybeInitNewNotification(NF_AUTO_DISPLAY_PARAM_INFO, NL_ALERT_WITH_TOAST, true);
   maybeInitNewNotification(NF_AUTO_LIST_COMPATIBLE_PARAMS, NL_ALERT_WITH_TOAST, true);
   maybeInitNewNotification(NF_AUTO_LIST_COMPATIBLE_VALUES, NL_ALERT_WITH_TOAST, true);
   maybeInitNewNotification(NF_LARGE_FILE_EDITING, NL_ALERT_WITH_TOAST, true);

   // see if we have a valid handle
   if (logHandle > 0 && !_xmlcfg_is_handle_valid(logHandle)) {
      logHandle = 0;
      logCount = 0;
      logNode = 0;
   }
   if (logNode > 0 && !_xmlcfg_is_node_valid(logHandle, logNode)) {
      logNode = 0;
   }

}

/**
 * When a user upgrades from a previous version, we determine if we need to turn 
 * off any notifications.  We don't want to annoy a user by telling him about 
 * something he already knows about. 
 * 
 * @param config_migrated_from_version             version migrating from
 */
void _UpgradeNotificationLevels(_str config_migrated_from_version)
{
   // if we did not upgrade from anything, don't worry about it
   if (config_migrated_from_version == '') return;

   // get the major version
   dotPos := pos('.', config_migrated_from_version);
   if (dotPos) {
      prevMajorVersion := (int)substr(config_migrated_from_version, 1, dotPos - 1);
      // notification feature was introduced in v15
      if (prevMajorVersion < 15) {
         setNotificationMethod(NF_ADAPTIVE_FORMATTING, def_warn_adaptive_formatting ? NL_ALERT_WITH_TOAST : NL_MESSAGE);
         setNotificationMethod(NF_AUTO_SYMBOL_TRANSLATION, def_nag_symbolTranslation ? NL_ALERT_WITH_TOAST : NL_MESSAGE);
         setNotificationMethod(NF_DOC_COMMENT_EXPANSION, def_nag_doccomment_expansion ? NL_ALERT_NO_TOAST : NL_MESSAGE);
      }
   }
}

/**
 * Adds a new notification to our array.  Used to add notification features 
 * after the initial release of notifications in v15. 
 * 
 * @param feature 
 * @param initMethod 
 * @param initLog 
 */
static void maybeInitNewNotification(NotificationFeature feature, NotificationMethod initMethod, boolean initLog)
{
   if (def_notification_actions[feature] == null || 
       def_notification_actions[feature].Log == null || 
       def_notification_actions[feature].Method == null) {
      NOTIFICATION_ACTION action;
      action.Log = initLog;
      action.Method = initMethod;
      def_notification_actions[feature] = action;
   }
}

#region Notification API
// Use these methods to tell the user that the application has does 
// something neat that they might want to know about

/**
 * Alerts the user that an automatic feature has been used.  Determines which
 * notification method to use.
 * 
 * @param feature       feature that was used (One of the NotificationFeature 
 *                      enums)
 */
void notifyUserOfFeatureUse(NotificationFeature feature1, _str filename = p_buf_name, int lineNumber = p_line, 
                            NotificationFeature feature2 = -1, _str msg = '')
{
   // make sure this is a valid feature
   if (!isFeatureValid(feature1)) return;
   if (feature2 != -1 && !isFeatureValid(feature2)) return;

   // determine which method of notifying the user we want to use
   method := 0;
   if (feature2 == -1) {
      // only one feature to worry about here
      method = getNotificationMethod(feature1);
   } else {
      // we want to use the more noticeable of the two features (which means the lower value enum)
      method1 := getNotificationMethod(feature1);
      method2 := getNotificationMethod(feature2);
      method = (method1 > method2) ? method2 : method1;
   }

   NOTIFICATION_INFO info;
   info.Feature = feature1;
   info.Timestamp = _time('F');
   info.Filename = filename;
   info.LineNumber = lineNumber;
   info.SecondFeature = feature2;

   // compare this item to the most recent one in the log - make sure they are not the same
   if (!hasBeenRecentlyLogged(info)) {
   
      // get our notification message
      if (msg == '') msg = getNotificationFeatureMessage(info);

      // now, what do we do?
      switch (method) {
      case NL_DIALOG:
         if (feature1 != NF_ADAPTIVE_FORMATTING) {
            displayNotificationDialog(feature1, feature2);
         }
         break;
      case NL_ALERT_WITH_TOAST:
      case NL_ALERT_NO_TOAST:
         alertId := getNotificationAlertId(feature1);
         if (alertId >= 0) {
            _ActivateAlert(ALERT_GRP_EDITING_ALERTS, alertId, msg, '', (int)(method == NL_ALERT_WITH_TOAST));
         }
         break;
      case NL_MESSAGE:
         helpInfo := getNotificationFeatureHelp(info.Feature);
         msg :+= '  Search the help for 'helpInfo' for more information.';

         // show a message for the user to see/ignore
         message(msg);
         break;
      }
   }

   // we always log this info in the log file
   addNotificationToLog(info);
   if (doLogNotification(feature1) || doLogNotification(feature2)) refreshNotificationTree();
}

_str getNotificationFeatureMessage(NOTIFICATION_INFO &info)
{
   text := '';

   switch (info.Feature) {
   case NF_AUTO_CLOSE_COMPLETION:
      text = "Auto-Close inserted matching closing punctuation.";
      keyToPress := '';
      if (def_autobracket_mode_keys == (AUTO_BRACKET_KEY_ENTER | AUTO_BRACKET_KEY_TAB)) {
         keyToPress = 'TAB or ENTER';
      } else if (def_autobracket_mode_keys == AUTO_BRACKET_KEY_ENTER) {
         keyToPress = 'ENTER';
      } else if (def_autobracket_mode_keys == AUTO_BRACKET_KEY_TAB) {
         keyToPress = 'TAB';
      }

      if (keyToPress != '') {
         text :+= "  Press "keyToPress" to jump to marker.";
      }
      break;
   case NF_AUTO_CLOSE_VISITED_FILE:
      text = _strip_filename(info.Filename, 'P')' has been auto-closed.';
      break;
   default:
      text = getNotificationFeatureName(info.Feature, info.SecondFeature)' has been performed.';
      break;
   }

   return text;
}

_str getSyntaxExpansionNotificationMessage(_str word)
{
   if (word != '') {
      return 'Syntax Expansion has expanded "'word'".';
   }
   
   return getNotificationFeatureName(NF_SYNTAX_EXPANSION)' has been performed.';;
}

boolean isFeatureValid(NotificationFeature feature)
{
   return (feature >= 0 && feature < def_notification_actions._length()); 
}

/**
 * Retrieves the current mechanism used to notify the user that an automatic 
 * feature has run. 
 * 
 * @param feature       feature that was used (one of the NotificationFeature 
 *                      enums)
 * 
 * @return              NotificationLevel used for this feature
 */
NotificationMethod getNotificationMethod(NotificationFeature feature)
{
   // make sure this is a valid feature
   if (feature < 0 || feature >= def_notification_actions._length()) return -1;

   return def_notification_actions[feature].Method;
}

/**
 * Retrieves whether we add an entry to the notification log for 
 * this kind of feature. 
 * 
 * @param feature       feature that was used (one of the 
 *                      NotificationFeature enums)
 * 
 * @return boolean      true if we log this feature, false 
 *                      otherwise
 */
boolean doLogNotification(NotificationFeature feature)
{
   // make sure this is a valid feature
   if (feature < 0 || feature >= def_notification_actions._length()) return false;

   return def_notification_actions[feature].Log;
}

/**
 * Sets the notification level for the given NotificationFeature, provided that 
 * level is allowed for that feature.  Some features may not allow the level of 
 * NM_DIALOG because a dialog would mess with the usability of the feature. 
 * 
 * @param feature       feature to set level for
 * @param level         new notification level
 */
void setNotificationMethod(NotificationFeature feature, NotificationMethod method)
{
   // make sure this is a valid feature
   if (feature < 0 || feature > def_notification_actions._length()) return;

   // we do not allow this case - a dialog would really screw up dynamic surround
   if (feature == NF_DYNAMIC_SURROUND && method == NL_DIALOG) return;

   def_notification_actions[feature].Method = method;
}

/**
 * Retrieves the alert ID used to pop a toast message for this feature.
 * 
 * @param feature       feature to get alert id for
 * 
 * @return int          alert id
 */
int getNotificationAlertId(NotificationFeature feature)
{
   // make sure this is a valid feature
   if (feature < 0 || feature > notification_info._length()) return -1;

   return notification_info[feature].AlertId;
}

/**
 * Sets whether we add an entry to the notification log for 
 * this kind of feature. 
 * 
 * @param feature       feature that was used (one of the 
 *                      NotificationFeature enums)
 * @param doLog         true if we log this feature, false 
 *                      otherwise
 */
void setLogNotification(NotificationFeature feature, boolean doLog)
{
   // make sure this is a valid feature
   if (feature < 0 || feature > def_notification_actions._length()) return;

   def_notification_actions[feature].Log = doLog;
}

/**
 * Sets the notification level for every Notification Feature to the same value, 
 * provided that level is allowed for that feature. 
 * 
 * @param level         new level
 */
void setAllNotificationMethods(NotificationMethod method)
{
   // go through the list of features and see which one has the matching name
   for (feature := 0; feature < notification_info._length(); feature++) {
      setNotificationMethod(feature, method);
   }
}

/**
 * Returns the description for the given NotificationLevel.  Used to translate 
 * notification levels to strings for displaying to the user. 
 * 
 * @param level            level to translate
 * 
 * @return _str            description of notification level
 */
static _str notificationMethodToDescription(NotificationMethod method)
{
   return notification_method_labels[method];
}

/**
 * Returns the NotificationLevel associated with the given text description.
 * 
 * @param description            level description
 * 
 * @return NotificationLevel     NotificationLevel described by description
 */
static NotificationMethod descriptionToNotificationMethod(_str description)
{
   foreach (auto method => auto desc in notification_method_labels) {
      if (desc == description) return method;
   }

   return -1;
}

#endregion Notification API

#region Notification Log

/**
 * Called when the application is exiting.  Closes and saves the database.
 */
void _exit_notifications()
{
   if (logHandle > 0 && _xmlcfg_is_handle_valid(logHandle)) {
      mergeNotificationLog(true);
      _xmlcfg_close(logHandle);
   }

   logHandle = 0;
   logCount = 0;
}

/**
 * Retrieves the path and filename to our notification log.  The file may no 
 * yet exist if no notifications have been logged. 
 * 
 * @return                    path to notification log
 */
static _str getSessionNotificationLogFilename()
{
   return _ConfigPath() :+ 'notificationsTEMP.xml';
}

/**
 * Gets the name of the filename where the permanent log file resides.
 * 
 * 
 * @return _str 
 */
static _str getPermanentNotificationLogFilename()
{
   return _ConfigPath() :+ 'notifications.xml';
}

/**
 * Opens up the notification log if it is not yet open.  Also gets the values 
 * for other variables used in managing the log file, such as the top-level 
 * notification node and the number of notifications currently in the list. 
 * 
 * @return                    0 for success, negative error code for failure
 */
static int maybeOpenNotificationLog()
{
   // if we already have a valid handle, then nothing needs to be done
   if (logHandle <= 0 || !_xmlcfg_is_handle_valid(logHandle)) {

      // open or create the file
      logHandle = _xmlcfg_create(getSessionNotificationLogFilename(), VSENCODING_UTF8, VSXMLCFG_CREATE_IF_EXISTS_OPEN);
      if (logHandle <= 0) return logHandle;

      // find the top level node, or maybe just create it
      logNode = findNotificationsListNode(logHandle);
      if (logNode <= 0) return logNode;

      // determine how many we have in our list, so we know when to start deleting stuff
      if (logCount < 0) {
         logCount = _xmlcfg_get_num_children(logHandle, logNode);
      }
   }

   return 0;
}

/**
 * Finds the parent node which contains the list of all notifications.  If no 
 * such node exists in the file, one is created. 
 * 
 * @param xmlHandle              handle to xml file containing notifications
 * 
 * @return int                   notification list parent node
 */
static int findNotificationsListNode(int xmlHandle)
{
   node := _xmlcfg_find_simple(xmlHandle, "//Notifications");
   if (node < 0) {
      // just create a new one
      node = _xmlcfg_add(xmlHandle, 0, "Notifications", VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   }

   return node;
}

/**
 * Adds a notification to our notification log.  If this is the first 
 * notification to be logged, creates and opens up the log file. 
 * 
 * @param feature             feature to be logged
 * 
 * @return                    0 for success, negative error code for failure
 */
static int addNotificationToLog(NOTIFICATION_INFO info)
{
   // we might need to open the log if this is the first notification
   status := maybeOpenNotificationLog();
   if (status) return status;

   maybeMergeNotificationLog();

   // add this one to the beginning
   featureNode := 0;
   firstChild := _xmlcfg_get_first_child(logHandle, logNode);
   if (firstChild < 0) {
      // there is no first child, so just add this to our list
      featureNode = _xmlcfg_add(logHandle, logNode, "Notification", VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   } else {
      // add this one before the first child
      featureNode = _xmlcfg_add(logHandle, firstChild, "Notification", VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_BEFORE);
   }
   if (featureNode < 0) return featureNode;

   _xmlcfg_add_attribute(logHandle, featureNode, "Feature", info.Feature);
   _xmlcfg_add_attribute(logHandle, featureNode, "FeatureName", getNotificationFeatureName(info.Feature));
   _xmlcfg_add_attribute(logHandle, featureNode, "Timestamp", info.Timestamp);
   _xmlcfg_add_attribute(logHandle, featureNode, "Filename", info.Filename);
   if (info.LineNumber != 0) {
      _xmlcfg_add_attribute(logHandle, featureNode, "LineNumber", info.LineNumber);
   }
   if (info.SecondFeature != null && info.SecondFeature != '') {
      _xmlcfg_add_attribute(logHandle, featureNode, "SecondFeature", info.SecondFeature);
   }

   // increase our count
   logCount++;

   // see if we have too many - need to get rid of one
   if (logCount > def_max_note_log_count) {
      // delete the first one
      lastChild := _xmlcfg_get_last_child(logHandle, logNode);
      status = _xmlcfg_delete(logHandle, lastChild);
      logCount--;
   }

   return status;
}

/**
 * Determines if the given notification has already been logged.  A notification 
 * is determined to be already logged if another notification with the same 
 * feature and filename has been logged within the last second.
 * 
 * @param info                Notification to look for
 * 
 * @return boolean            true if the notification has already been logged, 
 *                            false otherwise
 */
static boolean hasBeenRecentlyLogged(NOTIFICATION_INFO &info)
{
   do {
      // we only check on this for certain features that could potentially be very noisy
      if (info.Feature != NF_COMMENT_WRAP && info.Feature != NF_HTML_XML_FORMATTING) break;

      // maybe nothing has been logged
      if (logHandle <= 0 || !_xmlcfg_is_handle_valid(logHandle) || 
          logNode <= 0 || !_xmlcfg_is_node_valid(logHandle, logNode)) break;

      // if the log is empty, then the answer is obvious
      if (logCount <= 0) break;

      // find the last time we logged this feature
      lastNode := _xmlcfg_find_simple(logHandle, "//Notification[@Feature='"info.Feature"']");
      if (lastNode < 0) break;
         
      NOTIFICATION_INFO lastInfo;
      getNotificationInfo(lastNode, lastInfo);
   
      // for these to be considered the same, the feature, filename, and time have to match
      if (info.Filename != lastInfo.Filename) break;
   
//    // see if the line numbers are close
//    lineDiff := abs(info.LineNumber - lastInfo.LineNumber);
//    if (lineDiff > 5) break;

      DateTime lastdt();
      lastdt = DateTime.fromTimeF(lastInfo.Timestamp);
      lastdt = lastdt.add(5, DT_SECOND);
      if ((int)lastdt.toTimeF() >= (int)info.Timestamp) break;
         
      return true;

   } while (false);

   return false;
}

/**
 * Determines if the temporary in-memory log is too large.  If
 * so, merges the log information into the permanent log.
 * 
 */
void maybeMergeNotificationLog()
{
   if (logCount > (def_max_note_log_count / 2)) {
      mergeNotificationLog(false);
   }
}

/**
 * Merges the current notification log into the cumulative notification log for 
 * the editor.  The current log is only for this session.  So that it does not 
 * become too big, we limit it to a certain size ( 
 * 
 * 
 * @param mergeAll 
 */
void mergeNotificationLog(boolean mergeAll)
{
   // make sure this is all good
   if (logHandle <= 0 || !_xmlcfg_is_handle_valid(logHandle) || 
       logNode <= 0 || !_xmlcfg_is_node_valid(logHandle, logNode)) return;

   // nothing to save!
   if (logCount == 0) return;

   // see if the ongoing log exists
   permLogFile := getPermanentNotificationLogFilename();
   if (!file_exists(permLogFile)) {
      // this doesn't exist, so we can just save our current file as the new file
      _xmlcfg_save(logHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE, permLogFile);
   } else {
      // get a handle to the ongoing log
      // if we can't open it, then don't merge it
      int status = 0;
      permLogHandle := _xmlcfg_open(permLogFile, status);
      if (permLogHandle < 0 || status < 0) {
         return;
      }

      // find the notifications list
      permLogNode := findNotificationsListNode(permLogHandle);

      // how many are in here?
      permCount := _xmlcfg_get_num_children(permLogHandle, permLogNode);

      // now copy our new ones in
      permFirstChild := _xmlcfg_get_first_child(permLogHandle, permLogNode);
      if (permFirstChild > 0) {
         _xmlcfg_copy_children_as_siblings(permLogHandle, permFirstChild, logHandle, logNode, true);
      } else {
         _xmlcfg_copy(permLogHandle, permLogNode, logHandle, logNode, VSXMLCFG_COPY_CHILDREN);
      }

      // update our total count
      permCount += logCount;

      if (mergeAll) {
         // just delete everything in the temp file
         _xmlcfg_delete(logHandle, logNode, true);
      } else {
         // we want to leave some in the other list
         _xmlcfg_delete_first_n_children(permLogHandle, permLogNode, def_notification_tool_window_log_size);
         permCount -= def_notification_tool_window_log_size;

         // clean out the old list
         _xmlcfg_delete_last_n_children(logHandle, logNode, logCount - def_notification_tool_window_log_size);
         logCount = def_notification_tool_window_log_size;
      }

      if (permCount > def_max_note_log_count) {
         _xmlcfg_delete_last_n_children(permLogHandle, permLogNode, permCount - def_max_note_log_count);
      }

      _xmlcfg_save(permLogHandle, -1,  VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
      _xmlcfg_close(permLogHandle);
   }
}

/**
 * Pulls the data for one notification out of the xml file.
 * 
 * @param infoNode            node where data resides
 * @param info                data to be filled
 */
static void getNotificationInfo(int infoNode, NOTIFICATION_INFO &info)
{
   info.Feature = (int)_xmlcfg_get_attribute(logHandle, infoNode, "Feature");
   info.Timestamp = _xmlcfg_get_attribute(logHandle, infoNode, "Timestamp");
   info.Filename = _xmlcfg_get_attribute(logHandle, infoNode, "Filename");
   info.LineNumber = (int)_xmlcfg_get_attribute(logHandle, infoNode, "LineNumber", "0");
   info.SecondFeature = (int)_xmlcfg_get_attribute(logHandle, infoNode, "SecondFeature", "-1");
}

/**
 * Retrieves the most recent Notifications in an array.
 * 
 * @param log                 array to put Notifications in
 * @param num                 number of notifications to include
 */
void getNotificationLogArray(NOTIFICATION_INFO (&log)[], int num)
{
   if (logHandle > 0 && logNode > 0) {
      index := 0;
      featureNode := _xmlcfg_get_first_child(logHandle, logNode);
      while (featureNode > 0 && index < num) {
         NOTIFICATION_INFO info;
         getNotificationInfo(featureNode, info);

         // see if we are supposed to show this one
         if (doLogNotification(info.Feature)) {
            log[index] = info;
            index++;
         }

         featureNode = _xmlcfg_get_next_sibling(logHandle, featureNode);
      }
   }
}

#endregion Notification Log

#region Notification Data

/**
 * Retrieves the NotificationFeature that is associated with the given text.
 * 
 * @param featureName                  name of feature
 * 
 * @return NotificationFeature         NotificationFeature associated with name
 */
static NotificationFeature getNotificationFeatureByName(_str featureName)
{
   // go through the list of features and see which one has the matching name
   NOTIFICATION_FEATURE_INFO info;
   foreach (auto index => info in notification_info) {
      if (info.Name == featureName) return index;
   }

   return -1;
}

/**
 * Retrieves the display name of a NotificationFeature.
 * 
 * @param feature                feature of interest (one of NotificationFeature 
 *                               enum)
 * 
 * @return                       name of this feature as it is displayed to the 
 *                               user
 */
_str getNotificationFeatureName(NotificationFeature feature1, NotificationFeature feature2 = -1)
{
   // make sure this is a valid feature
   if (feature1 < 0 || feature1 > notification_info._length()) return "";

   name := notification_info[feature1].Name;
   if (feature2 != -1 && (feature2 >= 0 || feature2 < notification_info._length())) {
      name :+= ' with 'notification_info[feature2].Name;
   }

   return name;
}

/**
 * Retrieves the description of a NotificationFeature.
 * 
 * @param feature                feature of interest (one of NotificationFeature 
 *                               enum)
 * 
 * @return                       description of this feature as it is displayed 
 *                               to the user
 */
_str getNotificationFeatureDescription(NotificationFeature feature)
{
   // make sure this is a valid feature
   if (feature < 0 || feature > notification_info._length()) return "";

   return notification_info[feature].Description;
}

/**
 * Retrieves the options information of a NotificationFeature.
 * 
 * @param feature                feature of interest (one of NotificationFeature 
 *                               enum)
 * 
 * @return                       options information of this feature (to be sent 
 *                               to the {@link config} command)
 */
void getNotificationFeatureOptionsInfo(NotificationFeature feature, _str &optionsCommand, _str &optionsArg1, _str &optionsArg2)
{
   optionsCommand = '';
   optionsArg1 = '';
   optionsArg2 = '';

   // make sure this is a valid feature
   if (feature < 0 || feature > notification_info._length()) return;

   optionsCommand = notification_info[feature].OptionsCommand;
   optionsArg1 = notification_info[feature].OptionsArgument1;
   optionsArg2 = notification_info[feature].OptionsArgument2;
}

/**
 * Retrieves the help information of a NotificationFeature.
 * 
 * @param feature                feature of interest (one of NotificationFeature 
 *                               enum)
 * 
 * @return                       help information of this feature (to be sent 
 *                               to the {@link help} command)
 */
_str getNotificationFeatureHelp(NotificationFeature feature)
{
   // make sure this is a valid feature
   if (feature < 0 || feature > notification_info._length()) return "";

   return notification_info[feature].HelpLink;
}

#endregion Notification Data

/**
 * Displays the notification nag dialog to alert the user that a feature did 
 * some (possibly unexpected) editing. 
 * 
 * @param feature                feature that happened
 */
static void displayNotificationDialog(NotificationFeature feature1, NotificationFeature feature2)
{
   // launch the nag dialog with the relevant info
   show('-modal _notification_nag_form', feature1, feature2);
}

defeventtab _notification_options_form;

#define     CURRENT_OPTIONS_FEATURE       _ctl_feature_combo.p_user
#define     ORIGINAL_SETTINGS             _ctl_feature_notification.p_user
#define     NEW_SETTINGS                  _ctl_notification_label.p_user
#define     ORIGINAL_RADIO                ctllabel1.p_user
#define     ORIGINAL_SAME_LEVEL           _ctl_notes_same.p_user

#region Options Dialog Helper Functions

void _notification_options_form_init_for_options(NotificationFeature feature = -1)
{
   maybePickFeatureToConfigure(feature);
}

void _notification_options_form_restore_state(NotificationFeature feature = -1)
{
   maybePickFeatureToConfigure(feature);
}

void _notification_options_form_save_settings()
{
   // save the current level settings for each one
   ORIGINAL_SETTINGS = NEW_SETTINGS;
   NEW_SETTINGS = null;

   // save which radio button is checked
   ORIGINAL_RADIO = getCurrentRadioSelection();

   if (_ctl_all_notification.p_enabled) {
      methodDesc := _ctl_all_notification.p_text;
      ORIGINAL_SAME_LEVEL = descriptionToNotificationMethod(methodDesc);
   } else {
      ORIGINAL_SAME_LEVEL = -1;
   }

   // we just do this so the current item will be saved
   NOTIFICATION_ACTION action = getCurrentFeatureAction();
}

boolean _notification_options_form_is_modified()
{
   // save the old feature settings
   saveCurrentFeatureSettings();

   // see if any of the check boxes differ from their original values
   if ((_ctl_back_proc_hide_icon.p_user != _ctl_back_proc_hide_icon.p_value) || 
       (_ctl_disable_back_proc_popups.p_user != _ctl_disable_back_proc_popups.p_value) ||
       (_ctl_feat_notify_hide_icon.p_user != _ctl_feat_notify_hide_icon.p_value) ||
       (_ctl_disable_feat_notify_popups.p_user != _ctl_disable_feat_notify_popups.p_value))
   {
      return true;
   }

   // see which radio button is checked
   curRadio := getCurrentRadioSelection();
   if (ORIGINAL_RADIO != curRadio && curRadio != 2) return true;

   // see if they have set the features to all be something new
   if (_ctl_all_notification.p_enabled) {
      methodDesc := _ctl_all_notification.p_text;
      sameMethod := descriptionToNotificationMethod(methodDesc);
      if (sameMethod != ORIGINAL_SAME_LEVEL) return true;
   } 

   // finally, see if the settings are changed
   if (NEW_SETTINGS != null && NEW_SETTINGS._length() != 0) return true;

   return false;
}

boolean _notification_options_form_apply()
{
   // save the options related to alerts
   SaveAlertOptions();

   // save the old feature settings
   saveCurrentFeatureSettings();

   if (_ctl_notes_same.p_value) {
      // set everything to whatever is specified
      methodDesc := _ctl_all_notification.p_text;
      setAllNotificationMethods(descriptionToNotificationMethod(methodDesc));
   } else {
      // we gotta set each and every one
      for (feature := 0; feature < notification_info._length(); feature++) {
         if (NEW_SETTINGS[feature] != null) {
            NOTIFICATION_ACTION action = NEW_SETTINGS[feature];
            setNotificationMethod(feature, action.Method);
            setLogNotification(feature, action.Log);
         }
      }
   }

   // we may need to set things anew
   if ((_ctl_feat_notify_hide_icon.p_value && 
        _ctl_feat_notify_hide_icon.p_value != _ctl_feat_notify_hide_icon.p_user) || 
        (_ctl_disable_feat_notify_popups.p_value &&
        _ctl_feat_notify_hide_icon.p_value != _ctl_feat_notify_hide_icon.p_user)) {

      // check each feature - it may need a reset
      for (feature := 0; feature < notification_info._length(); feature++) {
         method := getNotificationMethod(feature);
         newMethod := maybeGetNewMethod(method);
         if (method != newMethod) {
            setNotificationMethod(feature, newMethod);
         }
      }
   }

   refreshNotificationTree();

   return true;
}

#define HIDE_ICON_FOR_BACK_PROC "Hide icon for background process"
#define DISABLE_POPUPS_FOR_BACK_PROC "Disable pop-ups for background process"
#define HIDE_ICON_FOR_FEAT_NOTIFY "Hide icon for feature notifications"
#define DISABLE_POPUPS_FOR_FEAT_NOTIFY "Disable pop-ups for feature notifications"

#define EXPORT_NOTIFICATION_CAPTION    ' notifications'
#define EXPORT_LOG_CAPTION             'Log '

_str _notification_options_form_build_export_summary(PropertySheetItem (&table)[])
{
   PropertySheetItem psi;

   // store the rest
   for (feature := 0; feature < notification_info._length(); feature++) {
      level := getNotificationMethod(feature);
      name := getNotificationFeatureName(feature);

      psi.Caption  = name :+ EXPORT_NOTIFICATION_CAPTION;
      psi.Value = notificationMethodToDescription(level);
      table[table._length()] = psi;

      psi.Caption  = EXPORT_LOG_CAPTION :+ name;
      psi.Value = doLogNotification(feature);
      table[table._length()] = psi;
   }

   // export the alert options
   ALERT_GROUP_INFO alertGroupInfo;
   _GetAlertGroup(ALERT_GRP_BACKGROUND_ALERTS, alertGroupInfo);
   psi.Caption = HIDE_ICON_FOR_BACK_PROC;
   psi.Value = flipOptionValue(alertGroupInfo.Enabled);
   table[table._length()] = psi;
   psi.Caption = DISABLE_POPUPS_FOR_BACK_PROC;
   psi.Value = flipOptionValue(alertGroupInfo.ShowPopups);
   _GetAlertGroup(ALERT_GRP_EDITING_ALERTS, alertGroupInfo);
   table[table._length()] = psi;
   psi.Caption = HIDE_ICON_FOR_FEAT_NOTIFY;
   psi.Value = flipOptionValue(alertGroupInfo.Enabled);
   table[table._length()] = psi;
   psi.Caption = DISABLE_POPUPS_FOR_FEAT_NOTIFY;
   psi.Value = flipOptionValue(alertGroupInfo.ShowPopups);
   table[table._length()] = psi;

   return '';
}

static int flipOptionValue(int optionValue)
{
   int retVal = 0;
   if (optionValue == 0) {
      retVal = 1;
   }
   return retVal;
}

_str _notification_options_form_import_summary(PropertySheetItem (&table)[])
{
   // import the alert options
   int alertValues:[];
   for (i := 0; i < table._length(); i++) {
      _str caption = table[i].Caption;
      switch (caption) {
      case HIDE_ICON_FOR_BACK_PROC:
         alertValues:[HIDE_ICON_FOR_BACK_PROC] = flipOptionValue((int)(table[i].Value));
         break;
      case DISABLE_POPUPS_FOR_BACK_PROC:
         alertValues:[DISABLE_POPUPS_FOR_BACK_PROC] = flipOptionValue((int)(table[i].Value));
         break;
      case HIDE_ICON_FOR_FEAT_NOTIFY:
         alertValues:[HIDE_ICON_FOR_FEAT_NOTIFY] = flipOptionValue((int)(table[i].Value));
         break;
      case DISABLE_POPUPS_FOR_FEAT_NOTIFY:
         alertValues:[DISABLE_POPUPS_FOR_FEAT_NOTIFY] = flipOptionValue((int)(table[i].Value));
         break;
      default:
         // it's not one of the checkboxes, so it must be stuff for individual notifications
         methodItem := false;
         if (pos(EXPORT_LOG_CAPTION, caption) == 1) {
            caption = substr(caption, 1 + length(EXPORT_LOG_CAPTION));
         } else {
            caption = substr(caption, 1, length(caption) - length(EXPORT_NOTIFICATION_CAPTION));
            methodItem = true;
         }

         int feature = getNotificationFromName(caption);
         if (feature != -1) {
            if (methodItem) {
               methodDesc := table[i].Value;
               method := descriptionToNotificationMethod(methodDesc);
               setNotificationMethod(feature, method);
            } else {
               setLogNotification(feature, ((int)table[i].Value != 0));
            }
         }

         break;
      }
   }
   // now set the values (make sure we have all four)
   if (alertValues._length() == 4) {
      _SetAlertGroupStatus(ALERT_GRP_BACKGROUND_ALERTS, alertValues:[HIDE_ICON_FOR_BACK_PROC], alertValues:[DISABLE_POPUPS_FOR_BACK_PROC]);
      _SetAlertGroupStatus(ALERT_GRP_EDITING_ALERTS, alertValues:[HIDE_ICON_FOR_FEAT_NOTIFY], alertValues:[DISABLE_POPUPS_FOR_FEAT_NOTIFY]);
   }

   return '';
}

static int getNotificationFromName(_str name)
{
   for (i := 0; i < notification_info._length(); i++) {
      _str curName = notification_info[i].Name;
      if (stricmp(curName, name) == 0) {
         return i;
      }
   }
   return -1;
}

#endregion Options Dialog Helper Functions

void _notification_options_form.on_create()
{
   // prepare some blank arrays
   NOTIFICATION_ACTION origSettings[];
   NOTIFICATION_ACTION newSettings[];
   ORIGINAL_SETTINGS = origSettings;
   NEW_SETTINGS = newSettings;

   // populate the check boxes for showing/enabling status icons
   PopulateAlertOptions();
   populateMethodCombos();

   noteLevel := -1;
   matchSoFar := true;

   // go through each feature and determine the notification level, also load up the combo box
   NOTIFICATION_FEATURE_INFO info;
   for (feature := 0; feature < notification_info._length(); feature++) {
      // get the name, add it to the combo
      info = notification_info[feature];
      _ctl_feature_combo._lbadd_item(info.Name);

      // get the level
      thisLevel := getNotificationMethod(feature);
      if (matchSoFar) {
         if (noteLevel == -1) {
            noteLevel = thisLevel;
         } else if (noteLevel != thisLevel) {
            matchSoFar = false;
         }
      }
   }

   // sort the list of features
   _ctl_feature_combo._lbsort();
   _ctl_feature_combo._lbtop();
   _ctl_feature_combo._lbselect_line();
   _ctl_feature_combo.p_text = _ctl_feature_combo._lbget_text();

   if (matchSoFar) {
      _ctl_notes_same.p_value = 1;
      _ctl_all_notification._lbfind_and_select_item(notificationMethodToDescription(noteLevel), '', true);
   } else {
      _ctl_notes_specify.p_value = 1;
   }

   // help is a link, so make it look linkified
   _ctl_help_link.p_mouse_pointer = MP_HAND;
   _ctl_options_link.p_mouse_pointer = MP_HAND;
}

void _ctl_notes_specify.lbutton_up()
{
   enableDisableFeatureSettings();
}

void _ctl_notes_same.lbutton_up()
{
   enableDisableFeatureSettings();
}

static void enableDisableFeatureSettings()
{
   specify := (_ctl_notes_specify.p_value != 0);

   // enable these things if we are specifying individual values
   _ctl_feature_frame.p_enabled = specify;
   ctllabel1.p_enabled = specify;
   _ctl_feature_combo.p_enabled = specify;
   _ctl_notification_label.p_enabled = specify;
   _ctl_feature_notification.p_enabled = specify;
   _ctl_log_check.p_enabled = specify;
   _ctl_desc.p_enabled = specify;
   _ctl_options_link.p_enabled = specify;
   _ctl_help_link.p_enabled = specify;

   // enable this if we setting all features to one level
   _ctl_all_notification.p_enabled = !specify;
}

static void populateMethodCombos()
{
   // save the initial values
   initFeatMethod := -1;
   if (_ctl_feature_notification.p_text != '') {
      initFeatMethod = descriptionToNotificationMethod(_ctl_feature_notification.p_text);
   } 

   initAllMethod := -1;
   if (_ctl_all_notification.p_text != '')  {
      initAllMethod = descriptionToNotificationMethod(_ctl_all_notification.p_text);
   }

   // clear both first
   _ctl_feature_notification._lbclear();
   _ctl_all_notification._lbclear();

   // add our notification levels to the combo boxes
   for (method := 0; method < notification_method_labels._length(); method++) {
      // are we disabling all status icons?
      if (isMethodAvailable(method)) {
         methodLabel := notification_method_labels[method];
         _ctl_feature_notification._lbadd_item(methodLabel);
         _ctl_all_notification._lbadd_item(methodLabel);
      }

   }

   // now reload initial values (may have changed if we removed the selection from the list)
   if (initFeatMethod != -1) {
      initFeatMethod = maybeGetNewMethod(initFeatMethod);
      _ctl_feature_notification._lbfind_and_select_item(notificationMethodToDescription(initFeatMethod), '', true);
   } else {
      // just pick the top thing
      _ctl_feature_notification._lbtop();
      _ctl_feature_notification._lbselect_line();
      _ctl_feature_notification.p_text = _ctl_feature_notification._lbget_text();
   }

   if (initAllMethod != -1) {
      initAllMethod = maybeGetNewMethod(initAllMethod);
      _ctl_all_notification._lbfind_and_select_item(notificationMethodToDescription(initAllMethod), '', true);
   } else {
      _ctl_all_notification._lbtop();
      _ctl_all_notification._lbselect_line();
      _ctl_all_notification.p_text = _ctl_all_notification._lbget_text();
   }
}

static NotificationMethod maybeGetNewMethod(int curMethod)
{
   while (!isMethodAvailable(curMethod)) {
      curMethod++;
   }

   return curMethod;
}

static boolean isMethodAvailable(int method)
{
   if (_ctl_feat_notify_hide_icon.p_value) {
      if (method == NL_ALERT_WITH_TOAST || method == NL_ALERT_NO_TOAST) {
         return false;
      }
   } else if (_ctl_disable_feat_notify_popups.p_value) {
      if (method == NL_ALERT_WITH_TOAST) {
         return false;
      }
   } 

   return true;
}

static void maybePickFeatureToConfigure(NotificationFeature feature)
{
   // if a feature is sent in, we may want to select it
   if (feature >= 0) {
      // only do this if the levels are not all the same
      if (_ctl_notes_specify.p_value) {
         _ctl_feature_combo._lbfind_and_select_item(getNotificationFeatureName(feature), '', true);
      }
   }
}

static int getCurrentRadioSelection()
{
   selection := -1;
   // save which ardio button is checked
   if (_ctl_notes_same.p_value) {
      selection = 1;
   } else {
      selection = 2;
   }

   return selection;
}

void _ctl_disable_all_popups.lbutton_up()
{
   if (_ctl_disable_all_popups.p_value == 0) {
      _ctl_disable_back_proc_popups.p_value = 0;
      _ctl_disable_feat_notify_popups.p_value = 0;
   } else if (_ctl_disable_all_popups.p_value == 1) {
      _ctl_disable_back_proc_popups.p_value = 1;
      _ctl_disable_feat_notify_popups.p_value = 1;
   }

   populateMethodCombos();
}

void _ctl_back_proc_hide_icon.lbutton_up()
{
   syncAlertCheckBoxStates();
}

void _ctl_disable_back_proc_popups.lbutton_up()
{
   syncAlertCheckBoxStates();
}

void _ctl_feat_notify_hide_icon.lbutton_up()
{
   syncAlertCheckBoxStates();
   populateMethodCombos();
}

void _ctl_disable_feat_notify_popups.lbutton_up()
{
   syncAlertCheckBoxStates();
   populateMethodCombos();
}

static void syncAlertCheckBoxStates()
{
   if ((_ctl_disable_back_proc_popups.p_value == 0) && (_ctl_disable_feat_notify_popups.p_value == 0)) {
      _ctl_disable_all_popups.p_value = 0;
   } else if ((_ctl_disable_back_proc_popups.p_value == 1) && (_ctl_disable_feat_notify_popups.p_value == 1)) {
      _ctl_disable_all_popups.p_value = 1;
   } else  {
      _ctl_disable_all_popups.p_value = 2;
   }
   _ctl_disable_back_proc_popups.p_enabled = (_ctl_back_proc_hide_icon.p_value == 0);
   _ctl_disable_feat_notify_popups.p_enabled = (_ctl_feat_notify_hide_icon.p_value == 0);
}

void _ctl_feature_combo.on_change(int reason)
{
   // save the old feature settings
   saveCurrentFeatureSettings();

   // get the feature name
   featureName := _ctl_feature_combo.p_text;

   // which enum is this?
   feature := getNotificationFeatureByName(featureName);
   if (feature >= 0) {
      CURRENT_OPTIONS_FEATURE = feature;
      loadFeatureInfo();
   } else {
      CURRENT_OPTIONS_FEATURE = 0;
   }
}

/**
 * Populates all options related to the status icon alerts.
 */
static void PopulateAlertOptions()
{
   ALERT_GROUP_INFO alertGroupInfo;
   _GetAlertGroup(ALERT_GRP_BACKGROUND_ALERTS, alertGroupInfo);
   _ctl_back_proc_hide_icon.p_value = (int)(alertGroupInfo.Enabled == 0);
   _ctl_back_proc_hide_icon.p_user = _ctl_back_proc_hide_icon.p_value;
   _ctl_disable_back_proc_popups.p_value = (int)(alertGroupInfo.ShowPopups == 0);
   _ctl_disable_back_proc_popups.p_user = _ctl_disable_back_proc_popups.p_value;
   _GetAlertGroup(ALERT_GRP_EDITING_ALERTS, alertGroupInfo);
   _ctl_feat_notify_hide_icon.p_value = (int)(alertGroupInfo.Enabled == 0);
   _ctl_feat_notify_hide_icon.p_user = _ctl_feat_notify_hide_icon.p_value;
   _ctl_disable_feat_notify_popups.p_value = (int)(alertGroupInfo.ShowPopups == 0);
   _ctl_disable_feat_notify_popups.p_user = _ctl_disable_feat_notify_popups.p_value;
   syncAlertCheckBoxStates();
}

/**
 * Saves all options related to the status icon alerts.
 */
static void SaveAlertOptions()
{
   int enabled = 1;
   if (_ctl_back_proc_hide_icon.p_value) {
      enabled = 0;
   }
   int showPopup = 1;
   if (_ctl_disable_back_proc_popups.p_value) {
      showPopup = 0;
   }
   _SetAlertGroupStatus(ALERT_GRP_BACKGROUND_ALERTS, enabled, showPopup);
   enabled = 1;
   if (_ctl_feat_notify_hide_icon.p_value) {
      enabled = 0;
   }
   showPopup = 1;
   if (_ctl_disable_feat_notify_popups.p_value) {
      showPopup = 0;
   }
   _SetAlertGroupStatus(ALERT_GRP_EDITING_ALERTS, enabled, showPopup);
}

static void saveCurrentFeatureSettings()
{
   if (CURRENT_OPTIONS_FEATURE >= 0 && _ctl_feature_combo.p_enabled) {
      NotificationMethod method;
      
      methodDesc := _ctl_feature_notification.p_text;
      newMethod := descriptionToNotificationMethod(methodDesc);
      
      newLog := (_ctl_log_check.p_value != 0);

      NOTIFICATION_ACTION origAction = ORIGINAL_SETTINGS[CURRENT_OPTIONS_FEATURE];

      // only save it if it's different
      if (origAction.Method != newMethod || origAction.Log != newLog) {
         NOTIFICATION_ACTION action;
         action.Method = newMethod;
         action.Log = newLog;
         NEW_SETTINGS[CURRENT_OPTIONS_FEATURE] = action;
      }
   }
}

static NOTIFICATION_ACTION getCurrentFeatureAction()
{
   NOTIFICATION_ACTION action;

   if (NEW_SETTINGS != null && NEW_SETTINGS[CURRENT_OPTIONS_FEATURE] != null) {
      action = NEW_SETTINGS[CURRENT_OPTIONS_FEATURE];
   } else if (ORIGINAL_SETTINGS != null && ORIGINAL_SETTINGS[CURRENT_OPTIONS_FEATURE] != null) {
      action = ORIGINAL_SETTINGS[CURRENT_OPTIONS_FEATURE];
   } else {
      // settings for this feature have not yet been loaded, load them now

      // what's the notification level?
      method := getNotificationMethod(CURRENT_OPTIONS_FEATURE);
      if (method < 0) method = NL_NONE;
      action.Method = method;
 
      action.Log = doLogNotification(CURRENT_OPTIONS_FEATURE);
       
      // save this info in our original settings
      ORIGINAL_SETTINGS[CURRENT_OPTIONS_FEATURE] = action;
   } 

   return action;
}

static void loadFeatureInfo()
{
   if (CURRENT_OPTIONS_FEATURE >= 0) {

      // load up the description
      _ctl_desc.p_caption = getNotificationFeatureDescription(CURRENT_OPTIONS_FEATURE);

      featureName := _ctl_feature_combo.p_text;
      _ctl_help_link.p_caption = featureName' Help';
      _ctl_options_link.p_caption = featureName' Options';

      // what's the notification level?
      NOTIFICATION_ACTION action = getCurrentFeatureAction();
      _ctl_feature_notification._lbfind_and_select_item(notificationMethodToDescription(action.Method), '', true);
      _ctl_log_check.p_value = (int)action.Log;
   }
}

void _ctl_help_link.lbutton_up()
{
   help(getNotificationFeatureHelp(CURRENT_OPTIONS_FEATURE));
}

void _ctl_options_link.lbutton_up()
{
   configure_notification_feature(CURRENT_OPTIONS_FEATURE);
}

defeventtab _notification_nag_form;

#define CURRENT_NAG_DIALOG_FEATURE        _ctl_ok_btn.p_user

void _ctl_ok_btn.on_create(NotificationFeature feature1, NotificationFeature feature2 = -1)
{
   CURRENT_NAG_DIALOG_FEATURE = feature1;

   featureName := getNotificationFeatureName(feature1, feature2);

   // load up the information on this feature
   _ctl_name_lbl.p_caption = "Feature : "featureName;
   _ctl_desc_lbl.p_caption = getNotificationFeatureDescription(feature1);

   resizeLabel(_ctl_name_lbl, 'd');
   resizeLabel(_ctl_desc_lbl, 'd');

   _ctl_configure_link.p_mouse_pointer = MP_HAND;
}

void _notification_nag_form.ESC()
{
   closeNag();
}

#define LINE_HEIGHT        255

void resizeLabel(int label, _str expandDirection, boolean doShrink = true)
{
   expandDirection = lowcase(expandDirection);

   // save original values
   origWidth := label.p_width;
   origHeight := label.p_height;
   origX := label.p_x;
   origY := label.p_y;
   label.p_auto_size = true;

   // calculate area
   area := label.p_height * label.p_width;

   // reset label back to originals
   label.p_auto_size = false;
   label.p_width = origWidth;
   label.p_height = origHeight;
   label.p_x = origX;
   label.p_y = origY;

   if (expandDirection == 'u' || expandDirection == 'd') {
      // get the height necessary to show this help info - we are expanding the height
      reqHeight := ceiling((double)area / (double)origWidth);
      numLines := ceiling((double)reqHeight / (double)LINE_HEIGHT);
      reqHeight = numLines * LINE_HEIGHT;
   
      // make any necessary adjustments
      heightDiff := reqHeight - origHeight;
      if (heightDiff > 0 || (heightDiff < 0 && doShrink)) {
         label.p_height = reqHeight;
         p_active_form.p_height += heightDiff;
   
         // if we are going up, we need to move the label up
         if (expandDirection == 'u') label.p_y -= heightDiff;
            
         // move the other controls to make room
         wid := label.p_next;
         while (wid != label) {

            if (expandDirection == 'u') {
               // only move things with a lower p_y - that means they are higher up
               if (wid.p_y <= origY) {
                  wid.p_y -= heightDiff;
               }
            } else {
               // only move things with a higher p_y - that means they are lower down
               if (wid.p_y > origY) {
                  wid.p_y += heightDiff;
               }
            }
  
            wid = wid.p_next;
         }
      } 
   } else if (expandDirection == 'l' || expandDirection == 'r') {
      reqWidth := ceiling((double)area / (double)origHeight);

      // make the necessary adjustments
      widthDiff := reqWidth - origWidth;
      if (widthDiff > 0 || (widthDiff < 0 && doShrink)) {
         label.p_width = reqWidth;
         p_active_form.p_width += widthDiff;

         // if we are expanding out to the left, we need to move the label over
         if (expandDirection == 'l') label.p_x -= widthDiff;

         // move the other controls to make room
         wid := label.p_next;
         while (wid != label) {

            if (expandDirection == 'l') {
               // only move things with a lower p_x - that means they are farther left
               if (wid.p_x <= origX) {
                  wid.p_x -= widthDiff;
               }
            } else {
               // only move things with a higher p_y - that means they are lower down
               if (wid.p_x > origX) {
                  wid.p_x += widthDiff;
               }
            }
  
            wid = wid.p_next;
         }
      }
   }
}

void _ctl_ok_btn.lbutton_up()
{
   closeNag();
}

void _ctl_help_btn.lbutton_up()
{
   show_help_for_notification_feature(CURRENT_NAG_DIALOG_FEATURE);
}

void _ctl_options_btn.lbutton_up()
{
   currentFeature := CURRENT_NAG_DIALOG_FEATURE;

   closeNag();
   configure_notification_feature(currentFeature);
}

void _ctl_configure_link.lbutton_up()
{
   currentFeature := CURRENT_NAG_DIALOG_FEATURE;

   closeNag();
   config('Notifications', 'N', currentFeature);
}

static void closeNag()
{
   if (!_ctl_nag_chbx.p_value) {
      // make sure this is set to the DIALOG value
      setNotificationMethod(CURRENT_NAG_DIALOG_FEATURE, NL_DIALOG);
   } else {
      // mark this down to the MESSAGE level
      setNotificationMethod(CURRENT_NAG_DIALOG_FEATURE, NL_MESSAGE);
   }

   p_active_form._delete_window();
}
