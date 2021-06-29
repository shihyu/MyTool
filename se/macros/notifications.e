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
#include "alerts.sh"
#include "xml.sh"
#import "cfg.e"
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

const NF_ADAPTIVE_FORMATTING= ALERT_ADAPTIVE_FORMATTING;
const NF_ALIAS_EXPANSION= ALERT_ALIAS_EXPANSION;
const NF_AUTO_SYMBOL_TRANSLATION= ALERT_AUTO_SYMBOL_TRANSLATION;
const NF_COMMENT_WRAP= ALERT_COMMENT_WRAP;
const NF_DOC_COMMENT_EXPANSION= ALERT_DOC_COMMENT_EXPANSION;
const NF_DYNAMIC_SURROUND= ALERT_DYNAMIC_SURROUND;
const NF_HTML_XML_FORMATTING= ALERT_HTML_XML_FORMATTING;
const NF_INSERT_RIGHT_BRACKET= ALERT_INSERT_RIGHT_BRACKET;
const NF_INSERT_MATCHING_PARAMETERS= ALERT_INSERT_MATCHING_PARAMETERS;
const NF_SMART_PASTE= ALERT_SMART_PASTE;
const NF_SYNTAX_EXPANSION= ALERT_SYNTAX_EXPANSION;
const NF_AUTO_CLOSE_VISITED_FILE= ALERT_AUTO_CLOSE;
const NF_AUTO_CASE_KEYWORD= ALERT_AUTO_CASE_KEYWORD;
const NF_AUTO_CLOSE_COMPLETION= ALERT_AUTO_CLOSE_COMPLETIONS;
const NF_AUTO_LIST_MEMBERS= ALERT_AUTO_LIST_MEMBERS;
const NF_AUTO_DISPLAY_PARAM_INFO= ALERT_AUTO_DISPLAY_PARAM_INFO;
const NF_AUTO_LIST_COMPATIBLE_PARAMS= ALERT_AUTO_LIST_COMPATIBLE_PARAMS;
const NF_AUTO_LIST_COMPATIBLE_VALUES= ALERT_AUTO_LIST_COMPATIBLE_VALUES;
const NF_LARGE_FILE_EDITING= ALERT_LARGE_FILE_SUPPORT;
const NF_AUTO_DOT_FOR_DASHGT= ALERT_AUTO_DOT_FOR_DASHGT;
const NF_AUTO_XML_VALIDATION= ALERT_AUTO_XML_VALIDATION;


static _str notification_method_labels[] = _reinit {
   "Dialog",
   "Status line icon with pop-up",
   "Status line icon, no pop-up",
   "Message line",
   "None",
};

struct NOTIFICATION_ACTION {
   NotificationMethod Method;
   bool Log;
};
//NOTIFICATION_ACTION def_notification_actions[];

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
   _str AlertGroupID;
   NotificationFeature Feature;
   _str FeatureName;
   _str Timestamp;
   _str Filename;
   int LineNumber;
   NotificationFeature SecondFeature;
   _str SecondFeatureName;
   int LogCount; // Number of times this feature notification occurred since log cleared.
};


#if 0
static NOTIFICATION_FEATURE_INFO notification_info[]= _reinit {
   {"Adaptive Formatting", "Adaptive Formatting scans your file for you to determine which coding styles are in use in the current file.  These style settings are then used so that your new code will match the existing coding style of the file.", "Adaptive Formatting", "config", "Adaptive Formatting", "L", ALERT_ADAPTIVE_FORMATTING},
   {"Auto-Alias Expansion", "If you type an alias identifier and press space, that alias is automatically expanded for you.", "Language-Specific Aliases", "config", "Aliases", "L", ALERT_ALIAS_EXPANSION},
   {"Auto Symbol Translation", "Auto Symbol Translation automatically converts a character or sequence of characters to the appropriate entity reference, saving you from having to repeatedly guess at the correct entity or look up reference charts. ", "Auto Symbol Translation", "config", "Formatting", "L", ALERT_AUTO_SYMBOL_TRANSLATION},
   {"Comment Wrap", "Comments are automatically wrapped to the next line as you type, eliminating the need to constantly reformat your comments manually.", "Comment Wrapping", "config", "Comment Wrap", "L", ALERT_COMMENT_WRAP},
   {"Doc Comment Expansion", "When you type the start characters for one of certain comment formats and press Enter on a line directly above a function, class, or variable, SlickEdit automatically inserts a skeleton doc comment for that style.", "Doc Comments", "config", "Comments", "L", ALERT_DOC_COMMENT_EXPANSION},
   {"Dynamic Surround", "Dynamic Surround provides a convenient way to surround a group of statements with a block statement, indented to the correct levels according to your preferences.  SlickEdit enters Dynamic Surround mode automatically after you expand a block statement.  A box is drawn as a visual guide, and you can pull the subsequent lines of code or whole statements into the block by using the Up, Down, PgUp, or PgDn keys.  Dynamic Surround stays active until you press ESC.", "Dynamic Surround", "config", "Auto-Complete", "L", ALERT_DYNAMIC_SURROUND},
   {"XML/HTML Formatting", "Content in XML and HTML files may be set to automatically wrap and format as you edit. XML/HTML Formatting is essentially comprised of two features: Content Wrap, which wraps the content between tags, and Tag Layout, which formats tags according to a specified layout.", "XML/HTML Formatting", "config", "Formatting", "L", ALERT_HTML_XML_FORMATTING},
   {"Auto-Insert >", "You can type the open brace of a start tag (<), and SlickEdit automatically inserts the closing brace (>) while leaving the cursor positioned between the braces, ready for you to type the tag.", "HTML Formatting", "config", "Formatting", "L", ALERT_INSERT_RIGHT_BRACKET},
   {"Auto-Insert Matching Parameters", "When parameter information is displayed and the name of the current formal parameter matches the name of a symbol in the current scope of the appropriate type or class, the name is automatically inserted. ", "Context Tagging Options (Language-Specific)", "config", "Context Tagging®":+VSREGISTEREDTM, "L", ALERT_INSERT_MATCHING_PARAMETERS},
   {"SmartPaste", "When pasting lines of text into a source file, SmartPaste reindents the added lines according to the surrounding code.", "SmartPaste", "config", "General", "L", ALERT_SMART_PASTE},
   {"Syntax Expansion", "Syntax Expansion is a feature designed to minimize keystrokes, increasing your code editing efficiency.  When you type certain keywords and then press the space bar or Enter key, Syntax Expansion inserts a default template that is specifically designed for this statement.", "Syntax Expansion", "config", "Auto-Complete", "L", ALERT_SYNTAX_EXPANSION},
   {"Auto-Close Visited File", "When a file is opened as a result of a symbol navigation or search operation, but not modified, it can be closed automatically after navigating away from it.", "Automatically close visited files", "config", "Bookmarks", "", ALERT_AUTO_CLOSE},
   {"Auto Case Keywords", "When a keyword is typed in a case-insensitive language, SlickEdit will modify the case of the keyword as you type the last letter.", "Auto case keywords", "config", "Formatting", "L", ALERT_AUTO_CASE_KEYWORD},
   {"Auto-Close Completion", "Auto-Close inserts matching closing punctuation when opening punctuation is entered.", "Auto-Close Options (Language-Specific)", "config", "Auto-Close", "L", ALERT_AUTO_CLOSE_COMPLETIONS},
   {"Auto-List Members", "Typing a member access operator (e.g. \".\" or \"->\" in C++) will trigger SlickEdit to display a list of the members for the corresponding type. ", "List Members", "config", "Context Tagging®", "L", ALERT_AUTO_LIST_MEMBERS},
   {"Auto-Display Parameter Information", "The prototype and comments for a function are automatically displayed when a function operator such as the open parenthesis is typed, and the current argument is highlighted within the displayed prototype.", "Parameter Information", "config", "Context Tagging®", "L", ALERT_AUTO_DISPLAY_PARAM_INFO},
   {"Auto-List Compatible Parameters", "Compatible variables are automatically listed when you are typing the arguments to a function call. ", "Auto List Compatible Parameters", "config", "Context Tagging®", "L", ALERT_AUTO_LIST_COMPATIBLE_PARAMS},
   {"Auto-List Compatible Values", "Compatible variables are automatically listed when you are typing the right hand side of an assignment statement. ", "Auto List Compatible Values", "config", "Context Tagging®", "L", ALERT_AUTO_LIST_COMPATIBLE_VALUES},
   {"Large File Editing", "SlickEdit can edit files up to 2000GB in size by reading the file block-by-block instead of reading the entire file.", "Load partially for large files", "config", "Load", "", ALERT_LARGE_FILE_SUPPORT},
};
#endif

static NOTIFICATION_INFO gLogInfo:[];

definit()
{
   gLogInfo=null;
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
   // Don't bother converting the old def_warn_adaptive_formatting and def_nag_xxx variables.
#if 0
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
#endif
}


#region Notification API
// Use these methods to tell the user that the application has does 
// something neat that they might want to know about

/**
 * Alerts the user that an automatic feature has been used.  Determines which
 * notification method to use.
 * 
 * @param feature1      feature that was used (One of the NotificationFeature enums)
 * @param filename      file that feature usage occured in
 * @param lineNumber    line number that feature usage occured at
 * @param feature2      secondary feature that was involved
 * @param msg           message describing what feature did
 */
void notifyUserOfFeatureUse(NotificationFeature feature1, 
                            _str filename = p_buf_name, int lineNumber = p_line, 
                            NotificationFeature feature2 = "", _str msg = '')
{
   if (_MultiCursor()) return;
   // make sure this is a valid feature
   if (feature2==-1) feature2="";
   ALERT_INFO alertInfo1;
   _GetAlert(ALERT_GRP_EDITING_ALERTS,feature1,alertInfo1);
   if (alertInfo1._isempty()) return;
   ALERT_INFO alertInfo2;
   if (feature2 != "") {
      _GetAlert(ALERT_GRP_EDITING_ALERTS,feature2,alertInfo2);
      if (alertInfo2._isempty()) return;
   }
   if (!_MultiCursorLastLoopIteration()) {
      return;
   }
   // This is the last multi cursor loop iteration or we are not in a multi cursor loop.

   // determine which method of notifying the user we want to use
   method := 0;
   if (feature2 == "") {
      // only one feature to worry about here
      method = alertInfo1.Method;
   } else {
      // we want to use the more noticeable of the two features (which means the lower value enum)
      method1 := alertInfo1.Method;
      method2 := alertInfo2.Method;
      method = (method1 > method2) ? method2 : method1;
   }

   NOTIFICATION_INFO info;
   info.AlertGroupID = ALERT_GRP_EDITING_ALERTS;
   info.Feature = feature1;
   info.FeatureName= alertInfo1.Name;
   info.Timestamp = _time('F');
   info.Filename = filename;
   info.LineNumber = lineNumber;
   info.SecondFeature = feature2;
   info.SecondFeatureName= (feature2=="")? '':alertInfo2.Name;
   info.LogCount=1;

   // compare this item to the most recent one in the log - make sure they are not the same
   if (!hasBeenRecentlyLogged(info)) {
   
      // get our notification message
      if (msg == '') msg = getNotificationEventMessage(info);

      // now, what do we do?
      switch (method) {
      case NL_DIALOG:
         if (alertInfo1.AllowDialogMethod) {
            displayNotificationDialog(ALERT_GRP_EDITING_ALERTS, feature1, feature2);
         }
         break;
      case NL_ALERT_WITH_TOAST:
      case NL_ALERT_NO_TOAST:
         alertId := alertInfo1.AlertID;
         if (alertId != "") {
            _ActivateAlert(ALERT_GRP_EDITING_ALERTS, alertId, msg, '', (int)(method == NL_ALERT_WITH_TOAST));
         }
         break;
      case NL_MESSAGE:
         helpInfo := getNotificationEventHelp(info.AlertGroupID, info.Feature);
         msg :+= '  Search the help for 'helpInfo' for more information.';

         // show a message for the user to see/ignore
         message(msg);
         break;
      }
   }

   // we always log this info in the log file
   addNotificationToLog(info);
   if (alertInfo1.Log || (feature2!="" && alertInfo2.Log)) refreshNotificationTree();
}

/**
 * Alerts the user that an warning happened.
 * Determines which notification method to use.
 * 
 * @param warning       warning that occured 
 *                      (One of the NotificationFeature enums)
 * @param msg           message to display along with warning
 * @param filename      file name that warning is associated with
 * @param lineNumber    line number that warning is associated with 
 * @param quiet         just log warning, do not show alerts or messages 
 */
void notifyUserOfWarning(NotificationFeature warning, _str msg,
                         _str filename, int lineNumber=0, bool quiet=false) 
{
   // This is the last multi cursor loop iteration or we are not in a multi cursor loop.
   if (!_MultiCursorLastLoopIteration()) {
      return;
   }

   // make sure this is a valid warning notification
   ALERT_INFO alertInfo1;
   _GetAlert(ALERT_GRP_WARNING_ALERTS,warning,alertInfo1);
   if (alertInfo1._isempty()) return;

   // set up notification information for logging
   NOTIFICATION_INFO info;
   info.AlertGroupID = ALERT_GRP_WARNING_ALERTS;
   info.Feature = warning;
   info.FeatureName= alertInfo1.Name;
   info.Timestamp = _time('F');
   info.Filename = filename;
   info.LineNumber = lineNumber;
   info.SecondFeature = "";
   info.SecondFeatureName= "";
   info.LogCount=1;

   // compare this item to the most recent one in the log - make sure they are not the same
   if (!quiet && !hasBeenRecentlyLogged(info)) {
   
      // get our notification message
      if (msg == '') msg = getNotificationEventMessage(info);

      // now, what do we do?
      method := alertInfo1.Method;
      switch (method) {
      case NL_DIALOG:
         if (alertInfo1.AllowDialogMethod) {
            displayNotificationDialog(ALERT_GRP_WARNING_ALERTS, warning, "");
         }
         break;
      case NL_ALERT_WITH_TOAST:
      case NL_ALERT_NO_TOAST:
         alertId := alertInfo1.AlertID;
         if (alertId != "") {
            _ActivateAlert(ALERT_GRP_WARNING_ALERTS, alertId, msg, '', (int)(method == NL_ALERT_WITH_TOAST));
         }
         break;
      case NL_MESSAGE:
         helpInfo := getNotificationEventHelp(info.AlertGroupID, info.Feature);
         if (helpInfo != "") {
            msg :+= '  Search the help for 'helpInfo' for more information.';
         }
         // show a message for the user to see/ignore
         if (msg != "") {
            message(msg);
         }
         break;
      }
   }

   // we always log this info in the log file
   addNotificationToLog(info);
   if (alertInfo1.Log) {
      refreshNotificationTree();
   }
}

/** 
 * @return 
 * Get the notification event message for the given notification.
 * 
 * @param info    notification information
 */
_str getNotificationEventMessage(NOTIFICATION_INFO &info)
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
      text = getNotificationEventName(info.AlertGroupID, info.Feature, info.SecondFeature,info.FeatureName,info.SecondFeatureName)' has been performed.';
      break;
   }

   return text;
}

/**
 * @return 
 * Return the syntax expansion notification message for the given word. 
 * 
 * @param word   keyword that was expanded using syntax expansion
 */
_str getSyntaxExpansionNotificationMessage(_str word)
{
   if (word != '') {
      return 'Syntax Expansion has expanded "'word'".';
   }
   
   return getNotificationEventName(ALERT_GRP_EDITING_ALERTS, NF_SYNTAX_EXPANSION)' has been performed.';;
}

/** 
 * @return 
 * Retrieves the current mechanism used to notify the user that an automatic
 * feature has run.
 * 
 * @param alertGroupId  kind of notification alert (feature, warning, etc., ALERT_GRP_*)
 * @param feature       feature that was used (one of the NotificationFeature enums)
 */
NotificationMethod getNotificationMethod(_str alertGroupId, NotificationFeature feature)
{
   if (alertGroupId == "") alertGroupId = ALERT_GRP_EDITING_ALERTS;
   ALERT_INFO alertInfo1;
   _GetAlert(alertGroupId,feature,alertInfo1);
   if (alertInfo1._isempty()) return NL_NONE;

   return alertInfo1.Method;
}

/**
 * Sets the notification level for the given NotificationFeature, provided that
 * level is allowed for that feature.  Some features may not allow the level of
 * NM_DIALOG because a dialog would mess with the usability of the feature.
 * 
 * @param alertGroupId  kind of notification alert (feature, warning, etc., ALERT_GRP_*)
 * @param feature       feature that was used (one of the NotificationFeature enums)
 * @param method        notification method (dialog, message, alert, ..., NL_*)
 */
void setNotificationMethod(_str alertGroupId, NotificationFeature feature, NotificationMethod method)
{
   // we do not allow this case - a dialog would really screw up dynamic surround
   if (feature == NF_DYNAMIC_SURROUND && method == NL_DIALOG) return;
   ALERT_INFO alertInfo1;
   alertInfo1.Method=method;
   _SetAlert(alertGroupId,feature,alertInfo1);
}

/**
 * Sets whether we add an entry to the notification log for this kind of feature.
 * 
 * @param alertGroupId  kind of notification alert (feature, warning, etc., ALERT_GRP_*)
 * @param feature       feature that was used (one of the NotificationFeature enums)
 * @param doLog         true if we log this feature, false otherwise
 */
void setLogNotification(_str alertGroupId, NotificationFeature feature, bool doLog)
{
   if (alertGroupId == "") alertGroupId = ALERT_GRP_EDITING_ALERTS;
   ALERT_INFO alertInfo1;
   alertInfo1.Log=doLog;
   _SetAlert(alertGroupId,feature,alertInfo1);
}

/**
 * Sets the notification level for every Notification Feature in the given 
 * group to the same value, provided that level is allowed for that feature.
 * 
 * @param alertGroupId  kind of notification alert (feature, warning, etc., ALERT_GRP_*)
 * @param method        notification method (dialog, message, alert, ..., NL_*)
 */
void setAllNotificationMethods(_str alertGroupId, NotificationMethod method)
{
   if (alertGroupId == "") alertGroupId = ALERT_GRP_EDITING_ALERTS;
   _str alertid_list[];
   _plugin_list_profiles(vsCfgPackage_for_NotificationGroup(alertGroupId),alertid_list);
   // store the rest
   for (i := 0; i < alertid_list._length(); ++i) {
      _str feature=alertid_list[i];
      setNotificationMethod(alertGroupId, feature, method);
   }
}

/** 
 * @return 
 * Returns the description for the given NotificationLevel.  Used to translate 
 * notification levels to strings for displaying to the user. 
 * 
 * @param level            level to translate
 */
static _str notificationMethodToDescription(NotificationMethod method)
{
   return notification_method_labels[method];
}

/** 
 * @return 
 * Returns the NotificationLevel associated with the given text description.
 * 
 * @param description            level description
 */
static NotificationMethod descriptionToNotificationMethod(_str description)
{
   foreach (auto method => auto desc in notification_method_labels) {
      if (desc == description) return method;
   }

   return NL_NONE;
}

#endregion Notification API

#region Notification Log

void _before_write_state_notifications_log() {
   gLogInfo=null;
}
static _str makeLogKey(NOTIFICATION_INFO &info) {
   return info.AlertGroupID"\t"info.Feature"\t"info.SecondFeature;
}

/**
 * Adds a notification to our notification log.  If this is the first 
 * notification to be logged, creates and opens up the log file. 
 * 
 * @param feature             feature to be logged
 * 
 * @return                    0 for success, negative error code for failure
 */
static void addNotificationToLog(NOTIFICATION_INFO info)
{
   _str key=makeLogKey(info);
   NOTIFICATION_INFO *pinfo=gLogInfo._indexin(key);
   if (!pinfo) {
      info.LogCount=1;
      gLogInfo:[key]=info;
   } else {
      *pinfo=info;
      ++pinfo->LogCount;
   }
}

/**
 * Determines if the given notification has already been logged.  A notification 
 * is determined to be already logged if another notification with the same 
 * feature and filename has been logged within the last second. 
 *  
 * @param info                Notification to look for
 * 
 * @return bool               true if the notification has already been logged, 
 *                            false otherwise
 */
static bool hasBeenRecentlyLogged(NOTIFICATION_INFO &info)
{
   do {
      // we only check on this for certain features that could potentially be very noisy
      if (info.Feature != NF_COMMENT_WRAP && info.Feature != NF_HTML_XML_FORMATTING) break;

      NOTIFICATION_INFO *plastinfo=gLogInfo._indexin(makeLogKey(info));
      if (!plastinfo) break;   // Nothing already log recently

      // for these to be considered the same, the feature, filename, and time have to match
      if (info.Filename != plastinfo->Filename) break;
      DateTime lastdt();
      lastdt = DateTime.fromTimeF(plastinfo->Timestamp);
      lastdt = lastdt.add(5, DT_SECOND);
      if ((long)lastdt.toTimeF() < (long)info.Timestamp) {
         // This occurred more than 5 seconds ago
         //say(lastdt.toTimeF()' 'info.Timestamp);
         //say('diff='((long)lastdt.toTimeF()-(long)info.Timestamp));
         break;
      }
      //say('occurred recently');
         
      return true;

   } while (false);

   return false;
}

/**
 * Merges the current notification log into the cumulative notification log for 
 * the editor.  The current log is only for this session.  So that it does not 
 * become too big, we limit it to a certain size ( 
 * 
 * 
 * @param mergeAll 
 */
void mergeNotificationLog(bool mergeAll) {
   if (mergeAll) {
      gLogInfo=null;
   }
}


/**
 * Retrieves the most recent Notifications in an array.
 * 
 * @param log                 array to put Notifications in
 * @param num                 number of notifications to include
 */
void getNotificationLogArray(NOTIFICATION_INFO (&log)[], int num)
{
   log=null;

   NOTIFICATION_INFO v;
   _str key;
   _str list[];  // List that will be sorted
   foreach (key => v in gLogInfo) {
      _str line;
      line=v.Timestamp"\t"v.Feature"\t"v.LineNumber"\t"v.SecondFeature"\t"v.LogCount"\t"v.Filename"\t"v.AlertGroupID;
      list[list._length()]=line;
   }
   list._sort('D');
   i := 0;
   for (i=0;i<list._length();++i) {
      if (i<num) {
         _str strLineNumber;
         _str strLogCount;
         parse list[i] with v.Timestamp"\t"v.Feature"\t"strLineNumber"\t"v.SecondFeature"\t"strLogCount"\t"v.Filename"\t"v.AlertGroupID;
         v.LineNumber=(int)strLineNumber;
         v.LogCount=(int)strLogCount;
         log[log._length()]=v;
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
static _str getNotificationFeatureByName(ALERT_INFO (&alerts):[],_str featureName)
{
   // get just the feature name part
   parse featureName with . ':' auto justFeatureName;
   justFeatureName = strip(justFeatureName);

   // go through the list of features and see which one has the matching name
   ALERT_INFO info;
   foreach (auto feature => info in alerts) {
      if (info.Name == justFeatureName && info.AlertGroupID != "") {
         thisFeatureName := getNotificationTypeAndEventName(info.AlertGroupID, info.AlertID);
         if (thisFeatureName == featureName) {
            return feature;
         }
      }
   }
   // did not find it, look using a more relaxed technique
   parse featureName with . ':' featureName;
   foreach (feature => info in alerts) {
      if (info.Name == justFeatureName) {
         return feature;
      }
   }

   return '';
}

/** 
 * @return 
 * Retrieves the display name of a NotificationFeature.
 * 
 * @param alertGroupId  kind of notification alert (feature, warning, etc., ALERT_GRP_*)
 * @param feature1      feature that was used (one of the NotificationFeature enums)
 * @param feature2      secondary feature that was involved (optional) 
 * @param name1         name of feature1 (optional)
 * @param name2         name of feature2 (optional)
 */
_str getNotificationEventName(_str alertGroupId, 
                              NotificationFeature feature1, 
                              NotificationFeature feature2 = "", 
                              _str name1=null, _str name2=null)
{
   if (alertGroupId=="") alertGroupId=ALERT_GRP_EDITING_ALERTS;
   if (name1._isempty()) {
      ALERT_INFO alertInfo1;
      _GetAlert(alertGroupId,feature1,alertInfo1);
      if (alertInfo1._isempty()) return"";
      name1=alertInfo1.Name;
   }
   if (feature2 == -1) feature2="";
   if (name2._isempty() && feature2 != "") {
      ALERT_INFO alertInfo2;
      _GetAlert(alertGroupId,feature2,alertInfo2);
      if (alertInfo2._isempty()) return "";
      name2=alertInfo2.Name;
   }
   if (!name2._isempty() && name2!='') {
      name1 :+= ' with 'name2;
   }

   return name1;
}

/** 
 * @return 
 * Retrieves the display name of a notification event along with it's group name.
 * 
 * @param alertGroupId  kind of notification alert (feature, warning, etc., ALERT_GRP_*)
 * @param feature1      feature that was used (one of the NotificationFeature enums)
 * @param feature2      secondary feature that was involved (optional) 
 */
_str getNotificationTypeAndEventName(_str alertGroupId, 
                                     NotificationFeature feature1,
                                     NotificationFeature feature2="")
{
   if (alertGroupId=="") alertGroupId=ALERT_GRP_EDITING_ALERTS;
   ALERT_GROUP_INFO alertGroupInfo;
   _GetAlertGroup(alertGroupId, alertGroupInfo);

   ALERT_INFO alertInfo1;
   _GetAlert(alertGroupId,feature1,alertInfo1);
   if (alertInfo1._isempty()) return"";

   withFeature2Phrase := "";
   if (feature2 == -1) feature2="";
   if (feature2 != "") {
      ALERT_INFO alertInfo2;
      _GetAlert(alertGroupId,feature2,alertInfo2);
      if (!alertInfo2._isempty() && alertInfo2.Name != "") {
         withFeature2Phrase = " with "alertInfo2.Name;
      }
   }

   return alertGroupInfo.Name": "alertInfo1.Name:+withFeature2Phrase;
}

/** 
 * @return 
 * Retrieves the description of a NotificationFeature.
 * 
 * @param alertGroupId  kind of notification alert (feature, warning, etc., ALERT_GRP_*)
 * @param feature       feature that was used (one of the NotificationFeature enums)
 */
_str getNotificationEventDescription(_str alertGroupId, NotificationFeature feature)
{
   if (alertGroupId=="") alertGroupId=ALERT_GRP_EDITING_ALERTS;
   ALERT_INFO alertInfo1;
   _GetAlert(alertGroupId,feature,alertInfo1);
   if (alertInfo1._isempty()) return"";

   return alertInfo1.Description;
}

/** 
 * Retrieves the configuration options command and arguments for the given notification. 
 *  
 * @param alertGroupId     kind of notification alert (feature, warning, etc., ALERT_GRP_*)
 * @param feature          feature that was used (one of the NotificationFeature enums)
 * @param optionsCommand   (reference) set to command to invoke options for feature
 * @param optionsArg1      (reference) set to first argument to pass to options command
 * @param optionsArg2      (reference) set to second argument to pass to options command
 */
void getNotificationEventOptionsInfo(_str alertGroupId, NotificationFeature feature, 
                                     _str &optionsCommand, _str &optionsArg1, _str &optionsArg2)
{
   if (alertGroupId=="") alertGroupId=ALERT_GRP_EDITING_ALERTS;
   optionsCommand = '';
   optionsArg1 = '';
   optionsArg2 = '';
   ALERT_INFO alertInfo1;
   _GetAlert(alertGroupId,feature,alertInfo1);
   if (alertInfo1._isempty()) return;

   optionsCommand = alertInfo1.Command;
   optionsArg1 = alertInfo1.ConfigPath;
   optionsArg2 = alertInfo1.ConfigOption;
}

/** 
 * @return 
 * Retrieves the help information of a NotificationFeature
 * (to be sent to the {@link help} command).
 * 
 * @param alertGroupId  kind of notification alert (feature, warning, etc., ALERT_GRP_*)
 * @param feature       feature that was used (one of the NotificationFeature enums)
 * 
 */
_str getNotificationEventHelp(_str alertGroupId, NotificationFeature feature)
{
   ALERT_INFO alertInfo1;
   _GetAlert(alertGroupId,feature,alertInfo1);
   if (alertInfo1._isempty()) return '';

   return alertInfo1.HelpID;
}

#endregion Notification Data

/**
 * Displays the notification nag dialog to alert the user that a feature did
 * some (possibly unexpected) editing.
 * 
 * @param alertGroupId  kind of notification alert (feature, warning, etc., ALERT_GRP_*)
 * @param feature1      feature that was used (one of the NotificationFeature enums)
 * @param feature2      secondary feature that was involved (optioonal)
 */
static void displayNotificationDialog(_str alertGroupId, NotificationFeature feature1, NotificationFeature feature2="")
{
   // launch the nag dialog with the relevant info
   show('-modal _notification_nag_form', alertGroupId, feature1, feature2);
}

#region Options Dialog Helper Functions

defeventtab _notification_options_form;

static _str CURRENT_OPTIONS_FEATURE(...) {
   if (arg()) _ctl_feature_combo.p_user=arg(1);
   return _ctl_feature_combo.p_user;
}
static const ORIGINAL_SETTINGS='orig_settings';
static const NEW_SETTINGS='new_settings';
static _str  ORIGINAL_RADIO(...) {
   if (arg()) ctllabel1.p_user=arg(1);
   return ctllabel1.p_user;
}
static typeless ORIGINAL_SAME_LEVEL(...) {
   if (arg()) _ctl_notes_same.p_user=arg(1);
   return _ctl_notes_same.p_user;
}

void _notification_options_form_init_for_options(NotificationFeature feature="")
{
   parse feature with feature "\t" auto alertGroupId;
   maybePickFeatureToConfigure(alertGroupId, feature);
}

void _notification_options_form_restore_state(NotificationFeature feature="")
{
   parse feature with feature "\t" auto alertGroupId;
   maybePickFeatureToConfigure(alertGroupId, feature);
}

void _notification_options_form_save_settings()
{
   //ORIGINAL_SETTINGS = NEW_SETTINGS;
   // save the current level settings for each one
   if (*_GetDialogInfoHtPtr(NEW_SETTINGS)!=null) {
      // Update the modified settings.
      ALERT_INFO info;
      foreach (auto feature => info in *_GetDialogInfoHtPtr(NEW_SETTINGS)) {
         _GetDialogInfoHtPtr(ORIGINAL_SETTINGS)->:[feature]=info;
      }
   }
   _SetDialogInfoHt(NEW_SETTINGS,null);

   // save which radio button is checked
   ORIGINAL_RADIO( getCurrentRadioSelection());

   if (_ctl_all_notification.p_enabled) {
      methodDesc := _ctl_all_notification.p_text;
      ORIGINAL_SAME_LEVEL(descriptionToNotificationMethod(methodDesc));
   } else {
      ORIGINAL_SAME_LEVEL(-1);
   }

   // we just do this so the current item will be saved
   ALERT_INFO action = getCurrentFeatureAction();

   _ctl_back_proc_hide_icon.p_user = _ctl_back_proc_hide_icon.p_value;
   _ctl_disable_back_proc_popups.p_user = _ctl_disable_back_proc_popups.p_value;
   _ctl_feat_notify_hide_icon.p_user = _ctl_feat_notify_hide_icon.p_value;
   _ctl_disable_feat_notify_popups.p_user = _ctl_disable_feat_notify_popups.p_value;

}

bool _notification_options_form_is_modified()
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
   if (ORIGINAL_RADIO() != curRadio && curRadio != 2) {
      return true;
   }

   // see if they have set the features to all be something new
   if (_ctl_all_notification.p_enabled) {
      methodDesc := _ctl_all_notification.p_text;
      sameMethod := descriptionToNotificationMethod(methodDesc);
      if (sameMethod != ORIGINAL_SAME_LEVEL()) {
         return true;
      }
   } 

   // finally, see if the settings are changed
   if (*_GetDialogInfoHtPtr(NEW_SETTINGS) != null && _GetDialogInfoHtPtr(NEW_SETTINGS)->_length() != 0) {
      return true;
   }

   return false;
}

bool _notification_options_form_apply()
{
   // save the alert group options
   SaveAlertGroupOptions();

   // save the old feature settings
   saveCurrentFeatureSettings();

   if (_ctl_notes_same.p_value) {
      // set everything to whatever is specified
      methodDesc := _ctl_all_notification.p_text;
      setAllNotificationMethods(ALERT_GRP_EDITING_ALERTS,         descriptionToNotificationMethod(methodDesc));
      setAllNotificationMethods(ALERT_GRP_WARNING_ALERTS,         descriptionToNotificationMethod(methodDesc));
      setAllNotificationMethods(ALERT_GRP_UPDATE_ALERTS,          descriptionToNotificationMethod(methodDesc));
      setAllNotificationMethods(ALERT_GRP_DEBUG_LISTENER_ALERTS,  descriptionToNotificationMethod(methodDesc));
   } else {
      if (*_GetDialogInfoHtPtr(NEW_SETTINGS)!=null) {
         // we gotta set each and every one
         ALERT_INFO info;
         NotificationFeature feature;
         foreach (feature => info in *_GetDialogInfoHtPtr(NEW_SETTINGS)) {
            parse feature with auto featureName "\t" auto alertGroupId;
            setNotificationMethod(alertGroupId, featureName, info.Method);
            setLogNotification(alertGroupId, featureName, info.Log);
         }
      }
   }
   if (*_GetDialogInfoHtPtr(NEW_SETTINGS)!=null) {
      // Update the modified settings.
      ALERT_INFO info;
      foreach (auto feature => info in *_GetDialogInfoHtPtr(NEW_SETTINGS)) {
         _GetDialogInfoHtPtr(ORIGINAL_SETTINGS)->:[feature]=info;
      }
   }

   // we may need to set things anew
   if ((_ctl_feat_notify_hide_icon.p_value && 
        _ctl_feat_notify_hide_icon.p_value != _ctl_feat_notify_hide_icon.p_user) || 
        (_ctl_disable_feat_notify_popups.p_value &&
        _ctl_feat_notify_hide_icon.p_value != _ctl_feat_notify_hide_icon.p_user)) {

      ALERT_INFO info;
      NotificationFeature feature;
      foreach (feature => info in *_GetDialogInfoHtPtr(ORIGINAL_SETTINGS)) {
         parse feature with auto featureName "\t" auto alertGroupId;
         method := info.Method;
         newMethod := maybeGetNewMethod(method);
         if (method != newMethod) {
            setNotificationMethod(alertGroupId, featureName, newMethod);
         }
      }
   }

   refreshNotificationTree();

   return true;
}

static const HIDE_ICON_FOR_BACK_PROC= "Hide icon for background process";
static const DISABLE_POPUPS_FOR_BACK_PROC= "Disable pop-ups for background process";
static const HIDE_ICON_FOR_FEAT_NOTIFY= "Hide icon for feature notifications";
static const DISABLE_POPUPS_FOR_FEAT_NOTIFY= "Disable pop-ups for feature notifications";

static const EXPORT_NOTIFICATION_CAPTION=    ' notifications';
static const EXPORT_LOG_CAPTION=             'Log ';

_str _notification_options_form_build_export_summary(PropertySheetItem (&table)[])
{
   PropertySheetItem psi;

   _str alertGroupList[];
   _plugin_list_profiles(VSCFGPACKAGE_NOTIFICATION_PROFILES, alertGroupList);

   alertGroupId := "";
   NotificationFeature feature;
   foreach (alertGroupId in alertGroupList) {
      if (alertGroupId == ALERT_GRP_BACKGROUND_ALERTS) continue;
      if (alertGroupId=='debug listener') continue;
      _str alertid_list[];
      _plugin_list_profiles(vsCfgPackage_for_NotificationGroup(alertGroupId),alertid_list);
      // store the rest
      foreach (feature in alertid_list) {
         ALERT_INFO alertInfo1;
         _GetAlert(alertGroupId,feature,alertInfo1);
         if (alertInfo1._isempty()) continue;

         level := alertInfo1.Method;
         name := alertInfo1.AlertID;

         psi.Caption  = name :+ EXPORT_NOTIFICATION_CAPTION:+"\t":+alertGroupId;
         psi.Value = notificationMethodToDescription(level);
         table[table._length()] = psi;

         psi.Caption  = EXPORT_LOG_CAPTION :+ name:+"\t":+alertGroupId;
         psi.Value = alertInfo1.Log;
         table[table._length()] = psi;

      }
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
   retVal := 0;
   if (optionValue == 0) {
      retVal = 1;
   }
   return retVal;
}

_str _notification_options_form_import_summary(PropertySheetItem (&table)[])
{

   NotificationFeature nameToFeature:[];
   bool featureExistsHash:[];
   _str alertGroupList[];
   _plugin_list_profiles(VSCFGPACKAGE_NOTIFICATION_PROFILES, alertGroupList);

   alertGroupId := "";
   NotificationFeature feature;
   foreach (alertGroupId in alertGroupList) {
      if (alertGroupId == ALERT_GRP_BACKGROUND_ALERTS) continue;
      if (alertGroupId=='debug listener') alertGroupId=ALERT_GRP_DEBUG_LISTENER_ALERTS;
      _str alertid_list[];
      _plugin_list_profiles(vsCfgPackage_for_NotificationGroup(alertGroupId),alertid_list);
      // store the rest
      foreach (feature in alertid_list) {
         ALERT_INFO alertInfo1;
         _GetAlert(alertGroupId,feature,alertInfo1);
         if (alertInfo1._isempty()) continue;
         nameToFeature:[lowcase(alertInfo1.Name)"\t"alertGroupId]=alertInfo1.AlertID;
         featureExistsHash:[feature"\t"alertGroupId] = true;
#if 0
         // get the level
         thisLevel := alertInfo1.Method;
         if (matchSoFar) {
            if (noteLevel == -1) {
               noteLevel = thisLevel;
            } else if (noteLevel != thisLevel) {
               matchSoFar = false;
            }
         }
#endif
      }
   }


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
         alertGroupId=ALERT_GRP_EDITING_ALERTS;
         hasTab:=false;
         if (pos("\t",caption)) {
            parse caption with caption "\t" alertGroupId;
            hasTab=true;
         }
         if (pos(EXPORT_LOG_CAPTION, caption) == 1) {
            caption = substr(caption, 1 + length(EXPORT_LOG_CAPTION));
         } else {
            caption = substr(caption, 1, length(caption) - length(EXPORT_NOTIFICATION_CAPTION));
            methodItem = true;
         }
         if (featureExistsHash._indexin(caption:+"\t":+alertGroupId)) {
            feature=caption;
         } else {
            // Conversion from old version (v19 or before).
            if (!hasTab) {
               feature = nameToFeature:[lowcase(caption):+"\t":+alertGroupId];
            }
         }
         if (feature!=null && feature != '') {
            if (methodItem) {
               methodDesc := table[i].Value;
               method := descriptionToNotificationMethod(methodDesc);
               setNotificationMethod(alertGroupId, feature, method);
            } else {
               setLogNotification(alertGroupId, feature, ((int)table[i].Value != 0));
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

#endregion Options Dialog Helper Functions

void _notification_options_form.on_create()
{
   // prepare some blank arrays
   ALERT_INFO origSettings:[];
   ALERT_INFO newSettings:[];
   _SetDialogInfoHt(ORIGINAL_SETTINGS,origSettings);
   _SetDialogInfoHt(NEW_SETTINGS,newSettings);

   // populate the check boxes for showing/enabling status icons
   PopulateAlertOptions();
   populateMethodCombos();

   noteLevel := -1;
   matchSoFar := true;

   _str alertGroupList[];
   _plugin_list_profiles(VSCFGPACKAGE_NOTIFICATION_PROFILES, alertGroupList);

   alertGroupId := "";
   feature := "";
   foreach (alertGroupId in alertGroupList) {
      if (alertGroupId == ALERT_GRP_BACKGROUND_ALERTS) continue;
      if (alertGroupId=='debug listener') continue;
      _str alertid_list[];
      _plugin_list_profiles(vsCfgPackage_for_NotificationGroup(alertGroupId),alertid_list);
      // store the rest
      foreach (feature in alertid_list) {
         ALERT_INFO alertInfo1;
         _GetAlert(alertGroupId,feature,alertInfo1);
         if (alertInfo1._isempty()) continue;
         if (!alertInfo1.DisplayOption) {
            continue;
         }
         origSettings:[feature"\t"alertGroupId] = alertInfo1;

         // get the name, add it to the combo
         featureName := getNotificationTypeAndEventName(alertGroupId, feature);
         _ctl_feature_combo._lbadd_item(featureName);

         // get the level
         thisLevel := alertInfo1.Method;
         if (matchSoFar) {
            if (noteLevel == -1) {
               noteLevel = thisLevel;
            } else if (noteLevel != thisLevel) {
               matchSoFar = false;
            }
         }
      }
   }

   _SetDialogInfoHt(ORIGINAL_SETTINGS,origSettings);

   // sort the list of features
   _ctl_feature_combo._lbsort();
   _ctl_feature_combo._lbtop();
   _ctl_feature_combo._lbselect_line();
   _ctl_feature_combo.p_text = _ctl_feature_combo._lbget_text();

   if (matchSoFar && noteLevel > 0) {
      _ctl_notes_same.p_value = 1;
      _ctl_all_notification._lbfind_and_select_item(notificationMethodToDescription(noteLevel), '', true);
   } else {
      _ctl_notes_specify.p_value = 1;
   }

   // help is a link, so make it look linkified
   _ctl_help_link.p_mouse_pointer = MP_HAND;
   _ctl_options_link.p_mouse_pointer = MP_HAND;
}

bool isFeatureAvailable(int feature)
{
   switch (feature) {
   case NF_AUTO_LIST_MEMBERS:
   case NF_INSERT_MATCHING_PARAMETERS:
   case NF_AUTO_DISPLAY_PARAM_INFO:
   case NF_AUTO_LIST_COMPATIBLE_PARAMS:
   case NF_AUTO_LIST_COMPATIBLE_VALUES:
   case NF_AUTO_DOT_FOR_DASHGT:
      if (!_haveContextTagging()) return false;
      break;
   case NF_AUTO_XML_VALIDATION:
      if (!_haveXMLValidation()) return false;
      break;
   }

   return true;
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

static NotificationMethod maybeGetNewMethod(NotificationMethod curMethod)
{
   while (!isMethodAvailable(curMethod)) {
      curMethod++;
   }

   return curMethod;
}

static bool isMethodAvailable(int method)
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

static void maybePickFeatureToConfigure(_str alertGroupId, NotificationFeature feature)
{
   // if a feature is sent in, we may want to select it
   if (feature != "") {
      // only do this if the levels are not all the same
      if (_ctl_notes_specify.p_value) {
         featureName := getNotificationTypeAndEventName(alertGroupId, feature);
         _ctl_feature_combo._lbfind_and_select_item(featureName, '', true);
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
      _ctl_disable_all_popups.p_style = PSCH_AUTO3STATEA;
      _ctl_disable_all_popups.p_value = 2;
      _ctl_disable_all_popups.p_style = PSCH_AUTO2STATE;
   }
   _ctl_disable_back_proc_popups.p_enabled = (_ctl_back_proc_hide_icon.p_value == 0);
   _ctl_disable_feat_notify_popups.p_enabled = (_ctl_feat_notify_hide_icon.p_value == 0);
}

void _ctl_feature_combo.on_change(int reason)
{
   // save the old feature settings
   saveCurrentFeatureSettings();

   // get the feature name
   alertGroupId := ALERT_GRP_EDITING_ALERTS;
   featureName := _ctl_feature_combo.p_text;

   // which enum is this?
   feature := getNotificationFeatureByName(*_GetDialogInfoHtPtr(ORIGINAL_SETTINGS),featureName);
   if (feature !='') {
      CURRENT_OPTIONS_FEATURE(feature);
      parse feature with feature "\t" alertGroupId;
      loadFeatureInfo(alertGroupId, feature);
   } else {
      CURRENT_OPTIONS_FEATURE("");
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
static void SaveAlertGroupOptions()
{
   enabled := 1;
   if (_ctl_back_proc_hide_icon.p_value) {
      enabled = 0;
   }
   showPopup := 1;
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
   if (CURRENT_OPTIONS_FEATURE() != "" && _ctl_feature_combo.p_enabled) {
      NotificationMethod method;
      
      methodDesc := _ctl_feature_notification.p_text;
      newMethod := descriptionToNotificationMethod(methodDesc);
      
      newLog := (_ctl_log_check.p_value != 0);

      ALERT_INFO origAction = _GetDialogInfoHtPtr(ORIGINAL_SETTINGS)->:[CURRENT_OPTIONS_FEATURE()];

      // only save it if it's different
      if (origAction.Method != newMethod || origAction.Log != newLog) {
         ALERT_INFO action=origAction;
         action.Method = newMethod;
         action.Log = newLog;
         _GetDialogInfoHtPtr(NEW_SETTINGS)->:[CURRENT_OPTIONS_FEATURE()] = action;
      }
   }
}

static ALERT_INFO getCurrentFeatureAction()
{
   ALERT_INFO alertInfo1;

   if (*_GetDialogInfoHtPtr(NEW_SETTINGS) != null && _GetDialogInfoHtPtr(NEW_SETTINGS)->:[CURRENT_OPTIONS_FEATURE()] != null) {
      alertInfo1 = _GetDialogInfoHtPtr(NEW_SETTINGS)->:[CURRENT_OPTIONS_FEATURE()];
   } else if (*_GetDialogInfoHtPtr(ORIGINAL_SETTINGS) != null && _GetDialogInfoHtPtr(ORIGINAL_SETTINGS)->:[CURRENT_OPTIONS_FEATURE()] != null) {
      alertInfo1 = _GetDialogInfoHtPtr(ORIGINAL_SETTINGS)->:[CURRENT_OPTIONS_FEATURE()];
   } else {
      // settings for this feature have not yet been loaded, load them now
      return null;
      //say('missing alert properties');
#if 0
      ALERT_INFO alertInfo1;
      _GetAlert(ALERT_GRP_EDITING_ALERTS,CURRENT_OPTIONS_FEATURE(),alertInfo1)
      if (alertInfo1._isempty()) {
         say('missing alert properties');
         alertInfo1.method=NL_NODE;
         alertInfo1.log=1;
      }
      // save this info in our original settings
      ORIGINAL_SETTINGS:[CURRENT_OPTIONS_FEATURE()] = alertInfo1;
#endif
   } 

   return alertInfo1;
}

static void loadFeatureInfo(_str alertGroupId, NotificationFeature feature)
{
   if (CURRENT_OPTIONS_FEATURE() != "") {

      ALERT_INFO action = getCurrentFeatureAction();
      if (action == null) return;

      // load up the description
      _ctl_desc.p_caption = action.Description;

      featureName := _ctl_feature_combo.p_text;
      parse featureName with . ':' featureName;
      featureName = strip(featureName);
      _ctl_help_link.p_caption = featureName' Help';
      _ctl_options_link.p_caption = featureName' Options';

      // what's the notification level?
      _ctl_feature_notification._lbfind_and_select_item(notificationMethodToDescription(action.Method), '', true);
      _ctl_log_check.p_value = (int)action.Log;
   }
}

void _ctl_help_link.lbutton_up()
{
   parse CURRENT_OPTIONS_FEATURE() with auto feature "\t" auto alertGroupId;
   help(getNotificationEventHelp(alertGroupId, feature));
}

void _ctl_options_link.lbutton_up()
{
   parse CURRENT_OPTIONS_FEATURE() with auto feature "\t" auto alertGroupId;
   configure_notification_feature(alertGroupId, feature);
}

defeventtab _notification_nag_form;

static _str CURRENT_NAG_DIALOG_FEATURE(...) {
   if (arg()) _ctl_ok_btn.p_user=arg(1);
   return _ctl_ok_btn.p_user;
}

void _ctl_ok_btn.on_create(_str alertGroupId, NotificationFeature feature1, NotificationFeature feature2 = "")
{
   if (alertGroupId == "") alertGroupId = ALERT_GRP_EDITING_ALERTS;
   CURRENT_NAG_DIALOG_FEATURE( feature1 "\t" alertGroupId);

   // load up the information on this feature
   _ctl_name_lbl.p_caption = getNotificationTypeAndEventName(alertGroupId, feature1, feature2);
   _ctl_desc_lbl.p_caption = getNotificationEventDescription(alertGroupId, feature1);

   resizeLabel(_ctl_name_lbl, 'd');
   resizeLabel(_ctl_desc_lbl, 'd');

   _ctl_configure_link.p_mouse_pointer = MP_HAND;
}

void _notification_nag_form.ESC()
{
   closeNag();
}

static const LINE_HEIGHT=        255;

void resizeLabel(int label, _str expandDirection, bool doShrink = true)
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
   parse CURRENT_NAG_DIALOG_FEATURE() with auto feature "\t" auto alertGroupId;
   show_help_for_notification_feature(alertGroupId, feature);
}

void _ctl_options_btn.lbutton_up()
{
   parse CURRENT_NAG_DIALOG_FEATURE() with auto feature "\t" auto alertGroupId;
   closeNag();
   configure_notification_feature(alertGroupId, feature);
}

void _ctl_configure_link.lbutton_up()
{
   parse CURRENT_NAG_DIALOG_FEATURE() with auto feature "\t" auto alertGroupId;
   closeNag();
   config('Notifications', 'N', feature);
}

static void closeNag()
{
   parse CURRENT_NAG_DIALOG_FEATURE() with auto feature "\t" auto alertGroupId;
   if (!_ctl_nag_chbx.p_value) {
      // make sure this is set to the DIALOG value
      setNotificationMethod(alertGroupId, feature, NL_DIALOG);
   } else {
      // mark this down to the MESSAGE level
      setNotificationMethod(alertGroupId, feature, NL_MESSAGE);
   }

   p_active_form._delete_window();
}
