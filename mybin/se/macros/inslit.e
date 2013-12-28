////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49237 $
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
#import "clipbd.e"
#import "cua.e"
#import "math.e"
#import "recmacro.e"
#import "stdprocs.e"
#import "util.e"
#endregion


   _text_box _inslit

   _text_box _inslitchar

   _radio_button _inslitdec
   _radio_button _inslithex
   _radio_button _inslitasc
   _spin _inslitspin

  static _str _ignore_change=0;

/**
 * Inserts a character you choose into the current buffer.  The <b>Insert 
 * Literal dialog box</b> is displayed which allows you to enter the character 
 * in decimal, hexadecimal, or ASCII.
 * 
 * @return Returns 0 if a character was inserted.
 * 
 * @see keyin
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command void insert_literal(_str result='') name_info(','VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   if (result:=='') {
      _macro_delete_line();
      result=show('_inslit_form -modal');
      if (result:=='') {
         return;
      }
      _macro('m',_macro('s'));
      _macro_call('insert_literal',result);
   }

   if (!doBlockModeKey(result,result,true)) {
      maybe_delete_selection();
      _insert_text(result);
   }
}
#define INSLIT_UNICODE_FORM  "_inslit_unicode_form"
static boolean insertingUnicode(){
   return(p_active_form.p_name:==INSLIT_UNICODE_FORM);
}
defeventtab _inslit_form;
/**
 * 
 * Displays the Insert Literal dialog box.
 * 
 * @return Returns '' if the user cancelled.  Otherwise, a 1 character 
 * length string is returned.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_inslit.on_create(boolean force_unicode=false)
{
   int wid;
   wid=_form_parent();
   if (!wid || !wid._isEditorCtl(false)) {
      wid=0;
   }
   if ((wid && wid.p_UTF8) || force_unicode) {
      // Change name of form so Unicode retrieve settings are different
      p_active_form.p_name=INSLIT_UNICODE_FORM;
      _inslitchar._use_source_window_font(CFG_UNICODE_SOURCE_WINDOW);
      _inslithex.p_value=1;
      _inslitspin.p_max=MAXINT;
   } else {
      _inslitchar._use_source_window_font(CFG_SBCS_DBCS_SOURCE_WINDOW);
   }
   _inslit.set_command(0,1,2);
   _retrieve_prev_form();
   set_format();
}
_inslit.on_change()
{
   if (_ignore_change) return('');
   _str text=lowcase(p_text);
   if ((text=='x' || text=='0x') && !_inslitasc.p_value) {
      _inslitdec.p_user='h';
      _inslithex.p_value=1;
   }
   _str new_char='';
   if (_inslitdec.p_value) {
      if (isinteger(p_text) && p_text<=_inslitspin.p_max && p_text>=0) {
         if (insertingUnicode()) {
            new_char=_UTF8Chr((int)p_text);
         } else {
            new_char = _MultiByteToUTF8(_chr((int)p_text));
         }
      }
   } else if (_inslithex.p_value) {
      typeless dec=hex2dec(p_text);
      if (dec!='') {
         if (insertingUnicode()) {
            new_char=_UTF8Chr(dec);
         } else {
            new_char = _MultiByteToUTF8(_chr(dec));
         }
         //new_char=_UTF8Chr(dec);
      }
   } else {
      if (_UTF8()) {
         int charLen=0;
         _strBeginChar(p_text,1,charLen,false);
         if (length(p_text)==charLen) {
            new_char=p_text;
         } else if (length(p_text)>charLen) {
            int charLen2=0;
            _strBeginChar(p_text,charLen+1,charLen2,false);
            new_char=substr(p_text,charLen+1,charLen2);
            _ignore_change=1;
            _inslit.set_command(new_char,length(new_char)+1);
            _ignore_change=0;
         }
      } else {
         if (length(p_text)==1) {
            new_char=p_text;
         } else if (length(p_text)>1) {
            new_char=last_char(p_text);
            _ignore_change=1;
            _inslit.set_command(new_char,length(new_char)+1);
            _ignore_change=0;
         }
      }
   }
   _inslitchar.p_ReadOnly=0;
   _inslitchar.p_text=new_char;
   _inslitchar.p_ReadOnly=1;
}
_inslitok.lbutton_up()
{
   if(data_not_valid()) {
      p_window_id=_inslit;
      _beep();
      return('');
   }
   typeless new_char=_inslit.p_text;
   if (_inslitdec.p_value) {
      //new_char=_UTF8Chr(new_char);
      if (insertingUnicode()) {
         new_char=_UTF8Chr(new_char);
      } else {
         new_char = _MultiByteToUTF8(_chr(new_char));
      }
   } else if (_inslithex.p_value) {
      typeless dec=hex2dec(new_char);
      //new_char=_UTF8Chr(dec);
      if (insertingUnicode()) {
         new_char=_UTF8Chr(dec);
      } else {
         new_char = _MultiByteToUTF8(_chr(dec));
      }
   }
   _save_form_response();
   p_active_form._delete_window(new_char);
}
_inslitdec.on_got_focus()
{
   if(data_not_valid()) {
      p_value=1;
      set_format();
      _beep();
      return('');
   }
   _str old_format=_inslitdec.p_user;
   typeless text=_inslit.p_text;
   typeless dec='';
   switch (old_format) {
   case 'h':
      dec=hex2dec(text);
      break;
   case 'a':
      if (insertingUnicode()) {
         dec=_UTF8Asc(text);
      } else {
         dec=_asc(_UTF8ToMultiByte(text));
         //say('len='length(text)' '_UTF8ToMultiByte(text)' dec='dec' u='_UTF8Asc(text));
      }
      break;
   default:
      dec=text;
   }
   p_value=1;
   if (_inslitasc.p_value) {
      if (insertingUnicode()) {
         _inslit.p_text=_UTF8Chr(dec);
      } else {
         //say('len 'dec' chr='_chr(dec)' 'length(_UTF8ToMultiByte(_MultiByteToUTF8(_chr(dec),1252),1252)));
         //say('len 'dec' 'length(_MultiByteToUTF8(_chr(dec),1252)));
         //say('len 'dec' 'length(_MultiByteToUTF8(_chr(dec),1252)));
         _inslit.p_text = _MultiByteToUTF8(_chr(dec));
      }
   } else if (_inslithex.p_value) {
      _inslit.p_text=dec2hex(dec);
   } else {
      _inslit.p_text=dec;
   }
   set_format();
}
static set_format()
{
   _str new_format='';
   if (_inslitasc.p_value) {
      new_format='a';
   } else if (_inslithex.p_value) {
      new_format='h';
   }
   //message 'new format='new_format
   _inslitdec.p_user=new_format;
}
static data_not_valid()
{
   _str old_format=_inslitdec.p_user;
   typeless text=_inslit.p_text;
   typeless dec='';
   switch (old_format) {
   case 'h':
      dec=hex2dec(text);
      if (dec=='') {
         return(1);
      }
      break;
   case 'a':
      if (_UTF8()) {
         int charLen=0;
         _strBeginChar(text,1,charLen,false);
         if (length(text)!=charLen) {
            return(1);
         }
         break;
      }
      if (length(text)!=1) {
         return(1);
      }
      break;
   default:
      if (!(isinteger(text) && text<=_inslitspin.p_max && text>=0)) {
         return(1);
      }
   }
   return(0);
}
_inslitspin.on_change(int reason)
{
   if (reason==CHANGE_NEW_FOCUS) {
      return(_inslit);
   }
}
_inslitspin.on_spin_up(_str direction='')
{
   if(data_not_valid()) {
      _beep();
      return('');
   }
   typeless text=_inslit.p_text;
   typeless dec='';
   if (_inslitdec.p_value) {
      dec=text;
   } else if (_inslithex.p_value) {
      dec=hex2dec(text);
   } else {
      dec=_UTF8Asc(text);
   }
   _inslitchar.p_ReadOnly=0;
   if (direction!='') {
      if (dec>0) {
         _inslitchar.p_text=_chr(--dec);
      }
   } else {
      if (dec<_inslitspin.p_max) {
         _inslitchar.p_text=_chr(++dec);
      }
   }
   _inslitchar.p_ReadOnly=1;
   if (_inslitdec.p_value) {
      text=dec;
   } else if (_inslithex.p_value) {
      text=dec2hex(dec);
   } else {
      text=_UTF8Chr(dec);
   }
   _inslit.set_command(text,1,length(text)+1);
}
_inslitspin.on_spin_down()
{
   call_event('-',p_window_id,ON_SPIN_UP,'');
}
