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
#include "tagsdb.sh"
#include "xml.sh"
#include "eclipse.sh"
#import "se/lang/api/LanguageSettings.e"
#import "alllanguages.e"
#import "autosave.e"
#import "backtag.e"
#import "context.e"
#import "diff.e"
#import "dlgman.e"
#import "fileman.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "help.e"
#import "javacompilergui.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "makefile.e"
#import "mprompt.e"
#import "notifications.e"
#import "optionsxml.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "recmacro.e"
#import "refactor.e"
#import "refactorgui.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "taggui.e"
#import "tagrefs.e"
#import "tags.e"
#import "toast.e"
#import "treeview.e"
#import "util.e"
#import "wkspace.e"
#endregion

using se.lang.api.LanguageSettings;


static const WORKSPACE_FOLDER_NAME=       "Workspace and Project Tag Files";
static const AUTO_UPDATED_FOLDER_NAME=    "Workspace Auto-Updated Tag Files";
static const COMPILER_CONFIG_FOLDER_NAME= "Compiler Configuration Tag Files";
static const LANGUAGE_CONFIG_FOLDER_NAME= "Tag Files";
static const WORKSPACE_LANG_ID=           "<WORKSPACE>";
static const SELECT_LANGUAGE_MODE=        "<Select Language>";

//12:20pm 7/3/1997
//Dan added for background/on save tagging
//10:25 10/17/2007
//Sandra moved to tagform.e and changed to enum for use with new options dialog
_metadata enum AutotagFlags {
   AUTOTAG_ON_SAVE            = 0x01,        // tag file on save
   AUTOTAG_BUFFERS            = 0x02,        // background tag buffers
// AUTOTAG_PROJECT_ONLY       = 0x04         // background tag project buffers only (OBSOLETE)
   AUTOTAG_FILES              = 0x08,        // background tag all files
   AUTOTAG_SYMBOLS            = 0x10,        // refresh tag window (symbols tab)
   AUTOTAG_FILES_PROJECT_ONLY = 0x20,        // background tag workspace files only
   AUTOTAG_CURRENT_CONTEXT    = 0x40,        // background update current context
   AUTOTAG_UPDATE_CALLSREFS   = 0x80,        // update call tree and references on change
                                             // event for symbol browser and proctree
   AUTOTAG_BUFFERS_NO_THREADS    = 0x100,    // DO NOT use thread for tagging buffer or save 
   AUTOTAG_FILES_NO_THREADS      = 0x200,    // DO NOT use threads for tagging files (OBSOLETE, ALWAYS ON)
   AUTOTAG_WORKSPACE_NO_THREADS  = 0x400,    // DO NOT use threads for tagging workspace files
   AUTOTAG_LANGUAGE_NO_THREADS   = 0x800,    // DO NOT use threads for language support tag files
   AUTOTAG_SILENT_THREADS        = 0x1000,   // Report background tagging activity on status bar
   AUTOTAG_WORKSPACE_NO_OPEN     = 0x2000,   // DO NOT update workspace tag file when workspace is opened
   AUTOTAG_WORKSPACE_NO_ACTIVATE = 0x4000,   // DO NOT update workspace tag file on app activate
   AUTOTAG_DISABLE_ALL_THREADS   = 0x8000,   // Disable all threaded tagging options
   AUTOTAG_DISABLE_ALL_BG        = 0x10000,  // Disable all background tagging options
   AUTOTAG_ON_SWITCHBUF          = 0x20000,  // background tag modified buffers on switchbuf
};

defeventtab _tag_form;
void ctlautotag_btn.lbutton_up()
{
   status   := 0;
   orig_wid := p_window_id;
   langId := TAGFORM_LANGUAGE_ID();
   if (langId == null || langId == "") {
      status = autotag(langId);
   } else {
      callbackIndex := find_index("_"langId"_getAutoTagChoices", PROC_TYPE);
      if (callbackIndex) {
         status = autotag(langId);
      } else {
         // check if background tagging is enabled for the language tag files
         useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
         status = _mdi.show('-modal _rebuild_tag_file_form', true, false, false, false, true, useThread, true, "Build ":+_LangId2Modename(langId)" Library Tag Files");
         if (status == '') return;
         tagOccurrences := (_param3 != 0);
         useThread = useThread && (_param5 != 0);
         MaybeBuildTagFile(langId, tagOccurrences, useThread, forceRebuild:true);
         status = 0;
      }
   }
   if (status!=COMMAND_CANCELLED_RC) {
      // Delete all items in the tree
      //tree1._TreeDelete(TREE_ROOT_INDEX,'c');
      //ctldone.call_event(langId,ctldone,ON_CREATE);
      if (_iswindow_valid(orig_wid)) {
         orig_wid.p_active_form.UpdateTagFilesForm(langId);
      }
   }
}

static _str TAG_FOLDER_INDEXES(...) {
   if (arg()) ctlfiles_btn.p_user=arg(1);
   return ctlfiles_btn.p_user;
}

//This is the indexes of the two folders in the format:
//ProjectFolderIndex' 'GlobalFolderIndex
static _str TAGFORM_SKIP_ON_CHANGE(...) {
   if (arg()) tree1.p_user=arg(1);
   return tree1.p_user;
}

static _str TAGFORM_LANGUAGE_ID(...) {
   if (arg()) ctldone.p_user=arg(1);
   return ctldone.p_user;
}

static _str TAGFORM_IS_MODIFIED(...) {
   if (arg()) ctlnew_tag_file_btn.p_user=arg(1);
   return ctlnew_tag_file_btn.p_user;
}

//SKIP_ON_CHANGE is used if we move a tree item up or down and really don't need
//the on change event.
static bool TreeIsEmpty(int a) {
   return (a._TreeGetFirstChildIndex(TREE_ROOT_INDEX)<0);
}
static const TAGFORM_FOLDER_DEPTH= 1;
static const TAGFORM_FILE_DEPTH=   2;

static const TAGFORM_PROGRESS_THRESHOLD= 2000;

// bitmap used for tag files and references files
int _pic_file_refs = 0;
int _pic_file_tags = 0;
int _pic_file_tags_error = 0;

defload()
{
   _pic_file_refs=_update_picture(-1,'_f_references.svg');
   if (_pic_file_refs < 0) {
      _pic_file_refs = _pic_file;
   }
   _pic_file_tags=_update_picture(-1,'_f_symbols.svg');
   if (_pic_file_tags < 0) {
      _pic_file_tags = _pic_file;
   }
   _pic_file_tags_error=_update_picture(-1,'_f_symbols_error.svg');
   if (_pic_file_tags_error < 0) {
      _pic_file_tags_error = _pic_file;
   }
}

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Load the filenames from the given tag file into the list control.
//    -- tag_filename  -- name of file to create
// The current object must be a list box control, tree control,
// editor control, or combo box control.
// Returns the number of files inserted >=0, or error code <0.
//
static int LoadFileNameList(_str tag_filename, bool quiet=false)
{
   // if the tag file hasn't changed since the last time the file list was loaded
   // then do not reload the file list.
   lastTagFileName := null;
   lastTagFileDate := null;
   if (p_object==OI_LIST_BOX && p_name == "list1") {
      lastTagFileName = ctl_files_label.p_user;
      lastTagFileDate = ctl_files_gauge.p_user;
   } else {
      quiet = true;
   }

   if (lastTagFileName != null && lastTagFileDate != null &&
       _file_eq(tag_filename, lastTagFileName) &&
       _file_date(tag_filename,'B') == lastTagFileDate) {
      // Check to make sure the file list isn't empty.
      numFiles := 0;
      switch (p_object) {
      case OI_COMBO_BOX:
         numFiles = p_Noflines;
         break;
      case OI_TREE_VIEW:
         numFiles = _TreeGetNumChildren(TREE_ROOT_INDEX);
         break;
      case OI_EDITOR:
      case OI_FORM:
      case OI_LIST_BOX:
         numFiles = p_Noflines;
         break;
      }
      if (numFiles > 0) {
         return numFiles;
      }
   } else {
      // otherwise, we need to rebuild the list of files in this tag database
      // We start by clearing out the existing list.
      switch (p_object) {
      case OI_COMBO_BOX:
         _lbclear();
         break;
      case OI_TREE_VIEW:
         _TreeDelete(TREE_ROOT_INDEX, 'C');
         break;
      case OI_EDITOR:
      case OI_FORM:
      case OI_LIST_BOX:
         _lbclear();
         break;
      }
   }

   // save the last tag file name and date
   if (p_object==OI_LIST_BOX && p_name == "list1") {
      ctl_files_label.p_user = tag_filename;
      ctl_files_gauge.p_user = _file_date(tag_filename,'B');
   }

   // open the database for business
   int status = tag_read_db(tag_filename);
   if (status < 0) {
      return status;
   }

   // set up the file labels
   num_files:=0;
   increment:=50;
   tag_get_detail(VS_TAGDETAIL_num_files, num_files);
   if (!quiet) {
      ctl_files_label.p_caption = get_message(VSRC_CFG_TAG_FILES_LOADING);
      if (num_files > TAGFORM_PROGRESS_THRESHOLD) {
         ctl_files_gauge.p_visible=true;
         ctl_files_gauge.p_value=0;
         ctl_files_gauge.p_max = num_files;
         ctl_files_gauge.p_x = ctl_files_label.p_x_extent + 300;
         ctl_files_gauge.p_x_extent = list1.p_x_extent - 60;
         gauge_width := _lx2dx(SM_TWIP, ctl_files_gauge.p_width);
         if (gauge_width <= 0) gauge_width = 1;
         increment = (num_files intdiv gauge_width);
         if (increment < 50) increment=50;
      }
      p_active_form.refresh();
   }

   // get the files from the database
   filename := "";
   status=tag_find_file(filename);
   count := 0;
   while (!status) {
      switch (p_object) {
      case OI_COMBO_BOX:
         _lbadd_item(filename);
         break;
      case OI_TREE_VIEW:
         _TreeAddItem(TREE_ROOT_INDEX, filename, TREE_ADD_AS_CHILD,
                      _pic_file, _pic_file, TREE_NODE_LEAF);
         break;
      case OI_EDITOR:
      case OI_FORM:
         insert_line(filename);
         break;
      case OI_LIST_BOX:
         _lbadd_item_index(count,filename,0);
         //_lbadd_item(filename);
         break;
      }
      ++count;
      if (!quiet && ctl_files_gauge.p_visible && (count % increment) == 0) {
         ctl_files_gauge.p_value= count;
         ctl_files_gauge.refresh('W');
      }
      status=tag_next_file(filename);
   }
   tag_reset_find_file();

   // maybe print final progress message and then sort the list
   switch (p_object) {
   case OI_COMBO_BOX:
      _lbsort('-f');
      _lbtop();
      break;
   case OI_TREE_VIEW:
      _TreeSortCaption(TREE_ROOT_INDEX,'F');
      _TreeTop();
      break;
   case OI_EDITOR:
   case OI_FORM:
      //don't sort in this case, to save time for large lists
      //sort_buffer('-f');
      top();up();
      break;
   case OI_LIST_BOX:
      _lbsort('-f');
      _lbtop();
      break;
   }

   // clear the messages and return the number of files inserted
   if (!quiet) {
      sizeK := (_file_size(tag_filename) intdiv 1024);
      sizeM := (sizeK / 1024);
      round(sizeM, 1);
      tagFileSize := (sizeK > 1000)? sizeM:+"MB" : sizeK:+"KB";
      ctl_files_label.p_caption = get_message(VSRC_CFG_TAG_FILES_COUNT, p_Noflines, tagFileSize);
      ctl_files_gauge.p_visible=false;
   }
   return num_files;
}

// used to cycle through which alert to activate for background tagging jobs
_str _GetBuildingTagFileAlertGroupId(_str tag_filename, bool generateId=true, bool removeId=false)
{
   if (!_haveContextTagging()) {
      return '';//VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // check if this tag file already is active
   static _str activatedAlerts:[];
   if (activatedAlerts._indexin(tag_filename)) {
      id := activatedAlerts:[tag_filename];
      if (removeId) {
         activatedAlerts._deleteel(tag_filename);
      }
      return id;
   }

   // do we need to generate an alert ID to use?
   if (!generateId) {
      return ''; //STRING_NOT_FOUND_RC;
   }

   // If this is the current workspace return a workspace build alert ID
   if (isWorkspaceTagFileName(tag_filename)) {
      static int workspaceTaggingAlertCount;
      alertId := ALERT_TAGGING_WORKSPACE :+ (++workspaceTaggingAlertCount % ALERT_TAGGING_MAX_WORKSPACES);
      activatedAlerts:[tag_filename] = alertId;
      return alertId;
   }

   // If this is a project in the current workspace, return a project build alert ID
   if (isProjectTagFileName(tag_filename)) {
      static int projectTaggingAlertCount;
      alertId := ALERT_TAGGING_PROJECT :+ (++projectTaggingAlertCount % ALERT_TAGGING_MAX_PROJECTS);
      activatedAlerts:[tag_filename] = alertId;
      return alertId;
   }

   // Otherwise, generate an ID for this tag file build
   static int backgroundTaggingAlertCount;
   alertId := ALERT_TAGGING_BUILD :+ (++backgroundTaggingAlertCount % ALERT_TAGGING_MAX_BUILDS);
   activatedAlerts:[tag_filename] = alertId;
   return alertId;
}

_str _GetBuildingTagFileMessage(bool useThread=false, _str tag_filename="")
{
   btf := "Building Tag File...";
   if (tag_filename != "") {
      btf :+= tag_filename;
   }
   if (useThread) {
      btf :+= " (to be completed in background)";
   }
   return btf;
}

//////////////////////////////////////////////////////////////////////////////
// Retag files listed in the current view.  The view is normally created
// using _create_temp_view.
//    tag_filename    -- name of tag file to retag.
//    extension       --
//    rebuild_all     -- rebuild all tags, not just files that are out of date
// Reports (via message box) if there were problems writing the tag file,
// or if there were any files not tagged successfully.
// Returns 0 on success or <0 on error.
//
static int RetagFilesInView(_str tag_filename, //_str extension='',
                            bool rebuild_all=false,
                            //bool retag_refs=false,
                            bool doRemove=false,
                            bool RemoveWithoutPrompting=false,
                            bool useThread=false,
                            bool quiet=false,
                            bool checkAllDates=false,
                            bool allowCancel=false,
                            bool skipFilesNotInTagFile=false,
                            bool KeepWithoutPrompting=false
                            )
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (useThread && (RemoveWithoutPrompting || KeepWithoutPrompting)) {
      retag_occurrences := true;
      int status = tag_read_db(tag_filename);
      if (status >= 0) {
         if ((tag_get_db_flags() & VS_DBFLAG_occurrences) == 0) {
            retag_occurrences = false; 
         }
      }
      
      alertId := _GetBuildingTagFileAlertGroupId(tag_filename);
      _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, "Updating: "tag_filename, '', 1);
      call_list("_LoadBackgroundTaggingSettings");
      rebuildFlags := 0;
      if (rebuild_all)           rebuildFlags |= VS_TAG_REBUILD_FROM_SCRATCH;
      if (checkAllDates)         rebuildFlags |= VS_TAG_REBUILD_CHECK_DATES;
      if (!rebuild_all)          rebuildFlags |= VS_TAG_REBUILD_CHECK_DATES;
      if (retag_occurrences)     rebuildFlags |= VS_TAG_REBUILD_DO_REFS;
      if (doRemove)              rebuildFlags |= VS_TAG_REBUILD_REMOVE_MISSING_FILES;
      if (skipFilesNotInTagFile) rebuildFlags |= VS_TAG_REBUILD_SKIP_MISSING_FILES;
      status = tag_build_tag_file_from_view(tag_filename, rebuildFlags, p_window_id);
      if (def_tagging_logging) {
         loggingMessage := nls("Starting background tag file update for '%s1'", tag_filename);
         dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      }
      return status;
   }


   IgnoreMissingFile := KeepWithoutPrompting;
   promptAboutNotTaggedFiles := false;
   _str filename, tagging_message;
   int temp_view_id, filelist_view_id;
   num_files := p_Noflines;
   not_tagged_count := 0;
   not_tagged_list := "";
   _str not_tagged_files[];
   not_tagged_more := false;
   top(); up();
   int orig_view_id;
   get_window_id(orig_view_id);

   orig_use_timers := _use_timers;
   orig_def_actapp := def_actapp;
   def_actapp=0;
   _use_timers=0;
   activate_window(orig_view_id);
   get_window_id(filelist_view_id);
   buildform_wid := 0;
   max_label2_width := 0;
   msg := "";
   answer := "";
   status := 0;
   wasCancelled := false;

   /*
       We might need to uncomment out the _AppHasFocus() if below
       if the check for "if (!def_actapp)" in _on_activate_app2()
       is a problem.

       Displaying dialog when VSE does not have focus causes an
       app activate (_on_activate_app2 gets called) which when the guibuilder is
       active closes or reopens the tag file as read only.  Then the code that follows
       calls _RetagCurrentFile which failes because the tag file is open read only.

       Reproduce original problem by adding a new gui item to a project.
   */
   //if (_AppHasFocus()) {
      if (allowCancel) {
         buildform_wid=show_cancel_form(_GetBuildingTagFileMessage(useThread, tag_filename),'',true,true);
      } else {
         buildform_wid=show_cancel_form(_GetBuildingTagFileMessage(useThread, tag_filename),'',false,true);
      }
      max_label2_width=cancel_form_max_label2_width(buildform_wid);
   //}

   while (!down()) {
      if (buildform_wid) {
         if (cancel_form_cancelled()) {
            wasCancelled = true;
            break;
         }
      }
      // update progress gauge
      cancelPressed := tagProgressCallback(p_line * 100 intdiv p_Noflines, true);
      if (cancelPressed) {
         wasCancelled = true;
         break;
      }

      get_line(filename);
      filename=strip(filename/*,'L'*/);
      if (filename=='') continue;
      current_line := p_line;
      if (buildform_wid) {
         if (cancel_form_progress(buildform_wid,p_line-1,num_files)) {
            sfilename := buildform_wid._ShrinkFilename(filename,max_label2_width);
            cancel_form_set_labels(buildform_wid,'Tagging 'p_line'/'num_files':',sfilename);
         }
      }

      // open view of file, try for a buffer first
      temp_view_id=0;
      fdate := "";
      typeless buf_id;
      parse buf_match(filename,1,'vhx') with buf_id .;
      if (buf_id!="") {
         fdate=_BufDate(buf_id);
      } else {
         if (!rebuild_all && (doRemove || checkAllDates)) {
            fdate=_file_date(filename,'b');
         } else {
            fdate=1;
         }
      }
   
      lang := _Filename2LangId(filename);
      doRemove2 := false;
      // file opened cleanly, so retag file and quit view
      if (fdate!="" && fdate!=0) {
         doRetag := false;
         // check date on disk, if same as last tagged, skip file
         if (!rebuild_all) {
            _str tagged_date;
            int date_status=tag_get_date(filename,tagged_date);
            _str tagged_lang;
            int lang_status=tag_get_language(filename, tagged_lang);
            if (!(doRemove || checkAllDates) && !date_status) {
               fdate=tagged_date;
            }
            if (date_status && skipFilesNotInTagFile) {
               doRetag=false;
            } else if (date_status || fdate!=tagged_date || lang!=tagged_lang || IncludeFileChanged(filename)) {
               doRetag=true;
               //say('doretag');
            } else if (!file_exists(filename)) {
               // the file is not on disk but open in a buffer
               doRemove2=true;
            } else {
               //say("avoiding retag of: "filename);
            }
         } else {
            //say("forced tagging of: "filename);
            doRetag=true;
         }
         if (doRetag) {
            if (!useThread || 
                !file_exists(filename) || 
                RetagCurrentFileAsync(filename, lang) < 0) {
               bool inmem;
               status=_open_temp_view(filename,temp_view_id,filelist_view_id,'',inmem,false,true);
               if (status) {
                  doRemove2=true;
               } else {
                  RetagCurrentFile(useThread,!inmem,tag_filename);
                  // IF this file is a new file that has not been saved OR
                  //    this is a buffer that has been renamed 
                  //    AND the file does not exist
                  if ((p_file_date=='' || p_file_date==0 ||(p_buf_flags&VSBUFFLAG_PROMPT_REPLACE)) && !file_exists(filename)) {
                     doRemove2=true;
                  }
                  // close the temporary view
                  _delete_temp_view(temp_view_id);
                  p_window_id=filelist_view_id;
                  // the file is not on disk but open in a buffer
               }
            }
         }
      } else {
         doRemove2=true;
      }
      if (doRemove2) {
         if (_istagging_supported(lang)) {
            not_tagged_count++;
            not_tagged_files[not_tagged_files._length()] = filename;
            if (not_tagged_list == '') {
               not_tagged_list = filename;
            } else if (length(not_tagged_list) < 1000) {
               strappend(not_tagged_list, ', 'filename);
            } else {
               not_tagged_more = true;
            }
            p_window_id=orig_view_id;
            // if the source file was not found, remove all tags associated with it
            if (doRemove) {
               removeFile := false;
               if (RemoveWithoutPrompting) {
                  removeFile=true;
                  promptAboutNotTaggedFiles=true;
               } else if (IgnoreMissingFile) {
                  removeFile=false;
                  promptAboutNotTaggedFiles=true;
               } else {
                  if (!quiet) {
                     msg = nls("%s\nno longer exists.\n\nRemove file from tag file?",filename);
                     answer= show("-modal _yesToAll_form", msg, "Remove File From Tag File");
                  }
                  if (answer == "CANCEL") {
                     break;
                  } else if (answer == "YES") {
                     removeFile=true;
                  } else if (answer == "YESTOALL") {
                     removeFile=true;
                     RemoveWithoutPrompting= true;
                  } else if (answer == "NOTOALL") {
                     removeFile=false;
                     IgnoreMissingFile=true;
                  }
               }
               if (removeFile) {
                  tag_open_db(tag_filename);
                  tag_remove_from_file(filename);
               }
               // back to the file list, dialog may have changed our focus
               activate_window(filelist_view_id);
            }
         } else {
            /*
            // prompt them about files that could not be tagged
            // because they did not have tagging support
            promptAboutNotTaggedFiles=true;
            not_tagged_count++;
            if (not_tagged_list == '') {
               not_tagged_list = filename;
            } else if (length(not_tagged_list) < 1000) {
               strappend(not_tagged_list, ', 'filename);
            } else {
               not_tagged_more = true;
            }
            */
         }
      }
   }
   if (buildform_wid) {
      close_cancel_form(buildform_wid);
   }
   _use_timers=orig_use_timers;
   def_actapp=orig_def_actapp;

   // report if any files not found or tagged
   if (!quiet && not_tagged_count > 0 && promptAboutNotTaggedFiles) {
      if (not_tagged_more) {
         strappend(not_tagged_list, ', ...');
      }
      // no message box, just warn them about files that aren't tagged
      plural  := (not_tagged_count > 1)? "s":"";
      verb    := (not_tagged_count > 1)? "were":"was";
      pronoun := (not_tagged_count > 1)? "they":"it";
      _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_TAGGING_ERROR,
                     nls("%s file":+plural:+" ":+verb:+" not tagged ":+
                         "because ":+pronoun:+" could not be opened or do not exist:\n\n%s",
                         not_tagged_count,not_tagged_list),
                     "Tagging", 1);
      foreach (filename in not_tagged_files) {
         msg = nls("File was not tagged because it could not be opened or do not exist:\n\n%s",filename);
         notifyUserOfWarning(ALERT_TAGGING_ERROR, msg, filename, 0, true);
      }
   }
   activate_window(orig_view_id);

   // that's all folks
   return (wasCancelled? COMMAND_CANCELLED_RC : 0);
}

static void CloseAllViews(int (&ProjectFileViewList):[])
{
   typeless j;
   for (j._makeempty();;) {
      ProjectFileViewList._nextel(j);
      if (j._isempty()) {
         break;
      }
      _delete_temp_view(ProjectFileViewList:[j]);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Opens or creates a tag database, depending on if the given database
// existed before.
//    tag_filename   -- the tag file to open or create
//    force_create   -- force the database to be recreated, not just opened
//    database_type  -- type of database to create
//    database_flags -- bitset of VS_DBFLAG_*, used only when creating
// Returns the status of the operation.  The file is left open for
// read-write after this function is called.  This function also works
// if 'tag_filename' does not exist.
//
int _OpenOrCreateTagFile(_str tag_filename, bool force_create=false,
                         int database_type=VS_DBTYPE_tags, int database_flags=0,
                         bool quiet=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if(tag_filename == '') {
      return -1;
   }
   // try to open the database for read/write
   int status=tag_open_db(tag_filename);
   if (status==FILE_NOT_FOUND_RC || force_create || status==BT_CANNOT_WRITE_OBSOLETE_VERSION_RC) {
      // need to re-create database, preserve database description
      descr := "";
      int  flags = database_flags;
      if (!status) {
         descr = tag_get_db_comment();
         if (!force_create) {
            flags = tag_get_db_flags();
         }
      }
      tag_close_db(tag_filename);
      delete_file(tag_filename);
      // create the new database and set description
      int cstatus=tag_create_db(tag_filename,database_type);
      if (cstatus < 0) {
         if (!quiet) {
            _message_box(nls("Could not create tags database %s.\n%s",tag_filename,get_message(cstatus)));
         }
         return cstatus;
      }
      tag_set_db_comment(descr);
      tag_set_db_flags(flags);
      tag_close_db(tag_filename, true);
      // inform the world about the new database
      if (status==FILE_NOT_FOUND_RC) {
         _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,"","");
      }
      return tag_open_db(tag_filename);
   } else if (status < 0) {
      // trouble
      if (!quiet) {
         _message_box(nls("Could not open tag file %s.\n%s",tag_filename,get_message(status)));
      }
      return(status);
   }
   // success!
   return(0);
}

//////////////////////////////////////////////////////////////////////////////
// Retag all the files in the given file list view for the given tag file
//    tag_filename  -- name of tag file to open or create
//    orig_view_id  -- view to revert back to after finished tagging files
//    list_view_id  -- view containing list of source files to tag
//    rebuild_all   -- rebuild all files or just recently modified files?
//    retag_refs    -- is this a references database?
// Returns 0 on success, <0 on error.
//
int RetagFilesInTagFile2(_str tag_filename,
                         int orig_view_id,
                         int list_view_id,
                         bool force_create,
                         bool rebuild_all,
                         bool retag_occurrences,
                         bool doRemove=false,
                         bool RemoveWithoutPrompting=false,
                         bool useThread=false,
                         bool quiet=false,
                         bool checkAllDates=false,
                         bool doDeleteListView=true,
                         bool allowCancel=false,
                         bool skipFilesNotInTagFile=false,
                         bool KeepWithoutPrompting=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // If rebuilding the entire database, force a tag_create_db to occur
   // otherwise, just open the file for write, create it if it doesn't exist
   //int database_type = (retag_refs)? VS_DBTYPE_references : VS_DBTYPE_tags;
   database_type  := VS_DBTYPE_tags;
   database_flags := (retag_occurrences)? VS_DBFLAG_occurrences:0;
   status := _OpenOrCreateTagFile(tag_filename,force_create,database_type,database_flags,quiet);
   if (status < 0) {
      if (!quiet && status==ACCESS_DENIED_RC) {
         message(nls("Can not rebuild out-of-date tag file: %s.\n%s",tag_filename,get_message(status)));
      }
      if (_iswindow_valid(orig_view_id)) {
         p_window_id = orig_view_id;
      }
      if (doDeleteListView) {
         _delete_temp_view(list_view_id);
      }
      return(status);
   }

   // Retag all the files in the view
   activate_window(list_view_id);
   status = RetagFilesInView(tag_filename, rebuild_all,
                             doRemove, force_create||RemoveWithoutPrompting,
                             useThread, quiet, 
                             checkAllDates, allowCancel,
                             skipFilesNotInTagFile, KeepWithoutPrompting);
   wasCancelled := (status == COMMAND_CANCELLED_RC);

   // blow away the file list temp view
   if (_iswindow_valid(orig_view_id)) {
      p_window_id = orig_view_id;
   }
   if (doDeleteListView) {
      _delete_temp_view(list_view_id);
   }

   // close the database and check that it was clean
   // if building using a thread, there a chance that the tag file does not exist yet.
   if (!useThread || file_exists(tag_filename)) {
      status = tag_close_db(tag_filename, true/*leave it open for read*/);
      if (!quiet && status) {
         _message_box(nls("Error closing tags database %s.\n%s",tag_filename,get_message(status)));
      }
      _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,tag_filename);
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }

   // report if any files not found or tagged
   // we are done
   clear_message();
   return(wasCancelled? COMMAND_CANCELLED_RC : 0);
}

//////////////////////////////////////////////////////////////////////////////
// This function converts a 2.0 format tag file to the new tag database
// format (3.0 and beyond).  It does so by first parsing through the file
// and collecting the filenames and paths in the file, putting those
// into a temporary view, then creating a new tag file, and feeding
// the list of files to RetagFilesInView(), above.
//    -- OldTagFilename  -- the original tag filename (something.slk)
//    -- NewTagFilename  -- the new tag filename (something.vtg)
// Returns <0 on error, 0 on success.
//
int RebuildOldTagFile(_str OldTagFilename, _str NewTagFilename,
                      bool quiet=false, 
                      bool tag_occurrences=false,
                      bool useThread=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // check if the new tag file exists already.
   NewTagFilename=absolute(NewTagFilename);
   int status=tag_read_db(NewTagFilename);
   if (status >= 0) {
      //Just assume that this one is ok....
      _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,"","");
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      return(0);
   }

   // open the old tag file
   int temp_view_id, orig_view_id;
   status=_open_temp_view(OldTagFilename,temp_view_id,orig_view_id,'+l');
   if (status) {
      if (status==NEW_FILE_RC) {
         p_window_id=orig_view_id;
         _delete_temp_view(temp_view_id);
      }
      return(status);
   }

   // keep track of where focus was
   orig_focus_wid := 0;
   if (_no_child_windows()) {
      orig_focus_wid=_cmdline;
   }
   if (!quiet) {
      // warn about converting the file
      _message_box("About to convert old tag file "OldTagFilename".\nThis may take a minute.");
   }
   if (orig_focus_wid==_cmdline) {
      _cmdline.p_visible=false;
   }

   // create the new tag database
   mou_hour_glass(true);
   delete_file(NewTagFilename);
   status=tag_create_db(NewTagFilename);
   if (status < 0) {
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
      if (orig_focus_wid==_cmdline) {
         _cmdline.p_visible=true;
      }
      if (!quiet) {
         _message_box(nls("Could not create tags database %s.\n%s",NewTagFilename,get_message(status)));
      }
      mou_hour_glass(false);
      return(status);
   }

   // Flag that occurrences are to be tagged
   if (tag_occurrences) {
      tag_set_db_flags(VS_DBFLAG_occurrences);
   }

   // create the path table
   _str line;
   _str PathTable[];
   PathTable._makeempty();
   p_line=0;
   while (!down()) {
      get_line(line);
      if (pos('%',line)) break;
      PathTable[p_line]=line;
   }
   up();

   // parse through the file and create the list of filenames
   _str filename;
   int NoExistList:[];
   NoExistList._makeempty();
   CorruptTagFile := false;
   while (!down()) {
      // update progress gauge
      int cancelPressed = tagProgressCallback(p_line * 100 intdiv p_Noflines, true);
      if(cancelPressed) break;

      get_line(line);
      typeless PathIndex;
      parse line with ./*TagName*/ PathIndex'%'filename;
      // IF this is just a corrupt tag file
      if (!isinteger(PathIndex)) {
         CorruptTagFile=true;
         break;
      }
      WholeFilename := PathTable[PathIndex]:+filename;
      date := "";
      status=tag_get_date(WholeFilename,date);
      if (status) {
         //If we do not get a status, we tagged the file already.
         if (!(NoExistList._indexin(WholeFilename))) {
            int source_view_id, junk_view_id;
            inmem := false;
            status=_open_temp_view(WholeFilename,source_view_id,junk_view_id,'',inmem,false,true);
            if (!status) {
               message('Tagging 'WholeFilename);
               RetagCurrentFile(useThread, !inmem, NewTagFilename);
               p_window_id=temp_view_id;
               _delete_temp_view(source_view_id);
            }else{
               // just to add the filename to the list
               tag_set_date(WholeFilename);
               NoExistList:[WholeFilename]=1;
            }
         }
      }
   }

   // close the old tag file and the new tag file
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;
   status=tag_close_db(NewTagFilename,true);
   _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,"","");
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);

   if (CorruptTagFile) {
      if (!quiet) {
         _message_box(nls("Tag file %s is corrupt.  You will have to recreate this tag file",OldTagFilename));
      }
   } else {
      // create a new view for the list of not-tagged files
      orig_view_id=_create_temp_view(temp_view_id);
      p_window_id=temp_view_id;
      typeless i;
      for (i._makeempty();;) {
         NoExistList._nextel(i);
         if (i._isempty()) break;
         insert_line(' 'i);
      }
      ShowDialog := p_Noflines;
      p_window_id=orig_view_id;

      // warn the user about files that were not tagged
      if (ShowDialog) {
         if (!quiet) {
            typeless result=p_active_form.show('-modal _sellist_form',
                             'The following files could not be found',
                             SL_VIEWID, // flags
                             temp_view_id);
         }
      }else{
         _delete_temp_view(temp_view_id);
      }
   }

   // that's all folks.
   clear_message();
   mou_hour_glass(false);
   if (orig_focus_wid==_cmdline) {
      _cmdline.p_visible=true;
   }
   return(status);
}

//////////////////////////////////////////////////////////////////////////////
// Insert the given list of tag files into the tag form tree at 'index'
//
static void AddLanguageTagFiles(int index,_str TagFileList,_str AllTagFileList,bool useThread=false)
{
   if (!_haveContextTagging()) {
      return;
   }

   flags := TREE_ADD_AS_CHILD;
   int AddedList:[];
   ext := "";
   status := 0;
   addingActiveTagFiles := false;
   for (;;) {
      CurTagFilename := "";
      if (!addingActiveTagFiles) {
         CurTagFilename = next_tag_file2(AllTagFileList,false/*no check*/,false/*no open*/);
      }
      if (CurTagFilename=="") {
         addingActiveTagFiles = true;
         CurTagFilename = next_tag_file2(TagFileList,false/*no check*/,false/*no open*/);
      }
      if (CurTagFilename=="") break;

      CurTagDescription := "";
      if (!AddedList._indexin(_file_case(CurTagFilename))) {
         bmp_index := _pic_file_tags;
         status=tag_read_db(absolute(CurTagFilename));
         if (status==FILE_NOT_FOUND_RC || status==PATH_NOT_FOUND_RC) {
            bmp_index=_pic_file_tags_error;
         } else if (status < 0) {
            ext=_get_extension(CurTagFilename);
            if (_file_eq('.'ext,TAG_FILE_EXT)) {
               bmp_index=_pic_file_tags;
            } else {
               //Invalid magic number...We assume that it is an old tag file
               NewTagFilename := _strip_filename(CurTagFilename,'E'):+TAG_FILE_EXT;
               status=RebuildOldTagFile(CurTagFilename,NewTagFilename,false,false,useThread);
               if (status) {
                  _message_box(nls("Could not rebuild old tags database %s.\n%s",CurTagFilename,get_message(status)));
                  bmp_index=_pic_file_d;
               } else {
                  CurTagFilename=NewTagFilename;
               }
            }
         } else {
            // get tag file description
            CurTagDescription = tag_get_db_comment();
            if (tag_get_db_flags() & VS_DBFLAG_occurrences) {
               bmp_index = _pic_file_refs;
            }
            tag_close_db(absolute(CurTagFilename),true);
         }
         CurTagFilename=strip(CurTagFilename,'B','"');
         allcaption := (CurTagDescription=='')? CurTagFilename:CurTagFilename' ('CurTagDescription')';
         index=tree1._TreeAddItem(index,   //Relative Index
                                  allcaption,    //Caption
                                  flags, //Flags
                                  bmp_index,         //Collapsed Bitmap Index
                                  bmp_index,         //Expanded Bitmap Index
                                  TREE_NODE_LEAF);               //Initial State
         flags=0;
         tree1._TreeSetInfo(_TreeGetParentIndex(index), TREE_NODE_EXPANDED);
         tree1._TreeSetCheckable(index, 1, 0, addingActiveTagFiles? TCB_CHECKED:TCB_UNCHECKED);
         AddedList:[_file_case(CurTagFilename)] = index;
      } else if (addingActiveTagFiles) {
         index = AddedList:[_file_case(CurTagFilename)];
         tree1._TreeSetCheckState(index, TCB_CHECKED);
      }
   }
}

/** 
 * Gets a hash table of (Remote => Local) mapped auto-updated 
 * tag file names. 
 *  
 * @param tag_filename_ht (out). Output (Remote => Local) mapped 
 *                        tag file names.
 */
static void _GetAutoUpdatedTagFileList(_str (&autoUpdateTagFiles)[], _str (&localTagFiles)[])
{
   autoUpdateTagFiles._makeempty();
   localTagFiles._makeempty();
   if ( gWorkspaceHandle < 0 ) {
      return;
   }

   // Insert the auto updated tag files
   tagFileDir := VSEWorkspaceTagFileDir();
   int autoUpdatedNodeArray[] = null;
   _WorkspaceGet_TagFileNodes(gWorkspaceHandle, autoUpdatedNodeArray);
   int i;
   for( i = 0; i < autoUpdatedNodeArray._length(); ++i ) {
      int node = autoUpdatedNodeArray[i];
      if( node < 0 ) continue;

      // Get the remote tag filename
      autoUpdateTagfile := _AbsoluteToWorkspace(_xmlcfg_get_attribute(gWorkspaceHandle, node, "AutoUpdateFrom"));

      // Get the absolute local tag filename
      localTagfile := _xmlcfg_get_attribute(gWorkspaceHandle, node, "File", _strip_filename(autoUpdateTagfile,'P'));
      if (localTagfile == "") localTagfile = _strip_filename(autoUpdateTagfile,'P');
      localTagfile = absolute(localTagfile, tagFileDir);

      autoUpdateTagFiles[autoUpdateTagFiles._length()] = autoUpdateTagfile;
      localTagFiles[localTagFiles._length()] = localTagfile;
   }
}

/**
 * Is the given file an auto-updated tag file?
 * 
 * @return A PATHSEP delimited list of auto update tag files for the current
 * workspace.  Returns '' if there are none.
 */
bool _IsAutoUpdatedTagFile(_str tagFile)
{
   // get the auto updated tag files
   if ( gWorkspaceHandle<0 ) return(false);
   int autoUpdatedNodeArray[] = null;
   _WorkspaceGet_TagFileNodes(gWorkspaceHandle, autoUpdatedNodeArray);
   int i;
   for(i = 0; i < autoUpdatedNodeArray._length(); i++) {
      // get the remote path and insert it
      int node = autoUpdatedNodeArray[i];
      if(node < 0) continue;

      _str autoUpdateTagfile = _AbsoluteToWorkspace(_xmlcfg_get_attribute(gWorkspaceHandle, node, "AutoUpdateFrom"));
      if (_file_eq(autoUpdateTagfile, tagFile)) {
         return true;
      }
   }
   return(false);
}

static void add_project_tag_file(int tree_wid, int tree_index, _str projectTagFile) 
{
   projectName := _strip_filename(projectTagFile, "PE");
   int bmp_index = _pic_file_tags;
   _str caption=projectTagFile;
   status := tag_read_db(projectTagFile);
   if (status==FILE_NOT_FOUND_RC) {
      bmp_index=_pic_file_tags_error;
   } else if (status >= 0) {
      tagFileDescription := tag_get_db_comment();
      if (tagFileDescription != "") {
         caption=projectName:+" (":+tagFileDescription:+")";
      }
      if (tag_get_db_flags() & VS_DBFLAG_occurrences) {
         bmp_index = _pic_file_refs;
      }
   }
   //We want to always display a project filename
   tree_wid._TreeAddItem(tree_index,         //Relative Index
                         caption,            //ProjectTagsFilename
                         TREE_ADD_AS_CHILD,  //Flags
                         bmp_index,          //Collapsed Bitmap Index
                         bmp_index,          //Expanded Bitmap Index
                         TREE_NODE_LEAF);    //Initial State
}

//////////////////////////////////////////////////////////////////////////////
// initialize the tag file management form
//
/**
 * Displays Tag Files dialog box.
 *
 * @return Returns '' if dialog box is cancelled.  Otherwise, a command line
 * argument ready for use as the input argument to the
 * <b>make_tags</b> function is returned.
 *
 * @example
 * <pre>
 *    show('-xy _tag_form')
 * </pre>
 */
ctldone.on_create(_str forLangId="", _str tagfilename="")
{
   // restore the position of the vertical divider bar
   typeless xpos = _moncfg_retrieve_value("_tag_form._divider.p_x");
   if (isuinteger(xpos)) _divider.p_x = xpos;
   _divider.p_user = _divider.p_x;
   ctl_files_label.p_user = "";
   ctl_files_gauge.p_user = "";

   if (_win32s()==1) {
      ctlautotag_btn.p_visible=false;
      ctlautotag_btn.p_enabled=false;
   }
   _xlat_old_vslicktags();

   // save the original language ID option
   TAGFORM_LANGUAGE_ID(forLangId);
   TAGFORM_IS_MODIFIED(false);

   // insert folder for workspace and project tag files
   ProjectTagfilesIndex := 0;
   if (forLangId == null || forLangId == "" || forLangId == WORKSPACE_LANG_ID) {
      ProjectTagfilesIndex = UpdateWorkspaceTagFiles();
   }

   // insert folder for automatically updated tag files
   autoUpdatedTagFilesIndex := 0;
   if (forLangId == null || forLangId == "" || forLangId == WORKSPACE_LANG_ID) {
      autoUpdatedTagFilesIndex = UpdateAutoUpdateTagFiles();
   }
   TAG_FOLDER_INDEXES(ProjectTagfilesIndex :+ " " :+ autoUpdatedTagFilesIndex);

   // insert folders for compiler config tag files
   UpdateAllCompilerTagFiles(forLangId);

   // get each of the extension specific tag file lists
   wid := _form_parent();
   CurModeName := "";
   isWorkspaceFile := false;
   if (forLangId != "" && forLangId != WORKSPACE_LANG_ID) {
      CurModeName = _LangId2Modename(forLangId);
      if (tagfilename == "" && wid && wid._isEditorCtl()) {
         tag_files := tags_filenamea(forLangId);
         foreach (auto tf in tag_files) {
            status := tag_read_db(tf);
            if (status < 0) continue;
            status = tag_find_file(auto found_file, wid.p_buf_name);
            if (status < 0) continue;
            if (_file_eq(found_file, wid.p_buf_name)) {
               tagfilename = tf;
            }
         }
      }
   } else if (wid && wid._isEditorCtl() && forLangId != WORKSPACE_LANG_ID) {
      CurModeName=wid.p_mode_name;
      if (tagfilename == "") {
         tag_files := tags_filenamea(wid.p_LangId);
         foreach (auto tf in tag_files) {
            status := tag_read_db(tf);
            if (status < 0) continue;
            status = tag_find_file(auto found_file, wid.p_buf_name);
            if (status < 0) continue;
            if (_file_eq(found_file, wid.p_buf_name)) {
               tagfilename = tf;
            }
         }
      }
      if (tagfilename == "") {
         if (_workspace_filename != "" && _FileExistsInCurrentWorkspace(wid.p_buf_name)) {
            isWorkspaceFile = true;
         }
      }
   }

   // add all the TagFiles stored in LanguageSettings
   UpdateTagFilesForLanguages(forLangId);

   // now maybe add one more for the current language mode
   // in case if there isn't one already.
   if (CurModeName != "") {
      langId := _Modename2LangId(CurModeName);
      if (_istagging_supported(langId)) {
         languageTagFilesCaption := '"':+CurModeName:+'" ':+LANGUAGE_CONFIG_FOLDER_NAME;
         langSectionIndex := tree1._TreeSearch(TREE_ROOT_INDEX, languageTagFilesCaption);
         if (langSectionIndex <= 0) {
            compilerTagFilesCaption := '"':+CurModeName:+'" ':+COMPILER_CONFIG_FOLDER_NAME;
            langCompilerIndex := tree1._TreeSearch(TREE_ROOT_INDEX, compilerTagFilesCaption);
            if (langCompilerIndex > 0) {
               langSectionIndex = tree1._TreeAddItem(langCompilerIndex,    //Relative Index
                                                      '"'CurModeName'" ':+LANGUAGE_CONFIG_FOLDER_NAME,//Caption
                                                      TREE_ADD_AFTER,     //Flags
                                                      _pic_fldclos,       //Collapsed Bitmap Index
                                                      _pic_fldopen,       //Expanded Bitmap Index
                                                      TREE_NODE_LEAF);                //Initial State
            } else {
               langSectionIndex = tree1._TreeAddItem(TREE_ROOT_INDEX,    //Relative Index
                                                      '"'CurModeName'" ':+LANGUAGE_CONFIG_FOLDER_NAME,//Caption
                                                      TREE_ADD_AS_CHILD,  //Flags
                                                      _pic_fldclos,       //Collapsed Bitmap Index
                                                      _pic_fldopen,       //Expanded Bitmap Index
                                                      TREE_NODE_LEAF);                //Initial State
            }
         }
         TAG_FOLDER_INDEXES(TAG_FOLDER_INDEXES()' 'langSectionIndex);
         tree1._TreeSetCurIndex(langSectionIndex);
         CurModeName='';
      }
   }

   // select the item to use as the current node
   if (CurModeName != "" && !isWorkspaceFile) {
      compilerTagFilesCaption := '"':+CurModeName:+'" ':+COMPILER_CONFIG_FOLDER_NAME;
      langCompilerIndex := tree1._TreeSearch(TREE_ROOT_INDEX, compilerTagFilesCaption);
      languageTagFilesCaption := '"':+CurModeName:+'" ':+LANGUAGE_CONFIG_FOLDER_NAME;
      langSectionIndex := tree1._TreeSearch(TREE_ROOT_INDEX, languageTagFilesCaption);
      if (langSectionIndex <= 0) langSectionIndex = langCompilerIndex;
      if (langSectionIndex > 0) {
         tree1._TreeSetCurIndex(langSectionIndex);
         tree1._TreeScroll(tree1._TreeGetLineNumber(langSectionIndex));
         if (tree1._TreeGetNumChildren(langSectionIndex) == 1) {
            tree1._TreeDown();
         }
      }
   }

   // initialize to the tag file they specified, if it is there
   if (tagfilename != "") {
      tagfileindex := tree1._TreeSearch(TREE_ROOT_INDEX, tagfilename, 'PT':+(_files_case_sensitive()? '':'I'));
      if (tagfileindex > 0) {
         tree1._TreeSetCurIndex(tagfileindex);
      }
   }

   SetTagFiles();
   index:=tree1._TreeCurIndex();
   if (index>=0) {
      tree1.call_event(CHANGE_SELECTED,index,tree1,ON_CHANGE,'W');
   }else{
      //There is nothing in the tree, so call the on change with TREE_ROOT_INDEX
      //for the index.  This will cause the right buttons to be enabled/disabled
      tree1.call_event(CHANGE_SELECTED,TREE_ROOT_INDEX,tree1,ON_CHANGE,'W');
   }
}

static int UpdateCompilerTagsFiles(_str (&compiler_names)[], _str langId)
{
   activeConfigName := refactor_get_active_config_name(-1, langId);
   compilerTagFilesCaption := '"' :+ _LangId2Modename(langId) :+ '" ' :+ COMPILER_CONFIG_FOLDER_NAME;
   compilerTagFilesIndex := tree1._TreeSearch(TREE_ROOT_INDEX, compilerTagFilesCaption);
   if (compilerTagFilesIndex < 0) {
      if (compiler_names._length() <= 0) {
         return -1;
      }
      compilerTagFilesIndex = tree1._TreeAddItem(TREE_ROOT_INDEX,
                                                 compilerTagFilesCaption,
                                                 TREE_ADD_AS_CHILD,
                                                 _pic_fldclos,
                                                 _pic_fldopen,
                                                 TREE_NODE_EXPANDED);
   }

   tree1._TreeBeginUpdate(compilerTagFilesIndex);
   for (i:=0; i<compiler_names._length(); ++i) {
      compilerTagFile := _tagfiles_path():+compiler_names[i]:+TAG_FILE_EXT;
      if (!file_exists(compilerTagFile)) {
         continue;
      }

      caption := compilerTagFile;
      bmp_index := _pic_file_tags;
      status := tag_read_db(compilerTagFile);
      if (status == FILE_NOT_FOUND_RC || status == PATH_NOT_FOUND_RC) {
         bmp_index = _pic_file_tags_error;
      } else if(status >= 0) {
         description := tag_get_db_comment();
         if(description != "") {
            caption :+= " (" description ")";
         }
         if(tag_get_db_flags() & VS_DBFLAG_occurrences) {
            bmp_index = _pic_file_refs;
         }
      }

      // store absolute local filename in user info for the node
      index := tree1._TreeAddItem(compilerTagFilesIndex, caption, TREE_ADD_AS_CHILD, bmp_index, bmp_index, TREE_NODE_LEAF, 0, compilerTagFile);
      tree1._TreeSetCheckable(index, 1, 0, (compiler_names[i] == activeConfigName)? TCB_CHECKED:TCB_UNCHECKED);
   }
   tree1._TreeEndUpdate(compilerTagFilesIndex);
   return compilerTagFilesIndex;
}

static void UpdateAllCompilerTagFiles(_str forLangId=null)
{
   // get the list of compiler configurations
   _str c_compiler_names[];
   _str java_compiler_names[];
   refactor_get_compiler_configurations(c_compiler_names, java_compiler_names);

   // insert folders for compiler config tag files
   c_compilerTagFileIndex := 0;
   if (forLangId=="" || _LanguageInheritsFrom("c", forLangId)) {
      c_compilerTagFileIndex = UpdateCompilerTagsFiles(c_compiler_names, "c");
   }
   j_compilerTagFileIndex := 0;
   if (forLangId=="" || _LanguageInheritsFrom("java", forLangId)) {
      j_compilerTagFileIndex = UpdateCompilerTagsFiles(java_compiler_names, "java");
   }

   parse TAG_FOLDER_INDEXES() with auto workspaceIndex auto autoUpdateIndex . . auto rest;
   TAG_FOLDER_INDEXES(workspaceIndex " " autoUpdateIndex " " c_compilerTagFileIndex " " j_compilerTagFileIndex " " rest);
}

static int UpdateAutoUpdateTagFiles()
{
   autoUpdatedTagFilesIndex := -1;
   if (_workspace_filename != "") {
      autoUpdatedTagFilesIndex = tree1._TreeSearch(TREE_ROOT_INDEX, AUTO_UPDATED_FOLDER_NAME);
      if (autoUpdatedTagFilesIndex < 0) {
         autoUpdatedTagFilesIndex = tree1._TreeAddItem(TREE_ROOT_INDEX,
                                                       AUTO_UPDATED_FOLDER_NAME,
                                                       TREE_ADD_AS_CHILD,
                                                       _pic_fldclos,
                                                       _pic_fldopen,
                                                       TREE_NODE_EXPANDED);
         parse TAG_FOLDER_INDEXES() with auto workspaceIndex auto autoUpdateIndex auto rest;
         if (autoUpdateIndex != "") {
            TAG_FOLDER_INDEXES(strip(workspaceIndex " " autoUpdatedTagFilesIndex " " rest));
         }
      }

      _str autoUpdatedTagFiles[];
      _str localTagFiles[];
      _GetAutoUpdatedTagFileList(autoUpdatedTagFiles, localTagFiles);

      tree1._TreeBeginUpdate(autoUpdatedTagFilesIndex);
      for (i:=0; i<autoUpdatedTagFiles._length() && i<localTagFiles._length(); i++) {
         autoUpdateTagfile := autoUpdatedTagFiles[i];
         localTagfile := localTagFiles[i]; 
         caption := autoUpdateTagfile;
         bmp_index := _pic_file_tags;
         status := tag_read_db(localTagfile);
         if( status == FILE_NOT_FOUND_RC || status == PATH_NOT_FOUND_RC ) {
            bmp_index = _pic_file_tags_error;
         } else if( status >=0 ) {
            _str description = tag_get_db_comment();
            if( description != "" ) {
               caption :+= " (" description ")";
            }
            if( tag_get_db_flags() & VS_DBFLAG_occurrences ) {
               bmp_index = _pic_file_refs;
            }
         }

         // Store absolute local filename in user info for the node
         tree1._TreeAddItem(autoUpdatedTagFilesIndex,caption,TREE_ADD_AS_CHILD,bmp_index,bmp_index,TREE_NODE_LEAF,0,localTagfile);
      }
      tree1._TreeEndUpdate(autoUpdatedTagFilesIndex);
   } else {
      autoUpdatedTagFilesIndex = tree1._TreeSearch(TREE_ROOT_INDEX, AUTO_UPDATED_FOLDER_NAME);
      if (autoUpdatedTagFilesIndex > 0) {
         tree1._TreeDelete(autoUpdatedTagFilesIndex, 'C');
      }
   }
   return autoUpdatedTagFilesIndex;
}

static int UpdateWorkspaceTagFiles()
{
   workspaceTagFilesIndex := -1;
   if (_workspace_filename != "") {
      workspaceTagFilesIndex = tree1._TreeSearch(TREE_ROOT_INDEX, WORKSPACE_FOLDER_NAME);
      if (workspaceTagFilesIndex < 0) {
         workspaceTagFilesIndex = tree1._TreeAddItem(TREE_ROOT_INDEX,
                                                     WORKSPACE_FOLDER_NAME,
                                                     TREE_ADD_AS_CHILD,
                                                     _pic_fldclos,
                                                     _pic_fldopen,
                                                     TREE_NODE_EXPANDED);
         parse TAG_FOLDER_INDEXES() with auto workspaceIndex auto rest;
         if (workspaceIndex != "") {
            TAG_FOLDER_INDEXES(strip(workspaceTagFilesIndex " " rest));
         }
      }
      tree1._TreeBeginUpdate(workspaceTagFilesIndex);

      if (isEclipsePlugin()) {
         wspaceTagfiles := "";
         status := _eclipse_get_projects_tagfiles(wspaceTagfiles);
         curProjTagfile := next_tag_file2(wspaceTagfiles, false);
         while (curProjTagfile != "") {
            add_project_tag_file(tree1.p_window_id, workspaceTagFilesIndex, curProjTagfile);
            curProjTagfile = next_tag_file2(wspaceTagfiles, false);
         }

      } else if (_workspace_filename != "") {
         wkspaceTagFilename := workspace_tags_filename_only();
         add_project_tag_file(tree1.p_window_id, workspaceTagFilesIndex, wkspaceTagFilename);

         projectTagFiles := project_tags_filename();
         projectTagFiles = strip(projectTagFiles,'B',';');
         if (!_file_eq(projectTagFiles, wkspaceTagFilename)) {
            curProjTagfile := next_tag_file2(projectTagFiles, false);
            while (curProjTagfile != "") {
               if (!_file_eq(curProjTagfile, wkspaceTagFilename)) {
                  add_project_tag_file(tree1.p_window_id, workspaceTagFilesIndex, curProjTagfile);
               }
               curProjTagfile = next_tag_file2(projectTagFiles, false);
            }
         }
      }

      /*
      ReferencesFilesIndex=tree1._TreeAddItem(TREE_ROOT_INDEX,    //Relative Index
                                              'References File',//Caption
                                              TREE_ADD_AS_CHILD,  //Flags
                                              _pic_fldclos,       //Collapsed Bitmap Index
                                              _pic_fldopen,       //Expanded Bitmap Index
                                              -1);                //Initial State
      */

      tree1._TreeEndUpdate(workspaceTagFilesIndex);
   } else {
      workspaceTagFilesIndex = tree1._TreeSearch(TREE_ROOT_INDEX, WORKSPACE_FOLDER_NAME);
      if (workspaceTagFilesIndex > 0) {
         tree1._TreeDelete(workspaceTagFilesIndex, 'C');
      }
   }
   return workspaceTagFilesIndex;
}

//////////////////////////////////////////////////////////////////////////////
// Get the file name of the tag file in the tree at 'index'
//
static _str GetRealTagFilenameFromTree(int index)
{
   typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
   typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
   parse TAG_FOLDER_INDEXES() with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;

   TagFilename := _TreeGetCaption(index);
   rest := "";
   parse TagFilename with TagFilename ' (' rest ')';

   if(_workspace_filename != "" && tree1._TreeGetParentIndex(index) == autoUpdateFilesIndex) {
      // no need to absolute this path because it is guaranteed to be absolute
      // for auto updated tag files
      TagFilename = _TreeGetUserInfo(index);
   } else {
      if (_TreeGetUserInfo(index)=='R') {
         TagFilename=absolute(TagFilename);
      }
   }

   return(TagFilename);
}

//////////////////////////////////////////////////////////////////////////////
// Handle change events for the tag file tree
//
void tree1.on_change(int reason,int index)
{
   if (TAGFORM_SKIP_ON_CHANGE()==1) return;

   parentIndex := 0;
   typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
   typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
   parse TAG_FOLDER_INDEXES() with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;

   switch (reason) {
   case CHANGE_SELECTED:
      if (index < 0) return;
      depth := tree1._TreeGetDepth(index);
      if(depth==TAGFORM_FILE_DEPTH) {
         // handle auto updated tag files
         if(tree1._TreeGetParentIndex(index) == autoUpdateFilesIndex) {
            // disable all buttons that modify the tagfile
            ctlremove_files_btn.p_enabled=false;
            ctlfiles_btn.p_enabled = false;
            ctltree_btn.p_enabled = false;
            ctlretag_files_btn.p_enabled = false;
            ctlremove_files_btn.p_enabled = false;

            ctlrebuild_tag_file_btn.p_enabled = false;
            ctlup_btn.p_enabled = true;
            ctldown_btn.p_enabled = true;
            ctlnew_tag_file_btn.p_enabled = true;
            ctlremove_tag_file_btn.p_enabled = true;

            // load files from local copy of tagfile
            mou_hour_glass(true);
            list1.LoadFileNameList(GetRealTagFilenameFromTree(index));
            mou_hour_glass(false);
         
         } else if (tree1._TreeGetParentIndex(index) == ProjectTagfilesIndex) {
            ctlremove_files_btn.p_enabled=false;
            ctlfiles_btn.p_enabled=false;
            ctltree_btn.p_enabled=false;
            ctlretag_files_btn.p_enabled=true;
            ctloptions_btn.p_enabled=true;

            if (ctldone.p_visible) {
               ctldone.p_enabled=true;
            }
            ctlnew_tag_file_btn.p_enabled=true;
            ctlremove_tag_file_btn.p_enabled = false;
            ctlrebuild_tag_file_btn.p_enabled=true;
            ctldown_btn.p_enabled=false;
            ctlup_btn.p_enabled=false;

            // load files from local copy of tagfile
            mou_hour_glass(true);
            list1.LoadFileNameList(GetRealTagFilenameFromTree(index));
            mou_hour_glass(false);
         
         } else {
            // Not a workspace or auto-updated tag file, could be a
            // compiler tag file though.
            ctlremove_files_btn.p_enabled=true;
            ctlfiles_btn.p_enabled=true;
            ctltree_btn.p_enabled=true;

            if (ctldone.p_visible) {
               ctldone.p_enabled=true;
            }
            ctlretag_files_btn.p_enabled=true;
            ctloptions_btn.p_enabled=true;

            ctlnew_tag_file_btn.p_enabled=true;
            ctlrebuild_tag_file_btn.p_enabled=true;

            mou_hour_glass(true);
            parentIndex = tree1._TreeGetParentIndex(index);
            TagFilename:=GetRealTagFilenameFromTree(index);
            list1.LoadFileNameList(TagFilename);
            mou_hour_glass(false);

            // Can't move compiler config files up or down
            ctlup_btn.p_enabled = ctldown_btn.p_enabled = 
               ( parentIndex!=ProjectTagfilesIndex && 
                 parentIndex!=cppCompilerTagFilesIndex && 
                 parentIndex!=javaCompilerTagFilesIndex );

            // do not allow removal of workspace tag files, auto-generated tag files, or compiler tag files
            ctlremove_tag_file_btn.p_enabled = (parentIndex!=ProjectTagfilesIndex);
         }

      } else if (depth==TAGFORM_FOLDER_DEPTH) {
         parentIndex=index;
         ctltree_btn.p_enabled=false;
         ctlfiles_btn.p_enabled=false;
         ctlretag_files_btn.p_enabled=false;
         ctlremove_files_btn.p_enabled=false;

         ctlnew_tag_file_btn.p_enabled=true;
         ctlremove_tag_file_btn.p_enabled=false;
         ctlrebuild_tag_file_btn.p_enabled=false;
         ctldown_btn.p_enabled=false;
         ctlup_btn.p_enabled=false;

         ctl_files_label.p_caption = get_message(VSRC_CFG_TAG_FILES_NONE);
         list1._lbclear();

      } else if (!depth) {
         //Root node.  This means there is nothing in the tree!!!!
         ctltree_btn.p_enabled=ctlfiles_btn.p_enabled=ctlretag_files_btn.p_enabled=false;
         ctlremove_tag_file_btn.p_enabled=ctlremove_files_btn.p_enabled=false;
         ctlrebuild_tag_file_btn.p_enabled=ctldown_btn.p_enabled=ctlup_btn.p_enabled=false;
         ctl_files_label.p_caption = get_message(VSRC_CFG_TAG_FILES_NONE);
         list1._lbclear();
      }
      break;
   case CHANGE_CHECK_TOGGLED:
      TagFilename := GetRealTagFilenameFromTree(index);
      justTagFileName := _strip_filename(TagFilename, 'PE');
      parentIndex = tree1._TreeGetParentIndex(index);
      if (parentIndex == cppCompilerTagFilesIndex) {
         activeConfigName := refactor_get_active_config_name(-1, "c");
         _TreeSetCheckState(index, (activeConfigName == justTagFileName)? TCB_CHECKED : TCB_UNCHECKED);
         message("Can not change active compiler configuration here, use Project Properties dialog.");
         return;
      } else if (parentIndex == javaCompilerTagFilesIndex) {
         activeConfigName := refactor_get_active_config_name(-1, "java");
         _TreeSetCheckState(index, (activeConfigName == justTagFileName)? TCB_CHECKED : TCB_UNCHECKED);
         message("Can not change active compiler configuration here, use Project Properties dialog.");
         return;
      }
      if (tree1._TreeGetCheckState(index) == TCB_CHECKED) {
         SetTagFilesOrSetModified(parentIndex, TagFilename, 'A');
      } else {
         SetTagFilesOrSetModified(parentIndex, TagFilename, 'R');
      }
      break;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle double-click events for the source file list
//
list1.lbutton_double_click,enter()
{
   _str filename=_lbget_text();
   if (filename != '') {
      if (!_QBinaryLoadTagsSupported(filename)) {
         edit(_maybe_quote_filename(filename),EDIT_DEFAULT_FLAGS);
      } else {
         message(nls('Can not locate source code for %s.',filename));
      }
   }
}

/**
 * @return Return the full path to the workspace tag file.
 *  
 * @categories Tagging_Functions 
 */
_str _GetWorkspaceTagsFilename()
{
   return workspace_tags_filename_only();
}

/**
 * @return Return the full path to the workspace C/C++ Preprocessing 
 * configuration header file.  Return "" if there is no workspace open.
 *  
 * @categories Tagging_Functions 
 */
_str _GetWorkspaceCPPHeaderFilename()
{
   if (_workspace_filename == "") return "";
   workspace_basename := _strip_filename(_workspace_filename,'E');
   return workspace_basename :+ "_cpp.h";
}

//////////////////////////////////////////////////////////////////////////////
// Is a tag file currently selected in the tag form tree?
//
static bool FileIsSelected()
{
   index := tree1._TreeCurIndex();
   int depth=tree1._TreeGetDepth(index);
   return(depth==TAGFORM_FILE_DEPTH);
}

//////////////////////////////////////////////////////////////////////////////
// Add a new(currently non-existant) file
// 9:43am 6/24/1999
// Needed this for workspace stuff(DWH)
int tag_add_new_file(_str TagFilename, _str filename,
                     _str ProjectName=_project_name,
                     bool AddToProject=true,
                     bool useThread=false)
{
   // create a temporary view
   int list_view_id;
   int orig_view_id = _create_temp_view(list_view_id);
   if (orig_view_id == '') {
      return(COMMAND_CANCELLED_RC);
   }

   // add files from the given file list to the tag file
   insert_line(filename);

   // Tag the files in the temporary view and close out the view
   p_window_id = list_view_id;
   top(); up();
   retag_occurrences := (def_references_options & VSREF_NO_WORKSPACE_REFS)==0;
   RetagFilesInTagFile2(TagFilename,
                        orig_view_id, list_view_id,
                        false, false, retag_occurrences,
                        false, false, useThread,
                        true, false, false, false, false, true);

   // get the project tags file name, and add files to project if needed
   if (AddToProject) {
      AddFileListToProjectFiles(ProjectName,_maybe_quote_filename(filename),0,false,false);
   }
   activate_window(orig_view_id);
   _delete_temp_view(list_view_id);
   return(0);
}

//////////////////////////////////////////////////////////////////////////////
// Add tags from the given list of files to the given tag file
//
int tag_add_viewlist(_str TagFilename, int filelist_view_id,
                     _str ProjectName=_project_name,
                     bool AddFilesToProject=true,
                     bool FileExistsOnDisk=true,
                     bool useThread=false)
{
   int orig_view_id;
   get_window_id(orig_view_id);  // This can be the list view id!


   // Tag the files in the temporary view and close out the view
   p_window_id = filelist_view_id;
   top(); up();
   retag_occurrences := (def_references_options & VSREF_NO_WORKSPACE_REFS)==0;
   RetagFilesInTagFile2(TagFilename,
                        orig_view_id, filelist_view_id,
                        false, false, retag_occurrences,
                        false, false, useThread,
                        !FileExistsOnDisk, false, false,
                        false, false, true);

   /*
      Need to do this after tagging so we can query the package names from the
      tag data base.
   */
   // get the project tags file name, and add files to project if needed
   _str project_tag_files=project_tags_filename_only(ProjectName);
   if (_file_eq(TagFilename,project_tag_files) && AddFilesToProject) {
      AddFileListToProjectFiles(ProjectName,'',filelist_view_id);
   }
   activate_window(orig_view_id);
   _delete_temp_view(filelist_view_id);
   return(0);
}
//////////////////////////////////////////////////////////////////////////////
// Add tags from the given list of files to the given tag file
//
int tag_add_filelist(_str TagFilename,typeless filelist,
                     _str ProjectName=_project_name,
                     bool useThread=false,
                     bool AddFilesToProject=true)
{
   // create a temporary view
   int list_view_id;
   int orig_view_id = _create_temp_view(list_view_id);
   if (orig_view_id == '') {
      return(COMMAND_CANCELLED_RC);
   }

   if (filelist._varformat()==VF_ARRAY) {
      _str wildcard, filename;
      for (i:=0;i<filelist._length();++i) {
         wildcard=filelist[i];
         if (wildcard=='') break;
         ff := 1;
         for (;;) {
            filename=file_match2(wildcard,ff,'-p');ff=0;
            if (filename=='') {
               break;
            }
            insert_line(filename);
         }
      }
   } else {
      // add files from the given file list to the tag file
      _str wildcard, filename;
      for (;;) {
         wildcard=parse_file(filelist,false);
         if (wildcard=='') break;
         ff := 1;
         for (;;) {
            filename=file_match2(wildcard,ff,'-p');ff=0;
            if (filename=='') {
               break;
            }
            insert_line(filename);
         }
      }
   }
   p_window_id=orig_view_id;
   return(tag_add_viewlist(TagFilename,list_view_id,ProjectName,AddFilesToProject,true,useThread));
}

//////////////////////////////////////////////////////////////////////////////
// Is this the workspace tag file ?
//
static bool isWorkspaceTagFileName(_str tag_filename)
{
   if (_file_eq(tag_filename, VSEWorkspaceTagFilename())) {
      return true;
   }
   return false;
}

//////////////////////////////////////////////////////////////////////////////
// Is this a project specific tag file ?
//
static bool isProjectTagFileName(_str tag_filename)
{
   if (_file_eq(tag_filename, workspace_tags_filename_only())) return false;
   project_tag_files := project_tags_filenamea();
   foreach (auto tf in project_tag_files) {
      if (_file_eq(tag_filename, tf)) {
         return true;
      }
   }
   return false;
}

//////////////////////////////////////////////////////////////////////////////
//  Handle 'add files' button press or menu selection
//
void ctlfiles_btn.lbutton_up()
{
   if (!FileIsSelected()) return;
   //TagFilename=tree1._TreeGetCaption(tree1._TreeCurIndex());
   _str TagFilename=tree1.GetRealTagFilenameFromTree(tree1._TreeCurIndex());
   TagDir := _strip_filename(TagFilename,'N');
   _str olddir=getcwd();


   // Change to workspace directory when we're about to add files
   // to the workspace tag file.
   if (isWorkspaceTagFileName(TagFilename)) {
      WorkspaceDir := _strip_filename(_workspace_filename, 'N');
      chdir(WorkspaceDir,1);
   }

   // Change to project file directory when we're about to add files
   // to the a project tag file.
   if (isProjectTagFileName(TagFilename)) {
      project_file := project_tags_filename_to_project_file(TagFilename);
      ProjectDir := _strip_filename(project_file, 'N');
      chdir(ProjectDir,1);
   }

   // get modename, wildcards, and whether this is a references database
   _str mode_name, wildcards;
   _GetWildcardsForTagFile(true, wildcards,mode_name);
   _str result;
   if (/*_DataSetSupport()*/ _DataSetIsFile(_last_open_path)) {
      // Just default to All Files to prevent each member of PDS to
      // be opened. Some PDS can be very large!
      wildcards = ALLFILES_RE;
   }
   // get modename, wildcards, and whether this is a references database
   _str filtercards=wildcards;
   if (filtercards=="") {
      filtercards = _last_wildcards;
      if (filtercards == '') {
         filtercards = _default_c_wildcards();
      }
   }
   if (/*_DataSetSupport()*/ _DataSetIsFile(_last_open_path)) {
      // Just default to All Files to prevent each member of PDS to
      // be opened. Some PDS can be very large!
      filtercards = ALLFILES_RE;
   }
   result=_OpenDialog("-modal",
                      'Add Source Files',// title
                      filtercards,// Initial wildcards
                      EXTRA_FILE_FILTERS:+',':+def_file_types,
                      OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT|OFN_SET_LAST_WILDCARDS,
                      "", // Default extension
                      ""/*wildcards*/, // Initial filename
                      "");// Initial directory
   chdir(olddir,1);
   if (result=='') return;

   int filelist_view_id;
   int orig_view_id=_create_temp_view(filelist_view_id);
   p_window_id=filelist_view_id;
   _str file_spec_list = result;
   while (file_spec_list != '') {
      _str file_spec = parse_file(file_spec_list);
      insert_file_list(file_spec' -v +p -d');
   }
   p_line=0;

   // Add files to the current project file
   message('SlickEdit is building tags for new files');

   // delegate to general purpose function for retagging files
   useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
   RetagFilesInTagFile2(TagFilename, 
                        orig_view_id, filelist_view_id, 
                        false, false, false,
                        false, false, useThread, 
                        false, true, true, 
                        false, false, true);
   activate_window((int)orig_view_id);

   // update the list of files, that's all
   index := tree1._TreeCurIndex();
   if (index>=0) {
      tree1.call_event(CHANGE_SELECTED,index,tree1,ON_CHANGE,'W');
   }
   mou_hour_glass(false);
   clear_message();
}

/**
 * Add the given list of files to the project file.
 * <P>
 * <P>IMPORTANT: Files must be absolute or relative to the
 * CURRENT DIRECTORY and NOT the project directory.
 *
 * @param project_filename
 *                 absolute project filename
 * @param filelist space delimited list of file names.  Filenames with spaces must be double quoted.
 * @param list_view_id
 *                 View list of files.  1 file per line.
 * @return Returns 0 if successful.
 */
static int AddFileListToProjectFiles(_str project_filename,_str filelist,int list_view_id=0,
                                     bool list_box_format=false,
                                     bool FileExistsOnDisk=true)
{
   status := 0;
   line := "";
   int handle=_ProjectHandle(project_filename);
   if (_IsWorkspaceAssociated(_workspace_filename) &&
       _IsAddDeleteSupportedWorkspaceFilename(_workspace_filename) &&
       _CanWriteFileSection( GetProjectDisplayName(project_filename) ) ) {
      if (list_view_id) {
         orig_view_id := p_window_id;
         p_window_id=list_view_id;
         top();up();
         while (!down()) {
            get_line(line);
            if (list_box_format) {
               line=substr(line,2);
            }
            filelist :+= ' '_maybe_quote_filename(line);
         }
         p_window_id=orig_view_id;
      }

      // check the project type
      if(_file_eq(_get_extension(GetProjectDisplayName(project_filename), true), JBUILDER_PROJECT_EXT)) {
         status = _AddFilesToJBuilderProject(filelist, project_filename/*, !FileExistsOnDisk*/);
      } else {
         status=_AddFileToVCPPMakefile(filelist,project_filename,!FileExistsOnDisk);
      }
      toolbarUpdateFilterList(project_filename);
      return(status);
   }
   if(_IsWorkspaceAssociated(_workspace_filename)) {
      _message_box(nls("Can't add files to this associated workspace"));
      return(1);
   }
   /*
      Get all the files from XML project file into a view
      Add the new files to the view if not already present
      sort the view
      re-add all files to the folders of XML project file
   */
   orig_view_id := p_window_id;

   int old_array_size=_default_option(VSOPTION_WARNING_ARRAY_SIZE);
   _default_option(VSOPTION_WARNING_ARRAY_SIZE,MAXINT);

   //filelist=result;
   if (list_view_id) {
      activate_window(list_view_id);
      top();up();
   }
   filename := "";
   _str NewFilesList[];
   project_path := _strip_filename(project_filename,'N');
   for (;;) {
      if (list_view_id) {
         if(down()) break;
         get_line(filename);
         filename=strip(filename);
      } else {
         filename=parse_file(filelist);
      }
      filename=strip(filename,'B','"');
      if (filename=='') break;
      filename=relative(absolute(filename),project_path);
      int Node=_ProjectGet_FileNode(handle,filename);
      if (Node<0) {
         NewFilesList[NewFilesList._length()]=filename;
      }
   }
   _default_option(VSOPTION_WARNING_ARRAY_SIZE,old_array_size);
   _ProjectAdd_Files(handle,NewFilesList);

   p_window_id=orig_view_id;
   status=_ProjectSave(handle);
   if (status) {
      _message_box(nls("Could not add files to project file %s.\n%s",project_filename,get_message(status)));
      mou_hour_glass(false);
      return(status);
   }
   toolbarUpdateFilterList(project_filename);
   //_delete_temp_view(temp_view_id);

   // regenerate makefile
   _maybeGenerateMakefile(project_filename);

   call_list('_prjupdate_');
   return(0);
}

// this is needed because background tagging will call SEFilename2LangId()
void _LoadBackgroundTaggingSettings_Filename2LangId()
{
   _file_name_map_initialize();
}

static int retag_project_with_files_in_view(_str tag_filename, 
                                            int list_view_id, 
                                            bool force_create,
                                            bool rebuild_all,
                                            bool tag_occurrences,
                                            bool doRemove,
                                            bool removeWithoutPrompting,
                                            bool keepWithoutPrompting,
                                            bool useThread,
                                            bool quiet,
                                            bool checkAllDates,
                                            bool allowCancel)
{
   // check if there are no or very few tag files,
   // special case of removing all files optimization
   orig_view_id := p_window_id;
   p_window_id = list_view_id;
   if (p_Noflines <= 1) {
      rebuild_all = true;
   }

   // open, or create from scratch the tag file
   int database_flags = (def_references_options & VSREF_NO_WORKSPACE_REFS)? 0:VS_DBFLAG_occurrences;
   status := _OpenOrCreateTagFile(tag_filename, false,
                                 VS_DBTYPE_tags, database_flags);
   // check for database corruption
   if (status == BT_DATABASE_CORRUPT_RC || (tag_occurrences != (database_flags & VS_DBFLAG_occurrences))) {
      // database is corrupted so delete it
      if(delete_file(tag_filename) == 0) {
         // deletion was successful so call the create function again
         status = _OpenOrCreateTagFile(tag_filename, false,
                                       VS_DBTYPE_tags, database_flags);
      }
   }

   if (status < 0) {
      _delete_temp_view(list_view_id);
      if (_iswindow_valid(orig_view_id)) {
         activate_window(orig_view_id);
      }
      return status;
   }

   // iterate through the files in the database and remove files not
   // found in the project file
   if (!rebuild_all && doRemove) {
      p_window_id=list_view_id;
      message('Updating files from 'tag_filename);
      top();
     
      // Load all the files in the tag file into a hash table     
      _str files_in_tag_database:[];
      filename := "";
      status = tag_find_file(filename);
      while (!status) {
         files_in_tag_database:[_file_case(filename)] = filename;
         status = tag_next_file(filename);
      }
      tag_reset_find_file();

      // compare sorted filelists from workspace to the files in the hash table
      status = 0;
      while (!status) {
         get_line(filename);
         filename = _file_case(filename);
         if (files_in_tag_database._indexin(filename)) {
            files_in_tag_database._deleteel(filename);
         }
         status = down();
      }

      // remove any remaining filenames in tag_view_id
      cased_filename := "";
      foreach (cased_filename => filename in files_in_tag_database) {
         tag_remove_from_file(filename);
      }
   }

   // Tag/retag all the files in the project
   p_window_id=list_view_id;
   p_line=0;
   //_delete_temp_view(temp_view_id);
   status = RetagFilesInTagFile2(tag_filename, 
                                 orig_view_id, list_view_id,
                                 force_create, rebuild_all, tag_occurrences,
                                 doRemove, removeWithoutPrompting,
                                 useThread, quiet,
                                 checkAllDates, true, allowCancel,
                                 false, keepWithoutPrompting);
   if (_iswindow_valid(orig_view_id)) activate_window(orig_view_id);
   return status;
}

int _workspace_update_files_retag(bool rebuild_all=false,
                                  bool doRemove=false,
                                  bool RemoveWithoutPrompting=false,
                                  bool quiet=false,
                                  bool tag_occurrences=false,
                                  bool checkAllDates=false,
                                  bool useThread=false,
                                  bool allowCancel=false,
                                  bool KeepWithoutPrompting=false,
                                  bool rebuildWorkspaceOnly=false)
{
   // No tagging support?
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // Do nothing if there is no workspace open
   if (_workspace_filename=='') {
      return VSRC_NO_CURRENT_WORKSPACE;
   }

   // Get the name of the workspace tag file
   workspace_tag_file := workspace_tags_filename_only();

   // If they want to do the tagging on a thread, start it that way.
   if (useThread && (RemoveWithoutPrompting || KeepWithoutPrompting)) {

      // set up tag file rebuild flags based on arguments
      rebuildFlags := 0;
      if (rebuild_all)     rebuildFlags |= VS_TAG_REBUILD_FROM_SCRATCH;
      if (!rebuild_all)    rebuildFlags |= VS_TAG_REBUILD_CHECK_DATES;
      if (checkAllDates)   rebuildFlags |= VS_TAG_REBUILD_CHECK_DATES;
      if (tag_occurrences) rebuildFlags |= VS_TAG_REBUILD_DO_REFS;
      if (doRemove)        rebuildFlags |= VS_TAG_REBUILD_REMOVE_MISSING_FILES;
      if (doRemove)        rebuildFlags |= VS_TAG_REBUILD_REMOVE_LEFTOVER_FILES;
      call_list("_LoadBackgroundTaggingSettings");

      // Rebuild the workspace tags and report that we are doing it.
      status := tag_build_workspace_tag_file(_workspace_filename, workspace_tag_file, rebuildFlags);
      if (status == 0) {
         alertId := _GetBuildingTagFileAlertGroupId(workspace_tag_file);
         _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, 'Updating workspace tag file (':+_strip_filename(workspace_tag_file,'p'):+')', '', 1);
      }
      if (def_tagging_logging) {
         loggingMessage := nls("Starting background tag file update for workspace tag file '%s1'", workspace_tag_file);
         dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      }

      // If they ONLY want to rebuild the workspace tag file, then stop here
      if (status == COMMAND_CANCELLED_RC || rebuildWorkspaceOnly) {
         return status;
      }

      // Otherwise, go through all the projects and see if any of them have
      // project-specific tag files that need to be rebuilt
      _str ProjectFilenames[];
      status = _GetWorkspaceFiles(_workspace_filename,ProjectFilenames);
      if (status) {
         return status;
      }
      for (i:=0;i<ProjectFilenames._length();++i) {
         // Get this project and check if it has a project-specific tag file
         absProjectFilename := _AbsoluteToWorkspace(ProjectFilenames[i]);
         if (!_ProjectFileExists(absProjectFilename)) continue;
         taggingOption := _ProjectGet_TaggingOption(_ProjectHandle(absProjectFilename));
         if (taggingOption == VPJ_TAGGINGOPTION_PROJECT || taggingOption == VPJ_TAGGINGOPTION_PROJECT_NOREFS) {
            // Rebuild the project tag file for this project
            project_tag_file := project_tags_filename_only(absProjectFilename);
            if (taggingOption == VPJ_TAGGINGOPTION_PROJECT_NOREFS) {
               rebuildFlags &= ~VS_TAG_REBUILD_DO_REFS;
            }
            status = tag_build_project_tag_file(_workspace_filename, absProjectFilename, project_tag_file, rebuildFlags);
            if (status == 0) {
               alertId := _GetBuildingTagFileAlertGroupId(project_tag_file);
               _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, 'Updating project tag file (':+_strip_filename(project_tag_file,'p'):+')', '', 1);
            }
            if (status == COMMAND_CANCELLED_RC) {
               break;
            }
            if (def_tagging_logging) {
               loggingMessage := nls("Starting background tag file update for project tag file '%s1'", project_tag_file);
               dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
            }
         }
      }

      // That's all for the threaded build case
      return status;
   }

   // Building synchronously, so set up hour glass 
   // and get all the project files in the current workspace
   mou_hour_glass(true);
   _str ProjectFilenames[];
   status := _GetWorkspaceFiles(_workspace_filename,ProjectFilenames);
   if (status) {
      mou_hour_glass(false);
      return status;
   }

   // Build a temp view with all the source files in all the projects
   // that are tagged as part of the workspace tag file
   temp_view_id := 0;
   orig_view_id := _create_temp_view(temp_view_id);
   for (i:=0; i<ProjectFilenames._length(); ++i) {
      absProjectFilename := _AbsoluteToWorkspace(ProjectFilenames[i]);
      if (!_ProjectFileExists(absProjectFilename)) continue;
      taggingOption := _projectGetTaggingOption(_workspace_filename, absProjectFilename);
      if (taggingOption != "" && taggingOption != VPJ_TAGGINGOPTION_WORKSPACE) continue;
      GetProjectFiles(absProjectFilename,temp_view_id,'',null,'',false,true);
   }

   // And then rebuild the workspace tag file
   status = retag_project_with_files_in_view(workspace_tag_file,
                                             temp_view_id,
                                             rebuild_all,
                                             rebuild_all,
                                             tag_occurrences,
                                             doRemove,
                                             RemoveWithoutPrompting,
                                             KeepWithoutPrompting,
                                             useThread,
                                             quiet,
                                             checkAllDates,
                                             allowCancel);

   // If they ONLY want to rebuild the workspace tag file, then stop here
   if (status < 0 || rebuildWorkspaceOnly) {
      clear_message();
      mou_hour_glass(false);
      return status;
   }

   // Now go through and rebuild all the projects 
   // and rebuild ones that have project-specific tag files
   for (i=0; i<ProjectFilenames._length(); ++i) {
      absProjectFilename := _AbsoluteToWorkspace(ProjectFilenames[i]);
      if (!_ProjectFileExists(absProjectFilename)) continue;
      taggingOption := _projectGetTaggingOption(_workspace_filename, ProjectFilenames[i]);
      if (taggingOption == VPJ_TAGGINGOPTION_PROJECT || taggingOption == VPJ_TAGGINGOPTION_PROJECT_NOREFS) {
         orig_view_id = _create_temp_view(temp_view_id);
         GetProjectFiles(absProjectFilename,temp_view_id,'',null,'',false,true);
         project_tag_file := project_tags_filename_only(ProjectFilenames[i]);
         if (taggingOption == VPJ_TAGGINGOPTION_PROJECT_NOREFS) {
            tag_occurrences = false;
         }
         status = retag_project_with_files_in_view(project_tag_file,
                                                   temp_view_id,
                                                   rebuild_all,
                                                   rebuild_all,
                                                   tag_occurrences,
                                                   doRemove,
                                                   RemoveWithoutPrompting,
                                                   KeepWithoutPrompting,
                                                   useThread,
                                                   quiet,
                                                   checkAllDates,
                                                   allowCancel);
         if (status < 0) break;
      }
   }

   // that's all folks
   clear_message();
   mou_hour_glass(false);
   return status;
}

//////////////////////////////////////////////////////////////////////////////
// Retag the files int the current 'primary' project tag file
//
int _project_update_files_retag(_str project_filename=_project_name,
                                bool rebuild_all=false,
                                bool doRemove=false,
                                bool RemoveWithoutPrompting=false,
                                bool quiet=false,
                                bool tag_occurrences=false,
                                bool checkAllDates=false,
                                bool useThread=false,
                                bool allowCancel=false,
                                bool KeepWithoutPrompting=false)
{
   // No tagging support?
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // Do nothing if there is no workspace open
   if (_workspace_filename=='') {
      return VSRC_NO_CURRENT_WORKSPACE;
   }
   if (project_filename=='') {
      return VSRC_NO_CURRENT_PROJECT;
   }

   // Check the tagging option for this project.
   // If the project is not supposed to be tagged, then do nothing
   taggingOption := _ProjectGet_TaggingOption(_ProjectHandle(project_filename));
   if (taggingOption == VPJ_TAGGINGOPTION_NONE) {
      return 0;
   }

   // Get the tag file.  This is either a project specific tag file
   // or the workspace tag file.
   project_tag_file := project_tags_filename_only(project_filename);

   // If they asked to rebuild everything, check if we can rebuild from scratch.
   // That is possible if the current project is the only project that is
   // tagged as part of the tag file we are building.
   force_create := rebuild_all;
   if (force_create && taggingOption != VPJ_TAGGINGOPTION_PROJECT && taggingOption != VPJ_TAGGINGOPTION_PROJECT_NOREFS) {
      _str ProjectFilenames[];
      _GetWorkspaceFiles(_workspace_filename,ProjectFilenames);
      for (i:=0; i<ProjectFilenames._length(); ++i) {
         absProjectFilename := _AbsoluteToWorkspace(ProjectFilenames[i]);
         if (_file_eq(ProjectFilenames[i], project_filename)) continue;
         if (_file_eq(absProjectFilename, project_filename)) continue;
         if (!_ProjectFileExists(absProjectFilename)) continue;
         projectTaggingOption := _projectGetTaggingOption(_workspace_filename, absProjectFilename);
         if (projectTaggingOption != "" && projectTaggingOption != VPJ_TAGGINGOPTION_WORKSPACE) continue;
         force_create=false;
         break;
      }
   }

   // If they want to do the tagging on a thread, start it that way.
   if (useThread && (RemoveWithoutPrompting || KeepWithoutPrompting)) {

      // set up tag file rebuild flags based on arguments
      rebuildFlags := 0;
      if (force_create)    rebuildFlags |= VS_TAG_REBUILD_FROM_SCRATCH;
      if (!rebuild_all)    rebuildFlags |= VS_TAG_REBUILD_CHECK_DATES;
      if (checkAllDates)   rebuildFlags |= VS_TAG_REBUILD_CHECK_DATES;
      if (tag_occurrences) rebuildFlags |= VS_TAG_REBUILD_DO_REFS;
      if (doRemove)        rebuildFlags |= VS_TAG_REBUILD_REMOVE_MISSING_FILES;
      if (doRemove)        rebuildFlags |= VS_TAG_REBUILD_REMOVE_LEFTOVER_FILES;
      call_list("_LoadBackgroundTaggingSettings");

      // Unless we are rebuilding from scratch, do not remove files from
      // the workspace tag file.
      if (!force_create && taggingOption != VPJ_TAGGINGOPTION_PROJECT && taggingOption != VPJ_TAGGINGOPTION_PROJECT_NOREFS) {
         rebuildFlags &= ~(VS_TAG_REBUILD_REMOVE_LEFTOVER_FILES);
         rebuildFlags &= ~(VS_TAG_REBUILD_REMOVE_MISSING_FILES);
      }

      // Rebuild the project tags and report that we are doing it.
      status := tag_build_project_tag_file(_workspace_filename, project_filename, project_tag_file, rebuildFlags);
      if (status == 0) {
         alertId := _GetBuildingTagFileAlertGroupId(project_tag_file);
         _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, 'Updating project tag file (':+_strip_filename(project_tag_file,'p'):+')', '', 1);
      }
      if (def_tagging_logging) {
         loggingMessage := nls("Starting background tag file update for project tag file '%s1'", project_tag_file);
         dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      }
      return status;
   }

   // Create a temp view and add all the files in the current project to it.
   mou_hour_glass(true);
   temp_view_id := 0;
   orig_view_id := _create_temp_view(temp_view_id);
   GetProjectFiles(_AbsoluteToWorkspace(project_filename),temp_view_id,'',null,'',false,true);

   // Unless we are rebuilding from scratch, do not remove files from
   // the workspace tag file.
   if (!force_create) {
      doRemove=false;
      RemoveWithoutPrompting=false;
      KeepWithoutPrompting=true;
   }

   // Retag the files in the temp view synchronously.
   // This function deletes the temp view when it finishes.
   status := retag_project_with_files_in_view(project_tag_file,
                                              temp_view_id,
                                              force_create,
                                              rebuild_all,
                                              tag_occurrences,
                                              doRemove,
                                              RemoveWithoutPrompting,
                                              KeepWithoutPrompting,
                                              useThread,
                                              quiet,
                                              checkAllDates,
                                              allowCancel);

   // that's all folks
   clear_message();
   mou_hour_glass(false);
   return status;
}

int TagRebuildAnyTagFile(_str TagFilename, _str langId="", int &bmp_index=0)
{
   // rebuild the database from scratch if it is out of date
   rebuild_all            := false;
   RemoveWithoutPrompting := false;
   KeepWithoutPrompting   := false;
   tag_occurrences        := false;
   isWorkspaceTagFile     := isWorkspaceTagFileName(TagFilename);
   isProjectTagFile       := isProjectTagFileName(TagFilename);
   status := tag_read_db(TagFilename);
   if (status < 0 || tag_current_version()<VS_TAG_LATEST_VERSION) {
      RemoveWithoutPrompting=true;
      KeepWithoutPrompting=true;
      if (isWorkspaceTagFile || isProjectTagFile) {
         tag_occurrences = (def_references_options & VSREF_NO_WORKSPACE_REFS) == 0;
      }
   }

   isAutoGeneratedTagFile := false;
   if (langId!="" && isTagFileAutoGenerated(TagFilename)) {
      isAutoGeneratedTagFile = true;
   }

   //say("ctlrebuild_tag_file.lbutton_up: status="status" flags="tag_get_db_flags()" file="tag_current_db());
   orig_db_flags := tag_get_db_flags();
   if (status >= 0 && (orig_db_flags & VS_DBFLAG_occurrences)) {
      tag_occurrences=true;
   }

   // If they select to retag all files, not just modified, force a rebuild
   useThread := true;
   if (!rebuild_all) {
      result := show('-modal _rebuild_tag_file_form',isAutoGeneratedTagFile,tag_occurrences,false,false,isWorkspaceTagFile||isProjectTagFile||isAutoGeneratedTagFile,useThread);
      if (result=="") {
         return(COMMAND_CANCELLED_RC);
      }
      rebuild_all            = !_param1;
      RemoveWithoutPrompting = _param2;
      tag_occurrences        = _param3;
      KeepWithoutPrompting   = true;
      useThread = useThread && (_param5 != 0);
   }

   // Instead of rebuilding Auto-Generated language tag files file-by-file,
   // try to use MaybeBuildTagFile() to re-generate the tag file from scratch.
   // This way we pick up any new files or file specifications.
   if (rebuild_all && isAutoGeneratedTagFile) {
      // Make a copy of the tag file, in case if it doesn't regenerate
      tag_close_db(TagFilename, false);
      copy_file(TagFilename,TagFilename".bak");
      delete_file(TagFilename);
      // Try to generate the tag file
      MaybeBuildTagFile(langId,tag_occurrences,useThread,forceRebuild:true);
      if (file_exists(TagFilename)) {
         // The tag file was re-built programmatically
         rebuild_all=false;
         delete_file(TagFilename".bak");
      } else {
         // The tag file was not re-built,
         // move the original back into place.
         tag_close_db(TagFilename, false);
         copy_file(TagFilename".bak",TagFilename);
         delete_file(TagFilename".bak");
      }
   }

   if (tag_occurrences && !(orig_db_flags & VS_DBFLAG_occurrences)) {
      rebuild_all=true;
      status=tag_open_db(TagFilename);
      if (status >= 0) {
         tag_set_db_flags(VS_DBFLAG_occurrences);
      }
      tag_read_db(TagFilename);

   } else if (!tag_occurrences && (orig_db_flags & VS_DBFLAG_occurrences)) {
      rebuild_all=true;
      status=tag_open_db(TagFilename);
      if (status >= 0) {
         tag_set_db_flags(orig_db_flags & ~(VS_DBFLAG_occurrences));
      }
      tag_read_db(TagFilename);
   }

   bmp_index = (tag_occurrences)? _pic_file_refs:_pic_file_tags;

   // if the current tag file is the primrary project file,
   // use techniques to stay in sync with project file
   // automatically rebuild it if it is corrupt
   database_flags := (tag_occurrences)? VS_DBFLAG_occurrences:0;
   if (isWorkspaceTagFile) {
      if (status==BT_INCORRECT_MAGIC_RC) {
         status = _OpenOrCreateTagFile(TagFilename, true, VS_DBTYPE_tags, database_flags);
         if (status >= 0) {
            status = tag_read_db(TagFilename);
         }
      }
      status = _workspace_update_files_retag(rebuild_all,
                                             doRemove:true, 
                                             RemoveWithoutPrompting,
                                             quiet:false, 
                                             tag_occurrences, 
                                             checkAllDates:false, 
                                             useThread, 
                                             allowCancel: !useThread, 
                                             KeepWithoutPrompting);
      if (status < 0) {
         _message_box("Error retagging workspace: "get_message(status, TagFilename));
      }
      toolbarUpdateWorkspaceList();
      return(0);
   }
   if (isProjectTagFile) {
      if (status==BT_INCORRECT_MAGIC_RC) {
         status = _OpenOrCreateTagFile(TagFilename, true, VS_DBTYPE_tags, database_flags);
         if (status >= 0) {
            status = tag_read_db(TagFilename);
         }
      }
      project_filename := project_tags_filename_to_project_file(TagFilename);
      status = _project_update_files_retag(project_filename,
                                           rebuild_all,
                                           doRemove:true, 
                                           RemoveWithoutPrompting,
                                           quiet:false, 
                                           tag_occurrences, 
                                           checkAllDates:false, 
                                           useThread, 
                                           allowCancel: !useThread, 
                                           KeepWithoutPrompting);
      if (status < 0) {
         _message_box("Error retagging project: "get_message(status, TagFilename));
      }
      toolbarUpdateWorkspaceList();
      return(0);
   }

   // ready to do some serious tagging, first get files from database
   mou_hour_glass(true);
   RetagFilesInTagFile(TagFilename, 
                       rebuild_all, tag_occurrences,
                       true, RemoveWithoutPrompting, useThread, 
                       false, false, false, KeepWithoutPrompting);

   // final cleanup and we are done
   clear_message();
   toolbarUpdateWorkspaceList();
   mou_hour_glass(false);
   return(0);
}

//////////////////////////////////////////////////////////////////////////////
// Handle pressing of 'rebuild tag file' button.  Prompt to ask if
// only modified files should be retagged, or all files.
//
int ctlrebuild_tag_file_btn.lbutton_up()
{
   // is a tag file selected?
   index := tree1._TreeCurIndex();
   if (tree1._TreeGetDepth(index)!=TAGFORM_FILE_DEPTH) return(0);
   orig_view_id:=0;
   get_window_id(orig_view_id);

   // get tag file name
   TagFilename := tree1.GetRealTagFilenameFromTree(index);

   // Is this a references file?
   typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
   typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
   parse TAG_FOLDER_INDEXES() with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;

   // Figure out the language mode for this tag file
   FolderIndex := tree1._TreeGetParentIndex(index);
   mode_name   := "";
   parse tree1._TreeGetCaption(FolderIndex) with '"'mode_name'"';
   langId := _Modename2LangId(mode_name);

   // rebuild the tag file using the generic function
   status := TagRebuildAnyTagFile(TagFilename, langId, auto bmp_index=0);
   if (status < 0) {
      return status;
   }

   // maybe change the bitmap for this item
   if (_iswindow_valid(orig_view_id)) {
      activate_window(orig_view_id);
      if (tree1._TreeIndexIsValid(index)) {
         if (bmp_index != 0) {
            tree1._TreeSetInfo(index,TREE_NODE_LEAF,bmp_index,bmp_index);
            tree1._TreeRefresh();
         }
         tree1.call_event(CHANGE_SELECTED,index,tree1,ON_CHANGE,'W');
      }
   }

   // final cleanup and we are done
   clear_message();
   toolbarUpdateWorkspaceList();
   return(0);
}

int RetagFilesInTagFile(_str tag_filename,
                        bool rebuild_all,
                        bool retag_occurrences,
                        bool doRemove=false,
                        bool RemoveWithoutPrompting=false,
                        bool useThread=false,
                        bool quiet=false,
                        bool checkAllDates=false,
                        bool allowCancel=false,
                        bool KeepWithoutPrompting=false
                        )
{
   // No tagging support?
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // if they want to rebuild the tag file using a thread, then do it
   // the new, super-fast way.  This creates a new thread which will
   // schedule all the files in the tag file to be rebuilt.
   if (useThread && (RemoveWithoutPrompting || KeepWithoutPrompting)) {
      rebuildFlags := 0;
      if (rebuild_all)       rebuildFlags |= VS_TAG_REBUILD_FROM_SCRATCH;
      if (checkAllDates)     rebuildFlags |= VS_TAG_REBUILD_CHECK_DATES;
      if (!rebuild_all)      rebuildFlags |= VS_TAG_REBUILD_CHECK_DATES;
      if (retag_occurrences) rebuildFlags |= VS_TAG_REBUILD_DO_REFS;
      if (doRemove)          rebuildFlags |= VS_TAG_REBUILD_REMOVE_MISSING_FILES;
      call_list("_LoadBackgroundTaggingSettings");
      status := tag_build_tag_file(tag_filename, rebuildFlags);
      if (status == 0) {
         alertId := _GetBuildingTagFileAlertGroupId(tag_filename);
         _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, "Updating: "tag_filename, '', 1);
         if (def_tagging_logging) {
            loggingMessage := nls("Starting background tag file update for '%s1'", tag_filename);
            dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
         }
      } else if (status < 0) {
         msg := get_message(status, tag_filename);
         notifyUserOfWarning(ALERT_TAGGING_ERROR, msg, tag_filename);
         if (def_tagging_logging) {
            loggingMessage := nls("Error starting background tag file update for '%s1': %s2", tag_filename, msg);
            dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
         }
      }
      return status;
   }

   //say('RetagFilesInTagFile');
   int list_view_id;
   _str orig_view_id = _create_temp_view(list_view_id);
   if (orig_view_id == '') {
      return (COMMAND_CANCELLED_RC);
   }

   // delegate to general purpose load-filename function above
   mou_hour_glass(false);
   LoadFileNameList(tag_filename,true);

   // rebuild the database
   int status=RetagFilesInTagFile2(tag_filename,
                                   (int)orig_view_id, list_view_id, 
                                   rebuild_all, rebuild_all, retag_occurrences,
                                   doRemove, RemoveWithoutPrompting,
                                   useThread, quiet, checkAllDates,
                                   true, allowCancel, false, KeepWithoutPrompting);
   return(status);
}

//////////////////////////////////////////////////////////////////////////////
// Handle pressing of 'retag source files' button.
//
int ctlretag_files_btn.lbutton_up()
{
   // find the selected tag file
   index := tree1._TreeCurIndex();
   if (tree1._TreeGetDepth(index)!=TAGFORM_FILE_DEPTH) return(0);
   _str TagFilename=tree1.GetRealTagFilenameFromTree(index);

   // nothing to do if there are no files to tag
   if (list1.p_Noflines <= 0) {
      _message_box("No files to retag");
      return(0);
   }

   // no files selected, ask if they want to retag everything
   status := 0;
   rebuild_all := false;
   if (list1.p_Nofselected == 0) {
      status=_message_box("No files selected.  Do you want to retag all files?",'',MB_YESNOCANCEL|MB_ICONQUESTION);
      if (status!=IDYES) {
         return(COMMAND_CANCELLED_RC);
      }
      list1._lbselect_all();
      rebuild_all=true;
   }

   // create a temporary view to hold names of files to be retagged
   mou_hour_glass(true);
   int list1_wid = list1.p_window_id;
   int list_view_id;
   int orig_view_id = _create_temp_view(list_view_id);
   if (orig_view_id == '') {
      return (COMMAND_CANCELLED_RC);
   }

   // transfer selected files to the temporary view
   p_window_id = list1_wid;
   noflines := p_Noflines;
   for (i:=1;i<=noflines;++i) {
      if ( _lbisline_selected_index(i) ) {
         _lbget_item_index(i,auto text,auto picIndex);
         list_view_id.insert_line(strip(text));
      }
   }
   p_window_id = list_view_id;

   // Check if the tag database requires tagging occurrences
   retag_occurrences := false;
   status = tag_read_db(TagFilename);
   if (status >= 0) {
      retag_occurrences = (tag_get_db_flags() & VS_DBFLAG_occurrences)? true:false;
   }

   // check if we should update the tag file in the background
   useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);

   // Retag all files that were inserted into the file list
   top(); up();
   RetagFilesInTagFile2(TagFilename, 
                        orig_view_id, list_view_id, 
                        false, false, retag_occurrences,
                        false, false, useThread,
                        useThread, true, true, 
                        false, false, true);

   // blow away the file list temp view
   clear_message();
   mou_hour_glass(false);
   return(0);
}

//////////////////////////////////////////////////////////////////////////////
// Get the wildcards for the given tag file
// The current object is the tag files form.
// Returns true if the current tag file is a references database.
//
bool _GetWildcardsForTagFile(bool getFromTree,_str &wildcards,_str &mode_name="")
{
   if (getFromTree) {
      wildcards = _default_c_wildcards();
      // Check if tree is selected, and chdir to directory containing tag file
      index := tree1._TreeCurIndex();
      if (tree1._TreeGetDepth(index)==TAGFORM_FILE_DEPTH) {
         index = tree1._TreeGetParentIndex(index);
      }
      typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
      typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
      parse TAG_FOLDER_INDEXES() with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;

      // get the mode name of the selected extension specific tag file
      mode_name='';
      while (extFilesIndexList != '') {
         typeless temp_index;
         parse extFilesIndexList with temp_index extFilesIndexList;
         if (temp_index!='' && index==temp_index) {
            // convert mode name to set of wildcards for extension
            parse tree1._TreeGetCaption(temp_index) with '"'mode_name'"';
            lang := _Modename2LangId(mode_name);
            wildcards = _GetWildcardsForLanguage(lang);
            break;
         }
      }
   }
   // Adjust the wild cards so the Add Files dialog gets initialized
   // properly.
   wildcards = addTypesToWildcards(wildcards);

   // retagging source files
   return false;
}

static _str addTypesToWildcards(_str wildcards)
{
   _str list=wildcards;
   for (;;) {
      _str wildcard;
      parse list with wildcard';' list;
      if (wildcard=="") {
         break;
      }

      // Check if this set of wildcards is in our def_file_types
      int i=pos('[(;]'_escape_re_chars(wildcard)'[);]',def_file_types,1,'r'_fpos_case);
      if (i) {
         // Set wildcards to this one.
         paren_i := lastpos('(',def_file_types,i);
         if (paren_i) {
            parse substr(def_file_types,paren_i) with '('wildcards')';
         }
         break;
      }

   }

   return wildcards;
}

//////////////////////////////////////////////////////////////////////////////
// Handle 'Add tree' button
//
void ctltree_btn.lbutton_up()
{
   // Check if tree is selected, and chdir to directory containing tag file
   index := tree1._TreeCurIndex();
   if (tree1._TreeGetDepth(index)!=TAGFORM_FILE_DEPTH) return;
   _str TagFilename=tree1.GetRealTagFilenameFromTree(index);

   // get modename, wildcards, and whether this is a references database
   _str mode_name, wildcards;
   _GetWildcardsForTagFile(true, wildcards,mode_name);

   // check if we should update the tag file in the background
   useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
   if (!_is_background_tagging_supported(_Modename2LangId(mode_name))) {
      useThread = false;
   } else if (_param1._varformat() == VF_LSTR && _param1 == "synchronous") {
      useThread = false;
   } else if (_param1._varformat() == VF_LSTR && _param1 == "threaded") {
      useThread = true;
   }

   // show the change directory form to select base to add tag files below
   TagDir := _strip_filename(TagFilename,'N');
   _str olddir=getcwd();
   chdir(TagDir,1);
   typeless orig_def_file_types=def_file_types;
   def_file_types=EXTRA_FILE_FILTERS:+',':+def_file_types;

   result := show('-modal _project_add_tree_or_wildcard_form',
                  'Add Tree',           // title
                  wildcards,            // filespec
                  (mode_name==''),      // attempt retrieval
                  true,                 // use excludes
                  '',                   // project name
                  false,               // show wildcard checkbox
                  true);               // Allow ant-like wildcards

   def_file_types=orig_def_file_types;
   chdir(olddir,1);
   if (result=='') {
      clear_message();
      return;
   }

   addFilesToTagFile(TagFilename, _param1, _param6, _param4, _param2, _param3, useThread);

   _param1._makeempty();
   _param4._makeempty();
   // update the list of files, that's all
   index=tree1._TreeCurIndex();
   if (index>=0) {
      tree1.call_event(CHANGE_SELECTED,index,tree1,ON_CHANGE,'W');
   }
}

static void addFilesToTagFile(_str TagFilename,_str basePath, _str (&includeList)[], _str (&excludeList)[], bool doRecurse, bool followSymlinks, bool useThread)
{
   mou_hour_glass(true);
   message('SlickEdit is finding all files in tree');

   recursive := doRecurse ? '+t' : '-t';
   OptimizeStats := followSymlinks ? '' : '+o';

   formwid := p_active_form;
   int filelist_view_id;
   int orig_view_id=_create_temp_view(filelist_view_id);
   p_window_id=filelist_view_id;

   all_files := _maybe_quote_filename(basePath);
   for (i := 0; i < includeList._length(); ++i) {
      strappend(all_files,' -wc '_maybe_quote_filename(includeList[i]));
   }

   for (i = 0; i < excludeList._length(); ++i) {
      strappend(all_files,' -exclude '_maybe_quote_filename(excludeList[i]));
   }

   // +W option supports multiple file specs but must specify switches
   // before files when you use this option.
   insert_file_list(recursive' 'OptimizeStats' +W -v +p -d 'all_files);
   p_line=0;

   // Add files to the current project file
   message('SlickEdit is building tags for new files');

   // delegate to the general purpose retagging proc
   p_window_id=filelist_view_id;
   p_line=0;
   status := RetagFilesInTagFile2(TagFilename,
                                  orig_view_id, filelist_view_id,
                                  false, false, false,
                                  false, false, useThread,
                                  false, false, false,
                                  true, false, true);
   activate_window((int)orig_view_id);
   _delete_temp_view(filelist_view_id);

   mou_hour_glass(false);
   clear_message();
}

//////////////////////////////////////////////////////////////////////////////
// handle resizing form, moving vertical divider between tag files
// on the left and source files on the left.
//
_divider.lbutton_down()
{
   _ul2_image_sizebar_handler(2*ctldone.p_width, list1.p_x_extent-2*ctldone.p_width);
}

//////////////////////////////////////////////////////////////////////////////
// Handle form resizing
//
_tag_form.on_resize()
{
   orig_list_x := list1.p_x;

   // calculate how much room we have to work with and with required for buttons
   form_width  := _dx2lx(SM_TWIP,p_active_form.p_client_width);
   form_height := _dy2ly(SM_TWIP,p_active_form.p_client_height);
   right_buttons_width := 2*ctldone.p_width + 120;
   left_buttons_width  := 2*ctldone.p_width + 120;
   max_divider_x := form_width - right_buttons_width;
   min_divider_x := left_buttons_width;

   // calculate location for divider control
   divider_x := _divider.p_x;
   if (p_active_form.p_visible) {
      if (divider_x > max_divider_x) divider_x = max_divider_x;
      if (divider_x < min_divider_x) divider_x = min_divider_x;
      if (divider_x != _divider.p_x) _divider.p_x = divider_x;
   }

   // make all the buttons invisible temporarily
   orig_ctldone_visible := ctldone.p_visible;
   ctldone.p_visible=ctltree_btn.p_visible=ctlremove_files_btn.p_visible=ctlfiles_btn.p_visible=false;
   ctlretag_files_btn.p_visible=ctloptions_btn.p_visible=ctlautotag_btn.p_visible=false;
   ctlnew_tag_file_btn.p_visible=ctlremove_tag_file_btn.p_visible=false;
   ctlrebuild_tag_file_btn.p_visible=ctldown_btn.p_visible=ctlup_btn.p_visible=false;

   // align the buttons to the tree control
   tree1.p_height = form_height - 2*tree1.p_y - 2*ctldone.p_height; 
   ctlup_btn.resizeToolButton(tree1.p_height intdiv 5 - PADDING_BETWEEN_CONTROL_BUTTONS);
   _divider.p_width = ctlup_btn.p_width;
   alignUpDownListButtons(tree1.p_window_id, 
                          _divider.p_x_extent + 30,
                          ctlnew_tag_file_btn.p_window_id, 
                          ctlrebuild_tag_file_btn.p_window_id, 
                          ctlup_btn.p_window_id, 
                          ctldown_btn.p_window_id, 
                          ctlremove_tag_file_btn.p_window_id, 
                          ctlautotag_btn.p_window_id);

   alignUpDownListButtons(list1.p_window_id, 
                          form_width - 60,
                          ctlfiles_btn.p_window_id, 
                          ctltree_btn.p_window_id, 
                          ctlretag_files_btn.p_window_id, 
                          ctlremove_files_btn.p_window_id, 
                          ctlblank_btn.p_window_id, 
                          ctloptions_btn.p_window_id);

   // adjust everything that depends on the divider location
   list1.p_x=_divider.p_x_extent+75;
   delta_x := (list1.p_x - orig_list_x);
   ctl_files_label.p_x += delta_x;
   ctl_files_gauge.p_x += delta_x;
   ctl_files_gauge.p_x_extent = list1.p_x_extent - tree1.p_x; 

   // adjust the tree height
   done_button_height := orig_ctldone_visible? ctldone.p_height+120 : 0;
   tree_height := form_height - tree1.p_y - done_button_height - 120;
   tree1.p_height    = tree_height;
   list1.p_height    = tree_height;

   // adjust the divider position
   _divider.p_y = ctlautotag_btn.p_y_extent + 15;
   _divider.p_height = tree1.p_y_extent - _divider.p_y;
   _divider.p_width  = ctlup_btn.p_width;

   // calculate the location for the "Done" button
   ctldone.p_x = ctl_tagfiles_label.p_x;
   ctldone.p_y = tree1.p_y_extent + 120;

   // now make the buttons visible again
   ctltree_btn.p_visible=ctlremove_files_btn.p_visible=ctlfiles_btn.p_visible=true;
   ctlretag_files_btn.p_visible=ctloptions_btn.p_visible=ctlautotag_btn.p_visible=true;
   ctlnew_tag_file_btn.p_visible=ctlremove_tag_file_btn.p_visible=true;
   ctlrebuild_tag_file_btn.p_visible=ctldown_btn.p_visible=ctlup_btn.p_visible=true;
   ctldone.p_visible = orig_ctldone_visible;
}

//////////////////////////////////////////////////////////////////////////////
// get the list of tag files under the given folder
//
static _str GetFolderFileList(int ParentIndex, bool lookForCheck)
{
   index := tree1._TreeGetFirstChildIndex(ParentIndex);
   str := "";
   for (;;) {
      if (index<0) break;
      if (!lookForCheck || tree1._TreeGetCheckState(index) == TCB_CHECKED) {
         filename := tree1._TreeGetCaption(index);
         parse filename with filename ' (' auto rest ')';
         if (str=="") {
            str = filename;
         } else {
            str :+= PATHSEP:+filename;
         }
      }
      index=tree1._TreeGetNextSiblingIndex(index);
   }
   return(str);
}

//////////////////////////////////////////////////////////////////////////////
// Store the tag file lists in their respective places for global, project,
// extension specific, and project references tag files.
//
static void SetTagFiles(int index=-1)
{
   typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
   typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
   parse TAG_FOLDER_INDEXES() with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;
   if (index<0) {
      //SetProjectTags();
      for (;;) {
         typeless temp_index;
         parse extFilesIndexList with temp_index extFilesIndexList;
         if (temp_index=='') {
            break;
         }
         SetLanguageTagFiles(temp_index);
      }
   } else if(index==ProjectTagfilesIndex){
      //SetProjectTags();
   } else if(index == autoUpdateFilesIndex) {
      SetAutoUpdateTagFiles(index);
   } else if (index == cppCompilerTagFilesIndex || index == javaCompilerTagFilesIndex) {
      // do nothing for compiler configurations
   } else {
      SetLanguageTagFiles(index);
   }
}

static void SetTagFilesOrSetModified(int index=-1, _str TagFilename="", _str CallbackOption="")
{
   langId := TAGFORM_LANGUAGE_ID();
   if (langId != null && (langId != "" && langId != WORKSPACE_LANG_ID)) {
      TAGFORM_IS_MODIFIED(true);
   } else {
      SetTagFiles(index);
      _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX, TagFilename, CallbackOption);
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Store the list of extension specific tag files for the given folder
//
static void SetLanguageTagFiles(int index)
{
   TAGFORM_SKIP_ON_CHANGE(1);
   list_all := GetFolderFileList(index, false);
   list_set := GetFolderFileList(index, true);
   mode_name := "";
   parse tree1._TreeGetCaption(index) with '"'mode_name'"';
   lang := _Modename2LangId(mode_name);
   LanguageSettings.setTagFileList(lang, list_set);
   LanguageSettings.setTagFileListAll(lang, list_all);
   TAGFORM_SKIP_ON_CHANGE(0);
}

#if 0
//////////////////////////////////////////////////////////////////////////////
// Store the project tag files list
//
static int SetProjectTags()
{
   if (_project_name=='') return(0);
   parse TAG_FOLDER_INDEXES() with ProjectTagfilesIndex autoUpdateFilesIndex compilerTagFilesIndex extFilesIndexList;
   list=GetFolderFileList(ProjectTagfilesIndex);
   status=_ini_set_value(_project_name,"COMPILER",'tagfiles',list);
   if (status) {
      _message_box(nls("Could not set project tag file list\n%s",get_message(status)));
   }
   return(status);
}
#endif

/**
 * Store the auto update tag files list
 */
static void SetAutoUpdateTagFiles(int index)
{
   // safety net
   if(_workspace_filename == "") {
      return;
   }

   // delete the current list
   _WorkspaceRemove_TagFiles(gWorkspaceHandle);

   childIndex := tree1._TreeGetFirstChildIndex(index);
   for(;;) {
      if(childIndex < 0) break;
      // get local and remote filenames
      _str local = tree1._TreeGetUserInfo(childIndex);
      remote := tree1._TreeGetCaption(childIndex);
      local = relative(local, VSEWorkspaceTagFileDir());

      // remove description from remote
      _str junk;
      parse remote with remote " (" junk ")";

      // add to workspace
      _WorkspaceSet_TagFile(gWorkspaceHandle, local, remote);

      // move next child
      childIndex = tree1._TreeGetNextSiblingIndex(childIndex);
   }

   // save the workspace
   _WorkspaceSave(gWorkspaceHandle);
}

//////////////////////////////////////////////////////////////////////////////
// Handle the 'remove tag file' button press.
//
void ctlremove_tag_file_btn.lbutton_up()
{
   typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
   typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
   parse TAG_FOLDER_INDEXES() with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;

   // check that a tag file is selected
   index := tree1._TreeCurIndex();
   depth := tree1._TreeGetDepth(index);
   if (depth!=TAGFORM_FILE_DEPTH) return;
   FolderIndex := tree1._TreeGetParentIndex(index);
   TagFilename := tree1.GetRealTagFilenameFromTree(index);
   mode_name   := "";
   parse tree1._TreeGetCaption(FolderIndex) with '"'mode_name'"';
   lang := _Modename2LangId(mode_name);

   doDelete := true;
   promptToDelete := true;
   autoGenWarning := "";
   if (FolderIndex == autoUpdateFilesIndex) {
      promptToDelete = false;
      doDelete = true;
   } else if (!file_exists(TagFilename)) {
      promptToDelete = false;
      doDelete = false;
   } else if (FolderIndex == ProjectTagfilesIndex) {
      promptToDelete = true;
   } else if (FolderIndex == cppCompilerTagFilesIndex || FolderIndex == javaCompilerTagFilesIndex) {
      promptToDelete = false;
      doDelete = true;
      autoGenWarning = "\n\nNote:  This tag file will be regenerated when you work with a project that uses this compiler configuration.";
   } else if (isTagFileAutoGenerated(TagFilename)) {
      promptToDelete = false;
      doDelete = true;
      autoGenWarning = "\n\nNote:  This tag file will be regenerated when you work with "mode_name" source files.";
   } else {
      promptToDelete = true;
   }

   orig_wid := p_window_id;
   result := checkBoxDialog('Remove Tag File', 
                            nls("Do you wish to remove the file %s from your tag file list?%s", _strip_filename(TagFilename,'P'), autoGenWarning), 
                            promptToDelete ? "Delete file from disk" : "", MB_YESNO, 0, 'deleteTagFile');
   p_window_id = orig_wid;
   if (promptToDelete) {
      doDelete = _param1;
   }

   if (result==IDYES) {
      // Yes this must be tag_close_db and not tag_close_db2
      tag_close_db(TagFilename);
   } else {
      return;
   }

   if (doDelete) {
      // make sure it is not read only
      if (_isUnix()) {
         chmod("\"u+w g+w o+w\" " _maybe_quote_filename(TagFilename));
      } else {
         chmod("-r " _maybe_quote_filename(TagFilename));
      }

      int status=recycle_file(TagFilename);
      if (status && status!=FILE_NOT_FOUND_RC) {
         _message_box(nls("Could not delete file %s",TagFilename));
      }
      // Tell Eclipse that we removed a tagfile
      if (isEclipsePlugin()) {
         proj := "";
         _eclipse_get_active_project_name(proj);
         if (proj != "") {
            _eclipse_update_tag_list(proj);
         }
      }
   }

   // remove the file from the tree and update the file list
   tree1._TreeDelete(index);
   SetTagFilesOrSetModified(FolderIndex, TagFilename, 'R');

   // if there are no more tag files listed for this language, 
   // then just select the language node
   if (tree1._TreeGetNumChildren(FolderIndex) == 0) {
      tree1._TreeSetCurIndex(FolderIndex);
   }

   // make sure the right node is selected
   index=tree1._TreeCurIndex();
   if (index>=0) {
      tree1.call_event(CHANGE_SELECTED,index,tree1,ON_CHANGE,'W');
   }
}

//////////////////////////////////////////////////////////////////////////////
// Remove selected files from the list for tags files
//
int tag_remove_filelist(_str TagFilename,_str FileList,bool CacheProjects_TagFileAlreadyOpen=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!CacheProjects_TagFileAlreadyOpen) {
      mou_hour_glass(true);
   }
   int status=tag_open_db(TagFilename);
   if (status < 0) {
      _message_box(nls("Unable to open tag file %s",TagFilename));

      // Could get tag file not found here
      // Lets continue any way

      //mou_hour_glass(false);
      //return(status);
   }
   if (!status) {
      _str list=FileList;
      for (;;) {
         _str dqfilename=parse_file(list);
         if (dqfilename=='') {
            break;
         }
         filename := strip(dqfilename,'B','"');
         message('Removing 'filename' from 'TagFilename);
         status = tag_remove_from_file(filename);
      }
      _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      tag_close_db('',true);
   }
   //tag_flush_db();
   clear_message();
   if (!CacheProjects_TagFileAlreadyOpen) {
      mou_hour_glass(false);
   }
   return(0);
}

//////////////////////////////////////////////////////////////////////////////
// Remove selected files from the current tag file
//
void ctlremove_files_btn.lbutton_up()
{
   // get the current tag filename from the tree
   orig_wid := p_window_id;
   index := tree1._TreeCurIndex();
   depth := tree1._TreeGetDepth(index);
   if (depth!=TAGFORM_FILE_DEPTH) return;
   TagFilename := tree1.GetRealTagFilenameFromTree(tree1._TreeCurIndex());
   if (!list1.p_Nofselected) return;

   // we can't remove files from a .bsc file
   if ('.':+lowcase(_get_extension(TagFilename)) :== BSC_FILE_EXT) {
      _beep();
      return;
   }

   // make sure they didn't press button by accident
   // determine if we should do this in the background or not
   result := textBoxDialog("Remove Files from Tag File",
                           0,                // Flags
                           0,                // Use default textbox width
                           "",               // Help item
                           "Remove Files,Cancel:_cancel\t":+
                           nls("Are you sure you wish to remove the selected files from '%s'?",_strip_filename(TagFilename, 'P')),
                           "",               // Retrieve Name
                           "-CHECKBOX Remove files in the the background:0");
   if (result==COMMAND_CANCELLED_RC) return;
   useThread := (_param1 != 0);

   // make sure that we can write to the tags database
   status := 0;
   if (useThread) {
      status = tag_read_db(TagFilename);
   } else {
      status = tag_open_db(TagFilename);
   }
   if (status < 0) {
      // Could get tag file not found here, warn, but don't return yet
      _message_box(nls("Unable to open tag file %s",TagFilename));
      return;
   }

   // construct the list of files to remove 
   _str LBFiles[];
   int list1_wid = list1.p_window_id;
   orig_limit := _default_option(VSOPTION_WARNING_ARRAY_SIZE);
   new_limit := list1_wid.p_Noflines+5;
   if (new_limit<orig_limit) new_limit=orig_limit;
   _default_option(VSOPTION_WARNING_ARRAY_SIZE,new_limit);

   status = list1_wid._lbfind_selected(true);
   while (!status) {
      filename := strip(list1_wid._lbget_text());
      LBFiles[LBFiles._length()]=filename;
      status=list1_wid._lbfind_selected(false);
   }

   //  report the progress removing the files from the tag file
   rebuildFlags := 0;
   if (useThread) {
      message('Removing 'LBFiles._length()' files from "'TagFilename'" in background');
   } else {
      message('Removing 'LBFiles._length()' files from "'TagFilename'"');
      // open the tag database for read-write
      rebuildFlags = VS_TAG_REBUILD_SYNCHRONOUS;
      mou_hour_glass(true);
   }

   // call generic function to remove the files
   tag_remove_files_from_tag_file_in_array(TagFilename, rebuildFlags, LBFiles);
   if (def_tagging_logging) {
      loggingMessage := nls("Removing %s2 files from tag file '%s1'", TagFilename, LBFiles._length());
      dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
   }

   // if the work was done in the foreground, we can report results immediately.
   tag_close_db(TagFilename,true);
   p_window_id=orig_wid;
   if (!useThread) { 
      // trigger callback to update the tree control
      index=tree1._TreeCurIndex();
      if (index>=0) {
         tree1.call_event(CHANGE_SELECTED,index,tree1,ON_CHANGE,'W');
      }
      // close the database and fire off refresh events
      _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      mou_hour_glass(false);
      clear_message();
   }

   // reset the array size warning 
   _default_option(VSOPTION_WARNING_ARRAY_SIZE,orig_limit);

   // that's all, we are done
   return;
}

//////////////////////////////////////////////////////////////////////////////
// Clean-up when form is destroyed
//
ctldone.on_destroy()
{
   //Refresh the background tag window if it is there
   wid := _find_formobj('_tag_window_form','N');
   if (wid) {
      _nocheck _control ctltagname;
      wid.ctltagname.call_event(CHANGE_OTHER,wid.ctltagname,ON_CHANGE,"W");
   }

   // check any auto-updated tagfiles in this workspace
   check_autoupdated_tagfiles();

   // save the position of the vertical divider bar
   _moncfg_append_retrieve(0,_divider.p_x,"_tag_form._divider.p_x");
}

//////////////////////////////////////////////////////////////////////////////
// Returns tree index if it exists, otherwise returns -1
//    Item        -- caption of item to search for
//    ParentIndex -- index to search under
//    Options     -- -F means match Item using _fpos_case
//
static int ItemInTree(_str Item,int ParentIndex,_str Options='')
{
   index := tree1._TreeGetFirstChildIndex(ParentIndex);
   str := "";
   FileOption := false;
   for (;;) {
      _str CurOp=parse_file(Options);
      if (CurOp=='') break;
      if (upcase(CurOp)=='-F') {
         FileOption=true;
      }
   }
   for (;;) {
      if (index<0) break;
      CurItem := tree1._TreeGetCaption(index);
      rest := "";
      parse CurItem with CurItem ' (' rest ')';
      if (FileOption) {
         if (_file_eq(Item,CurItem)) return(index);
      }else{
         if (Item==CurItem) return(index);
      }
      index=tree1._TreeGetNextSiblingIndex(index);
   }
   return(-1);
}

//////////////////////////////////////////////////////////////////////////////
// Create a new tag file
//
void ctlnew_tag_file_btn.lbutton_up()
{
   // get list of indexes
   typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
   typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
   parse TAG_FOLDER_INDEXES() with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;

   // figure out which folder we are dealing with, and therefore what kind
   // of tag file (project, auto-update, language)
   langId := TAGFORM_LANGUAGE_ID();
   FolderIndex := -1;
   categoryLetter := 'E';
   depth := -1;
   origindex := tree1._TreeCurIndex();
   if (origindex >= 0) {
      // use the depth to figure out whether this is a tag file or category
      depth = tree1._TreeGetDepth(origindex);
      if (depth == TAGFORM_FILE_DEPTH) {
         // file, get the parent category
         FolderIndex = tree1._TreeGetParentIndex(origindex);
      }else{
         // we have the category itself
         FolderIndex = origindex;
      }

      // which folder is this?
      if (FolderIndex == ProjectTagfilesIndex) {
         categoryLetter = 'P';
      } else if (FolderIndex == autoUpdateFilesIndex) {
         categoryLetter = 'A';
      } else {
         categoryLetter = 'E';
      }
   }

   // get a mode name for the new tag file (user can pick whatever
   // they want, but it's nice to push them in the direction that
   // they probably want)
   mode_name := "";
   if (FolderIndex > 0) {
      list := extFilesIndexList;
      typeless temp_index;
      while (true) {
         // go through each index in the list
         parse list with temp_index list;
         if (temp_index == '') break;

         if (FolderIndex == temp_index) {
            parse tree1._TreeGetCaption(temp_index) with '"'mode_name'"';
            break;
         }
      }

      // we didn't find a match, so check the obvious ones
      if (mode_name == '') {
         if (FolderIndex == cppCompilerTagFilesIndex) {
            parse tree1._TreeGetCaption(FolderIndex) with '"'mode_name'"';
            if (mode_name == "C") mode_name="C/C++";
         }
         if (FolderIndex == javaCompilerTagFilesIndex) {
            parse tree1._TreeGetCaption(FolderIndex) with '"'mode_name'"';
         }
      }
   }

   forceLanguageMode := false;
   if (langId != null && langId != "") {
      forceLanguageMode = true;
      mode_name = _LangId2Modename(langId);
   }

   // skip the dialog for auto-update tag files

   tagFile := '';
   tag_occurrences := false;
   useThread := true;
   createNew := false;
   rebuildTagFile := false;
   if(categoryLetter != 'A') {
      result := show('-modal _add_tag_file_form', mode_name, forceLanguageMode);

      // cancel
      if (result==IDCANCEL) return;

      // we treat everything as 'E', which is language (Extension) tag files
      categoryLetter = 'E';

      // _param1 - language
      // _param2 - generate references
      // _param3 - use background tagging
      // _param4 - create new file
      // _param5 - tag file path
      if (!forceLanguageMode) {
         mode_name = _param1;
      }
      tag_occurrences = _param2;
      useThread = _param3;
      createNew = _param4;
      tagFile = strip(_param5, 'B', '"');

      if (!createNew) {
         rebuildTagFile = _param6;
      }
   } else {
      workspaceDir := _strip_filename(_workspace_filename,'N');
      tagFile = pickTagFileToAdd(createNew, workspaceDir);
      if (tagFile == '') return;

      createNew = !file_exists(tagFile);
   }

   addNewExtensionCategory := '';
   switch (categoryLetter) {
   case 'P':    // Project
      FolderIndex = origindex = ProjectTagfilesIndex;
      depth = TAGFORM_FOLDER_DEPTH;
      break;
   case 'A':
      FolderIndex = origindex = autoUpdateFilesIndex;
      depth = TAGFORM_FOLDER_DEPTH;
      break;
   default:   // Extension specific tag files
      // figure our where we are going to put this one
      list := extFilesIndexList;
      typeless temp_index;
      while (true) {
         // go through the extension index list
         parse list with temp_index list;
         // we ran out, so we have to add a new category
         if (temp_index == '') {
            // Insert new category...later
            addNewExtensionCategory = mode_name;
            depth = TAGFORM_FOLDER_DEPTH;
            break;
         }

         // see if this matches
         parse tree1._TreeGetCaption(temp_index) with '"' auto caption_mode_name '"';
         if (_ModenameEQ(mode_name, caption_mode_name)) {
            FolderIndex = origindex = temp_index;
            depth = TAGFORM_FOLDER_DEPTH;
            break;
         }
      }
   }

   tag_file_type := VS_DBTYPE_tags;
   TagFilename := "";
   NewTagFilename := "";

   // if this is an auto updated tag file, remember the remote name for later use
   autoUpdatedTagfile := "";
   localAutoUpdatedCopy := "";
   if (FolderIndex > 0 && FolderIndex == autoUpdateFilesIndex) {
      // get the proper local tag filename
      autoUpdatedTagfile = tagFile;

      // make sure the local copy doesnt collide with any existing tag files
      // NOTE: it isnt safe to just check the list in this workspace because multiple
      //       workspaces may share the same directory.  the safest way is to check
      //       to see if a file by that name exists.
      localAutoUpdatedCopy = _AbsoluteToWorkspace(_strip_filename(tagFile, "P"), _workspace_filename);
      localAutoUpdatedCopyBase := _strip_filename(localAutoUpdatedCopy, "E");

      unique := 2;
      for(;; unique++) {
         if(!file_exists(localAutoUpdatedCopy)) {
            break;
         }
         localAutoUpdatedCopy = localAutoUpdatedCopyBase "-" unique :+ TAG_FILE_EXT;
      }

      tagFile = localAutoUpdatedCopy;
   }

   TagFilename=tagFile;
   TagFilename=strip(TagFilename,'B','"');

   // if tag file is existing file:
   //    _param6 - rebuild tag files
   // if tag file is a new file:
   //    _param6 - base path
   //    _param7 - recursive
   //    _param8 - follow symlinks
   //    _param9 - exclude filespecs
   //    _param10 - include filespecs

   // see if this file is already in the tree
   int index=ItemInTree(TagFilename, FolderIndex, '-F');
   if (index < 0) {
      // does this file already exist?
      if (!createNew && file_exists(TagFilename)) {
         //File exists already
         if (_file_eq(_get_extension(TagFilename),'slk')) {
            //The user added an old tag file
            NewTagFilename=_strip_filename(TagFilename,'E'):+TAG_FILE_EXT;
            if (file_exists(NewTagFilename)) {
               //A new tag file by this name exists already.
               result:=_message_box(nls("%s is an old SlickEdit tag file.\nWould you like to add the new SlickEdit tag file %s instead?",TagFilename,NewTagFilename),'',MB_YESNOCANCEL|MB_ICONQUESTION);
               if (result==IDCANCEL||result==IDNO) return;
               if (result==IDYES) {
                  TagFilename = NewTagFilename;
               }
            }
            status:=RebuildOldTagFile(TagFilename,NewTagFilename,false,tag_occurrences,useThread);
            if (status) {
               _message_box(nls("Could not rebuild old tag file %s.\n%s",TagFilename,get_message(status)));
               return;
            }
            TagFilename = NewTagFilename;
         } else {
            // tag file exists and is in the new format
            status:=tag_open_db(TagFilename);
            if (status >= 0) {
               // if we want to generate references and we didn't before, we need to rebuild this thing
               if (rebuildTagFile || tag_occurrences && !(tag_get_db_flags() & VS_DBFLAG_occurrences)) {
                  tag_set_db_flags(VS_DBFLAG_occurrences);
                  status=RetagFilesInTagFile(TagFilename,true,true,false,false,useThread);
               }
            }
            tag_close_db(TagFilename,true);
         }
      } else {
         // new file!
         if (FolderIndex > 0 && FolderIndex == autoUpdateFilesIndex) {
            // Create the auto-updated tag file now if it doesn't already exist
            if (!file_exists(autoUpdatedTagfile)) {
               // doesn't exist, we should get out of here
               int create_file_response = _message_box(nls("Tag file '%s' does not exist.\nCreate it now?",autoUpdatedTagfile),"SLICKEDIT",MB_OKCANCEL|MB_ICONQUESTION);
               if (create_file_response==IDCANCEL) {
                  return;
               }
               tag_create_db(autoUpdatedTagfile, tag_file_type);
               if (tag_occurrences) {
                  tag_set_db_flags(VS_DBFLAG_occurrences);
               }
               tag_close_db(autoUpdatedTagfile);
            }
            // now copy the auto-updated tag file to the local tag file
            message("Copying remote tag file...");
            mou_hour_glass(true);
            status := _updateAutoUpdatedTagfile(TagFilename, autoUpdatedTagfile);
            if (status < 0) {
               return;
            }
            mou_set_pointer(0);
            clear_message();
         } else {
            tag_create_db(TagFilename, tag_file_type);
            if (tag_occurrences) {
               tag_set_db_flags(VS_DBFLAG_occurrences);
            }
            tag_close_db(TagFilename,true);

            if (_param6 != '') {
               //    _param6 - base path
               //    _param7 - recursive
               //    _param8 - follow symlinks
               //    _param9 - exclude filespecs
               //    _param10 - include filespecs
               addFilesToTagFile(TagFilename, _param6, _param10, _param9, _param7, _param8, useThread);
            }
         }
      }

      // Add the tag file to the tree under the appropriate extension
      flags := 0;
      if (depth==TAGFORM_FOLDER_DEPTH) {
         //There are no children
         flags=TREE_ADD_AS_CHILD;
      }
      has_occurrences := (tag_get_db_flags() & VS_DBFLAG_occurrences);
      bmp_index := (has_occurrences)? _pic_file_refs:_pic_file_tags;

      tag_read_db(TagFilename);
      comment := tag_get_db_comment();
      tag_close_db(TagFilename);

      // restore the remote filename if it is an auto updated tagfile
      if(FolderIndex>0 && FolderIndex == autoUpdateFilesIndex) {
         TagFilename = autoUpdatedTagfile;
      }

      allcaption := (comment=='')? TagFilename:TagFilename' ('comment')';

      // need to add a folder for this extension
      if (addNewExtensionCategory != '') {
         FilesIndex := tree1._TreeAddItem(TREE_ROOT_INDEX,     //Relative Index
                                          '"'addNewExtensionCategory'" ':+LANGUAGE_CONFIG_FOLDER_NAME,//Caption
                                          TREE_ADD_AS_CHILD,   //Flags
                                          _pic_fldclos,        //Collapsed Bitmap Index
                                          _pic_fldopen,        //Expanded Bitmap Index
                                          TREE_NODE_LEAF);     //Initial State
         TAG_FOLDER_INDEXES(TAG_FOLDER_INDEXES()' 'FilesIndex);
         FolderIndex=origindex=FilesIndex;
      }

      index=tree1._TreeAddItem(origindex,                      //Relative Index
                               allcaption,                     //Caption
                               flags,                          //Flags
                               bmp_index,                      //Collapsed Bitmap Index
                               bmp_index,                      //Expanded Bitmap Index
                               TREE_NODE_LEAF);                //Initial State
      parentindex := tree1._TreeGetParentIndex(index);
      tree1._TreeSetInfo(parentindex,TREE_NODE_EXPANDED);
      if (FolderIndex != ProjectTagfilesIndex && FolderIndex != autoUpdateFilesIndex) {
         tree1._TreeSetCheckable(index, 1, 0, TCB_CHECKED);
      }

      // if this is an auto-updated tagfile, store the absolute local
      // path in the user info for the tree node
      if (FolderIndex>0 && FolderIndex == autoUpdateFilesIndex) {
         tree1._TreeSetUserInfo(index, localAutoUpdatedCopy);
      }

      // save the new tag file to the list
      SetTagFiles(origindex);

   } else {
      // This language already has the given tag file, but if it doesn't exist
      // on disk, we are free to build it now.  If not, we should ask if they
      // want to overwrite the existing file?
      if (file_exists(TagFilename)) {
         // file already exists, try to overwrite it?
         int create_file_response = _message_box(nls("Tag file '%s' already exists.\nOverwrite it now?",TagFilename),"SLICKEDIT",MB_OKCANCEL|MB_ICONQUESTION);
         if (create_file_response==IDCANCEL) {
            return;
         }
         delete_file(TagFilename);
      }

      tag_create_db(TagFilename, tag_file_type);
      if (tag_occurrences) {
         tag_set_db_flags(VS_DBFLAG_occurrences);
      }
      tag_close_db(TagFilename,true);

      if (_param6 != '') {
         //    _param6 - base path
         //    _param7 - recursive
         //    _param8 - follow symlinks
         //    _param9 - exclude filespecs
         //    _param10 - include filespecs
         addFilesToTagFile(TagFilename, _param6, _param10, _param9, _param7, _param8, useThread);
      }

      // update index for the tag file if it was already in the tree
      bmp_index := (tag_occurrences)? _pic_file_refs:_pic_file_tags;
      if (index > 0) {
         tree1._TreeSetInfo(index, TREE_NODE_LEAF, bmp_index, bmp_index);
      }
   }

   // select the tag file
   if (index > 0) {
      tree1._TreeSetCurIndex(index);
   }

   TAGFORM_IS_MODIFIED(true);
   SetTagFilesOrSetModified(FolderIndex, TagFilename, 'A');

   // Tell Eclipse that we removed a tagfile
   if (isEclipsePlugin()) {
      proj := "";
      _eclipse_get_active_project_name(proj);
      if (proj != "") {
         _eclipse_update_tag_list(proj);
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// translate 'DEL' key to pressing remove tag file button
//
tree1.del()
{
   if (ctlremove_tag_file_btn.p_enabled) {
      ctlremove_tag_file_btn.call_event(ctlremove_tag_file_btn,LBUTTON_UP);
   }
}

//////////////////////////////////////////////////////////////////////////////
// translate 'DEL' key to pressing remove source file button
//
list1.del()
{
   if (ctlremove_files_btn.p_enabled) {
      ctlremove_files_btn.call_event(ctlremove_files_btn,LBUTTON_UP);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Toggle building symbol cross-reference in this tag file
//
static ToggleGenerateReferences()
{
   wid := p_window_id;
   p_window_id=tree1;
   tree_wid := p_window_id;
   index := _TreeCurIndex();
   OrigFilename := _TreeGetCaption(index);
   rest := "";
   parse OrigFilename with OrigFilename ' (' rest ')';
   int db_flags = tag_get_db_flags();
   bmp_index := 0;
   if (db_flags & VS_DBFLAG_occurrences) {
      db_flags &= ~VS_DBFLAG_occurrences;
      tag_set_db_flags(db_flags);
      _TreeSetInfo(index,TREE_NODE_LEAF,_pic_file_tags,_pic_file_tags);
   } else {
      useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
      RetagFilesInTagFile(OrigFilename,true,true,
                          false,false,useThread,
                          useThread,false,false,true);
      p_window_id=tree_wid;
      _TreeSetInfo(index,TREE_NODE_LEAF,_pic_file_refs,_pic_file_refs);
   }
   _TreeRefresh();
   call_event(CHANGE_SELECTED,index,p_window_id,ON_CHANGE,'W');
   p_window_id=wid;
}

static void UpdateTagFilesForLanguages(_str forLangId="")
{
   // add all the TagFiles stored in LanguageSettings
   _str langTagFilesTable:[];
   LanguageSettings.getTagFileListAllTable(langTagFilesTable);
   foreach (auto langId => auto langTagFileList in langTagFilesTable) {

      // This is not the language we were looking for
      if (forLangId != "" && langId != forLangId) {
         continue;
      }

      langTagFileList     = LanguageSettings.getTagFileList(langId);
      langTagFileListAll := LanguageSettings.getTagFileListAll(langId);
      mode_name := _LangGetModeName(langId);
      langSectionIndex  := tree1._TreeSearch(TREE_ROOT_INDEX,'"'mode_name'" ':+LANGUAGE_CONFIG_FOLDER_NAME);
      langCompilerIndex := tree1._TreeSearch(TREE_ROOT_INDEX,'"'mode_name'" ':+COMPILER_CONFIG_FOLDER_NAME);
      useThread := !(def_autotag_flags2 & AUTOTAG_LANGUAGE_NO_THREADS);
      if (!_is_background_tagging_supported(langId)) useThread = false;
      if (langSectionIndex > 0) {
         // updating existing section
         tree1._TreeBeginUpdate(langSectionIndex);
         tree1.AddLanguageTagFiles(langSectionIndex,_replace_envvars(langTagFileList),_replace_envvars(langTagFileListAll),useThread);
         tree1._TreeEndUpdate(langSectionIndex);
      } else {
         // creating a new section
         if (langCompilerIndex > 0) {
            langSectionIndex = tree1._TreeAddItem(langCompilerIndex,   //Relative Index
                                                  '"'mode_name'" ':+LANGUAGE_CONFIG_FOLDER_NAME,//Caption
                                                  TREE_ADD_AFTER,     //Flags
                                                  _pic_fldclos,       //Collapsed Bitmap Index
                                                  _pic_fldopen,       //Expanded Bitmap Index
                                                  TREE_NODE_LEAF);    //Initial State
         } else {
            langSectionIndex = tree1._TreeAddItem(TREE_ROOT_INDEX,    //Relative Index
                                                  '"'mode_name'" ':+LANGUAGE_CONFIG_FOLDER_NAME,//Caption
                                                  TREE_ADD_AS_CHILD,  //Flags
                                                  _pic_fldclos,       //Collapsed Bitmap Index
                                                  _pic_fldopen,       //Expanded Bitmap Index
                                                  TREE_NODE_LEAF);    //Initial State
         }
         if (langSectionIndex > 0) {
            tree1.AddLanguageTagFiles(langSectionIndex,_replace_envvars(langTagFileList),_replace_envvars(langTagFileListAll),useThread);
            TAG_FOLDER_INDEXES(TAG_FOLDER_INDEXES()' 'langSectionIndex);
         }
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Update the tag form when the project file is opened or closed
//
static void UpdateTagFilesForm(_str forLangId="")
{
   static bool recursionGuard;
   if (recursionGuard) return;
   recursionGuard = true;

   formwid := p_window_id;
   if (formwid.p_object != OI_FORM || formwid.p_name != "_tag_form") {
      formwid = _find_formobj('_tag_form','N');
   }

   if (formwid) {
      if (formwid.TAGFORM_SKIP_ON_CHANGE()==1) {
         recursionGuard = false;
         return;
      }
      wid := p_window_id;
      p_window_id=formwid.tree1;
      if (forLangId == null || forLangId == "") {
         forLangId = TAGFORM_LANGUAGE_ID();
      }
      index := _TreeCurIndex();
      if (forLangId == null || forLangId == "" || forLangId == WORKSPACE_LANG_ID) {
         formwid.UpdateWorkspaceTagFiles();
         formwid.UpdateAutoUpdateTagFiles();
      }
      formwid.UpdateAllCompilerTagFiles(forLangId);
      formwid.UpdateTagFilesForLanguages(forLangId);
      if (index > TREE_ROOT_INDEX && _TreeIndexIsValid(index)) {
         call_event(CHANGE_SELECTED,index,p_window_id,ON_CHANGE,'W');
         formwid.list1.refresh('W');
         formwid.list1.p_redraw=true;
      }

      p_window_id=wid;
   }

   recursionGuard = false;
}
void _prjclose_tagform(bool singleFileProject)
{
   if (singleFileProject) return;
   orig_project_name:=_project_name;_project_name='';
   UpdateTagFilesForm();
   _project_name=orig_project_name;
}
_prjupdate_tagform()
{
   UpdateTagFilesForm();
}
void _prjopen_tagform(bool singleFileProject)
{
   if (singleFileProject) return;
   UpdateTagFilesForm();
}

//////////////////////////////////////////////////////////////////////////////
// Used by _textbox_form while editing the tag file description
//
int CheckDescriptionLengthLT96(_str descr)
{
   return (length(descr) < 96)? 0:1;
}
// Prompt user for and add comment to current tag file
static void AddCommentToCurTagfile()
{
   index := _TreeCurIndex();
   if (index > 0) {
      int depth = _TreeGetDepth(index);
      if (depth==TAGFORM_FILE_DEPTH && _haveContextTagging()) {
         _str TagFilename=GetRealTagFilenameFromTree(index);
         int status=tag_read_db(TagFilename);
         if (status < 0) {
            _message_box(nls("Unable to open tag file %s",TagFilename));
            return;
         }
         _str descr = tag_get_db_comment();
         status = show('-modal _textbox_form',
               'Enter Description for Current Tag File',
               0,//Flags,
               '',//Tb width
               '',//help item
               '',//Buttons and captions
               AddCommentToCurTagfile,//retrieve name
               '-e CheckDescriptionLengthLT96 Description:'descr);
         if (status=='') {
            return;
         }
         status=tag_open_db(TagFilename);
         if (status < 0) {
            _message_box(nls("Unable to open tag file %s",TagFilename));
            return;
         }
         tag_set_db_comment(_param1);
         _str allcaption = (_param1=='')? TagFilename:TagFilename' ('_param1')';
         _TreeSetCaption(index,allcaption);
         _TreeRefresh();
         tag_close_db(TagFilename,true);
         _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      }
   }
}

void RenameTagFileInForm(_str newFilename, _str oldFilename)
{
   static bool recursionGuard;
   if (recursionGuard) return;
   recursionGuard = true;

   formwid := _find_formobj('_tag_form','N');
   if (formwid) {
      orig_wid := p_window_id;
      p_window_id = formwid.tree1;

      typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
      typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
      parse formwid.TAG_FOLDER_INDEXES() with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;

      tree_index := _TreeGetFirstChildIndex(ProjectTagfilesIndex);
      while (tree_index > 0) {
         projectTagFile := GetRealTagFilenameFromTree(tree_index);
         if (_file_eq(projectTagFile, oldFilename)) {
            caption := newFilename;
            status := tag_read_db(projectTagFile);
            if (status >= 0) {
               tagFileDescription := tag_get_db_comment();
               if (tagFileDescription != "") {
                  caption=_strip_filename(newFilename,'P'):+" (":+tagFileDescription:+")";
               }
            }
            _TreeSetCaption(tree_index, caption);
            _TreeSetUserInfo(tree_index, newFilename);
         }
         tree_index = _TreeGetNextSiblingIndex(tree_index);
      }

      tree_index = _TreeGetFirstChildIndex(autoUpdateFilesIndex);
      while (tree_index > 0) {
         autoUpdatedTagFile := GetRealTagFilenameFromTree(tree_index);
         if (_file_eq(autoUpdatedTagFile, oldFilename)) {
            _TreeSetUserInfo(tree_index, newFilename);
         }
         tree_index = _TreeGetNextSiblingIndex(tree_index);
      }

      p_window_id = orig_wid;
   }

   recursionGuard = false;
}

//////////////////////////////////////////////////////////////////////////////
// Prompt the user for a new directory to place workspace files in.
//
void EditWorkspaceTagFileDirectory()
{
   workspaceDir := _strip_filename(_workspace_filename,'N');
   old_tag_files_dir := VSEWorkspaceTagFileDir();
   result := _ChooseDirDialog("Choose directory for Workspace tag files", old_tag_files_dir, "", CDN_PATH_MUST_EXIST|CDN_ALLOW_CREATE_DIR|CDN_NO_SYS_DIR_CHOOSER);
   if (result == "") {
      return;
   }
   if (_file_eq(result, old_tag_files_dir)) {
      message("Workspace tag file directory not changed.");
      return;
   }
   if (_file_eq(result, workspaceDir)) {
      result = "";
   }

   // save the original list of tag files
   mou_hour_glass(true);
   old_tag_files := project_tags_filenamea();
   old_auto_updated_tag_files := auto_updated_tags_filename();

   // set the new tag files directory
   _WorkspaceSet_TagFileDir(gWorkspaceHandle,result);

   // save the workspace
   _WorkspaceSave(gWorkspaceHandle);

   // get the new list of tag files
   gtag_filelist_cache_updated=false;
   new_tag_files := project_tags_filenamea();
   new_auto_updated_tag_files := auto_updated_tags_filename();
   tag_close_all();

   // Go through the list of project tag files and move them into place
   for (i:=0; i<old_tag_files._length() && i<new_tag_files._length(); i++) {
      newFilename := new_tag_files[i];
      oldFilename := old_tag_files[i];

      // let the user know what is going on
      message("Moving workspace tag file: "newFilename);

      // the tag file names should always match
      if (!_file_eq(_strip_filename(newFilename,'p'), _strip_filename(oldFilename,'p'))) {
         _message_box(nls("Failed to update workspace tag files due to file list mismatch"));
         break;
      }

      // rename the file in the Tag File dialog
      RenameTagFileInForm(newFilename, oldFilename);

      // rename the file to it's new location
      tag_cancel_async_tag_file_build(oldFilename);
      if (file_exists(newFilename)) delete_file(newFilename);

      // adjust the file paths
      status := adjustTagfilePaths(oldFilename, _strip_filename(newFilename, 'n'), _strip_filename(oldFilename, 'n'));
      if (status == BT_CANNOT_WRITE_OBSOLETE_VERSION_RC) {
         status = tag_update_tag_file_to_latest_version(oldFilename, newFilename);
         if (status < 0) {
            _message_box(nls("Failed to update tag file '%s1'.  Update tag file failed with error: %s2 (%s3).", newFilename, get_message(status), status));
            continue;
         }
      } else {
         tag_close_db(oldFilename, false);
         tag_close_db(newFilename, false);
         status = _file_move(newFilename, oldFilename);
         if (status < 0) {
            _message_box(nls("Failed to rename tag file '%s1'.  Rename tag file failed with error: %s2 (%s3).", newFilename, get_message(status), status));
         }
      }

      // clean up the old tag file name
      tag_close_db(oldFilename, false);
      if (file_exists(oldFilename)) delete_file(oldFilename);
   }

   // Go through the new list of auto-updated tag files and reload them
   check_autoupdated_tagfiles();

   // Go through the old list of auto-updated tag files and remove them
   old_tag_filename := next_tag_file2(old_auto_updated_tag_files,false);
   new_tag_filename := next_tag_file2(new_auto_updated_tag_files,false);
   while (old_tag_filename != "" && new_tag_filename != "") {
      tag_close_db(old_tag_filename, false);
      if (file_exists(old_tag_filename)) delete_file(old_tag_filename);
      RenameTagFileInForm(new_tag_filename, old_tag_filename);
      old_tag_filename = next_tag_file2(old_auto_updated_tag_files,false);
      new_tag_filename = next_tag_file2(new_auto_updated_tag_files,false);
   }

   // move the workspace history file
   new_workspace_history_file := VSEWorkspaceStateFilename();
   old_workspace_history_file := old_tag_files_dir:+_strip_filename(new_workspace_history_file,'P');
   if (file_exists(old_workspace_history_file)) {
      if (!file_exists(new_workspace_history_file)) {
         _file_move(new_workspace_history_file,old_workspace_history_file);
      } else if (!_file_eq(old_tag_files_dir, workspaceDir)) {
         delete_file(old_workspace_history_file);
      }
   }

   // call the update workspace callbacks
   tag_close_all();
   _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,"","");
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   clear_message();
   mou_hour_glass(false);
}

//////////////////////////////////////////////////////////////////////////////
// Handle right click menu events for the tag form
//
_command TagTreeRunMenu(_str command='') name_info(','VSARG2_CMDLINE|VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   if (command=='') {
      return('');
   }
   switch (lowcase(command)) {
   case 'addfiles':
      ctlfiles_btn.call_event(ctlfiles_btn,LBUTTON_UP);
      break;
   case 'addtree':
      ctltree_btn.call_event(ctltree_btn,LBUTTON_UP);
      break;
   case 'addtagfile':
      ctlnew_tag_file_btn.call_event(ctlnew_tag_file_btn,LBUTTON_UP);
      break;
   case 'deltagfile':
      ctlremove_tag_file_btn.call_event(ctlremove_tag_file_btn,LBUTTON_UP);
      break;
   case 'selectall':
      list1._lbselect_all();
      break;
   case 'delfiles':
      ctlremove_files_btn.call_event(ctlremove_files_btn,LBUTTON_UP);
      break;
   case 'addcomment':
      AddCommentToCurTagfile();
      break;
   case 'makerefs':
      ToggleGenerateReferences();
      break;
   case 'workspacedir':
      EditWorkspaceTagFileDirectory();
      break;
   case 'moveup':
      ctlup_btn.call_event(ctlup_btn,LBUTTON_UP);
      break;
   case 'movedown':
      ctldown_btn.call_event(ctldown_btn,LBUTTON_UP);
      break;
   case 'retagfiles':
      ctlretag_files_btn.call_event(ctlretag_files_btn,LBUTTON_UP);
      break;
   case 'rebuildtagfile':
      ctlrebuild_tag_file_btn.call_event(ctlrebuild_tag_file_btn,LBUTTON_UP);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Display right button menu for tag file tree (left hand side of dialog)
//
tree1.rbutton_up()
{
   tree1.call_event(tree1,LBUTTON_DOWN);
   int index=find_index("_tag_tree_menu",oi2type(OI_MENU));
   int menu_handle=p_active_form._menu_load(index,'P');
   index=tree1._TreeCurIndex();
   typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
   typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
   parse TAG_FOLDER_INDEXES() with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;
   if (_TreeGetDepth(index)!=TAGFORM_FILE_DEPTH) {
      _menu_set_state(menu_handle,"treeitem",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"moveitem",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"deltagfile",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"addcomment",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"rebuilditem",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"makerefs",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"workspacedir",MF_GRAYED,'C');
   } else {
      // initialize checkbox for building references
      TagFilename := tree1.GetRealTagFilenameFromTree(index);
      status := tag_read_db(TagFilename);
      if (status >= 0 && (tag_get_db_flags() & VS_DBFLAG_occurrences)) {
         _menu_set_state(menu_handle,"makerefs",MF_CHECKED,'C');
      }
      parentIndex := _TreeGetParentIndex(index);
      if (parentIndex == ProjectTagfilesIndex) {
         // disable certain items for project or workspace tag file
         _menu_set_state(menu_handle,"treeitem",MF_GRAYED,'C');
         _menu_set_state(menu_handle,"moveitem",MF_GRAYED,'C');
         _menu_set_state(menu_handle,"addtagfile",MF_GRAYED,'C');
         _menu_set_state(menu_handle,"deltagfile",MF_GRAYED,'C');
      } else if (parentIndex == autoUpdateFilesIndex) {
         // disable certain items for auto-updated tag files
         _menu_set_state(menu_handle,"treeitem",MF_GRAYED,'C');
         _menu_set_state(menu_handle,"moveitem",MF_GRAYED,'C');
         _menu_set_state(menu_handle,"rebuilditem",MF_GRAYED,'C');
         _menu_set_state(menu_handle,"addcomment",MF_GRAYED,'C');
         _menu_set_state(menu_handle,"makerefs",MF_GRAYED,'C');
      } else if (parentIndex == cppCompilerTagFilesIndex ||
          parentIndex == javaCompilerTagFilesIndex) {
         // disable up and down for compiler tag files
         _menu_set_state(menu_handle,"moveitem",MF_GRAYED,'C');
         _menu_set_state(menu_handle,"workspacedir",MF_GRAYED,'C');
      } else {
         // disable workspace dir for things not related to workspace
         _menu_set_state(menu_handle,"workspacedir",MF_GRAYED,'C');
      }
      if (!ctlremove_tag_file_btn.p_enabled) {
         _menu_set_state(menu_handle, "deltagfile", MF_GRAYED, 'C');
      }
   }
   int x,y;
   mou_get_xy(x,y);
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
}

//////////////////////////////////////////////////////////////////////////////
// Display right button menu for source file list (right hand side of dialog)
//
list1.rbutton_up()
{
   //_message_box('got here');
   /*if (p_scroll_left_edge>=0) {
      _scroll_page('r');
   }*/

   int x=mou_last_x();
   int y=mou_last_y();
   _map_xy(list1,0,x,y);
   if (!_lbisline_selected()) {
      _lbdeselect_all();
      _lbselect_line();
   }
   refresh();

   int index=find_index("_tag_list_menu",oi2type(OI_MENU));
   int menu_handle=p_active_form._menu_load(index,'P');
   index=tree1._TreeCurIndex();
   if (tree1._TreeGetDepth(index)!=TAGFORM_FILE_DEPTH) {
      _menu_set_state(menu_handle,"treeitem",MF_GRAYED,'C');
   }
   if (!list1.p_Noflines) {
      _menu_set_state(menu_handle,"listitem",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"delitem",MF_GRAYED,'C');
   }
   _str TagFilename=tree1.GetRealTagFilenameFromTree(index);
   if (isWorkspaceTagFileName(TagFilename)) {
      _menu_set_state(menu_handle,"treeitem",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"delitem",MF_GRAYED,'C');
   } else if (isProjectTagFileName(TagFilename)) {
      _menu_set_state(menu_handle,"treeitem",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"delitem",MF_GRAYED,'C');
   }

   if (!ctlremove_files_btn.p_enabled) _menu_set_state(menu_handle,"delitem",MF_GRAYED,'C');
   if (!ctlfiles_btn.p_enabled)        _menu_set_state(menu_handle,"treeitem",MF_GRAYED,'C');
   if (!ctltree_btn.p_enabled)         _menu_set_state(menu_handle,"treeitem",MF_GRAYED,'C');
   if (!ctlretag_files_btn.p_enabled)  _menu_set_state(menu_handle,"listitem",MF_GRAYED,'C');

   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
}

//////////////////////////////////////////////////////////////////////////////
// Move the tag file at the given index up.  This is done to allow the
// user to adjust the ordering in which tag files are searched.
//
static bool MoveFileUp(int FileIndex)
{
   TAGFORM_SKIP_ON_CHANGE(1);
   status := tree1._TreeMoveUp(FileIndex);
   TAGFORM_SKIP_ON_CHANGE(0);
   return (status == 0);
}

//////////////////////////////////////////////////////////////////////////////
// Move the tag file at the given index down.  This is done in order
// to allow the user to adjust the ordering in which tag files are searched.
//
static bool MoveFileDown(int FileIndex)
{
   TAGFORM_SKIP_ON_CHANGE(1);
   status := tree1._TreeMoveDown(FileIndex);
   TAGFORM_SKIP_ON_CHANGE(0);
   return (status == 0);
}

//////////////////////////////////////////////////////////////////////////////
// Handle 'Up' and 'Down' buttons
//
void ctlup_btn.lbutton_up()
{
   index := tree1._TreeCurIndex();
   depth := tree1._TreeGetDepth(index);
   if (depth==TAGFORM_FILE_DEPTH) {
      moved := MoveFileUp(index);
      if (moved) {
         FolderIndex := tree1._TreeGetParentIndex(index);
         SetTagFilesOrSetModified(FolderIndex);
      }
   }
}
void ctldown_btn.lbutton_up()
{
   index := tree1._TreeCurIndex();
   depth := tree1._TreeGetDepth(index);
   if (depth==TAGFORM_FILE_DEPTH) {
      moved := MoveFileDown(index);
      if (moved) {
         FolderIndex := tree1._TreeGetParentIndex(index);
         SetTagFilesOrSetModified(FolderIndex);
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Display auto tagging options form
//
ctloptions_btn.lbutton_up()
{
   config('Editing > Context Tagging'VSREGISTEREDTM);
}

bool isuinteger(_str text)
{
   if (!isinteger(text)) return false;
   return ((int) text >= 0);
}



#region Options Dialog Helper Functions

bool _tag_form_create_needs_lang_argument()
{
   return true;
}

void _tag_form_init_for_options(_str langID)
{
   ctldone.p_enabled = false;
   ctldone.p_visible = false;

   callbackIndex := find_index("_"langID"_getAutoTagChoices", PROC_TYPE);
   if (!callbackIndex) {
      callbackIndex = find_index("_"langID"_MaybeBuildTagFile", PROC_TYPE);
   }
   if (!callbackIndex) {
      ctlautotag_btn.p_enabled = false;
   }

}

void _tag_form_restore_state()
{
   p_active_form.UpdateTagFilesForm();
}

bool _tag_form_is_modified(_str settings:[])
{
   isModified := TAGFORM_IS_MODIFIED();
   return (isModified != null && isModified);
}

bool _tag_form_apply()
{
   SetTagFiles();
   _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,"","");
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   return true;
}


static const LANG_TAG_FILE_LIST_LABEL=     "tag_file_list";
static const LANG_TAG_FILE_LIST_ALL_LABEL= "tag_file_list_all";

_str _tag_form_build_export_summary(PropertySheetItem (&summary)[], _str langID="")
{
   error := "";
   PropertySheetItem psi;
   psi.ChangeEvents = 0;
   if (langID == "") {
      return error;
   }

   list_set := LanguageSettings.getTagFileList(langID);
   if (list_set != null && list_set != "") {
      psi.Caption = langID :+ " " :+ LANG_TAG_FILE_LIST_LABEL;
      psi.Value   = list_set;
      summary :+= psi;
   }

   list_all := LanguageSettings.getTagFileListAll(langID);
   if (list_all != null && list_all != "") {
      psi.Caption = langID :+ " " :+ LANG_TAG_FILE_LIST_ALL_LABEL;
      psi.Value   = list_all;
      summary :+= psi;
   }

   return "";
}

_str _tag_form_import_summary(PropertySheetItem (&summary)[], _str langID)
{
   error := "";
   foreach (auto psi in summary) {
      parse psi.Caption with auto ext auto label;
      if (ext == langID && label != '') {
         switch (label) {
         case LANG_TAG_FILE_LIST_LABEL:
            LanguageSettings.setTagFileList(langID, psi.Value);
            break;
         case LANG_TAG_FILE_LIST_ALL_LABEL:
            LanguageSettings.setTagFileListAll(langID, psi.Value);
            break;
         }
      }
   }

   // all done
   return error;
}


#endregion Options Dialog Helper Functions


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// add tag files form for selecting type of tag file to add
//
defeventtab _add_tag_file_form;
void _ctl_new_file_path.on_change()
{
   _ctl_create_new_file.p_value=1;
}
void _ctl_existing_file_path.on_change()
{
   _ctl_add_existing_file.p_value=1;
}

static _str PREVIOUS_EXISTING_PATH(...) {
   if (arg()) _ctl_existing_file_path.p_user=arg(1);
   return _ctl_existing_file_path.p_user;
}
static _str PREVIOUS_NEW_PATH(...) {
   if (arg()) _ctl_new_file_path.p_user=arg(1);
   return _ctl_new_file_path.p_user;
}
static _str PREVIOUS_SOURCE_PATH(...) {
   if (arg()) _ctl_source_path.p_user=arg(1);
   return _ctl_source_path.p_user;
}

_ctl_ok.on_create(_str defaultMode = "C/C++", bool forceDefaultMode=false)
{
   _retrieve_prev_form();
   orig_filespecs := ctlinclude_filespecs.p_text;

   // fill in the language combo box
   index := 0;
   findFirst := 1;
   langId := '';

   if (forceDefaultMode && defaultMode != "") {
      _ctl_languages._cbset_text(defaultMode);
      _ctl_languages.p_enabled = false;
   } else {
      if (defaultMode != "") {
         _ctl_languages._lbadd_item(SELECT_LANGUAGE_MODE);
      }
      LanguageSettings.getAllLanguageIds(auto langs);
      foreach (langId in langs) {
         // if tagging is supported for this language, add it to the list
         if (_istagging_supported(langId)) {
            _ctl_languages._lbadd_item(_LangGetModeName(langId));
         }
      }
      _ctl_languages._lbsort('i');
      if (defaultMode != "") {
         _ctl_languages._lbfind_and_select_item(defaultMode, 'i', true);
      } else {
         _ctl_languages._cbset_text(SELECT_LANGUAGE_MODE);
      }
      _ctl_languages.p_style = PSCBO_NOEDIT;
   }

   langId = _Modename2LangId(_ctl_languages._lbget_text());
   ctlUseThread.p_value = (def_autotag_flags2 & AUTOTAG_LANGUAGE_NO_THREADS)? 0:1;
   ctlUseThread.p_enabled = _is_background_tagging_supported(langId) && _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
   if (defaultMode == "") {
      ctlUseThread.p_enabled = true;
   }

   if (_isUnix()) {
      // Use retrieval value
      ctlsymlinks.p_value=def_symlinks;
   } else {
      ctlsymlinks.p_visible=false;
   }

   // add some filespecs to our combo
   ctlinclude_filespecs._retrieve_list();
   ctlinclude_filespecs.add_filetypes_to_combo();
   ctlinclude_filespecs._cbset_text(orig_filespecs);

   ctlexclude_filespecs._retrieve_list();
   ctlexclude_filespecs.p_text = _retrieve_value("_add_tag_file_form.ctlexclude_filespecs.p_text");

   // if the paths have initial values, save them in the p_user,
   // so as to reinitialize the browse button
   PREVIOUS_EXISTING_PATH(_ctl_existing_file_path.p_text);
   PREVIOUS_NEW_PATH(_ctl_new_file_path.p_text);
   PREVIOUS_SOURCE_PATH(_ctl_source_path.p_text);
   _ctl_existing_file_path.p_text = _ctl_new_file_path.p_text = _ctl_source_path.p_text = '';

   // align the controls based on image sizes
   _add_tag_file_form_initial_alignment();

   // try to make sure the include file specs are set up correctly for this language
   if (defaultMode != "") {
      _ctl_languages.call_event(CHANGE_SELECTED, _ctl_languages.p_window_id, ON_CHANGE, 'W');
   }
}

static void _add_tag_file_form_initial_alignment()
{
   rightAlign := _ctl_languages.p_x_extent;
   sizeBrowseButtonToTextBox(_ctl_existing_file_path.p_window_id, _ctl_existing_file_browse_btn.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(_ctl_new_file_path.p_window_id, _ctl_new_file_browse_btn.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(_ctl_source_path.p_window_id, _ctl_source_browse_btn.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctlinclude_label.p_window_id, ctlinclude_help.p_window_id);
   sizeBrowseButtonToTextBox(ctlexclude_label.p_window_id, ctlexclude_help.p_window_id);
}

void _ctl_languages.on_change(int reason)
{
   modeName := _ctl_languages.p_text;//_lbget_text();
   langId := _Modename2LangId(modeName);
   ctlUseThread.p_enabled = _is_background_tagging_supported(langId);
   if (modeName == SELECT_LANGUAGE_MODE) {
      ctlUseThread.p_enabled = true;
   }

   // update the wildcard specs if it looks like they are wrong for this language
   if (!pos(".":+langId:+";", ctlinclude_filespecs.p_text) && !endsWith(ctlinclude_filespecs.p_text, ".":+langId)) {
      wildcards := _GetWildcardsForLanguage(langId);
      if (wildcards != "" && wildcards != "*." && wildcards != ALLFILES_RE) {
         ctlinclude_filespecs._cbset_text(wildcards);
      }
   }
}

void _ctl_add_existing_file.lbutton_up()
{
   // enable/disable controls based on which radio button is picked
   enable_existing := (_ctl_add_existing_file.p_value == 1);
   _ctl_existing_file_path.p_enabled = enable_existing;
   _ctl_existing_file_browse_btn.p_enabled = enable_existing;
   ctlRebuild.p_enabled = enable_existing;

   enable_new := (_ctl_create_new_file.p_value == 1);
   _ctl_new_file_path.p_enabled = enable_new;
   _ctl_new_file_browse_btn.p_enabled = enable_new;
   ctlpath_label.p_enabled =enable_new;
   _ctl_source_path.p_enabled = enable_new;
   _ctl_source_browse_btn.p_enabled = enable_new;
   ctlrecursive.p_enabled =enable_new;
   ctlsymlinks.p_enabled = enable_new;
   ctlinclude_label.p_enabled = enable_new;
   ctlinclude_help.p_enabled = enable_new;
   ctlinclude_filespecs.p_enabled =enable_new;
   ctlexclude_label.p_enabled = enable_new;
   ctlexclude_help.p_enabled = enable_new;
   ctlexclude_filespecs.p_enabled = enable_new;
}

_ctl_existing_file_browse_btn.lbutton_up()
{
   // use the current value as the initial path
   initialPath := _ctl_existing_file_path.p_text;
   if (initialPath == '') {
      // or maybe the previous value
      initialPath = PREVIOUS_EXISTING_PATH();
   }
   initialPath = _strip_filename(initialPath, 'N');
   result := pickTagFileToAdd(false, initialPath);

   // set the value, then
   if (result != '') {
      _ctl_existing_file_path.p_text = result;
      PREVIOUS_EXISTING_PATH(result);
   }
}

_ctl_new_file_browse_btn.lbutton_up()
{
   // use the current value as the initial path
   initialPath := _ctl_new_file_path.p_text;
   if (initialPath == '') {
      // or maybe the previous value
      initialPath = PREVIOUS_NEW_PATH();
   }
   initialPath = _strip_filename(initialPath, 'N');
   result := pickTagFileToAdd(true, initialPath);

   // set the value, then
   if (result != '') {
      _ctl_new_file_path.p_text = result;
      PREVIOUS_NEW_PATH(result);
   }
}

static _str pickTagFileToAdd(bool createNew, _str initialPath = '')
{
   tag_file_type := VS_DBTYPE_tags;
   tag_file_ext :=_get_extension(TAG_FILE_EXT);

   int openDlgFlags = OFN_NODATASETS;
   if (!createNew) {
      // we are adding an existing file, so do not prompt about overwriting
      openDlgFlags |= OFN_FILEMUSTEXIST | OFN_NOOVERWRITEPROMPT;
   } else {
      openDlgFlags |= OFN_SAVEAS;
   }

   if (initialPath == '') {
      initialPath = _tagfiles_path();
   }

   // do this in a loop, so we can check that it's valid
   result := '';
   while (true) {
      result = _OpenDialog('-modal',
                           'Add Tags Database',      // title
                           "",                       // Initial wildcards
                           "Tag Files (*"TAG_FILE_EXT"), Old Tag Files (tags.slk)",
                           openDlgFlags,
                           tag_file_ext,             // Default extension
                  /*
                     The logic here is that typically all user
                     created tag files have the name "tags.vtg".
                     This prevents the user from having a
                     tag file conflict with a project tag file
                     which has the same extension.

                     That logic is obsolete now that almost all tag files
                     except for the project tag file are stored in the
                     users 'tagfiles' directory under his config dir.
                     [DJB 06-18-2002]
                  */
                           "*"TAG_FILE_EXT,          // Initial filename
                           initialPath               // Initial directory
                           );

      // cancel, break the loop
      if (result=='') break;
      result = strip(result, 'B', '"');

      ext := _get_extension(result);
      expected_ext := TAG_FILE_EXT;
      alternate_ext := '.slk';
      if (!_file_eq('.'ext, expected_ext) && !_file_eq('.'ext, alternate_ext)) {
         _message_box(nls("For your protection, tag files must have a '%s' extension.", expected_ext));
      } else {
         // this filename is okay, break the loop
         break;
      }
   }

   return result;
}

void _ctl_source_browse_btn.lbutton_up()
{
   initialPath := _ctl_source_path.p_text;
   if (initialPath == '') {
      // or maybe the previous value
      initialPath = PREVIOUS_SOURCE_PATH();
   }

   _str result = _ChooseDirDialog("", initialPath, "", CDN_PATH_MUST_EXIST | CDN_ALLOW_CREATE_DIR);
   if (result == '') return;

   _ctl_source_path.p_text = result;
}

void ctlrecursive.lbutton_up()
{
   ctlsymlinks.p_enabled=(p_value!=0);
}

void _ctl_ok.lbutton_up()
{
   _param1 = _ctl_languages.p_text;          // param1 - language
   _param2 = ctl_make_references.p_value;    // param2 - generate references
   _param3 = ctlUseThread.p_enabled && (ctlUseThread.p_value != 0);     // param3 - use background tagging
   _param4 = _ctl_create_new_file.p_value;   // param4 - create new file (as opposed to adding existing

   if (_ctl_languages.p_text == SELECT_LANGUAGE_MODE) {
      _message_box("Please specify a language mode name.", p_active_form.p_caption);
      _ctl_languages._set_focus();
      return;
   }

   // new or existing file?
   if (_ctl_add_existing_file.p_value) {
      tag_file := _ctl_existing_file_path.p_text;
      tag_file = _maybe_unquote_filename(tag_file);
      if (tag_file == "") {
         _message_box("Please select a tag file to add.", p_active_form.p_caption);
         text := _ctl_existing_file_path.p_text;
         _ctl_existing_file_path.set_command(text,1,length(text)+1);
         _ctl_existing_file_path._set_focus();
         return;
      }
      ext := get_extension(tag_file, returnDot:true);
      if (!file_eq(ext, TAG_FILE_EXT) && !file_eq(ext, REF_FILE_EXT) && !file_eq(ext, BSC_FILE_EXT)) {
         mbrc := _message_box("Expecting tag file with a "TAG_FILE_EXT" extension.  Are you sure?", "Confirm tag file name", MB_YESNO|MB_ICONEXCLAMATION);
         if (mbrc!=IDYES) {
            text := _ctl_existing_file_path.p_text;
            _ctl_existing_file_path.set_command(text,1,length(text)+1);
            _ctl_existing_file_path._set_focus();
            return;
         }
      }

      // existing file
      _param5 = tag_file;                 // tag file
      _param6 = ctlRebuild.p_value;       // rebuild tag files

   } else {

      // new file
      tag_file := _ctl_new_file_path.p_text;
      tag_file = _maybe_unquote_filename(tag_file);
      if (tag_file == "") {
         _message_box("Please specify a tag file name.", p_active_form.p_caption);
         text := _ctl_new_file_path.p_text;
         _ctl_new_file_path.set_command(text,1,length(text)+1);
         _ctl_new_file_path._set_focus();
         return;
      }

      // make sure the tag file has a .vtg extension
      ext := get_extension(tag_file, returnDot:true);
      if (ext == "") {
         tag_file :+= TAG_FILE_EXT;
      } else if (!file_eq(ext, TAG_FILE_EXT) && !file_eq(ext, REF_FILE_EXT) && !file_eq(ext, BSC_FILE_EXT)) {
         _message_box("Expecting tag file with a "TAG_FILE_EXT" extension", "Confirm tag file name", MB_OK|MB_ICONEXCLAMATION);
         text := _ctl_new_file_path.p_text;
         _ctl_new_file_path.set_command(text,1,length(text)+1);
         _ctl_new_file_path._set_focus();
         return;
      }

      // make sure the tag file path is absolute
      initialPath := _strip_filename(tag_file, 'N');
      if (initialPath == '') {
         initialPath = _tagfiles_path();
      }
      tag_file = absolute(tag_file, absolute(initialPath));
      _param5 = tag_file;

      // make sure we have a source path
      if (_ctl_source_path.p_text == '') {
         // Not adding and files to the tag file.
         _param6 = _param7 = _param8 = _param9= _param10='';

      } else {

         // _param6 is the array of include paths, built
         // using the source path and the include specs

         _param6=absolute(_ctl_source_path.p_text);
         if (!isdirectory(_param6)) {
            _message_box(get_message(CMRC_PATH_NOT_FOUND_1ARG,_param6), p_active_form.p_caption);
            text := _ctl_source_path.p_text;
            _ctl_source_path.set_command(text,1,length(text)+1);
            _ctl_source_path._set_focus();
            return;
         }

         _param7 = ctlrecursive.p_value;              // recursive
         _param8 = ctlsymlinks.p_value;               // follow symlinks

         // _param9 is an array of the exclude specs
         _param9._makeempty();
         list := ctlexclude_filespecs.p_text;
         while (list != '') {
            file:=parse_file_sepchar(list);
            if (file != '') {
               _param9[_param9._length()]=file;
            }
         }
         _param10._makeempty();
         list = ctlinclude_filespecs.p_text;
         while (list != '') {
            file:=parse_file_sepchar(list);
            if (file != '') {
               _param10[_param10._length()]=file;
            }
         }
         // Not sure if this is needed.
         if (!_param10._length() && ctlinclude_filespecs.p_visible) {
            _message_box('No include filespecs specified', p_active_form.p_caption);
            text := ctlinclude_filespecs.p_text;
            ctlinclude_filespecs.set_command(text,1,length(text)+1);
            ctlinclude_filespecs._set_focus();
            return;
         }
      }

      _append_retrieve(ctlexclude_filespecs, ctlexclude_filespecs.p_text);
      _append_retrieve(0, ctlexclude_filespecs.p_text, "_add_tag_file_form.ctlexclude_filespecs.p_text");

   }

   _save_form_response();

   p_active_form._delete_window(IDOK);
}

_ctl_cancel.lbutton_up()
{
   p_active_form._delete_window(IDCANCEL);
}
defeventtab _rebuild_tag_file_form;
void ctlok.on_create(bool rebuild_all=false,
                     bool tag_occurrences=false,
                     bool removeWithoutPrompting=false,
                     bool keepWithoutPrompting=false,
                     bool isWorkspaceTagFile=false,
                     bool useThread = false,
                     bool hideRetagModified = false,
                     _str caption="")
{
   ctlRetagModified.p_value=(int)!(rebuild_all);
   ctl_make_references.p_value=(int)tag_occurrences;
   ctlRemoveWithoutPrompting.p_value=(int)removeWithoutPrompting;
   ctlKeepWithoutPrompting.p_value=(int)keepWithoutPrompting;
   if (isWorkspaceTagFile) {
      ctlRemoveWithoutPrompting.p_enabled=false;
      ctlKeepWithoutPrompting.p_enabled=false;
      ctlRemoveWithoutPrompting.p_visible=false;
      ctlKeepWithoutPrompting.p_visible=false;

      yDiff := ctlRemoveWithoutPrompting.p_y - ctlUseThread.p_y;
      ctlUseThread.p_y += yDiff;
      ctlok.p_y += yDiff;
      ctlcancel.p_y = ctlok.p_y;
      p_active_form.p_height += yDiff;
   }
   if (hideRetagModified) {
      ctlRetagModified.p_enabled = false;
      ctlRetagModified.p_visible = false;
      yDiff := ctl_make_references.p_y - ctlUseThread.p_y;
      ctlRemoveWithoutPrompting.p_y += yDiff;
      ctlKeepWithoutPrompting.p_y += yDiff;
      ctl_make_references.p_y += yDiff;
      ctlUseThread.p_y += yDiff;
      ctlok.p_y += yDiff;
      ctlcancel.p_y = ctlok.p_y;
      p_active_form.p_height += yDiff;
   }
   if (caption != null && caption != "") {
      p_active_form.p_caption = caption;
   }
   if (!useThread) {
      ctlUseThread.p_value = 0;
      ctlUseThread.p_enabled = false;
   } else if (isWorkspaceTagFile) {
      ctlUseThread.p_value = _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS)? 1:0;
   } else {
      ctlUseThread.p_value = _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS)? 1:0;
   }
}
void ctlok.lbutton_up()
{
   _param1=ctlRetagModified.p_value;
   _param2=ctlRemoveWithoutPrompting.p_enabled ? ctlRemoveWithoutPrompting.p_value : 0;
   _param3=ctl_make_references.p_value;
   _param4=ctlKeepWithoutPrompting.p_enabled ? ctlKeepWithoutPrompting.p_value : 0;
   _param5=ctlUseThread.p_value;
   p_active_form._delete_window(1);
}
void ctlRemoveWithoutPrompting.lbutton_up()
{
   if (p_value && ctlRemoveWithoutPrompting.p_value) {
      ctlKeepWithoutPrompting.p_value = 0;
   }
}
void ctlKeepWithoutPrompting.lbutton_up()
{
   if (p_value && ctlRemoveWithoutPrompting.p_value) {
      ctlRemoveWithoutPrompting.p_value = 0;
   }
}


//////////////////////////////////////////////////////////////////////////////
// Callback for refreshing the symbol browser, as required by the background
// tagging.  Since we handle the AddRemove and Modified callbacks, we don't
// have to do anything for refresh, we are already totally up-to-date.
//
void _TagFileRefresh_tagform()
{
   UpdateTagFilesForm();
}

/**
 * Invokes the Tag Compiler Libraries dialog which detects installed compilers 
 * and makes it possible to build Tag Files for that language. 
 * 
 * @param langId     Specific language to find compiler libraries for. 
 * 
 * @return 0 on success, &lt;0 on error. 
 *  
 * @categories Tagging_Functions, Forms, Search_Functions
 */
_command int autotag(_str langId="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Tagging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (langId != null && langId != "") {
      callbackIndex := find_index("_"langId"_getAutoTagChoices", PROC_TYPE);
      if (!callbackIndex) {
         popup_nls_message(VSRC_AUTOTAG_NOT_SUPPORTED_FOR_FILES_OF_THIS_TYPE_ARG1, _LangId2Modename(langId));
         return STRING_NOT_FOUND_RC;
      }
   }
   return show("-modal _tag_compilers_form", langId);
}

defeventtab _tag_compilers_form;

void _tag_compilers_form_init_for_options()
{
   // hide the buttons!
   _ctl_divider.p_visible = _ctl_ok.p_visible = _ctl_cancel.p_visible = _ctl_help.p_visible = false;

   // change the text

   _ctl_info_html.p_text='<p style="font-family:'VSDEFAULT_DIALOG_FONT_NAME'; font-size:10">Context Tagging performs expression ':+
                         'type, scope and inheritance analysis as well as symbol look-up within the current context to ':+
                         'help you navigate and write code.  It  parses your code and builds a database of symbol definitions ':+
                         'and declarations - commonly referred to as tags.  Context Tagging works with your source code ':+
                         'as well as libraries for commonly-used languages such as C, C++, Java, and .NET.  To tag these ':+
                         'compiler libraries now, click the button below.  You can also access this feature from the main ':+
                         'menu under <b>Tools > Tag Files</b> and pressing the <b>Auto Tag</b> button.</p>';
}

bool _tag_compilers_form_is_modified()
{
   // if they don't have anything selected, then consider this as unmodified
   AUTOTAG_BUILD_INFO choices[];
   selectedItems := _ctl_tagfiles._getSelectedAutoTagFiles(choices);
   if (selectedItems == "") {
      return false; 
   }

   // check if the modify flag was set
   isModified := _ctl_tagfiles.p_user;
   if (isModified) {
      return true;
   }

   // check that all their tag files exist on disk
   for (i:=0; i<choices._length(); i++) {
      tagFilename := _tagfiles_path():+choices[i].tagDatabase;
      if (!file_exists(tagFilename)) {
         return true;
      }
   }

   // this is the case where they are just accepting the same defaults as before
   // and the tag files already have been built, so consider them as unmodified.
   return false;
}

void _tag_compilers_form_apply()
{
   tagFilesPath := _tagfiles_path();
   if (!isdirectory(tagFilesPath)) {
      mkdir(tagFilesPath);
   }

   AUTOTAG_BUILD_INFO choices[];
   selectedItems := _ctl_tagfiles._getSelectedAutoTagFiles(choices);
   if (choices._length() > 0) {
      _buildSelectedAutoTagFiles(choices, (_ctl_use_background_thread.p_value != 0));
   }

   // Tell Eclipse that we removed a tagfile
   if (isEclipsePlugin()) {
      proj := "";
      _eclipse_get_active_project_name(proj);
      if (proj != "") {
         _eclipse_update_tag_list(proj);
      }
   }

   if (selectedItems == "") selectedItems = "none";
   _append_retrieve(0, selectedItems, "_tag_compilers_form._ctl_tagfiles");
}

void _ctl_tagfiles.on_create(_str langId="")
{
   // adjust the position of the form relative to the help label
   _ctl_info_html.p_height *= 2;
   _ctl_info_html._minihtml_ShrinkToFit();
   _ctl_tagfiles.p_y = 2*_ctl_info_html.p_y + _ctl_info_html.p_height;

   // load all the autotag choices
   _ctl_tagfiles._loadAutoTagChoices(langId);
   _ctl_tagfiles.p_user = true;
   _ctl_add.p_user = langId;

   // get the last set of choices
   selectedItems := _retrieve_value("_tag_compilers_form._ctl_tagfiles");
   if (selectedItems != "") {
      _ctl_tagfiles._checkSelectedAutoTagFiles(selectedItems);
      _ctl_tagfiles.p_user = false;
   }

   _ctl_tagfiles.call_event(CHANGE_SELECTED, _ctl_tagfiles._TreeCurIndex(), _ctl_tagfiles, ON_CHANGE, 'W');
}

_ctl_ok.lbutton_up()
{
   _tag_compilers_form_apply();

   p_active_form._delete_window();
}

void _ctl_tagfiles.on_change(int reason, int treeIndex = 0)
{
   switch (reason) {
   case CHANGE_SELECTED:
      enabled := false;

      // determine whether configure button is enabled
      do {
         // determine whether or not to enable the configure button
         if (treeIndex <= 0) break;

         _ctl_tagfiles._TreeGetInfo(treeIndex, auto showChildren);
         if (showChildren != TREE_NODE_LEAF) break;

         // figure out what language we have here
         AUTOTAG_BUILD_INFO autotagInfo = _ctl_tagfiles._TreeGetUserInfo(treeIndex);

         enabled = (autotagInfo != null && getCompilerPropertiesForm(autotagInfo.langId) != '');
      } while (false);

      _ctl_add.p_enabled = enabled;
      _ctl_configure.p_enabled = enabled;
      break;
   case CHANGE_CHECK_TOGGLED:
      // we want to treat items under .NET and Xcode as radio buttons - check our category first
      parent := _TreeGetParentIndex(treeIndex);
      if (parent > 0) {
         // compare the caption
         caption := _TreeGetCaption(parent);
         if (caption == DOTNET_COMPILER_CAPTION || caption == XCODE_COMPILER_CAPTION) {
            // go through all the children, make sure only the latest selection is checked
            child := _TreeGetFirstChildIndex(parent);
            while (child > 0) {
               // if this is not our recent selection and it's checked...
               if (child != treeIndex && _TreeGetCheckState(child) == TCB_CHECKED) {
                  // uncheck it!
                  _TreeSetCheckState(child, TCB_UNCHECKED);
               }

               // next, please!
               child = _TreeGetNextSiblingIndex(child);
            }
         }
      }

      break;
   }
}

void _tag_compilers_form.on_resize()
{                                                                                                                
   padding := _ctl_info_html.p_x;
   width := _dx2lx(p_xyscale_mode,p_active_form.p_client_width);
   height := _dy2ly(p_xyscale_mode,p_active_form.p_client_height);

   _ctl_info_html.p_width = _ctl_tagfiles.p_width = _ctl_divider.p_width = width - (2 * padding);
   _ctl_configure.p_x  = width - padding - _ctl_configure.p_width;
   _ctl_add.p_x = _ctl_configure.p_x - padding - _ctl_add.p_width;
   _ctl_help.p_x = width - padding - _ctl_help.p_width;
   _ctl_cancel.p_x = _ctl_help.p_x - padding - _ctl_cancel.p_width;
   _ctl_ok.p_x = _ctl_cancel.p_x - padding - _ctl_ok.p_width;
           
   if (_ctl_ok.p_visible) {
      _ctl_ok.p_y = _ctl_cancel.p_y = _ctl_help.p_y = height - padding - _ctl_ok.p_height;
      _ctl_divider.p_y = _ctl_ok.p_y - padding - _ctl_divider.p_height;
      _ctl_add.p_y = _ctl_configure.p_y = _ctl_divider.p_y - padding - _ctl_configure.p_height;
      _ctl_use_background_thread.p_y = _ctl_divider.p_y - padding - _ctl_use_background_thread.p_height;
   } else {
      _ctl_add.p_y = _ctl_configure.p_y = height - padding - _ctl_configure.p_height;
      _ctl_use_background_thread.p_y = height - padding - _ctl_use_background_thread.p_height;
   }

   _ctl_tagfiles.p_height = _ctl_configure.p_y - padding - _ctl_tagfiles.p_y;
}

_ctl_add.lbutton_up()
{
   autotag_add_new_compiler(_ctl_tagfiles._TreeCurIndex(), p_user);
}

_ctl_configure.lbutton_up()
{
   index := _ctl_tagfiles._TreeCurIndex();
   AUTOTAG_BUILD_INFO autotagInfo = _ctl_tagfiles._TreeGetUserInfo(index);

   // launch the configuration form
   formName := getCompilerPropertiesForm(autotagInfo.langId);
   if (formName != '') {
      config := show("-xy -modal "formName, autotagInfo.configName);

      // maybe reload this section of the tree?
      if (config != '') {
         reloadLangCompilers(_ctl_tagfiles._TreeGetParentIndex(index), autotagInfo.langId, config);
      }
   }
}

_command void autotag_add_new_compiler(int index = 0, _str langId = "") name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Tagging");
      return;
   }
   type := '';
   if (langId != null && langId != "" && _LanguageInheritsFrom("c", langId)) {
      type = C_COMPILER_CAPTION;
   } else if (langId != null && langId != "" && _LanguageInheritsFrom("java", langId)) {
      type = JAVA_COMPILER_CAPTION;

   } else if (index == 0) {
      // get the possible values
      _str choices[];
      choices[0] = C_COMPILER_CAPTION;
      choices[1] = JAVA_COMPILER_CAPTION;

      defaultChoice := C_COMPILER_CAPTION;
      index = _ctl_tagfiles._TreeCurIndex();
      if (_ctl_tagfiles._TreeDoesItemHaveChildren(index)) {
         defaultChoice = _ctl_tagfiles._TreeGetCaption(index);
      } else {
         index = _ctl_tagfiles._TreeGetParentIndex(index);
         if (index > 0) defaultChoice = _ctl_tagfiles._TreeGetCaption(index);
      }

      // prompt for a language
      if (comboBoxDialog("Select compiler type", "Compiler", choices, 0, defaultChoice) != IDOK) {
         return;
      }

      type = _param1;
      index = _ctl_tagfiles._TreeSearch(TREE_ROOT_INDEX, type);
   } else {
      type = _ctl_tagfiles._TreeGetCaption(index);
   }

   config := '';
   switch (type) {
   case C_COMPILER_CAPTION:
      config = add_new_cpp_compiler();
      langId = 'c';
      break;
   case JAVA_COMPILER_CAPTION:
      config = add_new_java_compiler();
      langId = 'java';
      break;
   }

   if (config != '') {
      reloadLangCompilers(index, langId, config);

      // if this section was not already there, then sort again
      if (index == -1) {
         _ctl_tagfiles._TreeSortUserInfo(TREE_ROOT_INDEX, 'N');
      }
   }
}

static void reloadLangCompilers(int sectionIndex, _str langId, _str selection = '')
{
   // if we did not send in a selection, then restore what was selected before,
   // provided it was in this section
   if (selection == '') {
      curIndex := _ctl_tagfiles._TreeCurIndex();
      if (_ctl_tagfiles._TreeGetParentIndex(curIndex) == sectionIndex) {
         selection = _ctl_tagfiles._TreeGetCaption(curIndex);
      }
   }

   // go through and make a list of everything that was checked, so we can restore it later
   int sc, pic;
   bool checked:[];
   if (sectionIndex >= 0) {
      child := _ctl_tagfiles._TreeGetFirstChildIndex(sectionIndex);
      while (child > 0) {

         configName := _ctl_tagfiles._TreeGetCaption(child);
         isChecked  := _ctl_tagfiles._TreeGetCheckState(child);
         checked:[configName] = (isChecked == TCB_CHECKED);

         child = _ctl_tagfiles._TreeGetNextSiblingIndex(child);
      }
   }

   // finally, reload this section
   newSectionIndex := _ctl_tagfiles._loadLangAutoTagChoices(langId, sectionIndex, langId);
   if (newSectionIndex > 0) sectionIndex = newSectionIndex;
   if (sectionIndex <= 0) return;

   // restore everything that was checked
   child := _ctl_tagfiles._TreeGetFirstChildIndex(sectionIndex);
   while (child > 0) {

      configName := _ctl_tagfiles._TreeGetCaption(child);
      if (checked._indexin(configName) && checked:[configName]) {
         _ctl_tagfiles._TreeGetCheckState(child, TCB_CHECKED);
      } else {
         _ctl_tagfiles._TreeGetCheckState(child, TCB_UNCHECKED);
      }

      child = _ctl_tagfiles._TreeGetNextSiblingIndex(child);
   }

   // set the current index
   child = _ctl_tagfiles._TreeSearch(sectionIndex, selection);
   if (child > 0) {
      _ctl_tagfiles._TreeSetCurIndex(child);
   }
}

static _str getCompilerPropertiesForm(_str langId)
{
   result := '';
   switch (langId) {
   case 'c':
      result = '_refactor_c_compiler_properties_form';
      break;
   case 'java':
      result = '_java_compiler_properties_form';
      break;
   }

   return result;
}

