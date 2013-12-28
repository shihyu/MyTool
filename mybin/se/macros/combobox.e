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
#include "listbox.sh"
#include "slick.sh"
#import "clipbd.e"
#import "complete.e"
#import "dlgman.e"
#import "files.e"
#import "mouse.e"
#import "stdprocs.e"
#import "tbprops.e"
#import "util.e"
#endregion

//
//    User level 2 inheritance for COMBO BOX
//
static boolean ignore_completion;

defeventtab _ul2_combobx _inherit _ul2_textbox2;
//def on_vsb_page_down=_sb_page_down;
//def on_vsb_page_up=_sb_page_up;
def on_vsb_top=top_of_buffer;
def on_vsb_bottom=bottom_of_buffer;
//def on_vsb_line_down=fast_scroll;
//def on_vsb_line_up=fast_scroll;
def on_vsb_thumb_pos=_vsb_thumb_pos;
def on_vsb_thumb_track=_vsb_thumb_pos;
def on_sb_end_scroll=fast_scroll;
def on_hsb_line_down=fast_scroll;
def on_hsb_line_up=fast_scroll;
def on_hsb_top=scroll_begin_line;
def on_hsb_bottom=scroll_end_line;
def on_hsb_page_down=_sb_page_right;
def on_hsb_page_up=_sb_page_left;
def on_hsb_thumb_pos=_hsb_thumb_pos;
def on_hsb_thumb_track=_hsb_thumb_pos;
// Need these extra key bindings for emulations sucha as BRIEF
def s_home,s_up,s_pgup,s_left,s_right,s_end,s_down,s_pgdn,'c-s-left','c-s-right'=cua_select;
_ul2_combobx.on_create2()
{
   ignore_completion=false;
}
void _ul2_combobx.rbutton_down,context()
{
   if (p_style==PSCBO_NOEDIT) {
      return;
   }
   call_event(defeventtab _ul2_textbox,RBUTTON_DOWN,'e');
}
void _ul2_combobx.tab()
{
   call_event(_get_form(p_window_id),TAB);
}
void _ul2_combobx.s_tab()
{
   call_event(_get_form(p_window_id),S_TAB);
}
#if 0
void _ul2_combobx.\27-\255()
{
   _str key=last_event();
   if (p_style!=PSCBO_NOEDIT) {
      if (p_cb_active==p_cb_text_box /*||
          (p_style!=PSCBO_LIST_ALWAYS && p_cb_active==p_cb_list_box)*/) {
         p_cb_text_box.keyin(key);
         return;
      }
      if (p_cb_active!=p_cb_list_box) {
         return;
      }
   }
   p_window_id=p_cb_list_box;
   if (p_scroll_left_edge>=0) {
      p_scroll_left_edge= -1;
   }
   save_pos(auto p);
   if (substr(p_cb.p_cb_text_box.p_text,1,1)==substr(_lbget_text(),1,1)) {
      _end_line();
   }
   _str text;
   if (p_picture) {
      text='^?+\:'_escape_re_chars(key);
   } else {
      text='^?'_escape_re_chars(key);
   }
   _str case_sense=p_cb.p_case_sensitive?'e':'i';
   //case_sense='i';
   _str options='@r'case_sense;
   _lbdeselect_line();
   int status=search(text,options);
   _no_change= p_cb;
   if (status) {
      _lbtop();
      status=search(text,options);
      if (status) {
         restore_pos(p);
      } else {
         p_cb.p_text=_lbget_text();
      }
   } else {
      p_cb.p_text=_lbget_text();
   }
   _lbselect_line();
   p_window_id=p_cb;
   if (p_cb_list_box.p_visible) {
      call_event(CHANGE_CLINE,p_window_id,ON_CHANGE,'');
   } else {
      call_event(CHANGE_CLINE_NOTVIS,p_window_id,ON_CHANGE,'');
      call_event(CHANGE_CLINE_NOTVIS2,p_window_id,ON_CHANGE,'2');
   }
   _no_change=0;
}
#endif
_ul2_combobx.' '()
{
   if (p_style==PSCBO_NOEDIT) return('');
   if (p_completion!='') {
      maybe_complete(p_completion);
      return('');
   }
   keyin(' ');
}
_ul2_combobx.'?'()
{
   if (p_style==PSCBO_NOEDIT) return('');
   if (p_completion!='' && def_qmark_complete) {
      maybe_list_matches(p_completion,'',false,1);
      return('');
   }
   keyin('?');
}
void _ul2_combobx.on_change2()
{
   if (ignore_completion) return;
   if (p_style==PSCBO_EDIT && p_completion!='') {
      ArgumentCompletionUpdateTextBox();
   }
}

void _ul2_combobx.on_highlight()
{
   return;
}

// needed here because _ul2_textbox2 handles these keys and we need to trap them for noedit controls
_ul2_combobx.C_X()
{
   if (p_style!=PSCBO_NOEDIT) {
      cut();
   }
}
_ul2_combobx.C_V()
{
   if (p_style!=PSCBO_NOEDIT) {
      paste();
   }
}

/** 
 * <p>not_finished. We need to remove this function.
 * <p> 
 * Searches for combo box text (<b>p_text</b>) in the combo box list starting from 
 * the beginning of the list.  This function is typically used to check if the users 
 * input is valid or adjust the current line in the combo box list after more items 
 * have been added.  Search is case insensitive by default.  Set the <b>p_case_sensitive</b> 
 * property to <b>true</b> if you want a case sensitive search.  Normally the search is 
 * considered successful if a line that begins with <b>p_text</b> is found.  To search 
 * for an exact match, specify '$' for the second argument.
 * 
 * @param case_sense       'e' for a case-sensitive search, 'i' for case-insensitive
 * @param search_string    pass '$' for an exact match
 * 
 * @example
 * <pre>
 * defeventtab form1;
 * void ok.lbutton_up()
 * {
 *      // Check if text in combo box is valid.  You might think you could use a
 *      // non-editable style combo box.  However, many users prefer typing in
 *      // names using completion, to using the mouse to select an item out
 *      // of a list box.
 *      status=_cbi_search('','$');
 *      if (status) {
 *           _message_box("Combo box contains invalid input");
 *           return;
 *      }
 *       // have valid input
 *       ....    
 * }
 * command1.lbutton_up()
 * {
 *      // Add some items to the combo box list
 *      combo1.p_cb_list_box._lbadd_item("Hello")
 *      combo1.p_cb_list_box._lbadd_item("Open");
 *      combo1.p_cb_list_box._lbadd_item("New");
 *      // Make the correct item in the combo box list is current so combo box
 *      // retrieval works better.
 *      status=combo1._cbi_search('','$');
 *      if (!status) {
 *           messageNwait("Found it!");
 *           // Select the line in the combo box so that an up or down arrow
 *           // selects the line above or below and not the current line.
 *           combo1.p_cb_list_box._lbselect_line();
 *      }
 * }
 * </pre>
 * 
 * @return  Returns 0 if text in combo box is found.
 * 
 * @appliesTo  Combo_Box
 * 
 * @categories Combo_Box_Methods
 */
int _cbi_search(_str case_sense='', _str search_string='')
{
   save_search(auto a,auto b,auto c,auto d);
   if (case_sense == '') {
      case_sense = p_case_sensitive? 'e':'i';
   }
   if (_lbisline_selected()) {
      _lbdeselect_line();
   }
   //  IF the text box has a picture, use regular expression to match
   //  text
   _str text;
   text='^'_escape_re_chars(p_text);
   if (p_style==PSCBO_NOEDIT) text=text:+'$';
   _str options='@r'case_sense;
   top();
   int status=search(text:+search_string,options);
   restore_search(a,b,c,d);
   return(status);
}
extern void _ComboBoxCommand(_str command);

void _ul2_combobx.down()
{
   ignore_completion=true;
   _ComboBoxCommand('down');
   ignore_completion=false;
}
void _ul2_combobx.up()
{
   ignore_completion=true;
   _ComboBoxCommand('up');
   ignore_completion=false;
}
void _ul2_combobx.pgup()
{
   _ComboBoxCommand('pageup');
}
void _ul2_combobx.pgdn()
{
   _ComboBoxCommand('pagedown');
}
_ul2_combobx.c_home()
{
   _ComboBoxCommand('c-home');
}
_ul2_combobx.c_end()
{
   _ComboBoxCommand('c-end');
}
_ul2_combobx.home()
{
   _ComboBoxCommand('home');
}
_ul2_combobx.end()
{
   _ComboBoxCommand('end');
}
_ul2_combobx.f4()
{
   _ComboBoxCommand('f4');
}
void _ul2_combobx.lbutton_double_click()
{
}
void _ul2_combobx.lbutton_down,"c_lbutton_down"()
{
   if (_tbInDragDropCtlMode()) {
      _tbDragDropCtl();
      return;
   }
}

