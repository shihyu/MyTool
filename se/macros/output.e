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
#import "error.e"
#import "eclipse.e"
#import "files.e"
#import "stdprocs.e"
#import "stdcmds.e"
#endregion

defeventtab _tboutputwin_form;

_tboutputwin_form.'F12'()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   } else if (def_keys == 'eclipse-keys') {
      activate_editor();
   }
}

_tboutputwin_form.'C-M'()
{
   if (isEclipsePlugin()) {
      eclipse_maximize_part();
   }
}

void ctloutput.on_create()
{
   p_LCBufFlags&=~(VSLCBUFFLAG_LINENUMBERS|VSLCBUFFLAG_READWRITE);
   p_word_wrap_style &= ~WORD_WRAP_WWS;
   p_MouseActivate = MA_NOACTIVATE;
   _str sbuf_id;
   parse buf_match('.output',1,'vhx') with sbuf_id .;
   if ( isinteger(sbuf_id) && sbuf_id != p_buf_id ) {
      _delete_buffer();
      // Since we don't know what buffer is active here,
      // don't save previous buffer currsor location.
      load_files('+m +bi 'sbuf_id);
   } else {
      p_buf_name = ".output";
   }
   p_buf_flags|=VSBUFFLAG_DISABLE_SPELL_CHECK_WHILE_TYPING;

   p_UTF8 = true;
}

void _tboutputwin_form.on_destroy()
{
   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id,ON_DESTROY,'2');
}

///////////////////////////////////////////////////////////////////////////////
// For saving and restoring the state of the Output tool window
// when the user undocks, pins, unpins, or redocks the window.
//
void _twSaveState__tboutputwin_form(typeless& state, bool closing)
{
   //if( closing ) {
   //   return;
   //}
   ctloutput._GetBufferContents(state);
}
void _twRestoreState__tboutputwin_form(typeless& state, bool opening)
{
   //if( opening ) {
   //   return;
   //}
   if (state == null) return;
   ctloutput._insert_text_raw(state);
}

void ctloutput.lbutton_double_click()
{
   ctloutput.cursor_error2();
}

static void resizeOutputWin()
{
   int clientW = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   int clientH = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);

   ctloutput.p_width = clientW - 2 * ctloutput.p_x;
   ctloutput.p_y_extent = clientH - ctloutput.p_x;
}

_tboutputwin_form.on_resize()
{
   resizeOutputWin();
}
