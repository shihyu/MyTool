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
#import "beautifier.e"
#import "files.e"
#import "listbox.e"
#import "main.e"
#import "saveload.e" 
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "toolbar.e"
#import "util.e"
#import "vlstobjs.e"
#import "cfg.e"
#endregion

_command external_command(_str a="");

bool _need_to_save_state()
{
   // IF building state file OR any state file resource was modified
   if (editor_name('s')=='' || 
       (_default_option(VSOPTION_LOCALSTA) && (_config_modify & (CFGMODIFY_MUSTSAVESTATE_MASK))) 
       //|| ( file_eq(path,statepath) && (_config_modify & (CFGMODIFY_DELRESOURCE)) )
      ) {
      return(true);
   }
   return false;
#if 0
   // IF we are not listing source for modified forms and menus
   if (!def_cfgfiles) {
      _str path=_ConfigPath();
      statepath := _strip_filename(editor_name('s'),'n');
      // IF there is no local state file OR any state file resource was modified
      if (statepath=='' || /* file_eq(path,statepath)|| */
          (_config_modify & (CFGMODIFY_MUSTSAVESTATE_MASK)) 
          //|| ( file_eq(path,statepath) && (_config_modify & (CFGMODIFY_DELRESOURCE)) )
         ) {
         return(true);
      }
      return(false);
   }
   // IF want config source files OR
   //    always want state file when write config source files
   if (!def_cfgfiles || _default_option(VSOPTION_LOCALSTA)) return(true);
   _str path=_ConfigPath();
   statepath := _strip_filename(editor_name('s'),'n');
   if (statepath=='' || /* file_eq(path,statepath)|| */
       (_config_modify & (CFGMODIFY_MUSTSAVESTATE)) ||
       ( _file_eq(path,statepath) &&
         (_config_modify & (CFGMODIFY_DELRESOURCE))
       )
      ) {
      return(true);
   }
   return(false);
#endif

#if 0
   if (!def_cfgfiles) return(1);
   //The UNIX HOME environment variable is always set which make
   //all UNIX installations multiple user.
   single_user:=false;
#if !__UNIX__
   single_user= get_env(_SLICKCONFIG)=='';
#endif
   path=_ConfigPath();
   statepath=strip_filename(editor_name('s'),'n');
   if (single_user || statepath=='' || file_eq(path,statepath)||
       (_config_modify & (CFGMODIFY_MUSTSAVESTATE))) {
      return(true);
   }
   return(false);
#endif
}
bool _need_to_save_cfgfiles()
{
   if (!def_cfgfiles) return(false);
   statepath := _strip_filename(editor_name('s'),'n');
   // This is pretty close to the same as the flags required for saving the state file
   save_cfgfiles:=(_config_modify & (CFGMODIFY_MUSTSAVESTATE|CFGMODIFY_RESOURCE|CFGMODIFY_SYSRESOURCE|CFGMODIFY_USERMACS|CFGMODIFY_DELRESOURCE))!=0;
   return(statepath!='' && save_cfgfiles);
#if 0
   //  IF user never wants config source files written
   if (!def_cfgfiles) return(0);
   //The UNIX HOME environment variable is always set which make
   //all UNIX installations multiple user.
   single_user:=false;
#if !__UNIX__
   single_user= get_env(_SLICKCONFIG)=='';
#endif
   path=_ConfigPath();
   statepath=strip_filename(editor_name('s'),'n');
   // IF editor invoked with state file (NOT building state file) AND
   //    this is not a single user configuration
   if (statepath!='' && !single_user) {
      // Now check if the state file comes from the same directory as
      // the default configuration files.
      //
      default_cfgpath=get_env('VSROOT');
      //
      // IF state file is name directory as default stuff, don't need
      // need config files.
      //
      // This is a multi-user case where the user is configure like
      // a single user.
      //
      if (file_eq(path,default_cfgpath)) {
         //messageNwait('from default path statepath='statepath' default_cfgpath='default_cfgpath);
         return(0);
      }
      return(1);
   }
   return(0);
#endif
}
static bool gignore_user_options_changes=false;

void _config_reload_lang() {
   _plugin_eventtab_apply_all_bindings();
   _cbafter_import_beautifier_profiles_changed();
}

/** 
 * @return 
 * Returns 'true' if save should ignore changes to user options temporarily.
 * This prevents the "Do you want to reload your user options?" message. 
 *  
 * @param onoff   (optional) if specified, set whether or ignore changes to 
 *                user options. In this case, the original value is returned.
 */
bool _save_ignore_user_options_changes(bool onoff=null) 
{
   if (onoff != null) {
      orig_value := gignore_user_options_changes;
      gignore_user_options_changes = onoff;
      return orig_value;
   }
   return gignore_user_options_changes;
}

void _cbsave_user_options() {
   if (gignore_user_options_changes) return;
   _str user_options_filename=_ConfigPath():+VSCFGFILE_USER;
   if (!_file_eq(p_buf_name,user_options_filename)) {
      return;
   }
   handle:=_xmlcfg_open(user_options_filename,auto status);
   if (handle<0) {
      return;
   }
   _xmlcfg_close(handle);
   mou_hour_glass(false);
   result:=_message_box("Do you want to reload your user options?",'',MB_YESNO);
   if (result==IDYES) {
      plugin_reload_user_config();
   }
}
/**
 * Saves the user's configuration.
 *
 * @param save_immediate   false if we are saving on exit, true if
 *                         we are just saving for funsies
 *
 * @return int             0 if success
 */
int save_config2(bool save_immediate=false,bool ignore_errors=false,bool quiet=false)
{
   cfgfiles_already_saved := true;
   state_file_already_saved := true;
   user_cfg_xml_saved := true;
   orig_wid := p_window_id;
   typeless status=0;
   status_user_cfg_xml := 0;
   save_def_vars := (_config_modify & CFGMODIFY_DEFVAR)!=0;
   save_state_file:=(_config_modify & (CFGMODIFY_MUSTSAVESTATE_MASK))!=0;
   /*_message_box("save_state_file="save_state_file"\n":+
                "DEFVAR="(_config_modify & CFGMODIFY_DEFVAR)"\n":+
                "DEFDATA="(_config_modify & CFGMODIFY_DEFDATA)"\n":+
                "OPTION="(_config_modify & CFGMODIFY_OPTION)"\n":+
                "RESOURCE="(_config_modify & CFGMODIFY_RESOURCE)"\n":+
                "SYSRESOURCE="(_config_modify & CFGMODIFY_SYSRESOURCE)"\n":+
                "LOADMACRO="(_config_modify & CFGMODIFY_LOADMACRO)"\n":+
                "LOADDLL="(_config_modify & CFGMODIFY_LOADDLL)"\n":+
                "KEYS="(_config_modify & CFGMODIFY_KEYS)"\n":+
                "USERMACS="(_config_modify & CFGMODIFY_USERMACS)"\n":+
                "MUSTSAVESTATE="(_config_modify & CFGMODIFY_MUSTSAVESTATE)"\n":+
                "DELRESOURCE="(_config_modify & CFGMODIFY_DELRESOURCE)"\n");*/
   //_message_box('cfg='def_cfgfiles' local='_default_option(VSOPTION_LOCALSTA)' st='editor_name('s'));
   if (_need_to_save_cfgfiles()) {
      //_message_box('saving_cfgfiles');
      //_StackDump();
      //_message_box('pv='_post_install_version' loc='_default_option(VSOPTION_LOCALSTA)' MUSTSAVESTATE='(_config_modify & CFGMODIFY_MUSTSAVESTATE)' delres='(_config_modify &CFGMODIFY_DELRESOURCE)' res='(_config_modify &CFGMODIFY_RESOURCE)' sysres='(_config_modify&CFGMODIFY_SYSRESOURCE));
       status=_save_cfgfiles(cfgfiles_already_saved);
   }
   if (_need_to_save_state()) {
      //_message_box('saving_statefile');
      save_def_vars=true;
      //_message_box('write_state h2');
      status=write_state(_default_state_filename(),ignore_errors,quiet);
      state_file_already_saved=false;
   }
   // IF not building state file
   if (editor_name('s')!='') {
      if (save_def_vars) {
         //_message_box('saving vars');
         _def_vars_update_profile();
      }
   }
   if (_plugin_get_user_options_modify()) {
      int handle=_plugin_get_user_options();
      if (handle>=0) {
         user_cfg_xml_saved=false;
         _xmlcfg_apply_profile_style(handle,_xmlcfg_get_document_element(handle));
         int xml_output_wid;
         orig_wid2:=_create_temp_view(xml_output_wid);
         /* Save xml in UNIX eol format for more consistent cross platform EOL processing. This only makes
            a difference if new-lines are in PCDATA or attribute values.
         */
         p_newline="\n";
         p_buf_name=_xmlcfg_get_filename(handle);
         filename_no_quotes:=p_buf_name;
         _xmlcfg_save_to_buffer(xml_output_wid,handle,-1,VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
         gignore_user_options_changes=true;
         status_user_cfg_xml=save('',SV_NOADDFILEHIST|SV_QUIET);
         gignore_user_options_changes=false;
         _delete_temp_view(xml_output_wid);
         if (status_user_cfg_xml) {
            status_user_cfg_xml=_xmlcfg_save(handle,-1,VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
         }
         _xmlcfg_close(handle);
         if (!status_user_cfg_xml) {
            _plugin_set_user_options_modify(false);
         }
         //say('save user.cfg.xml');
         _config_file_dates:[_file_case(filename_no_quotes)]=_file_date(filename_no_quotes,'B');
      }
   }
   if (!ignore_errors) {
      if (cfgfiles_already_saved && state_file_already_saved && user_cfg_xml_saved) {
         message('Configuration already saved');
         status=0;
      } else if (status) {
         // Always fail silently when running as Tools
         if(isVisualStudioPlugin()) {
            status=0;
         } else {
            if (save_immediate) {
               int result=_message_box("Unable to save the configuration\n\nDo you want to correct the problem and try again?\n\nIf you can't correct the problem, your configuration changes will be lost.",'',MB_YESNO,IDYES);
               if (result==IDNO) {
                  status=0;
               }
            } else {
               int result=_message_box("Unable to save the configuration\n\nDo you want to exit anyway?",'',MB_YESNO,IDNO);
               if (result==IDYES) {
                  status=0;
               }
            }
         }
      }
   }
   if (!status) {
      _config_modify=0;
   }
   p_window_id=orig_wid;
   return(status);
}

static int _save_cfgfiles(var cfgfiles_already_saved)
{
   cfgfiles_already_saved=1;
   focus_wid := _get_focus();
   index := 0;
   // Check if there is a system toolbar which needs to be listed
   // in vusrobjs.e
   if (_config_modify & (CFGMODIFY_SYSRESOURCE|CFGMODIFY_ALLCFGFILES)) {
      index=name_match('',1,OBJECT_TYPE);
      for (;;) {
        if ( ! index ) { break; }
        /* Don't list source code for forms marked as system forms. */
        typeless ff=name_info(index);
        if (!isinteger(ff)) ff=0;
        if ((ff & FF_SYSTEM) && (ff & FF_MODIFIED) &&
            _tbIsCustomizeableToolbar(index)) {
           _config_modify_flags(CFGMODIFY_RESOURCE);
           break;
        }
        index=name_match('',0,OBJECT_TYPE);
      }
   }
   typeless status=0;
#if 0
   // vusrdefs
   if (_config_modify &
         (CFGMODIFY_ALLCFGFILES|CFGMODIFY_DEFVAR)
      ) {
      cfgfiles_already_saved=0;
      status = list_cfg_source(CS_USER_DEFS);
      if (status) {
         return(status);
      }
   }
#endif
#if 0
   // vusrdata
   if (_config_modify & (CFGMODIFY_ALLCFGFILES/*|CFGMODIFY_DEFDATA*/|CFGMODIFY_OPTION)) {
      cfgfiles_already_saved=0;
      status = list_cfg_source(CS_USER_DATA);
      if (status) {
         return(status);
      }
   }
#endif
#if 0
   // vusrkeys
   if (_config_modify & (CFGMODIFY_ALLCFGFILES|CFGMODIFY_KEYS)) {
      cfgfiles_already_saved=0;
      status = list_cfg_source(CS_USER_KEYS);
      if (status) {
         return(status);
      }
   }
#endif
   if (_config_modify & (CFGMODIFY_RESOURCE|CFGMODIFY_ALLCFGFILES)) {
      cfgfiles_already_saved=0;
      status=list_objects('','q'/* Quiet */,0 /* erase if none. */,1 /* UseTempViewNSave */);
      if (status!=1) {
         if (status) {
            return(status);
         }
      }
   }
   if (_config_modify & (CFGMODIFY_SYSRESOURCE|CFGMODIFY_ALLCFGFILES)) {
      cfgfiles_already_saved=0;
      status=list_objects(',,usersys','q'/* Quiet */,0 /* Erase if none.*/,1 /* UseTempViewNSave */);
      if (status!=1) {
         if (status) {
            return(status);
         }
      }
   }
   if (focus_wid ) {
      focus_wid._set_focus();
   }
   return(0);
}
/**
 * Opens a new buffer called "vusrs<I>NNN</I>.e" and inserts Slick-C&reg; source 
 * code for system dialog box templates (forms) that have been modified since 
 * SlickEdit was installed.  No user created dialog box templates are 
 * inserted.
 * 
 * @return Returns 0 if successful.  Returns 1 if no templates are defined.  
 * Other errors are non-zero.
 * 
 * @see list_sys_objects
 * @see list_objects
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Miscellaneous_Functions
 * 
 */
_command list_usersys_objects() name_info(','VSARG2_REQUIRES_MDI)
{
   return(list_objects(',,usersys'));
}
/**
 * Opens a new buffer called "sysobjs.e" and inserts Slick-C&reg; source code for 
 * all system dialog box (forms) and menu templates that existed when Visual 
 * SlickEdit was installed.  No user created dialog box templates are inserted.  
 * This command is typically used by the developers of SlickEdit.
 * 
 * @return Returns 0 if successful.  Returns 1 if no templates are defined 
 * (this should never happen).  Other errors are non-zero.
 * 
 * @see list_usersys_objects
 * @see list_objects
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Miscellaneous_Functions
 * 
 */
_command list_sys_objects() name_info(','VSARG2_REQUIRES_MDI)
{
   return(list_objects(',,sys'));
}
/** 
 * Runs the external batch macro 'listkeys.e' with no arguments.  This 
 * command creates a new buffer and inserts Slick-C&reg; source code representing all 
 * the key definitions including key definitions for all modes.  You may want to 
 * print this file and use it as a reference of your key definitions.
 * 
 * @see list_source
 * @see list_objects
 * @see list_usersys_objects
 * @see list_config
 * 
 * @categories Keyboard_Functions
 * 
 */
_command list_keydefs() name_info(','VSARG2_REQUIRES_MDI)
{
   return(external_command('vlstkeys'));
}
/** 
 * Runs the external batch macro 'listcfg.e' with no arguments.  This command 
 * creates a new buffer and inserts Slick-C&reg; source code representing the 
 * configuration of insert mode, colors, search case sensitivity, cache size, 
 * spill file path, scroll style, language syntax options, file load/save 
 * options, tabs, margins, and more.  For all variables that start with the four 
 * letters 'def_', an assignment statement (variable= current value) will be 
 * inserted into this buffer.  This command does NOT list key bindings or 
 * modified dialog box templates.  The commands <b>list_objects</b>, 
 * <b>list_usersys_objects</b>, and <b>list_source</b> generate other 
 * information.
 * 
 * @return Returns 0 if successful.
 * 
 * @see list_source
 * @see list_keydefs
 * @see list_objects
 * @see list_usersys_objects
 * @see list_sys_objects
 * 
 * @categories Miscellaneous_Functions
 * 
 */
_command list_config() name_info(','VSARG2_REQUIRES_MDI)
{
   return(external_command('vlstcfg'));
}


/**
 * Make sure we can find and build the macro used to list our 
 * config data. 
 * 
 * @return int       0 if everything is hunky dory, error 
 *                   message otherwise
 */
static int verify_list_cfg_macro(_str& path)
{
   if (path == '') {
      _str filename=_getSlickEditInstallPath()'macros':+FILESEP:+('vlstcfg'_macro_ext);
      if (filename=='') {
         filename=_getSlickEditInstallPath()'macros':+FILESEP:+('vlstcfg'_macro_ext'x');
         if (filename=='') {
            _message_box(nls("File '%s' not found",'vlstcfg'_macro_ext'x'));
            return(FILE_NOT_FOUND_RC);
         }
      }
      path= substr(filename,1,pathlen(filename));
   }

   // make sure we can run the list config macro
   _make(_maybe_quote_filename(path'vlstcfg'));
   if ( rc && rc!=FILE_NOT_FOUND_RC ) {   /* Don't have to have source code. */
     if ( rc==1 ) {  /* compiler error? */
       return(rc);
     }
     _message_box(nls('Unable to make external macros')'. 'get_message(rc));
     return(rc);
   }

   return 0;
}

enum_flags ConfigSource {
   CS_USER_DEFS,
   //CS_USER_DATA,
   CS_USER_KEYS,
};

static _str getCfgFilename(_str path, int cfg = CS_USER_DEFS)
{
   filename := '';
   switch (cfg) {
   case CS_USER_DEFS:
      filename = USERDEFS_FILE;
      break;
   //case CS_USER_DATA:
   //   filename = USERDATA_FILE;
   //   break;
   case CS_USER_KEYS:
      filename = USERKEYS_FILE;
      break;
   }

   temp_name := slick_path_search(filename :+ _macro_ext);

   if (temp_name == '') {
      temp_name = path :+ filename :+ _macro_ext;
   }

   temp_name = absolute(temp_name);
   if (_use_config_path(temp_name)) {
      local_dir := _ConfigPath();
      if (local_dir != '') {
         if (_create_config_path()) {
            return '';
         }
         temp_name = local_dir :+ filename :+ _macro_ext;
      }
   }

   return absolute(temp_name);
}

int list_cfg_source(int cfg)
{
   status := 0;
   path := '';
   filename := '';

   // first, make sure we have the proper macro to run
   if (cfg == CS_USER_KEYS) {
      return 1;
   } else {
      status = verify_list_cfg_macro(path);
   }
   if (status) return status;

   // now get the filename where we want to put this stuff
   filename = getCfgFilename(path, cfg);
   if (filename == '') return 1;

   // open up our file
   p_window_id = _mdi.p_window_id;
   temp_view_id := orig_view_id := 0;

   // do we open up a new temp view and save it as our file?
   status = _open_temp_view(filename, temp_view_id, orig_view_id);
   if (status) {
      if (status==FILE_NOT_FOUND_RC) {
         orig_view_id = _create_temp_view(temp_view_id);
         insert_line("");
         p_buf_name = filename;
         p_UTF8 = _load_option_UTF8(p_buf_name);
      } else {
         _message_box(nls("Unable to open '%s'.  "get_message(status), filename));
         return status;
      }
   }

   // if this file is currently being diffed, we can't do anything
   // apparently this happens sometimes
   if ( _isdiffed(p_buf_id) ) {
      _message_box(nls("Cannot list source because '%s' is currently being diffed.", filename));
      if (temp_view_id) {
         _delete_temp_view(temp_view_id);
      }
      return 1;
   }

   // clear the file
   _lbclear();
   switch (cfg) {
   case CS_USER_DEFS:
   //case CS_USER_DATA:
      status=shell('vlstcfg insert 'cfg);
      break;
   case CS_USER_KEYS:
      status = shell('vlstkeys insert');

      // add these to make it a batch file and make sure our config get saved
      insert_line('#pragma option(redeclvars,on)');
      insert_line("#include 'slick.sh'");
      insert_line('');
      insert_line('defmain()');
      insert_line('{');
      insert_line('  _config_modify_flags(CFGMODIFY_KEYS);');
      insert_line('  rc=0;');
      insert_line('}');
      break;
   }

   if (status) {
      // something went wrong!
      p_modify = false;
      _delete_temp_view(temp_view_id);
      return status;
   }

   // save and close our temp view
   status = _save_config_file();
   _delete_temp_view(temp_view_id);
   if (status) {
      _message_box(nls("Unable to save '%s'.  "get_message(status), filename));
      return status;
   }

   // done!
   return(0);
}

/**
 * This command creates a buffer called "vusrdefs.e" (UNIX: "vunxdefs.e") and 
 * inserts Slick-C&reg; source code representing your current configuration.  All 
 * configuration changes are listed except modified or new dialog box templates 
 * and menu templates.  See <b>list_objects</b>, <b>list_sys_objects</b> for 
 * information on generating source code for your dialog box and menu templates.   
 * The purpose of generating this file is usually to update to a new version of 
 * SlickEdit that can not read your old "vslick.sta" file.  The 
 * <b>vusrdefs</b> (UNIX: <b>vunxdefs</b>) batch macro can be executed in the 
 * new version of SlickEdit by typing the name on the command line.
 *  
 * @param unused           not used 
 * @param dorefresh        leave blank to force a refresh of the 
 *                         editor
 * @param insert_keys      1 or '' to insert the users key 
 *                         definitions
 * @param useTempView      create a temp view and save over the 
 *                         existing file
 * @param outputFilename   filename to output source
 *  
 * @return Returns 0 if successful.
 * 
 * @see list_objects
 * @see list_usersys_objects
 * @see list_keydefs
 * @see list_config
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Miscellaneous_Functions
 * 
 */
_command list_source(...) name_info(','VSARG2_REQUIRES_MDI)
{
   // retrieve the arguments
   _str output_filename=arg(5);
   UseTempViewNSave := arg(4)!="";
   dorefresh := arg(2)=='';
   insert_keys := arg(3)=='' || arg(3);

   // force immediate update of display
   if (dorefresh) refresh();

   // make sure we have the proper macros to do the job
   path := "";
   status := verify_list_cfg_macro(path);
   if (status) return status;

   // if we were not sent an output filename, use the default
   temp_name := getCfgFilename(path);

   // open up our file
   status=0;
   p_window_id=_mdi.p_window_id;
   filename:=absolute(temp_name);
   temp_view_id := 0;
   orig_view_id := 0;

   // do we open up a new temp view and save it as our file?
   if (UseTempViewNSave) {
      status=_open_temp_view(filename,temp_view_id,orig_view_id);
      if ( status) {
         if (status==FILE_NOT_FOUND_RC) {
            orig_view_id=_create_temp_view(temp_view_id);
            insert_line("");
            p_buf_name=filename;
            p_UTF8=_load_option_UTF8(p_buf_name);
         } else {
            _message_box(nls("Unable to open '%s'.  "get_message(status),filename));
            return(status);
         }
      }
   } else {
      // no, open the existing file and edit it
      status=edit('+q '_maybe_quote_filename(filename),EDIT_NOADDHIST|EDIT_NOSETFOCUS);
      if ( status && status!=NEW_FILE_RC) {
         _message_box(nls("Unable to open '%s'.  "get_message(status),filename));
         return(status);
      }
   }

   // if this file is currently being diffed, we can't do anything
   // apparently this happens sometimes
   if ( _isdiffed(p_buf_id) ) {
      _message_box(nls("Cannot list source because '%s' is currently being diffed.",temp_name));
      if ( temp_view_id) {
         _delete_temp_view(temp_view_id);
      }
      return(1);
   }

   typeless mark=0;
   line := "";
   // if we are not inserting the keys, then search for the marker in the file 
   // that is the end of the keys section
   if (!insert_keys) {
      top();
      status=search('^//marker','@rih');
      if (status) {
         // Skip of includes at top by searching for defeventtab statement
         search('^defeventtab','r@h');
         status=search('^\#include ','r@h');
      }
      if (status) {
         // no marker, we better insert the keys
         insert_keys=true;
      } else {
         up();get_line(line);
         if (line=='') {
            up();get_line(line);
            if (line!='') {
               down();
            }
         } else {
            down();
         }
         mark=_alloc_selection();
         if (mark<0) {
            insert_keys=true;
         } else {
            _select_line(mark);bottom();_select_line(mark);
            _delete_selection(mark);
            _free_selection(mark);
         }
      }
   }

   // insert keys?
   if (insert_keys) {
      _lbclear();
      status=shell('vlstkeys insert');
      if ( status ) {
         p_modify=false;
         if (UseTempViewNSave) {
            _delete_temp_view(temp_view_id);
         } else {
            quit(false);
         }
         return(status);
      }
   }

   // insert the config (def-data and def-vars)
   status=shell('vlstcfg insert');
   if ( status ) {
      p_modify=false;
      if (UseTempViewNSave) {
         _delete_temp_view(temp_view_id);
      } else {
         quit(false);
      }
      return(status);
   }

   // if we used a temp view, here is where we save and close it
   if (UseTempViewNSave) {
      status=_save_config_file();
      _str buf_name=p_buf_name;
      _delete_temp_view(temp_view_id);
      if (status) {
         _message_box(nls("Unable to save '%s'.  "get_message(status),buf_name));
         return(status);
      }
      return(0);
   }

   top();

   // done!
   return(0);
}

/** 
 * Saves a configuration option using standard, simplified 
 * options including only "+o" for overwrite and the user's 
 * +D options for file backup preferences (as specified in 
 * <code>def_save_options</code>). 
 * <p> 
 * The current object needs to be an editor control, just 
 * like you would expect for {@link _save_file()). 
 *  
 * @return Returns the result of {@link _save_file()}. 
 *  
 * @see _save_file 
 */
int _save_config_file(_str filename="")
{
   extension := _get_extension(p_buf_name);
   if (filename :!= "") extension = _get_extension(filename);

   saveOption := "+O";
   do {
      // don't try to do this for vpwhist files
      if (extension == "vpwhist") break;
         
      // backups have got to be turned on
      if (!pos("-O", def_save_options, 1, 'I')) break;

      // make sure we have a valid backup method
      if (!pos('(\+|\-)D', def_save_options, 1, 'IR')) break;
         
      // FINALLY, pull out the backup method and use it
      backupOption := "";
      parse substr(def_save_options, pos("S")) with backupOption .;
      saveOption = "-O "backupOption;

   } while (false);

   return _save_file(saveOption" "_maybe_quote_filename(filename));
}

