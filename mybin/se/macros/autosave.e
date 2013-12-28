////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49002 $
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
#import "hotfix.e"
#import "listbox.e"
#import "main.e"
#import "pip.e"
#import "proctree.e"
#import "project.e"
#import "pmatch.e"
#import "put.e"
#import "restore.e"
#import "rte.e"
#import "se/messages/MessageBrowser.e"
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
#import "window.e"
#endregion

#define ASTIMER_TIMEOUT     250

enum AutoSaveFlags {
   AS_ON             = 0x2,   // AutoSave is on
   AS_ASDIR          = 0x4,   // AutoSave to different directory
   AS_SAMEFN         = 0x8,   // AutoSave to same file
   AS_DIFFERENT_EXT  = 0x10,  // AutoSave to Generated extension
   AS_SAVE_WINDOWS   = 0x20,  // AutoSave window configuration
};

         // Timer amounts separated by spaces
         // inactive_amount absolute_amount config_amount

static long gforce_idle_timeout;
_str  _alltimer_handle = ''; //Global timer handle
static typeless autosave_view_id;
//This no longer needs to be global
//static int ascount=0;    // Timer Count in Seconds

//This no longer seems to be used
//static int aslast_save_window_count=0;
static int aslast_time=0;// Number of seconds since last timer event
static _str message_up=0;// 1 if a message box is being displayed
static boolean logNoticeUp = false; // Flag: true for log notice message box visible
static boolean as_timer_running = false;
static int as_flexlm_idle = 0;  // Flag used to keep track of FlexLM idle status
static typeless as_flexlm_timer = 0;  // amount of time elapsed since last flaxlm heartbeat
//long last_rte = 0;
static int _need_as_timer()
{
   // We are using this timer for listing functions and symbols
   return(1);
#if 0
   parse def_as_timer_amounts with inactive_time absolute_time config . ;
   return((def_as_flags&AS_ON) || _default_option('D'));
#endif
}
definit()
{
   as_flexlm_idle=0;
   as_timer_running=false;
   gforce_idle_timeout=0;
   as_flexlm_timer = _time('B');
   if (arg(1) == 'L') {
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

static void _as_removefilename(_str filename)
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
}
static void _as_addfilename(_str filename)
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

void _UpdateSymbolColoring(boolean force=false);


#define MAX_CALLBACK_TIME 10000
void _as_callback()
{
   if (!def_use_timers || !_use_timers) {
      return;
   }

   // IF we are in fast updating mode OR we want
   //    to force an update
   as_timer_running=true;
   if (_idle_time_elapsed()<=MAX_CALLBACK_TIME ||
       _idle_time_elapsed()-gforce_idle_timeout>=10000) {
      // It is up to the programmer to allow for the fact
      // that timer callbacks may not do save_search
      // and restore_search!   (Clark)

      // Update the current context, only if editor control
      /*
      // DJB 10-9-00 -- do not try to update context here.
      // Other timer callbacks and functions are responsible
      // for calling _UpdateContext before using the current
      // context.
      //
      focus_wid=_get_focus();
      if (focus_wid && focus_wid._isEditorCtl()) {
         focus_wid._UpdateContext();
      }
      */

      // update rte buffers
      if (_idle_time_elapsed() >= def_java_live_errors_sleep_interval) {
         rteUpdateBuffers();
      }

      // Save config?
      if((def_exit_flags & SAVE_CONFIG_IMMEDIATELY) && _config_modify_flags()){
         save_config(1);
      }
      
      // update the contents of the current buffer asynchronously, if supported
      _UpdateContextAsync();
      // Maybe retag buffers
      _BGReTag();
      // Update toolbar symbol combo box
      _UpdateContextWindow();
      // Update Class tool window
      _UpdateClass();
      // Update Symbol Tab on the output toolbar
      _UpdateTagWindow();
      // Update Procs Tab on project toolbar
      _UpdateCurrentTag();
      // update the completion hint
      AutoCompleteUpdateInfo();
      // Update enable/disable state of toolbar buttons
      _tbOnUpdate();
      // Check if need to terminate list members or function help.
      _CodeHelp();
      // find matching paren
      _UpdateShowMatchingParen();
      // Check FlexLM idle status.
      _as_checkFlexlmIdle();
      // call the flexlm hearbeat function
      _as_heartbeat();
      // Do Eclipse plugin idle work.
      eclipseDoIdleWork();
      // keep track of last time here
      gforce_idle_timeout=_idle_time_elapsed();
      _UpdateEditorLanguage();
      // Update the buffer tabs modified state(s)
      _update_mod_file_status();
      // Update file list modified state(s)
      _UpdateFileListModifiedFiles();
      // Update annotation browser
      _UpdateAnnotations();
      // Update message browser
      _UpdateMessages();
      // Update context highlighting
      _UpdateContextHighlights();
      // Update clipboard preview
      _UpdateClipboards();
      // Update advanced symbol coloring
      _UpdateSymbolColoring(false);
      // maybe send off data to the Product Improvement Program
      _pip_maybe_send();
      // maybe search for new hotfixes
      hotfixAutoFindCallback();

      _ScrollMarkupUpdateAllModels();
   }
   // call language specific buffer update callback
   _LanguageCallbackProcessBuffer(0);
   // if the user is idle, they may just be waiting for the search results
   // so don't stop calling bgm_update_search just because the user is idle
   bgm_update_search();

   // Is debugging active
   if (_tbDebugQMode()) {
      // update all the debugger toolbars
      _UpdateDebugger();
   }

   // check for incoming commands for the debug server
   _SlickCDebugHandler(0);

   // Report results of asynchronous tagging jobs that finished
   _ReportAsyncTaggingResults();

   //Maybe retag files
   _BGReTagFiles();
   as_timer_running=false;

#if __OS390__ || __TESTS390__
   if (!logNoticeUp && !suppressLogNotice()) {
      if (_hasNewEntryInLog()) {
         logNoticeUp = true;
         _str logFile;
         _userLogFile(logFile);
         _str msg = nls("A new entry has been added to your user log, '%s'. Click Browse Log to view the log.\n\nYou can also browse the log by typing 'userlog' on the SlickEdit command line.",logFile);
         show("-mdi -modal _userLogNotice_form", msg);
         logNoticeUp = false;
      }
   }
#endif
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
   typeless ascount=(curtime-aslast_time)/1000;

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
   if ((inactive_time + absolute_time == 0) ||

       ((_idle_time_elapsed() / 1000  < inactive_time) &&
        (ascount < absolute_time))  ||

       ( ((inactive_time == 0) && (ascount < absolute_time)) ||
         ((absolute_time == 0) && (_idle_time_elapsed() / 1000  < inactive_time))
       )
        || !(def_as_flags&AS_ON)
      ) {
      return;
   }
   save_search(auto ss1,auto ss2,auto ss3,auto ss4,auto ss5);
   _str ssmessage=get_message();
   int sticky=rc;
   aslast_time=curtime;
   int orig_view = p_window_id;
   p_window_id = _mdi.p_child;
   int orig_wid=p_window_id;
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   int orig_buf_id = p_buf_id;
   boolean file_was_saved=false;
   _str filename='';
   typeless status=0;

   // Removes files from list that have been autosaved or will be autosaved
   for (;;) {
      if (p_modify && (_need_to_save2()) && p_buf_name!='') {
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
   for (;;) {
      if (p_modify && (_need_to_save2()) && p_buf_name!='') {
         if (!(p_ModifyFlags &MODIFYFLAG_AUTOSAVE_DONE)) {
            if (def_max_autosave && p_buf_size>1024*def_max_autosave) {
               return;
            }
            file_was_saved=true;
            status=aswrite_file();
            if (status) {
               p_window_id=_mdi.p_child;
               return;
            }
         } else {
            // Add back in auto save file written previously
            filename=_mkautosave_filename();
            if (filename!='') {
               _as_addfilename(filename);
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
      save_window_config();
      message_up=0;
   }
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
       (_idle_time_elapsed() / 1000  >= inactive_time))
       {
         rc = save_all();
         if (rc == 0) {
            safe_exit();
         }
   }
}

static int as_failed()
{
   message_up = 2;
   int response=0;
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
   if (def_as_directory=='') {
      return(_ConfigPath():+'autosave':+FILESEP);
   }
   return(def_as_directory);
}
static _str _mkautosave_filename()
{
   _str name='';
   int as_flags=def_as_flags;
   if ((as_flags & AS_DIFFERENT_EXT) && _DataSetIsMember(p_buf_name)) {
      as_flags=AS_ASDIR;
   }
   if (as_flags&AS_ASDIR) {
      _str ch = '';
      if (last_char(_as_directory())!=FILESEP) {
         ch = FILESEP;
      }
      name = _as_directory():+ch:+_strip_filename(p_buf_name, 'p');
   } else if (as_flags&AS_DIFFERENT_EXT){
      _str new_ext= modify_ext(p_buf_name);
      if (new_ext) {
         name= _strip_filename(p_buf_name,'e'):+new_ext;
      } else {
         return('');
      }
   } else {
      name= p_buf_name;
   }
   return(name);
}
static int aswrite_file()
{
   if (message_up==2) {
      return(2);
   }
   if (p_buf_name=='') {
      return(0);
   }
   _str name=_mkautosave_filename();
   if (name=='') {
      return(0);
   }
   _str msg='';
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

   _project_disable_auto_build(true);
   message(msg);
   ++_ftpsave_override;   // Override the ftp upload
   int status = save('+o 'maybe_quote_filename(name), SV_OVERWRITE|SV_RETURNSTATUS|SV_NOADDFILEHIST);
   --_ftpsave_override;
   if (status == PATH_NOT_FOUND_RC||status == FAILED_TO_BACKUP_FILE_RC) {
      make_path(_as_directory(), 0);
      ++_ftpsave_override;   // Override the ftp upload
      status=save('+o 'maybe_quote_filename(name), SV_OVERWRITE|SV_RETURNSTATUS|SV_NOADDFILEHIST);
      --_ftpsave_override;
   }
   _project_disable_auto_build(false);
   if (status) {
      status=as_failed();
      _message_box(get_message(rc));
      return(status);
   }
   if (def_as_flags&AS_SAMEFN) {
      //p_modify=0   Let save do this
   }else{
      p_ModifyFlags|=MODIFYFLAG_AUTOSAVE_DONE;
      _as_addfilename(name);
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
   if ((def_autotag_flags2&AUTOTAG_FILES) ||    // background tagging 
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
static void _autosave_check()
{
   if ((def_as_flags & AS_SAMEFN)) return;

   // For each of the buffers, check for an autosave file.
   int orig_view_id;
   get_window_id(orig_view_id);
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();

   int orig_buf_id = p_buf_id;
   int count=0;
   for (;;) {
      // what would our autosave filename be?
      _str filename=_mkautosave_filename();
      if (filename!='') {
         // check the date on that file...is it newer than our current file date?
         typeless bfiledate=_file_date(filename,'B');
         if (bfiledate!='' && bfiledate!=0 && p_file_date<bfiledate) {
            typeless p=p_line;save_pos(p);
            _lbclear();
            get(maybe_quote_filename(filename),'','A');
            //p_modify=1;  get() will set ModifyFlags to 1
            ++count;
            //message_up=1;messageNwait('p_buf_name='p_buf_name'p='p);message_up=0;
            restore_pos(p);
         }
      }
      _next_buffer('hr');
      if (p_buf_id == orig_buf_id) {
         break;
      }
   }

   p_window_id=orig_view_id;
   if (count) {
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
}
int _sr_autosave(_str option='',_str info='',_str restoreFromInvocation='',_str relativeToDir=null)
{
   if (option=='N' || option=='R') {
      // call _autosave_check to reload autorestore files.
      if (restoreFromInvocation) {
         _post_call(_autosave_check);
      }
   }
   if (message_up) {
      insert_line("AUTOSAVE: 0");
   }
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
static boolean timer_is_on()
{
   if (_alltimer_handle != '') {
      return(_alltimer_handle >= 0);
   }
   return(false);
}
boolean autosave_timer_running()
{
   return as_timer_running;
}


static typeless modify_ext(_str fn)
{
#if __UNIX__
   return(_get_extension(fn,1)'~');
#else
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
   _str prefix=substr(ext,1,2);
   if (!_StartOfDBCS(ext,3)) {
      prefix=substr(ext,1,1);
   }
   _str suffix=substr(ext,4);
   if (!_StartOfDBCS(ext,4)) {
      suffix=substr(ext,5);
   }
   return('.'prefix:+'~':+suffix);
#endif
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
#define FLEXLM_IDLE_TIME 240000
//int def_license_checkin_time= 7200000; /* 2 hours- 2*60*60*1000;  */
int def_license_checkin_time= 0; /* off */

/**
 * FlexLM idle timeout.  After FLEXLM_IDLE_TIME milliseconds of idle time,
 * we become idle for the purposes of FlexLM license counting.
 */
static void _as_checkFlexlmIdle()
{
   if (_LicenseType()!=LICENSE_TYPE_CONCURRENT) {
      return;
   }
   int index=find_index('vsflexlm_idle',PROC_TYPE);
   if (!index_callable(index)) {
      return;
   }
   boolean doCheckIn=false;
   int idle=FLEXLM_IDLE_TIME;
   if (def_license_checkin_time) {
      doCheckIn=true;
      idle=def_license_checkin_time;
   }
   // flexlm_idle_time
   if (_idle_time_elapsed() >= idle) {
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
static boolean flexlm_mode()
{
   return(_Flexlm());
}

// defines how long to wait before calling vsflexlm_heartbeat
// again only applies to flexlm licensing mode
#define FLEXLM_HEARTBEAT_TIME 120000   /* every 2 minutes */

/**
 * Calls vsflexlm_heartbeat after every FLEXLM_HEARTBEAT_TIME
 * milliseconds of time.
 */
static void _as_heartbeat()
{
   if (_LicenseType()!=LICENSE_TYPE_CONCURRENT) {
      return;
   }
   int index=find_index('vsflexlm_heartbeat',PROC_TYPE);
   if (!index_callable(index)) {
      return;
   }
   typeless cur_time = _time('B');
   typeless time_diff = cur_time - as_flexlm_timer;
   //say('time_diff='time_diff' 'FLEXLM_HEARTBEAT_TIME);
   if (time_diff >= FLEXLM_HEARTBEAT_TIME || time_diff < 0) {
      as_flexlm_timer = cur_time;
      if (!as_flexlm_idle) {
         //say('calling vsflexlm_heartbeat');
         vsflexlm_heartbeat();
      }
   }
}
