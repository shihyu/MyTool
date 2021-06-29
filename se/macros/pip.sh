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
#pragma option(metadata,"pip.e")

enum PipCommandLaunchMethods {
   PCLM_COMMAND_LINE,
   PCLM_TOOLBAR_BUTTON,
   PCLM_MAIN_MENU,
   PCLM_CONTEXT_MENU,
   PCLM_KEYBINDING,
};

enum PipOnEnum {
   PIP_OFF,
   PIP_ON,
   PIP_PROMPT
};

/**
 * Determines whether the Product Improvement Program is on by 
 * default and whether whether the user is prompted before data 
 * is sent.
 */
int def_pip_on = PIP_PROMPT;

bool _pip_on;

/**
 * Whether our last attempt to send the PIP data into SlickEdit was successful.
 * If it was a failure, then we might need to clean out old records in the
 * database.
 */
int pip_last_send_success = 1;

/**
 * Idle time in milliseconds required before we attempt to send in the PIP data.
 * We don't want to try to send the data while the user is actively using the
 * editor. 
 *  
 * We want the editor to be good and idle, so we're using 15 minutes (900,000 
 * milliseconds). 
 */
int def_pip_send_delay = 900000;

/**
 * Whether we even show the options for the Product Improvement 
 * Program.  This option is for our enterprise customers who 
 * might not want to give their employees the ability to 
 * participate. 
 */
bool def_pip_show_options = true;

/**
 * Current version of the PIP database.
 */
_str pip_db_version = 0;

/**
 * Prepares for data logging by setting up the PIP database.
 * 
 * @param pipFilename            location of PIP database file
 * @param doUpgrade              whether we need to upgrade the database (due to 
 *                               version migration)
 * 
 * @return int                   0 if database was opened successfully, < 0 on 
 *                               error
 */
extern int _pip_start_logging(_str pipFilename, bool doUpgrade);

/**
 * Ends the data logging session.
 * 
 * @return int                   0 if everything was cleaned up successfully, < 
 *                               0 on error
 */
extern int _pip_end_logging();

/**
 * Logs a command into the PIP.  
 * 
 * @param cmd                    command that was launched.  This includes the 
 *                               whole command, including any arguments.
 *                               Arguments which might compromise the user's
 *                               privacy (filenames, symbol names, etc.) are
 *                               stripped out and not sent in to SlickEdit.
 * @param launchMethod           method used to run the command, part of the 
 *                               PipCommandLaunchMethods enum.  These values
 *                               include:
 *    <ul>
 *      <li>PCLM_COMMAND_LINE - command launched by typing the command name into
 *      the command line and pressing ENTER
 *      <li>PCLM_TOOLBAR_BUTTON - command launched by pressing a button on a
 *      button bar
 *      <li>PCLM_MAIN_MENU - command launched by selecting an item from the main
 *      menu
 *      <li>PCLM_CONTEXT_MENU - command launched by selecting an item from a
 *      context menu
 *      <li>PCLM_KEYBINDING - command launched using a keybinding
 *    </ul>
 *  
 * @param info                   extra information about the command launch, 
 *                               varies depending on the method
 *    <ul>
 *      <li>PCLM_COMMAND_LINE, PCLM_MAIN_MENU, PCLM_CONTEXT_MENU - n/a
 *      <li>PCLM_TOOLBAR_BUTTON - name of toolbar containing button that was
 *      clicked to launch the command
 *      <li>PCLM_KEYBINDING - keystrokes that launched the command (e.g. C-S-A,
 *      C-V)
 *    </ul>
 * 
 * @return int                   0 if command was logged successfully, < 0 on 
 *                               error
 */
extern int _pip_log_command_event(_str cmd, int launchMethod, _str info = "");

/**
 * Logs a file open event into the PIP.  Called whenever a file is opened in the 
 * editor. 
 * 
 * @param language               language id of file (see {@link p_LangId})
 * @param size                   size of file
 * 
 * @return int                   0 if event was logged successfully, < 0 on 
 *                               error
 */
extern int _pip_log_file_open_event(_str language, int size, _str ext);

/**
 * Logs a call into the help system into the PIP.  Called whenever the user 
 * issues a help command. 
 * 
 * @param topic                  help topic
 * @param currentObjectType      object type of currently active object (see 
 *                               {@link p_object})
 * @param currentObjectName      name of currently active object.  If the 
 *                               currently active object is an editor window,
 *                               this is left blank to preserve anonymity.
 * 
 * @return int                   0 if event was logged successfully, < 0 on 
 *                               error
 */
extern int _pip_log_help_event(_str topic,  int currentObjectType, _str currentObjectName);

/**
 * Logs a workspace open even into the PIP.  Called whenever a workspace is 
 * opened in the editor. 
 * 
 * @param numProjects            number of projects in the workspace
 * @param tagFileSize            size of the workspace tag file
 * 
 * @return int                   0 on success, < 0 on error
 */
extern int _pip_log_workspace_open_event(int numProjects, int tagFileSize);

/**
 * Logs a project open event into the PIP.  Called whenever a project is opened 
 * in the editor. 
 * 
 * @param type                   project type
 * @param numFiles               number of files in the project
 * @param vcs                    version control system used by the project
 * 
 * @return int                   0 on success, < 0 on error
 */
extern int _pip_log_project_open_event(_str type, int numFiles, _str vcs);

/**
 * Logs a license event into the PIP.  A license event occurs whenever the user 
 * applies a new license. 
 * 
 * @param oldLicenseType         license type being used previously
 * @param oldPipId               previous pip id
 * 
 * @return int                   0 for success, < 0 on error
 */
extern int _pip_log_license_event(_str oldLicenseType, _str oldPipId);

/**
 * Writes the PIP records out to an XML file.
 * 
 * @param xmlHandle              handle to the xml tree
 * @param parentNode             parent node where we want the logs to go
 * 
 * @return int                   0 on success, < 0 on error
 */
extern int _pip_write_to_xml(int xmlHandle, int parentNode);

/**
 * Sends the PIP data to SlickEdit.
 * 
 * @param url                    product improvement program URL
 * @param file                   zip file containing our precious data
 * @param timeout                how long (in milliseconds) we should try to 
 *                               send this thing before we give up
 * @param schemaVersion          version of our schema
 * 
 * @return int                   0 on success, < 0 on error.  This does not 
 *         indicate that the send operation itself was successful.  Since the
 *         send is done on a thread, you'll have to wait a while and use {@link
 *         _pip_check_send_result} to determine if the data was sent
 *         successfully.
 */
extern int _pip_send_data(_str url, _str file, int timeout, _str schemaVersion, _str pipId, _str date);

/**
 * Saves and closes the PIP database.  Should be called when the application is 
 * exiting to make sure the data is saved properly. 
 * 
 * @return int                   0 for success, < 0 on error
 */
extern int _pip_save_and_close();

/**
 * Retrieves the result of the PIP send operation.
 * 
 * @return _str                  Empty string if send was successful, error 
 *                               string otherwise
 */
extern _str _pip_get_send_result();

/**
 * Removes old records from the database.  A record is considered "old" if it 
 * was logged before a given time. 
 * 
 * @param timeF                  time in _time('F') format.  Records logged 
 *                               before this date and time will be purged.
 * 
 * @return int                   0 if removal was successful, < 0 on error
 */
extern int _pip_remove_old_records(_str timeF);

/**
 * Retrieves the user id used to associate the user with logs originating from 
 * him/her.  The user id is a hash of the user name, machine name, and SlickEdit 
 * serial number. 
 * 
 * @param userName               
 * @param machineName 
 * @param serial 
 * 
 * @return _str                  PIP user id
 */
extern _str _pip_get_user_id(_str userName, _str machineName, _str serial);

/**
 * Determines if the PIP database is currently empty of log records.
 * 
 * @return int                nonzero if the db is empty, zero if it contains 
 *                            at least one record
 */
extern int _pip_is_log_empty();

