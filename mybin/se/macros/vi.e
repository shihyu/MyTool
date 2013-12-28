////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50176 $
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
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

_str     def_vi_mode;
boolean  def_vi_start_in_insert_mode=false;
// Even if the 'c' command changes multiple lines, preview them
boolean  def_vi_always_preview_change;
boolean  def_vi_left_on_escape;
_str     def_vi_insertion_pos;
boolean  def_vi_show_msg;
// 1 = enable vi command-mode in the '.process' buffer
boolean  def_vi_ignore_process_keys;
_str     def_vi_chars='A-Za-z0-9_';
_str     def_vi_chars2='\!\@\#\$\%\^\&\*\(\)\-\+\|\=\\\{\}\[\]\"\39\`\:\;\~\?\/\,\.\>\<';
_str     vi_old_search_string;
int      vi_old_search_flags;
_str     vi_old_word_re;
_str     old_search_string;
typeless old_search_flags;
_str     old_word_re;
_str     _vi_prev_context;

// Non-zero = when in vi emulation, put build window into command mode
boolean def_vi_ignore_process_keys;

// Holds the index of the command to repeat, lastkey pressed, a
// repeat count, and additional arguments to pass to the command.
_str _vi_repeat_info='';
// Holds the index of the insert command to repeat, lastkey pressed,
// a repeat count, and additional arguments to pass to the command.
_str _vi_repeat_info0='';
// Whether or not to always highlight all matches found with Vim search
boolean def_vi_always_highlight_all;


#define VI_COMMAND_MODE_MSG "-- COMMAND --"
#define VI_INSERT_MODE_MSG  "-- INSERT --"
#define VI_VISUAL_MODE_MSG  "-- VISUAL --"

// A list of recorded events used during recorded macro playback
static _str _vi_ge_events;

// Pull chars backspace
static boolean _vi_pull;

definit()
{
   boolean show_message=1;
   if ( arg(1)=='L' ) {
      // This is handy when changing emulations
      show_message=0;
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
   def_vi_insertion_pos='';
   if ( !isinteger(def_vi_show_msg) ) {
      def_vi_show_msg=true;
   }
   if ( !isinteger(def_vi_ignore_process_keys) ) {
      def_vi_ignore_process_keys=false;
   }
   if ( ! isinteger(def_vi_left_on_escape) ) {
      def_vi_left_on_escape=true;
   }
   if ( ! isinteger(def_vi_always_highlight_all) ) {
      def_vi_always_highlight_all=true;
   }
   vi_old_search_string='';
   _str vi_old_replace_string='';
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

   // Remember def_pull setting (Pull chars backspace)
   _vi_pull=def_pull;

   // Abort any vi keyboard macro currently being recorded
   _macro('KA');

   rc=0;
}

/**
 * By default this command handles ESC pressed.
 */
_command int vi_escape() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   boolean in_process=(substr(p_buf_name,1,length(".process"))==".process"  || _process_info('B'));
   boolean in_fileman=(p_LangId=="fileman");
   if ( in_process || in_fileman ) return(0);

   // Put editor into command mode
   typeless status=0;
   _str mode=upcase(vi_get_vi_mode());
   if ( mode=='C' ) {
      // Already in command mode
      //
      // However, call vi-switch-mode() to loop through the buffers and make sure
      vi_switch_mode('');
      vi_message('Already in command mode');
   } else if ( mode=='I' ) {
      if ( vi_repeat_info('I') ) {
         int repeat_idx=vi_repeat_info('X');
         _str cmdname=vi_name_eq_translate(name_name(repeat_idx));
         int is_posted_cmd=pos(' 'cmdname' ',POSTED_INSERT_CMDS);
         if ( is_posted_cmd ) {
            vi_repeat_info('D');
            vi_repeat_info('E');
            last_index(repeat_idx,'C');
            int count=vi_repeat_info('C');
            if ( isinteger(count) && count>1 ) {
               if ( cmdname=='vi-replace-line' ) _insert_state('1');
               // Pass (count-1) as a playback count
               vi_repeat_info('Z2',count-1);
               return(0);
            }
         }
      }
      int col=p_col;
      status=vi_switch_mode('C');
      if ( !status ) {
         // Clear the beginning insertion pos marker
         def_vi_insertion_pos='';
         if ( def_vi_left_on_escape && p_col==col ) {
            left();
         }
      }
   } else if (mode == 'V') {
      vi_visual_toggle();
      vi_switch_mode('C');
   }

   // "Pull chars backspace" option is restored to it's previous setting.
   // This is usually done when user calls vi_replace_line ('R').
   _vi_restore_pull();

   // End keyboard recording
   vi_repeat_info('E');
   return(status);
}

int vi_message(_str msg, _str arg2="")
{
   int this_idx=find_index('vi-message',PROC_TYPE);
   if ( last_index()==this_idx ) {
      flush_keyboard();
   }
   last_index(this_idx);
   arg2=upcase(strip(arg2));
   int do_beep=pos('B',arg2);
   int show_msg=pos('M',arg2);
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
int vi_switch_mode(_str mode, _str showMessage="", typeless arg3="")
{
   if (!_isEditorCtl()) {
      // If the current object is not an editor control, this function cannot
      // continue.
      return(1);
   }
   // Do not change the mode of the .process buffer or the Fileman
   boolean in_process=(substr(p_buf_name,1,length(".process"))==".process"  || _process_info('B'));
   boolean in_fileman=(p_LangId=="fileman");
   boolean in_grep=_isGrepBuffer(p_buf_name);
   int orig_view_id=p_window_id;
   if ( in_process || in_fileman || in_grep ) {
      // Switch temporarily to the hidden view to enable the switch
      p_window_id=VSWID_HIDDEN;
   }

   boolean show_message=(showMessage=="" || showMessage);
   mode=upcase(strip(mode));
   def_vi_mode=upcase(strip(def_vi_mode));
   boolean showmode=__ex_set_showmode();
   showmode=(isinteger(showmode) && showmode>0);
   if ( mode:=='I' ) {
      if (def_vi_mode:=='V') return(0);
      def_vi_mode='I';
      if ( show_message && showmode ) {
         sticky_message(VI_INSERT_MODE_MSG);
      }
   } else if ( mode:=='C' ) {
      // This will also reset the mode if 'mode' is invalid
      if (def_vi_mode:=='V') return(0);
      def_vi_mode='C';
      if ( show_message && showmode ) {
         sticky_message(VI_COMMAND_MODE_MSG);
      }
   } else if ( mode:=='V') {
      if (def_vi_mode:=='V') {
         def_vi_mode='C';
         if ( show_message && showmode ) {
            sticky_message(VI_COMMAND_MODE_MSG);
         }
      } else {
         def_vi_mode='V';
         if ( show_message && showmode ) {
            sticky_message(VI_VISUAL_MODE_MSG);
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
      _str keytab_name=LanguageSettings.getKeyTableName(p_LangId);
      int insert_mode_keytab_idx=find_index(keytab_name,EVENTTAB_TYPE);
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
   return(upcase(strip(def_vi_mode)));
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
   int cur_line=p_line;
   int cur_col=p_col;
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
int vi_search(_str re, _str options)
{
   if (def_vi_always_highlight_all && !pos('*#', options)) {
      options = options :+ "*#";
   }
   if (pos('*#', options)) {
      clear_highlights();
   }
   int status=search(re,options);
   save_search(old_search_string,old_search_flags,old_word_re);
   set_find_next_msg("");
   if (!status && pos('*', options)) {
      typeless orig_pos; save_pos(orig_pos);
      top(); up();
      for (;;) {
         if (repeat_search()) break;
      }
      restore_pos(orig_pos);
   }
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
   _str return_event="";
   if ( event :!= '' ) {
      // We are loading events manually
      _vi_ge_events=_vi_ge_events:+event;
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

/**
 * This function is called by other functions like next_buffer(), prev_buffer().
 * <P>
 * This will display the current mode if the SHOWMODE option is turned ON
 */
int _switchbuf_vi(_str old_buffer_name, _str options="")
{
   _str keys=upcase(strip(translate(def_keys,'-','_')));
   if ( keys=="VI-KEYS" ) {
      if (def_vim_start_in_cmd_mode) {
         vi_switch_mode("c");
      }
      _str mode=vi_get_vi_mode();
      if ((mode=='C' && p_mode_eventtab!=find_index('vi-command-keys',EVENTTAB_TYPE)) ||
          (mode!='C' && p_mode_eventtab==find_index('vi-command-keys',EVENTTAB_TYPE))
         ) {
         //messageNwait('_switchbuf_vi');
         vi_switch_mode(vi_get_vi_mode(),upcase(options)!='W');
      }
      _str read_only="Read only";
      boolean showmode=__ex_set_showmode();
      showmode=(isnumber(showmode) && showmode>0);
      if ( showmode && upcase(options)!='W' ) {
         if ( p_readonly_mode) {
            sticky_message(VI_COMMAND_MODE_MSG);
         } else {
            mode=upcase(vi_get_vi_mode());
            if ( mode=='C' ) {
               sticky_message(VI_COMMAND_MODE_MSG);
            } else {
               sticky_message(VI_INSERT_MODE_MSG);
            }
         }
      }
   }

   return(0);
}

/**
 * This function copies marked text to the clipboard and to clipboard '0'.
 */
int vi_cut(boolean copy_option, _str cb_name, typeless doPush="")
{
   boolean stack_push=(doPush!='' && doPush);
   if ( cb_name!='' && (length(cb_name)!=1 || ! isalnum(cb_name)) ) {
      vi_message('Invalid clipboard name: "'cb_name'"');
      return(1);
   }
   boolean replace_mark_option=1;
   if ( cb_name!='' && _UTF8Asc(_maybe_e2a(cb_name))>=EB_ASCII_A && _UTF8Asc(_maybe_e2a(cb_name))<=EB_ASCII_Z ) {
      // If 'cb_name' is uppercase then append to the named clipboard
      replace_mark_option=0;
      cb_name=lowcase(cb_name);
   }
   if ( !select_active() ) {
      vi_message('There is no selection active');
      return(1);
   }
   // Make an exact copy of the mark
   typeless status=0;
   typeless mark=_duplicate_selection();
   // Are we pushing the clipboard on the stack AND is the name of the
   // clipboard != '0' already?
   if ( (stack_push || cb_name!='') && cb_name!=VI_CB0 ) {
      // First copy to clipboard '0'
      status=cut(1,true,VI_CB0);
      typeless old_mark=_duplicate_selection('');
      // Must show this again so we can copy to normal clipboard
      _show_selection(mark);
      status=cut(replace_mark_option,copy_option,cb_name);
      // Show 'old_mark' so we can free 'mark'
      _show_selection(old_mark);
   } else {
      status=cut(1,copy_option,VI_CB0);
   }
   _str num_lines = count_lines_in_selection(mark);
   if (isinteger(num_lines)) {
      if ((int)num_lines > 2) {
         vi_message(nls(num_lines' lines yanked'));
      }
   }
   _free_selection(mark);

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
   _str name="";

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
      int is_playback_cmd=pos(' 'name' ',PLAYBACK_CMDS);
      if ( isinteger(override_count) && override_count>0 ) {
         count=override_count;
      }
      if ( isalnum(override_cb_name) ) {
         cb_name=override_cb_name;
      }
      // Reset with (possibly) new count and clipboard name
      _vi_repeat_info=repeat_idx','lkey','count','cb_name','callback_idx;
      if ( is_playback_cmd ) {
         int is_posted_cmd=pos(' 'name' ',POSTED_INSERT_CMDS);
         if ( is_posted_cmd ) {
            // Just in case its been updated
            _vi_repeat_info0=_vi_repeat_info;
            status=vi_repeat_info('Z2');
         } else {
            // Play back the last recorded keyboard macro
            _macro('KP');
         }
      }
   } else if ( !isinteger(repeat_idx) ) {
      _str option=upcase(strip(repeat_idx));
      switch (option) {
      case 'A':
         // Abort the currently recording keyboard macro?
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
         status=_macro('KD');
         break;
      case 'E':
         // End the recording of the currently recording keyboard macro
         //
         status=_macro('KE');
         break;
      case 'I':
         // Are we currently recording a keyboard macro?
         //
         status=_macro('KI');
         break;
      case 'N':
         // Return the clipboard name for the command being played back?
         //
         // This is the clipboard name passed in from the command
         // currently being recorded.
         arg2=last_key_or_count;
         if ( _macro('KI') ) {
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
         int idx=find_index('vi_repeat_info',PROC_TYPE);
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
                  _macro('KP','0');
               }
            }
         } else {
            message('Invalid index for vi-repeat-info');
            status=1;
         }
         break;
      }
   } else {
      // Are we playing back OR recording a keyboard macro?
      if ( _macro('KR') || _macro('KI') ) {
         // We are recursing, so get out!
         return(0);
      }
      if ( index_callable(repeat_idx) ) {
         name=vi_name_eq_translate(name_name(repeat_idx));
         if ( vi_name_in_list(name,PLAYBACK_CMDS) ) {
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
            if ( pos(' 'name' ',INSERT_CMDS) ) {
               // Make a copy for the last insertion
               _vi_repeat_info0=_vi_repeat_info;
               // Begin keyboard recording for insert commands
               _macro('KB','0');
            } else {
               // Begin keyboard recording for non-insert commands
               _macro('KB','1');
            }
            if ( lkey:!='' ) {
               // Insert the key pressed which executed the last command
               // into the keyboard macro.
               _macro('KK',lkey);
            }
         }
      } else {
         message('Invalid index');
         status=1;
      }
   }

   return(status);
}

boolean vi_name_in_list(_str name,_str string)
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
   boolean exact_match=0;
   if ( pos('-p',lowcase(strip(prefix_name)))==1 ) {
      exact_match=1;
      parse prefix_name with . prefix_name;
   }
   for (;;) {
      if ( _vi_eq_string=='' ) return('');
      _str name="";
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
   if ( def_re_search&UNIXRE_SEARCH ) {
      return('u');
   } else if ( def_re_search&BRIEFRE_SEARCH ) {
      return('b');
   } else if ( def_re_search&VSSEARCHFLAG_PERLRE ){
      return('l');
   } else {
      return('r');
   }
}

void _vi_save_pull()
{
   _vi_pull=def_pull;
}
void _vi_restore_pull()
{
   def_pull=_vi_pull;
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
   _str syscfgRoot = get_env("VSROOT");
   _maybe_append_filesep(syscfgRoot);
   return(syscfgRoot:+"sysconfig":+FILESEP:+"vimtutor");
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
   _str tutorDir = _vtGetTutorDir();
   _maybe_append_filesep(tutorDir);
   _str tutorFile = tutorDir:+"tutor":+langid:+".txt";
   return tutorFile;
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
      _str tempTutorCopy = configPath :+ "vimtutor";

      // Remove any existing old scratch copy.
      if (file_exists(tempTutorCopy)) {
         delete_file(tempTutorCopy);
      }

      // Edit the new copy in the config directory. 
      if (copy_file(tutorFile, tempTutorCopy) == 0) {
         edit(maybe_quote_filename(tempTutorCopy));
         // Prompt to switch to Vim emulation if needed
         _vtMaybeSwitchEmulation();
      } else {
         message("Could not copy ":+tutorFile:+ " to ":+tempTutorCopy);
      }
   } else {
      message("Could not find ":+tutorFile);
   }
}
