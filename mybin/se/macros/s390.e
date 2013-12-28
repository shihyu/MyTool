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
#include "os390.sh"
#import "clipbd.e"
#import "dsutil.e"
#import "files.e"
#import "ini.e"
#import "listbox.e"
#import "main.e"
#import "saveload.e"
#import "stdprocs.e"
#import "util.e"
#endregion

static boolean gSuppressLogNotice = false; // Flag: true to suppress log notices

// TextOnChangeInfo is used to help monitor text box changes.
struct TextOnChangeInfo {
   int onChange;
   _str previousText;
};

// RegisteredDSInfo contains info on one registered data set.
struct RegisteredDSInfo {
   _str dsname; // data set name: DS.NAME, PDS.NAME
   boolean editRO; // Flag: true=initial edit readonly
   boolean registerMembers; // Flag: true=register PDS members
   boolean valid; // Flag: true=if isFixed,isPDS,lrecl are valid
   boolean isFixed; // Flag: true=fixed record length
   boolean isPDS; // Flag: true=data set is a PDS
   boolean newds; // Flag: true=if data set is newly registered
   int lrecl; // record length
};


/**
 * Check to see if the REXX exec LISTDSI has been created and
 * create it if needed. This REXX exec is stored in USER.VSLICK.MISC(LISTDSI).
 *
 * @return 0 OK, !0 error code
 */
int maybeCreateLISTDSI()
{
   // Build name to VSLICK.MISC PDS.
   _str userName;
   _userName(userName);
   _str vslickMiscPDS = userName :+ VSMISCDATASETSUFFIX;

   // Determine if the PDS USER.VSLICK.MISC exists.
   int status;
   _str dsInfoText;
   status = _os390DSInfo2(DATASET_ROOT:+vslickMiscPDS, dsInfoText);
   if (status) return(status);

   // If VSLICK.MISC does not exist, create it.
   if (pos(",,,,,", dsInfoText) == 1) {
      status = _os390NewDS(DATASET_ROOT:+vslickMiscPDS
                           ,"" // volser
                           ,"" // unit
                           ,SPACEUNIT_TRACKS
                           ,1 // primary quantity
                           ,1 // secondary quantity
                           ,20 // directory blocks
                           ,RECFM_FB // record format
                           ,80 // record length
                           ,8000 // block size
                           ,DSORG_PO // PDS
                           );
      if (status) {
         _message_box(nls("Can't allocate data set %s.\nReason: %s",vslickMiscPDS,get_message(status)));
         return(status);
      }
   }

   // Check to see if LISTDSI member is created. If it is, do nothing more.
   _str memberLISTDSI = DATASET_ROOT:+vslickMiscPDS:+FILESEP:+"LISTDSI";
   if (file_match("-p "memberLISTDSI, 1) != "") return(0);

   // Create LISTDSI member.
   _str listdsiSource = get_env("VSLICKBIN1");
   listdsiSource = listdsiSource :+ "listdsi.rexx";
   int temp_view, orig_view;
   status = _open_temp_view(listdsiSource, temp_view, orig_view);
   if (status) {
      _message_box(nls("Can't read %s.\nReason: %s",listdsiSource,get_message(status)));
      return(status);
   }
   p_buf_name = memberLISTDSI;
   status = _save_file('+o');
   if (status) {
      activate_window(orig_view);
      _delete_temp_view(temp_view);
      _message_box(nls("Can't write %s.\nReason: %s",memberLISTDSI,get_message(status)));
      return(status);
   }
   activate_window(orig_view);
   _delete_temp_view(temp_view, true);
   return(0);
}


//-----------------------------------------------------------------
// Check the data set name.
// Retn: 0 OK, 1 invalid name format
static int checkDSName(_str dsname, boolean allowStar=false)
{
   // Total length can not be more than 44 chars, including '.'
   if (length(dsname) > 44) return(1);

   // The first character can not be *.
   if (allowStar && substr(dsname,1,1) == '*') {
      return(5);
   }

   // Check individual qualifiers.
   boolean hasStar = false;
   boolean last = false;
   int start = 1;
   _str qq;
   while (!last) {
      // If a wildcard has been typed, allow no more characters.
      if (allowStar && hasStar) return(5);

      // Extract qualifier.
      int p = pos('.', dsname, start);
      if (!p) {
         qq = substr(dsname, start);
         last = true;
      } else {
         qq = substr(dsname, start, p-start);
         start = p+1;
      }
      //say("qq="qq);
      if (length(qq) > 8) return(2);
      if (length(qq) == 0 && last) return(3);
      if (length(qq) == 0) return(6);

      // First char must be A-Z or @#$ (or * for wildcard).
      _str firstChar = substr(qq, 1, 1);
      if (allowStar && firstChar == '*') {
         hasStar = true;
      } else if (firstChar != '@' && firstChar != '$' && firstChar != '#'
          && !isalpha(firstChar)) {
         return(4);
      }

      // Subsequent chars must be A-Z0-9 or @#$- (or * for wildcard).
      int i;
      for (i=2; i<=length(qq); i++) {
         _str cc = substr(qq, i, 1);
         if (allowStar) {
            if (hasStar) return(5);
            if (cc == '*') {
               if (i == length(qq)) {
                  hasStar = true;
                  break;
               }
               return(5);
            }
         }
         if (cc != '@' && cc != '$' && cc != '#' && cc != '-'
             && !isdigit(cc)
             && !isalpha(cc)) {
            return(5);
         }
      }
   }
   return(0);
}

// Check the volume serial.
// Retn: 0 OK, !0 error
static int checkVolSerAndUnit(_str text)
{
   // Total length must be less than 6.
   if (length(text) > 6) return(1);

   // First char must be A-Z
   _str firstChar = substr(text, 1, 1);
   if (!isalpha(firstChar)) return(4);

   // Subsequent chars must be A-Z0-9
   int i;
   for (i=2; i<=length(text); i++) {
      _str cc = substr(text, i, 1);
      if (!isdigit(cc) && !isalpha(cc)) return(5);
   }
   return(0);
}

// Check the PDS member.
// Retn: 0 OK, !0 error
static int checkPDSMember(_str text)
{
   // Total length must be less than 8.
   if (length(text) > 8) return(1);

   // First char must be A-Z,@,$,#
   _str firstChar = substr(text, 1, 1);
   if (!isalpha(firstChar)
       && firstChar != '@'
       && firstChar != '$'
       && firstChar != '#') return(4);

   // Subsequent chars must be A-Z0-9,@,$,#
   int i;
   for (i=2; i<=length(text); i++) {
      _str cc = substr(text, i, 1);
      if (!isdigit(cc) && !isalpha(cc)
          && firstChar != '@'
          && firstChar != '$'
          && firstChar != '#') return(5);
   }
   return(0);
}

//-----------------------------------------------------------------
defeventtab _s390opt_form;

ctlOK.on_create()
{
   _str opt = get_env(S390OPTENVVAR);
   opt = lowcase(opt);
   ctlDetectMouseMove.p_value = ((pos('-m', opt)) ? 0:1);
   ctlShowToolbars.p_value = ((pos('-t', opt)) ? 0:1);
   ctlBlinkCursor.p_value = ((pos('-c', opt)) ? 0:1);
   ctlUseKeyRelease.p_value = ((pos('-k', opt)) ? 0:1);
}

ctlOK.lbutton_up()
{
   // Build the new optimization option string.
   _str opt = "";
   opt = opt :+ ((ctlDetectMouseMove.p_value) ? "+m":"-m");
   opt = opt :+ ((ctlShowToolbars.p_value) ? "+t":"-t");
   opt = opt :+ ((ctlBlinkCursor.p_value) ? "+c":"-c");
   opt = opt :+ ((ctlUseKeyRelease.p_value) ? "+k":"-k");
   _str oldOpt = get_env(S390OPTENVVAR);
   if (opt != oldOpt) {
      set_env(S390OPTENVVAR, opt);
      updateUserIni();
   }
   p_active_form._delete_window(1);
}

// Create a user's own vslick.ini file from the global vslick.ini.
static _str createUserIniFile()
{
   _str filenopath = _INI_FILE;
   _str filename = _ConfigPath() :+ _INI_FILE;
   _str global_filename = slick_path_search(filenopath);
   if (global_filename == "") {
      // Missing global vslick.ini file!!! Something is wrong here.
      _message_box("Unable to find the global vslick.ini to make a user's local copy");
      return("");
   }
   copy_file(global_filename, filename);
   return(filename);
}

static void updateUserIni()
{
   // Make sure the user has a personal vslick.ini.
   // If one does not exist, make a copy from the global vslick.ini.
   _str filename = _ConfigPath() :+ _INI_FILE;
   if (file_match("-p "maybe_quote_filename(filename),1) == "") {
      filename = createUserIniFile();
      if (filename == "") return;
   }

   // Write new S/390 optimization options.
   _str options = get_env(S390OPTENVVAR);
   _ini_set_value(filename, "Environment", S390OPTENVVAR, options);
}

//-----------------------------------------------------------------
defeventtab _datasets_form;
// Extract only the dataset name.
static _str datasetNameOnly(_str dsname)
{
   _str nameonly;
   nameonly = dsname;
   if (pos(DATASET_ROOT, nameonly)==1) {
      nameonly = substr(dsname, length(DATASET_ROOT)+1);
   }
   if (last_char(nameonly)==FILESEP) {
      nameonly = substr(nameonly, 1, length(nameonly)-1);
   }
   return(nameonly);
}

// Add one data set name, DS.NAME
static void addOneDataSet(_str dsname)
{
   // Add data set to the listbox.
   RegisteredDSInfo currList[];
   currList = ctlAdd.p_user;
   int i,j=0;
   int listbox = _control ctlDataSetList;
   dsname = upcase(dsname);
   int count = listbox.p_Noflines;
   listbox._lbtop();
   _str junk="";
   int found = 0;
   for (i=0; i<count; i++) {
      _str line;
      line = listbox._lbget_text();
      parse line with line junk;
      if (dsname < line) {
         listbox._lbup();
         listbox._lbadd_item(dsname:+" (new)");
         found = 1;
         for (j=count; j>i; j--) {
            currList[j] = currList[j-1];
         }
         currList[i].dsname = dsname;
         currList[i].valid = false;
         currList[i].newds = true;
         currList[i].registerMembers = false;
         ctlAdd.p_user = currList;
         break;
      } else if (dsname == line) {
         found = 1;
         break;
      }
      listbox._lbdown();
   }
   if (!found) {
      listbox._lbbottom();
      listbox._lbadd_item(dsname:+" (new)");
      currList[count].dsname = dsname;
      currList[count].valid = false;
      currList[count].newds = true;
      currList[count].registerMembers = false;
      ctlAdd.p_user = currList;
   }
   listbox._lbselect_line();

   // Update the PDS member refresh and register buttons.
   enableRefreshPDSMembers();
}

// Add a new data set name into the list.
// Data set name can contain trailing wildcard (*).
static void addDataSet(_str dsname)
{
   // Add exactly one data set.
   if (last_char(dsname) != '*') {
      addOneDataSet(dsname);
      return;
   }

   // Data set name has trailing wildcard (*), get the list
   // and add one at a time.
   _str dsmatch = file_match(DATASET_ROOT:+dsname, 1);
   while (dsmatch != "") {
      // Convert //DS.NAME/ to DS.NAME
      if (last_char(dsmatch) == FILESEP) {
         dsmatch=substr(dsmatch, 1, length(dsmatch)-1);
      }
      if (substr(dsmatch,1,length(DATASET_ROOT)) == DATASET_ROOT) {
         dsmatch=substr(dsmatch, length(DATASET_ROOT)+1);
      }

      // Add one data set to list.
      addOneDataSet(dsmatch);

      // Next data set in list.
      dsmatch = file_match(DATASET_ROOT:+dsname, 0);
   }
}

// Check to see if the specified dataset name is already in the list.
// Retn: 1 in list, 0 not
static int isInList(_str dsname)
{
   int listbox = _control ctlDataSetList;
   int selLine = -1;
   if (!listbox._lbfind_selected(1)) {
      selLine = listbox.p_line;
   }
   int found = 0;
   if (listbox._lbsearch(dsname) == 0) found = 1;
   if (selLine > 0) {
      listbox.p_line = selLine;
      listbox._lbselect_line();
   }
   return(found);
}

// If the specified dataset name is already in the list, select the line
// in the list.
// Retn: 1 in list, 0 not
static int selectInList(_str dsname)
{
   int listbox = _control ctlDataSetList;
   int selLine = -1;
   if (!listbox._lbfind_selected(1)) {
      selLine = listbox.p_line;
   }
   int len = length(dsname);
   listbox._lbtop();
   listbox._lbup();
   while (!listbox._lbdown()) {
      _str line;
      line = listbox._lbget_text();
      if (substr(line,1,len) == dsname) {
         listbox._lbdeselect_all();
         listbox._lbselect_line();
         return(1);
      }
   }

   // Nothing found. Restore previous selection.
   if (selLine > 0) {
      listbox.p_line = selLine;
      listbox._lbselect_line();
   }
   return(0);
}

// Update the [Datasets] section in the user config file (vslick.ini).
// Retn: 0 OK, !0 error code
static int writeRegisteredDatasets(RegisteredDSInfo (&dslist)[])
{
   // Create temp view to hold the dataset names.
   int oldViewID;
   int viewID;
   oldViewID = _create_temp_view(viewID);
   if (oldViewID == "") {
      return(INSUFFICIENT_MEMORY_RC);
   }
   int i;
   for (i=0; i<dslist._length(); i++) {
      // Each line section has the following format:
      //    DS.NAME fixed pds maxreclen ro regMem
      if (dslist[i].valid) {
         insert_line(dslist[i].dsname" "dslist[i].isFixed" "dslist[i].isPDS" "dslist[i].lrecl" "dslist[i].editRO" "dslist[i].registerMembers);
      } else {
         insert_line(dslist[i].dsname);
      }
   }
   activate_window(oldViewID);

   // Build path to user config file.
   // If user does not a local config file, make the user a personal
   // copy starting with the content of the global config file.
   _str filename;
   _str filenopath;
   _str section;
   section = "Datasets";
   filename=_copy_vslick_ini();

   // Replace the [datasets] section.
   int status = _ini_put_section(filename, section, viewID);
   if (status) {
      _message_box(nls("Unable to update file %s.",filename)"  "get_message(status));
      return(status);
   }
   return(0);
}

// Get the list of registered data sets. The stored list must be sorted.
// Retn: 0 OK, !0 error
static int getRegisteredDataSet(RegisteredDSInfo (&dslist)[])
{
   // Access the config file.
   dslist._makeempty();
   _str inifile = _ConfigPath():+_INI_FILE;
   if (!file_exists(inifile)) return(0);
   int viewid;
   int orig_view_id = p_window_id;
   int status = _ini_get_section(inifile, "Datasets", viewid);
   if (status) {
      // If section is not present, do nothing.
      p_window_id = orig_view_id;
      return(0);
   }
   p_window_id = viewid;

   // Extract the registered dataset info.
   // Line format:
   //    DS.NAME fixed pds maxreclen ro regMem
   int count = 0;
   _str dsname;
   _str isFixed, isPDS, lrecl, isRO, registerMembers;
   _str line;
   top();up();
   for (;;) {
      if (down()) break;
      get_line(line);
      parse line with dsname isFixed isPDS lrecl isRO registerMembers;
      dslist[count].dsname = dsname;
      dslist[count].valid = true;
      dslist[count].newds = false;
      dslist[count].isFixed = (isFixed=="1");
      dslist[count].isPDS = (isPDS=="1");
      dslist[count].lrecl = isnumber(lrecl)?(int)lrecl:0;
      dslist[count].editRO = (isRO=="1");
      dslist[count].registerMembers = (registerMembers=="1");
      //say(dslist[count].dsname" "dslist[count].isFixed" "dslist[count].isPDS" "dslist[count].lrecl" "dslist[count].editRO" "dslist[count].registerMembers);
      count++;
   }

   // Clean up the temp view.
   p_window_id = orig_view_id;
   _delete_temp_view(viewid);
   return(0);
}

_datasets_form.on_load()
{
   // Set focus to the dataset name textbox.
   ctlDSName._set_focus();
}

// Registering PDS members put all the PDS members in
// $VSLICKCONFIG/PDS.NAME. This member list file is read when the
// PDS directory listing is first requested.
void ctlRegisterMembers.lbutton_up()
{
   _str dsname="", junk="";
   boolean listModified = false;
   RegisteredDSInfo currList[];
   currList = ctlAdd.p_user;
   int listbox = _control ctlDataSetList;
   int origLine = listbox.p_line;
   int status = listbox._lbfind_selected(1);
   while (!status) {
      parse listbox._lbget_text() with dsname junk;
      int i;
      for (i=0; i<currList._length(); i++) {
         if (currList[i].dsname == dsname) {
            currList[i].registerMembers = (ctlRegisterMembers.p_value==1);
            listModified = true;
         }
      }
      status = listbox._lbfind_selected(0);
   }
   if (listModified) ctlAdd.p_user = currList;
   listbox.p_line = origLine;
}

// Refreshing a PDS member list rereads the PDS directory and
// rebuilding $VSLICKCONFIG/PDS.NAME.
void ctlRefreshMembers.lbutton_up()
{
   _str dsname="", junk="";
   _str onedsname = "";
   int refreshedCount = 0;
   int listbox = _control ctlDataSetList;
   int origLine = listbox.p_line;
   int status = listbox._lbfind_selected(1);
   while (!status) {
      parse listbox._lbget_text() with dsname junk;
      if (_os390IsPDSMemberRegistered(dsname)) {
         status = _os390UnregisterPDSMembers(dsname);
         if (status) {
            _message_box(nls("Unable to unregister members for %s.\nMembers are not re-registered.",dsname));
            break;
         }
         status = _os390RegisterPDSMembers(dsname);
         if (status) _message_box(nls("Unable to register members for %s.\nMembers are not re-registered.",dsname));
         onedsname = dsname;
         refreshedCount++;
      }
      status = listbox._lbfind_selected(0);
   }
   listbox.p_line = origLine;
   if (refreshedCount == 1) {
      _message_box(nls("Re-registered %s member list.",onedsname));
   } else if (refreshedCount) {
      _message_box(nls("Re-registered %s member lists.",refreshedCount));
   }
}

void ctlOK.on_create(_str dsList="")
{
   // Internals.
   TextOnChangeInfo tinfo;
   tinfo.onChange = 0;
   tinfo.previousText = "";
   ctlDSName.p_user = tinfo;

   // Get the list of registered data sets.
   RegisteredDSInfo dslist[];
   int status = getRegisteredDataSet(dslist);
   if (status) {
      _message_box(nls("Can't get registered data set list.\n",get_message(status)));
      return;
   }

   // Insert into listbox.
   int listbox = ctlDataSetList;
   listbox._lbtop();
   int i;
   for (i=0; i<dslist._length(); i++) {
      listbox._lbadd_item(dslist[i].dsname);
   }
   listbox._lbtop();

   // Save data set list for later comparison and
   // keep current copy to sync with the list box.
   ctlDataSetList.p_user = dslist;
   ctlAdd.p_user = dslist;

   // Initially gray out add/delete buttons.
   ctlAdd.p_enabled = false;
   ctlDelete.p_enabled = false;

   enableRefreshPDSMembers();

   // If there are any data sets to be automatically added,
   // add them to the new now.
   if (dsList != "") {
      _str dsname;
      parse dsList with dsname" "dsList;
      while (dsname != "") {
         // Remove the leading "//" and upcase name.
         if (pos(DATASET_ROOT,dsname)) dsname = substr(dsname,3);
         dsname = upcase(dsname);
         addDataSet(dsname);
         parse dsList with dsname" "dsList;
      }

      // Update the buttons.
      ctlDSName.call_event(CHANGE_OTHER, ctlDSName,ON_CHANGE,'W');
   }
}

ctlOK.lbutton_up()
{
   // Get the list of dataset currently in list.
   RegisteredDSInfo currList[];
   currList = ctlAdd.p_user;

   // Get the data set stat() info. If a data set can not be stat(),
   // don't register it.
   _str skippedList[];
   skippedList._makeempty();
   int count = currList._length();
   int i = 0;
   int status;
   while (i < count) {
      // Do nothing more for existing registerd data sets.
      // To update the stat on an existing data set, remove it from
      // the registered list and add it back in.
      if (!currList[i].newds) {
         i++;
         continue;
      }

      // If data set is migrated, skip it.
      _str fdsname = DATASET_ROOT:+currList[i].dsname;
      if (_os390IsMigrated(fdsname)) {
         skippedList[skippedList._length()] = fdsname" -- Migrated";
         // Remove the data set from the current list.
         int j;
         for (j=i; j<count-1; j++) currList[j] = currList[j+1];
         count--;
         currList._deleteel(count);
         continue;
      }

      // Get the stat() info.
      int isFixed, isPDS, lrecl, blkSize;
      status = _os390DataSetStatInfo(fdsname, isFixed, isPDS, lrecl, blkSize);
      if (status) {
         //_message_box(nls("Unable to get data set stat() information for %s.\nData set is not registered.",fdsname));
         skippedList[skippedList._length()] = fdsname" -- No access";
         // Remove the data set from the current list.
         int j;
         for (j=i; j<count-1; j++) currList[j] = currList[j+1];
         count--;
         currList._deleteel(count);
         continue;
      }
      currList[i].valid = true;
      currList[i].isFixed = (isFixed==1);
      currList[i].isPDS = (isPDS==1);
      currList[i].lrecl = lrecl;
      currList[i].editRO = false;
      i++;
   }

   // Remember the old register member flags in a hash for quick
   // lookup later.
   RegisteredDSInfo savedList[];
   savedList = ctlDataSetList.p_user;
   boolean savedRegisterMemList:[];
   savedRegisterMemList._makeempty();
   for (i=0; i<savedList._length(); i++) {
      savedRegisterMemList:[savedList[i].dsname] = savedList[i].registerMembers;
   }

   // Determine what has been added or deleted and
   // update the "listed" datasets. This is done by comparing
   // the saved dataset list and the current dataset list.
   int savedCount = savedList._length();
   int currCount = currList._length();
   int ii, jj;
   ii = 0;
   jj = 0;
   while (1) {
      // Check for end lists.
      if (ii >= savedCount && jj >= currCount) {
         break;
      }

      // Special case when saved list at the end but
      // new list is not at the end. This means that
      // there are new datasets to be registered.
      if (ii >= savedCount && jj < currCount) {
         for (i=jj; i<currCount; i++) {
            //say("Add to list "currList[i].dsname);
            _os390ListDataSet(currList[i].dsname);
         }
         break;
      }

      // Special case when current list at the end but
      // saved list is not at the end. This means that
      // there are old datasets to be unregistered.
      if (ii < savedCount && jj >= currCount) {
         for (i=ii; i<savedCount; i++) {
            //say("Remove from list "savedList[i].dsname);
            _os390UnlistDataSet(savedList[i].dsname);
         }
         break;
      }

      // Both lists have more to go thru...

      // Same dataset. Skip over this one.
      if (savedList[ii].dsname == currList[jj].dsname) {
         ii++;
         jj++;
         continue;
      }

      // Old dataset is not in new list.
      // Dataset must have been deleted.
      // Remove the dataset from the "listed" datasets.
      if (savedList[ii].dsname < currList[jj].dsname) {
         //say("Remove from list "savedList[ii].dsname);
         _os390UnlistDataSet(savedList[ii].dsname);
         ii++;
         continue;
      }

      // New dataset has been added.
      //say("Add to list "currList[jj].dsname);
      _os390ListDataSet(currList[jj].dsname);
      jj++;
   }

   // Update [Datasets] section in vslick.ini
   writeRegisteredDatasets(currList);

   // Register the PDS members.
   for (i=0; i<currList._length(); i++) {
      boolean needRegister = false;
      boolean needUnregister = false;
      if (currList[i].newds && currList[i].isPDS && currList[i].registerMembers) {
         needRegister = true;
      } else if (savedRegisterMemList._indexin(currList[i].dsname)) {
         if (currList[i].valid && currList[i].isPDS) {
            if (savedRegisterMemList:[currList[i].dsname] != currList[i].registerMembers) {
               if (currList[i].registerMembers) {
                  needRegister = true;
               } else {
                  needUnregister = true;
               }
            }
         }
      }
      if (needRegister) {
         status = _os390RegisterPDSMembers(currList[i].dsname);
         if (status) _message_box(nls("Unable to register members for %s.\nMembers are not registered.",currList[i].dsname));
      } else if (needUnregister) {
         status = _os390UnregisterPDSMembers(currList[i].dsname);
         if (status) _message_box(nls("Unable to unregister members for %s.\nMembers are not unregistered.",currList[i].dsname));
      }
   }

   // If some data sets were skipped, show the list now.
   int skippedCount = skippedList._length();
   if (skippedCount) {
      _str msg;
      if (skippedCount > 1) {
         msg = "The following data sets were not registered:\n\n";
      } else {
         msg = "The following data set was not registered:\n\n";
      }
      for (i=0; i<skippedList._length(); i++) {
         // Limit data set listing to just 10... so that the message box
         // does not get too long.
         if (i > 10) {
            msg = msg :+ "     ...";
            break;
         }
         msg = msg :+ "     " :+ skippedList[i] :+ "\n";
      }
      _message_box(msg);
   }

   // Close the form.
   p_active_form._delete_window(1);
}

void ctlAdd.lbutton_up()
{
   // Add the data set to the registered listbox.
   int textbox = ctlDSName;
   addDataSet(textbox.p_text);
   textbox.p_text = "";
   textbox._set_sel(1);

   // After a successful add, clear the last valid text.
   TextOnChangeInfo tinfo = ctlDSName.p_user;
   tinfo.previousText = "";
   ctlDSName.p_user = tinfo;

   // Set focus to the dataset name textbox.
   ctlDSName._set_focus();
}

void ctlDelete.lbutton_up()
{
   int listbox = _control ctlDataSetList;
   int count = listbox.p_Noflines;
   if (!count) return;
   if (!listbox.p_Nofselected) return;
   RegisteredDSInfo currList[];
   currList = ctlAdd.p_user;

   // Delete all selected lines.
   int last = -1;
   listbox._lbtop();
   int curri = 0;
   int oriCount = count;
   int i;
   boolean listModified = false;
   for (i=0; i<oriCount; i++) {
      if (listbox._lbisline_selected()) {
         last = listbox.p_line;
         listbox._lbdelete_item();
         int j;
         for (j=curri; j<count-1; j++) {
            currList[j] = currList[j+1];
         }
         count--;
         currList._deleteel(count);
         listModified = true;
      } else {
         listbox._lbdown();
         curri++;
      }
   }
   if (listModified) ctlAdd.p_user = currList;

   // Restore previous selection, if there was one.
   listbox._set_focus();
   if (listbox.p_Noflines) {
      if (last > 0 && last <= listbox.p_Noflines) {
         listbox.p_line = last;
      } else {
         listbox.p_line = listbox.p_Noflines;
      }
      listbox._lbselect_line();
   }

   // Update add button.
   ctlDSName.call_event(CHANGE_OTHER, ctlDSName,ON_CHANGE,'W');

   // Update controls.
   enableRefreshPDSMembers();
   enableDelete();
}

static void enableDelete()
{
   if (!ctlDataSetList.p_Noflines) {
      if (ctlDelete.p_enabled == true) {
         ctlDelete.p_enabled = false;
      }
      return;
   }
   if (ctlDataSetList.p_Nofselected) {
      if (ctlDelete.p_enabled == false) {
         ctlDelete.p_enabled = true;
      }
   } else {
      if (ctlDelete.p_enabled == true) {
         ctlDelete.p_enabled = false;
      }
   }
}

void ctlDSName.on_change() // _datasets_form
{
   TextOnChangeInfo tinfo = p_user;
   if (tinfo.onChange) return;
   _str text = p_text;
   if (text :== "") {
      ctlAdd.p_enabled = false;
      ctlOK.p_default = true;
      ctlAdd.p_default = false;
      enableDelete();
      return;
   }
   text = upcase(text);
   int status = checkDSName(text, true);
   if (status) {
      if (status != 3) {
         _beep();
         text = tinfo.previousText;
         _set_sel(length(text)+1);
      } else {
         tinfo.previousText = text;
      }
   } else {
      tinfo.previousText = text;
   }
   tinfo.onChange = 1;
   p_user = tinfo;
   p_text = text;
   tinfo.onChange = 0;
   p_user = tinfo;

   // Make sure the other buttons match the right state.
   selectInList(text);
   if (text == "") {
      ctlAdd.p_enabled = false;
      ctlOK.p_default = true;
      ctlAdd.p_default = false;
      enableDelete();
   } else if (isInList(text)) {
      ctlAdd.p_enabled = false;
      ctlOK.p_default = true;
      ctlAdd.p_default = false;
      //ctlDelete.p_enabled = true;
      //ctlDelete.p_default = true;
   } else {
      ctlAdd.p_enabled = true;
      ctlOK.p_default = false;
      ctlAdd.p_default = true;
      enableDelete();
   }
}

static void enableRefreshPDSMembers()
{
   // If nothing is selected, do nothing.
   int listbox = _control ctlDataSetList;
   if (!listbox.p_Noflines || !listbox.p_Nofselected) {
      ctlRegisterMembers.p_enabled = false;
      ctlRegisterMembers.p_value = 0;
      ctlRefreshMembers.p_enabled = false;
      return;
   }

   // Update register PDS members.
   _str dsname="", junk="";
   RegisteredDSInfo currList[];
   currList = ctlAdd.p_user;
   RegisteredDSInfo origList[];
   origList = ctlDataSetList.p_user;
   boolean registerMembers = true;
   boolean allTheSame = true;
   boolean first = true;
   boolean allValidPDS = true;
   boolean allMayBePDS = true;
   boolean allMemberRegistered = true;
   int origLine = listbox.p_line;
   int status = listbox._lbfind_selected(1);
   while (!status) {
      parse listbox._lbget_text() with dsname junk;
      int i;
      for (i=0; i<currList._length(); i++) {
         if (currList[i].dsname == dsname) {
            if (first) {
               registerMembers = currList[i].registerMembers;
               first = false;
            } else {
               if (currList[i].registerMembers != registerMembers) {
                  allTheSame = false;
                  break;
               }
            }
            if (!currList[i].valid || !currList[i].isPDS) {
               allValidPDS = false;
            }
            if (currList[i].valid && !currList[i].isPDS) {
               allMayBePDS = false;
            }
         }
      }
      for (i=0; i<origList._length(); i++) {
         if (origList[i].dsname == dsname) {
            if (!origList[i].valid || !origList[i].isPDS || !origList[i].registerMembers) {
               allMemberRegistered = false;
            }
         }
      }
      status = listbox._lbfind_selected(0);
   }
   if (allTheSame && allMayBePDS) {
      ctlRegisterMembers.p_enabled = true;
      ctlRegisterMembers.p_value = (int)registerMembers;
   } else {
      ctlRegisterMembers.p_enabled = false;
      ctlRegisterMembers.p_value = 0;
   }
   ctlRefreshMembers.p_enabled = allMemberRegistered?true:false;
   listbox.p_line = origLine;
}

void ctlDataSetList.on_change(int reason)
{
   // Change the text box text but prevent another processing.
   TextOnChangeInfo tinfo = ctlDSName.p_user;
   tinfo.onChange = 1;
   ctlDSName.p_user = tinfo;
   _str junk = "";
   _str dsname = _lbget_text();
   parse dsname with dsname junk;
   ctlDSName.p_text = dsname;
   tinfo.onChange = 0;
   ctlDSName.p_user = tinfo;

   enableRefreshPDSMembers();
   enableDelete();
}

//-----------------------------------------------------------------
defeventtab _dsalloc_form;
ctlOK.on_create() // _dsalloc_form
{
   // Internals.
   TextOnChangeInfo tinfo;
   tinfo.onChange = 0;
   tinfo.previousText = "";
   ctlDSName.p_user = tinfo;
   ctlVolSer.p_user = tinfo;
   ctlUnit.p_user = tinfo;
   ctlPrimary.p_user = tinfo;
   ctlSecondary.p_user = tinfo;
   ctlDirBlks.p_user = tinfo;
   ctlRecLen.p_user = tinfo;
   ctlBlkSize.p_user = tinfo;

   // Init space unit choices.
   int listbox = ctlSpaceUnit.p_window_id;
   listbox._lbtop();
   listbox._lbadd_item("CYLINDERS");
   listbox._lbadd_item("TRACKS");
   listbox._lbadd_item("BLOCKS");

   // Init data set organization choices.
   listbox = ctlDSOrg.p_window_id;
   listbox._lbtop();
   listbox._lbadd_item("PO");
   listbox._lbadd_item("PS");
   listbox._lbadd_item("POU");
   listbox._lbadd_item("PSU");

   // Init record format choices.
   listbox = ctlRecFm.p_window_id;
   listbox._lbtop();
   listbox._lbadd_item("F");
   listbox._lbadd_item("V");
   listbox._lbadd_item("FB");
   listbox._lbadd_item("VB");
   // Take out support for spanned records now.
   //listbox._lbadd_item("FBS");
   //listbox._lbadd_item("VBS");

   // Dialog retrieval.
   ctlVolSer._retrieve_value();
   ctlUnit._retrieve_value();
   ctlSpaceUnit.p_text = _retrieve_value("_dsalloc.SpaceUnit");
   ctlPrimary._retrieve_value();
   ctlSecondary._retrieve_value();
   ctlDSOrg.p_text = _retrieve_value("_dsalloc.DSOrg");
   ctlDirBlks._retrieve_value();
   ctlRecFm.p_text = _retrieve_value("_dsalloc.RecFm");
   ctlRecLen._retrieve_value();
   ctlBlkSize._retrieve_value();

   // Default the space unit, organization, and record format, just
   // in case dialog retrieval has nothing.
   if (ctlSpaceUnit.p_text == "") {
      ctlSpaceUnit.p_text = "CYLINDERS";
   }
   if (ctlDSOrg.p_text == "") {
      ctlDSOrg.p_text = "PO";
   }
   if (ctlRecFm.p_text == "") {
      ctlRecFm.p_text = "FB";
   }
}

int ctlDSName.on_change()
{
   TextOnChangeInfo tinfo = p_user;
   if (tinfo.onChange) return(0);
   _str text = ctlDSName.p_text;
   if (text :== "") return(0);
   text = upcase(text);
   int status = checkDSName(text);
   if (status) {
      if (status != 3) {
         _beep();
         text = tinfo.previousText;
         ctlDSName._set_sel(length(text)+1);
      } else {
         tinfo.previousText = text;
      }
   } else {
      tinfo.previousText = text;
   }
   tinfo.onChange = 1;
   p_user = tinfo;
   p_text = text;
   tinfo.onChange = 0;
   p_user = tinfo;
   return(0);
}

int ctlVolSer.on_change()
{
   TextOnChangeInfo tinfo = p_user;
   if (tinfo.onChange) return(0);
   _str text = p_text;
   if (text :!= "") {
      text = upcase(text);
      int status = checkVolSerAndUnit(text);
      if (status) {
         _beep();
         text = tinfo.previousText;
         _set_sel(length(text)+1);
      }
   }
   if (text != "") {
      if (ctlUnit.p_enabled == true) {
         ctlUnit.p_enabled = false;
      }
   } else {
      if (ctlUnit.p_enabled == false) {
         ctlUnit.p_enabled = true;
      }
   }
   tinfo.onChange = 1;
   p_user = tinfo;
   p_text = text;
   tinfo.previousText = text;
   tinfo.onChange = 0;
   p_user = tinfo;
   return(0);
}

int ctlUnit.on_change()
{
   TextOnChangeInfo tinfo = p_user;
   if (tinfo.onChange) return(0);
   _str text = p_text;
   if (text :!= "") {
      text = upcase(text);
      int status = checkVolSerAndUnit(text);
      if (status) {
         _beep();
         text = tinfo.previousText;
         _set_sel(length(text)+1);
      }
   }
   if (text != "") {
      if (ctlVolSer.p_enabled == true) {
         ctlVolSer.p_enabled = false;
      }
   } else {
      if (ctlVolSer.p_enabled == false) {
         ctlVolSer.p_enabled = true;
      }
   }
   tinfo.onChange = 1;
   p_user = tinfo;
   p_text = text;
   tinfo.previousText = text;
   tinfo.onChange = 0;
   p_user = tinfo;
   return(0);
}

int ctlPrimary.on_change()
{
   TextOnChangeInfo tinfo = p_user;
   if (tinfo.onChange) return(0);
   if (p_enabled == false) return(0);
   _str text = p_text;
   if (text :!= "") {
      if (length(text) > 6 || !isnumber(text)) {
         _beep();
         text = tinfo.previousText;
         _set_sel(length(text)+1);
      }
   }
   tinfo.onChange = 1;
   p_user = tinfo;
   p_text = text;
   tinfo.previousText = text;
   tinfo.onChange = 0;
   p_user = tinfo;
   return(0);
}

void ctlDSOrg.on_change(int reason)
{
   if (ctlDSOrg.p_text == "PO" || ctlDSOrg.p_text == "POU") {
      if (ctlDirBlks.p_enabled == false) {
         ctlDirBlks.p_enabled = true;
      }
   } else {
      if (ctlDirBlks.p_enabled == true) {
         ctlDirBlks.p_enabled = false;
      }
      ctlDirBlks.p_text = "";
   }
}

int ctlOK.lbutton_up()
{
   // Check data set name.
   _str dsname = ctlDSName.p_text;
   if (dsname == "") {
      _message_box("Missing data set name.");
      ctlDSName._set_focus();
      return(1);
   }
   if (checkDSName(dsname)) {
      _message_box("Invalid data set name.");
      ctlDSName._set_focus();
      return(1);
   }

   // Either the volume serial or the generic unit can be specified
   // but not both. Both empty is OK.
   _str volser = ctlVolSer.p_text;
   _str unit = ctlUnit.p_text;
   if (volser != "" && unit != "") {
      _message_box("Specify either volume serial or generic unit but not both.");
      ctlVolSer._set_focus();
      return(1);
   }

   // Space unit.
   int spaceUnit = SPACEUNIT_CYLS;
   switch (ctlSpaceUnit.p_text) {
   case "CYLINDERS":
      spaceUnit = SPACEUNIT_CYLS;
      break;
   case "TRACKS":
      spaceUnit = SPACEUNIT_TRACKS;
      break;
   case "BLOCKS":
      spaceUnit = SPACEUNIT_BLOCKS;
      break;
   case "KB":
      spaceUnit = SPACEUNIT_KB;
      break;
   case "MB":
      spaceUnit = SPACEUNIT_MB;
      break;
   }

   // Check primary and secondary quantity.
   if (ctlPrimary.p_text == "") {
      _message_box("Missing primary quantity.");
      ctlPrimary._set_focus();
      return(1);
   }
   int primary = (int)ctlPrimary.p_text;
   if (primary < 1) {
      _message_box("Invalid primary quantity.");
      ctlPrimary._set_focus();
      return(1);
   }
   if (ctlSecondary.p_text == "") {
      ctlSecondary.p_text = "0";
   }
   int secondary = (int)ctlSecondary.p_text;

   // Record format.
   int recFm = RECFM_FB;
   switch (ctlRecFm.p_text) {
   case "F":
      recFm = RECFM_F;
      break;
   case "V":
      recFm = RECFM_V;
      break;
   case "FB":
      recFm = RECFM_FB;
      break;
   case "VB":
      recFm = RECFM_VB;
      break;
   case "FBS":
      recFm = RECFM_FBS;
      break;
   case "VBS":
      recFm = RECFM_VBS;
      break;
   }

   // Data set organization.
   int dsOrg = DSORG_PO;
   switch (ctlDSOrg.p_text) {
   case "PO":
      dsOrg = DSORG_PO;
      break;
   case "POU":
      dsOrg = DSORG_POU;
      break;
   case "PS":
      dsOrg = DSORG_PS;
      break;
   case "PSU":
      dsOrg = DSORG_PSU;
      break;
   }

   // Check directory block count.
   int dirBlks = 0;
   if (dsOrg == DSORG_PO || dsOrg == DSORG_POU) {
      if (ctlDirBlks.p_text == "") {
         _message_box("Missing directory blocks.");
         ctlDirBlks._set_focus();
         return(1);
      }
      dirBlks = (int)ctlDirBlks.p_text;
      if (dirBlks < 1) {
         _message_box("Invalid directory blocks.");
         dirBlks._set_focus();
         return(1);
      }
   }

   // Quick check on record length and block size.
   if (ctlRecLen.p_text == "") {
      _message_box("Missing record length.");
      ctlRecLen._set_focus();
      return(1);
   }
   if (ctlBlkSize.p_text == "") {
      _message_box("Missing block size.");
      ctlBlkSize._set_focus();
      return(1);
   }
   int recLen = (int)ctlRecLen.p_text;
   int blkSize = (int)ctlBlkSize.p_text;
   if (blkSize < 0 || blkSize > 32760) {
      _message_box("Invalid block size.");
      ctlBlkSize._set_focus();
      return(1);
   }
   if (recLen < 0 || recLen > 32760) {
      _message_box("Invalid record length.");
      ctlRecLen._set_focus();
      return(1);
   }

   // Check record length and block size combination.
   if (recFm == RECFM_F) {
      if (blkSize < recLen) {
         _message_box("Invalid record length and block size combination.");
         ctlRecLen._set_focus();
         return(1);
      }
   } else if (recFm == RECFM_FB) {
      if (blkSize % recLen) {
         _message_box("Invalid record length and block size combination.\nBlock size must be an integral multiple of record length.");
         ctlRecLen._set_focus();
         return(1);
      }
   } else if (recFm == RECFM_V || recFm == RECFM_VB) {
      // Check record length again.
      if (recLen < 5) {
         _message_box("Invalid variable record length.");
         ctlRecLen._set_focus();
         return(1);
      }

      // Check combo.
      int largestRec = blkSize - 4;
      if (recLen > largestRec) {
         _message_box("Invalid record length and block size combination.\nRecord length is too large for block size.");
         ctlRecLen._set_focus();
         return(1);
      }
   }

   // Dialog retrieval.
   _append_retrieve(ctlVolSer, ctlVolSer.p_text);
   _append_retrieve(ctlUnit, ctlUnit.p_text);
   _append_retrieve(0, ctlSpaceUnit.p_text, "_dsalloc.SpaceUnit");
   _append_retrieve(ctlPrimary, ctlPrimary.p_text);
   _append_retrieve(ctlSecondary, ctlSecondary.p_text);
   _append_retrieve(0, ctlDSOrg.p_text, "_dsalloc.DSOrg");
   _append_retrieve(ctlDirBlks, ctlDirBlks.p_text);
   _append_retrieve(0, ctlRecFm.p_text, "_dsalloc.RecFm");
   _append_retrieve(ctlRecLen, ctlRecLen.p_text);
   _append_retrieve(ctlBlkSize, ctlBlkSize.p_text);

   // Create the new dataset.
   int status;
   dsname = DATASET_ROOT :+ dsname;
   mou_hour_glass(1);
   message("Allocating "dsname" ...");
   status = _os390NewDS(dsname, volser, unit, spaceUnit
                        ,primary, secondary, dirBlks
                        ,recFm, recLen, blkSize, dsOrg);
   clear_message();
   mou_hour_glass(0);
   if (status) {
      _str msg = "Unable to allocate data set.\nAllocation failed.";
      _message_box(msg);
      return(1);
   }

   // Clean up.
   p_active_form._delete_window(0);
   return(0);
}
void ctlCancel.lbutton_up()
{
   p_active_form._delete_window(1);
}

_dsalloc_form.on_load()
{
   // Set focus to the dataset name textbox.
   ctlDSName._set_focus();
}

//---------------------------------------------------------------
defeventtab _dscopy_form;

void _dscopy_form.on_load()
{
   // Set focus to the dataset name textbox.
   _str opcode = ctlCancel.p_user;
   if (opcode == "copy") {
      ctlToDataSet._set_focus();
   } else {
      if (ctlOK.p_user != "") {
         ctlToMember._set_focus();
      } else {
         ctlToDataSet._set_focus();
      }
   }
}

/*
   arg(1)  ==> 0x01  -- disable "Allocate data set..."
               0x02  -- disable "To Member"
               0x04  -- disable "Volume"
               0x08  -- disable "No prompt"
               0x10  -- disable "Destination is seq"
*/
void ctlOK.on_create(int turnoff, _str sourceds, _str opcode)
{
   // Internals.
   TextOnChangeInfo tinfo;
   tinfo.onChange = 0;
   tinfo.previousText = "";
   ctlToDataSet.p_user = tinfo;
   ctlToMember.p_user = tinfo;
   ctlVolume.p_user = tinfo;

   // Fill the help area.
   _str helpText;
   if (opcode == "copy") {
      helpText = "Select 'Destination is...' if the destination is a sequential data set.  When copying PDS members to another PDS, you only need to specify the destination PDS and select 'Don't prompt again...'  If the destination data set does not exist and 'Allocate data set...' is selected, the destination data set will be automatically created with attributes like that of the source.";
   } else {
      helpText = "Type the new data set name and/or PDS member.\n\nA data set can not be renamed to a PDS member and vice-versa.";
   }
   ctlHelpLabel.p_caption = helpText;

   // Take only the data set name. Strip the leading "//"
   // and PDS member.
   _str member = "";
   sourceds = upcase(sourceds);
   if (pos(DATASET_ROOT,sourceds) == 1) {
      sourceds = substr(sourceds,3);
      int p = pos(FILESEP,sourceds);
      if (p) {
         member = substr(sourceds,p+1);
         sourceds = substr(sourceds,1,p-1);
      }
   }
   _str fromds = sourceds;
   if (member != "") {
      fromds = fromds :+ "(" :+ member :+ ")";
   }
   ctlFrom.p_caption = fromds;

   // If initial data set is specified, use it.
   if (opcode == "rename") {
      p_active_form.p_caption = "Rename Data Set";
      if (member != "") {
         tinfo.previousText = sourceds;
         ctlToDataSet.p_user = tinfo;
         ctlToDataSet.p_text = sourceds;
         ctlToDataSet.p_ReadOnly = true;
      }
   }
   ctlToMember.p_text = "";
   ctlVolume.p_text = "";
   ctlNoPrompt.p_value = 0;

   // Disable certain controls.
   if (turnoff & 0x01) { // "allocate data set..."
      ctlAllocIfNeeded.p_enabled = false;
   }
   if (turnoff & 0x02) { // "member"
      ctlToMember.p_enabled = false;
   }
   if (turnoff & 0x04) { // "volume"
      ctlVolume.p_enabled = false;
   }
   if (turnoff & 0x08) { // "no prompt"
      ctlNoPrompt.p_enabled = false;
   } else {
      ctlNoPrompt.p_value = 1;
   }
   if (turnoff & 0x10) { // "dest is seq"
      ctlDestAsPS.p_enabled = false;
   }
   ctlNoPrompt.p_user = turnoff;
   if (opcode == "copy") {
      ctlAllocIfNeeded.p_value = 1;
   }
   ctlAllocIfNeeded.p_user = sourceds;
   ctlOK.p_user = member;
   ctlCancel.p_user = opcode;

   // Dialog retrieval.
   if (opcode != "rename") {
      ctlToDataSet._retrieve_value();
      ctlVolume._retrieve_value();
   }
}

void ctlNoPrompt.lbutton_up()
{
   int turnoff = ctlNoPrompt.p_user;
   if (p_value == 1) {
      ctlToMember.p_text = "";
      ctlToMember.p_enabled = false;
   } else {
      if (turnoff & 0x08) { // "no prompt"
         ctlToMember.p_enabled = false;
      } else {
         ctlToMember.p_enabled = true;
      }
   }
}

void ctlDestAsPS.lbutton_up()
{
   if (p_value == 1) {
      p_user = ctlNoPrompt.p_value;
      ctlNoPrompt.p_value = 0;
   } else {
      ctlNoPrompt.p_value = p_user;
   }
}

ctlOK.lbutton_up()
{
   // Check data set name.
   _str dsname = ctlToDataSet.p_text;
   if (dsname == "") {
      _message_box("Missing data set name.");
      ctlToDataSet._set_focus();
      return(1);
   }
   if (checkDSName(dsname)) {
      _message_box("Invalid data set name.");
      ctlToDataSet._set_focus();
      return(1);
   }

   // If renaming data set, make sure new name is different.
   if (ctlCancel.p_user == "rename") {
      if (dsname == ctlAllocIfNeeded.p_user && ctlOK.p_user == "") {
         _message_box("When renaming data set,\na new name must be specified.");
         ctlToDataSet._set_focus();
         return(1);
      }
      if (ctlToMember.p_enabled && ctlToMember.p_text == "") {
         _message_box("When renaming PDS member,\na new member name must be specified.");
         ctlToMember._set_focus();
         return(1);
      }
   }

   // Check member.
   _str member = ctlToMember.p_text;
   _str sourceds = ctlAllocIfNeeded.p_user;
   if (ctlCancel.p_user == "copy") {
      if (ctlToMember.p_enabled && dsname == sourceds && member == "") {
         _message_box("When copying a member to the same PDS,\na new name must be specified.");
         ctlToMember._set_focus();
         return(1);
      }
   }

   // Check volume.
   _str volume = ctlVolume.p_text;

   // Dialog retrieval.
   _append_retrieve(ctlToDataSet, ctlToDataSet.p_text);
   _append_retrieve(ctlVolume, ctlVolume.p_text);

   // Return the info.
   _param1 = DATASET_ROOT :+ dsname;
   _param2 = ctlAllocIfNeeded.p_value;
   _param3 = member;
   _param4 = volume;
   _param5 = ctlNoPrompt.p_value;
   _param6 = ctlDestAsPS.p_value;
   p_active_form._delete_window(1);
   return(0);
}

int ctlToDataSet.on_change()
{
   TextOnChangeInfo tinfo = p_user;
   if (tinfo.onChange) return(0);
   _str text = ctlToDataSet.p_text;
   if (text :== "") return(0);
   text = upcase(text);
   int status = checkDSName(text);
   if (status) {
      if (status != 3) {
         _beep();
         text = tinfo.previousText;
         ctlToDataSet._set_sel(length(text)+1);
      } else {
         tinfo.previousText = text;
      }
   } else {
      tinfo.previousText = text;
   }
   tinfo.onChange = 1;
   p_user = tinfo;
   p_text = text;
   tinfo.onChange = 0;
   p_user = tinfo;
   return(0);
}

int ctlVolume.on_change()
{
   TextOnChangeInfo tinfo = p_user;
   if (tinfo.onChange) return(0);
   _str text = p_text;
   if (text :!= "") {
      text = upcase(text);
      int status = checkVolSerAndUnit(text);
      if (status) {
         _beep();
         text = tinfo.previousText;
         _set_sel(length(text)+1);
      }
   }
   tinfo.onChange = 1;
   p_user = tinfo;
   p_text = text;
   tinfo.previousText = text;
   tinfo.onChange = 0;
   p_user = tinfo;
   return(0);
}

int ctlToMember.on_change()
{
   TextOnChangeInfo tinfo = p_user;
   if (tinfo.onChange) return(0);
   _str text = p_text;
   if (text :!= "") {
      text = upcase(text);
      int status = checkPDSMember(text);
      if (status) {
         _beep();
         text = tinfo.previousText;
         _set_sel(length(text)+1);
      }
   }
   tinfo.onChange = 1;
   p_user = tinfo;
   p_text = text;
   tinfo.previousText = text;
   tinfo.onChange = 0;
   p_user = tinfo;
   if (ctlCancel.p_user == "copy" && !(ctlNoPrompt.p_user & 0x08)) {
      if (text != "") {
         if (ctlNoPrompt.p_enabled == true) {
            ctlNoPrompt.p_enabled = false;
         }
         ctlNoPrompt.p_value = 0;
      } else {
         if (ctlNoPrompt.p_enabled == false) {
            ctlNoPrompt.p_enabled = true;
         }
      }
   }
   return(0);
}


//---------------------------------------------------------------
defeventtab _dsinfo_form;

/**
 * Convert year and day of year into YYYY/MM/DD format.
 *
 * @param year      year
 * @param dayOfYear day of year
 * @return date in YYYY/MM/DD format
 */
static _str dayOfYearToDate(int year, int dayOfYear)
{
   int daysInMonth[];
   daysInMonth[0] = 31;
   daysInMonth[1] = 28;
   daysInMonth[2] = 31;
   daysInMonth[3] = 30;
   daysInMonth[4] = 31;
   daysInMonth[5] = 30;
   daysInMonth[6] = 31;
   daysInMonth[7] = 31;
   daysInMonth[8] = 30;
   daysInMonth[9] = 31;
   daysInMonth[10] = 30;
   daysInMonth[11] = 31;

   // Special case.
   if (!year) return("***None***");

   // Convert day of year into the month and day of month.
   int count = dayOfYear;
   int month = 1;
   int dayOfMonth = 0;
   int i;
   for (i=0; i<12; i++) {
      // Get the days in month. Leap year has extra day in Feb.
      int dd = daysInMonth[i];
      if (i == 1 && !(year % 4)) dd++;
      if (count <= dd) {
         dayOfMonth = count;
         break;
      }
      month++;
      count = count - dd;
   }

   _str dateText = year;
   if (month < 10) {
      dateText = dateText :+ "/0":+ month;
   } else {
      dateText = dateText :+ "/":+ month;
   }
   if (dayOfMonth < 10) {
      dateText = dateText :+ "/0":+ dayOfMonth;
   } else {
      dateText = dateText :+ "/":+ dayOfMonth;
   }
   return(dateText);
}

static _str parseLISTDSIInfo(_str rawText)
{
   _str formattedInfo = "";
   typeless SYSMSGLVL1, SYSMSGLVL2, SYSREASON, SYSDSNAME, SYSVOLUME, SYSUNIT, SYSDSORG, SYSRECFM, SYSLRECL, SYSBLKSIZE, SYSKEYLEN, SYSALLOC, SYSUSED, SYSUSEDPAGES, SYSPRIMARY, SYSSECONDS, SYSUNITS, SYSEXTENTS, SYSCREATEYEAR, SYSCREATEDAY, SYSREFDATEYEAR, SYSREFDATEDAY, SYSEXDATEYEAR, SYSEXDATEDAY, SYSPASSWORD, SYSRACFA, SYSUPDATED, SYSTRKSCYL, SYSBLKSTRK, SYSADIRBLK, SYSUDIRBLK, SYSMEMBERS, SYSDSSMS, SYSDATACLASS, SYSSTORCLASS, SYSMGMTCLASS;
   parse rawText with SYSMSGLVL1','SYSMSGLVL2','SYSREASON','SYSDSNAME','SYSVOLUME','SYSUNIT','SYSDSORG','SYSRECFM','SYSLRECL','SYSBLKSIZE','SYSKEYLEN','SYSALLOC','SYSUSED','SYSUSEDPAGES','SYSPRIMARY','SYSSECONDS','SYSUNITS','SYSEXTENTS','SYSCREATEYEAR','SYSCREATEDAY','SYSREFDATEYEAR','SYSREFDATEDAY','SYSEXDATEYEAR','SYSEXDATEDAY','SYSPASSWORD','SYSRACFA','SYSUPDATED','SYSTRKSCYL','SYSBLKSTRK','SYSADIRBLK','SYSUDIRBLK','SYSMEMBERS','SYSDSSMS','SYSDATACLASS','SYSSTORCLASS','SYSMGMTCLASS',';
   //                            ,            ,0000       ,ETPRPIN.FB.RL38.BS23446
   //                                                                 ,SMSP02     ,3380     ,PO        ,FB        ,38        ,23446       ,0          ,2         ,2        ,              ,1           ,1           ,TRACK     ,2           ,2000           ,251           ,2000            ,262            ,0              ,              ,NONE         ,GENERIC   ,1           ,15          ,2           ,1           ,1           ,1           ,PDS       ,              ,SC280         ,MCSTD        ,

   //DATA SET NAME                                DSORG RECFM LRECL BLKSZ PRIMA SECND ALUNIT EXTND ALLOC DIRBLK USED   USEDIR NUMMEM MGMTCLS STORCLS VOLSER DEV  CREATED    REFERENCED EXPIRE
   //-------------------------------------------- ----- ----- ----- ----- ----- ----- ------ ----- ----- ------ ------ ------ ------ ------- ------- ------ ---- ---------- ---------- ----------
   formattedInfo = formattedInfo :+ substr(SYSDSNAME, 1, 44) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSDSORG, 1, 5) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSRECFM, 1, 5) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSLRECL, 1, 5) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSBLKSIZE, 1, 5) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSPRIMARY, 1, 5) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSSECONDS, 1, 5) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSUNITS, 1, 6) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSEXTENTS, 1, 5) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSALLOC, 1, 5) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSADIRBLK, 1, 6) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSUSED, 1, 6) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSUDIRBLK, 1, 6) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSMEMBERS, 1, 6) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSMGMTCLASS, 1, 7) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSSTORCLASS, 1, 7) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSVOLUME, 1, 6) :+ " ";
   formattedInfo = formattedInfo :+ substr(SYSUNIT, 1, 4) :+ " ";
   formattedInfo = formattedInfo :+ dayOfYearToDate(SYSCREATEYEAR,SYSCREATEDAY) :+ " ";
   formattedInfo = formattedInfo :+ dayOfYearToDate(SYSREFDATEYEAR,SYSREFDATEDAY) :+ " ";
   formattedInfo = formattedInfo :+ dayOfYearToDate(SYSEXDATEYEAR,SYSEXDATEDAY) :+ " ";
   return(formattedInfo);
}

void _dsinfo_form.on_resize()
{
   int form_width = p_active_form.p_client_width*_twips_per_pixel_x();
   int form_height = p_active_form.p_client_height*_twips_per_pixel_y();

   // Calc new button's Y and list height.
   int newButtonY,newListH;
   int gapY = 5;
   newButtonY = form_height - _ly2ly(SM_PIXEL,SM_TWIP,gapY) - ctlOK.p_height;
   newListH = newButtonY - _ly2ly(SM_PIXEL,SM_TWIP,gapY) - ctlInfo.p_y;
   if (newListH < _ly2ly(SM_PIXEL,SM_TWIP,80)) {
      return;
   }

   // Calc new list width.
   int newListW;
   int gapX = ctlInfo.p_x;
   newListW = form_width - gapX - ctlInfo.p_x;
   if (newListW < _lx2lx(SM_PIXEL,SM_TWIP,200)) {
      return;
   }

   // Move the button.
   ctlOK._move_window(ctlOK.p_x, newButtonY, ctlOK.p_width, ctlOK.p_height);

   // Size the list.
   ctlInfo._move_window(ctlInfo.p_x, ctlInfo.p_y, newListW, newListH);
}

void ctlOK.on_create(_str dslist[])
{
   // Reset to fixed font.
   _str font=(_dbcs()?def_qt_jsellist_font:def_qt_sellist_font);
   ctlInfo._font_string2props(font);

   // Check and create USER.VSLICK.MISC(LISTDSI) REXX exec.
   int status;
   status = maybeCreateLISTDSI();
   if (status) {
      _message_box(nls("Unable to create LISTDSI REXX exec.\nReason is: ",get_message(status)));
      return;
   }

   // Build temporary flag and output file.
   _str userName;
   _userName(userName);
   _str outputDoneFlagFile = "/tmp/vsdsinfo." :+ userName;
   _str outputDS = userName :+ VSTMPOUTPUTDATASETSUFFIX;
   delete_file(outputDoneFlagFile);

   // Build JCL to exec USER.VSLICK.MISC(LISTDSI).
   int i;
   mou_hour_glass(1);
   _str jclText = "";
   _str jobStatement[];
   boolean cardDefined = dsuGetJobStatement(jobStatement);
   if (!cardDefined) {
      jclText = jclText :+ "//":+substr(userName:+"1",1,8):+" JOB  1,":+userName:+",MSGCLASS=X\n";
   } else {
      for (i=0; i<jobStatement._length(); i++) {
         jclText = jclText :+ jobStatement[i] :+ "\n";
      }
   }
   jclText = jclText :+ "//FORM1    OUTPUT DEFAULT=YES,OUTDISP=(PURGE,PURGE),JESDS=ALL\n";
   // First step deletes the old output data set, if needed.
   jclText = jclText :+ "//STEP10   EXEC PGM=IEFBR14\n";
   jclText = jclText :+ "//OUTDD    DD DSNAME=":+outputDS:+",\n";
   jclText = jclText :+ "//         DISP=(MOD,DELETE,DELETE),\n";
   jclText = jclText :+ "//         SPACE=(TRK,(1,1)),\n";
   jclText = jclText :+ "//         DCB=(RECFM=FB,LRECL=150,BLKSIZE=1500,DSORG=PS)\n";
   // Exec LISTDSI to get data set info.
   jclText = jclText :+ "//STEP20   EXEC PGM=IKJEFT01\n";
   jclText = jclText :+ "//SYSTSPRT DD DSNAME=":+outputDS:+",\n";
   jclText = jclText :+ "//         DISP=(NEW,CATLG),\n";
   jclText = jclText :+ "//         SPACE=(TRK,(1,1)),\n";
   jclText = jclText :+ "//         DCB=(RECFM=FB,LRECL=150,BLKSIZE=1500,DSORG=PS)\n";
   jclText = jclText :+ "//SYSPRINT DD SYSOUT=*\n";
   jclText = jclText :+ "//SYSUADS  DD DSN=SYS1.UADS,DISP=SHR\n";
   jclText = jclText :+ "//SYSLBC   DD DSN=SYS1.BRODCAST,DISP=SHR\n";
   jclText = jclText :+ "//SYSTSIN  DD *\n";
   for (i=0; i<dslist._length(); i++) {
      _str sourceds = upcase(dslist[i]);
      if (pos(DATASET_ROOT,sourceds) == 1) {
         sourceds = substr(sourceds,length(DATASET_ROOT)+1);
         int p = pos(FILESEP,sourceds);
         if (p) sourceds = substr(sourceds,1,p-1);
      }
      jclText = jclText :+ "EXEC '"userName:+VSMISCDATASETSUFFIX"(LISTDSI)' '"sourceds"'\n";
   }
   jclText = jclText :+ "/*\n";
   // Signal the completion.
   jclText = jclText :+ "//STEP30   EXEC PGM=IEFBR14\n";
   jclText = jclText :+ "//OUTDD    DD PATH='":+outputDoneFlagFile:+"',\n";
   jclText = jclText :+ "//         PATHDISP=(KEEP,KEEP),\n";
   jclText = jclText :+ "//         PATHOPTS=(OWRONLY,OCREAT),\n";
   jclText = jclText :+ "//         PATHMODE=(SIRWXU)\n";
   _os390SubmitJCL(jclText);

   // Wait the JCL to complete.
   // Apply a 30 seconds time-out waiting for the completion flag,
   // plus 2 seconds per data set.
   int totalWait = 0;
   int maxWait = 30 + dslist._length() * 2;
   while (!file_exists(outputDoneFlagFile)) {
      delay(10); // sleep 1 second
      totalWait++;
      if (totalWait > maxWait) {
         mou_hour_glass(0);
         _message_box(nls("Timed-out waiting for data set information.\nPlease check JES status queue for errors."));
         return;
      }
   }
   delete_file(outputDoneFlagFile);

   // Parse LISTDSI output.
   int lineCount = 0;
   _str outputText[];
   outputText._makeempty();
   int temp_view, orig_view;
   status = _open_temp_view(DATASET_ROOT:+outputDS, temp_view, orig_view);
   if (status) return;
   top(); up();
   _str line, line2, expectInfoFor, dsInfo;
   expectInfoFor = "";
   boolean expectInfo = false;
   while (!down()) {
      get_line(line);
      if (expectInfo) {
         dsInfo = "";
         if (pos("READY",line) != 1) {
            line2 = strip(line,'B',' ');
            down();
            get_line(line);
            line2 = line2 :+ strip(line,'B',' ');
            dsInfo = parseLISTDSIInfo(line2);
         } else {
            dsInfo = substr(expectInfoFor, 1, 44) :+ " *** Information not available ***";
         }
         outputText[lineCount] = dsInfo;
         lineCount++;
         expectInfo = false;
         continue;
      }
      _str command="";
      _str exec="";
      _str dsname="";
      parse line with command exec dsname;
      if (command == "READY") continue;
      if (command == "END") break;
      if (command == "EXEC") {
         expectInfo = true;
         expectInfoFor = strip(dsname, 'B', " ");
         expectInfoFor = strip(expectInfoFor, 'B', "'");
      }
   }
   activate_window(orig_view);
   _delete_temp_view(temp_view, true);
   mou_hour_glass(0);

   // Fill the data set info.
   _str header = "DATA SET NAME                                DSORG RECFM LRECL BLKSZ PRIMA SECND ALUNIT EXTND ALLOC DIRBLK USED   USEDIR NUMMEM MGMTCLS STORCLS VOLSER DEV  CREATED    REFERENCED EXPIRE    ";
   _str sep    = "-------------------------------------------- ----- ----- ----- ----- ----- ----- ------ ----- ----- ------ ------ ------ ------ ------- ------- ------ ---- ---------- ---------- ----------";
   ctlInfo._lbtop();
   ctlInfo._lbadd_item(header);
   ctlInfo._lbadd_item(sep);
   for (i=0; i<outputText._length(); i++) {
      ctlInfo._lbadd_item(outputText[i]);
   }
   clear_message();
   ctlInfo._lbtop();
   ctlInfo._lbselect_line();
}

void ctlInfo.on_change(int reason)
{
   ctlInfo._lbtop();
   ctlInfo._lbselect_line();
}

void ctlOK.lbutton_up()
{
   p_active_form._delete_window(1);
}


//---------------------------------------------------------------
defeventtab _dscatalog_form;

int ctlDSName.on_change()
{
   TextOnChangeInfo tinfo = p_user;
   if (tinfo.onChange) return(0);
   _str text = ctlDSName.p_text;
   if (text :== "") return(0);
   text = upcase(text);
   int status = checkDSName(text);
   if (status) {
      if (status != 3) {
         _beep();
         text = tinfo.previousText;
         ctlDSName._set_sel(length(text)+1);
      } else {
         tinfo.previousText = text;
      }
   } else {
      tinfo.previousText = text;
   }
   tinfo.onChange = 1;
   p_user = tinfo;
   p_text = text;
   tinfo.onChange = 0;
   p_user = tinfo;
   return(0);
}

ctlOK.on_create()
{
   // Internals.
   TextOnChangeInfo tinfo;
   tinfo.onChange = 0;
   tinfo.previousText = "";
   ctlDSName.p_user = tinfo;
   ctlVolume.p_user = tinfo;

   // Init data set caption.
   ctlDSName.p_text = "";

   // Dialog retrieval.
   ctlVolume._retrieve_value();
}

int ctlOK.lbutton_up()
{
   // Check data set name.
   _str dsname = ctlDSName.p_text;
   if (dsname == "") {
      _message_box("Missing data set name.");
      ctlDSName._set_focus();
      return(1);
   }

   // Check volume.
   _str volume = ctlVolume.p_text;
   if (volume == "") {
      _message_box("Missing volume name.");
      ctlVolume._set_focus();
      return(1);
   }

   // Dialog retrieval.
   _append_retrieve(ctlVolume, ctlVolume.p_text);

   _param1 = dsname;
   _param2 = volume;
   p_active_form._delete_window(1);
   return(0);
}

int ctlVolume.on_change()
{
   TextOnChangeInfo tinfo = p_user;
   if (tinfo.onChange) return(0);
   _str text = p_text;
   if (text :!= "") {
      text = upcase(text);
      int status = checkVolSerAndUnit(text);
      if (status) {
         _beep();
         text = tinfo.previousText;
         _set_sel(length(text)+1);
      }
   }
   tinfo.onChange = 1;
   p_user = tinfo;
   p_text = text;
   tinfo.previousText = text;
   tinfo.onChange = 0;
   p_user = tinfo;
   return(0);
}

/**
 * Submits the contents of the current buffer or the specified file to be 
 * processed as a batch job.  This command is available only on the 
 * System/390 platform.
 * 
 * @see shell
 * @see execute
 * @see dos
 * 
 * @categories Miscellaneous_Functions
 * 
 */
_command sub,submit() name_info(FILE_ARG'*,'VSARG2_REQUIRES_MDI)
{
   // Submits the contents of the current buffer or the specified file to be 
   // processed as a batch job.  This command is available only on the 
   // System/390 platform.
   // Build temporary flag and output file and temp JCL data set.
   _str userName;
   _userName(userName);

   //_str outputDoneFlagFile = "/tmp/vsbufsubmit." :+ userName;
   //delete_file(outputDoneFlagFile);
   _str outputDS = userName :+ VSTMPOUTPUTDATASETSUFFIX;
   _str jclDS = userName :+ VSTMPJCLDATASETSUFFIX;

   // If temp JCL data set does not exist, create it now.
   boolean isFixed, isPDS, isBlocked, isUndef;
   int recLen, blkSize;
   typeless status = dsuGetDSInfo(DATASET_ROOT:+jclDS, isFixed, isPDS,
                         isBlocked, isUndef, recLen, blkSize);
   if (status && status != FILE_NOT_FOUND_RC) {
      _message_box(nls("Can't get information on data set %s.\nReason: %s",jclDS,get_message(status)));
      return(status);
   }
   if (status) {
      status = _os390NewDS(DATASET_ROOT:+jclDS
                           ,"" // volser
                           ,"" // unit
                           ,SPACEUNIT_BLOCKS // allocate in blocks
                           ,5 // primary quantity
                           ,5 // secondary quantity
                           ,0 // directory blocks
                           ,RECFM_FB // record format
                           ,80 // record length
                           ,8000 // block size
                           ,DSORG_PS // PS
                           );
      if (status) {
         _message_box(nls("Can't allocate temporary JCL data set '%s'.\nReason: %s",jclDS,get_message(status)));
         return(status);
      }
   }

   // Format the JCL into a buffer.
   _str submitName;
   _str jclText = "";
   _str line;
   if (arg()) {
      // Read the JCL from a file or data set.
      _str filename = arg(1);
      submitName = filename;
      int temp_view, orig_view;
      status = _open_temp_view(filename, temp_view, orig_view);
      if (status) {
         _message_box(nls("Can't read source JCL '%s'.\nReason: %s",filename,get_message(status)));
         return(status);
      }
      status = save_file(DATASET_ROOT:+jclDS, "+o");
      activate_window(orig_view);
      _delete_temp_view(temp_view, true);
      if (status) {
         _message_box(nls("Can't copy '%s' to temporary JCL '%s'.\nReason: %s",filename,jclDS,get_message(status)));
         return(status);
      }
   } else {
      // Submit the active buffer, if there is one.
      if (_mdi.p_child._no_child_windows()) {
         _message_box(nls("Missing JCL file."));
         return(UNSUPPORTED_DATASET_OPERATION_RC);
      }

      // Make sure user know about modified buffer.
      submitName = "buffer '":+p_buf_name:+"'";
      if (p_modify) {
         int result;
         result = _message_box(nls("Current buffer has not been saved.\nContinue with submit?"), "", MB_YESNO);
         if (result != IDYES) return(0);
      }

      // Build the JCL buffer.
      status = save_file(DATASET_ROOT:+jclDS, "+o");
      if (status) {
         _message_box(nls("Can't write buffer to temporary JCL '%s'.\nReason: %s",jclDS,get_message(status)));
         return(status);
      }
   }

   // Submit the temp JCL data set. Delete the temporary
   // JCL data set after submitted.
   status = dsuSubmitDS(DATASET_ROOT:+jclDS, true, submitName);
   if (status) {
      _message_box(nls("Can't submit %s.\nReason: %s",submitName,get_message(status)));
      return(status);
   }
   return(0);
}

//-----------------------------------------------------------------
static void browseUserLog()
{
   _str logFile;
   _userLogFile(logFile);

   // If log file is already being viewed, close it.
   int temp_view_id;
   int orig_view_id = _create_temp_view(temp_view_id);
   int temp_buf_id = p_buf_id;
   _next_buffer("HR");
   while (p_buf_id != temp_buf_id) {
      if (p_buf_name == logFile) {
         quit_file();
         break;
      }
      _next_buffer( "HR" );
   }
   p_buf_id = temp_buf_id;
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);

   // Browse the log file.
   int status = edit(maybe_quote_filename(logFile)" -#read-only-mode");
   if (status == NEW_FILE_RC) {
      quit();
      _message_box(nls("Your log is empty."));
      clear_message();
   } else if (!status) {
      bottom();
      p_col = 1;
      center_line();
   } else {
      if (status == INSUFFICIENT_SPILL_DISK_SPACE_RC || status == INSUFFICIENT_LOG_DISK_SPACE_RC) {
         _message_box(nls("Can't open log '%s'.\n\n%s\n\nPlease close as many files as you can and exit the editor.",logFile,get_message(status)));
      } else {
         _message_box(nls("Can't open log '%s'.\n%s",logFile,get_message(status)));
      }
   }
}
_command userlog() name_info(FILE_ARG'*,'VSARG2_REQUIRES_MDI)
{
   browseUserLog();
}
boolean suppressLogNotice()
{
   return(gSuppressLogNotice);
}

//-----------------------------------------------------------------
defeventtab _userLogNotice_form;
ctlOK.on_create(_str text)
{
   ctlText.p_caption = text;
}
ctlOK.lbutton_up()
{
   if (ctlDontPrompt.p_value) {
      gSuppressLogNotice = true;
   }
   p_active_form._delete_window(1);
}
ctlBrowse.lbutton_up()
{
   if (ctlDontPrompt.p_value) {
      gSuppressLogNotice = true;
   }
   p_active_form._delete_window(1);
   browseUserLog();
}
