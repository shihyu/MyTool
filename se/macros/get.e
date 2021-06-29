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
#import "bind.e"
#import "complete.e"
#import "context.e"
#import "help.e"
#import "prefix.e"
#import "proctree.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

//
//  This function reads user input into the command line.  Parameters
//  5-11 are used by the QUERY command which displays pop-up command lines.
//  Use the QUERY command if you want pop-up command lines.
//
//  INPUT
//   1  line            Undefined
//   2  prompt          The command prompt.
//   3  arg_type[;help_name]
//                      (optional) Used for argument completion and help.
//                      The argument type constants that provide completion
//                      are listed in "slick.sh".  Argument type constants
//                      have the suffix "_ARG".  For example, FILE_ARG is
//                      an argument type constant.  If arg_type starts with
//                      a '-' character, the arg_type is assumed to be the
//                      constant name without the "_ARG" portion (i.e. FILE for
//                      FILE_ARG).  If the arg_type starts with '-.', the
//                      string following is assumed to be a command name.
//                      help_name may specify a help item in "slick.doc"
//                      or be a message.  If help_name starts with a '.', it
//                      should specify a help item in "slick.doc". If not
//                      specified and arg_type starts with '-.', the
//                      help_name is assumed to be help on the command
//                      specified.
//
//
//                    Example  (Note FILE_ARG='F' and is defined in "slick.sh"
//
//                         -.edit              Completion/help on edit command
//                         F;.edit command     Completion/help on edit command
//                         F                   Completion on file argument
//                         -FILE;Message text  Completion on file argument
//                                             with pop-up message help.
//                         -.edit;Message text Completion on file argument
//                                             with pop-up message help.
//
//
//
//   4  Initial value   (optional) The command line is set to initial value.
//                      If you want to specify this parameter and you don't
//                      want to specify the third parameter, pass '' for the
//                      third parameter.
//   5  col             (optional) column position within command line.
//   6  left-edge       (optional) Scroll position of left edge.
//   7  pop-up x        (optional) x coordinate for pop-up command line.
//   8  pop-up y        (optional) y coordinate for pop-up command line.
//   9  pop-up width    (optional) width of pop-up command line.
//   10 pop-up color    (optional) color of pop-up command line.
//   11 multi fields    (optional) If 1, return to caller when TAB or BACKTAB
//                      keys pressed.
//  OUTPUT
//      line            The string entered by the user
//      return value for non-pop-up command line
//                      A non-zero return value indicates that the user
//                      aborted the input.
//      return value for pop-up command line may be parsed as show below:
//                 parse value ret_value with left_edge' 'cursor_x' 'status ;
//
//                 Possible values for status       meaning
//                         1                  User selected to cancel
//                         DOWN,TAB           Next pop-up command line
//                         UP,S_TAB           Previous pop-up command line
//                         F9                 Retrieve previous
//                         F10                Retrieve next
//                         ENTER              Pop-up command lines completed.
//
//          Example
//
//             defc  query_searchNreplace
//                status=get_string(search_string,'Search for: ')
//                if status then return(1) endif /* user abort */
//                status=get_string(replace_string,'Replace with: ')
//                if status then return(1) endif /* user abort */
//                message 'Options are: E,I,-,*,R,W  '||
//                   'E=exact case I=ignore case -=Rev *=Go R=R-E W=Word'
//                status=get_string(options,'Options: ')
//                if status then return(1) endif /* user abort */
//                search search_string,options,replace_string

_str _retrieve='';   /* If 1 retrieve last argument */
_str _pgetkey='';
_str _key='';

static bool hit_actapp;
void _actapp_get_string()
{
   hit_actapp=true;
}

static bool IsMouseButtonEvent(_str key)
{
   _str event_name=event2name(key);
   event_name_prefix := substr(event_name,1,8);
   return(event_name_prefix=='LBUTTON-'||
          event_name_prefix=='RBUTTON-'||
          event_name_prefix=='MBUTTON-'
          );
}

/** 
 * Prompts user for an input string on the command line.  The result is 
 * placed in the variable <i>line</i>.  The users response is initialized to 
 * <i>initial_value</i> if given.  <i>prompt</i> is displayed to left of user 
 * input area.   <b>get_string</b> supports retrieval based on the <i>prompt</i> 
 * argument and completion.
 *
 * @param line                (output) set to value entered by user
 * @param prompt              the command prompt.
 * @param arg_type_info       completion info has the syntax
 * <i>arg_type</i>[;<i>help_name</i>] and is used for argument completion and 
 * help.  <i>arg_type</i> may be any completion constant listed in "slick.sh'".  
 * Completion constants have the suffix "_ARG".  If <i>arg_type</i> starts with 
 * a '-' character,  the <i>arg_type</i> is assumed to be the completion 
 * constant name without the "_ARG" suffix  (i.e. "FILE" for FILE_ARG).  If the 
 * <i>arg_type</i> starts with "-.", the string following is assumed to be a 
 * command name.  The command name may be used to get the completion information 
 * and help.  <i>help_name</i> may specify a help item in "vslick.hlp" (UNIX: 
 * "uvslick.hlp") or be a message.  If <i>help_name</i> starts with a '.', it 
 * should specify a help item in "vslick.hlp" (UNIX: "uvslick.hlp").
 * @param initial_value (optional) The command line is set to initial value.
 * If you want to specify this parameter and you don't want to specify the third
 * parameter, pass '' for the third parameter.
 * 
 * @return Returns 0 if successful.  Otherwise 1 (user aborted) is returned.  
 * On error, message is displayed.
 *
 * @example
 * <pre>
 *      /* Completion/help on edit command. */
 *      status=get_string(line,'Filename: ', '-.edit')
 * 
 *      /* Completion/help on edit command. */
 *      status=get_string(line,'Filename: ', FILE_ARG';.edit command')
 * 
 *      /* Completion on file argument with pop-up message help. */
 *      status=get_string(line,'Filename: ','-FILE;Help message')
 *    
 *      /* Completion on file argument with pop-up message help. */
 *      status=get_string(line,'Filename: ','-.edit;Help message')
 * </pre>
 *
 * @see letter_prompt
 * @see prompt
 *
 * @categories Command_Line_Functions, Keyboard_Functions
 * 
 */
_str get_string(_str &line,_str prompt, _str arg_type_info='', _str initial_value='',bool select_initial_value=true)
{
   typeless arg_type='';
   typeless result=0;
   help_name := "";
   help_arg := "";
   completion_info := "";
   help_data := "";

   orig_wid := 0;

   hit_actapp=false;
   if (!_default_option(VSOPTION_HAVECMDLINE)) {
      prompt=strip(prompt);
      if (_last_char(prompt)!=':' && prompt != ':'EX_VISUAL_RANGE) {
         prompt :+= ':';
      }
      parse arg_type_info with arg_type ';' help_name;
      help_arg='';
      if (help_name!='') {
         if (substr(help_name,1,1)=='.') {
            parse help_name with '.' help_arg .;
         } else {
            help_arg='?'help_name;
         }
      } else {
         if (substr(arg_type,1,2)=='-.') {
           help_arg=substr(arg_type,3);
         }
      }

      parse arg_type_info with completion_info ';' help_data ;
      if ( substr(completion_info,1,2)=='-.' && help_data:=='' ) {
         help_data=substr(completion_info,2);
      }
      if ( substr(completion_info,1,1)=='-' ) {
         completion_info=get_completion_info(substr(completion_info,2));
      }
      if (completion_info!='') {
         completion_info='-c 'completion_info:+_chr(0);
      }
      //messageNwait('completion_info='completion_info);
      orig_wid=p_window_id;
      old_def_focus_select := def_focus_select;
      if (!select_initial_value) def_focus_select=false;
      result = show('-modal _textbox_form',
                    '', // Form caption
                    0,  //flags
                    '', //use default textbox width
                    help_arg, //Help item.
                    '', //Buttons and captions
                    '', //Retrieve Name
                    completion_info:+prompt:+initial_value);
      if (!select_initial_value) def_focus_select=old_def_focus_select;
      p_window_id=orig_wid;
      if (result=='') {
         _key=ESC;
         return(1);
      }
      result=_param1;
      _key=ENTER;
      line=_param1;
      return(0);
   }

   orig_wid = p_window_id;

   typeless state=0;
   typeless orig_state=command_state();
   if ( ! command_state() ) {
      command_toggle();
   }
   string := "";
   /* Reset command retrieval to end of buffer and get last retrieve value. */
   _reset_retrieve();
   if ( _retrieve==1 && initial_value:=='' ) {
      string='@'length(prompt)prompt;
      initial_value=retrieve_skip('',string,string);
      if ( initial_value!='' ) {
         initial_value=substr(initial_value,length(string)+1);
      }
   }
   _retrieve='';

   getEventFlags := 'F';
   typeless hit_retrieve=''; /* Want to rest command retrieve buffer if retrieve arguments. */
   /* messageNwait('arg5='arg5' arg6='arg6' arg7='arg7' arg8='arg8' arg9='arg9' erase_color='erase_color) */
   _str orig_prompt=prompt;
   typeless leave_cursor='';
   /* messageNwait('h1 state='command_state()) */
   if (_get_string!='' && call_index('',prompt,orig_prompt,leave_cursor,'',orig_wid,_get_string)) {
      // do nothing
   }
   orig_arg_completion_options := def_argument_completion_options;
   def_argument_completion_options=0;
   if (select_initial_value) {
      _cmdline.set_command(initial_value,1,length(initial_value)+1,prompt);
   } else {
      _cmdline.set_command(initial_value,length(initial_value)+1,length(initial_value)+1,prompt);
   }
   def_argument_completion_options=orig_arg_completion_options;
   typeless multi_fields=0;
   parse arg_type_info with completion_info ';' help_data ;
   if ( substr(completion_info,1,2)=='-.' && help_data:=='' ) {
      help_data=substr(completion_info,2);
   }
   reset_prev_index := 1;
   if ( substr(completion_info,1,1)=='-' ) {
      completion_info=get_completion_info(substr(completion_info,2));
   }
   _pgetkey=completion_info;
   _default_option(VSOPTION_STAY_IN_GET_STRING_COUNT,1);
   typeless junk='';
   old_first_key := false;
   done := false;
   old_cmdline := "";
   cmd_text := "";
   last_arg := "";
   name := "";
   cmd_col := 0;
   cmd_leftedge := 0;
   start_sel := 0;
   end_sel := 0;
   index := 0;
   key := "";
   for (;;) {
      state=orig_state;
      if ( ! command_state() && ! leave_cursor ) {
         state=command_state();
         cursor_command();
      }
      if ( reset_prev_index ) {
         prev_index(0);
      }
      reset_prev_index=1;
      leave_cursor=0;
      if ( _get_string2!='' ) {   /* Allow editing? */
         _edit_window()._undo('S');
         key=get_event(getEventFlags);
         _key=key;
         if ( call_index(key,prompt,orig_prompt,leave_cursor,'',orig_wid,_get_string) ) {
            def_argument_completion_options=0;
            _cmdline.get_command(cmd_text,cmd_col,cmd_leftedge);
            _cmdline.set_command(cmd_text,cmd_col,cmd_leftedge,prompt);
            def_argument_completion_options=orig_arg_completion_options;
            if (_isEditorCtl()) {
               _UpdateContext(true);
               _UpdateCurrentTag(true);
               _UpdateContextWindow(true);
            }
            continue;
         }
         break;
      } else {
         key=pgetkey(getEventFlags);
      }
      if (IsMouseButtonEvent(key)) {
         continue;
      }
      if ( isnormal_char(key) ) {
         if ( length(key)>1 ) {
            key=key2ascii(key);
         }
         brief_complete := (key:==\t);
         //brief_complete=(def_keys=='brief-keys' && key:==\t)
         if ( (key:=='?' || brief_complete) && completion_info!='') {
            if ( completion_info!='' ) {
               get_command(old_cmdline,start_sel,end_sel);
               old_first_key=false;
               if (p_sel_length==length(old_cmdline)) {
                  old_first_key=true;
                  set_command('',1);
               }
               if ( brief_complete ) {
                  last_arg=maybe_list_matches(completion_info,'',true,true);
               } else {
                  last_arg=maybe_list_matches(completion_info,'',false,true);
               }
               hit_actapp=false;
               cursor_command();
               if ( last_arg && (multi_fields=='' ||
                  (multi_fields:==1 && p_Noflines<=2)) ) {
                  key=ENTER;
                  break;
               }
            } else {
               _cmdline.keyin(key);
            }
         } else if ( key:==' ' && completion_info!='' ) {
            if ( completion_info!='' ) {
               _cmdline.maybe_complete(completion_info);
            } else {
               _cmdline.keyin(key);
            }
         } else {
            _cmdline.keyin(key);
         }
         if (completion_info != '' || orig_prompt!='') {
            string='@'length(orig_prompt)orig_prompt;
            ArgumentCompletionUpdateTextBox(completion_info,string);
         }
         continue;
      }
      if (hit_actapp) {
         key=ESC;
         break;
      }
      if ( key:==BACKSPACE ) {
         _cmdline._rubout();
         if (completion_info != '' || orig_prompt!='') {
            string='@'length(orig_prompt)orig_prompt;
            ArgumentCompletionUpdateTextBox(completion_info,string);
         }
      } else if ( key:==DEL ) {
         _cmdline._delete_char();
         if (completion_info != '' || orig_prompt!='') {
            string='@'length(orig_prompt)orig_prompt;
            ArgumentCompletionUpdateTextBox(completion_info,string);
         }
      } else if ( key:==RIGHT ) {
         _cmdline.right();
      } else if ( key:==LEFT ) {
         _cmdline.left();
      } else {
         index=eventtab_index(_default_keys,_default_keys,event2index(key));
         if ( (name_type(index)== EVENTTAB_TYPE) ) {
            prompt_for_key('',index,key,junk,'R','1');
            index=eventtab_index(index,index,event2index(key));
         }
         name=name_name(index);
         done=false;
         _cmdline.get_command(cmd_text);
         if ( key:==ENTER ) {
            ArgumentCompletionKey(key);
            break;
         } else if ( _get_string!='' && call_index(key,prompt,orig_prompt,leave_cursor,'',orig_wid,_get_string) ) {
            def_argument_completion_options=0;
            _cmdline.get_command(cmd_text,cmd_col,cmd_leftedge);
            _cmdline.set_command(cmd_text,cmd_col,cmd_leftedge,prompt);
            def_argument_completion_options=orig_arg_completion_options;
         } else if ( multi_fields:=='1' && (key:==TAB || key:==S_TAB ||
                     key:==F9 || key:==F10) ) {
            break;
         } else if ( key:==UP || name=='cursor-up' || name=='retrieve-prev' ) {
            if (ArgumentCompletionKey(key)) continue;
            hit_retrieve='1';
            string='@'length(orig_prompt)orig_prompt;
            get_command(line);
            def_argument_completion_options=0;
            result=retrieve_skip('',string,string:+line);
            if ( result!='' ) {
               result=substr(result,length(string)+1);
               set_command(result,1,length(result)+1);
            }
            def_argument_completion_options=orig_arg_completion_options;
         } else if ( key:==DOWN || name=='cursor-down' ||  name=='retrieve-next' ) {
            if (ArgumentCompletionKey(key)) continue;
            hit_retrieve='1';
            string='@'length(orig_prompt)orig_prompt;
            get_command(line);
            def_argument_completion_options=0;
            result=retrieve_skip('N',string,string:+line);
            if ( result!='' ) {
               result=substr(result,length(string)+1);
               set_command(result,1,length(result)+1);
            }
            def_argument_completion_options=orig_arg_completion_options;
         } else if ( key:==LBUTTON_DOWN && command_state() ) {
            mou_click();
         } else if ( key:==name2event("s-lbutton-down") && command_state() ) {
            mou_click('','E');
         } else if (key:==PGUP || key:==PGDN) {
            ArgumentCompletionKey(key);
         } else if ( name_info_arg2(index) & VSARG2_TEXT_BOX) {
            if (key:==HOME || key:==END) {
               if (ArgumentCompletionKey(key)) continue;
            }
            reset_prev_index=0;
            if (command_state()){
               call_index(index);
            } else {
               p_window_id=_mdi.p_child;
               call_index(index);
               p_window_id=_cmdline;
            }
            prev_index(index);
         } else if ( name=='esc-alt-prefix' ) {
            if ( completion_info!='' ) {
               if ( esc_alt_prefix(completion_info) ) {
                  key='';
                  break;
               }
            }
         } else if ( name=='insert-toggle' ) {
            _cmdline._insert_toggle();
         } else if ( (key:==F1 || name_on_key(key)=='help') && help_data!='') {
            if ( substr(help_data,1,1)!='.' ) {
               popup_message(help_data);
            } else if ( substr(help_data,2)!='' ) {
               name = substr(help_data, 2);
               help(name);
               // Under windows, get_event does not seem to generate ESC automatically
               key= ESC;
               break;
            }
         } else if ( iscancel(key)) {
            if (ArgumentCompletionKey(key)) continue;
            break;
         }
      }
   }
   _default_option(VSOPTION_STAY_IN_GET_STRING_COUNT,0);
   ArgumentCompletionTerminate();
   _pgetkey='';
   if ( command_state() != state ) {
      if ( orig_wid ) {
         p_window_id = orig_wid;
         // _set_focus() will change the current mdi-window (as reported 
         // by _CurrentMDI()) if orig_wid is in a different mdi-window. 
         // This happens, for example, in edit() where the active window
         // is set to the current mdichild editor control before prompt()ing
         // for the filename to open.
         if ( !(p_mdi_child || p_active_form.p_isToolWindow) || _MDIFromChild(p_window_id) == _MDICurrent() ) {
            _set_focus();
         }
      } else {
         command_toggle();
      }
   }
   if (_get_focus()!=_cmdline) {
      _cmdline.p_visible=false;
   }
   _cmdline.get_command(line);
   _cmdline.set_command('',1,1,'');
   if ( hit_retrieve!='' ) {
      int v;
      get_window_id(v);
      activate_window(VSWID_RETRIEVE);
      bottom();
      activate_window(v);
   }
   if ( iscancel(key) ) {
      status := 2;
      if ( iscancel(key) ) {
         status=1;
      }
      return(status);
   }
   append_retrieve_command('@'length(orig_prompt)orig_prompt:+line);
   return(0);
}

_str get_string2(_str &line,_str prompt, _str arg_type_info='', _str initial_value='')
{
   hit_actapp=true;
   orig_wid := p_window_id;
   int orig_state=command_state();
   if ( ! command_state() ) {
      command_toggle();
   }
   string := "";
   /* Reset command retrieval to end of buffer and get last retrieve value. */
   if (_default_option(VSOPTION_HAVECMDLINE)) _reset_retrieve();
   if ( _retrieve==1 && initial_value:=='' ) {
      string='@'length(prompt)prompt;
      if (_default_option(VSOPTION_HAVECMDLINE)) initial_value=retrieve_skip('',string,string);
      if ( initial_value!='' ) {
         initial_value=substr(initial_value,length(string)+1);
      }
   }
   _retrieve='';

   typeless refresh_flags='';   /* Refresh the command only. */
   typeless hit_retrieve=''; /* Want to rest command retrieve buffer if retrieve arguments. */
   /* messageNwait('arg5='arg5' arg6='arg6' arg7='arg7' arg8='arg8' arg9='arg9' erase_color='erase_color) */
   _str orig_prompt=prompt;
   /* messageNwait('h1 state='command_state()) */
   typeless leave_cursor='';
   if (_get_string!='' && call_index('',prompt,orig_prompt,leave_cursor,'',orig_wid,_get_string)) {
      // do nothing
   }

   _str msg_text=initial_value;
   message(prompt:+msg_text);
   multi_fields := 0;
   completion_info := "";
   help_data := "";
   parse arg_type_info with completion_info ';' help_data ;
   if ( substr(completion_info,1,2)=='-.' && help_data:=='' ) {
      help_data=substr(completion_info,2);
   }
   reset_prev_index := true;
   if ( substr(completion_info,1,1)=='-' ) {
      completion_info=get_completion_info(substr(completion_info,2));
   }
   _pgetkey=completion_info;
   done := false;
   index := 0;
   typeless junk='';
   name := "";
   cmd_text := "";
   /* refresh_flags=refresh_flags'r' */
   key := "";
   for (;;) {
      if ( reset_prev_index ) {
         prev_index(0);
      }
      reset_prev_index=true;
      leave_cursor=0;
      if ( _get_string2!='' ) {   /* Allow editing? */
         _edit_window()._undo('S');
         key=get_event(refresh_flags);
         _key=key;
         if ( call_index(key,prompt,orig_prompt,leave_cursor,'',orig_wid,_get_string) ) {
            parse get_message() with ': 'msg_text;
            message(prompt:+msg_text);
            //_cmdline.get_command cmd_text,cmd_col,cmd_leftedge;
            //_cmdline.set_command cmd_text,cmd_col,cmd_leftedge,prompt;
            if (_isEditorCtl()) {
               _UpdateContext(true);
               _UpdateCurrentTag(true);
               _UpdateContextWindow(true);
            }
            continue;
         }
         break;
      } else {
         key=pgetkey(refresh_flags);
      }
      if ( isnormal_char(key) ) {
         if ( length(key)>1 ) {
            key=key2ascii(key);
         }
         //brief_complete=(def_keys=='brief-keys' && key:==\t)
         //brief_complete=(key:==\t);
         _cmdline.keyin(key);
         continue;
      }
      if (hit_actapp) {
         key=key;
         break;
      }
      if ( key:==BACKSPACE ) {
         //parse get_message() with prompt': 'msg_text;
         if (length(msg_text)) {
            msg_text=substr(msg_text,1,length(msg_text)-1);
            message(prompt:+msg_text);
         }
      } else {
         index=eventtab_index(_default_keys,_default_keys,event2index(key));
         if ( (name_type(index)== EVENTTAB_TYPE) ) {
            prompt_for_key('',index,key,junk,'R','1');
            index=eventtab_index(index,index,event2index(key));
         }
         name=name_name(index);
         done=false;
         cmd_text=msg_text;
         if ( key:==ENTER ) {
            break;
         } else if ( _get_string!='' && call_index(key,prompt,orig_prompt,leave_cursor,'',orig_wid,_get_string) ) {
            parse get_message() with ': 'msg_text;
            message(prompt:+msg_text);

            //_cmdline.get_command cmd_text,cmd_col,cmd_leftedge
            //_cmdline.set_command cmd_text,cmd_col,cmd_leftedge,prompt
         } else if ( multi_fields:=='1' && (key:==TAB || key:==S_TAB ||
                     key:==F9 || key:==F10) ) {
            break;
         } else if ( name=='rubout' || name=='linewrap-rubout') {
            if (length(msg_text)) {
               msg_text=substr(msg_text,1,length(msg_text)-1);
               message(prompt:+' ':+msg_text);
            }
#if 0
         } else if ( key:==UP || name=='cursor-up' || name=='retrieve-prev' ) {
               hit_retrieve='1'
               string='@'length(orig_prompt)orig_prompt
               get_command line
               result=retrieve_skip('',string,string:+line)
               if ( result!='' ) {
                  result=substr(result,length(string)+1)
                  set_command result,1,length(result)+1
               }
         } else if ( key:==DOWN || name=='cursor-down' ||  name=='retrieve-next' ) {
               hit_retrieve='1'
               string='@'length(orig_prompt)orig_prompt
               get_command line
               result=retrieve_skip('N',string,string:+line)
               if ( result!='' ) {
                  result=substr(result,length(string)+1)
                  set_command result,1,length(result)+1
               }
         } else if ( key:==LBUTTON_DOWN && command_state() ) {
            mou_click()
         } else if ( key:==name2event("s-lbutton-down") && command_state() ) {
            mou_click('','','E')
         } else if ( name_info_arg2(index) & VSARG2_TEXT_BOX) {
            reset_prev_index=0
            if (command_state()){
               call_index(index)
            } else {
               p_window_id=_mdi.p_child;
               call_index(index)
               p_window_id=_cmdline;
            }
            prev_index(index)
         } else if ( name=='esc-alt-prefix' ) {
            if ( completion_info!='' ) {
               if ( esc_alt_prefix(completion_info) ) {
                  key=''
                  break
               }
            }
         } else if ( name=='insert-toggle' ) {
            _cmdline._insert_toggle
#endif
         } else if ( (key:==F1 || name_on_key(key)=='help') && help_data!='') {
            if ( substr(help_data,1,1)!='.' ) {
               popup_message(help_data);
            } else if ( substr(help_data,2)!='' ) {
               help(name);
               // Under windows, get_event does not seem to generate ESC automatically
               key= ESC;
               break;
            }
         } else if ( iscancel(key) ) {
            break;
         }
      }
   }
   _pgetkey='';
   parse get_message() with ': 'line;
   //line=prompt;
   clear_message();
   if ( hit_retrieve!='' ) {
      int v;
      get_window_id(v);
      activate_window(VSWID_RETRIEVE);
      bottom();
      activate_window(v);
   }
   if ( iscancel(key) ) {
      status := 2;
      if ( iscancel(key) ) {
         status=1;
      }
      return(status);
   }
   append_retrieve_command('@'length(orig_prompt)orig_prompt:+line);
   return(0);
}

