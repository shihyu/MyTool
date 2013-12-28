////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48139 $
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
#import "dlgeditv.e"
#import "help.e"
#import "main.e"
#import "picture.e"
#import "sstab.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbautohide.e"
#import "tbtabgroup.e"
#import "util.e"
#import "window.e"
#endregion

static _str _default_wid,_adefault_wid,_in_enter,_cancel_wid;
definit()
{
   _in_enter=0;
}

//
//    DIALOG MANAGER.  Automatic inheritance for form control
//
defeventtab _ainh_dlg_manager;
#if 0
void _ainh_dlg_manager.c_e()
{
   p_enabled=0;
}
#endif
void _ainh_dlg_manager."c-s- "()
{
   p_window_id=p_active_form;
   _on_edit_form();
}

#if 0
void _ainh_dlg_manager."s- "()
{
   p_window_id=p_active_form;
   _on_edit_form();
}
#endif
#if 0
_ainh_dlg_manager." "()
{
   if (p_object==OI_CHECK_BOX) {
      call_event(p_window_id,LBUTTON_UP);
   }
}
#endif
void _ainh_dlg_manager.F7()
{
   _retrieve_next_form('-',1);
}
void _ainh_dlg_manager.F8()
{
   _retrieve_next_form('',1);
}
_ainh_dlg_manager.up,left()
{
   if (p_object!=OI_RADIO_BUTTON && p_object!=OI_CHECK_BOX &&
       p_object!=OI_COMMAND_BUTTON) return('');
   /* Look for previous radio button. */
   int first_wid=p_window_id;
   int wid=first_wid;
   int tab_index=0;
   int next_wid=0;
   int wrap_index=0;
   int wrap_wid=0;
   for (;;) {
      wid=wid.p_next;
      if (wid==first_wid) break;
      if (wid.p_tab_stop && wid.p_tab_index>0 &&
          wid._enabled()){
          if(wid.p_tab_index<p_tab_index && wid.p_tab_index>tab_index) {
             tab_index=wid.p_tab_index;
             next_wid=wid;
          }
          if (!wrap_wid || wid.p_tab_index>wrap_index) {
             wrap_index=wid.p_tab_index;
             wrap_wid=wid;
          }
      }
   }
   if (next_wid) {
      p_window_id=next_wid;
      if (p_object==OI_RADIO_BUTTON) {
         if (!p_value) {
            p_value=1;
            //call_event(p_window_id,LBUTTON_UP)
         }
      }
   } else if (wrap_wid) {
      p_window_id=wrap_wid;
      if (p_object==OI_RADIO_BUTTON) {
         if (!p_value) {
            p_value=1;
            //call_event(p_window_id,LBUTTON_UP)
         }
      }
   }
   _set_focus();
}
_ainh_dlg_manager.down,right()
{
   if (p_object!=OI_RADIO_BUTTON && p_object!=OI_CHECK_BOX &&
       p_object!=OI_COMMAND_BUTTON) return('');
   /* Look for previous radio button. */
   int first_wid=p_window_id;
   int wid=first_wid;
   int next_tab_index=0xffffff;  /* Make this larger that 65535 */
   int next_wid=0;
   int wrap_index=0;
   int wrap_wid=0;
   for (;;) {
      wid=wid.p_next;
      if (wid==first_wid) break;
      if (wid.p_tab_stop && wid.p_tab_index>0 &&
          wid._enabled()){
          if(wid.p_tab_index>p_tab_index &&
             (wid.p_tab_index<next_tab_index)) {
             next_tab_index=wid.p_tab_index;
             next_wid=wid;
          }
          if(!wrap_wid || wid.p_tab_index<wrap_index) {
             wrap_index=wid.p_tab_index;
             wrap_wid=wid;
          }
      }
   }
   if (next_wid) {
      p_window_id=next_wid;
      if (p_object==OI_RADIO_BUTTON) {
         if (!p_value) {
            p_value=1;
            //call_event(p_window_id,LBUTTON_UP)
         }
      }
   } else if (wrap_wid) {
      p_window_id=wrap_wid;
      if (p_object==OI_RADIO_BUTTON) {
         if (!p_value) {
            p_value=1;
            //call_event(p_window_id,LBUTTON_UP)
         }
      }
   }
   _set_focus();
}
static int _default2(int wid)
{
   if (wid.p_object!=OI_COMMAND_BUTTON) {
      return(0);
   }
   if (!wid.p_enabled) {
      return(0);
   }
   if (wid.p_cancel) {
      _cancel_wid=wid;
   }
   if (wid.p_adefault) {
      _adefault_wid=wid;
   } else if (wid.p_default){
      _default_wid=wid;
   }
   return(0);
}
static _str in_lbdown=0;
void _ainh_dlg_manager.lbutton_up()
{
   if (p_object==OI_COMMAND_BUTTON) {
      if (p_cancel) {
         call_event(defeventtab  _ainh_dlg_manager,ESC,'E');
      } else if (p_default) {
         if (_in_enter) {
            _dmhelp();
         } else {
            call_event(defeventtab  _ainh_dlg_manager,ENTER,'E');
         }
      } else if(p_command!=""){
         _in_enter=p_window_id;
         _tbCommand();
         _in_enter=0;
      } else {
         _dmhelp();
      }
   }
}

static void _dmhelp2(_str help_item)
{
   if (substr(help_item,1,1)=='?') {
      popup_imessage(substr(help_item,2));
      return;
   }
   _str keyword='';
   _str help_file='';
   parse help_item with keyword ':' help_file;
   help(keyword,help_file);

}
void _dmhelp(...)
{
   _str help_item=p_help;
   if (help_item=='') {
      help_item=p_active_form.p_help;
      if (help_item == "") {
         // Loop thru form's children for a tab control and use
         // the active tab's ActiveHelp string.
         int formwid;
         formwid = p_active_form;
         int child, orichild;
         orichild = child = formwid.p_child;
         while (child) {
            if (child.p_object == OI_SSTAB) {
               help_item = child.p_ActiveHelp;
               break;
            }
            child = child.p_next;
            if (child == orichild) break;
         }
      }
   }
   if (help_item=='') {
      return;
   }
   _dmhelp2(help_item);
}
void _ainh_dlg_manager.esc,A_F4,'M-F4',on_close()
{
   if (p_DockingArea) {
      if (last_event():==A_F4 && name_on_key(A_F4)=='safe-exit') {
         safe_exit();
      }
      if (last_event():==ESC) {
         if (_default_option(VSOPTION_HAVECMDLINE)) {
            _cmdline._set_focus();
         } else {
           if (_no_child_windows()) {
              _mdi.p_child._set_focus();
           }
         }
         //if (!_no_child_windows()) {
         //   _mdi.p_child._set_focus();
         //} else {
         //   _cmdline._set_focus();
         //}
      }
      return;
   } else if( _tbIsAutoShownWid(p_active_form) ) {
      // Note:
      // We could really just call _tbAutoHide and be safe,
      // but the check is for clarity.
      if( last_event():==ESC ) {
         _tbAutoHide(p_active_form);
         return;
      }
   }
   typeless event=last_event();
   typeless handler=p_active_form._event_handler(on_close);
   if (handler) {
      p_active_form.call_event(p_active_form,on_close);
      return;
   }
   _cancel_wid='';_default_wid='';_adefault_wid='';
   _for_each_control(p_active_form,_default2, 'C'); // Ignore hidden controls, but not controls clipped off the dialog.
   if (_cancel_wid!='') {
      handler=_cancel_wid._event_handler(LBUTTON_UP);
   }
   if (_cancel_wid!='' && handler) {
      _cancel_wid.call_event(_cancel_wid,LBUTTON_UP);
   } else if (event:==A_F4 || event:==ON_CLOSE || (_cancel_wid!='' && !handler)) {
      rc=COMMAND_CANCELLED_RC;
      p_active_form._delete_window();
   }
   //return(0)
}
void _dmResetInEnter()
{
   _in_enter=0;
}
boolean _ainh_dlg_manager.enter()
{
   if (_in_enter && p_window_id==_in_enter) {
      return(1);
   }
   _default_wid='';
   _adefault_wid='';

   typeless wid=0;
   _for_each_control(p_active_form,_default2, 'C');  // Ignore hidden controls, but not clipped controls.
   if (_adefault_wid!='') {
      wid=_adefault_wid;
   } else if (_default_wid!='') {
      wid=_default_wid;
   } else {
      wid=_get_focus();
      if (!(wid==p_window_id && p_object==OI_COMMAND_BUTTON && p_command!="")) {
         // message 'nothing'
         return(1);
      }
   }
   //messageNwait('name='wid.p_name)
   /* IF the default button is the cancel button. */
   if (wid.p_cancel) {
      _in_enter=wid;  // Don't want call self
      call_event(defeventtab  _ainh_dlg_manager,ESC,'E');
      _in_enter=0;
      return(0);
   }
   if (wid.p_object==OI_COMMAND_BUTTON && wid.p_command!="") {
      _in_enter=wid;  // Don't want call self
      _tbCommand();
      _in_enter=0;
      return(0);
   }
   // Call the default button
   // Don't want call self
   if (wid.p_eventtab) {
      int index=eventtab_index(wid.p_eventtab,wid.p_eventtab,event2index(LBUTTON_UP));
      if (index) {
         wid.call_event(wid,LBUTTON_UP);
      }
   }
#if 0
   in_enter=wid;  // Don't want call self
   wid.call_event(wid,LBUTTON_UP);
   _in_enter=0;
#endif
   return(0);
}

static int _help2(int wid)
{
   if (wid.p_help!='') {
      return(wid);
   } else if( wid.p_object==OI_SSTAB && wid.p_ActiveHelp!="" ) {
      return(wid);
   }
   return(0);
}
_ainh_dlg_manager.f1()
{
   _str help_item='';
   if (p_object == OI_SSTAB) {
      help_item=p_ActiveHelp;
   } else {
      help_item=p_help;
   }
   int parent=0;
   if (help_item=='') {
      help_item=p_active_form.p_help;
      if (help_item=='') {
         parent = p_window_id;
         while (parent) {
            if (parent.p_object == OI_SSTAB) {
               help_item=parent.p_ActiveHelp;
               break;
            }
            if (parent.p_object == OI_FORM || parent.p_object == OI_MDI_FORM) {
               break;
            }
            parent = parent.p_parent;
         }
      }
   }
   typeless wid=0;
   if (help_item=='') {
      wid=_for_each_control(p_active_form,_help2);
      if (!wid) {
         return('');
      }
      help_item=wid.p_help;
      if( help_item=="" && wid.p_object==OI_SSTAB ) {
         help_item=wid.p_ActiveHelp;
      }
      if (help_item!='' && wid.p_object==OI_COMMAND_BUTTON) {
         _in_enter=wid;  // Don't want call self
         wid.call_event(wid,LBUTTON_UP);
         _in_enter=0;
         return('');
      }
   }
   _dmhelp2(help_item);
}
void _ainh_dlg_manager.on_destroy2()
{
   if (p_init_style&IS_SAVE_XY) {
      _save_form_xy();
   }
}
static typeless   _wrap,            // index string to wrap back around to when we run out of 'next' controls
                  _wrap_wid,        // window id of control to wrap back around to
                  _next,            // index string of next control
                  _next_wid,        // window id of next control
                  _orig_wid;        // window id we're currently working with
static int _do_letter2(int wid,_str after,_str letter)
{
   switch (wid.p_object) {
   case OI_TEXT_BOX:
   case OI_COMBO_BOX:
   case OI_FORM:
   case OI_HTHELP:
   case OI_LIST_BOX:
   case OI_EDITOR:
   case OI_HSCROLL_BAR:
   case OI_VSCROLL_BAR:
   case OI_GAUGE:
   case OI_SPIN:
   case OI_TREE_VIEW:
   case OI_MINIHTML:
   case OI_SWITCH:
   case OI_TEXTBROWSER:
      return(0);
   case OI_PICTURE_BOX:
   case OI_IMAGE:
      if( wid.p_style != PSPIC_PUSH_BUTTON && wid.p_style != PSPIC_SPLIT_PUSH_BUTTON ) {
         return(0);
      }
      break;
   }
   if (!wid._enabled()) {
      return(0);
   }

   // For the tab control, check all the tabs for hot keys:
   if (wid.p_object==OI_SSTAB) {
      _str widTI;
      widTI = wid.MakeTabIndexString();
      SSTABCONTAINERINFO info;
      int childI;
      for (childI=0; childI<wid.p_NofTabs; childI++) {
         wid._getTabInfo(childI,info);
         if (pos('&'letter,info.caption,1,'i')) {
            if (widTI>after && (widTI<_next || _next=='')) {
               _next=widTI;
               _next_wid=wid;
               return(0);
            }
            if (widTI<_wrap || _wrap=='') {
               _wrap=widTI;
               _wrap_wid=wid;
               return(0);
            }
            return(0);
         }
      }
      return(0);
   }

   _str text=wid.p_caption;
   int i=pos('&'letter,text,1,'i');
   if (i && (i==1 || substr(text,i-1,1):!='&')) {
      if (wid.p_tab_index<=0 /*|| !wid.p_tab_stop*/) {
         return(0);
      }
      _str widTI;
      widTI = wid.MakeTabIndexString();
      if (widTI>after && (widTI<_next || _next=='')) {
         _next=widTI;
         _next_wid=wid;
         return(0);
      }
      if (widTI<_wrap || _wrap=='') {
         _wrap=widTI;
         _wrap_wid=wid;
         return(0);
      }
   }
   return(0);
}
int _dmDoLetter(_str letter)
{
   _wrap='';
   typeless after=MakeTabIndexString();
   _next='';
   _for_each_control(p_active_form,_do_letter2,'',after,letter);
   typeless wid=0;
   if (_next!='') {
      wid=_next_wid;
   } else if (_wrap!='') {
      wid=_wrap_wid;
   } else {
      return(1);
   }
   if (wid.p_tab_stop) {
      p_window_id=wid;_set_focus();
   }
   switch (wid.p_object) {
   case OI_COMMAND_BUTTON:
      p_window_id=wid;
      call_event(p_window_id,LBUTTON_UP);
      return(0);
   case OI_CHECK_BOX:
      p_window_id=wid;
      _next_button_state();
      call_event(p_window_id,LBUTTON_UP);
      return(0);
   case OI_RADIO_BUTTON:
      p_window_id=wid;
      _set_focus();
      return(0);
   case OI_SSTAB:
      p_window_id=wid;
      _str text;
      text = p_ActiveCaption;
      // If the tab with the matching letter is the active tab, do nothing.
      // Otherwise, locate the first matching tab and activate it.
      if (!pos('&'letter,text,1,'i')) {
         SSTABCONTAINERINFO info;
         int childI;
         for (childI=0; childI<p_NofTabs; childI++) {
            _getTabInfo(childI,info);
            if (pos('&'letter,info.caption,1,'i')) {
               p_ActiveTab = childI;
               break;
            }
         }
      }
      _set_focus();
      return(0);
   case OI_PICTURE_BOX:
   case OI_IMAGE:
      // _do_letter2() should have figured this out for us,
      // but no harm being extra careful.
      if( wid.p_style == PSPIC_PUSH_BUTTON || wid.p_style == PSPIC_SPLIT_PUSH_BUTTON ) {
         p_window_id = wid;
         call_event(p_window_id,LBUTTON_UP);
         return(0);
      }
      // Fall through
      break;
	case OI_FRAME:
		// if we have a checkbox on this frame, we might want to change the value
		if (wid.p_checkable) {
			p_window_id=wid;
			_next_button_state();
			call_event(p_window_id,LBUTTON_UP);
		}
		break;
   }
   /* User has selected frame or label. Switch to next control. */
   p_window_id=wid;
   _next_control();
   return(0);
}
static int _denext_control2(int wid,int after)
{
   if (wid.p_object==OI_FORM || wid.p_object==OI_SSTAB_CONTAINER) return(0);
   //    IF have closer tab index
   typeless tab_index=wid.MakeTabIndexString();
   if ((tab_index>after && (tab_index<_next || _next==''))) {
      //_message_box('h1 a='after' n='wid.p_name' t='tab_index' nx='_next' wid='wid);
      _next=tab_index;
      _next_wid=wid;
      return(0);
   }
   // IF  have closer tab index
   if ((tab_index<_wrap || _wrap=='')) {
      //_message_box('h2 n='wid.p_name' t='tab_index' w='_wrap);
      _wrap=tab_index;
      _wrap_wid=wid;
      return(0);
   }
   return(0);
}

/**
 * Takes the given number and pads it out to the required length 
 * as a string with 0's in front of the given number. 
 * 
 * @param number        number to become a padded string
 * 
 * @return              the transformed number string
 */
static _str MakeTabIndexLevel(int number)
{
   typeless result=number;
   if (length(number)<6) {
      result=substr("",1,6-length(number),"0"):+result;
   }
   return(result);
}

/**
 * A tab index string is a number that is used to represent a 
 * control's overall tab index within a form.  The string can be 
 * composed of several "levels" of six number places each.  The 
 * string has a 'T' at the beginning to force a string 
 * comparison rather than a numeric comparison. 
 *  
 * Thus a control that is a direct child of the main form could 
 * have tab index string = T000005, or tab_index = 5.  However, 
 * if a control is a child of container control(s), then another
 * level is added for each container. 
 *  
 * Thus, a textbox with p_tab_index = 3, within a frame with 
 * p_tab_index = 6 in the form could have index string = 
 * T000006000003. These tab index strings are used to compare 
 * controls to each other to find the "next" control that should 
 * receive focus. 
 * 
 * @return     the tab index string of the current control 
 *             (p_window_id)
 */
_str MakeTabIndexString(int wid = -1)
{
   typeless result="";
   if (wid == -1) wid=p_window_id;
   while (wid && wid.p_tab_index) {
      // make sure the tab index string is the right length, then add 
      // it to the beginning of the string already compiled
      result=MakeTabIndexLevel(wid.p_tab_index):+result;
      
      // break when we have no more parents
      if (!wid.p_parent) break;

      // if we have a tab container, we do the parent thing twice
      if (wid.p_parent.p_object==OI_SSTAB_CONTAINER) {
         wid=wid.p_parent;
      }
      // go to our parent so that we can continue making this index string
      wid=wid.p_parent;
   }

   // Force string compare
   return("T"result);
}
int _next_control2(int wid, int after)
{
   // make sure the current window id is valid for this maneuver
   if (!wid.p_tab_stop || wid.p_tab_index<=0 || !wid._enabled()) {
      return(0);
   }

   // compile the index string for this control
   typeless tab_index=wid.MakeTabIndexString();

   // IF chosen control is radio button with same parent OR
   //    have closer tab index
   // compare the current tab index string to the one we've 
   // found is the closest so far
   if ((_next!='' && wid.p_object==OI_RADIO_BUTTON &&
        _next_wid.p_object==OI_RADIO_BUTTON &&
        _next_wid.p_parent==wid.p_parent) 
       ||
       (tab_index>after && (tab_index<_next || _next==''))) {     // must be greater than the 
                                                                  // one we're looking one now 
                                                                  // ('after'), but less than 
                                                                  // the _next we've found so far

      if (wid.p_object==OI_RADIO_BUTTON) {

         // If original control was radio button with same parent,
         // do nothing.
         if (_orig_wid.p_object==OI_RADIO_BUTTON &&
             wid.p_parent==_orig_wid.p_parent) {
             return(0);
         }

         if (_next_wid!='' && _next_wid.p_object==OI_RADIO_BUTTON &&
            _next_wid.p_parent==wid.p_parent) {
            if (_next_wid.p_value) {
               return(0);
            }
            if (wid.p_value) {
              _next=tab_index;
              _next_wid=wid;
              return(0);
            }
         }
      }

      _next=tab_index;
      _next_wid=wid;
      return(0);
   }
   // IF chosen control is option button with same parent OR
   //    have closer tab index
   if ((_wrap!='' && wid.p_object==OI_RADIO_BUTTON &&
         _wrap_wid.p_object==OI_RADIO_BUTTON &&
         _wrap_wid.p_parent==wid.p_parent)
       ||
        (tab_index<_wrap || _wrap=='')) {    // we are looking for the one with the "smallest" tab index string
      if (wid.p_object==OI_RADIO_BUTTON) {
         if (_wrap!='' && wid.p_parent==_orig_wid.p_parent) {
             return(0);
         }
         if (_wrap_wid!='' && _wrap_wid.p_object==OI_RADIO_BUTTON &&
            _wrap_wid.p_parent==wid.p_parent) {
            if (_wrap_wid.p_value) {
               return(0);
            }
            if (wid.p_value) {
              _wrap=tab_index;
              _wrap_wid=wid;
              return(0);
            }
         }
      }
      _wrap=tab_index;
      _wrap_wid=wid;
      return(0);
   }
   return(0);
}
int _prev_control2(int wid,int before)
{
   if (wid.p_tab_index<=0 || !wid.p_tab_stop || !wid._enabled()) {
      return(0);
   }
   typeless tab_index=wid.MakeTabIndexString();
   /*tab_index=wid.p_tab_index;
   if (wid.p_active_form.p_tab_index) {
      tab_index=(wid.p_active_form.p_tab_index<<16)+tab_index;
   } */
   // IF chosen control is radio button with same parent OR
   //    have closer tab index
   if ((_next!='' && wid.p_object==OI_RADIO_BUTTON &&
         _next_wid.p_object==OI_RADIO_BUTTON &&
         _next_wid.p_parent==wid.p_parent
       )
       ||
        (tab_index<before && (tab_index>_next || _next==''))) {
      if (wid.p_object==OI_RADIO_BUTTON) {
         // If original control was radio button with same parent,
         // do nothing.
         if (_orig_wid.p_object==OI_RADIO_BUTTON &&
             wid.p_parent==_orig_wid.p_parent) {
             return(0);
         }
         if (_next_wid!='' && _next_wid.p_object==OI_RADIO_BUTTON &&
            _next_wid.p_parent==wid.p_parent) {
            if (_next_wid.p_value) {
               return(0);
            }
            if (wid.p_value) {
              _next=tab_index;
              _next_wid=wid;
              return(0);
            }
         }
      }
      _next=tab_index;
      _next_wid=wid;
      return(0);
   }
   // IF chosen control is option button with same parent OR
   //    have closer tab index
   if ((_wrap!='' && wid.p_object==OI_RADIO_BUTTON &&
         _wrap_wid.p_object==OI_RADIO_BUTTON &&
         _wrap_wid.p_parent==wid.p_parent
       )
       ||
       (tab_index>_wrap || _wrap=='')) {
      if (wid.p_object==OI_RADIO_BUTTON) {
         if (_wrap!='' && wid.p_parent==_orig_wid.p_parent) {
             return(0);
         }
         if (_wrap_wid!='' && _wrap_wid.p_object==OI_RADIO_BUTTON &&
            _wrap_wid.p_parent==wid.p_parent) {
            if (_wrap_wid.p_value) {
               return(0);
            }
            if (wid.p_value) {
              _wrap=tab_index;
              _wrap_wid=wid;
              return(0);
            }
         }
      }
      _wrap=tab_index;
      _wrap_wid=wid;
      return(0);
   }
   return(0);
}
static int _deprev_control2(int wid,int before)
{
   if (wid.p_object==OI_FORM || wid.p_object==OI_SSTAB_CONTAINER) return(0);
   // IF have closer tab index
   typeless tab_index=wid.MakeTabIndexString();
   if ((tab_index<before && (tab_index>_next || _next==''))) {
      _next=tab_index;
      _next_wid=wid;
      return(0);
   }
   // IF have closer tab index
   if ((tab_index>_wrap || _wrap=='')) {
      _wrap=tab_index;
      _wrap_wid=wid;
      return(0);
   }
   return(0);
}
/**
 * Switches to the previous control in a dialog box.  Identical to pressing 
 * the Shift+Tab key in a dialog box except text in text box and combo 
 * box controls are not selected.
 * 
 * @see _next_control
 * 
 * @appliesTo Text_Box, Check_Box, Command_Button, 
 * Radio_Button, Frame, Label, List_Box, Editor_Control, File_List_Box, 
 * Directory_List_Box, Hscroll_Bar, Vscroll_Bar, Combo_Box, Picture_Box, 
 * Image, Gauge, Spin
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void _prev_control()
{
   _next_control('P');
}
/**
 * Switches to the next control in a dialog box.  Identical to pressing the 
 * TAB key in a dialog box except text in text box and combo box controls is not 
 * selected.
 * 
 * @see _prev_control
 * 
 * @appliesTo Text_Box, Check_Box, Command_Button, 
 * Radio_Button, Frame, Label, List_Box, Editor_Control, File_List_Box, 
 * Directory_List_Box, Hscroll_Bar, Vscroll_Bar, Combo_Box, Picture_Box, 
 * Image, Gauge, Spin
 * 
 * @categories Miscellaneous_Functions
 * 
 */
void _next_control(_str direction="",int form_wid=0)
{
   _orig_wid=p_window_id;
   _wrap='';   // Window id of control to wrap to

   // generate the tab index string of our current wid
   typeless after=MakeTabIndexString();
   _next='';   // Window id of next control
   _next_wid='';
   _wrap_wid='';
   if (p_object!=OI_COMBO_BOX) {
      after=MakeTabIndexString();
   }

   // are we going to the next control or the previous?
   int index=0;
   if (upcase(direction)=='P') {
      index=find_index('_prev_control2',PROC_TYPE);
   } else {
      index=find_index('_next_control2',PROC_TYPE);
   }

   // use the currently active form if nothing is specified
   if (!form_wid) {
      form_wid=p_active_form;
   }
   if (form_wid.p_DockingArea && form_wid.p_parent && form_wid.p_parent.p_DockingArea==p_DockingArea) {
      // IF this form is tab-linked into a tabgroup, then do not start
      // looking for next tab index from the parent, since we only want
      // to find controls within this form.
      if( form_wid.p_parent.p_object!=OI_SSTAB_CONTAINER ||
          _tbTabGroupContainerWidFromWid(form_wid)!=form_wid.p_parent ) {

         form_wid=form_wid.p_parent.p_active_form;
      }
   }

   // run the _next_control or _prev_control on all the controls
   _for_each_control(form_wid,index,'',after);

   // we have found the next control, let's go to it
   if (_next!='') {
      p_window_id=_next_wid;_set_focus();
      return;
   }

   // there is no next control, so we wrap back around again
   if (_wrap!='') {
      p_window_id=_wrap_wid;_set_focus();
   }
}
void _deprev_control()
{
   _denext_control('P');
}
void _denext_control(_str direction='')
{
   //_orig_wid=p_window_id
   _wrap='';
   typeless after=MakeTabIndexString();
   //after=p_tab_index
   _next='';
   _next_wid='';
   _wrap_wid='';
   if (p_object!=OI_COMBO_BOX) {
      after=MakeTabIndexString();
   }
   typeless pfn=0;
   if (upcase(direction)=='P') {
      pfn=_deprev_control2;
   } else {
      pfn=_denext_control2;
   }
   _for_each_control(p_active_form,pfn,'',after);
   if (_next!='') {
      p_window_id=_next_wid;
      return;
   }
   if (_wrap!='') {
      p_window_id=_wrap_wid;
   }
}
/**
 * Switches to the next check box button state by setting the p_value 
 * property.  The next state depends on the <b>p_style</b> property.
 * 
 * Changes p_value to next value based on p_style and p_object
 * Currently this function only supports p_object==OI_CHECK_BOX
 * 
 * @appliesTo Check_Box
 * 
 * @categories Check_Box_Methods
 * 
 */
void _next_button_state()
{
    switch (p_style) {
    case PSCH_AUTO2STATE:
       p_value= (int)(!p_value);
       break;
    case PSCH_AUTO3STATEA:    /* Gray, check, uncheck. */
       switch (p_value) {
       case 0:
          p_value=2;
          break;
       case 1:
          p_value=0;
          break;
       case 2:
          p_value=1;
          break;
       }
       break;
    case PSCH_AUTO3STATEB:    /* Gray, uncheck, check */
       switch (p_value) {
       case 0:
          p_value=1;
          break;
       case 1:
          p_value=2;
          break;
       case 2:
          p_value=0;
          break;
       }
       break;
    }
}
void _ainh_dlg_manager.'A'-'Z','a'-'z'()
{
   typeless status=_dmDoLetter(last_event());
   if (status) {
      _beep();
   } else {
      _dmselect_text();
   }
}
void _dmDoDialogHotkey()
{
   _str event = last_event();
   _str id = '';
   parse event2name(event) with '[AM]-','r' id;
   int status = _dmDoLetter(id);
   if( status ) {
      // Try MDI child window if executing key from docked or auto-shown tool window
      if( (p_DockingArea || _tbIsAutoShownWid(p_window_id.p_active_form)) /*&& !_no_child_windows()*/ ) {
         if( eventtab_index(_default_keys,_mdi.p_child.p_mode_eventtab,event2index(event)) ) {
            //p_window_id = _mdi.p_child;
            //call_key(event);
            _mdi.p_child.call_event(_mdi.p_child,event,'W');
            return;
         }
      }
      p_active_form._menu_event(event);
   } else {
      _dmselect_text();
   }
}

/*
  Command+A  select_all     (does binding)
  Command+C  Copy-to-clipboard
  Command+V  Paste
  Command+X  Cut
  Command+W  Close window
  Command+Z  Undo


  Use Command+<letter> in dialogs for hot keys


  Text Box, Combo Box, Editor Control

*/

void _ainh_dlg_manager.'M-A'-'M-Z',A_A-A_Z,A_0-A_9()
{
   _dmDoDialogHotkey();
}

_ainh_dlg_manager.on_lost_focus()
{
   if (p_object==OI_TEXT_BOX || p_object==OI_COMBO_BOX) {
      if (!p_auto_select) return('');
      _set_sel(p_sel_start+p_sel_length);
   }
#if 0
   if(p_object==OI_TEXT_BOX) {
      if (!p_auto_select) return('');
      _set_sel(p_sel_start+p_sel_length)
   } else if(p_object==OI_COMBO_BOX && p_style!=PSCBO_NOEDIT){
      if (!p_auto_select) return('');
      p_cb_text_box._set_sel(p_sel_start+p_sel_length)
   }
#endif
}
static _dmselect_text()
{
   if(p_object==OI_TEXT_BOX) {
      if (!p_auto_select) return('');
      _set_sel(1,length(p_text)+1);
   } else if(p_object==OI_COMBO_BOX && p_style!=PSCBO_NOEDIT){
      if (!p_auto_select) return('');
      _set_sel(1,length(p_text)+1);
   }
}
typeless _ainh_dlg_manager."c-tab"()
{
   int parent;
   parent = p_window_id;
   if (p_object != OI_SSTAB) {
      parent = parent.p_parent;
outerloop:
      while (parent) {
         if (parent.p_object == OI_SSTAB) {
            break;
         }
         if (parent.p_object == OI_FORM || parent.p_object == OI_MDI_FORM) {
            // Search for Tab control on form.
            int first_wid=parent.p_child;
            if (!first_wid) {
               return("");
            }
            int wid=0;
            for (wid=first_wid;;) {
               if (wid.p_object==OI_SSTAB) {
                  parent=wid;
                  break;
               }
               wid=wid.p_next;
               if (wid==first_wid) {
                  return("");
               }
            }
            break outerloop;
         }
         parent = parent.p_parent;
      }
      if (!parent || parent.p_object != OI_SSTAB) return("");
   }
   p_window_id = parent;
   if (parent.p_tab_stop) {
      _set_focus();
   }
   call_event(p_window_id,RIGHT);
   return("");
}
typeless _ainh_dlg_manager."c-s-tab"()
{
   int parent;
   parent = p_window_id;
   if (p_object != OI_SSTAB) {
      parent = parent.p_parent;
      while (parent) {
         if (parent.p_object == OI_SSTAB) {
            break;
         }
         if (parent.p_object == OI_FORM || parent.p_object == OI_MDI_FORM) {
            return("");
         }
         parent = parent.p_parent;
      }
      if (parent.p_object != OI_SSTAB) return("");
   }
   p_window_id = parent;
   if (parent.p_tab_stop) {
      _set_focus();
   }
   call_event(p_window_id,LEFT);
   return("");
}
void _ainh_dlg_manager.tab()
{
   int orig_wid=p_window_id;
   _next_control();
   if (orig_wid!=p_window_id){
      _dmselect_text();
   }
}
_ainh_dlg_manager.s_tab()
{
   int orig_wid=p_window_id;
   _prev_control();
   if (orig_wid!=p_window_id){
      if(p_object==OI_TEXT_BOX) {
         if (!p_auto_select) return('');
         _set_sel(1,length(p_text)+1);
      } else if(p_object==OI_COMBO_BOX && p_style!=PSCBO_NOEDIT){
         if (!p_auto_select) return('');
         _set_sel(1,length(p_text)+1);
      }
   }
}
/*
      callback   may be index to function or function pointer
      arg(3)  Set to 'H' if hidden (p_visible=0) controls should be
              included in tree traversal.
      arg(4)..arg(7)   arguments to call back function
*/


/** 
 * Executes a callback function on a tree of controls where <i>wid</i> is the 
 * root window id of the tree.  <i>callback</i> is either the address of a 
 * function, the name of a global function, an index to a global function.  The 
 * <i>callback</i> function is called with the argument <i>arg1..arg4</i> 
 * arguments if specified.
 * <p>
 * If the window tree is NOT being edited (p_edit==0), disabled, invisible 
 * and controls clipped by the dialog box are skipped.  Specify the 'H' option 
 * if you do not want any controls skipped.  Set this to 'C' if 
 * you want to skip hidden controls, but not controls that have 
 * been clipped. 
 * <p>
 * If the window tree is being edited (p_edit==1), invisible 
 * (p_undo_visible==0) and controls clipped by the dialog box are skipped.  
 * Specify the 'H' option if you do not want any controls skipped.  It is likely 
 * that full undo (not just undelete) will be added to the dialog editor.  When 
 * this is done the p_undo_visible property will be removed.
 * 
 * @return  Returns 0 if callback function always returns 0.  Otherwise, the 
 * non-zero value (which can be anything) returned by the callback function is 
 * returned.
 * 
 * @categories Miscellaneous_Functions
 */
_str _for_each_control(int wid, typeless callback,
                       _str includeHiddenControls='',
                       typeless arg4='',typeless arg5='', 
                       typeless arg6='',typeless arg7='')
{
   if (upcase(includeHiddenControls)!='H') {
      if( (!wid.p_edit && !wid.p_visible && wid.p_object!=OI_SSTAB_CONTAINER) ||
            (wid.p_edit && !wid.p_undo_visible) ||
          (wid.p_edit && !wid.p_visible && wid.p_object==OI_SSTAB_CONTAINER)
        ){
         return(0);
      }
      int form_wid=wid.p_parent;
      if (includeHiddenControls != 'C' &&
          !wid.p_edit && wid.p_object!=OI_FORM &&
          (wid.p_y> _dy2ly(form_wid.p_xyscale_mode,form_wid.p_client_height) ||
           wid.p_x> _dx2lx(form_wid.p_xyscale_mode,form_wid.p_client_width)
          )
          ) {
         //message('h2 p_name='p_name);delay(300);clear_message
         return(0);
      }
      int temp_x=wid.p_x;
      int temp_y=wid.p_y;
      _map_xy(wid,form_wid,temp_x,temp_y,SM_TWIP);
      form_wid=wid.p_active_form;
      if (includeHiddenControls != 'C' &&
          !wid.p_edit && wid.p_object!=OI_FORM &&
          (wid.p_y> _dy2ly(form_wid.p_xyscale_mode,form_wid.p_client_height) ||
           wid.p_x> _dx2lx(form_wid.p_xyscale_mode,form_wid.p_client_width)
          )
          ) {
         //message('h2 p_name='p_name);delay(300);clear_message
         return(0);
      }
   }
   if(!_isfunptr(callback)){
      if (!isinteger(callback)) {
         typeless name=callback;
         callback=find_index(callback,PROC_TYPE|COMMAND_TYPE);
         if (!callback) {
            _message_box(nls("_sellist: Call back function '%s', not found",name));
            callback=0;
         }
      }
      callback=name_index2funptr(callback);
   }
   typeless status=(*callback)(wid,arg4,arg5,arg6,arg7);
   if (status) {
      return(status);
   }
   int tab_wids[]=null;
   if (wid.p_child && wid.p_object!=OI_COMBO_BOX) {
      int child=wid.p_child;
      status=LoopForEach(child,callback,includeHiddenControls,arg4,arg5,arg6,arg7);
      if (status) return(status);
   }
   return(0);
}

static int LoopForEach(int wid, typeless callback,
                       typeless includeHiddenControls='',
                       typeless arg4='',typeless arg5='', 
                       typeless arg6='',typeless arg7='')
{
   int first_child=wid;
   for (;wid;) {
      // Don't recurse forms.  Form can be wid of dialog box.
      // This indicates owner.
      if (wid.p_object!=OI_FORM || wid.p_DockingArea) {
         typeless status=_for_each_control(wid,callback,
                                           includeHiddenControls,
                                           arg4,arg5,arg6,arg7);
         if (status) {
            return(status);
         }
      }
      wid=wid.p_next;
      if (wid==first_child) break;
   }
   return(0);
}

/**
 * @return Returns an RGB color used by several Slick-C&reg; functions.  The 
 * <i>red</i>, <i>green</i>, and <i>blue</i> parameters are numbers 
 * between 0 and 255.   The return value is ((blue<<16)|(green<<8)|red).
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
int _rgb(int r, int g, int b)
{
   return((b<<16)|(g<<8)|r);
}

_str _event_handler(_str event)
{
   // inheritance is not check yet.
   int index=0;
   if (p_eventtab) {
      index=eventtab_index(p_eventtab,p_eventtab,event2index(event));
      if (index) {
         return(index);
      }
   }
   if (p_eventtab2) {
      index=eventtab_index(p_eventtab2,p_eventtab2,event2index(event));
      if (index) {
         return(index);
      }
   }
   int wid=p_active_form;
   if (wid.p_eventtab) {
      index=eventtab_index(wid.p_eventtab,wid.p_eventtab,event2index(event));
      if (index) {
         return(index);
      }
   }
   return(0);
}
//  This function is called when the editor doing a refresh and
//  about to set focus to a disabled window.  This function should
//  try to tab to the next control in the form or reenable forms.
_on_disabled()
{
   int wid=p_active_form;
   if (wid==_mdi || wid==_cmdline ||wid.p_mdi_child) {
      boolean form_disabled= !_mdi.p_enabled;
      _mdi.p_enabled=1;_mdi.p_visible=1;
      int first_wid=wid=_mdi.p_child;
      for (;;) {
         if (wid.p_enabled==0
             // (wid.p_visible==1 && (wid.p_window_flags & HIDE_WINDOW_OVERLAP))
             ) {
             form_disabled=1;
             wid.p_enabled=1;
             // Don't want to make mdi windows visible since windows seems to
             // to get confused.  In addition, in the future there may be user
             // defined hidden windows.
             //wid.p_visible=1;
         }
         wid=wid.p_next;
         if (wid==first_wid) break;
      }
      if (form_disabled) {
         _message_box("A macro has incorrectly disabled a form or died while a form was invisible.  The form has been enabled and made visible.");
      }
      return('');
   }
   if (!wid.p_visible || !wid.p_enabled) {
      _mdi.p_enabled=1;_mdi.p_visible=1;
      wid.p_enabled=1;wid.p_visible=1;
      _message_box("A macro has incorrectly disabled a form or died while a form was invisible.  The form has been enabled and made visible.");
   }
   _next_control();
}

#if 0
_str _dmvalidate2(wid)
{
   if (wid.p_object==OI_TEXT_BOX || wid.p_object==OI_COMBO_BOX) {
      switch (wid.p_validate_style) {
      case VS_INTEGER:
         if (!isinteger(wid.p_text)) {
            return(wid);
         }
         break;
      }
   }
   return(0);
}
_dmvalidate()
{
   wid=_for_each_control(p_active_form,'_dmvalidate2')
   if (!wid) {
      return(0);
   }
   //p_window_id=wid;refresh();
   switch (wid.p_validate_style) {
   case VS_INTEGER:
      if (!isinteger(wid.p_text)) {
         _message_box("Invalid integer")
      }
      break;
   }
   p_window_id=wid;refresh();

}
#endif

static int _morelargest;
_str _dmmorelargest(int wid, _str option='')
{
   if (wid.p_object==OI_FORM) {
      return(0);
   }
   if (lowcase(option)=='h') {
      int x=wid.p_x+wid.p_width;
      if (x>_morelargest) {
         _morelargest=x;
      }
   } else {
      int y=wid.p_y+wid.p_height;
      if (y>_morelargest) {
         _morelargest=y;
      }
   }
   return(0);
}
#define MORE_V_PAD 80
#define MORE_H_PAD 140


/**
 * Increases the size of an expandable dialog box.  An expandable 
 * dialog is a dialog box which changes its size to show more or 
 * less controls when a command button is pressed.  To create an 
 * expandable dialog box, create a dialog box in the dialog editor 
 * that is the full size of the dialog box when expanded.  Then add 
 * a command button at the lower right hand corner of the dialog box 
 * when it is NOT expanded.  The <b>p_caption</b> of the button must 
 * end with ">>" characters.  By default, the bottom edge of the dialog 
 * box is moved down so that the controls below the current button are 
 * not seen.  Specify the 'H' option if you want the right edge of the 
 * dialog moved to the right so that the controls to the right of the 
 * current button are not seen.  The ">>" characters in the button 
 * caption are changed to "<<" characters.
 * @example
 * <pre>
 * expandbutton.on_create()
 * {
 *     // Don't display the controls below this button.
 *      _dmless();
 * }
 * expandbutton.lbutton_up()
 * {
 *      // Toggle where the controls below this button are displayed.
 *      old_caption=p_caption;
 *      _dmmore();   // This function changes the >> to << in the caption
 *      p_caption=old_caption;
 *      p_enabled=0; // Disable this button so it can't be pressed.
 * }
 * </pre>
 * @see _dmmore
 * @see _dmmoreless
 * 
 * @appliesTo  Command_Button
 * @categories Command_Button_Methods
 */
void _dmmore(_str moveRightEdge='', _str padAmount='')
{
   int pad=0;
   int cx=0;
   int cy=0;
   _morelargest=0;
   int form_wid=p_active_form;
   _for_each_control(form_wid,'_dmmorelargest','H',moveRightEdge);
   if (lowcase(moveRightEdge)=='h') {
      pad=_lx2lx(SM_TWIP,form_wid.p_xyscale_mode,MORE_H_PAD);
      if (padAmount!='') pad=(int)padAmount;
      cx=form_wid.p_width-_dx2lx(form_wid.p_xyscale_mode,form_wid.p_client_width);
      form_wid.p_width=_morelargest+cx+pad;
   } else {
      pad=_ly2ly(SM_TWIP,form_wid.p_xyscale_mode,MORE_V_PAD);
      if (padAmount!='') pad=(int)padAmount;
      cy=form_wid.p_height-_dy2ly(form_wid.p_xyscale_mode,form_wid.p_client_height);
      form_wid.p_height=_morelargest+cy+pad;
   }
   _str before='';
   parse p_caption with before '>>|<<','r' ;
   p_caption=strip(before)' <<';
   p_active_form._show_entire_form();
}


/**
 * Decreases the size of an expandable dialog box.  An expandable dialog 
 * is a dialog box which changes its size to show more or less controls 
 * when a command button is pressed.  This function is usually called 
 * during an <b>on_create</b> event to display less of an expandable 
 * dialog box.  To create an expandable dialog box, create a dialog box 
 * in the dialog editor that is the full size of the dialog box when 
 * expanded.  Then add a command button at the lower right hand corner 
 * of the dialog box when it is NOT expanded.  The <b>p_caption</b> of 
 * the button must end with ">>" characters.  By default, the bottom 
 * edge of the dialog box is moved up so that the controls below the 
 * current button are not seen.  Specify the 'H' option if you want 
 * the right edge of the dialog moved to the left so that the controls 
 * to the right of the current button are not seen.  The "<<" characters 
 * in the button caption are changed to ">>" characters.
 * @example
 * <pre>
 * expandbutton.on_create()
 * {
 *     // Don't display the controls below this button.
 *      _dmless();
 * }
 * expandbutton.lbutton_up()
 * {
 *      // Toggle where the controls below this button are displayed.
 *      _dmmoreless();
 * }
 * </pre>
 * @see _dmmore
 * @see _dmmoreless
 * 
 * @appliesTo  Command_Button
 * @categories Command_Button_Methods
 */
void _dmless(_str moveRightEdge='', _str padAmount='')
{
   int pad=0;
   int cx=0;
   int cy=0;
   int form_wid=_get_form(p_window_id);
   if (lowcase(moveRightEdge)=='h') {
      pad=_lx2lx(SM_TWIP,form_wid.p_xyscale_mode,MORE_H_PAD);
      if (padAmount!='') pad=(int)padAmount;
      //cx=form_wid.p_width-_dx2lx(form_wid.p_xyscale_mode,form_wid.p_client_width);
      cx=form_wid._left_width();
      form_wid.p_width=p_x+p_width+cx+pad;
   } else {
      pad=_ly2ly(SM_TWIP,form_wid.p_xyscale_mode,MORE_V_PAD);
      if (padAmount!='') pad=(int)padAmount;
      cy=form_wid.p_height-_dy2ly(form_wid.p_xyscale_mode,form_wid.p_client_height);
      form_wid.p_height=p_y+p_height+cy+pad;
   }
   typeless before='';
   parse p_caption with before '>>|<<','r';
   p_caption=strip(before)' >>';
}


/**
 * Toggles the size of an expandable dialog box.  An expandable dialog 
 * is a dialog box which changes its size to show more or less controls 
 * when a command button is pressed.  To create an expandable dialog box, 
 * create a dialog box in the dialog editor that is the full size of the 
 * dialog box when expanded.  Then add a command button at the lower right 
 * hand corner of the dialog box when it is NOT expanded.  The <b>p_caption</b> 
 * of the button must end with ">>" characters.  By default, the bottom edge 
 * of the dialog box is moved down or up to display or not display the 
 * controls below the current button.  Specify the 'H' option if you want 
 * the right edge of the dialog moved right or left to display or not 
 * display the controls to the right of the current button.  The ">>" 
 * characters in the button caption the are changed from ">>" to "<<" 
 * or from "<<" to >>".  This function assumes that the dialog box needs 
 * to be expanded if the caption of the button contains ">>".  Otherwise 
 * the dialog box sized is reduced.
 * 
 * @example
 * <pre>
 * expandbutton.on_create()
 * {
 *     // Don't display the controls below this button.
 *      _dmless();
 * }
 * expandbutton.lbutton_up()
 * {
 *      // Toggle where the controls below this button are displayed.
 *      _dmmoreless();
 * }
 * </pre>
 * @see _dmmore
 * @see _dmless
 * 
 * @appliesTo  Command_Button
 * @categories Command_Button_Methods
 */
void _dmmoreless(_str moveRightEdge='', _str padAmount='')
{
   if (pos('>>',p_caption)) {
      _dmmore(moveRightEdge,padAmount);
   } else {
      _dmless(moveRightEdge,padAmount);
   }
}
/**
 * Saves x, y window position in the ".command" buffer.  This buffer is 
 * saved in the auto restore file ("vrestore.slk" by default) when auto 
 * restore is on.  The <b>_restore_form_xy</b> method may be used to 
 * restore the previous window position saved by this function.
 *  
 * @param form_name  (optional) form name to use to store position data
 *  
 * @appliesTo Form
 * 
 * @categories Form_Methods
 * 
 */ 
void _save_form_xy(_str form_name=null)
{
   if (form_name==null) {
      form_name=p_name;
   }
   int x=p_x;
   int y=p_y;
   typeless width=p_width;
   typeless height=p_height;
   if (p_edit) form_name=form_name' edit';
   width='';height='';
   if( p_border_style==BDS_SIZABLE ) {
      width=p_width;
      height=p_height;
   }
   int view_id=0;
   get_window_id(view_id);
   activate_window(VSWID_RETRIEVE);
   typeless p;
   _save_pos2(p);
   bottom();
   int status=search('^\@xy 'form_name'\:','-ri@');
   if (status) {
      insert_line('@xy 'form_name':'x' 'y' 'width' 'height);
   } else {
      replace_line('@xy 'form_name':'x' 'y' 'width' 'height);
   }
   _restore_pos2(p);
   activate_window(view_id);
}
/**
 * Restores x, y window position saved by the <b>_save_form_xy</b> 
 * function.
 *  
 * @param do_wh_only (optional) only do width and height, do not 
 *                   adjust the x and y position of form.
 * @param form_name  (optional) form name to use to store position data 
 * @param do_span    (optional) allow the form to span in width 
 *                   to an adjacent monitor.
 *  
 * @return Returns 0 if the old (x, y) position information is found.
 * 
 * @appliesTo Form
 * 
 * @categories Form_Methods
 * 
 */ 
int _restore_form_xy(boolean do_wh_only=false, _str form_name=null, boolean do_span=false)
{
   _str line='';
   if (form_name==null) {
      form_name=p_name;
   }
   typeless x=p_x;
   typeless y=p_y;
   typeless w=0;
   typeless h=0;
   if (p_edit) form_name=form_name' edit';
   int view_id=0;
   get_window_id(view_id);
   activate_window(VSWID_RETRIEVE);
   save_pos(auto p);
   bottom();
   int status=search('^\@xy 'form_name'\:','-ri@');
   if (!status) {
      get_line(line);
      if (do_wh_only) {
         parse line with ':' . . w h;
      } else {
         parse line with ':'x y w h;
      }
   }
   restore_pos(p);
   typeless junk='';
   typeless width='';
   typeless height='';
   activate_window(view_id);
   if (!status) {
      _get_window(junk,junk,width,height);
      /* 
         Getting the screen info for this window does not help much because it may get
         moved onto a different monitor later.
      */
      int screen_x=0, screen_y=0, screen_width=0, screen_height=0;
      _GetScreen(screen_x,screen_y,screen_width,screen_height);
      if( p_border_style==BDS_SIZABLE && isinteger(w) && isinteger(h) ) {
         width=w;
         height=h;
         _lxy2dxy(p_xyscale_mode,width,height);
         if (!do_span && width>screen_width) width=screen_width;
         if (!do_span && height>screen_height) height=screen_height;
         _dxy2lxy(p_xyscale_mode,width,height);
      }
      _move_window(x,y,width,height);
   }
   return(status);
}
#if 0
_isparent_control()
{
   switch (p_object) {
   case OI_PICTURE_BOX:
   case OI_FRAME:
   case OI_FORM:
      return(1);
   }
   return(0);
}
#endif
int _get_form(int wid)
{
   while (wid.p_parent && wid.p_object!=OI_FORM && wid.p_object!=OI_MDI_FORM){
      wid=wid.p_parent;
   }
   return(wid);
}

/**
 * Returns zero if the current window or any of its parents are 
 * disabled or invisible.   Otherwise, 1 is returned.  Checking stops when a form is reached.  A typical use of this function is to check if it is reasonable to tab to a control (one should also check if the control fits within the bounds of the dialog box).
 * 
 * @see p_enabled
 * @see p_visible
 * 
 * @appliesTo  All_Window_Objects
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Edit_Window_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, Label_Methods, List_Box_Methods, MDI_Window_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 */
boolean _enabled()
{
   int wid=p_window_id;
   for (;;) {
      if (!wid.p_enabled || !wid.p_visible) {
         return false;
      }
      if (!wid.p_parent || wid.p_object==OI_FORM ||
           wid.p_object==OI_MDI_FORM) {
         return true;
      }
      wid=wid.p_parent;
   }
}

void _set_value(int value)
{
   p_value=value;
   if (p_object==OI_GAUGE) {
      call_event(p_window_id,ON_CHANGE);
   } else {
      call_event(p_window_id,LBUTTON_UP);
   }
}


/** 
 * Enables or disables forms specified.  For simple, modal dialog boxes, 
 * you should not use this function.  If you want to write a loop which 
 * does some process and have a dialog box show the status of the process 
 * and allow canceling, you should use this function.
 * 
 * @param enable  If non-zero, forms are enabled.
 * @param skip_wid   Form with window id equal to this value will not be effected.
 * @param wid_list   Specific space delimited window ids of the forms to be 
 *    enabled or disabled.  Usually, this variable is the list of window ids 
 *    to be reenabled.  The list of windows disabled by this function is 
 *    returned by this function.
 * 
 * @return  '' is returned if the <i>enable</i> argument was non-zero.  
 * Otherwise, a space delimited list of the window ids that were disabled is returned.
 * @example
 * <pre>
 * #include "slick.sh"
 * static  typeless gcancel
 * _command test()
 * {
 *     // Show the form modeless so there is no modal wait
 *     form1_wid=show('form1');
 *     disabled_wid_list=_enable_non_modal_forms(0,form1_wid);
 *     gcancel=0;
 *     for (;;) {
 *           // Read mouse, key, and all other events until none are left
 *           // or until the variable gcancel  becomes true.
 *           process_events(gcancel);
 *           if (gcancel) break;
 *     }
 *     _enable_non_modal_forms(1,0,disabled_wid_list);
 *     form1_wid._delete_window();
 * }
 * defeventtab form1;
 * cancel.lbutton_up()
 * {
 *      gcancel=1;
 * }
 * </pre>
 * @categories Form_Functions
 */
_str _enable_non_modal_forms(boolean value,int skip_wid,_str wid_list='')
{
   typeless wid='';
   if (value) {
      for (;;) {
         parse wid_list with wid wid_list;
         if (wid=='') return('');
         if (wid!=skip_wid && _iswindow_valid(wid) && (wid.p_object==OI_FORM || wid.p_object==OI_MDI_FORM) && !wid.p_enabled &&
             !wid.p_edit && !wid.p_modal && !wid.p_mdi_child && !wid.p_DockingArea
            ) {
            wid.p_enabled=1;
         }
      }
   }
   int i,last=_last_window_id();
   wid_list='';
   for (i=1;i<=last;++i) {
      if (i!=skip_wid && _iswindow_valid(i) && (i.p_object==OI_FORM || i.p_object==OI_MDI_FORM) && i.p_enabled &&
          !i.p_edit&& !i.p_modal && !i.p_mdi_child && !i.p_DockingArea
         ) {
         i.p_enabled=0;
         wid_list=wid_list' 'i;
      }
   }
   return(wid_list);

}
int _left_width()
{
   int buf_wid=p_window_id;
   int buf_x= buf_wid.p_x;
   int buf_y= buf_wid.p_y;
   /*if (!buf_wid.p_xyparent) {
      buf_wid._GetScreen(screen_x,screen_y,screen_width,screen_height);
      buf_x+=screen_x*_twips_per_pixel_x();
      buf_y+=screen_y*_twips_per_pixel_y();
   } */
   _map_xy(buf_wid.p_xyparent,0,buf_x,buf_y,buf_wid.p_xyscale_mode);
   int client_x=0;
   int client_y=0;
   _map_xy(buf_wid,0,client_x,client_y,buf_wid.p_xyscale_mode);
   int left_border_width=client_x-buf_x;
   return(left_border_width);
}
/**
 * Returns height in <b>p_xyscale_mode</b> of the top border of the 
 * window.
 * 
 * @see _bottom_height
 * 
 * @appliesTo Form
 * 
 * @categories Form_Methods, Miscellaneous_Functions
 * 
 */ 
int _top_height()
{
   int buf_wid=p_window_id;
   int buf_x= buf_wid.p_x;
   int buf_y= buf_wid.p_y;
   /*if (!buf_wid.p_xyparent) {
      buf_wid._GetScreen(screen_x,screen_y,screen_width,screen_height);
      buf_x+=screen_x*_twips_per_pixel_x();
      buf_y+=screen_y*_twips_per_pixel_y();
   } */
   _map_xy(buf_wid.p_xyparent,0,buf_x,buf_y,buf_wid.p_xyscale_mode);
   int client_x=0;
   int client_y=0;
   _map_xy(buf_wid,0,client_x,client_y,buf_wid.p_xyscale_mode);
   int caption_height=client_y-buf_y;
   return(caption_height);
}

/**
 * Returns height in <b>p_xyscale_mode</b> of the bottom border of the window.
 * 
 * @appliesTo Form
 * @return the height of the window
 * @see _top_height
 * @categories Form_Methods, Miscellaneous_Functions
 */
int _bottom_height()
{
   int buf_wid=p_window_id;
   int border_height=_ly2dy(p_xyscale_mode,p_height)-p_client_height;
   return(_dy2ly(p_xyscale_mode,border_height)-_top_height());
}


/**
 * Gets width, height in <b>p_xyscale_mode</b> of the all contained child controls.
 * 
 * @appliesTo Form
 * @categories Form_Methods, Miscellaneous_Functions
 */
void _get_child_extents(int wid, int& w, int& h, boolean do_visible_controls)
{
   w = 0;
   h = 0;
   int child = wid.p_child;
   int first = child;
   while (child) {
      if (!do_visible_controls || child.p_visible) {
         int x = child.p_x + child.p_width;
         if (x > w) {
            w = x;
         }
         int y = child.p_y + child.p_height;
         if (y > h) {
            h = y;
         }
      }
      child = child.p_next;
      if (child == first) break;
   }
}


/**
 * Loads a form as a child into another form, without the form
 * frame.
 * 
 * @param form_name     Form name to be loaded.
 * @param parent_wid    Parent window to insert form.
 * @param options       Load options.
 * <dl><dt><b>''</b><dd>Default.
 * <dt><b>'H'</b><dd>Hidden.
 * </dl>
 * 
 * @appliesTo Form
 * @categories Form_Methods
 * @return window id of created subform
 */
int _load_subform(_str form_name, int parent_wid, _str options = '')
{
   if (!_iswindow_valid(parent_wid)) {
      return (0);
   }
   int orig_wid; get_window_id(orig_wid);
   int index = find_index(form_name, oi2type(OI_FORM));
   if (index == 0) {
      return (0);
   }
   int wid = _load_template(index, parent_wid, options:+'PNS');
   activate_window(orig_wid);
   return (wid);
}

