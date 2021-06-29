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
#import "math.e"
#import "recmacro.e"
#import "seldisp.e"
#import "stdprocs.e"
#endregion

   _radio_button _seekdec
   _radio_button _seekhex
   _control _seektext;

  static _str _ignore_change=0;
  static _str after_startup =0;

/**
 * <p>The <b>gui_seek</b> command displays the current buffer seek position and 
 * allows you to specify a mathematical expression representing a seek position 
 * (see <b>math</b> command for syntax of expression).  A seek position is a 
 * character position relative to the beginning of the file.  The first 
 * character of the file is seek position 0.</p>
 * 
 * <p>If a seek position is given, it cannot be past the end of the file.  
 * Negative seek positions are possible due to SlickEdit's implementation 
 * of line 0.</p>
 * 
 * <p>You may use the <b>gui_seek</b> command to determine the number of 
 * bytes in a file.  However, keep in mind that if your load options are set to 
 * expand tabs when loading, the seek file size will not match the disk file 
 * size.  In addition, for ASCII files, SlickEdit strips the EOF 
 * (character 27) if there is one at the end of the file.</p>
 * 
 * @see seek
 * @see _QROffset
 * @see _GoToROffset
 * @see goto_point
 * @see point
 * @see _nrseek
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Forms, Edit_Window_Methods, Editor_Control_Methods, Miscellaneous_Functions
 */
_command gui_seek() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int was_recording=_macro();
   _macro_delete_line();
   typeless result=show('-modal _seek_form',_QROffset());
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   _macro('m',was_recording);
   _macro_call('seek', result);
   seek(result);
}

defeventtab _seek_form;
/**
 * Displays the Seek dialog box which lets you specify a seek position to go to.
 * 
 * @return Returns '' if dialog box is cancelled.  Otherwise, a decimal seek 
 * position is returned which may be used as input to the seek function.
 * 
 * @example 
 * <pre>
 *     show('-modal _seek_form')
 * </pre>
 */ 
_seektext.on_create(long initial_value=0)
{
   _retrieve_prev_form();
   _seektext.set_command(initial_value,1,length(initial_value)+1);
   set_format();
   if (_seekhex.p_value) {
      _seekhex.call_event(_seekhex,ON_GOT_FOCUS,'W');
   }
}


_seektext.on_change()
{
   if (_ignore_change) return('');
   text := lowcase(p_text);
   if ((substr(text,1,1)=='x' || substr(text,1,2)=='0x')) {
      _seekdec.p_user='h';
      _seekhex.p_value=1;
   }
}


_seekok.lbutton_up()
{
   if(_seekdata_not_valid()) {
      p_window_id = _seektext;
      _beep();
      return('');
   }
   text := _seektext.p_text;
   text=strip(text);
   ch1 := substr(text,1,1);
   typeless result='';
   eval_exp(result,text,10 /* output base */);
   if (ch1=='+') {
      result='+'result;
   }
   //messageNwait('result='result' text='text);
   _save_form_response();
   p_active_form._delete_window(result);
}
_seekdec.on_got_focus()
{
   if(_seekdata_not_valid()) {
      p_value=1;
      set_format();
      _beep();
      return('');
   }
   typeless old_format=_seekdec.p_user;
   text := _seektext.p_text;
   typeless dec='';
   eval_exp(dec,text,10 /* output base */);
#if 0
   switch (old_format) {
   case 'h':
      dec=hex2dec(text);
      break;
   default:
      dec=text;
   }
#endif
   p_value=1;
   if (_seekhex.p_value) {
      _seektext.p_text="0x":+_dec2hex(dec);
   } else {
      _seektext.p_text=dec;
   }
   set_format();
}
static set_format()
{
   new_format := "";
   if (_seekhex.p_value) {
      new_format='h';
   }
   //message 'new format='new_format
   _seekdec.p_user=new_format;
}
static _seekdata_not_valid()
{
   _str old_format=_seekdec.p_user;
   text := _seektext.p_text;
   typeless result='';
   typeless status=eval_exp(result,text,10 /* output base */);
   return(status);
#if 0
   switch (old_format) {
   case 'h':
      dec=hex2dec(text)
      if (dec=='') {
         return(1);
      }
      break;
   default:
      if (!isinteger(text)) {
         return(1);
      }
   }
   return(0);
#endif
}


/**
 * <p>The <b>seek</b> command places the cursor on the seek position 
 * given or displays the current seek position.  A seek position is a 
 * character position relative to the beginning of the file.  The first 
 * character of the file is seek position 0.  If an expression is given, the 
 * cursor is placed on the seek position given.  Otherwise, the current 
 * seek position is displayed in hex and decimal.  Any expression 
 * accepted by the <b>math</b> command may be specified.  See 
 * <b>math</b> command for syntax of expression.</p>
 * 
 * <p>If a seek position is given, it can not be past the end of the file.  
 * Negative seek positions are possible due to SlickEdit's 
 * implementation of line 0.</p>
 * 
 * <p>You may use the <b>seek</b> command to determine the number of 
 * bytes in a file.  However, keep in mind that if your load options are set 
 * to expand tabs when loading, the seek file size will not match the disk 
 * file size.  In addition, for ASCII files, SlickEdit strips the EOF 
 * (character 27) if there is one at the end of the file.</p>
 * 
 * <p>Command line examples:</p>
 * 
 * <dl>
 * <dt>seek x1000</dt><dd>Go to seek position 
 * 1000 hex</dd>
 * <dt>seek xff+xff</dt><dd>Go to seek position 1fe 
 * hex</dd>
 * </dl> 
 * 
 * @see gui_seek
 * @see _QROffset
 * @see _GoToROffset
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 * 
*/
_command int seek(...) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless status;
   typeless result;
   if ( arg(1)!='' ) {
      a1 := strip(arg(1));
      first_ch := substr(a1,1,1);
      if (first_ch=='+' || first_ch=='-') {
         a1=_QROffset():+first_ch:+'('substr(a1,2)')';
      }
      status=eval_exp(result,a1,10);
      if ( status ) {
         message(get_message(INVALID_ARGUMENT_RC));
         return INVALID_ARGUMENT_RC;
      }
      result=_GoToROffset(result);
      expand_line_level();
      if (result<0) {
         message(nls('Invalid seek position'));
      }
      return(result);
   }
   result=_QROffset();
   sign := "";
   if ( result<0 ) {
      sign='-';
   }
   sticky_message('Seek position dec='result' hex='sign:+"0x":+_dec2hex(result));
   return(0);
}
_command int nrseek(...) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless status;
   typeless result;
   if ( arg(1)!='' ) {
      a1 := strip(arg(1));
      first_ch := substr(a1,1,1);
      if (first_ch=='+' || first_ch=='-') {
         a1=_nrseek():+first_ch:+'('substr(a1,2)')';
      }
      status=eval_exp(result,a1,10);
      if ( status ) {
         message(get_message(INVALID_ARGUMENT_RC));
         return INVALID_ARGUMENT_RC;
      }
      result=_nrseek(result);
      expand_line_level();
      if (result<0) {
         message(nls('Invalid seek position'));
      }
      return(result);
   }
   result=_nrseek();
   sign := "";
   if ( result<0 ) {
      sign='-';
   }
   sticky_message('Seek position dec='result' hex='sign:+"0x":+_dec2hex(result));
   return(0);
}

/**
 * <p>If <i>file_offset</i> is given, the cursor is placed in the file offset 
 * specified.  Otherwise, the current file offset is returned.  0 is the first 
 * character of the file.</p>
 * 
 * <p>IMPORTANT:  This function includes lines with NOSAVE_LF set which means 
 * that these file offsets will not match what is on disk if the file has non-
 * savable lines.  Use the <b>_GoToROffset</b> and <b>_QROffset</b> for dealing 
 * with disk seek positions.</p>
 * 
 * <p>If a file offset is given, it can not be past the end of the file.  
 * Negative file offsets are possible due to SlickEdit's implementation 
 * of line 0.</p>
 * 
 * @example
 * <pre>
 *           /* Get the current seek position. */
 *           p =_nrseek();
 *           /* Seek to offset 1000 */
 *           _nrseek(1000);
 * </pre>
 * 
 * @return If a valid file offset is given, 0 is returned.  If an invalid 
 * file offset is given '' is returned.
 * 
 * <p>If no file offset is given, the current seek position is returned.</p>
 * 
 * @see goto_point
 * @see point
 * @see _GoToROffset
 * @see _QROffset
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 * 
 */
typeless _nrseek(...)
{
   if ( arg(1)!='' ) {
      goto_point(arg(1));
      if ( rc ) {
         return('');
      }
      return(0);
   }
   typeless result;
   typeless a,b;
   parse point() with a b;
   if ( b!='' ) {   /* Null line? */
      col := p_col;
      goto_point(a);
      typeless LineLen=_line_length(true);
      goto_point(a" "b);
      p_col=col;
      result=a+LineLen;
   } else {
      return(point('s'));
   }
   return(result);
}

