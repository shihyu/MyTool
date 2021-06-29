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
#import "listbox.e"
#import "main.e"
#import "menu.e"
#import "menuedit.e"
#import "options.e"
#import "slickc.e"
#import "stdprocs.e"
#import "util.e"
#include "treeview.sh"
#import "tbprops.e"
#require "sc/controls/customizations/MenuCustomizationHandler.e"
#endregion

using namespace sc.controls.customizations;

_command void reset_menu(_str menuNameArg = '') name_info(',')
{
   menuName := prompt(menuNameArg);

   // see if we have previously stored an original version of this menu
   installVerIndex := find_index(menuName :+ SE_ORIG_MENU_SUFFIX, oi2type(OI_MENU));
   if (installVerIndex > 0) {
   
      // find the current index and delete that one
      curVerIndex := find_index(menuName, oi2type(OI_MENU));
      if (curVerIndex) delete_name(curVerIndex);
     
      // now copy the original one over to the menu name
      curVerIndex = insert_name(menuName, oi2type(OI_MENU), '', installVerIndex);
      delete_name(installVerIndex);

      // remove changes from the xml file
      MenuCustomizationHandler mch;
      mch.removeMenuMods(menuName);

      // did we edit the mdi menu?  cause we might need to update it...
      if (name_eq(menuName, translate(_cur_mdi_menu, '_', '-'))) {
         _menu_mdi_update();
      }
   }

   message(menuName' reset back to original configuration.');
}

defeventtab _menu_editor_form;

static _str MENU_OPTIONS(...) {
   if (arg()) _menu_name.p_user=arg(1);
   return _menu_name.p_user;
}
static _str EDITING_MDI(...) {
   if (arg()) _cancel.p_user=arg(1);
   return _cancel.p_user;
}
static int TREE_SELECTED_INDEX(...) {
   if (arg()) _item_help.p_user=arg(1);
   return _item_help.p_user;
}

void _item_command.on_change(int reason)
{
   if (p_text=="") {
      _auto_enable.p_enabled=false;
      return;
   }
   cmdname := "";
   parse p_text with cmdname .;
   enabled:=_tbprop_get_auto_enabled_value(cmdname);
   if (enabled!=_auto_enable.p_enabled) {
      _auto_enable.p_enabled=enabled;
   }
}
_item_help.' '()
{
   maybe_complete();
}
_item_help.'?'()
{
   if (def_qmark_complete) maybe_list_matches();
}
/** 
 * Displays the <b>Menu Editor dialog box</b> and edits the menu 
 * specified.  If the -new option is given, a new menu resource called 
 * <i>menu_name</i> is created if one does not already exist.  If no arguments 
 * are given, the SlickEdit menu bar is edited.
 * 
 * @categories Forms
 * 
 */
_ok.on_create(_str menu_name="")
{
   name := "";
   //list1.p_picture=_pic_lbminus;
   //list1.p_pic_point_scale=8;
   new_option := "";
   new_menu_name := "";
   parse menu_name with new_option new_menu_name ;
   if (upcase(new_option)=='-NEW') {
      menu_name=new_menu_name;
      new_option=1;
   } else {
      new_option=0;
   }

   if (!new_option && menu_name=='') {
      menu_name=def_mdi_menu;
      if (menu_name=='') {
         _message_box("Don't know what menu to edit");
         p_active_form._delete_window();
         return('');
      }
   }

   // see if we can find this menu
   menu_name=translate(menu_name,'_','-');
   tindex := 0;
   if (menu_name!='') {
      tindex=find_index(menu_name,oi2type(OI_MENU));
   }

   if (!tindex) {
      // this is a new one!
      if (!new_option) {
         // we are not allowing the user to make a new one
         _message_box(nls("Menu '%s' not found",menu_name));
         p_active_form._delete_window();
         return('');
      }

      if (menu_name=='') {
         name=_menu_match('',true);
         typeless largest=0;
         for (;;) {
            if (name=='') break;
            prefix := substr(name,1,4);
            number := substr(name,5);
            if (name_eq(prefix,'menu') && isinteger(number) && number>largest) {
               largest=number;
            }
            name=_menu_match('',false);
         }
         menu_name='menu':+(largest+1);
      }

      if (!isid_valid(menu_name)) {
         _message_box(nls("Menu name '%s' is an invalid identifier",menu_name));
         p_active_form._delete_window();
         return('');
      }

      // okay, this is a new menu
      tindex=insert_name(menu_name,oi2type(OI_MENU),FF_MODIFIED);
      if (!tindex) {
         _message_box(nls("Unable to create menu '%s'",menu_name)"\n\n"get_message(tindex));
         p_active_form._delete_window();
         return('');
      }
   } else {
      // Did not create a new menu
      new_option=0;
   }

   int orig_tindex=tindex;
   // IF we are editing an already existing menu
   if (!new_option) {
      //Make a copy and use an invalid menu name

      // Delete the temp name if it already exists.
      int index=find_index('*',oi2type(OI_MENU));
      if (index) delete_name(index);

      // copy the original menu to the temp menu
      mou_hour_glass(true);
      tindex=insert_name('*',oi2type(OI_MENU),'',tindex);
      rc_status:=rc;
      mou_hour_glass(false);

      // IF something bad happened
      if (!tindex) {
         _message_box(nls("Unable to create temp menu")"\n\n"get_message(rc_status));
         p_active_form._delete_window();
         return('');
      }

   }

   // set our info so we can access it later
   MENU_OPTIONS(new_option' 'menu_name' 'orig_tindex' 'tindex' .');
   EDITING_MDI(name_eq(menu_name,translate(_cur_mdi_menu,'_','-')));
   list1._TreeSetUserInfo(0,tindex);

   // If this menu is empty, add a sibling
   if (!tindex.p_child) {
      _menu_insert(tindex,0,0,
                   '',
                   '',
                   '',
                   '',
                   '');
   }
   list1._fill_tree_node(0,tindex);
   _item_command._lbtop();
   _item_command._lbsort('i');
   _menu_name.p_text=menu_name;
   list1.call_event(CHANGE_SELECTED,list1._TreeGetFirstChildIndex(0),list1,ON_CHANGE,'');
   update_up_down_enable();
}

void _ok.on_destroy()
{
   // IF OK button already processed destroy
   if (MENU_OPTIONS()=='') return;

   // parse out the temp index
   new_option := "";
   menu_name := "";
   typeless orig_tindex="";
   typeless tindex="";
   parse MENU_OPTIONS() with new_option menu_name orig_tindex tindex . ;

   //Delete the temporary editted menu
   delete_name(tindex);
}

void _ok.lbutton_up()
{
   index := 0;
   new_option := "";
   menu_name := "";
   typeless orig_tindex="";
   typeless tindex="";
   parse MENU_OPTIONS() with new_option menu_name orig_tindex tindex . ;
   new_name := strip(_menu_name.p_text);
   if (!name_eq(new_name,menu_name)) {
      if (!isid_valid(new_name)) {
         _message_box(nls("Menu name '%s' is an invalid identifier",new_name));
         _menu_name._set_sel(1,length(new_name)+1);
         _menu_name._set_focus();
         return;
      }
      menu_name=new_name;
      if (new_option) {
         index=find_index(new_name,OBJECT_TYPE);
         if (index) {
            _message_box(nls("This name has already been used.  Choose a different name"));
            _menu_name._set_sel(1,length(new_name)+1);
            _menu_name._set_focus();
            return;
         }
         replace_name(tindex,new_name);
      }
   }
   mou_hour_glass(true);
   maybe_commit_changes();
   // let's see if stuff changed...

   menuChanged := false;
   if (!new_option) {
      // see if we have previously stored an original version of this menu
      installVerIndex := find_index(menu_name :+ SE_ORIG_MENU_SUFFIX, oi2type(OI_MENU));

      if (installVerIndex == 0) installVerIndex = orig_tindex;

      MenuCustomizationHandler mch;
      if (mch.saveMenuChanges(menu_name, installVerIndex, tindex)) {
         // save the old one
         insert_name(menu_name :+ SE_ORIG_MENU_SUFFIX, oi2type(OI_MENU), '', installVerIndex);
         menuChanged = true;
      } else if (installVerIndex != orig_tindex) delete_name(installVerIndex);
   }

   index=tindex;
   if (!new_option) {
      index=orig_tindex;
      // Transfer temp menu to original menu
      typeless flags=name_info(orig_tindex);
      if (isinteger(flags)) {
         flags |= FF_MODIFIED;
      }
      replace_name(orig_tindex,menu_name,flags,tindex);

      // Delete temp menu
      delete_name(tindex);
   }
   MENU_OPTIONS('');
   if (EDITING_MDI() && menuChanged) {
      _menu_mdi_update();
   }
   mou_hour_glass(false);
   if (index) {
      _set_object_modify(index);
   }
   p_active_form._delete_window(0);

}

static const MENU_EDITOR_MIN_WIDTH=       6200;
static const MENU_EDITOR_MIN_HEIGHT=      5800;

void _menu_editor_form.on_resize()
{
   // make sure we keep to a minimum size
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(MENU_EDITOR_MIN_WIDTH, MENU_EDITOR_MIN_HEIGHT);
   }

   // available width and height
   width := p_width;
   height := p_height;

   padding := list1.p_x;

   // what's the difference between this and our baseline?
   widthDiff := width - (_insert_child.p_x_extent + padding);
   heightDiff := height - (list1.p_y_extent + padding);

   // all the extra space goes to the list control
   if (widthDiff) {
      list1.p_width += widthDiff;

      // widen the fields
      _menu_name.p_width += widthDiff;
      _item_caption.p_width = _item_help.p_width = _menu_name.p_width;
      _item_message.p_width += widthDiff;
      _item_command.p_width += widthDiff;

      // move the buttons
      _alias.p_x += widthDiff;
      _up.p_x += widthDiff;
      _down.p_x = _next.p_x = _insert_child.p_x=_insert.p_x = _delete.p_x = _ok.p_x = _cancel.p_x = _help.p_x = _up.p_x;
   }

   if (heightDiff) {
      list1.p_height += heightDiff;
   }

}

void _item_command.on_drop_down(int reason)
{
   if (p_user=='') {
      _insert_name_list(COMMAND_TYPE);
      _lbtop();
      _lbsort('i');
      p_user=1;
   }
}
void _alias.lbutton_up()
{
   maybe_commit_changes();
   // Get tindex of child
   int child=TREE_SELECTED_INDEX();
   childInfo := list1._TreeGetUserInfo(child);
   before := after := "";
   parse childInfo.p_command with before "\t" after ;
   typeless result=show('-modal _menualias_form',after);
   if (result=='') {
      return;
   }
   if (_param1=='') {
      childInfo.p_command=before;
   } else {
      childInfo.p_command=before"\t"_param1;
   }

}
void _auto_enable.lbutton_up()
{
   maybe_commit_changes();
   // Get tindex of child
   int child=TREE_SELECTED_INDEX();
   cmdname := "";
   parse _item_command.p_text with cmdname .;
   show('-modal _autoenable_form',cmdname);
}
int _get_sibling_position(int index,int &first_child) {
   first_child= -1;
   count := 0;
   for (;;++count) {
      index=list1._TreeGetPrevSiblingIndex(index);
      if (index<0) {
         break;
      }
      first_child=index;
   }
   return count;
}
void _down.lbutton_up()
{
   if (maybe_commit_changes()) return;
   //return;
   int index=TREE_SELECTED_INDEX();
   int tindex= list1._TreeGetUserInfo(list1._TreeGetParentIndex(TREE_SELECTED_INDEX()));
   //int next=_TreeGetNextSiblingIndex(index);
   //int prev=_TreeGetPrevSiblingIndex(index);
   int first_index;
   int position=_get_sibling_position(index,first_index);
   caption := list1._TreeGetCaption(index);
   add_parent := list1._TreeGetNextSiblingIndex(index);
   int add_flags;
   int move_to_position;
   if (add_parent<0) {
      // Move to first sibling
      move_to_position=0;
      add_parent=list1._TreeGetFirstChildIndex(list1._TreeGetParentIndex(TREE_SELECTED_INDEX()));
      add_flags=TREE_ADD_BEFORE;
   } else {
      move_to_position=position+1;
      add_flags=TREE_ADD_AFTER;
   }
   _menu_move(tindex,position,tindex,move_to_position);

   int child=tindex.p_child;
   int i;
   for (i=0;;++i) {
      if (i>=move_to_position) break;
      child=child.p_next;
   }

   int tree_index=TREE_SELECTED_INDEX();
   TREE_SELECTED_INDEX('');
   list1._TreeSetUserInfo(tree_index,'');
   list1._TreeDelete(tree_index);

   if (child.p_object==OI_MENU) {
      TREE_SELECTED_INDEX(list1._TreeAddItem(add_parent,caption,add_flags,0,0,TREE_NODE_COLLAPSED,0,child));
   } else {
      TREE_SELECTED_INDEX(list1._TreeAddItem(add_parent,caption,add_flags,0,0,-1,0,child));
   }
   list1._TreeSetCurIndex(TREE_SELECTED_INDEX());
   update_item_props(list1._TreeGetUserInfo(TREE_SELECTED_INDEX()));
}
void _up.lbutton_up()
{
   if (maybe_commit_changes()) return;
   //return;
   int index=TREE_SELECTED_INDEX();
   int tindex= list1._TreeGetUserInfo(list1._TreeGetParentIndex(TREE_SELECTED_INDEX()));
   //int next=_TreeGetNextSiblingIndex(index);
   //int prev=_TreeGetPrevSiblingIndex(index);
   int first_index;
   int position=_get_sibling_position(index,first_index);
   

   caption := list1._TreeGetCaption(index);
   add_parent := list1._TreeGetPrevSiblingIndex(index);
   int add_flags;
   int move_to_position;
   if (add_parent<0) {
      // move to last sibling position
      move_to_position=list1._TreeGetNumChildren(list1._TreeGetParentIndex(TREE_SELECTED_INDEX()));
      add_parent=list1._TreeGetParentIndex(TREE_SELECTED_INDEX());
      add_flags=TREE_ADD_AS_CHILD;
   } else {
      move_to_position=position-1;
      add_flags=TREE_ADD_BEFORE;
   }
   _menu_move(tindex,position,tindex,move_to_position);
   int child=tindex.p_child;
   int i;
   for (i=0;;++i) {
      if (i>=move_to_position) break;
      child=child.p_next;
   }

   int tree_index=TREE_SELECTED_INDEX();
   TREE_SELECTED_INDEX('');
   list1._TreeSetUserInfo(tree_index,'');
   //say('h2 tree_index='tree_index);
   list1._TreeDelete(tree_index);
   //say('h3');

   if (child.p_object==OI_MENU) {
      TREE_SELECTED_INDEX(list1._TreeAddItem(add_parent,caption,add_flags,0,0,TREE_NODE_COLLAPSED,0,child));
   } else {
      TREE_SELECTED_INDEX(list1._TreeAddItem(add_parent,caption,add_flags,0,0,-1,0,child));
   }
   list1._TreeSetCurIndex(TREE_SELECTED_INDEX());
   update_item_props(list1._TreeGetUserInfo(TREE_SELECTED_INDEX()));
}
void _item_popup.lbutton_up()
{
   if(!p_enabled) return;
   maybe_commit_changes();
}
void _item_caption.on_change()
{
   if (TREE_SELECTED_INDEX()=='') return;
   list1._TreeSetCaption(TREE_SELECTED_INDEX(),p_text);
}

static void _fill_tree_node(int tree_parent,int menu_parent)
{
   int child=menu_parent.p_child;
   if (child) {
      int first_child=child;
      int add_parent=tree_parent;
      int add_flags=TREE_ADD_AS_CHILD;
      for (;;) {
         caption := child.p_caption;
         parse caption with caption "\t" ;
         int index;
         if (child.p_object==OI_MENU) {
            index=_TreeAddItem(add_parent,caption,add_flags,0,0,TREE_NODE_COLLAPSED,0,child);
         } else {
            index=_TreeAddItem(add_parent,caption,add_flags,0,0,-1,0,child);
         }
         if (child.p_next==first_child) break;
         child=child.p_next;
         add_parent=index;
         add_flags=TREE_ADD_AFTER;
      }
   }
   
   //list1.call_event(CHANGE_SELECTED,list1,ON_CHANGE,'');
   
}
static void update_up_down_enable() {
   int index=TREE_SELECTED_INDEX();
   // enable up/down if at least two siblings
   next := list1._TreeGetNextSiblingIndex(index);
   prev := list1._TreeGetPrevSiblingIndex(index);
   if (next>=0 || prev>=0) {
      _up.p_enabled=_down.p_enabled=true;
   } else {
      _up.p_enabled=_down.p_enabled=false;
   }
}
void list1.on_change(int reason,int index)
{
   if (reason==CHANGE_SELECTED) {
      //say('on_change index='index' old='TREE_SELECTED_INDEX());
      // IF select index did not change
      if (TREE_SELECTED_INDEX()==index) return;
      if( index<=0 || list1._TreeGetUserInfo(index)=='') return;
      if (TREE_SELECTED_INDEX()!='') {
          maybe_commit_changes();
      }
      //say('caption='_TreeGetCaption(index));
      TREE_SELECTED_INDEX(index);
      update_up_down_enable();
      int menu_index=list1._TreeGetUserInfo(index);
      //say('index='index' menu_index='menu_index);
      update_item_props(menu_index);
   } else if (reason==CHANGE_EXPANDED) {
      if(list1._TreeGetFirstChildIndex(index)<0) {
         //say('change expanded');
         _fill_tree_node(index,_TreeGetUserInfo(index));
      }
   }
}
/*
    Insert new sibling or child and select it
*/
static void insert_new_item(int add_parent,int add_flags,int tindex, int position)
{

   TREE_SELECTED_INDEX('');
   _item_caption.p_text='';
   if(_item_command.p_text:!=''){
      _item_command.p_text='';
   }
   _item_short_cut.p_text='';
   _item_help.p_text='';_item_message.p_text='';
   _item_popup.p_value=0;
   _item_short_cut.p_enabled=_item_scutlabel.p_enabled=true;
   _item_command.p_enabled=_alias.p_enabled=true;_item_cmdlabel.p_enabled=true;
   _item_popup.p_enabled=true;

   _menu_insert(tindex,position,0,
                '',
                '',
                '',
                '',
                '');
   int child=tindex.p_child;
   int i;
   for (i=0;;++i) {
      if (i>=position) break;
      child=child.p_next;
   }
   TREE_SELECTED_INDEX(list1._TreeAddItem(add_parent,'',add_flags,0,0,-1,0,child));
   list1._TreeSetCurIndex(TREE_SELECTED_INDEX());
   update_item_props(list1._TreeGetUserInfo(TREE_SELECTED_INDEX()));
}
static void update_item_props(int child)
{
   caption := child.p_caption;
   short_cut := "";
   parse caption with caption "\t" short_cut ;
   _item_caption.p_text=caption;
   if (child.p_object==OI_MENU) {
      if(_item_command.p_text:!=''){
         _item_command.p_text='';
      }
      _item_short_cut.p_enabled=_item_scutlabel.p_enabled=false;
      _item_command.p_enabled=_alias.p_enabled=false;_item_cmdlabel.p_enabled=false;
      _item_popup.p_value=1;
      _item_popup.p_enabled=false;
   } else {
      before := "";
      parse child.p_command with before "\t" ;
      if (_item_command.p_text:!=before) {
         _item_command.p_text=before;
      }
      _item_short_cut.p_enabled=_item_scutlabel.p_enabled=true;
      _item_command.p_enabled=_alias.p_enabled=true;_item_cmdlabel.p_enabled=true;
      _item_popup.p_value=0;
      _item_popup.p_enabled=true;
   }
   _item_short_cut.p_text=short_cut;
   _item_help.p_text=child.p_help;
   _item_message.p_text=child.p_message;

}
void _delete.lbutton_up()
{
   int tindex= list1._TreeGetUserInfo(list1._TreeGetParentIndex(TREE_SELECTED_INDEX()));
   int first_index;
   int position=_get_sibling_position(TREE_SELECTED_INDEX(),first_index);

   int next=list1._TreeGetNextSiblingIndex(TREE_SELECTED_INDEX());
   if (next<0) {
      next=list1._TreeGetPrevSiblingIndex(TREE_SELECTED_INDEX());
      if (next<0) {
         next=list1._TreeGetParentIndex(TREE_SELECTED_INDEX());
      }
   }
   _menu_delete(tindex,position);
   int tree_index=TREE_SELECTED_INDEX();
   TREE_SELECTED_INDEX('');
   list1._TreeSetUserInfo(tree_index,'');
   list1._TreeDelete(tree_index);
   if (next==0) {
      insert_new_item(0,TREE_ADD_AS_CHILD,tindex,0);
   } else {
      //update_item_props(list1._TreeGetUserInfo(next));
      TREE_SELECTED_INDEX(next);
      list1._TreeSetCurIndex(TREE_SELECTED_INDEX());
      update_item_props(list1._TreeGetUserInfo(TREE_SELECTED_INDEX()));
   }
   update_up_down_enable();
}
void _next.lbutton_up()
{
   if(maybe_commit_changes()) return;

   int tindex= list1._TreeGetUserInfo(list1._TreeGetParentIndex(TREE_SELECTED_INDEX()));
   int first_index;
   int position=_get_sibling_position(TREE_SELECTED_INDEX(),first_index);
   insert_new_item(TREE_SELECTED_INDEX(),TREE_ADD_AFTER,tindex,position+1);
   _item_caption._set_sel(1,length(_item_caption.p_text)+1);
   _item_caption._set_focus();
}
void _insert.lbutton_up()
{
   if(maybe_commit_changes()) return;

   int tindex= list1._TreeGetUserInfo(list1._TreeGetParentIndex(TREE_SELECTED_INDEX()));
   int first_index;
   int position=_get_sibling_position(TREE_SELECTED_INDEX(),first_index);
   insert_new_item(TREE_SELECTED_INDEX(),TREE_ADD_BEFORE,tindex,position);
   _item_caption._set_sel(1,length(_item_caption.p_text)+1);
   _item_caption._set_focus();
}
void _insert_child.lbutton_up()
{
   if (TREE_SELECTED_INDEX()=='') {
      return;
   }
   if (!_item_popup.p_value) _item_popup.p_value=1;
   if(maybe_commit_changes()) return;

   insert_new_item(TREE_SELECTED_INDEX(),TREE_ADD_AS_CHILD,
                   list1._TreeGetUserInfo(TREE_SELECTED_INDEX()),list1._TreeGetNumChildren(TREE_SELECTED_INDEX()));
   _item_caption._set_sel(1,length(_item_caption.p_text)+1);
   _item_caption._set_focus();
   update_up_down_enable();
}
static bool maybe_commit_changes()
{
   if (maybe_delete_blank_line()) {
      return true;
   }

   int tindex= list1._TreeGetUserInfo(list1._TreeGetParentIndex(TREE_SELECTED_INDEX()));
   int child=list1._TreeGetUserInfo(TREE_SELECTED_INDEX());
   caption := "";
   child_short_cut := "";
   parse child.p_caption with caption "\t" child_short_cut;
   short_cut := "";
   if (_item_short_cut.p_text!='') {
      short_cut="\t"_item_short_cut.p_text;
   }
   //messageNwait('pos='position' chd o='child.p_object' cap='child.p_caption)
   typeless junk="";
   if ((child.p_object==OI_MENU && !_item_popup.p_value) ||
       (child.p_object==OI_MENU_ITEM && _item_popup.p_value)
      ) {
      flags := 0;
      if (_item_popup.p_value) {
         flags=MF_SUBMENU;
      }
      int first_index;
      int position=_get_sibling_position(TREE_SELECTED_INDEX(),first_index);
      // This item is no longer a popup OR item was changed to popup
      _str categories=child.p_categories;
      _menu_delete(tindex,position);
      int add_parent=list1._TreeGetPrevSiblingIndex(TREE_SELECTED_INDEX());
      int add_flags=TREE_ADD_AFTER;
      if (add_parent<0) {
         add_parent=list1._TreeGetNextSiblingIndex(TREE_SELECTED_INDEX());
         add_flags=TREE_ADD_BEFORE;
         if (add_parent<0) {
            add_parent=list1._TreeGetParentIndex(TREE_SELECTED_INDEX());
            add_flags=TREE_ADD_AS_CHILD;
         }
      }
      caption=_item_caption.p_text;
      _menu_insert(tindex,position,flags,
                   caption:+short_cut,
                   (flags)?'':_item_command.p_text,
                   categories,
                   _item_help.p_text,
                   _item_message.p_text);
      int i;
      child=tindex.p_child;
      for (i=0;;++i) {
         if (i>=position) break;
         child=child.p_next;
      }
      int tree_index=TREE_SELECTED_INDEX();
      TREE_SELECTED_INDEX('');
      list1._TreeSetUserInfo(tree_index,'');
      list1._TreeDelete(tree_index);
      //list1._TreeSetInfo(TREE_SELECTED_INDEX(),(child.p_object==OI_MENU)?TREE_NODE_COLLAPSED:-1);
      if (child.p_object==OI_MENU) {
         TREE_SELECTED_INDEX(list1._TreeAddItem(add_parent,caption,add_flags,0,0,TREE_NODE_COLLAPSED,0,child));
      } else {
         TREE_SELECTED_INDEX(list1._TreeAddItem(add_parent,caption,add_flags,0,0,-1,0,child));
      }
      list1._TreeSetCurIndex(TREE_SELECTED_INDEX());
      update_item_props(list1._TreeGetUserInfo(TREE_SELECTED_INDEX()));
      return false;
   }
   if (caption!=_item_caption.p_text || child_short_cut!=_item_short_cut.p_text) {
      child.p_caption=_item_caption.p_text:+short_cut;
   }
   if (child.p_object==OI_MENU_ITEM) {
      if (child.p_command!=_item_command.p_text) {
         after := "";
         parse child.p_command with "\t" +0 after ;
         child.p_command=_item_command.p_text:+after;
      }
   }
   if (child.p_help!=_item_help.p_text) {
      child.p_help=_item_help.p_text;
   }
   if (child.p_message!=_item_message.p_text) {
      child.p_message=_item_message.p_text;
   }
   return false;
}
// IF last line has blank caption, delete it
static bool maybe_delete_blank_line()
{
   if (TREE_SELECTED_INDEX()=='') {
      return true;
   }
   int tindex= list1._TreeGetUserInfo(list1._TreeGetParentIndex(TREE_SELECTED_INDEX()));
   int index= list1._TreeGetUserInfo(TREE_SELECTED_INDEX());
   if (_item_caption.p_text=='') {
      int first_index;
      int position=_get_sibling_position(TREE_SELECTED_INDEX(),first_index);
      int tree_index=TREE_SELECTED_INDEX();
      TREE_SELECTED_INDEX('');
      _menu_delete(tindex,position);
      list1._TreeSetUserInfo(tree_index,'');
      list1._TreeDelete(tree_index);
      return true;
   }
#if 0
   if (TREE_SELECTED_INDEX()=='') {
      _item_command.p_text='';
      _item_short_cut.p_enabled=_item_scutlabel.p_enabled=false;
      _item_command.p_enabled=_alias.p_enabled=false;_item_cmdlabel.p_enabled=false;
      _item_popup.p_value=0;
      _item_popup.p_enabled=false;
      _item_short_cut.p_text='';
      _item_help.p_text='';
      _item_message.p_text='';
      return true;
   }
#endif
   return false;
}
static const AUTO_ENABLE_LIST= 'ab-sel=1 block=2 clipboard=3 fileman=4 mto-buffer=5 mto-window=6 ncw=7 nicon=8 nrdonly=9 sel=10 undo=11';
defeventtab _menucat_form;
_ok.lbutton_up()
{

   list := strip(_user_cat.p_text);
   wid := _find_control('check1');
   for (;;) {
      if (wid.p_value) {
         typeless i=substr(wid.p_name,6);
         _str value=eq_value2name(i,AUTO_ENABLE_LIST);
         if (list=='') {
            list=value;
         } else {
            list :+= '|'value;
         }
      }
      wid=wid.p_next;
      if (wid.p_name=='check1') break;
   }
   _param1=list;
   p_active_form._delete_window(0);
}
_ok.on_create(_str list="")
{
   cat := "";
   value := "";
   user_list := "";
   for (;;) {
      parse list with cat '|' list ;
      if (cat=='') break;
      value=eq_name2value(cat,AUTO_ENABLE_LIST);
      if (value!='') {
         wid := _find_control('check'value);
         wid.p_value=1;
      } else {
         if (user_list=='') {
            user_list=cat;
         } else {
            user_list :+= '|'cat;
         }
      }
   }
   _user_cat.p_text=user_list;
}


defeventtab _menualias_form;
_ok.on_create(_str list="")
{
   alias := "";
   list1._delete_line();
   for (;;) {
      parse list with alias "\t" list ;
      list1.insert_line(alias);
      if (list=='') break;
   }
   //list1.top();
}
void _ok.lbutton_up()
{
   list := "";
   line := "";
   p_window_id=list1;
   top();up();
   for(;;){
      if (down()) break;
      get_line(line);
      if (line=='') continue;
      if (list=='') {
         list=line;
      } else {
         list :+= "\t"line;
      }
   }
   _param1=list;
   p_active_form._delete_window(0);
}

