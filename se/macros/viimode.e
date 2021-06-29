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
#import "alias.e"
#import "complete.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "vi.e"
#import "vicmode.e"
#endregion


_str _vi_insertion_pos;
_str def_vi_chars;
_str def_vi_chars2;


/**
 * Not supported.
 * <P>
 * By default this command handles 'C-U' pressed.
 */
_command int vi_restart_insertion() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if ( command_state() && length(last_event()):==1 ) {
      keyin(last_event());
      return(0);
   }
#if 1
   vi_message('Not supported in this release');
#else
   old_mark=_duplicate_selection('');
   if ( _vi_insertion_pos=='' ) {
      vi_message('No insertion information available');
      return(1);
   }
   parse value _vi_insertion_pos with line col;
   mark=_alloc_selection();
   if ( mark<0 ) {
      vi_message(get_message(mark));
      return(1);
   }
   _select_char(mark,'NP');
   if ( p_line==line ) {
      p_col=col;
   } else {
      p_col=1;
   }
   _select_char(mark,'NP');
   _delete_selection(mark);
   _show_selection(old_mark);
   _free_selection(mark);

   // Set new insertion position
   _vi_insertion_pos= p_line' 'p_col;
#endif

   return(0);
}

/**
 * By default this command handles 'C-@' pressed.
 */
_command int vi_repeat_last_insert() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if ( command_state() ) {
      _str key=last_event();
      if ( length(key):==1 && isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   status := 0;
   if( vi_repeat_info('I') ) {
      // Abort the keyboard macro recording started by going into insert-mode
      vi_repeat_info('A');
   }
   vi_switch_mode('I');
   status=vi_repeat_info('Z2');

   return(status);
}

/**
 * By default this command handles 'C-W' pressed.
 */
_command int vi_restart_word() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if ( command_state() ) {
      _str key=last_event();
      if ( length(key):==1 && isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      vi_message(get_message(mark));
      return(1);
   }
   if ( p_line==1 && p_col==1 ) {
      vi_message('At beginning of file');
      return(1);
   }
   typeless p1;
   save_pos(p1);
   vi_prev_word2();
   save_pos(auto p2);
   _select_char(mark,'NP');
   restore_pos(p1);
   _select_char(mark,'NP');
   _delete_selection(mark);
   restore_pos(p2);
   _free_selection(mark);

   return(0);
}

/**
 * By default this handles SPACE pressed.
 * <P>
 * This is not bound to any key.
 */
_command int vi_space () name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   key := "";
   if ( command_state() ) {
      key=last_event();
      if ( key:==' ' ) {
         maybe_complete();
      } else if ( length(key):==1 && isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   last_idx := last_index();
   key=last_event();
   dummy_col := 0;
   _str word=cur_word(dummy_col);
   // Clear possible "No word at cursor" message
   clear_message();
   if ( word=='' ) {
      if ( length(key):==1 && isnormal_char(key) ) {
         keyin(key);
      }
   } else {
      if (alias_find(strip(word))) {
         expand_alias();
      } else {
         _str name=vi_name_on_key(key);
         if ( name_name(last_idx)!=name ) {
            call_event(p_active_form,key);
         } else if ( length(key):==1 && isnormal_char(key) ) {
            keyin(key);
         }
      }
   }

   return(0);
}

// This procedure handles 'C-T', 'C-D' pressed in insert mode.
static int shift_text(typeless option,...)
{
   typeless count=arg(2);
   if( !isinteger(count) || count<1 ) {
      count=1;
   }

   typeless shiftwidth=def_vi_or_ex_shiftwidth;
   if( !isinteger(shiftwidth) || shiftwidth<1 ) {
      // This is the real vi default value
      shiftwidth=VI_DEFAULT_SHIFTWIDTH;
   }

   // Now shift the text
   //
   // Start on the line above so the FOR loop works correctly
   up();
   int i;
   typeless shift_amount=0;
   typeless lead_indent=0;
   dcount := 0;
   for( i=1;i<=count;++i ) {
      down();
      if( !_line_length() ) continue;
      _first_non_blank();
      if( option:=='-' ) {
         // Shifting left
         shift_amount=shiftwidth;
         if( shiftwidth>(p_col-1) ) {
            shift_amount=p_col-1;
         }
         if( p_col>1 ) {
            lead_indent=_expand_tabsc(1,p_col-shift_amount-1,'S');
            dcount=p_col-1;
            _begin_line();
            // Strip leading spaces
            _delete_text(dcount,'C');
            _insert_text(lead_indent);
         }
      } else {
         // Shifting right
         if( (_text_colc()+shiftwidth) > MAX_LINE ) {
            vi_message('This line cannot be shifted because it would exceed the line length limit!');
            return(1);
         }
         _first_non_blank();
         // The new indent
         lead_indent=indent_string(shiftwidth+p_col-1);
         dcount=p_col-1;
         _begin_line();
         // Strip leading spaces
         _delete_text(dcount,'C');
         _insert_text(lead_indent);
      }
   }
   up(count-1);
   _first_non_blank();

   return(0);
}

/**
 * By default this handles 'C-T' pressed.
 */
_command int vi_ptab(...) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if ( command_state() ) {
      _str key=last_event();
      if ( length(key):==1 && isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   if( arg(1)=='-' ) {
      //move_text_backtab();
      shift_text('-');
   } else {
      //move_text_tab();
      shift_text('');
   }

   return(0);
}

/**
 * By default this handles 'C-D' pressed.
 */
_command int vi_pbacktab() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   return(vi_ptab('-'));
}

/**
 * By default this handles TAB pressed.
 */
_command int vi_move_text_tab() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL)
{
   // Save this so we can change it back
   int old_indent_style=p_indent_style;

   // Must set this to INDENT_NONE so that ptab() ends up using
   // the tab settings instead of the syntax indent.
   p_indent_style=INDENT_NONE;

   move_text_tab();
   p_indent_style=old_indent_style;   // QUICK!!! Change it back

   return(0);
}

