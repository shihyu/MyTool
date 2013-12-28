////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47630 $
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
#include "vsevents.sh"
#import "complete.e"
#import "stdprocs.e"
#import "util.e"
#endregion


/** 
 * Defines an alternate CTRL key.  For example, after binding this 
 * command to the Ctrl+^ key, pressing Ctrl+^ 'x' is identical to Ctrl+X.
 * 
 * @see alt_prefix
 * @see shift_prefix
 * @see esc_alt_prefix
 * @categories Keyboard_Functions
 */
_command ctrl_prefix(...) name_info(','VSARG2_EDITORCTL|VSARG2_TEXT_BOX)
{
   //prev_name=name_name(prev_index('','C'))
   //prev_name2=name_name(prev_index())
   _macro_delete_line();
   typeless m=last_index('','p');
   if ( arg(1)!='' ) {
      //last_index(prev_index())
      //last_index(prev_index('','C'),'C')
      m=arg(3);
   }
   _str s=m;
   if ( length(m)>0 ) {
      s=s:+' ';
   }
   delay((int)get_event('d')*10,'k');
   if( !_IsKeyPending(true,true) ) {
      message(s:+'<Ctrl>');
   }

   _str key=get_event('nu'arg(4));
   key=xlat_prefix_key(arg(4),key,'',m:+'<Ctrl>',arg(5));
   if ( iscancel(key) || key:=='' ) {
      if ( arg(1)=='' ) { cancel(); } else { clear_message(); };
      return '';
   }
   last_index(prev_index());
   last_index(prev_index('','C'),'C');
   int index=event2index(key);
   index=index|VSEVFLAG_CTRL;
   key=index2event(index);
   //messageNwait('kt='name_name(last_index('','k'))' ln='name_name(last_index())' lnc='name_name(last_index('','C'))' pn='prev_name' pn2='prev_name2); */
   if ( arg(1)=='' ) {
      _macro('m',_macro());
      call_key(key,m);   /* Continue last key sequence */
   } else {
      clear_message();
   }
   //message 'last='name_name(last_index('','C'))' pn='prev_name' pn2='prev_name2
   return(key);

}
/**
 * Defines an alternative SHIFT key.  For example, after binding this 
 * command to the '~' key, pressing '~' F1 is identical to Shift+F1.
 * 
 * @see ctrl_prefix
 * @see alt_prefix
 * @see esc_alt_prefix
 * 
 * @categories Keyboard_Functions
 * 
 */ 
_command shift_prefix(...) name_info(','VSARG2_EDITORCTL|VSARG2_TEXT_BOX)
{
   _macro_delete_line();
   typeless m=last_index('','p');
   if ( arg(1)!='' ) {
      //last_index(prev_index())
      m=arg(3);
   }
   _str s=m;
   if ( length(m)>0 ) {
      s=s:+' ';
   }
   delay((int)get_event('d')*10,'k');
   if( !_IsKeyPending(true,true) ) {
      message(s:+'<Shift>');
   }

   _str key=get_event('n'arg(4));
   key=xlat_prefix_key(arg(4),key,'',m:+'<Shift>',arg(5));
   if ( iscancel(key) || key:=='' ) {
      if ( arg(1)=='' ) { cancel(); } else { clear_message(); }
      return '';
   }
   last_index(prev_index());
   last_index(prev_index('','C'),'C');
   int index=event2index(key);
   index=index|VSEVFLAG_SHIFT;
   key=index2event(index);
   //say('name='event2name(key));
   if ( arg(1)=='' ) {
      _macro('m',_macro());
      call_key(key,m);   /* Continue last key sequence */
   } else {
      clear_message();
   }
   return(key);

}
/**
 * Defines an Alt prefix key.  For example, after binding this command to 
 * the F1 key, pressing F1 'x' is identical to Alt+X.
 * 
 * @return 
 * @see shift_prefix
 * @see ctrl_prefix
 * @see esc_alt_prefix
 * @categories Keyboard_Functions
 */
_command alt_prefix(...) name_info(','VSARG2_EDITORCTL|VSARG2_TEXT_BOX)
{
   _macro_delete_line();
   typeless m=last_index('','p');
   if ( arg(1)!='' ) {
      //last_index(prev_index())
      m=arg(3);
   }
   if ( length(m)>0 ) {
      m=m:+' ';
   }
   delay((int)get_event('d')*10,'k');
   if( !_IsKeyPending(true,true) ) {
      message(m:+'<Alt>');
   }

   _str key=get_event('nu'arg(4));
   if ( iscancel(key) || key:=='' ) {
      if ( arg(1)=='' ) { cancel(); } else { clear_message(); }
      return '';
   }
   last_index(prev_index());
   last_index(prev_index('','C'),'C');
   key=xlat_prefix_key(arg(4),key,'',m:+'<Alt>',arg(5));
   int index=event2index(key);
   index=index|VSEVFLAG_ALT;
   key=index2event(index);
   if ( arg(1)=='' ) {
      _macro('m',_macro());
      call_key(key,m);   /* Continue last key sequence */
   } else {
      clear_message();
   }
   return(key);

}
_str
   _key
   ,_pgetkey;

/**
 * This function performs a normal <b>get_event</b> and 
 * translates the <b>alt_prefix</b>, 
 * <b>ctrl_prefix</b>, and <b>case_indirect</b> key bindings into the 
 * appropriate key.  The translated key is returned and the global variable 
 * _key is set to the returned key value.</p>
 * 
 * @param get_flags  Used as first parameter passed to 
 * <b>get_event</b> built-in.  See <b>get_event</b> 
 * built-in for description of first parameter.  Defaults 
 * to ''.
 * 
 * @param root_keys  Name table index of root event table.  
 * Defaults to index of "root_keys" event table.
 * 
 * @param mode_keys  index of mode specific event table.
 * 
 * @see get_event
 * @categories Keyboard_Functions
 */
_str pgetkey(...)
{
   typeless root='';
   typeless mode='';
   _str name='';
   for (;;) {
      _key=get_event(arg(1));
      if ( arg(2)!='' ) {  /* Use root and mode keys? */
         root=arg(2);
         mode=arg(3);
      } else {
         mode=root=_default_keys;
      }
      name=name_name(eventtab_index(root,mode,event2index(_key)));
      if ( name=='alt-prefix' || name=='esc-alt-prefix' ) {
         if ( iscancel(_key) && _pgetkey!='') {
            return(_key);
         }
         _key=alt_prefix('1','',arg(4),arg(1),arg(5));
      } else if ( name=='ctrl-prefix' ) {
         _key=ctrl_prefix('1','',arg(4),arg(1),arg(5));
      } else if ( name=='shift-prefix' ) {
         _key=shift_prefix('1','',arg(4),arg(1),arg(5));
      } else if ( name=='case-indirect' && arg(5) ) {
         _key=case_indirect(_key);
      }
      if ( _key:!='' ) {
         return(_key);
      }
   }

}
static _str xlat_prefix_key(...)
{
   _str key=arg(2);
   _str name=name_on_key(key);
   if ( name=='alt-prefix' || name=='esc-alt-prefix' ) {
      key=alt_prefix('1','',arg(4),arg(1),arg(5));
   } else if ( name=='ctrl-prefix' ) {
      key=ctrl_prefix('1','',arg(4),arg(1),arg(5));
   } else if ( name=='shift-prefix' ) {
      key=shift_prefix('1','',arg(4),arg(1),arg(5));
   } else if ( name=='case-indirect' && arg(5) ) {
      key=case_indirect(key);
   }
   if ( key:!='' ) {
      return(key);
   }
   return(key);

}

/** 
 * Defines an alternative ALT key and defines a completion/enter argument
 * key.  For example, after binding this command to the ESC key, pressing
 * ESC 'x' is identical to Alt+X when the cursor is in the text area.
 * When the cursor is on the command line pressing the ESC key will
 * complete argument at the cursor.  If a unique argument is found, it is
 * returned as if the ENTER key was pressed.
 * 
 * @see shift_prefix
 * @see ctrl_prefix
 * @see alt_prefix
 * @categories Keyboard_Functions
 */
_command esc_alt_prefix(_str completion_info='') name_info(','VSARG2_EDITORCTL|VSARG2_CMDLINE)
{
   if ( ! command_state() ) {

      // Whole-saled from cmdline_toggle() to handle hitting Ctrl+g to dismiss
      // a dialog.
      if (!p_mdi_child && !p_DockingArea && p_object==OI_EDITOR) {
         if (last_event():==ESC || last_event():==A_F4 ) {
            call_event(defeventtab _ainh_dlg_manager,last_event(),'e');
         }
      }

      _macro('m',_macro());
      return(alt_prefix());
   }
   _str junk='';
   int col=0;
   get_command(junk,col);
   if ( completion_info=='' ) {
      maybe_complete();
   } else {
      maybe_complete(completion_info);
   }
   int new_col=0;
   get_command(junk,new_col);
   if ( new_col>col && new_col>length(junk)+1 ) {
      if ( completion_info=='' ) {
         return(nosplit_insert_line());
      }
      return '';
   }
   return 0;
}
