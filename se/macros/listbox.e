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
#import "dlgman.e"
#import "mouse.e"
#import "put.e"
#import "stdprocs.e"
#import "util.e"
#endregion
//
//  This code to handle the list box can be
//  ellagantly and drastically reduced once the macro language
//  can call static functions by address.
//

//
//    User level 2 inheritance for LIST BOX p_multi_select!=MS_EDIT_WINDOW
//
defeventtab _ul2_listbox;
   // The p_value property is set to 0 if only the
   // current line is selected.  p_value is set to -1
   // more than the current line could be selected.
   // p_value is also set to a non-zero pivot point
   // when the user used the

_ul2_listbox.' '()
{
   switch (p_multi_select) {
   case MS_NONE:
      if (!_lbisline_selected()) {
         _lbselect_line();
      }
      break;
   case MS_SIMPLE_LIST:
      if (_lbisline_selected()) {
         _lbdeselect_line();
      } else {
         _lbselect_line();
      }
      break;
   case MS_EXTENDED:
      _lbdeselect_all();
      _lbselect_line();
      break;
   }
   call_event(CHANGE_SELECTED,p_window_id,ON_CHANGE,'');
}
//
//  Define this keys first,  If they get blown away latter (like c-a), don't worry about it
//  Try to use keys based on users emulation.
_ul2_listbox.c_b-c_z()
{
   switch (name_on_key(last_event())) {
   case 'cursor-up':
      call_event(defeventtab  _ul2_listbox,UP,'E');
      return('');
   case 'cursor-down':
      call_event(defeventtab  _ul2_listbox,DOWN,'E');
      return('');
   case 'page-up':
      call_event(defeventtab  _ul2_listbox,PGUP,'E');
      return('');
   case 'page-down':
      call_event(defeventtab  _ul2_listbox,PGDN,'E');
      return('');
   case 'top-of-buffer':
      call_event(defeventtab  _ul2_listbox,C_HOME,'E');
      return('');
   case 'bottom-of-buffer':
      call_event(defeventtab  _ul2_listbox,C_HOME,'E');
      return('');
   }
}
_ul2_listbox.c_a,'m_a'()
{
   switch (p_multi_select) {
   case MS_SIMPLE_LIST:
   case MS_EXTENDED:
      _lbselect_all();
      call_event(CHANGE_SELECTED,p_window_id,ON_CHANGE,'');
      break;
   }
}
#if 0
_ul2_listbox.on_create2()
{
   if (p_edit) {
      insert_line(' 'p_name);
   }
}
#endif
_ul2_listbox.tab()
{
  call_event(_get_form(p_window_id),TAB);
}
_ul2_listbox.s_tab()
{
   call_event(_get_form(p_window_id),S_TAB);
}

/**
 * Returns the text of current item in the list box.
 * If the current item is not selected, '' is returned.
 *
 * @see _lbget_text
 * @see _lbget_item
 *
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
_str _lbget_seltext()
{
   if (!_lbisline_selected()) {
      return('');
   }
   if (p_object==OI_LIST_BOX) {
      _str text;
      int pic_index;
      _lbget_item_index(p_line,text,pic_index);
      return(text);
   }
   text := "";
   line := "";
   get_line(line);
   if (p_picture) {
      parse line with ':' text;
   } else {
      text=substr(line,2);
   }

   return(text);
}
static const BMINDENT_WIDTH= 6;

/**
 * Deletes the current item in a list box and
 * decrements the {@link p_Nofselected} property if the current
 * item was selected.
 *
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
int _lbdelete_item()
{
   if (p_object==OI_LIST_BOX) {
      return(_lbdelete_item_index(p_line));
   }
   return(_delete_line());
}
/**
 * Replaces the current item in a list box.
 * 
 * @param item Text of item to be added to the list box.
 * 
 * @param indent Indent in twips before picture.  If this parameter is 
 * given, you must specify the <i>picture_index</i> parameter.  1440 twips are 
 * one inch on the display.
 * 
 * @param picture_index Index into names table of a picture to display.  
 * Currently only bitmap pictures are supported.  The _update_picture function 
 * may be used to load a picture and return an index.  In addition, there are 
 * several global picture index variables defined in "slick.sh" (look for  
 * _pic_??? variables).
 * 
 * @example
 * <pre>
 * #include 'slick.sh'
 * 
 * #define PIC_LSPACE_Y 60    // Extra line spacing for list box.
 * #define PIC_LINDENT_X 60   // Indent for list box bitmap.
 * 
 * defeventtab form1;
 * list1.on_create()
 * {
 *    _insert_drive_list();
 *    p_pic_space_y=PIC_LSPACE_Y;
 *    _lbtop();_lbup();
 *    for (;;) {
 *       if (_lbdown()) break;
 *       line=_lbget_text();
 *       dt=_drive_type(line);
 *       if (dt==DRIVE_NOROOTDIR) {
 *          status=_lbdelete_item();
 *          // If deleted last line
 *          if (status) break;
 *          _lbup();
 *          continue;
 *       } else if (dt==DRIVE_FIXED) {
 *          picture=_pic_drfixed;
 *       } else if (dt==DRIVE_CDROM){
 *          picture=_pic_drcdrom;
 *       } else {
 *          picture=_pic_drremov;
 *       }
 *       _lbset_item(line,PIC_LINDENT_X,picture);
 *    }
 *    // The p_picture property must be set to indicate that this list box is 
 * displaying pictures 
 *    // and to provide a scaling picture for the p_pic_point_scale property.  
 *    // The p_pic_point_scale property allows the picture to be resized for 
 * fonts larger or
 *    // smaller than the value of the p_pic_point_scale point size.
 *    p_picture=picture;
 *    p_pic_point_scale=8;
 * }
 * </pre>
 * 
 * @see _lbget_text
 * @see _lbget_seltext
 * @see _lbget_item
 * @see _lbadd_item
 * 
 * @appliesTo List_Box
 * 
 * @categories List_Box_Methods
 * 
 */
void _lbset_item(_str text, _str indent="", _str picture_index="")
{
   if (p_object==OI_COMBO_BOX || p_object==OI_LIST_BOX) {
      if (isinteger(picture_index)) {
         _lbset_item2(text,(int)picture_index);
         return;
      }
      _lbset_item2(text,0);
      return;
   }
   if (indent != '') {
      replace_line(' 'substr(indent,1,BMINDENT_WIDTH)' 'substr(picture_index,1,5)':'text);
   } else {
      replace_line(' 'text);
   }
}
/**
 * Places the cursor on the previous item in the list box.  If
 * the {@link p_multi_select} property is <b>MS_NONE</b> or
 * <b>MS_EXTENDED</b>, selected lines are deselected. The first
 * item in a list box is on line 1 (<b>p_line</b>==1).  If there
 * are non items in the list box, the current line will be line
 * 0 (<b>p_line</b>==0). If you call the <b>_lbup</b> function
 * when on line 1, the cursor will be placed on line 0.  You
 * might want to check if the list is empty
 * (<b>p_Noflines</b>==0) or if you are on line 1
 * (<b>p_line</b>==1) before calling this function.
 *
 * @return Returns non-zero value call when on line 0
 *         (<b>p_line</b>==0).
 *
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
_str _lbup()
{
   return(up());
}
/**
 * Places the cursor on the next item in the list box.  If the 
 * {@link p_multi_select} property is MS_NONE or MS_EXTENDED,
 * selected lines are deselected.
 * 
 * @return Returns non-zero value if the function is called when already on 
 * last item.
 * 
 * @appliesTo List_Box
 * @categories List_Box_Methods
 * 
 */
_str _lbdown()
{
   return(down());
}

/**
 * Places the cursor on the first item of the list box.  If the 
 * {@link p_multi_select} property is MS_NONE or MS_EXTENDED,
 * selected lines are deselected.
 * 
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
void _lbtop()
{
   if (p_object==OI_COMBO_BOX) {
      top();
      return;
   }
   switch (p_multi_select) {
   case MS_NONE:
      if (_lbisline_selected()) {
         _lbdeselect_line();
      }
      break;
   }
   top();
}
/**
 * Places the cursor on the last item of the list box.  If the 
 * {@link p_multi_select} property is MS_NONE or MS_EXTENDED,
 * selected lines are deselected.
 * 
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
void _lbbottom()
{
   if (p_object==OI_COMBO_BOX) {
      bottom();
      return;
   }
   switch (p_multi_select) {
   case MS_NONE:
      if (_lbisline_selected()) {
         _lbdeselect_line();
      }
      break;
   }
   bottom();
}
/**
 * Adds an item to a list box after the current line.
 * 
 * @param item The text of item to be added to the list box.
 * 
 * @param indent Indent in twips before picture.  If this parameter is 
 * given, you must specify the <i>picture_index</i> parameter.  1440 twips are 
 * one inch on the display.
 * 
 * @param picture_index Index into names table of a picture to display.  
 * Currently, only bitmap pictures are supported.  The <b>_update_picture</b> 
 * function may be used to load a picture and return an index.  In addition, 
 * there are several global picture index variables defined in "slick.sh" (look 
 * for  _pic_??? variables).
 * 
 * @example
 * <pre>
 * #include 'slick.sh'
 * 
 * #define   PIC_LSPACE_Y 60    // Extra line spacing for list box.
 * #define   PIC_LINDENT_X 60   // Indent before for list box bitmap.
 * 
 * defeventtab form1;
 * list1.on_create()
 * {
 *    p_pic_space_y=PIC_LSPACE_Y;
 *    _lbadd_item('a:',PIC_LINDENT_X,_pic_drremov);
 *    _lbadd_item('b:',PIC_LINDENT_X,_pic_drremov);
 *    _lbadd_item('c:',PIC_LINDENT_X,_pic_drfixed);
 *    // The p_picture property must be set to indicate that this list box
 *    // is displaying pictures and to provide a scaling picture for 
 *    // the p_pic_point_scale property.  The p_pic_point_scale property 
 * allows the picture to 
 *    // be resized for fonts larger or smaller that the value of the 
 * p_pic_point_scale point size.
 *    p_picture=_pic_drfixed;
 *    p_pic_point_scale=8;
 * }
 * </pre>
 * 
 * @see _lbget_text
 * @see _lbget_seltext
 * @see _lbget_item
 * @see _lbset_item
 * 
 * @appliesTo List_Box
 * 
 * @categories List_Box_Methods
 * 
 */
void _lbadd_item(_str text, _str indent="", _str picture_index="")
{
   if (p_object==OI_COMBO_BOX || p_object==OI_LIST_BOX) {
      if (isinteger(picture_index)) {
         _lbadd_item2(text,(int)picture_index);
         return;
      }
      _lbadd_item2(text,0);
      return;
   }
   if (indent != "" && indent != 0 && picture_index != "" && picture_index != 0) {
      //  bitmap_indent (twips)  bitmap_index
      insert_line(' 'substr(indent,1,BMINDENT_WIDTH)' 'substr(picture_index,1,5)':'text);
   } else {
      insert_line(' 'text);
   }
}

/**
 * Adds a list of items to a list box after the current line.
 * 
 * @param items  The array of text items to be added to the list box.
 * 
 * @param indent Indent in twips before picture.  If this parameter is 
 * given, you must specify the <i>picture_index</i> parameter.  1440 twips are 
 * one inch on the display.
 * 
 * @param picture_index Index into names table of a picture to display.  
 * Currently, only bitmap pictures are supported.  The <b>_update_picture</b> 
 * function may be used to load a picture and return an index.  In addition, 
 * there are several global picture index variables defined in "slick.sh" (look 
 * for  _pic_??? variables).
 * 
 * @see _lbadd_item 
 * @see _lbadd_file_list 
 * 
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
void _lbadd_item_list(_str (&text)[], _str indent="", _str picture_index="")
{
   prefix := " ";
   if (indent != "") {
      prefix :+= substr(indent,1,BMINDENT_WIDTH)' 'substr(picture_index,1,5)':';
   }
   int i;
   for (i = 0; i < text._length(); ++i) {
      insert_line(prefix:+text[i]);
   }
   //_begin_line();
}

/**
 * Adds a space-delimited list of items to a list box after the current line. 
 * Items contains spaces need to be quoted. 
 * 
 * @param items  The list of items to be added to the list box.
 * 
 * @param indent Indent in twips before picture.  If this parameter is 
 * given, you must specify the <i>picture_index</i> parameter.  1440 twips are 
 * one inch on the display.
 * 
 * @param picture_index Index into names table of a picture to display.  
 * Currently, only bitmap pictures are supported.  The <b>_update_picture</b> 
 * function may be used to load a picture and return an index.  In addition, 
 * there are several global picture index variables defined in "slick.sh" (look 
 * for  _pic_??? variables).
 * 
 * @see _lbadd_item 
 * @see _lbadd_item_list 
 * 
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
void _lbadd_file_list(_str list, _str indent="", _str picture_index="")
{
   prefix := " ";
   if (indent != "") {
      prefix :+= substr(indent,1,BMINDENT_WIDTH)' 'substr(picture_index,1,5)':';
   }
   cur := parse_file(list, true);
   while (cur != "") {
      insert_line(prefix:+_maybe_unquote_filename(cur));
      cur = parse_file(list, true);
   }
}

/**
 * Adds an item to the top of a list box.  If the item is already 
 * in the list, just move it to the top.  Limit the total number of items 
 * to 'max_items'.  This function is useful for keeping a 
 * most-recently-used list of items, such as you would from a search 
 * drop-down. 
 * 
 * @param text       The text of item to be added to the list box.
 * @param max_items  Maximum number of items to keep in list box.
 *
 * @see _lbadd_item
 * @see _lbsearch
 * @see _lbget_item
 * @see _lbset_item 
 *  
 * @appliesTo List_Box
 * @categories List_Box_Methods
 */
void _lbadd_bounded(_str text, int max_items=25)
{
   if (text=='') {
      return;
   }
   _lbtop();
   while (!_lbfind_and_select_item(text)) {
      _lbdelete_item();
   }
   _lbtop();up();
   _lbadd_item(text);
   if (p_Noflines>max_items) {
      _lbbottom();
      while (p_Noflines>max_items) {
         _lbdelete_item();
      }
      _lbtop();
   }
}

/**
 * Sort items in a list box.  By default, a case insensitive string sort is 
 * performed.  If <i>cmdline</i> is specified and is not '', a case sensitive 
 * sort will be performed unless the 'I' option letter is specified.
 * 
 * @param cmdline is a string in the format:<br>
 * <pre>
 * [ A|  D]   [ E | I ]    [  -N | -F]
 * </pre>
 * 
 * @param cmdline may contain multiple options having the following 
 * meaning:
 * <dl>
 * <dt>A</dt><dd>(Default) Sort in ascending order.</dd>
 * <dt>D</dt><dd>Sort in descending order.</dd>
 * <dt>I</dt><dd>Case insensitive sort (Ignore case).</dd>
 * <dt>E</dt><dd>Case sensitive sort (Exact case).</dd>
 * <dt>-N</dt><dd>Sort numbers</dd>
 * <dt>-F</dt><dd>Sort filenames</dd>
 * </dl>
 * 
 * @param start_point and <i>end_point</i> are seek positions to the 
 * beginning of lines in the list box returned by the point function.  If 
 * <i>start_point</i> is given, sorting does not affect lines above the line on 
 * this seek position.  If <i>end_point</i> is given, sorting does not affect 
 * lines below the line on this seek position.
 * 
 * @example
 * <pre>
 * #include "slick.sh"
 * defeventtab form1;
 * list1.on_create()
 * {
 *     _lbadd_item("10");
 *     _lbadd_item("1");
 *     _lbadd_item("4");
 *     _lbsort("-n");   // Sort the number in the list box
 *     _lbsort("d -n"); // Now sort them in descending order
 *     _lbclear();
 *     _lbadd_item("c");
 *     _lbadd_item("A");
 *     _lbadd_item("C");
 *     _lbsort(); // Sort strings case insensitive in ascending order.
 *     _lbsort("d"); // Sort strings case sensitive in descending order.
 *     _lbsort("i d");  // Sort strings case insensitive in descending order.
 * }
 * </pre>
 * 
 * @appliesTo List_Box
 * 
 * @categories List_Box_Methods
 * 
 */
int _lbsort(_str options="", int start_linenum=1, int end_linenum=-1)
{
   int count=end_linenum-start_linenum+1;
   if (count<0) {
      count=p_Noflines-start_linenum+1;
   }
   return(_lbsort2(options,start_linenum,count));
}
/**
 * Deletes all lines in a list box or buffer.
 * 
 * @appliesTo List_Box
 * 
 * @categories List_Box_Methods
 * 
 */
void _lbclear()
{
   if (p_object==OI_LIST_BOX || p_object==OI_COMBO_BOX) {
      _lbclear2();
      return;
   }
   typeless mark=_alloc_selection();
   if (mark<0) {
       top();
       while (p_Noflines) {
          _delete_line();
       }
       if (p_object==OI_LIST_BOX) {
          p_Nofselected=0;
       }
   } else {
      top();
      if (!_on_line0()) {
         _select_line(mark);
         bottom();p_col=1;
         _select_line(mark);
         _delete_selection(mark);
      }
      _free_selection(mark);
      if (p_object==OI_LIST_BOX) {
         p_Nofselected=0;
      }
   }
}
/**
 * Places the text, indent, and picture_index of the current item in the list 
 * box into the corresponding variables.
 * 
 * @see _lbget_text
 * @see _lbget_seltext
 * @see  _lbset_item
 * @see _lbadd_item
 * 
 * @appliesTo List_Box
 * 
 * @categories List_Box_Methods
 * 
 */
void _lbget_item(_str &item, var indent, var pic_index)
{
   if (p_object==OI_LIST_BOX) {
      indent=0;
      _lbget_item_index(p_line,item,pic_index);
      return;
   }
   line := "";
   get_line(line);
   if (p_picture) {
      typeless str_indent="";
      typeless str_index="";
      parse substr(line,2) with indent pic_index ':' item;
      pic_index=strip(pic_index);
   } else {
      item=substr(line,2);
      indent=0;
      pic_index=0;
   }
}
/** 
 * @return Returns the text of current item in the list box - regardless of what
 * is selected
 * 
 * @see _lbget_seltext
 * @see _lbget_item
 * 
 * @appliesTo List_Box
 * 
 * @categories List_Box_Methods
 * 
 */
_str _lbget_text()
{
   if (p_object==OI_LIST_BOX) {
      _str text;
      int pic_index;
      _lbget_item_index(p_line,text,pic_index);
      return(text);
   }
   text := "";
   line := "";
   get_line(line);
   if (p_picture) {
      parse line with ':' text ;
   } else {
      text=substr(line,2);
   }
   return(text);
}
_ul2_listbox.s_up()
{
   _lbcommand('s-up');
}
_ul2_listbox.s_down()
{
   _lbcommand('s-down');
}
_ul2_listbox.up()
{
   _lbcommand('up');
}
_ul2_listbox.down()
{
   _lbcommand('down');
}
_ul2_listbox.pgup()
{
   _lbcommand('pageup');
}
_ul2_listbox.pgdn()
{
   _lbcommand('pagedown');
}
_ul2_listbox.c_pgdn()
{
   _lbcommand('c-pagedown');
}
_ul2_listbox.c_pgup()
{
   _lbcommand('c-pageup');
}
_ul2_listbox.'c-s-pgdn'()
{
   _lbcommand('c-s-pagedown');
}
_ul2_listbox.'c-s-pgup'()
{
   _lbcommand('c-s-pageup');
}

_ul2_listbox.home,c_home()
{
   _lbcommand('home');
}
_ul2_listbox.end,c_end()
{
   _lbcommand('end');
}
_ul2_listbox.s_home,"c-s-home"()
{
   _lbcommand('s-home');
}
_ul2_listbox.s_end,"c-s-end"()
{
   _lbcommand('s-end');
}

def on_vsb_page_down=_sb_page_down;
def on_vsb_page_up=_sb_page_up;
def on_vsb_top=top_of_buffer;
def on_vsb_bottom=bottom_of_buffer;
def on_vsb_line_down=fast_scroll;
def on_vsb_line_up=fast_scroll;
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
static void set_scroll_directions(bool &past_bottom, bool &past_top, int &new_y)
{
   new_y=mou_last_y();
   past_bottom=false;past_top=false;
   if ( mou_last_y()>=p_client_height ) {
      past_bottom=true;
      new_y=p_client_height;
   }
   if ( mou_last_y()<p_windent_y ) {
      past_top=true;
      new_y=0;
   }
}
static void select_to_cursor2(int do_select,int new_y,_str specific_value)
{
   if (do_select==2) {
      linenum := p_line;
      typeless was_selected=_lbisline_selected();
      _lbdeselect_line();
      p_cursor_y=new_y;
      _lbselect_line();
#if 0
      if ((linenum!=p_line || !was_selected) && p_multi_select!=MS_NONE) {
         call_event(CHANGE_SELECTED,p_window_id,ON_CHANGE,'');
      }
#endif
      return;
   }
   p_cursor_y=new_y;
   if (!do_select) return;
   select_to_cursor(do_select!=0);
}
static void select_to_cursor(bool do_select, typeless specific_value="")
{
   if (!do_select) return;
   typeless pivot_point=p_value-1;
   typeless cursor_point=point();
   save_pos(auto p);

   // Deselect lines outside of selection area
   typeless start_point=pivot_point;
   typeless end_point=cursor_point;
   if (start_point>end_point) {
      typeless temp=start_point;start_point=end_point;end_point=temp;
   }
   if (specific_value=='') {
      // Deselect lines before start_point
      goto_point(start_point);
      for (;;) {
         if (point()<=0) break;
         up();
         if (!_lbisline_selected()) break;
         _lbdeselect_line();
      }
      // Deselect lines after end point
      goto_point(end_point);
      for (;;) {
         down();
         if (rc) break;
         if (!_lbisline_selected()) break;
         _lbdeselect_line();
      }
   }

   // Select lines while move in the direction of the pivot point.
   goto_point(cursor_point);
   if (cursor_point>=pivot_point) {
      //message 'cursor_point='cursor_point' pivot_point='pivot_point
      for (;;) {
         if(specific_value=='') {
            if (_lbisline_selected()) break;
            _lbselect_line();
         } else if (specific_value) {
            _lbselect_line();
         } else {
            _lbdeselect_line();
         }
         if (point()<=pivot_point) break;
         if (point()<=0) break;
         up();
      }

   } else {
      for (;;) {
         if(specific_value=='') {
            if (_lbisline_selected()) break;
            _lbselect_line();
         } else if (specific_value) {
            _lbselect_line();
         } else {
            _lbdeselect_line();
         }
         if (point()>=pivot_point) break;
         down();
         if (rc) break;
      }
   }
   restore_pos(p);
}
static _lbselect_specific(_str specific_value,int default_value)
{
   if (specific_value=='') specific_value=default_value;
   if (specific_value) {
      _lbselect_line();
   } else {
      _lbdeselect_line();
   }
}
static _str lbmou_in_window()
{
   return mou_last_y()>=p_windent_y && mou_last_y()<p_client_height;
}
static void _lbmou_click2(int do_select,_str specific_value)
{
   mou_mode(1);
   mou_release();mou_capture();
   old_y := p_cursor_y;
   for (;;) {
       _str event=get_event();
       if ( event:==MOUSE_MOVE ) {
          if ( lbmou_in_window() ) {
             if (!p_value) {
                int new_y=mou_last_y();
                if (new_y==old_y) {
                   continue;
                }
                if (do_select==2) {
                   _lbdeselect_line();
                }
                p_cursor_y=new_y;
                p_value=(int)point()+1;
             }
             select_to_cursor2(do_select,mou_last_y(),specific_value);
          } else {
             if (!p_value) {
                p_value=(int)point()+1;
             }
             typeless done=selectNscroll(do_select,specific_value);
             if ( done ) {
                break;
             }
          }
       } else {
          break;
       }
   }
   mou_mode(0);
   mou_release();
}
static _str selectNscroll(int do_select,_str specific_value)
{
   // Mapping coordinates under UNIX is VERY VERY slow.
   // Here were reduce the number of calls a lot by getting the mouse
   // coordinates relative the screen and mapping top left corner of
   // client window.
   int mx=mou_last_x('D');
   int my=mou_last_y('D');
   wx := wy := 0;
   _map_xy(p_window_id,0,wx,wy);
   mx-=wx;my-=wy;
   /* we are outside the window. */
   /* Determine which side of window we are outside. */

   typeless past_bottom=0;
   typeless past_top=0;
   new_y := 0;
   set_scroll_directions(past_bottom,past_top,new_y);
   select_to_cursor2(do_select,new_y,specific_value);
   typeless pivot_point=p_value -1;

   int init_delay=def_init_delay;
   max_skip := 1;
   int count=DEF_CHG_COUNT;
   _set_scroll_speed(init_delay,max_skip,count,mx,my);
   skip_count := 0;
   if ( machine()=='WINDOWS' ) {
      max_skip=2;
   }
   _set_timer(init_delay);
   for (;;) {
      typeless event=ON_TIMER;
      ++skip_count;
      no_skip := skip_count>=max_skip;  //  || test_event('r'):!='')
      if ( no_skip ) {
         event=get_event();
         skip_count=0;
      }
      if (event:==ON_TIMER) {
         --count;
         if ( count<=0 ) {
            count=DEF_CHG_COUNT;
            max_skip += DEF_INC_MAX_SKIP_BY;
            if ( max_skip>DEF_MAX_SKIP ) {
               max_skip=DEF_MAX_SKIP;
            }
         }
      } else if ( event:==MOUSE_MOVE ) {
         // Mapping coordinates under UNIX is VERY VERY slow.
         // Here were reduce the number of calls a lot.
         mx=mou_last_x('D');my=mou_last_y('D');
         mx-=wx;my-=wy;
         if ( lbmou_in_window() ) {
            select_to_cursor2(do_select,mou_last_y(),specific_value);
            _kill_timer();
            return(0);
         }
         set_scroll_directions(past_bottom,past_top,new_y);
         select_to_cursor2(do_select,new_y,specific_value);
         _set_scroll_speed(init_delay,max_skip,count,mx,my);
         _set_timer(init_delay);
      } else {
         _kill_timer();
         return(1);
      }
      switch (do_select) {
      case 2:
         if ( past_bottom ) {
            _lbdeselect_line();
            down();
            _lbselect_line();
         }
         if ( past_top ) {
            if (point()>0) {
               _lbdeselect_line();
               up();
               _lbselect_line();
            }
         }
         break;
      case 1:
         if ( past_bottom ) {
            if (point()>=pivot_point) {
               down();
               _lbselect_specific(specific_value,1);
            } else {
               _lbselect_specific(specific_value,0);
               down();
            }
         }
         if ( past_top ) {
            if (point()>0) {
               if (point()<=pivot_point) {
                  up();
                  _lbselect_specific(specific_value,1);
               } else {
                  _lbselect_specific(specific_value,0);
                  up();
               }
            }
         }
         break;
      default:
         if ( past_bottom ) {
            down();
         }
         if ( past_top ) {
            if (point()>0) {
               up();
            }
         }
      }
   }
}

/**
 * Set the text in a combo box to the given text.  If the given 
 * string is not in the combo box's list, add it to the list. 
 * 
 * @param text       string to set caption to 
 * @param pic_index  bitmap index for item if added 
 *  
 * @see p_text 
 * @see _lbfind_item 
 * @see _lbadd_item 
 * @see _lbsearch 
 * 
 * @appliesTo List_Box Combo_Box
 * @categories List_Box_Methods, Combo_Box_Methods
 */
void _cbset_text(_str text, int pic_index=0)
{
   if (p_picture != pic_index) p_picture = pic_index;
   if (p_text == text && _lbget_text() == text) return;
   ln := _lbfind_item(text);
   if (ln < 0) {
      _lbadd_item(text,0,pic_index);
   } else {
      p_line = ln+1;
   }
   p_text = text;
}

/**
 * Searches for a whole item in the list box which matches the <i>text</i> 
 * string given.  If the <i>options</i> parameter contains the R option, this 
 * function will search for an item which contains the <i>text</i> string given.  
 * The search always starts from the top of the list.
 * 
 * @param options is a string of zero or more of the following letters:
 * <dl>
 * <dt>E</dt><dd>Match case exactly</dd>
 * <dt>I</dt><dd>(Default) Ignore case</dd>
 * <dt>R</dt><dd>Interpret <i>text</i> as a SlickEdit regular expression.</dd>
 * <dt>L</dt><dd>Interpret <i>text</i> as a Perl regular expression.</dd>
 * <dt>~</dt><dd>Interpret <i>text</i> as a Vim regular expression.</dd>
 * <dt>U</dt><dd>Interpret <i>text</i> as a Perl regular expression. Support for Unix syntax regular expressions has been removed.</dd>
 * <dt>B</dt><dd>Interpret <i>text</i> as a Perl regular expression. Support for Brief syntax regular expresions has been removed.</dd>
 * </dl>
 *
 * @return Returns 0 if match is found
 * 
 * @see _lbi_search
 * 
 * @appliesTo List_Box Combo_Box
 * @categories List_Box_Methods, Combo_Box_Methods
 */
_str _lbsearch(_str text, _str options="")
{
   if (p_object==OI_COMBO_BOX) {
      if (options=='') {
         options=p_case_sensitive?'e':'i';
      }
      top();
      return(search(text,options));
   }
   last_data := "";
   if (options=='') options='i';
   if (!pos('r',options,1,'i')) {
      text=_escape_re_chars(text)'$';
      options :+= 'r';
   }
   return(_lbi_search(last_data,text,options));
}
#if 0
_str _lbsearch2(_str text, _str options="")
{
   switch (p_multi_select) {
   case MS_NONE:
      if (_lbisline_selected()) {
         _lbdeselect_line();
      }
      break;
#if 0
   case MS_EXTENDED:
      _lbdeselect_all();
      break;
#endif
   }

   if (p_scroll_left_edge>=0) {
      // parse _scroll_page() with line_pos down_count ;
      // goto_point line_pos
      // down down_count
      // set_scroll_pos p_scroll_left_edge,0
      p_scroll_left_edge= -1;
   }
   case_sense := 'i';
   if (options!='') {
      case_sense=options;
   }
   status := search(text,'@'case_sense);
   if (status) {
      return(status);
   }
   for (;;) {
      if (p_picture) {
         line := "";
         get_line(line);
         // For now, tab expansion not supported
         i := pos(':',line,1,'i');
         if (!i) break;
         if (p_col>i) break;
      } else {
         if (p_col>1) break;
      }
      status=repeat_search();
      if (status) break;
   }
   if (status) {
      return(status);
   }
   _post_paint();
   if (p_cursor_y!=0) {
      line_to_top();
   }
#if 0
   cursor_y=p_cursor_y;
   p_cursor_y=0;old_line=p_line;p_cursor_y=cursor_y;
   status=search(retext:+arg(4),options);
   if (status && last_status && add_char) {
      return(status);
   }
   cursor_y=p_cursor_y;
   p_cursor_y=0;new_line=p_line;p_cursor_y=cursor_y;
   if (old_line!=new_line) {
      line_to_top();
   }
#endif
   return(status);
}
#endif

/**
 * Searches for an item in the list box which starts with the string, 
 * <i>text</i>.  Set <i>last_data</i> to '' to initialize or reinitialize 
 * searching.  If you modify any items in the list box, you need to set the 
 * <i>last_data</i> input variable to ''.  Otherwise, on subsequent calls to 
 * this function, pass in the previous <i>last_data</i> value for fastest 
 * search.  When the <i>last_data</i> variable is '', searching always begins 
 * from the top of the list box which can be slow if there are many items in the 
 * list box.
 * 
 * @param options is a string of zero or more of the following letters:
 * <dl>
 * <dt>E</dt><dd>Match case exactly</dd>
 * <dt>I</dt><dd>(Default) Ignore case</dd>
 * <dt>R</dt><dd>Interpret <i>text</i> as a SlickEdit regular expression.</dd>
 * <dt>L</dt><dd>Interpret <i>text</i> as a Perl regular expression.</dd>
 * <dt>~</dt><dd>Interpret <i>text</i> as a Vim regular expression.</dd>
 * <dt>U</dt><dd>Interpret <i>text</i> as a Perl regular expression. Support for Unix syntax regular expressions has been removed.</dd>
 * <dt>B</dt><dd>Interpret <i>text</i> as a Perl regular expression. Support for Brief syntax regular expressions has been removed.</dd>
 * </dl>
 * 
 * @return Returns 0 if match is found
 * 
 * @see _lbsearch
 * 
 * @appliesTo List_Box
 * 
 * @categories List_Box_Methods
 * 
 */
_str _lbi_search(_str &last_data, _str text, _str case_sense="", ...)
{
   switch (p_multi_select) {
   case MS_NONE:
      if (_lbisline_selected()) {
         _lbdeselect_line();
      }
      break;
#if 0
   case MS_EXTENDED:
      _lbdeselect_all();
      break;
#endif
   }
   return(_lbi_search2(last_data,text,case_sense));
}
static _str _lbi_search2(_str &last_data, _str text, _str options="")
{
   typeless add_char=0;
   typeless sub_char=0;
   typeless last_status="";
   last_text := "";
   parse last_data with last_status last_text;
   _lbexit_scroll();
#if 0
   if (p_scroll_left_edge>=0) {
      // parse _scroll_page() with line_pos down_count ;
      // goto_point line_pos
      // down down_count
      // set_scroll_pos p_scroll_left_edge,0
      p_scroll_left_edge= -1;
   }
#endif
   if (options=='') {
      options='i';
   }
   if (last_text!='') {
      if (last_status) {
         bool prefix_not_found=substr(text,1,length(last_text)):==last_text &&
               length(last_text)<=length(text);
         if (last_status && prefix_not_found) {
            return(STRING_NOT_FOUND_RC);
         }
      }
      add_char=substr(text,1,length(last_text)):==last_text &&
               length(last_text)+1==length(text);
      if (!add_char && length(last_text)-1==length(text) &&
           substr(last_text,1,length(text))==text && text:!='') {
         typeless status=0;
         // Go back up the list until find mismatch or top line
         ignore_case := pos('i',options,1,'i');

         for (;;) {
            status=_lbup();
            if (status) {
               _lbdown();
               break;
            }
            _str line=_lbget_text();
            if (ignore_case) {
               if (!strieq(substr(line,1,length(text)),text)) {
                  _lbdown();
                  _lbline_to_top();
                  break;
               }
            } else if(substr(line,1,length(text))!=text){
               _lbdown();
               _lbline_to_top();
               break;
            }
         }
         last_data=status' 'text;
         return(status);
      }
   } else {
      last_status=0;
   }
   //  IF the list box has a picture, use regular expression to match
   //  text
   _str retext;
   if (pos('[rRuUbB]',options,1,'ri')) {
      retext="^":+text;
   } else {
      retext="^":+_escape_re_chars(text);
   }
   if (!add_char) {
      _lbtop();
   }
   lineNum := _lbsearch_index(p_line,retext,'@r'options);
   //int status=search(retext:+arg(4),options);
   int status;
   if (lineNum<0) {
      status=lineNum;
   } else {
      status=0;
      p_line=lineNum;
   }

   if (status) {
      if (last_status && add_char) {
         return(status);
      }
      if (!last_status && add_char) {
      } else {
         text='';
      }
   }
   last_data=status' 'text;
   return(status);
}
/**
 * Places the cursor on the next or first selected item of a list box.  
 * Specify a non-zero value for the <i>find_first</i> parameter to find the 
 * first selected item.  This function is intended for list boxes with the 
 * <b>p_multi_select</b> property set to MS_EXTENDED or MS_SIMPLE_LIST.   If 
 * <b>p_multi_select</b> is set to MS_NONE, the line at the cursor is the only 
 * line that can be selected (unless a macro has a bug).
 * 
 * @return Returns 0 if a selected item is found.
 * 
 * @see _lbdeselect_all
 * @see _lbselect_all
 * @see _lbselect_line
 * @see _lbdeselect_line
 * @see _lbinvert
 * @see _lbisline_selected
 * @see _lbmulti_select_result
 * 
 * @appliesTo List_Box
 * 
 * @categories List_Box_Methods
 * 
 */
int _lbfind_selected(bool find_first)
{
   if (find_first) {
      p_line=0;
   }
   lineNum := _lbfind_next_selected_index(p_line);
   if (lineNum<0) {
      p_line=lineNum;
      return(STRING_NOT_FOUND_RC);
   } else {
      p_line=lineNum;
      return(0);
   }
}

/**
 * Inserts each line in the given file as a line in the list
 * box.
 *
 * @param filename
 *
 * @appliesTo List_Box
 *
 * @categories List_Box_Methods
 *
 */
void _lbinsert_file(_str filename)
{
   int tempViewId;
   int listBoxId=_create_temp_view(tempViewId);
   if (!listBoxId) {
      // something went wrong
      return;
   }

   // get our file into the temp view
   get(_maybe_quote_filename(filename));
   p_window_id=tempViewId;

   // get each line and enter it into the listbox
   line := "";
   top();up();
   listBoxId._lbbegin_update();
   while (!down()) {
      get_line(line);
      line = strip(line);
      p_window_id=listBoxId;
      _lbadd_item_index(-1, line, 0);
      p_window_id=tempViewId;
   }
   listBoxId._lbend_update(listBoxId.p_Noflines);

   // all done
   _delete_temp_view(tempViewId);
   activate_window(listBoxId);
   _lbtop();
}

_command void insert_file_into_listbox(_str filename='') name_info(',')
{
   _lbinsert_file(filename);
}

static bool maybeChangeCaseSensitive(_str &options)
{
	newCS := false;
	if (options != '') {
		// gotta be one or the other, please
		if (!strieq(options, 'e') && !strieq(options, 'i')) {
			options = '';
		} else {
			newCS = strieq(options, 'e');
			if (newCS == p_case_sensitive) options = '';
		}
	}

	// maybe change the case sensitivity
	oldCS := p_case_sensitive;
	if (options != '') {
		p_case_sensitive = newCS;
	}

   return oldCS;
}

static void maybeRestoreCaseSensitive(_str options, bool oldCS)
{
	if (options != '') {
		p_case_sensitive = oldCS;
	}
}

/**
 * Searches for an item in the list box.  If the item is found,
 * we select it.
 *
 * @param item          				item to search for.
 * @param options                   'i' for case-insensitive
 *                                  searching, 'e' for exact
 *                                  match, '' to use the
 *                                  existing p_case_sensitive
 *                                  value
 * @param selectTopIfNotFound       if the item is not found,
 *                                  the topmost item in the list
 *                                  is selected
 *
 * @return int          0 if item is found, error code otherwise
 *
 * @appliesTo List_Box, Combo_Box
 *
 * @categories List_Box_Methods, Combo_Box_Methods
 *
 */
int _lbfind_and_select_item(_str item, _str options = '', bool selectTopIfNotFound = false)
{
	// maybe change the case sensitivity
	oldCS := maybeChangeCaseSensitive(options);

   // find the item
   index := _lbfind_item(item);

	// restore the case sensitivity value
   maybeRestoreCaseSensitive(options, oldCS);

   if (index >= 0) {
      // line number is index + 1
      p_line = index + 1;
      if (p_object==OI_COMBO_BOX) {
         p_text = _lbget_text();
      }
      _lbselect_line();

      return 0;
   } else if (selectTopIfNotFound) {
      p_line = 1;
		p_text = _lbget_text();
      _lbselect_line();
   }

   // just pass along the error code
   return index;
}

/**
 * Searches for an item in the list box.  If the item is found,
 * we delete it.
 *
 * @param item          				item to search for.
 * @param options                   'i' for case-insensitive
 *                                  searching, 'e' for exact
 *                                  match, '' to use the
 *                                  existing p_case_sensitive
 *                                  value
 *
 * @return int          0 if successful
 *
 * @appliesTo List_Box, Combo_Box
 *
 * @categories List_Box_Methods, Combo_Box_Methods
 *
 */
int _lbfind_and_delete_item(_str item, _str options = '')
{
   if (!_lbfind_and_select_item(item, options)) {
      _lbdelete_item();
   }

   return 0;
}

const LBADD_TOP=          1;
const LBADD_BOTTOM=       2;
const LBADD_SORT=         3;

/**
 * Determines if an item already exists in a combo box.  If not, 
 * the item is added. 
 * 
 * @param item          item to search for.
 * @param options       i' for case-insensitive searching, 'e'
 *    						for exact atch, '' to use the existing
 *    						p_case_sensitive value
 * @param addOption		where to add the new item (LBADD_TOP to
 *    						add it to the beginning of the list,
 *    						LBADD_BOTTOM to add at the end of the
 *    						list, LBADD_SORT to sort the list after
 *    						adding)
 * 
 * @return int 
 * @appliesTo List_Box, Combo_Box
 *
 * @categories List_Box_Methods, Combo_Box_Methods
 *
 */
int _lbadd_item_no_dupe(_str item, _str options = '', int addOption = 0, bool selectItem = false)
{
	// maybe change the case sensitivity
	oldCS := maybeChangeCaseSensitive(options);

   // find the item
   index := _lbfind_item(item);

	// restore the case sensitivity value
   maybeRestoreCaseSensitive(options, oldCS);

   // not found!
   if (index < 0) {

      // it's not there, so we add it
      if (addOption == LBADD_TOP) {
         _lbtop(); _lbup();
      } else if (addOption == LBADD_BOTTOM) {
         _lbbottom();
      }

      // add it
      _lbadd_item(item);

      // maybe sort
      if (addOption == LBADD_SORT) {
         _lbsort();
      }
   }

   if (selectItem) {
      _lbfind_and_select_item(item, options);
   }

   return 0;
}

/**
 * @return Returns the number of lines currently selected in the 
 *         list box.
 *
 * @see _lbdeselect_all
 * @see _lbselect_all
 * @see _lbselect_line
 * @see _lbdeselect_line
 * @see _lbinvert
 * @see _lbisline_selected
 * @see _lbfind_selected
 *
 * @appliesTo List_Box
 *
 * @categories List_Box_Methods
 */
int _lbnum_selected()
{
   // a very good place to start
   numSelected := 0;

   // start at the beginning and find all the selected items
   lineNum := _lbfind_next_selected_index(1);
   while (true) {
      // negative means we didn't find anything
      if (lineNum < 0) break;

      numSelected++;

      // substract one, because index is 0-based and line numbers are 1-based
      lineNum = _lbfind_next_selected_index(lineNum);
   }

   return numSelected;
}

/**
 * Gets the selected items and puts them in a handy array.
 * 
 * @param selected         array of selected items
 *
 * @appliesTo List_Box
 *
 * @categories List_Box_Methods
 */
void _lbget_selected_array(_str (&selected)[])
{
   // a fresh start
   selected._makeempty();

   _str item;
   int t1;

   // start at the beginning and find all the selected items
   lineNum := _lbfind_next_selected_index(1);
   while (true) {
      // negative means we didn't find anything
      if (lineNum < 0) break;

      _lbget_item_index(lineNum, item, t1);
      selected[selected._length()] = item;

      // substract one, because index is 0-based and line numbers are 1-based
      lineNum = _lbfind_next_selected_index(lineNum);
   }
}
