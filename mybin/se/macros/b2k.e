////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47103 $
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
#import "bind.e"
#import "combobox.e"
#import "files.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "recmacro.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

typeless vi_mode_eventtab=0;

/**
 * Runs the <b>Bind Command to Key dialog box</b> which allows you to 
 * change your key bindings.  This command is also used to run or edit any 
 * Slick-C&reg; command.
 * 
 * @see bind_to_key
 * @see unbind_key
 * 
 * @appliesTo Edit_Window
 *
 * @categories Keyboard_Functions
 * 
 */

_command int gui_bind_to_key_deprecated() name_info(','EDITORCTL_ARG2)
{
  _macro_delete_line();
   typeless result=show('-modal _b2k_form');
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   if (result!=1) {
      execute(result);
      return(rc);
   }
   return(0);
}

 /** 
 * Syntax   _str show('-modal _b2k_form' [, <i>allow_editrun</i> [ 
 * ,<i>title</i> [, <i>initial_command </i>[, <i>completion</i>]]]] )
 * 
 *    <i>allow_editrun</i> defaults to ''
 *    <i>title</i> defaults to "Bind Command to Key"
 *    <i>initial_command</i> defaults to ''
 *    <i>completion</i> defaults to all commands
 * 
 *    Displays Bind Command to Key dialog box.  If <i>allow_editrun</i> is 0, 
 * the Edit and Run buttons of this dialog box are disabled.   <i>title</i> 
 * specifies the title of the dialog box.  If <i>initial_command</i> is not '', 
 * the command combo box text is initialized to this value.   The 
 * <i>completion</i> argument may be MACRO_ARG (defined in "slick.sh") to list 
 * user defined macros.
 * 
 * @return  If the return value is not '', it should be executed.  This 
 * occurs when the user presses the edit or run buttons of this dialog box.
 * 
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Forms, Keyboard_Functions
 * 
 */

defeventtab _b2k_form;
void _b2kcommand.'_'()
{
   keyin('-');
}
_b2kdelete.lbutton_up()
{
   _str name=_b2kcommand.p_text;
   typeless result=_message_box(nls("Delete macro '%s'?",name),'',MB_ICONQUESTION|MB_YESNOCANCEL);
   if (result==IDCANCEL || result==IDNO) {
      return(COMMAND_CANCELLED_RC);
   }
   _macro('m',_macro('s'));
   _macro_call('_delete_macro',name);
   typeless status=_delete_macro(name);
   if (!status) {
      status=_b2kcommand._cbi_search('','$');
      if (!status) {
         _b2kcommand._lbdelete_item();
      }
   }
   _b2kcommand.p_text='';
}
void _b2kcmdhelp.lbutton_up()
{
   help(stranslate(_b2kcommand.p_text,'_','-'));
}
void _b2krun.lbutton_up()
{
   p_active_form._delete_window(_b2kcommand.p_text);
}
void _b2kedit.lbutton_up()
{
   if(!isEclipsePlugin()) {
   p_active_form._delete_window('find-proc -n '_b2kcommand.p_text);
   }else{
      find_proc(_b2kcommand.p_text);
      p_active_form._delete_window();
   }
}
#define EDITORCTL_WID _b2kcommand.p_user
void _b2kcommand.on_create(_str allowedit_run_option='',
                           _str title='',
                           _str initial_command='',
                           _str completion=''
                           )
{
   _macro('m',_macro('s'));
   _str lang='';
   if (EDITORCTL_WID == null || EDITORCTL_WID=='' || !EDITORCTL_WID) {
      int wid=_form_parent();
      if (!wid || !wid._isEditorCtl()) {
         EDITORCTL_WID=VSWID_HIDDEN;
         lang='';
      } else {
         EDITORCTL_WID=wid;
         lang=EDITORCTL_WID.p_LangId;
      }
   } else {
      lang=EDITORCTL_WID.p_LangId;
   }

   if( def_keys=='vi-keys' ) {   // Are we in vi emulation?
      // We will store the language-specific event-table so we don't have to repeatedly recalculate
      _str ktab_name=LanguageSettings.getKeyTableName(lang);
      int ktab_index=find_index(ktab_name,EVENTTAB_TYPE);
      if( !ktab_index ) {
         ktab_index=_default_keys;
      }
      vi_mode_eventtab=ktab_index;   // This will hold the index to the language-specific event-table
   }

   if (allowedit_run_option == 0) {
      _b2kedit.p_visible=_b2krun.p_visible=0;
   }
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
      _b2kedit.p_visible=false;
   }
   if (title!='') {
      p_active_form.p_caption=title;
   }

   if (p_object==OI_COMBO_BOX) {
      if (completion!='') {
         typeless prefix='';
         typeless flags='';
         p_completion=completion;
         parse p_completion with prefix ':' flags ;
         int index=find_index(prefix'-match',PROC_TYPE);
         _str name=call_index('',1,index);
         for (;;) {
            if (name=='') break;
            _lbadd_item(name);
            name=call_index('',0,index);
         }
         _b2kcmdhelp.p_visible=0;
      } else {
         _insert_name_list(COMMAND_TYPE);
         _b2kdelete.p_visible=0;
      }

      p_case_sensitive=1;
      _lbsort('e');
      top();
   }

   p_text=initial_command;

   if ( EDITORCTL_WID.p_LangId == FUNDAMENTAL_LANG_ID || EDITORCTL_WID==VSWID_HIDDEN) {
      _b2kall.p_enabled=0;
   }

   if( def_keys=='vi-keys' ) {
      _b2kall.p_caption='Affect All Insert &Modes';
      _b2k_vi_command.p_visible=1;
      _b2k_vi_command.p_value=0;
   } else {
      _b2k_vi_command.p_visible=0;
   }

   _macro('m',_macro('s'));
}

static void b2k_close_or_cancel()
{
   if (_b2kcommand.p_object==OI_TEXT_BOX) {
      //boolean enabled = _b2kbind.p_enabled;
      //if (enabled) {
      //   _b2kquit.p_caption="Cancel";
      //} else {
         _b2kquit.p_caption="Close";
      //}
   }
}

_b2kcommand.on_change(int reason)
{
   _str lbtext='';
   if (p_object == OI_TEXT_BOX) {
      lbtext=p_text;
   } else {
      lbtext=_lbget_text();
   }
   if (lbtext=='' || !name_eq(lbtext,p_text)) {
      _b2kbound_to.p_caption='';
      if (p_active_form._find_control("_b2kdelete")) {
         _b2kdelete.p_enabled=_b2kcmdhelp.p_enabled=_b2kedit.p_enabled=_b2krun.p_enabled=false;
      }
      _b2kbind.p_enabled=_b2kunbind.p_enabled=false;
      _b2kall.p_enabled=true;
      b2k_close_or_cancel();
      return('');
   }

   // Check to see if this command is allowed to be bound in all modes
   int index=find_index(lbtext,COMMAND_TYPE);
   if (index) {
      _str info=name_info(index);
      _str arg_info,arg2_info;
      parse info with arg_info ',' arg2_info;
      arg2_info=(arg2_info=='')?0:arg2_info;
      int flags=(int)arg2_info;
      if (flags&VSARG2_ONLY_BIND_MODALLY) {
         _b2kall.p_enabled=0;
      }else{
         _b2kall.p_enabled=1;
      }
   }

   if (p_active_form._find_control("_b2kdelete")) {
      _b2kdelete.p_enabled=_b2kcmdhelp.p_enabled=_b2kedit.p_enabled=_b2krun.p_enabled=true;
   }

   typeless old_mode_eventtab=EDITORCTL_WID.p_mode_eventtab;
   if (_b2kall.p_value) {
      EDITORCTL_WID.p_mode_eventtab=_default_keys;
   }

   _macro('m',0);
   _b2kbound_to.p_caption=EDITORCTL_WID.where_is(lbtext,1);
   _macro('m',_macro('s'));
   EDITORCTL_WID.p_mode_eventtab=old_mode_eventtab;
   _b2kbind.p_enabled=(_b2kkeys.p_text:!='');
   b2k_close_or_cancel();
}

_b2kadd.lbutton_up()
{
   _str orig_caption=p_caption;
   p_caption='Adding...To Abort Click Here';
   typeless event=get_event();
   if (event==ESC) {
      int result=_message_box('Add <Esc> Key?','',MB_YESNOCANCEL|MB_ICONQUESTION);
      if (result!=IDYES) {
         p_caption=orig_caption;
         return('');
      }
   }
   if (event==LBUTTON_DOWN) {
      if (mou_last_x('m')>=0 && mou_last_x('m')<p_width &&
          mou_last_y('m')>=0 && mou_last_y('m')<p_height){
         p_caption=orig_caption;
         return('');
      }
   }
   if (event:!=ESC) {
      event=_select_mouse_event(event);
      if (event:==ESC) {
         p_caption=orig_caption;
         return('');
      }
   }
   //_b2kadd.p_user contains binary length follow by binary string event.  Can
   // contain more than one or none.
   _b2kadd.p_user=_b2kadd.p_user:+_chr(length(event)):+event;
   _str text=_b2kkeys.p_text;
   if (text=='') {
      text=_key_for_display(event);
   } else {
      text=text' '_key_for_display(event);
   }
   _b2kkeys.p_user=text;
   _b2kkeys.p_text=text;
   p_caption=orig_caption;
}
void _b2kall.lbutton_up()
{
   /* 4/19/94 HERE - CANNOT bind a command for vi command-mode and insert-mode at the same time */
   if( def_keys=='vi-keys' ) {
      if( _b2kall.p_value ) _b2k_vi_command.p_value=0;
   }
   /* **** */

   _b2kcommand.call_event(CHANGE_OTHER,_control _b2kcommand,ON_CHANGE,'');
   _b2kkeys.call_event(CHANGE_OTHER,_control _b2kkeys,ON_CHANGE,'');
}
void _b2k_vi_command.lbutton_up()
{
   /* 4/19/94 HERE - CANNOT bind a command for vi command-mode and insert-mode at the same time */
   if( def_keys=='vi-keys' ) {
      if( _b2k_vi_command.p_value ) {
         _b2kall.p_value=0;
      } else if( !_b2kall.p_enabled ) {
         _b2kall.p_value=1;
      }
   }
   /* **** */

   _b2kcommand.call_event(CHANGE_OTHER,_control _b2kcommand,ON_CHANGE,'');
   _b2kkeys.call_event(CHANGE_OTHER,_control _b2kkeys,ON_CHANGE,'');
}
void _b2kclear.lbutton_up()
{
   // Warning: order of assignments matters a lot
   _b2kkeys.p_text=_b2kkeys.p_user=_b2kadd.p_user='';
}
_b2kkeys.on_change()
{
   /* 4/19/94 HERE - check for vi emulation */
   int vi_keys_idx=0;
   if( def_keys=='vi-keys' ) {
      vi_keys_idx=find_index('vi-command-keys',EVENTTAB_TYPE);
      if( !vi_keys_idx ) {
         _message_box('Can''t find event-table:  "vi-command-keys"');
         return('');
      }
   }
   /* **** */

   // _b2kkeys.p_user contains old p_text value before user modified p_text
   if (p_text!=_b2kkeys.p_user) {
      _beep();
      _message_box('Use "Add key or Mouse Click" button to add events here');
      p_text=_b2kkeys.p_user;
      return('');
   }
   _str key_sequence=_b2kadd.p_user;
   if (key_sequence=='') {
      _b2kcurbind.p_caption='';
      _b2kbind.p_enabled=0;
      _b2kunbind.p_enabled=0;
      b2k_close_or_cancel();
      return('');
   }
   _b2kcommand.call_event(CHANGE_OTHER,_control _b2kcommand,ON_CHANGE,'');
   typeless root,mode;
   root=mode=_default_keys;
   /* 4/19/94 HERE - added check for '_b2k_vi_command.p_value' */
   if ( !_b2kall.p_value ) {
      if( vi_keys_idx ) {   // Are we in vi emulation?
         if( !_b2k_vi_command.p_value ) {
            root=mode=vi_mode_eventtab;   // This holds the language-specific event-table index
         } else {
            root=mode=vi_keys_idx;
         }
      } else {
         root=mode=EDITORCTL_WID.p_mode_eventtab;
      }
   }
   /* **** */
   int index=0;
   int i;
   for (i=0;;) {
      int stringlen=_asc(substr(key_sequence,1,1));
      _str event=substr(key_sequence,2,stringlen);
      key_sequence=substr(key_sequence,stringlen+2);
      index=eventtab_index(root,mode,event2index(event));
#if 0 // Why not just show the exact binding
      if ( name_name(index)=='case-indirect') {
         if ( k>='a' && k<='z' ) {
            k=upcase(k);
         } else {
            k=lowcase(k);
         }
         index=eventtab_index(root,mode,event2index(event));
      }
#endif
      if ( name_type(index)== EVENTTAB_TYPE) {
         root=index;mode=index;
         if (!length(key_sequence)) {
            _b2kcurbind.p_caption=nls('Is Bound To An Event Table');
            _b2kunbind.p_enabled=1;
            return('');
         }
      } else {
         if (length(key_sequence)>0) {
            index=0;
            return('');
         }
         break;
      }
   }
   if (name_name(index)!='') {
      _b2kcurbind.p_caption='Is Bound To: 'name_name(index);
      _b2kunbind.p_enabled=1;
   } else {
      _b2kcurbind.p_caption='';
      _b2kunbind.p_enabled=0;
   }
}
void _b2kunbind.lbutton_up()
{
   int status=0;
   if( def_keys=='vi-keys' && _b2k_vi_command.p_value ) {
      status=EDITORCTL_WID._b2k_bind1('',_b2kadd.p_user,false,'CU');
   } else {
      status=EDITORCTL_WID._b2k_bind1('',_b2kadd.p_user,_b2kall.p_value!=0,'u');
   }
   _b2kkeys.call_event(CHANGE_OTHER,_control _b2kkeys,ON_CHANGE,'');
   _UncacheTagKeyInfo();
}
void _b2kquit.lbutton_up()
{
   p_active_form._delete_window(1);
}
int _b2kbind.lbutton_up()
{
   int status=0;
   if( def_keys=='vi-keys' && _b2k_vi_command.p_value ) {
      status=EDITORCTL_WID._b2k_bind1(_b2kcommand.p_text,_b2kadd.p_user,false,'C');
   } else {
      status=EDITORCTL_WID._b2k_bind1(_b2kcommand.p_text,_b2kadd.p_user,_b2kall.p_value&&_b2kall.p_enabled);
   }
   _b2kkeys.call_event(CHANGE_OTHER,_control _b2kkeys,ON_CHANGE,'');
   _b2kclear.call_event(_b2kclear,LBUTTON_UP);
   return(status);
}
static int _b2k_bind1(_str command, _str key_sequence,
                      boolean effect_all_modes, _str options='')
{
   //IF in VI emulation AND bind/unbind key to command mode only
   int status=0;
   if (def_keys=='vi-keys' && substr(options,1,1)=='C') {
      int idx=find_index('vi-command-keys',EVENTTAB_TYPE);
      if( !idx ) {
         _message_box('Can''t find event-table:  "vi-command-keys"');
         status=1;
      } else {
         typeless old_eventtab=p_mode_eventtab;   // Save this
         p_mode_eventtab=idx;
         status=_b2k_bind2(true,command,key_sequence,false,options);
         p_mode_eventtab=old_eventtab;   // Restore old event-table
      }
   } else if( def_keys=='vi-keys' && !effect_all_modes ) {
      typeless old_eventtab=p_mode_eventtab;   // Save this
      p_mode_eventtab=vi_mode_eventtab;
      status=_b2k_bind2(true,command,key_sequence,false,options);
      p_mode_eventtab=old_eventtab;   // Restore old event-table
   } else {
      status=_b2k_bind2(true,command,key_sequence,effect_all_modes,options);
   }
   return(status);
}
/**
 * We recommend you use the <b>set_eventtab_index</b> function to bind keys instead of this function.  
 * This function is likely to be changed in the future.  This function binds command to the 
 * binary <i>key_sequence</i> specified.  If <i>effect_all_modes</i> is false, the command is bound to the mode 
 * event table (<b>p_mode_eventtab</b>).   Specify an <i>unbind_option</i> of "U" to unbind the key.  You may 
 * prefix the unbind_option string with a "C" to effect command mode for VI emulation.  The <i>command</i> 
 * parameter is ignored when unbinding a key.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @param command
 * @param key_sequence
 * @param effect_all_modes
 * 
 * @return Returns 0 if successful.  Can fail if incorrect parameters given.
 * 
 * @categories Keyboard_Functions
 */
int _b2k_bind(_str command,_str key_sequence,_str effect_all_modes,_str options='')
{
   int orig_wid=p_window_id;
   if (!_isEditorCtl()) {
      p_window_id=VSWID_HIDDEN;
   }
   //IF in VI emulation AND bind/unbind key to command mode only
   int status=0;
   if (def_keys=='vi-keys' && substr(options,1,1)=='C') {
      int idx=find_index('vi-command-keys',EVENTTAB_TYPE);
      if( !idx ) {
         _message_box('Can''t find event-table:  "vi-command-keys"');
         status=1;
      } else {
         typeless old_eventtab=p_mode_eventtab;   // Save this
         p_mode_eventtab=idx;
         status=_b2k_bind1(command,key_sequence,false,options);
         p_mode_eventtab=old_eventtab;   // Restore old event-table
      }
   } else if( def_keys=='vi-keys' && !effect_all_modes ) {
      typeless old_eventtab=p_mode_eventtab;   // Save this
      p_mode_eventtab=vi_mode_eventtab;
      status=_b2k_bind1(command,key_sequence,false,options);
      p_mode_eventtab=old_eventtab;
   } else {
      status=_b2k_bind2(true,command,key_sequence,effect_all_modes!=0,options);
   }
   return(status);
}
void _maybeMakeModeEventTab()
{
   typeless was_ext_keytab=p_mode_eventtab==find_index('ext-keys',EVENTTAB_TYPE);
   if (p_mode_eventtab==_default_keys || was_ext_keytab ){
      _str lang=p_LangId;
      _str keytab_name=lang:+'-keys';
      if (find_index(keytab_name,EVENTTAB_TYPE)) {
         int i;
         for (i=2;;++i) {
            _str name=keytab_name:+i;
            if (!find_index(name,EVENTTAB_TYPE)) {
               keytab_name=name;
               break;
            }
         }
      }
      p_mode_eventtab=vi_mode_eventtab=
         insert_name(keytab_name,EVENTTAB_TYPE);
      if (was_ext_keytab) {
         set_eventtab_index(p_mode_eventtab,event2index(' '),
                            find_index('ext-space',COMMAND_TYPE));
      }
      LanguageSettings.setKeyTableName(p_LangId, keytab_name);
   }
}
static int _b2k_bind2(boolean in_b2k_form, _str command,
                      _str key_sequence, boolean effect_all_modes,
                      _str options='')
{
   int unbind_option= pos('U',upcase(options));
   if (command=='' && !unbind_option) {
      if (!in_b2k_form) return(1);
      _message_box(nls('Select a command'));
      p_window_id=_b2kcommand;_set_focus();
      return(1);
   }
   if (key_sequence:=='') {
      if (!in_b2k_form) return(1);
      _message_box(nls('Key sequence not defined'));
      p_window_id=_b2kadd;_set_focus();
      return(1);
   }
   int cmd_index=0;
   if (!unbind_option) {
      cmd_index=find_index(command,COMMAND_TYPE);
      if (!cmd_index) {
         if (!in_b2k_form) return(1);
         _message_box(nls("Command '%s' not found",command));
         p_window_id=_b2kcommand;_set_focus();
         return(1);
      }
   }
   _str orig_key_sequence=key_sequence;
   typeless keytab_used;
   typeless root,mode;
   root=mode=_default_keys;
   if (!effect_all_modes) {
      _maybeMakeModeEventTab();
      root=mode=p_mode_eventtab;
   }
   _str event='';
   _str keyname='';
   int i;
   for (i=0;;) {
      int stringlen=_asc(substr(key_sequence,1,1));
      event=substr(key_sequence,2,stringlen);
      key_sequence=substr(key_sequence,stringlen+2);
      int index=eventtab_index(root,mode,event2index(event));
      keyname=keyname:+_key_for_display(event)' ';
#if 0 // Why not just show the exact binding
      if ( name_name(index)=='case-indirect') {
         if ( k>='a' && k<='z' ) {
            k=upcase(k);
         } else {
            k=lowcase(k);
         }
         index=eventtab_index(root,mode,event2index(event));
      }
#endif
      if (length(key_sequence)==0) {
         if (!unbind_option) {
            keytab_used=mode;
         } else {
            keytab_used=eventtab_index(root,mode,event2index(event),'u');
         }
         break;
      }
      if ( name_type(index)== EVENTTAB_TYPE) {
         root=mode=index;
      } else {
         _str new_etab_name='default-keys:':+substr(keyname,1,length(keyname)-1);
         int eventtab_i=find_index(new_etab_name,EVENTTAB_TYPE);
         if (!eventtab_i) {
            eventtab_i=insert_name(new_etab_name,EVENTTAB_TYPE);
         }
         if ( ! eventtab_i ) {
            _message_box(nls("Could not create key table")". "get_message(eventtab_i));
            return(rc);
         }
         keytab_used=eventtab_index(root,mode,event2index(event),'u');
         set_eventtab_index(keytab_used,event2index(event),eventtab_i);
         root=mode=eventtab_i;
      }
   }
   keyname=strip(keyname);
   int old_cmd_index=eventtab_index(keytab_used,keytab_used,event2index(event));
   set_eventtab_index(keytab_used,event2index(event),cmd_index);
   _config_modify_flags(CFGMODIFY_KEYS);
   if (in_b2k_form) {
      _macro('m',_macro('s'));
      _macro_append('// Warning: Binary key strings likely to change in future releases');
      _macro_append('_b2k_bind('_quote(command)','_quote(orig_key_sequence)','_quote(effect_all_modes)','_quote(options)');');
   }
   if (_issysmenu_key(substr(orig_key_sequence,2))) {
      _update_sysmenu_bindings();
   }
   call_list('_eventtab_modify_',keytab_used,event);
   _UncacheTagKeyInfo();
   return(0);
}


//
// _command2k_form
//
defeventtab _command2k_form;
void ctlcommandlabel.on_create(_str cmdname='')
{
   EDITORCTL_WID = VSWID_HIDDEN;
   if (!_no_child_windows()) {
      EDITORCTL_WID = _mdi.p_child;
   }

   _b2kcommand.p_ReadOnly=false;
   _b2kcommand.p_text=cmdname;
   _b2kcommand.p_ReadOnly=true;
}

