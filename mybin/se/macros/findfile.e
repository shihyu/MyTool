////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47140 $
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
#import "complete.e"
#import "dlgman.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "recmacro.e"
#import "sellist.e"
#import "stdprocs.e"
#endregion

static _str total_files = 0;


/** 
 * Displays <b>Find File dialog box</b> used to search for open files.
 * 
 * @return  Returns string which should be used as input to the <b>edit</b> 
 * command.  If '' is returned, the user cancelled the dialog box.
 * @example
 * <pre>
 * #include "slick.sh"
 * defmain()
 * {
 *     result = show('-modal _find_file_form');
 *     if (result == '') {
 *        return(COMMAND_CANCELLED_RC);
 *     }
 *     return(edit(result))
 * }
 * </pre>
 * @categories Forms
 */
defeventtab _find_file_form;


/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _find_file_form_initial_alignment()
{
   rightAlign := _file_pattern.p_x + _file_pattern.p_width;
   sizeBrowseButtonToTextBox(_search_dir_list.p_window_id, ctlBrowsedir.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(_search_string.p_window_id, ctlremenu.p_window_id, 0, rightAlign);
}

/**
 * Displays the Find File dialog box which lets you find and open one or more 
 * files for editing.
 * 
 * @appliesTo  Edit_Window
 * @categories File_Functions
 */
_command void find_file() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
{
   _macro_delete_line();
   typeless result=show('-modal _find_file_form');
   if (result=='') {
      return;
   }
   p_window_id=_mdi._edit_window();
   _macro('m',_macro('s'));
   _macro_call('edit',result);
   edit(result, EDIT_DEFAULT_FLAGS);
}

static void _update_find_file_lists()
{
   int orig_wid; get_window_id(orig_wid);
   _str file_type = '';
   _str mask = '';
   _str list = def_file_types;

   activate_window(_file_pattern.p_window_id);
   _lbdeselect_all();
   _lbclear();
   _retrieve_list();
   _lbbottom();
   for (;;) {
      parse list with file_type ',' list;
      if (file_type == '') {
         break;
      }
      parse file_type with . '(' mask ')';
      _lbadd_item(mask);
   }
   _lbremove_duplicates();
   _lbtop();
   if (p_text == '') {
      p_text = _lbget_text();
   }
   activate_window(_search_dir_list.p_window_id);
   _lbdeselect_all();
   _lbclear();
   _retrieve_list();
   if (p_text == '') {
      p_text=getcwd();
   }
   activate_window(orig_wid);
}

_search.on_create()
{
   _find_file_form_initial_alignment();
   _update_find_file_lists();
   _openadv._dmless();
   _number_selected.p_caption = _file_list.p_Nofselected' of 0 selected';
}

_search_string.on_change()
{
   _findre.p_enabled = _word_search.p_enabled = _case_search.p_enabled = (p_text != '');
}

_search.lbutton_up()
{
   int status=0;
   _search.p_default = 1;
   _open.p_default = 0;
   _file_list._lbclear();
   mou_capture();
   p_mouse_pointer=MP_HOUR_GLASS;
   _str file_dir = _search_dir_list.p_text;
   _str file_spec='';
   _str list = _file_pattern.p_text;
   _maybe_append_filesep(file_dir);
   for (;;) {
      parse list with file_spec';'list;
      if (file_spec == '') {
         break;
      }
      status = _file_list.insert_file_list('-v +tp 'maybe_quote_filename(file_dir:+file_spec));
   }
   _file_list._lbsort(_fpos_case);
   _file_list.bottom();
   unenable();
   total_files = _file_list.p_line;
   _file_list.p_line = 1;
   _number_selected.p_caption = _file_list.p_nofselected' of 'total_files' selected';
   if (total_files > 0) {
      _number_selected.p_visible = 1;//Needn't show up if there are no files
   }
   //p_window_id = _open;_set_focus();
   //_open,p_default = 0;
   _open.p_default = 1;

   /*Form auto-sizing*/
   p_window_id=_file_list;
   int width=_find_longest_line();
   int cwidth=_dx2lx(p_xyscale_mode,p_client_width);
   if (width>cwidth) {
      int diff_x=width-cwidth;
      p_active_form.p_width=p_active_form.p_width+diff_x;
      p_width=p_width+diff_x;
   }
   /*End of Form auto-sizing*/

   mou_release();
   _search.p_mouse_pointer=MP_ARROW;
   if (_search_string.p_text!='') {
      _str search_options='@';  // Quiet. No messages.
      _str re='';
      if (def_re_search==UNIXRE_SEARCH) {
         re = 'u';
      } else if ( def_re_search==BRIEFRE_SEARCH ) {
         re = 'b';
      } else {
         re = 'r';
      }
      search_options=(_findre.p_value)?search_options:+re:search_options;
      search_options=(_word_search.p_value)?search_options'w':search_options;
      search_options=(!_case_search.p_value)?search_options'i':search_options;
      boolean go_down=1;
      _file_list._lbtop();_file_list._lbup();
      //mdi_buf_id=_mdi.p_child.p_buf_id;
      _default_option('x',1);
      for (;;) {
         if (go_down) {
            if (_file_list._lbdown()) {
               break;
            }
         }
         go_down=1;
         if (_file_list._lbget_text()=='') {
            break;
         }
         _str filename=_file_list._lbget_text();

         int temp_view_id=0;
         int orig_view_id=0;
         status=_open_temp_view(filename,temp_view_id,orig_view_id);
         if (!status) {
            int wid=p_window_id;
            activate_window(orig_view_id);
            wid.top();
            status=wid.search(_search_string.p_text, search_options);
            _delete_temp_view(temp_view_id);
         }
         if (status) {
            _file_list._lbdelete_item();
            go_down=0;
         }
      }
      _default_option('x',0);
      //_mdi.p_child.p_buf_id=mdi_buf_id;
      _file_list.bottom();
      total_files = _file_list.p_line;
      unenable();
      _number_selected.p_caption = _file_list.p_nofselected' of 'total_files' selected';
      _file_list._lbtop();
   }
   _append_retrieve(_control _file_pattern, _file_pattern.p_text);
   _append_retrieve(_control _search_dir_list, _search_dir_list.p_text);
   _update_find_file_lists();
}

void ctlBrowsedir.lbutton_up()
{
   int wid=p_window_id;
   typeless result = _ChooseDirDialog('',_search_dir_list.p_text);
   if ( result=='' ) {
      return;
   }
   p_window_id=_search_dir_list.p_window_id;
   p_text=result;
   end_line();
   _set_focus();
   return;
}

void _openadv.lbutton_up()
{
   _dmmoreless();
}

void _opendos.lbutton_up()
{
   zap_format_fields();
}

static zap_format_fields()
{
   _openlinesep.p_text='';
   _openwidth.p_text='';
   _openexpand.p_enabled=1;
   _openbinary.p_enabled=1;
}

void _openlinesep.on_change()
{
   if (p_text!='') {
      zap_radio_buttons();
      _openwidth.p_text='';
   }
}

void _openwidth.on_change()
{
   if (p_text!='') {
      _openlinesep.p_text='';
      zap_radio_buttons();
      _openexpand.p_enabled=0;
      _openbinary.p_enabled=0;
   }
}
void _file_list.on_change()
{
   total_files = p_Noflines;
   _number_selected.p_caption = p_nofselected' of 'total_files' selected';
   if (_file_list.p_nofselected > 0) {
      _open.p_enabled = _delete.p_enabled = _openreadonly.p_enabled=1;
   }else{
      unenable();
   }
}

static zap_radio_buttons()
{
   _opendos.p_value=0;
   _openmac.p_value=0;
   _openunix.p_value=0;
   _openauto.p_value=0;
}

static void unenable()
{
   _open.p_enabled = _delete.p_enabled = 0;
}

_open.lbutton_up()
{
   _str switches=_edit_get_switches();
   _str ret_val = _file_list._lbmulti_select_result();
   if (ret_val == '') {
      _message_box('No Files are Selected');
      return('');
   }
   _param1 = _openreadonly.p_value;
   _param2 = _file_pattern.p_text;
   p_active_form._delete_window(switches' ':+ret_val);
}

_delete.lbutton_up()
{
   int result = _message_box(nls("Delete "_file_list.p_Nofselected" Files \n\n Are You Sure?"),'',MB_YESNOCANCEL|MB_ICONQUESTION);
   if (result == IDCANCEL || result == IDNO) {
      return('');
   }
   int status=_file_list._lbfind_selected(1);
   for (;;) {
      if (status) break;
      _str file_name=_file_list._lbget_text();
      status=_file_list._lbdelete_item();
      delete_file(file_name);
      if (status) break;
      _file_list.up();
      status=_file_list._lbfind_selected(0);
   }
   _file_list.call_event(CHANGE_OTHER, _file_list, ON_CHANGE, "W");
}

_file_list.lbutton_double_click()
{
   get_event('B');
   _open.call_event(_open, LBUTTON_UP);
}

void _file_pattern.on_change(int reason)
{
   _search.p_default = 1;
   _open.p_default = 0;
}

