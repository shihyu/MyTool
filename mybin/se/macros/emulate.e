////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48733 $
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
#import "complete.e"
#import "files.e"
#import "help.e"
#import "keybindings.e"
#import "main.e"
#import "options.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "vi.e"
#endregion

#define   SLICKDEF_FILE 'slickdef'
#define   BRIEF_FILE 'briefdef'
#define   EMACS_FILE 'emacsdef'
#define   VI_FILE 'videf'
#define   WINDOWS_FILE 'windefs'
#define   MACOSX_FILE 'macosxdefs'
#define   GNUEMACS_FILE 'gnudef'
#define   ISPF_FILE 'ispfdef'
#define   VCPP_FILE 'vcppdef'
#define   VSNET_FILE 'vsnetdef'
#define   ISPF_FILE 'ispfdef'
#define   CW_FILE 'codewarriordef'
#define   CODEWRIGHT_FILE 'codewrightdef'
#define   BBEDIT_FILE 'bbeditdef'
#define   XCODE_FILE 'xcodedef'
#define   ECLIPSE_FILE 'eclipsedef'

defmain()
{
   parse arg(1) with auto new_keys auto export_keys auto import_keys;
   if (export_keys != '0') {
      //export current user key bindings for old emulation.
      _str exportFileName = '';
      exportFileName = longEmulationName(def_keys)'.user.xml';

      _str dirName = _ConfigPath()'keybindings':+FILESEP;
      _str quotedDirName = maybe_quote_filename(dirName);
      _str dirResult = dir_match(quotedDirName, 1);
      int madeDir = 0;
      if (dirResult == '') {
         madeDir = mkdir(dirName);
      }
      if (madeDir) {
         _StackDump();
         _message_box("Could not find or create directory for keybindings export: "dirName);
      } else {
         exportFileName = dirName :+ exportFileName;
         export_key_bindings(exportFileName, true);
      }
   }

   mou_hour_glass(1);
   _str param=upcase(strip(new_keys));
   int old_modify=_config_modify_flags();
   _config_modify_flags(CFGMODIFY_KEYS|CFGMODIFY_OPTION|CFGMODIFY_DEFVAR|CFGMODIFY_DEFDATA);
   if ( def_keys=='vi-keys' && param!='VI' ) {
      vi_switch_mode('I','1','1');   /* Fix up the keytable pointers */
   }
   typeless status=0;
   if ( param=='BRIEF' ) {
      status=brief();
   } else if ( param=='EMACS' || param=='EPSILON') {
      param='EPSILON';
      status=emacs();
   } else if ( param=='GNU' || param=='GNUEMACS' ) {
      status=gnuemacs();
   } else if ( param=='ISPF') {
      status=ispf();
   } else if ( param=='VI' || param=='VIM' ) {
      param = 'VIM';
      status=vi();
   } else if ( param=='SLICK' ) {
      status=slick();
   } else if ( param=='WINDOWS' || param=='WIN' || param=='CUA') {
      status=windows();
      param="CUA";
   } else if ( param=='MAC' || param=='MACOSX') {
      param="MACOSX";
      status=mac_cua();
   } else if ( param=='DEVSTUD' || param=='VCPP') {
      status=vcpp();
   } else if ( param=='VSNET' ) {
      status=vsnet();
   } else if ( param=='CODEWARRIOR' ) {
      status=codewarrior();
   } else if ( param=='CODEWRIGHT' ) {
      status=codewright();
   } else if ( param=='BBEDIT' ) {
      status=bbedit();
   } else if ( param=='XCODE' ) {
      status=xcode();
   } else if ( param=='ECLIPSE' ) {
      status=eclipse();
   } else {
      _config_modify_flags(old_modify, 0);
      message(nls("Don't have emulation for '%s'",param));
      status=1;
   }
   if ( ! status ) {
      message(nls('Configuration set to %s.',param));
   }

   if (import_keys != '0') {
      //import user keybindings for new emulation, if available.
      _str importFileName = longEmulationName(def_keys)'.user.xml';
      importFileName = _ConfigPath() :+ 'keybindings' :+ FILESEP :+ importFileName;
      if (file_exists(importFileName)) {
         import_key_bindings(importFileName);
      }
   }

   mou_hour_glass(0);
   return(status);

}
static _str brief()
{
   // If you add modules here, you must add then in the _firstinit function
   return(change_config("BRIEF",
      'argument briefsch briefutl poperror',
      BRIEF_FILE,
      "brief-keys")
      );
}
static _str change_config(_str config_name,
                          _str source_files,
                          typeless list_source_pcode,
                          typeless summary_of_keys)
{
   typeless status=0;
   list_source_pcode=list_source_pcode:+_macro_ext'x';
   _str path=get_env('VSROOT')'macros':+FILESEP:+('emulate'_macro_ext'x');
   if ( path=='' ) {
      popup_message(nls("Can't find %s file",'emulate'_macro_ext'x'));
      return(1);
   }

   _str filename='';
   _str filename_with_ext='';
   _str module='';
   _str qmodule='';
   path=substr(path,1,pathlen(path));
   for (;;) {
      parse source_files with filename source_files;
      if ( filename=='' ) {
         break;
      }
      filename=path:+filename;
      if ( file_match('-p 'maybe_quote_filename(filename:+_macro_ext),1)!='' ) {
         filename_with_ext=filename:+_macro_ext;
      } else {
         filename_with_ext=filename:+_macro_ext'x';
      }
      module=filename_with_ext;
      qmodule=maybe_quote_filename(module);
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
      if ( file_match('-p 'maybe_quote_filename(filename:+_macro_ext'x'),1)=='' ) {
         _message_box(nls("Can't find or build '%s'",filename:+_macro_ext:+'x'));
         return(1);
      }
   }
   zap_key_bindings('default-keys');
   zap_key_bindings('process-keys');
   zap_key_bindings('fileman-keys');
   zap_key_bindings('grep-keys');
   if (def_keys=='vi-keys') {    // extra cleanup on vi
      zap_key_bindings('vi-visual-keys');
      zap_key_bindings('vi-command-keys');
/*
      int index;
      index = find_index('vi-visual-keys', EVENTTAB_TYPE);
      if (index) {
         delete_name(index);
      }
      index = find_index('vi-command-keys', EVENTTAB_TYPE);
      if (index) {
         delete_name(index);
      }
*/
   }

   _str macro='';
   {
      macro='commondefs';
      filename=get_env('VSROOT')'macros':+FILESEP:+(macro:+_macro_ext'x');
      if (filename=='') {
         filename=get_env('VSROOT')'macros':+FILESEP:+(macro:+_macro_ext);
      }
      if (filename=='') {
         _message_box("File '%s' not found",macro:+_macro_ext'x');
         return(FILE_NOT_FOUND_RC);
      }
      _no_mdi_bind_all=1;
      status=shell(macro);
      _no_mdi_bind_all=0;
      if (status) {
         _message_box(nls("Unable to load common keybindings."));
         return(1);
      }
   
   }

   typeless gui=def_gui;
   //alt_menu=def_alt_menu;
   _no_mdi_bind_all=1;
   status=shell(maybe_quote_filename(path:+_strip_filename(list_source_pcode,'E')));
   _no_mdi_bind_all=0;
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
   def_gui=gui;
   //def_alt_menu=alt_menu;
   _str set_emulation='';
  
   //Set command line prompting if necessary
   {
      macro='guisetup';
      filename=get_env('VSROOT')'macros':+FILESEP:+(macro:+_macro_ext'x');
      if (filename=='') {
         filename=get_env('VSROOT')'macros':+FILESEP:+(macro:+_macro_ext);
      }
      if (filename=='') {
         _message_box("File '%s' not found",macro:+_macro_ext'x');
         return(FILE_NOT_FOUND_RC);
      }
      _no_mdi_bind_all=1;
      status=shell(macro' 'number2yesno(def_gui));
      _no_mdi_bind_all=0;
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
   menu_mdi_bind_all();

   def_keys=summary_of_keys;
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
static _str emacs()
{
   // If you add modules here, you must add then in the _firstinit function
   return(change_config("EMACS","argument prefix emacs",
     EMACS_FILE,
      "emacs-keys")
      );
}
static _str gnuemacs()
{
   // If you add modules here, you must add then in the _firstinit function
   return(change_config("GNUEMACS","argument prefix emacs gemacs",
     GNUEMACS_FILE,
      "gnuemacs-keys")
      );
}
static _str ispf()
{
   // If you add modules here, you must add then in the _firstinit function
   return(change_config("ISPF","ispf ispflc ispfsrch",
      ISPF_FILE,
      "ispf-keys")
      );
}
static _str vi()
{
   // If you add modules here, you must add then in the _firstinit function
   // Load vi files to rerun definit's
   typeless status=change_config("VI","ex vi vicmode viimode vivmode",
     VI_FILE,
     "vi-keys");
   if( !status ) {
      status=vi_switch_mode('C');   /* Have to switch the mode AFTER the event-tables have been loaded */
   }
   return(status);
}
static _str windows()
{
   // must reload cancel_key_index function
   return(change_config("WINDOWS",
            "",WINDOWS_FILE,
             "windows-keys")
      );

}
static _str mac_cua()
{
    return(change_config("MACOSX",
             "",MACOSX_FILE,
              "macosx-keys")
       );
}
static _str eclipse()
{
   // must reload cancel_key_index function
   return(change_config("ECLIPSE",
            "",ECLIPSE_FILE,
             "eclipse-keys")
      );

}
static _str vcpp()
{
   return(change_config("VCPP","vcpp",
                        VCPP_FILE,
                        "vcpp-keys")
         );

}
static _str vsnet()
{
   return(change_config("VSNET","vsnet",
                        VSNET_FILE,
                        "vsnet-keys")
         );
}
static _str codewarrior()
{
   return(change_config("CODEWARRIOR","codewarrior",
                        CW_FILE,
                        "codewarrior-keys")
         );
}
static _str codewright()
{
   return(change_config("CODEWRIGHT","briefutl", 
                        CODEWRIGHT_FILE,
                        "codewright-keys"
                        )
          );
}
static _str bbedit()
{
   return(change_config("BBEDIT","bbedit", 
                        BBEDIT_FILE,
                        "bbedit-keys"
                        )
          );
}
static _str xcode()
{
   return(change_config("XCODE","xcode", 
                        XCODE_FILE,
                        "xcode-keys"
                        )
          );
}
static _str slick()
{
   // must reload cancel_key_index function
   return(change_config("SLICK","",
                    SLICKDEF_FILE,""));

}

static void _empty_key_table(int ktab_index)
{
   VSEVENT_BINDING list[];
   int NofBindings;
   list_bindings(ktab_index, list);
   NofBindings = list._length();

   int i = 0;
   for (i; i < NofBindings; ++i) {
      int index = eventtab_index(ktab_index, ktab_index, list[i].iEvent);
      if (name_type(index) == EVENTTAB_TYPE) {
         _empty_key_table(index);
           delete_name(index);
      }
      set_eventtab_index(ktab_index, list[i].iEvent, 0, list[i].iEndEvent);
   }
}

static void zap_key_bindings(_str keytab_name)
{
   int ktab_index=find_index(keytab_name,EVENTTAB_TYPE);
   if (!ktab_index) {
      return;
   }
   _empty_key_table(ktab_index);
}
