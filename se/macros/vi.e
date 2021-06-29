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
#include "ex.sh"
#import "se/lang/api/LanguageSettings.e"
#import "clipbd.e"
#import "ex.e"
#import "files.e"
#import "main.e"
#import "markfilt.e"
#import "recmacro.e"
#import "search.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbfind.e"
#import "tbsearch.e"
#import "vivmode.e"
#endregion

using se.lang.api.LanguageSettings;

_str     _vi_mode;
bool _vi_auto_deselect_vmode;
bool  def_vi_start_in_insert_mode=false;
// Even if the 'c' command changes multiple lines, preview them
bool  def_vi_always_preview_change;
bool  def_vi_left_on_escape;
_str     _vi_insertion_pos;
bool  def_vi_show_msg=true;
// 1 = enable vi command-mode in the '.process' buffer
_str     def_vi_chars='A-Za-z0-9_';
_str     def_vi_chars2='\!\@\#\$\%\^\&\*\(\)\-\+\|\=\\\{\}\[\]\"\39\`\:\;\~\?\/\,\.\>\<';
_str     vi_old_search_string;
int      vi_old_search_flags;
_str     vi_old_word_re;
_str     _vi_prev_context;

bool _vi_enable_correct_visual_mode=true;
// Value of keyboard macro recorded for '.'
_str _vi_last_kbdmacro;

static const VI_CB0= '0';


static const VI_CMDS_PLAYBACK= ' vi-toggle-char-visual vi-toggle-line-visual vi-toggle-block-visual':+
                      ' vi-insert-mode vi-begin-line-insert-mode vi-append-mode vi-end-line-append-mode':+
                      ' vi-newline-mode vi-above-newline-mode vi-delete vi-change-line-or-to-cursor':+
                      ' vi-change-to-end vi-delete-to-end vi-replace-char vi-replace-line vi-substitute-char':+
                      ' vi-substitute-line vi-join-line vi-shift-text-left vi-shift-text-right':+
                      ' vi-forward-delete-char vi-backward-delete-char vi-yank-to-cursor vi-yank-line':+
                      ' vi-toggle-case-char vi-put-after-cursor vi-put-before-cursor vi-filter ':+
                      ' vi-first-col-insert-mode vi-increment vi-decrement ';
/* These are used for repeating the last insert/delete/modification in
 * such commands as:  Ctrl+@, '.', and giving a repeat count to one of
 * the text insertion commands (a, A, i, I, o, O).
 */
const VI_CMDS_INSERT= ' vi-insert-mode vi-begin-line-insert-mode vi-append-mode vi-end-line-append-mode':+
                    ' vi-newline-mode vi-above-newline-mode vi-change-line-or-to-cursor vi-change-to-end':+
                    ' vi-replace-char vi-replace-line vi-substitute-char vi-substitute-line ';

static bool gplaying_last_kbdmacro;

/* 
   We seem to call _macro('KE') too much when recording 
   the keyboard macro for '.'. To work around this,
   maintain this variable ensure keyboard macro stack
   isn't messed up.
*/
static bool grecording_last_kbdmacro;

/*
When this is '', we are recording to a named keyboard macro.
*/
static _str grecording_kbdmacro_name;

// Holds the index of the command to repeat, lastkey pressed, a
// repeat count, and additional arguments to pass to the command.
_str _vi_repeat_info='';
// Holds the index of the insert command to repeat, lastkey pressed,
// a repeat count, and additional arguments to pass to the command.
_str _vi_repeat_info0='';
// Whether or not to always highlight all matches found with Vim search
bool def_vi_always_highlight_all;

_str def_vi_command_mode_msg; //="-- COMMAND --";
const VI_INSERT_MODE_MSG=  "-- INSERT --";
const VI_VISUAL_MODE_MSG=  "-- VISUAL --";

// A list of recorded events used during recorded macro playback
static _str _vi_ge_events;

definit()
{
   show_message := true;
   if ( arg(1)=='L' ) {
      // This is handy when changing emulations
      show_message=false;
   }
   if ( upcase(strip(translate(def_keys,'-','_'))):=='VI-KEYS' ) {
      if ( !isinteger(def_vi_start_in_insert_mode) || !def_vi_start_in_insert_mode ) {
         // Make sure we are in command mode
         vi_switch_mode('C',show_message);
      } else {
         // Make sure we are in command mode
         vi_switch_mode('I',show_message);
      }
      // We want named clipboards
      def_show_cb_name=true;
   }
   if ( !isinteger(def_vi_always_preview_change) ) {
      def_vi_always_preview_change=false;
   }
   // The beginning of an insertion
   _vi_insertion_pos='';
   if ( !isinteger(def_vi_show_msg) ) {
      def_vi_show_msg=true;
   }
   if ( ! isinteger(def_vi_left_on_escape) ) {
      def_vi_left_on_escape=true;
   }
   if ( ! isinteger(def_vi_always_highlight_all) ) {
      def_vi_always_highlight_all=true;
   }
   vi_old_search_string='';
   vi_old_replace_string := "";
   vi_old_search_flags=0;
   vi_old_word_re='['def_word_chars']';
   if ( _search_case()=='I' ) {
      vi_old_search_flags=IGNORECASE_SEARCH;
   }
   if ( _isEditorCtl() ) {
      _vi_prev_context=p_line' 'p_col' 'p_buf_id' 'p_buf_name;
   }

   // Initialize static variables used in vi-repeat-info()
   _vi_repeat_info='';
   _vi_repeat_info0='';

   // Initialize event list for vi_get_event() to ""
   _vi_ge_events="";

   // Abort kbdmacro play back and all recording
   _macro('Ka');
   _vi_last_kbdmacro='';
   grecording_last_kbdmacro=false;
   grecording_kbdmacro_name='';
   gplaying_last_kbdmacro=false;
   _vi_enable_correct_visual_mode=true;

   rc=0;
}


void _vi_dot_kbd_macro_end_recording() {
   if (!_MultiCursorLastLoopIteration()) {
      return;
   }
   if (grecording_last_kbdmacro) {
      _macro('KE',0);
      _vi_last_kbdmacro=_macro('KG',0);
      grecording_last_kbdmacro=false;
   }
}
void _vi_dot_kbdmacro_start_recording() {
   if (!_MultiCursorLastLoopIteration()) {
      return;
   }
   if (grecording_last_kbdmacro) {
      // This should't happen
      _macro('KE',0);
   }
   _macro('KB',0);
   grecording_last_kbdmacro=true;
}

/**
 * By default this command handles '@' pressed.
 */
_command int vi_execute_kbdmacro(typeless count=1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY|
                                                    VSARG2_MARK)
{
   if( command_state() ) {
      _str key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }

   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');
   typeless status=0;
   static _str cb_name;
   _str cb_name_local;
   static int recurse;
   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration() || recurse) {
      cb_name_local=vi_get_event();
      if( !vi_is_valid_clipboard(cb_name_local) ) {
         _MultiCursorLoopDone();
         vi_message('Invalid clipboard name: "'cb_name_local'"');
         return(1);
      }
      if (!recurse) {
         cb_name=cb_name_local;
      }
   } else {
      cb_name_local=cb_name;
   }
   kbdmacro_string:=_getClipboardText(true,true,'"'cb_name_local,(p_object==OI_EDITOR)?p_UTF8:true);
   if (!isinteger(count)) {
      count=1;
   }
   ++recurse;
   _macro('KP',count,kbdmacro_string);
   --recurse;
   if (!recurse) {
      _undo('S');
   }
   return 0;
}
/**
 * By default this command handles 'q' pressed.
 */
_command int vi_record_kbdmacro() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY) 
{
   if( command_state() ) {
      _str key=last_event();
      if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if (grecording_kbdmacro_name!='') {
      _macro('KD',1);
      _macro('KE',1);
      // Turn off recording and save this kbdmacro to register grecording_kbdmacro_name
      save_selection(auto mark);
      _deselect();
      orig_wid:=_create_temp_view(auto temp_wid);
      _str text=_macro('KG',1); 
      if (length(text)==0) {
         insert_line('');
      } else {
         _insert_text(' 'text);
      }
      _begin_line();_select_char('','EN');
      _end_line();_select_char('','EN');
      vi_cut(true,grecording_kbdmacro_name);
      _delete_temp_view(temp_wid);
      restore_selection(mark);
      activate_window(orig_wid);
      grecording_kbdmacro_name='';
      switch (vi_get_vi_mode()) {
      case 'C':
         clear_message();
         break;
      case 'V':
         sticky_message(VI_VISUAL_MODE_MSG);
         break;
      case 'I':
         sticky_message(VI_INSERT_MODE_MSG);
         break;
      }
      return 0;
   }
   if (vi_get_vi_mode()!='') {
      // Abort the visual mode kbdmacro being recording for '.'
      _vi_dot_kbd_macro_end_recording();
      _vi_last_kbdmacro='';   // Must destroy the '.' kbdmacro
   }
   
   // Start/initialize the list of events used when playing back recorded macros
   vi_get_event('S');
   _str cb_name;
   cb_name=vi_get_event();
   if( !vi_is_valid_clipboard(cb_name) ) {
      vi_message('Invalid clipboard name: "'cb_name'"');
      return(1);
   }
   grecording_kbdmacro_name=cb_name;
   _macro('KB',1);
   switch (vi_get_vi_mode()) {
   case 'C':
      sticky_message('recording');
      break;
   case 'V':
      sticky_message(VI_VISUAL_MODE_MSG'recording');
      break;
   case 'I':
      sticky_message(VI_INSERT_MODE_MSG'recording');
      break;
   }


   return 0;
}
/**
 * By default this command handles ESC pressed.
 */
_command int vi_escape() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (command_state()) {
      cursor_data();
      return 0;
   }
   in_process := _isEditorCtl() && ((beginsWith(p_buf_name,".process") || _process_info('B')));
   in_fileman := _isEditorCtl() && (p_LangId=="fileman");
   if ( in_process || in_fileman ) {
      return(0);
   }

   // Put editor into command mode
   typeless status=0;
   mode := upcase(vi_get_vi_mode());
   if (last_event():==ESC && !command_state()) {
      if (_MultiCursor() && (!_MultiCursorAlreadyLooping())) {
         _MultiCursorClearAll();
         _deselect();
         if (mode!='V') {
            return 0;
         }
      }
   }
   if ( mode=='C' ) {
      // Already in command mode
      //
      // However, call vi-switch-mode() to loop through the buffers and make sure
      vi_switch_mode('');
      vi_message('Already in normal mode');
   } else if ( mode=='I' ) {
      if ( vi_repeat_info('I') ) {
         int repeat_idx=vi_repeat_info('X');
         _str cmdname=vi_name_eq_translate(name_name(repeat_idx));
         is_posted_cmd := pos(' 'cmdname' ',VI_CMDS_POSTED_INSERT);
         if ( is_posted_cmd ) {
            vi_repeat_info('D');
            vi_repeat_info('E');
            last_index(repeat_idx,'C');
            int count=vi_repeat_info('C');
            if ( isinteger(count) && count>1 ) {
               if ( cmdname=='vi-replace-line' ) _insert_state('1');
               // Pass (count-1) as a playback count
               vi_repeat_info('Z2',count-1);
               if (command_state()) cursor_data();
               return(0);
            }
         }
      }
      col := p_col;
      status=vi_switch_mode('C');
      _deselect();
      if ( !status ) {
         // Clear the beginning insertion pos marker
         _vi_insertion_pos='';
         if ( def_vi_left_on_escape && p_col==col ) {
            left();
         }
      }
   } else if (mode == 'V') {
      vi_visual_toggle_off();
      //vi_switch_mode('C');
   }

   // End keyboard recording
   vi_repeat_info('E');
   if (command_state()) cursor_data();
   return(status);
}

int vi_message(_str msg, _str arg2="")
{
   this_idx := find_index('vi-message',PROC_TYPE);
   if ( last_index()==this_idx ) {
      flush_keyboard();
   }
   last_index(this_idx);
   arg2=upcase(strip(arg2));
   do_beep := pos('B',arg2);
   show_msg := pos('M',arg2);
   if ( do_beep || def_vi_or_ex_errorbells ) {
      _beep();
   }
   if ( show_msg || def_vi_show_msg ) {
      if ( _default_option(VSOPTION_HAVEMESSAGELINE)) {
         _str current_msg = get_message();
         if ( current_msg!="" ) {
            msg=current_msg', 'msg;
         }
         message(msg);
      } else {
         _beep();
         //_message_box(msg,'vi',MB_OK|MB_ICONNONE);
      }
   }

   return(0);
}

_command vi_maybe_normal_character() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_CMDLINE)
{
   if ( command_state() ) {
      _str key=last_event();
      if ( isnormal_char(key) ) {
         keyin(key);
      }
   }

   return(0);
}

/**
 * This function switches to command, insert, or visual mode.
 */
int vi_switch_mode(_str mode, _str showMessage="", typeless arg3="", bool auto_deselect_vmode=false,bool keep_recording=false)
{
   if (!_isEditorCtl()) {
      // If the current object is not an editor control, this function cannot
      // continue.
      return(1);
   }
   // Do not change the mode of the .process buffer or the Fileman
   in_process := (beginsWith(p_buf_name,".process")  || _process_info('B'));
   in_fileman := (p_LangId=="fileman");
   in_grep := _isGrepBuffer(p_buf_name);
   orig_view_id := p_window_id;
   if ( in_process || in_fileman || in_grep ) {
      // Switch temporarily to the hidden view to enable the switch
      p_window_id=VSWID_HIDDEN;
   }

   show_message := (showMessage=="" || showMessage);
   mode=upcase(strip(mode));
   showmode := __ex_set_showmode();
   showmode=(isinteger(showmode) && showmode>0);
   if ( mode:=='I' ) {
      if (_vi_mode:=='V') return(0);
      _vi_mode='I';
      _vi_auto_deselect_vmode=false;
      if ( show_message && showmode ) {
         if (grecording_kbdmacro_name!='') {
            sticky_message(VI_INSERT_MODE_MSG'recording');
         } else {
            sticky_message(VI_INSERT_MODE_MSG);
         }
      }
   } else if ( mode:=='C' ) {
      // This will also reset the mode if 'mode' is invalid
      if (_vi_mode:=='V') return(0);
      _vi_mode='C';
      _vi_auto_deselect_vmode=false;
      if ( show_message && showmode ) {
         if (grecording_kbdmacro_name!='') {
            //sticky_message(VI_COMMAND_MODE_MSG'recording');
            sticky_message('recording');  // Consistent with Vim
         } else {
            sticky_message(def_vi_command_mode_msg);
         }
      }
   } else if ( mode:=='V') {
      if (_vi_mode:=='V') {
         if ( select_active() ) deselect();
         if (keep_recording) {
            // Used by vi_visual_change
            _vi_mode='C';
            _vi_auto_deselect_vmode=false;
         } else {
            _vi_dot_kbd_macro_end_recording();
            _vi_mode='C';
            _vi_auto_deselect_vmode=false;
            if ( show_message && showmode ) {
               //sticky_message(VI_COMMAND_MODE_MSG);
               if (grecording_kbdmacro_name!='') {
                  sticky_message(def_vi_command_mode_msg'recording');
               } else {
                  sticky_message(def_vi_command_mode_msg);
               }
            }
         }
      } else {
         _vi_mode='V';
         _vi_auto_deselect_vmode=auto_deselect_vmode;
         if ( show_message && showmode ) {
            if (grecording_kbdmacro_name!='') {
               sticky_message(VI_VISUAL_MODE_MSG'recording');
            } else {
               sticky_message(VI_VISUAL_MODE_MSG);
            }
         }
      }
   } else if ( mode=='' ) {
      // Do not change the mode, but loop through all the buffers and
      // reset their modes.
   } else {
      if ( show_message ) {
         vi_message('Invalid mode');
      }
      if ( in_process || in_fileman || in_grep ) {
         // Switch back to original view
         p_window_id=orig_view_id;
      }
      return(1);
   }
   call_list('_vi_switchmode_');
   if (arg3=='') {
      _SetEditorLanguage(p_LangId, true, false, false, true);
   } else {
      int first_buf_id=p_buf_id;
      for (;;) {
         _SetEditorLanguage('', true, false, false, true);
         /* 'H' because might be an editor control */
         _next_buffer('H');
         for ( ;p_buf_id!=first_buf_id && p_buf_flags&VSBUFFLAG_HIDDEN; ) _next_buffer('H');
         if ( p_buf_id==first_buf_id ) break;
      }
   }
   if ( in_process || in_fileman || in_grep ) {
      // Switch back to original view
      p_window_id=orig_view_id;
   }
   return(0);
}

/**
 * This function returns the command name bound to 'key' OR the keytable name.
 */
_str vi_name_on_key(_str key, _str option="")
{
   // 'R' = return root key binding,
   //       otherwise return mode
   //       key binding
   //
   // 'I' = return mode key binding
   //       as if user were in INSERT
   //       mode
   //
   // 'IK'= return the keytable name
   //       as if user were in INSERT
   //       mode
   option=upcase(strip(option));

   if ( option:=='R' ) {
      return(name_name(eventtab_index(_default_keys,_default_keys,event2index(key))));
   } else if ( option:=='I' || option:=='IK' ) {
      keytab_name := LanguageSettings.getKeyTableName(p_LangId);
      insert_mode_keytab_idx := find_index(keytab_name,EVENTTAB_TYPE);
      if ( !insert_mode_keytab_idx ) insert_mode_keytab_idx=_default_keys;
      if ( option:=='IK' ) {
         return(keytab_name);
      } else {
         return(name_name(eventtab_index(_default_keys,insert_mode_keytab_idx,event2index(key))));
      }
   } else {
      return(name_name(eventtab_index(_default_keys,p_mode_eventtab,event2index(key))));
   }
}


/**
 * This function returns the current mode of the current buffer.
 */
_str vi_get_vi_mode()
{
   return(_vi_mode);
}


/**
 * This function sets the previous context in the current buffer.
 */
void vi_set_prev_context(typeless prev_context="")
{
   if ( prev_context!='' ) {
      _vi_prev_context=prev_context;
   } else {
      _vi_prev_context=p_line' 'p_col' 'p_buf_id' 'p_buf_name;
   }
}


/**
 * This function gets the previous context.
 */
_str vi_get_prev_context()
{
   return(_vi_prev_context);
}

/**
 * This function goes to the previous context set by vi_set_prev_context().
 */
int vi_goto_prev_context()
{
   cur_line := p_line;
   cur_col := p_col;
   typeless prev_line="", prev_col="", buf_id="", buf_name="";
   parse _vi_prev_context with prev_line prev_col buf_id buf_name;
   if ( p_buf_id==buf_id && p_buf_name==buf_name ) {
      if ( isinteger(prev_line) && prev_line>0 ) {
         p_line=prev_line;
         if ( p_line!=prev_line ) {
            p_line=cur_line;
            return(1);
         }
         if ( prev_col>_text_colc() ) {
            p_col=_text_colc();
         } else {
            p_col=prev_col;
         }
      }
   } else {
      // If not known make the previous context line1,column1
      top();
   }
   _vi_prev_context=cur_line' 'cur_col' 'p_buf_id' 'p_buf_name;

   return(0);
}

/**
 * This function handles default searching in vi.
 */
int vi_search(_str re, _str options,bool &matched_all=false)
{
   matched_all=false;
   if (def_vi_always_highlight_all && !pos('*#', options)) {
      options :+= "*#";
   }
   if (pos('*#', options)) {
      clear_highlights();
   }

   addCursors := false;
   markSearch := false;
   cursorEnd := false;
   if (pos('|',options)) {
      _searchResetAllMultiCursors();
      addCursors = true;
      if (pos('M',upcase(options))) {
         markSearch = true;
      }
      if (pos('>',options)) {
         cursorEnd = true;
      }
   }

   status := search(re,options);
   save_search(old_search_string,old_search_flags,old_word_re);
   set_find_next_msg("");
   save_last_search(old_search_string, options);
   if (!status && (pos('*', options) || addCursors)) {
      matched_all=true;
      typeless orig_pos; save_pos(orig_pos);
      top(); up();
      for (;;) {
         if (repeat_search('@')) break;
         if (addCursors) {
            _searchAddMultiCursor(markSearch, cursorEnd);
         }
      }
      restore_pos(orig_pos);
   }
   old_search_flags &= ~(VSSEARCHFLAG_FINDHILIGHT|VSSEARCHFLAG_SCROLLHILIGHT);
   if (status == STRING_NOT_FOUND_RC) {
      clear_highlights();
   }
   return(status);
}

/**
 * This function returns all the recorded events. 
 * 
 * @return _str
 */
_str vi_get_all_events(){
   return(_vi_ge_events);
}

/**
 * This function handles getting an event.
 * <P>
 * If we are not playing back a recorded macro, then it does a get_event().
 * If we _are_ playing back a recorded macro, then we retrieve the
 * recorded event from a variable that was loaded during recording.
 * <P>
 * _vi_ge_events is a list of recorded events used during recorded
 * macro playback.
 */
_str vi_get_event(_str options="", _str event="")
{
   if ( upcase(options)=='S' || upcase(options)=='SP' ) {
      // Clear out the event list
      if ( upcase(options)=='SP' ) {
         // 'SP' guarantees that simply playing back a macro that calls
         // vi_get_event() with just 'S' does not clear the list out.
         _vi_ge_events="";
      } else if ( _macro('m',_macro('s')) ) {
         // We are recording, so preplace this call
         _str line=_macro_get_line();
         _macro_delete_line();
         _macro_call('vi_get_event','SP');
         // Put the old line back
         _macro_append(line);
      }
      return("");
   }
   return_event := "";
   if ( event :!= '' ) {
      // We are loading events manually
      _vi_ge_events :+= event;
      if ( _macro('m',_macro('s')) ) {
         // We are recording, so preplace the call
         _str line=_macro_get_line();
         _macro_delete_line();
         _macro_call('vi_get_event','',event);
         // Put the old line back
         _macro_append(line);
      }
      return_event=event;
   } else {
      if ( _vi_ge_events!="" && _macro('r') ) {
         // We are playing back a macro, so retrieve event from saved list
         return_event=substr(_vi_ge_events,1,1);
         _vi_ge_events=substr(_vi_ge_events,2);
      } else {
         return_event=get_event(options);
         if ( _macro('m',_macro('s')) ) {
            // We are recording, so preplace the call
            _str line=_macro_get_line();
            _macro_delete_line();
            _macro_call('vi_get_event','',return_event);
            // Put the old line back
            _macro_append(line);
         }
      }
   }

   return(return_event);
}

bool vi_is_valid_clipboard(_str cb_name) {
   return length(cb_name)==1 && (isalnum(cb_name) || cb_name=='+');
}
/**
 * This function copies marked text to the clipboard and to clipboard '0'.
 */
int vi_cut(bool copy_option, _str cb_name, _str default_cb_name=null) {
   //say("vi_cut: copy="copy_option' cb_name='cb_name'> default_cb_name='(default_cb_name==null?'<NULL>':default_cb_name)'>');
   if ( cb_name!='' && !vi_is_valid_clipboard(cb_name) ) {
      vi_message('Invalid clipboard name: "'cb_name'"');
      return(1);
   }
   replace_mark_option := true;
   if ( cb_name!='' && _UTF8Asc(_maybe_e2a(cb_name))>=EB_ASCII_A && _UTF8Asc(_maybe_e2a(cb_name))<=EB_ASCII_Z ) {
      // If 'cb_name' is uppercase then append to the named clipboard
      replace_mark_option=false;
      cb_name=lowcase(cb_name);
   }
   if ( !select_active() ) {
      vi_message('There is no selection active');
      return(1);
   }
   // Make an exact copy of the mark
   typeless status=0;
   if (cb_name=='') {
      if (default_cb_name==null) {
         if (copy_option) {
            cb_name='"'VI_CB0;
         } else {
            cb_name='';
         }
      } else {
         cb_name='"'default_cb_name;
      }
   } else {
      cb_name='"'cb_name;
   }
   if (cb_name=='"+') cb_name='';
   status=cut(replace_mark_option,copy_option,cb_name);
#if 0
   if ( (stack_push || cb_name!='' || default_cb_name_for_delete!='') && cb_name!=VI_CB0 ) {
      say('case 1 copy_option='copy_option);
      _str default_cb_name=(copy_option)?VI_CB0:default_cb_name_for_delete;
      status=cut(replace_mark_option,copy_option,(cb_name!='')?'"'cb_name:default_cb_name);
#if 0
      if (copy_option || cb_name!='' || default_cb_name_for_delete!='') {
         // First copy to clipboard '0' or default_cb_name_for_delete
         _str default_cb_name=(copy_option)?VI_CB0:default_cb_name_for_delete;
         say('default_cb_name='default_cb_name' copy_option='copy_option' delete_cb_name='default_cb_name_for_delete);
         status=cut(1,true,default_cb_name);
         typeless old_mark=_duplicate_selection('');
         // Must show this again so we can copy to normal clipboard
         _show_selection(mark);
         status=cut(replace_mark_option,copy_option,cb_name);
         // Show 'old_mark' so we can free 'mark'
         _show_selection(old_mark);
      } else {
         say('replace_mark_option='replace_mark_option);
         status=cut(replace_mark_option,copy_option,cb_name);
      }
#endif
   } else {
      say('case 2 copy_option='copy_option);
      status=cut(1,copy_option,(copy_option)?'"'VI_CB0:'');
   }
#endif
   _str num_lines = count_lines_in_selection('');
   if (isinteger(num_lines)) {
      if ((int)num_lines > 2) {
         vi_message(nls(num_lines' lines yanked'));
      }
   }
   //_free_selection(mark);

   return(status);
}


_str _vi_repeat_info_count;
_str old_vi_repeat_info='';
_str old_vi_repeat_info0='';

/** This function exists to remember the last insert/delete/modification.
 * <P>
 * Keyboard macro:
 * <BR>
 * '0' is for insert commands
 * <BR>
 * '1' is for non-insert commands
 */
int vi_repeat_info(typeless repeat_idx, 
                   typeless last_key_or_count="",
                   typeless cb_name_or_count="",
                   typeless cb_name="",
                   typeless callback_idx="")
{
   // IF arg(1)=='' THEN
   //    repeat_idx    = ''
   //    arg(2)        = repeat count which overrides the count saved wi th the original command (usually from VI-COUNT)
   //    arg(3)        = clipboard name which overrides the clipboard na me save with the original command
   // ELSE
   //    repeat_idx    = index of the command to repeat
   //    arg(2)        = last key pressed; MUST have this for playing ba ck delete/modification sequences where the first key is not recorded
   //    arg(3)        = repeat count from the command
   //    arg(4)        = clipboard name from the command (if any)
   //    arg(5)        = callback index of command to call after playbac k is done (if any)

   typeless lkey="";
   typeless count="";
   typeless override_count="";
   typeless override_cb_name="";
   name := "";

   typeless status=0;
   if ( repeat_idx=='' ) {
      if ( _vi_repeat_info=='' ) {
         vi_message('Nothing to repeat');
         return(1);
      }
      parse _vi_repeat_info with repeat_idx ',' lkey ',' count ',' cb_name ',' callback_idx;
      if ( !index_callable(repeat_idx) ) {
         message('Invalid index');
         return(1);
      }
      override_count=last_key_or_count;
      override_cb_name=cb_name_or_count;
      name=vi_name_eq_translate(name_name(repeat_idx));
      is_playback_cmd := pos(' 'name' ',VI_CMDS_PLAYBACK);
      if ( isinteger(override_count) && override_count>0 ) {
         count=override_count;
      }
      if ( vi_is_valid_clipboard(override_cb_name) ) {
         cb_name=override_cb_name;
      }
      // Reset with (possibly) new count and clipboard name
      _vi_repeat_info=repeat_idx','lkey','count','cb_name','callback_idx;
      if ( is_playback_cmd ) {
         is_posted_cmd := pos(' 'name' ',VI_CMDS_POSTED_INSERT);
         if ( is_posted_cmd ) {
            // Just in case its been updated
            _vi_repeat_info0=_vi_repeat_info;
            status=vi_repeat_info('Z2');
         } else {
            // Play back the last recorded keyboard macro
            gplaying_last_kbdmacro=true;
            _macro('KP',null,_vi_last_kbdmacro);
            gplaying_last_kbdmacro=false;
         }
      }
   } else if ( !isinteger(repeat_idx) ) {
      option := upcase(strip(repeat_idx));
      switch (option) {
      case 'A':
         // Abort the keyboard macro being played back
         //
         _vi_repeat_info=old_vi_repeat_info;
         _vi_repeat_info0=old_vi_repeat_info0;
         status=_macro('KA');
         break;
      case 'C':
         // Return the repeat count for the command being played back?
         //
         // This is the count passed in from the command currently being recorded
         _str arg2=last_key_or_count;
         if ( _macro('KI') ) {
            status=arg2;
         } else {
            parse _vi_repeat_info with repeat_idx ',' . ',' count ',' .;
            if ( last_index('','C')==repeat_idx ) {
               status=count;
            } else {
               status=arg2;
            }
         }
         break;
      case 'D':
         // Delete the last key sequence of the currently recording keyboard macro
         //
         status=0;
         _macro('KD',0);
         break;
      case 'E':
         // End the recording of the currently recording keyboard macro
         //
         _vi_dot_kbd_macro_end_recording();
         status=0;
         break;
      case 'I':
         // Are we currently recording a keyboard macro?
         //
         status=_macro('KI',0);
         break;
      case 'N':
         // Return the clipboard name for the command being played back?
         //
         // This is the clipboard name passed in from the command
         // currently being recorded.
         arg2=last_key_or_count;
         if ( _macro('KI',0) ) {
            status=arg2;
         } else {
            parse _vi_repeat_info with . ',' . ',' . ',' cb_name ',' .;
            status=cb_name;
         }
         break;
      case 'R':
         // Are we currently playing back a keyboard macro?
         //
         status=_macro('KR');
         break;
      case 'X':
         // Return the index which started the recording?
         //
         if ( _vi_repeat_info=='' ) {
            status=0;
         } else {
            parse _vi_repeat_info with repeat_idx ',' .;
            if ( !repeat_idx || !index_callable(repeat_idx) ) {
               status=0;
            } else {
               status=repeat_idx;
            }
         }
         break;
      case 'Z2':
         // Play back the last insertion
         //
         if ( _vi_repeat_info0=='' ) {
            _vi_repeat_info_count='';
            vi_message('Nothing to repeat');
            return(1);
         }
         if ( last_key_or_count!='' ) {
            count=last_key_or_count;
         } else {
            parse _vi_repeat_info0 with . ',' . ',' count ',' .;
         }
         if ( isinteger(count) && count>0 ) {
            _vi_repeat_info_count=count;
         } else {
            _vi_repeat_info_count=1;
         }
         idx := find_index('vi_repeat_info',PROC_TYPE);
         if ( idx && index_callable(idx) ) {
            _vi_repeat_info=_vi_repeat_info0;
            parse _vi_repeat_info0 with repeat_idx ',' lkey ',' . ',' . ',' callback_idx;
            if ( repeat_idx && index_callable(repeat_idx) ) {
               for (;;) {
                  last_index(repeat_idx);
                  if ( lkey:!='' ) last_event(lkey);
                  if ( !isinteger(_vi_repeat_info_count) || _vi_repeat_info_count<1 ) {
                     _vi_repeat_info_count='';
                     if ( isinteger(callback_idx) && index_callable(callback_idx) ) {
                        call_index(callback_idx);
                     }
                     return(0);
                  }
                  --_vi_repeat_info_count;
                  gplaying_last_kbdmacro=true;
                  _macro('KP',null,_vi_last_kbdmacro);
                  gplaying_last_kbdmacro=false;
               }
            }
         } else {
            message('Invalid index for vi-repeat-info');
            status=1;
         }
         break;
      }
   } else {
      // Are we running OR recording a keyboard macro?
      if ( gplaying_last_kbdmacro || _macro('KI',0) ) {
         // We are recursing, so get out!
         return(0);
      }
      if ( index_callable(repeat_idx) ) {
         name=vi_name_eq_translate(name_name(repeat_idx));
         if ( vi_name_in_list(name,VI_CMDS_PLAYBACK) ) {
            // Last key pressed
            lkey=last_key_or_count;
            // Repeat count
            count=cb_name_or_count;
            // Clipboard name
            cb_name=cb_name;
            // Index to a callback function
            callback_idx=callback_idx;

            // Save copies of these incase the macro recording is aborted
            old_vi_repeat_info=_vi_repeat_info;
            old_vi_repeat_info0=_vi_repeat_info0;

            _vi_repeat_info=repeat_idx','lkey','count','cb_name','callback_idx;
            if ( pos(' 'name' ',VI_CMDS_INSERT) ) {
               // Make a copy for the last insertion
               _vi_repeat_info0=_vi_repeat_info;
               // Begin keyboard recording for insert commands
            } else {
               // Begin keyboard recording for non-insert commands
            }
            _vi_dot_kbdmacro_start_recording();
            if ( lkey:!='' ) {
               // Insert the key pressed which executed the last command
               // into the keyboard macro.
               _macro('KK',lkey,0);
            }
         }
      } else {
         message('Invalid index');
         status=1;
      }
   }

   return(status);
}

bool vi_name_in_list(_str name,_str string)
{
   _str temp=vi_name_eq_match('-p 'name,'1',string);
   if ( temp=='' ) {
      return(false);
   } else {
      return(true);
   }
}

static _str _vi_eq_string;

_str vi_name_eq_match(_str prefix_name,typeless find_first,_str string)
{
   if ( find_first ) {
      _vi_eq_string=string;
   }
   exact_match := false;
   if ( pos('-p',lowcase(strip(prefix_name)))==1 ) {
      exact_match=true;
      parse prefix_name with . prefix_name;
   }
   for (;;) {
      if ( _vi_eq_string=='' ) return('');
      name := "";
      parse _vi_eq_string with name _vi_eq_string;
      if ( exact_match ) {
         if ( name==prefix_name ) {
            return(strip(name));
         }
      } else {
         if ( substr(name,1,length(prefix_name)):==prefix_name ) {
            return(strip(name));
         }
      }
   }

}

_str vi_name_eq_translate(_str name)
{
   return(strip(translate(name,'-','_')));
}

_str _vi_search_type()
{
   if(!(_default_option('s')&VSSEARCHFLAG_ISRE)) {
      return 'N';
   }
   //if ( def_re_search_flags&VSSEARCHFLAG_UNIXRE ) {
   //   return('u');
   //} else if ( def_re_search_flags&VSSEARCHFLAG_BRIEFRE ) {
   //   return('b');
   //} else 
   if ( def_re_search_flags&VSSEARCHFLAG_PERLRE ){
      return('l');
   } else if ( def_re_search_flags&VSSEARCHFLAG_VIMRE ){
      return('~');
   } else if ( def_re_search_flags&VSSEARCHFLAG_WILDCARDRE ){
      return('&');
   } else {
      return('r');
   }
}

/**
 * Callback for flipping into vi insert mode before a diff starts.
 *
 * @see _diffOnExit_vi
 */
static _str gdiffOnStart_vi_mode="";
int _diffOnStart_vi()
{
   gdiffOnStart_vi_mode="";
   if ( def_keys=="vi-keys" ) {
      gdiffOnStart_vi_mode=vi_get_vi_mode();
      if ( gdiffOnStart_vi_mode=='C' ) {
         // arg(2)=0 tells vi_switch_mode() not to display messages
         vi_switch_mode('I',0);
      }
   }

   return(0);
}

/**
 * Callback for flipping back into vi command mode after diff exits.
 *
 * @see _diffOnStart_vi
 */
int _diffOnExit_vi()
{
   if ( def_keys=="vi-keys" ) {
      if ( gdiffOnStart_vi_mode=='C' && gdiffOnStart_vi_mode!=vi_get_vi_mode() ) {
         // arg(2)=0 tells vi_switch_mode() not to display messages
         vi_switch_mode('C',0);
      }
   }

   return(0);
}

/**
 * Returns the directory where Vim tutorial files reside. 
 * Currently this is under $VSROOT/sysconfig/vimtutor. 
 * 
 * @return _str Full directory path
 */
_str _vtGetTutorDir()
{
   return _getSysconfigPath() :+ "vimtutor" :+ FILESEP;
}

/**
 * Get the full file path to the Vim tutorial file. Right now we
 * only have the default tutor.txt file, but this allows use to 
 * add other languages in the future. 
 * 
 * @param langid Optional language identifier. Passing 'fr' 
 *               would return the path to tutor.fr.txt
 * 
 * @return _str Full path to Vim tutorial file
 */
_str _vtGetTutorFile(_str langid = '')
{
   if ( langid :== 'en' || langid :== 'EN' ) {
      langid = '';
   }
   if ( langid != '' ) {
      langid = '.' :+ langid;
   }
   return _getSysconfigMaybeFixPath("vimtutor" :+ FILESEP :+ "tutor":+langid:+".txt");
}

/**
 * Prompt user to switch to Vim emulation when running the Vim 
 * tutorial from a different emulation. 
 */
void _vtMaybeSwitchEmulation(){
   if ( def_keys!="vi-keys" ) {
      _str answer = _message_box("You are not currently using Vim emulation. Switch to Vim emulation now?",
                                 "SlickEdit Vim Tutor",  MB_YESNO | MB_ICONQUESTION);
      if ( answer == IDYES ) {
         execute('emulate VI');
      }
   }
}

/** 
 * Displays the Vim tutorial file, customized for SlickEdit 
 * users. 
 */
_command void vimtutor(_str langid='')
{
   // Get original tutor file from the sysconfig directory
   _str tutorFile = _vtGetTutorFile(langid);
   if (file_exists(tutorFile)) {

      // Make a temp copy in the user's config directory
      _str configPath = _ConfigPath();
      tempTutorCopy :=  configPath :+ "vimtutor";

      // Remove any existing old scratch copy.
      if (file_exists(tempTutorCopy)) {
         delete_file(tempTutorCopy);
      }

      // Edit the new copy in the config directory. 
      if (copy_file(tutorFile, tempTutorCopy) == 0) {
         edit(_maybe_quote_filename(tempTutorCopy));
         // Prompt to switch to Vim emulation if needed
         _vtMaybeSwitchEmulation();
      } else {
         message("Could not copy ":+tutorFile:+ " to ":+tempTutorCopy);
      }
   } else {
      message("Could not find ":+tutorFile);
   }
}
