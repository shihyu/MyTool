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
#include "filewatch.sh"
#include "license.sh"
#import "annotations.e"
#import "autocomplete.e"
#import "backtag.e"
#import "bgsearch.e"
#import "bufftabs.e"
#import "codehelp.e"
#import "context.e"
#import "debug.e"
#import "eclipse.e"
#import "fileman.e"
#import "files.e"
#import "hotfix.e"
#import "listbox.e"
#import "main.e"
#import "menu.e"
#import "pip.e"
#import "pmatch.e"
#import "proctree.e"
#import "project.e"
#import "projutil.e"
#import "put.e"
#import "restore.e"
#import "rte.e"
#import "savecfg.e"
#import "saveload.e"
#import "seldisp.e"
#import "sellist.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "taghilite.e"
#import "tagwin.e"
#import "tbclass.e"
#import "tbclipbd.e"
#import "tbfilelist.e"
#import "tbview.e"
#import "toolbar.e"
#import "vicmode.e"
#import "window.e"
#import "wkspace.e"
#import "se/messages/MessageBrowser.e"
#endregion

static const ASTIMER_TIMEOUT           = 250;
static const ASTIMER_START_AT_MS_IDLE  = 30;
static const ASTIMER_SECONDS_TO_IDLE   = 10;
static const ASTIMER_CALLBACK_SLICE_MS = 20;

_metadata enum AutoSaveFlags {
   AS_ON             = 0x2,   // AutoSave is on
   AS_ASDIR          = 0x4,   // AutoSave to different directory
   AS_SAMEFN         = 0x8,   // AutoSave to same file
   AS_DIFFERENT_EXT  = 0x10,  // AutoSave to Generated extension
   AS_SAVE_WINDOWS   = 0x20,  // AutoSave window configuration
};

         // Timer amounts separated by spaces
         // inactive_amount absolute_amount config_amount

static long gforce_idle_timeout = 0;
_str  _alltimer_handle = ''; //Global timer handle
static typeless autosave_view_id;
//This no longer needs to be global
//static int ascount=0;    // Timer Count in Seconds

//This no longer seems to be used
//static int aslast_save_window_count=0;
static int aslast_time=0;// Number of seconds since last timer event
static _str message_up=0;// 1 if a message box is being displayed
static bool logNoticeUp = false; // Flag: true for log notice message box visible
static bool as_timer_running = false;
static int  as_timer_iterator = 0;

typedef void (*AUTOSAVE_TIMER_PFN_BOOL)(bool);
static AUTOSAVE_TIMER_PFN_BOOL as_running_timer_functions[];
static AUTOSAVE_TIMER_PFN_BOOL as_always_timer_functions[];

static int as_flexlm_idle = 0;  // Flag used to keep track of FlexLM idle status
static typeless as_flexlm_timer = 0;  // amount of time elapsed since last flaxlm heartbeat
/*
 When a file is saved and the autosave temp file gets deleted, the 
 auto-restore file must be updated. Otherwise, if the editor crashes 
 and the auto-restore file is not updated (maybe the last one was saved or no timeout),
 the auto-save temp files won't be found because it no longer exists.
*/
static bool gmust_write_auto_restore_file;
//long last_rte = 0;
static int _need_as_timer()
{
   // We are using this timer for listing functions and symbols.
   // Note: if this is disabled, there is an assumption that
   // autosave_view_id is always valid. name_file2() calls _as_addfilename()!
   return(1);
#if 0
   parse def_as_timer_amounts with inactive_time absolute_time config . ;
   return((def_as_flags&AS_ON) || _default_option('D'));
#endif
}
definit()
{
   gmust_write_auto_restore_file=false;
   as_flexlm_idle=0;
   as_timer_running=false;
   as_timer_iterator=0;
   as_running_timer_functions._makeempty();
   as_always_timer_functions._makeempty();
   gforce_idle_timeout=0;
   as_flexlm_timer = _time('B');
   if (arg(1) == 'L') {
      if (isinteger(_alltimer_handle)) {
         _kill_timer((int)_alltimer_handle);
      }
      // Create timer or temp view if necessary
      _alltimer_handle = '';
      if (_need_as_timer()) {
         turn_on_timer();
      }
      return;
   }
   autosave_view_id='';
   message_up = 0;
   //ascount = 0;
   //aslast_save_window_count=0;
   if (!isnumber(def_as_flags)) {
      def_as_flags = 0;
   }
   _alltimer_handle = '';
   if (_need_as_timer()) {
      turn_on_timer();
   }
}

void _as_removefilename(_str filename,bool deleteFile=false)
{
   int orig_view_id;
   get_window_id(orig_view_id);
   activate_window(autosave_view_id);
   top();
   int status=search('^'_escape_re_chars(filename),'rh@');
   //message_up=1;messageNwait('status='status' filename='filename' Noflines='p_Noflines);message_up=0;
   if (!status) {
      _delete_line();
   }
   activate_window(orig_view_id);
   if (deleteFile) {
      delete_file(filename);
      gmust_write_auto_restore_file=true;
   }
}
void _as_addfilename(_str filename)
{
   int orig_view_id;
   get_window_id(orig_view_id);
   activate_window(autosave_view_id);
   top();
   int status=search('^'_escape_re_chars(filename),'rh@');
   if (status) {
      insert_line(filename);
   }
   activate_window(orig_view_id);
}
void _DeleteAutosaveFiles()
{
   if (autosave_view_id=='') return;
   int orig_view_id;
   get_window_id(orig_view_id);
   activate_window(autosave_view_id);
   top();up();
   for (;;) {
      if (down()) {
         break;
      }
      get_line(auto filename);
      /* This is a debug line so that I could make sure that only the
         autosave file were being deleted.  No status is checked, so if
         the user deleted some of the files already, it shouldn't matter. */
      //if (_message_box('delete the file 'filename'?','',MB_YESNOCANCEL|MB_ICONQUESTION)!=IDYES)continue;
      delete_file(filename);
   }
   _lbclear();
   activate_window(orig_view_id);
}
void _exit_delete_autosave_files()
{
   _DeleteAutosaveFiles();
}

#if 0
static void diff_time(int start_time,int end_time,_str msg)
{
   diff=end_time-start_time;
   if (diff>250) {
      //say('diff='diff' msg='msg);
   }
}
#endif
/*
    This function is global only so that this module can be reloaded
    without changing the address of the function.
*/
//static int debug_count;

void _UpdateSymbolColoring(bool AlwaysUpdate=false);
void _UpdatePositionalKeywordColoring(bool AlwaysUpdate=false);
void _UpdateDocsearch(bool AlwaysUpdate=false);
void _MaybeRecentFilesProcessPending(bool AlwaysUpdate=false);
void _MaybeScrollMarkupUpdateAllModels(bool AlwaysUpdate=false);
void _MaybeLanguageCallbackProcessBuffer(bool AlwaysUpdate=false);

void _MaybeUpdateEditorLanguage(bool AlwaysUpdate=false)
{
   if (AlwaysUpdate || _idle_time_elapsed() >= 75) {
      _UpdateEditorLanguage(0);
   }
}

static void _MaybeAutoSaveFiles(bool AlwaysUpdate=false)
{
   //++debug_count;
   //message(_mdi.p_child._SymbolWord()" "debug_count);
   //IF autosave Message Box being displayed
   if (message_up) {
      return;
   }
   typeless curtime=_time('b');
   if (!aslast_time) {
      aslast_time=curtime;
   }
   //typeless ascount=(curtime-aslast_time)/1000;
   ascount := (curtime-aslast_time) intdiv 1000;

   /*
   if(curtime - last_rte >= 250){
      last_rte = curtime;
      rteUpdateBuffers();
   }
   */

   //say('ascount='ascount);
   typeless inactive_time;
   typeless absolute_time;
   parse def_as_timer_amounts with inactive_time absolute_time/* config*/ . ;
   //config_interval=config*60;
   //aslast_save_window_count+=10;
   if (substr(inactive_time,1,1)=='m') {
      inactive_time= (int)substr(inactive_time, 2) * 60;
   }else{
      inactive_time= substr(inactive_time, 2);
   }
   if (substr(absolute_time,1,1)=='m') {
      absolute_time= (int)substr(absolute_time, 2) * 60;
   }else{
      absolute_time= substr(absolute_time, 2);
   }
   if (!AlwaysUpdate) {
      if ((inactive_time + absolute_time == 0) ||

          ((_idle_time_elapsed() intdiv 1000  < inactive_time) &&
           (ascount < absolute_time))  ||

          ( ((inactive_time == 0) && (ascount < absolute_time)) ||
            ((absolute_time == 0) && (_idle_time_elapsed() intdiv 1000  < inactive_time))
          )
           || !(def_as_flags&AS_ON)
         ) {
         if (!gmust_write_auto_restore_file || !(def_as_flags&AS_ON)) {
            return;
         }
      }
   }
   save_search(auto ss1,auto ss2,auto ss3,auto ss4,auto ss5);
   _str ssmessage=get_message();
   int sticky=rc;
   aslast_time=curtime;
   orig_view := p_window_id;
   p_window_id = _mdi.p_child;
   orig_wid := p_window_id;
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   int orig_buf_id = p_buf_id;
   file_was_saved := false;
   filename := "";
   typeless status=0;

   // Removes files from list that have been autosaved or will be autosaved
   for (;;) {
      if (p_modify && _need_to_save2()) {
         filename=_mkautosave_filename();
         if (filename!='') {
            _as_removefilename(filename);
         }
      }
      _next_buffer('hr');
      if (p_buf_id == orig_buf_id) {
         break;
      }
   }
   // Deletes autosave temp files no longer needed.
   _DeleteAutosaveFiles();
   //save_auto_restore_file=def_as_flags&AS_SAVE_WINDOWS;
   found_modified_file := false;
   int as_wid;
   for (;;) {
      if (p_modify && (_need_to_save2())) {
         found_modified_file=true;
         if (!(p_ModifyFlags &MODIFYFLAG_AUTOSAVE_DONE)) {
            if (!def_max_autosave_ksize || p_buf_size<=1024*def_max_autosave_ksize) {
               file_was_saved=true;
               // Since undo('s') is called, try to use a descent cursor location.
               as_wid=window_match('',1,'',p_buf_id,"VG,VM,VA,GMA");
               if (as_wid) {
                  status=as_wid.aswrite_file();
               } else {
                  status=aswrite_file();
               }
               if (status) {
                  p_window_id=_mdi.p_child;
                  return;
               }
            } else if (p_modified_temp_name) {
               _as_addfilename(p_modified_temp_name);
               p_modified_temp_name='';
            }
         } else {
            // Add back in auto save file written previously
            filename=_mkautosave_filename();
            if (filename!='' && 
                p_buf_name!=''   /* Don't delete temp files for unnamed buffers*/
                ) {
               // Shouldn't need this if but check it anyway for safety
               if (!(def_as_flags&AS_SAMEFN)) {
                  _as_addfilename(filename);
               }
            }
         }
      }
      _next_buffer('hr');
      if (p_buf_id == orig_buf_id) {
         break;
      }
   }
   if (file_was_saved /*save_auto_restore_file*/) {
      message_up=1;
      save_window_config(false,0,false,null,true,true,true);
      message_up=0;
   } else if(gmust_write_auto_restore_file) {
      save_window_config(false,0, false /*true*/ /* exiting editor */,null,true,true,found_modified_file);
   }
   gmust_write_auto_restore_file=false;
   p_window_id=orig_view;
   //
   // Just incase the mouse is captured by incremental-search or get_string
   // set mouse pointer to arrow.  This is not the correct pointer but it
   // looks better than an hour glass
   //
   if (file_was_saved) {
      mou_set_pointer(MP_ARROW);
      // Timer call back functions need to explicitly refresh the screen.
      // Don't want to call refresh twice.  need to extend mark to cursor below if
      // active object is not the mdi child.  This won't work if a selection is in
      // an editor control.  A better way to do this is to temporarily lock
      // the active mark before calling refresh and unlock it afterwards.
      if (p_window_id==_mdi.p_child) refresh();
   }
   restore_search(ss1,ss2,ss3,ss4,ss5);
   if (ssmessage!='') {
      if (sticky) {
         sticky_message(ssmessage);
      } else {
         message(ssmessage);
      }
   }
   // Timer call back functions need to explicitly refresh the screen.
   if (p_window_id!=_mdi.p_child) _mdi.p_child.refresh();

  // Did the user want to exit after the autosave?
  // Changed filecfg.e, slick.sh
   if ((def_exit_on_autosave) &&
       (_idle_time_elapsed() intdiv 1000  >= inactive_time))
       {
         rc = save_all();
         if (rc == 0) {
            safe_exit();
         }
   }
}

static void registerStandardAutoSaveTimerCallbacks()
{
   // reset both arrays
   as_running_timer_functions = null;
   as_always_timer_functions  = null;

   /////////////////////////////////////////////////////////////////////////////
   // update the list of callbacks to call when the user is active
   // stop calling these if the editor goes idle for 10 seconds
   /////////////////////////////////////////////////////////////////////////////
   {
      // update mdi menu (enable disable items)
      as_running_timer_functions :+= _maybe_reload_mdi_menu;

      if (_haveRealTimeErrors()) {
         // update rte buffers
         as_running_timer_functions :+= rteUpdateBuffers;
      }

      // save config?
      as_running_timer_functions :+= _maybe_save_config;

      // update the contents of the current buffer asynchronously, if supported
      as_running_timer_functions :+= _UpdateContextAsync;

      // Update toolbar symbol combo box
      as_running_timer_functions :+= _UpdateContextWindow;

      if (_haveContextTagging()) {
         // Maybe retag buffers
         as_running_timer_functions :+= _BGReTag;

         // Update Class tool window
         as_running_timer_functions :+= _UpdateClass;

         // Update context highlighting
         as_running_timer_functions :+= _MaybeUpdateContextHighlights;

         // Update positional keyword coloring
         as_running_timer_functions :+= _UpdatePositionalKeywordColoring;
      }

      // Update Symbol Tab on the output toolbar
      as_running_timer_functions :+= _MaybeUpdateAllTagWindows;

      // Update Procs Tab on project toolbar
      as_running_timer_functions :+= _UpdateCurrentTag;

      // update the completion hint
      as_running_timer_functions :+= _MaybeUpdateAutoCompleteInfo;

      // Update enable/disable state of toolbar buttons
      as_running_timer_functions :+= _tbOnUpdate;

      // Check if need to terminate list members or function help.
      as_running_timer_functions :+= _CodeHelp;

      // find matching paren
      as_running_timer_functions :+= _UpdateShowMatchingParen;

      if (_LicenseType() == LICENSE_TYPE_CONCURRENT) {
         // Check FlexLM idle status.
         as_running_timer_functions :+= _as_checkFlexlmIdle;

         // call the flexlm hearbeat function
         as_running_timer_functions :+= _as_heartbeat;
      }

      // Do Eclipse plugin idle work.
      if (isEclipsePlugin()) {
         as_running_timer_functions :+= eclipseDoIdleWork;
      }

      // update editor language
      as_running_timer_functions :+= _MaybeUpdateEditorLanguage;

      // Update the buffer tabs modified state(s)
      as_running_timer_functions :+= _update_mod_file_status;

      // Update file list modified state(s)
      as_running_timer_functions :+= _UpdateFileListModifiedFiles;

      if (_haveCodeAnnotations()) {
         // Update annotation browser
         as_running_timer_functions :+= _UpdateAnnotations;
      }

      // Update message browser
      as_running_timer_functions :+= _UpdateMessages;

      // Update clipboard preview
      as_running_timer_functions :+= _UpdateClipboards;

      // Update selective display options
      as_running_timer_functions :+= _UpdateSelectiveDisplay;

      // maybe send off data to the Product Improvement Program
      as_running_timer_functions :+= _pip_maybe_send;

      // maybe search for new hotfixes
      as_running_timer_functions :+= hotfixAutoFindCallback;

      // document search
      as_running_timer_functions :+= _UpdateDocsearch;

      // update scrollbar markup
      as_running_timer_functions :+= _MaybeScrollMarkupUpdateAllModels;

      // vi timer
      as_running_timer_functions :+= vi_correct_visual_mode_timer;

      // update file watch
      as_running_timer_functions :+= _MaybeRecentFilesProcessPending;
   }

   /////////////////////////////////////////////////////////////////////////////
   // update the list of callbacks to keep running, even when the editor 
   // has been idle for at least 10 seconds.
   /////////////////////////////////////////////////////////////////////////////
   {
      // call language specific buffer update callback
      as_always_timer_functions :+= _MaybeLanguageCallbackProcessBuffer;

      // if the user is idle, they may just be waiting for the search results
      // so don't stop calling bgm_update_search just because the user is idle
      as_always_timer_functions :+= bgm_update_search;

      if (_haveDebugging()) {
         // update all the debugger toolbars
         as_always_timer_functions :+= _UpdateDebugger;

         // check for incoming commands for the debug server
         as_always_timer_functions :+= _UpdateSlickCDebugHandler;
      }

      if (_haveContextTagging()) {
         // Update advanced symbol coloring
         as_always_timer_functions :+= _UpdateSymbolColoring;

         // Report results of asynchronous tagging jobs that finished
         as_always_timer_functions :+= _MaybeReportAsyncTaggingResults;

         //Maybe retag files
         as_always_timer_functions :+= _BGReTagFiles;
      }

      // update workspace caching
      as_always_timer_functions :+= _UpdateWorkspaceCache;

      // auto-save modified files
      as_always_timer_functions :+= _MaybeAutoSaveFiles;
   }
}

/**
 * Register a callback function to be called from the autosave timer. 
 * 
 * @param pfnCallback                Slick-C function to call
 * @param keep_running_when_idle     should this function run even when the 
 *                                   editor is idle, or only when things are
 *                                   happening?
 */
void _register_autosave_timer_callback(void (*pfnCallback)(bool), bool keep_running_when_idle=false)
{
   if (pfnCallback == null) return;

   if (as_running_timer_functions._isempty()) {
      registerStandardAutoSaveTimerCallbacks();
   }

   if (keep_running_when_idle) {
      as_always_timer_functions :+= pfnCallback;
   } else {
      as_running_timer_functions :+= pfnCallback;
   }
}


static const MAX_CALLBACK_TIME= 10000;
void _as_callback()
{
   if (!def_use_timers || !_use_timers) {
      return;
   }
   if (gin_restore || _in_workspace_close || _in_project_close || _in_close_all) {
      return;
   }

   // if the user is busy doing something, wait.
   // most functions require an idle time delay anyway
   it_elapsed := _idle_time_elapsed();
   if (it_elapsed < ASTIMER_START_AT_MS_IDLE) {
      return;
   }

   // It is up to the programmer to allow for the fact
   // that timer callbacks may not do save_search
   // and restore_search!   (Clark)

   // make sure timer function are registered
   if (as_running_timer_functions._isempty()) {
      registerStandardAutoSaveTimerCallbacks();
   }

   as_timer_running=true;
   start_time := (long)_time('b');

   iterator_running_max := as_running_timer_functions._length();
   iterator_always_max  := as_always_timer_functions._length();
   iterator_max := max(iterator_running_max, iterator_always_max);

   /////////////////////////////////////////////////////////////////////////////
   // update the list of callbacks to call when the user is active
   // stop calling these if the editor goes idle for 10 seconds
   /////////////////////////////////////////////////////////////////////////////

   // IF we are in fast updating mode OR we want to force an update
   if (it_elapsed <= MAX_CALLBACK_TIME || it_elapsed-gforce_idle_timeout >= ASTIMER_SECONDS_TO_IDLE*1000 /* 10 seconds */) {
      _str line;
      int wid=_mdi.p_child;
      if (!wid._isEditorCtl(false)) {
         wid=0;
      } else {
         line=wid.point();
      }
      for (i:=0; i<iterator_running_max; i++) {

         // update the iteration counter
         as_timer_iterator++;
         if (as_timer_iterator > iterator_max) {
            as_timer_iterator = 0;
         }

         it := (as_timer_iterator % iterator_running_max);
         (*as_running_timer_functions[it])(false);
         if (wid) {
            int new_wid=_mdi.p_child;
            if (!new_wid._isEditorCtl(false)) {
               new_wid=0;
            }
            if (wid==new_wid) {
               if (line!=wid.point()) {
                  typeless pfn=as_running_timer_functions[it];
                  if (substr(pfn,1,1)=='&') {
                     typeless index=substr(pfn,2);
                     say('Cursor moved');
                     say('   n='name_name(index));
                     say('   f='wid.p_buf_name);
                     line=wid.p_line;
                  }
               }
            }
         }

         cur_time := (long)_time('b');
         if (cur_time - start_time > ASTIMER_CALLBACK_SLICE_MS) {
            break;
         }
      }
   }

   /////////////////////////////////////////////////////////////////////////////
   // update the list of callbacks to keep running, even when the editor 
   // has been idle for at least 10 seconds.
   /////////////////////////////////////////////////////////////////////////////

   for (i:=0; i<iterator_always_max; i++) {

      // update the iteration counter
      as_timer_iterator++;
      if (as_timer_iterator > iterator_max) {
         as_timer_iterator = 0;
      }

      it := (as_timer_iterator % iterator_always_max);
      (*as_always_timer_functions[it])(false);

      cur_time := (long)_time('b');
      if (cur_time - start_time > ASTIMER_CALLBACK_SLICE_MS) {
         break;
      }
   }
   as_timer_running=false;

   /////////////////////////////////////////////////////////////////////////////
   // keep track of the amount of idle time since we last finished this callback
   // when we have inactivity for 10 seconds more than this, then we switch to
   // the idle mode.
   /////////////////////////////////////////////////////////////////////////////
   gforce_idle_timeout=_idle_time_elapsed();

}

static int as_failed()
{
   message_up = 2;
   response := 0;
   switch (arg(4)) {
   case FAILED_TO_BACKUP_FILE_RC:
      response = _message_box(nls("AutoSave has failed to save the file %s.\n\nThis may be the result of a filename that is to long for this drive type.\n\nDo you wish to disable AutoSave?",p_buf_name),
                              '',
                              MB_YESNOCANCEL|MB_ICONQUESTION);
      break;
   default:
      response = _message_box(nls("AutoSave has failed to save the file %s.  Do you wish to disable AutoSave?", p_buf_name),
                              '',
                              MB_YESNOCANCEL|MB_ICONQUESTION);
      break;
   }
   if (response == IDYES) {
      //_kill_timer(_alltimer_handle);
      def_as_flags &= ~AS_ON;
      //p_window_id=orig_wid;// This is a shot in the dark
      message_up=0;
      return(1);
   }
   message_up=0;
   return(0);
}
static _str _as_directory()
{
   path := strip(def_as_directory,'B','"');
   if (_isRelative(path)) {
      path= _replace_envvars(path);
      _maybe_append_filesep(path);
   }
   if (path=='') {
      path = get_env(_SLICKEDITCONFIG);
      _maybe_append_filesep(path);
      return(path:+'autosave':+FILESEP);
   }
   return(path);
}
_command void open_all_unnamed() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI|VSARG2_NOEXIT_SCROLL) {
   orig_wid:=_create_temp_view(auto temp_wid);
   _str path=_as_directory();
   _maybe_append_filesep(path);

   insert_file_list('-v "':+path:+'Untitled *@*"');
   top();up();
   while (!down()) {
      _str modified_temp_name;
      get_line(modified_temp_name);
      modified_temp_name=strip(modified_temp_name);
      // IF a buffer is already using the modified temp name
      modified_temp_name=path:+modified_temp_name;
      //say('modified_temp_name='modified_temp_name);
      if (_FindModifiedTempName(modified_temp_name)>=0) {
         continue;
      }
      activate_window(orig_wid);
      status:=edit(_maybe_quote_filename(modified_temp_name));
      if (!status) {
         name_file('',false);
         p_modified_temp_name=modified_temp_name;
         p_modify=true;
         orig_undo_steps:=p_undo_steps;
         p_undo_steps=0;
         p_undo_steps=orig_undo_steps;
         //say('p_modified_temp_name='p_modified_temp_name);
      }
      p_window_id=temp_wid;
   }
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);
}
int _SaveModifiedTempName() {
   make_path(_strip_filename(p_modified_temp_name,'N'));
   orig_buf_name:=p_buf_name;
   p_buf_name=p_modified_temp_name;
   p_modified_temp_name='';
   ++_ftpsave_override;   // Override the ftp upload
   status := save(_maybe_quote_filename(p_buf_name),SV_OVERWRITE|SV_RETURNSTATUS|SV_NOADDFILEHIST);
   --_ftpsave_override;
   p_modified_temp_name=p_buf_name;
   p_buf_name=orig_buf_name;
   if (!status) {
      p_modify=true;
      p_ModifyFlags|=MODIFYFLAG_AUTOSAVE_DONE;
   }
   return status;
}
void  _CreateModifiedTempName() {
   p_modified_temp_name='';
   _str temp;
    temp = _strip_filename(p_buf_name,'P');
   if (temp=='') {
       //temp = "Untitled ":+p_buf_id; 
       temp = "Untitled ";
   }
   _str modified_temp_name;
   modified_temp_name=_as_directory();
   _maybe_append_filesep(modified_temp_name);
   strappend(modified_temp_name,temp:+/*'@':+*/_date('i')' ');
   t:=_time('m');
   j:=lastpos(':',t);
   if (j) {
      t=substr(t,1,j-1);
      //t=substr(t,1,j-1):+'_':+substr(t,j);
   }
   temp=stranslate(t,'',':');
   strappend(modified_temp_name,temp);
   //p_modified_temp_name=modified_temp_name;
   if (_FindModifiedTempName(modified_temp_name)<0) {
      p_modified_temp_name=modified_temp_name;
      return;
   }
   for (i:=2;;++i) {
      if (_FindModifiedTempName(modified_temp_name:+'-':+i)<0) {
         p_modified_temp_name=modified_temp_name:+'-':+i;
         return;
      }
   }
}
static _str _mkautosave_filename()
{
   if (p_buf_name=='') {
      if (p_modified_temp_name=='') {
         _CreateModifiedTempName();
      }
      return p_modified_temp_name;
   }
   name := "";
   int as_flags=def_as_flags;
   if (as_flags&AS_ASDIR) {
      if (p_modified_temp_name=='') {
         _CreateModifiedTempName();
      }
      return p_modified_temp_name;
      /*_str ch = '';
      if (last_char(_as_directory())!=FILESEP) {
         ch = FILESEP;
      }
      name = _as_directory():+ch:+_strip_filename(p_buf_name, 'p');*/
   } 
   if (as_flags&AS_DIFFERENT_EXT){
      _str new_ext= modify_ext(p_buf_name);
      if (new_ext) {
         name= _strip_filename(p_buf_name,'e'):+new_ext;
      } else {
         return('');
      }
   } else {
      name= p_buf_name;
   }
   // Just in case the user has switched auto-save styles.
   // Make sure the old auto-save name gets removed.
   // User really needs to exit and restart for new auto-save 
   // style to work since autosave may have kicked in for some modified
   // files.
   if (p_modified_temp_name!='') {
      _as_addfilename(p_modified_temp_name);
   }
   p_modified_temp_name='';
   return(name);
}
static int aswrite_file()
{
   if (message_up==2) {
      return(2);
   }
   _str name=_mkautosave_filename();
   if (name=='') {
      return(0);
   }
   msg := "";
   if (def_as_flags&(AS_ASDIR|AS_DIFFERENT_EXT)) {
      msg = 'SlickEdit is AutoSaving 'p_buf_name' to 'name;
   }else{
      msg = 'SlickEdit is AutoSaving 'p_buf_name;
      // This fixes a problem with pressing undo after
      // autosave turns off modify and undo to previous save.  Want
      // modify flag to be on.  This adds a bug where end up with
      // more undoes that you actual did.
      _undo('s');
   }

   _save_ignore_user_options_changes(true);
   _project_disable_auto_build(true);
   message(msg);
   no_backup_option := "+o ";
   int status;
   if (p_buf_name=='') {
      /* Go ahead and make backup history information unnamed files.
         Backup history could be useful for unnamed file history. 
         Only down side to backup is a little performance but unnamed
         files are typically small.
      */ 
      status = _SaveModifiedTempName();
   } else {
      ++_ftpsave_override;   // Override the ftp upload
      status = save(no_backup_option:+_maybe_quote_filename(name), SV_OVERWRITE|SV_RETURNSTATUS|SV_NOADDFILEHIST);
      --_ftpsave_override;
      if (status == PATH_NOT_FOUND_RC || status==FILE_NOT_FOUND_RC ||status == FAILED_TO_BACKUP_FILE_RC) {
         make_path(_as_directory(), 0);
         ++_ftpsave_override;   // Override the ftp upload
         status=save(no_backup_option:+_maybe_quote_filename(name), SV_OVERWRITE|SV_RETURNSTATUS|SV_NOADDFILEHIST);
         --_ftpsave_override;
      }
   }
   _project_disable_auto_build(false);
   _save_ignore_user_options_changes(false);
   if (status) {
      as_status:=as_failed();
      _message_box(get_message(status));
      return(as_status);
   }
   if (def_as_flags&AS_SAMEFN) {
      //p_modify=0   Let save do this
   }else{
      p_ModifyFlags|=MODIFYFLAG_AUTOSAVE_DONE;
      // Don't temp files for unnamed buffer
      if (p_buf_name!='' ) {
         _as_addfilename(name);
      }
   }
   return(0);
}


static void shut_off_timer()
{
   if (_alltimer_handle != '') {
      //_kill_timer(_alltimer_handle);
   }
}

void _autosave_set_timer_alternate()
{
   if (_alltimer_handle=='') {
      return;
   }
   if (!_timer_is_valid(_alltimer_handle)) {
      // Something killed the timer, try to restart it
      _alltimer_handle = _set_timer(ASTIMER_TIMEOUT, _as_callback, '');
      if (_alltimer_handle<0) {
         return;
      }
   }
   if (((def_autotag_flags2&AUTOTAG_FILES) && !(def_autotag_flags2&AUTOTAG_DISABLE_ALL_BG)) ||    // background tagging 
       _tbDebugQMode() ||                       // debugging something   
       (flexlm_mode() && !as_flexlm_idle) ||    // flexlm, no idle time
       gbgm_search_state ||                     // background search
       _SlickCDebuggingEnabled() ||             // Slick-C debugging
       tag_get_num_async_tagging_jobs('A') > 0  // threaded tagging
       ) {            
      _set_timer_alternate(_alltimer_handle,0,0);
      return;
   }
   typeless inactive_time, absolute_time, config;
   parse def_as_timer_amounts with inactive_time absolute_time config .;
   if (!(def_as_flags&AS_ON)) {
      _set_timer_alternate(_alltimer_handle,MAXINT,MAX_CALLBACK_TIME);
      return;
   }
   if (substr(inactive_time,1,1)=='m') {
      inactive_time= (int)substr(inactive_time, 2) * 60;
   }else{
      inactive_time= substr(inactive_time, 2);
   }
   int m=MAX_CALLBACK_TIME;
   if (m<inactive_time*2000) {
      m=inactive_time*2000;
   }
   _set_timer_alternate(_alltimer_handle,MAXINT,m);
}
static typeless turn_on_timer()
{
   if (_alltimer_handle == '') {
      _alltimer_handle = _set_timer(ASTIMER_TIMEOUT, _as_callback, '');
      _autosave_set_timer_alternate();
   }
   if (_alltimer_handle <0) {
      _alltimer_handle='';
      _message_box('Timer could not be turned on');
      def_as_flags = def_as_flags &  ~AS_ON;
      return(1);
   }
   int orig_view_id=_find_or_create_temp_view(autosave_view_id,'+futf8 +t','.autosave',false,VSBUFFLAG_THROW_AWAY_CHANGES);
   rc=0;
   activate_window(orig_view_id);
   return(!(_alltimer_handle >= 0));
}
static void _autosave_check() {
   if ((def_as_flags & AS_SAMEFN)) return;
   // +newi specified
   if (_default_option(VSOPTION_NEW_OPTION)==2) {
      return;
   }
   refresh();
   message_up=1;
   msg := "AutoSave has detected unsaved files from a previous instance of SlickEdit.  ":+
          "This can happen if SlickEdit doesn't shut down properly or if you have another ":+
          "instance of SlickEdit running with unsaved files open.  The AutoSaved version ":+
          "of these files have been loaded from the AutoSave folder.  You should save ":+
          "these files if you want to keep them.";
   _message_box(msg);
   message_up=0;
   
}
int _sr_autosave(_str option='',_str info='',_str restoreFromInvocation='',_str relativeToDir=null)
{
   if (option=='N' || option=='R') {
      // call _autosave_check to reload autorestore files.
      if (restoreFromInvocation) {
         _post_call(_autosave_check);
      }
   }
   // This is manually done now
   //if (message_up) {
   //   insert_line("AUTOSAVE: 0");
   //}
   return 0;
}
#if 0
static void check4old_as_files()
{
   if (def_as_flags&AS_ASDIR) {
      orig_view_id=_create_temp_view(temp_view_id);
      if (last_char(def_as_directory)=='\') {
         insert_file_list(_as_directory()'*.*');
      }else{
         insert_file_list(_as_directory()'\*.*');
      }
      if (p_Noflines>0) {
         _message_box(nls("There are %s old autosave files in the %s directory.", p_Noflines, _as_directory()),
                          "NOTICE");
      }
      activate_window(orig_view_id);
      _delete_temp_view(temp_view_id);
   }
   if (def_as_flags&AS_DIFFERENT_EXT) {
      orig_view_id=_create_temp_view(temp_view_id);
      insert_file_list('*.??~');
      if (p_Noflines>0) {
         _message_box(nls("There are %s old autosave files in the current directory.", p_Noflines),
                          "NOTICE");
      }
      activate_window orig_view_id;
      _delete_temp_view(temp_view_id);
   }
}
#endif
static bool timer_is_on()
{
   if (_alltimer_handle != '') {
      return(_alltimer_handle >= 0);
   }
   return(false);
}
bool autosave_timer_running()
{
   return as_timer_running;
}


static typeless modify_ext(_str fn)
{
   if (_isUnix()) {
      return(_get_extension(fn,true)'~');
   }

   _str ext=_get_extension(fn);
   if(ext==''){
      //File Had No Extension
      return('.__~');
   }
   if (substr(ext,3,1) == '~') {
      return(0);
   }
   if (length(ext) == 1) {
      //File Had one character extension
      return('.'ext:+'_~');
   }
   prefix := substr(ext,1,2);
   if (!_StartOfDBCS(ext,3)) {
      prefix=substr(ext,1,1);
   }
   suffix := substr(ext,4);
   if (!_StartOfDBCS(ext,4)) {
      suffix=substr(ext,5);
   }
   return('.'prefix:+'~':+suffix);
}

void _as_allocfree_timer()
{
   if (timer_is_on() && !_need_as_timer()) {
      shut_off_timer();
   } else if (!timer_is_on() && _need_as_timer()) {
      turn_on_timer();
   }
   if (_alltimer_handle!='') {
      _autosave_set_timer_alternate();
   }
}

// defines the amount of idle time required to set the flexlm idle flag
// applies only to flexlm licensing mode
static const FLEXLM_IDLE_TIME= 240000;
//int def_license_checkin_time= 7200000; /* 2 hours- 2*60*60*1000;  */
int def_license_checkin_time= 0; /* off */

/**
 * FlexLM idle timeout.  After FLEXLM_IDLE_TIME milliseconds of idle time,
 * we become idle for the purposes of FlexLM license counting.
 */
static void _as_checkFlexlmIdle(bool AlwaysUpdate=false)
{
   if (_LicenseType()!=LICENSE_TYPE_CONCURRENT) {
      return;
   }
   index := find_index('vsflexlm_idle',PROC_TYPE);
   if (!index_callable(index)) {
      return;
   }
   doCheckIn := false;
   int idle=FLEXLM_IDLE_TIME;
   if (def_license_checkin_time) {
      doCheckIn=true;
      idle=def_license_checkin_time;
   }
   // flexlm_idle_time
   if (AlwaysUpdate || _idle_time_elapsed() >= idle) {
      if (as_flexlm_idle == 0) {
         // we are transitioning to the idle state
         as_flexlm_idle = 1;
         // vsflexlm_idle is not available when state file is initially loaded.
         // We're OK here because we only get called after the message loop
         // gets a timer event.
         //say('idle ON');
         vsflexlm_idle(as_flexlm_idle,doCheckIn);
         _autosave_set_timer_alternate();
      }
   }  else if (as_flexlm_idle != 0) {
      // transition to the non-idle state
      as_flexlm_idle = 0;
      // vsflexlm_idle not available when state file initially loaded
      //say('idle OFF');
      vsflexlm_idle(as_flexlm_idle,doCheckIn);
      _autosave_set_timer_alternate();
   }
}

/**
 * Determines if a FlexLM license is being used, and keeps the autosave
 * timer alive long enough to send the idle signal to FlexLM.
 *
 * @return
 */
static bool flexlm_mode()
{
   return(_Flexlm());
}

// defines how long to wait before calling vsflexlm_heartbeat
// again only applies to flexlm licensing mode
static const FLEXLM_HEARTBEAT_TIME= 120000;   /* every 2 minutes */

/**
 * Calls vsflexlm_heartbeat after every FLEXLM_HEARTBEAT_TIME
 * milliseconds of time.
 */
static void _as_heartbeat(bool AlwaysUpdate=false)
{
   if (_LicenseType()!=LICENSE_TYPE_CONCURRENT) {
      return;
   }
   index := find_index('vsflexlm_heartbeat',PROC_TYPE);
   if (!index_callable(index)) {
      return;
   }
   typeless cur_time = _time('B');
   typeless time_diff = cur_time - as_flexlm_timer;
   //say('time_diff='time_diff' 'FLEXLM_HEARTBEAT_TIME);
   if (AlwaysUpdate || time_diff >= FLEXLM_HEARTBEAT_TIME || time_diff < 0) {
      as_flexlm_timer = cur_time;
      if (!as_flexlm_idle) {
         //say('calling vsflexlm_heartbeat');
         vsflexlm_heartbeat();
      }
   }
}
