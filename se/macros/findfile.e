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

_form _find_file_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption='Find File';
   p_forecolor=0x80000008;
   p_height=7440;
   p_width=6180;
   p_x=5432;
   p_y=3360;
   _label label1 {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='&File pattern:';
      p_forecolor=0x80000008;
      p_height=196;
      p_tab_index=1;
      p_width=924;
      p_word_wrap=false;
      p_x=120;
      p_y=207;
   }
   _combo_box _file_pattern {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_case_sensitive=false;
      p_completion=NONE_ARG;
      p_forecolor=0x80000008;
      p_height=280;
      p_style=PSCBO_EDIT;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=3714;
      p_x=1185;
      p_y=165;
      p_eventtab2=_ul2_combobx;
   }
   _command_button _search {
      p_auto_size=false;
      p_cancel=false;
      p_caption='&Search';
      p_default=true;
      p_height=378;
      p_tab_index=3;
      p_tab_stop=true;
      p_width=1078;
      p_x=4980;
      p_y=135;
   }
   _label ctllabel1 {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='&Directory:';
      p_forecolor=0x80000008;
      p_height=196;
      p_tab_index=4;
      p_width=742;
      p_word_wrap=false;
      p_x=120;
      p_y=597;
   }
   _combo_box _search_dir_list {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_case_sensitive=false;
      p_completion=DIRNOQUOTES_ARG;
      p_forecolor=0x80000008;
      p_height=280;
      p_style=PSCBO_EDIT;
      p_tab_index=5;
      p_tab_stop=true;
      p_width=3720;
      p_x=1185;
      p_y=555;
      p_eventtab2=_ul2_combobx;
   }
   _image ctlBrowsedir {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_forecolor=0x80000008;
      p_height=280;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='bbbrowse.svg';
      p_stretch=false;
      p_style=PSPIC_BUTTON;
      p_tab_index=6;
      p_tab_stop=true;
      p_value=0;
      p_width=280;
      p_x=4980;
      p_y=555;
      p_eventtab2=_ul2_imageb;
   }
   _label label5 {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='&Search string:';
      p_forecolor=0x80000008;
      p_height=196;
      p_tab_index=8;
      p_width=1050;
      p_word_wrap=false;
      p_x=120;
      p_y=1016;
   }
   _text_box _search_string {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_completion=NONE_ARG;
      p_forecolor=0x80000008;
      p_height=280;
      p_tab_index=9;
      p_tab_stop=true;
      p_width=3375;
      p_x=1185;
      p_y=974;
      p_eventtab2=_ul2_textbox;
   }
   _image ctlremenu {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_command='_re_menu';
      p_forecolor=0x80000008;
      p_height=280;
      p_max_click=MC_SINGLE;
      p_Nofstates=2;
      p_picture='bbmenu.svg';
      p_stretch=false;
      p_style=PSPIC_BUTTON;
      p_tab_index=10;
      p_value=0;
      p_width=280;
      p_x=4650;
      p_y=974;
      p_eventtab2=_ul2_imagebmenu;
   }
   _label label2 {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='Files f&ound:';
      p_forecolor=0x80000008;
      p_height=196;
      p_tab_index=11;
      p_width=868;
      p_word_wrap=false;
      p_x=120;
      p_y=2793;
   }
   _frame frame2 {
      p_backcolor=0x80000005;
      p_caption='Search o&ptions';
      p_forecolor=0x80000008;
      p_height=1224;
      p_tab_index=12;
      p_width=3360;
      p_x=120;
      p_y=1386;
      _check_box _findre {
         p_alignment=AL_LEFT;
         p_auto_size=false;
         p_backcolor=0x80000005;
         p_caption='Regular expression search';
         p_enabled=false;
         p_forecolor=0x80000008;
         p_height=262;
         p_style=PSCH_AUTO2STATE;
         p_tab_index=12;
         p_tab_stop=true;
         p_value=0;
         p_width=2832;
         p_x=255;
         p_y=288;
      }
      _check_box _word_search {
         p_alignment=AL_LEFT;
         p_auto_size=false;
         p_backcolor=0x80000005;
         p_caption='Word search';
         p_enabled=false;
         p_forecolor=0x80000008;
         p_height=262;
         p_style=PSCH_AUTO2STATE;
         p_tab_index=13;
         p_tab_stop=true;
         p_value=0;
         p_width=1536;
         p_x=255;
         p_y=564;
      }
      _check_box _case_search {
         p_alignment=AL_LEFT;
         p_auto_size=false;
         p_backcolor=0x80000005;
         p_caption='Case-sensitive search';
         p_enabled=false;
         p_forecolor=0x80000008;
         p_height=262;
         p_style=PSCH_AUTO2STATE;
         p_tab_index=14;
         p_tab_stop=true;
         p_value=0;
         p_width=2364;
         p_x=255;
         p_y=840;
      }
   }
   _list_box _file_list {
      p_border_style=BDS_FIXED_SINGLE;
      p_height=1815;
      p_multi_select=MS_EXTENDED;
      p_scroll_bars=SB_VERTICAL;
      p_tab_index=13;
      p_tab_stop=true;
      p_width=5940;
      p_x=120;
      p_y=3045;
      p_eventtab2=_ul2_listbox;
   }
   _check_box _openreadonly {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_caption='&Read only';
      p_forecolor=0x80000008;
      p_height=300;
      p_style=PSCH_AUTO3STATEA;
      p_tab_index=14;
      p_tab_stop=true;
      p_value=2;
      p_width=1248;
      p_x=180;
      p_y=4917;
   }
   _command_button _open {
      p_auto_size=false;
      p_cancel=false;
      p_caption='&Open';
      p_default=false;
      p_enabled=false;
      p_height=378;
      p_tab_index=15;
      p_tab_stop=true;
      p_width=1078;
      p_x=120;
      p_y=5310;
   }
   _command_button _cancel {
      p_auto_size=false;
      p_cancel=true;
      p_caption='&Cancel';
      p_default=false;
      p_height=378;
      p_tab_index=16;
      p_tab_stop=true;
      p_width=1078;
      p_x=1260;
      p_y=5310;
   }
   _command_button _help {
      p_auto_size=false;
      p_cancel=false;
      p_caption='&Help';
      p_default=false;
      p_height=378;
      p_help='find file dialog box';
      p_tab_index=17;
      p_tab_stop=true;
      p_width=1078;
      p_x=2400;
      p_y=5310;
   }
   _command_button _delete {
      p_auto_size=false;
      p_cancel=false;
      p_caption='&Delete';
      p_default=false;
      p_enabled=false;
      p_height=378;
      p_tab_index=18;
      p_tab_stop=true;
      p_width=1078;
      p_x=3540;
      p_y=5310;
   }
   _command_button _openadv {
      p_auto_size=false;
      p_cancel=false;
      p_caption='&Advanced >>';
      p_default=false;
      p_height=378;
      p_tab_index=19;
      p_tab_stop=true;
      p_width=1358;
      p_x=4680;
      p_y=5310;
   }
   _label _number_selected {
      p_alignment=AL_RIGHT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='Number selected';
      p_forecolor=0x80000008;
      p_height=240;
      p_tab_index=20;
      p_width=2940;
      p_word_wrap=false;
      p_x=3120;
      p_y=4953;
   }
   _check_box _openexpand {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_caption='&Expand tabs';
      p_forecolor=0x80000008;
      p_height=262;
      p_style=PSCH_AUTO3STATEA;
      p_tab_index=21;
      p_tab_stop=true;
      p_value=2;
      p_width=1500;
      p_x=120;
      p_y=5790;
   }
   _check_box _openlock {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_caption='File &locking';
      p_forecolor=0x80000008;
      p_height=262;
      p_style=PSCH_AUTO3STATEA;
      p_tab_index=22;
      p_tab_stop=true;
      p_value=2;
      p_width=1476;
      p_x=120;
      p_y=6090;
   }
   _check_box _openpreload {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_caption='Preload file';
      p_forecolor=0x80000008;
      p_height=262;
      p_style=PSCH_AUTO3STATEA;
      p_tab_index=23;
      p_tab_stop=true;
      p_value=2;
      p_width=1356;
      p_x=120;
      p_y=6390;
   }
   _check_box _openbinary {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_caption='&Binary';
      p_forecolor=0x80000008;
      p_height=262;
      p_style=PSCH_AUTO3STATEA;
      p_tab_index=24;
      p_tab_stop=true;
      p_value=2;
      p_width=1236;
      p_x=120;
      p_y=6690;
   }
   _check_box _opennewwin {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_caption='New window';
      p_forecolor=0x80000008;
      p_height=262;
      p_style=PSCH_AUTO3STATEA;
      p_tab_index=25;
      p_tab_stop=true;
      p_value=2;
      p_width=1536;
      p_x=120;
      p_y=6990;
   }
   _frame frame1 {
      p_backcolor=0x80000005;
      p_caption='File format';
      p_forecolor=0x80000008;
      p_height=1440;
      p_tab_index=26;
      p_width=4080;
      p_x=1680;
      p_y=5790;
      _radio_button _opendos {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='DOS';
         p_forecolor=0x80000008;
         p_height=262;
         p_tab_index=26;
         p_tab_stop=true;
         p_value=0;
         p_width=840;
         p_x=120;
         p_y=360;
      }
      _radio_button _openmac {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='Mac';
         p_forecolor=0x80000008;
         p_height=262;
         p_tab_index=27;
         p_tab_stop=true;
         p_value=0;
         p_width=840;
         p_x=960;
         p_y=360;
         p_eventtab=_find_file_form._opendos;
      }
      _radio_button _openunix {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='UNIX';
         p_forecolor=0x80000008;
         p_height=262;
         p_tab_index=28;
         p_tab_stop=true;
         p_value=0;
         p_width=840;
         p_x=1800;
         p_y=360;
         p_eventtab=_find_file_form._opendos;
      }
      _radio_button _openauto {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='Automatic';
         p_forecolor=0x80000008;
         p_height=262;
         p_tab_index=29;
         p_tab_stop=true;
         p_value=1;
         p_width=1224;
         p_x=2760;
         p_y=360;
         p_eventtab=_find_file_form._opendos;
      }
      _label label3 {
         p_alignment=AL_RIGHT;
         p_auto_size=false;
         p_backcolor=0x80000005;
         p_border_style=BDS_NONE;
         p_caption='Line separator char (decimal)';
         p_forecolor=0x80000008;
         p_height=240;
         p_tab_index=30;
         p_width=2796;
         p_word_wrap=false;
         p_x=165;
         p_y=740;
      }
      _text_box _openlinesep {
         p_auto_size=true;
         p_backcolor=0x80000005;
         p_border_style=BDS_FIXED_SINGLE;
         p_completion=NONE_ARG;
         p_forecolor=0x80000008;
         p_height=280;
         p_tab_index=31;
         p_tab_stop=true;
         p_width=720;
         p_x=3240;
         p_y=720;
         p_eventtab2=_ul2_textbox;
      }
      _label label4 {
         p_alignment=AL_RIGHT;
         p_auto_size=false;
         p_backcolor=0x80000005;
         p_border_style=BDS_NONE;
         p_caption='Record width';
         p_forecolor=0x80000008;
         p_height=240;
         p_tab_index=32;
         p_width=2076;
         p_word_wrap=false;
         p_x=885;
         p_y=1100;
      }
      _text_box _openwidth {
         p_auto_size=true;
         p_backcolor=0x80000005;
         p_border_style=BDS_FIXED_SINGLE;
         p_completion=NONE_ARG;
         p_forecolor=0x80000008;
         p_height=280;
         p_tab_index=33;
         p_tab_stop=true;
         p_width=720;
         p_x=3240;
         p_y=1080;
         p_eventtab2=_ul2_textbox;
      }
   }
}

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
   rightAlign := _file_pattern.p_x_extent;
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
_command void old_find_file() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
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
   file_type := "";
   mask := "";
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
   status := 0;
   _search.p_default = true;
   _open.p_default = false;
   _file_list._lbclear();
   mou_capture();
   p_mouse_pointer=MP_HOUR_GLASS;
   file_dir := _search_dir_list.p_text;
   file_spec := "";
   list := _file_pattern.p_text;
   _maybe_append_filesep(file_dir);
   for (;;) {
      parse list with file_spec';'list;
      if (file_spec == '') {
         break;
      }
      status = _file_list.insert_file_list('-v +tp '_maybe_quote_filename(file_dir:+file_spec));
   }
   _file_list._lbsort(_fpos_case);
   _file_list.bottom();
   unenable();
   total_files = _file_list.p_line;
   _file_list.p_line = 1;
   _number_selected.p_caption = _file_list.p_nofselected' of 'total_files' selected';
   if (total_files > 0) {
      _number_selected.p_visible = true;//Needn't show up if there are no files
   }
   //p_window_id = _open;_set_focus();
   //_open,p_default = 0;
   _open.p_default = true;

   /*Form auto-sizing*/
   p_window_id=_file_list;
   width := _find_longest_line();
   int cwidth=_dx2lx(p_xyscale_mode,p_client_width);
   if (width>cwidth) {
      int diff_x=width-cwidth;
      p_active_form.p_width += diff_x;
      p_width += diff_x;
   }
   /*End of Form auto-sizing*/

   mou_release();
   _search.p_mouse_pointer=MP_ARROW;
   if (_search_string.p_text!='') {
      search_options := '@';  // Quiet. No messages.
      re := "";
      if (def_re_search_flags&PERLRE_SEARCH) {
         re = 'l';
      //} else if ( def_re_search_flags&BRIEFRE_SEARCH ) {
      //   re = 'b';
      } else {
         re = 'r';
      }
      search_options=(_findre.p_value)?search_options:+re:search_options;
      search_options=(_word_search.p_value)?search_options'w':search_options;
      search_options=(!_case_search.p_value)?search_options'i':search_options;
      go_down := true;
      _file_list._lbtop();_file_list._lbup();
      //mdi_buf_id=_mdi.p_child.p_buf_id;
      _default_option('x',1);
      for (;;) {
         if (go_down) {
            if (_file_list._lbdown()) {
               break;
            }
         }
         go_down=true;
         if (_file_list._lbget_text()=='') {
            break;
         }
         _str filename=_file_list._lbget_text();

         temp_view_id := 0;
         orig_view_id := 0;
         status=_open_temp_view(filename,temp_view_id,orig_view_id);
         if (!status) {
            wid := p_window_id;
            activate_window(orig_view_id);
            wid.top();
            status=wid.search(_search_string.p_text, search_options);
            _delete_temp_view(temp_view_id);
         }
         if (status) {
            _file_list._lbdelete_item();
            go_down=false;
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
   wid := p_window_id;
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
   _openexpand.p_enabled=true;
   _openbinary.p_enabled=true;
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
      _openexpand.p_enabled=false;
      _openbinary.p_enabled=false;
   }
}
void _file_list.on_change()
{
   total_files = p_Noflines;
   _number_selected.p_caption = p_nofselected' of 'total_files' selected';
   if (_file_list.p_nofselected > 0) {
      _open.p_enabled = _delete.p_enabled = _openreadonly.p_enabled=true;
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
   _open.p_enabled = _delete.p_enabled = false;
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
   int status=_file_list._lbfind_selected(true);
   for (;;) {
      if (status) break;
      _str file_name=_file_list._lbget_text();
      status=_file_list._lbdelete_item();
      delete_file(file_name);
      if (status) break;
      _file_list.up();
      status=_file_list._lbfind_selected(false);
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
   _search.p_default = true;
   _open.p_default = false;
}

