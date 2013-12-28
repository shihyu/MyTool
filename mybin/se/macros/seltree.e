////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49623 $
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
#include "tagsdb.sh"
#import "dlgman.e"
#import "listbox.e"
#import "math.e"
#import "tagfind.e"
#import "stdprocs.e"
#import "tagform.e"
#import "treeview.e"
#endregion


///////////////////////////////////////////////////////////////////////////////
// This module implements a generic dialog for displaying a selection
// list in a tree control.  It is intended to be a clean, modern
// replacement for _sellist_form, and support most of the features
// of _sellist_form.
//
// The main entry point is the select_tree() function.
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Test code.
//
static _str test_select_cb(int reason, typeless user_data, typeless info=null)
{
   switch (reason) {
   case SL_ONDEFAULT:
      select_tree_message("Default message");
      break;
   case SL_ONINIT:
      select_tree_message("Filtering...");
      break;
   case SL_ONINITFIRST:
      select_tree_message(user_data);
      break;
   case SL_ONSELECT:
      _str caption=ctl_tree._TreeGetCaption(info);
      parse caption with caption "\t" .;
      select_tree_message(caption);
      break;
   }
   return '';
}
_command void test_select_tree(_str info='')
{
   _str captions[];
   _str keys[];
   int bitmaps[];
   int status=tag_read_db(_GetWorkspaceTagsFilename());
   if (status < 0) {
      return;
   }
   status = tag_find_prefix("");
   while (!status && captions._length()<1000) {
      _str tag_name,tag_class,tag_type;
      _str file_id,file_name;
      int tag_flags,file_line;
      tag_get_info(tag_name,tag_type,file_name,file_line,tag_class,tag_flags);
      tag_get_detail(VS_TAGDETAIL_file_id,file_id);

      int leaf_flag=0;
      int pic_member=0;
      int i_access,i_type;
      tag_tree_filter_member2(0,0,tag_type,(tag_class!='')?1:0,tag_flags,i_access,i_type);
      tag_tree_select_bitmap(i_access,i_type,leaf_flag,pic_member);
      keys[keys._length()]=(int)file_id*10000+(int)file_line;
      bitmaps[bitmaps._length()]=pic_member;

      captions[captions._length()]=tag_name"\t"tag_type"\t"tag_class"\t"file_name"\t"file_line;
      status = tag_next_prefix("");
   }
   tag_reset_find_tag();

   int flags=SL_COMBO\
      | SL_CLOSEBUTTON\
      | SL_SELECTCLINE\
      | SL_DESELECTALL\
      | SL_ALLOWMULTISELECT\
      | SL_COLWIDTH\
      | SL_SELECTPREFIXMATCH\
      | SL_INVERT\
      | SL_SELECTALL\
      | SL_MUSTEXIST;

   if (pos(' checklist ',' 'info' ',1,'i')) {
      flags|=SL_CHECKLIST;
      flags&=~SL_ALLOWMULTISELECT;
   }

   boolean select_array[];

   select_array[0]=true;
   select_array[1]=false;
   select_array[2]=false;
   select_array[3]=true;
   select_array[4]=true;
   select_array[5]=false;
   select_array[6]=true;
   select_array[7]=false;
   select_array[8]=true;
   select_array[9]=true;

   _str result = select_tree(captions, keys, bitmaps, null,
                             select_array,
                             test_select_cb,
                             "Hello, world",
                             "This is a test, select something",
                             flags,
                             "Tag,Type,Class,File,Line",
                             (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT)',' :+
                             (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT)',' :+
                             (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT)',' :+
                             (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_FILENAME)',' :+
                             (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_AL_RIGHT),
                             true,
                             "?This is the help message");
   //_message_box("selected: "result);

   //result = select_tree(tags_filenamea());
   //_message_box("selected: "result);
}


///////////////////////////////////////////////////////////////////////////////
// Main entry point

/**
 * Displays a selection list in a tree control.
 * <p>
 * <b>Syntax:</b>
 * <pre>
 *    _str result=select_tree(captions_array, key_array,
 *                            non_current_pic_array, current_pic_array,
 *                            callback_function, user_data,
 *                            dialog_caption, flags,
 *                            column_names, column_flags, modal);
 * </pre>
 * <p>
 * <b>Flags:</b>  The selection tree supports the following
 *                flags defined in "slick.sh":
 * <ul>
 * <li><b>SL_ALLOWMULTISELECT</b>
 *    Allow multiple items to be selected.  Multiple items are
 *    separated with newline (\n) characters.  Currently this function
 *    does not support items which contain newline characters.
 * <li><b>SL_NOTOP</b>
 *    Don't position cursor at top of list.
 * <li><b>SL_SELECTCLINE</b>
 *    Select the current line in the list box when initializing.
 * <li><b>SL_MATCHCASE</b>
 *    Case sensitive incremental searching in list box.
 *    Has no effect if SL_NOISEARCH flag is given.
 * <li><b>SL_INVERT</b>
 *    Display Invert button
 * <li><b>SL_SELECTALL</b>
 *    Display Select All button.
 * <li><b>SL_DELETEBUTTON</b>
 *    Display Delete button.
 * <li><b>SL_DEFAULTCALLBACK</b>
 *    Call the callback routine when default button invoked.
 * <li><b>SL_COMBO</b>
 *    Display combo box above tree control
 * <li><b>SL_MUSTEXIST</b>
 *    Selected item must exist.
 * <li><b>SL_DESELECTALL</b>
 *    Deselect all items in list box when initializing.
 * <li><b>SL_NORETRIEVEPREV</b>
 *    Don't retrieve last combo box value.
 *    By default, last combo box value
 *    is restored when initial_value not given.
 *    Has no effect if SL_COMBO not given
 * <li><b>SL_COLWIDTH</b>
 *    Compute column width settings and set up 'n' columns.
 *    Applies only if column_names are given
 * <li><b>SL_SELECTPREFIXMATCH</b>
 *    Effects SL_COMBO only.  When typing in the combo box
 *    and text is a prefix match of the text in the list box,
 *    list box line is selected.  If not given, it will do
 *    a match for any substring (can be overridden by "prefix" checkbox.
 * <li><b>SL_CLOSEBUTTON</b>
 *    Use Close instead of Cancel button
 * <li><b>SL_CHECKLIST</b>
 *    Use checkmarks for bitmaps.  If bitmap arrays are specified, they will
 *    be overridden.  If a select_array is specified, the selected items will
 *    be checked.
 * <li><b>SL_XY_WIDTH_HEIGHT</b>
 *    Save and retrieve the size and position of the form for
 *    next time use.  To distinguish between uses of the
 *    _select_tree_form, use the retrieve_name argument.
 * </ul>
 * <p>
 * The following selection list flags are not supported by the
 * selection tree dialog:
 * <code>SL_VIEWID, SL_FILENAME, SL_BUFID, SL_NOISEARCH,
 * SL_NODELETELIST, SL_HELPCALLBACK</code>
 * </ul>
 * <p>
 * <b>Callback:</b>
 * See example below for more information about call back function.
 * The prototype for the callback function is as follows:
 * <pre>
 *    _str select_tree_cb(int sl_event, typeless user_data, typeless info=null);
 * </pre>
 * The <code>callback_name</code> argument specifies the address of
 * a callback function to call for the following events.
 * For backward compatibility, this parameter can be a global function name.
 * Specify null or "" to specify no call back function.
 * <p>
 * Since there may be new call back events in the future, make sure you
 * test for the correct call back event.  The following are possible
 * values for sl_event:
 * <ul>
 * <li><b>SL_ONINITFIRST</b>
 *      First Dialog initialized callback, before autosizing
 * <li><b>SL_ONCLOSE</b>
 *      Dialog is about to be closed
 * <li><b>SL_ONINIT</b>
 *       Dialog box being initialized or reinitialized (loading items)
 * <li><b>SL_ONDEFAULT</b>
 *       Enter pressed and SL_DEFAULTCALLBACK flag was specified
 * <li><b>SL_ONLISTKEY</b>
 *       not supported
 * <li><b>SL_ONDELKEY</b>
 *       The Delete key was pressed in the list box,
 *       or they pressed the Delete button.
 * <li><b>SL_ONUSERBUTTON</b>
 *       not supported
 * <li><b>SL_ONSELECT</b>
 *     Selected item(s) changed.  'info' is the index of selected item.
 * </ul>
 * <p>
 * For any sl_event, the form is closed if result!=''.
 * When this occurs, the return value of selection list is the
 * return value of the callback.  If the return value from the
 * callback is <code>null</code>, the normal processing for that
 * event is short-circuited.
 * <p>
 * <b>Controls:</b>
 * <ul>
 * <li>The control name of the tree control is "ctl_tree".
 * <li>The control name for the combo box is "ctl_search".
 * <li>The control name for the default button is always "ctl_ok".
 * <li>The control name for the message label is "ctl_message".
 * <li>The control name for the prefix checkbox is "ctl_prefix".
 * <li>The control name for the bottom panel is "ctl_bottom_pic"
 * </ul>
 * <p>
 * You can add controls to the bottom of ths form dynamically
 * through the callbacks.  For SL_ONINITFIRST, add the controls
 * to ctl_bottom_pic, and set it's height.  The resize will take
 * care of the rest.  Catch SL_ONCLOSE to handle settings for
 * the dynamic controls.
 *
 * @param cap_array Array of strings for item captions
 *                  to insert into tree control
 * @param key_array Parallel array of keys to be stored
 *                  in user-data for each item in tree
 * @param pic_array_non
 *                  Parallel array of bitmaps to use for the
 *                  non-current bitmap for each item in tree
 * @param pic_array_cur
 *                  Parallel array of bitmaps to use for the
 *                  current bitmap for each item in tree
 * @param select_array
 *                  Parallel array of bitmaps to use for selecting
 *                  nodes in the tree.  If (sl_flags&SL_CHECKLIST), these
 *                  nodes will be checked.
 * @param callback  Callback function, see callback details above
 * @param user_data User data to pass along to callback function
 * @param caption   Dialog caption
 * @param sl_flags  bitset of SL_* selection list flags (see above)
 * @param col_names Comma delimited list of column names for tree
 * @param col_flags Comma delimited list of column flags for tree
 * @param modal     (default true) Display modal dialog?
 * @param help_item Specifies help ({@link p_help}) displayed when
 *                  F1 is pressed or the help button is pressed.
 *                  If the help_item starts with a '?' character,
 *                  the characters that follow are displayed in
 *                  a message box.
 * @param retrieve_name
 *                  Usually the name of the command which invoked this
 *                  function or the type of item being prompted for.
 *                  May be ''. Useful if the combo box is
 *                  displayed or if the SL_XY_WIDTH_HEIGHT flag
 *                  is used to save the size and position.
 *
 * @return Returns COMMAND_CANCELLED_RC if the dialog box is cancelled. If a key
 *         array was given, return the key(s) corresponding to the selections
 *         made, otherwise, return the item caption(s) separated by newline (\n)
 *         characters. Returns an empty string if nothing was selected.  If the
 *         callback handles SL_DEFAULT, return whatever the user-defined
 *         callback returns.
 * 
 * @example This example simply displays a list of tag files.
 * <pre>
 *    result = select_tree(tags_filenamea());
 * </pre>
 * <p>
 * This is a more sophisticated example that displays a list of tags
 * in the project tag file starting with the prefix 'b' and allows
 * you to select multiple items from a multi-column tree control,
 * sorting items by the columns of your choice.
 * <pre>
 *    _command void test_select_tree()
 *    {
 *       _str captions[];
 *       _str keys[];
 *       int bitmaps[];
 *       int status=tag_read_db(_GetWorkspaceTagsFilename());
 *       if (status) {
 *          return;
 *       }
 *       status = tag_find_prefix("");
 *       while (!status && captions._length()<1000) {
 *          _str tag_name,tag_class,tag_type;
 *          _str file_id,file_name;
 *          int tag_flags,file_line;
 *          tag_get_info(tag_name,tag_type,file_name,file_line,tag_class,tag_flags);
 *          tag_get_detail(VS_TAGDETAIL_file_id,file_id);
 *
 *          int leaf_flag=0;
 *          int pic_member=0;
 *          int i_access,i_type;
 *          tag_tree_filter_member(0,tag_type,(tag_class!='')?1:0,tag_flags,i_access,i_type);
 *          tag_tree_select_bitmap(i_access,i_type,leaf_flag,pic_member);
 *          keys[keys._length()]=(int)file_id*10000+(int)file_line;
 *          bitmaps[bitmaps._length()]=pic_member;
 *
 *          captions[captions._length()]=tag_name"\t"tag_type"\t"tag_class"\t"file_name"\t"file_line;
 *          status = tag_next_prefix("");
 *       }
 *
 *       _str result = select_tree(captions, keys, bitmaps, null,
 *                                 test_select_cb, "Hello, world",
 *                                 "This is a test, select something",
 *                                 SL_COMBO
 *                                  | SL_CLOSEBUTTON
 *                                  | SL_SELECTCLINE
 *                                  | SL_DESELECTALL
 *                                  | SL_ALLOWMULTISELECT
 *                                  | SL_COLWIDTH
 *                                  | SL_SELECTPREFIXMATCH
 *                                  | SL_INVERT
 *                                  | SL_SELECTALL
 *                                  | SL_MUSTEXIST,
 *                                 "Tag,Type,Class,File,Line",
 *                                 (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT)',' :+
 *                                 (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT)',' :+
 *                                 (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT)',' :+
 *                                 (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_FILENAME)',' :+
 *                                 (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_AL_RIGHT),
 *                                 false,
 *                                 "?This is the help message");
 *    }
 * </pre>
 * <p>
 * This is an example callback function.
 * <pre>
 *    static _str test_select_cb(int reason, typeless user_data, typeless info=null)
 *    {
 *       switch (reason) {
 *       case SL_ONDEFAULT:
 *          select_tree_message("Default message");
 *          break;
 *       case SL_ONINIT:
 *          select_tree_message("Filtering...");
 *          break;
 *       case SL_ONINITFIRST:
 *          select_tree_message(user_data);
 *          break;
 *       case SL_ONSELECT:
 *          _str caption=ctl_tree._TreeGetCaption(info);
 *          parse caption with caption "\t" .;
 *          select_tree_message(caption);
 *          break;
 *       }
 *       return '';
 *    }
 * </pre>
 * <p>
 * This is an example of a callback function that adds custom controls.
 * <pre>
 *    static _str test_select_option_cb(int reason, typeless user_data, typeless info=null)
 *    {
 *       switch (reason) {
 *       case SL_ONINITFIRST:
 *          if ( def_ask_a_question) {
 *             bottom_wid := _find_control("ctl_bottom_pic");
 *             checkb_wid := _create_window(OI_CHECK_BOX, bottom_wid, "Do not show these options again", 0, 30, bottom_wid.p_width, 270, CW_CHILD);
 *             bottom_wid.p_height = 300;
 *             bottom_wid.p_visible = bottom_wid.p_enabled = true;
 *             checkb_wid.p_name = "ctlhideoptions";
 *          }
 *          break;
 *       case SL_ONCLOSE:
 *          wid := p_active_form._find_control('ctlhideoptions');
 *          if (wid && wid.p_value) {
 *             def_ask_a_question = false;
 *             _config_modify_flags(CFGMODIFY_DEFVAR)
 *          }
 *          break;
 *       }
 *       return '';
 *    }
 * </pre>
 *  
 * @categories Forms
 */
_str select_tree(_str (&cap_array)[]=null,
                 _str (&key_array)[]=null,
                 int (&pic_array_non)[]=null,
                 int (&pic_array_cur)[]=null,
                 boolean (&select_array)[]=null,
                 typeless callback=null, typeless user_data=null,
                 _str caption=null, int sl_flags=0,
                 _str col_names=null, _str col_flags=null,
                 boolean modal=true,
                 _str help_item=null, _str retrieve_name=null)
{
   nocenter_arg := (sl_flags & SL_XY_WIDTH_HEIGHT)? "-nocenter ":"";
   modal_arg := modal? "-modal ":"";
   return show(modal_arg:+nocenter_arg:+"_select_tree_form",
               cap_array,key_array,pic_array_non,pic_array_cur,
               select_array,
               callback,user_data,
               caption,sl_flags,
               col_names,col_flags,
               help_item,retrieve_name);
}

/**
 * This function is intended to be used within selection tree
 * callback functions to set/reset the message displayed in
 * the message bar of the dialog.
 *
 * @param msg     message to display
 */
void select_tree_message(_str msg)
{
   _nocheck _control ctl_message;
   if (msg==null) msg="";
   p_active_form.ctl_message.p_caption=msg;
}

///////////////////////////////////////////////////////////////////////////////
// Selection tree dialog implemention
//
defeventtab _select_tree_form;

// use p_user for flags, callback function, user data, and retrieve name
#define SELECT_TREE_FLAGS     ctl_tree.p_user
#define SELECT_TREE_CALLBACK  ctl_ok.p_user
#define SELECT_TREE_USERDATA  ctl_cancel.p_user
#define SELECT_TREE_RETRIEVE  ctl_search.p_user
#define SELECT_TREE_HEIGHT    ctl_invert.p_user

void _select_tree_form.on_load()
{
   ctl_tree.select_tree_callback(ST_ONLOAD);
}

// resize callback, handles all cases
void _select_tree_form.on_resize()
{
   // minimum height/width so controls aren't obscured
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      int n=3;
      if (SELECT_TREE_FLAGS & SL_INVERT) ++n;
      if (SELECT_TREE_FLAGS & SL_SELECTALL) ++n;
      if (SELECT_TREE_FLAGS & SL_DELETEBUTTON) ++n;
      _set_minimum_size(n*ctl_ok.p_width, 6*ctl_ok.p_height);
   }

   // available space
   int avail_x = p_width;
   int avail_y = p_height;

   // subtract the height of the user control area from the total
   avail_y -= ctl_bottom_pic.p_height;
   ctl_bottom_pic.p_y = avail_y;
   ctl_bottom_pic.p_width = avail_x-600;

   // margin space
   int margin_x = ctl_tree.p_x;
   int margin_y = ctl_search.p_y;

   // calculate space for combo box
   int combo_y = margin_y + ctl_search.p_height;
   if (ctl_search.p_visible==false) {
      combo_y=0;
   }

   // buttons
   ctl_ok.p_y=ctl_cancel.p_y=avail_y-ctl_ok.p_height-margin_y;
   ctl_invert.p_y=ctl_ok.p_y;
   ctl_selectall.p_y=ctl_ok.p_y;
   ctl_delete.p_y=ctl_ok.p_y;
   if (!(SELECT_TREE_FLAGS & SL_INVERT)) {
      ctl_delete.p_x=ctl_selectall.p_x;
      ctl_selectall.p_x=ctl_invert.p_x;
   }
   if (!(SELECT_TREE_FLAGS & SL_SELECTALL)) {
      ctl_delete.p_x=ctl_selectall.p_x;
   }

   // move tree up if combo is missing
   if (ctl_search.p_visible==false) {
      ctl_tree.p_y=margin_y;
   }

   // tree
   int orig_tree_width=ctl_tree.p_width;
   ctl_tree.p_width=avail_x-2*margin_x;
   ctl_tree.p_height=ctl_cancel.p_y-margin_y-ctl_tree.p_y;

   // combo box
   ctl_prefix.p_width=ctl_prefix._text_width(ctl_prefix.p_caption)+250 /* fudge factor */;
   ctl_prefix.p_x = avail_x-margin_x-ctl_prefix.p_width;
   ctl_search.p_width=avail_x-margin_x*3-ctl_search.p_x-ctl_prefix.p_width;

   // message box
   int left_wid=ctl_cancel;
   if (SELECT_TREE_FLAGS & SL_INVERT) left_wid=ctl_invert;
   if (SELECT_TREE_FLAGS & SL_SELECTALL) left_wid=ctl_selectall;
   if (SELECT_TREE_FLAGS & SL_DELETEBUTTON) left_wid=ctl_delete;
   ctl_message.p_x=left_wid.p_x+left_wid.p_width+margin_x*2;
   ctl_message.p_width=avail_x-margin_x*4-ctl_message.p_x;
   ctl_message.p_y=ctl_ok.p_y+margin_y;

   // adjust column widths of tree
   ctl_tree._TreeAdjustColumnWidths(-1);
   ctl_tree.select_tree_callback(SL_ONRESIZE);
   parse SELECT_TREE_HEIGHT with auto restore_height auto calc_height;
   if (!isuinteger(restore_height) || !isuinteger(calc_height)) {
      SELECT_TREE_HEIGHT = p_active_form.p_height' 'calc_height;
   } else if ( !isapprox(p_active_form.p_height, restore_height, 100) && 
               !isapprox(p_active_form.p_height, calc_height, 100) ) {
      SELECT_TREE_HEIGHT = p_active_form.p_height' 'calc_height;
   }
}

/**
 * Call the callback function for the specified event and
 * pass along the user data and supplemental information.
 *
 * @param reason     SL_* event code
 * @param info       event data
 *
 * @return <code>true</code> if the event is short-circuited
 *         or the dialog is closed.
 *         <code>false</code> for the normal case.
 */
static boolean select_tree_callback(int reason, typeless info=null)
{
   typeless callback=SELECT_TREE_CALLBACK;
   if (info==null) info=ctl_tree._TreeCurIndex();
   if (callback!=null) {
      _str result=(*callback)(reason,SELECT_TREE_USERDATA,info);
      if (result==null) return(true);
      if (result!='') {
         (*callback)(SL_ONCLOSE,SELECT_TREE_USERDATA,result);
         p_active_form._delete_window(result);
         return(true);
      }
   }
   return(false);
}

/**
 * Call the callback function to notify that the select tree dialog
 * is about to be closed.
 */
static void select_tree_close_callback(typeless info=null)
{
   typeless callback=SELECT_TREE_CALLBACK;
   if (info==null) info=ctl_tree._TreeCurIndex();
   if (callback!=null) {
      (*callback)(SL_ONCLOSE,SELECT_TREE_USERDATA,info);
   }
}

/**
 * Enter pressed on combo box, call ONDEFAULT callback
 * and maybe pass event along to OK button.
 */
void ctl_search.ENTER()
{
   if (ctl_tree.select_tree_callback(SL_ONDEFAULT)) {
      return;
   }
   ctl_ok.call_event(ctl_ok,LBUTTON_UP);
}

/**
 * Change prefix / substring matching option and refilter items.
 */
void ctl_prefix.lbutton_up()
{
   int flags = SELECT_TREE_FLAGS;
   if (p_value) {
      flags |= SL_SELECTPREFIXMATCH;
   } else {
      flags &= ~SL_SELECTPREFIXMATCH;
   }
   SELECT_TREE_FLAGS=flags;
   if (ctl_search.p_text!='') {
      ctl_search.call_event(CHANGE_OTHER,1,ctl_search,ON_CHANGE,'');
   }
}

/**
 * Refilter when items in combo box change.
 */
void ctl_search.on_change(int reason)
{
   // no incremental search, ok, then fine, don't do anything
   if (SELECT_TREE_FLAGS & SL_NOISEARCH) {
      return;
   }

   // get the search string, and re-insert items using creation callback
   _str search_string=p_text;
   if (ctl_tree.select_tree_callback(SL_ONINIT,search_string)) {
      return;
   }

   // if no search string, unhide all items in the tree
   if (search_string=='') {
      ctl_tree._TreeSetAllFlags(0,TREENODE_HIDDEN);
      ctl_tree._TreeTop();
      return;
   }

   int wid=p_window_id;
   p_window_id=ctl_tree;
   typeless sc,nb,cb;
   boolean filter_items=(SELECT_TREE_FLAGS & SL_COMBO)? true:false;
   int prefix_pos=(SELECT_TREE_FLAGS & SL_SELECTPREFIXMATCH)? 1:MAXINT;
   _str case_opt=(SELECT_TREE_FLAGS & SL_MATCHCASE)? '':'i';
   int index = ctl_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   boolean first_one=true;
   if (filter_items) {
      _TreeDeselectAll();
   }
   int time1=0,time2=0;
   while (index > 0) {
      _str caption = _TreeGetCaption(index);
      int p = pos(search_string,caption,1,case_opt);
      if (p > 0 && p <= prefix_pos) {
         if (filter_items) {

            int flags;
            _TreeGetInfo(index,sc,nb,cb,flags);
            boolean select = false;
            if (first_one) {
               first_one=false;
               select = true;
               // Scroll this node into view
               _TreeSetCurIndex(index);
            }
            ctl_tree._TreeSetInfo(index,sc,nb,cb,flags&~(TREENODE_HIDDEN));
            if ( select ) _TreeSelectLine(index);

            ctl_tree._TreeGetInfo(index,sc,nb,cb);
            ctl_tree._TreeSetInfo(index,sc,nb,cb,0);
         } else {
            _TreeSetCurIndex(index);
            break;
         }
      } else if (filter_items) {
         _TreeGetInfo(index,sc,nb,cb);
         _TreeSetInfo(index,sc,nb,cb,TREENODE_HIDDEN);
      }
      index = _TreeGetNextSiblingIndex(index);
   }
   p_window_id=wid;
}

/**
 * Handle tree events, treat ENTER like OK button.
 */
void ctl_tree.on_change(int reason,int index)
{
   if (reason==CHANGE_SELECTED) {
      ctl_tree.select_tree_callback(SL_ONSELECT,index);
   } else if (reason==CHANGE_LEAF_ENTER) {
      if (ctl_tree.select_tree_callback(SL_ONDEFAULT)) {
         return;
      }
      ctl_ok.call_event(ctl_ok,LBUTTON_UP);
   }
}

/**
 * Handle tree events, treat double click like default
 */
void ctl_tree.lbutton_double_click()
{
   if (ctl_tree.select_tree_callback(SL_ONDEFAULT)) {
      return;
   }
   // Only call lbutton_up() when the user double-clicked on an
   // actual item in the tree (rather than a column button, etc.).
   int x = mou_last_x();
   int y = mou_last_y();
   int index = _TreeGetIndexFromPoint(x,y,'P');
   if( index >= 0 ) {
      ctl_ok.call_event(ctl_ok,LBUTTON_UP);
   }
}

/**
 * Catch lbutton up and space.  If the user is in checklist mode, change the
 * check.
 */
void ctl_tree.' '()
{
   if (SELECT_TREE_FLAGS&SL_CHECKLIST) {
      index := _TreeCurIndex();
      if ( index>=0 ) {
         newState := _TreeGetCheckState(index)? TCB_UNCHECKED:TCB_CHECKED;
         _TreeSetCheckState(index,newState);
      }
   }
}

/**
 * Catch delete key, let the tree know about the event. 
 */
void ctl_tree.DEL()
{
   ctl_tree.select_tree_callback(SL_ONDELKEY);
}
void ctl_delete.lbutton_up()
{
   ctl_tree.select_tree_callback(SL_ONDELKEY);
}

/**
 * Find the next selected item.  If we are in checklist mode, this is the next
 * item with that is checked.  Otherwise, it is the next item
 * returned but _TreeGetNextSelectedIndex(x).
 */
static int SeltreeFindSelected(int ff,int &info)
{
   if (SELECT_TREE_FLAGS&SL_CHECKLIST) {
      static int tree_search_index;
      if (ff) {
         tree_search_index=TREE_ROOT_INDEX;
      }
      boolean usingPics = _GetDialogInfoHt('usingPics');
      for (;tree_search_index>-1;) {
         tree_search_index=_TreeGetNextIndex(tree_search_index);
         if (tree_search_index<0) break;
         checked := _TreeGetCheckState(tree_search_index);
         if ( checked ) {
            return tree_search_index;
         }
      }
      return(tree_search_index);
   }
   return(_TreeGetNextSelectedIndex(ff,info));
}

/**
 * Handle OK button.  Pass the list of selected items
 * to the {@link _delete_window()} method.
 */
void ctl_ok.lbutton_up()
{
   if ((SELECT_TREE_FLAGS & SL_COMBO) && !(SELECT_TREE_FLAGS & SL_NORETRIEVEPREV)) {
      _append_retrieve(ctl_search,ctl_search.p_text,p_active_form.p_name:+SELECT_TREE_RETRIEVE);
   }

   // save the sorting info
   ctl_tree._TreeAppendColButtonSorting(true, SELECT_TREE_RETRIEVE);

   _str result=null;
   int index;
   boolean checklist=(SELECT_TREE_FLAGS&SL_CHECKLIST)!=0;
   boolean gettree=(SELECT_TREE_FLAGS & SL_GET_TREEITEMS)!=0;
   if (ctl_tree.p_multi_select==MS_NONE && !checklist && !gettree) {
      // single selection
      index = ctl_tree._TreeCurIndex();
      if (index <= 0) {
         if (SELECT_TREE_FLAGS & SL_MUSTEXIST) {
            _message_box("Please select an item");
            return;
         }
         select_tree_close_callback('');
         p_active_form._delete_window('');
         return;
      }
      result = ctl_tree._TreeGetUserInfo(index);
      if (result==null || result=='') {
         result = ctl_tree._TreeGetCaption(index);
      }
      select_tree_close_callback(result);
      p_active_form._delete_window(result);
      return;
   }

   int treeSelectionInfo;
   // multiple items selected
   if (gettree) {
      index=ctl_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if (index <= 0) {
         select_tree_close_callback('');
         p_active_form._delete_window('');
         return;
      }
   } else {
      index=ctl_tree.SeltreeFindSelected(1,treeSelectionInfo);
      if (index <= 0) {
         if (SELECT_TREE_FLAGS & SL_MUSTEXIST) {
            _message_box("Please select an item");
            return;
         }
         select_tree_close_callback('');
         p_active_form._delete_window('');
         return;
      }
   }
   // use first selected item to determine if we return keys or captions
   boolean use_keys=true;
   result=ctl_tree._TreeGetUserInfo(index);
   if (result==null || result=='') {
      result=maybe_quote_filename(ctl_tree._TreeGetCaption(index));
      use_keys=false;
   }
   // add the rest of the results to the list
   if (gettree) {
      index=ctl_tree._TreeGetNextSiblingIndex(index);
   } else {
      index=ctl_tree.SeltreeFindSelected(0,treeSelectionInfo);
   }
   while (index > 0) {
      strappend(result,"\n");
      if (use_keys) {
         strappend(result,ctl_tree._TreeGetUserInfo(index));
      } else {
         strappend(result,maybe_quote_filename(ctl_tree._TreeGetCaption(index)));
      }
      if (gettree) {
         index=ctl_tree._TreeGetNextSiblingIndex(index);
      } else {
         index=ctl_tree.SeltreeFindSelected(0,treeSelectionInfo);
      }
   }
   // return the complete string
   select_tree_close_callback(result);
   p_active_form._delete_window(result);
}

/**
 * Returns COMMAND_CANCELLED_RC.  Used to return an empty string, but this was 
 * indistiguishable from multi-selecting zero items in the tree. 
 */
void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window(COMMAND_CANCELLED_RC);
}

/**
 * Flip all selected items with selected items.
 */
void ctl_invert.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctl_tree;
   if (SELECT_TREE_FLAGS&SL_CHECKLIST) {
      int index=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         newState := _TreeGetCheckState(index)? TCB_UNCHECKED:TCB_CHECKED;
         _TreeSetCheckState(index,newState);

         index=_TreeGetNextIndex(index);
      }
   } else {
      _TreeInvertSelection();
   }
   p_window_id=wid;
}
/**
 * Select all items in the tree.
 */
void ctl_selectall.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctl_tree;
   if (SELECT_TREE_FLAGS&SL_CHECKLIST) {
      int index=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         _TreeSetCheckState(index,TCB_CHECKED);
         index=_TreeGetNextIndex(index);
      }
   } else {
      _TreeSelectAll();
   }
   p_window_id=wid;
}
void ctl_tree.C_A()
{
   ctl_ok.call_event(ctl_selectall,LBUTTON_UP);
}
void ctl_tree.C_U()
{
   ctl_ok.call_event(ctl_selectall,LBUTTON_UP);
   ctl_ok.call_event(ctl_invert,LBUTTON_UP);
}

/**
 * PRIVATE, use the select_tree() or select_tree_cb() to
 * create and display the form.  Do not use show() with
 * this form.
 *
 * @param cap_array        array of tree captions to use
 * @param pic_array_non    bitmap indexes for non-current item pictures to user
 * @param pic_array_cur    bitmap indexes for current item pictures to use
 * @param create_callback  callback for populating the tree control, p_window_id=tree
 * @param user_data        data to pass to callback function, may be null
 * @param caption          dialog caption
 * @param flags            dialog creating flags
 * @param col_names        tree column names to use (separated by semicolons)
 * @param col_flags        tree column flags (separated by semicolons)
 * @param help_item        p_help
 * @param retrieve_name    name to use for dialog retrieval (combo box text)
 */
void ctl_ok.on_create(_str (&cap_array)[],
                      _str (&key_array)[]=null,
                      int (&pic_array_non)[]=null,
                      int (&pic_array_cur)[]=null,
                      boolean (&select_array)[]=null,
                      typeless callback=null,
                      typeless user_data=null,
                      _str caption=null, int flags=0,
                      _str col_names=null, _str col_flags=null,
                      _str help_item=null, _str retrieve_name=null)
{
   // did they give us a tree caption
   if (caption!=null) {
      p_active_form.p_caption=caption;
   }

   // save setup flags
   SELECT_TREE_FLAGS=flags;
   SELECT_TREE_CALLBACK=callback;
   SELECT_TREE_USERDATA=user_data;

   // allow multi-select?
   if (flags & SL_ALLOWMULTISELECT) {
      ctl_tree.p_multi_select=MS_SIMPLE_LIST;
   } else {
      ctl_tree.p_multi_select=MS_NONE;
   }

   // Select current line.
   if (flags & SL_SELECTCLINE) {
      ctl_tree.p_AlwaysColorCurrent=true;
   } else {
      ctl_tree.p_AlwaysColorCurrent=false;
   }
   ctl_tree.p_LineStyle=TREE_DOTTED_LINES;
   ctl_tree.p_scroll_bars=SB_BOTH;

   // #define SL_COMBO             0x800 // Display combo box above list box
   boolean enable_combo=(flags & SL_COMBO)? true:false;
   ctl_search.p_visible=enable_combo;
   ctl_search.p_enabled=enable_combo;
   ctl_prefix.p_visible=enable_combo;
   ctl_prefix.p_enabled=enable_combo;

   //   SL_INVERT, SL_SELECTALL
   ctl_invert.p_visible=ctl_invert.p_enabled=(flags & SL_INVERT)? true:false;
   ctl_selectall.p_visible=ctl_selectall.p_enabled=(flags & SL_SELECTALL)? true:false;
   ctl_delete.p_visible=ctl_delete.p_enabled=(flags & SL_DELETEBUTTON)? true:false;

   // #define SL_DESELECTALL       0x4000  // Deselect all before selecting anything
   if (flags & SL_DESELECTALL) {
      ctl_tree._TreeSelectLine(TREE_ROOT_INDEX,true);
   }

   // #define SL_NORETRIEVEPREV    0x10000 // Don't retrieve last combo box value
   //                              // By default, last combo box value
   //                              // is restored when initial_value not given.
   //                              // Has no effect if SL_COMBO not given

   if (flags & SL_NORETRIEVEPREV) {
      // why not just always do this
   }

   // #define SL_COLWIDTH          0x20000 // Computer largest first column text string
   //                                      // and set up two columns


   // #define SL_SELECTPREFIXMATCH 0x40000 // Effects SL_COMBO only.
   //                                      // When typing in the combo box
   //                                      // and text is a prefix match
   //                                      // of the text in the list box,
   //                                      // list box line is selected.
   ctl_prefix.p_value=(flags & SL_SELECTPREFIXMATCH)? 1:0;

   // Use Close instead of Cancel button
   if (flags & SL_CLOSEBUTTON) {
      ctl_cancel.p_caption="Close";
   }

   boolean checklist=(SELECT_TREE_FLAGS&SL_CHECKLIST)!=0;

   boolean usingPics = ((pic_array_cur != null) || (pic_array_non != null));
   ctl_tree._SetDialogInfoHt('usingPics', usingPics);

   int wid=p_window_id;
   p_window_id=ctl_tree;
   int currentIndex = -1;
   // insert items into the tree using parallel arrays
   int i,n=cap_array._length();
   for (i=0; i<n; ++i) {
      int pic_index_non=0;
      int pic_index_cur=0;
      int more_flags=0;
      int checkboxValue = 0;
      boolean selected = false;
      if (checklist) { //... and checkboxes.
         if (select_array[i]!=null) {
            checkboxValue=select_array[i]?1:0;
         } else {
            checkboxValue=0;
         }
      } else if (select_array[i]!=null) { //... and just selecting rows.
         selected = select_array[i];
      }
      if (usingPics) {
         if (pic_array_non!=null && i < pic_array_non._length()) {
            pic_index_non=pic_array_non[i];
         }
         if (pic_array_cur!=null && i < pic_array_cur._length()) {
            pic_index_cur=pic_array_cur[i];
         } else {
            pic_index_cur=pic_index_non;
         }
      }
      int index = _TreeAddItem(TREE_ROOT_INDEX, cap_array[i],
                               TREE_ADD_AS_CHILD, pic_index_non,
                               pic_index_cur, -1,
                               more_flags);
      if ( checklist ) {
         _TreeSetCheckable(index,1,0,checkboxValue);
      }
      if ( selected  ) {
         _TreeSelectLine(index);
      }
      if (select_array[i]!=null && select_array[i]) {
         currentIndex = index;
      }
      if (key_array!=null && i < key_array._length()) {
         _TreeSetUserInfo(index,key_array[i]);
      }
   }
   if (currentIndex != -1) {
      _TreeSetCurIndex(currentIndex);
   }
   p_window_id=wid;

   // set column widths
   if (col_names!=null) {
      _str cnames[];
      int cflags[];

      n = 0;
      while (true) {
         if (col_names == '' && col_flags == '') break;

         coln := '';
         if (col_names != '') {
            parse col_names with coln ',' col_names;
         }
         colf := '';
         if (col_flags != '') {
            parse col_flags with colf ',' col_flags;
         }
         if (!isinteger(colf)) colf=0;

         // set the name, initialize the flags to 0
         cnames[n] = coln;
         cflags[n] = (int)colf;
         ++n;
      }

      if (n) {
         cwidth := ctl_tree.p_width intdiv n;
         firstSort := false;
         for (i = 0; i < n; i++) {
            ctl_tree._TreeSetColButtonInfo(i,cwidth,cflags[i],0,cnames[i]);

            // if this is the first column with the sort flag, then we sort with it
            if (!firstSort && cflags[i] & TREE_BUTTON_SORT) {
               ctl_tree._TreeSortCol(i);
               firstSort = true;
            }
         }
      }
   }

   // position on first item in list
   if (!(flags & SL_NOTOP)) {
      ctl_tree._TreeTop();
   }

   // retrieve previous combo box values
   if (retrieve_name==null) retrieve_name='ctl_search';
   SELECT_TREE_RETRIEVE=retrieve_name;
   if (!(flags & SL_NORETRIEVEPREV)) {
      ctl_search._retrieve_list(p_active_form.p_name"."retrieve_name);
   }

   // restore form position and size?
   if (flags & SL_XY_WIDTH_HEIGHT) {
      p_active_form._restore_form_xy(false, p_active_form.p_name:+retrieve_name);
   }
   orig_height := p_active_form.p_height;

   // further configuration and maybe
   // insert items using creation callback
   orig_bottom_height := ctl_bottom_pic.p_height;
   ctl_bottom_pic.p_x = 300;
   ctl_tree.select_tree_callback(SL_ONINITFIRST);
   if (ctl_bottom_pic.p_height != orig_bottom_height) {
      ctl_tree.p_height -= (ctl_bottom_pic.p_height - orig_bottom_height);
   }

   // adjust columns widths according to text
   if (flags & SL_COLWIDTH) {
      numWrappedRows := 0;
      tw := ctl_tree._TreeAdjustColumnWidths(-1,&numWrappedRows);
      p_active_form.p_width = _lx2lx(ctl_tree.p_xyscale_mode,p_active_form.p_xyscale_mode,tw+ctl_tree.p_x*2+360/*scrollbar*/);

      // shrink height of form to match number of lines
      lineHeight := ctl_tree._text_height() + ctl_tree.p_SpaceY;
      numLines   := ctl_tree._TreeGetNumChildren(TREE_ROOT_INDEX, 'T');
      int screen_width = _dx2lx(SM_TWIP, _screen_width());
      if (p_active_form.p_width >= screen_width) numLines += numWrappedRows;
      calc_height := (numLines+2)*lineHeight;
      if (calc_height < 1500) calc_height=1500;
      if (ctl_tree.p_height > calc_height) {
         p_active_form.p_height -= (ctl_tree.p_height - calc_height); 
         _SetDialogInfoHt("addedHeight",ctl_tree.p_height - calc_height);
      }
   }
   // maybe retrieve tree column sorting info
   ctl_tree._TreeRetrieveColButtonSorting(true, SELECT_TREE_RETRIEVE);

   SELECT_TREE_HEIGHT = orig_height ' 'p_active_form.p_height;

   // set up help string (for F1)
   if (help_item != null) {
      p_active_form.p_help=help_item;
   }

   // add keybindings for cursor up and down to this form
   int keys[];
   copy_key_bindings_to_form("cursor-up",    ctl_tree, UP,   keys);
   copy_key_bindings_to_form("cursor-down",  ctl_tree, DOWN, keys);
   copy_key_bindings_to_form("page-up",      ctl_tree, PGUP, keys);
   copy_key_bindings_to_form("page-down",    ctl_tree, PGDN, keys);

   // give focus to the combo box
   ctl_search._set_focus();
}

void ctl_ok.on_destroy()
{
   // save form position and size?
   if (SELECT_TREE_FLAGS & SL_XY_WIDTH_HEIGHT) {
      parse SELECT_TREE_HEIGHT with auto restore_height auto calc_height;

      if ( isuinteger(restore_height) ) {

         // this is the amount of space we trimmed off the dialog in on create
         // making room for other stuff.
         addedHeight := _GetDialogInfoHt("addedHeight");
         if ( !isinteger(addedHeight) ) addedHeight = 0;
         if ( !isapprox(p_active_form.p_height, (int)restore_height, 100)) {
            p_active_form.p_height = (int)restore_height;
         } else {
            // We always have to add this on
            p_active_form.p_height += addedHeight;
         }
      }
      p_active_form._save_form_xy(p_active_form.p_name:+SELECT_TREE_RETRIEVE);
   }
}

defeventtab _list_box_form;

_ctl_ok.on_create(_str (&list)[], _str msg, _str caption = 'SlickEdit')
{
   // fill the list
   foreach (auto item in list) {
      _ctl_list._lbadd_item(item);
   }

   // set our caption
   p_active_form.p_caption = caption;

   // set our message
   _ctl_message.p_caption = msg;

   // have a nice day
}

_ctl_ok.lbutton_up()
{
   p_active_form._delete_window();
}
