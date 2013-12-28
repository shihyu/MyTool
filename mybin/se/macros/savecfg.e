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
#endregion

_command external_command(_str a="");

boolean _need_to_save_state()
{
   // IF want config source files OR
   //    always want state file when write config source files
   if (!def_cfgfiles || def_localsta) return(1);
   _str path=_ConfigPath();
   _str statepath=_strip_filename(editor_name('s'),'n');
   if (statepath=='' || /* file_eq(path,statepath)|| */
       (_config_modify & (CFGMODIFY_MUSTSAVESTATE)) ||
       ( file_eq(path,statepath) &&
         (_config_modify & (CFGMODIFY_DELRESOURCE))
       )
      ) {
      return(1);
   }
   return(0);
#if 0
   if (!def_cfgfiles) return(1);
   //The UNIX HOME environment variable is always set which make
   //all UNIX installations multiple user.
   boolean single_user=0;
#if !__UNIX__
   single_user= get_env(_SLICKCONFIG)=='';
#endif
   path=_ConfigPath();
   statepath=strip_filename(editor_name('s'),'n');
   if (single_user || statepath=='' || file_eq(path,statepath)||
       (_config_modify & (CFGMODIFY_MUSTSAVESTATE))) {
      return(1);
   }
   return(0);
#endif
}
boolean _need_to_save_cfgfiles()
{
   if (!def_cfgfiles) return(0);
   _str statepath=_strip_filename(editor_name('s'),'n');
   return(statepath!='');
#if 0
   //  IF user never wants config source files written
   if (!def_cfgfiles) return(0);
   //The UNIX HOME environment variable is always set which make
   //all UNIX installations multiple user.
   boolean single_user=0;
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

int save_config2(boolean save_immediate=false)
{
   boolean cfgfiles_already_saved=1;
   boolean state_file_already_saved=1;
   int orig_wid=p_window_id;
   typeless status=0;
   if (_need_to_save_cfgfiles()) {
       status=_save_cfgfiles(cfgfiles_already_saved);
       if (_need_to_save_state()) {
          status=write_state(_default_state_filename());
          state_file_already_saved=0;
       }
   } else {
      if (_need_to_save_state()) {
         if (_config_modify) {
            status=write_state(_default_state_filename());
            state_file_already_saved=0;
         }
      }
   }
   if (cfgfiles_already_saved && state_file_already_saved) {
      message('Configuration already saved');
      status=0;
   } else if (status) {
      // Always fail silently when running as Tools
      if(isVisualStudioPlugin()) {
         status=0;
      } else {
         if (save_immediate) {
            int result=_message_box("Unable to save the configuration\n\nDo you want correct the problem and try again?\n\nIf you can't correct the problem, your configuration changes will be lost.",'',MB_YESNO,IDYES);
            if (result==IDNO) {
               status=0;
            }
         } else {
            int result=_message_box("Unable to save the configuration\n\nDo you want to exit anyway?",'',MB_YESNOCANCEL,IDNO);
            if (result==IDYES) {
               status=0;
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
   int focus_wid=_get_focus();
   int index=0;
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
   if (_config_modify &
         (CFGMODIFY_ALLCFGFILES|CFGMODIFY_DEFVAR|CFGMODIFY_DEFDATA|CFGMODIFY_OPTION|CFGMODIFY_KEYS)
      ) {
      cfgfiles_already_saved=0;
      status=list_source('','0'/* no refresh.*/,_config_modify&CFGMODIFY_KEYS,
                         1 /* UseTempViewNSave */);
      if (status) {
         return(status);
      }
   }
   if (_config_modify & (CFGMODIFY_RESOURCE|CFGMODIFY_ALLCFGFILES)) {
      cfgfiles_already_saved=0;
      status=list_objects('','',0 /* erase if none. */,1 /* UseTempViewNSave */);
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
   _str output_filename=arg(5);
   boolean UseTempViewNSave=arg(4)!="";
   boolean dorefresh=arg(2)=='';
   boolean insert_keys=arg(3)=='' || arg(3);
   if (dorefresh) {
      refresh();
   }
   _str filename=get_env('VSROOT')'macros':+FILESEP:+('vlstkeys'_macro_ext);
   if (filename=='') {
      filename=get_env('VSROOT')'macros':+FILESEP:+('vlstkeys'_macro_ext'x');
      if (filename=='') {
         _message_box(nls("File '%s' not found",'vlstkeys'_macro_ext'x'));
         return(FILE_NOT_FOUND_RC);
      }
   }
   _str path= substr(filename,1,pathlen(filename));
   _make(maybe_quote_filename(path'vlstkeys'));
   if ( rc && rc!=FILE_NOT_FOUND_RC ) {   /* Don't have to have source code. */
     if ( rc==1 ) {  /* compiler error? */
       return(rc);
     }
     _message_box(nls('Unable to make external macros')'. 'get_message(rc));
     return(rc);
   }
   _make(maybe_quote_filename(path'vlstcfg'));
   if ( rc && rc!=FILE_NOT_FOUND_RC ) {   /* Don't have to have source code. */
     if ( rc==1 ) {  /* compiler error? */
       return(rc);
     }
     _message_box(nls('Unable to make external macros')'. 'get_message(rc));
     return(rc);
   }
   _str temp_name=output_filename;

   if (temp_name=='') {
      temp_name=slick_path_search(USERDEFS_FILE:+_macro_ext);

      if ( temp_name=='' ) {
         temp_name=path:+USERDEFS_FILE:+_macro_ext;
      }
      temp_name=absolute(temp_name);
      if ( _use_config_path(temp_name) ) {
         _str local_dir=_ConfigPath();
         if ( local_dir!='' ) {
            if ( _create_config_path() ) {
               return(1);
            }
            temp_name=local_dir:+USERDEFS_FILE:+_macro_ext;
         }
      }
   }
   typeless status=0;
   p_window_id=_mdi.p_window_id;
   filename=absolute(temp_name);
   int temp_view_id=0;
   int orig_view_id=0;
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
      status=edit('+q 'maybe_quote_filename(filename),EDIT_NOADDHIST|EDIT_NOSETFOCUS);
      if ( status && status!=NEW_FILE_RC) {
         _message_box(nls("Unable to open '%s'.  "get_message(status),filename));
         return(status);
      }
   }
   if ( _isdiffed(p_buf_id) ) {
      _message_box(nls("Cannot list source because '%s' is currently being diffed.",temp_name));
      if ( temp_view_id) {
         _delete_temp_view(temp_view_id);
      }
      return(1);
   }
   typeless mark=0;
   _str line="";
   if (!insert_keys) {
      top();
      status=search('^//marker','@rih');
      if (status) {
         // Skip of includes at top by searching for defeventtab statement
         search('^defeventtab','r@h');
         status=search('^\#include ','r@h');
      }
      if (status) {
         insert_keys=1;
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
            insert_keys=1;
         } else {
            _select_line(mark);bottom();_select_line(mark);
            _delete_selection(mark);
            _free_selection(mark);
         }
      }
   }
   if (insert_keys) {
      _lbclear();
      status=shell('vlstkeys insert');
      if ( status ) {
         p_modify=0;
         if (UseTempViewNSave) {
            _delete_temp_view(temp_view_id);
         } else {
            quit(false);
         }
         return(status);
      }
   }
   status=shell('vlstcfg insert');
   if ( status ) {
      p_modify=0;
      if (UseTempViewNSave) {
         _delete_temp_view(temp_view_id);
      } else {
         quit(false);
      }
      return(status);
   }
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

   return _save_file(saveOption" "maybe_quote_filename(filename));
}

