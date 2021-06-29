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
#import "error.e"
#import "main.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

/**
 * Displays the build window in a popup edit window and allows 
 * you to go to a specific error location.
 * 
 * @see next_error
 * @see cursor_error
 * @see project_compile
 * @see project_build
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Miscellaneous_Functions
 * 
 */
_command list_errors()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI)
{
   if ( _error_file=='' ) {
      _error_file=absolute(COMPILE_ERROR_FILE);
      //_error_file=absolute(GetErrorFilename())
   }
   _str error_name=_error_file;

   temp_view_id := 0;
   orig_view_id := p_window_id;
   int status = _activate_error_file(auto mark, temp_view_id,auto is_process_mark,auto top_mark);
   if (status) {
      message(nls('No error messages'));
      return(status);
   }
   error_name=p_buf_name;
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   typeless result=show('_showerrfile_form -modal');
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   if ( result!='' ) {
      int line_number=result;
      status=_open_temp_view(error_name,temp_view_id,orig_view_id,'+b');
      if (!status) {
         p_line=line_number;
         _begin_line();set_next_error();
         _delete_temp_view();
         activate_window(orig_view_id);
      }
      next_error();
   }
}
// Number of lines
static const FAST_FIND_LONGEST= 400;
// Default width in twips
static const DEFAULT_WIDTH=     9000;
// Mininum width of form in twips
static const MIN_WIDTH=         6000;
// Twips
static const PAD_INSIDE_LIST=   1000;

defeventtab _showerrfile_form;
list1.a_h()
{
   _help.call_event(_help,LBUTTON_UP);
}
list1.enter()
{
   _ok.call_event(_ok,LBUTTON_UP);
}
list1.on_destroy()
{
   typeless readonly_mode;
   typeless mode_eventtab;
   parse list1.p_user with readonly_mode mode_eventtab .;
   p_readonly_mode=readonly_mode;
   p_mode_eventtab=mode_eventtab;
}
list1.on_create()
{
   _use_edit_font();
   if ( _error_file=='' ) {
      _error_file=absolute(COMPILE_ERROR_FILE);
      //_error_file=absolute(GetErrorFilename())
   }
   orig_buf_id:=p_buf_id;
   orig_view_id := p_window_id;
   int status = _activate_error_file(auto mark, auto temp_view_id,auto is_process_mark,auto top_mark);
   if (status) {
      //_ok.p_enabled=false;
      message(nls('No error messages'));
      p_active_form._delete_window('');
      return(status);
   }
   int buf_id=p_buf_id;
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   status=load_files('+m +bi 'orig_buf_id);
   _delete_buffer();
   status=load_files('+m +bi 'buf_id);
   //p_user=p_mode_eventtab;
   list1.p_user=p_readonly_mode' 'p_mode_eventtab;
   read_only_mode();p_mode_eventtab=_default_keys;
   longest := 0;
   if (p_Noflines<FAST_FIND_LONGEST) {
      longest=_find_longest_line();
   } else {
      longest=DEFAULT_WIDTH;
   }
   form_wid := p_active_form;
   int screen_x,screen_y,screen_width,screen_height;
   _GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
   int max_width=_dx2lx(SM_TWIP,screen_width)-100;
   junk := 0;
   _lxy2lxy(SM_TWIP,form_wid.p_xyscale_mode,max_width,junk);
   int client_width=form_wid.p_client_width;
   _dxy2lxy(form_wid.p_xyscale_mode,client_width);
   int border_widtht2=form_wid.p_width-client_width;
   int form_width=PAD_INSIDE_LIST+longest+p_x*2+border_widtht2;
   if (form_width>max_width) {
      form_width=max_width;
   }
   if (form_width<MIN_WIDTH) form_width=MIN_WIDTH;
   form_wid.p_width=form_width;
   p_width=_dx2lx(p_xyscale_mode,form_wid.p_client_width)-(border_widtht2 intdiv 2)-p_x*2;
   //messageNwait('form_width='form_width' p_width='p_width)
   //is_process_buffer=_process_info('b')
   if ( mark!='' ) {
      if ( _select_type(mark)=='' ) {
         top();_select_char(mark);
      } else {
         _begin_select(mark);
         line := "";
         get_line(line);
         line_to_top();
         // Are we past the end of the line?
         if (p_col>text_col(line)) {
            down();_begin_line();
         }
      }
   }
}
_ok.lbutton_up()
{
   p_active_form._delete_window(list1.p_line);
}

