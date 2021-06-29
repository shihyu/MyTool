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
#include "color.sh"
#include "plugin.sh"
#import "c.e"
#import "cfg.e"
#import "get.e"
#import "ini.e"
#import "keybindings.e"
#import "last.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "menu.e"
#import "pmatch.e"
#import "put.e"
#import "saveload.e"
#import "search.e"
#import "sellist2.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "util.e"
#endregion

static typeless _lastmac_wid;
static const STANDARD_MACRO_NAME_PREFIX= 'usermac_';

   void (*_pfn_end_recording_callback)(bool failed,_str macro_filename);
   bool grecord_keystrokes;
   bool _defining_macro;
   bool _macro_defined;
const _MACRO_FILENAME=".lastmac";
   static _str
      previous_cmd_index_list
      ,previous_key_index_list
      ,in_pause
      ,_orig_item_text
      ,_orig_help_string;


   _str def_save_macro;   // Prompt to save on end_recording

   static const DEFAULT_MACRO= 'last_recorded_macro';  /* Name or last macro recorded. */

// whether to generate stop() in a recorded macro in
// case of error for certain function calls
int def_gen_stop_on_error = 1;

definit()
{
   _defining_macro=false;
   in_pause='';
   previous_cmd_index_list='';
   previous_key_index_list='';
   _lastmac_wid='';
   _orig_item_text='';

   index := find_index('last_recorded_macro',COMMAND_TYPE);
   int module_index= index_callable(index);
   module_name := name_name(module_index);
   if ( module_name!='recmacro'_macro_ext'x' ) {
      _macro_defined=true;
   } else {
      _macro_defined=false;
   }
}
/**
 * <pre>
 * _str _macro_path( [_str try_first [, _str try_second ... ]])
 * </pre>
 * @return Returns the directory used to store macro files such as
 * "vusrdefs.e" (UNIX: "vunxdefs.e").
 * <p>
 * This function uses the {@link
 * slick_path_search} function to find the <tt>try_first</tt> and
 * <tt>try_second</tt> files if they are given.  If one is found, the path
 * on the file found is returned.  After looking for the argument
 * specified, this function looks for "vusrdefs.e" (UNIX: "vunxdefs.e"),
 * "vusrobjs.e" (UNIX: "vunxobjs.e"), and "windefs.e" (UNIX: "windu.e")
 * and returns the path of the first one found.  If no files are found,
 * the _config_path is returned.
 *
 * @param try_first     first path to try
 * @param try_second    (optional) second path to try
 * @param ...           subsequent paths to try
 *
 * @see restore_path
 * @see _create_config_path
 * @see _config_path
 * 
 * @categories File_Functions, Macro_Programming_Functions
 * 
 */
_str _macro_path(...)
{
   filename := "";
   int i;
   for (i=1;i<=arg();++i) {
      filename=slick_path_search(arg(i));
      if (filename!='') break;
   }
   if (filename=='') {
      filename=slick_path_search(USEROBJS_FILE:+_macro_ext);
   }
   if (filename=='' || _use_config_path(absolute(filename))) {
      return(_ConfigPath());
   }
   return(_strip_filename(filename,'n'));
}
int _OnUpdate_record_macro_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   int enabled=MF_ENABLED;
   /*if ( !target_wid || !target_wid._isEditorCtl()) {
      enabled=MF_GRAYED;
   } */
   /*if (!p_mdi_child || p_window_state:=='I') {
      enabled=MF_GRAYED;
   } */
   int menu_handle=cmdui.menu_handle;
   CTL_BUTTON button_wid=cmdui.button_wid;
   if (button_wid) {
      if ( !_defining_macro ) {
         button_wid.p_picture=find_index('bbmacro_record.svg',PICTURE_TYPE);
         button_wid.p_message="Starts macro recording";
         button_wid.p_command="record-macro-toggle";
      } else {
         //button_wid.p_picture=find_index('bbmacro_stop.svg',PICTURE_TYPE);
         button_wid.p_picture = _find_or_add_picture('bbmacro_stop.svg');
         button_wid.p_message="Stops macro recording";
         button_wid.p_command="record-macro-toggle";
      }
      return(enabled);
   }
   if (cmdui.menu_handle) {
      _str keys,text;
      parse _orig_item_text with keys ',' text;
      if ( keys!=def_keys || text=='') {
         flags := 0;
         new_text := "";
         _str junk;
         _menu_get_state(menu_handle,'record-macro-toggle',flags,'m',new_text,junk,junk,junk,_orig_help_string);
         text=new_text;
         _orig_item_text=def_keys','text;
         //message '_orig_item_text='_orig_item_text;delay(300);
      }
      key_name := "";
      parse _orig_item_text with \t key_name ;
      if ( !_defining_macro ) {
         _menu_set_state(menu_handle,
                         cmdui.menu_pos,enabled,'p',
                      text,
                      'record-macro-toggle','','',
                      _orig_help_string);
      } else {
         enabled=MF_ENABLED;
         int status=_menu_set_state(menu_handle,
                                    cmdui.menu_pos,enabled,'p',
                                    'Stop &Recording Macro'\t:+key_name,
                                    'record-macro-toggle','','',
                                    'Stops macro recording');
      }
   }
   return(enabled);
}

/**
 * Starts or ends definition of a keyboard macro.
 * <p>
 * Displays a message that a keyboard macro is being recorded or terminated.
 *
 * @see start_recording
 * @see end_recording
 * @see save_macro
 * @see gui_save_macro
 * @see record_macro_end_execute
 * @see record_macro_end_execute_key
 * @see execute_last_macro
 * @see execute_last_macro_key
 * 
 * @categories Macro_Programming_Functions
 * 
 */
_command void record_macro_toggle() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if ( !_defining_macro) {  /* not defining anthing? */
      start_recording();
   } else {
      end_recording();
   }

}
int _OnUpdate_record_macro_end_execute(CMDUI &cmdui,int target_wid,_str command)
{
   if ( _defining_macro ) {  /* defining macro? */
      return(MF_ENABLED);
   }
   return(_OnUpdate_last_macro(cmdui,target_wid,command));
}
int _OnUpdate_record_macro_end_execute_key(CMDUI &cmdui,int target_wid,_str command)
{
   if ( _defining_macro ) {  /* defining macro? */
      return(MF_ENABLED);
   }
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!p_mdi_child || p_window_state:=='I') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}
int _OnUpdate_execute_last_macro(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_record_macro_end_execute(cmdui,target_wid,command));
}
int _OnUpdate_execute_last_macro_key(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_record_macro_end_execute_key(cmdui,target_wid,command));
}
/**
 * Ends macro recording if currently recording and executes the last recorded macro.
 * <p>
 * Displays message if a macro was defined.
 *
 * @see start_recording
 * @see end_recording
 * @see record_macro_toggle
 * @see save_macro
 * @see gui_save_macro
 * @see record_macro_end_execute_key
 * @see execute_last_macro
 * @see execute_last_macro_key
 * 
 * @categories Macro_Programming_Functions
 * 
 */
_command void record_macro_end_execute() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if ( _defining_macro ) {  /* defining macro? */
      end_recording(true /* don't want to be prompted to bind and save */);
   }
   last_macro();
}
/**
 * Ends macro recording if currently recording and executes the last recorded macro
 * for this key.  This macro may be bound to an array of keys, such as Ctrl+0 through
 * Ctrl+9, in order to have unique last recorded macros for each key.
 * <p>
 * Displays message if a macro was defined.
 *
 * @see start_recording
 * @see end_recording
 * @see record_macro_toggle
 * @see save_macro
 * @see gui_save_macro
 * @see record_macro_end_execute
 * @see execute_last_macro
 * @see execute_last_macro_key
 * 
 * @categories Macro_Programming_Functions
 * 
 */
_command void record_macro_end_execute_key() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _str event_name = _get_idname_from_key_name(event2name(last_event()));
   if ( _defining_macro ) {  /* defining macro? */
      end_recording(true /* don't want to be prompted to bind and save */, event_name);
   }
   last_macro(event_name);
}
_str _get_idname_from_key_name(_str event_name) {
   i:=lastpos('-',event_name);
   if (!i) {
      i=lastpos('+',event_name);
      if (!i) {
         return event_name;
      }
   }
   if (i==length(event_name)) {
      --i;
   }
   return substr(event_name,i+1);
}

/**
 * Ends macro recording if currently recording and saves it as the last recorded macro.
 * <p>
 * Displays message if a macro was defined.
 *
 * @see start_recording
 * @see end_recording
 * @see record_macro_toggle
 * @see save_macro
 * @see gui_save_macro
 * @see execute_last_macro_key
 * @see record_macro_end_execute
 * 
 * @categories Macro_Programming_Functions
 * 
 */
_command void execute_last_macro() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if ( _defining_macro ) {  /* defining macro? */
      end_recording(true /* don't want to be prompted to bind and save */);
   } else {
      last_macro();
   }
}
/**
 * Ends macro recording if currently recording and saves it as the last recorded macro
 * for this key.  This macro may be bound to an array of keys, such as Ctrl+0 through
 * Ctrl+9, in order to have unique last recorded macros for each key.
 * <p>
 * Displays message if a macro was defined.
 *
 * @see start_recording
 * @see end_recording
 * @see record_macro_toggle
 * @see save_macro
 * @see gui_save_macro
 * @see execute_last_macro
 * @see record_macro_end_execute_key
 * 
 * @categories Macro_Programming_Functions
 * 
 */
_command void execute_last_macro_key() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   _str event_name = _get_idname_from_key_name(event2name(last_event()));
   if ( _defining_macro ) {  /* defining macro? */
      end_recording(true /* don't want to be prompted to bind and save */, event_name);
   } else {
      last_macro(event_name);
   }
}

int _OnUpdate_start_recording(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_record_macro_toggle(cmdui,target_wid,command));
}
/**
 * Starts macro recording.  Slick-C&reg; macro code will be generated until
 * {@link end_recording}, {@link record_macro_toggle},
 * {@link record_macro_end_execute}, or {@link record_macro_end_execute_key}
 * is executed.
 *
 * @see end_recording
 * @see record_macro_toggle
 * @see save_macro
 * @see gui_save_macro
 * @see record_macro_end_execute
 * @see record_macro_end_execute_key
 * @see execute_last_macro
 * @see execute_last_macro_key
 * 
 * @categories Macro_Programming_Functions
 * 
 */
_command start_recording() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if ( !_defining_macro ) {  /* not defining anthing? */
      status:=init_kbd_macro();
      if ( status ) {
         return(status);
      }
      _defining_macro=true;in_pause='';
      previous_cmd_index_list='';
      previous_key_index_list='';
      cancel_index := find_index('cancel_recording',COMMAND_TYPE);
      previous_key_index_list= cancel_key_index();
      previous_cmd_index_list= eventtab_index(_default_keys,_default_keys,
                                            cancel_key_index());
      orig_modify:=_eventtab_get_modify(_default_keys);
      set_eventtab_index( _default_keys,cancel_key_index(),cancel_index);
      _eventtab_set_modify(_default_keys,orig_modify);
      sticky_message(nls("Recording macro"));
      int view_id;get_window_id(view_id);
      activate_window(_lastmac_wid);
      _macro('B');
      activate_window(view_id);
      //_tbChangeButton('BBMREC.BMP','BBSMREC.BMP','end-recording','Stops macro recording');
      if (grecord_keystrokes) _macro('kb');
      return(0);
   }
   message(nls('Already defining macro'));
   return(1);

}
int _OnUpdate_end_recording(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_record_macro_toggle(cmdui,target_wid,command));
}
/**
 * Ends the definition of a recorded macro and names it last_recorded_macro.
 *
 * @param quiet   Save macro without prompting.
 * @param suffix  Suffix to append to macro name
 *
 * @return Returns 0 if successful and displays message.
 *         Otherwise a non-zero value is returned and a message or message box is displayed.
 *
 * @see start_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see execute_last_macro
 * @see execute_last_macro_key
 * @see list_macros
 * @see gui_save_macro
 * @see save_macro
 * @see _macro
 * @categories Macro_Programming_Functions
 */
_command end_recording(bool quiet=false, _str suffix="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if ( !_defining_macro ) {  /* not defining anthing? */
     message(nls('Macro not being recorded'));
     return(1);
   }
   orig_wid := p_window_id;
   kbd_macro_terminate();
   int view_id;get_window_id(view_id);
   activate_window(_lastmac_wid);
   bottom();
   // Ouput is only recorded for mdi child, mdi window, cmdline.
   //if (orig_wid.p_mdi_child || orig_wid==_mdi || orig_wid==_cmdline) {
   _str line;get_line(line);
   _str functionname,argument;
   parse line with functionname'(' '["'']','r' argument '["'']','r';
   argument=stranslate(argument,'_','-');
   if (functionname=='end_recording' ||
       functionname=='record_macro_end_execute' ||
       functionname=='record_macro_end_execute_key' ||
       functionname=='execute_last_macro' ||
       functionname=='execute_last_macro_key' ||
       functionname=='record_macro_toggle' ||
       functionname=='edittest_record_keys' ||
       functionname=='edittest_record_macro' ||
       (functionname=='execute' &&
        (argument=='record_macro_end_execute' ||
         argument=='record_macro_end_execute_key' ||
         argument=='execute_last_macro' ||
         argument=='execute_last_macro_key' ||
         argument=='record_macro_toggle' ||
         argument=='end_recording' ||
         argument=='edittest_record_keys' ||
         argument=='edittest_record_macro'
        )
       )) {
      _delete_line();
      if (grecord_keystrokes) _macro('kd');
   }
   if (grecord_keystrokes) _macro('ke');
   //}
   bottom();insert_line('}');

   // replace name of macro if this is a key macro
   top();
   suffix=stranslate(suffix,'_','-');
   status:=search("_command "DEFAULT_MACRO,"@>");
   if (status) {
      _message_box("Can't find start of recorded command");
      return 1;
   }
   macro_name:=DEFAULT_MACRO;
   if (suffix!='') {
      _insert_text('_'suffix);
      macro_name=macro_name:+'_'suffix;
   }
   get_line(line);
   parse line with "name_info(','" auto flags ")";
   activate_window(view_id);
   status=save_macro(macro_name' 'flags,true,'');
   if (status && status<0) {
      _message_box(get_message(status));
   }
   if (!status && def_save_macro && !quiet) {
      status=gui_save_macro();
      // Do not display list-macros after they finish recording
      // a macro.  The Save Macro form gives them a chance to
      // bind the macro to a key, so this is unneccessary.
      //if (!status) {
      //   list_macros(_macro_cmdname);
      //}
   }
   //_tbChangeButton('BBSMREC.BMP','BBMREC.BMP','start-recording','Starts macro recording');
   return(status);


}

static _str _list_macros_callback(int reason, var result, _str key)
{
   _nocheck _control _sellistcombo;
   _nocheck _control _sellist;
   _nocheck _control _sellistok;
   if (reason == SL_ONINIT) {
      _sellistcombo.set_command(_sellist._lbget_text(),1);
      return('');
   }
   if (reason == SL_ONDEFAULT) {
      return(1);
   }
   _str macro_name = _sellist._lbget_seltext();
   if (key == 3) { /* Edit. */
      result = 'find-proc -n ':+macro_name;
      return(1);
   }
   if (key == 4 || reason == SL_ONDELKEY) { /* Delete */
      result = 'delete-macro ':+macro_name;
      return(1);
   }
   if (key == 5) { /* Bind to key */
      result = 'gui-bind-to-key ':+macro_name;
      return(1);
   }
   return('');
}

/**
 * List user recorded macros and allows them to be bound to keys, edited, or run.
 *
 * @see start_recording
 * @see end_recording
 * @see last_macro
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see execute_last_macro
 * @see execute_last_macro_key
 *
 * @appliesto Edit_Window
 * 
 * @categories Macro_Programming_Functions
 */
_command list_macros(_str macro_name="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
#if 0
   int was_recording=_macro();
   int result=show('-modal _b2k_form',
                   1,         // Allow edit and run buttons
                   '',        // Optional title
                   arg(1),    //
                   MACRO_ARG  //Completion
                   );
   _macro('m',was_recording);
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   _macro_delete_line();
   if (result!=1) {
      _macro_call('execute',result);
      return(execute(result,""));
   }
   return(0);
#endif
   int was_recording=_macro();
   _str buttons = nls('&Run,&Edit,&Delete,&Bind to Key');
   _str user_macros[];
   int ff;
   for (ff = 1 ;; ff = 0) {
      int index = name_match("", ff, COMMAND_TYPE);
      if ( !index ) break;
      if (!index_callable(index)) {
         continue;
      }
      typeless flags = '';
      parse name_info(index) with ',' flags;
      if (isinteger(flags) && (flags & VSARG2_MACRO)) {
         user_macros[user_macros._length()] = name_name(index);
      }
   }

   if (user_macros._length() == 0) {
      _message_box(nls("No user macros defined"));
      return(1);
   }

   result := selectListDialog(nls("List Macros"),
                              SL_SELECTCLINE|SL_SELECTPREFIXMATCH|SL_COMBO|SL_MUSTEXIST|SL_SIZABLE,
                              user_macros,
                              buttons,
                              "",
                              "",
                              _list_macros_callback,
                              'list_macros',    // retrieve_name
                              MACROTAG_ARG      // completion
                              );
   _macro('m',was_recording);
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   _macro_delete_line();
    if (result!=1) {
      _macro_call('execute',result);
      return(execute(result,""));
   }
   return(0);
}
static void kbd_macro_terminate()
{
   for (;;) {
      if ( previous_cmd_index_list=='' ) { break; }
      typeless index,keyindex;
      parse previous_cmd_index_list with index previous_cmd_index_list ;
      parse previous_key_index_list with keyindex previous_key_index_list ;
      orig_modify:=_eventtab_get_modify(_default_keys);
      set_eventtab_index(_default_keys,keyindex,index);
      /*
         If the user updated the keyboard profiles,
         The keyboard profiles will have the wrong setting for ESC.
         One way to force this to happen is to bind a key during
         macro recording but there are many ways for this to
         happen.
      */
      command:=_plugin_get_property(VSCFGPACKAGE_EVENTTAB_PROFILES,_def_keys_2_profile_name(),"'ESC'");
      if (command=='cancel-recording') {
         // Special case handled here. Just correct the profile.
         update_emulation_profiles();
      } else {
         _eventtab_set_modify(_default_keys,orig_modify);
      }
   }
   int view_id;get_window_id(view_id);
   activate_window(_lastmac_wid);
   indent_kbd_macro();
   activate_window(view_id);
   in_pause='';
   clear_message();
   _macro('E');
   _defining_macro=false;

}

// returns number of views to absolute buffer name buf_name
static int _count_views(_str buf_name)
{
   int last=_last_window_id();
   //option=upcase(arg(2))
   i := Nofviews := 0;
   for (i=1;i<=last;++i) {
      if (_iswindow_valid(i) && i.p_HasBuffer && !i.p_IsMinimap && i.p_buf_name==buf_name) {
         ++Nofviews;
      }
   }
   return(Nofviews);
}

/**
 * (when recording) ESC
 * 
 * When <b>start_recording</b> has been executed, the definition of one key (usually the ESC key) 
 * is temporarily bound to this command.  To change the key rebound, modify the Slick-C&reg; macro 
 * procedure "cancel_key_index".  You can find it by executing the command "<b>find-proc cancel-key-index</b>".
 * 
 * 
 * @categories Macro_Programming_Functions
 */
_command void cancel_recording() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if ( !_defining_macro) {  /* not defining anthing? */
     message(nls('Nothing to cancel'));
   } else {
     result:=_message_box('Do you want to cancel macro recoding?','',MB_YESNO);
     if (result==IDNO) {
        _macro_delete_line();
        return;
     }
     kbd_macro_terminate();
     if (_count_views(_MACRO_FILENAME)<=1) {
        _find_and_delete_temp_view(_MACRO_FILENAME);
        _lastmac_wid='';
     }
     //_tbChangeButton('BBSMREC.BMP','BBMREC.BMP','start-recording','Starts macro recording');
     message(nls('Keyboard macro cancelled. last-recorded-macro not saved.'));

     if (_pfn_end_recording_callback) {
        (*_pfn_end_recording_callback)(true,'');
     }
   }

}
int _OnUpdate_last_macro(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!p_mdi_child || p_window_state:=='I') {
      return(MF_GRAYED);
   }
   if ( _macro_defined ) {
      return(MF_ENABLED);
   }
   // just because _macro_defined is false, doesn't mean that
   // we might not have a last_recorded_macro that we could call.
   macro_name := DEFAULT_MACRO;
   index := find_index(macro_name,PROC_TYPE|COMMAND_TYPE);
   if (index_callable(index)) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}
/**
 * Executes the last recorded macro if one exists.
 * Message is displayed if no macro exists.
 * 
 * @return Returns the name of the user recorded macro matching the prefix 
 * <i>name_prefix</i>.  If a match is not found, '' is returned.  If 
 * <i>find_first</i> is non-zero, matching starts from the first user recorded 
 * macro.  Otherwise matching starts after the previous match.
 * 
 * @categories Completion_Functions, Macro_Programming_Functions
 * 
 */
_command void last_macro(_str event_name="") name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _str macro_name=DEFAULT_MACRO;
   if (event_name!='') {
      event_name=stranslate(event_name,'_','-');
      macro_name=DEFAULT_MACRO'_'event_name;
   }
   // IF the macro can not be found OR isn't defined, maybe it needs to be reloaded
   index := find_index(macro_name,PROC_TYPE|COMMAND_TYPE);
   if (!index_callable(index) || file_eq(name_name(index_callable(index)),'recmacro'_macro_ext'x')) {
      filename := absolute(_macro_path():+USERMACS_FILE:+event_name:+_macro_ext);
      if (file_exists(filename)) {
         qfilename := _maybe_quote_filename(filename);
         int status=st(qfilename);
         if ( ! status ) {
            _load(qfilename,'u');
            status=_load(qfilename);_config_modify_flags(CFGMODIFY_USERMACS);
         }
      }
   }
   execute(macro_name,"");
}
/**
 * Executes the last recorded macro.
 * 
 * @categories Macro_Programming_Functions
 * 
 */
_command void last_recorded_macro() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   message(nls('No macro defined'));
}


defeventtab _savekmac_form;
ctledit.lbutton_up()
{
   _str lbtext=_b2kcommand._lbget_text();
   _str text=_b2kcommand.p_text;
   if (text=='' || !name_eq(lbtext,text)) {
      _param1=DEFAULT_MACRO;
   } else {
      _param1=lbtext;
   }
   p_active_form._delete_window(0);
}
void _b2kcommand.on_change(int reason)
{
   _str lbtext=_lbget_text();
   // enable save if they have typed something, anything.  The save code will
   // take care of validing the input, so we shouldn't do it here.
   // Otherwise, they have no way of knowing why save is disabled.
   //_svkmacok.p_enabled=!check_macroid(p_text);
   _svkmacok.p_enabled = (p_text != '');
   _savekmacbind.p_enabled = _svkmacok.p_enabled;
   if (name_eq(lbtext,p_text) && !name_eq(lbtext,translate(DEFAULT_MACRO,'-','_'))) {
      _b2kdelete.p_enabled=true;
   } else {
      _b2kdelete.p_enabled=false;
   }
   if (lbtext=='' || name_eq(lbtext,p_text)) {
      ctledit.p_enabled=true;
      return;
   }
   ctledit.p_enabled=false;
}
_b2kcommand.on_create()
{
   // Force on_change event.
   _b2kcommand.p_text='';
   if (!_haveProMacros()) {
      _b2kcommand.p_text=STANDARD_MACRO_NAME_PREFIX;
      _b2kcommand.p_auto_select=false;
      _b2kcommand.end_line();
   }

   p_completion= MACRO_ARG;
   _str prefix,flags;
   parse p_completion with prefix ':' flags;
   index := find_index(prefix'-match',PROC_TYPE);
   _str name=call_index('',1,index);
   for (;;) {
      if (name=='') break;
      _lbadd_item(name);
      name=call_index('',0,index);
   }
   ctlrequires_mdi_editorctl.p_value=1;
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
      ctledit.p_visible=false;
      //ctlrequires_mdi_editorctl.p_visible=false;
      //ctlrequires_mdi_editorctl.p_value=0;

      if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
         ctleditorctl.p_visible=false;
      }
      ctlicon.p_visible=false;
   }
   int wid=_form_parent();
   if (wid && !wid.p_mdi_child) {
      ctledit.p_visible=false;
   }
   if (wid && wid._MultiCursor()) {
      ctlmulticursor.p_value=1;
   }
}
void ctlrequires_mdi_editorctl.lbutton_up()
{
   if (p_value) {
      ctlread_only.p_enabled=true;
      ctlicon.p_enabled=true;
   } else {
      ctlread_only.p_enabled=false;
      ctlicon.p_enabled=false;
      ctlread_only.p_value=0;
      ctlicon.p_value=0;

   }
}
static _str savekmac()
{
   _param1='';
   name := _b2kcommand.p_text;
   int status=check_macroid(name);
   switch (status) {
   case 1:
      _message_box(nls("Invalid macro name.  It must be a valid Slick-C identifier."));
      break;
   case 2:
      // check and see if this one already exists
      if (!_b2kcommand._lbfind_and_select_item(name)) {
         answer := _message_box(nls("Replace existing macro?"),"SlickEdit",MB_YESNO|MB_ICONQUESTION);
         if (answer == IDYES) {
            delete_macro(name);
            status=0;
            break;
         }
      }
      _message_box(nls("This name has already been used.  Please select another name."));
      break;
   case 3:
      _message_box(nls("'"name"' is reserved by SlickEdit.  Please select another name."));
      break;
   case 4:
      _message_box('Standard edition requires macro name start with 'STANDARD_MACRO_NAME_PREFIX);
      _b2kcommand.p_text=STANDARD_MACRO_NAME_PREFIX:+_b2kcommand.p_text;
      //_b2kcommand.p_auto_select=false;
      _b2kcommand.end_line();
      _set_focus();
      return('');
   }
   if (status){
      p_window_id=_b2kcommand;
      _set_sel(1,length(name)+1);_set_focus();
      return('');
   }
   flag_names := "";
   if (ctlread_only.p_value) {
      if (flag_names!='') flag_names :+= '|';
      flag_names :+= 'VSARG2_READ_ONLY';
   }
   if (ctlicon.p_value) {
      if (flag_names!='') flag_names :+= '|';
      flag_names :+= 'VSARG2_ICON';
   }
   if (ctlmulticursor.p_value) {
      if (flag_names!='') flag_names :+= '|';
      flag_names :+= 'VSARG2_MULTI_CURSOR';
   }
   if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW) {
      if (ctleditorctl.p_value) {
         if (flag_names!='') flag_names :+= '|';
         if (ctlrequires_mdi_editorctl.p_value) {
            flag_names :+= 'VSARG2_REQUIRES_EDITORCTL';
         } else {
            flag_names :+= 'VSARG2_EDITORCTL';
         }
      } else if (ctlrequires_mdi_editorctl.p_value) {
         if (flag_names!='') flag_names :+= '|';
         flag_names :+= 'VSARG2_REQUIRES_MDI_EDITORCTL';
      }
   } else {
      if (ctlrequires_mdi_editorctl.p_value) {
         if (flag_names!='') flag_names :+= '|';
         flag_names :+= 'VSARG2_REQUIRES_EDITORCTL';
      }
   }
   _param1='';
   return name' 'flag_names;
}
void _svkmacok.lbutton_up()
{
   result := savekmac();
   if (result=='') return;
   p_active_form._delete_window(result);
}
void _savekmacbind.lbutton_up()
{
   result := savekmac();
   if (result=='') return;
   p_active_form._delete_window(result' bind');
}

static int check_macroid(_str name)
{
   // first check if name is a valid identifier, and doesn't start with underscore
   name=translate(name,'_','-');
   if (substr(name,1,1)=='_' || ! isid_valid(name) ) {
      return(1);
   }
   // does this macro already exists (from user or in SlickEdit)?
   if (find_index(name,OBJECT_TYPE|EVENTTAB_TYPE|PROC_TYPE|COMMAND_TYPE)) {
      return(2);
   }
   // is this one of the names for last-recorded macros?
   if ( name_eq(name,DEFAULT_MACRO) || name_eq(substr(name,1,length(DEFAULT_MACRO'_')),DEFAULT_MACRO'_')) {
      return(3);
   }
   if (!_haveProMacros()) {
      if (substr(name,1,length(STANDARD_MACRO_NAME_PREFIX))!=STANDARD_MACRO_NAME_PREFIX) {
         return 4;
      }
   }
   // this macro name is OK
   return(0);

}
int _OnUpdate_gui_save_macro(CMDUI &cmdui,int target_wid,_str command)
{
   if ( _lastmac_wid!='' && !_defining_macro) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}
/**
 * Saves the last macro recorded under the command name you specify.  The
 * Slick-C&reg; source for the macro is appended to the "vusrmacs.e" file.  The
 * Save Macro dialog box is displayed to prompt for a name for the macro
 * and options.
 *
 * @return Returns 0 if successful.
 *
 * @see save_macro
 * @see start_recording
 * @see end_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see execute_last_macro
 * @see execute_last_macro_key
 *
 * @categories Macro_Programming_Functions
 * 
 */
_command gui_save_macro() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if ( _defining_macro) {
      _macro_delete_line();
      _message_box(nls("Can't save macro while recording"));
      return(1);
   }
   if (_lastmac_wid=='') {
      _macro_delete_line();
      _message_box(nls("No macro defined"));
      return(1);
   }
   int result=show('-modal _savekmac_form');
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   if (_param1!='') {
      int status=find_proc("-n "_param1);
      if (status) {
         _message_box(nls("%s could not be found.", DEFAULT_MACRO));
         return(status);
      }
      return(2); // Use wanted to edit last macro, nothing saved.
   }
   parse result with auto name . auto do_bind_to_key;
   result = save_macro(result);
   // if they hit the "Save and Bind to Key" dialog
   // then direct them to key bindings dialog now
   if (!result && name!='' && do_bind_to_key!='') {
      gui_bind_to_key(name);
   }
}
/**
 * Saves the last macro recorded under the command name you specify.
 * The Slick-C&reg; source for the macro is appended to the "vusrmacs.e" file.
 * The name and flag_names strings are used to create the following
 * command definition:
 * <pre>
 *    _command name() name_info(','flag_names)
 * </pre>
 *
 * @param cmdline    a string in the format: name flag_names
 *
 * @return Returns 0 if successful.
 *
 * @see gui_save_macro
 * @see start_recording
 * @see end_recording
 * @see record_macro_toggle
 * @see record_macro_end_execute
 * @see execute_last_macro
 * @see execute_last_macro_key
 * 
 * @categories Macro_Programming_Functions
 * 
 */
_command save_macro(_str macro_info='',bool replacing_lastmac=false,_str prefix_flags='VSARG2_MACRO|VSARG2_MARK',typeless source_wid=_lastmac_wid) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if ( _defining_macro ) {
      _macro_delete_line();
      _message_box(nls("Can't save macro while recording"));
      return(1);
   }
   if (!isinteger(source_wid)) {
      _macro_delete_line();
      _message_box(nls("No macro defined"));
      return(1);
   }
   do_bind_to_key := "";
   flag_names := prefix_flags;
   _str name,add_flag_names;
   if (macro_info != '') {
      parse macro_info with name add_flag_names do_bind_to_key;
      if (flag_names!='' && add_flag_names!='') flag_names :+= '|';
      flag_names :+= add_flag_names;
   } else {
      typeless status=get_string(name,nls('Macro Name:')' ','-.save_macro');
      if ( status ) { return(status); }
   }
   status:=0;
   if (!replacing_lastmac) {
      /* Check if the name is an allowed identifier. */
      status=check_macroid(name);
      switch (status) {
      case 1:
         message(nls("Invalid macro name.  It must be a valid Slick-C identifier."));
         return(1);
      case 2:
         message(nls("This name has already been used.  Please select another name."));
         return(1);
      case 3:
         message(nls("'"name"' is reserved by SlickEdit.  Please select another name."));
         return(1);
      case 4:
         _message_box('This edition requires macro name start with 'STANDARD_MACRO_NAME_PREFIX);
         return 1;
      }
   }

   _str usermacs_filename=_macro_path(USERMACS_FILE:+_macro_ext):+USERMACS_FILE:+_macro_ext;
   // Update old cursor info for buffer.
   if (!isEclipsePlugin() && _isEditorCtl()) {
      _next_buffer('h');_prev_buffer('h');
   }
   //_message_box('got here');
   int orig_view_id=p_window_id;
   activate_window(source_wid);
   int mark=_alloc_selection();
   if ( mark<0) {
      activate_window(orig_view_id);
      return(TOO_MANY_SELECTIONS_RC);
   }
   top();
   int defc_rc=search('^_command','ri@');
   modify := p_modify;
   linenum := p_line;
   line := "";
   if ( ! defc_rc ) {
      get_line(line);
      modify=p_modify;
      linenum=p_line;
      //_macro_cmdname=translate(name,'-','_');  // Store name for caller in global
      name=translate(name,'_','-');
      replace_line("_command "name"() name_info(','"flag_names")");
      if (!file_exists(usermacs_filename)) {
         // Must copy include line
         top();
      }
   }
   _select_line(mark);
   bottom();_select_line(mark);
   //typeless orig_mark=_duplicate_selection('');
   //_show_selection(mark);
   int old_buf_id=p_buf_id;
   qfilename := _maybe_quote_filename(usermacs_filename);
   status=_delete_macro(name,false,mark,usermacs_filename);
   /*status=append(qfilename/*,'','-d'*/);
   if ( status==NEW_FILE_RC || status==FILE_NOT_FOUND_RC ) {
      p_buf_id=old_buf_id;
      top();_deselect();_select_line();bottom();_select_line();
      status=put(qfilename);
   } */
   //_show_selection(orig_mark);
   if ( ! defc_rc ) {
      p_modify=modify;
      p_line=linenum;
      replace_line(line);
   }
   _free_selection(mark);
   activate_window(orig_view_id);
   if ( ! status ) {
      status=st(qfilename);
      if ( ! status ) {
         status=load(qfilename);
#if 0
         _load(qfilename,'U');
         say('d1 qfilename='qfilename);
         status=_load(qfilename,'L');_config_modify_flags(CFGMODIFY_USERMACS);
         say('d2 status='status);
#endif
      }
      if ( ! status ) {
         message(nls('Macro command %s saved in file "%s"',name,usermacs_filename));
      }
   }
   return(status);

}
/**
 * Temporarily turns off macro recording so that some editor functions 
 * may be used before continuing macro recording.
 * 
 * @categories Macro_Programming_Functions
 * 
 */
_command void pause_recording() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if ( !_defining_macro) {  /* not defining anthing? */
      message(nls('Key strokes not being recorded'));
      return;
   }
   if ( in_pause=='1' ) {
      in_pause='';
      int view_id;get_window_id(view_id);
      activate_window(_lastmac_wid);
      _macro('B');
      activate_window(view_id);
      sticky_message(nls("Recording macro"));
   } else {
      sticky_message(nls('Macro recording paused'));
      _macro_delete_line();
      _macro('E');
      in_pause=1;
   }
}
static int init_kbd_macro()
{
   /*_make_macro_filename()
   status=_open_temp_view(_MACRO_FILENAME,_lastmac_wid,orig_view_id);
   if (status) {
      orig_view_id=_create_temp_view(_lastmac_wid);
   } else {
      _lbclear();
   } */
   is_read_only := false;
   if (_isEditorCtl(false)) {
      is_read_only=p_readonly_mode;
   }
   multiCursor := "";
   if (_MultiCursor()) {
      multiCursor='VSARG2_MULTI_CURSOR|';
   }
   int window_group_view_id;
   int temp_view_id;
   bool buffer_already_exists;
   //_find_or_open_temp_view(_MACRO_FILENAME,temp_view_id,window_group_view_id,'',buffer_already_exists,true,true,0,true);
   window_group_view_id=_find_or_create_temp_view(_lastmac_wid,'',_MACRO_FILENAME,false,VSBUFFLAG_THROW_AWAY_CHANGES,true);
   _SetEditorLanguage('e');
   insert_line('#include "slick.sh"');
   insert_line('');
   if (is_read_only) {
      insert_line("_command "DEFAULT_MACRO"() name_info(','"multiCursor"VSARG2_MACRO|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)");
   } else {
      insert_line("_command "DEFAULT_MACRO"() name_info(','"multiCursor"VSARG2_MACRO|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)");
   }
   insert_line('{');
   insert_line("_macro('R',1);");
   //say('init_kbd_macros n='p_Noflines);
   activate_window(window_group_view_id);
   return(0);
}
static void indent_kbd_macro()
{
   int syntax_indent=p_SyntaxIndent;
   if ( syntax_indent<=0) {
      syntax_indent=3;
   }
   top();up();
   search('^_command','ri@');
   down();
   for (;;) {
      down();
      if ( rc ) {
         break;
      }
      _str line;get_line(line);
      replace_line(reindent_line(line,syntax_indent));
   }
}
/**
 * @return If macro recording and output is on (_macro()!=0), the last
 * source line of recorded macro is returned.  Otherwise, '' is returned.
 *
 * @see _macro
 * @see _macro_append
 * @see _macro_delete_line
 * @see _macro_replace_line
 * @see _macro_repeat
 * @see _macro_call
 * 
 * @categories Macro_Programming_Functions
 * 
 */
_str _macro_get_line()
{
   if ( _macro() && _MultiCursorActiveLoopIteration()) {
      int view_id;get_window_id(view_id);
      activate_window(_lastmac_wid);
      line := "";
      bottom();get_line(line);
      activate_window(view_id);
      return(line);
   }
   return('');
}

#if 0
void _macro_debug(var last_line,var prev_line,var Noflines)
{
   if ( _macro('s')) {
      get_window_id view_id
      activate_window _lastmac_wid
      bottom;get_line last_line
      up;get_line prev_line;bottom;
      Noflines=p_Noflines;
      activate_window view_id
   }
}
#endif

/**
 * If macro recording and output is on (_macro()!=0),
 * the last source line of recorded macro is deleted.
 *
 * @see _macro
 * @see _macro_append
 * @see _macro_get_line
 * @see _macro_replace_line
 * @see _macro_repeat
 * @see _macro_call
 * 
 * @categories Macro_Programming_Functions
 * 
 */
void _macro_delete_line()
{
   if ( _macro() && _MultiCursorActiveLoopIteration()) {
      int view_id;get_window_id(view_id);
      activate_window(_lastmac_wid);
      bottom();
      //get_line(line);messageNwait('line='line);
      _delete_line();
      activate_window(view_id);
   }

}
/**
 * If macro recording and output is on (_macro()!=0),
 * and the last source line is of the form:
 * <pre>
 *     execute('show -modal &lt;form_name&gt;');
 * </pre>
 * the last source line of recorded macro is deleted.
 *
 * @param form_name  name of form to expect to see
 * 
 * @see _macro
 * @see _macro_append
 * @see _macro_get_line
 * @see _macro_replace_line
 * @see _macro_repeat
 * @see _macro_call
 * 
 * @categories Macro_Programming_Functions
 * 
 */
void _macro_delete_show(_str form_name)
{
   if ( _macro() && _MultiCursorActiveLoopIteration()) {
      int view_id;get_window_id(view_id);
      activate_window(_lastmac_wid);
      bottom();
      _str line;get_line(line);
      if (line == "execute('show -modal "form_name"');") {
         _delete_line();
      }
      activate_window(view_id);
   }

}
/**
 * If macro recording and output is on (_macro()!=0), the string argument
 * specified is appended to the end of the macro being recorded.
 *
 * @param string     text to append to macro definition.
 *
 * @example
 * <pre>
 *    _macro_call('find','Find this', 'ri');
 *    // The above is identical to
 *    _macro_append("find('Find this', 'ri')");
 *    // and is also identical to
 *    _macro_append( "find(" _quote('Find this') ',' _quote('ri') ")" );
 * </pre>
 * 
 * @categories Macro_Programming_Functions
 * 
 */
void _macro_append(_str string)
{
   if ( _macro() && _MultiCursorActiveLoopIteration()) {
      int view_id;get_window_id(view_id);
      activate_window(_lastmac_wid);
      bottom();insert_line(string);
      activate_window(view_id);
   }

}
/**
 * If macro recording and output is on (_macro()!=0),
 * the last source line of the recorded macro is replaced with string.
 *
 * @param string     text to replace last source line with
 *
 * @see _macro
 * @see _macro_append
 * @see _macro_delete_line
 * @see _macro_replace_line
 * @see _macro_call
 * @see _macro_get_line
 * 
 * @categories Macro_Programming_Functions
 * 
 */
void _macro_replace_line(_str string)
{
   if ( _macro() && _MultiCursorActiveLoopIteration()) {
      int view_id;get_window_id(view_id);
      activate_window(_lastmac_wid);
      bottom();replace_line(string);
      activate_window(view_id);
   }

}
/**
 * <pre>
 * void _macro_call( _str proc_name [,_str arg1 [,_str arg2 .. ]] )
 * </pre>
 * <p>
 * If macro recording and output is on (_macro()!=0), the call to function
 * proc_name with arguments arg1, arg2..  is appended to the end of the
 * macro being recorded.
 *
 * @param proc_name     Slick-C&reg; procedure to call
 * @param arg1          (optional) first argument
 * @param arg2          (optional) second argument
 * @param ...           subsequent arguments
 *
 * @example
 * <pre>
 *    _macro_call('find','Find this', 'ri');
 *    // The above is identical to
 *    _macro_append("find('Find this', 'ri')");
 *    // and is also identical to
 *    _macro_append( "find(" _quote('Find this') ',' _quote('ri') ")" );
 * </pre>
 *
 * @see _macro
 * @see _macro_append
 * @see _macro_delete_line
 * @see _macro_get_line
 * @see _macro_replace_line
 * @see _macro_repeat
 * 
 * @categories Macro_Programming_Functions
 * 
 */
void _macro_call(_str proc_name, ...)
{
   if ( ! _macro() || !_MultiCursorActiveLoopIteration()) {
      return;
   }
   string := proc_name'(';
   int i;
   for (i=2; i<=arg() ; ++i) {
      _str append;
      if (arg(i)==null) {
         append='null';
      } else {
         append=_quote(arg(i));
      }
      if ( i:==2 ) {
         string :+= append;
      } else {
         new_string := string','append;
         // Since we call _macro_delete_line(), we can't change a call into multiple lines!
         /*if ( length(new_string)>79 ) {
            _macro_append(string',');
            string=substr('',1,length(proc_name)+1):+append;
         } else {
            string=new_string;
         }*/
         string=new_string;
      }
   }
   _macro_append(string');');

}

void _macro_call2(_str proc_name, ...)
{
   if ( ! _macro() || !_MultiCursorActiveLoopIteration()) {
      return;
   }
   string := proc_name'(';
   int i;
   for (i=2; i<=arg() ; ++i) {
      _str append;
      if (arg(i)==null) {
         append='null';
      } else {
         append=arg(i);
      }
      if ( i:==2 ) {
         string :+= append;
      } else {
         new_string := string','append;
         if ( length(new_string)>79 ) {
            _macro_append(string',');
            string=substr('',1,length(proc_name)+1):+append;
         } else {
            string=new_string;
         }
      }
   }
   _macro_append(string');');

}

/**
 * Changes a macro call to do an error check and possibly call
 * stop();
 */
void _macro_call_maybe_stop(_str proc_name, ...)
{
   if ( ! _macro() || !_MultiCursorActiveLoopIteration()) {
      return;
   }
   string := proc_name'(';
   int i;
   for (i=2; i<=arg() ; ++i) {
      _str append;
      if (arg(i)==null) {
         append='null';
      } else {
         append=_quote(arg(i));
      }
      if ( i:==2 ) {
         string :+= append;
      } else {
         new_string := string','append;
         if ( length(new_string)>79 ) {
            _macro_append(string',');
            string=substr('',1,length(proc_name)+1):+append;
         } else {
            string=new_string;
         }
      }
   }

   string :+= ')';

   if (def_gen_stop_on_error) {
      string = 'if ('string') stop();';
   }
   _macro_append(string);
}

static _str gEscapeTab[]={
      "\\b","\\f","\\n","\\r","\\t","\\000","\\\"","\\\\"
     };

/**
 * Quotes input string quoted in C double-quoted string syntax.
 * This function is intended to be used in macros which generate Slick-C&reg; source code.
 *
 * @param string  input string to quote
 *
 * @return double quoted string
 *
 * @see _maybe_quote_filename
 * @see _quote
 * 
 * @categories Macro_Programming_Functions
 * 
 */
_str _dquote(_str string)
{
   // Check if string has does not have and special characters
   special_chars := "\b\f\n\r\t\0";
   i := 1;
   special_chars :+= '"\';
   for (;;) {
       int j=verify(string,special_chars,'M',i);
       if ( ! j ) break;
       if (substr(string,j,1)=='"') {
          string=substr(string,1,j-1):+'\':+substr(string,j);
       } else {
          i=pos(substr(string,j,1),special_chars);
          string=substr(string,1,j-1):+gEscapeTab[i-1]:+substr(string,j+1);
#if 0
          parse dec2hex(_asc(substr(string,j,1))) with 'x' hex;
          if (length(hex)<=1) {
             hex='0'hex;
          }
          string=substr(string,1,j-1):+'\x'hex:+substr(string,j+1);
#endif
       }
       i=j+2;
   }
   return('"'string'"');
}

/**
 * Quotes input string quoted in Slick-C&reg; syntax.
 * This function is intended to be used in macros which generate Slick-C&reg; source code.
 *
 * @param string  input string to quote
 *
 * @return quoted string
 *
 * @see _maybe_quote_filename
 * @see _dquote
 * 
 * @categories Macro_Programming_Functions
 */
_str _quote(_str string)
{
   // Check if string has does not have any special characters
   special_chars := "\b\f\n\r\t\0";
   special_chars_re := '['special_chars'\x80-\xff]';
   if(pos(special_chars_re,string,1,'yr')) { // Binary regex search
      //chars2='bfnrt0';
      // Escape special chars with backslash
      i := 1;
      special_chars :+= '"\\';
      special_chars_re='['special_chars:+'\x80-\xff]';
      for (;;) {
          j := pos(special_chars_re,string,i,'yr'); // Binary regex search
          if ( ! j ) break;
          if (substr(string,j,1)=='"') {
             string=substr(string,1,j-1):+'\':+substr(string,j);
          } else {
             i=pos(substr(string,j,1),special_chars);
             if (i) {
                string=substr(string,1,j-1):+gEscapeTab[i-1]:+substr(string,j+1);
             } else {
                hex := _dec2hex(_asc(substr(string,j,1)),16,2);
                string=substr(string,1,j-1):+'\x'hex:+substr(string,j+1);
             }
          }
          i=j+2;
      }
      return('"'string'"');
   }
   // If not a single character and the string does not contain any 
   // quotes or backslashes, quote it using double-quotes
   if (length(string) > 1 && pos("[\'\"\\\\]",string,1,'r') <= 0) {
      return('"'string'"');
   }
   // Replace each single quote in string with 2 single quotes.
   i := 1;
   for (;;) {
       j := pos("'",string,i);
       if ( ! j ) { break; }
       string=substr(string,1,j-1):+"'":+substr(string,j);
       i=j+2;
   }
   return("'"string"'");
}

static int _set_macro_enable_flags(_str macro_name,_str reqflag_names)
{
   if (macro_name=='') {
      return(0);
   }
   macro_name=translate(macro_name,"_","-");
   index := find_index(macro_name,COMMAND_TYPE);
   if (!index) {
      _message_box(nls("Macro %s does not exist or is not loaded.",macro_name));
      return(COMMAND_CANCELLED_RC);
   }
   int module_name_index=index_callable(index);
   if (!module_name_index) {
      // This error is a very strange error
      return(0);
   }
   module_name := name_name(module_name_index);
   module_name=_strip_filename(module_name, 'e'):+_macro_ext;
   int start_view_id,temp_view_id,orig_view_id;
   get_window_id(start_view_id);
   _str filename=_macro_path_search(module_name);
   if (filename=='') {
      filename=slick_path_search(module_name);
   }
   int status=_open_temp_view(filename,temp_view_id,orig_view_id);
   if (status) {
      activate_window(start_view_id);
      if (status==FILE_NOT_FOUND_RC) {
         _message_box(nls("File '%s' not found.\n\nMake sure your VSLICKMACROS path in user.cfg.xml is correct.\n\nIn addition, you may need to install macro source code.",filename));
      } else {
         _message_box(nls("Unable to open file %s\n\n"get_message(status), filename));
      }
      return(status);
   }
   _SetEditorLanguage('e');
   top();
   status=_VirtualProcSearch(macro_name);
   if (status) {
      _message_box(nls("Macro %s could not be found.", macro_name));
      _delete_temp_view(temp_view_id);
      activate_window(start_view_id);
      return(status);
   }
   // Skip over command parameters
   status=search('(','@xcs');
   if (status) {
      _message_box(nls("Unable to parse macro source"));
      _delete_temp_view(temp_view_id);
      activate_window(start_view_id);
      return(status);
   }
   status=find_matching_paren(true);
   if (status) {
      _message_box(nls("Unable to parse macro source"));
      _delete_temp_view(temp_view_id);
      activate_window(start_view_id);
      return(status);
   }
   right();
   save_pos(auto p);
   _clex_skip_blanks();

   // No name info?
   int junk;
   if (cur_word(junk)!='name_info') {
      restore_pos(p);
      _insert_text(" name_info(','"reqflag_names")");
   } else {
      right();_clex_skip_blanks();
      // Search for a comma or close paren
      // We can assume that if a comma is found, it must
      // be in a string
      status=search('[,)]','@rxc');
      if (status) {
         _message_box(nls("Unable to parse name_info source"));
         _delete_temp_view(temp_view_id);
         activate_window(start_view_id);
         return(status);
      }
      if (get_text()==')') {
         if (_clex_find(0,'g')==CFG_STRING) {
            _message_box(nls("Unable to parse name_info source"));
            _delete_temp_view(temp_view_id);
            activate_window(start_view_id);
            return(status);
         }
         _insert_text(" ','"reqflag_names);
      } else if (get_text()==',') {
         if (_clex_find(0,'g')!=CFG_STRING) {
            _message_box(nls("Unable to parse name_info source"));
            _delete_temp_view(temp_view_id);
            activate_window(start_view_id);
            return(status);
         }
         status=_clex_find(STRING_CLEXFLAG,"N");
         if (status) {
            _message_box(nls("Unable to parse name_info source"));
            _delete_temp_view(temp_view_id);
            activate_window(start_view_id);
            return(status);
         }
         typeless start_offset=point('s');
         status=search(')','@xcs');
         if (status) {
            _message_box(nls("Unable to parse name_info source"));
            _delete_temp_view(temp_view_id);
            activate_window(start_view_id);
            return(status);
         }
         typeless end_offset=point('s');
         goto_point(start_offset);
         int Nofbytes=end_offset-start_offset;
         flag_names := get_text(Nofbytes);
         _delete_text(Nofbytes);
         preserve_names := "";
         for (;;) {
            _str name;
            parse flag_names with name '|' flag_names;
            if (name=="") {
               break;
            }
            switch (name) {
            case "VSARG2_EDITORCTL":
            case "EDITORCTL_ARG2":
            case "VSARG2_REQUIRES_FILEMAN_MODE":
            case "VSARG2_READ_ONLY":
            case "READ_ONLY_ARG2":
            case "VSARG2_ICON":
            case "ICON_ARG2":
            case "VSARG2_REQUIRES_AB_SELECTION":
            case "VSARG2_REQUIRES_BLOCK_SELECTION":
            case "VSARG2_REQUIRES_CLIPBOARD":
            case "VSARG2_REQUIRES_SELECTION":
            case "VSARG2_REQUIRES_FILEMAN_MODE":
            case "VSARG2_REQUIRES_UNICODE_BUFFER":
            case "VSARG2_REQUIRES_MDI_EDITORCTL":
            case "VSARG2_REQUIRES_TAGGING":
            //case "VSARG2_REQUIRES_MDI":
               break;
            default:
               if (preserve_names!="") {
                  preserve_names :+= "|";
               }
               preserve_names :+= name;
            }
         }
         if (preserve_names!="") {
            if (reqflag_names!="") {
               reqflag_names :+= "|";
            }
            reqflag_names :+= preserve_names;
         }
         _insert_text(reqflag_names);
      }
   }
   if (!status) {
      status=save("",SV_RETURNSTATUS);
      if (status) {
         _message_box(nls('Make sure you have write access to the file %s',filename));
      }
   }
   activate_window(temp_view_id);
   _delete_temp_view(temp_view_id);
   if (!status) {
      status=load(filename);
      _tbSetRefreshBy(VSTBREFRESHBY_SWITCHBUF);  // Just force a refresh
   }
   activate_window(start_view_id);
   return(status);
}
/**
 * Deletes macro source code for macro command with name given.  This
 * function is typically used to deleted a recorded macro.  However, it
 * may be used to delete the source code for any macro command.  Currently
 * comments that appear before the command are not deleted and trailing
 * blanks after the function are not deleted.  This is likely to be
 * changed in the future.
 *
 * @return Returns 0 if successful.
 * @categories Macro_Programming_Functions
 */
int _delete_macro(_str macro_name,bool do_reload=true,int replace_code_with_markid=-1,_str replace_code_filename='')
{
   if (macro_name=='') {
      return(0);
   }
   macro_name=translate(macro_name,"_","-");
   index:=0;
   if (replace_code_filename=='') {
      index = find_index(macro_name,COMMAND_TYPE);
      if (!index) {
         return(COMMAND_CANCELLED_RC);
      }
   }
   file_already_loaded := false;
   status:=0;
   filename:='';
   int temp_view_id,orig_view_id;
   get_window_id(orig_view_id);
   if (replace_code_filename!='') {
      filename=replace_code_filename;
      status=_open_temp_view(replace_code_filename,temp_view_id,orig_view_id,'',file_already_loaded,false,false,0,true);
      if (status) {
         activate_window(orig_view_id);
         _message_box(nls("Could not open file '%s'", replace_code_filename));
         return(status);
      }
   } else {
      int module_name_index=index_callable(index);
      if (!module_name_index) {
         delete_name(index);
         name := name_name(index);
         if (name!='') {
            _message_box(nls('Macro %s will still be listed because another macro calls this macro.  However, its code has been deleted.  Fix your other macros which call %s.',name,name));
         }
         // Nothing to delete
         return(0);
      }
      module_name := name_name(module_name_index);
      module_name=_strip_filename(module_name, 'e'):+_macro_ext;
      filename=slick_path_search(module_name);
      status=_open_temp_view(filename,temp_view_id,orig_view_id,'',file_already_loaded);
      if (status) {
         activate_window(orig_view_id);
         _message_box(nls("%s could not be found.", macro_name));
         return(status);
      }
   }
   if (!file_already_loaded) {
      _SetEditorLanguage('e');
   }
   top();
   do_save:=false;
   status=_VirtualProcSearch(macro_name);
   if (status) {
      if (replace_code_filename=='') {
         _message_box(nls("%s could not be found.", macro_name));
      } else {
         // Need to append replace_code
         status=0;
      }
   } else {
      typeless mark_id=_alloc_selection();
      status=select_proc(0,mark_id);
      if (status) {
         _free_selection(mark_id);
         _message_box(nls("Unable to select macro function text"));
      }
      if (!status) {
         _begin_select(mark_id);up();
         _delete_selection(mark_id);
         _free_selection(mark_id);
         if (replace_code_with_markid>=0) {
            insert_line('');
            _copy_to_cursor(replace_code_with_markid);
         }
         do_save=true;
      }
      replace_code_with_markid= -1; // Done replacing code
   }
   if (replace_code_with_markid>=0) {
      bottom();
      insert_blank_line:=true;
      if (p_line==1) {
         get_line(auto line);
         if (line=='') {
            _delete_line();
            insert_blank_line=false;
         }
      }
      // IF we are appending to the end of a non_empty file
      if (insert_blank_line) {
         insert_line('');
      }
      _copy_to_cursor(replace_code_with_markid);
      do_save=true;
   }
   if (do_save ) {
      status=save('',SV_NOADDFILEHIST);
      //status=_save_file(build_save_options(p_buf_name));
      if (!status) {
         if (replace_code_filename=='') {
            delete_name(index);
            name := name_name(index);
            if (name!='') {
               _message_box(nls('Macro %s will still be listed because another macro calls this macro.  However, its code has been deleted.  Fix your other macros which call %s.',name,name));
            }
         }
      }
   }
   _delete_temp_view(temp_view_id);
   if (!status && do_reload) {
      load(_maybe_quote_filename(filename));
   }
   activate_window(orig_view_id);
   return(status);
}

_command int delete_macro(_str macro_name = '') name_info(MACRO_ARG','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (macro_name=='') {
      return(0);
   }
   macro_name=translate(macro_name,"_","-");
   index := find_index(macro_name,COMMAND_TYPE);
   if (!index) {
      _message_box(nls("%s does not exist or is not loaded.",macro_name));
      return(COMMAND_CANCELLED_RC);
   }

   typeless flags = '';
   parse name_info(index) with ',' flags;
   if (!(flags & VSARG2_MACRO)) {
      _message_box(nls("%s is not a user macro and cannot be deleted.",macro_name));
      return (0);
   }

   int status = _delete_macro(macro_name);
   return (status);
}

defeventtab _autoenable_form;
static bool ENABLE_ONUPDATE(...) {
   if (arg()) ctlok.p_user=arg(1);
   return ctlok.p_user;
}
static _str MACRO_NAME(...) {
   if (arg()) p_active_form.p_user=arg(1);
   return p_active_form.p_user;
}
void ctlok.lbutton_up()
{
   reqflag_names := "";
   if (ctleditorctl.p_value) {
      if (reqflag_names!='') reqflag_names :+= '|';
      reqflag_names :+= "VSARG2_EDITORCTL";
   }
   if (ctlread_only.p_value) {
      if (reqflag_names!='') reqflag_names :+= '|';
      reqflag_names :+= "VSARG2_READ_ONLY";
   }
   if (ctlicon.p_value) {
      if (reqflag_names!='') reqflag_names :+= '|';
      reqflag_names :+= "VSARG2_ICON";
   }
   if (ctlrequires_ab_selection.p_value) {
      if (reqflag_names!='') reqflag_names :+= '|';
      reqflag_names :+= "VSARG2_REQUIRES_AB_SELECTION";
   }
   if (ctlrequires_block_selection.p_value) {
      if (reqflag_names!='') reqflag_names :+= '|';
      reqflag_names :+= "VSARG2_REQUIRES_BLOCK_SELECTION";
   }
   if (ctlrequires_clipboard.p_value) {
      if (reqflag_names!='') reqflag_names :+= '|';
      reqflag_names :+= "VSARG2_REQUIRES_CLIPBOARD";
   }
   if (ctlrequires_selection.p_value) {
      if (reqflag_names!='') reqflag_names :+= '|';
      reqflag_names :+= "VSARG2_REQUIRES_SELECTION";
   }
   if (ctlrequires_fileman_mode.p_value) {
      if (reqflag_names!='') reqflag_names :+= '|';
      reqflag_names :+= "VSARG2_REQUIRES_FILEMAN_MODE";
   }
   if (ctlrequires_unicode_buffer.p_value) {
      if (reqflag_names!='') reqflag_names :+= '|';
      reqflag_names :+= "VSARG2_REQUIRES_UNICODE_BUFFER";
   }
   if (ctlrequires_mdi_editorctl.p_value) {
      if (reqflag_names!='') reqflag_names :+= '|';
      reqflag_names :+= "VSARG2_REQUIRES_MDI_EDITORCTL";
   }
   if (ctlrequires_tagging.p_value) {
      if (reqflag_names!='') reqflag_names :+= '|';
      reqflag_names :+= "VSARG2_REQUIRES_TAGGING";
   }
   int status=_set_macro_enable_flags(MACRO_NAME(),reqflag_names);
   if (!status) {
      p_active_form._delete_window();
   }
}
void ctlrequires_mdi_editorctl.lbutton_up()
{
   if (p_value) {
      ctlread_only.p_enabled=true;
      ctlicon.p_enabled=true;
      ctlrequires_ab_selection.p_enabled=ENABLE_ONUPDATE();
      ctlrequires_tagging.p_enabled=ENABLE_ONUPDATE();
      ctlrequires_fileman_mode.p_enabled=ENABLE_ONUPDATE();
      ctlrequires_unicode_buffer.p_enabled=ENABLE_ONUPDATE();
      return;
   }
   ctlread_only.p_enabled=false;
   ctlread_only.p_value=0;
   ctlicon.p_enabled=false;
   ctlicon.p_value=0;
   ctlrequires_ab_selection.p_enabled=false;
   ctlrequires_ab_selection.p_value=0;
   ctlrequires_tagging.p_enabled=false;
   ctlrequires_tagging.p_value=0;
   ctlrequires_fileman_mode.p_enabled=false;
   ctlrequires_fileman_mode.p_value=0;
   ctlrequires_unicode_buffer.p_enabled=false;
   ctlrequires_unicode_buffer.p_value=0;
}
void ctlok.on_create(_str cmdname="mac1" /* something for testing */)
{
   MACRO_NAME(cmdname);
   index := find_index(cmdname,COMMAND_TYPE);
   if (!index) {
      p_active_form._delete_window();
      return;
   }
   p_active_form.p_caption=p_active_form.p_caption' 'cmdname;
   int update_index=_findOnUpdateForCommand(cmdname);
   if (update_index) {
      ENABLE_ONUPDATE(false);
      // If this is an _OnUpdate function, many of the
      // requires flags have no effect.  This
      // may change in the future.
      ctlrequires_block_selection.p_enabled=false;
      ctlrequires_clipboard.p_enabled=false;
      ctlrequires_selection.p_enabled=false;
      ctlrequires_fileman_mode.p_enabled=false;
      ctlrequires_unicode_buffer.p_enabled=false;
      ctlrequires_tagging.p_enabled=false;
   } else {
      ENABLE_ONUPDATE(true);
   }
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
      //ctlrequires_mdi_editorctl.p_visible=false;
      //ctlrequires_mdi_editorctl.p_value=0;
      //ctlrequires_editorctl.p_value=1;
      ctlicon.p_visible=false;
   }
   typeless flags;
   parse name_info(index) with ',' flags;
   if (!isinteger(flags)) flags=0;
   if (flags &VSARG2_EDITORCTL) {
      ctleditorctl.p_value=1;
   }
   if (flags & VSARG2_READ_ONLY) {
      ctlread_only.p_value=1;
   }
   if (flags & VSARG2_ICON) {
      ctlicon.p_value=1;
   }
   if (flags & VSARG2_REQUIRES_AB_SELECTION) {
      ctlrequires_ab_selection.p_value=1;
   }
   if (flags & VSARG2_REQUIRES_BLOCK_SELECTION) {
      ctlrequires_block_selection.p_value=1;
   }
   if (flags & VSARG2_REQUIRES_CLIPBOARD) {
      ctlrequires_clipboard.p_value=1;
   }
   if (flags & VSARG2_REQUIRES_SELECTION) {
      ctlrequires_selection.p_value=1;
   }
   if (flags & VSARG2_REQUIRES_FILEMAN_MODE) {
      ctlrequires_fileman_mode.p_value=1;
   }
   if (flags & VSARG2_REQUIRES_UNICODE_BUFFER) {
      ctlrequires_unicode_buffer.p_value=1;
   }
   if (flags & VSARG2_REQUIRES_TAGGING) {
      ctlrequires_tagging.p_value=1;
   }
   if (flags & VSARG2_REQUIRES_MDI_EDITORCTL) {
      ctlrequires_mdi_editorctl.p_value=1;
   } else {
      ctlrequires_mdi_editorctl.call_event(ctlrequires_mdi_editorctl,LBUTTON_UP);
   }
}
