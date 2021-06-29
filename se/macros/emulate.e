////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc. 
// You may modify, copy, and distribute the Slick-C Code (modified o/r unmodified) 
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
#include "plugin.sh"
#import "complete.e"
#import "files.e"
#import "help.e"
#import "keybindings.e"
#import "main.e"
#import "options.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "vi.e"
#import "cfg.e"
#endregion

static const SLICKDEF_FILE= 'slickdef';
static const BRIEF_FILE= 'briefdef';
static const EMACS_FILE= 'emacsdef';
static const VI_FILE= 'videf';
static const WINDOWS_FILE= 'windefs';
static const MACOSX_FILE= 'macosxdefs';
static const GNUEMACS_FILE= 'gnudef';
static const ISPF_FILE= 'ispfdef';
static const VCPP_FILE= 'vcppdef';
static const VSNET_FILE= 'vsnetdef';
static const ISPF_FILE= 'ispfdef';
static const CW_FILE= 'codewarriordef';
static const CODEWRIGHT_FILE= 'codewrightdef';
static const BBEDIT_FILE= 'bbeditdef';
static const XCODE_FILE= 'xcodedef';
static const ECLIPSE_FILE= 'eclipsedef';

defmain()
{
   _no_mdi_bind_all=true;
   parse arg(1) with auto new_keys auto export_keys auto import_keys;
   int optionLevel=(import_keys!='0')?0:1;
   if (export_keys != '0') {
      _update_profiles_for_modified_eventtabs();
   }

   mou_hour_glass(true);
   param := upcase(strip(new_keys));
   int old_modify=_config_modify_flags();
   _config_modify_flags(CFGMODIFY_KEYS);
   if ( def_keys=='vi-keys' && param!='VI' ) {
      vi_switch_mode('I','1','1');   /* Fix up the keytable pointers */
   }
   typeless status=0;
   if ( param=='BRIEF' ) {
      status=brief(optionLevel);
   } else if ( param=='EMACS' || param=='EPSILON') {
      param='EPSILON';
      status=emacs(optionLevel);
   } else if ( param=='GNU' || param=='GNUEMACS' ) {
      status=gnuemacs(optionLevel);
   } else if ( param=='ISPF') {
      status=ispf(optionLevel);
   } else if ( param=='VI' || param=='VIM' ) {
      param = 'VIM';
      status=vi(optionLevel);
   } else if ( param=='SLICK' ) {
      status=slick(optionLevel);
   } else if ( param=='WINDOWS' || param=='WIN' || param=='CUA') {
      status=windows(optionLevel);
      param="CUA";
   } else if ( param=='MAC' || param=='MACOSX') {
      param="MACOSX";
      status=mac_cua(optionLevel);
   } else if ( param=='DEVSTUD' || param=='VCPP') {
      status=vcpp(optionLevel);
   } else if ( param=='VSNET' ) {
      status=vsnet(optionLevel);
   } else if ( param=='CODEWARRIOR' ) {
      status=codewarrior(optionLevel);
   } else if ( param=='CODEWRIGHT' ) {
      status=codewright(optionLevel);
   } else if ( param=='BBEDIT' ) {
      status=bbedit(optionLevel);
   } else if ( param=='XCODE' ) {
      status=xcode(optionLevel);
   } else if ( param=='ECLIPSE' ) {
      status=eclipse(optionLevel);
   } else {
      _config_modify_flags(old_modify, 0);
      message(nls("Don't have emulation for '%s'",param));
      status=1;
   }
   if ( ! status ) {
      message(nls('Configuration set to %s.',param));
   }

   _no_mdi_bind_all=false;
   menu_mdi_bind_all();

   mou_hour_glass(false);
   return(status);

}
static _str brief(int optionLevel)
{
   // If you add modules here, you must add then in the _firstinit function
   return(change_config(optionLevel,"BRIEF",
      'argument briefsch briefutl poperror',
      BRIEF_FILE,
      "brief-keys")
      );
}
static _str change_config(int optionLevel,_str config_name,
                          _str source_files,
                          typeless list_source_pcode,
                          typeless summary_of_keys)
{
   typeless status=0;
   list_source_pcode :+= _macro_ext'x';
   _str path=_getSlickEditInstallPath()'macros':+FILESEP:+('emulate'_macro_ext'x');
   if ( path=='' ) {
      popup_message(nls("Can't find %s file",'emulate'_macro_ext'x'));
      return(1);
   }

   filename := "";
   filename_with_ext := "";
   module := "";
   qmodule := "";
   path=substr(path,1,pathlen(path));
   // Now that all emulation source files have to be in the
   // system state file, we should not load these modules.
#if 0
   for (;;) {
      parse source_files with filename source_files;
      if ( filename=='' ) {
         break;
      }

      // check if this module is already loaded
      module_index := find_index(filename:+_macro_ext:+'x', MODULE_TYPE);
      if (module_index > 0) {
         continue;
      }

      filename=path:+filename;
      if ( file_match('-p '_maybe_quote_filename(filename:+_macro_ext),1)!='' ) {
         filename_with_ext=filename:+_macro_ext;
      } else {
         filename_with_ext=filename:+_macro_ext'x';
      }
      module=filename_with_ext;
      qmodule=_maybe_quote_filename(module);
      status=_load(qmodule,'u');      //Unload the module
      // IF this module has not already been loaded.
      if (status!=CANT_REMOVE_MODULE_RC) {
         // Make caller set this
         //_config_modify_flags(CFGMODIFY_LOADMACRO);

         message(nls('making:')' 'module);
         status=_make(qmodule);
         if (status) {
            _message_box(nls("Unable to compile macro '%s'",module));
            return(status);
         }
         status=_load(qmodule);
         if ( status) {
            _message_box(nls("Error loading module:")" ":+module:+".  "get_message(status));
            return(status);
         }
      }
      if ( file_match('-p '_maybe_quote_filename(filename:+_macro_ext'x'),1)=='' ) {
         _message_box(nls("Can't find or build '%s'",filename:+_macro_ext:+'x'));
         return(1);
      }
   }
#endif
   _eventtab_get_mode_keys('process-keys',1);
   _eventtab_get_mode_keys('fileman-keys',1);
   _eventtab_get_mode_keys('grep-keys',1);
   zap_key_bindings('default-keys');

   macro := "";
   {
      macro='commondefs';
      filename=_getSlickEditInstallPath()'macros':+FILESEP:+(macro:+_macro_ext'x');
      if (filename=='') {
         filename=_getSlickEditInstallPath()'macros':+FILESEP:+(macro:+_macro_ext);
      }
      if (filename=='') {
         _message_box("File '%s' not found",macro:+_macro_ext'x');
         return(FILE_NOT_FOUND_RC);
      }
      status=shell(macro);
      if (status) {
         _message_box(nls("Unable to load common keybindings."));
         return(1);
      }
   }

   typeless gui=def_gui;
   //alt_menu=def_alt_menu;
   status=shell(_maybe_quote_filename(path:+_strip_filename(list_source_pcode,'E')));
   if ( status==FILE_NOT_FOUND_RC || status==NO_MORE_FILES_RC ) {
      _message_box(nls("File '%s' not found",list_source_pcode));
      return(1);
   } else if (status){
      if (status<0) {
         _message_box(nls("Unable to run macro %s\n\n"get_message(status),list_source_pcode));
         return(status);
      } else {
         _message_box(nls('Unable to run macro %s',list_source_pcode));
         return(status);
      }
   }
   def_keys=summary_of_keys;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   _set_emulation_key_bindings(false,optionLevel);
   def_gui=gui;
   //def_alt_menu=alt_menu;
   set_emulation := "";
  
   //Set command line prompting if necessary
   {
      macro='guisetup';
      filename=_getSlickEditInstallPath()'macros':+FILESEP:+(macro:+_macro_ext'x');
      if (filename=='') {
         filename=_getSlickEditInstallPath()'macros':+FILESEP:+(macro:+_macro_ext);
      }
      if (filename=='') {
         _message_box("File '%s' not found",macro:+_macro_ext'x');
         return(FILE_NOT_FOUND_RC);
      }
      status=shell(macro' 'number2yesno(def_gui));
      if (status) {
         _message_box(nls("Unable to set cmdline prompt option.\n\nError probably caused by missing macro compiler or incorrect macro compiler version."));
         return(1);
      }
   }
#if 0
   {
      macro='altsetup';
      filename=get_env('VSROOT')'macros':+FILESEP:+(macro:+_macro_ext'x');
      if (filename=='') {
         filename=get_env('VSROOT')'macros':+FILESEP:+(macro:+_macro_ext);
      }
      if (filename=='') {
         _message_box("File '%s' not found",macro:+_macro_ext'x');
         return(FILE_NOT_FOUND_RC);
      }
      _no_mdi_bind_all=1;
      status=shell(macro' 'number2yesno(def_alt_menu));
      _no_mdi_bind_all=0;
      if (status) {
         _message_box(nls("Unable to set alt menu hotkeys.\n\nError probably caused by missing macro compiler or incorrect macro compiler version."));
         return(1);
      }
   }
#endif

   // Notify call-list about event table changes
   call_list('_eventtab_modify_',defeventtab default_keys,'');
   clear_message();
   return(0);

}
#if 0
static void rebind_rootkey(old_command,new_command)
{
   command_index= find_index(new_command,COMMAND_TYPE);
   if ( ! command_index ) {
      return(0);
   }
   index= find_index(old_command,COMMAND_TYPE);
   if ( ! index ) {
      return(0);
   }
   key_index= -1;
   for (;;) {
      list_bindings key_index,name_index_found,keys_used,
                    _default_keys,_default_keys,index;
      if ( key_index<0 ) { break; }
      key_name=_key_for_display(index2event(key_index));
      if ( ! (name_type(name_index_found)&EVENTTAB_TYPE) ) {
         set_eventtab_index _default_keys,key_index,command_index;
      }
   }
}
#endif
static _str emacs(int optionLevel)
{
   // If you add modules here, you must add then in the _firstinit function
   return(change_config(optionLevel,"EMACS","argument prefix emacs",
     EMACS_FILE,
      "emacs-keys")
      );
}
static _str gnuemacs(int optionLevel)
{
   // If you add modules here, you must add then in the _firstinit function
   return(change_config(optionLevel,"GNUEMACS","argument prefix emacs gemacs",
     GNUEMACS_FILE,
      "gnuemacs-keys")
      );
}
static _str ispf(int optionLevel)
{
   // If you add modules here, you must add then in the _firstinit function
   return(change_config(optionLevel,"ISPF","ispf ispflc ispfsrch",
      ISPF_FILE,
      "ispf-keys")
      );
}
static _str vi(int optionLevel)
{
   // If you add modules here, you must add then in the _firstinit function
   // Load vi files to rerun definit's
   typeless status=change_config(optionLevel,"VI","ex vi vicmode viimode vivmode",
     VI_FILE,
     "vi-keys");
   if( !status ) {
      status=vi_switch_mode('C');   /* Have to switch the mode AFTER the event-tables have been loaded */
   }
   return(status);
}
static _str windows(int optionLevel,)
{
   // must reload cancel_key_index function
   return(change_config(optionLevel,"WINDOWS",
            "",WINDOWS_FILE,
             "windows-keys")
      );

}
static _str mac_cua(int optionLevel)
{
    return(change_config(optionLevel,"MACOSX",
             "",MACOSX_FILE,
              "macosx-keys")
       );
}
static _str eclipse(int optionLevel)
{
   // must reload cancel_key_index function
   return(change_config(optionLevel,"ECLIPSE",
            "",ECLIPSE_FILE,
             "eclipse-keys")
      );

}
static _str vcpp(int optionLevel)
{
   return(change_config(optionLevel,"VCPP","vsnet",
                        VCPP_FILE,
                        "vcpp-keys")
         );

}
static _str vsnet(int optionLevel)
{
   return(change_config(optionLevel,"VSNET","vsnet",
                        VSNET_FILE,
                        "vsnet-keys")
         );
}
static _str codewarrior(int optionLevel)
{
   return(change_config(optionLevel,"CODEWARRIOR","codewarrior",
                        CW_FILE,
                        "codewarrior-keys")
         );
}
static _str codewright(int optionLevel)
{
   return(change_config(optionLevel,"CODEWRIGHT","briefutl", 
                        CODEWRIGHT_FILE,
                        "codewright-keys"
                        )
          );
}
static _str bbedit(int optionLevel)
{
   return(change_config(optionLevel,"BBEDIT","bbedit", 
                        BBEDIT_FILE,
                        "bbedit-keys"
                        )
          );
}
static _str xcode(int optionLevel)
{
   return(change_config(optionLevel,"XCODE","xcode", 
                        XCODE_FILE,
                        "xcode-keys"
                        )
          );
}
static _str slick(int optionLevel)
{
   // must reload cancel_key_index function
   return(change_config(optionLevel,"SLICK","",
                    SLICKDEF_FILE,""));

}

static void _empty_key_table(int ktab_index)
{
   VSEVENT_BINDING list[];
   int NofBindings;
   list_bindings(ktab_index, list);
   NofBindings = list._length();

   i := 0;
   for (i; i < NofBindings; ++i) {
      index := eventtab_index(ktab_index, ktab_index, list[i].iEvent);
      if (name_type(index) == EVENTTAB_TYPE) {
         _empty_key_table(index);
           delete_name(index);
      }
      set_eventtab_index(ktab_index, list[i].iEvent, 0, list[i].iEndEvent);
   }
}

static void zap_key_bindings(_str keytab_name)
{
   ktab_index := find_index(keytab_name,EVENTTAB_TYPE);
   if (!ktab_index) {
      return;
   }
   _empty_key_table(ktab_index);
}
