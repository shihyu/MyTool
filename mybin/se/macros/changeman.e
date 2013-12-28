////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47272 $
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
#endregion

// CMFileInfo contains all information regarding the file and/or
// data set given by ChangeMan via cmedit().
static struct CMFileInfo
{
   _str filename; // file or data set name
   int exitCode;  // Flag: 1=nothing changed & don't need save changes, 0=file modified & need to check in changes
   _str semFile;  // semaphore file
};
static CMFileInfo cmfiles[];
static int cmDebugState = 0; // Flag: 1=debug on; 0=off

#define MODIFYFLAG_CHANGEMAN_NOT_MODIFIED 0x10000
int gexit_code;

definit()
{
   cmfiles._makeempty();
   cmDebugState = 0;
}

#if __OS390__ || __TESTS390__

/**
 * Test to see if cmedit(), cmlist(), cmsendquit(), cmdebug() are available.
 *
 * @return Flag: true=CM hooks available, false=not available
 */
boolean isCMSupported()
{
   _str envVSLICKUSECM = get_env("VSLICKUSECM");
   if (envVSLICKUSECM == "") return(false);
   if (envVSLICKUSECM == "1" || upcase(envVSLICKUSECM) == "Y") return(true);
   return(false);
}

/**
 * Write the exit code into the semaphore file.<BR>
 * Edit status codes are:
 * <UL>
 *    <LI>0 --> data set modified
 *    <LI>1 --> data set unmodified
 *    <LI>2 --> data set already being edited
 *    <LI>3 --> CM not supported. Set VSLICKUSECM=1 to turn on CM support.
 * </UL>
 *
 * @param semFile  semaphore file
 * @param exitCode exit code
 */
static void cmSendQuitFile(_str semFile, int exitCode)
{
   /*_str cmd = "echo '"exitCode"' > "semFile;
   shell(cmd);*/
   int temp_view_id, orig_view_id;
   orig_view_id = _create_temp_view(temp_view_id);
   p_buf_name = semFile;
   delete_all();
   insert_line(exitCode);
   _save_file('+o');
   p_window_id = orig_view_id;
   _delete_temp_view(temp_view_id);
}

/**
 * Signal back to the caller about the CM data set being closed.
 *
 * @param fi     data set index in list
 */
static void cmSignalQuitFile(int fi)
{
   // Signal caller.
   if (cmDebugState) {
      //say("cmSignalQuitFile "cmfiles[fi].filename" ec="cmfiles[fi].exitCode);
      message("cmSignalQuitFile "cmfiles[fi].filename" ec="cmfiles[fi].exitCode);
   }
   cmSendQuitFile(cmfiles[fi].semFile, cmfiles[fi].exitCode);

   // Remove entry from file list.
   //message("Removed "cmfiles[fi].filename" "cmfiles[fi].semFile" "cmfiles[fi].exitCode);
   int count = cmfiles._length();
   int i;
   for (i=fi; i<count-1; i++) {
      cmfiles[i] = cmfiles[i+1];
   }
   cmfiles._deleteel(count-1);
}

/**
 * Check to see if the specified file or data set is currently in the CM file <BR>
 * list.  If found, return the index of its position in list.
 *
 * @param name   data set name
 * @param fi     returning index in list
 * @return Flag: 1 in list, 0 not
 */
static int cmIsDataSetInList(_str name, int & fi)
{
   fi = -1;
   int found = -1;
   int i;
   _str ff1 = name;
   if (_DataSetIsFile(ff1)) ff1 = upcase(ff1);
   for (i=0; i<cmfiles._length(); i++) {
      _str ff2 = cmfiles[i].filename;
      if (_DataSetIsFile(ff2)) ff2 = upcase(ff2);
      if (ff2 :== ff1) {
         fi = i;
         return(1);
      }
   }
   return(0);
}

/**
 * Handles quit_file() callback.
 */
void _cbquit_changeman()
{
   // If CM is not supported, do nothing.
   if (!isCMSupported()) return;

   // Check to see if buffer is one of CM data sets.
   if (cmDebugState) {
      //say("_cbquit_changeman "p_buf_name);
      message("_cbquit_changeman "p_buf_name);
   }
   int found;
   if (!cmIsDataSetInList(p_buf_name, found)) return;

   // Mark the modification flag for data set.
   if (p_modify) {
      // User does not want these changes
      //say('data set still modified');
      cmfiles[found].exitCode = 1;
   } else {
      if (p_ModifyFlags&MODIFYFLAG_CHANGEMAN_NOT_MODIFIED) {
         // No changes made to file
         //say('data set not modified');
         cmfiles[found].exitCode = 1;
      } else {
         // User wants these changes
         //say('data set changed');
         cmfiles[found].exitCode = 0;
      }
   }

   // Signal back to the caller about this data set being closed.
   cmSignalQuitFile(found);
}

/**
 * Handles safe_exit() callback.
 */
void _exit_changeman()
{
   // If CM is not supported, do nothing.
   if (!isCMSupported()) return;

   // Loop from a temp copy of the CM files list. This is needed because
   // the CM file list will get modified as CM data set are closed.
   //say("_exit_changeman");
   CMFileInfo tmpcmfiles[];
   tmpcmfiles = cmfiles;
   int count = tmpcmfiles._length();
   int i;
   for (i=0; i<count; i++) {
      if (buf_match(tmpcmfiles[i].filename, 1, 'hx') != '') {
         int status = edit(maybe_quote_filename(tmpcmfiles[i].filename));
         if (!status) {
            _cbquit_changeman();
            p_modify=0;
            quit();
         }
      }
   }
   gexit_code = 0;
}

/**
 * Edit a CM data set.<BR>
 * <BR>
 * USAGE:  dataSetName:semaphoreFile
 */
_command void cmedit(_str filename='')
{
   // Parse out the data set name and the semaphore file name.
   _str semFile='';
   parse filename with filename':'semFile;
   if (filename == "" && semFile == "") {
      _message_box("Missing data set and semaphore file name in cmedit command.");
      return;
   } else if (filename == ""){
      _message_box("Missing data set name in cmedit command.");
      return;
   } else if (semFile == ""){
      _message_box("Missing semaphore file name in cmedit command.");
      return;
   }

   // If CM is not supported, indicate so in the semaphore file.
   if (!isCMSupported()) {
      _message_box("CM not supported. Set VSLICKUSECM=1 to turn on the support.");
      cmSendQuitFile(semFile, 3);
      return;
   }

   // If the data set is already in the CM file list, ignore the
   // request.
   int found;
   if (cmIsDataSetInList(filename, found)) {
      cmSendQuitFile(semFile, 2);
      return;
   }

   // Edit the file/data set.
   int status = edit(maybe_quote_filename(filename));
   if (cmDebugState) {
      //say("cmedit '"filename"' status="status);
      message("cmedit '"filename"' status="status);
   }
   if (!status || status == FILE_NOT_FOUND_RC || status == NEW_FILE_RC) {
      // Default modify flag with a CM change bit.
      // If this bit is cleared, the buffer has been modified.
      p_ModifyFlags|=MODIFYFLAG_CHANGEMAN_NOT_MODIFIED;
      _mdi.refresh();

      // Add a new CM file entry.
      int count = cmfiles._length();
      cmfiles[count].filename = p_buf_name;
      cmfiles[count].exitCode = 1;
      cmfiles[count].semFile = semFile;
      //say("cmedit ADDED "cmfiles[count].filename" semFile="cmfiles[count].semFile);
      if (cmDebugState) {
         message("Added "cmfiles[count].filename);
      }
   }
   _mdi._set_foreground_window();
}

/**
 * List the CM buffer and semaphore file list.<BR>
 * This command is only used for debugging.<BR>
 */
_command void cmlist()
{
   // If CM is not supported, do nothing.
   if (!isCMSupported()) {
      _message_box("CM not supported. Set VSLICKUSECM=1 to turn on the support.");
      return;
   }

   // Get the CM buffer list.
   if (cmfiles._length()) {
      edit("+t");
      top();up();
      int i;
      for (i=0; i<cmfiles._length(); i++) {
         insert_line("Buffer:  "cmfiles[i].filename);
         insert_line("SemFile: "cmfiles[i].semFile);
         insert_line("");
      }
      p_modify = 0;
   } else {
      _message_box("The CM buffer list is empty.");
   }
}

/**
 * Force send the "quit" signal for the active buffer.  Sending the "quit" <BR>
 * signal constitutes ONLY updating the semaphore file.  The actual edit <BR>
 * buffer in the editor is NOT touched in any way.  <BR>
 * <BR>
 * The exit code is undefined.<BR>
 * This command is only used for debugging.<BR>
 * <BR>
 * USAGE:  cmsendquit CM bufname
 */
_command void cmsendquit(_str bufname='')
{
   // If CM is not supported, do nothing.
   if (!isCMSupported()) {
      _message_box("CM not supported. Set VSLICKUSECM=1 to turn on the support.");
      return;
   }

   // For no arguments, send the "quit" signal for the
   // active buffer.
   if (bufname='') {
      _cbquit_changeman();
      return;
   }

   // Check to see if buffer is one of CM data sets.
   int found;
   if (!cmIsDataSetInList(bufname, found)) return;

   // Send the "quit" signal.
   cmSignalQuitFile(found);
}

/**
 * Turn on/off debug messages.<BR>
 * <BR>
 * Usage:
 * <UL>
 *    <LI>cmdebug on
 *    <LI>cmdebug off
 * </UL>
 */
_command void cmdebug(_str onoff='on')
{
   // If CM is not supported, do nothing.
   if (!isCMSupported()) {
      _message_box("CM not supported. Set VSLICKUSECM=1 to turn on the support.");
      return;
   }

   if (lowcase(onoff) == "on" || lowcase(onoff) == "1") {
      cmDebugState = 1;
   } else {
      cmDebugState = 0;
   }
}

#endif
