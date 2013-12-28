////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49653 $
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
#import "complete.e"
#import "guiopen.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "saveload.e"
#import "sellist.e"
#import "stdprocs.e"
#endregion
/*
    callbacks

       When dialog initialized, before autosizing dialog

          status=callback(SL_ONINITFIRST,result.'');

       When dialog initialized

          status=callback(SL_ONINIT,result,'')

       When default button pressed

          status=callback(SL_ONDEFAULT,result,'')

       When key pressed while list is active that is not
       processed by the list.

          status=callback(SL_ONLISTKEY,result,key)

       When user button pressed
          status=callback(SL_ONUSERBUTTON,result,button_number)

       When number of selected item change

          status=callback(SL_ONSELECT,result,'')

*/
#define PAD_LONGEST_LINE   400  // Include scroll bars
#define PAD_BUTTON_WIDTH   300
#define PAD_AFTER_BUTTON   100
#define PAD_AFTER_LIST     100
#define PAD_BELOW_BUTTON   100
#define PAD_BELOW_LIST     60
#define MIN_BUTTON_WIDTH   1080
#define BUTTON_HEIGHT      372
#define MIN_LIST_WIDTH     2100
#define SL_ISEARCH         0x10000

#define SELLIST_DATA  _sellist.p_user
#define RE_SKIP  p_active_form.p_user


   _list_box _sellist
   _command_button _sellistok
   _label _selnofselected
   _combo_box _sellistcombo;

    static _str ignore_change=0;
defeventtab _sellist_form;

/**
 * Determines what the caption will be for a button
 */
static _str get_button_caption(_str button)
{
   parse button with button ':' .;
   return stranslate(button,'','&');
}

/**
 * Searches a comma delimited button list for a button that has
 * the specified caption
 */
static boolean contains_button(_str buttons,_str caption)
{
   caption = get_button_caption(caption);

   _str button;

   parse buttons with button ',' buttons;

   while (button:!='') {
      if (caption:==get_button_caption(button)) {
         return true;
      }

      parse buttons with button ',' buttons;
   }

   return false;
}

/**
 * Displays a selection list.
 *
 * @categories Forms
 * @param title      Title of dialog box.
 * @param flags      Combination of the following flags defined in
 *                   "slick.sh":
 *
 *                   <dl>
 *                   <dt>SL_ALLOWMULTISELECT</dt><dd>Allow multiple items to be selected.  Multiple
 *                   items are separated with space characters.  If an
 *                   item contains spaces, double quotes are placed
 *                   around the item.Currently this function does not
 *                   support items which contain double quotes.  If the
 *                   return string is longer than 200characters, a
 *                   "@<i>buffer_name</i>" string is returned.  The
 *                   buffer <i>buffer_name</i> contains the items
 *                   selected.</dd>
 *
 *                   <dt>SL_NOTOP</dt><dd>Don't position cursor at top of list.</dd>
 *
 *                   <dt>SL_VIEWID</dt><dd>Indicates that
 *                   <i>input_data</i> is a window id.
 *                   </dd>
 *
 *                   <dt>SL_FILENAME</dt><dd>Indicates that <i>input_data</i> is a filename that should be
 *                   loaded and placed in the list box.  File must contain blanks in
 *                   column one.</dd>
 *
 *                   <dt>SL_BUFID</dt><dd>Indicates that <i>input_data</i> is a buffer id.  Buffer is
 *                   deleted unless the SL_NODELETELIST flag given.</dd>
 *
 *                   <dt>SL_NOISEARCH</dt><dd>Indicates whether typing characters while list box is active
 *                   performs incremental searching in the list.</dd>
 *
 *                   <dt>SL_NODELETELIST</dt><dd>No longer has
 *                   any effect</dd>
 *
 *                   <dt>SL_SELECTCLINE</dt><dd>Select the current line in the list box when initializing.</dd>
 *
 *                   <dt>SL_MATCHCASE</dt><dd>Case sensitive incremental searching in  list box.  Has no effect if
 *                   SL_NOISEARCH flag is given.</dd>
 *
 *                   <dt>SL_INVERT</dt><dd>Display Invert button</dd>
 *
 *                   <dt>SL_SELECTALL</dt><dd>Display Select All button.  Must be set if SL_BUTTON_SELECTALL
 *                   is included in the buttons list</dd>
 *
 *                   <dt>SL_HELPCALLBACK</dt><dd>Call the callback routine when the help button is invoked.</dd>
 *
 *                   <dt>SL_DEFAULTCALLBACK</dt><dd>Call the callback routine when default button invoked.</dd>
 *
 *                   <dt>SL_COMBO</dt><dd>Display combo box above list box</dd>
 *
 *                   <dt>SL_MUSTEXIST</dt><dd>Selected item must exist.  Has no effect if
 *                   SL_ALLOWMULTISELECT is given.</dd>
 *
 *                   <dt>SL_DESELECTALL</dt><dd>Deselect all items in list box when initializing.</dd>
 *
 *                   <dt>SL_SIZABLE</dt><dd>Dialog can be resized.</dd>
 *                   </dl>
 * @param list_data
 * @param buttons    Comma delimited string of button captions (<b>p_caption</b>).
 *                   The buttons appear to the right of the list box. Cancel, and Help button are
 *                   inserted after the first button in the list if there positions are explicitly
 *                   specified.  The first button is the default button.  If buttons is '', a default
 *                   button of OK is used.  A button may be given a control name (p_name) by appending
 *                   colon and the control name.  This allows for easier access to the control in the
 *                   call back function.  The control name for the default button is always
 *                   "_sellistok" and may not be changed.   This parameter may be '' to specify OK,
 *                   Cancel, and Help buttons. <i>help_item</i>   Specifies help displayed when F1 is
 *                   pressed or the help button is pressed.  If the <i>help_item</i> starts with a
 *                   '?' character, the characters that follow are displayed in a message box.  The
 *                   help string may also specify a unique keyword in the "vslick.hlp" (UNIX:
 *                   "uvslick.hlp") help file.  The unique keywords for "vslick.hlp" (UNIX:
 *                   "uvslick.hlp") are contained in the file "vslick.lst" (UNIX: "uvslick.lst").  In
 *                   addition, you may specify a unique keyword for any windows help file by specifying
 *                   a string in the format:<br>
 *                   <b><i>keyword</i>:<i>help_filename</i></b>.
 * @param help_item
 * @param font       Font string of the form
 *                   "<i>font_name,font_size, font_flags</i>".
 *                   The font flags are defined in "slick.sh" and
 *                   have the prefix "F_".  <i>font_size</i> is in
 *                   points.  May be '' to specify default list box
 *                   font.
 * @param callback
 * @param separator
 * @param retrieve
 * @param completion
 * @param min_list
 * @param initial_value
 *                   Initial value displayed in combo box.   Useful
 *                   only if combo box is displayed.
 * @param SkipPrefixChars
 *
 * @return Returns '' if the dialog box is cancelled.  Otherwise, the selected item
 *         is returned or the value specified by the call back function is returned.
 * @example
 * _str show('_sellist_form', <i>title</i>, <i>flags</i>, <i>input_data
 * </i>[, <i>buttons</i> [,<i>help_item</i> [,<i>font</i>
 * [,<i>callback_name</i>
 *            [, <i>item_separator</i> [,<i>retrieve_name</i> [,
 * <i>combo_completion</i> [,<i>min_list_width</i>
 * [,<i>initial_value</i> ]]]]]]]]] )
 */
_sellist.on_create(
                    _str title="",
                    typeless flags="",
                    typeless list_data="",
                    _str buttons="",        // Don't include select all,
                                             // cancel, or help buttons
                                             // (Ex  "&Replace", &Add")
                                             // First button is default button.
                    _str help_item="",       // Help item name  (not support yet)
                    _str font="",            // "font-name,size,bold"
                                             // Font for list box
                    typeless callback="",    // Name or index of function
                    _str separator="",       // Item separator for list_data
                    _str retrieve="",        // Retrieve form name.
                                             // Best to give name of command.
                    _str completion="",      // Combo box. Completion property value.
                    typeless min_list="",    // Minimum list width
                    typeless initial_value="",  // Combo box initial value
                    typeless SkipPrefixChars="" // Number of leading characters
                                                // to skip over when searching
                  )
{
   if (SkipPrefixChars!='') {
      RE_SKIP=substr('',1,SkipPrefixChars,'?');
   }
   if (min_list=='') {
      min_list=MIN_LIST_WIDTH;
   }
   if (flags=='') flags=0;
   if (help_item=='') help_item='.';
   if (completion!='') {
      _sellistcombo.p_completion=completion;
      _sellistcombo.p_ListCompletions=false;
   }
   if (retrieve!='') {
      p_active_form.p_name=retrieve;
   }
   _str line="";
   _str name="";
   if (callback=='') {
      callback=0;
   } else if(!_isfunptr(callback)){
      if (!isinteger(callback)) {
         name=callback;
         callback=find_index(callback,PROC_TYPE|COMMAND_TYPE);
         if (!callback) {
            _message_box(nls("_sellist: Call back function '%s', not found",name));
            callback=0;
         }
      }
      callback=name_index2funptr(callback);
   }
   SELLIST_DATA=(flags&~SL_ISEARCH)' 'callback;
   // Delete all column widths if there are any.
   // The UNIX version needs this due to the -reinit option.
   typeless p=0;
   typeless status=0;
   int list_data_buf_id=0;
   int orig_buf_id=0;
   int new_buf_id=0;
   int view_id=0;
   int buf_id=0;
   int wid=0;
   _col_width(-2);
   if (flags & SL_VIEWID) {
      // Copy the data from the buffer.
      // Buffer data is never deleted.
      wid=p_window_id;
      activate_window(list_data);
      //save_pos(p); //line=p_line;left_edge=p_left_edge;col=p_col
      int curline=p_line;
      top();up();
      while(!down()) {
         get_line(line);
         wid.insert_line(line);
      }
      _delete_temp_view();
      p_window_id=wid;
      p_line=curline;
   } else if (flags & SL_BUFID){
      if (flags & SL_NODELETELIST) {
         _buf_transfer(list_data);
      } else {
         _delete_buffer();
         p_buf_id=list_data;
         p_buf_flags |=VSBUFFLAG_DELETE_BUFFER_ON_CLOSE;
      }
      // It is impractical to use the line number of the buffer given, so
      // go to top of buffer.
      top();
   } else if (flags & SL_FILENAME){
      if (list_data=='') {
         _message_box(nls('_sellist_form form called with null filename'));
      } else {
         orig_buf_id=p_buf_id;
         status=load_files(_load_option_encoding(list_data)' 'maybe_quote_filename(list_data));
         if (status) {
            if (status==NEW_FILE_RC) {
               _delete_buffer();
               status=FILE_NOT_FOUND_RC;
            }
            _message_box(nls("_sellist_form form unable to load file '%s'\n"get_message(status),list_data));
         }
         if (p_buf_id!=orig_buf_id) {
            new_buf_id=p_buf_id;
            _prev_buffer();_delete_buffer();
            p_buf_id=new_buf_id;
         }
      }
   } else {
      if (list_data._varformat()==VF_ARRAY || list_data._varformat()==VF_HASHTAB || list_data._varformat()==VF_OBJECT) {
         typeless i;
         for (i._makeempty();;) {
            typeless e=list_data._nextel(i);
            if (i._isempty()) break;
            _lbadd_item(e);
         }
      } else {
         for (;;) {
            line=_parse_line(list_data,separator);
            if (line=='') break;
            _lbadd_item(line);
         }
      }
   }

   if (!(flags & SL_NOTOP)) {
      top();
   //_sellist._lbadd_item("sdlfkj sdf;kjsd f;skjf s;dkfj s;dflkjsd f;lksjdf;slkjf s;dlfkjsd ;flksjf;ls kjf;sldkjf;slkjf;sdlkfjline1sdlfkj sdf;kjsd f;skjf s;dkfj s;dflkjsd f;lksjdf;slkjf s;dlfkjsd ;flksjf;ls kjf;sldkjf;slkjf;sdlkfjline1")
   //_sellist._lbadd_item("sdlfkj sdf;kjsd f;skjf s;dkfj s;dflkjsd f;lksjdf;slkjf s;dlfkjsd ;flksjf;ls kjf;sldkjf;slkjf;")
   }
   if ((flags & SL_DESELECTALL)) {
      p_value=1;
      _lbdeselect_all();
   }
   if ((flags & SL_SELECTCLINE) && !_on_line0()) {
      _lbselect_line();
   }
   if ((flags & SL_ALLOWMULTISELECT)){
      // Take the easy way out.  We want the Nofselected label to be
      // right below the list box.  auto sizing cause this label to be
      // pretty far off.  Could move the label and resize the dialog box
      // instead.
      _sellist.p_auto_size=0;
   }
   if (font=='') {
      font=(_dbcs()?def_qt_jsellist_font:def_qt_sellist_font);
   }
#if 1
   _str font_name="";
   typeless size="", font_flags="";
   parse font with font_name ',' size ',' font_flags ',';
   if (font_name!='') {
      p_font_name=font_name;
   }
   if (size!='') {
      p_font_size=size;
   }
   if (font_flags!='') {
      _font_flags2props(font_flags);
   } else if(font!=''){
      p_font_bold=0;
   }
#else
   _font_string2props(font);
#endif

   _str text="";
   _str rest="";
   if (flags & SL_COLWIDTH) {
      int field1_longest=0;
      save_pos(p);
      top();up();
      while (!down()) {
         get_line(line);
         parse line with text "\t" rest;
         if (_text_width(text)>field1_longest) {
            field1_longest=_text_width(text);
         }

      }
      _col_width(0,field1_longest+100);
      _col_width(-1,1);
      restore_pos(p);
   }
   p_redraw=1;
   if (!(flags & SL_COMBO)) {
      _sellistcombo.p_visible=0;
      int adjust_y=p_y-_sellistcombo.p_y;
      p_y-=adjust_y;
      p_height+=adjust_y;
   } else {
      wid=_sellistcombo;
      int old_height=wid.p_height;
      wid.p_font_name=p_font_name;
      wid.p_font_size=p_font_size;
      wid.p_font_bold=p_font_bold;
      //wid._auto_size  // Force auto size to occur now.
      int adjust_y=wid.p_height-old_height;
      p_y+=adjust_y;
      p_height+=adjust_y;
   }
   if (buttons=='') {
      buttons="OK";
   }
   int selnos_wid=_selnofselected;
   p_multi_select=MS_NONE;
   int form_wid=p_active_form;
   if ((flags & SL_ALLOWMULTISELECT)){
      selnos_wid.p_caption=p_Nofselected' of 'p_Noflines' selected';
      p_multi_select=MS_EXTENDED;
      if ((flags & SL_INVERT)&&(!contains_button(buttons,SL_BUTTON_INVERT))) {
         buttons=buttons","SL_BUTTON_INVERT;
      }
      if ((flags & SL_SELECTALL)&&(!contains_button(buttons,SL_BUTTON_SELECTALL))){
         buttons=buttons","SL_BUTTON_SELECTALL;
      }
   } else {
      // Don't display number of selected label
      selnos_wid.p_visible=0;
      int cy=form_wid.p_height-_dy2ly(form_wid.p_xyscale_mode,form_wid.p_client_height);
      form_wid.p_height=p_y+p_height+cy+PAD_BELOW_LIST;
   }
   _str insert_buttons='';
   if (flags&SL_CLOSEBUTTON) {
      if (!contains_button(buttons,SL_BUTTON_CLOSE)) {
         insert_buttons=SL_BUTTON_CLOSE;
      }
   } else {
      if (!contains_button(buttons,SL_BUTTON_CANCEL)) {
         insert_buttons=SL_BUTTON_CANCEL;
      }
   }
   if (help_item!='.' && !contains_button(buttons,SL_BUTTON_HELP)) {
      if (insert_buttons:!='') {
         strappend(insert_buttons,',');
      }
      strappend(insert_buttons,SL_BUTTON_HELP);
   }
   _str first="";
   parse buttons with first ',' rest;
   if (insert_buttons:!='') {
      buttons=first','insert_buttons','rest;
   }
   // Delete All the buttons except the _sellistok button.
   {
      typeless list_start,i;
      for (list_start=i=_sellist;;) {
         int next=i.p_next;
         if (i.p_object==OI_COMMAND_BUTTON && i.p_name!='_sellistok') {
            //messageNwait('got here caption='i.p_caption);
            i._delete_window();
         }
         i=next;
         if (i==list_start) {
            break;
         }
      }
   }
   // Find length of longest button name
   _str button="";
   int bwidth=0;
   int width=0;
   rest=buttons;
   for (;;) {
      parse rest with button ',' rest ;
      if (button=='') {
         break;
      }
      width=_sellistok._text_width(get_button_caption(button));
      //messageNwait('width='width' c='get_button_caption(button));
      if (width>bwidth) {
         bwidth=width;
      }
   }
   typeless result=0;
   if (callback) {
      result='';
      status=(*callback)(SL_ONINITFIRST,result,'');
      if (status!='') {
         status=(*callback)(SL_ONCLOSE,result,'');
         p_active_form._delete_window(result);
         return('');
      }
   }
   bwidth=bwidth+ PAD_BUTTON_WIDTH;
   int bsh_width,bsh_height;
   _sellistok._size_hint(bsh_width,bsh_height);
   if (bsh_width>bwidth) {
      bwidth=bsh_width;
   }

   int list_width=_find_longest_line()+PAD_LONGEST_LINE;
   if (list_width<min_list) {
      list_width=min_list;
   }
   if (list_width<selnos_wid.p_width) {
      list_width=selnos_wid.p_width;
   }
   form_wid.p_caption=title;
   int cx=form_wid.p_width-_dx2lx(form_wid.p_xyscale_mode,form_wid.p_client_width);
   int cy=form_wid.p_height-_dy2ly(form_wid.p_xyscale_mode,form_wid.p_client_height);
   int form_width=p_x+list_width+PAD_AFTER_LIST+bwidth+PAD_AFTER_BUTTON+cx;
   int screen_x=0, screen_y=0, screen_width=0, screen_height=0;
   form_wid._GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
   int tswidth=_dx2lx(form_wid.p_xyscale_mode,screen_width);
   if (form_width>tswidth) {
      list_width=list_width- (form_width-tswidth);
      form_width=tswidth;
      _sellist.p_scroll_bars=SB_BOTH;
   }
   p_width=list_width;

   if (flags & SL_COMBO) {
      _sellistcombo.p_width=list_width;
   }
   selnos_wid.p_x=p_x+p_width-selnos_wid.p_width;
   form_wid.p_width=form_width;
   form_wid.p_border_style = (flags & SL_SIZABLE) ? BDS_SIZABLE : BDS_DIALOG_BOX;
   _sellistok.p_caption=first;
   int button_x=p_x+list_width+PAD_AFTER_BUTTON;
   _sellistok.p_x=button_x;
   //_message_box('h1');
   _sellistok.p_width=bwidth;
   //say('ok w='_sellistok.p_width' bwidth='bwidth);
   typeless button_eventtab=_sellistok.p_eventtab;
   int prev_button=_sellistok;
   parse buttons with ',' rest ;
   _str button_name="";
   int button_number=0;
   for (button_number=2;;++button_number) {
      parse rest with button ',' rest ;
      if (button=='') {
         break;
      }
      parse button with button ':' button_name ;
      //say('bwidth='bwidth' button='button);
      prev_button=_create_window(OI_COMMAND_BUTTON,form_wid,button,
                    button_x,prev_button.p_y+PAD_BELOW_BUTTON+BUTTON_HEIGHT,
                    bwidth,BUTTON_HEIGHT,
                    CW_CHILD);
      //messageNwait('bwidth='bwidth' c='get_button_caption(button)' w='prev_button.p_width);
      if (prev_button<=0) {
         break;
      }
      if (button_name=='') {
         p_name='b'button_number;
      } else {
         p_name=button_name;
      }
      prev_button._unique_tab_index();
      //if (button=='Cancel') {
      if (button_name=='_sellistcancel') {
         prev_button.p_cancel=1;
      }
      prev_button.p_eventtab=button_eventtab;
   }
   // If there are more buttons than fit on the screen, make the
   // list box longer.
   int bottom_y=prev_button.p_y+prev_button.p_height;
   int diff_y=bottom_y+PAD_BELOW_LIST-_dy2ly(form_wid.p_xyscale_mode,form_wid.p_client_height);
   if (diff_y>0) {
      form_wid.p_height=form_wid.p_height+diff_y;
      _sellist.p_height=_sellist.p_height+diff_y;
      selnos_wid.p_y=selnos_wid.p_y+diff_y;
   }
   if (callback) {
      //status=call_index(SL_ONINIT,result,'',callback)
      result='';
      status=(*callback)(SL_ONINIT,result,'');
      if (status!='') {
         status=(*callback)(SL_ONCLOSE,result,'');
         p_active_form._delete_window(result);
         return('');
      }
   }
   if ((flags & SL_COMBO)) {
      if (initial_value!='') {
         _sellistcombo.p_text=initial_value;
      } else if (!(flags &SL_NORETRIEVEPREV)) {
         //isselected=_sellist._lbisline_selected();
         _sellist._lbdeselect_all();
         //say('a2 isselected='isselected' '_sellist.p_line);
         _sellist.save_pos(p);
         _retrieve_prev_form();
         //_sellist._lbdeselect_all();
         _sellist.restore_pos(p);
         _sellist._lbfind_selected(1);
         /*if (isselected) {
            _sellist._lbselect_line();
         } */
      }
   }
   if (help_item!='.') {
      _nocheck _control _sellisthelp;
      _sellisthelp.p_help=help_item;
   }

   if ((flags & SL_SELECTCLINE)) {
      if (_sellistcombo.p_text!='' && (flags & SL_SELECTPREFIXMATCH)) {
         _sellistcombo.call_event(CHANGE_OTHER, _sellistcombo, ON_CHANGE, "W");
      }
   }
   //messageNwait('seltext='_sellist._lbget_seltext());
   //messageNwait('p_line='_sellist.p_line' seltext='_sellist._lbget_text());
}

static boolean _disable_resize;
void _sellist_form.on_create()
{
   _disable_resize = true;
}

void _sellist_form.on_load()
{
   _disable_resize = false;
}

void _sellist_form.on_resize()
{
   if(_disable_resize || ((p_width == p_old_width) && (p_height == p_old_height))) {
      return;
   }
   typeless flags="";
   parse SELLIST_DATA with flags .;
   if (!(flags & SL_SIZABLE)) {
      return;
   }
   int list_pad_y = PAD_BELOW_LIST;
   if (_selnofselected.p_visible) {
      list_pad_y += _selnofselected.p_height;
   }
   int form_wid = p_active_form.p_window_id;
   int form_width = _dx2lx(form_wid.p_xyscale_mode, form_wid.p_client_width);
   int form_height = _dy2ly(form_wid.p_xyscale_mode, form_wid.p_client_height);
   int button_width = _sellistok.p_width;
   int button_x = form_width - PAD_AFTER_BUTTON - button_width;
   _sellist.p_width = button_x - PAD_AFTER_LIST - _sellist.p_x;
   if (_sellistcombo.p_visible ) {
      _sellistcombo.p_width = _sellist.p_width;
   }
   _sellist.p_height = form_height - list_pad_y - _sellist.p_y;
   int first_wid = _sellistok.p_window_id;
   _sellistok.p_x = button_x;
   int wid = first_wid;
   for (;;) {
      wid = wid.p_next;
      if (wid == first_wid) break;
      if (wid.p_object == OI_COMMAND_BUTTON) {
         wid.p_x = button_x;
      }
   }
   if (_selnofselected.p_visible) {
      _selnofselected.p_x = _sellist.p_x + _sellist.p_width -_selnofselected.p_width;
      _selnofselected.p_y = _sellist.p_y +_sellist.p_height;
   }
}

void _sellistcombo.on_drop_down(int reason)
{
   if (p_user=='' && _sellistcombo.p_visible) {
      _retrieve_list();
      p_user=1; // Indicate that retrieve list has been done
   }
}
#if 0
_sellist_auto_size()
{
   orig_wid=p_window_id;
   p_window_id=_sellist
   selnos_wid=_selnofselected
   form_wid=p_active_form;
   bwidth=_sellistok.p_width
   list_width=_find_longest_line()+PAD_LONGEST_LINE;
   if (list_width<MIN_LIST_WIDTH) {
      list_width=MIN_LIST_WIDTH;
   }
   if (list_width<selnos_wid.p_width) {
      list_width=selnos_wid.p_width
   }
   cx=form_wid.p_width-_dx2lx(form_wid.p_xyscale_mode,form_wid.p_client_width);
   cy=form_wid.p_height-_dy2ly(form_wid.p_xyscale_mode,form_wid.p_client_height);
   form_width=p_x+list_width+PAD_AFTER_LIST+bwidth+PAD_AFTER_BUTTON+cx;
   tswidth=_dx2lx(form_wid.p_xyscale_mode,_screen_width())
   if (form_width>tswidth) {
      list_width=list_width- (form_width-tswidth);
      form_width=tswidth;
      _sellist.p_scroll_bars=SB_BOTH
   }
   p_width=list_width;
   selnos_wid.p_x=p_x+p_width-selnos_wid.p_width;
   form_wid.p_width=form_width;
   p_window_id=orig_wid;


   button_x=p_x+list_width+PAD_AFTER_BUTTON;
   wid=first_wid=p_window_id
   for (;;) {
      wid=wid.p_next;
      if (wid==first_wid) break;
      if (wid.p_object==OI_COMMAND_BUTTON) {
         wid.p_x=button_x
      }
   }
}
#endif
_sellist.lbutton_double_click()
{
   call_event(p_window_id,ENTER);
   //_sellistok.call_event(_sellistok,LBUTTON_UP);
}
void _sellist.on_change(int reason)
{
   if (reason==CHANGE_SELECTED) {
      if (p_multi_select!=MS_NONE) {
         _str new_caption=p_Nofselected' of 'p_Noflines' selected';
         if (new_caption!=_selnofselected.p_caption) {
            _selnofselected.p_caption=new_caption;
         }
      }
   }
   if (p_multi_select==MS_NONE) {
      ignore_change=1;
      if (p_line == 0) _lbfind_selected(true);
      _sellistcombo.set_command(_lbget_text(),1);
      ignore_change=0;
   } else {
      if (reason==CHANGE_SELECTED) {
         if (p_Nofselected>1) {
            ignore_change=1;
            _sellistcombo.set_command('',1);
            ignore_change=0;
         } else {
            ignore_change=1;
            _str text="";
            parse _lbget_seltext() with text "\t" ;
            _sellistcombo.set_command(text,1);
            ignore_change=0;
         }
      }
   }
   if (reason==CHANGE_SELECTED) {
      typeless flags="";
      typeless callback="";
      typeless rest="";
      parse SELLIST_DATA with flags callback rest ;
      flags=flags&~SL_ISEARCH;
      SELLIST_DATA=flags' 'callback' 'rest;
      if (callback) {
         ignore_change=1;
         //status=call_index(SL_ONSELECT,result,'',callback)
         typeless result='';
         typeless status=(*callback)(SL_ONSELECT,result,'');
         ignore_change=0;
         if (status!='') {
            status=(*callback)(SL_ONCLOSE,result,'');
            p_active_form._delete_window(result);
            //return('');
         }
      }
   }
}

static int _sellist_search(int flags,_str &text)
{
   switch (p_multi_select) {
   case MS_NONE:
      if (_lbisline_selected()) {
         _lbdeselect_line();
      }
      break;
   case MS_EXTENDED:
      _lbdeselect_all();
      break;
   }
   _str reOption=(RE_SKIP=='')?'':'r';
   int status=search(AdjustSearch(text),'@'((flags&SL_MATCHCASE)?'e':'i'):+reOption);
   return(status);
}
_sellist.c_s()
{
   typeless flags="", callback="", text="", last_data="";
   parse SELLIST_DATA with flags callback text last_data ;
   if ((flags & SL_NOISEARCH)) return('');
   if (flags & SL_ISEARCH) {
      // Search again for the current string.
      p_col=p_col+length(text);
      int status=_sellist_search(flags,text);
      if (status) {
         p_col=p_col-length(text);
      }
      if (p_multi_select==MS_NONE) {
         _lbselect_line();
      }
   } else {
      flags=flags|SL_ISEARCH;p_cursor_x=p_left_edge;
      SELLIST_DATA=flags' 'callback' 'text' 'last_data;
   }
}
/*
    We don't want to remember what we searched for in the
    combo box.
*/
void _sellist.on_got_focus()
{
   typeless flags="", callback="", text="", last_data="";
   parse SELLIST_DATA with flags callback text last_data;
   SELLIST_DATA=flags' 'callback;
}
static void sellist_close_callback(typeless result=null)
{
   typeless callback="";
   parse SELLIST_DATA with . callback . . ;
   if (callback) {
      (*callback)(SL_ONCLOSE,result,'');
   }
}
/*
    Unfortunately, windows uses space bar to toggle
    line select.
*/
_sellist.'!'-\255()
{
   typeless flags="", callback="", text="", last_data="";
   parse SELLIST_DATA with flags callback text last_data ;
   if ((flags & SL_NOISEARCH)) {
      if (callback) {
         //status=call_index(SL_ONLISTKEY,result,last_event(),callback)
         typeless result='';
         typeless status=(*callback)(SL_ONLISTKEY,result,last_event());
         if (status!='') {
            status=(*callback)(SL_ONCLOSE,result,'');
            p_active_form._delete_window(result);
            return('');
         }
      }
      return('');
   }
   if (text==_chr(0)) {
      text='';
   }
   text=text:+last_event();
   int bcol=0;
   if (flags & SL_ISEARCH) {
      bcol=p_col;
      _sellist_search(flags,text);
   } else {
      _str reOption=(RE_SKIP=='')?'':'r';
      _str adj_last_data=AdjustSearch(last_data);
      typeless status=_lbi_search(adj_last_data,AdjustSearch(text),((flags&SL_MATCHCASE)?'e':'i'):+reOption);
   }
   SELLIST_DATA=flags' 'callback' '((text=='')?_chr(0):text)' 'last_data;
   if (p_multi_select==MS_NONE) {
      _lbselect_line();
   }
   call_event(CHANGE_SELECTED,p_window_id,ON_CHANGE,'');
}
void _sellistcombo.del()
{
   // nothing selected in the list, so just do a regular delete
   item := _sellist._lbget_seltext();
   if (item == '') {
      _delete_char();
      return;
   }

   // no callback function, so do a regular delete
   _str result='';
   typeless flags="", callback="", rest="";
   parse SELLIST_DATA with flags callback rest ;
   if (!callback) {
      _delete_char();
      return;
   }

   // call the callback with SL_ONDELKEY as an argument
   typeless status=(*callback)(SL_ONDELKEY,'','');
   if (status!='') {
      status=(*callback)(SL_ONCLOSE,result,'');
      p_active_form._delete_window(result);
   }
}
void _sellist.del()
{
   _str result='';
   typeless flags="", callback="", rest="";
   parse SELLIST_DATA with flags callback rest ;
   if (callback) {
      typeless status=(*callback)(SL_ONDELKEY,'','');
      if (status!='') {
         status=(*callback)(SL_ONCLOSE,result,'');
         p_active_form._delete_window(result);
      }
   }
}
_sellist.backspace()
{
   typeless flags="", callback="", text="", last_data="";
   parse SELLIST_DATA with flags callback text last_data ;
   last_data='';
   if ((flags & SL_NOISEARCH) && !length(text)) return('');
   if (length(text)>0) {
      text=substr(text,1,length(text)-1);
   }
   switch (p_multi_select) {
   case MS_NONE:
      if (_lbisline_selected()) {
         _lbdeselect_line();
      }
      break;
   case MS_EXTENDED:
      _lbdeselect_all();
      break;
   }
   top();
   search(LB_RE:+RE_SKIP:+_escape_re_chars(text),'@'((flags&SL_MATCHCASE)?'e':'i'):+'r');
   SELLIST_DATA=flags' 'callback' '((text=='')?_chr(0):text)' 'last_data;
   if (p_multi_select==MS_NONE) {
      _lbselect_line();
   }
}
_sellistok.lbutton_up()
{
   typeless flags="", callback="", text="", last_data="";
   parse SELLIST_DATA with flags callback text last_data ;
   if (p_cancel) {
      sellist_close_callback();
      p_active_form._delete_window();
      return('');
   }
   typeless result=0;
   typeless status=0;
   if (p_default) {
      if ((flags&SL_DEFAULTCALLBACK) && callback) {
         //status=call_index(SL_ONDEFAULT,result,'',callback)
         result='';
         status=(*callback)(SL_ONDEFAULT,result,'');
         if (status=='') {
            return('');
         }
      } else {
         if ((flags & SL_COMBO)) {
            result=_sellistcombo.p_text;
            if (flags & SL_SELECTPREFIXMATCH) {
               result=_sellist._lbget_seltext();
               if (result=='') {
                  result=_sellistcombo.p_text;
               }
            }
            if (result=='') {
               return('');
            }
            if (flags & SL_MUSTEXIST) {
               text=result;
               status=_sellist._lbi_search(last_data,result,((flags&SL_MATCHCASE)?'e':'i'));
               SELLIST_DATA=flags' 'callback' '((text=='')?_chr(0):text)' 'last_data;
               if (status) {
                  _message_box(nls('%s does not exist',result));
                  p_window_id=_sellistcombo;
                  _set_sel(1,length(p_text)+1);_set_focus();
                  return('');
               }
            }
         } else {
            if (_sellist.p_multi_select==MS_NONE) {
               result=_sellist._lbget_seltext();
            }  else {
               result=_sellist._lbmulti_select_result();
            }
         }
      }
      _save_form_response();
      sellist_close_callback(result);
      p_active_form._delete_window(result);
      return('');
   }
   if ((flags & SL_SELECTALL) && p_caption=="Select &All") {
      _sellist._lbselect_all();
      ignore_change=1;
      //status=call_index(SL_ONSELECT,result,'',callback)
      status='';
      if (callback) {
         status=(*callback)(SL_ONSELECT,result,'');
      }
      ignore_change=0;
      if (status!='') {
         sellist_close_callback(result);
         p_active_form._delete_window(result);
         return('');
      }
      _sellist.call_event(CHANGE_SELECTED,_sellist,ON_CHANGE,'');
   } else if ((flags & SL_INVERT) && p_caption=="&Invert") {
      _sellist._lbinvert();
      ignore_change=1;
      //status=call_index(SL_ONSELECT,result,'',callback)
      status='';
      if (callback) {
         status=(*callback)(SL_ONSELECT,result,'');
      }
      ignore_change=0;
      if (status!='') {
         sellist_close_callback(result);
         p_active_form._delete_window(result);
         return('');
      }
      _sellist.call_event(CHANGE_SELECTED,_sellist,ON_CHANGE,'');
   } else if (p_caption=='&Help'){
      _str help_item=p_help; //HELP_ITEM;
      if ((flags & SL_HELPCALLBACK)) {
         //status=call_index(SL_ONUSERBUTTON,result,p_tab_index-_sellistok.p_tab_index+1,callback)
         status=(*callback)(SL_ONUSERBUTTON,result,p_tab_index-_sellistok.p_tab_index+1);
         if (status!='') {
            sellist_close_callback(result);
            p_active_form._delete_window(result);
            return('');
         }
#if 0
         result=_sellist._lbget_seltext();
         call_index(result,help_item)
#endif
      } else if (substr(help_item,1,1)=='?'){
         popup_message(substr(help_item,2));
      } else if (help_item!='.'){
         help(help_item);
      }
   } else {
      if (callback) {
         //status=call_index(SL_ONUSERBUTTON,result,p_tab_index-_sellistok.p_tab_index+1,callback)
         status=(*callback)(SL_ONUSERBUTTON,result,p_tab_index-_sellistok.p_tab_index+1);
         if (status!='') {
            status=(*callback)(SL_ONCLOSE,result,'');
            p_active_form._delete_window(result);
            return('');
         }
      }
   }
}
void _sellistcombo.'PGDN','PGUP','C_HOME','C_END','DOWN','UP','C-K','C-I','C-N','C-P','c-a','s-down','s-up'()
{
   if (_ComboBoxListVisible()) {
      call_event(p_window_id,last_event(),'2');
      return;
   }
#if 0
   parse SELLIST_DATA with flags callback text last_data;
   _sellist.call_event(_sellist,last_event());
   if (flags& SL_SELECTPREFIXMATCH) {
      ignore_change=1;
      _sellistcombo.p_text='';
      _sellistcombo._set_sel(1);
      ignore_change=0;
   } else {
      _sellistcombo._set_sel(1,length(_sellistcombo.p_text)+1);
   }
#else
   if(_sellist.p_Nofselected==0 && !_sellist._on_line0() && 
      (last_event():==DOWN || last_event():==S_DOWN)) {
      _sellist._lbselect_line();
      _sellist.call_event(CHANGE_SELECTED,_sellist,ON_CHANGE,'');
   } else {
      _sellist.call_event(_sellist,last_event());
    }
   _sellistcombo._set_sel(1,length(_sellistcombo.p_text)+1);
#endif

}
static _str AdjustSearch(_str &text)
{
   if(RE_SKIP=='') {
      return(text);
   }
   return(RE_SKIP:+_escape_re_chars(text));
}
_sellistcombo.on_change(int reason)
{
   if (ignore_change) {
      return('');
   }
   _sellist._lbdeselect_all();
   typeless flags="", callback="", text="", last_data="";
   parse SELLIST_DATA with flags callback text last_data ;
   if (flags & SL_NOISEARCH) return('');
   text=strip(p_text,'L');
#if 0
   if (substr(text,1,1)=='"') {
      text=substr(text,2)
   }
#endif
   _str reOption=(RE_SKIP=='')?'':'r';
   typeless result=0;
   _str adj_last_data=AdjustSearch(last_data);
   typeless status=_sellist._lbi_search(adj_last_data,AdjustSearch(text),((flags&SL_MATCHCASE)?'e':'i'):+reOption,'');
   SELLIST_DATA=flags' 'callback' '((text=='')?_chr(0):text)' 'last_data;

   if (flags &SL_SELECTPREFIXMATCH) {
      if (!status) {
         _sellist._lbselect_line();
      }
      //_sellist.call_event(CHANGE_SELECTED,_sellist,ON_CHANGE,'');
      if (callback) {
         ignore_change=1;
         //status=call_index(SL_ONSELECT,result,'',callback)
         result='';
         status=(*callback)(SL_ONSELECT,result,'');
         ignore_change=0;
         if (status!='') {
            status=(*callback)(SL_ONCLOSE,result,'');
            p_active_form._delete_window(result);
            return('');
         }
      }
   }
}
_sellistcombo.'?'()
{
   if (p_completion!='' && def_qmark_complete) {
      boolean lastarg=maybe_list_matches(p_completion,'',false,1);
      if (lastarg) {
         _sellistok.call_event(_sellistok,LBUTTON_UP);
         return('');
      }
      return('');
   }
   keyin('?');
}
defeventtab _showbuf_form;
void _showbuf_form.on_resize()
{
   //10:25am 5/13/1998
   //Dan added for diff report stuff
   int formwidth=_dx2lx(SM_TWIP,p_active_form.p_client_width);
   int formheight=_dy2ly(SM_TWIP,p_active_form.p_client_height);
   list1.p_width=formwidth-(2*list1.p_x);
   list1.p_height=formheight-(2*list1.p_y)-ctlsave.p_height;
   ctlsave.p_y=closebtn.p_y=list1.p_y+list1.p_height+(list1.p_y intdiv 2);
}

closebtn.lbutton_up()
{
   if (ctlsave.p_visible && list1.p_modify) {
      int result=prompt_for_save(nls("Save Changes?"));
      if(result==IDCANCEL) {
          return(COMMAND_CANCELLED_RC);
      }
      if (result==IDYES) {
         int status=list1.save();
         if (status==COMMAND_CANCELLED_RC) return(COMMAND_CANCELLED_RC);
      }
   }
   p_active_form._delete_window(0);
}
list1.a_c()
{
   closebtn.call_event(closebtn,LBUTTON_UP);
}
list1.on_create(int src_buf_id=-1,
                _str caption='',
                _str save_button='',
                boolean read_only=false)
{
   //src_buf_id=arg(1)
   if (src_buf_id>=0) {
      _delete_buffer();
      p_buf_id=src_buf_id;
   }
   if (caption!='') {
      p_active_form.p_caption=caption;
   }
   if (upcase(save_button)=='S') {
      //10:25am 5/13/1998
      //Dan added for diff report stuff
      //Show save button
      ctlsave.p_visible=1;
      //Gotta let'em save it too
      list1.p_AllowSave=1;
   }
   if (read_only) {
      p_readonly_mode=1;
   }
   //show('-modal form10')
}
/**
 * Displays the buffer id or the buffer attatched to the window specified modally in a dialog box.  This
 * function is intended for debugging macros.  The default show options
 * used to display the dialog box are "-new -modal".  Specify the
 * <i>show_options</i> arguments to override the default show options.
 * See <b>show</b> function information on show options.
 *
 * @categories Miscellaneous_Functions
 * @param buf_or_window_id
 *                  This paramater must be a valid buffer or view id
 * @param isBuffer  When true,buf_or_window_id is a buffer id.
 * @param show_options
 *                  Arguments that are given to the show command before the form name. Default is <B>-new -modal</B>.  Specify '' for a modeless dialog
 * @param dialog_caption
 *                  Caption of hte dialog box
 * @param save_button
 *                  Specify 'S' to put a save button on this dialog
 * @param read_only if true, buffer is treated as read only, and if there is a save button, it will do a "save as..."
 *
 * @return the window id of the dialog.  Returns 0 if dialog is modal
 */
_showbuf(int buf_or_view_id,boolean isBuffer=true,_str show_options='-new -modal',_str dialog_caption='',_str save_button='',boolean read_only=false)
{
   if (!isBuffer) {
      buf_or_view_id=buf_or_view_id.p_buf_id;
   }
   int view_id=0;
   get_window_id(view_id);
   if (show_options=='-') show_options='';
   int wid=show(show_options' _showbuf_form',buf_or_view_id,dialog_caption,save_button,read_only);
   if (show_options!='') {
      activate_window(view_id);
   }
   if ( pos(' -modal ',' 'show_options' ') ) {
      // If the diaog was modal, there is no point in returning this window id
      wid=0;
   }
   return(wid);
}
ctlsave.lbutton_up()
{
   //10:24am 5/13/1998
   //Dan added for diff report stuff
   //I think this will be ok........
   int wid=p_window_id;
   p_window_id=list1;
   if (p_ReadOnly) {
      gui_save_as();
   }else{
      save();
   }
   p_window_id=wid;
}

