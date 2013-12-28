////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48790 $
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
#include "eclipse.sh"
#import "cua.e"
#import "recmacro.e"
#import "seek.e"
#import "stdprocs.e"
#import "vi.e"
#endregion

/**
 * String containing characters to display for corresponding hex
 * characters on right-hand side of hex display.  Typically uses
 * '.' to represent non-printable characters.
 * 
 * @categories Configuration_Variables
 * @see hex
 */
_str def_hex_display_xlat2;

#if __OS390__
_str def_hex_display_xlat2=_reinit
".....\t......\r.......\n.......................................... ...........<(+|&.........!$*);^-/.........,%_>?.........`:#@'=\".abcdefghi.......jklmnopqr.......~stuvwxyz...[...............]..{ABCDEFGHI......}JKLMNOPQR......\\.STUVWXYZ......0123456789......";
#elif __UNIX__
_str def_hex_display_xlat2=_reinit
       //0123456789 0 123 45678901234567890
        ".........\t\n..\r.................. !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~................................................................................................................................";
#elif 1
_str def_hex_display_xlat2=_reinit
       //0 123456789 0 123 45678901234567890
        "\0\t\n\r\x1A !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\x7f\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff";
#endif
int _OnUpdate_hex(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (p_UTF8 && p_encoding!=VSENCODING_UTF8 && p_encoding!=VSENCODING_UTF8_WITH_SIGNATURE) {
      return(MF_UNCHECKED|MF_GRAYED);
   }
   if (p_hex_mode==HM_HEX_ON) {
      return(MF_CHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_ENABLED);
}
void hex_off()
{
   p_show_tabs=0;
   p_hex_mode=HM_HEX_OFF;
   if (p_display_xlat:==def_hex_display_xlat2) {
      p_display_xlat="";
   }
}
void hex_on()
{
   if (p_display_xlat:=="") {
      p_display_xlat=def_hex_display_xlat2;
   }
   p_hex_mode=HM_HEX_ON;
   p_hex_nibble=0;
}
/**
 * <p>Toggles hex/ASCII display on/off.  This command does more than just set 
 * the <b>p_hex_mode</b> property.</p>
 * 
 * <p>In ISPF emulation, this command is not called when invoked from the 
 * command line.  Instead <b>ispf_hex</b> is called.  Use ("View", "Hex") to 
 * explicitly invoke the <b>hex </b>command.</p>
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command void hex() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (p_UTF8 && p_encoding!=VSENCODING_UTF8 && p_encoding!=VSENCODING_UTF8_WITH_SIGNATURE) {
      _message_box("Hex editing mode not supported for Unicode files");
      return;
   }
   if (p_hex_mode==HM_HEX_ON) {
      hex_off();
   } else {
      hex_on();
   }
   if (isEclipsePlugin()) {
      _eclipse_dispatchCommand(ECLIPSE_EV_HEX_TOGGLE);
   }
}
int _OnUpdate_linehex(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (target_wid.p_UTF8/* && target_wid.p_encoding!=VSENCODING_UTF8 && target_wid.p_encoding!=VSENCODING_UTF8_WITH_SIGNATURE*/) {
      return(MF_UNCHECKED|MF_GRAYED);
   }
   if (target_wid.p_hex_mode==HM_HEX_LINE) {
      return(MF_CHECKED|MF_ENABLED);
   }
   return(MF_UNCHECKED|MF_ENABLED);
}
/**
 * <p>Toggles line hex/ASCII display on/off.  This command does more than 
 * just set the <b>p_hex_mode</b> property.</p>
 * 
 * <p>In ISPF emulation, this command is not called when invoked from the 
 * command line.  Instead <b>ispf_hex</b> is called.  Use ("View", "Hex") to 
 * explicitly invoke the <b>hex </b>command.</p>
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command void linehex() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (p_UTF8 /*&& p_encoding!=VSENCODING_UTF8 && p_encoding!=VSENCODING_UTF8_WITH_SIGNATURE*/) {
      _message_box("Hex editing mode not supported for Unicode files");
      return;
   }
   if (p_hex_mode==HM_HEX_LINE) {
      hex_off();
   } else {
      if (p_display_xlat:=="") {
         p_display_xlat=def_hex_display_xlat2;
      }
      p_hex_mode=HM_HEX_LINE;
      p_hex_nibble=0;
   }
   if(isEclipsePlugin()) {
      _eclipse_dispatchCommand(ECLIPSE_EV_LINE_HEX_TOGGLE);
   }
}

void _on_hex()
{
   _str key=last_event();                 /* Key that was actually pressed. */
   int keymsg=last_index('','p');     /* Prefix key(s) message */
   int kt_index=last_index('','k');
   int command_index=eventtab_index(kt_index,kt_index,event2index(key));
   typeless flags=name_info_arg2(command_index);
   if (!isinteger(flags)) flags=0;
   if (p_scroll_left_edge>=0 && !(flags&VSARG2_NOEXIT_SCROLL) && (name_type(command_index) & COMMAND_TYPE)) {
      // Exit scroll mode.
      p_scroll_left_edge=(-1);
      //sticky_message("flags="flags" cmd="name_name(command_index));
      //_beep();
   }
   if (keymsg:!='' || vsIsOnEvent(event2index(key))) {
      call_key(key,keymsg,'e');
      return;
   }
   if (command_state()) {
      if ((flags & (VSARG2_CMDLINE|VSARG2_TEXT_BOX)) ||
          (length(key)==1 && !command_index)) {
         call_key(key,keymsg,'e');
      }
      return;
   }
   if (p_hex_mode==HM_HEX_ON) {
      switch (key) {
      case ENTER:
         if (p_hex_field) {
            return;
         }
         break;
      case BACKSPACE:
         if (_QReadOnly() ||
            (_select_type()!='' && def_persistent_select=='D')) {
            call_key(key,keymsg,'e');
            return;
         }
         _macro_call("hex_backspace");
         hex_backspace();
         return;
      case DEL:
         if (_QReadOnly()||
            (_select_type()!='' && def_persistent_select=='D')) {
            call_key(key,keymsg,'e');
            return;
         }
         _macro_call("hex_del");
         hex_del();
         return;
      case TAB:
      case S_TAB:
         _macro_call("hex_tab");
         hex_tab();
         return;
      }
   }
   if (_QReadOnly() || (def_keys=='vi-keys' && vi_get_vi_mode()=='C')) {
      call_key(key,keymsg,'e');
      return;
   }
   _str keya=key;
   if (!command_index) {
      keya=key2ascii(key);
   }
   if (length(keya)==1 && _asc(_maybe_e2a(keya))>=32) {
      hex_keyin();
      if (p_hex_field) {
         _undo('s');
      }
      return;
   }
   if (p_hex_mode==HM_HEX_LINE && !(flags & VSARG2_LINEHEX)) {

      // IF an editor control is required
      if ((flags & VSARG2_REQUIRES_MDI_EDITORCTL) &&
           !(flags & VSARG2_READ_ONLY)
         ) {
         p_hex_field=0;
         p_hex_nibble=0;
      }
   }
   call_key(key,keymsg,'e');
}

static void _hex_on_selection()
{
   if (_select_type()!='' && def_persistent_select=='D') {
      if (_select_type('','U')=='P' && _select_type('','S')=='E' ) {
         return;
      }
      _begin_select();
      if (_select_type()=='LINE') {
         p_col=1;
      }
      _delete_selection();
   }
}

/**
 * Inserts byte or nibble specified by <b>last_event</b>() depending on 
 * whether cursor is in ASCII column or hex nibbles.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command void hex_keyin() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      keyin(last_event());
      return;
   }
   _hex_on_selection();
   _hex_keyin(last_event());
}

static _str hex2digit="0123456789ABCDEF";
/**
 * Inserts bytes or nibbles depending on whether cursor is in ASCII column or 
 * hex nibbles.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
void _hex_keyin(_str string)
{
   // IF we are on right in ASCII
   _str ch="", curch="";
   typeless offset=0;
   int i=0,j=0;
   for (i=1;i<=length(string);++i) {
      ch=substr(string,i,1);
      if (_on_line0()) {
         _nrseek(0);
         offset=_nrseek();
         if (offset<0) {
            insert_line('');
            // Remove NLChars
            _delete_text(2);
         }
      }
      if (!p_hex_field) {
         if (_insert_state()) {
            _insert_text_raw(ch,1);
         } else {
            _delete_text();
            _insert_text_raw(ch,1);
         }
         p_hex_nibble=0;
         return;
      }
      j=pos(ch,hex2digit,1,'i');
      if (!j) {
         _beep();
         return;
      }
      --j;
      if (p_hex_nibble) {
         curch=get_text_raw();
         _delete_text();
         if (p_encoding==VSCP_EBCDIC_SBCS) {
            _insert_text_raw(_e2a(_chr((_asc(_a2e(curch))&0xf0)|j)),1);
         } else {
            _insert_text_raw(_chr((_asc(curch)&0xf0)|j),1);
         }
         p_hex_nibble=0;
      } else {
         if (_insert_state()) {
            if (p_encoding==VSCP_EBCDIC_SBCS) {
               _insert_text_raw(_e2a(_chr(j<<4)),1);
            } else {
               _insert_text_raw(_chr(j<<4),1);
            }
         } else {
            curch=get_text_raw();
            _delete_text();
            if (p_encoding==VSCP_EBCDIC_SBCS) {
               _insert_text_raw(_e2a(_chr((_asc(_a2e(curch))&0x0f)|(j<<4))),1);
            } else {
               _insert_text_raw(_chr((_asc(curch)&0x0f)|(j<<4)),1);
            }
         }
         offset=_nrseek();
         _nrseek(offset-1);
         /*if (p_col==1) {
            offset=_nrseek();
            _nrseek(offset-1);
         } else {
            left();
         } */
         p_hex_nibble=1;
      }
   }
}

/**
 * Toggles cursor between ASCII column or hex nibbles when in hex mode.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command void hex_tab() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      call_root_key(last_event());
      return;
   }
   p_hex_field=!p_hex_field;
   if (p_hex_field) {
      set_scroll_pos(0,p_cursor_y);
   }
   p_hex_nibble=0;
}
/**
 * Deletes the byte under the cursor when in hex mode.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command void hex_del() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless offset=_nrseek();
   if (offset<0) {
      _nrseek(0);
      offset=_nrseek();
      if (offset<0) {
         return;
      }
   }
   _delete_text();
   p_hex_nibble=0;
}
/**
 * Deletes byte to left of cursor when in hex mode.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command void hex_backspace() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless offset=_nrseek();
   if (offset>=0) {
      _nrseek(offset-1);
   }
   if (offset<0) {
      _nrseek(0);
      offset=_nrseek();
      if (offset<0) {
         return;
      }
   }
   _delete_text();
   p_hex_nibble=0;
}
/**
 * Moves the cursor one byte past the last byte in the current buffer.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command void hex_bottom() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   p_hex_nibble=0;
   _nrseek(p_buf_size);
}
/**
 * Moves the cursor down one hex line when in hex mode.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
int _hex_down(boolean doScreenLines)
{
   typeless result="";
   if (p_hex_mode==HM_HEX_LINE) {
      if (p_LCHasCursor && _LCIsReadWrite()) {
         p_hex_nibble=0;
         p_hex_field=0;
      } else if ((_lineflags() & NOSAVE_LF) || _on_line0()) {
         p_hex_nibble=0;
         p_hex_field=0;
      } else {
         if (!p_hex_field) {
            p_hex_field=1;
            p_hex_nibble=0;
            return(0);
         } else if (!p_hex_nibble) {
            p_hex_nibble=1;
            return(0);
         }
      }
      result=down(1,doScreenLines);
      if (!result) {
         while (_lineflags() & HIDDEN_LF) {
            result=down();
            if (result) {
               break;
            }
         }
      }
      if (!result) {
         p_hex_field=0;
         p_hex_nibble=0;
      }
      return(result);
   }
   int NofbytesPerLine=p_hex_Nofcols*HEX_CHARSPERCOL;
   typeless offset=_nrseek();
   if (offset+NofbytesPerLine>=p_buf_size) {
      hex_bottom();
      if (offset intdiv NofbytesPerLine!=_nrseek() intdiv NofbytesPerLine) {
         return(0);
      }
      return(BOTTOM_OF_FILE_RC);
   }
   _nrseek(offset+NofbytesPerLine);
   return(0);
}
/**
 * Moves the cursor up one hex line when in hex mode.
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
int _hex_up(boolean doScreenLines)
{
   typeless result=0;
   if (p_hex_mode==HM_HEX_LINE) {
      if (p_LCHasCursor && _LCIsReadWrite()) {
         p_hex_nibble=0;
         p_hex_field=0;
         result=up(1,doScreenLines);
         while (_lineflags() & HIDDEN_LF) {
            if (_on_line0()) {
               break;
            }
            result=up(1,doScreenLines);
         }
         return(result);
      }
      if (!p_hex_field) {
         result=up(1,doScreenLines);
         while (_lineflags() & HIDDEN_LF) {
            if (_on_line0()) {
               break;
            }
            result=up(1,doScreenLines);
         }
         if (_lineflags() & NOSAVE_LF) {
            p_hex_nibble=0;
            p_hex_field=0;
         }
         if (_on_line0()) {
            p_hex_field=0;
            p_hex_nibble=0;
            return(result);
         }
         p_hex_field=1;
         p_hex_nibble=1;
         return(result);
      } else if (p_hex_nibble) {
         p_hex_nibble=0;
         return(0);
      }
      p_hex_field=0;
      return(0);
   }
   int NofbytesPerLine=p_hex_Nofcols*HEX_CHARSPERCOL;
   typeless offset=_nrseek();
   if (offset<=0) {
      return(TOP_OF_FILE_RC);
   }
   if (offset-NofbytesPerLine<=0) {
      top_of_buffer();
      return(0);
   }
   _nrseek(offset-NofbytesPerLine);
   return(0);
}
/**
 * Moves cursor left one byte or one nibble depending on whether cursor is in 
 * ASCII column or hex nibbles.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
void _hex_left()
{
   typeless offset=0;
   if (!p_hex_field) {
      p_hex_nibble=0;
      if (p_col==1) {
         offset=_nrseek();
         if (offset<=0) {
            return;
         }
         _nrseek(offset-1);
         return;
      }
      left();
      return;
   }
   if (p_hex_nibble) {
      p_hex_nibble=0;
      return;
   }
   offset=_nrseek();
   if (offset<=0) {
      return;
   }
   _nrseek(offset-1);
   p_hex_nibble=1;
}
/**
 * Moves cursor right one byte or one nibble depending on whether cursor is in 
 * ASCII column or hex nibbles.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
void _hex_right()
{
   if (p_hex_field && !p_hex_nibble) {
      p_hex_nibble=1;
      return;
   }
   p_hex_nibble=0;
   if (!p_hex_field && p_col<_text_colc(0,"L")) {
      right();
      return;
   }
   typeless offset=_nrseek();
   if (offset+1>=p_buf_size) {
      hex_bottom();
      return;
   }
   _nrseek(offset+1);
}
/**
 * Moves cursor down to next hex page.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
void _hex_pagedown()
{
   int NofbytesPerLine=p_hex_Nofcols*HEX_CHARSPERCOL;
   int NofbytesPerPage=NofbytesPerLine*p_char_height;
   typeless LineOfs=0;
   typeless offset=_nrseek();
   if (offset+NofbytesPerPage>p_buf_size) {
      LineOfs=offset%NofbytesPerLine;
      offset=(p_buf_size intdiv NofbytesPerLine)*NofbytesPerLine;
      if (offset+LineOfs>p_buf_size) {
         _beep();
         hex_bottom();
         return;
      }
      _nrseek(offset+LineOfs);
      return;
   }
   _nrseek(offset+NofbytesPerPage);
}
/**
 * Moves cursor up to previous hex page.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
void _hex_pageup()
{
   int NofbytesPerLine=p_hex_Nofcols*HEX_CHARSPERCOL;
   int NofbytesPerPage=NofbytesPerLine*p_char_height;
   typeless LineOfs=0;
   typeless offset=_nrseek();
   if (offset-NofbytesPerPage<=0) {
      LineOfs=offset%NofbytesPerLine;
      if (LineOfs>p_buf_size) {
         top_of_buffer();
         return;
      }
      _nrseek(LineOfs);
      return;
   }
   _nrseek(offset-NofbytesPerPage);
}
/**
 * Moves the cursor to the beginning of a hex line when in hex mode.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
void _hex_begin_line()
{
   typeless offset=_nrseek();
   if (offset<0) return;
   int NofbytesPerLine=p_hex_Nofcols*HEX_CHARSPERCOL;
   _nrseek(offset-(offset%NofbytesPerLine));
   p_hex_nibble = 0;
}
/**
 * Moves the cursor to the last bye in the current hex line.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
void _hex_end_line()
{
   typeless offset=_nrseek();
   if (offset<0) return;
   int NofbytesPerLine=p_hex_Nofcols*HEX_CHARSPERCOL;
   int new_offset=(offset-(offset%NofbytesPerLine))+NofbytesPerLine-1;
   if (new_offset>p_buf_size) {
      new_offset=p_buf_size;
   }
   _nrseek(new_offset);
   p_hex_nibble = 0;
}

/**
 * Selects the current column in the hex mode display.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command void hex_select_word() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless offset=_nrseek();
   if (offset<0) return;
   int new_offset = offset - (offset%HEX_CHARSPERCOL);
   _deselect();
   _nrseek(new_offset);
   _select_char('','CN');
   new_offset = offset - (offset%HEX_CHARSPERCOL) + HEX_CHARSPERCOL;
   if (new_offset > p_buf_size) {
      new_offset = p_buf_size;
   }
   _nrseek(new_offset);
   _select_char('');
   if ( pos('C', def_select_style) && def_persistent_select!='Y' ) {
      _select_char('','CN');
   } else {
      _select_char('','EN');
   }
   p_hex_nibble=0;
}


/**
 * Selects the current line for hex mode display.  For practical
 * purposes, the mark is a character selection.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command void hex_select_line() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless offset=_nrseek();
   if (offset<0) return;
   
   int NofbytesPerLine=p_hex_Nofcols*HEX_CHARSPERCOL;
   int new_offset = offset - (offset % NofbytesPerLine);
   _deselect();
   _nrseek(new_offset);
   _select_char('','CN');
   new_offset = offset - (offset % NofbytesPerLine) + NofbytesPerLine;
   if (new_offset > p_buf_size) {
      new_offset = p_buf_size;
   }
   _nrseek(new_offset);
   _select_char('');
   if ( pos('C', def_select_style) && def_persistent_select!='Y' ) {
      _select_char('','CN');
   } else {
      _select_char('','EN');
   }
   p_hex_nibble=0;
}
