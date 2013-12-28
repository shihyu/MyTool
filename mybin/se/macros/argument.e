////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#import "main.e"
#import "prefix.e"
#import "recmacro.e"
#import "stdprocs.e"
#endregion

/**
 * Prompts you for a repeat count and executes the next key you press
 * the number of times specified.  The following keys have special meaning
 * while being prompted for the repeat count:
 * <DL compact style="margin-left:20pt;">
 * <dt>0..9</dt><dd>Appends one of the digits 0..9 to the counter.</dd>
 * <dt>Alt+0..Alt+9 </dt><dd>EMACS emulation only.  Appends one of the digits 0..9 to the counter.</dd>
 * <dt>-, Alt+Minus </dt> <dd>Toggles the repeat count from positive to negative.</dd>
 * </dl>
 * Pressing the key bound to the <b>argument</b> command while being prompted for
 * the repeat count multiplies the repeat count by 4.
 * 
 * The global variable "_argument" is set to the repeat count given before
 * the command is executed.  The command invoked may test the value of this
 * variable and set it to '' when finished processing the argument to do
 * some special processing when executed with a repeat count.
 * 
 * @appliesTo Edit_Window
 * @categories Keyboard_Functions
 */
_command void argument(...) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_CMDLINE)
{
   _macro_delete_line();
   cursor_data();
   _cmdline.p_visible=1;
   _argument='';
   typeless defaultn=arg(1);
   if ( defaultn=='' ) {
      defaultn='4';
   }else{
      _argument=defaultn;
      defaultn='';
   }
   _str sign=arg(3);
   _str text='';
   _str k='';
   _str number='';
   for (;;) {
      text=sign:+_argument:+defaultn;
      _cmdline.set_command(text,length(text),length(text),'Argument: ');
      k=pgetkey();
      if ( isdigit(k) ) {
         _argument=_argument:+k;
         defaultn='';
      } else if ( k:=='-' || k==PAD_MINUS || k:==A_MINUS || k==name2event('a-pad-minus') ) {
         if ( sign=='' ) {
            sign='-';
         } else {
            sign='';
         }
      } else if ( name_on_key(k)=='alt-argument' ) {
         parse event2name(k) with 'A-' number;
         _argument=_argument:+number;
         defaultn='';
      } else if ( name_on_key(k)=='argument' ) {
         if ( _argument=='' ) {
            defaultn=defaultn*4;
         } else {
            defaultn=_argument*4;
         }
         _argument='';
      } else if ( iscancel(k) ) {
         cancel();
         _cmdline.set_command('',1,1,'');
         return;
      } else {
         break;
      }
   }
   if ( _argument=='' ) {
      _argument=defaultn;
   }
   _argument=sign:+_argument;
   _cmdline.set_command('',1,1,'');
   typeless keytab_used=0;
   _str keyname='';
   typeless status=prompt_for_key(_argument' ',keytab_used,k,keyname,'','1');
   if ( status ) {
      return;
   }
   int index=eventtab_index(keytab_used,keytab_used,event2index(k));
   typeless info=name_info(index);
   typeless arg2info='';
   parse info with ',' arg2info;
   if (_QReadOnly() && //The file is read_only
       (info=='' //Was just a key press
        || !(arg2info & VSARG2_READ_ONLY) //The command is allowed in read_only mode
        || upcase(event2name(k)):=='ENTER') //The key was ENTER
       ) {
      //The command isn't allowed in Read-only mode.
      _message_box('This command is not allowed in read only mode.');
      return;
   }
   _str param='';
   _str key='';
   int i=0;
   if ( index ) {
      param='';
      if (name_name(index)=='quote-key') {
         message(nls('Type a key'));
         key=get_event();
         clear_message();
         key=key2ascii(key);
         if ( length(key)>1 ) {
            param=last_event();
         } else {
            param=key;
         }
      }
      if ( name_name(index)=='cut-end-line' ) {
         _argument=_argument*2;
      }
      parse name_info(index) with ',' info;
      if (info!='' && (info & VSARG2_LASTKEY)) {
         _macro_append('last_event(name2event('_quote(event2name(k))'));');
      }
      _macro_append('old_argument=_argument');
      _macro_append('_argument='_argument";");
      if ( _argument<0 ) {
         _macro_call(stranslate(name_name(index),'_','-'));
         _macro_append('_argument="";');
         call_index(index);
         /* prev_index(index) */
      } else {
         _macro_append('for (i=1; i<=_argument ; ++i) {');
         if (name_name(index)=='quote-key') {
            _macro_call('   keyin',param);
         } else {
            _macro_call('   'stranslate(name_name(index),'_','-'));
         }
         _macro_append('   '"if ( _argument=='' ) break;  /* Command process argument? */");
         _macro_append('}');
         //_macro_append('_argument="";')
         _macro_append('_argument=old_argument');
         //isnormal=isnormal_char(k) && keytab_used==_default_keys;
         last_event(k);
         for (i=1; i<=_argument ; ++i) {
            /*if (isnormal) {
               keyin(k);
            } else*/ {
               if (name_name(index)=='quote-key') {
                  keyin(param);
               } else {
                  call_index(index);
               }
            }
            /* prev_index(index) */
            if ( _argument=='' ) break;  /* Command process argument? */
         }
      }
      last_index(index);
   } else if ( length(k)==1 && keytab_used==_default_keys ) {
      _macro_append('old_argument=_argument');
      _macro_append('_argument='_argument";");
      _macro_call('last_event',k);
      _macro_append('for (i=1; i<=_argument ; ++i) call_key(name2event('_quote(k)'));');
      //_macro_append('_argument="";')
      _macro_append('_argument=old_argument');
      _macro('m',0);
      for (i=1; i<=_argument ; ++i) {
         call_key(k);
      }
   }
   _argument='';
}
/**
 * This command may only be bound to the keys Alt+0..Alt+9.  This command 
 * calls the <b>argument</b> command with a default count of 0 for Alt+0, 1 for 
 * Alt+1 ..., 9 for Alt+9.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * @categories Keyboard_Functions, Miscellaneous_Functions
 */
_command void alt_argument() name_info(','VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   _macro('m',_macro());
   _str number='';
   parse event2name(last_event()) with 'A-' number;
   if ( number=='-' || number=='PAD-MINUS' ) {
      argument('','','-');
      return;
   }
   argument(number);
}
