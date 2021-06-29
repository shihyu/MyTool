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
#import "mprompt.e"
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
      caption := ctl_tree._TreeGetCaption(info);
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
   int overlays[];
   int status=tag_read_db(_GetWorkspaceTagsFilename());
   if (status < 0) {
      return;
   }
   status = tag_find_prefix("");
   while (!status && captions._length()<1000) {
      tag_get_tag_browse_info(auto cm);
      tag_get_detail(VS_TAGDETAIL_file_id,auto file_id);
      pic_member := tag_get_bitmap_for_type(cm.type_id,cm.flags,auto pic_overlay);
      keys :+= (int)file_id*10000+(int)cm.line_no;
      bitmaps :+= pic_member;
      overlays :+= pic_overlay;
      captions[captions._length()]=cm.member_name"\t"cm.type_name"\t"cm.class_name"\t"cm.file_name"\t"cm.line_no;
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
      | SL_MUSTEXIST\
      | SL_USE_OVERLAYS\
      | SL_DEFAULTCALLBACK;

   if (pos(' checklist ',' 'info' ',1,'i')) {
      flags|=SL_CHECKLIST;
      flags&=~SL_ALLOWMULTISELECT;
   }

   bool select_array[];

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

   _str result = select_tree(captions, keys, bitmaps, overlays,
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
   if (result != "") {
      _message_box("selected: "result);
   }
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
 * <li><b>SL_ADDBUTTON</b>
 *    Display Add button to add a new item to the list.
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
 * <li><b>SL_USE_OVERLAYS</b>
 *    Use the second set of bitmaps as overlays.
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
 * @param pic_array
 *                  Parallel array of bitmaps to use for the
 *                  bitmap for each item in tree
 * @param overlay_array
 *                  Parallel array of bitmaps to use for the
 *                  overlay bitmap for each item in tree if
 *                  (sl_flags & SL_USE_OVERLAYS), otherwise, ignored.
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
                 int (&picture_array)[]=null,
                 int (&overlay_array)[]=null,
                 bool (&select_array)[]=null,
                 typeless callback=null, 
                 typeless user_data=null,
                 _str caption=null, 
                 int sl_flags=0,
                 _str col_names=null, _str col_flags=null,
                 bool modal=true,
                 _str help_item=null, 
                 _str retrieve_name=null,
                 _str message_text=null)
{
   nocenter_arg := (sl_flags & (SL_XY_WIDTH_HEIGHT|SL_RESTORE_XY))? "-nocenter ":"";
   modal_arg := modal? "-modal ":"";
   return show(modal_arg:+nocenter_arg:+"_select_tree_form",
               cap_array,key_array,picture_array,overlay_array,
               select_array,
               callback,user_data,
               caption,sl_flags,
               col_names,col_flags,
               help_item,retrieve_name,
               message_text);
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
static int SELECT_TREE_FLAGS(...) {
   if (arg()) ctl_tree.p_user=arg(1);
   return ctl_tree.p_user;
}
static typeless SELECT_TREE_CALLBACK(...) {
   if (arg()) ctl_ok.p_user=arg(1);
   return ctl_ok.p_user;
}
static typeless SELECT_TREE_USERDATA(...) {
   if (arg()) ctl_cancel.p_user=arg(1);
   return ctl_cancel.p_user;
}
_str _PUSER_SELECT_TREE_RETRIEVE(...) {
   if (arg()) ctl_search.p_user=arg(1);
   return ctl_search.p_user;
}
static _str SELECT_TREE_HEIGHT(...) {
   if (arg()) ctl_invert.p_user=arg(1);
   return ctl_invert.p_user;
}
static _str SELECT_TREE_WIDTH(...) {
   if (arg()) ctl_selectall.p_user=arg(1);
   return ctl_selectall.p_user;
}
static _str SELECT_TREE_COLUMN_WIDTHs(...) {
   if (arg()) ctl_additem.p_user=arg(1);
   return ctl_additem.p_user;
}

void _select_tree_form.on_load()
{
   ctl_tree.select_tree_callback(ST_ONLOAD);
}

// resize callback, handles all cases
void _select_tree_form.on_resize()
{
   // minimum height/width so controls aren't obscured
   // if the minimum width has not been set, it will return 0
   select_tree_flags := SELECT_TREE_FLAGS();
   if (!_minimum_width()) {
      n := 3;
      if (select_tree_flags & SL_INVERT) ++n;
      if (select_tree_flags & SL_SELECTALL) ++n;
      if (select_tree_flags & SL_DELETEBUTTON) ++n;
      if (select_tree_flags & SL_ADDBUTTON) ++n;
      _set_minimum_size(n*ctl_ok.p_width, 6*ctl_ok.p_height);
   }

   // available space
   avail_x := p_width;
   avail_y := p_height;

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
   ctl_additem.p_y=ctl_ok.p_y;
   if (!(select_tree_flags & SL_INVERT)) {
      diff := ctl_selectall.p_x - ctl_invert.p_x;
      ctl_selectall.p_x -= diff;
      ctl_delete.p_x -= diff;
      ctl_additem.p_x -= diff;
   }
   if (!(select_tree_flags & SL_SELECTALL)) {
      diff := ctl_delete.p_x - ctl_selectall.p_x;
      ctl_delete.p_x -= diff;
      ctl_additem.p_x -= diff;
   }
   if (!(select_tree_flags & SL_DELETEBUTTON)) {
      diff := ctl_additem.p_x - ctl_delete.p_x; 
      ctl_additem.p_x -= diff;
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
   if (select_tree_flags & SL_INVERT) left_wid=ctl_invert;
   if (select_tree_flags & SL_SELECTALL) left_wid=ctl_selectall;
   if (select_tree_flags & SL_DELETEBUTTON) left_wid=ctl_delete;
   if (select_tree_flags & SL_ADDBUTTON) left_wid=ctl_additem;
   ctl_message.p_x=left_wid.p_x_extent+margin_x*2;
   ctl_message.p_width=avail_x-margin_x*4-ctl_message.p_x;
   ctl_message.p_y=ctl_ok.p_y+margin_y;

   ctl_tree.select_tree_callback(SL_ONRESIZE);
   parse SELECT_TREE_HEIGHT() with auto restore_height auto calc_height;
   if (!isuinteger(restore_height) || !isuinteger(calc_height)) {
      SELECT_TREE_HEIGHT(p_active_form.p_height' 'calc_height);
   } else if ( !isapprox(p_active_form.p_height, restore_height, 100) && 
               !isapprox(p_active_form.p_height, calc_height, 100) ) {
      SELECT_TREE_HEIGHT(p_active_form.p_height' 'calc_height);
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
static bool select_tree_callback(int reason, typeless info=null)
{
   typeless callback=SELECT_TREE_CALLBACK();
   if (info==null) info=ctl_tree._TreeCurIndex();
   if (callback!=null) {
      _str result=(*callback)(reason,SELECT_TREE_USERDATA(),info);
      if (result==null) return(true);
      if (result!='') {
         (*callback)(SL_ONCLOSE,SELECT_TREE_USERDATA(),result);
         p_active_form._delete_window(result);
         return(true);
      }
   } else {
      if (reason == SL_ONDELKEY) {
         ctl_tree._TreeGetSelectionIndices(auto indices);
         if (indices._length() <= 0) {
            indices[0] = ctl_tree._TreeCurIndex();
         }
         foreach (info in indices) {
            ctl_tree._TreeDelete(info);
         }
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
   typeless callback=SELECT_TREE_CALLBACK();
   if (info==null) info=ctl_tree._TreeCurIndex();
   if (callback!=null) {
      (*callback)(SL_ONCLOSE,SELECT_TREE_USERDATA(),info);
   }
}

/**
 * Enter pressed on combo box, call ONDEFAULT callback
 * and maybe pass event along to OK button.
 */
void ctl_search.ENTER()
{
   ctl_ok.call_event(ctl_ok,LBUTTON_UP);
}

/**
 * Change prefix / substring matching option and refilter items.
 */
void ctl_prefix.lbutton_up()
{
   int flags = SELECT_TREE_FLAGS();
   if (p_value) {
      flags |= SL_SELECTPREFIXMATCH;
   } else {
      flags &= ~SL_SELECTPREFIXMATCH;
   }
   SELECT_TREE_FLAGS(flags);
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
   select_tree_flags := SELECT_TREE_FLAGS();
   if (select_tree_flags & SL_NOISEARCH) {
      return;
   }

   // get the search string, and re-insert items using creation callback
   search_string := p_text;
   if (ctl_tree.select_tree_callback(SL_ONINIT,search_string)) {
      return;
   }

   // if no search string, unhide all items in the tree
   if (search_string=='') {
      ctl_tree._TreeSetAllFlags(0,TREENODE_HIDDEN);
      ctl_tree._TreeTop();
      return;
   }

   wid := p_window_id;
   p_window_id=ctl_tree;
   typeless sc,nb,cb;
   filter_items := (select_tree_flags & SL_COMBO)? true:false;
   prefix_pos   := (select_tree_flags & SL_SELECTPREFIXMATCH)? 1:MAXINT;
   case_opt     := (select_tree_flags & SL_MATCHCASE)? '':'i';
   index := ctl_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   first_one := true;
   if (filter_items) {
      _TreeDeselectAll();
   }
   time1 := time2 := 0;
   while (index > 0) {
      caption := _TreeGetCaption(index);
      p := pos(search_string,caption,1,case_opt);
      if (p > 0 && p <= prefix_pos) {
         if (filter_items) {

            int flags;
            _TreeGetInfo(index,sc,nb,cb,flags);
            select := false;
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
 * Catch cursor-up and cursor-down. 
 */
void ctl_search.up,C_I()
{
   ctl_tree.call_event(ctl_tree,UP);
}
void ctl_search.down,C_K()
{
   ctl_tree.call_event(ctl_tree,DOWN);
}
void ctl_search.pgup,C_P()
{
   ctl_tree.call_event(ctl_tree,PGUP);
}
void ctl_search.pgdn,C_N()
{
   ctl_tree.call_event(ctl_tree,PGDN);
}

/**
 * Handle tree events, treat ENTER like OK button.
 */
void ctl_tree.on_change(int reason,int index, int col=-1)
{
   if (reason==CHANGE_SELECTED) {
      ctl_tree.select_tree_callback(SL_ONSELECT,index);
   } else if (reason==CHANGE_BUTTON_PRESS) {
      ctl_tree.select_tree_callback(ST_BUTTON_PRESS,col);
   } else if (reason==CHANGE_LEAF_ENTER) {
      ctl_ok.call_event(ctl_ok,LBUTTON_UP);
   }
}

/**
 * Handle tree events, treat double click like default
 */
void ctl_tree.lbutton_double_click()
{
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
   if (SELECT_TREE_FLAGS()&SL_CHECKLIST) {
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

void ctl_additem.lbutton_up()
{
   // collect tree column names
   _str col_names[];
   n := ctl_tree._TreeGetNumColButtons();
   for (i:=0; i<n; i++) {
      ctl_tree._TreeGetColButtonInfo(i, auto bw, auto bf, auto bs, col_names[i]);
   }

   // prompt for result
   result := 0;
   switch (n) {
   case 0:
      result = textBoxDialog("Add Item", 0, 3000, p_active_form.p_help, "", "", "New item");
      break;
   case 1:
      result = textBoxDialog("Add Item", 0, 3000, p_active_form.p_help, "", "", col_names[0]);
      break;
   case 2:
      result = textBoxDialog("Add Item", 0, 3000, p_active_form.p_help, "", "", col_names[0], col_names[1]);
      break;
   case 3:
      result = textBoxDialog("Add Item", 0, 3000, p_active_form.p_help, "", "", col_names[0], col_names[1], col_names[2]);
      break;
   case 4:
      result = textBoxDialog("Add Item", 0, 3000, p_active_form.p_help, "", "", col_names[0], col_names[1], col_names[2], col_names[3]);
      break;
   case 5:
      result = textBoxDialog("Add Item", 0, 3000, p_active_form.p_help, "", "", col_names[0], col_names[1], col_names[2], col_names[3], col_names[4]);
      break;
   case 6:
      result = textBoxDialog("Add Item", 0, 3000, p_active_form.p_help, "", "", col_names[0], col_names[1], col_names[2], col_names[3], col_names[4], col_names[5]);
      break;
   case 7:
      result = textBoxDialog("Add Item", 0, 3000, p_active_form.p_help, "", "", col_names[0], col_names[1], col_names[2], col_names[3], col_names[4], col_names[5], col_names[6]);
      break;
   case 8:
      result = textBoxDialog("Add Item", 0, 3000, p_active_form.p_help, "", "", col_names[0], col_names[1], col_names[2], col_names[3], col_names[4], col_names[5], col_names[6], col_names[7]);
      break;
   }
   if (result == COMMAND_CANCELLED_RC) {
      return;
   }

   new_item := "";
   switch (n) {
   case 8:
      new_item = "\t" :+ _param8 :+ new_item;
      // drop through
   case 7:
      new_item = "\t" :+ _param7 :+ new_item;
      // drop through
   case 6:
      new_item = "\t" :+ _param6 :+ new_item;
      // drop through
   case 5:
      new_item = "\t" :+ _param5 :+ new_item;
      // drop through
   case 4:
      new_item = "\t" :+ _param4 :+ new_item;
      // drop through
   case 3:
      new_item = "\t" :+ _param3 :+ new_item;
      // drop through
   case 2:
      new_item = "\t" :+ _param2 :+ new_item;
      // drop through
   case 1:
      new_item = _param1 :+ new_item;
      break;
   default:
      new_item = _param1;
   }


   ctl_tree._TreeAddItem(TREE_ROOT_INDEX, new_item, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
   ctl_tree._TreeSizeColumnToContents(-1);
}

/**
 * Find the next selected item.  If we are in checklist mode, this is the next
 * item with that is checked.  Otherwise, it is the next item
 * returned but _TreeGetNextSelectedIndex(x).
 */
static int SeltreeFindSelected(int ff,int &info)
{
   if (SELECT_TREE_FLAGS()&SL_CHECKLIST) {
      static int tree_search_index;
      if (ff) {
         tree_search_index=TREE_ROOT_INDEX;
      }
      usingPics := _GetDialogInfoHt('usingPics');
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
   select_tree_flags := SELECT_TREE_FLAGS();
   if (select_tree_flags&SL_DEFAULTCALLBACK && ctl_tree.select_tree_callback(SL_ONDEFAULT)) {
      return;
   }
   if ((select_tree_flags & SL_COMBO) && !(select_tree_flags & SL_NORETRIEVEPREV)) {
      _append_retrieve(ctl_search,ctl_search.p_text,p_active_form.p_name:+_PUSER_SELECT_TREE_RETRIEVE()"."ctl_search.p_name);
      _append_retrieve(ctl_prefix,ctl_prefix.p_value,p_active_form.p_name:+_PUSER_SELECT_TREE_RETRIEVE()"."ctl_prefix.p_name);
   }

   // save the sorting info
   if (ctl_tree._TreeGetNumColButtons() > 0) {
      ctl_tree._TreeAppendColButtonSorting(true, _PUSER_SELECT_TREE_RETRIEVE());
   }

   // gather the column widths so we know if the users changed them
   if (select_tree_flags & SL_COLWIDTH) {
      n := ctl_tree._TreeGetNumColButtons();
      if (n > 0) {
         column_widths := "";
         for (i := 0; i < n; i++) {
            ctl_tree._TreeGetColButtonInfo(i, auto width);
            column_widths :+= width;
            column_widths :+= ' ';
         }
         if (column_widths != SELECT_TREE_COLUMN_WIDTHs()) {
            ctl_tree._TreeAppendColButtonWidths(true, _PUSER_SELECT_TREE_RETRIEVE());
         }
      }
   }

   _str result=null;
   index := 0;
   checklist   := (select_tree_flags & SL_CHECKLIST)!=0;
   gettree     := (select_tree_flags & SL_GET_TREEITEMS)!=0;
   getrawitems := (select_tree_flags & SL_GET_ITEMS_RAW)!=0;
   if (ctl_tree.p_multi_select==MS_NONE && !checklist && !gettree) {
      // single selection
      index = ctl_tree._TreeCurIndex();
      if (index <= 0) {
         if (select_tree_flags & SL_MUSTEXIST) {
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

   // multiple items selected
   treeSelectionInfo := 0;
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
         if (select_tree_flags & SL_MUSTEXIST) {
            _message_box("Please select an item");
            return;
         }
         select_tree_close_callback('');
         p_active_form._delete_window('');
         return;
      }
   }
   // use first selected item to determine if we return keys or captions
   use_keys := true;
   result=ctl_tree._TreeGetUserInfo(index);
   if (result==null || result=='') {
      result=ctl_tree._TreeGetCaption(index);
      if (getrawitems) {
         result=stranslate(result, " ", "\n");
      } else {
         result=_maybe_quote_filename(result);
      }
      if (!getrawitems) {
      }
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
         rowtext := ctl_tree._TreeGetCaption(index);
         if (getrawitems) {
            result :+= stranslate(rowtext, " ", "\n");
         } else {
            result :+= _maybe_quote_filename(rowtext);
         }
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
   wid := p_window_id;
   p_window_id=ctl_tree;
   if (SELECT_TREE_FLAGS()&SL_CHECKLIST) {
      index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
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
   wid := p_window_id;
   p_window_id=ctl_tree;
   if (SELECT_TREE_FLAGS()&SL_CHECKLIST) {
      index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
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
                      int (&picture_array)[]=null,
                      int (&overlay_array)[]=null,
                      bool (&select_array)[]=null,
                      typeless callback=null,
                      typeless user_data=null,
                      _str caption=null, int flags=0,
                      _str col_names=null, 
                      _str col_flags=null,
                      _str help_item=null, 
                      _str retrieve_name=null,
                      _str message_text=null)
{
   // did they give us a tree caption
   if (caption!=null) {
      p_active_form.p_caption=caption;
   }

   // save setup flags
   SELECT_TREE_FLAGS(flags);
   SELECT_TREE_CALLBACK(callback);
   SELECT_TREE_USERDATA(user_data);

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
   enable_combo := (flags & SL_COMBO)? true:false;
   ctl_search.p_visible=enable_combo;
   ctl_search.p_enabled=enable_combo;
   ctl_prefix.p_visible=enable_combo;
   ctl_prefix.p_enabled=enable_combo;

   //   SL_INVERT, SL_SELECTALL
   ctl_invert.p_visible=ctl_invert.p_enabled=(flags & SL_INVERT)? true:false;
   ctl_selectall.p_visible=ctl_selectall.p_enabled=(flags & SL_SELECTALL)? true:false;
   ctl_delete.p_visible=ctl_delete.p_enabled=(flags & SL_DELETEBUTTON)? true:false;
   ctl_additem.p_visible=ctl_additem.p_enabled=(flags & SL_ADDBUTTON)? true:false;

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

   checklist := (SELECT_TREE_FLAGS() & SL_CHECKLIST)!=0;
   usingPics := (picture_array != null);
   ctl_tree._SetDialogInfoHt('usingPics', usingPics);

   usingOverlays := ((flags & SL_USE_OVERLAYS) && overlay_array != null);
   treeOverlayFlag := usingOverlays? TREE_OVERLAY_BITMAP1:0;

   // restore form position and size?
   if (retrieve_name != null && retrieve_name != "" && (flags & SL_RESTORE_XYWH)!=0) {
      do_xy     := (flags & (SL_XY_WIDTH_HEIGHT|SL_RESTORE_XY    )) != 0;
      do_width  := (flags & (SL_XY_WIDTH_HEIGHT|SL_RESTORE_WIDTH )) != 0;
      do_height := (flags & (SL_XY_WIDTH_HEIGHT|SL_RESTORE_HEIGHT)) != 0;
      p_active_form._restore_form_xy(!do_xy,
                                     p_active_form.p_name:+retrieve_name,
                                     false, 0, do_width, do_height);
      ctl_tree.p_width = p_active_form.p_width - 2*ctl_tree.p_x;
   }
   orig_height := p_active_form.p_height;
   orig_width  := p_active_form.p_width;

   wid := p_window_id;
   p_window_id=ctl_tree;
   currentIndex := -1;
   // insert items into the tree using parallel arrays
   int i,n=cap_array._length();
   for (i=0; i<n; ++i) {
      picture_index := 0;
      overlay_index := 0;
      more_flags := 0;
      checkboxValue := 0;
      selected := false;
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
         picture_index = 0;
         if (picture_array!=null && i < picture_array._length()) {
            picture_index = picture_array[i];
         }
         overlay_index = 0;
         if ( overlay_array!=null && i < overlay_array._length()) {
            overlay_index = overlay_array[i];
         }
      }
      index := _TreeAddItem(TREE_ROOT_INDEX, 
                            cap_array[i],
                            TREE_ADD_AS_CHILD|treeOverlayFlag, 
                            overlay_index,
                            picture_index, 
                            TREE_NODE_LEAF,
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
   tw := 0;
   haveSortColumn := false;
   if (col_flags==null) col_flags="";
   if (col_names!=null) {
      _str cnames[];
      int cflags[];
      int cwidths[];

      // restore column widths from last invocation
      // we will still try to dynamically resize them.
      ctl_tree._TreeRetrieveColButtonWidths(true, _PUSER_SELECT_TREE_RETRIEVE());

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
         restored_width := ctl_tree._text_width(coln)+300;
         cnames[n] = coln;
         cflags[n] = (int)colf;
         cwidths[n] = restored_width;

         if ( n < ctl_tree._TreeGetNumColButtons() ) {
            ctl_tree._TreeGetColButtonInfo(n, restored_width, auto bf, auto bs, auto bc);
         } else {
            ctl_tree._TreeSetColButtonInfo(n, cwidths[n], 0, 0, cnames[n]);
         }
         if (cwidths[n] < restored_width) {
            cwidths[n] = restored_width;
         }
         ++n;
      }

      if (n > 0) {
         if (flags & SL_COLWIDTH) {
            ctl_tree._TreeSizeColumnToContents(-1);
            for (i = 0; i < n; i++) {
               header_width := ctl_tree._text_width(cnames[i])+300;
               ctl_tree._TreeGetColButtonInfo(i, auto autosize_width, auto bf, auto bs, auto bc);
               if (autosize_width < header_width) autosize_width = header_width;
               cwidths[i] = autosize_width+60;
            }
         }
         for (i = 0; i < n; i++) {
            ctl_tree._TreeSetColButtonInfo(i,cwidths[i],cflags[i],0,cnames[i]);
            tw += cwidths[i];

            // if this is the first column with the sort flag, then we sort with it
            if (!haveSortColumn && (cflags[i] & TREE_BUTTON_SORT_DESCENDING)) {
               ctl_tree._TreeSortCol(i, 'd');
               haveSortColumn = true;
            }
            if (!haveSortColumn && (cflags[i] & TREE_BUTTON_SORT)) {
               ctl_tree._TreeSortCol(i);
               haveSortColumn = true;
            }
         }
      }
   }

   // maybe retrieve tree column sorting info
   if (haveSortColumn) {
      ctl_tree._TreeRetrieveColButtonSorting(true, _PUSER_SELECT_TREE_RETRIEVE());
   }

   // position on first item in list
   if (!(flags & SL_NOTOP)) {
      ctl_tree._TreeTop();
   }

   // retrieve previous combo box values
   if (retrieve_name==null) retrieve_name='ctl_search';
   _PUSER_SELECT_TREE_RETRIEVE(retrieve_name);
   if (!(flags & SL_NORETRIEVEPREV)) {
      ctl_search._retrieve_list(p_active_form.p_name:+retrieve_name"."ctl_search.p_name);
   }
   if (!(flags & SL_SELECTPREFIXMATCH)) {
      ctl_prefix._retrieve_value(p_active_form.p_name:+retrieve_name"."ctl_prefix.p_name);
   }

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
      //tw := ctl_tree._TreeAdjustColumnWidths(-1,&numWrappedRows);
      scroll_width := _dx2lx(SM_TWIP, ctl_tree._TreeGetVScrollBarWidth());
      border_width := _dx2lx(SM_TWIP, ctl_tree._TreeGetBorderWidth());
      left_width := ctl_tree._TreeGetLeftPadding();
      p_active_form.p_width = _lx2lx(ctl_tree.p_xyscale_mode,p_active_form.p_xyscale_mode,ctl_tree.p_x*2+left_width+tw+scroll_width);
      _SetDialogInfoHt("addedWidth", p_active_form.p_width - orig_width);

      // shrink height of form to match number of lines
      lineHeight := ctl_tree.p_line_height + _twips_per_pixel_y();
      numLines   := ctl_tree._TreeGetNumChildren(TREE_ROOT_INDEX, 'T');
      screen_width := _dx2lx(SM_TWIP, _screen_width());
      if (p_active_form.p_width >= screen_width) {
         numLines += numWrappedRows;
      }
      calc_height := (numLines+2)*lineHeight;
      if (calc_height < 1500) calc_height=1500;
      if (ctl_tree.p_height > calc_height) {
         p_active_form.p_height -= (ctl_tree.p_height - calc_height); 
         _SetDialogInfoHt("addedHeight",ctl_tree.p_height - calc_height);
      }
   }

   // save the column widths so we know if the users changes them
   n = ctl_tree._TreeGetNumColButtons();
   column_widths := "";
   for (i = 0; i < n; i++) {
      ctl_tree._TreeGetColButtonInfo(i, auto width);
      column_widths :+= width;
      column_widths :+= ' ';
   }
   SELECT_TREE_COLUMN_WIDTHs(column_widths);

   // also save the form width and height, to detect if they have changed later
   SELECT_TREE_HEIGHT(orig_height ' 'p_active_form.p_height);
   SELECT_TREE_WIDTH(orig_width ' 'p_active_form.p_width);

   // set up help string (for F1)
   if (help_item != null) {
      p_active_form.p_help=help_item;
   }

   // set the message information
   if (message_text != null) {
      p_active_form.ctl_message.p_caption = message_text;
   }

   // add keybindings for cursor up and down to this form
   int keys[];
   copy_key_bindings_to_form("cursor-up",    ctl_tree,   UP,   keys);
   copy_key_bindings_to_form("cursor-down",  ctl_tree,   DOWN, keys);
   copy_key_bindings_to_form("page-up",      ctl_tree,   PGUP, keys);
   copy_key_bindings_to_form("page-down",    ctl_tree,   PGDN, keys);
   copy_key_bindings_to_form("cursor-up",    ctl_search, UP,   keys);
   copy_key_bindings_to_form("cursor-down",  ctl_search, DOWN, keys);
   copy_key_bindings_to_form("page-up",      ctl_search, PGUP, keys);
   copy_key_bindings_to_form("page-down",    ctl_search, PGDN, keys);

   // give focus to the combo box
   ctl_search._set_focus();
}

void ctl_ok.on_destroy()
{
   // save form position and size?
   if (SELECT_TREE_FLAGS() & SL_RESTORE_XYWH) {
      parse SELECT_TREE_HEIGHT() with auto restore_height auto calc_height;
      parse SELECT_TREE_WIDTH()  with auto restore_width  auto calc_width;

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

      if (false && isuinteger(restore_width)) {
         // this is the amount of space we trimmed off the dialog in on create
         // making room for other stuff.
         addedWidth := _GetDialogInfoHt("addedWidth");
         if ( !isinteger(addedWidth) ) addedWidth = 0;
         if ( !isapprox(p_active_form.p_width, (int)restore_width, 100)) {
            p_active_form.p_width = (int)restore_width;
         } else {
            // We always have to add this on
            p_active_form.p_width += addedWidth;
         }
      }

      p_active_form._save_form_xy(p_active_form.p_name:+_PUSER_SELECT_TREE_RETRIEVE());
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
