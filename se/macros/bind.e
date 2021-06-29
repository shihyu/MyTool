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
#include "vsevents.sh"
#import "b2k.e"
#import "complete.e"
#import "files.e"
#import "help.e"
#import "main.e"
#import "prefix.e"
#import "recmacro.e"
#import "stdprocs.e"
#import "tags.e"
#import "xml.e"
#endregion

static const MOUSE_EVENT_NAMES= (\
                      '/lbutton-down='0' ':+\
                      '/rbutton-down='1' ':+\
                      '/mbutton-down='2' ':+\
                      '/back-button-down='3' ':+\
                      '/forward-button-down='4' ':+\
                      '/lbutton-double-click='5' ':+\
                      '/rbutton-double-click='6' ':+\
                      '/mbutton-double-click='7' ':+\
                      '/back-button-double-click='8' ':+\
                      '/forward-button-double-click='9' ':+\
                      '/lbutton-triple-click='10' ':+\
                      '/rbutton-triple-click='11' ':+\
                      '/mbutton-triple-click='12' ':+\
                      '/back-button-triple-click='13' ':+\
                      '/forward-button-triple-click='14' ':+\
                      '/wheel-up='21' ':+\
                      '/wheel-down='22);
   static _str gme_names;

/**
 * @return If <i>return_text</i> is not given or is '', this command displays the 
 * key(s) that are bound to <i>command</i> on the message line and 
 * returns 0.  Otherwise, the message that would be displayed on the 
 * message line is returned.
 * 
 * @categories Keyboard_Functions
 * 
 */ 
_command where_is(_str commandName='', _str quiet='',_str separatorChar=',') name_info(COMMAND_ARG',')
{
  _str arg1=prompt(commandName,'Where is command');
  index := find_index(arg1,COMMAND_TYPE);
  if ( ! index ) {
    if (quiet=='' ) {
       message(nls("Can't find command '%s'",arg1));
       return(1);
    }
    return("");
  }

  view_id := 0;
  get_window_id(view_id);
  key_binding_list := "";
  int mode=(p_HasBuffer)?p_mode_eventtab: _edit_window().p_mode_eventtab;
  append_key_bindings(index,key_binding_list,'',_default_keys,mode,quiet==3,separatorChar);
  activate_window(view_id);

  text := "";
  if ( key_binding_list=='' ) {
    text=nls('%s is not bound to a key',arg1);
  } else {
    text=nls('%s is bound to %s',arg1,strip(key_binding_list));
  }
  if ( quiet=='' ) {
     if (_no_child_windows()) {
        VSWID_STATUS._set_focus();
     }
     message(text);
  } else {
     if ( quiet==2 || quiet==3 ) {
        return(key_binding_list);
     } else {
        return(text);
     }
  }
  return(0);
}
/**
 * @return Returns the key(s) that are bound to <i>commandName</i>. 
 *  
 * @categories Keyboard_Functions
 */ 
_str _where_is(_str commandName='',_str separatorChar=',')
{
  index := find_index(commandName,COMMAND_TYPE);
  if ( ! index ) {
    return("");
  }
  key_binding_list := "";
  get_window_id(auto orig_view_id);
  append_key_bindings(index,key_binding_list,'',_default_keys,p_mode_eventtab,true,separatorChar);
  activate_window(orig_view_id);
  return strip(key_binding_list);
}
/**
 * Sets variable key_binding_list to key sequence separated by commas 
 * which are bound to the command index specified.  prefix_keys and 
 * the variable key_binding_list should be initialized to ''.  root_keys 
 * and mode_keys are name table indexes to event tables.
 * 
 * @param key_binding_list
 * @param ReturnFirstOnly
 * @categories Keyboard_Functions
 */
void append_key_bindings(int index,_str &key_binding_list,_str prefix_keys,
                         int _root_keys,int _mode_keys,bool ReturnFirstOnly=false,
                         _str separatorChar=',')
{
   VSEVENT_BINDING hashtab:[];
   VSEVENT_BINDING partial_list[];
   _str list[];
   list_bindings(_root_keys,partial_list,index);
   int i;
   for (i=0;i<partial_list._length();++i) {
      // If there is no mode binding
      if (!eventtab_index(_mode_keys,_mode_keys,partial_list[i].iEvent)) {
         list[list._length()]=_right_justify(partial_list[i].iEvent,10)' 'partial_list[i].iEndEvent;
      }
   }
   // Now append all the mode bindings
   list_bindings(_mode_keys,partial_list,index);
   for (i=0;i<partial_list._length();++i) {
      list[list._length()]=_right_justify(partial_list[i].iEvent,10)' 'partial_list[i].iEndEvent;
   }
   list._sort('');

   for (i=0;i<list._length();++i) {
      //int key_index=list[i];
      _str startStr,endStr;
      parse list[i] with startStr endStr;
      int key_index=(int)startStr;
      int keyend_index=(int)endStr;

      name_index_found := eventtab_index(_root_keys,_mode_keys,key_index);
      /*list_bindings(key_index,name_index_found,keys_used,
                    _root_keys,_mode_keys,index);
      if ( key_index<0 ) break;*/
      // don't show Mac specific keys on any platform other than the Mac
      if (!_isMac() && (key_index & VSEVFLAG_COMMAND)) {
         continue;
      }
      _str key_name=_key_for_display(index2event(key_index));

      if ( name_type(name_index_found)&EVENTTAB_TYPE ) {
         append_key_bindings(index,key_binding_list,prefix_keys " "key_name,
                                  name_index_found,name_index_found,ReturnFirstOnly,separatorChar);
      } else {
         if (ReturnFirstOnly && key_binding_list!='') {
            return;
         }
         /*
           I didn't use <keystart>..<keyend> because I think this will break
           some calls which use the first keybinding.
         */
         int j;
         for (j=key_index;j<=keyend_index;++j) {
            key_name=_key_for_display(index2event(j));
            if ( key_binding_list!='' ) key_binding_list :+= separatorChar;
            key_binding_list :+= prefix_keys " "key_name;
         }

      }
  }
}
/** 
 * Inserts Slick-C&reg; source code for the binding of the key(s) you type.
 * Displays message if key sequence pressed has no definition.
 * 
 * @categories Keyboard_Functions
 * 
 */
_command void insert_keydef() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _macro_delete_line();
   typeless keytab_used='';
   typeless keyname='';
   typeless k='';
   typeless status= prompt_for_key(nls('Insert def for key:')' ',keytab_used,k,keyname);
   if ( status ) return;
   int index=eventtab_index(keytab_used,keytab_used,event2index(k));
   if ( ! index ) {
     message(nls('%s has no definition',keyname));
     return;
   }
   keyname=stranslate(keyname,"._.","'-'");
   keyname=translate(keyname,'_','-');
   keyname=stranslate(keyname,"'-'","._.");
   param := 'def 'keyname' = ':+translate(name_name(index),'_','-');
   _macro_call('insert_line',param);
   insert_line(param);

}
_command what_is_cmd_index()
{
   _macro_delete_line();
//   say("p_window_id = "p_window_id);
   typeless keytab_used='';
   typeless keyname='';
   typeless k='';
   typeless status=prompt_for_key(nls('What is key:')' ',keytab_used,k,keyname,'','','',1);
   if ( status ) { return(1); }
//   say("event2index = "event2index(k));
//   _maybe_execute_command_for_key(p_window_id, event2index(k));
  int cmdIndex = _get_command_index_for_key(p_window_id, event2index(k));
  _switch_to_xml_output();
  _xml_display_output("Command index for "keyname" = "event2index(k));
   return(0);
}


/**
 * Displays help for the command that is bound to the next key you press.
 * 
 * @return Returns 0 if successful.
 * 
 * @categories Keyboard_Functions
 * 
 */ 
_command what_is()
{
   if(isEclipsePlugin()) {
      return(0);
   }
   _macro_delete_line();
   typeless keytab_used='';
   typeless keyname='';
   typeless k='';
   typeless status=prompt_for_key(nls('What is key:')' ',keytab_used,k,keyname,'','','',1);
   msg := "";
   if ( status ) { return(1); }
   int index=eventtab_index(keytab_used,keytab_used,event2index(k));
   if ( index && (name_type(index)&(COMMAND_TYPE|EVENTTAB_TYPE))) {
     int type=name_type(index) & ~(INFO_TYPE|DLLCALL_TYPE);
     _str type_name=eq_value2name(type& ~INFO_TYPE,HELP_TYPES);
     if ( type & (COMMAND_TYPE) ) {
        proc_name := name_name(index);
        proc_name = stranslate(proc_name, '_', '-');
        if (h_match_exact(proc_name)!='') {
           help(proc_name);
        }
     }
     msg=nls('%s runs the %s',keyname,type_name " "name_name(index));
     if (p_window_id==_cmdline) {
        _message_box(msg);
     }else{
        message(msg);
     }
     _macro_call('what_is', keyname);
     append_retrieve_command(name_name(index));
   } else {
      msg=nls('%s is not defined',keyname);
      if (p_window_id==_cmdline) {
         _message_box(msg);
      }else{
         message(msg);
      }
   }
   return(0);
}

/**
 * Displays the name of the command bound to the each key you 
 * press until you hit escape to cancel.  This is useful for 
 * finding an available key to reassign. 
 * 
 * @return Returns 0 if successful.
 * 
 * @categories Keyboard_Functions
 */ 
_command what_are()
{
   _macro_delete_line();

   mode  := (p_HasBuffer)?p_mode_eventtab: _edit_window().p_mode_eventtab;
   root  := _default_keys;
   keytab_used := 0;
   keyname := "";
   k := null;
   status := prompt_for_key(nls('What is key:')' ',keytab_used,k,keyname,'','','',1);
   for (;;) {
      if ( status ) break;
      if ( k==null ) break;
      if ( iscancel(k) ) break;
      index := eventtab_index(keytab_used,keytab_used,event2index(k));
      if ( index && (name_type(index)&(COMMAND_TYPE|EVENTTAB_TYPE))) {
        type := name_type(index) & ~(INFO_TYPE|DLLCALL_TYPE);
        type_name := eq_value2name(type& ~INFO_TYPE,HELP_TYPES);
        msg := nls('%s runs the %s.  Hit another key.',keyname,type_name " "name_name(index));
        if (p_window_id==_cmdline) {
           _message_box(msg);
        }else{
           message(msg);
        }
        _macro_call('what_is', keyname);
      } else {
         msg := nls('%s is not defined.  Try another key.',keyname);
         if (p_window_id==_cmdline) {
            _message_box(msg);
         }else{
            message(msg);
         }
      }
      k=pgetkey('',root,mode,'',false /*prompt==''*/);
      status = prompt_for_key(nls('What is key:')' ',keytab_used,k,keyname,'','','',1,true);
      //k = get_event('k');
      //keyname = _key_for_display(k);
      //keytab_used = eventtab_index(root,mode,event2index(k),'u');
   }
   clear_message();
}

/**
 * @return Returns the Slick-C&reg; event name corresponding to event index 
 * <i>index</i> in a form that can be used for defined event 
 * handlers.
 * 
 * @see event2name
 * @see index2event
 * @see event2index
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_str _source_event_name(int index)
{
   _str key_name=event2name(index2event(index));
   if ( pos("'",key_name) ) {
      return('"'key_name'"');
   }
   return("'"key_name"'");
/*
  key_name= translate(event2name(index2event(index)),'_','-')
  if length(key_name)>1 then return(key_name) endif
  if index=_asc("'") then
    return('"''"')
  endif
  return("'"_chr(index)"'")
*/
}
/** 
 * @return Returns the key name for <i>key</i>.  If the length of the key 
 * name is one,  the key name is enclosed in single quotes.  If the key name is 
 * the single quote character, it is enclosed in double quotes.  If the key name 
 * contains a space, the space is translated to the word 'SPACE'.
 * 
 * @categories Keyboard_Functions
 * 
 */
_str _key_for_display(_str key)
{
   // for Mac, we always want the long key names -
   // the short ones don't make any sense.
   option := def_keydisp;
   if (_isMac()) {
      option = 'L';
   }

   return(event2name(key, option));
}
/**
 * Prompts the user on the command line for a key sequence.  Returns 
 * non-zero number if the user presses a cancel key.  <i>keytab_used</i> 
 * is set to the index of the last key table referenced.  <i>k </i>is set to 
 * the last key of the sequence.  <i>keyname</i> is set to the displayable 
 * sequence of keys pressed.  The 'R' and 'M' options force the root or 
 * mode key table to be used.
 * 
 * @return Returns 0 if successful.  Otherwise COMMAND_CANCELLED_RC 
 * is returned.
 * 
 * @categories Keyboard_Functions
 * 
 */ 
_str prompt_for_key(_str prompt,
                    var keytab_used, var k,var keyname,
                    _str optionch='',_str noPrompt="",
                    _str maxcount="", _str mustbe_mouse_event="",bool have_k=false)
{

   int orig_auto_map_pad_keys=_default_option(VSOPTION_AUTO_MAP_PAD_KEYS);
   _default_option(VSOPTION_AUTO_MAP_PAD_KEYS,0);
   int mode=(p_HasBuffer)?p_mode_eventtab: _edit_window().p_mode_eventtab;
   count := 1;     /* Count key presses. */
   int state=command_state();
   if (!state && _default_option(VSOPTION_HAVECMDLINE)) {
      command_toggle();
   }
   status := 0;
   typeless root=_default_keys;
   if ( optionch=='R' ) {
      mode=root;
   } else if ( optionch=='M' ) {
      root=mode;
   }
   if ( prompt!='' ) { 
      if (_default_option(VSOPTION_HAVECMDLINE)) {
         _cmdline.set_command('',1,1,prompt); 
      } else {
         message(prompt);
      }
   }
   if (!have_k) {
      if ( noPrompt=='' ) {
         if ( count==maxcount ) {
            k=get_event();
         } else {
            k=pgetkey('',root,mode,'',prompt=='');
         }
      }
   }
   if ( mustbe_mouse_event!='' ) {
      k=_select_mouse_event(k);
   }
   if ( prompt!='' && iscancel(k) && maxcount=='' ) {
      status=COMMAND_CANCELLED_RC;
      cancel();
   }
   if ( ! status ) {
      keyname='';
      for (;;) {
         last_index(root,'K');
         int index=eventtab_index(root,mode,event2index(k));
         if ( name_name(index)=='case-indirect' && prompt==''  && arg(7)=='' ) {
            if ( k>='a' && k<='z' ) {
               k=upcase(k);
            } else {
               k=lowcase(k);
            }
            index=eventtab_index(root,mode,event2index(k));
         }
         keyname :+= _key_for_display(k)' ';
         if ( name_type(index)== EVENTTAB_TYPE && count!=maxcount ) {
            root=index;mode=index;
            if ( prompt!='' ) {
               if (_default_option(VSOPTION_HAVECMDLINE)) {
                  command_put(keyname);
               } else {
                  message(prompt' 'keyname);
               }
            } else {
               delay((int)get_event('D'),'K');
               if( !_IsKeyPending(true,true) ) {
                  message(keyname);
               }
            }
            k=pgetkey('N',root,mode,strip(keyname,'T'),prompt=='');
            count++;
            if ( prompt!='' && iscancel(k) && maxcount==''  ) {
               status=COMMAND_CANCELLED_RC;
               cancel();
               break;
            }
         } else {
            keytab_used=eventtab_index(root,mode,event2index(k),'u');
            clear_message();
            break;
         }
      }
   }
   if ( prompt!='' ) { 
      if (_default_option(VSOPTION_HAVECMDLINE)) {
         _cmdline.set_command('',1,1,''); 
      } else {
         clear_message();
      }
   }
   if (state!=command_state() && _default_option(VSOPTION_HAVECMDLINE)) {
      command_toggle();
   }
   _default_option(VSOPTION_AUTO_MAP_PAD_KEYS,orig_auto_map_pad_keys);
   return(status);
}
static void parse_keytab_options(_str &cmdline,_str &keytab_option,var max_keysequence_count,bool require_minus=true)
{
   re := "";
   max_keysequence_count='';

   if ( require_minus ) {  /* '-' required. */
      re='-';
   } else {
      re='(-|)';
   }
   // parse maximum number of keystrokes   -2 -r  or 2 -r
   after := "";
   parse cmdline with cmdline ('(^| )'re':i( |$)'),'r' +0 after ;
   if ( after!='' ) {
      if ( max_keysequence_count ) {  /* 0 command not being bound. */
         parse after with max_keysequence_count after ;
         if ( substr(max_keysequence_count,1,1)=='-' ) {
            max_keysequence_count=substr(max_keysequence_count,2);
         }
      }
      cmdline :+= " "after;
   }
   cmdline=strip(cmdline);
   keytab_option='';
   options := "";
   // In case user try to bind + or - commands to a key
   if (length(cmdline)>1) {
      cmdline=strip_options(cmdline,options);
   }
   if ( options=='-r' ) {
      keytab_option='R';
   }
   if ( options=='-m' ) {
      keytab_option='M';
   }
   cmdline=strip(cmdline);
}

/**
 *  <p>
 * Binds <i>command</i> specified to key(s) you type.
 * 
 * <p>
 * Prefix and cancel keys may only be bound by specifying the <i>max_keystrokes</i> parameter.  
 * <i>max_keystrokes</i> is a positive number representing the maximum number of keystrokes that will be pressed.  
 * The <i>max_keystrokes</i> parameter allows prefix keys to be rebound.
 * 
 *  
 * <p>
 * Use the create_prefix_key command to create a new prefix key for a multiple key sequence key binding.  
 * The -r and -m options may be used to select key bindings to the root or mode key table.  If you don't 
 * quite understand what root and mode key tables are, you should not specify the -r or -m option.
 * 
 * <pre>
 * Here are the reasons for selecting each option:
 *    -r You want this key binding to be active in all modes.
 *    -m You want this key binding to be active only in the current mode.
 * </pre>
 * 
 * <p>
 * If the current mode is fundamental, the -r and -m options have no effect.  Keys bound while in 
 * fundamental mode will be active in all modes unless there is a mode key binding.
 * 
 *    
 * <p>
 * In VI emulation, the -r option effects all modes and the -m option effects the current mode 
 * only which can be insert or command mode.
 * 
 * @appliesTo Edit_Window
 * 
 * @return Returns 0 if successful.  Possible return values are 1 (command not found) and COMMAND_CANCELLED_RC.  On error, message is displayed.
 * 
 * @example 
 * 
 * cmdline is a string in the format: [-<i>max_keystrokes</i>] [-r | -m] <i>command</i>
 * 
 * @see unbind_key
 * @see list_keydefs
 * @see create_prefix_key
 * @categories Keyboard_Functions
 */
_command bind_to_key(_str commandName='') name_info(COMMAND_ARG',')
{
   _macro_delete_line();
   int was_recording=_macro();
   _macro('m',0)   /* Turn off recording so prompt function does no recording */;
   _str cmdline=prompt(commandName);
   _macro('m',was_recording);
   keytab_option := "";
   typeless max_keysequence_count='';
   name := "";
   keyindex_list := "";
   parse_keytab_options(cmdline,keytab_option,max_keysequence_count);
   parse cmdline with name keyindex_list ;
   command_index := find_index(name,COMMAND_TYPE);
   if ( ! command_index ) {
     message(nls("Can't find command '%s'",name));
     return(1);
   }
   if (_isEditorCtl() && keytab_option=='M') {
      _maybeMakeModeEventTab();
   }
   line := "";
   line2 := "";
   typeless keyindex=0;
   typeless keytab_used='';
   typeless k='';
   typeless keyname='';
   if ( keyindex_list!='' ) {
     for (;;) {
       if ( keyindex_list=='' ) { break; }
       parse keyindex_list with keyindex keyindex_list ;
       if ( keytab_option=='R' ) {
          keytab_used=_default_keys;
       } else if ( keytab_option=='M' ) {
          keytab_used=_default_keys;
          if (_isEditorCtl()) {
             _maybeMakeModeEventTab();
             keytab_used=p_mode_eventtab;
          }
          //mode=(p_HasBuffer)?p_mode_eventtab: _edit_window().p_mode_eventtab;
       } else {
          keytab_used=_default_keys;
       }
       set_eventtab_index(keytab_used,keyindex,command_index);
       if (_issysmenu_key(index2event(keyindex))) {
          _update_sysmenu_bindings();
       }
       call_list('_eventtab_modify_',keytab_used,index2event(keyindex));
       _config_modify_flags(CFGMODIFY_KEYS);
       line='set_eventtab_index('string_keytab_used(keytab_used)',';
       line2='event2index(name2event('_quote(event2name(index2event(keyindex)))')),find_index('_quote(name_name(command_index))',COMMAND_TYPE));';
       _macro_append(line:+line2);
       _macro_append('_config_modify_flags(CFGMODIFY_KEYS);');
     }
   } else {
     typeless status=prompt_for_key(nls('To key:')' ',keytab_used,k,keyname,keytab_option,'',max_keysequence_count,1);
     if ( status ) { return(COMMAND_CANCELLED_RC); }

     /*typeless mode_etab=(p_HasBuffer)?p_mode_eventtab: _edit_window().p_mode_eventtab;
     if (keytab_used!=mode_etab || keytab_used==_default_keys) {
        keyname=strip(keyname);
        if (name_type(eventtab_index(keytab_used,keytab_used,event2index(k))) & EVENTTAB_TYPE) {
           menu_mdi_bind_all();
        } else {
           _menu_bind(_mdi.p_menu_handle,find_index(_cur_mdi_menu,oi2type(OI_MENU)),name_name(command_index),keyname,'B');
        }
       _macro_append("_menu_bind(_mdi.p_menu_handle,find_index(_cur_mdi_menu,oi2type(OI_MENU)),"_quote(name_name(command_index))","_quote(keyname)",'B');");
     } */

     set_eventtab_index(keytab_used,event2index(k),command_index);
     if (_issysmenu_key(k)) {
        _update_sysmenu_bindings();
     }
     call_list('_eventtab_modify_',keytab_used,event2index(k));
     _config_modify_flags(CFGMODIFY_KEYS);
     line='set_eventtab_index('string_keytab_used(keytab_used)',';
     line2='event2index(name2event('_quote(event2name(k))')),find_index('_quote(name_name(command_index))',COMMAND_TYPE));';
     _macro_append(line:+line2);
     _macro_append('_config_modify_flags(CFGMODIFY_KEYS);');
     update_emulation_profiles();
   }
   _UncacheTagKeyInfo();
   return(0);
}
static _str string_keytab_used(typeless keytab_used)
{
   return('find_index('_quote(name_name(keytab_used))',EVENTTAB_TYPE)');
}
/**
 * <p>Unbinds the next key you press.</p>
 * 
 * <p>Prefix and cancel keys may only be unbound by specifying the 
 * <i>max_keystrokes</i> parameter.  <i>max_keystrokes</i> is a 
 * positive number representing the maximum number of keystrokes that 
 * will be pressed.  Alt, Ctrl, and Shift prefix key combinations count as 
 * one key stroke.</p>
 * 
 * <p>Normally a mode event table binding takes precedence over a root 
 * event table binding.  When the mode event table has no binding for the 
 * key, the root event table binding is selected to be unbound.  The -r and 
 * -m options may be used to select key bindings to the root or mode 
 * event table.</p>
 * 
 * @return Returns 0 if successful. Otherwise COMMAND_CANCELLED_RC is 
 * returned.  On error, message is displayed.
 * 
 * @param cmdline is a string in the format: <i>max_keystrokes </i>[-r | -m]
 * 
 * @see bind_to_key
 * 
 * @categories Keyboard_Functions
 * 
 */ 
_command unbind_key(_str cmdline='')
{
   /*if (_isEditorCtl()) {
      _maybeMakeModeEventTab();
      keytab_used=p_mode_eventtab;
   }
   */
   _macro_delete_line();
   message(nls('Be careful what key you press!  Press ESC key to cancel this command.'));
   keytab_option := "";
   typeless keytab_used='';
   typeless keyname='';
   typeless k='';
   typeless max_keysequence_count='';
   parse_keytab_options(cmdline,keytab_option,max_keysequence_count,false);
   typeless status=prompt_for_key(nls('Unbind key:')' ',keytab_used,k,keyname,keytab_option,'',max_keysequence_count,1);
   if ( status ) { return(COMMAND_CANCELLED_RC); }
   typeless mode_etab=(p_HasBuffer)?p_mode_eventtab: _edit_window().p_mode_eventtab;
   int command_index=eventtab_index(keytab_used,keytab_used,event2index(k));
   set_eventtab_index(keytab_used,event2index(k),0);
   if (keytab_used!=mode_etab || keytab_used==_default_keys) {
      keyname=strip(keyname);
      //_menu_bind(_mdi.p_menu_handle,find_index(_cur_mdi_menu,oi2type(OI_MENU)),
      //           name_name(command_index),keyname,'U');
      //_menu_unbind(_mdi.p_menu_handle,find_index(_cur_mdi_menu,oi2type(OI_MENU)),command_index,keyname);
   }
   if (_issysmenu_key(k)) {
      _update_sysmenu_bindings();
   }
   call_list('_eventtab_modify_',keytab_used,event2index(k));
   _config_modify_flags(CFGMODIFY_KEYS);
   clear_message();
   line  := 'set_eventtab_index('string_keytab_used(keytab_used)',';
   line2 := 'event2index(name2event('_quote(event2name(k))')),0);';
   _macro_append(line:+line2);
   _macro_append('_config_modify_flags(CFGMODIFY_KEYS);');
   update_emulation_profiles();
   _UncacheTagKeyInfo();
   return(0);

}


/** 
 * Creates a new prefix key.  Using this command creates a multiple key 
 * sequence key binding of any length.  For example, to create a two key 
 * sequence key binding that starts with Ctrl+K, execute this command and 
 * press the Ctrl+K key (this assumes the Ctrl+K key is not already a prefix key).  
 * After creating the prefix key, the bind_to_key command will recognize 
 * Ctrl+K as a prefix key and prompt for another key.
 * 
 * @return  Returns 0 if successful.  Common return codes are 
 * COMMAND_CANCELLED_RC and INTERPRETER_OUT_OF_MEMORY_RC.  On error, 
 * 
 * @see bind_to_key
 * @see unbind_key
 * @see list_keydefs
 * 
 * @categories Keyboard_Functions
 */
_command int create_prefix_key()
{
   _macro_delete_line();
   typeless keytab_used='';
   typeless keyname='';
   typeless k='';
   typeless status=prompt_for_key(nls('New prefix key:')' ',keytab_used,k,keyname,'','','',1);
   if ( status ) { return(COMMAND_CANCELLED_RC); }
   int command_index=insert_name('default-keys:':+
                   substr(keyname,1,length(keyname)-1),EVENTTAB_TYPE);
   if ( ! command_index ) {
     _message_box(nls("Could not create key table")". "get_message(rc));
     return(rc);
   }
   set_eventtab_index(keytab_used,event2index(k),command_index);
   _config_modify_flags(CFGMODIFY_KEYS);
   line  := 'set_eventtab_index('string_keytab_used(keytab_used)',';
   line2 := 'event2index(name2event('_quote(event2name(k))')),'_quote(name_name(command_index))');';
   _macro_append(line:+line2);
   _macro_append('_config_modify_flags(CFGMODIFY_KEYS);');
   return 0;
}
_str me_match(_str name,bool find_first)
{
   return(name_eq_match(name,find_first,gme_names));
}
_str vsEventGetShiftString(int key)
{
   int evflags=VSEVFLAG_ALL_SHIFT_FLAGS&key;
   result := "";
   if (key & VSEVFLAG_CTRL) {
      strappend(result,'c-');
   }
   if (key & VSEVFLAG_ALT) {
      strappend(result,'a-');
   }
   if (key & VSEVFLAG_SHIFT) {
      strappend(result,'s-');
   }
   if (key & VSEVFLAG_COMMAND) {
      strappend(result,'m-');
   }
   return(result);
}
_str _select_mouse_event(var k)
{
   prefix := '1';
   int evIndex=event2index(k);
   offset := 0;
   if ( vsIsMouseEvent(evIndex)) {
      prefix=vsEventGetShiftString(evIndex);
      offset=VSEV_FIRST_MOUSE|(evIndex&VSEVFLAG_ALL_SHIFT_FLAGS);
   }
   if ( prefix!=1 ) {
      gme_names=stranslate(MOUSE_EVENT_NAMES,prefix,'/');
      typeless result=list_matches('','me',nls('Select a Mouse Event'));
      if ( result=='' ) {
         k=ESC;
      } else {
         k=index2event(offset+eq_name2value(result,gme_names));
      }
      gme_names=''; // Don't want to add 200 bytes to state file.
   }
   return(k);
}

bool _issysmenu_key(_str key)
{
   if (key:==name2event('c-f4') ||
       key:==name2event('c-f5') ||
       key:==name2event('c-f6') ||
       key:==name2event('c-f7') ||
       key:==name2event('c-f8') ||
       key:==name2event('c-f9') ||
       key:==name2event('c-f10') ||
       key:==name2event('a-f4') ||
       key:==name2event('a-f5') ||
       key:==name2event('a-f7') ||
       key:==name2event('a-f8') ||
       key:==name2event('a-f9') ||
       key:==name2event('a-f10')
      ) {
      return(true);
   }
   return(false);
}

_update_sysmenu_bindings()
{
   mdichild_close := "";
   mdichild_next := "";
   mdichild_restore := "";
   mdichild_move := "";
   mdichild_size := "";
   mdichild_minimize := "";
   mdichild_maximize := "";
   mdi_close := "";
   mdi_restore := "";
   mdi_move := "";
   mdi_size := "";
   mdi_minimize := "";
   mdi_maximize := "";
   if (name_on_key(name2event('c-f4'))== 'close-window') {
      mdichild_close="&Close\tCtrl+F4";
   } else {
      mdichild_close="&Close";
   }
   if (name_on_key(name2event('c-f6'))== 'next-window') {
      mdichild_next="Nex&t\tCtrl+F6";
   } else {
      mdichild_next="Nex&t";
   }
   if (_isWindows()) {
      if (name_on_key(name2event('c-f5'))== 'restore-window') {
         mdichild_restore="&Restore\tCtrl+F5";
      } else {
         mdichild_restore="&Restore";
      }
      if (name_on_key(name2event('c-f7'))== 'move-window') {
         mdichild_move="&Move\tCtrl+F7";
      } else {
         mdichild_move="&Move";
      }
      if (name_on_key(name2event('c-f8'))== 'size-window') {
         mdichild_size="&Size\tCtrl+F8";
      } else {
         mdichild_size="&Size";
      }
      if (name_on_key(name2event('c-f10'))== 'maximize-window') {
         mdichild_maximize="Ma&ximize\tCtrl+F10";
      } else {
         mdichild_maximize="Ma&ximize";
      }
   }
   if (name_on_key(name2event('a-f4'))== 'safe-exit') {
      mdi_close="&Close\tAlt+F4";
   } else {
      mdi_close="&Close";
   }
   int i,last=_last_window_id();
   for (i=1;i<=last;++i) {
      if (_iswindow_valid(i)){
         if (i.p_object==OI_MDI_FORM) {
            i._sysmenu_bind(SC_CLOSE,mdi_close);
         } else if (i.p_mdi_child) {
            i._sysmenu_bind(SC_CLOSE,mdichild_close);
            i._sysmenu_bind(SC_NEXTWINDOW,mdichild_next);
            if(_isWindows()) {
               i._sysmenu_bind(SC_RESTORE,mdichild_restore);
               i._sysmenu_bind(SC_MOVE,mdichild_move);
               i._sysmenu_bind(SC_SIZE,mdichild_size);
               //messageNwait('mdichild_minimize='mdichild_minimize);
               i._sysmenu_bind(SC_MAXIMIZE,mdichild_maximize);
            }
         }
      }
   }
   return(0);
}
/**
 * Restores an MDI child window.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Window_Functions
 * 
 */ 
_command void restore_window() name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   p_window_state='N';
}
/**
 * Allows you to move an MDI child window with the keyboard.  Not 
 * supported by UNIX version.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Window_Functions
 * 
 */
_command void move_window() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if(isEclipsePlugin()) {
      return;
   }
   if (p_window_state!='M') {
      p_active_form._sysmenu_command(SC_MOVE);
   }
}
/**
 * Allows you to size an MDI child window with the keyboard.  Not 
 * supported by UNIX version.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Window_Functions
 * 
 */ 
_command void size_window() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if(isEclipsePlugin()) {
      return;
   }
   if (p_window_state!='M') {
      p_active_form._sysmenu_command(SC_SIZE);
   }
}
/**
 * Iconizes an MDI child edit window.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Window_Functions
 * 
 */
_command void iconize_window() name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW)
{
   p_window_state=('I');
}
/**
 * Maximizes an MDI child edit window.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Window_Functions
 * 
 */
_command void maximize_window() name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW)
{
   p_window_state=('M');
}

int _OnUpdate_iconize_mdi(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_isMac()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED;
      }
      if (_isUnix()) {
         return MF_GRAYED;
      }
   }
   return MF_ENABLED;
}
/**
 * Iconizes the MDI window.
 *
 * @categories Window_Functions
 * 
 */
_command void iconize_mdi() name_info(','VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW)
{
   _MDICurrent().p_window_state=('I');
}

/**
 * Maximizes the MDI window.  Not support in UNIX version.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Window_Functions
 * 
 */
_command void maximize_mdi() name_info(','VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW)
{
   _MDICurrent().p_window_state=('M');
}

/**
 * Set all editor windows to iconized(minimized).
 *
 * @appliesTo Edit_Window
 * @categories Window_Functions
 * 
 */
_command void iconize_all() name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW)
{
   int firstChild = _mdi.p_child;
   int child = firstChild;
   for ( ;; ) {
      if ( child.p_mdi_child &&
         !(child.p_window_flags&HIDE_WINDOW_OVERLAP)) {
         child.p_window_state= 'I';
      }
      child = child.p_prev;
      if ( child == firstChild ) break;
   }
}

/**
 * Set all editor windows to normal.
 * 
 * @appliesTo Edit_Window
 * @categories Window_Functions
 * 
 */ 
_command void restore_all() name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW)
{
   int firstChild = _mdi.p_child;
   int child = firstChild;
   for ( ;; ) {
      if ( child.p_mdi_child &&
         !(child.p_window_flags&HIDE_WINDOW_OVERLAP)) {
         child.p_window_state= 'N';
      }
      child = child.p_prev;
      if ( child == firstChild ) break;
   }
}

int _eventtab_index_with_inheritance(int keytab_i,int event_index) {
   // Try inheritance up to twenty times for a key binding
   int i;
   for( i=1; i <= 20; ++i ) {
      if( keytab_i == 0 ) break;
      index := eventtab_index(keytab_i,keytab_i,event_index);
      // If a key binding was found
      if( index>0) {
         return index;
      }
      keytab_i = eventtab_inherit(keytab_i);
   }
   return 0;
   
}
