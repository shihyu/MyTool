////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50680 $
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
#import "autosave.e"
#import "backtag.e"
#import "context.e"
#import "diff.e"
#import "fileman.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "javacompilergui.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "makefile.e"
#import "mprompt.e"
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
#import "tags.e"
#import "toast.e"
#import "treeview.e"
#import "util.e"
#import "wkspace.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

#if __UNIX__
   #define  JAR_WILDCARDS "*.class;*.jar;*.zip"
#else
   #define  JAR_WILDCARDS "*.class;*.jar;*.zip"
#endif

#define AUTO_UPDATED_FOLDER_NAME    "Auto-Updated Tag Files"
#define COMPILER_CONFIG_FOLDER_NAME "Compiler Configuration Tag Files"

enum TagReferencesFlags {
   VSREF_FIND_INCREMENTAL     = 0x1,
   VSREF_DO_NOT_GO_TO_FIRST   = 0x2,
   VSREF_NO_WORKSPACE_REFS    = 0x4,
   VSREF_HIGHLIGHT_MATCHES    = 0x8,
   VSREF_SEARCH_WORDS_ANYWAY  = 0x10,
   VSREF_ALLOW_MIXED_LANGUAGES = 0x20,
};

int def_references_options = 0;

//12:20pm 7/3/1997
//Dan added for background/on save tagging
//10:25 10/17/2007
//Sandra moved to tagform.e and changed to enum for use with new options dialog
enum AutotagFlags {
   AUTOTAG_ON_SAVE            = 0x01,        // tag file on save
   AUTOTAG_BUFFERS            = 0x02,        // background tag buffers
// AUTOTAG_PROJECT_ONLY       = 0x04         // background tag project buffers only (OBSOLETE)
   AUTOTAG_FILES              = 0x08,        // background tag all files
   AUTOTAG_SYMBOLS            = 0x10,        // refresh tag window (symbols tab)
   AUTOTAG_FILES_PROJECT_ONLY = 0x20,        // background tag project files only (OBSOLETE)
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
};

defeventtab _tag_form;
void ctlAutoTag.lbutton_up()
{
   int status=autotag();
   if (status!=COMMAND_CANCELLED_RC) {
      // Delete all items in the tree
      tree1._TreeDelete(TREE_ROOT_INDEX,'c');
      ctldone.call_event(ctldone,ON_CREATE);
   }
}

#define TAG_FOLDER_INDEXES ctlfiles.p_user
//This is the indexes of the two folders in the format:
//ProjectFolderIndex' 'GlobalFolderIndex
#define TAGFORM_SKIP_ON_CHANGE tree1.p_user
//SKIP_ON_CHANGE is used if we move a tree item up or down and really don't need
//the on change event.
#define TreeIsEmpty(a) (a._TreeGetFirstChildIndex(TREE_ROOT_INDEX)<0)
#define TAGFORM_FOLDER_DEPTH 1
#define TAGFORM_FILE_DEPTH   2

#define TAGFORM_PROGRESS_THRESHOLD 4000

// bitmap used for references files
int _pic_file_refs = 0;

defload()
{
   _pic_file_refs=_update_picture(-1,'_filexr.ico');
   if (_pic_file_refs < 0) {
      _pic_file_refs = _pic_file;
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
static int LoadFileNameList(_str tag_filename, boolean quiet=false)
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
       file_eq(tag_filename, lastTagFileName) &&
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
   tag_get_detail(VS_TAGDETAIL_num_files, num_files);
   if (!quiet) {
      ctl_files_label.p_caption = get_message(VSRC_CFG_TAG_FILES_LOADING);
      if (num_files > TAGFORM_PROGRESS_THRESHOLD) {
         ctl_files_gauge.p_visible=true;
         ctl_files_gauge.p_value=0;
         ctl_files_gauge.p_max = num_files;
         ctl_files_gauge.p_x = ctl_files_label.p_x + ctl_files_label.p_width + 300;
         ctl_files_gauge.p_width = list1.p_x + list1.p_width - ctl_files_gauge.p_x - 60;
      }
      p_active_form.refresh();
   }

   // get the files from the database
   _str filename;
   status=tag_find_file(filename);
   int count=0;
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
      if (!quiet && ctl_files_gauge.p_visible && (count % 100) == 0) {
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
int _GetBuildingTagFileAlertGroupId(_str tag_filename, boolean generateId=true, boolean removeId=false)
{
   static int activatedAlerts:[];
   if (activatedAlerts._indexin(tag_filename)) {
      id := activatedAlerts:[tag_filename];
      if (removeId) {
         activatedAlerts._deleteel(tag_filename);
      }
      return id;
   }
   if (file_eq(tag_filename, _GetWorkspaceTagsFilename())) {
      return ALERT_TAGGING_WORKSPACE;
   }
   if (!generateId) {
      return STRING_NOT_FOUND_RC;
   }
   static int backgroundTaggingAlertCount;
   alertId := ALERT_TAGGING_BUILD0 + (++backgroundTaggingAlertCount % ALERT_TAGGING_MAX_BUILDS);
   activatedAlerts:[tag_filename] = alertId;
   return alertId;
}

_str _GetBuildingTagFileMessage(boolean useThread=false)
{
   if (useThread) {
      return "Building Tag File... (to be completed in background)";
   }
   return "Building Tag File...";
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
                            boolean rebuild_all=false,
                            //boolean retag_refs=false,
                            boolean doRemove=false,
                            boolean RemoveWithoutPrompting=false,
                            boolean useThread=false,
                            boolean quiet=false,
                            boolean checkAllDates=false,
                            boolean allowCancel=false,
                            boolean skipFilesNotInTagFile=false,
                            boolean KeepWithoutPrompting=false
                            )
{
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
      if (rebuild_all)       rebuildFlags |= VS_TAG_REBUILD_FROM_SCRATCH;
      if (checkAllDates)     rebuildFlags |= VS_TAG_REBUILD_CHECK_DATES;
      if (!rebuild_all)      rebuildFlags |= VS_TAG_REBUILD_CHECK_DATES;
      if (retag_occurrences) rebuildFlags |= VS_TAG_REBUILD_DO_REFS;
      if (doRemove)          rebuildFlags |= VS_TAG_REBUILD_REMOVE_MISSING_FILES;
      status = tag_build_tag_file_from_view(tag_filename, rebuildFlags, p_window_id);
      if (def_tagging_logging) {
         loggingMessage := nls("Starting background tag file update for '%s1'", tag_filename);
         dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      }
      return status;
   }


   boolean IgnoreMissingFile=KeepWithoutPrompting;
   boolean promptAboutNotTaggedFiles=false;
   _str filename, tagging_message;
   int temp_view_id, filelist_view_id;
   int num_files = p_Noflines;
   int not_tagged_count = 0;
   _str not_tagged_list = '';
   boolean not_tagged_more = false;
   top(); up();
   int orig_view_id;
   get_window_id(orig_view_id);

   int orig_use_timers=_use_timers;
   int orig_def_actapp=def_actapp;
   def_actapp=0;
   _use_timers=0;
   activate_window(orig_view_id);
   get_window_id(filelist_view_id);
   int buildform_wid=0;
   int max_label2_width=0;
   _str msg='';
   _str answer='';
   int status=0;

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
         buildform_wid=show_cancel_form(_GetBuildingTagFileMessage(useThread),'',true,true);
      } else {
         buildform_wid=show_cancel_form(_GetBuildingTagFileMessage(useThread),'',false,true);
      }
      max_label2_width=cancel_form_max_label2_width(buildform_wid);
   //}

   while (!down()) {
      if (buildform_wid) {
         if (cancel_form_cancelled()) {
            break;
         }
      }
      // update progress gauge
      int cancelPressed = tagProgressCallback(p_line * 100 intdiv p_Noflines, true);
      if(cancelPressed) break;

      get_line(filename);
      filename=strip(filename/*,'L'*/);
      if (filename=='') continue;
      int current_line = p_line;
      if (buildform_wid) {
         if (cancel_form_progress(buildform_wid,p_line-1,num_files)) {
            _str sfilename=buildform_wid._ShrinkFilename(filename,max_label2_width);
            cancel_form_set_labels(buildform_wid,'Tagging 'p_line'/'num_files':',sfilename);
         }
      }

      // open view of file, try for a buffer first
      temp_view_id=0;
      _str fdate="";
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
   
      _str lang = _Filename2LangId(filename);
      boolean doRemove2=false;
      // file opened cleanly, so retag file and quit view
      if (fdate!="" && fdate!=0) {
         boolean doRetag=false;
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
               boolean inmem;
               status=_open_temp_view(filename,temp_view_id,filelist_view_id,'',inmem,false,true);
               if (status) {
                  doRemove2=true;
               } else {
                  RetagCurrentFile(useThread,!inmem);
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
               boolean removeFile=false;
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
      _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_TAGGING,
                     nls("%s file":+plural:+" ":+verb:+" not tagged ":+
                         "because ":+pronoun:+" could not be opened or do not exist:\n\n%s",
                         not_tagged_count,not_tagged_list),
                     "Tagging", 1);
   }
   activate_window(orig_view_id);

   // that's all folks
   return 0;
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
int _OpenOrCreateTagFile(_str tag_filename, boolean force_create=false,
                         int database_type=VS_DBTYPE_tags, int database_flags=0,
                         boolean quiet=false)
{
   if(tag_filename == '') {
      return -1;
   }
   // try to open the database for read/write
   int status=tag_open_db(tag_filename);
   if (status==FILE_NOT_FOUND_RC || force_create) {
      // need to re-create database, preserve database description
      _str descr = '';
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
      tag_close_db(tag_filename, 1);
      // inform the world about the new database
      if (status==FILE_NOT_FOUND_RC) {
         _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
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
                         boolean force_create,
                         boolean rebuild_all,
                         boolean retag_occurrences,
                         boolean doRemove=false,
                         boolean RemoveWithoutPrompting=false,
                         boolean useThread=false,
                         boolean quiet=false,
                         boolean checkAllDates=false,
                         boolean doDeleteListView=true,
                         boolean allowCancel=false,
                         boolean skipFilesNotInTagFile=false,
                         boolean KeepWithoutPrompting=false)
{
   // If rebuilding the entire database, force a tag_create_db to occur
   // otherwise, just open the file for write, create it if it doesn't exist
   //int database_type = (retag_refs)? VS_DBTYPE_references : VS_DBTYPE_tags;
   int database_type  = VS_DBTYPE_tags;
   int database_flags = (retag_occurrences)? VS_DBFLAG_occurrences:0;
   int status = _OpenOrCreateTagFile(tag_filename,force_create,database_type,database_flags,quiet);
   if (status < 0) {
      if (quiet && status==ACCESS_DENIED_RC) {
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

   // blow away the file list temp view
   if (_iswindow_valid(orig_view_id)) {
      p_window_id = orig_view_id;
   }
   if (doDeleteListView) {
      _delete_temp_view(list_view_id);
   }

   // close the database and check that it was clean
   status = tag_close_db(tag_filename, 1/*leave it open for read*/);
   if (!quiet && status) {
      _message_box(nls("Error closing tags database %s.\n%s",tag_filename,get_message(status)));
   }
   _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,tag_filename);
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);

   // report if any files not found or tagged
   // we are done
   clear_message();
   return(0);
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
                      boolean quiet=false, 
                      boolean tag_occurrences=false,
                      boolean useThread=false)
{
   // check if the new tag file exists already.
   NewTagFilename=absolute(NewTagFilename);
   int status=tag_read_db(NewTagFilename);
   if (status >= 0) {
      //Just assume that this one is ok....
      _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
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
   int orig_focus_wid=0;
   if (_no_child_windows()) {
      orig_focus_wid=_cmdline;
   }
   if (!quiet) {
      // warn about converting the file
      _message_box("About to convert old tag file "OldTagFilename".\nThis may take a minute.");
   }
   if (orig_focus_wid==_cmdline) {
      _cmdline.p_visible=0;
   }

   // create the new tag database
   mou_hour_glass(1);
   delete_file(NewTagFilename);
   status=tag_create_db(NewTagFilename);
   if (status < 0) {
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
      if (orig_focus_wid==_cmdline) {
         _cmdline.p_visible=1;
      }
      if (!quiet) {
         _message_box(nls("Could not create tags database %s.\n%s",NewTagFilename,get_message(status)));
      }
      mou_hour_glass(0);
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
   boolean CorruptTagFile=false;
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
      _str WholeFilename=PathTable[PathIndex]:+filename;
      _str date='';
      status=tag_get_date(WholeFilename,date);
      if (status) {
         //If we do not get a status, we tagged the file already.
         if (!(NoExistList._indexin(WholeFilename))) {
            int source_view_id, junk_view_id;
            boolean inmem=false;
            status=_open_temp_view(WholeFilename,source_view_id,junk_view_id,'',inmem,false,true);
            if (!status) {
               message('Tagging 'WholeFilename);
               RetagCurrentFile(useThread, !inmem);
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
   status=tag_close_db(NewTagFilename,1);
   _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
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
      int ShowDialog=p_Noflines;
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
   mou_hour_glass(0);
   if (orig_focus_wid==_cmdline) {
      _cmdline.p_visible=1;
   }
   return(status);
}

//////////////////////////////////////////////////////////////////////////////
// Insert the given list of tag files into the tag form tree at 'index'
//
static void AddTagFiles(int index,_str TagFileList,boolean useThread=false)
{
   int flags=TREE_ADD_AS_CHILD;
   _str AddedList='';
   _str ext='';
   int status=0;
   for (;;) {
      _str CurTagFilename=next_tag_file2(TagFileList,false/*no check*/,false/*no open*/);
      if (CurTagFilename=='') break;
      _str CurTagDescription='';
      if (!pos(' 'CurTagFilename' ',AddedList,'',_fpos_case)) {
         int bmp_index = _pic_file;
         status=tag_read_db(absolute(CurTagFilename));
         if (status==FILE_NOT_FOUND_RC || status==PATH_NOT_FOUND_RC) {
            bmp_index=_pic_filem;
         } else if (status < 0) {
            ext=_get_extension(CurTagFilename);
            if (file_eq('.'ext,TAG_FILE_EXT)) {
               bmp_index=_pic_file_d;
            } else {
               //Invalid magic number...We assume that it is an old tag file
               _str NewTagFilename=_strip_filename(CurTagFilename,'E'):+TAG_FILE_EXT;
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
            tag_close_db(absolute(CurTagFilename),1);
         }
         CurTagFilename=strip(CurTagFilename,'B','"');
         _str allcaption = (CurTagDescription=='')? CurTagFilename:CurTagFilename' ('CurTagDescription')';
         index=tree1._TreeAddItem(index,   //Relative Index
                                  allcaption,    //Caption
                                  flags, //Flags
                                  bmp_index,         //Collapsed Bitmap Index
                                  bmp_index,         //Expanded Bitmap Index
                                  TREE_NODE_LEAF);               //Initial State
         flags=0;
         tree1._TreeSetInfo(_TreeGetParentIndex(index), TREE_NODE_EXPANDED);
         AddedList=AddedList' 'CurTagFilename' ';
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
static void _GetAutoUpdatedTagFileList(_str (&tag_filename_ht):[])
{
   tag_filename_ht._makeempty();

   if( gWorkspaceHandle < 0 ) {
      return;
   }

   // Insert the auto updated tag files
   int autoUpdatedNodeArray[] = null;
   _WorkspaceGet_TagFileNodes(gWorkspaceHandle, autoUpdatedNodeArray);
   int i;
   for( i = 0; i < autoUpdatedNodeArray._length(); ++i ) {

      // Get the remote tag filename
      int node = autoUpdatedNodeArray[i];
      if( node < 0 ) {
         continue;
      }

      _str autoUpdateTagfile = _AbsoluteToWorkspace(_xmlcfg_get_attribute(gWorkspaceHandle, node, "AutoUpdateFrom"));

      // Get the absolute local tag filename
      _str localTagfile = _AbsoluteToWorkspace(_xmlcfg_get_attribute(gWorkspaceHandle, node, "File"));

      tag_filename_ht:[autoUpdateTagfile] = localTagfile;
   }
}

/**
 * Is the given file an auto-updated tag file?
 * 
 * @return A PATHSEP delimited list of auto update tag files for the current
 * workspace.  Returns '' if there are none.
 */
boolean _IsAutoUpdatedTagFile(_str tagFile)
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
      if (file_eq(autoUpdateTagfile, tagFile)) {
         return true;
      }
   }
   return(false);
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
 * @example  _str show('-xy _tag_form')
 *
 * @categories Forms
 *
 */
ctldone.on_create()
{
   int i,status = 0;

   // restore the position of the vertical divider bar
   typeless xpos = _retrieve_value("_tag_form._divider.p_x");
   if (isuinteger(xpos)) _divider.p_x = xpos;
   _divider.p_user = _divider.p_x;
   ctl_files_label.p_user = "";
   ctl_files_gauge.p_user = "";

   if (_win32s()==1) {
      ctlAutoTag.p_visible=0;
      ctlAutoTag.p_enabled=0;
   }
   _xlat_old_vslicktags();
   int ProjectTagfilesIndex= -1;
   _str ProjectTagsFilename = '';
   if (isEclipsePlugin()) {
      _str wspaceTagfiles = "";
      status = _eclipse_get_projects_tagfiles(wspaceTagfiles);
      ProjectTagfilesIndex=tree1._TreeAddItem(TREE_ROOT_INDEX,    //Relative Index
                                              'Workspace Tag Files',//Caption
                                              TREE_ADD_AS_CHILD,  //Flags
                                              _pic_fldclos,       //Collapsed Bitmap Index
                                              _pic_fldopen,       //Expanded Bitmap Index
                                              TREE_NODE_EXPANDED);                //Initial State
      _str curProjTagfile = "";
      if (wspaceTagfiles != "") {
         parse wspaceTagfiles with curProjTagfile ";"; 
         wspaceTagfiles = substr(wspaceTagfiles,length(curProjTagfile)+2);
         while (curProjTagfile != '') {
            proj_name := _strip_filename(curProjTagfile, "PE");
            int bmp_index = _pic_file;
            _str caption=curProjTagfile;
            status=tag_read_db(curProjTagfile);
            if (status==FILE_NOT_FOUND_RC) {
               bmp_index=_pic_file_d;
            } else if (status >= 0) {
               _str CurTagDescription = tag_get_db_comment();
               if (CurTagDescription!='') {
                  caption=proj_name' ('CurTagDescription')';
               }
               if (tag_get_db_flags() & VS_DBFLAG_occurrences) {
                  bmp_index = _pic_file_refs;
               }
            }
            //We want to always display a project filename
            tree1._TreeAddItem(ProjectTagfilesIndex,   //Relative Index
                               caption,                //ProjectTagsFilename
                               TREE_ADD_AS_CHILD,      //Flags
                               bmp_index,              //Collapsed Bitmap Index
                               bmp_index,              //Expanded Bitmap Index
                               TREE_NODE_LEAF);        //Initial State
            parse wspaceTagfiles with curProjTagfile ";";
            wspaceTagfiles = substr(wspaceTagfiles,length(curProjTagfile)+2);
         }
      }
      // This needs to check _project_name and not _workspace_filename
   } else if (_project_name!="") {
      ProjectTagfilesIndex=tree1._TreeAddItem(TREE_ROOT_INDEX,    //Relative Index
                                              'Workspace Tag File',//Caption
                                              TREE_ADD_AS_CHILD,  //Flags
                                              _pic_fldclos,       //Collapsed Bitmap Index
                                              _pic_fldopen,       //Expanded Bitmap Index
                                              TREE_NODE_EXPANDED);//Initial State
      ProjectTagsFilename=_GetWorkspaceTagsFilename();
      int bmp_index = _pic_file;
      _str Caption=ProjectTagsFilename;
      status=tag_read_db(absolute(ProjectTagsFilename));
      if (status==FILE_NOT_FOUND_RC) {
         bmp_index=_pic_file_d;
      } else if (status >= 0) {
         _str CurTagDescription = tag_get_db_comment();
         if (CurTagDescription!='') {
            Caption=ProjectTagsFilename' ('CurTagDescription')';
         }
         if (tag_get_db_flags() & VS_DBFLAG_occurrences) {
            bmp_index = _pic_file_refs;
         }
      }
      //We want to always display a project filename
      tree1._TreeAddItem(ProjectTagfilesIndex,   //Relative Index
                         Caption,                //ProjectTagsFilename
                         TREE_ADD_AS_CHILD,      //Flags
                         bmp_index,              //Collapsed Bitmap Index
                         bmp_index,              //Expanded Bitmap Index
                         TREE_NODE_LEAF);        //Initial State
   }
   /*
   ReferencesFilesIndex=tree1._TreeAddItem(TREE_ROOT_INDEX,    //Relative Index
                                           'References File',//Caption
                                           TREE_ADD_AS_CHILD,  //Flags
                                           _pic_fldclos,       //Collapsed Bitmap Index
                                           _pic_fldopen,       //Expanded Bitmap Index
                                           -1);                //Initial State
   */
   TAG_FOLDER_INDEXES=ProjectTagfilesIndex;

   // insert folder for automatically updated tag files
   int autoUpdatedTagFilesIndex = -1;
   if(_workspace_filename != ""){
      autoUpdatedTagFilesIndex = tree1._TreeAddItem(TREE_ROOT_INDEX,
                                                    AUTO_UPDATED_FOLDER_NAME,
                                                    TREE_ADD_AS_CHILD,
                                                    _pic_fldclos,
                                                    _pic_fldopen,
                                                    TREE_NODE_EXPANDED);

      _str autoUpdatedTagFilesHt:[];
      _GetAutoUpdatedTagFileList(autoUpdatedTagFilesHt);
      _str autoUpdateTagfile;
      for( autoUpdateTagfile._makeempty();; ) {
         autoUpdatedTagFilesHt._nextel(autoUpdateTagfile);
         if( autoUpdateTagfile._isempty() ) {
            break;
         }
         _str caption = autoUpdateTagfile;
         _str localTagfile = autoUpdatedTagFilesHt:[autoUpdateTagfile];
         int bmp_index = _pic_file;
         status = tag_read_db(localTagfile);
         if( status == FILE_NOT_FOUND_RC || status == PATH_NOT_FOUND_RC ) {
            bmp_index = _pic_file_d;
         } else if( status >=0 ) {
            _str description = tag_get_db_comment();
            if( description != "" ) {
               caption = caption " (" description ")";
            }
            if( tag_get_db_flags() & VS_DBFLAG_occurrences ) {
               bmp_index = _pic_file_refs;
            }
         }

         // Store absolute local filename in user info for the node
         tree1._TreeAddItem(autoUpdatedTagFilesIndex,caption,TREE_ADD_AS_CHILD,bmp_index,bmp_index,TREE_NODE_LEAF,0,localTagfile);
      }
   }
   TAG_FOLDER_INDEXES = TAG_FOLDER_INDEXES " " autoUpdatedTagFilesIndex;

   // get the list of compiler configurations
   _str c_compiler_names[]; c_compiler_names._makeempty();
   _str java_compiler_names[]; java_compiler_names._makeempty();
   refactor_get_compiler_configurations(c_compiler_names, java_compiler_names);

   // insert folder for compiler config tag files
   int compilerTagFilesIndex = -1;
   if(c_compiler_names._length() > 0){
      compilerTagFilesIndex = tree1._TreeAddItem(TREE_ROOT_INDEX,
                                                 '"C" ':+COMPILER_CONFIG_FOLDER_NAME,
                                                 TREE_ADD_AS_CHILD,
                                                 _pic_fldclos,
                                                 _pic_fldopen,
                                                 TREE_NODE_EXPANDED);


      for (i=0; i<c_compiler_names._length(); ++i) {
         _str compilerTagFile=_tagfiles_path():+c_compiler_names[i]:+TAG_FILE_EXT;
         if (!file_exists(compilerTagFile)) {
            continue;
         }

         _str caption = compilerTagFile;
         int bmp_index = _pic_file;
         status = tag_read_db(compilerTagFile);
         if(status == FILE_NOT_FOUND_RC || status == PATH_NOT_FOUND_RC) {
            bmp_index = _pic_file_d;
         } else if(status >= 0) {
            _str description = tag_get_db_comment();
            if(description != "") {
               caption = caption " (" description ")";
            }
            if(tag_get_db_flags() & VS_DBFLAG_occurrences) {
               bmp_index = _pic_file_refs;
            }
         }

         // store absolute local filename in user info for the node
         tree1._TreeAddItem(compilerTagFilesIndex, caption, TREE_ADD_AS_CHILD, bmp_index, bmp_index, TREE_NODE_LEAF, 0, compilerTagFile);
      }
   }

   // add this to the list of tag folder indexes
   TAG_FOLDER_INDEXES = TAG_FOLDER_INDEXES " " compilerTagFilesIndex;

   if(java_compiler_names._length() > 0){
      compilerTagFilesIndex = tree1._TreeAddItem(TREE_ROOT_INDEX,
                                                 '"Java" ':+COMPILER_CONFIG_FOLDER_NAME,
                                                 TREE_ADD_AS_CHILD,
                                                 _pic_fldclos,
                                                 _pic_fldopen,
                                                 TREE_NODE_EXPANDED);


      for (i=0; i<java_compiler_names._length(); ++i) {
         _str compilerTagFile=_tagfiles_path():+java_compiler_names[i]:+TAG_FILE_EXT;
         if (!file_exists(compilerTagFile)) {
            continue;
         }

         _str caption = compilerTagFile;
         int bmp_index = _pic_file;
         status = tag_read_db(compilerTagFile);
         if(status == FILE_NOT_FOUND_RC || status == PATH_NOT_FOUND_RC) {
            bmp_index = _pic_file_d;
         } else if(status >= 0) {
            _str description = tag_get_db_comment();
            if(description != "") {
               caption = caption " (" description ")";
            }
            if(tag_get_db_flags() & VS_DBFLAG_occurrences) {
               bmp_index = _pic_file_refs;
            }
         }

         // store absolute local filename in user info for the node
         tree1._TreeAddItem(compilerTagFilesIndex, caption, TREE_ADD_AS_CHILD, bmp_index, bmp_index, TREE_NODE_LEAF, 0, compilerTagFile);
      }
   }

   // add this to the list of tag folder indexes
   TAG_FOLDER_INDEXES = TAG_FOLDER_INDEXES " " compilerTagFilesIndex;

   // get each of the extension specific tag file lists
   int wid=_form_parent();
   _str CurModeName='';
   if (wid && wid._isEditorCtl()) {
      CurModeName=wid.p_mode_name;
   }

   // add all the TagFiles stored in LanguageSettings
   _str langTagFilesTable:[];
   LanguageSettings.getTagFileListTable(langTagFilesTable);
   foreach (auto langId => auto langTagFileList in langTagFilesTable) {

      mode_name := _LangId2Modename(langId);
      if (_ModenameEQ(mode_name, CurModeName)) {
         // this will tell us that we already handled the current language
         CurModeName = '';
      }

      FilesIndex := tree1._TreeAddItem(TREE_ROOT_INDEX,    //Relative Index
                                       '"'mode_name'" Tag Files',//Caption
                                       TREE_ADD_AS_CHILD,  //Flags
                                       _pic_fldclos,       //Collapsed Bitmap Index
                                       _pic_fldopen,       //Expanded Bitmap Index
                                       TREE_NODE_LEAF);                //Initial State

      TAG_FOLDER_INDEXES = TAG_FOLDER_INDEXES' 'FilesIndex;

      if (FilesIndex>=0) {
         useThread := !(def_autotag_flags2 & AUTOTAG_LANGUAGE_NO_THREADS);
         if (!_is_background_tagging_supported(langId)) useThread = false;
         tree1.AddTagFiles(FilesIndex,_replace_envvars(langTagFileList),useThread);
      }
   }

   // now maybe add one more for the current mode
   if (CurModeName != '') {
      check_and_load_mode_support(CurModeName);
      langId = _Modename2LangId(CurModeName);
      if (_istagging_supported(langId)) {

         FilesIndex := tree1._TreeAddItem(TREE_ROOT_INDEX,    //Relative Index
                                       '"'CurModeName'" Tag Files',//Caption
                                        TREE_ADD_AS_CHILD,  //Flags
                                        _pic_fldclos,       //Collapsed Bitmap Index
                                        _pic_fldopen,       //Expanded Bitmap Index
                                       TREE_NODE_LEAF);                //Initial State

         TAG_FOLDER_INDEXES=TAG_FOLDER_INDEXES' 'FilesIndex;

         CurModeName='';
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

//////////////////////////////////////////////////////////////////////////////
// Get the file name of the tag file in the tree at 'index'
//
static _str GetRealTagFilenameFromTree(int index)
{
   typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
   typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
   parse TAG_FOLDER_INDEXES with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;

   _str TagFilename=_TreeGetCaption(index);
   _str rest='';
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
tree1.on_change(int reason,int index)
{
   if (TAGFORM_SKIP_ON_CHANGE==1) return('');
   int parentIndex=0;
   switch (reason) {
   case CHANGE_SELECTED:
      if (index < 0) return '';
      typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
      typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
      parse TAG_FOLDER_INDEXES with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;
      int depth=tree1._TreeGetDepth(index);
      if(depth==TAGFORM_FILE_DEPTH) {
         // handle auto updated tag files
         if(tree1._TreeGetParentIndex(index) == autoUpdateFilesIndex) {
            // disable all buttons that modify the tagfile
            ctlfiles.p_enabled = ctltree.p_enabled = 0;
            ctlretag_files.p_enabled = ctlremove_files.p_enabled = 0;
            ctlrebuild_tag_file.p_enabled = 0;
            ctlup.p_enabled = ctldown.p_enabled = 1;
            ctlnew_tag_file.p_enabled = ctlremove_tag_file.p_enabled = 1;

            // load files from local copy of tagfile
            mou_hour_glass(1);
            list1.LoadFileNameList(GetRealTagFilenameFromTree(index));
            mou_hour_glass(0);
         } else {
            //Disable the "Remove Src File" button if we are in a workspace
            _str project_tag_files=_GetWorkspaceTagsFilename();
            _str TagFilename=GetRealTagFilenameFromTree(index);
            if (file_eq(TagFilename,project_tag_files)) {
               ctlremove_files.p_enabled=0;
               ctlfiles.p_enabled=0;
               ctltree.p_enabled=0;
            } else {
               ctlremove_files.p_enabled=1;
               ctlfiles.p_enabled=1;
               ctltree.p_enabled=1;
            }
            parentIndex = tree1._TreeGetParentIndex(index);
            TagFilename=GetRealTagFilenameFromTree(index);
            mou_hour_glass(1);
            list1.LoadFileNameList(TagFilename);
            mou_hour_glass(0);

            ctlnew_tag_file.p_enabled=ctldone.p_enabled=1;
            ctlrebuild_tag_file.p_enabled=ctlretag_files.p_enabled=ctloptions.p_enabled=ctldown.p_enabled=ctlup.p_enabled=1;

            // do not allow removal of workspace tag files, auto-generated tag files, or compiler tag files
            ctlremove_tag_file.p_enabled = (parentIndex!=ProjectTagfilesIndex && 
                                            parentIndex!=cppCompilerTagFilesIndex && 
                                            parentIndex!=javaCompilerTagFilesIndex &&
                                            !isTagFileAutoGenerated(TagFilename));
         }
      }else if (depth==TAGFORM_FOLDER_DEPTH) {
         parentIndex=index;
         ctlnew_tag_file.p_enabled=1;
         ctltree.p_enabled=ctlremove_tag_file.p_enabled=ctlfiles.p_enabled=0;
         ctlrebuild_tag_file.p_enabled=ctlretag_files.p_enabled=ctldown.p_enabled=ctlup.p_enabled=0;
         ctl_files_label.p_caption = get_message(VSRC_CFG_TAG_FILES_NONE);
         list1._lbclear();
      }else if (!depth) {
         //Root node.  This means there is nothing in the tree!!!!
         ctltree.p_enabled=ctlremove_tag_file.p_enabled=ctlfiles.p_enabled=0;
         ctlremove_tag_file.p_enabled=ctlremove_files.p_enabled=0;
         ctlrebuild_tag_file.p_enabled=ctlretag_files.p_enabled=ctldown.p_enabled=ctlup.p_enabled=0;
         ctlrebuild_tag_file.p_enabled=ctlretag_files.p_enabled=ctldown.p_enabled=ctlup.p_enabled=0;
         ctl_files_label.p_caption = get_message(VSRC_CFG_TAG_FILES_NONE);
         list1._lbclear();
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
         _mdi.p_child.edit(maybe_quote_filename(filename),EDIT_DEFAULT_FLAGS);
      } else {
         message(nls('Can not locate source code for %s.',filename));
      }
   }
}

_str _GetWorkspaceTagsFilename()
{
   if (_workspace_filename=='') return('');
   _str workspace_filename=_workspace_filename;
   _str workspace_tag_files=_strip_filename(workspace_filename,'E'):+TAG_FILE_EXT;
   return(workspace_tag_files);
}

//////////////////////////////////////////////////////////////////////////////
// Is a tag file currently selected in the tag form tree?
//
static boolean FileIsSelected()
{
   int index=tree1._TreeCurIndex();
   int depth=tree1._TreeGetDepth(index);
   return(depth==TAGFORM_FILE_DEPTH);
}

//////////////////////////////////////////////////////////////////////////////
// Add a new(currently non-existant) file
// 9:43am 6/24/1999
// Needed this for workspace stuff(DWH)
int tag_add_new_file(_str TagFilename, _str filename,
                     _str ProjectName=_project_name,
                     boolean AddToProject=true,
                     boolean useThread=false)
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
   boolean retag_occurrences = (def_references_options & VSREF_NO_WORKSPACE_REFS)==0;
   RetagFilesInTagFile2(TagFilename,
                        orig_view_id, list_view_id,
                        false, false, retag_occurrences,
                        false, false, useThread,
                        true, false, false, false, false, true);

   // get the project tags file name, and add files to project if needed
   if (AddToProject) {
      AddFileListToProjectFiles(ProjectName,maybe_quote_filename(filename),0,false,false);
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
                     boolean AddFilesToProject=true,
                     boolean FileExistsOnDisk=true,
                     boolean useThread=false)
{
   int orig_view_id;
   get_window_id(orig_view_id);  // This can be the list view id!


   // Tag the files in the temporary view and close out the view
   p_window_id = filelist_view_id;
   top(); up();
   boolean retag_occurrences = (def_references_options & VSREF_NO_WORKSPACE_REFS)==0;
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
   _str project_tag_files=project_tags_filename();
   if (file_eq(TagFilename,project_tag_files) && AddFilesToProject) {
      AddFileListToProjectFiles(ProjectName,'',filelist_view_id);
   }
   activate_window(orig_view_id);
   _delete_temp_view(filelist_view_id);
   return(0);
}
//////////////////////////////////////////////////////////////////////////////
// Add tags from the given list of files to the given tag file
//
int tag_add_filelist(_str TagFilename,_str filelist,
                     _str ProjectName=_project_name,
                     boolean useThread=false)
{
   // create a temporary view
   int list_view_id;
   int orig_view_id = _create_temp_view(list_view_id);
   if (orig_view_id == '') {
      return(COMMAND_CANCELLED_RC);
   }

   // add files from the given file list to the tag file
   _str wildcard, filename;
   for (;;) {
      wildcard=parse_file(filelist,false);
      if (wildcard=='') break;
      int ff=1;
      for (;;) {
         filename=file_match2(wildcard,ff,'-p');ff=0;
         if (filename=='') {
            break;
         }
         insert_line(filename);
      }
   }
   p_window_id=orig_view_id;
   return(tag_add_viewlist(TagFilename,list_view_id,ProjectName,true,true,useThread));
}

//////////////////////////////////////////////////////////////////////////////
//  Handle 'add files' button press or menu selection
//
void ctlfiles.lbutton_up()
{
   if (!FileIsSelected()) return;
   //TagFilename=tree1._TreeGetCaption(tree1._TreeCurIndex());
   _str TagFilename=tree1.GetRealTagFilenameFromTree(tree1._TreeCurIndex());
   _str TagDir=_strip_filename(TagFilename,'N');
   _str olddir=getcwd();


   // Only change to Tag file directory when we're about to add files
   // to the project tag file.
   isWorkspaceTagFile := false;
   if (file_eq(TagFilename,_GetWorkspaceTagsFilename())) {
      chdir(TagDir,1);
      isWorkspaceTagFile = true;
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
                      EXTRA_FILE_FILTERS','def_file_types,
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
   int index=tree1._TreeCurIndex();
   if (index>=0) {
      tree1.call_event(CHANGE_SELECTED,index,tree1,ON_CHANGE,'W');
   }
   mou_hour_glass(0);
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
                                     boolean list_box_format=false,
                                     boolean FileExistsOnDisk=true)
{
   int status=0;
   _str line='';
   if (_IsWorkspaceAssociated(_workspace_filename) &&
       _IsAddDeleteSupportedWorkspaceFilename(_workspace_filename) &&
       _CanWriteFileSection( GetProjectDisplayName(project_filename) ) ) {
      if (list_view_id) {
         int orig_view_id=p_window_id;
         p_window_id=list_view_id;
         top();up();
         while (!down()) {
            get_line(line);
            if (list_box_format) {
               line=substr(line,2);
            }
            filelist=filelist' 'maybe_quote_filename(line);
         }
         p_window_id=orig_view_id;
      }

      // check the project type
      if(file_eq(_get_extension(GetProjectDisplayName(project_filename), true), JBUILDER_PROJECT_EXT)) {
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
   int handle=_ProjectHandle(project_filename);
   /*
      Get all the files from XML project file into a view
      Add the new files to the view if not already present
      sort the view
      re-add all files to the folders of XML project file
   */
   int orig_view_id=p_window_id;

   int old_array_size=_default_option(VSOPTION_WARNING_ARRAY_SIZE);
   _default_option(VSOPTION_WARNING_ARRAY_SIZE,MAXINT);

   //filelist=result;
   if (list_view_id) {
      activate_window(list_view_id);
      top();up();
   }
   _str filename='';
   _str NewFilesList[];
   _str project_path=_strip_filename(project_filename,'N');
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
      mou_hour_glass(0);
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

int _workspace_update_files_retag(boolean rebuild_all=false,
                                  boolean doRemove=false,
                                  boolean RemoveWithoutPrompting=false,
                                  boolean quiet=false,
                                  boolean tag_occurrences=false,
                                  boolean checkAllDates=false,
                                  boolean useThread=false,
                                  boolean allowCancel=false,
                                  boolean KeepWithoutPrompting=false)
{
   // Create a temporary view containing the files in the workspace
   if (_workspace_filename=='') {
      return VSRC_FF_COULD_NOT_OPEN_WORKSPACE_FILE;
   }

   _str workspace_tag_file = _GetWorkspaceTagsFilename();
   if (useThread && (RemoveWithoutPrompting || KeepWithoutPrompting)) {
      rebuildFlags := 0;
      if (rebuild_all)     rebuildFlags |= VS_TAG_REBUILD_FROM_SCRATCH;
      if (!rebuild_all)    rebuildFlags |= VS_TAG_REBUILD_CHECK_DATES;
      if (checkAllDates)   rebuildFlags |= VS_TAG_REBUILD_CHECK_DATES;
      if (tag_occurrences) rebuildFlags |= VS_TAG_REBUILD_DO_REFS;
      if (doRemove)        rebuildFlags |= VS_TAG_REBUILD_REMOVE_MISSING_FILES;
      if (doRemove)        rebuildFlags |= VS_TAG_REBUILD_REMOVE_LEFTOVER_FILES;
      call_list("_LoadBackgroundTaggingSettings");
      status := tag_build_workspace_tag_file(_workspace_filename, workspace_tag_file, rebuildFlags);
      if (status == 0) {
         _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING_WORKSPACE, 'Updating workspace tag file', '', 1);
      }
      if (def_tagging_logging) {
         loggingMessage := nls("Starting background tag file update for workspace tag file '%s1'", workspace_tag_file);
         dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      }
      return status;
   }

   mou_hour_glass(1);
   int orig_view_id=p_window_id;
   //int status=GetProjectFiles(_project_name, temp_view_id);

   _str ProjectFilenames[];
   int status=_GetWorkspaceFiles(_workspace_filename,ProjectFilenames);
   if (status) {
      mou_hour_glass(0);
      return status;
   }
   int temp_view_id;
   _create_temp_view(temp_view_id);
   int i;
   for (i=0;i<ProjectFilenames._length();++i) {
      GetProjectFiles(_AbsoluteToWorkspace(ProjectFilenames[i]),temp_view_id,'',null,'',false,true);
   }

   // check if there are no or very few tag files,
   // special case of removing all files optimization
   p_window_id = temp_view_id;
   if (p_Noflines <= 1) {
      rebuild_all = true;
   }

   // open, or create from scratch the tag file
   int database_flags = (def_references_options & VSREF_NO_WORKSPACE_REFS)? 0:VS_DBFLAG_occurrences;
   status = _OpenOrCreateTagFile(workspace_tag_file, false,
                                 VS_DBTYPE_tags, database_flags);
   // check for database corruption
   if (status == BT_DATABASE_CORRUPT_RC) {
      // database is corrupted so delete it
      if(delete_file(workspace_tag_file) == 0) {
         // deletion was successful so call the create function again
         status = _OpenOrCreateTagFile(workspace_tag_file, false,
                                       VS_DBTYPE_tags, database_flags);
      }
   }

   if (status < 0) {
      mou_hour_glass(0);
      return status;
   }
 
   // iterate through the files in the database and remove files not
   // found in the project file
   if (!rebuild_all) {
/* 
      typeless p1,p2,p3,p4;
      save_search(p1,p2,p3,p4);
      p_window_id=temp_view_id;
      sort_buffer('-f');
      _str prev_filename='';
      _str filename='';
      status = tag_find_file(filename);
      while (!status) {
         top();
         status=search('^'_escape_re_chars(filename)'$','@rh'_fpos_case);
         if (status) {
            // file is not in the project
            message('Removing 'filename' from 'workspace_tag_file);
            tag_remove_from_file(filename, 1);
            status=tag_find_file(filename,prev_filename);
            continue;
         } else {
            prev_filename=filename;
         }
         status = tag_next_file(filename);
      }
      tag_close_db(workspace_tag_file,1);
      restore_search(p1,p2,p3,p4);
*/
      // 20090403 - previous method does not scale well for large workspaces > 10k files.  LB
      message('Updating files from 'workspace_tag_file);
      p_window_id = temp_view_id;
      sort_buffer('-f u');
      top();
     
      _str filename = '';
      int tag_view_id;
      _create_temp_view(tag_view_id);
      status = tag_find_file(filename);
      while (!status) {
         insert_line(filename);
         status = tag_next_file(filename);
      }
      tag_reset_find_file();
      sort_buffer('-f');
      top();

      // compare sorted filelists from workspace (temp_view_id) and tagfile (tags_view_id)
      _str tag_filename = '';
      int fcmp = 0;
      status = 0;
      while (!status) {
         if (fcmp <= 0) {
            p_window_id = temp_view_id;
            get_line(filename);
         }
         p_window_id = tag_view_id;
         if (fcmp >= 0) {
            get_line(tag_filename);
         }
         fcmp = file_eq(filename, tag_filename)? 0:1;
         if (fcmp != 0) {
            if (lowcase(filename) < lowcase(tag_filename)) {
               fcmp = -1;
            } else {
               fcmp = 1;
            }
         }
         if (fcmp == 0) {
            _delete_line();   // remove matching lines from tag_view_id
         }
         if (fcmp > 0) {      // skip to next tagfilename
            status = down();  
         } else {             // else skip to next workspace filename
            p_window_id = temp_view_id;
            status = down();
         }
      }
      // remove any remaining filenames in tag_view_id
      p_window_id = tag_view_id;
      top();
      status = 0;
      while (!status) {
         get_line(filename);
         if (filename != '') {
            tag_remove_from_file(filename);
         }
         status = down();
      }
      p_window_id = temp_view_id;
      _delete_temp_view(tag_view_id);
   }

   // Tag/retag all the files in the project
   p_window_id=temp_view_id;
   p_line=0;
   //_delete_temp_view(temp_view_id);
   RetagFilesInTagFile2(workspace_tag_file, 
                        orig_view_id, temp_view_id,
                        rebuild_all, rebuild_all, tag_occurrences,
                        doRemove, RemoveWithoutPrompting,
                        useThread, quiet,
                        checkAllDates, true, allowCancel,
                        false, KeepWithoutPrompting);
   if (_iswindow_valid(orig_view_id)) activate_window(orig_view_id);

   // that's all folks
   clear_message();
   mou_hour_glass(0);
   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// Retag the files int the current 'primary' project tag file
//
void _project_update_files_retag(boolean rebuild_all=false,
                                 boolean doRemove=false,
                                 boolean RemoveWithoutPrompting=false,
                                 boolean quiet=false)
{
   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   _workspace_update_files_retag(rebuild_all,
                                 doRemove, RemoveWithoutPrompting,
                                 quiet, false, false, useThread);
}

//////////////////////////////////////////////////////////////////////////////
// Handle pressing of 'rebuild tag file' button.  Prompt to ask if
// only modified files should be retagged, or all files.
//
int ctlrebuild_tag_file.lbutton_up()
{
   // is a tag file selected?
   int index=tree1._TreeCurIndex();
   if (tree1._TreeGetDepth(index)!=TAGFORM_FILE_DEPTH) return(0);

   // get tag file name
   _str ProjectTagFilename=_GetWorkspaceTagsFilename();
   _str TagFilename=tree1.GetRealTagFilenameFromTree(index);

   // Is this a references file?
   typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
   typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
   parse TAG_FOLDER_INDEXES with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;

   // rebuild the database from scratch if it is out of date
   boolean rebuild_all = false;
   boolean RemoveWithoutPrompting=false;
   boolean KeepWithoutPrompting=false;
   boolean tag_occurrences=false;
   boolean isWorkspaceTagFile = file_eq(TagFilename,ProjectTagFilename);
   int status = tag_read_db(TagFilename);
   if (status < 0 || tag_current_version()<VS_TAG_LATEST_VERSION) {
      rebuild_all = true;
      RemoveWithoutPrompting=true;
      KeepWithoutPrompting=true;
   }
   //say("ctlrebuild_tag_file.lbutton_up: status="status" flags="tag_get_db_flags()" file="tag_current_db());
   int orig_db_flags = tag_get_db_flags();
   if (status >= 0 && (orig_db_flags & VS_DBFLAG_occurrences)) {
      tag_occurrences=true;
   }

   // If they select to retag all files, not just modified, force a rebuild
   useThread := true;
   if (!rebuild_all) {
      typeless result=show('-modal _rebuild_tag_file_form',rebuild_all,tag_occurrences,false,false,isWorkspaceTagFile,useThread);
      if (result=="") {
         return(COMMAND_CANCELLED_RC);
      }
      rebuild_all=!_param1;
      RemoveWithoutPrompting=_param2;
      tag_occurrences=_param3;
      KeepWithoutPrompting=true;
      useThread = useThread && (_param5 != 0);

      // Instead of rebuilding Auto-Generated language tag files from scratch,
      // try to use MaybeBuildTagFile() to re-generate the tag file.
      // This way we pick up any new files or file specifications. 
      if (rebuild_all && isTagFileAutoGenerated(TagFilename) &&
          RemoveWithoutPrompting && KeepWithoutPrompting) {
         // Figure out the language mode for this tag file
         FolderIndex:=tree1._TreeGetParentIndex(index);
         mode_name:='';
         parse tree1._TreeGetCaption(FolderIndex) with '"'mode_name'"';
         _message_box("caption="tree1._TreeGetCaption(FolderIndex));
         lang:=_Modename2LangId(mode_name);
         if (lang != "") {
            // Make a copy of the tag file, in case if it doesn't regenerate
            tag_close_db(TagFilename, false);
            copy_file(TagFilename,TagFilename".bak");
            delete_file(TagFilename);
            // Try to generate the tag file
            MaybeBuildTagFile(lang,tag_occurrences);
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
   int bmp_index=(tag_occurrences)? _pic_file_refs:_pic_file;

   // if the current tag file is the primrary project file,
   // use techniques to stay in sync with project file
   // automatically rebuild it if it is corrupt
   int database_flags=(tag_occurrences)? VS_DBFLAG_occurrences:0;
   if (isWorkspaceTagFile) {
      if (status==BT_INCORRECT_MAGIC_RC) {
         status = _OpenOrCreateTagFile(TagFilename, true, VS_DBTYPE_tags, database_flags);
         if (status >= 0) {
            status = tag_read_db(TagFilename);
         }
      }
      int orig_view_id;
      get_window_id(orig_view_id);
      status = _workspace_update_files_retag(rebuild_all,
                                             true, RemoveWithoutPrompting,
                                             false, tag_occurrences, 
                                             false, useThread, 
                                             false, KeepWithoutPrompting);
      if (status < 0) {
         _message_box("Error retagging workspace: "get_message(status, TagFilename));
      }
      if (_iswindow_valid(orig_view_id)) {
         activate_window(orig_view_id);
         tree1.call_event(CHANGE_SELECTED,index,tree1,ON_CHANGE,'W');
         tree1._TreeSetInfo(index,TREE_NODE_LEAF,bmp_index,bmp_index);
         tree1._TreeRefresh();
      }
      toolbarUpdateWorkspaceList();
      return(0);
   }

   // ready to do some serious tagging, first get files from database
   mou_hour_glass(1);
   int orig_wid=p_window_id;
   RetagFilesInTagFile(TagFilename, 
                       rebuild_all, tag_occurrences,
                       true, RemoveWithoutPrompting, useThread, 
                       false, false, false, KeepWithoutPrompting);
   p_window_id=orig_wid;

   // maybe change the bitmap for this item
   tree1._TreeSetInfo(index,TREE_NODE_LEAF,bmp_index,bmp_index);
   tree1._TreeRefresh();

   // final cleanup and we are done
   clear_message();
   tree1.call_event(CHANGE_SELECTED,index,tree1,ON_CHANGE,'W');
   toolbarUpdateWorkspaceList();
   mou_hour_glass(0);
   return(0);
}

int RetagFilesInTagFile(_str tag_filename,
                        boolean rebuild_all,
                        boolean retag_occurrences,
                        boolean doRemove=false,
                        boolean RemoveWithoutPrompting=false,
                        boolean useThread=false,
                        boolean quiet=false,
                        boolean checkAllDates=false,
                        boolean allowCancel=false,
                        boolean KeepWithoutPrompting=false
                        )
{
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
         _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_TAGGING_ERROR, msg, 'Tagging', 1);
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
   mou_hour_glass(0);
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
int ctlretag_files.lbutton_up()
{
   // find the selected tag file
   int index=tree1._TreeCurIndex();
   if (tree1._TreeGetDepth(index)!=TAGFORM_FILE_DEPTH) return(0);
   _str TagFilename=tree1.GetRealTagFilenameFromTree(index);
   typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
   typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
   parse TAG_FOLDER_INDEXES with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;

   // nothing to do if there are no files to tag
   if (list1.p_Noflines <= 0) {
      _message_box("No files to retag");
      return(0);
   }

   // no files selected, ask if they want to retag everything
   int status=0;
   boolean rebuild_all=false;
   if (list1.p_Nofselected == 0) {
      status=_message_box("No files selected.  Do you want to retag all files?",'',MB_YESNOCANCEL|MB_ICONQUESTION);
      if (status!=IDYES) {
         return(COMMAND_CANCELLED_RC);
      }
      list1._lbselect_all();
      rebuild_all=true;
   }

   // create a temporary view to hold names of files to be retagged
   mou_hour_glass(1);
   int list1_wid = list1.p_window_id;
   int list_view_id;
   int orig_view_id = _create_temp_view(list_view_id);
   if (orig_view_id == '') {
      return (COMMAND_CANCELLED_RC);
   }

   // transfer selected files to the temporary view
   status=list1_wid._lbfind_selected(true);
   while (!status) {
      insert_line(strip(list1_wid._lbget_text()));
      status = list1_wid._lbfind_selected(false);
   }

   // Check if the tag database requires tagging occurrences
   boolean retag_occurrences = false;
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
   mou_hour_glass(0);
   return(0);
}

//////////////////////////////////////////////////////////////////////////////
// Get the wildcards for the given tag file
// The current object is the tag files form.
// Returns true if the current tag file is a references database.
//
boolean _GetWildcardsForTagFile(boolean getFromTree,_str &wildcards,_str &mode_name="")
{
   if (getFromTree) {
      wildcards = _default_c_wildcards();
      // Check if tree is selected, and chdir to directory containing tag file
      int index=tree1._TreeCurIndex();
      if (tree1._TreeGetDepth(index)==TAGFORM_FILE_DEPTH) {
         index = tree1._TreeGetParentIndex(index);
      }
      typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
      typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
      parse TAG_FOLDER_INDEXES with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;

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
         int paren_i=lastpos('(',def_file_types,i);
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
void ctltree.lbutton_up()
{
   // Check if tree is selected, and chdir to directory containing tag file
   int index=tree1._TreeCurIndex();
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
   _str TagDir=_strip_filename(TagFilename,'N');
   _str olddir=getcwd();
   chdir(TagDir,1);
   typeless orig_def_file_types=def_file_types;
   def_file_types=EXTRA_FILE_FILTERS','def_file_types;

   result := show('-modal _project_add_tree_or_wildcard_form',
                  'Add Tree',           // title
                  wildcards,            // filespec
                  (mode_name==''),      // attempt retrieval
                  true,                 // use excludes
                  '',                   // project name
                  false);               // show wildcard checkbox

   def_file_types=orig_def_file_types;
   chdir(olddir,1);
   if (result=='') {
      clear_message();
      return;
   }

   addFilesToTagFile(TagFilename, _param1, _param4, _param2, _param3, useThread);

   _param1._makeempty();
   _param4._makeempty();
   // update the list of files, that's all
   index=tree1._TreeCurIndex();
   if (index>=0) {
      tree1.call_event(CHANGE_SELECTED,index,tree1,ON_CHANGE,'W');
   }
}

static void addFilesToTagFile(_str TagFilename, _str (&includePaths)[], _str (&exclusions)[], boolean doRecurse, boolean followSymlinks, boolean useThread)
{
   mou_hour_glass(1);
   message('SlickEdit is finding all files in tree');

   recursive := doRecurse ? '+t' : '-t';
   OptimizeStats := followSymlinks ? '' : '+o';

   int formwid=p_active_form;
   int filelist_view_id;
   int orig_view_id=_create_temp_view(filelist_view_id);
   p_window_id=filelist_view_id;

   _str all_files='';
   for (i := 0; i < includePaths._length(); ++i) {
      file := maybe_quote_filename(strip(absolute(includePaths[i]),'B','"'));
      all_files = all_files ' ' file;
   }

   if (exclusions._length() > 0) {
      all_files = all_files' -exclude';
      for (i = 0; i < exclusions._length(); ++i) {
         _str file = maybe_quote_filename(strip(exclusions[i], 'B', '"'));
         all_files = all_files' 'file;
      }
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

   mou_hour_glass(0);
   clear_message();
}

//////////////////////////////////////////////////////////////////////////////
// handle resizing form, moving vertical divider between tag files
// on the left and source files on the left.
//
_divider.lbutton_down()
{
   _ul2_image_sizebar_handler(ctldone.p_width, list1.p_x+list1.p_width-ctldone.p_width);
}

//////////////////////////////////////////////////////////////////////////////
// Handle form resizing
//
_tag_form.on_resize()
{
   orig_list_x := list1.p_x;
   tree1.p_width=_divider.p_x-tree1.p_x;
   list1.p_x=_divider.p_x+_divider.p_width;
   list1.p_width=_dx2lx(SM_TWIP,p_active_form.p_client_width)-list1.p_x;
   ctl_files_label.p_x += (list1.p_x - orig_list_x);
   ctl_files_gauge.p_x += (list1.p_x - orig_list_x);
   ctl_files_gauge.p_width = list1.p_x + list1.p_width - ctl_files_gauge.p_x - tree1.p_x; 

   ctlnew_tag_file.p_visible=ctldone.p_visible=ctltree.p_visible=ctlremove_tag_file.p_visible=ctlremove_files.p_visible=ctlfiles.p_visible=0;
   ctlrebuild_tag_file.p_visible=ctlretag_files.p_visible=ctloptions.p_visible=ctldown.p_visible=ctlup.p_visible=ctlAutoTag.p_visible=0;

   ctlfiles.p_y=_dy2ly(SM_TWIP,p_active_form.p_client_height)-((ctlfiles.p_height+75) + (ctlup.p_height+75));
   ctloptions.p_y=ctldone.p_y=ctltree.p_y=ctlremove_tag_file.p_y=ctlremove_files.p_y=ctlfiles.p_y;
   ctlnew_tag_file.p_y=ctlrebuild_tag_file.p_y=ctlretag_files.p_y=ctldown.p_y=ctlup.p_y=ctlAutoTag.p_y=ctlfiles.p_y+ctlfiles.p_height+75;
   tree1.p_height=list1.p_height=_divider.p_height=(ctlfiles.p_y-100)-tree1.p_y;

   ctlnew_tag_file.p_visible=ctldone.p_visible=ctltree.p_visible=ctlremove_tag_file.p_visible=ctlremove_files.p_visible=ctlfiles.p_visible=1;
   ctlrebuild_tag_file.p_visible=ctlretag_files.p_visible=ctloptions.p_visible=ctldown.p_visible=ctlup.p_visible=ctlAutoTag.p_visible=1;
}

//////////////////////////////////////////////////////////////////////////////
// get the list of tag files under the given folder
//
static _str GetFolderFileList(int ParentIndex,_str OmitList='')
{
   int index=tree1._TreeGetFirstChildIndex(ParentIndex);
   _str str='';
   for (;;) {
      if (index<0) break;
      _str filename=tree1._TreeGetCaption(index);
      _str rest='';
      parse filename with filename ' (' rest ')';
      if (str=='') {
         str=filename;
      }else{
         str=str:+PATHSEP:+filename;
      }
      index=tree1._TreeGetNextSiblingIndex(index);
   }
   //We don't want to put anything in if it is just the project tags filename
   if (file_eq(str,_GetWorkspaceTagsFilename())) str='';
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
   parse TAG_FOLDER_INDEXES with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;
   if (index<0) {
      //SetProjectTags();
      for (;;) {
         typeless temp_index;
         parse extFilesIndexList with temp_index extFilesIndexList;
         if (temp_index=='') {
            break;
         }
         SetExtensionTagFiles(temp_index);
      }
   } else if(index==ProjectTagfilesIndex){
      //SetProjectTags();
   } else if(index == autoUpdateFilesIndex) {
      SetAutoUpdateTagFiles(index);
   } else if (index == cppCompilerTagFilesIndex || index == javaCompilerTagFilesIndex) {
      // do nothing for compiler configurations
   } else {
      SetExtensionTagFiles(index);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Store the list of extension specific tag files for the given folder
//
static void SetExtensionTagFiles(int index)
{
   _str list=GetFolderFileList(index);
   _str mode_name='';
   parse tree1._TreeGetCaption(index) with '"'mode_name'"';
   _str lang=_Modename2LangId(mode_name);
                     
   LanguageSettings.setTagFileList(lang, list);
}

#if 0
//////////////////////////////////////////////////////////////////////////////
// Store the project tag files list
//
static int SetProjectTags()
{
   if (_project_name=='') return(0);
   parse TAG_FOLDER_INDEXES with ProjectTagfilesIndex autoUpdateFilesIndex compilerTagFilesIndex extFilesIndexList;
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

   int childIndex = tree1._TreeGetFirstChildIndex(index);
   for(;;) {
      if(childIndex < 0) break;
      // get local and remote filenames
      _str local = tree1._TreeGetUserInfo(childIndex);
      _str remote = tree1._TreeGetCaption(childIndex);

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
ctlremove_tag_file.lbutton_up()
{
   typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
   typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
   parse TAG_FOLDER_INDEXES with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;

   // check that a tag file is selected
   int index=tree1._TreeCurIndex();
   int depth=tree1._TreeGetDepth(index);
   if (depth!=TAGFORM_FILE_DEPTH) return(0);
   int FolderIndex=tree1._TreeGetParentIndex(index);
   _str TagFilename=tree1.GetRealTagFilenameFromTree(index);

   boolean promptToDelete, doDelete;
   if (FolderIndex == autoUpdateFilesIndex) {
      promptToDelete = false;
      doDelete = true;
   } else if (!file_exists(TagFilename)) {
      promptToDelete = false;
      doDelete = false;
   } else {
      promptToDelete = true;
   }

   result := checkBoxDialog('Remove Tag File', 
                            nls("Do you wish to remove the file %s from your tag file list?", TagFilename), 
                            promptToDelete ? "Delete file from disk" : "", MB_YESNO, 0, 'deleteTagFile');

   if (promptToDelete) {
      doDelete = _param1;
   }

   if (result==IDYES) {
      // Yes this must be tag_close_db and not tag_close_db2
      tag_close_db(TagFilename);
   } else {
      return('');
   }

   if(doDelete) {
      // make sure it is not read only
#if __UNIX__
   chmod("\"u+w g+w o+w\" " maybe_quote_filename(TagFilename));
#else
   chmod("-r " maybe_quote_filename(TagFilename));
#endif

      int status=recycle_file(TagFilename);
      if (status && status!=FILE_NOT_FOUND_RC) {
         _message_box(nls("Could not delete file %s",TagFilename));
      }
      // Tell Eclipse that we removed a tagfile
      if (isEclipsePlugin()) {
         _str proj = "";
         _eclipse_get_active_project_name(proj);
         if (proj != "") {
            _eclipse_update_tag_list(proj);
         }
      }
   }

   // remove the file from the tree and update the file list
   tree1._TreeDelete(index);
   index=tree1._TreeCurIndex();
   if (index>=0) {
      tree1.call_event(CHANGE_SELECTED,index,tree1,ON_CHANGE,'W');
   }

   // That's all folks.
   SetTagFiles(FolderIndex);
   _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,TagFilename,'R');
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
}

//////////////////////////////////////////////////////////////////////////////
// Remove selected files from the list for tags files
//
int tag_remove_filelist(_str TagFilename,_str FileList,boolean CacheProjects_TagFileAlreadyOpen=false)
{
   if (!CacheProjects_TagFileAlreadyOpen) {
      mou_hour_glass(1);
   }
   int status=tag_open_db(TagFilename);
   if (status < 0) {
      _message_box(nls("Unable to open tag file %s",TagFilename));

      // Could get tag file not found here
      // Lets continue any way

      //mou_hour_glass(0);
      //return(status);
   }
   if (!status) {
      _str list=FileList;
      for (;;) {
         _str dqfilename=parse_file(list);
         if (dqfilename=='') {
            break;
         }
         _str filename=strip(dqfilename,'B','"');
         message('Removing 'filename' from 'TagFilename);
         status = tag_remove_from_file(filename);
      }
      _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      tag_close_db('',1);
   }
   //tag_flush_db();
   clear_message();
   if (!CacheProjects_TagFileAlreadyOpen) {
      mou_hour_glass(0);
   }
   return(0);
}

//////////////////////////////////////////////////////////////////////////////
// Remove selected files from the current tag file
//
void ctlremove_files.lbutton_up()
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
   result := _message_box(nls("Are you sure you wish to remove all selected files from %s?",TagFilename),
                           '',MB_YESNOCANCEL|MB_ICONQUESTION);
   if (result!=IDYES) return;

   // determine if we should do this in the background or not
   useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
   rebuildFlags := 0;

   // make sure that we can write to the tags database
   status := tag_open_db(TagFilename);
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
      _str filename=strip(list1_wid._lbget_text());
      LBFiles[LBFiles._length()]=filename;
      status=list1_wid._lbfind_selected(false);
   }

   //  report the progress removing the files from the tag file
   if (useThread) {
      message('Removing 'LBFiles._length()' files from "'TagFilename'" in background');
   } else {
      message('Removing 'LBFiles._length()' files from "'TagFilename'"');
      // open the tag database for read-write
      rebuildFlags = VS_TAG_REBUILD_SYNCHRONOUS;
      mou_hour_glass(1);
   }

   // call generic function to remove the files
   tag_remove_files_from_tag_file_in_array(TagFilename, rebuildFlags, LBFiles);
   if (def_tagging_logging) {
      loggingMessage := nls("Removing %s2 files from tag file '%s1'", TagFilename, LBFiles._length());
      dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
   }

   // if the work was done in the foreground, we can report results immediately.
   tag_close_db(TagFilename,1);
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
      mou_hour_glass(0);
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
   int wid=_find_formobj('_tag_window_form','N');
   if (wid) {
      _nocheck _control ctltagname;
      wid.ctltagname.call_event(CHANGE_OTHER,wid.ctltagname,ON_CHANGE,"W");
   }

   // check any auto-updated tagfiles in this workspace
   check_autoupdated_tagfiles();

   // save the position of the vertical divider bar
   _append_retrieve(0,_divider.p_x,"_tag_form._divider.p_x");
}

//////////////////////////////////////////////////////////////////////////////
// Returns tree index if it exists, otherwise returns -1
//    Item        -- caption of item to search for
//    ParentIndex -- index to search under
//    Options     -- -F means match Item using _fpos_case
//
static int ItemInTree(_str Item,int ParentIndex,_str Options='')
{
   int index=tree1._TreeGetFirstChildIndex(ParentIndex);
   _str str='';
   boolean FileOption=false;
   for (;;) {
      _str CurOp=parse_file(Options);
      if (CurOp=='') break;
      if (upcase(CurOp)=='-F') {
         FileOption=true;
      }
   }
   for (;;) {
      if (index<0) break;
      _str CurItem=tree1._TreeGetCaption(index);
      _str rest = '';
      parse CurItem with CurItem ' (' rest ')';
      if (FileOption) {
         if (file_eq(Item,CurItem)) return(index);
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
void ctlnew_tag_file.lbutton_up()
{
   // get list of indexes
   typeless ProjectTagfilesIndex, autoUpdateFilesIndex;
   typeless cppCompilerTagFilesIndex, javaCompilerTagFilesIndex, extFilesIndexList;
   parse TAG_FOLDER_INDEXES with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;

   // figure out which folder we are dealing with, and therefore what kind
   // of tag file (project, auto-update, language)
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
   _str mode_name='';
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

   // skip the dialog for auto-update tag files
   tagFile := '';
   tag_occurrences := false;
   useThread := true;
   createNew := false;
   rebuildTagFile := false;
   if(categoryLetter != 'A') {
      result := show('-modal _add_tag_file_form', mode_name);

      // cancel
      if (result==IDCANCEL) return;

      // we treat everything as 'E', which is language (Extension) tag files
      categoryLetter = 'E';

      // _param1 - language
      // _param2 - generate references
      // _param3 - use background tagging
      // _param4 - create new file
      // _param5 - tag file path
      tag_occurrences = _param2;
      useThread = _param3;
      createNew = _param4;
      tagFile = strip(_param5, 'B', '"');

      if (!createNew) {
         rebuildTagFile = _param6;
      }
   } else {
      tagFile = pickTagFileToAdd(true);
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
            addNewExtensionCategory = _param1;
            depth = TAGFORM_FOLDER_DEPTH;
            break;
         }

         // see if this matches
         parse tree1._TreeGetCaption(temp_index) with '"'mode_name'"';
         if (_ModenameEQ(mode_name,_param1)) {
            FolderIndex = origindex = temp_index;
            depth = TAGFORM_FOLDER_DEPTH;
            break;
         }
      }
   }

   tag_file_type := VS_DBTYPE_tags;
   _str TagFilename='';
   _str NewTagFilename='';

   // if this is an auto updated tag file, remember the remote name for later use
   _str autoUpdatedTagfile = "";
   _str localAutoUpdatedCopy = "";
   if (FolderIndex > 0 && FolderIndex == autoUpdateFilesIndex) {
      // get the proper local tag filename
      autoUpdatedTagfile = tagFile;

      // make sure the local copy doesnt collide with any existing tag files
      // NOTE: it isnt safe to just check the list in this workspace because multiple
      //       workspaces may share the same directory.  the safest way is to check
      //       to see if a file by that name exists.
      localAutoUpdatedCopy = _AbsoluteToWorkspace(_strip_filename(tagFile, "P"), _workspace_filename);
      _str localAutoUpdatedCopyBase = _strip_filename(localAutoUpdatedCopy, "E");

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
   //    _param6 - include paths
   //    _param7 - recursive
   //    _param8 - follow symlinks
   //    _param9 - exclude filespecs

   // see if this file is already in the tree
   int index=ItemInTree(TagFilename, FolderIndex, '-F');
   if (index < 0) {
      // does this file already exist?
      if (!createNew && file_exists(TagFilename)) {
         //File exists already
         if (file_eq(_get_extension(TagFilename),'slk')) {
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
            tag_close_db(TagFilename,1);
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
            mou_hour_glass(1);
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
            tag_close_db(TagFilename,1);

            if (_param6 != '') {
               //    _param6 - include paths
               //    _param7 - recursive
               //    _param8 - follow symlinks
               //    _param9 - exclude filespecs
               addFilesToTagFile(TagFilename, _param6, _param9, _param7, _param8, useThread);
            }
         }
      }

      // Add the tag file to the tree under the appropriate extension
      int flags=0;
      if (depth==TAGFORM_FOLDER_DEPTH) {
         //There are no children
         flags=TREE_ADD_AS_CHILD;
      }
      int has_occurrences = (tag_get_db_flags() & VS_DBFLAG_occurrences);
      int bmp_index = (has_occurrences)? _pic_file_refs:_pic_file;

      tag_read_db(TagFilename);
      _str comment=tag_get_db_comment();
      tag_close_db(TagFilename);

      // restore the remote filename if it is an auto updated tagfile
      if(FolderIndex>0 && FolderIndex == autoUpdateFilesIndex) {
         TagFilename = autoUpdatedTagfile;
      }

      _str allcaption = (comment=='')? TagFilename:TagFilename' ('comment')';

      // need to add a folder for this extension
      if (addNewExtensionCategory != '') {
         int FilesIndex=tree1._TreeAddItem(TREE_ROOT_INDEX,    //Relative Index
                                       '"'addNewExtensionCategory'" Tag Files',//Caption
                                        TREE_ADD_AS_CHILD,  //Flags
                                        _pic_fldclos,       //Collapsed Bitmap Index
                                        _pic_fldopen,       //Expanded Bitmap Index
                                       TREE_NODE_LEAF);                //Initial State
         TAG_FOLDER_INDEXES=TAG_FOLDER_INDEXES' 'FilesIndex;
         FolderIndex=origindex=FilesIndex;
      }

      index=tree1._TreeAddItem(origindex,//Relative Index
                               allcaption,          //Caption
                               flags,                //Flags
                               bmp_index,         //Collapsed Bitmap Index
                               bmp_index,         //Expanded Bitmap Index
                               TREE_NODE_LEAF);                  //Initial State
      int parentindex=tree1._TreeGetParentIndex(index);
      tree1._TreeSetInfo(parentindex,TREE_NODE_EXPANDED);

      // if this is an auto-updated tagfile, store the absolute local
      // path in the user info for the tree node
      if(FolderIndex>0 && FolderIndex == autoUpdateFilesIndex) {
         tree1._TreeSetUserInfo(index, localAutoUpdatedCopy);
      }

   } else {
      _message_box(nls("%s already exists",TagFilename));
   }

   // select the tag file
   if (index >= 0) {
      tree1._TreeSetCurIndex(index);
   }

   SetTagFiles(FolderIndex);
   _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,TagFilename,'A');
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);

   // Tell Eclipse that we removed a tagfile
   if (isEclipsePlugin()) {
      _str proj = "";
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
   if (ctlremove_tag_file.p_enabled) {
      ctlremove_tag_file.call_event(ctlremove_tag_file,LBUTTON_UP);
   }
}

//////////////////////////////////////////////////////////////////////////////
// translate 'DEL' key to pressing remove source file button
//
list1.del()
{
   if (ctlremove_files.p_enabled) {
      ctlremove_files.call_event(ctlremove_files,LBUTTON_UP);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Toggle building symbol cross-reference in this tag file
//
static ToggleGenerateReferences()
{
   int wid=p_window_id;
   p_window_id=tree1;
   int tree_wid=p_window_id;
   int index=_TreeCurIndex();
   _str OrigFilename=_TreeGetCaption(index);
   _str rest='';
   parse OrigFilename with OrigFilename ' (' rest ')';
   int db_flags = tag_get_db_flags();
   int bmp_index=0;
   if (db_flags & VS_DBFLAG_occurrences) {
      db_flags &= ~VS_DBFLAG_occurrences;
      tag_set_db_flags(db_flags);
      _TreeSetInfo(index,TREE_NODE_LEAF,_pic_file,_pic_file);
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

//////////////////////////////////////////////////////////////////////////////
// Update the tag form when the project file is opened or closed
//
static void UpdateTagFilesForm()
{
   static boolean recursionGuard;
   if (recursionGuard) return;
   recursionGuard = true;

   int formwid=_find_object('_tag_form','N');
   if (formwid) {
      int wid=p_window_id;
      p_window_id=formwid.tree1;
      index := _TreeCurIndex();
      if (index > TREE_ROOT_INDEX) {
         call_event(CHANGE_SELECTED,index,p_window_id,ON_CHANGE,'W');
         formwid.list1.refresh('W');
         formwid.list1.p_redraw=1;
      }
      p_window_id=wid;
   }

   recursionGuard = false;
}
_prjclose_tagform()
{
   UpdateTagFilesForm();
}
_prjupdate_tagform()
{
   UpdateTagFilesForm();
}
_prjopen_tagform()
{
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
   int index = _TreeCurIndex();
   if (index > 0) {
      int depth = _TreeGetDepth(index);
      if (depth==TAGFORM_FILE_DEPTH) {
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
         tag_close_db(TagFilename,1);
         _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle right click menu events for the tag form
//
_command TagTreeRunMenu(_str command='') name_info(','VSARG2_CMDLINE)
{
   if (command=='') {
      return('');
   }
   switch (lowcase(command)) {
   case 'addfiles':
      ctlfiles.call_event(ctlfiles,LBUTTON_UP);
      break;
   case 'addtree':
      ctltree.call_event(ctltree,LBUTTON_UP);
      break;
   case 'addtagfile':
      ctlnew_tag_file.call_event(ctlnew_tag_file,LBUTTON_UP);
      break;
   case 'deltagfile':
      ctlremove_tag_file.call_event(ctlremove_tag_file,LBUTTON_UP);
      break;
   case 'selectall':
      list1._lbselect_all();
      break;
   case 'delfiles':
      ctlremove_files.call_event(ctlremove_files,LBUTTON_UP);
      break;
   case 'addcomment':
      AddCommentToCurTagfile();
      break;
   case 'makerefs':
      ToggleGenerateReferences();
      break;
   case 'moveup':
      ctlup.call_event(ctlup,LBUTTON_UP);
      break;
   case 'movedown':
      ctldown.call_event(ctldown,LBUTTON_UP);
      break;
   case 'retagfiles':
      ctlretag_files.call_event(ctlretag_files,LBUTTON_UP);
      break;
   case 'rebuildtagfile':
      ctlrebuild_tag_file.call_event(ctlrebuild_tag_file,LBUTTON_UP);
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
   parse TAG_FOLDER_INDEXES with ProjectTagfilesIndex autoUpdateFilesIndex cppCompilerTagFilesIndex javaCompilerTagFilesIndex extFilesIndexList;
   if (_TreeGetDepth(index)!=TAGFORM_FILE_DEPTH) {
      _menu_set_state(menu_handle,"treeitem",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"moveitem",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"deltagfile",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"addcomment",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"rebuilditem",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"makerefs",MF_GRAYED,'C');
   // not a folder so see if it is a child of auto update folder
   } else if(_TreeGetParentIndex(index) == autoUpdateFilesIndex) {
      _menu_set_state(menu_handle,"treeitem",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"rebuilditem",MF_GRAYED,'C');
      //_menu_set_state(menu_handle,"moveitem",MF_GRAYED,'C');
      //_menu_set_state(menu_handle,"addtagfile",MF_GRAYED,'C');
      //_menu_set_state(menu_handle,"deltagfile",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"addcomment",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"makerefs",MF_GRAYED,'C');
      
   }else{
      _str filename=_TreeGetCaption(index);
      _str rest;
      parse filename with filename ' (' rest ')';
      int parentIndex=_TreeGetParentIndex(index);
      int status=tag_read_db(filename);
      if (status >= 0 && (tag_get_db_flags() & VS_DBFLAG_occurrences)) {
         _menu_set_state(menu_handle,"makerefs",MF_CHECKED,'C');
      }
      _str project_tag_files=_GetWorkspaceTagsFilename();
      _str TagFilename=tree1.GetRealTagFilenameFromTree(index);
      if (file_eq(TagFilename,project_tag_files)) {
         _menu_set_state(menu_handle,"treeitem",MF_GRAYED,'C');
      }

      if (!ctlremove_tag_file.p_enabled) {
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
   _str project_tag_files=_GetWorkspaceTagsFilename();
   _str TagFilename=tree1.GetRealTagFilenameFromTree(index);
   if (file_eq(TagFilename,project_tag_files)) {
      _menu_set_state(menu_handle,"treeitem",MF_GRAYED,'C');
      _menu_set_state(menu_handle,"delitem",MF_GRAYED,'C');
   }
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
}

//////////////////////////////////////////////////////////////////////////////
// Move the tag file at the given index up.  This is done to allow the
// user to adjust the ordering in which tag files are searched.
//
static boolean MoveFileUp(int FileIndex)
{
   p_window_id=tree1;
   int ParentIndex=_TreeGetParentIndex(FileIndex);
   int TopFileIndex=_TreeGetFirstChildIndex(ParentIndex);
   int BottomIndex=0;
   int index=TopFileIndex;
   for (;;) {
      BottomIndex=index;
      index=_TreeGetNextSiblingIndex(index);
      if (index<0) break;
   }
   if (TopFileIndex==BottomIndex) {
      return(false);
   }
   int flags=TREE_ADD_BEFORE;
   int LSibIndex=_TreeGetPrevSiblingIndex(FileIndex);
   int rindex=LSibIndex;
   if (TopFileIndex==LSibIndex) {
      //flags|=TREE_ADD_BEFORE;
   }else if (LSibIndex<0) {
      rindex=BottomIndex;
      flags&=~TREE_ADD_BEFORE;
   }
   _str FileCaption=_TreeGetCaption(FileIndex);
   int show_children=TREE_NODE_COLLAPSED;
   int bmp_index1=0, bmp_index2=0;
   _TreeGetInfo(FileIndex,show_children,bmp_index1,bmp_index2);
   _str rest='';
   parse FileCaption with FileCaption ' (' rest ')';
   TAGFORM_SKIP_ON_CHANGE=1;
   _TreeDelete(FileIndex);
   int NewIndex=_TreeAddItem(rindex,
                         FileCaption,
                         flags,
                         bmp_index1,
                         bmp_index2,
                         TREE_NODE_LEAF);
   _TreeSetCurIndex(NewIndex);
   TAGFORM_SKIP_ON_CHANGE=0;
   return(true);
}

//////////////////////////////////////////////////////////////////////////////
// Move the tag file at the given index down.  This is done in order
// to allow the user to adjust the ordering in which tag files are searched.
//
static boolean MoveFileDown(int FileIndex)
{
   p_window_id=tree1;
   int ParentIndex=_TreeGetParentIndex(FileIndex);
   int TopFileIndex=_TreeGetFirstChildIndex(ParentIndex);
   int index=TopFileIndex;
   int BottomIndex=0;
   for (;;) {
      BottomIndex=index;
      index=_TreeGetNextSiblingIndex(index);
      if (index<0) break;
   }
   if (TopFileIndex==BottomIndex) {
      return(false);
   }
   int flags=0;
   int RSibIndex=_TreeGetNextSiblingIndex(FileIndex);
   int rindex=RSibIndex;
   if (RSibIndex<0) {
      rindex=TopFileIndex;
      flags|=TREE_ADD_BEFORE;
   }
   _str FileCaption=_TreeGetCaption(FileIndex);
   int show_children=TREE_NODE_COLLAPSED;
   int bmp_index1=0, bmp_index2=0;
   _TreeGetInfo(FileIndex,show_children,bmp_index1,bmp_index2);
   _str rest='';
   parse FileCaption with FileCaption ' (' rest ')';
   TAGFORM_SKIP_ON_CHANGE=1;
   _TreeDelete(FileIndex);
   int NewIndex=_TreeAddItem(rindex,
                         FileCaption,
                         flags,
                         bmp_index1,
                         bmp_index2,
                         TREE_NODE_LEAF);
   _TreeSetCurIndex(NewIndex);
   TAGFORM_SKIP_ON_CHANGE=0;
   return(true);
}

//////////////////////////////////////////////////////////////////////////////
// Handle 'Up' and 'Down' buttons
//
ctlup.lbutton_up()
{
   int index=tree1._TreeCurIndex();
   int depth=tree1._TreeGetDepth(index);
   if (depth==TAGFORM_FILE_DEPTH) {
      boolean moved=MoveFileUp(index);
      if (moved) {
         int FolderIndex=tree1._TreeGetParentIndex(index);
         SetTagFiles(FolderIndex);
         _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      }
   }
}
ctldown.lbutton_up()
{
   int index=tree1._TreeCurIndex();
   int depth=tree1._TreeGetDepth(index);
   if (depth==TAGFORM_FILE_DEPTH) {
      boolean moved=MoveFileDown(index);
      if (moved) {
         int FolderIndex=tree1._TreeGetParentIndex(index);
         SetTagFiles(FolderIndex);
         _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Display auto tagging options form
//
ctloptions.lbutton_up()
{
   config('Editing > Context Tagging'VSREGISTEREDTM);
}

boolean isuinteger(_str text)
{
   if (!isinteger(text)) return false;
   return ((int) text >= 0);
}

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// add tag files form for selecting type of tag file to add
//
defeventtab _add_tag_file_form;

#define PREVIOUS_EXISTING_PATH      _ctl_existing_file_path.p_user
#define PREVIOUS_NEW_PATH           _ctl_new_file_path.p_user
#define PREVIOUS_SOURCE_PATH        _ctl_source_path.p_user

_ctl_ok.on_create(_str defaultMode = 'C')
{
   _retrieve_prev_form();

   // fill in the language combo box
   index := 0;
   findFirst := 1;
   langId := '';
   while (true) {

      index = name_match('def-language-', findFirst, MISC_TYPE);
      if (!index) {
         break;
      }

      // if tagging is supported for this language, add it to the list
      parse name_name(index) with '-' . '-' langId;
      if (_istagging_supported(langId)) {
         _ctl_languages._lbadd_item(_LangId2Modename(langId));
      }

      // set this to 0, so we don't start over
      findFirst = 0;
   }

   _ctl_languages._lbsort('i');
   _ctl_languages._lbfind_and_select_item(defaultMode, 'i', true);

   langId = _Modename2LangId(_ctl_languages._lbget_text());
   ctlUseThread.p_value = (def_autotag_flags2 & AUTOTAG_LANGUAGE_NO_THREADS)? 0:1;
   ctlUseThread.p_enabled = _is_background_tagging_supported(langId) && _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);

#if __UNIX__
   // Use retrieval value
   ctlsymlinks.p_value=def_symlinks;
#else
   ctlsymlinks.p_visible=false;
#endif

   // add some filespecs to our combo
   ctlinclude_filespecs._retrieve_list();
   ctlinclude_filespecs.add_filetypes_to_combo();

   ctlexclude_filespecs._retrieve_list();
   ctlexclude_filespecs.p_text = _retrieve_value("_add_tag_file_form.ctlexclude_filespecs.p_text");

   // if the paths have initial values, save them in the p_user,
   // so as to reinitialize the browse button
   PREVIOUS_EXISTING_PATH = _ctl_existing_file_path.p_text;
   PREVIOUS_NEW_PATH = _ctl_new_file_path.p_text;
   PREVIOUS_SOURCE_PATH = _ctl_source_path.p_text;
   _ctl_existing_file_path.p_text = _ctl_new_file_path.p_text = _ctl_source_path.p_text = '';

   // align the controls based on image sizes
   _add_tag_file_form_initial_alignment();
}

static void _add_tag_file_form_initial_alignment()
{
   rightAlign := _ctl_languages.p_x + _ctl_languages.p_width;
   sizeBrowseButtonToTextBox(_ctl_existing_file_path.p_window_id, _ctl_existing_file_browse_btn.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(_ctl_new_file_path.p_window_id, _ctl_new_file_browse_btn.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(_ctl_source_path.p_window_id, _ctl_source_browse_btn.p_window_id, 0, rightAlign);
}

_ctl_languages.on_change()
{
   modeName := _ctl_languages._lbget_text();
   langId := _Modename2LangId(modeName);
   ctlUseThread.p_enabled = _is_background_tagging_supported(langId);
}

_ctl_add_existing_file.lbutton_up()
{
   // enable/disable controls based on which radio button is picked
   _ctl_existing_file_path.p_enabled = _ctl_existing_file_browse_btn.p_enabled =
      ctlRebuild.p_enabled = (_ctl_add_existing_file.p_value == 1);
   _ctl_new_file_path.p_enabled = _ctl_new_file_browse_btn.p_enabled = ctlpath_label.p_enabled =
      _ctl_source_path.p_enabled = _ctl_source_browse_btn.p_enabled = ctlrecursive.p_enabled =
      ctlsymlinks.p_enabled = ctlinclude_label.p_enabled = ctlinclude_filespecs.p_enabled =
       ctlexclude_label.p_enabled = ctlexclude_filespecs.p_enabled = (_ctl_create_new_file.p_value == 1);
}

_ctl_existing_file_browse_btn.lbutton_up()
{
   // use the current value as the initial path
   initialPath := _ctl_existing_file_path.p_text;
   if (initialPath == '') {
      // or maybe the previous value
      initialPath = PREVIOUS_EXISTING_PATH;
   }
   initialPath = _strip_filename(initialPath, 'N');
   result := pickTagFileToAdd(false, initialPath);

   // set the value, then
   if (result != '') {
      PREVIOUS_EXISTING_PATH = _ctl_existing_file_path.p_text = result;
   }
}

_ctl_new_file_browse_btn.lbutton_up()
{
   // use the current value as the initial path
   initialPath := _ctl_new_file_path.p_text;
   if (initialPath == '') {
      // or maybe the previous value
      initialPath = PREVIOUS_NEW_PATH;
   }
   initialPath = _strip_filename(initialPath, 'N');
   result := pickTagFileToAdd(true, initialPath);

   // set the value, then
   if (result != '') {
      PREVIOUS_NEW_PATH = _ctl_new_file_path.p_text = result;
   }
}

static _str pickTagFileToAdd(boolean createNew, _str initialPath = '')
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

      ext := _get_extension(result);
      expected_ext := TAG_FILE_EXT;
      alternate_ext := '.slk';
      if (!file_eq('.'ext, expected_ext) && !file_eq('.'ext, alternate_ext)) {
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
      initialPath = PREVIOUS_SOURCE_PATH;
   }

   _str result = _ChooseDirDialog("", initialPath, "", CDN_PATH_MUST_EXIST | CDN_ALLOW_CREATE_DIR);
   if (result == '') return;

   _ctl_source_path.p_text = result;
}

void _ctl_ok.lbutton_up()
{
   _param1 = _ctl_languages.p_text;          // param1 - language
   _param2 = ctl_make_references.p_value;    // param2 - generate references
   _param3 = ctlUseThread.p_enabled && (ctlUseThread.p_value != 0);     // param3 - use background tagging
   _param4 = _ctl_create_new_file.p_value;   // param4 - create new file (as opposed to adding existing

   // new or existing file?
   if (_ctl_add_existing_file.p_value) {
      if (_ctl_existing_file_path.p_text == '') {
         _message_box("Please select a tag file to add.", p_active_form.p_caption);
         _str text=_ctl_existing_file_path.p_text;
         _ctl_existing_file_path.set_command(text,1,length(text)+1);
         _ctl_existing_file_path._set_focus();
         return;
      }

      // existing file
      _param5 = _ctl_existing_file_path.p_text;    // tag file
      _param6 = ctlRebuild.p_value;                // rebuild tag files
   } else {

      if (_ctl_new_file_path.p_text == '') {
         _message_box("Please specify a tag file name.", p_active_form.p_caption);
         _str text=_ctl_new_file_path.p_text;
         _ctl_new_file_path.set_command(text,1,length(text)+1);
         _ctl_new_file_path._set_focus();
         return;
      }

      // new file
      _param5 = _ctl_new_file_path.p_text;         // tag file

      // make sure we have a source path
      if (_ctl_source_path.p_text == '') {
         _param6 = _param7 = _param8 = _param9;               // follow symlinks
      } else {

         // _param6 is the array of include paths, built
         // using the source path and the include specs
         error := compile_include_paths(_param6, _ctl_source_path.p_text, ctlinclude_filespecs.p_text);
         if (error != '') {
            _message_box(error, p_active_form.p_caption);
            _str text=ctlinclude_filespecs.p_text;
            ctlinclude_filespecs.set_command(text,1,length(text)+1);
            ctlinclude_filespecs._set_focus();
            return;
         }

         _param7 = ctlrecursive.p_value;              // recursive
         _param8 = ctlsymlinks.p_value;               // follow symlinks

         // _param9 is an array of the exclude specs
         _param9._makeempty();
         _str list = ctlexclude_filespecs.p_text;
         _str file_exclude;
         while (list != '') {
            parse list with file_exclude ";" list;
            if (file_exclude != '') {
               _param9[_param9._length()]=file_exclude;
            }
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
void ctlok.on_create(boolean rebuild_all=false,
                     boolean tag_occurrences=false,
                     boolean removeWithoutPrompting=false,
                     boolean keepWithoutPrompting=false,
                     boolean isWorkspaceTagFile=false,
                     boolean useThread = false)
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

_command int autotag() name_info(',')
{
   return show('-modal _tag_compilers_form');
}

defeventtab _tag_compilers_form;

void _tag_compilers_form_init_for_options()
{
   // hide the buttons!
   _ctl_divider.p_visible = _ctl_ok.p_visible = _ctl_cancel.p_visible = _ctl_help.p_visible = false;

   // change the text

   _ctl_info_html.p_text='<p style="font-family:Default Dialog Font; font-size:10">Context Tagging performs expression ':+
                         'type, scope and inheritance analysis as well as symbol look-up within the current context to ':+
                         'help you navigate and write code.  It  parses your code and builds a database of symbol definitions ':+
                         'and declarations - commonly referred to as tags.  Context Tagging works with your source code ':+
                         'as well as libraries for commonly-used languages such as C, C++, Java, and .NET.  To tag these ':+
                         'compiler libraries now, click the button below.  You can also access this feature from the main ':+
                         'menu under <b>Tools > Tag Files</b> and pressing the <b>Auto Tag</b> button.</p>';
}

boolean _tag_compilers_form_is_modified()
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
      _str proj = "";
      _eclipse_get_active_project_name(proj);
      if (proj != "") {
         _eclipse_update_tag_list(proj);
      }
   }

   if (selectedItems == "") selectedItems = "none";
   _append_retrieve(0, selectedItems, "_tag_compilers_form._ctl_tagfiles");
}

void _ctl_tagfiles.on_create()
{
   // adjust the position of the form relative to the help label
   _ctl_info_html.p_height *= 2;
   _ctl_info_html._minihtml_ShrinkToFit();
   _ctl_tagfiles.p_y = 2*_ctl_info_html.p_y + _ctl_info_html.p_height;

   // load all the autotag choices
   _ctl_tagfiles._loadAutoTagChoices();
   _ctl_tagfiles.p_user = true;

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

#define ADD_BUTTON_TEXT          'Add...'
#define CONFIGURE_BUTTON_TEXT    'Configure...'
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
   autotag_add_new_compiler();
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

_command void autotag_add_new_compiler(int index = 0) name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   type := '';
   if (index == 0) {
      // get the possible values
      _str choices[];
      choices[0] = C_COMPILER_CAPTION;
      choices[1] = JAVA_COMPILER_CAPTION;

      defaultChoice := '';
      index = _ctl_tagfiles._TreeCurIndex();
      if (_ctl_tagfiles._TreeDoesItemHaveChildren(index)) {
         defaultChoice = _ctl_tagfiles._TreeGetCaption(index);
      } else {
         index = _ctl_tagfiles._TreeGetParentIndex(index);
         defaultChoice = _ctl_tagfiles._TreeGetCaption(index);
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
   langId := '';
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
   boolean checked:[];
   child := _ctl_tagfiles._TreeGetFirstChildIndex(sectionIndex);
   while (child > 0) {

      configName := _ctl_tagfiles._TreeGetCaption(child);
      isChecked  := _ctl_tagfiles._TreeGetCheckState(child);
      checked:[configName] = (isChecked == TCB_CHECKED);

      child = _ctl_tagfiles._TreeGetNextSiblingIndex(child);
   }

   // finally, reload this section
   _ctl_tagfiles._loadLangAutoTagChoices(langId, sectionIndex);

   // restore everything that was checked
   child = _ctl_tagfiles._TreeGetFirstChildIndex(sectionIndex);
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

