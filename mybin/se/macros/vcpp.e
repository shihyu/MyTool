////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47103 $
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
#import "bookmark.e"
#import "c.e"
#import "cutil.e"
#import "error.e"
#import "fileman.e"
#import "listbox.e"
#import "markfilt.e"
#import "pmatch.e"
#import "seek.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbview.e"
#import "util.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

/*

   Visual C++ emulation macro

*/

/**
 * Mimics the MSDEV full screen editing capability by disabling all toolbars and maximizing the editor.
 */
_command void msdev_fullscreen()
{
   fullscreen(1);
}
//This upcases the selection (if exists) or upcases the current char.
_command void msdev_upcase_selection() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if ( ! select_active2() ) {
      _str letter=get_text(-2);
      if (isnormal_char(letter)) {
         _delete_text(length(letter));
         keyin(upcase(letter));
      }
      return;
   }
   upcase_selection();
}

//This lower-cases the selection (if exists) or cases the current char.
_command void msdev_lowcase_selection() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if ( ! select_active2() ) {
      _str letter=get_text(-2);
      if (isnormal_char(letter)) {
         _delete_text(length(letter));
         keyin(lowcase(letter));
      }
      return;
   }
   lowcase_selection();
}

_command void format_selection() name_info(','VSARG2_MARK)
{
   _str supported=' e c java ';
   if ( command_state() || _on_line0() || _in_comment() || !pos(' 'p_LangId' ',supported)) {
      call_root_key(TAB);
      return;
   }
   typeless p;
   _save_pos2(p);
   if (!select_active()) {
      format_line();
   } else {
      end_select(); end_line=p_line;
      begin_select();
      _deselect();
      for (;;) {
         _begin_line();
         format_line();
         down();
         if (p_line>=end_line) {
            break;
         }
      }
   }
   _restore_pos2(p);
}

static void format_line()
{
   boolean hacked_line=false;
   if ( command_state() || _on_line0() || _in_comment()) {
      call_root_key(TAB);
      return;
   }
   if ((p_line==1 || _no_code())) {
      get_line(auto line);
      replace_line(strip(line));
      return;
   }
   get_line(auto line1);
   if (strip(line1):=='') {
      line1='x';
      hacked_line=true;
      replace_line(line1);
   }
   //say('p_SyntaxIndent='p_SyntaxIndent);
   int col1=p_col;
   typeless inon_blank_col=_first_non_blank_col();
   first_non_blank();
   typeless Noflines,cur_line,first_word,last_word,rest,non_blank_col,semi,prev_semi;
   int status=c_get_info(Noflines,cur_line,first_word,last_word,rest,
                     non_blank_col,semi,prev_semi);
   if (status) return;
   int col=c_indent_col(non_blank_col,false);
#if 1
   if (col==1) {
      //Is this really supposed to go in column 1?
      up();
      get_line(auto above);
      if (strip(above):=='') {
         format_line();
         col=p_col;
         //messageNwait('col='col);
      } else {
         if (strip(above):=='{') {
            _end_line();
            col=p_col+p_SyntaxIndent-1;
         } else {
            if (strip(above):=='}') {
               _end_line();
               col=p_col-p_SyntaxIndent-1;
               //say('col='col'p_col='p_col'p_SyntaxIndent='p_SyntaxIndent);
            } else {
               col=pos('~[ \t]',above,1,'r');
               down();
               get_line(auto current);  //This may be a closing brace
               up();
               if ((strip(current):=='}') && (col-p_SyntaxIndent <=1)) {
                  col=1;
               }
               //say('col='col'p_col='p_col'p_SyntaxIndent='p_SyntaxIndent);
            }
         }
      }
      down();
   }
#endif

   //_message_box(nls("Noflines=%s,\ncur_line=%s,\nfirst_word=%s,\nlast_word=%s,\nrest=%s,\nnon_blank_col=%s,\nsemi=%s,\nprev_semi=%s,\ncol=%s",
   //                 Noflines,cur_line,first_word,last_word,rest,non_blank_col,semi,prev_semi,col));
   //p_col=old_col;down
   p_col=inon_blank_col;
   //col2=c_indent_col(0,0);
   //_indent_on_ctab2('',col2);
   _indent_on_ctab2(0,col);
   get_line(auto line2);
   //_indent_on_ctab2(

   /*  We want the cursor to remain in the same relative location
       in the line i.e.:

               if (<cursor>){
                  }

       Should become:

       if (<cursor>){
          }
   */

   if (hacked_line) {
      //col=_first_non_blank_col();
      replace_line('');
      //p_col=col;
   } else {
      p_col=col1-(length(line1)-length(line2));
   }
   //clear_message();
   //messageNwait(nls('line1=%s, line2=%s, diff=%s, p_col=%s',
   //                 length(line1), length(line2), length(line1)-length(line2),p_col));
}

static boolean _no_code()
{
   typeless start_line=p_line;
   _str line;
   while (!up()) {
      get_line(line);
      if (strip(line)=='') {
         continue;
      } else {
         p_line=start_line;
         return(0);
      }
   }
   p_line=start_line;
   return(1);
}

//This is the one that actually does the indention:
static void _indent_on_ctab2(int syntax_indent, typeless column='')
{
   //syntax_indent=arg(1em);
   if ( _expand_tabsc(1,p_col-1)=='' ) {
      first_non_blank();
   }
   get_line(auto line);
   if (arg(2)==0) {
      expand_replace_line(strip(line,'L'));
      return;
   }
   typeless col1,col2;
   if ( arg(2)!='' ) {
      col1=arg(2);
      col2=p_col;
      //messageNwait('here, col1='col1' col2='col2);
   } else {
      col2=p_col;
      col1=p_col+syntax_indent;
   }
   //_message_box(nls("col1=%s\ncol2=%s\nline=%s",col1,col2,line));
   _str result=indent_string(col1-1):+_expand_tabsc(col2,-1,'S');
   if ( result=='' && !LanguageSettings.getInsertRealIndent(p_LangId) ) {
      result='';
   }
   //messageNwait('**'result'**');
   expand_replace_line(result);
   p_col=col1;
}
static void expand_replace_line(_str line)
{
   if (p_indent_with_tabs) {
      typeless non_blank = verify( line," ");
      if ( non_blank ) {
         replace_line( indent_string(text_col(line,non_blank,'I')-1) :+
                       substr(line,non_blank) );
      }
   } else {
      //p_indent_with_tabs is off.  Just replace the line normally.
      replace_line(line);
   }
}




/*Goes to one of the following (can't implement them all):

 Address:  (debugger)                           Buttons:    "Go To" "Prev" "Close"
 Bookmark:                                                  "Next" "Prev"  "Close"
 Definition:  Works along side the "Tag Properties" dialog  "Go To"        "Close"
 Error/Tag:   combo box of errors.                          "Next" "Prev"  "Close"
 Line:                                                      "Go To"        "Close"
 Offset:                                                    "Go To"        "Close"
 Reference:   Close to "Definition"                         "Go To"        "Close"

 */

_command void gui_goto() name_info(','VSARG2_EDITORCTL)
{
   //show ('-nocenter vcpp_goto');
   if (p_object==OI_EDITOR) {
      show('-xy _goto_form');
   } else {
      show('-mdi -xy _goto_form');
   }
}

//Goes to the previous preprocessing statement, and does a char select from the current point.
_command void select_prev_condition() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE|VSARG2_MARK)
{
   save_pos(auto p);
   cua_select_char();
   int status=prev_condition();
   if (status) {
      restore_pos(p);
      _deselect();
      message('No enclosing conditional statement found.');
      return;
   }
   cua_select_char();
}
_command void select_next_condition() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE|VSARG2_MARK)
{
   save_pos(auto p);
   cua_select_char();
   int status=next_condition();
   if (status) {
      restore_pos(p);
      //_deselect();
      message('No enclosing conditional statement found.');
      return;
   }
   down();
   cua_select_char();
}
static void cua_select_char(_str markid="")
{
   typeless inclusive='';
   if ( _select_type(markid)!='' && _select_type(markid,'I') ) {
      inclusive='I';
   }
   _str mstyle;
   if ( def_persistent_select=='Y' ) {
      mstyle='EP':+inclusive;
   } else {
      mstyle='E':+inclusive;
   }
   int status=_select_char(markid,mstyle);
   if (status) {
      message(get_message(status));
      return;
   }
   _cua_select=1;
}
//This selects (char) from the current brace to the matching one.
_command void select_matching_brace() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   if (command_state()) {
      return;
   }
   _str text=get_text(1);
   if (_asc(text)==13 || _asc(text)==10) {
      left();
      text=get_text(1);
      if (!(text:=='{' || text:=='}')) {
         right();
         return;
      }
   }
   if (text:=='}') {
      right();
   }
   save_pos(auto p);
   int status=find_matching_paren(true);
   if (status) {
      restore_pos(p);
      _deselect();
      return;
   }
   int col=p_col;
   int line=p_line;
   restore_pos(p);
   cua_select_char();
   p_col=col; p_line=line;
   if (get_text(1):=='}') {
      right();
   }
   cua_select_char();
   _end_select();
}


defeventtab _goto_form;
void _goto_form.'TAB'()
{
   //This should activate the option_input line (text_box or combo_box)
   _goto_tab();
}
static void _goto_tab()
{
   typeless wid=_get_focus();
   typeless control_id;
   if (ctl_cb_option_input.p_visible) {
      control_id=_find_control('ctl_cb_option_input');
   } else {
      control_id=_find_control('ctl_tb_option_input');
   }
   if (wid==control_id) {
      //The text box/combo box has focus.
      if (radio_line.p_value) {
         _find_control('radio_line')._set_focus();
      }
      if (radio_offset.p_value) {
         _find_control('radio_offset')._set_focus();
      }
      if (radio_bookmark.p_value) {
         _find_control('radio_bookmark')._set_focus();
      }
      if (radio_definition.p_value) {
         _find_control('radio_definition')._set_focus();
      }
      if (radio_reference.p_value) {
         _find_control('radio_reference')._set_focus();
      }
      if (radio_error.p_value) {
         _find_control('radio_error')._set_focus();
      }
   } else {
      control_id._set_focus();
      control_id._begin_line();
      control_id.select_all();
   }
}
void _goto_form.'ENTER'()
{
   doOK();
}
void ctl_OK.lbutton_up()
{
   doOK();
}
static void doOK()
{
   typeless optionVal;
   if (ctl_cb_option_input.p_visible) {
      optionVal = ctl_cb_option_input.p_text;
   } else {
      optionVal = ctl_tb_option_input.p_text;
   }
   typeless wid;
   if ( optionVal=='') {
      wid=_find_formobj('_goto_form','N');
      wid._delete_window(1);
      return;
   }
   wid=getEditorCtl();
   int status;
   if (radio_line.p_value) {
      if (isnumber(optionVal) && optionVal <= wid.p_Noflines) {
#if 1
         //Check to see if the user did a "+nn" to go ahead nn lines
         switch (substr(optionVal,1,1)) {
         case '+':
            wid.p_line += (int) substr(optionVal,2);
            break;
         case '-':
            wid.p_line -= (int) substr(optionVal,2);
            break;
         default:
            wid.p_line = optionVal;
            break;
         }
#else
         wid.p_line = optionVal;
#endif
         wid._set_focus();
      } else {
         _message_box('Invalid line number entered');
         _goto_tab();
         return;
      }
   } else if (radio_offset.p_value) {
      status=wid.seek(optionVal);
      if (status) {
         clear_message();
         _message_box(get_message(status));
         _goto_tab();
         return;
      }
   } else if (radio_bookmark.p_value) {
      status = wid.goto_bookmark(optionVal);
      if (status < 0) {
         //_message_box('Invalid bookmark');
         _goto_tab();
         return;
      }
   } else if (radio_definition.p_value) {
      status=wid.find_tag(optionVal);
      if (status) {
         return;
      }
   } else if (radio_reference.p_value) {
      status=wid.push_ref(optionVal);
      if (status) {
         return;
      }
   }
   wid=_find_formobj('_goto_form','N');
   wid._delete_window(1);
}
void radio_reference.lbutton_up()
{
   activate_error(0);
   option_label.p_caption="Enter Reference:";
   typeless wid=getEditorCtl();
   if (wid) {
      int junk;
      ctl_tb_option_input.p_text=wid.cur_word(junk);
   } else {
      ctl_tb_option_input.p_text='';
      ctl_tb_option_input.p_enabled=0;
   }
   _goto_tab();
}
void radio_definition.lbutton_up()
{
   activate_error(0);
   option_label.p_caption = "Enter definition:";
   typeless wid=getEditorCtl();
   if (wid) {
      int junk;
      ctl_tb_option_input.p_text=wid.cur_word(junk);
   } else {
      ctl_tb_option_input.p_text='';
      ctl_tb_option_input.p_enabled=0;
   }
   _goto_tab();
}
void radio_error.lbutton_up()
{
   activate_error(1);
   ctl_cb_option_input.p_enabled=0;
   ctl_cb_option_input.p_visible=0;
   option_label.p_caption='Select Next/Prev Error:';
   _goto_tab();
}
void radio_bookmark.lbutton_up()
{
   activate_error(0);
   ctl_tb_option_input.p_enabled=0;
   ctl_tb_option_input.p_visible=0;
   ctl_cb_option_input.p_enabled=1;
   ctl_cb_option_input.p_visible=1;
   option_label.p_caption = "Choose bookmark:";
   ctl_cb_option_input.p_text = '';
   if (!getEditorCtl()) {
      ctl_cb_option_input.p_enabled=0;
      ctl_cb_option_input.p_visible=0;
   }
   //say('_BookmarkQCount='_BookmarkQCount());
   if (!_BookmarkQCount()) {
      ctl_cb_option_input.p_enabled=0;
      ctl_cb_option_input.p_text='No bookmarks present';
   } else {
      ctl_cb_option_input.p_enabled=1;
      int count = _BookmarkQCount();
      ctl_cb_option_input._lbclear();
      int index, status;
      _str name;
      for (index = count-1; index >=0; index--) {
         status=_BookmarkGetInfo(index, name);
         //messageNwait('_BookmarkGetInfo returned 'status' on bookmark 'name' index 'index);
         status=_BookmarkFind(name,VSBMFLAG_SHOWNAME);
         //messageNwait('_BookmarkFind returned 'status' on bookmark 'name' index 'index);
         if (status==-1) {
            //The bookmark was invalid
            continue;
         }
         ctl_cb_option_input._lbadd_item(name);
      }
      ctl_cb_option_input._lbsort();
      ctl_cb_option_input.top();
      if (ctl_cb_option_input.p_Noflines==0) {
         //There were no valid bookmarks, _BookmarkQCount() returned wrong count
         ctl_cb_option_input.p_enabled=0;
         ctl_cb_option_input.p_text='No bookmarks present';
      }
   }
   _goto_tab();
}
static int getEditorCtl()
{
   typeless wid=p_active_form.p_parent;
   if (wid && wid._isEditorCtl()) {
      return(wid);
   }
   if (_no_child_windows()) {
      return(0);
   }
   return(_mdi.p_child);
}
void radio_line.lbutton_up()
{
   activate_error(0);
   option_label.p_caption='Go to Line:';
   typeless wid=getEditorCtl();
   if (wid) {
      ctl_tb_option_input.p_text=wid.p_line;
   } else {
      ctl_tb_option_input.p_text='';
      ctl_tb_option_input.p_enabled=0;
   }
   _goto_tab();
}

void radio_offset.lbutton_up()
{
   activate_error(0);
   ctl_tb_option_input.p_text = '';
   option_label.p_caption='Enter offset:';
   typeless wid=getEditorCtl();
   if (wid) {
      ctl_tb_option_input.p_text=wid._QROffset();
   } else {
      ctl_tb_option_input.p_text='';
      ctl_tb_option_input.p_enabled=0;
   }
   _goto_tab();
}
void ctl_OK.on_create()
{
   initialize_goto_form(1);
}

static void initialize_goto_form(int set_default=1)
{
   activate_error(0);
   //Need to find out if there is currently an mdi child
   typeless wid=getEditorCtl();
   if (!wid) {
      //If there isn't an mdi child, we want to find out the first available option.
      //Otherwise, just go to "Error" and turn off all of the options.
      set_control('radio_line',0);
      set_control('radio_bookmark',0);
      set_control('radio_error',1);
      set_control('radio_offset',0);
      set_control('radio_definition',0);
      set_control('radio_reference',0);
      if (set_default) {
         radio_error.p_value=1;
         call_event('',_control radio_error,LBUTTON_UP,'');
      }
   } else {
      if (wid.p_hex_mode) {
         //The file is in hex:
         set_control('radio_line',1);
         set_control('radio_bookmark',1);  // This sort of works if !wid.p_mdi_child
         set_control('radio_offset',1);
         if (wid.p_mdi_child) {
            set_control('radio_error',1);
            set_control('radio_definition',1);
            set_control('radio_reference',1);
         } else {
            set_control('radio_error',0);
            set_control('radio_definition',0);
            set_control('radio_reference',0);
         }
         if (set_default) {
            radio_offset.p_value=1;
            call_event('',_control radio_offset,LBUTTON_UP,'');
         }
      } else {
         set_control('radio_line',1);
         set_control('radio_bookmark',1);  // This sort of works if !wid.p_mdi_child
         set_control('radio_offset',1);
         if (wid.p_mdi_child) {
            set_control('radio_error',1);
            set_control('radio_definition',1);
            set_control('radio_reference',1);
         } else {
            set_control('radio_error',0);
            set_control('radio_definition',0);
            set_control('radio_reference',0);
         }
         if (set_default) {
            radio_line.p_value=1;
            call_event('',_control radio_line,LBUTTON_UP,'');
         } else {
            //call_active();
         }
      }
   }
}
static void call_active()
{
   typeless wid=_find_formobj('_goto_form','N');
   if (wid.radio_line.p_value) {
      call_event('',_control radio_line,LBUTTON_UP,'');
   }
   if (wid.radio_bookmark.p_value) {
      call_event('',_control radio_bookmark,LBUTTON_UP,'');
   }
   if (wid.radio_offset.p_value) {
      call_event('',_control radio_offset,LBUTTON_UP,'');
   }
   if (wid.radio_error.p_value) {
      call_event('',_control radio_error,LBUTTON_UP,'');
   }
   if (wid.radio_definition.p_value) {
      call_event('',_control radio_definition,LBUTTON_UP,'');
   }
   if (wid.radio_reference.p_value) {
      call_event('',_control radio_reference,LBUTTON_UP,'');
   }
}
void ctl_nexterror.lbutton_up()
{
   int status=next_error();
   if (status) {
      clear_message();
      _str msg='';
      if (status==STRING_NOT_FOUND_RC) {
         msg="No error message files";
      } else {
         msg=get_message(status);
      }
      _message_box("Next Error failed.\n\n"msg,'Goto Next Error');
   }
}
void ctl_preverror.lbutton_up()
{
   int status=prev_error();
   if (status) {
      clear_message();
      _str msg='';
      if (status==STRING_NOT_FOUND_RC) {
         msg="No error message files";
      } else {
         msg=get_message(status);
      }
      _message_box("Prev Error failed.\n\n"msg,'Goto Prev Error');
   }
}
//I want to reinitialize the dialog so to something known.
static void activate_error(boolean on_off=true)
{
   typeless wid=_find_formobj('_goto_form','N');
   wid.ctl_nexterror.p_enabled=on_off;
   wid.ctl_nexterror.p_visible=on_off;
   wid.ctl_preverror.p_enabled=on_off;
   wid.ctl_preverror.p_visible=on_off;
   wid.ctl_cb_option_input.p_text='';
   wid.option_label.p_caption='';
   wid.ctl_cb_option_input.p_enabled=on_off;
   wid.ctl_cb_option_input.p_visible=on_off;
   wid.ctl_tb_option_input.p_enabled=!on_off;
   wid.ctl_tb_option_input.p_visible=!on_off;
}
//This may end up becoming much more general purpose.
static void set_control(_str control_name,typeless on_off)
{
   typeless wid=_find_formobj('_goto_form','N');
   typeless control_id=wid._find_control(control_name);
   control_id.p_enabled=on_off;
   control_id.p_visible=on_off;
}

