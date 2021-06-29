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
#region Import
#include "slick.sh"
#include "toolbar.sh"
#include "pip.sh"
#import "bind.e"
#import "dlgman.e"
#import "files.e"
#import "menu.e"
#import "recmacro.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbcontrols.e"
#import "tbprops.e"
#require "sc/controls/RubberBand.e"
#require "se/util/MousePointerGuard.e"
#require "se/ui/mainwindow.e"
#endregion
//
//    User level 2 inheritance for PICTURE BOX
//

static const MESSAGE_DIFF_X= 60;  /* twips */
static const MESSAGE_DIFF_Y= 60;  /* twips */

void _BBTimerCallback();
defeventtab _ul2_picture;
static int BBTimerHandle=-1;  // When >=0 this is the handle for the
                              // popup message timer
static int LastWindowButton=0; // Window id of button whose message we
                               //  are currently displaying
static int gLastMouseInWindow=0;
//static int debug_count=0;
static const BBTIMER_INTERVAL= 100;  // 1/10 second
definit()
{
   if (arg(1)!='L') {
      BBTimerHandle=-1;
      LastWindowButton=0;
      gLastMouseInWindow=0;
      //debug_count=0;
   }
}
static void _RestoreFlatButton()
{
   if (_iswindow_valid(gLastMouseInWindow) &&
       gLastMouseInWindow.p_object==OI_IMAGE &&
       (gLastMouseInWindow.p_style==PSPIC_FLAT_BUTTON ||
        gLastMouseInWindow.p_style==PSPIC_FLAT_MONO_BUTTON ||
        gLastMouseInWindow.p_style==PSPIC_HIGHLIGHTED_BUTTON ||
        gLastMouseInWindow.p_style==PSPIC_SPLIT_HIGHLIGHTED_BUTTON) &&
       gLastMouseInWindow.p_value==2) {

      gLastMouseInWindow.p_value=0;
   }
   gLastMouseInWindow=0;
}
void _KillToolButtonTimer()
{
   if (BBTimerHandle>=0) {
      _kill_timer(BBTimerHandle);
      BBTimerHandle=-1;
      LastWindowButton=0;
      _RestoreFlatButton();
   }
}
_ul2_picture.mouse_move()
{
   if (p_message != null && p_message != "" && isinteger(p_message) && _first_char(p_message)=='-' && (int)p_message < 0) {
      p_message = get_message((int)p_message);
   }
   if (!_ImageIsSpace() && p_message!='' &&
       !_tbInDragDropCtlMode() &&
       _AppActive()
       ) {
      typeless x=0, y=0;
      parse p_user2 with x y ;
      if (x!='') {
         new_x := new_y := 0;
         mou_get_xy(new_x,new_y);
         _dxy2lxy(SM_TWIP,new_x,new_y);
         _dxy2lxy(SM_TWIP,x,y);
         if (abs(new_x-x)<MESSAGE_DIFF_X && abs(new_y-y)<MESSAGE_DIFF_Y) {
            return('');
         }
         p_user2='';
      }
      //p_enabled=true;
      if( p_object == OI_IMAGE && p_value != 2 &&
          (p_style == PSPIC_FLAT_BUTTON ||
           p_style == PSPIC_FLAT_MONO_BUTTON ||
           p_style == PSPIC_HIGHLIGHTED_BUTTON ||
           p_style == PSPIC_SPLIT_HIGHLIGHTED_BUTTON)
         ) {
         if (p_window_id!=gLastMouseInWindow) {
            _RestoreFlatButton();
         }
         if (p_enabled) {
            p_value=2;
         }
         gLastMouseInWindow=p_window_id;
      }
      ConsiderBBWin(p_active_form,p_window_id);
   }
}
static void ConsiderBBWin(int form_wid,int wid)
{
   if (BBTimerHandle<0) {
      BBTimerHandle=_set_timer(BBTIMER_INTERVAL,_BBTimerCallback,form_wid' 'wid);
   }
}

static int GetWid(int form_wid,int MouX,int MouY)
{
   button := 0;
   int wid=form_wid.p_child;
   int first=wid;
   if (!wid) {
      return(0);
   }
   for (;;) {
      if ((MouX>=wid.p_x && MouX<=wid.p_x_extent)
        &&(MouY>=wid.p_y && MouY<=wid.p_y_extent)
        && (
            (wid.p_object==OI_IMAGE && wid.p_visible && !wid._ImageIsSpace()) ||
            (wid.p_object==OI_COMBO_BOX && wid.p_visible && wid.p_message!="")
            )
        )  {
         button=wid;
         break;
      }
      if (wid.p_child && wid.p_visible) {
         int new_moux=MouX;
         int new_mouy=MouY;
         _map_xy(form_wid,wid,new_moux,new_mouy,SM_TWIP);
         //sticky_message("name="wid.p_name" new_x,new_y="new_moux","new_mouy);
         button=GetWid(wid,new_moux,new_mouy);
         if (button) return(button);
      }
      wid=wid.p_next;
      if (wid==first) break;
   }
   return(button);
}

// Desc:  Check to see if all ancestors of specified window are visible.
// Retn:  1 for all ancestor visible, 0 for not.
static int isAllAncestorVisible(int mywid)
{
   int parent;
   parent = mywid.p_parent;
   while (parent) {
      if (!parent.p_visible) return( 0 );
      if (parent.p_object == OI_FORM || parent.p_object == OI_MDI_FORM) break;
      parent = parent.p_parent;
   }
   return( 1 );
}
bool _AppActive()
{
   if (!_AppHasFocus()) {
      return(false);
   }
   return(true);
}
static int debug_count;


/**
 * Return the button wid that has already been executed for the 
 * current form since the last time mouse pointer was inside 
 * form. '' is returned if no wid has been set. Pass non-null 
 * for <code>newValue</code> to set value.
 * 
 * @param newValue 
 * 
 * @return typeless
 */
static typeless lastExecutedWid(typeless newValue=null)
{
   if( newValue != null ) {
      _SetDialogInfoHt('lastExecutedWid', newValue, 0, true);
   }
   typeless val = _GetDialogInfoHt('lastExecutedWid', 0, true);
   val = val == null ? '' : val;
   return val;
}

/*
    This function is global only so that this module can be reloaded
    without changing the address of the function.
*/
void _BBTimerCallback()
{
   typeless form_wid=0, wid=0;
   parse arg(1) with form_wid wid;
   if (LastWindowButton=='') LastWindowButton=0;
   MouX := MouY := 0;
   mou_get_xy(MouX,MouY);

   //++debug_count;message("debug_count="debug_count);
   if (!_iswindow_valid(form_wid) || form_wid.p_object!=OI_FORM
       || !_AppActive()
       ) {
      if (!_AppActive() && _iswindow_valid(form_wid)) {
         //_beep();
         //form_wid.p_user2="";
         form_wid.lastExecutedWid('');
      }

      // The form was closed
      _kill_timer(BBTimerHandle);
      BBTimerHandle=-1;
      LastWindowButton=0;
      _RestoreFlatButton();
      return;
   }
   _map_xy(0,form_wid,MouX,MouY);
   MouX*=_twips_per_pixel_x();
   MouY*=_twips_per_pixel_y();
   CurrentWid := GetWid(form_wid,MouX,MouY);
   if (CurrentWid && CurrentWid.p_message=="") CurrentWid=0;

   //message((++debug_count)' form_wid.p_name='form_wid.p_name);
   // IF we are no longer in a button
   if (!CurrentWid) {
      // IF we are still inside the form.
      if (MouX>=0 && MouX<form_wid.p_width &&
          MouY>=0 && MouY<form_wid.p_height
         ) {
         _RestoreFlatButton();
         LastWindowButton=0;
         return;
      }
      //_beep();
      //form_wid.p_user2="";
      form_wid.lastExecutedWid('');
      _KillToolButtonTimer();
      return;
   }
   //++debug_count;message("debug_count="debug_count" u2="form_wid.lastExecutedWid());
   // Enforce that all tooltip's windown ancestors must be visible in
   // order for tooltip to be visible:
   if (!isAllAncestorVisible(CurrentWid)) {
      _KillToolButtonTimer();
      return;
   }
   if (CurrentWid.p_object == OI_IMAGE && CurrentWid.p_value != 2 &&
       (CurrentWid.p_style == PSPIC_FLAT_BUTTON ||
        CurrentWid.p_style == PSPIC_FLAT_MONO_BUTTON ||
        CurrentWid.p_style == PSPIC_HIGHLIGHTED_BUTTON ||
        CurrentWid.p_style == PSPIC_SPLIT_HIGHLIGHTED_BUTTON)
      ) {
      if (CurrentWid!=gLastMouseInWindow) {
         _RestoreFlatButton();
      }
      if (CurrentWid.p_enabled) {
         CurrentWid.p_value=2;
      }
      gLastMouseInWindow=CurrentWid;
   }

   // IF the message is already set for this window
   if( CurrentWid == LastWindowButton ) {
      return;
   }

   // IF no buttons have been executed OR
   //    same timer window AND we are not in the executed window
   if( form_wid.lastExecutedWid() == '' ||
      (CurrentWid == wid && form_wid.lastExecutedWid() != CurrentWid) ) {

      //form_wid.p_user2 = "";
      form_wid.lastExecutedWid('');
      bindings := "";
      _str msg = CurrentWid.p_message;
      child_wid:=_MDIGetActiveMDIChild();
      if (!child_wid) child_wid=_mdi.p_child;
      if( CurrentWid.p_object != OI_COMBO_BOX && CurrentWid.p_command != "" ) {
         first_word := "";
         parse CurrentWid.p_command with first_word .;
         bindings = child_wid._where_is(first_word);
      } else {
         bindings = "";
      }
      if( pos('emacs',def_keys,1,'i') ) {
         parse bindings with bindings ',';
      } else {
         first := "";
         rest := "";
         parse bindings with first ',' rest;
         rest = strip(rest);
         if( rest != '' && pos(' ',first) ) {
            bindings = rest;
         }
      }
      if( bindings != "" ) {
         msg :+= " (":+bindings")";
      }

      if( msg != CurrentWid.p_message ) {
         //say('_BBTimerCallback : msg='msg);
         CurrentWid._set_tooltip(msg);
      }

      LastWindowButton = CurrentWid;
      return;
   }
   // IF we are not in the button we were timing
   if( CurrentWid != wid ) {
      //_beep();
      _kill_timer(BBTimerHandle);
      BBTimerHandle=_set_timer(BBTIMER_INTERVAL,_BBTimerCallback,form_wid' 'CurrentWid);
   }
}

/** 
 * @return Returns the command name parsed from the front of the  
 * <i>cmdline</i> argument string.
 *
 * @example
 * <pre>
 * _get_cmdname("/test")   =="/"
 * _get_cmdname("sb 1") =="sb"
 * </pre>
 *
 * @categories Miscellaneous_Functions
 * 
 */
_str _get_cmdname(_str command)
{
   cmdname := args := "";
   first_ch := substr(command,1,1);
   if (isalpha(first_ch) || first_ch=='$') {
      parse command with cmdname args ;
   } else {
      cmdname=substr(command,1,1);
   }
   return(cmdname);
}
void _tbCommand()
{
   child_wid:=_MDIGetActiveMDIChild();
   if (!child_wid) child_wid=_mdi.p_child;
   //messageNwait("_on_select_execute: l="name_name(last_index('','C')));
   //messageNwait("_on_select_execute: p="name_name(prev_index('','C')));

   //command=p_command;
   command := "";
   typeless status=_ParseUserCommand(command,p_command,child_wid);
   if (status) return;

   // save which toolbar gave us this
   tbParent := p_parent;

   _str cmdname=_get_cmdname(command);
   index := find_index(cmdname,COMMAND_TYPE);
   if (index) {
      prevcmd_index := prev_index('','C');
      lastcmd_index := last_index('','C');
      CMDUI cmdui;
      cmdui.menu_handle=0;
      cmdui.button_wid=p_window_id;
      target_wid := 0;
      if (child_wid.p_window_flags & HIDE_WINDOW_OVERLAP) {
         target_wid=0;
      } else {
         target_wid=child_wid;
      }
      _OnUpdateInit(cmdui,target_wid);
      int mfflags=_OnUpdate(cmdui,target_wid,command);
      if ((mfflags&MF_GRAYED)) {
         _beep();
         return;
      }

      // log this guy in the pip 
      if (_pip_on) {
         info := '';
         if (tbParent) {
            info = tbParent.p_name;
         }
         _pip_log_command_event(command, PCLM_TOOLBAR_BUTTON, info);
      }

      typeless flags="";
      parse name_info(index) with ',' flags;
      if (flags=='') flags=0;
#if 0
      if (_mdi.p_child.p_window_flags & HIDE_WINDOW_OVERLAP) {
         if (
             (flags & VSARG2_REQUIRES_MDI_EDITORCTL)
             ) {
            _message_box(nls("Command '%s' not allowed when no edit windows active",command));
            return;
         }
      } else if(_mdi.p_child.p_window_state=='I'){
         if (!(flags & VSARG2_ICON) &&
             (flags & VSARG2_REQUIRES_MDI_EDITORCTL)
             ) {
            _message_box(nls("Command '%s' not allowed when current window is an icon",command));
            return;
         }
      } else if(_mdi.p_child._QReadOnly()) {
         if (!(flags & VSARG2_READ_ONLY)) {
            _message_box(nls("Command '%s' not allowed in read only mode",command));
            return;
         }
      }
#endif

      wid := p_window_id;
      //int child_wid=_MDIGetActiveMDIChild();
      p_window_id=child_wid;
#if 0
      /*
         Clark:  A user called in and indicated
         that clicking on the "save" toolbar button exited the scroll position.  Here's
         the offending code.  It appears that we don't need this code.  Code inside
         _on_select_execute() checks the VSARG2_NOEXIT_SCROLL takes care of this
         correctly.
      */
      if (!_no_child_windows()) {
         if (p_scroll_left_edge>=0) {
            p_scroll_left_edge= -1;
         }
         _undo('s');
      }
#endif
      x := y := 0;
      mou_get_xy(x,y);
      wid.p_user2=x' 'y;
      _macro('m',_macro('s'));
      /*
         Set focus can change the _MDICurrent(). Here
         we don't set focus if that is going to happen unless
         the command operates on an editor control.

         This fixes a problem where clicking on the "Open"
         tool bar button activates the wrong Open tool window.

      */
      if (p_window_id==child_wid || (flags&VSARG2_REQUIRES_EDITORCTL)) {
         _set_focus();
      }
      prev_index(prevcmd_index,'C');
      last_index(lastcmd_index,'C');
      _on_select_execute(command,flags);
      //messageNwait("_on_select_execute: out l="name_name(last_index('','C')));
   } else {
      param2 := 'a';
      // Assume this is an external program
      _macro('m',_macro('s'));
      _macro_call('execute',command,param2);
      execute(command,param2);
   }
}
bool _ImageIsSpace()
{
   return(p_object==OI_IMAGE && p_caption=="" && !p_picture && p_style!=PSPIC_SIZEHORZ && p_style!=PSPIC_SIZEVERT);
}
void _ul2_picture.lbutton_down(int reason=0)
{
   if (_tbInDragDropCtlMode()) {
      _tbDragDropCtl();
      return;
   }
   if (_ImageIsSpace()) {
      // Call user level one inheritance of form
      if (p_active_form.p_eventtab) {
         call_event(p_active_form.p_eventtab,LBUTTON_DOWN,'e');
      } else if (p_active_form.p_eventtab2) {
         // Call user level two inheritance of form
         call_event(p_active_form.p_eventtab2,LBUTTON_DOWN,'e');
      }
      return;
   }
   if (p_max_click==MC_SINGLE) {
      get_event('B');
   }
   switch (p_style) {
   case PSPIC_DEFAULT:
      bm_name := _strip_filename(name_name(p_picture), 'pe');
      if (length(p_command) == 0 && length(p_help) > 0 && _file_eq(bm_name,"bbvsehelp")) {
         _dmhelp2(p_help);
      }
      break;
   case PSPIC_AUTO_CHECK:
      ++p_value;
      if (p_value>=p_Nofstates) {
         p_value=0;
      }
      call_event(p_window_id,LBUTTON_UP);
      break;
   case PSPIC_PUSH_BUTTON:
   case PSPIC_SPLIT_PUSH_BUTTON:
   case PSPIC_AUTO_BUTTON:
   case PSPIC_BUTTON:
   case PSPIC_SPLIT_BUTTON:
      //message("h1 l="name_name(last_index('','C')));delay(200);clear_message();
      if(_push_button(p_Nofstates)){
         if (p_command!='') {
            // Indicate that we executed a command
            //p_active_form.p_user2=p_window_id;
            p_active_form.lastExecutedWid(p_window_id);
            _tbCommand();
            return;
         }
         if( p_style == PSPIC_SPLIT_PUSH_BUTTON || p_style == PSPIC_SPLIT_BUTTON ) {
            call_event(reason,p_window_id,LBUTTON_UP,'w');
         } else {
            call_event(p_window_id,LBUTTON_UP,'w');
         }
      }
      break;
   case PSPIC_FLAT_BUTTON:
   case PSPIC_FLAT_MONO_BUTTON:
   case PSPIC_HIGHLIGHTED_BUTTON:
   case PSPIC_SPLIT_HIGHLIGHTED_BUTTON:
      //message("h1 l="name_name(last_index('','C')));delay(200);clear_message();
      if(_flat_button()){
         if (p_command!='') {
            // Indicate that we executed a command
            //p_active_form.p_user2=p_window_id;
            p_active_form.lastExecutedWid(p_window_id);
            _tbCommand();
            return;
         }
         if( p_style == PSPIC_SPLIT_HIGHLIGHTED_BUTTON ) {
            call_event(reason,p_window_id,LBUTTON_UP,'w');
         } else {
            call_event(p_window_id,LBUTTON_UP,'w');
         }
      }
      break;
   }
}

static _str _on_select_execute(_str command,int flags)
{
   /* IF mark is persistent AND mark is begin/end sytle mark */
   typeless status=0;
   if ( _select_type('','U')=='P' && _select_type('','S')=='E' ) {
      _macro_call('execute',command,'');
      status=execute(command,'');
      return(status);
   }
   def_persistent_select=upcase(def_persistent_select);
   if ( def_persistent_select=='Y' ) {
      /* set_eventtab_index  _default_keys,event2index(on_select),0 */
      _macro_call('execute',command,'');
      status=execute(command,'');
      return(status);
   }
   if ( flags=='' ) {
      flags=0;
   }
   if ( (flags & VSARG2_MARK) ||
        !(flags & VSARG2_REQUIRES_MDI_EDITORCTL)
         ) {
      _macro_call('execute',command,'');
      status=execute(command,'');
   } else {
      if ( _select_type('','u')=='' ) {
         _macro_call('_deselect');
         _deselect();
      }
      _macro_call('execute',command,'');
      status=execute(command,'');
   }
   return(status);
}
//
//    User level 2 inheritance for IMAGE control
//
defeventtab _ul2_imageb;
_ul2_imageb.mouse_move()
{
   call_event(defeventtab _ul2_picture,mouse_move,'e');
}
_ul2_imageb.lbutton_down(int reason=0)
{
   if( !p_enabled ) {
      return('');
   }
   switch( p_style ) {
   case PSPIC_SPLIT_PUSH_BUTTON:
   case PSPIC_SPLIT_BUTTON:
   case PSPIC_SPLIT_HIGHLIGHTED_BUTTON:
      call_event(reason,defeventtab _ul2_picture,LBUTTON_DOWN,'e');
      break;
   default:
      call_event(defeventtab _ul2_picture,LBUTTON_DOWN,'e');
   }
}

/**
 * Called after an <b>lbutton_down</b> event to give the effect of 
 * pushing a command button.  The <i>p_value</i> property is 
 * temporarily set to the next state.  You can specify the 
 * <i>new_value</i> to select the temporary button state.  This function 
 * is typically called for 2 state pictures (<b>p_Nofstates</b>==2).  You 
 * can specify a different number of states than the p_Nofstates property 
 * by specifying the <i>Nofstates</i> parameter.
 * 
 * @return Returns 1 if the button is pressed and released while the mouse pointer 
 * was within the window.  Otherwise, 0 is returned.
 * 
 * @appliesTo Picture_Box, Image
 * 
 * @categories Image_Methods, Picture_Box_Methods
 * 
 */ 
bool _push_button(typeless Nofstates='', typeless new_value='')
{
   if (!p_enabled) {
      _beep();
      return(false);
   }
   _KillToolButtonTimer();
   if (p_object==OI_IMAGE && (p_caption!="" || p_style==PSPIC_BUTTON)) {
      Nofstates=2;
   }
   if (Nofstates=='') {
      Nofstates=p_Nofstates;
   }
   if (Nofstates<=1) {
      Nofstates=2;
   }
   typeless old_value=p_value;
   if (new_value=='') {
      new_value=old_value=p_value;
      ++new_value;
      if (new_value>=Nofstates) {
         new_value=0;
      }
   } else {
      old_value=p_value;
   }
   p_value=new_value;

   typeless event="";
   mou_mode(1);
   mou_capture();
   done := false;
   for (;;) {
      event=get_event();
      switch (event) {
      case MOUSE_MOVE:
         int mx=mou_last_x('m');
         int my=mou_last_y('m');
         x := y := width := height := 0;
         _get_window(x,y,width,height);
         if (mx>=0 && my>=0 && mx<width && my<height) {
            if (p_value!=new_value) {
               p_value=new_value;
            }
         } else {
            if (p_value!=old_value) {
               p_value=old_value;
            }
         }
         break;
      case LBUTTON_UP:
      case ESC:
         done=true;
      }
      if (done) break;
   }
   mou_mode(0);
   mou_release();
   do_event := p_value==new_value;
   p_value=old_value;
   return(do_event);
}
// Supports picture and image controls
_str _flat_button(...)
{
   if (!p_enabled) {
      _beep();
      return(false);
   }
   _KillToolButtonTimer();

   p_value=1;

   typeless event="";
   mou_mode(1);
   mou_capture();
   done := false;
   for (;;) {
      event=get_event();
      switch (event) {
      case MOUSE_MOVE:
         int mx=mou_last_x('m');
         int my=mou_last_y('m');
         x := y := width := height := 0;
         _get_window(x,y,width,height);
         if (mx>=0 && my>=0 && mx<width && my<height) {
            if (p_value!=1) {
               p_value=1;
            }
         } else {
            if (p_value!=2) {
               p_value=2;
            }
         }
         break;
      case LBUTTON_UP:
      case ESC:
         done=true;
      }
      if (done) break;
   }
   mou_mode(0);
   mou_release();
   do_event := p_value==1;
   p_value=0;
   return(do_event);
}

defeventtab _ul2_imagebmenu;
void _ul2_imagebmenu.lbutton_down()
{
   if (!p_enabled) return;
   menu_name := "";
   index := 0;
   menu_handle := 0;
   x := y := 0;
   flags := 0;
   //message("h1 l="name_name(last_index('','C')));delay(200);clear_message();
   if (_isWindows()) {
      p_value=(int)(!p_value);
   } else if (!_push_button(p_Nofstates)) {
      return;
   }
   if (p_command!='') {
      menu_name=p_command;
      index=find_index(menu_name,oi2type(OI_MENU));
      if (index) {
         wid := p_window_id;
         menu_handle=p_active_form._menu_load(index,'P');

         x=p_x+p_width;y=p_y;
         _lxy2dxy(SM_TWIP,x,y);
         _map_xy(p_xyparent,0,x,y);
         call_list('_on_popup2_',translate(menu_name,'_','-'),menu_handle);
         if (_isEditorCtl()) {
            call_list('_on_popup_',translate(menu_name,'_','-'),menu_handle);
         }
         flags=VPM_LEFTALIGN|VPM_LEFTBUTTON|VPM_RIGHTBUTTON;
         _menu_show(menu_handle,flags,x,y);
         _menu_destroy(menu_handle);
         // use the window id - focus may have changed while the menu was up
         if (_isWindows()) {
            wid.p_value=(int)(!wid.p_value);
         }
      }
   }
}
   static const PIC_PARSE_CHAR= "%";
int _ParseUserCommand(_str &result,_str command,int child_wid)
{
   if (child_wid.p_window_flags && HIDE_WINDOW_OVERLAP) {
      child_wid=0;
   }
   typeless status=0;
   s := "";
   ch := "";
   j := 1;
   len := 0;
   for (;;) {
     j=pos(PIC_PARSE_CHAR,command,j);
     if ( ! j ) {
        result=command;
        return(0);
     }
     ch=upcase(substr(command,j+1,1));
     len=2;

     /*
         Important:  If you add options which require
         an edit window here, you must also modify
         the code in _OnUpdate.
     */
     if ( ch=='F' ) {
        if (!child_wid) {
           _message_box("This command requires an edit window");
           return(1);
        }
        if (child_wid.p_modify && child_wid._need_to_save()) {
           status=child_wid.save("",SV_RETRYSAVE);
           if (status) return(status);
        }
        s=child_wid.p_buf_name;
     } else if ( ch=='L' ) {
        if (!child_wid) {
           _message_box("This command requires an edit window");
           return(1);
        }
        s=child_wid.p_line;
     } else if ( ch=='C' ) {
        if (!child_wid) {
           _message_box("This command requires an edit window");
           return(1);
        }
        junk := 0;
        s=child_wid.cur_word(junk);
     } else if ( ch==PIC_PARSE_CHAR ) {
       s=PIC_PARSE_CHAR;
     } else {
       len=1;
       s='';
     }
     command=substr(command,1,j-1):+s:+substr(command,j+len);
     j += length(s);
   }
}
/**
 * Handle the lbutton_down message for vertical and horizontal
 * size bars.  It determines if it is sizing vertically or
 * horizontally based on the picture style (PSPIC_SIZEVERT
 * vs. PSPIC_SIZEHORZ).
 * 
 * @param min minimum x or y position in TWIPS
 * @param max maximum x or y position in TWIPS
 * 
 * @return Returns 0
 */
int _ul2_image_sizebar_handler(int min, int max)
{
   // Get the width or height of the divider
   doHorizontal := false;
   divide_size := 0;
   switch( p_style ) {
   case PSPIC_SIZEVERT:
      divide_size = p_width;
      doHorizontal = true;
      break;
   case PSPIC_SIZEHORZ:
      divide_size = p_height;
      doHorizontal = false;
      break;
   default:
      return -1;
   }

   // Save the window ID of the size bar
   orig_wid := p_window_id;
   int capture_wid = orig_wid.p_parent;
   active_form_wid := p_active_form;

   // Save the original sizes of the size bar
   int orig_x, orig_y, orig_width, orig_height;
   orig_wid._get_window(orig_x,orig_y,orig_width,orig_height);

   // These will keep track of the position of the rectangle
   thickness := 0;
   int x = orig_x;
   int y = orig_y;

   // Outside of allowed area?
   if( doHorizontal ) {
      thickness = orig_width;
      if( x < min ) {
         x = min;
      }
      if( x > max ) {
         x = max;
      }
   } else {
      thickness = orig_height;
      if( y < min ) {
         y = min;
      }
      if( y > max ) {
         y = max;
      }
   }
   if( max <= (min+thickness) ) {
      message("Window is too small.  Sizebar is frozen.");
      return 0;
   }

   int new_x = x;
   int new_y = y;

   // capture the mouse until they release the button
   mou_mode(1);
   mou_release();
   capture_wid.mou_capture();
   moved := false;
   checkMinDrag := true;

   sc.controls.RubberBand rubberBand(capture_wid);
   rubberBand.setWindow(orig_x,orig_y,orig_width,orig_height);

   se.util.MousePointerGuard mousePointerSentry(MP_DEFAULT,capture_wid);
   if( doHorizontal ) {
      mousePointerSentry.setMousePointer(MP_SIZEWE);
   } else {
      mousePointerSentry.setMousePointer(MP_SIZENS);
   }

   event := "";
   done := false;

   do {

      event = capture_wid.get_event();
      switch( event ) {
      case MOUSE_MOVE:

         // Get new mouse locations
         if( doHorizontal ) {
            new_x = capture_wid.mou_last_x('M');
            if( new_x < min ) {
               new_x = min;
            } else if( new_x > (max-divide_size) ) {
               new_x = max - divide_size;
            }
            orig_wid.p_x = new_x;
            moved = new_x != orig_x;
            rubberBand.move(new_x,orig_y);
         } else {
            new_y = capture_wid.mou_last_y('M');
            if( new_y < min ) {
               new_y = min;
            } else if( new_y > (max-divide_size) ) {
               new_y = max - divide_size;
            }
            orig_wid.p_y = new_y;
            moved = new_y != orig_y;
            rubberBand.move(orig_x,new_y);
         }

         if( checkMinDrag ) {
            if( moved ) {
               checkMinDrag=false;
               if( !rubberBand.isVisible() ) {
                  rubberBand.setVisible(true);
               }
            }
         }

         active_form_wid.call_event(active_form_wid,ON_RESIZE,'w');
         if ( _isMac() && _default_option(VSOPTION_MAC_USE_SCROLL_PERFORMANCE_HACK) ) {
            active_form_wid.refresh('R');
         }
         break;

      case LBUTTON_UP:
      case ESC:
         done = true;
         break;
      }

   } while( !done );

   // Release the mouse from its servitude
   mou_mode(0);
   capture_wid.mou_release();

   if( moved ) {
      if( event != ESC ) {

         int new_pos = doHorizontal ? new_x : new_y;

         // Adjust the final positions
         if( new_pos < min ) {
            new_pos = min;
         } else if( new_pos > (max-divide_size) ) {
            new_pos = max - divide_size;
         }

         // Check if the final positions are valid
         if( new_pos >= min && new_pos <= (max-divide_size) ) {
            if( doHorizontal ) {
               orig_wid.p_x = new_pos;
            } else {
               orig_wid.p_y = new_pos;
            }
            active_form_wid.call_event(active_form_wid,ON_RESIZE,'w');
            p_window_id = orig_wid;
         }
      }
   }

   return 0;
}

const PADDING_BETWEEN_TEXTBOX_AND_BUTTON=         15;
const PADDING_BETWEEN_BUTTONS=                    10;

/**
 * Aligns a textbox (or combo) with browse button(s).
 *
 * @param textboxWid             text box
 * @param browseButtonWid        first browse button
 * @param secondButtonWid        second browse button
 * @param rightBorder            a margin to align with the
 *                               right side of the rightmost
 *                               button.  Textbox width will
 *                               change to reflect this
 *                               alignment.  If one is not
 *                               specified, then the buttons
 *                               will be aligned to the textbox.
 */
void sizeBrowseButtonToTextBox(int textboxWid, int browseButtonWid, int secondButtonWid = 0, int rightBorder = 0)
{
   textboxHeight := textboxWid.p_height;
   comboboxYAdjust := 0;
   if (textboxWid.p_object == OI_COMBO_BOX && textboxHeight > _dy2ly(SM_TWIP,4) && _isMac()) {
      comboboxYAdjust = _dy2ly(SM_TWIP,1);
      textboxHeight -= 2*comboboxYAdjust;
   } else if (textboxWid.p_object == OI_LABEL && textboxHeight > _dy2ly(SM_TWIP,4)) {
      comboboxYAdjust = -(textboxHeight intdiv 8);
      textboxHeight -= comboboxYAdjust;
   }

   if (browseButtonWid && browseButtonWid.p_visible) {
      // turn off auto-size on the buttons
      browseButtonWid.p_auto_size = false;
      browseButtonWid.resizeToolButton(textboxHeight, true);

      // make sure the buttons are the same height as the text box
      browseButtonWid.p_height = textboxHeight+_dy2ly(SM_TWIP,1);
      browseButtonWid.p_y = textboxWid.p_y + comboboxYAdjust;
   }

   // do the same for the second button, if it is there
   if (secondButtonWid && secondButtonWid.p_visible) {
      secondButtonWid.p_auto_size = false;
      secondButtonWid.resizeToolButton(textboxHeight, true);
      secondButtonWid.p_height = textboxHeight+_dy2ly(SM_TWIP,1);
      secondButtonWid.p_y = textboxWid.p_y + comboboxYAdjust;
   }

   // space them properly - we want just a teeny bit of room between them
   // since they are related
   if (rightBorder) {
      // align on the right
      if (secondButtonWid && secondButtonWid.p_visible) {
         secondButtonWid.p_x = rightBorder - secondButtonWid.p_width;
         rightBorder = secondButtonWid.p_x - PADDING_BETWEEN_BUTTONS;
      }
      if (browseButtonWid && browseButtonWid.p_visible) {
         browseButtonWid.p_x = rightBorder - browseButtonWid.p_width;
         textboxWid.p_x_extent = browseButtonWid.p_x - PADDING_BETWEEN_TEXTBOX_AND_BUTTON;
      } else {
         textboxWid.p_x_extent = rightBorder;
      }

   } else {
      // align with the existing text box position
      if (browseButtonWid) {
         browseButtonWid.p_x = textboxWid.p_x_extent + PADDING_BETWEEN_TEXTBOX_AND_BUTTON;
      }
      if (browseButtonWid && secondButtonWid) {
         secondButtonWid.p_x = browseButtonWid.p_x_extent + PADDING_BETWEEN_BUTTONS;
      }
   }
}

const PADDING_BETWEEN_LIST_AND_CONTROLS=          25;
const PADDING_BETWEEN_CONTROL_BUTTONS=            15;

/**
 * Aligns a listbox and a set of control buttons (up, down, add,
 * delete, etc.).
 *
 * The top most button will have the same p_y as the list box.
 * Additional buttons will be evenly spaced down. Can specify a
 * rightAlign to line up the right alignment of the buttons
 * (listbox width will be adjusted accordingly).
 *
 * Send buttons in order from top to bottom.
 *
 * @param listWid
 * @param rightAlign
 */
void alignUpDownListButtons(int listWid, int rightAlign, ...)
{
   // how many controls to align?
   numControls := arg() - 2;

   // set up our initial values - we want the top button to sit even with the list
   nextY := listWid.p_y;
   x := 0;

   // skip the first two args
   for (i := 3; i <= (numControls + 2); i++) {
      wid := arg(i);

      // resize tool window buttons to fit along side this control
      if (wid.p_object == OI_IMAGE) {
         wid.resizeToolButton(listWid.p_height intdiv numControls - PADDING_BETWEEN_CONTROL_BUTTONS);
      }

      if (!x) {
         // figure out where x should be
         if (rightAlign) {
            x = rightAlign - wid.p_width;

            // adjust the width of the listbox to go with this
            listWid.p_width = x - PADDING_BETWEEN_LIST_AND_CONTROLS - listWid.p_x;
         } else {
            // nothing to right align with, so just space out from the list
            x = listWid.p_x_extent + PADDING_BETWEEN_LIST_AND_CONTROLS;
         }
      }

      // set up the x position
      wid.p_x = x;

      wid.p_y = nextY;
      nextY += (wid.p_height + PADDING_BETWEEN_CONTROL_BUTTONS);
   }
}

void alignHorizontalAutoSizedListButtons(int listWid, int bottomAlign, ...)
{
   // how many controls to align?
   numControls := arg() - 2;

   // set up our initial values - we want the top button to sit even with the list
   nextX := listWid.p_x;
   y := 0;

   // skip the first two args
   for (i := 3; i <= (numControls + 2); i++) {
      wid := arg(i);

      // resize tool window buttons to fit along side this control
      if (wid.p_object == OI_IMAGE) {
         wid.resizeToolButton(listWid.p_width intdiv numControls - PADDING_BETWEEN_CONTROL_BUTTONS);
      }

      if (!y) {
         // figure out where x should be
         if (bottomAlign) {
            y = bottomAlign - wid.p_height;

            // adjust the width of the listbox to go with this
            listWid.p_height = y - PADDING_BETWEEN_LIST_AND_CONTROLS - listWid.p_y;
         } else {
            // nothing to right align with, so just space out from the list
            y = listWid.p_y_extent + PADDING_BETWEEN_LIST_AND_CONTROLS;
         }
      }

      // set up the x position
      wid.p_y = y;

      wid.p_x = nextX;
      nextX += (wid.p_width + PADDING_BETWEEN_CONTROL_BUTTONS);
   }
}

/**
 * Align a list of controls horizontally.
 * 
 * @param x         align to this left boundary
 * @param y         align to this top boundary
 * @param space_x   amount of space to put between controls 
 * @param controls  variadic arguments with window IDs of controls to align 
 */
void alignControlsHorizontal(int x, int y, int space_x, ...)
{
   numControls := arg()-3;
   for (i := 0; i < numControls; i++) {
      wid := arg(i+4);
      if (!wid) {
         continue;
      }
      wid.p_x = x;
      wid.p_y = y;
      x += (wid.p_width + space_x);
   }
}

/**
 * Align a list of controls vertically.
 * 
 * @param x         align to this left boundary
 * @param y         align to this top boundary
 * @param space_y   amount of space to put between controls
 * @param controls  variadic arguments with window IDs of controls to align 
 */
void alignControlsVertical(int x, int y, int space_y, ...)
{
   // skip the first two args
   numControls := arg()-3;
   for (i := 0; i < numControls; i++) {
      wid := arg(i+4);
      wid.p_x = x;
      wid.p_y = y;
      y += (wid.p_height + space_y);
   }
}

/**
 * Scale down this tool window button if necessary so that it 
 * does not look oversized on the current tool window. 
 * The current object is expected to be a tool window button. 
 * 
 * @param max_button_height   maximum height for button 
 * @param allowTinySizes      allow sizes less than 16 pixels
 */
void resizeToolButton(int max_button_height, bool allowTinySizes=false)
{
   // make sure the button height is within reasonable parameters
   if (!allowTinySizes && max_button_height < _dy2ly(SM_TWIP, 16)) {
      max_button_height = _dy2ly(SM_TWIP, 16);
   } else if (max_button_height < _dy2ly(SM_TWIP, 8)) {
      max_button_height = _dy2ly(SM_TWIP, 8);
   } else if (max_button_height > _dy2ly(SM_TWIP, 64)) {
      max_button_height = _dy2ly(SM_TWIP, 64);
   }

   // adjust the button height to a standard button size.
   nearest_size := getImageSizeForFontHeight(_ly2dy(SM_TWIP,max_button_height), allowTinySizes, true, allowTinySizes);
   tb_pic_size := _toolbar_pic_size_as_integer();
   if (nearest_size > tb_pic_size) {
      nearest_size = tb_pic_size;
   }
   max_button_height = _dy2ly(SM_TWIP,nearest_size);

   // now we see what the image's actual size is
   y_border := _dy2ly(SM_TWIP,4);
   if ( p_height >= max_button_height+y_border || p_height <= max_button_height-y_border) {
      p_auto_size = true;
      p_stretch = false;
      if ( p_height >= max_button_height+y_border || p_height <= max_button_height-y_border) {
         bm_index := p_picture;
         if (bm_index > 0) {
            bm_name := name_name(bm_index);
            if (bm_name != "") {
               parse bm_name with bm_name "@" .;
               if (_first_char(bm_name) == '_' || beginsWith(bm_name, "bb")) {
                  ext := _get_extension(bm_name);
                  if (beginsWith(ext, "svg")) {
                     p_stretch = true;
                     p_auto_size = false;
                     p_width = p_height = max_button_height + y_border;
                  } else {
                     bitmapsPath := _getSlickEditInstallPath():+"bitmaps";
                     if (file_exists(bitmapsPath:+FILESEP:+"dialogs":+FILESEP:+bm_name)) {
                        bm_name = "dialogs" :+ FILESEP :+ bm_name;
                     }
                     bm_name :+= "@":+def_toolbar_pic_style:+nearest_size;
                     bm_index = find_index(bm_name, PICTURE_TYPE);
                     if (bm_index <= 0) bm_index = _update_picture(-1, bm_name);
                     if (bm_index > 0) p_picture = bm_index;
                  }
               }
            }
         }
         p_auto_size = false;
         if (abs(p_height - max_button_height - y_border) > _dy2ly(SM_TWIP,1)) {
            p_stretch = true;
         }
         p_width = p_height = max_button_height + y_border;
      }
   }
}

/**
 * Return a standard image size based on the current control's font height. 
 *  
 * @param font_height_in_pixels   font height, from {@link p_font_height} control property 
 * @param hasLowRes               does the icon being loaded have low-res versions? 
 * @param hasHighRes              does the icon being loaded have hi-res versions? 
 * @param hasTinyRes              does the icon being loaded have tiny sizes (8-12)
 */
int getImageSizeForFontHeight(int font_height_in_pixels, 
                              bool hasLowRes=true, 
                              bool hasHighRes=false,
                              bool hasTinyRes=false)
{
   // first scale the font height down 90% to compensate for interline spacing
   //font_height_in_pixels = (font_height_in_pixels * 90) intdiv 100;

   // then pick a font height.
   if (hasHighRes) {
      // Button bar icons have high-resolution, scalable bitmaps
      if (font_height_in_pixels >= 256) {
         return 256;
      } else if (font_height_in_pixels >= 128) {
         return 128;
      } else if (font_height_in_pixels >= 96) {
         return 96;
      } else if (font_height_in_pixels >= 64) {
         return 64;
      }
   }

   // all bitmaps have these sizes
   if (font_height_in_pixels >= 48) {
      return 48;
   } else if (font_height_in_pixels >= 32) {
      return 32;
   } else if (font_height_in_pixels >= 24) {
      return 24;
   } else if (font_height_in_pixels >= 20) {
      // well, some don't have 20, but the image loader will find the nearest match (16)
      return 20;
   }

   if (!hasLowRes) {
      // 16 pixels is smallest size for button bar bitmaps
      return 16;
   }

   if (font_height_in_pixels >= 16) {
      return 16;
   } else if (font_height_in_pixels >= 14) {
      return 14;
   }

   if (!hasTinyRes) {
      // 12 is smallest size for tree bitmaps
      return 12;
   }

   // if tiny sizes are allowed
   if (font_height_in_pixels >= 12) {
      return 12;
   } else if (font_height_in_pixels >= 10) {
      return 10;
   } else {
      return 8;
   }
}

