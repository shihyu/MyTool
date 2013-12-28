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
#include "pip.sh"
#include "toolbar.sh"
#include "xml.sh"
#import "html.e"
#import "main.e"
#import "markfilt.e"
#import "pipe.e"
#import "projconv.e"
#import "refactor.e"
#import "search.e"
#import "sellist2.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "tbautohide.e"
#import "toast.e"
#import "toolbar.e"
#import "vc.e"
#import "wkspace.e"
#require "se/lang/api/LanguageSettings.e"
#require "se/datetime/DateTime.e"
#endregion

using se.lang.api.LanguageSettings;
using se.datetime.DateTime;
using namespace se.datetime;

#define PIPDB_FILE                  'pipDB.dbs'
#define PIP_LOG                     'pip'

#define PIP_SEND_PERIOD             7
#define PIP_TRIAL_SEND_PERIOD       1
#define PIP_CLEAR_PERIOD            4
#define PIP_TIME_INTERVAL           DT_DAY

#define PIP_URL                     'http://productimprovement.slickedit.com'
#define PIP_FAQS_URL                'http://www.slickedit.com/index.php?option=com_content&view=article&id=254'

#define PIP_SEND_TIMEOUT            30000
#define PIP_SEND_TIMER_FACTOR       10
#define PIP_NO_SEND_RESULT_YET      'Send not complete.'

#define PIP_SCHEMA_VERSION          "1.5"

/**
 * Set this to 1 to force the PIP to attempt a send for testing purposes.  You 
 * will then be prompted to send the pip every time you start the editor.  To 
 * turn off the prompt and just attempt a send, comment out the def_pip_on = 
 * PIP_PROMPT; line in the _pip_startup. 
 */
#define PIP_DEBUG                   0

/**
 * Timer for checking the results of our last attempt to send in the PIP data.
 */
static int pip_result_timer = -1;

/**
 * How many times we have checked for results
 */
static int pip_results_check_count;

/**
 * Date of our last successful send.  String in the form returned from
 * _time('B').
 */
static double gPipLastSendDate = 0;

/**
 * Keeps track of the regexes used to search.  Will be written
 * to PIP data at send-time.
 */
static int pip_regex_search_flags = 0;

definit()
{
   pip_result_timer = -1;
   gPipLastSendDate = 0;
}

/**
 * Starts the Product Improvement Program on startup.  Possibly does a send.
 */
void _pip_startup()
{
   if ( _OEM() || _default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS)==SW_HIDE ) {
      def_pip_on = 0;
      def_pip_show_options = false;
      return;
   }

   // we renamed the database file in v16.  We are so indecisive.
   _pip_maybe_rename_database();

#if PIP_DEBUG
   // set the date to a long time ago so we'll try to send
   gPipLastSendDate = 10151340027900000;

   // turn on the prompt
   def_pip_on = PIP_PROMPT;
#endif

   if (def_pip_on) {
      // start the database going
      _pip_start_logging(_pip_get_database_file(), _pip_db_needs_upgrade());

      // set the version to the current so we know that the db is up to date
      pip_db_version = _version();

#if PIP_DEBUG
      _pip_maybe_add_test_data();
#endif

      // if we don't have a date, set it for now
      _pip_maybe_reset_date();

      // check and see if want to go ahead and send this off
      _pip_maybe_send(false);
   }
}

/** 
 * The original database was named "pipDB.vtg," which is not accurate, since
 * it's not a tag database.  We changed it in v16 to avoid confusion.
 */
void _pip_maybe_rename_database()
{
   oldFile := _ConfigPath() :+ 'pipDB.vtg';
   newFile := _pip_get_database_file();

   // do we have the old file, but not the new file?  Check both, in 
   // case the old file did not get deleted properly.
   if (file_exists(oldFile) && !file_exists(newFile)) {
      copy_file(oldFile, newFile);
      delete_file(oldFile);
   }
}

/**
 * Adds some bogus data to the PIP for the purpose of doing a test send.  This
 * data is filtered out on the other end.
 */
void _pip_maybe_add_test_data()
{
   if (_pip_is_log_empty()) {
      // add some data so we'll have something to send
      _pip_log_help_event('cherries', OI_EDITOR, 'Perl file');
      _pip_log_command_event('config', PCLM_MAIN_MENU);
   }
}

/**
 * Determines if the current pip database needs an upgrade.  Checks version 
 * against versions where we know we made changes to the database.  As more 
 * changes are made, this function will be expanded. 
 */
boolean _pip_db_needs_upgrade()
{
   // in 15.0.1, we added file extension logging
   if (_version_compare(pip_db_version, '15.0.1') < 0) {
      return true;
   }

   return false;
}

_command void force_pip_debug_send() name_info(',')
{
   oldDate := gPipLastSendDate;
   if (length(oldDate) != 17) {
      oldDate = (double)_time('B');
   }
   oldOn := def_pip_on;

   // set the date to a long time ago so we'll try to send
   gPipLastSendDate = 10151340027900000;

   // turn on the prompt
   def_pip_on = PIP_PROMPT;

   if (!oldOn) {
      // start the database going
      _pip_start_logging(_pip_get_database_file(), false);
   
      // add some data so we'll have something to send
      _pip_maybe_add_test_data();
   }

   // check and see if want to go ahead and send this off
   _pip_send();

   gPipLastSendDate = oldDate;
   def_pip_on = oldOn;

   if (!oldOn) {
      _pip_end_logging();
   }
}

#region Application Callbacks

/**
 * Called when we are reading restore data.
 * 
 * @param option        
 * @param info 
 * 
 * @return int 
 */
int _srg_pip(_str option = '', _str info = '')
{
   if (option == 'N' || option == 'R') {
      typeless numlines = '';
      typeless tempDate = '';
      parse info with numlines tempDate .;

      if (tempDate != '') {
         gPipLastSendDate = tempDate;
      }
   } else {
      insert_line("PIP: 0 "gPipLastSendDate);
   }

   return 0;
}

/**
 * Called when the application is exiting.  Closes and saves the database.
 */
void _exit_pip()
{
   // this _project_close callback is not called when we 
   // exit, so do this here
   _pip_log_project_event();

   _pip_save_and_close();
}

/**
 * Called when a new workspace is opened up.  Logs the workspace event.
 */
void _workspace_opened_pip()
{
   // we may not be logging
   if (!def_pip_on) return;

   // make sure we have something to work with here
   if (gWorkspaceHandle <= 0 || _workspace_filename == '') return;

   // we want to know how many projects are in this workspace
   _str array[] = null;
   _WorkspaceGet_ProjectNodes(gWorkspaceHandle, array);
   numProjects := array._length();

   // now we want to know the tag files and their sizes
   tagFile := _GetWorkspaceTagsFilename();
   tagFileSize := 0;
   if (tagFile != 0) {
      tagFileSize = _file_size(tagFile);
      if (tagFileSize < 0) tagFileSize = 0;
   } 

   // log it!
   _pip_log_workspace_open_event(numProjects, tagFileSize);
}

/**
 * Called when a project is closed.  Logs the project event. 
 *  
 * We used to call this when the project was open.  However, 
 * when getting the number of project files for large projects, 
 * this could cause the editor to be sluggish, since the file 
 * list was not already cached.  By doing this work when the 
 * project is closed, then the file list will already be built 
 * and cached. 
 */
void _project_close_pip()
{  
   _pip_log_project_event();
}

static void _pip_log_project_event()
{
   // we may not be logging
   if (!def_pip_on) return;

   // no project open?
   if (_workspace_filename == '' || _project_name == '') return;

   // project type
   type := aboutProject('', true);

   // number of files
   numFiles := -1;
   if (_isProjectInfoCached(_workspace_filename, _project_name)) {
      numFiles = _getNumProjectFiles(_workspace_filename, _project_name);
   }

   // version control system
   vcs := _GetVCSystemName();

   // we have the info, so log it
   _pip_log_project_open_event(type, numFiles, vcs);
}

/**
 * Called when a new file is opened.
 */
void _buffer_add_pip(int newBufId, _str bufName, int bufFlags = 0)
{
   langId := _Filename2LangId(bufName);

   size := _file_size(bufName);
   if (size < 0) size = 0;

   ext  := _file_case(_get_extension(bufName));
   if (ext == '') {
      ext = 'Extensionless';
   }

   _pip_log_file_open_event(langId, size, ext);
}

#endregion Application Callbacks

/**
 * Gets the name of the Product Improvement Program database file.
 * 
 * @return _str            path to db file
 */
static _str _pip_get_database_file()
{
   return _ConfigPath() :+ PIPDB_FILE;
}

/**
 * Displays the Frequently Asked Questions page for the Product Improvement 
 * Program on the slickedit website. 
 */
static void _pip_goto_faqs()
{
   // this goes to a link on the website
   goto_url(PIP_FAQS_URL); 
}

/**
 * Gets the name of the Product Improvement Program xml file.  This file is 
 * created, zipped up, sent to SlickEdit, and then deleted. 
 * 
 * @return _str            path to xml file
 */
static _str _pip_get_xml_file()
{
   return _ConfigPath() :+ 'pip.xml';
}

/**
 * Gets the name of the Product Improvement Program zip file.  This file 
 * contains all the data mined from use of the application and is sent to 
 * SlickEdit. 
 * 
 * @param xmlFile          path to xml file which will be zipped up
 * 
 * @return _str            path to zip file
 */
static _str _pip_get_zip_file(_str xmlFile)
{
   return xmlFile'.zip';
}

/**
 * Starts the Product Improvement Program.
 */
void _pip_start()
{
   if (!def_pip_on) {
      def_pip_on = PIP_ON;

      _pip_start_logging(_pip_get_database_file(), false);

      // set the date to now so we don't immediately send a mostly blank data log
      _pip_maybe_reset_date(true);

      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
}

/**
 * Stops the Product Improvement Program and tidies up after it.
 */
void _pip_end()
{
   if (def_pip_on) {
      def_pip_on = PIP_OFF; 

      _pip_end_logging();
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
}

/**
 * Resets the PIP last send date.
 */
static void _pip_maybe_reset_date(boolean force = false)
{
   if (force || length((_str)gPipLastSendDate) != 17) {
      gPipLastSendDate = (double)_time('B');
   }
}

/**
 * Determines whether the PIP options would be visible at this 
 * point. 
 *  
 * Included as a Visibility setting because it relies on the 
 * current value of def_pip_show_options.  We added it for 
 * enterprise customers who may not want their users to opt in 
 * to the PIP. 
 *  
 * @return boolean            true if visible, false if 
 *                            invisible
 */
boolean _pip_are_options_visible()
{
   return def_pip_show_options;
}

/**
 * Determines whether it is time to send data back to SlickEdit for the Product
 * Improvement Program.  If so, attempts to send it.
 */
void _pip_maybe_send(boolean checkIdle = true)
{
   // we want to make sure that the editor is really idle - sometimes we skip 
   // this step (on startup, for instance)
   if (checkIdle && _idle_time_elapsed() < def_pip_send_delay) return;

   _pip_maybe_reset_date();

   DateTime now();
   DateTime then = DateTime.fromTimeB(gPipLastSendDate);

   // see find out when our next send date is, and compare to now
   // we send it at different intervals if we are on a trial
   sendPeriod := _trial() ? PIP_TRIAL_SEND_PERIOD : PIP_SEND_PERIOD;
   DateTime theNextTime = then.add(sendPeriod, PIP_TIME_INTERVAL);

   if (now.compare(theNextTime) > 0) {
      // it is time, so send it!
      _pip_send();
   } else {
      theNextTime = then.add(PIP_CLEAR_PERIOD, PIP_TIME_INTERVAL);
      if (now.compare(theNextTime) > 0) {
         // we might need to clear out old records if our last send was unsuccessful
         _pip_maybe_clear_old_records();
      }
   }
}

/**
 * Sends the Product Improvement Program data to SlickEdit.
 */
static void _pip_send()
{
   // before we write the event log, we might want to brush out the cobwebs
   _pip_maybe_clear_old_records();

   // if the log is empty, then there is no point in doing this
   if (_pip_is_log_empty()) return;

   pipId := getPipUserId();
   if (pipId == '') return;
   
   // we need the date   
   now := (double)_time('B');

   // let's start up a file
   filename := _pip_get_xml_file();
   xmlHandle := _xmlcfg_create(filename, VSENCODING_UTF8);
   if (xmlHandle < 0) {
      _pip_log_send_result('Error creating 'filename, now);
      return;
   }
   _xmlcfg_add(xmlHandle, TREE_ROOT_INDEX, 'xml version="1.0" encoding="UTF-8"',
               VSXMLCFG_NODE_XML_DECLARATION, VSXMLCFG_ADD_AS_CHILD);

   // add our top level node
   pipNode := _xmlcfg_add(xmlHandle, 0, 'ProductImprovementData', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   if (pipNode < 0) {
      _pip_log_send_result('Error creating ProductImprovementData node', now);
      _xmlcfg_close(xmlHandle);
      return;
   }

   // add some information
   DateTime sendTime;
   sendTime = DateTime.fromTimeB(now);
   sendTimeStr := sendTime.toStringISO8601();
   node := _xmlcfg_add(xmlHandle, pipNode, 'Date', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, node, sendTimeStr, VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

   node = _xmlcfg_add(xmlHandle, pipNode, 'ID', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, node, pipId, VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

   node = _xmlcfg_add(xmlHandle, pipNode, 'PipSchemaVersion', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, node, PIP_SCHEMA_VERSION, VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

   // see if we need to add the settings to it
   settingsNode :=  _xmlcfg_add(xmlHandle, pipNode, 'Settings', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);

   writeHelpAboutInfo(xmlHandle, settingsNode);
   writeTagFileSizes(xmlHandle, settingsNode);
   writeToolbarLayout(xmlHandle, settingsNode);
   writeEditorInfo(xmlHandle, settingsNode);
   writeNotificationSettings(xmlHandle, settingsNode);
   writeRegexUsage(xmlHandle, settingsNode);

   // now write the event log
   _pip_write_to_xml(xmlHandle, pipNode);

   // save and close our file
   status := _xmlcfg_save(xmlHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE | VSXMLCFG_SAVE_PCDATA_INLINE);
   if (status) {
      _pip_log_send_result('Error saving 'filename, now);
      _xmlcfg_close(xmlHandle);
      return;
   }

   if (!file_exists(filename)) {
      _pip_log_send_result('Error - after save, 'filename' does not exist', now);
      _xmlcfg_close(xmlHandle);
      return;
   }

   _xmlcfg_close(xmlHandle);

   // ask the user if they want to proceed
   if (def_pip_on == PIP_PROMPT) {
      result := show('-modal -xy _pip_nag_form');

      // a zero result means that the user does not want to send off the pip 
      // at this time - it might meant he opted out of the program or it might 
      // mean that he just didn't want to be bothered with it right now
      if (result == 0) {
         _pip_clean_up();
         return;
      }
   }

   // zip it up
   zipfile := _pip_get_zip_file(filename);
   _str fileArray[];
   fileArray[0] = filename;

   int fileStatus[];
   status = _CreateZipFile(zipfile, fileArray, fileStatus);
   if (status) {
      delete_file(filename);
      _pip_log_send_result("Error creating zip file "zipfile, now);
      return;
   }

   // alert the user
   _pip_alert(true);

   // send it off then
   _pip_send_data(PIP_URL, zipfile, PIP_SEND_TIMEOUT, PIP_SCHEMA_VERSION, pipId, sendTimeStr);

   // save the date
   gPipLastSendDate = (double)now;

   // start a timer to check our result, so we know whether to clear the data
   pip_results_check_count = 0;
   _pip_start_result_timer();
}

/**
 * Starts the timer to check for results from a PIP send operation.
 */
static void _pip_start_result_timer()
{
   // kill it first, just in case it's already running
   _pip_kill_result_timer();

   // now start it
   pip_result_timer = _set_timer(PIP_SEND_TIMEOUT / PIP_SEND_TIMER_FACTOR, _pip_check_result);
}

/**
 * Kills the timer which checks for results from a PIP send operation.
 */
static void _pip_kill_result_timer()
{
   if (pip_result_timer > 0 && _timer_is_valid(pip_result_timer)) {
      _kill_timer(pip_result_timer);
   }

   pip_result_timer = -1;
}

/**
 * If we fail to send the data for some reason, we want to periodically clear
 * out the data so we don't get bogged down.
 */
static void _pip_maybe_clear_old_records()
{
   // remove any record older than 30 days old
   DateTime lastMonth;
   lastMonth = lastMonth.add(-30, DT_DAY);
   _pip_remove_old_records(lastMonth.toTimeF());
}

/**
 * Checks the result of the last send operation of the Product Improvement
 * Program.  
 */
void _pip_check_result()
{
   if (pip_result_timer == null) return;

   // increment the check count
   pip_results_check_count++;

   // kill off our timer so it does not fire again
   _pip_kill_result_timer();

   // get the result
   result := _pip_get_send_result();
   // we haven't set a result yet, which means the send operation is not complete
   if (result == PIP_NO_SEND_RESULT_YET) {
      // we may have checked the max amount of times, so just forget it
      if (pip_results_check_count < PIP_SEND_TIMER_FACTOR) {
         // no, we want to check some more
         _pip_start_result_timer();
         return;
      } else {
         // nah, forget the whole thing, change the result so we can log it
         result = 'Send operation timed out.';
      }
   }

   pip_last_send_success = (int)(result == '');

   _pip_log_send_result(result);

   if (pip_last_send_success) {
      // now delete everything in the database that we sent off
      _pip_remove_old_records(_timeBToTimeF(gPipLastSendDate));

      // clear these flags out
      pip_regex_search_flags = 0;
   }

   // delete the files, regardless of success
   _pip_clean_up();

   // turn off the alert mechanism
   _pip_alert(false);
}

/**
 * Removes any files created by the pip send process.
 */
static void _pip_clean_up()
{
   // first get rid of the xml file
   filename := _pip_get_xml_file();
   if (file_exists(filename)) {
      delete_file(filename);
   }

   // now remove the zip file
   filename = _pip_get_zip_file(filename);
   if (file_exists(filename)) {
      delete_file(filename);
   }
}

/**
 * Alerts the user about the send status for the Product Improvement Program.
 * 
 * @param starting         true if we are starting the send attempt, false if we
 *                         are finishing up
 */
static void _pip_alert(boolean starting)
{
   if (starting) {
      _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_PIP_SEND, 'Product Improvement Program attempting to send data.', '', 0);
   } else {
      _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_PIP_SEND, 'Product Improvement Program completed sending data.', '', 0);
   }
}

/**
 * Logs the result of attempting to send data to SlickEdit for the Product 
 * Improvement Program. 
 * 
 * @param result           result of send operation (a string returned by 
 *                         SlickEdit)
 * @param date             date of our last send
 */
static void _pip_log_send_result(_str result, _str date = gPipLastSendDate)
{
   // I hate errors like this, too, but sometimes we just don't know, alright?
   if (result == null) result = "Unknown error.";

   // prepare a message for our log file
   strDate := 'Unknown date';
   if (length(date) == 17) {
      DateTime then = DateTime.fromTimeB(date);
      strDate = then.toStringISO8601();
   } 
   msg := "Product Improvement Program result ("strDate") - ";

   // if the result is not empty, then something went wrong
   if (result == '') {
      msg :+= 'Success!';
   } else {
      msg :+= 'Failed with error: 'result;
   }

   dsay(msg, PIP_LOG);
}

/**
 * Builds a unique user id to be associated with this user when data is sent to 
 * SlickEdit for the Product Improvement Program.  Though this user id contains 
 * the user name, machine name, and serial number, it is hashed so that the 
 * user's identity is protected.  All data will be anonymous. 
 * 
 * @return _str               hashed user id to be associated with data sent 
 *                            from this editor
 */
_str getPipUserId()
{
   // get the user name
   userName := _GetUserName();

   // now the machine name
   machineName := _gethostname();

   // finally, the serial
   serial := _getSerial();

   return _pip_get_user_id(userName, machineName, serial);
}

/**
 * Converts all non-printable characters into a replacement character.
 * 
 * @param string              string to convert 
 * @param replaceChr          character to stick in place of non-printable 
 *                            characters
 * 
 * @return _str               string with non-printable characters replaced
 */
static _str convertNonPrintableChars(_str string, _str replaceChr = '_')
{
   newString := '';

   // go through each character
   len := length(string);
   for (i := 1; i <= len; ++i) {

      // grab this one!
      ch := substr(string, i, 1);

      // is it printable?
      if (!isprint(ch)) {
         // no, change it to an underscore
         ch = replaceChr;
      }

      newString :+= ch;
   }

   return newString;
}

/**
 * Logs a search and checks for any regexes used.
 * 
 * @param options          options used to search
 */
void pip_log_regex_search(_str options)
{
   // check the options for any regex usage
   options = upcase(options);
   if (pos('U', options)) {
      pip_regex_search_flags |= VSSEARCHFLAG_UNIXRE;
   } else if (pos('B', options)) {
      pip_regex_search_flags |= VSSEARCHFLAG_BRIEFRE;
   } else if (pos('R', options)) {
      pip_regex_search_flags |= VSSEARCHFLAG_RE;
   } else if (pos('L', options)) {
      pip_regex_search_flags |= VSSEARCHFLAG_PERLRE;
   } else if (pos('&', options)) {
      pip_regex_search_flags |= VSSEARCHFLAG_WILDCARDRE;
   }
}

/**
 * Adds regex usage to the PIP data.
 * 
 * @param xmlHandle 
 * @param node 
 */
static void writeRegexUsage(int xmlHandle, int parentNode)
{
   // add our usage node
   regexNode := _xmlcfg_add(xmlHandle, parentNode, 'RegexUsage', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);

   // add each regex type as a child node, with their usage as a 1/0 data value
   typeNode := _xmlcfg_add(xmlHandle, regexNode, 'Brief', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, typeNode, (int)((pip_regex_search_flags & VSSEARCHFLAG_BRIEFRE) != 0), VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

   typeNode = _xmlcfg_add(xmlHandle, regexNode, 'Perl', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, typeNode, (int)((pip_regex_search_flags & VSSEARCHFLAG_PERLRE) != 0), VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

   typeNode = _xmlcfg_add(xmlHandle, regexNode, 'SlickEdit', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, typeNode, (int)((pip_regex_search_flags & VSSEARCHFLAG_RE) != 0), VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

   typeNode = _xmlcfg_add(xmlHandle, regexNode, 'Unix', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, typeNode, (int)((pip_regex_search_flags & VSSEARCHFLAG_UNIXRE) != 0), VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

   typeNode = _xmlcfg_add(xmlHandle, regexNode, 'Wildcard', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, typeNode, (int)((pip_regex_search_flags & VSSEARCHFLAG_WILDCARDRE) != 0), VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);
}

/**
 * Writes the notification status icon settings to the PIP.  
 * 
 * @param xmlHandle              handle to xml tree were data is being written
 * @param settingsNode           parent node where data is being written
 */
static void writeNotificationSettings(int xmlHandle, int settingsNode)
{
   notificationsNode := _xmlcfg_add(xmlHandle, settingsNode, 'Notifications', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   
   writeAlertGroupInfo(xmlHandle, notificationsNode, ALERT_GRP_EDITING_ALERTS);
   writeAlertGroupInfo(xmlHandle, notificationsNode, ALERT_GRP_BACKGROUND_ALERTS);
}

/**
 * Writes the settings for one notification group to the PIP.
 * 
 * @param xmlHandle              handle to xml tree were data is being written
 * @param notificationsNode      parent node, containing all notification 
 *                               settings
 * @param groupId                notification group to write info for
 */
static void writeAlertGroupInfo(int xmlHandle, int notificationsNode, int groupId)
{
   // get our alert info
   ALERT_GROUP_INFO alertGroupInfo;
   _GetAlertGroup(groupId, alertGroupInfo);

   // sometimes this is null?
   if (alertGroupInfo == null) return;

   // create a note for our group
   groupNode := _xmlcfg_add(xmlHandle, notificationsNode, 'NotificationGroup', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);

   // name
   data := (alertGroupInfo.Name == null) ? "Null" : alertGroupInfo.Name;
   infoNode := _xmlcfg_add(xmlHandle, groupNode, 'GroupName', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, infoNode, data, VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

   // group enabled?
   if (alertGroupInfo.Enabled == null) data = "Null";
   else data = alertGroupInfo.Enabled ? 'true' : 'false';

   infoNode = _xmlcfg_add(xmlHandle, groupNode, 'Enabled', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, infoNode, data, VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

   // popups!
   if (alertGroupInfo.ShowPopups == null) data = "Null";
   else data = alertGroupInfo.ShowPopups ? 'true' : 'false';
   infoNode = _xmlcfg_add(xmlHandle, groupNode, 'ShowPopups', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, infoNode, data, VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);
}

/**
 * Writes information from Help > About to the Product Improvement Program data 
 * file to be sent in.  This does not include any information which could 
 * identify the user sending the data. 
 * 
 * @param xmlHandle              handle to xml tree were data is being written
 * @param settingsNode           parent node where data is being written
 */
static void writeHelpAboutInfo(int xmlHandle, int settingsNode)
{
   aboutNode := _xmlcfg_add(xmlHandle, settingsNode, 'About', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);

   writeHelpAboutItem(xmlHandle, aboutNode, 'Product:'_getApplicationName());

   getPipLicenseInfo(auto licenseType, auto nOfUsers);
   writeHelpAboutItem(xmlHandle, aboutNode, 'Licensed Number Of Users:'nOfUsers);
   writeHelpAboutItem(xmlHandle, aboutNode, 'License Type:'licenseType);

   writeHelpAboutItem(xmlHandle, aboutNode, aboutProductBuildDate('Build Date:'));
   writeHelpAboutItem(xmlHandle, aboutNode, aboutVersion('Version:'));
   writeHelpAboutItem(xmlHandle, aboutNode, aboutEmulation('Emulation:'));

   osInfo := aboutOsInfo('');
   osInfo = stranslate(osInfo, '', '<b>|</b>', 'R');
   osInfo = stranslate(osInfo, ' ', '&nbsp;');

   _str osArray[];
   split(osInfo, "\n", osArray);
   foreach (auto osData in osArray) {
      if (strip(osData) != '') {
         writeHelpAboutItem(xmlHandle, aboutNode, osData);
      }
   }
   writeHelpAboutItem(xmlHandle, aboutNode, aboutMemoryInfo('Memory:'));
   writeHelpAboutItem(xmlHandle, aboutNode, aboutScreenResolutionInfo('Resolution:'));
}

/**
 * Gets license information to be sent to the PIP.
 * 
 * @param licenseType         type of license being used
 * @param nOfUsers            number of users on license
 */
void getPipLicenseInfo(_str &licenseType, int &nOfUsers)
{
   licenseType = _getLicenseType();
   tempN := _getLicensedNofusers();

   // 0 means that this is not a concurrent license
   // 1 means that this IS a concurrent license of 1.
   // We may one to change what gets displayed if "1" is returned.
   if (tempN == "" || tempN == "0") {
      licenseType = 'Standard';
      nOfUsers = 1;
   } else if (isinteger(tempN)) {
      nOfUsers = (int)tempN;
   } else {
      nOfUsers = 1;
   }
}

/**
 * Writes and individual item from Help > About to the Product Improvement 
 * Program data file to be sent in. 
 * 
 * @param xmlHandle              handle to xml tree were data is being written
 * @param aboutNode              parent node of Help > About section 
 * @param item                   item to be written, in FieldName:FieldValue 
 *                               form
 */
static void writeHelpAboutItem(int xmlHandle, int aboutNode, _str item)
{
   // our item is set up like in Help > About, so it will contain a caption, 
   // followed by a colon, and finally our info
   parse item with auto caption ':' auto info;

   // remove the spaces from the caption, convert to camel casing
   caption = strip(caption);

   _str parts[];
   split(caption, ' ', parts);
   newCaption := '';
   for (i := 0; i < parts._length(); i++) {
      thisPart := parts[i];
      if (thisPart != '') {
         newCaption :+= _cap_word(thisPart);
      }
   }

   // we might have some weird characters in this one...
   info = convertNonPrintableChars(info);

   node := _xmlcfg_add(xmlHandle, aboutNode, newCaption, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, node, info, VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);
}

/**
 * Writes information from about the user's tag files to the Product 
 * Improvement Program data file to be sent in.  This does not include 
 * any information which could identify the user sending the data. 
 * 
 * @param xmlHandle              handle to xml tree were data is being written
 * @param settingsNode           parent node where data is being written
 */
static void writeTagFileSizes(int xmlHandle, int settingsNode)
{
   tagFilesNode := _xmlcfg_add(xmlHandle, settingsNode, 'TagFiles', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);

   // get the list of compiler configurations
   _str c_compiler_names[];
   _str java_compiler_names[];

   c_compiler_names._makeempty();
   java_compiler_names._makeempty();
   refactor_get_compiler_configurations(c_compiler_names, java_compiler_names);

   // c compiler tag files
   for (i := 0; i < c_compiler_names._length(); ++i) {
      file := _tagfiles_path() :+ c_compiler_names[i] :+ TAG_FILE_EXT;
      writeTagFileInfo(xmlHandle, tagFilesNode, file);
   }

   // java tag files
   for (i = 0; i < java_compiler_names._length(); ++i) {
      file := _tagfiles_path() :+ java_compiler_names[i] :+ TAG_FILE_EXT;
      writeTagFileInfo(xmlHandle, tagFilesNode, file);
   }

   // get all the language-specific tag files
   _str langTagFilesTable:[];
   LanguageSettings.getTagFileListTable(langTagFilesTable);

   foreach (auto langId => auto langTagFilesList in langTagFilesTable) {
      langTagFilesList = _replace_envvars(langTagFilesList);

      while (langTagFilesList != '') {
         file := parse_tag_file_name(langTagFilesList);
         writeTagFileInfo(xmlHandle, tagFilesNode, file);
      }
   }
}

/**
 * Writes information about a tag file to the Product Improvement Program's data 
 * file. 
 * 
 * @param xmlHandle              handle to xml tree where data is being written
 * @param tagFilesNode           parent node where tag file information is 
 *                               contained
 * @param file                   tag file name
 */
static void writeTagFileInfo(int xmlHandle, int tagFilesNode, _str file)
{
   if (!file_exists(file)) return;

   status := tag_read_db(absolute(file));
   if (status >= 0) {
      fileNode := _xmlcfg_add(xmlHandle, tagFilesNode, 'TagFile', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);

      node := _xmlcfg_add(xmlHandle, fileNode, 'Name', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add(xmlHandle, node, _strip_filename(file, 'P'), VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

      text := tag_get_db_comment();
      if (text == '') {
         text = 'Not available';
      }
      node = _xmlcfg_add(xmlHandle, fileNode, 'Description', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add(xmlHandle, node, text, VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

      size := _file_size(file);
      if (size < 0) size = 0;         
      node = _xmlcfg_add(xmlHandle, fileNode, 'Size', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add(xmlHandle, node, size, VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

      tag_close_db(absolute(file), 1);
   }
}

/**
 * Writes information about Toolbars and Tool Windows to the Product 
 * Improvement Program data file to be sent in.  This does not include 
 * any information which could identify the user sending the data. 
 * 
 * @param xmlHandle              handle to xml tree were data is being written
 * @param settingsNode           parent node where data is being written
 */
static void writeToolbarLayout(int xmlHandle, int settingsNode)
{
   toolbarsNode := _xmlcfg_add(xmlHandle, settingsNode, 'Toolbars', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   toolWindowsNode := _xmlcfg_add(xmlHandle, settingsNode, 'ToolWindows', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);

   // go through the list of toolbars and write information about each one
   for (i := 0; i < def_toolbartab._length(); ++i) {
      isButtonBar := isToolbar(def_toolbartab[i].tbflags);
      writeToolbarInfo(xmlHandle, isButtonBar ? toolbarsNode : toolWindowsNode, def_toolbartab[i], isButtonBar);
   }
}

/**
 * Writes information about a toolbar to the Product Improvement Program's data.
 * 
 * @param xmlHandle              handle to xml tree where data is being written
 * @param toolbarsNode           parent node where toolbar info is being written
 * @param tb                     toolbar info
 * @param buttonBar              true if this toolbar is a button bar, false if 
 *                               it is a tool window
 */
static void writeToolbarInfo(int xmlHandle, int toolbarsNode, _TOOLBAR &tb, boolean buttonBar)
{
   tbNode := 0;
   // the element name is different, depending on what we have
   if (buttonBar) {
      tbNode = _xmlcfg_add(xmlHandle, toolbarsNode, 'Toolbar', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   } else {
      tbNode = _xmlcfg_add(xmlHandle, toolbarsNode, 'ToolWindow', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   }

   // the name of the form
   node := _xmlcfg_add(xmlHandle, tbNode, 'Name', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, node, tb.FormName, VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

   // the caption of the form, since the name is sometimes a little obscure
   index := find_index(tb.FormName, oi2type(OI_FORM));
   if (index) {
      node = _xmlcfg_add(xmlHandle, tbNode, 'Caption', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add(xmlHandle, node, index.p_caption, VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);
   }

   // is the form visible right now?
   wid := _find_formobj(tb.FormName, 'N');
   visible := (wid != 0);

   // only for tool windows - we check for autohide
   if (!buttonBar) {
      autohide := _tbIsAuto(tb.FormName, true);

      node = _xmlcfg_add(xmlHandle, tbNode, 'AutoHide', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add(xmlHandle, node, autohide ? 'true' : 'false', VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

      // sometimes we will get a false positive if the user happens to be using the window at the 
      // moment we are compiling data.  However, we don't want to count this one as being visible, 
      // since we are counting it as auto-hidden
      if (autohide) {
         visible = false;
      }
   }

   // now add the visible element
   node = _xmlcfg_add(xmlHandle, tbNode, 'Visible', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, node, visible ? 'true' : 'false', VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);
}

/**
 * Writes information about the editor to the Product Improvement Program
 * data file to be sent in.  This does not include any information which 
 * could identify the user sending the data. 
 * 
 * @param xmlHandle              handle to xml tree were data is being written
 * @param settingsNode           parent node where data is being written
 */
static void writeEditorInfo(int xmlHandle, int settingsNode)
{
   editorNode := _xmlcfg_add(xmlHandle, settingsNode, 'Editor', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);

   bufferCount := 0;
   buf_info := buf_match("", 1, "V");
   loop {
      if (rc) break;
      bufferCount++;
      buf_info = buf_match("", 0, "V");
   }

   node := _xmlcfg_add(xmlHandle, editorNode, 'OpenBuffers', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add(xmlHandle, node, bufferCount, VSXMLCFG_NODE_PCDATA, VSXMLCFG_ADD_AS_CHILD);

   writeHelpAboutItem(xmlHandle, editorNode, aboutProject('ProjectType:', true));
}

/**
 * GUI for opting in and out of the Product Improvement Program.
 */
defeventtab _pip_options_form;

void _pip_options_form_init_for_options()
{
   _cb_participate.p_value = (int)(def_pip_on != 0);
}

void _pip_options_form_apply()
{
   if ((int)(def_pip_on != 0) != _cb_participate.p_value) {
      if (_cb_participate.p_value) {
         _pip_start();
      } else {
         _pip_end();
      }
   }
}

void _cb_participate.on_create()
{
   _ctl_faq_link.p_mouse_pointer = MP_HAND;
   if (isEclipsePlugin()) {
      ctl_slickedit_pic.p_picture = _update_picture(-1, "vse_profile_eclipse_64.bmp");
   }
}

void _ctl_faq_link.lbutton_up()
{
   _pip_goto_faqs();
}

defeventtab _pip_nag_form;

void _ctl_ok.on_create()
{
   // make super sure that our file even exists 
   pipFile := _pip_get_xml_file();
   if (!file_exists(pipFile)) {
      p_active_form._delete_window(0);
      return;
   }

   _ctl_rb_yes.p_value = _ctl_rb_no.p_value = 0;
   _ctl_ok.p_enabled = false;

   // we need HANDS!
   _ctl_preview_link.p_mouse_pointer = _ctl_faq_link.p_mouse_pointer = MP_HAND;
}

void _ctl_ok.lbutton_up()
{
   if (_ctl_rb_yes.p_value) {
      // they want to help!  hopefully, we can just change the variable, as we should be 
      // already logging at this point
      def_pip_on = PIP_ON;
      _config_modify_flags(CFGMODIFY_DEFDATA);
   } else if (_ctl_rb_no.p_value) {
      // they want no part of this
      _pip_end();
   }

   p_active_form._delete_window(def_pip_on);
}

void _ctl_ask_later.lbutton_up()
{
   // change the value of gPipLastSendDate so we don't bother the 
   // user again until tomorrow at least
   DateTime dt;

   sendPeriod := _trial() ? PIP_TRIAL_SEND_PERIOD : PIP_SEND_PERIOD;
   sendPeriod--;
   dt = dt.add(-sendPeriod, PIP_TIME_INTERVAL);
   gPipLastSendDate = (double)dt.toTimeB();

   p_active_form._delete_window(0);
}

void _ctl_rb_yes.lbutton_up()
{
   _ctl_ok.p_enabled = (_ctl_rb_yes.p_value || _ctl_rb_no.p_value);
}

void _ctl_rb_no.lbutton_up()
{
   _ctl_ok.p_enabled = (_ctl_rb_yes.p_value || _ctl_rb_no.p_value);
}

void _ctl_preview_link.lbutton_up()
{
   // pop up a dialog with our info
   pipFile := _pip_get_xml_file();

   int temp_view_id, orig_view_id;
   status := _open_temp_view(pipFile, temp_view_id, orig_view_id);
   if (status) {
      _message_box(nls("Could not open local version of %s", pipFile));
      return;
   }

   _SetEditorLanguage();
   p_window_id=orig_view_id;

   _showbuf(temp_view_id, false, '-new -modal -xy', 'Preview data', '', true);

   _delete_temp_view(temp_view_id);
}

void _ctl_faq_link.lbutton_up()
{
   _pip_goto_faqs();
}
