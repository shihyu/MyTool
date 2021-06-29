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

_str def_alt_menu=0;

defmain()
{
   if ( arg(1)=='' ) {
     command_put('altsetup 'number2yesno(def_alt_menu));
     return(1);
   }
   new_alt_menu := false;
   status := setyesno(new_alt_menu,arg(1));
   if ( status ) {
      return(1);
   }
   def_alt_menu=new_alt_menu;
   _config_modify_flags(CFGMODIFY_DEFVAR|CFGMODIFY_KEYS);
   // Nothing to do for windows emulation
   if ( def_alt_menu ) {
      set_eventtab_index(_default_keys,event2index(A_F),0);
      set_eventtab_index(_default_keys,event2index(name2event('M-F')),0);
      set_eventtab_index(_default_keys,event2index(A_E),0);
      set_eventtab_index(_default_keys,event2index(name2event('M-E')),0);
      set_eventtab_index(_default_keys,event2index(A_S),0);
      set_eventtab_index(_default_keys,event2index(name2event('M-S')),0);
      if (def_keys=="") {
         set_eventtab_index(_default_keys,event2index(A_I),0);
         set_eventtab_index(_default_keys,event2index(name2event('M-I')),0);
      } else {
         set_eventtab_index(_default_keys,event2index(A_V),0);
         set_eventtab_index(_default_keys,event2index(name2event('M-V')),0);
      }
      set_eventtab_index(_default_keys,event2index(A_P),0);
      set_eventtab_index(_default_keys,event2index(name2event('M-P')),0);
#if USE_B_FOR_BUILD
      set_eventtab_index(_default_keys,event2index(A_B),0);
      set_eventtab_index(_default_keys,event2index(name2event('M-B')),0);
#endif
      set_eventtab_index(_default_keys,event2index(A_D),0);
      set_eventtab_index(_default_keys,event2index(name2event('M-D')),0);
      set_eventtab_index(_default_keys,event2index(A_C),0);
      set_eventtab_index(_default_keys,event2index(name2event('M-C')),0);
      set_eventtab_index(_default_keys,event2index(A_M),0);
      set_eventtab_index(_default_keys,event2index(name2event('M-M')),0);
#if USE_T_FOR_TOOLS
      set_eventtab_index(_default_keys,event2index(A_T),0);
      set_eventtab_index(_default_keys,event2index(name2event('M-T')),0);
#else
      if (def_keys=="windows-keys") {
         set_eventtab_index(_default_keys,event2index(A_T),0);
         set_eventtab_index(_default_keys,event2index(name2event('M-T')),0);
      } else {
         set_eventtab_index(_default_keys,event2index(A_O),0);
         set_eventtab_index(_default_keys,event2index(name2event('M-O')),0);
      }
#endif
      set_eventtab_index(_default_keys,event2index(A_W),0);
      set_eventtab_index(_default_keys,event2index(name2event('M-W')),0);
      set_eventtab_index(_default_keys,event2index(A_H),0);
      set_eventtab_index(_default_keys,event2index(name2event('M-H')),0);
   } else if ( def_keys=='windows-keys' ) {
      execute('bind-to-key -r gui-find 'event2index(name2event('M-F')),"");
      execute('bind-to-key -r set-find 'event2index(name2event('M-E')),"");
      execute('bind-to-key -r save 'event2index(name2event('M-S')),"");
      execute('bind-to-key -r paste 'event2index(name2event('M-V')),"");
      execute('bind-to-key -r gui-print 'event2index(name2event('M-P')),"");
      execute('bind-to-key -r copy-to-clipboard 'event2index(name2event('M-C')),"");
      execute('bind-to-key -r iconize-window 'event2index(name2event('M-M')),"");
      execute('bind-to-key -r macos-font-config 'event2index(name2event('M-T')),"");
      execute('bind-to-key -r close-window 'event2index(name2event('M-W')),"");
   } else if ( def_keys=='brief-keys' ) {
      execute('bind-to-key -r fill-selection 'event2index(A_F),"");
      execute('bind-to-key -r fill-selection 'event2index(name2event('M-F')),"");
      if (def_gui) {
         execute('bind-to-key -r gui_find 'event2index(A_S),"");
         execute('bind-to-key -r gui_find 'event2index(name2event('M-S')),"");
         execute('bind-to-key -r gui_open 'event2index(A_E),"");
         execute('bind-to-key -r gui_open 'event2index(name2event('M-E')),"");
      } else {
         execute('bind-to-key -r search-forward 'event2index(A_S),"");
         execute('bind-to-key -r search-forward 'event2index(name2event('M-S')),"");
         execute('bind-to-key -r edit 'event2index(A_E),"");
         execute('bind-to-key -r edit 'event2index(name2event('M-E')),"");
      }
      execute('bind-to-key -r version 'event2index(A_V),"");
      execute('bind-to-key -r version 'event2index(name2event('M-V')),"");
      execute('bind-to-key -r print_selection 'event2index(A_P),"");
      execute('bind-to-key -r print_selection 'event2index(name2event('M-P')),"");
#if USE_B_FOR_BUILD
      execute('bind-to-key -r list_buffers 'event2index(A_B),"");
      execute('bind-to-key -r list_buffers 'event2index(name2event('M-B')),"");
#endif
      execute('bind-to-key -r delete-line 'event2index(A_D),"");
      execute('bind-to-key -r delete-line 'event2index(name2event('M-D')),"");
      execute('bind-to-key -r brief_select_block 'event2index(A_C),"");
      execute('bind-to-key -r brief_select_block 'event2index(name2event('M-C')),"");
      execute('bind-to-key -r brief-iselect-char 'event2index(A_M),"");
      execute('bind-to-key -r brief-iselect-char 'event2index(name2event('M-M')),"");
      execute('bind-to-key -r brief-save 'event2index(A_W),"");
      execute('bind-to-key -r brief-save 'event2index(name2event('M-W')),"");
#if USE_T_FOR_TOOLS
      execute('bind-to-key -r translate_forward 'event2index(A_T),"");
      execute('bind-to-key -r translate_forward 'event2index(name2event('M-T')),"");
#else
      execute('bind-to-key -r name 'event2index(A_O),"");
      execute('bind-to-key -r name 'event2index(name2event('M-O')),"");
#endif
      execute('bind-to-key -r help 'event2index(A_H),"");
      execute('bind-to-key -r help 'event2index(name2event('M-H')),"");
   } else if ( def_keys=='emacs-keys' ) {
      execute('bind-to-key -r next_word 'event2index(A_F),"");
      execute('bind-to-key -r next_word 'event2index(name2event('M-F')),"");
      execute('bind-to-key -r next_sentence 'event2index(A_E),"");
      execute('bind-to-key -r next_sentence 'event2index(name2event('M-E')),"");
      execute('bind-to-key -r center_within_margins 'event2index(A_S),"");
      execute('bind-to-key -r center_within_margins 'event2index(name2event('M-S')),"");
      execute('bind-to-key -r page_up 'event2index(A_V),"");
      execute('bind-to-key -r page_up 'event2index(name2event('M-V')),"");
      execute('bind-to-key -r config 'event2index(A_P),"");
      execute('bind-to-key -r config 'event2index(name2event('M-P')),"");
#if USE_B_FOR_BUILD
      execute('bind-to-key -r prev_word 'event2index(A_B),"");
      execute('bind-to-key -r prev_word 'event2index(name2event('M-B')),"");
#endif
      execute('bind-to-key -r cut_word 'event2index(A_D),"");
      execute('bind-to-key -r cut_word 'event2index(name2event('M-D')),"");
      execute('bind-to-key -r cap_word 'event2index(A_C),"");
      execute('bind-to-key -r cap_word 'event2index(name2event('M-C')),"");
      execute('bind-to-key -r first_non_blank 'event2index(A_M),"");
      execute('bind-to-key -r first_non_blank 'event2index(name2event('M-M')),"");
      execute('bind-to-key -r copy_region 'event2index(A_W),"");
      execute('bind-to-key -r copy_region 'event2index(name2event('M-W')),"");
#if USE_T_FOR_TOOLS
      execute('bind-to-key -r transpose_words 'event2index(A_T),"");
      execute('bind-to-key -r transpose_words 'event2index(name2event('M-T')),"");
#else
      execute('bind-to-key -r overlay_block_selection 'event2index(A_O),"");
      execute('bind-to-key -r overlay_block_selection 'event2index(name2event('M-O')),"");
#endif
      execute('bind-to-key -r select_paragraph 'event2index(A_H),"");
      execute('bind-to-key -r select_paragraph 'event2index(name2event('M-H')),"");
   } else if ( def_keys=='gnuemacs-keys' ) {
      execute('bind-to-key -r next_word 'event2index(A_F),"");
      execute('bind-to-key -r next_word 'event2index(name2event('M-F')),"");
      execute('bind-to-key -r next_sentence 'event2index(A_E),"");
      execute('bind-to-key -r next_sentence 'event2index(name2event('M-E')),"");
      execute('bind-to-key -r center_paragraph 'event2index(A_S),"");
      execute('bind-to-key -r center_paragraph 'event2index(name2event('M-S')),"");
      execute('bind-to-key -r emacs_scroll_down 'event2index(A_V),"");
      execute('bind-to-key -r emacs_scroll_down 'event2index(name2event('M-V')),"");
      execute('bind-to-key -r config 'event2index(A_P),"");
      execute('bind-to-key -r config 'event2index(name2event('M-P')),"");
#if USE_B_FOR_BUILD
      execute('bind-to-key -r prev_word 'event2index(A_B),"");
      execute('bind-to-key -r prev_word 'event2index(name2event('M-B')),"");
#endif
      execute('bind-to-key -r cut_word 'event2index(A_D),"");
      execute('bind-to-key -r cut_word 'event2index(name2event('M-D')),"");
      execute('bind-to-key -r cap_word 'event2index(A_C),"");
      execute('bind-to-key -r cap_word 'event2index(name2event('M-C')),"");
      execute('bind-to-key -r first_non_blank 'event2index(A_M),"");
      execute('bind-to-key -r first_non_blank 'event2index(name2event('M-M')),"");
      execute('bind-to-key -r copy_region 'event2index(A_W),"");
      execute('bind-to-key -r copy_region 'event2index(name2event('M-W')),"");
#if USE_T_FOR_TOOLS
      execute('bind-to-key -r transpose_words 'event2index(A_T),"");
      execute('bind-to-key -r transpose_words 'event2index(name2event('M-T')),"");
#else
      execute('bind-to-key -r overlay_block_selection 'event2index(A_O),"");
      execute('bind-to-key -r overlay_block_selection 'event2index(name2event('M-O')),"");
#endif
      execute('bind-to-key -r select_paragraph 'event2index(A_H),"");
      execute('bind-to-key -r select_paragraph 'event2index(name2event('M-H')),"");
   } else if(def_keys==''){ /* SlickEdit emulation */
      execute('bind-to-key -r fill_selection 'event2index(A_F),"");
      execute('bind-to-key -r fill_selection 'event2index(name2event('M-F')),"");
      execute('bind-to-key -r end_select 'event2index(A_E),"");
      execute('bind-to-key -r end_select 'event2index(name2event('M-E')),"");
      execute('bind-to-key -r split_line 'event2index(A_S),"");
      execute('bind-to-key -r split_line 'event2index(name2event('M-S')),"");
      execute('bind-to-key -r reflow_paragraph 'event2index(A_P),"");
      execute('bind-to-key -r reflow_paragraph 'event2index(name2event('M-P')),"");
#if USE_B_FOR_BUILD
      execute('bind-to-key -r select_block 'event2index(A_B),"");
      execute('bind-to-key -r select_block 'event2index(name2event('M-B')),"");
#endif
      /* 'bind-to-key -r  'event2index(A_D)  */
      execute('bind-to-key -r copy_to_cursor 'event2index(A_C),"");
      execute('bind-to-key -r copy_to_cursor 'event2index(name2event('M-C')),"");
      execute('bind-to-key -r move_to_cursor 'event2index(A_M),"");
      execute('bind-to-key -r move_to_cursor 'event2index(name2event('M-M')),"");
      execute('bind-to-key -r cut_word 'event2index(A_W),"");
      execute('bind-to-key -r cut_word 'event2index(name2event('M-W')),"");
#if USE_T_FOR_TOOLS
      execute('bind-to-key -r find_matching_paren 'event2index(A_T));
      execute('bind-to-key -r find_matching_paren 'event2index(name2event('M-T')),"");
#else
      execute('bind-to-key -r overlay_block_selection 'event2index(A_O));
      execute('bind-to-key -r overlay_block_selection 'event2index(name2event('M-O')),"");
#endif
      /* 'bind-to-key -r  'event2index(A_H) */
   }
   update_emulation_profiles();
   return(0);
}
