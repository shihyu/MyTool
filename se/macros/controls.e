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
#include 'slick.sh'
#include 'minihtml.sh'
#import "complete.e"
#import "html.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

//
//    User level 2 inheritance for LIST BOX p_multi_select==MS_EDIT_WINDOW
//
defeventtab _ul2_editwin;
_ul2_editwin.on_create2()
{
   //p_multi_select=MS_EDIT_WINDOW;
   _SetEditorLanguage();
#if 0
   if (p_edit) {
      insert_line(' 'p_name)
      top()
   }
#endif
}
//_ul2_editwin.' '()
//{
//
//}
_ul2_editwin.tab()
{
   call_event(p_active_form,TAB);
}
_ul2_editwin.s_tab()
{
   call_event(p_active_form,S_TAB);
}



//
//    User level 2 inheritance for TEXT BOX control
//
defeventtab _ul2_textbox _inherit _ul2_textbox2;
/**
 * This function is invoked as a callback from the window procedure
 * for the SlickEdit command line.
 */
void _cmdline_on_change2()
{
   static _str last_text;
   if (!_cmdline || !_iswindow_valid(_cmdline) || _default_option(VSOPTION_STAY_IN_GET_STRING_COUNT)) return;
   if (last_text!=null && last_text==_cmdline.p_text) return;
   last_text=_cmdline.p_text;
   ArgumentCompletionUpdateTextBox();
}
/**
 * This function is invoked whenever a text box (not a combo box)
 * contents change.  The on_change2() callback is used because
 * on_change() may be overridden in the control's event table.
 */
void _ul2_textbox.on_change2()
{
   if (p_completion=='') return;
   ArgumentCompletionUpdateTextBox();
}
void _ul2_textbox.rbutton_down,context()
{
   int index=find_index("_textbox_menu",oi2type(OI_MENU));
   int menu_handle=_menu_load(index,'P');
   int x,y;
   if (last_event():==CONTEXT) {
      x=p_width intdiv 2;y=p_height intdiv 2;
      _lxy2dxy(p_xyscale_mode,x,y);
      _map_xy(p_window_id,0,x,y);
   } else {
      mou_get_xy(x,y);
   }
   p_auto_select=false;
   _default_option(VSOPTION_STAY_IN_GET_STRING_COUNT,1);
   orig_wid := p_window_id;
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
   p_window_id=orig_wid;
   _default_option(VSOPTION_STAY_IN_GET_STRING_COUNT,0);
   p_auto_select=true;
}
_ul2_textbox.down()
{
   call_event('-',defeventtab _ul2_textbox,UP,'e');
}
_ul2_textbox.up()
{
   if (p_next.p_object==OI_SPIN) {
      int direction= (arg(1)=='-')?-1:1;
      wid := p_window_id;
      p_window_id=p_next;
      if (p_increment<=0) {
         if (direction==1) {
            p_window_id.call_event(p_window_id,ON_SPIN_UP);
         } else if (direction==-1){
            p_window_id.call_event(p_window_id,ON_SPIN_DOWN);
         }
      } else {
         typeless text=wid.p_text;
         if (direction==1) {
            if (text+p_increment<=p_max) {
               text+=p_increment;
               wid._set_sel(1,length(text)+1);
               wid.p_text=text;
            }
         } else if (direction==-1){
            if(text-p_increment>=p_min){
              text-=p_increment;
               wid._set_sel(1,length(text)+1);
               wid.p_text=text;
            }
         }
      }
   }
}
def s_home,s_up,s_pgup,s_left,s_right,s_end,s_down,s_pgdn,'c-s-left','c-s-right'=cua_select;
_ul2_textbox.' '()
{
   if (p_completion!='') {
      maybe_complete(p_completion);
      return('');
   }
   keyin(' ');
}
_ul2_textbox.'?'()
{
   if (p_completion!='' && def_qmark_complete) {
      maybe_list_matches(p_completion,'',false,true);
      return('');
   }
   keyin('?');
}
void _ul2_textbox.tab()
{
   call_event(p_active_form,TAB);
}

void _ul2_textbox.end()
{
   end_line();
}

_ul2_textbox.s_tab()
{
   call_event(p_active_form,S_TAB);
}
#if 0
_ul2_textbox.A_A-A_Z()
{
   call_event(p_active_form,S_TAB)
}
_ul2_textbox.A_0-A_1()
{
   call_event(p_active_form,S_TAB)
}
#endif
defeventtab _ul2_textbox2;
_ul2_textbox2.A_A-A_Z()
{
   if (p_window_id==_cmdline) {
      _str command=name_on_key(last_event());
      if (command=='') return('');
      execute(command);
      return('');
   }
   call_event(p_active_form,last_event());
}
def C_X=cut;
def C_C=copy_to_clipboard;
def C_V=paste;
void _ul2_textbox2.C_A() {
   if (p_object==OI_COMBO_BOX && p_style==PSCBO_NOEDIT) {
      return;
   }
   _str command=name_on_key(last_event());
   // macOS emulation need support for begin_line commands.
   if (pos('begin-line',command)) {
      _set_sel(1,1);
      return;
   }
   _set_sel(1,length(p_text)+1);
}

#if 0
_ul2_textbox2.C_X()
{
   cut();
}
_ul2_textbox2.C_C()
{
   copy_to_clipboard();
}
_ul2_textbox2.C_V()
{
   paste();
}
#endif
_command void ctlinsert(_str text="", _str delim='%') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   col := 0;
   i := 0;
   j := 0;
   for (i=1;;) {
      j=pos(delim,text,i);
      if (!j) {
         break;
      }
      if (substr(text,j+1,1)==delim) {
         i=j+2;
      } else if (substr(text,j+1,2)=='\c') { // cursor position
         col=j;
         text=substr(text,1,j-1):+substr(text,j+3);
         i=j;
      } else if (substr(text,j+1,2)=='\w') { // wild cards
         col=j;
         text=substr(text,1,j-1):+ALLFILES_RE:+substr(text,j+3);
         i=j;
      } else if (substr(text,j+1,1)=='\') {  // escaped charactor
         text=substr(text,1,j-1):+substr(text,j+1);
         i=j;
      } else {
         i=j+1;
      }
   }

   // step back until a control is found that supports keyin
   wid := p_prev;
   for(;;) {
      if(wid.p_object == OI_COMBO_BOX || wid.p_object == OI_TEXT_BOX || wid.p_object == OI_EDITOR) {
         break;
      }

      // step previous
      wid = wid.p_prev;
   }
   if (wid) {
      wid._set_focus();
      int orig_col=wid._get_sel();
      wid.keyin(text);
      if (col) {
         wid._set_sel(orig_col+col-1);
      }
   }
}
defeventtab _ul2_minihtm;
void _ul2_minihtm.c_home,home()
{
   _minihtml_command("top");
}
void _ul2_minihtm.c_end,end()
{
   _minihtml_command("bottom");
}
void _ul2_minihtm.pgdn()
{
   _minihtml_command("pagedown");
}
void _ul2_minihtm.pgup()
{
   _minihtml_command("pageup");
}
void _ul2_minihtm.up,c_up()
{
   _minihtml_command("scrollup");
}
void _ul2_minihtm.down,c_down()
{
   _minihtml_command("scrolldown");
}
void _ul2_minihtm.left,c_left()
{
   _minihtml_command("scrollleft");
}
void _ul2_minihtm.right,c_right()
{
   _minihtml_command("scrollright");
}
void _ul2_minihtm.c_equal()
{
   _minihtml_command("zoomin");
}
void _ul2_minihtm.c_minus()
{
   _minihtml_command("zoomout");
}
void _ul2_minihtm.c_0()
{
   _minihtml_command("unzoom");
}

void _ul2_minihtm.lbutton_down()
{
   get_event('B');
   typeless result=_minihtml_click(mou_last_x(),mou_last_y());
   if (result!='') {
      call_event(CHANGE_CLICKED_ON_HTML_LINK,result,p_window_id,ON_CHANGE,'w');
   }
}
void _ul2_minihtm.on_change(int reason,_str hrefText)
{
   if (reason==CHANGE_CLICKED_ON_HTML_LINK) {
      if (_first_char(hrefText)=='#') {
         _minihtml_FindAName(substr(hrefText,2),0);
         return;
      }
      _str webpage=hrefText;
      i := pos('://',webpage);
      word := "";
      rest := "";
      type := "";
      if (i) {
         word=substr(webpage,1,i-1);
         rest=substr(webpage,i+3);
      }
      if (lowcase(word)=='file' ) {
         webpage=rest;
         type='f';
      } else if (word=='' &&
                 (substr(webpage,2,1)==':' || substr(webpage,2,1)=='|')  &&
                 (substr(webpage,3,1)=='\' || substr(webpage,3,1)=='/') &&
                  substr(webpage,4,1)!='\' && substr(webpage,4,1)!='/'
                 ) {
         type='f';
      } else if (word=='' &&
                 (substr(webpage,1,1)=='\' || substr(webpage,1,1)=='/') &&
                  substr(webpage,2,1)!='\' && substr(webpage,2,1)!='/'
                 ) {
         type='f';
      } else {
         type='p';
      }
      if (type=='f') {
         webpage=translate(webpage,':','|');
         if(FILESEP=='\') {
            webpage=translate(webpage,'\','/');
         }
      }

      protocol := "";
      remainder := "";
      parse webpage with protocol":"remainder;
      if (protocol :== "slickc") {
         execute(remainder);
         return;
      }
      goto_url(webpage);
      return;
   }
}
void _ul2_minihtm.'s-lbutton-down'()
{
   get_event('B');
   typeless result=_minihtml_click(mou_last_x(),mou_last_y(),'E');
   if (result!='') {
      call_event(CHANGE_CLICKED_ON_HTML_LINK,result,p_window_id,ON_CHANGE,'w');
   }
}
void _ul2_minihtm.pgup()
{
   _minihtml_command("pageup");
}
void _ul2_minihtm.c_c,c_ins,'m_c'()
{
   _minihtml_command("copy");
   _minihtml_command("deselect");
}
void _ul2_minihtm.c_a,'m_a'()
{
   _minihtml_command("selectall");
}
void _ul2_minihtm.c_u,'m_u'()
{
   _minihtml_command("deselect");
}

