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
#import "main.e"
#import "stdprocs.e"
#endregion

defmain()
{
   if ( arg(1)=='' ) {
     command_put('guisetup 'number2yesno(def_gui));
     return(1);
   }
   new_gui := false;
   typeless status=setyesno(new_gui,arg(1));
   if ( status ) {
      return(1);
   }
   typeless cx_index=0;
   def_gui=new_gui;
   _config_modify_flags(CFGMODIFY_KEYS);
   switch (def_keys) {
   case 'windows-keys':
   case 'ispf-keys':
      if ( def_gui ) {
         execute('bind-to-key -r gui_find 'event2index(C_F));
         execute('bind-to-key -r gui_goto_line 'event2index(C_J));
         execute('bind-to-key -r gui_open 'event2index(C_O));
         execute('bind-to-key -r gui_replace 'event2index(C_R));
         //execute('bind-to-key -r gui_open 'event2index(C_F12));
      } else {
         execute('bind-to-key -r / 'event2index(C_F));
         execute('bind-to-key -r goto_line 'event2index(C_J));
         execute('bind-to-key -r edit 'event2index(C_O));
         execute('bind-to-key -r c 'event2index(C_R));
         //execute('bind-to-key -r edit 'event2index(C_F12));
      }
      break;
   case '':
      if ( def_gui ) {
         execute('bind-to-key -r gui_open 'event2index(F7));

         cx_index=find_index('default-keys:c-x',EVENTTAB_TYPE);
         if (cx_index) {
             set_eventtab_index(cx_index,event2index(C_F),find_index('gui-open',COMMAND_TYPE));
         }
      } else {
         execute('bind-to-key -r edit 'event2index(F7));

         cx_index=find_index('default-keys:c-x',EVENTTAB_TYPE);
         if (cx_index) {
             set_eventtab_index(cx_index,event2index(C_F),find_index('edit',COMMAND_TYPE));
         }
      }
      break;
   case 'brief-keys':
      if ( def_gui ) {
         if (!def_alt_menu) {
            execute('bind-to-key -r gui_open 'event2index(A_E));
            execute('bind-to-key -r gui_find 'event2index(A_S));
         }

         execute('bind-to-key -r gui_goto_line 'event2index(A_G));
         execute('bind-to-key -r gui_insert_file 'event2index(A_R));
         execute('bind-to-key -r gui_find 'event2index(F5));
         execute('bind-to-key -r gui_find_backward 'event2index(A_F5));

         execute('bind-to-key -r gui_replace 'event2index(F6));
         execute('bind-to-key -r gui_replace 'event2index(A_T));
         execute('bind-to-key -r gui_replace_backward 'event2index(A_F6));

         execute('bind-to-key -r gui_load 'event2index(F9));
         execute('bind-to-key -r gui_unload 'event2index(S_F9));
         execute('bind-to-key -r gui_save_macro 'event2index(A_F8));
      } else {
         if (!def_alt_menu) {
            execute('bind-to-key -r edit 'event2index(A_E));
            execute('bind-to-key -r search_forward 'event2index(A_S));
         }

         execute('bind-to-key -r goto_line 'event2index(A_G));
         execute('bind-to-key -r get 'event2index(A_R));
         execute('bind-to-key -r search_forward 'event2index(F5));
         execute('bind-to-key -r search_backward 'event2index(A_F5));

         execute('bind-to-key -r translate_forward 'event2index(F6));
         execute('bind-to-key -r translate_forward 'event2index(A_T));
         execute('bind-to-key -r translate_backward 'event2index(A_F6));

         execute('bind-to-key -r prompt_load 'event2index(F9));
         execute('bind-to-key -r unload 'event2index(S_F9));
         execute('bind-to-key -r save_macro 'event2index(A_F8));
      }
      break;
   case 'emacs-keys':
      if ( def_gui ) {
         execute('bind-to-key -r gui_find_backward_regex 'event2index(name2event('C-A-R')));
         execute('bind-to-key -r gui_find_regex 'event2index(name2event('C-A-S')));
         execute('bind-to-key -r gui_replace 'event2index(name2event('A-S-5')));
         execute('bind-to-key -r gui_replace 'event2index(name2event('A-S-7')));
         execute('bind-to-key -r gui_replace_regex 'event2index(name2event('A-S-8')));
         execute('bind-to-key -r gui_cd 'event2index(name2event('F7')));
         execute('bind-to-key -r gui_set_var 'event2index(name2event('F8')));
         //execute('bind-to-key -r gui_save_config 'event2index(name2event('C-F3')));
         execute('bind-to-key -r gui_copy_to_file 'event2index(name2event('C-F7')));
         execute('bind-to-key -r gui_set_var 'event2index(name2event('C-F8')));
         execute('bind-to-key -r gui_bind_to_key 'event2index(name2event('F4')));
         cx_index=find_index('default-keys:c-x',EVENTTAB_TYPE);
         if (cx_index) {
             set_eventtab_index(cx_index,event2index(C_F),find_index('gui-open',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index(C_V),find_index('gui-visit-file',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('.'),find_index('gui_push_tag',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('d'),find_index('fileman',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('f'),find_index('gui_margins',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('g'),find_index('gui_goto_line',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('i'),find_index('gui_insert_file',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('w'),find_index('gui_write_selection',COMMAND_TYPE));
             //set_eventtab_index cx_index,event2index(name2event('a-.')),find_index('gui_make_tags',COMMAND_TYPE)
             set_eventtab_index(cx_index,event2index(name2event('a-n')),find_index('gui_save_macro',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index(name2event('c-w')),find_index('gui_save_as',COMMAND_TYPE));
         }
      } else {
         execute('bind-to-key -r reverse_regex_search 'event2index(name2event('C-A-R')));
         execute('bind-to-key -r regex_search 'event2index(name2event('C-A-S')));
         execute('bind-to-key -r query_replace 'event2index(name2event('A-S-5')));
         execute('bind-to-key -r replace_string 'event2index(name2event('A-S-7')));
         execute('bind-to-key -r regex_replace 'event2index(name2event('A-S-8')));
         execute('bind-to-key -r prompt_cd 'event2index(name2event('F7')));
         execute('bind-to-key -r set_var 'event2index(name2event('F8')));
         //execute('bind-to-key -r save_config 'event2index(name2event('C-F3')));
         execute('bind-to-key -r copy_to_file 'event2index(name2event('C-F7')));
         execute('bind-to-key -r set_var 'event2index(name2event('C-F8')));
         execute('bind-to-key -r bind_to_key 'event2index(name2event('F4')));
         cx_index=find_index('default-keys:c-x',EVENTTAB_TYPE);
         if (cx_index) {
             set_eventtab_index(cx_index,event2index(C_F),find_index('edit',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index(C_V),find_index('visit-file',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('.'),find_index('goto-tag',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('d'),find_index('prompt_dir',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('f'),find_index('margins',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('g'),find_index('goto_line',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('i'),find_index('get',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('w'),find_index('put',COMMAND_TYPE));
             //set_eventtab_index cx_index,event2index(name2event('a-.')),find_index('make_tags',COMMAND_TYPE)
             set_eventtab_index(cx_index,event2index(name2event('a-n')),find_index('save_macro',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index(name2event('c-w')),find_index('save_as',COMMAND_TYPE));
         }
      }
      break;
   case 'gnuemacs-keys':
      if ( def_gui ) {
         execute('bind-to-key -r gui_find_backward_regex 'event2index(name2event('C-A-R')));
         execute('bind-to-key -r gui_find_regex 'event2index(name2event('C-A-S')));
         execute('bind-to-key -r gui_replace 'event2index(name2event('A-S-5')));
         execute('bind-to-key -r gui_replace 'event2index(name2event('A-S-7')));
         execute('bind-to-key -r gui_replace_regex 'event2index(name2event('A-S-8')));
         execute('bind-to-key -r gui_cd 'event2index(name2event('F7')));
         execute('bind-to-key -r gui_set_var 'event2index(name2event('F8')));
         //execute('bind-to-key -r gui_save_config 'event2index(name2event('C-F3')));
         execute('bind-to-key -r gui_copy_to_file 'event2index(name2event('C-F7')));
         execute('bind-to-key -r gui_set_var 'event2index(name2event('C-F8')));
         execute('bind-to-key -r gui_bind_to_key 'event2index(name2event('F4')));
         cx_index=find_index('default-keys:c-x',EVENTTAB_TYPE);
         if (cx_index) {
             set_eventtab_index(cx_index,event2index(C_F),find_index('gui-open',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index(C_V),find_index('gui-visit-file',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('.'),find_index('gui_push_tag',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('d'),find_index('fileman',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('f'),find_index('gui_margins',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('g'),find_index('gui_goto_line',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('i'),find_index('gui_insert_file',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('w'),find_index('gui_write_selection',COMMAND_TYPE));
             //set_eventtab_index cx_index,event2index(name2event('a-.')),find_index('gui_make_tags',COMMAND_TYPE)
             set_eventtab_index(cx_index,event2index(name2event('a-n')),find_index('gui_save_macro',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index(name2event('c-w')),find_index('gui_save_as',COMMAND_TYPE));
         }
      } else {
         execute('bind-to-key -r reverse_regex_search 'event2index(name2event('C-A-R')));
         execute('bind-to-key -r regex_search 'event2index(name2event('C-A-S')));
         execute('bind-to-key -r query_replace 'event2index(name2event('A-S-5')));
         execute('bind-to-key -r replace_string 'event2index(name2event('A-S-7')));
         execute('bind-to-key -r regex_replace 'event2index(name2event('A-S-8')));
         execute('bind-to-key -r prompt_cd 'event2index(name2event('F7')));
         execute('bind-to-key -r set_var 'event2index(name2event('F8')));
         //execute('bind-to-key -r save_config 'event2index(name2event('C-F3')));
         execute('bind-to-key -r copy_to_file 'event2index(name2event('C-F7')));
         execute('bind-to-key -r set_var 'event2index(name2event('C-F8')));
         execute('bind-to-key -r bind_to_key 'event2index(name2event('F4')));
         cx_index=find_index('default-keys:c-x',EVENTTAB_TYPE);
         if (cx_index) {
             set_eventtab_index(cx_index,event2index(C_F),find_index('edit',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index(C_V),find_index('visit-file',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('.'),find_index('goto-tag',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('d'),find_index('prompt_dir',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('f'),find_index('margins',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('g'),find_index('goto_line',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('i'),find_index('get',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index('w'),find_index('put',COMMAND_TYPE));
             //set_eventtab_index cx_index,event2index(name2event('a-.')),find_index('make_tags',COMMAND_TYPE)
             set_eventtab_index(cx_index,event2index(name2event('a-n')),find_index('save_macro',COMMAND_TYPE));
             set_eventtab_index(cx_index,event2index(name2event('c-w')),find_index('save_as',COMMAND_TYPE));
         }
      }
      break;
   case 'vi-keys':
      if ( def_gui ) {
         execute('bind-to-key -r gui_open 'event2index(F7));

         cx_index=find_index('default-keys:c-x',EVENTTAB_TYPE);
         if (cx_index) {
             set_eventtab_index(cx_index,event2index(C_F),find_index('gui-open',COMMAND_TYPE));
         }
      } else {
         execute('bind-to-key -r edit 'event2index(F7));

         cx_index=find_index('default-keys:c-x',EVENTTAB_TYPE);
         if (cx_index) {
             set_eventtab_index(cx_index,event2index(C_F),find_index('edit',COMMAND_TYPE));
         }
      }
      break;
   case 'vcpp-keys':
      if ( def_gui ) {
         execute('bind-to-key -r gui_find 'event2index(C_F));
         execute('bind-to-key -r gui_open 'event2index(C_O));
         execute('bind-to-key -r gui_replace 'event2index(C_H));
      } else {
         execute('bind-to-key -r / 'event2index(C_F));
         execute('bind-to-key -r edit 'event2index(C_O));
         execute('bind-to-key -r c 'event2index(C_H));
      }
      break;
   }
   update_emulation_profiles();
   return(0);
}
