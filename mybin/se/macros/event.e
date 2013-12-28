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
#include "vsevents.sh"
#import "adaptiveformatting.e"
#import "bind.e"
#import "combobox.e"
#import "dlgman.e"
#import "files.e"
#import "guiopen.e"
#import "listbox.e"
#import "main.e"
#import "recmacro.e"
#import "slickc.e"
#import "stdprocs.e"
#import "util.e" 
#endregion

/*
    Tagging for events.
*/
#define ON_SELECT_I      VSEV_FIRST_ON
#define ON_CLOSE_I        (ON_SELECT_I+2)
#define ON_GOT_FOCUS_I    (ON_SELECT_I+3)
#define ON_LOST_FOCUS_I   (ON_SELECT_I+4)
#define ON_CHANGE_I       (ON_SELECT_I+5)
#define ON_RESIZE_I       (ON_SELECT_I+6)
#define ON_DROP_DOWN_I    (ON_SELECT_I+26)
#define ON_SCROLL_LOCK_I  (ON_SELECT_I+29)
#define ON_DROP_FILES_I   (ON_SELECT_I+30)
#define ON_CREATE_I       (ON_SELECT_I+31)
#define ON_DESTROY_I      (ON_SELECT_I+32)
#define ON_CREATE2_I      (ON_SELECT_I+33)
#define ON_DESTROY2_I     (ON_SELECT_I+34)
#define ON_SPIN_UP_I      (ON_SELECT_I+35)
#define ON_SPIN_DOWN_I    (ON_SELECT_I+36)
#define ON_SCROLL_I       (ON_SELECT_I+37)
#define ON_CHANGE2_I      (ON_SELECT_I+38)
#define ON_LOAD_I         (ON_SELECT_I+39)
#define ON_INIT_MENU_I    (ON_SELECT_I+40)
#define ON_LAST_I         ON_INIT_MENU_I

#define KEY_OR_MOUSE_EVENT 'key_or_mouse_event'
#define MOUSE_EVENT 'mouse_event'
#define EVENT_LIST ('mouse_move='VSEV_MOUSE_MOVE' on_resize='ON_RESIZE_I' ':+\
                'on_create='ON_CREATE_I' on_destroy='ON_DESTROY_I' ':+\
                'on_create2='ON_CREATE2_I' on_destroy2='ON_DESTROY2_I' ':+\
                'on_got_focus='ON_GOT_FOCUS_I' on_lost_focus='ON_LOST_FOCUS_I' ':+\
                'on_load='ON_LOAD_I' on_close='ON_CLOSE_I' ':+\
                'on_change='ON_CHANGE_I' lbutton_up='VSEV_LBUTTON_UP' ':+\
                'on_spin_up='ON_SPIN_UP_I' on_spin_down='ON_SPIN_DOWN_I' ':+\
                'on_drop_down='ON_DROP_DOWN_I' on_init_menu='ON_INIT_MENU_I' ':+\
                'on_scroll='  ON_SCROLL_I)
defeventtab _event_form;
_eventcombo.lbutton_double_click()
{
   _eventok.call_event(_control _eventok,LBUTTON_UP);
}
static _str gform_list[]={
   'key_press','mouse_click','mouse_move',
   'on_resize','on_create','on_destroy',
   'on_create2','on_destroy2',
   'on_got_focus','on_lost_focus',
   'on_load','on_close',
   'on_init_menu',
};
static _str gtext_box_list[]={
   'key_press','mouse_click','mouse_move','on_resize',
   'on_create','on_destroy','on_create2','on_destroy2',
   'on_got_focus','on_lost_focus','on_change',
};
static _str gcheck_box_list[]={
   'key_press','mouse_click','mouse_move','on_resize',
   'on_create','on_destroy','on_create2','on_destroy2',
   'on_got_focus','on_lost_focus','lbutton_up',
};
static _str gframe_list[]={
  'key_press','mouse_click','mouse_move','on_resize',
  'on_create','on_destroy','on_create2','on_destroy2',
};
static _str glist_box_list[]={
   'key_press','mouse_click','mouse_move','on_resize',
   'on_create','on_destroy','on_create2','on_destroy2',
   'on_got_focus','on_lost_focus','on_change(int reason)',
};
static _str geditor_list[]={
   'key_press','mouse_click','mouse_move','on_resize',
   'on_create','on_destroy','on_create2','on_destroy2',
   'on_got_focus','on_lost_focus',
};
static _str gscroll_bar_list[]={
   'key_press','mouse_move','on_resize',
   'on_create','on_destroy','on_create2','on_destroy2',
   'on_got_focus','on_lost_focus','on_change','on_scroll',
};
static _str gcombo_box_list[]={
   'key_press','mouse_click','mouse_move','on_resize',
   'on_create','on_destroy','on_create2','on_destroy2',
   'on_got_focus','on_lost_focus','on_drop_down(int reason)','on_change(int reason)',
};
static _str gpicture_box_list[]={
   'key_press','mouse_click','mouse_move','on_resize',
   'on_create','on_destroy','on_create2','on_destroy2',
   'on_got_focus','on_lost_focus','lbutton_up',
};
static _str gimage_list[]={
   'mouse_click','mouse_move',
   'on_create','on_destroy','on_create2','on_destroy2',
   'lbutton_up',
};
static _str ggauge_list[]={
   'key_press','mouse_click','mouse_move','on_resize',
   'on_create','on_destroy','on_create2','on_destroy2',
   'on_got_focus','on_lost_focus',
};
static _str gspin_list[]={
   'key_press','mouse_click','mouse_move','on_resize',
   'on_create','on_destroy','on_create2','on_destroy2',
   'on_got_focus','on_lost_focus','on_spin_up','on_spin_down','on_change(int reason)',
};
static _str gsstab_list[]={
   'mouse_move','on_resize',
   'on_create','on_destroy','on_create2','on_destroy2',
   'on_got_focus','on_lost_focus','on_change(int reason)',
};
static _str gtree_view_list[]={
   'on_resize',
   'on_create','on_destroy','on_create2','on_destroy2',
   'on_got_focus','on_lost_focus','on_change(int reason,int index)',
};
static _str gminihtml_list[]={
   'on_resize',
   'on_create','on_destroy','on_create2','on_destroy2',
   'on_got_focus','on_lost_focus','on_change(int reason,_str hrefText)',
};
_eventcombo.on_create()
{
   int wid=_display_wid;
   if (!wid) {
      // Assume just testing the form and use the form itself
      wid=p_active_form;
   }
   _str default_event='';
   _str list[];
   switch (wid.p_object) {
   case OI_FORM:
      list=gform_list;
      default_event='on_load';
      break;
   case OI_TEXT_BOX:
      list=gtext_box_list;
      default_event='on_change';
      break;
   case OI_CHECK_BOX:
   case OI_COMMAND_BUTTON:
   case OI_RADIO_BUTTON:
      list=gcheck_box_list;
      default_event='lbutton_up';
      break;
   case OI_FRAME:
   case OI_LABEL:
      list=gframe_list;
      default_event='on_create';
      break;
   case OI_LIST_BOX:
      list=glist_box_list;
      default_event='on_change';
      break;
   case OI_EDITOR:
      list=geditor_list;
      default_event='on_create';
      break;
   case OI_HSCROLL_BAR:
   case OI_VSCROLL_BAR:
      list=gscroll_bar_list;
      default_event='on_change';
      // on_change not call for WM_THUMBTRACK
      // In other words, on_change gets call when user releases the mouse
      // button.
      break;
   case OI_COMBO_BOX:
      list=gcombo_box_list;
      default_event='on_change';
      break;
   case OI_PICTURE_BOX:
      list=gpicture_box_list;
      default_event='on_create';
      break;
   case OI_IMAGE:
      list=gimage_list;
      default_event='on_create';
      break;
   case OI_GAUGE:
      list=ggauge_list;
      default_event='on_create';
      break;
   case OI_SPIN:
      list=gspin_list;
      default_event='on_spin_up';
      break;
   case OI_SSTAB:
      list=gsstab_list;
      default_event='on_change';
      break;
   case OI_TREE_VIEW:
      list=gtree_view_list;
      default_event='on_change';
      break;
   case OI_MINIHTML:
      list=gminihtml_list;
      default_event='on_change';
      break;
   }
   // List is not too long yet
   _str event_name='';
   int key_press=0;
   int mouse_click=0;
   int i=0;
   for (i=0;i<list._length();++i) {
      event_name=list[i];
      if (event_name=='') break;
      switch (event_name) {
      case 'key_press':
         key_press=1;
         continue;
      case 'mouse_click':
         mouse_click=1;
         continue;
      }
      _lbadd_item(event_name);
   }
   if (key_press && mouse_click) {
      _lbadd_item(KEY_OR_MOUSE_EVENT);
   } else if (mouse_click) {
      _lbadd_item(MOUSE_EVENT);
   }
   _lbsort('i');
   p_user=default_event;
   p_text=default_event;
#if 0
   status=_cbi_search();
   if (!status) {
      p_cb_list_box._lbselect_line();
   }
#endif
}
#if 0
void _eventcombo.on_change(int reason)
{
   if (reason == CHANGE_HIGHLIGHT) return;
   if (p_text!=_eventcombo.p_user) {
      _beep();
      p_text=_eventcombo.p_user
      return('');
   }
}
#endif
_eventok.lbutton_up()
{
   typeless status=_eventcombo._cbi_search('','(\(|$)');
   if (status) {
      _message_box('Invalid event name');
      p_window_id=_control _eventcombo;
      _set_sel(1,length(p_text)+1);_set_focus();
      return('');
   }
   int kindex=0;
   typeless event='';
   typeless result='';
   _str orig_caption='';
   _str event_name=strip(_eventcombo._lbget_text());
   if (event_name==KEY_OR_MOUSE_EVENT || event_name==MOUSE_EVENT) {
      orig_caption=_eventlabel.p_caption;
      _eventhelp.p_visible=_eventok.p_visible=_eventcombo.p_visible=0;
      if (event_name==MOUSE_EVENT) {
         _eventlabel.p_caption='Click mouse button to select event';
         for (;;) {
            event=get_event();
            if (event:==ESC) break;

            kindex=event2index(event);
            if ( vsIsMouseEvent(kindex)) {
               break;
            }

         }
      } else {
         _eventlabel.p_caption='Press key or mouse button to select event';
         event=get_event();
      }
      if (event==ESC) {
         if (event_name==MOUSE_EVENT) {
            p_window_id=_eventok;
            _eventhelp.p_visible=_eventok.p_visible=_eventcombo.p_visible=1;
            _eventlabel.p_caption=orig_caption;
            return('');
         }
         result=_message_box('Add <Esc> Key?','',MB_YESNOCANCEL|MB_ICONQUESTION);
         if (result!=IDYES) {
            p_caption=orig_caption;
            return('');
         }
      }
      p_window_id=_control _eventcancel;
      if (mou_last_x('m')>=0 && mou_last_x('m')<p_width &&
          mou_last_y('m')>=0 && mou_last_y('m')<p_height){
         p_window_id=_eventok;
         _eventhelp.p_visible=_eventok.p_visible=_eventcombo.p_visible=1;
         _eventlabel.p_caption=orig_caption;
         return('');
      }
      if (event:!=ESC) {
         event=_select_mouse_event(event);
         if (event:==ESC) {
            p_window_id=_eventok;
            _eventhelp.p_visible=_eventok.p_visible=_eventcombo.p_visible=1;
            _eventlabel.p_caption=orig_caption;
            return('');
         }
      }
      p_window_id=_eventok;
      result=event2index(event);
   } else {
      parse event_name with result '(';
      result=eq_name2value(result,EVENT_LIST)' 'event_name;
   }
   p_active_form._delete_window(result);
}

static int _find_any_event_index2(int wid,int ctl_wid,_str option,
                                  int eventtab_i,_str form_name)
{
   if (ctl_wid) {
      eventtab_i=wid.p_eventtab;
   }
   _str etab_form='';
   if (wid==ctl_wid || !(name_type(eventtab_i)&EVENTTAB_TYPE)) return(0);
   parse name_name(eventtab_i) with etab_form '.';
   boolean need_inheritance=!name_eq(translate(etab_form,'_','-'),form_name);
   if (need_inheritance) return(0);
   VSEVENT_BINDING list[];
   list_bindings(eventtab_i,list);
   int i,index,NofBindings=list._length();
   if (option) {
      index=eventtab_index(eventtab_i,eventtab_i,VSEV_LBUTTON_UP);
      if (index & 0xffff0000) return(index);
      // Look for ON_??? event
      for (i=0;i<NofBindings;++i) {
         if (vsIsOnEvent(list[i].iEvent)) {
            index=list[i].binding;
            if (index & 0xffff0000) return(index);
         }
      }
   } else {
      for (i=0;i<NofBindings;++i) {
         if (!vsIsOnEvent(list[i].iEvent)) {
            index=list[i].binding;
            if (index & 0xffff0000) return(index);
         }
      }
   }
   return(0);
}

static int _find_any_event_index(int ctl_wid,int eventtab_i)
{
   // If this control has an event table or user has specified
   // an inheritance event table, try this first.
   typeless index=0;
   _str form_name=ctl_wid.p_active_form.p_name;
   if (eventtab_i) {
      index=_find_any_event_index2(ctl_wid,0,1,eventtab_i,form_name);
      if (index) return(index);
      index=_find_any_event_index2(ctl_wid,0,0,eventtab_i,form_name);
      if (index) return(index);
   }
   // Now search all the other controls
   index=_for_each_control(ctl_wid.p_active_form,
                        _find_any_event_index2,'',ctl_wid,1,0,form_name);
   if (index) return(index);
   index=_for_each_control(ctl_wid.p_active_form,
                        _find_any_event_index2,'',ctl_wid,0,0,form_name);
   if (index) return(index);
   return(index);
}

/**
 * Find source code for form or event table specified.  Cursor is placed on 
 * definition of event table.
 * 
 * @return  Returns 0 if successful.  Otherwise, STRING_NOT_FOUND_RC or 
 * FILE_NOT_FOUND_RC is returned and message box is displayed.
 * @categories Search_Functions
 */
_str _find_form_eventtab(_str form_name,boolean ReturnModuleFilename=false)
{
   form_name=translate(name_case(form_name),'_','-');
   int index=find_index(form_name,oi2type(OI_FORM));
   if (!index) {
      index=find_index(form_name,EVENTTAB_TYPE);
      if (!index) {
         if (ReturnModuleFilename) return("");
         _message_box(nls("Could not find form '%s'",form_name));
         return(STRING_NOT_FOUND_RC);
      }
   }
   int i=0;
   int child=0;
   int tindex=0;
   int eventtab_i=0;
   int code_index=0;
   if (name_type(index)&EVENTTAB_TYPE) {
      eventtab_i=index;

      VSEVENT_BINDING list[];
      list_bindings(eventtab_i,list);
      int NofBindings=list._length();
      code_index=0;
      for (i=0;i<NofBindings;++i) {
         if (!vsIsOnEvent(list[i].iEvent)) {
            code_index=list[i].binding;
            if (code_index & 0xffff0000) break;
         }
      }
      if (!(code_index & 0xffff0000)) {
         if (ReturnModuleFilename) return("");
         _message_box(nls("Could not find event handler for event table '%s'",form_name));
         return(STRING_NOT_FOUND_RC);
      }
   } else {
      child=index &0xffff;
      index=index>>16;
      for (;;++child) {
         tindex=(index<<16)|child;
         if (name_name(tindex)=='' ) {
            if (ReturnModuleFilename) return("");
            _message_box(nls("Could not find event handler for form '%s'",form_name));
            return(STRING_NOT_FOUND_RC);
         }
         eventtab_i=tindex.p_eventtab;
         if (!(name_type(eventtab_i)&EVENTTAB_TYPE)) {
            continue;
         }
         _str etab_form='';
         parse name_name(eventtab_i) with etab_form '.';
         boolean need_inheritance=!name_eq(translate(etab_form,'_','-'),form_name);
         if (need_inheritance) continue;
         VSEVENT_BINDING list[];
         list_bindings(eventtab_i,list);
         int NofBindings=list._length();
         code_index=0;
         for (i=0;i<NofBindings;++i) {
            if (!vsIsOnEvent(list[i].iEvent)) {
               code_index=list[i].binding;
               if (code_index & 0xffff0000) {
                  break;
               }
            }
         }
         if (code_index & 0xffff0000) break;
      }
   }
   if (!(code_index & 0xffff0000)) {
      if (ReturnModuleFilename) return("");
      _message_box(nls("Could not find event handler for form '%s'",form_name));
      return(STRING_NOT_FOUND_RC);
   }
   int module_index=(code_index & 0xffff0000)>>16;
   _str module_name=name_name(module_index);
   if (module_name=='') {
      if (ReturnModuleFilename) return("");
      _message_box(nls("Could not find event handler for form '%s'",form_name));
      return(STRING_NOT_FOUND_RC);
   }
   module_name=substr(module_name,1,length(module_name)-1);
   _str filename=path_search(module_name,'VSLICKMACROS');
   if (filename=='') {
      if (ReturnModuleFilename) return("");
      _message_box(nls("Could not find event handler for form '%s'",form_name));
      return(STRING_NOT_FOUND_RC);
   }
   if (ReturnModuleFilename) {
      return(filename);
   }
   typeless file_already_loaded=buf_match(filename,1,'hx')!='';
   typeless status=edit(maybe_quote_filename(filename));
   if (status) {
      if (status==NEW_FILE_RC) {
         quit(false);
         _message_box(nls("File '%s' not found",filename));
         return(FILE_NOT_FOUND_RC);
      }
      _message_box(nls("Error load file '%s'",filename));
      // Must return 0 since its difficult to reverse effects of edit function
      return(0);
   }
   typeless p,p2;
   _str name='';
   _str word='';
   _str ctl_name='';
   parse form_name with form_name '.' ctl_name;
   if (ctl_name!='') {
      save_pos(p);top();
      name='^'ctl_name'.';
      status=search(name,'rh@');
      for (;;) {
         if (status) break;
         // Check if this is in the right event table
         save_pos(p2);
         int status2=search('^[ \t]*defeventtab[ \t]#{[a-zA-Z_$][a-zA-Z0-9_$]@}([~a-zA-Z0-9_$]|$)','@rh-');
         if (!status2) {
             word=get_match_text(0);
         }
         restore_pos(p2);
         if (!status2 && name_eq(word,form_name)) break;
         status=repeat_search();
      }
      if (!status) {
         return(0);
      }
   }
   status=_find_eventtab(form_name,ctl_name);
   if (status) {
      _message_box(nls("Event table '%s' not found",form_name));
      // Must return 0 since its difficult to reverse effects of edit function
      return(0);
   }
   return(0);
}

_str _select_event()
{
   typeless status=0;
   int ctl_wid=p_window_id;
   if (p_name=='') {
      if ((ctl_wid.p_object==OI_IMAGE || ctl_wid.p_object==OI_PICTURE_BOX) &&
         ctl_wid.p_command!='') {
         status=find_proc(ctl_wid.p_command);
         return(status);
      }
      _message_box(nls("This control has no name.\n\nSet name proproperty."));
      return(1);
   }
   int view_id=0;
   get_window_id(view_id);
   typeless result=show('-modal _event_form');
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   typeless event_index='';
   typeless event_name='';
   parse result with event_index event_name;
   activate_window(view_id);
#if 0
   // A better way to do this is to insert a phony event "command" into
   // the event list
   if (index2event(event_index)==LBUTTON_UP &&
      (ctl_wid.p_object==OI_IMAGE || ctl_wid.p_object==OI_PICTURE_BOX) &&
      ctl_wid.p_command!='') {
      status=find_proc(ctl_wid.p_command);
      return(status);
   }
#endif
   _str form_name=p_active_form.p_name;
   // Check if any code has already been written for this control
   // Any user level 1 event table?
   int index=0;
   typeless eventtab_i=p_eventtab;
   if (!(name_type(eventtab_i) & EVENTTAB_TYPE)) eventtab_i=0;
   _str etab_form='';
   boolean need_inheritance=false;
   parse name_name(eventtab_i) with etab_form '.';
   if (ctl_wid.p_object==OI_FORM) {
      need_inheritance=!name_eq(translate(name_name(eventtab_i),'_','-'),form_name) && eventtab_i;
   } else {
      need_inheritance=!name_eq(translate(name_name(eventtab_i),'_','-'),form_name'.'ctl_wid.p_name) && eventtab_i;
   }
   int i=0;
   _str inherit_etab_name=translate(name_name(eventtab_i),'_','-');
   if (eventtab_i) {
      boolean skip_first=need_inheritance;
      index=eventtab_index(eventtab_i,eventtab_i,event_index);
      if (!index || need_inheritance) {
         // Check for inherited event handler
         for (i=0;i<20;++i) {
            if (!skip_first) {
               eventtab_i=eventtab_inherit(eventtab_i);
               if (!(name_type(eventtab_i) & EVENTTAB_TYPE)) eventtab_i=0;
               if (!eventtab_i) break;
            }
            skip_first=0;
            index=eventtab_index(eventtab_i,eventtab_i,event_index);
            if (index) break;
         }
         result='';
         if (index || need_inheritance) {
            if (p_name=='') {
               result='g';
            } else {
               result=show('-modal _inherit_form',index,need_inheritance);
               if (result=='') {
                  return('');
               }
               if (result=='d'){
                  need_inheritance=0;
                  index=0;
                  eventtab_i=0;
#if 0
                  if (index && need_inheritance) {
                     need_inheritance=0;
                     index=0;
                     eventtab_i=0;
                     ctl_wid.p_eventtab=0;
                  } else {
                     need_inheritance=0;
                     index=0;
                     eventtab_i= ctl_wid.p_eventtab;
                  }
#endif
               }
            }
            if (result!='g') {
               index=0;
            }
         }
         if (!index) {
            eventtab_i=p_eventtab;
            if (need_inheritance || result=='d') eventtab_i=0;
         }
      }
   }
   _str ctl_name='';
   parse name_name(eventtab_i) with etab_form '.' ctl_name;
   form_name=translate(etab_form,'_','-');
   if (form_name=='') {
      form_name=p_active_form.p_name;
      ctl_name=p_name;
   } else {
      ctl_name=translate(ctl_name,'_','-');
      if (ctl_name=='') {
         ctl_name=form_name;
      }
   }
   // Has the user selected an existing event handler?
   if (index) {
      status=_find_event_function(ctl_wid,eventtab_i,form_name,ctl_name,index,event_index,event_name);
      return(status);
   }
   /* Find module name by searching current control code and form code */
   _str module_name=_get_module_name(ctl_wid,eventtab_i,index);
   if (module_name=='') {
      // Check current mdi child edit window for event table. */
      status=_check_mdi_edit_window(form_name,ctl_name,1);
      if (status) {
         // Could not find any existing code
         // Let the user open a file
         _create_config_path();
         result=_OpenDialog('-new -mdi -modal',
              'Open',
              '*.e',      // Initial wildcards
              'All Files ('ALLFILES_RE'),Slick-C (*.e)',
              OFN_READONLY|OFN_EDIT,
              '',      // Default extension
              '',      // Initial filename
              _macro_path()       // Initial directory
              );
         if (result=='') {
            return(COMMAND_CANCELLED_RC);
         }
         //_mdi.p_visible=1;  // Place this window on top of other windows.  Weird I know.
#if __UNIX__
         boolean cancel=0;
         process_events(cancel);
#endif
         _mdi._set_foreground_window();
         status=edit(result);
         if (status && status!=NEW_FILE_RC) {
            return(status);
         }
         if (status!=NEW_FILE_RC) {
            return(0);
         }
         replace_line('#include "slick.sh"');
         insert_line('');
         insert_line('defeventtab 'form_name';');
      }
   } else {
      _str filename=_macro_path_search(module_name);
      if (filename == '') {
         filename=slick_path_search(module_name);
         if (filename=='') {
            _message_box(nls("File '%s' not found",module_name));
            return(1);
         }
      }
      //file_already_loaded=buf_match(absolute(arg(1)),1,'X')!='';
      filename=maybe_quote_filename(filename);
      status=edit(filename);
      if (status) return(status);

      status=_find_event_function2(form_name,ctl_name,
                                   0xffff0000, // Look for ctl_name.event
                                   event_index,
                                   event_name);
      if (status) {
         status=_find_eventtab(form_name,ctl_name);
         if (status) {
            // Found the module but could not find "defeventtab form_name"
            _message_box(nls("Event table '%s' not found",form_name));
            return(status);
         }
      } else {
         // Found some code for this one.  Don't bother inserting any code.
         return(0);
      }

#if 0
      status=_find_eventtab(form_name,ctl_name);
      if (status) {
         // Found the module but could not find "defeventtab form_name"
         _message_box(nls("Event table '%s' not found",form_name));
         return(status);
#if 0
         _message_box(nls("Event table '%s' not found\n\n":+
                          "Insert defeventtab statement?",form_name),
                     '',MB_YESNOCANCEL|MB_ICONQUESTION)
#endif
      }
#endif
   }
   if (!pos('(',event_name)) {
      if ((vsIsOnEvent(event_index)) ||
          (vsIsMouseEvent(event_index))) {
         // It makes sense that event2name return upper case.  We
         // might want to remove this lowcase call later.
         event_name=lowcase(event2name(index2event(event_index)));
         event_name=translate(event_name,'_','-');
      } else {
         event_name=_source_event_name(event_index);
      }
   }
   if (need_inheritance) {
      insert_line('defeventtab 'form_name'.'ctl_name' _inherit 'inherit_etab_name';');
   }
   if (!pos('(',event_name)) {
      insert_line("void "ctl_name'.'event_name"()");
   } else {
      insert_line("void "ctl_name'.'event_name);
   }
   insert_line('{');
   insert_line('');
   insert_line('}');
   up();
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   if (p_SyntaxIndent<=0) {
      p_col=4;
   } else {
      p_col=p_SyntaxIndent+1;
   }
   return(0);
}
static _str _get_module_name(int ctl_wid,int eventtab_i,int &index)
{
   int module_index=index & 0xffff0000;
   if (module_index) {
      module_index= module_index>>16;
   } else {
      index=_find_any_event_index(ctl_wid,eventtab_i);
      module_index=index & 0xffff0000;
      if (module_index) {
         module_index= module_index>>16;
      }
   }
   _str name=name_name(module_index);
   if (name=='') {
      return(name);
   }
   // Strip the 'x' on the extension'
   return(substr(name,1,length(name)-1));
}
static _str _find_event_function2(_str form_name,_str ctl_name,
                                  int index, int event_index, _str event_name)
{
   _str name2='';
   _str name='';
   _str params='';
   // If this is the key or mouse click case
   if (event_name=='') {
      name=event2name(index2event(event_index));
      if (length(name)>1 && pos('[_\-]',name,1,'r')) {
         name=stranslate(name,'[_\-]','-');
      }
      // Look for name in double or single quotes
      name='(["'']|)'name'(["'']|)';
      //_undo 's';insert_line name;_undo 's'
   } else {
      parse event_name with name '(' +0 params;
      // Look for name with underscores or dashes if necessary
      if (pos('_',name)) {
         name=stranslate(name,'[_\-]','_');
      }
      // Look for name in double or single quotes
      name='(["'']|)'name'(["'']|)';
   }
   boolean look_for_control=0;
   _str left_delim_re='';
   _str right_delim_re='';
   _str try1='',try2='';
   if (index & 0xffff0000) {
      // Event function defined like this:  ctl_name.event()?
      look_for_control=1;
      left_delim_re='[ \t,\-]';
      right_delim_re='[ \t,\-(]';
      try1='.'name:+right_delim_re;
      try2='.?*'left_delim_re:+name:+right_delim_re;
      name='^([A-Za-z_$]?* {#0'ctl_name'}|{#0'ctl_name'})(('try1')|('try2'))';
   } else {
      // Event function defined like this:  def event,event-event=?
      left_delim_re='[ \t,\-]+';
      right_delim_re='[ \t,\-]+';
      name='^def?*'left_delim_re:+name:+'('right_delim_re'|=)';
   }
   _str word='';
   save_pos(auto p);top();
   int status=search(name,'rih@');
   for (;;) {
      if (status) break;
      if (look_for_control) {
         // Check if ctl_name is in correct case
         word=get_match_text(0);
         if (word!=ctl_name) {
            status=repeat_search();
            continue;
         }
      }

      // Check if this is in the right event table
      save_pos(auto p2);
      save_search(auto a,auto b,auto c,auto d);
      int status2=search('^[ \t]*defeventtab[ \t]#{[a-zA-Z_$][a-zA-Z0-9_$]@}([~a-zA-Z0-9_$]|$)','@rh-');
      if (!status2) {
          word=get_match_text(0);
      }
      restore_search(a,b,c,d);
      restore_pos(p2);
      if (!status2 && name_eq(word,form_name)) break;
      status=repeat_search();
   }
   return(status);
}
static _str _find_event_function(int ctl_wid, typeless eventtab_i,
                                 _str form_name, _str ctl_name,
                                 int &index, int event_index, _str event_name)
{
   // Look for this module and event table.
   _str module_name=_get_module_name(ctl_wid,eventtab_i,index);
   if (module_name=='') {
      return(_check_mdi_edit_window(form_name,ctl_name,0));
   }
   _str filename=slick_path_search(module_name);
   if (filename=='') {
      _message_box(nls("File '%s' not found",module_name));
      return(1);
   }
   filename=maybe_quote_filename(filename);
   boolean cancel=0;
   process_events(cancel);
   _mdi.p_visible=1;
   typeless status=edit(filename);
   if (status) {
      return(status);
   }
   status=_find_event_function2(form_name,ctl_name,index,event_index,event_name);
   if (status) {
      status=_find_eventtab(form_name,ctl_name);
      if (status) {
         _message_box(nls("Could not find event handler or form event table '%s'",form_name));
         return(status);
      }
      return(0);
   }
   return(0);
}
static int _check_mdi_edit_window(_str form_name,_str ctl_name,boolean ignore_not_found)
{
   typeless status=1;
   int view_id=0;
   get_window_id(view_id);
   int wid=_mdi.p_child;
   if (!(wid.p_window_flags & HIDE_WINDOW_OVERLAP) &&
       file_eq('.'_get_extension(wid.p_buf_name),_macro_ext)) {
      p_window_id=wid;
      status=_find_eventtab(form_name,ctl_name);
      if (status) {
         return(status);
      }
      _set_focus();
   }
   if (status) {
      activate_window(view_id);
      if (ignore_not_found) {
         return(1);
      }
      _set_focus();
      _message_box(nls('Could not determine source file'));
      return(1);
   }
   return(0);
}
static int _find_eventtab(_str form_name, _str ctl_name)
{
   int status2=0;
   save_pos(auto p);
   // Look for event table specific to this control. Could be inheritance line.
   // defeventtab  form_name.ctl_name;
   if (ctl_name!='') {
      top();
      status2=search('^[ \t]*defeventtab[ \t]#'form_name'.'ctl_name'([~a-zA-Z0-9_$]|$)','@rh');
      if (!status2) {
         return(0);
      }
   }
   // Well, let at least find the form event table
   top();
   status2=search('^[ \t]*defeventtab[ \t]#'form_name'([~a-zA-Z0-9_$]|$)','@rh');
   if (status2) {
      restore_pos(p);
      return(status2);
   }
   return(0);
}


defeventtab _inherit_form;
void _inheritok.on_create()
{
   if (!arg(1)) {
      _inheritgo.p_enabled=0;
   }
   if (!arg(2)) {
      _inheritcode.p_enabled=0;
   }
}
void _inheritok.lbutton_up()
{
   _str result='';
   if (_inheritcode.p_value) {
      result='i';
   } else if(_inheritgo.p_value){
      result='g';
   } else {
      result='d';
   }
   p_active_form._delete_window(result);
}
