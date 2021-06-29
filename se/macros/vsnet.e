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
#import "se/lang/api/LanguageSettings.e"
#import "se/ui/mainwindow.e"
#import "bookmark.e"
#import "c.e"
#import "cutil.e"
#import "error.e"
#import "fileman.e"
#import "listbox.e"
#import "markfilt.e"
#import "math.e"
#import "pmatch.e"
#import "pushtag.e"
#import "seek.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbview.e"
#import "toolbar.e"
#import "tbcmds.e"
#import "util.e"
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
      letter := get_text(-2);
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
      letter := get_text(-2);
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
   supported := " e c java ";
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
   hacked_line := false;
   if ( command_state() || _on_line0() || _in_comment()) {
      call_root_key(TAB);
      return;
   }
   line := "";
   if ((p_line==1 || _no_code())) {
      get_line(line);
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
   col1 := p_col;
   typeless inon_blank_col=_first_non_blank_col();
   _first_non_blank();

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

static bool _no_code()
{
   start_line := p_line;
   while (!up()) {
      get_line(auto line);
      if (strip(line)=='') {
         continue;
      } else {
         p_line=start_line;
         return(false);
      }
   }
   p_line=start_line;
   return(true);
}

//This is the one that actually does the indention:
static void _indent_on_ctab2(int syntax_indent, typeless column='')
{
   //syntax_indent=arg(1em);
   if ( _expand_tabsc(1,p_col-1)=='' ) {
      _first_non_blank();
   }
   get_line(auto line);
   if (column==0) {
      expand_replace_line(strip(line,'L'));
      return;
   }
   typeless col1=0, col2=0;
   if ( column!='' ) {
      col1=column;
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

_command void gui_goto() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
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
   _cua_select_char();
   int status=prev_condition();
   if (status) {
      restore_pos(p);
      _deselect();
      message('No enclosing conditional statement found.');
      return;
   }
   _cua_select_char();
}
_command void select_next_condition() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE|VSARG2_MARK)
{
   save_pos(auto p);
   _cua_select_char();
   int status=next_condition();
   if (status) {
      restore_pos(p);
      //_deselect();
      message('No enclosing conditional statement found.');
      return;
   }
   down();
   _cua_select_char();
}
//This selects (char) from the current brace to the matching one.
_command void select_matching_brace() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   _select_matching_paren();
}


//_command activate_project_toolbar() name_info(','VSARG2_EDITORCTL)
//{
//   return activate_tool_window('_tbprojects_form');
//}

//_command activate_output_toolbar() name_info(','VSARG2_EDITORCTL)
//{
//   return activate_tool_window('_tboutputwin_form');
//}
//_command void activate_tag_properties_toolbar() name_info(','VSARG2_EDITORCTL)
//{
//   activate_tab('Properties','','_tbprops_form','ctl_props_sstab');
//}


defeventtab _goto_form;
void _goto_form.'TAB'()
{
   //This should activate the option_input line (text_box or combo_box)
   _goto_tab();
}
static void _goto_tab()
{
   wid := _get_focus();
   control_id := 0;
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
      if (radio_declaration.p_value) {
         _find_control('radio_declaration')._set_focus();
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
      control_id.select_all_line();
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
   typeless optionVal="";
   if (ctl_cb_option_input.p_visible) {
      optionVal = ctl_cb_option_input.p_text;
   } else {
      optionVal = ctl_tb_option_input.p_text;
   }
   wid := 0;
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
         typeless rawNumber;
         switch (substr(optionVal,1,1)) {
         case '+':
            eval_exp(rawNumber,substr(optionVal,2),10);
            wid.p_line += (int) rawNumber;
            break;
         case '-':
            eval_exp(rawNumber,substr(optionVal,2),10);
            wid.p_line -= (int) rawNumber;
            break;
         default:
            eval_exp(rawNumber,optionVal,10);
            wid.p_line = (int) rawNumber;
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
         _message_box('Invalid bookmark');
         _goto_tab();
         return;
      }
   } else if (radio_definition.p_value) {
      status=wid.push_def(optionVal);
      if (status) {
         return;
      }
   } else if (radio_declaration.p_value) {
      status=wid.push_decl(optionVal);
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
   activate_error(false);
   option_label.p_caption="Enter Reference:";
   int wid=getEditorCtl();
   if (wid) {
      int junk;
      ctl_tb_option_input.p_text=wid.cur_word(junk);
   } else {
      ctl_tb_option_input.p_text='';
      ctl_tb_option_input.p_enabled=false;
   }
   _goto_tab();
}
void radio_definition.lbutton_up()
{
   activate_error(false);
   option_label.p_caption = "Enter definition:";
   int wid=getEditorCtl();
   if (wid) {
      int junk;
      ctl_tb_option_input.p_text=wid.cur_word(junk);
   } else {
      ctl_tb_option_input.p_text='';
      ctl_tb_option_input.p_enabled=false;
   }
   _goto_tab();
}
void radio_declaration.lbutton_up()
{
   activate_error(false);
   option_label.p_caption = "Enter declaration:";
   int wid=getEditorCtl();
   if (wid) {
      int junk;
      ctl_tb_option_input.p_text=wid.cur_word(junk);
   } else {
      ctl_tb_option_input.p_text='';
      ctl_tb_option_input.p_enabled=false;
   }
   _goto_tab();
}
void radio_error.lbutton_up()
{
   activate_error(true);
   ctl_cb_option_input.p_enabled=false;
   ctl_cb_option_input.p_visible=false;
   option_label.p_caption='Select Next/Prev Error:';
   _goto_tab();
}
void radio_bookmark.lbutton_up()
{
   activate_error(false);
   ctl_tb_option_input.p_enabled=false;
   ctl_tb_option_input.p_visible=false;
   ctl_cb_option_input.p_enabled=true;
   ctl_cb_option_input.p_visible=true;
   option_label.p_caption = "Choose bookmark:";
   ctl_cb_option_input.p_text = '';
   if (!getEditorCtl()) {
      ctl_cb_option_input.p_enabled=false;
      ctl_cb_option_input.p_visible=false;
   }
   //say('_BookmarkQCount='_BookmarkQCount());
   if (!_BookmarkQCount()) {
      ctl_cb_option_input.p_enabled=false;
      ctl_cb_option_input.p_text='No bookmarks present';
   } else {
      ctl_cb_option_input.p_enabled=true;
      int count = _BookmarkQCount();
      ctl_cb_option_input._lbclear();
      for (index := count-1; index >=0; index--) {
         name := "";
         int status=_BookmarkGetInfo(index, name);
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
         ctl_cb_option_input.p_enabled=false;
         ctl_cb_option_input.p_text='No bookmarks present';
      }
   }
   _goto_tab();
}
static int getEditorCtl()
{
   int wid=p_active_form.p_parent;
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
   activate_error(false);
   option_label.p_caption='Go to Line:';
   int wid=getEditorCtl();
   if (wid) {
      ctl_tb_option_input.p_text=wid.p_line;
   } else {
      ctl_tb_option_input.p_text='';
      ctl_tb_option_input.p_enabled=false;
   }
   _goto_tab();
}

void radio_offset.lbutton_up()
{
   activate_error(false);
   ctl_tb_option_input.p_text = '';
   option_label.p_caption='Enter offset:';
   int wid=getEditorCtl();
   if (wid) {
      ctl_tb_option_input.p_text=wid._QROffset();
   } else {
      ctl_tb_option_input.p_text='';
      ctl_tb_option_input.p_enabled=false;
   }
   _goto_tab();
}
void ctl_OK.on_create()
{
   initialize_goto_form(1);
}

static void initialize_goto_form(int set_default=1)
{
   activate_error(false);
   //Need to find out if there is currently an mdi child
   int wid=getEditorCtl();
   if (!wid) {
      //If there isn't an mdi child, we want to find out the first available option.
      //Otherwise, just go to "Error" and turn off all of the options.
      set_control('radio_line',false);
      set_control('radio_bookmark',false);
      set_control('radio_error',true);
      set_control('radio_offset',false);
      set_control('radio_definition',false);
      set_control('radio_declaration',false);
      set_control('radio_reference',false);
      if (set_default) {
         radio_error.p_value=1;
         call_event('',_control radio_error,LBUTTON_UP,'');
      }
   } else {
      if (wid.p_hex_mode) {
         //The file is in hex:
         set_control('radio_line',true);
         set_control('radio_bookmark',true);  // This sort of works if !wid.p_mdi_child
         set_control('radio_offset',true);
         if (wid.p_mdi_child) {
            set_control('radio_error',true);
            set_control('radio_definition',true);
            set_control('radio_declaration',true);
            set_control('radio_reference',true);
         } else {
            set_control('radio_error',false);
            set_control('radio_definition',false);
            set_control('radio_declaration',false);
            set_control('radio_reference',false);
         }
         if (set_default) {
            radio_offset.p_value=1;
            call_event('',_control radio_offset,LBUTTON_UP,'');
         }
      } else {
         set_control('radio_line',true);
         set_control('radio_bookmark',true);  // This sort of works if !wid.p_mdi_child
         set_control('radio_offset',true);
         if (wid.p_mdi_child) {
            set_control('radio_error',true);
            set_control('radio_definition',true);
            set_control('radio_declaration',true);
            set_control('radio_reference',true);
         } else {
            set_control('radio_error',false);
            set_control('radio_definition',false);
            set_control('radio_declaration',false);
            set_control('radio_reference',false);
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
   int wid=_find_formobj('_goto_form','N');
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
   if (wid.radio_declaration.p_value) {
      call_event('',_control radio_declaration,LBUTTON_UP,'');
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
      msg := "";
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
      msg := "";
      if (status==STRING_NOT_FOUND_RC) {
         msg="No error message files";
      } else {
         msg=get_message(status);
      }
      _message_box("Prev Error failed.\n\n"msg,'Goto Prev Error');
   }
}
//I want to reinitialize the dialog so to something known.
static void activate_error(bool on_off=true)
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
static void set_control(_str control_name,bool on_off)
{
   int wid=_find_formobj('_goto_form','N');
   control_id := wid._find_control(control_name);
   control_id.p_enabled=on_off;
   control_id.p_visible=on_off;
}

